import Term: tprint, theme, textlen
import Term.box: ROUNDED, SQUARE
import Term: remove_markup, remove_markup_open

struct CodeNode
    mod::String
    fn::Union{Nothing, String}
    file::String
    line::String
end

Base.show(io::IO, node::CodeNode) = print(io, "(CodeNode) Function $(node.mod).$(node.fn) at $(node.file):$(node.line)")

macro codeLocation()
    return quote
        st = stacktrace(backtrace())
        myf = nothing
        for frm in st
            funcname = frm.func
            if frm.func != :backtrace && frm.func!= Symbol("macro expansion")
                myf = frm.func
                break
            end
        end

        CodeNode(
            $("$(__module__)"),
            "$(myf)",
            $("$(__source__.file)"),
            $("$(__source__.line)")
        )
    end
end


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
            # start line with type if arg
            line = "[$(theme.type)]($(typeof(arg)))[/$(theme.type)]"
            pad = 9 - textlen(line)
            pad = pad < 0 ? pad : pad
            line = line * " "^pad * hor * " "
            lpad = textlen(line)

            # get sylized representation of arg
            if arg isa AbstractString
                line *= "[$(theme.string)]$arg[/$(theme.string)]"
            elseif arg isa Symbol
                val = nothing
                try
                    val = eval(arg)
                catch
                    val = "not a valid symbol"   
                end
                line *= "[$(theme.symbol)]:$arg[/$(theme.symbol)] $val"
            elseif arg isa Expr
                line *= "[$(theme.expression)]$arg[/$(theme.expression)] [$(theme.operator)]=[/$(theme.operator)] [italic]$(eval(arg))"
            else
                line *= "$arg"
            end

            # TODO if line content is multi lined, reshape text correctly

            # put everything together
            delim = n == length($(args)) ? "$bottom $hor" : "$vert $hor"
            push!(content, "   $vert " * line)
        end
        push!(content, "   [#90CAF9 bold dim]$(ROUNDED.bottom.left)" * "$(ROUNDED.row.mid)"^(cw) * "[/#90CAF9 bold dim]")

        tprint(join(content, "\n"))

    end
end


function foo()
    x = 1
    @tinfo adasdada "this sis sodifsdfnso" 1+1 x 2x
end

foo()

# TODO eval expressions
# TODO get variable value
# see: https://github.com/JuliaLang/julia/blob/2f67b51c70280cf7f0f2da5de2e7769da0d49869/base/logging.jl#L323

