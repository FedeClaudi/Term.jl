import Term: reshape_text
import Term.console: clear


strings = [
    # latin alphabet
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "Lorem [red]ipsum dolor sit [underline]amet, consectetur[/underline] adipiscing elit, [/red][blue]sed do eiusmod tempor incididunt[/blue] ut labore et dolore magna aliqua.",
    "Lorem[red]ipsumdolorsit[underline]amet, consectetur[/underline] adipiscing elit, [/red]seddoeiusmo[blue]dtemporincididunt[/blue]ut labore et dolore magna aliqua.",

    # arab
    "استنكار  النشوة وتمجيد الألم نشأت بالفعل، وسأعرض لك",
    "لكن لا بد أن أوضح لك أن كل ه[/green]ذه الأفكار[green] المغلوطة حو[/red]ل استنكار  النشوة وتمجيد الألم نشأت بالفعل، وسأعرض لك التفاصيل لتكتشف حقيقة و[red]أساس تلك السعادة",

    # thai
    "ต้าอ่วยวาทกรรมอาว์เซี้ยว กระดี๊กระด๊า ช็อปซาดิสต์โมจิดีพาร์ตเมนต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเตอร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",
    "ต้าอ่วยวาท[red]กรรมอาว์เซี้ยว กระดี๊กระด๊า [/red]ช็อปซาดิสต์โมจิดีพาร์ตเม[blue underline]นต์ อินดอร์วิว สี่แยกมาร์กจ๊อกกี้ โซนี่บัตเต[/blue underline]อร์ฮันนีมูน ยาวีแพลนหงวนสคริปต์ แจ็กพ็อตต่อรองโทรโข่งยากูซ่ารุมบ้า บอมบ์เบอร์รีวีเจดีพาร์ทเมนท์ บอยคอตต์เฟอร์รี่บึมมาราธอน ",

    # # korean
    "국가유공자·상이군경 및 전몰군경의 유가족은 법률이 정하는 바에 의하여",
    "국[red]가유공자·상이군[bold]경 및 전[/bold]몰군경의 유[/red]가족은 법률이 정하는 바에 의하여",

    # # large chars
    "┌────────────────┬────────────────┬────────────────┬────────────────┬──────────────",
    "┌────────────abcde────┬──────────── ────┬────────abcde fghi────────┬────────────────┬──────────────",
    "┌─────────[red]───ab[/red]cde────┬──────[green]────── ────┬────────abcde fghi[/green]────────┬────────────────┬──────────────",
    "┌──────────[red]────[/red]──┬[blue bold]────────────────┬[/blue bold]──────────────┬────────────────┬──────────────end",

    # nospaces
    "."^100  ,
    ".[red]|||[/red]...."^10,
    ".|||...."^10, 
]

clear()
width = 21
for text in strings
    println('_'^width)
    println(reshape_text(text, width))
    # show(reshape_text(text, width))
    # print("\n")
end


# text = strings[end-1]
# println('_'^width)
# println(reshape_text(text, width))