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
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'metarepo'
require 'mixlib/shellout'
require 'sequel'

Metarepo::Log.level = :fatal

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

SPEC_DATA = File.expand_path(File.join(File.dirname(__FILE__), 'data'))
SPEC_SCRATCH = File.expand_path(File.join(File.dirname(__FILE__), 'scratch'))


def clean_database
  Metarepo.connect_db("postgres://localhost/template1")

  begin
    Sequel::Model.db.run("drop database metarepo_spec")
  #rescue Sequel::DatabaseError 
    # We don't care if it doesn't exist
  end

  Sequel::Model.db.run("create database metarepo_spec")

  Metarepo.connect_db("postgres://localhost/metarepo_spec")

  cmd = Mixlib::ShellOut.new("sequel -m #{File.expand_path(File.join(File.dirname(__FILE__), "..", "migrations"))} postgres://localhost/metarepo_spec")
  cmd.run_command
  cmd.error!
end

clean_database

RSpec.configure do |config|
  
end

class RSpec::Core::ExampleGroup
  def self.inherited(subclass)
    super
    subclass.around do |example|
      system("rm -rf #{SPEC_SCRATCH}")
      system("mkdir -p #{SPEC_SCRATCH}")
      Sequel::Model.db.transaction(:rollback=>:always){example.call}
    end
  end
end
