# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

module ARMv8A

	
def self.simd_fp_instructions
	@simd_fp_instructions
end

@simd_fp_instructions = [
	# {
	# 	keyword: "add",
	# 	name: "Add (vector)",
	# 	description: "Adds corresponding elements in two source SIMD&FP vector registers, and writes the result vector to the destination SIMD&FP register.",
	# 	operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
	# 	mc_constructor: [
	# 		["ensure_eq", ["get_operand_key", 0, :vec_type], ["get_operand_key", 1, :vec_type], ["get_operand_key", 2, :vec_type], "add (vector) Error: Vectors are of different sizes"],
	# 		
	# 		
	# 		["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
	# 		["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	# 	
	# 		["bits", 1, 0,0,0,0,1],
	# 	
	# 		["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	# 	
	# 		["bits", 1],
	# 	
	# 		["get_bits", ["get_operand_key", 0, :re_size], 0, 2],
	# 		["bits", 0,1,1,1,0, 0],
	# 		["get_bits", ["get_operand_key", 0, :re_q], 0, 1],
	# 		["bits", 0],	
	# 	],
	# 	bitsize: 32
	# },
	# {
	# 	keyword: "add.4s",
	# 	operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
	# 	mc_constructor: [
	# 		["alias", "add", ["encode_imm_operand", 0], ["encode_imm_operand", 0], ["get_operand", 0], ["get_operand", 1], ["get_operand", 2]],
	# 	],
	# 	bitsize: 32,
	# }
	
]

sizes = [
	{suffix: "8b", enc_size: 0b00, enc_q: 0b0},
	{suffix: "16b", enc_size: 0b00, enc_q: 0b1},
	{suffix: "4h", enc_size: 0b01, enc_q: 0b0},
	{suffix: "8h", enc_size: 0b01, enc_q: 0b1},
	{suffix: "2s", enc_size: 0b10, enc_q: 0b0},
	{suffix: "4s", enc_size: 0b10, enc_q: 0b1},
	{suffix: "2d", enc_size: 0b11, enc_q: 0b1},
]

half_and_full_sizes = [{suffix: "8b", q: 0}, {suffix: "16b", q: 1}]

sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "add.#{size[:suffix]}",
		name: "Add (vector, #{size[:suffix]})",
		description: "Adds corresponding integer elements in two source NEON vector registers, and writes the result vector to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 0,0,0,0,1],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 1],
	
			["get_bits", size[:enc_size], 0, 2],
			["bits", 0,1,1,1,0, 0],
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],	
		],
		bitsize: 32
	}
	
end
@simd_fp_instructions << {
	keyword: "add.1d",
	name: "Add (scalar, 1d)",
	description: "Adds the 64-bit integer values of two source SIMD&FP registers, and writes the result to the destination SIMD&FP register.",
	operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
	mc_constructor: [
		["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
		["get_bits", ["get_operand_key", 1, :re_num], 0, 5],

		["bits", 1, 0,0,0,0,1],
		
		["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
		
		["bits", 1, 1,1, 0,1,1,1,1, 0, 1,0],
	],
	bitsize: 32
}


sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "sub.#{size[:suffix]}",
		name: "Subtract (vector, #{size[:suffix]})",
		description: "Subtracts each integer vector element in the second source SIMD&FP register from the corresponding integer vector element in the first source SIMD&FP register, and writes the result vector to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 0,0,0,0,1],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 1],
	
			["get_bits", size[:enc_size], 0, 2],
			["bits", 0,1,1,1,0, 1],
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],	
		],
		bitsize: 32
	}
	
end
@simd_fp_instructions << {
	keyword: "sub.1d",
	name: "Subtract (scalar, 1d)",
	description: "Subtracts the 64-bit integer value of the second source SIMD&FP register from the corresponding integer value of the first source SIMD&FP register, and writes the result vector to the destination SIMD&FP register.",
	operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
	mc_constructor: [
		["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
		["get_bits", ["get_operand_key", 1, :re_num], 0, 5],

		["bits", 1, 0,0,0,0,1],
		
		["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
		
		["bits", 1, 1,1, 0,1,1,1,1, 1, 1,0],
	],
	bitsize: 32
}




# Floating point sizes for vector operations
fp_sizes = [
	{suffix: "4s", enc_size: 0b0, enc_q: 0b1},
	{suffix: "2s", enc_size: 0b0, enc_q: 0b0},
	{suffix: "2d", enc_size: 0b1, enc_q: 0b1},
]


# Floating point, half-precision sizes for vector operations
fp_hp_sizes = [
	{suffix: "4h", enc_q: 0},
	{suffix: "8h", enc_q: 1},
]

ftypes = [
	{suffix: "1h", enc_ftype: 0b11},
	{suffix: "1s", enc_ftype: 0b00},
	{suffix: "1d", enc_ftype: 0b01},
]

ftypes_no_hp = [
	{suffix: "1s", enc_ftype: 0b00},
	{suffix: "1d", enc_ftype: 0b01},
]


ftypes_no_length = [
	{suffix: "h", enc_ftype: 0b11},
	{suffix: "s", enc_ftype: 0b00},
	{suffix: "d", enc_ftype: 0b01},
]

ftypes_no_hp_no_length = [
	{suffix: "s", enc_ftype: 0b00},
	{suffix: "d", enc_ftype: 0b01},
]


fp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fadd.#{size[:suffix]}",
		name: "Floating-point add (vector, #{size[:suffix]})",
		description: "Adds corresponding floating-point elements in two source NEON vector registers, and writes the result vector to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 0,1,0,1,1],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 1],
	
			["get_bits", size[:enc_size], 0, 1],
			["bits", 0, 0,1,1,1,0, 0],
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end

fp_hp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fadd.#{size[:suffix]}",
		name: "Floating-point add (vector, #{size[:suffix]})",
		description: "Adds corresponding floating-point elements in two source NEON vector registers, and writes the result vector to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 0,1,0,0,0],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 0,1, 0, 0,1,1,1,0, 0],
	
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end


ftypes.each do |ftype|
	@simd_fp_instructions << {
		keyword: "fadd.#{ftype[:suffix]}",
		name: "Floating-point add (scalar, #{ftype[:suffix]})",
		description: "Adds corresponding floating-point values of two source NEON vector registers, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 0,1, 0, 1,0,0],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],

			["bits", 1],
		
			["get_bits", ftype[:enc_ftype], 0, 2],
			["bits", 0,1,1,1,1, 0, 0, 0],
		],
		bitsize: 32
	}
end

ins_gp_sizes = [
	{suffix: "b", size_bits: [1], n_index_bits: 4, source_gp_reg_size: 32},
	{suffix: "h", size_bits: [0, 1], n_index_bits: 3, source_gp_reg_size: 32},
	{suffix: "s", size_bits: [0, 0, 1], n_index_bits: 2, source_gp_reg_size: 32},
	{suffix: "d", size_bits: [0, 0, 0, 1], n_index_bits: 1, source_gp_reg_size: 64},
]

ins_gp_sizes.each do |ins_size|
	@simd_fp_instructions << {
		keyword: "ins.#{ins_size[:suffix]}",
		name: "Insert vector element (from general, #{ins_size[:suffix]})",
		description: "Copies the contents of the source general-purpose register to the specified vector element in the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "immediate", restrictions: {}, name: "Destination element index"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: ins_size[:source_gp_reg_size]}, name: "Source general-purpose register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 2, :reg_value], 0, 5],
	
			["bits", 1, 1,1,0,0, 0],
	
			["bits"] + ins_size[:size_bits],

			["get_bits", ["get_operand", 1], 0, ins_size[:n_index_bits]],

			["bits", 0,0,0,0,1,1,1,0, 0, 1, 0],
		],
		bitsize: 32
	}
end



ins_simd_sizes = [
	{suffix: "b", imm5_pre_bits: [1], n_index1_bits: 4, imm4_pre_bits: [], n_index2_bits: 4},
	{suffix: "h", imm5_pre_bits: [0, 1], n_index1_bits: 3, imm4_pre_bits: [0], n_index2_bits: 3},
	{suffix: "s", imm5_pre_bits: [0, 0, 1], n_index1_bits: 2, imm4_pre_bits: [0,0], n_index2_bits: 2},
	{suffix: "d", imm5_pre_bits: [0, 0, 0, 1], n_index1_bits: 1, imm4_pre_bits: [0,0,0], n_index2_bits: 1},
]

ins_simd_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "ins.#{size[:suffix]}",
		name: "Insert vector element (from SIMD&FP, #{size[:suffix]})",
		description: "Copies the specified vector element in the source SIMD&FP register to the specified vector element in the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "immediate", restrictions: {}, name: "Destination element index"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}, {type: "immediate", restrictions: {}, name: "Source element index"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
			
			["bits", 1],
			
			["bits"] + size[:imm4_pre_bits],
			["get_bits", ["get_operand", 3], 0, size[:n_index2_bits]],
			
			["bits", 0],
			
			["bits"] + size[:imm5_pre_bits],
			
			["get_bits", ["get_operand", 1], 0, size[:n_index1_bits]],
			
			["bits", 0,0,0,0,1,1,1,0, 1, 1, 0],
		],
		bitsize: 32
	}
end


mov_to_gp_sizes = [
	{suffix: "s", reg_size: 32, imm5_size_bits: [0,0,1], n_index_bits: 2, q: 0},
	{suffix: "d", reg_size: 64, imm5_size_bits: [0,0,0,1], n_index_bits: 1, q: 1},
]

mov_to_gp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "mov.#{size[:suffix]}",
		name: "Move vector element (to general, #{size[:suffix]})",
		description: "Reads the specified unsigned integer element from the source SIMD&FP register, zero extends to 32 or 64 bits, and writes the result to the destination general-purpose register.",
		operands: [{type: "register", restrictions: {reg_type: "gpr", reg_size: size[:reg_size]}, name: "Destination general-purpose register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP register"}, {type: "immediate", restrictions: {}, name: "Source vector element index"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :reg_value], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 1, 1, 1,0, 0],
	
			["bits"] + size[:imm5_size_bits],

			["get_bits", ["get_operand", 2], 0, size[:n_index_bits]],

			["bits", 0,0,0,0,1,1,1,0, 0, size[:q], 0],
		],
		bitsize: 32
	}
end



fp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fsub.#{size[:suffix]}",
		name: "Floating-point subtract (vector, #{size[:suffix]})",
		description: "Subtracts floating-point vector elements in the second source SIMD&FP register, from the corresponding elements in the first source SIMD&FP registers. and writes the result vector to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 0,1,0,1,1],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 1],
	
			["get_bits", size[:enc_size], 0, 1],
			["bits", 1, 0,1,1,1,0, 0],
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
fp_hp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fsub.#{size[:suffix]}",
		name: "Floating-point subtract (vector, #{size[:suffix]})",
		description: "Subtracts floating-point vector elements in the second source SIMD&FP register, from the corresponding elements in the first source SIMD&FP registers. and writes the result vector to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 0,1,0, 0,0],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 0,1, 1, 0,1,1,1,0, 0],
	
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
ftypes.each do |size|
	@simd_fp_instructions << {
		keyword: "fsub.#{size[:suffix]}",
		name: "Floating-point subtract (scalar, #{size[:suffix]})",
		description: "Subtracts the floating-point value of the second source SIMD&FP register from the floating-point value of the first source SIMD&FP register, and writes the result to the destination SIMD&FP register",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 0,1, 1, 1,0,0],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],

			["bits", 1],
		
			["get_bits", size[:enc_ftype], 0, 2],
			["bits", 0, 1,1,1,1, 0, 0, 0],
		],
		bitsize: 32
	}
end




fp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fsqrt.#{size[:suffix]}",
		name: "Floating-point square root (vector, #{size[:suffix]})",
		description: "Calculates the square root of each floating-point vector element in the source SIMD&FP register, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector registe"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 0,1, 1,1,1,1,1, 0,0,0,0,1],
	
			["get_bits", size[:enc_size], 0, 1],
			["bits", 1, 0,1,1,1,0, 1],
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
fp_hp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fsqrt.#{size[:suffix]}",
		name: "Floating-point square root (vector, #{size[:suffix]})",
		description: "Calculates the square root of each floating-point vector element in the source SIMD&FP register, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector registe"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 0,1, 1,1,1,1,1, 0,0,1,1,1,1, 1, 0,1,1,1,0, 1],
	
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
ftypes.each do |size|
	@simd_fp_instructions << {
		keyword: "fsqrt.#{size[:suffix]}",
		name: "Floating-point square root (scalar, #{size[:suffix]})",
		description: "Calculates the square root of the value in the source SIMD&FP register, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector registe"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 0,0,0,0,1, 1,1, 0,0,0,0, 1],
	
			["get_bits", size[:enc_ftype], 0, 2],
			["bits", 0, 1,1,1,1, 0, 0, 0],
		],
		bitsize: 32
	}
end





fp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fmul.#{size[:suffix]}",
		name: "Floating-point multiply (vector, #{size[:suffix]})",
		description: "Multiplies the corresponding floating-point elements in two source SIMD&FP registers, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 1,1,0,1,1],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 1],
	
			["get_bits", size[:enc_size], 0, 1],
			["bits", 0, 0,1,1,1,0, 1],
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
fp_hp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fmul.#{size[:suffix]}",
		name: "Floating-point multiply (vector, #{size[:suffix]})",
		description: "Multiplies the corresponding floating-point elements in two source SIMD&FP registers, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 1,1,0, 0,0],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 0,1, 0, 0,1,1,1,0, 1],
	
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
ftypes.each do |size|
	@simd_fp_instructions << {
		keyword: "fmul.#{size[:suffix]}",
		name: "Floating-point multiply (scalar, #{size[:suffix]})",
		description: "Multiplies the floating-point values of two source SIMD&FP registers, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 0,1, 0,0,0, 0],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],

			["bits", 1],
		
			["get_bits", size[:enc_ftype], 0, 2],
			["bits", 0,1,1,1,1, 0, 0, 0],
		],
		bitsize: 32
	}
end

ftypes.each do |ftype_1|
	ftypes.each do |ftype_2|
		next if ftype_1 == ftype_2
		
		@simd_fp_instructions << {
			keyword: "fcvt.#{ftype_1[:suffix]}_to_#{ftype_2[:suffix]}",
			name: "Floating-point convert precision (scalar, #{ftype_1[:suffix]} to #{ftype_2[:suffix]})",
			description: "Converts the floating-point value in the SIMD&FP source register to the precision of the destination data type using the rounding mode determined by the FPCR system register, and writes the result to the destination SIMD&FP register.",
			operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
			mc_constructor: [
				["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
				["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
		
				["bits", 0,0,0,0,1],
		
				["get_bits", ftype_2[:enc_ftype], 0, 2],
				
				["bits", 1,0,0,0, 1],
			
				["get_bits", ftype_1[:enc_ftype], 0, 2],
				["bits", 0,1,1,1,1, 0, 0, 0],
			],
			bitsize: 32
		}
	end
end


# ftypes.each do |ftype|
# 	[{reg_size: 32, sf: 0}, {reg_size: 64, sf: 1}].each do |reg_size|
# 		@simd_fp_instructions << {
# 			keyword: "fcvt.#{ftype_1[:suffix]}_to_#{ftype_2[:suffix]}",
# 			name: "Floating-point convert precision (scalar, #{ftype_1[:suffix]} to #{ftype_2[:suffix]})",
# 			description: "Converts the floating-point value in the SIMD&FP source register to the precision of the destination data type using the rounding mode determined by the FPCR system register, and writes the result to the destination SIMD&FP register.",
# 			operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
# 			mc_constructor: [
# 				["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
# 				["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
# 		
# 				["bits", 0,0,0,0,1],
# 		
# 				["get_bits", ftype_2[:enc_ftype], 0, 2],
# 				
# 				["bits", 1,0,0,0, 1],
# 			
# 				["get_bits", ftype_1[:enc_ftype], 0, 2],
# 				["bits", 0,1,1,1,1, 0, 0, 0],
# 			],
# 			bitsize: 32
# 		}
# 	end
# end

@simd_fp_instructions << {
	keyword: "faddp.h",
	name: "Floating-point add pair of elements (scalar, h)",
	description: "Adds two floating-point vector elements in the source SIMD&FP register and writes the scalar result to the destination SIMD&FP register.",
	operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
	mc_constructor: [
		["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
		["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
		
		["bits", 0,1, 1,0,1,1,0, 0,0,0,1,1],
		
		["bits", 0], # sz
		
		["bits", 0, 0,1,1,1,1, 0, 1,0],
	],
	bitsize: 32
}

[{suffix: "s", sz: 0}, {suffix: "d", sz: 1}].each do |size|
	@simd_fp_instructions << {
		keyword: "faddp.#{size[:suffix]}",
		name: "Floating-point add pair of elements (scalar, #{size[:suffix]})",
		description: "Adds two floating-point vector elements in the source SIMD&FP register and writes the scalar result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 0,1, 1,0,1,1,0, 0,0,0,1,1],
			
			["bits", size[:sz]], # sz
			
			["bits", 0, 0,1,1,1,1, 1, 1,0],
		],
		bitsize: 32
	}
end


ftypes.each do |size|
	@simd_fp_instructions << {
		keyword: "fcmp.#{size[:suffix]}",
		name: "Floating-point compare (scalar, #{size[:suffix]})",
		description: "Compares the floating-point values of two source SIMD&FP registers, and updates the PSTATE N, Z, C, V flags based on the result.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP register 2"}],
		mc_constructor: [
			["bits", 0,0,0, 0,0],
			
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			
			["bits", 0,0,0,1, 0,0],
			
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 1],
			
			["get_bits", size[:enc_ftype], 0, 2],
			["bits", 0, 1,1,1,1, 0, 0, 0],
		],
		bitsize: 32
	}
end

ftypes.each do |size|
	@simd_fp_instructions << {
		keyword: "fcmpz.#{size[:suffix]}",
		name: "Floating-point compare to zero (scalar, #{size[:suffix]})",
		description: "Compares the floating-point value of the source SIMD&FP register with zero, and updates the PSTATE N, Z, C, V flags based on the result.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP register"}],
		mc_constructor: [
			["bits", 0,0,0, 1,0],
			
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			
			["bits", 0,0,0,1, 0,0],
			
			["get_bits", 0, 0, 5], # Rm = 0
			
			["bits", 1],
			
			["get_bits", size[:enc_ftype], 0, 2],
			["bits", 0, 1,1,1,1, 0, 0, 0],
		],
		bitsize: 32
	}
end


ftypes_no_length.each do |size|
	@simd_fp_instructions << {
		keyword: "scvtf.#{size[:suffix]}",
		name: "Signed integer convert to floating-point (scalar, #{size[:suffix]})",
		description: "Converts the signed integer in the source general-purpose register to a floating-point value using the rounding mode specified by the FPCR system register, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP register"}, {type: "register", restrictions: {reg_type: "gpr"}, name: "Source general-purpose register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :reg_value], 0, 5],
			
			["bits", 0,0,0,0,0,0, 0,1,0, 0,0, 1],
			
			["get_bits", size[:enc_ftype], 0, 2],
			
			["bits", 0,1,1,1,1, 0, 0],
			
			["case", ["get_key", ["get_operand", 1], :reg_size], 64, ["bits", 1], 32, ["bits", 0], 0],
		],
		bitsize: 32
	}
end



fp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "scvtf.#{size[:suffix]}",
		name: "Signed integer convert to floating-point (vector, #{size[:suffix]})",
		description: "Converts each signed integer element in the source SIMD&FP register to floating-point elements using the rounding mode specified in FPCR, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 0,1, 1,0,1,1,1, 0,0,0,0,1],
			
			["get_bits", size[:enc_size], 0, 1],
			["bits", 0, 0,1,1,1,0, 0],
			["get_bits", size[:enc_q], 0, 1],
			
			["bits", 0],
		],
		bitsize: 32
	}
end
fp_hp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "scvtf.#{size[:suffix]}",
		name: "Signed integer convert to floating-point (vector, #{size[:suffix]})",
		description: "Converts each signed integer element in the source SIMD&FP register to floating-point elements using the rounding mode specified in FPCR, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 0,1, 1,0,1,1,1, 0,0,1,1,1,1, 0, 0,1,1,1,0, 0],
			
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
ftypes_no_hp.each do |size|
	@simd_fp_instructions << {
		keyword: "scvtf.#{size[:suffix]}",
		name: "Signed integer convert to floating-point (vector, #{size[:suffix]})",
		description: "Converts each signed integer element in the source SIMD&FP register to floating-point elements using the rounding mode specified in FPCR, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 0,1, 1,0,1,1,1, 0,0,0,0,1],
			
			["get_bits", size[:enc_ftype], 0, 1],
			["bits", 0, 0,1,1,1,1, 0, 1,0],
		],
		bitsize: 32
	}
end
@simd_fp_instructions << {
	keyword: "scvtf.1h",
	name: "Signed integer convert to floating-point (vector, 1h)",
	description: "Converts each signed integer element in the source SIMD&FP register to floating-point elements using the rounding mode specified in FPCR, and writes the result to the destination SIMD&FP register.",
	operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
	mc_constructor: [
		["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
		["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
		
		["bits", 0,1, 1,0,1,1,1, 0,0,1,1,1,1, 0, 0,1,1,1,1, 0, 1,0],
	],
	bitsize: 32
}


[{suffix: "8b", q: 0}, {suffix: "16b", q: 1}].each do |size|
	@simd_fp_instructions << {
		keyword: "mov.#{size[:suffix]}",
		name: "Move vector (#{size[:suffix]})",
		description: "Copies the vector in the source SIMD&FP register into the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 1],
			["bits", 1,1,0,0,0],
			
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 1, 0,1, 0,1,1,1,0, 0],
			
			["bits", size[:q], 0],
		],
		bitsize: 32
	}
end





@simd_fp_instructions << {
	keyword: "fcvts.n.1h",
	name: "Floating-point convert to signed integer (vector, 1h)",
	description: "Converts each floating-point element in the source SIMD&FP register to a signed integer using the \"Round to Nearest\" rounding mode, and writes the result to the destination SIMD&FP register.",
	operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
	mc_constructor: [
		["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
		["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
		
		["bits", 0,1, 0, 1,0,1,1, 0,0,1,1,1,1, 0, 0,1,1,1,1, 0, 1,0],
	],
	bitsize: 32
}
ftypes_no_hp.each do |size|
	@simd_fp_instructions << {
		keyword: "fcvts.n.#{size[:suffix]}",
		name: "Floating-point convert to signed integer (vector, #{size[:suffix]})",
		description: "Converts each floating-point element in the source SIMD&FP register to a signed integer using the \"Round to Nearest\" rounding mode, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 0,1, 0, 1,0,1,1, 0,0,0,0,1],
			
			["get_bits", size[:enc_ftype], 0, 1],
			
			["bits", 0, 0,1,1,1,1, 0, 1,0],
		],
		bitsize: 32
	}
end
fp_hp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fcvts.n.#{size[:suffix]}",
		name: "Floating-point convert to signed integer (vector, #{size[:suffix]})",
		description: "Converts each floating-point element in the source SIMD&FP register to a signed integer using the \"Round to Nearest\" rounding mode, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 0,1, 0, 1,0,1,1, 0,0,1,1,1,1, 0, 0,1,1,1,0, 0],
			
			["get_bits", size[:enc_q], 0, 1],
			
			["bits", 0],
		],
		bitsize: 32
	}
end
fp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fcvts.n.#{size[:suffix]}",
		name: "Floating-point convert to signed integer (vector, #{size[:suffix]})",
		description: "Converts each floating-point element in the source SIMD&FP register to a signed integer using the \"Round to Nearest\" rounding mode, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 0,1, 0, 1,0,1,1, 0,0,0,0,1],
			
			["get_bits", size[:enc_size], 0, 1],
			
			["bits", 0, 0,1,1,1,0, 0],
			
			["get_bits", size[:enc_q], 0, 1],
			
			["bits", 0],
		],
		bitsize: 32
	}
end





fp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fdiv.#{size[:suffix]}",
		name: "Floating-point divide (vector, #{size[:suffix]})",
		description: "Divides the floating-point elements in the elements in the first source SIMD&FP register by the elements in the second source SIMD&FP register, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 1,1,1,1,1],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 1],
	
			["get_bits", size[:enc_size], 0, 1],
			["bits", 0, 0,1,1,1,0, 1],
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
fp_hp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fdiv.#{size[:suffix]}",
		name: "Floating-point divide (vector, #{size[:suffix]})",
		description: "Divides the floating-point elements in the elements in the first source SIMD&FP register by the elements in the second source SIMD&FP register, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 1,1,1, 0,0],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 0,1, 0, 0,1,1,1,0, 1],
	
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
ftypes.each do |size|
	@simd_fp_instructions << {
		keyword: "fdiv.#{size[:suffix]}",
		name: "Floating-point divide (scalar, #{size[:suffix]})",
		description: "Divides the floating-point elements in the elements in the first source SIMD&FP register by the elements in the second source SIMD&FP register, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 0,1, 1,0,0,0],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],

			["bits", 1],
		
			["get_bits", size[:enc_ftype], 0, 2],
			["bits", 0,1,1,1,1, 0, 0, 0],
		],
		bitsize: 32
	}
end



half_and_full_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "eor.#{size[:suffix]}",
		name: "Bitwise exclusive-OR (#{size[:suffix]})",
		description: "Performs a bitwise exclusive-OR operation between the two source SIMD&FP registers, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 1,1,0,0,0],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 1, 0,0, 0,1,1,1,0, 1],
		
			["get_bits", size[:q], 0, 2],
			["bits", 0],
		],
		bitsize: 32
	}
end




fp_hp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fmla.#{size[:suffix]}",
		name: "Floating-point multiply-add to accumulator (vector, #{size[:suffix]})",
		description: "Multiplies the corresponding floating-point elements in the first and second source SIMD&FP registers, adds the result and the corresponding floating-point elements in the destination SIMD&FP register (accumulates), and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register (accumulator)"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 1,0,0, 0,0],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 0,1, 0, 0,1,1,1,0, 0],
	
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
fp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fmla.#{size[:suffix]}",
		name: "Floating-point multiply-add to accumulator (vector, #{size[:suffix]})",
		description: "Multiplies the corresponding floating-point elements in the first and second source SIMD&FP registers, adds the result and the corresponding floating-point elements in the destination SIMD&FP register (accumulates), and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register (accumulator)"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 1"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register 2"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
	
			["bits", 1, 1,0,0,1,1],
	
			["get_bits", ["get_operand_key", 2, :re_num], 0, 5],
	
			["bits", 1],
	
			["get_bits", size[:enc_size], 0, 1],
			["bits", 0, 0,1,1,1,0, 0],
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end


ldr_sizes = [
	{suffix: "b", enc_size: 0b00, enc_opc_bit2: 0, bytesize: 1},
	{suffix: "h", enc_size: 0b01, enc_opc_bit2: 0, bytesize: 2},
	{suffix: "s", enc_size: 0b10, enc_opc_bit2: 0, bytesize: 4},
	{suffix: "d", enc_size: 0b11, enc_opc_bit2: 0, bytesize: 8},
	{suffix: "q", enc_size: 0b00, enc_opc_bit2: 1, bytesize: 16},
]


ldr_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "ldr.#{size[:suffix]}",
		name: "Load SIMD&FP Register (#{size[:suffix]})",
		description: "Loads the specified amount from memory at the address in the source general-purpose register, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP register"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address source general-purpose register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :reg_value], 0, 5],
	
			["get_bits", 0, 0, 12], # imm12
			
			["bits", 1, size[:enc_opc_bit2]],
			
			["bits", 1,0, 1, 1,1,1],
			
			["get_bits", size[:enc_size], 0, 2],
		],
		bitsize: 32
	}
end
ldr_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "ldr.unsigned.#{size[:suffix]}",
		name: "Load SIMD&FP Register (immediate, unsigned offset, #{size[:suffix]})",
		description: "Loads the specified amount from memory at the address in in the source general-purpose register, with a signed immediate offset added, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP register"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address source general-purpose register"}, {type: "immediate", name: "Unsigned offset"}],
		mc_constructor: [
			["if_eq_else", ["modulo", ["get_operand", 2], size[:bytesize]], 0, [], ["raise_error", "ldr (immediate) Error: Immediate offset is not divisible by #{size[:bytesize].to_s}."]],
			
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :reg_value], 0, 5],
			
			["get_bits", ["divide", ["get_operand", 2], size[:bytesize]], 0, 12], # imm12
			
			["bits", 1, size[:enc_opc_bit2]],
			
			["bits", 1,0, 1, 1,1,1],
			
			["get_bits", size[:enc_size], 0, 2],
		],
		bitsize: 32
	}
end
ldr_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "ldr.post_index.#{size[:suffix]}",
		name: "Load SIMD&FP Register (immediate, signed post-index offset, #{size[:suffix]})",
		description: "Loads the specified amount from memory at the address in in the source general-purpose register, with a signed immediate offset added permanently after reading, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP register"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address source general-purpose register"}, {type: "immediate", name: "Signed offset"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :reg_value], 0, 5],
			
			["bits", 1,0],
			
			["get_bits", ["get_operand", 2], 0, 9], # imm9
			
			["bits", 0],
			["bits", 1, size[:enc_opc_bit2]],
			["bits", 0,0, 1, 1,1,1],
			["get_bits", size[:enc_size], 0, 2],
		],
		bitsize: 32
	}
end
ldr_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "ldr.pre_index.#{size[:suffix]}",
		name: "Load SIMD&FP Register (immediate, signed pre-index offset, #{size[:suffix]})",
		description: "Loads the specified amount from memory at the address in in the source general-purpose register, with a signed immediate offset added permanently before reading, and writes the result to the destination SIMD&FP register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP register"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address source general-purpose register"}, {type: "immediate", name: "Signed offset"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :reg_value], 0, 5],
			
			["bits", 1,1],
			
			["get_bits", ["get_operand", 2], 0, 9], # imm9
			
			["bits", 0],
			["bits", 1, size[:enc_opc_bit2]],
			["bits", 0,0, 1, 1,1,1],
			["get_bits", size[:enc_size], 0, 2],
		],
		bitsize: 32
	}
end





ldr_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "str.#{size[:suffix]}",
		name: "Store SIMD&FP Register (#{size[:suffix]})",
		description: "Stores a SIMD&FP register of the specified size to memory at the address in the source general-purpose register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP register"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address source general-purpose register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :reg_value], 0, 5],
			
			["get_bits", 0, 0, 12], # imm12
			
			["bits", 0, size[:enc_opc_bit2]],
			
			["bits", 1,0, 1, 1,1,1],
			
			["get_bits", size[:enc_size], 0, 2],
		],
		bitsize: 32
	}
end
ldr_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "str.unsigned.#{size[:suffix]}",
		name: "Store SIMD&FP Register (immediate, unsigned offset, #{size[:suffix]})",
		description: "Stores a SIMD&FP register of the specified size to memory at the address in the source general-purpose register with an unsigned immediate offset added.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP register"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address source general-purpose register"}, {type: "immediate", name: "Unsigned offset"}],
		mc_constructor: [
			["if_eq_else", ["modulo", ["get_operand", 2], size[:bytesize]], 0, [], ["raise_error", "ldr (immediate) Error: Immediate offset is not divisible by #{size[:bytesize].to_s}."]],
			
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :reg_value], 0, 5],
			
			["get_bits", ["divide", ["get_operand", 2], size[:bytesize]], 0, 12], # imm12
			
			["bits", 0, size[:enc_opc_bit2]],
			
			["bits", 1,0, 1, 1,1,1],
			
			["get_bits", size[:enc_size], 0, 2],
		],
		bitsize: 32
	}
end
ldr_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "str.post_index.#{size[:suffix]}",
		name: "Store SIMD&FP Register (immediate, signed post-index offset, #{size[:suffix]})",
		description: "Stores a SIMD&FP register of the specified size to memory at the address in the source general-purpose register with a signed immediate offset permanently added after writing.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP register"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address source general-purpose register"}, {type: "immediate", name: "Signed offset"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :reg_value], 0, 5],
			
			["bits", 1,0],
			
			["get_bits", ["get_operand", 2], 0, 9], # imm9
			
			["bits", 0],
			["bits", 0, size[:enc_opc_bit2]],
			["bits", 0,0, 1, 1,1,1],
			["get_bits", size[:enc_size], 0, 2],
		],
		bitsize: 32
	}
end
ldr_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "str.pre_index.#{size[:suffix]}",
		name: "Store SIMD&FP Register (immediate, signed pre-index offset, #{size[:suffix]})",
		description: "Stores a SIMD&FP register of the specified size to memory at the address in the source general-purpose register with a signed immediate offset permanently added before writing.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP register"}, {type: "register", restrictions: {reg_type: "gpr", reg_size: 64}, name: "Address source general-purpose register"}, {type: "immediate", name: "Signed offset"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :reg_value], 0, 5],
			
			["bits", 1,1],
			
			["get_bits", ["get_operand", 2], 0, 9], # imm9
			
			["bits", 0],
			["bits", 0, size[:enc_opc_bit2]],
			["bits", 0,0, 1, 1,1,1],
			["get_bits", size[:enc_size], 0, 2],
		],
		bitsize: 32
	}
end






fp_hp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fabs.#{size[:suffix]}",
		name: "Floating-point absolute value (vector, #{size[:suffix]})",
		description: "Calculates the absolute value of each floating-point element in the source SIMD&FP register, and writes the result to the destination register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 0,1, 1,1,1,1,0, 0,0,1,1,1,1, 1, 0,1,1,1,0, 0],
			
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
fp_sizes.each do |size|
	@simd_fp_instructions << {
		keyword: "fabs.#{size[:suffix]}",
		name: "Floating-point absolute value (vector, #{size[:suffix]})",
		description: "Calculates the absolute value of each floating-point element in the source SIMD&FP register, and writes the result to the destination register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 0,1, 1,1,1,1,0, 0,0,0,0,1],
				
			["get_bits", size[:enc_size], 0, 1],
			["bits", 1, 0,1,1,1,0, 0],
			["get_bits", size[:enc_q], 0, 1],
			["bits", 0],
		],
		bitsize: 32
	}
end
ftypes.each do |size|
	@simd_fp_instructions << {
		keyword: "fabs.#{size[:suffix]}",
		name: "Floating-point absolute value (scalar, #{size[:suffix]})",
		description: "Calculates the absolute value of each floating-point element in the source SIMD&FP register, and writes the result to the destination register.",
		operands: [{type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Destination SIMD&FP vector register"}, {type: "register", restrictions: {reg_type: "simd_fp_reg"}, name: "Source SIMD&FP vector register"}],
		mc_constructor: [
			["get_bits", ["get_operand_key", 0, :re_num], 0, 5],
			["get_bits", ["get_operand_key", 1, :re_num], 0, 5],
			
			["bits", 0,0,0,0,1, 1,0, 0,0,0,0, 1],
			
			["get_bits", size[:enc_ftype], 0, 2],
			["bits", 0,1,1,1,1, 0, 0, 0],
		],
		bitsize: 32
	}
end







end # Kompiler::ARMv8A

end # Kompiler
