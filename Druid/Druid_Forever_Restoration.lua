-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "DRUID" then return end
-- ============================================================
-- Druid Forever · Restoration 专精薄壳（60级 / 无限服）
-- ------------------------------------------------------------
-- 2026-11-16 重做：按「彼岸花-无限服 · 恢复页」截图，逻辑全部在
-- Druid_Restoration_Features.lua（WT 功能层），本文件只做派发。
-- ★ 本文件不得在采集全局之前读 PlayerHP/TargetDeathTime 等：
--   那些值由 WT.Base() 每 tick 采集，提前读会拿到上一 tick 脏值。
-- ★ 共享件 Druid_Forever.lua 零改动：平衡/野性/守护不受影响。
-- ★ 旧 80 级循环参数（dotList/生命绽放/树皮术/狂咒/血肉成灰等）已移除。
-- ============================================================

function WR_DruidForeverRestoration()
    if type(WR_DruidRestorationUI) ~= "table" then return false end
    if type(WR_DruidRestorationUI.Run) ~= "function" then return false end
    return WR_DruidRestorationUI.Run()
end
