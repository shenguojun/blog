---
title: "Flutter学习笔记——用户界面"
date: 2020-04-07T15:19:10+08:00
tags: ["flutter"]
---
> 以下为对[Flutter官网](https://flutter.dev/docs)的学习总结，如果你想快速掌握知识点，或者想复习一下官网学习的内容，那么值得看看。
# 用户界面
## widgets介绍
* Flutter一切都是widget，包括设置padding的container。
* 几乎所有widget都通过build方法声明其UI
* StatelessWidget用于固定样式的widget，StatefulWidget用于根据数据变化的widget。
* StatefulWidget通过createState关联私有的State对象，并通过setState()方法更新数据并通知UI变化。
* 更新UI时Flutter会通过比较前后widget树来计算差异，widget只是保存了样式信息，它的重建可以考虑是轻量级的。widget树会对应到element树，并通过element树创建Render树。相同类型widget会重用element和render对象。
* State对象的生命周期跨越其对应的widget对象build方法，比widget本身生命周期要长
* State调用流程大致为initState -> build -> dispose，可以在initState做初始化操作，在dispose中做清理操作
* didChangeDependencies会在initState和build之间调用，当父widget有InheritedWidget变化时也会被调用
* InheritedWidget可用于在widget树中给子widget共享数据，通常通过of方法调用context.inheritFromWidgetOfExactType返回拥有共享数据的InheritedWidget对象
* key控制widget重建时与哪些其他widget进行匹配，从而保持正确的state状态，一般用在widget的添加删除或者重排序中控制widget重用
* key分为Local key（value key表示根据某个值判断、Object key表示根据某个对象判断、Unique key表示每个widget都不一样） 和Global key(表示不同页面的widget共享)，
## 构建layouts
### Flutter中的layouts
* 可以通过Row和Column构建复制页面
* mainAxisAlignment控制主轴对齐方式，crossAxisAlignment控制次轴对齐方式
* 使用Expanded widget来fit window，flex来指定比例
* 将布局widget赋值给变量，通过变量组合布局减少层级嵌套
* 使用Container设置margin、border、pandding和背景
* GridView.extend中maxCrossAxisExtent设置每个item的最大宽度，mainAxisSpacing设置主轴item之间的间隔，crossAxisSpacing设置次轴item之间的间隔，childAspectRatio设置item宽高比例
* GridView.builder用于数量较多的item展示，仅加载当前可见的部分，GridView.count用于加载少量固定数目的item并指定每行item格式，GridView.extend用于加载少量固定item并指定每行item最大宽度
* GridView中通过SliverGridDelegate控制子widget如何布局，通过SliverChildDelegate来获取子widget，可以通过自定义来实现自由或者叠加布局。
* GridView和ListView都继承自BoxScrollView
* 大量数据需使用ListView.builder并在itemBuilder回调中创建并提供widget；如果列表的item样式可以提前构建则可以直接使用new ListView；ListView.separated除了itemBuilder之外还有个separatorBuilder用来定义分隔线样式；ListView.custom通过提供自定义的SliverChildDelegate来
* Stack用于widget的堆叠，可以做渐变的图片阴影
* Card内部内容不能够滚动，可以自定义圆角和阴影大小
* ListTitle是方便构建至多三行文字加上前后图标的列表item widget
### layout使用例子
* 使用Expanded widget占满剩余空间，子widget设置CrossAxisAlignment.start表示从前开始
* Text softwrap控制是否需要自动换行
* 修改pubspec.yaml设置assets目录，例如：flutter: assets: [images/]
* Image.asset中设置fit:BoxFit.cover 表示图片应该以最小的大小占满box空间
* 使用ListView代替Column保证小屏幕手机中空间可以滚动
### 创建自适应UI应用
* 使用LayoutBuilder的BoxConstraints获取当前widget的宽高比例从而调整子widget布局
* 使用MediaQuery.of()获取屏幕宽高和旋转方向等设备信息从而控制整体布局样式
* AspectRatio控制子widget的宽高比例
* CustomSingleChildLayout、CustomMultiChildLayout将子widget的布局委托给ChildLayoutDelegate进行控制
* FittedBox：当子widget比父widget大时，通过FittedBox可以设置子widget的缩放方式
* FractionallySizedBox可以设置子widget占据其空间的宽高百分比
* MediaQueryData中padding指代周边有多少不能绘制的区域不计算被键盘等遮挡的区域，viewPadding指的是周边有多少不能被绘制的区域不受键盘等遮挡影响，viewInsert表示周边有多少区域被键盘等遮挡了
* OrientationBuilder获取屏幕是否旋转
### Constraints布局约束理解
* 布局流程：
  1. widget从parent中获取四个约束，分别是最小和最大宽度、最小和最大高度；
  2. widget将约束一个一个地传递给子widget，并让子widget根据约束条件设定其自身的大小；
  3. widget根据子widget的大小一个一个进行布局；
  4. widget将自身的大小上报给parent。
* 布局流程会导致以下三个限制：
  1. 一个widget最终布局大小需要受到parent的约束限制，不是想要什么大小都可以；
  2. 一个widget不能知道也不能决定其在屏幕中的位置，widget的布局由其parent决定；
  3. 只有考虑整棵widget树才能确定widget的大小和位置，不能准确地定义某个widget的位置和大小。
* Container布局行为：
  1. 若没有子widget，没有设置宽高，没有约束，parent是无界约束，Container会填充parent，并希望让自身尽量的小
  2. 若没有子widget，没有设置alignment，设置了宽高或者有约束，Container会在满足自身约束和parent约束的情况下尽量的小
  3. 若没有子widget，没有设置宽高，没有约束，没有设置alignment，parent是有界约束，那么Container会尽量的扩大以满足parent的约束
  4. 若设置了alignment，parent无界约束，那么Container尽量缩小为子widget大小
  5. 若设置了alignment，parent有界约束，那么Container扩大为parent约束大小，并将子widget根据alignment设置来布局
  6. 若只有子widget，没有设置宽高，没有约束，没有alignment，Container会将parent的约束传递给子widget，并尽量缩小为子widget大小
* 布局中FittedBox可以控制子widget在约束空间中的布局，例如设置自动缩小文字或者缩放图片
* tight约束表示固定宽高约束，loose约束表示在设置最大宽高基础上尽量的缩小
### Box constraints边界约束
* 有三种box，分别是无限扩展例如Center或者ListView、子widget决定例如Trnasform和Opacity、固定大小例如Image和Text
* 类似于当一个竖向的ListView嵌套进了一个横向的ListView，会造成无界约束状态（Unbounded constraints），这种状态会使得子widget可以在两个方向无限扩展导致错误
* Flex boxs指的是Row和Column，表示当其处于一个有界的区域会不断扩展至给定大小，当其处于一个无界区域会适应他的子widget大小。
* 如果将Flex box放置于类似于ListView的widget中，那么flex box中不能有类似于Expanded的widget，这会导致类似于Expanded的widget无限扩大造成错误
* Column的宽度和Row的高度不能设置为无界的，否则他们的子widget将无法布局
## 加入互动逻辑
* 可交互的widget有三点，一是有两个类，分别继承StatefulWidget和State，二是State类中拥有可变的状态和build方法，三是当状态变化，调用setState()方法对widget进行重绘。
* 将Text放在SizedBox中可以防止当文字变化时由于宽度变化带来的位置抖动
* 当调用setState({})方法时，会先执行lambda逻辑，然后调用_element.markNeedsBuild()标记当前element为dirty状态并在下一帧根据修改后的状态进行重绘
* 有三种常见的管理状态方法，分别是：widget自己管理自己的状态、父widget管理状态、混合前两种方式
* 如果状态是用户数据，那么最好在父widget管理。如果状态是与界面效果有关的例如动画，那么最好在widget自身内管理状态。如果不确定最好先在父widget中管理，因为大多数情况外层需要对状态数据进行处理并更新子widget，外层处理状态也有利于子widget保持整洁。当widget既包含用户状态又包含外部不关注的自身界面效果状态则使用混合状态管理模式。
* 对于必须传入的参数使用@require注解
## 添加assets和图片
* 在pubspec.yaml中声明assets文件夹的路径声明，如果需要添加子文件夹的话需要单独列出
* 声明assets时会同时查找其定义的子文件夹是否有同名的文件，如果有的话会把同名的文件同时引入，这是为了方便引入不同分辨率的图片资源
* 使用DefaultAssetBundle.of(context).load()或loadString()方法加载asset文本资源，其中context最好使用当前widget的BuildContext，这有利于父widget在测试或者本地化时在运行时替换不同的AssetBundle。
* 当不能获取widget context的地方，可以使用rootBundle来加载文本资源
* 对于图片资源，可以使用相同的图片命名并放在2.0x和3.0x文件夹中，不同dp/px比例的手机会自动选用合适大小的资源
* 使用AssetImage加载图片会自动选择对应分辨率的图片，如果需要加载不同package的图片，需要在AssetImange中指定package
* 对于不在同一个package的图片资源，也需要在pubspec.yaml文件中定义，例如需要引用package为fancy_backgrounds的图资源，需要在当前的pubspec.yaml中定义assets路径为packages/fancy_backgrounds/xxx(图片在fancy_backgrounds中libs目录下的相对位置)
* 在Android中使用flutter的asset资源，使用PluginRegistry.Registrar.lookupKeyForAsset()方法获取key，并使用AssetManager.openFd(key)方法获取AssetFileDescriptor
* 在iOS中使用flutter的asset资源，可以使用registrar lookupKeyForAsset或者key，然后通过mainBundle pathForResource:key ofType或者asset路径。如果使用了ios_platform_images插件，那么可以直接使用OC中的UIImage flutterImageWithName或者Swift中的UIImage.flutterImageNamed获取。
* flutter中使用iOS的图片可以使用ios_platform_images插件中的IosPlatformImages.load方法
* 启动页会在Flutter绘制第一帧的时候被替换，如果在main方法中不调用runApp方法，那么启动页将一直展示。
* 加入启动页的方式需要使用Android和iOS的本身的方式加入。
## 页面导航
### 导航至新页面并返回
* route在安卓中相当于Activity，在iOS中相当于ViewController，在Flutter中，route表示的只是一个widget
* 页面导航的步骤：创建两个route，使用Navigator.push()导航到第二个route，使用Navigator.pop()返回到上一个route
```dart
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SecondRoute()),
  )
```
* 通过创建MaterialPageRoute适配安卓和iOS页面跳转的动效，通过设置maintainState释放上一个页面的内存，通过fullscreenDialog设置是否全屏dialog样式
### 使用具名路由跳转
* 当页面之间跳转较多时，在MaterialApp中声明路由关系，然后使用具名路由导航Navigator.pushNamed()可以减少代码重复
```dart
  MaterialApp(
  // Start the app with the "/" named route. In this case, the app starts
  // on the FirstScreen widget.
  initialRoute: '/',
  routes: {
    // When navigating to the "/" route, build the FirstScreen widget.
    '/': (context) => FirstScreen(),
    // When navigating to the "/second" route, build the SecondScreen widget.
    '/second': (context) => SecondScreen(),
  },
);
```
```dart
Navigator.pushNamed(context, '/second');
```
### 非具名路由之间传递数据
* 使用非具名路由跳转有两种页面间传递数据的做法，一种是跳转新页面时在Widget的构造函数中传入数据；第二种是通过设置MaterialPageRoute的RouteSettings中的arguments，并在跳转页面中使用ModalRoute.of(context).settings.arguments获取
```dart
  // 第一种方法
  Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DetailScreen(todo: todos[index]),
        ),
    );
```
```dart
  // 第二种方法—设置参数
  Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DetailScreen(),
            // Pass the arguments as part of the RouteSettings. The
            // DetailScreen reads the arguments from these settings.
            settings: RouteSettings(
                arguments: todos[index],
            ),
        ),
    );
```
```dart
  // 第二种方法—获取参数
  final Todo todo = ModalRoute.of(context).settings.arguments;
```
### 具名路由之间传递数据
* 使用具名路由跳转有两种页面间传输的做法，一种是使用Navigator.pushNamed并设置arguments，然后在跳转页面使用ModalRoute.of(context).settings.arguments获取；第二种是是使用Navigator.pushNamed并设置arguments，然后在MaterialApp的onGenerateRoute方法中获取settings.arguments并在返回的MaterialPageRoute中通过构造函数设置给跳转页面
```dart
  // 第一种方法—设置
  Navigator.pushNamed(
      context,
      ExtractArgumentsScreen.routeName,
      arguments: ScreenArguments(
        'Extract Arguments Screen',
        'This message is extracted in the build method.',
      ),
    );
```
```dart
  // 第一种方法—获取
  final ScreenArguments args = ModalRoute.of(context).settings.arguments;
```
```dart
  // 第二种方法—通过onGenerateRoute方法构造目标页面并传递参数
  MaterialApp(
  // Provide a function to handle named routes. Use this function to
  // identify the named route being pushed, and create the correct
  // screen.
  onGenerateRoute: (settings) {
    // If you push the PassArguments route
    if (settings.name == PassArgumentsScreen.routeName) {
      // Cast the arguments to the correct type: ScreenArguments.
      final ScreenArguments args = settings.arguments;

      // Then, extract the required data from the arguments and
      // pass the data to the correct screen.
      return MaterialPageRoute(
        builder: (context) {
          return PassArgumentsScreen(
            title: args.title,
            message: args.message,
          );
        },
      );
    }
  },
);
```
### 从目标页面返回数据
* 使用Navigator.pop设置数据，并使用await获取Navigator.push返回结果
```dart
// 设置数据
Navigator.pop(context, 'Yep!');
// 获取数据
final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => nextScreen()),
  );
```

## 动画
### Implicit动画
* 对于普通的修改大小和形状等的属性动画可以使用Implicit动画，设置动画时间duration、动画效果curve。常用的Implicit动画有以下这些：
  * Align -> AnimatedAlign
  * Container -> AnimatedContainer
  * DefaulTextStyle -> AnimatedDefaulTextStyle
  * Opacity -> AnimatedOpacity
  * Padding -> AnimatedPadding
  * PhysicalModel -> AnimatedPhysicalModel
  * Positioned -> AnimatedPositioned
  * PositionedDirectional -> AnimatedPositionedDirectional
  * Theme -> AnimatedThemeSize -> AnimatedSize
* 若没有能满足需求的Implicit动画widget，那么可以尝试使用TweenAnimationBuilder来实现自定义属性动画
### Explicit动画
* 如果想要对动画进行播放控制，那么需要使用Explicit动画，并在turns中指定AnimationController。常用的Explicit动画有以下这些：
  * SizeTransition
  * FadeTransition
  * AlignTransition
  * ScaleTransition
  * SlideTransition
  * RotationTransition
  * PositionedTransition
  * DecoratedBoxTransition
  * DefaultTextStyleTransition
  * RelativePositionedTransition
  * StatusTransitionWidget
* Explicit动画的几个概念：
  * `Animaion<double>`：CurvedAnimation和AnimationController都继承自`Animaion<double>`，通过Animaion可以获取动画的状态目前的插值，但是Animaion不会参与动画的绘制
  *  CurvedAnimation用于定义动画的非线性过程；AnimationController用于控制动画播放进度，需要传入TickerProvider来减少处于屏幕外的动画资源消耗；Tween用于对Animation的范围进行转化；Animation可以通过设置Listners和StatusListeners来监听动画状态。
* SingleTickerProviderStateMixin是TickerProvider的实现；mixin是线性叠加的代码继承，最后的类会覆盖前面类方法，mixin是类的一层一层叠加，类型判断可以为每一层的类，mixin更多强调的是代码的复用而不是类继承关系，mixin是一种类型不能实例化。参考：[When to use mixins and when to use interfaces in Dart?
](https://stackoverflow.com/questions/45901297/when-to-use-mixins-and-when-to-use-interfaces-in-dart#:~:text=Mixins%20is%20all%20about%20how,that%20the%20class%20must%20satisfy.)
  > Mixins is all about how a class does what it does, it's inheriting and sharing concrete implementation. Interfaces is all about what a class is, it is the abstract signature and promises that the class must satisfy. 
* 如果想对动画进行播放控制，但是没有现成的Explicit动画，那么可以使用AnimatedBuilder或者AnimatedWidget
* AnimatedWidget需要传入一个listenable，一般是Animation，也可以是 ChangeNotifier and ValueNotifier，AnimatedWidget会在listenable变化的时候调用setState重新build从而产生动画效果。
  ```dart
  // 不使用AnimatedWidget
  animation = Tween<double>().animate(controller)
    ..addListener(() {
      setState((){});
    };
  ...
  Widget build(BuildContext context) => GeneralWidget(animation);

  // 使用AnimatedWidget
  animation = Tween<double>().animate(controller);
  ...
  Widget build(BuildContext context) => AnimatedWidget(animation);
  ```
* 继承自AnimatedWidget一般命名为FooTransition,而继承自ImplicitlyAnimatedWidget一般命名为AnimatedFoo，这里Foo指的是没有加入动画的widget名字.AnimatedWidget与ImplicitlyAnimatedWidget的最大区别在于前者需要使用者自己维护一个Animation，可以对动画进行控制；后者自身会带一个Animation并维护自身的动画状态，不需要使用者参与管理。
* 如果构造复杂的动画，可以使用AnimatedBuilder。为了性能考虑，可以在AnimatedBuilder中指定动画元素child，并在builder中将child传入动画中，避免每次动画tick回调都会重新build child。
```dart
class _SpinnerState extends State  with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Container(
        width: 200.0,
        height: 200.0,
        color: Colors.green,
        child: const Center(
          child: Text('Wee'),
        ),
      ),
      builder: (BuildContext context, Widget child) {
        return Transform.rotate(
          angle: _controller.value * 2.0 * math.pi,
          child: child,
        );
      },
    );
  }
}
```
[动画效果](https://flutter.github.io/assets-for-api-docs/assets/widgets/animated_builder.mp4)
* 可以对Animation使用addStatusListener添加动画状态监听。
* 使用SpringSimulation可以产生物理的弹性效果。
### Hero动画
* 页面间共享元素：使用Hero包裹页面间的共享widget，并设置一个相同的tag。当路由push和pop的时候都会触发动画。
* 共享元素能在两个页面之间过渡，其原理是使用了application overlay widget，并使用RecTween生成过渡动画。
* debug过程中可以使用`scheduler.dart`中的timeDilation减慢动画效果
* 在Hero中声明createRectTween为MaterialRectCenterArcTween可以使得动画产生中心变化的效果，默认的情况是使用Hero的四个角，如果形状变化的动画可以会产生变形。
* 如果想要更自然的形状变化效果，可以根据Hero动画过程中的大小变化动态设置目标位置大小，例子见[radial_hero_animation_animate_rectclip](https://github.com/flutter/website/blob/master/examples/_animation/radial_hero_animation_animate_rectclip/main.dart)
### 交替动画
* 通过指定Animation的curve为Interval来设置动画在Controller0到1之间出现的时机
  ```dart
  borderRadius = BorderRadiusTween(
      begin: BorderRadius.circular(4.0),
      end: BorderRadius.circular(75.0),
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          0.375, 0.500,
          curve: Curves.ease,
        ),
      ),
    ),
  ```
## 高级UI
### Silvers
### Gestures
### 闪屏
#### Android
* 设置应用打开闪屏的设置与原生方式一样，都是给第一个打开的activity设置主题
* 设置name为io.flutter.embedding.android.NormalTheme的meta-data来定义正常主题，这样就会使得页面从启动的主题转变为正常的主题。
* 在Android Activity启动后，还需要初始化Dart isolate，这段时间可以再设置闪屏
* 设置Flutter的闪屏有两种方法，一种是设置展示一个drawable，可以在Activity的Manifest中设置name为`io.flutter.embedding.android.SplashScreenDrawable`的meta-data并指定drawable资源，或在Fragment中重写provideSplashScreen方法返回一个DrawableSplashScreen对象。第二种方法是实现SplashScreen接口，通过createSplashView提供自定义闪屏view，并通过transitionToFlutter方法标记闪屏view动画是否完成。
#### iOS
# 学习资源
* [Flutter samples](https://github.com/flutter/samples/blob/master/INDEX.md)
* [Flutter YouTube playlist](https://www.youtube.com/channel/UCwXdFgeE9KYzlDdR7TG9cMw/playlists)
* [The Mahogany Staircase - Flutter's Layered Design](https://www.youtube.com/watch?v=dkyY9WCGMi0)
* [Flutter: The Advanced Layout Rule Even Beginners Must Know](https://medium.com/flutter-community/flutter-the-advanced-layout-rule-even-beginners-must-know-edc9516d1a2)
* [Widget库](https://flutter.dev/docs/development/ui/widgets)