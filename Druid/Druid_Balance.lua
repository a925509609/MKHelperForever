-- ============================================================
-- Druid_Balance.lua  (★ SoD 探索赛季改编版)
-- 平衡德鲁伊（鸟德）自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 平衡德优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   131=月火术/阳炎术 132=星涌术 133=愤怒 134=星火术 135=星落 136=飓风
-- ============================================================

function WR_DruidBalance()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("愤怒")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    sunfire = WR_SoD_HasRune("DRUID", "Sunfire")   -- 阳炎术符文（取代月火术）
    dotName = sunfire and "阳炎术" or "月火术"

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_DRUID ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 35)

    -- ===== 3. AoE 分支（3+ 敌）=====
    if UnitCount8 >= 3 and inRange and WR_SpellUsable("飓风", true) then
        if WR_ColorFrame_ShowSkill("飓风", 24) then return true end
    end

    -- ===== 4. 单体核心（仅当在射程）=====
    if inRange then
        -- 4.1 月火/阳炎 保持（DoT）
        if WR_GetUnitDebuffTime("target", dotName) == 0 and WR_SpellUsable(dotName, true) then
            if WR_ColorFrame_Show(131, dotName) then return true end
        end

        -- 4.2 星涌术（Starsurge 腿符文；瞬发填充，CD 即放）
        if WR_SoD_HasRune("DRUID", "Starsurge") and WR_SpellUsable("星涌术", true) then
            if WR_ColorFrame_ShowSkill("星涌术", 132) then return true end
        end

        -- 4.3 星落（爆发，长 CD）
        if WR_SpellUsable("星落", true) then
            if WR_ColorFrame_ShowSkill("星落", 135) then return true end
        end

        -- 4.4 愤怒（常驻填充）
        if WR_SpellUsable("愤怒", true) then
            if WR_ColorFrame_ShowSkill("愤怒", 20) then return true end
        end

        -- 4.5 星火术（备选填充）
        if PlayerMove and WR_SpellUsable("星火术", true) then
            if WR_ColorFrame_ShowSkill("星火术", 21) then return true end
        end
    end

    return false
end
