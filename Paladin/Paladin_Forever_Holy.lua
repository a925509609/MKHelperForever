-- ============================================================
-- Paladin Forever · Holy 专精循环（奶骑治疗 · 无限 1.60.x）
-- 共享 helper 见 Paladin_Forever.lua（公共件）
-- ------------------------------------------------------------
-- 【治疗模型】与牧师 / 萨满 / 德鲁伊同一套：色块 = 现在该按这个键。
--   治疗目标固定是「焦点」——本职业所有治疗宏都是 [@focus] 形态
--   （Paladin_Macros.lua：109 圣光闪现 / 110 圣光术 / 113 神圣震击 /
--     150 圣疗术 / 63 清洁术 / 43 自施清洁术 / 48 自施圣疗术）。
--   循环判定的对象必须与宏实际施放的对象一致，否则会出现「判 A 治 B」的错位。
--   所以本文件只以 focus 为治疗对象；焦点不可用时只走自施槽位
--   （18 圣盾术 / 48 圣疗术 / 43 清洁术），绝不点亮 [@focus] 技能。
--
-- 【技能依据】无限 1.60.1 法术库实测（/mkfspells + /mkfspellscan）
--   与 Data/Forever_Abilities.lua（官方天赋计算器口径）交叉核对：
--     可用：圣光术 635 / 圣光闪现 19750 / 神圣震击 20473 / 神恩术 20216 /
--           圣疗术 633 / 清洁术 4987 / 圣盾术 642 /
--           光之守夜（Holy 天赋）/ 真理之声（Holy 天赋）
--     不可用（已登记 WR_Forever_SkillAbsent，WR_SpellUsable 会拦下）：
--           圣光道标 / 圣洁护盾 / 神圣牺牲 / 光环掌握 / 复仇之怒 /
--           自由之手 / 洁净术 / 祈求圣光 / 神圣风暴
--   → 旧版本文件里的「圣光道标」「洁净术」两条分支在无限服恒不成立
--     （技能名根本不在法术库），本版删除；驱散改用本服真实存在的「清洁术」。
--
-- 【优先级】高 → 低：
--    0 脱战祝福（复用 Paladin_Blessing.lua 的自动补祝福）
--    1 读条保护：玩家正在施法时整轮让路，不点亮任何新色块
--      （否则 AHK 换键 = 自己打断自己的治疗读条，白烧蓝）
--    2 自身圣盾术（< SS_SDS，默认 30%）
--    3 自身圣疗术（< SS_SLS，默认 30%，自施槽 48）
--    4 焦点圣疗术（< SS_SLS，[@focus] 槽 150）
--    5 神恩术（低血且下一个治疗可用时，给 100% 暴击）
--    6 光之守夜（≥2 人低血时的群疗准备：标记后神圣震击触发小队治疗且不进 CD）
--    7 神圣震击（按 SS_SSZJ 模式：1 常规 / 2 积极 / 3 急救 / 4 禁用）
--    8 圣光术（< SS_SGS，默认 70%；读条 2.5 秒，蓝 <15% 不读）
--    9 圣光闪现（< SS_SGSX，默认 90%；读条 1.5 秒，蓝 <8% 不读）
--   10 清洁术（自己 → 焦点 → 指向；按 SS_QJS / SS_QJS_AUTO 控制）
--
-- 【与其他专精的隔离】本文件只调用公共件的通用 helper，不修改任何公共状态；
--   新增色块槽位（4 / 43 / 59 / 63 / 150）与「(焦点)(队友)(自己)(指向)」别名
--   仅被本文件使用，防护 / 惩戒的槽位（18 / 27 / 48 / 113 …）保持原值不变。
-- ============================================================

-- ★ 本地 CD / 状态记账（全局，供诊断命令读取）
WR_PaladinForeverHoly_FavorAt = WR_PaladinForeverHoly_FavorAt or nil  -- 最近一次提示神恩术的时刻
WR_PaladinForeverHoly_VigilAt = WR_PaladinForeverHoly_VigilAt or nil  -- 最近一次提示光之守夜的时刻

-- ============================================================
-- 配置读取
-- ------------------------------------------------------------
-- 面板下拉组写 PigSet[var] = menuID（1 起），滑块写 0~100 的整数。
-- 未初始化（nil）一律取默认值：菜单默认值与 Paladin_Menu.lua 的 defaultID /
-- defaultVal 完全对齐，保证「没打开过面板」与「保持默认」行为一致。
-- ============================================================
function WR_PaladinForeverHoly_Cfg(key, def)
    local v = PigSet and PigSet[key]
    if type(v) ~= "number" then return def end
    return v
end

-- ============================================================
-- 治疗目标：焦点是否可用（存在 / 存活 / 友善）
-- ★ 必须做友善判定：焦点常被玩家用来盯 BOSS，此时 [@focus] 治疗宏会失败，
--   若循环仍按「最低血队友」判定就会点亮一个永远打不出去的色块。
-- ============================================================
function WR_PaladinForeverHoly_FocusUsable()
    if type(UnitExists) ~= "function" or not UnitExists("focus") then return false end
    local okDead, dead = pcall(UnitIsDeadOrGhost, "focus")
    if okDead and dead then return false end
    if type(UnitIsFriend) == "function" then
        local okF, friend = pcall(UnitIsFriend, "player", "focus")
        if okF and friend == false then return false end
    end
    return true
end

-- ============================================================
-- 队伍单位列表（团队优先，其次小队，含 player）
-- ============================================================
function WR_PaladinForeverHoly_GroupUnits()
    local units = { "player" }
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    if raid > 0 then
        for i = 1, raid do units[#units + 1] = "raid" .. i end
    elseif party > 0 then
        for i = 1, party do units[#units + 1] = "party" .. i end
    end
    return units
end

-- ============================================================
-- 低于阈值的存活友方数量（用于群疗需求判定）
-- ★ UnitIsDeadOrGhost 在无限下可能抛错（secret 相关），统一 pcall 包裹，
--   读不到就跳过该单位，绝不因单个单位异常拖垮整条循环。
-- ============================================================
function WR_PaladinForeverHoly_LowCount(threshold)
    threshold = threshold or 0.70
    local n = 0
    local units = WR_PaladinForeverHoly_GroupUnits()
    for i = 1, #units do
        local u = units[i]
        if UnitExists(u) then
            local okD, dead = pcall(UnitIsDeadOrGhost, u)
            if okD and not dead and WR_GetUnitHP(u) < threshold then
                n = n + 1
            end
        end
    end
    return n
end

-- ============================================================
-- 可驱散判定
-- ★ 圣骑士清洁术可解：中毒 / 疾病 / 魔法。**不能解诅咒**。
--   2026-11-14 起公共件 WR_PaladinForever_HasDispel 也统一只认这三种；
--   本文件保留自己的函数，供奶骑按单位做安全判定与独立冷却检查。
-- ============================================================
function WR_PaladinForeverHoly_HasDispel(unit)
    if type(unit) ~= "string" or not UnitExists(unit) then return false end
    local kinds = { "中毒", "疾病", "魔法" }
    for i = 1, #kinds do
        local v = WR_GetUnitDebuffTime(unit, kinds[i])
        if type(v) == "number" and v > 0 then return true end
    end
    return false
end

-- ============================================================
-- 真名施放记账 → 硬冷却门
-- ------------------------------------------------------------
-- 循环里有几个技能用「别名」点亮不同槽位（圣光闪现(焦点)、圣疗术(队友)、
-- 清洁术(焦点)…），别名在公共件的施放记账表里查不到 → ShowSkillCD 的
-- 「施放记录通道」失效，只能落到保守兜底（每 1.5 秒重亮）。
-- 这里按**真名**再判一次成功施放时刻，保证冷却期真的不亮。
-- ============================================================
function WR_PaladinForeverHoly_OnCooldown(realName, cd)
    if type(realName) ~= "string" or type(cd) ~= "number" or cd <= 0 then return false end
    if type(WR_PaladinForever_GetLastCastAt) ~= "function" then return false end
    local at = WR_PaladinForever_GetLastCastAt(realName)
    if type(at) ~= "number" then return false end
    return (GetTime() - at) < cd
end

-- ============================================================
-- 神恩术是否已激活
-- ★ 双通道：① 光环可读 → 直接看 buff；② 光环读不到（无限战斗中的常见情况）
--   → 用「最近一次提示时刻 + 10 秒」兜底。10 秒够打完一发圣光术（2.5 秒读条）
--   外加 GCD，不会把同一个神恩术重复提示到刷屏。
-- ============================================================
function WR_PaladinForeverHoly_FavorActive()
    local remain = WR_GetUnitBuffTime("player", "神恩术")
    if type(remain) == "number" and remain > 0 then return true end
    local at = WR_PaladinForeverHoly_FavorAt
    if type(at) == "number" and (GetTime() - at) < 10 then return true end
    return false
end

-- ============================================================
-- 光之守夜标记是否已在目标身上
-- ★ 友方是 Buff、敌方是 Debuff，两条都查；都读不到时按 30 秒本地记账兜底
--   （天赋描述：标记持续 30 秒）。
-- ============================================================
function WR_PaladinForeverHoly_VigilOn(unit)
    if type(unit) ~= "string" or not UnitExists(unit) then return false end
    local b = WR_GetUnitBuffTime(unit, "光之守夜")
    if type(b) == "number" and b > 0 then return true end
    local d = WR_GetUnitDebuffTime(unit, "光之守夜")
    if type(d) == "number" and d > 0 then return true end
    local at = WR_PaladinForeverHoly_VigilAt
    if type(at) == "number" and (GetTime() - at) < 30 then return true end
    return false
end

-- ============================================================
-- 神恩术收益判定：下一个治疗法术确实用得上才提示
-- ★ 神恩只作用于「下一次圣光闪现 / 圣光术 / 神圣震击」。
--   但 2 分钟 CD 只值得押在单发治疗量最大的圣光术上：
--     · 圣光术基础 678~757，暴击翻倍收益最大；
--     · 圣光闪现 343~383、神圣震击 110~118，暴击收益小，
--       为它们插入一次神恩（多一个 GCD）反而拖慢治疗节奏。
--   所以只有「已进入圣光术阈值且圣光术可用」时才提示神恩。
-- ============================================================
function WR_PaladinForeverHoly_FavorUseful(hp, hlPct, flPct)
    if hlPct > 0 and hp < hlPct / 100 and WR_SpellUsable("圣光术", true) then return true end
    return false
end

-- ============================================================
-- ★ 判据失效即收色块（方案 A：血量回升立即停手）
-- ------------------------------------------------------------
-- 色块模型是「同色常亮就一直按」：AHK 约 60ms 按一次。治疗色块点亮后由
-- HideSkillLater 保留 1.5 秒；若这 1.5 秒内目标被别人抬回阈值以上，
-- AHK 还会继续按 20 次左右 —— 全是过量治疗，白烧蓝。
-- 这里在「血量从阈值下方跨回上方」的那一 tick 主动收掉对应槽位，
-- 把停止延迟从 1.5 秒压到 ≤1 个 tick（主循环 10Hz）。
--
-- 为什么只在「跨阈值上升」这一刻动手，而不是每 tick 无条件清扫：
--   ① 清洁术 43/63/59、圣疗 48、圣盾 18 等槽位在别的模块里也可能被点亮，
--      无差别 Hide 会误灭不属于自己的提示；
--   ② 同 tick「先收后亮」的顺序问题会让刚点亮的色块被自己收掉。
-- 抖动抑制：HideNow 清 PromptShown 但**不清 PromptCD**，所以收回后
--   0.45 秒（PROMPT_DEBOUNCE）内不会重亮 —— 血量在阈值边缘 100ms 级横跳时
--   不会退化成高频闪色块。
-- ============================================================
WR_PaladinForeverHoly_LastSample = WR_PaladinForeverHoly_LastSample or nil

function WR_PaladinForeverHoly_ReapOnRise(hp, playerHP, hlPct, flPct, slsPct, sdsPct, focusOK)
    local prev = WR_PaladinForeverHoly_LastSample
    WR_PaladinForeverHoly_LastSample = { hp = hp, php = playerHP }
    if type(prev) ~= "table" then return end          -- 首次采样只记录，不动作

    -- 焦点侧（治疗目标）
    if focusOK then
        if hlPct > 0 and prev.hp < hlPct / 100 and hp >= hlPct / 100 then
            -- 血量回到圣光术阈值以上 → 大治疗与神恩都不再需要
            WR_PaladinForever_HideNow("圣光术", 110)
            WR_PaladinForever_HideNow("神恩术", 114)
        end
        if flPct > 0 and prev.hp < flPct / 100 and hp >= flPct / 100 then
            WR_PaladinForever_HideNow("圣光闪现(焦点)", 109)
        end
        if slsPct > 0 and prev.hp < slsPct / 100 and hp >= slsPct / 100 then
            WR_PaladinForever_HideNow("圣疗术(队友)", 150)
        end
    end

    -- 自身侧
    if slsPct > 0 and prev.php < slsPct / 100 and playerHP >= slsPct / 100 then
        WR_PaladinForever_HideNow("圣疗术", 48)
    end
    if sdsPct > 0 and prev.php < sdsPct / 100 and playerHP >= sdsPct / 100 then
        WR_PaladinForever_HideNow("圣盾术", 18)
    end
end

-- ============================================================
-- ★ 自动焦点：恢复「点亮色块 → AHK 按宏 → /focus」的原有链路
-- ------------------------------------------------------------
-- 背景：奶骑所有治疗宏都是 [@focus]（109/110/113/150/63），焦点不动就只能治一个人。
--   原有行为（WLK/SoD 版）就是：Core/Utils_HealerWeight.lua 按治疗模式算权重，
--   WR_FocusMaxWeightUnit()（:447）点亮 192 / 147 / 175+i / 120+i 的「设焦点」色块，
--   AHK 按下对应键执行 /focus，下一 tick 起治疗宏自动打到新目标。
--
-- 本仓库里这条链断了两处，本文件补第二处：
--   ① 宏层：120-145 / 175-179 / 147 / 192 被加了 nocombat，战斗中不执行
--      → 已在 Paladin_Macros.lua 去掉（只去这 31 条，跟随/通用焦点宏不动）；
--   ② 调用层：WR_FocusMaxWeightUnit 只被血肉成灰链调用，Forever 下该链被短路
--      → 本函数替代它，并补两道「别抢玩家焦点」的门。
--
-- 为什么不直接用 WR_FocusMaxWeightUnit：
--   它对「权重最高」不做阈值判断。权重函数只回答「谁损血最多」（Utils_HealerWeight:100），
--   队伍满血时也会返回一个人。直接切过去会把玩家正在盯的坦克焦点挤掉，且下一 tick
--   判定满血 → 不出技能 → 表现为「色块闪一下就没了」。所以必须先过血量门。
--
-- 双门控（都在切之前判）：
--   门 1：候选单位血量 < 圣光闪现阈值（默认 90%）—— 不值得治就不切
--   门 2：当前焦点仍有效且血量不高于候选 —— 焦点更急就保持（尊重玩家手动选择）
-- 节流 0.2 秒：权重计算要遍历全团并对每人查血量/光环/职责，10Hz 跑代价过高
--   （原 WR_FocusMaxWeightUnit 也是 0.15 秒一次）。
-- ============================================================
WR_PaladinForeverHoly_FocusCalcAt = WR_PaladinForeverHoly_FocusCalcAt or 0
WR_PaladinForeverHoly_FocusDecision = WR_PaladinForeverHoly_FocusDecision or nil

-- 单位 token → 设焦点色块槽位（与 Paladin_Macros.lua 一一对应）
-- ------------------------------------------------------------
-- 这张表依赖两处宏层修复（都在 Paladin_Macros.lua，本文件不改宏）：
--   ① 121-145 / 176-179 的宏文本改成 `[target=raidN,...]` 形式。
--      原因：Core/UI_ColorFrame.lua:63-66 的 WR_ShouldGateFocusMacro 会把
--      任何「/focus + [@party / [@raid」的宏在跟随关闭时降级成**空宏**，
--      于是这 29 条设焦点宏一直是空占位 —— 点亮色块后 AHK 按下也没有任何动作。
--      `[target=raidN]` 是等价的宏语法（同样能带 exists/nodead 守卫），
--      但字面量不含 `[@raid`，因此不被跟随门控拦下。
--   ② 139-145（raid19-25）的键位从 `\` 系列改成 F9 系列，与 AHK 脚本
--      （正式版10.25）的颜色映射对齐；`\` 系列在 AHK 里属于 234-240（跟随系统）。
--   逐槽核对结果：121-145 / 147 / 176-179 / 192 共 31 个槽位，
--      插件 ColorTable → AHK 颜色 → AHK 按键 → 宏键位 四段全部一致。
function WR_PaladinForeverHoly_FocusSlot(unit)
    if type(unit) ~= "string" then return nil end
    if unit == "player" then return 192 end     -- /focus [@player]
    if unit == "target" then return 147 end     -- /focus [@target,exists,nodead,help]
    local p = string.match(unit, "^party(%d)$")
    if p then
        local n = tonumber(p)
        if n and n >= 1 and n <= 4 then return 175 + n end   -- 176-179
    end
    local r = string.match(unit, "^raid(%d+)$")
    if r then
        local n = tonumber(r)
        if n and n >= 1 and n <= 25 then return 120 + n end  -- 121-145
    end
    return nil
end

-- 返回 true 表示「本 tick 已占用色块去设焦点」，主循环应立即返回。
function WR_PaladinForeverHoly_AutoFocus(flPct)
    -- 开关：默认开启。游戏内关闭：/run PigSet.SS_ZDJD=false
    -- （菜单暂无控件，避免为一颗开关动 Paladin_Menu.lua）
    if PigSet and PigSet.SS_ZDJD == false then return false end
    if type(WR_GetHealthMaxWeightUnit) ~= "function" then return false end

    local now = GetTime()
    if (now - (WR_PaladinForeverHoly_FocusCalcAt or 0)) < 0.2 then return false end
    WR_PaladinForeverHoly_FocusCalcAt = now

    -- pcall：权重函数依赖 RaidOrParty/GroupSum/CLEU 注册等一串外部状态，
    -- 任何一环缺失都不该让整条治疗循环停摆。
    local ok, unit = pcall(WR_GetHealthMaxWeightUnit)
    if not ok or type(unit) ~= "string" or unit == "Nothing" then return false end
    if not UnitExists(unit) then return false end

    local uh = WR_GetUnitHP(unit)
    local gate = (flPct or 90) / 100
    if uh >= gate then
        WR_PaladinForeverHoly_FocusDecision = string.format("跳过 %s（血量 %.0f%% 未低于阈值）", unit, uh * 100)
        return false
    end

    -- 门 0：候选是自己 → 走自施通道（18 圣盾 / 48 圣疗），不需要切焦点。
    --   自疗宏是 [target=player]，与焦点无关；切到自己只会白占一 tick 色块。
    if unit == "player" then
        WR_PaladinForeverHoly_FocusDecision = "跳过 player（自疗走自施槽位）"
        return false
    end

    if UnitIsUnit(unit, "focus") then
        WR_PaladinForeverHoly_FocusDecision = "保持 " .. unit .. "（已是焦点）"
        return false
    end

    if WR_PaladinForeverHoly_FocusUsable() then
        local fh = WR_GetUnitHP("focus")
        if fh <= uh then
            WR_PaladinForeverHoly_FocusDecision =
                string.format("保持焦点（%.0f%% 不高于 %s 的 %.0f%%）", fh * 100, unit, uh * 100)
            return false
        end
    end

    local slot = WR_PaladinForeverHoly_FocusSlot(unit)
    if not slot then return false end
    if WR_ColorFrame_Show(slot, "设焦点") then
        WR_PaladinForeverHoly_FocusDecision = string.format("切换 %s（槽 %d，血量 %.0f%%）", unit, slot, uh * 100)
        return true
    end
    return false
end

-- ============================================================
-- 主循环
-- ============================================================
function WR_PaladinForeverHoly()
    -- ★ 兜底清理：过期色块按保持窗口熄灭。
    --   色块模型是「上一 tick 亮着就一直亮」，任何一条 return 之前都必须让
    --   过期提示有机会被清掉，否则 AHK 会一直按上一个技能。
    WR_PaladinForever_ClearStalePrompts(1.0)

    -- 0. 祝福（脱战自动补；战斗内该函数自身返回 false）
    --   type 保护：离线夹具未加载 Paladin_Blessing.lua 时安全跳过
    if type(WR_PaladinBlessing_Auto) == "function" and WR_PaladinBlessing_Auto() then return true end

    -- 1. 读条保护（★ 奶骑专项）
    --   圣光术 2.5 秒 / 圣光闪现 1.5 秒都是读条技能。读条期间只要点亮任何新色块，
    --   WR_ColorFrame_Show 会先隐藏全部色块再显示新的 → AHK 读到新颜色就按新键
    --   → 自己的治疗读条被打断，蓝白烧、治疗量为 0。
    --   所以施法中整轮让路：不点亮、不清提示，已亮的色块按 1.5 秒保持窗口自然熄灭。
    local casting = nil
    if type(WR_SafeCastingName) == "function" then
        casting = WR_SafeCastingName("player")
    end
    if casting then return true end

    -- 2. 采集
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()

    local focusOK = WR_PaladinForeverHoly_FocusUsable()
    local unit = focusOK and "focus" or "player"
    local hp = WR_GetUnitHP(unit)

    -- 阈值（与 Paladin_Menu.lua 的神圣专精滑块默认值一致）
    local hlPct  = WR_PaladinForeverHoly_Cfg("SS_SGS", 70)    -- 圣光术
    local flPct  = WR_PaladinForeverHoly_Cfg("SS_SGSX", 90)   -- 圣光闪现
    local slsPct = WR_PaladinForeverHoly_Cfg("SS_SLS", 30)    -- 圣疗术
    local sdsPct = WR_PaladinForeverHoly_Cfg("SS_SDS", 30)    -- 圣盾术
    local ssMode = WR_PaladinForeverHoly_Cfg("SS_SSZJ", 1)    -- 神圣震击模式
    local qjsMode = WR_PaladinForeverHoly_Cfg("SS_QJS", 2)    -- 清洁术模式

    -- 2.5 血量回升 → 立刻收掉已经失效的治疗色块（详见函数头注释）
    --   必须放在阈值读取之后、任何点亮之前：先收旧判断，再判新动作。
    WR_PaladinForeverHoly_ReapOnRise(hp, PlayerHP, hlPct, flPct, slsPct, sdsPct, focusOK)

    -- 2.6 自动焦点（恢复原有「宏设焦点」链路）
    --   命中时本 tick 只做设焦点，不治疗：焦点已经变了，本 tick 采集的 hp 属于旧焦点，
    --   继续判治疗会「按旧焦点的血量决定、按新焦点施放」。下一 tick（100ms）重判。
    if WR_PaladinForeverHoly_AutoFocus(flPct) then return true end

    -- 3. 自身圣盾术（最高优先级的自保：无敌 12 秒，撑到治疗落地）
    if sdsPct > 0 and PlayerHP < sdsPct / 100
       and WR_SpellUsable("圣盾术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣盾术", 300)
       and WR_PaladinForever_ShowSkillCD("圣盾术", 18, 300) then
        return true
    end

    -- 4. 自身圣疗术（<SS_SLS；自施槽 48 = /cast [target=player] 圣疗术）
    --   ★ 圣疗 20 分钟 CD：用真名记账做 1200 秒硬门，提示层只传 300 秒
    --     —— 漏按一次不会被锁死半小时，真打出去了也绝不会重复亮。
    if slsPct > 0 and PlayerHP < slsPct / 100
       and WR_SpellUsable("圣疗术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣疗术", 1200)
       and WR_PaladinForever_ShowSkillCD("圣疗术", 48, 300) then
        return true
    end

    -- 5. 焦点圣疗术（[@focus] 槽 150）：坦克/队友濒死时的最强单发
    if focusOK and slsPct > 0 and hp < slsPct / 100
       and WR_SpellUsable("圣疗术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣疗术", 1200)
       and WR_PaladinForever_ShowSkillCD("圣疗术(队友)", 150, 300) then
        return true
    end

    -- 6. 神恩术（下一个治疗 100% 暴击）
    --   只在「确实有治疗要打」时提示，避免满血空放浪费 2 分钟 CD。
    if focusOK and not WR_PaladinForeverHoly_FavorActive()
       and WR_PaladinForeverHoly_FavorUseful(hp, hlPct, flPct)
       and WR_SpellUsable("神恩术", true)
       and not WR_PaladinForeverHoly_OnCooldown("神恩术", 120)
       and WR_PaladinForever_ShowSkillCD("神恩术", 114, 120) then
        WR_PaladinForeverHoly_FavorAt = GetTime()
        return true
    end

    -- 7. 光之守夜（无限奶骑唯一的群疗手段）
    --   天赋描述：给目标上 30 秒标记，下一次对该目标的神圣震击不触发冷却，
    --   并让友方目标治疗其小队 315~333。所以它是「群疗的准备动作」，
    --   只在 ≥2 人低血（真需要群疗）时上，不常驻占用色块。
    --   ★ 条件顺序：先判 focusOK / 血量 / 技能，最后才做全团遍历——
    --     LowCount 要扫最多 25 个 raid 单位（每人 2 次 UnitHealth + pcall），
    --     放在 and 链末尾可让绝大多数 tick 完全不进入这次遍历。
    local vigilUp = focusOK and WR_PaladinForeverHoly_VigilOn("focus")
    if focusOK and not vigilUp
       and hp < 0.85
       and WR_PaladinForever_SpellKnown("光之守夜")
       and WR_SpellUsable("光之守夜", true)
       and not WR_PaladinForeverHoly_OnCooldown("光之守夜", 30)
       and WR_PaladinForeverHoly_LowCount(0.70) >= 2
       and WR_PaladinForever_ShowSkillCD("光之守夜", 4, 30) then
        WR_PaladinForeverHoly_VigilAt = GetTime()
        return true
    end

    -- 8. 神圣震击（核心瞬发单疗，CD 20 秒）
    --   模式 1 常规：低血或移动中（移动中只有瞬发能打出去）
    --   模式 2 积极：阈值放宽到 95%
    --   模式 3 急救：只在 <55% 时用
    --   模式 4 禁用：不提示
    --   ★ 目标身上有光之守夜标记时无条件优先：这一发不进 CD 且附带小队治疗，
    --     是整个循环里单位时间治疗量最高的一发。
    if focusOK and ssMode ~= 4
       and WR_SpellUsable("神圣震击", true)
       and not WR_PaladinForeverHoly_OnCooldown("神圣震击", 20) then
        local need = false
        if vigilUp then
            need = true
        elseif ssMode == 1 then
            need = (hp < 0.92) or (PlayerMove == true and hp < 0.98)
        elseif ssMode == 2 then
            need = hp < 0.95
        elseif ssMode == 3 then
            need = hp < 0.55
        end
        if need and WR_PaladinForever_ShowSkillCD("神圣震击", 113, 20) then
            return true
        end
    end

    -- 9. 圣光术（大治疗，2.5 秒读条）
    --   蓝量门槛 15%：读条被打断/过量都会白烧蓝，低蓝时降级到圣光闪现。
    if focusOK and hlPct > 0 and hp < hlPct / 100 and PlayerMP > 0.15
       and WR_SpellUsable("圣光术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣光术", 2.5)
       and WR_PaladinForever_ShowSkillCD("圣光术", 110, 2.5) then
        return true
    end

    -- 10. 圣光闪现（快速治疗，1.5 秒读条；HPM 高于圣光术，低蓝主力）
    if focusOK and flPct > 0 and hp < flPct / 100 and PlayerMP > 0.08
       and WR_SpellUsable("圣光闪现", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣光闪现", 1.5)
       and WR_PaladinForever_ShowSkillCD("圣光闪现(焦点)", 109, 1.5) then
        return true
    end

    -- 11. 清洁术（驱散）
    --   SS_QJS_AUTO 勾选 = 关闭驱散（总闸，优先级高于下拉）
    --   SS_QJS 模式 5 = 禁用
    --   施放顺序：自己 → 焦点 → 指向（模式 4 才查指向）
    --   三种用途用三个槽位：43 自施 / 63 焦点 / 59 指向，互不串台。
    local dispelOff = (PigSet and PigSet.SS_QJS_AUTO == true) or (qjsMode == 5)
    if not dispelOff
       and WR_SpellUsable("清洁术", true)
       and not WR_PaladinForeverHoly_OnCooldown("清洁术", 8) then
        if WR_PaladinForeverHoly_HasDispel("player")
           and WR_PaladinForever_ShowSkillCD("清洁术(自己)", 43, 8) then
            return true
        end
        if focusOK and WR_PaladinForeverHoly_HasDispel("focus")
           and WR_PaladinForever_ShowSkillCD("清洁术(焦点)", 63, 8) then
            return true
        end
        if qjsMode == 4 and UnitExists("mouseover")
           and WR_PaladinForeverHoly_HasDispel("mouseover")
           and WR_PaladinForever_ShowSkillCD("清洁术(指向)", 59, 8) then
            return true
        end
    end

    return false
end

-- ============================================================
-- 诊断命令 /mkpalholy
-- ------------------------------------------------------------
-- 输出：焦点状态 / 血量 / 各阈值 / 关键技能可用性与本地 CD 剩余。
-- 用途：区分「没设焦点」「技能没学会」「CD 没转好」「阈值取到 0」四类问题，
--   避免再靠猜改代码。
-- ============================================================
SLASH_MKPALHOLY1 = "/mkpalholy"
SlashCmdList["MKPALHOLY"] = function()
    local function spellState(name)
        local known = WR_PaladinForever_SpellKnown(name)
        local usable = WR_SpellUsable(name, true)
        local at = WR_PaladinForever_GetLastCastAt and WR_PaladinForever_GetLastCastAt(name)
        local ago = at and string.format("%.0f秒前", GetTime() - at) or "无记录"
        return string.format("%s(已学=%s 可用=%s 上次=%s)", name, tostring(known), tostring(usable), ago)
    end

    local focusOK = WR_PaladinForeverHoly_FocusUsable()
    local unit = focusOK and "focus" or "player"
    print("|cff00ff00[MKPALHOLY]|r 焦点可用=" .. tostring(focusOK)
        .. " 判定单位=" .. unit
        .. " 血量=" .. string.format("%.0f%%", (WR_GetUnitHP(unit) or 1) * 100)
        .. " 自身=" .. string.format("%.0f%%", (WR_GetUnitHP("player") or 1) * 100)
        .. " 蓝=" .. string.format("%.0f%%", (WR_GetUnitMP("player") or 1) * 100))
    print("|cff00ff00[MKPALHOLY]|r 阈值：圣光术=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SGS", 70))
        .. "% 圣光闪现=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SGSX", 90))
        .. "% 圣疗=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SLS", 30))
        .. "% 圣盾=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SDS", 30))
        .. "% 震击模式=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SSZJ", 1))
        .. " 清洁模式=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_QJS", 2))
        .. " 清洁总闸=" .. tostring(PigSet and PigSet.SS_QJS_AUTO))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("圣光术"))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("圣光闪现"))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("神圣震击")
        .. " 神恩激活=" .. tostring(WR_PaladinForeverHoly_FavorActive()))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("圣疗术"))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("清洁术")
        .. " 自身可驱=" .. tostring(WR_PaladinForeverHoly_HasDispel("player"))
        .. " 焦点可驱=" .. tostring(focusOK and WR_PaladinForeverHoly_HasDispel("focus") or false))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("光之守夜")
        .. " 标记=" .. tostring(focusOK and WR_PaladinForeverHoly_VigilOn("focus") or false)
        .. " 低血人数(<70%)=" .. tostring(WR_PaladinForeverHoly_LowCount(0.70)))
    print("|cff00ff00[MKPALHOLY]|r 读条中=" .. tostring(WR_SafeCastingName and WR_SafeCastingName("player") or nil))
    -- ★ 方案 A 可见性：这两份快照是「跨阈值回升 → 立刻收色块」的唯一依据。
    --   游戏内反复执行 /mkpalholy 若两个数字都不动，说明血量读取被降级
    --   （secret → 恒 100%），此时方案 A 与整条治疗循环都不会生效。
    local ls = WR_PaladinForeverHoly_LastSample
    local function pct(v)
        if type(v) ~= "number" then return "未采样" end
        return string.format("%.0f%%", v * 100)
    end
    print("|cff00ff00[MKPALHOLY]|r 血量快照：焦点侧=" .. (ls and pct(ls.hp) or "未采样")
        .. " 自身侧=" .. (ls and pct(ls.php) or "未采样")
        .. "（方案A 跨阈值回升判定依据）")
    -- ★ 自动焦点诊断：开 / 最近一次决策 / 权重最高单位
    local focusUnit = "?"
    if type(WR_GetHealthMaxWeightUnit) == "function" then
        local okW, u = pcall(WR_GetHealthMaxWeightUnit)
        if okW and type(u) == "string" then
            focusUnit = u .. string.format("(%.0f%%)", (WR_GetUnitHP(u) or 1) * 100)
        end
    end
    print("|cff00ff00[MKPALHOLY]|r 自动焦点：开关=" .. tostring(not (PigSet and PigSet.SS_ZDJD == false))
        .. " 权重最高=" .. focusUnit
        .. " 最近决策=" .. tostring(WR_PaladinForeverHoly_FocusDecision or "无"))
end
