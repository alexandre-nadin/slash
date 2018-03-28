#!/usr/bin/env bash

grep --color -R "^source" "$1" | cut -d':' -f2 | sed 's/^source//g'

