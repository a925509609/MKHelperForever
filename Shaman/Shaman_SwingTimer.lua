-- ============================================================
-- Shaman_SwingTimer.lua
-- 功能：监控萨满祭司的主副手平砍计时，
--       用于增强萨满的漩涡武器层数判断等
-- ============================================================

if WR_PlayerClass ~= "SHAMAN" then return end

if UnitClassBase("player") ~= "SHAMAN" then
    return
end

-- ============================================================
-- ★ 全局变量（供增强萨主循环使用）
-- ============================================================
LastMainHandTime = 0
LastOffHandTime = 0
NextMainHandTime = 0   -- 主手下次平砍剩余时间（秒）
NextOffHandTime = 0    -- 副手下次平砍剩余时间（秒）

-- ============================================================
-- ★ 战斗日志监听：记录平砍时间
-- ============================================================
local TempFrame = CreateFrame("Frame")
WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")

TempFrame:SetScript("OnEvent", function(self, event, ...)
    local _, subevent, _, sourceGUID, _, _, _, _, _, _, _, _, _, _, _, isOffHand = unpack(WR_CombatLogEvent)
    if sourceGUID == UnitGUID("player") and (subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED") then
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

-- ============================================================
-- ★ 定时更新：计算下次平砍剩余时间
-- ============================================================
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