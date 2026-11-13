-- ============================================================
-- Warlock Forever · Demonology 专精薄壳
-- 2026-11-13 重写：旧机械转译循环删除；逻辑全部在公共件
-- Warlock_Forever.lua 的共享段，本文件只传专精差异参数。
-- ★ 本文件不得在 WR_WarlockForever_Run 之前读 PlayerHP/TargetDeathTime 等
--   全局：那些值由公共件 Base() 每 tick 采集，提前读会拿到上一 tick 脏值。
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

function WR_WarlockForeverDemonology()
    -- 灾祸二选一：SS_EM_TKZZ 打开后不再放厄运诅咒 → 用痛苦诅咒
    local curse = (PigSet.SS_EM_TKZZ == true) and "痛苦诅咒" or "厄运诅咒"

    return WR_WarlockForever_Run("恶魔学识", {
        dotList = {
            { name = "腐蚀术", slot = 14, ttd = 6 },
            { name = "献祭",   slot = 36, ttd = 8 },
        },
        curse = curse,
        drainSoul = true,
        soulFire = true,      -- 灭杀/低血 灵魂之火
        incinerate = true,    -- 烧尽填充
        searingPain = false,
        torment = false,
        metaMorph = true,     -- 恶魔变形自动（SS_EM_ZDEMBX，战斗门后由公共件处理）
        bossDoom = false,
    })
end