-- ============================================================
-- Priest_Discipline.lua  (★ SoD 探索赛季改编版)
-- 戒律牧师自动治疗循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 戒律牧优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 治疗目标选取：WR_SoD_GetLowestFriendly（团队最低血友方）
-- 槽位约定（AHK 据此映射按键）：
--   189=真言术：盾 190=苦修 182=快速治疗 184=治疗祷言 185=愈合祷言
--   191=痛苦压制 188=绝望祷言 192=驱散魔法
-- ============================================================

function WR_PriestDisCipline()
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    local lowUnit = WR_SoD_GetLowestFriendly(0.90)
    local lowHP = lowUnit and WR_GetUnitHP(lowUnit) or 1
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
    if lowHP < 0.30 and WR_SpellUsable("痛苦压制", true) then
        if WR_ColorFrame_ShowSkill("痛苦压制", 64) then return true end
    end

    -- ===== 2. 群体治疗 =====
    if lowCount >= 3 and WR_SpellUsable("治疗祷言", true) then
        if WR_ColorFrame_ShowSkill("治疗祷言", 53) then return true end
    end

    -- ===== 3. 真言术：盾（预防性，无盾则套）=====
    if lowUnit and WR_GetUnitBuffTime(lowUnit, "真言术：盾") == 0 and WR_SpellUsable("真言术：盾", true) then
        if WR_ColorFrame_ShowSkill("真言术：盾", 59) then return true end
    end

    -- ===== 4. 苦修（Penance 手符文；主力单疗）=====
    if WR_SoD_HasRune("PRIEST", "Penance") and lowUnit and lowHP < 0.90 and WR_SpellUsable("苦修", true) then
        if WR_ColorFrame_ShowSkill("苦修", 54) then return true end
    end

    -- ===== 5. 愈合祷言（rune）=====
    if WR_SoD_HasRune("PRIEST", "PrayerOfMending") and lowUnit and lowHP < 0.92 and WR_SpellUsable("愈合祷言", true) then
        if WR_ColorFrame_ShowSkill("愈合祷言", 58) then return true end
    end

    -- ===== 6. 快速治疗（填充）=====
    if lowUnit and lowHP < 0.85 and WR_SpellUsable("快速治疗", true) then
        if WR_ColorFrame_ShowSkill("快速治疗", 57) then return true end
    end

    -- ===== 7. 自保 =====
    if PlayerHP < 0.40 and WR_SpellUsable("绝望祷言", true) then
        if WR_ColorFrame_ShowSkill("绝望祷言", 150) then return true end
    end

    return false
end
