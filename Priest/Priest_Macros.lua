if WR_PlayerClass ~= "PRIEST" then return end

local function CreateClassesMacro()
  WR_CreateMacro("NUMPAD1", "/cast [nochanneling:暗言术：渊]吸血鬼之触") -- 1
  WR_CreateMacro("NUMPAD2", "/CAST[nochanneling:暗言术：渊] 暗言术：痛") -- 2
  WR_CreateMacro("NUMPAD3", "/CAST [nochanneling:暗言术：渊]噬灵疫病") -- 3
  WR_CreateMacro("NUMPAD4", "/cast [nochanneling:暗言术：渊]心灵震爆") -- 4
  WR_CreateMacro("NUMPAD5", "/cast [nochanneling:暗言术：渊]精神鞭笞") -- 5
  WR_CreateMacro("NUMPAD6", "/CAST 暗言术：灭") -- 6
  WR_CreateMacro("NUMPAD7", "/cast [nochanneling:精神鞭笞,nochanneling:暗言术：渊] 暗影魔") -- 7
  WR_CreateMacro("NUMPAD8", "/cast [nostance:1]!暗影形态") -- 8
  WR_CreateMacro("NUMPAD9", "/cancelAura 消散") -- 9
  WR_CreateMacro("NUMPAD0", "/CAST 吸血鬼的拥抱") -- 10
  WR_CreateMacro("CTRL-NUMPAD1", "/stopcasting\n/CAST 消散") -- 11
  WR_CreateMacro("CTRL-NUMPAD2", "/cast [target=focus] 心灵震爆") -- 12
  WR_CreateMacro("CTRL-NUMPAD3", "/cast [target=focus] 吸血鬼之触") -- 13
  WR_CreateMacro("CTRL-NUMPAD4", "/cast [target=focus] 暗言术：痛") -- 14
  WR_CreateMacro("CTRL-NUMPAD5", "/cast [target=mouseover] 吸血鬼之触") -- 15
  WR_CreateMacro("CTRL-NUMPAD6", "/cast [target=mouseover] 暗言术：痛") -- 16
  WR_CreateMacro("CTRL-NUMPAD7", "/cast [target=focus] 精神鞭笞") -- 17
  WR_CreateMacro("CTRL-NUMPAD8", "/cast [target=mouseover] 精神鞭笞") -- 18
  WR_CreateMacro("CTRL-NUMPAD9", "/STOPCASTING") -- 19
  WR_CreateMacro("CTRL-NUMPAD0", "/focus") -- 20
  WR_CreateMacro("ALT-NUMPAD1", "/cast [target=focus,nochanneling:暗言术：渊] 噬灵疫病") -- 21
  WR_CreateMacro("ALT-NUMPAD2", "/CAST [nochanneling:暗言术：渊]狂暴(种族特长)\n/USE [nochanneling:暗言术：渊] 14\n/use [nochanneling:暗言术：渊]13\n/use [nochanneling:暗言术：渊]10") -- 22
  WR_CreateMacro("ALT-NUMPAD3", "/CAST [nochanneling:精神鞭笞,nochanneling:暗言术：渊] 心灵专注") -- 23
  WR_CreateMacro("ALT-NUMPAD4", "/CAST [nochanneling:暗言术：渊]狂暴(种族特长)\n/USE [nochanneling:暗言术：渊]14\n/use [nochanneling:暗言术：渊]13\n/use [nochanneling:暗言术：渊]10\n/USE  速度药水") -- 24
  WR_CreateMacro("ALT-NUMPAD5", "/CAST [nochanneling:暗言术：渊]狂暴(种族特长)\n/USE [nochanneling:暗言术：渊]14\n/use [nochanneling:暗言术：渊]13\n/use [nochanneling:暗言术：渊]10\n/cast [nochanneling:暗言术：渊]吸血鬼之触") -- 25
  WR_CreateMacro("ALT-NUMPAD6", "/cast [nochanneling:精神灼烧] 精神灼烧") -- 26
  WR_CreateMacro("ALT-NUMPAD7", "/cast [target=focus,nochanneling:暗言术：渊] 精神鞭笞(等级 8)") -- 27
  WR_CreateMacro("ALT-NUMPAD8", "/cast [nochanneling:暗言术：渊]精神鞭笞") -- 28
  WR_CreateMacro("ALT-NUMPAD9", "/target 镜像\n/target 裹体之网\n/cast 噬灵疫病") -- 29
  WR_CreateMacro("ALT-NUMPAD0", "/cast [target=mouseover] 心灵震爆") -- 30
  WR_CreateMacro("ALT-CTRL-NUMPAD1", "/CAST [nochanneling:暗言术：渊]心灵之火") -- 31
  WR_CreateMacro("ALT-CTRL-NUMPAD2", "/CAST [nochanneling:暗言术：渊]狂暴(种族特长)\n/USE [nochanneling:暗言术：渊]10\n/use [nochanneling:暗言术：渊]13\n/use [nochanneling:暗言术：渊]14") -- 32
  WR_CreateMacro("ALT-CTRL-NUMPAD3", "/USE  10") -- 33
  WR_CreateMacro("ALT-CTRL-NUMPAD4", "/USE 邪能治疗石") -- 34
  WR_CreateMacro("ALT-CTRL-NUMPAD5", "/cast 神圣赞美诗") -- 35
  WR_CreateMacro("ALT-CTRL-NUMPAD6", "/cast 希望圣歌") -- 36
  WR_CreateMacro("ALT-CTRL-NUMPAD7", "/targetenemy") -- 37
  WR_CreateMacro("ALT-CTRL-NUMPAD8", "/use [@player,nochanneling:精神鞭笞] 通用热力工程炸药\n/use [@player,nochanneling:精神鞭笞] 萨隆邪铁炸弹") -- 38
  WR_CreateMacro("ALT-CTRL-NUMPAD9", "/cast [@cursor,nochanneling:精神鞭笞] 萨隆邪铁炸弹") -- 39
  WR_CreateMacro("ALT-CTRL-NUMPAD0", "/cast [nochanneling:暗言术：渊]心灵震爆") -- 40
  WR_CreateMacro("SHIFT-F1", "/stopcasting\n/cast 暗言术：灭") -- 41
  WR_CreateMacro("SHIFT-F2", "/cast [nochanneling:暗言术：渊]吸血鬼之触") -- 42
  WR_CreateMacro("SHIFT-F3", "/cast [nochanneling:暗言术：渊]暗言术：痛") -- 43
  WR_CreateMacro("SHIFT-F11", "/cast [nochanneling:暗言术：渊]噬灵疫病") -- 44
  WR_CreateMacro("SHIFT-F5", "/USE 香辣猛犸小吃") -- 45
  WR_CreateMacro("SHIFT-F6", "/cast [@player]群体驱散") -- 46
  WR_CreateMacro("SHIFT-F7", "/cast [target=cursor] 群体驱散") -- 47
  WR_CreateMacro("SHIFT-F8", "/use [@player,nochanneling:精神鞭笞] 萨隆邪铁炸弹") -- 48
  WR_CreateMacro("SHIFT-F12", "") -- 49
  WR_CreateMacro("SHIFT-F10", "/cast [@focus] 真言术：盾(等级 11)") -- 50
  WR_CreateMacro("CTRL-F1", "/cast [@focus] 坚韧祷言") -- 51
  WR_CreateMacro("CTRL-F2", "/cast [@focus] 真言术：韧") -- 52
  WR_CreateMacro("CTRL-F3", "/cast [@focus] 治疗祷言") -- 53
  WR_CreateMacro("CTRL-F11", "/cast [@focus] 苦修") -- 54
  WR_CreateMacro("CTRL-F5", "/cast [@focus] 恢复") -- 55
  WR_CreateMacro("CTRL-F6", "/cast [@focus] 联结治疗") -- 56
  WR_CreateMacro("CTRL-F7", "/cast [@focus] 快速治疗") -- 57
  WR_CreateMacro("CTRL-F8", "/cast [@focus] 愈合祷言") -- 58
  WR_CreateMacro("CTRL-F12", "/cast [@focus] 真言术：盾") -- 59
  WR_CreateMacro("CTRL-F10", "/cast [@focus] 真言术：盾(等级 13)") -- 60
  WR_CreateMacro("ALT-CTRL-F1", "/cast [@focus] 真言术：盾(等级 12)") -- 61
  WR_CreateMacro("ALT-CTRL-F2", "/cast [@focus] 驱除疾病") -- 62
  WR_CreateMacro("ALT-CTRL-F3", "/cast [@focus] 驱散魔法") -- 63
  WR_CreateMacro("ALT-CTRL-F11", "/cast [@focus] 痛苦压制\n/cast [@focus] 守护之魂") -- 64
  WR_CreateMacro("ALT-CTRL-F5", "/use 8") -- 65
  WR_CreateMacro("ALT-CTRL-F6", "/cast 心灵震爆") -- 66
  WR_CreateMacro("ALT-CTRL-F7", "/cast [@focustarget] 暗影魔\n/petattack [@focustarget]") -- 67
  WR_CreateMacro("ALT-CTRL-F8", "/CAST  狂暴(种族特长)\n/USE  14\n/use  13\n/use  10\n/USE  速度药水") -- 68
  WR_CreateMacro("ALT-CTRL-F12", "/target 光明邪使菲奥拉\n/focus\n/target 黑暗邪使艾蒂丝") -- 69
  WR_CreateMacro("ALT-CTRL-F10", "/target 黑暗邪使艾蒂丝\n/focus\n/target 光明邪使菲奥拉") -- 70
  WR_CreateMacro("CTRL-SHIFT-F1", "/cast [@focus] 神圣之灵") -- 71
  WR_CreateMacro("CTRL-SHIFT-F2", "/cast [@focus] 精神祷言") -- 72
  WR_CreateMacro("CTRL-SHIFT-F3", "/cast [@focus] 暗影防护祷言") -- 73
  WR_CreateMacro("CTRL-SHIFT-F11", "/cast [@focus] 暗影防护") -- 74
  WR_CreateMacro("CTRL-SHIFT-F5", "/cast [@focus] 复活术") -- 75
  WR_CreateMacro("CTRL-SHIFT-F6", "/cast [@focus] 治疗之环") -- 76
  WR_CreateMacro("CTRL-SHIFT-F7", "/cast [@focus] 强效治疗术") -- 77
  WR_CreateMacro("CTRL-SHIFT-F8", "/cast 驱散魔法") -- 78
  WR_CreateMacro("CTRL-SHIFT-F12", "/cast [target=player] 驱散魔法") -- 79
  WR_CreateMacro("CTRL-SHIFT-F10", "") -- 80
  WR_CreateMacro("ALT-CTRL-SHIFT-F1", "") -- 81
  WR_CreateMacro("ALT-CTRL-SHIFT-F2", "/cast [@focus] 痛苦压制") -- 82 (指向痛苦压制专用)
  WR_CreateMacro("ALT-CTRL-SHIFT-F3", "") -- 83
  WR_CreateMacro("ALT-CTRL-SHIFT-F11", "") -- 84
  WR_CreateMacro("ALT-CTRL-SHIFT-F5", "/cast [target=player] 驱散魔法") -- 85
  WR_CreateMacro("ALT-CTRL-SHIFT-F6", "/cast 暗言术：渊") -- 86
  WR_CreateMacro("ALT-CTRL-SHIFT-F7", "/cast 暗言术：灭") -- 87
  WR_CreateMacro("ALT-CTRL-SHIFT-F8", "") -- 88
  WR_CreateMacro("ALT-CTRL-SHIFT-F12", "") -- 89
  WR_CreateMacro("ALT-CTRL-SHIFT-F10", "") -- 90
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
  WR_CreateMacro("ALT-SHIFT-,", "/cast [@player] 能量灌注") -- 149
  WR_CreateMacro("CTRL-,", "/cast 绝望祷言") -- 150
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
  WR_CreateMacro("ALT-PAGEUP", "/use [nochanneling:精神鞭笞,nochanneling:暗言术：渊] 10") -- 180
  WR_CreateMacro("ALT-CTRL-SHIFT-PAGEDOWN", "/cast [nochanneling:精神鞭笞,nochanneling:暗言术：渊]血性狂怒\n/cast [nochanneling:精神鞭笞,nochanneling:暗言术：渊]狂暴\n/cast [nochanneling:精神鞭笞,nochanneling:暗言术：渊]狮心") -- 181
  WR_CreateMacro("CTRL-SHIFT-PAGEDOWN", "/use [nochanneling:精神鞭笞,nochanneling:暗言术：渊] 13\n/use [nochanneling:精神鞭笞,nochanneling:暗言术：渊] 14") -- 182
  WR_CreateMacro("ALT-CTRL-PAGEDOWN", "/cast [nochanneling:精神鞭笞,nochanneling:暗言术：渊] 速度药水") -- 183
  WR_CreateMacro("ALT-SHIFT-PAGEDOWN", "/cast [nochanneling:精神鞭笞,nochanneling:暗言术：渊] 狂野魔精药水\n/cast [nochanneling:精神鞭笞,nochanneling:暗言术：渊] 狂野魔法药水") -- 184
  WR_CreateMacro("CTRL-PAGEDOWN", "/use [@player] 通用热力工程炸药") -- 185
  WR_CreateMacro("SHIFT-PAGEDOWN", "/use [@player] 萨隆邪铁炸弹") -- 186
  WR_CreateMacro("ALT-PAGEDOWN", "/cast [@cursor] 萨隆邪铁炸弹") -- 187
  WR_CreateMacro("ALT-CTRL-SHIFT-NUMPADDIVIDE", "/use 邪能治疗石") -- 188
  WR_CreateMacro("ALT-CTRL-NUMPADDIVIDE", "/use 8") -- 189
  WR_CreateMacro("CTRL-NUMPADDIVIDE", "/startattack") -- 190
  WR_CreateMacro("ALT-NUMPADDIVIDE", "/cancelaura 保护之手\n/cancelaura 能量灌注\n/cancelaura 专注魔法") -- 191
  WR_CreateMacro("ALT-CTRL-NUMPADMULTIPLY", "/focus player") -- 192
  WR_CreateMacro("CTRL-NUMPADMULTIPLY", "/cast [target=cursor] 群体驱散") -- 193
  WR_CreateMacro("ALT-NUMPADMULTIPLY", "") -- 194
  WR_CreateMacro("ALT-CTRL-NUMPADMINUS", "") -- 195
  WR_CreateMacro("CTRL-NUMPADMINUS", "") -- 196
  WR_CreateMacro("ALT-NUMPADMINUS", "") -- 197
  WR_CreateMacro("ALT-CTRL-NUMPADPLUS", "") -- 198
  WR_CreateMacro("CTRL-NUMPADPLUS", "") -- 199
  WR_CreateMacro("ALT-NUMPADPLUS", "") -- 200
end

local WR_EventFrame = CreateFrame("Frame")
WR_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
WR_EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
WR_EventFrame:SetScript("OnEvent", function(self, event, ...)
  if UnitClassBase("player") == "PRIEST" and not InCombatLockdown() then
    CreateClassesMacro()
  end
end)

-- ============================================================
-- ★ SoD 宏槽层：WR_SkillColor[PRIEST]（技能名 -> 颜色槽位 1-199）
--   由脚本依据本文件 WR_CreateMacro 注释槽位 + 各旋转调用自动生成；
--   旋转统一用 WR_ColorFrame_ShowSkill(技能名) 取槽位，优先此处，缺失回退原数值。
--   所有槽位强制落在 1-199（职业专用）；200-240 为 Core/Global_Macros.lua 全局保留，严禁占用。
--   未在此表的符文新技能已自动分配到空闲职业槽；如需 AHK 按键请在各 WR_CreateMacro 补绑定。
-- ============================================================
WR_SkillColor["PRIEST"] = {
    ["痛苦压制"] = 64,
    ["治疗祷言"] = 53,
    ["真言术：盾"] = 59,
    ["苦修"] = 54,
    ["愈合祷言"] = 58,
    ["快速治疗"] = 57,
    ["绝望祷言"] = 150,
    ["治疗之环"] = 76,
    ["强效治疗术"] = 77,
    ["恢复"] = 55,
    ["暗言术：痛"] = 14,
    ["吸血鬼之触"] = 1,
    ["噬灵疫病"] = 3,
    ["心灵震爆"] = 4,
    ["精神鞭笞"] = 5,
    ["暗影魔"] = 7,
    ["消散"] = 11,
    ["守护之魂"] = 187,
    ["暗言术：死"] = 176,
    ["心灵专注"] = 301,
    ["能量灌注"] = 302,
    ["神圣新星"] = 303,
    ["联结治疗"] = 304,
    ["吸血鬼的拥抱"] = 305,
    ["沉默"] = 306,
    ["暗影形态"] = 307,
}
