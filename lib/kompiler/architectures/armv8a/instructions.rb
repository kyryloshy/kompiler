# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

class ARMv8A
	
def self.instructions
	@@instructions
end
	
@@instructions = [
	{	keyword: "mov",
		operands: [{type: "register", restrictions: {reg_size: 64}}, {type: "immediate", restrictions: {}}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["get_operand", 1], 0, 16],
			["bits", 0,0, 1,0,1,0,0,1, 0,1, 1]
		],
		bitsize: 32
	},
	{	keyword: "mov",
		operands: [{type: "register", restrictions: {reg_size: 64}}, {type: "register", restrictions: {reg_size: 64}}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["bits", 1,1,1,1,1], # rn
			["bits", 0,0,0,0,0,0], # imm6
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rm
			["bits", 0, 0,0, 0,1,0,1,0,1,0, 1]
		],
		bitsize: 32
	},
	{	keyword: "mov_sp",
		operands: [{type: "register", restrictions: {reg_size: 64}}, {type: "register", restrictions: {reg_size: 64}}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rn
			["get_bits", 0, 0, 12], # imm12 as ones
			["bits", 0, 0,1,0,0,0,1, 0, 0, 1]
		],
		bitsize: 32
	},
	{	keyword: "mvn", # MVN writes the bitwise opposite of the source register to a destination register
		description: "MVN writes the bitwise opposite of the source register to the destination register",
		operands: [{type: "register", restrictions: {reg_size: 64}, name: "Destination"}, {type: "register", restrictions: {reg_size: 64}, name: "Source"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["bits", 1,1,1,1,1], # Rn
			["bits", 0,0,0,0,0,0], # imm6 (shift amount) set to zero
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rm
			["bits", 1, 0,0, 0,1,0,1,0,1,0, 1] # N - shift type (zero / LSL) - bits
		],
		bitsize: 32
	},
	{	keyword: "mvn", # MVN writes the bitwise opposite of the source register to a destination register
		description: "MVN writes the bitwise opposite of the source register to the destination register",
		operands: [{type: "register", restrictions: {reg_size: 32}, name: "Destination"}, {type: "register", restrictions: {reg_size: 32}, name: "Source"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["bits", 1,1,1,1,1], # Rn
			["bits", 0,0,0,0,0,0], # imm6 (shift amount) set to zero
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rm
			["bits", 1, 0,0, 0,1,0,1,0,1,0, 0] # N - shift type (zero / LSL) - bits
		],
		bitsize: 32
	},
	{	keyword: "mov",
		operands: [{type: "register", restrictions: {reg_size: 32}}, {type: "immediate", restrictions: {}}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["get_operand", 1], 0, 16],
			["bits", 0,0, 1,0,1,0,0,1, 0,1, 0]
		],
		bitsize: 32
	},
	{
		keyword: "add",
		operands: [{type: "register", restrictions: {reg_size: 64}}, {type: "register", restrictions: {reg_size: 64}}, {type: "immediate", restrictions: {}}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["get_bits", ["get_operand", 2], 0, 12],
			["bits", 0, 0,1,0,0,0,1,0,0,1]
		],
		bitsize: 32
	},
	
	{
		keyword: "add",
		name: "ADD (registers)",
		description: "Adds two source registers and writes the result to the destination register",
		operands: [{type: "register", restrictions: {reg_size: 64}}, {type: "register", restrictions: {reg_size: 64}}, {type: "register", restrictions: {reg_size: 64}}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rn
			["get_bits", 0, 0, 6], # imm6
			["get_bits", ["encode_gp_register", ["get_operand", 2]], 0, 5], # Rm
			["bits", 0],
			["bits", 0,0], # shift
			["bits", 1,1,0,1,0, 0, 0, 1], # sf at the end
		],
		bitsize: 32
	},
	
	{
		keyword: "and",
		name: "And (register)",
		description: "Performs a bitwise AND of two register values and writes the result to the destination register.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 1"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 2"}],
		mc_constructor: [
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "and Error: Register sizes are not the same"]],
			["if_eq_else", ["get_key", ["get_operand", 1], :reg_size], ["get_key", ["get_operand", 2], :reg_size], [], ["raise_error", "and Error: Register sizes are not the same"]],
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rn
			["get_bits", 0, 0, 6], # imm6 (shift amount) set to zero
			["get_bits", ["encode_gp_register", ["get_operand", 2]], 0, 5],
			["bits", 0], # N
			["bits", 0,0], # shift type
			["bits", 0,1,0,1,0, 0,0],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},
	
	{
		keyword: "orr", # And between registers, with shift set to zero
		name: "Or",
		description: "Computes a logical bit-wise OR operation between two registers and writes the result to the destination register.",
		operands: [{type: "register", restrictions: {reg_size: 64}, name: "Destination"}, {type: "register", restrictions: {reg_size: 64}, name: "Register 1"}, {type: "register", restrictions: {reg_size: 64}, name: "Register 2"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["get_bits", 0, 0, 6], # imm6 (shift amount) set to zero
			["get_bits", ["encode_gp_register", ["get_operand", 2]], 0, 5],
			["bits", 0], # N
			["bits", 0,0], # shift type
			["bits", 0,1,0,1,0, 1,0, 1],
		],
		bitsize: 32
	},
	
	{
		keyword: "adr",
		operands: [{type: "register", restrictions: {reg_size: 64}}, {type: "label"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["subtract", ["get_label_address", ["get_operand", 1]], ["get_current_address"]], 2, 19],
			["bits", 0,0,0,0,1],
			["get_bits", ["subtract", ["get_label_address", ["get_operand", 1]], ["get_current_address"]], 0, 2],
			["bits", 0],
		],
		bitsize: 32
	},
	{
		keyword: "b",
		operands: [{type: "immediate"}],
		mc_constructor: [["get_bits", ["get_operand", 0], 0, 26], ["bits", 1,0,1,0,0,0]],
		bitsize: 32
	},
	{
		keyword: "b",
		operands: [{type: "label"}],
		mc_constructor: [
			["if_eq_else", ["modulo", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, [], ["raise_error", "Can't branch to the address - offset not divisible by 4 bytes."]], # Check if address is accessible
			["get_bits", ["divide", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, 26],
			["bits", 1,0,1,0,0,0]
		],
		bitsize: 32
	},
	{
		keyword: "br",
		operands: [{type: "register", restrictions: {reg_size: 64}}],
		mc_constructor: [
			["bits", 0,0,0,0,0],
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],			
			["bits", 0, 0, 0,0,0,0, 1,1,1,1,1, 0,0, 0, 0, 1,1,0,1,0,1,1]
		],
		bitsize: 32
	},
	{
		keyword: "bl",
		operands: [{type: "label"}],
		mc_constructor: [
			["if_eq_else", ["modulo", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, [], ["raise_error", "Can't branch to the address - offset not divisible by 4 bytes."]], # Check if address is accessible
			["get_bits", ["divide", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, 26],
			["bits", 1,0,1,0,0,1]
		],
		bitsize: 32
	},
	{
		keyword: "lsl",
		name: "Logical shift left (immediate)",
		description: "Logically shifts left the value in the source register by the amount specified by the immediate, and writes the result to the destination register",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Source"}, {type: "immediate", name: "Shift amount"}],
		mc_constructor: [
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "lsl Error: Register sizes are not the same"]],
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			
			["case", ["get_key", ["get_operand", 0], :reg_size], 
				64, ["concat", ["get_bits", ["subtract", 63, ["get_operand", 2]], 0, 6],
					["get_bits", ["modulo", ["multiply", ["get_operand", 2], -1], 64], 0, 6],],
				32, ["concat", ["get_bits", ["subtract", 31, ["get_operand", 2]], 0, 6],
					["get_bits", ["modulo", ["multiply", ["get_operand", 2], -1], 32], 0, 6]],
				[]
			],
			
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # N
			["bits", 0,1,1,0,0,1, 0,1],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},
	
	{
		keyword: "lsl",
		name: "Logical shift left (register)",
		description: "Logically shifts left the value in the source register by the amount specified by a variable number of bits, shifting in zeros, and writes the result to the destination register. The shift amount is equal to a modulo operation between the second register value and register size (either 64 or 32).",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Source"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Shift amount"}],
		mc_constructor: [
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "lsl Error: Register sizes are not the same"]],
			["if_eq_else", ["get_key", ["get_operand", 1], :reg_size], ["get_key", ["get_operand", 2], :reg_size], [], ["raise_error", "lsl Error: Register sizes are not the same"]],

			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			
			["bits", 0,0, 0,1,0,0],
			
			["get_bits", ["encode_gp_register", ["get_operand", 2]], 0, 5],

			["bits", 0,1,1,0,1,0,1,1, 0, 0],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},
	
	{
		keyword: "lsr",
		name: "Logical shift right (immediate)",
		description: "Logically shifts right the value in the source register by the amount specified by the immediate, and writes the result to the destination register",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Source"}, {type: "immediate", name: "Shift amount"}],
		mc_constructor: [
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "lsr Error: Register sizes are not the same"]],
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			
			["bits", 1,1,1,1,1], # imms
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # imms end
			
			["get_bits", ["get_operand", 2], 0, 6], # immr
			
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # N
			
			["bits", 0,1,1,0,0,1, 0,1],
			
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},
	
	
	{
		keyword: "lsr",
		name: "Logical shift right (register)",
		description: "Logically shifts right the value in the source register by the amount specified by a variable number of bits, shifting in zeros, and writes the result to the destination register. The shift amount is equal to a modulo operation between the second register value and register size (either 64 or 32).",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Source"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Shift amount"}],
		mc_constructor: [
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "lsl Error: Register sizes are not the same"]],
			["if_eq_else", ["get_key", ["get_operand", 1], :reg_size], ["get_key", ["get_operand", 2], :reg_size], [], ["raise_error", "lsl Error: Register sizes are not the same"]],
	
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			
			["bits", 1,0, 0,1,0,0],
			
			["get_bits", ["encode_gp_register", ["get_operand", 2]], 0, 5],
	
			["bits", 0,1,1,0,1,0,1,1, 0, 0],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},
	
	
	
	{
		# LDR immediate
		keyword: "ldr",
		operands: [{type: "register", restrictions: {reg_size: 64}}, {type: "label"}],
		mc_constructor: [
			["if_eq_else", ["modulo", ["subtract", ["get_label_address", ["get_operand", 1]], ["get_current_address"]], 4], 0, [], ["raise_error", "Can't represent address for LDR - offset not divisible by 4 bytes."]], # Check if address is accessible
			
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["divide", ["subtract", ["get_label_address", ["get_operand", 1]], ["get_current_address"]], 4], 0, 19],

			["bits", 0,0,0,1,1,0,1,0],
		],
		bitsize: 32
	},
	
	{
		keyword: "ldr",
		name: "Load Register",
		description: "Loads 4 or 8 bytes from memory at the address in the second register, and writes it to the destination register",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Source address"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["get_bits", 0, 0, 12], # Immediate offset zero			
			["bits", 1,0, 1,0, 0, 1,1,1],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []],
			["bits", 1],
		],
		bitsize: 32
	},
	
	{
		keyword: "ldr_unsigned",
		name: "Load Register (immediate), unsigned offset",
		description: "Loads 4 or 8 bytes from memory at the address in the second register with an unsigned immediate offset, and writes it to the destination register",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Source address"}, {type: "immediate", name: "Offset"}],
		mc_constructor: [
			["case", ["get_key", ["get_operand", 0], :reg_size],
				64, ["if_eq_else", ["modulo", ["get_operand", 2], 8], 0, [], ["raise_error", "ldr_unsigned Error: Unsigned offset must be divisible by 8 for 64-bit registers."]],
				32, ["if_eq_else", ["modulo", ["get_operand", 2], 4], 0, [], ["raise_error", "ldr_unsigned Error: Unsigned offset must be divisible by 4 for 32-bit registers."]],
				[]
			],
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["get_bits",
				["case", ["get_key", ["get_operand", 0], :reg_size],
					64, ["divide", ["get_operand", 2], 8],
					32, ["divide", ["get_operand", 2], 4],
					["get_operand", 2]
				],
			0, 12],			
			["bits", 1,0, 1,0, 0, 1,1,1],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []],
			["bits", 1],
		],
		bitsize: 32
	},
	
	{
		keyword: "ldrb",
		name: "Load Register Byte",
		description: "Loads a byte from memory and writes the result to the destination register.",
		operands: [{type: "register", restrictions: {reg_type: "gpr", reg_size: 32}, name: "Destination"}, {type: "register", restrictions: {reg_size: 64, reg_type: "gpr"}, name: "Source address"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["get_bits", 0, 0, 12], # Immediate offset zero			
			["bits", 1,0, 1,0, 0, 1,1,1, 0,0],
		],
		bitsize: 32
	},
	{
		keyword: "strh",
		operands: [{type: "register", restrictions: {reg_size: 32}}, {type: "register", restrictions: {reg_size: 64}}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["get_bits", 0, 0, 12], # Immediate offset zero			
			["bits", 0,0, 1,0, 0, 1,1,1, 1,0],
		],
		bitsize: 32
	},
	
	{
		keyword: "str",
		name: "Store",
		description: "Stores the contents of a 64 bit register at the address specified by the second register.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Content"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["get_bits", 0, 0, 12],	
			["bits", 0,0, 1,0, 0, 1,1,1],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []],
			["bits", 1] # size second bit always 1
		],
		bitsize: 32
	},
	
	{
		keyword: "str_unsigned",
		name: "STR (immediate), unsigned offset",
		description: "Stores the contents of a 64 bit register at the address specified by the second register with an unsigned immediate offset.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Content"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address"}, {type: "immediate", name: "Address Offset"}],
		mc_constructor: [
			["case", ["get_key", ["get_operand", 0], :reg_size],
				64, ["if_eq_else", ["modulo", ["get_operand", 2], 8], 0, [], ["raise_error", "str_unsigned Error: Unsigned offset must be divisible by 8 for 64-bit registers."]],
				32, ["if_eq_else", ["modulo", ["get_operand", 2], 4], 0, [], ["raise_error", "str_unsigned Error: Unsigned offset must be divisible by 4 for 32-bit registers."]],
				[]
			],
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["get_bits",
				["case", ["get_key", ["get_operand", 0], :reg_size],
					64, ["divide", ["get_operand", 2], 8],
					32, ["divide", ["get_operand", 2], 4],
					["get_operand", 2]
				],
			0, 12],	
			["bits", 0,0, 1,0, 0, 1,1,1],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []],
			["bits", 1] # size second bit always 1
		],
		bitsize: 32
	},
	
	
	{
		keyword: "str_pre_index",
		name: "STR (immediate), signed offset, pre-index",
		description: "Stores the contents of a general purpose register at the address specified by the second register with an immediate offset added before writing.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Content"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address"}, {type: "immediate", name: "Address Offset"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["bits", 1, 1],
			["get_bits", ["get_operand", 2], 0, 9],	
			["bits", 0, 0,0, 0,0, 0, 1,1,1],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []],
			["bits", 1] # size second bit always 1
		],
		bitsize: 32
	},
	
	{
		keyword: "str_post_index",
		name: "STR (immediate), signed offset, post-index",
		description: "Stores the contents of a general purpose register at the address specified by the second register, with an immediate offset added after writing.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Content"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address"}, {type: "immediate", name: "Address Offset"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["bits", 1, 0],
			["get_bits", ["get_operand", 2], 0, 9],	
			["bits", 0, 0,0, 0,0, 0, 1,1,1],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []],
			["bits", 1] # size second bit always 1
		],
		bitsize: 32
	},


	{
		keyword: "strb",
		name: "Store byte",
		description: "Stores the least significant byte of a 32-bit general purpose register at the address specified by the second register.",
		operands: [{type: "register", restrictions: {reg_type: "gpr", reg_size: 32}, name: "Content"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["get_bits", 0, 0, 12],	
			["bits", 0,0, 1,0, 0, 1,1,1, 0,0],
		],
		bitsize: 32
	},

	{
		keyword: "strb_unsigned",
		name: "Store byte (immediate), unsigned offset",
		description: "Stores the least significant byte of a 32-bit general purpose register at the address specified by the second register with an unsigned immediate offset.",
		operands: [{type: "register", restrictions: {reg_type: "gpr", reg_size: 32}, name: "Content"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address"}, {type: "immediate", name: "Address Offset"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["get_bits", ["get_operand", 2], 0, 12],	
			["bits", 0,0, 1,0, 0, 1,1,1, 0,0],
		],
		bitsize: 32
	},
	
	{
		keyword: "strb_post_index",
		name: "Store byte (immediate), signed post-index offset",
		description: "Stores the least significant byte of a 32-bit general purpose register at the address specified by the second register with an immediate offset added after writing.",
		operands: [{type: "register", restrictions: {reg_type: "gpr", reg_size: 32}, name: "Content"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address"}, {type: "immediate", name: "Address Offset"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["bits", 1,0],
			["get_bits", ["get_operand", 2], 0, 9],	
			["bits", 0, 0,0, 0,0, 0, 1,1,1, 0,0],
		],
		bitsize: 32
	},
	
	{
		keyword: "strb_pre_index",
		name: "Store byte (immediate), signed pre-index offset",
		description: "Stores the least significant byte of a 32-bit general purpose register at the address specified by the second register with an immediate offset added before writing.",
		operands: [{type: "register", restrictions: {reg_type: "gpr", reg_size: 32}, name: "Content"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address"}, {type: "immediate", name: "Address Offset"}],
		mc_constructor: [
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["bits", 1,1],
			["get_bits", ["get_operand", 2], 0, 9],	
			["bits", 0, 0,0, 0,0, 0, 1,1,1, 0,0],
		],
		bitsize: 32
	},
	
		
	{
		keyword: "cmp",
		name: "Compare (immediate)",
		description: "Subtracts an immediate value from a register value, and updates the condition flags based on the result.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}}, {type: "immediate"}],
		mc_constructor: [
			["bits", 1,1,1,1,1],
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["get_operand", 1], 0, 12], # Immediate value	
			["bits", 0, 0,1,0,0,0,1, 1, 1],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},
	
	{
		keyword: "cmp",
		name: "Compare (registers)",
		description: "Subtracts the second register value from the first register value, and updates the condition flags based on the result.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Register 1"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 2"}],
		mc_constructor: [
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "cmp Error: Register sizes are not the same"]],
			["bits", 1,1,1,1,1], # Rd
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rn
			["get_bits", 0, 0, 6], # Immediate offset zero (shift amount)
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rm
			["bits", 0],
			["bits", 0, 0], # Shift type
			["bits", 1,1,0,1,0,1,1],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},

	
	{
		keyword: "sub",
		name: "Subtract (immediate)",
		description: "Subtract an immediate value from a register value, and store the result in the destination register",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Source"}, {type: "immediate", name: "Immediate"}],
		mc_constructor: [
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "sub Error: Register sizes are not the same"]],
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5],
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5],
			["get_bits", ["get_operand", 2], 0, 12], # Immediate offset zero
			["bits", 0], # Shift	
			["bits", 0,1,0,0,0,1,0,1],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},
	
	{
		keyword: "sub",
		name: "Subtract (register)",
		description: "Subtract the second register value from the first register value, and store the result in the destination register",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 1 (Source)"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 2 (To subtract)"}],
		mc_constructor: [
			# Check for size
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "sub Error: Register sizes are not the same"]], 
			["if_eq_else", ["get_key", ["get_operand", 1], :reg_size], ["get_key", ["get_operand", 2], :reg_size], [], ["raise_error", "sub Error: Register sizes are not the same"]],

			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rn
			["get_bits", 0, 0, 6], # shift amount zero
			["get_bits", ["encode_gp_register", ["get_operand", 2]], 0, 5], # Rm
			["bits", 0, 0,0, 1,1,0,1,0, 0, 1],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},
	
	{
		keyword: "mul",
		name: "Multiply",
		description: "Multiply the contents of two registers, and store the output in the destination register.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 1"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 2"}],
		mc_constructor: [
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "mul Error: Register sizes are not the same"]], 
			["if_eq_else", ["get_key", ["get_operand", 1], :reg_size], ["get_key", ["get_operand", 2], :reg_size], [], ["raise_error", "mul Error: Register sizes are not the same"]],
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rn
			["bits", 1,1,1,1,1, 0], # Ra o0
			["get_bits", ["encode_gp_register", ["get_operand", 2]], 0, 5], # Rm
			["bits", 0,0,0, 1,1,0,1,1, 0,0],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},
	
	
	{
		keyword: "madd",
		name: "Multiply-Add",
		description: "Multiplies two register values, adds a third register value, and writes the result to the destination register.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 1 (to multiply)"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 2 (to multiply)"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 3 (to add)"}],
		mc_constructor: [
			# Checks for register sizes being the same
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "madd Error: Register sizes are not the same"]], 
			["if_eq_else", ["get_key", ["get_operand", 1], :reg_size], ["get_key", ["get_operand", 2], :reg_size], [], ["raise_error", "madd Error: Register sizes are not the same"]], 
			["if_eq_else", ["get_key", ["get_operand", 2], :reg_size], ["get_key", ["get_operand", 3], :reg_size], [], ["raise_error", "madd Error: Register sizes are not the same"]], 

			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rn
			["get_bits", ["encode_gp_register", ["get_operand", 3]], 0, 5], #Ra
			["bits", 0], # o0
			["get_bits", ["encode_gp_register", ["get_operand", 2]], 0, 5], # Rm
			["bits", 0,0,0, 1,1,0,1,1, 0,0],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32,
	},
	
	
	{
		keyword: "msub",
		name: "Multiply-Subtract",
		description: "Multiplies two register values, subtracts the product from a third register value, and writes the result to the destination register.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 1 (to multiply)"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 2 (to multiply)"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 3 (To subtract from)"}],
		mc_constructor: [
			# Checks for register sizes being the same
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "madd Error: Register sizes are not the same"]], 
			["if_eq_else", ["get_key", ["get_operand", 1], :reg_size], ["get_key", ["get_operand", 2], :reg_size], [], ["raise_error", "madd Error: Register sizes are not the same"]], 
			["if_eq_else", ["get_key", ["get_operand", 2], :reg_size], ["get_key", ["get_operand", 3], :reg_size], [], ["raise_error", "madd Error: Register sizes are not the same"]], 
	
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rn
			["get_bits", ["encode_gp_register", ["get_operand", 3]], 0, 5], #Ra
			["bits", 1], # o0
			["get_bits", ["encode_gp_register", ["get_operand", 2]], 0, 5], # Rm
			["bits", 0,0,0, 1,1,0,1,1, 0,0],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32,
	},
	
	
	{
		keyword: "udiv",
		name: "Unsigned Divide",
		description: "Divides an unsigned integer register value by another unsigned integer register value, and writes the result to the destination register.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 1"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 2"}],
		mc_constructor: [
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "udiv Error: Register sizes are not the same"]], 
			["if_eq_else", ["get_key", ["get_operand", 1], :reg_size], ["get_key", ["get_operand", 2], :reg_size], [], ["raise_error", "udiv Error: Register sizes are not the same"]],
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rn
			["bits", 0, 1,0,0,0,0],
			["get_bits", ["encode_gp_register", ["get_operand", 2]], 0, 5], # Rm
			["bits", 0,1,1,0,1,0,1,1, 0, 0],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},
	
	{
		keyword: "sdiv",
		name: "Signed Divide",
		description: "Divides a signed integer register value by another signed integer register value, and writes the result to the destination register.",
		operands: [{type: "register", restrictions: {reg_type: "gpr"}, name: "Destination"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 1"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Register 2"}],
		mc_constructor: [
			["if_eq_else", ["get_key", ["get_operand", 0], :reg_size], ["get_key", ["get_operand", 1], :reg_size], [], ["raise_error", "udiv Error: Register sizes are not the same"]], 
			["if_eq_else", ["get_key", ["get_operand", 1], :reg_size], ["get_key", ["get_operand", 2], :reg_size], [], ["raise_error", "udiv Error: Register sizes are not the same"]],
			["get_bits", ["encode_gp_register", ["get_operand", 0]], 0, 5], # Rd
			["get_bits", ["encode_gp_register", ["get_operand", 1]], 0, 5], # Rn
			["bits", 1, 1,0,0,0,0],
			["get_bits", ["encode_gp_register", ["get_operand", 2]], 0, 5], # Rm
			["bits", 0,1,1,0,1,0,1,1, 0, 0],
			["case", ["get_key", ["get_operand", 0], :reg_size], 64, ["bits", 1], 32, ["bits", 0], []], # sf
		],
		bitsize: 32
	},
	
	
	#
	# B.cond instructions
	#
	
	{
		keyword: "b.eq",
		name: "Branch if equal (label)",
		description: "Branches to a label if the condition is met",
		operands: [{type: "label"}],
		mc_constructor: [
			["if_eq_else", ["modulo", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, [], ["raise_error", "Can't branch to the address - offset not divisible by 4 bytes."]], # Check if address is accessible
			["bits", 0,0,0,0], # eq condition
			["bits", 0],
			["get_bits", ["divide", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	{
		keyword: "b.eq",
		name: "Branch if equal (immediate)",
		description: "Changes the PC relatively by the immediate value if the condition is met",
		operands: [{type: "immediate"}],
		mc_constructor: [
			["bits", 0,0,0,0], # eq condition
			["bits", 0],
			["get_bits", ["get_operand", 0], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	
	
	{
		keyword: "b.ne",
		name: "Branch if not equal (label)",
		description: "Branches to a label if the condition is met",
		operands: [{type: "label"}],
		mc_constructor: [
			["if_eq_else", ["modulo", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, [], ["raise_error", "Can't branch to the address - offset not divisible by 4 bytes."]], # Check if address is accessible
			["bits", 1,0,0,0], # condition
			["bits", 0],
			["get_bits", ["divide", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	{
		keyword: "b.ne",
		name: "Branch if not equal (immediate)",
		description: "Changes the PC relatively by the immediate value if the condition is met",
		operands: [{type: "immediate"}],
		mc_constructor: [
			["bits", 1,0,0,0], # condition
			["bits", 0],
			["get_bits", ["get_operand", 0], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	
	
	{
		keyword: "b.ge",
		name: "Branch if greater or equal (label)",
		description: "Branches to a label if the condition is met",
		operands: [{type: "label"}],
		mc_constructor: [
			["if_eq_else", ["modulo", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, [], ["raise_error", "Can't branch to the address - offset not divisible by 4 bytes."]], # Check if address is accessible
			["bits", 0,1,0,1], # condition
			["bits", 0],
			["get_bits", ["divide", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	{
		keyword: "b.ge",
		name: "Branch if greater or equal (immediate)",
		description: "Changes the PC relatively by the immediate value if the condition is met",
		operands: [{type: "immediate"}],
		mc_constructor: [
			["bits", 0,1,0,1], # condition
			["bits", 0],
			["get_bits", ["get_operand", 0], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	
	
	
	{
		keyword: "b.lt",
		name: "Branch if less than (label)",
		description: "Branches to a label if the condition is met",
		operands: [{type: "label"}],
		mc_constructor: [
			["if_eq_else", ["modulo", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, [], ["raise_error", "Can't branch to the address - offset not divisible by 4 bytes."]], # Check if address is accessible
			["bits", 1,1,0,1], # condition
			["bits", 0],
			["get_bits", ["divide", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	{
		keyword: "b.lt",
		name: "Branch if less than (immediate)",
		description: "Changes the PC relatively by the immediate value if the condition is met",
		operands: [{type: "immediate"}],
		mc_constructor: [
			["bits", 1,1,0,1], # condition
			["bits", 0],
			["get_bits", ["get_operand", 0], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	
	
	
	
	{
		keyword: "b.gt",
		name: "Branch if greater than (label)",
		description: "Branches to a label if the condition is met",
		operands: [{type: "label"}],
		mc_constructor: [
			["if_eq_else", ["modulo", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, [], ["raise_error", "Can't branch to the address - offset not divisible by 4 bytes."]], # Check if address is accessible
			["bits", 0,0,1,1], # condition
			["bits", 0],
			["get_bits", ["divide", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	{
		keyword: "b.gt",
		name: "Branch if greater than (immediate)",
		description: "Changes the PC relatively by the immediate value if the condition is met",
		operands: [{type: "immediate"}],
		mc_constructor: [
			["bits", 0,0,1,1], # condition
			["bits", 0],
			["get_bits", ["get_operand", 0], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	
	
	{
		keyword: "b.le",
		name: "Branch if less or equal (label)",
		description: "Branches to a label if the condition is met",
		operands: [{type: "label"}],
		mc_constructor: [
			["if_eq_else", ["modulo", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, [], ["raise_error", "Can't branch to the address - offset not divisible by 4 bytes."]], # Check if address is accessible
			["bits", 1,0,1,1], # condition
			["bits", 0],
			["get_bits", ["divide", ["subtract", ["get_label_address", ["get_operand", 0]], ["get_current_address"]], 4], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	{
		keyword: "b.le",
		name: "Branch if less or equal (immediate)",
		description: "Changes the PC relatively by the immediate value if the condition is met",
		operands: [{type: "immediate"}],
		mc_constructor: [
			["bits", 1,0,1,1], # condition
			["bits", 0],
			["get_bits", ["get_operand", 0], 0, 19],
			["bits", 0, 0,1,0,1,0,1,0],
		],
		bitsize: 32
	},
	
]

end # Kompiler::ARMv8A

end # Kompiler
