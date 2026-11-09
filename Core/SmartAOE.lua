-- ============================================================
-- Core/SmartAOE.lua
-- ★ 2026-08-21：智能 AOE 逻辑接入（参考 ZZHELPER 8月19日 named 版 Combat.lua 的 QZWY_AOE_Name / ReflectionAOE）
--
-- 两个 PigSet 开关（由 Core/UI_Config.lua 的"智能AOE"分类开关控制）：
--   PigSet.WR_GLOBAL_SMART_AOE  智能 AOE（自动）：按目标数 + DEBUFF 自动判断
--   PigSet.WR_GLOBAL_MANUAL_AOE  手动 AOE（爆发）：爆发期间强制施放 AOE
--
-- 各职业 AOE 调用前直接判断：
--   if WR_ShouldUseAOE("暴风雪", 35, "", 3) then
--       -- 施放暴风雪
--   end
-- ============================================================

local _SmartAOE_Debug = false

-- ============================================================
-- ★ 范围内敌对单位计数（无 DEBUFF 过滤版）
--   复用 AOE_Count.lua 的过滤规则（敌对、非图腾/气体、姓名板有效）
--   参数：Range(默认 8yd), InCombat(默认 true)
-- ============================================================
function WR_GetEnemyCountInRange(Range, InCombat)
    local RangeCount = 0
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then
            local maxRange = WR_UnitRange(unit)
            local creatureType = WR_SafeCreatureType and WR_SafeCreatureType(unit) or UnitCreatureType(unit)
            if maxRange ~= nil and maxRange <= Range
               and UnitCanAttack("player", unit)
               and creatureType ~= "图腾" and creatureType ~= "Totem"
               and creatureType ~= "气体云雾" and creatureType ~= "Gas Cloud"
               and IsUnitValidTarget(unit) then
                if (UnitAffectingCombat(unit) and InCombat) or not InCombat then
                    RangeCount = RangeCount + 1
                end
            end
        end
    end
    return RangeCount
end

-- ============================================================
-- ★ 智能 AOE 判定（参考 ZZHELPER Combat.lua 的 QZWY_AOE_Name / ReflectionAOE）
-- 参数：
--   spellName   技能名（调试用，可空）
--   range       搜索半径（默认 8yd）
--   debuffName  可选：避免抢反状态目标（指定后按"未中此 debuff"计数）
--   minCount    最少目标数阈值（默认 3）
-- 返回：true / false（是否施放该 AOE）
-- 逻辑：
--   1. 手动 AOE 开启（爆发模式）→ 强制 true
--   2. 智能 AOE 关闭 + 手动 AOE 关闭 → false
--   3. 智能 AOE 开启 → 范围内未中 debuff 的敌对数 >= minCount 时 true
-- ============================================================
function WR_ShouldUseAOE(spellName, range, debuffName, minCount)
    local r = range or 8
    local mc = minCount or 3
    local db = debuffName or ""

    -- 手动 AOE 开启（爆发模式）：强制施放
    if PigSet.WR_GLOBAL_MANUAL_AOE == true then
        if _SmartAOE_Debug then
            print("|cff00adf0[SmartAOE]|r", spellName or "?", "手动 AOE 模式 → 施放")
        end
        return true
    end

    -- 智能 AOE 关闭：不施放 AOE
    if PigSet.WR_GLOBAL_SMART_AOE ~= true then
        if _SmartAOE_Debug then
            print("|cff00adf0[SmartAOE]|r", spellName or "?", "智能/手动 AOE 均关闭 → 不施放")
        end
        return false
    end

    -- 智能 AOE 模式：根据目标数判断
    local count
    if db ~= "" then
        count = WR_GetEnemyCountWithoutDebuff_BExt(r, db, true)
    else
        count = WR_GetEnemyCountInRange(r, true)
    end

    local result = count >= mc
    if _SmartAOE_Debug then
        print("|cff00adf0[SmartAOE]|r", spellName or "?", "智能 AOE:", count, "/", mc, "→", result and "施放" or "不施放")
    end
    return result
end

-- ============================================================
-- 调试开关（供 UI 或命令开关调用）
-- ============================================================
function WR_SetSmartAOEDebug(enabled)
    _SmartAOE_Debug = enabled and true or false
end

function WR_IsSmartAOEDebug()
    return _SmartAOE_Debug
end