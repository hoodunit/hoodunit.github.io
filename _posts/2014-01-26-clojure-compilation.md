---
title: "Clojure Compilation: Parenthetical Prose to Bewildering Bytecode"
layout: post
---

How does Clojure compilation work? What black magic is needed to transform elegant parenthetical prose into binary instructions executed by a processor?

Let's start with a simple question. Is Clojure compiled or interpreted? Someone asked this same question [on Stack Overflow](http://stackoverflow.com/questions/5669933/is-clojure-compiled-or-interpreted). The answer? It's complicated. Clojure code can be either dynamically loaded or AOT (ahead of time) compiled to Java bytecode. For loading Clojure code dynamically, the process looks like this:

<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 600px;" src="/img/dynamic_compilation.svg" />
<div class="blog-img-label">Clojure Dynamic Compilation</div>

For AOT compilation on the JVM, it looks more like this:

<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 600px;" src="/img/AOT_compilation.svg" />
<div class="blog-img-label">Clojure AOT Compilation</div>

So AOT compilation looks a lot like normal compilation: the code is compiled and then the compiled code is executed. For dynamic compilation the picture is a little hazier. It turns out it also uses an intermediate bytecode representation, but this is generated and used at run time without being saved to a file.

In many respects the process seems to be the same, but let's ignore dynamic compilation for the time being and look at AOT compilation. We're also talking only about Clojure compilation for the JVM. For AOT compilation the compiler must produce bytecode files, which are executed on the Java Virtual Machine. What do these bytecode files look like and how does the JVM execute them? Let's take a look.

### Java Compilation

The Java Virtual Machine does not understand Java but only Java bytecode. What is Java bytecode? Java bytecode is a collection of class files. Each class file contains a description of a class and the methods defined in the class, which have been translated to Java bytecode instructions. It looks like this:

<img class="blog-img" style="width: 250px" src="/img/class_file.svg" />
<div class="blog-img-label">Java Class File</div>

Magic is the hexadecimal string "0xCAFEBABE", which just provides an easy way to see that the file is a Java class file. The next items tell the Java class file version, such as J2SE 7. The constant pool is a data structure containing references to classes, interfaces, and other constants used in the class. Following the constant pool is information about the class such as whether it is a class or an interface, whether it is public or private, its name, and the name of classes or interfaces it extends or implements. Following this are the fields (class or instance variables), methods, and attributes of the class. The code for methods is represented with Java bytecode instructions.

The gory details are described in the [JVM specification](http://docs.oracle.com/javase/specs/jvms/se7/html/jvms-4.html).

So how does the JVM load and execute this code? The JVM *loads*, *links*, and *initializes* class files. Note that the class file information does not have to be stored in a file, but can also be downloaded over the network or generated on the fly. The last point is important for dynamic Clojure compilation.

<img class="blog-img" src="/img/loading_linking_init.gif" />
<div class="blog-img-label">Class Loading Process</div>

<center>Source: [Inside the Java Virtual Machine](http://www.artima.com/insidejvm/ed2/lifetypeP.html)</center>

*Loading* is finding a binary representation of a class and creating an internal JVM representation of the class (or interface).

*Linking* is adding this class to the current state of the JVM runtime so that it can be executed. The linking process also verifies that the representation of the class or interface is structurally correct and prepares static fields by creating them and setting them to default values. The linking step may also resolve symbolic references to the actual classes or interfaces that contain them.

*Initialization* is executing the \<clinit\> method of the class so that the class is ready to be used. The \<clinit\> method is the class or interface initialization method, kind of like class constructors (labeled in the JVM as \<init\>) are instance initialization methods.

Classes are initialized only when needed. A class is initialized at JVM startup if it is the main specified class. Classes are also initialized when they are referenced using JVM instructions like `new` or static method invocations, or when a sub-class is initialized. When a class needs to be initialized, it must first be loaded and linked, though these steps may occur at other times.

### Java Compilation Hello World

That's all nice, but what does it mean? What does this look like in practice? Suppose we have the following Hello World example in the Java file Hello.java:

```java
public class Hello {
    public static void main(String[] args){
        System.out.println("Hello world");
    }
}
```

If we compile this using `javac` it generates a single class file Hello.class with the following contents. Here we interpret the generated code with `javap`.

```
public class Hello extends java.lang.Object
minor version: 0
major version: 50

Constant pool:
const #1 = Method	#6.#15;         // java/lang/Object."<init>":()V
const #2 = Field	#16.#17;	    // java/lang/System.out:Ljava/io/PrintStream;
const #3 = String	#18;	        // Hello world
const #4 = Method	#19.#20;	    // java/io/PrintStream.println:(Ljava/lang/String;)V
const #5 = class	#21;            // Hello
const #6 = class	#22;            // java/lang/Object
const #7 = Asciz	<init>;
const #8 = Asciz	()V;
const #9 = Asciz	Code;
const #10 = Asciz	LineNumberTable;
const #11 = Asciz	main;
const #12 = Asciz	([Ljava/lang/String;)V;
const #13 = Asciz	SourceFile;
const #14 = Asciz	Hello.java;
const #15 = NameAndType	#7:#8;      // "<init>":()V
const #16 = class	#23;	        // java/lang/System
const #17 = NameAndType	#24:#25;    // out:Ljava/io/PrintStream;
const #18 = Asciz	Hello world;
const #19 = class	#26;            // java/io/PrintStream
const #20 = NameAndType	#27:#28;    // println:(Ljava/lang/String;)V
const #21 = Asciz	Hello;
const #22 = Asciz	java/lang/Object;
const #23 = Asciz	java/lang/System;
const #24 = Asciz	out;
const #25 = Asciz	Ljava/io/PrintStream;;
const #26 = Asciz	java/io/PrintStream;
const #27 = Asciz	println;
const #28 = Asciz	(Ljava/lang/String;)V;

{
  public Hello();
    aload_0
    invokespecial	#1; // Method java/lang/Object."<init>":()V
    return

  public static void main(java.lang.String[]);
    getstatic #2;     // Field java/lang/System.out:Ljava/io/PrintStream;
    ldc	#3;           // String Hello world
    invokevirtual #4; // Method java/io/PrintStream.println:(Ljava/lang/String;)V
    return
}
```

Or fitting this back to our diagram:

<img class="blog-img" style="width: 250px" src="/img/java_helloworld.svg" />
<div class="blog-img-label">Java Hello World Class File</div>

In this example our main method was compiled to the bytecode equivalent of the following:

```java
public static void main(java.lang.String[]);
  getstatic #2;     // Get static field out from java.lang.System
  ldc #3;           // Push constant "Hello world" to stack
  invokevirtual #4; // Invoke println method of java.io.PrintStream
  return
```

The JVM uses a stack to hold operands for instructions. In this example to print "Hello world" we fetch the the static field [java.lang.System.out](http://docs.oracle.com/javase/7/docs/api/java/lang/System.html#out), which returns an object of type PrintStream, and push its value to the stack. Then we push our constant string "Hello world" to the stack. Finally we call invokevirtual with constant "println" to execute [PrintStream.println](http://docs.oracle.com/javase/7/docs/api/java/io/PrintStream.html#println%28java.lang.String%29) and print our message.

### Java Compilation Summary

The JVM loads and executes class files. For Java each class file is a straightforward representation of a Java class. The JVM loads, links, and initializes these classes at run time when needed. The execution itself usually uses a form of just-in-time (JIT) compilation, where Java bytecode is binary translated to machine code just before it is needed.

A Clojure compiler must do a similar trick as a Java compiler. It must take a set of Clojure source code files and produce a corresponding set of class files that the JVM understands.

### AOT Clojure Compilation: Hello World

How does the Clojure compiler convert Clojure source to Java bytecode? Let's take a look at an example. Suppose we define a hello world Clojure file as follows:

```clojure
(ns hello.core)

(defn -main [& args]
  (println "Hello world"))
```

This does basically the same thing as our Java example. It defines a namespace hello.core containing a function -main, which calls println to greet the world. What Java bytecode output might you expect for this? You might expect something like the Java class file above: a single class file called core.class, named after the namespace, with a single static main method that does the printing.

Let's test it. We create a Clojure application called "hello" using Leiningen and modify the project configuration to specify AOT compilation. We run `lein compile` to compile the code. What was produced? 

```
$ lein compile
Compiling hello.core
$ ls -1 target/classes/hello/
core$fn__16.class
core__init.class
core$loading__4910__auto__.class
core$_main.class
```

This created not one class file, not two, but four class files. What is going on here? Where did all of that code come from?

### AOT: Clojure Source Code

The first place to look is back at the Clojure source code.

```clojure
(ns hello.core)

(defn -main [& args]
  (println "Hello world"))
```

That doesn't do much. But wait, Clojure has macros. Let's try macro-expanding the code once:

```clojure
(do
  (clojure.core/in-ns 'hello.core)
  (clojure.core/with-loading-context
    (clojure.core/refer 'clojure.core))
  (if (.equals 'hello.core 'clojure.core)
    nil
    (do
      (clojure.core/dosync
        (clojure.core/commute
          @#'clojure.core/*loaded-libs*
          clojure.core/conj
          'hello.core))
      nil)))

(def -main
  (clojure.core/fn 
    ([& args]
      (println "Hello world"))))
```

That didn't remove all of the macros. Here's the full macro expansion:

```clojure
(do
  (clojure.core/in-ns 'hello.core)
  ((fn*
    loading__4910__auto__
    ([]
       (. clojure.lang.Var
          (clojure.core/pushThreadBindings
           {clojure.lang.Compiler/LOADER
            (. (. loading__4910__auto__ getClass) getClassLoader)}))
       (try
         (clojure.core/refer 'clojure.core)
         (finally
           (. clojure.lang.Var (clojure.core/popThreadBindings)))))))
  (if (. 'hello.core equals 'clojure.core)
    nil
    (do
      (. clojure.lang.LockingTransaction
         (clojure.core/runInTransaction
          (fn*
           ([]
              (clojure.core/commute
               @#'clojure.core/*loaded-libs*
               clojure.core/conj
               'hello.core)))))
      nil)))

(def -main 
  (fn* ([& args]
    (println "Hello world"))))
```

What are all of those quotes and @ symbols? That doesn't look very Lispy. Oh yeah. Reader macros. Let's remove those, too:

```clojure
(do
  (clojure.core/in-ns (quote hello.core))
  ((fn*
    loading__4910__auto__
    ([]
       (. clojure.lang.Var
          (clojure.core/pushThreadBindings
           {clojure.lang.Compiler/LOADER
            (. (. loading__4910__auto__ getClass) getClassLoader)}))
       (try
         (clojure.core/refer (quote clojure.core))
         (finally
           (. clojure.lang.Var (clojure.core/popThreadBindings)))))))
  (if (. (quote hello.core) equals (quote clojure.core))
    nil
    (do
      (. clojure.lang.LockingTransaction
         (clojure.core/runInTransaction
          (fn*
           ([]
              (clojure.core/commute
               (deref (var clojure.core/*loaded-libs*))
               clojure.core/conj
               (quote hello.core))))))
      nil)))

(def -main 
  (fn* ([& args]
    (println "Hello world"))))
```

It doesn't look so simple anymore, does it?

### Generated files

If we closely compare the fully expanded Clojure code and the generated files we notice a few things. Three of the generated class files correspond to functions. One is for the -main function and the other two are for the anonymous functions within the namespace macro. The final class is a loader class for the core namespace (or hello/core.clj file, as each namespace corresponds to a file).

```
core__init.class // core.clj loader class
  public static {}
  public load()
  public static void __init0()

core$_main.class // -main function
  public static {}
  public hello.core$_main()
  public java.lang.Object doInvoke(java.lang.Object)
  public int getRequiredArity()

core$fn__16.class // dosync anonymous function
  public static {}
  public hello.core$fn__16()
  public java.lang.Object invoke()

core$loading__4910__auto__.class // with-loading-context anonymous function
  public static {}
  public hello.core$loading__4910__auto__()
  public java.lang.Object invoke()
```

Clojure has first-class functions, which can be passed around like any other variable. The JVM doesn't support first-class functions, but recognizes only data represented as class files. Clojure seems to use the same approach as other languages like Scala for representing functions. Each function is separated into its own class with a method to invoke the function here named `doInvoke` for a normal function and `invoke` for the anonymous functions.

We'll take a look at each of these files in turn.

### core__init: Loader class for core namespace

According to [Clojure.org documentation](http://clojure.org/compilation), for each namespace a loader class with an __init suffix is created. This is the loader class for the hello.core namespace.

```java
package hello;

import clojure.lang.AFn;
import clojure.lang.Compiler;
import clojure.lang.IFn;
import clojure.lang.IPersistentMap;
import clojure.lang.Keyword;
import clojure.lang.LockingTransaction;
import clojure.lang.PersistentList;
import clojure.lang.RT;
import clojure.lang.Symbol;
import clojure.lang.Var;
import java.util.Arrays;
import java.util.concurrent.Callable;

public class core__init
{
  public static final Var const__0;
  public static final AFn const__1;
  public static final AFn const__2;
  public static final Var const__3;
  public static final Keyword const__4;
  public static final Keyword const__5;
  public static final Object const__6;
  public static final Keyword const__7;
  public static final Object const__8;
  public static final Keyword const__9;
  public static final Object const__10;
  public static final AFn const__11;

  public static void load() {
    if (((Symbol)const__1).equals(const__2)){
       tmpTernaryOp = null;
       break label67;
       ((IFn)new core.loading__4910__auto__()).invoke();
    } else {
      LockingTransaction.runInTransaction((Callable)new core.fn__16());
    }
    label67: tmp70_67 = const__3;
    tmp70_67.setMeta((IPersistentMap)const__11);
    tmp70_67.bindRoot(new core._main());
  }

  public static void __init0() {
    const__0 = (Var)RT.var("clojure.core", "in-ns");
    const__1 = (AFn)Symbol.intern(null, "hello.core");
    const__2 = (AFn)Symbol.intern(null, "clojure.core");
    const__3 = (Var)RT.var("hello.core", "-main");
    const__4 = (Keyword)RT.keyword(null, "file");
    const__5 = (Keyword)RT.keyword(null, "column");
    const__6 = Integer.valueOf(1);
    const__7 = (Keyword)RT.keyword(null, "line");
    const__8 = Integer.valueOf(3);
    const__9 = (Keyword)RT.keyword(null, "arglists");
    const__10 = PersistentList.create(Arrays.asList(new Object[] {
      RT.vector(new Object[] {
        Symbol.intern(null, "&"),
        Symbol.intern(null, "args")
      })
    }));
    const__11 = (AFn)RT.map(new Object[] {
      RT.keyword(null, "arglists"),
      PersistentList.create(Arrays.asList(new Object[] {
        RT.vector(new Object[] {
          Symbol.intern(null, "&"), 
          Symbol.intern(null, "args")
        })
      })), 
      RT.keyword(null, "column"),
      Integer.valueOf(1),
      RT.keyword(null, "line"),
      Integer.valueOf(3),
      RT.keyword(null, "file"),
      "hello/core.clj"
    });
  }

  static
  {
    __init0();
    Compiler.pushNSandLoader(Class.forName("hello.core__init").getClassLoader());
    try
    {
      load();
      Var.popThreadBindings();
    }
    finally
    {
      Var.popThreadBindings();
      throw finally;
    }
  }
}
```

When the class is loaded, the static initializer method is called. This method in turn invokes the __init0 and load methods. The _init0 method sets up a bunch of variables with calls to `RT.var`, `RT.keyword`, and `Symbol.intern`. 

It also creates a map containing metadata for the -main function. The "file", "column", "line" values tell the location of the -main function in the core namespace file. The "arglists" identifier gives the arguments that the function accepts. All of this is stored in a map, which would be represented in Clojure as follows:

```clojure
{:arglists ["&" "args"]
 :column 1
 :line   3
 :keyword "hello/core.clj"}
```

After calling __init0, the static initializer calls the load method within a block executing [Compiler.pushNSandLoader](https://github.com/clojure/clojure/blob/master/src/jvm/clojure/lang/Compiler.java) beforehand and [Var.popThreadBindings](https://github.com/clojure/clojure/blob/master/src/jvm/clojure/lang/Var.java) afterwards. What it does is roughly equivalent to the following Clojure code, [as presented by Daniel Solano Gómez](http://www.deepbluelambda.org/programming/clojure/how-clojure-works-a-simple-namespace).

```clojure
(bind [clojure.core/*ns*         nil
       clojure.core/*fn-loader*  loader
       clojure.core/*read-eval*  true]
  (greeter.hello_init/load))
```

Finally, the load method performs the actual code of the ns function i.e. it does the equivalent of the following code:

```clojure
(do
  (clojure.core/in-ns (quote hello.core))
  (loading__4910__auto__)
  (if (. (quote hello.core) equals (quote clojure.core)) nil
    (do
      (. clojure.lang.LockingTransaction
         (clojure.core/runInTransaction
          (fn__16))))
      nil)))
```

Remember that our two anonymous functions have been deferred to separate files.

### core$_main: main function

```java
package hello;

import clojure.lang.IFn;
import clojure.lang.RT;
import clojure.lang.RestFn;
import clojure.lang.Var;

public final class core$_main extends RestFn
{
  public static final Var const__0 = (Var)RT.var("clojure.core", "println");

  public Object doInvoke(Object args) {
    return ((IFn)const__0.getRawRoot()).invoke("Hello world");
  }


  public int getRequiredArity()
  {
    return 0;
  }
}
```

The `-main` function class file is quite simple. It fetches the root binding for the `clojure.core/println` var, casts it as a function, and invokes it with our constant string `"Hello world"`.

In addition it has a method `getRequiredArity`. A few simple experiments show that this returns the number of fixed arguments that a variadic function take. In this case our main method does not have any fixed arguments, so it returns zero.

For a better comparison with the Java example, let's look at a more direct interpretation of the bytecode with `javap`:

```
public final class hello.core$_main extends clojure.lang.RestFn
  minor version: 0
  major version: 49
  flags: ACC_PUBLIC, ACC_FINAL, ACC_SUPER

Constant pool:
   #1 = Utf8 hello/core$_main
   #2 = Class #1                   //  hello/core$_main
   #3 = Utf8 clojure/lang/RestFn
   #4 = Class #3                   //  clojure/lang/RestFn
   #5 = Utf8 core.clj
   #6 = Utf8 const__0
   #7 = Utf8 Lclojure/lang/Var;
   #8 = Utf8 <clinit>
   #9 = Utf8 ()V
  #10 = Utf8 clojure.core
  #11 = String #10                 //  clojure.core
  #12 = Utf8 println
  #13 = String #12                 //  println
  #14 = Utf8 clojure/lang/RT
  #15 = Class #14                  //  clojure/lang/RT
  #16 = Utf8 var
  #17 = Utf8 (Ljava/lang/String;Ljava/lang/String;)Lclojure/lang/Var;
  #18 = NameAndType #16:#17        //  var:(Ljava/lang/String;Ljava/lang/String;)
                                   //  Lclojure/lang/Var;
  #19 = Methodref #15.#18          //  clojure/lang/RT.var:(Ljava/lang/String;
                                   //  Ljava/lang/String;)Lclojure/lang/Var;
  #20 = Utf8 clojure/lang/Var
  #21 = Class #20                  //  clojure/lang/Var
  #22 = NameAndType #6:#7          //  const__0:Lclojure/lang/Var;
  #23 = Fieldref #2.#22            //  hello/core$_main.const__0:Lclojure/lang/Var;
  #24 = Utf8 <init>
  #25 = NameAndType #24:#9         //  "<init>":()V
  #26 = Methodref #4.#25           //  clojure/lang/RestFn."<init>":()V
  #27 = Utf8 doInvoke
  #28 = Utf8 (Ljava/lang/Object;)Ljava/lang/Object;
  #29 = Utf8 getRawRoot
  #30 = Utf8 ()Ljava/lang/Object;
  #31 = NameAndType #29:#30        //  getRawRoot:()Ljava/lang/Object;
  #32 = Methodref #21.#31          //  clojure/lang/Var.getRawRoot:()Ljava/lang/Object;
  #33 = Utf8 clojure/lang/IFn
  #34 = Class #33                  //  clojure/lang/IFn
  #35 = Utf8 Hello world
  #36 = String #35                 //  Hello world
  #37 = Utf8 invoke
  #38 = NameAndType #37:#28        //  invoke:(Ljava/lang/Object;)Ljava/lang/Object;
  #39 = InterfaceMethodref #34.#38 //  clojure/lang/IFn.invoke:(Ljava/lang/Object;)
                                   //  Ljava/lang/Object;
  #40 = Utf8 this
  #41 = Utf8 Ljava/lang/Object;
  #42 = Utf8 args
  #43 = Utf8 getRequiredArity
  #44 = Utf8 ()I
  #45 = Utf8 Code
  #46 = Utf8 LineNumberTable
  #47 = Utf8 LocalVariableTable
  #48 = Utf8 SourceFile
  #49 = Utf8 SourceDebugExtension
{
  public static final clojure.lang.Var const__0;
    flags: ACC_PUBLIC, ACC_STATIC, ACC_FINAL

  public static {};
    flags: ACC_PUBLIC, ACC_STATIC

    ldc           #11                 // String clojure.core
    ldc           #13                 // String println
    invokestatic  #19                 // Method clojure/lang/RT.var:(Ljava/lang/String;
                                      // Ljava/lang/String;)Lclojure/lang/Var;
    checkcast     #21                 // class clojure/lang/Var
    putstatic     #23                 // Field const__0:Lclojure/lang/Var;
    return        

  public hello.core$_main();
    flags: ACC_PUBLIC

    aload_0       
    invokespecial #26                 // Method clojure/lang/RestFn."<init>":()V
    return        

  public java.lang.Object doInvoke(java.lang.Object);
    flags: ACC_PUBLIC

    getstatic     #23                 // Field const__0:Lclojure/lang/Var;
    invokevirtual #32                 // Method clojure/lang/Var.getRawRoot:
                                      // ()Ljava/lang/Object;
    checkcast     #34                 // class clojure/lang/IFn
    ldc           #36                 // String Hello world
    invokeinterface #39,  2           // InterfaceMethod clojure/lang/IFn.invoke:
                                      // (Ljava/lang/Object;)Ljava/lang/Object;
    areturn       

  public int getRequiredArity();
    flags: ACC_PUBLIC

    iconst_0      
    ireturn       
}
```

We notice two key differences when comparing this to the compiled Java Hello World file:

* Clojure uses an extra level of indirection for calling the print function. Java fetches `java.lang.System.out` and calls `invokevirtual` to print. Clojure loads the var pointing to the function, calls `invokevirtual` to get the function value, casts it to a function, and calls `invokeinterface` to print.
* Clojure does more setup work. Java just loads `java.lang.System.out` directly. Clojure sets up a var with its root binding pointing to the `clojure.core/println` function beforehand in the static initializer.

### core$loading\_\_4910\_\_auto\_\_: with-loading-context anonymous function

```java
// core$loading__4910__auto__.class

package hello;

import clojure.lang.AFn;
import clojure.lang.AFunction;
import clojure.lang.Associative;
import clojure.lang.Compiler;
import clojure.lang.IFn;
import clojure.lang.RT;
import clojure.lang.Symbol;
import clojure.lang.Var;

public final class core$loading__4910__auto__ extends AFunction
{
  public static final Var const__0 = (Var)RT.var("clojure.core", "refer");
  public static final AFn const__1 = (AFn)Symbol.intern(null, "clojure.core");

  public Object invoke() {
    Var.pushThreadBindings((Associative)RT.mapUniqueKeys(new Object[] {
      Compiler.LOADER, ((Class)getClass()).getClassLoader()
    }));
    Object localObject1;
    try {
      localObject1 = ((IFn)const__0.getRawRoot()).invoke(const__1);
      Var.popThreadBindings();
    } finally {
      Var.popThreadBindings();
    }
    return localObject1;
  }
}
```

This class corresponds to the expansion of `with-loading-context` from the `ns` macro:

```clojure
([] (. clojure.lang.Var
       (clojure.core/pushThreadBindings
         {clojure.lang.Compiler/LOADER
           (. (. loading__4910__auto__ getClass) getClassLoader)}))
    (try
      (clojure.core/refer (quote clojure.core))
      (finally
        (. clojure.lang.Var (clojure.core/popThreadBindings)))))
```

The compiled code seems to be a straightforward interpretation of the original code. Clojure uses a custom class loader (defined in [DynamicClassLoader](https://github.com/clojure/clojure/blob/master/src/jvm/clojure/lang/DynamicClassLoader.java)) instead of the default JVM bootstrap loader. According to the [JVM specification](http://docs.oracle.com/javase/specs/jvms/se7/html/jvms-5.html#jvms-5.3), "applications employ user-defined class loaders in order to extend the manner in which the Java Virtual Machine dynamically loads and thereby creates classes." For dynamic compilation it is clear that a custom class loader is necessary. Offhand it seems like AOT compilation could use the default bootstrap loader, but there may be good reasons for using a custom class loader that I'm not familiar with.

### core$fn\_\_16: dosync anonymous function

```java
// core$fn__16.class

package hello;

import clojure.lang.AFn;
import clojure.lang.AFunction;
import clojure.lang.IFn;
import clojure.lang.RT;
import clojure.lang.Symbol;
import clojure.lang.Var;

public final class core$fn__16 extends AFunction
{
  public static final Var const__0 = (Var)RT.var("clojure.core", "commute");
  public static final Var const__1 = (Var)RT.var("clojure.core", "deref");
  public static final Var const__2 = (Var)RT.var("clojure.core", "*loaded-libs*");
  public static final Var const__3 = (Var)RT.var("clojure.core", "conj");
  public static final AFn const__4 = (AFn)Symbol.intern(null, "hello.core");

  public Object invoke() {
    return ((IFn)const__0.getRawRoot())
      .invoke(((IFn)const__1.getRawRoot()).invoke(const__2),
              const__3.getRawRoot(),
              const__4);
  }
}
```

And here's the corresponding source code within the expansion of `dosync` in the `ns` form:

```clojure
(fn* ([] (clojure.core/commute
           (deref (var clojure.core/*loaded-libs*))
           clojure.core/conj
           (quote hello.core))))
```

This class file fetches and invokes `clojure.core/commute` with the given arguments. Note again the setup work and indirection. Four Vars are created and one Symbol. To invoke the `commute` function, it gets the root binding of the `commute` var declared earlier and invokes it. Similarly the root binding of `deref` is fetched and invoked and the root binding of `conj` is fetched.

### Summary

This post looked at Java compilation and Clojure AOT compilation to try and understand the Clojure compilation better. What did we learn?

* The JVM understands Java class files, which consist of class file info, a constant pool, and class info and compiled methods.
* The JVM loads, links, and initializes class files dynamically when needed.
* Java Hello World compiles to a single, simple class file.
* Clojure Hello World compiles to four class files with some interesting things happening in the namespace macro.
* A few key differences between compiled Java and Clojure:
  * Clojure functions are compiled to separate class files.
  * Clojure uses a custom class loader.
  * Clojure does more setup work, creating Vars to point to each function a class file needs (among other things).
  * Clojure calls functions indirectly, first fetching the value of a Var and then invoking it.
