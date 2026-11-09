-- ============================================================
-- Mage_Fire.lua  (★ SoD 探索赛季改编版)
-- 火焰法师自动循环 —— 符文自适应（P1-P4 一套代码，装备哪阶段符文解锁哪些技能）
-- 参考：Icy-Veins SoD 火法优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   51=火球术 52=炎爆术 53=活动炸弹 54=燃烧 55=魔爆术(AoE)
--   56=唤醒 57=法力宝石 58=冰霜新星 59=灼烧
-- ============================================================

function WR_MageFire()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("火球术")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    hotStreak = WR_GetUnitBuffTime("player", "法术连击") > 0   -- 法术连击(炎爆术瞬发)触发

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_MAGE ~= 0)   -- 默认允许 ADD 输出
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 35)

    -- ===== 3. AoE 分支（3+ 敌近身）=====
    if UnitCount8 >= 3 and inRange and WR_SpellUsable("魔爆术", true) then
        if WR_ColorFrame_ShowSkill("魔爆术", 75) then return true end
    end

    -- ===== 4. 单体核心（仅当在射程）=====
    if inRange then
        -- 4.1 活动炸弹保持（Living Bomb 手符文；目标无则补）
        if WR_SoD_HasRune("MAGE", "LivingBomb")
           and WR_GetUnitDebuffTime("target", "活动炸弹") == 0
           and WR_SpellUsable("活动炸弹", true) then
            if WR_ColorFrame_ShowSkill("活动炸弹", 3) then return true end
        end

        -- 4.2 燃烧（Burnout 胸符文；强力爆发，CD 即放）
        if WR_SoD_HasRune("MAGE", "Burnout") and WR_SpellUsable("燃烧", true) then
            if WR_ColorFrame_ShowSkill("燃烧", 58) then return true end
        end

        -- 4.3 炎爆术（法术连击触发瞬发时优先）
        if hotStreak and WR_SpellUsable("炎爆术", true) then
            if WR_ColorFrame_ShowSkill("炎爆术", 2) then return true end
        end

        -- 4.4 火球术（常驻填充）
        if WR_SpellUsable("火球术", true) then
            if WR_ColorFrame_ShowSkill("火球术", 5) then return true end
        end

        -- 4.5 灼烧（移动中无读条时用，保法术连击叠层）
        if PlayerMove and WR_SpellUsable("灼烧", true) then
            if WR_ColorFrame_ShowSkill("灼烧", 7) then return true end
        end
    end

    -- ===== 5. 法力管理 =====
    if PlayerMP < 0.25 and WR_SpellUsable("唤醒") then
        if WR_ColorFrame_ShowSkill("唤醒", 18) then return true end
    end
    if PlayerMP < 0.15 and WR_SpellUsable("法力宝石") then
        if WR_ColorFrame_ShowSkill("法力宝石", 77) then return true end
    end

    return false
end
