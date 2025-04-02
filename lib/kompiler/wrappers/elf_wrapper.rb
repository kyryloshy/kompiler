#
# This file implements ELF Wrappers for raw programs.
#

require 'kompiler/wrappers/packed_bytes'


module Kompiler

	module Wrappers

	module ELF

		# ELF Wrap Object
		# Wraps a raw program in the ELF relocatable format
		#
		# Arguments:
		# code - raw byte string
		# symbols - a list of labels and other objects and their corresponding values
		# options - a hash of configurable options:
		#            elf_class - 32 for ELFClass32 or 64 for ELFClass64 (default is 64)
		#            machine   - a raw machine ID to fill in the e_machine field
		# 
		def self.wrap_obj code, symbols, **options

			elf_class = options[:elf_class] || 64
			e_machine = options[:machine]
			
			sections, shstrndx = create_default_sections(code, symbols, elf_class: elf_class).values
			
			output = build(sections: sections, machine: e_machine, elf_class: elf_class, e_shstrndx: shstrndx, e_type: 1)
			
			output
		end


		# ELF Wrap Executable
		# Wraps a raw program in the ELF executable format
		#
		# Arguments:
		# code - raw byte string
		# options - a hash of configurable options:
		#           elf_class - 32 for ELFClass32 or 64 for ELFClass64 (default is 64)
		#           machine   - a raw machine ID to fill in the e_machine field
		#           vaddr     - virtual address for the program and entry (default is 0x80000)
		def self.wrap_exec code, symbols, **options

			elf_class = options[:elf_class] || 64
			e_machine = options[:machine]
			vaddr = options[:vaddr] || 0x80000

			sections, shstrndx = create_default_sections(code, symbols, elf_class: elf_class).values

			sections[1][:addr] = vaddr

			segments = [
				{
					type: 1, # Loadable segment
					flags: 7, # Execute, write, read permissions
					vaddr: vaddr, # Virtual address of segment in memory
					# content: code,
					content_section_i: 1,
					align: 4
				},
			]

			output = build(sections: sections, segments: segments, machine: e_machine, elf_class: elf_class, e_type: 2, virtual_entry_address: vaddr, e_shstrndx: shstrndx)
			
			output
		end


		

		# Converts a label hash of name-address pairs into an array of symbols
		def self.labels_to_symbols labels
			out = []
			labels.each do |name, value|
				out << {name: name, value: value, type: 1, binding: 0}
			end
			out
		end


		# Build ELF
		# Builds an ELF from provided sections, segments, and other options
		# 
		# Arguments:
		#  sections - ELF sections (structure below)
		#  segments - ELF segments (structure below)
		#  machine  - a raw machine ID for the ELF header
		#  virtual_entry_address - the virtual entry address for the ELF header
		#  elf_class - the ELF class (32 or 64)
		#  e_shstrndx - the value for ELF header's e_shstrndx field (index of the section header string table section)
		#  e_type - the value for ELF header's e_type field (e.g., 1 for relocatable, 3 for executable)
		#
		def self.build sections: [], segments: [], machine: nil, virtual_entry_address: 0, elf_class: 64, e_shstrndx: 0, e_type: 0

			raise "Machine ID not specified for the ELF header." if machine == nil

			case elf_class
			when 64
				elf_addr = 8
				elf_off = 8
				elf_half = 2
				elf_word = 4
				elf_char = 1
				elf_xword = 8
				elf_header_size = 64
				elf_shentsize = 64
				elf_phentsize = 56
			when 32
				elf_addr = 4
				elf_off = 4
				elf_half = 2
				elf_word = 4
				elf_char = 1
				elf_xword = 4
				elf_header_size = 52
				elf_shentsize = 40
				elf_phentsize = 32
			else
				raise "Invalid elf_class - must be 32 or 64."
			end

			# Calculate section header and program header sizes
			sh_size = sections.size * elf_shentsize
			ph_size = segments.size * elf_phentsize

			# Calculate the offsets for the section header and program header
			# In this method, the section header is placed right after the ELF header, and the program header is placed right after the section header
			elf_shoff = elf_header_size
			elf_phoff = elf_shoff + sh_size
			
			
			file_content = PackedBytes.new

			elf_header = PackedBytes.new

			e_ident = PackedBytes.new

			# Magic number
			e_ident.bytes [127]
			e_ident.bytes "ELF"

			# EI_Class
			case elf_class
			when 64
				e_ident.bytes 2, elf_char
			when 32
				e_ident.bytes 1, elf_char
			end

			# EI_Data (LSB)
			e_ident.bytes 1, elf_char


			# EI_Version (current)
			e_ident.bytes 1, elf_char

			e_ident.align 16, "\0"

			elf_header.add e_ident

			# E_Type (input)
			elf_header.bytes e_type, elf_half

			# E_Machine (input)
			elf_header.bytes machine, elf_half

			# E_version (current)
			elf_header.bytes 1, elf_word

			# E_entry (input)
			elf_header.bytes virtual_entry_address, elf_addr

			# E_phoff (calculated earlier)
			# If there aren't any segments, the elf_phoff should be zero
			if segments.size == 0
				elf_header.bytes 0, elf_off
			else
				elf_header.bytes elf_phoff, elf_off
			end
			
			# E_shoff (calculated earlier)
			# If there aren't any sections, the elf_shoff should be zero
			if sections.size == 0
				elf_header.bytes 0, elf_off
			else
				elf_header.bytes elf_shoff, elf_off
			end
	
			# E_flags
			elf_header.bytes 0, elf_word

			# E_ehsize (ELF header size)
			elf_header.bytes elf_header_size, elf_half

			# E_phentsize
			elf_header.bytes elf_phentsize, elf_half

			# E_phnum
			elf_header.bytes segments.size, elf_half

			# E_shentsize
			elf_header.bytes elf_shentsize, elf_half

			# E_shnum
			elf_header.bytes sections.size, elf_half

			# E_shstrndx
			elf_header.bytes e_shstrndx, elf_half

			file_content.add elf_header


			# Used later
			sections_contents_offset = elf_phoff + ph_size
			
			sections_content = PackedBytes.new
			
			sections.each_with_index do |section, section_i|
				if !section.keys.include?(:content)
					section[:size] = 0
					section[:offset] = 0
					next
				end

				matching_segments = segments.filter{_1[:content_section_i] == section_i}

				largest_alignment = matching_segments.map{|segment| segment[:align] || 1}.max || 1

				file_offset = sections_content.result.bytesize + sections_contents_offset

				if file_offset % largest_alignment != 0
					sections_content.bytes [0] * (largest_alignment - (file_offset % largest_alignment))
				end

				section[:size] = section[:content].bytesize
				section[:offset] = sections_content.result.bytesize + sections_contents_offset

				matching_segments.each do |segment|
					segment[:offset] = 0 if !segment.keys.include?(:offset)
					segment[:offset] += section[:offset]
					
					segment[:size] = section[:size] if !segment.keys.include?(:size)
				end

				sections_content.add section[:content]
			end


			segments_content = PackedBytes.new
			
			segments_contents_offset = sections_contents_offset + sections_content.result.bytesize

			segments.each_with_index do |segment, segment_i|

				if !segment.keys.include?(:align)
					segment[:align] = 1
				end

				if !segment.keys.include?(:vaddr)
					segment[:vaddr] = 0
				end

				if !segment.keys.include?(:paddr)
					segment[:paddr] = segment[:vaddr]
				end

				if segment.keys.include?(:content)
					segment[:size] = segment[:content].bytesize
				end

				if !segment.keys.include?(:vsize)
					segment[:vsize] = segment[:size]
				end

				if segment[:vaddr] % segment[:align] != 0
					raise "Improper segment at index #{segment_i} - the virtual address is not aligned to the specified alignment boundary."
				end


				if segment.keys.include? :content_section_i
					next
				end
				

				# ELF requires file_offset and vaddr to be a multiple of the alignment value
				
				file_offset = segments_contents_offset + segments_content.result.bytesize

				pad_amount = 0
				if file_offset % segment[:align] != 0
					pad_amount = segment[:align] - (file_offset % segment[:align])
				end

				segments_content.bytes "\0" * pad_amount

				segment[:offset] = segments_content.result.bytesize + segments_contents_offset
				segments_content.add segment[:content]

			end


			sh = PackedBytes.new

			sections.each do |section|
				sh.bytes section[:name_offset], elf_word
				sh.bytes section[:type], elf_word
				sh.bytes section[:flags], elf_xword
				sh.bytes section[:addr], elf_addr
				sh.bytes section[:offset], elf_off
				sh.bytes section[:size], elf_xword
				sh.bytes section[:link], elf_word
				sh.bytes section[:info], elf_word
				sh.bytes section[:addralign], elf_xword
				sh.bytes section[:entsize], elf_xword
			end


			file_content.add sh


			ph = PackedBytes.new

			segments.each do |segment|
				ph.bytes segment[:type], elf_word
				ph.bytes segment[:flags], elf_word
				ph.bytes segment[:offset], elf_off
				ph.bytes segment[:vaddr], elf_addr
				ph.bytes segment[:paddr], elf_addr
				ph.bytes segment[:size], elf_xword
				ph.bytes segment[:vsize], elf_xword
				ph.bytes segment[:align], elf_xword
			end

			file_content.add ph


			file_content.add sections_content

			file_content.add segments_content


			return file_content.result
		end



		# Builds a basic section structure with one progbits section and one symbol table
		
		def self.create_default_sections program_bytes, symbols, elf_class: 64

			case elf_class
			when 64
				symtab_ent_size = 24
				elf_char = 1
				elf_half = 2
				elf_word = 4
				elf_addr = 8
				elf_off = 8
				elf_xword = 8
			when 32
				symtab_ent_size = 16
				elf_char = 1
				elf_half = 2
				elf_word = 4
				elf_addr = 8
				elf_off = 8
				elf_xword = 8
			end

			sym_strtab_section_index = 3
			sh_strtab_section_index = 4
			symtab_section_index = 2
			progbits_section_index = 1

			sections = [
				# First section is all zeros
				{
					type: 0,
					flags: 0,
					addr: 0,
					link: 0,
					info: 0,
					addralign: 0,
					entsize: 0,
				},
				{
					name: ".text",
					type: 1,
					flags: 7,
					addr: 0,
					link: 0,
					info: 0,
					addralign: 4,
					entsize: 0,
					content: program_bytes,
				},
				{
					name: ".symtab",
					type: 2,
					flags: 0,
					addr: 0,
					link: sym_strtab_section_index, # Index of string table used for symbol names
					info: symbols.size + 1, # Index of first non-local symbol
					addralign: 0,
					entsize: symtab_ent_size,
					content: "",
				},
				{
					name: ".strtab",
					type: 3,
					flags: 0,
					addr: 0,
					link: 0,
					info: 0,
					addralign: 0,
					entsize: 0,
					content: "",
				},
				{
					name: ".shstrtab",
					type: 3,
					flags: 0,
					addr: 0,
					link: 0,
					info: 0,
					addralign: 0,
					entsize: 0,
					content: "",
				},
			]

			symtab = PackedBytes.new

			# First section is all zeros
			symtab.bytes [0] * symtab_ent_size

			
			symtab_string_table_content = "\0".encode("ASCII")

			symbols.each do |symbol|

				if symbol.keys.include? :name
					name_offset = symtab_string_table_content.bytesize
					symtab_string_table_content << symbol[:name] + "\0"
				else
					name_offset = 0
				end

				# name
				symtab.bytes name_offset, elf_word

				symbol_info = symbol[:type] | (symbol[:binding] << 4)

				# info
				symtab.bytes symbol_info, elf_char

				# other (must be zero)
				symtab.bytes 0, elf_char

				# section index of where the symbol is located
				symtab.bytes progbits_section_index, elf_half

				# symbol value
				symtab.bytes symbol[:value], elf_addr

				# symbol size
				symbol_size = symbol[:size] || 0
				symtab.bytes symbol_size, elf_xword
			end

			sections[symtab_section_index][:content] = symtab.result
			sections[sym_strtab_section_index][:content] = symtab_string_table_content


			sections_string_table_content = "\0"

			sections.each_with_index do |section, section_i|
				if section.keys.include? :name
					section[:name_offset] = sections_string_table_content.bytesize
					sections_string_table_content << section[:name] + "\0"
				else
					section[:name_offset] = 0
				end
			end

			sections[sh_strtab_section_index][:content] = sections_string_table_content

			return {sections: sections, shstrndx: sh_strtab_section_index}
			
		end

	end # Kompiler::ELF
	end # Kompiler::Wrappers

end # Kompiler
