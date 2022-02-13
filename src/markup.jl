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

    """
    Gets the postion of all [ ] and does quality checks.
    """
    function get_brackets_position(text::AbstractString)
        stripped = escape_brackets(text)
        starts = find_in_str("[", stripped)
        ends = find_in_str("]", stripped)
        nO, nC = length(starts), length(ends)
        
        # checks
        if nO != nC 
            @debug "Failed brackes finding" text stripped starts
            throw("Unequal number of '[' and ']', in text:  $text")
        end

        if nO == 0
            return [], [], 0, 0
        end
    
        for (i, (open, close)) in enumerate(zip(starts, ends))
            # check for nested []
            if i < nO
                if starts[i+1] < close || close < open
                    @debug "Failed to parse text: '$text'" open close starts ends
                    throw("There is a nested set of square brackets or error while parsing text, case not handled")
                end
            end
        end
        return starts, ends, nO, nC
    end
    
    """
        Checks if a string has markup tags definitions in it.
    """
    has_tags(text::AbstractString) = get_brackets_position(text)[3] > 0


    function tag_info(t)
        tprint("""
        [bold green]Tag[/bold green]:
            [yellow]range[/yellow]: [cyan]$(t.start_idx):$(t.end_idx)[/cyan]
            [yellow]text[/yellow]: [cyan]$(t.text)[/cyan]
            [yellow]color[/yellow]: [$(t.colorname)]$(t.colorname) (code: $(t.color))[/$(t.colorname)]
            [yellow]mode[/yellow]: [$(t.modename) white]$(t.modename) (code: $(t.mode))[/$(t.modename) white]
            [yellow]background[/yellow]: [$(t.bg_colorname) white]$(t.bg_colorname) (code: $(t.background))[/$(t.bg_colorname) white]
        """)
    end

    # ---------------------------------------------------------------------------- #
    #                                   Text Tag                                   #
    # ---------------------------------------------------------------------------- #
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


    ANSI_TAG_OPEN = "\033["
    ANSI_TAG_CLOSE = "\033[0m"

end