-- Copyright 2018-2020 Lienol <lawlienol@gmail.com>
module("luci.controller.ipsec-server", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/luci-app-ipsec-server") then
		return
	end

	entry({"admin", "vpn"}, firstchild(), "VPN", 45).dependent = false
	entry({"admin", "vpn", "ipsec-server"}, alias("admin", "vpn", "ipsec-server", "settings"), _("IPSec VPN Server"), 49).dependent = false
	entry({"admin", "vpn", "ipsec-server", "settings"}, cbi("ipsec-server/settings"), _("General Settings"), 10).leaf = true
	entry({"admin", "vpn", "ipsec-server", "users"}, cbi("ipsec-server/users"), _("Users Manager"), 20).leaf = true
	entry({"admin", "vpn", "ipsec-server", "l2tp_user"}, cbi("ipsec-server/l2tp_user")).leaf = true
	entry({"admin", "vpn", "ipsec-server", "online"}, cbi("ipsec-server/online"), _("L2TP Online Users"), 30).leaf = true
	entry({"admin", "vpn", "ipsec-server", "status"}, call("act_status")).leaf = true
end

function act_status()
	local e = {}

	-- 检查服务是否配置启用
	local uci = luci.model.uci.cursor()
	local service_enabled = uci:get("luci-app-ipsec-server", "@service[0]", "enabled") == "1"
	local l2tp_enabled = uci:get("luci-app-ipsec-server", "@service[0]", "l2tp_enable") == "1"

	-- 更准确的IPSec状态检测
	local ipsec_running = false
	if service_enabled then
		-- 检查strongswan进程和配置文件
		ipsec_running = (luci.sys.call("pgrep charon >/dev/null 2>&1") == 0) and
		               (luci.sys.call("test -f /etc/ipsec.conf") == 0)
	end

	-- 更准确的L2TP状态检测
	local l2tp_running = false
	if l2tp_enabled and service_enabled then
		-- 检查xl2tpd进程和配置文件
		l2tp_running = (luci.sys.call("pgrep xl2tpd >/dev/null 2>&1") == 0) and
		              (luci.sys.call("test -f /var/etc/xl2tpd/xl2tpd.conf") == 0)
	end

	e["ipsec_status"] = ipsec_running
	e["l2tp_status"] = l2tp_running
	e["service_enabled"] = service_enabled
	e["l2tp_enabled"] = l2tp_enabled

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
