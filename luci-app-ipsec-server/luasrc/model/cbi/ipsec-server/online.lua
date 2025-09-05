local o = require "luci.dispatcher"
local fs = require "nixio.fs"
local jsonc = require "luci.jsonc"

local sessions = {}
local session_path = "/var/etc/xl2tpd/session"
if fs.access(session_path) then
	for filename in fs.dir(session_path) do
		local session_file = session_path .. "/" .. filename
		local file = io.open(session_file, "r")
		local t = jsonc.parse(file:read("*a"))
		if t then
			t.session_file = session_file
			sessions[#sessions + 1] = t
		end
		file:close()
	end
end

local blacklist = {}
local firewall_user_path = "/etc/firewall.user"
if fs.access(firewall_user_path) then
	for line in io.lines(firewall_user_path) do
		local m = line:match('xl2tpd%-blacklist%-([^\n]+)')
		if m then
			local t = {}
			t.ip = m
			blacklist[#blacklist + 1] = t
		end
	end
end

f = SimpleForm("processes")
f.reset = false
f.submit = false

t = f:section(Table, sessions, translate("L2TP Online Users"))
t:option(DummyValue, "username", translate("Username"))
t:option(DummyValue, "interface", translate("Interface"))
t:option(DummyValue, "ip", translate("Client IP"))
t:option(DummyValue, "remote_ip", translate("IP address"))
t:option(DummyValue, "login_time", translate("Login Time"))

_blacklist = t:option(Button, "_blacklist", translate("Blacklist"))
function _blacklist.render(e, t, a)
	e.title = translate("Add to Blacklist")
	e.inputstyle = "remove"
	Button.render(e, t, a)
end
function _blacklist.write(t, s)
	local e = t.map:get(s, "remote_ip")
	local rule_name = "ipsec_blacklist_" .. e:gsub("%.", "_")

	-- 检测防火墙类型
	local fw_type = "fw3"
	if nixio.fs.access("/sbin/fw4") and nixio.fs.access("/usr/share/firewall4/main.uc") then
		fw_type = "fw4"
	end

	-- 添加 UCI 防火墙规则阻止该IP
	luci.util.execi("uci -q delete firewall.%s" % {rule_name})
	luci.util.execi("uci -q set firewall.%s=rule" % {rule_name})
	luci.util.execi("uci -q set firewall.%s.name='Block IPSec Client %s'" % {rule_name, e})
	luci.util.execi("uci -q set firewall.%s.src_ip='%s'" % {rule_name, e})
	luci.util.execi("uci -q set firewall.%s.proto='udp'" % {rule_name})
	luci.util.execi("uci -q set firewall.%s.dest_port='500 4500 1701'" % {rule_name})
	luci.util.execi("uci -q set firewall.%s.target='DROP'" % {rule_name})
	luci.util.execi("uci -q set firewall.%s.enabled='1'" % {rule_name})
	luci.util.execi("uci -q commit firewall")

	-- 重新加载防火墙
	if fw_type == "fw4" then
		luci.util.execi("fw4 reload >/dev/null 2>&1")
	else
		luci.util.execi("/etc/init.d/firewall reload >/dev/null 2>&1")
	end

	-- 向后兼容：同时添加到 firewall.user (仅对 fw3)
	if fw_type == "fw3" then
		luci.util.execi("echo 'iptables -I INPUT -s %s -p udp -m multiport --dports 500,4500,1701 -j DROP ## xl2tpd-blacklist-%s' >> /etc/firewall.user" % {e, e})
	end

	luci.util.execi("rm -f " .. t.map:get(s, "session_file"))
	null, t.tag_error[s] = luci.sys.process.signal(t.map:get(s, "pid"), 9)
	luci.http.redirect(o.build_url("admin/vpn/ipsec-server/online"))
end

_kill = t:option(Button, "_kill", translate("Forced offline"))
_kill.inputstyle = "remove"
function _kill.write(t, s)
	luci.util.execi("rm -f " .. t.map:get(s, "session_file"))
	null, t.tag_error[t] = luci.sys.process.signal(t.map:get(s, "pid"), 9)
	luci.http.redirect(o.build_url("admin/vpn/ipsec-server/online"))
end

t = f:section(Table, blacklist, translate("Blacklist"))
t:option(DummyValue, "ip", translate("IP address"))

_blacklist2 = t:option(Button, "_blacklist2", translate("Blacklist"))
function _blacklist2.render(e, t, a)
	e.title = translate("Remove from Blacklist")
	e.inputstyle = "apply"
	Button.render(e, t, a)
end
function _blacklist2.write(t, s)
	local e = t.map:get(s, "ip")
	local rule_name = "ipsec_blacklist_" .. e:gsub("%.", "_")

	-- 检测防火墙类型
	local fw_type = "fw3"
	if nixio.fs.access("/sbin/fw4") and nixio.fs.access("/usr/share/firewall4/main.uc") then
		fw_type = "fw4"
	end

	-- 删除 UCI 防火墙规则
	luci.util.execi("uci -q delete firewall.%s" % {rule_name})
	luci.util.execi("uci -q commit firewall")

	-- 重新加载防火墙
	if fw_type == "fw4" then
		luci.util.execi("fw4 reload >/dev/null 2>&1")
	else
		luci.util.execi("/etc/init.d/firewall reload >/dev/null 2>&1")
	end

	-- 向后兼容：清理 firewall.user (仅对 fw3)
	if fw_type == "fw3" then
		luci.util.execi("sed -i -e '/## xl2tpd-blacklist-%s/d' /etc/firewall.user" % {e})
		luci.util.execi("iptables -D INPUT -s %s -p udp -m multiport --dports 500,4500,1701 -j DROP 2>/dev/null" % {e})
	end

	luci.http.redirect(o.build_url("admin/vpn/ipsec-server/online"))
end

return f
