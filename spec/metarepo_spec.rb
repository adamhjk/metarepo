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
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Metarepo" do
  describe "self.command" do
    it "runs a command and returns stdout and stderr" do
      o, e = Metarepo.command("echo foo")
      o.should == "foo\n"

      o, e = Metarepo.command("bash -c 'echo foo 1>&2'")
      e.should == "foo\n"
    end

    it "raises a RuntimeError on command failure" do
      lambda { Metarepo.command("bash -c 'exit 1'") }.should raise_error(RuntimeError)
    end
  end

  describe "self.command_per_line" do
    it "yields a block for each line of output" do
      seen = Hash.new
      Metarepo.command_per_line("cat #{File.join(SPEC_DATA, 'command_per_line')}") do |line|
        seen[line] = true
      end
      seen.has_key?("one").should == true
      seen.has_key?("two").should == true
      seen.has_key?("three").should == true
      seen.keys.length.should == 3
    end
  end
end

