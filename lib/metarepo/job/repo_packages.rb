require 'metarepo'
Metarepo.connect_db unless Sequel::Model.db
require 'metarepo/upstream'
require 'metarepo/package'
require 'metarepo/repo'
require 'resque-meta'

class Metarepo
  class Job
    class RepoPackages
      extend Resque::Plugins::Meta

      @queue = :default

      def self.perform(meta_id, repo_name, package_list)
        Metarepo::Log.info("Syncronizing repo #{repo_name} to package list")
        repo = Metarepo::Repo[:name => repo_name]
        packages = Metarepo::Package.dataset.where('shasum IN ?', package_list.keys).all
        repo.sync_packages(packages)
        repo.update_index
      end
    end
  end
end


