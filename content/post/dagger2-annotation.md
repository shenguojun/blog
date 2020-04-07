---
title: "Dagger2注解大全"
date: 2019-01-14T20:00:40+08:00
author: 申国骏
tags: ["android"]
---

# 前言
&emsp;&emsp;Dagger是帮助实现依赖注入的库，虽然很多人都知道依赖注入对于架构设计的重要性，但是Dagger学习曲线十分陡峭，官方文档更是看了几遍也很难消化。本文旨在通过一篇文章来让大家看懂并上手Dagger。  
&emsp;&emsp;Dagger最早由[JakeWharton](https://jakewharton.com/)在square公司开发。后来转由Google维护并发展为Dagger2。Dagger2区别于Dagger1的地方主要在于两个，一个是由运行时通过反射构建依赖关系变为编译期通过注解生成依赖关系，另一个是出错时有更好地提醒（当然这也是因为Dagger2在编译期间根据注解生成好了可读性较好的代码带来的优势）。 转载请注明来源[「Bug总柴」](https://www.jianshu.com/u/b692bbf77991) 

# 参考
初学者建议先不要看官方文档，可以先看这几篇博客：  
* [Dagger 2 完全解析系列](http://johnnyshieh.me/posts/dagger-basic/) 
* [Dagger2 最清晰的使用教程](https://www.jianshu.com/p/24af4c102f62) 
* [Dagger 2 for Android Beginners系列](https://medium.com/@harivigneshjayapalan/dagger-2-for-android-beginners-introduction-be6580cb3edb)

# 依赖注入
在学习Dagger之前，我们先来了解一下依赖注入。
## 什么是依赖注入  
&emsp;&emsp;依赖注入，顾名思义，就是说当代码执行过程中需要某个服务对象的时候，不是通过当前代码自己去构造或者去查找获取服务对象，而是通过外部将这个服务对象传给当前代码。  
&emsp;&emsp;这样做的好处在于当服务对象构建或者获取方法改变时，不需要改变调用方的代码，这也是[S.O.L.I.D](https://en.wikipedia.org/wiki/SOLID)原则中[开发封闭原则](https://en.wikipedia.org/wiki/Open%E2%80%93closed_principle)的具体表现。
## 如何实现依赖注入  
在不使用Dagger等依赖注入库的情况下，我们可以通过以下三种方式手动实现依赖注入。
* 构造器依赖注入
```java
// Constructor
Client(Service service) {
    // Save the reference to the passed-in service inside this client
    this.service = service;
}
```
* Setter方法依赖注入
```java
// Setter method
public void setService(Service service) {
    // Save the reference to the passed-in service inside this client.
    this.service = service;
}
```
* 接口依赖注入
```
// Service setter interface.
public interface ServiceSetter {
    public void setService(Service service);
}

// Client class
public class Client implements ServiceSetter {
    // Internal reference to the service used by this client.
    private Service service;

    // Set the service that this client is to use.
    @Override
    public void setService(Service service) {
        this.service = service;
    }
}
```
##  Dagger2基本概念  
Dagger2可以理解成就是在编译阶段根据注解构建一个依赖关系图，然后根据依赖关系图之间的依赖关系生成对象工厂类，在需要的地方注入对象。如何使用注解构造一个依赖关系图是Dagger2使用的关键。在了解注解之前，我们先来认识一下以下三个概念：
### bindings
bindings的概念是告诉Dagger注入器如何能得到一个具体类。有几种方法可以表示当前代码可以提供某个类型的对象：
* 通过使用`@Provides`注解的非抽象方法返回一个类对象
```java
@Provides
public Fruit providerApple() {
    return new Apple();
}
```
* 通过`@Binds`注解的抽象方法，该抽象方法返回接口或抽象类，参数是一个该接口或者抽象类的具体实现类
```java
@Binds
abstract Fruit bindApple(Apple apple);
```
* 通过`@Inject`注解的构造方法
```java
public class Apple implements Fruit {
    @Inject
    public Apple() {
    }
}
```
* 通过`multibindings`（`@MapKey`后面提到）或者`producers`（暂不细说）提供

### modules
module是一个只有`@Provides`和`@Binds`方法的类，用于集合所有的依赖关系。同时module可以通过`inculdes`来引入其他module从而得到其他module的依赖关系集合。例如：
```java
@Module(includes = ProjectModule.class)
public abstract class FruitModule {
    @Binds 
    abstract Fruit bindApple(Apple apple);

    @Provides
    static Desk provideDesk() {
        return new Desk();
    }
}
```

### components
`component`是被`@Component`标注的接口或者抽象类，Dagger会负责实例化一个`component`。`component`中指定需要的`modules`，代表着这次依赖构建所有需要的全部依赖关系都可以从`modules`中找到。`compoent`中的方法只能是无参的，且这个无参方法的返回值就是Dagger最终需要构建得到的实体。**可以说构建`component`中无参方法的返回值对象就是整个依赖关系查找的起源点**。在构建这个实体时，如果遇到依赖，就会从`modules`中不断地传递查找，直到所有的依赖都被找到为止。如果中间有某些依赖没有注明实例化方式，Dagger会在编译期间报错。具体`component`的一个例子如下：
```java
@Component(modules = {FruitModule.class, ProjectModule.class})
public interface FruitComponent {
    FruitShop inject();
}
```
### bindings\modules\components的依赖关系图可以表示为下图所示
![Dagger依赖图.png](https://upload-images.jianshu.io/upload_images/2057980-45abc423e8a37514.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



# Dagger2注解  
知道上面的概念可以看懂基本的Dagger代码。不过Dagger有非常多帮助完成依赖关系图构建的注解，只有把这些注解都弄懂了，才能真正看懂Dagger2的代码。下面两个图可以看到一些常用的注解：

![javax.inject.png](https://upload-images.jianshu.io/upload_images/2057980-642ae0a8be862ec1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![dagger.png](https://upload-images.jianshu.io/upload_images/2057980-83c3d2cb425b1fec.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

下面我们来一一介绍一下。

## @Inject
`@Inject`是`javax.inject`包中的注解，可以用于对类的**构造函数**、**成员变量**和**方法**。
### 用于类构造器中表示该类在依赖注入时使用被注解的构造器创建对象。
例如：
```java
public class FruitShop {
    @Inject
    public FruitShop() {
    }
}
```
表示当其他地方依赖于`FruitShop`对象时，会使用FruitShop的默认构造方法进行创建。当被`@Inject`注解的构造函数是有参数的，那么Dagger会同时对其参数进行注入。例如：
```java
public class FruitShop {
    @Inject
    public FruitShop(Desk desk) {
    }
}
```
当需要构建依赖关系时，在创建FruitShop的时候回对参数`desk`进行注入。  
在生成的`FruitShop_Factory.java`代码中，可以看到以下方法：
```java
public final class FruitShop_Factory implements Factory<FruitShop> {
    private final Provider<Desk> deskProvider;
    
    public FruitShop_Factory(Provider<Desk> deskProvider) {
        this.deskProvider = deskProvider;
    }
    public static FruitShop provideInstance(Provider<Desk> deskProvider) {
        FruitShop instance = new FruitShop(deskProvider.get());
        return instance;
    }
}
```
`@Inject`用于构造函数需要注意两点：
1. 每个类只允许一个构造方法注解为`@Inject`，例如
```java
public class FruitShop {
    // 由于有另外的构造函数注解了@Inject，这里不能再使用@Inject，否则编译会出错Error: Types may only contain one @Inject constructor.
    public FruitShop() {
    }
    
    @Inject
    public FruitShop(Location location) {
    }
}
```
2. `javax.inject.Inject`文档中说明当被注解的构造函数是public且无参的默认构造函数`@Inject`可以省略。但是实际Dagger2项目中，需要被注入的对象必须拥有`@Inject`注解的构造方法或者通过`@Porvides`注解的方法提供，否则会报错`Error: cannot be provided without an @Inject constructor or an @Provides-annotated method.`。这一点Dagger的处理与`javax.inject.Inject`描述表现不一致。


### 用于成员变量中表示该成员变量作为依赖需要被注入
例如：
```java
public class FruitShop {
    @Inject
    Fruit apple;
}
```
表示`FruitShop`中需要依赖水果`apple`，并希望由外部注入进来。
编译之后我们会看到一个`FruitShop_MembersInjector.java`的类，里面会有一个这样的方法：
```java
public final class FruitShop_MembersInjector implements MembersInjector<FruitShop> {
    // Dagger生成代码中会通过MembersInjector给我们对象需要的属性进行注入
    public static void injectApple(FruitShop instance, Fruit apple) {
        instance.apple = apple;
    }
}
```
对于属性注解需要注意被注解的属性不能是`final`或者被`private`修饰符修饰。其中的原因在上面`instance.apple = apple;`代码中不言而喻。  
在生成的`FruitShop_Factory.java`代码中，可以看到以下方法：
```java
public final class FruitShop_Factory implements Factory<FruitShop> {
    private final Provider<Fruit> appleProvider;
    
    public FruitShop_Factory(Provider<Fruit> appleProvider) {
        this.appleProvider = appleProvider;
    }
    public static FruitShop provideInstance( Provider<Fruit> appleProvider) {
        FruitShop instance = new FruitShop();
        FruitShop_MembersInjector.injectApple(instance, appleProvider.get());
        return instance;
    }
}
```

### 用于方法中表示依赖于方法参数的类型会被注入
例如：
```java
public class FruitShop {
    Desk mDesk;

    @Inject
    public void setDesk(Desk desk) {
        this.mDesk = desk;
    }
}
```
被注解的`setDesk()`方法有一个`Desk`类型的参数，意味着需要对`Desk`进行依赖注入。Dagger生成的代码如下所示：
```java
public final class FruitShop_Factory implements Factory<FruitShop> {
    private final Provider<Desk> deskProvider;
    
    public FruitShop_Factory(Provider<Desk> deskProvider) {
        this.deskProvider = deskProvider;
    }
    public static FruitShop provideInstance(Provider<Desk> deskProvider) {
        FruitShop instance = new FruitShop();
        FruitShop_MembersInjector.injectSetDesk(instance, deskProvider.get());
        return instance;
    }
}
public final class FruitShop_MembersInjector implements MembersInjector<FruitShop> {
    public static void injectSetDesk(FruitShop instance, Desk desk) {
        instance.setDesk(desk);
    }
}
```
`@Inject`用于注解方法需要注意被注解的方法不能是`private`的。被注解的方法支持拥有多个参数。如果标注在public方法上，Dagger2会在构造方法执行之后立即调用这个方法。

## @Provides &  @Module & @Component
使用`@Inject`来标记依赖的注入不是什么时候都可以的，例如第三方api的代码我们是不能修改的，没办法通过`@Inject`注解第三方api类的构造器，从而没办法对第三方api的对象进行构建和依赖注入。这个时候我们可以使用`@Provides`来提供对应的依赖。而`@Provides`必须放到一个被`@Module`注解的类中。例如：
```java
// 通过在module中使用@Provides表示提供依赖的方法
@Module
public  class FruitModule {
    @Provides
    Fruit provideApple() {
        return new Apple();
    }
}

// 使用@Inject说明需要依赖注入的地方
public class FruitShop {
    // 这里需要提供一个Fruit类型的依赖
    @Inject
    Fruit apple;

    @Inject
    public FruitShop() {
    }
}

// 将需要用到依赖的地方FruitShop和提供依赖的地方FruitModule绑定在一起
@Component(modules = FruitModule.class)
public interface FruitComponent {
    FruitShop inject();
}
```
这里在module中声明了一个可以提供`Apple`类依赖的方法`provideApple()`。并且component将依赖的需求方和提供方都绑定在了一起。我们来看生成的代码
```java
public final class FruitModule_ProvideAppleFactory implements Factory<Fruit> {
  private final FruitModule module;

  public FruitModule_ProvideAppleFactory(FruitModule module) {
    this.module = module;
  }

  @Override
  public Fruit get() {
    return provideInstance(module);
  }

  public static Fruit provideInstance(FruitModule module) {
    return proxyProvideApple(module);
  }

  public static FruitModule_ProvideAppleFactory create(FruitModule module) {
    return new FruitModule_ProvideAppleFactory(module);
  }

  public static Fruit proxyProvideApple(FruitModule instance) {
    return Preconditions.checkNotNull(
        instance.provideApple(), "Cannot return null from a non-@Nullable @Provides method");
  }
}
```
这段生成的代码实际上是提供`Apple`类工厂`FruitModule_ProvideAppleFactory`，能够通过`provideApple()`提供`Apple`对象。以下的代码中，component通过传递`FruitModule_ProvideAppleFactory`对象到`FruitShop_Factory`中完成对`FruitShop`的依赖注入
```java
public final class DaggerFruitComponent implements FruitComponent {
  private FruitModule_ProvideAppleFactory provideAppleProvider;
  
  private void initialize(final Builder builder) {
    this.provideAppleProvider = FruitModule_ProvideAppleFactory.create(builder.fruitModule);
    this.fruitShopProvider = DoubleCheck.provider(FruitShop_Factory.create(provideAppleProvider));
  }
}
```
通过`@Provides` `@Module` `@Component` 三个注解就可以完成最基本的依赖注入关系图的构造，从而使用Dagger给依赖进行注入。这里需要注意：
* 通过`@Provides`注解的方法不能返回null，否则会报`NullPointerException`。如果`@Provides`方法可能返回null，那需要加上注入`@Nullable`，同时在需要依赖注入的地方加上`@Nullable`标注。
* 一般module类都使用XXXModule命名，而provide方法一般都使用provideXXX命名方式。

## @Binds
`@Binds`的作用和`@Provides`的作用是一样的，是提供接口依赖的一种简洁表示的方式。例如下面这个例子：
```java
@Module
public  class FruitModule {
    @Provides
    Fruit provideApple() {
        return new Apple();
    }
}
```
使用`@Binds`可以简化为：
```java
@Module
abstract public  class FruitModule {
    @Binds
    abstract Fruit bindApple(Apple apple);
}
```
表示当需要依赖`Furit`接口时，使用`Apple`实例对象进行注入。需要注意的是，使用`@Binds`标注的方法必须有且仅有一个方法参数，且这个方法参数是方法返回值的实现类或者子类。

## @Component
因为Componet较为复杂，拿出来再单独说一下。Component的声明如下：
```java
public @interface Component {
    Class<?>[] modules() default {};
    Class<?>[] dependencies() default {};
    @interface Builder {}
}
```
这代表着`@Component`的标签中除了可以指定modules之外还可以通过dependencies引用其他的component。在被`@Component`注解的类必须是接口或者抽象类，这个被注解的类中可以包含以下三个东西：
1. 表示需要提供的依赖的方法，例如：
```java
// 表示需要注入依赖生成SomeType类对象
SomeType getSomeType();
// 表示需要注入依赖生成Set<SomeType>对象，multibinding后面会介绍
Set<SomeType> getSomeTypes();
// 表示需要注入生成一个Qualifier为PortNumber的int整形，Qualifier后面会介绍
@PortNumber int getPortNumber();
// 表示需要注入依赖生成Provider<SomeType>对象，Provider<>后面介绍
Provider<SomeType> getSomeTypeProvider();
// 表示需要注入依赖生成Lazy<SomeType>对象，Lazy<>后面会介绍
Lazy<SomeType> getLazySomeType();
```
2. 表示需要注入成员依赖的方法,
```java
// 表示需要将someType中标记为依赖的属性和方法进行注入
void injectSomeType(SomeType someType);
// 表示需要将someType中标记为依赖的属性和方法进行注入，并返回SomeType对象
SomeType injectAndReturnSomeType(SomeType someType);
```
3. 构造Component的Builder  
Dagger生成Component实现类时，会自动根据Bulder模式生成所需要Builder类。当Component所依赖的Module为非抽象且默认构造函数为private时，则Dagger会生成对应的有传入module方法的Builder类，例如：
```java
@Component(modules = ProjectModule.class)
public interface FruitComponent {
    FruitShop inject();
}

@Module
public class ProjectModule {
    private Desk mDesk;

    private ProjectModule(){}
    
    public ProjectModule(Desk desk){
        mDesk = desk;
    }
    
    @Provides
    public Desk provide() {
        return mDesk;
    }
}
```
则在生成的DaggerFruitComponent中会有以下Builder方法
```java
public final class DaggerFruitComponent implements FruitComponent {
  private ProjectModule projectModule;
  
  public static final class Builder {
    private ProjectModule projectModule;

    private Builder() {}

    public FruitComponent build() {
      if (projectModule == null) {
        throw new IllegalStateException(ProjectModule.class.getCanonicalName() + " must be set");
      }
      return new DaggerFruitComponent(this);
    }

    public Builder projectModule(ProjectModule projectModule) {
      this.projectModule = Preconditions.checkNotNull(projectModule);
      return this;
    }
  }
}
```
在调用时需要传入依赖的module：
```java
FruitShop fruitShop = DaggerFruitComponent
                    .builder()
                    .projectModule(new ProjectModule(new Desk()))
                    .build()
                    .inject();
```
当Component所依赖的module和其他Componet都不需要使用有参的构造函数的话，Component可以使用简洁的`create()`方法，例如将上面的module改为：
```java
@Module
public class ProjectModule {
    
    @Provides
    public Desk provide() {
        return new Desk();
    }
}
```
则生成的componet会是这样的：
```java
public final class DaggerFruitComponent implements FruitComponent {
  public static FruitComponent create() {
    return new Builder().build();
  }
  public static final class Builder {
    private ProjectModule projectModule;

    private Builder() {}

    public FruitComponent build() {
      if (projectModule == null) {
        this.projectModule = new ProjectModule();
      }
      return new DaggerFruitComponent(this);
    }

    public Builder projectModule(ProjectModule projectModule) {
      this.projectModule = Preconditions.checkNotNull(projectModule);
      return this;
    }
  }
}
```
在调用时仅需调用`create()`方法既可
```java
FruitShop fruitShop = DaggerFruitComponent.create().inject();
```

## @Qualifier  
在上面了解完`@Inject`之后，大家可能有个疑惑，使用`@Inject`注入的对象如果是接口或者抽象类怎么办呢？在不同的地方可能需要不同的接口或者抽象类的实现，怎么让Dagger知道我究竟需要的哪种实现类呢？例如：
```java
public class FruitShop {
    @Inject
    Fruit apple;

    @Inject
    Fruit orange;
}
```

&emsp;&emsp;这里代码需要对`apple`和`orange`进行注入，但是对于`Fruit`的注入只能声明一个，所以这个地方`apple`和`orange`要么都被注入成`class Apple implements Fruit`或者`class Orange implements Fruit`。  
&emsp;&emsp;`@Qualifier`这个时候就能作为一个限定符派上用场了。`@Qualifier`是加在注解之上的注解（也称为元注解），当需要注入的是接口或者抽象类，就可以使用`@Qualifier`来定义一个新的注解用来表明对应需要的依赖关系。使用`@Qualifier`可以实现指定`apple`需要用`Apple`注入，`orange`需要使用`Orange`类注入。例如我们可以这样实现
```java
// 首先定义一个表示水果类型的注解
@Qualifier
@Documented
@Retention(RUNTIME)
public @interface FruitType {
    String value() default "";
}
```
```java
// 接着使用这个注解表示对应依赖关系
@Module
public abstract class FruitModule {
    @Binds @FruitType("apple")
    abstract Fruit bindApple(Apple apple);

    @Binds @FruitType("orange")
    abstract Fruit bindOrange(Orange orange);
}
```
```java
// 使用时标记相应的注解既可
public class FruitShop {
    @Inject @FruitType("apple")
    Fruit apple;

    @Inject @FruitType("orange")
    Fruit orange;
}
```
除了可以声明value为String的注解外，还可以传入其他类型，例如我们需要一张颜色是红色的桌子：
```java
@java.lang.annotation.Documented
@java.lang.annotation.Retention(RUNTIME)
@javax.inject.Qualifier
public @interface DeskColor {
    Color color() default Color.RED;
    public enum Color { RED, WHITE }
}
```
在Module中可以指定具体生成的对象：
```java
@Module
public class ProjectModule {

    @Provides @DeskColor(color = DeskColor.Color.RED)
    public Desk provideDesk() {
        return new Desk("RED");
    }
}
```
在使用时再进行标记既可：
```java
public class FruitShop {

    @Inject
    public FruitShop() {
    }

    @Inject @DeskColor(color = DeskColor.Color.RED)
    Desk desk;
}
```
通过`@Qualifier`定义注解可以实现对同一个接口或抽象类的指定不同对象注入。

## @Named 
了解完`@Qualifier`之后再看看`@Name`的声明：
```java
@Qualifier
@Documented
@Retention(RUNTIME)
public @interface Named {

    /** The name. */
    String value() default "";
}
```
可以看出除了接口名称不一样之外，其余的和上面定义的`@FruitType`是一致的，所以其实`@Named`只是系统定义好的，参数为String的默认限定符。将上面代码中的`@FruitType`改成`@Named`能达到一样的效果。
## @Scope和@Singleton  
`@Scope`是另一个元注解，它的作用是告诉注入器要注意对象的重用的生命周期。其中`@Scope`的声明如下：
```java
@Target(ANNOTATION_TYPE)
@Retention(RUNTIME)
@Documented
public @interface Scope {}
```
我们再看`@Singleton`的声明：
```java
@Scope
@Documented
@Retention(RUNTIME)
public @interface Singleton {}
```
可以发现`@Singleton`就是被`@Scope`声明的注解，可以作为一个生命周期的注解符。  
例如我们需要注入一个`Desk`类，我们希望一个`FruitShop`对应只有一个`Desk`，正常的情况下我们是这样声明的：
```java
public class FruitShop {

    @Inject
    public FruitShop() {
    }

    @Injec
    Desk desk;

    @Inject
    Desk desk2;
    
    public String checkDesk() {
        return desk == desk2 ? "desk equal" : "desk not equal";
    }
}

@Module
public class ProjectModule {

    @Provides
    public Desk provideDesk() {
        return new Desk();
    }
}

@Component(modules = ProjectModule.class)
public interface FruitComponent {
    FruitShop inject();
}
```
在Main函数中执行
```java
public class Main {

    public static void main(String[] args) {
        FruitShop fruitShop = DaggerFruitComponent.create().inject();
        System.out.println(fruitShop.checkDesk());
    }
}
```
得到的结果是
> desk not equal  
> 
> Process finished with exit code 0

当然这不是我们希望得到的结果，下面我们来用`@Singleton`改造一下如下：
```java
public class FruitShop {

    @Inject
    public FruitShop() {
    }

    @Injec
    Desk desk;

    @Inject
    Desk desk2;
    
    public String checkDesk() {
        return desk == desk2 ? "desk equal" : "desk not equal";
    }
}

@Module
public class ProjectModule {

    @Provides
    @Singleton
    public Desk provideDesk() {
        return new Desk();
    }
}

@Singleton
@Component(modules = ProjectModule.class)
public interface FruitComponent {
    FruitShop inject();
}
```
现在Rebuild之后再运行一下：
> desk equal  
> 
> Process finished with exit code 0

和之前不同的地方在于我们队Component和module中的provide方法都加了`@Singleton`标记。我们来看看对比下前后生成的代码有什么区别：

![diff.png](https://upload-images.jianshu.io/upload_images/2057980-480379ecf6e735e1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

可以看出，两次生成的代码中，只有`DaggerFruitComponent`有区别，其中的区别在于在Component中`provideDeskProvider`在有`@Singleton`标注的例子中是单例的存在：
```java
  private void initialize(final Builder builder) {
    // DoubleCheck.provider就是用了双重检验的单例模式提供单例
    this.provideDeskProvider =
        DoubleCheck.provider(ProjectModule_ProvideDeskFactory.create(builder.projectModule));
  }
  
  private FruitShop injectFruitShop(FruitShop instance) {
    FruitShop_MembersInjector.injectDesk(instance, provideDeskProvider.get());
    FruitShop_MembersInjector.injectDesk2(instance, provideDeskProvider.get());
    return instance;
  }
```
其中`DoubleCheck.get()`方法使用双重判断获取单例。
```java
public final class DoubleCheck<T> implements Provider<T>, Lazy<T> {
  @Override
  public T get() {
    Object result = instance;
    if (result == UNINITIALIZED) {
      synchronized (this) {
        result = instance;
        if (result == UNINITIALIZED) {
          result = provider.get();
          instance = reentrantCheck(instance, result);
          /* Null out the reference to the provider. We are never going to need it again, so we
           * can make it eligible for GC. */
          provider = null;
        }
      }
    }
    return (T) result;
  }
}
```
而在没有使用`@Singletion`的例子中，并没有使用单例来提供`Desk`对象：
```java
  private void initialize(final Builder builder) {
    this.projectModule = builder.projectModule;
  }
  private FruitShop injectFruitShop(FruitShop instance) {
    FruitShop_MembersInjector.injectDesk(
        instance, ProjectModule_ProvideDeskFactory.proxyProvideDesk(projectModule));
    FruitShop_MembersInjector.injectDesk2(
        instance, ProjectModule_ProvideDeskFactory.proxyProvideDesk(projectModule));
    return instance;
  }
```
通过上面的例子可以看出`@Scope`是用来定义需要的依赖对象在一个Component依赖关系图生成中是否需要重用，且重用的范围在一个Component对象的引用范围内。至于`@Scope`的意义在于可以在Components之间的依赖中使得依赖对象在不同的Components中重用。Components之间的依赖会在后面介绍。

这里需要注意几点：

1. `@Scope`注解的注解不能用于标注依赖的构造函数
2. 没有被`@Scope`注解的注解（如`@Singleton`）注解的componet不能存在被`@Scope`注解的注解（如`@Singleton`）注解的方法（有点绕，可以理解成没有标志为`@Singleton`的componet不能拥有标志为`@Singleton`的方法）
3. 如果componet定义了一个scope，那么这个componet里面只能存在没有scoped的依赖关系，或者拥有跟componet一样scope的依赖关系
4. 使用Componet的调用方需要负责重用范围的定义，例如希望有一个全局的单例，那么则需要保存一个拥有全局生命周期的component依赖生成类对象。

## @Reusable 
与`@Singleton`类似的，`@Reusable`也是被`@Scope`注释的注释。与`@Singleton`不同的是，`@Reusable`只表示Dagger生成的对象可以被缓存起来，从而节省内存消耗，但是不能保证对象的单例性质。我们将上面例子中的`@Singleton`改成`@Reusable`
```java
@Module
public class ProjectModule {

    @Provides
    @Reusable
    public Desk provideDesk() {
        return new Desk();
    }
}
```
rebuild之后我们来看生成的代码
```java
public final class DaggerFruitComponent implements FruitComponent {
  private void initialize(final Builder builder) {
    this.provideDeskProvider =
        SingleCheck.provider(ProjectModule_ProvideDeskFactory.create(builder.projectModule));
  }
  private FruitShop injectFruitShop(FruitShop instance) {
    FruitShop_MembersInjector.injectDesk(instance, provideDeskProvider.get());
    FruitShop_MembersInjector.injectDesk2(instance, provideDeskProvider.get());
    return instance;
  }
}
```
其中`SingleCheck.get()`方法如下：
```java
public final class SingleCheck<T> implements Provider<T> {
  @Override
  public T get() {
    Object local = instance;
    if (local == UNINITIALIZED) {
      // provider is volatile and might become null after the check, so retrieve the provider first
      Provider<T> providerReference = provider;
      if (providerReference == null) {
        // The provider was null, so the instance must already be set
        local = instance;
      } else {
        local = providerReference.get();
        instance = local;

        // Null out the reference to the provider. We are never going to need it again, so we can
        // make it eligible for GC.
        provider = null;
      }
    }
    return (T) local;
  }
}
```
与刚刚的区别是由`DoubleCheck.provider`变成了`SingleCheck.provider`，从代码实现可以看出`@Reusable`并不是严格的单例模式，只是对对象进行了缓存。

## @Component的dependencies和@SubComponent 
虽然独立的没有scope范围的component已经非常实用了，但是在某些情况可能需要用到多个不同scope的不同componet。不同的Component之间可以通过指定依赖关系来联系起来。Components之间的关联可以采取两种方式：指定指定dependencies或者SubComponet。下面我们来看看二者的区别。
### -指定dependencies
当一个Component需要从另一个Componet中获得依赖的时候，可以使用`@Component(dependencies = {XXXComponent.class})`来引用其他component的依赖。需要注意的是，被引用的Component需要显示暴露出给外部的依赖，不然编译会报错。看下面这个例子。
```java
@Singleton
@Component(modules = {FruitModule.class})
public interface FruitComponent {
    FruitShop inject();

    // 对外暴露的依赖，表示其他Component可以从这个Component中
    // 获得@FruitType为apple的类型为Fruit的依赖
    @FruitType("apple")
    Fruit getApple();
}
```
在有了水果的依赖之后，我们创建一个果汁的依赖关系：
```java
public interface Juice {
    String name();
}

public class AppleJuice implements Juice {

    private Fruit mApple;

    // 这里要构建一个苹果汁，需要用到苹果，这个依赖需要从FruitComponent中获得
    @Inject
    public AppleJuice(@FruitType("apple") Fruit apple) {
        mApple = apple;
    }

    @Override
    public String name() {
        return mApple.name();
    }
}

@Module
abstract public class JuiceModule {

    @OtherScop
    @Binds @JuiceType("appleJuice")
    abstract Juice bindAppleJuice(AppleJuice appleJuice);

}

// 这里通过指定dependencies，指出JuiceComponent需要FruitComponent作为依赖
@OtherScop
@Component(dependencies = {FruitComponent.class}, modules = {JuiceModule.class})
public interface JuiceComponent {
    JuiceShop inject();
}

public class JuiceShop {

    @Inject
    public JuiceShop(){}

    // 构建果汁商店需要一个苹果汁，Dagger将负责构建
    @Inject
    @JuiceType("appleJuice")
    public Juice appleJuice;

    public String getJuice() {
        return appleJuice.name();
    }
}
```
上面的代码，关注`JuiceComponent`类，这个类本身依赖关系图从`JuiceModule`中获得，而`JuiceModule`类只是声明了`JuiceType`为`appleJuice`的`Juice`类通过创建`AppleJuice`获得。而观察`AppleJuice`类需要一个`FruitType`为`apple`的`Fruit`类作为依赖。这个`Fruit`类的依赖并不能从`JuiceComponent`中获得，因此我们指定拥有这个`Fruit`类依赖的`dependencies = {FruitComponent.class}`。在`FruitComponent`类中需要显示声明其可以提供`FruitType`为`apple`的`Fruit`类如下：
```java
@FruitType("apple")
Fruit getApple();
```
因此通过指定`dependencies = {FruitComponent.class}`构成了完整的依赖关系链，我们可以如下构建一个`JuiceShop`:
```java
public static void main(String[] args) {
    JuiceShop juiceShop = DaggerJuiceComponent
            .builder()
            .fruitComponent(DaggerFruitComponent.create())
            .build()
            .inject();
    System.out.println(juiceShop.getJuice());
}
```
Dagger会给我们生成`DaggerJuiceComponent`，并通过`fruitComponent()`方法，放入`DaggerFruitComponent`的依赖。我们来看看Dagger生成的`DaggerJuiceComponent`具体是如何使用`DaggerFruitComponent`来生成依赖的：
```java
public final class DaggerJuiceComponent implements JuiceComponent {
    private com_shen_example_di_FruitComponent_getApple getAppleProvider;
    
    private DaggerJuiceComponent(Builder builder) {
        initialize(builder);
    }
    
    private void initialize(final Builder builder) {
        // 保存fruitComponent到com_shen_example_di_FruitComponent_getApple内部类中
        this.getAppleProvider = new com_shen_example_di_FruitComponent_getApple(builder.fruitComponent);
        // 将保存有fruitComponent的内部类传递给AppleJuice构造工厂
        this.appleJuiceProvider = AppleJuice_Factory.create(getAppleProvider);
    }
    
    private static class com_shen_example_di_FruitComponent_getApple implements Provider<Fruit> {
        private final FruitComponent fruitComponent;

        com_shen_example_di_FruitComponent_getApple(FruitComponent fruitComponent) {
        this.fruitComponent = fruitComponent;
        }

        // 通过fruitComponent创建apple
        @Override
        public Fruit get() {
        return Preconditions.checkNotNull(
            fruitComponent.getApple(), "Cannot return null from a non-@Nullable component method");
        }
    }
    
    public static final class Builder {
        private FruitComponent fruitComponent;

        public JuiceComponent build() {
            return new DaggerJuiceComponent(this);
        }

        public Builder fruitComponent(FruitComponent fruitComponent) {
            this.fruitComponent = Preconditions.checkNotNull(fruitComponent);
            return this;
        }
  }

}

public final class AppleJuice_Factory implements Factory<AppleJuice> {
  private final Provider<Fruit> appleProvider;

  public AppleJuice_Factory(Provider<Fruit> appleProvider) {
    this.appleProvider = appleProvider;
  }

  @Override
  public AppleJuice get() {
    return provideInstance(appleProvider);
  }

  public static AppleJuice provideInstance(Provider<Fruit> appleProvider) {
    // 最终通过调用保存有fruitComponent的get方法，
    // 通过fruitComponent创建apple，并传入给AppleJuice构造函数中
    return new AppleJuice(appleProvider.get());
  }

  public static AppleJuice_Factory create(Provider<Fruit> appleProvider) {
    return new AppleJuice_Factory(appleProvider);
  }

}
```
通过上述Dagger生成的代码可以看出，通过dependencies方式指定Component依赖，Dagger会将依赖的Component通过组合方式传入给目标的Component，并在目标Component需要创建依赖时，通过组合传入的依赖Component进行依赖类的构建。再次强调，如果没有在依赖Component中声明其对外暴露的依赖，会出现报错。例如假设我们将上面的`FruitComponent`去掉`getApple`方法：
```java
@Singleton
@Component(modules = {FruitModule.class})
public interface FruitComponent {
    FruitShop inject();
}
```
那么在编译时会出现报错：
```
Error:(8, 8) java: [Dagger/MissingBinding] @com.shen.example.di.FruitType("apple") com.shen.example.fruit.Fruit cannot be provided without an @Provides-annotated method.
      @com.shen.example.di.FruitType("apple") com.shen.example.fruit.Fruit is injected at
          com.shen.example.juice.AppleJuice(apple)
      com.shen.example.juice.AppleJuice is injected at
          com.shen.example.di.JuiceModule.bindAppleJuice(appleJuice)
      @com.shen.example.di.JuiceType("appleJuice") com.shen.example.juice.Juice is injected at
          com.shen.example.JuiceShop.appleJuice
      com.shen.example.JuiceShop is provided at
          com.shen.example.di.JuiceComponent.inject()
```

### -@SubComponent
`@SubComponent`声明的接口或者抽象类，表示其本身的依赖关系图是不完整的，必须通过依附于外部的Component才能获得完整的依赖关系。使用`@SubComponent`有两种方式，第一种是通过在被依赖的Component中声明返回SubComponent类型的方法，并使用SubComponent中声明的需要传入参数的Module作为参数。第二种是在Component声明的Module中，通过Module.subcomponents指定这个Module可以为哪些SubComponent提供依赖来源。  
我们先看第一种方法，对比使用dependencies方式，只需要改变以下两个类：
```java
@Singleton
@Component(modules = {FruitModule.class})
public interface FruitComponent {
    FruitShop inject();
    // 通过在被依赖的Component中声明返回SubComponent类型的方法，
    // 并使用SubComponent中声明的需要传入参数的Module作为参数。
    // 由于JuiceComponent没有指定有参的Module，因此这里方法的参数可以为空
    JuiceComponent juiceComponent();
}

// 将JuiceComponent标注为Subcomponent，去掉dependencies指定
@OtherScop
@Subcomponent(modules = {JuiceModule.class})
public interface JuiceComponent {
    JuiceShop inject();
}
```
我们可以如下构建一个`JuiceShop`:
```java
public static void main(String[] args) {
    JuiceShop juiceShop = DaggerFruitComponent
                .builder()
                .build().juiceComponent()
                .inject();
    System.out.println(juiceShop.getJuice());
}
```
我们来看生成的`DaggerFruitComponent`
```java
public final class DaggerFruitComponent implements FruitComponent {
    // 通过FruitComponent中转至JuiceComponent
    @Override
    public JuiceComponent juiceComponent() {
        return new JuiceComponentImpl();
    }
    
    private final class JuiceComponentImpl implements JuiceComponent {
        private AppleJuice_Factory appleJuiceProvider;
        private Provider<Juice> bindAppleJuiceProvider;

        private JuiceComponentImpl() {
            initialize();
        }

        @SuppressWarnings("unchecked")
        private void initialize() {
            this.appleJuiceProvider = AppleJuice_Factory.create((Provider) Apple_Factory.create());
            this.bindAppleJuiceProvider = DoubleCheck.provider((Provider) appleJuiceProvider);
        }

        // 最终会通过中转得到的JuiceComponent，调用inject方法得到目标对象
        @Override
        public JuiceShop inject() {
            return injectJuiceShop(JuiceShop_Factory.newJuiceShop());
        }

        @CanIgnoreReturnValue
        private JuiceShop injectJuiceShop(JuiceShop instance) {
            JuiceShop_MembersInjector.injectAppleJuice(instance, bindAppleJuiceProvider.get());
            return instance;
        }
    }
}
```
可以看出，当使用@SubModule时，`JuiceComponent`被声明为`FruitComponent`的内部类，通过内部中转至`JuiceComponent`从而构造出目标对象。  
第二种使用@Module.subcomponents，相比第一种SubComponent方法而言，不需要在在被依赖的Component中声明返回SubComponent类型的方法，只需要在被依赖的Component对应的Module中声明subcomponent既可。同时对SubComponent要求有@Subcomponent.Builder。  
我们看FruitComponent不在需要声明返回JuiceComponent的方法
```java
@Singleton
@Component(modules = {FruitModule.class})
public interface FruitComponent {
    FruitShop inject();
    // 不需要额外声明SubComponent
    //JuiceComponent juiceComponent();
}

@OtherScop
@Subcomponent(modules = {JuiceModule.class})
public interface JuiceComponent {
    JuiceShop inject();

    // 需要添加SubComponent.Builder
    @Subcomponent.Builder
    interface Builder {
        JuiceComponent build();
    }
}
```
同时对于JuiceComponent需要依赖的module添加subComponent依赖
```java
// 对Module加入subcomponents = {JuiceComponent.class}
@Module(subcomponents = {JuiceComponent.class})
abstract public  class FruitModule {

    @Binds @FruitType("apple")
    abstract Fruit bindApple(Apple apple);

    @Binds @FruitType("orange")
    abstract Fruit bindOrange(Orange orange);

}
```
这个时候可以在被依赖的Component生成产物的FruitShop中构造出JuiceShop
```java
public class FruitShop {
    // 这里可以直接使用JuiceComponent.Builder，Provider的作用后面再说
    @Inject
    public Provider<JuiceComponent.Builder> juiceComponentProvider;

    @Inject
    public FruitShop() {}
    
    public String juice() {
        // 通过声明需要注入一个JuiceComponent，从而获得JuiceShop
        JuiceShop juiceShop = juiceComponentProvider.get().build().inject();
        return juiceShop.getJuice();
    }

}
```
从生成的DaggerFruitComponent来看
```java
public final class DaggerFruitComponent implements FruitComponent {
  private Provider<JuiceComponent.Builder> juiceComponentBuilderProvider;
  
  // 初始化juiceComponentBuilderProvider
  private void initialize(final Builder builder) {
    this.juiceComponentBuilderProvider =
        new Provider<JuiceComponent.Builder>() {
          @Override
          public JuiceComponent.Builder get() {
            return new JuiceComponentBuilder();
          }
        };
  }
  
  // 将juiceComponentBuilderProvider注入到FruitShop中
  private FruitShop injectFruitShop(FruitShop instance) {
    FruitShop_MembersInjector.injectJuiceComponentProvider(instance, juiceComponentBuilderProvider);
    return instance;
  }
  
  private final class JuiceComponentBuilder implements JuiceComponent.Builder {
    // 通过JuiceComponent.Builder生成JuiceComponentImpl，这就是为什么通过@Module.subcomponents一定要声明Builder的原因。
    @Override
    public JuiceComponent build() {
      return new JuiceComponentImpl(this);
    }
  }
  
  // JuiceComponentImpl与第一种的SubComponent方法内容类似，省略
  private final class JuiceComponentImpl implements JuiceComponent {
    // ……
  }
}
```

### -指定dependencies与SubComponent区别

- dependencies可以同时指定多个，而采用SubComponent只能有一个parent Component
- dependencies指定的Component与本身的Component是属于组合关系，他们各自独立，可以单独使用。而SubComponent必须依赖于某个Component，Dagger不会对SubComponent生成DaggerXXXSubComponent类，而是在DaggerXXXComponent中定义了SubComponentImpl的内部类。
- 调用生成对象的时候依赖方向不同。使用dependencies方式，需要外部依赖的Componet和被依赖的Componet之间相互独立，会生成两个DaggerXXXComponet，并且是通过需要依赖的Componet发起，通过引入外部的Component来构建出最终的对象；而通过`@SubComponent`方式则是只生成一个DaggerXXXComponent，由被依赖的Component发起，通过中转至需要其依赖的内部Component或者从依赖的Component生成对象内部来构建出最终对象。见如下代码：
```java
// dependencies方式
JuiceShop juiceShop = DaggerJuiceComponent
                .builder()
                .fruitComponent(DaggerFruitComponent.create())
                .build()
                .inject();

// @SubComponent第一种方式
JuiceShop juiceShop = DaggerFruitComponent
        .builder()
        .build().juiceComponent()
        .inject();
        
// @SubComponent第二种方式
public class FruitShop {
    @Inject
    public Provider<JuiceComponent.Builder> juiceComponentProvider;

    @Inject
    public FruitShop() {}
    
    public void createJuiceShop() {
        JuiceShop juiceShop = juiceComponentProvider.get().build().inject();
    }
}
```
&ensp;&ensp;使用SubComponent的有两个好处，第一个是可以对不同的component声明不同的生命周期，规范对象存活的周期。第二个是为了更好的封装，将相同的依赖放置到同一个component并依赖于它，而将不同的依赖封装到不同的模块。  
&ensp;&ensp;对于Component的依赖关系介绍到这里。在平常的使用中，如果module之间依赖较多的话，不建议采用@SubComponent第一种方式，因为这种方式每增加一个submodule都要在被依赖的component中声明。如果被依赖的component比较稳定，建议使用dependencies方式，这样新增加一个依赖的component不用修改被依赖的component。而@SubComponent第二种方式仅适用于依赖的component是作为被依赖component的一个附属情况下使用，因为subcomponent无法脱离被依赖component的构建产物使用。不过第二种@SubComponent方式相对第一种方式而言，会让Dagger知道SubComponent是否被使用，从而减少生成没有被使用的SubComponent的代码。

## Lazy<> & Provider<>  
依赖注入有三种模式，一种是最常见的直接注入（Direct Injection），还有就是懒注入（Lazy Injection）和提供者注入（Provider Injection）。直接注入模式下，被注入的对象会先生成，然后当有需要被注入的地方时，将预先生成的对象赋值到需要的地方。Lazy注入只有当get的时候才会创建对象，且生成之后对象会被缓存下来。Provider注入在每次get都会创建新的对象。  
用官方的一个例子来说明。
```java
@Module
public class CounterModule {
    private int next = 100;

    @Provides
    Integer provideInteger() {
        System.out.println("computing...");
        return next++;
    }
}
```
`CounterModule`可以提供一个整形变量，每次提供完之后会对这个变量加一。
```java
/**
 * 直接注入
 */
public class DirectCounter {
    @Inject
    Integer value;

    void print() {
        System.out.println("direct counter printing...");
        System.out.println(value);
        System.out.println(value);
        System.out.println(value);
    }
}

/**
 * Provider注入
 */
public class ProviderCounter {
    @Inject
    Provider<Integer> provider;

    void print() {
        System.out.println("provider counter printing...");
        System.out.println(provider.get());
        System.out.println(provider.get());
        System.out.println(provider.get());
    }
}

/**
 * Lazy注入
 */
public class LazyCounter {
    @Inject
    Lazy<Integer> lazy;

    void print() {
        System.out.println("lazy counter printing...");
        System.out.println(lazy.get());
        System.out.println(lazy.get());
        System.out.println(lazy.get());
    }
}

/**
 * 多个Lazy注入，lazy与单例
 */
public class LazyCounters {
    @Inject
    LazyCounter counter1;
    @Inject
    LazyCounter counter2;

    void print() {
        System.out.println("lazy counters printing...");
        counter1.print();
        counter2.print();
    }
}
```
我们将这几种的Counter集合到一起并输入
```java
public class Counter {
    @Inject
    DirectCounter mDirectCounter;

    @Inject
    ProviderCounter mProviderCounter;

    @Inject
    LazyCounter mLazyCounter;

    @Inject
    LazyCounters mLazyCounters;

    public void print() {
        mDirectCounter.print();
        mProviderCounter.print();
        mLazyCounter.print();
        mLazyCounters.print();
    }
}
```
得到以下的输入结果：
```
// 直接注入
computing...
direct counter printing...
100
100
100
// Provider注入
provider counter printing...
computing...
101
computing...
102
computing...
103
// Lazy注入
lazy counter printing...
computing...
104
104
104
// 多个Lazy注入
lazy counters printing...
lazy counter printing...
computing...
105
105
105
lazy counter printing...
computing...
106
106
106
```
从结果可以看出，直接注入会先计算一次得到需要被注入的依赖对象（这里是整型100），并在需要的地方都返回这个预先计算好的对象，因此都返回100。  
Provider注入则会在每次get方法调用的地方都通过Module中的provider方法计算得到需要被注入的依赖对象，因此依次返回新计算的对象101、102、103。  
Lazy注入与直接注入相似，只会计算一次需要被注入的依赖对象，但是与直接注入不同的是，Lazy注入只有在被调用get方法的时候才会进行计算，因此可以看到`lazy counter printing...`先打印，然后才是`computing...`。  
需要注意的是Lazy注入并不等同于单例模式，不同的`LazyCounter`的get方法会获取到不同的对象。例如`LazyCounters`中通过两个`LazyCounter`的get方法分别获取到的是105和106，并且`lazy counter printing...`和`computing...`都打印了两次。
 
## @BindsInstance
当构建Component的时候，如果需要外部传入参数，我们有两种方法，一种是通过构建Module时通过Module的构造函数传入参数，第二种是通过`@BindsInstance`方式，在构建Component的时候通过Component.Builder来构建Component。我们先看第一种方法：
```java
// Pear对象需要一个String类型的名称
public class Pear implements Fruit {

    String customName;

    public Pear(String name) {
        customName = name;
    }

    @Override
    public String name() {
        if (customName != null && customName.length() > 0) {
            return customName;
        } else {
            return "pear";
        }
    }
}

// ProjectModule的构造函数接收一个String类型的参数，并最终用于构造Pear对象
@Module
public class ProjectModule {

    String name;

    public ProjectModule(String name) {
        this.name = name;
    }

    @Provides @Name
    public String provideName() {
        return name;
    }

    @Provides @FruitType("pear")
    public Fruit providerPear(@Nullable @Name String name) {
        return new Pear(name);
    }
}

// Component不需要特别的处理
@Singleton
@Component(modules = {ProjectModule.class})
public interface FruitComponent {
    FruitShop inject();
}

public class FruitShop {

    @Inject @FruitType("pear")
    Fruit pear;

    // 打印出Pear的名字
    public String createFruit() {
        return pear.get().name();
    }

}

public class Main {
    public static void main(String[] args) {
        // 通过projectModule构造传递参数
        FruitShop fruitShop = DaggerFruitComponent
                .builder()
                .projectModule(new ProjectModule("cus_Pear"))
                .build()
                .inject();
        System.out.println(fruitShop.createFruit());
    }
}
```
上面代码中，通过`ProjectModule`的构建函数传入了一个String对象参数，并最后用于构造`Pear`对象，最终会打印`cus_Pear`。对于这种在依赖关系图中需要外部传入参数的情况，可以使用`@BindInstance`来进行优化。优化之后的代码如下：
```java
// ProjectModule中不需要另外声明构造函数
@Module
public class ProjectModule {

    @Provides @FruitType("pear")
    public Fruit providerPear(@Name String name) {
        return new Pear(name);
    }
}

@Component(modules = {ProjectModule.class})
public interface FruitComponent {
    FruitShop inject();

    // 通过Component.Builder并使用BindsInstance提供依赖需要参数
    @Component.Builder
    interface Builder {
        @BindsInstance
        Builder cusPearName(@Name String name);
        FruitComponent build();
    }
}

public class Main {
    public static void main(String[] args) {
        // 使用builder中的cusPearName方法传入参数
        FruitShop fruitShop = DaggerFruitComponent
                .builder()
                .cusPearName("cus_Pear")
                .build()
                .inject();
        System.out.println(fruitShop.createFruit());
    }
}
```
与第一种方法不同，这种方法并不需要使用Module的带参数构造方法来传递依赖所需的参数，而是通过Component构造时候在build的过程中通过`cusPearName`方法传入依赖对象，逻辑更加清晰，并且减少了Module的复杂度。  
使用`@BindInstance`注解的方法，如果参数没有标记为`@Nullable`则这个方法必须要调用，否则会报`java.lang.IllegalStateException: java.lang.String must be set`。传入参数必须为非null，否则会报`java.lang.NullPointerException at dagger.internal.Preconditions.checkNotNull(Preconditions.java:33)`。如果这个参数是可选，则必须声明为nullable，如下：
```java
@Module
public class ProjectModule {

    @Provides @FruitType("pear")
    public Fruit providerPear(@Nullable @Name String name) {
        return new Pear(name);
    }
}

@Component(modules = {ProjectModule.class})
public interface FruitComponent {
    FruitShop inject();

    @Component.Builder
    interface Builder {
        @BindsInstance
        Builder cusPearName(@Nullable @Name String name);
        FruitComponent build();
    }
}
```
在实际项目中，应该尽量使用`@BindInstance`，而不是带参数构造函数的module。 
## @BindsOptionalOf  
## @MapKey  
## @Multibinds
## @IntoMap  @IntoSet  @ElementsIntoSet
## @StringKey @IntKey @LongKey @ClassKey  




# Dagger2的缺点
* 修改完相关依赖之后必须Rebuild才能生效
* 代码检索变得相对困难，对于接口或者抽象类没办法直观看到具体生成的是哪个对象
Kodein  
* 编写Dagger代码时需要关注比较多的规则约束，且不太容易记忆（例如Component中的方法要求，以及Builder里的方法要求等）

# 最后
Dagger2是非常棒的依赖注入器，但是Dagger2使用存在上述的一些缺点，所以建议仅在如架构关系之类的关键且依赖关系相对不经常修改的地方使用，不建议在项目中大范围使用。

# 例子代码下载：
本文的代码可以在github中下载：https://github.com/shenguojun/DaggerExample