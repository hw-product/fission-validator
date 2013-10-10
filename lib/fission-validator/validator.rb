require 'fission/utils'
require 'carnivore/callback'

module Fission
  module Validator
    class Github < Carnivore::Callback

      include Fission::Utils::MessageUnpack

      def valid?(message)
        m = unpack(message)
        m[:github]
      end

      def execute(message)
        payload = unpack(message)
        user_info = Celluloid::Actor[:fission_app].user(:github => payload[:github][:repository])
        if(user_info && user_info[:validated])
          payload[:user] = {:id => user_info[:id], :account_id => user_info[:account_id]}
          debug "Validated job for user: #{payload[:user].inspect}"
          Celluloid::Actor["fission_#{payload[:job]}".to_sym].transmit(payload, message)
        else
          error "Invalid authentication received: payload: #{payload.inspect} app response: #{user_info.inspect}"
        end
      end

    end
  end
end

Fission.register(:fission_validator, Fission::Validator::Github)
