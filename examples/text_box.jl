"""
    This example shows how to use TextBox



Sometimes, you have a very long piece of text to print to the console.
But you don't want to just print one long string, you want your text to e.g., have a fixed width. 
Maybe you want it to fit within a larger layout of Term Renderables (see layout example). 
Or maybe you just want to control the text's appeareance.

Whatever the reason, TextBox is here for you.
"""

import Term: @green, TextBox

my_long_text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

println(@green "This is what it looks like if you just print it out:")
println(my_long_text)

println(@green "\n\nAnd now in a textbox:")
print(TextBox(my_long_text))

"""
note that textbox is really printing a `Term.Panel` object, so all the arguments
you'd use in a panel can be used here for more creating control (see panels example)
"""

print(
    TextBox(
        my_long_text;
        title = "This is my long text",
        title_style = "bold red",
        title_justify = :center,
        subtitle = "styled by Term.jl",
        subtitle_justify = :right,
        subtitle_style = "dim",
    ),
)

"""
And of course it works well with markup styles too
"""
another_long_one =
    "This is a [red bold]long[/red bold] piece of [green italic]content[/green italic]. But TextBox can handle [underline]anything[/underline]!! "^5

print(TextBox(another_long_one; width = 44))

"""
And of course you can use Term.jl's layout syntax to compose TextBox objects, 
see layout example.

ps: this might not print correctly on smaller screens since you're asking for a 
very wide piece of text
"""

tb1 = TextBox(
    my_long_text;
    title = "This is my long text",
    title_style = "bold red",
    title_justify = :center,
    subtitle = "styled by Term.jl",
    subtitle_justify = :right,
    subtitle_style = "dim",
    width = 44,
)

tb2 = TextBox(
    another_long_one;
    width = 40,
    title = "second column",
    title_style = "blue bold",
    title_justify = :center,
)
print(tb1 * tb2)

""" or even 

ps: this might not print correctly on smaller screens since you're asking for a 
very wide piece of text
"""

import Term: Panel
print(Panel(tb1 * tb2; width = 100, justify=:center, title = "My Panel"))


"""
For copmarison, we can try to use RenderableText instead of TextBox
"""

import Term: RenderableText
print(Panel(RenderableText(my_long_text; width=44) * RenderableText(another_long_one; width=40); width = 100, justify=:center, title = "My Panel"))


"""
Ooopss, that doesn't look great. We can remedy this with a Spacer layout object.
However you get the idea, textbox behave more intutively. We can use 
padding to control how much space we want around our text
"""
tb1 = TextBox(my_long_text; width=38, padding=(0, 10, 0, 0))
tb2 = TextBox(my_long_text; width=30, padding=(0, 0, 1, 1))
print(
    tb1 * tb1
)

print(
    tb2 * tb2
)