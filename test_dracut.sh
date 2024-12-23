#!/usr/bin/bash

exit 3

set -xe

bash -n "$0"

s () {
  { echo -e "\n" ; } 2>/dev/null
}

n="$1"
[[ -n "$n" ]]
shift ||:

rm -f *.rpm

s

koji download-task --arch x86_64 $n

s

rm -f dracut-config-generic* dracut-debug* dracut-tools*

s

dnf reinstall -y *.rpm

s

dracut -v -f -H --kver="5.19.4-200.fc36.x86_64" "$@"

s

dracut -v -f -H --kver="5.19.4-200.fc36.x86_64" --uefi --hostonly-cmdline "$@"
