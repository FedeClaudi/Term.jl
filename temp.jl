import Term.progress: ProgressBar, start!, stop!, addjob!, update!, with


# TODO make this work

replace_expr_args(arg, vname) = arg == vname ? :__itervalue__ : arg
replace_expr_args(expr::Expr, vname) = Expr(expr.head, replace_expr_args.(expr.args, vname)...)

macro track(args...)
    quote
        vname = $args[1].args[2]
        iterable = eval($args[1].args[3])

        looplines = string.(map(e -> replace_expr_args(e, vname), $args[2].args[2:2:end]))
        # looplines = replace.(looplines, "__itervalue__"=>raw"$__itervalue__")

        # dump(looplines[1])


        # pbar = ProgressBar()
        # N = length(iterable)

        # # with(pbar) do
        #     job = addjob!(pbar; N=N)
            for __itervalue__ in iterable
        #         # eval.(map(e -> replace_expr_args(e, vname, itervalue), $args[2].args[2:2:end]))
                eval.(Meta.parse.(
                    replace.(looplines, "__itervalue__"=>__itervalue__)
                ))
            end

        #         # # eval.(looplines)
        #         # @info _looplines
        #         # # update!(job)
        #         # sleep(.1)
        #     end
        # # end
    end
end

function test()
    println("\n\nMacro")
    @time begin
        @track i in 1:10 begin
            print(i^2 + sqrt(100))
            sleep(.1)
        end
    end

    println("\njust loop")
    @time begin
        for i in 1:10
            print(i^2 + sqrt(100))
            sleep(.1)
        end
    end
end

test()
test()
