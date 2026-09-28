# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2024 asvow

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI for Tailscale
LUCI_DEPENDS:=+tailscale +jshn +curl +jq +flock
LUCI_PKGARCH:=all

PKG_VERSION:=1.2.17

define Package/luci-app-tailscale/conffiles
/etc/config/tailscale
/etc/config/tailscale_openclash
/etc/config/tailscale_policy_routing
endef

define Package/luci-app-tailscale/prerm
#!/bin/sh
state_dir=/etc/.luci-app-tailscale-upgrade

case "$${2:-}" in
	remove|[0-9]*) ;;
	*)
		# default_prerm sources this script for opkg, while OpenWrt 24.10
		# apk runs pre-deinstall directly with the old package version in $1.
		case "$${1:-}" in
			[0-9]*) ;;
			*) exit 0 ;;
		esac
		;;
esac

if [ -z "$${IPKG_INSTROOT}" ] && [ -x /usr/sbin/tailscale_policy_routing ]; then
	/usr/sbin/tailscale_policy_routing cleanup >/dev/null 2>&1 || exit 1
fi
if [ -z "$${IPKG_INSTROOT}" ] && [ -x /etc/init.d/tailscale-policy-routing ]; then
	/etc/init.d/tailscale-policy-routing disable >/dev/null 2>&1 || exit 1
fi
if [ -z "$${IPKG_INSTROOT}" ] && [ -x /usr/sbin/tailscale_openclash_bypass ]; then
	/usr/sbin/tailscale_openclash_bypass cleanup >/dev/null 2>&1 || true
fi
if [ -z "$${IPKG_INSTROOT}" ] && [ -x /etc/init.d/tailscale-openclash-bypass ]; then
	/etc/init.d/tailscale-openclash-bypass disable >/dev/null 2>&1 || true
fi
if [ -z "$${IPKG_INSTROOT}" ] && [ -x /etc/init.d/tailscale ]; then
	/etc/init.d/tailscale stop >/dev/null 2>&1 || exit 1
fi
for cleanup_dir in "$${state_dir}" "$${state_dir}.pending"; do
	rm -f "$${cleanup_dir}/tailscale" "$${cleanup_dir}/tailscale_openclash" \
		"$${cleanup_dir}/tailscale_openclash.absent" "$${cleanup_dir}/tailscale_policy_routing" \
		"$${cleanup_dir}/.complete"
	rmdir "$${cleanup_dir}" 2>/dev/null || true
done
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
