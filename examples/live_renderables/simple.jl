using Term
using Term.LiveWidgets
using Term.Tables

"""
Just a simple widget updating a table visualization.
"""

function on_draw(widget)
    rand() < .8 && return  # avoid updating at each frame
    n = 10
    data = hcat(1:n, rand(Float64, n), rand(Int8, n))
    widget.text = string(
        Table(data;
            header_style = "bold yellow_bright",
            footer = sum
        )
    )
end

wdg = TextWidget(;
    height = 25,
    as_panel=false,
    on_draw=on_draw,
)



App(wdg) |> play;
