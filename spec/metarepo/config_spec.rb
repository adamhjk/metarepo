require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'metarepo/config'

describe Metarepo::Config do
	it "db_connect has a sane default" do
		Metarepo::Config.db_connect.should == "postgres://localhost/metarepo"
	end

  it "pool_path has a sane default" do
    Metarepo::Config.pool_path.should == "/var/opt/metarepo/pool"
  end
end


