


import Term: tprint, highlight, tprintln

txt = """
These are numbers: 12311, 2 122.2321 not a number  121e-4 1.5e10 1/2

These are strings: "aaa" and 
            'dsda33d'
"
alsostrings
over multiple lines
"

These are operators: + - * %  not an operator  ^ /
{green}These are operators: + not an operator - * % ^  / {/green}

These are symbols: :x :abc not a symbol :P_1
This is code: `print(x)` and
```
    do α
    do β
```
vector: [1, 2, 3, 4, "aa", :x]
This is an expression: :(x + y)
"""


print("\n\n"^10)
tprintln(txt)
tprintln("1, 2, 3")


tprintln(zeros(4); highlight=true)


tprintln(Dict(:name=>"test", 1=>:v, :k=>[1, 2, 3]))



# x, y = :z, :(x+Y)
# tprintln("These are the results: x = $(highlight(x)), y = $(highlight(y))")src/layout.jl
# println()

# tprintln(highlight_syntax("""
# import Term

# tprintln("ok")
# """))


