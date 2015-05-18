require 'fission-validator'

module Fission
  module Validator
    # Github account validator
    class Github < Fission::Callback

      include Fission::Validator::Commons

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
            account_info = generate_account_information(account, payload)
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
