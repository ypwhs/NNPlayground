#!/usr/bin/env python3
"""只读整理九阶段中文截图，生成离线总览及经哈希核验的 GitHub 截图章节。"""

import argparse
import datetime as dt
import hashlib
from html import escape
import json
import os
from pathlib import Path
import re
import struct
import sys
from urllib.parse import quote

PHASES = tuple(f"{side}-{step}" for side in ("left", "right", "portrait")
               for step in ("trained", "settings", "reset"))
MAIN_PHASES = ("left-trained", "right-trained", "left-settings", "left-reset")
STEPS = {"trained": "训练后暂停", "settings": "打开设置", "reset": "重置后"}
ORIENTATIONS = {1: "真竖屏", 3: "右横屏", 4: "左横屏"}
ATTACHMENT_URL = re.compile(
    r"https://github\.com/user-attachments/assets/"
    r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}")
# 摘要不记录提交，不把当前 HEAD 或某批历史提交冒充为截图来源。
DEFAULT_COMMIT = "未标注来源提交"
NOTES = (
    "本批为中文界面截图，所有原图均使用 --mask=black；仅引用原图，不重拍、不复制、不旋转、不生成缩略图。",
    "方向以 snapshot 为准：非 Duo 展开内屏的 portrait 请求保持横屏；仅实际 orientation=1 才称为真竖屏。"
    "left/right 是 UIInterfaceOrientation 的名称，不代表相机所在侧。",
    "iPad 的 portrait 请求可能产生原生竖画布、横屏内容侧转 90°，不代表 iPad 支持竖屏。",
    "旧 10x / 5 节点截图不属于本次九阶段截图；严格保留 trained/settings/reset 阶段名，不以旧图替换当前状态。",
    "本页仅整理已有证据，不更改摘要中的验收状态，也不证明连续旋转、连续折叠切换或真机验证。",
)


def read_json(path):
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def png_pixels(path):
    with path.open("rb") as stream:
        header = stream.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError(f"不是有效 PNG/IHDR：{path}")
    return list(struct.unpack(">II", header[16:24]))


def device_title(device, captures):
    identity = re.sub(r"[^a-z0-9]", "", (device["name"] + device.get("deviceTypeIdentifier", "")).lower())
    if "duo" in identity:
        states = {(bool(item["snapshot"]["mask"] & 2),
                   item["snapshot"]["horizontal"] == item["snapshot"]["vertical"] == 2)
                  for item in captures}
        if states == {(True, True)}:
            return "Duo 展开内屏", "按全部快照判定：mask & 2 非零且横/纵 size class 均为 regular（RR），不依据设备名。"
        if states == {(False, False)}:
            return "Duo 折叠外屏", "按全部快照判定：mask & 2 为零且非 RR，不依据设备名（即使采集名含 Inner）。"
        raise ValueError(f"Duo 的 mask & 2 / RR 证据冲突或采集中发生变化，拒绝猜测内外屏：{device['udid']}")
    for tokens, title in (
        (("iphone18promax",), "18ProMax"),
        (("iphone17e",), "17e"),
        (("se3", "iphonese3rdgeneration"), "SE3"),
        (("ipad13m5", "ipadpro13inchm5"), "iPadPro13M5"),
    ):
        if any(token in identity for token in tokens):
            return title, ""
    return device["name"], ""


def load_summary(path):
    summary = read_json(path)
    date = dt.datetime.fromisoformat(summary["createdAt"].replace("Z", "+00:00")).date().isoformat()
    devices, seen = [], set()
    if not summary["devices"]:
        raise ValueError("摘要没有设备。")
    for entry in summary["devices"]:
        device, captures = entry["device"], entry["captures"]
        phases = [item["phase"] for item in captures]
        if len(phases) != len(PHASES) or set(phases) != set(PHASES):
            raise ValueError(f"设备必须包含不重复的完整九阶段：{device['udid']}，实际={phases}")
        shots = {}
        for capture in captures:
            phase, snapshot = capture["phase"], capture["snapshot"]
            for key in ("orientation", "mask", "horizontal", "vertical"):
                if type(snapshot[key]) is not int:
                    raise ValueError(f"快照字段必须为整数：{device['udid']} / {phase} / {key}")
            if snapshot["orientation"] not in ORIENTATIONS:
                raise ValueError(f"未知实际方向：{device['udid']} / {phase} / {snapshot['orientation']}")
            if len(capture["screenshots"]) != 1:
                raise ValueError(f"每阶段必须有一张明确显示器的原图，不接受缺图或歧义候选：{device['udid']} / {phase}")
            shot = capture["screenshots"][0]
            image = (path.parent / shot["path"]).resolve(strict=True)
            if image in seen:
                raise ValueError(f"同一原图被重复用于多个阶段：{image}")
            seen.add(image)
            if shot["mask"] != "black":
                raise ValueError(f"原图没有 --mask=black 记录：{image}")
            if png_pixels(image) != shot["pixels"]:
                raise ValueError(f"当前 PNG 尺寸与摘要不一致：{image}")
            shots[phase] = {"path": image, "pixels": shot["pixels"], "snapshot": snapshot, "phase": phase}
        title, evidence = device_title(device, captures)
        devices.append({"title": title, "evidence": evidence, "udid": device["udid"], "shots": shots})
    return date, devices


def verify_attachments(path, devices):
    manifest = read_json(path)
    commit, entries = manifest["sourceCommit"], manifest["attachments"]
    if not isinstance(commit, str) or not re.fullmatch(r"[0-9a-fA-F]{7,40}", commit):
        raise ValueError("附件清单 sourceCommit 必须为 7–40 位十六进制提交号。")
    if not isinstance(entries, dict):
        raise ValueError("附件清单 attachments 必须为以绝对 PNG 路径为键的对象。")
    normalized = {}
    for key, value in entries.items():
        if not Path(key).is_absolute():
            raise ValueError(f"附件键不是绝对 PNG 路径：{key}")
        image = Path(key).resolve()
        if image in normalized:
            raise ValueError(f"附件键重复指向同一原图：{key}")
        normalized[image] = value
    urls = {}
    for device in devices:
        for shot in device["shots"].values():
            image = shot["path"]
            if image not in normalized:
                raise ValueError(f"附件清单缺少原图：{image}")
            entry = normalized[image]
            if not isinstance(entry, dict):
                raise ValueError(f"附件条目必须是包含 url 与 sha256 的对象：{image}")
            url, expected = entry.get("url", ""), entry.get("sha256", "")
            if not isinstance(url, str) or not ATTACHMENT_URL.fullmatch(url):
                raise ValueError(f"附件 URL 必须是 https://github.com/user-attachments/assets/UUID：{image}")
            if not isinstance(expected, str) or not re.fullmatch(r"[0-9a-fA-F]{64}", expected):
                raise ValueError(f"附件 sha256 缺失或格式错误：{image}")
            digest = hashlib.sha256()
            with image.open("rb") as stream:
                for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                    digest.update(chunk)
            if digest.hexdigest() != expected.lower():
                raise ValueError(f"附件 sha256 与当前 PNG 不一致：{image}")
            urls[image] = url
    return commit, urls


def caption(device, shot):
    side, step = shot["phase"].split("-")
    orientation = shot["snapshot"]["orientation"]
    request = {"left": "左横屏请求", "right": "右横屏请求", "portrait": "portrait 竖屏请求"}[side]
    actual = f"{ORIENTATIONS[orientation]}（orientation={orientation}）"
    if side == "portrait" and orientation != 1:
        actual = "仍保持" + actual
    text = f"{shot['phase']} · {STEPS[step]} · {request} → {actual}"
    if device["title"] == "iPadPro13M5" and side == "portrait" and orientation != 1:
        if shot["pixels"][0] < shot["pixels"][1]:
            text += "；原生竖画布、横屏内容侧转 90°，非 iPad 竖屏支持"
    return text


def heading(date, commit, devices):
    count = sum(len(device["shots"]) for device in devices)
    return f"本次全机型中文截图（提交 {commit} · {date} · {len(devices)} 设备 / {count} 张）"


def render_html(date, commit, devices, output_dir):
    title = escape(heading(date, commit, devices))
    parts = [f'''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>
* {{ box-sizing: border-box; }}
body {{ margin: 0 auto; max-width: 1600px; padding: 24px; font-family: system-ui, sans-serif; color: #172033; background: #f4f6fa; }}
a {{ color: #1659a8; overflow-wrap: anywhere; }}
nav {{ display: flex; flex-wrap: wrap; gap: 12px; margin: 20px 0; }}
.notice, figure {{ background: white; padding: 16px; border: 1px solid #dbe0e8; border-radius: 10px; }}
section {{ margin: 32px 0; }}
.grid {{ display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; align-items: start; }}
figure {{ margin: 0; min-width: 0; }}
figcaption {{ margin-bottom: 12px; line-height: 1.65; overflow-wrap: anywhere; }}
img {{ display: block; width: 100%; height: auto; }}
@media (max-width: 720px) {{ body {{ padding: 12px; }} .grid {{ grid-template-columns: minmax(0, 1fr); }} }}
</style></head><body id="top"><header><h1>{title}</h1><div class="notice">''']
    parts.extend(f"<p>{escape(note)}</p>" for note in NOTES)
    parts.append("<p>点击任意图片打开完整原图；全部图片直接嵌入、延迟加载，保留原始比例。保持原图位置即可离线打开。</p></div><nav aria-label=\"设备导航\">")
    parts.extend(f'<a href="#device-{index}">{escape(device["title"])}</a>'
                 for index, device in enumerate(devices, 1))
    parts.append("</nav></header><main>")
    for index, device in enumerate(devices, 1):
        parts.append(f'<section id="device-{index}"><h2>{escape(device["title"])}（9 张）</h2>')
        parts.append(f'<p>UDID：<code>{escape(device["udid"])}</code> {escape(device["evidence"])}</p><div class="grid">')
        for phase in PHASES:
            shot = device["shots"][phase]
            url = escape(quote(Path(os.path.relpath(shot["path"], output_dir)).as_posix(), safe="/"))
            label = escape(caption(device, shot))
            width, height = shot["pixels"]
            parts.append(f'<figure><figcaption><strong>{label}</strong><br>{width} × {height} px · --mask=black</figcaption>'
                         f'<a href="{url}" target="_blank" rel="noopener"><img src="{url}" alt="{label}" loading="lazy" decoding="async"></a></figure>')
        parts.append('</div><p><a href="#top">返回顶部导航</a></p></section>')
    return "\n".join(parts + ["</main></body></html>\n"])


def render_table(device, phases, urls):
    parts = ["<table>"]
    for start in range(0, len(phases), 2):
        parts.append("<tr>")
        for phase in phases[start:start + 2]:
            shot = device["shots"][phase]
            label, url = escape(caption(device, shot)), escape(urls[shot["path"]])
            parts.append(f'<td width="50%" valign="top"><strong>{label}</strong><br>'
                         f'<a href="{url}"><img src="{url}" alt="{label}" width="460"></a></td>')
        if len(phases[start:start + 2]) == 1:
            parts.append('<td width="50%"></td>')
        parts.append("</tr>")
    return "\n".join(parts + ["</table>"])


def render_markdown(date, commit, devices, urls):
    parts = ["## " + heading(date, commit, devices), ""]
    parts.extend(f"> {note}\n>" for note in NOTES)
    for device in devices:
        parts.extend(["", f"### {escape(device['title'])}（9 张）", ""])
        if device["evidence"]:
            parts.extend([device["evidence"], ""])
        parts.extend([render_table(device, MAIN_PHASES, urls), "", "<details>"])
        portrait_note = "；含真竖屏 orientation=1" if any(
            shot["snapshot"]["orientation"] == 1 for shot in device["shots"].values()) else "；portrait 请求不等于真竖屏"
        parts.extend([f"<summary>其余 5 张：right-settings / right-reset / portrait 三阶段{portrait_note}</summary>", "",
                      render_table(device, tuple(phase for phase in PHASES if phase not in MAIN_PHASES), urls), "", "</details>"])
    return "\n".join(parts) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--summary", required=True, type=Path, help="capture_layout.py 生成的总 summary.json")
    parser.add_argument("--output-dir", required=True, type=Path, help="必须尚不存在的新输出目录；不复制原图")
    parser.add_argument("--attachments", type=Path, help="可选：sourceCommit 与绝对 PNG 路径到 url/sha256 的 JSON 清单")
    args = parser.parse_args()
    try:
        output_dir = args.output_dir.expanduser().absolute()
        if output_dir.exists() or output_dir.is_symlink():
            raise ValueError(f"拒绝覆盖已有输出目录或符号链接：{output_dir}")
        output_dir = output_dir.resolve()
        date, devices = load_summary(args.summary.expanduser().resolve(strict=True))
        commit, urls = DEFAULT_COMMIT, None
        if args.attachments:
            commit, urls = verify_attachments(args.attachments.expanduser(), devices)
        outputs = {"截图总览.html": render_html(date, commit, devices, output_dir)}
        if urls is not None:
            outputs["GitHub截图展示.md"] = render_markdown(date, commit, devices, urls)
        # 全部输入先验证；目录及文件均独占创建，失败时绝不退回本地/raw 图片链接。
        output_dir.mkdir(parents=True, exist_ok=False)
        for name, content in outputs.items():
            with (output_dir / name).open("x", encoding="utf-8") as stream:
                stream.write(content)
            print(output_dir / name)
        return 0
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
        print(f"错误：{error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
