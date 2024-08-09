#!/usr/bin/env zsh

set -xe

zsh -n "$0"

[[ "$1" == '-n' ]] && {
  RM=y
  shift ||:
  :
} || RM=

[[ "$1" == '-r' ]] && {
  RAW=y
  shift ||:
  :
} || RAW=

n="${1:-}"

[[ -n "$n" ]]

[[ -n "$RAW" ]] && {
  f=raw
  :
} || f=qcow2

d="disk-${n}.${f}"

[[ -n "$RM" ]] && {
  rm -f "$d" ||:
  :
} || {

  [[ -r "$d" ]] && exit 2
}

qemu-img create -f "$f" "$d" 10G

