import Term: remove_markup,
            remove_ansi,
            cleantext,
            escape_brackets,
            unescape_brackets,
            replace_text,
            fillin, truncate,
            do_by_line,
            textlen,
            join_lines, split_lines

import Term.consoles: clear

# clear()
print("\n"^3)


string = "text [red] text [/text] [red blue]fsfdsfs[/] test\n sfsdfsdf[red]\n fsdfsd[/red]"
ansistring = "text \e[31m text [/text] \e[39m\e[34mfsfdsfs\e[39m\e[31m test\n sfsdfsdf\e[39m\e[31m\n fsdfsd\e[39m\e[31m\e[39m"

println("remove markup")
@time  remove_markup(string)

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
@time do_by_line(
    fn, text
)


nothing


