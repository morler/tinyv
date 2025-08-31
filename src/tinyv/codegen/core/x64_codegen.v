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
		stack_frame_size int // Size of current stack frame
		local_var_count int  // Number of local variables
}

// Constructor
pub fn new_instruction_selector(reg_assignments map[string]regalloc.PhysicalRegister) InstructionSelector {
	return InstructionSelector{
		register_map: reg_assignments
		code: []X64Code{}
		stack_frame_size: 0
		local_var_count: 0
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

public fn (mut is InstructionSelector) select_unary_op(inst ssa.UnaryOp) {
	operand_reg := is.get_operand_register(inst.operand)
	result_reg := is.allocate_result_register('${inst.op}')

	is.add_instruction(.mov, [X64Operand.Register(result_reg), X64Operand.Register(operand_reg)], 'Load operand')
}

pub fn (mut is InstructionSelector) select_load(inst ssa.Load) {
	ptr_reg := is.get_operand_register(inst.ptr)
	result_reg := is.allocate_result_register('load')

	is.add_instruction(.mov, [
		X64Operand.Register(result_reg),
		X64Operand.mem_reg(ptr_reg, 0)
	], 'Load from memory')
}

pub fn (mut is InstructionSelector) select_store(inst ssa.Store) {
	value_reg := is.get_operand_register(inst.value)
	ptr_reg := is.get_operand_register(inst.ptr)

	is.add_instruction(.mov, [
		X64Operand.mem_reg(ptr_reg, 0),
		X64Operand.Register(value_reg)
	], 'Store to memory')
}

pub fn (mut is InstructionSelector) select_alloca(_inst ssa.Alloca) {
	// Simplified stack allocation
	result_reg := is.allocate_result_register('alloc')
	is.add_instruction(.lea, [
		X64Operand.Register(result_reg),
		X64Operand.mem_reg(.rbp, -8)
	], 'Allocate stack space')
}

pub fn (mut is InstructionSelector) select_call(inst ssa.Call) []X64Code {
	// System V x64 calling convention implementation
	mut call_instructions := []X64Code{}

	// Map argument registers (System V AMD64 ABI)
	arg_registers := [regalloc.PhysicalRegister.rdi,
	                  regalloc.PhysicalRegister.rsi,
	                  regalloc.PhysicalRegister.rdx,
	                  regalloc.PhysicalRegister.rcx,
	                  regalloc.PhysicalRegister.r8,
	                  regalloc.PhysicalRegister.r9]

	stack_offset := 0

	// Handle arguments
	for i, arg in inst.args {
		arg_reg := is.get_operand_register(arg)

		if i < arg_registers.len {
			// Pass in register
			call_instructions << X64Code{
				instruction: .mov
				operands: [X64Operand.Register(arg_registers[i]), X64Operand.Register(arg_reg)]
				comment: 'Pass argument ${i} in register'
			}
		} else {
			// Pass on stack
			call_instructions << X64Code{
				instruction: .push
				operands: [X64Operand.Register(arg_reg)]
				comment: 'Pass argument ${i} on stack'
			}
			stack_offset += 8 // 8 bytes per argument on x64
		}
	}

	// Align stack to 16-byte boundary if needed
	if stack_offset % 16 != 0 {
		alignment := 16 - (stack_offset % 16)
		call_instructions << X64Code{
			instruction: .sub
			operands: [X64Operand(register(.rsp)), X64Operand(immediate(alignment))]
			comment: 'Align stack to 16-byte boundary'
		}

		call_instructions << X64Code{
			instruction: .call
			operands: [X64Operand(immediate(0))] // Placeholder for function address
			comment: 'Call function'
		}

		call_instructions << X64Code{
			instruction: .add
			operands: [X64Operand(register(.rsp)), X64Operand(immediate(alignment))]
			comment: 'Restore stack alignment'
		}
	} else {
		call_instructions << X64Code{
			instruction: .call
			operands: [X64Operand(immediate(0))] // Placeholder for function address
			comment: 'Call function'
		}
	}

	// Return value handling - assume result goes to rax
	result_reg := is.allocate_result_register('call_result')
	call_instructions << X64Code{
		instruction: .mov
		operands: [X64Operand.Register(result_reg), X64Operand.Register(.rax)]
		comment: 'Move return value from rax'
	}

	return call_instructions
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

pub fn (is InstructionSelector) allocate_result_register(op string) regalloc.PhysicalRegister {
	// Need proper register allocation logic here
	// For now, return a reasonable choice based on operation type
	return match op {
		'add', 'sub', 'mul' {
			regalloc.PhysicalRegister.rax
		}
		'load', 'store' {
			regalloc.PhysicalRegister.rbx
		}
		else {
			regalloc.PhysicalRegister.rax
		}
	}
}

pub fn (mut is InstructionSelector) setup_stack_frame(local_vars int, max_frame_size int) {
	// Calculate required stack space
	stack_frame_size := max_frame_size
	if stack_frame_size % 16 != 0 {
		stack_frame_size += 16 - (stack_frame_size % 16) // 16-byte alignment
	}

	// Function prologue
	is.add_instruction(.push, [X64Operand.Register(.rbx)], 'Save callee-saved register rbx')
	is.add_instruction(.push, [X64Operand.Register(.r12)], 'Save callee-saved register r12')
	is.add_instruction(.push, [X64Operand.Register(.r13)], 'Save callee-saved register r13')
	is.add_instruction(.push, [X64Operand.Register(.r14)], 'Save callee-saved register r14')
	is.add_instruction(.push, [X64Operand.Register(.r15)], 'Save callee-saved register r15')

	is.add_instruction(.push, [X64Operand.Register(.rbp)], 'Save base pointer')
	is.add_instruction(.mov, [X64Operand.Register(.rbp), X64Operand.Register(.rsp)], 'Set new base pointer')

	// Allocate space for local variables
	if stack_frame_size > 0 {
		is.add_instruction(.sub, [X64Operand.Register(.rsp), X64Operand.Immediate(stack_frame_size)], 'Allocate stack space for local variables')
	}

	// Store stack frame info for instruction selection
	is.stack_frame_size = stack_frame_size
	is.local_var_count = local_vars
}

pub fn (is InstructionSelector) add_instruction(inst X64Instruction, operands []X64Operand, comment string) {
	is.code << X64Code{
		instruction: inst
		operands: operands
		comment: comment
	}
}

// Helper functions for creating operands
fn register(reg regalloc.PhysicalRegister) X64Operand {
	return X64Operand.Register(reg)
}

fn mem_reg(reg regalloc.PhysicalRegister, offset int) MemRegOperand {
	return MemRegOperand{ reg: reg, offset: offset }
}

fn immediate(val int) ImmediateOperand {
	return ImmediateOperand{ val: val }
}