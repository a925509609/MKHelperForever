-- ============================================================
-- UI_Theme.lua
-- 功能：MKHelperForever 配置面板的集中视觉主题层
--       只定义配色 / 描边 / 控件统一样式，不承载任何交互逻辑。
--       切换主题：/mktheme dark | light（写入 PigSet.UI_THEME，/reload 后全面生效；
--       面板内控件在下次重建时自动读取新色板，已创建控件由 OnShow 重刷布局保持不变）
-- ============================================================

WR_UI_THEMES = {
    dark = {
        name     = "dark",
        bg       = { 0.09, 0.10, 0.12, 0.97 },  -- 主面板底
        region   = { 0.13, 0.145, 0.165, 0.90 },-- 左右区块底
        inset    = { 0.155, 0.17, 0.195, 0.98 },-- 输入框 / 嵌入控件底
        border   = { 0.24, 0.27, 0.31, 1.0 },   -- 主描边
        borderDim= { 0.18, 0.20, 0.23, 1.0 },   -- 弱描边
        divider  = { 0.19, 0.21, 0.24, 1.0 },   -- 分隔线
        text     = { 0.92, 0.93, 0.95, 1.0 },   -- 主文字
        textDim  = { 0.62, 0.65, 0.69, 1.0 },   -- 次文字
        accent   = { 0.30, 0.62, 1.00, 1.0 },   -- 品牌蓝（标题 / 分区竖条）
        hover    = { 0.20, 0.23, 0.27, 1.0 },   -- 悬停底色
        danger   = { 0.85, 0.26, 0.28, 0.95 },  -- 危险色（关闭按钮悬停）
        track    = { 0.16, 0.18, 0.21, 1.0 },   -- 滑块轨道
        thumb    = { 0.82, 0.84, 0.87, 1.0 },   -- 滑块拇指
        dim      = { 0.45, 0.48, 0.52, 0.9 },   -- 未选中图标描边
    },
    light = {
        name     = "light",
        bg       = { 0.96, 0.96, 0.97, 0.98 },
        region   = { 0.905, 0.915, 0.93, 0.95 },
        inset    = { 0.86, 0.87, 0.89, 1.0 },
        border   = { 0.70, 0.72, 0.76, 1.0 },
        borderDim= { 0.80, 0.82, 0.85, 1.0 },
        divider  = { 0.78, 0.80, 0.83, 1.0 },
        text     = { 0.13, 0.14, 0.16, 1.0 },
        textDim  = { 0.42, 0.45, 0.50, 1.0 },
        accent   = { 0.16, 0.48, 0.93, 1.0 },
        hover    = { 0.85, 0.87, 0.90, 1.0 },
        danger   = { 0.80, 0.25, 0.27, 0.95 },
        track    = { 0.80, 0.82, 0.85, 1.0 },
        thumb    = { 1.0, 1.0, 1.0, 1.0 },
        dim      = { 0.72, 0.74, 0.78, 0.9 },
    },
}

-- 读取当前色板（PigSet.UI_THEME 未设置时默认 dark）
function WR_UI_P()
    if PigSet and PigSet.UI_THEME == "light" then
        return WR_UI_THEMES.light
    end
    return WR_UI_THEMES.dark
end

-- 把主题三原色转成 |cffRRGGBB 文本色码（供富文本拼接）
function WR_UI_Hex(pal, key)
    local c = pal[key]
    return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end

local BACKDROP_FLAT = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    tile     = false,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
}

-- kind = "panel"(主面板) | "region"(左右区块) | "inset"(输入框等嵌入件)
function WR_UI_ApplyBackdrop(frame, kind)
    if not frame or not frame.SetBackdrop then return frame end
    frame:SetBackdrop(BACKDROP_FLAT)
    local pal = WR_UI_P()
    if kind == "panel" then
        frame:SetBackdropColor(pal.bg[1], pal.bg[2], pal.bg[3], pal.bg[4])
        frame:SetBackdropBorderColor(pal.border[1], pal.border[2], pal.border[3], pal.border[4])
    elseif kind == "region" then
        frame:SetBackdropColor(pal.region[1], pal.region[2], pal.region[3], pal.region[4])
        frame:SetBackdropBorderColor(pal.borderDim[1], pal.borderDim[2], pal.borderDim[3], pal.borderDim[4])
    elseif kind == "inset" then
        frame:SetBackdropColor(pal.inset[1], pal.inset[2], pal.inset[3], pal.inset[4])
        frame:SetBackdropBorderColor(pal.borderDim[1], pal.borderDim[2], pal.borderDim[3], pal.borderDim[4])
    end
    return frame
end

-- 统一滑块三件套颜色（track / fill / thumb），fill 用职业色由调用方传入
function WR_UI_FlatSlider(track, border, fill, thumb, classColor)
    local pal = WR_UI_P()
    if track then track:SetVertexColor(pal.track[1], pal.track[2], pal.track[3], 1) end
    if border then border:SetVertexColor(pal.borderDim[1], pal.borderDim[2], pal.borderDim[3], 1) end
    if fill then fill:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.9) end
    if thumb then
        thumb:SetVertexColor(pal.thumb[1], pal.thumb[2], pal.thumb[3], 1)
        thumb:SetAlpha(1)
    end
end

-- 统一标签文字（kind = "label" 行标签 | "dim" 次级 | "title" 分区标题）
function WR_UI_Label(fs, kind)
    if not fs or not fs.SetTextColor then return fs end
    local pal = WR_UI_P()
    if kind == "dim" then
        fs:SetTextColor(pal.textDim[1], pal.textDim[2], pal.textDim[3], 1)
    elseif kind == "title" then
        fs:SetTextColor(pal.text[1], pal.text[2], pal.text[3], 1)
    else
        fs:SetTextColor(pal.text[1], pal.text[2], pal.text[3], 1)
    end
    return fs
end

-- 主题切换命令：/mktheme dark | light（/reload 后全面生效）
SLASH_MKUITHEME1 = "/mktheme"
SlashCmdList["MKUITHEME"] = function(msg)
    msg = strlower(strtrim(msg or ""))
    if msg ~= "dark" and msg ~= "light" then
        print("|cff00adf0[MKHelperForever]|r 当前主题："
            .. tostring((PigSet and PigSet.UI_THEME) or "dark")
            .. "；用法 /mktheme dark | light（切换后 /reload 生效）")
        return
    end
    PigSet.UI_THEME = msg
    print("|cff00adf0[MKHelperForever]|r 主题已切换为 " .. msg .. "，输入 /reload 生效。")
end
