-- ============================================================
-- Warlock_TargetCorruption_Snapshot.lua
-- 功能：为每个敌方单位记录腐蚀术施放时的快照伤害期望值
--       并随目标血量（<35% 增伤）和自身暴击变化动态计算
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

lastBaifenbiplus = nil
nameplate = {}
lastSpellPower = {}

for i = 1, 40, 1 do
    lastSpellPower[i] = 0
end

NPBaifenbiplus = {}
for i = 1, 40, 1 do
    nameplate[i] = "nameplate" .. i
    NPBaifenbiplus[i] = 0
end

-- 计算当前腐蚀术期望伤害（含暴击、增益、目标低血增伤）
function quanzhong()
    if not (UnitAffectingCombat("player")) then
        for i = 1, 40, 1 do
            NPBaifenbiplus[i] = 0
        end
    end

    local currentBaifenbiplus
    local baoji = GetSpellCritChance(6)  -- 毁灭系暴击率

    -- 检查目标身上影响暴击的 debuff（暗影之拥、强化暗影箭等）
    for i = 1, 60 do
        local _, _, _, _, _, _, _, _, _, spellId = UnitDebuff("target", i)
        if not spellId then
            break
        end
        if spellId == 22959 or spellId == 17800 then  -- 暗影之拥 / 强化暗影箭
            baoji = baoji + 5
        end
        if spellId == 54499 then  -- 暗影易伤（例如）
            baoji = baoji + 3
        end
    end

    -- 获取基础法术强度修正（含天赋、装备等）
    local _, _, _, _, _, _, varmodapplied = UnitDamage("player")
    local mod = varmodapplied

    -- 目标低血量增伤（<35%）
    local maxHP = WR_SafeNumber(UnitHealthMax("target"), 1)
    local curHP = WR_SafeNumber(UnitHealth("target"), WR_SafeNumber(UnitHealthMax("target"), 1))
    local perHP = 0
    if maxHP and maxHP > 0 then
        perHP = curHP * 100 / maxHP
    end
    if perHP <= 35 then
        mod = mod + 0.12  -- 毁灭系“毁灭”天赋加成
    end

    -- 期望伤害 = 非暴击部分 + 暴击部分（暴击伤害为 200%）
    currentBaifenbiplus = (100 * mod) * (100 - baoji) / 100 + (100 * mod * 2) * (baoji / 100)
    return currentBaifenbiplus
end

-- 战斗日志监听：施放腐蚀术时记录快照，暗影系伤害时更新法术强度
local TempFrame = CreateFrame("Frame")
TempFrame:SetScript("OnEvent", function()
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags,
          sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
          spellId, spellName, spellSchool, auraType = unpack(WR_CombatLogEvent)

    if subevent == "SPELL_MISSED" then
        return
    end

    -- 玩家成功施放腐蚀术
    if subevent == "SPELL_CAST_SUCCESS" and spellName == "腐蚀术" and sourceName == UnitName("player") then
        for i = 1, 40, 1 do
            if UnitGUID(nameplate[i]) == destGUID then
                NPBaifenbiplus[i] = quanzhong()
                lastSpellPower[i] = GetSpellBonusDamage(6)
            end
        end
    end

    -- 暗影系伤害技能（暗影箭、鬼影缠身、吸取生命、吸取灵魂）命中时，更新法术强度
    if subevent == "SPELL_DAMAGE" and
       (spellName == "暗影箭" or spellName == "鬼影缠身" or spellName == "吸取生命" or spellName == "吸取灵魂") and
       sourceName == UnitName("player") then
        for i = 1, 40 do
            if UnitGUID(nameplate[i]) == destGUID then
                lastSpellPower[i] = GetSpellBonusDamage(6)
                break
            end
        end
    end
end)
WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")