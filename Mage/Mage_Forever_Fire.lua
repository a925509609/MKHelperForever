-- ============================================================
-- Mage Forever · Fire 专精循环
-- 共享 helper 见 Mage_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_MageForeverFire()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("火球术")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    hotStreak = WR_GetUnitBuffTime("player", "法术连击") > 0   -- 法术连击(炎爆术瞬发)触发

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_HUOFA == 2)   -- 菜单 1=防ADD开 2=关；关时允许 ADD/起手
    if not (inBossEncounter or (UnitAffectingCombat("player") and (allowAdd or TargetInCombat))) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 35)

    -- ===== 3. AoE 分支（3+ 敌近身）=====
    if UnitCount8 >= 3 and inRange and WR_SpellUsable("魔爆术", true) then
        if WR_ColorFrame_ShowSkill("魔爆术", 75) then return true end
    end

    -- ===== 4. 单体核心（仅当在射程）=====
    if inRange then
        -- 4.1 活动炸弹保持（Living Bomb 手符文；目标无则补）
        if WR_GetUnitDebuffTime("target", "活动炸弹") == 0
           and WR_SpellUsable("活动炸弹", true) then
            if WR_ColorFrame_ShowSkill("活动炸弹", 3) then return true end
        end

        -- 4.2 燃烧（Burnout 胸符文；强力爆发，CD 即放）
        if WR_SpellUsable("燃烧", true) then
            if WR_ColorFrame_ShowSkill("燃烧", 58) then return true end
        end

        -- 4.3 炎爆术（法术连击触发瞬发时优先）
        if hotStreak and WR_SpellUsable("炎爆术", true) then
            if WR_ColorFrame_ShowSkill("炎爆术", 2) then return true end
        end

        -- 4.4 火球术（常驻填充）
        if WR_SpellUsable("火球术", true) then
            if WR_ColorFrame_ShowSkill("火球术", 5) then return true end
        end

        -- 4.5 灼烧（移动中无读条时用，保法术连击叠层）
        if PlayerMove and WR_SpellUsable("灼烧", true) then
            if WR_ColorFrame_ShowSkill("灼烧", 7) then return true end
        end
    end

    -- ===== 5. 法力管理 =====
    if PlayerMP < 0.25 and WR_SpellUsable("唤醒") then
        if WR_ColorFrame_ShowSkill("唤醒", 18) then return true end
    end
    if PlayerMP < 0.15 and WR_SpellUsable("法力宝石") then
        if WR_ColorFrame_ShowSkill("法力宝石", 77) then return true end
    end


    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("冲击波") and WR_SpellUsable("冲击波", true) then
        if WR_ColorFrame_ShowSkill("冲击波", 303) then return true end
    end
    return false
end
