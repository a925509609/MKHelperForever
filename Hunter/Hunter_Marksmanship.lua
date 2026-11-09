-- ============================================================
-- Hunter_Marksmanship.lua  (★ SoD 探索赛季改编版)
-- 射击猎人自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 射击猎优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   77=奇美拉射击 78=稳固射击 79=瞄准射击 73=杀戮射击 74=多重射击
--   75=毒蛇钉刺 76=雄鹰守护 78b=蝰蛇守护 79b=雄狮守护 85=自动射击
-- ============================================================

function WR_HunterMarksmanship()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.4
    GCD = WR_GetGCD("毒蛇钉刺")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    AutoShotOn = IsAutoRepeatSpell("自动射击")

    -- ===== 2. 自动射击保持 =====
    if not AutoShotOn and UnitCanAttack("player", "target") and not UnitIsDead("target")
       and (TargetRange and TargetRange <= 35) and WR_SpellUsable("自动射击") then
        if WR_ColorFrame_ShowSkill("自动射击", 85) then return true end
    end

    -- ===== 3. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_LR ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 35)

    -- ===== 4. 守护切换 =====
    if WR_SoD_HasRune("HUNTER", "AspectOfLion") and WR_GetUnitBuffTime("player", "雄狮守护") == 0
       and WR_SpellUsable("雄狮守护") then
        if WR_ColorFrame_ShowSkill("雄狮守护", 19) then return true end
    elseif PlayerMP < 0.30 and WR_GetUnitBuffTime("player", "蝰蛇守护") == 0 and WR_SpellUsable("蝰蛇守护") then
        if WR_ColorFrame_ShowSkill("蝰蛇守护", 78) then return true end
    elseif PlayerMP >= 0.30 and WR_GetUnitBuffTime("player", "雄鹰守护") == 0 and WR_SpellUsable("雄鹰守护") then
        if WR_ColorFrame_ShowSkill("雄鹰守护", 76) then return true end
    end

    -- ===== 5. 毒蛇钉刺保持 =====
    if WR_GetUnitDebuffTime("target", "毒蛇钉刺") == 0 and inRange and WR_SpellUsable("毒蛇钉刺", true) then
        if WR_ColorFrame_ShowSkill("毒蛇钉刺", 6) then return true end
    end

    -- ===== 6. 核心输出（仅当在射程）=====
    if inRange then
        -- 6.1 杀戮射击（<20% 斩杀）
        local hpPct = WR_SafeHPPct("target")
        if hpPct < 0.20 and WR_SpellUsable("杀戮射击", true) then
            if WR_ColorFrame_ShowSkill("杀戮射击", 5) then return true end
        end

        -- 6.2 奇美拉射击（Chimera Shot 手符文；核心，CD 即放）
        if WR_SoD_HasRune("HUNTER", "ChimeraShot") and WR_SpellUsable("奇美拉射击", true) then
            if WR_ColorFrame_ShowSkill("奇美拉射击", 14) then return true end
        end

        -- 6.3 多重射击（3+ 敌 AoE）
        if UnitCount8 >= 3 and WR_SpellUsable("多重射击", true) then
            if WR_ColorFrame_ShowSkill("多重射击", 20) then return true end
        end

        -- 6.4 瞄准射击（稳固读条时填充）
        if WR_SpellUsable("瞄准射击", true) then
            if WR_ColorFrame_ShowSkill("瞄准射击", 13) then return true end
        end

        -- 6.5 稳固射击（聚焦/填充）
        if WR_SpellUsable("稳固射击", true) then
            if WR_ColorFrame_ShowSkill("稳固射击", 12) then return true end
        end
    end

    return false
end
