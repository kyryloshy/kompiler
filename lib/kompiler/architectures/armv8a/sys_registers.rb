# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

class ARMv8A

def self.sys_registers
	@@sys_registers
end	

@@sys_registers = [
	{reg_name: "mpidr_el0", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>3, "op1"=>0, "CRn"=>0, "CRm"=>0, "op2"=>5}, rw_type: "ro"},
]

end # Kompiler::ARMv8A

end # Kompiler
