---
title: "Flutter架构综述"
date: 2020-06-17T14:01:07+08:00
draft: true
tags: ["flutter"]
---
>本文是对[TodoMVC for Flutter](https://github.com/brianegan/flutter_architecture_samples)中提到架构的总结

# 状态上浮
将数据保存在最外层widget中，并将操作方法一层层传递给子widget，最终由子widget调用操作方法触发最外层widget的setState完成界面刷新
* 缺点：每层传递代码不简洁、每次修改触发整体build
  
# InheritedWidget
将数据保存在最外层的widget，在子widget通过dependOnInheritedWidgetOfExactType的方法获取数据和调用数据操作方法，触发最外层widgetsetState完成界面刷新
* 缺点：每次修改触发整体build
* 优点：不需要每层传递代码、代码较为简洁易懂

# ChangeNotifier + Provider
* 适用于少量的回调，使用ChangeNotifier添加和删除listener复杂度是O(n)，消息发送复杂度是O(N^2)

# 参考
* [Flutter guide - State management](https://flutter.dev/docs/development/data-and-backend/state-mgmt/intro)
* [Flutter architecture samples](https://github.com/brianegan/flutter_architecture_samples)