# Developer Guidelines for TinyV

## Build Commands
- Build main executable: `v src/cmd/tinyv/tinyv.v`  
- Run with flags: `v run src/cmd/tinyv/tinyv.v --skip-builtin --skip-imports -d <file>`
- Test compilation: `v build tinyv.v`

## Test Commands
- Run specific test: `v run test/syntax.v` (or any test file)
- Run scanner test: `v run main.v` (tests scanner + parser)
- Run single function: No framework, use `v run <file>.v` containing `fn test_` functions
- Performance test: Include timing with `time.ticks()` calls

## Code Style Guidelines
- **Naming:** snake_case for functions/variables (e.g. `fn test_all`, `fn run_file`); PascalCase for types/structs (e.g. `Time`, `Person`)
- **Functions:** Use `fn` keyword; parameters before return type; explicit type annotations
- **Imports:** Simple module imports like `import os`, `import tinyv.token`; group related imports
- **Error Handling:** Use V's Result (`!`) and Option (`?`) types; panic/recover for fatal errors
- **Structure:** Modular architecture with separated concerns; use sum types (e.g. `Type = Alias | Array | ...`)
- **Formatting:** Standard V indentation; functional programming style when appropriate
- **Documentation:** Use `//` comments for explanations; document complex logic and invariants

## No Cursor/Copilot Rules Found