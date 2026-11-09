-- ============================================================
-- Utils_Interrupt_Focus.lua
-- 功能：监控焦点目标的施法状态，对特定目标（如纳兹夏尔愈灵者等）
--       在施放可打断技能时开启 jiaoduankaiguan（角断开关）
-- ============================================================

jiaoduankaiguan = true

-- 需要打断的技能列表
local jiaoduanliebiao = {
    ["治疗波"] = true,
    ["强效治疗术"] = true,
    ["奥术风暴"] = true,
}

-- 需要特殊处理的焦点目标名称
local focusNames = {
    ["纳兹夏尔愈灵者"] = true,
    ["神殿助祭"] = true,
    ["马洛拉克"] = true,
}

local focusFrame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    if event == "PLAYER_FOCUS_CHANGED" then
        local name = WR_SafeUnitName("focus")
        if focusNames[name] then
            jiaoduankaiguan = false
        else
            jiaoduankaiguan = true
        end
    elseif event == "UNIT_SPELLCAST_START" then
        local unit, spellName = ..., UnitCastingInfo("focus")
        if unit == "focus" and focusNames[WR_SafeUnitName("focus")] and jiaoduanliebiao[spellName] then
            jiaoduankaiguan = true
        end
    elseif event == "UNIT_SPELLCAST_STOP" or
           event == "UNIT_SPELLCAST_FAILED" or
           event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unit = ...
        if unit == "focus" and focusNames[WR_SafeUnitName("focus")] then
            jiaoduankaiguan = false
        end
    end
end

focusFrame:RegisterEvent("UNIT_SPELLCAST_START")
focusFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
focusFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
focusFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
focusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
focusFrame:SetScript("OnEvent", OnEvent)