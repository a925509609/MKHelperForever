-- ============================================================
-- Paladin Forever · Holy 专精循环
-- 共享 helper 见 Paladin_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_PaladinForeverHoly()
    -- 0. 祝福（战斗外按菜单「祝福」下拉补）
    if WR_PaladinForever_Blessing(PigSet and PigSet.SS_ZF) then return true end
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    local lowUnit = WR_SoD_GetLowestFriendly(0.90)
    local lowHP = lowUnit and WR_GetUnitHP(lowUnit) or 1

    -- 1. 紧急救场（自身）
    if PlayerHP < 0.30 and WR_SpellUsable("圣疗术", true) then
        if WR_ColorFrame_ShowSkill("圣疗术", 40) then return true end
    end

    -- 2. 圣光道标（无限天赋；坦克维持）
    if WR_PaladinForever_Talent("圣光道标", 112) then return true end

    -- 3. 神圣震击（核心单疗，招牌）
    if lowUnit and lowHP < 0.92 and WR_PaladinForever_SpellKnown("神圣震击")
       and WR_SpellUsable("神圣震击", true) then
        if WR_ColorFrame_ShowSkill("神圣震击", 113) then return true end
    end

    -- 4. 圣光术 / 圣光闪现（按危急程度）
    if lowUnit and lowHP < 0.55 and WR_SpellUsable("圣光术", true) then
        if WR_ColorFrame_ShowSkill("圣光术", 110) then return true end
    elseif lowUnit and lowHP < 0.85 and WR_SpellUsable("圣光闪现", true) then
        if WR_ColorFrame_ShowSkill("圣光闪现", 10) then return true end
    end

    -- 5. 洁净术（驱散友方 debuff）
    if WR_PaladinForever_HasDispel() and WR_SpellUsable("洁净术", true) then
        if WR_ColorFrame_ShowSkill("洁净术", 14) then return true end
    end

    -- 6. 神恩术（暴击预备）
    if WR_PaladinForever_Talent("神恩术", 114) then return true end

    -- 7. 光之守夜（无限天赋）
    if WR_PaladinForever_Talent("光之守夜", 116) then return true end

    return false
end
