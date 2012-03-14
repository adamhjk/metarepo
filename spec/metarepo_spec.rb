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

