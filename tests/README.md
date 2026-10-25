# 模拟器布局与带遮罩截图验证

[capture_layout.py](capture_layout.py) 使用 Python 标准库，串行运行工程现有 UI 测试，在每个操作阶段读取应用的布局快照，并对**明确选中的集成显示器**执行 `simctl screenshot --display <UUID> --mask=black`。不需要 Pillow 或第三方 Python 包。

## 依赖与准备

- macOS、Python 3、完整 Xcode 与目标 iOS Simulator runtime。
- 工程的 `NNPlayground` scheme 和 `NNPlaygroundUITests/NNPlaygroundUITests` UI 测试可运行。
- 应用的 Debug 诊断钩子只有通过 `-NNPReviewOrientation <1|3|4>` 启动参数才启用；正常启动、发布版本不应输出诊断快照或强制测试方向。
- UI 测试负责真实点击训练、暂停、设置和重置，输出下面约定的 marker，并在每个 marker 后留出截图窗口（建议至少六秒）。脚本只消费测试证据，不自行模拟训练成功。
- 不要同时运行另一份同设备 UI 测试，也不要在采集窗口手动改变方向或折叠状态。共享 derived-data 时也不要并发执行多个脚本实例。

先查看设备，再手动启动需要验证的模拟器：

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun simctl list devices available
xcrun simctl boot '<目标UDID>'
open -a Simulator
```

设备已启动时无需再次 `boot`。使用 Simulator 的设备控制手动展开/折叠 Duo，确认当前目标屏幕，再运行脚本。建议内屏与外屏分别运行并保留不同输出目录；两个独立状态的截图**不等于真实连续折叠切换已经验证**。脚本不自动创建、启动、删除模拟器，不操纵折叠状态、不启动服务器、不修改应用生产代码，也不删除任何文件。

## 运行

从任意目录调用均可；工程根由脚本自身的位置定位，不依赖当前 shell 目录。

```bash
python3 tests/capture_layout.py --help

# 默认验证当前所有已启动且 available 的模拟器。
python3 tests/capture_layout.py

# 重复 --device 选择多个设备，实际运行保持串行。
python3 tests/capture_layout.py \
  --device '<第一个UDID或唯一名称>' \
  --device '<第二个UDID或唯一名称>' \
  --output /tmp/nnp-layout-manual-review-001

# Xcode不在标准位置时显式选择。
python3 tests/capture_layout.py \
  --developer-dir '/Applications/Xcode.app/Contents/Developer' \
  --device '<目标UDID>' \
  --derived-data /tmp/nnp-layout-review-dd \
  --timeout 1800
```

名称在多个 runtime 中重名时必须改用 UDID，脚本不会猜选设备。显式选择的设备必须已经启动且可用。未提供 `--output` 时创建 `/tmp/nnp-layout-年月日-时分秒-微秒`；显式输出目录必须不存在，防止覆盖旧证据。默认构建缓存为 `/tmp/nnp-layout-review-dd`，可复用但不会自动清理。

构建使用 `Debug`、`CODE_SIGNING_ALLOWED=NO`、关闭并行测试，仅执行 `NNPlaygroundUITests/NNPlaygroundUITests`。`xcodebuild test` 运行在系统 `script` 的 PTY 中，减少 marker 被输出缓冲延迟的风险。脚本同时核对：

1. `script` 的退出码为零；
2. 包装器记录的真正 `xcodebuild` 退出码为零；
3. 输出实际包含 `** TEST SUCCEEDED **`；
4. 九个阶段全部出现且不重复；
5. 每阶段几何断言、显示器选择和 PNG 尺寸检查通过。

任何一项失败，最终退出码为非零。单台设备自动检查失败后仍会继续其他设备，并汇总结果。超时会终止本脚本启动的测试进程组。

## 测试与快照协议

每个方向依次执行“启动 → 单步 → 加速开/关 → 训练三秒并暂停 → 打开设置、切换 XOR 再恢复 Circle、增加一层再减回 → 点空白关闭设置 → 重置”，输出：

```text
LAYOUT_CAPTURE_READY left-trained
LAYOUT_CAPTURE_READY left-settings
LAYOUT_CAPTURE_READY left-reset
LAYOUT_CAPTURE_READY right-trained
LAYOUT_CAPTURE_READY right-settings
LAYOUT_CAPTURE_READY right-reset
LAYOUT_CAPTURE_READY portrait-trained
LAYOUT_CAPTURE_READY portrait-settings
LAYOUT_CAPTURE_READY portrait-reset
```

方向测试之间的执行顺序不作假设。应用 Debug 钩子在当前 data container 的 `Documents/layout-review.plist` 写入以下字段：

```text
orientation mask width height left right top bottom
heatX heatY heatWidth heatHeight nodeX buttonX
windowWidth windowHeight horizontal vertical
screenPixelWidth screenPixelHeight scale epoch training speedUp
settingsVisible dataset layers
statisticsHeight statisticsRequiredHeight lossHeight lossBottom
```

统计区也做几何验收：标签实际高度必须容纳 `sizeThatFits` 所需高度；曲线至少保留 48pt，底边不得超过底部安全区减 12pt。界面采用紧凑三行文案时，仍必须包含训练误差、测试误差和训练次数。

UI 测试先同步 `XCUIDevice` 的物理朝向，再由 Debug 钩子申请对应界面方向，避免只旋转 scene 后产生倒置采集。设置关闭手势以实际可见数据按钮的相对坐标定位，不依赖折叠过程中可能滞后的 `app.frame`。

`screenPixelWidth/Height` 应来自当前 `scene.screen.nativeBounds.size`，不是机型规格表、硬编码内屏尺寸或主屏幕猜测。若没有这两个字段，仅在快照明确提供实际 `screenScale`、`displayScale` 或 `scale` 时，才允许使用 root 尺寸乘 scale；不会猜测 2x/3x。诊断钩子启用时每 0.25 秒更新，UI 测试在 marker 前至少等待 0.5 秒稳定状态。

主机脚本还验证实际交互状态：`trained` 要求 `epoch > 0 && !training && !speedUp`；`settings` 要求 `settingsVisible && dataset == 0 && layers == 3`（Circle、默认层数已恢复）；`reset` 要求 `epoch == 0 && !training && !settingsVisible`。这些状态与原始 JSON 一同保存，不能仅凭点击命令返回就认为交互成功。

每次 marker 后脚本：

1. 从本次构建产品读取 bundle identifier，用 `simctl get_app_container` 获取该设备实际容器。
2. 读取快照并保存阶段 JSON。
3. 保存 `simctl io <UDID> enumerate` 全文。
4. 枚举 `Class: Display`、`Display class: 0` 的集成显示器，按 `Default width/height` 与快照实际像素尺寸匹配（允许长短边交换）。不硬编码 UUID、screen ID、设备名或内外屏尺寸。
5. 对匹配显示器指定 `--display UUID --mask=black` 截图。零匹配直接失败；多个匹配可留下全部候选截图，但**仍报告歧义失败**，绝不静默选择默认显示器。
6. 用标准库读取 PNG 的 IHDR，检查实际像素尺寸。

## 自动断言与人工验收

所有九个阶段都检查：

- `left` 对应 `UIInterfaceOrientationLandscapeLeft`，实际 `orientation == 4`；`right` 对应 `UIInterfaceOrientationLandscapeRight`，实际 `orientation == 3`。这是 **UIInterfaceOrientation** 的名称，不是 `UIDeviceOrientation` 的同名值，也不是摄像头位于哪侧；相机侧必须通过带遮罩截图人工确认。
- `portrait` 阶段若 `mask & 2`，实际方向必须为 `1`；否则仍须保持横屏 `3/4`。
- 实际方向属于当前支持 mask。
- `heatX + heatWidth <= width - right`，几何容差 0.5pt。
- `nodeX == max(25, left)`，`buttonX == max(24, left)`，容差 0.5pt。
- 根视图与窗口宽高一致；PNG 像素尺寸与目标显示器匹配。

这些断言**不证明**物理屏幕已填满，也不证明所有 CALayer 或数据圆点都没有溢出 frame。必须逐张打开 PNG 人工检查：

- 截图非全黑、非旧屏幕、确实对应目标型号与内/外屏。
- 相机/灵动岛区域有真实黑色遮罩，热图及控制按钮未被遮挡。
- 两个横屏方向的留白合理，内屏竖屏不再出现兼容横屏的大上下黑边。
- 训练结果可见、设置面板可用、重置后状态正确；连线与热图位置一致。
- 若系统截图方向与界面方向表现异常，核对 snapshot、显示器枚举和原始 PNG，不靠文件名推断方向。

还需另行人工执行：真实连续展开/折叠、后台折叠再前台、方向锁开关、最大网络规模，以及必要的真机回归。当前脚本不会把这些项目标成已验证。

## 输出结构与结论边界

每次运行生成总 `summary.json`；每台设备有独立目录，包含：

- `summary.json`：命令、退出码、操作路径、每阶段断言、错误与未验证事项。
- `build.log`、`terminal.log`：原始测试输出与 PTY 记录。
- 含设备名和阶段的 `.json` 快照、`-displays.txt` 显示器枚举。
- 含设备名、阶段和显示器 UUID 的 `.png`，避免内外屏候选互相覆盖。

`automatedPassed` 只表示上述自动步骤通过。`manualReview` 默认 `pending`，`screenAdaptationVerified` 始终为 `false`，避免把构建成功或几何通过冒充最终适配验收。人工结论应另写到评审记录，并引用对应截图，不覆盖原始采集证据。

语法自检可将 Python 缓存写到工程外：

```bash
PYTHONPYCACHEPREFIX=/tmp/nnp-layout-pycache python3 -m py_compile tests/capture_layout.py
python3 tests/capture_layout.py --help
```
