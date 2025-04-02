class PackedBytes
	def initialize bytes = ""
		@bytes = bytes.dup
	end
	
	def uint8 n
		n = [n] if n.is_a? Numeric
		@bytes << n.pack("C*")
	end
	
	def uint16 n
		n = [n] if n.is_a? Numeric
		@bytes << n.pack("S<*")
	end
	
	def uint32 n
		n = [n] if n.is_a? Numeric
		@bytes << n.pack("L<*")
	end
	
	def uint64 n
		n = [n] if n.is_a? Numeric
		@bytes << n.pack("Q<*")
	end
	
	def bytes bytes, n_bytes=nil
		if n_bytes == nil
			if bytes.is_a? PackedBytes
				@bytes += bytes.result
			elsif bytes.is_a? String
				@bytes += bytes
			elsif bytes.is_a? Array
				@bytes += bytes.pack("C*")
			end
		else
			case n_bytes
			when 1
				self.uint8 bytes
			when 2
				self.uint16 bytes
			when 4
				self.uint32 bytes
			when 8
				self.uint64 bytes
			end
		end
	end
	alias_method :add, :bytes

	def align n_bytes, pad_byte="\0"
		if @bytes.size % n_bytes == 0
			return
		else
			@bytes << pad_byte * (n_bytes - (@bytes.size % n_bytes))
		end
	end
	
	def result
		@bytes
	end
	alias_method :get_bytes, :result
	
	def to_file filename
		File.binwrite filename, self.result
	end
	alias_method :write, :to_file
	alias_method :save, :to_file
end
