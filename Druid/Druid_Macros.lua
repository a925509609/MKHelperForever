if WR_PlayerClass ~= "DRUID" then return end

local function CreateClassesMacro()
  WR_CreateMacro("NUMPAD1", "/CAST [nostance:3]!猎豹形态(变形)") -- 1
  WR_CreateMacro("NUMPAD2", "/CAST 猛虎之怒") -- 2
  WR_CreateMacro("NUMPAD3", "/use 13\n/use 14\n/CAST 狂暴") -- 3
  WR_CreateMacro("NUMPAD4", "/cast 割碎") -- 4
  WR_CreateMacro("NUMPAD5", "/CAST 割裂") -- 5
  WR_CreateMacro("NUMPAD6", "/CAST 凶猛撕咬") -- 6
  WR_CreateMacro("NUMPAD7", "/cast 斜掠") -- 7
  WR_CreateMacro("NUMPAD8", "/cast 裂伤（豹）") -- 8
  WR_CreateMacro("NUMPAD9", "/stopattack") -- 9
  WR_CreateMacro("NUMPAD0", "/CAST 精灵之火（野性）") -- 10
  WR_CreateMacro("CTRL-NUMPAD1", "/CAST 横扫（豹）") -- 11
  WR_CreateMacro("CTRL-NUMPAD2", "/use 10") -- 12
  WR_CreateMacro("CTRL-NUMPAD3", "/cast 复生") -- 13
  WR_CreateMacro("CTRL-NUMPAD4", "/cast 爪击") -- 14
  WR_CreateMacro("CTRL-NUMPAD5", "/cast 撕碎") -- 15
  WR_CreateMacro("CTRL-NUMPAD6", "/cast !枭兽形态") -- 16
  WR_CreateMacro("CTRL-NUMPAD7", "/cast [@cursor] 自然之力") -- 17
  WR_CreateMacro("CTRL-NUMPAD8", "/cast 星辰坠落") -- 18
  WR_CreateMacro("CTRL-NUMPAD9", "/cast 虫群") -- 19
  WR_CreateMacro("CTRL-NUMPAD0", "/cast 愤怒") -- 20
  WR_CreateMacro("ALT-NUMPAD1", "/cast 星火术") -- 21
  WR_CreateMacro("ALT-NUMPAD2", "/cast 台风") -- 22
  WR_CreateMacro("ALT-NUMPAD3", "/cast 树皮术") -- 23
  WR_CreateMacro("ALT-NUMPAD4", "/cast [@cursor] 飓风") -- 24
  WR_CreateMacro("ALT-NUMPAD5", "/CAST 激活") -- 25
  WR_CreateMacro("ALT-NUMPAD6", "/cast 月火术") -- 26
  WR_CreateMacro("ALT-NUMPAD7", "/cast !巨熊形态") -- 27
  WR_CreateMacro("ALT-NUMPAD8", "/cast 激怒") -- 28
  WR_CreateMacro("ALT-NUMPAD9", "/cancelaura 激怒") -- 29
  WR_CreateMacro("ALT-NUMPAD0", "/cast 裂伤（熊）") -- 30
  WR_CreateMacro("ALT-CTRL-NUMPAD1", "/cast 割伤") -- 31
  WR_CreateMacro("ALT-CTRL-NUMPAD2", "/CAST 重殴") -- 32
  WR_CreateMacro("ALT-CTRL-NUMPAD3", "/cast 横扫（熊）") -- 33
  WR_CreateMacro("ALT-CTRL-NUMPAD4", "/cast 猛击") -- 34
  WR_CreateMacro("ALT-CTRL-NUMPAD5", "/cancelaura 追踪人型生物") -- 35
  WR_CreateMacro("ALT-CTRL-NUMPAD6", "/cast 挑战咆哮") -- 36
  WR_CreateMacro("ALT-CTRL-NUMPAD7", "/CAST 野蛮咆哮") -- 37
  WR_CreateMacro("ALT-CTRL-NUMPAD8", "/cast 精灵之火") -- 38
  WR_CreateMacro("ALT-CTRL-NUMPAD9", "/startattack") -- 39
  WR_CreateMacro("ALT-CTRL-NUMPAD0", "/stopcasting") -- 40
  WR_CreateMacro("SHIFT-F1", "/use 速度药水") -- 41
  WR_CreateMacro("SHIFT-F2", "/cast 狂暴回复") -- 42
  WR_CreateMacro("SHIFT-F3", "/petattack") -- 43
  WR_CreateMacro("SHIFT-F11", "/use 邪能治疗石") -- 44
  WR_CreateMacro("SHIFT-F5", "/use 10\n/use 13\n/use 14\n/cast 狮心") -- 45
  WR_CreateMacro("SHIFT-F6", "/targetenemy") -- 46
  WR_CreateMacro("SHIFT-F7", "/use [@player] 通用热力工程炸药\n/use [@player] 萨隆邪铁炸弹") -- 47
  WR_CreateMacro("SHIFT-F8", "/cast [@cursor] 萨隆邪铁炸弹") -- 48
  WR_CreateMacro("SHIFT-F12", "/use 狂野魔精药水\n/use 狂野魔法药水\n/use 10\n/use 13\n/use 14\n/cast 狮心") -- 49
  WR_CreateMacro("SHIFT-F10", "/USE 香辣猛犸小吃") -- 50
  WR_CreateMacro("CTRL-F1", "/cast 重击") -- 51
  WR_CreateMacro("CTRL-F2", "/cast 槌击") -- 52
  WR_CreateMacro("CTRL-F3", "/cast 挥击") -- 53
  WR_CreateMacro("CTRL-F11", "/cast 狂怒") -- 54
  WR_CreateMacro("CTRL-F5", "/console autoUnshift 0\n/cast !猎豹形态\n/console autoUnshift 1") -- 55（用 /console 改 CVar 替代 /run SetCVar，避免自定义脚本弹窗；! 强制施法不受 autoUnshift 影响）
  WR_CreateMacro("CTRL-F6", "/cast 爪击") -- 56
  WR_CreateMacro("CTRL-F7", "/cast 扫击") -- 57
  WR_CreateMacro("CTRL-F8", "/cast [target=mouseover] 虫群") -- 58
  WR_CreateMacro("CTRL-F12", "/cast [target=mouseover] 月火术") -- 59
  WR_CreateMacro("CTRL-F10", "/cast 旋风") -- 60
  WR_CreateMacro("ALT-CTRL-F1", "/cast [target=mouseover] 旋风") -- 61
  WR_CreateMacro("ALT-CTRL-F2", "/target 镜像\n/target 裹体之网\n/cast 月火术") -- 62
  WR_CreateMacro("ALT-CTRL-F3", "/use [@player] 萨隆邪铁炸弹") -- 63
  WR_CreateMacro("ALT-CTRL-F11", "/cast 宁静") -- 64
  WR_CreateMacro("ALT-CTRL-F5", "/use 8") -- 65
  WR_CreateMacro("ALT-CTRL-F6", "/stopcasting") -- 66
  WR_CreateMacro("ALT-CTRL-F7", "/use 狂野魔精药水\n/use 狂野魔法药水\n/use 10\n/use 13\n/use 14\n/cast 狮心") -- 67
  WR_CreateMacro("ALT-CTRL-F8", "/use 速度药水") -- 68
  WR_CreateMacro("ALT-CTRL-F12", "/target 黑暗邪使艾蒂丝") -- 69
  WR_CreateMacro("ALT-CTRL-F10", "/target 光明邪使菲奥拉") -- 70
  WR_CreateMacro("CTRL-SHIFT-F1", "/cast 野性冲锋 - 豹") -- 71
  WR_CreateMacro("CTRL-SHIFT-F2", "/cast 生存本能") -- 72
  WR_CreateMacro("CTRL-SHIFT-F3", "/cast [@focus] 旋风") -- 73
  WR_CreateMacro("CTRL-SHIFT-F11", "/cast [@focus] 解除诅咒") -- 74
  WR_CreateMacro("CTRL-SHIFT-F5", "/cast [target=player] 解除诅咒") -- 75
  WR_CreateMacro("CTRL-SHIFT-F6", "/cast !熊形态") -- 76
  WR_CreateMacro("CTRL-SHIFT-F7", "/cast 猛击") -- 77
  WR_CreateMacro("CTRL-SHIFT-F8", "/cast 挑战咆哮") -- 78
  WR_CreateMacro("CTRL-SHIFT-F12", "/cast 挫志咆哮") -- 79
  WR_CreateMacro("CTRL-SHIFT-F10", "/cast 愈合") -- 80
  WR_CreateMacro("ALT-CTRL-SHIFT-F1", "") -- 81
  WR_CreateMacro("ALT-CTRL-SHIFT-F2", "/cast 宁静") -- 82
  WR_CreateMacro("ALT-CTRL-SHIFT-F3", "/cast 治疗之触") -- 83
  WR_CreateMacro("ALT-CTRL-SHIFT-F11", "") -- 84
  WR_CreateMacro("ALT-CTRL-SHIFT-F5", "/cast 重击") -- 85
  WR_CreateMacro("ALT-CTRL-SHIFT-F6", "/use 10\n/use 13\n/use 14\n/stopcasting\n/cast 月神轨道炮") -- 86
  WR_CreateMacro("ALT-CTRL-SHIFT-F7", "/cast [target=focus] 虫群") -- 87
  WR_CreateMacro("ALT-CTRL-SHIFT-F8", "/cast [target=focus] 月火术") -- 88
  WR_CreateMacro("ALT-CTRL-SHIFT-F12", "") -- 89
  WR_CreateMacro("ALT-CTRL-SHIFT-F10", "") -- 90
  WR_CreateMacro("ALT-F1", "/cast 挫志咆哮") -- 91
  WR_CreateMacro("ALT-F2", "/cast 旋风") -- 92
  WR_CreateMacro("ALT-F3", "/cast [target=player] 激活") -- 93
  WR_CreateMacro("ALT-F11", "/cast [@focus] 野性印记") -- 94
  WR_CreateMacro("ALT-F5", "/use 赞达拉英雄护符") -- 95
  WR_CreateMacro("ALT-F6", "/cancelaura 太阳能量") -- 96
  WR_CreateMacro("ALT-F7", "/focus party1target") -- 97
  WR_CreateMacro("ALT-F8", "/focus party2target") -- 98
  WR_CreateMacro("ALT-F12", "/focus party3target") -- 99
  WR_CreateMacro("ALT-F10", "/focus party4target") -- 100
  WR_CreateMacro("ALT-SHIFT-F1", "/cast [@focus] 消毒术") -- 101
  WR_CreateMacro("ALT-SHIFT-F2", "/cast 生命之树") -- 102
  WR_CreateMacro("ALT-SHIFT-F3", "/cast [@focus] 激活") -- 103
  WR_CreateMacro("ALT-SHIFT-F11", "/cast [@focus] 治疗之触") -- 104
  WR_CreateMacro("ALT-SHIFT-F5", "/cast [@focus] 起死回生") -- 105
  WR_CreateMacro("ALT-SHIFT-F6", "/cast [@focus] 滋养") -- 106
  WR_CreateMacro("ALT-SHIFT-F7", "/cast [@focus] 野性成长") -- 107
  WR_CreateMacro("ALT-SHIFT-F8", "/cast [@focus] 生命绽放") -- 108
  WR_CreateMacro("ALT-SHIFT-F12", "/cast [@focus] 回春术") -- 109
  WR_CreateMacro("ALT-SHIFT-F10", "/cast [@focus] 愈合") -- 110
  WR_CreateMacro("ALT-CTRL-SHIFT--", "/cast [@focus] 迅捷治愈") -- 111
  WR_CreateMacro("CTRL-SHIFT--", "/cast 自然迅捷\n/cast [@focus] 治疗之触") -- 112
  WR_CreateMacro("ALT-CTRL--", "/cast [@focus] 树皮术") -- 113
  WR_CreateMacro("ALT-SHIFT--", "/cast [@focus] 野性赐福") -- 114
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

local WR_EventFrame = CreateFrame("Frame")
WR_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
WR_EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
WR_EventFrame:SetScript("OnEvent", function(self, event, ...)
  if UnitClassBase("player") == "DRUID" and not InCombatLockdown() then
    CreateClassesMacro()
  end
end)

-- ============================================================
-- ★ SoD 宏槽层：WR_SkillColor[DRUID]（技能名 -> 颜色槽位 1-199）
--   由脚本依据本文件 WR_CreateMacro 注释槽位 + 各旋转调用自动生成；
--   旋转统一用 WR_ColorFrame_ShowSkill(技能名) 取槽位，优先此处，缺失回退原数值。
--   所有槽位强制落在 1-199（职业专用）；200-240 为 Core/Global_Macros.lua 全局保留，严禁占用。
--   未在此表的符文新技能已自动分配到空闲职业槽；如需 AHK 按键请在各 WR_CreateMacro 补绑定。
-- ============================================================
WR_SkillColor["DRUID"] = {
    ["月神轨道炮"] = 86,
    ["宁静"] = 64,
    ["飓风"] = 24,
    ["愤怒"] = 20,
    ["星火术"] = 21,
    ["斜掠"] = 7,
    ["野蛮咆哮"] = 37,
    ["割裂"] = 5,
    ["凶猛撕咬"] = 6,
    ["撕碎"] = 15,
    ["爪击"] = 14,
    ["狂暴回复"] = 42,
    ["树皮术"] = 23,
    ["精灵之火"] = 38,
    ["重殴"] = 32,
    ["挑战咆哮"] = 36,
    ["野性成长"] = 107,
    ["生命绽放"] = 108,
    ["回春术"] = 109,
    ["治疗之触"] = 83,
    ["愈合"] = 80,
    ["解除诅咒"] = 74,
    ["星涌术"] = 132,
    ["星落"] = 135,
    ["横扫"] = 143,
    ["裂伤"] = 137,
    ["痛击"] = 144,
    ["虫群"] = 301,
    ["枭兽形态"] = 302,
    ["野性冲锋"] = 305,
    ["狂暴"] = 306,
    ["迅捷治愈"] = 307,
    ["自然迅捷"] = 308,
}
