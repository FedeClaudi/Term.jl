using Term

# ------------------------------ abstract prompt ----------------------------- #

""" Prompt types """
abstract type AbstractPrompt end

""" display an `AbstractPrompt`, get user's reply and validate. """
function ask end

# -------------------------------- type prompt ------------------------------- #
"""
    struct TypePrompt{T}
        answer_type::Union{Union, DataType} = T
        prompt::String
    end

Asks for input given `prompt` and checks/converts the answer to type `T`
"""
struct TypePrompt{T}
    answer_type::Union{Union, DataType} = T
    prompt::String
end

# TODO ask and validate answer methods and print

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


