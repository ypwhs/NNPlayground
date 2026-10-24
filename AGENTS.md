# AGENTS.md — NNPlayground

TensorFlow Playground 的 iOS 移植。Swift 5 做 UI，Objective-C++/C++ 做模型和 Core Animation。iPhone/iPad，横屏，最低 iOS 17.0。

本文件放开发任务和代码修改必须遵守的约束。架构、时序、数学、数据、渲染、UI 接线、环境与构建记录在 [docs/INTERNALS.md](docs/INTERNALS.md)。

## 语言

1. 思考、回答、文档、代码注释、commit message、PR 标题与正文一律使用中文。
2. 代码标识符、类型名、API 名称、日志、分支名保持英文或工程现有写法，不强行翻译。

## 开发流程

1. 每个开发任务从最新 `master` 新建分支；分支名用 `<类型>/<英文短横线描述>`，类型取 `feat`/`fix`/`docs`/`refactor`/`chore`。
2. 每个阶段性成果单独 commit；commit message 用中文，格式 `<类型>：<摘要>`，正文列出改动点。无关改动不混入同一 commit，已推送的提交不改写，后续阶段追加新 commit。
3. 完成后 `git push -u origin <分支>`，用 `gh pr create --base master` 创建 PR，把 PR 链接发给用户。PR 标题和正文用中文，正文包含改动、原因、验证结果、影响范围。
4. UI 开发或逻辑修改必须在 PR 中提供 `master` 与当前 PR 分支的同条件截图对比：同一设备、同一方向、同一操作路径；PR 正文用表格并排展示 `master` 和 `PR`。
5. 截图必须上传为 GitHub PR 附件，正文引用返回的 `https://github.com/user-attachments/assets/...` URL；截图不提交进仓库，不写本地路径，不引用 `raw.githubusercontent.com`。
   上传使用 `gh` 2.99.0+ 的 `gh pr create --attach` 或 `gh pr edit <number> --body-file <file> --attach <image>`；正文里的本地图片路径会被替换为附件 URL。
   当前 `gh` 不支持 `--attach` 时，用 `POST https://uploads.github.com/user-attachments/assets?name=<文件名>&content_type=image/png&repository_id=<仓库ID>` 上传，`Authorization: Bearer <token>`，把返回的 `url` 写入正文。
6. 合并前确认构建、运行、截图对比完成且 PR 为 `mergeable`；合并还必须满足「合并授权」，命令为 `gh pr merge <number> --merge`。合并后报告结果和 PR 链接。

## 合并授权

1. 任何 PR 合并都必须在当前对话中获得明确授权（例如“合并 PR #12”）。
2. 规则文本、任务类型（开发/文档/规则更新）、构建通过、截图齐全、PR 可合并状态都不构成合并授权。
3. 未获得明确授权时，只能创建 PR、发送链接、报告状态，不执行 `gh pr merge`。

## 架构与状态

1. 模型/训练/数据/布局状态统一放在 `ViewController.mm` 的文件级全局变量里；Swift 视图类只保存控件自身的 UI 状态，不再复制 `network`/`networkShape`/`dataset`/超参。
2. `Network`/`Node`/`Link` 是 C++ 类，`Node.h` 依赖 UIKit/CALayer；模型与渲染状态都在这些对象上，不存在第二套模型。
3. 改层数、结点数、数据集、激活函数、正则函数、噪声、训练比例，走 `updateDataset`/`reset`/`resetNetwork`；改学习率、batch、正则率只改全局变量，下一次 `updateWeights` 生效。
4. `networkShape` 是裸 `int*`：替换时使用 `new int[newLayers]` + `delete[] old`；`Network` 构造时只拷贝内容。默认 shape `{2,4,1}` 在 `ViewController` 顶部和 `resetNetworkShape` 两处各写一次。
5. `Node.layer` 为 1-based；`networkShape` 为 0-based；隐藏层是 `networkShape[1..layers-2]`。`layers` 总数 2–7，隐藏层 0–5，每隐藏层 1–8 个结点。
6. 输入层固定 2 个结点，输出层固定 1 个；输出层激活固定 `tanh`，输入结点直接写入坐标。`buildInputImage`、数据集、`forwardProp(inputs,2,...)`、热图前向都按 2 个输入写死；`layers` 的 2–7 边界在 `SpreadView.minLayers/maxLayers` 和 `ViewController.addLayer`/`resetNetworkShape` 中。
7. 激活枚举顺序是 `ReLU,Tanh,Sigmoid,Linear`，正则是 `None,L1,L2`；`SpreadView` 的下拉数组、`ViewController` 的强转/查表必须保持同序。学习率 11 项、正则率 10 项，两份数组在 VC 和 SpreadView 中对应。

## 并发

1. 训练循环在 `QOS_CLASS_UTILITY` 队列；`reset`/`updateDataset`/`resetNetwork`、UIKit、CALayer 只在主线程。
2. `network`、Node、Link 的后台访问都持有 `networkLock`；`onestep` 的训练段和 `getHeatData` 的位图段在该锁内，`resetNetwork` 建网/算 loss 也在该锁内。
3. `getHeatData` 在锁内完成 100×100 前向后，把更新 CALayer 的 block 异步派到主队列，随后立即 unlock。该 block 读取全局 `network`/位图时不持锁；后台下一帧 `getHeatData` 会写同一批 `outputBitmap`。
4. `generateBigOutputImage` 在 utility 队列读取全局 `network`/`inputs`，不持 `networkLock`；`resetNetwork` 在主线程删除旧网络。
5. `always` 是普通 `bool`，主线程写、训练队列读；训练线程没有 join。`resetNetworkShape`/`addLayer` 用 `always=false + sleep(8ms) + lock/unlock` 等待当前 `onestep`。
6. `runButton.isRunButton` 是图标状态（true=播放键、未训练），`always` 是训练开关；两者由主线程翻转，reset 会同时把图标设回播放并置 `always=false`。

## 渲染与布局

1. 每个 Node 的位图固定 `100×100`，索引 `(99-y)*100+x`；主热图前向坐标 `(i-50)/50`，输入缩略图 `(i-50)/50*6`（放大 6 倍再 clamp）。大图固定 `512×512`。
2. 颜色：`getColor(-output)`，+1 蓝、-1 橙、0 灰；离散化取 `getColor(-output >= 0 ? 1 : -1)`；连接线 `getColor(-weight)`，线宽 `clamp(|weight|,0.5,4)`。
3. 结点/连接线 CALayer 挂在 `self.view.layer`；输出结点只 `initNodeLayer` 设 frame，不加入视图，输出图写入 `heatMap.backgroundLayer.contents`。`Node` 析构移除自己的三个 layer 并删除入边，`Link` 析构移除 `curveLayer`；每条 Link 只由目的 Node 删除。
4. `initNodeLayer` 负责结点坐标、结点尺寸、AddButton 位置和 `_spreadView.buttonWidth`（29/36）；`SpreadView.xib` 的 frame 数据不参与实际布局。
5. 工程锁定横屏，没有旋转重排；`HeatMapView` 的两个 layer frame 在 init 时取当时的值。

## IB、资源、本地化

1. storyboard/xib 通过类名、outlet、action、`@IBInspectable` 连接；Swift 类型要出现在 `NNPlayground-Swift.h` 必须标 `@objcMembers` 或显式 `@objc`。改名必须同步 xib/storyboard/`ViewController.h`。
2. 新源文件、资源、本地化文件必须加入 `NNPlayground.xcodeproj`（显式 file reference，无 folder sync）。
3. Base storyboard/xib 为中文；运行时文案走 `Localizable.strings`（en/zh），storyboard/xib 文案走 `Main.strings`/`SpreadView.strings`（en/zh）。`ViewController.mm` 的存图/相册提示是硬编码中文。
4. 新增第三方依赖需要同时改 pbxproj；当前只有源码内置的 MBProgressHUD、Reachability。
5. `Info.plist` 只声明横屏，`CFBundleName=神经网络`；保存相册调用 `UIImageWriteToSavedPhotosAlbum`，Info.plist 没有相册权限键。

## 验证

1. 构建/运行命令、环境记录和已验证结果在 [docs/INTERNALS.md §10](docs/INTERNALS.md)。
2. `NNPlaygroundTests`、`NNPlaygroundUITests` 是模板：只含 `testExample`/`testPerformanceExample`，UI test 查询的 `Button`/switch `0`/`1` 在 storyboard 中不存在，不能作为功能覆盖。
3. 当前完整 code map、默认值、生命周期、模型 API、数学、数据集、UI 接线、性能计数、实现事实在 [docs/INTERNALS.md](docs/INTERNALS.md)。
