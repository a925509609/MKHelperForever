-- ============================================================
-- Paladin_SwingTimer.lua
-- 功能：监控圣骑士的主副手平砍计时
--       用于惩戒骑/防护骑的技能优先级判断
-- ============================================================

if WR_PlayerClass ~= "PALADIN" then return end

if UnitClassBase("player") ~= "PALADIN" then
    return
end

local LastMainHandTime = 0
local LastOffHandTime = 0
NextMainHandTime = 0
NextOffHandTime = 0

local TempFrame = CreateFrame("Frame")
WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")

TempFrame:SetScript("OnEvent", function(self, event, ...)
    local _, subevent, _, sourceGUID, _, _, _, _, _, _, _, _, _, _, _, isOffHand =
        unpack(WR_CombatLogEvent)

    if sourceGUID == UnitGUID("player") and
       (subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED") then

        if subevent == "SWING_DAMAGE" then
            isOffHand = select(21, unpack(WR_CombatLogEvent))
        elseif subevent == "SWING_MISSED" then
            isOffHand = select(13, unpack(WR_CombatLogEvent))
        end

        if isOffHand then
            LastOffHandTime = GetTime()
        else
            LastMainHandTime = GetTime()
        end
    end
end)

TempFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.1 then return end
    self.elapsed = 0
    local mainSpeed, offSpeed = UnitAttackSpeed("player")

    if LastMainHandTime ~= 0 and mainSpeed then
        NextMainHandTime = LastMainHandTime + mainSpeed - GetTime()
        if NextMainHandTime < 0 then
            NextMainHandTime = 0
        end
    end

    if LastOffHandTime ~= 0 and offSpeed then
        NextOffHandTime = LastOffHandTime + offSpeed - GetTime()
        if NextOffHandTime < 0 then
            NextOffHandTime = 0
        end
    end
end)