-- ============================================================
-- Priest/Priest_Forever_Discipline.lua
-- Priest Forever · Discipline 专精循环（无限 1.60.x / 60级）
-- ------------------------------------------------------------
-- 2026-11-18 按「猪猪 / 彼岸花·无限服 · 戒律页」功能图重做：
--   选择：防ADD（是/否）、治疗模式（全团/目标/预读/坦克/脆皮/一队~五队）
--   拉条：喝红药 30 / 黑暗献祭 30 / 真言术：盾 80 / 苦修 70 /
--         联结治疗 70 / 快速治疗 50 / 强效治疗术 75 / 治疗术 75 /
--         次级治疗术 75 / 恢复 90
--   功能：驱散、暗言术：灭、真言术：韧、心灵之火、惩击
--   插入：能量灌注、神圣新星、治疗祷言（一次性，放完自关）
--   爆发：三个可配置槽位 + 种族爆发
-- 旧 80 级 / 本服不存在技能（痛苦压制、守护之魂、神圣赞美诗、希望圣歌、
-- 治疗之环、愈合祷言、绝望祷言等）全部从戒律循环与面板下线。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "PRIEST" then return end

local PD = {}
WR_PriestForeverPD = PD

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ============================================================
PD.Defaults = {
    -- 选择
    JL_FADD = 1,            -- 防ADD：1=是 2=否
    JL_ZLMS = 1,            -- 治疗模式：1全团 2目标 3预读 4坦克 5脆皮 6~10一~五队
    JL_QS   = 2,            -- 驱散模式：1常规 2优先 3目标 4指向 5禁用
    -- 拉条
    JL_HXY   = 30,          -- 喝红药：血低于 30%
    JL_HZ    = 30,          -- 黑暗献祭：法力低于 30%（自身血量低于35%时不用）
    JL_ZYSD  = 80,          -- 真言术：盾：血低于 80%
    JL_KX    = 70,          -- 苦修：血低于 70%
    JL_LJZL  = 70,          -- 联结治疗：血低于 70%
    JL_KSZL  = 50,          -- 快速治疗：血低于 50%
    JL_QXZLS = 75,          -- 强效治疗术：血低于 75%
    JL_ZLSHU = 75,          -- 治疗术：血低于 75%
    JL_CJZLS = 75,          -- 次级治疗术：血低于 75%
    JL_HF    = 90,          -- 恢复：血低于 90%
    -- 功能
    JL_QS_ON = true,        -- 自动驱散
    JL_AYSHM = false,       -- 暗言术：灭（默认关）
    JL_ZYSR  = true,        -- 真言术：韧
    JL_XLHZ  = true,        -- 心灵之火
    JL_CJ    = true,        -- 惩击
    -- 插入（一次性，默认关）
    JL_CRGNZ  = false,      -- 插入 能量灌注
    JL_CRXX   = false,      -- 插入 神圣新星
    JL_CRZLDY = false,      -- 插入 治疗祷言
    -- 爆发槽位（三个「未设置」）
    JL_BF_S1 = false, JL_BF_S2 = false, JL_BF_S3 = false,
    JL_BF_RACE = true,      -- 种族爆发
}

PD.Migrated = false

local function PD_Num(v, def)
    v = tonumber(v)
    if v == nil then return def end
    return v
end

function PD.Val(key, def)
    return PD_Num(PigSet and PigSet[key], def)
end

function PD.On(key, def)
    local v = PigSet and PigSet[key]
    if v == nil then return def end
    return v == true
end

function PD.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
end

function PD.InitDefaults()
    if type(PigSet) ~= "table" then return end
    if PD.DefaultsDone then return end
    if not PD.Migrated then
        PD.Migrated = true
        -- 旧治疗模式（1自动/2坦克/3脆皮/4目标）→ 新（1全团/2目标/3预读/4坦克/5脆皮/6~10队）
        if PigSet.JL_ZLMS ~= nil then
            local old = tonumber(PigSet.JL_ZLMS)
            if old == 2 then PigSet.JL_ZLMS = 4
            elseif old == 3 then PigSet.JL_ZLMS = 5
            elseif old == 4 then PigSet.JL_ZLMS = 2
            elseif old == 1 then PigSet.JL_ZLMS = 1 end
        end
        -- 旧盾档位 1~20（10%~99% / 积极 / 禁用）→ 新百分比 0~100
        local oldShield = tonumber(PigSet.JL_ZYSD)
        if oldShield ~= nil and oldShield >= 1 and oldShield <= 20 then
            if oldShield <= 9 then PigSet.JL_ZYSD = oldShield * 10
            elseif oldShield <= 18 then PigSet.JL_ZYSD = 90 + (oldShield - 9)
            elseif oldShield == 19 then PigSet.JL_ZYSD = 100
            else PigSet.JL_ZYSD = 0 end
        end
        -- 旧恢复布尔 → 90 / 0
        if type(PigSet.JL_HF) == "boolean" then
            PigSet.JL_HF = PigSet.JL_HF and 90 or 0
        end
        -- 旧「快速治疗/联结治疗/强效治疗术」总开关 → 三个独立拉条
        if type(PigSet.JL_ZL) == "boolean" then
            local on = PigSet.JL_ZL
            if PigSet.JL_KSZL  == nil then PigSet.JL_KSZL  = on and 50 or 0 end
            if PigSet.JL_LJZL  == nil then PigSet.JL_LJZL  = on and 70 or 0 end
            if PigSet.JL_QXZLS == nil then PigSet.JL_QXZLS = on and 75 or 0 end
        end
    end
    for k, v in pairs(PD.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
    PD.DefaultsDone = true
end

-- ============================================================
-- 2. 通用辅助（全部 pcall 包裹，读不到按保守值处理）
-- ============================================================
function PD.SpellAbsent(name)
    return type(WR_Forever_SkillAbsent) == "table" and WR_Forever_SkillAbsent[name] == true
end

function PD.CanCast(spell)
    if PD.SpellAbsent(spell) then return false end
    if type(WR_SpellUsable) ~= "function" then return false end
    local ok, usable = pcall(WR_SpellUsable, spell)
    return ok and usable == true
end

function PD.IsDead(unit)
    if type(UnitExists) ~= "function" then return false end
    local okE, exists = pcall(UnitExists, unit)
    if not okE or exists ~= true then return false end
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, dead = pcall(function() return UnitIsDeadOrGhost(unit) == true end)
        if ok and dead == true then return true end
    end
    return false
end

function PD.IsFriend(unit)
    if type(UnitExists) ~= "function" then return false end
    local okE, exists = pcall(UnitExists, unit)
    if not okE or exists ~= true then return false end
    if type(UnitIsFriend) ~= "function" then return true end
    local ok, friend = pcall(function() return UnitIsFriend("player", unit) == true end)
    return ok and friend == true
end

function PD.HP(unit)
    if type(WR_GetUnitHP) ~= "function" then return 1 end
    local ok, v = pcall(WR_GetUnitHP, unit)
    if ok then return PD_Num(v, 1) end
    return 1
end

function PD.MP(unit)
    if type(WR_GetUnitMP) ~= "function" then return 1 end
    local ok, v = pcall(WR_GetUnitMP, unit)
    if ok then return PD_Num(v, 1) end
    return 1
end

function PD.RangeOf(unit)
    if unit == "player" then return 0 end
    if type(WR_UnitRange) ~= "function" then return nil end
    local ok, r = pcall(WR_UnitRange, unit)
    if ok and type(r) == "number" then return r end
    return nil
end

function PD.InRaid()
    if type(GetNumRaidMembers) ~= "function" then return false end
    local ok, n = pcall(GetNumRaidMembers)
    return ok and type(n) == "number" and n > 0
end

function PD.GroupUnits()
    local units = { "player" }
    if PD.InRaid() then
        local ok, n = pcall(GetNumRaidMembers)
        local count = ok and PD_Num(n, 0) or 0
        for i = 1, math.min(count, 40) do units[#units + 1] = "raid" .. i end
    else
        if type(GetNumPartyMembers) == "function" then
            local ok, n = pcall(GetNumPartyMembers)
            local count = ok and PD_Num(n, 0) or 0
            for i = 1, math.min(count, 4) do units[#units + 1] = "party" .. i end
        end
    end
    return units
end

function PD.IsTank(unit)
    if type(UnitGroupRolesAssigned) == "function" then
        local ok, role = pcall(UnitGroupRolesAssigned, unit)
        if ok and role == "TANK" then return true end
    end
    return false
end

function PD.SubgroupOf(unit)
    if not PD.InRaid() then return 1 end
    if type(UnitInRaid) ~= "function" then return nil end
    local ok, idx = pcall(UnitInRaid, unit)
    if not ok or type(idx) ~= "number" or idx <= 0 then return nil end
    if type(GetRaidRosterInfo) ~= "function" then return nil end
    local ok2, _, _, subgroup = pcall(GetRaidRosterInfo, idx)
    if ok2 and type(subgroup) == "number" then return subgroup end
    return nil
end

-- 治疗模式过滤：1全团 2目标 3预读 4坦克 5脆皮 6~10 一~五队
function PD.ModeAllowed(unit)
    local mode = PD.Val("JL_ZLMS", 1)
    if mode == 1 then return true end
    if mode == 2 or mode == 3 then
        if type(UnitExists) == "function" and UnitExists("target") and PD.IsFriend("target") and not PD.IsDead("target") then
            if unit == "target" then return true end
            if type(UnitIsUnit) == "function" then
                local ok, same = pcall(UnitIsUnit, unit, "target")
                if ok and same == true then return true end
            end
            return false
        end
        return true
    end
    if mode == 4 then return PD.IsTank(unit) end
    if mode == 5 then return not PD.IsTank(unit) end
    if mode >= 6 and mode <= 10 then
        local want = mode - 5
        local sub = PD.SubgroupOf(unit)
        if sub == nil then return true end
        return sub == want
    end
    return true
end

function PD.IsHealable(unit)
    if not PD.IsFriend(unit) or PD.IsDead(unit) then return false end
    local range = PD.RangeOf(unit)
    -- 999 = 读不到（secret/无目标），按未知放行；只有明确 >40 码才排除
    if range ~= nil and range > 40 and range < 999 then return false end
    return PD.ModeAllowed(unit)
end

function PD.LowestBelow(threshold)
    if threshold == nil or threshold <= 0 then return nil end
    local units = PD.GroupUnits()
    -- 目标/预读模式：把当前目标也纳入候选（队伍列表本身不含 target）
    local mode = PD.Val("JL_ZLMS", 1)
    if (mode == 2 or mode == 3) and type(UnitExists) == "function" and UnitExists("target") then
        units[#units + 1] = "target"
    end
    local best, bestHP = nil, threshold
    for _, u in ipairs(units) do
        if PD.IsHealable(u) then
            local hp = PD.HP(u)
            if hp > 0 and hp < bestHP then
                best, bestHP = u, hp
            end
        end
    end
    return best, bestHP
end

function PD.Moving()
    if type(WR_PlayerMove) ~= "function" then return false end
    local ok, moving = pcall(WR_PlayerMove)
    return ok and moving == true
end

function PD.BuffRemain(name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, "player", name)
    if ok then return PD_Num(v, 0) end
    return 0
end

function PD.UnitBuffRemain(unit, name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, unit, name)
    if ok then return PD_Num(v, 0) end
    return 0
end

function PD.HasShield(unit)
    if PD.UnitBuffRemain(unit, "真言术：盾") > 0 then return true end
    if type(WR_GetUnitDebuffTime) == "function" then
        local ok, v = pcall(WR_GetUnitDebuffTime, unit, "虚弱灵魂")
        if ok and PD_Num(v, 0) > 0 then return true end
    end
    return false
end

function PD.HasDispelType(unit, kind)
    if type(WR_UnitDebuffType) ~= "function" then return false end
    local names
    if kind == "Magic" then names = { "Magic", "魔法" }
    elseif kind == "Disease" then names = { "Disease", "疾病" }
    else names = { kind } end
    for _, name in ipairs(names) do
        local ok, hit = pcall(WR_UnitDebuffType, unit, name)
        if ok and hit == true then return true end
    end
    return false
end

-- 焦点是否已经是该单位
function PD.IsFocus(unit)
    if not unit then return false end
    if type(UnitExists) == "function" and UnitExists("focus") and type(UnitIsUnit) == "function" then
        local ok, same = pcall(function() return UnitIsUnit("focus", unit) == true end)
        return ok and same == true
    end
    return false
end

-- 设置焦点：优先走既有 WR_FocusUnit（与 AHK 宏槽一致），失败时手工点槽
function PD.FocusOn(unit, text)
    if not unit or unit == "" then return false end
    if PD.IsFocus(unit) then return true end
    if type(WR_FocusUnit) == "function" then
        local ok, done = pcall(WR_FocusUnit, unit, text or "治疗")
        if ok and done == true then return true end
    end
    local slot
    if unit == "player" then slot = 192
    elseif unit == "target" then slot = 147
    else
        local p = string.match(unit, "^party(%d)$")
        if p then slot = 175 + PD_Num(p, 0) end
        if not slot then
            local r = string.match(unit, "^raid(%d+)$")
            if r then slot = 120 + PD_Num(r, 0) end
        end
    end
    if slot and type(WR_ColorFrame_Show) == "function" then
        local ok, shown = pcall(WR_ColorFrame_Show, slot, (text or "治疗") .. "\n" .. unit)
        return ok and shown == true
    end
    return false
end

function PD.Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) == "function" then
        local ok, shown = pcall(WR_ColorFrame_ShowSkill, spell, slot)
        return ok and shown == true
    end
    if slot and type(WR_ColorFrame_Show) == "function" then
        local ok, shown = pcall(WR_ColorFrame_Show, slot, spell)
        return ok and shown == true
    end
    return false
end

function PD.CastHeal(spell, slot, unit)
    if not unit then return false end
    if not PD.CanCast(spell) then return false end
    -- 本 tick 只负责把焦点切过去；治疗色块下一 tick 再亮（避免判旧焦点/打新焦点）
    if not PD.IsFocus(unit) then
        PD.FocusOn(unit)
        return true   -- 本 tick 只负责设焦点（AHK 下一 tick 才按 /focus）
    end
    return PD.Show(spell, slot)
end

-- 单个治疗步骤：阈值拉条（0=关闭）→ 选最低血 → 焦点施法
function PD.HealStep(spell, slot, key, default, blockMoving, extra)
    local threshold = PD.Val(key, default)
    if threshold <= 0 then return false end
    local unit = PD.LowestBelow(threshold / 100)
    if not unit then return false end
    if blockMoving and PD.Moving() then return false end
    if extra and not extra(unit) then return false end
    return PD.CastHeal(spell, slot, unit)
end

-- ============================================================
-- 3. 基础状态 / 停手门
-- ============================================================
function PD.Base()
    GCD = (type(WR_GetGCD) == "function" and WR_GetGCD("治疗术")) or 0
    PlayerHP = PD.HP("player")
    PlayerMP = PD.MP("player")
    PD.Casting = nil
    PD.Channel = nil
    if type(WR_SafeCastingName) == "function" then
        local ok, v = pcall(WR_SafeCastingName, "player")
        if ok then PD.Casting = v end
    end
    if type(WR_SafeChannelName) == "function" then
        local ok, v = pcall(WR_SafeChannelName, "player")
        if ok then PD.Channel = v end
    end
    PD.InCombat = false
    if type(UnitAffectingCombat) == "function" then
        local ok, v = pcall(UnitAffectingCombat, "player")
        PD.InCombat = ok and v == true
    end
end

function PD.StopGate()
    if PD.Casting or PD.Channel then return true end
    local stop = PD.IsDead("player")
    if not stop and type(IsMounted) == "function" then
        local ok, mounted = pcall(IsMounted)
        if ok and mounted then stop = true end
    end
    if not stop and type(UnitInVehicle) == "function" then
        local ok, v = pcall(UnitInVehicle, "player")
        if ok and v then stop = true end
    end
    if not stop and type(WR_GetUnitBuffTime) == "function" then
        local ok, v = pcall(WR_GetUnitBuffTime, "player", { "喝水", "进食", "饮用", "食物", "饮料", "饮水" }, nil, "NAME")
        if ok and type(v) == "number" and v > 0 then stop = true end
    end
    return stop
end

-- 防ADD：1=是（只在自己战斗中治疗） 2=否（任一队友战斗中即治疗）
function PD.CombatGate()
    if PD.InCombat then return true end
    if PD.Val("JL_FADD", 1) == 1 then return false end
    for _, u in ipairs(PD.GroupUnits()) do
        if type(UnitAffectingCombat) == "function" then
            local ok, v = pcall(UnitAffectingCombat, u)
            if ok and v == true then return true end
        end
    end
    return false
end

-- ============================================================
-- 4. 自保 / 黑暗献祭 / BUFF / 驱散 / 输出
-- ============================================================
function PD.SelfPotion()
    if PD.HP("player") >= PD.Val("JL_HXY", 30) / 100 then return false end
    if type(WR_Use_ZLYS) ~= "function" then return false end
    local ok, can = pcall(WR_Use_ZLYS)
    if ok and can == true and type(WR_ColorFrame_Show) == "function" then
        local ok2, shown = pcall(WR_ColorFrame_Show, "CSF", "治疗药水")
        if ok2 and shown then return true end
    end
    return false
end

-- 黑暗献祭：亡灵牧师种族技能，15 秒扣血换法力；血量高于拉条（安全下限）且法力低于80%时使用
function PD.DarkSacrificeStep()
    if not PD.InCombat then return false end
    local threshold = PD.Val("JL_HZ", 30)
    if threshold <= 0 then return false end
    if PD.HP("player") < threshold / 100 then return false end
    -- 法力高于 80% 不用；UNIT_POWER 可读时取真实比例，读不到（战斗 secret）
    -- 时按 WR_GetUnitMP 的安全口径（满蓝）处理，不在满蓝时白扣血。
    local mpPct = PD.MP("player")
    if type(UnitPower) == "function" and type(UnitPowerMax) == "function" then
        local ok1, cur = pcall(UnitPower, "player", 0)
        local ok2, max = pcall(UnitPowerMax, "player", 0)
        if ok1 and ok2 and type(cur) == "number" and type(max) == "number" and max > 0
           and not (type(WR_IsSecretValue) == "function" and (WR_IsSecretValue(cur) or WR_IsSecretValue(max))) then
            mpPct = cur / max
        end
    end
    if mpPct > 0.80 then return false end
    if not PD.CanCast("黑暗献祭") then return false end
    return PD.Show("黑暗献祭", 197)
end

function PD.BuffStep()
    local now = type(GetTime) == "function" and GetTime() or 0
    if now - (PD.LastBuffAt or -1e9) < 2.0 then return false end
    PD.LastBuffAt = now
    if PD.On("JL_ZYSR", true) and PD.BuffRemain("真言术：韧") <= 0 and PD.CanCast("真言术：韧") then
        if PD.FocusOn("player", "韧") then
            return PD.Show("真言术：韧", 52)
        end
    end
    if PD.On("JL_XLHZ", true) and PD.BuffRemain("心灵之火") <= 0 and PD.CanCast("心灵之火") then
        return PD.Show("心灵之火", 31)
    end
    return false
end

-- 驱散：自己优先，其次队友；魔法用驱散魔法，疾病用驱除疾病
function PD.DispelStep()
    if not PD.On("JL_QS_ON", true) then return false end
    if PD.Val("JL_QS", 2) == 5 then return false end
    local now = type(GetTime) == "function" and GetTime() or 0
    if now - (PD.LastDispelAt or -1e9) < 0.5 then return false end
    -- 自己
    if PD.HasDispelType("player", "Magic") and PD.CanCast("驱散魔法") then
        PD.LastDispelAt = now
        return PD.Show("驱散魔法", 79)
    end
    if PD.HasDispelType("player", "Disease") and PD.CanCast("驱除疾病") then
        if not PD.IsFocus("player") then
            PD.FocusOn("player", "驱病")
            return false
        end
        PD.LastDispelAt = now
        return PD.Show("驱除疾病", 62)
    end
    -- 队友
    for _, u in ipairs(PD.GroupUnits()) do
        if u ~= "player" and PD.IsHealable(u) then
            local magic = PD.HasDispelType(u, "Magic") and PD.CanCast("驱散魔法")
            local disease = (not magic) and PD.HasDispelType(u, "Disease") and PD.CanCast("驱除疾病")
            if magic or disease then
                if not PD.IsFocus(u) then
                    PD.FocusOn(u, "驱散")
                    return false
                end
                PD.LastDispelAt = now
                if magic then return PD.Show("驱散魔法", 63) end
                return PD.Show("驱除疾病", 62)
            end
        end
    end
    return false
end

function PD.OffenseStep()
    if type(UnitExists) ~= "function" or not UnitExists("target") then return false end
    if PD.IsDead("target") then return false end
    if type(UnitCanAttack) == "function" then
        local ok, attack = pcall(UnitCanAttack, "player", "target")
        if not ok or attack ~= true then return false end
    end
    local range = PD.RangeOf("target")
    if range ~= nil and range > 30 then return false end
    if PD.On("JL_AYSHM", false) and PD.CanCast("暗言术：灭") then
        return PD.Show("暗言术：灭", 87)
    end
    if PD.On("JL_CJ", true) and PD.CanCast("惩击") then
        return PD.Show("惩击", 196)
    end
    return false
end

-- ============================================================
-- 5. 插入（一次性，放完自关）
-- ============================================================
PD.Inserts = {
    { var = "JL_CRGNZ",  spell = "能量灌注", slot = 149, needFocus = false },
    { var = "JL_CRXX",   spell = "神圣新星", slot = 49,  needFocus = false },
    { var = "JL_CRZLDY", spell = "治疗祷言", slot = 53,  needFocus = true  },
}

function PD.InsertStep()
    for _, item in ipairs(PD.Inserts) do
        if PD.On(item.var, false) then
            if PD.SpellAbsent(item.spell) then
                PigSet[item.var] = false
                PD.SyncCheckbox(item.var)
                return false
            end
            if not PD.CanCast(item.spell) then return false end
            if item.needFocus then
                local unit = nil
                if PD.IsFriend("focus") and not PD.IsDead("focus") then unit = "focus"
                else unit = PD.LowestBelow(1.01) or "player" end
                if not PD.IsFocus(unit) then
                    PD.FocusOn(unit, item.spell)
                    return false
                end
            end
            if PD.Show(item.spell, item.slot) then
                PigSet[item.var] = false
                PD.SyncCheckbox(item.var)
                return true
            end
            return false
        end
    end
    return false
end

-- ============================================================
-- 6. 爆发：三个槽位 + 种族爆发
-- ============================================================
function PD.BurstSlotValue(i)
    return PigSet and PigSet["JL_BF_SLOT" .. i]
end

function PD.BurstStep()
    for i = 1, 3 do
        if PD.On("JL_BF_S" .. i, false) then
            local name = PD.BurstSlotValue(i)
            if type(name) == "string" and name ~= "" and PD.CanCast(name) then
                local extra = { ["血性狂怒"] = 181, ["狂暴"] = 181, ["狮心"] = 181, ["种族爆发"] = 181 }
                if PD.Show(name, extra[name]) then return true end
            end
        end
    end
    if PD.On("JL_BF_RACE", true) then
        local fn = WR_Forever_GetRacialBursts or WR_Forever_PlayerRacialBursts
        if type(fn) == "function" then
            local ok, bursts = pcall(fn)
            if ok and type(bursts) == "table" then
                for i = 1, #bursts do
                    local name = bursts[i]
                    if type(name) == "string" and PD.CanCast(name) then
                        if PD.Show("种族爆发", 181) then return true end
                        break
                    end
                end
            end
        end
    end
    return false
end

function PD.BurstSetAll(mode)
    if type(PigSet) ~= "table" then return end
    PD.InitDefaults()
    for i = 1, 3 do
        local key = "JL_BF_S" .. i
        if mode == "toggle" then
            PigSet[key] = not PD.On(key, false)
        else
            PigSet[key] = (mode == true)
        end
        PD.SyncCheckbox(key)
    end
    print("|cffFF69B4[MKHelperForever 戒律]|r 爆发槽位："
        .. tostring(mode) .. " → "
        .. tostring(PigSet.JL_BF_S1) .. "/"
        .. tostring(PigSet.JL_BF_S2) .. "/"
        .. tostring(PigSet.JL_BF_S3))
end

PD.BurstChoices = { "未设置", "能量灌注", "神圣新星", "心灵专注", "血性狂怒", "狂暴", "狮心" }

function PD.CycleBurstSlot(i)
    if type(PigSet) ~= "table" then return end
    local key = "JL_BF_SLOT" .. i
    local cur = PigSet[key]
    local idx = 1
    for n, name in ipairs(PD.BurstChoices) do
        if name == cur then idx = n break end
    end
    idx = idx + 1
    if idx > #PD.BurstChoices then
        PigSet[key] = nil
        print("|cffFF69B4[MKHelperForever 戒律]|r 爆发槽位 " .. i .. " = 未设置")
    else
        PigSet[key] = PD.BurstChoices[idx]
        print("|cffFF69B4[MKHelperForever 戒律]|r 爆发槽位 " .. i .. " = " .. PD.BurstChoices[idx])
    end
end

-- ============================================================
-- 7. Pre / Post
-- ============================================================
function PD.Pre()
    if PD.InsertStep() then return true end
    if PD.BurstStep() then return true end
    return false
end

function PD.Post()
    if PD.DispelStep() then return true end
    if PD.OffenseStep() then return true end
    return false
end

-- ============================================================
-- 8. 主循环
-- ============================================================
function WR_PriestForeverDiscipline()
    PD.InitDefaults()
    PD.Base()
    if PD.StopGate() then return true end

    -- 脱战：只维持自身 BUFF；防ADD=是 时不进入治疗
    if not PD.InCombat then
        if PD.BuffStep() then return true end
        if PD.Val("JL_FADD", 1) == 1 then return false end
    end

    if PD.SelfPotion() then return true end
    if PD.DarkSacrificeStep() then return true end

    if not PD.CombatGate() then return false end
    if PD.Pre() then return true end

    -- 驱散「优先」模式：先驱散再治疗
    if PD.Val("JL_QS", 2) == 2 then
        if PD.DispelStep() then return true end
    end

    -- 治疗链：盾 → 苦修 → 联结治疗 → 快速治疗 → 强效治疗术 → 治疗术 → 次级治疗术 → 恢复
    if PD.HealStep("真言术：盾", 59, "JL_ZYSD", 80, false, function(u) return not PD.HasShield(u) end) then return true end
    if PD.HealStep("苦修", 54, "JL_KX", 70, true) then return true end
    if PD.HealStep("联结治疗", 56, "JL_LJZL", 70, true) then return true end
    if PD.HealStep("快速治疗", 57, "JL_KSZL", 50, true) then return true end
    if PD.HealStep("强效治疗术", 77, "JL_QXZLS", 75, true) then return true end
    if PD.HealStep("治疗术", 194, "JL_ZLSHU", 75, true) then return true end
    if PD.HealStep("次级治疗术", 195, "JL_CJZLS", 75, true) then return true end
    if PD.HealStep("恢复", 55, "JL_HF", 90, false, function(u) return PD.UnitBuffRemain(u, "恢复") <= 0 end) then return true end

    if PD.Post() then return true end
    return false
end

-- ============================================================
-- 9. 诊断命令
-- ============================================================
SLASH_MKPDISC1 = "/mkpdisc"
SlashCmdList["MKPDISC"] = function()
    print("|cffFF69B4[MKHelperForever 戒律]|r 全团治疗诊断")
    print("  防ADD JL_FADD=" .. tostring(PD.Val("JL_FADD",1)) .. "（1是/2否）"
        .. "  治疗模式 JL_ZLMS=" .. tostring(PD.Val("JL_ZLMS",1)))
    print("  拉条：喝红药=" .. tostring(PD.Val("JL_HXY",30))
        .. " 黑暗献祭=" .. tostring(PD.Val("JL_HZ",30))
        .. " 盾=" .. tostring(PD.Val("JL_ZYSD",80))
        .. " 苦修=" .. tostring(PD.Val("JL_KX",70))
        .. " 联结=" .. tostring(PD.Val("JL_LJZL",70))
        .. " 快速=" .. tostring(PD.Val("JL_KSZL",50))
        .. " 强效=" .. tostring(PD.Val("JL_QXZLS",75))
        .. " 治疗=" .. tostring(PD.Val("JL_ZLSHU",75))
        .. " 次级=" .. tostring(PD.Val("JL_CJZLS",75))
        .. " 恢复=" .. tostring(PD.Val("JL_HF",90)))
    local unit, hp = PD.LowestBelow(1.01)
    if unit then
        print("  当前最低血 = " .. tostring(unit) .. string.format("（%.0f%%）", (hp or 1) * 100))
    else
        print("  当前最低血 = 无（全团满血或读不到）")
    end
    print("  焦点可用 = " .. tostring(PD.IsFriend("focus") and not PD.IsDead("focus")))
end
