-- ============================================================
-- RaidTarget_DeathTime.lua
-- 功能：监控团队中每个成员的目标，计算其预计死亡时间
--       结果存储在 duiyoumubiao[i].deathTime 中
--       提供 GetTargetTimeLeft(i) 接口
-- ============================================================

for i = 1, 25 do
    _G["duiyoumubiao" .. i] = {
        guid = nil,
        deathTime = 0,
        unitName = nil,
        lastUpdate = 0,
        lastHealth = 0,
        startTime = 0,
        startHealth = 0
    }
end

-- ★ 更新所有目标预测（全局函数，供统一辅助 ticker 调用）
function UpdateTargetPredictions()
    for i = 1, math.min(25, IsInRaid() and GetNumGroupMembers() or 0) do
        local unit = "raid" .. i .. "target"
        local data = _G["duiyoumubiao" .. i]

        if UnitExists(unit) then
            local currentGUID = WR_SafeUnitGUID(unit)
            local currentHealth = WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1))
            local currentTime = GetTime()

            local dataGUID = data.guid
            if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(dataGUID) then
                dataGUID = nil
            end

            if dataGUID ~= currentGUID then
                -- 新目标
                data.guid = currentGUID
                data.startTime = currentTime
                data.startHealth = currentHealth
                data.deathTime = 0
                data.unitName = WR_SafeUnitName and WR_SafeUnitName(unit) or UnitName(unit)
                data.lastHealth = currentHealth
            else
                -- 同一目标
                local healthLost = data.lastHealth - currentHealth
                local timePassed = currentTime - (data.lastUpdate > 0 and data.lastUpdate or data.startTime)

                if timePassed > 0.5 then
                    local dps = healthLost / timePassed
                    if dps > 0 then
                        data.deathTime = currentTime + (currentHealth / dps)
                    else
                        data.deathTime = 0
                    end
                end
            end

            data.lastHealth = currentHealth
            data.lastUpdate = currentTime
        else
            data.guid = nil
            data.deathTime = 0
        end
    end
end

-- ★ 获取指定团队成员的预计剩余时间（秒）
function GetTargetTimeLeft(memberIndex)
    local data = _G["duiyoumubiao" .. memberIndex]
    if data then
        local timeLeft = data.deathTime - GetTime()
        return math.max(timeLeft, 0)
    end
    return 0
end

-- ★ B-3：RaidTarget 死亡时间预测已并入统一辅助 ticker（Core_Functions.lua 末尾 WR_AuxTicker）。
--   UpdateTargetPredictions() 内部已有 timePassed>0.5 节流的生效判断，统一 0.1s 调用无害。