---
title: "The state of Clojure on Android"
layout: post
---

### Or: Does Lean Clojure work?

Clojure on Android suffers from the slow startup times of the Clojure runtime. The Lean Clojure compiler projects promise fast startup times and performance at the cost of dynamism and complexity. Does it work?

<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 600px;" src="/img/clojure_plus_android_dark.png"></img>

How do you know if anything works? You test it. You set up some experiment that you think models the problem. You make your change, run the experiment with and without the change, and see what happens. You draw conclusions and quibble about whether you tested what you thought you tested and whether the results mean anything.

Here's what I benchmarked and what I think it means. But first a bit of background.

## What is Lean Clojure?

The idea of Lean Clojure is to remove some of the dynamism of Clojure for performance. Over the summer of 2014 two projects were developed related to this. Alexander Yakushev developed the <a href="http://clojure-android.info/skummet/">Skummet lean Clojure compiler</a> based on the standard Clojure compiler. Reid McKenzie worked on the <a href="http://www.arrdem.com/2014/08/06/of_oxen,_carts_and_ordering/">Oxcart compiler</a> based on the Clojure in Clojure compiler. The Oxcart compiler compiles a rather limited subset of Clojure so it is not presented here. 

The Skummet compiler works something like the following.

Clojure namespaces set up a dynamic mapping between symbols, vars, and functions. This mapping looks basically like this:

<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 600px;" src="/img/namespace_vars.svg"></img>

At run time Clojure calls functions like this, in decompiled JVM bytecode:

```java
RT.var("clojure.core", "cons").getRawRoot().invoke(args);
```

Skummet changes this by dropping out the middle men, the symbols and vars, to get something like this:

<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 600px;" src="/img/namespace_vars_lean.svg"></img>

Invoking functions gets a lot simpler:

```java
clojure.core$cons.invoke(args);
```

Skummet does other things related to metadata and workarounds to preserve dynamism when necessary, but I believe this is the meat of it.

It's fairly obvious why this would be expected to improve Clojure execution speed. Clojure is mostly functions and this simplifies almost every function execution. This should speed things up by reducing overhead and making it easier for the virtual machine to optimize by inlining and doing whatever other black magic virtual machines do.

It's perhaps less immediately obvious why this is expected to improve startup times. When the Clojure runtime loads a program, it loads all of the namespaces that are used in the program right at the start. When a namespace is loaded, it sets up the mapping from symbols to vars to functions. It also sets metadata on those vars. This isn't a complicated process, but you need to create your var objects, create your metadata objects, and assign them to the appropriate places. It takes some time. Skummet cuts out a lot of this work, and so should reduce startup times.

That's the theory. But does it work?

## Does Lean Clojure work?

I took five benchmarks from the Computer Language Benchmarks Game,  two little benchmarks of my own, and ran the benchmarks on the Nexus 5 and Nexus 7 on both Dalvik and ART. Here are the results:

<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 800px;" src="/img/benchmarks1.png"></img>
<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 800px;" src="/img/benchmarks2.png"></img>
<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 800px;" src="/img/benchmarks3.png"></img>
<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 800px;" src="/img/benchmarks4.png"></img>

The same benchmarks presented with only startup times by test environment:

<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 800px;" src="/img/benchmark_startup_times.png"></img>

Each benchmark opens an Android activity and performs some task. The *hello* benchmark just prints "Hello world". The *dependencies* benchmark does something trivial with two library dependencies, <a href="https://github.com/ReactiveX/RxClojure">RxClojure</a> (or <a href="https://github.com/ReactiveX/RxJava">RxJava</a>) and <a href="https://github.com/cognitect/transit-clj">Transit</a>. The others execute algorithms specified in the <a href="http://benchmarksgame.alioth.debian.org/">Computer Language Benchmarks Game</a>.

The programs are written in Java and Clojure and compiled using the Java, Clojure, and Skummet compilers. Each benchmark is executed thirty times and the results are averaged.

What might we conclude from this?

**Clojure on Android apps start slowly (2+ seconds minimum)**

Well, duh, you're thinking. The benchmarks give a bit of the scope of the problem, though. On Android Dalvik, Clojure apps take a minimum of nearly two seconds to start on the Nexus 5 phone and 2.5 seconds on the Nexus 7 tablet. The Nexus 5 is a relatively new phone and probably faster than most phones on the market, so the general case for performance is likely to be worse.

The *dependencies* benchmark performs a trivial task with two library dependencies and has startup times exceeding 2.5 and 3.5 seconds for the same device setups. This suggests a fairly fast scaling up of startup times. Actual apps would likely have more dependencies and code and take significantly longer.

**ART helps (1.5+ seconds minimum)**

The latest version of Android, Lollipop, uses the new ART virtual machine to execute apps in place of Dalvik. This improved startup times in these benchmarks by about about 20-30% on average.

**Lean Clojure helps even more (0.7+ seconds minimum)**

Lean Clojure cuts Clojure on Android startup times in half across the board, dropping them from around 1.5 to 2.5 seconds to around 0.7 to 1 seconds. Run time performance seems to be on par with standard Clojure, though these benchmarks are poor tests of performance.

## What does this mean?

Lean Clojure works. Skummet cuts Clojure on Android startup times in half in these benchmarks. But it's not good enough.

A half a second is about the minimum amount of time needed to execute Clojure code on Android on Skummet. Times for actual programs are likely to be significantly higher. This might not be a problem for apps that are loaded once and run for a long period, but for many types of development this is just too long.

If the lean Clojure project were continued, it seems likely it would bring this down to an acceptable range. Dependency shaking and inlining functions could make a large difference. Tools like ProGuard could make additional improvements. There are also other possible directions for Clojure on Android like ClojureScript plus third party frameworks such as Titanium or the upcoming Facebook React Native.

But Android is still waiting for it's Swift.

## More details

The rather verbose version of this post is in my <a href="http://thesis.ndk.io">thesis</a>.
