# TargetsdkVersion 升级31（Android12）适配

我们升级到Targetsdk29有大半年时间了，今年为了满足审查去除蓝牙的精确定位权限，以及满足上架Google Play的要求，需要将Targetsdkversion升级到31，适配到Android12。这个过程遇到不少坑，这里记录一下，希望能对大家有所帮助。

由于我们在适配Android 29的时候已经适配了Scoped storage，因此这篇文章里面没有这部分的描述。



## 安全组件输出，exported

**编译时报错：**

android:exported needs to be explicitly specified for element <activity#xxxActivity>. Apps targeting Android 12 and higher are required to specify an explicit value for `android:exported` when the corresponding component has an intent filter defined. See https://developer.android.com/guide/topics/manifest/activity-element#exported for details.

**问题描述：**

在target到Android12之后，所有设置了intent filters的activity、services、broadcast receivers都需要设置 `android:exported` ，否则会导致编译异常。

**解决办法：**

如果需要被外部其他app访问的component（例如设置了[android.intent.category.LAUNCHER](https://developer.android.com/reference/android/content/Intent#CATEGORY_LAUNCHER) 的页面），那么需要`exported=true`，其他情况设置为`exported=false`。

* Activity

  true表示当前Activity需要被外部应用调用，例如桌面和应用需要打开当前应用首页，false表示当前Activity只能被当前的应用，或者具有相同userID的应用，或者有调用特权的系统components

* Service

  true表示可以跟外部应用的component进行交互，false表示只有自己应用内的component以及具有相同userID的应用的component可以启动并绑定这个服务。

* Receiver

  true表示可以非系统的其他应用的广播，false表示只能收到系统的、自己应用的、具有相同userID应用的广播

对于一些aar或者依赖库有里面component的报错，有两个解决办法：1. 尝试升级对应的依赖库版本，并看看是否已经进行了target android12适配；2. 在主工程中xml拷贝相关component声明，并覆盖exported设置，例如：

```xml
android:exported="true"
tools:replace="android:exported"
```



## PendingIntent mutability

**运行时报错：**

java.lang.RuntimeException: Unable to start activity ComponentInfo{xxx}: java.lang.IllegalArgumentException: Targeting S+ (version 31 and above) requires that one of FLAG_IMMUTABLE or FLAG_MUTABLE be specified when creating a PendingIntent.
    Strongly consider using FLAG_IMMUTABLE, only use FLAG_MUTABLE if some functionality depends on the PendingIntent being mutable, e.g. if it needs to be used with inline replies or bubbles.

**问题描述：**

在target到Android12之后，PendingIntent创建需要指定可变性FLAG_IMMUTABLE 或者 FLAG_MUTABLE

**解决办法：**

大部分情况下如果不希望创建的PendingIntent被外部应用修改，那么需要设置成PendingIntent.FLAG_IMMUTABLE既可。一些特殊情况可以设置成FLAG_MUTABLE（参考：https://developer.android.com/guide/components/intents-filters#DeclareMutabilityPendingIntent）

```kotlin
PendingIntent.getActivity(context, requestCode, intent, PendingIntent.FLAG_IMMUTABLE);
```



## 传感器刷新频率问题

**运行时报错：**

java.lang.SecurityException: To use the sampling rate of 0 microseconds, app needs to declare the normal permission HIGH_SAMPLING_RATE_SENSORS.
        at android.hardware.SystemSensorManager\$BaseEventQueue.enableSensor(SystemSensorManager.java:884)
        at android.hardware.SystemSensorManager$BaseEventQueue.addSensor(SystemSensorManager.java:802)
        at android.hardware.SystemSensorManager.registerListenerImpl(SystemSensorManager.java:272)
        at android.hardware.SensorManager.registerListener(SensorManager.java:835)
        at android.hardware.SensorManager.registerListener(SensorManager.java:742)

**问题描述：**

当使用`SensorManager`时，如果监听的频率太快，例如`sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_FASTEST);`，且没有改定义`permission HIGH_SAMPLING_RATE_SENSORS`权限的话会有这个崩溃。

**解决办法：**

大部分情况下我们并不需要太快的监听频率，可以设置成`SensorManager.SENSOR_DELAY_UI`。在某些确实需要快速频率监听的话，需要加上`HIGH_SAMPLING_RATE_SENSORS`权限

## ijkplayer

**运行时崩溃：**

运行时的native崩溃

**问题描述：**

在target到Android11并且在64位的安卓系统版本11及以上的手机，使用ijkplayer会产生崩溃。这里的原因是Android11对于64位的处理器中，每个指针的第一个字节将被用作标记位，用于ARM的内存标记扩展（MTE）支持。在释放内存的时候如果修改这个标记位程序就会崩溃。

那么ijkplayer在哪里会导致第一个字节被修改了呢，查看这个issues https://github.com/bilibili/ijkplayer/issues/5206 以及提交记录 https://github.com/bilibili/ijkplayer/commit/e99d640e5fe94c65132379307f92d7180bcde8e7 可以看出，主要的原因是之前将指针转换成了int64_t类型导致了精度丢失，修改的地方是将指针转成String或者无符号整形，避免精度丢失导致的首位字节丢失。

![MTE Example Diagram](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/Memory_5F00_Tagging_5F00_Blog_5F00_1040x1040.png)

例如，在上面的图中，访问0x8000的内存是可行的，因为用于进行访问的指针具有与被访问的内存相同的标签(用颜色表示)。但是，对0x9000的访问将会失败，因为指针对内存有不同的标记。

**解决办法：**

解决办法有两个，一个是拉一下ijkplayer最新的代码重新build一个依赖库更新一下，因为ijkplayer已经修改了这个错误。第二个办法是通过设置`<application android:allowNativeHeapPointerTagging="false">`暂时禁用Pointer Tagging功能。



## TelephonyManager.getNetworkType

**运行时崩溃：**

************* Crash INFO AT 04/01/2022 10:16 *************java.lang.SecurityException: getDataNetworkTypeForSubscriber
android.os.Parcel.createExceptionOrNull(Parcel.java:2389)
android.os.Parcel.createException(Parcel.java:2373)
android.os.Parcel.readException(Parcel.java:2356)
android.os.Parcel.readException(Parcel.java:2298)
com.android.internal.telephony.ITelephony\$Stub\$Proxy.getNetworkTypeForSubscriber(ITelephony.java:8762)
android.telephony.TelephonyManager.getNetworkType(TelephonyManager.java:3024)
android.telephony.TelephonyManager.getNetworkType(TelephonyManager.java:2988)

**问题描述：**

我们使用到的一个一键登录的库调用的`TelephonyManager.getNetworkType`被标记为`deprecated`，需要改成使用 `getDataNetworkType` ，并且需要加上权限`READ_PHONE_STATE` 或者 `READ_BASIC_PHONE_STAT`

**解决办法：**

升级一键登录的库，并且加上对应权限

## webview访问文件

**运行时问题：**

加载file://data目录底下数据时webview报错： 网页无法加载，net:ERR_ACCESS_DENIED

**问题描述：**

在target到Android11及以上的时候，默认setAllowFileAccess从true改成了false，无法访问到context.getDir()里面的文件，参考：https://developer.android.com/reference/android/webkit/WebSettings#setAllowFileAccess(boolean)

**解决办法：**

手动调用一下`webSettings.setAllowFileAccess(true)`

## Package可见性

**运行时问题：**

当使用[`queryIntentActivities()`](https://developer.android.com/reference/android/content/pm/PackageManager#queryIntentActivities(android.content.Intent, int)), [`getPackageInfo()`](https://developer.android.com/reference/android/content/pm/PackageManager#getPackageInfo(java.lang.String, int))或者 [`getInstalledApplications()`](https://developer.android.com/reference/android/content/pm/PackageManager#getInstalledApplications(int))查询是其他应用信息的话会查不到

**问题描述：**

当应用target到Android11之后，Package可见性受到了限制，查询其他应用信息需要加上`QUERY_ALL_PACKAGES`权限或者使用queries方式获取。

**解决办法：**

1. 在AndroidManifest.xml中加入权限`<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />`，这个需要谨慎使用，因为应用市场上线检查可能会需要提供使用的必要性说明，例如Google Play政策：https://support.google.com/googleplay/android-developer/answer/10158779

2. 在AndroidMainifest.xml中定义需要访问的应用信息，例如

   - 需要访问某个应用信息，直接指定应用包名

     ```xml
     <queries>
       <package android:name="com.example.store" />
     </queries>
     ```

   - 需要访问具有某些intent的外部组件，指定需要访问的intent

     ```xml
     <queries>
       <intent>
         <action android:name="android.intent.action.SEND" />
         <data android:mimeType="image/jpeg" />
       </intent>
     </queries>
     ```

   - 需要访问某些外部content provider，指定authoritites

     ```xml
     <queries>
       <provider android:authorities="com.example.settings.files" />
     </queries>
     ```

## 微博SDK

**运行时问题：**

微博SDK更新到最新版支持适配安卓11，遇到一个初始化的报错`please init sdk before use it. Wb.install()`

**问题描述：**

在微博进行登录授权的时候，需要获取授权信息，不过获取授权信息的时候，有一个断言判断失败了。需要在初始化之后等待一段时间。

**解决办法：**

通过循环等待的方式等待初始化断言通过再进行其他SDK操作：

```java
public static void waitForWeiboSDKValid() {
    // 微博sdk初始化需要等待一下
    // https://github.com/sinaweibosdk/weibo_android_sdk/issues/608
    // https://xie.infoq.cn/article/974795351e87627681cc353b5
    int retryCount = 0;
    while (retryCount <= 10) {
        try {
            a.b();
            break;
        } catch (Exception ignore) {
            try {
                Thread.sleep(100);
            } catch (InterruptedException ignored) {
            }
            retryCount++;
        }
    }
}

private void installWbSdk() {
   WBAPIFactory.createWBAPI(getApplicationContext());
   mWBAPI.registerApp(getApplicationContext(), authInfo);
   waitForWeiboSDKValid();
}
```

## 后台启动前台服务

**运行时崩溃：**

Caused by: android.app.ForegroundServiceStartNotAllowedException: Service.startForeground() not allowed due to mAllowStartForeground false: service XXXXService 16	at android.app.ForegroundServiceStartNotAllowedException\$1.createFromParcel(ForegroundServiceStartNotAllowedException.java:54) 17	at android.app.ForegroundServiceStartNotAllowedException\$1.createFromParcel(ForegroundServiceStartNotAllowedException.java:50) 18	at android.os.Parcel.readParcelable(Parcel.java:3345) 19	at android.os.Parcel.createExceptionOrNull(Parcel.java:2432) 20	at android.os.Parcel.createException(Parcel.java:2421) 21	at android.os.Parcel.readException(Parcel.java:2404) 22	at android.os.Parcel.readException(Parcel.java:2346) 23	at android.app.IActivityManager$Stub$Proxy.setServiceForeground(IActivityManager.java:8040) 24	at android.app.Service.startForeground(Service.java:733)

**问题描述：**

应用在target到Android12之后，如果应用在后台启用前台服务，那么就会报[`ForegroundServiceStartNotAllowedException`](https://developer.android.com/reference/android/app/ForegroundServiceStartNotAllowedException)

**解决办法：**

1. 使用WorkManager来处理后台任务
2. 避免在后台启动前台服务

## 蓝牙权限

**运行崩溃：**

Caused by: java.lang.SecurityException: Need android.permission.BLUETOOTH_CONNECT permission for android.content.AttributionSource@db46d647: enable 37	at android.os.Parcel.createExceptionOrNull(Parcel.java:2425) 38	at android.os.Parcel.createException(Parcel.java:2409) 39	at android.os.Parcel.readException(Parcel.java:2392) 40	at android.os.Parcel.readException(Parcel.java:2334) 41	at android.bluetooth.IBluetoothManager$Stub$Proxy.enable(IBluetoothManager.java:611) 42	at android.bluetooth.BluetoothAdapter.enable(BluetoothAdapter.java:1217)

**问题描述：**

在target到Android12之后，查找蓝牙设备需要添加 [`BLUETOOTH_SCAN`](https://developer.android.com/reference/android/Manifest.permission#BLUETOOTH_SCAN) 权限，与匹配的蓝牙设备传输数据需要获取[`BLUETOOTH_CONNECT`](https://developer.android.com/reference/android/Manifest.permission#BLUETOOTH_CONNECT) 权限

**解决办法：**

在查找和匹配蓝牙设备之前，先动态申请 [`BLUETOOTH_SCAN`](https://developer.android.com/reference/android/Manifest.permission#BLUETOOTH_SCAN) 权限以及[`BLUETOOTH_CONNECT`](https://developer.android.com/reference/android/Manifest.permission#BLUETOOTH_CONNECT) 权限。

## 其他

检查依赖的SDK中是否有新的版本，并进行更新，因为安全组件输出Exported以及包可见性的问题对于大多数SDK都可能会存在，所以最好都检查一下，例如华为小米OV相关的产商推送SDK，以及微信QQ微博等登录和分享的SDK。

## 参考

1. [Bluetooth permissions](https://developer.android.com/guide/topics/connectivity/bluetooth/permissions)
2. [Target API level requirements for Play Console](https://support.google.com/googleplay/android-developer/answer/9859152?visit_id=637843972853231765-3536328626&rd=1#targetsdk&zippy=%2Ctarget-api-level-requirements-for-play-console)
3. [Sensor Rate-Limiting](https://developer.android.com/guide/topics/sensors/sensors_overview#sensors-rate-limiting)
3. [Behavior changes: Apps targeting Android 12](https://developer.android.com/about/versions/12/behavior-changes-12)
3. [Behavior changes: Apps targeting Android 11](https://developer.android.com/about/versions/11/behavior-changes-11)
3. [vivo Android 12应用适配指南](https://dev.vivo.com.cn/documentCenter/doc/509)
3. [vivo Android 11应用适配指南](https://dev.vivo.com.cn/documentCenter/doc/428)
3. [oppo Android 12 应用兼容性适配指导](https://open.oppomobile.com/wiki/doc#id=10960)
3. [oppo Android 11 应用兼容性适配指导](https://open.oppomobile.com/wiki/doc#id=10724)
3. [小米 Android 12应用适配指南](https://dev.mi.com/console/doc/detail?pId=2439)
3. [Tagged Pointers](https://source.android.google.cn/devices/tech/debug/tagged-pointers)
3. [Memory Tagging Extension: Enhancing memory safety through architecture](https://community.arm.com/arm-community-blogs/b/architectures-and-processors-blog/posts/enhancing-memory-safety)
3. [Package visibility filtering on Android](https://developer.android.com/training/package-visibility)
3. [Declaring package visibility needs](https://developer.android.com/training/package-visibility/declaring)