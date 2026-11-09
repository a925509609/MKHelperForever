-- ============================================================
-- Rogue Forever · Combat 专精循环
-- 共享 helper 见 Rogue_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_RogueForeverCombat()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("影袭")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    cp = GetComboPoints("player", "target") or 0

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_DZ ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 5)

    -- ===== 3. AoE 分支（3+ 敌近身）=====
    if UnitCount8 >= 3 and inRange and WR_SpellUsable("刀扇", true) then
        if WR_ColorFrame_ShowSkill("刀扇", 26) then return true end
    end

    -- ===== 4. 单体核心（近战，仅当在射程）=====
    if inRange then
        -- 4.1 切割（Slice and Dice；CP>=1 且无 buff 时维持）
        if cp >= 1 and WR_GetUnitBuffTime("player", "切割") == 0 and WR_SpellUsable("切割", true) then
            if WR_ColorFrame_ShowSkill("切割", 21) then return true end
        end

        -- 4.2 割裂（Rupture；CP>=5 时上）
        if cp >= 5 and WR_GetUnitDebuffTime("target", "割裂") == 0 and WR_SpellUsable("割裂", true) then
            if WR_ColorFrame_ShowSkill("割裂", 3) then return true end
        end

        -- 4.3 要害打击（Between the Eyes 腿符文；CP>=5 眩晕+伤害）
        if cp >= 5 and WR_SpellUsable("要害打击", true) then
            if WR_ColorFrame_ShowSkill("要害打击", 156) then return true end
        end

        -- 4.4 军刀猛刺（Saber Slash 手符文；攒星）
        if WR_SpellUsable("军刀猛刺", true) then
            if WR_ColorFrame_ShowSkill("军刀猛刺", 154) then return true end
        end

        -- 4.5 影袭/邪恶攻击（填充攒星）
        if WR_SpellUsable("影袭", true) then
            if WR_ColorFrame_ShowSkill("影袭", 24) then return true end
        elseif WR_SpellUsable("邪恶攻击", true) then
            if WR_ColorFrame_ShowSkill("邪恶攻击", 31) then return true end
        end
    end


    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("还击") and WR_SpellUsable("还击", true) then
        if WR_ColorFrame_ShowSkill("还击", 303) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("剑刃乱舞") and WR_SpellUsable("剑刃乱舞", true) then
        if WR_ColorFrame_ShowSkill("剑刃乱舞", 304) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("冲动") and WR_SpellUsable("冲动", true) then
        if WR_ColorFrame_ShowSkill("冲动", 305) then return true end
    end
    return false
end
