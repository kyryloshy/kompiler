require_relative 'registers.rb'
require_relative 'directives.rb'
require_relative 'instructions.rb'
require_relative 'mc_builder.rb'
require_relative 'parsers.rb'
require_relative 'compiler_functions.rb'



in_filename = ARGV[0]
out_filename = ARGV[1]

raise "No input file path provided" if !in_filename
raise "No output file path provided" if !out_filename

code = File.read(in_filename)

compiled_bytes_str = compile(code, in_filename)

File.open(out_filename, "wb") do |file|
	file.write compiled_bytes_str
end
