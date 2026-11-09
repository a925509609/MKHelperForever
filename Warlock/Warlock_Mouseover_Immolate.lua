-- ============================================================
-- Warlock_Mouseover_Immolate.lua
-- 功能：监控献祭（法术ID 47811）施放和鼠标指向，
--       控制 zhi_xiang_xian_ji（指向献祭）开关
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

zhi_xiang_xian_ji = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_START" then
        local unit, _, spellId = ...
        -- 献祭（ID 47811）施放时，关闭指向献祭
        if unit == "player" and spellId == 47811 then
            zhi_xiang_xian_ji = false
        end
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        local mouseoverGUID = UnitGUID("mouseover")
        if mouseoverGUID then
            zhi_xiang_xian_ji = true   -- 有鼠标指向时启用
        end
    end
end)