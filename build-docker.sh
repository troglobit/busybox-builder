#!/bin/sh
# This script is based on build-cross.sh from BusyBox, see comment in
# that file.  Like everything here it's released in the public domain.

make_defconfig()
{
	arch=$1

	test -d busybox || {
		echo "busybox/ does not exist or is not a directory"
		return 1
	}

	cd busybox/ || exit $?

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
	cd ..
}

mkdir -p output
make_defconfig $1 >BUILD.log 2>&1

if [ ! -x "busybox/busybox" ]; then
	echo "Failed building 'busybox' executable, check BUILD.log below:"
	cat BUILD.log
	exit 1
fi

cp -v "busybox/busybox" "../output/busybox-$arch"
cp -v "BUILD.log"       "../output/busybox-$arch.log"

exit 0
