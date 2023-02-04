# Console
Term provides a `Console` object whose main function (for now) is to simulate having a terminal with a size different from what you actually have. Imagine that your terminal is currently 100 columns wide, but you want to simulate having a narrower one (why? Don't know, but assume that's the case), then using `Console` allows you to do just that. 

It may seems like a fairly niche thing to have, but can actually be useful if you want to ensure that the output of your package looks the same for all users regardless of their terminal size. Also `Console` will do a lot more in the future.

```@example
using Term: tprintln
using Term.Consoles: Console, enable, disable

tprintln("This is a very long text"^10)

myc = Console(40)  # 40 columns wide
myc |> enable  # activate it


tprintln("This is a very long text"^10)  # get's reshaped to fit in 60cols

myc |> disable  # de-activate the console

tprintln("This is a very long text"^10)

```

it also works for any `Renderable` made with Term:

```@example
using Term: tprintln, Panel # hide
using Term.Consoles: Console, enable, disable #hide

print(Panel())

myc = Console(40)  # 40 columns wide
myc |> enable  # activate it


print(Panel())  # get's reshaped to fit in 60cols

myc |> disable  # de-activate the console

print(Panel())

```


!!! warning "print vs tprint"
    `Console` reshapes the output of a `print` call only if this is *not* just a plain `String`. Any renderables you're using will be re-shaped. If it's just a string, the default `Base.print` method will be called and there's nothing we can do about it. One possible work-around is using Term's `tprint` which will take the `Console` in consideration, alternatively wrap your strings in `RenderableText` objects.