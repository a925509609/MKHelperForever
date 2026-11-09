-- ============================================================
-- Priest_Holy.lua  (★ SoD 探索赛季改编版)
-- 神圣牧师自动治疗循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 神圣牧优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 治疗目标选取：WR_SoD_GetLowestFriendly（团队最低血友方）
-- 槽位约定（AHK 据此映射按键）：
--   181=治疗之环 182=快速治疗 183=强效治疗术 184=治疗祷言 185=愈合祷言
--   186=恢复 187=守护之魂 188=绝望祷言 192=驱散魔法
-- ============================================================

function WR_PriestHoly()
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    -- 团队最低血友方（低于 90% 即纳入）
    local lowUnit = WR_SoD_GetLowestFriendly(0.90)
    local lowHP = lowUnit and WR_GetUnitHP(lowUnit) or 1
    -- 3+ 名队友低于 70% → AoE 治疗
    local lowCount = 0
    local units = { "player" }
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    if raid > 0 then for i = 1, raid do units[#units + 1] = "raid" .. i end
    elseif party > 0 then for i = 1, party do units[#units + 1] = "party" .. i end end
    for _, u in ipairs(units) do
        if UnitExists(u) and not UnitIsDead(u) and WR_GetUnitHP(u) < 0.70 then lowCount = lowCount + 1 end
    end

    -- ===== 1. 紧急救场 =====
    if lowHP < 0.30 and WR_SpellUsable("守护之魂", true) then
        if WR_ColorFrame_ShowSkill("守护之魂", 187) then return true end
    end

    -- ===== 2. 群体治疗 =====
    if lowCount >= 3 and WR_SpellUsable("治疗祷言", true) then
        if WR_ColorFrame_ShowSkill("治疗祷言", 53) then return true end
    end

    -- ===== 3. 治疗之环（Circle of Healing 手符文；小队群疗）=====
    if WR_SoD_HasRune("PRIEST", "CircleOfHealing") and lowUnit and lowHP < 0.90 and WR_SpellUsable("治疗之环", true) then
        if WR_ColorFrame_ShowSkill("治疗之环", 76) then return true end
    end

    -- ===== 4. 愈合祷言（Prayer of Mending 腿符文）=====
    if WR_SoD_HasRune("PRIEST", "PrayerOfMending") and lowUnit and lowHP < 0.92 and WR_SpellUsable("愈合祷言", true) then
        if WR_ColorFrame_ShowSkill("愈合祷言", 58) then return true end
    end

    -- ===== 5. 单疗（按危急程度）=====
    if lowUnit and lowHP < 0.55 and WR_SpellUsable("强效治疗术", true) then
        if WR_ColorFrame_ShowSkill("强效治疗术", 77) then return true end
    end
    if lowUnit and lowHP < 0.85 and WR_SpellUsable("快速治疗", true) then
        if WR_ColorFrame_ShowSkill("快速治疗", 57) then return true end
    end
    if lowUnit and lowHP < 0.95 and PlayerMP > 0.20 and WR_SpellUsable("恢复", true) then
        if WR_ColorFrame_ShowSkill("恢复", 55) then return true end
    end

    -- ===== 6. 自保 =====
    if PlayerHP < 0.40 and WR_SpellUsable("绝望祷言", true) then
        if WR_ColorFrame_ShowSkill("绝望祷言", 150) then return true end
    end

    return false
end
