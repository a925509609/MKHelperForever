-- ============================================================
-- DebugHUD.lua（2026-08-25 落地项 #8）
-- 独立调试 HUD：每 0.5s 刷新显示
--   目标类型(BOSS/精英/稀有/普通)、饰品触发状态、焦点/目标预计死亡时间、自动爆发状态
-- 纯显示，不影响任何战斗逻辑。可鼠标拖动。
-- 同时整合「自动爆发(zidongbaofa) 目标类型提示」，统一在此实时呈现。
-- ============================================================

if not WR_DebugHUD then
    WR_DebugHUD = CreateFrame("Frame", "WR_DebugHUD", UIParent)
    WR_DebugHUD:SetSize(230, 150)
    WR_DebugHUD:SetPoint("CENTER", UIParent, "CENTER", 360, 220)
    WR_DebugHUD:SetFrameStrata("DIALOG")
    WR_DebugHUD:EnableMouse(true)
    WR_DebugHUD:SetMovable(true)
    WR_DebugHUD:RegisterForDrag("LeftButton")
    WR_DebugHUD:SetScript("OnDragStart", function(self) self:StartMoving() end)
    WR_DebugHUD:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- 默认隐藏，输入 /wrdebug 切换显示
    WR_DebugHUD:Hide()
    SLASH_WRDEBUG1 = "/wrdebug"
    SlashCmdList["WRDEBUG"] = function()
        if WR_DebugHUD:IsShown() then
            WR_DebugHUD:Hide()
        else
            WR_DebugHUD:Show()
        end
    end

    local bg = WR_DebugHUD:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.55)

    local fs = WR_DebugHUD:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", WR_DebugHUD, "TOPLEFT", 8, -8)
    fs:SetPoint("BOTTOMRIGHT", WR_DebugHUD, "BOTTOMRIGHT", -8, 8)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetFont(STANDARD_TEXT_FONT, 12, "")
    fs:SetTextColor(1, 1, 1, 1)
    WR_DebugHUD.text = fs

    WR_DebugHUD.lastUpdate = 0

    local function GetTargetType(unit)
        if not unit or not UnitExists(unit) then return "无目标" end
        if WR_UnitIsBoss and WR_UnitIsBoss(unit) then return "BOSS" end
        local cls = UnitClassification(unit)
        if cls == "worldboss" then return "BOSS"
        elseif cls == "elite" or cls == "rareelite" then return "精英"
        elseif cls == "rare" then return "稀有" end
        return "普通"
    end

    local function FmtTime(t)
        if not t or t <= 0 then return "-" end
        if t >= 8888 then return "∞" end
        return string.format("%.1fs", t)
    end

    local function TrinketStr(slot)
        local active = _G["PIG_shipin" .. slot] or 0
        local cd = _G["PIG_shipincd" .. slot] or 0
        if active and active > 0 then
            return string.format("触发 %.1fs", active)
        elseif cd and cd > 0 then
            return string.format("CD %.1fs", cd)
        end
        return "就绪"
    end

    WR_DebugHUD:SetScript("OnUpdate", function(self, elapsed)
        self.lastUpdate = self.lastUpdate + elapsed
        if self.lastUpdate < 0.5 then return end
        self.lastUpdate = 0

        local ttype = GetTargetType("target")
        local ftype = GetTargetType("focus")
        local ttd = (TargetDeathTime and TargetDeathTime > 0) and TargetDeathTime or WR_GetUnitDeathTime("target")
        local ftd = _G["JDtodeathtime"] or 0
        local baofa = (zidongbaofa == true) and "|cff00ff00开|r" or "|cffff0000关|r"

        local lines = {}
        table.insert(lines, "|cffFFD100调试 HUD|r")
        table.insert(lines, string.format("目标: %s  死亡: %s", ttype, FmtTime(ttd)))
        table.insert(lines, string.format("焦点: %s  死亡: %s", ftype, FmtTime(ftd)))
        table.insert(lines, string.format("饰品13: %s", TrinketStr(13)))
        table.insert(lines, string.format("饰品14: %s", TrinketStr(14)))
        table.insert(lines, string.format("自动爆发: %s", baofa))

        self.text:SetText(table.concat(lines, "\n"))
    end)
end
