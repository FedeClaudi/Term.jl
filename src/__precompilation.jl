# ---------------------------------------------------------------------------- #
#                                     DATA                                     #
# ---------------------------------------------------------------------------- #


"""
Define a bunch of stuff we'll use to create renderables and call Term's methods
during precompilation.
"""

# ----------------------------------- TABLE ---------------------------------- #
 t = 1:5
 tb_data1 = hcat(t, ones(length(t)), rand(Int8, length(t)))
 


# ----------------------------------- LOREM ---------------------------------- #
lorem = replace(
    """
Lorem ipsum {bold}dolor sit{/bold} amet, consectetur adipiscing elit,
ed do e{red}iusmod tempor incididunt{/red} ut {bold}labore et {underline}dolore{/underline} magna aliqua.{/bold} Ut enim ad minim
veniam, quis{green} nostrud exercitation {on_black}ullamco laboris nisi ut aliquip ex {/on_black}
ea commodo consequat.{blue} Duis aute irure dolor in{/blue} reprehenderit 
in voluptate velit{/green} esse {italic}cillum dolore{/italic}{red} eu{/red}{italic green} fugiat {/italic green}nulla 
pariatur. Excepteur{red} sint{/red}{blue} occaecat cupidatat {/blue}non proident, 
sunt in culpa qui {italic}officia{/italic} deserunt mollit anim 
id est laborum.""",
    "\n" => "",
)


 # ---------------------------------------------------------------------------- #
 #                                PRECOMPILATION                                #
 # ---------------------------------------------------------------------------- #

 using SnoopPrecompile
 SnoopPrecompile.verbose[] = false


 @precompile_setup begin
    originalSTDOUT = stdout
    (outRead, outWrite) = redirect_stdout()

    @precompile_all_calls begin
        # renderables and layout
        Panel("test") * Panel(Panel()) / hLine(20) * "aa"/"BB" |> tprint
        Panel("this panel has fixed width, text on the left"; width = 66, justify = :left)
        Panel("this one too, but the text is at the center!"; width = 66, justify = :center)
        Panel("the text is here!"; width = 66, justify = :right)
        Panel("this one fits its content"; fit = true)


        RenderableText(lorem; width=50)


        # repr | termshow does a lot of things like printing highlighted code and markdown
        # so it leads to compilation of lots of methods
        termshow(Panel)
        termshow(Dict(:x => 1))
        termshow(print)
        termshow(zeros(4))
        termshow(zeros(4, 4))
        termshow(zeros(4, 4, 4))

        # table
        Table(
            tb_data1;
            header = ["Num", "Const.", "Values"],
            header_style = "bold white",
            columns_style = ["dim", "bold", "red"],
        )
        Table(tb_data1; footer = sum, footer_justify = :center, footer_style = "dim bold")


        # prompts
        Prompt("basic prompt?", "red") |> println
        TypePrompt(Int, "Gimme a number", "bold red") |> println
        OptionsPrompt(["one", "two"], "What option?", "red", "green") |> println
        DefaultPrompt(["yes", "no"], 1, "asking", "red", "green", "blue") |> println

    end
    close(outRead)
    redirect_stdout(originalSTDOUT)
end