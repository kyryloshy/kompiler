Gem::Specification.new do |s|
	s.name        = "kompiler"
	s.version     = "0.3.0.pre.4"
	s.summary     = "Kir's compiler for low-level machine code"
	s.description = <<~EOF
	Kompiler is a low-level, modular and extendable compiler for any architecture. By default Kompiler supports ARMv8-a, but other architecture extensions can be downloaded in the future.
	EOF
	s.authors     = ["Kyryl Shyshko"]
	s.email       = "kyryloshy@gmail.com"
	s.files       = ["lib/kompiler.rb", "LICENSE"] + Dir["lib/kompiler/*"] + Dir["lib/kompiler/arch_entries/*"] + Dir["lib/kompiler/architectures/armv8a/*"]
	s.executables << "kompile"
	s.homepage    = "https://github.com/kyryloshy/kompiler"
	s.license     = "Apache-2.0"
	s.required_ruby_version = ">= 3.0.0"
	s.metadata = {
		"source_code_uri" => "https://github.com/kyryloshy/kompiler",
		"bug_tracker_uri" => "https://github.com/kyryloshy/kompiler/issues"
	}
end
