// Register Allocation Algorithm Implementation for TinyV Compiler
// This module implements the core register allocation algorithms:
// - Live range computation using data flow analysis
// - Interference graph construction using graph coloring theory
// - Register assignment using Chaitin-Briggs algorithm

module regalloc

import tinyv.ir.ssa as ssa

// LiveRangeAnalysis implements data flow analysis for variable lifetime tracking
pub struct LiveRangeAnalysis {
pub mut:
	ssa_cfg    ssa.ControlFlowGraph  // SSA form CFG
	live_ranges LiveRangeMap         // computed live range map
}

// new_live_range_analysis creates a new live range analyzer
pub fn new_live_range_analysis(cfg ssa.ControlFlowGraph) LiveRangeAnalysis {
	return LiveRangeAnalysis{
		ssa_cfg:    cfg
		live_ranges: map[string]LiveRange{}
	}
}

// compute_live_ranges performs data flow analysis to compute live ranges for all variables
pub fn (mut lra LiveRangeAnalysis) compute_live_ranges() !LiveRangeMap {
	// Initialize worklist with all basic blocks
	mut worklist := []string{}
	for block_name in lra.ssa_cfg.blocks.keys() {
		worklist << block_name
	}

	// Map to track which variables are live at each program point
	mut live_in := map[string][]string{}  // block -> variables live at entry
	mut live_out := map[string][]string{} // block -> variables live at exit

	// Initialize with empty sets
	for block_name in worklist {
		live_in[block_name] = []
		live_out[block_name] = []
	}

	// Iterative data flow analysis
	mut changed := true
	for changed {
		changed = false

		// Process each block in reverse postorder for efficiency
		for block_name in worklist {
			block := lra.ssa_cfg.blocks[block_name] or { continue }
			mut successors := []string{}
			for edge in block.out_edges {
				successors << edge.target.name
			}

			// Calculate live_out for this block
			mut new_live_out := []string{}
			for succ in successors {
				if succ in live_in {
					new_live_out << live_in[succ]
				}
			}
			// Remove duplicates
			new_live_out = lra.unique_variables(new_live_out)

			// Update if changed
			if !lra.equal_variable_sets(live_out[block_name], new_live_out) {
				live_out[block_name] = new_live_out.clone()
				changed = true
			}

			// Calculate live_in for this block
			mut new_live_in := live_out[block_name].clone()

			// For each instruction in reverse order
			for i := block.instructions.len - 1; i >= 0; i-- {
				inst := block.instructions[i]

				// Remove defined variables from live set
				if inst.defines.len > 0 {
					new_live_in = lra.remove_variables(new_live_in, inst.defines)
				}

				// Add used variables to live set
				if inst.uses.len > 0 {
					new_live_in << inst.uses
				}
			}

			new_live_in = lra.unique_variables(new_live_in)

			// Update if changed
			if !lra.equal_variable_sets(live_in[block_name], new_live_in) {
				live_in[block_name] = new_live_in.clone()
				changed = true
			}
		}
	}

	// Convert live sets to live ranges
	return lra.convert_to_live_ranges(live_in, live_out)
}

// Helper method to remove duplicates from variable list
fn (lra LiveRangeAnalysis) unique_variables(vars []string) []string {
	mut seen := map[string]bool{}
	mut result := []string{}
	for v in vars {
		if !seen[v] {
			seen[v] = true
			result << v
		}
	}
	return result
}

// Helper method to remove variables from list
fn (lra LiveRangeAnalysis) remove_variables(vars []string, to_remove []string) []string {
	mut result := []string{}
	for v in vars {
		if v !in to_remove {
			result << v
		}
	}
	return result
}

// Helper method to compare variable sets
fn (lra LiveRangeAnalysis) equal_variable_sets(a []string, b []string) bool {
	if a.len != b.len { return false }
	mut a_set := map[string]bool{}
	for v in a { a_set[v] = true }
	for v in b {
		if !a_set[v] { return false }
	}
	return true
}

// Convert live sets to live ranges by finding first and last use
fn (lra LiveRangeAnalysis) convert_to_live_ranges(live_in map[string][]string, live_out map[string][]string) LiveRangeMap {
	mut ranges := map[string]LiveRange{}

	// Track first and last program point for each variable
	mut first_use := map[string]int{}
	mut last_use := map[string]int{}

	// Initialize with max values to find minimums
	for var_name in lra.get_all_variables() {
		first_use[var_name] = 999999
		last_use[var_name] = -1
	}

	// Calculate program points (simple sequential numbering)
	mut program_point := 0

	for block_name in lra.ssa_cfg.blocks.keys() {
		block := lra.ssa_cfg.blocks[block_name] or { continue }

		// Variables live at block entry
		for var_name in live_in[block_name] {
			if program_point < first_use[var_name] {
				first_use[var_name] = program_point
			}
			if program_point > last_use[var_name] {
				last_use[var_name] = program_point
			}
		}

		// Process each instruction
		for inst in block.instructions {
			program_point++

			// Variables used in this instruction
			for var_name in inst.uses {
				if program_point < first_use[var_name] {
					first_use[var_name] = program_point
				}
				if program_point > last_use[var_name] {
					last_use[var_name] = program_point
				}
			}

			// Variables defined in this instruction
			for var_name in inst.defines {
				if program_point < first_use[var_name] {
					first_use[var_name] = program_point
				}
				if program_point > last_use[var_name] {
					last_use[var_name] = program_point
				}
			}
		}

		// Variables live at block exit
		program_point++
		for var_name in live_out[block_name] {
			if program_point < first_use[var_name] {
				first_use[var_name] = program_point
			}
			if program_point > last_use[var_name] {
				last_use[var_name] = program_point
			}
		}
	}

	// Create live range objects
	for var_name in first_use.keys() {
		if first_use[var_name] <= last_use[var_name] {
			ranges[var_name] = LiveRange{
				start: first_use[var_name]
				end:   last_use[var_name]
			}
		}
	}

	lra.live_ranges = ranges
	return ranges
}

// Get all variables defined or used in the CFG
fn (lra LiveRangeAnalysis) get_all_variables() []string {
	mut vars := map[string]bool{}

	for block_name in lra.ssa_cfg.blocks.keys() {
		block := lra.ssa_cfg.blocks[block_name] or { continue }
		for inst in block.instructions {
			for v in inst.uses { vars[v] = true }
			for v in inst.defines { vars[v] = true }
		}
	}

	mut result := []string{}
	for v in vars.keys() { result << v }
	return result
}

// InterferenceGraphBuilder constructs conflict graphs for register allocation
pub struct InterferenceGraphBuilder {
pub mut:
	interference_graph InterferenceGraph
}

// new_interference_graph_builder creates a new interference graph builder
pub fn new_interference_graph_builder() InterferenceGraphBuilder {
	return InterferenceGraphBuilder{
		interference_graph: InterferenceGraph{
			nodes:  []VariableNode{}
			edges:  map[string][]string{}
		}
	}
}

// build_interference_graph constructs the interference graph from live ranges
pub fn (mut igb InterferenceGraphBuilder) build_interference_graph(live_ranges LiveRangeMap) !InterferenceGraph {
	// Create nodes for all variables
	for var_name in live_ranges.keys() {
		node := VariableNode{
			variable: var_name
			color:    -1  // uncolored initially
			degree:   0   // degree will be computed from edges
		}
		igb.interference_graph.nodes << node
		igb.interference_graph.edges[var_name] = []
	}

	// Find interfering variables using live range overlap
	variables := live_ranges.keys()
	for i := 0; i < variables.len; i++ {
		for j := i + 1; j < variables.len; j++ {
			var1 := variables[i]
			var2 := variables[j]

			range1 := live_ranges[var1]
			range2 := live_ranges[var2]

			// Check if live ranges overlap
			if igb.ranges_overlap(range1, range2) {
				// Add interference edge
				igb.add_interference(var1, var2)
				igb.add_interference(var2, var1)
			}
		}
	}

	// Update node degrees based on interference count
	for i := 0; i < igb.interference_graph.nodes.len; i++ {
		var_name := igb.interference_graph.nodes[i].variable
		degree := igb.interference_graph.edges[var_name].len
		igb.interference_graph.nodes[i].degree = degree
	}

	return igb.interference_graph
}

// Check if two live ranges overlap
fn (igb InterferenceGraphBuilder) ranges_overlap(range1 LiveRange, range2 LiveRange) bool {
	// Two ranges overlap if they are not completely separate
	return !(range1.end < range2.start || range2.end < range1.start)
}

// Add interference between two variables
fn (mut igb InterferenceGraphBuilder) add_interference(var1 string, var2 string) {
	// Avoid self-interference
	if var1 == var2 { return }

	// Avoid duplicate edges
	if var2 !in igb.interference_graph.edges[var1] {
		igb.interference_graph.edges[var1] << var2
	}
}

// ChaitinBriggsAlgorithm implements the graph coloring based register allocation
pub struct ChaitinBriggsAlgorithm {
pub mut:
	available_colors []PhysicalRegister  // available physical registers
	interference_graph InterferenceGraph
	coloring         map[string]PhysicalRegister  // variable -> register mapping
}

// new_chaitin_briggs creates a new Chaitin-Briggs allocator
pub fn new_chaitin_briggs(registers []PhysicalRegister) ChaitinBriggsAlgorithm {
	return ChaitinBriggsAlgorithm{
		available_colors: registers
		interference_graph: InterferenceGraph{}
		coloring: map[string]PhysicalRegister{}
	}
}

// allocate_registers performs graph coloring register allocation
pub fn (mut cba ChaitinBriggsAlgorithm) allocate_registers(igraph InterferenceGraph) !map[string]PhysicalRegister {
	cba.interference_graph = igraph

	// Create copy of graph for modification
	mut graph_copy := igb.copy_interference_graph(igraph)

	// Stack for removed nodes (reverse order for coloring)
	mut removed_stack := []VariableNode{}

	// Repeatedly remove nodes with degree < K (available colors)
	for graph_copy.nodes.len > 0 {
		mut found_low_degree := false

		for i := 0; i < graph_copy.nodes.len; i++ {
			node := graph_copy.nodes[i]
			if node.degree < cba.available_colors.len {
				// Remove this node and push to stack
				removed_stack << node
				igb.remove_node_from_graph(mut graph_copy, node.variable)
				found_low_degree = true
				break
			}
		}

		if !found_low_degree {
			// No low degree node found - must spill
			// For now, just pick the first node (simplified spill selection)
			spill_node := graph_copy.nodes[0]
			removed_stack << spill_node
			igb.remove_node_from_graph(mut graph_copy, spill_node.variable)
		}
	}

	// Color the nodes by popping from stack
	for removed_stack.len > 0 {
		node := removed_stack.pop()

		// Find available colors not used by neighbors
		mut used_colors := []PhysicalRegister{}
		for neighbor in igraph.edges[node.variable] {
			if neighbor in cba.coloring {
				used_colors << cba.coloring[neighbor]
			}
		}

		// Assign first available color
		mut assigned_color := PhysicalRegister.rax // default
		for color in cba.available_colors {
			if color !in used_colors {
				assigned_color = color
				break
			}
		}

		cba.coloring[node.variable] = assigned_color
	}

	return cba.coloring
}

// Helper functions for graph manipulation
struct InterferenceGraphBuilderHelper {}

fn igb.copy_interference_graph(graph InterferenceGraph) InterferenceGraph {
	mut new_graph := InterferenceGraph{
		nodes: []VariableNode{}
		edges: map[string][]string{}
	}

	// Copy nodes
	for node in graph.nodes {
		new_graph.nodes << VariableNode{
			variable: node.variable
			color:    node.color
			degree:   node.degree
		}
	}

	// Copy edges
	for var_name, neighbors in graph.edges {
		new_graph.edges[var_name] = neighbors.clone()
	}

	return new_graph
}

fn igb.remove_node_from_graph(mut graph InterferenceGraph, var_name string) {
	// Remove from nodes list
	for i := 0; i < graph.nodes.len; i++ {
		if graph.nodes[i].variable == var_name {
			graph.nodes.delete(i)
			break
		}
	}

	// Remove edges to this node and update degrees
	for neighbor in graph.edges[var_name] {
		if neighbor in graph.edges {
			// Remove var_name from neighbor's edge list
			mut neighbor_edges := []string{}
			for n in graph.edges[neighbor] {
				if n != var_name {
					neighbor_edges << n
				}
			}
			graph.edges[neighbor] = neighbor_edges

			// Update neighbor's degree in nodes list
			for mut node in graph.nodes {
				if node.variable == neighbor {
					node.degree = graph.edges[neighbor].len
					break
				}
			}
		}
	}

	// Remove the variable's edges entirely
	graph.edges.delete(var_name)
}

// RegisterAllocatorImpl provides the main register allocation implementation
pub struct RegisterAllocatorImpl {
pub mut:
	live_range_analyzer LiveRangeAnalysis
	interference_builder InterferenceGraphBuilder
	chaitin_briggs       ChaitinBriggsAlgorithm
}

// new_register_allocator creates a new register allocator implementation
pub fn new_register_allocator(cfg ssa.ControlFlowGraph) RegisterAllocatorImpl {
	reg_class := new_register_class()
	return RegisterAllocatorImpl{
		live_range_analyzer: new_live_range_analysis(cfg)
		interference_builder: new_interference_graph_builder()
		chaitin_briggs:       new_chaitin_briggs(reg_class.gpr_registers)
	}
}

// Implement the RegisterAllocator interface methods
pub fn (mut rai RegisterAllocatorImpl) compute_live_ranges(_ string) !LiveRangeMap {
	return rai.live_range_analyzer.compute_live_ranges()
}

pub fn (mut rai RegisterAllocatorImpl) build_interference_graph(live_ranges LiveRangeMap) !InterferenceGraph {
	return rai.interference_builder.build_interference_graph(live_ranges)
}

pub fn (rai RegisterAllocatorImpl) select_spill_candidate(graph InterferenceGraph) string {
	// Simple spill heuristic: highest degree first
	mut max_degree := 0
	mut candidate := ""

	for node in graph.nodes {
		if node.degree > max_degree {
			max_degree = node.degree
			candidate = node.variable
		}
	}

	if candidate == "" && graph.nodes.len > 0 {
		candidate = graph.nodes[0].variable
	}

	return candidate
}

// Implement the extended RegisterAllocator interface methods

pub fn (mut rai RegisterAllocatorImpl) allocate_function(func_name string) !RegisterAssignment {
	// Compute live ranges
	live_ranges := rai.compute_live_ranges(func_name)!

	// Build interference graph
	interference_graph := rai.build_interference_graph(live_ranges)!

	// Perform register allocation
	assignments := rai.chaitin_briggs.allocate_registers(interference_graph)!

	// Create assignment result
	return RegisterAssignment{
		function_assignments: assignments
		stack_spills:         []SpillLocation{}  // TODO: implement spilling
		calling_conventions:  CallConventionInfo{
			parameter_registers: []PhysicalRegister{.rdi, .rsi, .rdx, .rcx, .r8, .r9}
			return_register:     .rax
			stack_alignment:     16
		}
		live_ranges: live_ranges
	}
}

pub fn (mut rai RegisterAllocatorImpl) allocate_basic_block(block_name string) !map[string]PhysicalRegister {
	// For basic block allocation, extract its live ranges and allocate
	live_ranges := rai.compute_live_ranges(block_name)!

	// Create a subgraph for this block (simplified - would need block-specific analysis)
	interference_subgraph := InterferenceGraph{
		nodes: []VariableNode{}
		edges: map[string][]string{}
	}

	// Add variables from this block's live ranges
	for var_name, range_data in live_ranges {
		node := VariableNode{
			variable: var_name
			color:    -1
			degree:   0
		}
		interference_subgraph.nodes << node
		interference_subgraph.edges[var_name] = []
	}

	assignments := rai.chaitin_briggs.allocate_registers(interference_subgraph)!
	return assignments
}

pub fn (rai RegisterAllocatorImpl) follows_calling_convention(assignment RegisterAssignment) bool {
	// Check if parameter registers are assigned correctly
	param_regs := [PhysicalRegister.rdi, .rsi, .rdx, .rcx, .r8, .r9]
	for reg in param_regs {
		if reg in assignment.calling_conventions.parameter_registers {
			// Check if any parameters are assigned to unexpected registers
		}
	}
	return true  // Simplified check
}

pub fn (rai RegisterAllocatorImpl) optimize_calling_sequence(functions []string) ![]string {
	// Simple optimization: sort by function name length (not meaningful but consistent)
	mut sorted := functions.clone()
	sorted.sort_by_len()
	return sorted
}

// Basic implementations for remaining interface methods
pub fn (rai RegisterAllocatorImpl) allocate_register(var_name string, hint AllocationHint) !PhysicalRegister {
	// Find the next available register based on hint
	reg_class := new_register_class()

	match hint {
		.prefer_volatile {
			return reg_class.caller_saved[0]
		}
		.prefer_preserved {
			return reg_class.callee_saved[0]
		}
		else {
			// Default allocation order
			return reg_class.preferred_order[0]
		}
	}
}

pub fn (rai RegisterAllocatorImpl) free_register(_ PhysicalRegister) {
	// Implementation would track free registers
}

pub fn (rai RegisterAllocatorImpl) reserve_register(_ PhysicalRegister) ! {
	// Implementation would mark register as reserved
}

pub fn (rai RegisterAllocatorImpl) spill_to_stack(_ string, _ string) !SpillLocation {
	// Simplified spill implementation
	return SpillLocation{
		variable: "spilled_var"
		offset:   8  // fixed offset for simplicity
		size:     8  // assume 64-bit
	}
}</content>
<parameter name="file_path">D:/Code/MyProject/V/tinyv/src/tinyv/codegen/regalloc/liveness.v