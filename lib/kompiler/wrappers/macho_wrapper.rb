require 'kompiler/wrappers/packed_bytes'


module Kompiler

module Wrappers


module MachO

	MH_MAGIC_32 = 0xfeedface
	MH_MAGIC_64 = 0xfeedfacf


	def self.wrap_obj code, symbols, arch_type: 64, cputype: 0, cpusubtype: 0

		segments = [
			{
				name: "__TEXT",
				vaddr: 0,
				vsize: code.bytesize,
				maxprot: 7,
				initprot: 7,
				flags: 0,

				sections: [
					{
						name: "__text",
						vaddr: 0,
						vsize: 0,
						align: 1,
						flags: 0,
						content: code,
					},
				]
			}
		]


		output = MachO.build(segments: segments, symbols: symbols, arch_type: arch_type, cputype: cputype, cpusubtype: cpusubtype, filetype: 1, align_section_contents: false)

		return output

	end


	



	
	def self.build_macho_header arch_type: 64, cputype: 0, cpusubtype: 0, filetype: 0, ncmds: 0, sizeofcmds: 0, flags: 0

		macho_header = PackedBytes.new

		case arch_type
		when 64
			macho_header.uint32 MH_MAGIC_64
		when 32
			macho_header.uint32 MH_MAGIC_32
		end

		macho_header.uint32 cputype
		macho_header.uint32 cpusubtype

		macho_header.uint32 filetype

		macho_header.uint32 ncmds

		macho_header.uint32 sizeofcmds
		
		macho_header.uint32 flags

		if arch_type == 64
			# Reserved field in 64-bit
			macho_header.uint32 0
		end

		return macho_header
	end


	# Build a Mach-O file from the input segments, symbols and other pre-built load commands
	# 
	# Arguments:
	#  segments - list of segments to include in the file (structure below)
	#  symbols - list of symbols to be included inside a single symtab (structure below)
	#  prebuilt_lcs - a list of other already built load commands (strings) to be included in the file
	#  arch_type - architecture type, either 32- or 64-bit (default is 64)
	#  cputype - Mach-O header cputype field
	#  cpusubtype - Mach-O header cpusubtype field
	#  filetype - Mach-O file type
	#  align_section_contents - specifies whether to align the contents of each section to its alignment boundary (default is false)
	#
	# Segment structure:
	#  name - the segment's name
	#  vaddr - virtual load address of the segment
	#  vsize - virtual size in memory of the segment
	#  maxprot - Mach-O segment maxprot field
	#  initprot - Mach-O segment initprot field
	#  flags - Mach-O segment flags field
	#  sections - a list of segment's section (structure below)
	#
	# Segment section structure:
	#  name - the section's name
	#  vaddr - virtual load address of section
	#  vsize - virtual size in memory of the section
	#  align - section's byte alignment
	#  flags - section's flags
	#  content - section's content
	#
	# Symbol structure:
	#  name - symbol's name
	#  value - symbol's value
	#  type - symbol's type field value
	#  sect - symbol's sect field value
	#  desc - symbol's desc field value
	# 
	def self.build segments: [], symbols: [], prebuilt_lcs: [], arch_type: 64, cputype: 0, cpusubtype: 0, filetype: 0, align_section_contents: false

		file_content = PackedBytes.new

		case arch_type
		when 32
			flexval_size = 4
		when 64
			flexval_size = 8
		end

		segment_entry_size = 4 * 2 + 16 + flexval_size * 4 + 4 * 2 + 4 * 2

		section_entry_size = 16 + 16 + flexval_size * 2 + 7 * 4
		
		if arch_type == 64
			section_entry_size += 4 # one more reserved field for 64-bit
		end

		symtab_entry_size = 4 * 6


		n_sections = 1

		prebuilt_lcs_size = prebuilt_lcs.map(&:bytesize).sum
		
		cmds_size = segment_entry_size + section_entry_size * n_sections + symtab_entry_size + prebuilt_lcs_size
		

		n_cmds = segments.size + 1 + prebuilt_lcs.size # One segment (with possibly multiple sections), one symtab
		
		macho_header = build_macho_header(
			arch_type: 64,
			cputype: cputype,
			cpusubtype: cpusubtype,
			filetype: filetype,
			ncmds: n_cmds,
			sizeofcmds: cmds_size,
			flags: 0
		)
		

		file_content.add macho_header



		# Calculate where all of the content can be placed
		contents_offset = cmds_size + file_content.result.bytesize
		

		contents = ""
		


		segments.each do |segment|

			raise "Segment name is larger than 16 characters" if segment[:name].bytesize > 16

			start_size = contents.bytesize

			segment[:sections].each_with_index do |section, section_i|

				raise "Section name \"#{section[:name]}\" is larger than 16 characters" if section[:name].bytesize > 16

				section[:align] ||= 1

				raise "Section alignment value cannot be 0" if section[:align] == 0

				sec_offset = contents_offset + contents.bytesize

				pad_amount = 0
				if (sec_offset % section[:align] != 0) && align_sections
					pad_amount = section[:align] - (sec_offset % section[:align])
				end

				sec_offset += pad_amount
				contents << "\0" * pad_amount

				section[:file_offset] = sec_offset

				if section_i == 0
					segment[:file_offset] = sec_offset
					start_size = contents.bytesize
				end

				contents << section[:content]

				section[:vaddr] ||= 0
				section[:vsize] ||= section[:content].bytesize
			end

			end_size = contents.bytesize

			segment[:file_offset] ||= 0
			segment[:filesize] = end_size - start_size

			segment[:vaddr] ||= 0
			segment[:vsize] ||= segment[:filesize]
			
			segment[:flags] ||= 0

			segment[:maxprot] ||= 0
			segment[:initprot] ||= 0
		end


		

		symtab_contents = PackedBytes.new
		
		sym_strtab_contents = "\0"

		symbols.each do |symbol|
			if symbol.keys.include? :name
				symbol[:name_offset] = sym_strtab_contents.bytesize
				sym_strtab_contents << symbol[:name] + "\0"
			else
				symbol[:name_offset] = 0
			end

			symtab_contents.uint32 symbol[:name_offset]
			symtab_contents.uint8 symbol[:type]
			symtab_contents.uint8 symbol[:sect]
			symtab_contents.uint16 symbol[:desc]
			symtab_contents.bytes symbol[:value], flexval_size
		end


		symtab_offset = contents.bytesize + contents_offset
		symtab_align = 8

		if symtab_offset % symtab_align != 0
			pad = (symtab_align - (symtab_offset % symtab_align))
			contents << "\0" * pad
			symtab_offset += pad
		end

		contents << symtab_contents.result

		sym_strtab_offset = contents.bytesize + contents_offset
		
		contents << sym_strtab_contents



		load_commands = PackedBytes.new


		segments.each do |segment|

			case arch_type
			when 64
				load_commands.uint32 0x19 # LC_SEGMENT_64
			when 32
				load_commands.uint32 0x1 # LC_SEGMENT
			end

			load_commands.uint32 segment_entry_size + section_entry_size * segment[:sections].size

			load_commands.bytes segment[:name] + "\0" * (16 - segment[:name].bytesize)

			load_commands.bytes segment[:vaddr], flexval_size
			load_commands.bytes segment[:vsize], flexval_size

			load_commands.bytes segment[:file_offset], flexval_size
			load_commands.bytes segment[:filesize], flexval_size

			load_commands.uint32 segment[:maxprot]
			load_commands.uint32 segment[:initprot]

			load_commands.uint32 segment[:sections].size

			load_commands.uint32 segment[:flags]



			segment[:sections].each do |section|

				load_commands.bytes section[:name] + "\0" * (16 - section[:name].bytesize)
				load_commands.bytes segment[:name] + "\0" * (16 - segment[:name].bytesize)

				load_commands.bytes section[:vaddr], flexval_size
				load_commands.bytes section[:vsize], flexval_size

				load_commands.uint32 section[:file_offset]
				load_commands.uint32 section[:align]

				load_commands.uint32 0 # reloff
				load_commands.uint32 0 # nreloc

				load_commands.uint32 section[:flags]

				load_commands.uint32 0 # reserved 1
				load_commands.uint32 0 # reserved 2

				if arch_type == 64
					load_commands.uint32 0 # reserved 3 (only in 64-bit)
				end
				
			end
		end
		


		# Symtab load command

		load_commands.uint32 0x2 # LC_SYMTAB
		load_commands.uint32 symtab_entry_size

		load_commands.uint32 symtab_offset
		load_commands.uint32 symbols.size

		load_commands.uint32 sym_strtab_offset
		load_commands.uint32 sym_strtab_contents.bytesize


		load_commands.add prebuilt_lcs


		file_content.add load_commands


		file_content.add contents
		

		return file_content.result
		
	end


	# Converts a hash of label name-address pairs into section symbols suitable for the MachO.build method
	#
	# Arguments:
	#  labels - the hash of labels
	#  section_index - index of the section the symbols belong to (default is 1)
	#  external - specifies if the label is external or not (default is false)
	#  private_external - specifies if the label is private external or not (default is false)
	#  debug_entry - specifies if the label is a debug entry or not (default is false)
	def self.labels_to_symbols labels, 
		out = []
		labels.each do |name, value|
			out << create_symbol(name: name, value: value, type: :sect, external: false, section_number: 1)
		end
		return out
	end


	# Creates a symbol from input information suitable for the MachO.build method
	#
	# Arguments:
	#  name - the symbol's name
	#  value - the symbol's value
	#  type - the symbol's type: :undef, :abs, :sect, :prebound, :indirect (default is :sect)
	#  private_external - specifies whether the symbol is private external (default is false)
	#  external - specifies whether the symbol is external (default is false)
	#  debug_entry - specifies whether the symbol is a debugging entry (default is false)
	#  options - options depending on the symbol's type
	#
	# Type == :sect options:
	#  section_number - section number the symbol is defined in
	#  
	def self.create_symbol name: nil, value: nil, type: :sect, private_external: false, external: false, debug_entry: false, **options

		raise "No name provided for the symbol" if name == nil
		raise "No value provided for the symbol" if value == nil

		symbol = {name: name, value: value}

		type_encodings = {undef: 0x0, abs: 0x2, sect: 0xe, prebound: 0xc, indirect: 0xa}
		encoded_type = type_encodings[type]

		raise "Unknown symbol type \"#{type}\" - must be :undef, :abs, :sect, :prebound, or :indirect." if encoded_type == nil
		

		pext_bit = 0x0
		if private_external == true
			pext_bit = 0x10
		end

		ext_bit = 0x0
		if external == true
			ext_bit = 0x1
		end

		debug_entry_bit = 0x0
		if debug_entry == true
			debug_entry_bit = 0xe
		end

		type_field = encoded_type | pext_bit | ext_bit | debug_entry_bit

		symbol[:type] = type_field


		case type
		when :undef
			symbol[:sect] = 0
		when :abs
			symbol[:sect] = 0
		when :sect
			section_number = options[:section_number] || 0
			raise "Section number too high - maximum is 255." if section_number > 255
			symbol[:sect] = section_number
		when :prebound
			symbol[:sect] = 0
		when :indirect
			symbol[:sect] = 0
		end

		symbol[:desc] = 0

		return symbol
	end



end # Kompiler::Wrappers::MachO

end # Kompiler::Wrappers

end # Kompiler


