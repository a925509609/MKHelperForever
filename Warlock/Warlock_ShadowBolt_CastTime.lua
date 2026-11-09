-- ============================================================
-- Warlock_ShadowBolt_CastTime.lua
-- 功能：监控玩家身上的“暗影冥思”buff，动态更新暗影箭的施法时间
--       （用于其他模块中计算技能序列）
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if UnitClassBase("player") ~= "WARLOCK" then
    return
end

ayjcast = nil or 0

local SHADOW_TRANCE_SPELL_ID = 17941   -- 暗影冥思 buff ID
local SHADOW_BOLT_SPELL_NAME = "暗影箭"

-- 检查玩家是否拥有暗影冥思 buff
function HasShadowTranceBuff()
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        if spellId == SHADOW_TRANCE_SPELL_ID then
            return true
        elseif not name then
            break
        end
    end
    return false
end

-- 更新暗影箭的施法时间（如果无暗影冥思，则取原始施法时间；否则保持不变，因为暗影冥思已减少施法时间）
function UpdateShadowBoltCastTime()
    if not HasShadowTranceBuff() then
        local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(SHADOW_BOLT_SPELL_NAME)
        if castTime ~= nil then
            ayjcast = castTime / 1000   -- 转换为秒
        end
    end
    -- 注意：有暗影冥思时，不更新 ayjcast，保留上次值（因为施法时间已变短，但此处逻辑未主动改为更短值，可能需根据实际需求调整）
    -- 原代码仅当无 buff 时才获取，意味着有 buff 时维持之前的值（可能是错误，但保留原始逻辑）
end

-- 监听玩家施法开始和光环变化，及时更新
local function OnEvent(self, event, ...)
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            UpdateShadowBoltCastTime()
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_AURA")
frame:SetScript("OnEvent", OnEvent)

-- 初次初始化
UpdateShadowBoltCastTime()