-- ============================================================
-- DeathKnight_Unholy.lua  (★ SoD 探索赛季改编版)
-- 邪恶死亡骑士自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 邪DK优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   201=疾病(血液沸腾/爆发) 213=天灾打击 214=枯萎凋零 215=召唤石像鬼
--   208=凋零缠绕 216=传染
-- ============================================================

function WR_DeathKnightUnholy()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("天灾打击")
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

    -- ===== 3. 核心（近战，仅当在射程）=====
    if inRange then
        -- 3.1 双疾病保持
        if (WR_GetUnitDebuffTime("target", "血之疫病") == 0 or WR_GetUnitDebuffTime("target", "冰霜疫病") == 0)
           and WR_SpellUsable("血液沸腾", true) then
            if WR_ColorFrame_ShowSkill("血液沸腾", 6) then return true end
        elseif (WR_GetUnitDebuffTime("target", "血之疫病") == 0 or WR_GetUnitDebuffTime("target", "冰霜疫病") == 0)
           and WR_SpellUsable("爆发", true) then
            if WR_ColorFrame_ShowSkill("爆发", 17) then return true end
        end

        -- 3.2 枯萎凋零（AoE 区域，3+ 敌时铺设）
        if UnitCount8 >= 3 and WR_SpellUsable("枯萎凋零", true) then
            if WR_ColorFrame_ShowSkill("枯萎凋零", 4) then return true end
        end

        -- 3.3 天灾打击（核心，消耗邪符文）
        if WR_SpellUsable("天灾打击", true) then
            if WR_ColorFrame_ShowSkill("天灾打击", 24) then return true end
        end

        -- 3.4 传染（多目标扩散疾病）
        if UnitCount8 >= 2 and WR_SpellUsable("传染", true) then
            if WR_ColorFrame_ShowSkill("传染", 12) then return true end
        end

        -- 3.5 凋零缠绕（符文能量填充）
        if RunicPower >= 40 and WR_SpellUsable("凋零缠绕", true) then
            if WR_ColorFrame_ShowSkill("凋零缠绕", 9) then return true end
        end
    end

    -- ===== 4. 爆发 =====
    if WR_SpellUsable("召唤石像鬼", true) then
        if WR_ColorFrame_ShowSkill("召唤石像鬼", 30) then return true end
    end

    return false
end
