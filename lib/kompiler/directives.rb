# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

module Directives

def self.directives
	@directives
end

@directives = [
	{
		keyword: "zeros",
		func: lambda do |operands, state|
			raise "Incorrect use of the \"zeros\" directive." if operands.size > 1 || (operands[0] && operands[0][:type] != "immediate")
			
			n_zeros = operands[0][:value]
			state[:current_address] += n_zeros
			state[:parsed_lines] << {type: "insert", bits: (n_zeros*8).times.map{0} }
			state[:line_i] += 1
			
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
			state[:line_i] += 1
			
			state
		end
	},
	{
		keyword: "align",
		func: lambda do |operands, state|
			raise "Incorrect use of the \"align\" directive." if operands.size > 1 || (operands[0] && operands[0][:type] != "immediate")
			
			state[:line_i] += 1
			
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
			state[:line_i] += 1
			
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
			state[:line_i] += 1
			
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
			state[:line_i] += 1
			
			state
		end
	},
	{
		keyword: "bytes",
		func: lambda do |operands, state|
			raise "Incorrect use of the \"bytes\" directive." if (operands.size != 2) || (operands[0][:type] != "immediate" || operands[1][:type] != "immediate")			
			
			
			n_bytes = operands[0][:value]
			value = operands[1][:value]
			
			value_bits = (0...(n_bytes * 8)).map{|bit_i| value[bit_i]}
			
			# Insert the input amount of bytes of the value into the program
			state[:current_address] += n_bytes
			state[:parsed_lines] << {type: "insert", bits: value_bits}
			state[:line_i] += 1
			
			state
		end
	},
	{
		keyword: "set_pc",
		func: lambda do |operands, state|
			
			raise "Incorrect use of the \"set_pc\" directive." if (operands.size != 1) || (operands[0][:type] != "immediate")						
			
			new_pc = operands[0][:value]
			
			state[:current_address] = new_pc
			state[:line_i] += 1
			
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
			
			state[:line_i] += 1
			
			state
		end
	},
	{
		keyword: ["load_end", "include_end"],
		func: lambda do |operands, state|

			raise "Incorrect use of the \"load_end\" directive" if (operands.size != 1) || (operands[0][:type] != "string")

			file_selector = operands[0][:string]

			files_to_load = Dir[file_selector]

			# Create the loaded_files state entry if it doesn't exist
			state[:extra_state][:loaded_files] = Array.new if !state[:extra_state].keys.include?(:loaded_files)

			# Select only files that haven't been previously loaded
			files_to_load.select!{|file_name| !state[:extra_state][:loaded_files].include?(file_name)}

			# Add the files that will be loaded to the state entry
			state[:extra_state][:loaded_files] += files_to_load

			files_to_load.each do |load_filename|
				file_content = File.read load_filename

				file_lines = Kompiler::Parsers.get_code_lines(file_content)

				state[:lines] += file_lines
			end

			state[:line_i] += 1

			state
		end
	},
	{
		keyword: ["load", "include"],
		func: lambda do |operands, state|

			raise "Incorrect use of the \"load\" directive" if (operands.size != 1) || (operands[0][:type] != "string")

			file_selector = operands[0][:string]

			files_to_load = Dir[file_selector]

			# Create the loaded_files state entry if it doesn't exist
			state[:extra_state][:loaded_files] = Array.new if !state[:extra_state].keys.include?(:loaded_files)

			# Select only files that haven't been previously loaded
			files_to_load.select!{|file_name| !state[:extra_state][:loaded_files].include?(file_name)}

			# Add the files that will be loaded to the state entry
			state[:extra_state][:loaded_files] += files_to_load

			total_load_lines = []

			files_to_load.each do |load_filename|
				file_content = File.read load_filename

				file_lines = Kompiler::Parsers.get_code_lines(file_content)

				total_load_lines += file_lines
			end

			# Move to the next line
			state[:line_i] += 1

			# Insert the lines at the correct place
			state[:lines] = state[:lines][0...state[:line_i]] + total_load_lines + state[:lines][state[:line_i]..]

			state
		end
	},
	{
		keyword: "value",
		collect_operands: false,
		func: lambda do |_, state|			
			_, operands = Kompiler::Parsers.extract_instruction_parts(state[:lines][state[:line_i]])
			
			raise "Incorrect use of the .value directive - expected 2 operands: Program build not possible" if operands.size != 2
			
			value_name = operands[0]
			
			# Check that the name is made out of allowed characters
			if value_name.each_char.map{|char| Kompiler::Config.keyword_chars.include?(char)}.include?(false)
				raise "Incorrect use of the .value directive - the value name must contain only keyword characters: Program build not possible"
			end
			
			value_def = operands[1]
			
			scan_lines = state[:lines][(state[:line_i] + 1)..]
			
			scan_lines.each_with_index do |line, line_i|
				
				start_i = 0
				
				# Loop through each character starting position
				while start_i < line.size					
					
					# Skip whitespace characters
					if Kompiler::Config.whitespace_chars.include?(line[start_i])
						start_i += 1
						next
					end
					
					# Skip string definitions
					if ['"', "'"].include? line[start_i]
						str, parsed_length = Kompiler::Parsers.parse_str line[start_i..]
						start_i += parsed_length
						next
					end
					
					cut_line = line[start_i..]
					
					value_word_found = false
					
					# Check if the value name works
					
					if cut_line.start_with?(value_name) # Check that the piece of text starts with the value name
						if !Kompiler::Config.keyword_chars.include?(cut_line[value_name.size]) # Check that the cut text is a full word. This will not fire when value_name='arg', but the cut text is 'arg1'
							value_word_found = true # Indicate that a replacement was found
							
							scan_lines[line_i] = scan_lines[line_i][...start_i] + value_def + (scan_lines[line_i][(start_i+value_name.size)..] || "")
							line = scan_lines[line_i]
						end
					end
					
					# Check if the value name wasn't detected
					# If not, skip the text until the next whitespace character
					if !value_word_found
						while start_i < line.size && Kompiler::Config.keyword_chars.include?(line[start_i])
							start_i += 1
						end
						start_i += 1 # Move one more character
					end
					
				end
				
			end
			
			
			state[:extra_state][:values] = Array.new if !state[:extra_state].keys.include?(:values)
			
			state[:extra_state][:values] << {name: value_name, def_value: value_def}
			
			
			state[:lines] = state[:lines][..state[:line_i]] + scan_lines
			
			state[:line_i] += 1
			
			state
		end
	},
	{
		keyword: "macro",
		collect_operands: false,
		func: lambda do |_, state|
			line_i = state[:line_i]
			
			def_line = state[:lines][line_i]
			
			# First: collect the part after ".macro"
			
			char_i = 0
			# Skip the whitespace before .macro
			while char_i < def_line.size && Kompiler::Config.whitespace_chars.include?(def_line[char_i])
				char_i += 1
			end
			# Skip the .macro
			while char_i < def_line.size && Kompiler::Config.keyword_chars.include?(def_line[char_i])
				char_i += 1
			end
			# Skip the whitespace after .macro
			while char_i < def_line.size && Kompiler::Config.whitespace_chars.include?(def_line[char_i])
				char_i += 1
			end
			
			# If the end of the line was reached, throw an error
			raise "Incorrect .macro definition" if char_i == def_line.size
			
			# Now char_i contains the first index of the text after .macro
			
			macro_def = def_line[char_i..]
			
			# Second: extract the macro's name
			
			macro_name = ""			
			
			while char_i < def_line.size && Kompiler::Config.keyword_chars.include?(def_line[char_i])
				macro_name << def_line[char_i]
				char_i += 1
			end
			
			# Third: extract the operand names (code taken from parse_instruction_line in parsers.rb)
			
			arg_names = Kompiler::Parsers.extract_instruction_operands(def_line[char_i..])
			
			# Make sure that the arg names are unique
			raise "Macro definition error - arguments cannot have the same name: Program build not possible" if arg_names.size != arg_names.uniq.size
			
			# Extract the macro inside definition
			
			line_i = state[:line_i] + 1
			def_lines = []
			
			whitespace_regexp = /[#{Kompiler::Config.whitespace_chars.join("|")}]*/
			
			endmacro_regexp = /\A#{whitespace_regexp}\.?endmacro#{whitespace_regexp}\z/
			
			while line_i < state[:lines].size
				break if state[:lines][line_i].match? endmacro_regexp # Check if it's an end macro instruction
				def_lines << state[:lines][line_i]
				line_i += 1
			end
			
			
			# Find insert indexes for each argument
			arg_insert_locations = arg_names.map{|arg_name| [arg_name, []]}.to_h
			
			def_lines.each_with_index do |line, line_i|
				
				start_i = 0
				
				# Loop through each character starting position
				while start_i < line.size					
					
					# Skip whitespace characters
					if Kompiler::Config.whitespace_chars.include?(line[start_i])
						start_i += 1
						next
					end
					
					# Skip string definitions
					if ['"', "'"].include? line[start_i]
						str, parsed_length = Kompiler::Parsers.parse_str line[start_i..]
						start_i += parsed_length
						next
					end
					
					cut_line = line[start_i..]
					
					arg_found = false
					
					# Check if one of the argument names works
					arg_names.each do |arg_name|
						next if !cut_line.start_with?(arg_name) # Skip the argument if the line doesn't begin with it
						next if Kompiler::Config.keyword_chars.include?(cut_line[arg_name.size]) # Skip if the argument is a partial word. So, for the argument 'arg', this will skip in the case of 'arg1'
						# Here if the argument name should be replaced with the contents
						arg_found = true # Indicate that a replacement was found						
						
						arg_insert_locations[arg_name] << [line_i, start_i] # Add the insert location to the list
						
						# start_i += arg_name.size
						def_lines[line_i] = def_lines[line_i][...start_i] + (def_lines[line_i][(start_i+arg_name.size)..] || "")
						line = def_lines[line_i]
						
						break # Skip the arguments loop
					end
					
					# Check if an argument was found
					# If not, skip the text until the next whitespace character
					if !arg_found
						while start_i < line.size && Kompiler::Config.keyword_chars.include?(line[start_i])
							start_i += 1
						end
						start_i += 1 # Move one more character
					end
					
				end
				
			end
			
			state[:extra_state][:macros] = Array.new if !state[:extra_state].keys.include?(:macros)
			
			state[:extra_state][:macros] << {name: macro_name, args: arg_names, def_lines: def_lines, arg_insert_locations: arg_insert_locations}
			
			
			# Scan the lines after the macro for the macro call and replace it with the macro definition
			
			scan_lines = state[:lines][(state[:line_i] + def_lines.size + 1 + 1)..]
			
			line_i = 0
			
			# Re-group argument insert locations by line -> [index, arg index]			
			
			arg_insert_locations_regrouped = def_lines.size.times.map{[]}
			
			arg_insert_locations.each do |arg_name, insert_locations|
				insert_locations.each do |line_i, char_i|
					arg_insert_locations_regrouped[line_i] << [char_i, arg_names.index(arg_name)]
				end
			end
			
			
			while line_i < scan_lines.size
				keyword, operands = Kompiler::Parsers.extract_instruction_parts(scan_lines[line_i])
				
				# If parsing failed, move on to the next line
				if keyword == false
					line_i += 1
					next
				end
				
				# If the keyword isn't the macro's name, skip the line
				if keyword != macro_name
					line_i += 1
					next
				end
				
				# Here when the keyword matches the macro name
				
				# Check that the number of operands is correct
				if operands.size != arg_names.size
					raise "Incorrect use of the \"#{macro_name}\" macro - #{arg_names.size} operands expected, but #{operands.size} were given: Program build not possible."
				end
				
				# Build the replacement lines for the macro call
				build_lines = def_lines.map{|line| line.dup} # Copying strings inside array, because array.dup doesn't work for elements
				
				arg_insert_locations_regrouped.each_with_index do |locations, line_i|
					# Sort the locations by the insert character from largest to smallest, so that the inserts are made from end to start
					locations.sort_by{|el| el[0]}.reverse.each do |char_i, arg_index|
						build_lines[line_i].insert char_i, operands[arg_index]
					end
				end
				
				# Replace the macro call with the built lines
				scan_lines = scan_lines[...line_i] + build_lines + scan_lines[(line_i + 1)..]
				
				# Skip the inserted macro
				line_i += build_lines.size
			end			
			
			state[:lines] = state[:lines][...state[:line_i]] + scan_lines
			
			state[:line_i] += 1
			
			state
		end
	}
]


end # Kompiler::Directives

end # Kompiler
