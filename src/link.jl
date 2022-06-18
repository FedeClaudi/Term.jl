function create_link(filepath::String)
    parts = splitpath(filepath)
    name = length(parts) > 3 ? joinpath(parts[end-2:end]) : joinpath(parts)
    return "\e]8;;file:" * filepath * "\a" * name * "\e]8;;\a"
end


function creat_link(url::String, name::String)
    return "\e]8;;" * url * "\a" * name * "\e]8;;\a"
end