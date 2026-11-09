-- ============================================================
-- Mage_Arcane.lua  (★ SoD 探索赛季改编版)
-- 奥术法师自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 奥法优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   71=奥术冲击 72=奥术飞弹 73=奥术弹幕 74=奥术涌动
--   75=魔爆术(AoE) 76=唤醒 77=法力宝石
-- ============================================================

function WR_MageArcane()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("奥术冲击")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    missileProc = WR_GetUnitBuffTime("player", "奥术飞弹速射") > 0   -- 飞弹速射(奥术飞弹瞬发)触发

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_MAGE ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 35)

    -- ===== 3. AoE 分支（3+ 敌近身）=====
    if UnitCount8 >= 3 and WR_SpellUsable("魔爆术", true) then
        if WR_ColorFrame_ShowSkill("魔爆术", 75) then return true end
    end

    -- ===== 4. 单体核心（仅当在射程）=====
    if inRange then
        -- 4.1 奥术涌动（Arcane Surge 腿符文；爆发，CD 即放）
        if WR_SoD_HasRune("MAGE", "ArcaneSurge") and WR_SpellUsable("奥术涌动", true) then
            if WR_ColorFrame_ShowSkill("奥术涌动", 74) then return true end
        end

        -- 4.2 奥术飞弹（飞弹速射触发瞬发时消耗）
        if missileProc and WR_SpellUsable("奥术飞弹", true) then
            if WR_ColorFrame_ShowSkill("奥术飞弹", 14) then return true end
        end

        -- 4.3 奥术冲击（Arcane Blast 手符文；叠层输出核心）
        if WR_SoD_HasRune("MAGE", "ArcaneBlast") and WR_SpellUsable("奥术冲击", true) then
            if WR_ColorFrame_ShowSkill("奥术冲击", 13) then return true end
        end

        -- 4.4 奥术弹幕（消层/移动填充）
        if (PlayerMove or not WR_SoD_HasRune("MAGE", "ArcaneBlast"))
           and WR_SpellUsable("奥术弹幕", true) then
            if WR_ColorFrame_ShowSkill("奥术弹幕", 61) then return true end
        end
    end

    -- ===== 5. 法力管理（奥法更吃蓝）====
    if PlayerMP < 0.30 and WR_SpellUsable("唤醒") then
        if WR_ColorFrame_ShowSkill("唤醒", 18) then return true end
    end
    if PlayerMP < 0.15 and WR_SpellUsable("法力宝石") then
        if WR_ColorFrame_ShowSkill("法力宝石", 77) then return true end
    end

    return false
end
