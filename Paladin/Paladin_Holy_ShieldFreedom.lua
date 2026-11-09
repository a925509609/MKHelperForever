-- ============================================================
-- Paladin_Holy_ShieldFreedom.lua
-- 功能：神圣骑圣洁护盾和自由之手的补充逻辑
--       包含圣洁护盾刷新、自由之手驱散定身等
-- ============================================================

if WR_PlayerClass ~= "PALADIN" then return end

SS_SGDB_SJHD_Units = SS_SGDB_SJHD_Units or {}

-- ============================================================
-- ★ 圣洁护盾（单位）
-- ============================================================
function WR_PaladinHoly_Unit_SJHD(Unit)
    if not UnitIsDeadOrGhost(Unit) and IsSpellInRange("圣洁护盾", Unit) == 1 then
        if WR_FocusCast(Unit, 111, "圣洁护盾", "圣洁护盾") then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 刷新圣洁护盾
-- ============================================================
local function WR_PaladinHoly_Refresh_SJHD(Unit)
    if UnitExists(Unit) and WR_GetUnitBuffTime(Unit, "圣洁护盾", true) > 0 and
       WR_GetUnitBuffTime(Unit, "圣洁护盾", true) < 10 then
        if WR_PaladinHoly_Unit_SJHD(Unit) then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 圣洁护盾
-- ============================================================
function WR_PaladinHoly_SJHD()
    if not WR_SpellUsable("圣洁护盾", true) then return false end

    local setting = PigSet and PigSet.SS_SJHD
    if not setting or setting >= 7 then return false end

    -- 坦克选择模式
    if setting <= 4 then
        local Unit = SS_SGDB_SJHD_Units[setting]
        if Unit and WR_GetUnitBuffTime(Unit, "圣洁护盾", true) < 2 then
            if WR_PaladinHoly_Unit_SJHD(Unit) then
                return true
            end
        end
    -- 自己模式
    elseif setting == 5 then
        if WR_GetUnitBuffTime("player", "圣洁护盾", true) < 2 then
            if WR_PaladinHoly_Unit_SJHD("player") then
                return true
            end
        end
    -- 刷新模式
    elseif setting == 6 then
        if WR_PaladinHoly_Refresh_SJHD("player") then
            return true
        end

        local prefix = RaidOrParty or WR_GetInRaidOrParty()
        local groupSum = GroupSum or (prefix == "raid" and 25 or 4)

        for i = 1, groupSum do
            if WR_PaladinHoly_Refresh_SJHD(prefix .. i) then
                return true
            end
            if WR_PaladinHoly_Refresh_SJHD(prefix .. i .. "target") then
                return true
            end
        end
    end

    return false
end

-- ============================================================
-- ★ 自由之手（单位）
-- ============================================================
function WR_PaladinHoly_Unit_ZYZS(Unit)
    if not UnitExists(Unit) or UnitIsDeadOrGhost(Unit) then return false end
    if IsSpellInRange("自由之手", Unit) ~= 1 then return false end
    if not WR_Unbind(Unit) then return false end

    if UnitIsUnit("focus", Unit) then
        if WR_ColorFrame_ShowSkill("自由之手", 19) then
            return true
        end
    else
        if WR_FocusUnit(Unit, "自由") then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 自由之手
-- ============================================================
function WR_PaladinHoly_ZYZS()
    if not PigSet.SS_ZYZS or not UnitAffectingCombat("player") or
       not WR_SpellUsable("自由之手", true) then
        return false
    end

    if WR_PaladinHoly_Unit_ZYZS("player") then
        return true
    end

    local prefix = RaidOrParty or WR_GetInRaidOrParty()
    local groupSum = GroupSum or (prefix == "raid" and 25 or 4)

    for i = 1, groupSum do
        if WR_PaladinHoly_Unit_ZYZS(prefix .. i) then
            return true
        end
    end
    return false
end