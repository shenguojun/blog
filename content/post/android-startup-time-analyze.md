---
title: "如何统计Android App启动时间"
date: 2018-07-03T17:36:21+08:00
author: 申国骏
tags: ["android"]
---

随着App的逻辑不断庞大，一不注意就会将耗时的操作放置在应用启动过程之中，导致应用启动速度越来越慢，用户体验也越来越差。优化启动速度是几乎所有大型App应用开发者需要考虑的问题。优化启动速度之前首先需要准确测量App启动时间，这样有利于我们更准确可量化地看出优化效果，也可以指导我们进行持续优化。转载请注明出处：[Lawrence_Shen](http://www.jianshu.com/u/b692bbf77991)
## - 使用命令行方式
使用命令行方式统计多次启动某个Activity的平均用时可以在shell中执行如下指令：
```
adb shell am start -S -R 10 -W com.example.app/.MainActivity
```
其中`-S`表示每次启动前先强行停止，`-R`表示重复测试次数。每一次的输出如下所示信息。
```
Stopping: com.example.app
Starting: Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] cmp=com.example.app/.MainActivity }
Status: ok
Activity: com.example.app/.MainActivity
ThisTime: 1059
TotalTime: 1059
WaitTime: 1073
Complete
```
其中`TotalTime`代表当前Activity启动时间，将多次`TotalTime`加起来求平均即可得到启动这个Activity的时间。
### 缺点
1. 应用的启动过程往往不只一个Activity，有可能是先进入一个启动页，然后再从启动页打开真正的首页。某些情况下还有可能中间经过更多的Activity，这个时候需要将多个Activity的时间加起来。
2. 将多个Activity启动时间加起来并不完全等于用户感知的启动时间。例如在启动页可能是先等待某些初始化完成或者某些动画播放完毕后再进入首页。使用命令行统计的方式只是计算了Activity的启动以及初始化时间，并不能体现这种等待任务的时间。
3. 没有在*AndroidManifest.xml*对应的Activity声明中指定`<intent-filter>`或者属性没有`android:exported="true"`的Activity不能使用这种命令行的形式计算启动时间。

## -思考更准确的方式
  以上基于命令行的方式存在诸多问题，迫使我们思考怎样才能得到从用户角度上观察更准确的启动时间。在尝试其他方法之前，我们先定义一下怎样才是从用户角度上观察的启动时间。
### 冷启动、热启动（注意不是官方的定义，是我们从用户角度考虑的定义）
- 冷启动时间：冷启动表示用户首次打开应用，这时进程还没创建，包含了Application创建的过程。冷启动时间指从第一次用户点击Launcher中的应用图标开始，到首页内容全部展示出来的时间。
- 热启动时间：热启动表示用户在首页按了返回，首页Activity已经Destroy，不过Application仍在内存中存在，对应的进程并没有被杀掉，不包含Application创建过程。热启动时间指在Application仍然存在的情况下，从用户点击桌面图标，到首页内容全部展示出来的时间。

### App启动流程
  要优化以及分析启动时间，需要先了解App的启动流程。以冷启动为例子，Application以及Activity的启动流程如下，参考文章<sup>[3][4][5][6]</sup>：

![app启动流程](http://upload-images.jianshu.io/upload_images/2057980-9c537daee4ef6932.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

更为直观和简单的流程图参考Colt McAnlis在[Android Performance Patterns Season 6](https://www.youtube.com/playlist?list=PLWz5rJ2EKKc-9gqRx5anfX0Ozp-qEI2CF)中的表述。有兴趣的同学可以点击链接看看（[Youtube链接](https://www.youtube.com/watch?v=Vw1G1s73DsY&index=2&list=PLWz5rJ2EKKc-9gqRx5anfX0Ozp-qEI2CF)）。
![app启动流程by Colt McAnlis](http://upload-images.jianshu.io/upload_images/2057980-54287e0984138800.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

  从流程图以及参考Colt McAnlis的Android Performance Patterns<sup>[6]</sup>得知，在冷启动的过程中，首先会通过AMS在System进程展示一个Starting Window(通常情况下是个白屏，可以通过设置Application的theme修改)，接着AMS会通过Zygote创建应用程序的进程，并通过一系列的步骤后调用Application的`attachBaseContext()`、`onCreate()`然后最终调用Activity的`onCreate()`以及进行View相关的初始化工作。在Activity展示出来后会替换掉之前的Starting Window，这样启动过程结束。
### 如何加log
  参考<sup>[1]</sup>发现在Activity中`onWindowFocusChanged()`方法是最好的Activity对用户可见的标志，因此综合上一节的分析，我们可以考虑在Application的`attachBaseContext()`方法中开始计算冷启动计时，然后在真正首页Activity的`onWindowFocusChanged()`中停止冷启动计时，这样就可以初步得到应用的冷启动时间。

>public void **onWindowFocusChanged**(boolean hasFocus)

>Called when the current `android.view.Window` of the activity gains or loses focus. **This is the best indicator of whether this activity is visible to the user.**

为了方便统计，设置一个Util类专门做计时，添加的代码如下：
```
/**
 * 计时统计工具类
 */
public class TimeUtils {
    private static HashMap<String, Long> sCalTimeMap = new HashMap<>();
    public static final String COLD_START = "cold_start";
    public static final String HOT_START = "hot_start";
    public static long sColdStartTime = 0;

    /**
     * 记录某个事件的开始时间
     * @param key 事件名称
     */
    public static void beginTimeCalculate(String key) {
        long currentTime = System.currentTimeMillis();
        sCalTimeMap.put(key, currentTime);
    }

    /**
     * 获取某个事件的运行时间
     *
     * @param key 事件名称
     * @return 返回某个事件的运行时间，调用这个方法之前没有调用 {@link #beginTimeCalculate(String)} 则返回-1
     */
    public static long getTimeCalculate(String key) {
        long currentTime = System.currentTimeMillis();
        Long beginTime = sCalTimeMap.get(key);
        if (beginTime == null) {
            return -1;
        } else {
            sCalTimeMap.remove(key);
            return currentTime - beginTime;
        }
    }

    /**
     * 清除某个时间运行时间计时
     *
     * @param key 事件名称
     */
    public static void clearTimeCalculate(String key) {
        sCalTimeMap.remove(key);
    }

    /**
     * 清除启动时间计时
     */
    public static void clearStartTimeCalculate() {
        clearTimeCalculate(HOT_START);
        clearTimeCalculate(COLD_START);
        sColdStartTime = 0;
    }
}
```

然后在Application的`attachBaseContext()`方法中添加如下代码：
```
@Override
protected void attachBaseContext(Context base) {
    super.attachBaseContext(base);
    if (/**如果是主进程**/) {
        TimeUtils.beginTimeCalculate(TimeUtils.COLD_START);
    }
}
```
在第一个Activity的`onCreate()`方法中添加如下代码：
```
@Override
protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    calculateStartTime();
    ....
}

private void calculateStartTime() {
    long coldStartTime = TimeUtils.getTimeCalculate(TimeUtils.COLD_START);
    // 这里记录的TimeUtils.coldStartTime是指Application启动的时间，最终的冷启动时间等于Application启动时间+热启动时间
    TimeUtils.sColdStartTime = coldStartTime > 0 ? coldStartTime : 0;
    TimeUtils.beginTimeCalculate(DictTimeUtil.HOT_START);
}
```
在真正的首页Activity的 `onWindowFocusChanged()`方法中添加如下代码：
```
@Override
public void onWindowFocusChanged(boolean hasFocus) {
    if (hasFocus && /**没有经过广告或者引导页**/) {
        long hotStartTime = TimeUtils.getTimeCalculate(TimeUtils.HOT_START);
        if (TimeUtils.sColdStartTime > 0 && hotStartTime > 0) {
            // 真正的冷启动时间 = Application启动时间 + 热启动时间
            long coldStartTime = TimeUtils.sColdStartTime + hotStartTime;
            // 过滤掉异常启动时间
            if (coldStartTime < 50000) {
                // 上传冷启动时间coldStartTime
            }
        } else if (hotStartTime > 0) {
            // 过滤掉异常启动时间
            if (hotStartTime < 30000) {
                // 上传热启动时间hotStartTime
            }
        }
    }
}
```

### 避免坑的Checklist
  上面的分析给了我们初步的加log的起始和结束点，然而在实际的统计中会发现得到的数据有20%左右是不准确的，体现在计时数据非常大，有些甚至会显示冷启动时间超过一天。经过分析，在计算启动计时的时候需要注意一些问题。以下列举一下添加log时候需要注意的checklist。

1. 应用在启动过程可能会有广告（我们的业务是有道词典），第一次启动会有引导页，需要根据业务情况标记在没有广告、没有引导页的时候才计算。这种情况要注意在非正常启动的时候忽略启动时间统计。

2. 由于词典首页之前还有几个Activity，在没到首页Activity之前如果过早的返回，会出现冷启动时间过长的问题。这是因为词典返回的时候并没有杀掉进程，而时间统计信息是保存在内存中的，而等下次再进入的时候因为是热启动不会重新开始冷启动计时。这导致了这次热启动实际上打log的时候发现有上次冷启动的开始时间，算成了冷启动，而且因为启动时间是上一次的，所以这次冷启动log的时间比实际时间长。这种情况要注意在首页Activity之前的其他Activity`onPause()`方法中调用`TimeUtils.clearStartTimeCalculate();`清除计时。

3. 除了正常的启动流程，应用还有很多可能会导致Application的创建的入口，例如点击桌面小插件、系统账号同步、Deep Link跳转、直接进入设置了`<action android:name="android.intent.action.PROCESS_TEXT" />`的Activity、push达到等。我们需要检查所有有可能引起Application创建，但是不是正常启动流程的地方，调用`TimeUtils.clearStartTimeCalculate();`清除计时，避免引起冷启动时间计算过长错误的问题。

## - 使用第三方工具
  为了测试启动的过程中哪些方法比较耗时，我们可以使用Android Studio中集成的Android Monitor提供的[Method Tracering](https://developer.android.com/studio/profile/am-methodtrace.html)或者[Systrace](https://developer.android.com/studio/profile/systrace-commandline.html?utm_campaign=app_series_systracecommandline_081616&utm_source=anddev&utm_medium=yt-desc)。不过在实践中发现，有另外一个[nimbledroid](https://nimbledroid.com/)工具使用更加简便且能更明确指出耗时的地方。上传了应用之后会自动分析情景如下图所示。其中会自动检测出首页的Activity并且给出冷启动的启动情况。

![情景分析](http://upload-images.jianshu.io/upload_images/2057980-b8299b5e3097792b.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

  点击进入Cold Startup的情景可以看到主要耗时的方法如下图。

![情景详细耗时统计](http://upload-images.jianshu.io/upload_images/2057980-872a28759fb0cb6a.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

至于为什么[nimbledroid](https://nimbledroid.com/)会知道那个是我们首页的Activity，官网上解析如下：

>We use a heuristic to tell when an app finishes startup by detecting when (1) the main Activity has been displayed and (2) things like animated progress bars in the main Activity have stopped. Based on our experiments, this heuristic works in most cases.

点击进入某个方法，可以看到这个方法具体是由于调用了哪个子方法导致了耗时的问题。

![耗时方法详细](http://upload-images.jianshu.io/upload_images/2057980-4ee7efdc7c917454.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

  通过[nimbledroid](https://nimbledroid.com/)这个工具，我们可以比较轻松地发现一些比较明显的问题，并可以指导我们进行启动优化。同时[nimbledroid](https://nimbledroid.com/)还支持Memory Leaks、网络监测以及结果分享等一些功能，更多的功能有待读者继续发现。

## - 后记

  统计和分析启动时间有利于指导我们优化启动时间。以上介绍了有道词典在进行启动优化中的分析过程。通过详细了解Android应用启动的流程，进行准确的log记录，并且结合第三方工具，我们最终得到准确的启动时间统计数据以及启动优化的一些头绪。具体优化的方法参加下一篇文章《[如何优化Androd App启动速度](http://www.jianshu.com/p/bef74a4b6d5e)》。

## - 参考
【1】[单刀土豆](http://www.jianshu.com/u/c188a9c836b3)，2016.[Android 开发之 App 启动时间统计](http://www.jianshu.com/p/c967653a9468)

【2】[Android Developer](https://developer.android.com/index.html)，[Launch-Time Performance](https://developer.android.com/topic/performance/launch-time.html)

【3】[./multi_core_dump](http://multi-core-dump.blogspot.hk/)，2010.[Android Application Launch](http://multi-core-dump.blogspot.hk/2010/04/android-application-launch.html)

【4】[./multi_core_dump](http://multi-core-dump.blogspot.hk/)，2010.[Android Application Launch Part 2](http://multi-core-dump.blogspot.hk/2010/04/android-application-launch-part-2.html)

【5】[罗升阳](http://my.csdn.net/Luoshengyang)，2012.[Android系统源代码情景分析](http://0xcc0xcd.com/p/books/978-7-121-18108-5/index.php)

【6】[Colt McAnlis](https://medium.com/@duhroach)，2016.[Android Performance Patterns Season 6](https://www.youtube.com/playlist?list=PLWz5rJ2EKKc-9gqRx5anfX0Ozp-qEI2CF)
