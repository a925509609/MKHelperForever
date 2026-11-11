-- ============================================================
-- UI_ColorFrame_1.lua
-- 功能：控制色彩框架的显示、隐藏、大小切换，
--       以及 WR_ColorFrame_Show 入口函数
-- ============================================================

-- ★ 2026-11-11：屏幕文字提示总闸（PigSet.ScreenTextNotice，默认关闭）。
-- 只隐藏「文字」，色块颜色框架本身照常 Show（AHK 取色依赖，不能关）。
-- 技能名仍写入 FontString（SetText 保留），只做 Hide/Show，避免影响
-- Paladin_Forever.lua 里读取 GetText 判断「当前是否亮着该技能」的逻辑。
-- 不覆盖：色块本身的颜色显示（AHK 取色依赖，必须保留）。
local function WR_ColorTextVisible()
    if type(WR_ScreenTextNoticeEnabled) ~= "function" then return false end
    return WR_ScreenTextNoticeEnabled() == true
end

-- ★ 2026-08-30：技能提示图标框兜底映射（描述/拼接型 text → 真实技能名）
--   WotLK(3.3.5) 下 GetSpellInfo 只认技能名；WR_ColorFrame_Show 传入的 text 多为技能名，
--   但「指向保护」「填充奉献」等描述/拼接型需此处映射成真实技能名才能取到图标。
--   如需补全其它职业的描述型提示，往此表加 [显示文字] = 真实技能名 即可。
WR_SkillIcon_TextMap = {
    ["指向保护"] = "保护之手",
    ["指向牺牲"] = "牺牲之手",
    ["指向拯救"] = "拯救之手",
    ["填充奉献"] = "奉献",
    ["多目标奉献"] = "奉献",
    ["优先神圣之盾"] = "神圣之盾",
    ["填充神圣之盾"] = "神圣之盾",
}

-- ★ 2026-08-30：技能名解析兜底（让描述/括号/指代型 text 也能取到图标）
--   1) 精确查 WR_SkillIcon_TextMap；2) 去括号内容（「多重射击(AOE)」→「多重射击」）再试；
--   3) 去常见前缀（指向/焦点/目标/宝宝/自动/多目标/填充/优先）再试。
local WR_SkillIcon_Prefix = { ["指向"]=true, ["焦点"]=true, ["目标"]=true, ["宝宝"]=true, ["自动"]=true, ["多目标"]=true, ["填充"]=true, ["优先"]=true }
local function WR_SkillIcon_ResolveName(text)
    if not text or text == "" then return text end
    if WR_SkillIcon_TextMap[text] then return WR_SkillIcon_TextMap[text] end
    -- 去括号（中英文括号）
    local base = text:gsub("%（[^%)]*%）", ""):gsub("%([^%)]*%)", "")
    if base ~= text and GetSpellInfo(base) then return base end
    -- 去前缀
    for pfx in pairs(WR_SkillIcon_Prefix) do
        if base:sub(1, #pfx) == pfx then
            local cand = base:sub(#pfx + 1)
            if cand ~= "" and GetSpellInfo(cand) then return cand end
        end
    end
    return text
end

-- 隐藏指定位置的框架（Point = nil 或 0 为左上，Point = 1 为右上）
function WR_HideColorFrame(Point)
    if Point == nil or Point ~= 1 then
        for _, frame in pairs(ColorFrameArrayTopLeft) do
            frame:Hide()
        end
    end
    if Point == 1 then
        for _, frame in pairs(ColorFrameArrayTopRight) do
            frame:Hide()
        end
    end
    -- 隐藏独立的技能图标框体
    --   - 开关关闭时整个框体完全隐藏（什么都不显示）
    --   - 开关开启时仅隐藏图标+文字，保留空边框占位（可拖动）
    if WR_SkillIconFrame then
        if PigSet["SkillIconShow"] == false then
            WR_SkillIconFrame:Hide()
        else
            if WR_SkillIconFrame.Icon then WR_SkillIconFrame.Icon:Hide() end
            if WR_SkillIconFrame.Text then WR_SkillIconFrame.Text:Hide() end
        end
    end
end

-- 缩小所有框架（用于紧凑显示模式）
function WR_MinColorFrame()
    for _, frame in pairs(ColorFrameArrayTopLeft) do
        frame:SetSize(5, 5)
    end
    for _, text in pairs(ColorTextArrayTopLeft) do
        text:Hide()
    end
    for _, frame in pairs(ColorFrameArrayTopRight) do
        frame:SetSize(5, 5)
    end
    for _, text in pairs(ColorTextArrayTopRight) do
        text:Hide()
    end
end

-- 恢复所有框架到正常大小
function WR_MaxColorFrame()
    for _, frame in pairs(ColorFrameArrayTopLeft) do
        frame:SetSize(42, 42)
    end
    -- 总闸关闭时不要把技能名文字重新 Show 出来
    if WR_ColorTextVisible() then
        for _, text in pairs(ColorTextArrayTopLeft) do
            text:Show()
        end
    end
    for _, frame in pairs(ColorFrameArrayTopRight) do
        frame:SetSize(42, 42)
    end
    if WR_ColorTextVisible() then
        for _, text in pairs(ColorTextArrayTopRight) do
            text:Show()
        end
    end
end

-- 显示指定的框架
function WR_ShowColorFrame(name, text, Point)
    -- ★ 2026-08-21：独立的技能提示图标框体
    --   开关关闭时整个框体（含底色/边框）完全隐藏；开启时框体常驻显示（无提示仅边框占位，可拖动）
    local showIcon = (PigSet["SkillIconShow"] == true)  -- ★ 2026-08-21：默认不显示（仅显式开启才显示）
    if WR_SkillIconFrame then
        if not showIcon then
            -- 取消「技能图标」复选：什么都不显示
            WR_SkillIconFrame:Hide()
        elseif text and text ~= "" then
            -- ★ 2026-08-30：WotLK(3.3.5) 的 GetSpellTexture 仅接受数字法术 ID，而传入的 text 是技能名/描述文字，
            --   故改用 GetSpellInfo(name) 取第 3 返回值（图标路径）；真实技能名可正确显示图标，
            --   描述/拼接型（如「指向保护」）经 WR_SkillIcon_TextMap 兜底映射到真实技能名。
            local spellName = WR_SkillIcon_ResolveName(text)
            local ok, _, _, tex = pcall(GetSpellInfo, spellName)
            if ok and tex then
                WR_SkillIconFrame.Icon:SetTexture(tex)
                WR_SkillIconFrame.Icon:Show()
            else
                WR_SkillIconFrame.Icon:SetTexture(nil)
                WR_SkillIconFrame.Icon:Hide()
            end
            WR_SkillIconFrame.Text:SetText(text)
            if WR_ColorTextVisible() then
                WR_SkillIconFrame.Text:Show()
            else
                WR_SkillIconFrame.Text:Hide()
            end
            WR_SkillIconFrame:Show()
        else
            -- 开关开启但当前无提示文字：保留框体常驻可见（空边框占位，可拖动）
            if WR_SkillIconFrame.Icon then WR_SkillIconFrame.Icon:Hide() end
            if WR_SkillIconFrame.Text then WR_SkillIconFrame.Text:Hide() end
            WR_SkillIconFrame:Show()
        end
    end

    if Point == nil or Point ~= 1 then
        WR_EnsureColorSlot(name, "Left")
        if ColorFrameArrayTopLeft[name] then
            ColorFrameArrayTopLeft[name]:Show()
            local fs = ColorTextArrayTopLeft[name]
            fs:SetText("|cffffffff" .. text .. "\n" .. name)
            if WR_ColorTextVisible() then fs:Show() else fs:Hide() end
        else
            print("错误：[" .. name .. "]" .. text)
        end
    else
        WR_EnsureColorSlot(name, "Right")
        if ColorFrameArrayTopRight[name] then
            ColorFrameArrayTopRight[name]:Show()
            local fs = ColorTextArrayTopRight[name]
            fs:SetText("|cffffffff" .. text .. "\n" .. name)
            if WR_ColorTextVisible() then fs:Show() else fs:Hide() end
        else
            print("错误：[" .. name .. "]" .. text)
        end
    end
end

-- 对外接口：先隐藏所有框架，再显示指定框架（用于循环中返回 true）
function WR_ColorFrame_Show(Name, Text)
    WR_HideColorFrame(zhandoumoshi)
    WR_ShowColorFrame(Name, Text, zhandoumoshi)
    return true
end

-- 停止显示（临时隐藏所有框架，持续指定时间后恢复）
function WR_STOP(TempTime)
    if TempTime == nil or type(TempTime) ~= "number" then
        WR_TemporaryTtopTime = 0.5
    else
        WR_TemporaryTtopTime = TempTime
    end
    WR_StopTime = GetTime()
    WR_HideColorFrame(0)
    WR_HideColorFrame(1)
end