print("\n\n\n\n")

println("PRECOMILATION")
@time include("../src/Term.jl")

runnable = quote
    originalSTDOUT = stdout
    (outRead, outWrite) = redirect_stdout()

    t = 1:5
    tb_data1 = hcat(t, ones(length(t)), rand(Int8, length(t)))

    Term.Panel() * Term.Panel("aa"*"bb"; fit=true) / Term.Panel("aaa"; width=25, title="test") |> Term.tprint

    Term.hLine() * Term.vLine()
    Term.Panel(Term.hLine(), Term.vLine(),  Term.RenderableText("test"))

    Term.Tables.Table(
        tb_data1;
        header = ["Num", "Const.", "Values"],
        header_style = "bold white",
        columns_style = ["dim", "bold", "red"],
    ) |> Term.tprint

    close(outRead)
    redirect_stdout(originalSTDOUT)
end

println("\n\nFIRST RUN")
tstart = time(); eval(runnable); tend=time(); 
tend-tstart |> println

println("\nSECOND RUN")
tstart = time(); eval(runnable); tend=time(); 
tend-tstart |> println
