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

require 'metarepo/pool'
require 'metarepo/package'
require 'metarepo/upstream'

describe Metarepo::Pool do
  before(:each) do
    @centos = Metarepo::Upstream.create(:name => "centos-6.0-os-i386", :type => "yum", :path => File.join(SPEC_DATA, "/upstream/centos/6.0/os/i386/Packages"))
    @centos.sync_packages
    @pool_dir = File.join(SPEC_SCRATCH, "pool")
    @pool = Metarepo::Pool.new(@pool_dir)
  end

  describe "initialize" do
    it "takes a pool directory as an argument" do
      Metarepo::Pool.new("/tmp").dir.should == "/tmp"
    end

    it "defaults to Metarepo::Config['pool_path']" do
      Metarepo::Pool.new.dir.should == "/var/opt/metarepo/pool"
    end
  end

  describe "link_package" do
    before(:each) do
      @package = Metarepo::Package[:name => "basesystem"]
    end

    it "creates paths for shasums" do
      @pool.link_package(@package)
      Dir.exists?(File.join(@pool_dir, "1", "88", "6000")).should == true
    end

    it "hardlinks in the package file from the upstream" do
      @pool.link_package(@package)
      File.exists?(File.join(@pool_dir, "1", "88", "6000", @package.filename)).should == true
    end

    it "does not hardlink in the package file from the upstream if it exists" do
      @pool.link_package(@package)
      lambda { @pool.link_package(@package) }.should_not raise_error(Errno::EEXIST)
    end
  end

  describe "update" do
    it "hardlinks in every package file" do
      @pool.update
      File.exists?(File.join(@pool_dir, "1", "88", "6000", "basesystem-10.0-4.el6.noarch.rpm")).should == true
      File.exists?(File.join(@pool_dir, "9", "4b", "69ae", "bitmap-fonts-compat-0.3-15.el6.noarch.rpm")).should == true
    end
  end
end

