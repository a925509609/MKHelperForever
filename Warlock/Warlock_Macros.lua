if WR_PlayerClass ~= "WARLOCK" then return end

local function CreateClassesMacro()
  WR_CreateMacro("NUMPAD1", "/cast 邪甲术") -- 1
  WR_CreateMacro("NUMPAD2", "/CAST 痛苦无常") -- 2
  WR_CreateMacro("NUMPAD3", "/CAST 痛苦诅咒") -- 3
  WR_CreateMacro("NUMPAD4", "/use 永冻冰晶") -- 4
  WR_CreateMacro("NUMPAD5", "/CAST 鬼影缠身") -- 5
  WR_CreateMacro("NUMPAD6", "/CAST 暗影箭") -- 6
  WR_CreateMacro("NUMPAD7", "/cast [target=pettarget] 暗影箭") -- 7
  WR_CreateMacro("NUMPAD8", "/use 10\n/use 13\n/use 14\n/cast 狮心\n/cast 血性狂怒(种族特长)") -- 8
  WR_CreateMacro("NUMPAD9", "/cast 魔甲术") -- 9
  WR_CreateMacro("NUMPAD0", "/cast [nochanneling:吸取生命] 生命分流") -- 10
  WR_CreateMacro("CTRL-NUMPAD1", "/CAST 吸取灵魂") -- 11
  WR_CreateMacro("CTRL-NUMPAD2", "/cast [target=focus] 痛苦无常") -- 12
  WR_CreateMacro("CTRL-NUMPAD3", "/cast [target=mouseover] 痛苦无常") -- 13
  WR_CreateMacro("CTRL-NUMPAD4", "/cast [target=focus] 腐蚀术") -- 14
  WR_CreateMacro("CTRL-NUMPAD5", "/cast [target=mouseover] 腐蚀术") -- 15
  WR_CreateMacro("CTRL-NUMPAD6", "/cast [target=focus] 痛苦诅咒") -- 16
  WR_CreateMacro("CTRL-NUMPAD7", "/cast [target=mouseover] 痛苦诅咒") -- 17
  WR_CreateMacro("CTRL-NUMPAD8", "/cast [target=pettarget] 痛苦诅咒") -- 18
  WR_CreateMacro("CTRL-NUMPAD9", "/cast [target=pettarget] 腐蚀术") -- 19
  WR_CreateMacro("CTRL-NUMPAD0", "/cast [target=pettarget] 痛苦无常") -- 20
  WR_CreateMacro("ALT-NUMPAD1", "/cast 恶魔法阵：召唤") -- 21
  WR_CreateMacro("ALT-NUMPAD2", "/stopcasting\n/cast 恶魔法阵：传送") -- 22
  WR_CreateMacro("ALT-NUMPAD3", "/cast [target=mouseover] 腐蚀之种") -- 23
  WR_CreateMacro("ALT-NUMPAD4", "/cast 厄运诅咒") -- 24
  WR_CreateMacro("ALT-NUMPAD5", "/cast [target=cursor] 地狱火") -- 25
  WR_CreateMacro("ALT-NUMPAD6", "/cast 暗影防护结界") -- 26
  WR_CreateMacro("ALT-NUMPAD7", "/cast [target=pettarget] 暗影箭(等级 1)") -- 27
  WR_CreateMacro("ALT-NUMPAD8", "/cast [target=focus] 暗影箭") -- 28
  WR_CreateMacro("ALT-NUMPAD9", "/cast [target=mouseover] 暗影箭") -- 29
  WR_CreateMacro("ALT-NUMPAD0", "/petattack") -- 30: 纯宠物攻击（不强制改宠物模式，避免"被动状态却攻击"的矛盾）
  WR_CreateMacro("ALT-CTRL-NUMPAD1", "/cast 灵魂链接") -- 31
  WR_CreateMacro("ALT-CTRL-NUMPAD2", "/cast 恶魔变形") -- 32
  WR_CreateMacro("ALT-CTRL-NUMPAD3", "/cast 恶魔支配\n/cast 召唤恶魔卫士") -- 33
  WR_CreateMacro("ALT-CTRL-NUMPAD4", "/cast 献祭光环") -- 34
  WR_CreateMacro("ALT-CTRL-NUMPAD5", "/use 邪能治疗石") -- 35
  WR_CreateMacro("ALT-CTRL-NUMPAD6", "/cast 献祭") -- 36
  WR_CreateMacro("ALT-CTRL-NUMPAD7", "/cast 恶魔增效") -- 37
  WR_CreateMacro("ALT-CTRL-NUMPAD8", "/cast 灵魂之火") -- 38
  WR_CreateMacro("ALT-CTRL-NUMPAD9", "/cast 烧尽") -- 39
  WR_CreateMacro("ALT-CTRL-NUMPAD0", "/cast 灵魂碎裂") -- 40
  WR_CreateMacro("SHIFT-F1", "/cast 腐蚀术") -- 41
  WR_CreateMacro("SHIFT-F2", "/cast 燃烧") -- 42
  WR_CreateMacro("SHIFT-F3", "/CAST 腐蚀之种") -- 43
  WR_CreateMacro("SHIFT-F11", "/cast 恶魔冲锋") -- 44
  WR_CreateMacro("SHIFT-F5", "/cast 拦截") -- 45
  WR_CreateMacro("SHIFT-F6", "/stopcasting") -- 46
  WR_CreateMacro("SHIFT-F7", "/use 10") -- 47
  WR_CreateMacro("SHIFT-F8", "/cast [target=mouseover] 暗影箭(等级 1)") -- 48
  WR_CreateMacro("SHIFT-F12", "/cast [target=focus] 献祭") -- 49
  WR_CreateMacro("SHIFT-F10", "/cast 生命分流(等级 1)") -- 50
  WR_CreateMacro("CTRL-F1", "/cast 暗影烈焰") -- 51
  WR_CreateMacro("CTRL-F2", "/cast 混乱之箭") -- 52
  WR_CreateMacro("CTRL-F3", "/cast 燃烧") -- 53
  WR_CreateMacro("CTRL-F11", "/cast 暗影灼烧") -- 54
  WR_CreateMacro("CTRL-F5", "/cast [target=cursor] 暗影之怒") -- 55
  WR_CreateMacro("CTRL-F6", "/targetenemy") -- 56
  WR_CreateMacro("CTRL-F7", "/petPASSIVE\n/petfollow") -- 57
  WR_CreateMacro("CTRL-F8", "/cast [@cursor] 萨隆邪铁炸弹") -- 58
  WR_CreateMacro("CTRL-F12", "/use [@player] 通用热力工程炸药\n/use [@player] 萨隆邪铁炸弹") -- 59
  WR_CreateMacro("CTRL-F10", "/USE 香辣猛犸小吃") -- 60
  WR_CreateMacro("ALT-CTRL-F1", "/cast [target=mouseover] 献祭") -- 61
  WR_CreateMacro("ALT-CTRL-F2", "/cast [target=focus] 献祭") -- 62
  WR_CreateMacro("ALT-CTRL-F3", "/cast [target=focus] 暗影箭(等级 1)") -- 63
  WR_CreateMacro("ALT-CTRL-F11", "/use 10\n/cast 血性狂怒(种族特长)") -- 64
  WR_CreateMacro("ALT-CTRL-F5", "/use 8") -- 65
  WR_CreateMacro("ALT-CTRL-F6", "/cast 灵魂碎裂") -- 66
  WR_CreateMacro("ALT-CTRL-F7", "/use [@player] 萨隆邪铁炸弹") -- 67
  WR_CreateMacro("ALT-CTRL-F8", "/use 速度药水\n/use 10\n/cast 血性狂怒(种族特长)") -- 68
  WR_CreateMacro("ALT-CTRL-F12", "/target 光明邪使菲奥拉\n/focus\n/target 黑暗邪使艾蒂丝") -- 69
  WR_CreateMacro("ALT-CTRL-F10", "/target 黑暗邪使艾蒂丝\n/focus\n/target 光明邪使菲奥拉") -- 70
  WR_CreateMacro("CTRL-SHIFT-F1", "/cast [target=focus] 放逐术") -- 71
  WR_CreateMacro("CTRL-SHIFT-F2", "/cast 狮心") -- 72
  WR_CreateMacro("CTRL-SHIFT-F3", "/use 10\n/cast 血性狂怒(种族特长)") -- 73
  WR_CreateMacro("CTRL-SHIFT-F11", "/targetexact 麦拉多·深谷游者\n/targetexact 伊林·雾蹄\n/cast 放逐术") -- 74: TOC-放逐奶德
  WR_CreateMacro("CTRL-SHIFT-F5", "/cast 混沌流星") -- 75
  WR_CreateMacro("CTRL-SHIFT-F6", "/cast [@cursor] 火焰之雨") -- 76
  WR_CreateMacro("CTRL-SHIFT-F7", "/cast 地狱烈焰") -- 77
  WR_CreateMacro("CTRL-SHIFT-F8", "/cast 暗影烈焰") -- 78
  WR_CreateMacro("CTRL-SHIFT-F12", "/cast 制造法术石") -- 79
  WR_CreateMacro("CTRL-SHIFT-F10", "/use 完美法术石 \n/use 16\n/click StaticPopup1Button1") -- 80
  WR_CreateMacro("ALT-CTRL-SHIFT-F1", "") -- 81
  WR_CreateMacro("ALT-CTRL-SHIFT-F2", "/cast [target=focus] 暗影箭(等级 1)") -- 82
  WR_CreateMacro("ALT-CTRL-SHIFT-F3", "") -- 83
  WR_CreateMacro("ALT-CTRL-SHIFT-F11", "/targetexact 安塔尔·缮炉者\n/targetexact 严肃的凯普斯\n/cast 恐惧") -- 84: TOC-恐惧牧师
  WR_CreateMacro("ALT-CTRL-SHIFT-F5", "/petautocaston 火焰箭") -- 85
  WR_CreateMacro("ALT-CTRL-SHIFT-F6", "/cast [nochanneling] 吸取生命") -- 86
  WR_CreateMacro("ALT-CTRL-SHIFT-F7", "") -- 87
  WR_CreateMacro("ALT-CTRL-SHIFT-F8", "") -- 88
  WR_CreateMacro("ALT-CTRL-SHIFT-F12", "") -- 89
  WR_CreateMacro("ALT-CTRL-SHIFT-F10", "/targetexact 萨缪尔\n/targetexact 萨卡加尔\n/cast 恐惧") -- 90: TOC-恐惧奶萨
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
  WR_CreateMacro("ALT-SHIFT-F10", "/targetexact 玛兹迪娜\n/targetexact 伊锐丝·影踪\n/targetexact 鲁姬卡\n/targetexact 阿莱希娅·月行者") -- 110: TOC-选盗贼猎人
  WR_CreateMacro("ALT-CTRL-SHIFT--", "") -- 111
  WR_CreateMacro("CTRL-SHIFT--", "/cast [@focus] 法术偷取") -- 112
  WR_CreateMacro("ALT-CTRL--", "/cast [@focus] 解除诅咒") -- 113
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
  WR_CreateMacro("ALT-CTRL-SHIFT-,", "/cast [@focus] 解除诅咒") -- 146
  WR_CreateMacro("CTRL-SHIFT-,", "/cast [@focus] 法术偷取") -- 147
  WR_CreateMacro("ALT-CTRL-,", "/focus") -- 148
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
  WR_CreateMacro("ALT-SHIFT-PAGEDOWN", "/cast 狂野魔精药水\n/use 狂野魔法药水") -- 184
  WR_CreateMacro("CTRL-PAGEDOWN", "/use [@player] 通用热力工程炸药") -- 185
  WR_CreateMacro("SHIFT-PAGEDOWN", "/use [@player] 萨隆邪铁炸弹") -- 186
  WR_CreateMacro("ALT-PAGEDOWN", "/cast [@cursor] 萨隆邪铁炸弹") -- 187
  WR_CreateMacro("ALT-CTRL-SHIFT-NUMPADDIVIDE", "/use 邪能治疗石") -- 188
  WR_CreateMacro("ALT-CTRL-NUMPADDIVIDE", "/use 8") -- 189
  WR_CreateMacro("CTRL-NUMPADDIVIDE", "/startattack") -- 190
  WR_CreateMacro("ALT-NUMPADDIVIDE", "/cancelaura 保护之手\n/cancelaura 能量灌注\n/cancelaura 专注魔法") -- 191
  WR_CreateMacro("ALT-CTRL-NUMPADMULTIPLY", "/focus player") -- 192
  WR_CreateMacro("CTRL-NUMPADMULTIPLY", "/cast 制造火焰石") -- 193
  WR_CreateMacro("ALT-NUMPADMULTIPLY", "/use 完美火焰石 \n/use 16\n/click StaticPopup1Button1") -- 194
  WR_CreateMacro("ALT-CTRL-NUMPADMINUS", "/cast 召唤小鬼") -- 195
  WR_CreateMacro("CTRL-NUMPADMINUS", "/cast 召唤魅魔") -- 196  -- [BExt] 脱战自动召唤宠物
  WR_CreateMacro("ALT-NUMPADMINUS", "/cast 召唤虚空行者") -- 197  -- [BExt] 脱战自动召唤宠物
  WR_CreateMacro("ALT-CTRL-NUMPADPLUS", "/cast 召唤地狱猎犬") -- 198  -- [BExt] 脱战自动召唤宠物
  WR_CreateMacro("CTRL-NUMPADPLUS", "") -- 199
  WR_CreateMacro("ALT-NUMPADPLUS", "") -- 200
end

local WR_EventFrame = CreateFrame("Frame")
WR_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
WR_EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
WR_EventFrame:SetScript("OnEvent", function(self, event, ...)
  if UnitClassBase("player") == "WARLOCK" and not InCombatLockdown() then
    CreateClassesMacro()
  end
end)

-- ============================================================
-- ★ SoD 宏槽层：WR_SkillColor[WARLOCK]（技能名 -> 颜色槽位 1-199）
--   由脚本依据本文件 WR_CreateMacro 注释槽位 + 各旋转调用自动生成；
--   旋转统一用 WR_ColorFrame_ShowSkill(技能名) 取槽位，优先此处，缺失回退原数值。
--   所有槽位强制落在 1-199（职业专用）；200-240 为 Core/Global_Macros.lua 全局保留，严禁占用。
--   未在此表的符文新技能已自动分配到空闲职业槽；如需 AHK 按键请在各 WR_CreateMacro 补绑定。
-- ============================================================
WR_SkillColor["WARLOCK"] = {
    ["腐蚀之种"] = 23,
    ["鬼影缠身"] = 5,
    ["吸取灵魂"] = 11,
    ["痛苦无常"] = 2,
    ["腐蚀术"] = 14,
    ["痛苦诅咒"] = 3,
    ["暗影箭"] = 6,
    ["生命分流"] = 10,
    ["恶魔变形"] = 32,
    ["献祭"] = 36,
    ["灵魂之火"] = 38,
    ["烧尽"] = 39,
    ["厄运诅咒"] = 24,
    ["燃烧"] = 42,
    ["混乱箭"] = 98,
    ["强化诅咒"] = 301,
    ["疲劳诅咒"] = 302,
    ["生命虹吸"] = 303,
    ["吸取希望"] = 304,
    ["恶魔牺牲"] = 305,
    ["恶魔支配"] = 306,
    ["灵魂链接"] = 307,
    ["暗影灼烧"] = 308,
    ["浩劫诅咒"] = 309,
}
