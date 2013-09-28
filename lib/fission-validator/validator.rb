require 'fission/utils/message_unpack'
require 'carnivore/callback'

module Fission
  module Validator
    class Github < Carnivore::Callback

      include Fission::Utils::MessageUnpack

      def execute(message)
        payload = unpack(message)
        user = Fission::Rest.user(
          :token => payload[:token],
          :secret => payload[:secret]
        )
        if(user)
          debug "Validated job for account #{account}"
          [:token, :secret].each do |key|
            payload.delete(key)
          end
          payload[:user] = user
          Celluloid::Actor[:fission_bus].transmit(
            payload, payload[:job]
          )
        else
          error "Invalid authentication received: #{payload.inspect}"
        end
      end

    end
  end
end
