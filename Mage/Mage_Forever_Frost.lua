-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "MAGE" then return end
-- ============================================================
-- Mage_Forever_Frost.lua
-- 《魔兽世界：无限》(Forever) 冰霜专精循环
-- 改动日期：2026-11-16（按「猪猪 / 彼岸花-无限服 · 冰霜页」重做）
-- ------------------------------------------------------------
-- 本文件只保留「Forever 冰霜」入口；具体功能、默认值、右键小窗与
-- 全部优先级链都在 Mage/Mage_Frost_Features.lua（新功能层）。
--
-- 与旧版的区别：
-- 1. 不再引用狂咒 / 镜像 / 冰冷血脉 / 法力宝石 / 隐身术 / 深冻 / 寒冰宝珠 /
--    召唤水元素等 80 级或 SoD 专属逻辑；只使用 Forever 60 级真实冰霜技能。
-- 2. 旧「智能AOE模式」→ 奥爆拉条（8码内目标数阈值）；旧「自动种族」→
--    爆发「种族爆发」勾选；旧「插入暴风雪」→ 插入区开关。
-- ============================================================

function WR_MageForeverFrost()
    if WR_MageFrostFeatures and type(WR_MageFrostFeatures.Run) == "function" then
        return WR_MageFrostFeatures.Run()
    end
    return false
end
