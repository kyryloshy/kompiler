# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

require 'kompiler/architectures/armv8a/instructions.rb'
require 'kompiler/architectures/armv8a/sys_instructions.rb'
require 'kompiler/architectures/armv8a/registers.rb'
require 'kompiler/architectures/armv8a/sys_registers.rb'
require 'kompiler/architectures/armv8a/simd_fp_instructions.rb'
require 'kompiler/architectures/armv8a/simd_fp_registers.rb'


Kompiler::Architecture.set_arch(Kompiler::ARMv8A.instructions + Kompiler::ARMv8A.sys_instructions + Kompiler::ARMv8A.simd_fp_instructions, Kompiler::ARMv8A.registers + Kompiler::ARMv8A.sys_registers + Kompiler::ARMv8A.simd_fp_registers)
