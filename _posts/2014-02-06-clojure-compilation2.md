---
title: "Clojure Compilation: Full Disclojure"
subtitle: "Or What Does It Mean to Be Dynamic (and What Are the Costs)?"
layout: post
manual_id: "/clojure-compilation2"
---

The previous post looked at how a Hello World Clojure app is compiled. We saw how a Java source file compiles to a single Java class file while a comparable Clojure source file compiles to four class files. This is a lie.

The Java example is a complete example because it can be run directly using the JVM with the `java` command. The Clojure example is not complete. It cannot be run directly by the JVM because it depends on the availability of the `clojure.core` library.

So what does a complete Clojure example look like? Let's make one modification to the Hello World program from the last post:

```clojure
(ns hello.core
  (:gen-class))

(defn -main [& args]
  (println "Hello world"))
```

The modification is to add `:gen-class` to the `hello.core` namespace. This tells the Clojure compiler to produce a Java class file by the same name that the JVM can run directly. This time, instead of compiling using `lein compile`, let's see what gets packaged into a complete independent Clojure program. With `lein uberjar`, leiningen packages all of our dependencies into a single JAR file that can be executed with the `java` command.

```
$ lein uberjar
Compiling hello.core
Created target/uberjar/hello-0.1.0-SNAPSHOT.jar
Created target/hello-0.1.0-SNAPSHOT-standalone.jar
$ cd target/
$ java -jar hello-0.1.0-SNAPSHOT-standalone.jar 
Hello world
```

We were able to greet the world using this JAR file, so it worked. Now, what do you think is in that JAR? Here's what you might expect. You might expect to see the same compiled files from the previous post, four of them. You might expect an additional class file named `core.class` as the result of our `:gen-class` keyword. You might expect files for the forms defined in the `clojure.core` namespace: `in-ns`, `fn*`, `refer`, `pushThreadBindings`, `popThreadBindings`, `equals`, `quote`, `runInTransaction`, `commute`, `*loaded-libs*`, `conj`, `println`, and `def`. These are all from the macro-expansion of the previous example. In addition, the macro expansion used the following forms defined in Java, so these will probably each have a file: `clojure.lang.Var`, `clojure.lang.Compiler/LOADER`, and `clojure.lang.LockingTransaction`. Finally each of these classes might have their own dependencies.

This is getting to be a long list but for the most part it should be a complete list of the dependencies required for our AOT-compiled Hello World Clojure program. How many files are we expecting to see? Maybe 20-40?

Now let's open up that JAR. How many files do we find? 3122.

<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 400px;" src="/img/complete_hello_world.svg" />
<div class="blog-img-label">Complete Hello World</div>

META-INF has some files for the JAR format that we won't get in to. Both the hello directory and the clojure directory contain Clojure source code, which doesn't affect execution. Delete it and run the JAR if you don't believe me. The hello directory contains one extra file named `core.class` as expected. That all seems good and normal.

But what are all of these extra files in the clojure directory? Ignoring the source files, it contains 2096 files. From the names of the files, we can see that many of these correspond to functions in the `clojure.core` namespace. In fact, there is probably a corresponding file for every single function defined in the Clojure language.

This is absurd, you're thinking. Why does my Hello World program need every function defined in the language?

The answer is that Clojure is a *dynamic* language. Clojure has a little function named `eval`, among other similar functions. You can use this function to *dynamically* (i.e. at run time) read and evaluate arbitrary code. You need every function in case your arbitrary code uses one of them. A dynamic language allows you to do crazy and powerful things, like pausing your code, pulling up a REPL to inspect the state of your code, and continuing execution. You can define and re-define your entire program while running it, like replacing the engine of a sports car while driving. It means short feedback loops. Compiler and language and program and developer can interact in strange and wonderful ways, united in one rapturous expression of Turing power.

But, but... I don't want all that. I don't need it, except for development. I'm AOT-compiling my program. It doesn't use `eval`. My program runs on Android, where dynamic compilation is not possible in the same way. Can't I just delete all of those extra files and make my program smaller and run faster?

Yes and no. Yes, you can delete all of the extra class files. Your program won't notice, as it doesn't use them and the JVM only loads class files when needed. But you're still paying the cost. More on that later.
