// x64 Code Generation Backend for TinyV Compiler: Basic Instruction Selection Implementation
// This module implements basic instruction selection to convert SSA instructions to x64 assembly

module x64_codegen

import tinyv.ir.ssa
import tinyv.codegen.regalloc

// x64Instruction represents a single x64 assembly instruction
pub enum X64Instruction {
	// Data movement
	mov
	lea

	// Arithmetic
	add
	sub
	imul

	// Comparison
	cmp

	// Control flow
	jmp
	jne
	call
	ret
	push
	pop

	// Labels and other
	label
}

// X64Operand represents an operand for x64 instructions
type X64Operand = RegisterOperand | MemRegOperand | ImmediateOperand | LabelOperand

pub struct RegisterOperand {
	reg regalloc.PhysicalRegister
}

pub struct MemRegOperand {
	reg regalloc.PhysicalRegister
	offset int
}

pub struct ImmediateOperand {
	val int
}

pub struct LabelOperand {
	label_name string
}

// X64Code represents a complete x64 instruction with operands
pub struct X64Code {
	instruction X64Instruction
	operands []X64Operand
	comment string
}

// InstructionSelector converts SSA instructions to x64 assembly
pub struct InstructionSelector {
pub mut:
		register_map map[string]regalloc.PhysicalRegister
		code []X64Code
}

// Constructor
pub fn new_instruction_selector(reg_assignments map[string]regalloc.PhysicalRegister) InstructionSelector {
	return InstructionSelector{
		register_map: reg_assignments
		code: []X64Code{}
	}
}

// Main instruction selection method
pub fn (mut is InstructionSelector) select_instructions(cfg ssa.ControlFlowGraph) []X64Code {
	// Initialize stack frame
is.add_instruction(.label, [X64Operand.Label('function_entry')], 'Function prologue')
	is.add_instruction(.push, [X64Operand.Register(.rbp)], 'Save base pointer')
	is.add_instruction(.mov, [X64Operand.Register(.rbp), X64Operand.Register(.rsp)], 'Set new base pointer')

	// Process each basic block
	for block_name in cfg.blocks.keys() {
		block := cfg.blocks[block_name] or { continue }
		// Block label
		is.add_instruction(.label, [X64Operand.Label(block_name)], 'Block ${block_name}')

		// Convert each instruction
		for inst in block.instructions {
			is.select_single_instruction(inst)
		}

		// Handle terminator
		is.select_terminator(block.terminator)
	}
	// Function epilogue
	is.add_instruction(.label, [X64Operand.Label('function_exit')], 'Function epilogue')
	is.add_instruction(.mov, [X64Operand.Register(.rsp), X64Operand.Register(.rbp)], 'Restore stack pointer')
	is.add_instruction(.pop, [X64Operand.Register(.rbp)], 'Restore base pointer')
	is.add_instruction(.ret, [], 'Return from function')

	return is.code
}

// Convert terminator instructions
pub fn (mut is InstructionSelector) select_terminator(term ssa.Terminator) {
	match term {
		ssa.BranchTerminator {
			is.add_instruction(.jmp, [X64Operand.Label(term.bb.name)], 'Unconditional branch')
		}
		ssa.IfTerminator {
			// Compare condition with zero
			condition_reg := is.get_operand_register(term.val)
			is.add_instruction(.cmp, [
				X64Operand.Register(condition_reg),
				X64Operand.Immediate(0)
			], 'Test condition')

			is.add_instruction(.jne, [X64Operand.Label(term.bb_true.name)], 'Branch if true')
			is.add_instruction(.jmp, [X64Operand.Label(term.bb_false.name)], 'Branch if false')
		}
		ssa.ReturnTerminator {
			is.add_instruction(.jmp, [X64Operand.Label('function_exit')], 'Return from function')
		}
		else {}
	}
}

// Convert individual SSA instructions
pub fn (mut is InstructionSelector) select_single_instruction(inst ssa.Instruction) {
	match inst {
		ssa.BinaryOp {
			is.select_binary_op(inst)
		}
		ssa.UnaryOp {
			is.select_unary_op(inst)
		}
		ssa.Load {
			is.select_load(inst)
		}
		ssa.Store {
			is.select_store(inst)
		}
		ssa.Alloca {
			is.select_alloca(inst)
		}
		ssa.Call {
			is.select_call(inst)
		}
		else {
			// Unsupported instruction
		}
	}
}

// Helper methods for instruction selection
pub fn (mut is InstructionSelector) select_binary_op(inst ssa.BinaryOp) {
	left_reg := is.get_operand_register(inst.left)
	right_reg := is.get_operand_register(inst.right)

	match inst.op {
		.add {
			// Use result register or allocate new one
			result_reg := is.allocate_result_register('add')
			is.add_instruction(.mov, [X64Operand.Register(result_reg), X64Operand.Register(left_reg)], 'Load left operand')
			is.add_instruction(.add, [X64Operand.Register(result_reg), X64Operand.Register(right_reg)], 'Add operation')
		}
		.sub {
			result_reg := is.allocate_result_register('sub')
			is.add_instruction(.mov, [X64Operand.Register(result_reg), X64Operand.Register(left_reg)], 'Load left')
			is.add_instruction(.sub, [X64Operand.Register(result_reg), X64Operand.Register(right_reg)], 'Subtract')
		}
		.eq {
			result_reg := is.allocate_result_register('cmp')
			is.add_instruction(.mov, [X64Operand.Register(result_reg), X64Operand.Register(left_reg)], 'Compare operands')
			is.add_instruction(.cmp, [X64Operand.Register(result_reg), X64Operand.Register(right_reg)], 'Equality test')
		}
		else {
			// Handle other operations
		}
	}
}

pub fn (mut is InstructionSelector) select_unary_op(inst ssa.UnaryOp) {
	operand_reg := is.get_operand_register(inst.operand)
	result_reg := is.allocate_result_register('${inst.op}')

	is.add_instruction(.mov, [X64Operand.register(result_reg), X64Operand.register(operand_reg)], 'Load operand')
}

pub fn (mut is InstructionSelector) select_load(inst ssa.Load) {
	ptr_reg := is.get_operand_register(inst.ptr)
	result_reg := is.allocate_result_register('load')

	is.add_instruction(.mov, [
		X64Operand.register(result_reg),
		X64Operand.mem_reg(ptr_reg, 0)
	], 'Load from memory')
}

pub fn (mut is InstructionSelector) select_store(inst ssa.Store) {
	value_reg := is.get_operand_register(inst.value)
	ptr_reg := is.get_operand_register(inst.ptr)

	is.add_instruction(.mov, [
		X64Operand.mem_reg(ptr_reg, 0),
		X64Operand.register(value_reg)
	], 'Store to memory')
}

pub fn (mut is InstructionSelector) select_alloca(_inst ssa.Alloca) {
	// Simplified stack allocation
	result_reg := is.allocate_result_register('alloc')
	is.add_instruction(.lea, [
		X64Operand.register(result_reg),
		X64Operand.mem_reg(.rbp, -8)
	], 'Allocate stack space')
}

pub fn (mut is InstructionSelector) select_call(inst ssa.Call) {
	// Simplified function call - prepare arguments
	for i, arg in inst.args {
		arg_reg := is.get_operand_register(arg)
		if i == 0 { is.add_instruction(.mov, [X64Operand.register(.rdi), X64Operand.register(arg_reg)], 'Argument 0') }
		if i == 1 { is.add_instruction(.mov, [X64Operand.register(.rsi), X64Operand.register(arg_reg)], 'Argument 1') }
	}

	is.add_instruction(.call, [X64Operand.immediate(0)], 'Function call') // Placeholder for function address
}

// Helper functions
pub fn (is InstructionSelector) get_operand_register(val ssa.Value) regalloc.PhysicalRegister {
	match val {
		ssa.Variable {
			return is.register_map[val.name] or { regalloc.PhysicalRegister.rax }
		}
		ssa.None {
			return regalloc.PhysicalRegister.rax
		}
		else {
			return regalloc.PhysicalRegister.rax
		}
	}
}

pub fn (is InstructionSelector) allocate_result_register(_op string) regalloc.PhysicalRegister {
	// Simplified - always use rax for now
	return regalloc.PhysicalRegister.rax
}

pub fn (mut is InstructionSelector) add_instruction(inst X64Instruction, operands []X64Operand, comment string) {
	is.code << X64Code{
		instruction: inst
		operands: operands
		comment: comment
	}
}