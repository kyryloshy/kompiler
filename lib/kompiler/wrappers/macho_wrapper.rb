require 'kompiler/wrappers/packed_bytes'
require 'securerandom'
require 'digest'


module Kompiler

module Wrappers


module MachO

	MH_MAGIC_32 = 0xfeedface
	MH_MAGIC_64 = 0xfeedfacf

	LC_REQ_DYLD = 0x80000000


	# Encodes an unsigned integer into ULEB128 byte sequence
	def self.encode_uleb value

		result_bytes = ""
		
		loop do
			value_bits = value & 0x7f # 7 lower bits
			value >>= 7 # shift value by 7 bits
			continue_bit = (value == 0) ? 0 : 1 # "More bytes to come" bit
			final_byte = value_bits | (continue_bit << 7)
			result_bytes << final_byte.chr
			
			break if value == 0 # If nothing else to encode, exit the loop
		end

		return result_bytes
		
	end



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
						align: 4,
						flags: 0x80000400, # section contains some machine instructions
						content: code,
					},
				]
			}
		]



		output = MachO.build(segments: segments, symbols: symbols, prebuilt_lcs: prebuilt_lcs, arch_type: arch_type, cputype: cputype, cpusubtype: cpusubtype, filetype: 1, align_section_contents: true)

		return output

	end


	def self.wrap_exec_static code, symbols, arch_type: 64, cputype: 0, cpusubtype: 0, thread_state: nil, virtual_entry_address: 0x80000, codesign: false

		raise "Thread state must be provided for building a static Mach-O executable" if thread_state == nil

		segments = [
			{
				name: "__PAGEZERO",
				vaddr: 0,
				vsize: virtual_entry_address - 0x1000,
				maxprot: 0,
				initprot: 0,
				flags: 0,
				file_offset: 0,
				filesize: 0,
				sections: []
			},
			{
				name: "__TEXT",
				vaddr: virtual_entry_address - 0x1000,
				maxprot: 7,
				initprot: 7,
				flags: 0,
				file_offset: 0,
				sections: [
					{
						name: "__text",
						vaddr: virtual_entry_address,
						align: 0x1000,
						flags: 0x80000400, # section contains some machine instructions
						content: code,
					}
				]
			}
		]

		if codesign
			segments << {
				name: "__LINKEDIT",
				vaddr: 0x200000000,
				vsize: 0,
				maxprot: 1,
				initprot: 1,
				flags: 0,
				sections: []
			}
		end
		

		uuid_lc = PackedBytes.new
		uuid_lc.uint32 0x1b
		uuid_lc.uint32 24
		uuid_lc.bytes Random.urandom(16) # UUID


		unix_thread_lc = PackedBytes.new
		unix_thread_lc.uint32 0x5 # LC_UNIX_THREAD
		unix_thread_lc.uint32 thread_state.bytesize + 8 # cmdsize
		unix_thread_lc.add thread_state

		
		
		prebuilt_lcs = [
			{
				bytes: uuid_lc.result,
			},
			{
				bytes: unix_thread_lc.result,
			},
		]

		flags = 1

		out = MachO.build segments: segments, symbols: symbols, prebuilt_lcs: prebuilt_lcs, codesign: codesign, arch_type: arch_type, cputype: cputype, cpusubtype: cpusubtype, filetype: 2, flags: flags, align_section_contents: true

		return out
	end







	# Wrap executable with dynamic linker
	# Wraps a binary program in Mach-O format using dynamic link commands (especially used on ARM MacOS)
	#
	def self.wrap_exec_dylink code, symbols, arch_type: 64, cputype: 0, cpusubtype: 0, virtual_entry_address: 0x80000, codesign: false

		pagezero_size = 0x100000000

		text_segment_vaddr = pagezero_size

		text_section_vaddr = text_segment_vaddr + 0x1000

		virtual_entry_address = text_section_vaddr

		linkedit_vaddr = pagezero_size * 3



		n_local_sym = symbols.size

		symbols.map! do
			_1[:value] += text_section_vaddr
			_1
		end


		linkedit = PackedBytes.new


		symtab, sym_strtab = MachO.build_symtab(symbols, arch_type: arch_type).values
				
		symtab_offset = linkedit.result.bytesize
		linkedit.add symtab
		sym_strtab_offset = linkedit.result.bytesize
		linkedit.add sym_strtab


		segments = [
			{
				name: "__PAGEZERO",
				file_offset: 0,
				filesize: 0,
				vaddr: 0,
				vsize: pagezero_size,
				flags: 0,
				maxprot: 0,
				initprot: 0,
				sections: [],
			},
			{
				name: "__TEXT",
				vaddr: text_segment_vaddr,
				# vsize: 0x4000,
				maxprot: 7,
				initprot: 7,
				flags: 0,
				file_offset: 0,
				# filesize: 8192,

				sections: [
					{
						name: "__text",
						vaddr: text_section_vaddr,
						align: 0x1000,
						flags: 0x80000400, # section contains some machine instructions
						content: code,
					},
				]
			},
			{
				name: "__LINKEDIT",
				vaddr: linkedit_vaddr,
				maxprot: 1,
				initprot: 1,
				flags: 0,

				content: linkedit.result,
				content_align: 0x4000,
			}
		]

		entry_point_lc = PackedBytes.new
		entry_point_lc.uint32 0x80000028 # LC_MAIN
		entry_point_lc.uint32 24 # cmdsize

		entry_point_lc.uint64 0x80000 # file offset address
		entry_point_lc.uint64 0 # stack size



		uuid_lc = PackedBytes.new
		uuid_lc.uint32 0x1b
		uuid_lc.uint32 24
		uuid_lc.bytes Random.urandom(16) # UUID

				

		load_dylinker_lc = PackedBytes.new

		load_dylinker_lc.uint32 0xe
		load_dylinker_lc.uint32 32
		load_dylinker_lc.bytes "\f\x00\x00\x00/usr/lib/dyld\x00\x00\x00\x00\x00\x00\x00"

		symtab_lc = PackedBytes.new

		symtab_lc.uint32 0x2
		symtab_lc.uint32 24

		symtab_lc.uint32 0
		symtab_lc.uint32 symbols.size

		symtab_lc.uint32 0
		symtab_lc.uint32 sym_strtab.bytesize


		dyld_info_lc = PackedBytes.new

		dyld_info_lc.uint32 0x22
		dyld_info_lc.uint32 12 * 4

		dyld_info_lc.uint32 0 # rebase_off
		dyld_info_lc.uint32 0 # size

		dyld_info_lc.uint32 0 # bind_off
		dyld_info_lc.uint32 0 # size

		dyld_info_lc.uint32 0 # weak_bind_off
		dyld_info_lc.uint32 0 # size

		dyld_info_lc.uint32 0 # lazy_bind_off
		dyld_info_lc.uint32 0 # size

		dyld_info_lc.uint32 0 # export_off
		dyld_info_lc.uint32 0 # size



		code_signature_lc = PackedBytes.new

		code_signature_lc.uint32 0x1d # LC_CODE_SIGNATURE
		code_signature_lc.uint32 16 # cmdsize

		code_signature_lc.uint32 0 # offset
		code_signature_lc.uint32 0 # size



		prebuilt_lcs = [
			{
				bytes: symtab_lc.result,
				relocations: [
					{
						content_index: 1,
						bytefield_offset: 8,
						bytefield_size: 4,
						addend: symtab_offset,
					},
					{
						content_index: 1,
						bytefield_offset: 16,
						bytefield_size: 4,
						addend: sym_strtab_offset,
					}
				]
			},
			{
				bytes: load_dylinker_lc.result,
			},
			{
				bytes: uuid_lc.result
			},
			{
				bytes: dyld_info_lc.result
			},
			{
				bytes: entry_point_lc.result,
				relocations: [
					{
						content_index: 0,
						bytefield_offset: 8,
						bytefield_size: 8
					}
				]
			},
		]


		mh_flags = 0x200000 | 0x4 | 0x1 # MH_PIE | MH_DYLDLINK | MH_NOUNDEFS


		output = MachO.build(segments: segments, symbols: nil, prebuilt_lcs: prebuilt_lcs, arch_type: arch_type, codesign: codesign, cputype: cputype, cpusubtype: cpusubtype, filetype: 2, align_section_contents: true, flags: mh_flags)

		return output
		
	end


	def self.build_thread_state_x86_32(r: [0] * 7, esp: 0, ss: 0, eflags: 0, eip: 0, cs: 0, ds: 0, es: 0, fs: 0, gs: 0)
		raise "r must be an array of 7 elements" if r.size != 7
		
		thread_state = PackedBytes.new

		thread_state.uint32 1 # flavor = x86_THREAD_STATE_32
		thread_state.uint32 16 # count = 16 4-byte fields

		r.each do |r_val|
			thread_state.uint32 r_val
		end

		thread_state.uint32 esp
		thread_state.uint32 ss
		thread_state.uint32 eflags
		thread_state.uint32 eip
		thread_state.uint32 cs
		thread_state.uint32 ds
		thread_state.uint32 es
		thread_state.uint32 fs
		thread_state.uint32 gs

		return thread_state.result
	end


	def self.build_thread_state_x86_64(r: [0] * 16, rip: 0, rflags: 0, cs: 0, fs: 0, gs: 0)

		raise "r must be an array of 16 elements" if r.size != 16
	
		thread_state = PackedBytes.new

		thread_state.uint32 4 # flavor = x86_THREAD_STATE_64
		thread_state.uint32 42 # count = 21 8-byte fields / sizeof(int) (4 bytes)


		r.each do |r_val|
			thread_state.uint64 r_val
		end

		thread_state.uint64 rip

		thread_state.uint64 rflags
		thread_state.uint64 cs
		thread_state.uint64 fs
		thread_state.uint64 gs
		

		return thread_state.result
	end



	def self.build_thread_state_arm64(x: [0] * 29, fp: 0, lr: 0, sp: 0, pc: 0, cpsr: 0)

		thread_state = PackedBytes.new

		thread_state.uint32 6 # flavor = ARM_THREAD_STATE64
		thread_state.uint32 33 * 2 + 2 # count = 33 8-byte fields + 2 4-byte fields / sizeof(int) (4 bytes)

		raise "x must be an array of 29 values." if x.size != 29

		x.each do |x_val|
			thread_state.uint64 x_val
		end

		thread_state.uint64 fp
		thread_state.uint64 lr
		thread_state.uint64 sp
		thread_state.uint64 pc

		thread_state.uint32 cpsr
		
		thread_state.uint32 0 # pad

		return thread_state.result
	end



	def self.build_thread_state_arm32(r: [0] * 13, lr: 0, sp: 0, pc: 0, cpsr: 0)

		thread_state = PackedBytes.new

		thread_state.uint32 1 # flavor = ARM_THREAD_STATE
		thread_state.uint32 17  # count = 17 4-byte fields / sizeof(int) (4 bytes)

		raise "r must be an array of 13 values." if r.size != 13

		r.each do |r_val|
			thread_state.uint32 r_val
		end

		thread_state.uint32 lr
		thread_state.uint32 sp
		thread_state.uint32 pc

		thread_state.uint32 cpsr

		return thread_state.result
	end


	
	def self.build_thread_state arch: nil, entry_address: 0, stack_pointer: 0
		raise "arch must be specified" if arch == nil

		case arch
		when "arm64"
			return MachO.build_thread_state_arm64(pc: entry_address, sp: stack_pointer)
		when "arm32"
			return MachO.build_thread_state_arm32(pc: entry_address, sp: stack_pointer)
		when "x86-64"
			r = [0] * 16
			r[7] = stack_pointer
			return MachO.build_thread_state_x86_64(rip: entry_address, r: r)
		when "x86-32"
			r = [0] * 7
			return MachO.build_thread_state_x86_32(r: r, eip: entry_address)
		else
			raise "Unkown architecture"
		end
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
	#  codesign - specifies whether to create a code signature. If yes, a __LINKEDIT segment must be present. The code signature will be a code_directory struct with hashes of everything before it. A CODE_SIGNATURE load command will be added automatically.
	#  cputype - Mach-O header cputype field
	#  cpusubtype - Mach-O header cpusubtype field
	#  flags - Mach-O header flags field
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
	# Prebuilt load command structure:
	#  bytes - the load command bytes
	#  contents - contents related to the load command
	#  contents_align - alignment boundary in the file for the contents
	#  relocations - a list of relocations to replace some load command's bytes based on the content's file offset
	#
	# Prebuilt load command relocation structure:
	#  content_index - index of the contents related to the relocation (contents of segments and symtab will appear last)
	#  bytefield_offset - offset of the to-be-replaced bytes in the load command
	#  bytefield_size - size of the bytefield to be replaced
	#  addend - value to add to the contents' file offset to replace the specified bytefield in the load command with
	#  Relocation logic:
	#   load_command[:bytes][lc_offset...(lc_offset + lc_size)] = int_to_bytes(contents[content_i][:file_offset] + addend, lc_size)
	#
	def self.build segments: [], symbols: [], prebuilt_lcs: [], arch_type: 64, cputype: 0, cpusubtype: 0, filetype: 0, align_section_contents: false, flags: 0, codesign: false


		n_symtabs = 1
		n_symtabs = 0 if symbols == nil

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

		code_signature_lc_size = 4 * 4

		n_code_signature_lcs = codesign ? 1 : 0

		n_sections = segments.map{(_1[:sections] || []).size}.sum

		prebuilt_lcs_size = prebuilt_lcs.map{_1[:bytes].bytesize}.sum
		
		cmds_size = segment_entry_size * segments.size + section_entry_size * n_sections + symtab_entry_size * n_symtabs + code_signature_lc_size * n_code_signature_lcs + prebuilt_lcs_size
		

		n_cmds = segments.size + n_symtabs + n_code_signature_lcs + prebuilt_lcs.size # One segment (with possibly multiple sections), one symtab
		
		macho_header = build_macho_header(
			arch_type: arch_type,
			cputype: cputype,
			cpusubtype: cpusubtype,
			filetype: filetype,
			ncmds: n_cmds,
			sizeofcmds: cmds_size,
			flags: flags
		)
		

		file_content.add macho_header



		# Calculate where all of the content can be placed
		contents_offset = cmds_size + file_content.result.bytesize
		

		contents = ""


		prebuilt_lc_content_offsets = []

		prebuilt_lcs.each do |lc|
			if lc.keys.include? :contents

				align = lc[:contents_align] || 1

				file_offset = contents.bytesize + contents_offset

				if file_offset % align != 0
					pad = align - (file_offset % align)
					contents << "\0" * pad
					file_offset += pad
				end

				prebuilt_lc_content_offsets << file_offset
				
				contents << lc[:contents]
			else
				prebuilt_lc_content_offsets << nil
			end
		end
		


		contents_offsets = []

		if codesign
			# Ensure that the __LINKEDIT segment exists, and place it as the last segment to not interfere with other load commands and hash more of the file
			
			linkedit_segments = segments.each_with_index.filter{|seg, idx| seg[:name] == "__LINKEDIT"}
			if linkedit_segments.size == 0
				raise "Segment __LINKEDIT must be present if codesign is true"
			#	segments << {name: "__LINKEDIT", vaddr}
			else
				linkedit_segment, linkedit_segment_idx = linkedit_segments[0]

				# Make __LINKEDIT the last segment
				segments[-1], segments[linkedit_segment_idx] = segments[linkedit_segment_idx], segments[-1]
			end
		end


				


		segments.each do |segment|

			raise "Segment name is larger than 16 characters" if segment[:name].bytesize > 16

			raise "Segment can't contain both the :content and :sections key" if segment.keys.include?(:content) && segment.keys.include?(:sections) && segment[:sections].size > 0

			if segment.keys.include? :content

				segment[:sections] = []

				alignment = segment[:content_align] || 1

				file_offset = contents_offset + contents.bytesize
				if file_offset % alignment != 0
					pad = alignment - (file_offset % alignment)
					contents << "\0" * pad
					file_offset += pad
				end

				contents << segment[:content]

				segment[:file_offset] ||= file_offset
				segment[:filesize] ||= segment[:content].bytesize

				segment[:vaddr] ||= 0
				segment[:vsize] ||= segment[:filesize]

				segment[:flags] ||= 0

				segment[:maxprot] ||= 0
				segment[:initprot] ||= 0

				contents_offsets << segment[:file_offset]

				next
			end


			start_offset = contents.bytesize + contents_offset

			segment[:sections].each_with_index do |section, section_i|

				raise "Section name \"#{section[:name]}\" is larger than 16 characters" if section[:name].bytesize > 16

				section[:align] ||= 1

				raise "Section alignment value cannot be 0" if section[:align] == 0

				sec_offset = contents_offset + contents.bytesize

				pad_amount = 0
				if (sec_offset % section[:align] != 0) && align_section_contents
					pad_amount = section[:align] - (sec_offset % section[:align])
				end

				sec_offset += pad_amount
				contents << "\0" * pad_amount

				section[:file_offset] = sec_offset

				if section_i == 0
					segment[:file_offset] ||= sec_offset
				end

				contents_offsets << section[:file_offset]
				
				contents << section[:content]

				section[:vaddr] ||= 0
				section[:vsize] ||= section[:content].bytesize
			end

			end_offset = contents.bytesize + contents_offset

			segment[:file_offset] ||= start_offset
			segment[:filesize] ||= end_offset - segment[:file_offset]

			segment[:vaddr] ||= 0
			segment[:vsize] ||= segment[:filesize]
			
			segment[:flags] ||= 0

			segment[:maxprot] ||= 0
			segment[:initprot] ||= 0
		end


		if codesign

			# The __LINKEDIT segment is last (logic written previously)
			linkedit_segment = segments.last
			

			code_directory = PackedBytes.new endianess: :be

			code_directory.uint32 0xfade0c02 # Magic

			code_directory_length_offset = code_directory.result.bytesize
			code_directory.uint32 0 # Length (will be replaced)

			code_directory.uint32 0 # Version

			code_directory.uint32 0 # Flags

			code_directory_header_size = 96

			hash_array_offset = code_directory_header_size

			total_hashing_size = linkedit_segment[:file_offset] + linkedit_segment[:filesize]
			
			hashing_pagesize = 0x1000

			n_hashes = (total_hashing_size / hashing_pagesize.to_f).ceil

			hash_size = 32
			hash_type = 2 # SHA256

			hash_array_size = hash_size * n_hashes


			ident_offset = hash_array_offset + hash_array_size


			code_directory.uint32 hash_array_offset # Hash offset

			code_directory.uint32 ident_offset # Identifier string offset

			code_directory.uint32 0 # nSpecialSlots

			code_directory.uint32 n_hashes # nCodeSlots

			code_directory.uint32 total_hashing_size # codeLimit


			code_directory.uint8 hash_size
			code_directory.uint8 hash_type

			code_directory.uint8 0
			hashing_pagesize_enc = Math.log2(hashing_pagesize)
			raise "Code signing pagesize is not a power of two" if hashing_pagesize_enc.to_i != hashing_pagesize_enc
			code_directory.uint8 hashing_pagesize_enc.to_i

			code_directory.uint32 0 # spare2

			code_directory.uint32 0 # scatterOffset (zero for absent)
			code_directory.uint32 0 # teamIDOffset (zero for absent)

			code_directory.uint32 0 # spare3

			code_directory.uint64 total_hashing_size # codeLimit64
			
			code_directory.uint64 0 # offset of executable segment
			code_directory.uint64 0 # limit of executable segment
			code_directory.uint64 0 # exec segment flags

			code_directory.uint32 0 # runtime
			code_directory.uint32 0xFFFF # pre-encrypt hash slots offset

			

			hash_array_placeholder = "\0" * hash_array_size

			
			code_directory.add hash_array_placeholder

			ident_string = "program-#{SecureRandom.uuid.gsub('-', '')}\0"

			code_directory.add ident_string

			
			code_directory_bytes = code_directory.result
			code_directory_bytes[code_directory_length_offset...(code_directory_length_offset + 4)] = [code_directory_bytes.bytesize].pack("L>")

			blobs = [
				{type: 0, content: code_directory.result}
			]

			# Embedded signature blob (superblob with magic = 0xfade0cc0)
			superblob = MachO.build_superblob(magic: 0xfade0cc0, blobs: blobs)


			# Calculate the offset of the hash array that will be replaced later
			
			code_directory_offset = MachO.calc_superblob_offset(blobs, 0)
			superblob_offset = linkedit_segment[:file_offset] + linkedit_segment[:filesize]

			codesign_hash_array_offset = superblob_offset + code_directory_offset + hash_array_offset

			contents << superblob

			# Change the linkedit segment to include the embedded signature blob
			linkedit_segment[:filesize] += superblob.bytesize
			linkedit_segment[:vsize] += superblob.bytesize

			# Add a code signature load command
			code_signature_lc = PackedBytes.new
			code_signature_lc.uint32 0x1d # LC_CODE_SIGNATURE
			code_signature_lc.uint32 4 * 4 # cmdsize

			code_signature_lc.uint32 superblob_offset
			code_signature_lc.uint32 superblob.bytesize


			prebuilt_lcs << {
				bytes: code_signature_lc.result
			}
			
		end



		symtab_offset = nil


		if symbols != nil

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
			symtab_align = 360

			if symtab_offset % symtab_align != 0
				pad = (symtab_align - (symtab_offset % symtab_align))
				contents << "\0" * pad
				symtab_offset += pad
			end

			# contents_offsets << symtab_offset
			
			contents << symtab_contents.result

			sym_strtab_offset = contents.bytesize + contents_offset
			
			contents << sym_strtab_contents

		end



		contents_offsets << symtab_offset if symtab_offset != nil

		contents_offsets += prebuilt_lc_content_offsets



		prebuilt_lcs.each do |lc|

			if lc.keys.include? :relocations
				lc[:relocations].each do |reloc|

					addr = contents_offsets[reloc[:content_index]]

					raise "Load command contents at index #{reloc[:content_index]} is empty and doesn't have an offset" if addr == nil

					write_val = addr + (reloc[:addend] || 0)

					bytesize = reloc[:bytefield_size]

					bits = (0...(bytesize * 8)).map{|bit_i| write_val[bit_i] }
					bytes = (0...bytesize).map{|byte_i| bits[(byte_i*8)...(byte_i*8 + 8)] }.map{|byte_bits| byte_bits.each_with_index.map{|bit, bit_i| 2 ** bit_i * bit }.sum }
					str_bytes = bytes.map(&:chr).join

					lc[:bytes][reloc[:bytefield_offset]...(reloc[:bytefield_offset] + bytesize)] = str_bytes
				end
			end

		end


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
				
				align_value = Math.log2 section[:align]
				raise "Section alignment is not a power of 2" if align_value.to_i != align_value

				load_commands.uint32 align_value

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

		if symbols != nil
			load_commands.uint32 0x2 # LC_SYMTAB
			load_commands.uint32 symtab_entry_size

			load_commands.uint32 symtab_offset
			load_commands.uint32 symbols.size

			load_commands.uint32 sym_strtab_offset
			load_commands.uint32 sym_strtab_contents.bytesize
		end
		

		prebuilt_lcs.each do |lc|
			load_commands.bytes lc[:bytes]
		end


		file_content.add load_commands


		file_content.add contents


		if codesign
			# Compute the hashes and replace them instead of the placeholder
			
			out = file_content.result
			
			hash_array_contents = ""

			n_hashes.times do |hash_i|
				start_offset = hash_i * hashing_pagesize
				# Enf offset is either the end of the page or the code_limit field from code_directory
				end_offset = [start_offset + hashing_pagesize, total_hashing_size].min

				hashed = Digest::SHA256.digest out[start_offset...end_offset]

				hash_array_contents << hashed
			end


			hash_array_start = codesign_hash_array_offset
			hash_array_end = hash_array_start + hash_array_contents.bytesize
	
			out[hash_array_start...hash_array_end] = hash_array_contents

			return out
		end


		return file_content.result		
	end



	# Builds a code signature SuperBlob structure
	# 
	# Arguments:
	#  magic - SuperBlob's magic field value (default is 0)
	#  blobs - blobs included in the superblob (structure below)
	#
	# Blob structure:
	#  type - blob's type
	#  content - blob's content
	#
	def self.build_superblob magic: 0, blobs: []

		superblob = PackedBytes.new endianess: :be

		superblob.uint32 0xfade0cc0 # magic

		superblob_length_offset = superblob.result.bytesize
		superblob.uint32 0 # length (will be replaced)

		superblob.uint32 1 # Number of entries


		index_entry_size = 8
		index_entries_size = index_entry_size * blobs.size

		superblob_header_size = 4 * 3

		blobs_offset = superblob_header_size + index_entries_size

		blob_contents = ""

		blobs.each do |blob|
			blob[:offset] = blobs_offset + blob_contents.bytesize
			blob_contents << blob[:content]
		end

		# Index entries
		blobs.each do |blob|
			superblob.uint32 blob[:type]
			superblob.uint32 blob[:offset]				
		end

		# Blob contents write
		blobs.each do |blob|
			superblob.add blob[:content]
		end


		out = superblob.result
		out[superblob_length_offset...(superblob_length_offset + 4)] = [out.bytesize].pack("L>")

		out
	end


	# Calculates the offset of the specified blob from the beginning of the superblob
	def self.calc_superblob_offset blobs, index

		superblob_header_size = 4 * 3

		index_entry_size = 8
		
		index_entries_size = index_entry_size * blobs.size

		total_offset = superblob_header_size + index_entries_size

		blobs[...index].each do |blob|
			total_offset += blob[:content].bytesize
		end

		total_offset
	end




	# Builds a symtab and a strtab based off input symbols
	def self.build_symtab symbols, arch_type: 64

		case arch_type
		when 64
			flexval_size = 8
		when 32
			flexval_size = 4
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


		return {symtab: symtab_contents.result, strtab: sym_strtab_contents}
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
			out << create_symbol(name: name, value: value, type: :sect, external: true, section_number: 1)
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


