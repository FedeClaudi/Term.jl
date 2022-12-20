
# ---------------------------------------------------------------------------- #
#                                PRECOMPILATION                                #
# ---------------------------------------------------------------------------- #
#  originalSTDOUT = stdout
#  (outRead, outWrite) = redirect_stdout()

using SnoopPrecompile
SnoopPrecompile.verbose[] = false

@precompile_setup begin
    txt = "aa asdasdaasads da qw d"^30

    @precompile_all_calls begin
        reshape_text(txt, 10)
        # Panel(txt) |> string;
        # print(Panel(txt))
        # for fit in (true, false)
        #     Panel(txt; fit=fit);
        #     Panel(txt; padding=(2, 2, 2, 2),
        #         background="red", height=10,
        #         fit=fit
        #     );
        #     Panel()
        #     Panel(Panel(txt; fit=fit);)
        # end

        # replace_multi(txt, "a"=>"B", "d"=>"C")

        # with_ansi = apply_style(txt)
        # remove_ansi(with_ansi)
        # remove_markup(txt)
        # remove_markup(txt; remove_orphan_tags = false)

        # reshape_text(txt, 43);
        # text_to_width(txt, 43, :left)

        # r = RenderableText(txt; width=30, style="red");
        # p = Panel(txt);
        # r * p;
        # r / p;
    end
end

# close(outRead)
# redirect_stdout(originalSTDOUT)
