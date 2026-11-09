-- ============================================================
-- Druid_Feral.lua  (★ SoD 探索赛季改编版)
-- 野性德鲁伊（猫德 DPS）自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 野德优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   137=裂伤 138=野蛮咆哮 139=割裂 140=凶猛撕咬 141=撕碎 142=斜掠 143=横扫(AoE)
-- ============================================================

function WR_DruidFeral()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("撕碎")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    cp = GetComboPoints("player", "target") or 0   -- 连击点

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_DRUID ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 5)

    -- ===== 3. AoE 分支（3+ 敌近身）=====
    if UnitCount8 >= 3 and inRange and WR_SpellUsable("横扫", true) then
        if WR_ColorFrame_ShowSkill("横扫", 143) then return true end
    end

    -- ===== 4. 单体核心（近战，仅当在射程）=====
    if inRange then
        -- 4.1 裂伤（Mangle 手符文；保持 debuff 增伤）
        if WR_SoD_HasRune("DRUID", "Mangle")
           and WR_GetUnitDebuffTime("target", "裂伤") == 0
           and WR_SpellUsable("裂伤", true) then
            if WR_ColorFrame_ShowSkill("裂伤", 137) then return true end
        end

        -- 4.2 斜掠（Rake；保持流血）
        if WR_GetUnitDebuffTime("target", "斜掠") == 0 and WR_SpellUsable("斜掠", true) then
            if WR_ColorFrame_ShowSkill("斜掠", 7) then return true end
        end

        -- 4.3 野蛮咆哮（Savage Roar 腿符文；CP>=1 且无 buff 时维持）
        if WR_SoD_HasRune("DRUID", "SavageRoar")
           and cp >= 1 and WR_GetUnitBuffTime("player", "野蛮咆哮") == 0
           and WR_SpellUsable("野蛮咆哮", true) then
            if WR_ColorFrame_ShowSkill("野蛮咆哮", 37) then return true end
        end

        -- 4.4 割裂（Rip；CP>=5 且无 debuff 时上）
        if cp >= 5 and WR_GetUnitDebuffTime("target", "割裂") == 0 and WR_SpellUsable("割裂", true) then
            if WR_ColorFrame_ShowSkill("割裂", 5) then return true end
        end

        -- 4.5 凶猛撕咬（<25% 斩杀，CP>=5）
        local hpPct = WR_SafeHPPct("target")
        if hpPct < 0.25 and cp >= 5 and WR_SpellUsable("凶猛撕咬", true) then
            if WR_ColorFrame_ShowSkill("凶猛撕咬", 6) then return true end
        end

        -- 4.6 撕碎/毁伤（攒星；背后用撕碎，正面用爪击/毁伤）
        if WR_SpellUsable("撕碎", true) then
            if WR_ColorFrame_ShowSkill("撕碎", 15) then return true end
        elseif WR_SpellUsable("爪击", true) then
            if WR_ColorFrame_ShowSkill("爪击", 14) then return true end
        end
    end

    return false
end
