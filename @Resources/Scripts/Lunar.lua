-- ============================================================================
-- Lunar.lua  农历 / 二十四节气 / 传统节日 离线计算模块
--
-- 数据来源：solarlunar (1900-2100 农历信息表 + 节气日期表)
--   原作者 Ajing (JJonline@JJonline.Cn)  http://blog.jjonline.cn/userInterFace/173.html
-- 本文件为 Lua 移植版，仅保留本皮肤需要的功能：
--   Lunar.DayInfo(y, m, d) → { lMonth, lDay, monthCn, dayCn, term, festival }
--   Lunar.IsTermDay(y, m, d) → bool, termName
-- 由 Calendar.lua 通过 dofile 加载（必须是 UTF-8 无 BOM）
-- ============================================================================

local Lunar = {}

-- 1900-2100 农历信息表（每年一个数：12个月大小月 + 闰月信息）
local LUNAR_INFO = { 0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, 0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, 0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, 0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, 0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, 0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, 0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, 0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6, 0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570, 0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x05ac0, 0x0ab60, 0x096d5, 0x092e0, 0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, 0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, 0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, 0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, 0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, 0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0, 0x092e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4, 0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, 0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160, 0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a4d0, 0x0d150, 0x0f252, 0x0d520 }

-- 1900-2100 二十四节气日期速查表（每年30个十六进制字符）
local LTERM_INFO = { '9778397bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf97c3598082c95f8c965cc920f', '97bd0b06bdb0722c965ce1cfcc920f', 'b027097bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf97c359801ec95f8c965cc920f', '97bd0b06bdb0722c965ce1cfcc920f', 'b027097bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf97c359801ec95f8c965cc920f', '97bd0b06bdb0722c965ce1cfcc920f', 'b027097bd097c36b0b6fc9274c91aa', '9778397bd19801ec9210c965cc920e', '97b6b97bd19801ec95f8c965cc920f', '97bd09801d98082c95f8e1cfcc920f', '97bd097bd097c36b0b6fc9210c8dc2', '9778397bd197c36c9210c9274c91aa', '97b6b97bd19801ec95f8c965cc920e', '97bd09801d98082c95f8e1cfcc920f', '97bd097bd097c36b0b6fc9210c8dc2', '9778397bd097c36c9210c9274c91aa', '97b6b97bd19801ec95f8c965cc920e', '97bcf97c3598082c95f8e1cfcc920f', '97bd097bd097c36b0b6fc9210c8dc2', '9778397bd097c36c9210c9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf97c3598082c95f8c965cc920f', '97bd097bd097c35b0b6fc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf97c3598082c95f8c965cc920f', '97bd097bd097c35b0b6fc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf97c359801ec95f8c965cc920f', '97bd097bd097c35b0b6fc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf97c359801ec95f8c965cc920f', '97bd097bd097c35b0b6fc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf97c359801ec95f8c965cc920f', '97bd097bd07f595b0b6fc920fb0722', '9778397bd097c36b0b6fc9210c8dc2', '9778397bd19801ec9210c9274c920e', '97b6b97bd19801ec95f8c965cc920f', '97bd07f5307f595b0b0bc920fb0722', '7f0e397bd097c36b0b6fc9210c8dc2', '9778397bd097c36c9210c9274c920e', '97b6b97bd19801ec95f8c965cc920f', '97bd07f5307f595b0b0bc920fb0722', '7f0e397bd097c36b0b6fc9210c8dc2', '9778397bd097c36c9210c9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bd07f1487f595b0b0bc920fb0722', '7f0e397bd097c36b0b6fc9210c8dc2', '9778397bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf7f1487f595b0b0bb0b6fb0722', '7f0e397bd097c35b0b6fc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf7f1487f595b0b0bb0b6fb0722', '7f0e397bd097c35b0b6fc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf7f1487f531b0b0bb0b6fb0722', '7f0e397bd097c35b0b6fc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c965cc920e', '97bcf7f1487f531b0b0bb0b6fb0722', '7f0e397bd07f595b0b6fc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b97bd19801ec9210c9274c920e', '97bcf7f0e47f531b0b0bb0b6fb0722', '7f0e397bd07f595b0b0bc920fb0722', '9778397bd097c36b0b6fc9210c91aa', '97b6b97bd197c36c9210c9274c920e', '97bcf7f0e47f531b0b0bb0b6fb0722', '7f0e397bd07f595b0b0bc920fb0722', '9778397bd097c36b0b6fc9210c8dc2', '9778397bd097c36c9210c9274c920e', '97b6b7f0e47f531b0723b0b6fb0722', '7f0e37f5307f595b0b0bc920fb0722', '7f0e397bd097c36b0b6fc9210c8dc2', '9778397bd097c36b0b70c9274c91aa', '97b6b7f0e47f531b0723b0b6fb0721', '7f0e37f1487f595b0b0bb0b6fb0722', '7f0e397bd097c35b0b6fc9210c8dc2', '9778397bd097c36b0b6fc9274c91aa', '97b6b7f0e47f531b0723b0b6fb0721', '7f0e27f1487f595b0b0bb0b6fb0722', '7f0e397bd097c35b0b6fc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b7f0e47f531b0723b0b6fb0721', '7f0e27f1487f531b0b0bb0b6fb0722', '7f0e397bd097c35b0b6fc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b7f0e47f531b0723b0b6fb0721', '7f0e27f1487f531b0b0bb0b6fb0722', '7f0e397bd097c35b0b6fc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b7f0e47f531b0723b0b6fb0721', '7f0e27f1487f531b0b0bb0b6fb0722', '7f0e397bd07f595b0b0bc920fb0722', '9778397bd097c36b0b6fc9274c91aa', '97b6b7f0e47f531b0723b0787b0721', '7f0e27f0e47f531b0b0bb0b6fb0722', '7f0e397bd07f595b0b0bc920fb0722', '9778397bd097c36b0b6fc9210c91aa', '97b6b7f0e47f149b0723b0787b0721', '7f0e27f0e47f531b0723b0b6fb0722', '7f0e397bd07f595b0b0bc920fb0722', '9778397bd097c36b0b6fc9210c8dc2', '977837f0e37f149b0723b0787b0721', '7f07e7f0e47f531b0723b0b6fb0722', '7f0e37f5307f595b0b0bc920fb0722', '7f0e397bd097c35b0b6fc9210c8dc2', '977837f0e37f14998082b0787b0721', '7f07e7f0e47f531b0723b0b6fb0721', '7f0e37f1487f595b0b0bb0b6fb0722', '7f0e397bd097c35b0b6fc9210c8dc2', '977837f0e37f14998082b0787b06bd', '7f07e7f0e47f531b0723b0b6fb0721', '7f0e27f1487f531b0b0bb0b6fb0722', '7f0e397bd097c35b0b6fc920fb0722', '977837f0e37f14998082b0787b06bd', '7f07e7f0e47f531b0723b0b6fb0721', '7f0e27f1487f531b0b0bb0b6fb0722', '7f0e397bd097c35b0b6fc920fb0722', '977837f0e37f14998082b0787b06bd', '7f07e7f0e47f531b0723b0b6fb0721', '7f0e27f1487f531b0b0bb0b6fb0722', '7f0e397bd07f595b0b0bc920fb0722', '977837f0e37f14998082b0787b06bd', '7f07e7f0e47f531b0723b0b6fb0721', '7f0e27f1487f531b0b0bb0b6fb0722', '7f0e397bd07f595b0b0bc920fb0722', '977837f0e37f14998082b0787b06bd', '7f07e7f0e47f149b0723b0787b0721', '7f0e27f0e47f531b0b0bb0b6fb0722', '7f0e397bd07f595b0b0bc920fb0722', '977837f0e37f14998082b0723b06bd', '7f07e7f0e37f149b0723b0787b0721', '7f0e27f0e47f531b0723b0b6fb0722', '7f0e397bd07f595b0b0bc920fb0722', '977837f0e37f14898082b0723b02d5', '7ec967f0e37f14998082b0787b0721', '7f07e7f0e47f531b0723b0b6fb0722', '7f0e37f1487f595b0b0bb0b6fb0722', '7f0e37f0e37f14898082b0723b02d5', '7ec967f0e37f14998082b0787b0721', '7f07e7f0e47f531b0723b0b6fb0722', '7f0e37f1487f531b0b0bb0b6fb0722', '7f0e37f0e37f14898082b0723b02d5', '7ec967f0e37f14998082b0787b06bd', '7f07e7f0e47f531b0723b0b6fb0721', '7f0e37f1487f531b0b0bb0b6fb0722', '7f0e37f0e37f14898082b072297c35', '7ec967f0e37f14998082b0787b06bd', '7f07e7f0e47f531b0723b0b6fb0721', '7f0e27f1487f531b0b0bb0b6fb0722', '7f0e37f0e37f14898082b072297c35', '7ec967f0e37f14998082b0787b06bd', '7f07e7f0e47f531b0723b0b6fb0721', '7f0e27f1487f531b0b0bb0b6fb0722', '7f0e37f0e366aa89801eb072297c35', '7ec967f0e37f14998082b0787b06bd', '7f07e7f0e47f149b0723b0787b0721', '7f0e27f1487f531b0b0bb0b6fb0722', '7f0e37f0e366aa89801eb072297c35', '7ec967f0e37f14998082b0723b06bd', '7f07e7f0e47f149b0723b0787b0721', '7f0e27f0e47f531b0723b0b6fb0722', '7f0e37f0e366aa89801eb072297c35', '7ec967f0e37f14998082b0723b06bd', '7f07e7f0e37f14998083b0787b0721', '7f0e27f0e47f531b0723b0b6fb0722', '7f0e37f0e366aa89801eb072297c35', '7ec967f0e37f14898082b0723b02d5', '7f07e7f0e37f14998082b0787b0721', '7f07e7f0e47f531b0723b0b6fb0722', '7f0e36665b66aa89801e9808297c35', '665f67f0e37f14898082b0723b02d5', '7ec967f0e37f14998082b0787b0721', '7f07e7f0e47f531b0723b0b6fb0722', '7f0e36665b66a449801e9808297c35', '665f67f0e37f14898082b0723b02d5', '7ec967f0e37f14998082b0787b06bd', '7f07e7f0e47f531b0723b0b6fb0721', '7f0e36665b66a449801e9808297c35', '665f67f0e37f14898082b072297c35', '7ec967f0e37f14998082b0787b06bd', '7f07e7f0e47f531b0723b0b6fb0721', '7f0e26665b66a449801e9808297c35', '665f67f0e37f1489801eb072297c35', '7ec967f0e37f14998082b0787b06bd', '7f07e7f0e47f531b0723b0b6fb0721', '7f0e27f1487f531b0b0bb0b6fb0722' }

local TERM_NAMES = { '小寒','大寒','立春','雨水','惊蛰','春分','清明','谷雨','立夏','小满','芒种','夏至','小暑','大暑','立秋','处暑','白露','秋分','寒露','霜降','立冬','小雪','大雪','冬至' }

local N_STR1 = { '日','一','二','三','四','五','六','七','八','九','十' }
local N_STR2 = { '初','十','廿','卅' }
local N_STR3 = { '正','二','三','四','五','六','七','八','九','十','冬','腊' }

-- 农历传统节日（key = 月-日）
local LUNAR_FESTIVALS = {
    ['1-1'] = '春节', ['1-15'] = '元宵节', ['5-5'] = '端午节',
    ['7-7'] = '七夕节', ['7-15'] = '中元节', ['8-15'] = '中秋节',
    ['9-9'] = '重阳节', ['12-8'] = '腊八节', ['12-23'] = '小年',
}

-- 公历固定节日（key = 月-日）
local SOLAR_FESTIVALS = {
    ['1-1'] = '元旦', ['2-14'] = '情人节', ['3-8'] = '妇女节', ['3-12'] = '植树节',
    ['5-1'] = '劳动节', ['5-4'] = '青年节', ['6-1'] = '儿童节', ['7-1'] = '建党节',
    ['8-1'] = '建军节', ['9-10'] = '教师节', ['10-1'] = '国庆节', ['12-25'] = '圣诞节',
}

-- ------------------------- 基础算法 -------------------------

-- 公历日期 → 连续天数（Howard Hinnant days-from-civil，无平台依赖）
local function DaysFromCivil(y, m, d)
    if m <= 2 then y = y - 1 end
    local era = math.floor(y / 400)
    local yoe = y - era * 400
    local mp = (m + 9) % 12
    local doy = math.floor((153 * mp + 2) / 5) + d - 1
    local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
    return era * 146097 + doe - 719468
end
local DAYS_1900_1_31 = DaysFromCivil(1900, 1, 31)

-- 农历 y 年总天数
-- 农历 y 年闰哪个月（0=无闰月）
local function LeapMonth(y)
    return LUNAR_INFO[y - 1899] % 16
end

-- 农历 y 年闰月天数（0/29/30）
local function LeapDays(y)
    if LeapMonth(y) ~= 0 then
        local info = LUNAR_INFO[y - 1899]
        if math.floor(info / 65536) % 2 == 1 then return 30 else return 29 end
    end
    return 0
end

-- 农历 y 年 m 月（非闰月）天数
local function MonthDays(y, m)
    if m > 12 or m < 1 then return -1 end
    local info = LUNAR_INFO[y - 1899]
    if math.floor(info / 2^(16 - m)) % 2 == 1 then return 30 else return 29 end
end

-- 农历 y 年总天数
local function LYearDays(y)
    local sum = 348
    local info = LUNAR_INFO[y - 1899]
    for bit = 15, 4, -1 do
        if math.floor(info / 2^bit) % 2 == 1 then sum = sum + 1 end
    end
    return sum + LeapDays(y)
end

-- 公历 y 年第 n 个节气（1-24，1=小寒）是当月几号
local function GetTerm(y, n)
    if y < 1900 or y > 2100 or n < 1 or n > 24 then return -1 end
    local t = LTERM_INFO[y - 1899]
    local calDay = {}
    for k = 0, 5 do
        local s = tostring(tonumber(t:sub(k * 5 + 1, k * 5 + 5), 16))
        calDay[#calDay + 1] = tonumber(s:sub(1, 1))
        calDay[#calDay + 1] = tonumber(s:sub(2, 3))
        calDay[#calDay + 1] = tonumber(s:sub(4, 4))
        calDay[#calDay + 1] = tonumber(s:sub(5, 6))
    end
    return calDay[n]
end

-- ------------------------- 公历 → 农历 -------------------------

local function Solar2Lunar(y, m, d)
    if y < 1900 or y > 2100 then return nil end
    if y == 1900 and m == 1 and d < 31 then return nil end

    local offset = DaysFromCivil(y, m, d) - DAYS_1900_1_31
    local i, temp = 1900, 0
    while i < 2101 and offset > 0 do
        temp = LYearDays(i)
        offset = offset - temp
        i = i + 1
    end
    if offset < 0 then
        offset = offset + temp
        i = i - 1
    end
    local lYear = i

    local leap = LeapMonth(lYear)
    local isLeap = false
    local m2 = 1
    while m2 < 13 and offset > 0 do
        if leap > 0 and m2 == leap + 1 and not isLeap then
            m2 = m2 - 1
            isLeap = true
            temp = LeapDays(lYear)
        else
            temp = MonthDays(lYear, m2)
        end
        if isLeap and m2 == leap + 1 then isLeap = false end
        offset = offset - temp
        m2 = m2 + 1
    end
    if offset == 0 and leap > 0 and m2 == leap + 1 then
        if isLeap then isLeap = false else isLeap = true; m2 = m2 - 1 end
    end
    if offset < 0 then
        offset = offset + temp
        m2 = m2 - 1
    end
    return lYear, m2, offset + 1, isLeap
end

-- 农历日/月 中文表示
local function ToChinaDay(d)
    if d == 10 then return '初十' end
    if d == 20 then return '二十' end
    if d == 30 then return '三十' end
    return N_STR2[math.floor(d / 10) + 1] .. N_STR1[d % 10 + 1]
end

local function ToChinaMonth(m, isLeap)
    return (isLeap and '闰' or '') .. N_STR3[m] .. '月'
end

-- ------------------------- 对外接口 -------------------------

-- 公历 y-m-d 的完整信息
-- 返回：{ lMonth, lDay, monthCn, dayCn, term, festival }
function Lunar.DayInfo(y, m, d)
    local info = { term = '', festival = '' }

    -- 节气
    local firstNode = GetTerm(y, m * 2 - 1)
    local secondNode = GetTerm(y, m * 2)
    if d == firstNode then info.term = TERM_NAMES[m * 2 - 1] end
    if d == secondNode then info.term = TERM_NAMES[m * 2] end

    -- 公历固定节日 + 清明（清明为4月的第5个节气，需限定月份）
    info.festival = SOLAR_FESTIVALS[m .. '-' .. d] or ''
    if m == 4 and d == GetTerm(y, 5) then info.festival = '清明节' end

    -- 农历与农历节日
    local lYear, lMonth, lDay, isLeap = Solar2Lunar(y, m, d)
    if lYear then
        info.lMonth, info.lDay = lMonth, lDay
        info.monthCn = ToChinaMonth(lMonth, isLeap and LeapMonth(lYear) == lMonth)
        info.dayCn = ToChinaDay(lDay)
        local lf = LUNAR_FESTIVALS[lMonth .. '-' .. lDay]
        if lf then info.festival = lf end
        -- 除夕：农历12月最后一天
        if lMonth == 12 and lDay == MonthDays(lYear, 12) then
            info.festival = '除夕'
        end
    end
    return info
end

return Lunar