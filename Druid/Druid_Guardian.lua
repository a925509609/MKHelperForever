-- ============================================================
-- Druid_Guardian.lua  (★ SoD 探索赛季改编版)
-- 守护德鲁伊（熊坦）自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 守护德优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   147=精灵之火(野性) 137=裂伤 143=重殴 144=痛击(AoE) 145=狂暴回复
--   146=树皮术 148=挑战咆哮
-- ============================================================

function WR_DruidGuardian()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("重殴")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_DRUID ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 5)

    -- ===== 3. 生存技（优先）=====
    if PlayerHP < 0.50 and WR_SpellUsable("狂暴回复", true) then
        if WR_ColorFrame_ShowSkill("狂暴回复", 42) then return true end
    end
    if WR_SpellUsable("树皮术", true) then
        if WR_ColorFrame_ShowSkill("树皮术", 23) then return true end
    end

    -- ===== 4. 仇恨核心（近战，仅当在射程）=====
    if inRange then
        -- 4.1 精灵之火（野性；保持 debuff + 暴击）
        if WR_GetUnitDebuffTime("target", "精灵之火") == 0 and WR_SpellUsable("精灵之火", true) then
            if WR_ColorFrame_ShowSkill("精灵之火", 38) then return true end
        end

        -- 4.2 裂伤（Mangle 手符文；保持 debuff 增伤）
        if WR_SoD_HasRune("DRUID", "Mangle")
           and WR_GetUnitDebuffTime("target", "裂伤") == 0
           and WR_SpellUsable("裂伤", true) then
            if WR_ColorFrame_ShowSkill("裂伤", 137) then return true end
        end

        -- 4.3 重殴（Maul；怒气填充）
        if WR_SpellUsable("重殴", true) then
            if WR_ColorFrame_ShowSkill("重殴", 32) then return true end
        end

        -- 4.4 痛击（Swipe；3+ 敌 AoE 仇恨）
        if UnitCount8 >= 3 and WR_SpellUsable("痛击", true) then
            if WR_ColorFrame_ShowSkill("痛击", 144) then return true end
        end

        -- 4.5 挑战咆哮（OT 时嘲讽；需手动或 PigSet 开）
        if PigSet.GUARDIAN_TAUNT == 1 and WR_SpellUsable("挑战咆哮", true) then
            if WR_ColorFrame_ShowSkill("挑战咆哮", 36) then return true end
        end
    end

    return false
end
