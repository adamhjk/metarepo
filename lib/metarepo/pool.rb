require 'metarepo/config'

class Metarepo
  class Pool
    attr_accessor :dir

    def initialize(dir=nil)
      @dir = dir
      @dir ||= Metarepo::Config['pool_path']
    end

    def pool_path_for(package)
      File.join(@dir, package.shasum[0], package.shasum[1..2], package.shasum[3..6])
    end

    def pool_file_for(package)
      File.join(pool_path_for(package), package.filename)
    end

    def update_package(package)
      package_pool_path = pool_path_for(package)
      Metarepo.create_directory(package_pool_path)

      package_pool_file = pool_file_for(package)
      unless File.exists?(package_pool_file)
        File.link(package.path, File.join(package_pool_path, package.filename))
      end
    end

    def update
      Metarepo::Package.dataset.select(:shasum, :path, :filename).each do |package|
        update_package(package)
      end
    end
  end
end
