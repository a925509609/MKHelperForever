-- ============================================================
-- Warlock Forever · Affliction 专精薄壳（60级 / 无限服）
-- ------------------------------------------------------------
-- 2026-11-15 重做：按「彼岸花-无限服 · 痛苦页」截图，逻辑全部在
-- Warlock_Affliction_Features.lua（WA 功能层），本文件只做派发。
-- ★ 本文件不得在采集全局之前读 PlayerHP/TargetDeathTime 等：
--   那些值由 WA.Base() 每 tick 采集，提前读会拿到上一 tick 脏值。
-- ★ 共享件 Warlock_Forever.lua 零改动：毁灭/恶魔学识不受影响。
-- ★ 旧 80 级循环参数（dotList/curse="痛苦诅咒"/drainSoul/torment 等）
--   已废弃：痛苦诅咒/厄运诅咒本服不存在（改「灾祸」），80 级技能全部移除。
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

function WR_WarlockForeverAffliction()
    if WR_WarlockAffl and WR_WarlockAffl.Run then
        return WR_WarlockAffl.Run()
    end
    return false
end
