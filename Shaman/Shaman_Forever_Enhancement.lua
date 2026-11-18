-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "SHAMAN" then return end
-- ============================================================
-- Shaman_Forever_Enhancement.lua
-- 《魔兽世界：无限》(Forever) 增强专精循环
-- 改动日期：2026-11-16（按「猪猪 / 彼岸花-无限服 · 增强页」重做）
-- ------------------------------------------------------------
-- 本文件只保留「Forever 增强」入口；具体功能、默认值、右键小窗与
-- 全部优先级链都在 Shaman/Shaman_Enhancement_Features.lua（新功能层）。
--
-- 与旧版的区别：
-- 1. 不再引用野性狼魂 / 萨满之怒 / 熔岩猛击 / 熔岩爆裂 / 寒霜刺骨 /
--    潮汐之力等 80 级或 SoD 专属技能；只使用 Forever 60 级真实技能。
-- 2. 旧「漩涡层数」下拉 → 新拉条「漩涡武器 3层」（层数达到即打闪电箭）；
--    旧「火系图腾」下拉 → 自动图腾右键小窗（每系勾选）；
--    旧「武器附魔 / 治疗链 / 寒霜刺骨 / 偷药 / 饰品 / 手套」等旧开关下线，
--    旧档由 Shaman_Enhancement_Features.lua 迁移。
-- 3. 优先级链：护盾 → 插入 → 喝红药 → 切目标 → 防ADD门 →
--    自动图腾 → 种族爆发 → 打断(风剪) → 驱散(净化术) →
--    震击(烈焰震击/地震术) → 风暴打击 → 漩涡武器(闪电箭) →
--    火焰新星 → 大地震击。
-- ============================================================

function WR_ShamanForeverEnhancement()
    local SE = WR_ShamanEnhancementUI
    if type(SE) ~= "table" or type(SE.Run) ~= "function" then return false end
    return SE.Run() == true
end
