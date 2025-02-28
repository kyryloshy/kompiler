# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

module CompilerFunctions

def self.parse_code(lines)	
	
	parsed_lines = []
	
	instr_adr = 0
	
	line_i = 0

	extra_state = Hash.new
	
	add_later_directives = []
	
	while line_i < lines.size
		line = lines[line_i]
		
		# Check if line is not just whitespace
		is_char_whitespace = line.each_char.map{|c| Kompiler::Config.whitespace_chars.include? c}
		if !is_char_whitespace.include?(false) # If only whitespace
			line_i += 1
			next # Skip
		end
		
		is_instruction, exec_instruction = Kompiler::Parsers.check_instruction(line)
		if is_instruction
			parsed_lines << {type: "instruction", instruction: exec_instruction[:instruction], operands: exec_instruction[:operands], address: instr_adr}			
			instr_adr += exec_instruction[:instruction][:bitsize] / 8

			line_i += 1
		
			next # Go to the next line
		end
		
		
		is_directive, directive_hash = Kompiler::Parsers.check_directive(line)
		if is_directive
			directive = directive_hash[:directive]
			operands = directive_hash[:operands]
			
			state = {current_address: instr_adr, parsed_lines: parsed_lines, lines: lines, line_i: line_i, extra_state: extra_state}
			
			add_later_directive = false
			
			if directive.keys.include?(:add_later_directive) && directive[:add_later_directive] == true
				add_later_directive = true
			end
			
			new_operands = operands.map do |op|
				if op[:type] == "run_block"
					begin
						block_state = state.dup
						block_state[:block_args] = op[:block_args]
						block_state[:labels] = self.get_labels(parsed_lines)
						op = op[:block].call(block_state)
					rescue
						add_later_directive = true
						op = {type: "immediate", value: 0, def_type: "kompiler_test_value", definition: "0"}
					end
				end
				op
			end
			
			
			if add_later_directive
				
				try_state = {current_address: instr_adr, parsed_lines: parsed_lines.dup, lines: lines.dup, line_i: line_i, extra_state: extra_state.dup}
				
				try_state = directive[:func].call(new_operands, try_state)
				
				
				instr_adr = try_state[:current_address]
				line_i = try_state[:line_i]
				
				raise "Directive error 1.1" if !(lines == try_state[:lines])
				raise "Directive error 1.2" if !(extra_state == try_state[:extra_state])
				raise "Directive error 1.3" if !(parsed_lines == try_state[:parsed_lines][...parsed_lines.size]) # Check that the previous parsed lines were not changed by the directive
				
				state.delete :parsed_lines
				state.delete :lines
				
				add_later_directives << {directive_hash: directive_hash, insert_i: parsed_lines.size, run_state: state, return_line_i: line_i, return_current_address: instr_adr}
				
				next
			end
			
			state = directive[:func].call(new_operands, state)
		
			instr_adr = state[:current_address]
			parsed_lines = state[:parsed_lines]
			lines = state[:lines]
			line_i = state[:line_i]
			extra_state = state[:extra_state]
			
			next # Skip to the next lime
		end
		
		
		# Line wasn't classified
		# Throw an error
		
		raise "\"#{line}\" - Unknown syntax: Program build not possible"
		
	end	

	add_later_directives.sort_by{|hash| hash[:insert_i]}.reverse.each do |add_later_directive|
		directive_hash = add_later_directive[:directive_hash]
		insert_i = add_later_directive[:insert_i]
		state = add_later_directive[:run_state]
		
		state[:parsed_lines] = parsed_lines[...insert_i]
		state[:lines] = lines
		
		directive = directive_hash[:directive]
		operands = directive_hash[:operands]
		
		new_operands = operands.map do |op|
			if op[:type] == "run_block"
				block_state = state.dup
				block_state[:block_args] = op[:block_args]
				block_state[:labels] = self.get_labels(parsed_lines)
				op = op[:block].call(block_state)
			end
			op
		end
		
		state = directive[:func].call(new_operands, state)
		
		
		raise "Directive error 2.1" if add_later_directive[:return_current_address] != state[:current_address]
		raise "Directive error 2.2" if add_later_directive[:return_line_i] != state[:line_i]
		
		
		parsed_lines = state[:parsed_lines] + parsed_lines[insert_i..]
	end
	
	parsed_lines
end


def self.get_labels(parsed_lines)

	label_definitions = parsed_lines.filter{|line| line[:type] == "label"}
	
	labels_hash = Hash.new
	
	label_definitions.each do |label_def|
		if labels_hash.keys.include?(label_def[:label_name])
			puts "Warning: Label #{label_def[:label_name]} was aleady defined. Label is now re-defined"
		end
		
		labels_hash[label_def[:label_name]] = label_def[:label_address]
	end

	labels_hash
end


def self.construct_program_mc(parsed_lines, labels)
	
	lines_bytes = ""
	
	
	program_state = {labels: labels, current_address: 0, instruction_variables: {}}
	
	parsed_lines.each do |line|
		case line[:type]
		when "instruction"
			program_state[:current_address] = line[:address]
			
			operands = line[:operands]
			operands.map! do |op|
				if op[:type] == "run_block"
					state = program_state.dup
					state[:block_args] = op[:block_args]
					op = op[:block].call(state)
				end
				op
			end
			
			program_state[:operands] = operands
			
			
			mc_constructor = line[:instruction][:mc_constructor]
			
			instr_bits = Kompiler::MachineCode_AST.build_mc(mc_constructor, program_state)			
			program_state[:instruction_variables] = Hash.new # Clear the instruction variables after running the instruction

			instr_bytes = bits_to_bytes(instr_bits)
			
			lines_bytes += instr_bytes.map(&:chr).join
		when "insert"
			if line[:bits]
				lines_bytes += bits_to_bytes(line[:bits]).map(&:chr).join
			elsif line[:bytes]
				lines_bytes += line[:bytes].map(&:chr).join
			elsif line[:byte_string]
				lines_bytes += line[:byte_string]
			end
		end
	end
	
	lines_bytes
end


def self.bits_to_bytes(bits)

	bit_byte_groups = (0...(bits.size / 8)).map{|byte_i| bits[(byte_i * 8)...(byte_i * 8 + 8)] }

	bytes = []


	bit_byte_groups.each do |byte_bits|
		byte_val = 0
		byte_bits.each_with_index do |bit, bit_i|
			byte_val += bit * 2 ** bit_i
		end
		bytes << byte_val
	end

	bytes
end


def self.bit_lines_to_bytes(bit_lines)
	
	bits_flat = bit_lines.flatten
	
	bit_byte_groups = (0...(bits_flat.size / 8)).map{|byte_i| bits_flat[(byte_i * 8)...(byte_i * 8 + 8)] }
	
	bytes = []
	
	bit_byte_groups.each do |byte_bits|
		byte_val = 0
		
		byte_bits.each_with_index do |bit, bit_index|
			byte_val += bit * 2 ** bit_index
		end
		
		bytes << byte_val
	end
	
	bytes
end


def self.compile(code, included_files=[])

	lines = Kompiler::Parsers.get_code_lines(code)
	
	parsed_lines = parse_code(lines)
	
	labels = get_labels(parsed_lines)
	
	machine_code_bytes = construct_program_mc(parsed_lines, labels)
end


end # Kompiler::CompilerFunctions

end # Kompiler
