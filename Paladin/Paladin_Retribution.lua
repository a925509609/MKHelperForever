-- ============================================================
-- Paladin_Retribution.lua  (★ SoD 探索赛季改编版)
-- 惩戒骑士自动循环 —— 符文自适应（P1-P4 一套代码，装备哪阶段符文解锁哪些技能）
-- 参考：Icy-Veins SoD 惩戒骑 P3 优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 槽位约定（AHK 据此映射按键）：
--   8=殉难圣印 9=十字军圣印 32=复仇之怒 33=审判 34=十字军打击
--   35=驱邪 4=(空置/预留) 36=奉献 1=愤怒之锤 37=光环掌握
--   38=清洁术 41=圣盾术 39=保护之手 40=自由之手
-- ============================================================

function WR_PaladinRetribution()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("圣光术")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    RaidOrParty = WR_GetInRaidOrParty()
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount5  = WR_GetRangeHarmUnitCount(5)
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)

    -- ===== 2. 最高优先级：生存/净化/光环/祝福/攻击 =====
    if WR_PaladinRetribution_SZ() then return true end      -- 圣盾术（低血肉盾）
    if WR_PaladinRetribution_QJ() then return true end      -- 清洁术（优先驱散）
    if WR_PaladinRetribution_SYTX() then return true end    -- 光环提醒（圣洁光环）
    if WR_PaladinRetribution_ZF() then return true end      -- 自动祝福（战斗外）
    if WR_PaladinRetribution_GongJi() then return true end  -- 自动攻击

    -- ===== 3. 战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    if not (inBossEncounter or ((UnitAffectingCombat("player") and TargetInCombat and (PigSet.FANG_ADD_CJQ == 1 or PigSet.FANG_ADD_CJQ == 2)))) then
        return false
    end

    -- ===== 4. 爆发（仇恨安全时）=====
    if WR_PaladinRetribution_FX() then return true end       -- 复仇之怒
    if WR_PaladinRetribution_GMZD() then return true end     -- 光环掌握（符文）

    -- ===== 5. 圣印保持 =====
    if WR_PaladinRetribution_SY() then return true end       -- 殉难圣印（常驻）

    -- ===== 6. 核心输出（符文自适应）=====
    if WR_PaladinRetribution_SZJS() then return true end     -- 十字军圣印+审判（长战斗上debuff，腿符文）
    if WR_PaladinRetribution_QX() then return true end      -- 驱邪（Exorcist 腿符文）
    if WR_PaladinRetribution_SZJB() then return true end     -- 十字军打击（Crusader Strike 手符文）
    if WR_PaladinRetribution_PD() then return true end       -- 审判（常驻）

    -- ===== 7. AoE / 填充 =====
    if WR_PaladinRetribution_FX2() then return true end      -- 奉献（蓝量允许 / 3+ 敌）

    -- ===== 8. 斩杀 =====
    if WR_PaladinRetribution_FZH() then return true end      -- 愤怒之锤（目标 <20%）

    -- ===== 9. 低蓝回蓝 =====
    if WR_PaladinRetribution_SZJB_MP() then return true end  -- 十字军打击（蓝低时回蓝）

    return false
end

-- ★ 圣盾术（低血肉盾，避免猝死）
function WR_PaladinRetribution_SZ()
    if PlayerHP < 25 and WR_SpellUsable("圣盾术", true) then
        if WR_ColorFrame_ShowSkill("圣盾术", 18) then return true end
    end
    return false
end

-- ★ 清洁术（优先驱散友方 debuff）
function WR_PaladinRetribution_QJ()
    if PigSet.CJ_QJ ~= 0 and WR_SpellUsable("清洁术", true) then
        -- 简化：自身有可驱散 debuff 时提示（精确目标选择由 AHK/玩家处理）
        if WR_GetUnitDebuffTime("player", "中毒") > 0 or WR_GetUnitDebuffTime("player", "疾病") > 0
           or WR_GetUnitDebuffTime("player", "魔法") > 0 or WR_GetUnitDebuffTime("player", "诅咒") > 0 then
            if WR_ColorFrame_ShowSkill("清洁术", 27) then return true end
        end
    end
    return false
end

-- ★ 光环提醒：未开圣洁光环则提示（DPS 常驻）
function WR_PaladinRetribution_SYTX()
    if WR_GetUnitBuffTime("player", "圣洁光环") == 0 and WR_SpellUsable("圣洁光环") then
        PigAlert("开启圣洁光环", 1, 0.8, 0, 1.2)
    end
    return false
end

-- ★ 自动祝福（战斗外补祝福，避免进战无祝福）
function WR_PaladinRetribution_ZF()
    if UnitAffectingCombat("player") then return false end
    if WR_GetUnitBuffTime("player", "力量祝福") == 0 and WR_GetUnitBuffTime("player", "智慧祝福") == 0
       and WR_SpellUsable("力量祝福") then
        if WR_ColorFrame_ShowSkill("力量祝福", 81) then return true end
    end
    return false
end

-- ★ 自动攻击（确保平砍 boss）
function WR_PaladinRetribution_GongJi()
    if not PlayerMove and UnitCanAttack("player", "target") and not UnitIsDead("target")
       and not IsCurrentSpell("攻击") and WR_SpellUsable("攻击") then
        if WR_ColorFrame_ShowSkill("攻击", 15) then return true end
    end
    return false
end

-- ★ 复仇之怒（仇恨安全即开；可用且战斗中）
function WR_PaladinRetribution_FX()
    if UnitAffectingCombat("player") and WR_SpellUsable("复仇之怒", true) then
        if WR_ColorFrame_ShowSkill("复仇之怒", 28) then return true end
    end
    return false
end

-- ★ 光环掌握（符文；可用且战斗中）
function WR_PaladinRetribution_GMZD()
    if WR_SoD_HasRune("PALADIN", "AuraMastery") and UnitAffectingCombat("player")
       and WR_SpellUsable("光环掌握", true) then
        if WR_ColorFrame_ShowSkill("光环掌握", 55) then return true end
    end
    return false
end

-- ★ 殉难圣印保持（SoD 常驻；未上则补）
function WR_PaladinRetribution_SY()
    if WR_GetUnitBuffTime("player", "殉难圣印") == 0 and WR_SpellUsable("殉难圣印") then
        if WR_ColorFrame_ShowSkill("殉难圣印", 29) then return true end
    end
    return false
end

-- ★ 十字军圣印 + 审判（长战斗上 debuff；需十字军圣印腿符文）
--   不再判断目标身上的审判 debuff
function WR_PaladinRetribution_SZJS()
    if WR_SoD_HasRune("PALADIN", "SealOfTheCrusader")
       and TargetDeathTime > 20
       and WR_GetUnitBuffTime("player", "十字军圣印") == 0
       and WR_SpellUsable("十字军圣印") then
        if WR_ColorFrame_ShowSkill("十字军圣印", 30) then return true end
    end
    -- 已上十字军圣印 → 打审判
    if WR_GetUnitBuffTime("player", "十字军圣印") > 0
       and WR_SpellUsable("审判", true) then
        if WR_ColorFrame_ShowSkill("审判", 33) then return true end
    end
    return false
end

-- ★ 驱邪（Exorcist 腿符文；常驻输出，<10% 时优先）
function WR_PaladinRetribution_QX()
    if WR_SoD_HasRune("PALADIN", "Exorcist") and WR_SpellUsable("驱邪", true) then
        local executePhase = (WR_SafeHPPct("target")) < 0.10
        if executePhase or true then
            if WR_ColorFrame_ShowSkill("驱邪", 20) then return true end
        end
    end
    return false
end

-- ★ 十字军打击（Crusader Strike 手符文；常驻输出）
function WR_PaladinRetribution_SZJB()
    if WR_SoD_HasRune("PALADIN", "CrusaderStrike") and WR_SpellUsable("十字军打击", true) then
        if WR_ColorFrame_ShowSkill("十字军打击", 3) then return true end
    end
    return false
end

-- ★ 2026-11-09：原「神圣风暴」分支已整体移除（本版本无此技能）。
--   槽 4 色块 / NUMPAD4 按键保留占位，后续可分配给其他技能。

-- ★ 审判（常驻；殉难圣印下打审判触发殉难效果；不再判断目标审判 debuff）
function WR_PaladinRetribution_PD()
    if WR_GetUnitBuffTime("player", "殉难圣印") > 0
       and WR_SpellUsable("审判", true) then
        if WR_ColorFrame_ShowSkill("审判", 33) then return true end
    end
    return false
end

-- ★ 奉献（蓝量允许时；或 3+ 敌 AoE；目标需在近战距离内）
function WR_PaladinRetribution_FX2()
    -- ★ 受面板「自动 奉献」开关控制
    if PigSet and PigSet.CJ_FX == false then return false end
    if TargetRange == nil or TargetRange > 5 then return false end
    local lowMana = PlayerMP < 0.30
    if UnitCount8 >= 3 and not lowMana and WR_SpellUsable("奉献", true) then
        if WR_ColorFrame_ShowSkill("奉献", 5) then return true end
    elseif UnitCount8 < 3 and not lowMana and PlayerMP > 0.50 and WR_SpellUsable("奉献", true) then
        if WR_ColorFrame_ShowSkill("奉献", 5) then return true end
    end
    return false
end

-- ★ 愤怒之锤（目标 <20% 斩杀）
function WR_PaladinRetribution_FZH()
    local hpPct = WR_SafeHPPct("target")
    if hpPct < 0.20 and WR_SpellUsable("愤怒之锤", true) then
        if WR_ColorFrame_ShowSkill("愤怒之锤", 1) then return true end
    end
    return false
end

-- ★ 十字军打击回蓝（蓝低时优先 CS 回蓝，避免断档）
function WR_PaladinRetribution_SZJB_MP()
    if PlayerMP < 0.20 and WR_SoD_HasRune("PALADIN", "CrusaderStrike") and WR_SpellUsable("十字军打击", true) then
        if WR_ColorFrame_ShowSkill("十字军打击(回蓝)", 34) then return true end
    end
    return false
end
