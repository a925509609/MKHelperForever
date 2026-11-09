-- ============================================================
-- Priest_Mouseover_Cast.lua
-- 功能：记录鼠标是否指向有效目标（mouseover），
--       并在施放“能量灌注”（ID 48160）后重置为 false，
--       供其它模块判断是否执行鼠标指向施法
-- ============================================================

if WR_PlayerClass ~= "PRIEST" then return end

if UnitClassBase("player") ~= "PRIEST" then
    return
end

ShouldCastSpellOnMouseover = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_START" then
        local unit, _, spellId = ...
        if unit == "player" and spellId == 48160 then  -- 能量灌注
            ShouldCastSpellOnMouseover = false
        end
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        local mouseoverGUID = UnitGUID("mouseover")
        if mouseoverGUID then
            ShouldCastSpellOnMouseover = true
        end
    end
end)