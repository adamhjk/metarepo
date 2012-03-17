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

require 'sinatra/base'
require 'yajl'
require 'metarepo'
require 'metarepo/upstream'
require 'metarepo/job/upstream_sync_packages'
require 'resque'

class Metarepo
	class RestAPI < Sinatra::Base

		def serialize(data)
			Yajl::Encoder.encode(data)
		end

		get "/upstream" do
			content_type :json
			response_data = {}
			Metarepo::Upstream.each do |upstream|
				response_data[upstream.name] = url("/upstream/#{upstream.name}")
			end
			serialize(response_data)
		end

		post "/upstream" do
			content_type :json
			request.body.rewind
			upstream_data = Yajl::Parser.parse(request.body.read)
			upstream = Metarepo::Upstream.new
			upstream.name = upstream_data["name"]
			upstream.path = upstream_data["path"]
			upstream.type = upstream_data["type"]
			begin
				upstream.save
			rescue Sequel::ValidationFailed => e
				if e.message == "name is already taken"
					status 409
					return serialize({ "error" => e.message })
				else
					status 400
					return serialize({ "error" => e.message })
				end
			end
      status 201
      Resque.enqueue(Metarepo::Job::UpstreamSyncPackages, upstream.id)
			serialize({ "uri" => url("/upstream/#{upstream.name}") })
		end

    get "/upstream/:name" do
      content_type :json
      upstream = Metarepo::Upstream[:name => params[:name]]
      serialize(
        {
          "name" => upstream[:name],
          "type" => upstream[:type],
          "path" => upstream[:path],
          "created_at" => upstream[:created_at],
          "updated_at" => upstream[:updated_at]
        }
      )
    end

		put "/upstream/:name" do
			content_type :json
			request.body.rewind
			upstream_data = Yajl::Parser.parse(request.body.read)
      upstream = Metarepo::Upstream[:name => upstream_data["name"]]
      if upstream
        status 202
      else
        status 201
        upstream = Metarepo::Upstream.new
      end
      upstream.name = upstream_data["name"]
      upstream.path = upstream_data["path"]
      upstream.type = upstream_data["type"]

      begin
        upstream.save
			rescue Sequel::ValidationFailed => e
        status 400
        return serialize({ "error" => e.message })
			end

      Resque.enqueue(Metarepo::Job::UpstreamSyncPackages, upstream.id)

			serialize({ "uri" => url("/upstream/#{upstream.name}") })
		end

	end
end

