#!/usr/bin/env bash

# dnf copr enable pvalena/dracut -y centos-stream-10-${a}
# dnf update 'dracut*' -y

set -ex

bash -n "$0"

# https://download.copr.fedorainfracloud.org/results/pvalena/dracut/centos-stream-10-${a}/07889142-dracut/dracut-caps-102-1.2.el10.${a}.rpm

: 'COPR build'
b="${1:-4536097}"

: 'dracut version+release'
v="${2:-102-1.1}"

: 'rhel version'
r="${3:-10}"

: '--------------------------'

a='x86_64'

o="centos-stream-${r}-${a}"

##

b="$(printf "%08d" $b)"

u="https://download.copr.fedorainfracloud.org/results/pvalena/dracut/${o}/${b}-dracut/"

s="-${v}.el${r}.${a}.rpm"

l="$(
  for p in \
    dracut  \
    dracut-config-rescue  \
    dracut-network  \
    dracut-squash
  do
    echo "${u}${p}${s}"

  done
)"

echo "$l"

dnf install --disablerepo='*' -y $l || echo $l | xargs -rn1 curl -sOLk
