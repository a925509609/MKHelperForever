-- ============================================================
-- Warlock Forever · Destruction 专精循环
-- 共享 helper 见 Warlock_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_WarlockForeverDestruction()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("烧尽")
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
        -- 4.1 混乱箭（Chaos Bolt 手符文；核心，CD 即放）
        if WR_SpellUsable("混乱箭", true) then
            if WR_ColorFrame_ShowSkill("混乱箭", 98) then return true end
        end

        -- 4.2 献祭（保持，供燃烧消耗）
        if WR_GetUnitDebuffTime("target", "献祭") == 0 and WR_SpellUsable("献祭", true) then
            if WR_ColorFrame_ShowSkill("献祭", 36) then return true end
        end

        -- 4.3 燃烧（消耗献祭，必爆）
        if WR_GetUnitDebuffTime("target", "献祭") > 0 and WR_SpellUsable("燃烧", true) then
            if WR_ColorFrame_ShowSkill("燃烧", 42) then return true end
        end

        -- 4.4 烧尽（核心填充）
        if WR_SpellUsable("烧尽", true) then
            if WR_ColorFrame_ShowSkill("烧尽", 39) then return true end
        end

        -- 4.5 暗影箭（移动填充）
        if PlayerMove and WR_SpellUsable("暗影箭", true) then
            if WR_ColorFrame_ShowSkill("暗影箭", 6) then return true end
        end
    end

    -- ===== 5. 法力管理 =====
    if PlayerMP < 0.40 and WR_SpellUsable("生命分流") then
        if WR_ColorFrame_ShowSkill("生命分流", 10) then return true end
    end


    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("暗影灼烧") and WR_SpellUsable("暗影灼烧", true) then
        if WR_ColorFrame_ShowSkill("暗影灼烧", 308) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("浩劫诅咒") and WR_SpellUsable("浩劫诅咒", true) then
        if WR_ColorFrame_ShowSkill("浩劫诅咒", 309) then return true end
    end
    return false
end
