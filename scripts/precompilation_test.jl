print("\n\n\n\n")

using Term

txt = join(
    repeat(["this is a random {red}text{/red} to test {bold}precompilation"], 10),
    "\n",
)

runnable = quote
    originalSTDOUT = stdout
    (outRead, outWrite) = redirect_stdout()

    Panel(txt; fit = false, width = 25) |> tprint
    close(outRead)
    redirect_stdout(originalSTDOUT)
end

println("\n\nFIRST RUN")
tstart = time();
eval(runnable);
tend = time();
tend - tstart |> println

println("\nSECOND RUN")
tstart = time();
eval(runnable);
tend = time();
tend - tstart |> println
