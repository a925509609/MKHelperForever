if WR_PlayerClass ~= "HUNTER" then return end

local function CreateClassesMacro()
  WR_CreateMacro("NUMPAD1", "/cast !雄鹰守护") -- 1
  WR_CreateMacro("NUMPAD2", "/CAST 冰霜陷阱") -- 2
  WR_CreateMacro("NUMPAD3", "/petautocastoff 撕咬\n/cast 撕咬") -- 3
  WR_CreateMacro("NUMPAD4", "/cast [target=focus] 宁神射击") -- 4
  WR_CreateMacro("NUMPAD5", "/CAST 杀戮射击") -- 5
  WR_CreateMacro("NUMPAD6", "/CAST 毒蛇钉刺") -- 6
  WR_CreateMacro("NUMPAD7", "/cast 爆炸射击") -- 7
  WR_CreateMacro("NUMPAD8", "/cast 黑箭") -- 8
  WR_CreateMacro("NUMPAD9", "/cast 陷阱发射器：爆炸陷阱") -- 9
  WR_CreateMacro("NUMPAD0", "/CAST !灵狐守护") -- 10
  WR_CreateMacro("CTRL-NUMPAD1", "/CAST 眼镜蛇射击") -- 11
  WR_CreateMacro("CTRL-NUMPAD2", "/cast 稳固射击") -- 12
  WR_CreateMacro("CTRL-NUMPAD3", "/cast 瞄准射击") -- 13
  WR_CreateMacro("CTRL-NUMPAD4", "/cast 奇美拉射击") -- 14
  WR_CreateMacro("CTRL-NUMPAD5", "/cast 杀戮命令") -- 15
  WR_CreateMacro("CTRL-NUMPAD6", "/cast 集中火力") -- 16
  WR_CreateMacro("CTRL-NUMPAD7", "/cast 奥术射击") -- 17
  WR_CreateMacro("CTRL-NUMPAD8", "/cast 陷阱发射器") -- 18
  WR_CreateMacro("CTRL-NUMPAD9", "/cast [@cursor] 陷阱发射器：爆炸陷阱") -- 19
  WR_CreateMacro("CTRL-NUMPAD0", "/cast 多重射击") -- 20
  WR_CreateMacro("ALT-NUMPAD1", "/petattack") -- 21
  WR_CreateMacro("ALT-NUMPAD2", "/use 10\n/use 13\n/use 14\n/cast 狮心\n/cast 野性呼唤\n/施放 狂暴(种族特长)\n/施放 血性狂怒(种族特长)\n/cast 急速射击") -- 22
  WR_CreateMacro("ALT-NUMPAD3", "/cast 准备就绪") -- 23
  WR_CreateMacro("ALT-NUMPAD4", "/USE 10\n/use 13\n/use 14\n/cast 狮心\n/cast 狂暴(种族特长)\n/cast 血性狂怒(种族特长)\n/cast 狂野怒火") -- 24
  WR_CreateMacro("ALT-NUMPAD5", "/cast 热情") -- 25
  WR_CreateMacro("ALT-NUMPAD6", "/targetenemy") -- 26
  WR_CreateMacro("ALT-NUMPAD7", "/USE 10\n/use 13\n/use 14\n/cast 狮心\n/cast 狂暴(种族特长)\n/cast 血性狂怒(种族特长)") -- 27
  WR_CreateMacro("ALT-NUMPAD8", "/cast [target=focus] 误导") -- 28
  WR_CreateMacro("ALT-NUMPAD9", "/cast [@cursor] 冰霜陷阱") -- 29
  WR_CreateMacro("ALT-NUMPAD0", "/cast [@cursor] 冰冻之箭") -- 30
  WR_CreateMacro("ALT-CTRL-NUMPAD1", "/cast 治疗宠物") -- 31
  WR_CreateMacro("ALT-CTRL-NUMPAD2", "/STOPCASTING\n/cast 逃脱") -- 32
  WR_CreateMacro("ALT-CTRL-NUMPAD3", "/cast !龙鹰守护") -- 33
  WR_CreateMacro("ALT-CTRL-NUMPAD4", "/cast !蝰蛇守护") -- 34
  WR_CreateMacro("ALT-CTRL-NUMPAD5", "/cast 爆炸射击(等级 3)") -- 35
  WR_CreateMacro("ALT-CTRL-NUMPAD6", "/cast [target=mouseover] 杀戮射击") -- 36
  WR_CreateMacro("ALT-CTRL-NUMPAD7", "/cast [@cursor] 乱射") -- 37
  WR_CreateMacro("ALT-CTRL-NUMPAD8", "/CAST 猎人印记") -- 38
  WR_CreateMacro("ALT-CTRL-NUMPAD9", "/cast !雄鹰守护") -- 39
  WR_CreateMacro("ALT-CTRL-NUMPAD0", "/cast !自动射击") -- 40
  WR_CreateMacro("SHIFT-F1", "/use 邪能治疗石") -- 41
  WR_CreateMacro("SHIFT-F2", "/petfollow") -- 42
  WR_CreateMacro("SHIFT-F3", "/USE 速度药水") -- 43
  WR_CreateMacro("SHIFT-F11", "/use [@player] 通用热力工程炸药\n/use [@player] 萨隆邪铁炸弹") -- 44
  WR_CreateMacro("SHIFT-F5", "/cast [@cursor] 萨隆邪铁炸弹") -- 45
  WR_CreateMacro("SHIFT-F6", "/cast 奇美拉射击") -- 46
  WR_CreateMacro("SHIFT-F7", "/cast 沉默射击") -- 47
  WR_CreateMacro("SHIFT-F8", "/USE 香辣猛犸小吃") -- 48
  WR_CreateMacro("SHIFT-F12", "/cast [target=mouseover] 毒蛇钉刺") -- 49
  WR_CreateMacro("SHIFT-F10", "/cast 宁神射击") -- 50
  WR_CreateMacro("CTRL-F1", "/cast 扰乱射击") -- 51
  WR_CreateMacro("CTRL-F2", "/cast 震荡射击") -- 52
  WR_CreateMacro("CTRL-F3", "/cast 假死") -- 53
  WR_CreateMacro("CTRL-F11", "/use 15\n/run MouselookStart()\n/run RunNextFrame(function() MouselookStop() end)\n/castsequence reset=5 !龙鹰守护,逃脱") -- 54
  WR_CreateMacro("CTRL-F5", "/cast [target=focus] 奥术射击") -- 55
  WR_CreateMacro("CTRL-F6", "/cast [target=mouseover] 奥术射击") -- 56
  WR_CreateMacro("CTRL-F7", "/cast [target=focus] 杀戮射击") -- 57
  WR_CreateMacro("CTRL-F8", "/cast [target=focus] 毒蛇钉刺") -- 58
  WR_CreateMacro("CTRL-F12", "/use [@player] 萨隆邪铁炸弹") -- 59
  WR_CreateMacro("CTRL-F10", "/cast [target=pet] 误导") -- 60
  WR_CreateMacro("ALT-CTRL-F1", "/use 10\n/use 13\n/use 14\n/cast 狮心\n/cast 野性呼唤\n/施放 狂暴(种族特长)\n/施放 血性狂怒(种族特长)\n/cast 急速射击") -- 61
  WR_CreateMacro("ALT-CTRL-F2", "/cast [target=focus]误导") -- 62
  WR_CreateMacro("ALT-CTRL-F3", "/cast 雄鹰射击") -- 63
  WR_CreateMacro("ALT-CTRL-F11", "/cast [@cursor] 豪猪诱饵") -- 64
  WR_CreateMacro("ALT-CTRL-F5", "/use 8") -- 65
  WR_CreateMacro("ALT-CTRL-F6", "/cast !自动射击") -- 66
  WR_CreateMacro("ALT-CTRL-F7", "/cast [target=focus] 误导") -- 67
  WR_CreateMacro("ALT-CTRL-F8", "/USE 速度药水") -- 68
  WR_CreateMacro("ALT-CTRL-F12", "/target 黑暗邪使艾蒂丝") -- 69
  WR_CreateMacro("ALT-CTRL-F10", "/target 光明邪使菲奥拉") -- 70
  WR_CreateMacro("CTRL-SHIFT-F1", "/cast 复活宠物") -- 71
  WR_CreateMacro("CTRL-SHIFT-F2", "/cast 召唤宠物") -- 72
  WR_CreateMacro("CTRL-SHIFT-F3", "/cast 召唤宠物 2") -- 73
  WR_CreateMacro("CTRL-SHIFT-F11", "/cast 召唤宠物 3") -- 74
  WR_CreateMacro("CTRL-SHIFT-F5", "/cast 召唤宠物 4") -- 75
  WR_CreateMacro("CTRL-SHIFT-F6", "/cast 召唤宠物 5") -- 76
  WR_CreateMacro("CTRL-SHIFT-F7", "/cast 凤凰之心") -- 77
  WR_CreateMacro("CTRL-SHIFT-F8", "/cast 豪猪诱饵") -- 78
  WR_CreateMacro("CTRL-SHIFT-F12", "/cast 摔绊") -- 79
  WR_CreateMacro("CTRL-SHIFT-F10", "/cast 扰乱射击") -- 80
  WR_CreateMacro("ALT-CTRL-SHIFT-F1", "/cast [target=focus] 冰冻之箭") -- 81 焦点冰冻之箭
  WR_CreateMacro("ALT-CTRL-SHIFT-F2", "/cast [@cursor] 豪猪诱饵") -- 82
  WR_CreateMacro("ALT-CTRL-SHIFT-F3", "/cast 冰霜陷阱") -- 83
  WR_CreateMacro("ALT-CTRL-SHIFT-F11", "/cast [target=focus] 误导") -- 84
  WR_CreateMacro("ALT-CTRL-SHIFT-F5", "/cast [@cursor] 豪猪诱饵") -- 85
  WR_CreateMacro("ALT-CTRL-SHIFT-F6", "/cast [target=pet] 误导") -- 86
  WR_CreateMacro("ALT-CTRL-SHIFT-F7", "/cast [target=targettarget] 误导") -- 87
  WR_CreateMacro("ALT-CTRL-SHIFT-F8", "/cast 冰冻之箭") -- 88 目标冰冻之箭
  WR_CreateMacro("ALT-CTRL-SHIFT-F12", "/petstay") -- 89  宝宝待命(不控制模式原地)
  WR_CreateMacro("ALT-CTRL-SHIFT-F10", "") -- 90
  WR_CreateMacro("ALT-F1", "/cast [@cursor] 冰冻之箭") -- 91 指向冰冻之箭(备用)
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
  if UnitClassBase("player") == "HUNTER" and not InCombatLockdown() then
    CreateClassesMacro()
  end
end)

-- ============================================================
-- ★ SoD 宏槽层：WR_SkillColor[HUNTER]（技能名 -> 颜色槽位 1-199）
--   由脚本依据本文件 WR_CreateMacro 注释槽位 + 各旋转调用自动生成；
--   旋转统一用 WR_ColorFrame_ShowSkill(技能名) 取槽位，优先此处，缺失回退原数值。
--   所有槽位强制落在 1-199（职业专用）；200-240 为 Core/Global_Macros.lua 全局保留，严禁占用。
--   未在此表的符文新技能已自动分配到空闲职业槽；如需 AHK 按键请在各 WR_CreateMacro 补绑定。
-- ============================================================
WR_SkillColor["HUNTER"] = {
    ["毒蛇钉刺"] = 6,
    ["杀戮射击"] = 5,
    ["杀戮命令"] = 15,
    ["多重射击"] = 20,
    ["眼镜蛇射击"] = 11,
    ["奇美拉射击"] = 14,
    ["瞄准射击"] = 13,
    ["稳固射击"] = 12,
    ["爆炸射击"] = 7,
    ["自动射击"] = 85,
    ["雄狮守护"] = 19,
    ["蝰蛇守护"] = 78,
    ["雄鹰守护"] = 76,
    ["削砍"] = 81,
}
