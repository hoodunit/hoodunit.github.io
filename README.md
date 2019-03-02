# Blog

This is the source code for my [blog](http://blog.ndk.io).

External dependencies:

* Nix

To build and run locally, run the following in the root directory:

```
nix-shell
jekyll serve
```

## To update deps

Set versions in Gemfile, then:

```
nix-shell -p bundler bundix
bundler package --no-install
bundix
```

Commit results.