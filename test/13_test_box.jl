using Term.box

@testset "\e34mBOX" begin
    testbox = Term.box.Box(
        "ASCII",
        """
        +--+
        | ||
        |-+|
        | ||
        |-+|
        |-+|
        | ||
        +--+
        """,
    )

    @test string(testbox) == "Box\e[2m(ASCII)\e[0m"

    @suppress_out begin
        @test_nowarn println(stdout, testbox)
    end
   
    _bstring = Term.box.fit(Term.box.ASCII, [1, 1, 1, 1, 1, 1, 1, 1])
    @test _bstring == "+---------------+\n| | | | | | | | |\n|-+-+-+-+-+-+-+-|\n| | | | | | | | |\n|-+-+-+-+-+-+-+-|\n|-+-+-+-+-+-+-+-|\n| | | | | | | | |\n+---------------+"
end