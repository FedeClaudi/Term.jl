import Term.Tables: Table
import Term.Layout: PlaceHolder

t = 1:5
data = hcat(t, ones(length(t)), string.(ones(length(t)) .* 100000))

t1 = Table(data)
t2 = Table(
    data;
    header = ["Num", "Const.", "Values"],
    header_style = "bold white",
    columns_style = ["dim", "bold", "red"],
)
t3 = Table(
    data;
    header = ["Num", "Const.", "Values"],
    header_style = "bold white",
    columns_style = ["dim", "bold", "red"],
    hpad = [1, 2, 5],
    columns_justify = [:center, :right, :left],
    vpad = 1,
)
t4 = Table(data; footer = ["get", "a", "footer"], footer_justify = :center)

if VERSION >= v"1.7.1"
    t5 = Table(data; footer = sum, footer_justify = :center, footer_style = "dim bold")

    t7 = Table(data; columns_widths = [25, 7, 7], footer = sum, box = :SIMPLE)
end

ph1 = PlaceHolder(25, 5)
ph2 = PlaceHolder(23, 9)
ph3 = PlaceHolder(22, 11)

data = Dict(
    "first\ncol." => [ph1, ph2, ph3],
    "second\ncol." => [ph3, ph2, ph3],
    "third\ncol." => [ph2, ph2, ph1],
)

t6 = Table(data)

X = rand(RNG, 5, 3)
t8 = Table(
    X;
    columns_widths = [12, 10, 22],
    hpad = 2,
    columns_justify = [:left, :center, :left],
)

# save tables as strings to files
if VERSION >= v"1.7.1"
    tbls = [t1, t2, t3, t4, t5, t6, t7, t8]
else
    tbls = [t1, t2, t3, t4, nothing, t6, nothing, t8]
end

@testset "TABLE" begin
    for (i, t) in enumerate(tbls)
        isnothing(t) && continue
        name = string("table_$i")

        IS_WIN || @compare_to_string(cleanstring(t), name)
    end

    # test table with problems
    VERSION >= v"1.7.1" &&
        Table(data; columns_widths = [25, 7, 7, 12, 41, 52], footer = sum, box = :SIMPLE)
end
