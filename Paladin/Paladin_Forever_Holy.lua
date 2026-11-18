-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "PALADIN" then return end
-- ============================================================
-- Paladin Forever · Holy 专精循环（奶骑治疗 · 无限 1.60.x / 60级）
-- 共享 helper 见 Paladin_Forever.lua（公共件）
-- 功能层见 Paladin_Holy_Features.lua（圣印 / 圣光誓约 / 祝福 / 驱散 / 愤怒之锤 / 驱邪术 / 插入）
-- ------------------------------------------------------------
-- 【治疗模型】色块 = 现在该按这个键；治疗目标固定是「焦点」。
--   本职业所有治疗宏都是 [@focus] 形态：
--     109 圣光闪现 / 110 圣光术 / 113 神圣震击 / 150 圣疗术 / 63 清洁术(焦点)
--   焦点不可用时只走自施槽位（18 圣盾术 / 48 圣疗术 / 43 清洁术）。
--   ★ 2026-11-17 修复：109/110/150 宏改为「[@focus,help,nodead] 技能; 技能」两段式，
--     焦点无效时自动落回自己，杜绝「没焦点时圣光术/圣光闪现永远不亮」。
--
-- 【本服 60 级技能（法术书实测）】
--   圣光术 635 / 圣光闪现 19750 / 神圣震击 1311606 / 神恩术 20216 /
--   圣疗术 633 / 清洁术 4987 / 圣盾术 642 / 圣光守望 1311595 / 圣光誓约 1328548
--   ★ 80 级技能（圣光道标 / 圣洁护盾 / 神圣牺牲 / 光环掌握 / 复仇之怒 /
--     祈求圣光 / 神圣风暴）在无限服不存在，本文件不再引用。
--
-- 【优先级】高 → 低：
--   0 脱战祝福（复用 Paladin_Blessing.lua）
--   1 读条保护 / 过量停条（SS_GLTC）
--   2 自身圣盾术（< SS_SDS）
--   3 自身圣疗术 / 焦点圣疗术（< SS_SLS，默认 69）
--   4 喝红药（< SS_HXY，默认 90）
--   5 神恩术（只有圣光术确实要用时才提示）
--   6 圣光守望（< SS_SGWS，默认 52；≥2 人低血）
--   7 神圣震击（< SS_SSZJ，默认 54；移动中放宽；有守望标记无条件）
--   8 圣光术（< SS_SGS，默认 60）
--   9 圣光闪现（< SS_SGSX，默认 85）
--  10 清洁术（自己 → 焦点 → 指向）
--  11 圣光誓约 / 圣印 / 审判维持 / 切换目标 / 愤怒之锤 / 驱邪术 / 奉献 / 插入
--
-- 【2026-11-17 加血逻辑修复（参照 PaladinAssist 的队友血线快照 + 治疗预估模型）】
--   · 自动选人：每 tick 扫描 player / focus / target / party1-4 / raid1-25，
--     按「有效血量（当前血量 + 在途治疗）」选最低者，不再只看焦点。
--   · 治疗模式 SS_ZLMS：全团 / 目标 / 预读 / 泄蓝 / 坦克 / 脆皮 / 1-5队 / 萨12-15，
--     过滤规则与旧版奶骑一致；焦点会自动切到最该治疗的人（含自己 → 192 槽）。
--   · 有效血量：UnitGetIncomingHeals 计入在途治疗，避免重复刷满血目标。
--   · 移动判定：圣光术/圣光闪现是读条技能，移动中不点亮（战争艺术/瞬发例外）。
--   · 预读/泄蓝：SS_ZLMS=3/4 允许满血起手圣光术；SS_ZLMS=4 不受过量停条限制。
-- ============================================================

WR_PaladinForeverHoly_FavorAt = WR_PaladinForeverHoly_FavorAt or nil
WR_PaladinForeverHoly_VigilAt = WR_PaladinForeverHoly_VigilAt or nil

function WR_PaladinForeverHoly_Cfg(key, def)
    local v = PigSet and PigSet[key]
    if type(v) ~= "number" then return def end
    return v
end

-- 治疗模式（与 Paladin_Menu.lua 的 15 项下拉严格对应）
function WR_PaladinForeverHoly_GetMode()
    local v = WR_PaladinForeverHoly_Cfg("SS_ZLMS", 1)
    v = tonumber(v) or 1
    if v < 1 or v > 15 then v = 1 end
    return v
end

-- 安全布尔：secret boolean 直接比较会抛错，统一 pcall 收敛
local function WR_PaladinForeverHoly_SafeBool(v)
    if type(v) == "boolean" then return v end
    local okT, t = pcall(function() return v == true end)
    if okT and t == true then return true end
    local okF, f = pcall(function() return v == false end)
    if okF and f == true then return false end
    return nil
end

local function WR_PaladinForeverHoly_SafeNumber(v)
    local n = tonumber(v)
    if n == nil then return nil end
    if type(WR_IsSecretValue) == "function" then
        local ok, secret = pcall(WR_IsSecretValue, n)
        if ok and secret == true then return nil end
    end
    return n
end

function WR_PaladinForeverHoly_FocusUsable()
    if type(UnitExists) ~= "function" or not UnitExists("focus") then return false end
    local okDead, dead = pcall(UnitIsDeadOrGhost, "focus")
    if okDead and WR_PaladinForeverHoly_SafeBool(dead) == true then return false end
    if type(UnitIsFriend) == "function" then
        local okF, friend = pcall(UnitIsFriend, "player", "focus")
        if okF and WR_PaladinForeverHoly_SafeBool(friend) == false then return false end
    end
    if type(UnitCanAttack) == "function" then
        local okA, attack = pcall(UnitCanAttack, "player", "focus")
        if okA and WR_PaladinForeverHoly_SafeBool(attack) == true then return false end
    end
    -- 40 码外无法治疗：焦点失效，按「无焦点」处理（会重新自动选人）
    if type(WR_UnitRange) == "function" then
        local okR, range = pcall(WR_UnitRange, "focus")
        if okR and type(range) == "number" and range > 40 and range < 900 then return false end
    end
    return true
end

function WR_PaladinForeverHoly_GroupUnits()
    local units = { "player" }
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    if raid > 0 then
        for i = 1, raid do units[#units + 1] = "raid" .. i end
    elseif party > 0 then
        for i = 1, party do units[#units + 1] = "party" .. i end
    end
    return units
end

-- 单位 token → 队伍序号（用于坦克判定 / 队伍模式过滤）
function WR_PaladinForeverHoly_UnitIndex(unit)
    if type(unit) ~= "string" then return nil end
    local p = string.match(unit, "^party(%d)$")
    if p then return tonumber(p) end
    local r = string.match(unit, "^raid(%d+)$")
    if r then return tonumber(r) end
    return nil
end

-- 单位所在小队编号（1-5）；focus/target 先解析到真实队伍单位
function WR_PaladinForeverHoly_GroupId(unit)
    if unit == "player" then return 1 end
    local idx = WR_PaladinForeverHoly_UnitIndex(unit)
    if idx then
        local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
        if raid > 0 and type(GetRaidRosterInfo) == "function" then
            local ok, _, _, subgroup = pcall(GetRaidRosterInfo, idx)
            if ok and type(subgroup) == "number" and subgroup >= 1 then return subgroup end
            return math.ceil(idx / 5)
        end
        return 1
    end
    if unit == "focus" or unit == "target" then
        local units = WR_PaladinForeverHoly_GroupUnits()
        for i = 1, #units do
            local ok, same = pcall(function() return UnitIsUnit(units[i], unit) == true end)
            if ok and same == true then
                return WR_PaladinForeverHoly_GroupId(units[i])
            end
        end
        return 1
    end
    return 1
end

function WR_PaladinForeverHoly_IsTank(unit)
    if type(UnitGroupRolesAssigned) == "function" then
        local ok, role = pcall(UnitGroupRolesAssigned, unit)
        if ok and role == "TANK" then return true end
    end
    local idx = WR_PaladinForeverHoly_UnitIndex(unit)
    if idx and type(WR_NumIsTank) == "function" then
        local ok, tank = pcall(WR_NumIsTank, idx)
        if ok and tank == true then return true end
    end
    return false
end

-- 有效血量：当前血量百分比 + 在途治疗 / 最大生命；读不到返回 nil
function WR_PaladinForeverHoly_EffectiveHP(unit)
    if type(unit) ~= "string" or unit == "" then return nil end
    local hp = nil
    if type(WR_GetUnitHP) == "function" then
        local ok, v = pcall(WR_GetUnitHP, unit)
        if ok then hp = WR_PaladinForeverHoly_SafeNumber(v) end
    end
    if hp == nil then
        if type(UnitHealth) ~= "function" then return nil end
        local okH, v = pcall(UnitHealth, unit)
        local okM, m = pcall(UnitHealthMax, unit)
        local hv = okH and WR_PaladinForeverHoly_SafeNumber(v) or nil
        local mv = okM and WR_PaladinForeverHoly_SafeNumber(m) or nil
        if hv == nil or mv == nil or mv <= 0 then return nil end
        hp = hv / mv
    end
    if hp < 0 then hp = 0 elseif hp > 1 then hp = 1 end

    local maxHp = nil
    if type(WR_SafeUnitMaxHealth) == "function" then
        local ok, v = pcall(WR_SafeUnitMaxHealth, unit)
        if ok then maxHp = WR_PaladinForeverHoly_SafeNumber(v) end
    end
    if maxHp == nil and type(UnitHealthMax) == "function" then
        local ok, v = pcall(UnitHealthMax, unit)
        if ok then maxHp = WR_PaladinForeverHoly_SafeNumber(v) end
    end
    if type(UnitGetIncomingHeals) == "function" and type(maxHp) == "number" and maxHp > 1 then
        local okI, incoming = pcall(UnitGetIncomingHeals, unit)
        local inc = okI and WR_PaladinForeverHoly_SafeNumber(incoming) or nil
        if type(inc) == "number" and inc > 0 then
            hp = hp + inc / maxHp
            if hp > 1 then hp = 1 end
        end
    end
    return hp
end

-- 可治疗单位：存活 / 友善 / 玩家 / 40 码内 / 在线
function WR_PaladinForeverHoly_ValidHealUnit(unit)
    if type(unit) ~= "string" or unit == "" then return false end
    if type(UnitExists) ~= "function" then return false end
    local okE, exists = pcall(UnitExists, unit)
    if not okE or WR_PaladinForeverHoly_SafeBool(exists) ~= true then return false end
    if type(UnitIsDeadOrGhost) == "function" then
        local okD, dead = pcall(UnitIsDeadOrGhost, unit)
        if okD and WR_PaladinForeverHoly_SafeBool(dead) == true then return false end
    end
    if type(UnitIsCharmed) == "function" then
        local okC, charmed = pcall(UnitIsCharmed, unit)
        if okC and WR_PaladinForeverHoly_SafeBool(charmed) == true then return false end
    end
    if type(UnitIsConnected) == "function" then
        local okO, online = pcall(UnitIsConnected, unit)
        if okO and WR_PaladinForeverHoly_SafeBool(online) == false then return false end
    end
    if type(UnitIsFriend) == "function" then
        local okF, friend = pcall(UnitIsFriend, "player", unit)
        local fb = okF and WR_PaladinForeverHoly_SafeBool(friend) or nil
        if fb == false then return false end
        if fb == nil and type(UnitCanAttack) == "function" then
            local okA, attack = pcall(UnitCanAttack, "player", unit)
            if okA and WR_PaladinForeverHoly_SafeBool(attack) == true then return false end
        end
    elseif type(UnitCanAttack) == "function" then
        local okA, attack = pcall(UnitCanAttack, "player", unit)
        if okA and WR_PaladinForeverHoly_SafeBool(attack) == true then return false end
    end
    -- 只治疗玩家单位（宠物/图腾不在奶骑职责内）
    if type(UnitIsPlayer) == "function" then
        local okP, isPlayer = pcall(UnitIsPlayer, unit)
        if okP and WR_PaladinForeverHoly_SafeBool(isPlayer) == false then return false end
    end
    if type(WR_UnitRange) == "function" then
        local okR, range = pcall(WR_UnitRange, unit)
        if okR and type(range) == "number" and range > 40 and range < 900 then return false end
    end
    return true
end

-- 治疗模式过滤：1全团 2目标 3预读 4泄蓝 5坦克 6脆皮 7-11一~五队 12-15萨12/34/13/24
function WR_PaladinForeverHoly_ModeAllowed(unit, mode)
    mode = tonumber(mode) or 1
    if mode == 5 then return WR_PaladinForeverHoly_IsTank(unit) end
    if mode == 6 then return not WR_PaladinForeverHoly_IsTank(unit) end
    if mode >= 7 and mode <= 11 then
        return WR_PaladinForeverHoly_GroupId(unit) == (mode - 6)
    end
    if mode >= 12 and mode <= 15 then
        local assign = type(ZWYSDYJ_Unit) == "table" and ZWYSDYJ_Unit or nil
        if not assign then return true end
        local pair = mode - 11
        local a, b
        if pair == 1 then a, b = 1, 2
        elseif pair == 2 then a, b = 3, 4
        elseif pair == 3 then a, b = 1, 3
        else a, b = 2, 4 end
        if not assign[a] or not assign[b] then return false end
        local ok1, same1 = pcall(function() return UnitIsUnit(unit, assign[a]) == true end)
        local ok2, same2 = pcall(function() return UnitIsUnit(unit, assign[b]) == true end)
        return (ok1 and same1 == true) or (ok2 and same2 == true)
    end
    return true
end

local function WR_PaladinForeverHoly_AppendUnit(list, unit)
    if type(unit) ~= "string" or unit == "" then return end
    for i = 1, #list do
        if list[i] == unit then return end
        local ok, same = pcall(function() return UnitIsUnit(list[i], unit) == true end)
        if ok and same == true then return end
    end
    list[#list + 1] = unit
end

function WR_PaladinForeverHoly_HasPriorityDebuff(unit)
    if type(WR_UnitHasPriorityHealthDebuff) ~= "function" then return false end
    local ok, v = pcall(WR_UnitHasPriorityHealthDebuff, unit)
    return ok and v == true
end

-- 选人：优先用 Core 的治疗权重（含优先 Debuff / 坦克 / 队伍模式权重）；
-- 权重不可用或未命中时，退化为本地全团扫描「有效血量最低」。
function WR_PaladinForeverHoly_PickBest(threshold, mode)
    threshold = tonumber(threshold) or 0.85
    mode = tonumber(mode) or WR_PaladinForeverHoly_GetMode()
    local allowFull = (mode == 3 or mode == 4)

    -- 目标模式 / 预读 / 泄蓝：有友善目标优先锁定目标
    if mode == 2 or mode == 3 or mode == 4 then
        if WR_PaladinForeverHoly_ValidHealUnit("target") then
            local hp = WR_PaladinForeverHoly_EffectiveHP("target")
            if type(hp) == "number" and (allowFull or hp < threshold) then
                return "target", hp
            end
        end
    end

    -- ① Core 权重（优先级 Debuff / 坦克 / 脆皮 / 队伍模式已在 WR_GetUnitWeight 内处理）
    if type(WR_GetHealthMaxWeightUnit) == "function" then
        local ok, unit = pcall(WR_GetHealthMaxWeightUnit)
        if ok and type(unit) == "string" and unit ~= "Nothing"
           and WR_PaladinForeverHoly_ValidHealUnit(unit)
           and WR_PaladinForeverHoly_ModeAllowed(unit, mode) then
            local hp = WR_PaladinForeverHoly_EffectiveHP(unit)
            if type(hp) == "number" and (allowFull or hp < threshold) then
                return unit, hp
            end
        end
    end

    -- ② 本地全团扫描
    local list = {}
    WR_PaladinForeverHoly_AppendUnit(list, "focus")
    WR_PaladinForeverHoly_AppendUnit(list, "target")
    WR_PaladinForeverHoly_AppendUnit(list, "player")
    local group = WR_PaladinForeverHoly_GroupUnits()
    for i = 1, #group do WR_PaladinForeverHoly_AppendUnit(list, group[i]) end

    local best, bestHP, bestScore = nil, nil, nil
    for i = 1, #list do
        local unit = list[i]
        if WR_PaladinForeverHoly_ValidHealUnit(unit) and WR_PaladinForeverHoly_ModeAllowed(unit, mode) then
            local hp = WR_PaladinForeverHoly_EffectiveHP(unit)
            if type(hp) == "number" and (allowFull or hp < threshold) then
                local score = hp
                if WR_PaladinForeverHoly_HasPriorityDebuff(unit) then score = score - 0.75 end
                if WR_PaladinForeverHoly_IsTank(unit) then score = score - 0.02 end
                local okSame, isFocus = pcall(function() return UnitIsUnit(unit, "focus") == true end)
                if okSame and isFocus == true then score = score - 0.01 end
                if best == nil or score < bestScore then
                    best, bestHP, bestScore = unit, hp, score
                end
            end
        end
    end
    return best, bestHP
end

function WR_PaladinForeverHoly_LowCount(threshold)
    threshold = threshold or 0.70
    local n = 0
    local units = WR_PaladinForeverHoly_GroupUnits()
    for i = 1, #units do
        local u = units[i]
        if WR_PaladinForeverHoly_ValidHealUnit(u) then
            local hp = WR_PaladinForeverHoly_EffectiveHP(u)
            if type(hp) == "number" and hp < threshold then n = n + 1 end
        end
    end
    return n
end

-- 清洁术可解：中毒 / 疾病 / 魔法；不能解诅咒。
function WR_PaladinForeverHoly_HasDispel(unit)
    if type(unit) ~= "string" or not UnitExists(unit) then return false end
    if WR_PaladinForever_UnitHasDispel ~= nil then
        local ok, hit = pcall(WR_PaladinForever_UnitHasDispel, unit)
        if ok and hit == true then return true end
        if ok and hit == false then return false end
    end
    local cache = type(WR_AuraCache) == "table" and WR_AuraCache[unit] or nil
    local auras = cache and cache.HARMFUL or nil
    if type(auras) == "table" then
        for i = 1, #auras do
            local aura = auras[i]
            local dt = type(aura) == "table" and aura.dispelType or nil
            if type(dt) == "string" then
                local secret = false
                if WR_IsSecretValue ~= nil then
                    local okS, isSecret = pcall(WR_IsSecretValue, dt)
                    secret = okS and isSecret == true
                end
                if not secret then
                    local okL, s = pcall(string.lower, dt)
                    if not okL then s = nil end
                    if s == "poison" or s == "disease" or s == "magic"
                        or dt == "中毒" or dt == "疾病" or dt == "魔法" then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function WR_PaladinForeverHoly_OnCooldown(realName, cd)
    if type(realName) ~= "string" or type(cd) ~= "number" or cd <= 0 then return false end
    if type(WR_PaladinForever_GetLastCastAt) ~= "function" then return false end
    local at = WR_PaladinForever_GetLastCastAt(realName)
    if type(at) ~= "number" then return false end
    return (GetTime() - at) < cd
end

function WR_PaladinForeverHoly_FavorActive()
    local remain = WR_GetUnitBuffTime("player", "神恩术")
    if type(remain) == "number" and remain > 0 then return true end
    local at = WR_PaladinForeverHoly_FavorAt
    if type(at) == "number" and (GetTime() - at) < 10 then return true end
    return false
end

-- 圣光守望标记（友方 Buff / 敌方 Debuff 都查；读不到时按 30 秒本地记账兜底）
function WR_PaladinForeverHoly_VigilOn(unit)
    if type(unit) ~= "string" or not UnitExists(unit) then return false end
    local b = WR_GetUnitBuffTime(unit, "圣光守望")
    if type(b) == "number" and b > 0 then return true end
    local d = WR_GetUnitDebuffTime(unit, "圣光守望")
    if type(d) == "number" and d > 0 then return true end
    local at = WR_PaladinForeverHoly_VigilAt
    if type(at) == "number" and (GetTime() - at) < 30 then return true end
    return false
end

function WR_PaladinForeverHoly_FavorUseful(hp, hlPct, priority)
    if priority and WR_SpellUsable("圣光术", true) then return true end
    if hlPct > 0 and type(hp) == "number" and hp < hlPct / 100 and WR_SpellUsable("圣光术", true) then return true end
    return false
end

-- 圣光闪现是否瞬发（战争艺术 / 客户端读条 0）
function WR_PaladinForeverHoly_FlashInstant()
    local okB, art = pcall(WR_GetUnitBuffTime, "player", "战争艺术")
    if okB and type(art) == "number" and art > 0 then return true end
    if type(WR_GetTrueCastTime) == "function" then
        local ok, t = pcall(WR_GetTrueCastTime, "圣光闪现")
        if ok and tonumber(t) == 0 then return true end
    end
    return false
end

WR_PaladinForeverHoly_LastSample = WR_PaladinForeverHoly_LastSample or nil

function WR_PaladinForeverHoly_ReapOnRise(unit, hp, playerHP, hlPct, flPct, slsPct, sdsPct, focusOK)
    local prev = WR_PaladinForeverHoly_LastSample
    WR_PaladinForeverHoly_LastSample = { unit = unit, hp = hp, php = playerHP }
    if type(prev) ~= "table" then return end
    -- 自身血量回升的收尾不依赖当前治疗单位是否变化（T34/T37 场景）
    if slsPct > 0 and type(prev.php) == "number" and prev.php < slsPct / 100 and playerHP >= slsPct / 100 then
        WR_PaladinForever_HideNow("圣疗术", 48)
    end
    if sdsPct > 0 and type(prev.php) == "number" and prev.php < sdsPct / 100 and playerHP >= sdsPct / 100 then
        WR_PaladinForever_HideNow("圣盾术", 18)
    end
    if prev.unit ~= unit or type(hp) ~= "number" then return end
    if focusOK and unit == "focus" then
        if hlPct > 0 and type(prev.hp) == "number" and prev.hp < hlPct / 100 and hp >= hlPct / 100 then
            WR_PaladinForever_HideNow("圣光术", 110)
            WR_PaladinForever_HideNow("神恩术", 114)
        end
        if flPct > 0 and type(prev.hp) == "number" and prev.hp < flPct / 100 and hp >= flPct / 100 then
            WR_PaladinForever_HideNow("圣光闪现(焦点)", 109)
        end
        if slsPct > 0 and type(prev.hp) == "number" and prev.hp < slsPct / 100 and hp >= slsPct / 100 then
            WR_PaladinForever_HideNow("圣疗术(队友)", 150)
        end
    end
end

-- 自动焦点：恢复「点亮色块 → AHK 按宏 → /focus」链路
WR_PaladinForeverHoly_FocusCalcAt = WR_PaladinForeverHoly_FocusCalcAt or 0
WR_PaladinForeverHoly_FocusDecision = WR_PaladinForeverHoly_FocusDecision or nil

function WR_PaladinForeverHoly_FocusSlot(unit)
    if type(unit) ~= "string" then return nil end
    if unit == "player" then return 192 end
    if unit == "target" then return 147 end
    local p = string.match(unit, "^party(%d)$")
    if p then
        local n = tonumber(p)
        if n and n >= 1 and n <= 4 then return 175 + n end
    end
    local r = string.match(unit, "^raid(%d+)$")
    if r then
        local n = tonumber(r)
        if n and n >= 1 and n <= 25 then return 120 + n end
    end
    return nil
end

-- 自动焦点：候选目标由 PickBest 给出；焦点更急时保持不动。
-- ★ 2026-11-17 修复：以前 candidate == "player" 直接 return false，
--   导致「最该治的是自己」时永远不切焦点，圣光术/闪现只打旧焦点，自己反而没人加。
function WR_PaladinForeverHoly_AutoFocus(candidate, candidateHP, mode)
    if PigSet and PigSet.SS_ZDJD == false then return false end
    if type(candidate) ~= "string" or candidate == "" or candidate == "focus" then return false end

    local okSame, same = pcall(function() return UnitIsUnit(candidate, "focus") == true end)
    if okSame and same == true then return false end

    mode = tonumber(mode) or WR_PaladinForeverHoly_GetMode()
    if WR_PaladinForeverHoly_FocusUsable() then
        local focusAllowed = WR_PaladinForeverHoly_ModeAllowed("focus", mode)
        if focusAllowed then
            local fh = WR_PaladinForeverHoly_EffectiveHP("focus")
            local ch = tonumber(candidateHP) or 1
            if type(fh) == "number" and fh <= ch then
                WR_PaladinForeverHoly_FocusDecision =
                    string.format("保持焦点（%.0f%% 不高于 %s）", fh * 100, tostring(candidate))
                return false
            end
        end
    end

    local slot = WR_PaladinForeverHoly_FocusSlot(candidate)
    if not slot then return false end
    if WR_ColorFrame_Show(slot, "设焦点") then
        WR_PaladinForeverHoly_FocusDecision = string.format("切换 %s（槽 %d，血量 %.0f%%）",
            candidate, slot, (tonumber(candidateHP) or 1) * 100)
        return true
    end
    return false
end

-- 过量停条：SS_GLTC 开启时，在施法尾段（SS_GLTCCK*0.1 秒）若目标有效血量已满，点亮 101 停止施法。
-- 泄蓝模式（SS_ZLMS=4）不受限；优先 Debuff 目标强刷不打断。
function WR_PaladinForeverHoly_Stopcasting()
    if not (PigSet and PigSet.SS_GLTC == true) then return false end
    local mode = WR_PaladinForeverHoly_GetMode()
    if mode == 4 then return false end

    local name = nil
    if type(WR_SafeCastingName) == "function" then
        local ok, v = pcall(WR_SafeCastingName, "player")
        if ok and type(v) == "string" then name = v end
    end
    if name ~= "圣光术" and name ~= "圣光闪现" then return false end

    local unit = WR_PaladinForeverHoly_FocusUsable() and "focus" or "player"
    local hp = WR_PaladinForeverHoly_EffectiveHP(unit)
    if type(hp) ~= "number" or hp < 0.999 then return false end
    if WR_PaladinForeverHoly_HasPriorityDebuff(unit) then return false end

    local total = (name == "圣光术") and 2.5 or 1.5
    local remain = nil
    if type(WR_PaladinForever_DurationCastPercent) == "function" then
        local ok, pct = pcall(WR_PaladinForever_DurationCastPercent, "player")
        if ok and type(pct) == "number" then
            remain = (1 - pct / 100) * total
        end
    end
    if not remain and type(UnitCastingInfo) == "function" then
        local ok, _, _, _, startMS, endMS = pcall(UnitCastingInfo, "player")
        local s = ok and WR_PaladinForeverHoly_SafeNumber(startMS) or nil
        local e = ok and WR_PaladinForeverHoly_SafeNumber(endMS) or nil
        if type(s) == "number" and type(e) == "number" and e > s then
            remain = e / 1000 - GetTime()
        end
    end
    local window = (WR_PaladinForeverHoly_Cfg("SS_GLTCCK", 5)) * 0.1
    if type(remain) == "number" and remain <= window then
        return WR_ColorFrame_Show(101, (name == "圣光术") and "停止圣光" or "停止圣闪") == true
    end
    return false
end

-- ============================================================
-- 主循环
-- ============================================================
function WR_PaladinForeverHoly()
    WR_PaladinForever_ClearStalePrompts(1.0)

    -- 0. 祝福（脱战自动补）
    if type(WR_PaladinBlessing_Auto) == "function" and WR_PaladinBlessing_Auto() then return true end

    -- 1. 采集基础状态
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()

    -- 2. 读条保护 / 过量停条
    local casting = nil
    if type(WR_SafeCastingName) == "function" then
        local okC, v = pcall(WR_SafeCastingName, "player")
        if okC then casting = v end
    end
    if casting then
        if WR_PaladinForeverHoly_Stopcasting() then return true end
        return true
    end

    -- 3. 阈值 / 模式 / 选人
    local hlPct  = WR_PaladinForeverHoly_Cfg("SS_SGS", 60)
    local flPct  = WR_PaladinForeverHoly_Cfg("SS_SGSX", 85)
    local slsPct = WR_PaladinForeverHoly_Cfg("SS_SLS", 69)
    local sdsPct = WR_PaladinForeverHoly_Cfg("SS_SDS", 30)
    local ssPct  = WR_PaladinForeverHoly_Cfg("SS_SSZJ", 54)
    local sgwsPct = WR_PaladinForeverHoly_Cfg("SS_SGWS", 52)
    local qjsMode = WR_PaladinForeverHoly_Cfg("SS_QJS", 2)
    local mode = WR_PaladinForeverHoly_GetMode()
    local preRead = (mode == 3)
    local dumpMana = (mode == 4)

    local pickGate = math.max(hlPct, flPct, slsPct, ssPct, sgwsPct, 1) / 100
    if preRead or dumpMana then pickGate = 1.01 end

    local focusOK = WR_PaladinForeverHoly_FocusUsable()
    local healUnit, healHP = WR_PaladinForeverHoly_PickBest(pickGate, mode)
    if not healUnit and (preRead or dumpMana) then
        if focusOK then
            healUnit = "focus"
            healHP = WR_PaladinForeverHoly_EffectiveHP("focus")
        else
            healUnit = "player"
            healHP = WR_PaladinForeverHoly_EffectiveHP("player")
        end
    end

    WR_PaladinForeverHoly_ReapOnRise(healUnit or (focusOK and "focus" or "player"), healHP or PlayerHP,
        PlayerHP, hlPct, flPct, slsPct, sdsPct, focusOK)

    -- 4. 自身保命优先于自动焦点：自己快死了先开圣盾/圣疗，不把 GCD 花在切焦点上
    if sdsPct > 0 and PlayerHP < sdsPct / 100
       and WR_SpellUsable("圣盾术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣盾术", 300)
       and WR_PaladinForever_ShowSkillCD("圣盾术", 18, 300) then
        return true
    end
    if slsPct > 0 and PlayerHP < slsPct / 100
       and WR_SpellUsable("圣疗术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣疗术", 1200)
       and WR_PaladinForever_ShowSkillCD("圣疗术", 48, 300) then
        return true
    end

    -- 5. 自动焦点（有人要奶才切；当前焦点更急则保持）
    if WR_PaladinForeverHoly_AutoFocus(healUnit, healHP, mode) then return true end

    -- 6. 解析实际施法单位：优先焦点；没焦点时自己（宏 109/110 已带自施兜底）
    local castUnit = nil
    if healUnit == "focus" then
        castUnit = "focus"
    elseif healUnit and WR_PaladinForeverHoly_ValidHealUnit(healUnit) then
        local okSame, same = pcall(function() return UnitIsUnit(healUnit, "focus") == true end)
        if okSame and same == true then
            castUnit = "focus"
        elseif healUnit == "player" then
            castUnit = "player"
        end
    end
    if not castUnit then
        if focusOK then castUnit = "focus" else castUnit = "player" end
    end
    local hp = WR_PaladinForeverHoly_EffectiveHP(castUnit)
    if type(hp) ~= "number" then hp = WR_GetUnitHP(castUnit) end

    -- 8. 焦点圣疗术
    if castUnit == "focus" and slsPct > 0 and hp < slsPct / 100
       and WR_SpellUsable("圣疗术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣疗术", 1200)
       and WR_PaladinForever_ShowSkillCD("圣疗术(队友)", 150, 300) then
        return true
    end

    -- 9. 喝红药
    if type(WR_PaladinHolyUI) == "table" and type(WR_PaladinHolyUI.PotionStep) == "function"
       and WR_PaladinHolyUI.PotionStep() then return true end

    local priority = WR_PaladinForeverHoly_HasPriorityDebuff(castUnit)
    local wantHolyLight = hlPct > 0 and type(hp) == "number"
        and (hp < hlPct / 100 or priority or preRead or dumpMana)
    local wantFlash = flPct > 0 and type(hp) == "number"
        and (hp < flPct / 100 or priority or preRead or dumpMana)

    -- 10. 神恩术（只有圣光术确实要用时才提示）
    if wantHolyLight and not WR_PaladinForeverHoly_FavorActive()
       and WR_PaladinForeverHoly_FavorUseful(hp, hlPct, priority)
       and WR_SpellUsable("神恩术", true)
       and not WR_PaladinForeverHoly_OnCooldown("神恩术", 120)
       and WR_PaladinForever_ShowSkillCD("神恩术", 114, 120) then
        WR_PaladinForeverHoly_FavorAt = GetTime()
        return true
    end

    -- 11. 圣光守望（Light's Vigil）：群疗准备，30 秒标记
    local vigilUp = (castUnit == "focus") and WR_PaladinForeverHoly_VigilOn("focus")
    if castUnit == "focus" and not vigilUp
       and sgwsPct > 0 and hp < sgwsPct / 100
       and WR_PaladinForever_SpellKnown("圣光守望")
       and WR_SpellUsable("圣光守望", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣光守望", 6)
       and WR_PaladinForeverHoly_LowCount(0.70) >= 2
       and WR_PaladinForever_ShowSkillCD("圣光守望", 4, 6) then
        WR_PaladinForeverHoly_VigilAt = GetTime()
        return true
    end

    -- 12. 神圣震击（10 秒 CD，瞬发）
    if castUnit == "focus" and ssPct > 0
       and WR_SpellUsable("神圣震击", true)
       and not WR_PaladinForeverHoly_OnCooldown("神圣震击", 10) then
        local need = vigilUp or priority or (hp < ssPct / 100) or (PlayerMove == true and hp < 0.98)
        if need and WR_PaladinForever_ShowSkillCD("神圣震击", 113, 10) then
            return true
        end
    end

    -- 13. 圣光术（2.5 秒读条；移动中不亮）
    if wantHolyLight and not PlayerMove and PlayerMP > 0.15
       and WR_SpellUsable("圣光术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣光术", 2.5)
       and WR_PaladinForever_ShowSkillCD("圣光术", 110, 2.5) then
        return true
    end

    -- 14. 圣光闪现（1.5 秒读条；移动中仅战争艺术/瞬发例外）
    if wantFlash and (not PlayerMove or WR_PaladinForeverHoly_FlashInstant())
       and PlayerMP > 0.08
       and WR_SpellUsable("圣光闪现", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣光闪现", 1.5)
       and WR_PaladinForever_ShowSkillCD("圣光闪现(焦点)", 109, 1.5) then
        return true
    end

    -- 15. 清洁术（驱散）
    local dispelOff = (PigSet and PigSet.SS_QJS_AUTO == true)
        or (PigSet and PigSet.SS_QJS_ON == false) or (qjsMode == 5)
    local cleanseReady
    if WR_PaladinForever_CanCleanseCast ~= nil then
        cleanseReady = WR_PaladinForever_CanCleanseCast()
    else
        cleanseReady = WR_SpellUsable("清洁术", true)
    end
    if not dispelOff and cleanseReady and not WR_PaladinForeverHoly_OnCooldown("清洁术", 8) then
        if WR_PaladinForeverHoly_HasDispel("player")
           and WR_PaladinForever_ShowSkillCD("清洁术(自己)", 43, 8) then
            return true
        end
        if castUnit == "focus" and WR_PaladinForeverHoly_HasDispel("focus")
           and WR_PaladinForever_ShowSkillCD("清洁术(焦点)", 63, 8) then
            return true
        end
        if qjsMode == 4 and UnitExists("mouseover")
           and WR_PaladinForeverHoly_HasDispel("mouseover")
           and WR_PaladinForever_ShowSkillCD("清洁术(指向)", 59, 8) then
            return true
        end
    end

    -- 16. 圣光誓约（buff 维持）
    if type(WR_PaladinHolyUI) == "table" and type(WR_PaladinHolyUI.OathStep) == "function"
       and WR_PaladinHolyUI.OathStep() then return true end

    -- 17. 圣印 / 审判维持
    if type(WR_PaladinHolyUI) == "table" then
        if type(WR_PaladinHolyUI.SealStep) == "function" and WR_PaladinHolyUI.SealStep() then return true end
        if type(WR_PaladinHolyUI.JudgeStep) == "function" and WR_PaladinHolyUI.JudgeStep() then return true end
    end

    -- 18. 切换目标 / 愤怒之锤 / 驱邪术 / 奉献 / 插入
    if type(WR_PaladinHolyUI) == "table" then
        if type(WR_PaladinHolyUI.TargetSwitchStep) == "function" and WR_PaladinHolyUI.TargetSwitchStep() then return true end
        if type(WR_PaladinHolyUI.HammerStep) == "function" and WR_PaladinHolyUI.HammerStep() then return true end
        if type(WR_PaladinHolyUI.ExorcismStep) == "function" and WR_PaladinHolyUI.ExorcismStep() then return true end
        if type(WR_PaladinHolyUI.ConsecrationStep) == "function" and WR_PaladinHolyUI.ConsecrationStep() then return true end
        if type(WR_PaladinHolyUI.InsertStep) == "function" and WR_PaladinHolyUI.InsertStep() then return true end
    end

    return false
end

-- ============================================================
-- 诊断命令 /mkpalholy
-- ============================================================
SLASH_MKPALHOLY1 = "/mkpalholy"
SlashCmdList["MKPALHOLY"] = function()
    local function spellState(name)
        local known = WR_PaladinForever_SpellKnown(name)
        local usable = WR_SpellUsable(name, true)
        local at = WR_PaladinForever_GetLastCastAt and WR_PaladinForever_GetLastCastAt(name)
        local ago = at and string.format("%.0f秒前", GetTime() - at) or "无记录"
        return string.format("%s(已学=%s 可用=%s 上次=%s)", name, tostring(known), tostring(usable), ago)
    end

    local focusOK = WR_PaladinForeverHoly_FocusUsable()
    local unit = focusOK and "focus" or "player"
    local mode = WR_PaladinForeverHoly_GetMode()
    local pickGate = math.max(WR_PaladinForeverHoly_Cfg("SS_SGS", 60), WR_PaladinForeverHoly_Cfg("SS_SGSX", 85),
        WR_PaladinForeverHoly_Cfg("SS_SLS", 69), WR_PaladinForeverHoly_Cfg("SS_SSZJ", 54),
        WR_PaladinForeverHoly_Cfg("SS_SGWS", 52), 1) / 100
    if mode == 3 or mode == 4 then pickGate = 1.01 end
    local best, bestHP = WR_PaladinForeverHoly_PickBest(pickGate, mode)
    print("|cff00ff00[MKPALHOLY]|r 焦点可用=" .. tostring(focusOK)
        .. " 判定单位=" .. unit
        .. " 血量=" .. string.format("%.0f%%", (WR_GetUnitHP(unit) or 1) * 100)
        .. " 自身=" .. string.format("%.0f%%", (WR_GetUnitHP("player") or 1) * 100)
        .. " 蓝=" .. string.format("%.0f%%", (WR_GetUnitMP("player") or 1) * 100))
    print("|cff00ff00[MKPALHOLY]|r 治疗模式=" .. tostring(mode)
        .. " 选中=" .. tostring(best) .. (best and string.format("（%.0f%%）", (bestHP or 1) * 100) or "")
        .. " 决策=" .. tostring(WR_PaladinForeverHoly_FocusDecision))
    print("|cff00ff00[MKPALHOLY]|r 阈值：圣光术=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SGS", 60))
        .. "% 圣光闪现=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SGSX", 85))
        .. "% 圣疗=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SLS", 69))
        .. "% 圣光守望=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SGWS", 52))
        .. "% 震击=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SSZJ", 54))
        .. "% 喝红药=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_HXY", 90))
        .. "% 清洁模式=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_QJS", 2)))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("圣光术"))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("圣光闪现"))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("神圣震击")
        .. " 神恩激活=" .. tostring(WR_PaladinForeverHoly_FavorActive()))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("圣疗术"))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("清洁术")
        .. " 自身可驱=" .. tostring(WR_PaladinForeverHoly_HasDispel("player"))
        .. " 焦点可驱=" .. tostring(focusOK and WR_PaladinForeverHoly_HasDispel("focus") or false))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("圣光守望")
        .. " 标记=" .. tostring(focusOK and WR_PaladinForeverHoly_VigilOn("focus") or false))
    print("|cff00ff00[MKPALHOLY]|r 圣光誓约目标=" .. tostring(PigSet and PigSet.SS_OATH_TARGET)
        .. " 开关=" .. tostring(PigSet and PigSet.SS_OATH_ON)
        .. " 常驻圣印=" .. tostring(WR_PaladinHolyUI and WR_PaladinHolyUI.MainSeal and select(1, WR_PaladinHolyUI.MainSeal()) or "?"))
    print("|cff00ff00[MKPALHOLY]|r 读条中=" .. tostring(WR_SafeCastingName and WR_SafeCastingName("player") or nil))
end
