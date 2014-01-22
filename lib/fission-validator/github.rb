require 'fission/callback'

module Fission
  module Validator
    class Github < Fission::Callback

      def setup
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
          repository = Fission::Data::Repository.find_by_matching_url(git_uri)
          unless(repository)
            account_name = retrieve(payload, :data, :github, :repository, :owner, :name)
            account = Fission::Data::Account.lookup(account_name, :github, :remote)
            if(account && account.active?)
              if(account.new?)
                warn "Discovered previously existing account not in data store. Adding (#{account.inspect})"
                account.save
              end
              info "Unregistered repository encountered for active account: #{account}. Adding."
              repository = Fission::Data::Repository.new(
                :name => [
                  retrieve(payload, :data, :github, :repository, :owner, :name),
                  retrieve(payload, :data, :github, :repository, :name)
                ].join('/'),
                :source => :github,
                :private => retrieve(payload, :data, :github, :repository, :private),
                :url => retrieve(payload, :data, :github, :repository, :url),
                :clone_url => retrieve(payload, :data, :github, :repository, :url).sub('git:', 'https:')
              )
              repository.owner = account
              repository.save
            end
          end
          if(repository)
            debug "Account found for #{message}: #{repository.owner.id}"
            payload[:data][:account] = {
              :id => repository.owner.id,
              :name => repository.owner.name
            }
            debug 'Saving job into data store'
            job = Fission::Data::Job.new(
              :message_id => payload[:message_id],
              :payload => payload
            )
            job.account = repository.owner
            job.save
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

Fission.register(:validator, :github, Fission::Validator::Github)
