-- ============================================================
-- Warlock_Corruption_Refresh.lua
-- 功能：记录当前目标腐蚀术施放时的快照（法术强度+暴击+增伤），
--       通过 WW_SS_SHUAXIN() 判断当前快照是否优于原快照5%以上，
--       用于痛苦术的腐蚀术刷新逻辑
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

local IsSpellInRange = IsSpellInRange
local UnitExists = UnitExists
local UnitCanAttack = UnitCanAttack
local UnitAffectingCombat = UnitAffectingCombat

-- 距离检测（用于范围提示）
local isOutOfRange = false
local checkTimer = 0
local PigRangeCheckFrame = CreateFrame("Frame")
PigRangeCheckFrame:SetScript("OnUpdate", function(self, elapsed)
    checkTimer = checkTimer + elapsed
    if checkTimer < 0.2 then return end
    checkTimer = 0

    local isPigSetEnabled = (PigSet and PigSet.SS_HM_HDLX)
    if UnitExists("target") and UnitCanAttack("player", "target") and UnitAffectingCombat("player") and isPigSetEnabled then
        local inRange = IsSpellInRange("暗影灼烧", "target")
        if inRange == 0 then
            if not isOutOfRange then
                PigAlert("暗影灼烧 打不到", 1, 0, 0, 2)
                isOutOfRange = true
            end
        elseif inRange == 1 then
            if isOutOfRange then
                PigAlert("暗影灼烧 范围内", 0, 1, 0, 2)
                isOutOfRange = false
            end
        end
    else
        if isOutOfRange then
            isOutOfRange = false
        end
    end
end)

-- 全局快照存储表（按目标GUID索引）
if not WARLOCK_FFSQDXT then
    WARLOCK_FFSQDXT = {}
end

-- 获取当前快照评分（法术强度 + 暴击率 + 低血量增伤）
-- ★ 全局暴露：供 Warlock_Affliction.lua 的 WR_CalcCorruptionWeight() 复用
function WR_GetCurrentSnapshotStats()
    local currentSP = GetSpellBonusDamage(6)
    local crit = GetSpellCritChance(6)

    -- 检查目标身上的暴击加成debuff
    for i = 1, 40 do
        local _, _, _, _, _, _, sourceUnit, _, _, spellId = UnitDebuff("target", i)
        if not spellId then break end
        if spellId == 22959 or spellId == 17800 or spellId == 12579 then
            crit = crit + 5
        elseif spellId == 54499 or spellId == 57722 or spellId == 58413 then
            crit = crit + 3
        end
    end

    -- 获取伤害修正系数
    local _, _, _, _, _, _, damageMultiplier = UnitDamage("player")
    local mod = damageMultiplier or 1

    -- 目标<35%血量增伤
    local maxHP = WR_SafeNumber(UnitHealthMax("target"), 1)
    local curHP = WR_SafeNumber(UnitHealth("target"), WR_SafeNumber(UnitHealthMax("target"), 1))
    if maxHP and maxHP > 0 then
        if (curHP / maxHP) <= 0.35 then
            mod = mod + 0.12
        end
    end

    -- 评分 = 基础伤害 * (1 + 暴击率)
    local score = (100 * mod) * (1 + crit / 100)
    return score, currentSP
end

-- 战斗日志监听
local TempFrame = CreateFrame("Frame")
WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")
TempFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
TempFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

TempFrame:SetScript("OnEvent", function(self, event, ...)
    -- 脱离战斗时清空快照记录
    if event == "PLAYER_REGEN_ENABLED" then
        WARLOCK_FFSQDXT = {}
        return
    end

    local timestamp, subevent, _, sourceGUID, sourceName, _, _,
          destGUID, destName, _, _, spellId, spellName = unpack(WR_CombatLogEvent)

    if sourceGUID ~= UnitGUID("player") then
        return
    end

    -- 腐蚀术施放成功或刷新：记录快照
    if (subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH") and spellName == "腐蚀术" then
        if destGUID == UnitGUID("target") then
            local score, sp = WR_GetCurrentSnapshotStats()
            WARLOCK_FFSQDXT[destGUID] = {
                score = score,
                sp = sp
            }
            -- 同步到 Affliction 侧快照表，使 WR_NeedsCorruptionRefresh 基于真实权重比较
            if WR_CalcCorruptionWeight and WR_RecordCorruptionSnapshot then
                WR_RecordCorruptionSnapshot(destGUID, WR_CalcCorruptionWeight())
            end
        end
    end

    -- 暗影系伤害：更新法术强度
    if subevent == "SPELL_DAMAGE" and
       (spellName == "暗影箭" or spellName == "鬼影缠身" or spellName == "吸取生命" or spellName == "吸取灵魂") then
        if WARLOCK_FFSQDXT[destGUID] then
            WARLOCK_FFSQDXT[destGUID].sp = GetSpellBonusDamage(6)
        end
    end

    -- 腐蚀术移除：清空记录
    if subevent == "SPELL_AURA_REMOVED" and spellName == "腐蚀术" then
        WARLOCK_FFSQDXT[destGUID] = nil
    end
end)

-- 判断当前目标腐蚀术是否需要刷新（快照提升 > 4%）
function WW_SS_SHUAXIN()
    local targetGUID = UnitGUID("target")
    if not targetGUID then
        return false
    end

    local record = WARLOCK_FFSQDXT[targetGUID]
    if not record then
        return false
    end

    local currentScore, currentSP = GetCurrentSnapshotStats()
    local lastScore = record.score
    local lastSP = record.sp

    -- 如果当前法术强度低于记录时的法术强度，不刷新（防止低法强覆盖高法强）
    if currentSP < lastSP then
        return false
    end

    -- 当前评分 > 原评分 * 1.04（即提升超过4%）
    if currentScore > (lastScore * 1.04) then
        return true
    end

    return false
end