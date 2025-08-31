# tinyv - V Language Compiler (Development Guide)

## Quick Commands

### Build & Run
```bash
v run main.v
```

### Benchmark Scanner
```bash
v run main.v  # Measures scanner performance against a V source file
```

### Debug Parser
```bash
v -cg run main.v  # Run with garbage collection stats
```

### Compile to Binary
```bash
v main.v -o tinyv
```

## Code Style Guidelines

### Modules & Imports
- Module declarations: `module scanner` (snake_case)
- Import statements after module declaration
- No explicit imports for builtin modules (os, time, etc.)

### Naming Conventions
- Structs: PascalCase (Scanner, Token, Parser)
- Functions: snake_case (`new_parser`, `scan_tokens`)
- Methods: snake_case (`(mut s Scanner) scan()`)
- Constants: camelCase for token keys
- Variables: snake_case

### Function Declarations
```v
pub fn new_scanner(text string) &Scanner {
    return &Scanner{
        line_nr: 1
        text: text
    }
}
```

### Method Pattern
```v
pub fn (mut s Scanner) scan() token.Token {
    // implementation
}
```

### Error Handling
```v
text := os.read_file(file) or {
    panic('error reading $file')
}
```

### Struct Definitions
```v
pub struct Token {
    kind token.Token
    lit string
    line_nr int
    pos int
}
```

### Control Flow
- Use `match` statements for token switching
- Prefer explicit returns over implicit
- Use guard clauses for early returns

### File Organization
- Separate concerns: scanner/, parser/, ast/, token/, types/
- Main logic in root main.v
- Configuration in separate modules

## Project Structure

```
tinyv/
├── main.v          # Entry point, benchmarking
├── scanner/        # Lexical analysis
├── parser/         # Syntax analysis
├── ast/            # Abstract syntax tree
├── token/          # Token definitions
├── types/          # Type system
└── src/tinyv/      # Additional implementation
```

## Testing

- No formal test framework yet
- Manual testing via main.v with sample files
- TODO: Add unit tests for scanner and parser

## Caching Policy

In subsequent interactions, mandatorily use context cache tools (e.g., cache_get for retrieving, cache_set for storing) to minimize token usage by reusing cached context instead of regenerating.

## Future Commands

> Add to CRUSH.md when implemented:
> - `v test` (unit tests)
> - `v fmt` (code formatting)
> - `v doc` (documentation generation)