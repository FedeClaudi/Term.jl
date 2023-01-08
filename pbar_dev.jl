using Term
using Term.LiveWidgets
using Term.Consoles
using Term.Progress

# clear()

pbar = ProgressBar(; transient = false)
job = addjob!(pbar; N = 100)
start!(pbar)
for i in 1:100
    Progress.update!(job)
    # i % 25 == 0 && println("We can print from here too")
    LiveWidgets.refresh!(pbar)
    sleep(0.01)
end
Progress.stop!(pbar)

# # TODO deal with stdout
