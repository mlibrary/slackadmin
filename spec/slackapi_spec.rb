require_relative "../lib/slackapi.rb"

##
# Fake child of SlackAPI for testing purposes, also supports the "api" Slack api
# namespace, which only contains the testing method "test".
module Test
  extend SlackAPI
  # dispatch support
  def self.name
    "api"
  end
end

RSpec.describe SlackAPI do
  context "api test" do
    it "returns \"ok\"=>true" do
      expect(Test.apicall("test")["ok"]).to be true
    end
  end

  context "RTM.start" do
    it "returns \"ok\"=>true" do
      expect(RTM.start["ok"]).to be true
    end
  end

  context "SlackAPI.list" do
    channels = Channels.list
    it "Channels.list lists one or more channels" do
      expect(channels).to be_instance_of Array
      expect(channels.length > 0).to be true
    end

    users = Users.list
    it "Users.list lists one or more users" do
      expect(users).to be_instance_of Array
      expect(users.length > 0).to be true
    end
  end

  context "SlackAPI.info" do
    rchannel = Channels.list.sample
    channel_ret = Channels.info rchannel["name"]
    it "Channels.info returns expected user name and id" do
      expect(channel_ret["name"]).to eq(rchannel["name"])
      expect(channel_ret["id"]).to eq(rchannel["id"])
    end

    ruser = Users.list.sample
    user_ret = Users.info ruser["name"]
    it "Users.info returns expected user name and id" do
      expect(user_ret["name"]).to eq(ruser["name"])
      expect(user_ret["id"]).to eq(ruser["id"])
    end
  end

  context "SlackAPI.normalize" do
    it "Translates channel name to id" do
      rchannel = Channels.list.sample
      expect(Channels.normalize(rchannel["name"])).to eq(rchannel["id"])
    end
    it "Translates user name to id" do
      ruser = Users.list.sample
      expect(Users.normalize(ruser["name"])).to eq(ruser["id"])
    end
  end
end

RSpec.describe Users do
  context "Users.clean_list" do
    it "Lists users who aren't bots" do
      users = Users.clean_list

      expect(users).to be_instance_of Array
      expect(users.length > 0).to be true
      expect(users.select{|m| m["name"]=="slackbot"}.length).to equal(0)
      expect(users.select{|m| m["is_bot"]}.length).to equal(0)
      expect(users.select{|m| m["deleted"]}.length).to equal(0)
    end
  end

  context "make user a single channel guest" do
    it "sets is_ultra_restricted=true, deleted=false" do
      # enable test user
      Users.setRegular($conf["test_user"])
      # restrict user
      Users.setUltraRestricted($conf["test_user"],channel:$conf["banhammer"]["quarantine_channel"])
      user = Users.list($conf["test_user"])
      
      expect(user["is_ultra_restricted"]).to be true
      expect(user["deleted"]            ).to be false
    end
  end
  context "make user a standard guest" do
    it "sets is_ultra_restricted=false is_restricted=true deleted=false" do
      # enable test user
      Users.setRegular($conf["test_user"])
      # restrict test user
      Users.setRestricted($conf["test_user"])
      user = Users.list($conf["test_user"])

      expect(user["is_ultra_restricted"]).to be false
      expect(user["is_restricted"]      ).to be true
      expect(user["deleted"]            ).to be false
    end
  end
  context "make user a full standard user" do
    it "sets is_restricted=false deleted=false" do
      Users.setRegular($conf["test_user"])
      user = Users.list($conf["test_user"])

      expect(user["is_restricted"]).to be false
      expect(user["deleted"]      ).to be false
    end
  end
  context "ban user" do
    it "sets deleted=true" do
      # enable test user
      Users.setRegular($conf["test_user"])
      # kick them out again
      Users.setInactive($conf["test_user"])
      user = Users.list($conf["test_user"])

      expect(user["deleted"]).to be true
    end
  end
end
