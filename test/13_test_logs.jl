import Term: install_term_logger, uninstall_term_logger, TermLogger
using Term.Logs: handle_progress
using Term.Progress

import ProgressLogging
import UUIDs: uuid4

struct MyLogsStruct
    x::String
    y::Vector
    z::Int
end

@testset "\e[34mLOGS test" begin
    install_term_logger()
    println("\nTesting logging, stdout temporarily disabled")

    output = @capture_out begin
        @info "my log!"

        @warn "tell us if this was {bold red}undexpected!{/bold red}"

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

        @info MyStruct("aa a"^100, zeros(200), 4)

        @info "A" zeros(100, 100) zeros(10) zeros(100, 100, 100)
        @info "B" (1, 2)
        @info "C" Panel()
        @info "D" Dict{Symbol,Number}(Symbol(x) => x for x in 1:100)
    end

    # IS_WIN || @compare_to_string output "logs.txt"

    uninstall_term_logger()
end

# @testset "\e[34mLOGS handle_progress" begin
#     logger = TermLogger(devnull, TERM_THEME[])
#     for fraction in (nothing, 0.0, 0.5, 1.0)
#         handle_progress(logger, ProgressLogging.Progress(id = uuid4(), fraction = fraction))
#     end

#     @test true
# end
