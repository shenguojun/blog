---
title: "Tetris Native揭秘|有道词典动态化运营引擎"
date: 2023-11-13T16:37:24+08:00
---

> Tetris Native是有道词典端侧动态渲染引擎，目前已作为多个业务的运营投放容器，支持跨端UI动态化发布及多种样式，助力有道词典流量变现。《Tetris Native揭秘》系列文章将详细介绍Tetris Native的设计理念和详细落地方案。

在介绍Tetris Native之前，先给Tetris打个广告。Tetris是H5低代码平台，一直以来都被有道词典广泛使用。该平台已经在我们的会员、课程、社区等业务投放页中得到应用，显著提升了运营和市场投放页面的开发迭代效率。

![WX20231031-100717 (1)](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_10_31_mJpsAM.png)

<center>Tetris页面展示</center>

Tetris Native是一套动态化投放技术方案，旨在提升运营和广告投放效率。与Tetris不同的是，Tetris Native在客户端本地进行渲染，它属于端侧的服务驱动UI（Server-Driven UI）技术。服务端下发的数据包括图片、文本、视频和卡片等UI组件的样式布局及内容。通过服务驱动UI的方式，我们能够在客户端不需要更新版本的情况下，新增或调整现有页面的UI组件内容和布局，实现快速的运营开发迭代。

我们先来一睹为快，下面是有道词典线上投放的动态化运营版面展示。

![img](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_10_30_kWXnjP.png)

<center>案例一：有道词典头部动态版面运营位</center>

![首页底部运营位](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_10_30_vxR7Ob.png)

<center>案例二：有道词典底部动态版面运营位</center>

![其他位置](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_11_01_yZpwEw.jpg)

<center>案例三：线上其他动态化版面展示</center>

如上述案例所示，Tetris Native已在有道词典中大量使用。就使用方式而言，针对不同的业务场景，可以有三种使用方式。

![render-method](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_11_03_dYpER1.png)

<center>三种使用方式</center>

1. 第一种方式：服务端下发带有业务数据的页面描述DSL，客户端进行渲染。
   优势：在云端合成业务数据和页面样式描述DSL，客户端渲染DSL JSON。样式修改或新增只需更改投放后台，无需客户端发版。适合样式需要频繁修改的业务，但要求投放后台和服务高度配合，后台需处理业务数据的同时考虑端侧布局样式构建。目前主要用于首页快速运营迭代的地方。
2. 第二种方式：服务端下发纯业务数据，客户端构建页面渲染DSL后进行渲染。
   优势：服务端仅下发业务数据，无需额外改动。客户端结合业务数据生成页面描述DSL并进行渲染。与第一种开发模式相比，投放后台和服务端无感知，不过依赖客户端发版。客户端可通过构建DSL JSON实现双端样式一致，重用已有UI逻辑，降低业务开发难度。适合日常样式改动较少的页面。
3. 第三种方式：服务端下发纯业务数据和绘制DSL渲染JS脚本，端侧执行JS脚本生成页面渲染DSL后进行渲染。
   优势：不需改动现有服务端业务数据逻辑，与第二种方式类似对投放后台和服务端无感知，但不依赖客户端发版。客户端通过执行JS脚本生成DSL JSON来实现动态修改样式需求，无需侵入现有服务端和投放系统逻辑。适用于业务数据变化不大的情况下修改样式，不过这对端侧渲染性能有一定影响。目前尚未在线上使用。

以上介绍了动态渲染引擎Tetris Native的三种使用方式，以及它们的优缺点和适用业务场景。接下来，我们将回顾设计动态渲染引擎的初衷，解决的业务困境，需求分析和技术选型过程，以及介绍目前Tetris Native的整体开发进度。

## 需求分析

在使用动态化投放方案之前，我们面临的主要问题是无法快速进行投放试验。由于不同的投放样式需要进行端侧开发和发布，整个流程较为耗时。尤其是在首页设计了近20种不同的投放样式时，按照传统的开发流程，需要在安卓和iOS端各开发20种样式。而且，如果日后需要对这些样式进行修改或新增，还需要进行额外的发布。显然，传统的开发方式需要转变为更加灵活的方式。总结来说，我们面临的问题主要有两个方面：一是传统开发方式无法支持运营快速进行投放试验；二是研发效率和上线流程妨碍了快速迭代的实现。

运营投放具有以下特点：主要以卡片组合为投放样式，每个卡片承载不同的业务投放。一个投放版面由多种业务卡片组合而成，页面包含多个投放版面。单个业务素材会在不同样式的卡片中出现。

![投放示例](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_11_06_CEuXD9.png)

<center>素材、卡片、版面、页面之间的关系</center>

针对上述的业务需求，因为运营投放的样式多为卡片的组合，我们可以考虑开发一套以卡片为基础的动态运营投放系统。由于我们业务的落地页基本支持deeplink的跳转方式，因此我们仅需要处理卡片的deeplink跳转以及对应的展示和点击统计逻辑即可。

对于端侧，可以总结有以下的技术需求：

1. 支持动态发布（服务端下发卡片和素材内容及布局）
2. 支持多种卡片展示样式（平铺、横竖滚动、横竖列表等）
3. 支持多种卡片内容格式（文本、图片、动图、视频等）
4. 渲染速度快
5. 服务端下发数据尽量少保证传输速度快
6. 对卡片展示和点击进行自动上报

对于投放后台，有以下技术需求：

1. 支持创建素材并绑定素材跳转的deeplink落地页
2. 支持编辑投放的版面样式，并绑定对应的素材
3. 生成素材内容和样式描述DSL，加入需要统计上报字段
4. 支持编辑投放的生效规则和投放策略

在明确了上述的技术需求之后，我们对业内不同的技术方案进行评估，考虑其可行性、适用性和性能等因素。这样的分析对比有助于我们选择最适合我们需求的技术方案，并为后续的系统设计和开发提供指导。

## 技术选型

就实现客户端无需发版即可实现UI动态渲染而言，有多种技术选择。首先，可以采用像React Native或WEEX这类类似Web开发的方式。这种方法允许在移动端使用前端框架如Vue进行UI渲染，提供了丰富的UI控件，并具备成熟的社区支持。然而，与原生控件相比，性能略有损耗，而且存在一些交互差异。

另一种选择是使用Flutter动态化，例如58的Fair、腾讯的mxflutter以及阿里的karken。这些方法支持前端开发方式，并通过底层调用Flutter实现跨平台动态渲染。然而，这些方案在成熟度和开发维护成本方面尚有待改进。

还有一种方法是使用Webview来解决UI动态修改而无需发版的问题，但Webview的性能较差，不适合在高频用户路径中直接使用。

最后，可以考虑采用服务驱动UI（Server-Driven UI）的方案，如阿里的Tangram和优酷的Gaia-X。这些方法通过DSL描述来指导客户端构建原生UI，需要对支持的UI控件进行DSL定义，然后在客户端进行视图构建、布局和渲染。虽然这些方法目前支持的UI控件较少，但由于使用原生控件，性能较好。

| 技术选择                                   | 优点                                                    | 缺点                                        |
| ------------------------------------------ | ------------------------------------------------------- | ------------------------------------------- |
| React Native/WEEX                          | - 类似Web开发方式 <br />- 丰富的UI控件 <br />- 社区支持 | - 性能略有损耗 <br />- 存在交互差异         |
| Flutter动态化（如Fair、mxflutter、karken） | - 支持前端开发方式 <br />- 跨平台动态渲染               | - 成熟度和开发维护成本待改进                |
| Webview                                    | - 无需发版实现UI修改 <br />- 适用于低频使用路径         | - 性能较差 <br />- 不适合在高频用户路径使用 |
| 服务驱动UI（Tangram、Gaia-X）              | - 使用原生控件<br />- 性能较好                          | - 支持的UI控件较少                          |

考虑到我们项目的需求，主要以卡片组合形式为主，并且对于UI交互要求不太复杂。同时，我们对于性能和开发效率有着较高的要求。基于这些考虑，我们决定采用服务驱动UI的技术方案来推进项目。接下来，我们将对服务端驱动UI技术方案进行详细的业内方案对比。

在服务端驱动用户界面（Server Driver UI）的技术方案中，我们需要仔细考虑两个关键方面，即渲染引擎和领域特定语言（DSL）的选择。这两个方面的决策将直接影响我们后续的开发方案。因此，我们需要对这些方面进行深入的分析和评估，以确保最终选择的方案能够满足我们的需求并具备高度的可扩展性和灵活性。渲染引擎的选择涉及到考虑性能、跨平台支持、可定制性以及对现有技术栈的集成能力等因素。而在选择DSL语言时，我们需要评估其表达能力、易用性、可维护性以及对业务逻辑的良好支持等特性。通过深入研究和比较，我们将能够制定出一个既具备技术优势又能够满足业务需求的综合解决方案。

### 基于Flex布局框架

开源的跨平台Flex布局引擎，例如[facebook/yoga](https://github.com/facebook/yoga)以及[Tencent/Taitank](https://github.com/Tencent/Taitank)，提供了底层的跨平台渲染布局引擎。利用这些引擎可以实现跨平台的动态渲染框架。使用这种技术栈比较有代表性的动态化框架有美团的[MTFlexbox](https://tech.meituan.com/2019/09/19/litho-practice-in-dynamic-program-mtflexbox.html)以及知乎的[Morph](https://zhuanlan.zhihu.com/p/64968076)。这些框架的整体架构逻辑如下所示。

![flex_arch](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_11_07_VSovpU.png)

<center>基于flex跨端框架</center>

在这个框架下，由于底层依赖于Flex的跨端渲染引擎，因此所有UI布局的描述都必须采用Flex布局方式。Flex跨端布局引擎具有成熟可靠的优势，且Flex布局描述通用易懂。然而，与常规约束布局相比，将样式转化为Flex布局描述需要额外工作，并且不可避免地增加了View的层级嵌套，增加了整体DSL描述的复杂度和数据传输量。同时，[facebook/yoga](https://github.com/facebook/yoga)以及[Tencent/Taitank](https://github.com/Tencent/Taitank)有别于我们原生开发的View体系，在布局问题的维护和调试方面较为困难。

### 基于声明式UI框架

随着Jetpack Compose和SwiftUI等声明式UI框架的广泛应用和不断发展，将DSL转换为声明式UI框架成为一种可行的选择。特别是Compose Multiplatform的出现，理论上可以将DSL转换为适用于多平台的声明式UI。然而，目前引入Jetpack Compose和SwiftUI并没有明显的收益，声明式UI的引入会增加应用程序的包体积并影响启动速度。因此，我们目前没有采用这一方案。尽管一些技术论坛上存在相关的尝试和分享，例如：[《Jetpack Compose Enables JSON Defined View Layout》](https://medium.com/mobile-app-development-publication/jetpack-compose-enables-json-defined-view-layout-b1f8a0d5df8c)，但目前业内还没有一个完整的基于声明式UI的动态化框架。声明式UI框架是未来的发展趋势，我们将继续关注，并在认为基于声明式UI的动态化方案具有额外优势，如性能和维护性等方面时考虑进行切换。

### 基于原生UI框架

基于原生UI框架是指我们将DSL转换绑定到安卓和iOS的原生View中，并通过原生布局的方式或者引入对应平台的Flex布局对View进行渲染。采用这种方式虽然要求各端编写相应的代码来创建和渲染DSL对应的View，不过这种方式有以下几个好处：

1. 更接近熟悉的原生开发，无需额外学习成本
2. 性能与原生一样快
3. 在View的扩展和维护方面相对容易
4. 可与现有的原生控件页面很好集成，具有良好的互操作性。

基于上述考虑，我们选择了基于原生的View框架作为底层布局和渲染的基础。业内有两个具有影响力的基于原生UI框架的动态化项目，分别是天猫的Tangram([alibaba/Tangram-Android](https://github.com/alibaba/Tangram-Android)、[alibaba/Tangram-iOS](https://github.com/alibaba/Tangram-iOS))以及优酷的[alibaba/GaiaX](https://github.com/alibaba/GaiaX)。我们分别对这两个项目进行详细的分析。

#### Tangram

Tangram是阿里生态中淘宝&天猫开源的动态化渲染方案。该项目的主要代码贡献发生在2017年至2019年期间，目前已停止维护。Tangram实现了基于列表的多样式卡片式布局，支持一拖N、悬浮和吸顶效果，以及轮播等卡片样式的动态化布局。它包含了JSON样式解析器、数据解析绑定器、VirtualView渲染框架、VirtualLayout（LazyScroolView for iOS）布局框架、预设组件卡片库，以及布局预览、曝光点击处理等辅助工具。整体流程可参考下图：

![img](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_11_08_t2b41b.png)

<center>Tangram工作流程</center>

Tangram的实现思路给我们提供了有价值的启示和帮助，但它整体效果并不完全满足我们自身的业务需求。此外Tangram已处于停止维护状态，其代码逻辑庞大且复杂。因此，在Tetris Native中，我们只是借鉴了Tangram一些View生成的流程和思路，并没有基于它进行开发。

#### GaiaX

GaiaX是阿里生态中优酷开源的跨端动态化模板引擎，配套有卡片编辑器，文档较全且在活跃迭代。目前，网易云音乐也采用该框架来实现首页的动态化。整体思路与我们的目标相似，即通过将DSL转换为相应的原生业务卡片UI控件。其实现的整体思路和方案与Tetris Native类似，也是将DSL转换为虚拟节点树，再转换为原生View树。其中DSL包含描述UI控件层级关系的Layout JSON、描述样式的CSS和描述数据的Data JSON三部分。GaiaX整体框架实现流程如下：

![GaiaX-arch](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_11_09_O6Rogo.png)

<center>GaiaX工作流程</center>

在启动Tetris Native项目时，GaiaX还没有进入公众视野，因此我们没有基于GaiaX来开发动态化模板引擎。相比Tetris Native，GaiaX虽然有配套的卡片编辑器，但是无法和我们自己的投放系统进行结合（参考云音乐自研的投放系统）。此外，GaiaX缺乏我们业务需要的一些特性（如视频、不规则圆角、Flex布局等），同时GaiaX样式与数据分离增加了数据构造的复杂度和数据传输量，没有带来实质优势。因此我们将参考GaiaX的实现方式，吸取其中比较好的部分（如事件和JS引擎的引入），以完善和迭代Tetris Native。

#### Tetris Native

总体而言，跨端服务驱动UI框架的技术选型涉及以下三个方面的方案选择。首先，需要选择DSL层的格式，即XML、JSON还是YAML，并决定是否需要进行样式数据分离。其次，需要选择Layout层的布局引擎，是跨端的Flex布局引擎、声明式UI框架，还是原生的布局方式。最后，在View层需要选择使用原生View还是声明式UI控件。根据我们团队的技术条件、现有项目架构和业务需求，在Tetris Native中我们做出以下技术选型：

* 首先，明确我们的目标是根据业务需求来抽离共性，而不是构建类似RN或其他类Web开发引擎，不自嗨
* DSL层，使用JSON作为数据传输格式，简洁明了，减少数据传输量

* View层，基于基础原生组件构建，考虑与现有项目的互操作性和可维护性，暂时不引入声明式UI组件
* Layout层，使用原生相对布局和流式布局，避免引入难以维护的三方渲染引擎

技术架构和流程概览如下图所示：

<img src="https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_11_10_jcm7qz.png" alt="技术架构图" style="zoom:50%;" />

<center>Tetris Native技术架构图</center>

![Tetris Native工作流程](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_11_03_K5ssEk.png)

<center>Tetris Native工作流程</center>

详细设计方案和落地问题处理将在下一篇文章中进行详细介绍，敬请期待。

## DSL设计

对于动态模板引擎而言，DSL的设计是尤为关键的。我们遵循以下三个原则来设计DSL：

1. 直观：字段定义应该能够直观地传达其含义。
2. 简洁：在保持直观性的前提下，尽量保持简洁。
3. 通用：尽量使用已有的安卓和iOS原生参数，避免引入新的概念。

以下是Tetris Native支持的能力DSL一览。

| 根布局配置                                               |                                                              |
| -------------------------------------------------------- | ------------------------------------------------------------ |
| 设计稿宽度 (designWidth)                                 | 固定大小 (fixScale)<br />- 默认根据designWidth和当前view的宽度进行元素缩放 false <br />- 使用原生缩放策略 true |
| 边距 (marginLeft, marginRight,  marginTop, marginBottom) | 背景（bg,bgDark）                                            |

| 基础属性                                |                                                              |
| --------------------------------------- | ------------------------------------------------------------ |
| 位置&宽高（l, t, r, b, w, h）           | 边框（borderWidth, borderColor, borderColorDark）            |
| 圆角（borderRadiusArray, borderRadius） | 阴影（shadowXOffset, shadowYOffset, shadowBlur, shadowSpread, shadowColor, shadowColorDark） |

| 图片                                                         |                                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| 拉伸方式（scaleType）<br />- 两边拉伸，默认 （fillXY） <br />- 按比例展示全部，图片小于view部分透明（centerInside） <br />- 按比例填充图片，多余部分被裁剪（centerCrop） | 背景图片或者色值（src, srcDark）                             |
| 占位色值（placeholder, placeholderDark）                     | 占位色值（placeholder, placeholderDark）                     |
| 取色填充背景，是否获取当前图片的主题色值填充背景卡片（colorToBg） | 取色失败默认填充值（colorToBgPlaceholder, colorToBgPlaceholderDark） |

| 视频                                                         |                                                        |
| ------------------------------------------------------------ | ------------------------------------------------------ |
| 拉伸方式（scaleType）<br />- 两边拉伸，默认 （fillXY）<br />- 按比例展示全部，视频小于view部分透明（centerInside）<br />- 按比例填充视频，多余部分被裁剪（centerCrop） | 视频链接 (videoSrc)                                    |
| 封面背景图片或者色值（coverSrc, coverSrcDark）               | 封面占位色值（coverPlaceholder, coverPlaceholderDark） |
| 视频在多帧卡片中的轮播时长 (showInterval 单位为秒)           |                                                        |

| 文本                                                         |                                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| 文本内容（text）                                             | 字体色值（color, colorDark）                                 |
| 字体大小（size）                                             | 字体样式（textStyle）<br />- 正常，默认（normal） <br />- 粗体（bold） |
| 文本最大行数（maxLines）                                     | 超过行数显示样式 (ellipsize)<br />-  默认，尾部… (end) <br />- 走马灯 （marquee） |
| 文本对齐方式（align）                                        | 文本内边距 (contentInset)                                    |
| 文本左侧或右侧图片（drawableLeft, drawableLeftDark, drawableRight, drawableRightDark） | 文本阴影（textShadowXOffset, textShadowYOffset, textShadowRadius, textShadowColor, textShadowColorDark） |

| 卡片                   |                     |
| ---------------------- | ------------------- |
| 背景色值（bg, bgDark） | 跳转Deeplink（url） |
| 子节点（children）     |                     |

| 多帧卡片                                                     |                                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| 多帧布局间隔（frameSpace）                                   | 帧宽度（frameWidth）                                         |
| 背景色值（bg, bgDark）                                       | 多帧指示器（indicator）<br />- 隐藏指示器，默认（none） <br />- 左下方（left） <br />- 中部下方（center） <br />- 右下方（right） |
| 多帧指示器边距（indicatorMargin）                            | 自动循环（autoLoop）                                         |
| 自动循环禁止用户操作（disableUserScroll）                    | 设置自动循环间隔（loopIntervalMs）                           |
| 是否循环（isLoop，对于frameWidth * 2 + frameWidth >= width的情况，默认会采用循环方式，若不希望循环，可以设置为FALSE） | 通屏（isExtendToEdge，设置之后可以让卡片展示到外层padding位置，框架会处理与外边框对齐） |
| 轴向 (axis)<br />- 横向（默认）horizontal<br />- 竖向 vertical | 包含的卡片 (cards)                                           |

| Flex流式布局卡片                                             |                                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| 背景色值（bg, bgDark）                                       | 行间距 (lineSpacing)                                         |
| 同行元素间距 (interitemSpacing)                              | 元素是否另起一行 (wrapBefore，以flexParam参数放到每个元素之中) |
| 纵向方向布局方式 (alignContent)<br />- start<br />- end<br />- center<br />- spaceBetween<br />- spaceAround<br />- spaceEvenly | 行水平方向布局方式 （justifyContent）<br />- start<br />- end<br />- center<br />- spaceBetween<br />- spaceAround<br />- spaceEvenly |
| 同一行元素在纵向布局方式 (alignItem)<br />- start<br />- end<br />- center<br />- stretch |                                                              |

## 运营投放逻辑

从运营的角度来看，模板动态化的端侧实现仅仅是整体框架的一部分。以下是我们整体动态化运营投放、测试和服务上线的介绍。

首先，产品和运营团队会编写需要试验的所有投放样式的需求文档。设计师会根据产品需求文档设计试验投放样式的UI稿。根据UI稿，我们会生成动态版面的JSON描述。然后，在投放后台中，我们需要新增这些试验版面的投放流程。运营团队会上传图文等素材，并指定素材对应的业务落地页，生成不同样式的卡片。接着，运营团队会进入需要试验的版面，进行素材投放的编辑，并确定每个版面所需的素材组合。

在设置好试验版面的素材内容后，运营团队会在投放后台系统中设置这些试验版面的投放策略。当投放策略设置完成，我们可以预览投放的页面，并将其发布到测试环境。测试团队会在测试环境中对新增样式进行测试，当测试通过后，我们就可以将其发布到线上，向用户展示。

在用户浏览和点击投放试验卡片的过程中，我们会根据页面描述JSON中的统计字段自动收集和上报日志。最后，运营团队可以通过我们的日志报表查看不同版面和素材对用户点击率的影响，以便决定使用点击率更高的版面和素材。下图展示了投放流程和投放系统的测试及上线流程。

![运营流程1](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_11_09_ofL5tL.png)

<center>运营投放整体流程</center>

通过引入Tetris Native动态化运营，我们成功降低了客户端开发和迭代所需的开发成本和时间投入，从而提高了运营投放的效率。此外，我们还实现了规范的自动日志上报、广告获取和自动展示上报等功能，消除了过去产品和开发团队之间繁琐的日志对接和测试验收流程，进一步加速了整体运营投放的效率。

## 总结展望

Tetris Native经历了多个线上版本的迭代，从想法的萌生到正式立项，再发展到了目前相对稳定的阶段。在迭代过程中，我们不断提炼业务逻辑的共性，并持续优化整体框架的设计和性能。以下是Tetris Native整体开发和迭代的过程：

![tn-timeline](https://cdn.jsdelivr.net/gh/shenguojun/ImageServer@master/uPic/%202023_11_09_wJJ50f.png)

<center>Tetris Native 开发历程</center>

Tetris Native接下来的Roadmap会继续结合业务产品需求，继续往以下这些方面进行迭代优化

* 探索DSL编辑优化的方法，将DSL以类似于API的方式进行发布，降低使用门槛
* 将库中原生View构建逻辑进行抽离，支持调用方复用和快速构建
* 探索AI在这里提升效率的潜力和应用

以上介绍了网易有道动态化运营引擎Tetris Native的初衷以及迭代开发过程，同时详细阐述了有道词典在动态化运营投放方面的整体逻辑，并展示了引入Tetris Native后的效率提升，希望能为大家的提供一些思路和带来收益。

下面让我们为参与Tetris Native开发的团队成员们鼓掌！

服务端：谢江钊、前端：滕洁、Android端：申国骏、iOS端：林俊健
