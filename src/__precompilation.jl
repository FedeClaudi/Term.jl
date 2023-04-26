
# ---------------------------------------------------------------------------- #
#                                PRECOMPILATION                                #
# ---------------------------------------------------------------------------- #
using PrecompileTools
PrecompileTools.verbose[] = false

@setup_workload begin
    txt = join(
        repeat(["this is a random {red}text{/red} to test {bold}precompilation"], 10),
        "\n",
    )

    mdtext = md"""
    # Markdown rendering in Term.jl
    ## two
    ### three
    #### four
    ##### five
    ###### six

    This is an example of markdown content rendered in Term.jl.
    You can use markdown syntax to make words **bold** and *italic* or insert `literals`.


    You markdown can include in-line latex ``\LaTeX  \frac{{1}}{{2}}`` and maths in a new line too:

    ```math
    f(a) = \frac{1}{2\pi}\int_{0}^{2\pi} (\alpha+R\cos(\theta))d\theta
    ```

    You can also have links: [Julia](http://www.julialang.org) and
    footnotes [^1] for your content [^named].

    And, of course, you can show some code too:

    ```julia
    function say_hi(x)
        print("Hello World")
    end
    ```

    ---

    You can use "quotes" to highlight a section:

    > Multi-line quotes can be helpful to make a 
    > paragraph stand out, so that users won't miss it!
    > You can use **other inline syntax** in you `quotes` too.

    but if you really need to grab someone's attention, use admonitions:

    !!! note
        You can use different levels

    !!! warning
        to send different messages

    !!! danger
        to your reader

    !!! tip "Wow!"
        Turns out that admonitions can be pretty useful!
        What will you use them for?

    ---

    Of course you can have classic lists:
    * item one
    * item two
    * And a sublist:
        + sub-item one
        + sub-item two

    and ordered lists too:
    1. item one
    2. item two
    3. item three


    !!! note "Tables"
        You can use the [Markdown table syntax](https://www.markdownguide.org/extended-syntax/#tables)
        to insert tables - Term.jl will convert them to Table object!

    | Term | handles | tables|
    |:---------- | ---------- |:------------:|
    | Row `1`    | Column `2` |              |
    | *Row* 2    | **Row** 2  | Column ``3`` |


    ----

    This is where you print the content of your foot notes:

    [^1]: Numbered footnote text.

    [^note]:
        Named footnote text containing several toplevel elements.
    """

    code = """
function render(
content::Union{Renderable,RenderableText};
box::Symbol = TERM_THEME[].box,
style::String = TERM_THEME[].line,
title::Union{String,Nothing} = nothing,
title_style::Union{Nothing,String} = nothing,
Δh::Int,
padding::Padding,
background::Union{Nothing,String} = nothing,
kwargs...,
)::Panel
background = get_bg_color(background)
# @info "calling render" content content_measure background

# create top/bottom rows with titles
box = BOXES[box]  # get box object from symbol
top = get_title_row(
    :top,
    box;
    title_style = title_style,
    justify = title_justify,
)

bottom = get_title_row(
    :bottom,
    box,
    subtitle;
    width = panel_measure.w,
)

# get left/right vertical lines
σ(s) = apply_style("\e[0m{" * style * "}" * s * "{/" * style * "}")
left, right = σ(box.mid.left), σ(box.mid.right)

# get an empty padding line
empty = if isnothing(background)
    [Segment(left * " "^(panel_measure.w - 2) * right)]
else
    [Segment(left * "{background}" * " "^(panel_measure.w - 2) * "{/background}" * right)]
end
"""

    junkio = IOBuffer()  # from https://github.com/timholy/SnoopCompile.jl/issues/308

    @compile_workload begin
        reshape_text(txt, 10)
        print(junkio, Panel())
        tprint(junkio, Panel())

        print(junkio, Panel(txt; fit = false, justify = :right, width = 25))
        print(
            junkio,
            Panel(
                txt;
                fit = true,
                title = "test",
                subtitle = "test",
                style = "red on_blue",
                background = "blue",
            ),
        )

        r = RenderableText(txt; width = 30, style = "red")
        r2 = RenderableText(txt)
        p = Panel(txt)
        r * p
        r / p

        hLine(10)
        hLine(100, "test"; style = "red")
        vLine()

        tprintln(junkio, mdtext)

        # repr
        termshow(junkio, Panel)
        termshow(junkio, print)
        termshow(junkio, zeros(100))
        termshow(junkio, zeros(100, 100))
        termshow(junkio, zeros(100, 100, 10))

        # errors
        ctx = StacktraceContext()
        bt = backtrace()

        render_backtrace(ctx, bt)
        render_backtrace(ctx, bt; hide_frames = false)

        code_h = highlight_syntax(code; style = true)
        reshape_code_string(code_h, 30)

        # load_code_and_highlight("src/panels.jl", 20)
    end
end
