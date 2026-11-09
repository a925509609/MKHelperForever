-- ============================================================
-- Shaman_Elemental.lua  (★ SoD 探索赛季改编版)
-- 元素萨满自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 元素萨优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   111=闪电箭 112=烈焰震击 113=熔岩爆裂 114=闪电链 115=元素掌握
--   116=火元素图腾
-- ============================================================

function WR_ShamanElemental()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("闪电箭")
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
    local allowAdd = (PigSet.FANG_ADD_SM ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 35)

    -- ===== 3. AoE 分支（3+ 敌）=====
    if UnitCount8 >= 3 and inRange and WR_SpellUsable("闪电链", true) then
        if WR_ColorFrame_ShowSkill("闪电链", 11) then return true end
    end

    -- ===== 4. 单体核心（仅当在射程）=====
    if inRange then
        -- 4.1 烈焰震击（保持，供熔岩爆裂必爆）
        if WR_GetUnitDebuffTime("target", "烈焰震击") == 0 and WR_SpellUsable("烈焰震击", true) then
            if WR_ColorFrame_ShowSkill("烈焰震击", 5) then return true end
        end

        -- 4.2 熔岩爆裂（Lava Burst 手符文；有烈焰震击必爆，CD 即放）
        if WR_SoD_HasRune("SHAMAN", "LavaBurst")
           and WR_GetUnitDebuffTime("target", "烈焰震击") > 0
           and WR_SpellUsable("熔岩爆裂", true) then
            if WR_ColorFrame_ShowSkill("熔岩爆裂", 31) then return true end
        end

        -- 4.3 元素掌握（爆发，CD 即放）
        if WR_SpellUsable("元素掌握", true) then
            if WR_ColorFrame_ShowSkill("元素掌握", 43) then return true end
        end

        -- 4.4 闪电箭（常驻填充）
        if WR_SpellUsable("闪电箭", true) then
            if WR_ColorFrame_ShowSkill("闪电箭", 4) then return true end
        end
    end

    -- ===== 5. 火元素图腾（长 CD 爆发）=====
    if WR_SpellUsable("火元素图腾", true) then
        if WR_ColorFrame_ShowSkill("火元素图腾", 116) then return true end
    end

    return false
end
