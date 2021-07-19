#!/usr/bin/env bash

for language in rust ruby bash css html dockerfile vim lua terraform yaml typescript; do
  nvim +silent -c "LspInstall $language" +qall
done
