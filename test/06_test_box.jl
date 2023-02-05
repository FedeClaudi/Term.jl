using Term.Boxes
import Term: Segment

@testset "\e[34mBOX" begin
    testbox = Term.Boxes.Box(
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
        @test_nothrow println(stdout, testbox)
    end

    _bstring = Term.Boxes.fit(Term.Boxes.BOXES[:ASCII], [1, 1, 1, 1, 1, 1, 1, 1])
    @test _bstring ==
          "+---------------+\n| | | | | | | | |\n|-+-+-+-+-+-+-+-|\n| | | | | | | | |\n|-+-+-+-+-+-+-+-|\n|-+-+-+-+-+-+-+-|\n| | | | | | | | |\n+---------------+"

    # test get row
    @test get_row(Term.Boxes.BOXES[:ROUNDED], [3], :top) == "╭───╮"
    @test get_row(Term.Boxes.BOXES[:ROUNDED], 3, :top) == "╭─╮"
    @test get_row(Term.Boxes.BOXES[:ROUNDED], [3, 5], :top) == "╭───┬─────╮"

    # test get title row with no justification
    tr = get_title_row(:top, Term.Boxes.BOXES[:ROUNDED], nothing; width = 22, style = "red")
    @test tr isa Segment
    @test tr.measure.w == 22

    # test title row with justification
    left = get_title_row(
        :top,
        Term.Boxes.BOXES[:ROUNDED],
        "test";
        width = 22,
        justify = :left,
        title_style = "blue",
        style = "red",
    )
    @test left.measure.w == 22
    @test left.text ==
          "\e[31m╭──── \e[34mtest\e[39m\e[31m\e[31m ──────────╮\e[39m\e[0m\e[39m"

    right = get_title_row(
        :top,
        Term.Boxes.BOXES[:ROUNDED],
        "test";
        width = 22,
        justify = :right,
        title_style = "blue",
        style = "red",
    )
    @test right.measure.w == 22
    @test right.text ==
          "\e[31m╭─────────── \e[34mtest\e[39m\e[31m\e[31m ───╮\e[39m\e[0m\e[39m"

    center = get_title_row(
        :top,
        Term.Boxes.BOXES[:ROUNDED],
        "test";
        width = 22,
        justify = :center,
        title_style = "blue",
        style = "red",
    )
    @test center.measure.w == 22
    @test center.text ==
          "\e[31m╭─────── \e[34mtest\e[39m\e[31m\e[31m ───────╮\e[39m\e[0m\e[39m"

    for width in (15, 21, 33, 58), justify in (:left, :center, :right)
        line = get_title_row(
            :top,
            Term.Boxes.BOXES[:DOUBLE],
            "test";
            width = width,
            justify = justify,
            title_style = "on_green",
            style = "blue bold",
        )

        @test line.measure.w == width
    end
end
