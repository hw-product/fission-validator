require 'fission/callback'

module Fission
  module Validator
    class Github < Fission::Callback

      def setup
        if(enabled?(:data))
          require 'fission-data/init'
          if(key = Carnivore::Config.get(:fission, :stripe, :secret_key))
            begin
              debug 'Attempting to load stripe api library'
              require 'stripe'
              info 'Stripe API library loading was successful'
              Stripe.api_key = key
            rescue LoadError => e
              debug "Failed to load stripe api library: #{e.class} - #{e}"
            end
          end
        else
          warn "Data library is not available. This will impact functionality of this callback!"
        end
      end

      def valid?(message)
        super do |m|
          retrieve(m, :data, :github) && !retrieve(m, :data, :account)
        end
      end

      def execute(message)
        failure_wrap(message) do |payload|
          format_payload(payload, :repository, :github)
          git_uri = payload.get(:data, :format, :repository, :url)
          if(git_uri)
            repository = Fission::Data::Models::Repository.find_by_matching_url(git_uri)
            if(repository)
              debug "Account found for #{message}: #{repository.account.id}"
              payload[:data][:account] = {
                :id => repository.account.id,
                :name => repository.account.name
              }
              completed(payload, message)
            else
              failed(payload, message, 'Failed to locate registered repository using given location')
            end
          else
            failed(payload, message, 'No repository location found in payload')
          end
        end
      end

    end
  end
end

Fission.register(:validator, :github, Fission::Validator::Github)
