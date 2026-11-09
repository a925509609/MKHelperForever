-- ============================================================
-- Mage Forever · Frost 专精循环
-- 共享 helper 见 Mage_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_MageForeverFrost()
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
    local allowAdd = (PigSet.FADD_BF == 2)   -- 菜单 1=防ADD开 2=关；关时允许 ADD/起手
    if not (inBossEncounter or (UnitAffectingCombat("player") and (allowAdd or TargetInCombat))) then
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
        if WR_SpellUsable("冰冷之血", true) then
            if WR_ColorFrame_ShowSkill("冰冷之血", 4) then return true end
        end

        -- 4.2 冰枪术（Ice Lance 手符文；冰霜之指触发或平常消耗）
        if (fofProc or true) and WR_SpellUsable("冰枪术", true) then
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


    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("寒冰屏障") and WR_SpellUsable("寒冰屏障", true) then
        if WR_ColorFrame_ShowSkill("寒冰屏障", 304) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("急速冷却") and WR_SpellUsable("急速冷却", true) then
        if WR_ColorFrame_ShowSkill("急速冷却", 305) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("寒冰护盾") and WR_SpellUsable("寒冰护盾", true) then
        if WR_ColorFrame_ShowSkill("寒冰护盾", 306) then return true end
    end
    return false
end
