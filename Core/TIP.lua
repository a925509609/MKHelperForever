-- ============================================================
-- TIP.lua
-- 功能：创建屏幕中央的大字提示框架，用于显示技能/状态提醒
--       支持自定义文字、颜色、显示时长
-- ============================================================

if not PigAlertFrame then
    PigAlertFrame = CreateFrame("MessageFrame", "PigAlertFrame", UIParent)
    PigAlertFrame:SetPoint("CENTER", 0, 250)
    PigAlertFrame:SetSize(800, 150)
    PigAlertFrame:SetFrameStrata("TOOLTIP")

    local fontPath = (ChatFontNormal and ChatFontNormal:GetFont()) or "Fonts\\ARKai_T.ttf"
    PigAlertFrame:SetFont(fontPath, 50, "OUTLINE")
end

-- 显示提示信息
-- @param text: 显示的文字
-- @param r: 红色分量 (0-1)
-- @param g: 绿色分量 (0-1)
-- @param b: 蓝色分量 (0-1)
-- @param holdTime: 显示持续时间（秒）
function PigAlert(text, r, g, b, holdTime)
    if not text then return end

    local red = r or 1
    local green = g or 0.5
    local blue = b or 0
    local duration = holdTime or 0.8

    PigAlertFrame:Clear()
    PigAlertFrame:SetTimeVisible(duration)
    PigAlertFrame:SetFadeDuration(0.1)
    PigAlertFrame:AddMessage(text, red, green, blue)
end

-- 测试命令：/pg
SLASH_PIGTEST1 = "/pg"
SlashCmdList["PIGTEST"] = function()
    PigAlert("⚠️ 提示测试：MKHelperForever 框架功能正常！", 0, 1, 0, 2)
end