module Kompiler

class Architecture

@@instructions = []
@@registers = []
	
def self.set_arch instructions, registers
	@@instructions = instructions
	@@registers = registers
end

def self.load_arch(arch_name)
	require "kompiler/arch/#{arch_name.downcase}/load"
end

def self.instructions
	@@instructions
end

def self.registers
	@@registers
end

end

end