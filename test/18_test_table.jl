import Term.Tables: Table
import Term.Layout: PlaceHolder

t = 1:5
data = hcat(t, ones(length(t)), rand(Int8, length(t)))

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

t5 = Table(data; footer = sum, footer_justify = :center, footer_style = "dim bold")

ph1 = PlaceHolder(25, 5)
ph2 = PlaceHolder(23, 9)
ph3 = PlaceHolder(22, 11)

data = Dict(
    "first\ncol." => [ph1, ph2, ph3],
    "second\ncol." => [ph3, ph2, ph3],
    "third\ncol." => [ph2, ph2, ph1],
)

t6 = Table(data)

# save tables as strings to files
tbls = [t1, t2, t3, t4, t5, t6]
for (i, t) in enumerate(tbls)
    tofile(string(t), "./txtfiles/table_$i.txt")
end

@testset "TABLE" begin
    for (i, t) in enumerate(tbls)
        @test fromfile("./txtfiles/table_$i.txt") == cleanstring(t)
    end
end
