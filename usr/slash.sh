#!/usr/bin/env bash

# -----------------
# Unique sourcing
# -----------------
## Here we make the first sourcing of source.lib to directly set source::unique available.
SLASH_SOURCED=${SLASH_SOURCED:-false}
if $SLASH_SOURCED; then
  return 0
else
  SLASH_SOURCED=true
  #source source.sh                                             || return 1 
  #source::unique decorator.sh
fi
