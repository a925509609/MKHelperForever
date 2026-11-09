-- ============================================================
-- Warlock_DrainSoul_SnapshotSave.lua
-- 功能：在成功施放“吸取灵魂”时，调用 calculateLive() 函数
--       保存当前快照数据到全局变量 savexqlh
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

local spellID_DrainSoul = "吸取灵魂"

local frame = CreateFrame("Frame")
WR_RegisterEventSafe(frame, "COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", function(self, event)
    local timestamp, subEvent, _, sourceGUID, sourceName, _, _,
          destGUID, destName, _, _, spellId, spellname = unpack(WR_CombatLogEvent)

    if subEvent == "SPELL_CAST_SUCCESS" and spellname == spellID_DrainSoul and sourceGUID == UnitGUID("player") then
        savexqlh = calculateLive()
    end
end)