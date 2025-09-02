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
local uc = require "luci.model.uci".cursor()
uc:foreach("firewall", "rule", function(s)
	if s.name and s.name:match("^xl2tpd%-blacklist%-%") and s.src_ip then
		local t = {}
		t.ip = s.src_ip
		blacklist[#blacklist + 1] = t
	end
end)

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
	local sid = uc:add("firewall", "rule")
	uc:set("firewall", sid, "name", "xl2tpd-blacklist-" .. e)
	uc:set("firewall", sid, "src", "wan")
	uc:set("firewall", sid, "family", "ipv4")
	uc:set("firewall", sid, "src_ip", e)
	uc:set("firewall", sid, "proto", "udp")
	uc:set("firewall", sid, "dest_port", "500 4500 1701")
	uc:set("firewall", sid, "target", "DROP")
	uc:commit("firewall")
	luci.util.execi("/etc/init.d/firewall reload")
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
	local to_delete = {}
	uc:foreach("firewall", "rule", function(s)
		if s.name == ("xl2tpd-blacklist-" .. e) then
			to_delete[#to_delete + 1] = s[".name"]
		end
	end)
	for _, id in ipairs(to_delete) do
		uc:delete("firewall", id)
	end
	uc:commit("firewall")
	luci.util.execi("/etc/init.d/firewall reload")
	luci.http.redirect(o.build_url("admin/vpn/ipsec-server/online"))
end

return f
