Gem::Specification.new do |s|
	s.name        = "kompiler"
	s.version     = "0.0.0"
	s.summary     = "Kir's compiler for low-level ARM machine code"
	s.description = <<~EOF
	SymCalc adds symbolic mathematics and calculus to your code. Create, evaluate and differentiate mathematical functions with a single method call.
	EOF
	s.authors     = ["Kyryl Shyshko"]
	s.email       = "kyryloshy@gmail.com"
	s.files       = ["lib/kompiler.rb"] + Dir["lib/kompiler/*"] + Dir["lib/kompiler/arch/armv8a/*"]
	s.executables << "kompile"
	s.homepage    = "https://github.com/kyryloshy/kompiler"
	s.license     = "Apache-2.0"
	s.required_ruby_version = ">= 3.0.0"
	s.metadata = {
		"source_code_uri" => "https://github.com/kyryloshy/kompiler",
		"bug_tracker_uri" => "https://github.com/kyryloshy/kompiler/issues"
	}
end
