# tinyv Project Context

## Project Overview

This project, `tinyv`, is a research-oriented, simplified compiler for the V programming language. It is not intended to be a full replacement for the official V compiler, but rather a minimalistic implementation to explore compiler design concepts and potentially contribute ideas back to the main project. The goal is to achieve a high percentage of V's features (targeting the high 90s) while keeping the codebase simple and small.

The project is structured in typical compiler phases:
1.  **Scanner/Lexer (`scanner` module):** Tokenizes the input V source code. This stage is reported as almost complete.
2.  **Parser (`parser` module):** Parses the token stream into an Abstract Syntax Tree (AST). This stage is working but incomplete, with many stub methods and nodes.
3.  **AST (`ast` module):** Defines the data structures representing the parsed code.
4.  **Code Generation (Backends):** Planned stages for generating executable code (e.g., x64 assembly, C code). These are not yet started.

## Key Components

*   **`main.v`**: The entry point of the application. It demonstrates the current functionality by reading a V source file, running the scanner, and then the parser, printing timing information.
*   **`scanner/scanner.v`**: Implements the lexical analysis. It identifies and categorizes tokens like keywords, identifiers, numbers, strings, and operators.
*   **`parser/parser.v`**: Implements the syntactic analysis. It consumes tokens from the scanner and constructs an AST. It handles various V constructs like functions, structs, constants, imports, modules, expressions, and statements.
*   **`token/token.v`**: Defines the `Token` enum for all possible tokens and provides utility functions like binding power for Pratt parsing of expressions.
*   **`ast/ast.v`**: Defines the structs for different types of AST nodes (e.g., `Ident`, `NumberLiteral`, `FnDecl`, `Assign`).

## Building and Running

As this is a V project, it is built and run using the V compiler.

1.  Ensure you have the V compiler installed.
2.  Navigate to the project root directory (`D:\Code\MyProject\V\tinyv`).
3.  Compile the project: `v .` (This will produce an executable, likely `tinyv.exe` on Windows).
4.  Run the executable: `./tinyv.exe` (or just `tinyv` on Unix-like systems, if configured). The `main.v` file currently hardcodes the path to a V source file to parse.

*Note: Specific build scripts or configurations beyond the standard V build process have not been identified in the explored files.*

## Development Conventions

Based on the code inspected, the following conventions appear to be used:

*   **Language:** V.
*   **Naming:** V-style naming conventions are used (e.g., `snake_case` for functions/variables, `PascalCase` for structs).
*   **Structure:** Code is organized into modules (directories) representing logical components (scanner, parser, ast).
*   **Public API:** Functions and fields intended for use outside their module are prefixed with `pub`.
*   **Mutability:** Explicit use of `mut` keyword for mutable references.
*   **Error Handling:** Uses `or { ... }` blocks for error handling, typical in V.
*   **Pratt Parsing:** The parser uses Pratt parsing techniques for handling operator precedence in expressions, as indicated by `left_binding_power` in `token.v` and the expression parsing loop in `parser.v`.

This context provides a foundational understanding for interacting with and contributing to the `tinyv` project.