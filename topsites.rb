#!/usr/bin/env ruby

#
# Pull report of Alexa Top Sites and spit out a CSV
#
# You must setup AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY env vars
# Windows instructions: http://www.itechtalk.com/thread3595.html
#
# Author: Nate Wiger
# Github: https://github.com/nateware/alexa
# Created: July 31, 2013
#

#-------- BEGIN CONFIGURATION ---------
#
# Which country codes we care about
#
# USA - us
# Australia - au
# Brazil -  br
# Canada - ca
# China - cn
# India - in
# Japan - jp
COUNTRIES = %w[ us au br ca cn in jp ]

#
# Number of sites to return
# Currently Alexa seems to be server-limited at 100
#
NUMBER = 1000

#
#-------- END CONFIGURATION -----------


# Code from here down
require "cgi"
require "base64"
require "openssl"
require "digest/sha1"
require "uri"
require "net/https"
require 'rexml/document'
require 'rexml/xpath'
require "time"
require 'optparse'
require 'csv'


class TopSites
  SERVICE_HOST  = "ats.amazonaws.com"
  COUNT_PER_SET = 100 # Alexa max

  def initialize(options)
    @count     = options[:count] || NUMBER
    @start     = options[:start] || 1
    @countries = options[:countries] || COUNTRIES.join(',')

    # These must be Windows or Linux environment variables (security)
    @access_key_id     = ENV['AWS_ACCESS_KEY_ID']     || raise("Missing AWS_ACCESS_KEY_ID environment variable")
    @secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || raise("Missing AWS_SECRET_ACCESS_KEY environment variable")
  end

  # Do it
  def pull_reports!
    puts
    puts '=' * 70
    puts "  Generating reports of Top #{@count} sites for: #{@countries}"
    puts '=' * 70
    puts

    @countries.split(/\s*,\s*/).each do |country|
      pull_report(country)
    end

    puts
    puts '=' * 70
    puts "  All reports done."
    puts '=' * 70
    puts
  end

  def pull_report(country)
    @file = "alexa_top#{@count}_#{country}.csv"
    @csv  = CSV.open(@file, 'w')
    @csv << ['rank','site','country']

    # figure out how many fetches we need to do
    n = @count / COUNT_PER_SET
    n.times do |i|
      start = i * COUNT_PER_SET + 1
      pull_report_range(country, start)
    end

    # close CSV
    @csv.close

    puts "  * Wrote top #{@count} #{country} sites to: #{@file}"
  end

  def pull_report_range(country, start)
    timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")

    action = "TopSites"
    responseGroup = "Country"

    query = {
      "Action"           => action,
      "AWSAccessKeyId"   => @access_key_id,
      "Timestamp"        => timestamp,
      "ResponseGroup"    => responseGroup,
      "CountryCode"      => country,
      "Start"            => start,
      "Count"            => COUNT_PER_SET,
      "SignatureVersion" => 2,
      "SignatureMethod"  => "HmacSHA1"
    }

    # Manual request signing
    query_str = query.sort.map{|k,v| k + "=" + escapeRFC3986(v.to_s())}.join('&')
    sign_str  = "GET\n" + SERVICE_HOST + "\n/\n" + query_str 

    debug "String to sign:"
    debug sign_str

    signature = OpenSSL::HMAC.digest( OpenSSL::Digest::Digest.new("sha1"), 
                                      @secret_access_key, sign_str )
    query_str += "&Signature=" + escapeRFC3986(Base64.encode64(signature).strip)

    url = URI.parse("http://" + SERVICE_HOST + "/?" + query_str)

    debug
    debug '=' * 20
    debug "Request: #{url}"

    xml = REXML::Document.new(Net::HTTP.get(url))

    xml.elements.each("//aws:Site") do |el|
      url  = el.elements.to_a("aws:DataUrl").first.text
      rank = el.elements.to_a("aws:Country/aws:Rank").first.text
      @csv << [rank, url, country]
    end
  end

  private

  def debug(string='')
    puts string if ENV['DEBUG']
  end

  # escape str to RFC 3986
  def escapeRFC3986(str)
    return URI.escape(str,/[^A-Za-z0-9\-_.~]/)
  end
end


# Parse options and run command
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-n COUNT", Integer, "Number of records") do |v|
    options[:count] = v
  end
  opts.on("-s START", Integer, "Start record") do |v|
    options[:start] = v
  end
  opts.on("-c COUNTRY", String, "Country code") do |v|
    options[:countries] = v
  end
end.parse!

ts = TopSites.new(options)
ts.pull_reports!

