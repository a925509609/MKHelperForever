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
  -- ★★ 2026-11-12：78 原为空占位（CTRL-SHIFT-F8），启用为「魔爆术」宏。
  --   背景：火法/奥法循环一直点亮 75 号槽来提示「魔爆术」，但 75 号槽绑的是
  --   /petautocaston 水箭（开关水元素自动施法），全仓库也没有任何宏绑魔爆术 ——
  --   于是 AHK 读到 75 的颜色会去开关水元素，而不是放 AOE。
  --   现在把 78 号槽（ColorTable 有、AHK 已映射 ^+{F8}、原为空占位）绑成魔爆术，
  --   并把 WR_SkillColor["MAGE"]["魔爆术"] 从 75 改到 78。
  WR_CreateMacro("CTRL-SHIFT-F8", "/cast 魔爆术") -- 78
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
  WR_CreateMacro("ALT-SHIFT-F6", "/cast 冰甲术") -- 106 奥法：冰甲术
  WR_CreateMacro("ALT-SHIFT-F7", "/cast 魔甲术") -- 107 奥法：魔甲术
  WR_CreateMacro("ALT-SHIFT-F8", "/cast 奥术智慧") -- 108 奥法：奥术智慧（自己）
  WR_CreateMacro("ALT-SHIFT-F12", "/cast [@focus] 奥术智慧") -- 109 奥法：奥术智慧（焦点队友）
  WR_CreateMacro("ALT-SHIFT-F10", "/cast 奥术愤怒") -- 110 奥法：奥术愤怒
  WR_CreateMacro("ALT-CTRL-SHIFT--", "/use 阿加治疗药水\n/use 焕生治疗药水") -- 111 奥法：治疗药水
  WR_CreateMacro("CTRL-SHIFT--", "/cast 解除次级诅咒") -- 112 奥法：解除次级诅咒（自己）
  WR_CreateMacro("ALT-CTRL--", "/cast [@focus] 解除次级诅咒") -- 113 奥法：解除次级诅咒（焦点队友）
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
    -- ★★ 2026-11-12：魔爆术从 75 改到 78。
    --   75 号槽实际绑的是 /petautocaston 水箭（开关水元素自动施法），
    --   全仓库没有任何宏绑魔爆术 → 火法/奥法点亮 75 会让 AHK 去开关水元素。
    --   现在 78 号槽（原空占位 CTRL-SHIFT-F8）已绑 /cast 魔爆术。
    ["魔爆术"] = 78,
    ["奥术涌动"] = 74,
    ["法力宝石"] = 77,
    -- ★★ 2026-11-12：4 号槽实际绑的是 /CAST 活动炸弹，不是冰冷之血。
    --   且 Forever 冰霜树里根本没有「冰冷之血」（那是 SoD 腿符文），
    --   这条登记已无意义且会误导后续接入者 → 删除。
    -- ["冰冷之血"] = 4,
    -- ★★ 2026-11-12 修复：下面三个原来登记 301/302/303/304/305/306，
    --   但 Core/UI_ColorFrame.lua 的 ColorTable 只到 240（1..240）——
    --   WR_Frame_Color[304] 是 nil，WR_CreateSingleColorSlot 会把它送进
    --   PIG_BGRtoBGR 做 math.floor(nil / 0x10000) → 直接抛错（整个 tick 崩掉）。
    --   现在改为 Mage_Macros.lua 里真实绑定了宏的槽位：
    --     寒冰屏障 ALT-CTRL-NUMPAD2 = 32  → /cast 寒冰屏障
    --     急速冷却 ALT-CTRL-F3      = 63  → /cast 急速冷却
    --     寒冰护体 ALT-CTRL-F5      = 65  → /cast 寒冰护体
    --   顺带把「寒冰护盾」改成本服客户端真名「寒冰护体」（65 号槽的宏就是这个名字），
    --   避免 WR_SoD_ResolveSlot("寒冰护盾") 反查不到而回落。
    ["寒冰屏障"] = 32,
    ["急速冷却"] = 63,
    ["寒冰护体"] = 65,
    ["寒冰护盾"] = 65,   -- 别名：Data/Forever_Abilities.lua 的 zh 用「寒冰护盾」
    -- ★★ 2026-11-12：气定神闲 / 奥术强化 / 冲击波 的 301/302/303 同样是
    --   ColorTable 不存在的 key，会崩。它们目前没有任何循环在点亮，
    --   但为防将来误用，这里一并改成真实绑定的槽位：
    --     气定神闲 CTRL-NUMPAD5 = 15 → /cast 气定神闲
    --     奥术强化 CTRL-NUMPAD6 = 16 → /cast 奥术强化
    --     冲击波   ALT-NUMPAD2  = 22 → /cast 冲击波
    ["气定神闲"] = 15,
    ["奥术强化"] = 16,
    ["冲击波"] = 22,
    -- ★ 2026-11-16 奥法页新增/补齐：只登记真实存在且有宏绑定的槽位。
    ["奥术愤怒"] = 110,       -- ALT-SHIFT-F10 /cast 奥术愤怒
    ["霜火之箭"] = 20,        -- CTRL-NUMPAD0   /cast 霜火之箭
    ["烈焰风暴"] = 23,        -- ALT-NUMPAD3    /cast [target=cursor] 烈焰风暴
    ["闪现术"] = 31,          -- ALT-CTRL-NUMPAD1 /cast 闪现术
    ["闪现"] = 31,            -- 别名
    ["法术反制"] = 46,        -- SHIFT-F6       /cast 法术反制
    ["法术吸取"] = 43,        -- SHIFT-F3       /cast 法术吸取
    ["切换目标"] = 40,        -- ALT-CTRL-NUMPAD0 /targetenemy
    ["冰甲术"] = 106,         -- ALT-SHIFT-F6   /cast 冰甲术
    ["魔甲术"] = 107,         -- ALT-SHIFT-F7   /cast 魔甲术
    ["奥术智慧"] = 108,       -- ALT-SHIFT-F8   /cast 奥术智慧
    ["奥术智慧(队友)"] = 109, -- ALT-SHIFT-F12  /cast [@focus] 奥术智慧
    ["治疗药水"] = 111,       -- ALT-CTRL-SHIFT-- /use 阿加/焕生治疗药水
    ["解除次级诅咒"] = 112,   -- CTRL-SHIFT--   /cast 解除次级诅咒
    ["解除次级诅咒(队友)"] = 113, -- ALT-CTRL--  /cast [@focus] 解除次级诅咒
}
