# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

#
# Implements a custom AST structure and interpreter for instructions on how to build the instruction's machine code (MC).
#
# @MC_AST_NODES contains a list of all available instructions / AST nodes for building machine code.
# Each entry's structure is:
#  name - contains the node's / instruction's name
#  n_args - either an integer or "any". Contains the amount of arguments this instruction must receive.
#  func - a lambda receiving the arguments and the current program's state as inputs. Should output the instruction's result.
#  eval_args - optional, default true. Specifies whether to pre-evaluate the node's arguments.
#
# A MC instruction example:
# ["get_bits", ["get_current_address"], 0, 10]
# Which returns an array of ten integers, or bits, of the current address.
# 
# Each MC instruction is in the form of an array with a string, the instruction's name, as the first element.
# All other elements will count as arguments.
# For most nodes, the arguments will be evaluated / computed before calling the node's logic. For example, in:
# ["get_bits", ["get_current_address"], 0, 10]
# ["get_current_address"] will be evaluted first, and then the result will be passed into get_bits. This is similar to a Ruby piece of code like this:
# get_bits(get_current_address(), 0, 10)
#
# In more special nodes that have eval_args = false, such as the if_eq_else node, the arguments aren't pre-evaluated, which is required in an if-statement scenario. E.g., an error shouldn't be thrown before a check that the error must be raised.
#
#
# Main functions are:
#  build_mc - builds machine code from an input AST
#  run_mc_ast - runs an MC AST node
#  is_ast_node - returns if an object is an AST node, by checking whether it is an array with the first element being a string
#


module Kompiler

module MachineCode_AST

@MC_AST_NODES = [
	{name: "get_operand", n_args: 1, func: lambda {|args, state| state[:operands][args[0]][:value]} },
	{name: "get_operand_hash", n_args: 1, func: lambda {|args, state| state[:operands][args[0]] } },
	{name: "get_bits", n_args: 3, func: lambda {|args, state| (args[1]...(args[1] + args[2])).map{|bit_i| args[0][bit_i]} } },
	{name: "get_bits_signed", n_args: 3, func: lambda do |args, state|
		if args[1] == 0
			# If sign should be included
			(args[0] >= 0 ? [0] : [1]) + (0...(args[2] - 1)).map{|bit_i| args[0].abs[bit_i]}
		else
			# If sign shouldn't be included, since the bit range omits it
			((args[1] - 1)...(args[1] + args[2] - 1)).map{|bit_i| args[0].abs[bit_i]}
		end
	end},
	{name: "reverse", n_args: 1, func: lambda {|args, state| args[0].reverse } },
	{name: "encode_gp_register", n_args: 1, func: lambda {|args, state| args[0][:reg_value] } },
	{name: "add", n_args: 2, func: lambda {|args, state| args[0] + args[1] } },
	{name: "subtract", n_args: 2, func: lambda {|args, state| args[0] - args[1] } },
	{name: "multiply", n_args: 2, func: lambda {|args, state| args[0] * args[1] } },
	{name: "divide", n_args: 2, func: lambda {|args, state| args[0] / args[1] } },
	{name: "modulo", n_args: 2, func: lambda {|args, state| args[0] % args[1] } },
	{name: "get_current_address", n_args: 0, func: lambda {|args, state| state[:current_address] } },
	{name: "get_label_address", n_args: 1, func: lambda {|args, state| state[:labels].include?(args[0]) ? state[:labels][args[0]] : raise("Label \"#{args[0]}\" not found: Program build not possible") } },
	{name: "bits", n_args: "any", func: lambda {|args, state| args } },
	{name: "if_eq_else", n_args: 4, eval_args: false, func: lambda {|args, state| (eval_mc_node_arg(args[0], state) == eval_mc_node_arg(args[1], state)) ? eval_mc_node_arg(args[2], state) : eval_mc_node_arg(args[3], state) }},
	{name: "case", n_args: "any", eval_args: false, func: lambda do |args, state| 
		value = eval_mc_node_arg(args[0], state)
		raise "Incorrect use of the \"case\" MC Constructor: incorrect number of arguments. This is likely a problem with the architecture, not the program being compiled." if (args.size - 2) % 2 != 0
		args[1...-1].each_slice(2) do |check_value, block|
			if value == check_value
				return eval_mc_node_arg(block, state)
			end
		end
		eval_mc_node_arg(args.last, state)
	end},
	
	{name: "raise_error", n_args: 1, func: lambda {|args, state| raise args[0]; [] } },
	{name: "raise_warning", n_args: 1, func: lambda {|args, state| puts args[0]; [] } },
	
	{name: "get_key", n_args: 2, func: lambda {|args, state| args[0].keys.include?(args[1]) ? args[0][args[1]] : raise("MC Constructor get_key Error: The key \"#{args[1]}\" doesn't exist - Program build not possible. This is likely a problem with the ISA configuration, not the program being compiled.") }},

	# Concatenation of get_key and get_operand through get_key(get_operand(arg1), arg2)
	{name: "get_operand_key", n_args: 2, func: lambda do |args, state|
		op = state[:operands][args[0]][:value]
		op.keys.include?(args[1]) ? op[args[1]] : raise("MC Constructor get_operand_key Error: key \"#{args[1]}\" doesn't exist. This is likely an error with the ISA configuration, not the program being compiled.")
	end},

	{name: "concat", n_args: "any", func: lambda {|args, state| args.flatten}},
	{name: "set_var", n_args: 2, func: lambda {|args, state| state[:instruction_variables][args[0]] = args[1]; [] }},
	{name: "get_var", n_args: 1, func: lambda {|args, state| state[:instruction_variables].keys.include?(args[0]) ? state[:instruction_variables][args[0]] : raise("Instruction variable \"#{args[0]}\" not found: Program build not possible. This is likely a program with the ISA configuration, not the program being compiled.") }},
	
	# String manipulations
	{name: "downcase_str", n_args: 1, func: lambda {|args, state| args[0].downcase }},
	
	# Bit manipulations
	{name: "bit_and", n_args: 2, func: lambda {|args, state| args[0] & args[1] }},
	{name: "bit_or", n_args: 2, func: lambda {|args, state| args[0] | args[1] }},

	# Ensure equality between all arguments. Last argument provides the error message if not equal
	{name: "ensure_eq", n_args: "any", func: lambda do |args, state|
		args[1...-1].each do |arg|
			if args[0] != arg
				raise args.last
			end
		end
		[]
	end}
]

def self.is_ast_node(val)
	val.is_a?(Array) && (val.size >= 1) && val[0].is_a?(String)
end

# If an argument is a node, evaluates it. Otherwise just returns the argument
def self.eval_mc_node_arg(arg, state)
	is_ast_node(arg) ? run_mc_ast(arg, state) : arg
end

def self.run_mc_ast(node, state)
	
	node_name = node[0]
	node_args = node[1..]
	
	
	node_logic = @MC_AST_NODES.filter{|any_node| any_node[:name] == node_name}[0]
	
	if !node_logic
		raise "MC Node \"#{node_name}\" wasn't found. Cannot build the program"
	end
	
	if !node_logic.keys.include?(:eval_args) || node_logic[:eval_args] != false
		node_args.map!{|arg| eval_mc_node_arg(arg, state) }
	end
	
	raise "Undefined node \"#{node_name}\"" if !node_logic
	
	# Check if the amount of arguments is correct for the node
	raise "Incorrect node use for \"#{node_name}\": Expected #{node_logic[:n_args]} operands, but received #{node_args.size}" if (node_logic[:n_args] != "any") && (node_logic[:n_args] != node_args.size)
	
	node_logic[:func].call(node_args, state)
end


def self.build_mc(mc_constructor, state)
	final = []
	mc_constructor.each do |ast_node|		
		
		ast_result = run_mc_ast(ast_node, state)
		
		# Check if ast_result is only zeros and ones
		is_element_zero_or_one = ast_result.map{|el| [0, 1].include?(el)}
		if is_element_zero_or_one.include?(false)
			raise "MC AST Build resulted in a non-bit value (#{ast_result}): Cannot build the program"
		end
		
		final += ast_result
	end
	
	return final
end


end # Kompiler::MC_AST

end # Kompiler
