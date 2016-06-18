require_relative '../lib/slackapi.rb'
require_relative '../lib/slackadmin.rb'
require_relative '../lib/botaction.rb'
require_relative '../lib/conf.rb'
require 'websocket-eventmachine-client'
require 'json'

rtm = RTM.start
uri = rtm["url"]
my_name = rtm["self"]["name"]
my_id = rtm["self"]["id"]
puts "#{my_id} #{my_name}"

EM.run do
  ws = WebSocket::EventMachine::Client.connect(uri:uri)

  ws.onopen do
    if $conf["banhammer"]["enabled"]
      puts "Checking for new users to ban..."
      SlackAdmin.banInterlopersBecauseSlackWontLetUsTurnOffSelfServiceProvisioning
    end
  end

  ws.onmessage do |packet|
    event = JSON.parse packet
    case event["type"]
    when "team_join"
      if $conf["banhammer"]["enabled"]
        # Ban the new user if they aren't on the list
        puts "NEW USER DETECTED, SWINGING BANHAMMER"
        SlackAdmin.banInterlopersBecauseSlackWontLetUsTurnOffSelfServiceProvisioning
      end
    when "message"
      # ignore subtypes, only respond to @callouts, don't talk to yourself
      if (!event["subtype"] and event["text"].match(/\<\@#{my_id}\>/) and event["user"]!=my_id)
        puts "heard: #{event}"
        txt = "<@#{event["user"]}>: "
        case event["text"]
        when /\bDEBUG\b/
          txt+=event.to_s
        when /\bhelp\b/i
          txt+=BotAction.help(my_name)
        when /\bpleh\b/i
          txt+="That's not nice!"
        when /\binvite.+mailto:(.+)\|/i
          txt+=BotAction.invite(channel:event["channel"],email:$1)
        when /\bEXIT\b/
          exit 0
        else
          txt+=BotAction.confused()
        end
        reply = {"type": "message",
          "channel": event["channel"],
          "text": txt}
        puts "replied: #{reply}"
        ws.send(JSON.generate(reply))
      end
    end
  end

  ws.onclose do |code, reason|
    puts "Disconnected with status code: #{code}"
  end
end
