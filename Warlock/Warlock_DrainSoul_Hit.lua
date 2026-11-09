-- ============================================================
-- Warlock_DrainSoul_Hit.lua
-- 功能：监听吸取灵魂的周期性伤害事件，设置 xihun 标记为 true，
--       0.3 秒后恢复 false，用于判断是否正在引导中并造成了伤害
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

xihun = false

local frame = CreateFrame("Frame")
WR_RegisterEventSafe(frame, "COMBAT_LOG_EVENT_UNFILTERED")

local function ResetXihun()
    xihun = false
end

frame:SetScript("OnEvent", function(self, event)
    local timestamp, subEvent, _, sourceGUID, sourceName, _, _,
          destGUID, destName, _, _, spellId, spellname = unpack(WR_CombatLogEvent)

    if subEvent == "SPELL_PERIODIC_DAMAGE" and spellname == "吸取灵魂" and sourceGUID == UnitGUID("player") then
        xihun = true
        C_Timer.After(0.3, ResetXihun)
    end
end)