-- ============================================================
-- Warlock_FocusCorruption_Snapshot.lua
-- 功能：为焦点目标记录腐蚀术施放时的快照伤害期望值
--       类似目标腐蚀术快照，但针对 focus 单位
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

lastBaifenbiplus2 = nil
nameplate2 = {}
lastSpellPower2 = {}

for i = 1, 40 do
    lastSpellPower2[i] = 0
end

NPBaifenbiplus2 = {}
for i = 1, 40 do
    nameplate2[i] = "nameplate" .. i
    NPBaifenbiplus2[i] = 0
end

-- 计算焦点目标的腐蚀术期望伤害（含暴击、增益、低血增伤）
function quanzhong2()
    if not UnitAffectingCombat("player") then
        for i = 1, 40 do
            NPBaifenbiplus2[i] = 0
        end
    end

    local currentBaifenbiplus
    local baoji = GetSpellCritChance(6)  -- 毁灭系暴击率

    -- 检查焦点目标身上影响暴击的 debuff
    for i = 1, 60 do
        local _, _, _, _, _, _, _, _, _, spellId = UnitDebuff("focus", i)
        if not spellId then
            break
        end
        if spellId == 22959 or spellId == 17800 then
            baoji = baoji + 5
        end
        if spellId == 54499 then
            baoji = baoji + 3
        end
    end

    -- 获取基础法术强度修正
    local _, _, _, _, _, _, varmodapplied = UnitDamage("player")
    local mod = varmodapplied

    -- 焦点目标低血量增伤（<35%）
    local maxHP = WR_SafeNumber(UnitHealthMax("focus"), 1)
    local curHP = WR_SafeNumber(UnitHealth("focus"), WR_SafeNumber(UnitHealthMax("focus"), 1))
    local perHP = 0
    if maxHP and maxHP > 0 then
        perHP = curHP * 100 / maxHP
    end
    if perHP <= 35 then
        mod = mod + 0.12
    end

    -- 期望伤害 = 非暴击部分 + 暴击部分（暴击伤害 200%）
    currentBaifenbiplus = (100 * mod) * (100 - baoji) / 100 + (100 * mod * 2) * (baoji / 100)
    return currentBaifenbiplus
end

-- 战斗日志监听：施放腐蚀术时记录快照，暗影系伤害时更新法术强度
local TempFrame = CreateFrame("Frame")
TempFrame:SetScript("OnEvent", function()
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags,
          sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
          spellId, spellName = unpack(WR_CombatLogEvent)

    if subevent == "SPELL_MISSED" then
        return false
    end

    -- 玩家成功施放腐蚀术
    if subevent == "SPELL_CAST_SUCCESS" and spellName == "腐蚀术" and sourceName == UnitName("player") then
        for i = 1, 40 do
            if UnitGUID(nameplate2[i]) == destGUID then
                NPBaifenbiplus2[i] = quanzhong2()
                lastSpellPower2[i] = GetSpellBonusDamage(6)
            end
        end
    end

    -- 暗影系伤害技能命中时，更新法术强度
    if subevent == "SPELL_DAMAGE" and
       (spellName == "暗影箭" or spellName == "鬼影缠身" or spellName == "吸取生命" or spellName == "吸取灵魂") and
       sourceName == UnitName("player") then
        for i = 1, 40 do
            if UnitGUID(nameplate2[i]) == destGUID then
                lastSpellPower2[i] = GetSpellBonusDamage(6)
                break
            end
        end
    end
end)
WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")