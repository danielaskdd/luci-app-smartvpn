# Copyright 2021 Daniel Yang (gzdaniel@me.com)
# This is free software, licensed under the Apache License, Version 2.0

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for SmartVPN
LUCI_DEPENDS:=+luci-lib-jsonc
LUCI_PKGARCH:=all

PKG_LICENSE:=Apache-2.0

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
