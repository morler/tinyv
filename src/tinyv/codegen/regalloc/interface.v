// Machine Code Generation Backend for TinyV Compiler
// Register Allocation Interface Definitions
//
// This file defines the core interfaces and types for register allocation
// in the x64 machine code generation backend.

module regalloc

// AllocationHint provides hints for register allocation strategy
pub enum AllocationHint {
	prefer_volatile     // function-local variables - use caller-saved registers
	prefer_preserved    // variables crossing function calls - use callee-saved registers
	must_preserve       // variables that cannot be clobbered - force callee-saved
	parameter0          // first parameter register (RDI for x64)
	parameter1          // second parameter register (RSI for x64)
	parameter2          // third parameter register (RDX for x64) 
	parameter3          // fourth parameter register (RCX for x64)
	parameter4          // fifth parameter register (R8 for x64)
	parameter5          // sixth parameter register (R9 for x64)

	frequently_used     // allocate to most accessible registers
	rarely_used         // candidate for stack allocation
	immediate_value     // may be embedded directly in instruction
}

// RegisterAssignment contains the result of register allocation for a function
pub struct RegisterAssignment {
pub mut:
	function_assignments map[string]PhysicalRegister // variable -> register mapping
	stack_spills         []SpillLocation            // spilled variables
	calling_conventions  CallConventionInfo         // ABI compliance info
	live_ranges         LiveRangeMap               // lifetime analysis results
}

// SpillLocation represents a spilled variable's location on stack
pub struct SpillLocation {
	variable string        // SSA variable name
	offset   int          // stack offset from base pointer
	size     int          // variable size in bytes
}

// CallConventionInfo tracks ABI compliance details
pub struct CallConventionInfo {
	parameter_registers []PhysicalRegister // registers used for parameters
	return_register     PhysicalRegister   // register for return value
	stack_alignment     int               // required stack alignment
}

// LiveRangeMap tracks variable lifetimes
pub type LiveRangeMap = map[string]LiveRange

// LiveRange represents the lifetime of a variable
pub struct LiveRange {
	start int  // program point where variable becomes live
	end   int  // program point where variable dies
}

// InterferenceGraph represents register conflicts
pub struct InterferenceGraph {
pub mut:
	nodes []VariableNode
	edges map[string][]string  // variable -> conflicting variables
}

// VariableNode in the interference graph
pub struct VariableNode {
	variable string
	color    int  // assigned color (register)
	degree   int  // number of conflicts
}

// PhysicalRegister represents an x64 hardware register
pub enum PhysicalRegister {
	// General purpose registers
	rax
	rbx
	rcx
	rdx
	rsi
	rdi
	rbp
	rsp
	r8
	r9
	r10
	r11
	r12
	r13
	r14
	r15

	// Special purpose
	rip  // instruction pointer (not directly allocable)
}

// RegisterAllocator is the main interface for register allocation algorithms
pub interface RegisterAllocator {
	// Core allocation methods
	allocate_function(string) !RegisterAssignment
	allocate_basic_block(string) !map[string]PhysicalRegister
	spill_to_stack(string, string) !SpillLocation

	// Register management
	allocate_register(string, AllocationHint) !PhysicalRegister
	free_register(PhysicalRegister)
	reserve_register(PhysicalRegister) !

	// Analysis methods
	compute_live_ranges(string) !LiveRangeMap
	build_interference_graph(LiveRangeMap) !InterferenceGraph
	select_spill_candidate(InterferenceGraph) string

	// x64 specific methods
	follows_calling_convention(RegisterAssignment) bool
	optimize_calling_sequence([]string) ![]string
}

// RegisterClass provides register sets and properties for allocation
pub struct RegisterClass {
pub:
	// All general purpose registers
	gpr_registers []PhysicalRegister

	// Volatile (caller-saved) registers
	caller_saved   []PhysicalRegister

	// Preserved (callee-saved) registers
	callee_saved   []PhysicalRegister

	// Preferred allocation order (based on instruction efficiency)
	preferred_order []PhysicalRegister
}

// AllocationResult wraps allocation outcomes
pub struct AllocationResult {
	success         bool
	assignment      RegisterAssignment
	failed_variables []string           // variables that couldn't be allocated
}

// Utility functions for register management
pub fn (r PhysicalRegister) is_caller_saved() bool {
	caller_saved_regs := [PhysicalRegister.rax, .rcx, .rdx, .rsi, .rdi, .r8, .r9, .r10, .r11]
	return r in caller_saved_regs
}

pub fn (r PhysicalRegister) is_callee_saved() bool {
	callee_saved_regs := [PhysicalRegister.rbx, .rbp, .r12, .r13, .r14, .r15]
	return r in callee_saved_regs
}

pub fn (r PhysicalRegister) name() string {
	return match r {
		.rax { 'rax' }
		.rbx { 'rbx' }
		.rcx { 'rcx' }
		.rdx { 'rdx' }
		.rsi { 'rsi' }
		.rdi { 'rdi' }
		.rbp { 'rbp' }
		.rsp { 'rsp' }
		.r8  { 'r8' }
		.r9  { 'r9' }
		.r10 { 'r10' }
		.r11 { 'r11' }
		.r12 { 'r12' }
		.r13 { 'r13' }
		.r14 { 'r14' }
		.r15 { 'r15' }
		.rip { 'rip' }
	}
}

pub fn new_register_class() RegisterClass {
	return RegisterClass{
		gpr_registers: [
			.rax, .rbx, .rcx, .rdx,
			.rsi, .rdi, .rbp,
			.r8, .r9, .r10, .r11, .r12, .r13, .r14, .r15
		]
		caller_saved: [
			.rax, .rcx, .rdx, .rsi, .rdi,
			.r8, .r9, .r10, .r11
		]
		callee_saved: [
			.rbx, .rbp, .r12, .r13, .r14, .r15
		]
		preferred_order: [
			.rax, .rbx, .rcx, .rdx, .rsi, .rdi,
			.r8, .r9, .r10, .r11
		]
	}
}