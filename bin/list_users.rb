require_relative '../lib/slackapi.rb'
require "yaml"

users = Users.clean_list.select{|m| !m["is_ultra_restricted"]}
email = users.map{|u| u["profile"]["email"]}

puts email.to_yaml
