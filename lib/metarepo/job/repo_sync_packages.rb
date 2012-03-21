require 'metarepo'
Metarepo.connect_db unless Sequel::Model.db
require 'metarepo/upstream'
require 'metarepo/package'
require 'metarepo/repo'
require 'resque-meta'

class Metarepo
  class Job
    class RepoSyncPackages
      extend Resque::Plugins::Meta

      @queue = :default

      def self.perform(meta_id, repo_name, sync_type, sync_id)
        Metarepo::Log.info("Syncronizing repo #{repo_name} to #{sync_type} #{sync_id}")
        repo = Metarepo::Repo[:name => repo_name]
        case sync_type
        when "upstream"
          repo.sync_to_upstream(sync_id)
        when "repo"
          repo.sync_to_repo(sync_id)
        end
        repo.update_index
      end
    end
  end
end

