import Term: install_term_logger, uninstall_term_logger

install_term_logger()

@testset "\e[34mLOGS test" begin
    println("\nTesting logging, stdout temporarily disabled")

    @suppress_out begin
        @test_nothrow @info "my log!"

        @test_nothrow @warn "tell us if this was [bold red]undexpected![/bold red]"

        x = collect(1:2:20)
        y = x * x'
        name = "the name is [bold blue]Term[/bold blue]"
        p1 = Panel("text")

        @test_nothrow @error "[italic green bold]fancy logs![/italic green bold]" x y name √9 install_term_logger p1

        @test_nothrow @info """asdada asdasd\nasdada;
        asdadaada
        asdadaxc

        sdfs
        s""" 1 + 2

        # uninstall_term_logger()
        # @info "removed"

    end
end
