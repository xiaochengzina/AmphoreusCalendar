-- ============================================================================
-- Calendar.lua  日历主逻辑 v2（月历缓存 + 正常/农历双视图）
--
-- 入口函数（由 Rainmeter 自动调用）：
--   Initialize()         皮肤加载/刷新时调用 → 完整渲染
--   Update()             每秒调用 → 跨天检测 + 农历视图自动切换
--   HoverLunarView()     鼠标移入日历区（主 ini Background 悬停动作）
--   HoverNormalView()    鼠标移出日历区
--   ForceRender()        控制面板调用：设置变更即时重渲染
--   CalendarCoverClick() 封面点击
--
-- 视图说明：
--   正常视图：日期数字 + 今日高亮 + 莫比乌斯环 + 备忘圆点
--   农历视图：每格显示 备忘文字/节日名/节气名/农历日（初一显示月份名）
--   切换方式由 LunarViewMode 决定：0=关闭 1=悬停 2=自动(间隔/停留秒数可调)
-- ============================================================================

local Common, Lunar

local function EnsureLoaded()
    if Common == nil then
        Common = dofile(SKIN:GetVariable('@') .. 'Scripts\\Common.lua')
        Lunar  = dofile(SKIN:GetVariable('@') .. 'Scripts\\Lunar.lua')
    end
end

-- ----------------------------- 常量（可按需调整） -----------------------------

local MAX_CELLS       = 42             -- 网格总格数（6行 x 7列）
local SPEC_DATE_COUNT = 24             -- 特殊日期最大数量（标记页 2 页 x 12）
local MEMO_COUNT      = 12             -- 备忘录最大条数
local ROW_GAPS        = { 36, 27, 22 } -- 4行 / 5行 / 6行 布局对应的行距

-- 星期表头文字（0=周日开头, 1=周一开头）
local WEEK_NAMES = {
    [0] = { 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT' },
    [1] = { 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN' },
}

-- 形状前缀（颜色部分渲染时拼接）
local RECT_BASE   = 'Rectangle 0,0,(22 * #Scale#),(22 * #Scale#),#CurrentDateRecogRoundedSize# | Fill Color 0,0,0,0 | StrokeWidth (2 * #Scale#) | Stroke Color '
local MOBIUS_BASE = 'Path Path1 | StrokeWidth 0 | Fill Color '
local DOT_BASE    = 'Rectangle 0,0,(6 * #Scale#),(6 * #Scale#),(3 * #Scale#) | StrokeWidth 0 | Fill Color '
local TRANSPARENT = '0,0,0,0'

-- 农历视图配色
local MEMO_DOT_COLOR = '120,160,220'   -- 备忘圆点 / 备忘文字
local FESTIVAL_COLOR = '224,84,84'     -- 节日文字
local TERM_COLOR     = '140,170,90'    -- 节气文字
local MEMO_TEXT_LEN  = 4               -- 农历视图中备忘文字最大字数

-- ----------------------------- 运行状态 -----------------------------

local Cfg = {}                -- 当前生效的用户设置（每次渲染时重新读取）
local LastRenderDay = -1      -- 上次渲染的“日”，用于跨天检测
local MonthCache = {}         -- 当月每格内容缓存：{ num, lunar, kind, spec, specColor, memoDot }
local ViewState = 'normal'    -- 当前视图：normal / lunar
local LastSwitch = 0          -- 上次视图切换时间（自动模式计时用）

-- ----------------------------- 小工具 -----------------------------

local function SetOpt(meter, option, value)
    SKIN:Bang('!SetOption', meter, option, tostring(value))
end

-- 读取全部用户设置到 Cfg
local function LoadConfig()
    Cfg.weekFormat     = Common.GetNum('WeekFormatType', 0)
    Cfg.fixBgItem      = Common.GetNum('FixBgItemNum', 0)
    Cfg.monthMarkOn    = Common.GetNum('MonthShowOrHide', 0)
    Cfg.todayMarkOn    = Common.GetNum('CurrentDateRecogStyle', 0)
    Cfg.specDateOn     = Common.GetNum('SpecDateToggle', 0)
    Cfg.coverMode      = Common.GetNum('CalendarCoverMode', 5)
    Cfg.coverClickTime = SKIN:GetVariable('CalendarCoverClickTime', '')
    Cfg.lunarViewMode  = Common.GetNum('LunarViewMode', 0)
    Cfg.lunarInterval  = Common.GetNum('LunarViewInterval', 30)
    Cfg.lunarDuration  = Common.GetNum('LunarViewDuration', 5)

    Cfg.specDates = {}
    for i = 1, SPEC_DATE_COUNT do
        Cfg.specDates[i] = {
            str   = SKIN:GetVariable('SpecDateTime' .. i, ''),
            color = SKIN:GetVariable('SpecDateColor' .. i, ''),
        }
    end

    Cfg.memos = {}
    for i = 1, MEMO_COUNT do
        Cfg.memos[i] = {
            date = SKIN:GetVariable('Memo' .. i .. 'Date', ''),
            text = SKIN:GetVariable('Memo' .. i .. 'Text', ''),
        }
    end
end

-- 解析日期字符串：'YYYY-MM-DD'（一次性）或 'MM-DD'（每年循环），支持 / 分隔
-- 返回 { y, m, d, recur } 或 nil（格式非法）
local function ParseDate(str)
    if type(str) ~= 'string' or str == '' then return nil end
    local y, m, d = str:match('^(%d%d%d%d)[-/](%d%d?)[-/](%d%d?)$')
    if y then
        return { y = tonumber(y), m = tonumber(m), d = tonumber(d), recur = false }
    end
    m, d = str:match('^(%d%d?)[-/](%d%d?)$')
    if m then
        return { y = nil, m = tonumber(m), d = tonumber(d), recur = true }
    end
    return nil
end

-- 判断日期条目是否属于指定年月（recur 只匹配月份）
local function MatchMonth(entry, y, m)
    if entry.recur then
        return entry.m == m
    else
        return entry.y == y and entry.m == m
    end
end

-- 把“1号是星期几（0=周日）”换算为当前星期格式下的前置空格数
local function AdaptOffset(firstWeekday)
    if Cfg.weekFormat == 0 then
        return firstWeekday
    else
        return (firstWeekday + 6) % 7
    end
end

-- ----------------------------- 月历缓存 -----------------------------

-- 构建当月每格内容（数字 / 农历视图文字 / 标记信息）
local function BuildMonthCache(now)
    MonthCache = {}
    local days, firstWeekday = Common.GetMonthInfo(now.year, now.month)
    local offset = AdaptOffset(firstWeekday)

    -- 预处理特殊日期与备忘（命中当天则记录）
    local specByDay, memoByDay = {}, {}
    if Cfg.specDateOn == 1 then
        for _, s in ipairs(Cfg.specDates) do
            local e = ParseDate(s.str)
            if e and MatchMonth(e, now.year, now.month) and e.d > now.day then
                specByDay[e.d] = (s.color ~= '') and s.color or '#SpecDateColor#'
            end
        end
    end
    for _, memo in ipairs(Cfg.memos) do
        local e = ParseDate(memo.date)
        if e and memo.text ~= '' and MatchMonth(e, now.year, now.month) then
            memoByDay[e.d] = memo.text
        end
    end

    for i = 1, MAX_CELLS do
        local d = i - offset
        local cell = {}
        if d >= 1 and d <= days then
            cell.num = d
            local info = Lunar.DayInfo(now.year, now.month, d)
            -- 农历视图文字与类型（优先级：备忘 > 节日 > 节气 > 农历日/月）
            if memoByDay[d] then
                cell.kind = 'memo'
                cell.memoDot = true
                local t = memoByDay[d]
                -- 按字符数截断（UTF-8 中文每字 3 字节）
                local chars = {}
                for ch in t:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
                    chars[#chars + 1] = ch
                end
                if #chars > MEMO_TEXT_LEN then
                    t = table.concat(chars, '', 1, MEMO_TEXT_LEN - 1) .. '…'
                end
                cell.lunar = t
            elseif info.festival ~= '' then
                cell.kind = 'festival'
                cell.lunar = info.festival
            elseif info.term ~= '' then
                cell.kind = 'term'
                cell.lunar = info.term
            else
                cell.kind = 'lunar'
                cell.lunar = (info.lDay == 1) and info.monthCn or info.dayCn
            end
            -- 特殊日期标记（莫比乌斯环；两个视图中都隐藏文字只显示环）
            if specByDay[d] then
                cell.spec = true
                cell.specColor = specByDay[d]
            end
        end
        MonthCache[i] = cell
    end
end

-- ----------------------------- 视图绘制 -----------------------------

-- 正常视图：日期数字 + 今日高亮 + 莫比乌斯环 + 备忘圆点
local function PaintNormalView(now)
    local todayCell = 0
    for i = 1, MAX_CELLS do
        local c = MonthCache[i]
        if c.num then
            SetOpt('CalDate' .. i, 'Text', c.num)
            SetOpt('CalDate' .. i, 'FontColor', '#DateColor#')
            SetOpt('CalDate' .. i, 'FontWeight', '400')
            if c.num == now.day then todayCell = i end
        else
            SetOpt('CalDate' .. i, 'Text', '')
        end
        SetOpt('CalRect' .. i, 'Shape', RECT_BASE .. TRANSPARENT)
        SetOpt('CalMobius' .. i, 'Shape', MOBIUS_BASE .. TRANSPARENT)
        SetOpt('CalDot' .. i, 'Shape', DOT_BASE .. TRANSPARENT)

        if c.spec then
            SetOpt('CalDate' .. i, 'FontColor', TRANSPARENT)
            SetOpt('CalMobius' .. i, 'Shape', MOBIUS_BASE .. c.specColor)
        elseif c.memoDot then
            SetOpt('CalDot' .. i, 'Shape', DOT_BASE .. MEMO_DOT_COLOR)
        end
    end

    -- 今日高亮（文字变色加粗 + 可选圆角框）
    if todayCell > 0 then
        SetOpt('CalDate' .. todayCell, 'FontColor', '#CurrentDateColor#')
        SetOpt('CalDate' .. todayCell, 'FontWeight', '900')
        if Cfg.todayMarkOn == 1 then
            SetOpt('CalRect' .. todayCell, 'Shape', RECT_BASE .. '#CurrentDateRecogColor#')
        end
    end
end

-- 农历视图：备忘文字 / 节日 / 节气 / 农历日（特殊日期格仍只显示环）
local function PaintLunarView()
    for i = 1, MAX_CELLS do
        local c = MonthCache[i]
        if c.num and not c.spec then
            SetOpt('CalDate' .. i, 'Text', c.lunar)
            if c.kind == 'memo' then
                SetOpt('CalDate' .. i, 'FontColor', MEMO_DOT_COLOR)
            elseif c.kind == 'festival' then
                SetOpt('CalDate' .. i, 'FontColor', FESTIVAL_COLOR)
            elseif c.kind == 'term' then
                SetOpt('CalDate' .. i, 'FontColor', TERM_COLOR)
            else
                SetOpt('CalDate' .. i, 'FontColor', '#DateColor#')
            end
        elseif c.num and c.spec then
            SetOpt('CalDate' .. i, 'Text', '')
        else
            SetOpt('CalDate' .. i, 'Text', '')
        end
        SetOpt('CalRect' .. i, 'Shape', RECT_BASE .. TRANSPARENT)
        SetOpt('CalDot' .. i, 'Shape', DOT_BASE .. TRANSPARENT)
    end
end

-- 切换视图（内部；重复切换自动忽略）
local function SetView(mode)
    if mode == ViewState then return end
    if mode == 'lunar' then
        PaintLunarView()
    else
        PaintNormalView(os.date('*t'))
    end
    ViewState = mode
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

-- ----------------------------- 各模块渲染 -----------------------------

-- 星期表头
local function RenderWeekHeader()
    local names = WEEK_NAMES[Cfg.weekFormat] or WEEK_NAMES[0]
    for i, name in ipairs(names) do
        SetOpt('Week' .. i, 'Text', name)
    end
end

-- 背景图：FixBgItemNum 为 1-12 时固定该图，否则跟随月份
local function RenderBackground(month)
    local item = Cfg.fixBgItem
    local img = (item >= 1 and item <= 12) and item or month
    SetOpt('Background', 'ImageName', '#@#Images\\' .. img .. '.jpg')
end

-- 月份水印
local function RenderMonthMark(month)
    SetOpt('MonthMark', 'Text', Cfg.monthMarkOn == 1 and month or '')
end

-- 行距：按所需格子数确定 4/5/6 行
local function RenderLayout(now)
    local days, firstWeekday = Common.GetMonthInfo(now.year, now.month)
    local offset = AdaptOffset(firstWeekday)
    local needCells = offset + days
    local rows = (needCells <= 28) and 4 or (needCells <= 35) and 5 or 6
    local gap = ROW_GAPS[rows - 3]
    if SKIN:GetVariable('GridRowGap') ~= tostring(gap) then
        SKIN:Bang('!SetVariable', 'GridRowGap', tostring(gap))
    end
end

-- 封面：按模式决定是否显示（每天检查一次；isInit=皮肤刚加载）
local function RenderCover(now, isInit)
    local mode = Cfg.coverMode
    local t = Cfg.coverClickTime or ''

    if mode == 4 then
        if isInit then
            SKIN:Bang('!ShowMeterGroup', 'CalendarCover')
        end
    else
        local show = false
        if mode == 1 then
            show = (t:sub(1, 4) ~= string.format('%04d', now.year))
        elseif mode == 2 then
            show = (t:sub(1, 7) ~= string.format('%04d-%02d', now.year, now.month))
        elseif mode == 3 then
            show = (t ~= os.date('%Y-%m-%d'))
        end
        SKIN:Bang(show and '!ShowMeterGroup' or '!HideMeterGroup', 'CalendarCover')
    end

    local y = tostring(now.year)
    SetOpt('CalendarCoverText1', 'Text', y:sub(1, 2))
    SetOpt('CalendarCoverText2', 'Text', y:sub(3, 4))
end

-- ----------------------------- 渲染总入口 -----------------------------

local function Render(isInit)
    LoadConfig()
    local now = os.date('*t')
    RenderWeekHeader()
    RenderBackground(now.month)
    RenderMonthMark(now.month)
    RenderLayout(now)
    BuildMonthCache(now)
    PaintNormalView(now)
    RenderCover(now, isInit)
    LastRenderDay = now.day
    ViewState = 'normal'
    LastSwitch = os.time()
end

-- ----------------------------- Rainmeter 入口 -----------------------------

function Initialize()
    EnsureLoaded()
    Render(true)
end

function Update()
    EnsureLoaded()
    local now = os.date('*t')
    if now.day ~= LastRenderDay then
        Render(false)
        return
    end
    -- 农历视图自动切换（模式 2）
    if Cfg.lunarViewMode == 2 then
        local t = os.time()
        if ViewState == 'normal' and (t - LastSwitch) >= Cfg.lunarInterval then
            SetView('lunar')
            LastSwitch = t
        elseif ViewState == 'lunar' and (t - LastSwitch) >= Cfg.lunarDuration then
            SetView('normal')
            LastSwitch = t
        end
    end
end

-- 悬停切换（模式 1；主 ini Background 的悬停动作调用）
function HoverLunarView()
    EnsureLoaded()
    if Cfg.lunarViewMode == 1 then
        SetView('lunar')
    end
end

function HoverNormalView()
    EnsureLoaded()
    if Cfg.lunarViewMode == 1 then
        SetView('normal')
    end
end

-- 强制立即重渲染（供控制面板调用，设置变更即时生效）
function ForceRender()
    EnsureLoaded()
    Render(false)
end

-- 封面点击：隐藏封面并记录点击日期
function CalendarCoverClick()
    EnsureLoaded()
    SKIN:Bang('!HideMeterGroup', 'CalendarCover')
    local today = os.date('%Y-%m-%d')
    Common.WriteVar('CalendarCoverClickTime', today)
    Cfg.coverClickTime = today
    SKIN:Bang('!Redraw')
end
