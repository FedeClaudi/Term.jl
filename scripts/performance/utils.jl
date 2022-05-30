import Term:
    remove_markup,
    remove_ansi,
    cleantext,
    escape_brackets,
    unescape_brackets,
    replace_text,
    fillin,
    truncate,
    do_by_line,
    textlen,
    join_lines,
    split_lines,
    reshape_text

import Term.Console: clear

# clear()
print("\n"^3)

string = "text [red] text [/text] [red blue]fsfdsfs[/] test\n sfsdfsdf[red]\n fsdfsd[/red]"
ansistring = "text \e[31m text [/text] \e[39m\e[34mfsfdsfs\e[39m\e[31m test\n sfsdfsdf\e[39m\e[31m\n fsdfsd\e[39m\e[31m\e[39m"

println("remove markup")
@time remove_markup(string)

println("remove_ansi")
@time remove_ansi(ansistring)

println("clean text")
@time cleantext(ansistring)

println("escape regexes")
double = @time escape_brackets(string)
@time unescape_brackets(double)

println("replace_text")
text = "this is SOME text"
@time replace_text(text, 5, 8, "test")

println("Fillin")
text = """
aasdas
adadasdasdas
aasdas
"""
@time fillin(text)

println("truncate")
@time truncate(string, 5)

println("split/join")
@time split_lines(text)
@time join_lines(split_lines(text))

println("do by line")
fn(l::String)::String = truncate(l, 5)
@time do_by_line(fn, text)

println("reshape text")
text = """aaa a  aas[red]red
red red  red red red redredred[/red] asdsdfsfsfsfsdsfdfsada [blue] blue blue
blue blueblue blue blueblue  [/blue] asdasd
asda """
@time reshape_text(text, 10)

pts = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
@time reshape_text(pts, 20)
pts = """Lorem ipsum dolor sit amet, consectetur adipiscing elit,
ed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
 veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex 
 ea commodo consequat. Duis aute irure dolor in reprehenderit 
 in voluptate velit esse cillum dolore eu fugiat nulla 
 pariatur. Excepteur sint occaecat cupidatat non proident, 
 sunt in culpa qui officia deserunt mollit anim 
 id est laborum."""
@time reshape_text(pts, 10)

# TODO reshape_text splitting ANSI tags
nothing
