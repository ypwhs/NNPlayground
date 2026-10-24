# NNPlayground 内部实现参考

本文记录代码路径、数据流和实现事实。修改约束见 [AGENTS.md](../AGENTS.md)。

- 工程：target `NNPlayground`，scheme `NNPlayground`，bundle id `com.yangpeiwen.NNPlayground2`，Swift 5，C++ `gnu++0x`，最低 iOS 17.0，iPhone/iPad 横屏。
- 依赖：无 SPM/CocoaPods；`MBProgressHUD`、`Reachability` 为源码内置。
- 术语：`layers` 为总层数（含输入/输出），hidden = `layers - 2`；`networkShape` 为每层结点数（0-based）；epoch 为遍历训练集次数 × `trainBatch`；小图为结点 100×100 缩略图，大图为 512×512 导出图。

## 1. 源码结构

```
NNPlayground/
├── main.m                         UIApplicationMain
├── AppDelegate.h/.m               AppDelegate + SceneDelegate；SceneDelegate 加载 Main.storyboard 并创建窗口
├── ViewController.h/.mm           应用状态机 + 数据生成 + 训练 + 渲染调度 + 布局
├── Network.h/.mm                  MLP 结构、forward/backProp/updateWeights（C++）
├── Node.h/.mm                     Node/Link 数学 + CALayer + 位图
├── Util.h/.mm                     激活/正则函数、颜色、随机数
├── HeatMapView.swift              热力图容器（输出图 + 样本点）
├── LossView.swift                 训练/测试 loss 曲线
├── CheckButton.swift              复选框
├── Views/
│   ├── SpreadView.swift           配置面板逻辑
│   ├── Base.lproj/SpreadView.xib  配置面板布局
│   ├── DropDownView.swift         下拉菜单浮层
│   ├── Cells/DropDownCell.*       下拉行
│   ├── Buttons/*.swift            8 个自绘控件
│   └── Sliders/EasySlider.swift   自绘 thumb
├── Base.lproj/Main.storyboard     主界面 + IBOutlet/IBAction
├── en.lproj/, zh-Hans.lproj/      本地化
├── Assets.xcassets                图标 + 4 张数据集缩略图
├── Images.xcassets                Checkmark
├── MBProgressHUD.h/.m             导出图 HUD
├── Reachability.h/.m              仅桥接头引用
├── NNPlayground-Bridging-Header.h 只 import Reachability.h
├── NNPlayground.entitlements      工程引用
└── NNPlayground 2.entitlements    工程未引用
```

## 2. 生命周期与线程

### 2.1 执行体

| 执行体 | 内容 |
|---|---|
| 主线程 | UI、`reset`/`updateDataset`/`resetNetwork`、配置面板回调、单步按钮触发的 `onestep` |
| `QOS_CLASS_UTILITY` 全局队列 | `train()` 的循环；长按导出的 `generateBigOutputImage` |
| 主队列异步 block | `getHeatData` 的 CALayer 更新、`LossView.addLoss`、`updateLabel`、HUD 进度 |

- `xiancheng:` 把 block 派到 utility 队列；`ui:` 把 block 派到主队列。
- `networkLock` 是 `NSLock`。`onestep` 的训练段、`getHeatData` 的位图段、`resetNetwork` 的建网/算 loss 段在该锁内。
- `always` 是普通 `bool`，主线程写、utility 队列读。

### 2.2 启动

`SceneDelegate` 的 `scene:willConnectToSession:options:` 加载 `Main.storyboard`，创建 `UIWindow`、设置 rootViewController 并 makeKeyAndVisible；随后执行：

```
viewDidLoad
  initColor()
  dataset = Circle
  updateDataset()
    └─ 生成 500 点 → reset()
        ├─ runButton.isRunButton = true
        ├─ always = false
        ├─ lock/unlock
        ├─ ui { lossView.clearData() }
        └─ resetNetwork()
  initSpreadView()
  runButton 宽度约束：view 高 320 → 39，否则 46
  layoutIfNeeded
  heatMap 添加 0.5s 长按 → longpressAction:
  resetNetwork()
```

- `resetNetwork` 第一次执行时 `_spreadView` 仍为 nil；`initNodeLayer` 内对 `_spreadView.addNodeButton`/`subNodeButton` 的消息发送给 nil。
- `resetNetwork` 的流程：

```
lock
  epoch = 0; lastEpoch = 0
  oldNetwork = network
  network = new Network(networkShape, layers, activation, None)
  buildInputImage()
unlock
initNodeLayer()          // 内部调用 getHeatData()
lock
  计算 testLoss（test set）与 trainLoss（train set）
  delete oldNetwork
unlock
heatMap.setData(train...)
if isShowTestData: heatMap.setTestData(...)
updateLabel()
```

- 初始 `trainLoss` 在 `resetNetwork` 中除以 `testNum`。
- `initNodeLayer` 在锁内计算坐标并设置按钮 frame，解锁后调用 `getHeatData`，随后重新加锁添加 sublayer。

### 2.3 训练

```
runNN:
  always = sender.isRunButton
  sender.isRunButton = !sender.isRunButton
  lastEpochTime = (int)now
  xiancheng { train() }

train:
  while (always):
    if now - lastTrainTime > 1/120:
      lastTrainTime = now
      onestep()
    sleep(0.01/120)

onestep:
  lock
    testLoss = Σ_test 0.5(o-t)² / testNum       // 训练前
    loss = 0; trainEpoch = 0
    for n in 0..<trainBatch:
      for i in 0..<trainNum:
        forwardProp(trainx1[i], trainx2[i])
        backProp(trainy[i])
        loss += 0.5(o-t)²
        trainEpoch++
        if (trainEpoch+1) % batch == 0: updateWeights(lr, λ)
    epoch += trainBatch
    trainLoss = loss / trainNum / trainBatch
    ui { lossView.addLoss(trainLoss, testLoss) }
  unlock
  speed = 1/(now-lastEpochTime); lastEpochTime = now
  getHeatData()
  updateLabel()
```

- 单步按钮 `oneStep:` 在主线程直接调用 `onestep`。
- 训练线程的 `while (always)` 在 `always` 变 false 后于下一轮条件判断退出。
- `lastEpochTime` 赋值为 `(int)` 秒；`speed` 取整后显示在 `fpsLabel`。

### 2.4 重置与设置

| 操作 | 入口 | 状态变化 | reset |
|---|---|---|---|
| 播放/暂停 | `runNN:` | 翻转 `always` 与 `runButton.isRunButton` | 否 |
| 单步 | `oneStep:` | 同步执行一次 `onestep` | 否 |
| 重置 | `resetClick:` | `updateDataset` | 是 |
| 加速 | `speedUp:` | `trainBatch` 1↔10；`speedUpLabel.hidden` 随 `isSpeedUp` 翻转 | 否 |
| 数据集 | `setCircleData` 等闭包 | 改 `dataset` | 是 |
| 训练比例 | `setRatio` | `ratioOfTrainingData=(n+1)/10`；与 `lastRatio` 不同才 `updateDataset` | 条件 |
| 噪声 | `setNoise` | `noise=n/20`；与 `lastNoise` 不同才 `updateDataset` | 条件 |
| batch | `setBatchSize` | `batch=n+1` | 否 |
| 学习率 | `setLearningRate` | 11 项查表 | 否 |
| 激活 | `setActivation` | `activation=(ActivationFunction)n` | 是 |
| 正则 | `setRegularization` | `regularization=(RegularizationFunction)n` | 是 |
| 正则率 | `setRegularizationRate` | 10 项查表 | 否 |
| 隐藏层 +/- | `addLayer` | 重建 `networkShape`、改 `layers` | 是 |
| 结点 +/- | `addNode` | `networkShape[layerNum] += delta`，clamp 1..8 | 是 |
| 面板重置 | `Regenerate` | 见 §7.3 | 多次 |
| 显示测试数据 | `showTestData:` | 翻转 `isShowTestData`，改 dataLayer | 否 |
| 离散化 | `changeDiscretize:` | 翻转 `discretize`，重建输入缩略图，重画 | 否 |
| 配置面板 | `createSpread:` | 旋转按钮，`spreadView.showInView(window)` | 否 |
| 长按热图 | `longpressAction:` | action sheet → `generateBigOutputImage` → 相册 | 否 |

### 2.5 热力图刷新

```
getHeatData:
  lock
  for j in 0..<100:
    for i in 0..<100:
      inputs[0] = (i-50)/50
      inputs[1] = (j-50)/50
      network->forwardProp(inputs, 2, i, j, discretize)
  ui {
    outputNode = network[layers-1][0]
    heatMap.backgroundLayer.contents = outputNode.getImage()
    for i in 0..<layers-1:
      for node:
        if layers < 5 && i > 0: node.updateVisibility()
        node.nodeLayer.contents = node.getImage()
    for link: link.updateCurve()
  }
  unlock
```

- `ui` block 在 unlock 之后异步执行，读取全局 `network`、`layers`、`networkShape` 和结点位图。
- 训练线程在下一轮 `onestep` 结束后再次调用 `getHeatData`，写同一批 `outputBitmap`。
- 输出结点由 `heatMap.backgroundLayer` 显示；输入/隐藏结点由 `nodeLayer` 显示。

## 3. 模型层

### 3.1 Util.h/.mm

- 枚举：`ActivationFunction {ReLU, Tanh, Sigmoid, Linear}`、`RegularizationFunction {None, L1, L2}`。
- 激活 lambda：ReLU `max(0,x)`、Tanh `tanh(x)`、Sigmoid `1/(1+e^-x)`、Linear `x`；对应导数分别为分段常数、`1-tanh²`、`s(1-s)`、1。
- 正则 lambda：None `w`/`w`；L1 `|w|`/`sign(w)`；L2 `0.5w²`/`w`。
- `Activation` / `Regularization` 保存 `double(*)(double)`，Network/Link 构造时拷贝。
- `drand(a,b) = arc4random()/2^32*(b-a)+a`，区间 [a,b)。
- `initColor()` 填 256 级 `positiveColor`/`negativeColor`：
  - positive：(234,234,234) → (246,184,113)
  - negative：(234,234,234) → (97,167,213)
- `getColor(x)`：x>0 用 positive，否则 negative；|x| clamp 到 1；返回 `r | g<<8 | b<<16`。
- `positiveColor`/`negativeColor` 在头文件中以 `static` 指针定义，每个翻译单元各有一份；`initColor`/`getColor` 定义在 `Util.mm`，使用该 TU 的数组。

### 3.2 Node / Link

Node 字段：

| 字段 | 含义 |
|---|---|
| `layer` | 1-based 层号；输入层 1，输出层 `numLayers` |
| `id` | 1-based 层内下标 |
| `inputLinks` / `outputs` | 入边/出边；Link 指针同时被两端引用 |
| `bias` | 偏置 |
| `totalInput` / `output` | 前向值 |
| `outputDer` / `inputDer` | 反向值 |
| `accInputDer` / `numAccumulatedDers` | bias 梯度累计 |
| `activation` | 本结点激活函数 |
| `outputBitmap` | `100×100` `unsigned int` 位图 |
| `nodeLayer` / `shadowLayer` / `triangleLayer` | 3 个 CALayer |
| `nodeImage` | `getImage` 返回的 UIImage 引用 |

Link 字段：

| 字段 | 含义 |
|---|---|
| `source` / `dest` | 两端 |
| `weight` | 初始 `drand(-1,1)` |
| `errorDer` / `accErrorDer` / `numAccumulatedDers` | 权重梯度累计 |
| `regularization` | 本连接的正则函数指针 |
| `curveLayer` | CAShapeLayer |

方法：

- `Node::updateOutput()`：`totalInput = bias + Σ w·src.output`，`output = activation.output(totalInput)`。
- `Node::updateOutput(x,y,discretize)`：先算标量，写 `outputBitmap[(99-y)*100+x]`。
- `Node::updateBitmapPixel(x,y,value,discretize)`：只写位图，供输入缩略图。
- `Node::getImage()`：`CGBitmapContextCreate` 把位图包成 UIImage；每次调用新建 `CGColorSpaceRef`。
- `Node::initNodeLayer(frame)`：圆角 5、2px 黑边、阴影、右侧三角形。
- `Node::updateVisibility()`：`max|inWeight| * max|outWeight| < 1.5` 时 `shadowLayer.backgroundColor` 设为 clear，边框/三角形设为黑 20% alpha；否则三者黑色。
- `Link::initCurve()`：source 右中点 → dest 左中点，下发一条、上回一条贝塞尔，形成封闭细长路径；dest 端点 y 按 `source->id` 偏移 `d=min(height/15,4)`。
- `Link::updateCurve()`：`lineWidth=clamp(|w|,0.5,4)`，`strokeColor=getColor(-w)`，CATransaction 关闭隐式动画。
- `Node::~Node`：remove 3 个 layer；`delete` 每条入边；`delete outputBitmap`。
- `Link::~Link`：remove curveLayer。出边不删除。

### 3.3 Network

构造顺序：

1. 把 `ActivationFunction`/`RegularizationFunction` 映射为函数指针。
2. 输出层使用 `outputActivation = Tanh`；其他层使用传入的激活函数。
3. `numLayers = ls`，`networkShape` 拷贝 `ns[]`。
4. 逐层建 Node：`layer=layerIdx+1`、`id=i+1`，每个 Node 分配 `outputBitmap`。
5. 对 `layerIdx>=1`，把上一层每个结点连到当前结点：`new Link(prev,node,reg)`，压入 `prev->outputs` 和 `node->inputLinks`。

API：

| 方法 | 行为 |
|---|---|
| `forwardProp(inputs,size)` | size 与输入层结点数不等时打印错误并返回 -1；写输入层 output；逐层 `updateOutput`；返回输出结点 output |
| `forwardProp(inputs,size,x,y,discretize)` | 同上，并对每个 layer>=1 的结点写位图 |
| `backProp(target)` | 输出层 `outputDer=o-t`；从最后一层往前算 inputDer、link.errorDer、上一层 outputDer |
| `updateWeights(lr,λ)` | 从 layer 1 开始更新 bias 与入边权重；累计量清零 |
| `forEachNode(ignoreInputs,fn)` | 遍历结点；无调用点 |
| `getOutputNode()` | 返回 `network.back()[0]`；无调用点 |

所有权：Network 拥有 Node；Node 拥有入边；Link 由 dest 删除。析构顺序为删 Node（连带入边）→ 删层 vector。

## 4. 数学

### 4.1 前向

```
totalInput = bias + Σ_j w_ji * out_i
output     = φ(totalInput)
```

- 输入结点 output 直接等于输入坐标。
- 输出层 φ 为 tanh，输出范围 (-1,1)。
- 输出结点数为 1。

### 4.2 反向

```
输出层: outputDer = o - t
每个结点: inputDer = outputDer * φ'(totalInput)
每条入边: errorDer = inputDer * source.output
隐藏层: outputDer = Σ_{出边} w * dest.inputDer
累计: node.accInputDer += node.inputDer; node.numAccumulatedDers++
      link.accErrorDer += link.errorDer; link.numAccumulatedDers++
```

`backProp` 对最后一层设置 `outputDer=o-t`，随后逐层计算；`inputDer` 已包含本结点激活导数。

### 4.3 参数更新

```
bias   -= lr * accInputDer / numAccumulatedDers
weight -= lr * (accErrorDer + λ * reg'(weight)) / numAccumulatedDers
```

- 正则项同样除以 `numAccumulatedDers`。
- 仅 `numAccumulatedDers > 0` 时更新并清零。
- 更新发生在 `(trainEpoch+1) % batch == 0`，即每 `batch` 个训练样本一次。
- 一个 `onestep` 末尾不足 `batch` 的累计量保留，下一次 `onestep` 继续累加；reset 时随旧网络丢弃。

### 4.4 指标

- `testLoss`：训练前在 test set 上计算，除以 `testNum`。
- `trainLoss`：本步全部样本误差和 / `trainNum` / `trainBatch`。
- `resetNetwork` 的初始 `trainLoss` 除以 `testNum`。
- `epoch` 每步加 `trainBatch`。
- `speed`：`1/(now-lastEpochTime)`，取整。
- 无 accuracy、交叉熵、混淆矩阵。

## 5. 数据集

`DATA_NUM = 500`。`updateDataset` 调用生成函数写 `rawx1/rawx2/rawy`，洗牌后按 `trainNum=ratio*500` 顺序切分，再 `reset`。

洗牌：

```
for i in 0..<500:
  r = floor(drand(0,500))
  swap(rawx1[i], rawx1[r]); swap(rawx2[i], rawx2[r]); swap(rawy[i], rawy[r])
```

| 数据集 | 生成 | 标签 |
|---|---|---|
| Circle | 前 250 个半径 0.7–0.9，后 250 个半径 0–0.5，角度 `drand(0,2π)`；`x=r cosθ`、`y=r sinθ` | 对加噪坐标 `(x+dx, y+dy)` 计算 `x²+y² < 0.25 ? 1 : -1`；存储的 x/y 不加噪 |
| Two Gaussian | 500 点，`label = i>250 ? 1 : -1`；`variance=0.14+0.5*noise`；x/y 独立 `normal(label*0.4, variance)` | 前 251 个 -1，后 249 个 +1；存储坐标已加噪 |
| XOR | x/y ∈ `drand(-0.8,0.8)`；按符号各加 ±0.05 padding | 对加噪坐标计算 `x*y>0 ? 1 : -1`；存储坐标不含噪声 |
| Spiral | 两臂各 250 点；`r=(i/250)*0.8`，`t=1.75*(i/250)*2π`（第二臂 +π）；`x=r sin t`、`y=r cos t` | 第一臂 +1，第二臂 -1；坐标加 `drand(-1,1)/6*noise` |

`normalRandom(mean,variance)` 用拒绝采样生成单位圆内两点，再 `sqrt(-2 ln(s)/s)*v1`，返回 `mean + variance*result`。

`ratioOfTrainingData` 由滑条产生 0.1–0.9，`trainNum` 为 50 的倍数，`testNum=500-trainNum`。Gaussian 坐标可超出 [-1,1]；`HeatMapView` 绘制时跳过越界点，训练/测试数组不筛。

## 6. 渲染

### 6.1 位图与颜色

- 每个 Node 一个 `100×100` `unsigned int` 位图，`imageWidth=100`。
- 写入索引 `(99-y)*100+x`；数组行 0 为图像顶部，`99-y` 把数学 y 向上映射到存储行。
- 值取 `getColor(-output)`：+1 蓝、-1 橙、0 灰。
- 离散化取 `getColor(-output >= 0 ? 1 : -1)`。
- 输入缩略图：`(i-50)/50*6`、`(j-50)/50*6`，放大 6 倍后 clamp。
- 颜色按 `r | g<<8 | b<<16` 打包，配合 `kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast`。
- 2026-10-24 启动截图：上输入结点左侧橙、右侧蓝；下输入结点上侧蓝、下侧橙。

### 6.2 坐标系

| 空间 | 原点/朝向 | 用途 |
|---|---|---|
| 数据 | 中心 (0,0)，x 右，y 上，约 [-1,1] | 网络输入、样本点、热图 |
| 位图 | (0,0) 左上，行向下；写入时 `99-y` | 缩略图/热图 |
| View | (0,0) 左上，y 向下 | CALayer frame、结点、样本点 |
| dataLayer 绘制 | `x_px = w/2*x + w/2`，`y_px = h/2 - h/2*y` | 样本点 |

热图前向覆盖 `x,y ∈ [(0-50)/50, (99-50)/50] = [-1,0.98]`。

### 6.3 图像输出

- 结点缩略图：`Node::getImage()` 把 100×100 位图包成 UIImage，设置 `nodeLayer.contents`。
- 主热图：输出结点位图设置到 `heatMap.backgroundLayer.contents`。
- 导出大图：`generateBigOutputImage` 用 512×512 位图，`x=(x-256)/256`、`y=(y-256)/256`，逐行前向写 `outputBitmap[(511-y)*512+x]`，每行 `hud.progress` 主线程更新；最后 `UIImageWriteToSavedPhotosAlbum`。
- `HeatMapView.initLayer` 在 init 时按当时的 frame 设置 `backgroundLayer`/`dataLayer` 的 frame。

### 6.4 样本点

- `setData`：清空 `dataLayer.sublayers`；每个训练点先画 6×6 白底圆，再画 4×4 实心圆（+1 蓝、-1 橙）；越界点跳过。
- `setTestData`：不清空 `dataLayer`；每个测试点先画 6×6 黑底圆，再画 4×4 实心圆。
- 显示测试数据时测试点叠加在训练点之上；取消时 `setData` 清空重画。
- reset 时先 `setData`，`isShowTestData` 为真再 `setTestData`。

### 6.5 结点与连接线布局

`initNodeLayer`：

```
frame = heatMap.frame
outputNode.initNodeLayer(frame)
margin = heatMap.frame.origin.y
x = 25；屏幕长边为 812 或 896 时 x = 65
y = margin
width  = (frame.origin.x - x) / (layers - 1)
height = (view.frame.height - margin) / 8
nodeW  = min(50, height - 5*screenScale)
```

- 第 i 层（i<layers-1）第 j 个结点 frame 为 `(x + width*i, y + height*j, nodeW, nodeW)`。
- 输出结点只调用 `initNodeLayer(frame)`，不加入视图。
- 隐藏层 i>0 的 `addNodeButton[i-1]` 放在 `(frame.x, subNodeButtonY + 2*buttonWidth)`，`subNodeButton[i-1]` 放在 `(frame.x, subNodeButtonY)`，尺寸 `nodeW`。
- 布局完成后按屏高设置 `_spreadView.buttonWidth = 29/36`。
- `nodeLayer`/`triangleLayer` 加到 `view.layer`；`shadowLayer` 和每条 `curveLayer` 插入 index 0；storyboard 子视图的 layer 在同一父层中。
- `Link::initCurve` 在 reset 建网时按当时 frame 生成路径；结点 frame 变化不会自动重算路径。

### 6.6 LossView

- `addLoss(a,b)` 向 train/test 数组 append，`setNeedsDisplay`。
- `draw`：空数组返回；取两组数据的 max/min，`min*=0.9`，`delta=(max-min)*1.1`；元素数 <5000 时逐点画，否则按 `i*n/5000` 抽样 5000 点；训练灰、测试黑。
- 元素数为 1 时 x 坐标按 `width*i/(n-1)` 计算。

## 7. UI 层

### 7.1 Main.storyboard

| Outlet | 控件 |
|---|---|
| `heatMap` | `HeatMapView` 160×160 |
| `outputLabel` | UILabel，Courier New 12 |
| `fpsLabel` | UILabel，位于 heatMap 内右上 |
| `lossView` | `LossView` |
| `runButton` | `RunButton` |
| `speedUpLabel` | UILabel “10x”，默认 hidden |

| Action | 控件 | 行为 |
|---|---|---|
| `runNN:` | RunButton | 开始/暂停训练 |
| `speedUp:` | AccelerateButton | `trainBatch` 1↔10 |
| `oneStep:` | ResetButton（`isResetButton=NO`） | 单步 |
| `resetClick:` | ResetButton（`isResetButton=YES`） | 重置 |
| `showTestData:` | CheckButton | 显示/隐藏测试点 |
| `changeDiscretize:` | CheckButton | 离散化输出 |
| `createSpread:` | ConfigureButton | 打开配置面板 |

左侧按钮从上到下：重置、播放、单步、加速、配置。右侧：热图、两个 CheckButton、loss 文本、loss 曲线。

### 7.2 ViewController 闭包接线

`initSpreadView` 中赋值：

| SpreadView 闭包 | VC 行为 |
|---|---|
| `regenerate` | `resetNetworkShape()`：shape `{2,4,1}`、layers 3、reset |
| `introduce(url)` | `exOpenURL` → `SFSafariViewController` |
| `addNode(layer,delta)` | `networkShape[layer] += delta`，clamp 1..8，reset，返回新值 |
| `setRatio(n)` | `ratio=(n+1)/10`，变化时 `updateDataset` |
| `setNoise(n)` | `noise=n/20`，变化时 `updateDataset` |
| `setBatchSize(n)` | `batch=n+1` |
| `setCircleData` 等 | `dataset=...`，`updateDataset` |
| `setLearningRate(n)` | 11 项查表 |
| `setActivation(n)` | enum 强转，reset |
| `setRegularization(n)` | enum 强转，reset |
| `setRegularizationRate(n)` | 10 项查表 |
| `addLayer` | 重建 shape，reset |

`addLayer` 的 shape 算法：

```
newLayers = spreadView.layers
oldShape = networkShape
shape = new int[newLayers]; shape[0] = 2
for i in 1..<layers-1: shape[i] = oldShape[i]
repeat = oldShape[layers-2]
layers = newLayers
for i in 当前i..<layers-1: shape[i] = repeat
shape[layers-1] = 1
delete[] oldShape
```

层数减少时同一函数执行，最后一层隐藏层被去掉。

### 7.3 SpreadView

- `layers` 默认 3，`minLayers=2`，`maxLayers=7`，`maxNodes=8`。
- `showInView(window)`：frame 设为 window bounds，加入 window，背景动画到黑 40%；点空白（`touch.view == self`）或 `hide()` 移除。
- `makeUI` 在首次 `didMoveToSuperview` 执行一次：`setCircleButton.isChosen=true`，设置数据集按钮/加层按钮宽度约束，创建并添加 6 组 add/sub 按钮，索引 1..5 隐藏。
- `addLayerButtons`：加层时 `layers += 1`，调用 `addLayer`；减层时 `layers -= 1`，调用 `addLayer`；更新按钮显隐、enable 状态、标题（单/复数）。
- `addNodeAction`：按 sender 在 6 个按钮中的位置得到层号，调用 `addNode`；结点数到 1 或 8 时禁用对应按钮，另一端 enable。
- `setSpacing`：把滑条值吸附到 `(max-min)/total` 的整数倍；ratio 总档 8、noise 10、batch 29。
- 滑条映射：ratio `(n+1)/10`；noise `n/20`；batch `n+1`。
- 下拉项：
  - 学习率 `0.00001,0.0001,0.001,0.003,0.01,0.03,0.1,0.3,1,3,10`，默认 index 5
  - 激活 `ReLU,Tanh,Sigmoid,Linear`，默认 1
  - 正则 `None,L1,L2`，默认 0
  - 正则率 `0,0.001,0.003,0.01,0.03,0.1,0.3,1,3,10`，默认 0
- 下拉回调 `showSelectedLabel(name,num)` 设置按钮标题、收起浮层、调用 VC setter。
- `Regenerate` 顺序：
  1. `regenerate?()`（VC 重置 shape/layers + reset）
  2. `setCircleData?()`（circle + reset）
  3. `resetAlpha(setCircleButton)`
  4. 三个滑条 `setValue` 并调用对应 action（ratio 0.5、noise 0、batch 10）
  5. `layers=2`，隐藏索引 1..5 的按钮，`addLayerAction(addLayerButton)`（加回第 3 层 + reset）
  6. 四个下拉调用 `showSelectedLabel`（学习率、激活、正则、正则率）；激活/正则的 VC 闭包各 reset 一次
- 介绍按钮先 `hide()` 再调用 `introduce`，URL 为 `https://ypwhs.gitbooks.io/nnplayground/content/`。

### 7.4 自绘控件

| 类 | 绘制/状态 |
|---|---|
| `RunButton` | 深蓝圆；`isRunButton` 为 true 画播放三角，false 画暂停双竖线 |
| `ResetButton` | 白圆；`isResetButton` 为 true 画顺时针箭头，false 画单步图标 |
| `AccelerateButton` | 白圆 + 双三角；`isEquilateralTriangle`、`frontWidthRatio` |
| `AddButton` | 白圆 + 蓝加号/减号；`isAddButton=false` 只画减号 |
| `SelectButton` | `isChosen` 时填 `fillColor`；`didMoveToSuperview` 设置圆角、背景色、标题颜色 |
| `SelectDataButton` | 背景图按钮；`isChosen` true→alpha 1，false→alpha 0.4；黑 2px 边框 |
| `ConfigureButton` | 贝塞尔齿轮 |
| `DropDownButton` | 白底、蓝下划线、右侧小三角、标题左对齐 |
| `CheckButton` | 14×14 圆角框 + 对勾；`checked` 由 VC 翻转 |
| `EasySlider` | 蓝色圆形 thumb，直径默认 20 |

`@IBDesignable`/`@IBInspectable` 属性被 storyboard/xib 引用。

### 7.5 下拉与滑条

- `DropDownView` 加到 window；`tableView` frame 为按钮下方，行高等于按钮高度，总高超过窗口底部时截断并可滚动。
- 点空白（`touch.view == containerView`）收起。
- `DropDownCell` 含 `detailLabel` 和 `isSelectedImage`；选中行显示 Checkmark。
- 滑条档位：ratio 9 个位置（0..8，值=(n+1)/10）、noise 11 个（0..10，值=n/20）、batch 30 个（0..29，值=n+1）。
- 默认 batch 滑条 value 1/3，吸附到 9/29，回调 `batch=10`。

### 7.6 本地化与资源

- 运行时文案：
  - `Localizable.strings`：`show_loss`、4 个滑条模板、`set hidden layer(s)`、`CFBundleDisplayName`
  - `SpreadView.strings`：面板 label/按钮，按 object ID
  - `Main.strings`：storyboard 的 fps、loss 占位、10x、两个 checkbox
  - `LaunchScreen.strings`：启动图文字
- Base storyboard/xib 为中文；en.lproj 为英文。
- 图片：`Assets.xcassets` 有 AppIcon 与 `CircleData`/`GaussianData`/`ExclusiveOrData`/`SpiralData`（200×200）；`Images.xcassets` 有 Checkmark。
- 存图/相册提示为 `ViewController.mm` 中的中文字符串，未走 `NSLocalizedString`。
- 工程没有 `InfoPlist.strings`。

## 8. 代码事实

- `resetNetwork` 初始 `trainLoss = loss / testNum`。
- `Node::~Node`：`delete outputBitmap`；分配处为 `new unsigned int[...]`。
- `Node::getImage`：每次 `CGColorSpaceCreateDeviceRGB()`，无 `CGColorSpaceRelease`。
- `getHeatData`：UI block 在 `unlock` 后执行；block 读取全局 `network`/位图；后台下一帧 `getHeatData` 写同一 `outputBitmap`。
- `generateBigOutputImage`：在 utility 队列读 `network`/`inputs`，不持 `networkLock`；`resetNetwork` 在主线程 `delete oldNetwork`。
- `longpressAction`：`UIAlertControllerStyleActionSheet`，未设置 `popoverPresentationController.sourceView`/`sourceRect`。
- Photo：`longpressAction` 中 action sheet 的 `ok` handler 调用 `UIImageWriteToSavedPhotosAlbum`；Info.plist 声明 `NSPhotoLibraryAddUsageDescription`，未声明 `NSPhotoLibraryUsageDescription`（只写不读）。
- `rNone` 返回 `w`；`updateWeights` 对每条边计算 `λ*reg'(w)/N`。
- `always` 无 atomics；训练线程在 `always=false` 后于下一轮 while 退出。
- `resetNetworkShape`/`addLayer`：`always=false` + `sleep(0.008)` + `lock/unlock`；无线程 join。
- `LossView.draw`：元素数 1 时按 `(n-1)` 计算 x；`clearData` 只清数组。
- 长按：`HeatMapView.initLayer` 添加 1s recognizer（空实现）；`ViewController` 对同一 heatMap 添加 0.5s recognizer（存图）。
- `Info.plist`：`UIApplicationSceneManifest` 指向 `SceneDelegate`；`UIMainStoryboardFile` 已移除；无 `UIRequiredDeviceCapabilities`；`CFBundleName=神经网络`；横屏 orientations（iPhone/iPad 各 2 项）；`UIRequiresFullScreen=true`；`ITSAppUsesNonExemptEncryption=false`；`NSPhotoLibraryAddUsageDescription`。
- `NNPlayground.entitlements`：`com.apple.security.app-sandbox`、`com.apple.security.network.client`；`NNPlayground 2.entitlements` 未在 pbxproj 中引用。
- `Reachability`：仅 `NNPlayground-Bridging-Header.h` 引入；无 Swift/ObjC 调用点。
- `Network::forEachNode`、`Network::getOutputNode`、`HeatMapView.setBackground`：无调用点。
- `Localizable.strings` 有 `CFBundleDisplayName` 键；工程无 `InfoPlist.strings`。
- `SpreadView.xib`：root 852×393；部分数据集按钮 frame y 到 748；安装的约束中四个数据按钮纵向排列（`top = 上一个 bottom + 10`）。
- `SelectButton.didMoveToSuperview`：`layer.backgroundColor` 与 `titleLabel?.textColor` 都设为 `fillColor`；`fillColor` 默认白色。
- `initNodeLayer`：先用 `_spreadView.buttonWidth` 布置 add/sub 按钮，后按屏高赋值为 29/36。
- Duo 内屏横屏 `self.view.bounds` 约 951×669，`safeAreaInsets` 仍为 0；`duoTopInset` 对 phone 且高度 >600 返回 80，热力图 top 约束从 108 调到 188，节点 y 从 24 移到 104，8 槽位高度按剩余空间重算；普通 iPhone/iPad 返回 0。用于避开右上角状态栏、灵动岛、通知横幅、定位/录制指示。
- `SelectDataButton`：选中 alpha 1，未选 0.4。
- `DropDownView`：行高取按钮高度；总高超过窗口底部时截断并允许滚动。
- 启动截图（2026-10-24）：`fps:0`，训练/测试误差 0.530/0.574，训练次数 0。
- 历史分支 `WKWebView`（2022）含 `DropWebView.swift`/`ShowWebView.swift`；HEAD 删除这两个文件；介绍页使用 `SFSafariViewController`。

## 9. 性能与内存

- 每个 Node 位图：`100*100*4 = 40,000` 字节。
- 默认网络：2+4+1=7 个结点，2×4 + 4×1 = 12 条连接。
- 最大网络：layers 7、5 个隐藏层各 8 结点 → 2+5×8+1 = 43 个结点；连接 2×8 + 4×8×8 + 8×1 = 280 条。
- 每次 `onestep`：test 500 次前向；训练 `trainBatch*500` 次前向+反向；热图 10,000 次前向 + 每结点 10,000 次像素写。
- 导出大图：512×512 = 262,144 次前向；每行一次主线程 HUD 更新。
- 主线程同步执行：`reset` 的建网/初始 loss、单步的完整 `onestep`、`getHeatData` 的 10,000 次前向（单步路径）、`LossView` 重绘。
- 每帧创建的 UIImage：输入+隐藏结点各一张 + 输出结点一张；每个 Link 改一次颜色/线宽。
- `LossView.train`/`test` 数组只 append；`clearData` 赋空数组。
- `getImage` 每次新建颜色空间，未释放；`Node` 位图按 `delete`（非 `delete[]`）释放。

## 10. 构建与运行记录

- 构建命令（2026-10-24 09:41）：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project NNPlayground.xcodeproj -scheme NNPlayground -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/nnp-dd CODE_SIGNING_ALLOWED=NO build
```

结果：`** BUILD SUCCEEDED **`。产物在 `/tmp/nnp-dd/Build/Products/Debug-iphonesimulator/NNPlayground.app`。

- `xcodebuild -list`：targets `NNPlayground`、`NNPlaygroundTests`、`NNPlaygroundUITests`；configurations Debug/Release；scheme `NNPlayground`。
- `xcodebuild -showBuildSettings`：`IPHONEOS_DEPLOYMENT_TARGET = 17.0`、`PRODUCT_BUNDLE_IDENTIFIER = com.yangpeiwen.NNPlayground2`、`SWIFT_VERSION = 5.0`、`TARGETED_DEVICE_FAMILY = 1,2,6`、`SUPPORTED_PLATFORMS = iphoneos iphonesimulator`。
- 构建产物 Info.plist：`MinimumOSVersion=17.0`、`UIDeviceFamily=[1,2]`、`UIApplicationSceneManifest`、无 `UIRequiredDeviceCapabilities`、横屏 orientations、`UIRequiresFullScreen=true`、`CFBundleName=神经网络`、`ITSAppUsesNonExemptEncryption=false`、`NSPhotoLibraryAddUsageDescription`。
- 2026-10-24 09:37 在 iPhone 15 / iOS 17.2 安装启动成功（pid 51391），截图路径 `/tmp/nnp-initial.png`；画面为 2 输入、4 隐藏、1 输出热力图，右侧 loss 文本 0.530/0.574/0。
- 2026-10-24 09:40 后 `simctl list runtimes` 输出为空；`simctl list devices available` 无可用设备；`/Applications/Xcode.app` 下无 `Simulator.app`。
- 2026-10-24 14:00 后 Xcode 27.1 的 iOS 27.0/27.1 runtime 可用；`simctl` 可无 GUI 启动设备。iPhone 18 Pro Max（2868×1320）、iPhone 17e、iPhone SE 3、iPhone Duo、iPad Air 13-inch (M4)（2048×2732）、iPad Pro 13-inch (M5)（2064×2752）均可安装运行。
- 2026-10-24 14:50 起用临时 XCUITest 驱动真实 UI：`XCUIDevice.orientation = landscapeLeft` 解决 iPad 竖屏启动时布局按 1024×1366 计算的问题；`XCUIScreen.mainScreen.screenshot` 附件为 1320×2868/2064×2752，带 EXIF orientation 8，需 `ImageOps.exif_transpose` 后才是横屏尺寸。
- 2026-10-24 15:00 版本号更新为 `2026.10.24`（build `2026.10.24`）；Debug/Release 构建通过；Release 签名证书仍只有 Apple Development，App Store 分发需补 Distribution 证书或在 Xcode Cloud 归档。
- 2026-10-25 01:20 修复 Duo 内屏右上角系统区域：`duoTopInset` 预留 80pt，热力图/节点下移；用 Clock 系统通知横幅在 Duo 上验证，热力图、loss 和训练按钮不再被通知遮挡；普通 iPhone 18 Pro Max 回归布局不变。

## 11. 发布准备记录（2026-10-24）

- 发布目标：iPhone 版 `神经网络`（App Store id `1116487840`，bundle `com.yangpeiwen.NNPlayground2`）的通用更新；该更新首次把 iPhone 应用扩展到 iPad。iPad 独立应用 id `1115132797` 不受影响。
- 版本：`MARKETING_VERSION = 2026.10.24`，`CURRENT_PROJECT_VERSION = 2026.10.24`。采用日期式版本，version 与 build 相同；同日重传需换更大的三段 build（如 `2026.10.2401`），不能加四段。
- 素材：iPhone 6.9"（2868×1320）与 iPad 13"（2752×2064）横屏截图，中文/英文各 4 张；中文 App Preview 26.5 秒、1920×886、H.264。
- App Store 文案、隐私政策、审核备注、截图顺序和提交清单见桌面 `2026-10-24/` 目录（不提交进仓库）。
- 已知限制：iPhone 17 / 18 系列横屏 440pt 高度下，右侧 loss 数字标签被 Auto Layout 压缩为 0 高度，只显示 loss 曲线；iPad 正常。该问题不影响构建与提交，若本次要修，需单独改布局并重新截取对比图。
- 签名：`security find-identity` 只有 `Apple Development: Peiwen Yang (8H535XCXVJ)`；无 Distribution 证书，无法本机导出 App Store 签名包。Xcode Cloud manifest 已存在，推荐走 Xcode Cloud 归档或补证书。

