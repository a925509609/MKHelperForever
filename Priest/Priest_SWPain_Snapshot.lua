-- ============================================================
-- Priest_SWPain_Snapshot.lua
-- 功能：记录每个目标施放暗言术：痛时的快照伤害期望值
--       包含暴击、暗影交织层数等动态修正
-- ============================================================

if WR_PlayerClass ~= "PRIEST" then return end

if UnitClassBase("player") ~= "PRIEST" then
    return
end

lastBaifenbiplus = nil
nameplate = {}
NPBaifenbiplus = {}

for i = 1, 40, 1 do
    nameplate[i] = "nameplate" .. i
    NPBaifenbiplus[i] = 0
end

-- ★ 计算当前痛的期望伤害
function quanzhong()
    if not (UnitAffectingCombat("player")) then
        for i = 1, 40, 1 do
            NPBaifenbiplus[i] = 0
        end
    end

    local currentBaifenbiplus
    local baoji = GetSpellCritChance(6)  -- 暗影系暴击率

    -- 检查目标身上的暴击加成debuff
    for i = 1, 60 do
        local _, _, _, _, _, _, _, _, _, spellId = UnitDebuff("target", i)
        if not spellId then break end
        if spellId == 22959 or spellId == 17800 then
            baoji = baoji + 5
        end
        if spellId == 54499 then
            baoji = baoji + 3
        end
    end

    -- 获取基础伤害系数
    local _, _, _, _, _, _, baifenbi = UnitDamage("player")

    -- 检查暗影交织层数（+2%每层）
    for i = 1, 60 do
        local _, _, count, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        if not spellId then break end
        if spellId == 15258 then
            baifenbi = baifenbi + (0.02 * count)
        end
    end

    -- 期望伤害 = 非暴击 + 暴击（200%）
    currentBaifenbiplus = (100 * baifenbi) * (100 - baoji) / 100 + (100 * baifenbi * 2) * (baoji / 100)
    return currentBaifenbiplus
end

-- ★ 战斗日志监听
local TempFrame = CreateFrame("Frame")
TempFrame:SetScript("OnEvent", function()
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags,
          sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
          spellId, spellName = unpack(WR_CombatLogEvent)

    if subevent == "SPELL_MISSED" then
        return false
    end

    if subevent == "SPELL_CAST_SUCCESS" and spellName == "暗言术：痛" and sourceName == UnitName("player") then
        for i = 1, 40, 1 do
            if UnitGUID(nameplate[i]) == destGUID then
                NPBaifenbiplus[i] = quanzhong()
            end
        end
    end
end)
WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")