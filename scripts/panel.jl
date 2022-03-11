using Term
import Term: chars
install_term_logger()


pprint(pan) = begin
    print(pan)
    println(pan.measure, "   ", length(chars(pan.segments[1].plain)) )
end

# TODO with size info for nested panels
# TODO test with title and subtitles
# TODO test panels layout
# TODO test with other Renderables and TB as content

# ---------------------------------------------------------------------------- #
#                                  no content                                  #
# ---------------------------------------------------------------------------- #
# ---------------------------------- fitted ---------------------------------- #
# pprint(
#     Panel(;fit=true)
# )

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
#         Panel("."^2050); fit=true
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