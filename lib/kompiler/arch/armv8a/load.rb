# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

require 'kompiler/arch/armv8a/instructions.rb'
require 'kompiler/arch/armv8a/registers.rb'


Kompiler::Architecture.set_arch(Kompiler::ARMv8A.instructions, Kompiler::ARMv8A.registers)