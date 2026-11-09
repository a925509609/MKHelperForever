-- ============================================================
-- Druid Forever · Feral 专精循环
-- 共享 helper 见 Druid_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_DruidForeverFeral()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("撕碎")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    cp = GetComboPoints("player", "target") or 0   -- 连击点

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_DRUID ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 5)

    -- ===== 3. AoE 分支（3+ 敌近身）=====
    if UnitCount8 >= 3 and inRange and WR_SpellUsable("横扫", true) then
        if WR_ColorFrame_ShowSkill("横扫", 143) then return true end
    end

    -- ===== 4. 单体核心（近战，仅当在射程）=====
    if inRange then
        -- 4.1 裂伤（Mangle 手符文；保持 debuff 增伤）
        if WR_GetUnitDebuffTime("target", "裂伤") == 0
           and WR_SpellUsable("裂伤", true) then
            if WR_ColorFrame_ShowSkill("裂伤", 137) then return true end
        end

        -- 4.2 斜掠（Rake；保持流血）
        if WR_GetUnitDebuffTime("target", "斜掠") == 0 and WR_SpellUsable("斜掠", true) then
            if WR_ColorFrame_ShowSkill("斜掠", 7) then return true end
        end

        -- 4.3 野蛮咆哮（Savage Roar 腿符文；CP>=1 且无 buff 时维持）
        if cp >= 1 and WR_GetUnitBuffTime("player", "野蛮咆哮") == 0
           and WR_SpellUsable("野蛮咆哮", true) then
            if WR_ColorFrame_ShowSkill("野蛮咆哮", 37) then return true end
        end

        -- 4.4 割裂（Rip；CP>=5 且无 debuff 时上）
        if cp >= 5 and WR_GetUnitDebuffTime("target", "割裂") == 0 and WR_SpellUsable("割裂", true) then
            if WR_ColorFrame_ShowSkill("割裂", 5) then return true end
        end

        -- 4.5 凶猛撕咬（<25% 斩杀，CP>=5）
        local hpPct = WR_SafeHPPct("target")
        if hpPct < 0.25 and cp >= 5 and WR_SpellUsable("凶猛撕咬", true) then
            if WR_ColorFrame_ShowSkill("凶猛撕咬", 6) then return true end
        end

        -- 4.6 撕碎/毁伤（攒星；背后用撕碎，正面用爪击/毁伤）
        if WR_SpellUsable("撕碎", true) then
            if WR_ColorFrame_ShowSkill("撕碎", 15) then return true end
        elseif WR_SpellUsable("爪击", true) then
            if WR_ColorFrame_ShowSkill("爪击", 14) then return true end
        end
    end


    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("野性冲锋") and WR_SpellUsable("野性冲锋", true) then
        if WR_ColorFrame_ShowSkill("野性冲锋", 303) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("狂暴") and WR_SpellUsable("狂暴", true) then
        if WR_ColorFrame_ShowSkill("狂暴", 304) then return true end
    end
    return false
end
