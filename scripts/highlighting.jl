


import Term: tprint, highlight, tprintln

print("\n\n"^10)

txt = """
{bold underline bright_blue}Term.jl{/bold underline bright_blue} highlights numbers: 123 1.5e10 1/2 and "strings too"

Operators are colored red: + - * % ^ / while symbols are orange: :x :y :z

Code looks like this:
```
    do α
    do β
```

And you can highlight expression like :(x + y) too.
"""
tprintln(txt)





# tprintln("1, 2, 3")


# tprintln(zeros(4); highlight=true)


# tprintln(Dict(:name=>"test", 1=>:v, :k=>[1, 2, 3]))



# x, y = :z, :(x+Y)
# tprintln("These are the results: x = $(highlight(x)), y = $(highlight(y))")src/layout.jl
# println()

# tprintln(highlight_syntax("""
# import Term

# tprintln("ok")
# """))


