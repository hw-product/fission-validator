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
          repository = Fission::Data::Repository.find_by_url(git_uri)
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
