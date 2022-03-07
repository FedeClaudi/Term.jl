
Related:
- https://github.com/KristofferC/Crayons.jl
- https://github.com/Aerlinger/AnsiColor.jl



## Roadmap

#### docs/examples
- [ ] re-write docstrings; https://docs.julialang.org/en/v1/manual/documentation/
- [x] README generated by Term like Rich's
- [x] logo
- [ ] docs
  - [ ] installation
  - [ ] basic usage
  - [ ] macros
  - [ ] textbox/panels + nesting
  - [ ] layout: stacking + layout objects
  - [ ] inspect
  - [ ] errors
  - [ ] logging


### To do & bugs
- [ ] `highlight` sometimes doesnt apply styles correctly when >1 elements per line
- [ ] BUG: read code style from file sometimes gives the wrong line (towards end of file)
- [x] `logging` accept symbols and expressions in message

#### Future features
- [ ] add :time and :date options for panel's subtitles

- [ ] pretty print commond data structure such as Dict

- [ ] progress bar

- [ ] allow things like Panel and TextBox to `fill` their parent renderable

- [ ] tree visualization
- [ ] type hierarchy tree (https://towardsdatascience.com/runtime-introspection-julias-most-powerful-best-kept-secret-bf845e282367)

- [ ] logging:
  - [ ] get "stack trace" of logging: where is the log message triggered from?

- [ ] allow for user created `Theme`s

- [ ] add additional error types to error messages
  - [ ] SystemError
  - [ ] UndefRefError 
  - [ ] EOFError
  - [ ] InterruptException