using Revise

Revise.revise()

using Term
import Term.consoles: clear


"""
# TODO
Stdout doesn't get preserved, only the first line does.
"""

# clear()
# print("\n\n\n")



N = 100


for i in track(1:N; expand=false, description="test", width=150)
    sleep(.01)
    if i % 50 == 0
        println("cacca")
    end
end

