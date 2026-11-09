-- ============================================================
-- Combat_ResurrectPotion.lua
-- 功能：监控玩家战斗中复活状态
--       战斗中复活后，zhandoufuhuoyaoshui = false（60秒内不可用）
--       脱战或非战斗中复活则恢复可用
-- ============================================================

zhandoufuhuoyaoshui = true
local lastResurrectTime = 0
local inCombat = false

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("RESURRECT_REQUEST")
f:RegisterEvent("PLAYER_ALIVE")
f:RegisterEvent("PLAYER_UNGHOST")
f:RegisterEvent("PLAYER_DEAD")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true

    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false

    elseif event == "RESURRECT_REQUEST" then
        lastResurrectTime = GetTime()

    elseif event == "PLAYER_DEAD" then
        zhandoufuhuoyaoshui = true

    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        if inCombat then
            zhandoufuhuoyaoshui = false
            C_Timer.After(60, function()
                zhandoufuhuoyaoshui = true
            end)
        else
            zhandoufuhuoyaoshui = true
        end
    end
end)