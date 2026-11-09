-- ============================================================
-- Druid Forever · Restoration 专精循环
-- 共享 helper 见 Druid_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_DruidForeverRestoration()
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

    -- ===== 1. 团队 HOT =====
    if lowCount >= 3 and WR_SpellUsable("野性成长", true) then
        if WR_ColorFrame_ShowSkill("野性成长", 107) then return true end
    end

    -- ===== 2. 生命绽放（Lifebloom 腿符文；坦克维持）=====
    if WR_GetUnitBuffTime("target", "生命绽放") == 0 and WR_SpellUsable("生命绽放", true) then
        if WR_ColorFrame_ShowSkill("生命绽放", 108) then return true end
    end

    -- ===== 3. 回春术（保持 HOT）=====
    if lowUnit and WR_GetUnitBuffTime(lowUnit, "回春术") == 0 and WR_SpellUsable("回春术", true) then
        if WR_ColorFrame_ShowSkill("回春术", 109) then return true end
    end

    -- ===== 4. 愈合 / 治疗之触（按危急程度）=====
    if lowUnit and lowHP < 0.55 and WR_SpellUsable("治疗之触", true) then
        if WR_ColorFrame_ShowSkill("治疗之触", 83) then return true end
    elseif lowUnit and lowHP < 0.85 and WR_SpellUsable("愈合", true) then
        if WR_ColorFrame_ShowSkill("愈合", 80) then return true end
    end

    -- ===== 5. 宁静（大招，群危）=====
    if lowCount >= 4 and WR_SpellUsable("宁静", true) then
        if WR_ColorFrame_ShowSkill("宁静", 64) then return true end
    end

    -- ===== 6. 解除诅咒 =====
    if WR_GetUnitDebuffTime("player", "诅咒") > 0 and WR_SpellUsable("解除诅咒", true) then
        if WR_ColorFrame_ShowSkill("解除诅咒", 74) then return true end
    end


    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("迅捷治愈") and WR_SpellUsable("迅捷治愈", true) then
        if WR_ColorFrame_ShowSkill("迅捷治愈", 307) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("自然迅捷") and WR_SpellUsable("自然迅捷", true) then
        if WR_ColorFrame_ShowSkill("自然迅捷", 308) then return true end
    end
    return false
end
