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
require 'metarepo/command'
require 'yajl'
require 'rest_client'
require 'mixlib/cli'

class Metarepo
  class Command
    class RepoPackages < Metarepo::Command
      option :name,
      :short => "-n NAME",
      :long => "--name NAME",
      :description => "The repo name",
      :required => true

      def run
        response = @rest["/repo/#{config[:name]}/packages"].get
        data = Yajl::Parser.parse(response.body)
        puts Yajl::Encoder.encode(data, :pretty => true, :indent => "  ")
        exit 0
      end
    end
  end
end
