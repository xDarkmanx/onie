#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of mtdutils
#

MTDUTILS_VERSION	= 2.3.1
MTDUTILS_TARBALL	= mtd-utils-$(MTDUTILS_VERSION).tar.bz2
MTDUTILS_TARBALL_URLS	+= $(ONIE_MIRROR) https://infraroot.at/pub/mtd
MTDUTILS_BUILD_DIR	= $(USER_BUILDDIR)/mtd-utils
MTDUTILS_DIR		= $(MTDUTILS_BUILD_DIR)/mtd-utils-$(MTDUTILS_VERSION)

MTDUTILS_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/mtdutils-$(MTDUTILS_VERSION)-download
MTDUTILS_SOURCE_STAMP	= $(USER_STAMPDIR)/mtdutils-source
MTDUTILS_PATCH_STAMP	= $(USER_STAMPDIR)/mtdutils-patch
MTDUTILS_CONFIGURE_STAMP	= $(USER_STAMPDIR)/mtdutils-configure
MTDUTILS_BUILD_STAMP	= $(USER_STAMPDIR)/mtdutils-build
MTDUTILS_INSTALL_STAMP	= $(STAMPDIR)/mtdutils-install
MTDUTILS_STAMP		= $(MTDUTILS_SOURCE_STAMP) \
			  $(MTDUTILS_PATCH_STAMP) \
			  $(MTDUTILS_CONFIGURE_STAMP) \
			  $(MTDUTILS_BUILD_STAMP) \
			  $(MTDUTILS_INSTALL_STAMP)

MTDUTILS_SRCPATCHDIR	= $(PATCHDIR)/mtdutils
MTDBINS = mkfs.jffs2 mkfs.ubifs ubinize ubiformat ubinfo mtdinfo 
UBIBINS = ubiattach ubimkvol ubidetach ubirmvol

PHONY += mtdutils mtdutils-download mtdutils-source mtdutils-patch mtdutils-configure \
	 mtdutils-build mtdutils-install mtdutils-clean mtdutils-download-clean

mtdutils: $(MTDUTILS_STAMP)

DOWNLOAD += $(MTDUTILS_DOWNLOAD_STAMP)
mtdutils-download: $(MTDUTILS_DOWNLOAD_STAMP)
$(MTDUTILS_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream mtdutils ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(MTDUTILS_TARBALL) $(MTDUTILS_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(MTDUTILS_SOURCE_STAMP)
mtdutils-source: $(MTDUTILS_SOURCE_STAMP)
$(MTDUTILS_SOURCE_STAMP): $(USER_TREE_STAMP) | $(MTDUTILS_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream mtdutils ===="
	$(Q) $(SCRIPTDIR)/extract-package $(MTDUTILS_BUILD_DIR) $(DOWNLOADDIR)/$(MTDUTILS_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
MTDUTILS_NEW_FILES = $(shell test -d $(MTDUTILS_DIR) && test -f $(MTDUTILS_BUILD_STAMP) && \
	              find -L $(MTDUTILS_DIR) -newer $(MTDUTILS_BUILD_STAMP) -type f -print -quit)
endif

mtdutils-patch: $(MTDUTILS_PATCH_STAMP)
$(MTDUTILS_PATCH_STAMP): $(MTDUTILS_SRCPATCHDIR)/* $(MTDUTILS_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching mtd-utils ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(MTDUTILS_SRCPATCHDIR)/series $(MTDUTILS_DIR)
	$(Q) touch $@

mtdutils-configure: $(MTDUTILS_CONFIGURE_STAMP)
$(MTDUTILS_CONFIGURE_STAMP): $(MTDUTILS_PATCH_STAMP) $(UTILLINUX_BUILD_STAMP) \
			     $(LZO_BUILD_STAMP) $(ZLIB_BUILD_STAMP) \
			     $(MTDUTILS_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure mtd-utils-$(MTDUTILS_VERSION) ===="
	$(Q) cd $(MTDUTILS_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
	    $(MTDUTILS_DIR)/configure			\
		--prefix=$(DEV_SYSROOT)/usr		\
		--host=$(TARGET)				\
		--with-jffs					\
		--with-ubifs				\
		--with-zlib					\
		--with-lzo					\
		--without-lsmtd				\
		--without-tests				\
		--without-xattr				\
		--without-zstd				\
		--without-selinux				\
		--without-crypto				\
		--disable-ubihealthd			\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(filter-out -Werror,$(ONIE_CFLAGS))"			\
		LDFLAGS="$(ONIE_LDFLAGS)"			\
		ZLIB_CFLAGS="-I$(DEV_SYSROOT)/usr/include"	\
		ZLIB_LIBS="-L$(DEV_SYSROOT)/usr/lib -lz"	\
		UUID_CFLAGS="-I$(DEV_SYSROOT)/usr/include/uuid"	\
		UUID_LIBS="-L$(DEV_SYSROOT)/usr/lib -luuid"	\
		LZO_CFLAGS="-I$(DEV_SYSROOT)/usr/include"	\
		LZO_LIBS="-L$(DEV_SYSROOT)/usr/lib -llzo2"	\
		$(ONIE_PKG_CONFIG)
	$(Q) touch $@

mtdutils-build: $(MTDUTILS_BUILD_STAMP)
$(MTDUTILS_BUILD_STAMP): $(MTDUTILS_CONFIGURE_STAMP) $(MTDUTILS_NEW_FILES) | \
			   $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building mtd-utils-$(MTDUTILS_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(MTDUTILS_DIR) CFLAGS="$(ONIE_CFLAGS)"
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(MTDUTILS_DIR) CFLAGS="$(ONIE_CFLAGS)" install
	$(Q) touch $@

mtdutils-install: $(MTDUTILS_INSTALL_STAMP)
$(MTDUTILS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(MTDUTILS_BUILD_STAMP) $(UTILLINUX_INSTALL_STAMP) \
				$(LZO_INSTALL_STAMP) $(ZLIB_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing mtdutils in $(SYSROOTDIR) ===="
	$(Q) for file in $(MTDBINS) ; do \
		cp -av --remove-destination $(DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin/ ; \
	done
        #if UBI utils from busybox are not installed, use the mtdtools versions
	$(Q) for file in $(UBIBINS) ; do \
		if [ ! -f $(SYSROOTDIR)/usr/sbin/$$file ] ; \
		then \
			cp -av --remove-destination $(DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin/ ; \
		fi; \
	done
	$(Q) touch $@

USER_CLEAN += mtdutils-clean
mtdutils-clean:
	$(Q) rm -rf $(MTDUTILS_BUILD_DIR)
	$(Q) rm -f $(MTDUTILS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += mtdutils-download-clean
mtdutils-download-clean:
	$(Q) rm -f $(MTDUTILS_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(MTDUTILS_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
