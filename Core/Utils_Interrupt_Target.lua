-- ============================================================
-- Utils_Interrupt_Target.lua
-- 功能：监控当前目标的施法状态，对特定目标（如纳兹夏尔愈灵者等）
--       在施放可打断技能时开启 daduankaiguan（打断开关）
-- ============================================================

daduankaiguan = true

-- 需要打断的技能列表
local daduanliebiao = {
    ["治疗波"] = true,
    ["强效治疗术"] = true,
    ["奥术风暴"] = true,
}

-- 需要特殊处理的当前目标名称
local targetNames = {
    ["纳兹夏尔愈灵者"] = true,
    ["神殿助祭"] = true,
    ["马洛拉克"] = true,
    ["维扎克斯将军"] = true,
}

local frame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        local name = WR_SafeUnitName("target")
        if targetNames[name] then
            daduankaiguan = false
        else
            daduankaiguan = true
        end
    elseif event == "UNIT_SPELLCAST_START" then
        local unit, spellName = ..., UnitCastingInfo("target")
        if unit == "target" and targetNames[WR_SafeUnitName("target")] and daduanliebiao[spellName] then
            daduankaiguan = true
        end
    elseif event == "UNIT_CAST_SUCCESS" or
           event == "UNIT_SPELLCAST_FAILED" or
           event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unit = ...
        if unit == "target" and targetNames[WR_SafeUnitName("target")] then
            daduankaiguan = false
        end
    end
end

frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:SetScript("OnEvent", OnEvent)