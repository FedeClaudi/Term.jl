using Term
import Term.progress: track, ProgressBar, update, start, stop
import Term.consoles: clear, line
import Term.color: RGBColor

clear()


tprint(hLine("progress bars"; style="blue"))
line()  # print a new line

"""
The easiest way to use Term's progress bars is through the 
`track` function. This just takes an iterable object as input
when you're doing a for loop over the object. It will print
out a visualization of progress along the for loop:
"""

myvec = collect(1:100)
for i in track(myvec)
    # do stuff
    sleep(.025)
end


"""
`track` creates and updates a `ProgressBar` object for you.
But you can do it manually if you want more control over it 
"""
# create progress bar
pbar = ProgressBar(;N=250, description="Manual pbar", width=120)
line()
# loop da loop
for i in 1:250
    # do stuff
    sleep(.007)

    # manually update the progress bar
    update(pbar)
end
stop(pbar)

"""
As you can see, progress bars have parameters to set their appearance.
The same parameters can be used for both ProgressBar and track.
Here's more:
"""

print("\n")
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
for i in trk(1:500)
    sleep(0.007)
end

"""
Each bit of information (the description, the progress bar, the number of 
completed iterations...) is a `column`. A progress bar can be made up
of different sets of columns, and you can create your own.

Term provides three different presets to display different ammounts of information:
"""

print("\n")
for (level, color) in zip((:minimal, :default, :detailed), ("red", "green","blue"))
    for i in track(1:100; description="[bold $color italic]$level[/bold $color italic]", columns=level, width=150)
        sleep(.005)
    end
end


"""
As you can see the display is adjusted so that it always has the right
width regardless of how many columns there are. The only thing
left to see is how to create your own column.
"""

import Term.progress: AbstractColumn, DescriptionColumn, BarColumn
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

# define a function to update the column when the progress bar is updated
# it must return a string
Term.progress.update(col::MyCol, i::Int, args...)::String = return apply_style("[$(col.style)]$i[/$(col.style)]")


# okay let's create a progress bar with out columns
cols = [
    DescriptionColumn("MY columns!!!"),
    BarColumn(),  # this will show the actual bar
    MyCol("bold red"),
]

line()
for i in track(1:100; columns=cols)
    sleep(.01)
end


"""
Our simple column simply keeps track of the number of iterations in the loop,
but you can go crazy and make all sorts of columns! Check the docs for more info.

Sometimes you want to create a lot of progress bars, but don't want to 
clutter the console space too much, make them transient!
"""

print("\n")
for i in 1:3
    for j in track(1:250; description="[yellow bold]Transient pbars![/yellow bold]", transient=true, width=250)
        sleep(0.001)

    end
end
tprint("[bright_blue bold]poof![/bright_blue bold] [underline bright_blue]They disappeared[/]")


line(;i=3)
tprint(hLine("Done"; style="green"))
