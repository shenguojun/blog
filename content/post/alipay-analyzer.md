---
title: "Alipay逆向工程分析"
date: 2021-06-10T15:44:18+08:00
author: 申国骏
tags: ["android"]
draft: true
---

## 入口

AndroidManifest.xml

```xml
<application android:allowBackup="false" android:debuggable="false" android:hardwareAccelerated="true" android:icon="@drawable/appicon" android:label="@string/name" android:largeHeap="true" android:name="com.alipay.mobile.quinox.LauncherApplication" android:networkSecurityConfig="@xml/network_security_config" android:requestLegacyExternalStorage="true" android:roundIcon="@drawable/appicon" android:theme="@style/AppThemeNew">
    <uses-library android:name="org.apache.http.legacy" android:required="false" />
    <meta-data android:name="android.max_aspect" android:value="2.4" />
    <meta-data android:name="android.min_aspect" android:value="1.0" />
    <meta-data android:name="client_signature" android:value="30820244308201ad02044b28a3c9300d06092a864886f70d01010405003068310b300906035504061302636e3110300e060355040813076265696a696e673110300e060355040713076265696a696e67310f300d060355040a1306616c69706179310f300d060355040b1306616c69706179311330110603550403130a73686971756e2e7368693020170d3039313231363039303932395a180f32303531303131303039303932395a3068310b300906035504061302636e3110300e060355040813076265696a696e673110300e060355040713076265696a696e67310f300d060355040a1306616c69706179310f300d060355040b1306616c69706179311330110603550403130a73686971756e2e73686930819f300d06092a864886f70d010101050003818d0030818902818100b6cbad6cbd5ed0d209afc69ad3b7a617efaae9b3c47eabe0be42d924936fa78c8001b1fd74b079e5ff9690061dacfa4768e981a526b9ca77156ca36251cf2f906d105481374998a7e6e6e18f75ca98b8ed2eaf86ff402c874cca0a263053f22237858206867d210020daa38c48b20cc9dfd82b44a51aeb5db459b22794e2d6490203010001300d06092a864886f70d010104050003818100b6b5e3854b2d5daaa02d127195d13a1927991176047982feaa3d1625740788296443e9000fe14dfe6701d7e86be06b9282e68d4eff32b19d48555b8a0838a6e146238f048aca986715d7eab0fb445796bbd19360a7721b8d99ba04581af957a290c47302055f813862f3c40b840e95898e72a1de03b6257a1acad4b482cd815c" />
    <meta-data android:name="setting.logging.encryption.pubkey" android:value="MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCpffOiYcozIfgIiaOPWsmfktv7Sl/9Af3mIgYz7vkTXoGq4iMN+t5BLV6KjddVEI/9oLtAYV8qx7FhFrUoi3smcYfX35ETPUiHi1gLizeXKVSRYhIm2kiDF5lGfDgcS7uJZvmKjbdYy/RphnH+WQvQyeEH+4rjYSkdhIRE2W52BwIDAQAB" />
    <meta-data android:name="agent.application" android:value="com.alipay.mobile.framework.AlipayApplication" />
    <meta-data android:name="agent.activity" android:value="com.alipay.mobile.quinox.splash.AlipayLauncherActivityAgent" />
    <meta-data android:name="agent.activity.layout" android:value="activity_start_logo" />
    <meta-data android:name="agent.commonservice.load" android:value="com.alipay.mobile.framework.service.ClientServicesLoader" />
    <meta-data android:name="agent.settings.provider" android:value="com.alipay.mobile.framework.settings.AlipaySettingsProvider" />
    <meta-data android:name="agent.entry.appid" android:value="20000001" />
    <meta-data android:name="ipp.components" android:value="org.rome.android.ipp.binder.IppService;com.alipay.pushsdk.BroadcastActionReceiver" />
    <meta-data android:name="com.amap.api.v2.apikey" android:value="7e4e4d24935c4a30249efd2ff5b32149" />
    <meta-data android:name="mobilegw.url" android:value="" />
    <meta-data android:name="sandbox.amnet.server" android:value="" />
    <meta-data android:name="enable.stlport.load" android:value="true" />
    <meta-data android:name="enable.gnustl.load" android:value="false" />
    <meta-data android:name="enable.framework.monitor" android:value="true" />
    <meta-data android:name="process.start.worker" android:value="com.alipay.mobile.quinox.splash.ProcessStarter" />
    <meta-data android:name="product_name" android:value="ALIPAY_WALLET" />
    <meta-data android:name="login_refresh_feature" android:value="true" />
    <meta-data android:name="com.huawei.hms.client.appid" android:value="@string/huawei_push_appid" />
    <meta-data android:name="com.xiaomi.mipush.sdk.appid" android:value="@string/xiaomi_push_appid" />
    <meta-data android:name="com.xiaomi.mipush.sdk.appkey" android:value="@string/xiaomi_push_appkey" />
    <meta-data android:name="com.meizu.cloud.pushsdk.appid" android:value="@string/meizu_push_appid" />
    <meta-data android:name="com.meizu.cloud.pushsdk.appkey" android:value="@string/meizu_push_appkey" />
    <meta-data android:name="com.coloros.mcssdk.appkey" android:value="@string/oppo_push_appkey" />
    <meta-data android:name="com.coloros.mcssdk.appsecret" android:value="@string/oppo_push_appsecret" />
    <meta-data android:name="com.vivo.push.api_key" android:value="@string/vivo_push_apikey" />
    <meta-data android:name="com.vivo.push.app_id" android:value="@string/vivo_push_appid" />
    <meta-data android:name="android.notch_support" android:value="true" />
    <meta-data android:name="notch.config" android:value="portrait|landscape" />
    <meta-data android:name="android.vivo_multidisplay_support" android:value="true" />
    <meta-data android:name="com.huawei.messaging.default_notification_icon" android:resource="@drawable/appicon_push" />
```

LuanchApplication

```java
protected void attachBaseContext(Context arg3) {
    this.mCurrentProcessStartupTime = SystemClock.elapsedRealtime();
    LauncherApplication.sInstance = this;
    super.attachBaseContext(arg3);
    // 初始化动态化库
    this.checkAndPrepareDexPatch();
    this.ensureWrapper();
    // 调用wrapper处理
    this.applicationWrapper.attachBaseContext(arg3);
}
```



LaunchActivity

```xml
<activity android:configChanges="0xde0" android:launchMode="1" android:name="com.eg.android.AlipayGphone.AlipayLogin" android:resizeableActivity="true" android:screenOrientation="1" android:theme="@style/tablauncher_theme" android:windowSoftInputMode="0x10">
      <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
      </intent-filter>
      <meta-data android:name="com.huawei.android.quickaction.quick_action_service" android:value="com.alipay.android.tablauncher.HuaWeiQuickActionService" />
    </activity>
```

