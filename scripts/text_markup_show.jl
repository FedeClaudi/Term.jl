using Revise
Revise.revise()

using Term
import Term: MarkupText



text_string = "[bold red]Hello[/bold red] [white on_blue]---[/white on_blue] [green]Test[/green] --- [black on_green]success![/black on_green]?"

text = MarkupText(text_string)


info.(text.tags)
tprint(text_string)
