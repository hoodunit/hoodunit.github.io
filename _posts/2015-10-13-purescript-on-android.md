---
title: "PureScript on Android"
layout: post
---

I've been playing around with PureScript on Android via React Native. 

Here's what a TodoMVC-style app looks like:

<img style="width: 300px;" src="/img/todomvc_screenshot.png"></img>

And here's what the guts of the code look like:

```haskell
render :: forall props eff. Render props AppState eff
render ctx = do
  (AppState state) <- readState ctx
  return $ 
    view [(style "container")] [
      text [style "title"] "todos",
      view [style "newTodoContainer"] [
        textInput [style "newTodo", 
                   P.value state.newTodo,
                   P.placeholder "What needs to be done?",
                   N.onChangeText \newTodo -> transformState ctx (updateNewTodo newTodo),
                   N.onSubmitEditing \_ -> transformState ctx addTodo]],
      listView [style "todoList",
                N.renderRow $ todoRow ctx,
                N.renderSeparator todoSeparator,
                N.renderHeader $ view [style "separator"] [],
                N.dataSource state.dataSource],
      view [style "bottomBar"] [
        view [style "filters"] [
           filterButton ctx state.filter All, 
           filterButton ctx state.filter Active,
           filterButton ctx state.filter Completed],
        text [style "clearCompleted", 
              N.onPress \_ -> transformState ctx clearCompleted] 
             "Clear completed"]]
        
main = do
  log "Running app"
  registerComponent "PureScriptSampleApp" component
  where
    component = createClass $ spec initialState render
    dataSource = listViewDataSource initialTodos
    initialState = updateDataSource $ AppState { nextId: 18, 
                                                 newTodo: "", 
                                                 todos: initialTodos, 
                                                 dataSource: dataSource, 
                                                 filter: All }
```

Check out the [example source code](https://github.com/nicholaskariniemi/purescript-react-native-todomvc) or the [React Native wrapper code](https://github.com/nicholaskariniemi/purescript-react-native). 

This wrapper code builds on Phil Freeman's [purescript-react](https://github.com/purescript-contrib/purescript-react) low-level wrapper for React, adding support for various elements used in Android. It is a work in progress. Functional afficionados will raise their eyebrows. Android gurus will throw their hands up in disgust. But it is PureScript. It is Android. And it is awesome.