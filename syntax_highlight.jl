import Term: highlight_syntax, read_file_lines
import Term.style: apply_style, rehsape_text

import Term: hLine, TextBox

println(hLine(50))


function load_code_and_highlighy(path, lineno; δ=3, width=120)
    η = countlines(path)
    @assert lineno > 0 "lineno must be ≥1"
    @assert lineno ≤ η "lineno $lineno too high for file with $(η) lines"

    lines = read_file_lines(_file, lineno-9, lineno+10)
    linenos = [ln[1] for ln in lines]
    lines = [ln[2] for ln in lines]
    code =  split(highlight_syntax(join(lines); style=false), "\n")

    # clean
    clean(line) =replace(line, "    [/    ]"=>"")
    if η - lineno < 10
        @warn "alarm" length(code)
        println(TextBox(join(code, "\n")))
    end
    codelines = clean.(code)  # [10-δ:10+δ]
    linenos = linenos  # [10-δ:10+δ]

    # make n lines match
    if lineno ≤  δ
        codelines = clean.(code)[1:lineno+δ]
        linenos = linenos[1:lineno+δ]
    elseif η - lineno ≤ δ
        codelines = clean.(code)[end-δ:end]
        linenos = linenos[end-δ:end]
    else
        codelines = clean.(code)[10-δ:10+δ]
        linenos = linenos[10-δ:10+δ]
    end

    # format
    cleaned_lines = []
    for (n, line) in zip(linenos, codelines)        
        # style
        if n == lineno
            symb = "[red bold]▶[/red bold]"
            color = "white"
        else
            symb = " "
            color = "grey39"
        end

        # end
        line = symb * " [$color]$n[/$color] " * line
        push!(cleaned_lines, line)
    end

    return cleaned_lines
end



lineno = 265
_file = "/Users/federicoclaudi/Documents/Github/Term.jl/src/stacktrace.jl"
cleaned_lines = load_code_from_file(_file, lineno)

println(
    TextBox(
        join(cleaned_lines, "\n"),
        width=120,
        fit=:truncate
    )
)





# println(code)