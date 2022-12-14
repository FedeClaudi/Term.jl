
module Prompts

import Term
import Term: highlight, TERM_THEME
import ..Style: apply_style
import ..Tprint: tprint, tprintln

export TypePrompt, OptionsPrompt, DefaultPropt, confirm, ask

"""
Prompts in VSCODE require a bit of a hack:
https://discourse.julialang.org/t/vscode-errors-with-user-input-readline/75097/4?u=fedeclaudi
"""


# ------------------------------ abstract prompt ----------------------------- #

""" Prompt types """
abstract type AbstractPrompt end

function Base.print(io::IO, prompt::AbstractPrompt)
    style = TERM_THEME[].prompt_text
    tprintln(io, "{$style}{dim}❯❯❯ {/dim}"*prompt.prompt * "{/$style}")
end

Base.println(io::IO, prompt::AbstractPrompt) = print(io, prompt, "\n")
tprint(io::IO, prompt::AbstractPrompt) = print(io, prompt)
tprintln(io::IO, prompt::AbstractPrompt) = println(io, prompt)

""" display an `AbstractPrompt`, get user's reply and validate. """
function ask(io::IO, prompt::AbstractPrompt)
    print(io, prompt)
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


struct AnswerValidationError <: Exception
    answer_type
    expected_type
    err
end

Term.Errors.error_message(e::AnswerValidationError) = highlight(
    "TypePrompt expected an answer of type: `$(e.expected_type)`, got `$(e.answer_type)` instead\nConversion to `$(e.expected_type)` failed because of: $(e.err)") |> apply_style


function validate_answer(answer, prompt::TypePrompt)
    answer isa prompt.answer_type && return answer

    err = nothing
    try
        return parse(prompt.answer_type, answer)
    catch err
    end
    throw(AnswerValidationError(typeof(answer), prompt.answer_type, apply_style(string(err))))
end



# ---------------------------------------------------------------------------- #
#                                OPTIONS PROMPTS                               #
# ---------------------------------------------------------------------------- #
""" Prompt types where user can only choose among options """
abstract type AbstractOptionsPrompt <: AbstractPrompt end


function Base.print(io::IO, prompt::AbstractOptionsPrompt)
    style = TERM_THEME[].prompt_text
    txt = "{$style}{dim}❯❯❯ {/dim}"*prompt.prompt * "{/$style} "
    answer_styles = map(
        i -> i == prompt.default ? TERM_THEME[].prompt_default_option : TERM_THEME[].prompt_options,
        1:length(prompt.options)
    )
    options = join(
        (
            map(
                i -> "{$(answer_styles[i])}$(prompt.options[i]){/$(answer_styles[i])}",
                1:length(prompt.options)
            )
        ), ", "
    )
    tprint(io, txt * options)
end


function validate_answer(answer, prompt::AbstractOptionsPrompt)
    (prompt isa AbstractDefaultPrompt && strip(answer) == "") && return prompt.options[prompt.default]
    answer ∉ prompt.options && begin
        tprintln("{dim}Answer `$(answer)` is not valid.{/dim}")
        return nothing
    end
    return answer

end


function ask(io::IO, prompt::AbstractOptionsPrompt)
    ans = nothing
    while isnothing(ans)
        println(io, prompt)
        ans = validate_answer(readline(), prompt)
    end
    return ans
end



""" Options types with a default answer """
abstract type AbstractDefaultPrompt <: AbstractOptionsPrompt end


""" An option prompt with a default option """
struct DefaultPropt <: AbstractDefaultPrompt
    options::Vector
    default::Int # index of default answer
    prompt::String

    function DefaultPropt(options::Vector, default::Int, prompt::String)
        @assert default > 0 && default < length(options)  "Default answer number: $default not valid"
        new(options, default, prompt)
    end
end



confirm() = ask(DefaultPropt(["Yes", "No"], 1, "Confirm?"))
end

