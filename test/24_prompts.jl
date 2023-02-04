using Term.Prompts
import Term.Prompts: validate_answer, AnswerValidationError

@testset "Prompt, Creation" begin
    basic = Prompt("basic prompt?")
    basic_with_color = Prompt("basic prompt?", "red")

    type_prompt = TypePrompt(Int, "Gimme a number")
    type_prompt_style = TypePrompt(Int, "Gimme a number", "bold red")

    opts = OptionsPrompt(["one", "two"], "What option?")
    opts_style = OptionsPrompt(["one", "two"], "What option?", "red", "green")

    default = DefaultPrompt(["yes", "no"], 1, "asking", "red", "green", "blue")
    default = DefaultPrompt(["yes", "no"], 1, "asking")
end

basic = Prompt("basic prompt?")
basic_with_color = Prompt("basic prompt?", "red")

type_prompt = TypePrompt(Int, "Gimme a number")
type_prompt_style = TypePrompt(Int, "Gimme a number", "bold red")

opts = OptionsPrompt(["one", "two"], "What option?")
opts_style = OptionsPrompt(["one", "two"], "What option?", "red", "green")

default = DefaultPrompt(["yes", "no"], 1, "asking", "red", "green", "blue")

all_prompts =
    (basic, basic_with_color, type_prompt, type_prompt_style, opts, opts_style, default)

IS_WIN || @testset "Prompt, printing" begin
    for (i, p) in enumerate(all_prompts)
        @compare_to_string(sprint(print, p), "prompt_print_$i")
        @compare_to_string(sprint(println, p), "prompt_print_$(i)_ln")
        @compare_to_string(sprint(tprintln, p), "prompt_print_$(i)_t")
        @compare_to_string(sprint(tprintln, p), "prompt_print_$(i)_tln")
    end
end

@testset "Prompt, validation" begin
    @test validate_answer("test", basic) == "test"

    @test_throws AnswerValidationError validate_answer("sdadas", type_prompt)
    @test validate_answer("1", type_prompt) == 1

    @test isnothing(validate_answer("asdada", opts))
    @test validate_answer("one", opts) == "one"

    @test validate_answer("", default) == "yes"
end
