-- ============================================================
-- Druid Forever · Balance 专精循环
-- 共享 helper 见 Druid_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_DruidForeverBalance()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("愤怒")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)

    dotName = sunfire and "阳炎术" or "月火术"

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_DRUID ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 35)

    -- ===== 3. AoE 分支（3+ 敌）=====
    if UnitCount8 >= 3 and inRange and WR_SpellUsable("飓风", true) then
        if WR_ColorFrame_ShowSkill("飓风", 24) then return true end
    end

    -- ===== 4. 单体核心（仅当在射程）=====
    if inRange then
        -- 4.1 月火/阳炎 保持（DoT）
        if WR_GetUnitDebuffTime("target", dotName) == 0 and WR_SpellUsable(dotName, true) then
            if WR_ColorFrame_Show(131, dotName) then return true end
        end

        -- 4.2 星涌术（Starsurge 腿符文；瞬发填充，CD 即放）
        if WR_SpellUsable("星涌术", true) then
            if WR_ColorFrame_ShowSkill("星涌术", 132) then return true end
        end

        -- 4.3 星落（爆发，长 CD）
        if WR_SpellUsable("星落", true) then
            if WR_ColorFrame_ShowSkill("星落", 135) then return true end
        end

        -- 4.4 愤怒（常驻填充）
        if WR_SpellUsable("愤怒", true) then
            if WR_ColorFrame_ShowSkill("愤怒", 20) then return true end
        end

        -- 4.5 星火术（备选填充）
        if PlayerMove and WR_SpellUsable("星火术", true) then
            if WR_ColorFrame_ShowSkill("星火术", 21) then return true end
        end
    end


    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("虫群") and WR_SpellUsable("虫群", true) then
        if WR_ColorFrame_ShowSkill("虫群", 301) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("枭兽形态") and WR_SpellUsable("枭兽形态", true) then
        if WR_ColorFrame_ShowSkill("枭兽形态", 302) then return true end
    end
    return false
end
