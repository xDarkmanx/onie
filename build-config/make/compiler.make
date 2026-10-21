#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines compiler and linker options
# for building the user space tools.
#
# Note: The kernel and u-boot do not use these options.
#

# Native build: compile and link against the build container's system
# gcc/glibc. No --sysroot indirection, no cross toolchain.
#
# Warning policy: warnings are errors, everywhere. Fix the code, do
# not silence the compiler.
export ONIE_CPPFLAGS	=
export ONIE_CFLAGS	= -Os -Wall -Wextra -Werror $(ONIE_CPPFLAGS)
export ONIE_CXXFLAGS	= -Os -Wall -Wextra -Werror $(ONIE_CPPFLAGS)
export ONIE_LDFLAGS	=

export ONIE_PKG_CONFIG	= \
	PKG_CONFIG_SYSROOT_DIR=/ \
	PKG_CONFIG_LIBDIR=/usr/lib/$(ARCH)-linux-gnu/pkgconfig

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
