# AGENTS.md - tinyv Development Guide

## Build/Run Commands
- **Run compiler**: `v run src/cmd/tinyv/tinyv.v --skip-builtin --skip-imports test/syntax.v`
- **Debug mode**: Add `-d` or `--debug` flag
- **Skip codegen**: Add `--skip-genv` flag
- **Disable parallel**: Add `--no-parallel` flag

## Project Structure
- `src/cmd/tinyv/`: Main entry point
- `src/tinyv/`: Core compiler modules
- `test/`: Test files (.v extension)

## Code Style Guidelines
- **Module imports**: Group standard lib first, then project modules
- **Error handling**: Use `errors.error()` with position and details
- **Naming**: snake_case for functions/vars, PascalCase for types
- **Types**: Use V's sum types for AST nodes
- **Formatting**: Follow V fmt conventions for indentation
- **Comments**: Use V-style `//` comments, avoid unnecessary docs

## Testing
- Tests are .v files in `test/` directory
- Run individual test: `v run src/cmd/tinyv/tinyv.v test/filename.v`
- Test files should contain valid V syntax for parsing

## Key Conventions
- Prefer `mut` keyword for mutable variables
- Use V's built-in types (string, int, bool, etc.)
- Error messages include position information
- AST nodes use union types with proper type safety