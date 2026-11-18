-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "PALADIN" then return end
-- ============================================================
-- Paladin Forever · Ret 专精循环（60级 / 无限服）
-- ------------------------------------------------------------
-- 2026-11-15 按「彼岸花-无限服 · 惩戒页」重做：
--   选择：防ADD（FANG_ADD_CJQ）
--   拉条：喝红药 90 / 圣疗术 69 / 奉献 4目标
--   功能：圣印（常驻 / 解封之怒舞 / 保持审判 / 卡CD审判）/ 祝福 /
--         切换目标 / 驱散 / 愤怒之锤 / 驱邪术
--   插入：制裁 / 圣佑 / 审判 / 奉献（一次性，放完自关）
--   主循环：圣印层 → 神圣打击 → 审判兜底 → 驱邪术 → 愤怒之锤 → 奉献
-- ★ 80 级技能（复仇之怒 / 祈求圣光 / 神圣牺牲 / 十字军打击 /
--   神圣震击 / 神恩术 / 真理之声 / 光之守夜 / 圣殿壁垒）在无限服
--   惩戒不存在或非惩戒天赋，本循环不再引用。
-- 共享 helper 见 Paladin_Forever.lua（公共件），功能层见
-- Paladin_Retribution_Features.lua（RT 命名空间）。
-- ============================================================

function WR_PaladinForeverRet()
    local RT = WR_PaladinRetUI
    WR_PaladinForever_ClearStalePrompts(1.0)
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("审判")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)

    -- 1. 祝福（脱战自动补；总开关在功能区「祝福」图标）
    if RT.On("CJ_BLESS_ON", true) and type(WR_PaladinBlessing_Auto) == "function" and WR_PaladinBlessing_Auto() then return true end

    -- 2. 圣疗术（自疗：血量低于拉条）
    local sls = RT.Val("CJ_SLLS", 69)
    local hpSafe = tonumber(PlayerHP) or 1
    if sls > 0 and hpSafe < sls / 100 and RT.SpellKnown("圣疗术")
       and WR_SpellUsable("圣疗术", true) then
        if WR_PaladinForever_ShowSkillCD("圣疗术", 48, 1200) then return true end
    end

    -- 3. 喝红药
    if RT.PotionStep() then return true end

    -- 4. 插入（一次性：制裁 / 圣佑 / 审判 / 奉献）
    if RT.InsertStep() then return true end

    -- 5. 驱散（清洁术：常规/优先/目标/指向，见右键或下拉）
    if RT.On("CJ_QJS_ON", true) then
        if WR_PaladinForever_CleanseStep("CJ_QJS", "priority") then return true end
        if WR_PaladinForever_CleanseStep("CJ_QJS", "normal") then return true end
    end

    -- 6. 自动攻击（仅开怪前提示；战斗中视为已激活）
    if not PlayerMove and UnitCanAttack("player", "target") and not UnitIsDead("target")
       and not WR_PaladinForever_AutoAttackActive() and WR_SpellUsable("攻击") then
        if WR_ColorFrame_ShowSkill("攻击", 15) then return true end
    end

    -- 7. 切换目标（没有可攻击目标时自动找）
    if RT.TargetSwitchStep() then return true end

    -- 8. 战斗主循环门（防 ADD）
    if not WR_PaladinForever_InCombatGate(PigSet.FANG_ADD_CJQ == 1 or PigSet.FANG_ADD_CJQ == 2) then
        return false
    end

    -- 9. 圣印层：常驻圣印 / 解封之怒舞 / 保持审判 / 卡CD审判
    if RT.SealStep() then return true end

    -- 10. 主循环
    local hsRangeOK = (TargetRange == nil or TargetRange >= 999 or TargetRange <= 8)
    local danceActive = RT.On("CJ_SY_ON", true) and RT.On("CJ_SY_JF", true) and RT.SpellKnown("解封之怒")

    -- 10.1 神圣打击（核心输出，冷却好了就打）
    if hsRangeOK and RT.SpellKnown("神圣打击") and WR_SpellUsable("神圣打击", true) then
        local hsCD = (type(WR_PaladinForever_SkillCD) == "table" and WR_PaladinForever_SkillCD["神圣打击"]) or 6
        if WR_PaladinForever_ShowSkillCD("神圣打击", 74, hsCD) then return true end
    end

    -- 10.2 审判兜底（未开「卡CD使用」且非舞印时，保持自动审判）
    if not danceActive and not RT.On("CJ_SY_KCD", true) then
        local okA, active = pcall(WR_PaladinForever_SealActive)
        if okA and active == true and WR_SpellUsable("审判", true) then
            local okC, judgeCD = pcall(WR_PaladinForever_GetJudgeCooldown)
            if okC and type(judgeCD) == "number"
               and WR_PaladinForever_ShowSkillCD("审判", 2, judgeCD) then
                return true
            end
        end
    end

    -- 11. 驱邪术（亡灵/恶魔）
    if RT.ExorcismStep() then return true end

    -- 12. 愤怒之锤（斩杀期）
    if RT.HammerStep() then return true end

    -- 13. 奉献（8 码内目标数达到拉条）
    if RT.ConsecrationStep() then return true end

    return false
end