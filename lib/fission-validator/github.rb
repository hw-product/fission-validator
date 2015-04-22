require 'fission-validator'

module Fission
  module Validator
    # Github account validator
    class Github < Fission::Callback

      # Load data store bits
      def setup(*_)
        require 'fission-data/init'
        if(key = app_config.get(:stripe, :secret_key))
          begin
            debug 'Attempting to load stripe api library'
            require 'stripe'
            info 'Stripe API library loading was successful'
            Stripe.api_key = key
          rescue LoadError => e
            debug "Failed to load stripe api library: #{e.class} - #{e}"
          end
        end
      end

      # Determine validity of message
      #
      # @param message [Carnivore::Message]
      # @return [Truthy, Falsey]
      def valid?(message)
        super do |payload|
          payload.get(:data, :validator, :github, :repository) &&
            payload.get(:data, :account).nil?
        end
      end

      # Validate account for payload
      #
      # @param message [Carnivore::Message]
      def execute(message)
        failure_wrap(message) do |payload|
          repository = Fission::Data::Models::Repository.find_by_name(
            payload.get(:data, :validator, :github, :repository)
          )
          if(repository)
            account = repository.account
            if(account.account_configs && !account.account_configs.empty?)
              account_config = Smash.new.tap do |a_config|
                account.account_configs.each do |ac|
                  a_config.deep_merge!(
                    Smash.new(
                      ac.service.name => ac.data
                    )
                  )
                end
              end
              account_config = Fission::Utils::Cipher.encrypt(
                MultiJson.dump(account_config),
                :iv => payload[:message_id],
                :key => app_config.fetch(:grouping, DEFAULT_SECRET)
              )
            end
            account_info = Smash.new(
              :id => account.id,
              :name => account.name
            )
            account_info[:config] = account_config if account_config
            info "Message validated with account #{account} (#{message})"
            payload.set(:data, :account, account_info)
            job_completed(:validator, payload, message)
          else
            error "Failed to validate message. Repository is not registered! (#{message})"
            failed(payload, message, 'Failed to validate message')
          end
        end
      end

    end
  end
end

Fission.register(:validator, :github, Fission::Validator::Github)
