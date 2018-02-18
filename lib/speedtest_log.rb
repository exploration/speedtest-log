# frozen_string_literal: true

require 'CSV'

# Run the `speedtest-cli` app, and manipulate + store the results in a logfile
# and an in-memory object.
class SpeedTestLog
  # Test results
  attr_reader :results
  # Check the initialize function for more information
  attr_accessor :attempts, :attempt_interval

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
  def initialize(**options)
    @attempts = options.fetch(:attempts, 2)
    @attempt_interval = options.fetch(:attempt_interval, 30)
    @logfile = options.fetch(:logfile, "#{dir}/log/speedtest.log")
    @results = []
  end

  # Checks that the speed test results are over the designated minimum values
  # @param variety [Symbol] :download or :upload
  # @param threshold [Integer] MB value for warning that there's an error
  # @return [Boolean] Did the test averages go below the minimum threshold?
  def check_minimum(variety, threshold)
    return :no_results if @results.empty?

    values = parse_results(:local, variety)
    average = mb_val(values.reduce(:+) / values.count)

    average > threshold ? average : false
  end

  # Append speedtest results to the log
  def log_speedtest
    append_cmd = proc { |f| @results.each { |r| f.puts r } }
    File.open(@logfile, 'a', &append_cmd) unless @log_append
    @log_append = true
  end

  # Actually run the speed test, and log the results both to an internal array,
  # and to the logfile.
  def run_speedtest
    @results = Array.new(@attempts).map do
      `'#{dir}/bin/speedtest-cli' --csv && sleep #{@attempt_interval}`
    end
  end

  # This will print out averages of download + upload speed
  # @param location [Symbol] :logfile or :local
  def stats(location = :local)
    VARIETIES.map do |variety, _index|
      values = parse_results(location, variety)
      average = values.reduce(:+) / values.count
      {
        variety: variety,
        average: mb_val(average),
        min: mb_val(values.min),
        max: mb_val(values.max)
      }
    end
  end

  # Return the stats in a more human-readable format
  def stats_printout(location = :local)
    stats(location).map do |stat|
      format "%s\naverage: %.2f Mb/sec\nmax: %.2f Mb/sec\n" \
             "min: %.2f Mb/sec\n",
             stat[:variety], stat[:average], stat[:min], stat[:max]
    end
  end

  private

  def dir
    File.join(File.dirname(__FILE__), '..')
  end

  def parse_results(location, variety)
    case location
    when :logfile
      CSV.read(@logfile)[1..-1].map { |a| a[VARIETIES[variety]].to_f }
    when :local
      if @results.empty?
        [0]
      else
        @results.map { |a| CSV.parse(a)[0][VARIETIES[variety]].to_f }
      end
    end
  end

  def mb_val(raw_value)
    mb_val = raw_value.to_f / 1_000_000
    (mb_val * 100).floor / 100.0
  end
end
