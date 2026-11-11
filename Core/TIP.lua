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
    -- ★★ 2026-11-11：屏幕文字提示总闸（PigSet.ScreenTextNotice，默认关闭）。
    -- 所有 PigAlert 调用点（术士暗影灼烧/惩戒站位/防骑天赋提示等）统一在此拦截，
    -- 不再逐个删调用点，也不影响循环判定与色块逻辑。
    if type(WR_ScreenTextNoticeEnabled) ~= "function"
        or not WR_ScreenTextNoticeEnabled() then return end

    local red = r or 1
    local green = g or 0.5
    local blue = b or 0
    local duration = holdTime or 0.8

    PigAlertFrame:Clear()
    PigAlertFrame:SetTimeVisible(duration)
    PigAlertFrame:SetFadeDuration(0.1)
    PigAlertFrame:AddMessage(text, red, green, blue)
end

-- 测试命令：/pg（总闸关闭时不再弹测试大字，只给一条普通聊天反馈）
SLASH_PIGTEST1 = "/pg"
SlashCmdList["PIGTEST"] = function()
    if type(WR_ScreenTextNoticeEnabled) ~= "function"
        or not WR_ScreenTextNoticeEnabled() then
        print("|cff00ff00[MKHelperForever]|r 屏幕文字提示已关闭；用 /screentip on 可重新开启。")
        return
    end
    PigAlert("⚠️ 提示测试：MKHelperForever 框架功能正常！", 0, 1, 0, 2)
end

-- ============================================================
-- ★ 屏幕文字提示总闸命令：/screentip on | off | status
-- 全局区「屏幕文字提示」复选框与此处写的是同一个 PigSet 字段。
-- 面板打开时用 WR_RefreshScreenTextCheckbox 同步勾选态（定义于 UI_Config.lua）。
-- ============================================================
SLASH_SCREENTIP1 = "/screentip"
SlashCmdList["SCREENTIP"] = function(msg)
    msg = strtrim(strlower(msg or ""))
    if PigSet == nil then PigSet = {} end
    if msg == "on" or msg == "1" then
        PigSet["ScreenTextNotice"] = true
    elseif msg == "off" or msg == "0" then
        PigSet["ScreenTextNotice"] = false
    elseif msg == "" or msg == "status" then
        -- 仅查询，不改状态
    else
        print("|cff00ff00[MKHelperForever]|r 用法: /screentip on | off | status")
        return
    end
    local state = WR_ScreenTextNoticeEnabled() and "|cff00ff00开启|r" or "|cffff0000关闭|r"
    print("|cff00ff00[MKHelperForever]|r 屏幕文字提示总开关: " .. state
        .. "（/pigchat 可单独调整聊天框提示窗口）")
    if type(WR_RefreshScreenTextCheckbox) == "function" then
        WR_RefreshScreenTextCheckbox()
    end
end