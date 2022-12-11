using Term

# ------------------------------ abstract prompt ----------------------------- #

""" Prompt types """
abstract type AbstractPrompt end

""" display an `AbstractPrompt`, get user's reply and validate. """
function ask(prompt::AbstractPrompt)
    println(prompt)
    ans = readline()
    return validate_answer(ans, prompt)
end

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

function Base.println(io, prompt::TypePrompt)
    println(io, prompt.prompt)
end

function validate_answer(answer, prompt::TypePrompt)
    answer isa prompt.answer_type && return answer
    try
        return convert(prompt.answer_type, answer)
    catch
        error("Prompt expected answer of type: $(prompt.answer_type), got $(typeof(answer))")
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



ask(TypePrompt(Int, "give me a number"))

