using Term: Panel

print(Panel())

print(Panel("test"))

print(Panel("test"^100))

print(Panel(; width=100, fit=:nofit))

print(Panel("."^250; width=100, fit=:nofit))

print(Panel("."^500; width=100))
Panel("."^500; width=100)
print(Panel("."^50; width=25, height=10))


print(
    Panel(
        Panel("test\ntest")
    )
)


print(
    Panel(
        Panel("test\ntest"),
        Panel("test\ntest"),
    )
)

print(
    Panel(
        "testasdsadadsa",
        "test",
    )
)