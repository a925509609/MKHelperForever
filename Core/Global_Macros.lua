-- ============================================================
-- Global_Macros.lua
-- 全局宏：所有职业通用（不随当前职业变化），随插件加载一次即对所有职业生效。
-- 与各职业 *Macros.lua 的区别：那里是逐职业专属宏；这里是跨职业共享宏。
-- ============================================================
--
-- ★ 颜色 201-240 段宏登记（与 AHK 启动器 8.30 的 ColorMap 一一对应）
--   本文件是「颜色索引 -> 宏」的集中登记处：
--     · 使用中的索引挂真实宏（WR_CreateMacro）；
--     · 预留索引（205-210）留空，不挂宏。
--   说明：各职业 *Macros.lua 里也有同名 /focus party/raid 宏（键位一致），
--   本文件保证「即便某个职业文件未定义对应宏，全职业仍可用」。
--   加载顺序上本文件（TOC 第23行）先于各职业宏文件，WR_CreateMacro 同键幂等覆盖，无副作用。
--
--   ★ 关键：本段键位严格对齐各职业 *Macros.lua 里 /focus 的权威键位
--     （如 raid12=ALT-CTRL-SHIFT-]、raid19=ALT-CTRL-SHIFT-\\），
--     否则 AHK 发的键与宏绑定的键对不上，设焦会错目标。

-- ============ 201-204：手动通用四件套（跟随/上马/设焦） ============
-- 0) 目标跟随（颜色 201）-> 键位 CTRL-SHIFT-T
--   开始跟随当前目标。随时按 CTRL-SHIFT-T。
--   说明：各职业 *Macros.lua 里也有 /follow target 宏（键位 CTRL--，注释 --115），与本宏「同动作、不同键」，
--     互不冲突；此处用独立键位，专门避免未来把 115 挪作新技能时与 201 撞键（原 201 误沿用过 115 的 ^- 键位）。
--   ★ 2026-11-08：加 nocombat 守卫 —— 实证 AHK 会在战斗中连发 /follow 类键（6 次/秒），
--     虽被客户端拒绝但会持续刷无效动作；战斗中直接不执行。
WR_CreateMacro("CTRL-SHIFT-T", "/follow [@target,exists,nodead,help,nocombat]")

-- 1) 焦点上马（颜色 202）-> 键位 CTRL-SHIFT-M
--   触发：WR_AutoFollow 判断「焦点已上马且自己未上马」时出颜色 202，由 AHK 识别后按 CTRL-SHIFT-M 调用。
--   手动：随时按 CTRL-SHIFT-M 也可召唤坐骑。
--   说明：C_MountJournal 是军团/正式服坐骑日志 API（SummonByID(0)=随机召唤收藏夹坐骑），原版 WotLK 3.3.5 无此 API，
--     故加 nil 守卫——有 API 时正常召唤，无则静默不报错。该 /run 宏由 WR_CreateMacro 自动改走「按键直执行 Lua」，
--     不再经过宏文本，因此不会触发暴雪「自定义脚本」确认弹窗。
WR_CreateMacro("CTRL-SHIFT-M", "/run if C_MountJournal and C_MountJournal.SummonByID then C_MountJournal.SummonByID(0) end")

-- 2) 设置焦点（颜色 203）-> 键位 CTRL-SHIFT-F
--   ★★ 2026-11-08 重要修复「战斗中莫名其妙把队友设成焦点」：
--     原宏是裸 `/focus`，而 `CTRL-SHIFT-F` 正好是各职业宏 `CTRL-SHIFT-F11`（神圣打击等）
--     的**按键前缀**。AHK 连发按键时若时序抖动（先按下 CTRL-SHIFT-F、再补 F11），
--     或脚本误发，就会直接执行 /focus 把当前目标设为焦点 —— 战斗中尤其明显。
--     现改为带守卫的条件宏 `/focus [@target,exists,nodead,help,nocombat]`：
--       · nocombat —— 战斗中一律不执行（战斗里的焦点完全交给玩家手动控制）；
--       · help     —— 只允许把「友方」设为焦点（绝不把怪物/敌人设成焦点）；
--       · exists,nodead —— 目标必须存在且未死亡。
--     条件不满足时 /focus 不执行任何动作（静默跳过），不会再误设焦点。
--     手动需要设焦点时，脱战后选中队友按 CTRL-SHIFT-F 即可。
WR_CreateMacro("CTRL-SHIFT-F", "/focus [@target,exists,nodead,help,nocombat]")

-- 3) 跟随（颜色 204）-> 键位 CTRL-SHIFT-G
--   ★ 2026-11-05：204 不再注册固定 /follow focus 宏，改由 MainLoop.lua 的「动态跟随安全按钮」
--     （WR_FollowSecureBtn，绑同一键 CTRL-SHIFT-G）接管：其 macrotext 每 tick 被设为
--     /follow <unitID>，unitID 来自 AUTO_FOLLOW_GUID 反查——彻底不占用游戏焦点槽
--     （奶职业用焦点做治疗焦点，跟随必须解耦）。此处不再注册宏，避免键位被旧 /follow focus 覆盖。

-- ============ 205-210：预留 / 协助攻击 ============
-- [205] 协同攻击（协助攻击）→ 键位 CTRL-SHIFT-N：AHK 识别色块 205 后按此键，触发 WR_AssistSecureBtn 执行
--        /dismount + /assist <跟随目标> + /startattack [harm,nodead] + /petattack [harm,nodead]。
--        宏由 MainLoop.lua 动态赋值（脱战写/战中排队），此处不挂静态宏。
-- [206] 预留
-- [207] 预留
-- [208] 预留
-- [209] 预留
-- [210] 预留

-- ============ 211-215：跟随系统「设置焦点」party1-5（颜色 211-215） ============
--   ★★ 2026-11-08 重要修复「战斗中莫名其妙把队友设成焦点」：
--     实证抓到 AHK 在同一秒内连发 6 次 `ALT-SHIFT-PAGEUP`（= /focus party2），
--     而插件当时并没有点亮任何焦点色块（色块序列为空）——说明是 AHK 侧在无提示的情况下
--     自行发键，把队伍第 2 名成员反复设成焦点。
--
--     这 5 个宏原本只服务于「跟随系统」（选中队员 → 弹 211-215 专属色块 → AHK 按键设焦点）。
--     而跟随系统现已默认关闭（AUTO_FOLLOW_ENABLED=false），这些宏成为纯冗余，
--     只会被 AHK 误触发。故改为「仅在跟随系统真正开启时才生效」的条件宏：
--       · 跟随关闭（默认）→ 按键完全无动作，不会误设焦点；
--       · 跟随开启 → 行为与原来一致（[@partyN,exists,nodead] 确保目标有效）。
--     ★ 使用宏条件而非直接删除：保留功能可用性，同时消除误触发。
--     ★★ 时序注意：本文件在 TOC 第 97 行加载，而 PigSet 是 SavedVariablesPerCharacter，
--        要到 ADDON_LOADED 才恢复。因此这里**不能在加载时直接判断**开关，
--        否则玩家开着跟随时会因存档未恢复而漏注册。改为延迟到 ADDON_LOADED 后执行。
local function WR_FollowFocusMacro(unit)
    -- 跟随系统关闭时返回 nil（不注册该键位），开启时返回条件宏文本
    if not (PigSet and PigSet.AUTO_FOLLOW_ENABLED) then
        return nil
    end
    return "/focus [@" .. unit .. ",exists,nodead]"
end

-- 注册/注销 partyN + raidN 焦点宏（按当前 PigSet 状态决定）
local WR_PARTY_FOCUS_KEYS = {
    { key = "ALT-CTRL-PAGEUP",  unit = "party1" },
    { key = "ALT-SHIFT-PAGEUP", unit = "party2" },
    { key = "CTRL-PAGEUP",      unit = "party3" },
    { key = "SHIFT-PAGEUP",     unit = "party4" },
    { key = "ALT-PAGEUP",       unit = "party5" },
}
local WR_RAID_FOCUS_KEYS = {
    { "ALT-SHIFT-=",       "raid1"  }, { "CTRL-=",            "raid2"  },
    { "SHIFT-=",           "raid3"  }, { "ALT-=",             "raid4"  },
    { "ALT-CTRL-SHIFT-[",  "raid5"  }, { "CTRL-SHIFT-[",      "raid6"  },
    { "ALT-CTRL-[",        "raid7"  }, { "ALT-SHIFT-[",       "raid8"  },
    { "CTRL-[",            "raid9"  }, { "SHIFT-[",           "raid10" },
    { "ALT-[",             "raid11" }, { "ALT-CTRL-SHIFT-]",  "raid12" },
    { "CTRL-SHIFT-]",      "raid13" }, { "ALT-CTRL-]",        "raid14" },
    { "ALT-SHIFT-]",       "raid15" }, { "CTRL-]",            "raid16" },
    { "SHIFT-]",           "raid17" }, { "ALT-]",             "raid18" },
    { "ALT-CTRL-SHIFT-\\", "raid19" }, { "CTRL-SHIFT-\\",     "raid20" },
    { "ALT-CTRL-\\",       "raid21" }, { "ALT-SHIFT-\\",      "raid22" },
    { "CTRL-\\",           "raid23" }, { "SHIFT-\\",          "raid24" },
    { "ALT-\\",            "raid25" },
}

function WR_ApplyFollowFocusMacros()
    -- ★ 2026-11-09：统一改为「跟随关闭 → 注册空宏吃掉按键」，不再 ClearOverrideBindings。
    --   原实现解绑后，AHK 误发的键会**回落到游戏默认绑定**（PgUp/PgDn/Insert 在
    --   客户端都有默认动作），比空宏更危险；空宏能确保按键被插件吃掉、零动作。
    --   真正的门控在 Core/UI_ColorFrame.lua 的 WR_CreateMacro 里（按跟随开关自动降级），
    --   这里只需按当前状态重新注册一遍即可。
    local enabled = (PigSet and PigSet.AUTO_FOLLOW_ENABLED) and true or false
    for _, rec in ipairs(WR_PARTY_FOCUS_KEYS) do
        local mt = WR_FollowFocusMacro(rec.unit)   -- 关闭时返回 nil
        WR_CreateMacro(rec.key, mt or "")
    end
    for _, rec in ipairs(WR_RAID_FOCUS_KEYS) do
        local mt = WR_FollowFocusMacro(rec[2])
        WR_CreateMacro(rec[1], mt or "")
    end
end

-- 延迟到存档恢复后再决定是否注册（避免读不到 AUTO_FOLLOW_ENABLED 而漏注册）
do
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "MKHelperForever" then
            self:UnregisterEvent("ADDON_LOADED")
            WR_ApplyFollowFocusMacros()
        end
    end)
end

-- ★ 2026-11-09：/focus 宏门控随跟随开关变化（见 Core/UI_ColorFrame.lua）。
--   各职业 *_Macros.lua 在 PLAYER_ENTERING_WORLD / PLAYER_REGEN_ENABLED 时会重跑
--   CreateClassesMacro()，那时已按当时开关正确门控；这里再补一次「脱战对齐」，
--   覆盖「战斗中切了跟随开关」的情形（战斗中 SetAttribute 受限，被跳过的那次）。
do
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:SetScript("OnEvent", function()
        if type(WR_ReapplyFocusMacros) == "function" then
            WR_ReapplyFocusMacros()
        end
    end)
end

-- ============ 216-240：跟随系统「设置焦点」raid1-25（颜色 216-240） ============
--   ★★ 2026-11-08：同 211-215，改为「仅在跟随系统开启时才注册」（见上方 WR_ApplyFollowFocusMacros）。
--     跟随默认关闭 → 这些键位不再执行 /focus，彻底杜绝 AHK 误发键导致的乱设焦点。
--     键位严格对齐各职业 *Macros.lua 的 /focus raidN 权威键位（务必一致，否则 AHK 设焦错目标）。
--     （键位表 WR_RAID_FOCUS_KEYS 已在上方统一定义，此处不再重复注册。）
