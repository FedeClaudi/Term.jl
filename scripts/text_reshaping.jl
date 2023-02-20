import Term: reshape_text, tprintln
import Term.Consoles: clear

strings = [
    # latin alphabet
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "Lorem {red}ipsum dolor sit {underline}amet, consectetur{/underline} adipiscing elit, {/red}{blue}sed do eiusmod tempor incididunt{/blue} ut labore et dolore magna aliqua.",
    "Lorem{red}ipsumdolorsit{underline}amet, consectetur{/underline} adipiscing elit, {/red}seddoeiusmo{blue}dtemporincididunt{/blue}ut labore et dolore magna aliqua.",

    # thai
    "ต้าอ่วยวาทกรรมอาว์เซี้ยว กระดี๊กระด๊า ช็อปซาดิสต์โมจิดีพาร์ตเมนต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเตอร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",
    "ต้าอ่วยวาท{red}กรรมอาว์เซี้ยว กระดี๊กระด๊า {/red}ช็อปซาดิสต์โมจิดีพาร์ตเม{blue underline}นต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเต{/blue underline}อร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",

    # # korean
    "국가유공자·상이군경 및 전몰군경의 유가족은 법률이 정하는 바에 의하여",
    "국{red}가유공자·상이군{bold}경 및 전{/bold}몰군경의 유{/red}가족은 법률이 정하는 바에 의하여",

    # # large chars
    "┌────────────────┬────────────────┬────────────────┬────────────────┬──────────────",
    "┌────────────abcde────┬──────────── ────┬────────abcde fghi────────┬────────────────┬──────────────",
    "┌─────────{red}───ab{/red}cde────┬──────{green}────── ────┬────────abcde fghi{/green}────────┬────────────────┬──────────────",
    "┌──────────{red}────{/red}──┬{blue bold}────────────────┬{/blue bold}──────────────┬────────────────┬──────────────end",

    # nospaces
    "."^100,
    ".{red}|||{/red}...."^10,
    ".|||...."^10,
    replace(
        """
Lorem ipsum {bold}dolor sit{/bold} amet, consectetur adipiscing elit,
ed do e{red}iusmod tempor incididunt{/red} ut {bold}labore et {underline}dolore{/underline} magna aliqua.{/bold} Ut enim ad minim
veniam, quis{green} nostrud exercitation {on_black}ullamco laboris nisi ut aliquip ex {/on_black}
ea commodo consequat.{blue} Duis aute irure dolor in{/blue} reprehenderit 
in voluptate velit{/green} esse {italic}cillum dolore{/italic}{red} eu{/red}{italic green} fugiat {/italic green}nulla 
pariatur. Excepteur{red} sint{/red}{blue} occaecat cupidatat {/blue}non proident, 
sunt in culpa qui {italic}officia{/italic} deserunt mollit anim 
id est laborum.""",
        "\n" => "",
    ),
]

print("\n"^3)
width = 33
for text in strings
    # println('_'^width)
    # println(reshape_text(text, width))

    print("\n\n")
    println("\e[0m" * '_'^width)
    tprintln(reshape_text(text, width) * Panel(; height = 10, width = 10))
    println("\e[0m" * '_'^width)
end

# text = strings[end]

# println('_'^width)
# println(reshape_text(text, width))
# println(text)
