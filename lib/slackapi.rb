require 'net/http'
require 'json'
require_relative './conf.rb'
require 'byebug'
##
# Abstract module inherited by all other API modules.
module SlackAPI
  ##
  # Calls arbitrary API on Slack, fills in namespace based on module we're in
  def apicall(verb, **options)
    uri = URI "https://slack.com/api/#{self.name}.#{verb}"
    options[:token]=$conf["token"]
    result = Net::HTTP.post_form(uri,options)
    json = JSON.parse result.body
    json["ok"] and return json

    raise "API call to #{uri} failed with: #{json["error"]}"
  end

  ##
  # Call ModuleName.list on Slack
  def list(name=nil)
    list = self.apicall('list')[self.list_item]
    name and return list.select{|i| i["name"]==name}[0]
    list
  end

  ##
  # Takes object name or id and returns id
  def normalize(data)
    self.normalizeField(:"#{self.name}",data)
  end

  ##
  # Call ModuleName.list on Slack
  #
  # Runs input through normalize() first, so either id or name is acceptable
  def info(id)
    id = self.normalize(id)
    self.apicall("info","#{self.info_field1}":id)[self.info_field2]
  end

  protected
  ##
  # Internal support for dispatch on other methods
  def list_item
    self.name
  end
  
  ##
  # Internal support for info() dispatch
  def info_field2
    self.name.chop
  end
  ##
  # Internal support for info() dispatch
  def info_field1
    self.info_field2
  end

  ##
  # normalize() implimentation
  def normalizeField(type,data)
    # assume non-strings are okay
    (data.is_a? String) or return data

    # if it's already an ID we're done
    data.match(/^[A-Z]/) and return data

    # transform names to ID's
    entry = nil
    case type
    when :channel, :channels, :group, :groups
      (entry = Channels.list data) or (entry = Groups.list data)
    when :user, :users
      entry = Users.list data
    end

    if entry
      return entry["id"]
    end

    # either this field doesn't need to be normalized or we failed,
    # either way, we'll return the original input
    data
  end
end

##
# Wrapper around Slack "channels" API namespace. See SlackAPI for methods.
module Channels
  extend SlackAPI
  protected
  # dispatch support
  def self.name
    "channels"
  end
end

##
# Wrapper around Slack "groups" API namespace. See SlackAPI for methods.
module Groups
  extend SlackAPI
  protected
  # dispatch support
  def self.name
    "groups"
  end
  # dispatch support, work around API inconsistancies
  def self.info_field1
    "channel"
  end
end

##
# Wrapper around Slack "users" API namespace. See SlackAPI for additional methods.
module Users
  extend SlackAPI
  
  # skip disabled and bot users
  def self.clean_list
    self.list.select{|m| !m["deleted"] and !m["is_bot"] and m["name"]!="slackbot"}
  end

  ##
  # users.admin.setRegular method wrapper.
  #
  # Promote guest or disabled user to standard full user account.
  def self.setRegular(user)
    self.adminapicall("setRegular",user:user)
  end

  ##
  # users.admin.setRestricted method wrapper.
  #
  # Sets user as a guest.
  def self.setRestricted(user)
    self.adminapicall("setRestricted",user:user)
  end

  ##
  # users.admin.setUltraRestricted method wrapper.
  #
  # Sets user as a single channel guest. "channel:" field is required. This
  # method is an effective way of purging users from the main channel before 
  # banning them (with #detInactive). May also be an effective way of kicking
  # users from hidden groups (aka private channels).
  def self.setUltraRestricted(user, channel:)
    self.adminapicall("setUltraRestricted",user:user,channel:channel)
  end

  ##
  # users.admin.setInactive method wrapper.
  # 
  # Sets user deleted=true. This is the same as "disable" in the Slack GUI.
  # Following this method with #setRegular may cause user to show as "inactive".
  def self.setInactive(user)
    self.adminapicall("setInactive",user:user)
  end

  ##
  # users.admin.invite method wrapper
  def self.invite(email:, channel: nil, first_name: nil, last_name: nil, ultra_restricted: nil, restricted: nil)
    if (restricted and ultra_restricted)
      raise "Can't be both a standard and single-channel guest."
    end
    if (restricted or ultra_restricted)
      channel or raise "Guests must be assigned at least one channel."
    end
    options = {}
    first_name and options[:first_name]=first_name
    last_name  and options[:last_name] =last_name
    restricted and options[:restricted]=1
    ultra_restricted and options[:ultra_restricted]=1
    # sic
    channel and options[:channels]=channel
    self.adminapicall("invite",email:email,**options)
  end

  ##
  # get a UID from email address
  def self.email2id(email)
    self.list.select{|u| u["profile"]["email"]==email}.first["id"]
  end

  protected
  # dispatch support
  def self.name
    "users"
  end
  # dispatch support
  def self.list_item
    "members"
  end

  ##
  # Implimentation of *.admin.* namespace.
  #
  # Will move to SlackAPI module in future versions if other top level
  # namespaces require its use.
  def self.adminapicall(verb, **options)
    options.each_pair do |k,v|
      id = self.normalizeField(k,v)
      options[k] = id
    end
    self.apicall("admin.#{verb}",options)
  end
end

##
# Wrapper around Slack "search" API namespace.
module Search
  extend SlackAPI

  ##
  # Search messages.
  #
  # This is a stub, missing important features like paging.
  def self.messages(q)
    self.apicall("messages",query:q)
  end

  protected
  # dispatch support
  def self.name
    "search"
  end
end

##
# Wrapper around Slack "rtm" (real time messaging) API namespace.
module RTM
  extend SlackAPI

  ##
  # Open and RTM session.
  #
  # Only gets the setup json object, actually using it out of the scope of this
  # library.
  def self.start(simple_latest: true, no_unreads: true, mpim_aware: false)
    self.apicall("start",simple_latest: simple_latest, no_unreads: no_unreads, mpim_aware: mpim_aware)
  end

  protected
  # dispatch support
  def self.name
    "rtm"
  end
end
