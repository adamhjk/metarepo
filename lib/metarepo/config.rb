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

require 'mixlib/config'

class Metarepo
  class Config
    extend Mixlib::Config

    def self.load
      if File.exists?("/var/opt/metarepo/metarepo/etc/metarepo-service.rb")
        Metarepo::Config.from_file("/var/opt/metarepo/metarepo/etc/metarepo-service.rb")
      elsif File.exists?("/etc/metarepo/metarepo-service.rb")
        Metarepo::Config.from_file("/etc/metarepo/metarepo-service.rb")
      else
        Metarepo::Log.warn("Cannot find a configuration file!")
      end
      true
    end

    db_connect 'postgres://localhost/metarepo'
    pool_path '/var/opt/metarepo/pool'
    repo_path '/var/opt/metarepo/repo'
    upstream_path '/var/opt/metarepo/upstream'
    uri "http://localhost:6667"
    gpg_key "metarepo@example.com"

  end
end

