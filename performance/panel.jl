import Term: Panel

# Creating a panel is very simple


p = @time Panel("This is my first panel!")
print(p)

p = @time Panel("This is my first panel!"; fit=true)
print(p)