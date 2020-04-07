---
title: "如何优化Androd App启动速度"
date: 2018-07-03T17:42:32+08:00
tags: ["android"]
---
在上一篇文章[《如何统计Android App启动时间》](http://www.jianshu.com/p/59a2ca7df681)中我们探讨了如何统计Android App的启动时间，以及简要分析了App启动流程。这一篇文章主要讲如何在实战中提升Android App的启动速度。下面我们先回顾一下App的启动流程。转载请注明出处：[Lawrence_Shen](http://www.jianshu.com/u/b692bbf77991)
## App 启动流程分析
  上一篇文章[《如何统计Android App启动时间》](http://www.jianshu.com/p/59a2ca7df681)我们定义了从用户角度上观察的启动时间。我们把这段时间再细分成两段，一段是从用户点击Launcher图标到进入第一个Acitivity的时间，另一段是从第一个Activity到最后首页Activity完全展示出来用户可进行操作的时间。在第一段时间中耗时的任务主要体现在Application的创建，第二段时间耗时主要是因为Activity的创建以及在最后首页Activity展示之前的业务流程。主要解决的思路有两个：一个是**尽可能将初始化延后到真正调用的时候**，另一个是**尽可能将不是用户第一时间能体验的业务功能延后**。经过对我们App的详细分析以及对业务的了解，可以通过以下一些方法来解决应用启动慢的问题。
## 解决问题
### 控制Static初始化范围
  启动过程可能会用到一些Utils等工具类，这些类中包含了几乎整个项目需要使用到的工具。我们在优化的过程中发现某些Utils类中定义了静态变量，而这些静态变量的初始化会有一定耗时。这里需要注意可以把静态变量的初始化移到第一次使用的时候。这样可以避免在用到工具类的其他方法时提前做了没必要的初始化。例如一个Utils如下：
```
public class ExampleUtils {
    private static HeavyObject sHeavyObject = HeavyObject.newInstance(); //比较耗时的初始化
    ...
    public static void useHeavyObject() {
        sHeavyObject.doSomething();
    }

    /**
     *
     * 启动过程中需要用到的方法
     */
    public static void methodUseWhenStartUp() {
      ...
    }
    ...
}
```
可以修改为：
```
public class ExampleUtils {
    private static HeavyObject sHeavyObject;
    ...
    public static void useHeavyObject() {
        if (sHeavyObject == null) {
            sHeavyObject = HeavyObject.newInstance(); //比较耗时的初始化
        }
        sHeavyObject.doSomething();
    }

    /**
     *
     * 启动过程中需要用到的方法
     */
    public static void methodUseWhenStartUp() {
      ...
    }
    ...
}
```
### ViewStub 初始化延迟
  对于一些只有在特定情况下才会出现的view，我们可以通过ViewStub延后他们的初始化。例如出于广告业务的需求，在有广告投放的时候需要在首页展示一个视频或者一个h5广告。由于视频控件以及webview的初始化需要耗费较长时间，我们可以使用ViewStub，然后在需要显示的时候通过ViewStub的inflate显示真正的view。例如在启动页的xml中某一段如下：
```
<com.example.ad.h5Ad.ui.H5AdWebView
    android:id="@+id/ad_web"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:visibility="gone" />
```
可以修改为：
```
<ViewStub
    android:id="@+id/ad_web_stub"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:layout="@layout/h5_ad_layout"/>
```
并新建一个`h5_ad_layout.xml`如下：
```
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:orientation="vertical" android:layout_width="match_parent"
    android:layout_height="match_parent">

    <com.example.ad.h5Ad.ui.H5AdWebView
        android:id="@+id/ad_web"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:visibility="gone" />

</LinearLayout>
```
然后在代码中需要显示webview时进行inflate：
```
...
    private void setupView() {
        ...  
        mAdWebViewStub = (ViewStub) findViewById(R.id.ad_web_stub);
        mAdWebViewStub.setOnInflateListener(new ViewStub.OnInflateListener() {
            @Override
            public void onInflate(ViewStub stub, View inflated) {
                isAdWebStubInflated = true;
            }
        });
        ...
    }

    /**
     * 显示H5交互广告
     */
    private void showWebAd() {
        ...
        if (!isAdWebStubInflated) {
            View h5AdLayout = mAdWebViewStub.inflate();
            mAdWebView = (H5AdWebView) h5AdLayout.findViewById(R.id.ad_web);
        }
        ...
    }

```
### Fragment懒加载
  如果应用使用一层甚至几层`ViewPager`，然后为了让加载后Fragment不被销毁而改变了`setOffscreenPageLimit()`来缓存所有Fragment，那么`ViewPager`会一次性将所有`Fragment`进行渲染，如果`Fragment`本身又包含了耗时很长的初始化将严重影响App的启动速度。即使是使用默认设置`setOffscreenPageLimit(1)`，也会加载前一页和后一页的`Fragment`。因此我们考虑需要对Fragment进行懒加载。这里可以使用两种方式来实现`Fragment`的懒加载。
  第一种方式是**继承模式**，通过继承懒加载Fragment基类，在得到用户焦点后再调用生命周期方法。具体实现如下：
```java
/**
 * 使用继承方式实现的懒加载Fragment基类
 */
public abstract class InheritedFakeFragment extends Fragment {
    protected FrameLayout rootContainer;
    private boolean isLazyViewCreated = false;
    private LayoutInflater inflater;
    private Bundle savedInstanceState;

    @Nullable
    @Override
    public final View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        this.inflater = inflater;
        this.savedInstanceState = savedInstanceState;
        rootContainer = new FrameLayout(getContext().getApplicationContext());
        rootContainer.setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        return rootContainer;
    }

    @Override
    public final void onViewCreated(View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
    }

    @Override
    public void setUserVisibleHint(boolean isVisibleToUser) {
        super.setUserVisibleHint(isVisibleToUser);
        if (isVisibleToUser && !isLazyViewCreated && inflater != null) {
            View view = onLazyCreateView(inflater, rootContainer, savedInstanceState);
            rootContainer.addView(view);
            isLazyViewCreated = true;
            onLazyViewCreated(rootContainer, savedInstanceState);
        }
    }

    /**
     * 获取真实的fragment是否已经初始化view
     *
     * @return 已经初始化view返回true，否则返回false
     */
    @SuppressWarnings("unused")
    public boolean isLazyViewCreated() {
        return isLazyViewCreated;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        isLazyViewCreated = false;
    }

    /**
     * 用于替代真实Fragment的onCreateView，在真正获取到用户焦点后才会调用
     *
     * @param inflater           - The LayoutInflater object that can be used to inflate any views in the fragment,
     * @param container          - If non-null, this is the parent view that the fragment's UI should be attached to. The fragment should not add the view itself, but this can be used to generate the LayoutParams of the view.
     * @param savedInstanceState - If non-null, this fragment is being re-constructed from a previous saved state as given here.
     * @return Return the View for the fragment's UI, or null.
     */
    protected abstract View onLazyCreateView(LayoutInflater inflater, ViewGroup container, @Nullable Bundle savedInstanceState);

    /**
     * 用来代替真实Fragment的onViewCreated，在真正获得用户焦点并且{@link #onLazyViewCreated(View, Bundle)}
     *
     * @param view               - The View returned by onCreateView(LayoutInflater, ViewGroup, Bundle).
     * @param savedInstanceState - If non-null, this fragment is being re-constructed from a previous saved state as given here.
     */
    protected abstract void onLazyViewCreated(View view, @Nullable Bundle savedInstanceState);

}
```
真正的Fragment需要继承`InheritedFakeFragment`，并将的`onCreateView`，`onViewCreated`方法修改为`onLazyCreateView`，`onLazyViewCreated`。修改如下图所示。
![继承延迟加载Fragment对比.PNG](http://upload-images.jianshu.io/upload_images/2057980-b8e18697342f93c0.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

创建时直接new出来`InheritedLazyFragment.newInstance("InheritedLazyFragment", position);`。

  第一种方式是**代理模式**，先创建代理的Fragment，当代理Fragment得到用户焦点之后再将真实的Fragment加入其中。具体实现如下：

```java
/**
 * 使用代理方式实现的懒加载Fragment基类
 */
public class ProxyFakeFragment extends Fragment {
    private static final String REAL_FRAGMENT_NAME = "realFragmentName";

    private String realFragmentName;

    private Fragment realFragment;

    private LayoutInflater inflater;
    private boolean isRealFragmentAdded = false;
    private boolean isCurrentVisiable = false;


    public ProxyFakeFragment() {
        // Required empty public constructor
    }

    /**
     * Use this factory method to create a new instance of
     * this fragment using the provided parameters.
     *
     * @param realFragmentName 需要替换的真实fragment.
     * @return A new instance of fragment FakeFragment.
     */
    @SuppressWarnings("unused")
    public static ProxyFakeFragment newInstance(String realFragmentName) {
        ProxyFakeFragment fragment = new ProxyFakeFragment();
        Bundle args = new Bundle();
        args.putString(REAL_FRAGMENT_NAME, realFragmentName);
        fragment.setArguments(args);
        return fragment;
    }

    /**
     * Use this factory method to create a new instance of
     * this fragment using the provided parameters.
     *
     * @param realFragmentName 需要替换的真实fragment.
     * @param bundle           放入真实fragment 需要的bundle
     * @return A new instance of fragment FakeFragment.
     */
    @SuppressWarnings("unused")
    public static ProxyFakeFragment newInstance(String realFragmentName, Bundle bundle) {
        ProxyFakeFragment fragment = new ProxyFakeFragment();
        Bundle args = new Bundle();
        args.putString(REAL_FRAGMENT_NAME, realFragmentName);
        if (bundle != null) {
            args.putAll(bundle);
        }
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (TextUtils.isEmpty(realFragmentName) && getArguments() != null) {
            realFragmentName = getArguments().getString(REAL_FRAGMENT_NAME);
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        this.inflater = inflater;
        View view = inflater.inflate(R.layout.fragment_fake, container, false);
        setUserVisibleHint(isCurrentVisiable);
        return view;
    }

    @Override
    public void setUserVisibleHint(boolean isVisibleToUser) {
        super.setUserVisibleHint(isVisibleToUser);
        isCurrentVisiable = isVisibleToUser;
        if (TextUtils.isEmpty(realFragmentName) && getArguments() != null) {
            realFragmentName = getArguments().getString(REAL_FRAGMENT_NAME);
        }
        if (!TextUtils.isEmpty(realFragmentName) && isVisibleToUser &&
                !isRealFragmentAdded) {
            getRealFragment();
            if (inflater != null) {
                addRealFragment();
            }
        }
        if (isRealFragmentAdded) {
            realFragment.setUserVisibleHint(isVisibleToUser);
        }
    }

    /**
     * 获取对应的真正的fragment实体
     *
     * @return 真正的fragment实体
     */
    public Fragment getRealFragment() {
        if (TextUtils.isEmpty(realFragmentName) && getArguments() != null) {
            realFragmentName = getArguments().getString(REAL_FRAGMENT_NAME);
        }
        if (!TextUtils.isEmpty(realFragmentName) && realFragment == null) {
            try {
                realFragment = (Fragment) Class.forName(realFragmentName).newInstance();
                realFragment.setArguments(getArguments());
                return realFragment;
            } catch (Exception e) {
                e.printStackTrace();
                return null;
            }
        } else if (realFragment != null) {
            return realFragment;
        } else {
            return null;
        }
    }

    private void addRealFragment() {
        if (realFragment != null) {
            getChildFragmentManager()
                    .beginTransaction()
                    .add(R.id.fake_fragment_container, realFragment)
                    .commit();
            getChildFragmentManager().executePendingTransactions();
            isRealFragmentAdded = true;
        }
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        if (TextUtils.isEmpty(realFragmentName) && getArguments() != null) {
            realFragmentName = getArguments().getString(REAL_FRAGMENT_NAME);
        }
    }
}
```
使用这种代理的方式，并不需要对真实的Fragment做特殊的改动，只需要在创建的时候通过代理Fragment进行创建：
```java
Bundle bundle = new Bundle();
bundle.putString(OriginFragment.FRAGMENT_MSG, "ProxyLazyFragment");
bundle.putInt(OriginFragment.FRAGMENT_POS, position);
return ProxyFakeFragment.newInstance(OriginFragment.class.getName(), bundle);
```
具体实现代码见github项目：[shenguojun](https://github.com/shenguojun)/**[LazyFragmentTest](https://github.com/shenguojun/LazyFragmentTest)**

以下看看不同方式对Fragment生命周期的影响。
先看正常的Fragment生命周期如下：
```
05-03 16:59:17.420 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest0: Pos: 0 , setUserVisibleHint: false
05-03 16:59:17.438 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest0: Pos: 0 , onCreateView
05-03 16:59:17.439 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest0: Pos: 0 , onViewCreated
05-03 16:59:17.439 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest0: Pos: 0 , onActivityCreated
05-03 16:59:17.443 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest0: Pos: 0 , onStart
05-03 16:59:17.444 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest0: Pos: 0 , onResume
05-03 16:59:20.662 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest0: Pos: 0 , setUserVisibleHint: true
05-03 16:59:49.417 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest0: Pos: 0 , setUserVisibleHint: false
05-03 16:59:50.678 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest0: Pos: 0 , onPause
05-03 16:59:50.678 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest0: Pos: 0 , onStop
05-03 16:59:50.678 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest0: Pos: 0 , onDestroyView
```
使用继承方式真实Fragment生命周期如下：
```
05-03 17:00:20.795 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest1: Pos: 1 , setUserVisibleHint: false
05-03 17:00:20.800 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest1: Pos: 1 , onActivityCreated
05-03 17:00:20.801 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest1: Pos: 1 , onStart
05-03 17:00:20.801 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest1: Pos: 1 , onResume
05-03 17:00:22.365 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest1: Pos: 1 , onLazyCreateView
05-03 17:00:22.366 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest1: Pos: 1 , onLazyViewCreated
05-03 17:00:22.366 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest1: Pos: 1 , setUserVisibleHint: true
05-03 17:00:25.197 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest1: Pos: 1 , setUserVisibleHint: false
05-03 17:00:26.037 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest1: Pos: 1 , onPause
05-03 17:00:26.037 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest1: Pos: 1 , onStop
05-03 17:00:26.038 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest1: Pos: 1 , onDestroyView
```

使用代理方式Fragment生命周期如下：
```
05-03 17:01:01.257 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest2: Pos: 2 , setUserVisibleHint: false
05-03 17:01:01.260 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest2: Pos: 2 , onCreateView
05-03 17:01:01.260 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest2: Pos: 2 , onViewCreated
05-03 17:01:01.260 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest2: Pos: 2 , onActivityCreated
05-03 17:01:01.261 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest2: Pos: 2 , onStart
05-03 17:01:01.261 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest2: Pos: 2 , onResume
05-03 17:01:01.761 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest2: Pos: 2 , setUserVisibleHint: true
05-03 17:01:03.625 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest2: Pos: 2 , setUserVisibleHint: false
05-03 17:01:04.132 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest2: Pos: 2 , onPause
05-03 17:01:04.133 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest2: Pos: 2 , onStop
05-03 17:01:04.134 27200-27200/me.xshen.lazyfragmenttest D/FragmentTest2: Pos: 2 , onDestroyView
```

可以看出使用代理方式不改变Fragment的生命周期，但是使用继承方式改变了Fragment的调用顺序。两种方式的优缺点如下表：

| 实现方式| 优点| 缺点|
| :---: |:---:| :---:|
|继承方式|不需要改变创建及管理代码|`onResume()`等方法在真实的`createView`之前调用，生命周期与没延迟化之前有差异|
|代理方式|1. 不需要改变真实Fragment代码</br> 2. 生命周期没有变化|管理以及创建代码需要修改|

效果如下：

![fragment-lazy-load.gif](http://upload-images.jianshu.io/upload_images/2057980-2af5d3b670175797.gif?imageMogr2/auto-orient/strip)


### 使用后台线程
  在启动的过程中，尽量把能在后台做的任务都放到后台，可以使用以下几个方式来执行后台任务：
* **AsyncTask**: 为UI线程与工作线程之间进行快速的切换提供一种简单便捷的机制。适用于当下立即需要启动，但是异步执行的生命周期短暂的使用场景。
* **HandlerThread**: 为某些回调方法或者等待某些任务的执行设置一个专属的线程，并提供线程任务的调度机制。
* **ThreadPool**: 把任务分解成不同的单元，分发到各个不同的线程上，进行同时并发处理。
* **IntentService**: 适合于执行由UI触发的后台Service任务，并可以把后台任务执行的情况通过一定的机制反馈给UI。

### 使用EventBus
  适当地使用EventBus可以延后一些初始化。在需要的地方post一个事件，EventBus会通知注册过这些事件的地方，这样可以把一些初始化在真实需要的时候再post一个触发事件，然后延后初始化。

**EventBus使用3步骤**
1. 定义事件:
    ```java  
    public static class MessageEvent { /* Additional fields if needed */ }
    ```
2. 在需要的地方注册:
    可以指定线程模式 [thread mode](http://greenrobot.org/eventbus/documentation/delivery-threads-threadmode/):  
    ```java
    @Subscribe(threadMode = ThreadMode.MAIN)  
    public void onMessageEvent(MessageEvent event) {/* Do something */};
    ```
    注册与反注册
   ```java
    @Override
    public void onStart() {
        super.onStart();
        EventBus.getDefault().register(this);
    }

    @Override
    public void onStop() {
        super.onStop();
        EventBus.getDefault().unregister(this);
    }
    ```
3. 发送事件:
   ```java
    EventBus.getDefault().post(new MessageEvent());
    ```
**更详细的使用参见 [How to get started with EventBus in 3 steps](http://greenrobot.org/eventbus/documentation/how-to-get-started/).**

### 启动闪屏主题设置
  默认的启动闪屏是白色的，某些开发者会通过设置一个透明的启动闪屏主题来隐藏启动加载慢的问题，不过这种做法会影响用户体验。我们可以通过设置一个带logo的启动闪屏主题来让用户感受到在点击桌面图标后马上得到响应。不过这里需要注意启动闪屏主题不能使用很大的图片资源，因为加载这些资源本身也是耗时的。
  设置启动闪屏可以在第一个展示的Acitivty设置主题：

AndroidManifest.xml：
```
<activity
    android:name=".activity.DictSplashActivity"
    android:theme="@style/MyLightTheme.NoActionBar.FullScreen">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity>
```
styles.xml：
```
<style name="MyLightTheme.NoActionBar.FullScreen" parent="MyLightTheme.NoActionBar">
    <item name="android:windowBackground">@drawable/bg_launcher</item>
    <item name="android:windowFullscreen">true</item>
</style>
```
bg_launcher.xml:
```
<?xml version="1.0" encoding="utf-8"?><!--
  ~ @(#)bg_launcher.xml, 2017-02-06.
  ~
  ~ Copyright 2014 Yodao, Inc. All rights reserved.
  ~ YODAO PROPRIETARY/CONFIDENTIAL. Use is subject to license terms.
  -->

<layer-list xmlns:android="http://schemas.android.com/apk/res/android"
    android:opacity="opaque">
    <!-- The background color, preferably the same as your normal theme -->
    <item>
        <shape android:shape="rectangle">
            <solid android:color="@color/background_grey"/>
            <size android:height="640dp" android:width="360dp"/>
        </shape>
    </item>
    <!-- Your product logo - 144dp color version of your app icon -->
    <item>
        <bitmap
            android:gravity="bottom|center"
            android:src="@drawable/splash_bottom" />
    </item>
</layer-list>
```
效果如下：

![启动闪屏主题.gif](http://upload-images.jianshu.io/upload_images/2057980-cd350aa92e616b28.gif?imageMogr2/auto-orient/strip)

### 其他可以优化的细节
* 减少广告等业务逻辑时间
  这里属于业务逻辑的优化，可根据不同的应用发掘可以缩短的等待时间。
* 将`SharePreferences`中的commit改为apply
  `SharePreferences`的操作涉及文件的读写，最好尽量使用apply方法代替commit方法。apply方法会先将结果保存在内存的`SharePreferences`中并异步地更新SharePreferences文件
* `onPause`不要执行太多任务
  在展示另一个Acitivty之前，需要经过上一个Acitvity的`onPause()`方法，因此在Activity的`onPause()`方法中不适合有耗时的工作。
*  `ContentProvider`不要做太多静态初始化以及在`onCreate()`中做耗时操作。
  因为`ContentProvider`的`onCreate()`会在Application  `onCreate()`之前调用。
* 减少View层级
  减少View的层级可以有效避免过度绘制，减少不必要的绘制过程。
* 注意内存抖动
  瞬间产生大量的对象会严重占用Young Generation的内存区域，当达到阀值，剩余空间不够的时候，会触发GC。即使每次分配的对象占用了很少的内存，但是他们叠加在一起会增加Heap的压力，从而触发更多其他类型的GC。这个操作有可能会影响到帧率，并使得用户感知到性能问题。
* 用更快的方式获取信息，例如获取Webview UA
  获取Webview UA可以通过创建要给Webview然后获取setting中的UserAgent，不过为了获取UA而创建Webview是一个比较耗时的操作。我们可以在API17及以上的系统中通过`WebSettings.getDefaultUserAgent(context)`快速获取。
* 尽量删除没必要的中间过渡Activity，减少Activity切换时间
  Activity的切换是比较耗时的，如果没有必要，我们可以将达到主要页面之前的Activity删除，或者修改成Fragment动态加入。

## 后记
  通过之前的分析以及这篇文章介绍的启动优化方法，我们词典的启动速度得到了50%的提升，有效地提升了用户体验。在以后的开发过程中，当涉及到启动流程的代码时需要格外谨慎，避免有耗时的操作加入。当然目前的词典启动速度还可以进一步优化，可以思考的方向一下几点：1. 进一步优化信息流布局，减少不必要的绘制；2. 深入探索第三方SDK带来的启动速度延迟并尝试优化；3. 获取更多实时广告的成功率并尝试去除实时广告逻辑。

## 参考
【1】[胡凯](http://hukai.me/)，2016.[Android性能优化典范 - 第5季](http://hukai.me/android-performance-patterns-season-5/)

【2】[胡凯](http://hukai.me/)，2016.[Android性能优化典范 - 第6季](http://hukai.me/android-performance-patterns-season-6/)

【3】[TellH的博客](http://blog.csdn.net/tellh)，2016.[实现类似微信Viewpager-Fragment的惰性加载，lazy-loading](http://blog.csdn.net/tellh/article/details/50705178)
