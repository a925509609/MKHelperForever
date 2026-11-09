-- ============================================================
-- Shaman_Enhancement.lua  (★ SoD 探索赛季改编版)
-- 增强萨满自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 增强萨优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   117=风暴打击 118=熔岩猛击 112=烈焰震击 119=大地震击
--   120=漩涡武器(闪电箭) 121=野性狼魂 122=萨满之怒
-- ============================================================

function WR_ShamanEnhancement()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("风暴打击")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    maelstrom = WR_GetUnitBuffTime("player", "漩涡武器") > 0   -- 漩涡武器(闪电箭/链消耗)

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_SM ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 5)

    -- ===== 3. 核心（近战，仅当在射程）=====
    if inRange then
        -- 3.1 烈焰震击（保持，供熔岩猛击增伤）
        if WR_GetUnitDebuffTime("target", "烈焰震击") == 0 and WR_SpellUsable("烈焰震击", true) then
            if WR_ColorFrame_ShowSkill("烈焰震击", 5) then return true end
        end

        -- 3.2 风暴打击（核心，CD 即放）
        if WR_SpellUsable("风暴打击", true) then
            if WR_ColorFrame_ShowSkill("风暴打击", 3) then return true end
        end

        -- 3.3 熔岩猛击（Lava Lash 手符文；有烈焰震击增伤，CD 即放）
        if WR_SoD_HasRune("SHAMAN", "LavaLash")
           and WR_GetUnitDebuffTime("target", "烈焰震击") > 0
           and WR_SpellUsable("熔岩猛击", true) then
            if WR_ColorFrame_ShowSkill("熔岩猛击", 10) then return true end
        end

        -- 3.4 漩涡武器消耗（闪电箭/链，满层优先）
        if maelstrom and WR_SpellUsable("闪电箭", true) then
            if WR_ColorFrame_ShowSkill("漩涡武器", 120) then return true end
        end

        -- 3.5 大地震击（填充）
        if WR_SpellUsable("大地震击", true) then
            if WR_ColorFrame_ShowSkill("大地震击", 8) then return true end
        end
    end

    -- ===== 4. 爆发 / 法力 =====
    if WR_SpellUsable("野性狼魂", true) then
        if WR_ColorFrame_ShowSkill("野性狼魂", 18) then return true end
    end
    if PlayerMP < 0.30 and WR_SpellUsable("萨满之怒") then
        if WR_ColorFrame_ShowSkill("萨满之怒", 13) then return true end
    end

    return false
end
