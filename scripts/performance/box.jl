import Term.box: ROUNDED, get_row, get_title_row, fit
import Term
println("get row")
@time get_row(ROUNDED, [3], :top)
@time get_row(ROUNDED, 3, :top)

println("get title row")
@time get_title_row(:top, Term.box.ROUNDED, nothing, width=12, style="red")

for justify in (:left, :center, :right)
    @time get_title_row(:top, Term.box.ROUNDED, "test", width=12, 
                                justify=justify, title_style="blue", style="red")                                                       
end