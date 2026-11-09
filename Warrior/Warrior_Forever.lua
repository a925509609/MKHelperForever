-- ============================================================
-- Warrior_Forever.lua  《魔兽世界：无限》(Forever) WARRIOR 完整循环
-- ------------------------------------------------------------
-- 机械转译自原 SoD 旋转：移除全部 WR_SoD_HasRune 符文门（无限无符文系统），
-- 改走 WR_SpellUsable（已含 WR_Forever_SkillAbsent 缺失闸门）+ WR_Forever_IsSpellKnown。
-- 无限里真实存在的经典/TBC 技能按原名解析；缺失的 WotLK/SoD 专属技能由闸门跳过。
-- ============================================================

function WR_WarriorForeverRotation()
    local spec = WR_GetMyTalent()
    local isForever = WR_Forever_ClientInfo().isForever
    -- 非 Forever 客户端：回退原 SoD 实现
    if not isForever then
        if spec == "武器" then WR_WarriorArms() end
        if spec == "狂怒" then WR_WarriorFury() end
        if spec == "防护" then WR_WarriorProtection() end
        return
    end
    -- Forever 路径
    if spec == "武器" then WR_WarriorForeverArms() end
    if spec == "狂怒" then WR_WarriorForeverFury() end
    if spec == "防护" then WR_WarriorForeverProtection() end
end

-- ============================================================
-- ★ 共享 helper（原单文件内联，拆分后供各专精文件调用）
-- ============================================================

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

function WR_WarriorArms_BZ()
    if WR_SpellUsable("鞭笞", true) then
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

    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("贯刺打击") and WR_SpellUsable("贯刺打击", true) then
        if WR_ColorFrame_ShowSkill("贯刺打击", 301) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("横扫攻击") and WR_SpellUsable("横扫攻击", true) then
        if WR_ColorFrame_ShowSkill("横扫攻击", 302) then return true end
    end
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

function WR_WarriorFury_BZ()
    if WR_SpellUsable("狂暴打击", true) then
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

function WR_WarriorFury_XJ()
    if WR_SpellUsable("迅捷打击", true) then
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

    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("刺耳怒吼") and WR_SpellUsable("刺耳怒吼", true) then
        if WR_ColorFrame_ShowSkill("刺耳怒吼", 303) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("死亡之愿") and WR_SpellUsable("死亡之愿", true) then
        if WR_ColorFrame_ShowSkill("死亡之愿", 304) then return true end
    end
    return false
end
