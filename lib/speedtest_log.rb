# frozen_string_literal: true

require 'CSV'

# Run the `speedtest-cli` app, and manipulate + store the results in a logfile
# and an in-memory object.
class SpeedTestLog
  # Test results
  attr_reader :results
  # Check the initialize function for more information
  attr_accessor :attempts, :attempt_interval, :notify, :notify_usernames

  # These are indexes in the CSV hash returned from `speedtest-cli` that
  # correspond to the `download` and `upload` entries.
  # CSV format is:
  #   Server ID, Sponsor, Server Name, Timestamp, Distance, Ping,
  #   Download, Upload, Share, IP Address
  VARIETIES = { download: 6, upload: 7 }.freeze

  # @param [Hash] options Some configuration options
  # @option options [Integer] :attempts How many tests should we run?
  # @option options [Integer] :attempts_interval Seconds between test runs
  # @option options [String] :logfile Location of log file
  # @option options [Boolean] :notify Should we send notifications via HipChat?
  # @option options [Array String] :notify_usernames List of HipChat users to
  #   notify.
  def initialize(**options)
    @attempts = options.fetch(:attempts, 2)
    @attempt_interval = options.fetch(:attempt_interval, 30)
    @logfile = options.fetch(:logfile, "#{dir}/log/speedtest.log")
    @notify = options.fetch(:notify, true)
    @notify_usernames = options.fetch(:notify_usernames, %w[Eric Donald])
    @results = []
  end

  # Checks that the speed test results are over the designated minimum values
  # @param variety [Symbol] :download or :upload
  # @param threshold [Integer] MB value for warning that there's an error
  def check_minimum(variety, threshold)
    return if @results.empty?

    values = @results.map { |a| mb_value(CSV.parse(a)[0][VARIETIES[variety]]) }
    value = values.reduce(:+) / @attempts

    msg = "Warning - #{variety} speed of #{value} Mb/sec is under the " \
          "minimum threshold of #{threshold}."
    puts msg if value < threshold

    users = @notify_usernames.map { |r| "@#{r}" }.join(' ')
    `#{dir}/bin/hipchat "#{users} #{msg}"` if @notify && value < threshold
  end

  # This will print out averages of download + upload speed
  # @param location [Symbol] :logfile or :local
  def print_stats(location = :logfile)
    VARIETIES.each do |name, index|
      items =
        case location
        when :logfile
          CSV.read(@logfile)[1..-1].map { |a| a[index].to_f }
        when :local
          if @results.empty?
            [0]
          else
            @results.map { |a| CSV.parse(a)[0][index].to_f }
          end
        end
      item_average = items.reduce { |a, b| a + b } / items.count
      puts "#{name} average: #{mb_value(item_average)} Mb/sec"
    end
  end

  # Actually run the speed test, and log the results both to an internal array,
  # and to the logfile.
  def run_speedtest
    @results = Array.new(@attempts).map do
      `#{dir}/bin/speedtest-cli --csv && sleep #{@attempt_interval}`
    end
    @results.each { |r| File.open(@logfile, 'a') { |f| f.puts r } }
  end

  private

  def dir
    File.join(File.dirname(__FILE__), '..')
  end

  def mb_value(raw_value)
    mb_value = raw_value.to_f / 1_000_000
    (mb_value * 100).floor / 100.0
  end
end
