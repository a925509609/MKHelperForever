-- ============================================================
-- Core_Functions.lua
-- 核心函数库（兼容怀旧服/正式服）
-- 包含：API兼容层、全局数据表、帧级缓存系统、光环获取、
--       战斗判断、装备物品、目标过滤、施法信息、坦克减伤、
--       范围计数、无敌检测、WCL黑名单、COMBAT_LOG分发等
-- 已拆分：治疗权重系统 → Utils_HealerWeight.lua
--       死亡预测/杂项 → Utils_DeathTime.lua
-- ============================================================

-- ★ 2026-08-21：把任意 ScrollFrame（UIPanelScrollFrameTemplate）的滚动条底色统一设为黑色
--   用于各弹窗（爆发列表/怪物屏蔽/命令清单/更新公告等右侧框架）的滚动条，
--   使其与左区自定义滑块的深色风格一致。调用时机：ScrollFrame 创建后。
function WR_StyleScrollBarBlack(scrollFrame)
    if not scrollFrame then return end
    local sb = scrollFrame.ScrollBar
    if not sb and scrollFrame.GetScrollBar then
        sb = scrollFrame:GetScrollBar()
    end
    if not sb then return end
    -- 覆盖一个黑色 BACKGROUND 纹理（置于原模板背景之上）
    local bg = sb:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0, 0, 0, 0.85)
    bg:SetAllPoints(sb)
end

-- ============================================================
-- ★ 2026-08-21：下拉框紧凑高度常量（=下拉框最终视觉高度，单位px）
--   所有经过 WR_StyleDropdownFlat 的下拉框最终都被锁定为此高度。
-- ============================================================
WR_DROPDOWN_H = 16

-- 扁平化 UIDropDownMenuTemplate 下拉框：去掉外框边缘，保留文字和箭头
-- ★ 2026-08-21：用户要求取消所有下拉框的框架边缘，并对齐上方控件
function WR_StyleDropdownFlat(dropdown)
    if not dropdown then return end
    local name = dropdown:GetName()
    if not name then return end
    -- 标记：该下拉框已被我们样式化，供下方 hook 的 UIDropDownMenu_SetWidth 识别并补高度
    dropdown.WR_styled = true
    local left = _G[name .. "Left"]
    local middle = _G[name .. "Middle"]
    local right = _G[name .. "Right"]
    if left then left:Hide() end
    if middle then middle:Hide() end
    if right then right:Hide() end

    -- 模板自带的鼠标悬停高亮层（name.."Highlight"）默认按 32px 高度创建，
    -- 悬停时显示会比 14px 的框高出一截。强制让其贴合下拉框四边，高度与框一致。
    local hl = _G[name .. "Highlight"]
    if hl then
        hl:ClearAllPoints()
        hl:SetAllPoints(dropdown)
    end

    -- ★ 2026-08-21：先压缩下拉框高度到 WR_DROPDOWN_H（=16px，框体仅包住文字），
    --   再创建 flatBg / flatBorder。避免先创建背景/边框时按默认32px锚定，
    --   导致后续 SetHeight 后灰色背景底仍按原高度渲染、超出黑线边框。
    dropdown:SetHeight(WR_DROPDOWN_H)
    -- 最强兜底：一旦其他代码（UIDropDownMenu_Initialize / UIDropDownMenu_SetWidth 等）
    -- 把高度改回默认值，立即自动弹回 WR_DROPDOWN_H，确保视觉高度不再被撑开。
    dropdown:SetScript("OnSizeChanged", function(self)
        if not self.WR_lockingH and self:GetHeight() ~= WR_DROPDOWN_H then
            self.WR_lockingH = true
            self:SetHeight(WR_DROPDOWN_H)
            self.WR_lockingH = nil
        end
    end)

    -- 保留下拉箭头，但替换为更简洁的向下箭头纹理，去掉自带背景
    local btn = _G[name .. "Button"]
    if btn then
        local function clearTex(t)
            if t then t:SetTexture(nil) end
        end
        clearTex(btn:GetNormalTexture())
        clearTex(btn:GetPushedTexture())
        clearTex(btn:GetDisabledTexture())
        clearTex(btn:GetHighlightTexture())
        -- 使用聊天窗口下拉箭头，无框
        btn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        btn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
        btn:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
        btn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Highlight", "ADD")
        btn:ClearAllPoints()
        btn:SetPoint("RIGHT", dropdown, "RIGHT", -2, 0)
        btn:SetSize(12, 12)
    end

    -- 文字直接左对齐在下拉框内，不再依赖被隐藏的 Middle 纹理
    local text = _G[name .. "Text"]
    if text then
        text:ClearAllPoints()
        text:SetPoint("LEFT", dropdown, "LEFT", 4, 0)
        text:SetPoint("RIGHT", btn or dropdown, btn and "LEFT" or "RIGHT", btn and -2 or 0, 0)
        text:SetJustifyH("LEFT")
        text:SetFont(STANDARD_TEXT_FONT, 14, "")
        text:SetTextColor(1, 1, 1, 1)
        text:SetAlpha(1)
        text:Show()
    end

    -- 给下拉框加一层极淡的扁平背景，保证文字可读且无立体边框
    if not dropdown.flatBg then
        local flatBg = dropdown:CreateTexture(nil, "BACKGROUND")
        flatBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        flatBg:SetVertexColor(0.12, 0.12, 0.12, 0.65)
        flatBg:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, 0)
        flatBg:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", 0, 0)
        dropdown.flatBg = flatBg
    else
        dropdown.flatBg:Show()
    end

    -- 添加黑色 1px 细线边框（替代原模板的立体外框）
    if not dropdown.flatBorder then
        local border = {}
        local function addEdge(pointA, relA, pointB, relB, height)
            local t = dropdown:CreateTexture(nil, "BORDER")
            t:SetTexture("Interface\\Buttons\\WHITE8x8")
            t:SetVertexColor(0, 0, 0, 0.9)
            t:SetPoint(pointA, dropdown, relA, 0, 0)
            t:SetPoint(pointB, dropdown, relB, 0, 0)
            if height then
                t:SetHeight(height)
            else
                t:SetWidth(height or 1)
            end
            return t
        end
        border.top    = addEdge("TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", 1)
        border.bottom = addEdge("BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", 1)
        border.left   = addEdge("TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", nil)
        border.right  = addEdge("TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", nil)
        dropdown.flatBorder = border
    end
end

-- ============================================================
-- ★ API兼容性适配
-- ============================================================
if not IsSpellInRange then
    IsSpellInRange = C_Spell.IsSpellInRange
end
if not WR_SIR then
    WR_SIR = C_Spell.IsSpellInRange
end
if not WR_PS then
    WR_PS = IsPlayerSpell
end
if not GetSpellCount then
    GetSpellCount = C_Spell.GetSpellCastCount
end
if not GetSpellLink then
    GetSpellLink = C_Spell.GetSpellLink
end
if not IsUsableSpell then
    IsUsableSpell = C_Spell.IsSpellUsable
end
if not GetSpellInfo then
    GetSpellInfo = function(spellID)
        if not spellID then return nil end
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime,
                   spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID,
                   spellInfo.originalIconID
        end
    end
end
-- ★ 无限适配：1.60.x 已移除全局 IsCurrentSpell（多职业旋转的"自动攻击"分支
--   会直接 attempt to call a nil value）。用 C_Spell.IsCurrentSpell 兼容：
--   名字先解析成 spellID；再退化为比较当前施法/引导名称（secret 值一律按不匹配）。
if type(IsCurrentSpell) ~= "function" then
    IsCurrentSpell = function(spell)
        -- ★ 自动攻击特例：客户端读不到真实"自动攻击进行中"状态。
        --   战斗中按“已激活”处理，避免「自动攻击」分支每 tick 抢占后续技能循环；
        --   非战斗返回 false，保留开怪前的攻击提示。
        if spell == "攻击" or spell == "Attack" or spell == 6603 then
            local okC, inC = pcall(UnitAffectingCombat, "player")
            if okC and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(inC)) then
                return inC == true
            end
            return false
        end
        if type(C_Spell) == "table" and type(C_Spell.IsCurrentSpell) == "function" then
            local key = spell
            if type(spell) == "string" and type(WR_ResolveSpellID) == "function" then
                key = WR_ResolveSpellID(spell) or spell
            end
            local ok, res = pcall(C_Spell.IsCurrentSpell, key)
            if ok and res ~= nil and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(res)) then
                return res and true or false
            end
        end
        if type(spell) == "string" then
            local function SameName(cur)
                if type(cur) ~= "string" then return false end
                if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(cur) then return false end
                return cur == spell
            end
            if type(UnitCastingInfo) == "function" then
                local okC, cur = pcall(UnitCastingInfo, "player")
                if okC and SameName(cur) then return true end
            end
            if type(UnitChannelInfo) == "function" then
                local okH, cur = pcall(UnitChannelInfo, "player")
                if okH and SameName(cur) then return true end
            end
        end
        return false
    end
end

-- ============================================================
-- ★ 数据表初始化（仅在本文件内使用的改为 local）
-- ============================================================
local PartyRange = {}
local RiadRange = {}
local PartyLostHealth = {}
local RiadLostHealth = {}
PlayerLostHealth = 0  -- 跨文件共享（牧师治疗模块也使用）
local TrainingName = {}
local OutburstDebuff = {}
local PartyOutburstDebuff = {}
local NecroblastName = {}
local MustHealSpellName = {}
local AssistDebuffName = {}
local DangerDebuff = {}
local OutburstAoe = {}
local OutburstCasting = {}
local SustainedAoe = {}
local SustainedDebuff = {}
local SustainedBuff = {}
local DangerOutburstAoe = {}
local DangerSustainedAoe = {}
local QZWY_AOE_Name = {}
local QZWY_Spell_Name = {}
local DangerSpellToMe = {}
local DontTabUnitName = {}
local DontDotUnitName = {}
local DontStunUnitName = {}
local InvincibleUnitName = {}
local CrazyBuff = {}
local StunCastName = {}
local StunChannelName = {}
local SpeedUpSpellName = {}
local TankResist_SmallMagicToMe = {}
local TankResist_BigMagicToMe = {}
local TankResist_SmallPhysicalToMe = {}
local TankResist_BigPhysicalToMe = {}
local TankResist_SmallMagicToAoe = {}
local TankResist_BigMagicToAoe = {}
local TankResist_SmallPhysicalToAoe = {}
local TankResist_BigPhysicalToAoe = {}
local AOE_List = {}
local Spell_List = {}

-- ============================================================
-- ★ 帧级缓存系统（性能优化核心 - 懒加载模式）
-- 按需扫描，仅在首次查询时才扫描该单位/nameplate
-- ============================================================
local WR_FrameTime = 0
WR_AuraCache = {}
WR_AuraCacheScanned = {}
WR_NameplateCache = {}
WR_NameplateScanned = false
local WR_FrameState = {}

-- ============================================================
-- ★ P0 性能优化：光环缓存事件驱动失效 + 兜底刷新
--   原逻辑每 tick（≈0.05~0.1s）全 wipe(WR_AuraCacheScanned)，导致所有被访问单位
--   每 0.1s 重扫 40 buff + 40 debuff（每单位 80 次 API 调用），CPU 居高不下。
--   新方案：UNIT_AURA / UNIT_TARGET / 目标焦点切换事件即时把对应单位标记未扫描，
--   未变化的单位直接命中缓存；兜底每 0.5s 全刷新一次防漏刷。名牌缓存每 0.3s 兜底刷新。
-- ============================================================
local WR_AuraFullRefreshCycle = 0.5
local WR_NameplateRefreshCycle = 0.3
local WR_LastAuraFullRefresh = 0
local WR_LastNameplateRefresh = 0
local WR_LastCacheCleanup = 0
local WR_AuraEventFrame = nil

local function WR_InvalidateAuraUnit(unit)
    if unit then WR_AuraCacheScanned[unit] = false end
end

if not WR_AuraEventFrame then
    WR_AuraEventFrame = CreateFrame("Frame")
    WR_AuraEventFrame:RegisterEvent("UNIT_AURA")
    WR_AuraEventFrame:RegisterEvent("UNIT_TARGET")
    WR_AuraEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    WR_AuraEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    WR_AuraEventFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "UNIT_AURA" then
            WR_InvalidateAuraUnit(unit)
            if unit then WR_InvalidateAuraUnit(unit .. "target") end
        elseif event == "UNIT_TARGET" then
            WR_InvalidateAuraUnit(unit)
            if unit then WR_InvalidateAuraUnit(unit .. "target") end
        elseif event == "PLAYER_TARGET_CHANGED" then
            WR_InvalidateAuraUnit("target")
            WR_InvalidateAuraUnit("targettarget")
        elseif event == "PLAYER_FOCUS_CHANGED" then
            WR_InvalidateAuraUnit("focus")
            WR_InvalidateAuraUnit("focustarget")
        end
    end)
end

local function WR_ScanAurasForUnit(unit)
    local HELPFUL = {}
    local HARMFUL = {}

    if not UnitExists(unit) then
        WR_AuraCache[unit] = nil
        WR_AuraCacheScanned[unit] = true
        return
    end

    -- ★ 无限适配：战斗中 target/名牌/焦点 等单位的 aura 会变成 secret 值，
    --   此时 C_UnitAuras.GetAuraDataByIndex 抛
    --   "Auras cannot be accessed when secret"（执行路径被 taint 时必现）。
    --   把两遍扫描整体包进 pcall：一旦命中 secret 单位直接放弃本次扫描，
    --   保留上一次缓存（可能为 nil），并始终标记「已扫描」避免每 tick 重试刷屏。
    --   非战斗 / 可读单位照常填充，行为不变。
    local function doScan()
        for i = 1, 40 do
            local name, count, dispelType, expirationTime, source, spellId
            local data
            if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
                data = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
            end
            if data then
                name = data.name
                count = data.applications
                expirationTime = data.expirationTime
                source = data.sourceUnit
                spellId = data.spellId
                HELPFUL[#HELPFUL + 1] = {
                    name = name, count = count or 1,
                    expirationTime = expirationTime or 999,
                    source = source, spellId = spellId,
                    dispelType = data.dispelName
                }
            else
                -- ★ 无限适配：C_UnitAuras 取完后不再回退旧 API；若旧 API 已被
                --   移除则直接 break，避免每 tick 报 attempt to call a nil value
                if type(UnitBuff) ~= "function" then break end
                name, _, count, dispelType, _, expirationTime, source, _, _, spellId = UnitBuff(unit, i)
                if not name then break end
                HELPFUL[#HELPFUL + 1] = {
                    name = name, count = count or 1,
                    expirationTime = expirationTime or 999,
                    source = source, spellId = spellId,
                    dispelType = dispelType
                }
            end
        end

        for i = 1, 40 do
            local name, count, dispelType, expirationTime, source, spellId
            local data
            if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
                data = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
            end
            if data then
                name = data.name
                count = data.applications
                expirationTime = data.expirationTime
                source = data.sourceUnit
                spellId = data.spellId
                HARMFUL[#HARMFUL + 1] = {
                    name = name, count = count or 1,
                    expirationTime = expirationTime or 999,
                    source = source, spellId = spellId,
                    dispelType = data.dispelName
                }
            else
                -- ★ 无限适配：同上，旧 API 被移除时直接 break，不做无效回退
                if type(UnitDebuff) ~= "function" then break end
                name, _, count, dispelType, _, expirationTime, source, _, _, spellId = UnitDebuff(unit, i)
                if not name then break end
                HARMFUL[#HARMFUL + 1] = {
                    name = name, count = count or 1,
                    expirationTime = expirationTime or 999,
                    source = source, spellId = spellId,
                    dispelType = dispelType
                }
            end
        end
    end

    local ok = pcall(doScan)
    if ok then
        WR_AuraCache[unit] = { HELPFUL = HELPFUL, HARMFUL = HARMFUL }
    end
    -- 无论成功与否都标记已扫描；secret 单位读取失败也不重试，避免刷屏。
    WR_AuraCacheScanned[unit] = true
end

function WR_EnsureAuraCached(unit)
    if not WR_AuraCacheScanned[unit] then
        WR_ScanAurasForUnit(unit)
    end
end

function WR_ForceRefreshAuraCache(unit)
    WR_AuraCacheScanned[unit] = false
    WR_ScanAurasForUnit(unit)
end

local function WR_ScanNameplates()
    -- ★ B-2：非战斗时不扫名牌（名牌主要用于战斗中识别敌方施法/血量），
    --   省去无谓的 40 名牌 × 多次 API 调用；标记已扫避免无意义重试。
    if not UnitAffectingCombat("player") and not UnitAffectingCombat("target") then
        WR_NameplateScanned = true
        return
    end
    for i = 1, 40 do
        local unit = "nameplate" .. i
        local entry = {}
        local exists = UnitExists(unit)

        if not exists then
            WR_NameplateCache[i] = nil
        else
            entry.name = UnitName(unit)
            entry.unit = unit
            entry.canAttack = UnitCanAttack("player", unit)
            entry.isPlayer = UnitIsPlayer(unit)
            entry.isDead = UnitIsDead(unit)
            entry.inCombat = UnitAffectingCombat(unit)
            entry.isHostile = entry.canAttack
            entry.creatureType = UnitCreatureType(unit)
            entry.range = WR_UnitRange(unit)

            if entry.canAttack then
                entry.healthPercent = WR_GetUnitHP(unit)
            end

            local cName, _, _, cStart, cEnd, _, _, _, cSpellId = UnitCastingInfo(unit)
            if cName then
                entry.castingName = cName
                entry.castingSpellId = cSpellId
                entry.castingEndTime = cEnd and cEnd / 1000 or 0
                entry.castingRemaining = cEnd and cEnd / 1000 - GetTime() or 0
                entry.isChanneled = false
            else
                cName, _, _, cStart, cEnd, _, _, _, cSpellId = UnitChannelInfo(unit)
                if cName then
                    entry.castingName = cName
                    entry.castingSpellId = cSpellId
                    entry.castingEndTime = cEnd and cEnd / 1000 or 0
                    entry.castingRemaining = cEnd and cEnd / 1000 - GetTime() or 0
                    entry.isChanneled = true
                end
            end

            entry.targetName = UnitName(unit .. "target")
            if unit .. "target" and UnitIsUnit(unit .. "target", "player") then
                entry.targetIsPlayer = true
            end

            WR_NameplateCache[i] = entry
        end
    end
    WR_NameplateScanned = true
end

function WR_EnsureNameplatesCached()
    if not WR_NameplateScanned then
        WR_ScanNameplates()
    end
end

function WR_UpdateFrameState()
    local now = GetTime()
    if now - WR_FrameTime < 0.05 then
        return
    end
    WR_FrameTime = now

    -- ★ P0 性能优化：不再每 tick 全 wipe 光环缓存。
    --   光环变化由 UNIT_AURA 等事件即时失效（WR_AuraCacheScanned[unit]=false），
    --   未变化的单位直接命中缓存；兜底每 0.5s 全刷新一次防漏刷。
    if now - WR_LastAuraFullRefresh > WR_AuraFullRefreshCycle then
        wipe(WR_AuraCacheScanned)
        WR_LastAuraFullRefresh = now
    end
    if now - WR_LastNameplateRefresh > WR_NameplateRefreshCycle then
        WR_NameplateScanned = false
        WR_LastNameplateRefresh = now
    end

    -- ★ B-1：缓存残留清理（每 30s 一次）。团本中 raid/party target 等动态 token
    --   离开后不会被再次访问，其 aura 缓存条目会永久残留导致内存膨胀；此处统一收割。
    --   标准 token(player/target/focus/mouseover/pet) 由 WR_ScanAurasForUnit 自行清理，不在收割范围。
    if now - WR_LastCacheCleanup > 30 then
        WR_LastCacheCleanup = now
        for k in pairs(WR_AuraCache) do
            if k ~= "player" and k ~= "target" and k ~= "focus" and k ~= "mouseover" and k ~= "pet" then
                if not UnitExists(k) then
                    WR_AuraCache[k] = nil
                    WR_AuraCacheScanned[k] = nil
                end
            end
        end
        for i = 1, 40 do
            if not UnitExists("nameplate" .. i) then
                WR_NameplateCache[i] = nil
            end
        end
    end

    WR_FrameState.playerHP = WR_SafeUnitHealth("player")
    WR_FrameState.playerHPMax = WR_SafeUnitMaxHealth("player")
    WR_FrameState.playerHPPct = WR_SafeHPPct("player")
    WR_FrameState.playerMP = WR_SafeUnitPower("player", Enum.PowerType.Mana)
    WR_FrameState.playerMPMax = WR_SafeUnitPowerMax("player", Enum.PowerType.Mana)
    WR_FrameState.playerMoving = WR_PlayerMove()
    -- 施法名 / 施法结束时间在 12.x 亦可能为 secret，先检测再比较
    local castName = UnitCastingInfo("player")
    WR_FrameState.playerIsCasting = WR_IsSecretValue(castName) or castName ~= nil
    local channelName = UnitChannelInfo("player")
    WR_FrameState.playerIsChanneling = WR_IsSecretValue(channelName) or channelName ~= nil
    WR_FrameState.playerCastingEnd = WR_SafeNumber((select(5, UnitCastingInfo("player"))), 0)
    WR_FrameState.playerChannelEnd = WR_SafeNumber((select(5, UnitChannelInfo("player"))), 0)
    WR_FrameState.playerInCombat = UnitAffectingCombat("player")
    WR_FrameState.playerClass = UnitClassBase("player")
    WR_FrameState.playerGUID = UnitGUID("player")

    if UnitExists("target") then
        WR_FrameState.targetName = WR_SafeUnitName("target")
        WR_FrameState.targetHP = WR_SafeUnitHealth("target")
        WR_FrameState.targetHPMax = WR_SafeUnitMaxHealth("target")
        WR_FrameState.targetHPPct = WR_SafeHPPct("target")
        WR_FrameState.targetGUID = WR_SafeUnitGUID("target")
        WR_FrameState.targetInCombat = UnitAffectingCombat("target")
        WR_FrameState.targetIsPlayer = UnitIsPlayer("target")
        WR_FrameState.targetRange = WR_UnitRange("target")
    end

    if UnitExists("focus") then
        WR_FrameState.focusName = WR_SafeUnitName("focus")
        WR_FrameState.focusRange = WR_UnitRange("focus")
        WR_FrameState.focusGUID = WR_SafeUnitGUID("focus")
    end
end

function WR_GetFrameState()
    WR_UpdateFrameState()
    return WR_FrameState
end

-- ============================================================
-- ★ 网络延迟获取
-- ============================================================
function WR_GetMaxLatency()
    local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
    if latencyHome > latencyWorld then
        return latencyHome / 1000
    else
        return latencyWorld / 1000
    end
end

-- ============================================================
-- ★ GCD计算
-- ============================================================
function WR_GetMaxGCD(GCD)
    return GCD / (1 + GetHaste() / 100)
end

-- ============================================================
-- ★ 法术数值获取（带缓存）
-- ============================================================
local SpellValueCache = {}
local SpellValueCacheTime = 0

function WR_GetSpellValue(SpellName, Prefix, Suffix)
    local currentTime = GetTime()
    if currentTime > SpellValueCacheTime then
        wipe(SpellValueCache)
        SpellValueCacheTime = currentTime + 5
    end

    local cacheKey = tostring(SpellName) .. (Prefix or "") .. (Suffix or "")
    if SpellValueCache[cacheKey] then
        return SpellValueCache[cacheKey]
    end

    local DescriptionText = "(.-)"
    if Prefix ~= nil then
        DescriptionText = Prefix .. DescriptionText
    end
    if Suffix ~= nil then
        DescriptionText = DescriptionText .. Suffix
    end

    -- ★ SoD 适配：经典客户端用全局 GetSpellDescription（C_Spell 为零售 API，不存在）
    local SpellText = GetSpellDescription(SpellName)
    if SpellText ~= nil then
        SpellText = SpellText:match(DescriptionText)
    end
    if SpellText ~= nil then
        SpellText = SpellText:gsub(",", "")
    end
    if SpellText ~= nil then
        SpellText = SpellText:gsub(" 万", "0000")
    end

    local result = 0
    if SpellText ~= nil then
        local SpellValue = tonumber(SpellText)
        if type(SpellValue) == "number" then
            result = SpellValue
        end
    end

    SpellValueCache[cacheKey] = result
    return result
end

-- ============================================================
-- ★ 天赋数值获取（带缓存）
-- ============================================================
local TalentValueCache = {}
local TalentValueCacheTime = 0

function WR_GetTalentValue(SpellId, Prefix, Suffix)
    local currentTime = GetTime()
    if currentTime > TalentValueCacheTime then
        wipe(TalentValueCache)
        TalentValueCacheTime = currentTime + 5
    end

    local cacheKey = tostring(SpellId) .. (Prefix or "") .. (Suffix or "")
    if TalentValueCache[cacheKey] then
        return TalentValueCache[cacheKey]
    end

    local DescriptionText = "(.-)"
    if Prefix ~= nil then
        DescriptionText = Prefix .. DescriptionText
    end
    if Suffix ~= nil then
        DescriptionText = DescriptionText .. Suffix
    end

    local SpellText = C_TooltipInfo.GetSpellByID(SpellId).lines[4].leftText
    if SpellText ~= nil then
        SpellText = SpellText:match(DescriptionText)
    end
    if SpellText ~= nil then
        SpellText = SpellText:gsub(",", "")
    end
    if SpellText ~= nil then
        SpellText = SpellText:gsub(" 万", "0000")
    end

    local result = 0
    if SpellText ~= nil then
        local SpellValue = tonumber(SpellText)
        if type(SpellValue) == "number" then
            result = SpellValue
        end
    end

    TalentValueCache[cacheKey] = result
    return result
end

-- ============================================================
-- ★ 队伍成员死亡检测
-- ============================================================
function WR_PartyIsDeath()
    for i = 1, 4, 1 do
        if UnitExists("party" .. i) and UnitIsDead("party" .. i) then
            return true
        end
    end
    for i = 1, 40, 1 do
        if UnitExists("raid" .. i) and UnitIsDead("raid" .. i) then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 定身/束缚检测
-- ============================================================
function WR_Unbind(Unit)
    local BindName = {
        "混乱之网", "镇压之网", "钩网", "罩网", "吞噬印记", "灵魂吞噬",
    }
    if WR_GetUnitDebuffTime(Unit, BindName) > 0 then
        return true
    end
    return false
end

-- ============================================================
-- ★ 预防定身检测
-- ============================================================
function WR_YuFangDingShen(Unit)
    if WR_GetRangeSpellTime(40, YuFangDingShenSpell) < 2 then
        return true
    end
    if Unit == nil or Unit == "player" then
        if WR_GetRangeSpellTime(40, YuFangDingShenSpellToUnit, "player") < 2 then
            return true
        end
    else
        if WR_GetRangeSpellTime(40, YuFangDingShenSpellToUnit, Unit) < 2 then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 协助/危险Debuff检测
-- ============================================================
function WR_UnitAssistDebuff(Unit)
    return WR_GetUnitDebuffTime(Unit, AssistDebuffName) > 0 or
           WR_GetUnitDebuffTime(Unit, DangerDebuff) > 0 or
           WR_GetRangeSpellTime(45, OutburstCasting, Unit) < 5
end

-- ============================================================
-- ★ 必须治疗判断
-- ============================================================
function WR_Mustheal(Unit)
    local j = 1
    if WR_GetUnitDebuffTime(Unit, MustHealSpellName) > 0 or WR_UnitAssistDebuff(Unit) then
        if WR_SafeHPPct(Unit) < 0.9 then
            return true
        end
    end
    local UName = WR_SafeUnitName(Unit)
    if UName == "卡多雷精魂" or UName == "焦化树人" then
        if WR_SafeHPPct(Unit) < 0.9 then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 光环数据获取（核心）
-- ============================================================
local function WR_GetAuraData(Unit, index, filter)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local data = C_UnitAuras.GetAuraDataByIndex(Unit, index, filter)
        if data then
            return data.name, data.applications, data.dispelName
        end
        return nil
    end

    if filter == "HELPFUL" and UnitBuff then
        local name, _, count, dispelType = UnitBuff(Unit, index)
        if name then
            return name, count, dispelType
        end
    elseif filter == "HARMFUL" and UnitDebuff then
        local name, _, count, dispelType = UnitDebuff(Unit, index)
        if name then
            return name, count, dispelType
        end
    end
    return nil
end

-- ============================================================
-- ★ Buff类型检测（使用缓存）
-- ============================================================
function WR_GetUnitBuffType(Unit, BuffType)
    WR_UpdateFrameState()
    WR_EnsureAuraCached(Unit)

    local cache = WR_AuraCache[Unit]
    if not cache then return false end

    local auras = cache.HELPFUL or {}
    for i = 1, #auras do
        local aura = auras[i]
        local name = aura.name
        local count = aura.count
        local dispelType = aura.dispelType

        local isBlacklisted = (name == "无穷饥渴" and count < 6) or (name == "窃取时间")
        if not isBlacklisted and dispelType == BuffType then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ Debuff类型检测（使用缓存）
-- ============================================================
function WR_UnitDebuffType(Unit, DebuffType)
    WR_UpdateFrameState()
    WR_EnsureAuraCached(Unit)

    local cache = WR_AuraCache[Unit]
    if not cache then return false end

    local auras = cache.HARMFUL or {}
    for i = 1, #auras do
        local aura = auras[i]
        if aura.dispelType == DebuffType then
            return true, aura.count
        end
    end
    return false
end

-- ★ 判断单位是否拥有指定类型的【有益】光环（用于进攻驱散：移除敌方身上的魔法增益）
function WR_UnitBuffType(Unit, BuffType)
    WR_UpdateFrameState()
    WR_EnsureAuraCached(Unit)

    local cache = WR_AuraCache[Unit]
    if not cache then return false end

    local auras = cache.HELPFUL or {}
    for i = 1, #auras do
        local aura = auras[i]
        if aura.dispelType == BuffType then
            return true, aura.count
        end
    end
    return false
end

-- ============================================================
-- ★ 光环信息获取核心（支持byMe、按名称/ID、累计）
-- ============================================================
local function WR_GetAuraInfoCore(Unit, AuraName, ByMe, NameOrId, SumUp, filter)
    WR_UpdateFrameState()
    WR_EnsureAuraCached(Unit)

    local AuraTime = 0
    local AuraCount = 0
    local AuraSum = 0
    local currentTime = GetTime()

    local cache = WR_AuraCache[Unit]
    if not cache then
        return 0, 0, 0
    end

    local auras = cache[filter] or {}

    for i = 1, #auras do
        local aura = auras[i]
        local name = aura.name
        local count = aura.count
        local expirationTime = aura.expirationTime
        local source = aura.source
        local spellId = aura.spellId

        if ByMe and source ~= "player" then
        else
            local isMatch = false
            if type(AuraName) == "table" then
                for TempID, TempName in pairs(AuraName) do
                    if (NameOrId == nil and (name == TempName or spellId == TempID)) or
                       (NameOrId == "NAME" and name == TempName) or
                       (NameOrId == "ID" and spellId == TempID) then
                        isMatch = true
                        break
                    end
                end
            else
                if (NameOrId == nil and (name == AuraName or spellId == AuraName)) or
                   (NameOrId == "NAME" and name == AuraName) or
                   (NameOrId == "ID" and spellId == AuraName) then
                    isMatch = true
                end
            end

            if isMatch then
                -- ★★★ 2026-11-09 第十二次修正：缓存条目可能是「已过期的残留」。
                --   旧逻辑只要名字/ID 匹配就返回 999（存在但无到期时间），于是
                --   WR_GetUnitBuffTime(...) > 0 会把早已消失的 Buff 误判为仍在
                --   （真机 /mkseal：53.7 秒前上的 30 秒圣印，buffRemain=999 却 state=up）。
                --   到期时间可读且已过去 → 视为该光环不存在；只有到期时间不可读
                --   （nil / 0 / secret）才保留 999 的「存在但无计时」语义。
                local expSecret = type(WR_IsSecretValue) == "function"
                    and WR_IsSecretValue(expirationTime)
                local expExpired = (not expSecret)
                    and type(expirationTime) == "number"
                    and expirationTime > 0
                    and expirationTime ~= 999   -- 999 = 存在但无到期时间的合法哨兵
                    and expirationTime <= currentTime
                if not expExpired then
                    if AuraTime == 0 then
                        if expSecret then
                            AuraTime = 999
                        elseif expirationTime and expirationTime ~= 999 and expirationTime > currentTime then
                            AuraTime = expirationTime - currentTime
                        else
                            AuraTime = 999
                        end
                        if count and count > 0 then
                            AuraCount = count
                        else
                            AuraCount = 1
                        end
                    end
                    if not SumUp then break end
                    AuraSum = AuraSum + 1
                end
            end
        end
    end
    return AuraTime, AuraCount, AuraSum
end

-- ============================================================
-- ★ Buff/Debuff时间/层数/计数获取
-- ============================================================
function WR_GetUnitBuffInfo(Unit, BuffName, ByMe, NameOrId, SumUp)
    return WR_GetAuraInfoCore(Unit, BuffName, ByMe, NameOrId, SumUp, "HELPFUL")
end

function WR_GetUnitDebuffInfo(Unit, DebuffName, ByMe, NameOrId)
    local t, c, _ = WR_GetAuraInfoCore(Unit, DebuffName, ByMe, NameOrId, false, "HARMFUL")
    return t, c
end

function WR_GetUnitBuffTime(Unit, BuffName, ByMe, NameOrId)
    return select(1, WR_GetUnitBuffInfo(Unit, BuffName, ByMe, NameOrId))
end

function WR_GetUnitBuffCount(Unit, BuffName, ByMe, NameOrId)
    return select(2, WR_GetUnitBuffInfo(Unit, BuffName, ByMe, NameOrId))
end

function WR_GetUnitBuffSum(Unit, BuffName, ByMe, NameOrId)
    return select(3, WR_GetUnitBuffInfo(Unit, BuffName, ByMe, NameOrId, true))
end

function WR_GetUnitDebuffTime(Unit, DebuffName, ByMe, NameOrId)
    return select(1, WR_GetUnitDebuffInfo(Unit, DebuffName, ByMe, NameOrId))
end

function WR_GetUnitDebuffCount(Unit, DebuffName, ByMe, NameOrId)
    return select(2, WR_GetUnitDebuffInfo(Unit, DebuffName, ByMe, NameOrId))
end

-- ============================================================
-- ★ 训练假人检测
-- ============================================================
function WR_InTraining()
    local targetName = WR_SafeUnitName("target")
    if not targetName then return false end
    for _, TempName in pairs(TrainingName) do
        if targetName == TempName then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 单位治疗吸收量获取（盾吸收）
-- ============================================================
function WR_GetHealAbsorbs(Unit)
    if Unit and UnitExists(Unit) and not UnitIsDead(Unit) then
        return UnitGetTotalAbsorbs(Unit) or 0
    end
    return 0
end

-- ============================================================
-- ★ 单位丢失血量获取（含吸收盾）
-- ============================================================
function WR_GetUnitLostHealth(Unit)
    if UnitExists(Unit) and not UnitIsDead(Unit) then
        local healthMax = WR_SafeNumber(UnitHealthMax(Unit), 1)
        local health = WR_SafeNumber(UnitHealth(Unit), WR_SafeNumber(UnitHealthMax(Unit), 1))
        local incoming = WR_SafeNumber(UnitGetIncomingHeals(Unit), 0) or 0
        local absorbs = WR_GetHealAbsorbs(Unit)
        local LostHealth = (healthMax - health - incoming) + absorbs
        return LostHealth > 0 and LostHealth or 0
    else
        return 0
    end
end

-- ============================================================
-- ★ 队伍/团队血量丢失比例
-- ============================================================
local partyUnits = { "party1", "party2", "party3", "party4" }
local raidUnits = {
    "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8",
    "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15",
    "raid16", "raid17", "raid18", "raid19", "raid20"
}

function WR_PartyLostHP()
    local LostHP = 0
    local sum = 0
    local groupType = WR_GetInRaidOrParty()
    local unit = "player"

    if UnitExists(unit) and not UnitIsDead(unit) and WR_UnitRange(unit) <= 46 then
        local maxHp = WR_SafeNumber(UnitHealthMax(unit), 1)
        if maxHp > 0 then
            LostHP = LostHP + (maxHp - WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1))) / maxHp
            sum = sum + 1
        end
    end

    if groupType == "party" then
        for i = 1, 4 do
            local u = partyUnits[i]
            if UnitExists(u) and not UnitIsDead(u) and WR_UnitRange(u) <= 46 then
                local maxHp = WR_SafeNumber(UnitHealthMax(u), 1)
                if maxHp > 0 then
                    LostHP = LostHP + (maxHp - WR_SafeNumber(UnitHealth(u), WR_SafeNumber(UnitHealthMax(u), 1))) / maxHp
                    sum = sum + 1
                end
            end
        end
    elseif groupType == "raid" then
        for i = 1, 20 do
            local u = raidUnits[i]
            if UnitExists(u) and not UnitIsDead(u) and WR_UnitRange(u) <= 46 then
                local maxHp = WR_SafeNumber(UnitHealthMax(u), 1)
                if maxHp > 0 then
                    LostHP = LostHP + (maxHp - WR_SafeNumber(UnitHealth(u), WR_SafeNumber(UnitHealthMax(u), 1))) / maxHp
                    sum = sum + 1
                end
            end
        end
    end

    if sum == 0 then
        LostHP = 0
    else
        LostHP = math.ceil(LostHP / sum * 100) / 100
    end

    return LostHP
end

-- ============================================================
-- ★ 范围内可攻击单位计数（按法术）
-- ============================================================
function WR_GetSpellRangeHarmUnitCount(SpellName, InCombat)
    local RangeHarm = 0
    for i = 1, 40, 1 do
        local Unit = "nameplate" .. i
        if IsSpellInRange(SpellName, Unit) and UnitCanAttack("player", Unit) and
           not WR_Invincible(Unit) and
           (InCombat ~= true or UnitAffectingCombat(Unit) == InCombat) and
           (WR_SafeCreatureType(Unit) ~= "图腾" and WR_SafeCreatureType(Unit) ~= "气体云雾") then
            RangeHarm = RangeHarm + 1
        end
    end
    return RangeHarm
end

-- ============================================================
-- ★ 队伍是否在战斗中
-- ============================================================
function WR_PartyInCombat()
    if UnitAffectingCombat("player") then return true end
    for i = 1, 4 do
        local TempUnit = "party" .. i
        if UnitAffectingCombat(TempUnit) then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ Boss战斗中判断
-- ============================================================
function WR_InBossCombat()
    if UnitGUID("boss1") == nil and UnitGUID("boss2") == nil and
       UnitGUID("boss3") == nil and UnitGUID("boss4") == nil and
       UnitGUID("boss5") == nil then
        return false
    else
        return true
    end
end

-- ============================================================
-- ★ 目标是否为Boss
-- ============================================================
function WR_TargetIsBoss()
    local i
    local targetGUID = WR_SafeUnitGUID("target")
    if not targetGUID then return false end
    for i = 1, 5, 1 do
        local bossGUID = WR_SafeUnitGUID("boss" .. i)
        if bossGUID ~= nil and bossGUID == targetGUID then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 爆发Debuff时间获取
-- ============================================================
function WR_GetUnitOutburstDebuffTime(Unit)
    for _, TempDebuffName in pairs(OutburstDebuff) do
        local DebuffTime = WR_GetUnitDebuffTime(Unit, TempDebuffName)
        if DebuffTime ~= 0 then
            return DebuffTime
        end
    end
    return 999
end

-- ============================================================
-- ★ 队伍爆发Debuff时间获取
-- ============================================================
function WR_GetPartyOutburstDebuffTime()
    local i
    for i = 1, 4, 1 do
        if UnitExists("party" .. i) then
            for _, Debuff in pairs(PartyOutburstDebuff) do
                local DebuffTime = WR_GetUnitDebuffTime("party" .. i, Debuff)
                if DebuffTime > 0 then
                    return DebuffTime
                end
            end
        end
    end
    for i = 1, 40, 1 do
        if UnitExists("raid" .. i) then
            for _, Debuff in pairs(PartyOutburstDebuff) do
                local DebuffTime = WR_GetUnitDebuffTime("raid" .. i, Debuff)
                if DebuffTime > 0 then
                    return DebuffTime
                end
            end
        end
    end
    return 999
end

-- ============================================================
-- ★ 爆发抵抗时间计算
-- ============================================================
function WR_ResistOutburstTime()
    local OutburstAoeTime = WR_GetRangeSpellTime(45, OutburstAoe)
    if OutburstAoeTime < 999 then
        return OutburstAoeTime
    end

    local PlayerOutburstDebuffTime = WR_GetUnitOutburstDebuffTime("player")
    if PlayerOutburstDebuffTime < 999 then
        return PlayerOutburstDebuffTime
    end

    local PartyOutburstDebuffTime = WR_GetPartyOutburstDebuffTime()
    if PartyOutburstDebuffTime < 999 then
        return PartyOutburstDebuffTime
    end

    local OutburstCastingToMeTime = WR_GetRangeSpellTime(45, OutburstCasting, "player")
    if OutburstCastingToMeTime < 999 then
        return OutburstCastingToMeTime
    end

    WR_DangerSpellTime()
    local TempTime
    if Time == nil then
        TempTime = 5
    else
        TempTime = Time
    end

    if SF_CastTime ~= nil then
        if 6 - (GetTime() - SF_CastTime) > 0 then
            return 6 - (GetTime() - SF_CastTime)
        end
    end
    if QFJ_CastTime ~= nil then
        if 1.5 - (GetTime() - QFJ_CastTime) > 0 then
            return 1.5 - (GetTime() - QFJ_CastTime)
        end
    end
    if WL_CastTime ~= nil then
        if 0.5 - (GetTime() - WL_CastTime) > 0 then
            return 0.5 - (GetTime() - WL_CastTime)
        end
    end
    if JSSP_CastTime ~= nil then
        if 0.5 - (GetTime() - JSSP_CastTime) > 0 then
            return 0.5 - (GetTime() - JSSP_CastTime)
        end
    end
    if JLPB_CastTime ~= nil then
        if 4 - (GetTime() - JLPB_CastTime) > 0 then
            return 4 - (GetTime() - JLPB_CastTime)
        end
    end

    return 999
end

-- ============================================================
-- ★ 持续伤害抵抗判断
-- ============================================================
function WR_ResistSustained(HP)
    if HP == nil or (WR_SafeHPPct("player") <= HP) then
        local SustainedAoeTime = WR_GetRangeSpellTime(45, SustainedAoe)
        if SustainedAoeTime < 999 then
            return true
        end

        if WR_GetUnitDebuffTime("player", SustainedDebuff) > 0 then
            return true
        end

        for i = 1, 40, 1 do
            if UnitExists("nameplate" .. i) then
                if WR_GetUnitBuffTime("nameplate" .. i, SustainedBuff) > 0 then
                    return true
                end
                for _, TempName in pairs(NecroblastName) do
                    if TempName == UnitName("nameplate" .. i) and
                       WR_SafeHPPct("nameplate" .. i) <= 0.15 then
                        return true
                    end
                end
            end
        end

        if JSJM_CastTime ~= nil and GetTime() - JSJM_CastTime < 3 then
            return true
        end
    end
    return false
end

function CheckSpellEnvironment()
    return true
end

-- ============================================================
-- ★ 必须防御时间计算
-- ============================================================
function WR_MustDefenseTime()
    local ResistSustained = WR_ResistSustained()
    local ResistOutburst = WR_ResistOutburstTime()

    if WR_GetUnitHP("player") <= 0.35 and UnitAffectingCombat("player") then
        if ResistSustained or not WR_InBossCombat() then
            return 0
        end
        if ResistOutburst < 999 then
            return ResistOutburst
        end
    end

    if ResistOutburst < 999 and (ResistSustained or
       WR_GetUnitDebuffCount("player", "音速易伤") >= 2) then
        return ResistOutburst
    end

    local DangerOutburstAoeTime = WR_GetRangeSpellTime(45, DangerOutburstAoe)
    if DangerOutburstAoeTime < 999 then
        return DangerOutburstAoeTime
    end

    local DangerSustainedAoeTime = WR_GetRangeSpellTime(45, DangerSustainedAoe)
    if DangerSustainedAoeTime < 999 then
        return 0
    end

    local RLZL_SpellTime = WR_GetRangeSpellTime(45, "熔炉之力")
    if RLZL_SpellTime > 5 and RLZL_SpellTime < 999 then
        return RLZL_SpellTime - 6
    end

    if WR_SafeUnitName("boss1") == "丹塔利纳克斯" and WR_SafeCastingName("boss1") == "暗影箭雨" and
       WR_GetUnitDebuffCount("player", "拉文凯斯的遗产") == 0 then
        return 0
    end

    if WR_GetUnitDebuffTime("player", DangerDebuff) > 0 then
        return 0
    end

    local DangerSpellToMeTime = WR_GetRangeSpellTime(45, DangerSpellToMe, "player")
    if DangerSpellToMeTime <= 0.8 then
        return DangerSpellToMeTime
    end

    WR_DangerSpellTime()
    if SF_CastTime ~= nil then
        if 6.2 - (GetTime() - SF_CastTime) > 0 then
            return 6.2 - (GetTime() - SF_CastTime)
        end
    end

    return 999
end

-- ============================================================
-- ★ 逃离判断
-- ============================================================
function WR_Escape()
    if not WR_PlayerMove() and UnitAffectingCombat("player") then
        if WR_GetRangeSpellTime(45, EscapeSpellName, "player") < 999 then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 装备使用判断
-- ============================================================
function WR_Use_Equip(Num, ID)
    if GetInventoryItemID("player", Num) == ID and WR_GetEquipCD(Num) then
        return true
    end
    return false
end

-- ============================================================
-- ★ 武器饰品使用（通用）
-- ============================================================
function WR_WuQi(Range, Mode)
    if Mode == 1 or (Mode == 2 and zhandoumoshi == 1) then
        if WR_GetEquipCD(16) and WR_UnitRange("target") <= Range and
           WR_UnitInCombat("target") and UnitAffectingCombat("player") then
            if WR_ColorFrame_Show("F6", "武器") then
                return true
            end
        end
    end
    return false
end

function WR_ShiPin(Num, Mode)
    if Mode == 13 then return false end
    if not WR_GetEquipCD(Num + 12) then return false end

    if Num == 1 then
        if WR_Use_Equip(13, 178783) and WR_GetUnitBuffTime("player", 345549) > 0 then
            return false
        end
        if WR_Use_Equip(13, 219309) and WR_GetUnitBuffTime("player", 450720) > 0 then
            return false
        end

        if Mode == 1 then
            if WR_ColorFrame_Show("F10", Num .. "饰常") then return true end
        elseif Mode == 2 and zhandoumoshi == 1 then
            if WR_ColorFrame_Show("F10", Num .. "饰爆") then return true end
        elseif Mode >= 3 and Mode <= 7 and UnitAffectingCombat("player") then
            if WR_GetUnitHP("player") <= (Mode - 2) / 10 then
                if WR_ColorFrame_Show("ACF2", Num .. "饰自") then return true end
            end
        elseif Mode >= 8 and Mode <= 12 and UnitAffectingCombat("player") then
            if WR_GetUnitHP("player") <= (Mode - 7) / 10 then
                if WR_ColorFrame_Show("ACF2", Num .. "饰协P") then return true end
            elseif not UnitIsDead("party1") and WR_GetUnitHP("party1") <= (Mode - 7) / 10 and
                   WR_UnitRange("party1") <= 40 then
                if WR_ColorFrame_Show("ACF3", Num .. "饰协P1") then return true end
            elseif not UnitIsDead("party2") and WR_GetUnitHP("party2") <= (Mode - 7) / 10 and
                   WR_UnitRange("party2") <= 40 then
                if WR_ColorFrame_Show("ACF5", Num .. "饰协P2") then return true end
            elseif not UnitIsDead("party3") and WR_GetUnitHP("party3") <= (Mode - 7) / 10 and
                   WR_UnitRange("party3") <= 40 then
                if WR_ColorFrame_Show("ACF6", Num .. "饰协P3") then return true end
            elseif not UnitIsDead("party4") and WR_GetUnitHP("party4") <= (Mode - 7) / 10 and
                   WR_UnitRange("party4") <= 40 then
                if WR_ColorFrame_Show("ACF7", Num .. "饰协P4") then return true end
            end
        end

    elseif Num == 2 then
        if WR_Use_Equip(14, 178783) and WR_GetUnitBuffTime("player", 345549) > 0 then
            return false
        end
        if WR_Use_Equip(14, 219309) and WR_GetUnitBuffTime("player", 450720) > 0 then
            return false
        end

        if Mode == 1 then
            if WR_ColorFrame_Show("F11", Num .. "饰常") then return true end
        elseif Mode == 2 and zhandoumoshi == 1 then
            if WR_ColorFrame_Show("F11", Num .. "饰爆") then return true end
        elseif Mode >= 3 and Mode <= 7 and UnitAffectingCombat("player") then
            if WR_GetUnitHP("player") <= (Mode - 2) / 10 then
                if WR_ColorFrame_Show("ACSF2", Num .. "饰自") then return true end
            end
        elseif Mode >= 8 and Mode <= 12 and UnitAffectingCombat("player") then
            if WR_GetUnitHP("player") <= (Mode - 7) / 10 then
                if WR_ColorFrame_Show("ACSF2", Num .. "饰协P") then return true end
            elseif not UnitIsDead("party1") and WR_GetUnitHP("party1") <= (Mode - 7) / 10 and
                   WR_UnitRange("party1") <= 40 then
                if WR_ColorFrame_Show("ACSF3", Num .. "饰协P1") then return true end
            elseif not UnitIsDead("party2") and WR_GetUnitHP("party2") <= (Mode - 7) / 10 and
                   WR_UnitRange("party2") <= 40 then
                if WR_ColorFrame_Show("ACSF5", Num .. "饰协P2") then return true end
            elseif not UnitIsDead("party3") and WR_GetUnitHP("party3") <= (Mode - 7) / 10 and
                   WR_UnitRange("party3") <= 40 then
                if WR_ColorFrame_Show("ACSF6", Num .. "饰协P3") then return true end
            elseif not UnitIsDead("party4") and WR_GetUnitHP("party4") <= (Mode - 7) / 10 and
                   WR_UnitRange("party4") <= 40 then
                if WR_ColorFrame_Show("ACSF7", Num .. "饰协P4") then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 治疗药水可用性检测
-- ============================================================
function WR_Use_ZLYS()
    if ZLS_UseTime ~= nil and GetTime() - ZLS_UseTime < 0.5 then return false end
    if ZLYS_UseTime ~= nil and GetTime() - ZLYS_UseTime < 0.5 then return false end
    if ZLYS2_UseTime ~= nil and GetTime() - ZLYS2_UseTime < 0.5 then return false end
    if WR_GetUnitBuffTime("player", "圣盾术") > 0 then return false end

    local ZLYS = { [1] = "阿加治疗药水", [2] = "焕生治疗药水" }
    for _, ZLYS_name in pairs(ZLYS) do
        local count = C_Item.GetItemCount(ZLYS_name)
        local start, duration, enable = C_Item.GetItemCooldown(ZLYS_name)
        if count ~= nil and count >= 1 and start + duration - GetTime() <= 0 then
            return true
        end
    end
    return false
end

function WR_Use_ZLYS2()
    if ZLS_UseTime ~= nil and GetTime() - ZLS_UseTime < 0.5 then return false end
    if ZLYS_UseTime ~= nil and GetTime() - ZLYS_UseTime < 0.5 then return false end
    if ZLYS2_UseTime ~= nil and GetTime() - ZLYS2_UseTime < 0.5 then return false end
    if WR_GetUnitBuffTime("player", "圣盾术") > 0 then return false end

    local ZLYS = { [1] = "洞穴住民的挚爱" }
    for _, ZLYS_name in pairs(ZLYS) do
        local count = C_Item.GetItemCount(ZLYS_name)
        local start, duration, enable = C_Item.GetItemCooldown(ZLYS_name)
        if count ~= nil and count >= 1 and start + duration - GetTime() <= 0 then
            return true
        end
    end
    return false
end

function WR_ZLYS(Variable)
    if not PlayerHP then
        PlayerHP = WR_SafeHPPct("player")
    end
    if Variable ~= 5 and PlayerHP < Variable / 10 and UnitAffectingCombat("player") and
       WR_Use_ZLYS() then
        if WR_ColorFrame_Show("CSF", "治疗药水") then
            return true
        end
    end
    return false
end

function WR_ZLYS2(Variable)
    if not PlayerHP then
        PlayerHP = WR_SafeHPPct("player")
    end
    if Variable ~= 5 and PlayerHP < Variable / 10 and UnitAffectingCombat("player") and
       WR_Use_ZLYS2() then
        if WR_ColorFrame_Show("CST", "治疗药水") then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 爆发药水可用性检测
-- ============================================================
function WR_Use_BFYS()
    local BFYS = { [1] = "淬火药水" }
    for _, BFYS_Name in pairs(BFYS) do
        local count = C_Item.GetItemCount(BFYS_Name)
        local start, duration, enable = C_Item.GetItemCooldown(BFYS_Name)
        if count ~= nil and count >= 1 and start + duration - GetTime() <= 0 then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 预判治疗检测
-- ============================================================
function WR_PreemptiveHealing(Spell)
    if WR_GetRangeSpellTime(45, QZWY_AOE_Name) < 999 then
        return false
    end
    if WR_GetRangeSpellTime(45, QZWY_Spell_Name, "player") < 999 then
        return false
    end
    if WR_ResistOutburstTime() < WR_GetTrueCastTime(Spell) then
        return true
    end
    return false
end

-- ============================================================
-- ★ 事件通知（打断/驱散/反射）
-- ============================================================
function WR_EventNotifications()
    if WR_EventNotificationsIsOpen == true then return end

    local TempFrame = CreateFrame("Frame")
    WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")
    TempFrame:SetScript("OnEvent", function()
        if IsInInstance() then
            local channel = "SAY"
            local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags,
                  sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags =
                  unpack(WR_CombatLogEvent)

            if eventType == "SPELL_INTERRUPT" then
                local spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSchool =
                    select(12, unpack(WR_CombatLogEvent))
                if sourceName == UnitName("player") or sourceName == UnitName("pet") then
                    SendChatMessage("打断-->" .. GetSpellLink(extraSpellId), channel)
                end
            elseif eventType == "SPELL_DISPEL" then
                local spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSchool, auraType =
                    select(12, unpack(WR_CombatLogEvent))
                if sourceName == UnitName("player") or sourceName == UnitName("pet") then
                    SendChatMessage("驱散-->" .. GetSpellLink(extraSpellId), channel)
                end
            elseif eventType == "SPELL_STOLEN" then
                local spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSchool, auraType =
                    select(12, unpack(WR_CombatLogEvent))
                if sourceName == UnitName("player") then
                    SendChatMessage("偷取-->" .. GetSpellLink(extraSpellId), channel)
                end
            elseif eventType == "SPELL_MISSED" then
                local spellId, spellName, spellSchool, missType, isOffHand, amountMissed =
                    select(12, unpack(WR_CombatLogEvent))
                if missType == "REFLECT" and destName == UnitName("player") then
                    SendChatMessage("反射-->" .. GetSpellLink(spellId), channel)
                elseif missType == "ABSORB" and destName == "根基图腾" and destFlags == 8465 then
                    SendChatMessage("吸收-->" .. GetSpellLink(spellId), channel)
                end
            end
        end
    end)
    WR_EventNotificationsIsOpen = true
end

-- ============================================================
-- ★ 危险法术时间记录
-- ============================================================
function WR_DangerSpellTime()
    if WR_DangerSpellTimeIsOpen == true then return end

    local TempFrame = CreateFrame("Frame")
    WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")
    TempFrame:SetScript("OnEvent", function()
        if select(2, unpack(WR_CombatLogEvent)) == "SPELL_CAST_SUCCESS" then
            local SpellName = select(13, unpack(WR_CombatLogEvent))
            if SpellName == "霜风" then
                SF_CastTime = GetTime()
            end
            if SpellName == "强风箭" then
                QFJ_CastTime = GetTime()
            end
            if SpellName == "紊流" then
                WL_CastTime = GetTime()
            end
            if SpellName == "坚石碎片" then
                JSSP_CastTime = GetTime()
            end
            if SpellName == "警示尖鸣" then
                JSJM_CastTime = GetTime()
            end
            if SpellName == "激流破奔" then
                JLPB_CastTime = GetTime()
            end
        end
    end)
    WR_DangerSpellTimeIsOpen = true
end

-- ============================================================
-- ★ 切目标判断（黑名单）
-- ============================================================
function WR_CanTab()
    local targetName = WR_SafeUnitName("target")
    if not targetName then return true end
    for _, name in pairs(DontTabUnitName) do
        if targetName == name then
            return false
        end
    end
    return true
end

-- ============================================================
-- ★ DOT上挂判断（黑名单/无敌）
-- ============================================================
function WR_CanDot(Unit)
    TempUnit = Unit
    if TempUnit == nil then
        TempUnit = "target"
    end

    local uName = WR_SafeUnitName(TempUnit)
    if not uName then return false end

    for _, name in pairs(DontDotUnitName) do
        if uName == name then
            return false
        end
    end

    for _, name in pairs(InvincibleUnitName) do
        if uName == name then
            return false
        end
    end
    return true
end

-- ============================================================
-- ★ 队伍Buff缺失检测
-- ============================================================
function WR_PartyNotBuff(BuffName, Spell)
    if WR_GetUnitBuffCount("player", BuffName) == 0 then
        return true
    end
    if not IsInInstance() then
        return false
    end
    if UnitAffectingCombat("player") then
        return false
    end

    for i = 1, 40, 1 do
        if i <= 4 then
            unit = "party" .. i
            if UnitExists(unit) and UnitIsPlayer(unit) and not (UnitCanAttack("player", unit)) and
               not (UnitIsDead(unit)) and WR_GetUnitBuffCount(unit, BuffName) == 0 and
               (WR_UnitRange(unit) <= 50 or Spell ~= nil and IsSpellInRange(Spell, unit)) then
                return true
            end
            unit = "raid" .. i
            if UnitExists(unit) and UnitIsPlayer(unit) and not (UnitCanAttack("player", unit)) and
               not (UnitIsDead(unit)) and WR_GetUnitBuffCount(unit, BuffName) == 0 and
               (WR_UnitRange(unit) <= 50 or Spell ~= nil and IsSpellInRange(Spell, unit)) then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 可驱散Debuff检测
-- ============================================================
function WR_CanRemoveUnitDebuff(Unit)
    local Magic = false
    local Curse = false
    local Disease = false
    local Poison = false

    if IsPlayerSpell(1152) == true then
        Disease = true
        Poison = true
    end
    if IsPlayerSpell(4987) == true then
        Disease = true
        Poison = true
        Magic = true
    end
    if IsPlayerSpell(528) == true then
        Disease = true
    end
    if IsPlayerSpell(552) == true then
        Disease = true
    end
    if IsPlayerSpell(988) == true then
        Magic = true
    end
    if IsPlayerSpell(2782) == true then
        Curse = true
    end
    if IsPlayerSpell(8946) == true then
        Poison = true
    end
    if IsPlayerSpell(51886) == true then
        Poison = true
        Disease = true
        Curse = true
    end

    local CanRemove = false
    if (Magic and WR_UnitDebuffType(Unit, "Magic")) or
       (Curse and WR_UnitDebuffType(Unit, "Curse")) or
       (Disease and WR_UnitDebuffType(Unit, "Disease")) or
       (Poison and WR_UnitDebuffType(Unit, "Poison")) then
        CanRemove = true
    end

    if CanRemove then
        local HuLueQuSanDebuffName = {
            "寒冰箭", "寒冰箭雨", "冰霜撕咬", "冻结", "冰锥术", "变异注射",
            "痛苦无常", "畸变", 70308,
        }
        if WR_GetUnitDebuffTime(Unit, HuLueQuSanDebuffName) > 0 then
            return false
        else
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 危险Debuff驱散检测
-- ============================================================
function WR_CanRemoveUnitDangerDebuff(Unit)
    local QuSanDangerDebuff = {
        "妖术", "僵化", "变形术", "烟雾弹", "音素爆破", "恐惧", "催眠术",
        "心灵尖啸", "结晶", "沉默", "暗影之拥", "法术封锁", "冰冻陷阱效果",
        "家畜", "奥术洪流", "水晶锁链", "腐烂撕咬", "疫病喷溅", "衰老热疫",
        "恐吓", "晶化", "血毒素", "黑暗中的眼睛", "沉睡", "你被感染了！",
        "死灵之毒", "畸变感染", "灵魂尖啸", "熔化冲压", "吸取毒药", "黑色瘟疫",
        "冷漠", "麻痹诅咒", "支配心智", "精神控制", "心灵惊骇", "恐惧", "致死",
        "翼龙钉刺", "吸血鬼之触", "制裁", "冰冻陷阱", "寄生", "熔化冲压",
        "灵魂尖啸",
    }

    if not WR_CanRemoveUnitDebuff(Unit) then
        return false
    end

    if WR_GetUnitDebuffTime(Unit, QuSanDangerDebuff) > 0 then
        return true
    end
end

-- ============================================================
-- ★ 队伍复活检测
-- ============================================================
function WR_ResurrectParty()
    for i = 1, 40, 1 do
        local unit
        if i <= 4 then
            unit = "party" .. i
            if UnitIsDead(unit) and WR_UnitRange(unit) <= 100 then
                return true
            end
            unit = "raid" .. i
            if UnitIsDead(unit) and WR_UnitRange(unit) <= 100 then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 范围内低血量单位计数
-- ============================================================
function WR_RangeCountPR(Range, Percentage)
    local unit
    local Count = 0

    unit = "player"
    if WR_SafeNumber(UnitHealthMax(unit), 1) ~= 0 and WR_GetUnitHP(unit, "盾") <= Percentage then
        Count = Count + 1
    end

    if UnitExists("raid1") then
        for i = 1, 40, 1 do
            unit = "raid" .. i
            local maxRange = WR_UnitRange(unit)
            local TempHealthPer = 0
            if UnitExists(unit) then
                TempHealthPer = WR_GetUnitHP(unit, "盾")
            end
            if maxRange ~= nil and maxRange <= Range and TempHealthPer > 0 and
               TempHealthPer <= Percentage then
                Count = Count + 1
            end
        end
    else
        for i = 1, 4, 1 do
            unit = "party" .. i
            local maxRange = WR_UnitRange(unit)
            local TempHealthPer = 0
            if UnitExists(unit) then
                TempHealthPer = WR_GetUnitHP(unit, "盾")
            end
            if maxRange ~= nil and maxRange <= Range and TempHealthPer > 0 and
               TempHealthPer <= Percentage then
                Count = Count + 1
            end
        end
    end
    return Count
end

-- ============================================================
-- ★ 激怒Buff检测
-- ============================================================
function WR_UnitEnragedBuff(Unit)
    if WR_GetUnitBuffType(Unit, "") then
        return true
    end
end

-- ============================================================
-- ★ 打断判断（施法/引导）
-- ============================================================
function WR_GetCastInterruptible(Unit, InterruptibleTime)
    if WR_GetUnitBuffTime(Unit, "冲击屏障") > 0 then
        return false
    end

    local UnitCastTime, UnitCastRemainingTime, UnitCastInterruptible = WR_GetUnitCastInfo(Unit)
    if UnitCastTime ~= nil and UnitCastRemainingTime ~= nil and UnitCastInterruptible ~= nil then
        if UnitCastInterruptible and
           (UnitCastTime / (UnitCastTime + UnitCastRemainingTime) >= InterruptibleTime or
            UnitCastTime >= InterruptibleTime * 10) then
            return true
        end
    end

    local UnitChannelTime, UnitChannelRemainingTime, UnitChannelInterruptible = WR_GetUnitChannelInfo(Unit)
    if UnitChannelTime ~= nil and UnitChannelRemainingTime ~= nil and UnitChannelInterruptible ~= nil then
        if UnitChannelInterruptible and UnitChannelTime >= InterruptibleTime then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 单位施法信息获取
-- ============================================================
function WR_GetUnitCastInfo(Unit)
    local shifashengyushijian = nil
    local shifakedaduan = nil
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID,
          notInterruptible, spellId = UnitCastingInfo(Unit)

    if endTimeMS ~= nil then
        return GetTime() - startTimeMS / 1000, endTimeMS / 1000 - GetTime(),
               not (notInterruptible)
    end
    return nil, nil, nil
end

-- ============================================================
-- ★ 单位引导信息获取
-- ============================================================
function WR_GetUnitChannelInfo(Unit)
    local yindaoshifakaishishijian = nil
    local yindaoshifakedaduan = nil
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible,
          spellId = UnitChannelInfo(Unit)

    if endTimeMS ~= nil then
        return GetTime() - startTimeMS / 1000, endTimeMS / 1000 - GetTime(),
               not (notInterruptible)
    end
    return nil, nil, nil
end

-- ============================================================
-- ★ 符文数量获取
-- ============================================================
function WR_GetRuneCount()
    local total = 0
    for i = 1, 6 do
        if GetRuneCount(i) ~= nil then
            total = total + GetRuneCount(i)
        end
    end
    return total
end

-- ============================================================
-- ★ 坦克减伤判断（使用缓存）
-- ============================================================
local function WR_CheckSpellInTable(spellTable, name, spellId, defaultTime)
    if spellTable == nil then return nil end
    local t = defaultTime
    for SpellID, SpellName in pairs(spellTable) do
        if SpellName == "" then break end
        if SpellName == name or SpellID == spellId then
            return t
        end
    end
    return nil
end

function WR_TankResist()
    WR_UpdateFrameState()
    WR_EnsureNameplatesCached()

    local SmallMagicTime = 999
    local BigMagicTime = 999
    local SmallPhysicalTime = 999
    local BigPhysicalTime = 999
    local now = GetTime()

    if WR_SafeUnitName("boss1") == "乌比斯将军" and
       WR_GetUnitDebuffCount("player", "碎颅打击") >= 2 and
       WR_GetUnitDebuffTime("player", "碎颅打击") > 4 then
        SmallPhysicalTime = 1.4
        BigPhysicalTime = 1.4
    end

    if WR_SafeUnitName("boss1") == "狂犬K.U.-J.0." and
       WR_GetUnitDebuffTime("player", "烈焰撕咬") > 0 then
        SmallMagicTime = 1.4
        BigMagicTime = 1.4
    end

    for i = 1, 40 do
        local entry = WR_NameplateCache[i]
        if entry and entry.castingName then
            local endTime = entry.castingEndTime
            local remaining = endTime - now

            if entry.targetIsPlayer then
                local t = WR_CheckSpellInTable(TankResist_SmallMagicToMe, entry.castingName, entry.castingSpellId, remaining)
                if t then SmallMagicTime = t end
                t = WR_CheckSpellInTable(TankResist_BigMagicToMe, entry.castingName, entry.castingSpellId, remaining)
                if t then BigMagicTime = t end
                t = WR_CheckSpellInTable(TankResist_SmallPhysicalToMe, entry.castingName, entry.castingSpellId, remaining)
                if t then SmallPhysicalTime = t end
                t = WR_CheckSpellInTable(TankResist_BigPhysicalToMe, entry.castingName, entry.castingSpellId, remaining)
                if t then BigPhysicalTime = t end
            end

            local t = WR_CheckSpellInTable(TankResist_SmallMagicToAoe, entry.castingName, entry.castingSpellId, remaining)
            if t then SmallMagicTime = t end
            t = WR_CheckSpellInTable(TankResist_BigMagicToAoe, entry.castingName, entry.castingSpellId, remaining)
            if t then BigMagicTime = t end
            t = WR_CheckSpellInTable(TankResist_SmallPhysicalToAoe, entry.castingName, entry.castingSpellId, remaining)
            if t then SmallPhysicalTime = t end
            t = WR_CheckSpellInTable(TankResist_BigPhysicalToAoe, entry.castingName, entry.castingSpellId, remaining)
            if t then BigPhysicalTime = t end
        end
    end

    return SmallMagicTime, BigMagicTime, SmallPhysicalTime, BigPhysicalTime
end

-- ============================================================
-- ★ 法术反射检测（使用缓存）
-- ============================================================
function WR_SpellReflection(Time)
    WR_UpdateFrameState()
    WR_EnsureNameplatesCached()

    local AOE_List = ReflectionAOE
    local Spell_List = ReflectionSpell
    local ReflectionTime = Time

    if UnitGroupRolesAssigned("player") == "TANK" then
        AOE_List = TankResist_BigMagicToAoe
        Spell_List = TankResist_BigMagicToMe
        ReflectionTime = 999
    end

    local now = GetTime()
    for i = 1, 40 do
        local entry = WR_NameplateCache[i]
        if entry and entry.castingName then
            local remaining = entry.castingEndTime - now
            if remaining < ReflectionTime then
                local t = WR_CheckSpellInTable(AOE_List, entry.castingName, entry.castingSpellId, remaining)
                if t then return true end
                if entry.targetIsPlayer then
                    t = WR_CheckSpellInTable(Spell_List, entry.castingName, entry.castingSpellId, remaining)
                    if t then return true end
                end
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 眩晕技能判断（使用缓存）
-- ============================================================
function WR_StunUnit(Range, Exclude)
    WR_UpdateFrameState()
    WR_EnsureNameplatesCached()

    if WR_SafeCastingName("boss1") == "宇宙奇点" then
        return false
    end

    local NowTime = GetTime()

    for i = 1, 40 do
        local entry = WR_NameplateCache[i]
        if entry and entry.canAttack then
            local Pass = true

            if Exclude == "机械" and entry.creatureType == "机械" then
                Pass = false
            else
                for _, Name in pairs(DontStunUnitName) do
                    if entry.name == Name then
                        Pass = false
                        break
                    end
                end
            end

            if Pass and entry.castingName then
                local maxRange = entry.range
                if maxRange ~= nil and maxRange <= Range then
                    local castingRemaining = entry.castingEndTime - NowTime

                    for _, info in pairs(StunCastName) do
                        if info.name == entry.castingName or info.id == entry.castingSpellId then
                            if castingRemaining > 0 and castingRemaining < (info.time + 2) then
                                if InterruptTime == nil or InterruptTime == 0 or info.time ~= 0 then
                                    return true
                                end
                            end
                        end
                    end

                    for _, info in pairs(StunChannelName) do
                        if info.name == entry.castingName or info.id == entry.castingSpellId then
                            if castingRemaining > 0 and castingRemaining < (info.time + 2) then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 法术充能信息获取
-- ============================================================
function WR_GetSpellNextCharge(SpellName)
    -- ★ SoD 适配：经典 GetSpellCharges 返回 (currentCharges, maxCharges, cdStart, cdDuration)
    local _, _, cooldownStart, cooldownDuration = WR_SpellChargesInfo(SpellName)
    if cooldownStart == nil then
        return 999
    end
    if cooldownStart == 0 then
        return 0
    end
    return cooldownStart + cooldownDuration - GetTime()
end

function WR_GetSpellCharges(SpellName)
    local charges = WR_SpellChargesInfo(SpellName)
    if charges ~= nil then
        return charges
    end
    return 0
end

-- ============================================================
-- ★ 套装件数获取
-- ============================================================
function WR_GetSuit(TName)
    local TCount = 0
    for i = 1, 19 do
        local itemID = GetInventoryItemID("player", i)
        for _, id in pairs(TName) do
            if itemID == id then
                TCount = TCount + 1
            end
        end
    end
    return TCount
end

-- ============================================================
-- ★ 队伍/团队距离获取
-- ============================================================
function WR_GetPartyRange()
    local i
    TargetRange = WR_UnitRange("target")
    FocusRange = WR_UnitRange("focus")
    for i = 1, 4, 1 do
        PartyRange[i] = WR_UnitRange("party" .. i)
    end
    for i = 1, 40, 1 do
        RiadRange[i] = WR_UnitRange("raid" .. i)
    end
end

-- ============================================================
-- ★ 队伍/团队丢失血量获取
-- ============================================================
function WR_GetPartyLostHealth()
    local i
    PlayerLostHealth = WR_GetUnitLostHealth("player")
    TargetLostHealth = WR_GetUnitLostHealth("target")
    FocusLostHealth = WR_GetUnitLostHealth("focus")
    for i = 1, 4, 1 do
        PartyLostHealth[i] = WR_GetUnitLostHealth("party" .. i)
    end
    for i = 1, 40, 1 do
        RiadLostHealth[i] = WR_GetUnitLostHealth("raid" .. i)
    end
end

-- ============================================================
-- ★ 最后施放法术名称获取
-- ============================================================
local local_LastSpellName = (function()
    local lastSpellName = nil
    local isInitialized = false

    local function OnCombatLogEvent()
        local _, subevent, _, sourceGUID = unpack(WR_CombatLogEvent)
        if subevent == "SPELL_CAST_SUCCESS" and sourceGUID == UnitGUID("player") then
            lastSpellName = select(13, unpack(WR_CombatLogEvent))
        end
    end

    local function Initialize()
        if not isInitialized then
            local eventFrame = CreateFrame("Frame")
            WR_RegisterEventSafe(eventFrame, "COMBAT_LOG_EVENT_UNFILTERED")
            eventFrame:SetScript("OnEvent", OnCombatLogEvent)
            isInitialized = true
        end
    end

    return function()
        Initialize()
        return lastSpellName
    end
end)()

function WR_GetLastSpellName()
    return local_LastSpellName()
end

-- ============================================================
-- ★ 法术光环施加时间记录
-- ============================================================
function WR_GetSpellAuraApplied()
    if WR_GetSpellAuraAppliedIsOpen == true then return end

    local TempFrame = CreateFrame("Frame")
    WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")
    TempFrame:SetScript("OnEvent", function()
        local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags,
              sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags =
              unpack(WR_CombatLogEvent)

        if subevent == "SPELL_AURA_APPLIED" and destGUID == UnitGUID("player") then
            if select(12, unpack(WR_CombatLogEvent)) == 438141 or
               select(13, unpack(WR_CombatLogEvent)) == "暮光屠戮" then
                MGTL_DebuffTime = GetTime()
            end
        end

        if subevent == "SPELL_CAST_START" and destGUID == UnitGUID("player") then
            if select(12, unpack(WR_CombatLogEvent)) == 438141 or
               select(13, unpack(WR_CombatLogEvent)) == "暮光屠戮" then
                MGTL_DebuffTime = GetTime()
            end
        end
    end)
    WR_GetSpellAuraAppliedIsOpen = true
end

-- ============================================================
-- ★ 加速Buff检测（使用缓存）
-- ============================================================
function WR_SpeedUp()
    WR_UpdateFrameState()
    WR_EnsureNameplatesCached()

    if WR_GetUnitDebuffInfo("player", "能量过载", false) ~= 0 then
        return true
    end

    WR_GetSpellAuraApplied()
    if MGTL_DebuffTime ~= nil and GetTime() - MGTL_DebuffTime > 0 and
       GetTime() - MGTL_DebuffTime < 2 then
        return true
    end

    for i = 1, 40 do
        local entry = WR_NameplateCache[i]
        if entry and entry.name == "怨毒影魔" and entry.targetIsPlayer then
            return true
        end

        if entry and entry.castingName then
            for SpellID, SpellName in pairs(SpeedUpSpellName) do
                if SpellName == entry.castingName or SpellID == entry.castingSpellId then
                    return true
                end
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 疯狂Buff检测
-- ============================================================
function WR_GetUnitCrazyBuff(Unit)
    for _, BuffName in pairs(CrazyBuff) do
        if WR_GetUnitBuffInfo(Unit, BuffName) > 12 then
            return true
        end
    end

    WR_GetCrazyBuffTime()
    if Unit == "party1" and WR_GetCrazyBuffTime_Party1 ~= nil and
       GetTime() - WR_GetCrazyBuffTime_Party1 <= 2 then
        return true
    end
    if Unit == "party2" and WR_GetCrazyBuffTime_Party2 ~= nil and
       GetTime() - WR_GetCrazyBuffTime_Party2 <= 2 then
        return true
    end
    if Unit == "party3" and WR_GetCrazyBuffTime_Party3 ~= nil and
       GetTime() - WR_GetCrazyBuffTime_Party3 <= 2 then
        return true
    end
    if Unit == "party4" and WR_GetCrazyBuffTime_Party4 ~= nil and
       GetTime() - WR_GetCrazyBuffTime_Party4 <= 2 then
        return true
    end
    return false
end

-- ============================================================
-- ★ 疯狂Buff施法时间记录
-- ============================================================
function WR_GetCrazyBuffTime()
    if WR_GetCrazyBuffTimeIsOpen == true then return end

    local TempFrame = CreateFrame("Frame")
    WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")
    TempFrame:SetScript("OnEvent", function()
        local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags,
              sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags =
              unpack(WR_CombatLogEvent)

        if subevent == "SPELL_CAST_SUCCESS" or subevent == "SPELL_CAST_START" then
            for _, BuffName in pairs(CrazyBuff) do
                if select(13, unpack(WR_CombatLogEvent)) == BuffName or
                   select(12, unpack(WR_CombatLogEvent)) == BuffName then
                    if sourceGUID == UnitGUID("party1") then
                        WR_GetCrazyBuffTime_Party1 = GetTime()
                    end
                    if sourceGUID == UnitGUID("party2") then
                        WR_GetCrazyBuffTime_Party2 = GetTime()
                    end
                    if sourceGUID == UnitGUID("party3") then
                        WR_GetCrazyBuffTime_Party3 = GetTime()
                    end
                    if sourceGUID == UnitGUID("party4") then
                        WR_GetCrazyBuffTime_Party4 = GetTime()
                    end
                end
            end
        end
    end)
    WR_GetCrazyBuffTimeIsOpen = true
end

-- ============================================================
-- ★ 忽略单位名称检测
-- ============================================================
function WR_UnitIsHuLueName(Unit)
    local isInInstance = IsInInstance()
    if not (isInInstance) and UnitIsPlayer(Unit) then
        return true
    end

    local UName = WR_SafeUnitName(Unit)
    local j = 1
    while (HuLueUnitName[j] ~= nil and HuLueUnitName[j] ~= "") do
        if UName == HuLueUnitName[j] then
            return true
        end
        j = j + 1
    end
    return false
end

-- ============================================================
-- ★ 范围内无Debuff单位计数
-- ============================================================
local WR_NDRUC_Cache = { sig = "", t = 0, val = 0 }
function WR_GetNoDebuffRangeUnitCount(Range, DebuffName, InCombat)
    -- ★ P2 性能：范围扫描结果缓存（每0.25秒按参数签名刷新）
    local sig = tostring(Range) .. "|" .. tostring(DebuffName) .. "|" .. tostring(InCombat)
    local now = GetTime()
    if WR_NDRUC_Cache.sig == sig and now - WR_NDRUC_Cache.t < 0.25 then
        return WR_NDRUC_Cache.val
    end
    local RangeCount = 0
    local time = 1
    if Time ~= nil then time = Time end

    for i = 1, 40, 1 do
        local UName, _ = UnitName("nameplate" .. i)
        local maxRange = WR_UnitRange("nameplate" .. i)
        local TargetCanAttack = UnitCanAttack("player", "nameplate" .. i)
        local NPInCombat = UnitAffectingCombat("nameplate" .. i)
        local NPDebuffTime = WR_GetUnitDebuffInfo("nameplate" .. i, DebuffName, true)
        local creatureType = WR_SafeCreatureType("nameplate" .. i)

        if maxRange ~= nil and maxRange <= Range and TargetCanAttack == true and
           NPDebuffTime == 0 and creatureType ~= "图腾" and creatureType ~= "Totem" and
           creatureType ~= "气体云雾" and creatureType ~= "Gas Cloud" then
            if (NPInCombat == true and InCombat == true) or InCombat ~= true then
                if not WR_Invincible("nameplate" .. i) then
                    RangeCount = RangeCount + 1
                end
            end
        end
    end

    WR_NDRUC_Cache.sig = sig
    WR_NDRUC_Cache.t = now
    WR_NDRUC_Cache.val = RangeCount
    return RangeCount
end

-- ============================================================
-- ★ 范围内有Debuff单位计数
-- ============================================================
local WR_HDRUC_Cache = { sig = "", t = 0, val = 0 }
function WR_GetHaveDebuffRangeUnitCount(Range, DebuffName, InCombat, Time)
    -- ★ P2 性能：范围扫描结果缓存（每0.25秒按参数签名刷新）
    local sig = tostring(Range) .. "|" .. tostring(DebuffName) .. "|" .. tostring(InCombat) .. "|" .. tostring(Time)
    local now = GetTime()
    if WR_HDRUC_Cache.sig == sig and now - WR_HDRUC_Cache.t < 0.25 then
        return WR_HDRUC_Cache.val
    end
    local RangeCount = 0
    local time = 1
    if Time ~= nil then time = Time end

    for i = 1, 40, 1 do
        local creatureType = WR_SafeCreatureType("nameplate" .. i)
        if creatureType ~= "图腾" and creatureType ~= "Totem" and
           creatureType ~= "气体云雾" and creatureType ~= "Gas Cloud" and
           UnitCanAttack("player", "nameplate" .. i) and
           (InCombat ~= true or (InCombat == true and
            UnitAffectingCombat("nameplate" .. i))) and
           WR_UnitRange("nameplate" .. i) <= Range and
           not WR_Invincible("nameplate" .. i) and
           WR_GetUnitDebuffInfo("nameplate" .. i, DebuffName, true) >= time then
            RangeCount = RangeCount + 1
        end
    end

    WR_HDRUC_Cache.sig = sig
    WR_HDRUC_Cache.t = now
    WR_HDRUC_Cache.val = RangeCount
    return RangeCount
end

-- ============================================================
-- ★ 伤害衰减计算
-- ============================================================
function WR_DamageMitigation(Damage, UnitCount, Number)
    if Number > UnitCount then
        return Damage * UnitCount
    end

    DamageMitigation = Damage * (Number - 1)
    for i = Number, UnitCount, 1 do
        DamageMitigation = DamageMitigation + Damage * math.sqrt((Number - 1) / i)
    end
    return DamageMitigation
end

-- ============================================================
-- ★ BN字符串哈希
-- ============================================================
function WR_GetBN(Text)
    if Text ~= nil then
        local Num = 0
        for i = 1, string.len(Text), 1 do
            if string.byte(Text, i) ~= nil then
                Num = Num + string.byte(Text, i)
            end
        end
        Num = Num .. tonumber(string.sub(Text, string.len(Text) - 3, string.len(Text)))
        return Num
    end
    return nil
end

-- ============================================================
-- ★ 智能目标选择：队友目标可见性 / LoS 黑名单
-- ============================================================
-- LoS 失败黑名单：记录近期因"目标不在视野中 / 视线遮挡"导致施法失败的单位 GUID 与过期时间
local WR_ZNMB_LoSBlackList = {}
local WR_ZNMB_LoSMonitor_Open = false

-- 判断某候选单位是否应被跳过（不可见 或 处于 LoS 失败冷却中）
local function WR_ZNMB_IsUnitBlocked(unit)
    -- 单位未加载 / 未渲染（柱子后、楼下、过远）时不可见，直接跳过
    if not UnitIsVisible(unit) then
        return true
    end
    -- 近期因 LoS 失败被记录的单位，冷却期内跳过
    local guid = WR_SafeUnitGUID(unit)
    if guid then
        local expire = WR_ZNMB_LoSBlackList[guid]
        if expire and expire > GetTime() then
            return true
        end
    end
    return false
end

-- 注册 UI_ERROR_MESSAGE 监听：捕获 LoS 失败，将失败单位写入黑名单
local function WR_ZNMB_RegisterLoSMonitor()
    if WR_ZNMB_LoSMonitor_Open then return end
    WR_ZNMB_LoSMonitor_Open = true
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UI_ERROR_MESSAGE")
    frame:SetScript("OnEvent", function(self, event, messageType, message)
        if not message then return end
        -- 命中"目标不在视野中"(ERR_UNIT_NOT_VISIBLE) 或 "你无法看见那个目标"(SPELL_FAILED_LINE_OF_SIGHT)
        if string.find(message, "视野") or string.find(message, "line of sight")
           or string.find(message, "not visible") or string.find(message, "看见") then
            local u = "target"
            if UnitExists(u) then
                local guid = WR_SafeUnitGUID(u)
                if guid then
                    WR_ZNMB_LoSBlackList[guid] = GetTime() + 2.5
                end
            end
        end
    end)
end

-- ============================================================
-- ★ 智能目标选择
-- ============================================================
function WR_Function_ZNMB(Range, Mode)
    if Mode == 3 then return false end

    -- 启用队友目标可见性 / LoS 跳过机制（P0：全职业）
    WR_ZNMB_RegisterLoSMonitor()
    -- 清理过期的 LoS 黑名单条目
    local now = GetTime()
    for k, v in pairs(WR_ZNMB_LoSBlackList) do
        if v <= now then
            WR_ZNMB_LoSBlackList[k] = nil
        end
    end

    if WR_PartyInCombat() and (not UnitExists("target") or UnitIsDead("target") or
       not UnitCanAttack("player", "target") or
       (Mode == 2 and WR_UnitRange("target") > Range) or
       (Mode == 2 and not WR_UnitInCombat("target"))) then
        local BestUnit
        local BestHealth = 0

        local TempUnit = "pettarget"
        if not UnitIsDead(TempUnit) and UnitCanAttack("player", TempUnit) and
           not WR_ZNMB_IsUnitBlocked(TempUnit) and
           UnitAffectingCombat(TempUnit) and WR_UnitInCombat(TempUnit) and
           WR_UnitRange(TempUnit) <= Range then
            local TempUnitHealth = WR_SafeNumber(UnitHealth(TempUnit), WR_SafeNumber(UnitHealthMax(TempUnit), 1))
            if TempUnitHealth > BestHealth then
                BestUnit = TempUnit
                BestHealth = TempUnitHealth
            end
        end

        for i = 1, 4, 1 do
            local TempUnit = "party" .. i .. "target"
            if not UnitIsDead(TempUnit) and UnitCanAttack("player", TempUnit) and
               not WR_ZNMB_IsUnitBlocked(TempUnit) and
               UnitAffectingCombat(TempUnit) and WR_UnitInCombat(TempUnit) and
               WR_UnitRange(TempUnit) <= Range then
                local TempUnitHealth = WR_SafeNumber(UnitHealth(TempUnit), WR_SafeNumber(UnitHealthMax(TempUnit), 1))
                if TempUnitHealth > BestHealth then
                    BestUnit = TempUnit
                    BestHealth = TempUnitHealth
                end
            end
        end

        if BestUnit then
            if BestUnit == "pettarget" then
                if WR_ColorFrame_Show("ACN9", "宠物目标") then return true end
            elseif BestUnit == "party1target" then
                if WR_ColorFrame_Show("ACN5", "智目P1T") then return true end
            elseif BestUnit == "party2target" then
                if WR_ColorFrame_Show("ACN6", "智目P2T") then return true end
            elseif BestUnit == "party3target" then
                if WR_ColorFrame_Show("ACN7", "智目P3T") then return true end
            elseif BestUnit == "party4target" then
                if WR_ColorFrame_Show("ACN8", "智目P4T") then return true end
            end
        end

        if not IsInInstance() then
            if (WR_TargetEnemyTime == nil or GetTime() - WR_TargetEnemyTime > 0.2) and
               WR_GetRangeHarmUnitCount(Range) >= 1 then
                WR_TargetEnemyTime = GetTime()
                if WR_ColorFrame_Show("CSF10", "智能目标") then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 调试时间输出
-- ============================================================
function WR_DebugTime(Text)
    if not wrdebug then return end

    if Text == 0 then
        print("循环开始-----------------------------------------")
    end

    if Text ~= nil then
        TempText = Text
    else
        TempText = ""
    end

    if Text ~= 0 and WR_Debug_StartTime ~= nil then
        print("循环时间" .. Text .. ": " ..
              string.format("%.2f", debugprofilestop() - WR_Debug_StartTime) .. "毫秒")
    end
    WR_Debug_StartTime = debugprofilestop()
end

-- ============================================================
-- ★ 光环施加时间记录（特定法术）
-- ============================================================
function WR_GetTime_AURA_APPLIED()
    if WR_GetTime_AURA_APPLIED_Open ~= true then
        local frame = CreateFrame("Frame")
        WR_RegisterEventSafe(frame, "COMBAT_LOG_EVENT_UNFILTERED")
        frame:SetScript("OnEvent", function(self, event)
            local _, subEvent, _, _, _, _, _, _, destName, _, _, spellId =
                unpack(WR_CombatLogEvent)
            if subEvent == "SPELL_AURA_APPLIED" and destName == UnitName("player") then
                if spellId == 451568 then
                    WR_AURA_APPLIED_TIME_451568 = GetTime()
                end
            end
        end)
        WR_GetTime_AURA_APPLIED_Open = true
    end
end

-- ============================================================
-- ★ 智能焦点（按标记）
-- ============================================================
function WR_ZNJD(Num)
    if Num == 9 then return false end

    if GetRaidTargetIndex("target") ~= nil and GetRaidTargetIndex("target") == 9 - Num then
        if WR_FocusUnit("target", "智能") then return true end
    elseif GetRaidTargetIndex("mouseover") ~= nil and GetRaidTargetIndex("mouseover") == 9 - Num then
        if WR_FocusUnit("mouseover", "智能") then return true end
    elseif GetRaidTargetIndex("party1target") ~= nil and GetRaidTargetIndex("party1target") == 9 - Num then
        if WR_FocusUnit("party1target", "智能") then return true end
    elseif GetRaidTargetIndex("party2target") ~= nil and GetRaidTargetIndex("party2target") == 9 - Num then
        if WR_FocusUnit("party2target", "智能") then return true end
    elseif GetRaidTargetIndex("party3target") ~= nil and GetRaidTargetIndex("party3target") == 9 - Num then
        if WR_FocusUnit("party3target", "智能") then return true end
    elseif GetRaidTargetIndex("party4target") ~= nil and GetRaidTargetIndex("party4target") == 9 - Num then
        if WR_FocusUnit("party4target", "智能") then return true end
    end
    return false
end

-- ============================================================
-- ★ 主手武器类型判断
-- ============================================================
-- ★ 主手武器类型判断
--   无限 12.x 安全：GetItemInfo 可能缺失（裸调会 nil 报错），统一走存在性守卫 + pcall
local function WR_ItemSubTypeSafe(itemLink)
    if not itemLink then return nil end
    if type(GetItemInfo) == "function" then
        local ok, _, _, subtype = pcall(GetItemInfo, itemLink)
        if ok and type(subtype) == "string" then return subtype end
    end
    if type(C_Item) == "table" and type(C_Item.GetItemInfo) == "function" then
        local ok, t = pcall(C_Item.GetItemInfo, itemLink)
        if ok then
            if type(t) == "table" then return t.itemSubType or t.subType end
            if type(t) == "string" then return t end
        end
    end
    return nil
end

function WR_MainWeapon()
    local link = GetInventoryItemLink("player", 16)
    if link == nil then
        return "没有武器"
    end
    local subType = WR_ItemSubTypeSafe(link)
    if subType == "INVTYPE_2HWEAPON" then
        return "双手武器"
    elseif subType == "INVTYPE_WEAPON" then
        return "单手武器"
    end
    return false
end

-- ============================================================
-- ★ 自身Buff数量统计
-- ============================================================
function WR_GetMyBuffCount(BuffName)
    local BuffCount = 0
    unit = "player"

    if WR_GetUnitBuffInfo(unit, BuffName, true) > 0 then
        BuffCount = BuffCount + 1
    end

    if WR_GetInRaidOrParty() == "party" then
        for i = 1, 4, 1 do
            unit = "party" .. i
            if WR_GetUnitBuffInfo(unit, BuffName, true) > 0 then
                BuffCount = BuffCount + 1
            end
        end
    end

    if WR_GetInRaidOrParty() == "raid" then
        for i = 1, 20, 1 do
            unit = "raid" .. i
            if WR_GetUnitBuffInfo(unit, BuffName, true) > 0 then
                BuffCount = BuffCount + 1
            end
        end
    end

    return BuffCount
end

-- ============================================================
-- ★ 范围内存活队友计数
-- ============================================================
function WR_GetLifeParty(Range)
    local PartySum = 1
    for i = 1, 4, 1 do
        unit = "party" .. i
        if WR_UnitRange(unit) <= Range and not (UnitIsDead(unit)) then
            PartySum = PartySum + 1
        end
    end
    return PartySum
end

-- ============================================================
-- ★ 消息窗口
-- ============================================================
function WR_MessageWindows(Message)
    local messageFrame = CreateFrame("Frame", "WR_MessageFrame", UIParent, "BackdropTemplate")
    messageFrame:SetSize(300, 110)
    messageFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 400)
    messageFrame:SetMovable(true)
    messageFrame:EnableMouse(true)

    messageFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    messageFrame:EnableMouse(true)
    messageFrame:SetMovable(true)
    messageFrame:RegisterForDrag("LeftButton")
    messageFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    messageFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local messageText = messageFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    messageText:SetPoint("CENTER")
    messageText:SetText(Message)

    local closeButton = CreateFrame("Button", nil, messageFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", messageFrame, "TOPRIGHT")
    closeButton:SetScript("OnClick", function() messageFrame:Hide() end)

    messageFrame:Show()
end

-- ============================================================
-- ★ 插件版本通信
-- ============================================================
local prefix = "WR_Addon"
C_ChatInfo.RegisterAddonMessagePrefix(prefix)

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED")

frame:SetScript("OnEvent", function(_, event, ...)
    if WRSet == nil then return end

    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" then
        C_ChatInfo.SendAddonMessage(prefix, "V" .. WR_Addon_Version, "PARTY")
        C_ChatInfo.SendAddonMessage(prefix, "B" .. (select(2, BNGetInfo())), "PARTY")
        C_ChatInfo.SendAddonMessage(prefix, "V" .. WR_Addon_Version, "RAID")
        C_ChatInfo.SendAddonMessage(prefix, "B" .. (select(2, BNGetInfo())), "RAID")
        C_ChatInfo.SendAddonMessage(prefix, "V" .. WR_Addon_Version, "GUILD")
        C_ChatInfo.SendAddonMessage(prefix, "B" .. (select(2, BNGetInfo())), "GUILD")
        C_ChatInfo.SendAddonMessage(prefix, "V" .. WR_Addon_Version, "INSTANCE_CHAT")
        C_ChatInfo.SendAddonMessage(prefix, "B" .. (select(2, BNGetInfo())), "INSTANCE_CHAT")

    elseif event == "CHAT_MSG_ADDON" then
        local receivedPrefix, message, channel, sender = ...
        if receivedPrefix == prefix then
            if not UnitAffectingCombat("player") then
                if not WR_Addon_VersionMessage and string.sub(message, 1, 1) == "V" then
                    local Version = string.sub(message, 2)
                    if tonumber(Version) ~= nil and tonumber(Version) > tonumber(WR_Addon_Version) then
                        print(C_AddOns.GetAddOnMetadata("!WR", "Title") .. "发现新的插件版本。")
                        print("当前版本：|cffff94af" .. WR_Addon_Version .. "|r")
                        print("最新版本：|cffff94af" .. Version .. "|r")
                        WR_Addon_VersionMessage = true
                    end
                end

                if WRSet.BNDay == nil or WRSet.BNDay ~= date("%Y%m%d") then
                    WRSet.BNFriendTag = {}
                    WRSet.BNDay = date("%Y%m%d")
                end

                if string.sub(message, 1, 1) == "B" and
                   WR_GetBN((select(2, BNGetInfo()))) == "35935671" and
                   WR_GetBN(string.sub(message, 2)) ~= WR_GetBN((select(2, BNGetInfo()))) and
                   channel ~= "GUILD" then
                    local Show = true
                    for _, BNTag in pairs(WRSet.BNFriendTag) do
                        if BNTag == string.sub(message, 2) then
                            Show = false
                        end
                    end
                    if Show then
                        table.insert(WRSet.BNFriendTag, string.sub(message, 2))
                        WR_MessageWindows(sender .. "\n" .. channel .. "\n" ..
                                         string.sub(message, 2))
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- ★ 重载命令
-- ============================================================
SLASH_RL1 = "/rl"
SlashCmdList["RL"] = function()
    ReloadUI()
end

-- ============================================================
-- ★ 插入类开关 脱战统一关闭（2026-08-25 落地项 #1）
-- 所有「一次性插入」开关统一以 _CR 结尾，且在 UI_Config 中已自动注册对应斜杠命令
-- SlashCmdList["<var>"]（支持 on/off/toggle）。
-- 脱战(PLAYER_REGEN_ENABLED)时遍历注册表，将仍处于 on 的插入开关统一置 off，
-- 避免玩家切怪/脱战后残留 on 态导致下次进战斗误触发。
-- 说明：采用「按 _CR 命名约定自动收集」方式，无需逐职业手动注册，覆盖全职业插入开关。
-- ============================================================
WR_InsertToggleRegistry = WR_InsertToggleRegistry or {}

function WR_RegisterInsertToggle(name)
    if type(name) ~= "string" or name == "" then return end
    for _, v in ipairs(WR_InsertToggleRegistry) do
        if v == name then return end
    end
    table.insert(WR_InsertToggleRegistry, name)
end

-- 按命名约定自动收集所有 *_CR 插入开关（PigSet 中以后缀 _CR 结尾的键）
function WR_CollectInsertToggles()
    if not PigSet then return end
    for k, _ in pairs(PigSet) do
        if type(k) == "string" and k:sub(-3) == "_CR" then
            WR_RegisterInsertToggle(k)
        end
    end
end

local WR_InsertOffFrame = CreateFrame("Frame")
WR_InsertOffFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
WR_InsertOffFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        WR_CollectInsertToggles()
        for _, name in ipairs(WR_InsertToggleRegistry) do
            if PigSet[name] then
                if SlashCmdList[name] then
                    SlashCmdList[name]("off")
                else
                    PigSet[name] = false
                end
            end
        end
    end
end)

-- ============================================================
-- ★ 战斗中时间记录
-- ============================================================
function WR_RecordPlayerInCombatTime()
    if RecordPlayerInCombatTimeIsOpen == true then return end

    PlayerInCombatTime = nil
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            PlayerInCombatTime = GetTime()
        elseif event == "PLAYER_REGEN_ENABLED" then
            PlayerInCombatTime = nil
        end
    end)

    RecordPlayerInCombatTimeIsOpen = true
end

function WR_GetCombatTime()
    WR_RecordPlayerInCombatTime()
    if PlayerInCombatTime ~= nil then
        return GetTime() - PlayerInCombatTime
    elseif UnitAffectingCombat("player") then
        PlayerInCombatTime = GetTime()
        return 0
    else
        return 0
    end
end

-- ============================================================
-- ★ Boss单位判断
-- ============================================================
function WR_UnitIsBoss(Unit)
    if not Unit or not UnitExists(Unit) or UnitIsDeadOrGhost(Unit) then
        return false
    end

    -- ★ 1) boss1~5 单位帧 GUID 精确匹配（原有）
    local ug = WR_SafeUnitGUID(Unit)
    if ug then
        for i = 1, 5, 1 do
            local bg = WR_SafeUnitGUID("boss" .. i)
            if bg and bg == ug then
                return true
            end
        end
    end

    -- ★ 2) 分类检测：worldboss / rareelite（来源：B 的 ZZ_Wrath_Priest_ClassShared_Z 多信号识别）
    local cls = UnitClassification and UnitClassification(Unit)
    if cls == "worldboss" or cls == "rareelite" then
        return true
    end

    -- ★ 3) 负等级（骷髅级）通常是 BOSS
    local lvl = UnitLevel and UnitLevel(Unit)
    if lvl and lvl < 0 then
        return true
    end

    -- ★ 4) UnitIsBoss API（时光服零售客户端可用）
    if UnitIsBoss and UnitIsBoss(Unit) then
        return true
    end

    -- ★ 5) 兜底：副本战斗进行中且目标可攻击
    if IsEncounterInProgress and IsEncounterInProgress()
       and UnitAffectingCombat(Unit)
       and UnitCanAttack("player", Unit) then
        return true
    end

    return false
end

-- ============================================================
-- ★ 玩具可用性检测
-- ============================================================
function WR_IsToyReady(toyID)
    if not PlayerHasToy(toyID) then
        return false
    end
    local start, duration, enabled = GetItemCooldown(toyID)
    if enabled == 0 then
        return false
    end
    if duration == 0 then
        return true
    end
    return false
end

-- ============================================================
-- ★ 团队危险检测
-- ============================================================
function WR_Teamdanger()
    if WR_PreemptiveHealing(399491) or WR_RangeCountPR(40, 0.60) >= 3 or
       WR_RangeCountPR(40, 0.70) >= 4 or WR_RangeCountPR(40, 0.80) >= 5 or
       (WR_RangeCountPR(40, 0.70) >= 3 and WR_ResistSustained()) or
       (WR_RangeCountPR(40, 0.80) >= 4 and WR_ResistSustained()) then
        return true
    end
    return false
end

-- ============================================================
-- ★ 雕文检测
-- ============================================================
function WR_IsUsingGlyph(name)
    for i = 1, 6 do
        local _, _, _, spellID = GetGlyphSocketInfo(i)
        if GetSpellInfo(spellID) == name then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 获取队伍/团队类型
-- ============================================================
function WR_GetInRaidOrParty()
    if IsInRaid() then
        return "raid"
    elseif IsInGroup() then
        return "party"
    else
        return "single"
    end
end

-- ============================================================
-- ★ 安全单位名读取（无限 12.x：战斗中 UnitName 可能是 secret string）
--   任何比较 / 作为表键都会抛 "attempt to compare ... secret string"，
--   统一降级为 nil，调用方按 nil 做保守处理。
-- ============================================================
function WR_SafeUnitName(unit)
    local name = UnitName(unit)
    if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(name) then
        return nil
    end
    return name
end

-- ★ 安全单位 GUID 读取（同上：战斗中 UnitGUID 可能是 secret string）
function WR_SafeUnitGUID(unit)
    local guid = UnitGUID(unit)
    if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(guid) then
        return nil
    end
    return guid
end

-- ★ 安全单位类型读取（战斗中 UnitCreatureType 可能是 secret string）
function WR_SafeCreatureType(unit)
    if type(UnitCreatureType) ~= "function" then return nil end
    local ok, ct = pcall(UnitCreatureType, unit)
    if not ok or type(ct) ~= "string" then return nil end
    if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(ct) then
        return nil
    end
    return ct
end

-- ★ 安全读当前施法/引导名称（战斗中可能是 secret string）
function WR_SafeCastingName(unit)
    if type(UnitCastingInfo) ~= "function" then return nil end
    local ok, name = pcall(UnitCastingInfo, unit)
    if not ok or type(name) ~= "string" then return nil end
    if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(name) then return nil end
    return name
end

function WR_SafeChannelName(unit)
    if type(UnitChannelInfo) ~= "function" then return nil end
    local ok, name = pcall(UnitChannelInfo, unit)
    if not ok or type(name) ~= "string" then return nil end
    if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(name) then return nil end
    return name
end

-- ============================================================
-- ★ 无敌/不可攻击单位检测
-- ============================================================
function WR_Invincible(Unit)
    if not UnitExists(Unit) then
        return false
    end

    local InvincibleUnitName = { "坍缩星", "黑暗之核" }
    local UName = WR_SafeUnitName(Unit)
    for _, name in pairs(InvincibleUnitName) do
        if UName == name then
            return true
        end
    end

    local InvincibleBuffName = {
        [1] = "灵魂护甲", [2] = "铁树皮盾", [3] = "符文结界",
        [4] = "虚空之盾", [5] = "浪潮汹涌", [6] = "培植毁灭",
        [7] = "生命结界", [8] = "冰川护盾", [9] = "烧蚀屏障",
        [10] = "神圣屏障", [11] = "烧灼屏障", [12] = "封印强化",
        [13] = "爆裂护盾", [14] = "统御心灵", [15] = "玄秘遮蔽",
        [16] = "暗影屏障", [17] = "放逐术", [18] = "魔法屏障",
        [19] = "", [20] = "",
    }

    if WR_GetUnitBuffCount(Unit, InvincibleBuffName) > 0 or
       WR_GetUnitDebuffCount(Unit, InvincibleBuffName) > 0 then
        return true
    end

    local PlayerDebuffs = { "疯狂嗜血", "萨隆亚的礼物" }
    if WR_GetUnitDebuffCount("player", PlayerDebuffs) > 0 then
        return true
    end

    local PlayerDebuffs2 = { "麻痹诅咒" }
    if WR_GetUnitDebuffCount("player", PlayerDebuffs2) > 0 then
        return true
    end

    return false
end

-- ============================================================
-- ★ 单位战斗中判断（含黑名单）
-- ============================================================
function WR_UnitInCombat(Unit)
    local UName = WR_SafeUnitName(Unit)

    -- TOC3特殊NPC
    local TOC3_name = {
        ["暗语者维维尼"] = true, ["德拉克道格"] = true, ["戈瑞姆·影斩"] = true,
        ["玛兹迪娜"] = true, ["比莱纳·雷蹄"] = true, ["鲁姬卡"] = true,
        ["断钢者纳霍克"] = true, ["伊林·雾蹄"] = true, ["萨卡加尔"] = true,
        ["莉安德拉·唤日者"] = true, ["凋零者吉塞尔"] = true, ["严肃的凯普斯"] = true,
        ["布罗恩·粗角"] = true, ["玛里萨斯·辉刃"] = true, ["布瑞娜·沉夜"] = true,
        ["塞瑞莎·术轮"] = true, ["泰利乌斯·达斯布雷德"] = true, ["伊锐丝·影踪"] = true,
        ["卡雯娜·林歌"] = true, ["阿莱希娅·月行者"] = true, ["索库尔"] = true,
        ["麦拉多·深谷游者"] = true, ["萨缪尔"] = true, ["维兰纳"] = true,
        ["努兹尔·啸钉"] = true, ["安塔尔·缮炉者"] = true, ["沙拜德"] = true,
        ["圣光使者巴尔诺"] = true, ["黑暗邪使艾蒂丝"] = true, ["光明邪使菲奥拉"] = true,
    }

    if TOC3_name[UName] then
        if Unit == "target" and not UnitAffectingCombat("player") then
            return false
        end
    end

    -- ★ 统一屏蔽过滤层（不计分/被屏蔽单位不进入目标判定，委托怪物屏蔽系统）
    if WR_IsDamageBlocked(Unit) then
        return false
    end

    -- ★ 多目标屏蔽：被怪物屏蔽系统标记为 target 屏蔽的单位，不通过焦点/指向/队友目标切换过去。
    --   原 wlk_pingbi_duomubiao_name 名单已并入怪物屏蔽 INDEX（TARGET_BLOCKED / AOE_EXCLUDED），
    --   此处统一委托 IsMonsterBlocked（受 MONSTER_BLOCK_ENABLED 总开关控制）。
    local TOC4_name = {
        ["黑暗邪使艾蒂丝"] = true,
        ["光明邪使菲奥拉"] = true,
    }

    if IsMonsterBlocked(UName, "target") then
        if Unit == "focus" or Unit == "mouseover" then
            return false
        end
        for i = 1, 25 do
            if Unit == "raid" .. i .. "target" then
                return false
            end
        end
    end

    if TOC4_name[UName] and UnitClassBase("player") ~= "PRIEST" then
        if Unit == "focus" or Unit == "mouseover" then
            return false
        end
        for i = 1, 25 do
            if Unit == "raid" .. i .. "target" then
                return false
            end
        end
    end

    local is25Heroic = select(3, GetInstanceInfo()) == 6
    if UName == "瓦格里暗影戒卫者" and is25Heroic and WR_GetUnitHP(Unit) < 0.5 then
        return false
    end
    if UName == "瓦格里暗影戒卫者" and is25Heroic and WR_GetUnitHP(Unit) == 1 then
        return false
    end

    if not UnitExists(Unit) or UnitIsDead(Unit) or not UnitCanAttack("player", Unit) or
       WR_Invincible(Unit) then
        return false
    end

    if not UnitIsPlayer(Unit) and UnitIsPlayer(Unit .. "target") then
        return true
    end

    if UnitAffectingCombat(Unit) then
        return true
    end

    local InCombatName = {
        ["破天号巫师"] = true, ["寒冰之墓"] = true, ["训练假人"] = true,
        ["顺劈训练假人"] = true, ["地下城训练假人"] = true,
        ["团队副本训练假人"] = true, ["普通坦克假人"] = true,
        ["镜像"] = true, ["裹体之网"] = true, ["冰冻核心"] = true,
        ["大师的训练假人"] = true, ["专家的训练假人"] = true,
        ["英雄训练假人"] = true, ["宗师的训练假人"] = true,
        ["新兵的训练假人"] = true, ["学徒的训练假人"] = true,
        ["大领主的训练假人"] = true, ["黑锋骑士的训练假人"] = true,
        ["精兵的训练假人"] = true, ["镇压者"] = true, ["骨针"] = true,
        ["被污染的元素"] = true, ["魔化元素"] = true, ["蛛网裹体"] = true,
    }

    if InCombatName[UName] then
        return true
    end

    if WR_GetUnitHP(Unit) < 1 then
        return true
    end

    if UnitThreatSituation("player", "target") ~= nil then
        return true
    end

    local name, instanceType, difficultyID, difficultyName = GetInstanceInfo()
    if difficultyID == 208 or difficultyID == 12 or difficultyID == 152 then
        return true
    end

    return false
end

-- ============================================================
-- ★ 玩家移动状态
-- ============================================================
function WR_PlayerMove()
    -- ★ 无限适配：战斗中 GetUnitSpeed("player") 在 taint 路径下返回 secret value，
    --   直接 "currentSpeed == 0" 比较会抛 "attempt to compare ... secret number"。
    --   改走 WR_SafeNumber：secret / 不可读时收敛为 0（视为静止），既避免崩溃，
    --   也保持「未知即不阻止施法」的保守语义。
    local currentSpeed = WR_SafeNumber((GetUnitSpeed("player")), 0)
    return currentSpeed ~= 0
end

-- ★ 判断单位是否处于上马状态（WotLK 无 IsMounted(unit)，用速度阈值近似）
--   跑步速度≈7、最慢坐骑(60%)≈8.9，故当前速度>8.5 视为已上马。
--   局限：静止的坐骑速度为0，无法识别（上马通常伴随移动，实际够用）。
--   对玩家自身优先用 IsMounted() 精确判断。
function WR_IsUnitMounted(Unit)
    if not Unit or not UnitExists(Unit) then return false end
    if UnitIsUnit(Unit, "player") then
        return IsMounted() or UnitInVehicle("player")
    end
    -- ★ 无限适配：战斗 taint 下 GetUnitSpeed(Unit) 对 target/名牌 等单位返回
    --   secret value，直接比较 "speed > 8.5" 会抛 secret number 错误。
    --   改走 WR_SafeNumber：不可读时收敛为 0（视为未上马）。
    local speed = WR_SafeNumber((GetUnitSpeed(Unit)), 0)
    return speed > 8.5
end

-- ============================================================
-- ★ 单位距离获取
-- ============================================================
function WR_UnitRange(Unit)
    if not Unit or not UnitExists(Unit) then return 999 end
    -- ★ 无限适配：LibRangeCheck 内部用 UnitGUID(unit) 拼 cacheKey 并作为表键；
    --   战斗中 GUID 是 secret string。库内已做「secret/空 GUID 时跳过缓存」的处理。
    --   这里再做 pcall + 数值收敛兜底。
    local guid = UnitGUID(Unit)
    if guid == nil then return 999 end
    if not WR_LibRangeCheck3 or type(WR_LibRangeCheck3.GetRange) ~= "function" then
        return 999
    end
    local ok, _, maxRange = pcall(WR_LibRangeCheck3.GetRange, WR_LibRangeCheck3, Unit)
    if not ok then return 999 end
    maxRange = WR_SafeNumber(maxRange, nil)
    if maxRange == nil then
        return 999
    end
    return maxRange
end

-- ============================================================
-- ★ 弹道飞行时间计算
-- 功能：根据目标距离估算弹道飞行时间（秒）
-- 说明：法师火球术/炎爆术飞行速度约40码/秒，猎人箭矢约50码/秒
-- 参数：Unit - 目标单位, spellType - "mage" 或 "hunter"
-- 返回：飞行时间（秒），距离不可达时返回0
-- ============================================================
function WR_CalcTravelTime(Unit, spellType)
    if not UnitExists(Unit) then return 0 end
    local dist = WR_UnitRange(Unit)
    if dist >= 999 or dist <= 0 then return 0 end

    local speed
    if spellType == "mage" then
        speed = 40
    elseif spellType == "hunter" then
        speed = 50
    else
        speed = 45
    end

    return dist / speed
end

-- ============================================================
-- ★ 远距离技能释放预判
-- 功能：在远距离时提前判断技能释放窗口
-- 说明：考虑弹道飞行时间，避免在目标刚好出/入射程时释放技能导致丢失
-- 参数：Unit - 目标单位, spellType - "mage" 或 "hunter", maxRange - 技能最大射程
-- 返回：true 表示应该立即释放（预判已考虑飞行时间）
-- ============================================================
function WR_CheckLongRangeCast(Unit, spellType, maxRange)
    if not UnitExists(Unit) then return false end
    local dist = WR_UnitRange(Unit)
    if dist >= 999 or dist <= 0 then return false end

    -- 只有在距离技能最大射程的80%以上时才需要预判
    if dist < maxRange * 0.8 then return false end

    local travelTime = WR_CalcTravelTime(Unit, spellType)
    if travelTime <= 0 then return false end

    -- 如果目标距离边界小于飞行时间内移动距离（假设移动速度约7码/秒）
    -- 则需要立即释放，否则目标可能在弹道到达前离开射程
    local targetMoveSpeed = 7
    local bufferTime = travelTime + 0.15
    local predictedDist = dist + targetMoveSpeed * bufferTime

    -- 如果按当前趋势预测，目标即将离开射程，立即释放
    if dist > maxRange - (targetMoveSpeed * travelTime) then
        return true
    end

    -- 远距离时（>35码），优先释放瞬发技能
    if dist >= maxRange - 5 then
        return true
    end

    return false
end

-- ============================================================
-- ★ 伤害/DoT 屏蔽统一检查函数
-- 功能：检查单位是否应跳过伤害/DoT 施放（不计分/被屏蔽单位）
-- 说明：委托怪物屏蔽系统 IsMonsterBlocked（target 类型），由 MONSTER_BLOCK_ENABLED 总开关控制；
--       BOSS 目标自动豁免（ZZ_IsBossName）。原 WR_IsWCLBlacklisted（WCL 冲分模式专用黑名单）
--       已并入怪物屏蔽 INDEX（见 ZZ_Features_Migration.lua 的 TARGET_BLOCKED / AOE_EXCLUDED）。
-- 参数：Unit - 目标单位
-- 返回：true 表示应跳过（不计分/被屏蔽），false 表示正常
-- ============================================================
function WR_IsDamageBlocked(Unit)
    if not UnitExists(Unit) then return false end
    return IsMonsterBlocked(WR_SafeUnitName(Unit), "target")
end

-- ============================================================
-- ★ 多线目标智能排序
-- 功能：按优先级排序多线目标，返回排序后的单位列表
-- 排序规则：TTD短 > Debuff即将断补 > 高血量 > 远距离单位
-- 参数：unitList - 单位数组（如 {"target", "focus", "nameplate1", ...}）
--       debuffName - 要检查的debuff名称
-- 返回：排序后的单位数组
-- ============================================================
function WR_SortMultilineTargets(unitList, debuffName)
    if not unitList or #unitList == 0 then return unitList end

    local scoredUnits = {}
    for _, unit in ipairs(unitList) do
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            -- 统一屏蔽过滤（不计分/被屏蔽单位跳过）
            if not WR_IsDamageBlocked(unit) then
                local score = 0
                local TTD = WR_GetUnitDeathTime(unit)
                local debuffTime = debuffName and WR_GetUnitDebuffTime(unit, debuffName, true) or 999

                -- TTD越短优先级越高（即将死亡的先上DoT）
                if TTD and TTD > 0 and TTD < 999 then
                    score = score + (1000 - TTD)
                end

                -- Debuff即将断补（<5秒）优先级最高
                if debuffTime and debuffTime > 0 and debuffTime < 5 then
                    score = score + 500
                elseif debuffTime and debuffTime == 0 then
                    score = score + 300
                end

                -- 目标类型：BOSS > 精英 > 普通
                if UnitClassification(unit) == "worldboss" or UnitClassification(unit) == "elite" then
                    score = score + 200
                end

                -- 远距离单位额外加分（弹道修正相关）
                local dist = WR_UnitRange(unit)
                if dist >= 35 then
                    score = score + 50
                end

                -- 正在战斗的单位加分
                if UnitAffectingCombat(unit) then
                    score = score + 30
                end

                table.insert(scoredUnits, {
                    unit = unit,
                    score = score,
                    TTD = TTD,
                    debuffTime = debuffTime,
                })
            end
        end
    end

    -- 按分数降序排序
    table.sort(scoredUnits, function(a, b)
        return a.score > b.score
    end)

    -- 返回排序后的单位列表
    local result = {}
    for _, entry in ipairs(scoredUnits) do
        table.insert(result, entry.unit)
    end
    return result
end

-- ============================================================
-- ★ 单位血量百分比获取
-- ============================================================
function WR_GetUnitHP(Unit, Text)
    -- ★ 无限适配：1.60.x 上 UnitHealth 为 secret value，任何算术都会抛错，
    --   并给插件打会话级 taint（进而使 RegisterEvent 等保护函数被拦）。
    --   全部改走 Core/Forever_SecretGuard.lua 的安全百分比读取。
    --   Text：nil / "护盾" = 纯血量；"吸收盾" / "盾" = 扣除治疗吸收盾。
    --   未知 Text 返回 1（满血），避免旧调用点拿到 nil 后再比较抛错。
    if Text ~= nil and Text ~= "护盾" and Text ~= "吸收盾" and Text ~= "盾" then
        return 1
    end
    return WR_SafeHPPct(Unit, Text == "吸收盾" or Text == "盾")
end

-- ============================================================
-- ★ 单位蓝量百分比获取
-- ============================================================
function WR_GetUnitMP(Unit)
    -- ★ 无限适配：UnitPower / UnitPowerMax 同为 secret-affected API
    local pt = (Enum and Enum.PowerType and Enum.PowerType.Mana) or 0
    return WR_SafePowerPct(Unit, pt)
end

-- ============================================================
-- ★ GCD/施法剩余时间获取
-- ============================================================
function WR_GetGCD(SpellName)
    local SpellCD = 0
    -- ★ 无限适配：冷却信息在战斗中可能是 secret number，先收敛为普通数字
    local start, duration = WR_SpellCooldownInfo(SpellName)
    start = WR_SafeNumber(start, 0)
    duration = WR_SafeNumber(duration, 0)
    if start and duration then
        if start + duration > GetTime() then
            SpellCD = start + duration - GetTime()
        end
    end

    local okCast, _, _, _, _, endTimeMS = pcall(UnitCastingInfo, "player")
    if okCast then
        endTimeMS = WR_SafeNumber(endTimeMS, nil)
    else
        endTimeMS = nil
    end
    if endTimeMS ~= nil then
        local remain = endTimeMS / 1000 - GetTime()
        if remain > SpellCD then
            return remain
        end
    end
    return SpellCD
end

-- ============================================================
-- ★ 物品信息获取（含冷却）
-- ============================================================
function WR_GetItemInfo(Item)
    if type(Item) == "table" then
        for _, id in pairs(Item) do
            local count = GetItemCount(id)
            if count ~= nil and count >= 1 then
                local start, duration, enable = C_Container.GetItemCooldown(id)
                if start + duration - GetTime() <= 0 then
                    return true, count
                end
            end
        end
    else
        local count = GetItemCount(Item)
        if count ~= nil and count >= 1 then
            local start, duration, enable = C_Container.GetItemCooldown(Item)
            if start + duration - GetTime() <= 0 then
                return true, count
            end
        end
    end
    return false, count
end

-- ============================================================
-- ★ 范围内可攻击单位计数（增强版）
-- ============================================================
local WR_RHUC_Cache = { sig = "", t = 0, val = 0 }
function WR_GetRangeHarmUnitCount(Range, InCombat, Names)
    -- ★ P2 性能：范围扫描结果缓存（每0.25秒按参数签名刷新，避免每tick遍历40名牌）
    local sig = tostring(Range) .. "|" .. tostring(InCombat) .. "|" ..
        (Names == nil and "nil" or (type(Names) == "table" and "t" or tostring(Names)))
    local now = GetTime()
    if WR_RHUC_Cache.sig == sig and now - WR_RHUC_Cache.t < 0.25 then
        return WR_RHUC_Cache.val
    end
    local sum = 0
    local function _isSecret(v)
        return type(WR_IsSecretValue) == "function" and WR_IsSecretValue(v) == true
    end
    local role
    if type(UnitGroupRolesAssigned) == "function" then
        local okR, vR = pcall(UnitGroupRolesAssigned, "player")
        if okR and type(vR) == "string"
           and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(vR)) then
            role = vR
        end
    end
    local isTank = (role == "TANK")

    if role == "NONE" then
        if type(GetSpecialization) == "function" then
            local specIndex = GetSpecialization()
            if specIndex and type(GetSpecializationRole) == "function" then
                if GetSpecializationRole(specIndex) == "TANK" then
                    isTank = true
                end
            end
        end
    end

    for i = 1, 40, 1 do
        local Unit = "nameplate" .. i

        -- ★ 无限适配（2026-11-06）：战斗中 nameplate 的 UnitName 可能是
        --   secret string，任何 == 比较都会抛
        --   "attempt to compare ... (a secret string value)"。
        --   这里先把 secret 名字降级为 nil，后面所有名字相关判断都判空跳过，
        --   计数时按「名字不可读则计入」的保守策略，避免 AOE 数被误判为 0。
        local rawName = UnitName(Unit)
        local Uname = rawName
        if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(Uname) then
            Uname = nil
        end

        local canAttack = false
        local okA, vA = pcall(UnitCanAttack, "player", Unit)
        if okA and not _isSecret(vA) and vA == true then canAttack = true end

        if canAttack then
            local isValidTarget = true

            local okP, isPlayer = pcall(UnitIsPlayer, Unit)
            if okP and not _isSecret(isPlayer) and isPlayer == true then
                isValidTarget = false
            end

            if Uname == "瓦丝琪" and WR_GetUnitBuffTime(Unit, "魔法屏障") > 0 then
                isValidTarget = false
            end

            local creatureType
            if type(UnitCreatureType) == "function" then
                local okC, vC = pcall(UnitCreatureType, Unit)
                if okC and type(vC) == "string"
                   and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(vC)) then
                    creatureType = vC
                end
            end

            local dist = 999
            if type(WR_UnitRange) == "function" then
                local okD, vD = pcall(WR_UnitRange, Unit)
                if okD and type(vD) == "number"
                   and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(vD)) then
                    dist = vD
                end
            end

            local combatOk = true
            if InCombat == true then
                local okI, inC = pcall(UnitAffectingCombat, Unit)
                local enc = false
                if type(IsEncounterInProgress) == "function" then
                    local okE, vE = pcall(IsEncounterInProgress)
                    enc = okE and not _isSecret(vE) and vE == true
                end
                combatOk = (okI and not _isSecret(inC) and inC == true) or enc
            end

            local invincible = false
            if type(WR_Invincible) == "function" then
                local okV, vV = pcall(WR_Invincible, Unit)
                invincible = okV and not _isSecret(vV) and vV == true
            end

            if isValidTarget and not invincible and combatOk
               and creatureType ~= "图腾" and creatureType ~= "气体云雾"
               and dist <= Range then

                if Names == nil then
                    local playerClass = UnitClassBase("player")
                    if playerClass == "PALADIN" or playerClass == "DRUID" or
                       playerClass == "WARRIOR" or playerClass == "DEATHKNIGHT" or
                       playerClass == "ROGUE" or playerClass == "SHAMAN" then
                        -- ★ AoE 数量统计：坦克始终计入；非坦克按怪物屏蔽系统（aoe 标记）排除不计分/被屏蔽单位。
                        --   名字是 secret 时无法查屏蔽表，按「计入」保守处理。
                        local blocked = false
                        if Uname ~= nil and type(IsMonsterBlocked) == "function" then
                            local okB, vB = pcall(IsMonsterBlocked, Uname, "aoe")
                            blocked = okB and not _isSecret(vB) and vB == true
                        end
                        if isTank or not blocked then
                            sum = sum + 1
                        end
                    else
                        sum = sum + 1
                    end
                else
                    if Uname ~= nil then
                        if type(Names) == "table" then
                            for _, name in pairs(Names) do
                                if name == Uname then
                                    sum = sum + 1
                                end
                            end
                        else
                            if Names == Uname then
                                sum = sum + 1
                            end
                        end
                    end
                end
            end
        end
    end
    WR_RHUC_Cache.sig = sig
    WR_RHUC_Cache.t = now
    WR_RHUC_Cache.val = sum
    return sum
end

-- ============================================================
-- ★ 单目标判断（黑名单 / SoD 版）
-- 直接复用中央 BOSS 机制表 WR_BossMechanics 的 BOSS 中文名与英文别名，
-- 命中即视为单体目标战斗（旋转不进入 AoE）。天然只含 SoD 名册、零漂移。
-- ============================================================
function WR_SingleUnit()
    if not WR_BossMechanics then return false end
    local UName = WR_SafeUnitName("target")
    if not UName then return false end
    for bossKey, bossData in pairs(WR_BossMechanics) do
        if bossKey == UName then
            return true
        end
        if type(bossData) == "table" then
            for alias, _ in pairs(bossData) do
                if type(alias) == "string" and alias == UName then
                    return true
                end
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 装备持有判断
-- ============================================================
function WR_GetEquip(ID)
    for i = 1, 19, 1 do
        if GetInventoryItemID("player", i) == ID then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 界面高度计算
-- ============================================================
function WRH(Sum1, Sum2)
    local Sum = WR_FRAME_BASE_HEIGHT or 112
    if Sum1 ~= nil and Sum1 ~= 0 then
        Sum = Sum + Sum1 * 26
    end
    if Sum2 ~= nil and Sum2 ~= 0 then
        Sum = Sum + Sum2 * 44
    end
    Sum = Sum + 6
    return Sum
end

-- ============================================================
-- ★ 法术可用性判断
-- ============================================================
function WR_SpellUsable(Spell, GlobalCooldown)
    -- ★ 无限 12.x 适配：C_Spell.IsSpellUsable 只认 spellID，而本插件全传中文技能名。
    --   改走 WR_IsSpellUsableCompat（Forever_Compat.lua 提供），它先把名字经
    --   法术书索引解析成 ID，再逐级尝试 IsUsableSpell / C_Spell.IsSpellUsable /
    --   IsPlayerSpell；SoD 经典客户端上该函数直通原 IsUsableSpell，行为不变。
    if WR_GetGCD(Spell) <= (GCD or 0.4) and WR_IsSpellUsableCompat(Spell) and
       (GlobalCooldown ~= true or (GCD or 0.4) <= (ShiFaSuDu or 0.4)) then
        return true
    end
    return false
end

-- ============================================================
-- ★ 技能等级获取
-- ============================================================
function WR_GetSkillRank(Skill)
    -- ★ 无限适配：1.60.x 移除 GetNumSkillLines / GetSkillLineInfo 全局函数，
    --   裸调会抛 "attempt to call a nil value"。转调工程学模块的鲁棒实现
    --   （GetProfessions → GetSkillLineInfo → IsPlayerSpell 多级兜底）。
    if type(GetNumSkillLines) ~= "function" or type(GetSkillLineInfo) ~= "function" then
        if type(WR_GetProfessionRank_BExt) == "function" then
            return WR_GetProfessionRank_BExt(Skill)
        end
        return 0
    end
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
        if not isHeader and skillName == Skill then
            return WR_SafeNumber(skillRank, 0)
        end
    end
    return 0
end

-- ============================================================
-- ★ 范围内施法时间获取（使用缓存）
-- ============================================================
function WR_GetRangeSpellTime(Range, SpellName, Unit)
    WR_UpdateFrameState()
    WR_EnsureNameplatesCached()
    local now = GetTime()

    for i = 1, 40 do
        local entry = WR_NameplateCache[i]
        if entry and entry.range ~= nil and entry.range <= Range and
           (Unit == nil or (entry.targetName and UnitIsUnit(entry.unit .. "target", Unit))) then

            if entry.castingName then
                if type(SpellName) == "table" then
                    for TempSpellID, TempSpellName in pairs(SpellName) do
                        if entry.castingName == TempSpellName or entry.castingSpellId == TempSpellID then
                            return entry.castingEndTime - now
                        end
                    end
                else
                    if SpellName == nil or entry.castingName == SpellName or entry.castingSpellId == SpellName then
                        return entry.castingEndTime - now
                    end
                end
            end
        end
    end
    return 999
end

-- ============================================================
-- ★ 装备冷却判断
-- ============================================================
function WR_GetEquipCD(ItemNum)
    local start, duration, enable = GetInventoryItemCooldown("player", ItemNum)
    if enable == 1 then
        if start + duration <= GetTime() + GCD then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 当前天赋获取
-- ============================================================
-- ★ 2026-08-21：1级/未点天赋时 GetTalentTabInfo 返回空名或全 0 点数，
--   无法识别专精 → 按职业给默认专精（德鲁伊=平衡），保证界面有内容可显示
WR_DEFAULT_SPEC_BY_CLASS = {
    PALADIN     = "惩戒",
    DRUID       = "平衡",
    MAGE        = "奥术",
    WARRIOR     = "武器",
    PRIEST      = "暗影",
    DEATHKNIGHT = "鲜血",
    HUNTER      = "野兽控制",
    ROGUE       = "奇袭",
    SHAMAN      = "元素",
    WARLOCK     = "痛苦",
}
function WR_GetDefaultSpecByClass(classBase)
    return (WR_DEFAULT_SPEC_BY_CLASS or {})[classBase or UnitClassBase("player")]
end

function WR_GetTalent()
    local TalentRank = -1
    local TalentName
    local TalentId

    -- 页数动态获取（德鲁伊 4 页：平衡/野性/守护/恢复）。
    -- ★ 2026-08-21 修正：本端 GetTalentTabInfo 返回值1=数字tabID，返回值2=中文页名，返回值5=点数。
    --   因此名字取第2返回值，点数取第5返回值（与 Boss 文件 select(5) 一致）。
    local tabCount = 4
    -- ★ 无限适配：经典天赋 API 已移除（Core/Forever_Compat.lua 提供同名兜底），
    --   此处仍加存在性 + pcall 守卫，避免缺失/异常时抛错中断调用方。
    if type(GetNumTalentTabs) == "function" then
        local ok, n = pcall(GetNumTalentTabs)
        if ok and type(n) == "number" and n >= 1 then tabCount = n end
    end
    for i = 1, tabCount do
        local tabName, extraRank
        if type(GetTalentTabInfo) == "function" then
            local ok, _, name, _, _, rank = pcall(GetTalentTabInfo, i)
            if ok then tabName, extraRank = name, rank end
        end
        tabName = tabName or ""
        -- ★ 无限适配：天赋树改名归一（元素战斗→元素 / 暗影魔法→暗影 / 野性战斗→野性）
        if type(WR_Forever_NormalizeSpec) == "function" then
            tabName = WR_Forever_NormalizeSpec(tabName)
        end
        local rank = extraRank or 0
        if rank > TalentRank then
            TalentRank = rank
            TalentName = tabName or ""
            TalentId = i
        end
    end
    -- 兜底：完全没点天赋时按职业默认专精（德鲁伊=平衡）
    if (not TalentName or TalentName == "") and TalentRank <= 0 then
        TalentName = WR_GetDefaultSpecByClass() or ""
        TalentId = 1
    end
    return TalentName, TalentId
end

-- ============================================================
-- ★ 职业颜色
-- ============================================================
function WR_ClassesColor(Unit)
    local unitClass = UnitClassBase(Unit)

    if unitClass == "WARRIOR" then
        return "|cffC79C6E"
    elseif unitClass == "MAGE" then
        return "|cff40C7EB"
    elseif unitClass == "HUNTER" then
        return "|cffA9D271"
    elseif unitClass == "ROGUE" then
        return "|cffFFF569"
    elseif unitClass == "SHAMAN" then
        return "|cff0070DE"
    elseif unitClass == "EVOKER" then
        return "|cff33937F"
    elseif unitClass == "WARLOCK" then
        return "|cff8787ED"
    elseif unitClass == "DEATHKNIGHT" then
        return "|cffC41F3B"
    elseif unitClass == "PRIEST" then
        return "|cffFFFFFF"
    elseif unitClass == "MONK" then
        return "|cff00FF96"
    elseif unitClass == "PALADIN" then
        return "|cffF58CBA"
    elseif unitClass == "DRUID" then
        return "|cffFF7D0A"
    elseif unitClass == "DEMONHUNTER" then
        return "|cffA330C9"
    end
    return ""
end

-- ============================================================
-- ★ 打断施法检测
-- ============================================================
function WR_StopCast(StopCastTime)
    local StopCastName = { "恐怖咆哮", "烈焰喷射", "大地震颤", "震耳咆哮" }
    if WR_GetRangeSpellTime(45, StopCastName) < StopCastTime + 0.4 then
        return true
    end
    return false
end

-- ============================================================
-- ★ 邪能治疗石可用性
-- ============================================================
function WR_Use_ZLS()
    local count = GetItemCount("邪能治疗石")
    if count ~= nil and count >= 1 then
        local ZLS = { [1] = 36892, [2] = 36893, [3] = 36894 }
        for _, ZLS_ID in ipairs(ZLS) do
            local start, duration, enable = C_Container.GetItemCooldown(ZLS_ID)
            if start + duration - GetTime() <= 0 then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 鼠标指向攻击判断
-- ============================================================
function WR_AttackMouseover()
    local Not_AM_Name = {
        ["弗蕾亚"] = true, ["光明邪使菲奥拉"] = true, ["黑暗邪使艾蒂丝"] = true,
        ["维扎克斯将军"] = true, ["萨隆邪铁畸体"] = true, ["坍缩星"] = true,
        ["萨隆邪铁蒸汽"] = true, ["有生命的星座"] = true, ["暗物质"] = true,
        ["小软泥怪"] = true, ["大软泥怪"] = true, ["动力炸弹"] = true,
        ["黑暗之核"] = true, ["寒冰之墓"] = true, ["食尸鬼苦工"] = true,
        ["蹒跚的血僵尸"] = true, ["凯雷塞斯王子"] = true, ["塔达拉姆王子"] = true,
        ["瓦拉纳王子"] = true,
    }

    local mouseoverName = UnitName("mouseover")
    if mouseoverName and Not_AM_Name[mouseoverName] then
        return false
    end
    return true
end

-- ============================================================
-- ★ 真实施法时间获取（带缓存）
-- ============================================================
WR_SpellTimeCache = {}

function WR_GetTrueCastTime(Spell)
    local name, _, _, castTime = GetSpellInfo(Spell)
    if not name then
        return 999
    end

    local cName, _, _, cStart, cEnd = UnitChannelInfo("player")
    if cName == name then
        WR_SpellTimeCache[name] = (cEnd - cStart) / 1000
    end

    if castTime > 0 then
        return castTime / 1000
    end
    return WR_SpellTimeCache[name] or 0
end

-- ============================================================
-- ★ 单位名称匹配
-- ============================================================
function WR_UnitName(Unit, Names)
    local uname = WR_SafeUnitName(Unit)
    if not uname then return false end
    if type(Names) == "table" then
        for _, Name in pairs(Names) do
            if uname == Name then
                return true
            end
        end
    else
        if uname == Names then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 队伍中自身Debuff计数
-- ============================================================
function WR_GetRaidByMyBuffCount(BuffName)
    local Count = 0
    for i = 1, 25, 1 do
        if WR_GetUnitBuffTime("raid" .. i, BuffName, true) > 0 then
            Count = Count + 1
        end
    end
    return Count
end

function WR_GetRaidByMyDebuffCount(DebuffName)
    local Count = 0
    for i = 1, 25, 1 do
        if WR_GetUnitDebuffTime("raid" .. i, DebuffName, true) > 0 then
            Count = Count + 1
        end
    end
    return Count
end

-- ============================================================
-- ★ 范围内Debuff最短剩余时间
-- ============================================================
function WR_GetDebuffMinTimeInRange(Range, Debuff, ByMe)
    local time = 999
    for i = 1, 40, 1 do
        local Unit = "nameplate" .. i
        if UnitCanAttack("player", Unit) and WR_UnitRange(Unit) <= Range then
            local UnitDebuffTime = WR_GetUnitDebuffTime(Unit, Debuff, ByMe)
            if UnitDebuffTime > 0 and UnitDebuffTime <= time then
                time = UnitDebuffTime
            end
        end
    end
    if time == 999 then
        return 0
    else
        return time
    end
end

-- ============================================================
-- ★ 法力青玉可用性
-- ============================================================
function WR_Use_BaoShi()
    local count = GetItemCount("法力青玉")
    if count ~= nil and count >= 1 then
        local ZLS = { [1] = 33312 }
        for _, ZLS_ID in ipairs(ZLS) do
            local start, duration, enable = C_Container.GetItemCooldown(ZLS_ID)
            if start + duration - GetTime() <= 0 then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 天赋点数获取（按法术ID）
-- ============================================================
function GetTalentPointsBySpellID(spell)
    -- ★ 无限适配：经典逐条天赋 API 已移除，兜底函数返回 0 条；此处再做一次
    --   存在性守卫，避免任何一环缺失时 "attempt to call a nil value"。
    if type(GetNumTalentTabs) ~= "function"
       or type(GetNumTalents) ~= "function"
       or type(GetTalentInfo) ~= "function" then
        return 0
    end
    for treeIndex = 1, (GetNumTalentTabs() or 0) do
        for talentIndex = 1, (GetNumTalents(treeIndex) or 0) do
            local name, _, _, _, currentRank = GetTalentInfo(treeIndex, talentIndex)
            if name == spell then
                return currentRank
            end
        end
    end
    return 0
end

-- ============================================================
-- ★ 坦克职责判断
-- ============================================================
function WR_NumIsTank(Num)
    if not WR_NumIsTank_Group then
        WR_NumIsTank_Group = {}
    end

    if Num == nil then
        return false
    end

    if UnitAffectingCombat("player") then
        if WR_NumIsTank_Group[Num] == "Tank" then
            return true
        else
            return false
        end
    else
        local RaidOrParty = WR_GetInRaidOrParty()
        local unitClass = UnitClassBase(RaidOrParty .. Num)

        if RaidOrParty == "single" or unitClass == nil or
           unitClass == "MAGE" or unitClass == "HUNTER" or unitClass == "ROGUE" or
           unitClass == "SHAMAN" or unitClass == "PRIEST" or unitClass == "WARLOCK" then
            WR_NumIsTank_Group[Num] = "NotTank"
            return false
        end

        if UnitGroupRolesAssigned(RaidOrParty .. Num) == "TANK" then
            WR_NumIsTank_Group[Num] = "Tank"
            return true
        elseif RaidOrParty == "raid" then
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role,
                  isML, combatRole = GetRaidRosterInfo(Num)
            if role == "MAINTANK" or combatRole == "TANK" then
                WR_NumIsTank_Group[Num] = "Tank"
                return true
            end
        else
            WR_NumIsTank_Group[Num] = "NotTank"
            return false
        end
    end
end

-- ============================================================
-- ★ 玩家范围内检测
-- ============================================================
function WR_PlayerInRange(Range)
    for i = 1, 40, 1 do
        local Unit = "nameplate" .. i
        if UnitCanAttack("player", Unit) and UnitIsPlayer(Unit) and
           WR_UnitRange(Unit) <= Range then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 血兽范围内检测
-- ============================================================
function WR_XueShou_InRange(Range)
    for i = 1, 40, 1 do
        local Unit = "nameplate" .. i
        if UnitCanAttack("player", Unit) and WR_SafeUnitName(Unit) == "血兽" and
           WR_UnitRange(Unit) <= Range then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 设置焦点单位
-- ============================================================
function WR_FocusUnit(Unit, Text)
    if not UnitIsUnit("focus", Unit) then
        if GCD > 0.5 then
            WR_FocusHealthMaxWeightUnit_LastTime = GetTime() + GCD
        else
            WR_FocusHealthMaxWeightUnit_LastTime = GetTime() + 0.5
        end

        if Unit == "player" then
            if WR_ColorFrame_Show(192, Text .. "\n焦点P") then
                return true
            end
        elseif Unit == "target" then
            if WR_ColorFrame_Show(147, Text .. "\n焦点T") then
                return true
            end
        elseif Unit == "mouseover" then
            if WR_ColorFrame_Show(148, Text .. "\n焦点F") then
                return true
            end
        else
            for i = 1, 4 do
                if Unit == "party" .. i then
                    if WR_ColorFrame_Show(175 + i, Text .. "\n焦点P" .. i) then
                        return true
                    end
                end
            end
            for i = 1, 4 do
                if Unit == "party" .. i .. "target" then
                    if WR_ColorFrame_Show(96 + i, Text .. "\n焦点P" .. i .. "T") then
                        return true
                    end
                end
            end
            for i = 1, 25 do
                if Unit == "raid" .. i then
                    if WR_ColorFrame_Show(120 + i, Text .. "\n焦点R" .. i) then
                        return true
                    end
                end
                if Unit == "raid" .. i .. "target" then
                    if WR_ColorFrame_Show(150 + i, Text .. "\n焦点R" .. i .. "T") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 跟随系统专用「设置焦点」色块（2026-08-30）
-- 与战斗循环焦点色块（176=party1 / 121-145=raid1-25）隔离，
-- 避免两套逻辑抢同一颜色导致 AHK 误识别。
-- 选中跟随目标时弹对应玩家的专属「设置焦点」色块（211-240），
-- 由 AHK 识别后按既有 /focus 宏键设焦点（宏在各职业 *Macros.lua 已存在）。
-- ============================================================
local WR_FollowFocusMap = {
    party1 = 211, party2 = 212, party3 = 213, party4 = 214, party5 = 215,
    raid1 = 216, raid2 = 217, raid3 = 218, raid4 = 219, raid5 = 220,
    raid6 = 221, raid7 = 222, raid8 = 223, raid9 = 224, raid10 = 225,
    raid11 = 226, raid12 = 227, raid13 = 228, raid14 = 229, raid15 = 230,
    raid16 = 231, raid17 = 232, raid18 = 233, raid19 = 234, raid20 = 235,
    raid21 = 236, raid22 = 237, raid23 = 238, raid24 = 239, raid25 = 240,
}
function WR_FollowFocusShow(unit, text)
    local n = WR_FollowFocusMap[unit]
    if not n then return false end          -- 仅支持 party1-5 / raid1-25（超出范围不弹）
    if UnitIsUnit("focus", unit) then return false end  -- 已是焦点则不重复弹
    if WR_ColorFrame_Show then
        WR_ColorFrame_Show(n, (text or "设置焦点") .. "\n" .. unit)
    end
    return true
end

-- ============================================================
-- ★ 优先级检查（停手条件）
-- ============================================================
function WR_PriorityCheck()
    local Stop_Buff = {
        "喝水", "进食", "饮用", "进食饮水", "假死", "影遁",
        "食物", "饮料", "食物和饮料", "饮水",
    }

    local Stop_Debuff = { "假死", "萨隆亚的礼物", "疯狂嗜血" }

    local stopTargetName = WR_SafeUnitName("target")
    local playerChannel = WR_SafeChannelName("player")
    if (IsMounted() and stopTargetName ~= "永恒子嗣") or
       (UnitInVehicle("player") and stopTargetName ~= "永恒子嗣") or
       UnitIsDeadOrGhost("player") or
       ChatEdit_GetActiveWindow() ~= nil or
       (playerChannel ~= nil and playerChannel ~= "吸取灵魂" and
        playerChannel ~= "乱射" and
        playerChannel ~= "精神鞭笞") or
       WR_GetUnitBuffTime("player", Stop_Buff, nil, "NAME") > 0 or
       WR_GetUnitDebuffTime("player", Stop_Debuff, nil, "NAME") > 0 or
       (WR_GetUnitDebuffTime("player", "威慑凝视") > 0 and
        WR_GetUnitBuffTime("player", "保护之手") == 0) then
        WR_HideColorFrame()
        return true
    end
    return false
end

-- ============================================================
-- ★ 眩晕技能判断（增强版）
-- ============================================================
function WR_StunSpell(Unit)
    local debuff = {
        "制裁之锤", "神圣愤怒", "肾击", "偷袭", "肾击", "变形术",
        "放逐术", "旋风"
    }

    if WR_GetUnitDebuffTime(Unit, debuff) > 0 then
        return false
    end

    local StunUnitName = { ["瓦格里暗影戒卫者"] = true }
    if StunUnitName[WR_SafeUnitName(Unit)] then
        return true
    end

    local StunSpellName = {
        ["黑暗治疗"] = true, ["圣光术"] = true, ["圣光闪现"] = true,
        ["治疗链"] = true, ["治疗波"] = true, ["家畜"] = true,
        ["变形术"] = true, ["恐吓"] = true, ["暗影箭雨"] = true,
        ["宁静"] = true, ["治疗之触"] = true, ["愈合"] = true,
        ["治疗术"] = true, ["快速治疗"] = true, ["恐惧"] = true,
    }

    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID,
          notInterruptible, spellId = UnitCastingInfo(Unit)
    if name == nil then
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible,
        spellId = UnitChannelInfo(Unit)
    end

    if name ~= nil and StunSpellName[name] then
        return true
    end
    return false
end

-- ============================================================
-- ★ 统一COMBAT_LOG事件分发（性能优化）
-- 每事件仅解包一次，存入全局表 WR_CombatLogEvent，
-- 供所有战斗日志 handler 通过 unpack(WR_CombatLogEvent) 读取，
-- 避免 80+ 个独立 Frame 各自重复调用 CombatLogGetCurrentEventInfo()。
-- （TOC 中本文件最先加载，分发器最先注册，故每张表在 handler 读取前已填好）
-- ============================================================
WR_CombatLogEvent = WR_CombatLogEvent or {}   -- 全局共享：当前战斗日志事件元表
local WR_CombatLogFrame = CreateFrame("Frame")
-- ★ 无限适配：12.x 直接注册 CLEU 会触发 ADDON_ACTION_FORBIDDEN，
--   统一走 WR_RegisterEventSafe 闸门；无限下跳过注册，战斗日志职责由
--   Core/Forever_APIShim.lua 的安全事件桥接（合成伪事件）承担。
WR_RegisterEventSafe(WR_CombatLogFrame, "COMBAT_LOG_EVENT_UNFILTERED")
local WR_CombatLogHandlers = {}

function WR_RegisterCombatLogHandler(handler, handlerName)
    WR_CombatLogHandlers[handlerName] = handler
end

WR_CombatLogFrame:SetScript("OnEvent", function(self, event)
    if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then return end

    -- ★ 每事件只解包一次
    local cle = {CombatLogGetCurrentEventInfo()}
    local n = #cle
    for k = 1, n do
        WR_CombatLogEvent[k] = cle[k]
    end
    for k = n + 1, #WR_CombatLogEvent do
        WR_CombatLogEvent[k] = nil
    end

    -- 供 WR_RegisterCombatLogHandler 注册的处理器使用（当前未使用，保留扩展位）
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags,
          sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags =
          unpack(WR_CombatLogEvent)
    for name, handler in pairs(WR_CombatLogHandlers) do
        local ok, err = pcall(handler, timestamp, subevent, hideCaster,
                              sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
                              destGUID, destName, destFlags, destRaidFlags)
        if not ok then
            print("WR CombatLog handler error (" .. name .. "): " .. tostring(err))
        end
    end
end)

-- ============================================================
-- ★ SetCVar事件驱动（从OnUpdate移出）
-- ============================================================
local WR_SetCVarFrame = CreateFrame("Frame")
WR_SetCVarFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
WR_SetCVarFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
WR_SetCVarFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
WR_SetCVarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local function WR_ApplySetCvars()
    if not UnitAffectingCombat("player") then
        SetCVar("Contrast", 50)
        SetCVar("Brightness", 50)
        SetCVar("gamma", 1.0)
        SetCVar("colorblindMode", 0)
        SetCVar("Colorblindsimulator", 0)
        SetCVar("doNotFlashLowHealthWarning", 1)
        SetCVar("secureAbilityToggle", 1)
        SetCVar("findYourselfAnywhereOnlyInCombat", 0)
        SetCVar("findYourselfAnywhere", 1)
        SetBinding("CTRL-S", nil)
        SetCVar("autoUnshift", 1)
        SetCVar('equipmentManager', 1)
        local inInstance = IsInInstance()
        if inInstance then
            SetCVar("nameplateShowAll", 1)
            SetCVar("nameplateShowEnemies", 1)
            SetCVar("nameplateShowEnemyMinions", 1)
            SetCVar("nameplateShowEnemyMinus", 1)
            SetCVar("nameplateTargetRadialPosition", 1)
            SetCVar("nameplateOtherTopInset", 0.05)
            SetCVar("nameplateOtherBottomInset", 0.1)
            SetCVar("nameplateLargeTopInset", 0.05)
            SetCVar("nameplateLargeBottomInset", 0.15)
            SetCVar("nameplateMaxDistance", 40)
            SetCVar("clampTargetNameplateToScreen", 1)
        end
        SetCVar("cameraDistanceMaxZoomFactor", 4)
    end
end

WR_SetCVarFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" or event == "ZONE_CHANGED_NEW_AREA" or
       event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, WR_ApplySetCvars)
    end
end)

-- ============================================================
-- ★ 2026-08-21：hook UIDropDownMenu_SetWidth
--   原生 UIDropDownMenu_SetWidth 在设宽时会重建下拉框尺寸，把之前
--   WR_StyleDropdownFlat 设好的紧凑高度（WR_DROPDOWN_H）冲掉，导致下拉框
--   视觉高度始终是模板默认的约32px、怎么改 SetHeight 都没用。
--   这里在设宽之后，对所有被 WR_StyleDropdownFlat 标记（WR_styled）的下拉框
--   强制补回 WR_DROPDOWN_H，确保最终高度稳定锁定。
-- ============================================================
do
    local orig_UIDropDownMenu_SetWidth = UIDropDownMenu_SetWidth
    UIDropDownMenu_SetWidth = function(frame, width, padding)
        orig_UIDropDownMenu_SetWidth(frame, width, padding)
        if frame and frame.WR_styled then
            frame:SetHeight(WR_DROPDOWN_H)
        end
    end
end


-- ============================================================
-- ★ 临时诊断命令 /mkfear（排查狂暴之怒解恐惧不提示，确认后删除）
-- ============================================================
SLASH_MKFEAR1 = "/mkfear"
SlashCmdList["MKFEAR"] = function(msg)
    print("===== MKFear 诊断 =====")
    -- 1. 主循环是否调用过 WR_FZ_KBZN
    print("[1] WR_FZ_KBZN 累计调用次数 = " .. tostring(WR_FZ_KBZN_CallCount or 0))
    -- 2. 当前 player HARMFUL cache 真实 debuff 名
    WR_EnsureAuraCached("player")
    local cache = WR_AuraCache and WR_AuraCache["player"]
    if not cache then
        print("[2] WR_AuraCache[player] 不存在（缓存机制未初始化）")
    else
        local auras = cache["HARMFUL"] or {}
        print("[2] player HARMFUL debuff 数量 = " .. #auras)
        for i = 1, #auras do
            local a = auras[i]
            print("    " .. i .. ". name=[" .. tostring(a.name) .. "] id=[" .. tostring(a.spellId) .. "]")
        end
    end
    -- 3. 直接测试 WR_FZ_KBZN 返回值
    local r = WR_FZ_KBZN()
    print("[3] 直接调用 WR_FZ_KBZN() 返回 = " .. tostring(r))
    -- 4. 测试原 7 个名各自匹配情况
    for _, n in ipairs({"心灵尖啸","煽动惊恐","恐吓","破胆怒吼","恐惧","低沉咆哮","恐慌"}) do
        print("    [" .. n .. "] t=" .. WR_GetUnitDebuffTime("player", n))
    end
    print("===== MKFear 诊断结束 =====")
end

-- ============================================================
-- ★ B-3：统一辅助 ticker（合并 Focus/Mouseover/RaidTarget/Trinket 的分散 OnUpdate）
--   原 Focus/Mouseover 每帧（60Hz）无节流跑死亡时间估算，团本中纯属浪费；
--   现统一 0.1s（10Hz）刷新，RaidTarget/Trinket 保持原有节流频率接入，减少独立 frame 数量。
-- ============================================================
local WR_AuxTicker = CreateFrame("Frame")
WR_AuxTicker.auxAccum = 0
WR_AuxTicker:SetScript("OnUpdate", function(self, elapsed)
    self.auxAccum = (self.auxAccum or 0) + elapsed
    if self.auxAccum < 0.1 then return end
    self.auxAccum = 0
    if CalculateFocusDeathTime then CalculateFocusDeathTime() end
    if CalculateMouseOverDeathTime then CalculateMouseOverDeathTime() end
    if UpdateTargetPredictions then UpdateTargetPredictions() end
    if WR_TrinketMonitorTick then WR_TrinketMonitorTick() end
end)
