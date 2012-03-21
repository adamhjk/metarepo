require 'metarepo'
Metarepo.connect_db unless Sequel::Model.db
require 'metarepo/upstream'
require 'metarepo/package'
require 'metarepo/repo'
require 'metarepo/pool'
require 'resque-meta'

class Metarepo
  class Job
    class UpstreamSyncPackages
      extend Resque::Plugins::Meta

      @queue = :default

      def self.perform(meta_id, id)
        Metarepo::Log.info("Syncronizing upstream packages and updating the pool for upstream #{id}")
        Metarepo::Upstream[id].sync_packages
        Metarepo::Pool.new.update
      end
    end
  end
end
