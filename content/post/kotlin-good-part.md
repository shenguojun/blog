---
title: "Kotlin精髓"
date: 2018-11-07T17:42:32+08:00
author: 申国骏
tags: ["android"]
---
![引言](https://upload-images.jianshu.io/upload_images/2057980-a3f52c9bfe0e692d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
# 前言
从谨慎地在项目中引入kotlin到全部转为kotlin开发我们用了大概半年的时间。这中间经历了从在一个小功能中尝试使用到完全使用kotlin完成了大版本开发的过程。使用方法也从仅仅地用java风格写kotlin代码，慢慢地变成使用kotlin风格去编写代码。  

到目前为止，kotlin的引入至少没有给我们带来不必要的麻烦，在慢慢品尝kotlin语法糖的过程中，我们领略到了能给开发者真正带来好处的一些特性。本文就是对这些我们认为是精髓的一些特性的进行总结，希望能给还在犹豫是否要开始学习kotlin或者刚开始编写kotlin但是不知道该如何利用kotlin的人们先一睹kotlin的优雅风采。

# Kotlin设计哲学
KotlinConf 2018 - Conference Opening Keynote by Andrey Breslav 上讲的Kotlin设计理念：
![2018KotlinConference](https://upload-images.jianshu.io/upload_images/2057980-e00727992fed0bc6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
Kotlin拥有强大的IDE厂商Intellij和Google的支持，保证了其务实、简洁、安全和与JAVA互操作的良好设计理念。  

其中务实表示了Kotlin并没有独创一些当前没有或大众不太熟悉的设计理念，而是吸收了众多其他语言的精髓，并且提供强大的IDE支持，能真正方便开发者运用到实际项目之中。  

简洁主要指的是Kotlin支持隐藏例如getter、setter等Java样板代码，并且有大量的标准库以及灵活的重载和扩展机制，来使代码变得更加直观和简洁。  

安全主要是说空值安全的控制以及类型自动检测，帮助减少NullPointerException以及ClassCastException。  

与Java互操作以为这可以与Java相互调用、混合调试以及同步重构，同时支持Java到kotlin代码的自动转换。

# 空值安全
Kotlin类型分为可空和非可空，赋值null到非可空类型会编译出错
```
fun main() {
    var a: String = "abc"
    a = null // compilation error
    var b: String? = "abc" 
    b = null // ok
}
```
对空的操作有以下这些

![空值运算符](https://upload-images.jianshu.io/upload_images/2057980-bf124e44a0b88136.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



使用安全调用运算符 ```?:``` 可以避免Java中大量的空值判断。以下是一个对比的例子：
```java
// 用Java实现
public void sendMessageToClient(
    @Nullable Client client,
    @Nullable String message,
    @NotNull Mailer mailer
) {
    if (client == null || message == null) return;
    PersonalInfo personalInfo = client.getPersonalInfo();
    if (personalInfo == null) return;
    String email = personalInfo.getEmail();
    if (email == null) return;
    mailer.sendMessage(email, message);
}
```
```
// 用Kotlin实现
fun sendMessageToClient(
    client: Client?, 
    message: String?, 
    mailer: Mailer
){
    val email = client?.personalInfo?.email
    if (email != null && message != null) {
        mailer.sendMessage(email, message)
    }
}
```

# 扩展

## 扩展函数
扩展函数是Kotlin精华特点之一，可以给别人的类添加方法或者属性，使得方法调用更加自然和直观。通过扩展函数的特性，Kotlin内置了大量的辅助扩展方法，非常实用。下面我们通过这个例子看一下
```
fun main() {
    val list = arrayListOf<Int>(1, 5, 3, 7, 9, 0)
    println(list.sortedDescending())
    println(list.joinToString(
        separator = " | ",
        prefix = "(",
        postfix = ")"
    ) {
        val result = it + 1
        result.toString()
    })
}
```
其中```sortedDescending```以及```joinToString```都是Kotlin内置的扩展方法。
上述的函数会输出

![扩展函数实例输出](https://upload-images.jianshu.io/upload_images/2057980-38b2abdc4a64752a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

Kotlin内部的实现如下
```
public fun <T : Comparable<T>> Iterable<T>.sortedDescending(): List<T> {
    return sortedWith(reverseOrder())
}

public fun <T> Iterable<T>.joinToString(separator: CharSequence = ", ", prefix: CharSequence = "", postfix: CharSequence = "", limit: Int = -1, truncated: CharSequence = "...", transform: ((T) -> CharSequence)? = null): String {
    return joinTo(StringBuilder(), separator, prefix, postfix, limit, truncated, transform).toString()
}
```
可见```sortedDescending```和```joinToString```都是对```Iterable<T>```类对象的一个扩展方法。  

我们也可以自己实现一个自定义的扩展函数如下：
```
fun Int.largerThen(other: Int): Boolean {
    return this > other
}

fun main() {
    println(2.largerThen(1))
}
```
上述代码输出为```true```  
通过扩展函数我们以非常直观的方式，将某个类对象的工具类直接使用该类通过```"."```方式调用。  
当然扩展函数是一种静态的实现方式，不会对原来类对象的方法进行覆盖，也不会有正常函数的子类方法覆盖父类方法现象。

## 扩展属性
扩展属性与扩展函数类似，也是可以直接给类对象增加一个属性。例如：
```
var StringBuilder.lastChar: Char
        get() = get(length -1)
        set(value: Char) {
            this.setCharAt(length -1, value)
        }
        
fun main() {
    val sb = StringBuilder("kotlin")
    println(sb.lastChar)
    sb.lastChar = '!'
    println(sb.lastChar)
}
```
无论是扩展函数还是扩展属性，都是对Java代码中utils方法很好的改变，可以避免多处相似功能的util定义以及使得调用更为直观。

# 集合
通过扩展的方式，Kotlin对集合类提供了非常丰富且实用的诸多工具，只有你想不到，没有你做不到。下面我们通过 [Kotlin Koans](https://play.kotlinlang.org/koans/overview) 上的一个例子来说明一下：
```
data class Shop(val name: String, val customers: List<Customer>)

data class Customer(val name: String, val city: City, val orders: List<Order>) {
    override fun toString() = "$name from ${city.name}"
}

data class Order(val products: List<Product>, val isDelivered: Boolean)

data class Product(val name: String, val price: Double) {
    override fun toString() = "'$name' for $price"
}

data class City(val name: String) {
    override fun toString() = name
}
```
以上是数据结构的定义，我们有一个超市，超市有很多顾客，每个顾客有很多笔订单，订单对应着一定数量的产品。下面我们来通过集合的操作来完成以下任务。


操作符 | 作用
---|---
filter | 将集合里的元素过滤，并返回过滤后的元素
map | 将集合里的元素一一对应转换为另一个元素
```
// 返回商店中顾客来自的城市列表
fun Shop.getCitiesCustomersAreFrom(): Set<City> = customers.map { it.city }.toSet()

// 返回住在给定城市的所有顾客
fun Shop.getCustomersFrom(city: City): List<Customer> = customers.filter { it.city == city }

```
操作符 | 作用
---|---
all | 判断集合中的所有元素是否满足某个条件，都满足返回true
any | 判断集合中是否有元素满足某个条件，有则返回true
count | 返回集合中满足某个条件的元素数量
find |查找集合中满足某个条件的一个元素，不存在则返回null
```
// 如果超市中所有顾客都来自于给定城市，则返回true
fun Shop.checkAllCustomersAreFrom(city: City): Boolean = customers.all { it.city == city }

// 如果超市中有某个顾客来自于给定城市，则返回true
fun Shop.hasCustomerFrom(city: City): Boolean = customers.any{ it.city == city}

// 返回来自于某个城市的所有顾客数量
fun Shop.countCustomersFrom(city: City): Int = customers.count { it.city == city }

// 返回一个住在给定城市的顾客，若无返回null
fun Shop.findAnyCustomerFrom(city: City): Customer? = customers.find { it.city == city }

```
操作符 | 作用
---|---
flatMap | 将集合的元素转换为另外的元素（非一一对应）
```
// 返回所有该顾客购买过的商品集合
fun Customer.getOrderedProducts(): Set<Product> = orders.flatMap { it.products }.toSet()

// 返回超市中至少有一名顾客购买过的商品列表
fun Shop.getAllOrderedProducts(): Set<Product> = customers.flatMap { it.getOrderedProducts() }.toSet()
```
操作符 | 作用
---|---
max | 返回集合中以某个条件排序的最大的元素
min | 返回集合中以某个条件排序的最小的元素
```
// 返回商店中购买订单次数最多的用户
fun Shop.getCustomerWithMaximumNumberOfOrders(): Customer? = customers.maxBy { it.orders.size }

// 返回顾所购买过的最贵的商品
fun Customer.getMostExpensiveOrderedProduct(): Product? = orders.flatMap { it.products }.maxBy { it.price }
```
操作符 | 作用
---|---
sort | 根据某个条件对集合元素进行排序
sum | 对集合中的元素按照某种规则进行相加
groupBy | 对集合中的元素按照某种规则进行组合
```
// 按照购买订单数量升序返回商店的顾客
fun Shop.getCustomersSortedByNumberOfOrders(): List<Customer> = customers.sortedBy { it.orders.size }

// 返回顾客在商店中购买的所有订单价格总和
fun Customer.getTotalOrderPrice(): Double = orders.flatMap { it.products }.sumByDouble { it.price }

// 返回商店中居住城市与顾客的映射
fun Shop.groupCustomersByCity(): Map<City, List<Customer>> = customers.groupBy { it.city }
```
操作符 | 作用
---|---
partition | 根据某种规则将集合中的元素分为两组
fold | 对集合的元素按照某个逻辑进行一一累计
```
// 返回商店中未送到订单比送达订单要多的顾客列表
fun Shop.getCustomersWithMoreUndeliveredOrdersThanDelivered(): Set<Customer> = customers.filter {
    val (delivered, undelivered) = it.orders.partition { it.isDelivered }
    undelivered.size > delivered.size
}.toSet()

// 对所有顾客购买过的商品取交集，返回所有顾客都购买过的商品列表
fun Shop.getSetOfProductsOrderedByEveryCustomer(): Set<Product> {
    val allProduct = customers.flatMap { it.orders }.flatMap { it.products }.toSet()

    return customers.fold(allProduct) { orderedByAll, customer ->
        orderedByAll.intersect(customer.orders.flatMap { it.products })
    }
}
```
综合使用：
```
// 返回顾客所有送达商品中最贵的商品
fun Customer.getMostExpensiveDeliveredProduct(): Product? {
    return orders.filter { it.isDelivered }.flatMap { it.products }.maxBy { it.price }
}

// 返回商店中某件商品的购买次数
fun Shop.getNumberOfTimesProductWasOrdered(product: Product): Int {
    return customers.flatMap { it.orders }.flatMap { it.products }.count{it == product}
}
```
Kotlin对集合提供了几乎你能想到的所有操作，通过对这些操作的组合减少集合操作的复杂度，提高可读性。以下是Java和Kotln对集合操作的对比
```java
// 用Java实现
public Collection<String> doSomethingStrangeWithCollection(
        Collection<String> collection
) {
    Map<Integer, List<String>> groupsByLength = Maps.newHashMap();
    for (String s : collection) {
        List<String> strings = groupsByLength.get(s.length());
        if (strings == null) {
            strings = Lists.newArrayList();
            groupsByLength.put(s.length(), strings);
        }
        strings.add(s);
    }
    int maximumSizeOfGroup = 0;
    for (List<String> group : groupsByLength.values()) {
        if (group.size() > maximumSizeOfGroup) {
            maximumSizeOfGroup = group.size();
        }
    }
    for (List<String> group : groupsByLength.values()) {
        if (group.size() == maximumSizeOfGroup) {
            return group;
        }
    }
    return null;
}

```
```
// 用Kotlin实现
fun doSomethingStrangeWithCollection(collection: Collection<String>): Collection<String>? {

    val groupsByLength = collection.groupBy { s -> s.length }

    val maximumSizeOfGroup = groupsByLength.values.map { group -> group.size }.max()

    return groupsByLength.values.firstOrNull { group -> group.size == maximumSizeOfGroup }
}
```

# 运算符
## 运算符重载
还是举 [Kotlin Koans](https://play.kotlinlang.org/koans/overview) 上的运算符重载例子。假设我们需要实现以下功能：
```
enum class TimeInterval { DAY, WEEK, YEAR }

data class MyDate(val year: Int, val month: Int, val dayOfMonth: Int) : Comparable<MyDate> {
    override fun compareTo(other: MyDate): Int {
        if (year != other.year) return year - other.year
        if (month != other.month) return month - other.month
        return dayOfMonth - other.dayOfMonth
    }

    override fun toString(): String {
        return "$year/$month/$dayOfMonth"
    }
}

fun main() {
    val first = MyDate(2018, 10, 30)
    val last = MyDate(2018, 11, 1)
    for (date in first..last) {
        println(date)
    }
    println()
    println(first + DAY)
    println()
    println(first + DAY * 2 + YEAR * 2)
}
```
输出为以下： 

![运算符重载例子输出](https://upload-images.jianshu.io/upload_images/2057980-0a39304797f3b80e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

只要实现以下运算符重载既可：
```
operator fun MyDate.rangeTo(other: MyDate): DateRange = DateRange(this, other)

operator fun MyDate.plus(timeInterval: TimeInterval): MyDate = this.addTimeIntervals(timeInterval, 1)

operator fun TimeInterval.times(num: Int): RepeatTimeInterval = RepeatTimeInterval(this, num)

operator fun MyDate.plus(repeatTimeInterval: RepeatTimeInterval): MyDate =
    this.addTimeIntervals(repeatTimeInterval.timeInterval, repeatTimeInterval.num)

class RepeatTimeInterval(val timeInterval: TimeInterval, val num: Int)

class DateRange(override val start: MyDate, override val endInclusive: MyDate) : ClosedRange<MyDate>, Iterable<MyDate> {
    override fun iterator(): Iterator<MyDate> = DateIterator(start, endInclusive)
}

class DateIterator(first: MyDate, private val last: MyDate) : Iterator<MyDate> {
    private var current = first
    override fun hasNext(): Boolean {
        return current <= last
    }

    override fun next(): MyDate {
        val result = current
        current = current.nextDay()
        return result
    }
}

fun MyDate.nextDay(): MyDate = this.addTimeIntervals(DAY, 1)

fun MyDate.addTimeIntervals(timeInterval: TimeInterval, number: Int): MyDate {
    val c = Calendar.getInstance()
    c.set(year + if (timeInterval == TimeInterval.YEAR) number else 0, month - 1, dayOfMonth)
    var timeInMillis = c.timeInMillis
    val millisecondsInADay = 24 * 60 * 60 * 1000L
    timeInMillis += number * when (timeInterval) {
        TimeInterval.DAY -> millisecondsInADay
        TimeInterval.WEEK -> 7 * millisecondsInADay
        TimeInterval.YEAR -> 0L
    }
    val result = Calendar.getInstance()
    result.timeInMillis = timeInMillis
    return MyDate(result.get(Calendar.YEAR), result.get(Calendar.MONTH) + 1, result.get(Calendar.DATE))
}
```
Kotlin支持使用指定的扩展函数来实现运算符的重载，运算符对应的方法名具体参见官方文档 [Operator overloading](http://kotlinlang.org/docs/reference/operator-overloading.html)

## infix
标记为infix的方法，可以类似于二元运算符使用，举个例子
```
infix fun Int.plus(other: Int): Int {
    return this + other
}

fun main() {
    // 结果会输出7
    println(3 plus 4)
}
```
infix方法执行的优先级低于算数运算符、类型转换type case以及rangTo运算符，但是高于布尔、is、in check等其他运算符。  
使用infix的扩展函数可以实现自定义的二元运算标记。

# 整洁Kotlin风格
在《Kotlin in Action》一书中有归纳了一些Kotlin对比Java的整洁语法如下：
常规语法|	整洁语法|	用到的功能
---|---|---
StringUtil.capitalize(s)|	s.capitalize()	|扩展函数
1.to("one")	|1 to "one"	|中缀函数 infix
set.add(2)|	set += 1|	运算符重载
map.get("key")|	map["key"]	|get方法约定
file.use({f -> f.read})	|file.use { it.read() }	|括号内lambda外移
sb.append("a") sb.append("b")|	with(sb) { append(“a") append(“b")}|	带接收者的lambda
整洁语法换句话来说也是Kotlin的一种编程风格，其他约定俗成的整洁Kotlin编程风格可见官方文档 [Idioms](http://kotlinlang.org/docs/reference/idioms.html)。非常建议大家看看Idioms这个文档，里面涵盖了非常Kotlin的使用方式，包括：
* 使用默认参数代替方法重载
* String模板（在Android中是否推荐仍值得商榷）
* lambda使用it代替传入值
* 使用下标方式访问map
* 懒初始化属性
* 使用rangs范围遍历
* if when表达式返回值
* 等等
## 方法参数
Kotlin中的function是一等公民，拥有和变量一样的定义以及传参方式，如以下例子：
```
fun SQLiteDatabase.inTransaction(func: (SQLiteDatabase) -> Unit) {
  beginTransaction()
  try {
    func(this)
    setTransactionSuccessful()
  } finally {
    endTransaction()
  }
}
// 调用的时候就可以如下方法进行调用
db.inTransaction {
  it.db.delete("users", "first_name = ?", arrayOf("Jake"))
}
```
## 带接收者的lambda表达式
lambda表达式可以声明拥有接收者，例如：
```
val isEven: Int.() -> Boolean = {
    this % 2 == 0
}

fun main() {
    print(2.isEven())
}
```
这种带接收者的lambda实际上也是一种方法定义，不过其优先级比扩展方法要低，如果同时有扩展函数（如下）拥有相同名字，则会优先调用扩展方法。
```
fun Int.isEven(): Boolean {
    return this % 2 != 0
}
```
## let run with apply also
这几个关键字其实都是Kotlin的特殊方法，他们可以让lambda里面的代码在相同的接收者中运行，避免冗余代码，他们的声明如下：
```
public inline fun <T, R> T.let(block: (T) -> R): R {
    return block(this)
}
public inline fun <R> run(block: () -> R): R {
    return block()
}
public inline fun <T, R> with(receiver: T, block: T.() -> R): R {
    return receiver.block()
}
public inline fun <T> T.apply(block: T.() -> Unit): T {
    block()
    return this
}
public inline fun <T> T.also(block: (T) -> Unit): T {
    block(this)
    return this
}
```
从声明中可以看出他们有以下区别，假设在以下代码中运行
```
class MyClass {
    fun test() {
        val str: String = "..."
        val result = str.xxx {
            print(this) // 接收者this
            print(it) // lambda参数it
            42 // 返回结果
        }
    }
}
```
方法| 接收者this|lambda参数it|返回结果
---|---|---|---
let | this@MyClass    | String("...") | Int(42)       
 run      | String("...")   | N\A           | Int(42)       
 with(*)    | String("...")   | N\A           | Int(42)       
 apply    | String("...")   | N\A           | String("...") 
 also     | this@MyClass    | String("...") | String("...") 
 
## DSL构建
以下是DSL和API调用方式的区别
```
// DSL
dependencies {
    compile("junit")
    compile("guice")
}
```
```
// API
project.dependencies.add("compile", "junit")
project.dependencies.add("compile", "guice")
```
对比下DSL方式更为简洁且易读。通过上述对lambda的介绍可以发现Kotlin可以完美地支持DSL方式编程，只要少量的扩展方法以及lambda定义既可实现以下方式来构建一段html表格
```
html {
    table {
        tr (color = getTitleColor()){
            this.td {
                text("Product")
            }
            td {
                text("Price")
            }
            td {
                text("Popularity")
            }
        }
        val products = getProducts()
        for ((index, product) in products.withIndex()) {
            tr {
                td(color = getCellColor(index, 0)) {
                    text(product.description)
                }
                td(color = getCellColor(index, 1)) {
                    text(product.price)
                }
                td(color = getCellColor(index, 2)) {
                        text(product.popularity)
                }
            }
        }
    }
}

```
具体定义如下：
```
import java.util.ArrayList

open class Tag(val name: String) {
    val children: MutableList<Tag> = ArrayList()
    val attributes: MutableList<Attribute> = ArrayList()

    override fun toString(): String {
        return "<$name" +
            (if (attributes.isEmpty()) "" else attributes.joinToString(separator = "", prefix = " ")) + ">" +
            (if (children.isEmpty()) "" else children.joinToString(separator = "")) +
            "</$name>"
    }
}

class Attribute(val name : String, val value : String) {
    override fun toString() = """$name="$value" """
}

fun <T: Tag> T.set(name: String, value: String?): T {
    if (value != null) {
        attributes.add(Attribute(name, value))
    }
    return this
}

fun <T: Tag> Tag.doInit(tag: T, init: T.() -> Unit): T {
    tag.init()
    children.add(tag)
    return tag
}

class Html: Tag("html")
class Table: Tag("table")
class Center: Tag("center")
class TR: Tag("tr")
class TD: Tag("td")
class Text(val text: String): Tag("b") {
    override fun toString() = text
}

fun html(init: Html.() -> Unit): Html = Html().apply(init)

fun Html.table(init : Table.() -> Unit) = doInit(Table(), init)
fun Html.center(init : Center.() -> Unit) = doInit(Center(), init)

fun Table.tr(color: String? = null, init : TR.() -> Unit) = doInit(TR(), init).set("bgcolor", color)

fun TR.td(color: String? = null, align : String = "left", init : TD.() -> Unit) = doInit(TD(), init).set("align", align).set("bgcolor", color)

fun Tag.text(s : Any?) = doInit(Text(s.toString()), {})
```

# 属性代理
Kotlin提供对属性代理的支持，可以将属性的get set操作代理到外部执行。代理的好处有三个：
* 懒初始化，只在第一次调用进行初始化操作
* 实现对属性的观察者模式
* 方便对属性进行保存等管理  

下面来看比较常用的懒初始化例子：
```
val lazyValue: String by lazy {
    println("computed!")
    "Hello"
}

fun main() {
    println(lazyValue)
    println(lazyValue)
}
```
以上代码会输出
```
computed!
Hello
Hello
```
证明懒加载模块只在第一次调用被执行，然后会将得到的值保存起来，后面访问属性将不会继续计算。这也是在Kotlin中实现单例模式的方式。这种懒初始化的过程也是线程同步的，线程同步方式有以下几种：
```java
public enum class LazyThreadSafetyMode {
    /**
     * 加锁单一线程初始化Lazy实例
     */
    SYNCHRONIZED,

    /**
     * 初始化代码块会被多次调用，但只有首次初始化的值会赋值给Lazy实例
     */
    PUBLICATION,

    /**
     * 没有线程安全，不保证同步，只能在确保单线程环境中使用
     */
    NONE,
}
```

# 解构
解构是非常实用的Kotlin提供的将一个对象属性分离出来的特性。
内部实现原理是通过声明为```componentN()```的操作符重载实现。对Kotlin中的```data```类会自动生成```component```函数，默认支持解构操作。以下是解构比较实用的一个例子：
```
for ((key, value) in map) {
   // 使用该 key、value 做些事情
}
```
# 协程Coroutine
先占个位，等我看懂了再来补充 :)
先po一个协程和Rxjava的对比吸引下大家
```
// RxJava
interface RemoteService {
    @GET("/trendingshows")
    fun trendingShows(): Single<List<Show>>
}
service.trendingShows()
    .scheduleOn(schedulers.io)
    .subscribe(::onTrendingLoaded, ::onError)
```
```
// Coroutine
interface RemoteService {
    @GET("/trendingshows")
    suspend fun trendingShows(): List<Show>
}
val show = withContext(dispatchers.io) {
    service.trendingShows()
}
```
# 在Android中使用
## findViewById
通过引入```import kotlinx.android.synthetic.main.```实现直接获取xml中ui组件。
## anko 
[anko](https://github.com/Kotlin/anko)提供了很多工具类，帮助开发者在Android中更好地使用Kotlin。anko提供了以下实用工具：
* 快捷Intent：```startActivity(intentFor<SomeOtherActivity>("id" to 5).singleTop())```
* 快捷toast、dialog：```toast("Hi there!")```
* 快捷log：```info("London is the capital of Great Britain")```
* 快捷协程：```bg()```
* layout DSL构建
* 等等
## ktx
[android-ktx](https://github.com/android/android-ktx) 提供了一系列Andrdoid方法的简洁实现。

# 与Java不太一样的地方
* static 与 伴生对象  
在Kotlin中并没有```static```这个关键字，如果想要实现类似于Java中```static```的用法，需要声明伴生对象[companion object](https://kotlinlang.org/docs/reference/object-declarations.html#companion-objects)。使用```object```声明的类实际上是一个单例，可以支持直接调用其中的属性与方法。使用了```companion```修饰的object实际上是可以放在其他类内部的单例，因此可以实现类似于Java中```static```的效果。至于为什么Kotlin要这样设计，原因是Kotlin希望所有属性都是一个类对象，不做差异化处理，这也是为什么Java中的int、long等基本数据类型在Kotlin中也用Int、Long处理的原因。  

* 默认都是final，除非声明为open  
在Kotlin中所有方法默认都是禁止覆盖的，这样的好处是规范了接口设计的安全性，仅开放那些确实在设计中希望子类覆盖的方法。  

* 默认是public，多了internal  
在Java中，如果不加可见性修饰的话默认是包内可见，Kotlin中默认都是public。同时Kotlin加入了internal关键字，代表着是模块内可见。这个可见性弥补了使用Java进行模块设计的过程中，可见性设计的缺陷。如果要想在Java中实现仅开放某些方法给外部模块使用，但是这些方法又能在内部模块自由调用，那只能是把这些方法都放到一个包内，显然是一个很不好的包结构设计。Kotlin```internal```关键字可以完美解决这个问题。要想在Java调用的时候完全隐蔽Kotlin的方法，可以加上```@JvmSynthetic```。
* 泛型  
Java中使用```extends```和```super```来区分泛型中生产者和消费者，俗称[PEST](https://stackoverflow.com/questions/2723397/what-is-pecs-producer-extends-consumer-super)，在Kotlin中对应的是```out```和```in```。同时Java与Kotlin都会对泛型进行运行时擦除，Kotlin不一样的是可以对```inline```方法使用```reified```关键字来提供运行时类型。
* 本地方法  
由于在Kotlin语言中方法是一等公民，因此可以声明局部生命周期的本地方法，如下例子：
```
fun dfs(graph: Graph) {
    val visited = HashSet<Vertex>()
    fun dfs(current: Vertex) {
        if (!visited.add(current)) return
        for (v in current.neighbors)
            dfs(v)
    }

    dfs(graph.vertices[0])
}
```

# 学习资源
[ Kotlin online try ](https://play.kotlinlang.org/koans/Introduction/Hello,%20world!/Task.kt)  
[ Kotlin官方文档 ](https://kotlinlang.org/docs/reference/)  
[ kotlin in action ](https://note.youdao.com/share/?id=b9a1a935fa1cd93a4bb75e2a52067f6e&type=note#/)  
[ Android Development with kotlin ](http://note.youdao.com/noteshare?id=20bf8baae8e69b269870e9140e6ad1bd )  
[ Kotlin for Android Developers ](http://note.youdao.com/noteshare?id=bef3033ab6d5f1dd189a831d18e33034)

# 问题
在Java项目中引入kotlin在大多数情况下都是无痛的，且可以马上带给我们不一样的快捷高效体验。如果硬是要说出一点Kotlin的问题，我觉得会有几个：
* Kotlin加入会增加方法数以及不多的代码体积，这在大多数情况下不会产生太大的问题
* 写法太灵活，较难统一。由于Kotlin允许程序员选择传统的Java风味或者Kotlin风味来编写代码，这种灵活性可能导致混合风味的代码出现，且较难统一。
* 过多的大括号层级嵌套。这是因为lambda以及方法参数带来的，其初衷是希望大家可以用DSL的代码风格，如果没掌握DSL方式的话可能会写出比较丑陋的多层级嵌套Java风味代码，影响代码可读性。

# 最后
Kotlin是一门优秀的语言，值得大家尝试。


