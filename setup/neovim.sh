#!/usr/bin/env bash

nvim +silent +'PlugInstall --sync' +qall &> /dev/null < /dev/tty
nvim +silent +'CocInstall coc-json coc-solargraph coc-rust-analyzer' +qall &> /dev/null < /dev/tty

