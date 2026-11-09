-- ============================================================
-- Utils_HealerWeight.lua
-- 治疗权重系统（智能治疗目标选择）
-- 从 Core_Functions.lua 拆分
-- 包含：优先级Debuff配置、单位权重计算、队伍状态缓存、
--       最大权重单位获取、焦点最大权重、焦点施法框架
-- ============================================================

-- ============================================================
-- ★ 优先级Debuff配置
-- ============================================================
local PriorityHealthDebuff = {
    [66013] = "刺骨之寒", [69065] = "白骨贯体", [72385] = "沸腾之血",
    [72293] = "阵亡勇士的印记", [69240] = "邪恶毒气", [69290] = "枯萎的孢子",
    [69674] = "畸变感染", [69789] = "软泥洪流", [69778] = "粘稠的软泥",
    [71278] = "窒息毒气", [72451] = "畸变瘟疫", [70447] = "不稳定的软泥怪粘合剂",
    [71807] = "闪耀火花", [71265] = "蜂拥之影", [71623] = "疯狂斩杀",
    [71304] = "黑暗堕落者的契约", [70744] = "酸性爆炸", [70633] = "胆汁喷溅",
    [72963] = "血肉腐烂", [69766] = "动荡", [70126] = "冰霜道标",
    [70106] = "寒霜刺骨", [72546] = "收割灵魂", [69409] = "灵魂收割",
    [69242] = "灵魂尖啸", [68980] = "收割灵魂", [72754] = "污染",
}

local HighestPriorityDebuff = {
    [72149] = "血肉成灰", [72150] = "血肉成灰", [66237] = "血肉成灰",
}

local WR_MaxWeight = -0
local WR_MaxWeightUnit = "Nothing"

function WR_FocusHasPriorityDebuff()
    if WR_GetUnitDebuffTime("focus", HighestPriorityDebuff) > 0 then
        return true
    end
    return false
end

-- ============================================================
-- ★ 单位权重计算（用于智能治疗）
-- ============================================================
local UnitExists = UnitExists
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsCharmed = UnitIsCharmed
local UnitCanAttack = UnitCanAttack
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitGUID = UnitGUID
local UnitIsUnit = UnitIsUnit
local UnitClassBase = UnitClassBase
local GetTime = GetTime
local math_ceil = math.ceil

local playerClass = nil
local AnubSwarmHealMode = false

function WR_AnubSwarmPhaseActive()
    local bossName = WR_GetHealthMaxWeightUnit_CurrentBossName
    if not bossName and UnitExists("target") then
        bossName = WR_SafeUnitName and WR_SafeUnitName("target") or UnitName("target")
    end
    if bossName == "阿努巴拉克" and WR_GetUnitDebuffTime("player", "吸血虫群") > 0 then
        return true
    end
    return false
end

function WR_UnitHasAnubBoneSpike(Unit)
    if WR_GetUnitDebuffTime(Unit, 66013) > 0 then
        return true
    end
    return false
end

local function WR_GetUnitWeight(Unit, ID)
    if not playerClass then
        playerClass = UnitClassBase("player")
    end

    local TempUnit = Unit
    if ID then
        if Unit == "raid" and raidUnits then
            TempUnit = raidUnits[ID] or (Unit .. ID)
        elseif Unit == "party" and partyUnits then
            TempUnit = partyUnits[ID] or (Unit .. ID)
        else
            TempUnit = Unit .. ID
        end
    end

    if UnitExists(TempUnit) and not UnitIsDeadOrGhost(TempUnit) and
       not UnitIsCharmed(TempUnit) and not UnitCanAttack(TempUnit, "player") and
       WR_UnitRange(TempUnit) <= 40 then

        local maxHp = WR_SafeNumber(UnitHealthMax(TempUnit), 1)
        if maxHp <= 0 then return end

        local UnitHP = (WR_SafeNumber(UnitHealth(TempUnit), WR_SafeNumber(UnitHealthMax(TempUnit), 1)) + (WR_SafeNumber(UnitGetIncomingHeals(TempUnit), 0) or 0)) / maxHp
        local UnitWeight = UnitHP * 100
        if UnitWeight > 100 then UnitWeight = 100 end
        UnitWeight = 100 - UnitWeight

        local UnitIsTank = false
        if UnitGroupRolesAssigned(TempUnit) == "TANK" or WR_NumIsTank(ID) then
            UnitIsTank = true
        end

        local currentTime = GetTime()
        local tempGUID = (WR_SafeUnitGUID and WR_SafeUnitGUID(TempUnit)) or nil
        if OutOfSight_ErrorMessageTime ~= nil and OutOfSight_FocusID ~= nil and
           (currentTime - OutOfSight_ErrorMessageTime) < 0.2 and
           tempGUID ~= nil and OutOfSight_FocusID == tempGUID then
            UnitWeight = UnitWeight - 10000
        elseif AnubSwarmHealMode and not UnitIsTank and
               not WR_UnitHasAnubBoneSpike(TempUnit) then
            UnitWeight = UnitWeight - 10000
        else
            if playerClass ~= "PRIEST" then
                if UnitIsUnit(TempUnit, "player") and UnitHP < 0.50 then
                    UnitWeight = UnitWeight + (50 - UnitHP * 100) / 2
                end
            end

            if WR_GetUnitDebuffTime(TempUnit, PriorityHealthDebuff) > 0 then
                UnitWeight = UnitWeight + 1000
            end

            if WR_GetUnitDebuffTime(TempUnit, HighestPriorityDebuff) > 0 then
                UnitWeight = UnitWeight + 10000
            end

            if AnubSwarmHealMode then
                if UnitIsTank then
                    UnitWeight = UnitWeight + 1000
                end
                if WR_UnitHasAnubBoneSpike(TempUnit) then
                    if UnitHP >= 0.92 then
                        UnitWeight = UnitWeight - 10000
                    else
                        UnitWeight = UnitWeight + 1500 + (1 - UnitHP) * 300
                    end
                end
            end

            if WR_JaraxxusFleshAnyoneActive and WR_UnitNeedsFleshOverheal(TempUnit) then
                local absorb = WR_GetHealAbsorbs(TempUnit)
                if absorb > 0 then
                    UnitHP = (WR_SafeNumber(UnitHealth(TempUnit), WR_SafeNumber(UnitHealthMax(TempUnit), 1)) + (WR_SafeNumber(UnitGetIncomingHeals(TempUnit), 0) or 0) - absorb) /
                             WR_SafeNumber(UnitHealthMax(TempUnit), 1)
                    if UnitHP < 0 then UnitHP = 0 end
                    UnitWeight = 100 - UnitHP * 100
                else
                    UnitWeight = math.max(UnitWeight, 100)
                end
                UnitWeight = UnitWeight + 3000
            end

            -- 圣骑士特殊处理
            if playerClass == "PALADIN" then
                local BuffTime_SGDB = WR_GetUnitBuffTime(TempUnit, "圣光道标", true)
                if BuffTime_SGDB > 0 then
                    UnitWeight = UnitWeight - 10000
                else
                    local zlms = PigSet.SS_ZLMS
                    if UnitHP < 0.7 and UnitIsTank and Unit == "raid" then
                        UnitWeight = UnitWeight + 100
                    end

                    if zlms == 2 or zlms == 3 or zlms == 4 then
                        if UnitIsUnit(TempUnit, "target") then
                            UnitWeight = UnitWeight + 1000
                        end
                    elseif zlms == 5 then
                        if BuffTime_SGDB == 0 and UnitIsTank then
                            UnitWeight = UnitWeight + 1000
                        end
                    elseif zlms == 6 then
                        if BuffTime_SGDB == 0 and not UnitIsTank then
                            UnitWeight = UnitWeight + 1000
                        end
                    end

                    if Unit == "raid" then
                        local groupID = math_ceil(ID / 5)
                        if zlms == groupID + 6 then
                            UnitWeight = UnitWeight + 1000
                        end
                    end

                    if ZWYSDYJ_Unit then
                        if zlms == 12 and
                           ((ZWYSDYJ_Unit[1] and UnitIsUnit(TempUnit, ZWYSDYJ_Unit[1])) or
                            (ZWYSDYJ_Unit[2] and UnitIsUnit(TempUnit, ZWYSDYJ_Unit[2]))) then
                            UnitWeight = UnitWeight + 1000
                        elseif zlms == 13 and
                               ((ZWYSDYJ_Unit[3] and UnitIsUnit(TempUnit, ZWYSDYJ_Unit[3])) or
                                (ZWYSDYJ_Unit[4] and UnitIsUnit(TempUnit, ZWYSDYJ_Unit[4]))) then
                            UnitWeight = UnitWeight + 1000
                        elseif zlms == 14 and
                               ((ZWYSDYJ_Unit[1] and UnitIsUnit(TempUnit, ZWYSDYJ_Unit[1])) or
                                (ZWYSDYJ_Unit[3] and UnitIsUnit(TempUnit, ZWYSDYJ_Unit[3]))) then
                            UnitWeight = UnitWeight + 1000
                        elseif zlms == 15 and
                               ((ZWYSDYJ_Unit[2] and UnitIsUnit(TempUnit, ZWYSDYJ_Unit[2])) or
                                (ZWYSDYJ_Unit[4] and UnitIsUnit(TempUnit, ZWYSDYJ_Unit[4]))) then
                            UnitWeight = UnitWeight + 1000
                        end
                    end
                end

            -- 牧师特殊处理
            elseif playerClass == "PRIEST" then
                local zlms = PigSet.JL_ZLMS
                if zlms == 2 and UnitIsTank then
                    UnitWeight = UnitWeight + 1000
                elseif zlms == 3 and not UnitIsTank then
                    UnitWeight = UnitWeight + 1000
                elseif zlms == 4 and UnitIsUnit(TempUnit, "target") then
                    UnitWeight = UnitWeight + 1000
                end

                local WR_XXCQ = AnubSwarmHealMode
                local isAnub = AnubSwarmHealMode

                if not WR_XXCQ and UnitHP < 0.4 and UnitIsTank and WR_SpellUsable("苦修", true) then
                    UnitWeight = UnitWeight + 100
                end

                if WR_XXCQ and WR_GetUnitBuffTime(TempUnit, "真言术：盾", true) > 0 then
                    UnitWeight = UnitWeight - 15
                end

                if isAnub and WR_Priest_CiGuUnit then
                    for k = 1, 5 do
                        if (PigSet.JL_CGZH and PigSet.JL_CGZH[k]) or
                           (JL_CGZH_selectedItems and JL_CGZH_selectedItems[k]) and
                           WR_Priest_CiGuUnit[k] == TempUnit and
                           WR_GetUnitDebuffTime(TempUnit, 66013) > 0 then
                            if WR_XXCQ then
                                UnitWeight = UnitWeight + 1000
                            else
                                UnitWeight = UnitWeight + 100
                            end
                        end
                    end
                end

            -- 德鲁伊/萨满特殊处理
            elseif playerClass == "DRUID" or playerClass == "SHAMAN" then
                local zlms = PigSet.HF_ZLMS
                if zlms == 2 and UnitIsTank then
                    UnitWeight = UnitWeight + 1000
                elseif zlms == 3 and not UnitIsTank then
                    UnitWeight = UnitWeight + 1000
                elseif zlms == 4 and UnitIsUnit(TempUnit, "target") then
                    UnitWeight = UnitWeight + 1000
                end
            end
        end

        UnitWeight = math_ceil(UnitWeight)

        if WR_MaxWeight <= UnitWeight then
            WR_MaxWeight = UnitWeight
            WR_MaxWeightUnit = TempUnit
        end
    end
end

-- ============================================================
-- ★ 队伍状态缓存
-- ============================================================
WR_RosterState = {
    Members = {},
    Tanks = {},
    GroupSum = 0,
    RaidOrParty = "single",
    UpdateTime = 0,
}

function WR_UpdateRosterState()
    local currentTime = GetTime()
    if currentTime - WR_RosterState.UpdateTime < 0.1 then
        return
    end
    WR_RosterState.UpdateTime = currentTime

    RaidOrParty = WR_GetInRaidOrParty()
    GroupSum = RaidOrParty == "raid" and 25 or (RaidOrParty == "party" and 4 or 0)
    WR_RosterState.RaidOrParty = RaidOrParty
    WR_RosterState.GroupSum = GroupSum

    wipe(WR_RosterState.Tanks)
    local tankCount = 1

    WR_RosterState.Player = WR_RosterState.Player or {}
    local pMember = WR_RosterState.Player
    pMember.Unit = "player"
    pMember.GUID = UnitGUID("player")
    pMember.IsDead = UnitIsDeadOrGhost("player")

    if pMember.IsDead then
        pMember.HP = 0
        pMember.MaxHP = WR_SafeNumber(UnitHealthMax("player"), 1)
        pMember.LostHP = pMember.MaxHP
    else
        pMember.MaxHP = WR_SafeNumber(UnitHealthMax("player"), 1)
        local hp = WR_SafeNumber(UnitHealth("player"), WR_SafeNumber(UnitHealthMax("player"), 1)) + (WR_SafeNumber(UnitGetIncomingHeals("player"), 0) or 0)
        if pMember.MaxHP > 0 then
            pMember.HP = hp / pMember.MaxHP
        else
            pMember.HP = 0
        end
        pMember.LostHP = pMember.MaxHP - hp
    end

    pMember.Range = 0
    local pIsTank = false
    if UnitGroupRolesAssigned("player") == "TANK" then
        pIsTank = true
    end
    pMember.IsTank = pIsTank
    if pIsTank then
        WR_RosterState.Tanks[tankCount] = "player"
        tankCount = tankCount + 1
    end

    if GroupSum > 0 then
        for i = 1, GroupSum do
            local unit
            if RaidOrParty == "raid" then
                unit = raidUnits and raidUnits[i] or ("raid" .. i)
            else
                unit = partyUnits and partyUnits[i] or ("party" .. i)
            end

            if not WR_RosterState.Members[i] then
                WR_RosterState.Members[i] = {}
            end

            local member = WR_RosterState.Members[i]
            if UnitExists(unit) then
                member.Unit = unit
                member.GUID = UnitGUID(unit)
                member.IsDead = UnitIsDeadOrGhost(unit)

                if member.IsDead then
                    member.HP = 0
                    member.MaxHP = WR_SafeNumber(UnitHealthMax(unit), 1)
                    member.LostHP = member.MaxHP
                else
                    member.MaxHP = WR_SafeNumber(UnitHealthMax(unit), 1)
                    local hp = WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1)) + (WR_SafeNumber(UnitGetIncomingHeals(unit), 0) or 0)
                    if member.MaxHP > 0 then
                        member.HP = hp / member.MaxHP
                    else
                        member.HP = 0
                    end
                    member.LostHP = member.MaxHP - hp
                end

                member.Range = WR_UnitRange(unit)

                local isTank = false
                if UnitGroupRolesAssigned(unit) == "TANK" then
                    isTank = true
                else
                    if WR_NumIsTank(i) then
                        isTank = true
                    end
                end
                member.IsTank = isTank

                if isTank and not (RaidOrParty == "raid" and UnitIsUnit("player", unit)) then
                    WR_RosterState.Tanks[tankCount] = unit
                    tankCount = tankCount + 1
                end
            else
                member.Unit = nil
            end
        end
    end
end

-- ============================================================
-- ★ 最大权重单位获取
-- ============================================================
function WR_GetHealthMaxWeightUnit()
    if not IsEncounterInProgress() then
        WR_GetHealthMaxWeightUnit_CurrentBossName = nil
    end

    if not WR_GetHealthMaxWeightUnit_Event then
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("UI_ERROR_MESSAGE")
        frame:SetScript("OnEvent", function(self, event, messageType, message)
            if string.find(message, "目标不在视野中") then
                OutOfSight_ErrorMessageTime = GetTime()
                OutOfSight_FocusID = WR_SafeUnitGUID("focus")
            end
        end)

        local TempFrame = CreateFrame("Frame")
        WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")
        TempFrame:SetScript("OnEvent", function()
            local _, subevent, _, sourceGUID, _, _, _, destGUID, destName, _, _, _, spellName =
                unpack(WR_CombatLogEvent)
            if subevent == "SPELL_CAST_SUCCESS" then
                if destName == "阿努巴拉克" then
                    WR_GetHealthMaxWeightUnit_CurrentBossName = destName
                end
            end
        end)

        WR_GetHealthMaxWeightUnit_Event = true
    end

    WR_UpdateRosterState()
    AnubSwarmHealMode = WR_AnubSwarmPhaseActive()

    WR_MaxWeight = -0
    WR_MaxWeightUnit = "Nothing"

    WR_GetUnitWeight("target")
    WR_GetUnitWeight("player")

    local RaidOrParty = WR_RosterState.RaidOrParty
    if RaidOrParty == "party" then
        for i = 1, 4, 1 do
            WR_GetUnitWeight("party", i)
        end
    elseif RaidOrParty == "raid" then
        for i = 1, 25, 1 do
            WR_GetUnitWeight("raid", i)
        end
    end

    return WR_MaxWeightUnit
end

-- ============================================================
-- ★ 焦点最大权重单位（自动焦点）
-- ============================================================
local WR_PlayerClassCache = nil

function WR_FocusMaxWeightUnit()
    if not WR_PlayerClassCache then
        WR_PlayerClassCache = UnitClassBase("player")
    end

    if GCD > ShiFaSuDu then
        return false
    end

    if WR_PlayerClassCache == "PRIEST" and (WR_SafeCastingName and WR_SafeCastingName("player") ~= nil) then
        return false
    end

    if WR_PlayerClassCache == "PALADIN" and (WR_SafeCastingName and WR_SafeCastingName("player") ~= nil) and
       PigSet.SS_ZLMS ~= 4 then
        return false
    end

    if WR_FocusHealthMaxWeightUnit_LastTime ~= nil and
       GetTime() - WR_FocusHealthMaxWeightUnit_LastTime <= 0 and UnitExists("focus") then
        return false
    end

    local now = GetTime()
    if not WR_HealthMaxWeightUnit_LastCalcTime or
       (now - WR_HealthMaxWeightUnit_LastCalcTime) > 0.15 then
        WR_HealthMaxWeightUnit = WR_GetHealthMaxWeightUnit()
        WR_HealthMaxWeightUnit_LastCalcTime = now
    end

    if UnitIsUnit(WR_HealthMaxWeightUnit, "focus") then
        return false
    end

    if WR_HealthMaxWeightUnit == "player" then
        if WR_ColorFrame_Show(192, "焦点P") then return true end
    elseif WR_HealthMaxWeightUnit == "target" then
        if WR_ColorFrame_Show(147, "焦点T") then return true end
    else
        for i = 1, 4 do
            if WR_HealthMaxWeightUnit == "party" .. i then
                if WR_ColorFrame_Show(175 + i, "焦点P" .. i) then
                    return true
                end
                break
            end
        end
        for i = 1, 25 do
            if WR_HealthMaxWeightUnit == "raid" .. i then
                if WR_ColorFrame_Show(120 + i, "焦点R" .. i) then
                    return true
                end
                break
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 焦点施法框架
-- ============================================================
if not WR_FocusCast_Info then
    WR_FocusCast_Info = {}
end

function WR_FocusCast(Unit, Button, Spell, Text)
    if Unit and Button and Spell and Text then
        WR_FocusCast_Info.active = true
        WR_FocusCast_Info.unit = Unit
        WR_FocusCast_Info.button = Button
        WR_FocusCast_Info.spell = Spell
        WR_FocusCast_Info.text = Text
        WR_FocusCast_Info.time = GetTime()
    end

    if not WR_FocusCast_EventFrame then
        WR_FocusCast_EventFrame = CreateFrame("Frame")
        WR_RegisterEventSafe(WR_FocusCast_EventFrame, "COMBAT_LOG_EVENT_UNFILTERED")
        WR_FocusCast_EventFrame:SetScript("OnEvent", function()
            local _, subevent, _, sourceGUID, _, _, _, _, _, _, _, _, _, _, spellName =
                unpack(WR_CombatLogEvent)
            if WR_FocusCast_Info.active and
               (subevent == "SPELL_CAST_SUCCESS" or subevent == "SPELL_CAST_START") and
               sourceGUID == UnitGUID("player") and
               spellName == WR_FocusCast_Info.spell then
                WR_FocusCast_Info.active = false
            end
        end)
    end

    if WR_FocusCast_Info.active then
        if GetTime() - WR_FocusCast_Info.time <= (GCD and math.max(GCD, 0.1) or 0.1) then
            if UnitIsUnit(WR_FocusCast_Info.unit, "focus") then
                if WR_ColorFrame_Show(WR_FocusCast_Info.button,
                                      WR_FocusCast_Info.text .. "\n" ..
                                      WR_FocusCast_Info.unit) then
                    return true
                end
            else
                if WR_FocusUnit(WR_FocusCast_Info.unit, WR_FocusCast_Info.text) then
                    return true
                end
            end
        else
            WR_FocusCast_Info.active = false
        end
    end
    return false
end
