require 'fission/utils'
require 'carnivore/callback'

module Fission
  module Validator
    class Github < Fission::Callback

      include Fission::Utils::MessageUnpack

      def setup
        require 'fission-data/init'
      end

      def valid?(message)
        super do |m|
          retrieve(m, :data, :github) && !retrieve(m, :data, :account)
        end
      end

      def execute(message)
        payload = unpack(message)
        git_uri = retrieve(payload, :data, :github, :repository, :url)
        if(git_uri)
          repository = Fission::Data::Repository.find_by_uri(git_uri)
          if(repository)
            debug "Account found for #{message}: #{repository.account.id}"
            payload[:data][:account] = repository.account.id
            completed(payload, message)
          else
            failed(payload, message, 'Failed to registered repository using given location')
          end
        else
          failed(payload, message, 'No repository location found in payload')
        end
      end

    end
  end
end

Fission.register(:validator, :github, Fission::Validator::Github)
