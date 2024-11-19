# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

class Directives

def self.directives
	@@DIRECTIVES
end

@@DIRECTIVES = [
	{
		keyword: "zeros",
		func: lambda do |operands, state|
			raise "Incorrect use of the \"zeros\" directive." if operands.size > 1 || (operands[0] && operands[0][:type] != "immediate")
			n_zeros = operands[0][:value]
			state[:current_address] += n_zeros
			state[:parsed_lines] << {type: "insert", bits: (n_zeros*8).times.map{0} }
			state
		end
	},
	{
		keyword: "ascii",
		func: lambda do |operands, state|
			raise "Incorrect use of the \"ascii\" directive." if operands.size > 1 || (operands[0] && operands[0][:type] != "string")
			
			insert_bytes = operands[0][:string].encode("ascii").bytes
			insert_bits = insert_bytes.map{|byte| 8.times.map{|bit_i| byte[bit_i]}}.flatten
			
			state[:parsed_lines] << {type: "insert", bits: insert_bits, address: state[:current_address]}
			state[:current_address] += insert_bytes.size
			
			state
		end
	},
	{
		keyword: "align",
		func: lambda do |operands, state|
			raise "Incorrect use of the \"align\" directive." if operands.size > 1 || (operands[0] && operands[0][:type] != "immediate")
			
			alignment = operands[0][:value]
			to_add = alignment - (state[:current_address] % alignment)			
			
			# If aligned, do nothing
			return state if to_add == alignment
			
			# Else add stuff
			
			state[:current_address] += to_add
			state[:parsed_lines] << {type: "insert", bits: (to_add * 8).times.map{0} }
			
			state
		end
	},
	{
		keyword: "label",
		func: lambda do |operands, state|
			
			raise "Incorrect use of the \"label\" directive." if (operands.size < 1 || operands.size > 2) || (operands[0] && operands[0][:type] != "label")
			
			raise "Incorrect use of the \"label\" directive: second argument must be an immediate value" if operands[1] && operands[1][:type] != "immediate"
			
			label_name = operands[0][:value]
			
			# If a second argument is provided, use it as the label value; otherwise use the current instruction address (PC)
			if operands[1] && operands[1][:type] == "immediate"
				label_value = operands[1][:value]
			else
				label_value = state[:current_address]
			end
			
			# Add the label definition
			state[:parsed_lines] << {type: "label", label_name: label_name, label_address: label_value, address: state[:current_address]}
			
			state
		end
	},
	{
		keyword: "8byte",
		func: lambda do |operands, state|
			
			raise "Incorrect use of the \"8byte\" directive." if (operands.size != 1) || (operands[0] && operands[0][:type] != "immediate")			
			
			value = operands[0][:value]
			
			value_bits = (0...(8 * 8)).map{|bit_i| value[bit_i]}
			
			# Insert 64 bits of the value into the program
			state[:current_address] += 8
			state[:parsed_lines] << {type: "insert", bits: value_bits}
			
			state
		end
	},
	{
		keyword: "4byte",
		func: lambda do |operands, state|
			
			raise "Incorrect use of the \"4byte\" directive." if (operands.size != 1) || (operands[0] && operands[0][:type] != "immediate")			
			
			value = operands[0][:value]
			
			value_bits = (0...(4 * 8)).map{|bit_i| value[bit_i]}
			
			# Insert 64 bits of the value into the program
			state[:current_address] += 4
			state[:parsed_lines] << {type: "insert", bits: value_bits}
			
			state
		end
	},
	{
		keyword: "bytes",
		func: lambda do |operands, state|
			
			raise "Incorrect use of the \"bytes\" directive." if (operands.size != 2) || (operands[0][:type] != "immediate" && operands[1][:type] != "immediate")			
			
			n_bytes = operands[0][:value]
			value = operands[1][:value]
			
			value_bits = (0...(n_bytes * 8)).map{|bit_i| value[bit_i]}
			
			# Insert the input amount of bytes of the value into the program
			state[:current_address] += n_bytes
			state[:parsed_lines] << {type: "insert", bits: value_bits}
			
			state
		end
	},
	{
		keyword: "set_pc",
		func: lambda do |operands, state|
			
			raise "Incorrect use of the \"set_pc\" directive." if (operands.size != 1) || (operands[0][:type] != "immediate")			
			
			new_pc = operands[0][:value]

			state[:current_address] = new_pc
			
			state
		end
	},
	{
		keyword: "insert_file",
		func: lambda do |operands, state|
			raise "Incorrect use of the \"insert_file\" directive" if (operands.size != 1) || (operands[0][:type] != "string")

			filename = operands[0][:string]

			file_content = ""
			File.open(filename, "rb") do |f|
				file_content = f.read()
			end

			state[:current_address] += file_content.bytes.size
			state[:parsed_lines] << {type: "insert", byte_string: file_content}

			state
		end
	}
]


end # Kompiler::Directives

end # Kompiler