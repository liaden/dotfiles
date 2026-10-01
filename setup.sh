#!/usr/bin/env bash

function win_setup() {
    echo 'Not Implemented'
}

function mac_setup() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon installs to /opt/homebrew, which is not on PATH yet.
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
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

