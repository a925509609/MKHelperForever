-- ============================================================
-- Warlock_FocusShadowBolt_Switch.lua
-- 功能：监听暗影箭施放，若满足条件（涉及外部变量 ffss, ayjcast, fgycsfly, fayzy），
--       则将焦点施法开关 focuskaiguan 置为 false，并在 2.5 秒后恢复
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

focuskaiguan = true

-- 检查是否满足暗影箭施放条件（依赖于外部全局变量）
function checkShadowBoltConditions()
    if ffss ~= nil and ayjcast ~= nil and fgycsfly ~= nil then
        if (fayzy ~= nil and ffss < ayjcast * 2 + fgycsfly + 1) or
           (fayzy ~= nil and fayzy < ayjcast * 2 + fgycsfly + 1) or
           (fayzy == nil and ffss < ayjcast * 2 + fgycsfly + 1) then
            return true
        end
    end
    return false
end

-- 2.5 秒后恢复焦点施法开关
function resetFocusSwitch2()
    focuskaiguan = true
end

-- 战斗日志监听
local function OnCombatEvent(self, event, ...)
    local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags,
          _, destGUID, destName, destFlags, destRaidFlags,
          spellId, spellName = unpack(WR_CombatLogEvent)

    if subEvent == "SPELL_CAST_START" and spellName == "暗影箭" and sourceName == UnitName("player") then
        if checkShadowBoltConditions() then
            focuskaiguan = false
            C_Timer.After(2.5, resetFocusSwitch2)
        end
    end
end

local eventFrame = CreateFrame("Frame")
WR_RegisterEventSafe(eventFrame, "COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:SetScript("OnEvent", OnCombatEvent)