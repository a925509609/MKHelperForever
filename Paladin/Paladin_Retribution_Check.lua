-- ============================================================
-- Paladin_Retribution_Check.lua
-- 功能：惩戒骑循环决策提示（ZZ 2026-08-21 移植）
--   1) 祈求圣光条件即将满足时，提前提醒「祈求圣光 别动了」（红色大字）
--   2) 最后一次十字军打击即将结束时提醒（停下移动准备引导）
--   3) 5层正义圣光重担即将结束时提醒
--   4) 保留原「别乱动」饰品触发提示
-- 控制开关：PigSet.CJ_ZD_TIP（默认开）
-- ============================================================

if WR_PlayerClass ~= "PALADIN" then return end

local IsSpellInRange = IsSpellInRange
local UnitExists = UnitExists
local UnitCanAttack = UnitCanAttack
local UnitAffectingCombat = UnitAffectingCombat
local GetSpellCooldown = GetSpellCooldown
local GetTime = GetTime

local isOutOfRange = false
local checkTimer = 0

-- ★ 提醒节流计时器（秒），防止 PigAlert 刷屏
local tipCooldown = {
    qqsg = 0,      -- 祈求圣光提醒
    crusader = 0,  -- 十字军打击结束提醒
    burden = 0,    -- 圣光重担结束提醒
}

-- 取技能冷却剩余秒数（>0 表示还在冷却）
local function WR_CJ_SpellCDLeft(spell)
    local start, duration = WR_SpellCooldownInfo(spell)
    if not start or not duration or duration <= 0 then return 0 end
    local left = (start + duration) - GetTime()
    if left < 0 then left = 0 end
    return left
end

local PigRangeCheckFrame = CreateFrame("Frame")
PigRangeCheckFrame:SetScript("OnUpdate", function(self, elapsed)
    checkTimer = checkTimer + elapsed
    if checkTimer < 0.2 then return end
    checkTimer = 0

    local now = GetTime()
    local tipEnabled = (PigSet and PigSet.CJ_ZD_TIP)
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target")

    -- ============================================================
    -- 提醒 1：祈求圣光可用 → 大字「祈求圣光 别动了」
    --   对齐官方(PigToGo Paladin_Retribution_Rotation.lua:1151)：
    --   技能可用(脱CD) + 无圣光重担 + 5层精确组合(2/0,5/0,4/1,3/2)
    -- ============================================================
    if tipEnabled and inCombat and PigSet.CJ_ZD_QQSG and hasTarget then
        local justice = WR_GetUnitBuffCount("player", "正义") or 0
        local piety = WR_GetUnitBuffCount("player", "虔诚") or 0
        local noBurden = WR_GetUnitBuffTime("player", "圣光重担") == 0
        -- 5 层精确组合（与官方触发条件完全一致）
        local layerOk = (justice == 2 and piety == 0) or
                        (justice == 5 and piety == 0) or
                        (justice == 4 and piety == 1) or
                        (justice == 3 and piety == 2)
        if WR_SpellUsable("祈求圣光", true) and noBurden and layerOk and now >= tipCooldown.qqsg then
            PigAlert("祈求圣光 别动了", 1, 0, 0, 1.2)
            tipCooldown.qqsg = now + 5  -- 5 秒内不重复
        end
    end

    -- ============================================================
    -- 提醒 2：十字军打击 buff 即将结束（≤2 秒）→ 提醒站定引导
    -- ============================================================
    if tipEnabled and inCombat and hasTarget then
        local crusaderTime = WR_GetUnitBuffTime("player", "十字军打击")
        if crusaderTime > 0 and crusaderTime <= 2 and now >= tipCooldown.crusader then
            PigAlert("十字军快断 站定", 1, 0.5, 0, 1.0)
            tipCooldown.crusader = now + 4
        end
    end

    -- ============================================================
    -- 提醒 3：5层正义圣光重担（圣光裁决）即将结束 → 提醒
    --   ZZ：最后一次 5 层正义圣光重担即将结束时提醒准备引导
    -- ============================================================
    if tipEnabled and inCombat and hasTarget then
        local burdenTime = WR_GetUnitBuffTime("player", "圣光裁决")  -- 5层时的增益名
        if burdenTime <= 0 then
            burdenTime = WR_GetUnitDebuffTime("player", "圣光重担")
        end
        if burdenTime > 0 and burdenTime <= 2 and now >= tipCooldown.burden then
            PigAlert("圣光重担快断 站定", 1, 0.8, 0, 1.0)
            tipCooldown.burden = now + 4
        end
    end

    -- ============================================================
    -- 原有：饰品冷却快好 / 即将触发时提示「别乱动」
    -- ============================================================
    if UnitExists("target") and UnitCanAttack("player", "target") and
       UnitAffectingCombat("player") and (PigSet and PigSet.CJ_ZD_QQSG) then

        local inRange = IsSpellInRange("暗影灼烧", "target")

        -- 条件1：饰品冷却快好时提示
        if (shipincd13 < 8 or shipincd14 < 8) and zidongbaofa and
           (WR_SpellUsable("祈求圣光") or
            (WR_GetUnitDebuffTime("player", "圣光重担") <= 3 and
             WR_GetUnitDebuffTime("player", "圣光重担") > 0 and
             not WR_SpellUsable("祈求圣光"))) and
           ((WR_GetUnitBuffCount("player", "正义") >= 5 and
             WR_GetUnitBuffCount("player", "虔诚") >= 0) or
            (WR_GetUnitBuffCount("player", "正义") >= 4 and
             WR_GetUnitBuffCount("player", "虔诚") >= 1) or
            (WR_GetUnitBuffCount("player", "正义") >= 3 and
             WR_GetUnitBuffCount("player", "虔诚") >= 2) or
            (WR_GetUnitBuffCount("player", "正义") >= 2 and
             WR_GetUnitBuffCount("player", "虔诚") >= 3) or
            (WR_GetUnitBuffCount("player", "正义") >= 1 and
             WR_GetUnitBuffCount("player", "虔诚") >= 4)) then
            PigAlert("别乱动", 0, 1, 0, 2)
        end

        -- 条件2：饰品即将触发时提示
        if (shipincd13 <= 5 or shipincd14 <= 5) and WR_SpellUsable("祈求圣光") and
           WR_GetGCD("十字军打击") <= 3 and zidongbaofa and
           ((WR_GetUnitBuffCount("player", "正义") >= 4 and
             WR_GetUnitBuffCount("player", "虔诚") >= 0) or
            (WR_GetUnitBuffCount("player", "正义") >= 3 and
             WR_GetUnitBuffCount("player", "虔诚") >= 1) or
            (WR_GetUnitBuffCount("player", "正义") >= 2 and
             WR_GetUnitBuffCount("player", "虔诚") >= 2) or
            (WR_GetUnitBuffCount("player", "正义") >= 1 and
             WR_GetUnitBuffCount("player", "虔诚") >= 3) or
            (WR_GetUnitBuffCount("player", "正义") >= 0 and
             WR_GetUnitBuffCount("player", "虔诚") >= 4)) then
            PigAlert("别乱动", 0, 1, 0, 2)
        end
    end
end)
