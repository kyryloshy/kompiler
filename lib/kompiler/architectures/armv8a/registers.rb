# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

module ARMv8A

def self.registers
	@registers
end	

@registers = [
	{:reg_name=>"w0", :reg_value=>0, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w1", :reg_value=>1, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w2", :reg_value=>2, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w3", :reg_value=>3, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w4", :reg_value=>4, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w5", :reg_value=>5, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w6", :reg_value=>6, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w7", :reg_value=>7, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w8", :reg_value=>8, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w9", :reg_value=>9, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w10", :reg_value=>10, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w11", :reg_value=>11, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w12", :reg_value=>12, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w13", :reg_value=>13, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w14", :reg_value=>14, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"w15", :reg_value=>15, :reg_size=>32, :reg_type=>"gpr"},
	{:reg_name=>"x0", :reg_value=>0, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x1", :reg_value=>1, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x2", :reg_value=>2, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x3", :reg_value=>3, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x4", :reg_value=>4, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x5", :reg_value=>5, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x6", :reg_value=>6, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x7", :reg_value=>7, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x8", :reg_value=>8, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x9", :reg_value=>9, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x10", :reg_value=>10, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x11", :reg_value=>11, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x12", :reg_value=>12, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x13", :reg_value=>13, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x14", :reg_value=>14, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x15", :reg_value=>15, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x16", :reg_value=>16, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x17", :reg_value=>17, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x18", :reg_value=>18, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x19", :reg_value=>19, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x20", :reg_value=>20, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x21", :reg_value=>21, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x22", :reg_value=>22, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x23", :reg_value=>23, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x24", :reg_value=>24, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x25", :reg_value=>25, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x26", :reg_value=>26, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x27", :reg_value=>27, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x28", :reg_value=>28, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x29", :reg_value=>29, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x30", :reg_value=>30, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"x31", :reg_value=>31, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"lr", :reg_value=>30, :reg_size=>64, :reg_type=>"gpr"},
	{:reg_name=>"sp", :reg_value=>31, :reg_size=>64, :reg_type=>"gpr"},
]

end # Kompiler::ARMv8A

end # Kompiler
