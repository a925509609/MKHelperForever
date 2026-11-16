-- ============================================================
-- Warrior Forever · Fury 专精循环（60级 / 无限服）
-- ------------------------------------------------------------
-- 2026-11-16 按「猪猪 / 彼岸花-无限服 · 狂暴页」截图复核：
--   核心：斩杀（目标血量低于拉条）> 嗜血 > 旋风斩 > 压制（触发）
--         > 猛击 > 顺劈斩（2+ 目标、怒气拉条）> 英勇打击（怒气拉条）
--   功能：撕裂 / 雷霆挫志 / 血性狂暴 / 破甲攻击 /
--         切姿态 / 战斗怒吼 / 切换目标 / 鲁莽挥击
--   爆发：死亡之愿 / 鲁莽 / 种族爆发（全开/全关/切换按钮）
--   插入：反击风暴 / 鲁莽 / 狂暴之怒（一次性，放完自关）
--   保命：喝红药 / 乘胜追击 / 狂暴之怒解控
--
-- 数据依据：
--   · 当前客户端 60 级法术书（DungeonsForeverSpell/Core/Data/Data_SpellBook.lua
--     2026-11-13）：英勇打击 25286 / 撕裂 11574 / 雷霆一击 11581 /
--     反击风暴 20230 / 乘胜追击 402927 / 战斗怒吼 25289 / 挫志怒吼 11556 /
--     顺劈斩 20569 / 猛击 11605 / 斩杀 20662 / 狂暴之怒 18499 /
--     狂暴姿态 2458 / 旋风斩 1680 / 拳击 6554 / 嗜血 23894 / 鲁莽 1719 /
--     死亡之愿 12328 / 血性狂暴 2687 / 破甲攻击 11597。
--   · 狂怒天赋（DungeonsForeverClass/Data_TalentTrees.lua 2026-11-13）：
--     鲁莽挥击 1329555（4 次近战额外 5 怒气/次）、死亡之愿、嗜血。
--   · GearInsight《无限》狂怒手法：斩杀 > 嗜血 > 旋风斩 > 压制 >
--     猛击（15 秒冷却）> 顺劈（2+、怒气≥40）> 英勇（怒气≥50）。
--
-- 本文件只在 WR_WarriorForeverRotation() 判定为「狂怒」时调用，
-- 不会污染武器战 / 防护战 / 其他职业。
-- ============================================================

function WR_WarriorForeverFury()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("嗜血")
    PlayerHP = WR_GetUnitHP("player") or 1
    PlayerMP = WR_GetUnitMP("player") or 1
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target") or 999
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8) or 0
    UnitCount10 = WR_GetRangeHarmUnitCount(10) or 0
    Rage = WR_SafeNumber(UnitPower("player", 1), 0) or 0

    local WF = WR_WarriorFuryUI
    if not WF then return false end
    WF.InitDefaults()

    -- ===== 2. 自动切目标（先于目标有效性判断）=====
    if WF.On("KN_TAB", true) then
        local needTarget = (not UnitExists("target")) or (UnitIsDead("target"))
        if needTarget and WF.Show("切换目标", 90) then return true end
    end

    -- ===== 3. 目标有效性 =====
    if not WF.TargetExistsAttackable() then return false end

    -- ===== 4. 脱战：切战斗姿态（点了「先锋」就不切）=====
    if not UnitAffectingCombat("player") then
        local oocStance = WF.Stance()
        -- 截图口径：防御姿态下点了天赋「先锋」时不切（先锋让防御姿态也能冲锋开怪）
        if WF.On("KN_QTZ", true) and WF.On("KN_QTZ_OOC", true)
           and oocStance > 0 and oocStance ~= 1
           and not (oocStance == 2 and WF.SpellKnown("先锋")) then
            if WF.Show("战斗姿态", 9) then return true end
        end
        return false
    end

    -- ===== 5. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do
        if UnitExists("boss" .. i) then bossFrameActive = true; break end
    end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (tonumber(PigSet.FANG_ADD_KBZ) or 1) ~= 2
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    -- ===== 6. 进战切狂暴姿态 =====
    -- 插入的反击（反击风暴）开着且技能快好了时不切，等它在战斗姿态放出去。
    if WF.On("KN_QTZ", true) and WF.On("KN_QTZ_IC", true) then
        local combatStance = WF.Stance()
        if combatStance > 0 and combatStance ~= 3 and not WF.StanceInsertPending() then
            if WF.Show("狂暴姿态", 33) then return true end
        end
    end

    -- ===== 7. 保命 =====
    -- 喝红药：血量低于拉条且药水可用
    local hxyHP = WF.Val("KN_HXY", 30)
    if hxyHP > 0 and PlayerHP < hxyHP / 100 and type(WR_Use_ZLYS) == "function" then
        local okUse, canUse = pcall(WR_Use_ZLYS)
        if okUse and canUse == true then
            if WF.Show("治疗药水", 75) then return true end
        end
    end

    -- 狂暴之怒解恐惧 / 昏迷（默认开）
    if PigSet.KN_KBZN ~= false and WR_SpellUsable("狂暴之怒", true) then
        local fear = WR_GetUnitDebuffTime("player", "恐惧") > 0
        local stun = WR_GetUnitDebuffTime("player", "昏迷") > 0
        if fear or stun then
            if WF.Show("狂暴之怒", 11) then return true end
        end
    end

    -- ===== 8. 插入（一次性，放完自关）=====
    -- 反击风暴：需要战斗姿态；在狂暴/防御姿态先切战斗姿态
    if WF.On("KN_FJFB_CR", false) then
        local fjStance = WF.Stance()
        if fjStance > 0 and fjStance ~= 1 and WF.SpellKnown("反击风暴")
           and WF.CooldownLeft("反击风暴") <= 2 then
            if WF.Show("战斗姿态", 9) then return true end
        elseif fjStance == 1 and WF.InsertOnce("KN_FJFB_CR", "反击风暴", 14) then
            return true
        end
    end
    if WF.On("KN_LM_CR", false) and WF.InsertOnce("KN_LM_CR", "鲁莽", 37) then return true end
    if WF.On("KN_KBZN_CR", false) and WF.InsertOnce("KN_KBZN_CR", "狂暴之怒", 11) then return true end

    -- ===== 8.5 打断：按面板「打断」拉条（0=关闭）=====
    if WF.Val("KN_QJ", 60) > 0 and type(WR_ShouldInterrupt) == "function"
       and WR_ShouldInterrupt("target", "KN_QJ") then
        if WR_SpellUsable("拳击", true) then
            if WF.Show("拳击", 24) then return true end
        elseif WR_SpellUsable("盾击", true) then
            if WF.Show("盾击", 27) then return true end
        end
    end

    -- ===== 9. 自身 Buff / 怒气（先于攻击）=====
    if WF.On("KN_ZDZH", true) and WF.BuffRemain("战斗怒吼", false) <= 0
       and WR_SpellUsable("战斗怒吼", true) then
        if WF.Show("战斗怒吼", 10) then return true end
    end
    if WF.BloodrageWanted() and WR_SpellUsable("血性狂暴", true) then
        if WF.Show("血性狂暴", 12) then return true end
    end
    if WF.RecklessSwingWanted() and WR_SpellUsable("鲁莽挥击", true) then
        if WF.Show("鲁莽挥击", 78) then return true end
    end

    -- ===== 10. 自动攻击 =====
    if WF.AutoAttack() then return true end

    -- ===== 11. 爆发 =====
    if WF.On("KN_SWZY", true) and WF.BuffRemain("死亡之愿") <= 0
       and WR_SpellUsable("死亡之愿", true) then
        if WF.Show("死亡之愿", 60) then return true end
    end
    if WF.On("KN_LM", true) and WF.BuffRemain("鲁莽") <= 0
       and WR_SpellUsable("鲁莽", true) then
        if WF.Show("鲁莽", 37) then return true end
    end
    if WF.RacialBurstWanted() then
        if WF.Show("种族爆发", 181) then return true end
    end

    -- ===== 12. 近战核心 =====
    local inRange = (TargetRange == nil) or (TargetRange <= 5) or (TargetRange >= 900)

    if inRange then
        -- 12.1 乘胜追击：击杀后 20 秒内可用；自己血量低于拉条才用（回 10% 最大生命）
        if WF.VictoryRushWanted() and WR_SpellUsable("乘胜追击", true) then
            if WF.Show("乘胜追击", 36) then return true end
        end

        -- 12.2 破甲：只打1破 / 高优先级 / 续破（排在核心前）
        local sunderMode = WF.SunderMode()
        if (sunderMode == 1 or sunderMode == 2 or sunderMode == 4)
           and WR_SpellUsable("破甲攻击", true) then
            if WF.Show("破甲攻击", 1) then return true end
        end

        -- 12.3 撕裂：没有自己撕裂就补；不打元素/机械/亡灵；预判
        if WF.RendWanted() and WR_SpellUsable("撕裂", true) then
            if WF.Show("撕裂", 39) then return true end
        end

        -- 12.4 雷霆一击：按多目标/单体 保持/卡CD/不放
        if WF.ThunderWanted() and WR_SpellUsable("雷霆一击", true) then
            if WF.Show("雷霆一击", 23) then return true end
        end

        -- 12.5 挫志怒吼：按多目标/单体 保持/卡CD/不放
        if WF.DemoShoutWanted() and WR_SpellUsable("挫志怒吼", true) then
            if WF.Show("挫志怒吼", 25) then return true end
        end

        -- 12.6 斩杀：目标进入拉条血量且客户端可用
        if WF.ExecuteWanted() then
            if WF.Show("斩杀", 13) then return true end
        end

        -- 12.7 嗜血：狂怒核心，转好就打
        if WR_SpellUsable("嗜血", true) then
            if WF.Show("嗜血", 2) then return true end
        end

        -- 12.8 旋风斩：转好就打（多目标核心）
        if WR_SpellUsable("旋风斩", true) then
            if WF.Show("旋风斩", 3) then return true end
        end

        -- 12.9 压制：目标躲闪后触发
        if WR_SpellUsable("压制", true) then
            if WF.Show("压制", 41) then return true end
        end

        -- 12.10 猛击：15 秒冷却，转好就打
        if WR_SpellUsable("猛击", true) then
            if WF.Show("猛击", 35) then return true end
        end

        -- 12.11 低优先级破甲：其他技能都不可用才补
        if sunderMode == 3 and WR_SpellUsable("破甲攻击", true) then
            if WF.Show("破甲攻击", 1) then return true end
        end

        -- 12.12 顺劈斩：多目标且怒气达到拉条
        local cleaveRage = WF.Val("KN_SPZ", 30)
        if UnitCount8 >= 2 and Rage >= cleaveRage and WR_SpellUsable("顺劈斩", true) then
            if WF.Show("顺劈斩", 7) then return true end
        end

        -- 12.13 英勇打击：怒气达到拉条
        local heroRage = WF.Val("KN_YYDJ", 20)
        if Rage >= heroRage and WR_SpellUsable("英勇打击", true) then
            if WF.Show("英勇打击", 5) then return true end
        end
    end

    return false
end
