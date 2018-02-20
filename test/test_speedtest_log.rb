# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/speedtest_log'

class TestSpeedTestLog < MiniTest::Test
  def setup
    clear_logfile
  end

  def teardown
    clear_logfile
  end

  def test_param_passing
    speed_logger = SpeedTestLog.new(
      attempts: 3,
      attempt_interval: 10
    )
    assert_equal 3, speed_logger.attempts
    assert_equal 10, speed_logger.attempt_interval
    assert_empty speed_logger.results
  end

  def test_check_no_results_on_empty_results
    speed_logger = SpeedTestLog.new
    dl_check = speed_logger.check_minimum(:download, 1)
    assert_equal :no_results, dl_check
  end

  def test_check_minimum_download
    refute stl.check_minimum(:download, 1000)
    assert stl.check_minimum(:download, 5)
    assert_equal stl.check_minimum(:download, 5), 110.29
  end

  def test_check_minimum_upload
    refute stl.check_minimum(:upload, 1000)
    assert stl.check_minimum(:upload, 5)
    assert_equal stl.check_minimum(:upload, 5), 73.34
  end

  def test_local_stats
    expected_stats = [
      { variety: :download, average: 110.29, min: 104.02, max: 116.57 },
      { variety: :upload, average: 73.34, min: 73.05, max: 73.63 }
    ]
    assert_equal expected_stats, stl.stats(:local)
  end

  def test_local_stats_printout
    expected_stats = [
      "download\naverage: 110.29 Mb/sec\nmax: 116.57 Mb/sec\n" \
        "min: 104.02 Mb/sec\n",
      "upload\naverage: 73.34 Mb/sec\nmax: 73.63 Mb/sec\nmin: 73.05 Mb/sec\n"
    ]
    assert_equal expected_stats, stl.stats_printout(:local)
  end

  def test_log_speedtest
    refute File.exist?(logfile)

    stl.log_speedtest
    assert File.exist?(logfile)

    refute_empty File.read(logfile)
  end

  def test_log_speedtest_twice_does_not_dupe_write
    speed_logger = stl
    speed_logger.log_speedtest
    initial_contents = File.read(logfile)
    speed_logger.log_speedtest

    assert_equal initial_contents, File.read(logfile)
  end

  def clear_logfile
    File.delete(logfile) if File.exist?(logfile)
  end

  def logfile
    '/tmp/speedtest_log_test.log'
  end

  # rubocop:disable Metrics/MethodLength
  def stl(**options)
    test_options = {
      logfile: logfile
    }.merge(options)

    _fake_results = [
      '13429,"Starry, Inc.","Boston, MA",2018-02-17T01:39:45.635670Z' \
      ',4.6833942951256855,11.644,116570392.9570789,73639233.01446815,,' \
      "108.49.177.89\n",
      '13429,"Starry, Inc.","Boston, MA",2018-02-17T01:40:38.780967Z,' \
      '4.6833942951256855,19.065,104020397.60698155,73059630.19414869,,' \
      "108.49.177.89\n"
    ]

    stl = SpeedTestLog.new(test_options)
    stl.instance_eval('@results = _fake_results', __FILE__, __LINE__)

    stl
  end
  # rubocop:enable Metrics/MethodLength
end
