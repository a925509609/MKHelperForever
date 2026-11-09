-- ============================================================
-- PetAttack_Status.lua
-- 功能：监控宠物是否在攻击目标
--       通过战斗日志判断宠物是否造成伤害
--       结果存储在全局变量 petattack 中
-- ============================================================

local frame = CreateFrame("Frame")
WR_RegisterEventSafe(frame, "COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("UNIT_TARGET")

petattack = false
-- ★ ⑧ 杀戮停等：记录宠物最近一次平砍/伤害时刻与平砍速度，供杀戮命令抑制判定
--   【MK/TIAN 原创 · 非 ZZ 对齐】此功能在 ZZ 时光(Titan 38002) 与 MOP 源码中均无任何对应实现，
--   系从 TIAN 线移植的 MKHelperForever 自有扩展；ZZ 对齐审计时单独列于「MK 原创扩展」区，不计入 ZZ 对齐清单。
WR_LR_SWL_LastPetSwing = 0
WR_LR_SWL_PetSwingSpeed = 2.0

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags,
              destGUID, destName, destFlags = unpack(WR_CombatLogEvent)

        if sourceGUID == UnitGUID("pet") then
            if subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE" or
               subEvent == "SWING_DAMAGE" then
                petattack = true
                WR_LR_SWL_LastPetSwing = GetTime()  -- ★ 记录最近平砍时刻（⑧ 杀戮停等）
                local ms = select(1, UnitAttackSpeed("pet"))
                if ms and ms > 0 then WR_LR_SWL_PetSwingSpeed = ms end  -- ★ 记录主手平砍速度
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" or event == "UNIT_TARGET" then
        local unit = ...
        if event == "UNIT_TARGET" and unit == "pet" then
            petattack = false
            WR_LR_SWL_LastPetSwing = 0  -- ★ 换目标重置平砍计时（⑧ 杀戮停等）
        elseif event == "PLAYER_REGEN_ENABLED" then
            petattack = false
            WR_LR_SWL_LastPetSwing = 0
        end
    end
end)

-- ★ ⑧ 杀戮停等：宝宝是否近期平砍过（未超过两个实际平砍间隔）
--   【MK/TIAN 原创 · 非 ZZ 对齐】见上方变量声明说明，ZZ 时光与 MOP 均无此导出函数。
-- 返回 false 表示宝宝已超过 2 个平砍间隔未攻击，杀戮命令应停止提示，避免卡路/离开目标后挡住杀戮射击
function WR_LR_PetHasAutoAttackedRecently()
    local speed = WR_LR_SWL_PetSwingSpeed or 2.0
    if GetTime() - (WR_LR_SWL_LastPetSwing or 0) > speed * 2 then
        return false
    end
    return true
end