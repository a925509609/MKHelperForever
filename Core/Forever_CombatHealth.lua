-- ============================================================
-- Core/Forever_CombatHealth.lua
-- 《魔兽世界：无限》(WoW: Forever) 战斗内血量估算
-- ------------------------------------------------------------
-- 背景：Forever 继承 12.x secret value 机制，战斗中 UnitHealth /
-- UnitHealthMax / UnitHealthPercent 对插件返回 secret，直接比较会
-- 报 "attempt to compare a secret number value"。但客户端仍允许：
--   · UNIT_COMBAT 的 amount 是普通数字（伤害/治疗量可读）
--   · UNIT_HEALTH 事件正常触发（只告诉“变了”，不给值）
-- 本模块用「脱战精确快照 + 战斗中 UNIT_COMBAT 增减 + UNIT_HEALTH
-- 事件压力」维护每个队伍成员的估算血量，供 WR_GetUnitHP 在
-- secret 期间使用。脱战/可读时始终走精确值，不改变旧行为。
-- ============================================================

WR_CombatHealth = WR_CombatHealth or {}
local CH = WR_CombatHealth

CH.PRESSURE_WINDOW = 2.5      -- 秒：未匹配 UNIT_HEALTH 事件的统计窗口
CH.COMBAT_MATCH_WINDOW = 0.35 -- 秒：UNIT_COMBAT 与 UNIT_HEALTH 的配对窗口
CH.HEALTH_DEBOUNCE = 0.05     -- 秒：UNIT_HEALTH / UNIT_HEALTH_FREQUENT 同一次变化的去重窗口
CH.RECORD_TTL = 30            -- 秒：不在队伍中的记录清理时间

local DAMAGE_ACTIONS = {
    WOUND = true, DAMAGE = true, SPELL_DAMAGE = true, SPELL_PERIODIC_DAMAGE = true,
    RANGED_DAMAGE = true, DAMAGE_SHIELD = true, ENVIRONMENTAL_DAMAGE = true,
    SPELL_BUILDING_DAMAGE = true, DAMAGE_SPLIT = true,
}
local HEAL_ACTIONS = {
    HEAL = true, SPELL_HEAL = true, SPELL_PERIODIC_HEAL = true,
}

local function CH_Now()
    if type(GetTime) == "function" then return GetTime() end
    return 0
end

local function CH_IsSecret(v)
    if type(WR_IsSecretValue) == "function" then return WR_IsSecretValue(v) end
    if type(issecretvalue) == "function" then
        local ok, res = pcall(issecretvalue, v)
        return ok and res == true
    end
    return false
end

local function CH_Num(v, fallback)
    if CH_IsSecret(v) then return fallback end
    if type(v) ~= "number" then return fallback end
    return v
end

local function CH_UnitExists(unit)
    if type(unit) ~= "string" or unit == "" then return false end
    if type(UnitExists) ~= "function" then return false end
    local ok, exists = pcall(UnitExists, unit)
    return ok and exists == true
end

local function CH_IsGroupUnit(unit)
    if unit == "player" or unit == "pet" then return true end
    if type(unit) ~= "string" then return false end
    if unit:match("^party%d+$") or unit:match("^raid%d+$") then return true end
    if unit:match("^partypet%d+$") or unit:match("^raidpet%d+$") then return true end
    return false
end

local function CH_Ensure(unit)
    local rec = CH[unit]
    if type(rec) ~= "table" then
        rec = {
            hp = nil, maxHp = nil, pct = 1, init = false, maxKnown = false,
            lastExact = -1, lastCombat = -1, lastSeen = CH_Now(),
            unmatched = {},
        }
        CH[unit] = rec
    end
    rec.lastSeen = CH_Now()
    return rec
end

-- 精确读取（可读时）。返回 true 表示成功刷新。
function WR_CombatHealth_RefreshExact(unit)
    if not CH_UnitExists(unit) then return false end
    local rec = CH_Ensure(unit)
    local hp = UnitHealth(unit)
    local maxHp = UnitHealthMax(unit)
    if CH_IsSecret(hp) or CH_IsSecret(maxHp) then return false end
    hp = CH_Num(hp, nil)
    maxHp = CH_Num(maxHp, 0)
    if hp == nil or maxHp == nil or maxHp <= 0 then return false end
    if hp < 0 then hp = 0 end
    if hp > maxHp then hp = maxHp end
    rec.hp = hp
    rec.maxHp = maxHp
    rec.pct = hp / maxHp
    rec.init = true
    rec.maxKnown = true
    rec.lastExact = CH_Now()
    return true
end

-- 初始化一个无法精确读取的单位：优先用可读的最大生命，否则用 100 点虚拟血。
local function CH_InitFallback(unit, rec)
    local maxHp = 100
    local maxKnown = false
    if CH_UnitExists(unit) then
        local raw = UnitHealthMax(unit)
        raw = CH_Num(raw, nil)
        if raw and raw > 0 then
            maxHp = raw
            maxKnown = true
        end
    end
    rec.maxHp = maxHp
    rec.maxKnown = maxKnown
    rec.hp = maxHp
    rec.pct = 1
    rec.init = true
end

-- 把 focus / target 别名解析到真实队伍单位 token：
-- 战斗中焦点/目标也是 secret，但 UnitIsUnit 仍可安全比较；
-- 不解析的话 "focus" 会新建一条 100/100 的假记录，永远按满血算。
local function CH_ResolveUnit(unit)
    if type(unit) ~= "string" then return unit end
    if unit ~= "focus" and unit ~= "target" then return unit end
    if type(UnitIsUnit) ~= "function" then return unit end
    local candidates = { "player" }
    local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    if raid > 0 then
        for i = 1, raid do candidates[#candidates + 1] = "raid" .. i end
    else
        for i = 1, party do candidates[#candidates + 1] = "party" .. i end
    end
    for _, token in ipairs(candidates) do
        if CH_UnitExists(token) then
            local ok, same = pcall(UnitIsUnit, token, unit)
            if ok and same == true then return token end
        end
    end
    return unit
end

function WR_CombatHealth_GetPct(unit)
    unit = CH_ResolveUnit(unit)
    if not CH_UnitExists(unit) then return nil end
    local rec = CH_Ensure(unit)
    -- 能直读就永远直读，估算只在 secret 时兜底
    if WR_CombatHealth_RefreshExact(unit) then return rec.pct end
    if not rec.init then CH_InitFallback(unit, rec) end

    -- 脱战时的血量变化（吃喝/回复）不算战斗压力
    if type(UnitAffectingCombat) == "function" then
        local okCombat, inCombat = pcall(UnitAffectingCombat, unit)
        if okCombat and inCombat == false then return rec.pct end
    end

    local now = CH_Now()
    local count = 0
    for i = #rec.unmatched, 1, -1 do
        local t = rec.unmatched[i]
        if now - t <= CH.PRESSURE_WINDOW then
            count = count + 1
        else
            table.remove(rec.unmatched, i)
        end
    end

    local pct = rec.pct or 1
    -- 没配上 UNIT_COMBAT 的 UNIT_HEALTH 事件 = 有看不到数值的血量变化。
    -- 对治疗而言宁可多刷，不放过连续掉血的目标；用压力上限逐步压低估算。
    if count >= 3 then
        pct = math.min(pct, 0.45)
    elseif count == 2 then
        pct = math.min(pct, 0.65)
    elseif count == 1 then
        pct = math.min(pct, 0.85)
    end
    if pct < 0 then pct = 0 end
    if pct > 1 then pct = 1 end
    return pct
end

function WR_CombatHealth_GetInfo(unit)
    unit = CH_ResolveUnit(unit)
    local rec = CH[unit]
    if type(rec) ~= "table" then return nil end
    return {
        pct = WR_CombatHealth_GetPct(unit),
        hp = rec.hp,
        maxHp = rec.maxKnown and rec.maxHp or nil,
        init = rec.init,
        maxKnown = rec.maxKnown,
        lastExact = rec.lastExact,
        lastCombat = rec.lastCombat,
    }
end

local function CH_ApplyCombat(unit, action, amount)
    if not CH_IsGroupUnit(unit) then return end
    if type(action) ~= "string" then return end
    amount = CH_Num(amount, 0)
    if not amount or amount <= 0 then return end
    local rec = CH_Ensure(unit)
    if not rec.init then
        if not WR_CombatHealth_RefreshExact(unit) then CH_InitFallback(unit, rec) end
    end
    local isDamage = DAMAGE_ACTIONS[action] == true
    local isHeal = HEAL_ACTIONS[action] == true
    if not isDamage and not isHeal then return end
    local now = CH_Now()
    -- 事件顺序可能是 UNIT_HEALTH 先、UNIT_COMBAT 后；先到的 UNIT_HEALTH 已经
    -- 记过一次压力，这里把配对的一条压力删掉，避免同一次掉血算两次。
    for i = #rec.unmatched, 1, -1 do
        if now - rec.unmatched[i] <= CH.COMBAT_MATCH_WINDOW then
            table.remove(rec.unmatched, i)
            break
        end
    end
    if isDamage then
        if rec.maxKnown and rec.maxHp and rec.maxHp > 0 then
            rec.hp = rec.hp - math.abs(amount)
            if rec.hp < 0 then rec.hp = 0 end
            rec.pct = rec.hp / rec.maxHp
        else
            -- 最大生命也不可读（新入队/名册中新增）：绝对伤害无法换算成百分比，
            -- 退化为一次「未知掉血」压力，至少不会把 2000 伤害当成 100 点血直接归零。
            rec.unmatched[#rec.unmatched + 1] = now
            if #rec.unmatched > 20 then table.remove(rec.unmatched, 1) end
        end
    else
        if rec.maxKnown and rec.maxHp and rec.maxHp > 0 then
            rec.hp = rec.hp + math.abs(amount)
            if rec.hp > rec.maxHp then rec.hp = rec.maxHp end
            rec.pct = rec.hp / rec.maxHp
        else
            -- 未知最大血时，治疗事件抵消一次压力（不能按绝对值累加）
            if #rec.unmatched > 0 then table.remove(rec.unmatched) end
        end
    end
    rec.lastCombat = now
end

local function CH_OnHealth(unit)
    if not CH_IsGroupUnit(unit) then return end
    local now = CH_Now()
    if WR_CombatHealth_RefreshExact(unit) then
        local rec = CH[unit]
        if rec then rec.unmatched = {} end
        return
    end
    local rec = CH_Ensure(unit)
    if not rec.init then CH_InitFallback(unit, rec) end
    if type(UnitAffectingCombat) == "function" then
        local okCombat, inCombat = pcall(UnitAffectingCombat, unit)
        if okCombat and inCombat == false then return end
    end
    if now - (rec.lastCombat or -999) <= CH.COMBAT_MATCH_WINDOW then
        return -- 已经由 UNIT_COMBAT 记账
    end
    -- UNIT_HEALTH 与 UNIT_HEALTH_FREQUENT 可能对同一次变化各发一次，去重
    local last = rec.unmatched[#rec.unmatched]
    if last and now - last < CH.HEALTH_DEBOUNCE then return end
    rec.unmatched[#rec.unmatched + 1] = now
    if #rec.unmatched > 20 then table.remove(rec.unmatched, 1) end
end

function WR_CombatHealth_SnapshotAll()
    local units = { "player", "pet" }
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    if raid > 0 then
        for i = 1, raid do
            units[#units + 1] = "raid" .. i
            units[#units + 1] = "raidpet" .. i
        end
    elseif party > 0 then
        for i = 1, party do
            units[#units + 1] = "party" .. i
            units[#units + 1] = "partypet" .. i
        end
    end
    for _, unit in ipairs(units) do
        if CH_UnitExists(unit) then
            local okDead, dead = pcall(UnitIsDeadOrGhost, unit)
            if okDead and not dead then WR_CombatHealth_RefreshExact(unit) end
        end
    end
    -- 清理已经离队的记录
    local now = CH_Now()
    for unit, rec in pairs(CH) do
        if type(rec) == "table" and now - (rec.lastSeen or now) > CH.RECORD_TTL then
            CH[unit] = nil
        end
    end
end

local function CH_ClearPressure()
    for _, rec in pairs(CH) do
        if type(rec) == "table" then rec.unmatched = {} end
    end
end

local frame = CreateFrame("Frame")
local function reg(event)
    -- 事件名不存在时 RegisterEvent 会抛错，这里统一用 pcall 容错；
    -- CLEU 等被安全层拦下的事件由 WR_RegisterEventSafe 负责。
    local ok, res = pcall(function()
        if type(WR_RegisterEventSafe) == "function" then
            return WR_RegisterEventSafe(frame, event)
        end
        return frame:RegisterEvent(event)
    end)
    return ok and res ~= false
end
reg("UNIT_COMBAT")
reg("UNIT_HEALTH")
reg("UNIT_HEALTH_FREQUENT")
reg("UNIT_MAXHEALTH")
reg("PLAYER_REGEN_DISABLED")
reg("PLAYER_REGEN_ENABLED")
reg("GROUP_ROSTER_UPDATE")
reg("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_COMBAT" then
        local unit, action, _flag, amount = ...
        CH_ApplyCombat(unit, action, amount)
    elseif event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        local unit = ...
        CH_OnHealth(unit)
    elseif event == "UNIT_MAXHEALTH" then
        local unit = ...
        if CH_IsGroupUnit(unit) then WR_CombatHealth_RefreshExact(unit) end
    elseif event == "PLAYER_REGEN_DISABLED" then
        WR_CombatHealth_SnapshotAll()
    elseif event == "PLAYER_REGEN_ENABLED" then
        CH_ClearPressure()
        WR_CombatHealth_SnapshotAll()
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        WR_CombatHealth_SnapshotAll()
    end
end)

-- 脱战期间每秒刷一次精确快照，保证下一次进战斗前基线是最新的
local snapshotElapsed = 0
frame:SetScript("OnUpdate", function(_, elapsed)
    if type(InCombatLockdown) == "function" then
        local ok, locked = pcall(InCombatLockdown)
        if ok and locked then return end
    end
    snapshotElapsed = (snapshotElapsed or 0) + (elapsed or 0)
    if snapshotElapsed >= 1.0 then
        snapshotElapsed = 0
        WR_CombatHealth_SnapshotAll()
    end
end)

WR_CombatHealth_SnapshotAll()
