-- ============================================================
-- Warlock Forever · Destruction 专精薄壳
-- 2026-11-13 重写：旧机械转译循环删除；逻辑全部在公共件
-- Warlock_Forever.lua 的共享段，本文件只传专精差异参数。
-- ★ 本文件不得在 WR_WarlockForever_Run 之前读 TargetDeathTime 等全局：
--   那些值由公共件 Base() 每 tick 采集，提前读会拿到上一 tick 脏值。
--   「自动 BOSS 厄运诅咒」已移入公共件 DOT 段（bossDoom 参数驱动）。
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

function WR_WarlockForeverDestruction()
    return WR_WarlockForever_Run("毁灭", {
        dotList = {
            { name = "腐蚀术", slot = 14, ttd = 6 },
            { name = "献祭",   slot = 36, ttd = 8 },
        },
        curse = nil,          -- 毁灭诅咒只走 SS_HM_EYZZ / 插入键
        drainSoul = false,
        soulFire = true,
        incinerate = true,    -- 需目标有献祭（公共件内判）
        searingPain = true,   -- 灼热之痛移动填充
        torment = false,
        metaMorph = false,
        bossDoom = true,      -- 自动 BOSS 厄运诅咒（SS_HM_EYZZ）
    })
end