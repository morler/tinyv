// Copyright (c) 2020-2023 Joe Conigliaro. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ssa

import tinyv.types

// To construct the SSA, we will be using the algorithm's described in:
// 1. Simple and Efficient Construction of Static Single Assignment Form
// 	  https://pp.info.uni-karlsruhe.de/uploads/publikationen/braun13cc.pdf
// SSA will be constructed directly from AST without needing an existing CFG
// We will try to employ on the fly optimization's while constructing it:
//   * Remove trivial φ functions
//   * Arithmetic simplification
//   * Common subexpression elimination
//   * Constant folding
//   * Copy propagation

// Complete instruction system
type Terminator = BranchTerminator | IfTerminator | MatchTerminator | ReturnTerminator
type Instruction = BinaryOp | UnaryOp | Call | Load | Store | Alloca | PhiInstruction | Terminator

// Unified Value type based on ref-1.v implementation
type None = u8
type Value = None | Phi | Variable

// Internal types for type checking
struct ErrorType {}
struct UnknownType {}

struct Variable {
	// TODO: Add variable metadata (name, type, etc.)
	parent &Function
	typ    types.Type
	name   string
}

struct Phi {
mut:
	block    &BasicBlock
	users    []Value
	operands []Value
}

// BasicBlock methods for predecessor/successor management
fn (mut bb BasicBlock) add_predecessor(pred &BasicBlock) {
	if !bb.predecessors.contains(pred) {
		bb.predecessors << pred
	}
}

fn (mut bb BasicBlock) remove_predecessor(pred &BasicBlock) {
	for i, p in bb.predecessors {
		if p == pred {
			bb.predecessors.delete(i)
			return
		}
	}
}

fn (mut bb BasicBlock) add_successor(succ &BasicBlock) {
	if !bb.successors.contains(succ) {
		bb.successors << succ
	}
	unsafe {
		mut succ_mut := succ
		succ_mut.add_predecessor(&bb)
	}
}

fn (bb BasicBlock) get_predecessors() []&BasicBlock {
	return bb.predecessors
}

fn (bb BasicBlock) has_predecessors() bool {
	return bb.predecessors.len > 0
}

fn (bb BasicBlock) get_predecessor_count() int {
	return bb.predecessors.len
}

fn (mut bb BasicBlock) remove_successor(succ &BasicBlock) {
	for i, s in bb.successors {
		if s == succ {
			bb.successors.delete(i)
			return
		}
	}
}

fn (bb BasicBlock) get_successors() []&BasicBlock {
	return bb.successors
}

fn (bb BasicBlock) has_successors() bool {
	return bb.successors.len > 0
}

fn (bb BasicBlock) get_successor_count() int {
	return bb.successors.len
}

fn (bb BasicBlock) is_sealed() bool {
	return bb.sealed
}

fn (mut bb BasicBlock) mark_sealed() {
	bb.sealed = true
}

// Dominance calculation methods
fn (mut f Function) compute_dominance() {
	// Initialize dominance information
	for mut bb in f.bb {
		bb.immediate_dominator = unsafe { nil }
	}
	
	// Entry block dominates itself
	if f.bb.len > 0 {
		mut entry := f.bb[0]
		entry.immediate_dominator = entry
	}
	
	// Iterative algorithm to compute immediate dominators
	mut changed := true
	for changed {
		changed = false
		for i in 1 .. f.bb.len {
			mut bb := f.bb[i]
			mut new_idom := unsafe { nil }
			
			// Find first processed predecessor
			for pred in bb.predecessors {
				if pred.immediate_dominator != unsafe { nil } {
					new_idom = pred
					break
				}
			}
			
			// Intersect with all other predecessors
			for pred in bb.predecessors {
				if pred != new_idom && pred.immediate_dominator != unsafe { nil } {
					new_idom = intersect_dominators(pred, new_idom)
				}
			}
			
			if new_idom != bb.immediate_dominator {
				bb.immediate_dominator = new_idom
				changed = true
			}
		}
	}
}

fn intersect_dominators(b1 &BasicBlock, b2 &BasicBlock) &BasicBlock {
	mut finger1 := unsafe { b1 }
	mut finger2 := unsafe { b2 }
	
	for finger1 != finger2 {
		for finger1.depth() > finger2.depth() {
			finger1 = finger1.immediate_dominator
		}
		for finger2.depth() > finger1.depth() {
			finger2 = finger2.immediate_dominator
		}
	}
	
	return finger1
}

fn (bb &BasicBlock) depth() int {
	mut depth := 0
	mut current := unsafe { bb }
	for current.immediate_dominator != unsafe { nil } && current != current.immediate_dominator {
		depth++
		current = current.immediate_dominator
	}
	return depth
}

fn (bb &BasicBlock) dominates(other &BasicBlock) bool {
	mut current := unsafe { other }
	for current != unsafe { nil } {
		if current == bb {
			return true
		}
		current = current.immediate_dominator
	}
	return false
}

// Dominance frontier calculation (simplified version)
fn (f Function) compute_dominance_frontier() {}

// Value interface methods
fn (v Value) to_string() string {
	match v {
		None { return "None" }
		Variable { return 'Variable("${v.name}")' }
		Phi { 
			mut s := "Phi(["
			for i, op in v.operands {
				if i > 0 {
					s += ", "
				}
				s += op.to_string()
			}
			s += "])@" + v.block.name
			return s
		}
	}
}

// Helper function for variable creation
fn (mut f Function) create_variable(name string, typ types.Type) &Variable {
	return &Variable{
		parent: unsafe { f }
		name: name
		typ: typ
	}
}

@[heap]
struct Function {
mut:
	bb []&BasicBlock
}

// Terminators
struct BranchTerminator {
	bb &BasicBlock
}

struct IfTerminator {
	val      Value
	bb_true  &BasicBlock
	bb_false &BasicBlock
}

struct MatchTerminator {}

struct ReturnTerminator {}

// Arithmetic and logical operations
struct BinaryOp {
mut:
	op    BinaryOperator
	left  Value
	right Value
}

struct UnaryOp {
mut:
	op   UnaryOperator
	operand Value
}

// Memory operations
struct Load {
mut:
	ptr Value
}

struct Store {
mut:
	ptr   Value
	value Value
}

struct Alloca {
	typ types.Type
}

// Phi instruction (different from Phi value)
struct PhiInstruction {
mut:
	operands []Value
	block    &BasicBlock
}

// Function call
struct Call {
mut:
	fn      Value
	args    []Value
	is_tail bool
}

// Operator types
enum BinaryOperator {
	add
	sub
	mul
	div
	mod
	eq
	ne
	lt
	le
	gt
	ge
	and
	or
	xor
	shl
	shr
}

enum UnaryOperator {
	neg
	not
	compl
}

pub struct BasicBlock {
mut:
	// Original ssa.v fields
	parent_fn    &Function
	index        int
	name         string
	instructions []Instruction
	terminator   Terminator
	
	// ref-1.v SSA algorithm fields
	predecessors    []&BasicBlock
	definitions     map[string]Value
	incomplete_phis map[string]Phi
	sealed          bool
	
	// Additional fields for complete CFG support
	immediate_dominator &BasicBlock
	successors         []&BasicBlock
}

fn add_edge(from &BasicBlock, mut to BasicBlock) {
	// from.successors << to
	// from.successor = to
	to.predecessors << from
}

fn (mut f Function) add_basic_block(name string) &BasicBlock {
	b := &BasicBlock{
		parent_fn: unsafe { f }
		index: f.bb.len
		name: name
		immediate_dominator: unsafe { nil }
	}
	f.bb << b
	return b
}

// Algorithm 1: Implementation of local value numbering
fn (mut block BasicBlock) write_variable(name string, value Value) {
	// currentDef[variable][block] = value
	block.definitions[name] = value
}

fn (mut block BasicBlock) read_variable(variable string) Value {
	// if currentDef[variable] contains block {
	// local value numbering
	// return currentDef[variable][block]
	// }
	// global value numbering
	// return read_variable_recursive(variable, block)
	// =======================
	// local value numbering
	return block.definitions[variable] or {
		// global value numbering
		block.read_variable_recursive(variable)
	}
}

// Algorithm 2: Implementation of global value numbering
fn (mut block BasicBlock) read_variable_recursive(variable string) Value {
	// if block not in sealedBlocks {
	val := if !block.sealed {
		// Incomplete CFG
		// val = new Phi(block)
		// incomplete_phis[block][variable] = val
		val0 := Phi{
			block: unsafe { &block }
		}
		block.incomplete_phis[variable] = val0
		Value(val0)
	} else if block.predecessors.len == 1 {
		// Optimize the common case of one predecessor: No phi needed
		// val = read_variable(variable, block.predecessors[0])
		block.predecessors[0].read_variable(variable)
	} else {
		// Break potential cycles with operandless phi
		// val = new Phi(block)
		mut val0 := Phi{
			block: unsafe { &block }
		}
		block.write_variable(variable, val0)
		val0.add_operands(variable)
		val0
	}
	block.write_variable(variable, val)
	return val
}

fn (mut phi Phi) add_operands(variable string) Value {
	// Determine operands from predecessors
	for mut pred in phi.block.predecessors {
		// phi.appendOperand(read_variable(variable, pred))
		phi.operands << pred.read_variable(variable)
	}
	return try_remove_trivial_phi(phi)
}

// Algorithm 3: Detect and recursively remove a trivial φ function
fn try_remove_trivial_phi(phi Phi) Value {
	mut same := Value(None(0))
	for op in phi.operands {
		// if op == same || op == phi {
		// 	continue // Unique value or self−reference
		// }
		if op == same {
			continue // Unique value or self−reference
		}
		if op is Phi {
			if op == phi {
				continue
			}
		}
		if same !is None {
			return phi // The phi merges at least two values: not trivial
		}
		same = op
	}
	if same is None {
		// same = Undef() // The phi is unreachable or in the start block
		// TODO:
	}
	// users = phi.users.remove(phi) // Remember all users except the phi itself
	mut users := []Value{}
	for user in phi.users {
		match user {
			Phi {
				if user != phi {
					users << user
				}
			}
			else {
				users << user
			}
		}
	}
	// phi.replaceBy(same) // Reroute all uses of phi to same and remove phi
	// Try to recursively remove all phi users, which might have become trivial
	for use in users {
		if use is Phi {
			try_remove_trivial_phi(use)
		}
	}
	return same
}

// Algorithm 4: Handling incomplete CFGs
fn (mut block BasicBlock) seal() {
	// for variable in incomplete_phis[block] {
	for variable, phi in block.incomplete_phis {
		// add_phi_operands(variable, incomplete_phis[block][variable])
		mut phi_mut := phi
		phi_mut.add_operands(variable)
	}
	// sealedBlocks.add(block)
	block.sealed = true
}

fn (mut bb BasicBlock) add_instruction(inst Instruction) Value {
	// inst.set_block(bb) // TODO: implement set_block method for Instruction
	bb.instructions << inst
	// return inst.value() // TODO: implement value method for Instruction
	return Value(None(0)) // placeholder
}

fn (mut bb BasicBlock) set_terminator(inst Terminator) Value {
	bb.terminator = inst
	return bb.add_instruction(inst)
}

// Instruction interface methods
fn (inst Instruction) get_operands() []Value {
	match inst {
		BinaryOp { return [inst.left, inst.right] }
		UnaryOp { return [inst.operand] }
		Load { return [inst.ptr] }
		Store { return [inst.ptr, inst.value] }
		Alloca { return [] }
		PhiInstruction { return inst.operands }
		Call { 
			mut result := [inst.fn]
			result << inst.args
			return result
		}
		Terminator { 
			match inst {
				BranchTerminator { return [] }
				IfTerminator { return [inst.val] }
				MatchTerminator { return [] }
				ReturnTerminator { return [] }
			}
		}
	}
}

fn (mut inst Instruction) set_operands(operands []Value) {
	match mut inst {
		BinaryOp { 
			if operands.len == 2 {
				inst.left = operands[0]
				inst.right = operands[1]
			}
		}
		UnaryOp { 
			if operands.len == 1 {
				inst.operand = operands[0]
			}
		}
		Load { 
			if operands.len == 1 {
				inst.ptr = operands[0]
			}
		}
		Store { 
			if operands.len == 2 {
				inst.ptr = operands[0]
				inst.value = operands[1]
			}
		}
		PhiInstruction { inst.operands = operands }
		Call { 
			if operands.len >= 1 {
				inst.fn = operands[0]
				if operands.len > 1 {
					inst.args = operands[1..]
				}
			}
		}
		else {}
	}
}

fn (inst Instruction) to_string() string {
	match inst {
		BinaryOp { return '${inst.left.to_string()} ${inst.op} ${inst.right.to_string()}' }
		UnaryOp { return '${inst.op} ${inst.operand.to_string()}' }
		Load { return 'load ${inst.ptr.to_string()}' }
		Store { return 'store ${inst.value.to_string()}, ${inst.ptr.to_string()}' }
		Alloca { return 'alloca' }
		PhiInstruction { 
			mut s := 'phi ['
			for i, op in inst.operands {
				if i > 0 { s += ', ' }
				s += op.to_string()
			}
			s += ']'
			return s
		}
		Call { 
			mut s := 'call ${inst.fn.to_string()}(' 
			for i, arg in inst.args {
				if i > 0 { s += ', ' }
				s += arg.to_string()
			}
			s += ')'
			if inst.is_tail { s += ' tail' }
			return s
		}
		Terminator { 
			match inst {
				BranchTerminator { return 'br ${inst.bb.name}' }
				IfTerminator { return 'if ${inst.val.to_string()} then ${inst.bb_true.name} else ${inst.bb_false.name}' }
				MatchTerminator { return 'match' }
				ReturnTerminator { return 'ret' }
			}
		}
	}
}

// CFG management methods
fn (f Function) get_entry_block() &BasicBlock {
	if f.bb.len > 0 {
		return f.bb[0]
	}
	return unsafe { nil }
}

fn (f Function) get_exit_blocks() []&BasicBlock {
	mut exits := []&BasicBlock{}
	for bb in f.bb {
		if bb.terminator is ReturnTerminator || bb.successors.len == 0 {
			exits << bb
		}
	}
	return exits
}

fn (f Function) is_reachable(bb &BasicBlock) bool {
	for b in f.bb {
		if b == bb {
			return true
		}
	}
	return false
}
