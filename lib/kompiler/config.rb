
# 
# Contains config options for how Kompiler interprets different characters.
# 
# Main config options:
#  keyword_chars - list of characters that a keyword can contain
#  label_chars - list of characters that a label name can contain
#  whitespace_chars - list of characters that qualify as whitespace / separators of words
#  string_delimiters - a list of characters that denote the start and end of a string
#

module Kompiler

	module Config

		@keyword_chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + ["_", "."]
		@label_chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + ["_", "."]
		@whitespace_chars = [" ", "\t", "\r"]
		@string_delimiters = ['"', "'"]
		
		# Returns the permittable keyword characters
		def self.keyword_chars
			@keyword_chars
		end
		
		# Returns the permittable label characters
		def self.label_chars
			@label_chars
		end

		def self.whitespace_chars
			@whitespace_chars
		end
		
		def self.string_delimiters
			@string_delimiters
		end
	end
	
end
