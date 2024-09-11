export LC_ALL=C
SHELL:=/bin/bash

CURRENT_DIR ?= $(shell pwd)
PKG_TARBALL := lz4-v1.10.0.tar.gz
PKG_NAME := lz4-1.10.0

all:
	rm -rf $(PKG_NAME); \
	tar -xf $(PKG_TARBALL); \
	pushd $(CURRENT_DIR)/$(PKG_NAME)/; \
		make -j$(SYSDRV_JOBS);\
	popd;

clean: distclean

distclean:
	-rm -rf $(PKG_NAME)
