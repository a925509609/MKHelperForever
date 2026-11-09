-- ============================================================
-- Warlock_DrainSoul_Calc.lua
-- 功能：计算当前状态下吸取灵魂每一跳的期望伤害（用于快照对比）
--       公式参考：基础伤害 + 法术强度*系数，乘以各类增伤，再除以通道总时间
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

local spellCoefficient   = 0.429     -- 每跳系数
local coefficientTotal   = 2.145     -- 总共5跳（0.429 * 5）
local shadowMastery      = 1.15      -- 暗影掌握（天赋）
local deathsEmbrace      = 1.12      -- 死亡拥抱（天赋，目标<35%时）

function getCurrentValues()
    local spellPower = GetSpellBonusDamage(6)  -- 暗影系法术强度
    local _, _, _, _, _, _, varmodapplied = UnitDamage("player")
    local mod = varmodapplied                   -- 全局伤害修正（含增伤、易伤等）
    local _, _, _, sbCastTime = GetSpellInfo(6215)  -- 暗影箭施法时间（用于计算吸魂通道时间）
    local dsChannel = (sbCastTime / 1000) * 10   -- 吸取灵魂总引导时间（暗影箭施法时间*10）
    return spellPower, mod, dsChannel
end

function calculateLive()
    local spellPower, mod, dsChannel = getCurrentValues()
    local spellDamage = spellPower * coefficientTotal
    -- ★ 运行时读取，可按本服实际数值调整；默认值保持原推测值
    local drainSoulModifier = (PigSet and PigSet.SS_DS_Modifier) or 4
    local baseDS = (PigSet and PigSet.SS_DS_Base) or 840
    local snappedDamage = (baseDS + spellDamage) * shadowMastery * deathsEmbrace * drainSoulModifier * mod
    local total = snappedDamage / dsChannel   -- 每跳伤害（向下取整）
    return math.floor(total)
end