require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'metarepo/repo'
require 'metarepo/package'
require 'metarepo/upstream'
require 'metarepo/pool'

describe Metarepo::Repo do
  before(:each) do
    @repo = Metarepo::Repo.new
    @repo.name = "Shadows Fall"
    @repo.type = "yum"
    @repo.path = File.join(SPEC_SCRATCH, "repos", "shadows-fall")
    @repo.save
    @upstream = Metarepo::Upstream.create(:name => "centos-6.0-os-i386", :type => "yum", :path => File.join(SPEC_DATA, "/upstream/centos/6.0/os/i386/Packages"))
    @upstream.sync_packages
    @pool_dir = File.join(SPEC_SCRATCH, "pool")
    @pool = Metarepo::Pool.new(@pool_dir)
    @pool.update
  end

  describe "name" do
    it "must be unique" do
      lambda { 
        o = Metarepo::Repo.create(:name => "Shadows Fall", :type => "yum", :path => "/foo")
      }.should raise_error(Sequel::ValidationFailed)
    end
  end

  describe "path" do
    it "must be present" do
      lambda { 
        Metarepo::Repo.create(:name => "Shadows Falter", :type => "dir")
      }.should raise_error(Sequel::ValidationFailed)
    end
  end

  describe "type" do
    it "must be present" do
      lambda { 
        Metarepo::Repo.create(:name => "Shadows Falling", :path => "/foo")
      }.should raise_error(Sequel::ValidationFailed)
    end

    [ "yum", "apt", "dir" ].each do |type_name|
      it "can be #{type_name}" do
        @repo.type = type_name
        lambda { @repo.save }.should_not raise_error(Sequel::ValidationFailed)
      end
    end

    it "raises an error on other values" do
      @repo.type = "frobnobbery"
      lambda { @repo.save }.should raise_error(Sequel::ValidationFailed)
    end
  end

  describe "sync_to_upstream" do
    it "should link in every file in the upstream from the pool to the repo" do
      @repo.sync_to_upstream(@upstream.name, @pool)
    end
  end
  
end


