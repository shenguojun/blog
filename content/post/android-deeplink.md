---
title: "记录一次Android Deeplink跳转失败问题修复"
date: 2018-08-18T12:57:47+08:00
author: 申国骏
tags: ["android"]
---

## Android Deeplink实现
在Android中，Deeplnk通过声明Activity的intent-filter来实现对自定义url访问事件的捕捉。在有道背单词的项目中，我们需要通过前端分享词单的方式，将词单分享给别人，并通过点击前端页面收藏按钮，实现调起客户端收藏词单的功能。  
从前端通过自定义url的方式调起客户端这个功能原来一直都没有什么问题，直到最近有部分用户反馈在某些浏览器下无法调起。下面我们来看一下分析查找问题的方法以及如何解决。

## 检查客户端deeplink配置
在AndroidManifest.xml文件中，对路由Activity配置如下：
```xml
<activity
            android:name=".deeplink.RouterActivity"
            android:configChanges="keyboardHidden|orientation|screenSize"
            android:launchMode="singleTask"
            android:theme="@style/Theme.Translucent">
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />

                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />

                <data
                    android:host="youdao.com"
                    android:scheme="recite"
                    android:pathPattern=".*"/>
            </intent-filter>

            <meta-data
                android:name="android.support.PARENT_ACTIVITY"
                android:value=".home.ui.MainActivity" />
        </activity>
```
里面比较重要的部分是intent-filter中的data配置，检查后发现配置正常，可以正常拦截到 recite://youdao.com/.*的所有请求。  
转到RouterActivity通过断点调试，发现并没有到达。从而可以确认是浏览器调起的时候发生了异常。

tips: adb 命令同样可以启动deeplink进行测试
![adb_test.png](https://upload-images.jianshu.io/upload_images/2057980-73c35e7454f39985.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 分析浏览器对deeplink处理
通过用户反馈，主要集中是在UC和华为自带的浏览器点击前端页面的【收藏词单】无法调起有道背单词  
同时我们在chrome上面发现通过deeplink只有第一次会跳转到应用，往后几次都是没有任何相应，确实有点百思不得其解。  
经过查找资料，发现了chrome的一个对Android Intent处理的介绍  
[Android Intents with Chrome](https://developer.chrome.com/multidevice/android/intents)  
里面提到
 
> One scenario is launching an app when the user lands on a page, which you can achieve by embedding an iframe in the page with a custom URI-scheme set as the src, as follows: \<iframe src="paulsawesomeapp://page1"\> \</iframe\>. This works in the Chrome for Android browser, version 18 and earlier. It also works in the Android browser, of course.

> The functionality has changed slightly in Chrome for Android, versions 25 and later. It is no longer possible to launch an Android app by setting an iframe's src attribute. For example, navigating an iframe to a URI with a custom scheme such as paulsawesomeapp:// will not work even if the user has the appropriate app installed. Instead, you should implement a user gesture to launch the app via a custom scheme, or use the “intent:” syntax described in this article.

翻译一下，大概的意思就是之前通过\<iframe\>没有用户主动操作就打开app的行为在chrome25版本及之后会被禁止。开发者必须通过用户操作来触发跳转应用的行为。目前chrome的版本都已经68了，证明这个规则已经由来已久。抱着试试看的姿态，开始查找是否是前端的代码有问题。  
通过[chrome inspect](chrome://inspect/#devices)，捕捉到前端代码果然有一处疑似iframe的使用
![ebc8daf14130474bbd69103bf4e6ff5d_ac466235c97c6e9fb45c8820addbce1d.jpg](https://upload-images.jianshu.io/upload_images/2057980-6b577639649d4752.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)  

![018ff33c02e047c59196534a3a28ef8b_e15f0d6e314113b2260119e917400191.jpg](https://upload-images.jianshu.io/upload_images/2057980-c97f1fbc1d1e2125.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)  

随后经过对前端代码debug，果然有走了这段逻辑
![ca286076d8594b55b7db5847e6d031b6_c0169d9d3acbb13b8835c5a0a8aa028f.jpg](https://upload-images.jianshu.io/upload_images/2057980-281a63c225a4f593.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)  

证据确凿，可以找前端大神反馈了。经过了解，确实是之前有改动过这部分的代码，使用了iframe来处理deeplink的打开。处理的办法也相对简单，将iframe换成href来做跳转处理就可以了。


## 测试
最后我们对国内的浏览器试了一下deeplink是否生效
### UC浏览器
会弹出一个应用打开提醒，如果用户本次没有【允许】操作，则浏览器下次会拦截打开应用行为，没有任何提醒，不知道这是一个bug还是故意为之。点击【允许】后可以跳转应用
![Screenshot_20180818-112921.jpg](https://upload-images.jianshu.io/upload_images/2057980-a5e83c90747d064a.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
### QQ浏览器
同样会弹出应用打开题型，如果用户本次没有【打开】，下次用户操作还是会继续提醒。点击【打开】后可以跳转应用
![Screenshot_20180818-113231.jpg](https://upload-images.jianshu.io/upload_images/2057980-0783dfe185065554.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
### 360浏览器
行为与QQ浏览器类似，每次都会提醒
![Screenshot_20180818-113459.jpg](https://upload-images.jianshu.io/upload_images/2057980-191f1f99af00a992.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
### 猎豹浏览器
行为与QQ浏览器类似，每次都会提醒
![Screenshot_20180818-113718.jpg](https://upload-images.jianshu.io/upload_images/2057980-f956c1cdbd9b4e48.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
### 一加系统默认浏览器
行为与QQ浏览器类似，每次都会提醒
![Screenshot_20180818-113921.jpg](https://upload-images.jianshu.io/upload_images/2057980-331e8219180a3cfa.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
### 搜狗浏览器
没有提醒，直接跳转到app
### chrome
行为与搜狗浏览器类似，没有提醒，直接跳转app  

测试结果除了UC浏览器第一次不点击跳转之后会跳转不了之外，
其他浏览器跳转app问题得到解决。

## 结语
通过这次查deeplink跳转的问题，收获了两点知识。  
* 一个是前端使用iframe来处理deeplink跳转会有问题  
* 二个是除了采用
```
"scheme://host/path"
```
这种deeplink方式之外，还可以采用
```
"intent://about/#Intent;action=[string];scheme=[string];package=[string];S.browser_fallback_url=[encoded_full_url];end"
```
的方式来触发应用intent的请求访问。

同时，在处理deeplink的规则里面，体会到了一条原则：

* 最短路径处理原则  

意思就是刚开始的时候，deeplink处理的逻辑要从根目录开始进行。比如有一个收藏词单的需求，没有使用最短路径原则可能会设计成这样

> recite://youdao.com/bookId?&action=collect

对应的处理是如果action为collect就收藏词单。这个时候需求如果改成默认进来不需要收藏就非常尴尬了。因为对于旧版本而已，只认有action=collect才会处理，那就意味这如果想对默认的recite://youdao.com/bookId只是查看不收藏的需求，对于旧版本就没办法实现，会出现兼容性问题。  
而最短路径处理原则，意思就是在开始的时候，尽量对最短的路径行为进行处理，具体到上面的例子，对于收藏某个词单的需求，我们可以设计deeplink为

> recite://youdao.com/bookId?&action=collect

然后我们对 *recite://youdao.com/bookId以及recite://youdao.com/bookId?&action=collect* 都处理成收藏词单。上线之后，如果想修改默认参数行为，就可以直接改对 *recite://youdao.com/bookId* 的处理，这样对于旧版本仍然是可以执行的收藏行为，对于新版本就可以对应新的逻辑

## 最后
卖个广告，欢迎大家在各大应用市场下载【有道背单词】体验。  
也可以扫一扫下载：  
![QRCODE.png](https://upload-images.jianshu.io/upload_images/2057980-beb4d17106c8c5ad.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


