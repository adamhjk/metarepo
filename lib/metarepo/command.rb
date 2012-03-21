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

require 'metarepo'
require 'yajl'
require 'rest_client'
require 'mixlib/cli'

class Metarepo
  class Command
    include Mixlib::CLI

    attr_accessor :rest, :opts

    option :config_file,
      :short => "-c CONFIG",
      :long => "--config CONFIG",
      :description => "A configuration file to use"

    option :log_level,
      :short => "-l LEVEL",
      :long  => "--log LEVEL",
      :description => "Set the log level (debug, info, warn, error, fatal)",
      :proc => Proc.new { |l| l.to_sym }

    option :uri,
      :short => "-u URI",
      :long => "--uri URI",
      :description => "The URI to find your metarepo server"

    option :help,
      :short => "-h",
      :long => "--help",
      :description => "Show this message",
      :on => :tail,
      :boolean => true,
      :show_options => true,
      :exit => 0

    def setup
      opts = parse_options
      Metarepo::Config.from_file(config[:config_file]) if config[:config_file]
      Metarepo::Log.level = config[:log_level] if config[:log_level]
      Metarepo::Config.uri = config[:uri] if config[:uri]
      @rest = RestClient::Resource.new Metarepo::Config.uri 
    end
  end
end
