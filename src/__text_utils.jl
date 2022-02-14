
"""Removes all spaces from a string"""
nospaces(text::AbstractString) = replace(text, " " => "")

"""Removes all () brackets from a string"""
remove_brackets(text::AbstractString) = replace(replace(text, "("=>""), ")"=>"")

"""Removes spaces after commas """
unspace_commas(text::AbstractString) = replace(replace(text, ", "=>","), ". "=>".")