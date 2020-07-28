---
title: "Flutter架构综述"
date: 2020-06-17T14:01:07+08:00
tags: ["flutter"]
draft: true
---
>本文是对[TodoMVC for Flutter](https://github.com/brianegan/flutter_architecture_samples)中提到架构的总结

在聊架构之前，我们需要先进入Flutter声明式（declaratively）的世界。在传统的iOS或者Android开发的命令式（imperative）世界中，我们可以很容易地构建一个Widget，并通过这个构建出来的Widget直接修改它的属性，例如`var textView = TextView(); textView.text = "xxx"`。然而在Flutter声明式的世界里，这个看似理所当然的做法并不是常用的方法，甚至你会发现Flutter不支持这样做。我们需要用一种全新的思维来思考。在Flutter声明式的世界里，频繁地调用build方法来重绘是可接受的，如果想改变一个Widget的属性，声明式的做法是通过改变数据，并告诉Flutter根据当前的数据对界面进行重绘。

![ui-equals-function-of-state](https://shenguojun.github.io/image/ui-equals-function-of-state.png)

因此对Flutter架构的研究，很大层度上可以归结为探究如何对状态进行存储，以及如何触发界面重绘的问题。

# 状态上浮
原理：将数据保存在最外层widget中，并将操作方法一层层传递给子widget，最终由子widget调用操作方法触发最外层widget的setState完成界面刷新。[代码例子](https://github.com/brianegan/flutter_architecture_samples/tree/master/vanilla)
* 缺点：每层传递代码不简洁、每次修改触发整体build

# InheritedWidget
原理：将数据保存在最外层的widget，在子widget通过dependOnInheritedWidgetOfExactType的方法获取数据和调用数据操作方法，触发最外层widgetsetState完成界面刷新。[代码例子](https://github.com/brianegan/flutter_architecture_samples/tree/master/inherited_widget)
* 缺点：每次修改触发整体build
* 优点：不需要每层传递代码、代码较为简洁易懂

# ChangeNotifier + Provider
原理：Provider底层也是使用InheritedWidget，原理是ChangeNotifierProvider将widget包裹在InheritedWidget中，并将继承自ChangeNotifier的数据Model对象放到内置的InheritedWidget对象中，当调用Provider.of的时候对数据Model添加listener，并在数据Model调用notifyListeners()方法时，设置markNeedsBuild()刷新界面。ChangeNotifier添加和删除listener复杂度是O(n)，消息发送复杂度是O(N^2)
* 缺点：
* 优点：

# BLoC
* 缺点：为了dispose释放资源需要大量的StatefulWidget，可以结合Provider优化

# 参考
* [Flutter guide - State management](https://flutter.dev/docs/development/data-and-backend/state-mgmt/intro)
* [Flutter architecture samples](https://github.com/brianegan/flutter_architecture_samples)