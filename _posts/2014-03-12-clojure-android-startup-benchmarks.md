---
title: Clojure on Android Startup Benchmarks (including ART)
layout: post
---

How slowly do Clojure on Android apps start? Here are a few benchmarks.

<img class="blog-img" src="/img/clojure_android_startup_benchmarks.png"></img>

The Java app is a simple Hello World application written in Java that displays the text "Hello World". The minimal app is an equivalent written entirely in Clojure. The lein-droid app is essentially the [lein-droid](https://github.com/clojure-android/lein-droid) default template app. Lein-droid provides a number of nice tools for developing Clojure on Android apps.

Each app was run on the Nexus 5 and Nexus 7 devices using both the standard Dalvik VM and the newer ART VM. The lein-droid app does not run on ART because of some neko or Clojure incompatibility. I was hoping ART might improve start times but at least in these tests it made them slightly worse.

These show about the fastest a Java or Clojure Android application can start. Non-trivial apps would probably take longer to start, although one could always present a loading screen in about the measured times and then load the rest of the app.

The goal of these benchmarks is to provide a consistent way to compare the start time of different Clojure implementations. How have my changes affected Clojure on Android startup time? Run the benchmarks and see. At least that's what I plan to do.

Startup time is measured from when logcat displays the "START" message indicating the application launch activity has been launched to when the "Display" message indicates the app main activity has been displayed. Each app is run ten times for each device and the results are averaged. Before testing each app the phone is restarted and left alone for two minutes to allow phone booting to complete. The process is automated.

Check out the [benchmark summary spreadsheet](https://docs.google.com/spreadsheets/d/1HxiNNY7RPLYYSXwiAbqRhU5YtgFO7_njIp-z_hJTL68/edit?usp=sharing) and the [benchmarking setup](https://github.com/nicholaskariniemi/clojure_android_startup_benchmarks/tree/e95d7eea2ac714af4257001ef0ded548272ba724). Tell me if I'm doing something foolishly.
