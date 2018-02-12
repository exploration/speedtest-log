#!/usr/bin/env ruby
# frozen_string_literal: true

require 'CSV'

def dir
  File.dirname(__FILE__)
end

DOWNLOAD_MINIMUM_MB = 40
UPLOAD_MINIMUM_MB = 20
LOGFILE = "#{dir}/log/speedtest.log"
NOTIFY_USERNAMES = %w[Eric Donald].freeze

results = `#{dir}/bin/speedtest-cli --csv`
File.open(LOGFILE, 'a') { |f| f.puts results }

def check_minimum(variety, raw_value, threshold)
  users = NOTIFY_USERNAMES.map { |r| "@#{r}" }.join(' ')

  mb_value = raw_value.to_f / 1_000_000
  value = (mb_value * 100).floor / 100.0

  msg = "Warning - #{variety} speed of #{value}Mb/sec is under the " \
        "minimum threshold of #{threshold}."

  puts msg if value < threshold
  `#{dir}/bin/hipchat "#{users} #{msg}"` if value < threshold
end

# CSV format is:
# Server ID,Sponsor,Server Name,
#   Timestamp,Distance,Ping,Download,Upload,Share,IP Address
values = CSV.parse(results)[0]

check_minimum 'download', values[6], DOWNLOAD_MINIMUM_MB
check_minimum 'upload', values[7], UPLOAD_MINIMUM_MB
