---
title: "Why is Clojure bootstrapping so slow?"
layout: post
---

In my tests Clojure programs take 35x and 6x as long to boot on the desktop and Android when compared to their Java counterparts. Why? Where does all of the time go?

Here is the execution time for basic Hello World programs in Java and Clojure on the desktop and Android:

<img class="blog-img" src="/img/hello_world_all.png"></img>

So the short answer is this: Clojure programs start slowly because every Clojure program loads the main Clojure namespace `clojure.core` before executing. This takes time.

But what exactly does `clojure.core` do that takes so long?

### clojure.core bootstrap time

An AOT-compiled Clojure program is run by loading and executing its main class file. One of the first things the main class file does is load the `clojure.core` namespace so that Clojure functions can be executed. The `clojure.core` namespace is compiled into a loader class `core__init.class`.

About 80% of the load time of my profiled Hello World apps on both the JVM and Dalvik went into loading/executing this loader class. The rest of the time is split between loading other classes necessary for Clojure code execution (such as clojure.lang.RT and clojure.lang.Compiler) and loading and executing the Hello World program itself. In order to completely separate Clojure load time from our program load time I will focus right now solely on the loading of `clojure.core`.

Here's one way of looking at how `core__init.class` load time breaks down: 

<img class="blog-img" style="display: inline-block;" src="/img/desktop_core_time.png"></img>
<img class="blog-img" style="display: inline-block;" src="/img/android_core_time.png"></img>

A good portion of the time goes into creating and assigning vars and metadata for clojure.core functions. The desktop program takes a significantly longer time assigning vars and metadata than the Android program. Over half of the total time goes into what I have described as loading "external functions". Let's look at what exactly is happening in each of those to get an understanding of where time goes and what happens when `clojure.core` is loaded. 

In the following sections I have marked the percentage of the total load time of `clojure.core` that was consumed by various tasks in desktop profiling and Android profiling (in parentheses).

### Creating vars and metadata: 11.2% (17.3%)

When `core__init.class` is loaded, the first thing that is executed by the JVM or Dalvik runtime is the class initialization method of the file. This is called `<clinit>` in the JVM. The decompiled `<clinit>` method for `core__init.class` is as follows.

```java
static
  {
    // 11% (17%)
    // Creating vars + metadata
    __init0();
    __init1();
    __init2();
    __init3();
    __init4();
    __init5();
    __init6();
    __init7();
    __init8();
    __init9();
    __init10();
    __init11();
    __init12();
    __init13();
    __init14();
    __init15();
    __init16();
    __init17();
    __init18();
    __init19();
    __init20();
    __init21();
    __init22();
    __init23();

    // ~0%
    Compiler.pushNSandLoader(Class.forName("clojure.core__init").getClassLoader());
    try
    {
      // 89% (83%)
      // Assigning vars + metadata, loading external functions
      load();
 
      // ~0%
      Var.popThreadBindings();
    }
    finally
    {
      // ~0%
      Var.popThreadBindings();
      throw finally;
    }
  }
```

The load method calls a bunch of `__init` methods and then calls the `load` method (within a specific binding context). Creating vars and metadata happens in the `__init` methods and most of the rest of the work happens in `load`.

Note that loading this class (and therefore running its `<clinit>` method) is functionally equivalent to loading the corresponding Clojure file. So loading `core__init.class` is the same as loading `clojure/core.clj`, the `clojure.core` namespace file.

Creating vars and metadata is all done in the `__init` methods as I have labeled above. Assigning vars and metadata and loading external classes happens in the `load` method.

What do the `__init` methods look like? Here's the decompiled first part of `__init0`:

```java
public static void __init0(){
    const__0 = (Var)RT.var("clojure.core", "in-ns");
    IObj localIObj1 = (IObj)Symbol.intern(null, "clojure.core");
    Object[] arrayOfObject1 = new Object[4];
    arrayOfObject1[0] = RT.keyword(null, "author");
    arrayOfObject1[1] = "Rich Hickey";
    arrayOfObject1[2] = RT.keyword(null, "doc");
    arrayOfObject1[3] = "The core Clojure language.";
    const__1 = (AFn)localIObj1.withMeta((IPersistentMap)RT.map(arrayOfObject1));
    const__2 = (AFn)Symbol.intern(null, "clojure.core");
    const__3 = (Var)RT.var("clojure.core", "unquote");
    const__4 = (Keyword)RT.keyword(null, "file");
    const__5 = (Keyword)RT.keyword(null, "column");
    const__6 = Integer.valueOf(1);
    const__7 = (Keyword)RT.keyword(null, "line");
    const__8 = Integer.valueOf(13);
    Object[] arrayOfObject2 = new Object[6];
    arrayOfObject2[0] = RT.keyword(null, "column");
    arrayOfObject2[1] = Integer.valueOf(1);
    arrayOfObject2[2] = RT.keyword(null, "line");
    arrayOfObject2[3] = Integer.valueOf(13);
    arrayOfObject2[4] = RT.keyword(null, "file");
    arrayOfObject2[5] = "clojure/core.clj";
    const__9 = (AFn)RT.map(arrayOfObject2);
    const__10 = (Var)RT.var("clojure.core", "unquote-splicing");
    const__11 = Integer.valueOf(14);
    Object[] arrayOfObject3 = new Object[6];
    arrayOfObject3[0] = RT.keyword(null, "column");
    arrayOfObject3[1] = Integer.valueOf(1);
    arrayOfObject3[2] = RT.keyword(null, "line");
    arrayOfObject3[3] = Integer.valueOf(14);
    arrayOfObject3[4] = RT.keyword(null, "file");
    arrayOfObject3[5] = "clojure/core.clj";
    const__12 = (AFn)RT.map(arrayOfObject3);
    const__13 = (Var)RT.var("clojure.core", "list");
    const__14 = Integer.valueOf(16);
    const__15 = (Keyword)RT.keyword(null, "added");
    const__16 = (Keyword)RT.keyword(null, "doc");
    const__17 = (Keyword)RT.keyword(null, "arglists");
    Object[] arrayOfObject4 = new Object[1];
    Object[] arrayOfObject5 = new Object[2];
    arrayOfObject5[0] = Symbol.intern(null, "&");
    arrayOfObject5[1] = Symbol.intern(null, "items");
    arrayOfObject4[0] = RT.vector(arrayOfObject5);
    IObj localIObj2 = (IObj)PersistentList.create(Arrays.asList(arrayOfObject4));
    Object[] arrayOfObject6 = new Object[4];
    arrayOfObject6[0] = RT.keyword(null, "line");
    arrayOfObject6[1] = Integer.valueOf(17);
    arrayOfObject6[2] = RT.keyword(null, "column");
    arrayOfObject6[3] = Integer.valueOf(15);
    const__18 = localIObj2.withMeta((IPersistentMap)RT.map(arrayOfObject6));
    Object[] arrayOfObject7 = new Object[12];
    arrayOfObject7[0] = RT.keyword(null, "arglists");
    Object[] arrayOfObject8 = new Object[1];
    Object[] arrayOfObject9 = new Object[2];
    arrayOfObject9[0] = Symbol.intern(null, "&");
    arrayOfObject9[1] = Symbol.intern(null, "items");
    arrayOfObject8[0] = RT.vector(arrayOfObject9);
    IObj localIObj3 = (IObj)PersistentList.create(Arrays.asList(arrayOfObject8));
    Object[] arrayOfObject10 = new Object[4];
    arrayOfObject10[0] = RT.keyword(null, "line");
    arrayOfObject10[1] = Integer.valueOf(17);
    arrayOfObject10[2] = RT.keyword(null, "column");
    arrayOfObject10[3] = Integer.valueOf(15);
    arrayOfObject7[1] = localIObj3.withMeta((IPersistentMap)RT.map(arrayOfObject10));
    arrayOfObject7[2] = RT.keyword(null, "column");
    arrayOfObject7[3] = Integer.valueOf(1);
    arrayOfObject7[4] = RT.keyword(null, "added");
    arrayOfObject7[5] = "1.0";
    arrayOfObject7[6] = RT.keyword(null, "doc");
    arrayOfObject7[7] = "Creates a new list containing the items.";
    arrayOfObject7[8] = RT.keyword(null, "line");
    arrayOfObject7[9] = Integer.valueOf(16);
    arrayOfObject7[10] = RT.keyword(null, "file");
    arrayOfObject7[11] = "clojure/core.clj";
    const__19 = (AFn)RT.map(arrayOfObject7);
    const__20 = (Var)RT.var("clojure.core", "cons");
    const__21 = Integer.valueOf(22);
    const__22 = (Keyword)RT.keyword(null, "static");

    // ...lots more
}
```

Compare this to the beginning of `clojure/core.clj` from the Clojure compiler:

```clojure
(ns ^{:doc "The core Clojure language."
       :author "Rich Hickey"}
  clojure.core)

(def unquote)
(def unquote-splicing)

(def
 ^{:arglists '([& items])
   :doc "Creates a new list containing the items."
   :added "1.0"}
  list (. clojure.lang.PersistentList creator))

(def
 ^{:arglists '([x seq])
    :doc "Returns a new seq where x is the first element and seq is
    the rest."
   :added "1.0"
   :static true}

 cons (fn* ^:static cons [x seq] (. clojure.lang.RT (cons x seq))))
```

You can see that the decompiled code creates a bunch of constants containing the metadata and the names and arguments for the Clojure functions in `clojure.core`. The data is stored in constants that are used later, as we shall see. Creating these vars and metadata consumes about 10-20% of our bootstrap time.

### Assigning vars + metadata: 37.6% (19.3%)

Assigning the vars and metadata that were created earlier happens in the `load` method of `core__init.class`. Here's the first part of the decompiled code for the `load` method:

```java
public static void load()
{
    if (((Symbol)const__1).equals(const__2)) {
       tmpTernaryOp = null; break label67;
       ((IFn)new core.loading__1327__auto__()).invoke();
    } else {
      LockingTransaction.runInTransaction((Callable)new core.fn__3836());
    }
    label67: const__3.setMeta((IPersistentMap)const__9);
    const__10.setMeta((IPersistentMap)const__12);
    Var tmp96_93 = const__13;
    tmp96_93.setMeta((IPersistentMap)const__19);
    tmp96_93.bindRoot(PersistentList.creator);
    Var tmp116_113 = const__20;
    tmp116_113.setMeta((IPersistentMap)const__24);
    tmp116_113.bindRoot(new core.cons());
    Var tmp140_137 = const__25;
    tmp140_137.setMeta((IPersistentMap)const__28);
    tmp140_137.bindRoot(new core.let());
    
    // ... many more similar lines
```

Again, compare this to the beginning of `clojure/core.clj`:

```clojure
(ns ^{:doc "The core Clojure language."
       :author "Rich Hickey"}
  clojure.core)

(def unquote)
(def unquote-splicing)

(def
 ^{:arglists '([& items])
   :doc "Creates a new list containing the items."
   :added "1.0"}
  list (. clojure.lang.PersistentList creator))

(def
 ^{:arglists '([x seq])
    :doc "Returns a new seq where x is the first element and seq is
    the rest."
   :added "1.0"
   :static true}

 cons (fn* ^:static cons [x seq] (. clojure.lang.RT (cons x seq))))
```

You can see that the decompiled method sets the metadata and binds the vars for the `list` (PersistentList), `cons`, and `let` functions. The `load` method does most of the work of `clojure.core`. It runs through every function in the `clojure.core` namespace and does a few things. The code in `load` for the `cons` function from above, for instance, looks like this:

```java
// __init0()
// The var was created in __init0
const__20 = (Var)RT.var("clojure.core", "cons");


// load()

// Create new Var with value (Var)RT.var("clojure.core", "cons")
Var tmp116_113 = const__20;

// Set metadata for Var
tmp116_113.setMeta((IPersistentMap)const__24);

// Make Var point to new instance of inner class cons
tmp116_113.bindRoot(new core.cons());
```

For each function the `load` method does four things: 

* Assigns the corresponding constant, which was created in an `__init` method, to a local Var.
* Adds meta data, which was also created in an `__init` method, to the Var with `setMeta`.
* Creates a new instance of the class corresponding to the function. Functions in `clojure.core` are defined as inner classes of the `core` class in Java bytecode.
* Binds the root of the new Var to point to the new instance.

The part we mostly care about is this line:

```java
tmp116_113.bindRoot(new core.cons());
```

About one third of `clojure.core` bootstrap time on the desktop goes into executing statements like these. Most of this time is consumed just loading the class itself before executing anything from the class. Some time is also consumed by running the constructor for the class. In other words, the time is consumed roughly like this:

```java
tmp116_113.bindRoot( // 0%
  new                // 0%
    core             // 29%
    .cons()          // 8-19%
);
```

On Android the profiler did not pick up any time for loading Java class files. I presume that this is because there was no loading step here in Dalvik. An Android application is packaged as a single DEX file instead of many class files. This file needs to be loaded for the application to even run, so at this stage all of the Clojure bytecode was already loaded. The time on Android should show up in the initial load of the application, although this seems to be something Android optimizes for so it might not be as significant.

In any event, this explains the difference in our previous chart for the time spent assigning vars and metadata between the desktop and Android. The desktop spends much more time because it spends a significant amount of time loading the class files themselves.

### Loading external functions: 63.3% (51.2%)

The rest of our time goes into loading external `clojure.core` functions. What do I mean by this? There's a section in `clojure/core.clj` that looks like this:

```clojure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; helper files ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(alter-meta! (find-ns 'clojure.core) 
             assoc :doc "Fundamental library of the Clojure language")
(load "core_proxy")     ; 2%
(load "core_print")     ; 4%
(load "genclass")       ; 2%
(load "core_deftype")   ; 3%
(load "core/protocols") ; 8%
(load "gvec")           ; 2%
(load "instant")        ; 6%
(load "uuid")           ; 5%
```

There's also another line like this:

```clojure
(require '[clojure.java.io :as jio]) ;; 8%
```

I have marked the individual times only for desktop profiling as Android profiling data was difficult to parse. These lines load a number of functions that are defined in other classes. Functions from `core_proxy.clj`, `core_print.clj`, `genclass.clj`, `core_deftype.clj`, and `gvec.clj` are defined in the `clojure.core` namespace. Functions from the other files are defined in their own namespaces. I'm not sure why these are separated from the main file except perhaps for organizational purposes, but over half of our load time comes from these methods.

### What can we do about this?

Martin Trojer [discusses this same issue](http://martinsprogrammingblog.blogspot.fi/2012/02/why-is-clojure-so-slow.html) based on Daniel Solano Gómez's [presentation](https://github.com/relevance/clojure-conj/blob/master/2011-slides/daniel-solano-gómez-clojure-and-android.pdf) from Clojure/conj 2011. Solano's presentation presents the problems of Clojure on Android quite clearly. He has also for several years proposed a ["Lean JVM Runtime"](http://dev.clojure.org/display/community/Project+Ideas#ProjectIdeas-LeanJVMRuntime) Google Summer of Code project targetting this problem. The ideas presented here are mostly not my own.

Based on this simple, fairly informal look at Clojure startup time the primary problem is that many classes are loaded that are not used. This is probably to support the dynamic capabilities of Clojure, as functions like `eval` cannot know what classes are needed (see e.g. [this post](http://blog.fogus.me/2011/07/29/compiling-clojure-to-javascript-pt-2-why-no-eval/)).

My simplistic approach to this says we can speed up Clojure bootstrap time in two ways: doing less or doing it more quickly.

Doing less means not loading classes that aren't needed or not loading them until they are needed. The core namespace could be modularized, so that only the parts that are used are loaded. Loading of parts could be done lazily, to transfer the time used from startup time to execution time. Or before generating code a dependency tree could generated and "shaken" to remove unneeded dependencies so that they don't exist in the resulting code at all.

Doing it more quickly means making `clojure.core` load quickly. Removing metadata could give us some small gains. Vars could possibly be [replaced with a lighter-weight construct](http://dev.clojure.org/pages/viewpage.action?pageId=950293). The `clojure.core` namespace could maybe be serialized in some fashion so that loading it takes much less time.

What's my stake in this? I am interested in finding ways to make Clojure work better for Android development as a master's thesis project at Aalto University. I have been communicating with Daniel Solano Gómez about some of this and trying to fully understand the problem. I will also be trying to come up with a better set of benchmarks by which to measure improvements to this problem. I hope we can make Clojure a viable solution for Android development.

A few questions related to this that I am thinking about:

* Are larger Clojure programs even slower to start up?
* Is there an existing set of benchmarks that could be used to measure this problem?
* How do other languages like Scala handle this problem?
* Does solving slow startup require losing dynamic features?
* What Clojure features would need to be dropped to create a static runtime?
* How much improvement could be gained by simply not loading unused code?

I would love to hear any ideas or feedback. 

-----

<a name="footnotes"></a>
### Footnotes

* [Desktop profiling setup](https://github.com/nicholaskariniemi/thesis_experiments/tree/master/clojure_jvm/profiling)
* [Android profiling setup](https://github.com/nicholaskariniemi/thesis_experiments/tree/master/clojure_dalvik/profiling)

-----

Edit 2014-2-26: Corrected which external functions are defined in clojure.core.
Edit 2014-3-02: Corrected Daniel Solano Gómez's name.

-----
