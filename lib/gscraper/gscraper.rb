#
#--
# GScraper - A web-scraping interface to various Google Services.
#
# Copyright (c) 2007-2009 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#++
#

require 'uri/http'
require 'mechanize'
require 'nokogiri'
require 'open-uri'

module GScraper
  # Common proxy port.
  COMMON_PROXY_PORT = 8080

  #
  # Returns the +Hash+ of proxy information.
  #
  def GScraper.proxy
    @@gscraper_proxy ||= {:host => nil, :port => COMMON_PROXY_PORT, :user => nil, :password => nil}
  end

  #
  # Creates a HTTP URI based from the given _proxy_info_ hash. The
  # _proxy_info_ hash defaults to Web.proxy, if not given.
  #
  # _proxy_info_ may contain the following keys:
  # <tt>:host</tt>:: The proxy host.
  # <tt>:port</tt>:: The proxy port. Defaults to COMMON_PROXY_PORT,
  #                  if not specified.
  # <tt>:user</tt>:: The user-name to login as.
  # <tt>:password</tt>:: The password to login with.
  #
  def GScraper.proxy_uri(proxy_info=GScraper.proxy)
    if GScraper.proxy[:host]
      return URI::HTTP.build(
        :host => GScraper.proxy[:host],
        :port => GScraper.proxy[:port],
        :userinfo => "#{GScraper.proxy[:user]}:#{GScraper.proxy[:password]}",
        :path => '/'
      )
    end
  end
  
  #
  # Returns the supported GScraper User-Agent Aliases.
  #
  def GScraper.user_agent_aliases
    Mechanize::AGENT_ALIASES
  end

  #
  # Returns the GScraper User-Agent
  #
  def GScraper.user_agent
    @@gscraper_user_agent ||= GScraper.user_agent_aliases['Windows IE 6']
  end

  #
  # Sets the GScraper User-Agent to the specified _agent_.
  #
  def GScraper.user_agent=(agent)
    @@gscraper_user_agent = agent
  end

  #
  # Sets the GScraper User-Agent using the specified user-agent alias
  # _name_.
  # 
  def GScraper.user_agent_alias=(name)
    @@gscraper_user_agent = GScraper.user_agent_aliases[name.to_s]
  end

  #
  # Opens the _uri_ with the given _options_. The contents of the _uri_
  # will be returned.
  #
  # _options_ may contain the following keys:
  # <tt>:user_agent_alias</tt>:: The User-Agent Alias to use.
  # <tt>:user_agent</tt>:: The User-Agent String to use.
  # <tt>:proxy</tt>:: A +Hash+ of proxy information which may
  #                   contain the following keys:
  #                   <tt>:host</tt>:: The proxy host.
  #                   <tt>:port</tt>:: The proxy port.
  #                   <tt>:user</tt>:: The user-name to login as.
  #                   <tt>:password</tt>:: The password to login with.
  #
  #   GScraper.open_uri('http://www.hackety.org/')
  #
  #   GScraper.open_uri('http://tenderlovemaking.com/',
  #     :user_agent_alias => 'Linux Mozilla')
  #   GScraper.open_uri('http://www.wired.com/',
  #     :user_agent => 'the future')
  #
  def GScraper.open_uri(uri,options={})
    headers = {}

    if options[:user_agent_alias]
      headers['User-Agent'] = Mechanize::AGENT_ALIASES[options[:user_agent_alias]]
    elsif options[:user_agent]
      headers['User-Agent'] = options[:user_agent]
    elsif GScraper.user_agent
      headers['User-Agent'] = GScraper.user_agent
    end

    proxy = (options[:proxy] || GScraper.proxy)
    if proxy[:host]
      headers[:proxy] = GScraper.proxy_uri(proxy)
    end

    return Kernel.open(uri,headers)
  end

  #
  # Similar to GScraper.open_uri but returns a Nokogiri::HTML document.
  #
  def GScraper.open_page(uri,options={})
    Nokogiri::HTML(GScraper.open_uri(uri,options))
  end

  #
  # Creates a new Mechanize agent with the given _options_.
  #
  # _options_ may contain the following keys:
  # <tt>:user_agent_alias</tt>:: The User-Agent Alias to use.
  # <tt>:user_agent</tt>:: The User-Agent string to use.
  # <tt>:proxy</tt>:: A +Hash+ of proxy information which may
  #                   contain the following keys:
  #                   <tt>:host</tt>:: The proxy host.
  #                   <tt>:port</tt>:: The proxy port.
  #                   <tt>:user</tt>:: The user-name to login as.
  #                   <tt>:password</tt>:: The password to login with.
  #
  #   GScraper.web_agent
  #
  #   GScraper.web_agent(:user_agent_alias => 'Linux Mozilla')
  #   GScraper.web_agent(:user_agent => 'Google Bot')
  #
  def GScraper.web_agent(options={},&block)
    agent = Mechanize.new

    if options[:user_agent_alias]
      agent.user_agent_alias = options[:user_agent_alias]
    elsif options[:user_agent]
      agent.user_agent = options[:user_agent]
    elsif GScraper.user_agent
      agent.user_agent = GScraper.user_agent
    end

    proxy = (options[:proxy] || GScraper.proxy)
    if proxy[:host]
      agent.set_proxy(proxy[:host],proxy[:port],proxy[:user],proxy[:password])
    end

    block.call(agent) if block
    return agent
  end
end
