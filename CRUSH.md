# CRUSH.md - tinyv Project Guide

## Build Commands
```bash
# Build and run (main entry)
v run src/cmd/tinyv/tinyv.v

# Run with debug output
v run src/cmd/tinyv/tinyv.v --debug -d

# Run specific test file
v run src/cmd/tinyv/tinyv.v --skip-builtin --skip-imports -d test/syntax.v

# Run individual test (examples)
v run src/cmd/tinyv/tinyv.v test/generic_fn.v
v run src/cmd/tinyv/tinyv.v test/string_interpolation.v
```

## Code Style Guidelines

### Naming Conventions
- **Modules**: lowercase (e.g., `import tinyv.ast`)
- **Functions**: camelCase, pub prefix for public functions
- **Structs**: PascalCase (e.g., `struct Parser`)
- **Variables**: camelCase, mut prefix for mutable
- **Constants**: PascalCase with ALL_CAPS variants
- **Enum values**: lowercase_single_word or camelCase

### Formatting
- **Indentation**: 4 spaces (V language standard)
- **Line endings**: No semicolons after statements except in specific cases
- **Line length**: ~100 characters (flexible)
- **Braces**: Same line for functions/structs
- **Imports**: Grouped by external/internal, one per line

### Code Patterns

#### Error Handling
```v
result := os.read_file(filename) or {
    p.error('error reading ${filename}')
    return default_value
}
// or
eprintln('Error message: ${details}')
```

#### Struct Definitions
```v
pub struct Parser {
pub mut:
    config  Config
    scanner &scanner.Scanner
mut:
    line int
pub:
    file_id int = -1
}
```

#### Function Signatures
```v
pub fn new_parser(config Config) &Parser {
    return &Parser{
        config: config
    }
}

fn (mut p Parser) private_method() {
    // implementation
}
```

#### Enum Types
```v
pub enum TokenKind {
    unknown
    eof
    ident
    number
}
```

### Best Practices
- Use union types (sum types) for AST nodes: `pub type Expr = BinaryExpr | UnaryExpr | ...`
- Include copyright headers on all source files
- Use `mut` for mutable variables in function parameters
- Prefer `or { panic/error }` for error handling
- Use short variable names for common structs (p for Parser, b for Builder)
- Comment complex logic but avoid redundant comments
- Use `pub mut:` / `mut:` / `pub:` consistently in structs
- Prefer early returns in functions
- Use unsafe blocks sparingly for performance-critical sections

### Testing
- Individual tests: Run compiler against test files
- Main syntax test: `test/syntax.v`
- Specialized tests: `test/generic_*.v`, `test/string_interpolation.v`
- Debug test output: Use `--debug` flag for verbose logging

### Architecture Notes
- Modular design: scanner → parser → AST → builder → IR
- Parallel parsing enabled by default (use `--no-parallel` to disable)
- Performance timing built-in for each compilation stage
- Copyright notices required on all source files