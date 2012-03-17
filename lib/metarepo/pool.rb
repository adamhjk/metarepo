#
# Author: adam@opscode.com
#
# Copyright 2012, Opscode, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'metarepo/config'

class Metarepo
  class Pool
    attr_accessor :dir

    def initialize(dir=nil)
      @dir = dir
      @dir ||= Metarepo::Config.pool_path
    end

    def pool_path_for(package)
      File.join(@dir, package.shasum[0], package.shasum[1..2], package.shasum[3..6])
    end

    def pool_file_for(package)
      File.join(pool_path_for(package), package.filename)
    end

    def link_package(package)
      Metarepo::Log.info("Linking #{package.name} from #{package.path} to pool")
      package_pool_path = pool_path_for(package)
      Metarepo.create_directory(package_pool_path)

      package_pool_file = pool_file_for(package)
      unless File.exists?(package_pool_file)
        Metarepo::Log.debug("Building hard link for missing package #{package.name} in pool")
        File.link(package.path, File.join(package_pool_path, package.filename))
      end
    end

    def update
      Metarepo::Package.dataset.select(:name, :shasum, :path, :filename).each do |package|
        link_package(package)
      end
    end
  end
end
