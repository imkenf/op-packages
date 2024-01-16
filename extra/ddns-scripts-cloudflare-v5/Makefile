include $(TOPDIR)/rules.mk

PKG_NAME:=ddns-scripts-cloudflare-v5
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_LICENSE:=GPLv2
PKG_MAINTAINER:=Kenf <imkenf@gmail.com>

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=IP Addresses and Names
	TITLE:=Extension for cloudflare.com API v5
	DEPENDS:=ddns-scripts +curl
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Dynamic DNS Client scripts extension for cloudflare.com API v5 (require curl)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/ddns
	$(INSTALL_BIN) ./update_cloudflare_com_v5.sh $(1)/usr/lib/ddns

	$(INSTALL_DIR) $(1)/usr/share/ddns/default
	$(INSTALL_DATA) ./cloudflare.com-v5.json $(1)/usr/share/ddns/default
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/ddns stop
fi
if [ -w $${IPKG_INSTROOT}/etc/ddns/services ]; then
	/bin/sed -i '/cloudflare\.com/d' $${IPKG_INSTROOT}/etc/ddns/services >/dev/null 2>&1
	/bin/sed -i '/cloudflare\.com/d' $${IPKG_INSTROOT}/etc/ddns/services_ipv6 >/dev/null 2>&1
fi
exit 0
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -w $${IPKG_INSTROOT}/etc/ddns/services ]; then
	/bin/sed -i '/cloudflare\.com/d' $${IPKG_INSTROOT}/etc/ddns/services >/dev/null 2>&1
	/bin/sed -i '/cloudflare\.com/d' $${IPKG_INSTROOT}/etc/ddns/services_ipv6 >/dev/null 2>&1
	printf "%s\\t\\t%s\\n" '"cloudflare.com"' '"update_cloudflare_com_v5.sh"' >> $${IPKG_INSTROOT}/etc/ddns/services
	printf "%s\\t\\t%s\\n" '"cloudflare.com"' '"update_cloudflare_com_v5.sh"' >> $${IPKG_INSTROOT}/etc/ddns/services_ipv6
fi
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/ddns enabled
	/etc/init.d/ddns start
fi
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
