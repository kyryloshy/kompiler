require 'yaml'

REGISTERS = YAML.load_file File.expand_path("registers.yaml", File.dirname(__FILE__))
