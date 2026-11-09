-- ============================================================
-- TargetDeathTime_Advanced.lua
-- 功能：通过监测目标血量变化计算DPS，预测目标剩余存活时间
--       支持巫妖王特殊处理（10%血量阶段转换）
--       结果存储在全局变量 todeathtime 中
-- ============================================================

todeathtime = nil

local targetGUID      = nil       -- 当前目标的GUID
local targetbegintime = nil       -- 开始记录的时间
local targethealth    = nil       -- 上一次记录的血量
local elapsedAccumulated = 0      -- 累计更新间隔

local LICH_KING_ID = "36597"      -- 巫妖王的NPC ID

-- ★ 计算目标死亡时间
function CalculateTargetDeathTime()
    local unit = "target"
    if not UnitExists(unit) then
        todeathtime = nil
        targetGUID = nil
        return
    end

    local currentGUID = WR_SafeUnitGUID(unit)
    local currentHealth = WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1))
    local maxHealth = WR_SafeNumber(UnitHealthMax(unit), 1)
    local currentTime = GetTime()

    -- 提取NPC ID
    local npcId
    if currentGUID then
        local _, _, _, _, _, id = strsplit("-", currentGUID)
        npcId = id
    end

    local prevGUID = targetGUID
    if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(prevGUID) then
        prevGUID = nil
    end

    -- 目标切换或目标回血时重置记录
    if prevGUID ~= currentGUID or (targethealth and currentHealth > targethealth and currentHealth > 0) then
        targetbegintime = currentTime
        targethealth = currentHealth
        todeathtime = nil
        targetGUID = currentGUID
        return
    end

    -- 目标血量下降时计算DPS和剩余时间
    if targetbegintime and targethealth and targethealth > currentHealth then
        local healthChange = targethealth - currentHealth
        local timeChange = currentTime - targetbegintime
        local dps = healthChange / timeChange

        if dps > 0 and currentHealth > 0 then
            -- 巫妖王特殊处理：10%血量阶段转换
            if npcId == LICH_KING_ID then
                local phaseTransitionHealth = maxHealth * 0.1
                local remainingDamage = currentHealth - phaseTransitionHealth
                if remainingDamage > 0 then
                    todeathtime = remainingDamage / dps
                else
                    todeathtime = 0
                end
            else
                todeathtime = currentHealth / dps
            end
        end
    end

    targetGUID = currentGUID
end

-- ★ 定期更新（每0.2秒执行一次）
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(_, elapsed)
    elapsedAccumulated = elapsedAccumulated + elapsed
    if elapsedAccumulated > 0.2 then
        CalculateTargetDeathTime()
        elapsedAccumulated = 0
    end
end)