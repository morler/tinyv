module ast

import token

// pub type Decl = ConstDecl | EnumDecl | StructDecl
pub type Expr = ArrayInit | BoolLiteral | Cast | CharLiteral | Ident | If | Index
	| Infix | List | Match | NumberLiteral | ParExpr | Prefix | Selector | StringLiteral
	| StructInit
pub type Stmt =  Assign | Block | ConstDecl | EnumDecl | ExprStmt | FlowControl | FnDecl
	| For | Go | Defer | Asm | Goto | LabeledStmt | Import | Module | Return | StructDecl | TypeDecl

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
	stmts []Stmt
}

pub struct BoolLiteral {
	val bool
}

pub struct Cast {
	expr Expr
}

pub struct CharLiteral {
pub:
	value string
}

pub struct ConstDecl {
	is_public bool
	fields []ConstField
}

pub struct ConstField {
	name string
	expr Expr
}

pub struct EnumDecl {
	is_public bool
	name string
	fields []EnumField
}

pub struct EnumField {
	name string
	val ?Expr
}

pub struct ExprStmt {
	
}

pub struct FnDecl {
	
}

pub struct FlowControl {
	op token.Token
}

pub struct For {
	
}

pub struct Ident {
pub:
	name   string
	is_mut bool
}

pub struct If {

}

pub struct Infix {

}

pub struct List {
pub:
	exprs []Expr
}

pub struct Import {

}

pub struct Index {
	lhs Expr
}

pub struct Match {
	expr Expr
	cases []MatchCase
	else_stmts []Stmt
}

pub struct Module {
pub:
	name string
}

pub struct NumberLiteral {
pub:
	value string
}

pub struct ParExpr {

}

pub struct Prefix {

}

pub struct Return {

}

pub struct Selector {
	lhs Expr
	rhs Expr
}

pub struct StringLiteral {
	value string
}

pub struct StructDecl {
	is_public bool
	name string
	fields []StructField
}

pub struct StructField {
	is_pub bool
	is_mut bool
	name string
	is_embed bool
	typ Expr
	default_val ?Expr
}

pub struct StructInit {
	
}

pub struct Go {
	stmt Stmt
}

pub struct Defer {
	stmt Stmt
}

pub struct Asm {
	body string
}

pub struct Goto {
	label string
}

pub struct LabeledStmt {
	label string
	stmt Stmt
}

