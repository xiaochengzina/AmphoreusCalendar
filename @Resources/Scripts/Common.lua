-- ============================================================================
-- Common.lua  共享工具模块
-- 由 Calendar.lua / Settings.lua 通过 dofile 加载（各自的 Lua 沙盒互不影响）
-- 只放与具体业务无关的通用函数，业务逻辑请放在各自的脚本里
-- ============================================================================

local Common = {}

-- 用户设置文件路径（#@# = @Resources 目录，自带末尾反斜杠）
function Common.VarsPath()
    return SKIN:GetVariable('@') .. 'Configs\\Variables.inc'
end

-- 出厂默认设置文件路径
function Common.DefaultsPath()
    return SKIN:GetVariable('@') .. 'Configs\\Default.inc'
end

-- 读取数值型变量，无效时返回默认值
function Common.GetNum(key, default)
    local v = tonumber(SKIN:GetVariable(key))
    if v == nil then return default end
    return v
end

-- 校验输入：取整并限制在 [min, max]，越界或非法时返回 default
function Common.ClampInt(raw, min, max, default)
    local n = tonumber(raw)
    if n == nil then return default end
    n = math.floor(n)
    if n < min or n > max then return default end
    return n
end

-- 持久化写入用户设置文件（注意：写入后需要 Refresh 或 !SetVariable 才会生效）
-- path 可指定其他 ini 数据文件，默认 Variables.inc
function Common.WriteVar(key, value, path)
    SKIN:Bang('!WriteKeyValue', 'Variables', key, tostring(value), path or Common.VarsPath())
end

-- 校验特殊日期/备忘日期字符串：
--   'YYYY-MM-DD'（一次性，且不早于今天）或 'MM-DD'（每年循环）
-- 返回：(true, 格式化字符串) 或 (false, 错误原因)
function Common.ValidateSpecDate(dateStr)
    if type(dateStr) ~= 'string' or dateStr == '' then
        return false, '输入为空'
    end

    -- 每年循环：MM-DD
    local m, d = dateStr:match('^(%d%d?)[-/](%d%d?)$')
    if m and d then
        m, d = tonumber(m), tonumber(d)
        if m < 1 or m > 12 then
            return false, '月份必须在 1-12 之间'
        end
        local maxDays = (m == 2) and 29 or ((m == 4 or m == 6 or m == 9 or m == 11) and 30 or 31)
        if d < 1 or d > maxDays then
            return false, string.format('日期无效（该月最大日期为 %d）', maxDays)
        end
        return true, string.format('%02d-%02d', m, d)
    end

    -- 一次性：YYYY-MM-DD（复用完整校验，含过期检查）
    return Common.ValidateDate(dateStr)
end

-- 获取指定年月的核心日期信息
-- 返回：本月天数, 本月1号的星期（0=周日, 1=周一 ... 6=周六）
function Common.GetMonthInfo(year, month)
    -- 利用“下个月的第0天 = 本月最后一天”求本月天数
    local nextMonth, nextYear = month + 1, year
    if nextMonth > 12 then nextMonth, nextYear = 1, nextYear + 1 end
    local lastDay = os.time({ year = nextYear, month = nextMonth, day = 0 })
    local totalDays = tonumber(os.date('%d', lastDay))

    local firstDay = os.time({ year = year, month = month, day = 1 })
    local firstWeekday = tonumber(os.date('%w', firstDay))

    return totalDays, firstWeekday
end

-- 校验日期字符串（支持 YYYY-MM-DD 或 YYYY/MM/DD），并要求不早于今天
-- 返回：(true, 格式化后的 'YYYY-MM-DD') 或 (false, 错误原因)
function Common.ValidateDate(dateStr)
    if type(dateStr) ~= 'string' or dateStr == '' then
        return false, '输入为空'
    end

    local year, month, day = dateStr:match('^(%d%d%d%d)[-/](%d%d?)[-/](%d%d?)$')
    if not year then
        return false, '格式错误（需为 YYYY-MM-DD 或 YYYY/MM/DD）'
    end

    local y, m, d = tonumber(year), tonumber(month), tonumber(day)
    if not y or not m or not d then
        return false, '年/月/日包含非数字字符'
    end

    if m < 1 or m > 12 then
        return false, '月份必须在 1-12 之间'
    end

    -- 校验日范围（含闰年判断）
    local maxDays
    if m == 2 then
        local isLeap = (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0)
        maxDays = isLeap and 29 or 28
    else
        maxDays = (m == 4 or m == 6 or m == 9 or m == 11) and 30 or 31
    end
    if d < 1 or d > maxDays then
        return false, string.format('日期无效（该月最大日期为 %d）', maxDays)
    end

    local fmtDate = string.format('%d-%02d-%02d', y, m, d)

    -- 过期判断（早于今天则拒绝）
    local now = os.date('*t')
    if y < now.year
        or (y == now.year and m < now.month)
        or (y == now.year and m == now.month and d < now.day) then
        return false, '日期已过期'
    end

    return true, fmtDate
end

-- 解析简单的 ini 文件（[Section] + key=value），按文件顺序返回
-- 返回数组：{ {key=..., value=...}, ... }
-- 仅用于读取本皮肤的 Default.inc / Variables.inc，不做完整 ini 语法支持
function Common.ReadIni(path)
    local entries = {}
    local f = io.open(path, 'r')
    if not f then return entries end
    local data = f:read('*a')
    f:close()
    -- 编码兼容：UTF-16 LE（去 BOM 后逐字去 null，仅适用 ASCII 内容）
    if data:sub(1, 2) == '\255\254' then
        data = data:sub(3):gsub('%z', '')
    end
    -- 去掉 UTF-8 BOM（如果有）
    data = data:gsub('^\239\187\191', '')
    for line in data:gmatch('[^\r\n]+') do
        line = line:match('^%s*(.-)%s*$')
        if line ~= '' and line:sub(1, 1) ~= ';' and line:sub(1, 1) ~= '[' then
            local k, v = line:match('^([%w_]+)%s*=%s*(.-)%s*$')
            if k then
                entries[#entries + 1] = { key = k, value = v }
            end
        end
    end
    return entries
end

return Common
