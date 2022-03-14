@testset "\e[34mProgress" begin
    import Term.progress: track, ProgressBar, update, track, start, stop


    @test_nothrow begin
        for i in track(1:10)
            sleep(0.001)
        end
    end

    @test_nothrow begin
        vec = collect(1:10)
        for i in track(vec; description="[red]")
            sleep(0.001)
        end
    end

    for level in (:minimal, :default, :extensive)
        @test_nothrow begin
            for i in track(1:10; columns=level)
                sleep(0.001)
            end
        end
    end

    for redirect in (true, false)
        @test_nothrow begin
            for i in track(1:10; redirectstdout=redirect)
                sleep(0.001)
                print("test")
            end
        end
    end

    import Term.progress: DescriptionColumn, BarColumn, PercentageColumn
    cols = [DescriptionColumn("test"), BarColumn(), PercentageColumn()]
    @test_nothrow begin
        for i in track(1:10; columns=cols)
            sleep(0.001)
            print("test")
        end
    end

end