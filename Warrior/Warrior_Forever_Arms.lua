-- ============================================================
-- Warrior Forever · Arms 专精循环（60级 / 无限服）
-- ------------------------------------------------------------
-- 2026-11-15 按「彼岸花-无限服 · 武器页」重做：
--   核心：斩杀（目标血量低于拉条）> 致死打击 > 压制（触发）
--         > 撕裂（保持）> 破甲攻击（按额外条件）> 雷霆/挫志（按设置）
--         > 横扫攻击（多目标）> 猛击（15 秒冷却）> 顺劈斩/英勇打击（怒气拉条）
--   功能：撕裂 / 雷霆挫志 / 血性狂暴 / 破甲攻击 / 致死打击 /
--         横扫攻击 / 旋风斩（姿态舞）/ 战斗怒吼 / 切换目标 / 猛击
--   爆发：鲁莽 / 种族爆发（全开/全关/切换按钮）
--   插入：反击风暴 / 穿刺打击 / 横扫攻击 / 狂暴之怒（一次性，放完自关）
--   保命：喝红药 / 乘胜追击 / 狂暴之怒解控
--
-- 数据依据：
--   · 当前客户端 60 级法术书（DungeonsForeverSpell/Core/Data/Data_SpellBook.lua
--     2026-11-13）：英勇打击 25286 / 撕裂 11574 / 雷霆一击 11581 /
--     反击风暴 20230 / 乘胜追击 402927 / 战斗怒吼 25289 / 挫志怒吼 11556 /
--     顺劈斩 20569 / 猛击 11605 / 斩杀 20662 / 狂暴之怒 18499 /
--     狂暴姿态 2458 / 旋风斩 1680 / 拳击 6554 / 鲁莽 1719 /
--     血性狂暴 2687 / 破甲攻击 11597 / 致死打击 21553 /
--     横扫攻击 12292 / 穿刺打击 1310222。
--   · 武器天赋（DungeonsForeverClass/Data_TalentTrees.lua 2026-11-13）：
--     穿刺打击 1310222（新主动）、血之气息（撕裂目标近战有几率激活压制）、
--     强化猛击（猛击冷却 15 → 10 秒）、横扫攻击、致死打击。
--   · GearInsight《无限》武器战手法：斩杀 > 致死打击 > 压制 >
--     旋风斩（2+）> 撕裂 > 猛击 > 顺劈（2+、怒气≥40）> 英勇（怒气≥50）。
--
-- 本文件只在 WR_WarriorForeverRotation() 判定为「武器」时调用，
-- 不会污染狂怒战 / 防护战 / 其他职业。
-- ============================================================

function WR_WarriorForeverArms()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("致死打击")
    PlayerHP = WR_GetUnitHP("player") or 1
    PlayerMP = WR_GetUnitMP("player") or 1
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target") or 999
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8) or 0
    UnitCount10 = WR_GetRangeHarmUnitCount(10) or 0
    Rage = WR_SafeNumber(UnitPower("player", 1), 0) or 0

    local WA = WR_WarriorArmsUI
    if not WA then return false end
    WA.InitDefaults()

    -- ===== 2. 自动切目标（先于目标有效性判断）=====
    if WA.On("WQZ_TAB", true) then
        local needTarget = (not UnitExists("target")) or (UnitIsDead("target"))
        if needTarget and WA.Show("切换目标", 90) then return true end
    end

    -- ===== 3. 目标有效性 =====
    if not WA.TargetExistsAttackable() then
        WA.SetWhirlwindState(0)
        return false
    end

    -- ===== 4. 脱战：回战斗姿态（武器战常驻战斗姿态）=====
    if not UnitAffectingCombat("player") then
        WA.SetWhirlwindState(0)
        local oocStance = WA.Stance()
        if oocStance > 0 and oocStance ~= 1 then
            if WA.Show("战斗姿态", 9) then return true end
        end
        return false
    end

    -- ===== 5. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do
        if UnitExists("boss" .. i) then bossFrameActive = true; break end
    end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (tonumber(PigSet.FANG_ADD_WQZ) or 1) ~= 2
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    -- ===== 6. 旋风斩姿态舞：已切到狂暴，负责放旋风斩 / 放完切回战斗 =====
    local wwState = WA.GetWhirlwindState()
    if wwState > 0 then
        local st = WA.Stance()
        if st == 3 then
            if wwState == 1 then
                if type(WR_SpellUsable) == "function" and WR_SpellUsable("旋风斩", true) then
                    if WA.Show("旋风斩", 3) then
                        WA.SetWhirlwindState(2)
                        return true
                    end
                end
                -- 怒气还不够：在狂暴姿态先攒着，不执行其他耗怒技能
                return false
            elseif wwState == 2 then
                if WA.CooldownLeft("旋风斩") > 0.3
                   or (type(WR_SpellUsable) == "function" and not WR_SpellUsable("旋风斩", true)) then
                    if WA.Show("战斗姿态", 9) then
                        WA.SetWhirlwindState(0)
                        return true
                    end
                end
                return false
            end
        else
            -- 已经离开狂暴姿态（被打断/手动切），清掉状态
            WA.SetWhirlwindState(0)
        end
    end

    -- ===== 7. 保命 =====
    -- 喝红药：血量低于拉条且药水可用
    local hxyHP = WA.Val("WQZ_HXY", 30)
    if hxyHP > 0 and PlayerHP < hxyHP / 100 and type(WR_Use_ZLYS) == "function" then
        local okUse, canUse = pcall(WR_Use_ZLYS)
        if okUse and canUse == true then
            if WA.Show("治疗药水", 75) then return true end
        end
    end

    -- 狂暴之怒解恐惧 / 昏迷
    if WR_SpellUsable("狂暴之怒", true) then
        local fear = WR_GetUnitDebuffTime("player", "恐惧") > 0
        local stun = WR_GetUnitDebuffTime("player", "昏迷") > 0
        if fear or stun then
            if WA.Show("狂暴之怒", 11) then return true end
        end
    end

    -- ===== 8. 插入（一次性，放完自关）=====
    -- 反击（反击风暴）：需要战斗姿态
    if WA.On("WQZ_CRFJFB", false) then
        local fjStance = WA.Stance()
        if fjStance > 0 and fjStance ~= 1 and WA.SpellKnown("反击风暴")
           and WA.CooldownLeft("反击风暴") <= 2 then
            if WA.Show("战斗姿态", 9) then return true end
        elseif fjStance == 1 and WA.InsertOnce("WQZ_CRFJFB", "反击风暴", 14) then
            return true
        end
    end
    -- 穿刺（穿刺打击）
    if WA.On("WQZ_CCDJ_CR", false) and WA.InsertOnce("WQZ_CCDJ_CR", "穿刺打击", 61) then return true end
    -- 横扫（横扫攻击，单放一次）：需要战斗姿态
    if WA.On("WQZ_CRHS", false) then
        local hsStance = WA.Stance()
        if hsStance > 0 and hsStance ~= 1 and WA.SpellKnown("横扫攻击") then
            if WA.Show("战斗姿态", 9) then return true end
        elseif hsStance == 1 and WA.InsertOnce("WQZ_CRHS", "横扫攻击", 42) then
            return true
        end
    end
    -- 狂暴之怒
    if WA.On("WQZ_KBZN_CR", false) and WA.InsertOnce("WQZ_KBZN_CR", "狂暴之怒", 11) then return true end

    -- ===== 8.5 打断：按面板「打断」拉条（0=关闭）=====
    if WA.Val("WQZ_QJ", 60) > 0 and type(WR_ShouldInterrupt) == "function"
       and WR_ShouldInterrupt("target", "WQZ_QJ") then
        if WR_SpellUsable("拳击", true) then
            if WA.Show("拳击", 24) then return true end
        end
    end

    -- ===== 9. 自身 Buff / 怒气（先于攻击）=====
    if WA.On("WQZ_ZDZH", true) and WA.BuffRemain("战斗怒吼", false) <= 0
       and WR_SpellUsable("战斗怒吼", true) then
        if WA.Show("战斗怒吼", 10) then return true end
    end
    if WA.BloodrageWanted() and WR_SpellUsable("血性狂暴", true) then
        if WA.Show("血性狂暴", 12) then return true end
    end

    -- ===== 10. 自动攻击 =====
    if WA.AutoAttack() then return true end

    -- ===== 11. 爆发 =====
    if WA.On("WQZ_LM", true) and WA.BuffRemain("鲁莽") <= 0
       and WR_SpellUsable("鲁莽", true) then
        if WA.Show("鲁莽", 37) then return true end
    end
    if WA.RacialBurstWanted() then
        if WA.Show("种族爆发", 181) then return true end
    end

    -- ===== 12. 横扫攻击（多目标优先于旋风斩姿态舞）=====
    if WA.SweepWanted() then
        if WA.Show("横扫攻击", 42) then return true end
    end

    -- ===== 12.1 旋风斩姿态舞启动（战斗姿态 → 狂暴姿态）=====
    if WA.WhirlwindWanted() then
        if WA.Show("狂暴姿态", 33) then
            WA.SetWhirlwindState(1)
            return true
        end
    end

    -- ===== 12.5 横扫攻击「强制留怒」：冷却好了但怒气不够，先不平砍泄怒 =====
    if WA.SweepPooling() then
        if WA.SweepWanted() then
            if WA.Show("横扫攻击", 42) then return true end
        end
        return false
    end

    -- ===== 13. 近战核心 =====
    local inRange = (TargetRange == nil) or (TargetRange <= 5) or (TargetRange >= 900)

    if inRange then
        -- 13.1 乘胜追击：击杀后 20 秒内可用；自己血量低于拉条才用（回 10% 最大生命）
        if WA.VictoryRushWanted() and WR_SpellUsable("乘胜追击", true) then
            if WA.Show("乘胜追击", 36) then return true end
        end

        -- 13.2 斩杀：目标进入拉条血量且客户端可用（斩杀期一切给斩杀让路）
        if WA.ExecuteWanted() then
            if WA.Show("斩杀", 13) then return true end
        end

        -- 13.3 致死打击：武器战核心，转好就打（致死打击让怒不影响它本身）
        if WR_SpellUsable("致死打击", true) then
            if WA.Show("致死打击", 40) then return true end
        end

        -- 13.4 压制：目标躲闪 / 血之气息触发
        if WR_SpellUsable("压制", true) then
            if WA.Show("压制", 41) then return true end
        end

        -- 13.5 撕裂：没有自己撕裂就补；不打元素/机械/亡灵；预判
        if WA.RendWanted() and WR_SpellUsable("撕裂", true) then
            if WA.Show("撕裂", 39) then return true end
        end

        -- 13.6 破甲：只打1破 / 高优先级 / 续破（高优先级排在填充前）
        local sunderMode = WA.SunderMode()
        if (sunderMode == 1 or sunderMode == 2 or sunderMode == 4)
           and WR_SpellUsable("破甲攻击", true) then
            if WA.Show("破甲攻击", 1) then return true end
        end

        -- 13.7 雷霆一击：按多目标/单体 保持/卡CD/不放
        if WA.ThunderWanted() and WR_SpellUsable("雷霆一击", true) then
            if WA.Show("雷霆一击", 23) then return true end
        end

        -- 13.8 挫志怒吼：按多目标/单体 保持/卡CD/不放
        if WA.DemoShoutWanted() and WR_SpellUsable("挫志怒吼", true) then
            if WA.Show("挫志怒吼", 25) then return true end
        end

        -- 13.9 横扫攻击（随缘模式；强制留怒模式在上面已处理）
        if WA.SweepWanted() then
            if WA.Show("横扫攻击", 42) then return true end
        end

        -- 13.10 猛击：15 秒冷却，怒气≥40 且能站定才打
        if WA.On("WQZ_MJ", true) and not PlayerMove and Rage >= 40
           and WR_SpellUsable("猛击", true) then
            if WA.Show("猛击", 35) then return true end
        end

        -- 13.11 低优先级破甲：其他技能都不可用才补
        if sunderMode == 3 and WR_SpellUsable("破甲攻击", true) then
            if WA.Show("破甲攻击", 1) then return true end
        end

        -- 13.12 顺劈斩：多目标且怒气达到拉条（致死打击让怒时门槛提高到让怒怒气）
        local cleaveRage = WA.Val("WQZ_SPZ", 30)
        if UnitCount8 >= 2 and Rage >= cleaveRage and WA.RageDumpAllowed()
           and WR_SpellUsable("顺劈斩", true) then
            if WA.Show("顺劈斩", 7) then return true end
        end

        -- 13.13 英勇打击：怒气达到拉条（致死打击让怒时门槛提高到让怒怒气）
        local heroRage = WA.Val("WQZ_YYDJ", 20)
        if Rage >= heroRage and WA.RageDumpAllowed() and WR_SpellUsable("英勇打击", true) then
            if WA.Show("英勇打击", 5) then return true end
        end
    end

    return false
end
