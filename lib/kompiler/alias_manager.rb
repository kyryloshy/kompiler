
module Kompiler

module AliasManager

	@aliases = []

	def self.aliases
		@aliases
	end

	def self.default_alias_file_path()
		ENV["KOMPILER_ALIASES_FILE_PATH"] || Gem.find_files("kompiler/config/aliases")[0]
	end

	# Load aliases from the config file in Kompiler
	def self.load_aliases()
		file_path = AliasManager.default_alias_file_path()
		AliasManager.import_aliases_file(file_path)
	end

	# Save aliases to the config file in Kompiler
	def self.save_aliases()
		file_path = AliasManager.default_alias_file_path()
		AliasManager.export_aliases_file(file_path)
	end

	def self.reset_aliases()
		@aliases = []
		nil
	end

	# Apply aliases to the instruction set
	def self.apply_aliases()

		@aliases.each do |alias_entry|

			instr_index = alias_entry[:index] - 1
			instr_keyword = alias_entry[:keyword]

			instruction = Kompiler::Architecture.instructions[instr_index]

			# Something is not right in the alias config, so just skip
			next if instruction[:keyword] != instr_keyword

			instruction[:aliases] = alias_entry[:aliases]

		end

		return true
	end

	# Import aliases from a string
	def self.import_aliases(aliases_content)
		lines = Kompiler::Parsers.get_code_lines(aliases_content)

		line_words = []

		@aliases = []

		lines.each_with_index do |line, line_i|

			words = []

			curr_i = 0
			max_i = line.bytesize

			while curr_i < max_i

				while curr_i < max_i && Kompiler::Config.whitespace_chars.include?(line[curr_i])
					curr_i += 1
				end

				word = ""

				while curr_i < max_i && !Kompiler::Config.whitespace_chars.include?(line[curr_i])
					word << line[curr_i]
					curr_i += 1
				end

				words << word
			end

			instr_index = words[0].to_i
			instr_keyword = words[1]
			instr_aliases = words[2..]

			@aliases << {index: instr_index, keyword: instr_keyword, aliases: instr_aliases}

		end

		@aliases.size
	end

	# Import aliases from a file
	def self.import_aliases_file(filename)
		content = File.binread(filename)
		AliasManager.import_aliases(content)
	end

	# Export aliases to a string
	def self.export_aliases()
		separator = Kompiler::Config.whitespace_chars[0]

		output = ""

		@aliases.each do |instr_alias|
			line = ([instr_alias[:index], instr_alias[:keyword]] + instr_alias[:aliases]).join(separator)

			output << line
			output << "\n"
		end

		output
	end

	# Export aliases to a file
	def self.export_aliases_file(filename)
		content = AliasManager.export_aliases()
		File.binwrite filename, content
	end

	# Add alias
	def self.add_alias(index, keyword, *aliases)
		alias_entry, entry_index = @aliases.each_with_index.filter{|entry, idx| entry[:index] == index && entry[:keyword] == keyword }[0]

		if alias_entry == nil
			alias_entry = {index: index, keyword: keyword, aliases: []}
			entry_index = @aliases.size
		end

		alias_entry[:aliases] += aliases

		@aliases[entry_index] = alias_entry

		return true
	end

	# Remove alias
	def self.remove_alias(index, keyword, *aliases)
		alias_entry, entry_index = @aliases.each_with_index.filter{|entry, idx| entry[:index] == index && entry[:keyword] == keyword }[0]

		if alias_entry == nil
			return false
		end
		
		alias_entry[:aliases] -= aliases

		if alias_entry[:aliases].size == 0
			@aliases.delete_at entry_index
		else
			@aliases[entry_index] = alias_entry
		end

		return true
	end

end # Kompiler::AliasManager

end # Kompiler
