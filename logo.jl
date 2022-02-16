import IterTools: product as ×

import Term: Panel


logo = """ 
            GGGGG                                                                
           GGGGGGG                                                               
          GGGGGGGGG                                                              
          GGGGGGGGG                                                              
          GGGGGGGGG                 TTTTTTTTTTTTT                              
          GGGGGGGGG                 TTTTTTTTTTTTT eeee                
          GGGGGGGGG                      TTT    eeeeeeeee rrr   rrrmmm      mmm
           GGGGGGG                       TTT   eee    eee rrr rrr  mmmmm  mmmmm
            GGGGG                        TTT   eeeeeeee   rrrr     mmm  mm  mmm
                                         TTT   eee        rrr      mmm      mmm
                                         TTT   eee        rrr      mmm      mmm
   RRRRR              PPPPP              TTT     eeeee    rrr      mmm      mmm
  RRRRRRR            PPPPPPP                                                    
 RRRRRRRRR          PPPPPPPPP                                                    
 RRRRRRRRR          PPPPPPPPP                                                   
 RRRRRRRRR          PPPPPPPPP                                                   
 RRRRRRRRR          PPPPPPPPP                                                   
 RRRRRRRRR          PPPPPPPPP                                                   
  RRRRRRR            PPPPPPP                                                    
   RRRRR              PPPPP                                                      
"""

logo = """
            gggg                      
         gggggggggg                 
        gggggggggggg                 
        gggggggggggg                    
         gggggggggg   
            gggg                           

    rrrr             pppp                      
 rrrrrrrrrr       pppppppppp                 
rrrrrrrrrrrr     pppppppppppp                 
rrrrrrrrrrrr     pppppppppppp                    
 rrrrrrrrrr       pppppppppp
    rrrr             pppp                           
"""
                              


logo = replace(logo, "g"=>"[green bold]X[/]")
logo = replace(logo, "p"=>"[purple bold]X[/]")
logo = replace(logo, "r"=>"[red bold]X[/]")



print("\n\n")
print(Panel(logo, style="green"), )

