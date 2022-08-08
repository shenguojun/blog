---
title: "深入理解Android Runtime&Profile启动优化"
date: 2021-06-30T11:07:45+08:00
author: 申国骏
tags: ["android"]
draft: true
---



## Dex&Profile文件说明



![image-20210708153531874](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image-20210708153531874.png)

![image-20210708153958013](https://raw.githubusercontent.com/shenguojun/ImageServer/master/uPic/image-20210708153958013.png)















## Dexlayout

Dexlayout is a library introduced in Android 8.0 to analyze dex files and reorder them according to a profile. Dexlayout aims to use runtime profiling information to reorder sections of the dex file during idle maintenance compilation on device. By grouping together parts of the dex file that are often accessed together, programs can have better memory access patterns from improved locality, saving RAM and shortening start up time.

Since profile information is currently available only after apps have been run, dexlayout is integrated in dex2oat's on-device compilation during idle maintenance.



The number of files, their extensions, and names are subject to change across releases, but as of the Android O release, the files being generated are:

- `.vdex`: contains the uncompressed DEX code of the APK, with some additional metadata to speed up verification.
- `.odex`: contains AOT compiled code for methods in the APK.
- `.art (optional)`: contains ART internal representations of some strings and classes listed in the APK, used to speed application startup.



One core ART option to configure these two categories is *compiler filters*. Compiler filters drive how ART compiles DEX code and is an option passed to the `dex2oat` tool. Starting in Android O, there are four officially supported filters:

- *verify*: only run DEX code verification.
- *quicken*: run DEX code verification and optimize some DEX instructions to get better interpreter performance.
- *speed*: run DEX code verification and AOT-compile all methods.
- *speed-profile*: run DEX code verification and AOT-compile methods listed in a profile file.



## Forcing compilation

To force compilation, run the following:

```
adb shell cmd package compile
```

Common use cases for force compiling a specific package:

- Profile-based:

  ```
  adb shell cmd package compile -m speed-profile -f my-package
  ```

- Full:

  ```
  adb shell cmd package compile -m speed -f my-package
  ```



## Clearing profile data

To clear profile data and remove compiled code, run the following:

- For one package:

  ```
  adb shell cmd package compile --reset my-package
  ```



To understand how these code profiles achieve better performance, we need to look at their structure. Code profiles contain information about:

- Classes loaded during startup
- Hot methods that the runtime deemed worthy of optimizations
- The layout of the code (e.g. code that executes during startup or post-startup)

Using this information, we use a variety of optimization techniques, out of which the following three provide most of the benefits:

- [App Images](https://youtu.be/fwMM6g7wpQ8?t=2145): 

  We use the start up classes to build a pre-populated heap where the classes are pre-initialized (called an app image). When the application starts, we map the image directly into memory so that all the startup classes are readily available.

  - The benefit here is that the app's execution saves cycles since it doesn't need to do the work again, leading to a faster startup time.

  App images are a memory map of pre-initialized classes that are used at startup. The image is directly mapped to the memory heap on launch. Similarly, code-precompilation targets code that is executed when the app launches. This code is precompiled and optimized, sparing thus the time it takes for the JIT compiler to do its job. Finally, the bytecode re-layout of an app aims to keep close together code that is used at startup, code that is used immediately after startup, and the rest of the code, thus improving loading times.

- *Code pre-compilation:* We pre-compile all the hot code. When the apps execute, the most important parts of the code are already optimized and ready to be natively executed. The app no longer needs to wait for the JIT compiler to kick in.

- - The benefit is that the code is mapped as clean memory (compared to the JIT dirty memory) which improves the overall memory efficiency. The clean memory can be released by the kernel when under memory pressure while the dirty memory cannot, lessening the chances that the kernel will kill the app.

- More efficient dex layout: 

  We reorganize the dex bytecode based on method information the profile exposes. The dex bytecode layout will look like: [startup code, post startup code, the rest of non profiled code].

  - The benefit of doing this is a much higher efficiency of loading the dex byte code in memory: The memory pages have a better occupancy, and since everything is together, we need to load less and we can do less I/O.





#### /data/app/{一串奇怪的字符}/{package_name}一串奇怪的字符/

* base.apk
* lib/arm/xxx.so
* oat/arm/base.odex
* oat/arm/base.vdex

#### /data/data/{package_name}/oat/arm/

* Anonymous-DexFile@xxx.vdex

#### /data/misc/profiles/cur/0/{package_name}/

* primary.prof 30.55k



## Profile启动优化原理&实操

