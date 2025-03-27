# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

module ARMv8A

def self.simd_fp_registers
	@simd_fp_registers
end	

@simd_fp_registers = [
	
]

(0..31).each do |reg_i|
	@simd_fp_registers << {reg_name: "q#{reg_i}", reg_type: "simd_fp_reg", re_num: reg_i}
end


end # Kompiler::ARMv8A

end # Kompiler
