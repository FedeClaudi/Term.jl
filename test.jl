"""
Replaces:
    [[ with {
    ]] with }
    \e[ with \e{
    \\033[ with \\033{
"""
function escape_brackets(text::String)
    text = replace(text, "[[" => "{")
    text = replace(text, "}}" => "}")
    text = replace(text, "\e[" => "{{")
    text = replace(text, "\\033[" => "{{{")
    return text
end

text= "\e[1;31;49mHello\e[0m [white on_blue]---[/white on_blue] [green]Test[/green] --- [black on_green]success![/black on_green]?"


println(escape_brackets(text))

@info "le" length(text) length(escape_brackets(text))
