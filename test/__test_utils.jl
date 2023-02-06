import Term: cleantext, chars, textlen, split_lines, replace_multi
import Term: Table

cleanstring(x) = replace(string(x), "\r\n" => "\n")
cleansprint(fn, x) = replace(sprint(fn, x), "\r\n" => "\n")

"""
Write one or multiple strings to a text file so that they can 
later be used for testing.
"""
tofile(content::Vector, filepath) =
    open(filepath, "w") do io
        map(ln -> println(io, ln), content)
        close(io)
    end

tofile(content::String, filepath) =
    open(filepath, "w") do io
        print(io, content)
        close(io)
    end

"""
Load a string representation of a renderable from file
and clean it up
"""
fromfile(filepath) = replace_multi(read(filepath, String), "\\n" => "\n", "\\e" => "\e")

fromfilelines(filepath) = readlines(filepath)

"""
Highlight different characters between two strings.
"""
function highlight_diff(s1::String, s2::String; stop = 500)
    s1 == s2 && return

    r(x) = replace(x, ' ' => "⋅")  # replace spaces for visualization
    c1, c2 = Any[collect(r(s1))...], Any[collect(r(s2))...]
    length(c1) != length(c2) &&
        (@warn "Strings have different length: $(length(c1)) vs $(length(c2))")

    for i in 1:min(length(c1), length(c2))
        a, b = c1[i], c2[i]
        color = a == b ? "default" : "bold black on_red"
        c1[i] = "{$color}$a{/$color}"
        c2[i] = "{$color}$b{/$color}"
    end

    hLine("STRING DIFFERENCE $(length(c1)) chrs", style = "red") |> tprint
    hLine("FIRST", style = "blue") |> tprint
    println(s1)
    hLine("SECOND", style = "blue") |> tprint
    println(s2)
    hLine(style = "dim blue") |> tprint

    i = 1
    while i < (min(length(c1), length(c2)) - 50)
        "{dim}Characters $i-$(i+50){/dim}" |> tprintln
        tprintln(
            "{bold blue}(current){/bold blue}  - " * join(c1[i:(i + 50)]),
            highlight = false,
        )
        tprintln(
            "{bold blue}(correct){/bold blue}  - " * join(c2[i:(i + 50)]),
            highlight = false,
        )
        hLine(style = "dim") |> tprint
        print("\n")
        i += 50
        i > stop && break
    end
    hLine(style = "red") |> tprint
end

"""
Load "correct' string from .txt file and correct new lines
for windows.
"""
function load_from_txt(filename)
    filepath = "./txtfiles/$(filename).txt"
    correct = fromfile(filepath)
    IS_WIN && (correct = replace(correct, "\n" => "\r\n"))
    correct
end

"""
    macro compare_to_string(obj, filename::String, fn::Function=x->x)

Check that the string representation of an object is identical to
what's saved in a .txt file at `filename`. If `obj` is an expression or
a renderable first turn it into a string.

If `TEST_DEBUG_MODE=true`, instead of comparing to a file, save the 
obj's string to the file for future comparison. Also print out
the output for visual inspection.
"""
macro compare_to_string(obj, filename, fn = x -> x, skip = nothing)
    __f = string(__source__.file)
    __l = string(__source__.line)
    quote
        txt = if $obj isa Expr
            @capture_out eval($obj)
        else
            $obj
        end |> string
        txt = $fn(txt)

        !isnothing($skip) && (txt = join(split(txt, '\n')[1:(end - $skip)], '\n'))

        filepath = "./txtfiles/$($filename).txt"

        if TEST_DEBUG_MODE || !isfile(filepath)  # if it doesn't exist, create it.
            print("\n"^3)
            tprintln(txt, highlight = false)
            tofile(txt, filepath)
        else
            correct = load_from_txt($filename)
            txt != correct && (@warn "Failed to match to text" $filename $__f $__l)
            highlight_diff(txt, correct)
            @test txt == correct # <-- TEST
        end
    end |> esc
end

# ----------------------------------- misc ----------------------------------- #

same_widths(text::String) = length(unique(textlen.(split_lines(text)))) == 1

function check_widths(text, width)
    for line in split_lines(text)
        @test textlen(line) <= width
    end
end

"""
Extensively test a panel making sure it has
the right size and Measure
"""
macro testpanel(p, h, w)
    quote
        # isnothing($h) || println(vLine(h) * $p)
        # check all lines have the same length
        _p = string($p)

        dw = displaysize(stdout)[2]
        if isnothing($w) || $w > dw
            return nothing
        else
            widths = textwidth.(cleantext.(split(_p, '\n')))
        end

        # println(p, p.measure, widths)
        @test length(unique(widths)) == 1

        # check it has the right measure
        if !isnothing($w)
            @test $p.measure.w == $w
            _txt = $p.segments[1].text
            @test textlen(cleantext(_txt)) == $w
            @test length(chars(cleantext(_txt))) == $w
        end

        if !isnothing($h)
            @test $p.measure.h == $h
            @test length($p.segments) == $h
        end
    end |> esc
end

macro testtree(p, h, w)
    quote
        # check all lines have the same length
        _p = string($p)

        dw = displaysize(stdout)[2]
        if isnothing($w) || $w > dw
            return nothing
        else
            widths = textwidth.(cleantext.(split(_p, '\n')))
        end

        # println(p, p.measure, widths)
        @test length(unique(widths)) == 1

        # check it has the right measure
        if !isnothing($w)
            @test $p.measure.w == $w
        end

        if !isnothing($h)
            @test $p.measure.h == $h
            @test length($p.segments) == $h
        end
    end |> esc
end

nlines(x) = length(split(x, '\n'))
lw(x) = max(length.(split(x, '\n'))...)

"""
Include but with a timer
"""

macro timeit_include(path::AbstractString)
    return :(@timeit TIMEROUTPUT $path include($path))
end

# ------------------------------- test no throw ------------------------------ #

struct NoException <: Exception end

macro test_nothrow(ex)
    return esc(:(@test_throws NoException ($(ex); throw(NoException()))))
end
