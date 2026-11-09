-- ============================================================
-- Hunter Forever · MM 专精循环
-- 共享 helper 见 Hunter_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_HunterForeverMM()
    local inRange = WR_HunterForever_Base()
    if not inRange then return false end
    if WR_HunterForever_AutoShot(inRange) then return true end
    if not WR_HunterForever_InCombatGate() then return false end
    if WR_HunterForever_Aspect() then return true end
    if WR_HunterForever_KillShot(inRange) then return true end
    -- 奇美拉射击（无限中作为射击天赋存在，WR_SoD_HasRune 已映射 IsPlayerSpell）
    if WR_SoD_HasRune and WR_SoD_HasRune("HUNTER", "ChimeraShot") and WR_SpellUsable("奇美拉射击", true) then
        if WR_ColorFrame_ShowSkill("奇美拉射击", 77) then return true end
    end
    if WR_SpellUsable("急速射击", true) and WR_GetUnitBuffTime("player", "急速射击") == 0 then
        if WR_ColorFrame_ShowSkill("急速射击", 18) then return true end
    end
    if WR_HunterForever_Serpent(inRange) then return true end
    if WR_HunterForever_MultiShot(inRange) then return true end
    if WR_SpellUsable("瞄准射击", true) then
        if WR_ColorFrame_ShowSkill("瞄准射击", 79) then return true end
    end
    if WR_SpellUsable("稳固射击", true) then
        if WR_ColorFrame_ShowSkill("稳固射击", 78) then return true end
    end
    return false
end
