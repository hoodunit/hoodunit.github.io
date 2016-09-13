---
title: "Wrapping JavaScript for PureScript"
layout: post
---
{% include base.html %}

How do I wrap a JavaScript API to use from PureScript? I had a chance to think about this while wrapping the [Screeps game][screeps] [API][screeps_api] so I could [play Screeps using PureScript][purescript_screeps].

<img class="blog-img" style="min-width: 300px; width: 100%; max-width: 800px;" src="/img/screeps_room.png" />

Screeps is an MMO strategy game for programmers. You play by writing a JavaScript AI to control your minions. Everyone's code runs 24/7 across hundreds of rooms in the same world.

PureScript is a small strongly typed language that compiles to JavaScript.

As a target for PureScript, the Screeps JavaScript API has some challenges. It makes heavy use of prototypes, a class hierarchy, and implicit effects. There's some implicit mutable state. Performance is important, because the game caps the amount of CPU and memory you can use. But I gave a shot at wrapping it and I'm pretty happy with the result.

## How do I...
---

As a relative newcomer to PureScript and strongly typed functional programming languages, I ran into a number of puzzles in wrapping the Screeps API. Here is what I ran into and how I ended up solving it.

### How do I call a JavaScript function from PureScript?

Write a `foreign import` type declaration for how you want to call the function and a corresponding JavaScript function that actually calls the function (and handles currying). Borrowing an example from the [PureScript Wiki][purescript_ffi_tips]:

PureScript: 

```haskell
foreign import joinPath :: FilePath -> FilePath -> FilePath
```

JavaScript:

```javascript
exports.joinPath = function(start) {
  return function(end) {
    return require('path').join(start, end);
  }
}
```

In practice, though, writing these curried JavaScript functions is tedious and error-prone so you'll want to use helper functions. The [purescript-functions][purescript_functions] library provides some basic wrappers to allow you to do this instead:

PureScript: 

```haskell
foreign import joinPathImpl :: Fn2 FilePath FilePath FilePath

joinPath :: FilePath -> FilePath -> FilePath
joinPath = runFn2 joinPathImpl
```

JavaScript:

```javascript
exports.joinPathImpl = require('path').join;
```

### How do I wrap functions that use `this`?

The Screeps API is makes heavy use of object and singleton methods. For example, to make a creep attack a target you call

```javascript
creep.attack(target)
```

PureScript doesn't have classes or the concept of `this`. I represent this in PureScript as a function that takes in the object as the first argument. Calling the method on the object is handled with a little FFI helper function.

PureScript:

```haskell
getActiveBodyparts :: Creep -> BodyPartType -> Int
getActiveBodyparts = runThisFn1 "getActiveBodyparts"

foreign import runThisFn1 :: forall this a b. String -> this -> a -> b
```

JavaScript:

```javascript
exports.runThisFn1 = function(key){
  return function(self){
    return function(a){
      return self[key](a);
    }
  }
}
```

### How do I wrap constant values?

The Screeps API has a large number of constants. I wanted to expose these to PureScript in a type-safe way without much runtime overhead. The solution I used was to wrap constants in `newtypes`.

PureScript:

```haskell
newtype ReturnCode = ReturnCode Int
foreign import ok :: ReturnCode
foreign import err_not_owner :: ReturnCode
foreign import err_no_path :: ReturnCode
```

JavaScript:

```javascript
exports.ok = OK;
exports.err_not_owner = ERR_NOT_OWNER;
exports.err_no_path = ERR_NO_PATH;
```

For those unfamiliar with newtypes, it provides a type alias that at runtime works the same as the underlying type. In theory this gives us the benefits of both worlds: compile-time type safety and run-time performance. If we never expose the constructor for the newtype, the only way for a user to obtain values e.g. of type `ReturnCode` is through the ways we provide. This allows the use of only the constant values that we have defined.

The type could also be defined with a `foreign import`:

```haskell
foreign import data ReturnCode :: *
```

This might be nicer for some cases, but makes it harder to write, say, type class implementations because you can't rely on generics.

### How do I wrap a class hierarchy?

Screeps has a class hierarchy a few classes deep:

```
RoomObject
-> Creep
-> Structure
  -> OwnedStructure
    -> StructureContainer
    -> StructureSpawn
    -> ...etc
```

PureScript doesn't have classes, prototypes, or inheritance. In particular, wrapping this in PureScript involves at least two challenges:

1. How can functions be defined once to work with any objects of a given class?
1. How can appropriately-typed sub-class instances be obtained when needed?

The solution to 2) is discussed elsewhere. My initial solution for 1) used a *type class* hierarchy like the following:

```haskell
class IRoomObject a
class (IRoomObject a) <= IStructure a
class (IStructure a) <= IOwnedStructure a

foreign import data RoomObject :: *
instance iRoomObjectRoomObject :: IRoomObject RoomObject

foreign import data Structure :: *
instance iRoomObjectStructure :: IRoomObject Structure
instance iStructureStructure :: IStructure Structure
```

Generic functions can then be written that require any member of a certain type class:

```haskell
room :: forall a. (IRoomObject a) => a -> Room
room = unsafeField "room"
```

This was less than ideal to use, though. Type classes aren't very composable, they say, and in particular I was having difficulty defining ADTs that used type class instances. Type classes and ADTs don't seem to mix well. You can't, for instance, put a type class constraint on an ADT.

I ended up borrowing a trick from [wxHaskell][wx_haskell] using *phantom types*. Instead of using type classes, I defined the class hierarchy using ADTs:

```haskell
foreign import data RawOwnedStructure :: * -> *
foreign import data RawRoomObject :: * -> *
foreign import data RawStructure :: * -> *

foreign import data RawContainer :: *

type RoomObject a = RawRoomObject a
type Structure a = RoomObject (RawStructure a)
type OwnedStructure a = Structure (RawOwnedStructure a)

type Container = Structure RawContainer
type Controller = OwnedStructure RawController
```

The types the user uses are defined as type synonyms on the left, e.g. `RoomObject` or `Container`. Parent classes contain a phantom type `a` which carries the class hierarchy information. On the right side we have the "raw" types which are not used directly by users but are seen in type errors.

The `room` function from above ends up like this:

```haskell
room :: forall a. RoomObject a -> Room
room = unsafeField "room"
```

This is simpler--no type class constraint-- and works more nicely with ADTs and other constructs. How it works was a little tricky to me at first. Suppose we pass in a `Container` to our `room` function, which expects a `RoomObject a`. `Container` is a type synonym. If we expand out the type synonyms it ends up looking as follows:

```
  Container
= Structure RawContainer
= RoomObject (RawStructure RawContainer)
= RawRoomObject (RawStructure RawContainer)
```

The actual type defined by `Container` is

```
RawRoomObject (RawStructure RawContainer)
```

Notice how this contains the class hierarchy. So a function taking in `RoomObject a` will accept a `Container` because, looking at the expansion above, `Container` is equivalent to

```
RoomObject (RawStructure RawContainer) = RoomObject a
```

Pretty neat. Also, all of these types are defined only at compile-time and disappear at run time. In the end the JS code just passes in objects like it always does, but with strong compile-time guarantees about correct objects being passed within our code.

### How do I parse function return values into the correct types?

The Screeps API has a number of functions that take in a constant specifying a type and return an object of that type. For example, `room.find(FIND_CREEPS)` finds all creeps in a room, `room.find(FIND_FLAGS)` finds all flags, and so forth.

In JavaScript this is not a problem, because you either assume the correct type or verify the type otherwise e.g. from a "type" field. For PureScript we would like to have this function return the appropriate type e.g. Creep or Flag.

Phantom types to the rescue. It turns out that we can tag our `FIND_*` constants with a phantom type and use this type tag to return an object of the correct type.

```haskell
newtype FindType a = FindType Int

foreign import find_creeps :: FindType Creep
foreign import find_flags :: FindType Flag
foreign import find_construction_sites :: FindType ConstructionSite
foreign import find_my_spawns :: FindType Spawn

find :: forall a. Room -> FindType a -> Array a
find = runThisFn1 "find"
```

Some constants are not associated with the most specific type, though. For example `room.find(FIND_STRUCTURES)` returns all structures in a room, which may be one of any number of more specific structure types. We can't know at compile time what types it is returning. In these cases I just return `Structure Unit` and then provide functions for safe casting to more specific sub-types.

```haskell
toContainer :: forall a. Structure a -> Maybe Container
toContainer = unsafeCast structure_container

unsafeCast :: forall a b. StructureType -> Structure a -> Maybe b
unsafeCast t struc
  | structureType struc == t = Just $ unsafeCoerce struc
  | otherwise = Nothing
```

This checks the type of the object from the `structureType` field, which contains the string name of the type, and then uses `unsafeCoerce` to force it to the correct type. This works similarly to TypeScript's [user defined type guards][ts_type_guards]. I'm not entirely happy with this solution but it works.

### How do I handle functions that return null or undefined?

In JavaScript anything can be null or undefined and there's no way of knowing. In PureScript nullable values are represented explicitly using `Maybe` types. We can parse values to `Maybe` values using a little FFI helper that just checks for null or undefined and returns the appropriate `Maybe` value.

PureScript:

```haskell
findClosestByPath :: forall a. RoomPosition -> FindType a -> Maybe a
findClosestByPath pos findType = toMaybe $ runThisFn1 "findClosestByPath" pos findType

toMaybe :: forall a. NullOrUndefined a -> Maybe a
toMaybe n = runFn3 toMaybeImpl n Nothing Just

foreign import toMaybeImpl :: forall a m. Fn3 (NullOrUndefined a) m (a -> m) m
```

JavaScript:

```javascript
exports.toMaybeImpl = function(val, nothing, just){
    if(val === null || val === undefined){
        return nothing;
    } else {
        return just(val);
    }
}
```

### How do I handle functions that throw exceptions?

JavaScript functions can throw exceptions willy nilly. In PureScript it's more common to use an `Either` type, for instance, to return either the value we want or an error. So we catch the exception and return an `Either` value:

PureScript:

```haskell
findClosestByPath :: forall a. RoomPosition -> FindContext a -> Either Error (Maybe a)
findClosestByPath pos ctx = errorToEither \_ ->
  toMaybe $ runThisFn1 "findClosestByPath" pos (unwrapContext ctx)
  
errorToEither :: forall a. (Unit -> a) -> Either Error a
errorToEither fun = errorToEitherImpl fun Left Right

foreign import errorToEitherImpl :: forall a.
  (Unit -> a) ->
  (Error -> Either Error a) ->
  (a -> Either Error a) ->
  Either Error a
```

JavaScript:

```javascript
exports.errorToEitherImpl = function(fun){
  return function(left){
    return function(right){
      try {
        return right(fun());
      } catch(e){
        return left(e);
      }
    }
  }
}
```

This admittedly gets a bit ugly in some cases such as the above example, where it turns out the Screeps API will either throw an exception, or return a value which is sometimes null or undefined. But that's how the API is, and we keep our type guarantees.

It turns out we can make this easier by using functions from [purescript-exceptions]. `try` takes an effectful function that throws an exception and turns it into a function that catches exceptions and returns either the exception or the value you wanted. As we've handled all of the side effects, we can make it a pure (non-effectful) function again with `runPure`.

```haskell
findClosestByPath :: forall a. RoomPosition -> FindContext a -> Either Error (Maybe a)
findClosestByPath pos ctx = runPure (try closestByPath)
  where closestByPath = toMaybe <$> runThisEffFn1 "findClosestByPath" pos (unwrapContext ctx)
```

### How do I pass in arguments to overloaded functions?

For example, a number of Screeps functions take in either x and y coordinates or a RoomPosition (containing x and y coordinates) or a RoomObject (which exists at a certain x and y position).

PureScript doesn't have function overloading, but you can handle it fairly neatly using ADTs as in the following:

```haskell
data TargetPosition a =
  TargetPt Int Int |
  TargetObj (RoomObject a) |
  TargetPos RoomPosition
  
getDirectionTo :: forall a. RoomPosition -> TargetPosition a -> Direction
getDirectionTo pos (TargetPt x' y') = runThisFn2 "getDirectionTo" pos x' y'
getDirectionTo pos (TargetPos otherPos) = runThisFn1 "getDirectionTo" pos otherPos
getDirectionTo pos (TargetObj obj) = runThisFn1 "getDirectionTo" pos obj
```

Of course, this requires the caller to wrap the argument in the appropriate type constructor e.g. `getDirectionTo pos (TargetObj obj)`.

### How do I pass in a large number of optional parameters?

Some Screeps functions take in a JavaScript object which contains a number of optional fields. In JavaScript this works neatly because you just pass in an object with the fields you want. In PureScript it's not as clean because optional fields have to be represented explicitly e.g. as `Maybe` values.

One seemingly common pattern for handling this in Haskell is to provide a default options object that has all of the options with their defaults. Users can then modify the object to include the options that they want with a relatively short syntax.

The tweak I made in my library is to make all of the options `Maybe` types and to only include the `Just` values in the final options object. The reason for this is that the way to indicate that an option is not used in the Screeps API is to exclude it. Including a default value, even `undefined`, may not be the same semantically.

```haskell
moveTo' :: forall a e. Creep -> TargetPosition a -> MoveOptions -> Eff (cmd :: CMD, memory :: MEMORY | e) ReturnCode
moveTo' creep (TargetPt x y) opts = runThisEffFn3 "moveTo" creep x y (selectMaybes opts)

type MoveOptions = PathOptions
  ( reusePath :: Maybe Int
  , serializeMemory :: Maybe Boolean
  , noPathFinding :: Maybe Boolean )

type PathOptions o =
  { ignoreCreeps :: Maybe Boolean
  , ignoreDestructibleStructures :: Maybe Boolean
  , ignoreRoads :: Maybe Boolean
  , ignore :: Maybe (Array RoomPosition)
  , avoid :: Maybe (Array RoomPosition)
  , maxOps :: Maybe Int
  , heuristicWeight :: Maybe Number
  , serialize :: Maybe Boolean
  , maxRooms :: Maybe Int
  | o }

moveOpts :: MoveOptions
moveOpts =
  { ignoreCreeps: Nothing
  , ignoreDestructibleStructures: Nothing
  , ignoreRoads: Nothing
  , ignore: Nothing
  , avoid: Nothing
  , maxOps: Nothing
  , heuristicWeight: Nothing
  , serialize: Nothing
  , maxRooms: Nothing
  , reusePath: Nothing
  , serializeMemory: Nothing
  , noPathFinding: Nothing }

selectMaybes :: forall a. a -> JsObject
selectMaybes obj = unsafePartial $ selectMaybesImpl isJust fromJust obj

foreign import selectMaybesImpl :: forall a. (Maybe a -> Boolean) -> (Maybe a -> a) -> a -> JsObject
foreign import data JsObject :: *
```

JavaScript:

```javascript
exports.selectMaybesImpl = function(isJust){
    return function(fromJust){
        return function(obj){
            var newObj = {};
            for(var key in obj){
                if(obj.hasOwnProperty(key) && isJust(obj[key])){
                    newObj[key] = fromJust(obj[key]);
                }
            }
            return newObj;
        }
    }
}
```

### How do I store memory in a type-safe way?

Screeps allow you to store 2 MB of your own memory. The default way this is handled is that you store objects on the `Memory` object that are serializable to JSON. When your code is loaded on each tick, the memory gets deserialized. This deserialization also counts toward your CPU usage.

You can also handle memory at a lower level using `RawMemory`, which allows you to write your own serialization/deserialization in place of the default `JSON.stringify` and `JSON.parse`.

In PureScript we want all of our loaded data to be typed, of course, so we need easy ways to store and load typed data.

The approach I took is to use [purescript-argonaut][ps_argonaut] to allow you to store any data for which you can write `DecodeJson` and `EncodeJson` instances. You can use generics to avoid writing most of the boilerplate and you end up with something like the following to do encoding and decoding:

```haskell
derive instance genericCreepState :: Generic CreepState
instance decodeJsonCreepState :: DecodeJson CreepState where
  decodeJson = gDecodeJson
instance encodeJsonCreepState :: EncodeJson CreepState where
  encodeJson = gEncodeJson
```

One interesting API quirk I ran into is that it turns out some functions implicitly modify the memory. This is not necessarily directly represented in the Screeps API, but in my PureScript wrapper those functions are tagged with the `MEMORY` effect to warn of this. This brings me to the next item.

### How do I handle effectful code?

Screeps has a number of commands that have implicit side effects. When you give a creep a command, the command is implicitly executed at the end of the game tick. Some functions implicitly or explicitly modify stored memory. Others are time-dependent.

In PureScript implicit side effects are made explicit to make the code easier to think about and refactor. The classic Haskell example is that if a function can launch nukes as a side effect, we would like to know about it.

Well, Screeps has a function for launching nukes: `launchNuke`. We save ourselves from accidentally launching nukes by tagging it with an effect:

```haskell
launchNuke :: forall e. Nuker -> RoomPosition -> Eff (cmd :: CMD | e) ReturnCode
launchNuke = runThisEffFn1 "launchNuke"
```

Returning an effect forces all callers to recognize the fact that this function has side effects. It makes it clearer what functions actually do and makes it easier to separate the simpler side-effect free functions from the more difficult side-effectful functions.

In the end I defined four effects:

```haskell
-- | Execute a Screeps command before the next tick as a side effect e.g. to move a creep.
foreign import data CMD :: !

-- | Get or set mutable memory
foreign import data MEMORY :: !

-- | Global scope is cleared periodically, so values depending on global variables
-- | like Game and Memory need to be fetched dynamically. This effect enforces this.
foreign import data TICK :: !

-- | Time-dependent functions have different output depending on when they are called.
foreign import data TIME :: !
```

### How do I get performance?

Code performance in Screeps is important. You are allowed a certain CPU/processing cap and if you exceed the cap your code is killed. The cap rises according to your level.

PureScript doesn't have a runtime and compilation mostly includes only the bits of libraries that you use. Overall performance using this PureScript library is good enough and I suspect depends more on the user's code than the library itself. Anecdotally my AI code performs close to its CPU cap (e.g. 40/40 CPU used for 2 rooms) where others seem to be able to perform much under the CPU cap (e.g. 10-20 CPU for 2 rooms). This is probably because the code is mostly a pure function with side effects at the edges. More performant code might spend more time in the Eff monad's `do` notation. But it's not something I've looked into much yet.

There are a few things I do in the library and in my code to try to eke out a little more performance:

* Use type aliases or newtype wrapping to only use types at compile time.
* Use pattern-matching where possible in place of e.g. chained Maybe values. In Haskell I suspect `(Just a) <|> somethingElse` wouldn't execute `somethingElse`, but in PureScript you need to handle the laziness yourself. Pattern-matching maps directly to performant nested if statements.
* Avoid inlining functions.
* Use lazily-evaluated values via [purescript-lazy] where necessary.

## Conclusions

Writing Screeps code in PureScript is fun. Tick-based gameplay maps nicely to modeling your AI as a pure function from memory and game state to new memory and commands to execute, with side effects executed only at the edges. Type-safety saves you from breaking everything in late night refactoring or frantic live-coding updates to save your base. Though to be fair it didn't quite save my base from annihilation. Twice.

Wrapping JavaScript in PureScript requires more thought than writing TypeScript or Flow definitions for JavaScript. To do a proper job of it you have to *grok* the code you are wrapping. But it also allows you to create better compile-time guarantees about how your code works, which translates to more reliable and refactorable code.

Compared to compile-to-js languages like ClojureScript or GHCJS, it's likely easier to get performant PureScript code because PureScript doesn't have a runtime. The low-level tools like mutability and JavaScript hacks are also there to be used if necessary.

The Screeps PureScript library is [here][purescript_screeps]. Go forth and screep, my friend.

[screeps]: https://screeps.com
[screeps_api]: http://support.screeps.com/hc/en-us/articles/203084991-API-Reference
[purescript_screeps]: https://github.com/nicholaskariniemi/purescript-screeps
[wx_haskell]: https://wiki.haskell.org/wikiupload/6/65/Wxhaskell.pdf
[ts_type_guards]: https://basarat.gitbooks.io/typescript/content/docs/types/typeGuard.html
[purescript_ffi_tips]: https://github.com/purescript/purescript/wiki/FFI-tips
[purescript_functions]: https://github.com/purescript/purescript-functions
[ps_argonaut]: https://github.com/purescript-contrib/purescript-argonaut
[purescript-lazy]: https://github.com/purescript/purescript-lazy
[purescript-exceptions]: https://github.com/purescript/purescript-exceptions

<small>
Edit 2016-9-13: Added comments about purescript-exceptions and defining constants with `foreign import data`.
<small>
