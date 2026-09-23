-- ============================================================================
-- Settings.lua  控制面板逻辑 v1.2.0（数据驱动 + 左侧 7 页导航 + 即时生效）
--
-- 通用入口（由 Settings.ini 的鼠标动作调用）：
--   Toggle('键名')                  开关类（0/1 切换）
--   SetWeekFormat(0/1)              星期格式（分段选择器）
--   SetBg(0-12)                     背景缩略图选择（0=自动）
--   SetLunarViewMode(0-2)           农历视图：关闭/悬停/自动
--   SliderSet/Jump/Step             滑块（含切换间隔、停留时长、缩放等 6 个）
--   SetCoverMode(1..5)              封面显示模式（分段选择器）
--   SpecPagePrev() / SpecPageNext() 标记日期列表分页（2 页 x 12 行 = 24 槽）
--   SetSpecDate(槽位, '输入值')      特殊日期（YYYY-MM-DD 一次性 / MM-DD 循环）
--   ResetToDefaults()               恢复出厂设置
--   ShowPage(1..7) / HoverNav       分页导航
--
-- 应用模型（ApplyVar）：写文件 → 同步面板与主皮肤内存变量 →
--   主皮肤 ForceRender() 即时重渲染。全程零刷新：不闪动、不跳页。
-- ============================================================================

local Common

local function EnsureLoaded()
    if Common == nil then
        Common = dofile(SKIN:GetVariable('@') .. 'Scripts\\Common.lua')
    end
end

-- ------------------------- 设置项注册表（改这里） -------------------------

-- 开关型设置：键名列表（开关 meter 命名约定：<键名>Box / <键名>Thumb）
local TOGGLES = {
    'MonthShowOrHide',        -- 月份水印
    'CurrentDateRecogStyle',  -- 今日圆角框
    'LunarShowMobius',        -- 节日视图显示莫比乌斯环
}

-- 滑块型设置：键名 = {最小值, 最大值, 步进}
local SLIDERS = {
    MonthRecogColorAlpha       = { 0, 255, 5 },  -- 月份水印透明度
    BgRoundedSize              = { 0, 100, 2 },  -- 背景圆角
    CurrentDateRecogRoundedSize= { 0, 20, 1 },   -- 今日框圆角
    LunarViewInterval          = { 10, 120, 5 }, -- 农历视图自动切换间隔（秒）
    LunarViewDuration          = { 2, 30, 1 },   -- 农历视图停留时长（秒）
    Scalepercent               = { 50, 300, 5 }, -- 缩放百分比
}

local TRACK_W          = 144  -- 滑块轨道宽度（与 Settings.ini 一致）
local TRACK_X          = 488  -- 滑块轨道起点 X（与 Settings.ini 一致）
local COVER_MODE_COUNT = 5    -- 封面模式数量
local LUNAR_MODE_COUNT = 3    -- 农历视图模式数量（0关闭 1悬停 2自动）
local BG_ITEM_COUNT    = 12   -- 背景缩略图数量（0=自动，1-12=月份图）
local PAGE_COUNT       = 7    -- 分页数量
local SPEC_ROWS        = 6    -- 标记页每页行数
local SPEC_SLOTS       = 24   -- 事件存储槽位上限（列表区每页 6 行）

-- 缩略图墙几何（与 Settings.ini 一致）
local BG_GRID = { x = 204, y = 146, cellW = 64, cellH = 110, gapX = 10, gapY = 12, cols = 7 }

-- ------------------------- 运行状态 -------------------------

local CurrentPage = 1
local SpecListPage = 1    -- 标记日期列表当前页（1-2）

-- ------------------------- 内部函数 -------------------------

-- 应用设置（核心）：写文件 + 同步面板与主皮肤内存变量 + 主皮肤即时重渲染
local function ApplyVar(key, value, path)
    Common.WriteVar(key, value, path)
    SKIN:Bang('!SetVariable', key, tostring(value))                      -- 面板
    SKIN:Bang('!SetVariable', key, tostring(value), 'AmphoreusCalendar') -- 主皮肤
    SKIN:Bang('!CommandMeasure', 'Script', 'ForceRender()', 'AmphoreusCalendar')
    -- 动态公式重算滞后一个更新周期：连续两次 UpdateMeter 才能让新值生效（缩放等公式类设置）
    SKIN:Bang('!UpdateMeter', '*', 'AmphoreusCalendar')
    SKIN:Bang('!UpdateMeter', '*', 'AmphoreusCalendar')
    SKIN:Bang('!Redraw', 'AmphoreusCalendar')
end

-- 批量应用：先写完所有键，再统一渲染一次（避免中间态闪帧）
local function ApplyVars(kv)
    for k, v in pairs(kv) do
        Common.WriteVar(k, v)
        SKIN:Bang('!SetVariable', k, tostring(v))
        SKIN:Bang('!SetVariable', k, tostring(v), 'AmphoreusCalendar')
    end
    SKIN:Bang('!CommandMeasure', 'Script', 'ForceRender()', 'AmphoreusCalendar')
    SKIN:Bang('!UpdateMeter', '*', 'AmphoreusCalendar')
    SKIN:Bang('!UpdateMeter', '*', 'AmphoreusCalendar')
    SKIN:Bang('!Redraw', 'AmphoreusCalendar')
end

-- 重绘面板
local function Repaint()
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

-- 设置某个开关控件的样式
local function SetSwitch(prefix, on)
    SKIN:Bang('!SetOption', prefix .. 'Box',   'MeterStyle', on and 'SwitchBoxOnStyle'   or 'SwitchBoxOffStyle')
    SKIN:Bang('!SetOption', prefix .. 'Thumb', 'MeterStyle', on and 'SwitchThumbOnStyle' or 'SwitchThumbOffStyle')
end

-- ------------------------- 外观同步 -------------------------

-- 滑块外观：填充宽度 + 旋钮位置 + 数值文字（部分键带单位后缀）
local function SliderLayout(key, v)
    local s = SLIDERS[key]
    v = Common.ClampInt(v, s[1], s[2], s[1])
    local w = math.floor((v - s[1]) / (s[2] - s[1]) * TRACK_W + 0.5)
    SKIN:Bang('!SetOption', 'Slt' .. key .. 'Fill', 'Shape',
        'Rectangle 0,9,' .. w .. ',6,3 | StrokeWidth 0 | Fill Color 176,138,74')
    SKIN:Bang('!SetOption', 'Slt' .. key .. 'Knob', 'X', tostring(TRACK_X - 5 + w))
    local text = tostring(v)
    if key == 'Scalepercent' then text = v .. '%'
    elseif key == 'LunarViewInterval' or key == 'LunarViewDuration' then text = v .. 's' end
    SKIN:Bang('!SetOption', 'Slt' .. key .. 'Value', 'Text', text)
end

-- 星期格式分段选择器
local function SyncWeekSeg()
    local cur = Common.GetNum('WeekFormatType', 0)
    for i = 0, 1 do
        SKIN:Bang('!SetOption', 'WeekFmt' .. i,        'MeterStyle', i == cur and 'SegOnStyle' or 'SegOffStyle')
        SKIN:Bang('!SetOption', 'WeekFmt' .. i .. 'T', 'MeterStyle', i == cur and 'SegTextOnStyle' or 'SegTextOffStyle')
    end
end

-- 星期语言分段选择器
local function SyncLangSeg()
    local cur = Common.GetNum('WeekLanguage', 0)
    for i = 0, 1 do
        SKIN:Bang('!SetOption', 'WeekLang' .. i,        'MeterStyle', i == cur and 'SegOnStyle' or 'SegOffStyle')
        SKIN:Bang('!SetOption', 'WeekLang' .. i .. 'T', 'MeterStyle', i == cur and 'SegTextOnStyle' or 'SegTextOffStyle')
    end
end
-- 封面模式分段选择器
local function SyncCoverSegs()
    local mode = Common.GetNum('CalendarCoverMode', 5)
    for i = 1, COVER_MODE_COUNT do
        SKIN:Bang('!SetOption', 'CoverSeg' .. i,        'MeterStyle', i == mode and 'CoverSegOnStyle' or 'CoverSegOffStyle')
        SKIN:Bang('!SetOption', 'CoverSeg' .. i .. 'T', 'MeterStyle', i == mode and 'SegTextOnStyle' or 'SegTextOffStyle')
    end
end

-- 农历视图分段选择器
local function SyncLunarSeg()
    local mode = Common.GetNum('LunarViewMode', 0)
    for i = 0, LUNAR_MODE_COUNT - 1 do
        SKIN:Bang('!SetOption', 'LunarMode' .. i,        'MeterStyle', i == mode and 'LunarSegOnStyle' or 'LunarSegOffStyle')
        SKIN:Bang('!SetOption', 'LunarMode' .. i .. 'T', 'MeterStyle', i == mode and 'SegTextOnStyle' or 'SegTextOffStyle')
    end
end

-- 背景缩略图：选中金描边 + 未选压暗 + 选中徽标定位 + “自动”格文字变色
local function SyncBgThumbs()
    local cur = Common.GetNum('FixBgItemNum', 0)
    local rnd = Common.GetNum('BgRandomMode', 0)
    local g = BG_GRID
    for i = 0, 13 do
        local active = (i == 13 and rnd == 1) or (i < 13 and rnd == 0 and i == cur)
        SKIN:Bang('!SetOption', 'BgBd' .. i, 'MeterStyle', active and 'BgBdOnStyle' or 'BgBdOffStyle')
        if i >= 1 and i <= 12 then
            SKIN:Bang('!SetOption', 'BgThumb' .. i, 'ImageAlpha', active and '255' or '170')
        end
    end
    SKIN:Bang('!SetOption', 'BgAutoT', 'FontColor', (rnd == 0 and cur == 0) and '#ColorGold#' or '#ColorSub#')
    SKIN:Bang('!SetOption', 'BgRandomT', 'FontColor', rnd == 1 and '#ColorGold#' or '#ColorSub#')
    local badgeCell = (rnd == 1) and 13 or cur
    local col = badgeCell % g.cols
    local row = math.floor(badgeCell / g.cols)
    SKIN:Bang('!SetOption', 'BgBadge', 'X', tostring(g.x + col * (g.cellW + g.gapX) + g.cellW - 20))
    SKIN:Bang('!SetOption', 'BgBadge', 'Y', tostring(g.y + row * (g.cellH + g.gapY) + 4))
end

-- ------------------------- 事件列表（输入区 + 排序列表） -------------------------

local NewEvent = { date = '', desc = '' }   -- 输入区暂存（未提交）

-- 从 24 组存储键读取全部事件
local function LoadEvents()
    local list = {}
    for i = 1, SPEC_SLOTS do
        local d = SKIN:GetVariable('SpecDateTime' .. i, '')
        if d ~= '' then
            list[#list + 1] = {
                date  = d,
                color = SKIN:GetVariable('SpecDateColor' .. i, ''),
                desc  = SKIN:GetVariable('SpecDateDesc' .. i, ''),
            }
        end
    end
    return list
end

-- 排序键：距今最近 → 最远 → 过期 → 循环（循环永远最后，按月日排）
local function EventSortKey(e)
    local y, m, d = e.date:match('^(%d%d%d%d)-(%d%d?)-(%d%d?)$')
    if y then
        local t = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) })
        return math.floor((t - os.time()) / 86400)
    end
    local mm, dd = e.date:match('^(%d+)-(%d+)$')
    return 100000 + (tonumber(mm) or 0) * 100 + (tonumber(dd) or 0)
end

local function SortEvents(list)
    table.sort(list, function(a, b) return EventSortKey(a) < EventSortKey(b) end)
end

-- 事件变更统一提交：序列化回 24 组键 + 同步两个皮肤 + 单次渲染
local function CommitEvents(list)
    for i = 1, SPEC_SLOTS do
        local e = list[i]
        local dt = e and e.date or ''
        local dc = e and e.color or ''
        local dd = e and e.desc or ''
        Common.WriteVar('SpecDateTime' .. i, dt)
        Common.WriteVar('SpecDateColor' .. i, dc)
        Common.WriteVar('SpecDateDesc' .. i, dd)
        SKIN:Bang('!SetVariable', 'SpecDateTime' .. i, dt)
        SKIN:Bang('!SetVariable', 'SpecDateColor' .. i, dc)
        SKIN:Bang('!SetVariable', 'SpecDateDesc' .. i, dd)
        SKIN:Bang('!SetVariable', 'SpecDateTime' .. i, dt, 'AmphoreusCalendar')
        SKIN:Bang('!SetVariable', 'SpecDateColor' .. i, dc, 'AmphoreusCalendar')
        SKIN:Bang('!SetVariable', 'SpecDateDesc' .. i, dd, 'AmphoreusCalendar')
    end
    SKIN:Bang('!CommandMeasure', 'Script', 'ForceRender()', 'AmphoreusCalendar')
    SKIN:Bang('!UpdateMeter', '*', 'AmphoreusCalendar')
    SKIN:Bang('!UpdateMeter', '*', 'AmphoreusCalendar')
    SKIN:Bang('!Redraw', 'AmphoreusCalendar')
end

-- 渲染事件列表（6 行/页；每行：日期 + 描述 + 色块 + 删除按钮）
local function RenderSpecList(p)
    local list = LoadEvents()
    local totalPages = math.max(1, math.ceil(#list / SPEC_ROWS))
    SpecListPage = Common.ClampInt(p, 1, totalPages, 1)
    for row = 1, SPEC_ROWS do
        local idx = (SpecListPage - 1) * SPEC_ROWS + row
        local e = list[idx]
        SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'DateText', 'Text', e and e.date or '')
        SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'DescText', 'Text', e and e.desc or '')
        if e then
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'DateBox', 'Shape',
                'Rectangle 0,0,98,24,5 | StrokeWidth 1 | Stroke Color #ColorBorder# | Fill Color #ColorInput#')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'DescBox', 'Shape',
                'Rectangle 0,0,308,24,5 | StrokeWidth 1 | Stroke Color #ColorBorder# | Fill Color #ColorInput#')
            local c = (e.color ~= '') and e.color or SKIN:GetVariable('SpecDateColor', '227,203,165')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'Color', 'Shape',
                'Rectangle 0,0,20,20,4 | StrokeWidth 1 | Stroke Color #ColorBorder# | Fill Color ' .. c)
        else
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'DateBox', 'Shape',
                'Rectangle 0,0,98,24,5 | StrokeWidth 0 | Fill Color 0,0,0,0')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'DescBox', 'Shape',
                'Rectangle 0,0,308,24,5 | StrokeWidth 0 | Fill Color 0,0,0,0')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'Color', 'Shape',
                'Rectangle 0,0,20,20,4 | StrokeWidth 0 | Fill Color 0,0,0,0')
        end
        if e then
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'Color', 'LeftMouseUpAction',
                '[!CommandMeasure "Script" "OpenSpecColorPicker(' .. idx .. ')"]')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'DateInput', 'Command1',
                '[!CommandMeasure "Script" "SetEventField(' .. idx .. ', \'date\', \'$UserInput$\')"]')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'DescInput', 'Command1',
                '[!CommandMeasure "Script" "SetEventField(' .. idx .. ', \'desc\', \'$UserInput$\')"]')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'Del', 'Text', '×')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'Del', 'LeftMouseUpAction',
                '[!CommandMeasure "Script" "DeleteSpecEvent(' .. idx .. ')"]')
        else
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'Color', 'LeftMouseUpAction', '')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'DateInput', 'Command1', '')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'DescInput', 'Command1', '')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'Del', 'Text', '')
            SKIN:Bang('!SetOption', 'SpecDate' .. row .. 'Del', 'LeftMouseUpAction', '')
        end
    end
    SKIN:Bang('!SetOption', 'SpecPageInd', 'Text', SpecListPage .. '/' .. totalPages)
    SKIN:Bang('!SetOption', 'SpecListEmpty', 'Hidden', (#list == 0) and '0' or '1')
    Repaint()
end

function SpecPagePrev()
    EnsureLoaded()
    RenderSpecList(SpecListPage - 1)
end

function SpecPageNext()
    EnsureLoaded()
    RenderSpecList(SpecListPage + 1)
end

-- 输入区显示同步（占位提示）
local function SyncNewInputs()
    local d = NewEvent.date
    if d == '' then
        SKIN:Bang('!SetOption', 'SpecNewDateText', 'Text', 'YYYY-MM-DD')
        SKIN:Bang('!SetOption', 'SpecNewDateText', 'FontColor', '#ColorHint#')
    else
        SKIN:Bang('!SetOption', 'SpecNewDateText', 'Text', d)
        SKIN:Bang('!SetOption', 'SpecNewDateText', 'FontColor', '#ColorText#')
    end
    local t = NewEvent.desc
    if t == '' then
        SKIN:Bang('!SetOption', 'SpecNewDescText', 'Text', '事件描述（可选）')
        SKIN:Bang('!SetOption', 'SpecNewDescText', 'FontColor', '#ColorHint#')
    else
        SKIN:Bang('!SetOption', 'SpecNewDescText', 'Text', t)
        SKIN:Bang('!SetOption', 'SpecNewDescText', 'FontColor', '#ColorText#')
    end
    Repaint()
end

-- 输入区字段写入（date / desc）
function SetNewField(field, value)
    EnsureLoaded()
    NewEvent[field] = type(value) == 'string' and value:match('^%s*(.-)%s*$') or ''
    SyncNewInputs()
end

-- 添加事件：校验日期 → 去重 → 排序 → 提交 → 清空输入区
function AddSpecEvent()
    EnsureLoaded()
    local ok, result = Common.ValidateSpecDate(NewEvent.date)
    if not ok then
        SyncNewInputs()
        return
    end
    local list = LoadEvents()
    if #list >= SPEC_SLOTS then return end
    for _, e in ipairs(list) do
        if e.date == result then
            -- 完全重复：更新描述即可
            e.desc = NewEvent.desc
            SortEvents(list)
            CommitEvents(list)
            NewEvent = { date = '', desc = '' }
            SyncNewInputs()
            RenderSpecList(SpecListPage)
            return
        end
    end
    list[#list + 1] = { date = result, desc = NewEvent.desc, color = '' }
    SortEvents(list)
    CommitEvents(list)
    NewEvent = { date = '', desc = '' }
    SyncNewInputs()
    RenderSpecList(SpecListPage)
end

-- 行内编辑事件字段（date 校验、desc 去空白；编辑日期后重排序）
function SetEventField(idx, field, raw)
    EnsureLoaded()
    local list = LoadEvents()
    local e = list[idx]
    if not e then return end
    if field == 'date' then
        local ok, result = Common.ValidateSpecDate(raw)
        if ok then e.date = result end
    elseif field == 'desc' then
        e.desc = type(raw) == 'string' and raw:match('^%s*(.-)%s*$') or ''
    end
    SortEvents(list)
    CommitEvents(list)
    RenderSpecList(SpecListPage)
end

-- 删除事件
function DeleteSpecEvent(idx)
    EnsureLoaded()
    local list = LoadEvents()
    if list[idx] then
        table.remove(list, idx)
        CommitEvents(list)
        RenderSpecList(SpecListPage)
    end
end
-- ------------------------- 全部同步 -------------------------

local function SyncAll()
    for _, key in ipairs(TOGGLES) do
        SetSwitch(key, Common.GetNum(key, 0) == 1)
    end
    for key in pairs(SLIDERS) do
        SliderLayout(key, Common.GetNum(key, 0))
    end
    SyncWeekSeg()
    SyncLangSeg()
    SyncCoverSegs()
    SyncLunarSeg()
    SyncBgThumbs()
end

-- ------------------------- 分页导航 -------------------------

function ShowPage(n)
    EnsureLoaded()
    n = Common.ClampInt(n, 1, PAGE_COUNT, 1)
    CurrentPage = n
    -- 持久化当前页：RainRGB 改色刷新面板后仍停留在本页
    Common.WriteVar('SettingsPage', n)
    SKIN:Bang('!SetVariable', 'SettingsPage', tostring(n))
    for i = 1, PAGE_COUNT do
        SKIN:Bang(i == n and '!ShowMeterGroup' or '!HideMeterGroup', 'Page' .. i)
        SKIN:Bang('!SetOption', 'NavBg' .. i, 'MeterStyle', i == n and 'NavBgOnStyle' or 'NavBgOffStyle')
        SKIN:Bang('!SetOption', 'Nav' .. i,   'MeterStyle', i == n and 'NavTextOnStyle' or 'NavTextOffStyle')
    end
    if n == 3 then RenderSpecList(SpecListPage) end  -- ShowMeterGroup 会覆盖空态提示的 Hidden，重渲染恢复
    Repaint()
end

function HoverNav(n, over)
    EnsureLoaded()
    if n == CurrentPage then return end
    SKIN:Bang('!SetOption', 'NavBg' .. n, 'MeterStyle', tonumber(over) == 1 and 'NavBgHoverStyle' or 'NavBgOffStyle')
    SKIN:Bang('!UpdateMeter', 'NavBg' .. n)
    SKIN:Bang('!Redraw')
end

-- ------------------------- 通用入口（面板调用） -------------------------

function Toggle(key)
    EnsureLoaded()
    local newVal = 1 - Common.GetNum(key, 0)
    ApplyVar(key, newVal)
    SetSwitch(key, newVal == 1)
    Repaint()
end

function SetWeekFormat(v)
    EnsureLoaded()
    v = Common.ClampInt(v, 0, 1, 0)
    ApplyVar('WeekFormatType', v)
    SyncWeekSeg()
    Repaint()
end

-- 星期语言（0=EN 1=中文）
function SetWeekLang(v)
    EnsureLoaded()
    v = Common.ClampInt(v, 0, 1, 0)
    ApplyVar('WeekLanguage', v)
    SyncLangSeg()
    Repaint()
end
function SetBg(n)
    EnsureLoaded()
    n = Common.ClampInt(n, 0, BG_ITEM_COUNT, 0)
    ApplyVars({ BgRandomMode = 0, FixBgItemNum = n })
    SyncBgThumbs()
    Repaint()
end

-- 随机背景模式（0/1；进入或重击时立即重摇）
-- 进入(v=1)：先写入变量但不渲染，由 PickRandomBg 选新图后一次性渲染，避免旧随机图闪帧
function SetBgRandom(v)
    EnsureLoaded()
    v = Common.ClampInt(v, 0, 1, 0)
    if v == 1 then
        Common.WriteVar('BgRandomMode', 1)
        SKIN:Bang('!SetVariable', 'BgRandomMode', '1')
        SKIN:Bang('!SetVariable', 'BgRandomMode', '1', 'AmphoreusCalendar')
        SKIN:Bang('!CommandMeasure', 'Script', 'PickRandomBg()', 'AmphoreusCalendar')
    else
        ApplyVar('BgRandomMode', 0)
    end
    SyncBgThumbs()
    Repaint()
end

function SetLunarViewMode(v)
    EnsureLoaded()
    v = Common.ClampInt(v, 0, LUNAR_MODE_COUNT - 1, 0)
    ApplyVar('LunarViewMode', v)
    SyncLunarSeg()
    Repaint()
end

-- 滑块统一设置：外观 + 落盘
local function SetSlider(key, v)
    local s = SLIDERS[key]
    v = Common.ClampInt(v, s[1], s[2], s[1])
    SliderLayout(key, v)
    if key == 'Scalepercent' then
        local sv = string.format('%.2f', v / 100)
        Common.WriteVar('Scale', sv)
        SKIN:Bang('!SetVariable', 'Scale', sv, 'AmphoreusCalendar')
    end
    ApplyVar(key, v)
    Repaint()
end

function SliderSet(key, v)
    EnsureLoaded()
    SetSlider(key, tonumber(v) or 0)
end

function SliderJump(key, pct)
    EnsureLoaded()
    local s = SLIDERS[key]
    local v = s[1] + (tonumber(pct) or 0) / 100 * (s[2] - s[1])
    SetSlider(key, v)
end

function SliderStep(key, delta)
    EnsureLoaded()
    SetSlider(key, Common.GetNum(key, 0) + (tonumber(delta) or 0))
end

function SetCoverMode(v)
    EnsureLoaded()
    ApplyVar('CalendarCoverMode', Common.ClampInt(v, 1, COVER_MODE_COUNT, COVER_MODE_COUNT))
    SyncCoverSegs()
    Repaint()
end

-- 打开日期专属颜色选择器：RainRGB 无法解析空值会静默退出，
-- 因此先给空槽位补写全局色，再启动取色器
function OpenSpecColorPicker(slot)
    EnsureLoaded()
    slot = Common.ClampInt(slot, 1, SPEC_SLOTS, 1)
    local key = 'SpecDateColor' .. slot
    local cur = SKIN:GetVariable(key, '')
    if cur == '' then
        cur = SKIN:GetVariable('SpecDateColor', '227,203,165')
        Common.WriteVar(key, cur)
    end
    SKIN:Bang('[#@#Addons\\RainRGB4.exe VarName=' .. key .. ' FileName=#@#Configs\\Variables.inc RefreshConfig=#CURRENTCONFIG#]')
end
-- 恢复出厂设置（低频操作：整体刷新两个皮肤，回到第一页）
function ResetToDefaults()
    EnsureLoaded()
    for _, e in ipairs(Common.ReadIni(Common.DefaultsPath())) do
        Common.WriteVar(e.key, e.value)
    end
    SKIN:Bang('!Refresh', 'AmphoreusCalendar')
    SKIN:Bang('!Refresh')
end

-- ------------------------- Rainmeter 入口 -------------------------

function Initialize()
    EnsureLoaded()
    SKIN:Bang('!Refresh', 'AmphoreusCalendar')
    SyncAll()
    SyncNewInputs()
    RenderSpecList(1)
    ShowPage(Common.GetNum('SettingsPage', 1))
end

function Update()
end
