import Term: install_term_logger, uninstall_term_logger, TermLogger
using Term.Logs: handle_progress
using Term.Progress

import ProgressLogging
import UUIDs: uuid4

@testset "\e[34mLOGS test" begin
    install_term_logger()
    println("\nTesting logging, stdout temporarily disabled")

    @suppress_out begin
        @info "my log!"

        @warn "tell us if this was [bold red]undexpected![/bold red]"

        x = collect(1:2:20)
        y = x * x'
        name = "the name is [bold blue]Term[/bold blue]"
        p1 = Panel("text")

        @error "[italic green bold]fancy logs![/italic green bold]" x y name √9 install_term_logger p1

        @info """asdada asdasd\nasdada;
        asdadaada
        asdadaxc

        sdfs
        s""" 1 + 2
    end
    uninstall_term_logger()
end

@testset "\e[34mLOGS handle_progress" begin
    logger = TermLogger(devnull, TERM_THEME[])
    for fraction in (nothing, 0.0, 0.5, 1.0)
        handle_progress(logger, ProgressLogging.Progress(id = uuid4(), fraction = fraction))
    end

    @test true
end
