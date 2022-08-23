import Term: cleantext, chars, textlen, split_lines, replace_multi

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

fromfilelines(filepath) = lines = readlines(filepath)

"""
Highlight different characters between two strings
"""
function highlight_diff(s1::String, s2::String)
    s1 == s2 && return
    c1, c2 = Any[collect(s1)...], Any[collect(s2)...]
    length(c1) != length(c2) &&
        (@warn "Strings have different length: $(length(c1)) vs $(length(c2))")

    for i in 1:min(length(c1), length(c2))
        a, b = c1[i], c2[i]
        color = a == b ? "green" : "red"
        c1[i] = "{$color}$a{/$color}"
        c2[i] = "{$color}$b{/$color}"
    end
    tprintln(join(c1))
    tprintln(join(c2))
end

"""
If in testing debug mode: print the renderable `obj`
and save the string to file, if not, load the string from
file and compare to the obj.
"""
function compare_to_string(obj, filename::String)
    filepath = "./txtfiles/$filename.txt"
    if TEST_DEBUG_MODE
        @info "TEST DEBUG" filename typeof(obj)
        println(obj)
        tofile(string(obj), filepath)
        return string(obj)
    else
        correct = fromfile(filepath)
        IS_WIN && (correct = replace(correct, "\n" => "\r\n"))
        highlight_diff(txt, correct)
        @test string(obj) == correct
        return correct
    end
end

function compare_to_string(txt::AbstractString, filename::String)
    filepath = "./txtfiles/$filename.txt"
    if TEST_DEBUG_MODE
        @info "TEST DEBUG" filename
        tprint(txt)
        tofile(txt, filepath)
        return txt
    else
        correct = fromfile(filepath)
        IS_WIN && (correct = replace(correct, "\n" => "\r\n"))
        highlight_diff(txt, correct)
        @test txt == correct
        return correct
    end
end

"""
Evaluate `expr` capturing the output as a string and comparing to 
a saved text at filename.
"""
function compare_to_string(expr::Expr, filename::String, fn::Function = (x) -> x)
    out = @capture_out eval(expr)
    filepath = "./txtfiles/$filename.txt"
    if TEST_DEBUG_MODE
        @info "TEST DEBUG" filename
        tprint(out)
        tofile(out, filepath)
        return out
    else
        correct = fromfile(filepath)
        IS_WIN && (correct = replace(correct, "\n" => "\r\n"))
        highlight_diff(txt, correct)
        @test fn(out) == correct
        return correct
    end
end

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
