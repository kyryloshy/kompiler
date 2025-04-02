
#
# Implements logic to parse math-like expressions into an ASTs.
#
# Main functions:
#  str_to_ast - converts a raw string into an AST.
#  run_ast - runs the AST created by str_to_ast.
#
# Config options are available in Kompiler::Parsers::SymAST::Config :
#  word_begin_chars - a list of characters that a word can begin with
#  word_chars - a list of characters that a word can contain
#  number_begin_chars - a list of characters that a number can begin with
#  number_chars - a list of characters that a number can contain
#  whitespace_chars - a list of whitespace / separator characters
#  parse_functions - a boolean specifying whether functions with syntax func(x + 2) should be parsed or throw an error
#  sign_types - a list of available signs, their names and character sequences that qualify as the sign.
#               Entries appearing earlier in the list are prioritized.
#  one_element_ast_operations - a list of one element operations, their names, sign types, and checking direction (1 for left to right, -1 for right to left).
#                               For example, the negation "-x" is a one element operation, with the sign type "sub", and check_direction -1 (checks from right to left) because it is on the left of the 'x'
#                               Entries appearing earlier in the list are prioritized.
#  two_element_ast_operations - a list of two element operation 'groups'. Groups are implemented to list operations on the same priority level with the same check direction.
#                               Each group has a check_direction (1 for left to right, -1 for opposite), and a list of operations in this group, their names and sign types, similar to one element operations.
#                               Entries appearing earlier in the list are prioritized.
#                               An example group could be multiplication and division. The check_direction will be 1, and there will be two operations (mul and div). This group will be below the power (a ** b) group.
#  functions - a list of available functions in expressions in Kompiler programs
#


module Kompiler

module Parsers


module SymAST
	
	module Config
	
		# Word begin characters are characters from which a word can begin (right now, everything except numbers)
		@word_begin_chars = ("a".."z").to_a + ("A".."Z").to_a + ["_"]
		# Word characters are characters that the word can contain (excluding the first character)
		@word_chars = @word_begin_chars + ("0".."9").to_a
		
		# Number begin characters. Same as word_begin_chars but for numbers
		@number_begin_chars = ("0".."9").to_a
		# Number characters. Same as word_chars but for numbers
		@number_chars = ("0".."9").to_a + ["."]
		
		# Whitespace characters
		@whitespace_chars = [" ", "\t"]
		
		class <<self
			attr_accessor :word_begin_chars, :word_chars, :number_begin_chars, :number_chars, :whitespace_chars
		end
		
		
		
		# Include function operations parsing (e.g., func(x + 2) )
		@parse_functions = true
		
		class <<self
			attr_accessor :parse_functions
		end
		
		
		@sign_types = [
			{name: "open_bracket", chars: ["("]},
			{name: "close_bracket", chars: [")"]},
			{name: "power", chars: ["**"]},
			{name: "div", chars: ["/"]},
			{name: "mul", chars: ["*"]},
			{name: "add", chars: ["+"]},
			{name: "sub", chars: ["-"]},
			{name: "shift_left", chars: ["<<"]},
			{name: "shift_right", chars: [">>"]},
			{name: "or", chars: ["|"]},
			{name: "and", chars: ["&"]},
			{name: "modulo_sign", chars: ["%"]},
			{name: "equal_sign", chars: ["=="]},
			{name: "not_equal_sign", chars: ["!="]},
			{name: "less_or_eq_sign", chars: ["<="]},
			{name: "greater_or_eq_sign", chars: [">="]},
			{name: "less_than_sign", chars: ["<"]},
			{name: "greater_than_sign", chars: [">"]},
			
			{name: "exclamation_mark", chars: ["!"]},
		]
		
		# One element operations (e.g., negate operation as "-x" or factorial as "x!"). Elements earlier have higher priority
		# check_direction means whether parsing should start from the left (-1) or from the right (1)
		@one_element_ast_operations = [
			{name: "negate", sign_type: "sub", check_direction: -1},
			{name: "factorial", sign_type: "exclamation_mark", check_direction: 1},
		]
		
		# # Two element operations (e.g., division as "a / b"). Elements earlier have higher priority
		# # check_direction means whether parsing should start from the left (-1) or from the right (1)
		# @two_element_ast_operations = [
		# 	{name: "power", sign_type: "power", check_direction: -1},
		# 	{name: "div", sign_type: "div", check_direction: 1},
		# 	{name: "mul", sign_type: "mul", check_direction: 1},
		# 	{name: "add", sign_type: "add", check_direction: 1},
		# 	{name: "sub", sign_type: "sub", check_direction: 1},
		# 	{name: "bitshift_left", sign_type: "shift_left", check_direction: 1},
		# 	{name: "bitshift_right", sign_type: "shift_right", check_direction: 1},
		# 	{name: "bit_or", sign_type: "or", check_direction: 1},
		# 	{name: "bit_and", sign_type: "and", check_direction: 1},
		# ]
		
		# Two element operations (e.g., division as "a / b"). Elements earlier have higher priority
		# check_direction means whether parsing should start from the left (-1) or from the right (1)
		@two_element_ast_operations = [
			{
				group_check_direction: -1, 
				group_operations: [
					{name: "power", sign_type: "power"},
				]
			},
			{
				group_check_direction: 1,
				group_operations: [
					{name: "modulo", sign_type: "modulo_sign"},
				]
			},
			{
				group_check_direction: 1, 
				group_operations: [
					{name: "div", sign_type: "div"},
					{name: "mul", sign_type: "mul"},
				]
			},
			{
				group_check_direction: 1,
				group_operations: [
					{name: "bitshift_left", sign_type: "shift_left"},
					{name: "bitshift_right", sign_type: "shift_right"},
					{name: "bit_or", sign_type: "or"},
					{name: "bit_and", sign_type: "and"},
				]
			},
			{
				group_check_direction: 1, 
				group_operations: [
					{name: "add", sign_type: "add"},
					{name: "sub", sign_type: "sub"},
				]
			},
			{
				group_check_direction: 1, 
				group_operations: [
					{name: "equal", sign_type: "equal_sign"},
					{name: "not_equal", sign_type: "not_equal_sign"},
					{name: "less_than", sign_type: "less_than_sign"},
					{name: "greater_than", sign_type: "less_than_sign"},
					{name: "less_or_eq", sign_type: "less_or_eq_sign"},
					{name: "greater_or_eq", sign_type: "greater_or_eq_sign"},
				]
			},
		]
		
		
		@functions = {
			"len" => lambda do |arg|
				if !arg.is_a?(String) then raise "Math AST len() error 1" end
				return arg.size
			end,
			"floor" => lambda do |arg|
				if !arg.is_a?(Numeric) then raise "Math AST floor() error 1" end
				return arg.floor
			end
		}
		
		class <<self
			attr_accessor :sign_types, :one_element_ast_operations, :two_element_ast_operations, :functions
		end
	end
	
	
	def self.str_to_tokens str
		
		tokens = []
		
		char_i = 0
		
		# Types of available signs (the first one is prioritized)
		sign_types = Config.sign_types
		
		
		full_word = ""
		
		while char_i < str.size
		
		
			# Check if the character is a whitespace
			if Config.whitespace_chars.include?(str[char_i])
				char_i += 1 # Move to the next character
				next # Skip
			end
		
			cut_str = str[char_i..]
		
			# Check if the current position is a math sign
			
			sign_found = false
			str_found = false
			
			sign_types.each do |sign|
				sign[:chars].each do |seq|
					if cut_str.start_with? seq
						# Here when the sign matched
						tokens << {type: "sign", sign_type: sign[:name], match_seq: seq}
						char_i += seq.size
						sign_found = true
					end
					break if sign_found
				end
				break if sign_found
			end
			
			
			if !sign_found && Kompiler::Config.string_delimiters.include?(str[char_i])
				str_content, len_parsed = Kompiler::Parsers.parse_str(cut_str)
				
				
				case str[char_i]
				when '"'
					tokens << {type: "string", str_content: str_content}
				when "'"
					if str_content.size != 1 then raise "Math AST parse error - a character definition cannot be longer than 1" end
					full_str = str[char_i...(char_i + len_parsed)]
					tokens << {type: "number", number_content: full_str}
				end
				
				str_found = true
				char_i += len_parsed
			end
			
			
			if sign_found || str_found
				next if full_word.size == 0
				
				is_imm, imm_value = Kompiler::Parsers.check_immediate_operand(full_word)
				if is_imm
					tokens.insert -2, {type: "number", number_content: full_word, number_value: imm_value[:value]}
					full_word = ""
					next
				end
				
				if Config.word_begin_chars.include?(full_word[0]) && !(full_word[1..].each_char.map{|c| Config.word_chars.include?(c)}.include?(false))
					tokens.insert -2, {type: "word", word_content: full_word}
					full_word = ""
					next
				end
				
				raise "Math AST Error 1"
			else
				full_word << str[char_i]
				char_i += 1
			end
			
			next
			
			
			
			next_word = ""
			word_char_i = char_i.dup
			
			while word_char_i < str.size && !Config.whitespace_chars.include?(str[word_char_i])
				next_word += str[word_char_i]
				word_char_i += 1
			end
			
			is_imm, imm_value = Kompiler::Parsers.check_immediate_operand(next_word)
			
			if is_imm
				tokens << {type: "number", number_content: next_word, number_value: imm_value[:value]}
				char_i = word_char_i
				next
			end
			
			# if Config.number_begin_chars.include?(str[char_i])
			# 	full_number = str[char_i]
			# 	char_i += 1
			# 	
			# 	while char_i < str.size && Config.number_chars.include?(str[char_i])
			# 		full_number << str[char_i]
			# 		char_i += 1
			# 	end
			# 	
			# 	tokens << {type: "number", number_content: full_number}
			# 	
			# 	next
			# end
			
			
			if Config.word_begin_chars.include?(str[char_i])
				full_word = str[char_i]
				char_i += 1
				
				while char_i < str.size && Config.word_chars.include?(str[char_i])
					full_word << str[char_i]
					char_i += 1
				end
				
				tokens << {type: "word", word_content: full_word}
				
				next
			end
			
			
			# Here when non of the checks worked
			raise "\"#{str}\" - unrecognized syntax at position #{char_i}"
		end
		
		a = 0
		while a != 1
			a = 1 
			if full_word.size > 0
				is_imm, imm_value = Kompiler::Parsers.check_immediate_operand(full_word)
				if is_imm
					tokens.insert -1, {type: "number", number_content: full_word, number_value: imm_value[:value]}
					full_word = ""
					next
				end
				
				if Config.word_begin_chars.include?(full_word[0]) && !(full_word[1..].each_char.map{|c| Config.word_chars.include?(c)}.include?(false))
					tokens.insert -1, {type: "word", word_content: full_word}
					full_word = ""
					next
				end
				
				raise "Math AST Error 2"
			end
		end
		
		
		tokens
	end
	
	
	# A recursive function that makes blocks (bracket enclosed) into single tokens
	def self.parse_blocks_from_tokens tokens
	
		final_tokens = []
		
		token_i = 0
	
		while token_i < tokens.size
			
			token = tokens[token_i]
			
			if !(token[:type] == "sign" && ["open_bracket", "close_bracket"].include?(token[:sign_type]))
				final_tokens << token
				token_i += 1
				next
			end
			
			if token[:sign_type] == "close_bracket"
				raise "Parsing error - unexpected close bracket at token #{token_i}"
			end
			
			# Set up a bracket count that counts the bracket level (zero means 'absolute' / ground level)
			bracket_count = 1
			block_end_i = token_i + 1
			
			while block_end_i < tokens.size && bracket_count != 0
				if tokens[block_end_i][:type] != "sign"
					block_end_i += 1
					next
				end
				
				case tokens[block_end_i][:sign_type]
				when "open_bracket"
					bracket_count += 1
				when "close_bracket"
					bracket_count -= 1
				end
				
				block_end_i += 1
			end
			
			raise "Parsing error - Bracket amount does not match" if bracket_count != 0
			
			block_tokens = tokens[(token_i + 1)...(block_end_i - 1)]
			
			parsed_block_tokens = parse_blocks_from_tokens(block_tokens)
			parsed_block_tokens = parse_functions_from_tokens(parsed_block_tokens)
			
			final_tokens << {type: "block", content: parsed_block_tokens}
			
			token_i = block_end_i
		end
	
		final_tokens
	
	end
	
	
	def self.parse_functions_from_tokens tokens
		
		final_tokens = []
		
		token_i = 0
		
		while token_i < (tokens.size - 1)
			token = tokens[token_i]
			
			if !(token[:type] == "word" && tokens[token_i + 1][:type] == "block")
				token_i += 1
				final_tokens << token
				next
			end
			
			final_tokens << {type: "func", func_name: token[:word_content], func_arg_block: tokens[token_i + 1]}
			token_i += 2
		end
		
		final_tokens << tokens.last
		
		final_tokens
	end
	
	
	def self.tokens_to_ast tokens	
		
		
		# Swap words and numbers for operations of type word and number
		token_i = 0
		
		while token_i < tokens.size
			token = tokens[token_i]
			
			if !["word", "number", "block", "string", "func"].include?(token[:type])
				token_i += 1
				next
			end
			
			case token[:type]
			when "word"
				tokens[token_i] = {type: "operation", op_type: "word", elements: [token[:word_content]]}
			when "number"
				tokens[token_i] = {type: "operation", op_type: "number", elements: [token[:number_content]]}
			when "string"
				tokens[token_i] = {type: "operation", op_type: "string", elements: [token[:str_content]]}
			when "block"
				tokens[token_i] = tokens_to_ast(token[:content])
			when "func"
				tokens[token_i] = {type: "operation", op_type: "func", elements: [token[:func_name], tokens_to_ast(token[:func_arg_block][:content])]}
			end
			
			token_i += 1
		end
		
		# Check for negation operations of type "-x"
		
		one_element_ast_ops = Config.one_element_ast_operations
		
		one_element_ast_ops.each do |operation|
		
			if operation[:check_direction] == -1
				token_i = tokens.size - 1
				token_i_change = -1
				check_condition = -> {token_i >= 0}
				check_boundary = 0
			elsif operation[:check_direction] == 1
				token_i = 0
				token_i_change = 1
				check_condition = -> {token_i < tokens.size}
				check_boundary = tokens.size - 1
			end			
			
			while check_condition.call
				token = tokens[token_i]
				
				if token[:type] != "sign"
					token_i += token_i_change
					next
				end
				
				if token[:sign_type] != operation[:sign_type]
					token_i += token_i_change
					next
				end
				
				# Check if this is the first token (and a minus sign), which means "[-]x"
				# Or check if this token is preceded by another sign, e.g. "+[-]x"
				if token_i == check_boundary || ["sign"].include?(tokens[token_i + token_i_change][:type])
					ast_node = {type: "operation", op_type: operation[:name], elements: [tokens[token_i - token_i_change]]}
					if token_i_change == -1
						tokens = tokens[...token_i] + [ast_node] + tokens[(token_i + 1 + 1)..]
					elsif token_i_change == 1
						tokens = tokens[...(token_i - 1)] + [ast_node] + tokens[(token_i + 1)..]
					end
					check_boundary -= token_i_change
					next
				end
				
				token_i += token_i_change
			end
			
		end
		
		
		# Math AST operations sorted in priority order
		two_element_ast_ops = Config.two_element_ast_operations
		
		two_element_ast_ops.each do |operations_group|
			
			if operations_group[:group_check_direction] == -1
				token_i = tokens.size - 1
				token_i_change = -1
				check_condition = -> {token_i >= 0}
			elsif operations_group[:group_check_direction] == 1
				token_i = 0
				token_i_change = 1
				check_condition = -> {token_i < tokens.size}
			end
			
			while check_condition.call
				token = tokens[token_i]
				
				if token[:type] != "sign"
					token_i += token_i_change
					next
				end
				
				operation_found = false
				
				operations_group[:group_operations].each do |operation|
					if token[:sign_type] != operation[:sign_type]
						next
					end
					
					elements = [tokens[token_i - 1], tokens[token_i + 1]]
					
					# Check if there are some non-operation elements, which shouldn't happen
					raise "Parsing error - something went wrong, compute elements were not operations" if elements.filter{|e| e[:type] != "operation"}.size > 0
					
					operation_found = true
					
					ast_node = {type: "operation", op_type: operation[:name], elements: }
					
					tokens = tokens[...(token_i - 1)] + [ast_node] + tokens[(token_i + 1 + 1)..]
					
					# token_i += token_i_change
					
					break
				end
				
				if !operation_found
					token_i += token_i_change
					next
				end
				
				# if token[:sign_type] != operation[:sign_type]
				# 	token_i += token_i_change
				# 	next
				# end
				# 
				# elements = [tokens[token_i - 1], tokens[token_i + 1]]
				# 
				# # Check if there are some non-operation elements, which shouldn't happen
				# raise "Parsing error - something went wrong, compute elements were not operations" if elements.filter{|e| e[:type] != "operation"}.size > 0
				# 
				# ast_node = {type: "operation", op_type: operation[:name], elements: }
				# 
				# tokens = tokens[...(token_i - 1)] + [ast_node] + tokens[(token_i + 1 + 1)..]
				# 
				# token_i += token_i_change
			end
			
		end	
		
		
		raise "Parsing error - something went wrong, tokens should've collapsed into a single AST, but didn't :(" if tokens.size != 1
		
		tokens[0]
	end

	def self.token_ast_to_ast(token_ast)
		final_ast = Hash.new
		
		final_ast[:type] = token_ast[:op_type]
		
		elements = token_ast[:elements]
		
		elements.map! do |el|
			if el.is_a?(Hash) && el.keys.include?(:type) && el[:type] == "operation"
				el = token_ast_to_ast(el)
			end
			el
		end
		
		final_ast[:elements] = elements
		
		final_ast
	end


	def self.str_to_ast str
		tokens = str_to_tokens(str)
		
		tokens = parse_blocks_from_tokens(tokens)
			
		tokens = parse_functions_from_tokens(tokens) if Config.parse_functions
		
		token_ast = tokens_to_ast(tokens)
		
		ast = token_ast_to_ast(token_ast)
		
		ast
	end
	
	# Strange looking thing to create an alias for str_to_ast
	class <<self
		alias_method :parse, :str_to_ast
	end  


	def self.run_ast ast, words=Hash.new, functions=Hash.new
		
		# p ast
		
		case ast[:type]
		when "word"
			return words[ast[:elements][0]]
		when "number"
			# if ast[:elements][0].include?(".")
			# 	return ast[:elements][0].to_f
			# else
			# 	return ast[:elements][0].to_i
			# end
			is_num, imm_value = Kompiler::Parsers.check_immediate_operand(ast[:elements][0])
			raise "AST recognition error - \"#{ast[:elements][0]}\" is not a number" if !is_num
			
			return imm_value[:value]
		when "string"
			return ast[:elements][0]
		when "func"
			func_name = ast[:elements][0]
			return Config.functions[func_name].call(run_ast(ast[:elements][1]))
		when "add"
			return run_ast(ast[:elements][0], words, functions) + run_ast(ast[:elements][1], words, functions)
		when "sub"
			return run_ast(ast[:elements][0], words, functions) - run_ast(ast[:elements][1], words, functions)
		when "mul"
			return run_ast(ast[:elements][0], words, functions) * run_ast(ast[:elements][1], words, functions)
		when "div"
			return run_ast(ast[:elements][0], words, functions) / run_ast(ast[:elements][1], words, functions)
		when "power"
			return run_ast(ast[:elements][0], words, functions) ** run_ast(ast[:elements][1], words, functions)
		when "negate"
			return -run_ast(ast[:elements][0], words, functions)
		when "bitshift_left"
			return run_ast(ast[:elements][0], words, functions) << run_ast(ast[:elements][1], words, functions)
		when "bitshift_right"
			return run_ast(ast[:elements][0], words, functions) >> run_ast(ast[:elements][1], words, functions)
		when "bit_or"
			return run_ast(ast[:elements][0], words, functions) | run_ast(ast[:elements][1], words, functions)
		when "bit_and"
			return run_ast(ast[:elements][0], words, functions) & run_ast(ast[:elements][1], words, functions)
		when "factorial"
			res = 1
			lim = run_ast(ast[:elements][0], words, functions)
			(1..lim).each do |n|
				res *= n
			end
			return res
		when "modulo"
			return run_ast(ast[:elements][0], words, functions) % run_ast(ast[:elements][1], words, functions)
		
		when "equal"
			return (run_ast(ast[:elements][0], words, functions) == run_ast(ast[:elements][1], words, functions)) ? 1 : 0
		when "not_equal"
			return (run_ast(ast[:elements][0], words, functions) != run_ast(ast[:elements][1], words, functions)) ? 1 : 0
		when "less_than"
			return (run_ast(ast[:elements][0], words, functions) < run_ast(ast[:elements][1], words, functions)) ? 1 : 0
		when "greater_than"
			return (run_ast(ast[:elements][0], words, functions) > run_ast(ast[:elements][1], words, functions)) ? 1 : 0
		when "less_or_eq"
			return (run_ast(ast[:elements][0], words, functions) <= run_ast(ast[:elements][1], words, functions)) ? 1 : 0
		when "greater_or_eq"
			return (run_ast(ast[:elements][0], words, functions) >= run_ast(ast[:elements][1], words, functions)) ? 1 : 0
		end
		
	
	end


end # Kompiler::Parsers::SymAST

end # Kompiler::Parsers

end # Kompiler
