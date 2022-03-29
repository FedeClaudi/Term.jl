using Term
import Term: chars
import Term.console: clear
install_term_logger()

clear()

pprint(pan) = begin
    print(" " * hLine(pan.measure.w; style="red"))
    print(vLine(pan.measure.h; style="red") * pan)
    println(pan.measure, "  ", length(pan.segments) )
    # print(pan)
end

# TODO test panels layout

# ---------------------------------------------------------------------------- #
#                                  no content                                  #
# ---------------------------------------------------------------------------- #
# ---------------------------------- fitted ---------------------------------- #
pprint(
    Panel(;fit=true)
)

# # --------------------------------- unfitted --------------------------------- #
# pprint(
#     Panel()
# )

# pprint(
#     Panel(; width=12, height=4)
# )




# ---------------------------------------------------------------------------- #
#                                   text only                                  #
# ---------------------------------------------------------------------------- #
# ---------------------------------- fitted ---------------------------------- #
# pprint(
#     Panel("t"; fit=true)
# )

# pprint(
#     Panel("test"; fit=true)
# )

# pprint(
#     Panel("1234\n123456789012"; fit=true)
# )

# pprint(
#     Panel("나랏말싸미 듕귁에 달아"; fit=true)
# )

# pprint(
#     Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012"; fit=true)
# )

# pprint(
#     Panel("."^500; fit=true)
# )

# --------------------------------- unfitted --------------------------------- #
# pprint(
#     Panel("t")
# )

# pprint(
#     Panel("test")
# )

# pprint(
#     Panel("1234\n123456789012")
# )

# pprint(
#     Panel("나랏말싸미 듕귁에 달아\n1234567890123456789012")
# )

# pprint(
#     Panel("."^500)
# )


# ---------------------------------------------------------------------------- #
#                                 nested panels                                #
# ---------------------------------------------------------------------------- #
# ---------------------------------- fitted ---------------------------------- #
# pprint(
#     Panel(
#         Panel("test"; fit=true);
#     fit=true)
# )


# pprint(
#     Panel(
#         Panel(Panel("."; fit=true); fit=true);
#     fit=true)
# )

# pprint(
#     Panel(
#         Panel("."^500; fit=true); fit=true
#     )
# )

# --------------------------------- unfitted --------------------------------- #
# pprint(
#     Panel(
#         Panel("test");
#     fit=true)
# )


# pprint(
#     Panel(
#         Panel(Panel("."); fit=true);
#     fit=true)
# )

# pprint(
#     Panel(
#         Panel("."^250); fit=true
#     )
# )

# pprint(
#     Panel(
#         Panel("test");
# )
# )


# pprint(
#     Panel(
#         Panel(Panel("."););
# )
# )

# pprint(
#     Panel(
#         Panel("."^250);
#     )
# )

# pprint(
#     Panel(
#         Panel("t1"),
#         Panel("t2"),
#     )
# )

# pprint(
#     Panel(
#         Panel("test", width=22);  width=30, height=8
#     )
# )

# pprint(
#     Panel(
#         Panel("test", width=42);  width=30, height=8
#     )
# )


# pprint(
#     Panel(
#         Panel("test", width=42,height=12);  width=30, height=8
#     )
# )


# pprint(
#     Panel(
#         Panel("test", width=42,height=12);  width=30, height=14
#     )
# )

# -------------------------- with other renderables -------------------------- #
# pprint(
#     Panel(
#         RenderableText("x".^5)
#     )
# )


# pprint(
#     Panel(
#         RenderableText("x".^500)
#     )
# )

# pprint(
#     Panel(
#         RenderableText("x".^5); fit=true
#     )
# )


# pprint(
#     Panel(
#         RenderableText("x".^500); fit=true
#     )
# )



# ---------------------------------------------------------------------------- #
#                                    titles                                    #
# ---------------------------------------------------------------------------- #

# pprint(
#     Panel(
#         Panel("[red].[/red]"^50, title="test", subtitle="subtest")
#     )
# )

# pprint(
#     Panel("."^50, title="test",
#                             subtitle="subtest",
#                             subtitle_style="red",
#                             fit=false
#                             )
# )


# ---------------------------------------------------------------------------- #
#                                    PADDING                                   #
# ---------------------------------------------------------------------------- #

# pprint(
#     Panel("."^24; padding = [4, 4, 2, 2])
# )


# pprint(
#     Panel("."^24; padding = [4, 4, 2, 2], fit=true)
# )


# pprint(
#     Panel("."^24; padding = [0, 0, 0, 0], fit=true)
# )