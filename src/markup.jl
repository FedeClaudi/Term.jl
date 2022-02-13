module markup
    include("colors.jl")
    include("modes.jl")
    include("utils.jl")

    using Parameters

    export Tag

    # ----------------------------------- utils ---------------------------------- #
    """"Checks if a string with style is a clolor"""
    is_color(str::AbstractString) = string(str) ∈ keys(ANSI_COLOR_NAMES)

    """
    Cecks if a string with style information specifies a backgroun color.
    For that it has to be of the form "on_COLOR".
    """
    is_background(str::AbstractString) = is_color(str[4:end])

    """Checks if a string with style is a mode specification"""
    is_mode(str::AbstractString) = string(str) ∈ keys(MODES)

    """If a tag starts with '/' it must be closing another tag"""
    is_tag_closer(text::String) = '/' == text[1]



    # --------------------------------- text tag --------------------------------- #
    """
    RawSingleTag represents a portion of text specifying a tag. For instance in
        ``"text [this is tag] and [/this is end tag]"`

    There are two `RawSingleTag`: "[this is tag]" and "[/this is end tag]"
    """
    struct RawSingleTag
        start_char_idx::Int  # position of [ in main text
        end_char_idx::Int # position of ] in main text
        text::AbstractString  # text between []
        closer::Bool
    end

    # ---------------------------------------------------------------------------- #
    #                                      Tag                                     #
    # ---------------------------------------------------------------------------- #

    """
        Tag

    Represents a complete style tag + the text to be sylised. Given:
        `"before [start] inside [/end] after`
    there is a single `Tag` (in comparison, there are 2 `TagText`) going from
    [start] -> [end].
    """
    @with_kw mutable struct Tag
        start_idx:: Int  # position of first [
        end_idx:: Int  # position of last ]
        text::AbstractString  # string XXX from [open]XXX[/closed]
        definition::String   # text in first []
        color::String = "7"
        colorname::String="white"
        background::String = "49"
        bg_colorname::String="default"
        mode::String = "0"
        modename::String = "default"
    end
   



    """
    Constructor for `Tag` extacting style info from a string description (`tag`).
    """
    function Tag(start_idx::Int, end_idx::Int, tag::String, text::AbstractString)
        tg = Tag(start_idx=start_idx, end_idx=end_idx, text=text, definition=tag)

        elements = split(tag)
        for elem in elements
            elem = remove_brackets(elem)
            if is_color(elem) 
                tg.color = string(30 + ANSI_COLOR_NAMES[elem])
                tg.colorname = elem
            elseif is_mode(elem)
                tg.mode = string(MODES[elem])
                tg.modename = elem
            elseif is_background(elem)
                tg.background = string(40 + ANSI_COLOR_NAMES[elem[4:end]])
                tg.bg_colorname = elem
            else
                @debug "Type of tag element not identified: $elem"
            end
        end
        return tg
    end

    """Creates a string with ANSI codes given a tag"""
    tag2ansi(tag::Tag) = "\033[$(tag.mode);$(tag.color);$(tag.background)m$(tag.text)\033[0m"

end