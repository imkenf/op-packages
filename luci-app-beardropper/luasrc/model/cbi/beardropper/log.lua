f = SimpleForm("logview")
f.reset = false
f.submit = false
t = f:field(TextValue, "conf")
t.rmempty = true
t.rows = 20
function t.cfgvalue()
	local cmd = "logread | grep authpriv | grep beardropper"
	local logs = luci.sys.exec(cmd)
	if logs then
		-- 反转行顺序以显示最新日志在顶部
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
