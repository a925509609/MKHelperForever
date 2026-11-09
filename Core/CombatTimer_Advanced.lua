-- ============================================================
-- CombatTimer_Advanced.lua
-- 功能：监控战斗开始时间，计算zhandoutime（战斗已持续秒数）
--       支持BOSS战（ENCOUNTER事件）和野外战斗（REGEN事件）
-- ============================================================

zhandoutime = 0
local combatStartTime = 0
local isSoloCombat = false

local f = CreateFrame("Frame")
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

local function StartTimer()
    combatStartTime = GetTime()
    zhandoutime = 0
    f:SetScript("OnUpdate", function()
        zhandoutime = GetTime() - combatStartTime
    end)
end

local function StopTimer()
    f:SetScript("OnUpdate", nil)
    zhandoutime = 0
end

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ENCOUNTER_START" then
        isSoloCombat = false
        StartTimer()

    elseif event == "ENCOUNTER_END" then
        StopTimer()

    elseif event == "PLAYER_REGEN_DISABLED" then
        if not IsInGroup() and not IsInInstance() then
            isSoloCombat = true
            StartTimer()
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if isSoloCombat then
            isSoloCombat = false
            StopTimer()
        end
    end
end)