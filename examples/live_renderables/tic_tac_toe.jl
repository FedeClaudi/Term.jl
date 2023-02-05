using Term
using Term.LiveWidgets
using Term.Compositors
import Term.LiveWidgets: Esc, quit, ArrowLeft, ArrowDown, ArrowRight, ArrowUp
import Term.Style: apply_style

"""
More advanced example of how to build a function with 
a bunch of additional functionality and customization
compared to usual usage.

The app allows the user to play tic tac toe and to read 
some instructions about the game. The tic tac toe "gameborad"
is made of cells. These cells gets highlighted when activated 
and the user can choose to place an X or an O in the cell.
"""

# set layout with cells' 3x3 grid and a pager by the side
h = 9
h2 = 3 * h - 1
layout = :(
    (
        (A($h, 0.15) * B($h, 0.15) * C($h, 0.15)) /
        (D($h, 0.15) * E($h, 0.15) * F($h, 0.15)) /
        (G($h, 0.15) * H($h, 0.15) * I($h, 0.15))
    ) * Z($h2, 0.55)
)

"""
The board's cells are TextWidgets, define some function
to change the widget's text when the user draws and x or a o.
"""

"""
write a X made of multiple line of characters
"""
x = RenderableText(
    """xx    xx
 xx  xx
  xxxx
  xxxx
 xx  xx
xx    xx""";
    style = "red",
) |> string |> rstrip

o = RenderableText(
    """  oooooo
 oo    oo
oo      oo
oo      oo
 oo    oo
  oooooo""";
    style = "blue",
) |> string |> rstrip

""" set widget's text"""
set_text(widget, text) =
    if text == 'x'
        widget.text = x
    else
        widget.text = o
    end

"""
Define some functions to show when a cell is highlighted
"""

function on_cell_highlighted(cell)
    cell.panel_kwargs[:style] = "whie on_gray23"
end

function on_cell_not_highlighted(cell)
    cell.panel_kwargs[:style] = "dim"
end

"""
Define keyboard controls
"""

button_controls = Dict('x' => set_text, 'o' => set_text, 'q' => quit, Esc() => quit)

"""
Create a widget for each cell
"""

widgets = Dict{Symbol,Any}(
    map(
        c ->
            c => TextWidget(
                "";
                controls = button_controls,
                as_panel = true,
                on_activated = on_cell_highlighted,
                on_deactivated = on_cell_not_highlighted,
                padding = (1, 0, 0, 0),
                justify = :center,
                style = "dim",
            ),
        (:A, :B, :C, :D, :E, :F, :G, :H, :I),
    )...,
)

widgets[:Z] = Pager("""
Tic-tac-toe, also known as noughts and crosses, 
is a simple two-player game that has been enjoyed
by people of all ages for many years. The game 
is played on a 3x3 grid, typically made up of 
a pencil and paper or a game board. Each player
takes turns placing their symbol (an "X" or an "O") on
the grid, with the goal of getting three of their
 symbols in a row, either horizontally, 
 vertically, or diagonally.

The origins of tic-tac-toe are uncertain, but it 
is believed to have originated in ancient Egypt,
Greece, or Roman times. The game has been played 
in various forms throughout history and has been known
by different names in different cultures. The game 
was known as "tic-tac-toe" in the United States in the
early 20th century, and it became popular in the 1930s. 
The name "tic-tac-toe" is thought to have come from the 
sound that people made when they made the X or O marks on the game board.

Tic-tac-toe is a simple game that can be played by people
of all ages and skill levels, making it a popular pastime 
for families and friends. The game is often used as a tool
for teaching basic strategic thinking and problem-solving
skills to children. It is also a popular game 
to play in the classroom as an educational tool.

In the 20th century, tic-tac-toe was adopted as a game 
for computers, and the first computer game of tic-tac-toe 
was developed in 1952. Since then, it has been used as 
a benchmark problem for artificial intelligence research 
and has been widely used to teach computer science 
students the basics of game theory and artificial intelligence.

Tic-tac-toe has evolved over time, and it's now possible to 
play it on smartphones, tablets, and computers. There are also 
many variations of the game, such as 3D tic-tac-toe, and 
games that use a larger grid or more symbols.

In conclusion, Tic-tac-toe is a simple but challenging 
game that has been enjoyed by people for centuries. It's a 
game that's easy to learn but difficult to master, making it 
a popular pastime for families and friends. The game's simplicity 
has also made it a popular educational tool and a benchmark 
åproblem for artificial intelligence research.
""")

"""
Define a custom set of transition rules
to specify how to move between cells
using keyboard controls.
"""

transition_rules = Dict(
    ArrowDown() => Dict(:A => :D, :B => :E, :C => :F, :D => :G, :E => :H, :F => :I),
    ArrowUp() => Dict(:D => :A, :E => :B, :F => :C, :G => :D, :H => :E, :I => :F),
    ArrowRight() => Dict(
        :A => :B,
        :B => :C,
        :D => :E,
        :E => :F,
        :G => :H,
        :H => :I,
        :C => :Z,
        :F => :Z,
        :I => :Z,
    ),
    ArrowLeft() =>
        Dict(:B => :A, :C => :B, :E => :D, :F => :E, :H => :G, :I => :H, :Z => :A),
)

app = App(layout; widgets = widgets, transition_rules = transition_rules)
play(app; transient = false);

nothing
