-- ============================================================
-- Warrior_Arms.lua  (★ SoD 探索赛季改编版)
-- 武器战自动循环 —— 符文自适应（P1-P4）
-- 核心：致死打击(常驻) / 压制(触发) / 斩杀(<20%) / 旋风斩(AoE)
--       / 英勇打击(填充) / 顺劈斩(AoE) / 猛击 / 狂暴之怒(解恐+爆发)
--       SoD 符文：鞭笞(胸,爆发) / 战争使者(胸,冲锋) / 无尽狂怒(手,怒气) / 毁灭打击(手)
-- 槽位：51=致死打击 52=压制 53=斩杀 54=旋风斩 55=英勇打击
--       56=顺劈斩 57=猛击 58=狂暴之怒 59=鞭笞 60=毁灭打击
-- ============================================================

function WR_WarriorArms()
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("英勇打击")
    PlayerHP = WR_GetUnitHP("player")
    PlayerRage = WR_SafeNumber(UnitPower("player", 1), 0)  -- 怒气 powerType=1
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)

    -- 生存/解控最高优先级
    if WR_WarriorArms_KZ() then return true end        -- 狂暴之怒（解恐/解控）
    if WR_WarriorArms_GongJi() then return true end    -- 自动攻击

    -- 战斗门
    if not (UnitAffectingCombat("player") and TargetInCombat) then return false end

    -- 爆发（符文）
    if WR_WarriorArms_BZ() then return true end        -- 鞭笞（胸符文）

    -- 核心输出
    if WR_WarriorArms_ZS() then return true end        -- 斩杀（<20%）
    if WR_WarriorArms_YZ() then return true end        -- 压制（触发）
    if WR_WarriorArms_XLZ() then return true end       -- 旋风斩（AoE）
    if WR_WarriorArms_SPP() then return true end       -- 顺劈斩（AoE 怒气充裕）
    if WR_WarriorArms_MJ() then return true end        -- 猛击（触发）
    if WR_WarriorArms_HXJB() then return true end      -- 致死打击（常驻）
    if WR_WarriorArms_MP() then return true end        -- 英勇打击（怒气填充）

    return false
end

function WR_WarriorArms_KZ()
    -- 被恐惧/定身时开狂暴之怒解控
    if (WR_GetUnitDebuffTime("player", "恐惧") > 0 or WR_GetUnitDebuffTime("player", "昏迷") > 0)
       and WR_SpellUsable("狂暴之怒", true) then
        if WR_ColorFrame_ShowSkill("狂暴之怒(解控)", 58) then return true end
    end
    return false
end

function WR_WarriorArms_GongJi()
    if not PlayerMove and UnitCanAttack("player", "target") and not UnitIsDead("target")
       and not IsCurrentSpell("攻击") and WR_SpellUsable("攻击") then
        if WR_ColorFrame_ShowSkill("攻击", 4) then return true end
    end
    return false
end

-- ★ 鞭笞（胸符文）：爆发，配合斩杀/致死阶段
function WR_WarriorArms_BZ()
    if WR_SoD_HasRune("WARRIOR", "Flagellation") and WR_SpellUsable("鞭笞", true) then
        if WR_ColorFrame_ShowSkill("鞭笞", 59) then return true end
    end
    return false
end

function WR_WarriorArms_ZS()
    local hpPct = WR_SafeHPPct("target")
    if hpPct < 0.20 and WR_SpellUsable("斩杀", true) then
        if WR_ColorFrame_ShowSkill("斩杀", 13) then return true end
    end
    return false
end

function WR_WarriorArms_YZ()
    -- 压制：目标被躲闪后触发（SoD 武器战核心）；用 buff/状态近似判断
    if WR_SpellUsable("压制", true) and WR_GetUnitBuffTime("player", "压制") > 0 then
        if WR_ColorFrame_ShowSkill("压制", 41) then return true end
    end
    return false
end

function WR_WarriorArms_XLZ()
    if UnitCount8 >= 3 and WR_SpellUsable("旋风斩", true) then
        if WR_ColorFrame_ShowSkill("旋风斩", 3) then return true end
    end
    return false
end

function WR_WarriorArms_SPP()
    if UnitCount8 >= 2 and PlayerRage > 40 and WR_SpellUsable("顺劈斩", true) then
        if WR_ColorFrame_ShowSkill("顺劈斩", 7) then return true end
    end
    return false
end

function WR_WarriorArms_MJ()
    if WR_GetUnitBuffTime("player", "猛击") > 0 and WR_SpellUsable("猛击", true) then
        if WR_ColorFrame_ShowSkill("猛击", 35) then return true end
    end
    return false
end

function WR_WarriorArms_HXJB()
    if WR_SpellUsable("致死打击", true) then
        if WR_ColorFrame_ShowSkill("致死打击", 40) then return true end
    end
    return false
end

function WR_WarriorArms_MP()
    -- 英勇打击：怒气充裕时填充（避免溢出）
    if PlayerRage > 50 and WR_SpellUsable("英勇打击", true) then
        if WR_ColorFrame_ShowSkill("英勇打击", 5) then return true end
    end
    return false
end
