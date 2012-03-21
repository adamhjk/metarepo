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
require 'mixlib/shellout'
require 'sequel'
require 'metarepo/log'
require 'metarepo/config'

class Metarepo
  VERSION = "0.1.0"

  class << self
    def create_directory(dir)
      unless Dir.exists?(dir)
        Metarepo.command("mkdir -p #{dir}")
      end
    end

    def connect_db(db_connect=Metarepo::Config['db_connect'])
      Sequel::Model.plugin :timestamps
      Sequel::Model.db = Sequel.connect(db_connect)
    end

    # Runs a command and returns stdout and stderr on success. On failure, raises a RuntimeError.
    #
    # @param [String] the command to run
    # @return [Array] Returns an array with STDOUT and STDERR as strings.
    # @raise [RuntimeError] if the command has non-zero exit code.
    def command(cmd)
      Metarepo::Log.debug("Running command: #{cmd}")
      command = Mixlib::ShellOut.new(cmd)
      command.run_command
      status = command.status
      stdout = command.stdout
      stderr = command.stderr
      unless status.success?
        Metarepo::Log.error("Command #{cmd} failed with status code #{status.exitstatus}")
        Metarepo::Log.error("---STDOUT---")
        Metarepo::Log.error(stdout)
        Metarepo::Log.error("---STDERR---")
        Metarepo::Log.error(stderr)
        raise RuntimeError, "Command #{cmd} failed with status code #{status.exitstatus}"
      end
      Metarepo::Log.debug("---STDOUT---")
      Metarepo::Log.debug(stdout)
      Metarepo::Log.debug("---STDERR---")
      Metarepo::Log.debug(stderr)
      return stdout, stderr
    end

    # Runs a command with @cmd, but yields each line of stdout to the block.
    #
    # @param [String] the command to run
    def command_per_line(cmd, &block)
      o, e = command(cmd)
      o.split("\n").each do |line|
        block.call(line)
      end
    end
  end
end

