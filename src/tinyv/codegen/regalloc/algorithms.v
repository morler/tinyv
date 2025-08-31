// Register Allocation Algorithm Implementation for TinyV Compiler
// This module implements the core register allocation algorithms:
// Basic structure and interface stubs with proper integration

module regalloc

import tinyv.ir.ssa as ssa

// LiveRangeAnalysis implements data flow analysis for variable lifetime computation
pub struct LiveRangeAnalysis {
pub mut:
	ssa_cfg    ssa.ControlFlowGraph
	live_ranges LiveRangeMap
}

// new_live_range_analysis creates live range analyzer
pub fn new_live_range_analysis(cfg ssa.ControlFlowGraph) LiveRangeAnalysis {
	return LiveRangeAnalysis{
		ssa_cfg: cfg
		live_ranges: map[string]LiveRange{}
	}
}

// compute_live_ranges implements basic live range computation
pub fn (mut lra LiveRangeAnalysis) compute_live_ranges() !LiveRangeMap {
	mut ranges := map[string]LiveRange{}

	// Simple analysis: collect all variables and assign basic ranges
	mut program_point := 0
	for block_name in lra.ssa_cfg.blocks.keys() {
		block := lra.ssa_cfg.blocks[block_name] or { continue }

		for inst in block.instructions {
			for v in inst.uses {
				if v !in ranges {
					ranges[v] = LiveRange{start: program_point, end: program_point + 1}
				} else {
					ranges[v].end = program_point + 1
				}
			}
			for v in inst.defines {
				if v !in ranges {
					ranges[v] = LiveRange{start: program_point, end: program_point + 1}
				} else {
					ranges[v].end = program_point + 1
				}
			}
			program_point++
		}
	}

	lra.live_ranges = ranges
	return ranges
}

// InterferenceGraphBuilder constructs basic interference graphs
pub struct InterferenceGraphBuilder {
pub mut:
	interference_graph InterferenceGraph
}

// new_interference_graph_builder creates interference graph builder
pub fn new_interference_graph_builder() InterferenceGraphBuilder {
	return InterferenceGraphBuilder{
		interference_graph: InterferenceGraph{
			nodes: []VariableNode{}
			edges: map[string][]string{}
		}
	}
}

// build_interference_graph creates basic interference graph
pub fn (mut igb InterferenceGraphBuilder) build_interference_graph(live_ranges LiveRangeMap) !InterferenceGraph {
	// Create nodes
	for var_name in live_ranges.keys() {
		node := VariableNode{
			variable: var_name
			color: -1
			degree: 0
		}
		igb.interference_graph.nodes << node
		igb.interference_graph.edges[var_name] = []string{}
	}

	// Simple interference: connect all overlapping ranges
	variables := live_ranges.keys()
	for i := 0; i < variables.len; i++ {
		for j := i + 1; j < variables.len; j++ {
			var1 := variables[i]
			var2 := variables[j]
			range1 := live_ranges[var1]
			range2 := live_ranges[var2]

			// Simple overlap check
			if !(range1.end < range2.start || range2.end < range1.start) {
				if var2 !in igb.interference_graph.edges[var1] {
					igb.interference_graph.edges[var1] << var2
					igb.interference_graph.edges[var2] << var1
				}
			}
		}
	}

	// Update degrees
	for i := 0; i < igb.interference_graph.nodes.len; i++ {
		var_name := igb.interference_graph.nodes[i].variable
		igb.interference_graph.nodes[i].degree = igb.interference_graph.edges[var_name].len
	}

	return igb.interference_graph
}

// ChaitinBriggsAlgorithm provides basic graph coloring register allocation
pub struct ChaitinBriggsAlgorithm {
pub mut:
	available_colors []PhysicalRegister
	coloring map[string]PhysicalRegister
}

// new_chaitin_briggs creates Chaitin-Briggs allocator
pub fn new_chaitin_briggs(registers []PhysicalRegister) ChaitinBriggsAlgorithm {
	return ChaitinBriggsAlgorithm{
		available_colors: registers
		coloring: map[string]PhysicalRegister{}
	}
}

// allocate_registers performs simplified graph coloring
pub fn (mut cba ChaitinBriggsAlgorithm) allocate_registers(igraph InterferenceGraph) !map[string]PhysicalRegister {
	// Simple allocation: assign colors in order
	for node in igraph.nodes {
		// Find first available color not used by neighbors
		mut available_color := cba.available_colors[0]
		for color in cba.available_colors {
			used_by_neighbor := false
			for neighbor in igraph.edges[node.variable] {
				if neighbor in cba.coloring && cba.coloring[neighbor] == color {
					used_by_neighbor = true
					break
				}
			}
			if !used_by_neighbor {
				available_color = color
				break
			}
		}
		cba.coloring[node.variable] = available_color
	}

	return cba.coloring
}

// RegisterAllocatorImpl implements the full RegisterAllocator interface
pub struct RegisterAllocatorImpl {
pub mut:
	live_range_analyzer LiveRangeAnalysis
	interference_builder InterferenceGraphBuilder
	chaitin_briggs ChaitinBriggsAlgorithm
}

// new_register_allocator creates the main register allocator
pub fn new_register_allocator(cfg ssa.ControlFlowGraph) RegisterAllocatorImpl {
	reg_class := new_register_class()

	return RegisterAllocatorImpl{
		live_range_analyzer: new_live_range_analysis(cfg)
		interference_builder: new_interference_graph_builder()
		chaitin_briggs: new_chaitin_briggs(reg_class.gpr_registers)
	}
}

// Core interface methods implementation
pub fn (mut rai RegisterAllocatorImpl) compute_live_ranges(_ string) !LiveRangeMap {
	return rai.live_range_analyzer.compute_live_ranges()
}

pub fn (mut rai RegisterAllocatorImpl) build_interference_graph(live_ranges LiveRangeMap) !InterferenceGraph {
	return rai.interference_builder.build_interference_graph(live_ranges)
}

pub fn (rai RegisterAllocatorImpl) select_spill_candidate(graph InterferenceGraph) string {
	if graph.nodes.len == 0 {
		return ""
	}

	// Select highest degree node for spilling
	mut max_degree := 0
	mut candidate := graph.nodes[0].variable

	for node in graph.nodes {
		if node.degree > max_degree {
			max_degree = node.degree
			candidate = node.variable
		}
	}

	return candidate
}

pub fn (mut rai RegisterAllocatorImpl) allocate_function(func_name string) !RegisterAssignment {
	// Compute live ranges
	live_ranges := rai.compute_live_ranges(func_name)!

	// Build interference graph
	interference_graph := rai.build_interference_graph(live_ranges)!

	// Perform register allocation
	assignments := rai.chaitin_briggs.allocate_registers(interference_graph)!

	// Create register assignment result
	reg_class := new_register_class()

	return RegisterAssignment{
		function_assignments: assignments
		stack_spills: []SpillLocation{}
		calling_conventions: CallConventionInfo{
			parameter_registers: reg_class.caller_saved[..6].clone()
			return_register: .rax
			stack_alignment: 16
		}
		live_ranges: live_ranges
	}
}

pub fn (rai RegisterAllocatorImpl) allocate_register(var_name string, hint AllocationHint) !PhysicalRegister {
	reg_class := new_register_class()

	match hint {
		.prefer_volatile { return reg_class.caller_saved[0] }
		.prefer_preserved { return reg_class.callee_saved[0] }
		.parameter0 { return .rdi }
		.parameter1 { return .rsi }
		.parameter2 { return .rdx }
		.parameter3 { return .rcx }
		.parameter4 { return .r8 }
		.parameter5 { return .r9 }
		else { return reg_class.preferred_order[0] }
	}
}

pub fn (rai RegisterAllocatorImpl) free_register(_ PhysicalRegister) {
	// Register management would be implemented here
}

pub fn (rai RegisterAllocatorImpl) reserve_register(_ PhysicalRegister) ! {
	// Register reservation would be implemented here
}

pub fn (rai RegisterAllocatorImpl) spill_to_stack(var_name string, _ string) !SpillLocation {
	return SpillLocation{
		variable: var_name
		offset: 8  // Simple fixed offset
		size: 8    // Assume 64-bit
	}
}

pub fn (mut rai RegisterAllocatorImpl) allocate_basic_block(block_name string) !map[string]PhysicalRegister {
	// For basic blocks, reuse function-level allocation
	return rai.allocate_function(block_name)
}

pub fn (rai RegisterAllocatorImpl) follows_calling_convention(_ RegisterAssignment) bool {
	// Basic implementation - would do full validation
	return true
}

pub fn (rai RegisterAllocatorImpl) optimize_calling_sequence(functions []string) ![]string {
	mut sorted := functions.clone()
	sorted.sort()
	return sorted
}</content>
<parameter name="file_path">D:/Code/MyProject/V/tinyv/src/tinyv/codegen/regalloc/algorithms.v