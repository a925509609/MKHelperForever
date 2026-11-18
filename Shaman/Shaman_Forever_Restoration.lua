-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "SHAMAN" then return end
-- ============================================================
-- Shaman Forever · Restoration 专精薄壳（60级 / 无限服）
-- ------------------------------------------------------------
-- 2026-11-16 重做：按「猪猪 / 彼岸花-无限服 · 恢复萨满页」截图，
-- 逻辑全部在 Shaman_Restoration_Features.lua（SR 功能层），本文件只做派发。
-- ★ 本文件不得在采集全局之前读 PlayerHP/TargetDeathTime 等：
--   那些值由 SR.Base() 每 tick 采集，提前读会拿到上一 tick 脏值。
-- ★ 共享件 Shaman_Forever.lua 零改动：元素/增强不受影响。
-- ★ 旧 80 级循环参数（治疗之雨/潮汐之力/狂咒/过量停条等）已移除。
-- ============================================================

function WR_ShamanForeverRestoration()
    if type(WR_ShamanRestorationUI) ~= "table" then return false end
    if type(WR_ShamanRestorationUI.Run) ~= "function" then return false end
    return WR_ShamanRestorationUI.Run()
end
