-- ============================================================
-- Druid Forever · Guardian 专精循环
-- 共享 helper 见 Druid_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_DruidForeverGuardian()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("重殴")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_DRUID ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 5)

    -- ===== 3. 生存技（优先）=====
    if PlayerHP < 0.50 and WR_SpellUsable("狂暴回复", true) then
        if WR_ColorFrame_ShowSkill("狂暴回复", 42) then return true end
    end
    if WR_SpellUsable("树皮术", true) then
        if WR_ColorFrame_ShowSkill("树皮术", 23) then return true end
    end

    -- ===== 4. 仇恨核心（近战，仅当在射程）=====
    if inRange then
        -- 4.1 精灵之火（野性；保持 debuff + 暴击）
        if WR_GetUnitDebuffTime("target", "精灵之火") == 0 and WR_SpellUsable("精灵之火", true) then
            if WR_ColorFrame_ShowSkill("精灵之火", 38) then return true end
        end

        -- 4.2 裂伤（Mangle 手符文；保持 debuff 增伤）
        if WR_GetUnitDebuffTime("target", "裂伤") == 0
           and WR_SpellUsable("裂伤", true) then
            if WR_ColorFrame_ShowSkill("裂伤", 137) then return true end
        end

        -- 4.3 重殴（Maul；怒气填充）
        if WR_SpellUsable("重殴", true) then
            if WR_ColorFrame_ShowSkill("重殴", 32) then return true end
        end

        -- 4.4 痛击（Swipe；3+ 敌 AoE 仇恨）
        if UnitCount8 >= 3 and WR_SpellUsable("痛击", true) then
            if WR_ColorFrame_ShowSkill("痛击", 144) then return true end
        end

        -- 4.5 挑战咆哮（OT 时嘲讽；需手动或 PigSet 开）
        if PigSet.GUARDIAN_TAUNT == 1 and WR_SpellUsable("挑战咆哮", true) then
            if WR_ColorFrame_ShowSkill("挑战咆哮", 36) then return true end
        end
    end


    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("野性冲锋") and WR_SpellUsable("野性冲锋", true) then
        if WR_ColorFrame_ShowSkill("野性冲锋", 305) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("狂暴") and WR_SpellUsable("狂暴", true) then
        if WR_ColorFrame_ShowSkill("狂暴", 306) then return true end
    end
    return false
end
