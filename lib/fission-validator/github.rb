require 'fission/utils'
require 'carnivore/callback'

module Fission
  module Validator
    class Github < Fission::Callback

      include Fission::Utils::MessageUnpack

      def valid?(message)
        super do |m|
          m[:data] && m[:data][:github] && !m[:data][:user]
        end
      end

      def execute(message)
        payload = unpack(message)
        payload[:data][:user] = "I'm a big phony"
        info "User has been validated (stub)"
        completed(payload, message)
=begin
# NOTE: This is not a real implementation. just some jotted thoughts
        user_info = Celluloid::Actor[:fission_app].user(:github => payload[:github][:repository])
        if(user_info && user_info[:validated])
          payload[:user] = {:id => user_info[:id], :account_id => user_info[:account_id]}
          debug "Validated job for user: #{payload[:user].inspect}"
          forward(payload, message)
        else
          error "Invalid authentication received: payload: #{payload.inspect} app response: #{user_info.inspect}"
        end
=end
      end

    end
  end
end

Fission.register(:validator, :github, Fission::Validator::Github)
