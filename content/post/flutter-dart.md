---
title: "Flutter入门1——Dart语言基础"
date: 2022-09-01T19:43:01+08:00
author: 申国骏
tags: ["flutter"]
---

Dart语言的某些特性可能会让习惯使用Java或者Kotlin的开发者看不懂或者感到疑惑，本文主要介绍Dart语言的一些和Java以及Kotlin不太一样的地方，旨在让Android开发者可以快速掌握Dart语言。

## 1 变量&数据类型

### 1.1 初始化

变量定义可以用 `var value = 18;`或者直接声明类型`int value = 18;`，大部分情况下使用`var`定义变量，仅当不太能通过代码字面意义判断类型时，可以直接声明类型，例如`String people = getPeople(true, 100);`

对于非空类型，如果不能马上进行初始化，可以使用`late`关键字，例如：

```dart
// 这里使用List<String>不是用var是因为保持非空性
// 相当于Kotlin里面的 lateinit var names: List<String>
late List<String> names;
if (iWantFriends())
	names = friends.getNames();
else
	names = haters.getNames();
```

注意非空类型在初始化之前访问会编译出错。

### 1.2 Final

`finale`关键字表示不可修改，可以不声明类型`final name = "Alberto"; `

### 1.3 类型转换

```dart
// 1. If the string is not a number, val is null 
double? val = double.tryParse("12@.3x_"); // null 
double? val = double.tryParse("120.343"); // 120.343
// 2. The onError callback is called when parsing fails 
var a = int.parse("1_6", onError: (value) => 0); // 0 
var a = int.parse("16", onError: (value) => 0); // 16
```

### 1.4 String

```dart
// Very useful for SQL queries, for example
// 这种情况换行以及每行前面的空格不会删除
var query = """
  SELECT name, surname, age
  FROM people
  WHERE age >= 18
  ORDER BY name DESC
  """;


// 这种情况不会有换行
var s = 'I am going to the'
				'second line';
```

### 1.5 空安全

在Dart中可以使用`??`来进行空安全赋值，例如：

```dart
String? status; // This is null 
String isAlive = status ?? "RIP";
```

### 1.6 注释

Dart中可以使用以下三种注释：

```dart
// for signle line comments

/*
 * 
 for multi-line comments
 */

/// for ducumentation comments [b] xxx
void a (int b) {
}
```

## 2 方法函数

### 2.1 具名参数（Named Parameters）

表示调用的时候必须声明参数的名称，参数使用括号`{}`包裹，例如方法：

```dart
void test({int a = 0, required int b}) {
  print("$a");
  print("$b");
}
```

调用的时候需要写明参数名称，`required`表示这个参数必须填写

```dart
void main() {
  test(a: 5, b: 3); // Ok
  test(b: 3); // Ok
  test(a: 5); // Compilation error, 'b' is required
  test(5, 3); // Compilation error, name is required
}
```

### 2.2 位置参数（Positional parameters）

表示调用的时候这些参数是可选的。使用可选参数的时候，不能写参数的名称，非空参数必须有默认值，例如：

```dart
// void test([int a = 0, int b])  Compilation error The parameter 'b' can't have a value of 'null' because of its type, but the implicit default value is 'null'
void test([int a = 0, int? b]) {
  print("$a");
  print("$b");
}
```

调用的时候不能写参数名

```dart
void main() {
  test(a: 5, b: 3); // Compilation error
  test(b: 3); // Compilation error
  test(a: 5); // Compilation error
  test(5, 3); // Ok 
  test();     // Ok
  test(5);    // Ok
}
```

目前暂时不允许方法的参数既有具名参数又有位置参数，例如以下这样会编译出错：

```dart
void test({int a = 0, int b = 0}, [int c = 0, int d?]) {  // compile error
}
```

### 2.3 匿名方法

一行写法：

```dart
final isEven = (int value) => value % 2 == 0;
```

多行写法：

```dart
final anon = (String nickname) {
  var myName = "Alberto";
  myName += nickname;
  return myName;
};
```

### 2.4 扩展方法

与Kotlin扩展方法类似，语法稍微有点不同

```dart
extension FractionExt on String {
  bool isFraction() => ...
    
  // Converts a string into a fraction
  Fraction toFraction() => Fraction.fromString(this);
}

void main() {
  var str = "2/5";
  if (str.isFraction()) {
    final frac = str.toFraction();
  }
}
```

## 3 类

Dart中不允许有类方法重载，方法签名不一样也不行

```dart
class Example { 
  void test(int a) {}
  // Doesn't compile; you have to use different names
  void test(double x, double y) {}
}
```

### 3.1 Cascade 操作符

```dart
class Test {
  String val1 = "One";
  String val2 = "Two";
  int randomNumber() {
    print("Random!");
    return Random().nextInt(10);
  }
}
```

例如如果想多次调用`randomNumber()`可以这用写

```dart
Test()..randomNumber()
  ..randomNumber()
  ..randomNumber();
```

### 3.2 Library引入

Dart里面通过 `import 'package:path/to/file/library.dart';`来引入一个文件，当两个文件的类名有冲突时，可以采取两种方式解决，一种是设置别名，例如：

```dart
// Contains a class called 'MyClass'
import 'package:libraryOne.dart';
// Also contains a class called 'MyClass' 
import 'package:libraryTwo.dart' as second;

void main() {
  // Uses MyClass from libraryOne 
  var one = MyClass();
  //Uses MyClass from libraryTwo. 
  var two = second.MyClass();
}
```

另一种方法是选择展示或隐藏

```dart
//Imports only MyClass and discards all the rest.
import 'package:libraryOne.dart' show MyClass; 
//Import severything except MyClass.
import 'package:libraryTwo.dart' hide MyClass; 
```

Dart for web中还支持library的延迟加载，library只会在需要的时候才会加载进来：

```dart
import 'package:greetings/hello.dart' deferred as hello;

// 使用时：
Future<void> greet() async {
  await hello.loadLibrary();
  hello.printGreeting();
}
```

Flutter也支持动态加载，具体见：https://docs.flutter.dev/perf/deferred-components

### 3.3 可见性

Dart中没有`public`、`private`、`protected`等声明可见性的关键字，只能通过下划线`_`来表示变量或者方法私有（同一个文件里面加了下划线也能访问，私有仅相对于其他文件而言）。为什么这样设计？跟Dart的dynamic类型有关，感兴趣看看：https://github.com/dart-lang/sdk/issues/33383#issuecomment-396168900

```dart
 // === File: test.dart ===
class Test {
  String nickname = "";
  String _realName = "";
}

// === File: main.dart ===
import 'package:test.dart';

void main() {
  final obj = Test();
  
  // OK
  var name = obj.nickname; 
  // ERROR, doesn't compile 
  var real = obj._realName;
}
```

### 3.4 构造函数

因为构造函数的执行在变量初始化之后，因此类里面的变量如果希望通过构造函数来初始化并且希望是非空的话，需要使用`late`来声明：

```dart
class Fraction {
  late int _numerator;
  late int _denominator;
  
  Fraction(int numerator, int denominator) {
    _numerator = numerator;
    _denominator = denominator;\
  }
}
```

为了更好的可读性，还有个语法糖（优先考虑）：

```dart
class Fraction {
  int _numerator;
  int _denominator;
  
  Fraction(this._numerator, this._denominator);
}
```

如果不希望暴露内部的私有变量名称，可以使用Initializer list (优先考虑)，例如：

```dart
class Test {
  int _secret;
  double _superSecret;
  
  Test(int age, double wallet) : 
  	_secret = age,
  	_superSecret = wallet;
}
```

#### 3.4.1 具名构造函数

因为Dart没有方法重载，因此如果希望类有多个构造函数的话，需要使用具名构造函数，例如：

```dart
class Fraction {
  int _numerator;
  int _denominator;
  
  Fraction(this._numerator, this._denominator);
  
  // denominator cannot be 0 because 0/0 is not defined!
  Fraction.zero() :
  	_numerator = 0,
  	_denominator = 1;
}

void main() {
  // "Traditional" initialization
  final fraction1 = Fraction(0, 1);
  // Same thing but with a named constructor
  final fraction2 = Fraction.zero();
}
```

在具名构造函数声明中重定向到默认构造函数或者其他具名函数：

```dart
Fraction(this._numerator, this._denominator); 
// Represents '1/2'
Fraction.oneHalf() : this(1, 2);
// Represents integers, like '3' which is '3/1' 
Fraction.whole(int val) : this(val, 1);
// Ok
Fraction.three() : this.whole(3)
```

#### 3.4.2 工厂模式构造函数

当需要用到单例或者根据不同条件构造子类的时候，可以使用`factory`关键字修饰构造函数。`factory`构造函数与普通构造函数的区别的是需要有return对象，并且可以根据不同的参数返回不同的对象。

```dart
abstract class Animal {
  
  factory Animal(String name) {
    // 根据不同类型生成不同子类，工厂构造函数可以使用return
    if (name == 'dog') return Dog(name);
    if (name == 'cat') return Cat(name);
    throw 'type error';
  }
  
  void talk();
}

class Dog implements Animal {
  String _name;
  // factory不会默认生成单例，需要使用static等手段实现
  static int count = 0;
  
  factory Dog(String name) {
    // 可以调用普通构造函数
    return Dog._default(name);
  }
  
  Dog._default(this._name);
  
  @override
  void talk() {
    count++;
    print('cout: $count,name: $_name');
  }
}

class Cat implements Animal {
  String name;
  // 不使用factory构造函数，同样可以使用static实现cache功能
  static int count = 0;
  
  Cat(this.name);

  @override
  void talk() {
    count++;
    print('cout: $count,name: $name');
  }
}

void main() {
  // 调用的时候与普通构造函数没有区别
  Animal('dog').talk();
  Animal('dog').talk();
  Animal('cat').talk();
  Animal('cat').talk();
}

/*
 * 输出：
cout: 1,name: dog
cout: 2,name: dog
cout: 1,name: cat
cout: 2,name: cat
 */
```

### 3.5 Getters & Setters

```dart
class Fraction {
  int _numerator;
  int _denominator;
  Fraction(this._numerator, this._denominator);
  
  // getters
  int get numerator => _numerator;
  int get denominator => _denominator;
  
  // setter
  set denominator(int value) {
    if (value == 0) {
      // Or better, throw an exception...
      _denominator = 1;
    } else {
      _denominator = value;
    }
  }
}
```

### 3.6 Callable类

 在类里面，如果方法名字是`call()`的话，那么这个类被称为Callable类。Callable类对象可以像方法一样调用：

```dart
// Create this inside 'my_test.dart' for example
class _Test {
  const _Test();
  void call(String something) {
    print(something);
  }
}

const test = _Test();

// Somewhere else, for example in main.dart
import 'package:myapp/my_test.dart';
void main() {
  test("Hello");
}
```

### 3.7 操作符重载

对比两个对象是否相等，正常情况下是对比是否引用了同一个对象，假设我们希望根据类中的某个字段判断对象相等，需要重载`==`号，例如：

```dart
class Example {
  int a;
  Example(this.a);
  
  @override
  bool operator== (Object other) {
    // 1. The function identical() is provided by the Dart code API 
    //    and checks if two objects have the same reference.
    if (identical(this, other))
      return true;

    // 2.
    if (other is Example) {
      final example = other;
      // 3.
      return runtimeType == example.runtimeType &&
        a == example.a;
    } else {
      return false;
    } 
  }
  // 4.
  @override
  int get hashCode => a.hashCode;
}
void main() {
	final ex1 = Example(2); 
  final ex2 = Example(2); 
  print(ex1 == ex2); //true
}
```

当类里面有很多变量的时候，手动实现`operator==`以及`hashCode`比较复杂，我们可以借助于[Equatable](https://pub.dev/packages/equatable)这个库来实现，例如：

```dart
class Test extends Equatable {
  final int a;
  final int b;
  final String c;
  Test(this.a, this.b, this.c);
  
  @override
  List<Object> get props => [a, b, c];
}
```

或者使用`with`来引入`EquatableMixin`：

```dart
 class Test extends SomeClass with EquatableMixin {
   final int a;
   final int b;
   final String c;
   Test(this.a, this.b, this.c);
   
   @override
   List<Object> get props => [a, b, c];
 }
```

## 4. 继承

与Kotlin中类和方法默认都是`final`不同，Dart中方法和类默认都是`virtual`，可以继承和覆盖的。而且Dart中暂时没有办法禁止类被继承。

### 4.1 covariant

当继承父类的时候，默认情况下覆盖父类方法需要使用父类方法一样的参数，在某些特殊情况下，子类覆盖方法如果希望方法参数也使用父类方法参数的子类，可以使用`covariant`关键字，例如：

```dart
abstract class Fruit {}
class Apple extends Fruit {}
class Grape extends Fruit {}
class Banana extends Fruit {}

abstract class Mammal {
  void eat(Fruit f);
}

class Human extends Mammal {
  // Ok
  void eat(Fruit f) => print("Fruit");
}

class Monkey extends Mammal { 
  // Error
  void eat(Banana f) => print("Banana");
  // Ok
  void eat(covariant Banana f) => print("Banana");
}
```

或者直接在父类方法声明：

```dart
abstract class Mammal {
  void eat(covariant Fruit f);
}

class Human extends Mammal {
  // Ok
  void eat(Fruit f) => print("Fruit");
}
class Monkey extends Mammal {
  // Ok
  void eat(Banana f) => print("Banana");
}
```

### 4.2 接口

在 Dart中没有`interface`，创建接口使用`abstract class`，例如：

```dart
abstract class MyInterface {
   void methodOne();
   void methodTwo();
}

class Example implements MyInterface {
  @override
  void methodOne() {}
  @override
  void methodTwo() {}
}
```

一个类可以实现多个接口，不过只能继承一个父类。

Dart中不支持接口有默认实现，如果使用implements，则必须实现所有接口方法，即使在接口中方法有实现，例如：

```dart
abstract class MyInterface {
   void methodOne();
   void methodTwo() {
     print('MyInterface');
   }
}

// Error Missing concrete implementation of 'MyInterface.methodTwo'
class Example implements MyInterface {
  @override
  void methodOne() {
    // Error The method 'methodTwo' is always abstract in the supertype.
    super.methodTwo();
  }
}

void main() {
  Example()..methodOne()
    ..methodTwo();
}
```

如果希望复用部分父类的实现，只能用`extends`。

### 4.3 Mixins

Mixins表示一个没有构造函数的类，这个类的方法可以组合到其他类中实现代码复用，例如：

```dart
mixin Walking {
  void walk() => print("Walking");
}

class Human with Walking {
}

void main() {
  final me = Human();
  // prints "Walking"
  me.walk();
}
```

如果父类通过with复用了Mixins类，则子类继承父类后同样拥有Mixins类，例如：

```dart
mixin Walking {
  void walk() {}
}
mixin Breathing {
  void breath() {}
}
mixin Coding {
  void code() {}
}

// Human only has walk()
class Human with Walking {}

// Developer has walk() inherited from Human and also // breath() and code() from the two mixins
class Developer extends Human with Breathing, Coding {}

```

使用`on`关键字来限制使用Mixins的类只能是某种类型的子类，例如：

```dart
// Constrain 'Coding' so that it can be attached only to
// subtypes of 'Human'
mixin Coding on Human {
  void code() {}
}

// All good
class Human {}
class Developer extends Human with Coding {}

// NO, 'Coding' can be used only on subclasses
class Human with Coding {}

// NO, 'Fish' is not a subclass of 'Human' so 
// you cannot attach the 'Coding' mixin
class Fish with Coding {}
```

Mixins不是一种继承关系，没有层级结构，使用Mixins的类不需要通过super调用Mixins里面的变量和方法。Mixins是一种组合的思想，类似于把一部分通用的变量和方法放到一个公共的区域。

## 5. 异常处理

异常处理与Kotlin类似。捕捉特定异常使用关键字`on`，例如：

```dart
void main() {
  try {
    final f = Fraction(1, 0);
  } on IntegerDivisionByZeroException {
    print("Division by zero!");
  } on FormatException {
    print("Invalid format!");
  } on Exception catch (e) {
    // You arrive here if the thrown exception is neither 
    // IntegerDivisionByZeroException or FormatException 
    print("General exception: $e");
  } catch(e) {
    print("General error: $e");
  } finally {
    print("Always here");
  }
}
```

### 5.1 rethrow

如果希望在try中重新抛出一样的异常，使用`rethrow`关键字，例如：

```dart
try {
	try {
    throw FormatException();
  } on Exception catch (e) {
    print("$e");
    // same as `throw e;`
    rethrow; 
  }
} catch (e2) {
  print("$e2");
}
```

## 6. Collections操作

### 6.1 List 

因为Dart中所有列表都是List对象，因此可以添加元素，也可以使用`...`操作符来添加另一个列表，例如：

```dart
void main() {
  List<int>? list1 = [1, 2, 3];
  list1?.add(4);
  var list3 = [-2, -1, 0, ...?list1]; // All good
  print('$list3');
}
```

列表初始化也可以存在`if`或者`for`表达式，例如：

```dart
const hasCoffee = true;

final jobs = const [
  "Welder",
  "Race driver",
  "Journalist",
  if (hasCoffee) "Developer"
];

final numbers = [
  0, 1, 2,
  for(var i = 3; i < 100; ++i) i
];
```

除了直接定义列表，还有其他列表的构造函数，例如：

```dart
// Now example has this content: [1, 1, 1, 1, 1]
final example = List<int>.filled(5, 1, growable: true); 

var example = List<int>.unmodifiable([1,2,3]);
// same as `var example = const <int>[1, 2, 3];`
example.add(4); // Runtime error

// Now example has this content: [0, 1, 4, 9, 16]
var example = List<int>.generate(5, (int i) => i*i);
```

### 6.2 Set

有几种方式声明`set`变量：

```dart
// 1. Direct type annotation
Set<int> example = {};
// 2. Type inference with diamonds 
final example = <int>{};
// 3. Initialize with objects
final example = {1, 2, 3};
// 4. This is a Map, not a set!!
final example = {};
```

### 6.3 Map

定义一个map

```dart
 final example = <int, String> {
   0: "A",
   1: "B",
 };
```

添加元素：

```dart
// The key '0' is already present, "C" not added
example.putIfAbsent(0, () => "C");
// The key '6' is not present, "C" successfully added 
example.putIfAbsent(6, () => "C");

// "A" has '0' as key and it's replaced with "C". 
// Now the map contains {0: "C", 1: "B"} 
example[0] = "C";
// The key '6' is not present, "C" gets added 
example[6] = "C";
```

### 6.4 Transform方法

```dart
void main() {
	// Generate a list of 20 items using a factory 
  final list = List<int>.generate(20, (i) => i);
  // Return a new list of even numbers
  final List<String> other = list
    .where((int value) => value % 2 == 0) // Intermediate
    .map((int value) => value.toString()) // Intermediate
    .toList(); // Terminal
}
```

**Intermediates**

- `where()`：相当于Kotlin中的filter，用于过滤
- `map()`：1对1转换成另外元素
- `skip()`：跳过前n个元素
- `followedBy()`：拼接元素

**Terminals**

* `toList()/toSet()/toMap()`：聚合元素组成新的Collections

* `every()`：判断是否所有元素都满足某个条件

* `contains()`：是否包含某个元素

* `reduce()`：将所有元素归集到一个元素

* `fold()`：与`reduce()`类似，拥有初始值，且最后归集元素类型可以不一样，例如：

  ```dart
  final list = ['hello', 'Dart', '!'];
  final value = list.fold(0, (int count, String item) => count + item.length);
  print(value); // 10
  ```

## 7. 异步

所有的Dart代码都是运行在isolate中的，每个isolate只有一个线程，isolate之间不会共享内存。

在单个isolate中，如果因为系统I/O、或者等待HTTP请求、或者与浏览器通信、或者等待另一个isolate处理返回、或者等待timer计时触发等，需要等待在非当前isloate处理的事情（这些事情要不就在不同的线程中运行，要不就是由操作系统或者Dart运行时处理，允许与当前的isolate同时执行），可以使用Futrue或者Stream进行异步操作。

一个例子是读取文件的内容：

![Flowchart-like figure showing app code executing from start to exit, waiting for native I/O in between](https://dart.dev/guides/language/concurrency/images/basics-await.png)

如果是进行复杂耗CPU的计算任务，需要在独立的isolate中执行。

### 7.1 Futures

对于耗时I/0等任务，可以使用`Future`类来避免主线程阻塞，例如：

```dart
Future<int> processData(int param1, double param2) {
	// function that takes 4 or 5 seconds to execute...
  final res = httpGetRequest(value);
  return Future<int>.value(res);
}

void main() {
  final process = processData(1, 2.5);
  process.then((data) => print("result = $data"))
    .catchError((e) => print(e.message));
  print("Future is bright");
}

// output:
// Future is bright
// result = 10; // <-- printed after 4 or 5 seconds
```

如果等待多个Futures，可以使用`wait()`方法：

```dart
Future<int> one = exampleOne();
Future<int> two = exampleTwo();
Future<int> three = exampleThree();
Future.wait<int>([
  one,
  two,
  three
]).then(...).catchError(...);
```

Future类的一些具名构造函数：

* `Future<T>.delayed()`：延迟一段时间执行
* `Future<T>.error()`：一般用于结束表示异步方法错误结束
* `Future<T>.value()`：包裹异步方法返回结果

#### 7.1.1 async & await

`async`和`await`是简化Future写法的语法糖，可以解决多个Futture嵌套等待的回调地狱，与Kotlin协程写法有点像，以下两段代码是一样效果：

```dart
void main() {
  final process = processData(1, 2.5);
  process.then((data) => print("result = $data"));
}
```

```dart
void main() async {
  final data = await processData(1, 2.5);
  print("result = $data")
}
```

异步方法也可以使用`async`返回结果，例如以下两段代码等价：

```dart
// Use the named constructor
Future<int> example() => Future<int>.value(3);
```

```dart
// Use async and the compiler wraps the value in a Future
Future<int> example() async => 3;
```

### 7.2 Streams

Stream类型也是表示未来返回的结果，与Future不同的是Stream表示的不是单一个结果，而是一连串的结果。

![image-20220824154717676](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image-20220824154717676.png)

Stream中有几个概念：

* Generator：负责生产数据并通过stream发送
* Stream：生产数据放置的地方，可以通过对Stream进行订阅获取Generator生产的数据
* Subscriber：订阅者，通过订阅监听获取数据

#### 7.2.1 Streams & Generator

```dart
Stream<int> randomNumbers() async* { 						// 1. 
  final random = Random();
  for(var i = 0; i < 100; ++i) { 								// 2. 
    await Future.delayed(Duration(seconds: 1)); // 3.
    yield random.nextInt(50) + 1; 							// 4.
	}
}          																			// 5.
```

1. 返回类型是`Stream<int>`，`async*`表示可以使用`yield`来发送数据
2. 循环产生100个随机数
3. `await`等待Future延迟1秒
4. 使用`yield`来发送数据
5. 如果方法被`async*`修饰的话，方法不能有`return`返回，因为数据是通过`yield`发送的

Stream的产生是on demand的，意味着仅当有观察者订阅之后才会执行Stream的生产逻辑。

Stream类的一些具名构造函数：

* `Stream<T>.periodic()`：不断地间隔产生数据，例如：

  ```dart
  final random = Random();
  final stream = Stream<int>.periodic(
    const Duration(seconds: 2),
    (count) => random.nextInt(10)
  );
  ```

* `Stream<T>.value()`：产生一个简单的事件，例如：

  ```dart
  final stream = Stream<String>.value("Hello");
  ```

* `Stream<T>.error()`：产生一个错误的事件，例如：

  ```dart
  Future<void> something(Stream<int> source) async {
    try {
      await for (final event in source) { ... }
    } on SomeException catch (e) {
      print("An error occurred: $e");
    }
  }
  // Pass the error object
  something(Stream<int>.error("Whoops"));
  ```

* `Stream<T>.fromIterable()`：产生一个从列表发送数据的Stream，例如：

  ```dart
   final stream = Stream<double>.fromIterable(const <double>[
     1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9
  ]);
  ```

* `Stream<T>.fromFuture()`：将Future转换成Stream，包含两个事件，一个是Future的结果，另一个是Stream的结束，例如：

  ```dart
  final stream = Stream<double>.fromFuture(
    Future<double>.value(15.10)
  );
  ```

* `Stream<T>.empty()`：表示发送一个结束的事件

Stream的一些方法：

* `drain(...)`：忽略所有事件，仅在完成或者错误时通知
* `map(...)`：改变事件
* `skip(int count)`：跳过前几个事件

#### 7.2.2 Subscribers

```dart
import 'dart:math';
Stream<int> randomNumbers() async* { 
  final random = Random();
  for(var i = 0; i < 10; ++i) { 								
    await Future.delayed(Duration(seconds: 1)); 
    yield random.nextInt(50) + 1; 							
	}
}
void main() async {									// 1.
  final stream = randomNumbers();		// 2.
  await for (var value in stream) {	// 3.
    print(value);
  }
  // 最后打印
  print("Async stream!");						// 4.
}
```

1. 处理异步Stream需要声明方法为`async`
2. 通过调用`randomNumbers`来订阅Stream，在订阅的时候开始执行数据产生，因为Stream是on-demand的
3. 通过`await for`捕获`yield`发送的数据
4. 在最后打印结果

如果不希望打印"Async stream!"不希望被`await`阻塞，可以使用`listen`来监听Stream结果：

```dart
void main() async {
  final stream = randomNumbers();

  stream.listen((value) {
    print(value);
  });
  // 最先打印
  print("Async stream!");
}
```

如果需要被多个Subscribers订阅的话，可以使用`asBroadcastStream()`方法，详见：https://api.flutter.dev/flutter/dart-async/Stream/asBroadcastStream.html

在Flutter中大部分情况下只需要订阅，不需要写Stream的生产者，因为大部分生产者都是来自于library。

#### 7.2.3 Controller

我们可以使用`StreamController<T>`来更精细地控制和管理Stream，例如下面代码：

```dart
/// Exposes a stream that continuously generates random numbers
class RandomStream {
	/// The maximum random number to be generated final 
  int maxValue;
	static final _random = Random();
  
  Timer? _timer;
  late int _currentCount;
  late StreamController<int> _controller;
  
  /// Handles a stream that continuously generates random numbers. Use 
  /// [maxValue] to set the maximum random value to be generated. 
  RandomStream({this.maxValue = 100}) {
    _currentCount = 0;
    _controller = StreamController<int>(
      onListen: _startStream,
      onResume: _startStream,
      onPause: _stopTimer,
      onCancel: _stopTimer
    ); 
  }
  
	/// A reference to the random number stream
	Stream<int> get stream => _controller.stream; 
  
  void _startStream() {
    _timer = Timer.periodic(const Duration(seconds: 1), _runStream);
    _currentCount = 0;
  }
  
  void _stopTimer() {
    _timer?.cancel();
    _controller.close();
  }
  
  void _runStream(Timer timer) {
    _currentCount++;
    _controller.add(_random.nextInt(maxValue));
    if (_currentCount == maxValue) {
      _stopTimer();
    }
  }
}
```

调用代码：

```dart
void main() async {
  final stream = RandomStream().stream;
  await Future.delayed(const Duration(seconds: 2));
  
  // The timer inside our 'RandomStream' is started
  final subscription = stream.listen((int random) {
    print(random);
  });
  
  await Future.delayed(const Duration(milliseconds: 3200));
  subscription.cancel();
}
```

`StreamController<T>`使用比较复杂，不过比较强大而且扩展性较好，在Dart和Flutter中优先使用`StreamController<T>`对Stream进行处理。

### 7.3 Isolates

与Java等其他语言不同，Dart不支持直接开启多线程来处理后台复杂计算任务，也没有线程安全的例如`AtomicInteger`的类型，也不支持信号量、互斥锁等避免数据竞争和多线程编程问题的手段。

Dart代码都是运行在isolates中，每个isolate中只有一个线程，isolate之间不会共享内存，isolate之间通过message进行通信，因此Dart中不存在数据竞争。

如何在一个线程实现异步处理呢？每个isolate中都包含一个Event loop，异步方法会被切分成多个事件放到Event loop中，从而达到不阻塞的效果。

![A more general figure showing that any isolate runs some code, optionally responds to events, and then exits](https://dart.dev/guides/language/concurrency/images/basics-isolate.png)

例如下面代码：

```dart
void requestAsync() async {
  print("event in async but not future");
  final String result = await getRequest();
  print(result);
}

void main() {
  requestAsync();
  print("event in main");
}

Future<String> getRequest() async {
  return Future<String>.value("")
    .then((value) {
      print("event in future");
      return Future<String>.value("future result");
    });
}

// output:
// event in async but not future
// event in main
// event in future
// future result
```

isolate中的Event loop大致如下：

![isolate_event_loop.drawio](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/isolate_event_loop.drawio.png)

#### 7.3.1 多个isolates

Dart application可以有多个isolate，可以使用`Isolate.spawn()`创建。Isolates有各自的内存空间以及event loop，不同isolate不会共享内存，isolate之间通过message通信。

![image-20220824192820534](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image-20220824192820534.png)

Isolate有`ReceivePort`以及`SendPort`用于接受和发送message，例如：

```dart
void main() async {
  // Read some data.
  final jsonData = await _parseInBackground();

  // Use that data
  print('Number of JSON keys: ${jsonData.length}');
}

// Spawns an isolate and waits for the first message
Future<Map<String, dynamic>> _parseInBackground() async {
  final p = ReceivePort();
  await Isolate.spawn(_readAndParseJson, p.sendPort);
  return await p.first as Map<String, dynamic>;
}

Future<void> _readAndParseJson(SendPort p) async {
  final fileData = await File(filename).readAsString();
  final jsonData = jsonDecode(fileData);
  Isolate.exit(p, jsonData);
}
```

![A figure showing the previous snippets of code running in the main isolate and in the worker isolate](https://dart.dev/guides/language/concurrency/images/isolate-api.png)

通常情况下不会直接调用`Isolate.spawn()`，而是调用`Future<T> compute(...)`，例如：

```dart
 // Model class
class PrimeParams {
  final int limit;
  final double another;
  const PrimeParams(this.limit, this.another);
}

// Use the model as parameter
int sumOfPrimes(PrimeParams data) {
  final limit = data.limit;
  final another = data.another;
  ...
}

// Function to be called in Flutter
Future<int> heavyCalculations() {
  final params = PrimeParams(50000, 10.5);
  return compute<PrimeParams, int>(sumOfPrimes, params);
}
```

## 参考

1. [Flutter Complete Reference](https://fluttercompletereference.com/)
2. [A tour of the Dart language](https://dart.dev/guides/language/language-tour#named-parameters)
3. [Concurrency in Dart](https://dart.dev/guides/language/concurrency)
4. [Asynchronous programming: Streams](https://dart.dev/tutorials/language/streams)
