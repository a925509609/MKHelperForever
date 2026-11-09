-- ============================================================
-- Paladin_Protection.lua  (★ SoD 探索赛季改编版)
-- 防护骑士自动循环 —— 符文自适应（P1-P4）
-- 核心：审判/驱邪(腿符文)续仇恨、奉献 AoE 仇恨、神圣之盾自保
-- 槽位：33=审判 35=驱邪
--       36=奉献 45=神圣之盾 1=愤怒之锤 32=复仇之怒
-- ============================================================

function WR_PaladinProtection()
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("圣光术")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)

    -- 生存优先级
    if WR_PaladinProtection_SZ() then return true end       -- 圣盾术
    if WR_PaladinProtection_QJ() then return true end       -- 清洁术
    if WR_PaladinProtection_SYTX() then return true end     -- 光环提醒（虔诚/荆棘等）

    -- 自动攻击
    if WR_PaladinProtection_GongJi() then return true end    -- 自动攻击

    -- 战斗门
    if not (UnitAffectingCombat("player") and TargetInCombat) then return false end

    -- 续仇恨核心
    if WR_PaladinProtection_PD() then return true end         -- 审判
    if WR_PaladinProtection_QX() then return true end         -- 驱邪（腿符文）
    if WR_PaladinProtection_FX2() then return true end        -- 奉献（AoE 仇恨）
    if WR_PaladinProtection_SZS() then return true end        -- 神圣之盾（自保）
    if WR_PaladinProtection_FZH() then return true end        -- 愤怒之锤（<20%）
    if WR_PaladinProtection_FX() then return true end         -- 复仇之怒（仇恨）

    return false
end

function WR_PaladinProtection_SZ()
    if PlayerHP < 25 and WR_SpellUsable("圣盾术", true) then
        if WR_ColorFrame_ShowSkill("圣盾术", 18) then return true end
    end
    return false
end

function WR_PaladinProtection_QJ()
    if WR_SpellUsable("清洁术", true)
       and (WR_GetUnitDebuffTime("player", "中毒") > 0 or WR_GetUnitDebuffTime("player", "疾病") > 0
            or WR_GetUnitDebuffTime("player", "魔法") > 0 or WR_GetUnitDebuffTime("player", "诅咒") > 0) then
        if WR_ColorFrame_ShowSkill("清洁术", 27) then return true end
    end
    return false
end

function WR_PaladinProtection_SYTX()
    if WR_GetUnitBuffTime("player", "虔诚光环") == 0 and WR_GetUnitBuffTime("player", "荆棘光环") == 0
       and WR_SpellUsable("虔诚光环") then
        PigAlert("开启防御光环", 1, 0.8, 0, 1.2)
    end
    return false
end

function WR_PaladinProtection_GongJi()
    if not PlayerMove and UnitCanAttack("player", "target") and not UnitIsDead("target")
       and not IsCurrentSpell("攻击") and WR_SpellUsable("攻击") then
        if WR_ColorFrame_ShowSkill("攻击", 15) then return true end
    end
    return false
end

function WR_PaladinProtection_PD()
    -- ★ 有圣印才亮色块打审判
    if type(WR_PaladinForever_SealActive) == "function" and not WR_PaladinForever_SealActive() then
        return false
    end
    if WR_SpellUsable("审判", true) then
        if WR_ColorFrame_ShowSkill("审判", 33) then return true end
    end
    return false
end

function WR_PaladinProtection_QX()
    if WR_SoD_HasRune("PALADIN", "Exorcist") and WR_SpellUsable("驱邪", true) then
        if WR_ColorFrame_ShowSkill("驱邪", 20) then return true end
    end
    return false
end

function WR_PaladinProtection_FX2()
    -- ★ 受面板「自动 奉献」开关控制
    if PigSet and PigSet.FH_FX == false then return false end
    -- ★ 只在近战攻击距离内释放（奉献以自身为中心，目标打不到时无意义）
    if TargetRange == nil or TargetRange > 5 then return false end
    if UnitCount8 >= 2 and PlayerMP > 0.30 and WR_SpellUsable("奉献", true) then
        if WR_ColorFrame_ShowSkill("奉献", 5) then return true end
    elseif UnitCount8 < 2 and PlayerMP > 0.60 and WR_SpellUsable("奉献", true) then
        if WR_ColorFrame_ShowSkill("奉献", 5) then return true end
    end
    return false
end

function WR_PaladinProtection_SZS()
    if WR_GetUnitBuffTime("player", "神圣之盾") == 0 and WR_SpellUsable("神圣之盾") then
        if WR_ColorFrame_ShowSkill("神圣之盾", 24) then return true end
    end
    return false
end

function WR_PaladinProtection_FZH()
    local hpPct = WR_SafeHPPct("target")
    if hpPct < 0.20 and WR_SpellUsable("愤怒之锤", true) then
        if WR_ColorFrame_ShowSkill("愤怒之锤", 1) then return true end
    end
    return false
end

function WR_PaladinProtection_FX()
    if WR_SpellUsable("复仇之怒", true) then
        if WR_ColorFrame_ShowSkill("复仇之怒", 28) then return true end
    end
    return false
end
