-- ============================================================
-- Paladin Forever · Ret 专精循环
-- 共享 helper 见 Paladin_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_PaladinForeverRet()
    WR_PaladinForever_ClearStalePrompts(1.0)
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("审判")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)

    -- 1. 生存
    if PlayerHP < 25 and WR_SpellUsable("圣盾术", true) then
        if WR_ColorFrame_ShowSkill("圣盾术", 18) then return true end
    end
    if PigSet.CJ_QJ ~= 0 and WR_SpellUsable("清洁术", true) and WR_PaladinForever_HasDispel() then
        if WR_ColorFrame_ShowSkill("清洁术", 27) then return true end
    end

    -- 2. 输出光环（复仇光环 / 圣洁光环，常驻 DPS）
    local auraUp = (WR_GetUnitBuffTime("player", "复仇光环") > 0) or (WR_GetUnitBuffTime("player", "圣洁光环") > 0)
    if not auraUp and (WR_SpellUsable("复仇光环") or WR_SpellUsable("圣洁光环")) then
        PigAlert("开启输出光环", 1, 0.8, 0, 1.2)
    end

    -- 3. 祝福（战斗外按菜单「祝福」下拉补）
    if WR_PaladinForever_Blessing(PigSet and PigSet.CJ_ZF) then return true end

    -- 4. 自动攻击（仅开怪前提示；战斗中视为已激活，不抢占技能）
    if not PlayerMove and UnitCanAttack("player", "target") and not UnitIsDead("target")
       and not WR_PaladinForever_AutoAttackActive() and WR_SpellUsable("攻击") then
        if WR_ColorFrame_ShowSkill("攻击", 15) then return true end
    end

    -- 5. 战斗主循环门（防 ADD）
    if not WR_PaladinForever_InCombatGate(PigSet.FANG_ADD_CJQ == 1 or PigSet.FANG_ADD_CJQ == 2) then
        return false
    end

    -- 6. 圣印保持
    if WR_PaladinForever_Seal(UnitCount8) then return true end

    -- 7. 主循环调度：「谁 CD 好了先打谁」
    --     审判与神圣打击都就绪时比 FreeAt，谁先轮到谁先打；
    --     审判 CD 随「强化审判」天赋变化（10 → 8 秒），运行时探测。
    local judgeCD = WR_PaladinForever_GetJudgeCooldown()
    local hsRangeOK = (TargetRange == nil or TargetRange >= 999 or TargetRange <= 8)
    local candidates = {}
    if WR_PaladinForever_SealActive() and WR_SpellUsable("审判", true) then
        candidates["审判"] = judgeCD
    end
    if hsRangeOK and (PigSet.FH_HS ~= false) and WR_SpellUsable("神圣打击") then
        candidates["神圣打击"] = WR_PaladinForever_SkillCD["神圣打击"]
    end
    local scheduled = WR_PaladinForever_PickMostReady(candidates)
    if scheduled then
        local slot = (scheduled == "审判") and 33 or 74
        if WR_PaladinForever_ShowSkillCD(scheduled, slot, candidates[scheduled]) then
            return true
        end
    end

    -- 8. 驱邪术（经典即可用，无限按名解析；本地 15 秒 CD）
    if WR_SpellUsable("驱邪术", true) then
        if WR_PaladinForever_ShowSkillCD("驱邪术", 20, 15) then return true end
    end

    -- 9. 神圣震击（天赋；已学会才提示）
    if WR_PaladinForever_CanPrompt("神圣震击", 8)
       and WR_PaladinForever_Talent("神圣震击", 113) then
        WR_PaladinForever_MarkPrompt("神圣震击")
        return true
    end

    -- 10. 奉献（受面板「自动 奉献」开关 CJ_FX 控制；仅目标数量 >2、近战 5 码内）
    local lowMana = PlayerMP < 0.30
    if (PigSet.CJ_FX ~= false)
       and UnitCount8 >= 3 and not lowMana
       and TargetRange ~= nil and TargetRange <= 5
       and WR_SpellUsable("奉献", true) then
        if WR_PaladinForever_ShowSkillCD("奉献", 5, 8) then return true end
    end

    -- 11. 制裁之锤（控制/打断，可用即提示；冷却 60 秒）
    if WR_SpellUsable("制裁之锤", true) then
        if WR_PaladinForever_ShowSkillCD("制裁之锤", 22, 60) then return true end
    end

    -- 12. 愤怒之锤（斩杀 <20%；本地 6 秒 CD）
    if WR_SafeHPPct("target") < 0.20 and WR_SpellUsable("愤怒之锤", true) then
        if WR_PaladinForever_ShowSkillCD("愤怒之锤", 1, 6) then return true end
    end

    -- 13. 无限天赋（已学会才提示）
    --   ★ 2026-11-08：真理之声(115)/光之守夜(116)/迅捷审判(117) 原用色块，
    --     但这三个槽位是旧版跟随系统专用（115=跟随目标 / 116=设焦点 / 117=跟随焦点），
    --     点亮即等于命令 AHK 执行 /follow、/focus —— 会造成「莫名其妙跟随/设焦点」。
    --     改为只弹文字提示，不占色块槽位。
    if WR_PaladinForever_Talent("神恩术", 114) then return true end
    if WR_PaladinForever_SpellKnown("真理之声")
       and WR_PaladinForever_CanPrompt("真理之声", 60) then
        PigAlert("可施放 真理之声", 1, 0.8, 0, 1.2)
        WR_PaladinForever_MarkPrompt("真理之声")
        return true
    end
    if WR_PaladinForever_SpellKnown("光之守夜")
       and WR_PaladinForever_CanPrompt("光之守夜", 60) then
        PigAlert("可施放 光之守夜", 1, 0.8, 0, 1.2)
        WR_PaladinForever_MarkPrompt("光之守夜")
        return true
    end
    if WR_PaladinForever_SpellKnown("迅捷审判")
       and WR_PaladinForever_CanPrompt("迅捷审判", 60) then
        PigAlert("可施放 迅捷审判", 1, 0.8, 0, 1.2)
        WR_PaladinForever_MarkPrompt("迅捷审判")
        return true
    end
    if WR_PaladinForever_Talent("圣殿壁垒", 118) then return true end

    return false
end
