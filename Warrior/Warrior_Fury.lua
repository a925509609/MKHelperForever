-- ============================================================
-- Warrior_Fury.lua  (★ SoD 探索赛季改编版)
-- 狂暴战自动循环 —— 符文自适应（P1-P4）
-- 核心：嗜血(常驻) / 旋风斩(AoE) / 斩杀(<20%) / 英勇打击(填充)
--       / 顺劈斩(AoE) / 猛击 / 狂暴之怒(解恐+爆发) / 鲁莽(爆发)
--       SoD 符文：狂暴打击(胸,Raging Blow) / 无尽狂怒(手,怒气) / 单手狂怒(手,SMF) / 迅捷打击(手)
-- 槽位：61=嗜血 62=旋风斩 63=斩杀 64=英勇打击 65=顺劈斩
--       66=猛击 67=狂暴之怒 68=鲁莽 69=狂暴打击 70=迅捷打击
-- ============================================================

function WR_WarriorFury()
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("英勇打击")
    PlayerHP = WR_GetUnitHP("player")
    PlayerRage = WR_SafeNumber(UnitPower("player", 1), 0)
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)

    -- 生存/解控
    if WR_WarriorFury_KZ() then return true end        -- 狂暴之怒（解恐/解控）
    if WR_WarriorFury_GongJi() then return true end    -- 自动攻击

    -- 战斗门
    if not (UnitAffectingCombat("player") and TargetInCombat) then return false end

    -- 爆发
    if WR_WarriorFury_LM() then return true end        -- 鲁莽
    if WR_WarriorFury_KZ2() then return true end       -- 狂暴之怒（爆发）
    if WR_WarriorFury_BZ() then return true end        -- 狂暴打击（胸符文）

    -- 核心输出
    if WR_WarriorFury_ZS() then return true end        -- 斩杀（<20%）
    if WR_WarriorFury_XLZ() then return true end       -- 旋风斩（AoE）
    if WR_WarriorFury_SPP() then return true end       -- 顺劈斩（AoE）
    if WR_WarriorFury_XJ() then return true end        -- 迅捷打击（手符文副手）
    if WR_WarriorFury_MJ() then return true end        -- 猛击（触发）
    if WR_WarriorFury_XX() then return true end        -- 嗜血（常驻）
    if WR_WarriorFury_MP() then return true end        -- 英勇打击（怒气填充）

    return false
end

function WR_WarriorFury_KZ()
    if (WR_GetUnitDebuffTime("player", "恐惧") > 0 or WR_GetUnitDebuffTime("player", "昏迷") > 0)
       and WR_SpellUsable("狂暴之怒", true) then
        if WR_ColorFrame_ShowSkill("狂暴之怒(解控)", 58) then return true end
    end
    return false
end

function WR_WarriorFury_GongJi()
    if not PlayerMove and UnitCanAttack("player", "target") and not UnitIsDead("target")
       and not IsCurrentSpell("攻击") and WR_SpellUsable("攻击") then
        if WR_ColorFrame_ShowSkill("攻击", 4) then return true end
    end
    return false
end

function WR_WarriorFury_LM()
    if WR_SpellUsable("鲁莽", true) then
        if WR_ColorFrame_ShowSkill("鲁莽", 37) then return true end
    end
    return false
end

function WR_WarriorFury_KZ2()
    if WR_SpellUsable("狂暴之怒", true) then
        if WR_ColorFrame_ShowSkill("狂暴之怒", 11) then return true end
    end
    return false
end

-- ★ 狂暴打击（胸符文 Raging Blow）：核心高伤，有 CD 即放
function WR_WarriorFury_BZ()
    if WR_SoD_HasRune("WARRIOR", "RagingBlow") and WR_SpellUsable("狂暴打击", true) then
        if WR_ColorFrame_ShowSkill("狂暴打击", 69) then return true end
    end
    return false
end

function WR_WarriorFury_ZS()
    local hpPct = WR_SafeHPPct("target")
    if hpPct < 0.20 and WR_SpellUsable("斩杀", true) then
        if WR_ColorFrame_ShowSkill("斩杀", 13) then return true end
    end
    return false
end

function WR_WarriorFury_XLZ()
    if UnitCount8 >= 3 and WR_SpellUsable("旋风斩", true) then
        if WR_ColorFrame_ShowSkill("旋风斩", 3) then return true end
    end
    return false
end

function WR_WarriorFury_SPP()
    if UnitCount8 >= 2 and PlayerRage > 40 and WR_SpellUsable("顺劈斩", true) then
        if WR_ColorFrame_ShowSkill("顺劈斩", 7) then return true end
    end
    return false
end

-- ★ 迅捷打击（手符文）：副手攻击，触发可用即放
function WR_WarriorFury_XJ()
    if WR_SoD_HasRune("WARRIOR", "QuickStrike") and WR_SpellUsable("迅捷打击", true) then
        if WR_ColorFrame_ShowSkill("迅捷打击", 70) then return true end
    end
    return false
end

function WR_WarriorFury_MJ()
    if WR_GetUnitBuffTime("player", "猛击") > 0 and WR_SpellUsable("猛击", true) then
        if WR_ColorFrame_ShowSkill("猛击", 35) then return true end
    end
    return false
end

function WR_WarriorFury_XX()
    if WR_SpellUsable("嗜血", true) then
        if WR_ColorFrame_ShowSkill("嗜血", 2) then return true end
    end
    return false
end

function WR_WarriorFury_MP()
    if PlayerRage > 50 and WR_SpellUsable("英勇打击", true) then
        if WR_ColorFrame_ShowSkill("英勇打击", 5) then return true end
    end
    return false
end
