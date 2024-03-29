---
title: "深入理解Android Runtime"
date: 2022-08-08T11:07:45+08:00
author: 申国骏
tags: ["android"]
---

![Android Platform Architecture](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/android-stack_2x.png)

上图是Android整体的架构，Android Runtime之于Android而言相当于心脏之于人体，是Android程序加载和运行的环境。这篇文章主要针对Android Runtime部分进行展开，探讨Android Runtime的发展以及目前现状，并介绍应用Profile-Guided Optimization(PGO)技术对应用启动速度进行优化的可行性。

## App运行时演进

### JVM

Android原生代码使用Java或者Kotlin编写，这些代码会通过javac或者kotlinc编译成.class文件，在Android之前，这些.class文件会被输入到JVM中执行。JVM可以简单分为三个子系统，分别是Class Loader、Runtime Data Area以及Execution Engine。其中Class Loader主要负责加载类、校验字节码、符号引用链接及对静态变量和静态方法分配内存并初始化。Runtime Data负责存储数据，分为方法区、堆区、栈区、程序计数器以及本地方法栈。Execution Engine负责二进制代码的执行以及垃圾回收。

![img](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/1*90GzG4RaWMMBxzJZfW3TVA.png)

Execution Engine中，会采用Interpreter或者JIT执行。其中Interpreter表示在运行的过程中对二进制代码进行解释，每次执行相同的二进制代码都进行解释比较浪费资源，因此对于热区的二进制代码会进行JIT即时编译，对二进制代码编译成机器码，这样相同的二进制代码执行时，就不用再次进行解释。

![img](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/1*z-OtDrR1xqUyymP01nmzTQ.png)

### DVM(Android 2.1/2.2)

JVM是stack-based的运行环境，在移动设备中对性能和存储空间要求较高，因此Android使用了register-based的Dalvik VM。从JVM转换到DVM我们需要将.class文件转换为.dex文件，从.class转换到.dex的过程需要经过 desugar -> proguard -> dex compiler三个过程，这三个过程后来逐步变成 proguard -> D8(Desugar) 直到演变到今天只需要一步R8(D8(Desugar))。

![img](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/1*APXAk8JFCdcfOPTpCD7SeQ.png)

我们主要关注Android中Runtime Engine与JVM的区别。在Android早期的版本里面，只存在Interpreter解释器，到了Android2.2版本将JIT引入，这个版本Dalvik与JVM的Runtime Engine区别不大。

![image-20210630153643456](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image-20210630153643456.png)

### ART-AOT(Android 4.4/5.0)

为了加快应用的启动速度和体验，到了Android4.4，Google提供了一个新的运行时环境ART(Android Runtime)，到了Android5.0，ART替换Dalvik成为唯一的运行时环境。

![image-20210630153852139](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image-20210630153852139.png)

ART运行时环境中，采用了AOT(Ahead-of-time)编译方式，即在应用安装的时候就将.dex提前编译成机器码，经过AOT编译之后.dex文件会生成.oat文件。这样在应用启动执行的时候，因为不需要进行解释编译，大大加快了启动速度。

![image-20210630154438374](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image-20210630154438374.png)

然而AOT带来了以下两个问题：

1. 应用安装时间大幅增加，由于在安装的过程中同时需要编译成机器码，应用安装时间会比较长，特别在系统升级的时候，需要对所有应用进行重新编译，出现了经典的升级等待噩梦。

   ![img](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/1*aKZJgCOMWCfoCr4btsdAFQ.png)

2. 应用占用过多的存储空间，由于所有应用都被编译成.oat机器码，应用所占的存储空间大大增加，使得本来并不充裕的存储空间变得雪上加霜。

进一步思考对应用全量进行编译可能是没有必要的，因为用户可能只会用到一个应用的部分常用功能，并且全量编译之后更大的机器码加载会占用IO资源。

### ART-PGO(Android 7.0)

从Android7.0开始，Google重新引入了JIT的编译方式，不再对应用进行全量编译，结合AOT、JIT、Interpreter三者的优势提出了PGO(Profile-guided optimization)的编译方式。

在应用执行的过程中，先使用Interpreter直接解释，当某些二进制代码被调用次数较多时，会生成一个Profile文件记录这些方法存储起来，当二进制代码被频繁调用时，则直接进行JIT即时编译并缓存起来。

当应用处于空闲（屏幕关闭且充电）的状态时，编译守护进程会根据Profile文件进行AOT编译。

当应用重新打开时，进行过JIT和AOT编译的代码可以直接执行。

这样就可以在应用安装速度以及应用打开速度之间取得平衡。

![image-20210630184913469](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image-20210630184913469.png)

![img](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/1*tCwFSndZOofgYb-TNNWhCw.png)

JIT 工作流程：

![JIT architecture](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/jit-workflow.png)

### ART-Cloud Profile(Android 9.0)

不过这里还是有一个问题，就是当用户第一次安装应用的时候并没有进行任何的AOT优化，通常会经过用户多次的使用才能使得启动速度得到优化。

![img](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image1.png)

考虑到一个应用通常会有一些用户经常使用执行的代码（例如启动部分以及用户常用功能）并且大多数时候会有先行版本用于收集Profile数据，因此Google考虑将用户生成的Profile文件上传到Google Play中，并在应用安装时同时带上这个Profile文件，在安装的过程中，会根据这个Profile对应用进行部分的AOT编译。这样当用户安装完第一次打开的时候，就能达到较快的启动速度。

![img](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image4.png)

![image-20210708160128463](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image-20210708160128463.png)

Profile in cloude 需要系统应用市场支持，在国内市场使用Google Play的占比非常低，因此cloud profile的优化在国内几乎是没有作用的，不过Profile的机制提供了一个可以做启动优化的思路。早在2019年，支付宝就在秒开技术的回应的里面提到过profile-based compile的技术，参考：[如何看待今日头条自媒体发布谣言称「支付宝几乎秒开是因为采用华为方舟编译器」？](https://www.zhihu.com/question/322429114)，这也是我们一直研究Profile技术的原因。困扰着我们的一直有两个问题，第一个问题是如何生成Profile文件，第二个问题是怎么使用生成的Profile文件。对于第一个问题的解决相对还是有思路的，因为app运行就会生成profile文件，因此我们手动运行几次app就能在文件系统中收集到这个文件，不过如何以一种较为自动化的手段收集仍然是个问题。第二个问题我们知道Profile文件最终生成的位置，因此我们可以把生成的文件放到相应的系统目录，不过大多数手机和应用都没有权限直接放置这个文件。因此Profile优化技术一直都没有落地，直到Baseline Proflie让我们看到了希望。

### Baseline Profile

Baseline Profile是一套生成和使用Profile文件的工具，在2022年一月份开始进入视野，随后在Google I/O 2022随着Jetpack新变化得到广泛关注。其背景是Google Map加快了发版速度，Cloud Profle还没完全收集好就上新版，导致Cloud Proflie失效。还有一个背景是Jetpack Compose 不是系统代码，因此没有完全编译成机器码，而且Jetpack Compose库比较大，因此在Profile生成之前使用了Jetpack Compose的应用启动会产生性能问题。最后Google为了解决这些问题，创造了收集Profile的BaselineProfileRule Macrobenchmark以及使用Profile的ProfileInstaller。

使用Baseline Profile的机制可以在Android7及以上的手机上得到应用的启动加速，因为从上述知道Android7就已经开始有PGO(Profile-guided optimization)的编译方式。生成的Profile文件会打包到apk里面，并且会结合Google Play的Cloud Profile来引导AOT编译。虽然在国内基本上用不了Cloud Profile，不过Baseline Profile是可以独立于Google Play单独使用的。

![image-20220629114656005](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image-20220629114656005.png)

在使用了Baseline Proflie之后，有道词典的启动速度从线上统计上看，冷启动时间有15%的提升。

这篇文章主要介绍了Android Runtime的演进以及对于应用启动的影响，下一篇文章我会详细介绍关于Profile&dex文件优化、Baseline Profile工具库原理，以及在实际操作上如何使用的问题，敬请大家期待一下！





## 参考

* [Android CPU, Compilers, D8 & R8](https://proandroiddev.com/android-cpu-compilers-d8-r8-a3aa2bfbc109)
* [Implementing ART Just-In-Time (JIT) Compiler](https://source.android.com/devices/tech/dalvik/jit-compiler)
* [Configuring ART](https://source.android.com/devices/tech/dalvik/configure)
* [Improving app performance with ART optimizing profiles in the cloud](https://android-developers.googleblog.com/2019/04/improving-app-performance-with-art.html)
* [Understanding Android Runtime (ART) for faster apps (Google I/O'19)](https://www.youtube.com/watch?v=1uLzSXWWfDg)
* [What's new in Android Runtime (Google I/O '18)](https://www.youtube.com/watch?v=Yi9-BqUxsno&list=PLWz5rJ2EKKc9Gq6FEnSXClhYkWAStbwlC&t=985s)
* [Performance and memory improvements in Android Run Time (ART) (Google I/O '17)](https://www.youtube.com/watch?v=iFE2Utbv1Oo)
* [The Evolution of ART - Google I/O 2016](https://www.youtube.com/watch?v=fwMM6g7wpQ8)
* [Google I/O 2014 - The ART runtime](https://www.youtube.com/watch?v=EBlTzQsUoOw)
* [Google I/O 2010 - A JIT Compiler for Android's Dalvik VM](https://www.youtube.com/watch?v=Ls0tM-c4Vfo)
* [Android Runtime  -  How Dalvik and ART work?](https://www.youtube.com/watch?v=0J1bm585UCc)
* [Android Debug Bridge - Read ART profiles for apps](https://developer.android.com/studio/command-line/adb#appprofiles)
* [Deep dive into the ART runtime (Android Dev Summit '18)](https://www.youtube.com/watch?v=vU7Rhcl9x5o)
* [Deep dive into ART(Android Runtime) for dynamic binary analysis | SungHyoun Song | Nullcon 2021](https://www.youtube.com/watch?v=mFq0vNvUgj8)
* [Baseline Profiles](https://developer.android.com/topic/performance/baselineprofiles)
* [Google I/O 2022: What’s new in Jetpack](https://android-developers.googleblog.com/2022/05/whats-new-in-jetpack.html)
* [Improving App Performance with Baseline Profiles](https://android-developers.googleblog.com/2022/01/improving-app-performance-with-baseline.html)
* [Android 强推的 Baseline Profiles 国内能用吗？我找 Google 工程师求证了！](https://juejin.cn/post/7104230480391864356)

