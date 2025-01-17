# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

module CompilerFunctions

def self.parse_includes(lines, loaded_files=[])
	
	final_lines = lines.dup	
	
	line_i = 0
	
	loop do
		break if line_i >= final_lines.size
		
		line = final_lines[line_i]
		
		keyword, operands = Kompiler::Parsers.parse_instruction_line(line)
		
		if keyword == false
			line_i += 1
			next
		end
		
		if keyword.start_with? "."
			keyword = keyword[1..]
		end
		
		if !["load", "include", "load_end", "include_end"].include?(keyword)
			line_i += 1
			next
		end
		
		raise "Incorrect use of the \"#{keyword}\" directive: requires a filename in a string." if operands.size != 1 || (operands.size == 1 && operands[0][:type] != "string")
		
		load_file_name_selector = operands[0][:string]


		# Remove the include code line from the lines array
		final_lines.delete_at line_i

		# If ends with _end, that means that the file contents should be appended at the end of the current lines
		if keyword.end_with? "_end"
			next_i_insert = final_lines.size
		else
			# If doesn't end with _end, files should be loaded in-place of the current line
			next_i_insert = line_i
		end
		
		
		Dir[load_file_name_selector].each do |load_file_name|
			# Get the absolute path filename
			full_file_name = File.expand_path(load_file_name)
			
			raise "#{keyword} \"#{load_file_name}\": File not found." if !File.exist?(full_file_name)
			
			# Check if the file was already loaded (stop recursive loading)
			if loaded_files.include?(full_file_name)
				next
			end
			
			# Read the file to load
			include_code = File.read(full_file_name)
			
			# Separate the lines inside it
			include_code_lines = Kompiler::Parsers.get_code_lines(include_code)
			
			# Add the lines from the load file to the lines array at the line_i index, effectively replacing the load command with the content of the load file
			final_lines.insert next_i_insert, *include_code_lines
			
			next_i_insert += include_code_lines.size
			
			# Add the filename (absolute path) to the list of included files
			loaded_files << full_file_name
		end
		
		# Don't increment line_i, since the new loop will now start include-parsing the newly loaded file in the same program
	end

	final_lines
	
end


def self.parse_macros(lines)

	macros = []

	line_i = 0
	
	loop do
		break if line_i >= lines.size
		
		line = lines[line_i]
		
		keyword, operands = Kompiler::Parsers.parse_instruction_line line
		
		keyword = keyword[1..] if keyword.start_with? "."
		
		if keyword == 'macro'
			raise "Macro definition error: Expected two operands to be provided, while #{operands.size} were given" if operands.size != 2
			raise "Macro definition error: The macro name must either be a word or a string" if !["label", "string"].include?(operands[0][:type])
			
			case operands[0][:type]
			when "label"
				macro_name = operands[0][:value]
			when "string"
				macro_name = operands[0][:value]
			end
			
			macro_definition = operands[1][:definition]
			
			macros << {name: macro_name, definition: macro_definition}
			
			lines.delete_at line_i
		else
			line_i += 1
		end
	end
	
	# Apply the macros to all lines, and then the lines that were changed, and than again, and so on (iterative loop until none of the lines need to be checked)
	
	lines_to_check = (0...lines.size).to_a
	
	while lines_to_check.size != 0 # Repeat until no more lines to check		

		# Define restricted separators characters (characters that CAN'T separate a macro from everything else)
		restricted_separator_chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + ["_", "."]
		
		# Create an array for the lines to check once again
		new_lines_to_check = []
		
		lines_to_check.each do |line_i|
			line = lines[line_i]
			
			char_i = 0
			
			# Create a variable to indicate if a macro was used on the current line 
			line_macro_used = false
			
			loop do
				break if char_i >= line.size
				
				if ['"', "'"].include? line[char_i]
					# If a string, skip it
					str, parsed_length = Kompiler::Parsers.parse_str line[char_i..]
					char_i += parsed_length
					next
				end
				
				cut_line = line[char_i..]			
				
				# Create a variable to indicate if a macro was used in the current position
				macro_used = false			
				
				macros.each do |macro|
					macro_name = macro[:name]
					macro_def = macro[:definition]
					next if !cut_line.start_with?(macro_name) # Skip if doesn't begin with the macro's name
					next if (cut_line.size > macro_name.size) && restricted_separator_chars.include?(cut_line[macro_name.size]) # Skip if there is a character after the macro name, and the character is not permitted
					next if (char_i > 0) && restricted_separator_chars.include?(line[char_i - 1]) # Skip if there is a character before the checking sequence, and the character is not permitted
					
					# Here if the macro is 'accepted'
					line = line[...char_i] + macro_def + line[(char_i + macro_name.size)..]
					# Indicate that a macro was used
					macro_used = true
				end
				
				if macro_used
					# If a macro was used, indicate that on line level
					line_macro_used = true
				else
					# If a macro wasn't used, proceed to the next character
					char_i += 1
				end
			end # line characters loop
			
			if line_macro_used
				# If a macro was used on the current line, update the lines array, and add the line to check for macros again
				lines[line_i] = line
				new_lines_to_check << line_i
			end
		end # lines_to_check.each loop
		
		lines_to_check = new_lines_to_check # Update lines to check with the new ones
	
	end # while lines_to_check.size != 0 loop

	lines
end


def self.parse_code(lines)	
	
	parsed_lines = []
	
	instr_adr = 0
	
	lines.each_with_index do |line, line_i|
		
		# Check if line is not just whitespace
		is_char_whitespace = line.each_char.map{|c| [" ", "\t"].include? c}
		if !is_char_whitespace.include?(false) # If only whitespace
			next # Skip
		end
		
		#
		# Label definitions are now a directive, so this isn't needed
		#
		
		# is_label, label_name = check_label(line)
		# if is_label
		# 	# labels[label_name] = instr_adr
		# 	parsed_lines << {type: "label", label_name: label_name, label_address: instr_adr, address: instr_adr}
		# 	next
		# end
	
		is_instruction, exec_instruction = Kompiler::Parsers.check_instruction(line)
		if is_instruction
			parsed_lines << {type: "instruction", instruction: exec_instruction[:instruction], operands: exec_instruction[:operands], address: instr_adr}			
			instr_adr += exec_instruction[:instruction][:bitsize] / 8
			
			next # Go to the next line
		end
		
		
		is_directive, directive_hash = Kompiler::Parsers.check_directive(line)
		if is_directive
			directive = directive_hash[:directive]
			operands = directive_hash[:operands]
			
			state = {current_address: instr_adr, parsed_lines: parsed_lines}
			
			state = directive[:func].call(operands, state)
		
			instr_adr = state[:current_address]
			parsed_lines = state[:parsed_lines]
			
			next # Skip to the next lime
		end
		
		
		# Line wasn't classified
		# Throw an error
		
		raise "\"#{line}\" - Unknown syntax: Program build not possible"
		
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
			program_state[:operands] = line[:operands]
			program_state[:current_address] = line[:address]
			
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
	
	included_lines = parse_includes(lines, included_files.map{|fname| File.expand_path(fname)})
	
	macroed_lines = parse_macros(included_lines)
	
	parsed_lines = parse_code(macroed_lines)
	
	labels = get_labels(parsed_lines)	
	
#	machine_code_bit_lines = construct_program_mc(parsed_lines, labels)
#
#	machine_code_bytes = bit_lines_to_bytes(machine_code_bit_lines)	
	
	machine_code_bytes = construct_program_mc(parsed_lines, labels)
end


end # Kompiler::CompilerFunctions

end # Kompiler
