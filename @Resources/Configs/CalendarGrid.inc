; ======================================================================
; 日历网格 · 42 格（6行 x 7列），三种 meter 各 42 个：
;   CalRectN   今日高亮圆角框（默认透明）
;   CalDateN   日期文字（默认空）
;   CalMobiusN 特殊日期莫比乌斯环（默认透明）
;
; 定位全部使用公式：列距 41，行距 #GridRowGap#（由 Calendar.lua 按月设置：
; 4行=36 / 5行=27 / 6行=22）。未使用的格子天然不可见，无需隐藏切换。
; 基准坐标：高亮框(54,611)  日期(64,622)  莫比乌斯环(47,614)
; ======================================================================

; 日期文字样式
[CalDateStyle]
FontFace=#FontMain#
W=(41 * #Scale#)
H=(14 * #Scale#)
FontSize=(10 * #Scale#)
AntiAlias=1
FontColor=#DateColor#
StringAlign=CenterCenter
Container=RoundedContainer
DynamicVariables=1

; 今日高亮圆角框样式
[CalRectStyle]
Shape=Rectangle 0,0,(22 * #Scale#),(22 * #Scale#),#CurrentDateRecogRoundedSize# | Fill Color 0,0,0,0 | StrokeWidth (2 * #Scale#) | Stroke Color 0,0,0,0
AntiAlias=1
Container=RoundedContainer
DynamicVariables=1

; 莫比乌斯环样式
[CalMobiusStyle]
W=(35 * #Scale#)
H=(16 * #Scale#)
Shape=Path Path1 | StrokeWidth 0 | Fill Color 0,0,0,0
Shape2=Path Path2 | StrokeWidth 0
Shape3=Path Path3 | StrokeWidth 0
Shape4=Combine Shape1 | XOR Shape2 | XOR Shape3 | Scale (1 * #Scale#),(1 * #Scale#),0,0
Path1=35, 12.12 | CurveTo 27.74, 8.2, 34.71, 8.16, 27.74, 8.2 | CurveTo 19.39, 10.16, 23.44, 8.2, 19.39, 10.16 | CurveTo 3.75, 0, 10.17, -0.44, 3.75, 0 | CurveTo 0.03, 4.28, -0.6, -0.04, 0.03, 4.28 | CurveTo 11.85, 13.64, 1.12, 14.04, 11.85, 13.64 | CurveTo 19.4, 11.28, 16.27, 13.64, 19.4, 11.28 | CurveTo 29.07, 16, 22.68, 15.96, 29.07, 16 | CurveTo 35, 12.12, 35.14, 15.64, 35, 12.12 | ClosePath 1
Path2=11.59, 12.56 | CurveTo 2.29, 5.52, 3.75, 12.16, 2.29, 5.52 | CurveTo 4.92, 2.8, 1.93, 2.4, 4.92, 2.8 | CurveTo 18.7, 10.6, 11.59, 3.56, 18.7, 10.6 | CurveTo 11.59, 12.56, 16.44, 12.56, 11.59, 12.56 | ClosePath 1
Path3=32.85, 11.76 | CurveTo 28.66, 14.4, 33.11, 14.28, 28.66, 14.4 | CurveTo 20.57, 11, 22.97, 14.4, 20.57, 11 | CurveTo 28.04, 9.44, 22.72, 9.36, 28.04, 9.44 | CurveTo 32.85, 11.76, 32.7, 9.72, 32.85, 11.76 | ClosePath 1
AntiAlias=1
Container=RoundedContainer
DynamicVariables=1

; -------------------- CalRect --------------------

[CalRect1]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 0) * #Scale#)
Y=((611 + #GridRowGap# * 0) * #Scale#)

[CalRect2]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 1) * #Scale#)
Y=((611 + #GridRowGap# * 0) * #Scale#)

[CalRect3]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 2) * #Scale#)
Y=((611 + #GridRowGap# * 0) * #Scale#)

[CalRect4]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 3) * #Scale#)
Y=((611 + #GridRowGap# * 0) * #Scale#)

[CalRect5]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 4) * #Scale#)
Y=((611 + #GridRowGap# * 0) * #Scale#)

[CalRect6]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 5) * #Scale#)
Y=((611 + #GridRowGap# * 0) * #Scale#)

[CalRect7]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 6) * #Scale#)
Y=((611 + #GridRowGap# * 0) * #Scale#)

[CalRect8]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 0) * #Scale#)
Y=((611 + #GridRowGap# * 1) * #Scale#)

[CalRect9]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 1) * #Scale#)
Y=((611 + #GridRowGap# * 1) * #Scale#)

[CalRect10]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 2) * #Scale#)
Y=((611 + #GridRowGap# * 1) * #Scale#)

[CalRect11]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 3) * #Scale#)
Y=((611 + #GridRowGap# * 1) * #Scale#)

[CalRect12]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 4) * #Scale#)
Y=((611 + #GridRowGap# * 1) * #Scale#)

[CalRect13]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 5) * #Scale#)
Y=((611 + #GridRowGap# * 1) * #Scale#)

[CalRect14]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 6) * #Scale#)
Y=((611 + #GridRowGap# * 1) * #Scale#)

[CalRect15]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 0) * #Scale#)
Y=((611 + #GridRowGap# * 2) * #Scale#)

[CalRect16]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 1) * #Scale#)
Y=((611 + #GridRowGap# * 2) * #Scale#)

[CalRect17]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 2) * #Scale#)
Y=((611 + #GridRowGap# * 2) * #Scale#)

[CalRect18]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 3) * #Scale#)
Y=((611 + #GridRowGap# * 2) * #Scale#)

[CalRect19]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 4) * #Scale#)
Y=((611 + #GridRowGap# * 2) * #Scale#)

[CalRect20]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 5) * #Scale#)
Y=((611 + #GridRowGap# * 2) * #Scale#)

[CalRect21]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 6) * #Scale#)
Y=((611 + #GridRowGap# * 2) * #Scale#)

[CalRect22]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 0) * #Scale#)
Y=((611 + #GridRowGap# * 3) * #Scale#)

[CalRect23]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 1) * #Scale#)
Y=((611 + #GridRowGap# * 3) * #Scale#)

[CalRect24]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 2) * #Scale#)
Y=((611 + #GridRowGap# * 3) * #Scale#)

[CalRect25]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 3) * #Scale#)
Y=((611 + #GridRowGap# * 3) * #Scale#)

[CalRect26]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 4) * #Scale#)
Y=((611 + #GridRowGap# * 3) * #Scale#)

[CalRect27]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 5) * #Scale#)
Y=((611 + #GridRowGap# * 3) * #Scale#)

[CalRect28]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 6) * #Scale#)
Y=((611 + #GridRowGap# * 3) * #Scale#)

[CalRect29]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 0) * #Scale#)
Y=((611 + #GridRowGap# * 4) * #Scale#)

[CalRect30]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 1) * #Scale#)
Y=((611 + #GridRowGap# * 4) * #Scale#)

[CalRect31]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 2) * #Scale#)
Y=((611 + #GridRowGap# * 4) * #Scale#)

[CalRect32]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 3) * #Scale#)
Y=((611 + #GridRowGap# * 4) * #Scale#)

[CalRect33]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 4) * #Scale#)
Y=((611 + #GridRowGap# * 4) * #Scale#)

[CalRect34]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 5) * #Scale#)
Y=((611 + #GridRowGap# * 4) * #Scale#)

[CalRect35]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 6) * #Scale#)
Y=((611 + #GridRowGap# * 4) * #Scale#)

[CalRect36]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 0) * #Scale#)
Y=((611 + #GridRowGap# * 5) * #Scale#)

[CalRect37]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 1) * #Scale#)
Y=((611 + #GridRowGap# * 5) * #Scale#)

[CalRect38]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 2) * #Scale#)
Y=((611 + #GridRowGap# * 5) * #Scale#)

[CalRect39]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 3) * #Scale#)
Y=((611 + #GridRowGap# * 5) * #Scale#)

[CalRect40]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 4) * #Scale#)
Y=((611 + #GridRowGap# * 5) * #Scale#)

[CalRect41]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 5) * #Scale#)
Y=((611 + #GridRowGap# * 5) * #Scale#)

[CalRect42]
Meter=Shape
MeterStyle=CalRectStyle
X=((54 + 41 * 6) * #Scale#)
Y=((611 + #GridRowGap# * 5) * #Scale#)

; -------------------- CalDate --------------------

[CalDate1]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 0) * #Scale#)
Y=((622 + #GridRowGap# * 0) * #Scale#)

[CalDate2]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 1) * #Scale#)
Y=((622 + #GridRowGap# * 0) * #Scale#)

[CalDate3]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 2) * #Scale#)
Y=((622 + #GridRowGap# * 0) * #Scale#)

[CalDate4]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 3) * #Scale#)
Y=((622 + #GridRowGap# * 0) * #Scale#)

[CalDate5]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 4) * #Scale#)
Y=((622 + #GridRowGap# * 0) * #Scale#)

[CalDate6]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 5) * #Scale#)
Y=((622 + #GridRowGap# * 0) * #Scale#)

[CalDate7]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 6) * #Scale#)
Y=((622 + #GridRowGap# * 0) * #Scale#)

[CalDate8]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 0) * #Scale#)
Y=((622 + #GridRowGap# * 1) * #Scale#)

[CalDate9]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 1) * #Scale#)
Y=((622 + #GridRowGap# * 1) * #Scale#)

[CalDate10]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 2) * #Scale#)
Y=((622 + #GridRowGap# * 1) * #Scale#)

[CalDate11]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 3) * #Scale#)
Y=((622 + #GridRowGap# * 1) * #Scale#)

[CalDate12]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 4) * #Scale#)
Y=((622 + #GridRowGap# * 1) * #Scale#)

[CalDate13]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 5) * #Scale#)
Y=((622 + #GridRowGap# * 1) * #Scale#)

[CalDate14]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 6) * #Scale#)
Y=((622 + #GridRowGap# * 1) * #Scale#)

[CalDate15]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 0) * #Scale#)
Y=((622 + #GridRowGap# * 2) * #Scale#)

[CalDate16]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 1) * #Scale#)
Y=((622 + #GridRowGap# * 2) * #Scale#)

[CalDate17]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 2) * #Scale#)
Y=((622 + #GridRowGap# * 2) * #Scale#)

[CalDate18]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 3) * #Scale#)
Y=((622 + #GridRowGap# * 2) * #Scale#)

[CalDate19]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 4) * #Scale#)
Y=((622 + #GridRowGap# * 2) * #Scale#)

[CalDate20]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 5) * #Scale#)
Y=((622 + #GridRowGap# * 2) * #Scale#)

[CalDate21]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 6) * #Scale#)
Y=((622 + #GridRowGap# * 2) * #Scale#)

[CalDate22]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 0) * #Scale#)
Y=((622 + #GridRowGap# * 3) * #Scale#)

[CalDate23]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 1) * #Scale#)
Y=((622 + #GridRowGap# * 3) * #Scale#)

[CalDate24]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 2) * #Scale#)
Y=((622 + #GridRowGap# * 3) * #Scale#)

[CalDate25]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 3) * #Scale#)
Y=((622 + #GridRowGap# * 3) * #Scale#)

[CalDate26]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 4) * #Scale#)
Y=((622 + #GridRowGap# * 3) * #Scale#)

[CalDate27]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 5) * #Scale#)
Y=((622 + #GridRowGap# * 3) * #Scale#)

[CalDate28]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 6) * #Scale#)
Y=((622 + #GridRowGap# * 3) * #Scale#)

[CalDate29]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 0) * #Scale#)
Y=((622 + #GridRowGap# * 4) * #Scale#)

[CalDate30]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 1) * #Scale#)
Y=((622 + #GridRowGap# * 4) * #Scale#)

[CalDate31]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 2) * #Scale#)
Y=((622 + #GridRowGap# * 4) * #Scale#)

[CalDate32]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 3) * #Scale#)
Y=((622 + #GridRowGap# * 4) * #Scale#)

[CalDate33]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 4) * #Scale#)
Y=((622 + #GridRowGap# * 4) * #Scale#)

[CalDate34]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 5) * #Scale#)
Y=((622 + #GridRowGap# * 4) * #Scale#)

[CalDate35]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 6) * #Scale#)
Y=((622 + #GridRowGap# * 4) * #Scale#)

[CalDate36]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 0) * #Scale#)
Y=((622 + #GridRowGap# * 5) * #Scale#)

[CalDate37]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 1) * #Scale#)
Y=((622 + #GridRowGap# * 5) * #Scale#)

[CalDate38]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 2) * #Scale#)
Y=((622 + #GridRowGap# * 5) * #Scale#)

[CalDate39]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 3) * #Scale#)
Y=((622 + #GridRowGap# * 5) * #Scale#)

[CalDate40]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 4) * #Scale#)
Y=((622 + #GridRowGap# * 5) * #Scale#)

[CalDate41]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 5) * #Scale#)
Y=((622 + #GridRowGap# * 5) * #Scale#)

[CalDate42]
Meter=String
MeterStyle=CalDateStyle
Text=
X=((64 + 41 * 6) * #Scale#)
Y=((622 + #GridRowGap# * 5) * #Scale#)

; -------------------- CalMobius --------------------

[CalMobius1]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 0) * #Scale#)
Y=((614 + #GridRowGap# * 0) * #Scale#)

[CalMobius2]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 1) * #Scale#)
Y=((614 + #GridRowGap# * 0) * #Scale#)

[CalMobius3]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 2) * #Scale#)
Y=((614 + #GridRowGap# * 0) * #Scale#)

[CalMobius4]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 3) * #Scale#)
Y=((614 + #GridRowGap# * 0) * #Scale#)

[CalMobius5]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 4) * #Scale#)
Y=((614 + #GridRowGap# * 0) * #Scale#)

[CalMobius6]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 5) * #Scale#)
Y=((614 + #GridRowGap# * 0) * #Scale#)

[CalMobius7]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 6) * #Scale#)
Y=((614 + #GridRowGap# * 0) * #Scale#)

[CalMobius8]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 0) * #Scale#)
Y=((614 + #GridRowGap# * 1) * #Scale#)

[CalMobius9]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 1) * #Scale#)
Y=((614 + #GridRowGap# * 1) * #Scale#)

[CalMobius10]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 2) * #Scale#)
Y=((614 + #GridRowGap# * 1) * #Scale#)

[CalMobius11]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 3) * #Scale#)
Y=((614 + #GridRowGap# * 1) * #Scale#)

[CalMobius12]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 4) * #Scale#)
Y=((614 + #GridRowGap# * 1) * #Scale#)

[CalMobius13]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 5) * #Scale#)
Y=((614 + #GridRowGap# * 1) * #Scale#)

[CalMobius14]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 6) * #Scale#)
Y=((614 + #GridRowGap# * 1) * #Scale#)

[CalMobius15]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 0) * #Scale#)
Y=((614 + #GridRowGap# * 2) * #Scale#)

[CalMobius16]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 1) * #Scale#)
Y=((614 + #GridRowGap# * 2) * #Scale#)

[CalMobius17]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 2) * #Scale#)
Y=((614 + #GridRowGap# * 2) * #Scale#)

[CalMobius18]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 3) * #Scale#)
Y=((614 + #GridRowGap# * 2) * #Scale#)

[CalMobius19]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 4) * #Scale#)
Y=((614 + #GridRowGap# * 2) * #Scale#)

[CalMobius20]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 5) * #Scale#)
Y=((614 + #GridRowGap# * 2) * #Scale#)

[CalMobius21]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 6) * #Scale#)
Y=((614 + #GridRowGap# * 2) * #Scale#)

[CalMobius22]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 0) * #Scale#)
Y=((614 + #GridRowGap# * 3) * #Scale#)

[CalMobius23]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 1) * #Scale#)
Y=((614 + #GridRowGap# * 3) * #Scale#)

[CalMobius24]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 2) * #Scale#)
Y=((614 + #GridRowGap# * 3) * #Scale#)

[CalMobius25]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 3) * #Scale#)
Y=((614 + #GridRowGap# * 3) * #Scale#)

[CalMobius26]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 4) * #Scale#)
Y=((614 + #GridRowGap# * 3) * #Scale#)

[CalMobius27]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 5) * #Scale#)
Y=((614 + #GridRowGap# * 3) * #Scale#)

[CalMobius28]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 6) * #Scale#)
Y=((614 + #GridRowGap# * 3) * #Scale#)

[CalMobius29]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 0) * #Scale#)
Y=((614 + #GridRowGap# * 4) * #Scale#)

[CalMobius30]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 1) * #Scale#)
Y=((614 + #GridRowGap# * 4) * #Scale#)

[CalMobius31]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 2) * #Scale#)
Y=((614 + #GridRowGap# * 4) * #Scale#)

[CalMobius32]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 3) * #Scale#)
Y=((614 + #GridRowGap# * 4) * #Scale#)

[CalMobius33]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 4) * #Scale#)
Y=((614 + #GridRowGap# * 4) * #Scale#)

[CalMobius34]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 5) * #Scale#)
Y=((614 + #GridRowGap# * 4) * #Scale#)

[CalMobius35]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 6) * #Scale#)
Y=((614 + #GridRowGap# * 4) * #Scale#)

[CalMobius36]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 0) * #Scale#)
Y=((614 + #GridRowGap# * 5) * #Scale#)

[CalMobius37]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 1) * #Scale#)
Y=((614 + #GridRowGap# * 5) * #Scale#)

[CalMobius38]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 2) * #Scale#)
Y=((614 + #GridRowGap# * 5) * #Scale#)

[CalMobius39]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 3) * #Scale#)
Y=((614 + #GridRowGap# * 5) * #Scale#)

[CalMobius40]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 4) * #Scale#)
Y=((614 + #GridRowGap# * 5) * #Scale#)

[CalMobius41]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 5) * #Scale#)
Y=((614 + #GridRowGap# * 5) * #Scale#)

[CalMobius42]
Meter=Shape
MeterStyle=CalMobiusStyle
X=((47 + 41 * 6) * #Scale#)
Y=((614 + #GridRowGap# * 5) * #Scale#)
