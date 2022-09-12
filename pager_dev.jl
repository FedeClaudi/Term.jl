using Suppressor: @capture_out
using Term
using Term.LiveDisplays
using Term.Consoles


clear()
text =  @capture_out inspect(Panel; documentation=true, supertypes=false)
# text = join(rand("\nasdasd\n \n asd ", 1000))
pager = Pager(text; page_lines=30, title="inspect(Panel)")
while true
    LiveDisplays.update!(pager) || break
end
stop!(pager)
println("done")

