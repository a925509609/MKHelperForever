-- ============================================================
-- Priest_Shadow.lua  (★ SoD 探索赛季改编版)
-- 暗影牧师自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 暗牧优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   171=暗言术：痛 172=吸血鬼之触 173=噬灵疫病 174=心灵震爆
--   175=精神鞭笞 176=暗言术：死 177=暗影魔 178=消散
-- ============================================================

function WR_PriestShadow()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("精神鞭笞")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_MS ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 35)

    -- ===== 3. 单体核心（仅当在射程）=====
    if inRange then
        -- 3.1 暗言术：痛（保持）
        if WR_GetUnitDebuffTime("target", "暗言术：痛") == 0 and WR_SpellUsable("暗言术：痛", true) then
            if WR_ColorFrame_ShowSkill("暗言术：痛", 14) then return true end
        end

        -- 3.2 吸血鬼之触（保持）
        if WR_GetUnitDebuffTime("target", "吸血鬼之触") == 0 and WR_SpellUsable("吸血鬼之触", true) then
            if WR_ColorFrame_ShowSkill("吸血鬼之触", 1) then return true end
        end

        -- 3.3 噬灵疫病（Void Plague 胸符文；保持）
        if WR_SoD_HasRune("PRIEST", "VoidPlague")
           and WR_GetUnitDebuffTime("target", "噬灵疫病") == 0
           and WR_SpellUsable("噬灵疫病", true) then
            if WR_ColorFrame_ShowSkill("噬灵疫病", 3) then return true end
        end

        -- 3.4 心灵震爆（CD 即放）
        if WR_SpellUsable("心灵震爆", true) then
            if WR_ColorFrame_ShowSkill("心灵震爆", 4) then return true end
        end

        -- 3.5 暗言术：死（Shadow Word: Death 手符文；斩杀/低血）
        if WR_SoD_HasRune("PRIEST", "ShadowWordDeath") and WR_SpellUsable("暗言术：死", true) then
            if WR_ColorFrame_ShowSkill("暗言术：死", 176) then return true end
        end

        -- 3.6 精神鞭笞（常驻填充）
        if WR_SpellUsable("精神鞭笞", true) then
            if WR_ColorFrame_ShowSkill("精神鞭笞", 5) then return true end
        end
    end

    -- ===== 4. 法力 / 保命 =====
    if PlayerMP < 0.30 and WR_SpellUsable("暗影魔", true) then
        if WR_ColorFrame_ShowSkill("暗影魔", 7) then return true end
    end
    if PlayerHP < 0.35 and WR_SpellUsable("消散", true) then
        if WR_ColorFrame_ShowSkill("消散", 11) then return true end
    end

    return false
end
