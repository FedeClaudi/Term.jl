# Progress bars


!!! warning
    Progress bars displays are updated in the background while your code executes. This is done by having the display rendering code run on a separate thread. If you're using a single thread (see: https://docs.julialang.org/en/v1/manual/multi-threading/) you'll need to add a `sleep(0.001)` or `yield()` command inside your code whose progress you're monitoring to ensure that the display is updated correctly.


## Overview
Progress bars! We all love progress bars, and Julia has some great [progress bars](https://juliapackages.com/p/progressbars) packages. 
But this is `Term`, and `Term` too has its own progress bars API. We think you'll like it. If not, worry not! `Term`'s progress bars play well `ProgressLogging.jl`, scroll to the bottom of this page!

!!! warning
    Progress bars do some terminal magic that doesn't play well with how the docs are rendered here. If you want to see what progress bars actually look like, 
    we **encourage** you to copy-paste the code below and try it out in your own console. Or head to [github](https://github.com/FedeClaudi/Term.jl) where you can find more examples.

So this is what a progress bar looks like in `Term`:

```@example prog
using Term.Progress

pbar = ProgressBar()
job = addjob!(pbar; N=5)
start!(pbar)
for i in 1:5
    update!(job)
    sleep(0.01)
    render(pbar)
end
stop!(pbar)
```


Let's see what's happening. We start by creating a progress bar

```Julia
pbar = ProgressBar()
```

and then we add a "job"

```Julia
job = addjob!(pbar; N=5)
```

what's that? `Term`'s `ProgressBar`s can handle multiple "jobs" simultaneously. So if you have multiple things you want to keep track of (e.g. multiple nested loops), you can have a job for each. Next we start the progress bar:
```Julia
start!(pbar)
```
we update the job at each step of the loop and render the updated display:
```Julia
    update!(job)
    render(pbar)
```
and finally we stop the whole thing:
```
stop!(pbar)
```.

Okay, why do we need all of this starting and stopping business? Updating the job makes sense, we need to know when we made progress, but why do we need to start and stop the progress bar? Well, `ProgressBar` does a bit of terminal magic to ensure that any content you print to STDOUT is displayed without disrupting the progress bar's behavior, so we need to start and stop it to make sure that the magic happens and that the terminal is restored when we're done. 

You might spot a problem: what if we forgot `stop!`, or our code errors before we reach it or something else like this? That's a problem, our terminal won't be restored. Well don't worry, there's a solution:

```@example prog

pbar = ProgressBar()
job1 = addjob!(pbar; N=5)
job2 = addjob!(pbar; N=10)

with(pbar) do
    for i in 1:10
        update!(job1)
        update!(job2)
        i % 3 == 0 && println("text appears here!")
        sleep(0.001)
    end
end
```

!!! info "`println` vs `print`"
    You'll notice we've used `println` in the example above. Currently, using `print` will break the layout and the text won't be printed correctly. Please use `println` while using `ProgressBar`!

`with` takes care of it all. It starts the progress bar and stops it too! No matter what happens in the code inside the `do` block, `with` will stop the progress bar so we can use it with no fear. It also removes the need to explicitly call `start!/stop!`, which helps. We recommend that you always use `with`. 

So with `with` we loose some of the boiler plate, but it's still a bit too much isn't it? It's cool if you
need something specific, but if you want a simple progress bar to monitor progress in a loop perhaps you want something simpler. That's where `@track` comes in:

```@example prog
@track for i in 1:10
    sleep(0.01)
end
```

As simple as that!



### ProgressJob
There's just couple things you need to know about `ProgessJob`. First, you can set the expected number of steps in the progress bar. We've seen that before, it's the `N` in `addjob!(pbar; N=5)`. You don't have to though, if you don't know how long your job's going to be then just leave it out! In that case you won't see a progress bar, but you can still see some progress:

```@example prog
pbar = ProgressBar(; columns=:spinner)
job = addjob!(pbar; description="how long is this")

with(pbar) do
    for i in 1:10
        update!(job)
        sleep(0.001)
    end
end
```

What's up with that `columns=:spinner`? Read below. By the way, there's a few different kind of spinners

```@example prog
import Term.Progress: SPINNERS

for spinner in keys(SPINNERS)
    columns_kwargs = Dict(
        :SpinnerColumn => Dict(:spinnertype => spinner, :style=>"bold green"),
        :CompletedColumn => Dict(:style => "dim")
    )

    pbar = ProgressBar(; columns=:spinner, columns_kwargs=columns_kwargs)
    with(pbar) do
        job = addjob!(pbar; description="{orange1}$spinner...")
        for i in 1:3
            update!(job)
            sleep(.0025)
        end
    end
end

```


## Options
The main way in which you can personalize progress bars display, is by choosing which columns to show (see below), but there's also a few additional parameters. You can use `width` to specify how wide the progress bar display should be, or set `expand=true` to make it fill up all available space. Also, sometimes you want to have a bunch of display bars to show progress in various bits of your code, but you don't want your final terminal display to be cluttered. In that case set `transient=true` and the progress bars will be erased when they're finished!


## Columns
As you've seen, each progress bar display shows various bits of information: some text description, the progress bar itself, a counts bit... Each of these is a "column" (a subtype of `AbstractColumn`). There's many types of columns showing different kinds of information, and you can make your own too (see below). `Term` offers different presets columns layouts do display varying levels of detail:


```@example prog
for details in (:minimal, :default, :detailed)
    pbar = ProgressBar(; columns=details, width=80)
    with(pbar) do 
        job = addjob!(pbar; N=5)
        for i in 1:5
            update!(job)
            sleep(0.02)
        end
    end
end

```

but you can also choose your own combination of columns:

```@example prog
import Term.Progress: CompletedColumn, SeparatorColumn, ProgressColumn, DescriptionColumn

mycols = [DescriptionColumn, CompletedColumn, SeparatorColumn, ProgressColumn]
cols_kwargs = Dict(
    :DescriptionColumn => Dict(:style=>"red bold")
)

pbar = ProgressBar(; columns=mycols, columns_kwargs=cols_kwargs, width=140)
with(pbar) do 
    job = addjob!(pbar; N=5)
    for i in 1:5
        update!(job)
        sleep(0.02)
    end
end
```

what's that `cols_kwargs`? You can use that to pass additional parameters to each columns, e.g. to set its style.


You can also pass a `cols_kwargs` argument to `addjob!` to set the column style for individual jobs!
```@example prog

pbar = ProgressBar(; expand = true, columns=:detailed, colors="#ffffff", 
    columns_kwargs = Dict(
        :ProgressColumn => Dict(:completed_char => '█', :remaining_char => '░'),
    )
)
job = addjob!(pbar; N = 10, description="Test")

job2 = addjob!(
    pbar; 
    N = 10, 
    description="Test2", 
    columns_kwargs = Dict(
        :ProgressColumn => Dict(:completed_char => 'x', :remaining_char => '_'),
    )
)

with(pbar) do
    for i in 1:10
        update!(job)
        update!(job2)
        sleep(0.01)
    end
end
```

### Custom columns
If there some kind of information that you want to display and Term doesn't have a column for it, just make your own! 

You need two things: a column type that is a subtype of `AbstractColumn` and an `update!` method to update the column's text at each step of the progress bar. Here's a, not very useful, example of a column that displays random text:

```@example customcolumn
using Random

using Term.Progress
import Term.Progress: AbstractColumn, DescriptionColumn, CompletedColumn, SeparatorColumn, ProgressColumn
import Term.Segments: Segment
import Term.Measures: Measure

struct RandomColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    style::String

    function RandomColumn(job::ProgressJob; style="red" )
        txt = Segment(randstring(6), style)
        return new(job, [txt], txt.measure, style)
    end
end


function Progress.update!(col::RandomColumn, color::String, args...)::String
    txt = Segment(randstring(6), col.style)
    return txt.text
end
```

which you can use as you would any column:

```@example customcolumn

mycols = [DescriptionColumn, CompletedColumn, SeparatorColumn, ProgressColumn, RandomColumn]
cols_kwargs = Dict(
    :RandomColumn => Dict(:style=>"green bold")
)

pbar = ProgressBar(; columns=mycols, columns_kwargs=cols_kwargs, width=140)
with(pbar) do 
    job = addjob!(pbar; N=5)
    for i in 1:5
        update!(job)
        sleep(0.02)
    end
end

```

done!

## For each progress
Want to just wrap an iterable in a progress bar rendering? Check this out.

```Julia
using Term
using Term.Progress

pbar = Term.ProgressBar()
foreachprogress(1:100, pbar,   description = "Outer    ", parallel=true) do i
    foreachprogress(1:5, pbar, description = "    Inner") do j
        sleep(rand() / 5)
    end
end
```

The loop above will render a progress bar for each iteration of the outer loop, and a progress bar for each iteration of the inner loop - easy.


## ProgressLogging
I know that some of you will be thinking: hold on, Julia already had a perfectly functioning progress API with `ProgressLogging.jl`, can't we just use that? Long story short, yes you can. But `Term`'s API gives you so much more control over what kind information to display and what it should look like. Nonetheless, many of you will want to use `ProgressLogging` in conjunction with Term, so we've made it possible, you just need to use Term's logger (see [Logger](@ref LoggingDoc)):


```Julia
using ProgressLogging
import Term: install_term_logger
install_term_logger()

@progress "outer...." for i in 1:3
    sleep(0.01)
end

```
