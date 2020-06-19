---
title: "Flutter多模块启动方案"
date: 2020-04-07T17:56:55+08:00
---
# 问题缘起
* 单一入口容易造成模块之间逻辑
* 不同模块使用不同路由方案
* iOS中设置了Entrypoint之后setInitialRouter设置无效
* flutter boost同时使用，iOS打开new engine页面返回flutterboost 页面路由不生效
# 代码解读
## setInitialRouter过程
* Android
* iOS
* Flutter
* FlutterEngine
## entryPoint设置
## 页面启动过程
## 最终解决办法
### channel
### flutter boost项目
* 跨模块