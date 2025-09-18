module("luci.controller.beardropper", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/beardropper") then
	return
    end
    entry({"admin", "services", "beardropper"}, alias("admin", "services", "beardropper", "setting"),_("BearDropper"), 20).dependent = true
    entry({"admin", "services", "beardropper", "status"}, call("act_status"))
    entry({"admin", "services", "beardropper", "setting"}, cbi("beardropper/setting"), _("Setting"), 30).leaf= true
    entry({"admin", "services", "beardropper", "log"}, form("beardropper/log"),_("Log"),40).leaf= true
    entry({"admin", "services", "beardropper", "start"}, call("act_start"))
    entry({"admin", "services", "beardropper", "stop"}, call("act_stop"))
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

function act_start()
    local result = {}
    local function log_action(msg)
        local path = luci.sys.exec("uci -q get beardropper.@beardropper[0].fileLogPath 2>/dev/null") or ""
        path = (path or ""):gsub("%s+$", "")
        luci.sys.call("logger -t 'beardropper[luci]' '" .. msg .. "'")
        if path ~= "" then
            local ts = os.date('%Y-%m-%d %H:%M:%S')
            luci.sys.call("echo '" .. ts .. " " .. msg .. "' >> " .. path .. " 2>/dev/null")
        end
    end

    -- 先启用服务
    luci.sys.call("uci set beardropper.@beardropper[0].enabled=1")
    luci.sys.call("uci commit beardropper")

    -- 启动服务
    log_action("LuCI start requested")
    local status = luci.sys.call("/etc/init.d/beardropper start >/dev/null 2>&1")

    if status == 0 then
        result.success = true
        result.message = "BearDropper service started successfully"
        log_action("LuCI start success")
    else
        result.success = false
        result.message = "Failed to start BearDropper service"
        log_action("LuCI start failed")
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function act_stop()
    local result = {}

    -- 先禁用服务，避免 procd 立即拉起
    luci.sys.call("uci set beardropper.@beardropper[0].enabled=0")
    luci.sys.call("uci commit beardropper")

    -- 再停止服务
    local function log_action(msg)
        local path = luci.sys.exec("uci -q get beardropper.@beardropper[0].fileLogPath 2>/dev/null") or ""
        path = (path or ""):gsub("%s+$", "")
        luci.sys.call("logger -t 'beardropper[luci]' '" .. msg .. "'")
        if path ~= "" then
            local ts = os.date('%Y-%m-%d %H:%M:%S')
            luci.sys.call("echo '" .. ts .. " " .. msg .. "' >> " .. path .. " 2>/dev/null")
        end
    end
    log_action("LuCI stop requested")
    local status = luci.sys.call("/etc/init.d/beardropper stop >/dev/null 2>&1")

    -- 强制清理遗留进程（保险）
    luci.sys.call("pgrep -f /usr/sbin/beardropper >/dev/null 2>&1 && kill -9 `pgrep -f /usr/sbin/beardropper` >/dev/null 2>&1")

    if status == 0 then
        result.success = true
        result.message = "BearDropper service stopped successfully"
        log_action("LuCI stop success")
    else
        result.success = false
        result.message = "Failed to stop BearDropper service"
        log_action("LuCI stop failed")
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end
