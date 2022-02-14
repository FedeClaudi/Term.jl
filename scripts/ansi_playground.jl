

struct AnsiTag
    open::String
    close::String
end



print_tags(tags)=  for (name, mode) in tags
    println("$(mode.open)$name$(mode.close)")
end 

# ----------------------------------- modes ---------------------------------- #
modes = Dict(
    "normal" => AnsiTag("",""),
    "bold" => AnsiTag("\e[1m", "\e[22m"),
    "dim" => AnsiTag("\e[2m", "\e[22m"),
    "italic" => AnsiTag("\e[3m", "\e[23m"),
    "underline" => AnsiTag("\e[4m", "\e[24m"),
    "blinking" => AnsiTag("\e[5m", "\e[25m"),
    "inverse" => AnsiTag("\e[7m", "\e[27m"),
    "hidden" => AnsiTag("\e[8m", "\e[28m"),
    "striked" => AnsiTag("\e[9m", "\e[29m"),
)

print_tags(modes)


# ---------------------------------------------------------------------------- #
#                                    colors                                    #
# ---------------------------------------------------------------------------- #
# ----------------------------------- 8-bit ---------------------------------- #
println("\n \e[32m"*"-"^20*"COLORS"*"-"^20*"\e[39m")
colors_8_bit = Dict(
    "a_black" => AnsiTag("\e[30m", "\e[39m"),
    "a_red" => AnsiTag("\e[31m", "\e[39m"),
    "a_green" => AnsiTag("\e[32m", "\e[39m"),
    "a_yellow" => AnsiTag("\e[33m", "\e[39m"),
    "a_blue" => AnsiTag("\e[34m", "\e[39m"),
    "a_magenta" => AnsiTag("\e[35m", "\e[39m"),
    "a_cyan" => AnsiTag("\e[36m", "\e[39m"),
    "a_white" => AnsiTag("\e[37m", "\e[39m"),
    "a_default" => AnsiTag("\e[39m", "\e[39m"),

    "b_bg_black" => AnsiTag("\e[40m", "\e[49m"),
    "b_bg_red" => AnsiTag("\e[41m", "\e[49m"),
    "b_bg_green" => AnsiTag("\e[42m", "\e[49m"),
    "b_bg_yellow" => AnsiTag("\e[43m", "\e[49m"),
    "b_bg_blue" => AnsiTag("\e[44m", "\e[49m"),
    "b_bg_magenta" => AnsiTag("\e[45m", "\e[49m"),
    "b_bg_cyan" => AnsiTag("\e[46m", "\e[49m"),
    "b_bg_white" => AnsiTag("\e[47m", "\e[49m"),
    "b_bg_default" => AnsiTag("\e[49m", "\e[49m"),

    "c_red_on_black" => AnsiTag("\e[31;40m", "\e[39;49m"),
    "c_red_on_black_v2" => AnsiTag("\e[31m\e[40m", "\e[39m\e[49m"),

    "d_bright_black" => AnsiTag("\e[90m", "\e[39m"),
    "d_bright_red" => AnsiTag("\e[91m", "\e[39m"),
    "d_bright_green" => AnsiTag("\e[92m", "\e[39m"),
    "d_bright_yellow" => AnsiTag("\e[93m", "\e[39m"),
    "d_bright_blue" => AnsiTag("\e[94m", "\e[39m"),
    "d_bright_magenta" => AnsiTag("\e[95m", "\e[39m"),
    "d_bright_cyan" => AnsiTag("\e[96m", "\e[39m"),
    "d_bright_white" => AnsiTag("\e[97m", "\e[39m"),
    "d_bright_default" => AnsiTag("\e[99m", "\e[39m"),

    "e_bright_bg_black" => AnsiTag("\e[100m", "\e[49m"),
    "e_bright_bg_red" => AnsiTag("\e[101m", "\e[49m"),
    "e_bright_bg_green" => AnsiTag("\e[102m", "\e[49m"),
    "e_bright_bg_yellow" => AnsiTag("\e[103m", "\e[49m"),
    "e_bright_bg_blue" => AnsiTag("\e[104m", "\e[49m"),
    "e_bright_bg_magenta" => AnsiTag("\e[105m", "\e[49m"),
    "e_bright_bg_cyan" => AnsiTag("\e[106m", "\e[49m"),
    "e_bright_bg_white" => AnsiTag("\e[107m", "\e[49m"),
    "e_bright_bg_default" => AnsiTag("\e[109m", "\e[49m"),
)

print_tags(colors_8_bit)


# ------------------------------- 16 bit color ------------------------------- #
println("\n\n")
for i in 0:255
    cstart = "\e[38;5;$(i)m"
    cend = "\e[39m"
    bgstart = "\e[48;5;$(i)m"
    bgend = "\e[49m"
    print("$(cstart)F$(bgstart)\e[37mB\e[30mG$(bgend)  ")
end

# ------------------------------------ rbg ----------------------------------- #
println("\n\n")

for r in 1:10:255, b in 1:10:255, g in 1:10:255
    rbg = "$(r);$(b);$(g)"
    cstart = "\e[38;2;$(rbg)m"
    cend = "\e[39m"
    bgstart = "\e[48;2;$(rbg)m"
    bgend = "\e[49m"
    print("$(cstart)F$(bgstart)\e[37mB\e[30mG$(bgend)  ")
end