local sys = require "luci.sys"

m = Map("luci-app-ipsec-server", translate("IPSec VPN Server"))
m.template = "ipsec-server/ipsec-server_status"

s = m:section(TypedSection, "service")
s.anonymous = true

o = s:option(DummyValue, "ipsec-server_status", translate("Current Condition"))
o.rawhtml = true
o.cfgvalue = function(t, n)
	return '<font class="ipsec-server_status"></font>'
end

 -- runtime toggle button instead of checkbox
 local btn_toggle = s:option(Button, "_toggle")
 btn_toggle.title = translate("Enable")
 btn_toggle.cfgvalue = function(self, section)
 	local running = (sys.call("/usr/bin/pgrep ipsec >/dev/null") == 0)
 	self.inputtitle = running and translate("停止服务") or translate("启动服务")
 	self.inputstyle = running and "reset" or "apply"
 	return true
 end
 btn_toggle.write = function(self, section)
 	if sys.call("/usr/bin/pgrep ipsec >/dev/null") == 0 then
 		-- stop
 		sys.call("uci set luci-app-ipsec-server.@service[0].enabled='0'")
 		sys.call("uci commit luci-app-ipsec-server")
 		sys.call("/etc/init.d/luci-app-ipsec-server stop >/dev/null 2>&1 &")
 	else
 		-- start
 		sys.call("uci set luci-app-ipsec-server.@service[0].enabled='1'")
 		sys.call("uci commit luci-app-ipsec-server")
 		sys.call("/etc/init.d/luci-app-ipsec-server start >/dev/null 2>&1 &")
 	end
 end

clientip = s:option(Value, "clientip", translate("VPN Client IP"))
clientip.description = translate("VPN Client reserved started IP addresses with the same subnet mask, such as: 192.168.100.10/24")
clientip.datatype = "ip4addr"
clientip.optional = false
clientip.rmempty = false

secret = s:option(Value, "secret", translate("Secret Pre-Shared Key"))
secret.password = true

if sys.call("command -v xl2tpd > /dev/null") == 0 then
	o = s:option(DummyValue, "l2tp_status", "L2TP " .. translate("Current Condition"))
	o.rawhtml = true
	o.cfgvalue = function(t, n)
		return '<font class="l2tp_status"></font>'
	end

	-- L2TP toggle button instead of checkbox
	local l2tp_btn = s:option(Button, "_l2tp_toggle")
	l2tp_btn.title = "L2TP " .. translate("Enable")
	l2tp_btn.cfgvalue = function(self, section)
		local l2tp_running = (sys.call("top -bn1 | grep -v grep | grep '/var/etc/xl2tpd' >/dev/null") == 0)
		self.inputtitle = l2tp_running and translate("停止L2TP") or translate("启用L2TP")
		self.inputstyle = l2tp_running and "reset" or "apply"
		return true
	end
	l2tp_btn.write = function(self, section)
		local l2tp_running = (sys.call("top -bn1 | grep -v grep | grep '/var/etc/xl2tpd' >/dev/null") == 0)
		local ipsec_running = (sys.call("/usr/bin/pgrep ipsec >/dev/null") == 0)
		if l2tp_running then
			-- 关闭 L2TP
			sys.call("uci set luci-app-ipsec-server.@service[0].l2tp_enable='0'")
			sys.call("uci commit luci-app-ipsec-server")
			if ipsec_running then
				sys.call("/etc/init.d/luci-app-ipsec-server restart >/dev/null 2>&1 &")
			end
		else
			-- 启用 L2TP
			sys.call("uci set luci-app-ipsec-server.@service[0].l2tp_enable='1'")
			-- 若主服务未启用，则一并启用
			if sys.call("uci -q get luci-app-ipsec-server.@service[0].enabled | grep -q '^1$'") ~= 0 then
				sys.call("uci set luci-app-ipsec-server.@service[0].enabled='1'")
			end
			sys.call("uci commit luci-app-ipsec-server")
			if ipsec_running then
				sys.call("/etc/init.d/luci-app-ipsec-server restart >/dev/null 2>&1 &")
			else
				sys.call("/etc/init.d/luci-app-ipsec-server start >/dev/null 2>&1 &")
			end
		end
	end

	o = s:option(Value, "l2tp_localip", "L2TP " .. translate("Server IP"))
	o.description = translate("VPN Server IP address, such as: 192.168.101.1")
	o.datatype = "ip4addr"
	o.rmempty = true
	o.default = "192.168.101.1"
	o.placeholder = o.default

	o = s:option(Value, "l2tp_remoteip", "L2TP " .. translate("Client IP"))
	o.description = translate("VPN Client IP address range, such as: 192.168.101.10-20")
	o.rmempty = true
	o.default = "192.168.101.10-20"
	o.placeholder = o.default

	if sys.call("ls -L /usr/lib/ipsec/libipsec* 2>/dev/null >/dev/null") == 0 then
		o = s:option(DummyValue, "_o", " ")
		o.rawhtml = true
		o.cfgvalue = function(t, n)
			return string.format('<a style="color: red">%s</a>', translate("L2TP/IPSec is not compatible with kernel-libipsec, which will disable this module."))
		end
		o:depends("l2tp_enable", true)
	end
end

return m
