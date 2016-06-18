require_relative '../lib/slackapi.rb'

##
# Things the bot can do or say.
module BotAction
  ##
  # Invite a user by email address to a channel. Will fail (with a helpful
  # message) if user exists or has already been invited.
  def self.invite(channel:, email:)
    ret=nil
    case channel
    when /^C/
      channel=Channels.info(channel)
    when /^G/
      channel=Groups.info(channel)
    when /^D/
      return "Sorry, I can't invite users to a Direct Message session. Try a channel or group instead."
    else
      return self.confused
    end
    puts "Inviting #{email} to #{channel["id"]}"
    begin
      puts Users.invite(channel:channel["id"],email:email,ultra_restricted:true)
      ret="I've invited #{email} as a single channel guest in this channel!"
    rescue Exception => e
      if (e.message.match /already_invited$/)
        ret="Sorry, #{email} has already been invited, I can't send another invitation."
      elsif (e.message.match /already_in_team$/)
        ret="#{email} is already a member of the this Slack team. Try '/invite <@#{Users.email2id(email)}>' instead."
      else
        puts "invite failed: #{e.message}"
        ret="Sorry, I couldn't invite #{email}, there was an error I don't know how to handle. Contact my creator for assistance."
      end
    end
  end

  # Return bot's help text message.
  def self.help(my_name)
    "say \"@#{my_name}: Invite user@example.com\" to invite a single channel guest to the channel."
  end

  # Return bot's message of misunderstanding.
  def self.confused
    "I'm not sure what you need, use the word 'help' if you'd like to know what I can do!"
  end
end