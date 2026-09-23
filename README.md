# AmphoreusCalendar · 翁法罗斯年历

崩铁（崩坏：星穹铁道）翁法罗斯主题桌面年历 Rainmeter 皮肤，含独立控制面板。
当前版本 v1.2.0：农历/节气/节日视图、每年循环纪念日、每日期独立颜色、随机背景、节日视图莫比乌斯环。

## 功能一览

- 375×812 主题日历，背景图按月自动切换（1-12.jpg），可指定固定背景，
  或开启「随机」模式：每次加载随机选一张且不与上次重复
- 星期表头支持 周日开头 / 周一开头 两种格式，中英文可选
- 日历网格按当月自动选择 4 / 5 / 6 行布局
- 今日高亮（变色加粗 + 可选圆角框）
- **农历视图**：格内直接显示 节日名/节气名/农历日（初一显示月份名），
  支持 关闭 / 悬停切换 / 自动切换（间隔 10-120s、停留 2-30s 可调），
  节日/节气/农历日颜色各自可调
- **特殊日期**：最多 24 个（分页器），莫比乌斯环标记，支持
  `YYYY-MM-DD`（一次性）与 `MM-DD`（每年循环，生日/纪念日），
  每个日期可设独立颜色（留空用全局色），可附事件描述（悬停环上显示）；
  列表按时间临近自动排序、循环事件居后，行内直接编辑/删除；
  可选在农历视图中同样显示莫比乌斯环
- 背景月份水印（开关 + 透明度可调）
- 封面模式：每年 / 每月 / 每天 / 每次加载 / 关闭，点击封面关闭并记录
- 整体缩放（50%-300%，滑块实时预览）
- 控制面板 v1.2.0：亮色主题 + 左侧导航 7 分页，右键皮肤 →「打开控制面板」
  - 背景缩略图选择墙（Container 圆角裁切，点选即换）
  - 数值设置全部滑块化：点击轨道跳转 / 滚轮微调 / ±按钮
  - 分段选择器（星期格式 / 星期语言 / 农历视图 / 封面模式）
  - 所有设置零刷新即时生效（ForceRender + 变量推送）

## 目录结构

```
AmphoreusCalendar\
├─ AmphoreusCalendar.ini        主皮肤（骨架：容器/背景/水印/星期/封面 + 脚本）
├─ Settings\
│  └─ Settings.ini              控制面板（亮色主题，左导航 7 分页，命名遵循约定）
├─ @Resources\
│  ├─ Configs\
│  │  ├─ Variables.inc          用户设置（面板自动写入，键名勿改）
│  │  ├─ Default.inc            出厂默认值（「恢复默认设置」的数据源）
│  │  └─ CalendarGrid.inc       日历网格：42格 x 3种 meter，公式定位
│  ├─ Scripts\
│  │  ├─ Lunar.lua             农历/节气/节日离线计算（2026-2100 数据表）
│  │  ├─ Common.lua             共享工具（变量读写/日期计算/校验）
│  │  ├─ Calendar.lua           日历主逻辑（渲染管线）
│  │  └─ Settings.lua           面板逻辑（设置项注册表 + 通用入口）
│  ├─ Addons\RainRGB4.exe       取色器
│  ├─ Fonts\                    字体（思源黑体/獅尾圓體/Rouge Script）
│  └─ Images\                   0.jpg=封面, 1-12.jpg=月份背景
```

## 架构要点

- **单一网格**：旧版为 4/5/6 行各维护一份布局文件（315 个手写坐标 meter）。
  现在只有一份 42 格网格，坐标全部用公式表达，行距变量 `#GridRowGap#`
  （36/27/22）由 `Calendar.lua` 按月动态设置，未用格子天然不可见。
- **渲染管线**：`Calendar.lua` 流程为
  `LoadConfig → 星期表头 → 随机背景 → 背景 → 月份水印 → 网格(清空/填日期/今日/标记) → 封面`。
  设置变更由面板即时推送变量并调用 `ForceRender()` 全量重渲染，无增量状态残留。
- **数据驱动面板**：`Settings.lua` 顶部的 `TOGGLES` / `SLIDERS` 是设置项
  注册表，开关样式同步、滑块校验全部走通用逻辑，没有为每个设置写死代码。
  分页由 `ShowPage(n)` 纯显隐切换。
- **即时生效引擎**：设置写入 `Variables.inc` 后，通过 `!SetVariable` 推送到
  主皮肤内存，再调用主皮肤的 `ForceRender()` 公开函数重渲染 —— 全程零刷新，
  不闪动、不跳页，缩放/圆角等调整可实时预览。
- **设置持久化**：只写 `Variables.inc`；`Default.inc` 永不写入，用于重置。

## 如何扩展

**新增一个开关型设置**（例：显示/隐藏某元素）
1. `Variables.inc` 和 `Default.inc` 各加一行 `MyNewToggle=0`；
2. `Settings.lua` 的 `TOGGLES` 表加 `'MyNewToggle'`；
3. `Settings.ini` 仿照现有开关加 `[MyNewToggleBox]` / `[MyNewToggleThumb]`
   两个 meter，动作 `[!CommandMeasure "Script" "Toggle('MyNewToggle')"]`；
4. `Calendar.lua` 的 `LoadConfig` 读取并在渲染中使用。

**新增一个数值型设置**
1. 两个 .inc 加键；2. `SLIDERS` 表加 `MyKey = {最小值, 最大值, 步进}`；
3. 面板仿现有滑块加 `−` / 轨道 / `＋` / 数值一组 meter（命名遵循 `MyKeyMinus`、
   `SltMyKeyHit/Fill/Knob`、`MyKeyPlus`、`SltMyKeyValue`），校验与即时生效全部走通用逻辑。

**新增颜色设置**：两个 .inc 加键 + 面板放一个颜色块 meter，动作为
`["#@#Addons\RainRGB4.exe" "VarName=MyColor" "FileName=#@#Configs\Variables.inc" "RefreshConfig=#CURRENTCONFIG#"]`，无需改 Lua。

**修改日历几何**：网格基准坐标、列距、行距分别在 `CalendarGrid.inc` 头部
注释与 `Calendar.lua` 的 `ROW_GAPS` 中，改数字即可，无需重排 315 个坐标。

## 维护约定

- **编码（实测结论，勿随意更改）**：
  - Rainmeter 直接读取的文件（`.ini`、被 `@include` 的 `.inc`、作为 ScriptFile
    加载的 `Calendar.lua` / `Settings.lua`）必须是 **UTF-16 LE BOM**。
    Rainmeter 的解析器不识别 UTF-8 BOM，会导致脚本报 `unexpected symbol`、
    变量段首行损坏（全部变量未定义）。
  - 仅被 Lua `dofile` / `io.open` 读取的文件（`Common.lua`、`Default.inc`）
    必须是 **UTF-8 无 BOM**（Lua 5.1 不识别任何 BOM，也读不了 UTF-16）。
  - `!WriteKeyValue` / RainRGB4 写入 `Variables.inc` 时会保持其 UTF-16 编码。
- `Variables.inc` 的**键名是兼容契约**：改名会导致老用户设置丢失，
  RainRGB4 与控制面板都按键名写入。
- Lua 中除 `Initialize` / `Update` / 面板与 meter 调用的入口函数外，
  一律使用 `local`，避免污染 Rainmeter Lua 全局环境。
- Rainmeter 执行脚本文件顶层代码时 `SKIN` 对象尚未注入，因此共享模块
  一律通过 `EnsureLoaded()` 在入口函数内延迟 `dofile`，不要在顶层访问 `SKIN`。
