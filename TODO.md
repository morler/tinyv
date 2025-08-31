# tinyv Development To-Do List

Based on the project status and code review, here are the key areas that need work to advance the `tinyv` compiler.

## 1. Scanner / Lexer Enhancements

- [x] Implement support for string interpolation (`str_inter` token).
- [x] Add support for the `@` symbol (attributes, `at` token).
- [x] Implement support for raw strings.
- [x] Add support for rune literals (Unicode code points).
- [x] Implement support for floating-point number literals (fraction & exponent parts).
- [x] Add support for imaginary number literals.
- [x] Improve comment handling to correctly parse documentation comments (e.g., `//doc:` or `/*doc*/`).

## 2. Parser - Top-Level Declarations

- [x] Complete `const_decl` implementation: Parse and store the assigned expression value.
- [x] Complete `enum_decl` implementation: Parse and store enum fields and their potential values.
- [x] Complete `struct_decl` implementation: Parse and store struct fields, their types, mutability, and default values. Handle struct embedding.
- [x] Complete `type_decl` implementation: Correctly parse type aliases and function types.

## 3. Parser - Statements (`stmt` function)

- [x] Implement parsing for `if` statements.
- [ ] Implement parsing for `switch` statements.
- [x] Implement parsing for `match` expressions/statements (more robustly than current).
- [x] Implement parsing for `go` and `defer` statements.
- [x] Implement parsing for `asm` blocks.
- [ ] Implement parsing for labeled statements and `goto`.
- [ ] Improve error handling and reporting within the statement parsing loop.

## 4. Parser - Expressions (`expr` function)

- [ ] Finish the Pratt parsing loop to correctly handle operator precedence and associativity for all infix and postfix operators.
- [ ] Implement parsing for prefix operators (`&`, `*`, `!`, `~`, `^`).
- [ ] Implement parsing for selector expressions (`a.b`).
- [ ] Implement parsing for call expressions (`f()`).
- [ ] Implement parsing for slice expressions (`a[1..2]`).
- [ ] Implement parsing for type assertion/cast expressions (`a as Type`, `typeof(a)`).
- [ ] Implement parsing for `or` blocks (`or {}`).
- [ ] Implement parsing for `?` operator (optional propagation).
- [ ] Implement parsing for `none` literal.
- [ ] Complete `ParExpr` handling.

## 5. AST Enhancements

- [ ] Add fields to AST node structs to hold parsed information (e.g., `FnDecl` should have name, args, return types, body; `Ident` should store position).
- [ ] Implement `Arg` struct for function arguments and use it in `FnDecl`.
- [ ] Add nodes for missing statement and expression types identified during parser development.

## 6. Code Generation (Backends)

- [ ] Initiate work on the C backend.
    - [ ] Design the IR (Intermediate Representation) or directly generate C code from the AST.
    - [ ] Implement code generation for basic declarations (variables, constants).
    - [ ] Implement code generation for function definitions.
    - [ ] Implement code generation for control flow statements (`if`, `for`).
    - [ ] Implement code generation for expressions.
- [ ] Plan and potentially start work on the x64 backend.

## 7. Testing and Robustness

- [ ] Add unit tests for the scanner to verify correct tokenization of various inputs.
- [ ] Add unit tests for the parser to verify correct AST generation for various code snippets.
- [ ] Implement a basic test framework to run V code snippets through `tinyv` and check output/behavior.
- [ ] Improve error messages to be more informative (include line numbers, context).
- [ ] Add panic recovery mechanisms to prevent the compiler from crashing on invalid input.

## 8. Main Function & CLI

- [ ] Modify `main.v` to accept command-line arguments (e.g., input file path, output file path, target backend).
- [ ] Add options for different verbosity levels or output modes (e.g., print AST, print tokens).

This list provides a roadmap for advancing the `tinyv` project. Prioritization should likely follow the natural order of compiler development: solidify scanner/parser/AST, then move to code generation.