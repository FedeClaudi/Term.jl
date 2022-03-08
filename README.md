[![Build Status](https://github.com/FedeClaudi/Term.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/FedeClaudi/Term.jl/actions/workflows/CI.yml?query=branch%3Amain)

[![Coverage](https://codecov.io/gh/FedeClaudi/Term.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/FedeClaudi/Term.jl)

[![Dev docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://fedeclaudi.github.io/Term.jl/dev/)


Related:
- https://github.com/KristofferC/Crayons.jl
- https://github.com/Aerlinger/AnsiColor.jl


## Roadmap

#### docs/examples
- [x] re-write docstrings; https://docs.julialang.org/en/v1/manual/documentation/
- [x] README generated by Term like Rich's
- [x] logo
- [x] TODO either remove text utils from API docs or avoid importing it
- [ ] docs
  - [ ] development disclaimer
  - [ ] how to contribute
  - [x] installation
  - [x] basic usage
    - [x] markup
    - [x] apply style
    - [x] macros
  - [x] colors
    - [x] allowed colors
    - [x] how to use them and exmaples
  - [x] renderabletext, textbox/panels + nesting
    - [x] segments
    - [x] measure
    - [x] panels
    - [x] textbox
  - [ ] layout
    - [ ] the idea
    - [ ] vstack vs hstack
    - [ ] nesting
    - [ ] hline
    - [ ] vLine
    - [ ] Spacer
  - [ ] inspect
  - [ ] errors
  - [ ] logging



### To do & bugs
- [ ] `highlight` sometimes doesnt apply styles correctly when >1 elements per line
- [ ] BUG: read code style from file sometimes gives the wrong line (towards end of file)
- [x] `logging` accept symbols and expressions in message
- [ ] refactor `TextBox` and `RenderableText`
- [ ] use project board
- [x] `logging` handle well multi-line messages
- [x] `tprint` should accept multiple arguments and non-string arguments
  - [x] print symbols, numbers... with style

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
