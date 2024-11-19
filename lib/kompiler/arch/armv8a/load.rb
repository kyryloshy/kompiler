require 'kompiler/arch/armv8a/instructions.rb'
require 'kompiler/arch/armv8a/registers.rb'


Kompiler::Architecture.set_arch(Kompiler::ARMv8A.instructions, Kompiler::ARMv8A.registers)