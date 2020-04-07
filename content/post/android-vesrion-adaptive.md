---
title: "targetSdkVersion升级到28一些修改的地方"
date: 2018-11-16T20:00:40+08:00
author: 申国骏
tags: ["android"]
---

# 前言
Android官方的迁移适配文档有点混乱，这篇文章旨在给开发者在适配中对代码做快速检查。适配变化将分为运行版本影响和Target版本影响，并提供可能影响的功能以便测试参考。转载请注明来源[「Bug总柴」](https://www.jianshu.com/u/b692bbf77991) 

# Android Q (API level 29)
## 沙箱机制([scoped-storage](https://developer.android.com/preview/privacy/scoped-storage))
在Android Q中变化比较大的是对外置sdcard的访问权限变化，这个变化将会影响大部分需要访问外置存储的应用。

### 沙箱机制解读
1. external storage在Android Q开始被设置成像internal storage那种只能访问自己包名下的空间，无法直接访问sdcard其他位置内容。就算声明了READ_EXTERNAL_STORAGE权限，在应用中通过File.listFiles只能看到/storage/emulated/0/Android/data/<package> , /storage/emulated/0/Android/media/<package> , /storage/emulated/0/Android/obb/<package> 三个文件夹。
2. READ_EXTERNAL_STORAGE和WRITE_EXTERNAL_STORAGE的通用访问外置sdcard的权限被拆分为访问音乐READ_MEDIA_AUDIO、照片READ_MEDIA_IMAGES和视频READ_MEDIA_VIDEO三种权限，而访问应用沙箱的内容无需额外申请权限。

### 沙箱生效时机
1. 如果target版本小于等于28并且应用是安装在从Android 9升级到Andoid Q的手机上，则会启用兼容模式，仍然可以随意访问external存储的内容。
2. 意味着当target版本大于28，或者应用是在Android Q的手机上新安装都会使沙箱机制生效。这里需要说明，不管是否target到28以上，只要是在Android Q上新安装的应用都会使沙箱机制生效。
3. 对于模拟器里面的Andorid Q Beta 1版本，需要执行adb shell sm set-isolated-storage on开启沙箱机制

### 影响范围
1. 各种为了实现离线使用功能的离线下载文件
2. 各种缓存文件（例如信息流缓存、广告缓存等）
3. 需要注意某些三方库可能会使用外置sdcard（例如log或者crash统计等）

四、处理办法
1. 对于图片视频音乐和下载文件可以通过MediaStore类访问，或者使用Storage Access Framework
2. 对于之前存储在外置sdcard的其他数据，需要迁移存储到getExternalFilesDir目录中
3. 对于新增的文件尽量保存在getExternalFilesDir和getExternalCacheDir

### Api检查
Context.getExternalFilesDir(null) ->  /storage/emulated/0/Android/data/<package>/files
Context.getExternalFilesDir(Environment.DIRECTORY_PICTURES) -> /storage/emulated/0/Android/data/<package>/files/Pictures
Context.externalCacheDir -> /storage/emulated/0/Android/data/<package>/cache
Context.obbDir -> /storage/emulated/0/Android/obb/<package>
Environment.getExternalStorageDirectory() ->  /storage/emulated/0 （沙箱机制下无法访问）
Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES) -> /storage/emulated/0/Pictures （沙箱机制下无法访问）

# Android 9 (API level 28)
[官方行为变更文档](https://developer.android.com/about/versions/pie/android-9.0-changes-all)

## 非SDK接口使用限制
使用 [veridex](https://android.googlesource.com/platform/prebuilts/runtime/+/master/appcompat)工具测试apk是否有调用非SDK接口
```shell
➜  veridex-mac ./appcompat.sh --dex-file=test.apk
```
实例结果如下：
```shell
6889 hidden API(s) used: 6817 linked against, 72 through reflection
       0 in blacklistgetConnectionInfo
       3 in dark greylist
       47 in light greylist
To run an analysis that can give more reflection accesses, 
but could include false positives, pass the --imprecise flag.
```
其中：  
类型 | 描述
---|---
blacklist | 不管是否target到28，都会报```NoSuchMethodError/NoSuchFieldException```  
dark greylist | 如果target在28一下没问题，但是target到28及以上会报```NoSuchMethodError/NoSuchFieldException```  
light greylist | 暂时没有问题，可以使用

处理办法：  
去除blacklist以及dark greylist的非android sdk调用的反射调用，有些是android support包内部调用的可以考虑升级support包版本

## 隐私&权限相关

运行在9.0受到影响 |  可能受到影响的功能
---|---
不能在后台访问麦克风和摄像头 | 后台录音、后台拍照
加速器陀螺仪等传感器不能在后台持续获取数据|步数计算
通过[变化模式](https://source.android.com/devices/sensors/report-modes#on-change)或者[单次模式](https://source.android.com/devices/sensors/report-modes#one-shot)的传感器收不到事件|显著运动检测、计步器、近程传感器和心率传感器 
通话记录权限组别由```PHONE```组调整到```CALL_LOG```组|需要获通过记录权限的功能
通过```android.intent.action.PHONE_STATE```或```TelephonyManager.listen```方法获取手机号码需要申请```READ_CALL_LOG```   权限| 例如来电归属地显示或者来电拦截等需要获取通话手机号的功能
wifi扫描频率限制更为严格，```getConnectionInfo WifiManager.getScanResults()```以及``` WifiManager.startScan()```需要而外权限[详见](https://developer.android.com/guide/topics/connectivity/wifi-scan#wifi-scan-restrictions) | 需要wifi扫描匹配等功能
```WifiManager.getConnectionInfo()``` 要获得SSID和BSSID，要求定位权限并要求设备打开定位功能，```NETWORK_STATE_CHANGED_ACTION ```不再能获得SSID和BSSID|需要获取wifi信息的功能
WifiManager与WifiP2pManager中```getScanResults() getConnectionInfo()```和```discoverServices() addServiceRequest()```和```NETWORK_STATE_CHANGED_ACTION```不再包含用户定位信息|使用wifi定位功能
```TelephonyManager```中[getAllCellInfo()](https://developer.android.com/reference/android/telephony/TelephonyManager.html#getAllCellInfo()) [listen()](TelephonyManager#listen(android.telephony.PhoneStateListener,%20int)) [getCellLocation()](https://developer.android.com/reference/android/telephony/TelephonyManager.html#getCellLocation()) [getNeighboringCellInfo()](https://developer.android.com/reference/android/telephony/TelephonyManager.html#getNeighboringCellInfo())不返回结果，除非用户打开了定位功能|使用移动信号定位



Target在9.0受到影响 | 可能受到影响的功能
---|---
启动前台服务要去注册```android.permission.FOREGROUND_SERVICE```权限 | 前台服务启动
获取序列号不能通过Build.SERIAL，需要注册```android.permission.READ_PHONE_STATE```然后使用```Build.getSerial()```|获取序列号相关功能

## 安全相关

运行在9.0受到影响 |  可能受到影响的功能
---|---
```SSLSocket```出错不返回```NullPointerException```，改成返回```IOException``` | https网络错误处理
加密函数```Cipher.getInstance("AES/CBC/PKCS7PADDING", "BC")``` ```Cipher.getInstance("AES/CBC/PKCS7PADDING",Security.getProvider("BC"))``` ```SecureRandom.getInstance("SHA1PRNG", "Crypto");```移除| 加密功能
Android secure encrypted files移除|移动app到sdcard功能


Target在9.0受到影响 | 可能受到影响的功能
---|---
DNS客户端需要根据系统使用加密DNS查找与系统相同的主机名，或改由系统解析程序 | DNS自解析功能
默认要求使用https，如果需要使用http需要设置```cleartextTrafficPermitted="true"```[详见](https://developer.android.com/training/articles/security-config) | 所有http网络请求
webview的数据包括cookies和caches不允许多进程共享|多进程使用webview
不用通过设置全局Unix权限共享数据文件，不用应用的文件共享需要使用ContentProvider|应用间文件共享

## 国际化相关

运行在9.0受到影响 |  可能受到影响的功能
---|---
```java.text.SimpleDateFormat``` 使用```zzzz```格式、```java.text.DateFormatSymbols.getZoneStrings()```格式、```NumberFormat.getInstance(ULocale, PLURALCURRENCYSTYLE).parse(String)```格式修改| 时区、货币显示相关功能

## 网络相关
运行在9.0受到影响 |  可能受到影响的功能
---|---
[NetworkCapabilities](https://developer.android.com/reference/android/net/NetworkCapabilities.html)支持返回[NET_CAPABILITY_NOT_VPN](https://developer.android.com/reference/android/net/NetworkCapabilities#NET_CAPABILITY_NOT_VPN) | vpn设置功能
Apache HTTP client不能使用system ClassLoader加载，若要使用需要实现自定义ClassLoader| 使用旧Apache Http client网络功能


Target在9.0受到影响 | 可能受到影响的功能
---|---
```NetworkStatsManager ```能获取非当前正在使用的流量情况 | 网络使用统计
```ConnectivityManager.getMultipathPreference()``` 可以获取是否超过了移动流量使用限制 | 网络使用情况提醒
Apache Http背去除，要使用需要加上```<uses-library android:name="org.apache.http.legacy" android:required="false"/>```或者想apache.http相关类包通过jar方式引入|使用旧Apache Http client网络功能


## 界面相关
运行在9.0受到影响 |  可能受到影响的功能
---|---
通过非activity的context启动activity强制要求intent带上```FLAG_ACTIVITY_NEW_TASK``` | 后台启动页面
屏幕旋转方式由原来的“自动旋转”和“纵向”改为“自动旋转”和“固定旋转”| 屏幕旋转功能

Target在9.0受到影响 | 可能受到影响的功能
---|---
长或宽为0的view不再可以获取焦点，新开页面不默认获取焦点|交互过程通过特殊焦点实现的功能
webview可以支持带透明度的8位颜色css|webview css 颜色透明度功能
webview中document的root元素滚动位置得到支持|webview 相关
暂停挂起app的通知会在app resumed之后重新通知|通知相关

## 设备相关
运行在9.0受到影响 |  可能受到影响的功能
---|---
多摄像头支持```getCameraIdList()```前后摄像头切换需要选择合适的摄像头 | 摄像头相关功能

## 其他
运行在9.0受到影响 |  可能受到影响的功能
---|---
UTF-8解码更加严格按照Unicode标准[详见](https://developer.android.com/about/versions/pie/android-9.0-changes-all?hl=zh-cn#decoder) | UTF-8解码相关的功能

## 实用参考地址
[权限组级别](https://developer.android.com/guide/topics/permissions/overview)

# Android 8 (API level 26)
[官方行为变更文档](https://developer.android.com/about/versions/oreo/android-8.0-changes)

## 后台限制

运行在8.0受到影响 |  可能受到影响的功能
:---:|---
[后台应用](https://developer.android.com/about/versions/oreo/background#services)通过```startService()```方法启动服务，<br>包括```IntentService```会受到限制并抛出```IllegalStateException```异常，<br>需要改成使用 ```JobScheduler ``` 或者```JobIntentService``` | 所有启动后台服务的行为，包括但不限于后台下载、后台数据更新、后台初始化等等
前台服务启动不能通过启动后台服务再将其转换为前台，<br>需要通过[startForegroundService()](https://developer.android.com/reference/android/content/Context#startForegroundService(android.content.Intent))方法，<br>并在5s内调用[startForeground()](https://developer.android.com/reference/android/app/Service#startForeground(int,%20android.app.Notification))方法显示前台通知，否则会ANR|所有前台服务，包括音乐播放功能、其他有通知的服务
自定义action广播以及其他[系统非指向性的广播](https://developer.android.com/guide/components/broadcast-exceptions)接收受到限制，<br>可通过manifests注册指向性广播或者通过```Context.registerReceiver()```动态注册，<br>系统性的广播事件可考虑通过```JobScheduler```配置实现|例如软件安装后的广播处理以及网络变化通知处理功能
后台应用获取位置受到限制，包括[FusedLocationProviderApi](https://developers.google.com/android/reference/com/google/android/gms/location/FusedLocationProviderApi)、<br>[GnssMeasurement](https://developer.android.com/reference/android/location/GnssMeasurement)、[GnssNavigationMessage](https://developer.android.com/reference/android/location/GnssNavigationMessage)、<br>[WifiManager.startScan()](https://developer.android.com/reference/android/net/wifi/WifiManager#startScan())、[LocationManager](https://developer.android.com/reference/android/location/LocationManager)，需要使用前台服务保持[应用前台状态](https://developer.android.com/about/versions/oreo/background-location-limits)|后台动作检测功能、后台需要用到地理位置的功能例如后台导航之类


## 隐私&权限相关

运行在8.0受到影响 |  可能受到影响的功能
---|---
[ANDROID_ID](https://developer.android.com/reference/android/provider/Settings.Secure#ANDROID_ID)从之前的仅与设备相关，改为与应用签名、设备、设备登录用户相关。|使用```ANDROID_ID```的功能
获取系统属性```net.hostname```将返回null|wifi hostname获取功能

Target在8.0受到影响 | 可能受到影响的功能
---|---
系统属性```net.dns*```不再支持|通过系统属性获取dns功能
需要获取DNS信息需要```ACCESS_NETWORK_STATE```权限，通过<br>[NetworkRequest](https://developer.android.com/reference/android/net/NetworkRequest.html)或者[NetworkCallback](https://developer.android.com/reference/android/net/ConnectivityManager.NetworkCallback.html)获取|DNS获取功能
获取序列号不能通过Build.SERIAL，需要注册```android.permission.READ_PHONE_STATE```然后使用```Build.getSerial()```|获取序列号相关功能
[LauncherApps](https://developer.android.com/reference/android/content/pm/LauncherApps.html)获取不同用户的应用信息时，会当做没有任何应用安装，而不是抛出异常|桌面启动器相关功能
相同权限组的其他权限会在真正需要时才被自动授予，之前是整个权限组同时授予|权限授予相关


## 安全相关

运行在8.0受到影响 |  可能受到影响的功能
---|---
不再支持SSLv3|使用SSLv3的地方
当HTTPS使用错误的TLS协议与服务交互时，不再使用其他TLS协议重试|HTTPS相关
在bionic之外的系统调用将被禁止|bionic系统调用
WebView被运行在多进程空间|WebView间数据共享
APKs安装路径可能会被修改|APKs管理
判断是否能安装应用需使用[PackageManager.canRequestPackageInstalls()](https://developer.android.com/reference/android/content/pm/PackageManager#canRequestPackageInstalls())，<br>```INSTALL_NON_MARKET_APPS```失效|应用安装
8.0系统默认禁止应用安装未知应用|应用安装功能
```Thread.UncaughtExceptionHandler``` 会记录在stacktrace中，但不会杀死应用|线程异常处理


Target在8.0受到影响 | 可能受到影响的功能
---|---
[registerContentObserver(Uri, boolean, ContentObserver)](https://developer.android.com/reference/android/content/ContentResolver.html#registerContentObserver(android.net.Uri,%20boolean,%20android.database.ContentObserver))中的Uri必须使用```ContentProvider```注册|以Uri来通知变化的功能
```network_security_config.xml``` 配置禁止明文传输将同样影响WebView|Https功能
AccountManager不能只通过申明```GET_ACCOUNTS```来获取账号，需要调用<br>[AccountManager.newChooseAccountIntent()](https://developer.android.com/reference/android/accounts/AccountManager.html#newChooseAccountIntent(android.accounts.Account,%20java.util.List%3Candroid.accounts.Account%3E,%20java.lang.String[],%20java.lang.String,%20java.lang.String,%20java.lang.String[],%20android.os.Bundle))让用户选择，<br>再通过[AccountManager.getAccounts()](https://developer.android.com/reference/android/accounts/AccountManager.html#getAccounts())来获取 | Account Services相关
native库若包含可执行文件则不会加载|native库相关
JNI调用会检查反射的类或方法是否存在，否则会抛出异常|JNI调用
DexFile API已经过时，建议使用系统默认```PathClassLoader``` 或者 ```BaseDexClassLoader```。<br>如果需要用到DexFile，不应该进行压缩，否则会解压消耗内存。<br>多线程加载相同类由最先加载的类的加载器决定。|Dex 加载相关


## 国际化相关

运行在8.0受到影响 |  可能受到影响的功能
:---:|---
[Currency.getDisplayName()](https://developer.android.com/reference/java/util/Currency.html#getDisplayName())、[Currency.getSymbol()](https://developer.android.com/reference/java/util/Currency.html#getSymbol())、<br>[Locale.getDisplayScript()](https://developer.android.com/reference/java/util/Locale.html#getDisplayScript())<br>默认调用[Locale.getDefault(Category.DISPLAY)](https://developer.android.com/reference/java/util/Locale.html#getDefault(java.util.Locale.Category))|国际化显示
[Currency.getDisplayName(null)](https://developer.android.com/reference/java/util/Currency.html#getDisplayName())将会抛出异常|国际化单位显示
对于```SimpleDateFormat```的时区获取由原来在设备第一次启动时候获取，改为每次实时获取|时区显示
升级[ICU](http://site.icu-project.org/home)到58版本|国际化单位标准

## 网络相关

运行在8.0受到影响 |  可能受到影响的功能
---|---
无正文的 OPTIONS 请求具有 Content-Length: 0 头部|options请求相关
HttpURLConnection会保证请求最后带上“/” | HttpURLConnection
```ProxySelector.setDefault() ```设置的代理仅处理scheme/host/port，不会处理请求参数| 代理设置相关功能
不再支持空lable的URI|使用URI相关功能
HttpsURLConnection不会执行不安全的TLS/SSL协议版本回退|HttpsURLConnection
隧道Https协议改变，具体见[Networking and HTTP(S) connectivity](https://developer.android.com/about/versions/oreo/android-8.0-changes#networking-all)|隧道Https
如果```DatagramSocket.connect() ```返回错误，[DatagramSocket.send()](https://developer.android.com/reference/java/net/DatagramSocket.html#send(java.net.DatagramPacket))也会返回错误|socket相关
```InetAddress.isReachable()``` 会在会退到TCP Echo协议之前尝试ICMP协议，若不可达会消耗更多时间|IP地址判断是否可达等网络功能
在支持设备上wifi连接当有强度大且已经保存的网络时可以自动切换|需保证网络切换不会影响应用功能



## 界面相关

运行在8.0受到影响 |  可能受到影响的功能
:---:|---
[TYPE_PHONE](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_PHONE)、[TYPE_PRIORITY_PHONE](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_PRIORITY_PHONE)、<br>[TYPE_SYSTEM_ALERT](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_SYSTEM_ALERT)、[TYPE_SYSTEM_OVERLAY](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_SYSTEM_OVERLAY)、<br> [TYPE_SYSTEM_ERROR](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_SYSTEM_ERROR)这些类型的窗口都会显示在[TYPE_APPLICATION_OVERLAY](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_APPLICATION_OVERLAY)之下|悬浮球、快速查词等需要弹窗弹窗的地方
使用键盘导航时，获取焦点的view将会加上ripple高亮，<br>如果不需要这种默认的高亮，<br>需要设置```android:defaultFocusHighlightEnabled```<br>或者```setDefaultFocusHighlightEnabled(false)```|键盘导航
webview中[WebSettings.getSaveFormData()](https://developer.android.com/reference/android/webkit/WebSettings.html#getSaveFormData())返回false，<br>[WebSettings.setSaveFormData()](https://developer.android.com/reference/android/webkit/WebSettings.html#setSaveFormData(boolean))没有任何作用，<br>[WebViewDatabase.clearFormData()](https://developer.android.com/reference/android/webkit/WebViewDatabase.html#clearFormData())没有任何作用，<br>[WebViewDatabase.hasFormData()](https://developer.android.com/reference/android/webkit/WebViewDatabase.html#hasFormData())返回false| 网页相关

Target在8.0受到影响 | 可能受到影响的功能
:---:|---
[TYPE_PHONE](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_PHONE)、[TYPE_PRIORITY_PHONE](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_PRIORITY_PHONE)、<br>[TYPE_SYSTEM_ALERT](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_SYSTEM_ALERT)、[TYPE_SYSTEM_OVERLAY](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_SYSTEM_OVERLAY)、<br>[TYPE_SYSTEM_ERROR](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_SYSTEM_ERROR)<br>不能用在alert window上，必须使用<br>[TYPE_APPLICATION_OVERLAY](https://developer.android.com/reference/android/view/WindowManager.LayoutParams.html#TYPE_APPLICATION_OVERLAY)|悬浮球、快速查词等需要弹窗弹窗的地方
可点击的View默认拥有可获取焦点属性|View焦点显示
Notificaiton通知必须指定Notificaiton Channels，否则不会显示通知，详见[notifications](https://developer.android.com/about/versions/oreo/android-8.0#notifications)|通知相关

## 设备相关

运行在8.0受到影响 |  可能受到影响的功能
---|---
蓝牙[ScanRecord.getBytes()](https://developer.android.com/reference/android/bluetooth/le/ScanRecord.html#getBytes())返回长度不受限制|蓝牙相关功能

Target在8.0受到影响 | 可能受到影响的功能
---|---
音频获取焦点时会自动降低其他音频音量，现在支持暂停而不是降低音量，详见[automatic ducking](https://developer.android.com/guide/topics/media-apps/audio-focus#automatic-ducking)| 音频播放相关功能
当来电时，自动静音音频播放|音频播放相关功能
需要使用[AudioAttributes](https://developer.android.com/reference/android/media/AudioAttributes.html)实现音频回放功能，[AudioTrack](https://developer.android.com/reference/android/media/AudioTrack.html#AudioTrack(int,%20int,%20int,%20int,%20int,%20int))过期|音频回放功能
音量按键事件会优先给前台activity，如果前台activity不处理会给最近一次播放音频的应用|音量控制

## 其他

运行在8.0受到影响 |  可能受到影响的功能
:---:|---
应用快捷方式不能通过```com.android.launcher.action.INSTALL_SHORTCUT```创建，<br>需要使用[ShortcutManager](https://developer.android.com/reference/android/content/pm/ShortcutManager.html)，具体如何创建可以看[这篇文章](https://www.jianshu.com/p/7b8706fb79e4)|快捷方式创建功能
无障碍功能中双击动作转换为点击动作、<br>能识别TextView中的ClickableSpan|无障碍功能
```findViewById()``` 返回类型由View改为```<T extends View> T``` | 覆盖```findViewById()``` 的地方需要相应修改
从2019年1月7日起，将无法通过<br>[LAST_TIME_CONTACTED](https://developer.android.com/reference/android/provider/ContactsContract.ContactOptionsColumns#LAST_TIME_CONTACTED)<br>/[TIMES_CONTACTED](https://developer.android.com/reference/android/provider/ContactsContract.ContactOptionsColumns#TIMES_CONTACTED)<br>/[LAST_TIME_USED](https://developer.android.com/reference/android/provider/ContactsContract.DataUsageStatColumns#LAST_TIME_USED)<br>/[TIMES_USED](ContactsContract.DataUsageStatColumns.TIMES_USED)<br>获取联系人使用情况|联系人联系情况获取功能
[AbstractCollection.removeAll(java.util.Collection)](https://developer.android.com/reference/java/util/AbstractCollection.html#removeAll(java.util.Collection%3C?%3E))<br>/[AbstractCollection.retainAll(java.util.Collection)](https://developer.android.com/reference/java/util/AbstractCollection.html#retainAll(java.util.Collection%3C?%3E))<br>当传入参数为null时会报```NullPointerException```|集合操作

Target在8.0受到影响 | 可能受到影响的功能
---|---
浏览器ua会包含```OPR```有可能导致判断是否Opera浏览器失效|根据ua判断浏览器
[Collections.sort()](https://developer.android.com/reference/java/util/Collections.html#sort(java.util.List%3CT%3E))改为在[List.sort()](https://developer.android.com/reference/java/util/List.html#sort(java.util.Comparator%3C?%20super%20E%3E))基础上实现，之前是恰好相反。<br>如果在[List.sort()](https://developer.android.com/reference/java/util/List.html#sort(java.util.Comparator%3C?%20super%20E%3E))中调用[Collections.sort()](https://developer.android.com/reference/java/util/Collections.html#sort(java.util.List%3CT%3E))会产生死循环|集合排序
在遍历的过程中进行排序，现在使用无论使用```List.sort()```还是```Collections.sort()```都会报错|集合排序

