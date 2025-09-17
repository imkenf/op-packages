f = SimpleForm("logview")
f.reset = false
f.submit = false
t = f:field(TextValue, "conf")
t.rmempty = true
t.rows = 20
function t.cfgvalue()
    -- 优先读取本地滚动日志文件；否则退回系统日志
    local file_path = "/tmp/beardropper.log"
    local logs
    if nixio.fs.access(file_path) then
        logs = luci.sys.exec("tail -n 500 " .. file_path)
    else
        logs = luci.sys.exec("logread -e beardropper | tail -n 200")
    end
    if logs and #logs > 0 then
        local lines = {}
        for line in logs:gmatch("([^\r\n]*)\r?\n?") do
            if line ~= "" then
                table.insert(lines, 1, line)
            end
        end
        return table.concat(lines, "\n")
    end
    return ""
end
t.readonly="readonly"

return f
