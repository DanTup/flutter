#!/bin/bash
set -ex

function retry {
  local total_tries=$1
  local remaining_tries=$total_tries
  shift
  while [ $remaining_tries -gt 0 ]; do
    "$@" && break
    remaining_tries=$(($remaining_tries - 1))
    sleep 5
  done

  [ $remaining_tries -eq 0 ] && {
    echo "Command still failed after $total_tries tries: $@"
    return 1
  }
  return 0
}
