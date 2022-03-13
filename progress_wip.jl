using Revise

Revise.revise()

using Term
import Term.consoles: clear

N = 250
# pbar = ProgressBar(;
#         N=N,
#         fill=true,
#         width=200,
#         transient=false,
#         description="Made with [bold blue underline]Term[/bold blue underline]"
#     )

# clear()
println("."^150)
for i in track(1:N; expand=false, description="test", width=150)
    sleep(.01)
end

