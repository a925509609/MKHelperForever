if WR_PlayerClass ~= "WARRIOR" then return end

local function CreateClassesMacro()
  WR_CreateMacro("NUMPAD1", "/cast 破甲攻击") -- 1
  WR_CreateMacro("NUMPAD2", "/CAST 嗜血") -- 2
  WR_CreateMacro("NUMPAD3", "/CAST 旋风斩") -- 3
  WR_CreateMacro("NUMPAD4", "/stopattack") -- 4
  WR_CreateMacro("NUMPAD5", "/CAST 英勇打击") -- 5
  WR_CreateMacro("NUMPAD6", "/CAST 英勇投掷") -- 6
  WR_CreateMacro("NUMPAD7", "/cast 顺劈斩") -- 7
  WR_CreateMacro("NUMPAD8", "/cast [target=focus] 拳击;拳击") -- 8
  WR_CreateMacro("NUMPAD9", "/cast 战斗姿态") -- 9
  WR_CreateMacro("NUMPAD0", "/CAST 战斗怒吼") -- 10
  WR_CreateMacro("CTRL-NUMPAD1", "/CAST 狂暴之怒") -- 11
  WR_CreateMacro("CTRL-NUMPAD2", "/cast 血性狂暴") -- 12
  WR_CreateMacro("CTRL-NUMPAD3", "/cast 斩杀") -- 13
  WR_CreateMacro("CTRL-NUMPAD4", "/cast 反击风暴") -- 14
  WR_CreateMacro("CTRL-NUMPAD5", "/stopcasting") -- 15
  WR_CreateMacro("CTRL-NUMPAD6", "/cast 盾牌猛击") -- 16
  WR_CreateMacro("CTRL-NUMPAD7", "/CAST 毁灭打击") -- 17
  WR_CreateMacro("CTRL-NUMPAD8", "/cast 复仇") -- 18
  WR_CreateMacro("CTRL-NUMPAD9", "/cast 石像形态\n/cast 死亡之愿") -- 19
  WR_CreateMacro("CTRL-NUMPAD0", "/CAST 命令怒吼") -- 20
  WR_CreateMacro("ALT-NUMPAD1", "/startattack") -- 21
  WR_CreateMacro("ALT-NUMPAD2", "/cast 碎裂投掷") -- 22
  WR_CreateMacro("ALT-NUMPAD3", "/CAST 雷霆一击") -- 23
  WR_CreateMacro("ALT-NUMPAD4", "/cast 拳击") -- 24
  WR_CreateMacro("ALT-NUMPAD5", "/cast 挫志怒吼") -- 25
  WR_CreateMacro("ALT-NUMPAD6", "/cast [target=focus] 盾击;盾击") -- 26
  WR_CreateMacro("ALT-NUMPAD7", "/cast 盾击") -- 27
  WR_CreateMacro("ALT-NUMPAD8", "/cast 防御姿态") -- 28
  WR_CreateMacro("ALT-NUMPAD9", "/cast 震荡波") -- 29
  WR_CreateMacro("ALT-NUMPAD0", "/cast 破釜沉舟") -- 30
  WR_CreateMacro("ALT-CTRL-NUMPAD1", "/cast 盾牌格挡") -- 31
  WR_CreateMacro("ALT-CTRL-NUMPAD2", "/cast 挑战怒吼") -- 32
  WR_CreateMacro("ALT-CTRL-NUMPAD3", "/cast 狂暴姿态") -- 33
  WR_CreateMacro("ALT-CTRL-NUMPAD4", "/施放 狂暴(种族特长)\n/施放 血性狂怒(种族特长)\n/use 10\n/use 13\n/use 14\n/cast 狮心") -- 34
  WR_CreateMacro("ALT-CTRL-NUMPAD5", "/CAST 猛击") -- 35
  WR_CreateMacro("ALT-CTRL-NUMPAD6", "/cast 乘胜追击") -- 36
  WR_CreateMacro("ALT-CTRL-NUMPAD7", "/CAST 鲁莽") -- 37
  WR_CreateMacro("ALT-CTRL-NUMPAD8", "/use 10") -- 38
  WR_CreateMacro("ALT-CTRL-NUMPAD9", "/CAST 撕裂") -- 39
  WR_CreateMacro("ALT-CTRL-NUMPAD0", "/cast 致死打击") -- 40
  WR_CreateMacro("SHIFT-F1", "/cast 压制") -- 41
  WR_CreateMacro("SHIFT-F2", "/cast 横扫攻击") -- 42
  WR_CreateMacro("SHIFT-F3", "/cast 利刃风暴") -- 43
  WR_CreateMacro("SHIFT-F11", "/use 邪能治疗石") -- 44
  WR_CreateMacro("SHIFT-F5", "/use 速度药水") -- 45
  WR_CreateMacro("SHIFT-F6", "/use [@player] 通用热力工程炸药\n/use [@player] 萨隆邪铁炸弹") -- 46
  WR_CreateMacro("SHIFT-F7", "/cast 盾墙") -- 47
  WR_CreateMacro("SHIFT-F8", "/CAST 战斗姿态") -- 48
  WR_CreateMacro("SHIFT-F12", "/cast 断筋") -- 49
  WR_CreateMacro("SHIFT-F10", "/cast [target=focus] 破甲攻击") -- 50
  WR_CreateMacro("CTRL-F1", "/use [@player] 萨隆邪铁炸弹") -- 51
  WR_CreateMacro("CTRL-F2", "/cast 拦截") -- 52
  WR_CreateMacro("CTRL-F3", "/cast 刺耳怒吼") -- 53
  WR_CreateMacro("CTRL-F11", "/cast 战斗姿态\n/cast 横扫攻击") -- 54
  WR_CreateMacro("CTRL-F5", "/cast 狂怒回复") -- 55
  WR_CreateMacro("CTRL-F6", "/cast 惩戒痛击") -- 56
  WR_CreateMacro("CTRL-F7", "/cast 冲锋") -- 57
  WR_CreateMacro("CTRL-F8", "") -- 58
  WR_CreateMacro("CTRL-F12", "") -- 59
  WR_CreateMacro("CTRL-F10", "") -- 60
  WR_CreateMacro("ALT-CTRL-F1", "") -- 61
  WR_CreateMacro("ALT-CTRL-F2", "") -- 62
  WR_CreateMacro("ALT-CTRL-F3", "") -- 63
  WR_CreateMacro("ALT-CTRL-F11", "") -- 64
  WR_CreateMacro("ALT-CTRL-F5", "") -- 65
  WR_CreateMacro("ALT-CTRL-F6", "/cast 致死打击") -- 66
  WR_CreateMacro("ALT-CTRL-F7", "/cleartarget\n/targetlasttarget\n/startattack") -- 67
  WR_CreateMacro("ALT-CTRL-F8", "/use 速度药水") -- 68
  WR_CreateMacro("ALT-CTRL-F12", "/target 光明邪使菲奥拉\n/focus\n/target 黑暗邪使艾蒂丝") -- 69
  WR_CreateMacro("ALT-CTRL-F10", "/target 黑暗邪使艾蒂丝\n/focus\n/target 光明邪使菲奥拉") -- 70
  WR_CreateMacro("CTRL-SHIFT-F1", "") -- 71
  WR_CreateMacro("CTRL-SHIFT-F2", "") -- 72
  WR_CreateMacro("CTRL-SHIFT-F3", "") -- 73
  WR_CreateMacro("CTRL-SHIFT-F11", "") -- 74
  WR_CreateMacro("CTRL-SHIFT-F5", "") -- 75
  WR_CreateMacro("CTRL-SHIFT-F6", "") -- 76
  WR_CreateMacro("CTRL-SHIFT-F7", "") -- 77
  WR_CreateMacro("CTRL-SHIFT-F8", "") -- 78
  WR_CreateMacro("CTRL-SHIFT-F12", "") -- 79
  WR_CreateMacro("CTRL-SHIFT-F10", "") -- 80
  WR_CreateMacro("ALT-CTRL-SHIFT-F1", "") -- 81
  WR_CreateMacro("ALT-CTRL-SHIFT-F2", "") -- 82
  WR_CreateMacro("ALT-CTRL-SHIFT-F3", "") -- 83
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
  WR_CreateMacro("ALT-CTRL-SHIFT-,", "") -- 146
  WR_CreateMacro("CTRL-SHIFT-,", "") -- 147
  WR_CreateMacro("ALT-CTRL-,", "") -- 148
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
  WR_CreateMacro("CTRL-SHIFT-PAGEDOWN", "/use 13\n/use 14") -- 182
  WR_CreateMacro("ALT-CTRL-PAGEDOWN", "/cast 速度药水") -- 183
  WR_CreateMacro("ALT-SHIFT-PAGEDOWN", "/cast 不灭药水") -- 184
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
  if UnitClassBase("player") == "WARRIOR" and not InCombatLockdown() then
    CreateClassesMacro()
  end
end)

-- ============================================================
-- ★ SoD 宏槽层：WR_SkillColor[WARRIOR]（技能名 -> 颜色槽位 1-199）
--   由脚本依据本文件 WR_CreateMacro 注释槽位 + 各旋转调用自动生成；
--   旋转统一用 WR_ColorFrame_ShowSkill(技能名) 取槽位，优先此处，缺失回退原数值。
--   所有槽位强制落在 1-199（职业专用）；200-240 为 Core/Global_Macros.lua 全局保留，严禁占用。
--   未在此表的符文新技能已自动分配到空闲职业槽；如需 AHK 按键请在各 WR_CreateMacro 补绑定。
-- ============================================================
WR_SkillColor["WARRIOR"] = {
    ["斩杀"] = 13,
    ["压制"] = 41,
    ["旋风斩"] = 3,
    ["顺劈斩"] = 7,
    ["猛击"] = 35,
    ["致死打击"] = 40,
    ["英勇打击"] = 5,
    ["鲁莽"] = 37,
    ["狂暴之怒"] = 11,
    ["嗜血"] = 2,
    ["破釜沉舟"] = 30,
    ["毁灭打击"] = 17,
    ["复仇"] = 18,
    ["盾牌猛击"] = 16,
    ["雷霆一击"] = 23,
    ["盾牌格挡"] = 31,
    ["挑战怒吼"] = 32,
    ["血性狂暴"] = 12,
    ["狂暴之怒(解控)"] = 58,
    ["攻击"] = 4,
    ["鞭笞"] = 59,
    ["狂暴打击"] = 69,
    ["迅捷打击"] = 70,
    ["贯刺打击"] = 301,
    ["横扫攻击"] = 302,
    ["刺耳怒吼"] = 303,
    ["死亡之愿"] = 304,
    ["震荡猛击"] = 305,
}
