-- ============================================================
-- Warlock_PetFocusTarget_Switch.lua
-- 功能：记录恶魔增效（ID 47809）施放的目标类型（宠物当前目标、焦点、目标），
--       并设置对应的开关变量（petkaiguan / focuskaiguan / lianfakaiguan）
--       供其它逻辑判断增益施放对象
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

local function OnCombatEvent(self, event, ...)
    local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags,
          destGUID, destName, destFlags, destRaidFlags,
          spellId, spellName = unpack(WR_CombatLogEvent)

    if subEvent == "SPELL_CAST_SUCCESS" and spellId == 47809 and sourceName == UnitName("player") then
        if destGUID == UnitGUID("pettarget") then
            petkaiguan = true
        end
        if destGUID == UnitGUID("focus") then
            focuskaiguan = true
        end
        if destGUID == UnitGUID("target") then
            petkaiguan = true
            focuskaiguan = true
            lianfakaiguan = false
        end
    end
end

local eventFrame = CreateFrame("Frame")
WR_RegisterEventSafe(eventFrame, "COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:SetScript("OnEvent", OnCombatEvent)