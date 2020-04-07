---
title: "Databinding subModule library 爬坑"
date: 2019-04-12T12:57:47+08:00
author: 申国骏
tags: ["android"]
---

# 问题描述
最近把gradle的‘com.android.tools.build:gradle’升级到3.2.1，升级之后dataBinding出错了，编译通过，但是运行时报了一个错误```java.lang.ClassCastException: com.youdao.dict.databinding.FragmentYdliveBindingImpl cannot be cast to com.youdao.ydliveplayer.databinding.FragmentYdliveBinding```。转载请注明来源[「Bug总柴」](https://www.jianshu.com/u/b692bbf77991) 

# 问题分析
## 表象原因
生成这个Binding的layout文件是在submodule里面的，然而最终生成了三个Binding文件，分别是对应submodule包名的```com.youdao.ydliveplayer.databinding.FragmentYdliveBinding```，以及对应主工程包名的```com.youdao.dict.databinding.FragmentYdliveBinding```与```com.youdao.dict.databinding.FragmentYdliveBindingImpl```。而在submodule代码中通过```DataBindingUtil.inflate```得到的binding对象是强制转换赋值给submodule的binding对象，但是运行时却得到的是主工程的binding对象，最后因为submodule的binding对象与主工程的binding对象虽然类名相同但是实际上从属于两个不同包底下不同的两个类，导致了运行时的类型转换错误。
![image.png](https://upload-images.jianshu.io/upload_images/2057980-2291816e789826ab.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
## 根本原因
为什么升级了com.android.tools.build:gradle会影响Databinding的编译呢，我们看build tool的changelog文档[https://developer.android.com/studio/releases/gradle-plugin#bug_fixes](https://developer.android.com/studio/releases/gradle-plugin#bug_fixes)
![image.png](https://upload-images.jianshu.io/upload_images/2057980-66238c2dd507ba0b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
从3.2.0开始对library modules的data binding分离做了更好的支持。我们再看databinding的文档[https://developer.android.com/topic/libraries/data-binding/start#preview-compiler](https://developer.android.com/topic/libraries/data-binding/start#preview-compiler)
![image.png](https://upload-images.jianshu.io/upload_images/2057980-d942b1eedb35a47f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![image.png](https://upload-images.jianshu.io/upload_images/2057980-87d52e4fcf60fd76.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
意思就是从3.1.0-alpha06开始有新的对databinding的编译方式，并且在3.2的时候默认开启。同时3.2版本之后可以兼容databinding v1编译。
看完上面这些大致可以理解为什么设置‘com.android.tools.build:gradle’为3.2.1的时候会崩溃，但是设置回3.1.4的时候就没问题，这应该是由于databinding compile从3.2.0开始有新的编译方式，从而不兼容旧的databinding导致的。
## 进一步分析
官方文档里面明明说明了3.2可以兼容V1的databinding，为什么我们这里会崩溃呢，为了试验一下是否真的会支持，我们重新建立一个新的工程来看看。新工程的类和layout如下所示：
![image.png](https://upload-images.jianshu.io/upload_images/2057980-a995de5f175a915d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
```kotlin
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DataBindingUtil.setContentView<ActivityMainBinding>(this, R.layout.activity_main)
        supportFragmentManager.beginTransaction()
            .add(R.id.container, BlankFragment(), "BlankFragment").commit()
    }
}
```
```xml
<?xml version="1.0" encoding="utf-8"?>
<layout xmlns:android="http://schemas.android.com/apk/res/android">

    <android.support.constraint.ConstraintLayout xmlns:tools="http://schemas.android.com/tools"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        tools:context=".MainActivity">


        <FrameLayout
            android:id="@+id/container"
            android:layout_width="match_parent"
            android:layout_height="match_parent" />

    </android.support.constraint.ConstraintLayout>
</layout>
```
```kotlin
class BlankFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val fragmentBlankBinding = DataBindingUtil.inflate<FragmentBlankBinding>(
            inflater,
            R.layout.fragment_blank,
            container,
            false
        )
        fragmentBlankBinding.hello = "hi there"
        return fragmentBlankBinding.root
    }
}
```
```xml
<?xml version="1.0" encoding="utf-8"?>
<layout xmlns:android="http://schemas.android.com/apk/res/android">

    <data>
        <variable
            name="hello"
            type="java.lang.String" />
    </data>

    <FrameLayout xmlns:tools="http://schemas.android.com/tools"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:background="@android:color/holo_orange_light"
        tools:context=".BlankFragment">

        <TextView
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:text="@{hello}" />

    </FrameLayout>
</layout>
```

这个工程很简单，我们在主工程中调用library工程中的fragment并展示出来，library工程中使用了databinding。
### databinding V2主工程引用V2 library
首先我们使用‘com.android.tools.build:gradle’ 3.2.1版本对library工程进行assemble打出aar包
![image.png](https://upload-images.jianshu.io/upload_images/2057980-1217f622ae7d1330.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
可以看出V2编译出来的binding类是直接生成到aar包中
我们再看主工程生成的databinding类
![image.png](https://upload-images.jianshu.io/upload_images/2057980-908191a110bc9cc7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
可以看出并没有包含library工程的任何databinding信息。从而我们可以判断从databing compile V2版本开始，databinding的生成是直接放到library工程里面的，不会影响到外层工程。但是这样也意味着library工程不能拥有与主工程相同包名和类名的databinding。当然在在这个例子里面是完全没有问题可以正常编译以及运行的。

### databinding V2主工程引用V1 library
为了验证‘com.android.tools.build:gradle’ 3.2版本是否支持databinding compile V1打包出来的aar，我们首先将com.android.tools.build:gradle改成3.1.4，并对library工程assemble生成aar包
![image.png](https://upload-images.jianshu.io/upload_images/2057980-c0d7aaa370729ae2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
可以看出与V2编译出来的aar不同，通过v1编译出来的aar包并不包含databinding的生成类。并且我们看```fragment_blank.xml```
![image.png](https://upload-images.jianshu.io/upload_images/2057980-1f03de987e6b5846.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
可以看出其中的databinding内容已经被移除。
我们把这个通过v1编译出来的aar包放入主工程，并且修改‘com.android.tools.build:gradle’ 为3.2.1，然后clean build运行一下。**结果出乎我的意料成功了，并且没有任何上面遇到的问题。**我们来看databinding生成的类：
![image.png](https://upload-images.jianshu.io/upload_images/2057980-626da142efff7896.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240) 

```FragmentBlankBinding```应该是按照V1版本格式生成的，并且通过```V1CompatDataBinderMapperImpl```来兼容到V2的databinding中。

### databinding V1主工程引用V2 library
我们使用‘com.android.tools.build:gradle’ 3.2.1版本先生成好library的aar文件，然后使用‘com.android.tools.build:gradle’ 3.1.4版本对主工程进行构建，这可以编译成功，但是运行失败了
![image.png](https://upload-images.jianshu.io/upload_images/2057980-79a95596bac0eb23.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这证明V1是不能兼容到V2的，但是V2可以兼容V1。

## 如果V2可以兼容V1，为什么还会报错ClassCastException？
回到我们最初的问题，实验证明databinding compile V2是可以兼容databinding compile V1生成的aar包的，但是为什么当我们把‘com.android.tools.build:gradle’升级到3.2.1会报错，但是降级回3.1.4就没问题了呢？暂时从理论上我也没办法解释，但是有个区别是值得我们注意的。那就是在报错的aar中，其中的layout文件并没有像我们实验中的所示去掉了databinding的信息，而是如下：![image.png](https://upload-images.jianshu.io/upload_images/2057980-8764908c7aead526.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
仍然包含有databinding的内容。所以这里猜测问题就是出在这个引用的aar包打包的时候用了比3.1.4更古老的com.android.tools.build:gradle（后附：最终找到了原来引用库的代码，发现build tools版本是2.2.3），然后databinding compile造成了连V2都没法兼容的问题。但是由于这个出问题的aar包我们并有他的源码，真是原因已经无从考究了。

# 解决办法
那么，从上面的分析，我们可以得到解决这个问题的两个办法：
1. 将com.android.tools.build:gradle改成3.1.4，通过databinding compile V1来构建主工程和library（存在的风险是不兼容databinding compileV2打出来的aar）
2. 将aar包中的代码通过反编译出来，使用databinding compile V2重新打包一次（但是由于aar里面代码比较多，暂时没有采取这个办法）


# 最后
虽然做了不少实验，不过具体的原因仍然不是特别清晰，希望有经历过这个问题的小伙伴可以给我留言，指出我不对的地方。

================ 分割线 =======================

升级到com.android.tools.build:gradle:3.4.0之后，会提示library的databinding出错
```
 java.lang.NoSuchMethodError: No direct method <init>
(Landroidx/databinding/DataBindingComponent;Landroid/view/View;I)V in 
class Landroidx/databinding/ViewDataBinding; or its super classes
(declaration of 'androidx.databinding.ViewDataBinding'
```
原因是library的databinding使用了3.4.0之前的build tools进行打包，具体可以见[这里]([https://stackoverflow.com/questions/54221707/databinding-nosuchmethoderror-with-buildtools-3-4-0](https://stackoverflow.com/questions/54221707/databinding-nosuchmethoderror-with-buildtools-3-4-0))

>One of your libraries relies on data binding and is distributed with generated data-binding classes built with build tools 3.3 (or earlier). The issue is caused by the breaking change introduced in the latest beta/rc version of the data binding lib. In version 3.4 the signature of `androidx.databinding.ViewDataBinding` constructor has been changed from:

```
protected ViewDataBinding(DataBindingComponent bindingComponent, View root, int localFieldCount)
```

>to:

```
protected ViewDataBinding(Object bindingComponent, View root, int localFieldCount)
```

>Which makes any generated data binding class binary incompatible with 3.4 databinding lib, resulting in the following exception upon startup:

```
java.lang.NoSuchMethodError: No direct method <init>(Landroidx/databinding/DataBindingComponent;Landroid/view/View;I)V in class Landroidx/databinding/ViewDataBinding; or its super classes (declaration of 'androidx.databinding.ViewDataBinding' appears in /data/app/com.example.idolon-LqF2y8dUMxZoK3PVRlzbzg==/base.apk)
        at com.example.lib.databinding.ActivityLibBinding.<init>(ActivityLibBinding.java:20)
        at com.example.lib.databinding.ActivityLibBindingImpl.<init>(ActivityLibBindingImpl.java:30)
        at com.example.lib.databinding.ActivityLibBindingImpl.<init>(ActivityLibBindingImpl.java:27)
        at com.example.lib.DataBinderMapperImpl.getDataBinder(DataBinderMapperImpl.java:316)
        at androidx.databinding.MergedDataBinderMapper.getDataBinder(MergedDataBinderMapper.java:74)
        at androidx.databinding.DataBindingUtil.bind(DataBindingUtil.java:199)
        at androidx.databinding.DataBindingUtil.bindToAddedViews(DataBindingUtil.java:327)
        at androidx.databinding.DataBindingUtil.setContentView(DataBindingUtil.java:306)
        at androidx.databinding.DataBindingUtil.setContentView(DataBindingUtil.java:284)
```

>As a workaround you can rebuild libraries that contains data binding classes using the latest build tools.

>The corresponding bug on Androig Bug tracker is: [https://issuetracker.google.com/issues/122936785](https://issuetracker.google.com/issues/122936785)
