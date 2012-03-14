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

require 'metarepo/package'

describe Metarepo::Package do
  before(:each) do 
    @package = Metarepo::Package.new
    @package.shasum = "6b916ab5078337dd9b0fa411216044eb3c6dec71626145b0f7f3e7dfcebb060a"
    @package.name = "all_that_remains"
    @package.version = "0.1.1"
    @package.iteration = "1"
    @package.arch = "any"
    @package.maintainer = "Phil Labonte"
    @package.url = "http://foo.bar"
    @package.description = "All that remains!"
    @package.type = "rpm"
    @package.path = "/foo/bar/all_that_remains_0.1.1-1_x86_64.rpm"
    @package.filename = "all_that_remains_0.1.1-1_x86_64.rpm"
  end

  describe "shasum" do
    it "must be unique" do
      @package.save
      bp = Metarepo::Package.new
      bp.shasum = "6b916ab5078337dd9b0fa411216044eb3c6dec71626145b0f7f3e7dfcebb060a"
      bp.name = "all_that_remains"
      bp.version = "0.1.1"
      bp.iteration = "1"
      bp.arch = "any"
      bp.maintainer = "Phil Labonte"
      bp.url = "http://foo.bar"
      bp.description = "All that remains!"
      bp.type = "rpm"
      bp.path = "/foo/bar/all_that_remains_0.1.1-1_x86_64.rpm"
      bp.filename = "all_that_remains_0.1.1-1_x86_64.rpm"
      lambda { 
        bp.save
      }.should raise_error(Sequel::ValidationFailed)
    end
  end

  [ "name", "version", "iteration", "arch", "maintainer", "url", "description", "path", "filename" ].each do |pkg_attr|
    describe pkg_attr do
      it "must be present" do
        @package.send("#{pkg_attr}=", nil)
        lambda { 
          @package.save
        }.should raise_error(Sequel::ValidationFailed)
      end
    end
  end

  describe "type" do
    it "must be present" do
      @package.type = nil
      lambda { 
        @package.save
      }.should raise_error(Sequel::ValidationFailed)
    end

    [ "rpm", "deb" ].each do |type_name|
      it "can be #{type_name}" do
        @package.type = type_name
        lambda { @package.save }.should_not raise_error(Sequel::ValidationFailed)
      end
    end

    it "raises an error on other values" do
      @package.type = "frobnobbery"
      lambda { @package.save }.should raise_error(Sequel::ValidationFailed)
    end
  end

  describe "self.from_deb" do
    before(:all) do
      @p = Metarepo::Package.from_deb(File.join(SPEC_DATA, "libxcb-property1_0.3.6-1build1_amd64.deb"))
    end

    it "builds an Metarepo::Package from an rpm file" do
      @p.should be_a_kind_of(Metarepo::Package)
    end

    it "is a deb" do
      @p.type.should == "deb"
    end

    it "has a name" do
      @p.name.should == "libxcb-property1"
    end

    it "has a version" do
      @p.version.should == "0.3.6"
    end

    it "has an iteration" do
      @p.iteration.should == "1build1"
    end

    it "has an architecture" do
      @p.arch.should == "amd64"
    end

    it "has a maintainer" do
      @p.maintainer.should == "Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>"
    end
  end

  describe "self.from_rpm" do
    before(:all) do
      @p = Metarepo::Package.from_rpm(File.join(SPEC_DATA, "at-3.1.10-42.el6.i686.rpm"))
    end

    it "builds an Metarepo::Package from an rpm file" do
      @p.should be_a_kind_of(Metarepo::Package)
    end

    it "is an rpm" do
      @p.type.should == "rpm"
    end

    it "has a name" do
      @p.name.should == "at"
    end

    it "has a version" do
      @p.version.should == "3.1.10"
    end

    it "has an iteration" do
      @p.iteration.should == "42.el6"
    end

    it "has an architecture" do
      @p.arch.should == "i686"
    end

    it "has a maintainer" do
      @p.maintainer.should == "CentOS BuildSystem <http://bugs.centos.org>"
    end
  end

end

