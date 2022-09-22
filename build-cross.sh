#!/bin/sh
# This script was downloaded from the binaries directory for 1.31.0 at
# https://busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/
# there was no licensed attached so I'm assuming it's released in the
# public domain.

make_defconfig()
{
	test -d busybox || {
		echo "busybox/ does not exist or is not a directory"
		return 1
	}
	command -v "${1}cc" || {
		echo "${1}cc is not available"
		return 1
	}

	cp -a busybox busybox-"$1" || exit $?

	# Go backgorund
	(
	cd busybox-"$1" || exit $?
	exec </dev/null >BUILD.log 2>&1

	make defconfig >/dev/null || {
		make defconfig # no redirects, to see all messages in log
		exit 1
	}

	# Set cross-compiler
	sed 's/^CONFIG_CROSS_COMPILER_PREFIX=".*$/CONFIG_CROSS_COMPILER_PREFIX="'"$1"'"/' -i .config

	# Want static build
	sed 's/^.*CONFIG_STATIC.*$/CONFIG_STATIC=y/' -i .config

	# Without this, I get MIPS-I binary instead of MIPS32.
	# No idea what's the difference, but my router wants MIPS32.
	##sed 's/^.*CONFIG_EXTRA_CFLAGS.*$/CONFIG_EXTRA_CFLAGS="-mips32"/' -i .config

	sed 's/^.*CONFIG_FEATURE_MOUNT_HELPERS.*$/CONFIG_FEATURE_MOUNT_HELPERS=y/' -i .config

	# These won't build because of toolchain/libc breakage:
	##sed 's/^.*CONFIG_FEATURE_INETD_RPC.*$/# CONFIG_FEATURE_INETD_RPC is not set/' -i .config
	# no syncfs() on armv4l, sparc
	##sed 's/^.*CONFIG_FEATURE_SYNC_FANCY.*$/# CONFIG_FEATURE_SYNC_FANCY is not set/' -i .config
	# if namespace functions (unshare,setns) aren't in libc
	##sed 's/^.*CONFIG_NSENTER.*$/# CONFIG_NSENTER is not set/' -i .config
	##sed 's/^.*CONFIG_UNSHARE.*$/# CONFIG_UNSHARE is not set/' -i .config

	make oldconfig
	cat .config

	make #V=1 || sh
	) &
}

test "$*" || set -- \
	armv5l-linux-musleabihf- \
	armv7l-linux-musleabihf- \
	armv7m-linux-musleabi- \
	armv7r-linux-musleabihf- \
	armv8l-linux-musleabihf- \
	i486-linux-musl- \
	i686-linux-musl- \
	microblaze-linux-musl- \
	mips64-linux-musl- \
	mipsel-linux-musl- \
	mips-linux-musl- \
	powerpc64-linux-musl- \
	powerpc-linux-musl- \
	s390x-linux-musl- \
	sh2eb-linux-muslfdpic- \
	sh4-linux-musl- \
	x86_64-linux-musl- \

for cross; do
	make_defconfig "$cross" 2>&1
done
wait

mkdir -p output
for bb in busybox-*; do
	test -d "$bb" || continue
	test "$bb" = "busybox" && continue
	test -x "$bb/busybox" || {
		echo "Directory $bb has no 'busybox' executable, check BUILD.log"
		continue
	}
	arch="${bb#busybox-}"
	arch="${arch%%-*}"
	cp -v "$bb/busybox"   "output/busybox-$arch"
	cp -v "$bb/BUILD.log" "output/busybox-$arch.log"
done
