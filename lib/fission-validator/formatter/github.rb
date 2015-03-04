require 'fission-router'

module Fission
  module Router
    module Validator

      # Format github sourced payload for validator
      class Github < Fission::Formatter

        # Source of payload
        SOURCE = :github
        # Destination of payload
        DESTINATION = :validator

        # Add validator information to payload
        #
        # @param payload [Smash]
        def format(payload)
          if(payload.get(:data, :github) && payload.get(:data, :validator).nil?)
            payload.set(:data, :validator, :github, :repository, repository_name(payload))
          end
        end

        # Provide repoistory name from github payload data
        #
        # @param payload [Smash]
        # @return [String] full repository name
        def repository_name(payload)
          case payload.get(:data, :github, :event)
          when 'pull_request'
            [payload.get(:data, :github, :pull_request, :head, :repo, :owner, :login),
              payload.get(:data, :github, :pull_request, :head, :repo, :name)].join('/')
          when 'push'
            [payload.get(:data, :github, :repository, :owner, :name),
              payload.get(:data, :github, :repository, :name)].join('/')
          else
            [payload.get(:data, :github, :repository, :owner, :login),
              payload.get(:data, :github, :repository, :name)].join('/')
          end
        end

      end

    end
  end
end
