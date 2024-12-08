# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

class ARMv8A
	
def self.sys_instructions
	@@sys_instructions
end
	
@@sys_instructions = [
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
		name: "Move to system register (register)",
		description: "Moves the contents of a general-purpose register to a system register",
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
]

end # Kompiler::ARMv8A

end # Kompiler
