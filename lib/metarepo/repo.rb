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
require 'metarepo/package'

class Metarepo
  class Repo < Sequel::Model
    plugin :validation_helpers

    many_to_many :packages

    attr_accessor :repo_dir

    def validate
      super
      validates_unique :name
      validates_presence [ :type ]
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
  
    def repo_path
      rpath = @repo_dir.nil? ? Metarepo::Config.repo_path : @repo_dir
      File.expand_path(File.join(rpath, name))
    end

    def repo_file_for(package)
      File.expand_path(File.join(repo_path, package.filename))
    end

    def link_package(package, pool=nil)
      Metarepo::Log.info("Linking #{package.name} to repo #{name}")
      pool ||= Metarepo::Pool.new(Metarepo::Config.pool_path)
      Metarepo.create_directory(repo_path)
      unless File.exists?(repo_file_for(package))
        Metarepo::Log.info("Building hard link for missing package #{package.name} in repo")
        File.link(pool.pool_file_for(package), repo_file_for(package))
      end
      add_package(package) unless packages.detect { |o| o.shasum == package.shasum } 
    end

    def unlink_package(package, pool=nil)
      Metarepo::Log.info("Unlinking #{package.name} from repo #{name}")
      File.unlink(repo_file_for(package)) if File.exists?(repo_file_for(package))
      remove_package(package) 
    end

    def sync_packages(upstream_packages, pool=nil)
      pool ||= Metarepo::Pool.new(Metarepo::Config.pool_path)
      upstream_packages.each do |upstream_package|
        link_package(upstream_package, pool) unless packages.detect { |o| o.shasum == upstream_package.shasum }
      end
      packages_dataset.all do |repo_package|
        unlink_package(repo_package, pool) unless upstream_packages.detect { |o| o.shasum == repo_package.shasum }
      end
      self.save
    end

    def sync_to_upstream(name, pool=nil)
      pool ||= Metarepo::Pool.new(Metarepo::Config.pool_path)
      upstream_packages = Metarepo::Upstream[:name => name].packages_dataset.all
      sync_packages(upstream_packages, pool)
    end

    def sync_to_repo(name, pool=nil)
      pool ||= Metarepo::Pool.new(Metarepo::Config.pool_path)
      upstream_packages = Metarepo::Repo[:name => name].packages_dataset.all
      sync_packages(upstream_packages, pool)
    end

    def update_index_yum
      Metarepo.command("createrepo #{repo_path}")
    end

    def update_index
      Metarepo::Log.info("Creating package index")
      case type
      when "yum"
        update_index_yum
      end
    end

  end
end

