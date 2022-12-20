"""
Reshaping strings with Julia code requires particular care
"""
function reshape_code_string(code, width::Int)
    # highlight syntax
    code = highlight(code; ignore_ansi=false) |> apply_style

    # reshape
    code = reshape_text(code, width; ignore_markup = true) 
    return code
end