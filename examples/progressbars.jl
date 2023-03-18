using Term
import Term.Progress: ProgressBar, start!, update!, stop!, with, @track, addjob!, render
import Term.Consoles: clear

tprint(hLine("progress bars"; style = "blue"))

"""
This example shows how to create progress bars visualizations in Term.

Progress bars in Term can handle multiple simultaneous tasks ('jobs') 
whose progress we can monitor (think of nested for loops). The
basic workflow involves creating a progress bars, adding jobs
and updating them to update the visual display

"""

pbar = ProgressBar()
job = addjob!(pbar; N = 100)
start!(pbar)
for i in 1:100
    update!(job)
    sleep(0.01)
    i % 25 == 0 && println("We can print from here too")
    render(pbar)
    # LiveDisplays.refresh!(pbar)
end
stop!(pbar)

"""
Or with multiple jobs
"""

pbar = ProgressBar(transient = true)
job = addjob!(pbar; N = 100)
job2 = addjob!(pbar; N = 50)
job3 = addjob!(pbar; N = 25)

start!(pbar)
for i in 1:100
    update!(job)
    i % 2 == 0 && update!(job2)
    i % 3 == 0 && update!(job3)
    sleep(0.01)
    render(pbar)
end
stop!(pbar)

"""
As you can see, the progress bar display stays as the bottom while the text is printed above.
To make that happen Term needs to mess around with your terminal, calling
`stop!` ensures that the normal terminal behavior is restored. If you
don't call `stop!` (e.g. because your code gave an error), then the 
terminal is not correctly restored. To avoid that we can use `with(pbar)`, this
will ensure that the progress bar is correctly stopped no matter what happens.

"""

pbar = ProgressBar(; expand = true)
job = addjob!(pbar; N = 100)

with(pbar) do
    for i in 1:100
        update!(job)
        sleep(0.01)
        i % 25 == 0 && println("We can print from here too")
    end
end

"""
As you can see, we don't need to call `start!` and `stop!` any more, `with` takes
care of that (even if there's an error in the loop).

Also, you might have noticed that `expand=true` makes the progress bar expand
to fill in all the available space. An alternative is to set the `width` value.

In addition to `width`, you can also use a convenient macro called @track
to wrap any loop with a progress bar display.
"""

@track for i in 1:100
    sleep(0.01)
end

"""
You can customize what kind of information should show in your progress bar and what it 
should look like. Each bit of information (the text, the percentage count...) is a 
"column" and you can choose which columns to display and in which order:
"""

for details in (:minimal, :default, :detailed)
    pbar = ProgressBar(; columns = details, width = 140)
    with(pbar) do
        job = addjob!(pbar; N = 100)
        for i in 1:100
            update!(job)
            sleep(0.02)
        end
    end
end

"""
Or you can create your choice of columns
"""

import Term.Progress: CompletedColumn, SeparatorColumn, ProgressColumn, DescriptionColumn

mycols = [DescriptionColumn, CompletedColumn, SeparatorColumn, ProgressColumn]
cols_kwargs = Dict(:DescriptionColumn => Dict(:style => "red bold"))

pbar = ProgressBar(; columns = mycols, columns_kwargs = cols_kwargs, width = 140)
with(pbar) do
    job = addjob!(pbar; N = 100)
    for i in 1:100
        update!(job)
        sleep(0.02)
    end
end

"""
As you can see you can use `cols_kwargs` to pass additional info to each column.

Sometimes you are not sure how many iterations your loop should run for.
In that case you can use spinners!
"""

import Term.Progress: SPINNERS

for spinner in keys(SPINNERS)
    columns_kwargs = Dict(
        :SpinnerColumn => Dict(:spinnertype => spinner, :style => "bold green"),
        :CompletedColumn => Dict(:style => "dim"),
    )

    pbar = ProgressBar(; columns = :spinner, columns_kwargs = columns_kwargs)
    with(pbar) do
        job = addjob!(pbar; description = "{orange1}$spinner...")
        for i in 1:250
            update!(job)
            sleep(0.0025)
        end
    end
end

"""
You can make your own column too! You just need to define a type and an update! method for them

"""

using Random

using Term.Progress
import Term.Progress:
    AbstractColumn, DescriptionColumn, CompletedColumn, SeparatorColumn, ProgressColumn
import Term.Segments: Segment
import Term.Measures: Measure

struct RandomColumn <: AbstractColumn
    job::ProgressJob
    segments::Vector{Segment}
    measure::Measure
    style::String

    function RandomColumn(job::ProgressJob; style = "red")
        txt = Segment(randstring(6), style)
        return new(job, [txt], txt.measure, style)
    end
end

function Progress.update!(col::RandomColumn, color::String, args...)::String
    txt = Segment(randstring(6), col.style)
    return txt.text
end

mycols = [DescriptionColumn, CompletedColumn, SeparatorColumn, ProgressColumn, RandomColumn]
cols_kwargs = Dict(:RandomColumn => Dict(:style => "green bold"))

pbar = ProgressBar(; columns = mycols, columns_kwargs = cols_kwargs, width = 140)
with(pbar) do
    job = addjob!(pbar; N = 100)
    for i in 1:100
        update!(job)
        sleep(0.02)
    end
end

"""
This is an example of how to use a progress bar to show file
downloading/loading progress.
"""

import Term.Progress: SeparatorColumn, ProgressColumn, DescriptionColumn, DownloadedColumn

FILESIZE = 2342341
CHUNK = 2048
nsteps = Int64(ceil(FILESIZE / CHUNK))

mycols = [DescriptionColumn, SeparatorColumn, ProgressColumn, DownloadedColumn]

pbar = ProgressBar(; columns = mycols, width = 140)
job = addjob!(pbar; N = FILESIZE)

with(pbar) do
    for i in 1:nsteps
        update!(job; i = CHUNK)
        sleep(0.001)
    end
end
