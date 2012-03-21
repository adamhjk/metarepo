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
require 'metarepo/repo'
require 'metarepo/package'
require 'metarepo/job/upstream_sync_packages'
require 'metarepo/job/repo_sync_packages'
require 'metarepo/job/repo_packages'
require 'resque'

class Metarepo
	class RestAPI < Sinatra::Base

		def serialize(data)
			Yajl::Encoder.encode(data)
		end

    def package_serialize(p)
      {
        "name" => p.name,
        "type" => p.type,
        "shasum" => p.shasum,
        "path" => p.path,
        "filename" => p.filename,
        "version" => p.version,
        "arch" => p.arch,
        "maintainer" => p.maintainer,
        "description" => p.description,
        "url" => p.url
      }
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
      meta = Metarepo::Job::UpstreamSyncPackages.enqueue(upstream.id)
      serialize({ :enqueued_at => meta.enqueued_at, :job_id => meta.meta_id, :job_class => meta.job_class })
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

      meta = Metarepo::Job::UpstreamSyncPackages.enqueue(upstream.id)
      serialize({ :enqueued_at => meta.enqueued_at, :job_id => meta.meta_id, :job_class => meta.job_class })
		end

    get "/upstream/:name/packages" do
			content_type :json
      upstream = Metarepo::Upstream[:name => params["name"]]
      response = {}
      upstream.packages_dataset.all do |p|
        response[p.shasum] = package_serialize(p) 
      end
      serialize(response)
    end

    get "/package" do
			content_type :json
      response = {}
      Metarepo::Package.dataset.select(:shasum).each do |package|
        response[package.shasum] = url("/package/#{package.shasum}")
      end
      serialize(response)
    end

    get "/package/:shasum" do
			content_type :json
      response = {}
      package = Metarepo::Package[:shasum => params[:shasum]]
      serialize(package_serialize(package))
    end

    get "/repo" do
			content_type :json
      response = {}
      Metarepo::Repo.dataset.select(:name).each do |repo|
        response[repo.name] = url("/repo/#{repo.name}")
      end
      serialize(response)
    end

		post "/repo" do
			content_type :json
			request.body.rewind
			repo_data = Yajl::Parser.parse(request.body.read)
			repo = Metarepo::Repo.new
			repo.name = repo_data["name"]
			repo.type = repo_data["type"]
			begin
				repo.save
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
      serialize({ repo.name => url("/repo/#{repo.name}") })
		end

    get "/repo/:name" do
			content_type :json
      response = {}
      repo = Metarepo::Repo[:name => params[:name]]
      serialize({
        "name" => repo.name,
        "type" => repo.type,
        "created_at" => repo.created_at,
        "updated_at" => repo.updated_at
      })
    end

		put "/repo/:name" do
			content_type :json
			request.body.rewind
			repo_data = Yajl::Parser.parse(request.body.read)
      repo = Metarepo::Repo[:name => repo_data["name"]]
      if repo
        status 202
      else
        status 201
        repo = Metarepo::Repo.new
      end
			repo.name = repo_data["name"]
			repo.type = repo_data["type"]

			begin
				repo.save
			rescue Sequel::ValidationFailed => e
        status 400
        return serialize({ "error" => e.message })
			end
      serialize(
        {
          "name" => repo[:name],
          "type" => repo[:type],
          "created_at" => repo[:created_at],
          "updated_at" => repo[:updated_at]
        }
      )
		end

    put "/repo/:name/packages" do
			content_type :json
			request.body.rewind
			package_data = Yajl::Parser.parse(request.body.read)
      repo = Metarepo::Repo[:name => params[:name]]
      if package_data.has_key?("sync")
        meta = Metarepo::Job::RepoSyncPackages.enqueue(repo.name, package_data["sync"]["type"], package_data["sync"]["name"])
      else
        meta = Metarepo::Job::RepoPackages.enqueue(repo.name, package_data)
      end
      status 201
      serialize({ :enqueued_at => meta.enqueued_at, :job_id => meta.meta_id, :job_class => meta.job_class })
    end

    get "/job/:job_class/:job_id" do
			content_type :json
      meta = Resque.constantize(params["job_class"]).get_meta(params["job_id"])
      serialize({
        :job_id => meta.meta_id,
        :job_class => meta.job_class,
        :enqueued_at => meta.enqueued_at,
        :started_at => meta.started_at,
        :succeeded => meta.succeeded?,
        :finished_at => meta.finished_at
      })
    end

	end
end

