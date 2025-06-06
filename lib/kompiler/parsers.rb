# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

#
# Implements generic parsers used everywhere and checks specific to the compilation process
# 
# Functions:
#  parse_str - parses a string definition from the input text, and returns the amount of characters parsed and the string's contents
#  get_code_lines - parses the initial raw code text into lines, removing comments along the way
#  
# Compilation specific functions:
#  check_instruction - checks whether a line is a valid instruction with the current architecture (Kompiler::Architecture)
#  check_directive - checks whether a line is a directive call
#  
#  parse_instruction_line - parses an instruction line into its keyword (string) and operands with their descriptions (e.g., type of operand, content, value)
#  extract_instruction_parts - parses an instruction line into a string keyword and a list of operand definitions (used by parse_instruction_line)
#  extract_instruction_operands - parses the string after the keyword to extract only the operand definitions (used by extract_instruction_parts)
#  parse_operand_str - parses an operand definition (raw string) into its type, value, and other type-dependent information (uses check_register_operand, check_immediate_operand, check_expression_operand, check_label_operand)
#  check_operand_match - checks whether an operand's info (returned by parse_operand_str) matches the input operand description. Operand descriptions are mostly stored in instruction files (e.g., lib/kompiler/architectures/armv8a/instructions.rb) in the :operands key
#  match_parsed_line_to_instruction - checks whether a parsed instruction line (keyword + operand info) matches an instruction entry, mostly stored in instruction files (example one line above) (used by check_instruction)
#
#


module Kompiler

module Parsers

def self.parse_str(code)

	# Skip the "
	i = 1
	
	quote = code[0]

	next_char_backslashed = false

	str_content = ""

	while true
		if next_char_backslashed
			if code[i] == "n"
				str_content << "\n"
			elsif code[i] == "r"
				str_content << "\r"
			elsif code[i] == "0"
				str_content << "\0"
			else
				str_content << code[i]
			end
			next_char_backslashed = false
		else
			if code[i] == quote
				break
			elsif code[i] == "\\"
				next_char_backslashed = true
			else
				str_content << code[i]
			end
		end
		
		i += 1
	end


	return [str_content, i + 1]
end

def self.get_code_lines(code)

	lines = []

	i = 0

	curr_line = ""

	# EOL - end of line
	skip_to_eol = false

	while i < code.size

		if code[i] == "\n"
			lines << curr_line
			curr_line = ""
			i += 1
			skip_to_eol = false
		elsif code[i] == "/" && code[i + 1] == "/"
			skip_to_eol = true
			i += 1
		elsif code[i] == "\""
			str_content, parse_size = parse_str(code[i..])
			curr_line << code[i...(i+parse_size)] if !skip_to_eol
			i += parse_size
		else
			curr_line << code[i] if !skip_to_eol
			i += 1
		end
	end
	
	if curr_line.size > 0
		lines << curr_line
	end

	return lines
end


def self.check_register_operand(str)
	Kompiler::Architecture.registers.each do |register|
		# Downcase both the string and the register if the register name is not case sensitive (the default)
		processed_str = register[:case_sensitive] ? str : str.downcase
		processed_reg_name = register[:case_sensitive] ? register[:reg_name] : register[:reg_name].downcase
		return [true, register] if processed_str == processed_reg_name
	end
	return [false, nil]
end

def self.check_binary_operand(str)
	return [false, nil] if !str.start_with?("0b")
	binary = str[2..]
	
	# Check if the definition contains only 0 and 1
	zero_or_one = binary.each_char.map{|c| ["0", "1"].include?(c)}
	incorrect_definition = zero_or_one.include?(false)
	
	return [false, nil] if incorrect_definition
	
	binary.reverse!
	
	binary_val = (0...(binary.size)).map{|i| binary[i].to_i * 2 ** i}.sum
	return [true, binary_val]
end


def self.check_hex_operand(str)
	return [false, nil] if !str.start_with?("0x")
	hex = str[2..].downcase
	
	# Check if the definition contains only 0-9 + a-f
	valid_characters = ("0".."9").to_a + ("a".."f").to_a
	is_hex_chars = hex.each_char.map{|c| valid_characters.include?(c)}
	
	# Return false if not only hex characters
	return [false, nil] if is_hex_chars.include?(false)	
	
	# Convert to hex with base 16
	hex_value = hex.to_i(16)
	
	return [true, hex_value]
end


def self.check_decimal_operand(str)
	minus_sign = false
	
	# Check if the string starts with a minus sign. If yes remove it and set minus_sign to true
	if str[0] == '-'
		minus_sign = true
		str = str[1..]
	end
	
	only_numbers = !str.each_char.map{|c| ("0".."9").to_a.include?(c)}.include?(false)
	return [false, nil] if !only_numbers
	
	# If the minus sign is present, multiply the number part by -1
	int = str.to_i
	int *= -1 if minus_sign
	
	return [true, int]
end


def self.check_char_operand(str)

	# If doesn't start with ' or doesn't end with ', return false
	if (str[0] != "'") || (str[-1] != "'")
		return [false, nil]
	end

	# Use existing logic to parse the contents
	to_parse = str.dup
	to_parse[0] = '"'
	to_parse[-1] = '"'
	content, parse_i = parse_str(to_parse)
	
	# If more than one character, return false
	if content.size != 1
		return [false, nil]
	end

	return [true, content.encode("ascii").bytes[0]]
end


def self.check_expression_operand(str)
	begin
		
		ast = Kompiler::Parsers::SymAST.parse str
		
		run_block = lambda do |state|
			state[:labels]["here"] = state[:current_address]
			
			ast_result = Kompiler::Parsers::SymAST.run_ast state[:block_args][:ast], state[:labels], []
			
			return {type: "immediate", value: ast_result, def_type: "sym_ast", definition: state[:block_args][:definition]}
		end
		
		return [true, {type: "run_block", block: run_block, block_args: {ast: ast, definition: str}, block_output_type: "immediate"}]
		
	rescue RuntimeError => e
		p e
		# If an error was caused, return false
		return [false, nil]
	end

end


def self.check_immediate_operand(operand_str)
	
	is_bin, bin_value = check_binary_operand(operand_str)
	return [true, {type: "immediate", value: bin_value, def_type: "binary", definition: operand_str}] if is_bin
	
	is_decimal, decimal_value = check_decimal_operand(operand_str)
	return [true, {type: "immediate", value: decimal_value, def_type: "decimal", definition: operand_str}] if is_decimal
	
	is_hex, hex_value = check_hex_operand(operand_str)
	return [true, {type: "immediate", value: hex_value, def_type: "hex", definition: operand_str}] if is_hex
	
	is_char, char_value = check_char_operand(operand_str)
	return [true, {type: "immediate", value: char_value, def_type: "char", definition: operand_str}] if is_char
	
	return [false, nil]
end


def self.check_label_operand(str)
	# If first character is a number, return false
	return false if ("0".."9").to_a.include?(str[0])

	# Check if it's only made up of allowed characters
	allowed_chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + ["_", "."]
	
	is_each_char_allowed = str.each_char.map{|c| allowed_chars.include?(c)}
	
	# If some characters aren't allowed, return false
	return false if is_each_char_allowed.include?(false)
	
	# Return true if none of the checks returned false
	return true
end


def self.parse_operand_str(operand_str)
	
	# Check if the operand is a register
	is_register, register = check_register_operand(operand_str)
	return {type: "register", value: register, register: register, definition: operand_str} if is_register
	
	# Check if the operand is a string
	is_string = operand_str[0] == "\""
	return {type: "string", value: operand_str[1...-1], string: operand_str[1...-1], definition: operand_str} if is_string
	
	# Checks if it's an immediate
	is_immediate, immediate_val = check_immediate_operand(operand_str)
	return immediate_val if is_immediate
	
	
	#
	# Check if it's a label
	#
	
	# The operand is a label if it doesn't start with a number and doesn't include spaces
	is_label = check_label_operand(operand_str)
	return {type: "label", value: operand_str, definition: operand_str} if is_label
	
	
	is_expr, expr_operand = check_expression_operand(operand_str)
	return expr_operand if is_expr
	
	# If no checks succeeded, return false
	return false
end

# Extract operand strings from the structure "op1, op2, op3, ..."
# Returns an array of the operand strings
def self.extract_instruction_operands(line)
	i = 0
	operand_strings = []
	
	loop do
		break if i >= line.size
		
		operand_content = ""
		
		# Collect the operand's content until a comma or end of line
		loop do
			break if (i >= line.size)
			
			# If the character is a comma, move to the next character and break out of the operand's content loop
			if line[i] == ","
				i += 1
				break
			end
			
			# Skip whitespace
			if Kompiler::Config.whitespace_chars.include? line[i]
				i += 1
				next
			end
			
			# If a string definition, parse to the end of the string
			if Kompiler::Config.string_delimiters.include?(line[i])
				str_content, parsed_size = parse_str(line[i..])
				operand_content += line[i] + str_content + line[i]
				i += parsed_size
				next
			end
			
			# Else just add the character to the operand content
			operand_content += line[i]
			
			# Move to the next character
			i += 1
		end
		
		# After operand content was collected, add it to the list of operands if the content isn't empty
		operand_strings << operand_content if operand_content.size != 0
	end

	operand_strings
end


def self.extract_instruction_parts(line)

	keyword = ""
	i = 0
	
	# Loop until a non-whitespace character
	while i < line.size
		break if !Kompiler::Config.whitespace_chars.include?(line[i])
		i += 1
	end
	
	# Loop to get the keyword
	loop do
		# Exit out of the loop if the character is a whitespace
		break if Kompiler::Config.whitespace_chars.include?(line[i]) || i >= line.size
		# Add the character if not a whitespace
		keyword << line[i]
		# Proceed to the next character
		i += 1	
	end
	
	operand_strings = extract_instruction_operands(line[i..])
	
	# Loop for operands
	
	return keyword, operand_strings
end



def self.parse_instruction_line(line)
	
	keyword, operand_strings = extract_instruction_parts(line)
	
	# Parse operand strings into operand types and values
	
	operands = []
	
	operand_strings.each do |operand_str|
		operand = parse_operand_str(operand_str)
		return false if operand == false
		operands << operand
	end
	
	return [keyword, operands]
end



def self.check_operand_match(operand_description, operand)

	if operand[:type] == "run_block" # A special check for a run block
		return false if operand[:block_output_type] != operand_description[:type]
	else
		# If operand type doesn't not match, return false
		return false if operand[:type] != operand_description[:type]
	end

	# Get the restrictions
	operand_restrictions = operand_description[:restrictions]
	return true if !operand_restrictions # If no restrictions, return true

	# Get the operand's values / encoding
	case operand[:type]
	when "register"
		operand_encoding = operand[:value]
	when "immediate"
		operand_encoding = operand[:value]
	when "run_block"
		operand_encoding = Hash.new
	when "string"
		operand_encoding = Hash.new
	end

	# Loop through each restriction to see if the operand matches it
	operand_restrictions.each do |r_key, r_spec|
		# Get the restricted value of the operand
		op_value = operand_encoding[r_key]

		# Check if it matches the restriction specification
		# If an array, the OR algorithm works (the operand key value must be one of the specified values in the r_spec list)
		if r_spec.is_a? Array
			return false if !r_spec.include?(op_value)
		else # If not an array, just check of equality
			return false if op_value != r_spec
		end
	end
	
	
	# If the restrictions match (by not returning a negative answer), return true
	return true
end

 



# Returns array of [status, operands]
# If status = false, operands = nil; otherwise, status = true, operands = instruction operands
def self.match_parsed_line_to_instruction(parsed_line, instruction)

	keyword, operands = parsed_line

	# Check if the keyword matches
	if instruction[:keyword] != keyword && !(instruction[:aliases] != nil && instruction[:aliases].include?(keyword))
		return [false, nil]
	end

	# Check if there's the right amount of operands
	if operands.size != instruction[:operands].size
		return [false, nil]
	end	
	
	# Check if operands match descriptions
	operands.zip(instruction[:operands]).each do |operand, operand_description|
		return [false, nil] if !check_operand_match(operand_description, operand)
	end
	
	return [true, operands]
end



def self.check_instruction(line)
	
	instruction = nil
	operands = nil
	
	parsed_line = Kompiler::Parsers.parse_instruction_line(line)
	
	Kompiler::Architecture.instructions.each do |curr_instruction|
		# If the instruction matches - break
		
		status, curr_operands = match_parsed_line_to_instruction(parsed_line, curr_instruction)
		if status == true
			instruction = curr_instruction
			operands = curr_operands
			break
		end
	end
	
	if instruction != nil
		return [true, {instruction: instruction, operands: operands}]
	else
		return [false, nil]
	end
end



def self.check_directive(line)
	# Skip whitespace
	char_i = 0
	while char_i < line.size && Kompiler::Config.whitespace_chars.include?(line[char_i])
		char_i += 1
	end
	
	# Collect the keyword
	keyword = ""
	
	while char_i < line.size && Kompiler::Config.keyword_chars.include?(line[char_i])
		keyword << line[char_i]
		char_i += 1
	end
	
	if keyword[0] == "."
		keyword = keyword[1..]
	end
	
	directive = nil
	
	Kompiler::Directives.directives.each do |curr_directive|
		if curr_directive[:keyword].is_a? String
			if curr_directive[:keyword] == keyword
				directive = curr_directive
				break
			end
		elsif curr_directive[:keyword].is_a? Array
			if curr_directive[:keyword].include? keyword
				directive = curr_directive
				break
			end
		else
			raise "Directive name error"
		end
	end
	
	if directive == nil
		return [false, nil]
	end
	
	# Check if the directive requires pre-collected operands (with the :collect_operands key that is true by default)
	if !directive.keys.include?([:collect_operands]) || directive[:collect_operands] == true
		parse_status, operands = parse_instruction_line(line)
		
		return [false, nil] if parse_status == false # Return negative if operands can't be parsed
		
		return [true, {directive: directive, operands: operands}] # Otherwise, return the directive
	else
		# If operand collection isn't required, return the directive
		return [true, {directive: directive, operands: []}]
	end
end


end # End Kompiler::Parsers


end # End Kompiler
