# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

module Architecture

@instructions = []
@registers = []

def self.set_arch instructions, registers
	@instructions = instructions
	@registers = registers
end

# def self.load_arch(arch_name)
# 	require "kompiler/arch/#{arch_name.downcase}/load"
# end

def self.instructions
	@instructions
end

def self.registers
	@registers
end

end

end