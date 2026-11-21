-- ============================================================
-- Mage_Fire_Features.lua
-- 火法（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 MAGE「火焰」专精：不写全局战斗状态、不影响奥术/冰霜与其他职业。
--
-- 按「猪猪 / 彼岸花-无限服 · 火法页」截图逐项落地：
--   选择：防ADD
--   拉条：喝红药 30% / 打断 60% / 魔杖回蓝 50% / 奥爆 关闭
--   爆发：燃烧 / 种族爆发（全开 / 全关 / 切换）
--   功能：读条引导 / 护甲 / 奥术智慧 / 切换目标 / 驱散
--   插入：冰环 / 烈焰风暴 / 暴风雪 / 魔爆术 / 闪现 / 冲击波（一次性，放完自关）
--
-- 【本服真实技能（Forever 60级火焰天赋/法术书）】
--   炎爆术 11366(天赋) / 灼烧 2948 / 霜火之箭 401502 / 火球术 133 /
--   寒冰箭 116 / 燃烧 11129(天赋) / 冲击波 11113(天赋) / 烈焰风暴 8422 /
--   暴风雪 8427 / 魔爆术 8439 / 冰霜新星 865 / 闪现术 1953 / 法术反制 2139 /
--   解除次级诅咒 475 / 法术吸取 30449 / 奥术智慧 1461 / 冰甲术 7302 /
--   魔甲术 6117 / 唤醒 12051。
--   ★ 80级/SoD 特有技能（活动炸弹/镜像/冰冷血脉/法力宝石/法术连击等）
--     本服不存在或不属于火法页，本层不再引用。
-- ============================================================

if WR_PlayerClass ~= "MAGE" then return end

WR_MageFireFeatures = WR_MageFireFeatures or {}
local MF = WR_MageFireFeatures

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ------------------------------------------------------------
-- 规则：只补 nil，绝不覆盖用户已有设置。
-- 旧档：
--   FANG_ADD_HUOFA（旧防ADD）→ HY_FADD
--   HY_HQS（旧「火球OR霜火」）→ HY_CAST_FIREBALL / HY_CAST_FROSTFIRE
--   HY_ZDRS（旧「自动燃烧」）→ HY_ZD_RS
--   HY_JCZZ / HY_JCZZ_P / HY_ZDFSTQ → HY_QS / HY_QS_PARTY / HY_QS_SELF / HY_QS_STEAL
-- ============================================================
MF.Defaults = {
    -- 选择 / 拉条
    HY_FADD = 1,                 -- 防ADD：1=是（开） 2=否（关）
    HY_HXY = 30,                 -- 喝红药（血量 %，0=关闭）
    HY_FSFZ = 60,                -- 打断（施法进度 %，0=关闭）
    HY_MZHL = 50,                -- 魔杖回蓝（蓝量 %，0=关闭）
    HY_AOBAO = 0,                -- 奥爆（8码内目标数，0=关闭）

    -- 读条引导（右键小窗）
    HY_CAST = true,              -- 读条引导总开关
    HY_CAST_PYRO = true,         -- 炎爆术 -火焰
    HY_CAST_SCORCH = false,      -- 灼烧（截图默认不勾）
    HY_CAST_FROSTFIRE = true,    -- 霜火之箭
    HY_CAST_FIREBALL = true,     -- 火球术
    HY_CAST_FROSTBOLT = true,    -- 寒冰箭

    -- 护甲（右键小窗）
    HY_ARMOR = true,             -- 护甲总开关
    HY_ARMOR_KIND = 1,           -- 1=冰甲术 / 2=魔甲术

    -- 奥术智慧（右键小窗）
    HY_INT = true,               -- 奥术智慧总开关
    HY_INT_SELF = true,          -- 自己
    HY_INT_PARTY = true,         -- 小队

    -- 驱散（右键小窗）
    HY_QS = true,                -- 驱散总开关
    HY_QS_SELF = true,           -- 自己（解除次级诅咒）
    HY_QS_PARTY = true,          -- 小队（解除次级诅咒）
    HY_QS_STEAL = true,          -- 法术偷取

    HY_TAB = true,               -- 切换目标

    -- 爆发（截图：燃烧 / 种族爆发）
    HY_ZD_RS = true,             -- 燃烧
    HY_ZDZZ = true,              -- 种族爆发

    -- 插入（一次性，放完自关）
    HY_CRBH = false,             -- 冰环（冰霜新星）
    HY_CRLYFB = false,           -- 烈焰风暴
    HY_CRBFX = false,            -- 暴风雪
    HY_CRMB = false,             -- 魔爆术
    HY_CRSX = false,             -- 闪现
    HY_CRCSB = false,            -- 冲击波
}

MF.Migrated = MF.Migrated or false

function MF.Num(v, d)
    local n = tonumber(v)
    if type(n) == "number" then return n end
    return d
end

function MF.Bool(v, d)
    if v == true then return true end
    if v == false then return false end
    return d
end

function MF.On(var, default)
    if type(PigSet) ~= "table" then return default == true end
    return MF.Bool(PigSet[var], default == true)
end

function MF.Val(var, default)
    if type(PigSet) ~= "table" then return default end
    return MF.Num(PigSet[var], default)
end

function MF.InitDefaults()
    if type(PigSet) ~= "table" then return end

    if not MF.Migrated then
        -- 旧防ADD：FANG_ADD_HUOFA 1=是 2=否
        if PigSet.HY_FADD == nil then
            local old = tonumber(PigSet.FANG_ADD_HUOFA)
            if old == 2 then PigSet.HY_FADD = 2
            elseif old == 1 then PigSet.HY_FADD = 1 end
        end
        -- 旧「火球OR霜火」→ 读条技能勾选（1=火球术 2=霜火箭）
        local hqs = tonumber(PigSet.HY_HQS)
        if hqs ~= nil then
            if hqs == 2 then
                if PigSet.HY_CAST_FROSTFIRE == nil then PigSet.HY_CAST_FROSTFIRE = true end
                if PigSet.HY_CAST_FIREBALL == nil then PigSet.HY_CAST_FIREBALL = false end
            else
                if PigSet.HY_CAST_FIREBALL == nil then PigSet.HY_CAST_FIREBALL = true end
                if PigSet.HY_CAST_FROSTFIRE == nil then PigSet.HY_CAST_FROSTFIRE = false end
            end
        end
        -- 旧「自动燃烧」→ 新爆发开关
        if PigSet.HY_ZDRS ~= nil and PigSet.HY_ZD_RS == nil then
            PigSet.HY_ZD_RS = (PigSet.HY_ZDRS == true)
        end
        -- 旧驱散 → 新驱散总开关 + 子项
        if PigSet.HY_JCZZ ~= nil then
            if PigSet.HY_QS == nil then PigSet.HY_QS = (PigSet.HY_JCZZ == true) end
            if PigSet.HY_QS_PARTY == nil then PigSet.HY_QS_PARTY = (PigSet.HY_JCZZ == true) end
        end
        if PigSet.HY_JCZZ_P ~= nil and PigSet.HY_QS_SELF == nil then
            PigSet.HY_QS_SELF = (PigSet.HY_JCZZ_P == true)
        end
        if PigSet.HY_ZDFSTQ ~= nil and PigSet.HY_QS_STEAL == nil then
            PigSet.HY_QS_STEAL = (PigSet.HY_ZDFSTQ == true)
        end
        MF.Migrated = true
        PigSet.HY_FIRE_MIGRATED = true
    end

    for k, v in pairs(MF.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
end

MF.InitDefaults()

-- ============================================================
-- 2. 通用小工具
-- ============================================================
function MF.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
    if type(WR_SyncFrameCheckboxes) == "function" and WR_ConfigFrame then
        pcall(WR_SyncFrameCheckboxes, WR_ConfigFrame, var)
    end
end

function MF.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, v = pcall(WR_Forever_IsSpellKnown, name)
        if ok and v == true then return true end
    end
    if type(WR_ResolveSpellID) == "function" then
        local ok, sid = pcall(WR_ResolveSpellID, name)
        if ok and sid ~= nil then return true end
    end
    return false
end

function MF.CanCast(spell)
    if not MF.SpellKnown(spell) then return false end
    if type(WR_SpellUsable) == "function" then
        local ok, v = pcall(WR_SpellUsable, spell, true)
        if ok then return v == true end
    end
    return true
end

function MF.Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) ~= "function" then return false end
    local ok, v = pcall(WR_ColorFrame_ShowSkill, spell, slot)
    if ok and v == true then
        MF.Shown[spell] = slot
        return true
    end
    return false
end

MF.Shown = MF.Shown or {}

function MF.HideOne(spell)
    local slot = MF.Shown[spell]
    if not slot then return end
    if type(WR_HideSkillColorSlot) == "function" then
        pcall(WR_HideSkillColorSlot, spell, slot)
    else
        if ColorFrameArrayTopLeft and ColorFrameArrayTopLeft[slot] then
            ColorFrameArrayTopLeft[slot]:Hide()
        end
        if ColorFrameArrayTopRight and ColorFrameArrayTopRight[slot] then
            ColorFrameArrayTopRight[slot]:Hide()
        end
    end
    MF.Shown[spell] = nil
end

function MF.Sweep()
    for spell in pairs(MF.Shown) do
        MF.HideOne(spell)
    end
end

function MF.UnitHP(unit)
    if type(WR_GetUnitHP) ~= "function" then return nil end
    local ok, v = pcall(WR_GetUnitHP, unit)
    if ok and type(v) == "number" then return v end
    return nil
end

function MF.UnitMP(unit)
    if type(WR_GetUnitMP) ~= "function" then return nil end
    local ok, v = pcall(WR_GetUnitMP, unit)
    if ok and type(v) == "number" then return v end
    return nil
end

function MF.InCombat()
    if type(UnitAffectingCombat) ~= "function" then return false end
    local ok, v = pcall(UnitAffectingCombat, "player")
    return ok and v == true
end

function MF.PlayerMoving()
    if type(WR_PlayerMove) ~= "function" then return false end
    local ok, v = pcall(WR_PlayerMove)
    return ok and v == true
end

function MF.IsMountedOrVehicle()
    if type(IsMounted) == "function" then
        local ok, v = pcall(IsMounted)
        if ok and v == true then return true end
    end
    if type(UnitInVehicle) == "function" then
        local ok, v = pcall(UnitInVehicle, "player")
        if ok and v == true then return true end
    end
    return false
end

function MF.EatingDrinking()
    if type(WR_GetUnitBuffTime) ~= "function" then return false end
    local names = { "喝水", "进食", "饮用", "进食饮水", "食物", "饮料" }
    for i = 1, #names do
        local ok, v = pcall(WR_GetUnitBuffTime, "player", names[i], nil, "NAME")
        if ok and type(v) == "number" and v > 0 then return true end
    end
    return false
end

function MF.BuffRemain(unit, name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, unit, name)
    if ok then return MF.Num(v, 0) end
    return 0
end

function MF.HasAnyBuff(names)
    for i = 1, #names do
        local ok, v = pcall(WR_GetUnitBuffTime, "player", names[i])
        if ok and type(v) == "number" and v > 0 then return true end
    end
    return false
end

function MF.TargetOK()
    if type(UnitExists) ~= "function" then return false end
    local okEx, exists = pcall(UnitExists, "target")
    if not okEx or exists ~= true then return false end
    if type(UnitIsDeadOrGhost) == "function" then
        local okG, ghost = pcall(UnitIsDeadOrGhost, "target")
        if okG and ghost == true then return false end
    elseif type(UnitIsDead) == "function" then
        local okD, dead = pcall(UnitIsDead, "target")
        if okD and dead == true then return false end
    end
    if type(UnitCanAttack) == "function" then
        local okA, can = pcall(UnitCanAttack, "player", "target")
        if okA and can == false then return false end
    end
    return true
end

function MF.IsBossTarget()
    if type(UnitExists) ~= "function" then return false end
    for i = 1, 4 do
        local unit = "boss" .. i
        if UnitExists(unit) then
            if type(UnitIsUnit) == "function" then
                local ok, same = pcall(UnitIsUnit, "target", unit)
                if ok and same == true then return true end
            end
        end
    end
    if type(UnitClassification) == "function" then
        local ok, c = pcall(UnitClassification, "target")
        if ok and c == "worldboss" then return true end
    end
    return false
end

function MF.GetRacialBursts()
    local fn = WR_Forever_GetRacialBursts or WR_Forever_PlayerRacialBursts
    if type(fn) ~= "function" then return {} end
    local ok, list = pcall(fn)
    if ok and type(list) == "table" then return list end
    return {}
end

-- ============================================================
-- 3. 本地冷却记账（Forever 战斗中客户端 CD 是 secret）
-- ------------------------------------------------------------
-- 只对「有 CD 且循环需要判断」的技能记账；无 CD 填充技能不记。
-- ============================================================
MF.CD = {
    ["燃烧"] = 180,
    ["冲击波"] = 30,
    ["唤醒"] = 480,
    ["法术反制"] = 30,
    ["冰霜新星"] = 25,
    ["闪现术"] = 15,
    ["烈焰风暴"] = 0,
    ["暴风雪"] = 0,
    ["魔爆术"] = 0,
    ["冰甲术"] = 0,
    ["魔甲术"] = 0,
    ["奥术智慧"] = 0,
    ["解除次级诅咒"] = 0,
}

MF.RANK_IDS = {
    ["炎爆术"] = { 11366, 12505, 12522, 12523, 12524, 12525, 12526, 18809 },
    ["灼烧"] = { 2948, 8444, 8445, 8446, 10205, 10206, 10207 },
    ["霜火之箭"] = { 401502, 1237312, 1237313 },
    ["火球术"] = { 133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151, 25306 },
    ["寒冰箭"] = { 116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304 },
    ["燃烧"] = { 11129 },
    ["冲击波"] = { 11113, 13018, 13019, 13020, 13021 },
    ["奥术智慧"] = { 1459, 1460, 1461, 10156, 10157 },
    ["冰甲术"] = { 7302, 7320, 10220 },
    ["魔甲术"] = { 6117, 22782, 22783 },
    ["唤醒"] = { 12051 },
    ["法术反制"] = { 2139 },
    ["冰霜新星"] = { 122, 865, 6131, 10230 },
    ["闪现术"] = { 1953 },
    ["解除次级诅咒"] = { 475 },
}

MF.ID_NAME = MF.ID_NAME or {}
for nm, ids in pairs(MF.RANK_IDS) do
    for i = 1, #ids do MF.ID_NAME[ids[i]] = nm end
end

MF.CastAt = MF.CastAt or {}
MF.CastAtByID = MF.CastAtByID or {}

function MF.StripRankSuffix(nm)
    if type(nm) ~= "string" then return nil end
    local s = string.gsub(nm, "%s*（等级%s*%d+）%s*$", "")
    if s == nm then s = string.gsub(nm, "%s*%(等级%s*%d+%)%s*$", "") end
    return s
end

function MF.NoteCast(spellName, spellID, at)
    local now = at or GetTime()
    local sid = tonumber(spellID)
    if sid and sid > 0 then
        MF.CastAtByID[sid] = now
        local byId = MF.ID_NAME[sid]
        if byId then MF.CastAt[byId] = now end
    end
    local nm = MF.StripRankSuffix(spellName)
    if type(nm) == "string" and nm ~= "" and MF.CD[nm] ~= nil then
        MF.CastAt[nm] = now
    end
end

function MF.LastCastAt(spell)
    local best = MF.CastAt[spell]
    local ids = MF.RANK_IDS[spell]
    if ids then
        for i = 1, #ids do
            local t = MF.CastAtByID[ids[i]]
            if t and (not best or t > best) then best = t end
        end
    end
    return best
end

function MF.ClientCDLeft(spell)
    if type(WR_SpellCooldownInfo) ~= "function" then return nil end
    local sid
    if type(WR_ResolveSpellID) == "function" then
        local ok, v = pcall(WR_ResolveSpellID, spell)
        if ok and type(v) == "number" then sid = v end
    end
    if not sid then
        local ids = MF.RANK_IDS[spell]
        if ids and #ids > 0 then sid = ids[#ids] end
    end
    if not sid then return nil end
    local ok, start, dur = pcall(WR_SpellCooldownInfo, sid)
    if not ok then return nil end
    if type(start) ~= "number" or type(dur) ~= "number" or dur <= 0 then return nil end
    if type(WR_IsSecretValue) == "function" and (WR_IsSecretValue(start) or WR_IsSecretValue(dur)) then
        return nil
    end
    local left = (start + dur) - GetTime()
    if left > 0 then return left end
    return 0
end

function MF.Ready(spell)
    local cd = MF.CD[spell]
    if not cd or cd <= 0 then return true end
    local now = GetTime()
    local castAt = MF.LastCastAt(spell)
    if castAt then return (now - castAt) >= cd end
    local clientLeft = MF.ClientCDLeft(spell)
    if clientLeft and clientLeft > 0 then return false end
    return true
end

-- 事件：成功施放 → 记录本地 CD 起点（与冰法同一套做法）
if type(CreateFrame) == "function" then
    local f = CreateFrame("Frame")
    if f and f.RegisterEvent then
        pcall(f.RegisterEvent, f, "UNIT_SPELLCAST_SUCCEEDED")
        if f.SetScript then
            f:SetScript("OnEvent", function(_, event, unit, castGUID, spellID, spellName)
                if unit ~= "player" then return end
                MF.NoteCast(spellName, spellID, GetTime())
            end)
        end
    end
end

-- ============================================================
-- 4. 基础状态 / 停手门 / 防ADD门
-- ============================================================
function MF.Base()
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("火球术")
    PlayerHP = MF.UnitHP("player")
    PlayerMP = MF.UnitMP("player")
    PlayerMove = MF.PlayerMoving()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)
    MF.CasterOK = true
    MF.CastingName = nil
    MF.ChannelName = nil
    if type(WR_SafeCastingName) == "function" then
        local ok, v = pcall(WR_SafeCastingName, "player")
        if ok and type(v) == "string" then MF.CastingName = v end
    elseif type(UnitCastingInfo) == "function" then
        local ok, v = pcall(UnitCastingInfo, "player")
        if ok and type(v) == "string" then MF.CastingName = v end
    end
    if type(WR_SafeChannelName) == "function" then
        local ok, v = pcall(WR_SafeChannelName, "player")
        if ok and type(v) == "string" then MF.ChannelName = v end
    elseif type(UnitChannelInfo) == "function" then
        local ok, v = pcall(UnitChannelInfo, "player")
        if ok and type(v) == "string" then MF.ChannelName = v end
    end
    MF.TargetValid = MF.TargetOK()
    MF.InRange = (type(TargetRange) == "number" and TargetRange <= 35)
end

function MF.StopGate()
    local stop = false
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, dead = pcall(UnitIsDeadOrGhost, "player")
        if ok and dead == true then stop = true end
    end
    if not stop and MF.IsMountedOrVehicle() then stop = true end
    if not stop and MF.EatingDrinking() then stop = true end
    if stop then MF.Sweep(); return true end
    return false
end

function MF.CombatGate()
    local bossFrameActive = false
    for i = 1, 4 do
        if type(UnitExists) == "function" and UnitExists("boss" .. i) then bossFrameActive = true; break end
    end
    local inBossEncounter = bossFrameActive and (MF.InCombat() or (type(UnitAffectingCombat) == "function" and UnitAffectingCombat("target")))
    if inBossEncounter then return true end
    if not MF.InCombat() then return false end
    local preventAdd = (MF.Val("HY_FADD", 1) == 1)
    if preventAdd then
        return TargetInCombat == true
    end
    return true
end

-- ============================================================
-- 5. 功能段：护甲 / 奥术智慧 / 驱散 / 切换目标 / 喝红药 / 打断
-- ============================================================
function MF.ArmorStep()
    if not MF.On("HY_ARMOR", true) then return false end
    local kind = MF.Val("HY_ARMOR_KIND", 1)
    local spell, slot
    if kind == 2 then spell, slot = "魔甲术", 107 else spell, slot = "冰甲术", 106 end
    if not MF.SpellKnown(spell) then
        if kind == 2 then spell, slot = "冰甲术", 106 else spell, slot = "魔甲术", 107 end
    end
    if not MF.SpellKnown(spell) then return false end
    if MF.BuffRemain("player", spell) == 0 and MF.CanCast(spell) then
        return MF.Show(spell, slot)
    end
    return false
end

MF.FocusParty = nil
MF.FocusUntil = nil
MF.FocusCastAt = nil

function MF.StartFocus(unit, label)
    MF.FocusParty = unit
    MF.FocusUntil = GetTime() + 6
    MF.FocusCastAt = nil
    if type(WR_FocusUnit) == "function" then
        return WR_FocusUnit(unit, label) == true
    end
    return false
end

function MF.FocusFlow(castSpell, castSlot, label)
    if not MF.FocusParty or not MF.FocusUntil then return false end
    local now = GetTime()
    if now >= MF.FocusUntil then
        MF.FocusParty = nil; MF.FocusUntil = nil; MF.FocusCastAt = nil
        return false
    end
    if type(UnitIsUnit) == "function" and UnitIsUnit("focus", MF.FocusParty) then
        if not MF.FocusCastAt then
            MF.FocusCastAt = now
        end
        if now - MF.FocusCastAt <= 2.5 then
            return MF.Show(castSpell, castSlot)
        end
        MF.FocusParty = nil; MF.FocusUntil = nil; MF.FocusCastAt = nil
        return false
    end
    if type(WR_FocusUnit) == "function" then
        return WR_FocusUnit(MF.FocusParty, label) == true
    end
    return false
end

-- 小队里有没有蓝（战士/盗贼等无蓝职业不加）
function MF.UnitHasMana(unit)
    if type(UnitPowerMax) ~= "function" then return true end
    local ok, v = pcall(UnitPowerMax, unit, 0)
    if ok and type(v) == "number" then return v > 0 end
    return true
end

function MF.IntellectRemain(unit)
    local a = MF.BuffRemain(unit, "奥术智慧")
    local b = MF.BuffRemain(unit, "奥术光辉")
    if b > a then return b end
    return a
end

function MF.IntellectStep()
    if not MF.On("HY_INT", true) then return false end
    if MF.InCombat() or MF.IsMountedOrVehicle() or MF.EatingDrinking() then return false end
    if MF.On("HY_INT_SELF", true) and MF.IntellectRemain("player") < 60 and MF.CanCast("奥术智慧") then
        return MF.Show("奥术智慧", 108)
    end
    if not MF.On("HY_INT_PARTY", true) then return false end

    if MF.FocusFlow("奥术智慧(队友)", 109, "奥术智慧") then return true end

    for i = 1, 4 do
        local unit = "party" .. i
        if type(UnitExists) == "function" and UnitExists(unit) then
            local alive = true
            if type(UnitIsDeadOrGhost) == "function" then
                local ok, dead = pcall(UnitIsDeadOrGhost, unit)
                if ok and dead == true then alive = false end
            end
            local connected = true
            if type(UnitIsConnected) == "function" then
                local ok, c = pcall(UnitIsConnected, unit)
                if ok and c == false then connected = false end
            end
            local inRange = true
            if type(WR_UnitRange) == "function" then
                local ok, r = pcall(WR_UnitRange, unit)
                if ok and type(r) == "number" and r > 30 then inRange = false end
            end
            if alive and connected and inRange and MF.UnitHasMana(unit) and MF.IntellectRemain(unit) < 60 then
                return MF.StartFocus(unit, "奥术智慧")
            end
        end
    end
    return false
end

function MF.DispelStep()
    if not MF.On("HY_QS", true) then return false end
    local function hasCurse(unit)
        if type(WR_UnitDebuffType) ~= "function" then return false end
        local okC, c = pcall(WR_UnitDebuffType, unit, "Curse")
        local okD, d = pcall(WR_UnitDebuffType, unit, "Disease")
        return (okC and c == true) or (okD and d == true)
    end
    if MF.On("HY_QS_SELF", true) and hasCurse("player") and MF.CanCast("解除次级诅咒") then
        return MF.Show("解除次级诅咒", 112)
    end
    if MF.On("HY_QS_PARTY", true) then
        if MF.FocusFlow("解除次级诅咒(队友)", 113, "解除诅咒") then return true end
        for i = 1, 4 do
            local unit = "party" .. i
            if type(UnitExists) == "function" and UnitExists(unit) and hasCurse(unit) then
                return MF.StartFocus(unit, "解除诅咒")
            end
        end
    end
    if MF.On("HY_QS_STEAL", true) and MF.TargetValid and MF.InRange then
        if type(WR_UnitBuffType) == "function" then
            local ok, v = pcall(WR_UnitBuffType, "target", "Magic")
            if ok and v == true and MF.CanCast("法术吸取") then
                return MF.Show("法术吸取", 43)
            end
        end
    end
    return false
end

MF.LastTab = MF.LastTab or 0

function MF.TargetSwitchStep()
    if not MF.On("HY_TAB", true) then return false end
    if MF.TargetValid then return false end
    if not MF.InCombat() then return false end
    if type(WR_CanTab) == "function" then
        local ok, can = pcall(WR_CanTab)
        if ok and can == false then return false end
    end
    local now = GetTime()
    if now - (MF.LastTab or 0) < 1.0 then return false end
    if MF.Show("切换目标", 40) then
        MF.LastTab = now
        return true
    end
    return false
end

function MF.PotionStep()
    local threshold = MF.Val("HY_HXY", 30)
    if threshold <= 0 then return false end
    if not MF.InCombat() then return false end
    local hp = MF.UnitHP("player")
    if not hp or hp >= threshold / 100 then return false end
    if type(WR_Use_ZLYS) == "function" then
        local ok, can = pcall(WR_Use_ZLYS)
        if not ok or can ~= true then return false end
        return MF.Show("治疗药水", 111)
    end
    return false
end

function MF.InterruptStep()
    if type(WR_ShouldInterrupt) ~= "function" then return false end
    local ok, should = pcall(WR_ShouldInterrupt, "target", "HY_FSFZ")
    if not ok or should ~= true then return false end
    if MF.CanCast("法术反制") then return MF.Show("法术反制", 46) end
    return false
end

-- ============================================================
-- 6. 爆发：燃烧 / 种族爆发
-- ============================================================
function MF.BurstStep()
    if MF.On("HY_ZD_RS", true)
       and MF.Ready("燃烧")
       and MF.CanCast("燃烧") then
        return MF.Show("燃烧", 58)
    end
    -- ★★★ 2026-11-21 三十五次修复：统一走 WR_Forever_RacialBurstStep 补 CD 维。
    -- 旧实现只问 CanCast（→ WR_SpellUsable），而无限战斗中 GetSpellCooldown 是
    -- secret → GCD 门恒成立 → 3 分钟大招被当成随时可用 → 用了还一直亮。
    if type(WR_Forever_RacialBurstStep) == "function" then
        return WR_Forever_RacialBurstStep(MF.Show, MF.CanCast, 181, MF.On("HY_ZDZZ", true))
    end
    if MF.On("HY_ZDZZ", true) then
        local list = MF.GetRacialBursts()
        for i = 1, #list do
            local name = list[i]
            if type(name) == "string" and MF.CanCast(name) then
                return MF.Show("种族爆发", 181)
            end
        end
    end
    return false
end

-- ============================================================
-- 7. 奥爆 / 唤醒 / 读条引导（核心）
-- ============================================================
function MF.AoeStep()
    local need = MF.Val("HY_AOBAO", 0)
    if need <= 0 then return false end
    local count = tonumber(UnitCount8) or 0
    if count >= need and MF.CanCast("魔爆术") then
        return MF.Show("魔爆术", 78)
    end
    return false
end

-- 唤醒：不归「读条引导」总开关管；低蓝时自动提示（8 分钟 CD）
function MF.EvocationStep()
    local mp = MF.UnitMP("player") or 0
    if mp < 0.20 and MF.Ready("唤醒") and MF.CanCast("唤醒") then
        return MF.Show("唤醒", 18)
    end
    return false
end

function MF.CastStep()
    if not MF.On("HY_CAST", true) then
        -- 关掉读条引导：不提示任何读条技能，但低蓝时仍让魔杖兜底；
        -- 同时接管本 tick，阻止 Mage_Forever.lua 的分发器插入保底火球术。
        if MF.TargetValid and MF.InRange then
            local mpOff = MF.UnitMP("player") or 1
            local wandOff = MF.Val("HY_MZHL", 50)
            if wandOff > 0 and mpOff < wandOff / 100 then return false end
            MF.Sweep()
            return true
        end
        return false
    end
    if not MF.TargetValid or not MF.InRange then return false end
    if MF.ChannelName then return true end
    if MF.CastingName then return false end
    if MF.PlayerMoving() then return false end

    -- 读条组（从上到下就是先后）：炎爆术 → 灼烧 → 霜火之箭 → 火球术 → 寒冰箭
    if MF.On("HY_CAST_PYRO", true) and MF.CanCast("炎爆术") then
        return MF.Show("炎爆术", 2)
    end
    if MF.On("HY_CAST_SCORCH", false) and MF.CanCast("灼烧") then
        return MF.Show("灼烧", 7)
    end
    if MF.On("HY_CAST_FROSTFIRE", true) and MF.CanCast("霜火之箭") then
        return MF.Show("霜火之箭", 20)
    end
    if MF.On("HY_CAST_FIREBALL", true) and MF.CanCast("火球术") then
        return MF.Show("火球术", 5)
    end
    if MF.On("HY_CAST_FROSTBOLT", true) and MF.CanCast("寒冰箭") then
        return MF.Show("寒冰箭", 60)
    end

    -- 蓝量低于魔杖拉条 → 交给 WandStep（魔杖兜底），不要在这里接管
    local mpNow = MF.UnitMP("player") or 1
    local wandThreshold = MF.Val("HY_MZHL", 50)
    if wandThreshold > 0 and mpNow < wandThreshold / 100 then return false end

    -- 有目标且在射程内，但本 tick 所有技能都放不出（CD/蓝量/全部取消勾选）：
    -- 清掉残留色块，并接管本 tick，阻止 Mage_Forever.lua 的分发器插入保底火球术。
    MF.Sweep()
    return true
end

-- ============================================================
-- 8. 插入（一次性：放完自动取消勾选）
-- ============================================================
function MF.InsertOnce(var, spell, slot)
    if not MF.On(var, false) then return false end
    if not MF.CanCast(spell) then return false end
    if MF.Show(spell, slot) then
        PigSet[var] = false
        MF.SyncCheckbox(var)
        return true
    end
    return false
end

function MF.InsertStep()
    if MF.InsertOnce("HY_CRBH", "冰霜新星", 11) then return true end
    if MF.InsertOnce("HY_CRLYFB", "烈焰风暴", 23) then return true end
    if MF.InsertOnce("HY_CRBFX", "暴风雪", 26) then return true end
    if MF.InsertOnce("HY_CRMB", "魔爆术", 78) then return true end
    if MF.InsertOnce("HY_CRSX", "闪现术", 31) then return true end
    if MF.InsertOnce("HY_CRCSB", "冲击波", 22) then return true end
    return false
end

-- ============================================================
-- 9. 魔杖兜底
-- ============================================================
function MF.WandStep()
    local threshold = MF.Val("HY_MZHL", 50)
    if threshold <= 0 then return false end
    if not MF.TargetValid or not MF.InRange then return false end
    local mp = MF.UnitMP("player") or 1
    if mp >= threshold / 100 then return false end
    return MF.Show("魔杖", 190)
end

-- ============================================================
-- 10. 主循环
-- ============================================================
function MF.Run()
    MF.InitDefaults()
    MF.Base()
    if MF.StopGate() then return false end
    if MF.InsertStep() then return true end
    if MF.PotionStep() then return true end
    if MF.ArmorStep() then return true end
    if MF.IntellectStep() then return true end
    if MF.TargetSwitchStep() then return true end
    if not MF.CombatGate() then MF.Sweep(); return false end
    if MF.InterruptStep() then return true end
    if MF.DispelStep() then return true end
    if MF.BurstStep() then return true end
    if MF.EvocationStep() then return true end
    if MF.AoeStep() then return true end
    if MF.CastStep() then return true end
    if MF.WandStep() then return true end
    MF.Sweep()
    return false
end

-- ============================================================
-- 11. 右键「额外条件」小窗
-- ============================================================
local function MakeFont(parent, text, size, r, g, b, width)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size or 12, "")
    fs:SetTextColor(r or 0.92, g or 0.93, b or 0.95, 1)
    fs:SetText(text or "")
    if width then fs:SetWidth(width); fs:SetJustifyH("LEFT") end
    return fs
end

local function ApplyPopupBackdrop(f)
    if type(WR_UI_ApplyBackdrop) == "function" then
        WR_UI_ApplyBackdrop(f, "panel")
        return
    end
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        f:SetBackdropColor(0.05, 0.05, 0.07, 0.97)
        f:SetBackdropBorderColor(0.55, 0.42, 0.18, 0.95)
    end
end

MF.PopupDefs = {
    HY_CAST = {
        title = "读条引导  功能",
        width = 380,
        desc = "开着时按右键里勾上的技能放读条技能，从上到下就是先后：炎爆术、灼烧、霜火之箭、火球术、寒冰箭（上面的放得出来就轮不到下面的，想打下面的就去掉上面的勾）。\n\n"
            .. "名字后面的灰字 = 要点哪一系的天赋才有，没学会的勾了也放不出来。\n\n"
            .. "关掉后右键里的读条技能一个都不放（只剩瞬发技能和魔杖）。\n"
            .. "宏：/MAGE_CAST 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "HY_CAST", label = "读条引导", default = true },
            { type = "check", var = "HY_CAST_PYRO", label = "炎爆术 -火焰", default = true },
            { type = "check", var = "HY_CAST_SCORCH", label = "灼烧", default = false },
            { type = "check", var = "HY_CAST_FROSTFIRE", label = "霜火之箭", default = true },
            { type = "check", var = "HY_CAST_FIREBALL", label = "火球术", default = true },
            { type = "check", var = "HY_CAST_FROSTBOLT", label = "寒冰箭", default = true },
        },
    },
    HY_ARMOR = {
        title = "护甲  功能",
        width = 340,
        desc = "开着时，自己身上没有右键里选中的那种甲就自动补上（冰甲术 / 魔甲术 二选一）；战斗内外都补。\n\n"
            .. "关掉后不再自动补甲。\n"
            .. "宏：/MAGE_ARMOR_ON 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "HY_ARMOR", label = "护甲", default = true },
            { type = "radio", var = "HY_ARMOR_KIND", default = 1, perRow = 2, indent = 18,
              options = { { id = 1, name = "冰甲术" }, { id = 2, name = "魔甲术" } } },
        },
    },
    HY_INT = {
        title = "奥术智慧  功能",
        width = 360,
        desc = "开着时，脱战后身上没有奥术智慧、或者剩不到 1 分钟，就自动补上；给谁加在右键里勾，两个可以都勾。\n\n"
            .. "自己：给自己加。\n\n"
            .. "小队：给小队里有蓝的队友加，战士、盗贼这类没蓝的不加；队友离得太远、死了、掉线时先不加他。团队里只管自己这个小队。给队友加时会把焦点切到他，加完切回自己；进了战斗会把焦点清掉。\n\n"
            .. "别人加的奥术智慧、奥术光辉也算有；战斗中、骑着坐骑、吃喝时不补。\n\n"
            .. "关掉后不再自动补奥术智慧。\n"
            .. "宏：/MAGE_INTELLECT 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "HY_INT", label = "奥术智慧", default = true },
            { type = "check", var = "HY_INT_SELF", label = "自己", default = true, indent = 18 },
            { type = "check", var = "HY_INT_PARTY", label = "小队", default = true, indent = 18 },
        },
    },
    HY_QS = {
        title = "驱散  功能",
        width = 340,
        desc = "开着时，自己或小队身上有诅咒/疾病就用解除次级诅咒驱散；目标身上有可偷取的魔法增益时自动法术偷取。\n\n"
            .. "右键可分别关闭「自己」「小队」「法术偷取」。\n"
            .. "宏：/MAGE_QS 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "HY_QS", label = "驱散", default = true },
            { type = "check", var = "HY_QS_SELF", label = "自己", default = true, indent = 18 },
            { type = "check", var = "HY_QS_PARTY", label = "小队", default = true, indent = 18 },
            { type = "check", var = "HY_QS_STEAL", label = "法术偷取", default = true, indent = 18 },
        },
    },
}

local function BuildPopup(key)
    local def = MF.PopupDefs[key]
    if not def then return nil end
    local width = def.width or 360
    local f = CreateFrame("Frame", "WR_MageFirePopup_" .. key, UIParent, "BackdropTemplate")
    f:SetSize(width, 120)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    ApplyPopupBackdrop(f)

    local title = MakeFont(f, def.title or "额外条件", 14, 1, 0.82, 0.2)
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -9)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() f:Hide() end)

    local rows = {}
    local y = -34
    local contentWidth = width - 30
    local function addRow(h) y = y - h end

    if def.desc then
        local desc = MakeFont(f, def.desc, 11, 0.78, 0.78, 0.78, contentWidth)
        desc:SetPoint("TOPLEFT", f, "TOPLEFT", 12, y)
        desc:SetSpacing(2)
        local h = 60
        if desc.GetStringHeight then
            local ok, measured = pcall(desc.GetStringHeight, desc)
            if ok and type(measured) == "number" and measured > 0 then h = math.ceil(measured) + 6 end
        end
        addRow(h + 4)
    end

    for _, rowDef in ipairs(def.rows or {}) do
        local indent = rowDef.indent or 0
        if rowDef.type == "header" then
            local h = MakeFont(f, rowDef.text or "", 12, 1, 0.65, 0.2)
            h:SetPoint("TOPLEFT", f, "TOPLEFT", 12 + indent, y - 3)
            addRow(20)
        elseif rowDef.type == "check" then
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + indent, y)
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            cb:SetChecked(PigSet[rowDef.var] == true)
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95)
            label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            cb:SetScript("OnClick", function(self)
                PigSet[rowDef.var] = self:GetChecked() and true or false
                MF.SyncCheckbox(rowDef.var)
            end)
            rows[#rows + 1] = { kind = "check", row = rowDef, control = cb }
            addRow(24)
        elseif rowDef.type == "slider" then
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95, 110)
            label:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + indent, y - 2)
            local slider = CreateFrame("Slider", nil, f)
            slider:SetOrientation("HORIZONTAL")
            slider:SetSize(110, 10)
            slider:SetPoint("LEFT", label, "RIGHT", 8, 0)
            slider:SetMinMaxValues(rowDef.minv or 0, rowDef.maxv or 100)
            slider:SetValueStep(rowDef.step or 1)
            slider:SetObeyStepOnDrag(true)
            slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
            local thumb = slider:GetThumbTexture()
            if thumb then thumb:SetSize(6, 14); thumb:SetVertexColor(0.82, 0.84, 0.87, 1) end
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            local val = MF.Num(PigSet[rowDef.var], rowDef.default or 0)
            slider:SetValue(val)
            local valText = MakeFont(f, tostring(val) .. (rowDef.suffix or ""), 12, 0.62, 0.65, 0.69, 52)
            valText:SetPoint("LEFT", slider, "RIGHT", 8, 0)
            local function update(v)
                v = math.floor((v or 0) + 0.5)
                PigSet[rowDef.var] = v
                valText:SetText(tostring(v) .. (rowDef.suffix or ""))
            end
            update(val)
            slider:SetScript("OnValueChanged", function(self, v) update(v) end)
            rows[#rows + 1] = { kind = "slider", row = rowDef, control = slider, valText = valText }
            addRow(30)
        elseif rowDef.type == "radio" then
            local buttons = {}
            local perRow = rowDef.perRow or 2
            local optCount = #(rowDef.options or {})
            local lineCount = math.ceil(optCount / perRow)
            local startX = 14 + indent
            for i, opt in ipairs(rowDef.options or {}) do
                local col = (i - 1) % perRow
                local line = math.floor((i - 1) / perRow)
                local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
                btn:SetSize(84, 21)
                btn:SetPoint("TOPLEFT", f, "TOPLEFT", startX + col * 88, y - line * 24)
                if btn.SetBackdrop then
                    btn:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8X8",
                        edgeFile = "Interface\\Buttons\\WHITE8X8",
                        edgeSize = 1,
                    })
                end
                if btn.SetBackdropColor then
                    btn:SetBackdropColor(0.12, 0.13, 0.15, 0.9)
                    btn:SetBackdropBorderColor(0.18, 0.20, 0.23, 1)
                end
                local txt = MakeFont(btn, opt.name, 11, 0.85, 0.85, 0.85)
                txt:SetPoint("CENTER", btn, "CENTER", 0, 0)
                btn:SetScript("OnClick", function()
                    PigSet[rowDef.var] = opt.id
                    for _, b in ipairs(buttons) do
                        local on = (tonumber(PigSet[rowDef.var]) == b.id)
                        if b.btn.SetBackdropColor then
                            if on then b.btn:SetBackdropColor(0.35, 0.27, 0.10, 1)
                            else b.btn:SetBackdropColor(0.12, 0.13, 0.15, 0.9) end
                        end
                        b.txt:SetTextColor(on and 1 or 0.65, on and 0.82 or 0.65, on and 0.2 or 0.65)
                    end
                end)
                buttons[#buttons + 1] = { btn = btn, txt = txt, id = opt.id }
            end
            rows[#rows + 1] = { kind = "radio", row = rowDef, buttons = buttons }
            addRow(lineCount * 24 + 6)
        end
    end

    local contentH = math.abs(y) + 12
    f:SetHeight(math.max(100, contentH + 18))
    f.rows = rows
    f.defKey = key

    function f:Refresh()
        for _, rec in ipairs(self.rows or {}) do
            if rec.kind == "check" then
                rec.control:SetChecked(PigSet[rec.row.var] == true)
            elseif rec.kind == "slider" then
                local v = MF.Num(PigSet[rec.row.var], rec.row.default or 0)
                rec.control:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            elseif rec.kind == "radio" then
                local cur = tonumber(PigSet[rec.row.var]) or rec.row.default or 1
                for _, b in ipairs(rec.buttons) do
                    local on = (cur == b.id)
                    if b.btn.SetBackdropColor then
                        if on then b.btn:SetBackdropColor(0.35, 0.27, 0.10, 1)
                        else b.btn:SetBackdropColor(0.12, 0.13, 0.15, 0.9) end
                    end
                    b.txt:SetTextColor(on and 1 or 0.65, on and 0.82 or 0.65, on and 0.2 or 0.65)
                end
            end
        end
    end
    return f
end

MF.PopupCache = MF.PopupCache or {}

function MF.ShowOptions(key)
    MF.InitDefaults()
    local def = MF.PopupDefs[key]
    if not def then return end
    local f = MF.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        MF.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(MF.PopupCache) do
        if other ~= f and other.Hide then other:Hide() end
    end
    f:Refresh()
    local x, y = 0, 0
    if type(GetCursorPosition) == "function" then
        local okX, cx, cy = pcall(GetCursorPosition)
        if okX and type(cx) == "number" and type(cy) == "number" then
            local scale = 1
            if UIParent and UIParent.GetEffectiveScale then
                local okS, s = pcall(UIParent.GetEffectiveScale, UIParent)
                if okS and type(s) == "number" and s > 0 then scale = s end
            end
            x, y = cx / scale, cy / scale
        end
    end
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + 12, y - 12)
    f:Show()
end

-- ============================================================
-- 12. 爆发按钮（全开 / 全关 / 切换）
-- ============================================================
function MF.SetBurst(on)
    if type(PigSet) ~= "table" then return end
    PigSet.HY_ZD_RS = on and true or false
    PigSet.HY_ZDZZ = on and true or false
    MF.SyncCheckbox("HY_ZD_RS")
    MF.SyncCheckbox("HY_ZDZZ")
end

function WR_MageFireBurstAllOn()
    if WR_MageFireFeatures then WR_MageFireFeatures.SetBurst(true) end
end

function WR_MageFireBurstAllOff()
    if WR_MageFireFeatures then WR_MageFireFeatures.SetBurst(false) end
end

function WR_MageFireBurstToggle()
    if not WR_MageFireFeatures then return end
    local any = (PigSet.HY_ZD_RS == true) or (PigSet.HY_ZDZZ == true)
    WR_MageFireFeatures.SetBurst(not any)
end

-- ============================================================
-- 13. 斜杠命令（截图口径；与奥法共用命令，按专精分流）
-- ============================================================
local function SetVarByCommand(var, msg, label)
    msg = string.lower(msg or "")
    if msg == "on" then
        PigSet[var] = true
    elseif msg == "off" then
        PigSet[var] = false
    elseif msg == "" or msg == "toggle" then
        PigSet[var] = not PigSet[var]
    else
        return
    end
    MF.SyncCheckbox(var)
    local status = PigSet[var] and "|cff00ff00已开启|r" or "|cffff0000已关闭|r"
    local text = status .. " [" .. label .. "]"
    if type(WR_PrintToVisible) == "function" then
        pcall(WR_PrintToVisible, text)
    elseif type(print) == "function" then
        print(text)
    end
end

local function BindSharedCommand(cmd, var, label)
    _G["SLASH_" .. cmd .. "1"] = "/" .. cmd
    local registry = _G.WR_MageCommandRegistry
    if type(registry) ~= "table" then registry = {}; _G.WR_MageCommandRegistry = registry end
    local bySpec = registry[cmd]
    if type(bySpec) ~= "table" then bySpec = {}; registry[cmd] = bySpec end
    bySpec["火焰"] = function(msg) SetVarByCommand(var, msg, label) end
    SlashCmdList[cmd] = function(msg)
        local spec = nil
        if type(WR_GetMyTalent) == "function" then
            local ok, v = pcall(WR_GetMyTalent)
            if ok and type(v) == "string" then spec = v end
        end
        local fn = bySpec[spec]
        if type(fn) == "function" then return fn(msg) end
    end
end

BindSharedCommand("MAGE_CAST", "HY_CAST", "读条引导")
BindSharedCommand("MAGE_ARMOR_ON", "HY_ARMOR", "护甲")
BindSharedCommand("MAGE_INTELLECT", "HY_INT", "奥术智慧")
BindSharedCommand("MAGE_QS", "HY_QS", "驱散")
