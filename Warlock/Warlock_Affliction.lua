-- ============================================================
-- Warlock_Affliction.lua  (★ SoD 探索赛季改编版)
-- 痛苦术自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 痛苦术优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   91=暗影箭 92=鬼影缠身 93=痛苦无常 94=腐蚀术 95=痛苦诅咒
--   96=吸取灵魂 97=生命分流 104=腐蚀之种(AoE)
-- ============================================================

function WR_WarlockAffliction()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("暗影箭")
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
    local allowAdd = (PigSet.FANG_ADD_WL ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 35)

    -- ===== 3. AoE 分支（3+ 敌）=====
    if UnitCount8 >= 3 and inRange and WR_SpellUsable("腐蚀之种", true) then
        if WR_ColorFrame_ShowSkill("腐蚀之种", 23) then return true end
    end

    -- ===== 4. 单体核心（仅当在射程）=====
    if inRange then
        -- 4.1 鬼影缠身（Haunt 手符文；保持并回蓝）
        if WR_SoD_HasRune("WARLOCK", "Haunt")
           and WR_GetUnitDebuffTime("target", "鬼影缠身") == 0
           and WR_SpellUsable("鬼影缠身", true) then
            if WR_ColorFrame_ShowSkill("鬼影缠身", 5) then return true end
        end

        -- 4.2 吸取灵魂（<20% 斩杀，需鬼影缠身增伤）
        local hpPct = WR_SafeHPPct("target")
        if hpPct < 0.20 and WR_SpellUsable("吸取灵魂", true) then
            if WR_ColorFrame_ShowSkill("吸取灵魂", 11) then return true end
        end

        -- 4.3 痛苦无常（保持）
        if WR_GetUnitDebuffTime("target", "痛苦无常") == 0 and WR_SpellUsable("痛苦无常", true) then
            if WR_ColorFrame_ShowSkill("痛苦无常", 2) then return true end
        end

        -- 4.4 腐蚀术（保持）
        if WR_GetUnitDebuffTime("target", "腐蚀术") == 0 and WR_SpellUsable("腐蚀术", true) then
            if WR_ColorFrame_ShowSkill("腐蚀术", 14) then return true end
        end

        -- 4.5 痛苦诅咒（保持）
        if WR_GetUnitDebuffTime("target", "痛苦诅咒") == 0 and WR_SpellUsable("痛苦诅咒", true) then
            if WR_ColorFrame_ShowSkill("痛苦诅咒", 3) then return true end
        end

        -- 4.6 暗影箭（填充 + 暗影之拥）
        if WR_SpellUsable("暗影箭", true) then
            if WR_ColorFrame_ShowSkill("暗影箭", 6) then return true end
        end
    end

    -- ===== 5. 法力管理（生命分流）=====
    if PlayerMP < 0.40 and WR_SpellUsable("生命分流") then
        if WR_ColorFrame_ShowSkill("生命分流", 10) then return true end
    end

    return false
end
