---
title: "targetSdkVersion升级到28一些修改的地方"
date: 2018-07-18T20:00:40+08:00
author: 申国骏
tags: ["android"]
---

## 前言
Google Play应用市场对于应用的targetSdkVersion有了更为严a格的要求。从 2018 年 8 月 1 日起，所有向 Google Play 首次提交的新应用都必须针对 Android 8.0 (API 等级 26) 开发； 2018 年 11 月 1 日起，所有 Google Play 的现有应用更新同样必须针对 Android 8.0。

以下记录了我们升级targetSdkVersion的坑以及解决办法，希望对各位开发者有帮助。

## 错误1. java.lang.IllegalStateException: Not allowed to start service Intent {}: app is in background uid UidRecord{}

### 原因分析
从Android8.0开始，[系统会对后台执行进行限制](https://developer.android.com/about/versions/oreo/background)。初步判断由于我们应用在Application的onCreate过程中使用了IntentService来后台初始化一些任务，这个时候被系统认为是应用还处于后台，从而报出了java.lang.IllegalStateException错误。

### 解决办法
解决后台服务的限制，首先想到的办法是将服务变成前台服，随即我们又遇到了另一个问题，见错误2

## 错误2. android.app.RemoteServiceException: Context.startForegroundService() did not then call Service.startForeground(): ServiceRecord{}

### 原因分析
见Android8.0[行为变更](https://developer.android.com/about/versions/oreo/android-8.0-changes#back-all)。新的 Context.startForegroundService() 函数将启动一个前台服务。现在，即使应用在后台运行，系统也允许其调用 Context.startForegroundService()。不过，应用必须在创建服务后的五秒内调用该服务的 startForeground() 函数。

### 解决办法
在后台服务启动执行执行之后，通过[Service.startForeground()](https://developer.android.com/reference/android/app/Service.html#startForeground(int,%20android.app.Notification))方法传入notification变成前台服务。需要注意的是从Android8.0开始，Notification必须制定Channel才可以正常弹出通知，如果创建Notification Channels详见[这里](https://developer.android.com/training/notify-user/channels)。

由于我们的初衷是在启动程序的过程中后台进行一些初始化，这种前台给用户带来感知的效果并不是我们所希望的，因此我们考虑可以采用另一个后台执行任务的方法。这里官方推荐使用[JobScheduler](https://developer.android.com/reference/android/app/job/JobScheduler)。由于我们引入了ktx以及[WorkManager](https://developer.android.com/topic/libraries/architecture/workmanager)，这里我们采用了[OneTimeWorkRequest](https://developer.android.com/reference/androidx/work/OneTimeWorkRequest)来实现。具体实现如下：
```kotlin
class InitWorker : Worker(){
    override fun doWork(): Result {
        // 把耗时的启动任务放在这里

        return Result.SUCCESS
    }
}
```
然后在Applicaiton的onCreate中调用
```kotlin
val initWork = OneTimeWorkRequestBuilder<InitWorker>().build()
WorkManager.getInstance().enqueue(initWork)
```
来执行后台初始化工作

## 错误3.  java.lang.NoClassDefFoundError: Failed resolution of: Lorg/apache/http/ProtocolVersion; Caused by: java.lang.ClassNotFoundException: Didn't find class "org.apache.http.ProtocolVersion"

### 原因分析
Android P Developer Preview的[bug](https://issuetracker.google.com/issues/79478779)

### 解决办法
在AndroidManifest.xml文件中<Application>标签里面加入
```xml
<uses-library android:name="org.apache.http.legacy" android:required="false"/>
```

## 错误4. java.io.IOException: Cleartext HTTP traffic to dict.youdao.com not permitted

### 原因分析
从Android 6.0开始引入了对Https的推荐支持，与以往不同，Android P的系统上面默认所有Http的请求都被阻止了。
```xml
<application android:usesCleartextTraffic=["true" | "false"]>
```
原本这个属性的默认值从true改变为false
### 解决办法
解决的办法简单来说可以通过在AnroidManifest.xml中的application显示设置
```xml
<application android:usesCleartextTraffic="true">
```
更为根本的解决办法是修改应用程序中Http的请求为Https，当然这也需要服务端的支持。

## 错误5. android.os.FileUriExposedException file exposed beyond app through Intent.getData()

### 原因分析
主要原因是7.0系统对file uri的暴露做了限制，加强了安全机制。详见：[官方文档](https://developer.android.com/about/versions/nougat/android-7.0-changes#permfilesys)
代码里出现问题的原因是，在需要安装应用的时候将下载下来的安装包地址传给了application/vnd.android.package-archive的intent

### 解决办法
使用[FileProvider](https://developer.android.com/reference/android/support/v4/content/FileProvider)
具体代码可参考[这篇文章](https://www.jianshu.com/p/577816c3ce93)
简单说明就是要在AndroidManifest里面声明FileProvider，并且在xml中声明需要使用的uri路径
```xml
<provider
        android:name="android.support.v4.content.FileProvider"
        android:authorities="${applicationId}.fileProvider"
        android:exported="false"
        android:grantUriPermissions="true">
        <meta-data
            android:name="android.support.FILE_PROVIDER_PATHS"
            android:resource="@xml/file_paths" />
</provider>
```
对应的xml/file_paths中指定需要使用的目录
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path
        name="download"
        path="yddownload"/>
</paths>
```

## 错误6. java.lang.SecurityException: Failed to find provider ** for user 0; expected to find a valid ContentProvider for this authority

### 原因分析
target到android8.0之后对ContentResolver.notifyChange() 以及 registerContentObserver(Uri, boolean, ContentObserver)做了限制，官方解释在[这里](https://developer.android.com/about/versions/oreo/android-8.0-changes#ccn)

### 解决办法
参考[文章](https://medium.com/@egemenhamutcu/fixing-securityexception-requiring-a-valid-contentprovider-on-android-8-1110d840522)
简单来说解决的办法就是创建一个contentprovider，并在AndroidManifest里面注册的provider的authority声明为registerContentObserver中uri的authority就可以了。
```xml
<provider
        android:name=".download.DownloadUriProvider"
        android:authorities="${applicationId}"
        android:enabled="true"
        android:exported="false"/>
```
```java
public class DownloadUriProvider extends ContentProvider {
    public DownloadUriProvider() {
    }

    @Override
    public int delete(Uri uri, String selection, String[] selectionArgs) {
        return 0;
    }

    @Override
    public String getType(Uri uri) {
        return null;
    }

    @Override
    public Uri insert(Uri uri, ContentValues values) {
        return null;
    }

    @Override
    public boolean onCreate() {
        return true;
    }

    @Override
    public Cursor query(Uri uri, String[] projection, String selection,
                        String[] selectionArgs, String sortOrder) {
        return null;
    }

    @Override
    public int update(Uri uri, ContentValues values, String selection,
                      String[] selectionArgs) {
        return 0;
    }
}
```

## 错误7. notification没有显示

### 原因分析
如果targetsdkversion设定为26或以上，开始要求notification必须知道channel，具体查阅[这里](https://developer.android.com/training/notify-user/channels)。

### 解决办法
在notify之前先创建notificationChannel
```java
private void createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        CharSequence name = "下载提醒";
        String description = "显示下载过程及进度";
        int importance = NotificationManager.IMPORTANCE_DEFAULT;
        NotificationChannel channel = new NotificationChannel(DOWNLOAD_CHANNEL_ID, name, importance);
        channel.setDescription(description);
        mNotificationManager.createNotificationChannel(channel);
    }
}
```
## 错误8. 在AndroidManifest中注册的receiver不能收到广播

### 原因分析
针对targetsdkversion为26的应用，加强对匿名receiver的控制，以至于在manifest中注册的隐式receiver都失效。具体见[官方原文](https://developer.android.com/about/versions/oreo/background#broadcasts)

### 解决办法
将广播从在AndroidManifest中注册移到在Activity中使用registerReceiver注册

## 错误9. 无法通过“application/vnd.android.package-archive” action安装应用

### 原因分析
targetsdkversion大于25必须声明REQUEST_INSTALL_PACKAGES权限，见官方说明：
[REQUEST_INSTALL_PACKAGES](https://developer.android.com/reference/android/Manifest.permission.html#REQUEST_INSTALL_PACKAGES)

### 解决办法
在AndroidManifest中加入
```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```
