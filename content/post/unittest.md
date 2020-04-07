---
title: "单元测试之JUnit4"
date: 2019-05-09T12:57:47+08:00
author: 申国骏
tags: ["android"]
---

# [JUnit4](https://junit.org/junit4/)

JUnit是一个帮助编写和执行单元测试的框架。可能很多人都接触过单元测试，但是只是停留在copy别人的测试代码再改一下的状态，下文尝试较为体系列举JUnit4中比较关键的一些知识点。转载请注明来源[「Bug总柴」](https://www.jianshu.com/u/b692bbf77991) 

## Assertions断言
判断结果是否满足预期，Junit有以下几种断言方法：`assertArrayEquals`、`assertEquals`、`assertFalse`、`assertNotNull`、`assertNotSame`、`assertNull`、`assertSame`、`assertTrue`、`assertThat`。

### [Hamcrest Mathers](http://hamcrest.org/JavaHamcrest/tutorial)

Hamcrest扩展JUnit`assertThat`的Matcher类型，支持以下matchers:

支持类型 | 常用matchers
---|---
Core | anything、describedAs、is
Logical | allOf、anyOf、not、both、either
Object | equalTo、hasToString、instanceOf、isCompatibleType、notNullValue、nullValue、sameInstance、theInstance
Beans | hasProperty
Collections | array、hasEntry、hasKey、hasValue、hasItem、hasItems、hasItemInArray、everyItem
Number | closeTo、greaterThan、greaterThanOrEqualTo、lessThan、lessThanOrEqualTo
Text | equalToIgnoringCase、equalToIgnoringWhiteSpace、containsString、endsWith、startsWith

使用`assertThat`具有更好的可读性和出错信息，建议大多数情况下使用`assertTaht`来进行断言判断。

## Runner执行器
Runner执行器用于组织和执行在一个类中的测试，可以在执行器中做一些必须的前置和后置工作。使用`@RunWith`注解可以指定测试的执行类。如果没有使用`@RunWith`指定测试执行器，默认会使用`BlockJunit4ClassRunner`。每个测试类只能指定一个Runner。除了默认的Runner还有以下的Runner：

Runner名称| 作用 | 备注
---|---|---
Suite | 将分布在多个类中的测试组合在一起作为一个测试执行 | JUnit自带 [文档](https://github.com/junit-team/junit4/wiki/Aggregating-tests-in-suites)
Categories | 执行多个类具有某些类别标志的一组测试 | JUnit自带 [文档](https://github.com/junit-team/junit4/wiki/Categories)
Parameterized | 使用同一种类型的多个数据重复执行同一个测试类的所有测试 | JUnit自带 [文档](https://github.com/junit-team/junit4/wiki/Parameterized-tests)
Theories | 使用多种类型的数据的排列组合执行同一个测试类的所有测试 | JUnit自带 [文档](https://github.com/junit-team/junit4/wiki/Theories)
[SpringJUnit4ClassRunner](https://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/test/context/junit4/SpringJUnit4ClassRunner.html) | 提供Spring上下文支持的测试执行类 | 继承自BlockJUnit4ClassRunner
MockitoJUnitRunner | 最终会构造`DefaultInternalRunner`，根据mockito的注解在测试之前生成mock对象| 详见[mockito介绍](https://dzone.com/refcardz/mockito?chapter=1)
PowerMockRunner | 最终通过`PowerMockJUnit44RunnerDelegateImpl.executeTest()`方法，将被`@PrepareForTest`、`@PrepareOnlyThisForTest`、`@SuppressStaticInitializationFor`标注的类使用`MockClassLoader`进行加载，实现对静态以及final对象的mock| 详见[powermock文档](https://github.com/powermock/powermock/wiki/Getting-Started)
AndroidJUnit4 | 会根据是否在Android设备执行，选择`AndroidJUnit4ClassRunner`或者`RobolectricTestRunner`（AndroidX版本）。在Android中执行测试时，可以获得运行的Instrumentation和Bundle参数，以及可以使用`@UiThreadTest`标记测试方法在UI线程执行| 原理可以参阅[这篇文章](https://www.jianshu.com/p/e28868ab4882)
RobolectricTestRunner |直接在安卓真机或者模拟器运行测试通常会比较慢，RobolectricTestRunner继承自SandboxTestRunner，以提供在JVM中的Android运行时环境| 详见[Robolectric官网](http://robolectric.org/)
[其他](https://github.com/junit-team/junit4/wiki/Custom-runners) |其他的Runner可以看[这里](https://github.com/junit-team/junit4/wiki/Custom-runners)||

## [Rule规则](https://github.com/junit-team/junit4/wiki/Rules)
使用Rule可以对一个或者一组测试的方法进行修改，可以向测试方法中添加额外逻辑来决定测试是否通过，也可以代替`@Before`、`@After`、`@BeforeClass`、`@AfterClass`来实现初始化和清理工作。换句话而言，Rule相当于是相对测试方法独立的作用于测试方法中的额外处理逻辑。多个Rule可以顺序叠加。如果一个规则标注为`@Rule`则对测试类的每个方法生效，如果一个规则标注为`@ClassRule`则只会在整个测试类的所有方法开始之前和结束只会生效一次。以下常见的Rules如下：

Rules名称 | 作用 | 备注
---|---|---
ErrorCollector | 使用`ErrorCollector.checkThat()`方法可以在执行完整个测试方法之后再报错，不会因为测试方法中的某一个错误而提前终止测试 | JUnit自带 [文档](https://junit.org/junit4/javadoc/4.12/org/junit/rules/ErrorCollector.html) 
ExpectedException | 使用`ExpectedException.expect()`方法指定测试方法需要抛出的异常，当测试方法没有抛出异常或者抛弃不符合预期的异常时判定测试失败 | JUnit自带 [文档](https://junit.org/junit4/javadoc/4.12/org/junit/rules/ExpectedException.html)
ExternalResource| 类似于`@Before`和`@After`的效果，只是用了Rule来实现，可以声明发生在测试之前和测试之后的行为|JUnit自带[文档](https://junit.org/junit4/javadoc/4.12/org/junit/rules/ExternalResource.html)
TemporaryFolder|在测试方法之前创建一个存放测试临时文件的目录，在测试结束后会自动删除|JUnit自带 [文档](https://junit.org/junit4/javadoc/4.12/org/junit/rules/TemporaryFolder.html)
TestWatcher| 可以用来监测测试方法执行的生命周期，包括开始、成功、错误、结束等|JUnit自带 [文档](https://junit.org/junit4/javadoc/4.12/org/junit/rules/TestWatcher.html)
TestName| 继承自`TestWatcher`，用来获取每个测试方法的名字|JUnit自带 [文档](https://junit.org/junit4/javadoc/4.12/org/junit/rules/TestName.html)
Timeout|将测试类中的每个测试方法都是用独立的线程执行，并等待一段时间。若等待时间内没有结果返回则报错。如果设置等待时间为0，则表示没有超时只是在线程中执行。|JUnit自带 [文档](https://junit.org/junit4/javadoc/4.12/org/junit/rules/Timeout.html)
RuleChain|将多个Rule按照指定的顺序作用于测试方法中|JUnit自带 [文档](https://junit.org/junit4/javadoc/4.12/org/junit/rules/RuleChain.html)
Verifier|ErrorCollector的基类，抽象类，表示可以在运行完测试方法后做一些验证操作|JUnit自带 [文档](https://junit.org/junit4/javadoc/4.12/org/junit/rules/Verifier.html)
MockitoRule| 是一个扩展MethodRule的接口，通过`JUnitRule`实现，会在执行测试方法之前，初始化所有mock对象。这个rule的作用与`MockitoJUnitRunner`类似|[文档](https://static.javadoc.io/org.mockito/mockito-core/2.19.0/org/mockito/junit/MockitoJUnit.html)
PowerMockRule|最终通过`PowerMockAgentTestInitializer.initialize()`方法将被@PrepareForTest、@PrepareOnlyThisForTest、@SuppressStaticInitializationFor标注的类使用MockClassLoader进行加载，实现对静态以及final对象的mock，作用与`PowerMockRunner`类似|[文档](https://github.com/powermock/powermock/wiki/powermockrule)
ProviderTestRule|在测试方法之前对ContentProvider进行初始化，可以执行相应的数据库操作。|[文档](https://developer.android.com/reference/android/support/test/rule/provider/ProviderTestRule)
ServiceTestRule|调用`ServiceTestRule.startService()`或者`ServiceTestRule.bindService()`在测试方法中建立Service连接，在测试结束后会自动关闭Service。不适用于IntentService，可以对其他Service进行测试。|[文档](https://developer.android.com/reference/android/support/test/rule/ServiceTestRule)
ActivityTestRule| 可以自动在测试方法和`@Before`之前启动Activity，并在测试方法结束和`@After`之后结束Activity。也可以手动调用`ActivityTestRule.launchActivity()`和`ActivityTestRule.finishActivity()`|[文档](https://developer.android.com/reference/android/support/test/rule/ActivityTestRule)
GrantPermissionRule|帮助在Android API 23及以上的环境申请运行时权限。申请权限时可以避免用户交互弹窗占用UI测试焦点。最终会调用`PermissionRequester.requestPermissions()`方法，通过执行`UiAutomationShellCommand`直接在shell中为当前target申请权限|[文档](https://developer.android.com/reference/android/support/test/rule/GrantPermissionRule)
ActivityScenarioRule|作为`ActivityTestRule`的替代，在测试方法之前启动一个activity，并在测试方法之后结束activity。同时可以在测试方法中获得`ActivityScenario`|[ActivityScenarioRule文档](https://developer.android.com/reference/androidx/test/ext/junit/rules/ActivityScenarioRule) / [ActivityScenario文档](https://developer.android.com/reference/androidx/test/core/app/ActivityScenario)
InstantTaskExecutorRule|用于Architecture Components的测试，可以将默认使用的后台executor转为同步执行，让测试可以马上获得结果|[文档](https://developer.android.com/reference/android/arch/core/executor/testing/InstantTaskExecutorRule)
CountingTaskExecutorRule|可以使用`CountingTaskExecutorRule.drainTasks()`方法手动等待所有Architecture Components的后台任务执行完毕|[文档](https://developer.android.com/reference/android/arch/core/executor/testing/CountingTaskExecutorRule)
IntentsTestRule|在测试之前会初始化Espresso的Intent，可以使用Espresso `Intents.intended()`方法校验activity操作触发的intent|[espresso intent](https://developer.android.com/training/testing/espresso/intents#kotlin)


## 测试默认执行流程源码分析

整个测试的执行过程是对`Statement`根据`@BeforeClass`、`@AfterClass`、`@Before`、`@After`、Rules的按照[装饰者模式](https://zh.wikipedia.org/wiki/%E4%BF%AE%E9%A5%B0%E6%A8%A1%E5%BC%8F)进行的层层包装。最后会根据这些包装的规则一步一步执行测试。

```java
// BlockJUnit4ClassRunner会继承ParentRunner
public abstract class ParentRunner<T> extends Runner implements Filterable, Sortable {

    // 执行测试
    @Override
    public void run(final RunNotifier notifier) {
        EachTestNotifier testNotifier = new EachTestNotifier(notifier,
                getDescription());
        try {
            Statement statement = classBlock(notifier);
            statement.evaluate();
        } catch (AssumptionViolatedException e) {
            testNotifier.addFailedAssumption(e);
        } catch (StoppedByUserException e) {
            throw e;
        } catch (Throwable e) {
            testNotifier.addFailure(e);
        }
    }
    
    // 在执行类中测试的前后加上BeforeClass和AfterClass逻辑
    protected Statement classBlock(final RunNotifier notifier) {
        // 执行测试类中的测试方法
        Statement statement = childrenInvoker(notifier);
        if (!areAllChildrenIgnored()) {
            // 这里会对类中的测试加上Before和After的逻辑
            statement = withBeforeClasses(statement);
            statement = withAfterClasses(statement);
            statement = withClassRules(statement);
        }
        return statement;
    }
    
    protected Statement childrenInvoker(final RunNotifier notifier) {
        return new Statement() {
            @Override
            public void evaluate() {
                runChildren(notifier);
            }
        };
    }
    
    private void runChildren(final RunNotifier notifier) {
        final RunnerScheduler currentScheduler = scheduler;
        try {
            for (final T each : getFilteredChildren()) {
                currentScheduler.schedule(new Runnable() {
                    public void run() {
                        // 最终先执行runChild
                        ParentRunner.this.runChild(each, notifier);
                    }
                });
            }
        } finally {
            currentScheduler.finished();
        }
    }
}
```
```java
// 默认JUnit4 Runner BlockJUnit4ClassRunner对runChild进行处理
public class BlockJUnit4ClassRunner extends ParentRunner<FrameworkMethod> {
    @Override
    protected void runChild(final FrameworkMethod method, RunNotifier notifier) {
        Description description = describeChild(method);
        if (isIgnored(method)) {
            notifier.fireTestIgnored(description);
        } else {
            // 调用methodBlock加入Before/After以及Rules逻辑
            runLeaf(methodBlock(method), description, notifier);
        }
    }
    
    // 最终会调用After/Before以及Rule逻辑
    protected Statement methodBlock(FrameworkMethod method) {
        Object test;
        try {
            test = new ReflectiveCallable() {
                @Override
                protected Object runReflectiveCall() throws Throwable {
                    return createTest();
                }
            }.run();
        } catch (Throwable e) {
            return new Fail(e);
        }

        Statement statement = methodInvoker(method, test);
        // 在测试的前后加上Before/After以及withRules
        statement = possiblyExpectingExceptions(method, test, statement);
        statement = withPotentialTimeout(method, test, statement);
        statement = withBefores(method, test, statement);
        statement = withAfters(method, test, statement);
        statement = withRules(method, test, statement);
        return statement;
    }
}
```
```java
// 对于Rule规则，最终会调用TestRule.apply()方法
public class RunRules extends Statement {
    private final Statement statement;

    public RunRules(Statement base, Iterable<TestRule> rules, Description description) {
        statement = applyAll(base, rules, description);
    }

    @Override
    public void evaluate() throws Throwable {
        statement.evaluate();
    }

    private static Statement applyAll(Statement result, Iterable<TestRule> rules,
            Description description) {
        for (TestRule each : rules) {
            // 顺序加上Rule的逻辑
            result = each.apply(result, description);
        }
        return result;
    }
}
```

## JUnit后记
如果有能代替Runner的Rule，最好使用Rule，因为一个测试类可以指定多个Rule，但是只能声明一个Runner。
