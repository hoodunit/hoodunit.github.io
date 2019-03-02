---
title: "Refactoring 30000 lines of JS with types"
layout: post
---
{% include base.html %}

30000 lines of client-side JavaScript. No tests. Two difficult TV deployment platforms with poor tooling. Strong dependencies on poorly documented external APIs. The task: add support for a third TV platform to the two supported platforms and switch to a new backend with a different API. How can we do this without breaking things?

One approach is to add tests incrementally- end to end tests to avoid breaking functionality and unit tests to aid with refactoring. But this was mostly user interface code on TV platforms with poor and varied tooling. Automated user interface testing on each platform would be challenging if possible at all. Manual testing on each platform was time consuming due to slow and inconsistent deployment tools.

Some parts of the application could be tested and this was a part of how we made this change. But the more interesting idea we tried was to refactor with types.

[Read the full post on the Reaktor blog.](https://www.reaktor.com/blog/refactoring-30000-lines-js-types/)