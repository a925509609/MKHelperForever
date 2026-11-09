-- ============================================================
-- Rogue_Assassination.lua  (★ SoD 探索赛季改编版)
-- 奇袭贼（毁伤贼）自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 刺杀贼优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   151=毁伤 152=毒伤 153=割裂 155=切割 161=刀扇(AoE)
-- ============================================================

function WR_RogueAssassination()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("毁伤")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    cp = GetComboPoints("player", "target") or 0

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_DZ ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 5)

    -- ===== 3. AoE 分支（3+ 敌近身）=====
    if UnitCount8 >= 3 and inRange and WR_SpellUsable("刀扇", true) then
        if WR_ColorFrame_ShowSkill("刀扇", 26) then return true end
    end

    -- ===== 4. 单体核心（近战，仅当在射程）=====
    if inRange then
        -- 4.1 割裂（Rupture；CP>=5 且无 debuff 时上）
        if cp >= 5 and WR_GetUnitDebuffTime("target", "割裂") == 0 and WR_SpellUsable("割裂", true) then
            if WR_ColorFrame_ShowSkill("割裂", 3) then return true end
        end

        -- 4.2 切割（Slice and Dice；CP>=1 且无 buff 时维持）
        if cp >= 1 and WR_GetUnitBuffTime("player", "切割") == 0 and WR_SpellUsable("切割", true) then
            if WR_ColorFrame_ShowSkill("切割", 21) then return true end
        end

        -- 4.3 毒伤（Envenom 腿符文；CP>=5 倾泻，刷新致命毒药）
        if WR_SoD_HasRune("ROGUE", "Envenom") and cp >= 5 and WR_SpellUsable("毒伤", true) then
            if WR_ColorFrame_ShowSkill("毒伤", 6) then return true end
        end

        -- 4.4 毁伤（Mutilate 手符文；攒星）
        if WR_SoD_HasRune("ROGUE", "Mutilate") and WR_SpellUsable("毁伤", true) then
            if WR_ColorFrame_ShowSkill("毁伤", 7) then return true end
        elseif WR_SpellUsable("毒伤", true) then
            -- 无符文时仍可用毒伤清层
            if WR_ColorFrame_ShowSkill("毒伤", 6) then return true end
        end
    end

    return false
end
