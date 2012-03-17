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

      it "puts a sync job on the queue, and the job updates the database" do
        resque_run.should == true
        Metarepo::Upstream[:name => "centos-6.0-updates-x86_64"].packages(true).length.should == 2
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

	end
end
