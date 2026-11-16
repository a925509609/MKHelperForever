-- ============================================================
-- Mage_Forever_Arcane.lua
-- 《魔兽世界：无限》(Forever) 奥术专精循环
-- 改动日期：2026-11-16（按「猪猪 / 彼岸花-无限服 · 奥法页」重做）
-- ------------------------------------------------------------
-- 本文件只保留「Forever 奥术」入口；具体功能、默认值、右键小窗与
-- 全部优先级链都在 Mage/Mage_Arcane_Features.lua（新功能层）。
--
-- 与旧版（SoD 符文版）的区别：
--   1. 不再引用奥术弹幕 / 奥术涌动 / 法力宝石 / 镜像 / 冰冷血脉等
--      80 级或 SoD 专属技能；只使用 Forever 60 级真实技能。
--   2. 奥术冲击 / 奥术愤怒 / 奥术飞弹 / 填充技能（寒冰箭→霜火之箭→火球术）
--      走「读条引导」总开关，支持 叠加 / 无脑 / 奥术愤怒 三种打法。
--   3. 战斗内客户端 CD 读不到时，由功能层用 UNIT_SPELLCAST_SUCCEEDED
--      做本地冷却记账，避免爆发技能每 tick 重复点亮。
-- ============================================================

if WR_PlayerClass ~= "MAGE" then return end

function WR_MageForeverArcane()
    if type(WR_MageArcaneFeatures) == "table" and type(WR_MageArcaneFeatures.Run) == "function" then
        return WR_MageArcaneFeatures.Run() == true
    end

    -- 功能层未加载时的极简兜底：只保证有目标且射程内能提示火球术。
    local range = WR_UnitRange("target")
    if type(range) == "number" and range <= 35 and type(WR_SpellUsable) == "function" then
        local ok, usable = pcall(WR_SpellUsable, "火球术")
        if ok and usable == true then
            return WR_ColorFrame_ShowSkill("火球术", 5) == true
        end
    end
    return false
end