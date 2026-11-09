-- ============================================================
-- Paladin_Holy.lua  (★ SoD 探索赛季改编版)
-- 神圣骑士自动治疗循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 神圣骑优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 治疗目标选取：WR_SoD_GetLowestFriendly（团队最低血友方）
-- 槽位约定（AHK 据此映射按键）：
--   221=圣光道标 222=神圣震击 223=圣光闪现 224=圣光术
--   225=洁净术 227=圣疗术
-- ============================================================

function WR_PaladinHoly()
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
    if PlayerHP < 0.30 and WR_SpellUsable("圣疗术", true) then
        if WR_ColorFrame_ShowSkill("圣疗术", 40) then return true end
    end

    -- ===== 2. 圣光道标（Beacon of Light 手符文；坦克维持）=====
    if WR_SoD_HasRune("PALADIN", "BeaconOfLight")
       and WR_GetUnitBuffTime("target", "圣光道标") == 0
       and WR_SpellUsable("圣光道标", true) then
        if WR_ColorFrame_ShowSkill("圣光道标", 112) then return true end
    end

    -- ===== 3. 神圣震击（核心单疗，神圣骑招牌）=====
    if lowUnit and lowHP < 0.92 and WR_SpellUsable("神圣震击", true) then
        if WR_ColorFrame_ShowSkill("神圣震击", 113) then return true end
    end

    -- ===== 4. 圣光闪现 / 圣光术（按危急程度）=====
    if lowUnit and lowHP < 0.55 and WR_SpellUsable("圣光术", true) then
        if WR_ColorFrame_ShowSkill("圣光术", 110) then return true end
    elseif lowUnit and lowHP < 0.85 and WR_SpellUsable("圣光闪现", true) then
        if WR_ColorFrame_ShowSkill("圣光闪现", 10) then return true end
    end

    -- ===== 5. 洁净术（驱散友方 debuff）=====
    if WR_GetUnitDebuffTime("player", "中毒") > 0 or WR_GetUnitDebuffTime("player", "疾病") > 0
       or WR_GetUnitDebuffTime("player", "魔法") > 0 or WR_GetUnitDebuffTime("player", "诅咒") > 0 then
        if WR_SpellUsable("洁净术", true) then
            if WR_ColorFrame_ShowSkill("洁净术", 14) then return true end
        end
    end

    return false
end
