-- ============================================================
-- Potion_Cooldown_Full.lua
-- 功能：完整版药水冷却管理
--       支持战斗外/战斗中药水使用、延迟脱战、BUFF监控、
--       死亡处理、60秒冷却计时
-- ============================================================

yaoshuicd                  = true
yaoshuiRemain              = 0

local POTION_CD            = 60
local EXIT_COMBAT_DELAY    = 5

local inCombat             = UnitAffectingCombat("player") or false
local waitPostCombatStart  = false
local cdEndAt              = 0
local exitCombatAt         = 0
local cdTimer              = nil
local delayTimer           = nil
local lastPotionExpiration = 0

-- 安全取消计时器
local function SafeCancel(t)
    if t then
        pcall(function() t:Cancel() end)
    end
    return nil
end

-- 重置药水状态
local function ResetPotionStatus()
    yaoshuicd = true
    yaoshuiRemain = 0
    cdEndAt = 0
    exitCombatAt = 0
    waitPostCombatStart = false
    cdTimer = SafeCancel(cdTimer)
    delayTimer = SafeCancel(delayTimer)
end

-- 开始60秒冷却
local function Start60sCooldown()
    cdTimer = SafeCancel(cdTimer)
    cdEndAt = GetTime() + POTION_CD
    yaoshuicd = false
    waitPostCombatStart = false
    exitCombatAt = 0

    cdTimer = C_Timer.NewTimer(POTION_CD, function()
        ResetPotionStatus()
    end)
end

-- 药水物品ID集合
local potionIdSet = {
    [43185] = true, [43186] = true, [67489] = true, [67490] = true,
    [53836] = true, [53908] = true, [53909] = true, [53910] = true,
    [53911] = true, [53762] = true,
    [105706] = true, [105702] = true, [105697] = true,
    [1282971] = true,
    -- ★ SoD 探索赛季药水（与经典同物品库）
    [43839] = true, -- 超级治疗药水
    [43838] = true, -- 极效法力药水
    [43845] = true, -- 疯狂药水
    [43832] = true, -- 不灭药水
    [43841] = true, -- 狂野魔法药水
}

-- 检查是否有新的药水BUFF（使用缓存）
local function HasNewPotionBuff()
    WR_ForceRefreshAuraCache("player")

    local cache = WR_AuraCache["player"]
    if not cache then return false, 0 end

    local auras = cache.HELPFUL or {}
    for i = 1, #auras do
        local aura = auras[i]
        if potionIdSet[aura.spellId] then
            local exp = aura.expirationTime or -1
            if exp ~= lastPotionExpiration then
                return true, exp
            else
                return false, 0
            end
        end
    end
    return false, 0
end

-- 更新逻辑
local function UpdateLogic()
    local now = GetTime()

    if cdEndAt > 0 then
        if now >= cdEndAt then
            ResetPotionStatus()
        else
            yaoshuiRemain = cdEndAt - now
        end
        return
    end

    if waitPostCombatStart and not inCombat and exitCombatAt > 0 then
        if now >= (exitCombatAt + EXIT_COMBAT_DELAY) then
            waitPostCombatStart = false
            exitCombatAt = 0
            Start60sCooldown()
        else
            yaoshuiRemain = POTION_CD
        end
    end
end

-- 事件监听
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("PLAYER_DEAD")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        ResetPotionStatus()
        inCombat = UnitAffectingCombat("player") or false

    elseif event == "PLAYER_DEAD" then
        if waitPostCombatStart then
            Start60sCooldown()
        end

    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        delayTimer = SafeCancel(delayTimer)
        exitCombatAt = 0

    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        if waitPostCombatStart then
            exitCombatAt = GetTime()
            delayTimer = SafeCancel(delayTimer)
            delayTimer = C_Timer.NewTimer(EXIT_COMBAT_DELAY, function()
                waitPostCombatStart = false
                exitCombatAt = 0
                Start60sCooldown()
            end)
        end

    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            local isNew, expireTime = HasNewPotionBuff()
            if isNew then
                lastPotionExpiration = expireTime
                local isPrePot = not inCombat
                if not isPrePot then
                    -- 战斗中喝药
                    waitPostCombatStart = true
                    yaoshuicd = false
                    cdTimer = SafeCancel(cdTimer)
                    delayTimer = SafeCancel(delayTimer)
                    cdEndAt = 0
                else
                    -- 战斗外喝药
                    Start60sCooldown()
                end
            end
        end
    end
end)

-- 外部查询接口
function WR_PotionRemaining()
    UpdateLogic()
    return yaoshuicd, yaoshuiRemain
end