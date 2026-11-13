-- ============================================================
-- Warlock Forever · Affliction 专精薄壳
-- 2026-11-13 重写：旧机械转译循环删除；逻辑全部在公共件
-- Warlock_Forever.lua 的共享段，本文件只传专精差异参数。
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

function WR_WarlockForeverAffliction()
    return WR_WarlockForever_Run("痛苦", {
        -- DOT 维持：腐蚀术(TTD>6) + 生命虹吸(不卡TTD，已学会才用)
        dotList = {
            { name = "腐蚀术",   slot = 14,  ttd = 6 },
            { name = "生命虹吸", slot = 303, ttd = 0 },
        },
        -- 灾祸二选一：痛苦默认痛苦诅咒
        curse = "痛苦诅咒",
        drainSoul = true,     -- 吸取灵魂斩杀
        soulFire = false,
        incinerate = false,
        searingPain = false,
        torment = true,       -- 折磨（无限新技能）填充
        metaMorph = false,
        bossDoom = false,
    })
end