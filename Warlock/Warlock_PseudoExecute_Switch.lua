-- ============================================================
-- Warlock_PseudoExecute_Switch.lua
-- 功能：监控鼠标指向目标，并监听鬼影缠身施法，
--       用以控制是否开启“伪斩杀”模式（pianmiesha 变量）
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

pianmiesha = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_START" then
        local unit, _, spellId = ...
        -- 鬼影缠身（法术ID 686）施放时，将伪斩杀标记置为 false
        if unit == "player" and spellId == 686 then
            pianmiesha = false
        end
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        local mouseoverGUID = UnitGUID("mouseover")
        if mouseoverGUID then
            pianmiesha = true  -- 有鼠标指向目标时，启用伪斩杀
        end
    end
end)