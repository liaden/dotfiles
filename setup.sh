#!/usr/bin/env bash

function win_setup() {
    echo 'Not Implemented'
}

function mac_setup() {
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  brew update && brew install bash

  ./setup/mac
}

function linux_setup() {
    ./setup/linux "$(realpath .)"
}

mkdir setup/log

case "$OSTYPE" in
  darwin*)  mac_setup ;;
  linux*)   linux_setup ;;
  msys*)    win_setup ;;
  *)        echo "unknown: $OSTYPE" ;;
esac

