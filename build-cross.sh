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
	exec </dev/null 2>&1 | tee BUILD.log

	cp ../busybox_defconfig .config

	# Set cross-compiler
	sed 's/^CONFIG_CROSS_COMPILER_PREFIX=".*$/CONFIG_CROSS_COMPILER_PREFIX="'"$1"'"/' -i .config

	# Want static build
	sed 's/^.*CONFIG_STATIC.*$/CONFIG_STATIC=y/' -i .config

	# Without this, I get MIPS-I binary instead of MIPS32.
	# No idea what's the difference, but my router wants MIPS32.
	##sed 's/^.*CONFIG_EXTRA_CFLAGS.*$/CONFIG_EXTRA_CFLAGS="-mips32"/' -i .config

	# These won't build because of toolchain/libc breakage:
	##sed 's/^.*CONFIG_FEATURE_INETD_RPC.*$/# CONFIG_FEATURE_INETD_RPC is not set/' -i .config
	# no syncfs() on armv4l, sparc
	##sed 's/^.*CONFIG_FEATURE_SYNC_FANCY.*$/# CONFIG_FEATURE_SYNC_FANCY is not set/' -i .config
	# if namespace functions (unshare,setns) aren't in libc
	##sed 's/^.*CONFIG_NSENTER.*$/# CONFIG_NSENTER is not set/' -i .config
	##sed 's/^.*CONFIG_UNSHARE.*$/# CONFIG_UNSHARE is not set/' -i .config

	# https://wiki.musl-libc.org/building-busybox.html
	sed 's/^.*\(CONFIG_EXTRA_COMPAT\).*$/# \1 is not set/' -i .config
	sed 's/^.*\(CONFIG_SELINUX\).*$/# \1 is not set/' -i .config
	sed 's/^.*\(CONFIG_FEATURE_HAVE_RPC\).*$/# \1 is not set/' -i .config
	sed 's/^.*\(CONFIG_WERROR\).*$/# \1 is not set/' -i .config
	sed 's/^.*\(CONFIG_FEATURE_SYSTEMD\).*$/# \1 is not set/' -i .config
	sed 's/^.*\(CONFIG_FEATURE_VI_REGEX_SEARCH\).*$/# \1 is not set/' -i .config
	sed 's/^.*\(CONFIG_PAM\).*$/# \1 is not set/' -i .config
	sed 's/^.*\(CONFIG_FEATURE_INETD_RPC\).*$/# \1 is not set/' -i .config
	sed 's/^.*\(CONFIG_SELINUXENABLED\).*$/# \1 is not set/' -i .config
	sed 's/^.*\(CONFIG_FEATURE_MOUNT_NFS\).*$/# \1 is not set/' -i .config

	# Citing Buildroot: "The correct way to regenerate a .config
	#   file is to use 'make olddefconfig'.  For historical reasons,
	#   the target name is 'oldnoconfig' between Linux kernel
	#   versions 2.6.36 and 3.6, and remains as an alias in later
	#   versions.  In older versions, and in some other projects
	#   that use kconfig, the target is not supported at all, and we
	#   use 'yes "" | make oldconfig' as a fallback only, as this
	#   can fail in complex cases."
        make olddefconfig || make oldnoconfig || yes "" | make oldconfig
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
	ls -lrt "$bb"
	test -x "$bb/busybox" || {
		echo "Directory $bb has no 'busybox' executable, check BUILD.log"
		continue
	}
	arch="${bb#busybox-}"
	arch="${arch%%-*}"
	cp -v "$bb/busybox"   "output/busybox-$arch"
	cp -v "$bb/BUILD.log" "output/busybox-$arch.log"
	cd output/ || exit 1
	sha256sum "busybox-$arch" > "busybox-${arch}.sha256"
done
