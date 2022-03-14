using Revise

Revise.revise()

using Term
import Term.consoles: clear, line, up
using Term.progress

clear()
# for i in 1:20
#     up()
# end

print(hLine("starting"))
line()

"""
# TODO
Stdout doesn't get preserved, only the first line does.
"""

# clear()
# print("\n\n\n")



N = 100

# ---------------------------------- manual ---------------------------------- #
# pbar = ProgressBar(;N=N, columns=:default, update_every=5)

# for i in 1:N
#     sleep(.01)
#     update(pbar)

    
#     i == 1 && println("printed during loop, or is it?")


# end
# stop(pbar)
# print("done")


# ----------------------------------- track ---------------------------------- #
trk(x) = track(x; 
        expand=false,
        description="Task [bold red]66[/bold red]",
        width=150,
        transient=false,
        columns=:extensive,
    redirectstdout=false)
for i in trk(1:50)
    sleep(.25)
    # if i % 50 == 0
    #     # println("meanwhile")
    #     print(Panel("meanwile"; fit=true, style="red"))
    # end
end


# --------------------------------- transient -------------------------------- #
# for j in 1:5
#     for i in track(1:N; expand=false, description="Task [bold red]$j[/bold red]", width=150, transient=true)
#         sleep(.01)
#         # if i % 50 == 0
#         #     println("cacca")
#         # end
#     end
# end
line()
print(hLine("done"; style="red"))