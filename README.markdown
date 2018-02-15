# Speed Test Logger

[We](https://www.explo.org) wrote this utility to run as a CRON task within our network. It uses [speedtest-cli](https://github.com/sivel/speedtest-cli) to check the local network speed. This speed gets logged to a file (`log/speedtest.log`), and the utility will [hipchat](https://raw.githubusercontent.com/dmerand/dlm-dot-bin/master/hipchat) us if our speeds fall below a minimum threshold.

# Setup

1. Run `sh setup.sh`, which will create any necessary folders and download any necessary scripts.
2. Edit `bin/hipchat` to include your API keys, and room numbers etc.
3. There is no step 3. You can run `ruby run_tests.rb` or just `run_tests.rb` now.
