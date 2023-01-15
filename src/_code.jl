"""
Reshaping strings with Julia code requires particular care
"""
function reshape_code_string(code, width::Int)
    # highlight syntax
    code = apply_style(highlight(code; ignore_ansi = false); leave_orphan_tags = true)

    # reshape
    code = reshape_text(code, width; ignore_markup = true)
    return code
end
