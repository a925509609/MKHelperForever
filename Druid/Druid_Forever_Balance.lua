-- ============================================================
-- Druid Forever · Balance 专精薄壳（60级 / 无限服）
-- ------------------------------------------------------------
-- 2026-11-15 重做：按「彼岸花-无限服 · 平衡页」截图，逻辑全部在
-- Druid_Balance_Features.lua（WB 功能层），本文件只做派发。
-- ★ 本文件不得在采集全局之前读 PlayerHP/TargetDeathTime 等：
--   那些值由 WB.Base() 每 tick 采集，提前读会拿到上一 tick 脏值。
-- ★ 共享件 Druid_Forever.lua 零改动：野性/守护/恢复不受影响。
-- ★ 旧 80 级/SoD 循环参数（星落 / 月神轨道炮 / 星辰坠落 / 阳炎术 /
--   星涌术符文门 / 自然之力 / 台风等）已废弃，本服 60 级不再引用。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "DRUID" then return end

function WR_DruidForeverBalance()
    if WR_DruidBalanceUI and WR_DruidBalanceUI.Run then
        return WR_DruidBalanceUI.Run()
    end
    return false
end
