# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

module ARMv8A

def self.sys_registers
	@sys_registers
end	

@sys_registers = [
	{reg_name: "mpidr_el0", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>3, "op1"=>0, "CRn"=>0, "CRm"=>0, "op2"=>5}, rw_type: "ro"},
	
	{reg_name: "vbar_el1", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0, "CRn"=>0b1100, "CRm"=>0, "op2"=>0}, rw_type: "rw"},
	{reg_name: "vbar_el12", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b101, "CRn"=>0b1100, "CRm"=>0, "op2"=>0}, rw_type: "rw"},
	{reg_name: "vbar_el2", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b100, "CRn"=>0b1100, "CRm"=>0, "op2"=>0}, rw_type: "rw"},
	{reg_name: "vbar_el3", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b110, "CRn"=>0b1100, "CRm"=>0, "op2"=>0}, rw_type: "rw"},

	{reg_name: "currentEL", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b000, "CRn"=>0b0100, "CRm"=>0b0010, "op2"=>0b010}},
	
	{reg_name: "SPSR_EL1", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b000, "CRn"=>0b0100, "CRm"=>0b0000, "op2"=>0b000}},
	{reg_name: "SPSR_EL12", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b101, "CRn"=>0b0100, "CRm"=>0b0000, "op2"=>0b000}},
	{reg_name: "SPSR_EL2", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b100, "CRn"=>0b0100, "CRm"=>0b0000, "op2"=>0b000}},
	{reg_name: "SPSR_EL3", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b110, "CRn"=>0b0100, "CRm"=>0b0000, "op2"=>0b000}},
	
	{reg_name: "ELR_EL1", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b000, "CRn"=>0b0100, "CRm"=>0b0000, "op2"=>0b001}},
	{reg_name: "ELR_EL12", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b101, "CRn"=>0b0100, "CRm"=>0b0000, "op2"=>0b001}},
	{reg_name: "ELR_EL2", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b100, "CRn"=>0b0100, "CRm"=>0b0000, "op2"=>0b001}},
	{reg_name: "ELR_EL3", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b110, "CRn"=>0b0100, "CRm"=>0b0000, "op2"=>0b001}},
	
	{reg_name: "SCTLR_EL1", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b000, "CRn"=>0b0001, "CRm"=>0b0000, "op2"=>0b000}},
	{reg_name: "SCTLR_EL2", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b100, "CRn"=>0b0001, "CRm"=>0b0000, "op2"=>0b000}},
	{reg_name: "SCTLR_EL3", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b110, "CRn"=>0b0001, "CRm"=>0b0000, "op2"=>0b000}},
	
	{reg_name: "SCTLR2_EL1", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b000, "CRn"=>0b0001, "CRm"=>0b0000, "op2"=>0b011}},
	{reg_name: "SCTLR2_EL2", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b100, "CRn"=>0b0001, "CRm"=>0b0000, "op2"=>0b011}},
	{reg_name: "SCTLR2_EL3", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b110, "CRn"=>0b0001, "CRm"=>0b0000, "op2"=>0b011}},
	
	{reg_name: "HCR_EL2", reg_size: 64, reg_type: "sr", reg_encoding: {"op0"=>0b11, "op1"=>0b100, "CRn"=>0b0001, "CRm"=>0b0001, "op2"=>0b000}},
	
	# Special registers for the MSR (immediate) instruction (some of them were previously defined already)
	{reg_name: "SPSel", reg_type: "pstate_reg"},
	{reg_name: "DAIFSet", reg_type: "pstate_reg"},
	{reg_name: "DAIFClr", reg_type: "pstate_reg"},
	{reg_name: "UAO", reg_type: "pstate_reg"},
	{reg_name: "PAN", reg_type: "pstate_reg"},
	{reg_name: "ALLINT", reg_type: "pstate_reg"},
	{reg_name: "PM", reg_type: "pstate_reg"},
	{reg_name: "SSBS", reg_type: "pstate_reg"},
	{reg_name: "DIT", reg_type: "pstate_reg"},
	{reg_name: "SVCRSM", reg_type: "pstate_reg"},
	{reg_name: "SVCRZA", reg_type: "pstate_reg"},
	{reg_name: "SVCRSMZA", reg_type: "pstate_reg"},
	{reg_name: "TCO", reg_type: "pstate_reg"},
]

end # Kompiler::ARMv8A

end # Kompiler
