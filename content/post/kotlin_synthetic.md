---
title: "Kotlin升级1.5版本synthetic引发的血案分析"
date: 2021-07-09T16:27:41+08:00
tags: ["android"]
---

## 场景重现

因为项目里面Kotlin版本还停留在1.4，看到1.5版本[更新记录](https://Kotlinlang.org/docs/releases.html#release-details)提升了性能并且新加了一些特性，准备怒升级一波。怀着开心的心情升级完之后，运行起来就傻眼了！

![1625820518128283](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/1625820518128283.gif)

视频列表有个浮层没有隐藏，就升级下Kotlin，居然还有这个问题，真是太不可思议了！把Kotlin降级回去，然后就好了，确定是因为Kotlin升级导致的问题。接下来就开始分析了。

## FindViewById？

第一反应是找下代码看看！

```kotlin
private fun tryHideTransitionImage() {
  // transition_image就是那个浮层
  if (transition_image.visibility != View.GONE) {
      transition_image.visibility = View.GONE
  }
}
```

debug一下，代码运行的顺序在Kotlin升级前和升级后没有区别！然后想到的就是`transition_image`使用Kotlin synthetic获取的，是不是和findViewById有什么区别呢？于是改成了

```kotlin
private fun tryHideTransitionImage() {
  // transition_image就是那个浮层
  if (view.findViewById(R.id.transition_image).visibility != View.GONE) {
      view.findViewById(R.id.transition_image).visibility = View.GONE
  }
}
```

然而问题还是一样！果然问题不是那么简单！我们使用[Stetho]([Download (facebook.github.io)](http://facebook.github.io/stetho/))来看看这个页面里面`transition_image`的状态：

![WechatIMG1033](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/WechatIMG1033.jpeg)

不出所料有两个transition_image，一个是在外层FrameLayout底下的悬浮层，另一个是在Recyclerview的ItemView里面的视频封面。悬浮层的属性显示确实是没有隐藏。这个时候就要看看FindViewById的原理了，我们看下`findViewById`的源码：

```java
// View.java
public final <T extends View> T findViewById(@IdRes int id) {
  if (id == NO_ID) {
    return null;
  }
  return findViewTraversal(id);
}
```

在ViewGroup里面重写了`findViewTraversal`方法

```java
findViewTraversalprotected <T extends View> T findViewTraversal(@IdRes int id) {
  if (id == mID) {
    return (T) this;
  }

  final View[] where = mChildren;
  final int len = mChildrenCount;

  for (int i = 0; i < len; i++) {
    View v = where[i];

    if ((v.mPrivateFlags & PFLAG_IS_ROOT_NAMESPACE) == 0) {
      v = v.findViewById(id);

      if (v != null) {
        return (T) v;
      }
    }
  }

  return null;
}
```

![image-20210714164915387](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image-20210714164915387.png)

可以看出是一个深度优先搜索算法，因此在我们使用[Stetho]([Download (facebook.github.io)](http://facebook.github.io/stetho/))时看到的View树里面，会先遍历到RecyclerView底下的视频封面，因此如果直接使用`findViewById(R.id.transition_image)`来隐藏浮层的话，拿到的并不是浮层。

那么为什么1.4版本的Kotlin里面不会出问题呢？这个时候得分析下编译之后的ByteCode了。

## ByteCode分析

```kotlin
private fun tryHideTransitionImage() {
  // transition_image就是那个浮层
  if (transition_image.visibility != View.GONE) {
      transition_image.visibility = View.GONE
  }
}
```

同样的这段代码，在使用Kotlin1.4版本的android extensions compile编译之后的dex的二进制代码如下：

```assembly
.method private final tryHideTransitionImage()V
          .registers 4
00000000  sget                v0, R$id->transition_image:I
00000004  invoke-virtual      CommunityVideoListFragment->_$_findCachedViewById(I)View, p0, v0
0000000A  move-result-object  v0
0000000C  check-cast          v0, ImageView
00000010  const-string        v1, "transition_image"
00000014  invoke-static       Intrinsics->checkNotNullExpressionValue(Object, String)V, v0, v1
0000001A  invoke-virtual      ImageView->getVisibility()I, v0
00000020  move-result         v0
00000022  const/16            v2, 8
00000026  if-eq               v0, v2, :46
:2A
0000002A  sget                v0, R$id->transition_image:I
0000002E  invoke-virtual      CommunityVideoListFragment->_$_findCachedViewById(I)View, p0, v0
00000034  move-result-object  v0
00000036  check-cast          v0, ImageView
0000003A  invoke-static       Intrinsics->checkNotNullExpressionValue(Object, String)V, v0, v1
00000040  invoke-virtual      ImageView->setVisibility(I)V, v0, v2
:46
00000046  return-void
.end method

.method public _$_findCachedViewById(I)View
          .registers 4
00000000  iget-object         v0, p0, CommunityVideoListFragment->_$_findViewCache:HashMap
00000004  if-nez              v0, :16
:8
00000008  new-instance        v0, HashMap
0000000C  invoke-direct       HashMap-><init>()V, v0
00000012  iput-object         v0, p0, CommunityVideoListFragment->_$_findViewCache:HashMap
:16
00000016  iget-object         v0, p0, CommunityVideoListFragment->_$_findViewCache:HashMap
0000001A  invoke-static       Integer->valueOf(I)Integer, p1
00000020  move-result-object  v1
00000022  invoke-virtual      HashMap->get(Object)Object, v0, v1
00000028  move-result-object  v0
0000002A  check-cast          v0, View
0000002E  if-nez              v0, :5C
:32
00000032  invoke-virtual      Fragment->getView()View, p0
00000038  move-result-object  v0
0000003A  if-nez              v0, :42
:3E
0000003E  const/4             p1, 0
00000040  return-object       p1
:42
00000042  invoke-virtual      View->findViewById(I)View, v0, p1
00000048  move-result-object  v0
0000004A  iget-object         v1, p0, CommunityVideoListFragment->_$_findViewCache:HashMap
0000004E  invoke-static       Integer->valueOf(I)Integer, p1
00000054  move-result-object  p1
00000056  invoke-virtual      HashMap->put(Object, Object)Object, v1, p1, v0
:5C
0000005C  return-object       v0
.end method
```

我们查看下[dex指令文档](https://source.android.com/devices/tech/dalvik/dex-format)，对这段dex二进制翻译一下：

```java
private final void tryHideTransitionImage() {
  ImageView v0 = (ImageView)this._$_findCachedViewById(id.transition_image);
  Intrinsics.checkNotNullExpressionValue(v0, "transition_image");
  if(v0.getVisibility() != View.Gone) {
    ImageView v0_1 = (ImageView)this._$_findCachedViewById(id.transition_image);
    Intrinsics.checkNotNullExpressionValue(v0_1, "transition_image");
    v0_1.setVisibility(View.Gone);
  }
}

public View _$_findCachedViewById(int arg3) {
  if(this._$_findViewCache == null) {
    this._$_findViewCache = new HashMap();
  }
  View v0 = (View)this._$_findViewCache.get(Integer.valueOf(arg3));
  if(v0 == null) {
    View v0_1 = this.getView();
    if(v0_1 == null) {
      return null;
    }
    v0 = v0_1.findViewById(arg3);
    this._$_findViewCache.put(Integer.valueOf(arg3), v0);
  }
  return v0;
}
```



在升级到Kotlin1.5版本后，二进制代码如下：

```assembly
.method private final tryHideTransitionImage()V
          .registers 4
00000000  invoke-virtual      CommunityVideoListFragment->getView()View, p0
00000006  move-result-object  v0
00000008  const/4             v1, 0
0000000A  if-nez              v0, :12
:E
0000000E  move-object         v0, v1
00000010  goto                :1E
:12
00000012  sget                v2, R$id->transition_image:I
00000016  invoke-virtual      View->findViewById(I)View, v0, v2
0000001C  move-result-object  v0
:1E
0000001E  check-cast          v0, ImageView
00000022  invoke-virtual      ImageView->getVisibility()I, v0
00000028  move-result         v0
0000002A  const/16            v2, 8
0000002E  if-eq               v0, v2, :56
:32
00000032  invoke-virtual      CommunityVideoListFragment->getView()View, p0
00000038  move-result-object  v0
0000003A  if-nez              v0, :40
:3E
0000003E  goto                :4C
:40
00000040  sget                v1, R$id->transition_image:I
00000044  invoke-virtual      View->findViewById(I)View, v0, v1
0000004A  move-result-object  v1
:4C
0000004C  check-cast          v1, ImageView
00000050  invoke-virtual      ImageView->setVisibility(I)V, v1, v2
:56
00000056  return-void
.end method
```

翻译成Java代码如下：

```java
private final tryHideTransitionImage() {
    Object v0 = this.getView();
    if (v0 != null) {
        v0 = v0.findViewById(R.id.transition_image);
    } else {
        v0 = null;
    }
    if (((ImageView) v0).getVisibility != View.Gone) {
        v0 = this.getView();
        if (v0 != null) {
            Object v1 = v0.findViewById(R.id.transition_image);
            ((ImageView) v1).setVisibility(View.Gone)
        }
    }
}
```

可以看出在1.5版本之后，Kotln Synthetic由原来的生成一个`_findCachedViewById`来保存View对象，变成了直接将`findViewById`inLine到调用的地方，没有使用view cache保存对象。这个改动的

**因此我们上面遇到的问题也能得到比较清晰的答案了。因为在1.4版本里面，代码里面的`transition_image`指的是第一次调用的对象，而我们发现代码里面第一次调用`transition_image`是在`Fragment`的`onViewCreated`的代码中，这个时候由于列表还没加载，所以获取到的就是外层的浮层，之后对`transitoin_image`的调用都是指向这个浮层对象，因此没有问题。而在升级到1.5版本之后，由于view cache机制改成了直接`findViewById`，因此在列表加载之后再获取`transition_image`获取到的就是列表里面的封面对象，导致了浮层没有正常隐藏。**

## Kotlin Synthetic原理

在知道问题的答案之后，我们再进一步看看Kotlin Synthetic是怎么生成这些代码的。

```kotlin
override fun generateClassSyntheticParts(codegen: ImplementationBodyCodegen) {
    val classBuilder = codegen.v
    val targetClass = codegen.myClass as? KtClass ?: return

		// 没有enable的话不生成
    if (!isEnabled(targetClass)) return

    val container = codegen.descriptor
    if (container.kind != ClassKind.CLASS && container.kind != ClassKind.OBJECT) return

    val containerOptions = ContainerOptionsProxy.create(container)
    // 判断目标是否Framgent或者Activity等需要生成cache的类
    if (containerOptions.getCacheOrDefault(targetClass) == NO_CACHE) return

		// 如果是LayoutContainer则需要开启experiment特性才会生成cache
    if (containerOptions.containerType == LAYOUT_CONTAINER && !isExperimental(targetClass)) {
        return
    }

    val context = SyntheticPartsGenerateContext(classBuilder, codegen.state, container, targetClass, containerOptions)
    // 生成_findCachedViewById方法
    context.generateCachedFindViewByIdFunction()
    context.generateClearCacheFunction()
    context.generateCacheField()

    if (containerOptions.containerType.isFragment) {
        val classMembers = container.unsubstitutedMemberScope.getContributedDescriptors()
        val onDestroy = classMembers.firstOrNull { it is FunctionDescriptor && it.isOnDestroyFunction() }
        if (onDestroy == null) {
            context.generateOnDestroyFunctionForFragment()
        }
    }
}
```



```kotlin
private fun SyntheticPartsGenerateContext.generateCachedFindViewByIdFunction() {
  val containerAsmType = state.typeMapper.mapClass(container)

    val viewType = Type.getObjectType("android/view/View")

    val methodVisitor = classBuilder.newMethod(
    JvmDeclarationOrigin.NO_ORIGIN, ACC_PUBLIC, CACHED_FIND_VIEW_BY_ID_METHOD_NAME, "(I)Landroid/view/View;", null, null)
    methodVisitor.visitCode()
    val iv = InstructionAdapter(methodVisitor)

    val cacheImpl = CacheMechanism.get(containerOptions.getCacheOrDefault(classOrObject), iv, containerAsmType)

    fun loadId() = iv.load(1, Type.INT_TYPE)

    // Get cache property
    cacheImpl.loadCache()

    val lCacheNonNull = Label()
    iv.ifnonnull(lCacheNonNull)

    // Init cache if null
    cacheImpl.initCache()

    // Get View from cache
    iv.visitLabel(lCacheNonNull)
    cacheImpl.loadCache()
    loadId()
    cacheImpl.getViewFromCache()
    iv.checkcast(viewType)
    iv.store(2, viewType)

    val lViewNonNull = Label()
    iv.load(2, viewType)
    iv.ifnonnull(lViewNonNull)

    // Resolve View via findViewById if not in cache
    iv.load(0, containerAsmType)

    val containerType = containerOptions.containerType
  	// 根据不同的类型获取root View
    when (containerType) {
    AndroidContainerType.ACTIVITY, AndroidContainerType.ANDROIDX_SUPPORT_FRAGMENT_ACTIVITY, AndroidContainerType.SUPPORT_FRAGMENT_ACTIVITY, AndroidContainerType.VIEW, AndroidContainerType.DIALOG -> {
      loadId()
        iv.invokevirtual(containerType.internalClassName, "findViewById", "(I)Landroid/view/View;", false)
    }
    AndroidContainerType.FRAGMENT, AndroidContainerType.ANDROIDX_SUPPORT_FRAGMENT, AndroidContainerType.SUPPORT_FRAGMENT, LAYOUT_CONTAINER -> {
      if (containerType == LAYOUT_CONTAINER) {
        iv.invokeinterface(containerType.internalClassName, "getContainerView", "()Landroid/view/View;")
      } else {
        iv.invokevirtual(containerType.internalClassName, "getView", "()Landroid/view/View;", false)
      }

      iv.dup()
        val lgetViewNotNull = Label()
        iv.ifnonnull(lgetViewNotNull)

        // Return if getView() is null
        iv.pop()
        iv.aconst(null)
        iv.areturn(viewType)

        // Else return getView().findViewById(id)
        iv.visitLabel(lgetViewNotNull)
        loadId()
        iv.invokevirtual("android/view/View", "findViewById", "(I)Landroid/view/View;", false)
    }
    else -> throw IllegalStateException("Can't generate code for $containerType")
  }
  iv.store(2, viewType)

    // Store resolved View in cache
    cacheImpl.loadCache()
    loadId()
    cacheImpl.putViewToCache { iv.load(2, viewType) }

  iv.visitLabel(lViewNonNull)
    iv.load(2, viewType)
    iv.areturn(viewType)

    FunctionCodegen.endVisit(methodVisitor, CACHED_FIND_VIEW_BY_ID_METHOD_NAME, classOrObject)
}
```

这部分代码在1.4和1.5的版本之间并没有任何区别，那究竟是什么导致Kotlin1.5版本不生成`_findCachedViewById`方法呢？

这个时候，我们在使用Kotlin1.5版本的基础上，通过在build.gradle文件中，加入下面这段代码，会发现`_findCachedViewById`方法会继续生成。而下面这段代码的意思是使用旧的JVM编译器。

```js
tasks.withType(org.jetbrains.kotlin.gradle.dsl.KotlinJvmCompile) {
    kotlinOptions.useOldBackend = true
}
```

因此，可以推断是Kotin1.5版本中使用了新的JVM IR编译器导致的。

报了个Bug给Jetbrains，后续保持关注：https://youtrack.jetbrains.com/issue/KT-47733

## 注意事项

1. 使用synthetic需要注意在1.5之前是使用cache机制的，在一个类里面使用synthetic获取view会按照第一个获取到的view为准，因此如果一个类里面对应的viewid有重复的话，会以第一个为准。在1.5之后，就是每个地方都通过findviewbyid获取。
2. 尽量避免在同一个页面的不同级别的地方使用同样的id，特别注意列表的item的id不要和外层的id重复。
3. `import kotlinx.android.synthetic.xx`导入的只是符号引用，有可能声明的是`kotlinx.android.synthetic.a.view1`但是实际上代码里面获取的是`kotlinx.android.synthetic.b.view1`。
4. 使用Kotlin Synthetics获取view可能会导致null pointer，特别是在某些回调函数里面view已经释放的情况下。
5. 在2020年11月，[Google官方宣布正式弃用Kotlin Android Extensions里面的Synthetics](https://android-developers.googleblog.com/2020/11/the-future-of-kotlin-android-extensions.html)，而推荐使用[Jecpack View Binding](https://developer.android.com/topic/libraries/view-binding)，android-kotlin-extensions将会在2021年的9月左右移除，后续代码尽量不要使用Kotlin Synthetics。

## 参考

* [The future of Kotlin Android Extensions](https://android-developers.googleblog.com/2020/11/the-future-of-kotlin-android-extensions.html)

* [Dalvik Executable format](https://source.android.com/devices/tech/dalvik/dex-format)

* [Stable JVM IR backend﻿](https://kotlinlang.org/docs/whatsnew15.html#stable-jvm-ir-backend)

  

