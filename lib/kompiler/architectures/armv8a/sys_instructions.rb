# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

module ARMv8A
	
def self.sys_instructions
	@sys_instructions
end
	
@sys_instructions = [
	{
		keyword: "mrs",
		name: "Move from system register",
		description: "Moves the contents of a system register to a 64-bit general-purpose register",
		operands: [{type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Destination general-purpose register"}, {type: "register", restrictions: {reg_type: "sr"}, name: "Source system register"}],
		mc_constructor: [
			["set_var", "sr_encoding", ["get_key", ["get_operand", 1], :reg_encoding]],
			["get_bits", ["get_key", ["get_operand", 0], :reg_value], 0, 5],
			["get_bits", ["get_key", ["get_var", "sr_encoding"], "op2"], 0, 3],
			["get_bits", ["get_key", ["get_var", "sr_encoding"], "CRm"], 0, 4],
			["get_bits", ["get_key", ["get_var", "sr_encoding"], "CRn"], 0, 4],
			["get_bits", ["get_key", ["get_var", "sr_encoding"], "op1"], 0, 3],
			["get_bits", ["get_key", ["get_var", "sr_encoding"], "op0"], 0, 2],
			["bits", 1], # L
			["bits", 0,0,1,0,1,0,1,0,1,1]
		],
		bitsize: 32
	},
	{
		keyword: "msr",
		name: "Move general-purpose register to system register",
		description: "Writes the contents of a general-purpose register to a system register",
		operands: [{type: "register", restrictions: {reg_type: "sr"}, name: "Destination system register"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Source general-purpose register"}],
		mc_constructor: [
			["set_var", "sr_encoding", ["get_key", ["get_operand", 0], :reg_encoding]],
			["get_bits", ["get_key", ["get_operand", 1], :reg_value], 0, 5],
			["get_bits", ["get_key", ["get_var", "sr_encoding"], "op2"], 0, 3],
			["get_bits", ["get_key", ["get_var", "sr_encoding"], "CRm"], 0, 4],
			["get_bits", ["get_key", ["get_var", "sr_encoding"], "CRn"], 0, 4],
			["get_bits", ["get_key", ["get_var", "sr_encoding"], "op1"], 0, 3],
			["get_bits", ["get_key", ["get_var", "sr_encoding"], "op0"], 0, 2],
			["bits", 0], # L
			["bits", 0,0,1,0,1,0,1,0,1,1]
		],
		bitsize: 32
	},
	{
		keyword: "msr",
		name: "Move immediate value to special register",
		description: "Moves an immediate value to selected bits of the PSTATE",
		operands: [{type: "register", name: "Destination system register"}, {type: "immediate", name: "Immediate value"}],
		mc_constructor: [
			# Case for PSTATE special register encodings
			["case", ["downcase_str", ["get_key", ["get_operand_hash", 0], :definition]],
				"spsel", 	["concat", ["set_var", "op1", 0b000], ["set_var", "op2", 0b101], ["if_eq_else"]],
				"daifset", 	["concat", ["set_var", "op1", 0b011], ["set_var", "op2", 0b110]],
				"daifclr",	["concat", ["set_var", "op1", 0b011], ["set_var", "op2", 0b111]],
				"uao", 		["concat", ["set_var", "op1", 0b000], ["set_var", "op2", 0b011]],
				"pan", 		["concat", ["set_var", "op1", 0b000], ["set_var", "op2", 0b100]],
				"allint", 	["concat", ["set_var", "op1", 0b001], ["set_var", "op2", 0b000]],
				"pm", 		["concat", ["set_var", "op1", 0b001], ["set_var", "op2", 0b000]],
				"ssbs", 	["concat", ["set_var", "op1", 0b011], ["set_var", "op2", 0b001]],
				"dit", 		["concat", ["set_var", "op1", 0b011], ["set_var", "op2", 0b010]],
				"svcrsm",	["concat", ["set_var", "op1", 0b011], ["set_var", "op2", 0b011]],
				"svcrza", 	["concat", ["set_var", "op1", 0b011], ["set_var", "op2", 0b011]],
				"svcrsmza", ["concat", ["set_var", "op1", 0b011], ["set_var", "op2", 0b011]],
				"tco", 		["concat", ["set_var", "op1", 0b011], ["set_var", "op2", 0b100]],
				["raise", "msr Error: The specified PSTATE special register was not found - Program build not possible."]
			],
			["bits", 1,1,1,1,1],
			["get_bits", ["get_var", "op2"], 0, 3],
			["get_bits", ["get_operand", 1], 0, 4],
			["bits", 0,0,1,0],
			["get_bits", ["get_var", "op1"], 0, 3],
			["bits", 0,0, 0, 0,0,1,0,1,0,1,0,1,1],
		],
		bitsize: 32
	},
]

end # Kompiler::ARMv8A

end # Kompiler
