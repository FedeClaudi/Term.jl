"""
    module Prompts

Defines functionality relative to prompts in the terminal. 
Typically a prompt is composed of a piece of text that gets displayed prompting
the user to provide an input and some machinery to parse/validate the user's inputs.
For example, some prompts may only accept as replies objects of a given type (e.g. an `Int`).
Additionally, some prompts will have "options" the user can choose between and the answer
has to be one of these options.
"""
module Prompts

import Term
import Term: highlight, TERM_THEME
import ..Style: apply_style
import ..Tprint: tprint, tprintln
import ..Repr: @with_repr, termshow

export Prompt, TypePrompt, OptionsPrompt, DefaultPrompt, confirm, ask

"""
Prompts in VSCODE require a bit of a hack:
https://discourse.julialang.org/t/vscode-errors-with-user-input-readline/75097/4?u=fedeclaudi

When the text is displayed, the user should input "space" and a new line before inputting the
actual reponse. This is not a Term.jl problem.
"""

# ------------------------------ abstract prompt ----------------------------- #

""" Prompt types """
abstract type AbstractPrompt end

_print_prompt_text(io::IO, prompt::AbstractPrompt) =
    tprintln(io, "{$(prompt.style)}{dim}❯❯❯ {/dim}" * prompt.prompt * "{/$(prompt.style)}")

"""
    Base.print(io::IO, prompt::AbstractPrompt)

Default prompt printing, just prints the message `prompt`
with a bit of style.
"""
Base.print(io::IO, prompt::AbstractPrompt) = _print_prompt_text(io, prompt)

"""
    ask

Ask does three things:
  1. displays a prompt
  2. accepts user input and validates it
  3. if the answer was accepted, returns the desired value.
"""
function ask end

""" 
    ask(io::IO, prompt::AbstractPrompt)

Default `ask` method for generic prompt objects.
"""
function ask(io::IO, prompt::AbstractPrompt)
    print(io, prompt)
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

# -------------------------- answer validation error ------------------------- #

"""
    AnswerValidationError <: Exception

Exception to handle cases in which the user's answer to a
prompt failed to pass validation.
"""
struct AnswerValidationError <: Exception
    answer_type
    expected_type
    err
end

Base.showerror(io::IO, e::AnswerValidationError) = print(
    io,
    highlight(
        "TypePrompt expected an answer of type: `$(e.expected_type)`, got `$(e.answer_type)` instead\nConversion to `$(e.expected_type)` failed because of: $(e.err)",
    ) |> apply_style,
)

# ---------------------------------------------------------------------------- #
#                                    PROMPT                                    #
# ---------------------------------------------------------------------------- #

"""
    struct Prompt{T} <: AbstractPrompt
        prompt::String
        style::String = TERM_THEME[].prompt_text
    end

Generic prompt, accepts any answer
"""
@with_repr struct Prompt <: AbstractPrompt
    prompt::String
    style::String
end
Prompt(prompt::String) = Prompt(prompt, TERM_THEME[].prompt_text)

validate_answer(ans, ::Prompt) = ans

# ---------------------------------------------------------------------------- #
#                                  TYPE PROMPT                                 #
# ---------------------------------------------------------------------------- #

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
    style::String
end

TypePrompt(answer_type, prompt::String) =
    TypePrompt(answer_type, prompt, TERM_THEME[].prompt_text)

"""
    validate_answer(answer, prompt::TypePrompt)

For a TypePrompt an anwer is valid if it is of the correct type
or if a string containg the answer can be parsed as the correct type.
For example, `answer="1.0"` can be accepted for a TypePrompt
asking for a `Number`.
If validation fails, an error is raised.
"""
function validate_answer(answer, prompt::TypePrompt)
    answer isa prompt.answer_type && return answer

    err = nothing
    try
        return parse(prompt.answer_type, answer)
    catch err
    end
    throw(
        AnswerValidationError(typeof(answer), prompt.answer_type, apply_style(string(err))),
    )
end

# ---------------------------------------------------------------------------- #
#                                OPTIONS PROMPTS                               #
# ---------------------------------------------------------------------------- #
""" Prompt types where user can only choose among options """
abstract type AbstractOptionsPrompt <: AbstractPrompt end

"""
    struct OptionsPrompt <: AbstractOptionsPrompt
        options::Vector{String}
        prompt::String
        style::String 
        answers_style::String
    end

Just a simple prompt, giving some pre-defined options.
"""
@with_repr struct OptionsPrompt <: AbstractOptionsPrompt
    options::Vector{String}
    prompt::String
    style::String
    answers_style::String
end

OptionsPrompt(options, prompt::String) =
    OptionsPrompt(options, prompt, TERM_THEME[].prompt_text, TERM_THEME[].prompt_options)

"""
    Base.print(io::IO, prompt::AbstractOptionsPrompt)

Options prompts additionally print the available options. 
"""
function Base.print(io::IO, prompt::AbstractOptionsPrompt)
    _print_prompt_text(io, prompt)
    tprint(
        io,
        " {$(prompt.answers_style)}" *
        join(prompt.options, " {$(prompt.style)}/{/$(prompt.style)} ") *
        "{/$(prompt.answers_style)}";
        highlight = false,
    )
end

"""
    validate_answer(answer, prompt::AbstractOptionsPrompt)

For an AbstractOptionsPrompt an answer is accepted if its one of the options.
Additionally, for an `AbstractDefaultPrompt`, if no answer is given that's
also accepted and the default option is returned.
"""
function validate_answer(answer, prompt::AbstractOptionsPrompt)
    (prompt isa AbstractDefaultPrompt && strip(answer) == "") &&
        return prompt.options[prompt.default]
    strip(answer) ∉ prompt.options && begin
        tprintln("{dim}Answer `$(answer)` is not valid.{/dim}")
        return nothing
    end
    return answer
end

"""
    ask(io::IO, prompt::AbstractOptionsPrompt)

In asking an `AbstractOptionsPrompt`, keep asking for input
until an accepted answer is provided.
"""
function ask(io::IO, prompt::AbstractOptionsPrompt)
    ans = nothing
    while isnothing(ans)
        println(io, prompt)
        ans = validate_answer(readline(), prompt)
    end
    return ans
end

# ---------------------------------------------------------------------------- #
#                                DEFAULT PROMPT                                #
# ---------------------------------------------------------------------------- #

""" Options prompt types with a default answer """
abstract type AbstractDefaultPrompt <: AbstractOptionsPrompt end

"""

"""
@with_repr struct DefaultPrompt <: AbstractDefaultPrompt
    options::Vector{String}
    default::Int
    prompt::String
    style::String
    answers_style::String
    default_answer_style::String

    function DefaultPrompt(options::Vector, default::Int, prompt::String, args...)
        @assert default > 0 && default <= length(options) "Default answer number: $default not valid"
        new(options, default, prompt, args...)
    end
end

function DefaultPrompt(options::Vector, default::Int, prompt::String)
    DefaultPrompt(
        options,
        default,
        prompt,
        TERM_THEME[].prompt_text,
        TERM_THEME[].prompt_options,
        TERM_THEME[].prompt_default_option,
    )
end

"""
    Base.print(io::IO, prompt::AbstractDefaultPrompt)

Print a prompt with style applied to the default option.
"""
function Base.print(io::IO, prompt::AbstractDefaultPrompt)
    n_options = length(prompt.options)
    _print_prompt_text(io, prompt)
    answer_styles = map(
        i -> i == prompt.default ? prompt.default_answer_style : prompt.answers_style,
        1:n_options,
    )
    options = join(
        (map(
            i -> "{$(answer_styles[i])}$(prompt.options[i]){/$(answer_styles[i])}",
            1:n_options,
        )),
        ", ",
    )
    tprint(io, " " * options)
end

confirm() = ask(DefaultPrompt(["yes", "no"], 1, "Confirm?"))
end
