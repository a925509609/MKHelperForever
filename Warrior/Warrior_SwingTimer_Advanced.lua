-- ============================================================
-- Warrior_SwingTimer_Advanced.lua
-- 功能：监控玩家主/副手平砍计时，以及英勇/顺劈等技能对计时的影响
-- ============================================================

if WR_PlayerClass ~= "WARRIOR" then return end

local LastMainHandTime = 0
local LastOffHandTime  = 0
NextMainHandTime       = 0
NextOffHandTime        = 0
ElapsedMainHandTime    = 0
ElapsedOffHandTime     = 0

local TempFrame = CreateFrame("Frame")
WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")

TempFrame:SetScript("OnEvent", function(self, event, ...)
    local _, subevent, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName,
          _, _, isOffHandMiss, _, _, _, _, isOffHand = unpack(WR_CombatLogEvent)

    if sourceGUID == UnitGUID("player") then
        if subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED" then
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

        elseif (subevent == "SPELL_DAMAGE" or subevent == "SPELL_MISSED") and
               (spellName == "英勇打击" or spellName == "顺劈斩") then
            LastMainHandTime = GetTime()

        elseif (subevent == "SPELL_DAMAGE" or subevent == "SPELL_MISSED") and
               (spellName == "英勇投掷" or spellName == "碎裂投掷") then
            LastMainHandTime = GetTime()
            LastOffHandTime  = GetTime()
        end
    end
end)

TempFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.1 then return end
    self.elapsed = 0
    local mainSpeed, offSpeed = UnitAttackSpeed("player")
    local currentTime       = GetTime()

    -- 主手计时
    if LastMainHandTime ~= 0 and mainSpeed then
        NextMainHandTime = LastMainHandTime + mainSpeed - currentTime
        if NextMainHandTime < 0 then
            NextMainHandTime = 0
        end
        ElapsedMainHandTime = currentTime - LastMainHandTime
        if ElapsedMainHandTime > mainSpeed then
            ElapsedMainHandTime = mainSpeed
        end
    end

    -- 副手计时
    if LastOffHandTime ~= 0 and offSpeed then
        NextOffHandTime = LastOffHandTime + offSpeed - currentTime
        if NextOffHandTime < 0 then
            NextOffHandTime = 0
        end
        ElapsedOffHandTime = currentTime - LastOffHandTime
        if ElapsedOffHandTime > offSpeed then
            ElapsedOffHandTime = offSpeed
        end
    end

    -- 检测当前是否正在施放英勇/顺劈（供其它模块使用）
    yingyong = IsCurrentSpell("英勇打击")
    shunpi   = IsCurrentSpell("顺劈斩")
end)