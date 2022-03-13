using Revise

Revise.revise()

using Term
import Term.consoles: clear

N = 250
pbar = ProgressBar(;
        N=N,
        fill=true,
        width=200,
        transient=false,
        description="Made with [bold blue underline]Term[/bold blue underline]"
    )

clear()

for i in 1:N
    update(pbar)
    sleep(.01)
end

