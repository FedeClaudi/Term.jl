# Prompt

Time for a little example of a simple thing you can use `Term.jl` for: asking for some input. Use a `Prompt`, ask a question, get an answer. Simple, but a little extra style. That's what `AbstractPrompt` types are for. There's a few different flavors, which we'll look at in due time, but essentially a prompt is made of a bit of text, the `prompt` that is displayed to the user, and some machinery to capture the user's input and parse it/ validate it. 

For example:

```@example prompt
using Term.Prompts

prompt = Prompt("Simple, right?");
```

creates a `Prompt` object and `ask` then prints the prompt and asks for input: 
```julia
prompt |> ask
```
the output should look something like
```@example prompt
print(prompt)  # hide
```

here we construct a basic `Prompt` and "ask" it: print the message and capture the reply. `ask` returns the answer, which you can do with as you please. A small warning before we carry on:

!!! warning "Using VSCode"
    As you can see [here](https://discourse.julialang.org/t/vscode-errors-with-user-input-readline/75097/4?u=fedeclaudi), `readlines`, which `AbstractPrompts` use to get the user's input, is a bit troublesome in VSCode. In VSCode, after the prompt gets printed you need to enter "space" (hit the space bar) and then enter and **after** that you can enter your actual replies.

## Prompt flavours
There's a couple more ways you can use prompts like. One is to ensure you get an answer of the correct `Type`, using the imaginatively names `TypePrompt`:

```@example prompt

# this only accepts `Int`s
prompt = TypePrompt(Int, "give me a number")  # don't forget to |> ask
print(prompt) # hide
```


If your answer can't be converted to the correct type you'll get a `AnswerValidationError`, not good.


So, what if you want to get user inputs, but you don't want to handle any crazy input they can provide? Fear not, use `OptionsPrompt` so that only acceptable options will be ok. This will keep "asking" your prompt until the user's answer matches one of the given options

```@example prompt
prompt = OptionsPrompt(["a lot", "so much", "the most"], "How likely would you be to recommend Term.jl to a friend or colleague?") # don't forget to |> ask
print(prompt) # hide
```

Okay, so much typing though. Let's be realistic, most likely you just want to ask a yes/no question and the answer is likely just yes. So just use a `DefaultPrompt`:

```@example prompt

# one says the first option is the default
prompt = DefaultPrompt(["yes", "no"], 1, "Confirm?") # don't forget to |> ask
print(prompt) # hide
```

still too much typing? You can just use the `confirm` function which is equivalent to asking the prompt shown above. 


## Style
The style of prompt elements (e.g. the color of the prompt's text or of the options) is defined in `Theme`. You can also pass style information during prompt creation:

```@example prompt
Prompt("Do you like this color?", "red") |> println
DefaultPrompt(["yes", "no"], 1, "Confirm?", "green", "blue", "red") |> println
```