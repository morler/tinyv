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

fn (mut b Builder) add_basic_block(name string) &BasicBlock {
	mut fn_ref := unsafe { b.current_fn }
	return fn_ref.add_basic_block('${b.current_bb.name}.${name}')
}

fn (b Builder) expr(expr ast.Expr) Value {
	match expr {
		ast.CallExpr {
			// TODO: implement call expression handling
			return Value(None(0))
		}
		else {
			// TODO: implement other expressions
			return Value(None(0))
		}
	}
}

fn (mut b Builder) stmt(stmt ast.Stmt) {
	match stmt {
		ast.ForStmt {
			b.for_stmt(stmt)
		}
		else {
			// TODO: implement other statements
		}
	}
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
