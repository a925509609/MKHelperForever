-- ============================================================
-- DeathKnight_RuneTracker.lua
-- 功能：监控死亡骑士六个符文的冷却时间和就绪状态
--       供邪恶DK循环判断符文可用性
-- ============================================================

if WR_PlayerClass ~= "DEATHKNIGHT" then return end

if UnitClassBase("player") ~= "DEATHKNIGHT" then
    return
end

-- 符文冷却时间（秒）
hong1cd, hong2cd, lv1cd, lv2cd, lan1cd, lan2cd = 0, 0, 0, 0, 0, 0
-- 符文是否就绪
hong1rd, hong2rd, lv1rd, lv2rd, lan1rd, lan2rd = true, true, true, true, true, true

-- 定时更新帧（每0.1秒更新符文状态，避免每帧无谓调度）
local frame = CreateFrame("Frame")
local WR_RuneAcc = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    WR_RuneAcc = WR_RuneAcc + elapsed
    if WR_RuneAcc < 0.1 then return end
    WR_RuneAcc = 0
    local start, duration, ready

    -- 符文1（红色/鲜血）
    start, duration, ready = GetRuneCooldown(1)
    if start and duration then
        hong1cd = math.max(0, (start + duration) - GetTime())
        hong1rd = ready
    end

    -- 符文2（红色/鲜血）
    start, duration, ready = GetRuneCooldown(2)
    if start and duration then
        hong2cd = math.max(0, (start + duration) - GetTime())
        hong2rd = ready
    end

    -- 符文3（绿色/邪恶）
    start, duration, ready = GetRuneCooldown(3)
    if start and duration then
        lv1cd = math.max(0, (start + duration) - GetTime())
        lv1rd = ready
    end

    -- 符文4（绿色/邪恶）
    start, duration, ready = GetRuneCooldown(4)
    if start and duration then
        lv2cd = math.max(0, (start + duration) - GetTime())
        lv2rd = ready
    end

    -- 符文5（蓝色/冰霜）
    start, duration, ready = GetRuneCooldown(5)
    if start and duration then
        lan1cd = math.max(0, (start + duration) - GetTime())
        lan1rd = ready
    end

    -- 符文6（蓝色/冰霜）
    start, duration, ready = GetRuneCooldown(6)
    if start and duration then
        lan2cd = math.max(0, (start + duration) - GetTime())
        lan2rd = ready
    end
end)