require 'metarepo/package'

class Metarepo
  class Repo < Sequel::Model
    plugin :validation_helpers

    many_to_many :packages

    def validate
      super
      validates_unique :name
      validates_presence [ :path, :type ]
      errors.add(:type, "must be yum, apt or dir") unless [ "yum", "apt", "dir" ].include?(type)
    end

    def list_packages
      case type
      when "yum"
        Dir[File.join(path, "*.rpm")]
      when "apt"
        Dir[File.join(path, "*.deb")]
      when "dir"
        [
          Dir[File.join(path, "*.rpm")],
          Dir[File.join(path, "*.deb")]
        ].flatten
      end
    end
  
    def repo_path_for(package)

    end

    def update_package(package, pool=nil)
      pool ||= Metarepo::Pool.new(Metarepo::Config.pool_path)
      Metarepo.create_directory(package_pool_path)
    end

    def sync_to_upstream(name, pool)
      Metarepo::Upstream[:name => name].packages.each do |package|
      end
    end
  end
end

