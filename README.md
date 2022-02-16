# TODO
- [x] get plain text for Measure
  - [x] remove markup
  - [ ] remove ansi | only if needed
  
- [x] regex markup extraction
  - [x] deal with no or minmal closings
  - [x] test

- [x] color: test detection
  - [x] print all named colors
  - [x] test
  - [x] hex -> rgb

- [x] markup -> ansi substitution, modular
  - [x] detect style
  - [x] inject style
    - [x] all colors
  - [ ] fix bug with nested tags
  
- [x] segment
  - [x] base
  - [x] from string + style
  - [x] from string + markup

- [ ] tests
  - [ ] check that Measure is correct for all types of segment, segments, renderable...
  - [ ] also check results make sense when concatenating them

## Roadmap
- [ ] macros for styling a string
- [ ] box
- [ ] panel
  - [ ] panel subtitle
- [ ] inspect
- [ ] latex->unicode parsing (https://github.com/phfaist/pylatexenc)
- [ ] markdown parsing
- [ ] Line divider thingy

## BUGS
- [ ] nested tags, outer's color/bg not correctly restored