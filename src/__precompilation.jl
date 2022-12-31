
# ---------------------------------------------------------------------------- #
#                                PRECOMPILATION                                #
# ---------------------------------------------------------------------------- #
originalSTDOUT = stdout
(outRead, outWrite) = redirect_stdout()

using SnoopPrecompile
SnoopPrecompile.verbose[] = false

@precompile_setup begin
    txt = join(
        repeat(["this is a random {red}text{/red} to test {bold}precompilation"], 10),
        "\n",
    )
    print(txt)

    @precompile_all_calls begin
        reshape_text(txt, 10)
        Panel() |> tprint

        Panel(txt; fit = false, width = 25) |> tprint
        Panel(txt; fit = true) |> tprint

        r = RenderableText(txt; width = 30, style = "red")
        r2 = RenderableText(txt)
        p = Panel(txt)
        r * p
        r / p
    end
end

close(outRead)
redirect_stdout(originalSTDOUT)
