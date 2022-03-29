using Term.progress
import Term.progress: render



# TODO get access to variables in func scope
# TODO add try finally to avoid accidents

function test()
    x = 0
    @time begin
        @track for i in 1:100
            # x += i
            # sleep(0.1)
            # sleep(0.0001)
        end
    end
    println(x)
end

test()


