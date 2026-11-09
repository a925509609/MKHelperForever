-- ============================================================
-- Mage_Frost.lua  (★ SoD 探索赛季改编版)
-- 冰霜法师自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 冰法优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   61=寒冰箭 62=冰枪术 63=冰冷之血 64=冰霜新星 65=暴风雪
--   66=魔爆术(AoE)
-- ============================================================

function WR_MageFrost()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("寒冰箭")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    fofProc = WR_GetUnitBuffTime("player", "冰霜之指") > 0   -- 冰霜之指(冰枪术瞬发)触发

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_MAGE ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 35)

    -- ===== 3. AoE 分支（3+ 敌近身）=====
    if UnitCount8 >= 3 then
        if inRange and WR_SpellUsable("暴风雪", true) then
            if WR_ColorFrame_ShowSkill("暴风雪", 26) then return true end
        elseif WR_SpellUsable("魔爆术", true) then
            if WR_ColorFrame_ShowSkill("魔爆术", 75) then return true end
        end
    end

    -- ===== 4. 单体核心（仅当在射程）=====
    if inRange then
        -- 4.1 冰冷之血（Icy Veins 腿符文；急速爆发，CD 即放）
        if WR_SoD_HasRune("MAGE", "IcyVeins") and WR_SpellUsable("冰冷之血", true) then
            if WR_ColorFrame_ShowSkill("冰冷之血", 4) then return true end
        end

        -- 4.2 冰枪术（Ice Lance 手符文；冰霜之指触发或平常消耗）
        if WR_SoD_HasRune("MAGE", "IceLance")
           and (fofProc or true) and WR_SpellUsable("冰枪术", true) then
            if WR_ColorFrame_ShowSkill("冰枪术", 44) then return true end
        end

        -- 4.3 冰霜新星（近身控制/保命；目标贴脸时）
        if TargetRange and TargetRange <= 8 and WR_SpellUsable("冰霜新星", true) then
            if WR_ColorFrame_ShowSkill("冰霜新星", 11) then return true end
        end

        -- 4.4 寒冰箭（常驻填充）
        if WR_SpellUsable("寒冰箭", true) then
            if WR_ColorFrame_ShowSkill("寒冰箭", 60) then return true end
        end
    end

    -- ===== 5. 法力管理 =====
    if PlayerMP < 0.25 and WR_SpellUsable("唤醒") then
        if WR_ColorFrame_ShowSkill("唤醒", 18) then return true end
    end

    return false
end
