import Term.Compositors:
    Compositor, update!, collect_elements, clean_layout_expr, parse_single_element_layout
import Term: Panel, Renderable

@testset "Compositor - expression" begin
    expr_1 = :(A(4, 12) * B(4, 12) / C(4, 12))
    expr_2 = :(hstack(A(4, 12), B(4, 12), C(4, 12)))
    expr_3 = :(vstack(A(4, 12), B(4, 12), C(4, 12); pad = 2))
    expr_4 = :(A(4, 12))

    @test parse_single_element_layout(expr_1) isa Vector{Expr}

    @test collect_elements(expr_2) == collect_elements(expr_1)
    @test collect_elements(expr_3) == collect_elements(expr_1)
    @test collect_elements(expr_4) == :(A(4, 12))

    @test clean_layout_expr(expr_1) == :((A * B) / C)
    @test clean_layout_expr(expr_2) == :(hstack(A, B, C))
    @test clean_layout_expr(expr_3) == :(vstack(pad = 2, A, B, C))
end

@testset "Compositor - creation" begin
    expr_1 = :(A(14, 12) * B(14, 12) / C(14, 12))

    C1 = Compositor(expr_1)
    C1_b = Compositor(expr_1; B = Panel(height = 14, width = 12))
    C2 = Compositor(:(hstack(A(14, 12), B(14, 12), C(14, 12))))

    C3 = Compositor(:(vstack(A(14, 20), B(14, 12), C(14, 12); pad = 2)))

    update!(C3, :B, Panel(height = 14, width = 12))
    update!(C3, :A, Panel(height = 14, width = 20))
    update!(C3, :A, Panel(height = 14, width = 20))

    C4 = Compositor(:(vstack(A(5, 10), B(20, 15))))
    update!(C4; A = Panel(height = 5, width = 10), B = Panel(height = 20, width = 15))
    @test_logs (:warn, r"Could not update compositor") update!(C4, :FOO, Panel())

    C5 = Compositor(:(A(100, 55) * B(20, 15)))
    # @test_logs (:warn, r"Shape mismatch while updating compositor element") update!(
    #     C5,
    #     :A,
    #     Panel(; width=20),
    # )

    compositors = [C1, C1_b, C2, C3]

    if !Sys.iswindows()
        for (i, t) in enumerate(compositors)
            IS_WIN || @compare_to_string(cleanstring(t), "compositor_$i")

            # coverage
            @test Renderable(t) isa RenderableText
            print(devnull, t)
            show(devnull, MIME("text/plain"), t)
            show(devnull, t)
        end
    end
end
