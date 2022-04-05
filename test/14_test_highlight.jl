import Term: load_code_and_highlight, highlight_syntax, highlight, theme


@testset "\e[34mHIGHLIGHT" begin

    # @test highlight("test 1 123 33.4 44,5 +1 -2 12 0.5, ,, ...") == "test[#90CAF9][#90CAF9] 1 [/#90CAF9][/#90CAF9][#90CAF9]123[/#90CAF9] [#90CAF9]33.4[/#90CAF9] [#90CAF9]44,5[/#90CAF9] [#90CAF9]+1 [/#90CAF9][#90CAF9]-2 [/#90CAF9][#90CAF9]12[/#90CAF9] [#90CAF9]0.5[/#90CAF9][#90CAF9], [/#90CAF9],[#90CAF9], [/#90CAF9]..."

    @test highlight("this is ::Int64") == "this is [#CE93D8]::Int64[/#CE93D8]"

    @test highlight("print", :func) == "[#FFEE58]print[/#FFEE58]"

    @test highlight("1 + 2", :code) == "[#90CAF9]1 + 2[/#90CAF9]"

    @test highlight("this 1 + `test`") == "this 1 + [#90CAF9]`test`[/#90CAF9]"

    @test highlight(1) == "[#42A5F5]1[/#42A5F5]"

    @test highlight([1, 2, 3]) == "[#42A5F5][1, 2, 3][/#42A5F5]"

    @test highlight(Int) == "[#CE93D8]Int64[/#CE93D8]"

    @test highlight(print) == "[#FFEE58]print[/#FFEE58]"


    @test highlight_syntax("""
    This is ::Int64 my style
    """) == "This is \e[1m\e[38;2;252;98;98m::\e[22m\e[39mInt64 my style\n"

    @test highlight_syntax("""
    This is ::Int64 my style
    print(x + 2)
    """) == "This is \e[1m\e[38;2;252;98;98m::\e[22m\e[39mInt64 my style\n\e[1m\e[38;2;255;245;157mprint\e[22m\e[39m\e[38;2;252;116;116m(\e[39mx \e[1m\e[38;2;252;98;98m+\e[22m\e[39m \e[38;2;144;202;249m2\e[39m\e[38;2;252;116;116m)\e[39m\n"

    @test load_code_and_highlight("14_test_highlight.jl", 7) == "[red bold]❯[/red bold] [white]7[/white] \n  [grey39]8[/grey39]  @test [(255, 245, 157)  bold  ]highlight[/(255, 245, 157)  bold  ][(252, 116, 116)    ]([/(252, 116, 116)    ][(165, 214, 167)    ]\"this is ::Int64\"[/(165, 214, 167)    ][(252, 116, 116)    ])[/(252, 116, 116)    ] [(252, 98, 98)  bold  ]==[/(252, 98, 98)  bold  ] [(165, 214, 167)    ]\"this is [[#CE93D8]]::Int64[[/#CE93D8]]\"[/(165, 214, 167)    ]\n  [grey39]9[/grey39] \n  [grey39]10[/grey39]  @test [(255, 245, 157)  bold  ]highlight[/(255, 245, 157)  bold  ][(252, 116, 116)    ]([/(252, 116, 116)    ][(165, 214, 167)    ]\"print\"[/(165, 214, 167)    ][(252, 116, 116)    ],[/(252, 116, 116)    ] [(165, 214, 167)    ]:func[/(165, 214, 167)    ][(252, 116, 116)    ])[/(252, 116, 116)    ] [(252, 98, 98)  bold  ]==[/(252, 98, 98)  bold  ] [(165, 214, 167)    ]\"[[#FFEE58]]print[[/#FFEE58]]\"[/(165, 214, 167)    ]\n  [grey39]11[/grey39] \n  [grey39]12[/grey39]  @test [(255, 245, 157)  bold  ]highlight[/(255, 245, 157)  bold  ][(252, 116, 116)    ]([/(252, 116, 116)    ][(165, 214, 167)    ]\"1 + 2\"[/(165, 214, 167)    ][(252, 116, 116)    ],[/(252, 116, 116)    ] [(165, 214, 167)    ]:code[/(165, 214, 167)    ][(252, 116, 116)    ])[/(252, 116, 116)    ] [(252, 98, 98)  bold  ]==[/(252, 98, 98)  bold  ] [(165, 214, 167)    ]\"[[#90CAF9]]1 + 2[[/#90CAF9]]\"[/(165, 214, 167)    ]\n  [grey39]13[/grey39] "


end

