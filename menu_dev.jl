using Suppressor: @capture_out
using Term
using Term.LiveDisplays
using Term.Consoles

# clear()
# tv = TabViewer(
#     [
#         TextTab("one", join(rand("\nasdasd\n \n asd ", 25))),
#         TextTab("two", join(rand("\nasdasd\n \n asd ", 25))),
#         PagerTab("three", join(rand("\nasdasd\n \n asd ", 1000))),
#         PagerTab("four", join(rand("\nasdasd\n \n asd ", 1000))),
#     ]
# )


# while true
#     LiveDisplays.update!(tv) || break
# end
# stop!(tv)
# println("done")

inspect(Panel)