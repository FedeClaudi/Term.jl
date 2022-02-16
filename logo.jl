import IterTools: product as ×

import Term: Panel



logo = """            GGGG   
         GGGGGGGGGG     
        GGGGGGGGGGGG    
        GGGGGGGGGGGG    
         GGGGGGGGGG   
            GGGG           
    RRRR            PPPP    
 RRRRRRRRRR      PPPPPPPPPP   
RRRRRRRRRRRR    PPPPPPPPPPPP
RRRRRRRRRRRR    PPPPPPPPPPPP
 RRRRRRRRRR      PPPPPPPPPP
    RRRR            PPPP   """
                              

logo = replace(logo, "G"=>"[#389826 bold]o[/]")
logo = replace(logo, "P"=>"[#9558B2 bold]o[/]")
logo = replace(logo, "R"=>"[#CB3C33 bold]o[/]")



print("\n\n")
print(Panel(logo, style=" bold green", title="Term", title_style="bold red"), )

