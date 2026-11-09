-- ============================================================
-- CastInfo_Monitor.lua
-- 功能：持续监控目标和焦点的施法/引导状态
--       提供全局变量供其他模块使用
-- ============================================================

local updateFrame = CreateFrame("Frame")
dd, gt, yddd, ydgt = nil, nil, nil, nil
jddd, jdgt, jdyddd, jdydgt = nil, nil, nil, nil

-- ★ 2026-11-05：Forever 客户端下 UnitCastingInfo/UnitChannelInfo 返回的时间是 secret number，
--   直接做算术会抛 taint 错误（attempt to perform arithmetic on ... a secret number value，见报错 16 行）。
--   必须先经 WR_IsSecretValue 守卫；secret 视为「读不到」→ 不更新施法进度（降级为无施法信息）。
local function WR_CastTimeUsable(t)
    if t == nil then return false end
    if WR_IsSecretValue(t) then return false end
    return true
end

local function updateCastInfo(self, elapsed)
    -- 目标施法
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID,
          notInterruptible, spellId = UnitCastingInfo("target")
    if WR_CastTimeUsable(endTimeMS) then
        dd = endTimeMS / 1000 - GetTime()
        gt = notInterruptible
    else
        dd = nil
        gt = nil
    end

    -- 目标引导
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible,
          spellId = UnitChannelInfo("target")
    if WR_CastTimeUsable(startTimeMS) then
        yddd = GetTime() - startTimeMS / 1000
        ydgt = notInterruptible
    else
        yddd = nil
        ydgt = nil
    end

    -- 焦点施法
    local fname, ftext, ftexture, fstartTimeMS, fendTimeMS, fisTradeSkill, fcastID,
          fnotInterruptible, fspellId = UnitCastingInfo("focus")
    if WR_CastTimeUsable(fendTimeMS) then
        jddd = fendTimeMS / 1000 - GetTime()
        jdgt = fnotInterruptible
    else
        jddd = nil
        jdgt = nil
    end

    -- 焦点引导
    local fname, ftext, ftexture, fstartTimeMS, fendTimeMS, fisTradeSkill, fnotInterruptible,
          fspellId = UnitChannelInfo("focus")
    if WR_CastTimeUsable(fstartTimeMS) then
        jdyddd = GetTime() - fstartTimeMS / 1000
        jdydgt = fnotInterruptible
    else
        jdyddd = nil
        jdydgt = nil
    end
end

-- ★ P0-4：原每帧调用 4 次 UnitCastingInfo/UnitChannelInfo（≈60fps 下 240 次/秒）。
--   改为帧 elapsed 累加器，每 0.1s 刷新一次（10Hz），足够打断/反制判断，CPU 大幅下降。
local WR_CastInfoAccum = 0
local WR_CastInfoInterval = 0.1
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    WR_CastInfoAccum = WR_CastInfoAccum + elapsed
    if WR_CastInfoAccum < WR_CastInfoInterval then return end
    WR_CastInfoAccum = 0
    updateCastInfo()
end)