require_relative "../lib/botaction.rb"

RSpec.describe BotAction do
  context "verbs" do
    it "invites new single channel guests"
  end

  context "messages" do
    it "help" do
      expect(BotAction.help "foobar").to be_instance_of String
    end
    it "confused" do
      expect(BotAction.confused).to be_instance_of String
    end
  end
end
