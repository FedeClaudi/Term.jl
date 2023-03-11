using Term
import Term.Tables: Table
import Term.Layout: PlaceHolder

install_term_stacktrace()

"""
    This is an example showing how to create tables in Term.jl

There's MANY options to tables, so we can't cover all of them here, head to the docs
for more info.
"""

t = 1:5
data = hcat(t, ones(length(t)), rand(Int8, length(t)))

"""
You can create data from `Matrix` and `Vector` objects
"""

print(Table(data))

"""
You can justify the table headers
"""

print(
    Table(
        data;
        header = ["Num", "Const.", "Values"],
        header_style = "bold white",
        columns_style = ["dim", "bold", "red"],
    ),
)

"""
For most of the options, you can either pass a single value
(which gets applied to a whole column/row) or a vector of values
to e.g. specify the style of each column independently.

You can use vertical/horizontal padding to space out the table.
"""

print(
    Table(
        data;
        header = ["Num", "Const.", "Values"],
        header_style = "bold white",
        columns_style = ["dim", "bold", "red"],
        hpad = [1, 2, 5],
        columns_justify = [:center, :right, :left],
        vpad = 1,
    ),
)

"""
You can also specify footers
"""

print(Table(data; footer = ["get", "a", "footer"], footer_justify = :center))

"""
    Or even use a function that gets applied column wise
"""

print(Table(data; footer = sum, footer_justify = :center, footer_style = "dim bold"))

"""
You can use different `Box` types to change the table style.
And you can create layouts with tables as you would with any
other renderables.
"""

print(
    (Table(data; box = :ROUNDED, style = "red") * " " * Table(data; box = :HEAVY)) /
    Table(data; box = :SIMPLE_HEAVY, style = "dim blue"),
)

"""
Tables can also be created from `Dict` objects and can include other
renderables.
"""

ph1 = PlaceHolder(5, 25)
ph2 = PlaceHolder(9, 23)
ph3 = PlaceHolder(11, 22)

data = Dict(
    "first\ncol." => [ph1, ph2, ph3],
    "second\ncol." => [ph3, ph2, ph3],
    "third\ncol." => [ph2, ph2, ph1],
)

print(Table(data))
