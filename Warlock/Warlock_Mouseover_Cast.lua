-- ============================================================
-- Warlock_Mouseover_Cast.lua
-- 功能：监控鬼影缠身（法术ID 47843）施放和鼠标指向，
--       控制 ShouldCastSpellOnMouseover 开关
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

ShouldCastSpellOnMouseover = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_START" then
        local unit, _, spellId = ...
        -- 鬼影缠身（ID 47843）施放时，关闭鼠标指向施法
        if unit == "player" and spellId == 47843 then
            ShouldCastSpellOnMouseover = false
        end
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        local mouseoverGUID = UnitGUID("mouseover")
        if mouseoverGUID then
            ShouldCastSpellOnMouseover = true  -- 有鼠标指向时启用
        end
    end
end)