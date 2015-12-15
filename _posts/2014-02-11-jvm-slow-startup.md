---
title: "The (Clojure) \"JVM Slow Startup Time\" Myth"
layout: post
---

> By far the largest subset of performance-related complaints were about JVM startup time. Phil Hagelberg has also reported that this is one of, perhaps the highest, complaint of leiningen users as well. In particular, it seems from reading between the lines that at least some of these complaints are from users developing command line scripts or tools. JVM startup time is never going to go away (unless we ultimately have a natively compiled Clojure), but there are likely still things that can be done to decrease Clojure loading time or better control the loading of code.
>
> \- [Alex Miller's analysis of the State of Clojure survey](http://tech.puredanger.com/2013/12/01/clj-problems/)

One of the most frequent complaints in the most recent State of Clojure survey was about Clojure's "slow JVM startup time". When asked [what is Clojure's most glaring weakness/blind spot/problem](http://polldaddy.com/share/s38666b2bdecfb3d0f76b97a0846bbf0d1111669078/results/4199926), many responded like this:

> slow start-up time of JVM

> JVM startup time still sucks

> usefulness in many potential applications is limited by the jvm's startup time

> that damn JVM startup time

> JVM startup overhead

> JVM bootstrap time

The [same type](http://stackoverflow.com/questions/6016440/clojure-application-startup-performance?rq=1) of [comments](http://stackoverflow.com/questions/2531616/why-is-the-clojure-hello-world-program-so-slow-compared-to-java-and-python?rq=1) show up on StackOverflow. There are several proposed solutions in these kinds of posts: use lazy loading, run a persistent VM with Nailgun or Drip, use the "client VM" for Java, AOT compile and so forth. 

Even [Java users complain](http://stackoverflow.com/questions/844143/why-is-the-jvm-slow-to-start) about [slow JVM startup time](http://stackoverflow.com/questions/4056280/anyway-to-boost-java-jvm-startup-speed). Research [shows](http://www.codeproject.com/Articles/92812/Benchmark-start-up-and-system-performance-for-Net#heading0002) that the JVM starts more slowly than other runtimes. JVM startup time is clearly a huge problem for Clojure development today.

Or is it? How long does the JVM actually take to start up? Let's try running a Java Hello World app:

```java
// Hello.java
public class Hello {
    public static void main(String[] args){
        System.out.println("Hello world");
    }
}
```

```
$ time java Hello
Hello world
0.04user 0.01system 0:00.12elapsed 43%CPU (0avgtext+0avgdata 15436maxresident)k
29672inputs+64outputs (82major+3920minor)pagefaults 0swaps
```

40 milliseconds. That's not very long. Maybe I have a faster computer than most people, although I will say that this computer is not a powerhouse. Maybe Java is running a persistent VM in the background to give this performance. In any event, this seems to be a solid performance. Let's try using the same Java installation to run AOT-compiled Clojure code.

```
$ time java -jar hello-0.1.0-SNAPSHOT-standalone.jar
Hello world
1.21user 0.04system 0:00.95elapsed 131%CPU (0avgtext+0avgdata 67700maxresident)k
0inputs+64outputs (0major+19581minor)pagefaults 0swaps
```

1.21 seconds! That's **30** times as long! To put it into perspective:

<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 500px;" src="/img/jvm_vs_clojure.svg" />
<div class="blog-img-label">JVM Versus Clojure</div>

Let's note a few things here. I was using the SAME Java installation, so there shouldn't be any differences due to persistent VMs or client VMs. The code was AOT-compiled.

The situation is worse on Android. The scale of the problem is roughly the same, but since Android apps already start much more slowly the problem is exacerbated.

<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 500px;" src="/img/dalvik_vs_clojure.svg" />
<div class="blog-img-label">Dalvik Versus Clojure</div>

This compares a Java Hello World app from the Android tutorials and a Clojure version using a release compilation of lein-droid on my Nexus 4. The point is not to get exact measurements, but to show the scale of the problem.

Conclusion: JVM startup time is not a problem. **Clojure startup time** is. But why? That's for another post.

-----
Update 2014-2-18: I did some more testing and I was able to get Clojure on Android start times down to about 1.7 seconds by removing the lein-droid default splash screen and neko code (and using a Nexus 5 phone). This is about 6.8x slower than the standard Android Hello World startup. See the [original benchmark](https://github.com/nicholaskariniemi/thesis_experiments/tree/master/clojure_dalvik/hello_world) and the [updated benchmark](https://github.com/nicholaskariniemi/thesis_experiments/tree/master/clojure_dalvik/profiling).
