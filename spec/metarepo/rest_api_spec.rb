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
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'metarepo/repo'
require 'metarepo/package'
require 'metarepo/upstream'
require 'metarepo/pool'
require 'metarepo/rest_api'
require 'rack/test'
require 'yajl'

describe Metarepo::RestAPI do
  include Rack::Test::Methods

	Metarepo::RestAPI.set :environment => "test"

	def app
		Metarepo::RestAPI
	end

  def resque_run
    klass, args = Resque.reserve(:default)
    if klass.respond_to? :perform
      klass.perform(*args) 
      true
    end
  end

	before(:each) do
    @upstream = Metarepo::Upstream.create(:name => "centos-6.0-os-i386", :type => "yum", :path => File.join(SPEC_DATA, "/upstream/centos/6.0/os/i386/Packages"))
    @upstream.sync_packages
    @pool_dir = File.join(SPEC_SCRATCH, "pool")
    @pool = Metarepo::Pool.new(@pool_dir)
    @pool.update
    @repo = Metarepo::Repo.new
    @repo.name = "shadows_fall"
    @repo.type = "yum"
    @repo.path = File.join(SPEC_SCRATCH, "repos", "shadows-fall")
    @repo.repo_dir = File.join(SPEC_SCRATCH, "repos")
    @repo.save
    @package_fields = [
        "name",
        "type",
        "shasum",
        "path",
        "filename",
        "version",
        "arch",
        "maintainer",
        "description",
        "url",
      ]
	end


  after(:each) do
    Resque.remove_queue(:default)
  end

	describe "/upstream" do
		describe "GET" do
			before(:each) do
				get '/upstream' 
			end

			it "returns 200 OK" do
				last_response.should be_ok
			end

			it "is application/json" do
				last_response.content_type.should =~ /^application\/json/
			end

			it "should include the upstream data" do
				response_data = Yajl::Parser.parse(last_response.body)
				response_data.should have_key("centos-6.0-os-i386")
			end
		end

		describe "POST" do
			before(:each) do
        @old_pool_path = Metarepo::Config.pool_path
        Metarepo::Config.pool_path = File.join(SPEC_SCRATCH, "pool")
				@upstream_body = <<-EOH 
					{
						"name": "centos-6.0-updates-x86_64",
            "path": "#{File.join(SPEC_DATA, "/upstream/centos/6.0/os/i386/Packages")}",
						"type": "yum"
					}
				EOH
				post '/upstream', @upstream_body 
			end

      after(:each) do
        Metarepo::Config.pool_path = @old_pool_path 
      end

			it "returns 201 OK" do
				last_response.status.should == 201 
			end

			it "is application/json" do
				last_response.content_type.should =~ /^application\/json/
			end

			it "creates a new upstream if it does not exist" do
				Metarepo::Upstream[:name => "centos-6.0-updates-x86_64"].should be_a_kind_of(Metarepo::Upstream)
			end

			it "returns 409 conflict if you try and create an upstream that already exists" do
				post '/upstream', @upstream_body 
				last_response.status.should == 409
				response_data = Yajl::Parser.parse(last_response.body)
				response_data.should have_key("error")
				response_data["error"].should == "name is already taken"
			end

			it "returns 400 if you validate another requirement" do
				@upstream_body["type"] = "nope"
				@upstream_body["name"] = "i-think-you-know"
				post '/upstream', @upstream_body 
				last_response.status.should == 400
				response_data = Yajl::Parser.parse(last_response.body)
				response_data["error"].should =~ /type must be/
			end

      it "returns the job_id" do
				response_data = Yajl::Parser.parse(last_response.body)
        response_data.should have_key("job_id")
      end

      it "puts a sync job on the queue, and the job updates the database" do
				response_data = Yajl::Parser.parse(last_response.body)
        resque_run.should == true
        Metarepo::Upstream[:name => "centos-6.0-updates-x86_64"].packages(true).length.should == 2
        Resque.constantize(response_data["job_class"]).get_meta(response_data["job_id"]).finished?.should == true
      end
		end
  end

  describe "/upstream/:name" do
    describe "GET" do
      before(:each) do
        get "/upstream/#{@upstream.name}"
      end

      it "returns 200 OK" do
        last_response.should be_ok
      end

      it "is application/json" do
        last_response.content_type.should =~ /^application\/json/
      end

      it "should return the upstream object" do
        test_upstream = Metarepo::Upstream[:name => @upstream.name]
        response_data = Yajl::Parser.parse(last_response.body)
        [ "name", "type", "path", "created_at", "updated_at" ].each do |key|
          response_data.should have_key(key)
        end
      end
    end

    describe "PUT" do
      before(:each) do
        @old_pool_path = Metarepo::Config.pool_path 
        Metarepo::Config.pool_path = File.join(SPEC_SCRATCH, "pool")
        @upstream_body = <<-EOH 
          {
            "name": "centos-6.0-updates-x86_64",
            "path": "#{File.join(SPEC_DATA, "/upstream/centos/6.0/os/i386/Packages")}",
            "type": "yum"
          }
        EOH
        put "/upstream/#{@upstream.name}", @upstream_body
      end

      after(:each) do
        Metarepo::Config.pool_path = @old_pool_path 
      end

      it "should return 201 on creation" do
        last_response.status.should == 201 
      end

      it "is application/json" do
        last_response.content_type.should =~ /^application\/json/
      end

      it "puts a sync job on the queue, and the job updates the database" do
        resque_run.should == true
        Metarepo::Upstream[:name => "centos-6.0-updates-x86_64"].packages(true).length.should == 2
      end
    end
  end

  describe "/upstream/:name/packages" do
    describe "GET" do
      before(:each) do
        get "/upstream/#{@upstream.name}/packages"
      end

      it "should return 200" do
        last_response.status.should == 200
      end

      it "is application/json" do
        last_response.content_type.should =~ /^application\/json/
      end

      it "should return all the packages in the upstream" do
				response_data = Yajl::Parser.parse(last_response.body)
        response_data.length.should == @upstream.packages.length
      end

      it "should have keys that are shasums" do
				response_data = Yajl::Parser.parse(last_response.body)
        response_data.each do |shasum, package|
          shasum.length.should == 64
        end
      end

      it "should have all the package fields for each package" do
        @package_fields.each do |package_key|
          response_data = Yajl::Parser.parse(last_response.body)
          response_data.each do |shasum, package|
            package.should have_key(package_key)
          end
        end
      end
    end
  end

  describe "/repo" do
    describe "GET" do
      before(:each) do
        get "/repo"
      end

      it "should return 200" do
        last_response.status.should == 200
      end

      it "is application/json" do
        last_response.content_type.should =~ /^application\/json/
      end

      it "should return all the repos names and urls" do
				response_data = Yajl::Parser.parse(last_response.body)
        response_data.length.should == Metarepo::Repo.all.length
        Metarepo::Repo.all do |r|
          response_data[r.name].should =~ /^http:\/\/.+\/repo\/#{r.name}/
        end
      end
    end

		describe "POST" do
			before(:each) do
        @old_pool_path = Metarepo::Config.pool_path
        Metarepo::Config.pool_path = File.join(SPEC_SCRATCH, "pool")
				@repo_body = <<-EOH 
					{
						"name": "centos-6.0-updates-x86_64-dev",
						"type": "yum"
					}
				EOH
				post '/repo', @repo_body 
			end

      after(:each) do
        Metarepo::Config.pool_path = @old_pool_path 
      end

			it "returns 201 OK" do
				last_response.status.should == 201 
			end

			it "is application/json" do
				last_response.content_type.should =~ /^application\/json/
			end

			it "creates a new repo if it does not exist" do
				Metarepo::Repo[:name => "centos-6.0-updates-x86_64-dev"].should be_a_kind_of(Metarepo::Repo)
			end

			it "returns 409 conflict if you try and create a repo that already exists" do
				post '/repo', @repo_body 
				last_response.status.should == 409
				response_data = Yajl::Parser.parse(last_response.body)
				response_data.should have_key("error")
				response_data["error"].should == "name is already taken"
			end

			it "returns 400 if you validate another requirement" do
				@repo_body["type"] = "nope"
				@repo_body["name"] = "i-think-you-know"
				post '/repo', @repo_body 
				last_response.status.should == 400
				response_data = Yajl::Parser.parse(last_response.body)
				response_data["error"].should =~ /type must be/
			end
    end
  end

  describe "/repo/:name" do
    describe "GET" do
      before(:each) do
        @repo = Metarepo::Repo.first
        get "/repo/#{@repo.name}"
      end

      it "should return 200" do
        last_response.status.should == 200
      end

      it "is application/json" do
        last_response.content_type.should =~ /^application\/json/
      end

      it "should the repos name, type, created_at and updated_at fields" do
				response_data = Yajl::Parser.parse(last_response.body)
        response_data.should have_key("name")
        response_data.should have_key("type")
        response_data.should have_key("created_at")
        response_data.should have_key("updated_at")
      end
    end

    describe "PUT" do
      before(:each) do
        @old_pool_path = Metarepo::Config.pool_path 
        Metarepo::Config.pool_path = File.join(SPEC_SCRATCH, "pool")
        Metarepo::Config.repo_path = File.join(SPEC_SCRATCH, "repo")
        @repo_body = <<-EOH 
          {
            "name": "centos-6.0-updates-x86_64-dev",
            "type": "yum"
          }
        EOH
        put "/repo/centos-6.0-updates-x86_64-dev", @repo_body
      end

      after(:each) do
        Metarepo::Config.pool_path = @old_pool_path 
      end

      it "should return 201 on creation" do
        last_response.status.should == 201 
      end

      it "is application/json" do
        last_response.content_type.should =~ /^application\/json/
      end
    end
  end

  describe "/repo/:name/packages" do
    describe "PUT" do
      before(:each) do
        @old_pool_path = Metarepo::Config.pool_path 
        @old_repo_path = Metarepo::Config.repo_path 
        Metarepo::Config.pool_path = File.join(SPEC_SCRATCH, "pool")
        Metarepo::Config.repo_path = File.join(SPEC_SCRATCH, "repo")
      end

      after(:each) do
        Metarepo::Config.repo_path = @old_repo_path 
        Metarepo::Config.pool_path = @old_pool_path 
      end

      describe "sync requests" do
        before(:each) do
          @sync_body = <<-EOH 
          {
            "sync": {
              "name": "#{@upstream.name}",
              "type": "upstream"
            }
          }
          EOH
          put "/repo/#{@repo.name}/packages", @sync_body
        end

        it "should return 201 on creation" do
          last_response.status.should == 201 
        end

        it "is application/json" do
          last_response.content_type.should =~ /^application\/json/
        end

        it "puts a sync job on the queue, and the job updates the database" do
          resque_run.should == true
          @repo.packages.length.should == 2
        end
      end

      describe "package list requests" do
        before(:each) do
          @packages = Metarepo::Package.limit(2).order(:name)
          @req_body = {}
          @packages.each do |pkg|
            @req_body[pkg.shasum] = true
          end
          put "/repo/#{@repo.name}/packages", Yajl::Encoder.encode(@req_body)
        end

        it "should return 201 on creation" do
          last_response.status.should == 201 
        end

        it "is application/json" do
          last_response.content_type.should =~ /^application\/json/
        end

        it "puts a job on the queue, and the job updates the database" do
          resque_run.should == true
          @repo.packages.length.should == 2
        end
      end
    end
  end

  describe "/package" do
    describe "GET" do
      before(:each) do
        get "/package"
      end

      it "should return 200" do
        last_response.status.should == 200
      end

      it "is application/json" do
        last_response.content_type.should =~ /^application\/json/
      end

      it "should return all the packages shasum and url" do
				response_data = Yajl::Parser.parse(last_response.body)
        response_data.length.should == Metarepo::Package.all.length
        response_data.each do |shasum, uri|
          shasum.length.should == 64
          uri.should =~ /http:\/\/.+\/package\/#{shasum}/
        end
      end
    end

  end

  describe "/package/:shasum" do
    describe "GET" do
      before(:each) do
        @package = Metarepo::Package.first
        get "/package/#{@package.shasum}"
      end

      it "should return 200" do
        last_response.status.should == 200
      end

      it "is application/json" do
        last_response.content_type.should =~ /^application\/json/
      end

      it "should return the package object, and have all the fields" do
				response_data = Yajl::Parser.parse(last_response.body)
        @package_fields.each do |package_key|
          response_data.should have_key(package_key)
        end
      end
    end
  end

end
