-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "DRUID" then return end
-- ============================================================
-- Druid Forever · Feral 专精薄壳（60级 / 无限服）
-- ------------------------------------------------------------
-- 2026-11-16 重做：按「彼岸花-无限服 · 野性页」截图，逻辑全部在
-- Druid_Feral_Features.lua（WF 功能层），本文件只做派发。
-- ★ 本文件不得在采集全局之前读 PlayerHP/TargetDeathTime 等：
--   那些值由 WF.Base() 每 tick 采集，提前读会拿到上一 tick 脏值。
-- ★ 共享件 Druid_Forever.lua 零改动：平衡/守护/恢复不受影响。
-- ★ 旧 80 级/SoD 循环参数（野蛮咆哮 / 割碎 / 痛击 / 重殴 /
--   横扫（豹/熊）/ 寒霜刺骨等）已废弃，本服 60 级不再引用。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "DRUID" then return end

function WR_DruidForeverFeral()
    if WR_DruidFeralUI and WR_DruidFeralUI.Run then
        return WR_DruidFeralUI.Run()
    end
    return false
end
