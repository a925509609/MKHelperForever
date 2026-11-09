-- ============================================================
-- Core/AOE_Count.lua
-- 模块：范围计数族 / 团队光环统计 / 爆发DEBUFF门控（维度3）
-- 来源：ZZHELPER_Wrath/Aura.lua 的 ZZ_Shared_MiscModule_* 系列
-- 适配：重命名为 WR_*_BExt；剥离 ZZ_Shared_RuntimeCore_* / ZZ_Wrath_Priest_ClassShared_* 引擎依赖
-- 依赖 A 既有 helper：
--   WR_GetUnitDebuffTime(Unit, Debuff, ByMe)  -- 替代 RuntimeCore_X / RuntimeCore_Y
--   WR_GetUnitBuffTime(Unit, Buff)            -- 替代 RuntimeCore_Z
--   WR_UnitRange(Unit)                        -- 替代 RuntimeCore_R（姓名板距离，无则 999）
--   IsUnitValidTarget(unit)                   -- 替代 ZZ_Wrath_Priest_ClassShared_AS（姓名板有效性过滤）
-- 注：B 专用数据（AssistDebuffName / DangerDebuff / Outburst* 等）改为下方
--     模块级配置表，默认空（安全门控：未配置时函数返回 999 / false，
--     不会因缺少 B 引擎数据而报错）。调用方可按需填充或传参覆盖。
-- ============================================================

-- ===== B 专用"爆发/危险 DEBUFF"配置（默认空，安全门控）=====
-- 如需启用"全团爆发DEBUFF最短剩余扫描"，把对应的 DEBUFF 名填入下表：
BExt_BurstDebuffList = BExt_BurstDebuffList or {}        -- 例如 {"暴怒","魔法增效",...}
BExt_PartyOutburstDebuffList = BExt_PartyOutburstDebuffList or {}
BExt_AssistDebuffName = BExt_AssistDebuffName or ""       -- 助攻型 DEBUFF 名（可选）
BExt_DangerDebuffName = BExt_DangerDebuffName or ""       -- 危险 DEBUFF 名（可选）
BExt_OutburstCastingSpell = BExt_OutburstCastingSpell or "" -- 正在施放的爆发法术名（可选）

-- 调试开关（对应 B 的全局 MSG）：true 时打印计数结果
local BExt_AOE_Debug = false

-- ============================================================
-- ★ 范围内未中指定 DEBUFF 的敌对单位计数（B: MiscModule_J）
-- 参数：Range, DebuffName, InCombat
-- ============================================================
function WR_GetEnemyCountWithoutDebuff_BExt(Range, DebuffName, InCombat)
    local RangeCount = 0
    for i = 1, 40 do
        local unit = "nameplate" .. i
        local maxRange = WR_UnitRange(unit)
        local creatureType = WR_SafeCreatureType and WR_SafeCreatureType(unit) or UnitCreatureType(unit)
        if maxRange ~= nil and maxRange <= Range
           and UnitCanAttack("player", unit)
           and WR_GetUnitDebuffTime(unit, DebuffName, true) == 0
           and creatureType ~= "图腾" and creatureType ~= "Totem"
           and creatureType ~= "气体云雾" and creatureType ~= "Gas Cloud" then
            if (UnitAffectingCombat(unit) and InCombat) or not InCombat then
                if IsUnitValidTarget(unit) then
                    RangeCount = RangeCount + 1
                end
            end
        end
    end
    if BExt_AOE_Debug then
        print("|cff00ff00", Range, "|cffffffff码内，没有中|cffffdf00", DebuffName, "|cffffffff的敌人数量为:|cffff5040", RangeCount)
    end
    return RangeCount
end

-- ============================================================
-- ★ 范围内带指定 DEBUFF 且剩余 ≥ 阈值的敌对单位计数（B: MiscModule_H）
-- 参数：Range, DebuffName, InCombat, Time(默认1)
-- ============================================================
function WR_GetEnemyCountWithDebuffThreshold_BExt(Range, DebuffName, InCombat, Time)
    local RangeCount = 0
    local time = Time or 1
    for i = 1, 40 do
        local unit = "nameplate" .. i
        local creatureType = WR_SafeCreatureType and WR_SafeCreatureType(unit) or UnitCreatureType(unit)
        if creatureType ~= "图腾" and creatureType ~= "Totem"
           and creatureType ~= "气体云雾" and creatureType ~= "Gas Cloud"
           and UnitCanAttack("player", unit)
           and ((InCombat and UnitAffectingCombat(unit)) or not InCombat)
           and WR_UnitRange(unit) <= Range
           and IsUnitValidTarget(unit)
           and WR_GetUnitDebuffTime(unit, DebuffName, true) >= time then
            RangeCount = RangeCount + 1
        end
    end
    if BExt_AOE_Debug then
        print("|cff00ff00", Range, "|cffffffff码内，中|cffffdf00", DebuffName, "|cffffffff(≥", time, ")的敌人数量为:|cffff5040", RangeCount)
    end
    return RangeCount
end

-- ============================================================
-- ★ 范围内带指定 DEBUFF 的敌对单位计数（B: MiscModule_L）
-- 参数：Range, Debuff, ByMe
-- ============================================================
function WR_GetEnemyCountWithDebuff_BExt(Range, Debuff, ByMe)
    local count = 0
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit)
           and UnitCanAttack("player", unit)
           and WR_UnitRange(unit) <= Range
           and WR_GetUnitDebuffTime(unit, Debuff, ByMe) > 0 then
            count = count + 1
        end
    end
    return count
end

-- ============================================================
-- ★ AOE 伤害衰减计算（按目标数 sqrt 衰减）（B: MiscModule_D）
-- 参数：Damage(单目标基础伤害), UnitCount(目标总数), Number(衰减起始目标)
-- 返回：衰减后总伤害
-- ============================================================
function WR_AOEDamageFalloff_BExt(Damage, UnitCount, Number)
    if Number > UnitCount then
        return Damage * UnitCount
    end
    local DamageMitigation = Damage * (Number - 1)
    for i = Number, UnitCount do
        DamageMitigation = DamageMitigation + Damage * math.sqrt((Number - 1) / i)
    end
    return DamageMitigation
end

-- ============================================================
-- ★ 全团带指定 BUFF 的人数统计（B: MiscModule_K）
-- 参数：BuffName
-- ============================================================
function WR_GetRaidBuffCount_BExt(BuffName)
    local Count = 0
    for i = 1, 25 do
        if WR_GetUnitBuffTime("raid" .. i, BuffName) > 0 then
            Count = Count + 1
        end
    end
    return Count
end

-- ============================================================
-- ★ 全团带指定 DEBUFF 的人数统计（B: MiscModule_G）
-- 参数：DebuffName
-- ============================================================
function WR_GetRaidDebuffCount_BExt(DebuffName)
    local Count = 0
    for i = 1, 25 do
        if WR_GetUnitDebuffTime("raid" .. i, DebuffName) > 0 then
            Count = Count + 1
        end
    end
    return Count
end

-- ============================================================
-- ★ 范围内带指定 DEBUFF 的敌对单位中，最短剩余时间（B: MiscModule_I）
-- 参数：Range, Debuff, ByMe
-- 返回：最短剩余秒数；无则 0
-- ============================================================
function WR_GetRangeDebuffMinTime_BExt(Range, Debuff, ByMe)
    local time = 999
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitCanAttack("player", unit) and WR_UnitRange(unit) <= Range then
            local t = WR_GetUnitDebuffTime(unit, Debuff, ByMe)
            if t > 0 and t <= time then
                time = t
            end
        end
    end
    return (time == 999) and 0 or time
end

-- ============================================================
-- ★ 全团"爆发 DEBUFF"最短剩余扫描（安全门控）（B: MiscModule() 无参版）
-- 参数：debuffList(可选，默认 BExt_PartyOutburstDebuffList / BExt_BurstDebuffList)
-- 返回：最短剩余秒数；无则 999
-- ============================================================
function WR_GetRaidBurstDebuffMinTime_BExt(debuffList)
    local list = debuffList or BExt_PartyOutburstDebuffList
    local best = 999
    local scanUnit = function(u)
        local lt = list
        for _, Debuff in pairs(lt) do
            local t = WR_GetUnitDebuffTime(u, Debuff)
            if t > 0 and t < best then best = t end
        end
    end
    for i = 1, 4 do
        if UnitExists("party" .. i) then scanUnit("party" .. i) end
    end
    for i = 1, 40 do
        if UnitExists("raid" .. i) then scanUnit("raid" .. i) end
    end
    return best
end

-- ============================================================
-- ★ 单个单位"爆发 DEBUFF"最短剩余时间（B: MiscModule_F）
-- 参数：Unit, debuffList(可选，默认 BExt_BurstDebuffList)
-- 返回：最短剩余秒数；无则 999
-- ============================================================
function WR_GetUnitBurstDebuffMinTime_BExt(Unit, debuffList)
    local list = debuffList or BExt_BurstDebuffList
    local best = 999
    for _, Debuff in pairs(list) do
        local t = WR_GetUnitDebuffTime(Unit, Debuff)
        if t > 0 and t < best then best = t end
    end
    return best
end

-- ============================================================
-- ★ 单位是否带有危险/爆发 DEBUFF（安全门控）（B: MiscModule_C）
-- 参数：Unit, 可选覆盖：assistName, dangerName, castingSpell
-- 返回：true/false
-- ============================================================
function WR_HasDangerBurstDebuff_BExt(Unit, assistName, dangerName, castingSpell)
    local aName = assistName or BExt_AssistDebuffName
    local dName = dangerName or BExt_DangerDebuffName
    local cSpell = castingSpell or BExt_OutburstCastingSpell
    if aName ~= "" and WR_GetUnitDebuffTime(Unit, aName) > 0 then return true end
    if dName ~= "" and WR_GetUnitDebuffTime(Unit, dName) > 0 then return true end
    if cSpell ~= "" then
        local name = (UnitCastingInfo(Unit))
        if name == cSpell then return true end
    end
    return false
end
