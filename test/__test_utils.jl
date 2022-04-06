import Term: cleantext, chars, textlen, split_lines, replace_multi


function cleanstring(x)
    replace(
        string(x),
        "\r\n" => "\n"
    )
end

function cleansprint(fn, x)
    replace(
        sprint(fn, x),
        "\r\n" => "\n"
    )
end

"""
Write one or multiple strings to a text file so that they can 
later be used for testing.
"""
function tofile(content::Vector, filepath)
    open(filepath, "w") do io
        map(ln -> println(io, ln), content)
        close(io)
    end
end

function tofile(content::String, filepath)
    open(filepath, "w") do io
        print(io, content)
        close(io)
    end
end


"""
Load a string representation of a renderable from file
and clean it up
"""
function fromfile(filepath)::String
    return replace_multi(
        read(filepath, String), "\\n"=>"\n", "\\e" => "\e"
    )
end

function fromfilelines(filepath)
    lines = readlines(filepath)
end






function same_widths(text::String)::Bool
    widths = textlen.(split_lines(text))
    return length(unique(widths)) == 1
end

function check_widths(text, width)
    for line in split_lines(text)
        @test textlen(line) <= width
    end
end


"""
Extensively test a panel making sure it has
the right size and Measure
"""
function testpanel(p, w, h)
    # check all lines have the same length
    _p = string(p)

    dw = displaysize(stdout)[2]
    if isnothing(w) || w > dw
        return
    else
        widths = textwidth.(cleantext.(split(_p, "\n")))
    end
    
    # println(p, p.measure, widths)
    @test length(unique(widths)) == 1

    # check it has the right measure
    if !isnothing(w)
        @test p.measure.w == w
        @test textlen(cleantext(p.segments[1].text)) == w
        @test length(chars(cleantext(p.segments[1].text))) == w
    end

    if !isnothing(h)
        @test p.measure.h == h
        @test length(p.segments) == h
    end
end

function testtree(p, w, h)
    # check all lines have the same length
    _p = string(p)

    dw = displaysize(stdout)[2]
    if isnothing(w) || w > dw
        return
    else
        widths = textwidth.(cleantext.(split(_p, "\n")))
    end
    
    # println(p, p.measure, widths)
    @test length(unique(widths)) == 1

    # check it has the right measure
    if !isnothing(w)
        @test p.measure.w == w
    end

    if !isnothing(h)
        @test p.measure.h == h
        @test length(p.segments) == h
    end
end

nlines(x) = length(split(x, "\n"))
lw(x) = max(length.(split(x, "\n"))...)


"""
Include but with a timer
"""

macro timeit_include(path::AbstractString)
    return :(@timeit TIMEROUTPUT $path include($path))
end


# ------------------------------- test no throw ------------------------------ #

struct NoException <: Exception end

macro test_nothrow(ex)
    esc(:(@test_throws NoException ($(ex); throw(NoException()))))
end
