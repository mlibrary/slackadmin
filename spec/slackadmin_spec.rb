require_relative "../lib/slackadmin.rb"

RSpec.describe SlackAdmin do
  context "read whitelist" do
    it "returns an array of email addresses" do
      wl=SlackAdmin.whitelist
      expect(wl).to be_instance_of Array
      expect(wl.length > 0).to be true
      expect(wl.select{|i| i.is_a?(String) and i===/^[a-z0-9\_\-]+\@([a-z0-9\-]+\.)+[a-z]+$/i})
    end
  end

  context "get interlopers" do
    it "returns list of users to ban, only user on list should be the test user" do
      # enable test user
      Users.setRegular($conf["test_user"])

      interlopers = SlackAdmin.interlopers
      expect(interlopers).to be_instance_of Array
      expect(interlopers.length).to equal (1)
      expect(interlopers.select{|i| i["name"]==$conf["test_user"]}.length).to equal (1)
      expect(interlopers[0]["name"]).to eq ($conf["test_user"])
    end
  end

  context "quarantine" do
    it "makes user a single channel guest in the quarantine channel" do
      Users.setRegular($conf["test_user"])
      SlackAdmin.quarantine($conf["test_user"])

      user = Users.list($conf["test_user"])
      expect(user["is_ultra_restricted"]).to be true
      expect(user["deleted"]            ).to be false
      expect(Channels.info($conf["banhammer"]["quarantine_channel"])["members"].include?(user["id"])).to be (true)
    end
  end
end
