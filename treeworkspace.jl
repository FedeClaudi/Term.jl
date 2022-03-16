import Parameters: @with_kw
import MyterialColors: yellow, orange, red, blue

import Term.layout: vstack
import Term: loop_last, replace_double_brackets, escape_brackets, fillin
import Term.segment: Segment
import Term.measure: Measure
import Term.renderables: AbstractRenderable



















# ---------------------------------------------------------------------------- #
#                                   EXAMPLES                                   #
# ---------------------------------------------------------------------------- #



d = Dict(
    "nested" => Dict(
        "n1"=>1,
        "n2"=>2,
    ),  
)

d1 = Dict(
    "nested" => Dict(
        "n1"=>1,
        "n2"=>2,
    ),  
    "nested2" => Dict(
        "n1"=>"a",
        "n2"=>2,
    ),  
)

d2 = Dict(
    "nested" => Dict(
        "n1"=>1,
        "n2"=>2,
    ),  
    "leaf2" => 2,
    "leaf" => 2,
    "leafme" => "v",
    "canopy" => "test",
)


d3 = Dict(
    "nested" => Dict(
        "deeper"=>Dict(
            "aleaf"=>"unbeliefable",
            "leaflet"=>"level 3"
        ),
        "n2"=>Int,
        "n3"=>1 + 2,
    ),  
    "nested2" => Dict(
        "n1"=>"a",
        "n2"=>2,
    ),  
)


d4 = Dict(
    "nested" => Dict(
        "deeper"=>Dict(
            "aleaf"=>"unbeliefable",
            "leaflet"=>"level 3",
            "sodeep" => Dict(
                "a"=>4
            )
        ),
        "n2"=>Int,
        "n3"=>1 + 2,
        "adict"=>Dict(
            "x"=>2
        )
    ),  
    "nested2" => Dict(
        "n1"=>"a",
        "n2"=>2,
    ),  
)

# ----------------------------------- full ----------------------------------- #

# TODO: allow for nested trees to print out correctly
# TODO: fix misplaced guides
# TODO: fill in widths function

print("\n"^20)
import Term: Panel
p(d) = Panel(Tree(d); title="A tree", style="dim", fit=false, width=22, title_style="bold white", padding=(1, 1, 0, 0))

# print(p(d) * p(d1) * p(d2)  * p(d3) * p(d4))
# print(tree)

print(Tree(d) * Tree(d))