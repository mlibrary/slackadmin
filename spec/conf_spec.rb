require_relative "../lib/conf.rb"

RSpec.describe "conf.rb" do
  context "upon require" do
    it "loads conf.yaml to a hash, with some cofiguration in it" do
      expect($conf).to be_instance_of(Hash)
      expect($conf["token"]).not_to be_nil
    end
  end
end
