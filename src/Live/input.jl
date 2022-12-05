
abstract type KeyInput end
struct ArrowLeft <: KeyInput end
struct ArrowRight <: KeyInput end
struct ArrowUp <: KeyInput end
struct ArrowDown <: KeyInput end
struct DelKey <: KeyInput end
struct HomeKey <: KeyInput end
struct EndKey <: KeyInput end
struct PageUpKey <: KeyInput end
struct PageDownKey <: KeyInput end

struct CharKey <: KeyInput
    char::Char
end

KEYs = Dict{Int,KeyInput}(
    1000 => ArrowLeft(),
    1001 => ArrowRight(),
    1002 => ArrowUp(),
    1003 => ArrowDown(),
    1004 => DelKey(),
    1005 => HomeKey(),
    1006 => EndKey(),
    1007 => PageUpKey(),
    1008 => PageDownKey(),
)

"""
    keyboard_input(live::AbstractLiveDisplay)

Read an user keyboard input during live display.

If there are bytes available at `stdin`, read them.
If it's a special character (e.g. arrows) call `key_press`
for the `AbstractLiveDisplay` with the corresponding
`KeyInput` type. Else, if it's not `q` (reserved for exit),
use that.
If the input was `q` it signals that the display should be stopped
"""
function keyboard_input(live::AbstractLiveDisplay)::Bool
    if bytesavailable(terminal.in_stream) > 0
        c = readkey(terminal.in_stream) |> Int

        c in keys(KEYs) && key_press(live, KEYs[Int(c)])

        c = Char(c)
        c == 'q' && return true
        key_press(live, CharKey(c))
    end
    return false
end
