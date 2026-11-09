-- ============================================================
-- Shaman Forever · Restoration 专精循环
-- 共享 helper 见 Shaman_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_ShamanForeverRestoration()
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

    -- ===== 1. 大地之盾（Earth Shield 腿符文；坦克维持）=====
    if WR_GetUnitBuffTime("target", "大地之盾") == 0 and WR_SpellUsable("大地之盾", true) then
        if WR_ColorFrame_ShowSkill("大地之盾", 79) then return true end
    end

    -- ===== 2. 激流（Riptide；触发治疗链增效）=====
    if lowUnit and WR_GetUnitBuffTime(lowUnit, "激流") == 0 and lowHP < 0.92 and WR_SpellUsable("激流", true) then
        if WR_ColorFrame_ShowSkill("激流", 81) then return true end
    end

    -- ===== 3. 治疗链（Chain Heal；群疗）=====
    if lowCount >= 3 and WR_SpellUsable("治疗链", true) then
        if WR_ColorFrame_ShowSkill("治疗链", 52) then return true end
    end

    -- ===== 4. 治疗之雨（Healing Rain 胸符文；地面群疗）=====
    if lowCount >= 3 and WR_SpellUsable("治疗之雨", true) then
        if WR_ColorFrame_ShowSkill("治疗之雨", 9) then return true end
    end

    -- ===== 5. 治疗波 / 次级治疗波（单疗）=====
    if lowUnit and lowHP < 0.55 and WR_SpellUsable("治疗波", true) then
        if WR_ColorFrame_ShowSkill("治疗波", 82) then return true end
    elseif lowUnit and lowHP < 0.85 and WR_SpellUsable("次级治疗波", true) then
        if WR_ColorFrame_ShowSkill("次级治疗波", 76) then return true end
    end

    -- ===== 6. 净化术（驱散）=====
    if WR_GetUnitDebuffTime("player", "中毒") > 0 or WR_GetUnitDebuffTime("player", "疾病") > 0
       or WR_GetUnitDebuffTime("player", "魔法") > 0 or WR_GetUnitDebuffTime("player", "诅咒") > 0 then
        if WR_SpellUsable("净化术", true) then
            if WR_ColorFrame_ShowSkill("净化术", 23) then return true end
        end
    end


    -- ★ 无限天赋技能（原旋转未引用；已学会才提示，缺失自动跳过）
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("水之护盾") and WR_SpellUsable("水之护盾", true) then
        if WR_ColorFrame_ShowSkill("水之护盾", 302) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("法力之潮图腾") and WR_SpellUsable("法力之潮图腾", true) then
        if WR_ColorFrame_ShowSkill("法力之潮图腾", 303) then return true end
    end
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("自然迅捷") and WR_SpellUsable("自然迅捷", true) then
        if WR_ColorFrame_ShowSkill("自然迅捷", 304) then return true end
    end
    return false
end
