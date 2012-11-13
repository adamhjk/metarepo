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
require 'zlib'

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
      if path =~ /^\//
        real_path = path
      else
        real_path = File.join(Metarepo::Config.upstream_path, path)
      end
      case type
      when "yum"
        Dir[File.join(real_path, "*.rpm")]
      when "apt"
        file_list = Array.new
        Zlib::GzipReader.open(File.join(real_path, "Packages.gz")) do |file|
          file.each_line do |line|
            if line =~ /^Filename: (.+)$/
              file_list << File.expand_path(File.join(
                                                      real_path,
                                                      "..",
                                                      "..",
                                                      "..",
                                                      "..",
                                                      $1
                                                      ))
            end
          end
        end
        file_list
      when "dir"
        [
         Dir[File.join(real_path, "*.rpm")],
         Dir[File.join(real_path, "*.deb")]
        ].flatten
      end
    end

    def sync_packages(file_list=nil)
      Metarepo::Log.info("Syncing packages from upstream #{name}")
      file_list ||= list_packages
      save
      seen_list = []
      file_list.each do |pkg|
        package = Metarepo::Package.from_file(pkg)
        Metarepo::Log.debug("Adding package #{package.name} to upstream #{name}")
        seen_list << package.shasum
        db.transaction do
          package.save
          add_package(package) unless packages.detect { |o| o.shasum == package.shasum }
        end
      end

      # Remove no longer relevant associations
      packages(true).detect do |pkg|
        if !seen_list.include?(pkg.shasum)
          Metarepo::Log.debug("Removing package #{pkg.name} from upstream #{name}")
          remove_package(pkg)
        end
      end
    end
  end
end
