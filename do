#!/bin/sh
# Does all the things
set -ex

TAG=$1
if [ -z "$TAG" ]; then
	echo "Usage: $0 BUSYBOX-TAG"
	exit 1
fi

wget http://musl.cc/x86_64-linux-musl-cross.tgz
tar xf x86_64-linux-musl-cross.tgz

export PATH="x86_64-linux-musl-cross/bin:$PATH"

git clone https://github.com/mirror/busybox
(cd busybox && git checkout "$TAG")

./build-cross.sh x86_64-linux-musl-
