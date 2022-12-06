using Term

abstract type AbstractPrompt end

function validate_default(default::String, options::Vector{String})
    default ∉ options && error("Default is not a valid option: $default, $(options).")
end


function ask(p::AbstractPrompt)

    _options = join(map(
        o -> o == p.default ? "{bold underline}$o{/bold underline}" : o,
        p.options
    ), ", ")

    tprint("$(p.text)? $(_options)\n\n")
    reply = readline();
end


struct YNPrompt <: AbstractPrompt
    text::String
    options::Vector{String}
    default::String

    function YNPrompt(text::String, options::Vector{String}, default::String)
        validate_default(default, options)
        @assert length(options) >= 2 "Need at least two options for a prompt"
        return new(text, options, default)
    end
    
end





confirm = YNPrompt("Confirm", ["Yes", "No"], "Yes")
ask(confirm)