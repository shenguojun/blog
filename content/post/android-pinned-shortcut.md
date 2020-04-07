---
title: "Android create pinned shortcut创建桌面快捷方式"
date: 2018-11-23T20:00:40+08:00
author: 申国骏
tags: ["android"]
---

# 前言
本文主要针对文章[Create shortcuts](https://developer.android.com/guide/topics/ui/shortcuts/creating-shortcuts)中动态创建桌面快捷方式的解释和例子。在8.0系统中，创建桌面快捷方式的广播```com.android.launcher.action.INSTALL_SHORTCUT```不再生效，创建桌面快捷方式需要用另外的方法。由于文章中没有详细的例子而且表达不是很清楚，笔者也一头雾水，经过了多方的尝试，最后才明白其中的意思，希望能给同样遇到困惑的人一点帮助。转载请注明来源[「Bug总柴」](https://www.jianshu.com/u/b692bbf77991) 

# 主动创建pinned shortcuts
主动创建pinned shortcuts的意思是可以通过代码让用户选择是否需要在桌面快捷方式。

```java
/**
 * 这里用ShortcutManagerCompat是因为ShortcutManager的minsdkversion要求至少是25
 */
private void createShortCut() {
    if (ShortcutManagerCompat.isRequestPinShortcutSupported(this)) {
        ShortcutInfoCompat shortcut = new ShortcutInfoCompat.Builder(this, "id1")
                .setShortLabel("Website")
                .setLongLabel("Open the website")
                .setIcon(IconCompat.createWithResource(this, R.drawable.ic_logo_app))
                .setIntent(new Intent(Intent.ACTION_VIEW,
                    Uri.parse("https://www.mysite.example.com/")))
                    .build();

        Intent pinnedShortcutCallbackIntent = ShortcutManagerCompat.createShortcutResultIntent(this, shortcut);
        PendingIntent successCallback = PendingIntent.getBroadcast(this, /* request code */ 0,
                pinnedShortcutCallbackIntent, /* flags */ 0);

        ShortcutManagerCompat.requestPinShortcut(this, shortcut, successCallback.getIntentSender());
    }
}
```
运行这段代码后，会有这样的提示给到用户如下图：
![device-2018-11-23-151817.png](https://upload-images.jianshu.io/upload_images/2057980-f51c843330ec1dfa.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
当用户点击【添加】后会在桌面显示快捷方式，不过现在的快捷方式都带了一个下标如下图：
![image.png](https://upload-images.jianshu.io/upload_images/2057980-aea603e678fc9db6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

# 通过桌面小部件方式添加快捷方式
这种方式属于用户通过添加桌面小部件方式手动添加，我们需要创建一个activity来表明我们的应用有这样的快捷方式小部件，并且处理添加的行为。
```xml
// 在AndoidManifest文件中添加activity
<activity android:name=".activity.AddShortcutActivity">
    <intent-filter>
        <action android:name="android.intent.action.CREATE_SHORTCUT"/>
        <category android:name="android.intent.category.DEFAULT" />
    </intent-filter>
</activity>
```
然后在Activity中创建快捷方式：
```java
public class AddShortcutActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_add_shortcut);
        Toast.makeText(this, "add shortcut", Toast.LENGTH_SHORT).show();
        if (ShortcutManagerCompat.isRequestPinShortcutSupported(this)) {
            ShortcutInfoCompat shortcut = new ShortcutInfoCompat.Builder(this, "id1")
                    .setShortLabel("Website")
                    .setLongLabel("Open the website")
                    .setIcon(IconCompat.createWithResource(this, R.drawable.ic_logo_app))
                    .setIntent(new Intent(Intent.ACTION_VIEW,
                            Uri.parse("https://www.mysite.example.com/")))
                    .build();

            Intent pinnedShortcutCallbackIntent = ShortcutManagerCompat.createShortcutResultIntent(this, shortcut);
            setResult(RESULT_OK, pinnedShortcutCallbackIntent);
            finish();
        }
    }
}
```
再次运行代码之后，可以在系统添加桌面小部件的地方看到有我们创建的小部件，这一个时候就可以拖动它到桌面了:)

![image.png](https://upload-images.jianshu.io/upload_images/2057980-1e080fb9b9d60953.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)