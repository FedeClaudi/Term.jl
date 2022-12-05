using Suppressor: @capture_out
using Term
using Term.LiveDisplays
using Term.Consoles
using Term.Progress

clear()
inspect(Panel)

# pbar = ProgressBar(; transient = false)
# job = addjob!(pbar; N = 100)
# start!(pbar)
# for i in 1:100
#     Progress.update!(job)
#     i % 25 == 0 && println("We can print from here too")
#     LiveDisplays.refresh!(pbar) || break
# end
# Progress.stop!(pbar)

# # TODO deal with stdout
