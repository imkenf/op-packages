#
# Copyright (C) 2020 Nate Ding
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for BearDropper
LUCI_PKGARCH:=all

PKG_VERSION:=1.1
PKG_RELEASE:=20250902

PKG_MAINTAINER:=Nate Ding <natelol@github.com>
PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE

LUCI_DEPENDS:=+luci-base +rpcd +rpcd-mod-uci

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
