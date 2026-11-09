-- ============================================================
-- Warlock_CorruptionSnapshot_All.lua
-- 功能：为任意目标（通过 nameplate 索引）记录腐蚀术施放时的快照，
--       支持目标、焦点及其他nameplate单位
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

lastBaifenbiplus3 = nil
nameplate3 = {}
lastSpellPower3 = {}

for i = 1, 40 do
    lastSpellPower3[i] = 0
end

NPBaifenbiplus3 = {}
for i = 1, 40 do
    nameplate3[i] = "nameplate" .. i
end

-- 计算指定目标的腐蚀术期望伤害（含暴击、增伤、低血加成）
function quanzhong123(Unit)
    local currentBaifenbiplus
    local baoji = GetSpellCritChance(6)

    -- 检查目标身上的暴击加成debuff
    for i = 1, 60 do
        local _, _, _, _, _, _, _, _, _, spellId = UnitDebuff(Unit, i)
        if not spellId then break end
        if spellId == 22959 or spellId == 17800 then
            baoji = baoji + 5
        end
        if spellId == 54499 then
            baoji = baoji + 3
        end
    end

    -- 获取伤害修正系数
    local _, _, _, _, _, _, varmodapplied = UnitDamage("player")
    local mod = varmodapplied

    -- 目标<35%血量增伤
    local maxHP = WR_SafeNumber(UnitHealthMax(Unit), 1)
    local curHP = WR_SafeNumber(UnitHealth(Unit), WR_SafeNumber(UnitHealthMax(Unit), 1))
    local perHP = 0
    if maxHP and maxHP > 0 then
        perHP = curHP * 100 / maxHP
    end
    if perHP <= 35 then
        mod = mod + 0.12
    end

    -- 期望伤害 = 非暴击 + 暴击（200%）
    currentBaifenbiplus = (100 * mod) * (100 - baoji) / 100 + (100 * mod * 2) * (baoji / 100)
    return currentBaifenbiplus
end

-- 战斗日志监听
local TempFrame = CreateFrame("Frame")
TempFrame:SetScript("OnEvent", function()
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags,
          sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
          spellId, spellName = unpack(WR_CombatLogEvent)

    if subevent == "SPELL_MISSED" then
        return false
    end

    -- 玩家施放腐蚀术成功：记录快照到目标或焦点
    if subevent == "SPELL_CAST_SUCCESS" and spellName == "腐蚀术" and sourceName == UnitName("player") then
        if UnitGUID("target") == destGUID then
            NPBaifenbiplus3[destGUID] = {
                QZ = quanzhong123("target"),
                FS = GetSpellBonusDamage(6)
            }
        end
        if UnitGUID("focus") == destGUID then
            NPBaifenbiplus3[destGUID] = {
                QZ = quanzhong123("focus"),
                FS = GetSpellBonusDamage(6)
            }
        end
    end

    -- 暗影系伤害：更新对应目标的法术强度
    if subevent == "SPELL_DAMAGE" and
       (spellName == "暗影箭" or spellName == "鬼影缠身" or spellName == "吸取生命" or spellName == "吸取灵魂") and
       sourceName == UnitName("player") then
        for i = 1, 40 do
            if UnitGUID(nameplate3[i]) == destGUID then
                lastSpellPower3[i] = GetSpellBonusDamage(6)
                break
            end
        end
    end
end)
WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")