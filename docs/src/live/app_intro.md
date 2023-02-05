# App

The starting point of any good "live" or interactive terminal display is an `App`. The `App` takes care of generating and updating the visuals as well as taking in user input making use of it (e.g. to update the display accordingly). 
An app has some content. This content is in the form of `AbstractWidget` elements. These widgets are single content elements that serve a specific function, for example displaying some text or acting as buttons etc. More on widgets later. In addition to knowing **what** is in an app, we also need to specify **how** it should look like. Specifically, how should the different widgets be layed out.  So in addition to creating widgets, you will need to specify a layout for your app. 
There's a lot more to apps, but for now we can start with some simple examples

### A first example
We start with a simple example: an app that only shows some content
```@example app
using Term
using Term.LiveWidgets


```