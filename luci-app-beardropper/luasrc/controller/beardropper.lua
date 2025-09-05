module("luci.controller.beardropper", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/beardropper") then
	return
    end
    entry({"admin", "services", "beardropper"}, alias("admin", "services", "beardropper", "setting"),_("BearDropper"), 20).dependent = true
    entry({"admin", "services", "beardropper", "status"}, call("act_status"))
    entry({"admin", "services", "beardropper", "setting"}, cbi("beardropper/setting"), _("Setting"), 30).leaf= true
    entry({"admin", "services", "beardropper", "log"}, form("beardropper/log"),_("Log"),40).leaf= true
    --entry:
end

function act_status()
    local e={}
    -- 使用 procd 方式检查服务状态
    local status = luci.sys.call("/etc/init.d/beardropper status >/dev/null 2>&1")
    e.running = (status == 0)

    -- 备用检查方法：检查进程是否存在
    if not e.running then
        e.running = luci.sys.call("pgrep -f /usr/sbin/beardropper >/dev/null 2>&1") == 0
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end
