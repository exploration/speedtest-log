#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/speedtest_log'

DOWNLOAD_MINIMUM_MB = 40
UPLOAD_MINIMUM_MB = 20

stl = SpeedTestLog.new

if ARGV[0] == '--stats'
  stl.print_stats :logfile
  exit
end

stl.run_speedtest

stl.print_stats :local
stl.check_minimum :download, DOWNLOAD_MINIMUM_MB
stl.check_minimum :upload, UPLOAD_MINIMUM_MB
