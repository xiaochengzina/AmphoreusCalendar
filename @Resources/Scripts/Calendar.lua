-- ============================================================================
-- Calendar.lua  日历主逻辑 v2.1（月历缓存 + 正常/农历双视图 + 淡入淡出切换）
--
-- 入口函数（由 Rainmeter 自动调用）：
--   Initialize()         皮肤加载/刷新时调用 → 完整渲染
--   Update()             每秒调用 → 跨天检测 + 农历视图自动切换
--   HoverLunarView() / HoverNormalView()   悬停切换（主 ini Background 悬停动作）
--   ApplyPendingView()   淡入淡出中途调用（!Delay 后执行，交换内容并淡入）
--   ForceRender()        控制面板调用：设置变更即时重渲染
--   CalendarCoverClick() 封面点击
--
-- 视图切换（内置淡入淡出指令）：
--   SetView → [!HideFade][!Delay][ApplyPendingView] → 交换内容 → !ShowFade
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
local SPEC_DATE_COUNT = 24             -- 特殊日期最大数量
local ROW_GAPS        = { 36, 27, 22 } -- 4行 / 5行 / 6行 布局对应的行距

-- 星期表头文字：[星期格式][语言]（0=EN, 1=中文）
local WEEK_NAMES = {
    [0] = {  -- 周日开头
        [0] = { 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT' },
        [1] = { '周日', '周一', '周二', '周三', '周四', '周五', '周六' },
    },
    [1] = {  -- 周一开头
        [0] = { 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN' },
        [1] = { '周一', '周二', '周三', '周四', '周五', '周六', '周日' },
    },
}

-- 形状前缀（颜色部分渲染时拼接）
local RECT_BASE   = 'Rectangle 0,0,(22 * #Scale#),(22 * #Scale#),#CurrentDateRecogRoundedSize# | Fill Color 0,0,0,0 | StrokeWidth (2 * #Scale#) | Stroke Color '
local MOBIUS_BASE = 'Path Path1 | StrokeWidth 0 | Fill Color '
local TRANSPARENT = '0,0,0,0'
local ALPHA       = ',#ViewAlpha#' -- 网格区域淡入淡出 alpha 通道后缀

-- ----------------------------- 运行状态 -----------------------------

local Cfg = {}                -- 当前生效的用户设置（每次渲染时重新读取）
local LastRenderDay = -1      -- 上次渲染的“日”，用于跨天检测
local MonthCache = {}         -- 当月每格内容缓存：{ num, lunar, kind, spec, specColor }
local ViewState = 'normal'    -- 当前视图：normal / lunar
local PendingView = nil       -- 淡入淡出进行中待切换的视图（进行中再触发会被忽略）
local LastSwitch = 0          -- 上次视图切换时间（自动模式计时用）

-- ----------------------------- 小工具 -----------------------------

local function SetOpt(meter, option, value)
    SKIN:Bang('!SetOption', meter, option, tostring(value))
end

-- 读取全部用户设置到 Cfg
local function LoadConfig()
    Cfg.weekFormat     = Common.GetNum('WeekFormatType', 0)
    Cfg.fixBgItem      = Common.GetNum('FixBgItemNum', 0)
    Cfg.bgRandomMode   = Common.GetNum('BgRandomMode', 0)
    Cfg.lastRandomBg   = Common.GetNum('LastRandomBg', 0)
    Cfg.lastRandomTime = Common.GetNum('LastRandomTime', 0)
    Cfg.monthMarkOn    = Common.GetNum('MonthShowOrHide', 0)
    Cfg.todayMarkOn    = Common.GetNum('CurrentDateRecogStyle', 0)
    Cfg.specDateOn     = Common.GetNum('SpecDateToggle', 0)
    Cfg.coverMode      = Common.GetNum('CalendarCoverMode', 5)
    Cfg.coverClickTime = SKIN:GetVariable('CalendarCoverClickTime', '')
    Cfg.lunarViewMode  = Common.GetNum('LunarViewMode', 0)
    Cfg.lunarInterval  = Common.GetNum('LunarViewInterval', 30)
    Cfg.lunarDuration  = Common.GetNum('LunarViewDuration', 5)

    Cfg.weekLang = Common.GetNum('WeekLanguage', 0)

    -- 特殊日期开关：日期列表非空即启用（不再需要手动开关）
    Cfg.specDateOn = false
    Cfg.specDates = {}
    for i = 1, SPEC_DATE_COUNT do
        local str = SKIN:GetVariable('SpecDateTime' .. i, '')
        if str ~= '' then Cfg.specDateOn = true end
        Cfg.specDates[i] = {
            str   = str,
            color = SKIN:GetVariable('SpecDateColor' .. i, ''),
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

    -- 预处理特殊日期（命中当天则记录；仅当月且晚于今天）
    local specByDay = {}
    if Cfg.specDateOn == 1 then
        for _, s in ipairs(Cfg.specDates) do
            local e = ParseDate(s.str)
            if e and MatchMonth(e, now.year, now.month) and e.d > now.day then
                specByDay[e.d] = (s.color ~= '') and s.color or '#SpecDateColor#'
            end
        end
    end

    for i = 1, MAX_CELLS do
        local d = i - offset
        local cell = {}
        if d >= 1 and d <= days then
            cell.num = d
            local info = Lunar.DayInfo(now.year, now.month, d)
            -- 农历视图文字与类型（优先级：节日 > 节气 > 农历日/月）
            if info.festival ~= '' then
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

-- 正常视图：日期数字 + 今日高亮 + 莫比乌斯环
local function PaintNormalView(now)
    local todayCell = 0
    for i = 1, MAX_CELLS do
        local c = MonthCache[i]
        if c.num then
            SetOpt('CalDate' .. i, 'Text', c.num)
            SetOpt('CalDate' .. i, 'FontColor', '#DateColor#' .. ALPHA)
            SetOpt('CalDate' .. i, 'FontWeight', '400')
            if c.num == now.day then todayCell = i end
        else
            SetOpt('CalDate' .. i, 'Text', '')
        end
        SetOpt('CalRect' .. i, 'Shape', RECT_BASE .. TRANSPARENT)
        SetOpt('CalMobius' .. i, 'Shape', MOBIUS_BASE .. TRANSPARENT)

        if c.spec then
            SetOpt('CalDate' .. i, 'FontColor', TRANSPARENT)
            SetOpt('CalMobius' .. i, 'Shape', MOBIUS_BASE .. c.specColor .. ALPHA)
        end
    end

    -- 今日高亮（文字变色加粗 + 可选圆角框）
    if todayCell > 0 then
        SetOpt('CalDate' .. todayCell, 'FontColor', '#CurrentDateColor#' .. ALPHA)
        SetOpt('CalDate' .. todayCell, 'FontWeight', '900')
        if Cfg.todayMarkOn == 1 then
            SetOpt('CalRect' .. todayCell, 'Shape', RECT_BASE .. '#CurrentDateRecogColor#' .. ALPHA)
        end
    end
end

-- 农历视图：节日 / 节气 / 农历日（特殊日期格仍只显示环；今天使用当天日期颜色）
local function PaintLunarView(now)
    for i = 1, MAX_CELLS do
        local c = MonthCache[i]
        if c.num and not c.spec then
            SetOpt('CalDate' .. i, 'Text', c.lunar)
            SetOpt('CalDate' .. i, 'FontWeight', '400')
            if c.num == now.day then
                -- 与数字视图一致：今天使用当天日期颜色并加粗
                SetOpt('CalDate' .. i, 'FontColor', '#CurrentDateColor#' .. ALPHA)
                SetOpt('CalDate' .. i, 'FontWeight', '900')
            elseif c.kind == 'festival' then
                SetOpt('CalDate' .. i, 'FontColor', '#FestivalColor#' .. ALPHA)
            elseif c.kind == 'term' then
                SetOpt('CalDate' .. i, 'FontColor', '#TermColor#' .. ALPHA)
            else
                SetOpt('CalDate' .. i, 'FontColor', '#LunarDayColor#' .. ALPHA)
            end
        else
            SetOpt('CalDate' .. i, 'Text', '')
        end
        SetOpt('CalRect' .. i, 'Shape', RECT_BASE .. TRANSPARENT)
    end
end

-- 切换视图：内置淡入淡出（!HideFade → !Delay → 交换 → !ShowFade）
-- 过渡进行中再次触发时仅更新目标视图（链尾会交换到最新目标）
local InTransition = false
local function SetView(mode)
    -- 与“有效目标”比较：过渡中 ViewState 还是旧视图，但目标已是新视图
    local target = PendingView or ViewState
    if mode == target then return end
    PendingView = mode
    if InTransition then return end
    InTransition = true
    -- 网格区域淡入淡出：ViewFadeTimer（淡出 → ApplyPendingView 交换 → 淡入）
    SKIN:Bang('!CommandMeasure', 'ViewFadeTimer', 'Execute 1')
end

-- 淡入淡出中途：交换内容并淡入（由计时器 SwapView 动作调用）
function ApplyPendingView()
    EnsureLoaded()
    if PendingView == nil then return end
    ViewState = PendingView
    PendingView = nil
    if ViewState == 'lunar' then
        PaintLunarView(os.date('*t'))
    else
        PaintNormalView(os.date('*t'))
    end
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

-- 计时器完整跑完（Done 动作调用）：复位过渡状态；若期间积累了新目标则接力切换
function TransitionDone()
    EnsureLoaded()
    InTransition = false
    if PendingView ~= nil and PendingView ~= ViewState then
        local mode = PendingView
        InTransition = true
        SKIN:Bang('!CommandMeasure', 'ViewFadeTimer', 'Execute 1')
    end
end

-- ----------------------------- 各模块渲染 -----------------------------

-- 星期表头
local function RenderWeekHeader()
    local names = (WEEK_NAMES[Cfg.weekFormat] or WEEK_NAMES[0])[Cfg.weekLang] or WEEK_NAMES[0][0]
    for i, name in ipairs(names) do
        SetOpt('Week' .. i, 'Text', name)
    end
end

-- 随机背景：加载时从 12 张中随机选一张（不与上次重复）
local function DoRandomPick(force)
    if Cfg.bgRandomMode ~= 1 then return end
    -- 只有冷启动（距上次选择超过 300 秒）或强制重摇时才重新随机，
    -- 普通刷新保持原图，避免旧画面闪帧
    if not force and (os.time() - Cfg.lastRandomTime) <= 300 and Cfg.lastRandomBg >= 1 and Cfg.lastRandomBg <= 12 then
        return
    end
    local last = Cfg.lastRandomBg
    local n = last
    while n == last do
        n = math.random(1, 12)
    end
    Cfg.lastRandomBg = n
    Cfg.lastRandomTime = os.time()
    Common.WriteVar('LastRandomBg', n)
    Common.WriteVar('LastRandomTime', Cfg.lastRandomTime)
end

-- 背景图：随机模式 > 固定图 > 跟随月份
local function RenderBackground(month)
    local img = month
    if Cfg.bgRandomMode == 1 then
        img = (Cfg.lastRandomBg >= 1 and Cfg.lastRandomBg <= 12) and Cfg.lastRandomBg or month
    elseif Cfg.fixBgItem >= 1 and Cfg.fixBgItem <= 12 then
        img = Cfg.fixBgItem
    end
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
        -- “每次加载显示一次”：只在加载时展示，跨天不重弹
        if isInit then
            SKIN:Bang('!ShowMeterGroup', 'CalendarCover')
        end
    else
        local show = false
        if mode == 1 then     -- 每年显示一次
            show = (t:sub(1, 4) ~= string.format('%04d', now.year))
        elseif mode == 2 then -- 每月显示一次
            show = (t:sub(1, 7) ~= string.format('%04d-%02d', now.year, now.month))
        elseif mode == 3 then -- 每天显示一次
            show = (t ~= os.date('%Y-%m-%d'))
        end                   -- mode 5：关闭封面
        SKIN:Bang(show and '!ShowMeterGroup' or '!HideMeterGroup', 'CalendarCover')
    end

    -- 封面年份艺术字（前两位 / 后两位）
    local y = tostring(now.year)
    SetOpt('CalendarCoverText1', 'Text', y:sub(1, 2))
    SetOpt('CalendarCoverText2', 'Text', y:sub(3, 4))
end

-- ----------------------------- 渲染总入口 -----------------------------

local function Render(isInit)
    LoadConfig()
    if isInit then math.randomseed(os.time()) end
    local now = os.date('*t')
    RenderWeekHeader()
    if isInit then DoRandomPick() end
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

-- 悬停切换（模式 1）
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

-- 立即重摇随机背景（控制面板开启/重击随机时调用）
function PickRandomBg()
    EnsureLoaded()
    if Cfg.bgRandomMode ~= 1 then return end
    DoRandomPick(true)
    RenderBackground(os.date('*t').month)
    SKIN:Bang('!UpdateMeter', 'Background')
    SKIN:Bang('!Redraw')
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
