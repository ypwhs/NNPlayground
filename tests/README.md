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

## 整理已有截图：离线总览与 GitHub 章节

[build_layout_gallery.py](build_layout_gallery.py) 仅用 Python 标准库，读取总摘要和已有 PNG；不运行模拟器、不联网、不认证、不上传、不修改 PR，也不复制、旋转、重拍图片或生成缩略图。不改变上面的采集协议及任何验收状态。每设备须有完整、不重复的九阶段，且每阶段只有一张明确显示器的截图；缺图、候选歧义、非 `black` 遮罩记录、当前 PNG 尺寸与摘要不符均明确失败。

```bash
python3 tests/build_layout_gallery.py --help

# 输出目录必须尚不存在；本批为 6 设备 × 9 阶段，共 54 张中文截图。
python3 tests/build_layout_gallery.py \
  --summary '/Users/ypw/Desktop/2026-10-26/全机型最终复查/summary.json' \
  --output-dir /tmp/nnp-gallery-review-001

# 由上传者另行准备真实附件清单；生成器本身不执行任何上传。
python3 tests/build_layout_gallery.py \
  --summary '/Users/ypw/Desktop/2026-10-26/全机型最终复查/summary.json' \
  --output-dir /tmp/nnp-gallery-review-002 \
  --attachments /tmp/nnp-uploaded-attachments.json

PYTHONPYCACHEPREFIX=/tmp/nnp-gallery-pycache python3 -m py_compile tests/build_layout_gallery.py
```

未提供附件清单时只生成 `截图总览.html`：顶部设备导航、每设备一节，等宽两列（窄屏一列），所有原图直接嵌入并延迟加载；点击打开原图，宽度随列调整、高度自动，保持原始比例。图片 URL 是相对 HTML 所在目录的 URL 编码路径，可直接离线打开；原图不复制，移动 HTML 或原图后需重新生成。已存在的输出目录（包括符号链接）及输出文件均拒绝覆盖。

附件清单格式如下；路径必须指向摘要对应的绝对 PNG 路径，`url` 必须替换为上传者取得的真实 GitHub 附件 URL，`sha256` 为该原图当前字节的 SHA-256，不能使用示例占位内容：

```json
{
  "sourceCommit": "45e674f",
  "attachments": {
    "/绝对路径/原图.png": {
      "url": "https://github.com/user-attachments/assets/00000000-0000-0000-0000-000000000000",
      "sha256": "替换为64位十六进制SHA-256"
    }
  }
}
```

提供 `--attachments` 后逐张校验附件 URL 的完整 GitHub 前缀与 UUID 格式、清单完整性及当前 PNG 的 SHA-256；任何缺失、非法 URL 或哈希不匹配都在创建输出目录前失败，绝不退回本地路径或 `raw.githubusercontent.com`。校验只针对清单与本地原图，不进行网络请求，也不能据此证明远端 URL 可访问或其远端内容一致；清单来源需由上传者负责。

通过后额外生成 `GitHub截图展示.md`，只含可拼入 PR 的截图章节，不是完整 PR 正文。每机型主展示依次为 `left-trained`、`right-trained`、`left-settings`、`left-reset`，其余五张仍以图片放入同机型的 `details`；全部 54 张都保留。使用 HTML table 每行两图，单元格宽度 50%，图片统一 `width="460"`、不固定高度，并链接同一附件原图。

两种输出均从摘要的 `createdAt` 取得日期。无清单时不猜测截图来源提交，标题标为“未标注来源提交”；提供清单时使用明确填写的 `sourceCommit`（7–40 位十六进制）。复用于其它提交时应提供正确来源提交的清单，不能把当前 Git HEAD 或本批历史提交当作新截图来源。

展示中的方向和命名边界：

- 其它四机型使用 `18ProMax`、`17e`、`SE3`、`iPadPro13M5` 友好名。两个 Duo 的标题依据所有快照的 `mask & 2` 及横/纵 `regular/regular`（RR）判定为“展开内屏”或“折叠外屏”；采集名含 `Inner` 也不能据此认定为内屏。证据冲突或阶段间改变时拒绝猜测。
- 每图保留原始阶段名和实际 `orientation`。非 Duo 展开内屏的 `portrait` 请求仍保持横屏，仅实际 `orientation=1` 标为“真竖屏”；Duo 真竖屏即使在折叠详情中也明确标记。
- iPad 的 `portrait` 请求可能生成原生竖画布、横屏内容侧转 90°；这不是 iPad 竖屏支持，不应旋转图片伪装成另一种采集结果。
- 明确声明本批中文截图、所有原图 `--mask=black`；旧 `10x` / `5 节点` 截图不属于本次 54 张九阶段证据，不替换 `trained/settings/reset` 的实际状态。

## 独立商店素材路径（2026.10.24）

[capture_appstore.py](<capture_appstore.py>) 是独立的商店采集入口；上面的 [capture_layout.py](<capture_layout.py>) 仍为固定中文诊断工具，不能替代商店中英文素材。新增 UI 测试仅扩展 [NNPlaygroundUITests.m](<../NNPlaygroundUITests/NNPlaygroundUITests.m>)；既有 `testLeft/testRight/testPortrait` 的代码与行为不变。

### 真实操作与采集边界

- `testStoreChinese/testStoreEnglish` 分别使用 `AppleLanguages=(zh-Hans)/(en)` 和对应 locale，启动后断言真实统计标签语言。
- 每种语言四张：Circle 加速训练后暂停 → 打开设置、真实切换 XOR 并增加一个隐藏层 → 关闭设置、训练并勾选测试数据 → 勾选二值化输出。
- `testStoreVideoChinese` 为独立真实交互录屏路径，覆盖训练、10x、暂停、测试数据、二值化、配置 XOR 和增层。录屏前后 marker 不用于合成帧或修改数据。
- Swift 自绘 `CheckButton` 没有专用可访问状态；脚本使用真实本地化 button label 定位，点击位置相对于当次 `XCUIElement.frame`，不硬编码机型宽高。日志保留 `STORE_CONTROL test_data/binary` 的实际标签与 frame；勾选与效果必须目检。
- `-NNPReviewOrientation 4` 只启用现有 Debug 可访问标识、诊断快照及真实横屏请求；生产源、布局、训练数据和 Release 入口不变。素材来自模拟器 Debug 运行，不声称为签名 Release 二进制或真机验证。
- 每阶段从当前 `scene.screen.nativeBounds` 与 `simctl io enumerate` 唯一匹配 `Display class: 0`，截图和原始视频都显式指定显示器 UUID、`--mask=black`。不使用默认显示器猜测。

### 当前 Apple 规格

2026-10-26 直接核对 [Apple截图规格](<https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications>)：iPhone 必需 **Dynamic Island medium**，横屏可为 `2622×1206` 或 `2556×1179`；支持 iPad 时必需13寸素材，可用 `2752×2064`。本任务另提供 large `2868×1320`。图片不能有 alpha 通道。

[Apple视频规格](<https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications>)：横屏 `1920×886`，15–30秒，H.264，最高30fps、High Profile Level 4.0，目标10–12Mbps、最大500MB。规范列出有声轨的立体声AAC 256kbps、44.1/48kHz参数；没有在该表明确写出强制音轨。应用本身无音效，本工具不捏造音频，输出无音轨，并在报告明确记为0；是否被最终上传处理接受仍须上传者核验。[Apple预览设计建议](<https://developer.apple.com/app-store/app-previews/>) 说明默认静音播放及音效/配音可选，不把默认静音等同于音轨强制性结论。

### 执行

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
PYTHONPYCACHEPREFIX=/tmp/nnp-appstore-media-dd/pycache python3 tests/capture_appstore.py \
  --device large:880330D2-CFC2-4811-B2ED-CE4F4AAC31B0 \
  --device medium:27BBFCB4-2A77-4370-90EA-8B2A69C89085 \
  --device ipad:A427034E-3014-4F6C-BEF5-03BCE18218A9 \
  --release-root '/Users/ypw/Desktop/2026-10-26/上架2026.10.24' \
  --run-id store-new-unique-id --source-commit 45e674f --video-role large --shutdown-after
```

只会依次启动显式指定的目标模拟器；`--shutdown-after` 关闭这些目标，不操作其它设备。构建缓存独占 `/tmp/nnp-appstore-media-dd`，不得与另一采集进程并发。每种角色同次只能指定一台；实际截图尺寸不符会失败，不能缩放截图假冒设备规格。

输出只位于既有发布根的 `01_截图/<run-id>`、`02_视频/<run-id>`、`07_原始素材/<run-id>`、`08_素材校验/<run-id>`。`run-id` 必须全新；不得覆盖或清理旧材料。`06_构建与发布` 完全不访问。`--source-commit` 指定本次真实生产来源，省略时默认当前HEAD；两者均解析为完整SHA，记录来源→HEAD的生产目录差异及HEAD→工作树的生产目录差异（包含暂存与未暂存改动）。有差异时在启动模拟器/创建输出目录前拒绝采集。上例的 `45e674f` 仅用于复现本批，不是未来版本的固定来源；已有素材来源记录不回写。

UI tests 由 `/usr/bin/script` 创建 PTY。必须同时具备 `scriptExitCode=0`、包装器捕获的真正 `xcodebuildExitCode=0`、实际 `TEST SUCCEEDED`、中英各四marker、几何/训练/尺寸/RGB检查全部通过。失败批次保留原日志、xcresult和截图，不能标为完成。录屏使用 `simctl recordVideo --codec=h264`；结束时仅向本脚本启动的录屏进程发送SIGINT并验证退出码。

### 安全视频导出

[export_app_preview.swift](<export_app_preview.swift>) 使用AVFoundation `AVAssetReader/AVAssetWriter` 明确编码H.264 High 4.0、最高30fps和11Mbps目标，不依赖可能导出HEVC的泛用preset。它不删除任何文件，拒绝覆盖输出/关键帧目录/报告，拒绝无效时长、越界裁切及非横屏源；错误退出码非零。等比保留整个真实画面，不叠加宣传图、不伪造界面、不裁掉安全区。完整源录屏保留。

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun swift tests/export_app_preview.swift \
  '/完整原始录屏.mov' '/全新预览.mp4' 0.5 28 \
  '/全新关键帧目录' '/全新视频校验.json'
```

参数依次为输入、全新输出、裁切起点秒、时长秒、全新关键帧目录、全新JSON报告；输出父目录必须存在。导出后重新打开成片，验证codec `avc1`、尺寸1920×886、时长15–30、名义fps≤30、H.264 SPS profile/level、无音轨及文件大小；保存首帧和3/8/13/18/23/末帧用于逐图目检。原生图像与报告的SHA-256应另存素材清单。静止界面在模拟器源录屏中为稀疏帧，成片可为可变帧率；不得把名义fps冒充最大帧率。本批另解析MP4视频轨 `mdhd/stts` 全部446个样本，最短时长1/30秒、最大30fps，名义约16.082fps；实际平均码率约4.10Mbps（编码目标11Mbps）。

### 验收要求

1. 用 `read_image` 逐张打开全部最终PNG；核对语言、遮罩、清晰度、统计文字/误差曲线、真实配置与复选框状态，无黑屏或倒置。
2. 同样打开所有视频关键帧，检查连贯真实交互、无设备外框/桌面/闪屏，确认裁切没有留出测试结束画面。
3. 自动报告保持原始 `manualReview=pending`，人工结论另写入 `08_素材校验`，引用原图与哈希，不回写或覆盖采集证据。
4. 视频无声轨的上传处理结果、真实设备验证、App Store提交审核不在本采集工具的自动验收结论内。
5. 本批采集24张且全部逐图复核；推荐22张：medium英文设置页存在生产布局自带长标题省略号，iPad英文Circle训练170次尚未收敛，这两张保留为真实原始证据但不推荐上架。其余每设备/语言仍有3–4张。iPad英文应用内标签已英文，系统状态栏日期/应用名仍中文，未改图或修改生产本地化。

### iPad保存菜单独立冒烟

新增 `testStoreIPadSaveSheetCancel`，只长按由测试数据按钮实际frame推导的热图中心，等待“取消”，使用 `XCUIScreen` 保存keepAlways附件，然后取消并断言主界面仍可操作；不会点击“确定”或修改照片权限。通过 `-only-testing:NNPlaygroundUITests/NNPlaygroundUITests/testStoreIPadSaveSheetCancel` 单独选择，仍须以PTY包装并检查真实退出码。

2026-10-26在iPad13M5/iOS27.0 Debug上两次通过：无崩溃，系统将保存菜单显示为屏幕中央320×126pt的Sheet，无popover箭头，取消后返回正常。不能据此宣称较旧iPadOS、真机、实际保存或照片授权已验证。Xcode在测试结束后诊断收集报simctl查找error72，但测试本身1例0失败、真实退出码0；需分别记录而不是忽略日志或误报应用崩溃。

## iPhone Duo 双屏商店截图（2026-11-20 补充）

Apple 的 iPhone Duo 展示位有两组物理尺寸，**同一个 `IPHONE_DUO` display class 同时容纳两组**，不能用一组冒充另一组：

| 形态 | 横屏像素 | 竖屏像素 | 对应显示 |
|---|---|---|---|
| 折叠外屏 | 2034×1398 | 1398×2034 | 合盖后的外屏 |
| 展开内屏 | 2853×2007 | 2007×2853 | 展开后的内屏 |

来源：<https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications>（2026-11-20 核对）。

### 折叠态必须手动设置

Duo 的折叠/展开状态由模拟器设备窗口手动切换，`capture_layout.py` 与 `capture_appstore.py` 都**不控制折叠态**，只根据应用报告的 `scene.screen.nativeBounds` 与 `simctl io <UDID> enumerate` 中唯一的 `Display class: 0` 显示器匹配截图，并断言实际像素等于目标尺寸。折叠态不对时脚本直接失败，不会把折叠图当展开图上传。

设备名不代表折叠态（`NNP-Duo-Inner` 的实测像素曾在折叠态）。判定以每次采集的 `layout-review.plist` 尺寸与 `traitCollection` 为准：横/纵都 `regular/regular`（RR）为展开内屏，`compact/compact`（CC）为折叠外屏；`build_layout_gallery.py` 用同一规则并结合 `mask & 2` 复核。

### 已采素材（2026-10-26，中文诊断批次）

`capture_layout.py` 当时的 6 设备 54 张中包含 18 张 Duo 原图，全部为 `--mask=black`、RGB 无 alpha：

- 展开内屏（`iPhone Duo` / `436D8A55-DF48-4239-AE78-25254ABD9891`）：9 张，横屏 `2853×2007`（left/right × trained/settings/reset）+ 竖屏 `2007×2853`（portrait × trained/settings/reset）。
- 折叠外屏（`NNP-Duo-Inner` / `E12037A9-D206-49B4-AE60-8B758C5D086C`）：9 张，`2034×1398`（left/right/portrait × trained/settings/reset）。
- 目录：`/Users/ypw/Desktop/2026-10-26/全机型最终复查/<设备名>-<UDID>/`；判定与哈希在 `summary.json`，人工验收在 `验收记录.md`。

这批是**中文布局诊断流程**（trained/settings/reset），可直接用于中文商店的 Duo 槽位；它不含中英文商店四阶段（Circle 训练 / 参数面板 / 测试数据 / 二值化输出），英文 Duo 图须用下面的商店采集重新生成。

### 商店采集命令

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
# 展开内屏：先在设备窗口手动展开，确认 simctl io enumerate 的唯一 class 0 为 2853×2007
PYTHONPYCACHEPREFIX=/tmp/nnp-appstore-media-dd/pycache python3 tests/capture_appstore.py \
  --device duo-unfolded:436D8A55-DF48-4239-AE78-25254ABD9891 \
  --release-root '/Users/ypw/Desktop/2026-11-20-上架' \
  --run-id duo-unfolded-01 --source-commit <生产来源SHA> --shutdown-after

# 折叠外屏：先在设备窗口手动折叠，确认唯一 class 0 为 2034×1398
PYTHONPYCACHEPREFIX=/tmp/nnp-appstore-media-dd/pycache python3 tests/capture_appstore.py \
  --device duo-folded:E12037A9-D206-49B4-AE60-8B758C5D086C \
  --release-root '/Users/ypw/Desktop/2026-11-20-上架' \
  --run-id duo-folded-01 --source-commit <生产来源SHA> --shutdown-after
```

角色 `duo-unfolded`/`duo-folded` 只校验尺寸，不修改设备的折叠态；两台设备可复用同一台，只需在运行前切到目标形态。若展开态无法设置，不要用 2034×1398 的图代替 2853×2007。

### 上传映射（App Asset Library）

- display class：`IPHONE_DUO`；placement group：`IPHONE_DUO_PROFILE`。
- 同一 group 同时接受 `i2034x1398a0`、`i2853x2007a0` 及其竖屏 spec；App Store 版本每个 group **上限 10 张**，所以折叠 + 展开总数不能超过 10。
- 顺序请求按 group 统一提交；折叠图与展开图放在同一组内按上传顺序展示。
