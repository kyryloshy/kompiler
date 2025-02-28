# Copyright 2024 Kyrylo Shyshko
# Licensed under the Apache License, Version 2.0. See LICENSE file for details.

module Kompiler

	# Object for managing architecture entries / available architectures
	module ArchManager
		@arch_entries = []
		
		def self.add_arch(arch_name, include_path)
			@arch_entries << {name: arch_name, include_path: include_path}
		end
		
		def self.get_arch(arch_name)
			@arch_entries.filter{|entry| entry[:name] == arch_name}[0]
		end
		
		def self.entries
			@arch_entries
		end
		
		def self.load_all_entries
			Gem.find_files("kompiler/arch_entries/*").each { |file| require file }
		end
	end

end