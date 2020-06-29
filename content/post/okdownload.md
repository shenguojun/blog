---
title: "OKDownload下载框架详解"
date: 2020-06-19T14:58:54+08:00
draft: true
---
[OKDowload](https://github.com/lingochamp/okdownload)是流利说开源的一个下载工具，是之前同样开源的[FileDownloader](https://github.com/lingochamp/FileDownloader)的升级版，拥有多线程分块下载、断点续传、完备的下载回调、可以获取下载断点状态、高性能、设置下载优先级等特性。

# 源码解析
## 整体类图
![okdownload类图.png](https://shenguojun.github.io/image/okdownload-uml.png)
OKDownload类中采用策略模式的组合，提供各个环节的自定义灵活性。可以定义底层的使用OkHttp还是URLConnection，也可以定义是否使用数据库来保存下载断点信息。

## 下载任务创建&分配执行流程
### 通过`DownloadTask.execute()`方法入口进行启动

```java
/**
 * Execute the task with the {@code listener} on the invoke thread.
 *
 * @param listener the listener is used for listen the whole lifecycle of the task.
 */
public void execute(DownloadListener listener) {
    this.listener = listener;
    OkDownload.with().downloadDispatcher().execute(this);
}
```

最终会执行`OkDownload.with().downloadDispatcher().execute(this);`。其中`OkDownload.with().downloadDispatcher()`会生成默认的`DownloadDispatcher`类实例，并执行`DownloadDispatcher.execute()`方法。

```java
public void execute(DownloadTask task) {
    final DownloadCall call;

    synchronized (this) {
        // 通过下载断点或者检查目标文件是否存在判断任务是否已经完成
        if (inspectCompleted(task)) return;
        // 检查是已经有相同的下载任务，或者有相同目的文件的下载任务
        if (inspectForConflict(task)) return;

        call = DownloadCall.create(task, false, store);
        // runningSyncCalls表示正在执行的顺序任务
        runningSyncCalls.add(call);
    }

    syncRunCall(call);
}
```

## 下载任务执行流程

## 下载断点信息

## 监听器设计

# 功能API说明
接入的说明见项目[wiki](https://github.com/lingochamp/okdownload/wiki)。一般的调用方法见[Simple Use Guideline](https://github.com/lingochamp/okdownload/wiki/Simple-Use-Guideline)和[Advanced Use Guideline](https://github.com/lingochamp/okdownload/wiki/Advanced-Use-Guideline)


