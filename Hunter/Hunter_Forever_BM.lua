-- ============================================================
-- Hunter Forever · BM 专精循环
-- 共享 helper 见 Hunter_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_HunterForeverBM()
    local inRange = WR_HunterForever_Base()
    if not inRange then return false end
    if WR_HunterForever_AutoShot(inRange) then return true end
    if not WR_HunterForever_InCombatGate() then return false end
    if WR_HunterForever_Aspect() then return true end
    if WR_HunterForever_KillShot(inRange) then return true end
    if WR_SpellUsable("狂野怒火", true) and WR_GetUnitBuffTime("player", "狂野怒火") == 0 then
        if WR_ColorFrame_ShowSkill("狂野怒火", 17) then return true end
    end
    if WR_HunterForever_KillCommand(inRange) then return true end
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
