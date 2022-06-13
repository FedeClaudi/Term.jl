import Term.Compositors:
    Compositor, update!, collect_elements, clean_layout_expr, parse_single_element_layout
import Term: Panel

expr_1 = :(A(12, 4) * B(12, 4) / C(12, 4))
expr_2 = :(hstack(A(12, 4), B(12, 4), C(12, 4)))
expr_3 = :(vstack(A(12, 4), B(12, 4), C(12, 4); pad = 2))
expr_4 = :(A(12, 4))

@testset "Compositor - expression" begin
    @test parse_single_element_layout(expr_1) isa Vector{Expr}

    @test collect_elements(expr_2) == collect_elements(expr_1)
    @test collect_elements(expr_3) == collect_elements(expr_1)
    @test collect_elements(expr_4) == :(A(12, 4))

    @test clean_layout_expr(expr_1) == :((A * B) / C)
    @test clean_layout_expr(expr_2) == :(hstack(A, B, C))
    @test clean_layout_expr(expr_3) == :(vstack(pad = 2, A, B, C))
end

expr_1 = :(A(12, 14) * B(12, 14) / C(12, 14))
expr_2 = :(hstack(A(12, 14), B(12, 14), C(12, 14)))
expr_3 = :(vstack(A(12, 14), B(12, 14), C(12, 14); pad = 2))

C1 = Compositor(expr_1)
C1_b = Compositor(expr_1; B = Panel(width = 12, height = 14))
C2 = Compositor(expr_2)
C3 = Compositor(expr_3)
update!(C3, :B, Panel(width = 12, height = 14))
update!(C3, :A, Panel(width = 20, height = 14))
compositors = [C1, C1_b, C2, C3]

# for (i, t) in enumerate(compositors)
#     tofile(string(t), "./txtfiles/compositor_$i.txt")
# end

@testset "Compositor - creation" begin
    if !Sys.iswindows()
        for (i, t) in enumerate(compositors)
            @test fromfile("./txtfiles/compositor_$i.txt") == cleanstring(t)

            # coverage
            @test Renderable(t) isa RenderableText
            show(devnull, t)
            print(devnull, t)
        end
    end
end
