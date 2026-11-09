-- ============================================================
-- Warrior_Protection.lua  (★ SoD 探索赛季改编版)
-- 防护战士自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 防战优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   231=毁灭打击 232=复仇 233=盾牌猛击 234=雷霆一击 235=顺劈斩
--   236=狂暴之怒 237=破釜沉舟 238=盾牌格挡 239=挑战怒吼 240=血性狂暴
-- ============================================================

function WR_WarriorProtection()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("毁灭打击")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    Rage = WR_SafeNumber(UnitPower("player", 1), 0) or 0   -- 怒气 = powerType 1

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_ZS ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 5)

    -- ===== 3. 保命（优先）=====
    if PlayerHP < 0.40 and WR_SpellUsable("破釜沉舟", true) then
        if WR_ColorFrame_ShowSkill("破釜沉舟", 30) then return true end
    end

    -- ===== 4. 仇恨核心（近战，仅当在射程）=====
    if inRange then
        -- 4.1 毁灭打击（Devastate 手符文；破甲/上 debuff）
        if WR_SoD_HasRune("WARRIOR", "Devastate") and WR_SpellUsable("毁灭打击", true) then
            if WR_ColorFrame_ShowSkill("毁灭打击", 17) then return true end
        end

        -- 4.2 复仇（Revenge；受击触发，可用即放）
        if WR_SpellUsable("复仇", true) then
            if WR_ColorFrame_ShowSkill("复仇", 18) then return true end
        end

        -- 4.3 盾牌猛击（Shield Slam；有盾时核心）
        if WR_SpellUsable("盾牌猛击", true) then
            if WR_ColorFrame_ShowSkill("盾牌猛击", 16) then return true end
        end

        -- 4.4 雷霆一击（AoE 群拉）
        if UnitCount8 >= 3 and WR_SpellUsable("雷霆一击", true) then
            if WR_ColorFrame_ShowSkill("雷霆一击", 23) then return true end
        end

        -- 4.5 顺劈斩（AoE 仇恨填充）
        if UnitCount8 >= 2 and WR_SpellUsable("顺劈斩", true) then
            if WR_ColorFrame_ShowSkill("顺劈斩", 7) then return true end
        end

        -- 4.6 盾牌格挡（减伤，常驻维持）
        if WR_SpellUsable("盾牌格挡", true) then
            if WR_ColorFrame_ShowSkill("盾牌格挡", 31) then return true end
        end

        -- 4.7 挑战怒吼（OT 嘲讽；需 PigSet 开）
        if PigSet.WARRIOR_TAUNT == 1 and WR_SpellUsable("挑战怒吼", true) then
            if WR_ColorFrame_ShowSkill("挑战怒吼", 32) then return true end
        end
    end

    -- ===== 5. 怒气 / 解控 =====
    if Rage < 20 and WR_SpellUsable("血性狂暴", true) then
        if WR_ColorFrame_ShowSkill("血性狂暴", 12) then return true end
    end
    if WR_SpellUsable("狂暴之怒", true) then
        if WR_ColorFrame_ShowSkill("狂暴之怒", 11) then return true end
    end

    return false
end
