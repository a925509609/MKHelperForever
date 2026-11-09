-- ============================================================
-- Burst_Whitelist.lua
-- 功能：标记特定目标为"可爆发目标"
--       当目标在爆发列表（ZZ 移植 WCL_BURST_LIST / PHASES）中时，zidongbaofa = true
--       特殊处理塔迪乌斯（电荷判断）和洛欧塞布（蘑菇花）
--
-- ★ 2026-08-30 对齐 ZZHELPER：退役本地 whitelistedTargets 硬编码表，
--   改以 ZZ 移植的 WCL_BURST_LIST / PHASES 为唯一事实源
--   （BOSS 默认允许爆发、小怪默认禁止、显式勾选优先；五人本 BOSS 不在 PHASES 中 → 默认不爆发）
--   训练假人单独保留为默认允许，方便木桩测试
-- ============================================================

zidongbaofa = false

-- ★ 训练假人：始终允许自动爆发（方便木桩 / 训练假人场景测试循环）
--   名单对齐原 whitelistedTargets 中的假人条目；如需增减在此维护
local TRAINING_DUMMY_NAMES = {
    ["训练假人"] = true,
    ["大领主的训练假人"] = true,
    ["新兵的训练假人"] = true,
    ["宗师的训练假人"] = true,
    ["精兵的的训练假人"] = true,
    ["黑锋骑士的训练假人"] = true,
    ["学徒的训练假人"] = true,
    ["专家的训练假人"] = true,
    ["英雄训练假人"] = true,
    ["大师的训练假人"] = true,
}

-- ★ 判定目标名是否为训练假人
local function IsTrainingDummy(name)
    return name and TRAINING_DUMMY_NAMES[name] or false
end

local function updateZidongbaofa()
    -- ★ 无限适配：战斗中 UnitName 可能是 secret string，统一走安全读取
    local targetName = WR_SafeUnitName("target")
    -- 无目标时不触发爆发
    if not targetName then
        zidongbaofa = false
        return
    end
    -- ★ 统一闸门：以 ZZ 移植的 WCL_BURST_LIST / PHASES 为唯一事实源
    --   WR_IsBurstListTarget：BOSS 默认允许爆发、小怪默认禁止、UI 显式勾选优先
    local allowTarget = WR_IsBurstListTarget(targetName) or IsTrainingDummy(targetName)
    -- 多目标 / 分身 Boss 兜底：boss 框任一单位命中爆发列表（或训练假人）也允许
    -- 解决 艾瑞达双子 / 卡雷苟斯 等分身、双子战锁定小怪或单体时 zidongbaofa 误判为 false 的问题。
    -- ★ 2026-08-30：boss 框目标一律走 WR_IsBurstListTarget 判定（不再依赖退役的 whitelistedTargets）
    local allowBossFrame = false
    if UnitAffectingCombat("player") then
        for i = 1, 4 do
            local bname = WR_SafeUnitName("boss" .. i)
            if bname and (WR_IsBurstListTarget(bname) or IsTrainingDummy(bname)) then
                allowBossFrame = true
                break
            end
        end
    end
    if (not allowTarget) and (not allowBossFrame) then
        zidongbaofa = false
        return
    end
    -- 特殊时机：塔迪乌斯（电荷判断）/ 洛欧塞布（蘑菇花）
    if targetName == "塔迪乌斯" then
        local timePos = WR_GetUnitDebuffTime("player", "正能量电荷") or 0
        local timeNeg = WR_GetUnitDebuffTime("player", "负能量电荷") or 0
        zidongbaofa = (timePos > 0) or (timeNeg > 0)
        return
    elseif targetName == "洛欧塞布" then
        local timeMogu = WR_GetUnitDebuffTime("player", "蘑菇花") or 0
        zidongbaofa = (timeMogu > 0)
        return
    end
    zidongbaofa = true
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("UNIT_AURA")

frame:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" then
        if unit == "player" then
            local tName = WR_SafeUnitName("target")
            if tName == "塔迪乌斯" or tName == "洛欧塞布" then
                updateZidongbaofa()
            end
        end
    else
        updateZidongbaofa()
    end
end)
