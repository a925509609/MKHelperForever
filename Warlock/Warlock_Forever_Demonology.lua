-- ============================================================
-- Warlock Forever · Demonology 专精薄壳（60级 / 无限服）
-- ------------------------------------------------------------
-- 2026-11-15 重做：按「猪猪-无限服 · 恶魔术页」截图，逻辑全部在
-- Warlock_Demonology_Features.lua（WD 功能层），本文件只做派发。
-- ★ 本文件不得在采集全局之前读 PlayerHP/TargetDeathTime 等：
--   那些值由 WD.Base() 每 tick 采集，提前读会拿到上一 tick 脏值。
-- ★ 共享件 Warlock_Forever.lua 零改动：痛苦/毁灭 不受影响。
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

function WR_WarlockForeverDemonology()
    if WR_WarlockDemo and WR_WarlockDemo.Run then
        return WR_WarlockDemo.Run()
    end
    return false
end
