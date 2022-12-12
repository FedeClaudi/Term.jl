using Term
import Term.Style: apply_style
import Term: highlight

"""
Prompts in VSCODE require a bit of a hack:
https://discourse.julialang.org/t/vscode-errors-with-user-input-readline/75097/4?u=fedeclaudi
"""


# ------------------------------ abstract prompt ----------------------------- #

""" Prompt types """
abstract type AbstractPrompt end

""" display an `AbstractPrompt`, get user's reply and validate. """
function ask(io::IO, prompt::AbstractPrompt)
    println(io, prompt)
    ans = readline()
    return validate_answer(ans, prompt)
end

ask(prompt) = ask(stdout, prompt)

"""
    validate_answer

Validate user's answer for a prompt type.
The validation mechanism depends on the type of prompt.
Validate answer will return the answer if it passed validation
or raise and error otherwise.
"""
function validate_answer end


# -------------------------------- type prompt ------------------------------- #
"""
    struct TypePrompt{T}
        answer_type::Union{Union, DataType} = T
        prompt::String
    end

Asks for input given `prompt` and checks/converts the answer to type `T`
"""
struct TypePrompt{T} <: AbstractPrompt
    answer_type::T
    prompt::String
end

function Base.println(io::IO, prompt::TypePrompt)
    println(io, prompt.prompt)
end

struct AnswerValidationError <: Exception
    answer_type
    expected_type
end

Term.Errors.error_message(e::AnswerValidationError) = highlight("TypePrompt expected an answer of type: `$(e.expected_type)`, got `$(e.answer_type)` instead") |> apply_style


function validate_answer(answer, prompt::TypePrompt)
    answer isa prompt.answer_type && return answer
    try
        return parse(prompt.answer_type, answer)
    catch err
        throw(AnswerValidationError(typeof(answer), prompt.answer_type))
    end
end



# ---------------------------------------------------------------------------- #
#                                OPTIONS PROMPTS                               #
# ---------------------------------------------------------------------------- #
""" Prompt types where user can only choose among options """
abstract type OptionsPrompt <: AbstractPrompt end

""" Options types with a default answer """
abstract type AbstractDefaultPrompt <: OptionsPrompt end


struct DefaultPropt
    answers::Vector
    default::Int # index of default answer
    prompt::String

    function DefaultPropt(answers::Vector, default::Int, prompt::String)
        @assert default > 0 && default < length(answers)  "Default answer number: $default not valid"
        new(answers, default, prompt)
    end
end

function Base.println(io::IO, prompt::DefaultPropt)
    txt = prompt.prompt * " "
    answer_styles = map(
        i -> i == prompt.default ? "green bold" : "default",
        1:length(prompt.answers)
    )
    # answers = join(
    #     apply_style.(
    #         map(
    #             i -> "{$(answer_styles[i])}$(prompt.answers[1]){/$(answer_styles[i])}"
    #         )
    #     ), ", "
    # )
    # # println(io, txt * answers)
end

function validate_answer(answer, prompt::DefaultPropt)
    answer == "" && return prompt.answers[prompt.default]
    answer ∉ prompt.answers && begin
        println("Answer `$(answer)` is not a valid option.")
        return nothing
    end
    return answer

end


function ask(io::IO, prompt::DefaultPropt)
    println(io, prompt)
    ans = nothing
    while isnothing(ans)
        println(io, prompt)
        ans = validate_answer(readline(), prompt)
    end
    return ans
end


confirm() = ask(DefaultPropt(["Yes", "No"], 1, "Confirm?"))


# ---------------------------------------------------------------------------- #
#                                      DEV                                     #
# ---------------------------------------------------------------------------- #
# ask(TypePrompt(Int, "give me a number"))
confirm()


# TODO add style & theme
# TODO add tprint methods
