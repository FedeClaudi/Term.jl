
 # ---------------------------------------------------------------------------- #
 #                                PRECOMPILATION                                #
 # ---------------------------------------------------------------------------- #

 using SnoopPrecompile
#  SnoopPrecompile.verbose[] = false

txt = "aa bb casc"^10
styled = "aa {red} bb {green} asad {/green} sada {/red} asdasda"
 @precompile_setup begin
    @precompile_all_calls begin
        replace_multi(styled, "a"=>"B", "d"=>"C")

        with_ansi = apply_style(styled)
        remove_ansi(with_ansi)
        remove_markup(styled)
        remove_markup(styled; remove_orphan_tags = false)
        
        reshape_text(txt, 43);
        text_to_width(txt, 43, :left)

        r = RenderableText(txt; width=30, style="red");
        p = Panel(txt);
        r * p;
        r / p;
    end
end
