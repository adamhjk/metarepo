require 'metarepo'
Metarepo.connect_db unless Sequel::Model.db
require 'metarepo/upstream'
require 'metarepo/package'
require 'metarepo/repo'

class Metarepo
  class Job
    class UpstreamSyncPackages

      @queue = :default

      def self.perform(id)
        Metarepo::Log.info("Syncronizing upstream packages and updating the pool for upstream #{id}")
        Metarepo::Upstream[id].sync_packages
        Metarepo::Pool.new.update
      end
    end
  end
end
