-- ============================================================
-- UI_Config.lua - MKHelperForever 配置界面
-- 兼容怀旧服，所有跟随操作通过宏执行
-- ============================================================

--[[
    本文件负责创建 MKHelperForever 插件的图形配置界面（GUI）。
    它包含了：
      - 主框架（可拖拽、缩放、调整透明度）
      - 每个天赋（如惩戒、防护、神圣等）独立的面板
      - 复选框（图标+开关）用于启用/禁用功能
      - 下拉菜单用于选择选项（如圣印、祝福等）
      - 滑块用于调节数值（如阈值、缩放等）
      - 自动跟随功能（通过宏实现）
    所有配置保存在全局表 PigSet 中。
--]]

local _, playerClass = UnitClass("player")   -- 获取玩家职业
PIG_UI_PANEL_TITLE = "|cff808080MKHelperForever|r"            -- 界面标题颜色（蓝绿色）
PIG_RtUiCaptionHash = 0x2392466B              -- 用于防篡改的哈希值
PIG_RtUiCaptionSeal = 0x6252CB38              -- 另一个哈希值

local classColor = RAID_CLASS_COLORS[playerClass] or { r = 1, g = 0.82, b = 0 } -- 职业颜色

-- ============================================================
-- ★ 界面尺寸与字体相关参数（可调常量）
-- ★ 2026-08-21：对齐 ZZHELPER 单面板紧凑式呈现（图标34px/列距39/行距64/复选框24px/深色面板）
-- ============================================================
local CB_CELL_W = 74           -- 每个复选框单元格宽度（★ 2026-08-21：再翻倍，图标34+空隙40；原 54 空隙20）
local CB_CELL_H = 62           -- 每个复选框单元格高度（图标 34 + 间距 + 复选框 24 ≈ 62，ZZHELPER 行距 64）
local CB_ICON_CB_GAP = 4       -- 图标与下方复选框之间的垂直间距（ZZHELPER 勾选标记 BOTTOM(0,3) 取 4）
local CB_SIDE_PAD = 8          -- 左右两侧内边距
local ICON_BASE_SIZE = 34      -- 图标基础大小（ZZHELPER：34×34）
local CB_BASE_SIZE = 24        -- 复选框基础大小（ZZHELPER：24×24）
local ICON_LABEL_SCALE = 1.0   -- 图标标签文字缩放
local DEFAULT_ICON_COLS = 4    -- 默认每行图标数量
local MENU_DROPDOWN_W = 150    -- 下拉菜单默认宽度（右区会根据可用空间动态压缩）
local MENU_ROW_H = 25          -- 下拉菜单/滑块每行高度（ZZHELPER：行高 25）
local MENU_TOP_PAD = 2         -- 菜单区第一行顶部留白（紧凑：原6→2）
local MENU_LABEL_W = 60        -- 右区下拉/滑块标签固定宽度（紧凑：原 100→60，2~4 字标签留少量内边距即可，不再撑满右半区）
local talentFrameSeq = 0       -- 天赋面板编号计数器

-- ★ 左右分区布局相关常量（左全局区 / 右职业区）
local GLOBAL_REGION_W = 190    -- 左侧全局区固定宽度
local GLOBAL_OUTER_PAD = 6     -- 左区外侧左边距
local DIV_GAP = 8              -- 左右区分隔间距
local RIGHT_OUTER_PAD = 6      -- 右区外侧右边距
local TOP_BAR_H = 42           -- 顶栏高度（★ 2026-08-21 v3：36→42，让图标 24px 锚 (8,-12) 后距顶部 1px 横线 12px、距深色条底边 6px，完全避开"全局上面那根横线切断图标"）
local BOTTOM_BAR_H = 0         -- 底栏高度（图标缩放/窗口透明度滑块已迁入左侧全局区，右区不再预留底栏）
local GLOBAL_ROW_H = 20        -- 左区每行控件高度（紧凑：复选框/滑块统一 20px 行高，消除 20/24/32 混用造成的节奏错乱）
local GLOBAL_INNER_PAD = 6     -- 左区内部左边距
local MIN_RIGHT_COLS = 2       -- 右职业区至少显示的图标列数
-- ★ 2026-08-21：右区宽度缩到约为左区 2 倍（左 190 + 右 ≈380）
local MIN_TOTAL_WIDTH = 495    -- 主面板最小总宽度（★ 2026-08-21 v2：580→495，右区=285=1.5×左区190；原 580 右区 370≈2×左区）
local DEFAULT_FRAME_WIDTH = 495 -- 主面板默认宽度（★ 2026-08-21 v2：与最小宽度一致，右区=1.5×左区）
local DEFAULT_FRAME_HEIGHT = 460 -- 主面板默认高度（兜底：实际高度由 WR_LayoutConfigFrame 按内容收敛，远低于此值）
local MAX_FRAME_HEIGHT = 1000  -- 主面板最大默认高度（放宽：原 680→1000，让超高职业的 6+ section 完整显示，
                                    --   不再被 45% 压缩把"插入"section 挤到主面板外；超出 1000 的极端情况由 ScrollFrame 滚动处理）
local MENU_TITLE_H = 22        -- 右区天赋标题高度
local MENU_BOTTOM_PAD = 0      -- 右区下拉菜单区底部留白（收紧与图标区的距离）
local ICON_REGION_TOP_PAD = 6  -- 图标区顶部留白（菜单区最后一行下拉框 ↔ 第一个 section header 之间留 6px 空气，避免视觉贴脸）
local ICON_REGION_BOTTOM_PAD = 0 -- 图标区底部留白（紧贴主面板底，零空白）
local ICON_REGION_MIN_H = 40   -- 图标区最小高度（与 cellH 兜底一致）
local SECTION_HEADER_H = 22    -- 分类标题条高度（如「爆发」）
local SECTION_HEADER_GAP = 10  -- 分类标题条上下留白（10：与复选框图标-文字间距 5px 略宽，留视觉呼吸；原 0 太贴脸）

-- ★ 宏索引缓存（避免重复查找）
local FOLLOW_MACRO_INDEX = nil
local FOCUS_MACRO_INDEX = nil

-- ★ 切换提示信息输出（统一供下拉菜单/复选框切换调用，与6冰触提示方式一致）
--    ChatNoticeMode：0=关闭 1=默认窗口 2=所有可见窗口
local function PrintToVisible(msg)
    local mode = PigSet["ChatNoticeMode"]
    if mode == 0 then return end
    if mode == 1 then print(msg); return end
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf and cf:IsVisible() then
            cf:AddMessage(msg)
        end
    end
end

-- ★ 全局包装：供 UI_Config 之外的模块（如 MainLoop 焦点跟随提示）调用，
--   行为与 PrintToVisible 完全一致（尊重 ChatNoticeMode：0关/1默认窗口/2所有可见窗口）
function WR_PrintToVisible(msg)
    PrintToVisible(msg)
end

-- ============================================================
-- ★ 确保跟随宏存在（在插件加载时执行）
-- 创建两个宏：/follow focus 和 /focus
-- ============================================================
local function EnsureFollowMacros()
    -- 创建跟随宏（内容：/follow focus）
    local followName = "WR_FOLLOW"
    if not GetMacroInfo(followName) then
        CreateMacro(followName, "跟随", nil, "/follow focus")
    end
    FOLLOW_MACRO_INDEX = GetMacroIndexByName(followName)

    -- 创建焦点宏（内容：/focus）
    local focusName = "WR_FOCUS"
    if not GetMacroInfo(focusName) then
        CreateMacro(focusName, "焦点", nil, "/focus")
    end
    FOCUS_MACRO_INDEX = GetMacroIndexByName(focusName)
end

EnsureFollowMacros()

-- ============================================================
-- 工具函数（用于操作下拉菜单和图标布局）
-- ============================================================

-- 调整下拉菜单的宽度
local function ResizeDropdownBox(dropdown, boxW)
    UIDropDownMenu_SetWidth(dropdown, boxW)
    dropdown:SetWidth(boxW)
    local left = _G[dropdown:GetName() .. "Left"]
    local middle = _G[dropdown:GetName() .. "Middle"]
    local right = _G[dropdown:GetName() .. "Right"]
    if left and middle and right then
        middle:SetWidth(math.max(20, boxW - left:GetWidth() - right:GetWidth()))
    end
    -- ★ 2026-08-21：强制锁死紧凑高度（兜底，确保不被原生 UIDropDownMenu_SetWidth 重建覆盖）
    if dropdown.SetHeight then dropdown:SetHeight(WR_DROPDOWN_H) end
end

-- （已移除 HideDropdownNativeText：现直接复用原生下拉文字显示选中值，无需隐藏）

-- 应用显示文字到下拉菜单（直接复用原生下拉文字，杜绝与原生 Text 叠加成双层重影）
local function ApplyDropdownDisplayText(dropdown, text, boxW)
    boxW = boxW or (dropdown.config and (dropdown.config.width or MENU_DROPDOWN_W)) or MENU_DROPDOWN_W
    ResizeDropdownBox(dropdown, boxW)
    -- 直接复用 UIDropDownMenu 的原生文字对象(Name.."Text")显示选中值，
    -- 关掉它自带的黑色阴影、把字号设为 18、染成职业色。
    -- 不再创建自定义 displayText，避免两个文字对象叠在一起形成重影。
    local nativeText = _G[dropdown:GetName() .. "Text"]
    local nativeBtn = _G[dropdown:GetName() .. "Button"]
    if nativeText then
        nativeText:ClearAllPoints()
        -- ★ 2026-08-21：外框已取消，文字直接左对齐在下拉框内；有箭头时让出箭头宽度
        nativeText:SetPoint("LEFT", dropdown, "LEFT", 4, 0)
        nativeText:SetPoint("RIGHT", nativeBtn or dropdown, nativeBtn and "LEFT" or "RIGHT", nativeBtn and -2 or 0, 0)
        nativeText:SetJustifyH("LEFT")
        nativeText:SetText(text)
        -- 使用 STANDARD_TEXT_FONT 彻底避免 UIDropDownMenuTemplate 原生阴影
        nativeText:SetFont(STANDARD_TEXT_FONT, 14, "")
        nativeText:SetTextColor(classColor.r, classColor.g, classColor.b)
        nativeText:SetAlpha(1)
        nativeText:Show()
    end
end

-- 将当前天赋的下拉菜单注册到全局 WR_Dropdown（便于外部调用）
local function WR_SetActiveDropdowns(talentFrame)
    if not talentFrame or not talentFrame.dmDropdowns then return end
    if not WR_Dropdown then WR_Dropdown = {} end
    for key, dropdown in pairs(talentFrame.dmDropdowns) do
        WR_Dropdown[key] = dropdown
    end
end

-- 清除水平调整光标
local function ClearHorizontalResizeCursor(owner)
    if owner then owner:SetScript("OnUpdate", nil) end
    if ResetCursor then ResetCursor() end
end

-- 隐藏图标的高亮/光环效果
local function HideIconGlow(iconFrame, iconTexture)
    if iconFrame.glowFrame then iconFrame.glowFrame:Hide() end
    if iconFrame.glowRotate then iconFrame.glowRotate:Stop() end
    if iconFrame.glowPulse then iconFrame.glowPulse:Stop() end
    if iconFrame.borderGlow then
        for _, tex in ipairs(iconFrame.borderGlow) do tex:Hide() end
    end
    if iconFrame.procGlow then iconFrame.procGlow:Hide() end
    if iconFrame.procShine then iconFrame.procShine:Hide() end
    if iconFrame.procAnim then iconFrame.procAnim:Stop() end
    if iconTexture then iconTexture:SetAlpha(0.8) end
end

-- 更新复选框的高亮/光环（根据是否选中）
local function UpdateCheckboxGlow(iconFrame, iconTexture, checkbox)
    local checked = checkbox:GetChecked()
    local iconSize = iconFrame:GetWidth() or ICON_BASE_SIZE
    local pad = math.max(2, iconSize * 0.1)

    if checked then
        -- 如果选中且高亮框架未创建，则创建
        if not iconFrame.glowFrame then
            local glowFrame = CreateFrame("Frame", nil, iconFrame)
            glowFrame:SetFrameLevel(iconFrame:GetFrameLevel() + 3)
            iconFrame.glowFrame = glowFrame

            -- 四角光芒纹理
            local corners = glowFrame:CreateTexture(nil, "ARTWORK")
            corners:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
            corners:SetTexCoord(0.19, 0.81, 0.19, 0.81)
            corners:SetBlendMode("ADD")
            corners:SetVertexColor(1, 0.82, 0.15, 1)   -- 金色
            iconFrame.glowCorners = corners

            -- 旋转星辉纹理
            local spin = glowFrame:CreateTexture(nil, "OVERLAY")
            spin:SetTexture("Interface\\Cooldown\\star4")
            spin:SetBlendMode("ADD")
            spin:SetVertexColor(1, 0.78, 0.12, 0.42)
            iconFrame.glowSpin = spin

            -- 旋转动画组
            local agRot = glowFrame:CreateAnimationGroup()
            agRot:SetLooping("REPEAT")
            local rot = agRot:CreateAnimation("Rotation")
            rot:SetTarget(spin)
            rot:SetOrigin("CENTER", 0, 0)
            rot:SetDegrees(360)
            rot:SetDuration(2.6)
            iconFrame.glowRotate = agRot

            -- 呼吸脉冲动画组
            local agPulse = glowFrame:CreateAnimationGroup()
            agPulse:SetLooping("BOUNCE")
            local pulse = agPulse:CreateAnimation("Alpha")
            pulse:SetTarget(corners)
            pulse:SetFromAlpha(0.4)
            pulse:SetToAlpha(1)
            pulse:SetDuration(0.7)
            pulse:SetSmoothing("IN_OUT")
            iconFrame.glowPulse = agPulse
        end

        -- 设置高亮框架的位置和大小
        iconFrame.glowFrame:ClearAllPoints()
        iconFrame.glowFrame:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -pad, pad)
        iconFrame.glowFrame:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", pad, -pad)
        iconFrame.glowCorners:SetAllPoints(iconFrame.glowFrame)
        iconFrame.glowSpin:SetAllPoints(iconFrame.glowFrame)
        iconFrame.glowFrame:Show()

        -- 播放动画（如果未播放）
        if iconFrame.glowRotate and not iconFrame.glowRotate:IsPlaying() then
            iconFrame.glowRotate:Play()
        end
        if iconFrame.glowPulse and not iconFrame.glowPulse:IsPlaying() then
            iconFrame.glowPulse:Play()
        end
        iconTexture:SetAlpha(0.8)                 -- 勾选 alpha 0.8（ZZHELPER 勾选态 0.8 / 0.3）
        iconTexture:SetVertexColor(1, 1, 1)   -- 恢复彩色
    else
        -- 未选中：隐藏高亮光环，图标降低透明度（ZZHELPER 方案：alpha 0.3，保持彩色不置灰）
        HideIconGlow(iconFrame, iconTexture)
        iconTexture:SetVertexColor(1, 1, 1)   -- 保持彩色（ZZHELPER：仅调透明度，不置灰）
        iconTexture:SetAlpha(0.3)             -- 未勾选 alpha 0.3（ZZHELPER 勾选态 0.8 / 0.3）
    end
end

-- ============================================================
-- 图标缩放相关
-- ============================================================

-- 获取当前图标缩放比例（存储为百分比，默认100）
local function WR_GetIconScale()
    if PigSet["IconScale"] == nil then PigSet["IconScale"] = 100 end
    return PigSet["IconScale"] / 100
end

-- 根据缩放获取布局尺寸（单元格宽/高、图标大小、复选框大小）
-- 注：cellW 不在此函数内死锁，改为在 WR_ComputeGridLayout 里按 slotW 算，
--     避免"slotW >> cellW"时图标在格内居中、视觉上"1 个孤悬"的问题。
local function WR_GetLayoutMetrics()
    local scale = WR_GetIconScale()
    local iconSize = ICON_BASE_SIZE * scale
    local cbSize = CB_BASE_SIZE * scale
    local cellH = math.max(CB_CELL_H * scale, math.ceil(iconSize + CB_ICON_CB_GAP * scale + cbSize))
    return cellH, iconSize, cbSize
end

-- 计算网格布局（列数、行数、每个槽位宽度等）
-- cellW 跟 slotW 联动：让 cellW = ceil(slotW)，cellH 仍由图标+复选框决定，
-- 这样 slotW >> cellW 时 cellW 自动撑大、图标铺满格子不再"1 个孤悬居中"
local function WR_ComputeGridLayout(frameWidth, iconCount)
    local sidePad = CB_SIDE_PAD
    local scale = WR_GetIconScale()
    local iconSize = ICON_BASE_SIZE * scale
    local cbSize = CB_BASE_SIZE * scale
    local availW = math.max(iconSize, frameWidth - sidePad * 2)
    -- 最小槽宽使用缩放后的图标尺寸，并保留随缩放变化的基础间隙，
    -- 避免放大图标时 slotW < iconSize 导致图标之间无间距。
    -- ★ 2026-08-21：间距翻倍（2 → 4），图标之间的水平间距变大
    local minSlotW = iconSize + 8 * scale
    local cols = math.max(1, math.min(iconCount, math.floor(availW / minSlotW)))
    local slotW = availW / cols
    local cellH = math.max(CB_CELL_H * scale, math.ceil(iconSize + CB_ICON_CB_GAP * scale + cbSize))
    local cellW = math.max(math.ceil(CB_CELL_W * scale), math.ceil(slotW))
    local rows = math.ceil(iconCount / cols)
    return cols, cellH, cellW, slotW, sidePad, rows, iconSize, iconCount
end

-- 更新图标布局锚点（锚定在右职业区底部的图标区）
local function WR_UpdateIconLayoutAnchor(talentFrame, sidePad)
    if not WR_ConfigFrame or not WR_ConfigFrame.iconLayoutAnchor then return end
    local anchor = WR_ConfigFrame.iconLayoutAnchor
    local region = WR_ClassIconRegion or WR_ClassRegion or WR_ConfigFrame
    anchor:ClearAllPoints()
    anchor:SetPoint("TOP", region, "TOP", 0, -ICON_REGION_TOP_PAD)
    anchor:SetPoint("LEFT", region, "LEFT", sidePad, 0)
    anchor:SetPoint("RIGHT", region, "RIGHT", -sidePad, 0)
    anchor:SetHeight(1)
end

-- 应用缩放到一个图标项（更新尺寸和复选框位置）
-- ★ 2026-08-21 修复（v2）：新增 live 模式 —— 拖动中只整体 SetScale 轻量视觉缩放，
--   绝不改 SetSize / 锚点 / 触发重排，避免与每 tick 的 WR_LayoutConfigFrame 重排相互冲突导致滑块跳变。
local function WR_ApplyIconScaleToItem(item, iconSize, cbSize, live)
    if live then
        local s = WR_GetIconScale()
        item.iconFrame:SetScale(s)
        item.checkbox:SetScale(s)
        if item.labelText then item.labelText:SetScale(s) end
        return
    end
    item.iconFrame:SetSize(iconSize, iconSize)
    item.checkbox:SetSize(cbSize, cbSize)
    item.iconFrame:SetScale(1)
    item.checkbox:SetScale(1)
    if item.labelText then
        -- ★ 2026-08-21：文字随图标一起缩放（原固定 ICON_LABEL_SCALE=1.0，图标放大时文字不放大）
        item.labelText:SetScale(WR_GetIconScale())
    end
    if item.iconTexture and item.checkbox then
        item.checkbox:ClearAllPoints()
        item.checkbox:SetPoint("TOP", item.iconTexture, "BOTTOM", 0, -CB_ICON_CB_GAP * WR_GetIconScale())
        if item.checkbox:GetChecked() then
            UpdateCheckboxGlow(item.iconFrame, item.iconTexture, item.checkbox)
        end
    end
end

-- ============================================================
-- ★ 2026-11-08：把 PigSet 里的开关状态同步回面板勾选框
-- ------------------------------------------------------------
-- 背景：勾选框只在「创建时」用 SetChecked(PigSet[var]) 同步一次。
--   对于「一次性插入」类开关（指向保护 FH_ZZBH、插入光明圣印 FH_CRGMSY 等），
--   代码在施放成功后会直接写 PigSet[var] = false 自动关闭，
--   但**界面上的勾选不会跟着取消** → 玩家看到勾还在，以为没生效、
--   或者重新点一次反而又打开，表现为「无法回弹取消」。
-- 做法：遍历所有已建面板的 cbItems，按 PigSet 现状刷新 SetChecked + 光效。
-- 调用时机：一次性插入关闭后、以及面板 OnShow 时（双保险）。
-- ============================================================
function WR_SyncConfigCheckbox(saveVariable)
    if not WR_TalentFrameList then return end
    for i = 1, 4 do
        local talentFrame = WR_TalentFrameList[i]
        if talentFrame and talentFrame.cbItems then
            for _, item in ipairs(talentFrame.cbItems) do
                local var = item.config and item.config.saveVariable
                if var and (saveVariable == nil or var == saveVariable) then
                    local want = PigSet[var] and true or false
                    if item.checkbox and item.checkbox:GetChecked() ~= want then
                        item.checkbox:SetChecked(want)
                    end
                    if UpdateCheckboxGlow and item.iconFrame and item.iconTexture then
                        UpdateCheckboxGlow(item.iconFrame, item.iconTexture, item.checkbox)
                    end
                end
            end
        end
    end
end

-- 全局应用图标缩放（遍历所有天赋面板）
-- ★ 2026-08-21 修复（v2）：拖动期间（_IconScaleAdjusting=true）只做 live 视觉缩放、跳过 WR_LayoutConfigFrame。
--   这是关键：主循环 OnUpdate 每 tick 都会调 WR_RefreshConfigUI→WR_ApplyIconScale，若拖动中仍重排面板，
--   图标尺寸变化会让网格列数重算、图标位置跳变，与滑块拖动互相干扰（不稳定）。
--   松手后 _IconScaleAdjusting 清除，下一次调用走完整分支（真实 SetSize + 重排定稿）。
function WR_ApplyIconScale()
    local cellH, iconSize, cbSize = WR_GetLayoutMetrics()
    local live = PigSet["_IconScaleAdjusting"]
    if WR_TalentFrameList then
        for i = 1, 4 do
            local talentFrame = WR_TalentFrameList[i]
            if talentFrame and talentFrame.cbItems then
                for _, item in ipairs(talentFrame.cbItems) do
                    WR_ApplyIconScaleToItem(item, iconSize, cbSize, live)
                end
            end
        end
    end
    if not live then
        -- ★ 2026-08-21 修复：图标缩放定稿时标记 _IconScaleCommit，让 WR_LayoutConfigFrame
        --   突破 FrameUserSized 的"只增不减"高度/宽度锁定，使缩小图标时界面也跟随缩小。
        PigSet["_IconScaleCommit"] = true
        WR_LayoutConfigFrame()
        PigSet["_IconScaleCommit"] = nil
    end
end

-- 刷新配置界面（外部调用）
function WR_RefreshConfigUI()
    if WR_ApplyIconScale then
        WR_ApplyIconScale()
    elseif WR_LayoutConfigFrame then
        WR_LayoutConfigFrame()
    end
end

-- 布局某个天赋面板的复选框（计算行列位置）
-- doLayout=false 时只计算并返回像素高度（供外层计算面板高度），不实际摆放
function WR_LayoutTalentCheckboxes(talentFrame, frameWidth, doLayout)
    if not talentFrame or not talentFrame.cbItems or #talentFrame.cbItems == 0 then
        return 0
    end

    -- 按 section 分组：无 section 标签的归入「自动」归纳，确保所有复选框都在三大分类内
    local sectionGroups = {}
    local sectionOrder = {}
    for _, item in ipairs(talentFrame.cbItems) do
        local sec = item.config and item.config.section
        if not sec or sec == "" then sec = "自动" end
        if not sectionGroups[sec] then
            sectionGroups[sec] = {}
            table.insert(sectionOrder, sec)
        end
        table.insert(sectionGroups[sec], item)
    end

    -- 固定分组标题条顺序：自动 → 爆发 → 插入（其余未知分组按名称排其后）
    local sectionPriority = { ["自动"] = 1, ["爆发"] = 2, ["插入"] = 3 }
    table.sort(sectionOrder, function(a, b)
        local pa = sectionPriority[a] or 99
        local pb = sectionPriority[b] or 99
        if pa ~= pb then return pa < pb end
        return a < b
    end)

    local realCount = 0
    for _, sec in ipairs(sectionOrder) do
        realCount = realCount + #sectionGroups[sec]
    end
    if realCount == 0 then return 0 end

    local cols, cellH, cellW, slotW, sidePad, rows, iconSize = WR_ComputeGridLayout(frameWidth, realCount)
    local iconPadX = math.max(0, (slotW - iconSize) / 2)

    local layoutAnchor
    if doLayout then
        WR_UpdateIconLayoutAnchor(talentFrame, sidePad)
        layoutAnchor = WR_ConfigFrame and WR_ConfigFrame.iconLayoutAnchor or talentFrame
    end

    local yCursor = 0
    local col = 0

    local function placeIcon(item)
        if doLayout then
            local xOffset = slotW * col + iconPadX
            item.iconFrame:ClearAllPoints()
            item.iconFrame:SetPoint("TOPLEFT", layoutAnchor, "BOTTOMLEFT", xOffset, yCursor)
        end
        col = col + 1
        if col >= cols then col = 0; yCursor = yCursor - cellH end
    end

    local function placeHeader(sec, collapsed)
        if doLayout then
            local header = talentFrame.sectionHeaders and talentFrame.sectionHeaders[sec]
            if header then
                header:ClearAllPoints()
                header:SetPoint("TOPLEFT", layoutAnchor, "BOTTOMLEFT", 0, yCursor - SECTION_HEADER_GAP)
                header:SetPoint("TOPRIGHT", layoutAnchor, "BOTTOMRIGHT", 0, yCursor - SECTION_HEADER_GAP)
                header:SetHeight(SECTION_HEADER_H)
                if header.RefreshIndicator then header:RefreshIndicator() end
                header:Show()
            end
        end
        yCursor = yCursor - SECTION_HEADER_GAP - SECTION_HEADER_H - SECTION_HEADER_GAP
        col = 0
    end

    -- 各分类（带标题条）按顺序摆放：自动 → 爆发 → 插入；折叠的分类只显示标题，其下图标隐藏且不计入布局高度
    for _, sec in ipairs(sectionOrder) do
        if col > 0 then yCursor = yCursor - cellH; col = 0 end  -- 收尾当前行
        -- ★ 2026-08-21：取消全部折叠功能，分类始终展开显示
        local collapsed = false
        placeHeader(sec, collapsed)
        local group = sectionGroups[sec]
        if collapsed then
            -- 折叠：隐藏该分类下所有图标、复选框与文字标签，不推进布局高度（面板自动收缩）
            -- ★ 修复：复选框是 parentFrame 的独立子控件（非 iconFrame 子级），只 Hide iconFrame 会残留勾选框
            for _, item in ipairs(group) do
                if item.iconFrame then item.iconFrame:Hide() end
                if item.checkbox then item.checkbox:Hide() end
                if item.labelText then item.labelText:Hide() end
            end
        else
            table.sort(group, function(a, b)
                if a.config.row ~= b.config.row then return a.config.row < b.config.row end
                return a.config.column < b.config.column
            end)
            for _, item in ipairs(group) do
                if item.iconFrame then item.iconFrame:Show() end
                if item.checkbox then item.checkbox:Show() end
                if item.labelText then item.labelText:Show() end
                placeIcon(item)
            end
        end
    end

    -- ★ 关键：完整内容像素高度 = 从「起点 cellH 顶」到「终点 cellH 视觉底」的物理距离。
    --    -yCursor 表示从起点 cellH 顶 → 终点 cellH 顶的累加距离（cellH+section header 全在内）。
    --    还要再加：
    --      (1) 起点 cellH 顶到 anchor.bottom 的距离 = 第一个 section header 的视觉占空（10+22+10=42）
    --      (2) 终点 cellH 顶到视觉底（复选框位于图标正下方）= iconSize + 间距 + cbSize
    --    旧算法只算了 (2) 的 28-8+1=21，完全漏算 (1) 的 42，导致"插入"section 复选框整体溢出主面板外 ~140px。
    local FIRST_HEADER_BLOCK = SECTION_HEADER_GAP + SECTION_HEADER_H + SECTION_HEADER_GAP
    local cbSize = CB_BASE_SIZE * WR_GetIconScale()
    local LAST_CELL_VISUAL = iconSize + CB_ICON_CB_GAP * WR_GetIconScale() + cbSize
    return -yCursor + FIRST_HEADER_BLOCK + LAST_CELL_VISUAL
end

-- 主布局函数：调整整个配置框架的大小并重新排布图标
function WR_LayoutConfigFrame()
    if not WR_ConfigFrame then return end

    local shownFrame = nil
    local iconCount = 0
    local dmCount = 0

    -- 找到当前显示的天赋面板（只显示一个）
    if WR_TalentFrameList then
        for i = 1, 4 do
            local talentFrame = WR_TalentFrameList[i]
            if talentFrame and talentFrame:IsShown() and talentFrame.cbItems and #talentFrame.cbItems > 0 then
                shownFrame = talentFrame
                iconCount = #talentFrame.cbItems
                if talentFrame.dmCount and talentFrame.dmCount > dmCount then
                    dmCount = talentFrame.dmCount
                end
                break
            end
        end
    end

    if not shownFrame then return end

    local scale = WR_GetIconScale()
    local rightW
    local rows
    local cellW, cellH

    -- 右职业区最小宽度（至少 MIN_RIGHT_COLS 列图标，按缩放后的 CB_CELL_W 兜底）
    local minRightW = CB_SIDE_PAD * 2 + MIN_RIGHT_COLS * (CB_CELL_W * scale) + 4
    -- 主面板最小总宽度（保证左右分区不挤）
    local minFrameW = math.max(MIN_TOTAL_WIDTH, GLOBAL_OUTER_PAD + GLOBAL_REGION_W + DIV_GAP + minRightW + RIGHT_OUTER_PAD)

    -- 自动宽度：按图标数计算右职业区宽度；手动宽度：取当前右区宽度
    -- ★ 2026-08-21：图标缩放时（_IconScaleAdjusting 或 _IconScaleCommit）宽度也按内容重算（不锁定旧宽度），跟随缩放
    if PigSet["FrameUserSized"] and not PigSet["_IconScaleAdjusting"] and not PigSet["_IconScaleCommit"] then
        local totalW = math.max(minFrameW, WR_ConfigFrame:GetWidth())
        rightW = totalW - GLOBAL_OUTER_PAD - GLOBAL_REGION_W - DIV_GAP - RIGHT_OUTER_PAD
        -- 保证右区不窄于最小宽度（总宽度随之扩展）
        if rightW < minRightW then
            rightW = minRightW
            totalW = minFrameW
        end
        _, cellH, cellW, _, _, rows = WR_ComputeGridLayout(rightW, iconCount)
        WR_ConfigFrame:SetWidth(totalW)
    else
        local cols = math.min(DEFAULT_ICON_COLS, math.max(MIN_RIGHT_COLS, iconCount))
        -- ★ 修复：rightW 必须既满足 cols 视觉需求，也填满 MIN_TOTAL_WIDTH 给出的右区空间；
        --    这样下拉框（boxW=dmMaxW=rightW-78）、复选框网格、图标铺满全用上 classRegion 实际宽度。
        local colsRightW = CB_SIDE_PAD * 2 + cols * (CB_CELL_W * scale) + 4
        local frameRightW = MIN_TOTAL_WIDTH - GLOBAL_OUTER_PAD - GLOBAL_REGION_W - DIV_GAP - RIGHT_OUTER_PAD
        rightW = math.max(colsRightW, frameRightW)
        _, cellH, cellW, _, _, rows = WR_ComputeGridLayout(rightW, iconCount)
        rows = math.ceil(iconCount / cols)
    end

    -- 右区内部高度拆分：菜单区（标题+WCL模式行+职业下拉） + 图标区
    -- 底栏滑块已迁入左侧全局区，右区不再保留底栏；WCL 模式占用菜单区第一行（dmCount +1）
    -- ★ 2026-08-20 WCL 与职业下拉间距修复：职业 Frame 顶改为 -2*MENU_ROW_H（紧贴 WCL 行底 -66），
    --   菜单区内容实际占用 = 标题行(顶部-4~-26) + WCL 行(-34~-66) + 职业下拉 dmCount*32 = 66 + dmCount*32，
    --   公式同步改为 MENU_TOP_PAD + (dmCount+2)*MENU_ROW_H（=66 + dmCount*32），
    --   （旧公式 MENU_TITLE_H+(dmCount+1)*MENU_ROW_H = 54+dmCount*32，低估 12px）
    -- 先按「网格 + 分节标题」测算图标区像素高度（doLayout=false 仅测量）
    local iconPixelH = WR_LayoutTalentCheckboxes(shownFrame, rightW, false)
    -- ★ 2026-08-21：取消全部折叠功能，右区菜单区（下拉框/滑块）始终显示
    local menuRegionH = MENU_TOP_PAD + (math.max(0, dmCount) + 2) * MENU_ROW_H + MENU_BOTTOM_PAD
    local iconRegionH = math.max(ICON_REGION_MIN_H, iconPixelH + ICON_REGION_TOP_PAD + ICON_REGION_BOTTOM_PAD)
    -- 右区内容高度：始终为 settings 标题条预留 SECTION_HEADER_H
    local rightContentH = (menuRegionH + iconRegionH) + SECTION_HEADER_H

    -- 左区内容高度（标题 + 10 行控件含 2 个滑块 + 底部余量；行高已统一为 GLOBAL_ROW_H=20）
    -- 左侧内容高度（下限）：由左侧控件链实际深度决定。
    -- 实测链（globalRegion 顶向下，单位 px）：AOE标题(36)→AOE内容(展开+40)→调试模式→自动救人→倒数偷药(滑块)
    --   →爆发总闸→启用怪物屏蔽→职业屏蔽标题→近战/远程/坦克屏蔽→开关提示→图标缩放滑块→窗口透明度滑块
    --   →自动跟随复选框→跟随目标下拉（最深控件）。AOE 展开时跟随下拉底边≈658px。
    -- ★ 修复：旧值 638 低估真实链深，右区折叠后主面板高度被压到 666、左区只剩 638，
    --   导致最深的"跟随目标"下拉（焦点窗口）被挤出框外。改为 690（+32 余量）兜底，右区更高时仍以右区为准。
    --   折叠 AOE 时链上移 40px，余量更宽松，不会溢出。
    -- 左区内容高度（下限）：由左侧控件链实际深度决定
    -- ★ 2026-08-21：左区「全局」整体折叠时，左区只剩标题条，高度收缩到仅容纳标题条
    -- ★ 2026-08-21 修复复选框溢出：实测左区控件链（全局标题→智能AOE展开→调试模式→自动救人→
    --   倒数偷药→爆发总闸→怪物/职业屏蔽→开关提示→图标缩放→窗口透明度→自动跟随→跟随目标下拉）
    --   真实深度≈706px（每行控件约 40px：控件 20 + 行距 20）。旧值 690 余量不足，导致右区较矮的专精下
    --   最深的「跟随目标」下拉框及上方复选框被挤出主面板底边。旧值 800 导致底部留大段空白，
    --   2026-08-21 改为 740（余量 34px），在防溢出与减空白之间平衡。
    local leftContentH = 740
    local frameHeight = TOP_BAR_H + math.max(leftContentH, rightContentH)
    -- 限制最大默认高度，防止超高职业撑爆屏幕
    if not PigSet["FrameUserSized"] then
        if frameHeight > MAX_FRAME_HEIGHT then
            frameHeight = MAX_FRAME_HEIGHT
            -- 超过屏幕时：优先保证图标区可见，菜单区按需压缩（80% 留图标，20% 留菜单；原 45% 太激进导致"插入"section 溢出）
            local maxRightContentH = MAX_FRAME_HEIGHT - TOP_BAR_H
            local availableForMenuIcon = math.max(MENU_TITLE_H + ICON_REGION_MIN_H, maxRightContentH)
            iconRegionH = math.max(ICON_REGION_MIN_H, math.min(iconRegionH, availableForMenuIcon * 0.80))
            menuRegionH = availableForMenuIcon - iconRegionH
            rightContentH = menuRegionH + iconRegionH
        end
    end

    -- 总宽度 = 左区 + 分隔 + 右区 + 两侧边距
    local frameWidth = math.max(minFrameW, GLOBAL_OUTER_PAD + GLOBAL_REGION_W + DIV_GAP + rightW + RIGHT_OUTER_PAD)
    FrameWide = frameWidth
    PigSet["FrameWide"] = frameWidth

    if PigSet["FrameUserSized"] and not PigSet["_IconScaleCommit"] then
        -- ★ 2026-08-21：用户手动拖拽改过窗口尺寸时，默认"只增不减"锁定高度，
        --   防止切换专精（图标变少）时把用户拉大的窗口自动压回去。
        --   但图标缩放定稿（_IconScaleCommit=true）属于用户主动的尺寸变化，应突破锁定、自由跟随缩小/放大。
        local fh = math.max(frameHeight, WR_ConfigFrame:GetHeight())
        PigSet["FrameHigh"] = fh
        WR_ConfigFrame:SetHeight(fh)
    else
        -- 自动尺寸 / 图标缩放定稿：无条件按内容尺寸（frameWidth×frameHeight）设置，缩小时界面跟随缩小
        PigSet["FrameHigh"] = frameHeight
        WR_ConfigFrame:SetSize(frameWidth, frameHeight)
    end

    -- ★ 2026-08-21：取消全部折叠功能，右区菜单区（下拉框/滑块）始终显示
    -- ★ 2026-08-21 修复：图标区由「贴右框架底边」改为「紧贴菜单区下方」，
    --   避免右框架高度被左区撑高时，整块「自动/爆发/插入」复选框被甩到右框架最底沿（中间留大段空档、像脱离框架/被底边切掉）。
    --   空档统一留到右框架底部，复选框紧跟下拉框，定位更直观也远离屏幕底边。
    if WR_ClassMenuRegion then WR_ClassMenuRegion:Show() end
    if WR_ClassIconRegion then
        WR_ClassIconRegion:ClearAllPoints()
        WR_ClassIconRegion:SetPoint("TOPLEFT", WR_ClassMenuRegion, "BOTTOMLEFT", 0, 0)
        WR_ClassIconRegion:SetPoint("TOPRIGHT", WR_ClassMenuRegion, "BOTTOMRIGHT", 0, 0)
        WR_ClassIconRegion:SetHeight(iconRegionH)
    end
    if WR_ClassMenuRegion then
        WR_ClassMenuRegion:SetHeight(menuRegionH)
    end

    -- 右区下拉框宽度自适应：标签固定宽度 + 两侧边距，保证与阈值条右边缘对齐
    local dmMaxW = math.max(80, rightW - MENU_LABEL_W - GLOBAL_INNER_PAD * 3)
    if shownFrame and shownFrame.dmDropdowns then
        for _, dropdown in pairs(shownFrame.dmDropdowns) do
            if dropdown and dropdown.SetDisplayWidth then
                dropdown.SetDisplayWidth(dmMaxW)
            end
        end
    end

    WR_LayoutTalentCheckboxes(shownFrame, rightW, true)

    if shownFrame.dmList then
        WR_SetActiveDropdowns(shownFrame)
    end
end

-- ============================================================
-- 创建下拉菜单
-- 输入：config表格（包含 text, row, saveVariable, menuItems, defaultID等）
-- 返回：textFrame（标签）、dropdown（下拉菜单对象）
-- ============================================================
local function CreateDropdownMenu(config)
    local row = config.row or 1
    local yOffset = -MENU_TOP_PAD - MENU_ROW_H * (row - 1)
    local boxW = config.width or MENU_DROPDOWN_W

    -- 创建标签文字（使用 STANDARD_TEXT_FONT 避免模板自带阴影导致重影）
    local textFrame = config.parentFrame:CreateFontString(nil, "ARTWORK")
    textFrame:SetFont(STANDARD_TEXT_FONT, 14, "")
    textFrame:SetTextColor(classColor.r, classColor.g, classColor.b)
    textFrame:SetText(config.text)

    -- 创建下拉菜单对象
    local dropdown = CreateFrame("Frame", config.dropdownName, config.parentFrame, "UIDropDownMenuTemplate")

    -- ★ 2026-08-21：取消下拉框外框边缘，改用扁平背景+简洁箭头，并对齐标签
    if type(WR_StyleDropdownFlat) == "function" then
        WR_StyleDropdownFlat(dropdown)
    end

    -- 根据对齐方式放置标签和下拉框
    if config.align == "left" then
        -- 左对齐：标签固定宽度左对齐，下拉框左接标签、右对齐父框右侧
        local labelX = config.x or GLOBAL_INNER_PAD
        textFrame:SetPoint("TOPLEFT", config.parentFrame, "TOPLEFT", labelX, yOffset)
        -- 用 SetSize 锁死标签尺寸，避免 FontString 因文本长度自动伸缩导致跨行控件左缘错位
        textFrame:SetSize(MENU_LABEL_W, 16)
        textFrame:SetJustifyH("LEFT")
        -- 下拉框左边缘接标签右边缘；标签高16、下拉框高 WR_DROPDOWN_H(16)，两者等高，
        -- 顶边同高即中心对齐，故 y 偏移为 0（不再用旧的 +5，否则框会偏上）
        dropdown:SetPoint("TOPLEFT", textFrame, "TOPRIGHT", 4, 0)
        dropdown:SetPoint("TOPRIGHT", config.parentFrame, "TOPRIGHT", -labelX, yOffset)
    else
        -- 默认右对齐：标签在父框右侧，下拉框向左展开（兼容 1x1 锚点）
        textFrame:SetPoint("TOPRIGHT", config.parentFrame, "TOPRIGHT", 0, yOffset)
        dropdown:SetPoint("RIGHT", textFrame, "LEFT", -10, -2)
    end

    dropdown.config = config
    dropdown.menuItems = config.menuItems
    ResizeDropdownBox(dropdown, boxW)

    -- 覆盖一个透明按钮来捕获点击（因为原生下拉菜单的点击区域可能太小）
    local overlayBtn = CreateFrame("Button", nil, dropdown)
    -- ★ 2026-08-21：外框已取消，点击区直接占满整个下拉框，无需再避让边框
    overlayBtn:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, 0)
    overlayBtn:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", 0, 0)
    local btn = _G[dropdown:GetName() .. "Button"]
    overlayBtn:SetScript("OnClick", function()
        -- 先关闭其他已打开的下拉，避免同时展开多个菜单
        CloseDropDownMenus()
        if btn then btn:Click() end
    end)

    -- 下拉菜单打开时由 UIDropDownMenu 调用的初始化函数
    -- 注意：只在菜单实际展开时执行，创建阶段不调用，避免污染全局 DropDownList
    local function InitializeDropdown(self, level)
        level = level or 1
        local currentDefaultID = config.defaultID or 1
        if currentDefaultID < 1 then currentDefaultID = 1 end
        -- ★ 2026-08-21 防御：menuItems 缺失（如误把复选框/占位项放进 DM）时跳过，避免 ipairs(nil) 崩溃
        if not (dropdown.menuItems and type(dropdown.menuItems) == "table" and #dropdown.menuItems > 0) then
            return
        end
        for i, item in ipairs(dropdown.menuItems) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.checked = ((PigSet[config.saveVariable] or currentDefaultID) == i)
            info.minWidth = (config.width or MENU_DROPDOWN_W)
            info.font = "GameFontNormal"
            info.fontSize = 16
            info.func = function()
                UIDropDownMenu_SetSelectedID(dropdown, i)
                ApplyDropdownDisplayText(dropdown, item.text, boxW)
                if config.saveVariable then
                    PigSet[config.saveVariable] = i
                    PrintToVisible(string.format("|cff00ff00%s|r 已设置为：|cffffd700%s|r", config.text, item.text))
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    -- 仅注册初始化函数，不立即执行 UIDropDownMenu_Initialize，防止创建时向当前打开的下拉列表追加按钮
    dropdown.initialize = InitializeDropdown
    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")

    -- 设置下拉菜单的弹出位置（锚定在下拉框自身左下角）
    -- 菜单从下拉框底部中央向下弹出（水平居中，避免偏出窗口右侧，与焦点下拉框体验一致）
    dropdown.point = "TOP"
    dropdown.relativeTo = dropdown
    dropdown.relativePoint = "BOTTOM"
    dropdown.xOffset = 0
    dropdown.yOffset = 0

    -- 覆盖按钮的高亮和提示
    overlayBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    overlayBtn:SetScript("OnEnter", function(self)
        textFrame:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(config.tooltipText .. "\n宏/" .. config.saveVariable .. " 这个是切换宏\n宏/" .. config.saveVariable .. "空格+数字，可以调到你填的数字那项")
        GameTooltip:Show()
    end)
    overlayBtn:SetScript("OnLeave", function(self)
        textFrame:SetTextColor(classColor.r, classColor.g, classColor.b)
        GameTooltip:Hide()
    end)

    -- 刷新显示文本与选中状态（不展开下拉列表）
    local function RefreshDisplay()
        -- ★ 2026-08-22 防御：menuItems 缺失（如误把开关项当作下拉框、或未配置菜单项）时跳过刷新，避免 #config.menuItems / config.menuItems[id] 对 nil 取长度/索引崩溃
        if not (config.menuItems and type(config.menuItems) == "table" and #config.menuItems > 0) then
            if config.saveVariable then
                PrintToVisible(string.format("|cffff0000警告|r: 下拉项 [%s] 缺少 menuItems 配置，已跳过显示刷新（请检查该项的菜单配置）", config.saveVariable))
            end
            return
        end
        local defaultID = config.defaultID or 1
        if defaultID < 1 then defaultID = 1 end
        if PigSet[config.saveVariable] == nil or type(PigSet[config.saveVariable]) ~= "number" or PigSet[config.saveVariable] < 1 or PigSet[config.saveVariable] > #config.menuItems then
            PigSet[config.saveVariable] = defaultID
        end
        local selectedID = PigSet[config.saveVariable]
        UIDropDownMenu_SetSelectedID(dropdown, selectedID)
        local menuItem = config.menuItems[selectedID]
        local displayText = menuItem and menuItem.text or ""
        ApplyDropdownDisplayText(dropdown, displayText, boxW)
    end
    RefreshDisplay()

    -- 注册斜杠命令：/saveVariable 或 /saveVariable 数字
    if config.saveVariable then
        local function SetDropdownSelection(selection)
            local id = tonumber(selection)
            if id == nil then
                id = PigSet[config.saveVariable] + 1
                if id > #config.menuItems then id = 1 end
            end
            if id and id >= 1 and id <= #config.menuItems then
                UIDropDownMenu_SetSelectedID(dropdown, id)
                ApplyDropdownDisplayText(dropdown, config.menuItems[id].text, boxW)
                if config.saveVariable then
                    PigSet[config.saveVariable] = id
                end
                PrintToVisible(string.format("|cff00ff00%s|r 已设置为：|cffffd700%s|r", config.text, config.menuItems[id].text))
            else
                PrintToVisible(string.format("|cffff0000错误|r: 无效选项 ID (1-%d)", #config.menuItems))
            end
        end
        _G["SLASH_" .. config.saveVariable .. "1"] = "/" .. config.saveVariable
        SlashCmdList[config.saveVariable] = function(msg) SetDropdownSelection(msg) end
    end

    -- 外部接口：更新菜单项
    function dropdown.UpdateMenuItems(newItems)
        dropdown.menuItems = newItems
        RefreshDisplay()
    end

    -- 外部接口：更新单个菜单项的文字
    function dropdown.UpdateMenuItem(index, newText)
        if not dropdown.menuItems then return end
        if index >= 1 and index <= #dropdown.menuItems then
            dropdown.menuItems[index].text = newText
            RefreshDisplay()
        end
    end

    -- 外部接口：设置显示宽度
    function dropdown.SetDisplayWidth(w)
        config.width = w
        dropdown.config.width = w
        boxW = w
        RefreshDisplay()
        local selectedID = PigSet[config.saveVariable] or config.defaultID
        if dropdown.menuItems[selectedID] then
            ApplyDropdownDisplayText(dropdown, dropdown.menuItems[selectedID].text, w)
        end
    end

    return textFrame, dropdown
end

-- ============================================================
-- ★ 2026-08-26：图标可拖到动作条 —— 切换宏生成器（PigToGo 同款能力移植）
-- 在 CreateCheckbox 的 iconFrame 上注册拖拽入口，调用本函数生成
--   #showtooltip <技能名或FileID>
--   /<saveVariable>
-- 形式的开关宏，并 PickupMacro 挂到光标上。战斗中拒绝拖出。
-- 设计要点：
--   1) 优先使用 config.showSpell（真实技能中文名，最稳）；nil 时回退到 IconID
--      作为 #showtooltip 参数（FileID 也可工作，能正确显示冷却）
--   2) SPELL_ALIAS 简称映射（手套/饰品/药水类）+ GetInventoryItemLink 兜底
--   3) FindMacroByCommand 复用同名开关宏，避免每次拖动占一个新宏位
--   4) MakeUniqueMacroName 重名自动加 2/3...；超 16 字截断（WoW 宏名硬约束）
--   5) 战斗中拒绝拖出（InCombatLockdown 红字提示）
-- ============================================================
local function WR_PickupToggleMacro(config, iconFrame)
    if not config or not config.saveVariable then return false end
    if InCombatLockdown and InCombatLockdown() then
        WR_PrintToVisible("|cffff0000战斗中无法拖出宏|r")
        return false
    end

    -- 绕过可能被其他插件/库 patch 的 string.sub：按字节安全取子串
    local function SafeSub(s, startPos, endPos)
        s = tostring(s or "")
        local len = #s
        if len == 0 then return "" end
        startPos = startPos or 1
        endPos = endPos or len
        if startPos < 1 then startPos = 1 end
        if endPos > len then endPos = len end
        if startPos > endPos then return "" end
        local bytes = {}
        for i = startPos, endPos do
            bytes[#bytes + 1] = string.char(string.byte(s, i))
        end
        return table.concat(bytes)
    end

    -- 按完整 UTF-8 字符截断（返回前 maxChars 个完整字符的字节），避免截出损坏尾字节
    local function SafeSubUtf8(s, maxChars)
        s = tostring(s or "")
        if maxChars <= 0 or s == "" then return "" end
        local n = 0
        local endPos = 0
        local i = 1
        local len = #s
        while i <= len and n < maxChars do
            local b = string.byte(s, i)
            local charLen = 1
            if b >= 0xF0 then
                charLen = 4
            elseif b >= 0xE0 then
                charLen = 3
            elseif b >= 0xC0 then
                charLen = 2
            end
            n = n + 1
            endPos = i + charLen - 1
            i = i + charLen
        end
        if endPos > len then endPos = len end
        return SafeSub(s, 1, endPos)
    end

    -- 去除宏名/字符串中的 WoW 颜色转义与图标 inline（|cffRRGGBB、|r、|T...|t）
    local function StripMacroName(s)
        s = tostring(s or "")
        s = s:gsub("|c%x%x%x%x%x%x%x%x", "")
        s = s:gsub("|r", "")
        s = s:gsub("|T.-|t", "")
        return s
    end
    local function TrimMacroBody(s)
        s = tostring(s or "")
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        return s
    end

    -- 简称 → 真实技能/物品名映射（PigToGo 同款精简版）
    local SPELL_ALIAS = {
        ["手套"]       = "工程手套",
        ["工程手套"]   = "工程手套",
        ["饰品"]       = "饰品",
        ["种族"]       = "种族",
        ["速度药水"]   = "速度药水",
        ["狂野魔法"]   = "狂野魔法药水",
        ["不灭"]       = "不灭药水",
        ["不灭药水"]   = "不灭药水",
        ["法力宝石"]   = "法力宝石",
        ["法力红宝石"] = "法力红宝石",
        ["冰箱"]       = "寒冰屏障",
        ["冰箱术"]     = "寒冰屏障",
        ["闪现"]       = "闪现术",
        ["燃烧"]       = "燃烧",
        ["素质5连"]    = "炎爆术",
        ["渊"]         = "暗影恶魔",
    }

    local function IsValidTipTarget(name)
        if not name or name == "" then return false end
        if GetSpellInfo and GetSpellInfo(name) then return true end
        if GetItemInfo and GetItemInfo(name) then return true end
        return false
    end

    local function NormalizeTipName(raw)
        local name = tostring(raw or ""):gsub("%s+", "")
        if name == "" or name == "种族" or name == "布鲁塔卢斯" or name == "燃烧" or name == "素质5连" then
            return nil
        end
        if SPELL_ALIAS[name] then name = SPELL_ALIAS[name] end
        -- 手套：从 InventorySlot 10 解析真实手套物品
        if name == "工程手套" or name == "手套" then
            local link = GetInventoryItemLink and GetInventoryItemLink("player", 10)
            return link and link:match("%[(.-)%]") or nil
        end
        -- 饰品：优先槽 13（上位饰品），回退槽 14
        if name == "饰品" then
            for _, slot in ipairs({ 13, 14 }) do
                local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
                local itemName = link and link:match("%[(.-)%]")
                if itemName then return itemName end
            end
            return nil
        end
        if IsValidTipTarget(name) then return name end
        if not name:find("药水", 1, true) then
            local potion = name .. "药水"
            if IsValidTipTarget(potion) then return potion end
        end
        return nil
    end

    -- 从 tooltipText 推导真实技能/物品名（着色段优先；否则取"插入/使用 X"纯文本）
    -- 这样全职业所有插入类开关（_CR / CR<技能> / section=插入）无需逐条补 showSpell 也能正确显示冷却
    -- 信任配置写死的名称：优先 NormalizeTipName（别名/手套/饰品特例），
    -- GetSpellInfo 校验失败时不再回退 IconID，直接用配置里的名字作为 #showtooltip 名
    local function TrustTipName(raw)
        local n = NormalizeTipName(raw)
        if n then return n end
        local name = tostring(raw or ""):gsub("%s+", "")
        if name == "" or name == "种族" or name == "燃烧" or name == "素质5连" or name == "布鲁塔卢斯" then
            return nil
        end
        if SPELL_ALIAS[name] then name = SPELL_ALIAS[name] end
        return name
    end

    local function ExtractTipSpellName(rawTip)
        local tip = tostring(rawTip or "")
        -- 1) 着色段优先（tooltip 中的 |cff00adf0真实名|r）
        local colored = tip:match("|c%x%x%x%x%x%x%x%x(.-)|r")
        if colored and colored ~= "" then
            return TrustTipName(colored)
        end
        -- 2) 纯文本：去掉颜色代码，取首行，按字面前缀"插入/使用/自动使用"截取名字
        local plain = tip:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
        plain = plain:match("^[^\r\n]+") or plain
        local prefixes = {"插入", "使用", "自动使用"}
        local name
        for _, p in ipairs(prefixes) do
            local pos = plain:find(p, 1, true)
            if pos then
                -- 用 SafeSub 绕过 string.sub 可能被 patch 的问题
                name = SafeSub(plain, pos + #p)
                break
            end
        end
        if not name then name = plain end
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        name = name:gsub("%[.+%]", "")
        -- 全角括号：用完整 UTF-8 字面量当边界，避免拆字节误伤中文
        name = name:gsub("（.-）", "")
        -- 只清理 ASCII 标点后续，避免全角标点 UTF-8 字节误伤中文字符
        name = name:gsub("[,%.;:%|/].*$", "")
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then return nil end
        return TrustTipName(name)
    end

    -- 解析 #showtooltip 用的真实技能/物品名（FileID 也可作为参数）
    local function ResolveShowTooltipName()
        -- 1) 显式 showSpell 优先（真实中文技能/物品名，最稳）
        if type(config.showSpell) == "string" and config.showSpell ~= "" then
            local n = NormalizeTipName(config.showSpell)
            if n then return n end
        end
        -- 2) 从 tooltipText 自动推导（覆盖所有未显式标注的插入类开关）
        local derived = ExtractTipSpellName(config.tooltipText)
        if derived then return derived end
        -- 3) 回退 IconID（FileID，至少图标正确；无着色/无合法技能名时的兜底）
        if type(config.IconID) == "number" or (type(config.IconID) == "string" and config.IconID ~= "") then
            return config.IconID
        end
        return nil
    end

    -- 解析宏名（中文技能名优先；失败回退到 stripped text）
    local function ResolveMacroDisplayName()
        -- 1) 显式 showSpell（经 NormalizeTipName，手套/饰品拿到真实物品名）
        if type(config.showSpell) == "string" and config.showSpell ~= "" then
            local n = NormalizeTipName(config.showSpell)
            if n then return n end
        end
        -- 2) 从 tooltip 推导（着色段/纯文本，含手套/饰品/药水/种族特例）
        local derived = ExtractTipSpellName(config.tooltipText)
        if derived then return derived end
        -- 3) 旧逻辑兜底（处理无合法技能名的奇例）
        local tip = tostring(config.tooltipText or "")
        local candidates = {}
        for colored in tip:gmatch("|c%x%x%x%x%x%x%x%x(.-)|r") do
            local n = tostring(colored):gsub("%s+", "")
            if n ~= "" and n ~= "种族" and n ~= "燃烧" and n ~= "素质5连" then
                candidates[#candidates + 1] = n
            end
        end
        for i = #candidates, 1, -1 do
            local n = candidates[i]
            if SPELL_ALIAS[n] then n = SPELL_ALIAS[n] end
            if n ~= "" then return n end
        end
        local plain = tip:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
        plain = plain:match("^[^\r\n]+") or plain
        plain = plain:gsub("^%s+", ""):gsub("%s+$", "")
        local after = plain:match("插入%s*(.+)$") or plain:match("使用%s*(.+)$") or plain:match("自动使用%s*(.+)$")
        if after then
            after = after:gsub("^自动", "")
            after = after:gsub("[（(].*$", "")
            after = after:gsub("[，,。．%.；;：:、|/].*$", "")
            after = after:gsub("%s+", "")
            if SPELL_ALIAS[after] then after = SPELL_ALIAS[after] end
            if after ~= "" and after ~= "种族" then return after end
        end
        local label = StripMacroName(config.text)
        if label ~= "" and label ~= "插入" and label ~= "自动" and label ~= "使用" then
            return label
        end
        return nil
    end

    -- 查找已存在的同 body / 同 cmd 宏（用于复用而不是新建）
    local function FindMacroByCommand(cmd, exactBody)
        if not GetMacroInfo then return 0 end
        local maxMacros = (MAX_ACCOUNT_MACROS or 120) + (MAX_CHARACTER_MACROS or 18)
        local cmdEsc = cmd:gsub("(%W)", "%%%1")
        for i = 1, maxMacros do
            local name, _, macroBody = GetMacroInfo(i)
            if name and macroBody then
                if TrimMacroBody(macroBody) == exactBody then return i, name end
                for line in tostring(macroBody):gmatch("[^\r\n]+") do
                    local t = TrimMacroBody(line)
                    if t == cmd or t:match("^" .. cmdEsc .. "%s") then return i, name end
                end
            end
        end
        return 0
    end

    -- 唯一化宏名（同名加 2/3/4...；超 16 字节截断；WoW 宏名硬约束）
    local function MakeUniqueMacroName(baseName, body)
        local name = baseName
        if name == "" or not name then name = config.saveVariable or "开关" end
        -- 截断到最多 16 字节；中文按完整 UTF-8 字符截断，避免截出损坏尾字节
        if #name > 16 then
            name = SafeSubUtf8(name, 5)
        end
        local exist = GetMacroIndexByName and GetMacroIndexByName(name) or 0
        if exist == 0 then return name end
        local _, _, existBody = GetMacroInfo(exist)
        local cmd = "/" .. tostring(config.saveVariable)
        if TrimMacroBody(existBody) == body then return name end
        if existBody and tostring(existBody):find(cmd, 1, true) then return name end
        for i = 2, 99 do
            local suffix = tostring(i)
            local candidate = SafeSubUtf8(baseName, math.max(1, 5 - #suffix)) .. suffix
            exist = GetMacroIndexByName and GetMacroIndexByName(candidate) or 0
            if exist == 0 then return candidate end
            _, _, existBody = GetMacroInfo(exist)
            if TrimMacroBody(existBody) == body then return candidate end
            if existBody and tostring(existBody):find(cmd, 1, true) then return candidate end
        end
        return "插入技"
    end

    -- 解析宏图标（优先 IconID；失败回退到问号图标）
    local function ResolveMacroIcon()
        local id = config.IconID
        if type(id) == "number" or (type(id) == "string" and id ~= "") then return id end
        return "INV_MISC_QUESTIONMARK"
    end

    local cmd = "/" .. config.saveVariable
    local tipName = ResolveShowTooltipName()
    -- ★ 2026-08-31：组合宏 —— 当开关图标能推导出真实可施放技能/物品名时，
    --   拖出宏在切换命令前追加 /cast 行，使一个动作条按键「既施放又切开关」。
    --   仅对"插入型/施放型"开关生效（tipName 为真实技能名且非纯数字），
    --   无对应技能的开关（AOE 总开关、自动跟随等回退到 FileID 的）维持纯切换宏。
    local castLine = ""
    if type(tipName) == "string" and tipName ~= "" and not tipName:match("^%d+$") and IsValidTipTarget(tipName) then
        castLine = "/cast " .. tipName .. "\n"
    end
    local body = cmd
    if tipName and tipName ~= "" then
        body = "#showtooltip " .. tostring(tipName) .. "\n" .. castLine .. cmd
    end
    local icon = ResolveMacroIcon()
    -- 宏名优先用 tipName；当 tipName 是数字/含图标 inline 时回退到中文技能名解析；最后兜底 saveVariable（保证非空 ASCII）
    local baseName
    if type(tipName) == "string" and tipName ~= "" and not tipName:find("^%d+$") then
        baseName = tipName
    else
        baseName = ResolveMacroDisplayName()
    end
    if not baseName or baseName == "" or baseName == "插入" or baseName == "自动" or baseName == "使用" then
        baseName = ResolveMacroDisplayName() or StripMacroName(config.text) or config.saveVariable or "开关"
    end
    local idx = FindMacroByCommand(cmd, body)
    local macroName
    local ok, result
    if idx and idx > 0 then
        macroName = MakeUniqueMacroName(baseName, body)
        ok = pcall(EditMacro, idx, macroName, icon, body)
        if not ok then ok = pcall(EditMacro, idx, macroName, "INV_MISC_QUESTIONMARK", body) end
    else
        macroName = MakeUniqueMacroName(baseName, body)
        ok, result = pcall(CreateMacro, macroName, icon, body, 1)
        if not ok or not result or result == 0 then
            ok, result = pcall(CreateMacro, macroName, "INV_MISC_QUESTIONMARK", body, 1)
        end
        if type(result) == "number" and result > 0 then
            idx = result
        else
            idx = FindMacroByCommand(cmd, body)
        end
    end

    if idx and idx > 0 and PickupMacro then
        PickupMacro(idx)
        return true
    end
    WR_PrintToVisible("|cffff0000创建宏失败（宏可能已满）|r")
    return false
end

-- ============================================================
-- 创建复选框（图标+勾选框）
-- 输入：config表格（包含 IconID, text, saveVariable, defaultState, tooltipText, showSpell）
-- 返回：iconFrame（图标按钮）、checkbox（复选框）、iconTexture（图标纹理）、text（标签文字）
-- ★ 2026-08-26：showSpell（可选）指定拖出宏的 #showtooltip 技能名；nil 时回退 IconID 兜底
-- ============================================================
local function CreateCheckbox(config)
    local iconFrame = CreateFrame("Button", nil, config.parentFrame)
    iconFrame:SetSize(ICON_BASE_SIZE, ICON_BASE_SIZE)
    iconFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- 图标纹理（ZZHELPER：alpha 0.8）
    local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(iconFrame)
    iconTexture:SetAlpha(0.8)
    iconTexture:SetTexture(config.IconID)

    -- ★ 2026-08-21：ZZHELPER 风格外框 UI-Quickslot2（职业色，OVERLAY，四边内收 1px）
    local iconBorder = iconFrame:CreateTexture(nil, "OVERLAY")
    iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    iconBorder:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -1, 1)
    iconBorder:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 1, -1)
    iconBorder:SetTexCoord(0.2, 0.8, 0.2, 0.8)
    iconBorder:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
    iconFrame.iconBorder = iconBorder

    -- 图标上的文字标签（先 SetFont 再 SetText，必须显式关阴影，否则出现重影）
    -- ★ 2026-08-21：对齐 ZZHELPER —— GameFontNormalSmall 字体 + OUTLINE + 职业色 + CENTER
    local text = iconFrame:CreateFontString(nil, "OVERLAY")
    local smallFontPath = GameFontNormalSmall and GameFontNormalSmall:GetFont() or STANDARD_TEXT_FONT
    text:SetFont(smallFontPath, 12 * (1 / ICON_LABEL_SCALE), "OUTLINE")
    text:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
    text:SetShadowOffset(0, 0)
    text:SetShadowColor(0, 0, 0, 0)
    text:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
    text:SetText(config.text or "")
    -- ★ 2026-08-21：文字初始缩放跟随当前图标缩放（原固定 ICON_LABEL_SCALE=1.0）
    text:SetScale(WR_GetIconScale())

    -- 创建复选框（置于图标正下方、水平居中，与图标形成上下视觉关联，单独占一格）
    local checkbox = CreateFrame("CheckButton", config.checkboxName, config.parentFrame, "UICheckButtonTemplate")
    checkbox:SetSize(CB_BASE_SIZE, CB_BASE_SIZE)
    -- 复选框放置在图标正下方（水平居中对齐），形成明确的"图标在上、勾选框在下"视觉关联
    -- 乘以当前图标缩放，使复选框与图标的相对间距随缩放保持一致。
    checkbox:SetPoint("TOP", iconTexture, "BOTTOM", 0, -CB_ICON_CB_GAP * WR_GetIconScale())
    checkbox:SetAlpha(0.95)

    -- 从PigSet读取状态，若不存在则使用默认值
    if PigSet[config.saveVariable] == nil then
        PigSet[config.saveVariable] = config.defaultState
    end
    checkbox:SetChecked(PigSet[config.saveVariable])
    UpdateCheckboxGlow(iconFrame, iconTexture, checkbox)
    iconFrame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    -- 显示提示信息
    local function ShowTooltip(self)
        iconTexture:SetAlpha(1)
        checkbox:SetAlpha(1)
        iconFrame:LockHighlight()
        if config.tooltipText then
            GameTooltip:SetOwner(self, config.tooltipAnchor or "ANCHOR_RIGHT")
            GameTooltip:SetText(config.tooltipText ..
                "\n宏/" .. config.saveVariable .. "切换开和关" ..
                "\n宏/" .. config.saveVariable .. "空格on 打开开关" ..
                "\n宏/" .. config.saveVariable .. "空格off 关闭开关" ..
                "\n|cff00adf0按住图标拖到动作条可生成切换宏（带技能冷却）|r")
            GameTooltip:Show()
        end
    end

    local function HideTooltip(self)
        UpdateCheckboxGlow(iconFrame, iconTexture, checkbox)
        checkbox:SetAlpha(0.8)
        iconFrame:UnlockHighlight()
        GameTooltip:Hide()
    end

    checkbox:SetScript("OnEnter", ShowTooltip)
    checkbox:SetScript("OnLeave", HideTooltip)
    iconFrame:SetScript("OnEnter", ShowTooltip)
    iconFrame:SetScript("OnLeave", HideTooltip)

    -- 点击切换函数（PrintToVisible 为文件级函数，见文件顶部）
    -- ★ 2026-08-26：draggedMacro 防误触 —— 拖拽成功后本次 OnMouseUp 不再切状态
    local draggedMacro = false
    local function OnToggleClick(self, button)
        if draggedMacro then
            draggedMacro = false
            return
        end
        local newState = not PigSet[config.saveVariable]
        PigSet[config.saveVariable] = newState
        checkbox:SetChecked(newState)
        UpdateCheckboxGlow(iconFrame, iconTexture, checkbox)
        local statusText = newState and "|cff00ff00开启|r" or "|cffff0000关闭|r"
        PrintToVisible(string.format(statusText .. " [%s]", config.tooltipText or config.checkboxName))
    end

    checkbox:RegisterForClicks("AnyUp")
    checkbox:SetScript("OnClick", OnToggleClick)
    checkbox:SetScript("OnMouseUp", nil)
    iconFrame:SetScript("OnClick", OnToggleClick)
    iconFrame:SetScript("OnMouseUp", nil)

    -- ★ 2026-08-26：图标可拖到动作条（PigToGo 同款）—— 调用 WR_PickupToggleMacro
    -- 创建/复用 #showtooltip 宏并 PickupMacro 挂到光标；战斗中函数内拦截并红字提示
    if config.saveVariable then
        iconFrame:RegisterForDrag("LeftButton")
        iconFrame:SetScript("OnDragStart", function()
            draggedMacro = WR_PickupToggleMacro(config, iconFrame)
            if GameTooltip then GameTooltip:Hide() end
        end)
    end

    -- 注册斜杠命令：/saveVariable [on/off/toggle]
    if config.saveVariable then
        local function HandleCommand(msg)
            msg = strlower(msg or "")
            if msg == "on" then
                PigSet[config.saveVariable] = true
                checkbox:SetChecked(true)
                UpdateCheckboxGlow(iconFrame, iconTexture, checkbox)
                PrintToVisible(string.format("|cff00ff00已启用 [%s]|r", config.tooltipText or config.checkboxName))
            elseif msg == "off" then
                PigSet[config.saveVariable] = false
                checkbox:SetChecked(false)
                UpdateCheckboxGlow(iconFrame, iconTexture, checkbox)
                PrintToVisible(string.format("|cffff0000已关闭 [%s]|r", config.tooltipText or config.checkboxName))
            elseif msg == "" or msg == "toggle" then
                local newState = not PigSet[config.saveVariable]
                PigSet[config.saveVariable] = newState
                checkbox:SetChecked(newState)
                UpdateCheckboxGlow(iconFrame, iconTexture, checkbox)
                local statusText = newState and "|cff00ff00开启|r" or "|cffff0000关闭|r"
                PrintToVisible(string.format(statusText .. " [%s]", config.tooltipText or config.checkboxName))
            end
        end
        _G["SLASH_" .. config.saveVariable .. "1"] = "/" .. config.saveVariable
        SlashCmdList[config.saveVariable] = HandleCommand
    end

    return iconFrame, checkbox, iconTexture, text
end

-- ============================================================
-- 创建分类标题条（如「爆发」）
-- 横跨图标区宽度，把同类开关归到一组，方便查找
-- ============================================================
local function CreateSectionHeader(parentFrame, text, collapseKey)
    -- 可点击折叠的分类标题条；collapseKey 为 PigSet 持久化键（nil 表示静态标题，不可折叠）
    -- ★ 2026-08-21：对齐 ZZHELPER —— 金色标题(1,0.82,0) + 1px 灰色分隔线(0.35)，无半透明金底
    local f = CreateFrame("Frame", nil, parentFrame)
    f:SetSize(10, SECTION_HEADER_H)
    if collapseKey then f:EnableMouse(true) end
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", f, "LEFT", 6, 0)
    title:SetFont(STANDARD_TEXT_FONT, 14, "")
    title:SetShadowOffset(0, 0)
    title:SetShadowColor(0, 0, 0, 0)
    title:SetTextColor(1, 0.82, 0, 1)   -- 金色（ZZHELPER 标题金 1,0.82,0）
    title:SetText(text)
    -- 1px 分隔线（ZZHELPER：WHITE8X8 色 0.35,0.35,0.35，位于标题条底部）
    local divider = f:CreateTexture(nil, "BACKGROUND")
    divider:SetTexture("Interface\\Buttons\\WHITE8X8")
    divider:SetVertexColor(0.35, 0.35, 0.35, 1)
    divider:Show()
    divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    divider:SetHeight(1)
    f.divider = divider
    f.collapseKey = collapseKey
    if collapseKey then
        local indicator = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        indicator:SetPoint("RIGHT", f, "RIGHT", -6, 0)
        indicator:SetFont(STANDARD_TEXT_FONT, 14, "")
        indicator:SetTextColor(1, 0.82, 0, 1)
        f.indicator = indicator
        f.RefreshIndicator = function(self)
            local collapsed = (PigSet[collapseKey] == true)
            self.collapsed = collapsed
            if self.indicator then self.indicator:SetText(collapsed and "+" or "-") end
        end
        f:RefreshIndicator()
        f:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("点击" .. (self.collapsed and "展开" or "折叠") .. "【" .. text .. "】分类")
            GameTooltip:Show()
        end)
        f:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f:SetScript("OnMouseDown", function(self)
            PigSet[collapseKey] = not (PigSet[collapseKey] == true)
            self:RefreshIndicator()
            if WR_LayoutGlobalAOECategory then WR_LayoutGlobalAOECategory() end
            if WR_RefreshConfigUI then WR_RefreshConfigUI() end
        end)
    end
    f:Hide()
    return f
end

-- ============================================================
-- 创建滑块（Slider）
-- 输入：config表格（含 text, row, saveVariable, minValue, maxValue, valueStep, defaultVal, tooltipText）
-- 返回：textFrame（标签），slider（滑块对象）
-- ============================================================
local function CreateMenuSlider(config)
    local yOffset = -MENU_TOP_PAD - MENU_ROW_H * (config.row - 1)

    -- 标签文字（使用 STANDARD_TEXT_FONT 避免模板自带阴影）
    local textFrame = config.parentFrame:CreateFontString(nil, "ARTWORK")
    textFrame:SetFont(STANDARD_TEXT_FONT, 14, "")
    textFrame:SetTextColor(classColor.r, classColor.g, classColor.b)
    textFrame:SetText(config.text)
    local labelX = config.x or GLOBAL_INNER_PAD
    textFrame:SetPoint("TOPLEFT", config.parentFrame, "TOPLEFT", labelX, yOffset)
    -- 用 SetSize 锁死标签尺寸，避免 FontString 因文本长度自动伸缩导致跨行控件左缘错位
    textFrame:SetSize(config.labelWidth or MENU_LABEL_W, 16)
    textFrame:SetJustifyH("LEFT")

    -- 创建滑块：左接标签，右端留出百分比文字宽度，整体与下拉框等长
    local slider = CreateFrame("Slider", config.saveVariable .. "_Slider", config.parentFrame)
    slider:SetOrientation("HORIZONTAL")
    slider:SetHeight(10)
    local VAL_TEXT_W = 40           -- 百分比文字固定宽度（容纳 "100%"）
    local VAL_GAP = 6               -- 滑块与百分比文字间距
    -- 滑块与下拉框同处行顶（-2），保证两类控件视觉水平一致；不再垂直居中
    slider:SetPoint("LEFT", textFrame, "RIGHT", 4, -2)
    slider:SetPoint("RIGHT", config.parentFrame, "RIGHT", -(labelX + VAL_TEXT_W + VAL_GAP), 0)
    slider:SetMinMaxValues(config.minValue or 0, config.maxValue or 100)
    slider:SetValueStep(config.valueStep or 1)
    slider:SetObeyStepOnDrag(true)

    -- ★ 滑块最小宽度保护：容器过窄时（用户拖窄面板），滑块左右锚点会交叉导致负宽度/溢出右边界。
    --    此处检测实际宽度，若低于 MIN_SLIDER_W 则把右锚点向内推，保证滑块始终在容器内且不被裁剪。
    local MIN_SLIDER_W = 60
    local actualW = slider:GetWidth()
    if actualW < MIN_SLIDER_W then
        local deficit = MIN_SLIDER_W - actualW
        slider:SetPoint("RIGHT", config.parentFrame, "RIGHT", -(labelX + VAL_TEXT_W + VAL_GAP) - deficit, 0)
    end

    -- 背景轨道（与左侧全局区滑块统一：深灰底）
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetTexture("Interface\\Buttons\\WHITE8x8")
    track:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    track:SetAllPoints()

    -- 边框
    local border = slider:CreateTexture(nil, "BACKGROUND", nil, -1)
    border:SetTexture("Interface\\Buttons\\WHITE8x8")
    border:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.5)   -- 职业色弱描边
    border:SetPoint("TOPLEFT", slider, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", slider, "BOTTOMRIGHT", 1, -1)

    -- 填充条（显示进度）
    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetTexture("Interface\\Buttons\\WHITE8x8")
    fill:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.9)
    fill:SetPoint("TOPLEFT", slider, "TOPLEFT", 0, 0)
    fill:SetPoint("BOTTOMLEFT", slider, "BOTTOMLEFT", 0, 0)

    -- 可见拖动手柄（白色小方块，与左侧「偷药时间」滑块风格一致）
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:SetSize(6, 14)
        thumb:SetVertexColor(1, 1, 1)   -- 白色手柄
    end

    -- 显示当前数值的文字（放在滑块右侧，右端与下拉框右端对齐）
    local valText = slider:CreateFontString(nil, "ARTWORK")
    valText:SetFont(STANDARD_TEXT_FONT, 14, "")
    valText:SetTextColor(classColor.r, classColor.g, classColor.b)
    valText:SetPoint("LEFT", slider, "RIGHT", VAL_GAP, 0)
    valText:SetWidth(VAL_TEXT_W)
    valText:SetJustifyH("RIGHT")

    -- 更新数值显示和填充条
    local function UpdateValText(val)
        if config.formatFunc then
            valText:SetText(config.formatFunc(val))
        elseif config.menuItems and config.menuItems[val] then
            valText:SetText(config.menuItems[val].text)
        else
            if val == 0 then
                valText:SetText("|cffff5040关闭|r")
            else
                if config.isPercent == false then
                    valText:SetText(val)
                else
                    valText:SetText(val .. "%")
                end
            end
        end

        local min, max = slider:GetMinMaxValues()
        local pct = (max > min) and ((val - min) / (max - min)) or 0
        if pct < 0 then pct = 0 end
        if pct > 1 then pct = 1 end
        local w = slider:GetWidth() * pct
        if w == 0 then w = 0.001 end
        fill:SetWidth(w)
    end

    -- ★ 修复金色 thumb 位置错乱：slider 宽度变化时（parentFrame 从 510 扩到 720 后）fill 必须同步扩。
    --    之前只在创建时调用 UpdateValText 锁死 fill 宽度，slider 自动扩后 fill 仍停在旧宽度，
    --    导致 thumb（slider 内部 widget）位置与 fill 不一致（金色 thumb 偏离数值）。
    --    加 OnSizeChanged hook，slider 每次宽度变化重算 fill。
    slider:HookScript("OnSizeChanged", function(self)
        local v = self:GetValue()
        UpdateValText(v)
    end)

    local minV = config.minValue or 0
    local maxV = config.maxValue or 100

    -- 兼容旧版本存储的数值（例如从百分比到实际数值的转换）
    local function MigrateLegacySliderValue(saveVariable, val)
        if type(val) ~= "number" then
            if type(val) == "boolean" then
                return val and (config.defaultVal or maxV) or 0
            end
            return nil
        end
        if saveVariable == "SS_SGS" or saveVariable == "SS_SGSX" or saveVariable == "SS_SLS" or
           saveVariable == "SS_SDS" or saveVariable == "SS_XSZS" or saveVariable == "SS_BHZS" or
           saveVariable == "SS_HF" then
            if val >= 19 then return val end
            if val <= 0 then return 0 end
            if val <= 9 then return val * 10 end
            return 90 + (val - 9)
        end
        if saveVariable == "HF_ZRXJ" and (val == 0 or val == 1) then
            return val == 1 and (config.defaultVal or 40) or 0
        end
        if saveVariable == "HF_YXGL" and val <= 10 then
            return val * 10
        end
        return val
    end

    local stored = PigSet[config.saveVariable]
    local migrated = MigrateLegacySliderValue(config.saveVariable, stored)
    if migrated == nil or type(migrated) ~= "number" then
        migrated = config.defaultVal or 80
    end
    if migrated < minV then migrated = minV end
    if migrated > maxV then migrated = maxV end
    PigSet[config.saveVariable] = migrated
    slider:SetValue(migrated)
    UpdateValText(migrated)

    -- 滑块值改变时的处理
    slider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value + 0.5)
        PigSet[config.saveVariable] = val
        UpdateValText(val)
    end)

    -- 高亮和提示
    local highlight = slider:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(slider)
    highlight:Hide()

    slider:SetScript("OnEnter", function(self)
        highlight:Show()
        textFrame:SetTextColor(1, 1, 1)
        if config.tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local tipText = config.tooltipText
            if config.saveVariable then
                tipText = tipText .. "\n宏/" .. config.saveVariable .. " 空格<数值> 快速设置"
            end
            GameTooltip:SetText(tipText)
            GameTooltip:Show()
        end
    end)

    slider:SetScript("OnLeave", function(self)
        highlight:Hide()
        textFrame:SetTextColor(classColor.r, classColor.g, classColor.b)
        if config.tooltipText then
            GameTooltip:Hide()
        end
    end)

    -- 注册斜杠命令：/saveVariable <数值>
    if config.saveVariable then
        local function HandleCommand(msg)
            msg = strtrim(msg or "")
            local val = tonumber(msg)
            if val then
                local min, max = slider:GetMinMaxValues()
                if val < min then val = min end
                if val > max then val = max end
                if config.valueStep and config.valueStep > 0 then
                    val = math.floor((val - min) / config.valueStep + 0.5) * config.valueStep + min
                end
                slider:SetValue(val)
                print(string.format("|cff00ff00已将 [%s] 设置为:|r %s", config.text or config.saveVariable, tostring(val)))
            else
                local min, max = slider:GetMinMaxValues()
                print(string.format("|cffff0000命令用法:|r /%s <数值> (当前: %s, 范围: %s-%s)",
                    config.saveVariable, tostring(PigSet[config.saveVariable]), tostring(min), tostring(max)))
            end
        end
        _G["SLASH_" .. config.saveVariable .. "1"] = "/" .. config.saveVariable
        SlashCmdList[config.saveVariable] = HandleCommand
    end

    return textFrame, slider
end

-- ============================================================
-- 框架大小调整（拖拽）
-- ============================================================

-- 在拖拽过程中应用新尺寸（内部函数）
local function ApplyConfigFrameUserSizeDuringResize(configFrame, newW, newH)
    if newW < MIN_TOTAL_WIDTH then newW = MIN_TOTAL_WIDTH end
    if newH < 300 then newH = 300 end
    configFrame:SetSize(newW, newH)
    FrameWide = newW
    PigSet["FrameWide"] = newW
    PigSet["FrameHigh"] = newH
    PigSet["FrameUserSized"] = true
    if WR_LayoutConfigFrame then WR_LayoutConfigFrame() end
end

-- 拖拽结束后应用尺寸
local function ApplyConfigFrameUserSize(configFrame, newW, newH)
    ApplyConfigFrameUserSizeDuringResize(configFrame, newW, newH)
    WR_RefreshConfigUI()
end

-- 结束拖拽调整
local function EndConfigFrameResize(configFrame, resizeButton)
    configFrame:SetScript("OnUpdate", nil)
    configFrame.resizeState = nil
    if resizeButton then resizeButton:SetScript("OnUpdate", nil) end
    ClearHorizontalResizeCursor(resizeButton)
    PigSet["FrameWide"] = configFrame:GetWidth()
    PigSet["FrameHigh"] = configFrame:GetHeight()
    PigSet["FrameUserSized"] = true
    WR_RefreshConfigUI()
end

-- 开始拖拽调整
local function BeginConfigFrameResize(configFrame, resizeButton, widthOnly)
    local startX, startY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    local startW = configFrame:GetWidth()
    local startH = configFrame:GetHeight()

    configFrame.resizeState = {
        widthOnly = widthOnly,
        startX = startX,
        startY = startY,
        startW = startW,
        startH = startH,
        uiScale = uiScale,
        button = resizeButton,
    }

    configFrame:SetScript("OnUpdate", function(self)
        local state = self.resizeState
        if not state then return end
        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
            EndConfigFrameResize(self, state.button)
            return
        end
        local currentX, currentY = GetCursorPosition()
        local newW = state.startW + (currentX - state.startX) / state.uiScale
        local newH = state.startH + (state.startY - currentY) / state.uiScale
        if state.widthOnly then newH = state.startH end
        ApplyConfigFrameUserSizeDuringResize(self, newW, newH)
    end)
end

-- ============================================================
-- 创建天赋框架（每个天赋独立面板）
-- 输入：DM_List（下拉菜单/滑块配置列表），CB_List（复选框配置列表）
-- 返回：Frame（面板对象）
-- ============================================================
local function CreateTalentFrame(DM_List, CB_List, specName)
    talentFrameSeq = talentFrameSeq + 1
    local frameId = talentFrameSeq
    local Frame = CreateFrame("Frame", nil, WR_ClassMenuRegion or WR_ClassRegion or WR_ConfigFrame)
    Frame:SetSize(1, 1)
    Frame.frameId = frameId
    Frame.specName = specName or "NA"
    Frame.cbItems = {}
    Frame.sectionHeaders = {}
    Frame.dmCount = DM_List and #DM_List or 0
    Frame.dmList = DM_List
    Frame.dmDropdowns = {}
    Frame.dmLabels = {}
    Frame.menuAnchor = nil
    if WR_ClassMenuRegion then
        -- 右职业区菜单区：填满菜单区，给下拉菜单/滑块提供真实宽度参考
        -- 顶部偏移 -1*MENU_ROW_H：原 WCL 模式下拉（row=2）已移除，职业下拉上移一行紧贴天赋标题下方，
        -- 避免原 WCL 行位置留出空行。
        Frame:SetPoint("TOPLEFT", WR_ClassMenuRegion, "TOPLEFT", 0, -1 * MENU_ROW_H)
        Frame:SetPoint("BOTTOMRIGHT", WR_ClassMenuRegion, "BOTTOMRIGHT", 0, 0)
    elseif WR_ClassRegion then
        Frame:SetPoint("TOPLEFT", WR_ClassRegion, "TOPLEFT", 0, -22)
        Frame:SetPoint("BOTTOMRIGHT", WR_ClassRegion, "BOTTOMRIGHT", 0, 0)
    else
        Frame:SetPoint("TOP", MKHelperForeverIcon, "BOTTOM", 50, -10 - MENU_ROW_H)
    end

    if DM_List then
        if not WR_Dropdown then WR_Dropdown = {} end
        local DM_Text
        local row = 1
        for i, config in ipairs(DM_List) do
            if config.isSlider then
                -- 创建滑块
                DM_Text, WR_Dropdown[config.saveVariable] = CreateMenuSlider({
                    parentFrame = Frame,
                    row = row,
                    text = config.text,
                    saveVariable = config.saveVariable,
                    tooltipText = config.tooltipText,
                    minValue = config.minValue,
                    maxValue = config.maxValue,
                    valueStep = config.valueStep,
                    defaultVal = config.defaultVal,
                    formatFunc = config.formatFunc
                })
                Frame.dmDropdowns[config.saveVariable] = WR_Dropdown[config.saveVariable]
            elseif config.isCheckBox then
                -- ★ 2026-08-21：支持 DM 列表内的复选框行（ZZ 移植条目，如愈合坦模式/荆棘术）
                --   布局与滑块一致：标签 TOPLEFT + 复选框在标签右侧
                local yOffset = -MENU_TOP_PAD - MENU_ROW_H * (row - 1)
                local label = Frame:CreateFontString(nil, "ARTWORK")
                label:SetFont(STANDARD_TEXT_FONT, 16, "")
                label:SetTextColor(classColor.r, classColor.g, classColor.b)
                label:SetText(config.text)
                local labelX = config.x or GLOBAL_INNER_PAD
                label:SetPoint("TOPLEFT", Frame, "TOPLEFT", labelX, yOffset)
                label:SetSize(config.labelWidth or MENU_LABEL_W, 16)
                label:SetJustifyH("LEFT")

                local chk = CreateFrame("CheckButton", (config.saveVariable or "WR_DM_CB") .. "_F" .. frameId, Frame, "UICheckButtonTemplate")
                chk:SetSize(CB_BASE_SIZE, CB_BASE_SIZE)
                chk:SetPoint("LEFT", label, "RIGHT", 4, -2)
                chk:SetAlpha(0.95)
                if PigSet[config.saveVariable] == nil then
                    PigSet[config.saveVariable] = (config.defaultState == true)
                end
                chk:SetChecked(PigSet[config.saveVariable] == true)
                chk:SetScript("OnClick", function(self)
                    PigSet[config.saveVariable] = self:GetChecked()
                    local statusText = self:GetChecked() and "|cff00ff00开启|r" or "|cffff0000关闭|r"
                    PrintToVisible(string.format(statusText .. " [%s]", config.tooltipText or config.text))
                end)
                if config.tooltipText and config.tooltipText ~= "" then
                    chk:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText(config.tooltipText)
                        GameTooltip:Show()
                    end)
                    chk:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
                DM_Text = label
                Frame.dmLabels[config.saveVariable] = label
                Frame.dmDropdowns[config.saveVariable] = chk  -- 供重置逻辑读取
            else
                -- 创建下拉菜单
                DM_Text, WR_Dropdown[config.saveVariable] = CreateDropdownMenu({
                    parentFrame = Frame,
                    row = row,
                    text = config.text,
                    dropdownName = config.saveVariable .. "_DM_F" .. frameId,
                    menuItems = config.menuItems,
                    tooltipText = config.tooltipText,
                    saveVariable = config.saveVariable,
                    defaultID = config.defaultID,
                    width = config.width or MENU_DROPDOWN_W,
                    align = "left"
                })
                Frame.dmDropdowns[config.saveVariable] = WR_Dropdown[config.saveVariable]
                Frame.dmLabels[config.saveVariable] = DM_Text
            end
            row = row + 1
        end
        Frame.dmCount = #DM_List
        Frame.menuAnchor = DM_Text

        -- 如果有复选框配置，则创建复选框
        if CB_List then
            for _, config in ipairs(CB_List) do
                -- 惰性创建对应分类标题条：无 section 的开关归入「自动」归纳；「自动/爆发/插入」三标题条均显示，标题条上下留白已收紧为 0
                local cbSection = config.section or "自动"
                if not Frame.sectionHeaders[cbSection] then
                    -- ★ 2026-08-21：取消全部折叠功能，分类标题条改为静态（不可点击折叠）
                    Frame.sectionHeaders[cbSection] = CreateSectionHeader(Frame, cbSection, nil)
                end
                local iconFrame, checkbox, iconTexture, labelText = CreateCheckbox({
                    parentFrame = Frame,
                    row = config.row,
                    column = config.column,
                    IconID = config.IconID,
                    text = config.text,
                    checkboxName = config.saveVariable .. "_CB",
                    tooltipText = config.tooltipText,
                    saveVariable = config.saveVariable,
                    defaultState = config.defaultState
                })
                table.insert(Frame.cbItems, {
                    iconFrame = iconFrame,
                    checkbox = checkbox,
                    iconTexture = iconTexture,
                    labelText = labelText,
                    config = config,
                    anchorTo = DM_Text,
                })
            end
        end
    end

    -- 重置按钮（恢复所有选项为默认值）
    local resetBtn = CreateFrame("Button", nil, Frame, "UIPanelButtonTemplate")
    resetBtn:SetSize(65, 22)
    resetBtn:SetPoint("TOPRIGHT", WR_ConfigFrame, "TOPRIGHT", -34, -3)
    resetBtn:SetText("重置")
    resetBtn:SetFrameLevel(Frame:GetFrameLevel() + 5)
    resetBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("点击重置【当前天赋】的所有开关选项为默认值")
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    resetBtn:SetScript("OnClick", function()
        -- 重置下拉菜单/滑块
        if DM_List then
            for _, config in ipairs(DM_List) do
                if config.saveVariable then
                    if config.isSlider then
                        local def = config.defaultVal or 0
                        PigSet[config.saveVariable] = def
                        local slider = WR_Dropdown[config.saveVariable]
                        if slider and slider.SetValue then slider:SetValue(def) end
                    elseif config.isCheckBox then
                        -- ★ 2026-08-21：DM 内复选框行重置
                        local def = (config.defaultState ~= nil) and config.defaultState or false
                        PigSet[config.saveVariable] = def
                        local chk = Frame.dmDropdowns and Frame.dmDropdowns[config.saveVariable]
                        if chk and chk.SetChecked then chk:SetChecked(def) end
                    else
                        local def = config.defaultID or 1
                        PigSet[config.saveVariable] = def
                        local dropdown = Frame.dmDropdowns and Frame.dmDropdowns[config.saveVariable]
                        if dropdown then
                            UIDropDownMenu_SetSelectedID(dropdown, def)
                            if config.menuItems and config.menuItems[def] then
                                local w = (dropdown.config and dropdown.config.width) or MENU_DROPDOWN_W
                                ApplyDropdownDisplayText(dropdown, config.menuItems[def].text, w)
                            end
                        end
                    end
                end
            end
        end

        -- 重置复选框
        if CB_List then
            for _, config in ipairs(CB_List) do
                if config.saveVariable then
                    local def = config.defaultState ~= nil and config.defaultState or false
                    PigSet[config.saveVariable] = def
                    local cb = _G[config.saveVariable .. "_CB"]
                    if cb and cb.SetChecked then cb:SetChecked(def) end
                end
            end
        end
        print("|cff00ff00[MKHelperForever]|r 当前天赋的设置已恢复默认值！")
    end)

    -- 主界面命令清单/更新公告/BOSS特化按钮已迁移至功能设置面板
    -- 使用底部"功能设置"按钮统一进入

    Frame:Hide()

    -- 应用当前图标缩放
    if Frame.cbItems and #Frame.cbItems > 0 then
        local cellH, iconSize, cbSize = WR_GetLayoutMetrics()
        for _, item in ipairs(Frame.cbItems) do
            WR_ApplyIconScaleToItem(item, iconSize, cbSize)
        end
    end

    return Frame
end

-- ============================================================
-- 主配置框架
-- 创建整个配置界面的根框架，包含所有控件
-- ============================================================
local function ConfigFrame()
    if WR_ConfigIsOK ~= nil then return end

    -- 第一次加载时强制丢弃旧版单栏尺寸（必须在读取 FrameWide 之前执行）
    -- ★ 2026-08-18 二次重置：上一轮标记已置位，用户的 FrameUserSized 一直保留，
    --    导致 WR_LayoutConfigFrame 中 math.max(frameHeight, GetHeight()) 吞掉所有紧凑化改动，
    --    面板始终停在拖高过的高度（蓝框下方大段空白）。换新标记强制重新贴合内容高度。
    -- ★ 2026-08-19 三次重置（撤销后恢复）：用户左区仍溢出 → PigSet.FrameHigh 缓存旧值（如 366/486）仍在生效，
    --   主窗口创建时用缓存值（1361 行），OnShow 走 ApplyIconScale 不重算 frameHeight（355-360 行互斥），
    --   导致 leftContentH=20 行新长度不生效。清缓存强制用 DEFAULT_FRAME_HEIGHT + OnShow LayoutConfigFrame 重算。
    -- ★ 2026-08-21 四次重置（右区缩到 2×左区）：新默认宽度 580 需要覆盖旧 FrameWide（720/800），
    --   否则 FrameUserSized/FrameWide 缓存会吞掉新宽度。清缓存强制用新 DEFAULT_FRAME_WIDTH。
    -- ★ 2026-08-21 v2 五次重置（右区 2×→1.5×左区）：新默认宽度 495 覆盖旧 FrameWide（580）。
    if not PigSet["_UI_Config_Resized_2026_08_21_v2"] then
        PigSet["FrameUserSized"] = nil
        PigSet["FrameWide"] = nil
        PigSet["FrameHigh"] = nil
        PigSet["_UI_Config_Resized_2026_08_21_v2"] = true
    end
    if not PigSet["_UI_Config_Resized_2026_08_21"] then
        PigSet["FrameUserSized"] = nil
        PigSet["FrameWide"] = nil
        PigSet["FrameHigh"] = nil
        PigSet["_UI_Config_Resized_2026_08_21"] = true
    end
    if not PigSet["_UI_Config_Resized_2026_08_19"] then
        PigSet["FrameUserSized"] = nil
        PigSet["FrameWide"] = nil
        PigSet["FrameHigh"] = nil
        PigSet["_UI_Config_Resized_2026_08_19"] = true
        -- 清理旧标记
        PigSet["_UI_Config_Resized"] = nil
        PigSet["_UI_Config_Resized_2026_08_16"] = nil
        PigSet["_UI_Config_Resized_2026_08_16_02"] = nil
        PigSet["_UI_Config_Resized_2026_08_18_02"] = nil
    end
    if not PigSet["_UI_Config_Resized_2026_08_18_02"] then
        PigSet["FrameUserSized"] = nil
        PigSet["FrameWide"] = nil
        PigSet["FrameHigh"] = nil
        PigSet["_UI_Config_Resized_2026_08_18_02"] = true
        -- 清理旧标记
        PigSet["_UI_Config_Resized"] = nil
        PigSet["_UI_Config_Resized_2026_08_16"] = nil
        PigSet["_UI_Config_Resized_2026_08_16_02"] = nil
    end

    -- 初始化尺寸（左右分区后默认更宽更高）
    FrameWide = DEFAULT_FRAME_WIDTH
    WR_FRAME_BASE_HEIGHT = 112
    local FrameHigh = PigSet["FrameHigh"] or DEFAULT_FRAME_HEIGHT
    local initWide = PigSet["FrameWide"] or FrameWide

    -- 创建主框架（使用暴雪的对话框模板）
    -- ★ 2026-08-21：去掉 UIPanelDialogTemplate（其自带外框体边框线条），仅用 BackdropTemplate 画深色底、无边框
    local configFrame = CreateFrame("Frame", "WR_ConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(initWide, FrameHigh)
    FrameWide = initWide
    -- ★ 2026-08-22：窗口位置记忆。优先恢复上次关闭前保存的位置（PigSet 是 per-character 存档），
    --   首次使用或尚无记录时回退到屏幕顶部水平居中。
    local savedPoint = PigSet["_MKH_ConfigFrame_Point"]
    if savedPoint then
        configFrame:ClearAllPoints()
        configFrame:SetPoint(
            savedPoint.point or "TOPLEFT",
            UIParent,
            savedPoint.relPoint or "TOPLEFT",
            savedPoint.xOfs or 0,
            savedPoint.yOfs or 0
        )
    else
        -- ★ 2026-08-22：首次打开（无存档）默认屏幕左侧垂直居中，左侧留 16px 边距
        configFrame:SetPoint("LEFT", UIParent, "LEFT", 16, 0)
    end
    -- 仅背景色，无外框边线（用户要求去掉外框体线条）
    if configFrame.SetBackdrop then
        configFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = nil,
            tile = true,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        configFrame:SetBackdropColor(0.28, 0.28, 0.28, 1)
    else
        -- 回退：手工绘制深色底（无边框）
        local darkBg = configFrame:CreateTexture(nil, "BACKGROUND")
        darkBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        darkBg:SetVertexColor(0.28, 0.28, 0.28, 1)
        darkBg:SetAllPoints(configFrame)
    end

    -- 可拖拽移动
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- ★ 2026-08-22：拖拽结束后保存窗口位置到 per-character 存档，下次打开恢复
        local point, _, relPoint, xOfs, yOfs = self:GetPoint(1)
        if point then
            PigSet["_MKH_ConfigFrame_Point"] = {
                point = point,
                relPoint = relPoint,
                xOfs = xOfs,
                yOfs = yOfs,
            }
        end
    end)
    configFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.resizeState then
            EndConfigFrameResize(self, self.resizeState.button)
        end
    end)
    configFrame:SetFrameStrata("FULLSCREEN")
    configFrame:Hide()

    -- 显示时刷新布局
    configFrame:SetScript("OnShow", function()
        PigSet["IconScale"] = PigSet["IconScale"] or 100
        if WR_IconScaleSlider then WR_IconScaleSlider:SetValue(PigSet["IconScale"]) end
        WR_RefreshConfigUI()
        -- ★ 2026-08-19：第一次登录时 slider 跑出界面（"圣光闪现"等治疗职业滑块 thumb 超出范围）。
        --  根因：OnShow 首次跑 LayoutConfigFrame 时 TalentFrame 的 cbItems 数量尚未稳定，layoutAnchor 位置用 0,0 默认值，
        --  slider 的 SetPoint RIGHT configFrame 用了错的宽度，导致 thumb 跑出 slider 范围。
        --  修复：延迟 1 帧再跑一次 LayoutConfigFrame，确保所有元素就位后重新计算 layout。
        if C_Timer and C_Timer.After and WR_LayoutConfigFrame then
            C_Timer.After(0, function()
                if configFrame:IsShown() and WR_LayoutConfigFrame then
                    WR_LayoutConfigFrame()
                end
            end)
        end
    end)

    -- ★ 2026-08-22：面板隐藏（关闭/Esc/切换）时保存当前位置，配合 OnDragStop
    --   与初始化读取，实现「记住上次窗口位置」，不再每次固定弹出。
    configFrame:SetScript("OnHide", function(self)
        local point, _, relPoint, xOfs, yOfs = self:GetPoint(1)
        if point then
            PigSet["_MKH_ConfigFrame_Point"] = {
                point = point,
                relPoint = relPoint,
                xOfs = xOfs,
                yOfs = yOfs,
            }
        end
    end)

    -- ★ 2026-08-21：用户要求不要标题底色 —— 不再绘制顶栏深色条，
    --   仅保留 TOP_BAR_H 顶部留白高度（标题与内容分区仍按此留白对齐，避免文字重叠）。

    configFrame.title = configFrame:CreateFontString(nil, "OVERLAY")
    -- ★ 2026-08-21 v7：MKH 标题放左上角，并在顶栏深色条内垂直居中
    configFrame.title:SetPoint("LEFT", configFrame, "TOPLEFT", 8, -TOP_BAR_H / 2)
    configFrame.title:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    configFrame.title:SetText("MKH")  -- ★ 用户要求：标题简化为 "MKH"
    configFrame.title:SetTextColor(0, 0.68, 0.94, 1)  -- 天蓝 00adf0（ZZHELPER 标题色）

    -- 关闭按钮（自定义：WR_ConfigFrame 用的是 BackdropTemplate，无自带关闭按钮，需自建）
    local closeBtn = CreateFrame("Button", "WR_ConfigCloseBtn", configFrame)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -2, -2)
    closeBtn:SetFrameLevel(configFrame:GetFrameLevel() + 8)
    closeBtn:SetNormalFontObject(GameFontNormalSmall)
    closeBtn:SetText("✕")  -- 叉号
    closeBtn:GetFontString():SetTextColor(0.9, 0.9, 0.9, 1)
    -- 背景：半透明圆角方块，常态微暗，悬停变红
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    closeBg:SetVertexColor(0.15, 0.15, 0.15, 0.85)
    local closeBorder = closeBtn:CreateTexture(nil, "BORDER")
    closeBorder:SetAllPoints()
    closeBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
    closeBorder:SetVertexColor(0.6, 0.6, 0.6, 0.9)
    -- 内缩 1px 形成描边效果
    closeBg:ClearAllPoints()
    closeBg:SetPoint("TOPLEFT", closeBtn, "TOPLEFT", 1, -1)
    closeBg:SetPoint("BOTTOMRIGHT", closeBtn, "BOTTOMRIGHT", -1, 1)
    closeBtn:SetScript("OnEnter", function(self)
        closeBg:SetVertexColor(0.7, 0.1, 0.1, 0.95)
        self:GetFontString():SetTextColor(1, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("关闭界面")
        GameTooltip:Show()
    end)
    closeBtn:SetScript("OnLeave", function(self)
        closeBg:SetVertexColor(0.15, 0.15, 0.15, 0.85)
        self:GetFontString():SetTextColor(0.9, 0.9, 0.9, 1)
        GameTooltip:Hide()
    end)
    closeBtn:SetScript("OnClick", function() configFrame:Hide() end)

    -- ============================================================
    -- ★ 左右分区：左侧全局区 / 右侧职业区
    -- ============================================================
    -- 左侧全局区（固定宽，承载跨职业通用开关，仅构建一次）
    local globalRegion = CreateFrame("Frame", "WR_GlobalRegion", configFrame)
    globalRegion:SetPoint("TOPLEFT", configFrame, "TOPLEFT", GLOBAL_OUTER_PAD, -TOP_BAR_H)
    globalRegion:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", GLOBAL_OUTER_PAD, BOTTOM_BAR_H)
    globalRegion:SetWidth(GLOBAL_REGION_W)
    globalRegion:EnableMouse(true)
    WR_GlobalRegion = globalRegion

    -- ★ 2026-08-21 v6：取消全部折叠功能，「全局」标题条改为静态（不可点击折叠）
    --   图标将放在标题条左侧（全局左上角），"全局"文字右对齐到标题条右侧
    --   标题条从 globalRegion 顶边开始（y=0 偏移），与右侧「设置」标题条顶部对齐、底部横线同高
    local globalHeader = CreateSectionHeader(globalRegion, "全局", nil)
    globalHeader:ClearAllPoints()
    globalHeader:SetPoint("TOPLEFT", globalRegion, "TOPLEFT", GLOBAL_INNER_PAD, 0)
    globalHeader:SetPoint("TOPRIGHT", globalRegion, "TOPRIGHT", -GLOBAL_INNER_PAD, 0)
    globalHeader:SetHeight(SECTION_HEADER_H)
    globalHeader:Show()
    -- 将「全局」标题文字改为右对齐（图标将占据左侧）
    for _, region in ipairs({globalHeader:GetRegions()}) do
        if region.GetText and region:GetText() == "全局" then
            region:ClearAllPoints()
            region:SetPoint("RIGHT", globalHeader, "RIGHT", -6, 0)
            region:SetJustifyH("RIGHT")
        end
    end

    -- 左右分隔线
    local divider = configFrame:CreateTexture("WR_Divider", "ARTWORK")
    divider:SetColorTexture(0.6, 0.6, 0.6, 0.45)
    divider:SetPoint("TOPLEFT", globalRegion, "TOPRIGHT", 0, 0)
    divider:SetPoint("BOTTOMLEFT", globalRegion, "BOTTOMRIGHT", 0, 0)
    divider:SetWidth(1)
    WR_Divider = divider

    -- 右侧职业区（自适应宽，承载当前专精天赋面板）
    local classRegion = CreateFrame("Frame", "WR_ClassRegion", configFrame)
    classRegion:SetPoint("TOPLEFT", globalRegion, "TOPRIGHT", DIV_GAP, 0)
    classRegion:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -RIGHT_OUTER_PAD, BOTTOM_BAR_H)
    classRegion:EnableMouse(true)
    WR_ClassRegion = classRegion

    -- 右区顶部菜单区（下拉菜单/滑块）
    local classMenuRegion = CreateFrame("Frame", "WR_ClassMenuRegion", classRegion)
    -- ★ 2026-08-21：菜单区下移一个标题条高度，给右区「设置」折叠标题条让位（标题条固定在 classRegion 顶部）
    classMenuRegion:SetPoint("TOPLEFT", classRegion, "TOPLEFT", 0, -SECTION_HEADER_H)
    classMenuRegion:SetPoint("TOPRIGHT", classRegion, "TOPRIGHT", 0, -SECTION_HEADER_H)
    classMenuRegion:SetHeight(120)
    WR_ClassMenuRegion = classMenuRegion

    -- 右区底部图标区（职业图标网格）
    local classIconRegion = CreateFrame("Frame", "WR_ClassIconRegion", classRegion)
    classIconRegion:SetPoint("BOTTOMLEFT", classRegion, "BOTTOMLEFT", 0, 0)
    classIconRegion:SetPoint("BOTTOMRIGHT", classRegion, "BOTTOMRIGHT", 0, 0)
    classIconRegion:SetHeight(ICON_REGION_MIN_H)
    WR_ClassIconRegion = classIconRegion

    -- ★ 2026-08-21：取消全部折叠功能，「设置」标题条改为静态（不可点击折叠），菜单区始终显示
    local settingsHeader = CreateSectionHeader(classRegion, "设置", nil)
    settingsHeader:ClearAllPoints()
    settingsHeader:SetPoint("TOPLEFT", classRegion, "TOPLEFT", 0, 0)
    settingsHeader:SetPoint("TOPRIGHT", classRegion, "TOPRIGHT", 0, 0)
    settingsHeader:SetHeight(SECTION_HEADER_H)
    settingsHeader:Show()

    -- 图标布局锚点（挂在右职业区底部的图标区）
    configFrame.iconLayoutAnchor = CreateFrame("Frame", "WR_IconLayoutAnchor", classIconRegion)
    configFrame.iconLayoutAnchor:SetSize(1, 1)

    -- 插件图标（★ 2026-08-21 v5：从顶栏移到左全局区「全局」标题条左侧）
    --   历史：顶栏 (8,-12)；现改为 globalHeader 左侧，与右对齐的"全局"文字同行。
    local iconTexture = configFrame:CreateTexture("MKHelperForeverIcon", "OVERLAY")
    iconTexture:SetSize(22, 22)
    iconTexture:SetPoint("TOPLEFT", globalHeader, "TOPLEFT", 4, -1)
    iconTexture:SetTexture("Interface\\AddOns\\MKHelperForever\\MKHelperForever.tga")

    -- 智能AOE 分类（左全局区首个分类，标题条静态不可折叠）
    -- ★ 设计：仅提供 UI 开关 + PigSet 占位键，暂未接入各职业 AOE 逻辑（按用户 8/21 决策"UI开关+占位hook"）
    --   始终显示"智能AOE（自动）/手动AOE（爆发）"两个子开关；并据此重定位下方调试模式控件链。
    local aoeCatHeader = CreateSectionHeader(globalRegion, "智能AOE", nil)
    aoeCatHeader:SetWidth(GLOBAL_REGION_W - GLOBAL_INNER_PAD * 2)

    local aoeCatContent = CreateFrame("Frame", nil, globalRegion)
    aoeCatContent:SetWidth(GLOBAL_REGION_W - GLOBAL_INNER_PAD * 2)

    -- 创建智能AOE 子开关（复选框 + 标签），yOffset 为相对内容容器顶部的偏移
    local function MakeAOESwitch(var, label, defaultVal, tip, yOffset)
        if PigSet[var] == nil then PigSet[var] = defaultVal end
        local chk = CreateFrame("CheckButton", nil, aoeCatContent, "UICheckButtonTemplate")
        chk:SetSize(18, 18)
        chk:SetPoint("TOPLEFT", aoeCatContent, "TOPLEFT", 0, yOffset)
        chk:SetChecked(PigSet[var] == true)
        chk:SetScript("OnClick", function(self) PigSet[var] = self:GetChecked() end)
        local txt = aoeCatContent:CreateFontString(nil, "ARTWORK")
        txt:SetFont(STANDARD_TEXT_FONT, 15, "")
        txt:SetTextColor(classColor.r, classColor.g, classColor.b)
        txt:SetPoint("LEFT", chk, "RIGHT", 4, 0)
        txt:SetText(label)
        if tip and tip ~= "" then
            chk:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tip)
                GameTooltip:Show()
            end)
            chk:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        return chk
    end

    -- 两个子开关：默认关闭"智能AOE（自动）"，默认开启"手动AOE（爆发）"
    -- ★ 2026-08-21：提示更新（智能/手动 AOE 逻辑已接入，参考 ZZHELPER 三段式：手动强制/智能按目标数/都关不施放）
    local aoeSmartChk = MakeAOESwitch("WR_GLOBAL_SMART_AOE", "智能AOE（自动）", false,
        "|cff00ff00智能 AOE 模式|r：所有职业 AOE 技能已统一接入 WR_ShouldUseAOE。\n开启后，AOE 技能按范围内敌对数阈值自动判定（近战 8yd≥2、远程 10-35yd≥2）。\n|cffff5040关闭|r + |cffff5040手动 AOE 关闭|r 时全职业 AOE 停用。", 0)
    local aoeManualChk = MakeAOESwitch("WR_GLOBAL_MANUAL_AOE", "手动AOE（爆发）", true,
        "|cff00ff00手动 AOE 模式|r（爆发期）：开启后强制施放 AOE 技能，无视目标数。\n典型场景：饰品触发 / 团队爆发 / 开怪倒数期间。\n与智能 AOE 独立，可同时开启（手动覆盖智能判定）。", -GLOBAL_ROW_H)

    -- 智能AOE 分类布局：根据折叠状态显隐内容，并据此重定位下方调试模式等控件链（依赖 globalRegion.debugCheckbox）
    -- ★ 2026-08-21：取消全部折叠功能，智能AOE 分类始终展开显示，下方调试模式控件链锚定到 AOE 内容底部
    function WR_LayoutGlobalAOECategory()
        if not aoeCatHeader or not aoeCatContent then return end
        aoeCatHeader:ClearAllPoints()
        -- ★ 2026-08-21 v5：AOE 标题从 -36 下移到 -40，给 globalHeader 左侧的图标留一点间距
        aoeCatHeader:SetPoint("TOPLEFT", globalRegion, "TOPLEFT", GLOBAL_INNER_PAD, -40)
        aoeCatHeader:Show()
        aoeCatContent:Show()
        aoeCatContent:ClearAllPoints()
        aoeCatContent:SetPoint("TOPLEFT", aoeCatHeader, "BOTTOMLEFT", 0, 0)
        aoeCatContent:SetHeight(2 * GLOBAL_ROW_H)
        if globalRegion.debugCheckbox then
            globalRegion.debugCheckbox:ClearAllPoints()
            globalRegion.debugCheckbox:SetPoint("TOPLEFT", aoeCatContent, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
        end
    end

    -- ★ 2026-08-21：取消全部折叠功能，左区全局内容始终全部显示，仅负责 AOE 子区块定位
    function WR_LayoutGlobal()
        if not globalRegion then return end
        if globalHeader then globalHeader:Show() end
        if WR_LayoutGlobalAOECategory then WR_LayoutGlobalAOECategory() end
    end

    -- ★ 2026-08-21：取消全部折叠功能，WR_CollapseAllCategories / 折叠全部·展开全部按钮 已移除


    -- 调试模式复选框（迁入左侧全局区，位于标题下方）
    local checkbox = CreateFrame("CheckButton", "WR_TestCheckbox", globalRegion, "UICheckButtonTemplate")
    checkbox:SetSize(20, 20)
    checkbox:SetPoint("TOPLEFT", globalRegion, "TOPLEFT", GLOBAL_INNER_PAD, -36)
    -- ★ 2026-11-06：调试模式改为「可持久化 + 默认关闭」。
    --   原实现硬编码 SetChecked(true)：每次 /reload 后自动进入调试模式，
    --   MainLoop 每帧走 WR_MaxColorFrame()，把所有已创建的色块放大到 42×42
    --   并显示技能名文字（正常游玩应为 WR_MinColorFrame 的 5×5 小点），
    --   于是屏幕左上角会成片出现彩色方块 —— 这是误开的调试显示，不是功能异常。
    checkbox:SetChecked(PigSet["DEBUG_MODE"] == true)
    checkbox:SetScript("OnClick", function(self)
        PigSet["DEBUG_MODE"] = self:GetChecked() and true or false
    end)
    globalRegion.debugCheckbox = checkbox
    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("如果卡技能，请勾选此选项。\n可以查出卡在什么技能或功能上了。")
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    -- ★ 2026-08-21：文本标签改为 globalRegion 子级，确保全局折叠时随左区一起隐藏
    local TSMS_Text = globalRegion:CreateFontString("TSMS_Text", "ARTWORK")
    TSMS_Text:SetFont(STANDARD_TEXT_FONT, 16, "")
    TSMS_Text:SetTextColor(classColor.r, classColor.g, classColor.b)
    TSMS_Text:SetText("调试模式")
    TSMS_Text:SetPoint("LEFT", checkbox, "RIGHT", 0, 0)

    -- ★ 2026-08-21：技能提示图标开关（与调试模式同行靠右）
    --   控制屏幕角落技能提示框是否叠加显示技能图标；图标位置可在游戏内直接拖动
    local iconChk = CreateFrame("CheckButton", "WR_SkillIconShowChk", globalRegion, "UICheckButtonTemplate")
    iconChk:SetSize(20, 20)
    iconChk:SetPoint("TOPLEFT", globalRegion, "TOPLEFT", 120, -36)
    -- ★ 2026-08-21：技能图标默认不勾选（仅当用户显式开启 SkillIconShow=true 才勾选）
    iconChk:SetChecked(PigSet["SkillIconShow"] == true)
    iconChk:SetScript("OnClick", function(self)
        PigSet["SkillIconShow"] = self:GetChecked()
        -- ★ 取消勾选时立即隐藏整个技能图标框体（含底色与边框），勾选时恢复常驻
        if WR_SkillIconFrame then
            if self:GetChecked() then
                WR_SkillIconFrame:Show()
            else
                WR_SkillIconFrame:Hide()
            end
        end
    end)
    iconChk:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("技能提示图标：开启后，屏幕角落的技能提示框会叠加显示当前技能的图标。\n位置可在游戏内用鼠标左键直接拖动。")
        GameTooltip:Show()
    end)
    iconChk:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    local iconChkText = globalRegion:CreateFontString("WR_SkillIconShowText", "ARTWORK")
    iconChkText:SetFont(STANDARD_TEXT_FONT, 15, "")
    iconChkText:SetTextColor(classColor.r, classColor.g, classColor.b)
    iconChkText:SetText("技能图标")
    iconChkText:SetPoint("LEFT", iconChk, "RIGHT", 0, 0)
    globalRegion.skillIconCheckbox = iconChk

    -- ★ 2026-08-19 顶栏重构：删除原"功能设置"单一按钮，改为三个独立按钮（怪物屏蔽/命令清单/更新公告）
    -- 三个按钮采用短词版本（屏蔽/命令/更新），宽 40 高 24，紧凑排列在重置按钮左侧
    -- 按钮位置（相对 configFrame TOPRIGHT）：
    --   - 重置按钮宽 65 左边界 -99；三个按钮右边界依次 -62 / -105 / -148（左边界 -102 / -145 / -188），间隔 3 px
    --   调 ZZ_OpenMonsterBlockSection(1/2/3) 显示弹窗并跳到对应 tab

    local function CreateTopBarButton(text, tooltip, sectionIdx, width)
        local btn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
        -- ★ 2026-08-19：按钮尺寸与重置按钮一致（65×22，视觉统一）
        btn:SetSize(width or 65, 22)
        btn:SetText(text)
        btn:SetScript("OnClick", function()
            ZZ_OpenMonsterBlockSection(sectionIdx)
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
        return btn
    end

    -- 四个按钮按"由右到左"排（最右的"屏蔽"最靠近重置按钮）
    -- 重置按钮：TOPRIGHT -34, -3，宽 65，左边界 = -34-65 = -99
    -- "爆发"右边界 -34-65-4 = -103（重置左侧）；"屏蔽"再往左 -171；"命令" -239；"更新" -307
    -- ★ 2026-08-21：新增「爆发」按钮在「屏蔽」右侧（重置按钮左边），打开爆发列表 tab
    local burstListBtn = CreateTopBarButton("爆发",
        "|cffffd100爆发列表|r\n按副本阶段配置允许触发自动爆发的团本目标（BOSS/小怪勾选）\n\n勾选=允许爆发；取消=爆发循环跳过该目标", 2, 65)
    burstListBtn:SetPoint("TOPRIGHT", WR_ConfigFrame, "TOPRIGHT", -103, -3)

    local monsterBlockBtn = CreateTopBarButton("屏蔽",
        "|cffffd100怪物屏蔽|r\n打开分副本阶段配置首类/单体/AOE 屏蔽名单\n\n命令 |cff00adf0/monster [on|off|toggle]|r 直接切换总开关", 1, 65)
    monsterBlockBtn:SetPoint("TOPRIGHT", WR_ConfigFrame, "TOPRIGHT", -171, -3)

    local commandListBtn = CreateTopBarButton("命令",
        "|cffffd100命令清单|r\n打开所有可用的 / 命令、宏绑定与说明", 3, 65)
    commandListBtn:SetPoint("TOPRIGHT", WR_ConfigFrame, "TOPRIGHT", -239, -3)

    local updateLogBtn = CreateTopBarButton("更新",
        "|cffffd100更新公告|r\n打开插件历史更新日志", 4, 65)
    updateLogBtn:SetPoint("TOPRIGHT", WR_ConfigFrame, "TOPRIGHT", -307, -3)

    -- ★ 2026-08-21：取消全部折叠功能，「折叠全部 / 展开全部」按钮已移除

    -- 天赋标题文本（占位，由外部设置）
    -- ★ 2026-08-21 v3：加大到 16 号 + OUTLINE + 加阴影 + 提升绘制层级（防止被菜单区下拉框覆盖）
    --   TianFu_Text 父级是 configFrame 而非 classMenuRegion，且锚在 classMenuRegion 顶部上方，
    --   原 14 号 + ARTWORK 层会被 classMenuRegion 内的下拉框覆盖（看起来"显示不正常"）。
    --   修复：FontString 无 SetFrameStrata（那是 Frame 方法），改用 SetDrawLayer("OVERLAY", 7)
    --   + 16 号 OUTLINE + 黑色阴影，确保始终在所有控件之上可见。
    local TianFu_Text = configFrame:CreateFontString("TianFu_Text", "OVERLAY")
    TianFu_Text:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
    TianFu_Text:SetShadowOffset(1, -1)
    TianFu_Text:SetShadowColor(0, 0, 0, 1)
    TianFu_Text:SetDrawLayer("OVERLAY", 7)
    TianFu_Text:SetText("")
    TianFu_Text:SetPoint("TOP", classMenuRegion, "TOP", 0, -4)
    TianFu_Text:SetJustifyH("CENTER")

    -- ============================================================
    -- ★ 底部区域重新布局（自下而上），垂直间距22像素
    -- 布局: 跟随 → 图标缩放 → 透明度 → 开关提示（屏蔽开关已移至功能设置面板）
    -- ============================================================

    -- ★ 1. 自动跟随（迁入左侧全局区，位于调试模式下方）
    local followCheckbox = CreateFrame("CheckButton", "WR_FollowCheckbox", globalRegion, "UICheckButtonTemplate")
    followCheckbox:SetSize(20, 20)
    followCheckbox:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    followCheckbox:SetChecked(PigSet.AUTO_FOLLOW_ENABLED or false)
    followCheckbox:SetScript("OnClick", function(self)
        PigSet.AUTO_FOLLOW_ENABLED = self:GetChecked()
        -- 重置状态变量
        currentFollowPhase = "idle"
        currentFollowGUID = nil
        currentFollowUnit = nil
        lastFollowAttempt = 0
        -- ★ 2026-11-09：复选框是主要开关入口，同样要重注册 /focus 宏
        if type(WR_ReapplyFocusMacros) == "function" then WR_ReapplyFocusMacros() end
        local status = self:GetChecked() and "|cff00ff00开启|r" or "|cffff0000关闭|r"
        PrintToVisible(string.format("|cff00adf0[跟随]|r 自动跟随: %s", status))
    end)
    followCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("自动跟随\n开启后自动跟随指定目标移动。\n\n|cff00adf0开启跟随：/mkaf on|r\n|cff00adf0关闭跟随：/mkaf off|r\n|cff00adf0切换跟随：/mkaf|r\n\n可选择跟随：焦点/目标/队伍成员")
        GameTooltip:Show()
    end)
    followCheckbox:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    -- ★ 2026-08-21：文本标签改为 globalRegion 子级，确保全局折叠时随左区一起隐藏
    local followLabel = globalRegion:CreateFontString(nil, "ARTWORK")
    followLabel:SetFont(STANDARD_TEXT_FONT, 16, "")
    followLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    followLabel:SetText("跟随")
    followLabel:SetPoint("LEFT", followCheckbox, "RIGHT", 5, 0)

    -- ★ 动态下拉菜单：实时显示队友名字（带职业颜色，迁入左侧全局区）
    -- 与「跟随」复选框同一行，右侧并列
    local followDropdown = CreateFrame("Frame", "WR_FollowDropdown", globalRegion, "UIDropDownMenuTemplate")
    -- ★ 2026-08-21：取消下拉框外框边缘
    if type(WR_StyleDropdownFlat) == "function" then
        WR_StyleDropdownFlat(followDropdown)
    end
    -- 跟随下拉框：置于「跟随」复选框下方独占一行（左缘对齐「跟随」文字，避免与左区焦点窗口重叠）
    -- ★ 之前改到「跟随」标签右侧同行导致与左区焦点控件水平重叠，现恢复为下方独占行布局。
    --   左缘锚 followCheckbox 的 BOTTOMLEFT（即与「跟随」文字左缘对齐），下方留 GLOBAL_ROW_H 行距。
    followDropdown:SetPoint("TOPLEFT", followCheckbox, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    -- ★ 2026-08-21：左区下拉框宽度锁定为左区内可用宽（GLOBAL_REGION_W - 2*内边距 = 178），
    --   不再用 UIDropDownMenu_SetWidth（其会隐式 +25px 导致框宽超出左区边界）。
    --   ResizeDropdownBox 末尾用 dropdown:SetWidth 覆盖，最终 frame 宽严格 = 178。
    ResizeDropdownBox(followDropdown, GLOBAL_REGION_W - GLOBAL_INNER_PAD * 2)
    followDropdown:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("跟随目标\n选择自动跟随的目标。\n支持：焦点/目标/队伍成员\n\n|cff00adf0开启跟随：/mkaf on|r\n|cff00adf0关闭跟随：/mkaf off|r\n|cff00adf0切换跟随：/mkaf|r")
        GameTooltip:Show()
    end)
    followDropdown:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    -- ★ 2026-08-21：与原右区 CreateDropdownMenu 一致，覆盖一个透明按钮占满整个下拉框，
    --   捕获点击并展开菜单。原因：WR_StyleDropdownFlat 把原生箭头 Button 缩到 12×12 并移到右上角，
    --   原生点击区过小且不可靠，仅靠它无法稳定展开菜单。覆盖整框后点击任意位置都能打开。
    local followBtn = _G[followDropdown:GetName() .. "Button"]
    local followOverlay = CreateFrame("Button", nil, followDropdown)
    followOverlay:SetPoint("TOPLEFT", followDropdown, "TOPLEFT", 0, 0)
    followOverlay:SetPoint("BOTTOMRIGHT", followDropdown, "BOTTOMRIGHT", 0, 0)
    followOverlay:SetScript("OnClick", function()
        CloseDropDownMenus()
        if followBtn then followBtn:Click() end
    end)
    -- tooltip 跟随覆盖层，避免 overlay 拦截鼠标导致提示不显示
    followOverlay:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("跟随目标\n选择自动跟随的目标。\n支持：焦点/目标/队伍成员\n\n|cff00adf0开启跟随：/mkaf on|r\n|cff00adf0关闭跟随：/mkaf off|r\n|cff00adf0切换跟随：/mkaf|r")
        GameTooltip:Show()
    end)
    followOverlay:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    -- ★ 2026-08-21：补全与右区 CreateDropdownMenu 一致的菜单弹出锚点。
    --   缺失 point/relativeTo/relativePoint 时，ToggleDropDownMenu 因无法确定弹出位置而完全不弹菜单
    --   （这正是"跟随下拉点击无反应"的根因之一）。
    followDropdown.point = "TOP"
    followDropdown.relativeTo = followDropdown
    followDropdown.relativePoint = "BOTTOM"
    followDropdown.xOffset = 0
    followDropdown.yOffset = 0
    UIDropDownMenu_JustifyText(followDropdown, "LEFT")

    -- ★ 2026-08-21：overlay 点击兜底——若原生 Button 不可靠则直接 ToggleDropDownMenu，
    --   避免 followBtn 为 nil 或 Click 不触发 OnClick 时菜单打不开。
    followOverlay:SetScript("OnClick", function()
        CloseDropDownMenus()
        if followBtn and followBtn:IsShown() then
            followBtn:Click()
        else
            ToggleDropDownMenu(1, nil, followDropdown, "WR_FollowDropdown", 0, 0)
        end
    end)

    -- 辅助函数：获取带职业颜色的玩家名字
    local function GetColoredPlayerName(unit)
        local name = UnitName(unit)
        if not name then return nil end
        local _, class = UnitClass(unit)
        if class then
            local color = RAID_CLASS_COLORS[class]
            if color then
                return string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name)
            end
        end
        return name
    end

    -- ★ 2026-11-05：跟随目标下拉改为 GUID 锚定（移植自 WotLK 时光服 MKHelper）。
    --   选中即把跟随对象的 GUID 存进 PigSet.AUTO_FOLLOW_GUID（稳定锚点，小队重排/改名/跨服不丢人），
    --   彻底不占用游戏焦点槽（奶职业用焦点做治疗焦点不冲突）。
    local function InitFollowDropdown()
        -- 固定选项：当前焦点 / 当前目标 / 清除跟随目标
        local fixedItems = {
            { text = "当前焦点", capture = "focus" },
            { text = "当前目标", capture = "target" },
            { text = "清除跟随目标", clear = true },
        }
        for i, item in ipairs(fixedItems) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.notCheckable = true
            info.func = function()
                UIDropDownMenu_SetText(followDropdown, item.text)
                if item.clear then
                    PigSet.AUTO_FOLLOW_GUID = nil
                    PigSet.AUTO_FOLLOW_NAME = ""
                    if WR_ResetAutoFollow then WR_ResetAutoFollow() end
                    if WR_HideFollowColorFrames then WR_HideFollowColorFrames() end
                    PrintToVisible("|cff00ff00已清除跟随目标|r")
                else
                    local u = item.capture
                    if UnitExists(u) and UnitIsPlayer(u) and not UnitIsUnit(u, "player") then
                        PigSet.AUTO_FOLLOW_GUID = UnitGUID(u)
                        PigSet.AUTO_FOLLOW_NAME = UnitName(u) or ""
                        if WR_ResetAutoFollow then WR_ResetAutoFollow() end
                        PrintToVisible(string.format("|cff00ff00已设为跟随目标(存GUID): %s|r", PigSet.AUTO_FOLLOW_NAME))
                    else
                        PrintToVisible("|cffff0000当前" .. item.text .. "无效（不存在/非玩家/是自己）|r")
                    end
                end
            end
            UIDropDownMenu_AddButton(info)
        end

        -- 分隔线
        local sep = UIDropDownMenu_CreateInfo()
        sep.text = "队伍/团队成员"
        sep.isTitle = true
        sep.notCheckable = true
        UIDropDownMenu_AddButton(sep)

        -- 遍历成员：点击即存其 GUID 作为主跟随目标（与游戏焦点槽完全解耦）
        local numGroup = GetNumGroupMembers() or 0
        if numGroup == 0 then return end
        local isRaid = IsInRaid()
        local maxMembers = isRaid and 40 or 4
        local prefix = isRaid and "raid" or "party"
        for i = 1, maxMembers do
            local unit = prefix .. i
            local name = UnitName(unit)
            if name and not UnitIsUnit(unit, "player") then
                local coloredName = GetColoredPlayerName(unit) or name
                local guid = UnitGUID(unit)
                local info = UIDropDownMenu_CreateInfo()
                info.text = coloredName
                info.checked = (PigSet.AUTO_FOLLOW_GUID == guid)
                info.func = function()
                    UIDropDownMenu_SetText(followDropdown, coloredName)
                    PigSet.AUTO_FOLLOW_GUID = guid
                    PigSet.AUTO_FOLLOW_NAME = name
                    if WR_ResetAutoFollow then WR_ResetAutoFollow() end
                    PrintToVisible(string.format("|cff00ff00已设为跟随目标(存GUID): %s|r", name))
                end
                UIDropDownMenu_AddButton(info)
            end
        end
    end

    UIDropDownMenu_Initialize(followDropdown, InitFollowDropdown)

    -- ★ 2026-08-21 v5：焦点下拉框下方加「界面缩放(%)」输入框
    --   用户可手动填写 50~200，Enter 后应用 configFrame:SetScale()，
    --   写入 PigSet["FrameScale"] 与右下角 scaleGrabber 拖拽缩放共享同一缩放值
    --   标签与输入框水平同行（标签在左，输入框紧贴右侧）
    local uiScaleLabel = globalRegion:CreateFontString(nil, "ARTWORK")
    uiScaleLabel:SetFont(STANDARD_TEXT_FONT, 13, "")
    uiScaleLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    -- ★ 按左区标准行距 GLOBAL_ROW_H 排布：跟随下拉框已回到「跟随」复选框下方独占行，
    --   界面缩放行锚在跟随下拉框底下方 GLOBAL_ROW_H（即「跟随」+下拉框两行之后）
    uiScaleLabel:SetPoint("TOPLEFT", followDropdown, "BOTTOMLEFT", 16, -GLOBAL_ROW_H)
    uiScaleLabel:SetText("界面缩放(%):")

    local uiScaleEdit = CreateFrame("EditBox", "WR_UIScaleEdit", globalRegion, "InputBoxTemplate")
    uiScaleEdit:SetSize(42, 20)
    uiScaleEdit:SetPoint("LEFT", uiScaleLabel, "RIGHT", 6, 0)
    -- 默认值：从 PigSet["FrameScale"] 反推百分比
    local defaultScale = PigSet["FrameScale"] or 1
    uiScaleEdit:SetText(string.format("%.0f", defaultScale * 100))
    uiScaleEdit:SetAutoFocus(false)
    uiScaleEdit:SetNumeric(true)
    uiScaleEdit:SetMaxLetters(3)
    local function ApplyUIScale(self)
        local txt = self:GetText() or ""
        local num = tonumber(txt)
        if not num then num = 100 end
        if num < 50 then num = 50 end
        if num > 200 then num = 200 end
        local scale = num / 100
        configFrame:SetScale(scale)
        PigSet["FrameScale"] = scale
        self:SetText(string.format("%.0f", num))
    end
    uiScaleEdit:SetScript("OnEnterPressed", function(self)
        ApplyUIScale(self)
        self:ClearFocus()
    end)
    uiScaleEdit:SetScript("OnEditFocusLost", function(self)
        ApplyUIScale(self)
    end)
    uiScaleEdit:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("界面缩放(%)\n填写 50~200 调整整个配置面板的显示比例。\n\n|cff00adf0窗口右下角也可拖拽缩放。|r")
        GameTooltip:Show()
    end)
    uiScaleEdit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    WR_UIScaleEdit = uiScaleEdit

    -- ★ 2026-11-05：默认显示文字取跟随目标名（GUID 主目标）
    local function GetFollowDisplayText()
        if not PigSet.AUTO_FOLLOW_GUID or PigSet.AUTO_FOLLOW_NAME == "" then
            return "无"
        end
        return PigSet.AUTO_FOLLOW_NAME
    end
    ApplyDropdownDisplayText(followDropdown, GetFollowDisplayText(), GLOBAL_REGION_W - GLOBAL_INNER_PAD * 2)

    -- ★ 监听队伍变化事件，自动刷新下拉菜单与显示文字
    local function OnGroupRosterUpdate()
        if followDropdown and followDropdown.Initialize then
            UIDropDownMenu_Initialize(followDropdown, InitFollowDropdown)
            ApplyDropdownDisplayText(followDropdown, GetFollowDisplayText(), GLOBAL_REGION_W - GLOBAL_INNER_PAD * 2)
        end
    end

    -- 注册队伍变化事件（仅注册一次）
    if not WR_FollowGroupEventRegistered then
        local groupEventFrame = CreateFrame("Frame")
        groupEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        groupEventFrame:SetScript("OnEvent", function()
            OnGroupRosterUpdate()
        end)
        WR_FollowGroupEventRegistered = true
    end

    -- ★ 自动跟随部分结束 ★
    -- ★ 左侧全局区：跨职业通用开关（仅构建一次）
    -- ============================================================


    -- ★ 自动跟随部分结束 ★

    -- ============================================================
    -- ★ 左侧全局区：跨职业通用开关（仅构建一次）
    -- ============================================================
    -- ★ 自动救人（治疗职业通用，统一在左区管理）
    if PigSet["ZL_ZDJS"] == nil then PigSet["ZL_ZDJS"] = true end
    local rescueCheckbox = CreateFrame("CheckButton", "WR_RescueCheckbox", globalRegion, "UICheckButtonTemplate")
    rescueCheckbox:SetSize(20, 20)
    -- 与「跟随」复选框左对齐（而非其右侧的下拉框），保持左区所有复选框纵向对齐
    -- 跟随已移至左区最底部，自动救人接在调试模式下方
    rescueCheckbox:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    rescueCheckbox:SetChecked(PigSet["ZL_ZDJS"])
    rescueCheckbox:SetScript("OnClick", function(self)
        PigSet["ZL_ZDJS"] = self:GetChecked()
        local status = self:GetChecked() and "|cff00ff00开启|r" or "|cffff0000关闭|r"
        PrintToVisible(string.format("|cff00adf0[救人]|r 自动救人: %s", status))
    end)
    rescueCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("自动救人\n开启后治疗职业自动对倒地的队友使用救人技能。\n所有治疗专精统一生效。")
        GameTooltip:Show()
    end)
    rescueCheckbox:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    local rescueLabel = globalRegion:CreateFontString(nil, "ARTWORK")
    rescueLabel:SetFont(STANDARD_TEXT_FONT, 16, "")
    rescueLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    rescueLabel:SetText("自动救人")
    rescueLabel:SetPoint("LEFT", rescueCheckbox, "RIGHT", -2, 1)

    -- ★ 倒数偷药（全局，开启 boss 战前自动喝药）
    if PigSet["DBM_PREPULL_POTION"] == nil then PigSet["DBM_PREPULL_POTION"] = false end
    local prepullCheckbox = CreateFrame("CheckButton", "WR_PrepullCheckbox", globalRegion, "UICheckButtonTemplate")
    prepullCheckbox:SetSize(20, 20)
    prepullCheckbox:SetPoint("TOPLEFT", rescueCheckbox, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    prepullCheckbox:SetChecked(PigSet["DBM_PREPULL_POTION"])
    prepullCheckbox:SetScript("OnClick", function(self)
        PigSet["DBM_PREPULL_POTION"] = self:GetChecked()
        local status = self:GetChecked() and "|cff00ff00开启|r" or "|cffff0000关闭|r"
        PrintToVisible(string.format("|cff00adf0[偷药]|r 倒数偷药: %s", status))
    end)
    prepullCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("倒数偷药\n开启后根据 DBM 倒计时在开怪前自动喝药水。")
        GameTooltip:Show()
    end)
    prepullCheckbox:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    local prepullLabel = globalRegion:CreateFontString(nil, "ARTWORK")
    prepullLabel:SetFont(STANDARD_TEXT_FONT, 16, "")
    prepullLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    prepullLabel:SetText("倒数偷药")
    prepullLabel:SetPoint("LEFT", prepullCheckbox, "RIGHT", -2, 1)

    -- ★ 偷药时间（全局滑块，单位：秒）
    if PigSet["TOUYAO_TIME"] == nil then PigSet["TOUYAO_TIME"] = 3 end
    local touyaoSlider = CreateFrame("Slider", "WR_TouyaoSlider", globalRegion)
    touyaoSlider:SetOrientation("HORIZONTAL")
    touyaoSlider:SetWidth(GLOBAL_REGION_W - GLOBAL_INNER_PAD * 2 - 30)
    touyaoSlider:SetHeight(10)
    touyaoSlider:SetPoint("TOPLEFT", prepullCheckbox, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    touyaoSlider:SetMinMaxValues(0, 10)
    touyaoSlider:SetValueStep(1)
    touyaoSlider:SetObeyStepOnDrag(true)
    local touyaoTrack = touyaoSlider:CreateTexture(nil, "BACKGROUND")
    touyaoTrack:SetTexture("Interface\\Buttons\\WHITE8x8")
    touyaoTrack:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    touyaoTrack:SetAllPoints()
    local touyaoFill = touyaoSlider:CreateTexture(nil, "ARTWORK")
    touyaoFill:SetTexture("Interface\\Buttons\\WHITE8x8")
    touyaoFill:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.9)
    touyaoFill:SetPoint("TOPLEFT", touyaoSlider, "TOPLEFT", 0, 0)
    touyaoFill:SetPoint("BOTTOMLEFT", touyaoSlider, "BOTTOMLEFT", 0, 0)
    touyaoSlider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    -- ★ 显式设置拇指尺寸，使其与滑动条等高（否则用默认缩略图尺寸，会比 10px 滑块高）
    local touyaoThumb = touyaoSlider:GetThumbTexture()
    if touyaoThumb then
        touyaoThumb:SetVertexColor(1, 1, 1, 1)
        touyaoThumb:SetSize(10, touyaoSlider:GetHeight())
    end
    touyaoSlider:SetValue(PigSet["TOUYAO_TIME"])
    local function UpdateTouyaoFill(val)
        local min, max = touyaoSlider:GetMinMaxValues()
        local pct = (max > min) and ((val - min) / (max - min)) or 0
        touyaoFill:SetWidth(math.max(0.001, touyaoSlider:GetWidth() * pct))
    end
    UpdateTouyaoFill(PigSet["TOUYAO_TIME"])
    local touyaoText = touyaoSlider:CreateFontString(nil, "ARTWORK")
    touyaoText:SetFont(STANDARD_TEXT_FONT, 14, "")
    touyaoText:SetTextColor(classColor.r, classColor.g, classColor.b)
    touyaoText:SetPoint("LEFT", touyaoSlider, "RIGHT", 4, 0)
    touyaoText:SetText(PigSet["TOUYAO_TIME"] .. "s")
    local touyaoLabel = globalRegion:CreateFontString(nil, "ARTWORK")
    touyaoLabel:SetFont(STANDARD_TEXT_FONT, 14, "")
    touyaoLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    touyaoLabel:SetPoint("BOTTOMLEFT", touyaoSlider, "TOPLEFT", 0, 2)
    touyaoLabel:SetText("偷药时间")
    touyaoSlider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value + 0.5)
        PigSet["TOUYAO_TIME"] = val
        touyaoText:SetText(val .. "s")
        UpdateTouyaoFill(val)
    end)

    -- ★ 爆发总闸（全局 UI 总开关，纯 UI，不迁移各职业爆发判定逻辑）
    if PigSet["GLOBAL_BURST"] == nil then PigSet["GLOBAL_BURST"] = true end
    local burstCheckbox = CreateFrame("CheckButton", "WR_GlobalBurstCheckbox", globalRegion, "UICheckButtonTemplate")
    burstCheckbox:SetSize(20, 20)
    burstCheckbox:SetPoint("TOPLEFT", touyaoSlider, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    burstCheckbox:SetChecked(PigSet["GLOBAL_BURST"])
    burstCheckbox:SetScript("OnClick", function(self)
        PigSet["GLOBAL_BURST"] = self:GetChecked()
        local status = self:GetChecked() and "|cff00ff00开启|r" or "|cffff0000关闭|r"
        PrintToVisible(string.format("|cff00adf0[爆发]|r 全局爆发总闸: %s", status))
    end)
    burstCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("爆发总闸\n一键总开关：关闭后全局禁止自动爆发（各职业爆发总闸仍保留在右区）。\n开启则按各职业设置正常触发。")
        GameTooltip:Show()
    end)
    burstCheckbox:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    local burstLabel = globalRegion:CreateFontString(nil, "ARTWORK")
    burstLabel:SetFont(STANDARD_TEXT_FONT, 16, "")
    burstLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    burstLabel:SetText("爆发总闸")
    burstLabel:SetPoint("LEFT", burstCheckbox, "RIGHT", -2, 1)

    -- ★ 怪物屏蔽总开关 / 职业屏蔽（从功能设置面板迁至左侧全局面板，位于爆发总闸下方）
    -- 普通复选框形态，与「爆发总闸」「开关提示」一致；功能逻辑、状态存储、原有行为完全不变
    -- 启用怪物屏蔽：仍走 ZZ_SetMonsterBlock（写入 MONSTER_BLOCK_ENABLED + 打印 + 同步主控框）；/monster 命令亦同步本框
    if PigSet["MONSTER_BLOCK_ENABLED"] == nil then PigSet["MONSTER_BLOCK_ENABLED"] = false end
    local monsterChk = CreateFrame("CheckButton", "WR_MonsterBlockChk", globalRegion, "UICheckButtonTemplate")
    monsterChk:SetSize(20, 20)
    monsterChk:SetPoint("TOPLEFT", burstCheckbox, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    monsterChk:SetChecked(PigSet["MONSTER_BLOCK_ENABLED"])
    monsterChk:SetScript("OnClick", function(self)
        ZZ_SetMonsterBlock(self:GetChecked())
    end)
    monsterChk:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("启用怪物屏蔽\n勾选后按规则屏蔽指定怪物的目标选择。\n关闭总开关则全部不屏蔽。\n可用 /monster [on|off|toggle] 直接切换。")
        GameTooltip:Show()
    end)
    monsterChk:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    local monsterLabel = globalRegion:CreateFontString(nil, "ARTWORK")
    monsterLabel:SetFont(STANDARD_TEXT_FONT, 16, "")
    monsterLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    monsterLabel:SetText("启用怪物屏蔽")
    monsterLabel:SetPoint("LEFT", monsterChk, "RIGHT", -2, 1)
    ZZ_MonsterBlockMasterChk = monsterChk   -- 供 ZZ_SetMonsterBlock / /monster 命令同步勾选态（ZZ_Features_Migration.lua 引用，已改为全局）

    -- 职业屏蔽（近战AOE / 远程多线 / 坦克 三个独立子开关，保持各自控制，行为不变）
    if PigSet["MELEE_AOE_BLACKLIST"] == nil then PigSet["MELEE_AOE_BLACKLIST"] = true end
    if PigSet["RANGED_MULTILINE_BLACKLIST"] == nil then PigSet["RANGED_MULTILINE_BLACKLIST"] = true end
    if PigSet["TANK_BLACKLIST"] == nil then PigSet["TANK_BLACKLIST"] = false end

    local blTitle = globalRegion:CreateFontString(nil, "ARTWORK")
    blTitle:SetFont(STANDARD_TEXT_FONT, 14, "")
    blTitle:SetTextColor(classColor.r, classColor.g, classColor.b)
    blTitle:SetText("|cffffd700职业屏蔽|r")
    blTitle:SetPoint("TOPLEFT", monsterChk, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)

    local function MakeBLToggle(var, label)
        local chk = CreateFrame("CheckButton", nil, globalRegion, "UICheckButtonTemplate")
        chk:SetSize(20, 20)
        chk:SetChecked(PigSet[var])
        chk:SetScript("OnClick", function(self)
            PigSet[var] = self:GetChecked()
            local status = self:GetChecked() and "|cff00ff00开启|r" or "|cffff0000关闭|r"
            print(string.format("|cff00adf0[黑名单]|r %s: %s", label, status))
        end)
        chk:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label .. "\n勾选后，对应类型的单位将屏蔽名单内怪物。")
            GameTooltip:Show()
        end)
        chk:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
        local lbl = globalRegion:CreateFontString(nil, "ARTWORK")
        lbl:SetFont(STANDARD_TEXT_FONT, 16, "")
        lbl:SetTextColor(classColor.r, classColor.g, classColor.b)
        lbl:SetText(label)
        lbl:SetPoint("LEFT", chk, "RIGHT", -2, 1)
        return chk
    end

    local meleeBlChk = MakeBLToggle("MELEE_AOE_BLACKLIST", "近战AOE屏蔽")
    meleeBlChk:SetPoint("TOPLEFT", blTitle, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    local rangedBlChk = MakeBLToggle("RANGED_MULTILINE_BLACKLIST", "远程多线屏蔽")
    rangedBlChk:SetPoint("TOPLEFT", meleeBlChk, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    local tankBlChk = MakeBLToggle("TANK_BLACKLIST", "坦克屏蔽")
    tankBlChk:SetPoint("TOPLEFT", rangedBlChk, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)

    -- ★ 4. 开关提示（迁入左侧全局区，位于爆发总闸下方）
    local noticeCheckbox = CreateFrame("CheckButton", nil, globalRegion, "UICheckButtonTemplate")
    noticeCheckbox:SetSize(20, 20)
    noticeCheckbox:SetPoint("TOPLEFT", tankBlChk, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)

    local noticeLabel = noticeCheckbox:CreateFontString(nil, "ARTWORK")
    noticeLabel:SetFont(STANDARD_TEXT_FONT, 16, "")
    noticeLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    noticeLabel:SetText("开关提示")
    noticeLabel:SetPoint("LEFT", noticeCheckbox, "RIGHT", -2, 1)

    if PigSet["ChatNoticeMode"] == nil then PigSet["ChatNoticeMode"] = 2 end
    noticeCheckbox:SetChecked(PigSet["ChatNoticeMode"] ~= 0)
    noticeCheckbox:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        PigSet["ChatNoticeMode"] = isChecked and 2 or 0
        local statusText = isChecked and "|cff00ff00开启|r" or "|cffff0000关闭|r"
        print(string.format("|cff00ff00[MKHelperForever]|r 聊天窗口提示已%s。", statusText))
    end)
    noticeCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("开启或关闭技能开关时的聊天窗口提示。\n可通过 /pigchat 命令设置高级模式。")
        GameTooltip:Show()
    end)
    noticeCheckbox:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    -- ★ 2. 图标大小缩放滑块（迁入左侧全局区，位于「开关提示」复选框下方）
    local iconScaleSlider = CreateFrame("Slider", "WR_IconScaleSlider", globalRegion)
    iconScaleSlider:SetOrientation("HORIZONTAL")
    iconScaleSlider:SetWidth(GLOBAL_REGION_W - GLOBAL_INNER_PAD * 2 - 44)
    iconScaleSlider:SetHeight(10)
    -- 开关提示与图标大小缩放之间采用统一行高（GLOBAL_ROW_H），与其它控件保持一致的紧凑节奏
    iconScaleSlider:SetPoint("TOPLEFT", noticeCheckbox, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    iconScaleSlider:SetMinMaxValues(50, 200)
    iconScaleSlider:SetValueStep(1)
    iconScaleSlider:SetObeyStepOnDrag(true)

    -- 滑块组件（轨道、填充条、拇指）
    local iconTrack = iconScaleSlider:CreateTexture(nil, "BACKGROUND")
    iconTrack:SetTexture("Interface\\Buttons\\WHITE8x8")
    iconTrack:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    iconTrack:SetAllPoints()

    local iconBorder = iconScaleSlider:CreateTexture(nil, "BACKGROUND", nil, -1)
    iconBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
    iconBorder:SetVertexColor(0, 0, 0, 1)
    iconBorder:SetPoint("TOPLEFT", iconScaleSlider, "TOPLEFT", -1, 1)
    iconBorder:SetPoint("BOTTOMRIGHT", iconScaleSlider, "BOTTOMRIGHT", 1, -1)

    local iconFill = iconScaleSlider:CreateTexture(nil, "ARTWORK")
    iconFill:SetTexture("Interface\\Buttons\\WHITE8x8")
    iconFill:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.9)
    iconFill:SetPoint("TOPLEFT", iconScaleSlider, "TOPLEFT", 0, 0)
    iconFill:SetPoint("BOTTOMLEFT", iconScaleSlider, "BOTTOMLEFT", 0, 0)

    iconScaleSlider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local iconThumb = iconScaleSlider:GetThumbTexture()
    iconThumb:SetAlpha(0)

    -- 更新填充条
    local function UpdateIconScaleFill(val)
        local min, max = iconScaleSlider:GetMinMaxValues()
        local pct = (max > min) and ((val - min) / (max - min)) or 0
        if pct < 0 then pct = 0 end
        if pct > 1 then pct = 1 end
        local w = iconScaleSlider:GetWidth() * pct
        if w == 0 then w = 0.001 end
        iconFill:SetWidth(w)
    end

    if PigSet["IconScale"] == nil then PigSet["IconScale"] = 100 end
    iconScaleSlider:SetValue(PigSet["IconScale"])
    UpdateIconScaleFill(PigSet["IconScale"])

    -- 显示数值的文字
    local iconScaleText = iconScaleSlider:CreateFontString(nil, "ARTWORK")
    iconScaleText:SetFont(STANDARD_TEXT_FONT, 14, "")
    iconScaleText:SetTextColor(classColor.r, classColor.g, classColor.b)
    iconScaleText:SetPoint("LEFT", iconScaleSlider, "RIGHT", 8, 0)
    iconScaleText:SetText(PigSet["IconScale"] .. "%")

    local iconScaleLabel = iconScaleSlider:CreateFontString(nil, "ARTWORK")
    iconScaleLabel:SetFont(STANDARD_TEXT_FONT, 14, "")
    iconScaleLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    iconScaleLabel:SetPoint("BOTTOM", iconScaleSlider, "TOP", 0, 5)
    iconScaleLabel:SetText("图标大小缩放")

    -- 高亮和提示
    local iconScaleHighlight = iconScaleSlider:CreateTexture(nil, "HIGHLIGHT")
    iconScaleHighlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    iconScaleHighlight:SetBlendMode("ADD")
    iconScaleHighlight:SetAllPoints(iconScaleSlider)
    iconScaleHighlight:Hide()

    iconScaleSlider:SetScript("OnEnter", function(self)
        iconScaleHighlight:Show()
        iconScaleLabel:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("图标大小缩放\n调整技能图标显示大小。\n范围：50% - 200%\n\n|cff00adf0快捷命令：/run PigSet.IconScale=数值|r")
        GameTooltip:Show()
    end)
    iconScaleSlider:SetScript("OnLeave", function(self)
        iconScaleHighlight:Hide()
        iconScaleLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        GameTooltip:Hide()
    end)

    -- 应用缩放值并刷新UI
    -- ★ 2026-08-21 修复（v2）：拖动期间只更新数值 + 轻量视觉缩放（整体 SetScale），绝不重排面板。
    --   真正稳定化的关键点：WR_ApplyIconScale 检测到 _IconScaleAdjusting 时会跳过 WR_LayoutConfigFrame，
    --   因此主循环每 tick 的重排不会在拖动中发生，滑块映射不再被打乱（与窗口透明度滑块一样稳定）。
    local isIconScaleDragging = false
    local function ApplyIconScaleSlider(val, fullRefresh)
        PigSet["IconScale"] = val
        iconScaleText:SetText(val .. "%")
        UpdateIconScaleFill(val)
        if fullRefresh then
            -- 完整重排（面板尺寸稳定时调用：初始化 / 拖动结束 / 外部 SetValue）
            WR_RefreshConfigUI()
        else
            -- 拖动中：仅轻量视觉缩放（WR_ApplyIconScale 检测到 _IconScaleAdjusting 走 live，不重排）
            if WR_ApplyIconScale then WR_ApplyIconScale() end
        end
    end

    iconScaleSlider:SetScript("OnValueChanged", function(self, value)
        -- 拖动中 isIconScaleDragging=true → 轻量刷新；否则（SetValue/初始化）→ 完整刷新
        ApplyIconScaleSlider(math.floor(value + 0.5), not isIconScaleDragging)
    end)
    iconScaleSlider:SetScript("OnMouseDown", function(self)
        isIconScaleDragging = true
        -- 标记拖动中：让主循环每 tick 的 WR_ApplyIconScale 走 live 分支（只缩放不重排），滑块映射稳定
        PigSet["_IconScaleAdjusting"] = true
        self:SetScript("OnUpdate", function(slider)
            local val = math.floor(slider:GetValue() + 0.5)
            if val ~= PigSet["IconScale"] then
                ApplyIconScaleSlider(val, false)
            end
        end)
    end)
    iconScaleSlider:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
        isIconScaleDragging = false
        PigSet["_IconScaleAdjusting"] = nil
        -- 松手时统一做一次完整面板重排（此时尺寸稳定，不会再跳）
        ApplyIconScaleSlider(math.floor(self:GetValue() + 0.5), true)
    end)

    -- ★ 2026-08-21：图标缩放「数值填入框」—— 输入数值后实时更新图标大小。
    --   设计：输入期间只轻量视觉缩放（live，不重排面板，与窗口透明度滑块一样稳定），
    --   回车 / 失焦时把滑块值同步过去并做一次完整重排定稿；同时反向联动滑块与百分比文字。
    local function ClampIconScale(v)
        if type(v) ~= "number" then v = tonumber(v) end
        if not v or v ~= v then v = 100 end  -- NaN 兜底
        if v < 50 then v = 50 end
        if v > 200 then v = 200 end
        return math.floor(v + 0.5)
    end

    local iconScaleEdit = CreateFrame("EditBox", "WR_IconScaleEdit", globalRegion, "InputBoxTemplate")
    iconScaleEdit:SetSize(56, 22)
    iconScaleEdit:SetPoint("TOPLEFT", iconScaleSlider, "BOTTOMLEFT", 0, -GLOBAL_ROW_H + 2)
    iconScaleEdit:SetAutoFocus(false)
    iconScaleEdit:SetNumeric(true)
    iconScaleEdit:SetMaxLetters(3)
    iconScaleEdit:SetFont(STANDARD_TEXT_FONT, 14, "")
    iconScaleEdit:SetText(PigSet["IconScale"] or 100)
    iconScaleEdit:SetCursorPosition(0)

    local iconScaleEditLabel = iconScaleEdit:CreateFontString(nil, "ARTWORK")
    iconScaleEditLabel:SetFont(STANDARD_TEXT_FONT, 14, "")
    iconScaleEditLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    iconScaleEditLabel:SetPoint("LEFT", iconScaleEdit, "RIGHT", 8, 0)
    iconScaleEditLabel:SetText("%（直接输入数值）")

    -- 输入框旁的「应用」提示文字已由 label 说明，不再额外按钮，回车即实时应用
    local function SetIconScaleFromEdit(commit)
        local raw = iconScaleEdit:GetText()
        local v = ClampIconScale(raw)
        iconScaleEdit:SetText(v)  -- 归一化显示（去掉非法字符/越界夹紧）
        -- 联动滑块与百分比文字
        if math.floor(iconScaleSlider:GetValue() + 0.5) ~= v then
            iconScaleSlider:SetValue(v)  -- 触发 OnValueChanged：拖动标记 false → 完整刷新
        end
        iconScaleText:SetText(v .. "%")
        UpdateIconScaleFill(v)
        PigSet["IconScale"] = v
        -- 实时视觉缩放（live，不重排），保证手感与窗口透明度一致
        PigSet["_IconScaleAdjusting"] = true
        if WR_ApplyIconScale then WR_ApplyIconScale() end
        PigSet["_IconScaleAdjusting"] = nil
        if commit then
            -- 回车 / 失焦：完整重排定稿（尺寸稳定，不跳）
            WR_RefreshConfigUI()
        end
    end

    iconScaleEdit:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        SetIconScaleFromEdit(true)
    end)
    iconScaleEdit:SetScript("OnEscapePressed", function(self)
        -- 取消：恢复为当前 PigSet 值
        self:SetText(PigSet["IconScale"] or 100)
        self:ClearFocus()
    end)
    iconScaleEdit:SetScript("OnEditFocusLost", function(self)
        SetIconScaleFromEdit(true)
    end)
    iconScaleEdit:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    -- 输入过程中实时联动（每字符变化即轻量更新，不做完整重排，避免抖动）
    iconScaleEdit:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local raw = self:GetText()
        local v = tonumber(raw)
        if not v or v ~= v then return end
        v = ClampIconScale(v)
        iconScaleText:SetText(v .. "%")
        UpdateIconScaleFill(v)
        PigSet["IconScale"] = v
        PigSet["_IconScaleAdjusting"] = true
        if WR_ApplyIconScale then WR_ApplyIconScale() end
        PigSet["_IconScaleAdjusting"] = nil
    end)

    -- ★ 3. 窗口透明度滑块（迁入左侧全局区，位于图标缩放下方）
    local alphaSlider = CreateFrame("Slider", "WR_AlphaSlider", globalRegion)
    alphaSlider:SetOrientation("HORIZONTAL")
    alphaSlider:SetWidth(GLOBAL_REGION_W - GLOBAL_INNER_PAD * 2 - 44)
    alphaSlider:SetHeight(10)
    -- ★ 2026-08-21 修复：填入框（iconScaleEdit）占据图标缩放滑块下方一行，
    --   窗口透明度滑块改为锚定填入框底部，使其及下方所有内容整体下移，避免重叠。
    alphaSlider:SetPoint("TOPLEFT", iconScaleEdit, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    alphaSlider:SetMinMaxValues(10, 100)
    alphaSlider:SetValueStep(1)
    alphaSlider:SetObeyStepOnDrag(true)

    -- 组件
    local track = alphaSlider:CreateTexture(nil, "BACKGROUND")
    track:SetTexture("Interface\\Buttons\\WHITE8x8")
    track:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    track:SetAllPoints()

    local border = alphaSlider:CreateTexture(nil, "BACKGROUND", nil, -1)
    border:SetTexture("Interface\\Buttons\\WHITE8x8")
    border:SetVertexColor(0, 0, 0, 1)
    border:SetPoint("TOPLEFT", alphaSlider, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", alphaSlider, "BOTTOMRIGHT", 1, -1)

    local fill = alphaSlider:CreateTexture(nil, "ARTWORK")
    fill:SetTexture("Interface\\Buttons\\WHITE8x8")
    fill:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.9)
    fill:SetPoint("TOPLEFT", alphaSlider, "TOPLEFT", 0, 0)
    fill:SetPoint("BOTTOMLEFT", alphaSlider, "BOTTOMLEFT", 0, 0)

    alphaSlider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = alphaSlider:GetThumbTexture()
    thumb:SetAlpha(0)

    -- 更新填充条
    local function UpdateAlphaFill(val)
        local min, max = alphaSlider:GetMinMaxValues()
        local pct = (max > min) and ((val - min) / (max - min)) or 0
        if pct < 0 then pct = 0 end
        if pct > 1 then pct = 1 end
        local w = alphaSlider:GetWidth() * pct
        if w == 0 then w = 0.001 end
        fill:SetWidth(w)
    end

    -- 设置窗口背景透明度（只对背景层）
    local function UpdateBgAlpha(alphaValue)
        local alpha = alphaValue / 100
        for _, region in ipairs({ configFrame:GetRegions() }) do
            if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
                region:SetAlpha(alpha)
            end
        end
    end

    if PigSet["FrameAlpha"] == nil then PigSet["FrameAlpha"] = 100 end
    alphaSlider:SetValue(PigSet["FrameAlpha"])
    UpdateBgAlpha(PigSet["FrameAlpha"])
    UpdateAlphaFill(PigSet["FrameAlpha"])

    local alphaText = alphaSlider:CreateFontString(nil, "ARTWORK")
    alphaText:SetFont(STANDARD_TEXT_FONT, 14, "")
    alphaText:SetTextColor(classColor.r, classColor.g, classColor.b)
    alphaText:SetPoint("LEFT", alphaSlider, "RIGHT", 8, 0)
    alphaText:SetText(PigSet["FrameAlpha"] .. "%")

    local alphaLabel = alphaSlider:CreateFontString(nil, "ARTWORK")
    alphaLabel:SetFont(STANDARD_TEXT_FONT, 14, "")
    alphaLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    alphaLabel:SetPoint("BOTTOM", alphaSlider, "TOP", 0, 5)
    alphaLabel:SetText("窗口透明度")

    local alphaHighlight = alphaSlider:CreateTexture(nil, "HIGHLIGHT")
    alphaHighlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    alphaHighlight:SetBlendMode("ADD")
    alphaHighlight:SetAllPoints(alphaSlider)
    alphaHighlight:Hide()

    alphaSlider:SetScript("OnEnter", function(self)
        alphaHighlight:Show()
        alphaLabel:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("窗口透明度\n调整配置窗口背景透明度。\n范围：10% - 100%\n\n|cff00adf0快捷命令：/run PigSet.FrameAlpha=数值|r")
        GameTooltip:Show()
    end)
    alphaSlider:SetScript("OnLeave", function(self)
        alphaHighlight:Hide()
        alphaLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        GameTooltip:Hide()
    end)

    alphaSlider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value + 0.5)
        PigSet["FrameAlpha"] = val
        UpdateBgAlpha(val)
        alphaText:SetText(val .. "%")
        UpdateAlphaFill(val)
    end)

    -- 将「自动跟随」整体移到左区最底部（窗口透明度滑块下方），跟随下拉框置于跟随复选框下方
    followCheckbox:ClearAllPoints()
    followCheckbox:SetPoint("TOPLEFT", alphaSlider, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    followDropdown:ClearAllPoints()
    -- ★ 跟随下拉框与「跟随」复选框左侧严格对齐，下方留 GLOBAL_ROW_H 标准行距（与创建处一致，避免被此处重新布局覆盖回旧值）
    followDropdown:SetPoint("TOPLEFT", followCheckbox, "BOTTOMLEFT", 0, -GLOBAL_ROW_H)
    -- ★ 强制锁死紧凑高度（兜底，确保最终布局后左区下拉框高度 = WR_DROPDOWN_H，不被原生重建覆盖）
    followDropdown:SetHeight(WR_DROPDOWN_H)
    -- 同步把「界面缩放」行锚点也重新固定一遍，确保它严格位于下拉框下方 GLOBAL_ROW_H 处，不被旧锚点拖偏
    if uiScaleLabel then
        uiScaleLabel:ClearAllPoints()
        uiScaleLabel:SetPoint("TOPLEFT", followDropdown, "BOTTOMLEFT", 16, -GLOBAL_ROW_H)
    end

    -- 应用左区全局折叠初始状态（含智能AOE 子区块定位）；WR_LayoutGlobal 内部在展开时再调 AOE 布局
    if WR_LayoutGlobal then WR_LayoutGlobal() end

    -- 右下角整体缩放手柄（等比缩放整个框架，含文字与控件一起放大/缩小）
    local scaleGrabber = CreateFrame("Button", nil, configFrame)
    scaleGrabber:SetSize(18, 18)
    scaleGrabber:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -1, 1)
    scaleGrabber:SetFrameLevel(configFrame:GetFrameLevel() + 10)
    scaleGrabber:SetNormalTexture("Interface\Buttons\UI-AutoCastableOverlay")
    local sgTex = scaleGrabber:GetNormalTexture()
    if sgTex then sgTex:SetTexCoord(0, 0.5, 0, 0.5) end
    scaleGrabber:SetHighlightTexture("Interface\Buttons\UI-AutoCastableOverlay", "ADD")
    scaleGrabber:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("拖动等比缩放整个窗口（含文字与控件一起放大/缩小，0.5x~2x）")
        GameTooltip:Show()
    end)
    scaleGrabber:SetScript("OnLeave", function() GameTooltip:Hide() end)
    scaleGrabber:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local startX, startY = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()
        local startScale = configFrame:GetScale()
        local baseW = configFrame:GetWidth() / startScale
        local baseH = configFrame:GetHeight() / startScale
        local avgBase = (baseW + baseH) / 2
        if avgBase < 1 then avgBase = 1 end
        self.scaleState = { startX = startX, startY = startY, startScale = startScale, uiScale = uiScale, avgBase = avgBase }
        configFrame:SetScript("OnUpdate", function()
            local st = self.scaleState
            if not st then return end
            if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
                self:GetScript("OnMouseUp")(self, "LeftButton")
                return
            end
            local curX, curY = GetCursorPosition()
            -- 屏幕像素增量换算为布局像素（除以当前 scale * uiScale）
            local dx = (curX - st.startX) / (st.uiScale * st.startScale)
            local dy = (curY - st.startY) / (st.uiScale * st.startScale)
            -- 右下角向外拖（dx>0, dy<0）放大；向内拖缩小
            local delta = (dx - dy) / 2
            local newScale = st.startScale * (st.avgBase + delta) / st.avgBase
            if newScale < 0.5 then newScale = 0.5 end
            if newScale > 2.0 then newScale = 2.0 end
            configFrame:SetScale(newScale)
            PigSet["FrameScale"] = newScale
        end)
    end)
    scaleGrabber:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" then return end
        configFrame:SetScript("OnUpdate", nil)
        self.scaleState = nil
    end)

    -- 右侧拖拽调整宽度（仅水平）
    local rightSizer = CreateFrame("Frame", nil, configFrame)
    rightSizer:EnableMouse(true)
    rightSizer:SetWidth(12)
    rightSizer:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", 0, -22)
    rightSizer:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", 0, 18)

    local rightSizerEdge = rightSizer:CreateTexture(nil, "ARTWORK")
    rightSizerEdge:SetColorTexture(1, 1, 1, 0)
    rightSizerEdge:SetPoint("TOP", rightSizer, "TOP", 0, 0)
    rightSizerEdge:SetPoint("BOTTOM", rightSizer, "BOTTOM", 0, 0)
    rightSizerEdge:SetPoint("RIGHT", rightSizer, "RIGHT", 0, 0)
    rightSizerEdge:SetWidth(2)

    rightSizer:SetScript("OnEnter", function()
        rightSizerEdge:SetColorTexture(1, 1, 1, 0.2)
        GameTooltip:SetOwner(rightSizer, "ANCHOR_LEFT")
        GameTooltip:SetText("拖动调整宽度")
        GameTooltip:Show()
    end)
    rightSizer:SetScript("OnLeave", function()
        if configFrame.resizeState then return end
        rightSizerEdge:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
        ClearHorizontalResizeCursor(rightSizer)
    end)
    rightSizer:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then BeginConfigFrameResize(configFrame, self, true) end
    end)
    rightSizer:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then EndConfigFrameResize(configFrame, self) end
    end)


    -- 左下角切换按钮（显示/隐藏配置界面）
    local frame = CreateFrame("Button", "WR_ClickFrame", UIParent, "UIPanelButtonTemplate")
    frame:SetSize(25, 25)
    frame:SetPoint("BOTTOMLEFT", 0, 0)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(frame)
    texture:SetTexture("Interface\\AddOns\\MKHelperForever\\MKHelperForever.tga")

    frame:SetScript("OnClick", function(self, button, down)
        if configFrame:IsShown() then
            configFrame:Hide()
        else
            configFrame:Show()
            WR_RefreshConfigUI()
        end
    end)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("MKHelperForever\n点击打开/关闭配置面板\n\n|cff00adf0快捷命令：/pigconfig 或 /pigcfg|r\n|cff00adf0重新加载：/reload|r")
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    frame:Show()

    _G.PIG_RtLibTitleOk = true
    if type(PIG_RtUiCaptionHash) == "number" and PIG_RtUiCaptionHash ~= 0 then
        _G.PIG_RtLiveCaptionStamp = PIG_RtUiCaptionHash
    end

    -- 定时器确保标题不被篡改（每1秒检查）
    if C_Timer and C_Timer.NewTicker then
        C_Timer.NewTicker(1, function()
            if WR_ConfigFrame == nil or WR_ConfigFrame.title == nil or WR_ConfigFrame.title.GetText == nil then
                return
            end
            if WR_ConfigFrame.title:GetText() ~= PIG_UI_PANEL_TITLE then
                WR_ConfigFrame.title:SetText(PIG_UI_PANEL_TITLE)
            end
            if type(PIG_HashUiCaption) == "function" and type(PIG_GetUiCaptionPlain) == "function" then
                local liveHash = PIG_HashUiCaption(PIG_GetUiCaptionPlain())
                if liveHash ~= 0 then
                    _G.PIG_RtLiveCaptionStamp = liveHash
                end
            end
        end)
    end

    WR_DK = 1
    WR_ConfigIsOK = true

    -- ★ 2026-08-21：/reload 时自动应用保存的界面缩放
    configFrame:SetScale(PigSet["FrameScale"] or 1)
end

-- ============================================================
-- 对外接口
-- ============================================================
function WR_CreateConfigFrame()
    ConfigFrame()
    return WR_ConfigFrame
end

function WR_CreateTalentFrame(DM_List, CB_List, specName)
    return CreateTalentFrame(DM_List, CB_List, specName)
end

function WR_SetActiveTalentDropdowns(talentFrame)
    WR_SetActiveDropdowns(talentFrame)
end

-- 聊天提示模式切换（斜杠命令 /pigchat）
SLASH_PIGCHAT1 = "/pigchat"
SlashCmdList["PIGCHAT"] = function(msg)
    msg = strtrim(strlower(msg or ""))
    if msg == "0" or msg == "off" then
        PigSet["ChatNoticeMode"] = 0
        print("|cff00ff00[MKHelperForever]|r 开关提示已完全|cffff0000关闭|r。")
    elseif msg == "1" then
        PigSet["ChatNoticeMode"] = 1
        print("|cff00ff00[MKHelperForever]|r 开关提示现在只显示在|cffffd700默认聊天框|r。")
    elseif msg == "2" or msg == "on" then
        PigSet["ChatNoticeMode"] = 2
        print("|cff00ff00[MKHelperForever]|r 开关提示现在显示在|cff00ff00所有可见的聊天框|r。")
    else
        local current = PigSet["ChatNoticeMode"]
        if current == nil then current = 2 end
        if current == 2 then
            PigSet["ChatNoticeMode"] = 1
            print("|cff00ff00[MKHelperForever]|r 开关提示现在只显示在|cffffd700默认聊天框|r。")
        elseif current == 1 then
            PigSet["ChatNoticeMode"] = 0
            print("|cff00ff00[MKHelperForever]|r 开关提示已完全|cffff0000关闭|r。")
        else
            PigSet["ChatNoticeMode"] = 2
            print("|cff00ff00[MKHelperForever]|r 开关提示现在显示在|cff00ff00所有可见的聊天框|r。")
        end
        print("可用命令: /pigchat 0(关闭), /pigchat 1(默认窗口), /pigchat 2(全部可见窗口)")
    end
end