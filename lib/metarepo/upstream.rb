require 'metarepo/package'

class Metarepo
  class Upstream < Sequel::Model
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
      when "dir"
        [
          Dir[File.join(path, "*.rpm")],
          Dir[File.join(path, "*.deb")]
        ].flatten
      end
    end

    def sync_packages(file_list=nil)
      file_list ||= list_packages
      save
      seen_list = []
      file_list.each do |pkg|
        package = Metarepo::Package.from_file(pkg)
        seen_list << package.shasum
        db.transaction do
          package.save
          add_package(package) unless packages.detect { |o| o.shasum == package.shasum } 
        end
      end

      # Remove no longer relevant associations
      packages(true).detect do |pkg|
        remove_package(pkg) unless seen_list.include?(pkg.shasum)
      end
    end
  end
end
