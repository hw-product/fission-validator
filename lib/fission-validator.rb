require 'fission'
require 'fission-validator/version'
require 'fission-validator/validator'

Dir.glob(File.join(File.dirname(__FILE__), 'fission-validator', 'validations', '*.rb')).each do |path|
  require "fission-validator/#{File.basename(path).sub('.rb', '')}"
end
