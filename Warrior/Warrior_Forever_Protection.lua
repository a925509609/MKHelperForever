-- ============================================================
-- Warrior Forever · Protection 专精循环（60级 / 无限服）
-- ------------------------------------------------------------
-- 2026-11-16 按「猪猪 / 彼岸花-无限服 · 防战页」同步：
--   核心：盾牌猛击 > 复仇 > 破甲攻击（只打1破/高优先/低优先/续破）> 撕裂
--         > 雷霆一击 > 挫志怒吼 > 乘胜追击（自己血量低于拉条）
--         > 鲁莽挥击 > 顺劈斩/英勇打击（怒气拉条）
--   保命：破釜沉舟 / 喝红药 / 盾牌格挡（多目标·卡CD·血量）
--   爆发：种族爆发（全开/全关/切换按钮）
--   功能：切姿态 / 战斗怒吼 / 切换目标 / 嘲讽 / 血性狂暴
--   插入：反击 / 震荡 / 挑战 / 盾墙 / 挫志怒吼 / 拦截 / 惩戒痛击 / 狂暴之怒
--         （一次性，放完自关；80 级遗留的英勇投掷 / 缴械 / 碎裂投掷 / 自动盾墙已下线）
--
-- 数据依据：
--   · 当前客户端 60 级法术书（DungeonsForeverSpell/Core/Data/Data_SpellBook.lua
--     2026-11-13）：撕裂 11574 / 破甲攻击 11597 / 盾牌格挡 2565 /
--     盾牌猛击 23925 / 复仇 25288 / 雷霆一击 11581 / 挫志怒吼 11556 /
--     战斗怒吼 25289 / 盾墙 871 / 嘲讽 355 / 拦截 20617 / 惩戒痛击 20560 /
--     乘胜追击 402927 / 震荡猛击 12809。
--   · 无限服 2026-11-05 战士改动：雷霆一击可在防御姿态使用、CD 6 秒；
--     乘胜追击击杀后 20 秒内可用、恢复最大生命 10%、30 秒 CD；
--     盾墙/反击风暴/鲁莽不再共享 CD；破甲攻击可正常叠加。
--   · GearInsight 防战手法：盾牌猛击 → 复仇 → 破甲（<5 层）→ 雷霆（3+）→
--     顺劈（2+、怒气≥40）→ 英勇（怒气≥40）→ 破甲刷新。
--   · 图片（彼岸花）额外条件：撕裂不打元素/机械/亡灵、预判 N 秒；
--     格挡多目标/卡CD/血量；破甲只打1破/高优先/低优先/续破秒数；
--     雷霆挫志分多目标/单体 保持/卡CD/不放；血性狂暴怒气/血量；切姿态脱战/进战。
--
-- 本文件只在 WR_WarriorForeverRotation() 判定为「防护」时调用，
-- 不会污染武器战 / 狂怒战 / 其他职业。
-- ============================================================

function WR_WarriorForeverProtection()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("盾牌猛击")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target") or 999
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8) or 0
    UnitCount10 = WR_GetRangeHarmUnitCount(10) or 0
    Rage = WR_SafeNumber(UnitPower("player", 1), 0) or 0

    local WP = WR_WarriorProt
    if not WP then return false end
    WP.InitDefaults()

    -- ===== 2. 自动切目标（先于目标有效性判断：没目标/目标死了才选）=====
    if WP.On("FZ_TAB", false) then
        local needTarget = (not UnitExists("target")) or (UnitIsDead("target"))
        if needTarget and WP.Show("切换目标", 90) then return true end
    end

    -- ===== 3. 目标有效性 =====
    if not WP.TargetExistsAttackable() then return false end

    -- ===== 4. 脱战：切战斗姿态（点了「先锋」就不切，防御姿态也能冲锋）=====
    if not UnitAffectingCombat("player") then
        local oocStance = WP.Stance()
        if WP.On("FZ_QTZ", true) and WP.On("FZ_QTZ_OOC", true)
           and oocStance > 0 and oocStance ~= 1 and not WP.SpellKnown("先锋") then
            if WP.Show("战斗姿态", 9) then return true end
        end
        return false
    end

    -- ===== 5. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do
        if UnitExists("boss" .. i) then bossFrameActive = true; break end
    end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_FZ ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    -- ===== 6. 进战切防御姿态 =====
    -- 插入的反击 / 拦截 / 惩戒痛击开着且技能快好了时不切，等它放出去。
    if WP.On("FZ_QTZ", true) and WP.On("FZ_QTZ_IC", true) then
        local combatStance = WP.Stance()
        if combatStance > 0 and combatStance ~= 2 and not WP.StanceInsertPending() then
            if WP.Show("防御姿态", 28) then return true end
        end
    end

    -- ===== 7. 保命（优先级最高）=====
    -- 破釜沉舟：血量低于面板拉条
    local pfcHP = WP.Val("FZ_KG_PFCZ", 20)
    if pfcHP > 0 and PlayerHP < pfcHP / 100 and WR_SpellUsable("破釜沉舟", true) then
        if WP.Show("破釜沉舟", 30) then return true end
    end

    -- 喝红药：血量低于拉条且药水可用
    local hxyHP = WP.Val("FZ_HXY", 30)
    if hxyHP > 0 and PlayerHP < hxyHP / 100 and type(WR_Use_ZLYS) == "function" then
        local okUse, canUse = pcall(WR_Use_ZLYS)
        if okUse and canUse == true then
            if WP.Show("治疗药水", 73) then return true end
        end
    end

    -- ===== 8. 插入（一次性，放完自关）=====
    if WP.On("FZ_TZNH_CR", false) and WP.InsertOnce("FZ_TZNH_CR", "挑战怒吼", 32) then return true end
    if WP.On("FZ_DQ_CR", false) and WP.InsertOnce("FZ_DQ_CR", "盾墙", 47) then return true end
    if WP.On("FZ_CJTJ_CR", false) and WP.InsertOnce("FZ_CJTJ_CR", "惩戒痛击", 56) then return true end
    if WP.On("FZ_ZCMJ_CR", false) and WP.InsertOnce("FZ_ZCMJ_CR", "震荡猛击", 89) then return true end
    if WP.On("FZ_FJFB_CR", false) and WP.InsertOnce("FZ_FJFB_CR", "反击风暴", 14) then return true end
    if WP.On("FZ_CZNH_CR", false) and WP.InsertOnce("FZ_CZNH_CR", "挫志怒吼", 25) then return true end
    if WP.On("FZ_KBZN_CR", false) and WP.InsertOnce("FZ_KBZN_CR", "狂暴之怒", 11) then return true end

    -- 插入拦截：8~25 码；先切战斗姿态再拦截，放完由「进战切防御」切回
    if WP.On("FZ_JL_CR", false) and TargetRange and TargetRange > 8 and TargetRange <= 25 then
        local jlStance = WP.Stance()
        if jlStance > 0 and jlStance ~= 1 then
            if WP.Show("战斗姿态", 9) then return true end
        elseif jlStance == 1 and WR_SpellUsable("拦截", true) then
            if WP.Show("拦截", 52) then
                PigSet.FZ_JL_CR = false
                WP.SyncCheckbox("FZ_JL_CR")
                return true
            end
        end
    end

    -- ===== 8.5 打断：按面板「打断」拉条（0=关闭）=====
    if WP.Val("FZ_KG_QJ", 60) > 0 and type(WR_ShouldInterrupt) == "function"
       and WR_ShouldInterrupt("target", "FZ_KG_QJ") then
        if WR_SpellUsable("盾击", true) then
            if WP.Show("盾击", 27) then return true end
        elseif WR_SpellUsable("拳击", true) then
            if WP.Show("拳击", 24) then return true end
        end
    end

    -- ===== 9. 嘲讽（默认关）=====
    if WP.On("FZ_CT", false) then
        local wantTaunt = false
        if type(UnitThreatSituation) == "function" then
            local okSit, sit = pcall(UnitThreatSituation, "player", "target")
            if okSit and type(sit) == "number" and sit < 2 then wantTaunt = true end
        end
        if wantTaunt and WR_SpellUsable("嘲讽", true) then
            if WP.Show("嘲讽", 76) then return true end
        end
    end

    -- ===== 10. 自身 Buff / 格挡（先于攻击，避免永远被核心技能挡住）=====
    if WP.On("FZ_ZDZH", true) and WP.BuffRemain("战斗怒吼", false) <= 0
       and WR_SpellUsable("战斗怒吼", true) then
        if WP.Show("战斗怒吼", 10) then return true end
    end
    if WP.BloodrageWanted() and WR_SpellUsable("血性狂暴", true) then
        if WP.Show("血性狂暴", 12) then return true end
    end
    if WP.RecklessSwingWanted() and WR_SpellUsable("鲁莽挥击", true) then
        if WP.Show("鲁莽挥击", 78) then return true end
    end
    if WP.ShieldBlockWanted() and WR_SpellUsable("盾牌格挡", true) then
        if WP.Show("盾牌格挡", 31) then return true end
    end

    -- 种族爆发：面板「种族爆发」勾选时，种族爆发技能可用就提示（宏 181）
    if WP.RacialBurstWanted() then
        if WP.Show("种族爆发", 181) then return true end
    end

    -- ===== 10.5 自动攻击 =====
    if WP.AutoAttack() then return true end

    -- ===== 11. 近战核心 =====
    local inRange = (TargetRange == nil) or (TargetRange <= 5) or (TargetRange >= 900)

    if inRange then
        -- 12.1 盾牌猛击：仇恨最高，转好就打
        if WR_SpellUsable("盾牌猛击", true) then
            if WP.Show("盾牌猛击", 16) then return true end
        end

        -- 12.2 复仇：格挡/躲闪/招架后亮，可用就打
        if WR_SpellUsable("复仇", true) then
            if WP.Show("复仇", 18) then return true end
        end

        -- 12.3 乘胜追击：击杀后 20 秒内可用；自己血量低于拉条才用（回 10% 最大生命）
        if WP.VictoryRushWanted() and WR_SpellUsable("乘胜追击", true) then
            if WP.Show("乘胜追击", 36) then return true end
        end

        -- 12.4 破甲攻击：只打1破 / 高优先级 / 续破
        local sunderMode = WP.SunderMode()
        if (sunderMode == 1 or sunderMode == 2 or sunderMode == 4)
           and WR_SpellUsable("破甲攻击", true) then
            if WP.Show("破甲攻击", 1) then return true end
        end

        -- 12.5 撕裂：没有自己撕裂就补；不打元素/机械/亡灵；预判
        if WP.RendWanted() and WR_SpellUsable("撕裂", true) then
            if WP.Show("撕裂", 39) then return true end
        end

        -- 12.6 雷霆一击：按多目标/单体 保持/卡CD/不放
        if WP.ThunderWanted() and WR_SpellUsable("雷霆一击", true) then
            if WP.Show("雷霆一击", 23) then return true end
        end

        -- 12.7 挫志怒吼：按多目标/单体 保持/卡CD/不放
        if WP.DemoShoutWanted() and WR_SpellUsable("挫志怒吼", true) then
            if WP.Show("挫志怒吼", 25) then return true end
        end

        -- 12.9 低优先级破甲：其他技能都不可用才补
        if sunderMode == 3 and WR_SpellUsable("破甲攻击", true) then
            if WP.Show("破甲攻击", 1) then return true end
        end

        -- 12.10 顺劈斩：多目标且怒气达到拉条
        local cleaveRage = WP.Val("FZ_SPZ", 30)
        if UnitCount8 >= 2 and Rage >= cleaveRage and WR_SpellUsable("顺劈斩", true) then
            if WP.Show("顺劈斩", 7) then return true end
        end

        -- 12.11 英勇打击：怒气达到拉条
        local heroRage = WP.Val("FZ_YYDJ", 20)
        if Rage >= heroRage and WR_SpellUsable("英勇打击", true) then
            if WP.Show("英勇打击", 5) then return true end
        end
    end

    return false
end
