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

