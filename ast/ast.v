module ast

import token

// pub type Decl = ConstDecl | EnumDecl | StructDecl
pub type Expr = ArrayInit | BoolLiteral | Cast | CharLiteral | Ident | If | Index
	| Infix | List | Match | NumberLiteral | ParExpr | Postfix | Prefix | Selector | StringLiteral
	| StructInit
pub type Stmt =  Assign | Block | ConstDecl | EnumDecl | ExprStmt | FlowControl | FnDecl
	| For | Go | Defer | Asm | Goto | LabeledStmt | Import | Module | Return | StructDecl | Switch | TypeDecl | If

pub struct ArrayInit {
pub:
	exprs []Expr
}

pub struct Assign {
pub:
	op  token.Token
	lhs []Expr
	rhs []Expr
}

pub struct Block {
pub:
	stmts []Stmt
}

pub struct BoolLiteral {
pub:
	val bool
}

pub struct Cast {
pub:
	expr Expr
	// typ: // TODO: Add type field
}

pub struct CharLiteral {
pub:
	value string
}

pub struct ConstDecl {
pub:
	is_public bool
	fields []ConstField
}

pub struct ConstField {
pub:
	name string
	expr Expr
}

pub struct EnumDecl {
pub:
	is_public bool
	name string
	fields []EnumField
}

pub struct EnumField {
pub:
	name string
	val ?Expr
}

pub struct ExprStmt {
pub:
	expr Expr
}

pub struct FnDecl {
pub:
	// TODO: Add fields for name, args, return types, body
}

pub struct FlowControl {
pub:
	op token.Token
}

pub struct For {
pub:
	// TODO: Add fields
}

pub struct Ident {
pub:
	name   string
	is_mut bool
}

pub struct If {
pub:
	cond Expr
	then_stmts []Stmt
	else_stmts []Stmt
}

pub struct Infix {
pub:
	lhs Expr
	op  token.Token
	rhs Expr
}

pub struct List {
pub:
	exprs []Expr
}

pub struct Import {
pub:
	path string // TODO: Populate this field in parser
}

pub struct Index {
pub:
	lhs Expr
}

pub struct Match {
pub:
	expr Expr
	cases []MatchCase
	else_stmts []Stmt
}

pub struct MatchCase {
pub:
	vals []Expr
	stmts []Stmt
}

pub struct Module {
pub:
	name string // TODO: Populate this field in parser
}

pub struct NumberLiteral {
pub:
	value string
}

pub struct ParExpr {
pub:
	expr Expr // Populate the expr field
}

pub struct Prefix {
pub:
	op  token.Token
	rhs Expr
}

pub struct Postfix {
pub:
	lhs Expr
	op  token.Token
}

pub struct Return {
pub:
	exprs []Expr
}

pub struct Selector {
pub:
	lhs Expr
	rhs Expr
}

pub struct StringLiteral {
pub:
	value string
}

pub struct StructDecl {
pub:
	is_public bool
	name string
	fields []StructField
}

pub struct StructField {
pub:
	is_pub bool
	is_mut bool
	name string
	is_embed bool
	typ string
	default_val ?Expr
}

pub struct StructFieldExpr {
pub:
	name string
	expr Expr
}

pub struct StructInit {
pub:
	fields []StructFieldExpr
}

pub struct Go {
pub:
	stmt Stmt
}

pub struct Defer {
pub:
	stmt Stmt
}

pub struct Asm {
pub:
	body string
}

pub struct Goto {
pub:
	label string
}

pub struct LabeledStmt {
pub:
	label string
	stmt Stmt
}

pub struct Switch {
pub:
	cond Expr
	cases []SwitchCase
	default_stmts []Stmt
}

pub struct SwitchCase {
pub:
	vals []Expr
	stmts []Stmt
	fallthrough bool
}

pub struct TypeDecl {
pub:
	is_public bool
	name string
	expr Expr // This should likely be a more specific type for type expressions
}