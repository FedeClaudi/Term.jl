# Progress bars
## General usage
Progress bars! We all love progress bars, and julia has some great [progress bars](https://juliapackages.com/p/progressbars) packages. 
But this is `Term`, and `Term` too has its own progress bars API. We think you'll like it.

!!! warning
    In the docs each "update" of the progress bar gets printed in a new line. This is not what it looks like in reality.
    We **encourage** you to copy-paste the code below and try it out in your own console. Or head to [github](https://github.com/FedeClaudi/Term.jl) where you can find more examples.

So this is what a progress bar looks like in `Term`:

```@example
import Term.progress: track

myvec = collect(1:5)
for i in track(myvec; width=60)
    # do stuff
    sleep(.025)
end
```

You'll noticed that we used a function `track` for the whole thing. `track` accepts an iterable object (e.g., a vector, or a range) in the context
of a for loop. It then takes care of creating, starting, and stopping your very own `ProgressBar` object. It also takes a bunch of arguments to specify how exactly the progress bar should appear, more on that below.

Now, `track` is handy because it takes care of most of the work. But lets look in more detail at what goes on under the hood (which can be useful when you want more control over your bars). A progress bar is represented by the creatively named `ProgressBar` type. When initializing a new instance of it you must say how many iterations will the bar have to run over:

```Julia
import Term.progress: ProgressBar
pbar = ProgressBar(100)
```

When you want to sue your progress bar you need to `start` it, `update` it and `stop` it. Everytime you `update` `pbar` it adds a `+1` to its internal counter of how many iterations it's done (until it's done all the iterations you've set out at the beginning), You can reset this by specifying the iteration number: `update(pbar, 50)`.
So this is what it looks like:

```@example
import Term.progress: track, ProgressBar, update, start, stop

# create progress bar
pbar = ProgressBar(;N=5, description="Manual pbar", width=60)

# loop da loop
for i in 1:5
    # do stuff
    sleep(.01)

    # manually update the progress bar
    update(pbar)
end
stop(pbar)
```

You'll see that we've passed `description` to specify the text that goes before the bar in the progress bar. There's other arguments you can use to set the bar's appearance:

```@example
import Term.progress: track
import Term.color: RGBColor

trk(x) = track(x;
    description="[red bold]Choose your colors![/red bold]",
    expand=true,  #  fill the screen
    update_every=5,  # don't update at every iteration
    columns=:detailed,  # print more info
    colors = [
        RGBColor("(.3, .3, 1)"),
        RGBColor("(1, 1, 1)"),
        RGBColor("(.9, .3, .3)"),
    ]
)

print("\n")
for i in trk(1:10)
    sleep(0.005)
end
```

## Columns
What's going on with `columns=:detailed` you ask? Well let me tell you. Each bit of information in the progress bar visualization is a `Column`. The initial description, those pink dots, the progress bar itself... all columns. There's many types of columns and you can create your own. You can mix and match different columns to create your own progress bar visualization. `Term` provides three presets to visualize increasing amounts of information with your progress bar:

```@example
import Term.progress: track


for (level, color) in zip((:minimal, :default, :detailed), ("red", "green","blue"))
    for i in track(1:5; description="[bold $color italic]$level[/bold $color italic]", columns=level, width=150)
        sleep(.005)
    end
end

```

As you can see, regardless of how many columns there are the progress bar will have the right width. That's because each column is a `Term` renderable object and as such has a `Measure` object that tells us about it's width. The size of the bar in the progress bar is then adjusted to fit in all the columns. 


### Custom columns
Nice right? Let's see how to make your own column with a simple exampe: a column that just shows the current iteration number.

All columns are subtypes of an `AbstractColumn <: AbstractRenderable` type, so they must have a `segments` and a `measure` field. You can create a column like this:

```julia
import Term.progress: AbstractColumn, DescriptionColumn, ProgressColumn
import Term.style: apply_style  # to style strings
import Term.measure: Measure  # to define the column's size

# define a new column type
struct MyCol <: AbstractColumn
    segments::Vector
    measure::Measure
    style::String
end

# constructor
MyCol(style::String) = MyCol([], Measure(10, 1), style)
```

The only other thing you need to define is a function that updates the columns display

```julia
# define a function to update the column when the progress bar is updated
# it must return a string
Term.progress.update(col::MyCol, i::Int, args...)::String = return apply_style("[$(col.style)]$i[/$(col.style)]")
```

That should do it. Now we can specify our own set fo columns before creating the visualization:
```julia
cols = [
    DescriptionColumn("MY columns!!!"),
    ProgressColumn(),  # this will show the actual bar
    MyCol("bold red"),
]

line()
for i in track(1:100; columns=cols)
    sleep(.01)
end
```

## Transient bars
Sometimes you need loads of progress bars. Why? Not sure, but lets say you do. You likely don't want your terminal to be cluttered by loads of finished progress bars, right? Well lucky you! You can make `ProgressBar` transient so that it just disappears when it's done:

```@example

import Term: tprint
import Term.progress: track

for i in 1:3
    for j in track(1:5; description="[yellow bold]Transient pbars![/yellow bold]", transient=true)
        sleep(0.001)

    end
end
tprint("[bright_blue bold]poof![/bright_blue bold] [underline bright_blue]They disappeared[/]")
```

!!! note
    Okay, they didn't really disappear. But they will in the terminal, promised.

## A note on STDOUT
This is more advanced than most people will care about, but if you're confused about why the stuff you print in your for loops is not showing up perhaps have a look.

The way the progress bar happens, in practice, is that ANSI codes are used to move the cursor around in the terminal and erase the *old* progress bar before the update version is printed. This means that if you tried to print suff to terminal during the progress bar updates everything would go wrong! We woulnd't know which line to erase, where to print! A mess.
So, what we do is we **redirect** your `STDOUT` for the duration of the progress bar and only show it to you once the progress bar is done. That's why you need to wait until the end of the loop to see the results of `print`:

```@example
import Term.progress: track

for i in track(1:5)
    print("where is my text!")
end
```

You can disable this behavior by passing `redirectstdout=false` to `track` and `ProgressBar`.