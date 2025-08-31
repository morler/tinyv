// Copyright (c) 2020-2023 Joe Conigliaro. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ssa

import tinyv.ast

struct Builder {
mut:
	current_fn &Function
	current_bb &BasicBlock
	}
}

// New expression handlers
fn (mut b Builder) index_expr(expr ast.IndexExpr) Value {
	// Evaluate base expression and index
	base := b.expr(expr.left)
	index := b.expr(expr.index)

	// TODO: Implement proper array indexing instruction
	return Value(None(0))
}

fn (mut b Builder) selector_expr(expr ast.SelectorExpr) Value {
	// Evaluate left expression
	left := b.expr(expr.expr)

	// TODO: Implement proper field selection instruction
	return Value(None(0))
}

fn (mut b Builder) if_expr_val(expr ast.IfExpr) Value {
	// TODO: Implement if expression value evaluation
	b.current_bb = b.add_basic_block('if.expr')
	// Handle condition and both branches, returning a phi value
	cond := b.expr(expr.cond)

	// For now, just evaluate the main expression
	true_val := b.expr(expr.stmt)

	return true_val
}

fn (mut b Builder) array_init_expr(expr ast.ArrayInitExpr) Value {
	// Evaluate array elements
	mut elements := []Value{}
	for elem in expr.exprs {
		elements << b.expr(elem)
	}

	// TODO: Implement array initialization instruction
	return Value(None(0))
}

fn (mut b Builder) map_init_expr(expr ast.MapInitExpr) Value {
	// Evaluate map keys and values
	mut keys := []Value{}
	mut values := []Value{}

	for i in 0 .. expr.keys.len {
		keys << b.expr(expr.keys[i])
		values << b.expr(expr.vals[i])
	}

	// TODO: Implement map initialization instruction
	return Value(None(0))
}

fn (mut b Builder) paren_expr(expr ast.ParenExpr) Value {
	// Parenthesized expressions evaluate to the inner expression
	return b.expr(expr.expr)
}


	fn (b Builder) expr(expr ast.Expr) Value {
	match expr {
		ast.CallExpr {
			// Handle function call expressions
			unsafe {
				mut b_mut := b
				return b_mut.call_expr(expr)
			}
		}
		ast.BasicLit {
			// Handle literal constants
			unsafe {
				mut b_mut := b
				return b_mut.basic_lit(expr)
			}
		}
		ast.Ident {
			// Handle identifier/variable references
			unsafe {
				mut b_mut := b
				return b_mut.ident_expr(expr)
			}
		}
		ast.BinaryExpr {
			// Handle binary operations
			unsafe {
				mut b_mut := b
				return b_mut.binary_expr(expr)
			}
		}
		ast.UnaryExpr {
			// Handle unary operations
			unsafe {
				mut b_mut := b
				return b_mut.unary_expr(expr)
			}
		}
		ast.SoLit {  // Slice literal
			unsafe {
				mut b_mut := b
				return b_mut.slice_literal(expr)
			}
		}
		ast.StructLit {  // Struct literal
			unsafe {
				mut b_mut := b
				return b_mut.struct_literal(expr)
			}
		}
		ast.IndexExpr {
			// Handle array/slice indexing
			unsafe {
				mut b_mut := b
				return b_mut.index_expr(expr)
			}
		}
		ast.SelectorExpr {
			// Handle field selection
			unsafe {
				mut b_mut := b
				return b_mut.selector_expr(expr)
			}
		}
		ast.IfExpr {
			// Handle conditional expressions
			unsafe {
				mut b_mut := b
				return b_mut.if_expr_val(expr)
			}
		}
		ast.ArrayInitExpr {
			// Handle array initialization
			unsafe {
				mut b_mut := b
				return b_mut.array_init_expr(expr)
			}
		}
		ast.MapInitExpr {
			// Handle map initialization
			unsafe {
				mut b_mut := b
				return b_mut.map_init_expr(expr)
			}
		}
		ast.ParenExpr {
			// Handle parenthesized expressions
			unsafe {
				mut b_mut := b
				return b_mut.paren_expr(expr)
			}
		}
		ast.StringLiteral, ast.StringInterLiteral {
			// Handle string literals - convert to BasicLit format
			unsafe {
				mut b_mut := b
				return b_mut.basic_lit(ast.BasicLit{ val: '', kind: .string_ }) // TODO: extract actual string value
			}
		}
		else {
			// TODO: handle more expression types as needed (RangeExpr, CastExpr, etc.)
			return Value(None(0))
		}
	}
}

	fn (mut b Builder) stmt(stmt ast.Stmt) {
	match stmt {
		ast.ForStmt {
			b.for_stmt(stmt)
		}
		ast.IfStmt {
			b.if_stmt(stmt)
		}
		ast.ReturnStmt {
			b.return_stmt(stmt)
		}
		ast.AssignStmt {
			b.assign_stmt(stmt)
		}
		ast.ExprStmt {
			b.expr_stmt(stmt)
		}
		ast.BlockStmt {
			b.block_stmt(stmt)
		}
		ast.ImportStmt {
			// Skip import statements in SSA generation (handled at compilation time)
		}
		ast.GlobalDecl {
			b.global_decl(stmt)
		}
		ast.ConstDecl {
			b.const_decl(stmt)
		}
		ast.FnDecl {
			b.fn_decl(stmt)
		}
		ast.StructDecl {
			b.struct_decl(stmt)
		}
		else {
			// TODO: implement other statements (DeferStmt, AssertStmt, etc.)
		}
	}
}

// Implement expression handlers
fn (mut b Builder) call_expr(expr ast.CallExpr) Value {
	// Get function value
	fn_val := b.expr(expr.left)
	
	// Evaluate arguments
	mut args := []Value{}
	for arg in expr.args {
		args << b.expr(arg)
	}
	
	// Create call instruction
	call_inst := Call{
		fn: fn_val
		args: args
		is_tail: false
	}
	
	return b.current_bb.add_instruction(call_inst)
}

fn (mut b Builder) basic_lit(expr ast.BasicLit) Value {
	// Create a constant value from the literal
	// For now, just return a placeholder - proper constant handling
	// would require adding Constant instruction type to SSA module
	match expr.kind {
		.string_ {
			// String constant
			// TODO: Create proper string constant representation
			return Value(None(0))
		}
		.int_, .hexa, .octal {
			// Integer constant
			// TODO: Create proper integer constant representation
			return Value(None(0))
		}
		.float_ {
			// Float constant
			// TODO: Create proper float constant representation
			return Value(None(0))
		}
		else {
			// Other literal types (char, bool, etc.)
			return Value(None(0))
		}
	}
}

fn (mut b Builder) ident_expr(expr ast.Ident) Value {
	// Read variable from current block
	return b.current_bb.read_variable(expr.name)
}

fn (mut b Builder) binary_expr(expr ast.BinaryExpr) Value {
	// Evaluate left and right operands
	left := b.expr(expr.left)
	right := b.expr(expr.right)
	
	// Convert AST operator to SSA operator
	op := match expr.op {
		'+' { BinaryOperator.add }
		'-' { BinaryOperator.sub }
		'*' { BinaryOperator.mul }
		'/' { BinaryOperator.div }
		'%' { BinaryOperator.mod }
		'==' { BinaryOperator.eq }
		'!=' { BinaryOperator.ne }
		'<' { BinaryOperator.lt }
		'<=' { BinaryOperator.le }
		'>' { BinaryOperator.gt }
		'>=' { BinaryOperator.ge }
		'&' { BinaryOperator.and }
		'|' { BinaryOperator.or }
		'^' { BinaryOperator.xor }
		'<<' { BinaryOperator.shl }
		'>>' { BinaryOperator.shr }
		else { 
			// Default operator for unsupported ones
			BinaryOperator.eq
		}
	}
	
	// Create binary instruction
	bin_inst := BinaryOp{
		op: op
		left: left
		right: right
	}
	
	return b.current_bb.add_instruction(bin_inst)
}

fn (mut b Builder) unary_expr(expr ast.UnaryExpr) Value {
	operand := b.expr(expr.operand)
	
	op := match expr.op {
		'-' { UnaryOperator.neg }
		'-!' { UnaryOperator.not }
		'~' { UnaryOperator.compl }
		else { UnaryOperator.neg }
	}
	
	unary_inst := UnaryOp{
		op: op
		operand: operand
	}
	
	return b.current_bb.add_instruction(unary_inst)
}

fn (mut b Builder) slice_literal(expr ast.SliceLit) Value {
	// TODO: implement slice literal support
	return Value(None(0))
}

fn (mut b Builder) struct_literal(expr ast.StructLit) Value {
	// TODO: implement struct literal support  
	return Value(None(0))
}

// Statement handlers
fn (mut b Builder) if_stmt(stmt ast.IfStmt) Value {
	// Create basic blocks
	true_bb := b.add_basic_block('if.true')
	mut false_bb := b.add_basic_block('if.false')
	merge_bb := b.add_basic_block('if.merge')
	
	if stmt.elses.len == 0 {
		// No else branch
		false_bb = merge_bb
	}
	
	// Evaluate condition
	cond := b.expr(stmt.cond)
	
	// Set terminator for current block as conditional branch
	curr_bb := b.current_bb
	unsafe {
		mut curr_bb_mut := curr_bb
		curr_bb_mut.set_terminator(IfTerminator{
			val: cond
			bb_true: true_bb
			bb_false: false_bb
		})
	}
	
	// Handle then branch
	b.current_bb = true_bb
	for st in stmt.stmts {
		b.stmt(st)
	}
	// Branch to merge
	unsafe {
		mut true_bb_mut := true_bb
		true_bb_mut.set_terminator(BranchTerminator{ bb: merge_bb })
	}
	
	// Handle else branch if present
	if stmt.elses.len > 0 {
		b.current_bb = false_bb
		for st in stmt.elses {
			b.stmt(st)
		}
		unsafe {
			mut false_bb_mut := false_bb
			false_bb_mut.set_terminator(BranchTerminator{ bb: merge_bb })
		}
	}
	
	// Switch to merge block
	b.current_bb = merge_bb
	
	return Value(None(0)) // If statement doesn't return a value
}

fn (mut b Builder) return_stmt(stmt ast.ReturnStmt) Value {
	if stmt.exprs.len > 0 {
		// Evaluate return value
		ret_val := b.expr(stmt.exprs[0])
		
		// Create return terminator
		b.current_bb.set_terminator(ReturnTerminator{})
		
		return ret_val
	} else {
		// Void return
		b.current_bb.set_terminator(ReturnTerminator{})
		return Value(None(0))
	}
}

fn (mut b Builder) assign_stmt(stmt ast.AssignStmt) Value {
	if stmt.left.len == 1 && stmt.right.len == 1 {
		// Simple assignment
		rhs := b.expr(stmt.right[0])
		left_ident := stmt.left[0]
		
		if left_ident is ast.Ident {
			// Store variable assignment
			var_name := left_ident.name
			mut curr_bb := b.current_bb
			curr_bb.write_variable(var_name, rhs)
		}
	}
	
	return Value(None(0)) // Assignment doesn't return a value
}

// New statement handlers
fn (mut b Builder) expr_stmt(stmt ast.ExprStmt) Value {
	// Evaluate the expression
	return b.expr(stmt.expr)
}

fn (mut b Builder) block_stmt(stmt ast.BlockStmt) Value {
	// Process all statements in the block
	for st in stmt.stmts {
		b.stmt(st)
	}
	return Value(None(0))
}

fn (mut b Builder) global_decl(stmt ast.GlobalDecl) Value {
	// TODO: Handle global variable declarations
	for spec in stmt.specs {
		if spec is ast.ValueSpec {
			for name in spec.names {
				// Add global variable to symbol table
				// This is typically handled at a higher level
			}
		}
	}
	return Value(None(0))
}

fn (mut b Builder) const_decl(stmt ast.ConstDecl) Value {
	// TODO: Handle constant declarations
	for spec in stmt.specs {
		if spec is ast.ValueSpec {
			// Constants don't need SSA variables, just compile-time evaluation
			for i, name in spec.names {
				if i < spec.values.len {
					// Evaluate constant value once during compilation
					_ := b.expr(spec.values[i])
	}
}

// Composite literal handlers
fn (mut b Builder) slice_literal(expr ast.SoLit) Value {
	// Handle slice literal expressions (e.g., [1, 2, 3])
	mut elements := []Value{}
	for elem in expr.exprs {
		elements << b.expr(elem)
	}

	// TODO: Create proper slice initialization instruction
	// For now, this could be represented as an array with dynamic size
	return Value(None(0))
}

fn (mut b Builder) struct_literal(expr ast.StructLit) Value {
	// Handle struct literal expressions (e.g., User{name: "John", age: 30})
	mut field_values := []Value{}

	// Evaluate field values if present
	if expr.fields.len > 0 {
		for field in expr.fields {
			if field.value !is ast.EmptyExpr {
				field_values << b.expr(field.value)
			}
		}
	} else if expr.exprs.len > 0 {
		// Handle positional initialization
		for elem in expr.exprs {
			field_values << b.expr(elem)
		}
	}

	// TODO: Create proper struct initialization instruction
	// This would need field information and proper ordering
	return Value(None(0))
}

// New expression handlers I added earlier
fn (mut b Builder) index_expr(expr ast.IndexExpr) Value {
	// Evaluate base expression and index
	base := b.expr(expr.left)
	index := b.expr(expr.index)

	// TODO: Implement proper array indexing instruction
	return Value(None(0))
}

fn (mut b Builder) selector_expr(expr ast.SelectorExpr) Value {
	// Evaluate left expression
	left := b.expr(expr.expr)

	// TODO: Implement proper field selection instruction
	return Value(None(0))
}

fn (mut b Builder) if_expr_val(expr ast.IfExpr) Value {
	// TODO: Implement if expression value evaluation
	b.current_bb = b.add_basic_block('if.expr')
	// Handle condition and both branches, returning a phi value
	cond := b.expr(expr.cond)

	// For now, just evaluate the main expression
	true_val := b.expr(expr.stmt)

	return true_val
}

fn (mut b Builder) array_init_expr(expr ast.ArrayInitExpr) Value {
	// Evaluate array elements
	mut elements := []Value{}
	for elem in expr.exprs {
		elements << b.expr(elem)
	}

	// TODO: Implement array initialization instruction
	return Value(None(0))
}

fn (mut b Builder) map_init_expr(expr ast.MapInitExpr) Value {
	// Evaluate map keys and values
	mut keys := []Value{}
	mut values := []Value{}

	for i in 0 .. expr.keys.len {
		keys << b.expr(expr.keys[i])
		values << b.expr(expr.vals[i])
	}

	// TODO: Implement map initialization instruction
	return Value(None(0))
}

fn (mut b Builder) paren_expr(expr ast.ParenExpr) Value {
	// Parenthesized expressions evaluate to the inner expression
	return b.expr(expr.expr)
}

		}
	}
	return Value(None(0))
}

fn (mut b Builder) fn_decl(stmt ast.FnDecl) Value {
	// TODO: Handle function declarations
	// This typically creates a new function in the module
	return Value(None(0))
}

fn (mut b Builder) struct_decl(stmt ast.StructDecl) Value {
	// TODO: Handle struct type declarations
	// This is typically handled during type checking
	return Value(None(0))
}

fn (mut b Builder) if_expr(if_expr ast.IfExpr) {
	if_bb := b.add_basic_block('if')
	else_bb := b.add_basic_block('if.else')
	endif_bb := b.add_basic_block('if.endif')
	// TODO: implement if expression handling
	_ = if_bb
	_ = else_bb 
	_ = endif_bb
}

fn (mut b Builder) for_stmt(stmt ast.ForStmt) {
	mut bb_body := b.add_basic_block('for.body')
	mut bb_done := b.add_basic_block('for.done')

	mut bb_loop := bb_body
	if stmt.cond !is ast.EmptyExpr {
		bb_loop = b.add_basic_block('for.loop')
	}
	mut bb_cont := bb_loop
	if stmt.post !is ast.EmptyStmt {
		bb_cont = b.add_basic_block('for.post')
	}

	// Set branch from body to loop header  
	unsafe {
		mut bb_body_mut := bb_body
		bb_body_mut.set_terminator(BranchTerminator{ bb: bb_loop })

		if stmt.cond !is ast.EmptyExpr {
			// Handle condition: branch to body if true, done if false
			cond := b.expr(stmt.cond)
			mut bb_loop_mut := bb_loop
			bb_loop_mut.set_terminator(IfTerminator{ val: cond, bb_true: bb_body, bb_false: bb_done })
		}

		if stmt.post !is ast.EmptyStmt {
			// TODO: process post increment/decrement statement
			// b.stmt(stmt.post)
			mut bb_cont_mut := bb_cont
			bb_cont_mut.set_terminator(BranchTerminator{ bb: bb_loop })
		}
	}
}
