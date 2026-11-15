-- ============================================================
-- Warlock Forever · Destruction 专精薄壳（60级 / 无限服）
-- ------------------------------------------------------------
-- 2026-11-15 重做：按「猪猪-无限服 · 毁灭页」截图，逻辑全部在
-- Warlock_Destruction_Features.lua（WD 功能层），本文件只做派发。
-- ★ 本文件不得在采集全局之前读 PlayerHP/TargetDeathTime 等：
--   那些值由 WD.Base() 每 tick 采集，提前读会拿到上一 tick 脏值。
-- ★ 共享件 Warlock_Forever.lua 零改动：痛苦/恶魔学识不受影响。
-- ★ 旧 80 级循环参数（dotList/curse/drainSoul/soulFire/incinerate/
--   searingPain/bossDoom 等）已废弃：本层改走 WD 功能层。
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

function WR_WarlockForeverDestruction()
    if WR_WarlockDest and WR_WarlockDest.Run then
        return WR_WarlockDest.Run()
    end
    return false
end
