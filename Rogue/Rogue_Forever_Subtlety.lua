-- ============================================================
-- Rogue Forever · Subtlety 专精循环
-- 共享 helper 见 Rogue_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_RogueForeverSubtlety()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("背刺")
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
        -- 4.1 暗影步（Shadowstrike 手符文；起手/位移，可用即放）
        if WR_SpellUsable("暗影步", true) then
            if WR_ColorFrame_ShowSkill("暗影步", 51) then return true end
        end

        -- 4.2 切割（Slice and Dice；CP>=1 且无 buff 时维持）
        if cp >= 1 and WR_GetUnitBuffTime("player", "切割") == 0 and WR_SpellUsable("切割", true) then
            if WR_ColorFrame_ShowSkill("切割", 21) then return true end
        end

        -- 4.3 割裂（Rupture；CP>=5 时上）
        if cp >= 5 and WR_GetUnitDebuffTime("target", "割裂") == 0 and WR_SpellUsable("割裂", true) then
            if WR_ColorFrame_ShowSkill("割裂", 3) then return true end
        end

        -- 4.4 剔骨（Eviscerate；CP>=5 倾泻）
        if cp >= 5 and WR_SpellUsable("剔骨", true) then
            if WR_ColorFrame_ShowSkill("剔骨", 160) then return true end
        end

        -- 4.5 背刺（背后攒星）/ 毁伤（正面）
        if WR_SpellUsable("背刺", true) then
            if WR_ColorFrame_ShowSkill("背刺", 34) then return true end
        elseif WR_SpellUsable("毁伤", true) then
            if WR_ColorFrame_ShowSkill("毁伤", 7) then return true end
        end
    end


    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("幽魂击") and WR_SpellUsable("幽魂击", true) then
        if WR_ColorFrame_ShowSkill("幽魂击", 306) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("预谋") and WR_SpellUsable("预谋", true) then
        if WR_ColorFrame_ShowSkill("预谋", 307) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("伺机待发") and WR_SpellUsable("伺机待发", true) then
        if WR_ColorFrame_ShowSkill("伺机待发", 308) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("出血") and WR_SpellUsable("出血", true) then
        if WR_ColorFrame_ShowSkill("出血", 309) then return true end
    end
    return false
end
