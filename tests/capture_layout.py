#!/usr/bin/env python3
"""串行运行布局 UI 测试，捕获明确显示器的黑色遮罩截图及几何证据。"""

import argparse
import datetime as dt
import json
import math
import os
from pathlib import Path
import plistlib
import re
import selectors
import signal
import struct
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
MARKER = re.compile(r"LAYOUT_CAPTURE_READY\s+((?:left|right|portrait)-(?:trained|settings|reset))\b")
EXIT_MARKER = re.compile(r"LAYOUT_XCODEBUILD_EXIT=(\d+)")
PHASES = {f"{side}-{step}" for side in ("left", "right", "portrait")
          for step in ("trained", "settings", "reset")}
UNVERIFIED = [
    "真实折叠/展开的连续切换，以及后台折叠后回前台",
    "截图是否黑屏、是否为目标屏幕、相机遮罩与实际内容是否遮挡（必须人工查看）",
    "最大网络规模、全部配置选项、方向锁开关及真机行为",
]


def run(command, env, timeout=30):
    result = subprocess.run(command, cwd=ROOT, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
    if result.returncode:
        raise RuntimeError(f"命令失败({result.returncode}): {command}\n{result.stderr}\n{result.stdout}")
    return result.stdout


def write_json(path, value):
    with path.open("x", encoding="utf-8") as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def safe_name(value):
    return re.sub(r"[^\w.-]+", "-", value, flags=re.UNICODE).strip(".-") or "device"


def devices_for(args, env):
    data = json.loads(run(["xcrun", "simctl", "list", "devices", "available", "--json"], env))
    available = [dict(item, runtime=runtime) for runtime, items in data["devices"].items()
                 for item in items if item.get("isAvailable", False)]
    selected = []
    for requested in args.device or []:
        matches = [item for item in available
                   if item["udid"].lower() == requested.lower() or item["name"] == requested]
        if len(matches) != 1:
            raise ValueError(f"设备必须唯一匹配名称或 UDID：{requested}，匹配数={len(matches)}")
        if matches[0]["state"] != "Booted":
            raise ValueError(f"请先手动启动模拟器：{matches[0]['name']} ({matches[0]['udid']})")
        if matches[0]["udid"] not in {item["udid"] for item in selected}:
            selected.append(matches[0])
    if not args.device:
        selected = [item for item in available if item["state"] == "Booted"]
    if not selected:
        raise ValueError("没有已启动且可用的模拟器；请先启动目标设备。")
    return selected


def parse_displays(text):
    displays = []
    for block in re.split(r"(?m)^Port:\s*$", text):
        def field(key):
            match = re.search(r"(?m)^\s*" + re.escape(key) + r":\s*(.*?)\s*$", block)
            return match.group(1) if match else None
        if field("Class") != "Display":
            continue
        uuid, width, height = field("UUID"), field("Default width"), field("Default height")
        if uuid and width and height:
            displays.append({"uuid": uuid, "width": int(width), "height": int(height),
                             "displayClass": field("Display class"), "power": field("Power state")})
    return displays


def target_pixels(snapshot):
    width, height = snapshot.get("screenPixelWidth"), snapshot.get("screenPixelHeight")
    if width and height:
        return sorted((round(float(width)), round(float(height)))), "scene.screen.nativeBounds"
    scale = snapshot.get("screenScale", snapshot.get("displayScale", snapshot.get("scale")))
    if scale and snapshot.get("width") and snapshot.get("height"):
        return sorted((round(float(snapshot["width"]) * float(scale)),
                       round(float(snapshot["height"]) * float(scale)))), "root.bounds * reported scale"
    raise ValueError("快照没有实际屏幕像素尺寸，也没有可用的实际 scale；拒绝猜测显示器。")


def png_size(path):
    with path.open("rb") as stream:
        header = stream.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError(f"不是有效 PNG/IHDR：{path}")
    return struct.unpack(">II", header[16:24])


def check_snapshot(snapshot, phase):
    checks = []
    def check(name, passed, actual):
        checks.append({"name": name, "passed": bool(passed), "actual": actual})
    required = ("orientation", "mask", "width", "height", "left", "right", "top", "bottom",
                "heatX", "heatY", "heatWidth", "heatHeight", "nodeX", "buttonX",
                "windowWidth", "windowHeight", "horizontal", "vertical", "epoch", "training", "speedUp",
                "settingsVisible", "dataset", "layers")
    for key in required:
        if key not in snapshot or not isinstance(snapshot[key], (int, float)) or not math.isfinite(snapshot[key]):
            raise ValueError(f"快照缺少有效数值：{key}")
    side = phase.split("-")[0]
    orientation, mask = int(snapshot["orientation"]), int(snapshot["mask"])
    # marker 使用 UIInterfaceOrientation 名称，与 UIDeviceOrientation 的横屏左右值相反。
    expected = {"left": 4, "right": 3}.get(side)
    if expected is not None:
        check("实际横屏方向与 marker 匹配", orientation == expected, {"expected": expected, "orientation": orientation})
    elif mask & 2:
        check("支持 portrait 时必须实际进入 portrait", orientation == 1, orientation)
    else:
        check("不支持 portrait 时保持横屏", orientation in (3, 4), orientation)
    check("当前方向属于支持集合", orientation in (1, 2, 3, 4) and bool(mask & (1 << orientation)),
          {"orientation": orientation, "mask": mask})
    epsilon = 0.5
    right = snapshot["width"] - snapshot["right"]
    check("热图右沿不越过安全区", snapshot["heatX"] + snapshot["heatWidth"] <= right + epsilon,
          {"heatMaxX": snapshot["heatX"] + snapshot["heatWidth"], "safeMaxX": right})
    check("节点左沿不叠加安全区留白", abs(snapshot["nodeX"] - max(25, snapshot["left"])) <= epsilon,
          {"nodeX": snapshot["nodeX"], "expected": max(25, snapshot["left"])})
    check("按钮左沿不叠加安全区留白", abs(snapshot["buttonX"] - max(24, snapshot["left"])) <= epsilon,
          {"buttonX": snapshot["buttonX"], "expected": max(24, snapshot["left"])})
    check("窗口与根视图尺寸一致", abs(snapshot["width"] - snapshot["windowWidth"]) <= epsilon and
          abs(snapshot["height"] - snapshot["windowHeight"]) <= epsilon,
          {key: snapshot[key] for key in ("width", "height", "windowWidth", "windowHeight")})
    for key in ("statisticsHeight", "statisticsRequiredHeight", "lossHeight", "lossBottom"):
        if key not in snapshot or not isinstance(snapshot[key], (int, float)) or not math.isfinite(snapshot[key]):
            raise ValueError(f"快照缺少统计区几何：{key}")
    check("统计文字完整容纳", snapshot["statisticsHeight"] + epsilon >= snapshot["statisticsRequiredHeight"],
          {key: snapshot[key] for key in ("statisticsHeight", "statisticsRequiredHeight")})
    check("误差曲线保留可见高度且不越底部安全区", snapshot["lossHeight"] >= 48 - epsilon and
          snapshot["lossBottom"] <= snapshot["height"] - snapshot["bottom"] - 12 + epsilon,
          {key: snapshot[key] for key in ("lossHeight", "lossBottom", "height", "bottom")})
    step = phase.split("-")[1]
    if step == "trained":
        check("已训练且暂停、加速已关闭", snapshot["epoch"] > 0 and not snapshot["training"] and not snapshot["speedUp"],
              {key: snapshot[key] for key in ("epoch", "training", "speedUp")})
    elif step == "settings":
        check("设置可见且数据集与层数已恢复", bool(snapshot["settingsVisible"]) and snapshot["dataset"] == 0 and snapshot["layers"] == 3,
              {key: snapshot[key] for key in ("settingsVisible", "dataset", "layers")})
    elif step == "reset":
        check("重置后归零、暂停且设置关闭", snapshot["epoch"] == 0 and not snapshot["training"] and not snapshot["settingsVisible"],
              {key: snapshot[key] for key in ("epoch", "training", "settingsVisible")})
    return checks


def capture(device, phase, directory, args, env):
    result = {"phase": phase, "assertions": [], "screenshots": [], "errors": []}
    stem = f"{safe_name(device['name'])}-{phase}"
    try:
        app_info = Path(args.derived_data) / "Build/Products/Debug-iphonesimulator/NNPlayground.app/Info.plist"
        with app_info.open("rb") as stream:
            bundle_id = plistlib.load(stream)["CFBundleIdentifier"]
        container = run(["xcrun", "simctl", "get_app_container", device["udid"], bundle_id, "data"], env).strip()
        with (Path(container) / "Documents/layout-review.plist").open("rb") as stream:
            snapshot = plistlib.load(stream)
        result["snapshot"] = snapshot
        write_json(directory / f"{stem}.json", snapshot)
        result["assertions"] = check_snapshot(snapshot, phase)
        enumeration = run(["xcrun", "simctl", "io", device["udid"], "enumerate"], env)
        with (directory / f"{stem}-displays.txt").open("x", encoding="utf-8") as stream:
            stream.write(enumeration)
        displays = parse_displays(enumeration)
        pixels, source = target_pixels(snapshot)
        result["displaySelection"] = {"targetPixels": pixels, "source": source, "enumerated": displays}
        candidates = [display for display in displays if display["displayClass"] == "0"
                      and sorted((display["width"], display["height"])) == pixels]
        result["displaySelection"]["candidates"] = candidates
        if not candidates:
            raise ValueError("没有与快照像素尺寸匹配的集成显示器；拒绝默认显示器截图。")
        for display in candidates:
            path = directory / f"{stem}-{display['uuid']}.png"
            if path.exists():
                raise FileExistsError(f"拒绝覆盖截图：{path}")
            run(["xcrun", "simctl", "io", device["udid"], "screenshot", "--type=png",
                 "--display", display["uuid"], "--mask=black", str(path)], env)
            dimensions = png_size(path)
            result["screenshots"].append({"path": str(path), "display": display["uuid"],
                                           "mask": "black", "pixels": list(dimensions), "manualReview": "pending"})
            result["assertions"].append({"name": "PNG像素尺寸匹配目标显示器", "passed": sorted(dimensions) == pixels,
                                          "actual": list(dimensions)})
        if len(candidates) != 1:
            result["errors"].append("多个集成显示器尺寸匹配，已保存全部候选；选择有歧义，必须人工确认并修正判据。")
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        result["errors"].append(str(error))
    result["passed"] = not result["errors"] and bool(result["assertions"]) and all(item["passed"] for item in result["assertions"])
    print(f"{device['name']} {phase}: {'自动检查通过' if result['passed'] else '失败'}", flush=True)
    return result


def review_device(device, directory, args, env):
    directory.mkdir()
    command = ["xcodebuild", "test", "-project", str(ROOT / "NNPlayground.xcodeproj"),
               "-scheme", "NNPlayground", "-configuration", "Debug", "-destination",
               f"platform=iOS Simulator,id={device['udid']}", "-derivedDataPath", str(Path(args.derived_data).resolve()),
               "CODE_SIGNING_ALLOWED=NO", "-parallel-testing-enabled", "NO",
               "-only-testing:NNPlaygroundUITests/NNPlaygroundUITests"]
    # 同时保留 script 与真正 xcodebuild 的退出码，不能仅凭终端包装器返回成功。
    wrapped = ["/usr/bin/script", "-q", str(directory / "terminal.log"), "/bin/sh", "-c",
               '"$@"; code=$?; printf "\\nLAYOUT_XCODEBUILD_EXIT=%s\\n" "$code"; exit "$code"',
               "layout-review", *command]
    result = {"device": device, "command": command, "captures": [], "errors": [],
              "operationPath": "每方向启动 → 单步 → 加速开/关 → 训练3秒并暂停 → 设置切XOR再恢复Circle、增层再减回 → 点空白关闭 → 重置；以UI测试及状态断言为证据",
              "unverified": UNVERIFIED, "manualReview": "pending"}
    process = None
    selector = selectors.DefaultSelector()
    succeeded = False
    xcode_exit = None
    seen = set()
    try:
        process = subprocess.Popen(wrapped, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        selector.register(process.stdout, selectors.EVENT_READ)
        deadline = time.monotonic() + args.timeout
        pending = b""
        with (directory / "build.log").open("xb") as log:
            while selector.get_map():
                if time.monotonic() >= deadline:
                    raise TimeoutError(f"设备测试超过 {args.timeout} 秒")
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
                        exit_match = EXIT_MARKER.search(text)
                        if exit_match:
                            xcode_exit = int(exit_match.group(1))
                        match = MARKER.search(text)
                        if match:
                            phase = match.group(1)
                            if phase in seen:
                                result["errors"].append(f"重复 marker，拒绝覆盖：{phase}")
                            else:
                                seen.add(phase)
                                result["captures"].append(capture(device, phase, directory, args, env))
            process.wait(timeout=max(1, deadline - time.monotonic()))
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        result["errors"].append(str(error))
    finally:
        selector.close()
        if process and process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
        result["scriptExitCode"] = process.returncode if process else None
    result["xcodebuildExitCode"] = xcode_exit
    result["testSucceededMarker"] = succeeded
    missing = sorted(PHASES - seen)
    if missing:
        result["errors"].append(f"缺少截图阶段：{', '.join(missing)}")
    if result["scriptExitCode"] != 0 or xcode_exit != 0 or not succeeded:
        result["errors"].append("必须同时满足 script/xcodebuild 退出码为0及实际 TEST SUCCEEDED。")
    result["automatedPassed"] = not result["errors"] and all(item["passed"] for item in result["captures"])
    result["screenAdaptationVerified"] = False
    write_json(directory / "summary.json", result)
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", action="append", help="已启动模拟器 UDID 或唯一名称；可重复，默认全部已启动可用设备")
    parser.add_argument("--output", type=Path, help="全新输出目录；默认 /tmp/nnp-layout-日期时间，不覆盖已有目录")
    parser.add_argument("--derived-data", default="/tmp/nnp-layout-review-dd", help="构建缓存目录")
    parser.add_argument("--developer-dir", default=os.environ.get("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer"), help="Xcode Developer 目录")
    parser.add_argument("--timeout", type=float, default=1800, help="每设备测试超时秒数，默认1800")
    args = parser.parse_args(argv)
    if args.timeout <= 0:
        parser.error("--timeout 必须大于0")
    env = dict(os.environ, DEVELOPER_DIR=args.developer_dir)
    output = (args.output or Path("/tmp") / ("nnp-layout-" + dt.datetime.now().strftime("%Y%m%d-%H%M%S-%f"))).resolve()
    try:
        selected = devices_for(args, env)
        output.mkdir(parents=True, exist_ok=False)
        print(f"输出目录：{output}", flush=True)
        results = []
        for device in selected:
            directory = output / f"{safe_name(device['name'])}-{device['udid']}"
            results.append(review_device(device, directory, args, env))
        summary = {"createdAt": dt.datetime.now().astimezone().isoformat(), "projectRoot": str(ROOT),
                   "devices": results, "automatedPassed": all(item["automatedPassed"] for item in results),
                   "screenAdaptationVerified": False, "manualReview": "pending", "unverified": UNVERIFIED}
        write_json(output / "summary.json", summary)
        print(f"自动检查：{'通过' if summary['automatedPassed'] else '失败'}；截图仍须人工逐张检查。")
        return 0 if summary["automatedPassed"] else 1
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(f"错误：{error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
