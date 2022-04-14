---
title: "在Android中使用Kotlin协程"
date: 2021-09-10T11:01:07+08:00
author: 申国骏
tags: ["android","kotlin","coroutines"]
draft: true
---

协程是执行后台任务的一大利器，相比于回调式的任务调度，协程写法更为简洁，逻辑更为清晰，生命周期管理更为容易。

掌握了协程可以大大减少写后台线程的工作量，举一个例子让大家先睹为快，假设我们要在Activity中并行请求两个数据，并更新UI。

* Callback回调式写法

  ```kotlin
  class MainActivity {
    
    val countDownLatch = CountDownLatch(2)
    override fun onCreate() {
      service1.getResponse() { response ->
        countDownLatch.countDown()
      }
      service2.getResponse() { response ->
        countDownLatch.countDown()
      }
      countDownLatch.await()
      updateUI()
    }
    
  }
  ```

* 协程写法

  ```kotlin
  class MainActivity {
    
    override fun onCreate() {
      lifecycleScope.launch { 
        async {service1.getResponse()}
        async {service2.getResponse()}
        updateUI()
      }
    }
    
  }
  ```

  

## 重要的概念

* CoroutineScope

定义协程的生命周期，结构式，继承parent

* Job



## 生命周期管理

页面 view viewmodel livedata



## 线程切换

dispatcher
