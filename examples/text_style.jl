"""
This example shows how to use Term.jl to print styled text to the console.

The easiest way to apply style to a String is to use Markup Tags.

Let's say you have this string: 

s = "this is my string!"

and you want 'my' to be bold and blue, then simply write:

s = "this is [bold blue]my[/bold blue] string!

The [xx]text[/xx] syntax will result in the style 'xx' being applied to the
text between parentheses.
The style can include things like: `bold`, `underline`, `italic`, `red`, `blue`...
all separated by a space. You can also use hexcodes (like #ff0022) to specify 
the color of your text.


Once you're happy with your markup string, you can use `Term.tprintln` to print it!

Note: the second set of parentheses, [/xx], terminates the markup tag and the style
information 'xx' must be identical between the start/end parentheses.
"""

import Term: tprintln

my_string = "{bold underline}This{/bold underline} is {red italic}my{/red italic} {on_green black bold}string{/on_green black bold}"
tprintln(my_string)

"""
Using markup tags is great when you want your styled text to be printed within other `Renderable` object
from Term such as `TextBox` and `Panel` (see examples).

But if you just need to quickly print something with a bit of color, you don't want to be typing all those [,].
Fortunately, Term provides a set of macros to easily print styled strings!!
"""

import Term: @red, @blue, @style

println(@red "This is red")
println(@blue "and this is blue")

# or, if you want some more control
println(@style "this is my beautifully styled text" green italic bold)
