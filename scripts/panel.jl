using Term
import Term.Consoles: clear
import Term: chars
install_term_logger()

clear()

pprint(pan) = begin
    print(" " * hLine(pan.measure.w; style = "red"))
    print(vLine(pan.measure.h; style = "red") * pan)
    println(pan.measure, "  ", length(pan.segments))
    # print(pan)
end

# ---------------------------------------------------------------------------- #
#                                  no content                                  #
# ---------------------------------------------------------------------------- #
# ---------------------------------- fitted ---------------------------------- #
@time pprint(Panel(fit = true))

# # --------------------------------- unfitted --------------------------------- #
@time pprint(Panel())

@time pprint(Panel(width = 12, height = 4))

# ---------------------------------------------------------------------------- #
#                                   text only                                  #
# ---------------------------------------------------------------------------- #
# ---------------------------------- fitted ---------------------------------- #
@time pprint(Panel("t"; fit = true))

@time pprint(Panel("test"; fit = true))

@time pprint(Panel("1234\n123456789012"; fit = true))

@time pprint(Panel("나랏말싸미 듕귁에 달아"; fit = true))

@time pprint(Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; fit = true))

@time pprint(Panel("."^500; fit = true))

# --------------------------------- unfitted --------------------------------- #
@time pprint(Panel("t"))

@time pprint(Panel("test"))

@time pprint(Panel("1234\n123456789012"))

@time pprint(Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"))

@time pprint(Panel("."^500))

# ---------------------------------------------------------------------------- #
#                                 nested panels                                #
# ---------------------------------------------------------------------------- #
# ---------------------------------- fitted ---------------------------------- #
@time pprint(Panel(Panel("test"; fit = true); fit = true))

@time pprint(Panel(Panel(Panel("."; fit = true); fit = true); fit = true))

@time pprint(Panel(Panel("."^500; fit = true); fit = true))

# --------------------------------- unfitted --------------------------------- #
@time pprint(Panel(Panel("test"); fit = true))

@time pprint(Panel(Panel(Panel("."); fit = true); fit = true))

@time pprint(Panel(Panel("."^250); fit = true))

@time pprint(Panel(Panel("test");))

@time pprint(Panel(Panel(Panel("."););))

@time pprint(Panel(Panel("."^250);))

@time pprint(Panel(Panel("t1"), Panel("t2")))

@time pprint(Panel(Panel("test"; width = 22); width = 30, height = 8))

@time pprint(Panel(Panel("test"; width = 42); width = 30, height = 8))

@time pprint(Panel(Panel("test"; width = 42, height = 12); width = 30, height = 8))

@time pprint(Panel(Panel("test"; width = 42, height = 12); width = 30, height = 14))

# -------------------------- with other renderables -------------------------- #
@time pprint(Panel(RenderableText("x" .^ 5)))

@time pprint(Panel(RenderableText("x" .^ 500)))

@time pprint(Panel(RenderableText("x" .^ 5); fit = true))

@time pprint(Panel(RenderableText("x" .^ 500); fit = true))

# ---------------------------------------------------------------------------- #
#                                    titles                                    #
# ---------------------------------------------------------------------------- #

@time pprint(Panel(Panel("[red].[/red]"^50; title = "test", subtitle = "subtest")))

@time pprint(
    Panel(
        "."^50;
        title = "test",
        subtitle = "subtest",
        subtitle_style = "red",
        fit = false,
    ),
)

# ---------------------------------------------------------------------------- #
#                                    PADDING                                   #
# ---------------------------------------------------------------------------- #

@time pprint(Panel("."^24; padding = (4, 4, 2, 2)))

@time pprint(Panel("."^24; padding = (4, 4, 2, 2), fit = true))

@time pprint(Panel("."^24; padding = (0, 0, 0, 0), fit = true))
