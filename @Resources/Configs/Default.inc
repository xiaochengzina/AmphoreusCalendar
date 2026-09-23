[Variables]
; ============================================================================
; Factory default settings - used by 'Reset to defaults' in the control panel.
; Keep keys in sync with Variables.inc (same key set, default values).
; ============================================================================

; ---- Background ----
; Fixed background image index (0 = auto-switch by month, 1-12 = fixed image)
FixBgItemNum=0
; Random background at load (0 = off, 1 = on; overrides FixBgItemNum)
BgRandomMode=0
; Last random pick (1-12, avoids repeat)
LastRandomBg=
; Timestamp of last random pick (re-roll only on cold start, gap > 300s)
LastRandomTime=
; Month watermark on background (0 = off, 1 = on)
MonthShowOrHide=0
; Month watermark opacity (0-255)
MonthRecogColorAlpha=10
; Background corner radius (0-100)
BgRoundedSize=14

; ---- Calendar style ----
; Week format (0 = Sunday first, 1 = Monday first)
WeekFormatType=0
; Week header language (0 = EN, 1 = CN)
WeekLanguage=0
; Week header text color
WeekColor=255,255,255
; Date text color
DateColor=255,255,255
; Today text color
CurrentDateColor=227,203,165
; Today rounded-rect marker (0 = off, 1 = on)
CurrentDateRecogStyle=0
; Today marker corner radius (0-20)
CurrentDateRecogRoundedSize=4
; Today marker color
CurrentDateRecogColor=227,203,165

; ---- Special dates (Mobius strip marks) ----
; Special date marks (0 = off, 1 = on)
; Mobius strip color
SpecDateColor=227,203,165

; Per-date mark colors (empty = use SpecDateColor above)
SpecDateColor1=
SpecDateColor2=
SpecDateColor3=
SpecDateColor4=
SpecDateColor5=
SpecDateColor6=
SpecDateColor7=
SpecDateColor8=
SpecDateColor9=
SpecDateColor10=
SpecDateColor11=
SpecDateColor12=
SpecDateColor13=
SpecDateColor14=
SpecDateColor15=
SpecDateColor16=
SpecDateColor17=
SpecDateColor18=
SpecDateColor19=
SpecDateColor20=
SpecDateColor21=
SpecDateColor22=
SpecDateColor23=
SpecDateColor24=
; Special date list (YYYY-MM-DD, up to 12, empty = unused)
SpecDateTime1=
SpecDateTime2=
SpecDateTime3=
SpecDateTime4=
SpecDateTime5=
SpecDateTime6=
SpecDateTime7=
SpecDateTime8=
SpecDateTime9=
SpecDateTime10=
SpecDateTime11=
SpecDateTime12=
SpecDateTime13=
SpecDateTime14=
SpecDateTime15=
SpecDateTime16=
SpecDateTime17=
SpecDateTime18=
SpecDateTime19=
SpecDateTime20=
SpecDateTime21=
SpecDateTime22=
SpecDateTime23=
SpecDateTime24=

; ---- Lunar view (0=off 1=hover 2=auto) ----
LunarViewMode=1
; Seconds between auto switches (10-120)
LunarViewInterval=30
; Seconds lunar view stays (2-30)
LunarViewDuration=5

; Lunar view colors (festival / solar term / lunar day)
FestivalColor=224,84,84
TermColor=140,170,90
LunarDayColor=255,255,255

; ---- Scale ----
; Scale factor (= Scalepercent / 100, written automatically)
Scale=1.00
; Scale percent (1-300)
Scalepercent=100

; ---- Cover ----
; Cover mode (1=yearly 2=monthly 3=daily 4=every load 5=off)
CalendarCoverMode=1
; Last cover click date (YYYY-MM-DD, written automatically)
CalendarCoverClickTime=
; Cover year text color
CalendarCoverTextColor=116,83,16
