-- ============================================================
-- Warlock_Incinerate_Switch.lua
-- 功能：监听烧尽的施放开始和失败事件，结合外部变量 rhzxcs，
--       控制开关 sjkaiguan，用于调整输出循环（例如避免连续施放烧尽）
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

sjkaiguan = true
if rhzxcs == nil then
    rhzxcs = 0
end

local function OnCombatEvent(self, event, ...)
    local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags,
          destGUID, destName, destFlags, destRaidFlags,
          _, spellId, spellName = unpack(WR_CombatLogEvent)

    if subEvent == "SPELL_CAST_START" and spellName == "烧尽" and sourceName == UnitName("player") then
        C_Timer.After(0.2, function()
            if rhzxcs ~= nil and (rhzxcs <= 1 or rhzxcs == nil) then
                sjkaiguan = false
            end
        end)
    end

    if subEvent == "SPELL_CAST_FAILED" and spellName == "烧尽" and sourceName == UnitName("player") then
        sjkaiguan = true
    end

    if rhzxcs ~= nil and rhzxcs == 3 then
        sjkaiguan = true
    end
end

local eventFrame = CreateFrame("Frame")
WR_RegisterEventSafe(eventFrame, "COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:SetScript("OnEvent", OnCombatEvent)