-- ============================================================
-- Paladin_Macros.lua
-- 功能：为圣骑士创建大量按键绑定的宏命令
--       覆盖技能施放、目标选择、焦点设置、物品使用等
-- ============================================================

if WR_PlayerClass ~= "PALADIN" then return end

local function CreateClassesMacro()
    WR_CreateMacro("NUMPAD1", "/CAST 愤怒之锤") -- 1
    WR_CreateMacro("NUMPAD2", "/CAST 审判") -- 2
    WR_CreateMacro("NUMPAD3", "/CAST 十字军打击") -- 3
    WR_CreateMacro("NUMPAD4", "") -- 4（原「神圣风暴」：本版本无此技能，已清理；键位与色块保留占位，供后续技能使用）
    WR_CreateMacro("NUMPAD5", "/CAST 奉献") -- 5
    WR_CreateMacro("NUMPAD6", "/CAST 驱邪术") -- 6
    WR_CreateMacro("NUMPAD7", "/CAST 神圣愤怒") -- 7
    WR_CreateMacro("NUMPAD8", "/CAST 腐蚀圣印\n/CAST 复仇圣印") -- 8
    WR_CreateMacro("NUMPAD9", "/cast 公正圣印") -- 9
    WR_CreateMacro("NUMPAD0", "/CAST 圣光闪现") -- 10
    WR_CreateMacro("CTRL-NUMPAD1", "/CAST 愤怒圣印") -- 11
    WR_CreateMacro("CTRL-NUMPAD2", "/CAST 命令圣印") -- 12
    WR_CreateMacro("CTRL-NUMPAD3", "/CAST 清算之手") -- 13
    WR_CreateMacro("CTRL-NUMPAD4", "/stopattack") -- 14
    WR_CreateMacro("CTRL-NUMPAD5", "/STARTATTACK") -- 15
    WR_CreateMacro("CTRL-NUMPAD6", "/CAST 正义之锤") -- 16
    WR_CreateMacro("CTRL-NUMPAD7", "/CAST 审判") -- 17
    WR_CreateMacro("CTRL-NUMPAD8", "/CAST 圣盾术") -- 18
    WR_CreateMacro("CTRL-NUMPAD9", "/cast [target=mouseover] 自由之手") -- 19
    WR_CreateMacro("CTRL-NUMPAD0", "/CAST 驱邪术") -- 20
    WR_CreateMacro("ALT-NUMPAD1", "/CAST 复仇者之盾") -- 21
    WR_CreateMacro("ALT-NUMPAD2", "/cast 制裁之锤") -- 22
    WR_CreateMacro("ALT-NUMPAD3", "/cast [target=focus,exists] 牺牲之手;牺牲之手") -- 23
    WR_CreateMacro("ALT-NUMPAD4", "/CAST 神圣之盾") -- 24
    WR_CreateMacro("ALT-NUMPAD5", "/cancelaura 神圣牺牲\n/cast 神圣牺牲") -- 25
    WR_CreateMacro("ALT-NUMPAD6", "/cast 正义盾击") -- 26
    WR_CreateMacro("ALT-NUMPAD7", "/cast [target=targettarget] 清洁术") -- 27
    WR_CreateMacro("ALT-NUMPAD8", "/cast [target=mouseover] 制裁之锤") -- 28
    WR_CreateMacro("ALT-NUMPAD9", "/CAST 殉难圣印") -- 29（原 /cancelAura 森罗万象；改为殉难圣印：惩戒常驻圣印色块槽 29 点亮时须真正施放，否则「其他圣印不打」）
    WR_CreateMacro("ALT-NUMPAD0", "/CAST 十字军圣印") -- 30（原「神圣风暴」占位空槽；分配给十字军圣印：防护单体起手/惩戒/共享圣印保持均点亮槽 30，空宏会导致十字军圣印永远打不出）
    WR_CreateMacro("ALT-CTRL-NUMPAD1", "/CAST 正义之怒") -- 31
    WR_CreateMacro("ALT-CTRL-NUMPAD2", "/use 10\n/use 13\n/use 14\n/cast 狮心\n/CAST 复仇之怒") -- 32
    WR_CreateMacro("ALT-CTRL-NUMPAD3", "/cast 清洁术") -- 33
    WR_CreateMacro("ALT-CTRL-NUMPAD4", "/cast 自由之手") -- 34
    WR_CreateMacro("ALT-CTRL-NUMPAD5", "/CAST 拯救之手") -- 35
    WR_CreateMacro("ALT-CTRL-NUMPAD6", "/USE 10") -- 36
    WR_CreateMacro("ALT-CTRL-NUMPAD7", "/use 邪能治疗石") -- 37
    WR_CreateMacro("ALT-CTRL-NUMPAD8", "/use 速度药水") -- 38
    WR_CreateMacro("ALT-CTRL-NUMPAD9", "/use [@player] 通用热力工程炸药\n/use [@player] 萨隆邪铁炸弹") -- 39
    WR_CreateMacro("ALT-CTRL-NUMPAD0", "/cast 圣疗术") -- 40
    WR_CreateMacro("SHIFT-F1", "/use 雪球") -- 41
    WR_CreateMacro("SHIFT-F2", "/use [@player] 萨隆邪铁炸弹") -- 42
    WR_CreateMacro("SHIFT-F3", "/cast [target=player] 清洁术") -- 43
    WR_CreateMacro("SHIFT-F11", "/cast [target=target] 清洁术") -- 44
    WR_CreateMacro("SHIFT-F5", "/cast [target=targettarget] 牺牲之手") -- 45
    WR_CreateMacro("SHIFT-F6", "/CAST 审判") -- 46
    WR_CreateMacro("SHIFT-F7", "/cast 正义圣印") -- 47
    WR_CreateMacro("SHIFT-F8", "/cast [target=player] 圣疗术") -- 48
    WR_CreateMacro("SHIFT-F12", "/cast [target=player] 庇护祝福") -- 49
    WR_CreateMacro("SHIFT-F10", "/cast [target=player] 圣洁护盾") -- 50
    WR_CreateMacro("CTRL-F1", "/cast 祈求圣光") -- 51
    WR_CreateMacro("CTRL-F2", "/cast stopcasting") -- 52
    WR_CreateMacro("CTRL-F3", "/cast 专注光环") -- 53
    WR_CreateMacro("CTRL-F11", "/cast 光明圣印") -- 54
    WR_CreateMacro("CTRL-F5", "/cast 光环掌握") -- 55
    WR_CreateMacro("CTRL-F6", "/cast 祈求圣光") -- 56
    WR_CreateMacro("CTRL-F7", "/cast [target=focus] 愤怒之锤") -- 57
    WR_CreateMacro("CTRL-F8", "/cast [target=player] 强效庇护祝福") -- 58
    WR_CreateMacro("CTRL-F12", "/cast [target=mouseover] 清洁术") -- 59
    WR_CreateMacro("CTRL-F10", "/cast [target=mouseover] 拯救之手") -- 60
    WR_CreateMacro("ALT-CTRL-F1", "/cast [@focus] 自由之手") -- 61
    WR_CreateMacro("ALT-CTRL-F2", "/cast [@focus] 制裁之锤") -- 62
    WR_CreateMacro("ALT-CTRL-F3", "/cast [@focus] 清洁术") -- 63
    WR_CreateMacro("ALT-CTRL-F11", "/cast [@focus] 保护之手") -- 64
    WR_CreateMacro("ALT-CTRL-F5", "/use 8") -- 65
    WR_CreateMacro("ALT-CTRL-F6", "/cast [@focus] 保护之手") -- 66
    WR_CreateMacro("ALT-CTRL-F7", "/cast [target=mouseover] 保护之手") -- 67
    WR_CreateMacro("ALT-CTRL-F8", "/use 速度药水") -- 68
    WR_CreateMacro("ALT-CTRL-F12", "/target 黑暗邪使艾蒂丝") -- 69
    WR_CreateMacro("ALT-CTRL-F10", "/target 光明邪使菲奥拉") -- 70
    WR_CreateMacro("CTRL-SHIFT-F1", "/cast [@focus] 拯救之手") -- 71
    WR_CreateMacro("CTRL-SHIFT-F11", "/CAST 神圣打击") -- 74
    WR_CreateMacro("CTRL-SHIFT-F5", "/cast [@focus] 庇护祝福") -- 75
    WR_CreateMacro("CTRL-SHIFT-F6", "/cast [@focus] 强效庇护祝福") -- 76
    WR_CreateMacro("CTRL-SHIFT-F7", "/cast [target=mouseover] 牺牲之手") -- 77
    WR_CreateMacro("CTRL-SHIFT-F8", "/CAST 圣佑术") -- 78
    WR_CreateMacro("CTRL-SHIFT-F12", "") -- 79
    WR_CreateMacro("CTRL-SHIFT-F10", "") -- 80
    WR_CreateMacro("ALT-CTRL-SHIFT-F1", "/cast 力量祝福") -- 81
    WR_CreateMacro("ALT-CTRL-SHIFT-F2", "/cast 智慧祝福") -- 82
    WR_CreateMacro("ALT-CTRL-SHIFT-F3", "/cast 王者祝福") -- 83
    WR_CreateMacro("ALT-CTRL-SHIFT-F4", "/cast 强效力量祝福") -- 84
    WR_CreateMacro("ALT-CTRL-SHIFT-F5", "/cast 强效智慧祝福") -- 85
    WR_CreateMacro("ALT-CTRL-SHIFT-F6", "/cast 强效王者祝福") -- 86
    WR_CreateMacro("ALT-CTRL-SHIFT-F7", "") -- 87
    WR_CreateMacro("ALT-CTRL-SHIFT-F8", "") -- 88
    WR_CreateMacro("ALT-CTRL-SHIFT-F12", "") -- 89
  WR_CreateMacro("ALT-CTRL-SHIFT-F10", "/targetenemy") -- 90
    WR_CreateMacro("ALT-F1", "") -- 91
    WR_CreateMacro("ALT-F2", "") -- 92
    WR_CreateMacro("ALT-F3", "") -- 93
    WR_CreateMacro("ALT-F11", "") -- 94
    WR_CreateMacro("ALT-F5", "") -- 95
    WR_CreateMacro("ALT-F6", "/cast 神启") -- 96
    WR_CreateMacro("ALT-F7", "/focus [@party1target,exists,nodead,nocombat]") -- 97
    WR_CreateMacro("ALT-F8", "/focus [@party2target,exists,nodead,nocombat]") -- 98
    WR_CreateMacro("ALT-F12", "/focus [@party3target,exists,nodead,nocombat]") -- 99
    WR_CreateMacro("ALT-F10", "/focus [@party4target,exists,nodead,nocombat]") -- 100
    WR_CreateMacro("ALT-SHIFT-F1", "/stopcasting") -- 101
    WR_CreateMacro("ALT-SHIFT-F2", "/cast [@focus] 力量祝福") -- 102
    WR_CreateMacro("ALT-SHIFT-F3", "/cast [@focus] 强效力量祝福") -- 103
    WR_CreateMacro("ALT-SHIFT-F11", "/cast [@focus] 智慧祝福") -- 104
    WR_CreateMacro("ALT-SHIFT-F5", "/cast [@focus] 强效智慧祝福") -- 105
    WR_CreateMacro("ALT-SHIFT-F6", "/cast [@focus] 王者祝福") -- 106
    WR_CreateMacro("ALT-SHIFT-F7", "/cast [@focus] 强效王者祝福") -- 107
    WR_CreateMacro("ALT-SHIFT-F8", "/cast 智慧圣印") -- 108
    WR_CreateMacro("ALT-SHIFT-F12", "/cast [@focus] 圣光闪现") -- 109
    WR_CreateMacro("ALT-SHIFT-F10", "/cast [@focus] 圣光术") -- 110
    WR_CreateMacro("ALT-CTRL-SHIFT--", "/cast [@focus] 圣洁护盾") -- 111
    WR_CreateMacro("CTRL-SHIFT--", "/cast [@focus] 圣光道标") -- 112
    WR_CreateMacro("ALT-CTRL--", "/cast [@focus] 神圣震击") -- 113
    WR_CreateMacro("ALT-SHIFT--", "/cast 神恩术") -- 114
    -- ★ 2026-11-08：跟随类宏加 nocombat 守卫
    --   实证：AHK 在战斗中连按 6 次 ALT-- （=/follow focus），
    --   而插件当时并没有点亮任何跟随色块（色块序列只有技能块），属 AHK 主动误发键。
    --   /follow 本身在战斗中会被客户端拒绝，但每次发键都会产生一次无效动作+聊天刷屏，
    --   加 nocombat 后战斗中直接不执行，彻底静默。
    WR_CreateMacro("CTRL--", "/follow [@target,exists,nodead,help,nocombat]") -- 115
    -- ★ 2026-11-08：加 nocombat + help 守卫，避免战斗中/对敌人误设焦点
    --   （原为 /focus [@target,exists,nodead]，战斗中会把当前目标（常是怪）设成焦点）
    WR_CreateMacro("SHIFT--", "/focus [@target,exists,nodead,help,nocombat]") -- 116
    WR_CreateMacro("ALT--", "/follow [@focus,exists,nodead,help,nocombat]") -- 117
    WR_CreateMacro("ALT-CTRL-SHIFT-=", "/target 凯雷塞斯王子") -- 118
    WR_CreateMacro("CTRL-SHIFT-=", "/target 塔达拉姆王子") -- 119
    WR_CreateMacro("ALT-CTRL-=", "/target 瓦拉纳王子") -- 120
    WR_CreateMacro("ALT-SHIFT-=", "/focus [@raid1,exists,nodead,nocombat]") -- 121
    WR_CreateMacro("CTRL-=", "/focus [@raid2,exists,nodead,nocombat]") -- 122
    WR_CreateMacro("SHIFT-=", "/focus [@raid3,exists,nodead,nocombat]") -- 123
    WR_CreateMacro("ALT-=", "/focus [@raid4,exists,nodead,nocombat]") -- 124
    WR_CreateMacro("ALT-CTRL-SHIFT-[", "/focus [@raid5,exists,nodead,nocombat]") -- 125
    WR_CreateMacro("CTRL-SHIFT-[", "/focus [@raid6,exists,nodead,nocombat]") -- 126
    WR_CreateMacro("ALT-CTRL-[", "/focus [@raid7,exists,nodead,nocombat]") -- 127
    WR_CreateMacro("ALT-SHIFT-[", "/focus [@raid8,exists,nodead,nocombat]") -- 128
    WR_CreateMacro("CTRL-[", "/focus [@raid9,exists,nodead,nocombat]") -- 129
    WR_CreateMacro("SHIFT-[", "/focus [@raid10,exists,nodead,nocombat]") -- 130
    WR_CreateMacro("ALT-[", "/focus [@raid11,exists,nodead,nocombat]") -- 131
    WR_CreateMacro("ALT-CTRL-SHIFT-]", "/focus [@raid12,exists,nodead,nocombat]") -- 132
    WR_CreateMacro("CTRL-SHIFT-]", "/focus [@raid13,exists,nodead,nocombat]") -- 133
    WR_CreateMacro("ALT-CTRL-]", "/focus [@raid14,exists,nodead,nocombat]") -- 134
    WR_CreateMacro("ALT-SHIFT-]", "/focus [@raid15,exists,nodead,nocombat]") -- 135
    WR_CreateMacro("CTRL-]", "/focus [@raid16,exists,nodead,nocombat]") -- 136
    WR_CreateMacro("SHIFT-]", "/focus [@raid17,exists,nodead,nocombat]") -- 137
    WR_CreateMacro("ALT-]", "/focus [@raid18,exists,nodead,nocombat]") -- 138
    WR_CreateMacro("ALT-CTRL-SHIFT-\\", "/focus [@raid19,exists,nodead,nocombat]") -- 139
    WR_CreateMacro("CTRL-SHIFT-\\", "/focus [@raid20,exists,nodead,nocombat]") -- 140
    WR_CreateMacro("ALT-CTRL-\\", "/focus [@raid21,exists,nodead,nocombat]") -- 141
    WR_CreateMacro("ALT-SHIFT-\\", "/focus [@raid22,exists,nodead,nocombat]") -- 142
    WR_CreateMacro("CTRL-\\", "/focus [@raid23,exists,nodead,nocombat]") -- 143
    WR_CreateMacro("SHIFT-\\", "/focus [@raid24,exists,nodead,nocombat]") -- 144
    WR_CreateMacro("ALT-\\", "/focus [@raid25,exists,nodead,nocombat]") -- 145
    -- ★ 2026-11-08：三个「通用型」焦点宏加 nocombat 守卫
    --   这三条不指定具体队员（player/target/mouseover），最容易在战斗中被动触发；
    --   加 nocombat 后战斗中一律不执行，避免误把当前目标/鼠标指向设成焦点。
    WR_CreateMacro("ALT-CTRL-SHIFT-,", "/focus [@player,nocombat]") -- 146
    WR_CreateMacro("CTRL-SHIFT-,", "/focus [@target,exists,nodead,nocombat]") -- 147
    WR_CreateMacro("ALT-CTRL-,", "/focus [@mouseover,exists,nodead,nocombat]") -- 148
    WR_CreateMacro("ALT-SHIFT-,", "/cast [@focus] 救赎") -- 149
    WR_CreateMacro("CTRL-,", "/cast [@focus] 圣疗术") -- 150
    WR_CreateMacro("SHIFT-,", "/focus [@raid1target,exists,nodead,nocombat]") -- 151
    WR_CreateMacro("ALT-,", "/focus [@raid2target,exists,nodead,nocombat]") -- 152
    WR_CreateMacro("ALT-CTRL-SHIFT-.", "/focus [@raid3target,exists,nodead,nocombat]") -- 153
    WR_CreateMacro("CTRL-SHIFT-.", "/focus [@raid4target,exists,nodead,nocombat]") -- 154
    WR_CreateMacro("ALT-CTRL-.", "/focus [@raid5target,exists,nodead,nocombat]") -- 155
    WR_CreateMacro("ALT-SHIFT-.", "/focus [@raid6target,exists,nodead,nocombat]") -- 156
    WR_CreateMacro("CTRL-.", "/focus [@raid7target,exists,nodead,nocombat]") -- 157
    WR_CreateMacro("SHIFT-.", "/focus [@raid8target,exists,nodead,nocombat]") -- 158
    WR_CreateMacro("ALT-.", "/focus [@raid9target,exists,nodead,nocombat]") -- 159
    WR_CreateMacro("ALT-CTRL-SHIFT-/", "/focus [@raid10target,exists,nodead,nocombat]") -- 160
    WR_CreateMacro("CTRL-SHIFT-/", "/focus [@raid11target,exists,nodead,nocombat]") -- 161
    WR_CreateMacro("ALT-CTRL-/", "/focus [@raid12target,exists,nodead,nocombat]") -- 162
    WR_CreateMacro("ALT-SHIFT-/", "/focus [@raid13target,exists,nodead,nocombat]") -- 163
    WR_CreateMacro("CTRL-/", "/focus [@raid14target,exists,nodead,nocombat]") -- 164
    WR_CreateMacro("SHIFT-/", "/focus [@raid15target,exists,nodead,nocombat]") -- 165
    WR_CreateMacro("ALT-/", "/focus [@raid16target,exists,nodead,nocombat]") -- 166
    WR_CreateMacro("ALT-CTRL-SHIFT-INSERT", "/focus [@raid17target,exists,nodead,nocombat]") -- 167
    WR_CreateMacro("CTRL-SHIFT-INSERT", "/focus [@raid18target,exists,nodead,nocombat]") -- 168
    WR_CreateMacro("ALT-CTRL-INSERT", "/focus [@raid19target,exists,nodead,nocombat]") -- 169
    WR_CreateMacro("ALT-SHIFT-INSERT", "/focus [@raid20target,exists,nodead,nocombat]") -- 170
    WR_CreateMacro("CTRL-INSERT", "/focus [@raid21target,exists,nodead,nocombat]") -- 171
    WR_CreateMacro("SHIFT-INSERT", "/focus [@raid22target,exists,nodead,nocombat]") -- 172
    WR_CreateMacro("ALT-INSERT", "/focus [@raid23target,exists,nodead,nocombat]") -- 173
    WR_CreateMacro("ALT-CTRL-SHIFT-PAGEUP", "/focus [@raid24target,exists,nodead,nocombat]") -- 174
    WR_CreateMacro("CTRL-SHIFT-PAGEUP", "/focus [@raid25target,exists,nodead,nocombat]") -- 175
    -- ★★ 2026-11-08：这 4 个 partyN 焦点宏加 nocombat 守卫。
    --   实证：AHK 在战斗中/脱战后连按 6 次 ALT-SHIFT-PAGEUP（=/focus party2），
    --   而插件当时没有点亮任何焦点色块 → 属 AHK 主动误发键，把队伍第 2 名反复设成焦点。
    --   注意：本文件在 Global_Macros.lua 之后加载，会**覆盖**同名键位的注册，
    --   因此必须在这里也加守卫，否则改了 Global_Macros 也无效。
    WR_CreateMacro("ALT-CTRL-PAGEUP", "/focus [@party1,exists,nodead,nocombat]") -- 176
    WR_CreateMacro("ALT-SHIFT-PAGEUP", "/focus [@party2,exists,nodead,nocombat]") -- 177
    WR_CreateMacro("CTRL-PAGEUP", "/focus [@party3,exists,nodead,nocombat]") -- 178
    WR_CreateMacro("SHIFT-PAGEUP", "/focus [@party4,exists,nodead,nocombat]") -- 179
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
    WR_CreateMacro("ALT-CTRL-NUMPADMULTIPLY", "/focus [@player,nocombat]") -- 192
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
    if UnitClassBase("player") == "PALADIN" and not InCombatLockdown() then
        CreateClassesMacro()
    end
end)

-- ============================================================
-- ★ SoD 宏槽层：WR_SkillColor[PALADIN]（技能名 -> 颜色槽位 1-199）
--   由脚本依据本文件 WR_CreateMacro 注释槽位 + 各旋转调用自动生成；
--   旋转统一用 WR_ColorFrame_ShowSkill(技能名) 取槽位，优先此处，缺失回退原数值。
--   所有槽位强制落在 1-199（职业专用）；200-240 为 Core/Global_Macros.lua 全局保留，严禁占用。
--   未在此表的符文新技能已自动分配到空闲职业槽；如需 AHK 按键请在各 WR_CreateMacro 补绑定。
-- ============================================================
WR_SkillColor["PALADIN"] = {
    ["圣疗术"] = 48,
    ["圣光道标"] = 112,
    ["神圣震击"] = 113,
    ["圣光术"] = 110,
    ["圣光闪现"] = 10,
    ["自由之手"] = 19,
    ["圣盾术"] = 18,
    ["清洁术"] = 27,
    ["奉献"] = 5,
    ["神圣之盾"] = 24,
    ["愤怒之锤"] = 1,
    ["神圣牺牲"] = 25,
    ["力量祝福"] = 81,
    -- ★ 2026-11-06：祝福下拉对应的宏槽补全（与宏 ALT-CTRL-SHIFT-F2~F6 一致）
    ["智慧祝福"] = 82,
    ["王者祝福"] = 83,
    ["强效力量祝福"] = 84,
    ["强效智慧祝福"] = 85,
    ["强效王者祝福"] = 86,
    ["光环掌握"] = 55,
    ["十字军打击"] = 3,
    -- 槽 4 已释放（原「神圣风暴」本版本不存在）：色块与按键保留占位，后续可分配给其他技能
    ["洁净术"] = 14,
    ["攻击"] = 15,
    ["复仇之手"] = 44,
    ["审判"] = 2,
    ["驱邪"] = 20,
    ["复仇之怒"] = 28,
    ["殉难圣印"] = 29,
    ["十字军圣印"] = 30,
    ["十字军打击(回蓝)"] = 34,
    -- ★ Forever 新增技能（无限天赋/经典技能）槽位补全
    ["驱邪术"] = 20,          -- 与旧 驱邪 同槽，现代客户端法术名
    ["制裁之锤"] = 22,        -- 与宏 ALT-NUMPAD2 一致
    ["正义之怒"] = 31,        -- 防护仇恨光环（宏 ALT-CTRL-NUMPAD1）
    ["正义圣印"] = 47,        -- 与宏 SHIFT-F7 一致
    ["命令圣印"] = 12,        -- 与宏 CTRL-NUMPAD2 一致
    ["公正圣印"] = 9,
    ["复仇光环"] = 49,        -- 输出光环提醒（非色块提示）
    ["圣洁光环"] = 50,
    ["神恩术"] = 114,         -- 与宏 ALT-SHIFT-- 一致
    -- ★★ 2026-11-08 关键修复「战斗中莫名其妙跟随/设焦点」：
    --   115 / 116 / 117 这三个槽位是**旧版跟随系统**的专用色块：
    --     115 = 目标跟随(/follow target)  116 = 设置焦点(/focus)  117 = 焦点跟随(/follow focus)
    --   跟随系统在 2026-08-30 已整体迁移到 201-210 段（见 Core/GX.lua:47），
    --   但这三个「无限天赋」技能仍然占着旧槽位没挪走 —— 迁移只做了一半。
    --   后果：防护/惩戒循环点亮 117（迅捷审判）时，AHK 按 ALT-- 执行 /follow focus，
    --   表现为「莫名其妙跟随一下 / 把队友设成焦点」。实证日志已抓到
    --   `宏 ALT-- → /follow focus` 战斗中连按 6 次，而当时色块序列正是天赋技能。
    --   修复：这三个天赋技能改为**只提示不占色块槽位**（值设 nil = 不映射），
    --   循环里改为走 PigAlert 文字提示，彻底避免与跟随/焦点键位撞车。
    --   如需恢复色块提示，必须另选 ≥ 241 的空闲槽位并同步 AHK ColorMap。
    ["真理之声"] = nil,       -- 原 115（与旧「目标跟随」撞车）
    ["光之守夜"] = nil,       -- 原 116（与旧「设置焦点」撞车）
    ["迅捷审判"] = nil,       -- 原 117（与旧「焦点跟随」撞车）
    -- ★★★ 2026-11-10 修复：圣殿壁垒原写 118，注释说「118 无冲突」是错的。
    --   118 在本文件 :132 已绑定 /target 凯雷塞斯王子（纳克萨玛斯 BOSS）：
    --     WR_CreateMacro("ALT-CTRL-SHIFT-=", "/target 凯雷塞斯王子") -- 118
    --   后果：① 圣殿壁垒永远打不出去（AHK 按的是切目标宏）；
    --         ② 色块亮 1.5 秒 → AHK 连按 15~25 次 → 战斗中强行把目标切走，
    --            直接毁掉当前目标与后续整条循环（比不出技能严重得多）。
    --   按 115/116/117 同一处理：不占色块槽位，循环里改为只弹文字提示。
    ["圣殿壁垒"] = nil,       -- 原 118（与 /target 凯雷塞斯王子 撞车）
    -- ★ 2026-11-06：防骑新增技能（槽位与宏注释槽位一致）
    ["愤怒圣印"] = 11,        -- 防护常驻圣印（宏 CTRL-NUMPAD1）
    ["神圣打击"] = 74,        -- 防护主要仇恨技能（宏 CTRL-SHIFT-F11）
    ["圣佑术"] = 78,          -- 低血减伤（宏 CTRL-SHIFT-F8）
    -- ★ 2026-11-07：光明圣印（已学）—— 与宏 CTRL-F11 一致（光明圣印常驻开关使用）
    ["光明圣印"] = 54,
    -- ★ 2026-11-09：智慧圣印（已学，可插入；回复法力）—— 与宏 ALT-SHIFT-F8 一致
    --   槽 108 颜色 0x892888 → AHK ColorMap "!+{F8}"，链路已核对一致
    ["智慧圣印"] = 108,
}
