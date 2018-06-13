#!/usr/bin/env bash

# Checks if a command exists.
type -P "$@" &> /dev/null
