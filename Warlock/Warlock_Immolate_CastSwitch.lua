-- ============================================================
-- Warlock_Immolate_CastSwitch.lua
-- 功能：监听献祭施放，施放后置 xjkaiguan 为 false，
--       1.5 秒后自动恢复 true，用于避免重复献祭或控制循环
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

xjkaiguan = true

local function resetFocusSwitch()
    xjkaiguan = true
end

local function OnCombatEvent(self, event, ...)
    local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags,
          destGUID, destName, destFlags, destRaidFlags,
          _, spellId, spellName = unpack(WR_CombatLogEvent)

    if subEvent == "SPELL_CAST_START" and spellName == "献祭" and sourceName == UnitName("player") then
        xjkaiguan = false
        C_Timer.After(1.5, resetFocusSwitch)
    end
end

local eventFrame = CreateFrame("Frame")
WR_RegisterEventSafe(eventFrame, "COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:SetScript("OnEvent", OnCombatEvent)