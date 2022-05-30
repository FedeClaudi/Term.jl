import Term.Style: apply_style

@testset "\e[34mMACROS" begin
    @test (@green "string") == apply_style("{green}string{/green}")
    @test (@blue "string") == apply_style("{blue}string{/blue}")
    @test (@red "string") == apply_style("{red}string{/red}")

    @test (@bold "string") == apply_style("{bold}string{/bold}")
    @test (@italic "string") == apply_style("{italic}string{/italic}")
    @test (@underline "string") == apply_style("{underline}string{/underline}")

    @test (@style "string" bold underline) ==
          apply_style("{bold underline}string{/bold underline}")
    @test (@style "string" bold greeen) == apply_style("{bold greeen}string{/bold greeen}")
    @test (@style "string" red on_blue underline) ==
          apply_style("{red on_blue underline}string{/red on_blue underline}")
    @test (@style "string" bold italic) == apply_style("{bold italic}string{/bold italic}")

    # test with interpolations
    x = "test"
    @test (@red "aa $x aa") == "\e[31maa test aa\e[39m"
    @test (@bold "aa $x aa") == "\e[1maa test aa\e[22m"
    @test (@style "aa $x aa" green bold) == "\e[1m\e[32maa test aa\e[22m\e[39m"
end
