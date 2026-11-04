# NNPlayground 发布与上架手册

本文记录版本号、构建、素材规格、App Store Connect 填写项和发布检查清单。实现细节见 [INTERNALS.md](INTERNALS.md)，代码修改约束见 [AGENTS.md](../AGENTS.md)。

## 1. 发布目标

| 项 | 值 |
|---|---|
| App Store 名称 | 神经网络-在你的手机上训练神经网络 |
| App Store id | 1116487840 |
| Bundle ID | `com.yangpeiwen.NNPlayground2` |
| 开发者 | 杨培文（Team `W26WBSVK66`） |
| 支持设备 | iPhone / iPad，iOS 17.0+；普通手机和 iPad 横屏，iOS 27+ phone regular/regular 场景额外支持竖屏 |
| 价格 | 免费，无内购、无广告、无账号 |
| 主分类 | 教育 |

iPad 独立应用 `神经网络`（id 1115132797，bundle `com.yangpeiwen.NNPlayground`）是另一条 App Store 记录，不要与本项目混淆。本项目本次更新会让 iPhone 版变成 iPhone/iPad 通用应用。

## 2. 版本规则

- `MARKETING_VERSION` 用日期式 `YYYY.MM.DD`，例如 `2026.10.24`。
- `CURRENT_PROJECT_VERSION` 目前与 `MARKETING_VERSION` 相同，都用 `YYYY.MM.DD`，例如 `2026.10.24`；App Store 允许 version 与 build 相同。
- 同一天需要第二次上传时，不能加第四段（`2026.10.24.1` 非法）；改用更大的三段 build，例如 `2026.10.2401`，或次日日期 `2026.10.25`。首次上传前确认好后续策略。
- 两个值都在 `NNPlayground.xcodeproj/project.pbxproj` 的 Debug/Release 两处同步修改。
- App Store Connect 的版本号必须大于线上已批准版本（线上是 `1.2`），构建号必须唯一且递增；`2026.10.24` 大于旧 build `2022.11.5`。

## 3. 发布前检查

1. `git status` 干净，版本号与 `Info.plist` 变量正确。
2. `Info.plist` 包含：`ITSAppUsesNonExemptEncryption=false`、`NSPhotoLibraryAddUsageDescription`、横屏 orientations、`UIRequiresFullScreen=true`；无 `UIRequiredDeviceCapabilities`。
3. `Assets.xcassets/AppIcon.appiconset/icon-1024.png` 为 1024×1024、无 alpha。
4. Debug 与 Release 都能构建；有条件时用 Xcode Cloud 或 Distribution 证书归档。
5. iPhone 6.9" 与 iPad 13" 横屏截图齐全，尺寸分别是 2868×1320、2752×2064；中文、英文各一套。
6. App Preview 如提供，时长 15–30 秒，6.9" 规格 1920×886，H.264。
7. 隐私政策 URL、支持 URL、营销 URL 可访问；隐私政策内容与实际数据处理一致。
8. App 隐私问卷选择“不收集数据”；出口合规选择“不使用非豁免加密”；内容版权与开源致谢已确认。
9. 审核备注写清使用步骤、无账号、相册权限触发点、外部链接。
10. 提交前在真机/模拟器完整走一遍：启动、训练、暂停、切换数据集、增删层/神经元、保存图片、中英文。

## 4. 构建与上传

本机当前只有 Apple Development 证书，没有 Distribution 证书，不能直接导出 App Store 签名包。可选：

### 4.1 Xcode 归档

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild archive \
  -project NNPlayground.xcodeproj \
  -scheme NNPlayground \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath /tmp/NNPlayground.xcarchive
```

在 Xcode 的 Organizer 中 Validate App → Distribute App → App Store Connect。首次需要登录 Apple Developer 账号并让 Xcode 自动管理签名。

### 4.2 Xcode Cloud

工程已有 `NNPlayground.xcodeproj/xcshareddata/xcodecloud/manifest.json`，target 名称为“神经网络”。在 App Store Connect → Xcode Cloud 新建/运行工作流，归档后可直接分发到 TestFlight/App Store。

### 4.3 命令行验证

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project NNPlayground.xcodeproj -scheme NNPlayground \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/nnp-release CODE_SIGNING_ALLOWED=NO build
```

## 5. 截图与视频规格

### 5.1 截图

| 设备槽位 | 横屏像素 | 来源模拟器 |
|---|---|---|
| iPhone 6.9" | 2868×1320 | iPhone 18 Pro Max |
| iPad 13" | 2752×2064 | iPad Pro 13-inch (M5) |

- 仅横屏，PNG，RGB，无 alpha，单张 < 8 MB。
- 建议每个语言 3–4 张：训练后的主界面、参数面板、测试数据/二值化输出。
- 截图顺序：主界面 → 参数面板 → 测试数据；第一张放最有代表性的训练结果。
- 中文、英文各一套；App Store Connect 分别上传到对应本地化。

### 5.2 App Preview

- 6.9" 横屏：1920×886，H.264，15–30 秒，无设备边框。
- 建议内容：主界面 → 参数面板选螺旋数据集/加隐藏层 → 10× 训练 → 暂停。
- 视频里出现 Dynamic Island 是屏幕录制的一部分，可保留；不要加真人、手势或第三方素材。

### 5.3 采集方法

1. 用 `simctl` 启动对应模拟器，`status_bar override` 把时间固定为 9:41。
2. 用 XCUITest 把设备方向设为 `landscapeLeft`，驱动真实 UI；iPad 必须先转横屏，否则 `self.view.bounds` 仍是 1024×1366，节点布局会挤在顶部。
3. 截图可用 `XCUIScreen.mainScreen.screenshot` 附件；导出的 PNG 带 EXIF orientation 8，需转置后才是 2868×1320/2752×2064。
4. 视频用 `simctl io recordVideo --codec=h264`，后期裁到 15–30 秒并缩放到 1920×886。
5. 截图和视频不提交仓库，放到发布素材目录或 PR 附件。

## 6. App Store Connect 填写项

| 字段 | 中文 | 英文 |
|---|---|---|
| 名称 | 神经网络-在你的设备上训练神经网络（或保持原名“手机”） | Neural Network Playground |
| 副标题 | 可视化训练，看懂神经网络 | Train & visualize neural nets |
| 关键词 | 神经网络,深度学习,机器学习,AI,人工智能,教学,可视化,训练,模型 | neural network,deep learning,machine learning,AI,education,visualization,training,playground |
| 宣传文本 | 见发布素材 `03_元数据` | 同左 |
| 描述 | 见发布素材 `03_元数据` | 同左 |
| 版本说明 | 见发布素材 `03_元数据` | 同左 |
| 支持 URL | `https://ypw.io` | 同左 |
| 营销 URL | `https://ypw.gitbook.io/nnplayground/` | 同左 |
| 隐私政策 URL | `https://ypw.gitbook.io/nnplayground/privacy` | 同左 |
| 版权 | `© 2016-2026 杨培文` | 同左 |

隐私问卷：Data Not Collected；Tracking：No；第三方 SDK：无。
出口合规：`ITSAppUsesNonExemptEncryption=false`，选择“不使用非豁免加密”。
年龄分级：4+。
审核备注：说明无需登录、无内购/广告、全部本地计算、相册权限只在长按保存时触发、外部链接用 SFSafariViewController 打开。

## 7. 2026-10-24 发布记录

- 版本：`2026.10.24`，build `2026.10.24`（version 与 build 相同，沿用旧工程写法）。
- 变更：iPhone/iPad 通用支持、iPhone Duo 横屏适配、Duo 内屏右上角为状态栏/灵动岛/通知/定位指示预留 80pt（按 size class 区分内屏与折叠外屏）、UIScene 生命周期、安全区布局、英文文案优化、相册写入权限、出口合规声明。
- 已验证：Debug/Release 构建通过；iPhone 18 Pro Max、iPhone 17e、iPhone SE 3、iPhone Duo、iPad Air 13-inch (M4)、iPad Pro 13-inch (M5) 安装启动；中英文截图与中文 App Preview 已生成。
- 未完成：本机无 Distribution 证书，尚未归档上传；iPad 端参数面板为拉伸布局；iPhone 6.9" 横屏下右侧 loss 数字标签被压缩，只显示 loss 曲线（不影响提交）。
- 素材目录：桌面 `2026-10-24/`，包含截图、视频、元数据、隐私政策、审核备注、构建说明和校验清单。

## 8. 2026-10-26 适配复查补充

- 已修复双向横屏的左右安全区、Duo 内屏竖屏黑边及紧凑屏幕统计文字/曲线被压缩的问题。版本仍保持已确认的 `2026.10.24`，未自动改变营销或构建版本。
- 当前六台模拟器（18 Pro Max、17e、SE3、iPad Pro 13 M5、Duo 内屏、Duo 外屏）完成三种方向请求和实际操作，共 18 项 UI 测试、54 张带系统黑色遮罩原图；自动断言通过，全部原图逐张目视复核。另 10 项单元测试通过，Release 模拟器构建成功。
- iPad 左右横屏截图均正向；物理设备竖持但应用保持横屏时，portrait 请求的三张原始屏幕截图为竖画布、内容侧转 90°，不作为可直接上传的正向商店图片。普通手机和 Duo 外屏的 portrait 请求不表示启用了竖屏。
- 截图和原始日志保存在桌面 `2026-10-26/全机型最终复查/`。复用流程见 [测试说明](../tests/README.md)，必须明确选择当前点亮显示器并保留 `--mask=black`；不能用无遮罩截图判定摄像头适配。
- 以上是模拟器逐方向启动验证，不涵盖连续折叠/训练中旋转/真机。此前商店截图与视频仍为旧布局，上架前需按最终版本重新生成中英文商店截图和中文视频；此批中文调试证据不能直接替代整套上架素材。
- 54 张最新原图已作为 GitHub 附件发布至 [PR #7](https://github.com/ypwhs/NNPlayground/pull/7)，统一为每行最多两图、等宽保比例；其余状态按机型折叠，旧版截图独立保留。全部附件已逐张核验公开可读且 SHA-256 与原图一致。画廊生成器见 [build_layout_gallery.py](../tests/build_layout_gallery.py)，离线画廊和完整原图压缩包保存在本轮桌面目录。
- GitHub CLI 本身未单独登录，但已使用本仓库现有 Git 凭据完成 API 上传与正文更新。master 同条件图像对照、Distribution 签名和 App Store 上传仍未完成。未经明确授权不合并 PR。
