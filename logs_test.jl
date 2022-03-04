import Term: tprint, theme, textlen
import Term.box: ROUNDED, SQUARE
import Term: remove_markup, remove_markup_open
import Term: install_stacktrace

install_stacktrace()

struct CodeNode
    mod::String
    fn::Union{Nothing, String}
    file::String
    line::String
end

Base.show(io::IO, node::CodeNode) = print(io, "(CodeNode) Function $(node.mod).$(node.fn) at $(node.file):$(node.line)")


macro tinfo(args...)
    return quote
        # get trigger code line
        st = stacktrace(backtrace())
        myf = nothing
        for frm in st
            funcname = frm.func
            if frm.func != :backtrace && frm.func!= Symbol("macro expansion")
                myf = frm.func
                break
            end
        end

        cn = CodeNode(
            $("$(__module__)"),
            "$(myf)",
            $("$(__source__.file)"),
            $("$(__source__.line)")
        )
        

        # get outline elements with style
        color = "#90CAF9"
        outline_markup = "$color dim"
        hor = "[$outline_markup]▶[/$outline_markup]"
        vert = "[$outline_markup]" * ROUNDED.mid.left * "[/$outline_markup]"
        bottom = "[$outline_markup]" * ROUNDED.bottom.left * "[/$outline_markup]"

        # crate log ijnfo content
        content = ["""  
                [$color underline]@info:[/$color underline] [#FFF59D]$(cn.mod).[/#FFF59D][#FFEE58]$(cn.fn)[/#FFEE58]
                   $vert   [dim]$(cn.file):$(cn.line) [/dim][bold dim](line: $(cn.line))[/bold dim]
                   $vert"""]
        cw = (Int ∘ round)(textlen(content[1])/2)

        for (n, arg) in enumerate($(args))
            # start line with type if args
            _line = "[$(theme.type) dim]($(typeof(arg)))[/$(theme.type) dim]"
            pad = 9 - textlen(_line)
            pad = pad < 0 ? 1 : pad
            _line = _line * " "^pad * hor * " "

            # get sylized representation of arg
            if arg isa AbstractString
                _line *= "[$(theme.string)]$arg[/$(theme.string)]"

            elseif arg isa Symbol
                val = nothing
                try
                    # val = eval(arg)
                    val = $(arg)
                catch
                    val = "[bold red]not a valid symbol![/bold red]"   
                end
                _line *= "[$(theme.symbol)]:$arg[/$(theme.symbol)] $val"

            elseif arg isa Expr
                # e = Expr(:kw, Symbol(arg), esc(arg))
                # println(e)
            
                # _line *= "[$(theme.expression)]$arg[/$(theme.expression)] [$(theme.operator)]=[/$(theme.operator)] [italic]$(eval(arg))[/italic]"
                _line *= "[$(theme.expression)]$arg[/$(theme.expression)]"

            else
                _line *= "$arg"
            end

            # # TODO if line content is multi lined, reshape text correctly

            # put everything together
            push!(content, "   $vert " * _line)
        end
        push!(content, "   [#90CAF9 bold dim]$(ROUNDED.bottom.left)" * "$(ROUNDED.row.mid)"^(cw) * "[/#90CAF9 bold dim]")

        tprint(join(content, "\n"))

    end
end


function foo()
    x = 1
    @info "this sis sodifsdfnso" 1+1 x 2x
    @tinfo "this sis sodifsdfnso" 1+1 x 2x
end

foo()

# TODO fix error in errors.jl line 203
# TODO eval expressions
# TODO get variable value
# see: https://github.com/JuliaLang/julia/blob/2f67b51c70280cf7f0f2da5de2e7769da0d49869/base/logging.jl#L323
