if WR_PlayerClass ~= "MAGE" then return end

local function CreateClassesMacro()
  WR_CreateMacro("NUMPAD1", "/cast 熔岩护甲") -- 1
  WR_CreateMacro("NUMPAD2", "/CAST 炎爆术") -- 2
  WR_CreateMacro("NUMPAD3", "/cast [target=mouseover] 活动炸弹") -- 3
  WR_CreateMacro("NUMPAD4", "/CAST 活动炸弹") -- 4
  WR_CreateMacro("NUMPAD5", "/cast 火球术") -- 5
  WR_CreateMacro("NUMPAD6", "/stopcasting\n/CAST 火焰冲击\n/petattack [combat]") -- 6
  WR_CreateMacro("NUMPAD7", "/cast 灼烧") -- 7
  WR_CreateMacro("NUMPAD8", "/USE 10\n/use 13\n/use 14\n/cast 狮心\n/cast 狂暴(种族特长)\n/cast 血性狂怒(种族特长)\n/cast 燃烧") -- 8
  WR_CreateMacro("NUMPAD9", "/stopcasting\n/cast 解除诅咒") -- 9
  WR_CreateMacro("NUMPAD0", "/use 法力青玉\n/use 法力刚玉\n/petattack [combat]") -- 10
  WR_CreateMacro("CTRL-NUMPAD1", "/cast 冰霜新星\n/petattack [combat]") -- 11
  WR_CreateMacro("CTRL-NUMPAD2", "/CAST 镜像\n/petattack [combat]") -- 12
  WR_CreateMacro("CTRL-NUMPAD3", "/CAST 奥术冲击") -- 13
  WR_CreateMacro("CTRL-NUMPAD4", "/cast 奥术飞弹") -- 14
  WR_CreateMacro("CTRL-NUMPAD5", "/cast 气定神闲") -- 15
  WR_CreateMacro("CTRL-NUMPAD6", "/cast 奥术强化") -- 16
  WR_CreateMacro("CTRL-NUMPAD7", "/cast 法师护甲") -- 17
  WR_CreateMacro("CTRL-NUMPAD8", "/cast 唤醒") -- 18
  WR_CreateMacro("CTRL-NUMPAD9", "/USE 10\n/use 13\n/use 14\n/cast 狮心\n/cast 狂暴(种族特长)\n/cast 血性狂怒(种族特长)\n/petattack [combat]") -- 19
  WR_CreateMacro("CTRL-NUMPAD0", "/cast 霜火之箭\n/petattack [combat]") -- 20
  WR_CreateMacro("ALT-NUMPAD1", "/USE 10\n/use 13\n/use 14\n/cast 狮心\n/cast 血性狂怒(种族特长)\n/cast 冰冷血脉\n/petattack [combat]") -- 21
  WR_CreateMacro("ALT-NUMPAD2", "/cast 冲击波") -- 22
  WR_CreateMacro("ALT-NUMPAD3", "/cast [target=cursor] 烈焰风暴") -- 23
  WR_CreateMacro("ALT-NUMPAD4", "/cast 龙息术") -- 24
  WR_CreateMacro("ALT-NUMPAD5", "/cast [target=cursor] 烈焰风暴(等级 8)") -- 25
  WR_CreateMacro("ALT-NUMPAD6", "/cast [target=cursor] 暴风雪") -- 26
  WR_CreateMacro("ALT-NUMPAD7", "/cast 冰锥术\n/petattack [combat]") -- 27
  WR_CreateMacro("ALT-NUMPAD8", "/cast [target=focus] 活动炸弹") -- 28
  WR_CreateMacro("ALT-NUMPAD9", "/STOPCASTING\n/CAST 隐形术") -- 29
  WR_CreateMacro("ALT-NUMPAD0", "/cancelaura 隐形术") -- 30
  WR_CreateMacro("ALT-CTRL-NUMPAD1", "/STOPCASTING\n/cast 闪现术") -- 31
  WR_CreateMacro("ALT-CTRL-NUMPAD2", "/STOPCASTING\n/cast 寒冰屏障") -- 32
  WR_CreateMacro("ALT-CTRL-NUMPAD3", "/stopcasting") -- 33
  WR_CreateMacro("ALT-CTRL-NUMPAD4", "/stopcasting\n/cast [target=focus] 法术吸取") -- 34
  WR_CreateMacro("ALT-CTRL-NUMPAD5", "/USE 10") -- 35
  WR_CreateMacro("ALT-CTRL-NUMPAD6", "/USE 10\n/use 13\n/use 14\n/cast 狮心\n/cast 狂暴(种族特长)\n/cast 血性狂怒(种族特长)\n/use 速度药水\n/petattack [combat]") -- 36
  WR_CreateMacro("ALT-CTRL-NUMPAD7", "/cast 防护冰霜结界") -- 37
  WR_CreateMacro("ALT-CTRL-NUMPAD8", "/cast 防护火焰结界") -- 38
  WR_CreateMacro("ALT-CTRL-NUMPAD9", "/cast [target=focus] 炎爆术") -- 39
  WR_CreateMacro("ALT-CTRL-NUMPAD0", "/targetenemy") -- 40
  WR_CreateMacro("SHIFT-F1", "/use [@player] 通用热力工程炸药\n/use [@player] 萨隆邪铁炸弹") -- 41
  WR_CreateMacro("SHIFT-F2", "/cast [target=cursor] 萨隆邪铁炸弹") -- 42
  WR_CreateMacro("SHIFT-F3", "/stopcasting\n/cast 法术吸取") -- 43
  WR_CreateMacro("SHIFT-F11", "/stopcasting\n/cast [target=mouseover] 冰枪术") -- 44
  WR_CreateMacro("SHIFT-F5", "/stopcasting\n/cast 冰枪术") -- 45
  WR_CreateMacro("SHIFT-F6", "/cast 法术反制") -- 46
  WR_CreateMacro("SHIFT-F7", "/cast [target=focus] 法术反制") -- 47
  WR_CreateMacro("SHIFT-F8", "/stopcasting\n/cast [target=mouseover] 火焰冲击") -- 48
  WR_CreateMacro("SHIFT-F12", "/cancelAura 寒冰屏障") -- 49
  WR_CreateMacro("SHIFT-F10", "/target 镜像\n/target 裹体之网\n/cast 冰枪术") -- 50
  WR_CreateMacro("CTRL-F1", "/cast [target=party1target] 活动炸弹") -- 51
  WR_CreateMacro("CTRL-F2", "/cast [target=party2target] 活动炸弹") -- 52
  WR_CreateMacro("CTRL-F3", "/cast [target=party3target] 活动炸弹") -- 53
  WR_CreateMacro("CTRL-F11", "/cast [target=party4target] 活动炸弹") -- 54
  WR_CreateMacro("CTRL-F5", "/target 教派狂热者\n/focus\n/target 亡语者女士") -- 55
  WR_CreateMacro("CTRL-F6", "/use 雪球") -- 56
  WR_CreateMacro("CTRL-F7", "/use [@player] 萨隆邪铁炸弹\n/petattack [combat]") -- 57
  WR_CreateMacro("CTRL-F8", "/cast 燃烧") -- 58
  WR_CreateMacro("CTRL-F12", "/target 卑劣的灵魂\n/cast 冰枪术") -- 59
  WR_CreateMacro("CTRL-F10", "/cast 寒冰箭\n/petattack [combat]") -- 60
  WR_CreateMacro("ALT-CTRL-F1", "/cast 奥术弹幕") -- 61
  WR_CreateMacro("ALT-CTRL-F2", "/cast 深度冻结\n/petattack [combat]") -- 62
  WR_CreateMacro("ALT-CTRL-F3", "/cast 急速冷却\n/petattack [combat]") -- 63
  WR_CreateMacro("ALT-CTRL-F11", "/cast [target=cursor] 暴风雪") -- 64
  WR_CreateMacro("ALT-CTRL-F5", "/cast 寒冰护体") -- 65
  WR_CreateMacro("ALT-CTRL-F6", "/targetenemy") -- 66
  WR_CreateMacro("ALT-CTRL-F7", "/use 速度药水\n/USE 10\n/use 13\n/use 14\n/cast 狮心\n/cast 狂暴(种族特长)\n/cast 血性狂怒(种族特长)\n/cast 燃烧") -- 67
  WR_CreateMacro("ALT-CTRL-F8", "/USE 10\n/use 13\n/use 14\n/cast 狮心\n/cast 狂暴(种族特长)\n/cast 血性狂怒(种族特长)\n/use 速度药水\n/petattack [combat]") -- 68
  WR_CreateMacro("ALT-CTRL-F12", "/target 光明邪使菲奥拉\n/focus\n/target 黑暗邪使艾蒂丝") -- 69
  WR_CreateMacro("ALT-CTRL-F10", "/target 黑暗邪使艾蒂丝\n/focus\n/target 光明邪使菲奥拉") -- 70
  WR_CreateMacro("CTRL-SHIFT-F1", "/petattack") -- 71
  WR_CreateMacro("CTRL-SHIFT-F2", "/petfollow") -- 72
  WR_CreateMacro("CTRL-SHIFT-F3", "/cast [target=cursor] 暴风雪\n/petattack [combat]") -- 73
  WR_CreateMacro("CTRL-SHIFT-F11", "") -- 74
  WR_CreateMacro("CTRL-SHIFT-F5", "/petautocaston 水箭\n/petattack [combat]") -- 75
  WR_CreateMacro("CTRL-SHIFT-F6", "/cast 寒冰箭\n/petattack [combat]") -- 76
  WR_CreateMacro("CTRL-SHIFT-F7", "") -- 77
  WR_CreateMacro("CTRL-SHIFT-F8", "") -- 78
  WR_CreateMacro("CTRL-SHIFT-F12", "") -- 79
  WR_CreateMacro("CTRL-SHIFT-F10", "") -- 80
  WR_CreateMacro("ALT-CTRL-SHIFT-F1", "") -- 81
  WR_CreateMacro("ALT-CTRL-SHIFT-F2", "/cast [target=raid12target] 活动炸弹") -- 82
  WR_CreateMacro("ALT-CTRL-SHIFT-F3", "/cast [target=raid13target] 活动炸弹") -- 83
  WR_CreateMacro("ALT-CTRL-SHIFT-F11", "/cast [target=raid14target] 活动炸弹") -- 84
  WR_CreateMacro("ALT-CTRL-SHIFT-F5", "/cast [target=raid15target] 活动炸弹") -- 85
  WR_CreateMacro("ALT-CTRL-SHIFT-F6", "/cast [target=raid16target] 活动炸弹") -- 86
  WR_CreateMacro("ALT-CTRL-SHIFT-F7", "/cast [target=raid17target] 活动炸弹") -- 87
  WR_CreateMacro("ALT-CTRL-SHIFT-F8", "/cast [target=raid18target] 活动炸弹") -- 88
  WR_CreateMacro("ALT-CTRL-SHIFT-F12", "/cast [target=raid19target] 活动炸弹") -- 89
  WR_CreateMacro("ALT-CTRL-SHIFT-F10", "/cast [target=raid20target] 活动炸弹") -- 90
  WR_CreateMacro("ALT-F1", "/cast [target=raid21target] 活动炸弹") -- 91
  WR_CreateMacro("ALT-F2", "/cast [target=raid22target] 活动炸弹") -- 92
  WR_CreateMacro("ALT-F3", "/cast [target=raid23target] 活动炸弹") -- 93
  WR_CreateMacro("ALT-F11", "/cast [target=raid24target] 活动炸弹") -- 94
  WR_CreateMacro("ALT-F5", "/cast [target=raid25target] 活动炸弹") -- 95
  WR_CreateMacro("ALT-F6", "/cast [@focus] 解除诅咒") -- 96
  WR_CreateMacro("ALT-F7", "/focus party1target") -- 97
  WR_CreateMacro("ALT-F8", "/focus party2target") -- 98
  WR_CreateMacro("ALT-F12", "/focus party3target") -- 99
  WR_CreateMacro("ALT-F10", "/focus party4target") -- 100
  WR_CreateMacro("ALT-SHIFT-F1", "/cast 冰枪术\n/petattack [combat]") -- 101
  WR_CreateMacro("ALT-SHIFT-F2", "/cast 寒冰宝珠\n/petattack [combat]") -- 102
  WR_CreateMacro("ALT-SHIFT-F3", "/cast 召唤水元素\n/petattack [combat]") -- 103
  WR_CreateMacro("ALT-SHIFT-F11", "") -- 104
  WR_CreateMacro("ALT-SHIFT-F5", "/cancelaura 能量灌注") -- 105
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
  WR_CreateMacro("CTRL-SHIFT-,", "/cast [@focus] 法术吸取") -- 147
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
  WR_CreateMacro("ALT-CTRL-SHIFT-PAGEDOWN", "/cast 狮心\n/cast 血性狂怒\n/cast 狂暴\n/petattack [combat]") -- 181
  WR_CreateMacro("CTRL-SHIFT-PAGEDOWN", "/use 13\n/use 14\n/cast 狮心\n/petattack [combat]") -- 182
  WR_CreateMacro("ALT-CTRL-PAGEDOWN", "/cast 速度药水\n/petattack [combat]") -- 183
  WR_CreateMacro("ALT-SHIFT-PAGEDOWN", "/cast 狂野魔精药水\n/use 狂野魔法药水\n/petattack [combat]") -- 184
  WR_CreateMacro("CTRL-PAGEDOWN", "/use [@player] 通用热力工程炸药\n/petattack [combat]") -- 185
  WR_CreateMacro("SHIFT-PAGEDOWN", "/use [@player] 萨隆邪铁炸弹\n/petattack [combat]") -- 186
  WR_CreateMacro("ALT-PAGEDOWN", "/cast [@cursor] 萨隆邪铁炸弹\n/petattack [combat]") -- 187
  WR_CreateMacro("ALT-CTRL-SHIFT-NUMPADDIVIDE", "/use 邪能治疗石") -- 188
  WR_CreateMacro("ALT-CTRL-NUMPADDIVIDE", "/cast 狂暴\n/petattack [combat]") -- 189
  WR_CreateMacro("CTRL-NUMPADDIVIDE", "/startattack") -- 190
  WR_CreateMacro("ALT-NUMPADDIVIDE", "/cancelaura 保护之手\n/cancelaura 能量灌注\n/cancelaura 专注魔法") -- 191
  WR_CreateMacro("ALT-CTRL-NUMPADMULTIPLY", "/focus player") -- 192
  WR_CreateMacro("CTRL-NUMPADMULTIPLY", "/cast 制造法力宝石") -- 193
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
  if UnitClassBase("player") == "MAGE" and not InCombatLockdown() then
    CreateClassesMacro()
  end
end)

-- ============================================================
-- ★ SoD 宏槽层：WR_SkillColor[MAGE]（技能名 -> 颜色槽位 1-199）
--   由脚本依据本文件 WR_CreateMacro 注释槽位 + 各旋转调用自动生成；
--   旋转统一用 WR_ColorFrame_ShowSkill(技能名) 取槽位，优先此处，缺失回退原数值。
--   所有槽位强制落在 1-199（职业专用）；200-240 为 Core/Global_Macros.lua 全局保留，严禁占用。
--   未在此表的符文新技能已自动分配到空闲职业槽；如需 AHK 按键请在各 WR_CreateMacro 补绑定。
-- ============================================================
WR_SkillColor["MAGE"] = {
    ["奥术飞弹"] = 14,
    ["奥术冲击"] = 13,
    ["奥术弹幕"] = 61,
    ["唤醒"] = 18,
    ["活动炸弹"] = 3,
    ["燃烧"] = 58,
    ["炎爆术"] = 2,
    ["火球术"] = 5,
    ["灼烧"] = 7,
    ["暴风雪"] = 26,
    ["冰枪术"] = 44,
    ["冰霜新星"] = 11,
    ["寒冰箭"] = 60,
    ["魔爆术"] = 75,
    ["奥术涌动"] = 74,
    ["法力宝石"] = 77,
    ["冰冷之血"] = 4,
    ["气定神闲"] = 301,
    ["奥术强化"] = 302,
    ["冲击波"] = 303,
    ["寒冰屏障"] = 304,
    ["急速冷却"] = 305,
    ["寒冰护盾"] = 306,
}
