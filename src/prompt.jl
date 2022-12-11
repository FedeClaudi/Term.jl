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

ask(prompt::AbstractPrompt) = ask(stdout, prompt)

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
    answers::Vector{String}
    default::Int # index of default answer
    prompt::String
end

# TODO ask, validate and print methods

confirm() = ask(DefaultPropt(["Yes", "No"], 1, "Confirm?"))


# ---------------------------------------------------------------------------- #
#                                      DEV                                     #
# ---------------------------------------------------------------------------- #
ask(TypePrompt(Int, "give me a number"))

