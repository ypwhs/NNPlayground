#!/usr/bin/env python3
"""采集真实中英文商店截图及中文录屏；不覆盖历史素材，不修改应用状态数据。"""

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import selectors
import signal
import subprocess
import sys
import time

from capture_layout import parse_displays, png_size, target_pixels, check_snapshot

ROOT = Path(__file__).resolve().parents[1]
PHASES = {"01-circle-trained", "02-network-settings", "03-xor-test-data", "04-binary-output"}
SIZES = {"large": (2868, 1320), "medium": (2622, 1206), "ipad": (2752, 2064), "duo-folded": (2034, 1398), "duo-unfolded": (2853, 2007)}
CAPTURE = re.compile(r"STORE_CAPTURE_READY\s+(zh-Hans|en)\s+([\w-]+)")
EXIT = re.compile(r"STORE_XCODEBUILD_EXIT=(\d+)")


def run(command, env, timeout=60):
    result = subprocess.run(command, cwd=ROOT, env=env, text=True, capture_output=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError(f"命令失败({result.returncode}): {command}\n{result.stdout}\n{result.stderr}")
    return result.stdout


def save(path, value):
    with path.open("x", encoding="utf-8") as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_scene(device, directory, name, args, env):
    product = Path(args.derived_data) / "Build/Products/Debug-iphonesimulator/NNPlayground.app/Info.plist"
    with product.open("rb") as stream:
        bundle = plistlib.load(stream)
    if bundle["CFBundleIdentifier"] != "com.yangpeiwen.NNPlayground2":
        raise ValueError("构建产品 bundle id 不是本次授权应用")
    container = run(["xcrun", "simctl", "get_app_container", device["udid"], bundle["CFBundleIdentifier"], "data"], env).strip()
    with (Path(container) / "Documents/layout-review.plist").open("rb") as stream:
        scene = plistlib.load(stream)
    save(directory / f"{name}-scene.json", scene)
    enumeration = run(["xcrun", "simctl", "io", device["udid"], "enumerate"], env)
    with (directory / f"{name}-displays.txt").open("x") as stream:
        stream.write(enumeration)
    displays = parse_displays(enumeration)
    pixels, source = target_pixels(scene)
    candidates = [item for item in displays if item["displayClass"] == "0" and
                  sorted((item["width"], item["height"])) == pixels]
    if len(candidates) != 1:
        raise ValueError(f"集成显示器必须唯一匹配 scene 实际像素：{candidates}")
    return scene, {"source": source, "targetPixels": pixels, "selected": candidates[0], "enumerated": displays}, bundle


def capture(device, language, phase, dirs, args, env):
    name = f"{language}-{phase}"
    scene, display, bundle = read_scene(device, dirs["raw"], name, args, env)
    target = dirs["shots"] / language
    target.mkdir(exist_ok=True)
    path = target / f"{phase}.png"
    if path.exists():
        raise FileExistsError(f"拒绝覆盖截图：{path}")
    command = ["xcrun", "simctl", "io", device["udid"], "screenshot", "--type=png",
               "--display", display["selected"]["uuid"], "--mask=black", str(path)]
    run(command, env)
    dimensions = png_size(path)
    # 复用诊断脚本的公共几何检查，替换仅适用原布局路径的交互状态断言。
    checks = [item for item in check_snapshot(scene, "left-reset") if not item["name"].startswith("重置后")]
    checks.append({"name": "原生横屏PNG尺寸符合目标规格", "passed": dimensions == SIZES[device["role"]], "actual": dimensions})
    if phase == "02-network-settings":
        state_ok = scene["settingsVisible"] and scene["dataset"] == 1 and scene["layers"] == 4
    else:
        state_ok = scene["epoch"] > 0 and not scene["training"] and not scene["settingsVisible"] and not scene["speedUp"]
        state_ok = state_ok and scene["dataset"] == (0 if phase == "01-circle-trained" else 1)
    checks.append({"name": "真实训练/配置状态匹配阶段", "passed": bool(state_ok), "actual": scene})
    # Apple不接受alpha通道，检查PNG IHDR color type；simctl black输出应为RGB。
    with path.open("rb") as stream:
        header = stream.read(26)
    checks.append({"name": "PNG不含alpha通道", "passed": header[25] in (0, 2), "actual": header[25]})
    result = {"language": language, "phase": phase, "path": str(path), "pixels": dimensions,
              "sha256": sha256(path), "display": display, "mask": "black", "command": command,
              "bundleVersion": bundle.get("CFBundleShortVersionString"), "checks": checks,
              "passed": all(item["passed"] for item in checks), "manualReview": "pending"}
    print(f"截图 {device['role']} {name}: {'通过' if result['passed'] else '失败'}", flush=True)
    return result


def test_device(device, dirs, args, env, video=False):
    kind = "video" if video else "screenshots"
    methods = ["testStoreVideoChinese"] if video else ["testStoreChinese", "testStoreEnglish"]
    command = ["xcodebuild", "test", "-project", str(ROOT / "NNPlayground.xcodeproj"),
               "-scheme", "NNPlayground", "-configuration", "Debug", "-destination",
               f"platform=iOS Simulator,id={device['udid']}", "-derivedDataPath", str(Path(args.derived_data).resolve()),
               "CODE_SIGNING_ALLOWED=NO", "-parallel-testing-enabled", "NO", "-maximum-concurrent-test-simulator-destinations", "1",
               "-resultBundlePath", str(dirs["raw"] / f"{kind}.xcresult")]
    command += [f"-only-testing:NNPlaygroundUITests/NNPlaygroundUITests/{method}" for method in methods]
    wrapped = ["/usr/bin/script", "-q", str(dirs["raw"] / f"{kind}-terminal.log"), "/bin/sh", "-c",
               '"$@"; code=$?; printf "\\nSTORE_XCODEBUILD_EXIT=%s\\n" "$code"; exit "$code"', "store-media", *command]
    result = {"command": command, "captures": [], "errors": [], "manualReview": "pending"}
    process = recorder = None
    recorder_log = None
    selector = selectors.DefaultSelector()
    seen = set()
    succeeded = False
    xcode_exit = None
    try:
        process = subprocess.Popen(wrapped, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        selector.register(process.stdout, selectors.EVENT_READ)
        deadline = time.monotonic() + args.timeout
        pending = b""
        with (dirs["raw"] / f"{kind}-build.log").open("xb") as log:
            while selector.get_map():
                if time.monotonic() >= deadline:
                    raise TimeoutError("UI测试超时")
                for key, _ in selector.select(timeout=1):
                    chunk = os.read(key.fileobj.fileno(), 65536)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        continue
                    log.write(chunk)
                    log.flush()
                    pending += chunk
                    while b"\n" in pending:
                        line, pending = pending.split(b"\n", 1)
                        text = line.decode("utf-8", errors="replace")
                        if "** TEST SUCCEEDED **" in text:
                            succeeded = True
                        match = EXIT.search(text)
                        if match:
                            xcode_exit = int(match.group(1))
                        match = CAPTURE.search(text)
                        if match and not video:
                            language, phase = match.groups()
                            if (language, phase) in seen or phase not in PHASES:
                                raise ValueError(f"重复或未知截图marker：{match.group(0)}")
                            seen.add((language, phase))
                            result["captures"].append(capture(device, language, phase, dirs, args, env))
                        if video and "STORE_VIDEO_BEGIN zh-Hans" in text:
                            if recorder is not None:
                                raise ValueError("重复视频开始marker")
                            scene, display, bundle = read_scene(device, dirs["raw"], "video-start", args, env)
                            path = dirs["raw"] / "zh-Hans-original.mov"
                            if path.exists():
                                raise FileExistsError(path)
                            rec_command = ["xcrun", "simctl", "io", device["udid"], "recordVideo", "--codec=h264",
                                           "--display", display["selected"]["uuid"], "--mask=black", str(path)]
                            recorder_log = (dirs["raw"] / "record-video.log").open("xb")
                            recorder = subprocess.Popen(rec_command, cwd=ROOT, env=env, stdout=recorder_log, stderr=subprocess.STDOUT)
                            result["video"] = {"path": str(path), "display": display, "mask": "black", "command": rec_command,
                                               "beginAt": dt.datetime.now().astimezone().isoformat(), "scene": scene}
                            print(f"真实录屏开始：{path}", flush=True)
                        if video and "STORE_VIDEO_END zh-Hans" in text:
                            if recorder is None or recorder.poll() is not None:
                                raise RuntimeError("录屏结束marker前录屏未运行")
                            recorder.send_signal(signal.SIGINT)
                            recorder.wait(timeout=30)
                            recorder_log.close()
                            result["video"]["recorderExitCode"] = recorder.returncode
                            result["video"]["sha256"] = sha256(Path(result["video"]["path"]))
                            result["video"]["endAt"] = dt.datetime.now().astimezone().isoformat()
                            print(f"真实录屏结束：exit={recorder.returncode}", flush=True)
            process.wait(timeout=max(1, deadline - time.monotonic()))
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        result["errors"].append(str(error))
    finally:
        selector.close()
        if process and process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
        if recorder and recorder.poll() is None:
            recorder.send_signal(signal.SIGINT)
            try:
                recorder.wait(timeout=30)
            except subprocess.TimeoutExpired:
                recorder.kill()
                recorder.wait()
        if recorder_log and not recorder_log.closed:
            recorder_log.close()
    result.update(scriptExitCode=process.returncode if process else None,
                  xcodebuildExitCode=xcode_exit, testSucceededMarker=succeeded)
    if result["scriptExitCode"] != 0 or xcode_exit != 0 or not succeeded:
        result["errors"].append("PTY包装器、真正xcodebuild退出码及TEST SUCCEEDED必须全部通过")
    if video:
        if result.get("video", {}).get("recorderExitCode") != 0:
            result["errors"].append("原始录屏没有正常结束")
    elif seen != {(language, phase) for language in ("zh-Hans", "en") for phase in PHASES}:
        result["errors"].append("中英文各四张截图marker不完整")
    result["automatedPassed"] = not result["errors"] and all(item["passed"] for item in result["captures"])
    save(dirs["check"] / f"{kind}-summary.json", result)
    return result


def resolve_source(requested, env):
    # 每次显式解析到完整提交，不把历史素材来源当作未来采集的固定授权来源。
    commit = run(["git", "rev-parse", "--verify", "--end-of-options", requested + "^{commit}"], env).strip()
    head = run(["git", "rev-parse", "HEAD"], env).strip()
    return {"head": head, "productionSource": commit, "requestedSource": requested,
            "productionDiff": run(["git", "diff", commit, head, "--", "NNPlayground", "NNPlayground.xcodeproj"], env),
            "workingTreeDiff": run(["git", "diff", "HEAD", "--", "NNPlayground", "NNPlayground.xcodeproj"], env)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", action="append", required=True, help="large|medium|ipad|duo-folded|duo-unfolded:UDID，可重复；依次运行")
    parser.add_argument("--release-root", type=Path, required=True, help="只在01/02/07/08下建立新run目录")
    parser.add_argument("--run-id", default=dt.datetime.now().strftime("store-%Y%m%d-%H%M%S"))
    parser.add_argument("--source-commit", default="HEAD", help="本次明确的生产来源提交；默认当前HEAD，解析为完整SHA")
    parser.add_argument("--derived-data", default="/tmp/nnp-appstore-media-dd")
    parser.add_argument("--developer-dir", default="/Applications/Xcode.app/Contents/Developer")
    parser.add_argument("--timeout", type=float, default=1200)
    parser.add_argument("--video-role", choices=SIZES)
    parser.add_argument("--shutdown-after", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", args.run_id):
        parser.error("run-id只能包含字母数字与._-")
    if args.timeout <= 0:
        parser.error("timeout必须大于0")
    env = dict(os.environ, DEVELOPER_DIR=args.developer_dir)
    try:
        source = resolve_source(args.source_commit, env)
        if source["productionDiff"] or source["workingTreeDiff"]:
            raise ValueError("生产源码与指定来源不一致，拒绝采集（包含已暂存及未暂存改动）")
        data = json.loads(run(["xcrun", "simctl", "list", "devices", "available", "--json"], env))
        available = {item["udid"]: dict(item, runtime=runtime) for runtime, items in data["devices"].items() for item in items}
        selected = []
        for value in args.device:
            role, udid = value.split(":", 1)
            if role not in SIZES or udid not in available or not available[udid].get("isAvailable"):
                raise ValueError(f"设备/角色无效：{value}")
            if role in {item["role"] for item in selected} or udid in {item["udid"] for item in selected}:
                raise ValueError("设备与角色不得重复")
            selected.append(dict(available[udid], role=role))
        dirs = {key: args.release_root.resolve() / value / args.run_id for key, value in
                {"shots": "01_截图", "video": "02_视频", "raw": "07_原始素材", "check": "08_素材校验"}.items()}
        for path in dirs.values():
            if path.exists() or path.is_symlink():
                raise FileExistsError(f"拒绝覆盖已有运行目录：{path}")
        for path in dirs.values():
            path.mkdir(parents=True, exist_ok=False)
        source.update(xcode=run(["xcodebuild", "-version"], env), createdAt=dt.datetime.now().astimezone().isoformat(),
                      scripts={str(path.relative_to(ROOT)): sha256(path) for path in
                               [Path(__file__), ROOT / "NNPlaygroundUITests/NNPlaygroundUITests.m"]})
        save(dirs["check"] / "source.json", source)
        results = []
        for device in selected:
            device_dirs = {key: path / device["role"] for key, path in dirs.items()}
            for path in device_dirs.values():
                path.mkdir()
            if device["state"] != "Booted":
                run(["xcrun", "simctl", "boot", device["udid"]], env)
            run(["xcrun", "simctl", "bootstatus", device["udid"], "-b"], env, timeout=300)
            print(f"设备开始：{device['name']} {device['udid']}", flush=True)
            entry = {"device": device, "screenshots": test_device(device, device_dirs, args, env)}
            if args.video_role == device["role"] and entry["screenshots"]["automatedPassed"]:
                entry["video"] = test_device(device, device_dirs, args, env, video=True)
            results.append(entry)
            if args.shutdown_after:
                run(["xcrun", "simctl", "shutdown", device["udid"]], env)
        passed = all(entry["screenshots"]["automatedPassed"] and entry.get("video", {}).get("automatedPassed", True) for entry in results)
        summary = {"source": source, "results": results, "automatedPassed": passed, "manualReview": "pending",
                   "note": "Debug可访问标识仅辅助真实UI操作；不等于真机/Release二进制测试。复选框状态需逐图确认。视频需另用安全导出器生成并验证。"}
        save(dirs["check"] / "summary.json", summary)
        print(f"采集自动检查：{'通过' if passed else '失败'}；仍须逐图目检。{dirs['check']}", flush=True)
        return 0 if passed else 1
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"错误：{error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
