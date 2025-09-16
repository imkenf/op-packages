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

-- runtime start/stop buttons instead of checkbox
local running = (sys.call("/usr/bin/pgrep ipsec >/dev/null") == 0)

local btn_start = s:option(Button, "_start")
btn_start.title = translate("Enable")
btn_start.inputtitle = translate("启动服务")
btn_start.inputstyle = "apply"
btn_start.cfgvalue = function(self, section)
	return running and nil or true
end
btn_start.write = function(self, section)
	sys.call("uci set luci-app-ipsec-server.@service[0].enabled='1'")
	sys.call("uci commit luci-app-ipsec-server")
	sys.call("/etc/init.d/luci-app-ipsec-server start >/dev/null 2>&1 &")
end

local btn_stop = s:option(Button, "_stop")
btn_stop.inputtitle = translate("停止服务")
btn_stop.inputstyle = "reset"
btn_stop.cfgvalue = function(self, section)
	return running and true or nil
end
btn_stop.write = function(self, section)
	sys.call("uci set luci-app-ipsec-server.@service[0].enabled='0'")
	sys.call("uci commit luci-app-ipsec-server")
	sys.call("/etc/init.d/luci-app-ipsec-server stop >/dev/null 2>&1 &")
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

	o = s:option(Flag, "l2tp_enable", "L2TP " .. translate("Enable"))
	o.description = translate("Use a client that supports L2TP over IPSec PSK to connect to this server.")
	o.default = 0
	o.rmempty = false

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
