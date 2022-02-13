"""
    find_in_str("test", "my test")  # [4]
Returns the first index of when the string "search"
appears in the text.
"""
find_in_str(search::String, text::String) = [f[1] for f in findall(search, text)]

"""Removes [()] from a string"""
remove_brackets(text::AbstractString) = replace(replace(replace(replace(text, "[" => ""), "]" => ""), "(" => ""), ")" => "")

"""Removes all spaces from a string"""
nospaces(text::String) = replace(text, " " => "")