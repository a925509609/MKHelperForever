-- ============================================================
-- Shaman_Macros.lua
-- 功能：为萨满祭司创建所有自定义宏（按快捷键绑定）
--       包含元素/增强/恢复三系常用技能宏
-- ============================================================

if WR_PlayerClass ~= "SHAMAN" then return end

local function CreateClassesMacro()
  WR_CreateMacro("NUMPAD1", "/cast [@mouseover,noharm,exists]治疗波;治疗波") -- 1
  WR_CreateMacro("NUMPAD2", "/CAST 元素的召唤") -- 2
  WR_CreateMacro("NUMPAD3", "/CAST 风暴打击") -- 3
  WR_CreateMacro("NUMPAD4", "/CAST 闪电箭") -- 4
  WR_CreateMacro("NUMPAD5", "/CAST 烈焰震击") -- 5
  WR_CreateMacro("NUMPAD6", "/CAST 熔岩图腾") -- 6
  WR_CreateMacro("NUMPAD7", "/CAST 闪电之盾") -- 7
  WR_CreateMacro("NUMPAD8", "/CAST 大地震击") -- 8
  WR_CreateMacro("NUMPAD9", "/run DestroyTotem(1)") -- 9（/run 由 WR_CreateMacro 自动改走按键直执行 Lua，避免自定义脚本弹窗）
  WR_CreateMacro("NUMPAD0", "/CAST 熔岩猛击") -- 10
  WR_CreateMacro("CTRL-NUMPAD1", "/CAST 闪电链") -- 11
  WR_CreateMacro("CTRL-NUMPAD2", "/cast [target=focus,exists] 风剪;风剪") -- 12
  WR_CreateMacro("CTRL-NUMPAD3", "/CAST 萨满之怒") -- 13
  WR_CreateMacro("CTRL-NUMPAD4", "") -- 14
  WR_CreateMacro("CTRL-NUMPAD5", "/CAST 大地之力图腾") -- 15
  WR_CreateMacro("CTRL-NUMPAD6", "/STOPATTACK") -- 16
  WR_CreateMacro("CTRL-NUMPAD7", "/cast 风剪") -- 17
  WR_CreateMacro("CTRL-NUMPAD8", "/petpassive\n/cast 野性狼魂\n/petpassive") -- 18
  WR_CreateMacro("CTRL-NUMPAD9", "/cast 嗜血\n/cast 英勇") -- 19
  WR_CreateMacro("CTRL-NUMPAD0", "/cast 血性狂怒(种族特长)\n/use 13\n/use 14\n/cast 狮心\n/USE 10\n/cast 火元素图腾") -- 20
  WR_CreateMacro("ALT-NUMPAD1", "/startattack") -- 21
  WR_CreateMacro("ALT-NUMPAD2", "/cast 水之护盾") -- 22
  WR_CreateMacro("ALT-NUMPAD3", "/cast 净化术") -- 23
  WR_CreateMacro("ALT-NUMPAD4", "/cast [@mouseover,noharm,exists]治疗链;治疗链") -- 24
  WR_CreateMacro("ALT-NUMPAD5", "/cast 土元素图腾") -- 25
  WR_CreateMacro("ALT-NUMPAD6", "/CAST 火焰新星") -- 26
  WR_CreateMacro("ALT-NUMPAD7", "/cast 火舌武器") -- 27
  WR_CreateMacro("ALT-NUMPAD8", "/cast 血性狂怒(种族特长)\n/use 13\n/use 14\n/cast 狮心\n/USE 10\n/cast 元素掌握") -- 28
  WR_CreateMacro("ALT-NUMPAD9", "/cast 雷霆风暴") -- 29
  WR_CreateMacro("ALT-NUMPAD0", "/cast 冰霜震击") -- 30
  WR_CreateMacro("ALT-CTRL-NUMPAD1", "/cast 熔岩爆裂") -- 31
  WR_CreateMacro("ALT-CTRL-NUMPAD2", "/cast 闪电箭") -- 32
  WR_CreateMacro("ALT-CTRL-NUMPAD3", "/cast 战栗图腾") -- 33
  WR_CreateMacro("ALT-CTRL-NUMPAD4", "/use [@none] 火舌武器(等级 9)\n/use 16\n/click StaticPopup1Button1") -- 34
  WR_CreateMacro("ALT-CTRL-NUMPAD5", "/use [@none] 火舌武器\n/use 17\n/click StaticPopup1Button1") -- 35
  WR_CreateMacro("ALT-CTRL-NUMPAD6", "/use [@none] 风怒武器\n/use 16\n/click StaticPopup1Button1") -- 36
  WR_CreateMacro("ALT-CTRL-NUMPAD7", "/petattack\n/cast 幽魂步") -- 37
  WR_CreateMacro("ALT-CTRL-NUMPAD8", "/cast 先祖的召唤") -- 38
  WR_CreateMacro("ALT-CTRL-NUMPAD9", "/cast 灵魂的召唤") -- 39
  WR_CreateMacro("ALT-CTRL-NUMPAD0", "/cast 血性狂怒(种族特长)\n/cast 狂暴(种族特长)\n/use 13\n/use 14\n/cast 狮心\n/USE 10") -- 40
  WR_CreateMacro("SHIFT-F1", "/stopcasting") -- 41
  WR_CreateMacro("SHIFT-F2", "/use 10") -- 42
  WR_CreateMacro("SHIFT-F3", "/cast 元素掌握") -- 43
  WR_CreateMacro("SHIFT-F11", "/use 邪能治疗石") -- 44
  WR_CreateMacro("SHIFT-F5", "/cast 灼热图腾") -- 45
  WR_CreateMacro("SHIFT-F6", "/use [@player] 通用热力工程炸药\n/use [@player] 萨隆邪铁炸弹") -- 46
  WR_CreateMacro("SHIFT-F7", "/cast [@cursor] 萨隆邪铁炸弹") -- 47
  WR_CreateMacro("SHIFT-F8", "/USE 香辣猛犸小吃") -- 48
  WR_CreateMacro("SHIFT-F12", "/cast [target=focus] 烈焰震击") -- 49
  WR_CreateMacro("SHIFT-F10", "/cast [target=mouseover] 烈焰震击") -- 50
  WR_CreateMacro("CTRL-F1", "/use [@player] 萨隆邪铁炸弹") -- 51
  WR_CreateMacro("CTRL-F2", "/cast 治疗链") -- 52
  WR_CreateMacro("CTRL-F3", "/cast 火舌武器") -- 53
  WR_CreateMacro("CTRL-F11", "/cast 熔岩强击") -- 54
  WR_CreateMacro("CTRL-F5", "/cast 根基图腾") -- 55
  WR_CreateMacro("CTRL-F6", "/tar 强力火元素\n/focus\n/targetlasttarget") -- 56
  WR_CreateMacro("CTRL-F7", "/cast [target=focus] 驱毒术") -- 57
  WR_CreateMacro("CTRL-F8", "/tar 庞然火元素\n/focus\n/targetlasttarget") -- 58
  WR_CreateMacro("CTRL-F12", "") -- 59
  WR_CreateMacro("CTRL-F10", "/use [@player] 萨隆邪铁炸弹") -- 60
  WR_CreateMacro("ALT-CTRL-F1", "") -- 61
  WR_CreateMacro("ALT-CTRL-F2", "") -- 62
  WR_CreateMacro("ALT-CTRL-F3", "") -- 63
  WR_CreateMacro("ALT-CTRL-F11", "/cast [target=focus] 净化术") -- 64 对焦点敌方进攻驱散，保留当前目标作为治疗目标
  WR_CreateMacro("ALT-CTRL-F5", "/use 8") -- 65
  WR_CreateMacro("ALT-CTRL-F6", "/cast 血性狂怒(种族特长)\n/cast 狂暴(种族特长)\n/use 13\n/use 14\n/cast 狮心\n/USE 10") -- 66
  WR_CreateMacro("ALT-CTRL-F7", "/cast 血性狂怒(种族特长)\n/use 13\n/use 14\n/cast 狮心\n/USE 10\n/cast 元素掌握") -- 67
  WR_CreateMacro("ALT-CTRL-F8", "/use 速度药水") -- 68
  WR_CreateMacro("ALT-CTRL-F12", "/target 黑暗邪使艾蒂丝") -- 69
  WR_CreateMacro("ALT-CTRL-F10", "/target 光明邪使菲奥拉") -- 70
  WR_CreateMacro("CTRL-SHIFT-F1", "/cast [@focus] 净化灵魂") -- 71
  WR_CreateMacro("CTRL-SHIFT-F2", "/cast 潮汐之力") -- 72
  WR_CreateMacro("CTRL-SHIFT-F3", "/cast [@focus] 先祖之魂") -- 73
  WR_CreateMacro("CTRL-SHIFT-F11", "/cast 自然迅捷") -- 74
  WR_CreateMacro("CTRL-SHIFT-F5", "/cast [@focus] 治疗链") -- 75
  WR_CreateMacro("CTRL-SHIFT-F6", "/cast [@focus] 次级治疗波") -- 76
  WR_CreateMacro("CTRL-SHIFT-F7", "/cast 元素的召唤") -- 77
  WR_CreateMacro("CTRL-SHIFT-F8", "/cast 收回图腾") -- 78
  WR_CreateMacro("CTRL-SHIFT-F12", "/cast [@focus] 大地之盾") -- 79
  WR_CreateMacro("CTRL-SHIFT-F10", "/cast 大地生命武器") -- 80
  WR_CreateMacro("ALT-CTRL-SHIFT-F1", "/cast [@focus] 激流") -- 81
  WR_CreateMacro("ALT-CTRL-SHIFT-F2", "/cast [@focus] 治疗波") -- 82
  WR_CreateMacro("ALT-CTRL-SHIFT-F3", "/cast 法力之潮图腾") -- 83
  WR_CreateMacro("ALT-CTRL-SHIFT-F11", "") -- 84
  WR_CreateMacro("ALT-CTRL-SHIFT-F5", "") -- 85
  WR_CreateMacro("ALT-CTRL-SHIFT-F6", "") -- 86
  WR_CreateMacro("ALT-CTRL-SHIFT-F7", "") -- 87
  WR_CreateMacro("ALT-CTRL-SHIFT-F8", "") -- 88
  WR_CreateMacro("ALT-CTRL-SHIFT-F12", "") -- 89
  WR_CreateMacro("ALT-CTRL-SHIFT-F10", "/targetenemy") -- 90
  WR_CreateMacro("ALT-F1", "") -- 91
  WR_CreateMacro("ALT-F2", "") -- 92
  WR_CreateMacro("ALT-F3", "") -- 93
  WR_CreateMacro("ALT-F11", "") -- 94
  WR_CreateMacro("ALT-F5", "") -- 95
  WR_CreateMacro("ALT-F6", "") -- 96
  WR_CreateMacro("ALT-F7", "/focus party1target") -- 97
  WR_CreateMacro("ALT-F8", "/focus party2target") -- 98
  WR_CreateMacro("ALT-F12", "/focus party3target") -- 99
  WR_CreateMacro("ALT-F10", "/focus party4target") -- 100
  WR_CreateMacro("ALT-SHIFT-F1", "") -- 101
  WR_CreateMacro("ALT-SHIFT-F2", "") -- 102
  WR_CreateMacro("ALT-SHIFT-F3", "") -- 103
  WR_CreateMacro("ALT-SHIFT-F11", "") -- 104
  WR_CreateMacro("ALT-SHIFT-F5", "") -- 105
  WR_CreateMacro("ALT-SHIFT-F6", "") -- 106
  WR_CreateMacro("ALT-SHIFT-F7", "") -- 107
  WR_CreateMacro("ALT-SHIFT-F8", "") -- 108
  WR_CreateMacro("ALT-SHIFT-F12", "") -- 109
  WR_CreateMacro("ALT-SHIFT-F10", "") -- 110
  WR_CreateMacro("ALT-CTRL-SHIFT--", "") -- 111
  WR_CreateMacro("CTRL-SHIFT--", "") -- 112
  WR_CreateMacro("ALT-CTRL--", "") -- 113
  WR_CreateMacro("ALT-SHIFT--", "") -- 114
    WR_CreateMacro("CTRL--", "/follow target") -- 115
    WR_CreateMacro("SHIFT--", "/focus [@target,exists,nodead]") -- 116
    WR_CreateMacro("ALT--", "/follow focus") -- 117
  WR_CreateMacro("ALT-CTRL-SHIFT-=", "/target 凯雷塞斯王子") -- 118
  WR_CreateMacro("CTRL-SHIFT-=", "/target 塔达拉姆王子") -- 119
  WR_CreateMacro("ALT-CTRL-=", "/target 瓦拉纳王子") -- 120
  WR_CreateMacro("ALT-SHIFT-=", "/focus raid1") -- 121
  WR_CreateMacro("CTRL-=", "/focus raid2") -- 122
  WR_CreateMacro("SHIFT-=", "/focus raid3") -- 123
  WR_CreateMacro("ALT-=", "/focus raid4") -- 124
  WR_CreateMacro("ALT-CTRL-SHIFT-[", "/focus raid5") -- 125
  WR_CreateMacro("CTRL-SHIFT-[", "/focus raid6") -- 126
  WR_CreateMacro("ALT-CTRL-[", "/focus raid7") -- 127
  WR_CreateMacro("ALT-SHIFT-[", "/focus raid8") -- 128
  WR_CreateMacro("CTRL-[", "/focus raid9") -- 129
  WR_CreateMacro("SHIFT-[", "/focus raid10") -- 130
  WR_CreateMacro("ALT-[", "/focus raid11") -- 131
  WR_CreateMacro("ALT-CTRL-SHIFT-]", "/focus raid12") -- 132
  WR_CreateMacro("CTRL-SHIFT-]", "/focus raid13") -- 133
  WR_CreateMacro("ALT-CTRL-]", "/focus raid14") -- 134
  WR_CreateMacro("ALT-SHIFT-]", "/focus raid15") -- 135
  WR_CreateMacro("CTRL-]", "/focus raid16") -- 136
  WR_CreateMacro("SHIFT-]", "/focus raid17") -- 137
  WR_CreateMacro("ALT-]", "/focus raid18") -- 138
  WR_CreateMacro("ALT-CTRL-SHIFT-\\", "/focus raid19") -- 139
  WR_CreateMacro("CTRL-SHIFT-\\", "/focus raid20") -- 140
  WR_CreateMacro("ALT-CTRL-\\", "/focus raid21") -- 141
  WR_CreateMacro("ALT-SHIFT-\\", "/focus raid22") -- 142
  WR_CreateMacro("CTRL-\\", "/focus raid23") -- 143
  WR_CreateMacro("SHIFT-\\", "/focus raid24") -- 144
  WR_CreateMacro("ALT-\\", "/focus raid25") -- 145
  WR_CreateMacro("ALT-CTRL-SHIFT-,", "/focus player") -- 146
  WR_CreateMacro("CTRL-SHIFT-,", "/focus target") -- 147
  WR_CreateMacro("ALT-CTRL-,", "/focus mouseover") -- 148
  WR_CreateMacro("ALT-SHIFT-,", "") -- 149
  WR_CreateMacro("CTRL-,", "") -- 150
  WR_CreateMacro("SHIFT-,", "/focus raid1target") -- 151
  WR_CreateMacro("ALT-,", "/focus raid2target") -- 152
  WR_CreateMacro("ALT-CTRL-SHIFT-.", "/focus raid3target") -- 153
  WR_CreateMacro("CTRL-SHIFT-.", "/focus raid4target") -- 154
  WR_CreateMacro("ALT-CTRL-.", "/focus raid5target") -- 155
  WR_CreateMacro("ALT-SHIFT-.", "/focus raid6target") -- 156
  WR_CreateMacro("CTRL-.", "/focus raid7target") -- 157
  WR_CreateMacro("SHIFT-.", "/focus raid8target") -- 158
  WR_CreateMacro("ALT-.", "/focus raid9target") -- 159
  WR_CreateMacro("ALT-CTRL-SHIFT-/", "/focus raid10target") -- 160
  WR_CreateMacro("CTRL-SHIFT-/", "/focus raid11target") -- 161
  WR_CreateMacro("ALT-CTRL-/", "/focus raid12target") -- 162
  WR_CreateMacro("ALT-SHIFT-/", "/focus raid13target") -- 163
  WR_CreateMacro("CTRL-/", "/focus raid14target") -- 164
  WR_CreateMacro("SHIFT-/", "/focus raid15target") -- 165
  WR_CreateMacro("ALT-/", "/focus raid16target") -- 166
  WR_CreateMacro("ALT-CTRL-SHIFT-INSERT", "/focus raid17target") -- 167
  WR_CreateMacro("CTRL-SHIFT-INSERT", "/focus raid18target") -- 168
  WR_CreateMacro("ALT-CTRL-INSERT", "/focus raid19target") -- 169
  WR_CreateMacro("ALT-SHIFT-INSERT", "/focus raid20target") -- 170
  WR_CreateMacro("CTRL-INSERT", "/focus raid21target") -- 171
  WR_CreateMacro("SHIFT-INSERT", "/focus raid22target") -- 172
  WR_CreateMacro("ALT-INSERT", "/focus raid23target") -- 173
  WR_CreateMacro("ALT-CTRL-SHIFT-PAGEUP", "/focus raid24target") -- 174
  WR_CreateMacro("CTRL-SHIFT-PAGEUP", "/focus raid25target") -- 175
  WR_CreateMacro("ALT-CTRL-PAGEUP", "/focus party1") -- 176
  WR_CreateMacro("ALT-SHIFT-PAGEUP", "/focus party2") -- 177
  WR_CreateMacro("CTRL-PAGEUP", "/focus party3") -- 178
  WR_CreateMacro("SHIFT-PAGEUP", "/focus party4") -- 179
  WR_CreateMacro("ALT-PAGEUP", "/use 10") -- 180
  WR_CreateMacro("ALT-CTRL-SHIFT-PAGEDOWN", "/cast 血性狂怒\n/cast 狂暴\n/cast 狮心") -- 181
  WR_CreateMacro("CTRL-SHIFT-PAGEDOWN", "/use 13\n/use 14\n/cast 狮心") -- 182
  WR_CreateMacro("ALT-CTRL-PAGEDOWN", "/cast 速度药水") -- 183
  WR_CreateMacro("ALT-SHIFT-PAGEDOWN", "/cast 狂野魔精药水\n/use 狂野魔法药水") -- 184
  WR_CreateMacro("CTRL-PAGEDOWN", "/use [@player] 通用热力工程炸药") -- 185
  WR_CreateMacro("SHIFT-PAGEDOWN", "/use [@player] 萨隆邪铁炸弹") -- 186
  WR_CreateMacro("ALT-PAGEDOWN", "/cast [@cursor] 萨隆邪铁炸弹") -- 187
  WR_CreateMacro("ALT-CTRL-SHIFT-NUMPADDIVIDE", "/use 邪能治疗石") -- 188
  WR_CreateMacro("ALT-CTRL-NUMPADDIVIDE", "/use 8") -- 189
  WR_CreateMacro("CTRL-NUMPADDIVIDE", "/startattack") -- 190
  WR_CreateMacro("ALT-NUMPADDIVIDE", "/cancelaura 保护之手\n/cancelaura 能量灌注\n/cancelaura 专注魔法") -- 191
  WR_CreateMacro("ALT-CTRL-NUMPADMULTIPLY", "/focus player") -- 192
  WR_CreateMacro("CTRL-NUMPADMULTIPLY", "") -- 193
  WR_CreateMacro("ALT-NUMPADMULTIPLY", "") -- 194
  WR_CreateMacro("ALT-CTRL-NUMPADMINUS", "") -- 195
  WR_CreateMacro("CTRL-NUMPADMINUS", "") -- 196
  WR_CreateMacro("ALT-NUMPADMINUS", "") -- 197
  WR_CreateMacro("ALT-CTRL-NUMPADPLUS", "") -- 198
  WR_CreateMacro("CTRL-NUMPADPLUS", "") -- 199
  WR_CreateMacro("ALT-NUMPADPLUS", "") -- 200
end

-- ============================================================
-- ★ 进入世界/脱离战斗时创建宏
-- ============================================================
local WR_EventFrame = CreateFrame("Frame")
WR_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
WR_EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
WR_EventFrame:SetScript("OnEvent", function(self, event, ...)
  if UnitClassBase("player") == "SHAMAN" and not InCombatLockdown() then
    CreateClassesMacro()
  end
end)

-- ============================================================
-- ★ SoD 宏槽层：WR_SkillColor[SHAMAN]（技能名 -> 颜色槽位 1-199）
--   由脚本依据本文件 WR_CreateMacro 注释槽位 + 各旋转调用自动生成；
--   旋转统一用 WR_ColorFrame_ShowSkill(技能名) 取槽位，优先此处，缺失回退原数值。
--   所有槽位强制落在 1-199（职业专用）；200-240 为 Core/Global_Macros.lua 全局保留，严禁占用。
--   未在此表的符文新技能已自动分配到空闲职业槽；如需 AHK 按键请在各 WR_CreateMacro 补绑定。
-- ============================================================
WR_SkillColor["SHAMAN"] = {
    ["闪电链"] = 11,
    ["烈焰震击"] = 5,
    ["熔岩爆裂"] = 31,
    ["元素掌握"] = 43,
    ["闪电箭"] = 4,
    ["风暴打击"] = 3,
    ["熔岩猛击"] = 10,
    ["大地震击"] = 8,
    ["野性狼魂"] = 18,
    ["萨满之怒"] = 13,
    ["大地之盾"] = 79,
    ["激流"] = 81,
    ["治疗链"] = 52,
    ["治疗波"] = 82,
    ["次级治疗波"] = 76,
    ["净化术"] = 23,
    ["速度药水"] = 183,
    ["潮汐之力"] = 72,
    ["火元素图腾"] = 116,
    ["漩涡武器"] = 120,
    ["治疗之雨"] = 9,
    ["手套"] = 180,
    ["饰品"] = 14,
    ["先知之怒"] = 301,
    ["水之护盾"] = 302,
    ["法力之潮图腾"] = 303,
    ["自然迅捷"] = 304,
}
