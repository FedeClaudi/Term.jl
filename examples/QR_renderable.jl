using Term

# necessary to create the "renderable" type
import Term.Renderables: AbstractRenderable
import Term.Measures: Measure
import Term.Segments: Segment

# for styling
import Term: apply_style

# define a new subtype of AbstractRenderable
struct QR <: AbstractRenderable
    segments::Vector{Segment}
    measure::Measure
end

"""
    QR(qr::BitMatrix)

Construct a QR renderable from a BitMatrix of pixel values. 

The half block `▄` is used, this allows for 2 colors per REPL line
by separately setting the foreground and background colors. 
Each "pixel" in the function body thus represents two pixels in the`qr` matrix,
the entry at (i, j) and (i+1, j).
"""
function QR(qr::BitMatrix)
    blk = "(0, 0, 0)"
    pixels = Dict(
        [1, 1] => "{white on_white}▄{/white on_white}" |> apply_style,
        [1, 0] => "{white on_$blk}▄{/white on_$blk}" |> apply_style,
        [0, 1] => "{$blk on_white}▄{/$blk on_white}" |> apply_style,
        [0, 0] => "{$blk on_$blk}▄{/$blk on_$blk}" |> apply_style,
    )

    out = []
    for row in 1:2:(size(qr, 1) - 1)
        out_row = String[]
        for col in 1:size(qr, 2)
            px = pixels[qr[row:(row + 1), col]]
            push!(out_row, px)
        end
        push!(out, join(out_row))
    end

    segments = Segment.(out)
    QR(segments, Measure(segments))
end

# hand made QR code bitmatrix :)
qr = rand(Bool, 20, 20) |> BitArray
qr[1:5, 1:5] .= 1
qr[16:20, 1:5] .= 1
qr[1:5, 16:20] .= 1
qr[16:20, 16:20] .= 1

description = RenderableText("""
    {bright_blue}Scan this QR to discover the secret behind beautiful {/bright_blue}
    {bright_blue}terminal output in your REPL.{/bright_blue}

    Just kidding, the QR code is fake, just use Term.jl

    But seriously, this should work with proper QR codes

    
    {bold white}What will you use this for?{/bold white}
""")

# embed the QR renderable in a panel
Panel(
    QR(qr) * description,
    fit = true,
    title = "scan me",
    title_justify = :center,
    padding = (4, 4, 1, 1),
)
