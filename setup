#!/usr/bin/env sh
set -eu

chmod +x speedtest

if [ ! -d bin ]; then
  mkdir bin
fi
if [ ! -d log ]; then
  mkdir log
fi

if [ ! -e 'bin/speedtest-cli' ]; then
  printf "\n%s\n" "downloading speedtest-cli..."
  wget -O bin/speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
  chmod +x bin/speedtest-cli
fi

if [ ! -e 'bin/hipchat' ]; then
  printf "\n%s\n" "downloading hipchat utility..."
  wget -O bin/hipchat https://raw.githubusercontent.com/dmerand/dlm-dot-bin/master/hipchat
  chmod +x bin/hipchat
  printf "%s\n" "NOTE: you'll want to edit bin/hipchat to set up API values"
fi

if [ ! -e 'log/speedtest.log' ]; then
  bin/speedtest-cli --csv-header > 'log/speedtest.log'
  printf "\n%s\n" "log/speedtest.log created"
fi
