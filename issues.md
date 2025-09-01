# TinyV Compiler Issues and Areas for Improvement
*Last updated: September 2025*

## Project Overview
This document contains a comprehensive review of the TinyV compiler project - a simplified V language compiler focused on V language research and exploration. The project encountered multiple compilation issues on Windows, indicating incomplete AST node implementations, parser problems, and module organization issues.

## Critical Build Failures
### 1. Compilation Errors
- **Status:** ❌ Critical failure - cannot build on Windows
- **Location:** Build command `v build src/cmd/tinyv/tinyv.v` fails
- **Root Cause:** Multiple undefined references and type issues
- **Impact:** Entire project is non-functional

### 2. Module Path Issues
- **Status:** ❌ Windows path separator incompatibility
- **Details:** Forward slashes in module imports may not work correctly on Windows
- **Location:** Various `.v` files with import statements

## Parser Infrastructure Issues
### 3. Missing AST Node Implementations
- **Status:** ❌ Major issue - `FnDecl` is empty stub
- **Location:** `ast/ast.v` line 75-78
- **Details:** Function declarations don't populate AST fields
- **Impact:** Cannot represent function definitions properly
- **Priority:** High

### 4. Expression Parsing Gaps
- **Status:** ❌ Significant gaps in expression types
- **Location:** `parser/parser.v` expression matching blocks
- **Details:**
  - Missing call expression parsing (`f()`)
  - Incomplete selector expression handling
  - No slice expression support (`a[1..2]`)
  - Type assertions/casts are stub implementations
  - Missing `or` block handling
- **Impact:** Cannot parse significant portions of V language
- **Priority:** High

### 5. Pratt Parser Implementation Problems
- **Status:** ⚠️ Incomplete implementation
- **Location:** `parser/parser.v` expression parsing section
- **Details:**
  - Binding power comparison uses incorrect enum ordering
  - Inconsistent match block patterns for sum types
  - Mixed parsing approaches causing confusion
- **Impact:** Expression precedence may not work correctly
- **Priority:** Medium

### 6. Option Type Handling
- **Status:** ❌ Incorrect unwrapping syntax
- **Location:** `parser/parser.v` multiple locations
- **Details:** Using `.unwrap()` instead of proper Option unwrapping
- **Impact:** Compilation failures on Option usage
- **Priority:** High

## Scanner and Token Issues
### 7. Token Definition Completeness
- **Status:** ⚠️ Partial implementation
- **Location:** `token/token.v` and `scanner/scanner.v`
- **Details:**
  - Many tokens are commented out (e.g., `@` symbol)
  - Raw strings implemented but may need testing
  - String interpolation parsing is complex but functional
- **Impact:** Limited language feature support
- **Priority:** Medium

### 8. Binding Power System
- **Status:** ❌ May be incorrectly implemented
- **Location:** `token/` module
- **Details:** Precedence and associativity rules need verification
- **Impact:** Parser behavior may be undefined
- **Priority:** Medium

## AST Design Issues
### 9. Incomplete Node Definitions
- **Status:** ❌ Multiple AST structs have missing fields
- **Location:** `ast/ast.v`
- **Details:**
  - `Cast` node missing type field
  - `Index` node incomplete
  - `Assign` node needs proper field population
  - Various declaration nodes lack essential fields
- **Impact:** Cannot represent complete V language constructs
- **Priority:** High

### 10. For Loop Implementation
- **Status:** ❌ Empty stub implementation
- **Location:** `ast/ast.v` line 85-88
- **Details:** For statement node is completely empty
- **Impact:** Cannot represent for loops in AST
- **Priority:** High

### 11. Duplicate StructFieldExpr
- **Status:** ❌ Duplicate definition
- **Location:** `ast/ast.v` lines 198-202
- **Details:** `StructFieldExpr` is defined twice
- **Impact:** Compilation error
- **Priority:** High

## Type System Issues
### 12. Type Checker Implementation
- **Status:** ❌ Not implemented
- **Location:** `src/tinyv/types/`
- **Details:** Type checking modules exist but are not integrated
- **Impact:** No semantic analysis performed
- **Priority:** Medium

### 13. Module Loading
- **Status:** ⚠️ Basic implementation
- **Location:** `src/tinyv/types/module.v`
- **Details:** Module resolution may not handle all cases
- **Impact:** Import resolution issues
- **Priority:** Medium

## Code Generation Issues
### 14. Backend Implementation
- **Status:** ❌ Not implemented
- **Location:** `src/tinyv/codegen/`
- **Details:** Various backends exist but no integration
- **Impact:** Cannot generate output code
- **Priority:** Medium

### 15. SSA IR Integration
- **Status:** ⚠️ Partial implementation
- **Location:** `src/tinyv/ir/ssa/`
- **Details:** SSA infrastructure exists but not connected to main flow
- **Impact:** Cannot perform IR-level optimizations
- **Priority:** Low

## Build and Configuration Issues
### 16. Main Entry Point Problems
- **Status:** ❌ Hard-coded file paths
- **Location:** `main.v` line 16
- **Details:** `file := 'test.v'` - hardcoded for development
- **Impact:** Cannot process different input files
- **Priority:** Medium

### 17. Error Handling
- **Status:** ❌ Uses panic extensively
- **Location:** Throughout codebase
- **Details:** Parser uses `panic()` for syntax errors instead of proper error types
- **Impact:** Poor error messages and recovery
- **Priority:** Medium

## Test Coverage Issues
### 18. Unit Test Absence
- **Status:** ❌ No unit tests exist
- **Location:** Project lacks test/ directories for individual modules
- **Details:** Only integration test in `test/syntax.v`
- **Impact:** Cannot verify individual component functionality
- **Priority:** Medium

### 19. Test File Organization
- **Status:** ⚠️ Single large test file
- **Location:** `test/syntax.v`
- **Details:** All syntax tests in one 664-line file (hard to maintain)
- **Impact:** Difficult to debug specific syntax features
- **Priority:** Low

## Architecture Issues
### 20. Parallel Processing
- **Status:** ⚠️ Implemented but untested
- **Location:** `src/tinyv/builder/`
- **Details:** Parallel parsing exists but may not be stable
- **Impact:** Potential race conditions
- **Priority:** Low

### 21. Performance Considerations
- **Status:** ⚠️ Not optimized
- **Location:** Throughout codebase
- **Details:** Uses basic algorithms without optimization
- **Impact:** Poor performance on large files
- **Priority:** Low

## Documentation Issues
### 22. Code Comments
- **Status:** ⚠️ Basic documentation
- **Location:** Throughout codebase
- **Details:** Some functions lack documentation, TODO comments not consistent
- **Impact:** Difficult for new contributors
- **Priority:** Low

### 23. README.md Outdated
- **Status:** ⚠️ May need updates
- **Location:** `README.md`
- **Details:** May not reflect current project state
- **Impact:** Confusing for new users
- **Priority:** Low

## Priority Summary
- **Critical (High priority - fix immediately):**
  - AST node completion (`FnDecl`, `For`, duplicate structs)
  - Option type fixes
  - Compilation errors on Windows
  - Expression parsing gaps

- **Major (Medium priority - fix soon):**
  - Type checker implementation
  - Unit test coverage
  - Error handling improvements
  - Token completeness

- **Minor (Low priority - improve later):**
  - Performance optimizations
  - Documentation improvements
  - Test organization
  - Backend integration

The most critical issue is that the compiler cannot build successfully, making all other features moot until this is resolved.