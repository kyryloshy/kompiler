# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

class Parsers

def self.parse_str(code)

	# Skip the "
	i = 1

	next_char_backslashed = false

	str_content = ""

	while true
		if next_char_backslashed
			if code[i] == "n"
				str_content << "\n"
			elsif code[i] == "r"
				str_content << "\r"
			elsif code[i] == "\\"
				str_content << "\\"
			else
				str_content << "\\"
				str_content << code[i]
			end
			next_char_backslashed = false
		else
			if code[i] == "\""
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
		return [true, register] if str == register[:reg_name]
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


def self.check_immediate_operand(operand_str)
	
	is_bin, bin_value = check_binary_operand(operand_str)
	return [true, {type: "immediate", value: bin_value, def_type: "binary"}] if is_bin
	
	is_decimal, decimal_value = check_decimal_operand(operand_str)
	return [true, {type: "immediate", value: decimal_value, def_type: "decimal"}] if is_decimal
	
	is_hex, hex_value = check_hex_operand(operand_str)
	return [true, {type: "immediate", value: hex_value, def_type: "hex"}] if is_hex
	
	return [false, nil]
end


def self.check_label_operand(str)
	# If first character is a number, return false
	return false if ("0".."9").to_a.include?(str[0])

	# Check if it's only made up of allowed characters
	allowed_chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + ["_"] 
	
	is_each_char_allowed = str.each_char.map{|c| allowed_chars.include?(c)}
	
	# If some characters aren't allowed, return false
	return false if is_each_char_allowed.include?(false)
	
	# Return true if none of the checks returned false
	return true
end


def self.parse_operand_str(operand_str)
	
	
	# Check if the operand is a register
	is_register, register = check_register_operand(operand_str)
	return {type: "register", value: register, register: register} if is_register
	
	# Check if the operand is a string
	is_string = operand_str[0] == "\""
	return {type: "string", value: operand_str[1...-1], string: operand_str[1...-1]} if is_string
	
	# Checks if it's an immediate
	is_immediate, immediate_val = check_immediate_operand(operand_str)
	return immediate_val if is_immediate
	
	
	#
	# Check if it's a label
	#
	
	# The operand is a label if it doesn't start with a number and doesn't include spaces
	is_label = check_label_operand(operand_str)
	return {type: "label", value: operand_str} if is_label
	
	
	# If no checks succeeded, return false
	return false
end




def self.parse_instruction_line(line)
	keyword = ""
	i = 0
	
	# Loop until a non-whitespace character
	while i < line.size
		break if ![" ", "\t"].include?(line[i])
		i += 1
	end

	# Loop to get the keyword
	loop do
		# Exit out of the loop if the character is a whitespace
		break if [" ", "\t"].include?(line[i]) || i >= line.size
		# Add the character if not a whitespace
		keyword << line[i]
		# Proceed to the next character
		i += 1	
	end

	operand_strings = []
	
	# Loop for operands
	loop do
		break if i >= line.size

		# # Whitespace - skip
		# if [" ", "\t"].include? line[i]
		# 	i += 1
		# 	next
		# end

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
			if [" ", "\t"].include? line[i]
				i += 1
				next
			end
			
			# If a string definition, parse to the end of the string
			if line[i] == "\""
				str_content, parsed_size = parse_str(line[i..])
				operand_content += '"' + str_content + '"'
				i += parsed_size
				next
			end
			
			# Else just add the character to the operand content
			operand_content += line[i]
			
			# Move to the next character
			i += 1
		end
		
		# After operand content was collected, add it to the list of operands
		operand_strings << operand_content
	end	
	
	# Parse operand strings into operand types and values
	
	operands = []
	
	operand_strings.each do |operand_str|
		operand = parse_operand_str(operand_str)
		return false if operand == false
		operands << operand
	end
	
	return [keyword, operands]
end





# def self.parse_instruction_line(line)
# 	keyword = ""
# 	i = 0
# 	
# 	# Loop until a non-whitespace character
# 	while i < line.size
# 		break if ![" ", "\t"].include?(line[i])
# 		i += 1
# 	end
# 
# 	# Loop to get the keyword
# 	loop do
# 		# Exit out of the loop if the character is a whitespace
# 		break if [" ", "\t"].include?(line[i]) || i >= line.size
# 		# Add the character if not a whitespace
# 		keyword << line[i]
# 		# Proceed to the next character
# 		i += 1	
# 	end
# 
# 	operand_strings = []
# 	
# 	# Loop for operands
# 	loop do
# 		break if i >= line.size
# 
# 		# Whitespace - skip
# 		if [" ", "\t"].include? line[i]
# 			i += 1
# 			next
# 		end
# 
# 		# If a string operand - parse the string
# 		if line[i] == "\""
# 
# 			str_content, parsed_size = parse_str(line[i..])
# 			operand_strings << line[i...(i + parsed_size)]
# 			i += parsed_size
# 
# 		# If anything else - parse until whitespace, comma or end of line
# 		else
# 			content = ""
# 
# 			while i < line.size
# 				break if [" ", ","].include? line[i]
# 				content << line[i]
# 				i += 1
# 			end
# 			
# 			operand_strings << content
# 		end
# 
# 
# 		# After operand parsed
# 		# Loop to meet a comma or end of line
# 		# Give error if stuff except whitespace
# 
# 		while i < line.size
# 			# If comma, move to next character and repeat the bigger operand loop
# 			if line[i] == ","
# 				i += 1
# 				break
# 			end
# 			# If non-whitespace, raise an error
# 			# raise "Error: Unparsed content - exiting" if ![" ", "\t"].include?(line[i])
# 			return false if ![" ", "\t"].include?(line[i])
# 			i += 1
# 		end
# 	end
# 	
# 	# If end of line not reached, return an error
# 	if i != line.size
# 		return false
# 	end
# 
# 	
# 	# Parse operand strings into operand types and values
# 	
# 	operands = []
# 	
# 	operand_strings.each do |operand_str|
# 		operand = parse_operand_str(operand_str)
# 		return false if operand == false
# 		operands << operand
# 	end
# 	
# 	return [keyword, operands]
# end



def self.check_operand_match(operand_description, operand)

	# If operand type doesn't not match, return false
	return false if operand[:type] != operand_description[:type]

	# If no operand restrictions, return true
	return true if !operand_description.keys.include?(:restrictions)

	case operand_description[:type]
	when "register"
	
		# Check register type match
		if operand_description[:restrictions].keys.include?(:reg_type)
			return false if operand[:register][:reg_type] != operand_description[:restrictions][:reg_type]
		end
	
		# Check register size match
		if operand_description[:restrictions].keys.include?(:reg_size)
			return false if operand[:register][:reg_size] != operand_description[:restrictions][:reg_size]
		end
		
	when "immediate"
		
		
		
	when "label"
		
		
		
	end
	
	
	# If the restrictions match (by not returning a negative answer), return true
	return true
end


# Returns array of [status, operands]
# If status = false, operands = nil; otherwise, status = true, operands = instruction operands
def self.match_instruction(line, instruction)

	keyword, operands = parse_instruction_line(line)


	# Check if the keyword matches
	if instruction[:keyword] != keyword
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
	
	Kompiler::Architecture.instructions.each do |curr_instruction|
		# If the instruction matches - break
		status, curr_operands = match_instruction(line, curr_instruction)
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
	status = parse_instruction_line(line)

	return [false, nil] if status == false

	keyword, operands = status

	if keyword[0] == "."
		keyword = keyword[1..]
	end
	
	directive = nil
	
	Kompiler::Directives.directives.each do |curr_directive|
		if curr_directive[:keyword] == keyword
			directive = curr_directive
			break
		end
	end
	
	if directive == nil
		return [false, nil]
	else
		return [true, {directive: directive, operands: operands}]
	end
end


end # End Kompiler::Parsers


end # End Kompiler