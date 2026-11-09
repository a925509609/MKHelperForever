-- ============================================================
-- Rogue_ComboPoints_Tracker.lua
-- 功能：追踪盗贼在不同目标身上的连击点数量
--       支持目标切换、转嫁（Redirect）等场景
--       提供 GetCurrentComboState() 和 CheckComboCondition() 接口
-- ============================================================

if WR_PlayerClass ~= "ROGUE" then return end

if UnitClassBase("player") ~= "ROGUE" then
    return false
end

-- ============================================================
-- ★ 数据结构
-- ============================================================
local comboPointsByGUID = {}   -- GUID -> 连击点数量
local currentCpGUID = nil      -- 当前连击点所属目标的GUID
local lastCP = 0               -- 上次记录的连击点数量
local lastBuilderDestGUID = nil -- 上次生成连击点的目标GUID
local lastBuilderTime = 0      -- 上次生成连击点的时间
local BUILDER_VALID_WINDOW = 0.1 -- 生成连击点的有效窗口时间

-- ============================================================
-- ★ 常量定义
-- ============================================================
local GetTime, UnitGUID, UnitExists, UnitPower, select, CombatLogGetCurrentEventInfo =
    GetTime, UnitGUID, UnitExists, UnitPower, select, CombatLogGetCurrentEventInfo

local playerGUID = UnitGUID("player")
local COMBO_ENUM = (Enum and Enum.PowerType and Enum.PowerType.ComboPoints) or 4
local wipe_tbl = wipe or function(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

local function Now()
    return GetTime()
end

-- ============================================================
-- ★ 连击点生成技能（Builder）
-- ============================================================
local CP_BUILDERS = {
    ["邪恶攻击"] = true,
    ["Sinister Strike"] = true,
    ["背刺"] = true,
    ["Backstab"] = true,
    ["割裂"] = true,
    ["Mutilate"] = true,
    ["伏击"] = true,
    ["Ambush"] = true,
    ["绞喉"] = true,
    ["Garrote"] = true,
    ["偷袭"] = true,
    ["Cheap Shot"] = true,
    ["出血"] = true,
    ["Hemorrhage"] = true,
    ["毒刃"] = true,
    ["Shiv"] = true,
    ["斩击"] = true,
    ["Dispatch"] = true,
    ["刀扇"] = true,
    ["Fan of Knives"] = true,
    ["揭示打击"] = true,
    ["Revealing Strike"] = true,
}

-- ============================================================
-- ★ 连击点消耗技能（Finisher）
-- ============================================================
local FINISHERS = {
    ["剔骨"] = true,
    ["Eviscerate"] = true,
    ["毒伤"] = true,
    ["Envenom"] = true,
    ["割裂"] = true,
    ["Rupture"] = true,
    ["切割"] = true,
    ["Slice and Dice"] = true,
    ["肾击"] = true,
    ["Kidney Shot"] = true,
    ["赤红风暴"] = true,
    ["Crimson Tempest"] = true,
    ["致命投掷"] = true,
    ["Deadly Throw"] = true,
}

local REDIRECT_SPELL_NAME = "转嫁"

-- ============================================================
-- ★ 核心函数
-- ============================================================

-- 清空所有数据
local function ClearAll()
    wipe_tbl(comboPointsByGUID)
    currentCpGUID = nil
    lastCP = WR_SafeNumber(UnitPower("player", COMBO_ENUM), 0) or 0
    lastBuilderDestGUID = nil
    lastBuilderTime = 0
end

-- 清除指定GUID的连击点
local function ClearGUID(guid)
    if not guid then return end
    comboPointsByGUID[guid] = nil
    if currentCpGUID == guid then
        currentCpGUID = nil
    end
end

-- 检查目标是否有连击点
local function HasCPOnGUID(guid)
    local v = guid and comboPointsByGUID[guid]
    return (v and v > 0) and true or false
end

-- ============================================================
-- ★ 事件处理
-- ============================================================

local previousTargetCP = 0
local previousTargetGUID = nil

-- 目标切换处理
local function HandleTargetChanged()
    if currentCpGUID then
        previousTargetCP = comboPointsByGUID[currentCpGUID] or 0
        previousTargetGUID = currentCpGUID
    else
        previousTargetCP = 0
        previousTargetGUID = nil
    end
end

-- 连击点变化处理
local function HandleCPChanged(unit, powerType)
    if unit ~= "player" then return end

    local cp = WR_SafeNumber(UnitPower("player", COMBO_ENUM), 0) or 0

    if cp > lastCP then
        -- 连击点增加
        if lastBuilderDestGUID and (Now() - lastBuilderTime) <= BUILDER_VALID_WINDOW then
            comboPointsByGUID[lastBuilderDestGUID] = cp
            currentCpGUID = lastBuilderDestGUID
        else
            if currentCpGUID then
                comboPointsByGUID[currentCpGUID] = cp
            end
        end
    elseif cp < lastCP then
        -- 连击点减少（消耗）
        if currentCpGUID then
            comboPointsByGUID[currentCpGUID] = cp
        end
    end

    lastCP = cp
end

-- 转嫁处理
local function HandleRedirect()
    local newGUID = UnitGUID("target")
    if not newGUID or not UnitExists("target") then return end

    local fromGUID = currentCpGUID
    local movedCP = (fromGUID and comboPointsByGUID[fromGUID]) or 0

    if movedCP > 0 then
        comboPointsByGUID[newGUID] = movedCP
        currentCpGUID = newGUID
        if fromGUID and fromGUID ~= newGUID then
            comboPointsByGUID[fromGUID] = nil
        end
        previousTargetCP = movedCP
        previousTargetGUID = fromGUID
    else
        comboPointsByGUID[newGUID] = nil
        if currentCpGUID == newGUID then
            currentCpGUID = nil
        end
    end

    lastBuilderDestGUID = newGUID
    lastBuilderTime = Now()
end

-- 战斗日志处理
local function HandleCLEU()
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags,
          sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
          spellId, spellName, spellSchool, auraType = unpack(WR_CombatLogEvent)

    if sourceGUID == playerGUID then
        if subevent == "SPELL_CAST_SUCCESS" then
            if CP_BUILDERS[spellName] then
                lastBuilderDestGUID = destGUID
                lastBuilderTime = Now()
            end

            if FINISHERS[spellName] and destGUID then
                ClearGUID(destGUID)
                return
            end

            if spellName == REDIRECT_SPELL_NAME then
                HandleRedirect()
                return
            end
        end
    end

    if subevent == "UNIT_DIED" and destGUID then
        ClearGUID(destGUID)
    end
end

-- 脱离战斗处理
local function HandleLeaveCombat()
    wipe_tbl(comboPointsByGUID)
    currentCpGUID = nil
    lastCP = 0
    lastBuilderDestGUID = nil
    lastBuilderTime = 0
end

-- 进入世界处理
local function HandleEnteringWorld()
    ClearAll()
    previousTargetCP = 0
    previousTargetGUID = nil
end

-- ============================================================
-- ★ 对外接口
-- ============================================================

-- 获取当前连击点状态
function GetCurrentComboState()
    local guid = currentCpGUID
    return {
        isCPTarget    = ((UnitGUID("target") == guid) and HasCPOnGUID(guid)) or false,
        currentCpGUID = guid,
        comboPoints   = (guid and comboPointsByGUID[guid]) or 0,
    }
end

-- 获取上一个目标的连击点数
function GetPreviousTargetComboPoints()
    return previousTargetCP or 0
end

-- 比较当前目标和上一个目标的连击点
function CompareComboPointsWithPrevious()
    local currentTargetCP = GetCurrentComboState().comboPoints
    local previousCP = GetPreviousTargetComboPoints()
    return {
        currentTargetCP = currentTargetCP,
        previousTargetCP = previousCP,
        hasPreviousTarget = previousTargetGUID ~= nil,
        previousTargetGUID = previousTargetGUID,
        shouldUseRedirect = (currentTargetCP == 0 and previousCP > 0)
    }
end

-- 检查是否应该使用转嫁
function CheckComboCondition()
    if not UnitAffectingCombat("player") then
        return false
    end

    local targetGUID = UnitExists("target") and UnitGUID("target") or nil
    local cpGUID = currentCpGUID
    local cp = (cpGUID and comboPointsByGUID[cpGUID]) or 0
    local isTargetCPTarget = (targetGUID and cpGUID and targetGUID == cpGUID) or false

    return (not isTargetCPTarget) and cp >= (PigSet and PigSet.DZ_MR_ZJ or 1)
end

-- ============================================================
-- ★ 事件监听帧
-- ============================================================
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("UNIT_POWER_UPDATE")
WR_RegisterEventSafe(f, "COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

f:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        HandleEnteringWorld()
    elseif event == "PLAYER_TARGET_CHANGED" then
        HandleTargetChanged()
    elseif event == "UNIT_POWER_UPDATE" then
        local unit = ...
        if unit == "player" then
            HandleCPChanged(unit)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HandleCLEU()
    elseif event == "PLAYER_REGEN_ENABLED" then
        HandleLeaveCombat()
    end
end)