-- ============================================================
-- Shaman_Restoration.lua  (★ SoD 探索赛季改编版)
-- 恢复萨满自动治疗循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 恢复萨优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 治疗目标选取：WR_SoD_GetLowestFriendly（团队最低血友方）
-- 槽位约定（AHK 据此映射按键）：
--   248=大地之盾 249=激流 250=治疗链 251=治疗之雨 252=治疗波
--   253=次级治疗波 254=净化术
-- ============================================================

function WR_ShamanRestoration()
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
    if WR_SoD_HasRune("SHAMAN", "EarthShield")
       and WR_GetUnitBuffTime("target", "大地之盾") == 0 and WR_SpellUsable("大地之盾", true) then
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
    if WR_SoD_HasRune("SHAMAN", "HealingRain") and lowCount >= 3 and WR_SpellUsable("治疗之雨", true) then
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

    return false
end
