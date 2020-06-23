---
title: "Flutter学习笔记（中）"
date: 2020-04-07T17:56:55+08:00
tags: ["flutter"]
---
> 以下为对[Flutter官网](https://flutter.dev/docs)的学习总结，如果你想快速掌握知识点，或者想复习一下官网学习的内容，那么值得看看。
# 数据与网络服务
## 状态管理
* 与传统iOS或者Android开发中创建Widget并直接修改其属性不同，在Flutter声明式的世界里，频繁地调用build方法来重绘是可接受的，如果想改变一个Widget的属性，声明式的做法是通过改变数据，并告诉Flutter根据当前的数据对界面进行重绘。
* 状态可以分为两种，一种是widget内短暂的数据状态，可以使用StatefulWidget来管理并根据状态刷新界面。另一种是类似于单例的跨多个widget的全局状态
* 为了维护全局状态，可以将状态保存在最上层widget，并通过传递操作函数给底层widget从而实现底层widget修改全局状态并更新ui，也可以使用Inherited相关的widget让底层widget通过dependOnInheritedWidgetOfExactType获取并更新状态。或者使用Provider。
* Provider有三个概念，分别是ChangeNotifier（触发事件并支持订阅）、ChangeNotifierProvider（将事件与消费者绑定）和Consumer（事件消费者）。当ChangeNotifier发出事件时，Consumer的build方法都会重新执行，为避免不必要的界面重绘，可以尽可能地将Consumer置于底层，并且使用child参数预先定义好不需要变化的子widget。
* 如果仅需要调用数据操作方法而不需要获取当前数据，可以使用`Provider.of<T>(context, listen: false)`
* Provider的更多知识可以看[Flutter | 状态管理指南篇——Provider](https://juejin.im/post/5d00a84fe51d455a2f22023f)，以及[Making sense of all those Flutter Providers](https://medium.com/flutter-community/making-sense-all-of-those-flutter-providers-e842e18f45dd)
* `context.watch<T>()` 与 `Provider.of<T>(context)`等效，使当前widget监听T类型对象的变化并对界面进行重绘
* `context.read<T>()` 与 `Provider.of<T>(context, listen: false)`等效，可以获取类型为T的对象
* `context.select<T, R>(R cb(T value))` 使widget仅监听类型T对象的某个部分
* 其他对全局数据操作的方法还有Redux、BLoC、Rx、和MobX

# Cookbook
## 动画
## 设计
## 表格
## 手势
## 图片
## 列表
## 维护
## 导航
## 网络
## 持久化
## 插件
## 测试