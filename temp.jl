import Term.progress: ProgressBar, update


pbar = ProgressBar(; N=100, redirectstdout=false)

for i in 1:100
    update(pbar)
    i % 25 == 0 && break
end