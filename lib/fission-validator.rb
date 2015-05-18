require 'fission'
require 'fission-validator/version'

module Fission
  module Validator

    autoload :Github, 'fission-validator/github'
    autoload :Commons, 'fission-validator/commons'

  end
end

require 'fission-validator/github'
require 'fission-validator/formatter'
