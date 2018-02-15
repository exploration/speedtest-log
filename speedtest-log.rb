#!/usr/bin/env ruby
# frozen_string_literal: true

require 'CSV'

def dir
  File.dirname(__FILE__)
end

DOWNLOAD_MINIMUM_MB = 40
UPLOAD_MINIMUM_MB = 20

# How many speed test attempts should we be averaging together?
ATTEMPTS = 2
LOGFILE = "#{dir}/log/speedtest.log"
# These are chat service short-handles (eg HipChat)
NOTIFY_USERNAMES = %w[Eric Donald].freeze

def mb_value(raw_value)
  mb_value = raw_value.to_f / 1_000_000
  (mb_value * 100).floor / 100.0
end

def check_minimum(variety, results, index, threshold)
  values = results.map { |a| mb_value(CSV.parse(a)[0][index]) }
  value = values.reduce(:+) / ATTEMPTS

  msg = "Warning - #{variety} speed of #{value}Mb/sec is under the " \
        "minimum threshold of #{threshold}."
  puts msg if value < threshold

  users = NOTIFY_USERNAMES.map { |r| "@#{r}" }.join(' ')
  `#{dir}/bin/hipchat "#{users} #{msg}"` if value < threshold
end

# ---- ACTUAL WORK HERE ---- #

# Note that we wait 30 seconds between each test
results =
  Array.new(ATTEMPTS).map { `#{dir}/bin/speedtest-cli --csv && sleep 30` }
results.each { |r| File.open(LOGFILE, 'a') { |f| f.puts r } }

# CSV format is:
# Server ID,Sponsor,Server Name,
#   Timestamp,Distance,Ping,Download,Upload,Share,IP Address
check_minimum 'download', results, 6, DOWNLOAD_MINIMUM_MB
check_minimum 'upload', results, 7, UPLOAD_MINIMUM_MB
