require 'fission/callback'

module Fission
  module Validator
    class Github < Fission::Callback

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
          repository = Fission::Data::Repository.find_by_matching_url(git_uri)
          unless(repository)
            account_name = retrieve(payload, :data, :github, :repository, :owner, :name)
            account = Account.lookup(account_name, :github, :remote)
            if(account && account.active?)
              if(account.new?)
                warn "Discovered previously existing account not in data store. Adding (#{account.inspect})"
                account.save
              end
              info "Unregistered repository encountered for active account: #{account}. Adding."
              repository = Fission::Data::Repository.new(
                :name => retrieve(payload, :data, :github, :repository, :name),
                :source => :github,
                :url => retrieve(payload, :data, :github, :repository, :url),
                :clone_url => retrieve(payload, :data, :github, :repository, :url).sub('git:', 'https:')
              )
              repository.owner = account
              repository.save
            end
          end
          if(repository)
            debug "Account found for #{message}: #{repository.owner.id}"
            payload[:data][:account] = repository.owner.id
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
