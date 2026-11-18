-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "MAGE" then return end
-- ============================================================
-- Mage_Forever_Fire.lua
-- 《魔兽世界：无限》(Forever) 火焰专精循环
-- 改动日期：2026-11-16（按「猪猪 / 彼岸花-无限服 · 火法页」重做）
-- ------------------------------------------------------------
-- 本文件只保留「Forever 火焰」入口；具体功能、默认值、右键小窗与
-- 全部优先级链都在 Mage/Mage_Fire_Features.lua（新功能层）。
--
-- 与旧版的区别：
-- 1. 不再引用活动炸弹 / 镜像 / 冰冷血脉 / 法力宝石 / 法术连击等
--    80 级或 SoD 专属逻辑；只使用 Forever 60 级真实火焰技能。
-- 2. 旧「火球OR霜火」下拉 → 读条引导右键小窗五技能勾选；
--    旧「自动燃烧」→ 爆发「燃烧」勾选。
-- ============================================================

function WR_MageForeverFire()
    if WR_MageFireFeatures and type(WR_MageFireFeatures.Run) == "function" then
        return WR_MageFireFeatures.Run()
    end
    return false
end
