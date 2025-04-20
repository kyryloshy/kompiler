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
			
			output = build(sections: sections, e_machine: e_machine, elf_class: elf_class, e_shstrndx: shstrndx, e_type: 1)
			
			output
		end


		# ELF Wrap Executable
		# Wraps a raw program in the ELF executable format
		#
		# Arguments:
		# code - raw byte string
		# options - a hash of configurable options:
		#           machine   - a raw machine ID to fill in the e_machine field (default is 0)
		#           elf_class - 32 for ELFClass32 or 64 for ELFClass64 (default is 64)
		#           vaddr     - virtual address for the program and entry (default is 0x80000)
		#           align     - alignment value for the load segment (default is 0x1000)
		#           flags     - segment flags (default is 0b111, bits are in form 0bRWX)
		def self.wrap_exec code, symbols, **options

			elf_class = options[:elf_class] || 64
			e_machine = options[:machine] || 0
			vaddr = options[:vaddr] || 0x80000
			align = options[:align] || 0x1000
			flags = options[:flags] || 0b111

			sections, shstrndx = create_default_sections(code, symbols, elf_class: elf_class).values

			sections[1][:addr] = vaddr

			segments = [
				{
					type: 1, # Loadable segment
					flags: flags, # Execute, write, read permissions
					vaddr: vaddr, # Virtual address of segment in memory
					# content: code,
					content_section_i: 1,
					align: align
				},
			]

			output = build(sections: sections, segments: segments, e_machine: e_machine, elf_class: elf_class, e_type: 2, virtual_entry_address: vaddr, e_shstrndx: shstrndx)
			
			output
		end


		

		# Converts a label hash of name-address pairs into an array of symbols
		def self.labels_to_symbols labels, vaddr: 0
			out = []
			labels.each do |name, value|
				out << {name: name, value: value + vaddr, type: 0, binding: 0}
			end
			out
		end

		# Converts a values hash of name-value pairs into an array of symbols
		def self.values_to_symbols values
			out = []
			values.each do |name, value|
				out << {name: name, value: value, type: 0, binding: 0}
			end
		end


		# Build ELF
		# Builds an ELF from provided sections, segments, and other options
		# 
		# Arguments:
		#  sections - ELF sections (structure below)
		#  segments - ELF segments (structure below)
		#  virtual_entry_address - the virtual entry address for the ELF header (default is 0)
		#  elf_class - the ELF class (32 or 64) (default is 0)
		#  e_machine  - a raw machine ID for the ELF header (default is 0)
		#  e_shstrndx - the value for ELF header's e_shstrndx field (index of the section header string table section) (default is 0)
		#  e_type - the value for ELF header's e_type field (e.g., 1 for relocatable, 3 for executable) (default is 0)
		#  e_os_abi - the value for the ELF Identification header's osabi field (default is 0) (not used with elf_class = 32)
		#  e_abi_version - the value for the ELF Identification header's abiversion field (default is 0) (not used with elf_class = 32)
		#
		# Section structure:
		#  name_offset - section's name field value
		#  type - section's type field value
		#  flags - section's flags field value
		#  addr - section's addr field value
		#  link - section's link field value
		#  info - section's info field value
		#  addralign - section's addralign field value
		#  entsize - section's entsize field value
		#  content - section's content (offset and size will be computed automatically)  
		#  segment_content_i - index of segment that contains this section's content (useful to remove repeated info and 'link' a section with a segment)
		#  offset - if segment_content_i is present, an optional offset can be added to take only part of the segment's content (default is 0)
		#  size - if segment_content_i is present, size can be provided optionally to take only part of the segment's content (default is 0)
		#
		# Segment structure:
		#  type - segment's type field value
		#  flags - segment's flags field value
		#  vaddr - segment's vaddr field value (default is 0)
		#  paddr - segment's paddr field value (default is value of vaddr)
		#  vsize - segment's memsz / vsize field value (default is same as content.size)
		#  align - segment's alignment value. This will also ensure that the segment's content is aligned to this boundary in the file
		#  content - segment's content (offset and size will be computed automatically)
		#  section_content_i - index of section that contaisn this segment's content (idea is same as section[:segment_content_i])
		#  offset - idea same as section[:offset]
		#  size - idea same as section[:size]
		#
		def self.build sections: [], segments: [], virtual_entry_address: 0, elf_class: 64, e_machine: 0, e_shstrndx: 0, e_type: 0, e_os_abi: 0, e_abi_version: 0


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

			e_ident.bytes e_os_abi, 1 # OS_ABI
			e_ident.bytes e_abi_version, 1 # ABI_VERSION
			
			e_ident.bytes [0] * 6 # Pad to 15

			e_ident.bytes [16] # E_Ident size

			elf_header.add e_ident

			# E_Type (input)
			elf_header.bytes e_type, elf_half

			# E_Machine (input)
			elf_header.bytes e_machine, elf_half

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
					segment[:offset] ||= 0

					segment[:size] ||= section[:size] - segment[:offset]

					segment[:offset] += section[:offset]	
				end

				sections_content.add section[:content]
			end


			segments_content = PackedBytes.new
			
			segments_contents_offset = sections_contents_offset + sections_content.result.bytesize

			segments.each_with_index do |segment, segment_i|

				segment[:align] ||= 1

				segment[:vaddr] ||= 0

				segment[:paddr] ||= segment[:vaddr]

				if segment.keys.include?(:content)
					segment[:size] = segment[:content].bytesize
				end

				segment[:vsize] ||= segment[:size]


				if segment[:vaddr] % segment[:align] != 0
					raise "Improper segment at index #{segment_i} - the virtual address is not aligned to the specified alignment boundary."
				end

				# If the segment uses :content, add the segment's content to the file and compute the offset
				if !segment.keys.include?(:content_section_i)

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


				# If some sections depend on the segment, update their values
				
				matching_sections = sections.filter{_1[:segment_content_i] == segment_i}

				matching_sections.each do |section|
					section[:offset] ||= 0

					section[:size] ||= segment[:size] - section[:offset]
					
					section[:offset] += segment[:offset]
				end

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

			case elf_class
			when 64
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
			when 32
				segments.each do |segment|
					ph.bytes segment[:type], elf_word
					ph.bytes segment[:offset], elf_off
					ph.bytes segment[:vaddr], elf_addr
					ph.bytes segment[:paddr], elf_addr
					ph.bytes segment[:size], elf_word
					ph.bytes segment[:vsize], elf_word
					ph.bytes segment[:flags], elf_word
					ph.bytes segment[:align], elf_word
				end
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
			]


			symbols.map! do |sym|
				sym[:section_index] = sym[:section_index] || progbits_section_index
				sym
			end

			symtab_section, sym_strtab_contents = create_symtab_section(symbols, link: sym_strtab_section_index, info: "first-non-local", elf_class: elf_class)

			sections << symtab_section
			
			sections << create_strtab_section(sym_strtab_contents, name: ".strtab", elf_class: elf_class)

			
			sections << create_strtab_section("\0", name: ".shstrtab", elf_class: elf_class)


			sections.each_with_index do |section, section_i|
				if section.keys.include? :name
					section[:name_offset] = sections[sh_strtab_section_index][:content].bytesize
					sections[sh_strtab_section_index][:content] << section[:name] + "\0"
				else
					section[:name_offset] = 0
				end
			end


			return {sections: sections, shstrndx: sh_strtab_section_index}
			
		end



		# Creates a section structure with type symtab, builds symbol entries and symbol string table contents
		# Returns [symtab_section, sym_strtab_contents]
		#
		# Arguments:
		#  symbols - an array of hashes with info about each symbol (structure below)
		#  **options - additional options
		#
		# Options are:
		#  elf_class - elf class, either 64 or 32 (default is 64)
		#  name - the symtab section's name (default is .symtab)
		#  link - the symtab section's link field value (default is 0)
		#  info - the symtab section's info field value (default is 0)
		#         set to "first-non-local" to auto-sort all symbols and
		#         set info field to the index of the first non-local symbol
		#  flags - the symtab section's flags field value (default is 0)
		#
		# Symbol hash structure:
		#  :name - the symbol's name (optional)
		#  :type - symbol type (0 - notype, 1 - object, 2 - func, 3 - section, 4 - file)
		#  :binding - symbol binding (0 - local, 1 - global, 2 - weak)
		#  :section_index - corresponding section's index (0 - undef, 0xfff1 - absolute, 0xfff2 - common block)
		#  :value - the symbol's value
		#  :size - the symbol's size (default is 0)
		#
		def self.create_symtab_section symbols, **options

			elf_class = options[:elf_class] || 64

			section_name = options[:name] || ".symtab"
			section_link = options[:link] || 0
			section_info = options[:info] || 0
			section_flags = options[:flags] || 0

			# Check if the auto option was selected
			if section_info == "first-non-local"

				# Sort symbols for global symbols to come last

				local_symbols = symbols.filter{_1[:binding] == 0}
				non_local_symbols = symbols.filter{_1[:binding] != 0}

				first_non_local_i = local_symbols.size

				# Sort symbols for local ones to come first
				symbols = local_symbols + non_local_symbols

				# + 1 because the first symbol will be pre-forced to be all zeros and local
				section_info = first_non_local_i + 1
			end


			case elf_class
			when 64
				elf_char = 1
				elf_half = 2
				elf_word = 4
				elf_addr = 8
				elf_xword = 8
				symtab_ent_size = 24
			when 32
				elf_char = 1
				elf_half = 2
				elf_word = 4
				elf_addr = 4
				elf_xword = 4
				symtab_ent_size = 16
			end

			symtab_content = PackedBytes.new
			sym_strtab_contents = "\0".encode "ASCII"

			# First entry must be all zeros
			symtab_content.bytes [0] * symtab_ent_size

			case elf_class
			when 64
				symbols.each do |symbol|
					if symbol.keys.include? :name
						name_offset = sym_strtab_contents.bytesize
						sym_strtab_contents << symbol[:name] + "\0"
					else
						name_offset = 0
					end

					# name
					symtab_content.bytes name_offset, elf_word

					symbol_info = symbol[:type] | (symbol[:binding] << 4)
					# info
					symtab_content.bytes symbol_info, elf_char

					# other
					symtab_content.bytes 0, elf_char

					# shndx
					symtab_content.bytes symbol[:section_index], elf_half

					# value
					symtab_content.bytes symbol[:value], elf_addr

					# size
					symtab_content.bytes symbol[:size] || 0, elf_xword
				end
			when 32
				symbols.each do |symbol|
					if symbol.keys.include? :name
						name_offset = sym_strtab_contents.bytesize
						sym_strtab_contents << symbol[:name] + "\0"
					else
						name_offset = 0
					end

					# name
					symtab_content.bytes name_offset, elf_word

					# value
					symtab_content.bytes symbol[:value], elf_addr

					# size
					symtab_content.bytes symbol[:size] || 0, elf_xword
					
					symbol_info = symbol[:type] | (symbol[:binding] << 4)
					# info
					symtab_content.bytes symbol_info, elf_char

					# other
					symtab_content.bytes 0, elf_char

					# shndx
					symtab_content.bytes symbol[:section_index], elf_half
				end
			end


			symtab_section = {
				name: ".symtab",
				type: 2,
				flags: section_flags,
				addr: 0,
				link: section_link,
				info: section_info,
				addralign: 0,
				entsize: symtab_ent_size,
				content: symtab_content.result,
			}

			return symtab_section, sym_strtab_contents
			
		end


		# Create string table section
		# Creates a hash with information for a string table section
		# 
		# Arguments:
		#  string_content - the string table's content
		#  **options - additional options
		#
		# Options:
		#  name - the section's name (default is nil)
		#  info - the section's info field value (default is 0)
		#  link - the section's link field value (default is 0)
		#  flags - the section's flags field value (default is 0)
		#  addr - the section's addr field value (default is 0)
		#  addralign - the section's addralign field value (default is 0)
		#  elf_class - ELF class 32 or 64 (not used)
		#
		def self.create_strtab_section string_content, **options
			name = options[:name]
			info = options[:info] || 0
			link = options[:link] || 0
			flags = options[:flags] || 0
			addr = options[:addr] || 0
			addralign = options[:addralign] || 0


			section = {
				type: 3,
				info: info,
				link: link,
				flags: flags,
				addr: addr,
				addralign: addralign,
				content: string_content,
				entsize: 0,
			}

			section[:name] = name if name != nil

			return section
		end

		

	end # Kompiler::ELF
	end # Kompiler::Wrappers

end # Kompiler
