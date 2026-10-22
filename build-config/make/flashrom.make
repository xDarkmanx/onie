#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of flashrom
#

FLASHROM_VERSION		= 1.7.0
FLASHROM_TARBALL		= flashrom-v$(FLASHROM_VERSION).tar.xz
FLASHROM_TARBALL_URLS		+= $(ONIE_MIRROR) \
				   https://download.flashrom.org/releases/flashrom-v$(FLASHROM_VERSION).tar.xz
FLASHROM_BUILD_DIR		= $(USER_BUILDDIR)/flashrom
FLASHROM_DIR			= $(FLASHROM_BUILD_DIR)/flashrom-v$(FLASHROM_VERSION)

FLASHROM_SRCPATCHDIR		= $(PATCHDIR)/flashrom
FLASHROM_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/flashrom-download
FLASHROM_SOURCE_STAMP		= $(USER_STAMPDIR)/flashrom-source
FLASHROM_PATCH_STAMP		= $(USER_STAMPDIR)/flashrom-patch
FLASHROM_BUILD_STAMP		= $(USER_STAMPDIR)/flashrom-build
FLASHROM_INSTALL_STAMP		= $(STAMPDIR)/flashrom-install
FLASHROM_STAMP			= $(FLASHROM_SOURCE_STAMP) \
				  $(FLASHROM_PATCH_STAMP) \
				  $(FLASHROM_BUILD_STAMP) \
				  $(FLASHROM_INSTALL_STAMP)

FLASHROM_PROGRAMS		= flashrom

PHONY += flashrom flashrom-download flashrom-source flashrom-patch flashrom-build \
	 flashrom-install flashrom-clean flashrom-download-clean

flashrom: $(FLASHROM_STAMP)

DOWNLOAD += $(FLASHROM_DOWNLOAD_STAMP)
flashrom-download: $(FLASHROM_DOWNLOAD_STAMP)
$(FLASHROM_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream flashrom ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(FLASHROM_TARBALL) $(FLASHROM_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(FLASHROM_SOURCE_STAMP)
flashrom-source: $(FLASHROM_SOURCE_STAMP)
$(FLASHROM_SOURCE_STAMP): $(USER_TREE_STAMP) $(FLASHROM_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream flashrom ===="
	$(Q) $(SCRIPTDIR)/extract-package $(FLASHROM_BUILD_DIR) $(DOWNLOADDIR)/$(FLASHROM_TARBALL)
	$(Q) touch $@

PATCH += $(FLASHROM_PATCH_STAMP)
flashrom-patch: $(FLASHROM_PATCH_STAMP)
$(FLASHROM_PATCH_STAMP): $(FLASHROM_SOURCE_STAMP) $(FLASHROM_SRCPATCHDIR)/series
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching flashrom ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(FLASHROM_SRCPATCHDIR)/series $(FLASHROM_DIR)
	$(Q) touch $@

# flashrom 1.x builds with meson. Only the 'internal' programmers are
# enabled by default, plus the Intel NIC EEPROM programmers, which
# could be useful in manufacturing to program the MAC address for eth0.
# Individual platforms can extend FLASHROM_MESON_EXTRA_OPTS, e.g.
#
#   FLASHROM_MESON_EXTRA_OPTS = -Dprogrammer=internal,nicintel,dummy
#
FLASHROM_MESON_OPTS = \
	-Dprogrammer=internal,nicintel,nicintel_eeprom,nicintel_spi \
	-Dclassic_cli=enabled -Dtests=disabled -Ddocumentation=disabled \
	-Dman-pages=disabled -Dich_descriptors_tool=disabled \
	-Dbash_completion=disabled -Duse_git_version=disabled \
	--buildtype plain \
	-Dc_args='$(ONIE_CFLAGS)' -Dc_link_args='$(ONIE_LDFLAGS)' \
	$(FLASHROM_MESON_EXTRA_OPTS)

flashrom-build: $(FLASHROM_BUILD_STAMP)
$(FLASHROM_BUILD_STAMP): $(FLASHROM_SOURCE_STAMP) $(PCIUTILS_BUILD_STAMP) \
				| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building flashrom-$(FLASHROM_VERSION) ===="
	$(Q) cd $(FLASHROM_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		PKG_CONFIG_PATH=$(DEV_SYSROOT)/usr/lib/pkgconfig	\
		PKG_CONFIG_SYSROOT_DIR=$(DEV_SYSROOT)		\
		meson setup buildd --prefix=/usr $(FLASHROM_MESON_OPTS)
	$(Q) PATH='$(CROSSBIN):$(PATH)'	\
		PKG_CONFIG_PATH=$(DEV_SYSROOT)/usr/lib/pkgconfig	\
		PKG_CONFIG_SYSROOT_DIR=$(DEV_SYSROOT)		\
		ninja -C $(FLASHROM_DIR)/buildd
	$(Q) PATH='$(CROSSBIN):$(PATH)'	meson install -C $(FLASHROM_DIR)/buildd \
		--destdir $(DEV_SYSROOT)
	$(Q) touch $@

flashrom-install: $(FLASHROM_INSTALL_STAMP)
$(FLASHROM_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(FLASHROM_BUILD_STAMP) $(PCIUTILS_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing flashrom programs in $(SYSROOTDIR) ===="
	$(Q) for file in $(FLASHROM_PROGRAMS); do \
		cp -av --remove-destination $(DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin ; \
	     done
	$(Q) for lib in $(wildcard $(DEV_SYSROOT)/usr/lib/*/libflashrom.so*); do \
		cp -av --remove-destination $$lib $(SYSROOTDIR)/usr/lib ; \
	     done
	$(Q) touch $@

USER_CLEAN += flashrom-clean
flashrom-clean:
	$(Q) rm -rf $(FLASHROM_BUILD_DIR)
	$(Q) rm -f $(FLASHROM_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += flashrom-download-clean
flashrom-download-clean:
	$(Q) rm -f $(FLASHROM_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(FLASHROM_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
