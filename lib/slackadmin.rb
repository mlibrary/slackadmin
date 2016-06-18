require_relative './slackapi.rb'
require_relative './conf.rb'

##
# Collection of higher level actions for Slack build on top of SlackAPI methods.
# Some of these methods are intentionally chatty (i.e. they print to standard
# out) to help the bot generate useful logs.
module SlackAdmin
  ##
  # load user defined whitelist of allowed email addresses
  def self.whitelist
    YAML.load_file("#{File.dirname(__FILE__)}/../etc/whitelist.yaml")
  end

  ##
  # Generate array of Slack user objects that, based upon their absence from the
  # whitelist, should be banned.
  def self.interlopers
    users = Users.clean_list
    users.select{|m| !m["is_ultra_restricted"] and !whitelist.include?(m["profile"]["email"])}
  end

  ##
  # Set user as single channel guest in quarantine defined in config.yaml.
  def self.quarantine(user)
    Users.setUltraRestricted(user,channel:$conf["banhammer"]["quarantine_channel"])
  end

  ##
  # Find all non-whitelisted full and guest users (everyone but single channel
  # guests) and "ban" them (exact behavior set in config.yaml).
  def self.banInterlopersBecauseSlackWontLetUsTurnOffSelfServiceProvisioning
    interlopers = self.interlopers

    if interlopers.size > 0
      interlopers.each do |m|
        if($conf["banhammer"]["use_quarantine"])
          puts self.quarantine(m["id"])
          puts "QUARANTINED: #{m["name"]} <#{m["profile"]["email"]}>"
        end
        if($conf["banhammer"]["use_disable"])
          puts Users.setInactive(m["id"])
          puts "DISABLED: #{m["name"]} <#{m["profile"]["email"]}>"
        end
      end
    end
  end

  ##
  # Send out invitations to everyone who's on the whitelist, but isn't yet a
  # member.
  def self.inviteMissingUsers
    users  = Users.clean_list
    emails = users.map{|m| m["profile"]["email"]}
    missing = whitelist.select{|e| !emails.include?(e)}

    if missing.size > 0
      missing.each do |m|
        begin
          puts Users.invite(email: m)
          puts "Invited: <#{m}>"
        rescue Exception => e
          puts "Can't invite <#{m}>: #{e.message}"
        end
      end
    else
      puts "No new users to invite."
    end
  end

end
