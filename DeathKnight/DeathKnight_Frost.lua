-- ============================================================
-- DeathKnight_Frost.lua  (★ SoD 探索赛季改编版)
-- 冰霜死亡骑士自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 冰DK优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   201=疾病(血液沸腾/爆发) 209=湮没 210=凛风冲击 211=冰霜打击
--   212=寒冬号角 207=符文武器增效 208=凋零缠绕
-- ============================================================

function WR_DeathKnightFrost()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("湮没")
    PlayerHP = WR_GetUnitHP("player")
    RunicPower = UnitPower("player", 6) or UnitPower("player", 3) or 0
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_DK ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 5)

    -- ===== 3. 增益保持 =====
    if WR_GetUnitBuffTime("player", "寒冬号角") == 0 and WR_SpellUsable("寒冬号角", true) then
        if WR_ColorFrame_ShowSkill("寒冬号角", 15) then return true end
    end

    -- ===== 4. 核心（近战，仅当在射程）=====
    if inRange then
        -- 4.1 双疾病保持
        if (WR_GetUnitDebuffTime("target", "血之疫病") == 0 or WR_GetUnitDebuffTime("target", "冰霜疫病") == 0)
           and WR_SpellUsable("血液沸腾", true) then
            if WR_ColorFrame_ShowSkill("血液沸腾", 6) then return true end
        elseif (WR_GetUnitDebuffTime("target", "血之疫病") == 0 or WR_GetUnitDebuffTime("target", "冰霜疫病") == 0)
           and WR_SpellUsable("爆发", true) then
            if WR_ColorFrame_ShowSkill("爆发", 17) then return true end
        end

        -- 4.2 凛风冲击（AoE / 冰霜疫病下；3+ 敌优先）
        if UnitCount8 >= 3 and WR_SpellUsable("凛风冲击", true) then
            if WR_ColorFrame_ShowSkill("凛风冲击", 33) then return true end
        end

        -- 4.3 湮没（核心，消耗冰/邪符文）
        if WR_SpellUsable("湮没", true) then
            if WR_ColorFrame_ShowSkill("湮没", 35) then return true end
        end

        -- 4.4 冰霜打击（符文能量填充）
        if RunicPower >= 40 and WR_SpellUsable("冰霜打击", true) then
            if WR_ColorFrame_ShowSkill("冰霜打击", 34) then return true end
        end
    end

    -- ===== 5. 爆发 =====
    if WR_SpellUsable("符文武器增效", true) then
        if WR_ColorFrame_ShowSkill("符文武器增效", 18) then return true end
    end

    return false
end
