module parser

import os
import ast
import scanner
import token

struct Parser {
	file_path string
mut:
	scanner   &scanner.Scanner
	tok       token.Token
	peek_tok ?token.Token
}

pub fn new_parser(file string) Parser {
	text := os.read_file(file) or {
		panic('error reading $file')
	}
	return Parser{
		file_path: file,
		scanner: scanner.new_scanner(text)
	}
}

pub fn (mut p Parser) parse() {
	p.next()
	for p.tok != .eof {
		p.top_stmt()
	}
}

pub fn (mut p Parser) top_stmt() ast.Stmt {
	// p.next()
	for {
	match p.tok {
		.key_const {
			return p.const_decl(false)
		}
		.key_enum {
			return p.enum_decl(false)
		}
		.key_fn {
			return p.fn_decl(false)
		}
		.key_import {
			p.next()
			if p.tok == .name {
				// p.next()
				println('import: $p.scanner.lit')
				p.next()
			}
			return ast.Import{

			}
		}
		.key_module {
			p.expect(.key_module)
			if p.tok == .name {
				// p.next()
				println('module: $p.scanner.lit')
				p.next()
			}
			return ast.Module{

			}
		}
		.key_pub {
			p.next()
			match p.tok {
				.key_const {
					return p.const_decl(true)
				}
				.key_enum {
					return p.enum_decl(true)
				}
				.key_fn {
					return p.fn_decl(true)
				}
				.key_struct {
					return p.struct_decl(true)
				}
				.key_type {
					return p.type_decl(true)
				}
				else {}
			}
		}
		.key_struct {
			return p.struct_decl(false)
		}
		.key_type {
			return p.type_decl(false)
		}
		.lsbr {
			// [attribute]
			p.next()
			p.expect(.name)
			p.expect(.rsbr)
			continue
		}
		else {
			
			panic('X: $p.tok')
		}
	}
	}
	p.error('unknown top stmt')
	panic('')
}

pub fn (mut p Parser) stmt() ast.Stmt {
	println('STMT: $p.tok')
	if p.tok == .name {
		label_lit := p.scanner.lit
		if p.peek() == .colon {
			p.next() // consume name (now tok = colon)
			p.next() // consume colon
			stmt := p.stmt()
			return ast.LabeledStmt{
				label: label_lit
				stmt: stmt
			}
		}
	}
	match p.tok {
		// .assign, .decl_assign {
		// 	p.next()
		// 	return ast.Assign {}
		// }
		.key_break, .key_continue {
			op := p.tok
			p.next()
			return ast.FlowControl{op: op}
		}
		.key_for {
			p.next()
			p.expr(.lowest)
			p.block()
			return ast.For{}
		}
		.key_if {
			cond := p.expr(.lowest)
			then_stmts := p.block()
			mut else_stmts := []ast.Stmt{}
			if p.tok == .key_else {
				p.next()
				if p.tok == .key_if {
					// else if
					elif := p.stmt() // recursive
					if elif is ast.If {
						else_stmts = [elif]
					}
				} else {
					// else
					else_stmts = p.block()
				}
			}
			return ast.If{
				cond: cond
				then_stmts: then_stmts
				else_stmts: else_stmts
			}
		}
		.name, .key_mut {
			lhs := p.expr_list()
			if p.tok in [.assign, .decl_assign, .plus_assign, .minus_assign] {
				op := p.tok
				p.next()
				return ast.Assign{op: op, lhs: lhs, rhs: p.expr_list()}
			}
			//panic('WHY ARE WE HERE: $p.tok - $p.scanner.line_nr')
			return ast.ExprStmt{}
		}
		// .key_match {}
		// .key_mut {
		// 	println('MUT')
		// 	p.next()
		//  // previously Same as .name, now .mut handled in expr
		//  // the ident is set to is_mut
		// }
		.key_return {
			println('ast.Return')
			p.next()
			expr := p.expr(.lowest)
			if expr is ast.List {
				println('## RETURN IS LIST')
			}
			return ast.Return{

			}
		}
		.key_switch {
			return p.parse_switch()
		}
		.key_goto {
			p.next()
			label := p.scanner.lit
			p.expect(.name)
			return ast.Goto{
				label: label
			}
		}
			.key_defer {
			p.next()
			stmts := p.block()
			return ast.Defer{
				stmt: ast.Block{ stmts: stmts }
			}
		}
		.key_go {
			p.next()
			expr := p.expr(.lowest)
			return ast.Go{
				stmt: ast.ExprStmt{ expr: expr }
			}
		}
		.key_asm {
			return p.parse_asm()
		}
	}

	// TODO
	p.error('unknown stmt: $p.tok')
	panic('')
}

pub fn (mut p Parser) expr(min_lbp token.BindingPower) ast.Expr {
	// TODO: dont return continue to pratt loop
	// TODO: fix match so it last expr can be used `x := match {...`
	println('EXPR: $p.tok - $p.scanner.line_nr')
	mut lhs := ast.Expr{}
	match p.tok {
		.chartoken {
			value := p.scanner.lit
			p.next()
			lhs = ast.CharLiteral{
				value: value
			}
		}
		// .dot {
		// 	p.next()
		// 	rhs := p.expr(.lowest)
		// 	lhs = ast.Selector{
		// 		flhs: lhs
		// 		rhs: rhs
		// 	}
		// }
		.key_if {
			println('START IF')
			p.next()
			p.expr(.lowest)
			p.expect(.lcbr)
			for p.tok != .rcbr {
				p.stmt()
			}
			p.expect(.rcbr)
			lhs = ast.If{}
			println('END IF')
		}
		// .key_mut {
		// 	// TODO: maybe this shouldnt be done like this
		// 	// or we need to save somewhere or pass
		// 	p.next()
		// 	p.expr(.lowest)
		// }
		.key_true, .key_false {
			val := if p.tok == .key_true { true } else { false }
			p.next()
			return ast.BoolLiteral{
				val: val
			}
		}
		// .lcbr {
		// 	p.next()
		// 	p.expect(.rsbr)
		// }
		.lpar {
			// ParExpr
			p.next()
			println('PAREXPR:')
			p.expr(.lowest)
			// TODO
			p.expect(.rpar)
			lhs = ast.ParExpr{

			}
		}
		.lsbr {
			p.next()
			// index
			// if lhs is ast.Selector {
				// lhs = ast.Index{
				// 	lhs: lhs
				// }
			// }
			// array init
			// else {
				// [1,2,3,4]
				line_nr := p.scanner.line_nr
				mut exprs := []ast.Expr{}
				for p.tok != .rsbr {
					println('ARRAY INIT EXPR:')
					exprs << p.expr(.lowest)
					if p.tok == .comma {
						p.next()
					}
					// p.expect(.comma)
				}
				p.expect(.rsbr)
				// []int{}
				// TODO: restructure in parts (type->init) ?? no
				if p.tok == .name && p.scanner.line_nr == line_nr {
					// typ := p.parse_type()
					p.next()
				}
				println('HERE')
				if p.tok == .lcbr {
					p.next()
					// TODO:
					p.expect(.rcbr)
				}
				lhs = ast.ArrayInit{
					exprs: exprs
				}
			// }
		}
		.key_match {
			return p.parse_match()
		}
		.key_mut, .name {
			is_mut := p.tok == .key_mut
			if is_mut {
				p.next()
			}
			name := p.scanner.lit
			p.next()
			// TODO: parse type for cast
			println('NAME: $name')
			// cast
			if p.tok == .lpar {
				p.next()
				expr := p.expr(.lowest)
				p.expect(.rpar)
				lhs = ast.Cast{
					expr: expr
					// typ: // TODO
				}
			}
			// struct init
			// TODO: replace capital check with type check OR with inside stmt init check (`for cond {` OR `if cond {`)
			else if p.tok == .lcbr && name[0].is_capital() {
				p.next()
				for p.tok != .rcbr {
					p.expr(.lowest)
					if p.tok == .comma {
						p.next()
					}
				}
				p.expect(.rcbr)
				lhs = ast.StructInit{}
			}
			// ident
			else {
				lhs = ast.Ident{
					name: name
					is_mut: is_mut
				}
			}
		}
		.number {
			value := p.scanner.lit
			println('NUMBER: $value')
			p.next()
			lhs = ast.NumberLiteral{
				value: value
			}
		}
		.string {
			value := p.scanner.lit
			p.next()
			lhs = ast.StringLiteral{
				value: value
			}
		}
		.plus_assign{
			p.error('BOO')
		}
		else {
			if p.tok.is_prefix() {
				p.next()
				p.expr(.lowest)
				return ast.Prefix{}
			}
		}
	}

	for {
		// index
		if p.tok == .lsbr {
			// lhs = p.expr(.lowest)
			p.next()
			p.expr(.lowest)
			lhs = ast.Index{
				lhs: lhs
			}
			p.expect(.rsbr)
		}
		// Selector
		else if p.tok == .dot {
			p.next()
			println('ast.Selector')
			rhs := p.expr(.lowest)
			lhs = ast.Selector{
				lhs: lhs
				rhs: rhs
			}
		}
		// expr list muti assign / return
		else if p.tok == .comma {
			p.next()
			println('ast.ExprList')
			mut exprs := []ast.Expr{}
			exprs << lhs
			for {
				exprs << p.expr(.lowest)
				if p.tok != .comma {
					break
				}
				p.next()
			}
			lhs = ast.List{
				exprs: exprs
			}
			println('LIST: $exprs.len - $p.scanner.line_nr')
		}
		// TODO: pratt loop - finish
		// println('PRATT LOOP: $p.tok - $p.scanner.line_nr')
		lbp := p.tok.left_binding_power()
		if lbp < min_lbp {
			println('breaking precedense')
			break
		}
		// p.expr(lbp)
		// TODO: use bp loop for infix & postifx instead		
		// lbp2 := p.tok.infix_bp()
		// if lbp2 < min_lbp {
		// 	break
		// }
		// p.next()
		
		if p.tok.is_infix() {
			// Save operator and consume it
			op := p.tok
			p.next()
			// Parse right-hand side with operator precedence
			rhs := p.expr(lbp)
			lhs = ast.Infix{
				lhs: lhs
				op: op
				rhs: rhs
			}
			println('INFIX: $op with precedence $lbp')
} else if p.tok.is_postfix() {
			// Save operator and consume it
			op := p.tok
			p.next()
			// Postfix operators don't need RHS
			lhs = ast.Postfix{
				lhs: lhs
				op: op
			}
			println('POSTFIX: $op')
		}
		else {
			// return lhs
			break
		}
	}
	println('returning: $p.tok')
	return lhs
}

pub fn (mut p Parser) next() {
	for {
		p.tok = if p.peek_tok != none {
			val := p.peek_tok.unwrap()
			p.peek_tok = none
			val
		} else {
			p.scanner.scan()
		}
		if p.tok != .comment {
			break
		}
	}
}

pub fn (mut p Parser) expect(tok token.Token) {
	// println('expect $tok - $p.tok')
	if tok != p.tok {
		p.error('unexpected token. expecting `$tok`, got `$p.tok`')
	}
	p.next()
}

pub fn (mut p Parser) peek() token.Token {
	if p.peek_tok == none {
		p.peek_tok = p.scanner.scan()
	}
	return p.peek_tok.unwrap()
}

pub fn (p &Parser) block() []ast.Stmt {
	mut stmts := []ast.Stmt{}
	p.expect(.lcbr)
	for p.tok != .rcbr {
		// println('BLOCK STMT START')
		stmts << p.stmt()
		// println('BLOCK STMT END')
	}
	p.expect(.rcbr)
	println('END BLOCK')
	return stmts
}

pub fn (mut p Parser) expr_list() []ast.Expr {
	expr := p.expr(.lowest)
	match expr {
		ast.List { return it.exprs }
		else { return [expr] }
	}
}

pub fn (mut p Parser) assign(lhs []ast.Expr) ast.Assign {
	// lhs := p.expr(.lowest)
	// p.expect
	return ast.Assign{}
}

pub fn (mut p Parser) const_decl(is_public bool) ast.ConstDecl {
	p.next()
	p.expect(.lpar)
	mut fields := []ast.ConstField{}
	for {
		name := p.scanner.lit
		p.expect(.name)
		println('const: $name')
		p.expect(.assign)
		expr := p.expr(.lowest)
		fields << ast.ConstField{
			name: name
			expr: expr
		}
		if p.tok == .rpar {
			break
		}
	}
	p.expect(.rpar)

	return ast.ConstDecl{
		is_public: is_public
		fields: fields
	}
}

pub fn (mut p Parser) fn_decl(is_public bool) ast.FnDecl {
	p.next()
	// method
	if p.tok == .lpar {
		p.next()
		// TODO: use parse_ident & parse_type
		// receiver := p.ident() ?
		if p.tok == .key_mut {
			p.next()
		}
		receiver := p.scanner.lit
		p.expect(.name)
		// receiver_type := p.parse_type()
		receiver_type := p.scanner.lit
		p.next()
		p.expect(.rpar)
	}
	name := p.scanner.lit
	println('FN: $name')
	p.next()

	p.fn_args()

	// TODO: parse type (multi return)
	if p.tok == .lpar {
		p.next()
		for p.tok != .rpar {
			p.expect(.name) // type
			if p.tok == .comma {
				p.next()
			}
		}
		p.expect(.rpar)
	}

	if p.tok != .lcbr {
		p.expect(.name) // return type
	}

	stmts := p.block()

	return ast.FnDecl{

	}
}

pub fn (mut p Parser) fn_args() /* []ast.Arg */ {
	p.expect(.lpar)
	for p.tok != .rpar {
		p.expect(.name) // arg
		if p.tok == .name {
			p.expect(.name) // type
		}
		if p.tok == .comma {
			// p.expect(.comma)
			p.next()
		}
	}
	p.expect(.rpar)
}

pub fn (mut p Parser) enum_decl(is_public bool) ast.EnumDecl {
	p.next()
	name := p.scanner.lit
	p.expect(.name)
	println('enum: $name')
	p.expect(.lcbr)
	mut fields := []ast.EnumField{}
	for p.tok != .rcbr {
		field_name := p.scanner.lit
		p.expect(.name)
		println('field: $field_name')
		mut val := ?ast.Expr{none}
		if p.tok == .assign {
			p.next()
			val = p.expr(.lowest)
		}
		fields << ast.EnumField{
			name: field_name
			val: val
		}
		if p.tok == .comma {
			p.next()
		}
	}
	p.expect(.rcbr)
	return ast.EnumDecl{
		is_public: is_public
		name: name
		fields: fields
	}
}

pub fn (mut p Parser) struct_decl(is_public bool) ast.StructDecl {
	p.next()
	name := p.scanner.lit
	p.expect(.name)
	println('struct: $name')
	p.expect(.lcbr)
	mut fields := []ast.StructField{}
	for {
		if p.tok == .rcbr { break }
		is_pub := p.tok == .key_pub
		if is_pub { p.next() }
		is_mut := p.tok == .key_mut
		if is_mut { p.next() }
		field_name := p.scanner.lit
		p.expect(.name)
		println('field: $field_name')
		mut typ := ''
		mut is_embed := false
		if p.tok == .name {
			// parse type
			// for now, simple string
			typ = p.scanner.lit
			p.expect(.name)
		} else {
			// embedded
			is_embed = true
			typ = field_name
		}
		mut default_val := ?ast.Expr{none}
		if p.tok == .assign {
			p.next()
			default_val = p.expr(.lowest)
		}
		fields << ast.StructField{
			is_pub: is_pub
			is_mut: is_mut
			name: field_name
			is_embed: is_embed
			typ: typ
			default_val: default_val
		}
	}
	p.expect(.rcbr)
	return ast.StructDecl{
		is_public: is_public
		name: name
		fields: fields
	}
}

pub fn (mut p Parser) type_decl(is_public bool) ast.TypeDecl {
	p.next()
	name := p.scanner.lit
	p.expect(.name)
	// sum type
	if p.tok == .eq {
		p.next()
	}
	// fn type TODO: move to parse_type (become part of alias)
	else if p.tok == .key_fn {
		p.next()
		// p.fn_decl(false)
		p.fn_args()
	}
	// alias
	// else {
	// 	alias_type := p.parse_type()
	// }
	p.next() // return type

	println('TYPE: $name')
	return ast.TypeDecl {
		is_public: is_public
		name: name
		expr: p.expr(.lowest)
	}
}

pub fn (mut p Parser) parse_switch() ast.Stmt {
	p.next() // consume 'switch'
	cond := p.expr(.lowest)
	p.expect(.lcbr)
	mut cases := []ast.SwitchCase{}
	mut default_stmts := []ast.Stmt{}
	for p.tok != .rcbr {
		if p.tok == .name && p.scanner.lit == 'case' {
			p.next()
			mut vals := []ast.Expr{}
			for {
				vals << p.expr(.lowest)
				if p.tok == .comma {
					p.next()
				} else {
					break
				}
			}
			p.expect(.colon)
			mut stmts := []ast.Stmt{}
			for p.tok != .rcbr && !(p.tok == .name && p.scanner.lit in ['case', 'default']) {
				stmts << p.stmt()
			}
			cases << ast.SwitchCase{
				vals: vals
				stmts: stmts
				fallthrough: false
			}
		} else if p.tok == .name && p.scanner.lit == 'default' {
			p.next()
			p.expect(.colon)
			for p.tok != .rcbr && !(p.tok == .name && p.scanner.lit in ['case', 'default']) {
				default_stmts << p.stmt()
			}
		} else {
			panic('Unexpected token in switch: $p.tok')
		}
	}
	p.expect(.rcbr)
	return ast.Switch{
		cond: cond
		cases: cases
		default_stmts: default_stmts
	}
}


pub fn (mut p Parser) parse_match() ast.Expr {
	p.next() // consume 'match'
	cond := p.expr(.lowest)
	p.expect(.lcbr)
	mut cases := []ast.MatchCase{}
	mut else_stmts := []ast.Stmt{}
	for p.tok != .rcbr {
		if p.tok == .name && p.scanner.lit == 'case' {
			p.next()
			mut vals := []ast.Expr{}
			for {
				vals << p.expr(.lowest)
				if p.tok == .comma {
					p.next()
				} else {
					break
				}
			}
			stmts := p.block()
			cases << ast.MatchCase{
				vals: vals
				stmts: stmts
			}
		} else if p.tok == .name && p.scanner.lit == 'else' {
			p.next()
			else_stmts = p.block()
		} else {
			panic('Unexpected token in match: $p.tok')
		}
	}
	p.expect(.rcbr)
	return ast.Match{
		expr: cond
		cases: cases
		else_stmts: else_stmts
	}
}


pub fn (mut p Parser) parse_asm() ast.Stmt {
	p.next() // consume asm
	mut body := ''
	// optionally parse arch (e.g., amd64)
	if p.tok == .name {
		p.next() // skip arch
	}
	if p.tok == .lcbr {
		p.next() // skip {
		for p.tok != .rcbr && p.tok != .eof {
			body += p.scanner.lit + ' '
			p.next()
		}
		p.expect(.rcbr)
	}
	return ast.Asm{ body: body.trim(' ') }
}

