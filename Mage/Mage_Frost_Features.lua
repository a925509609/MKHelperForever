-- ============================================================
-- Mage_Frost_Features.lua
-- 冰法（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 MAGE「冰霜」专精：不写全局战斗状态、不影响奥法/火法与其他职业。
--
-- 按「猪猪 / 彼岸花-无限服 · 冰霜页」截图逐项落地：
--   选择：防ADD
--   拉条：喝红药 30% / 打断 60% / 魔杖回蓝 50% / 奥爆 关闭
--   爆发：种族爆发（全开 / 全关 / 切换）
--   功能：读条引导 / 护甲 / 奥术智慧 / 切换目标 / 驱散 / 寒冰护体
--   插入：冰环 / 烈焰风暴 / 暴风雪 / 魔爆术 / 闪现 / 寒冰屏障 / 寒冰护体
--         （一次性，放完自关）
--
-- 【本服真实技能（Forever 60级冰霜天赋/法术书）】
--   寒冰箭 116（主力读条）/ 冰枪术 1312002（瞬发 8 秒 CD，冻结目标 +300%）/
--   冰锥术（瞬发 10 秒 CD）/ 冰霜新星 865（25 秒 CD）/
--   寒冰屏障 11958（5 分钟 CD）/ 急速冷却 12472（10 分钟 CD）/
--   寒冰护体 11426（30 秒 CD，吸收盾 1 分钟）/ 烈焰风暴 8422 / 暴风雪 8427 /
--   魔爆术 8439 / 闪现术 1953 / 法术反制 2139 / 解除次级诅咒 475 /
--   法术吸取 30449 / 奥术智慧 1461 / 冰甲术 7302 / 魔甲术 6117 / 唤醒 12051。
--   ★ 80级/SoD 特有技能（狂咒/镜像/冰冷血脉/法力宝石/隐身术/深冻/寒冰宝珠/
--     召唤水元素等）本服不存在或不属于冰霜页，本层不再引用。
-- ============================================================

if WR_PlayerClass ~= "MAGE" then return end

WR_MageFrostFeatures = WR_MageFrostFeatures or {}
local HF = WR_MageFrostFeatures

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ------------------------------------------------------------
-- 规则：只补 nil，绝不覆盖用户已有设置。
-- 旧档：
--   FADD_BF（旧防ADD 下拉 1=是 2=否）→ BF_FADD
--   BF_ZDZZ（旧「自动种族」）→ BF_ZZ
--   BF_JCZZ / BF_JCZZ_P / BF_ZDFSTQ → BF_QS / BF_QS_PARTY / BF_QS_SELF / BF_QS_STEAL
--   BF_BFX_CR（旧「插入暴风雪」）→ BF_CRBFX
--   BF_FSFZ（打断滑条）沿用；BF_CRSX（插入闪现）沿用。
--   旧 80 级体系开关（BF_YXS 隐身 / BF_KZ 狂咒 / BF_ZDJX 镜像 / BF_BLXM 冰冷血脉 /
--   BF_ZDBS 法力宝石 / BF_BX 自动冰箱 / BF_JSLQ 自动急冷 / BF_JZMODE 智能AOE /
--   饰品 / 手套 / 炸弹 / 宝宝攻击等）全部下线，不再读取。
-- ============================================================
HF.Defaults = {
    -- 选择 / 拉条
    BF_FADD = 1,                 -- 防ADD：1=是（开） 2=否（关）
    BF_HXY = 30,                 -- 喝红药（血量 %，0=关闭）
    BF_FSFZ = 60,                -- 打断（施法进度 %，0=关闭）
    BF_MZHL = 50,                -- 魔杖回蓝（蓝量 %，0=关闭）
    BF_AOBAO = 0,                -- 奥爆（8码内目标数，0=关闭）

    -- 读条引导（右键小窗；冰霜页截图顺序：炎爆术→灼烧→寒冰箭→霜火之箭→火球术）
    BF_CAST = true,              -- 读条引导总开关
    BF_CAST_PYRO = true,         -- 炎爆术 -火焰
    BF_CAST_SCORCH = false,      -- 灼烧（截图默认不勾）
    BF_CAST_FROSTBOLT = true,    -- 寒冰箭（冰法主力）
    BF_CAST_FROSTFIRE = true,    -- 霜火之箭
    BF_CAST_FIREBALL = true,     -- 火球术

    -- 护甲（右键小窗）
    BF_ARMOR = true,             -- 护甲总开关
    BF_ARMOR_KIND = 1,           -- 1=冰甲术 / 2=魔甲术

    -- 奥术智慧（右键小窗）
    BF_INT = true,               -- 奥术智慧总开关
    BF_INT_SELF = true,          -- 自己
    BF_INT_PARTY = true,         -- 小队

    -- 驱散（右键小窗）
    BF_QS = true,                -- 驱散总开关
    BF_QS_SELF = true,           -- 自己（解除次级诅咒）
    BF_QS_PARTY = true,          -- 小队（解除次级诅咒）
    BF_QS_STEAL = true,          -- 法术偷取

    BF_TAB = true,               -- 切换目标
    BF_HBT = true,               -- 寒冰护体（保持护盾，冰霜页特有功能）

    -- 爆发（截图：种族爆发）
    BF_ZZ = true,                -- 种族爆发

    -- 插入（一次性，放完自关）
    BF_CRBH = false,             -- 冰环（冰霜新星）
    BF_CRLYFB = false,           -- 烈焰风暴
    BF_CRBFX = false,            -- 暴风雪
    BF_CRMB = false,             -- 魔爆术
    BF_CRSX = false,             -- 闪现
    BF_CRBZ = false,             -- 寒冰屏障
    BF_CRHT = false,             -- 寒冰护体
}

HF.Migrated = HF.Migrated or false

function HF.Num(v, d)
    local n = tonumber(v)
    if type(n) == "number" then return n end
    return d
end

function HF.Bool(v, d)
    if v == true then return true end
    if v == false then return false end
    return d
end

function HF.On(var, default)
    if type(PigSet) ~= "table" then return default == true end
    return HF.Bool(PigSet[var], default == true)
end

function HF.Val(var, default)
    if type(PigSet) ~= "table" then return default end
    return HF.Num(PigSet[var], default)
end

function HF.InitDefaults()
    if type(PigSet) ~= "table" then return end

    if not HF.Migrated then
        -- 旧防ADD：FADD_BF 1=是 2=否
        if PigSet.BF_FADD == nil then
            local old = tonumber(PigSet.FADD_BF)
            if old == 2 then PigSet.BF_FADD = 2
            elseif old == 1 then PigSet.BF_FADD = 1 end
        end
        -- 旧「自动种族」→ 新爆发开关
        if PigSet.BF_ZZ == nil and PigSet.BF_ZDZZ ~= nil then
            PigSet.BF_ZZ = (PigSet.BF_ZDZZ == true)
        end
        -- 旧驱散 → 新驱散总开关 + 子项
        if PigSet.BF_JCZZ ~= nil then
            if PigSet.BF_QS == nil then PigSet.BF_QS = (PigSet.BF_JCZZ == true) end
            if PigSet.BF_QS_PARTY == nil then PigSet.BF_QS_PARTY = (PigSet.BF_JCZZ == true) end
        end
        if PigSet.BF_JCZZ_P ~= nil and PigSet.BF_QS_SELF == nil then
            PigSet.BF_QS_SELF = (PigSet.BF_JCZZ_P == true)
        end
        if PigSet.BF_ZDFSTQ ~= nil and PigSet.BF_QS_STEAL == nil then
            PigSet.BF_QS_STEAL = (PigSet.BF_ZDFSTQ == true)
        end
        -- 旧「插入暴风雪」→ 新插入开关
        if PigSet.BF_CRBFX == nil and PigSet.BF_BFX_CR ~= nil then
            PigSet.BF_CRBFX = (PigSet.BF_BFX_CR == true)
        end
        HF.Migrated = true
        PigSet.BF_FROST_MIGRATED = true
    end

    for k, v in pairs(HF.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
end

HF.InitDefaults()

-- ============================================================
-- 2. 通用小工具
-- ============================================================
function HF.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
    if type(WR_SyncFrameCheckboxes) == "function" and WR_ConfigFrame then
        pcall(WR_SyncFrameCheckboxes, WR_ConfigFrame, var)
    end
end

function HF.SpellKnown(name)
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

function HF.CanCast(spell)
    if not HF.SpellKnown(spell) then return false end
    if type(WR_SpellUsable) == "function" then
        local ok, v = pcall(WR_SpellUsable, spell, true)
        if ok then return v == true end
    end
    return true
end

function HF.Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) ~= "function" then return false end
    local ok, v = pcall(WR_ColorFrame_ShowSkill, spell, slot)
    if ok and v == true then
        HF.Shown[spell] = slot
        return true
    end
    return false
end

HF.Shown = HF.Shown or {}

function HF.HideOne(spell)
    local slot = HF.Shown[spell]
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
    HF.Shown[spell] = nil
end

function HF.Sweep()
    for spell in pairs(HF.Shown) do
        HF.HideOne(spell)
    end
end

function HF.UnitHP(unit)
    if type(WR_GetUnitHP) ~= "function" then return nil end
    local ok, v = pcall(WR_GetUnitHP, unit)
    if ok and type(v) == "number" then return v end
    return nil
end

function HF.UnitMP(unit)
    if type(WR_GetUnitMP) ~= "function" then return nil end
    local ok, v = pcall(WR_GetUnitMP, unit)
    if ok and type(v) == "number" then return v end
    return nil
end

function HF.InCombat()
    if type(UnitAffectingCombat) ~= "function" then return false end
    local ok, v = pcall(UnitAffectingCombat, "player")
    return ok and v == true
end

function HF.PlayerMoving()
    if type(WR_PlayerMove) ~= "function" then return false end
    local ok, v = pcall(WR_PlayerMove)
    return ok and v == true
end

function HF.IsMountedOrVehicle()
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

function HF.EatingDrinking()
    if type(WR_GetUnitBuffTime) ~= "function" then return false end
    local names = { "喝水", "进食", "饮用", "进食饮水", "食物", "饮料" }
    for i = 1, #names do
        local ok, v = pcall(WR_GetUnitBuffTime, "player", names[i], nil, "NAME")
        if ok and type(v) == "number" and v > 0 then return true end
    end
    return false
end

function HF.BuffRemain(unit, name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, unit, name)
    if ok then return HF.Num(v, 0) end
    return 0
end

function HF.HasAnyBuff(names)
    for i = 1, #names do
        local ok, v = pcall(WR_GetUnitBuffTime, "player", names[i])
        if ok and type(v) == "number" and v > 0 then return true end
    end
    return false
end

function HF.TargetOK()
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

function HF.IsBossTarget()
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

function HF.GetRacialBursts()
    local fn = WR_Forever_GetRacialBursts or WR_Forever_PlayerRacialBursts
    if type(fn) ~= "function" then return {} end
    local ok, list = pcall(fn)
    if ok and type(list) == "table" then return list end
    return {}
end

-- ============================================================
-- 3. 本地冷却记账（Forever 战斗中客户端 CD 是 secret）
-- ============================================================
HF.CD = {
    ["冰枪术"] = 8,
    ["冰锥术"] = 10,
    ["冰霜新星"] = 25,
    ["寒冰护体"] = 30,
    ["寒冰屏障"] = 300,
    ["闪现术"] = 15,
    ["唤醒"] = 480,
    ["法术反制"] = 30,
    ["烈焰风暴"] = 0,
    ["暴风雪"] = 0,
    ["魔爆术"] = 0,
    ["寒冰箭"] = 0,
    ["火球术"] = 0,
    ["灼烧"] = 0,
    ["霜火之箭"] = 0,
    ["炎爆术"] = 0,
    ["冰甲术"] = 0,
    ["魔甲术"] = 0,
    ["奥术智慧"] = 0,
    ["解除次级诅咒"] = 0,
}

HF.RANK_IDS = {
    ["寒冰箭"] = { 116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304 },
    ["冰枪术"] = { 1312002, 30455 },
    ["冰锥术"] = { 120, 127, 849, 10185, 10186 },
    ["冰霜新星"] = { 122, 865, 6131, 10230 },
    ["寒冰护体"] = { 11426, 13031, 13032, 13033 },
    ["寒冰屏障"] = { 11958 },
    ["炎爆术"] = { 11366, 12505, 12522, 12523, 12524, 12525, 12526, 18809 },
    ["灼烧"] = { 2948, 8444, 8445, 8446, 10205, 10206, 10207 },
    ["霜火之箭"] = { 401502, 1237312, 1237313 },
    ["火球术"] = { 133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151, 25306 },
    ["烈焰风暴"] = { 2120, 2121, 8422, 8423, 10215, 10216 },
    ["暴风雪"] = { 10, 8427, 8431, 10187, 10188 },
    ["魔爆术"] = { 1449, 8438, 8439, 10201, 10202 },
    ["闪现术"] = { 1953 },
    ["奥术智慧"] = { 1459, 1460, 1461, 10156, 10157 },
    ["冰甲术"] = { 7302, 7320, 10220 },
    ["魔甲术"] = { 6117, 22782, 22783 },
    ["唤醒"] = { 12051 },
    ["法术反制"] = { 2139 },
    ["解除次级诅咒"] = { 475 },
}

HF.ID_NAME = HF.ID_NAME or {}
for nm, ids in pairs(HF.RANK_IDS) do
    for i = 1, #ids do HF.ID_NAME[ids[i]] = nm end
end

HF.CastAt = HF.CastAt or {}
HF.CastAtByID = HF.CastAtByID or {}

function HF.StripRankSuffix(nm)
    if type(nm) ~= "string" then return nil end
    local s = string.gsub(nm, "%s*（等级%s*%d+）%s*$", "")
    if s == nm then s = string.gsub(nm, "%s*%(等级%s*%d+%)%s*$", "") end
    return s
end

function HF.NoteCast(spellName, spellID, at)
    local now = at or GetTime()
    local sid = tonumber(spellID)
    if sid and sid > 0 then
        HF.CastAtByID[sid] = now
        local byId = HF.ID_NAME[sid]
        if byId then HF.CastAt[byId] = now end
    end
    local nm = HF.StripRankSuffix(spellName)
    if type(nm) == "string" and nm ~= "" and HF.CD[nm] ~= nil then
        HF.CastAt[nm] = now
    end
end

function HF.LastCastAt(spell)
    local best = HF.CastAt[spell]
    local ids = HF.RANK_IDS[spell]
    if ids then
        for i = 1, #ids do
            local t = HF.CastAtByID[ids[i]]
            if t and (not best or t > best) then best = t end
        end
    end
    return best
end

function HF.ClientCDLeft(spell)
    if type(WR_SpellCooldownInfo) ~= "function" then return nil end
    local sid
    if type(WR_ResolveSpellID) == "function" then
        local ok, v = pcall(WR_ResolveSpellID, spell)
        if ok and type(v) == "number" then sid = v end
    end
    if not sid then
        local ids = HF.RANK_IDS[spell]
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

function HF.Ready(spell)
    local cd = HF.CD[spell]
    if not cd or cd <= 0 then return true end
    local now = GetTime()
    local castAt = HF.LastCastAt(spell)
    if castAt then return (now - castAt) >= cd end
    local clientLeft = HF.ClientCDLeft(spell)
    if clientLeft and clientLeft > 0 then return false end
    return true
end

-- 事件：成功施放 → 记录本地 CD 起点（与奥法/火法同一套做法）
if type(CreateFrame) == "function" then
    local f = CreateFrame("Frame")
    if f and f.RegisterEvent then
        pcall(f.RegisterEvent, f, "UNIT_SPELLCAST_SUCCEEDED")
        if f.SetScript then
            f:SetScript("OnEvent", function(_, event, unit, castGUID, spellID, spellName)
                if unit ~= "player" then return end
                HF.NoteCast(spellName, spellID, GetTime())
            end)
        end
    end
end

-- ============================================================
-- 4. 基础状态 / 停手门 / 防ADD门
-- ============================================================
function HF.Base()
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("寒冰箭")
    PlayerHP = HF.UnitHP("player")
    PlayerMP = HF.UnitMP("player")
    PlayerMove = HF.PlayerMoving()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)
    HF.CasterOK = true
    HF.CastingName = nil
    HF.ChannelName = nil
    if type(WR_SafeCastingName) == "function" then
        local ok, v = pcall(WR_SafeCastingName, "player")
        if ok and type(v) == "string" then HF.CastingName = v end
    elseif type(UnitCastingInfo) == "function" then
        local ok, v = pcall(UnitCastingInfo, "player")
        if ok and type(v) == "string" then HF.CastingName = v end
    end
    if type(WR_SafeChannelName) == "function" then
        local ok, v = pcall(WR_SafeChannelName, "player")
        if ok and type(v) == "string" then HF.ChannelName = v end
    elseif type(UnitChannelInfo) == "function" then
        local ok, v = pcall(UnitChannelInfo, "player")
        if ok and type(v) == "string" then HF.ChannelName = v end
    end
    HF.TargetValid = HF.TargetOK()
    HF.InRange = (type(TargetRange) == "number" and TargetRange <= 35)
    HF.InMelee = (type(TargetRange) == "number" and TargetRange <= 10)
end

function HF.StopGate()
    local stop = false
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, dead = pcall(UnitIsDeadOrGhost, "player")
        if ok and dead == true then stop = true end
    end
    if not stop and HF.IsMountedOrVehicle() then stop = true end
    if not stop and HF.EatingDrinking() then stop = true end
    if stop then HF.Sweep(); return true end
    return false
end

function HF.CombatGate()
    local bossFrameActive = false
    for i = 1, 4 do
        if type(UnitExists) == "function" and UnitExists("boss" .. i) then bossFrameActive = true; break end
    end
    local inBossEncounter = bossFrameActive and (HF.InCombat() or (type(UnitAffectingCombat) == "function" and UnitAffectingCombat("target")))
    if inBossEncounter then return true end
    if not HF.InCombat() then return false end
    local preventAdd = (HF.Val("BF_FADD", 1) == 1)
    if preventAdd then
        return TargetInCombat == true
    end
    return true
end

-- ============================================================
-- 5. 功能段：护甲 / 奥术智慧 / 驱散 / 切换目标 / 喝红药 / 打断 / 寒冰护体
-- ============================================================
function HF.ArmorStep()
    if not HF.On("BF_ARMOR", true) then return false end
    local kind = HF.Val("BF_ARMOR_KIND", 1)
    local spell, slot
    if kind == 2 then spell, slot = "魔甲术", 107 else spell, slot = "冰甲术", 106 end
    if not HF.SpellKnown(spell) then
        if kind == 2 then spell, slot = "冰甲术", 106 else spell, slot = "魔甲术", 107 end
    end
    if not HF.SpellKnown(spell) then return false end
    if HF.BuffRemain("player", spell) == 0 and HF.CanCast(spell) then
        return HF.Show(spell, slot)
    end
    return false
end

HF.FocusParty = nil
HF.FocusUntil = nil
HF.FocusCastAt = nil

function HF.StartFocus(unit, label)
    HF.FocusParty = unit
    HF.FocusUntil = GetTime() + 6
    HF.FocusCastAt = nil
    if type(WR_FocusUnit) == "function" then
        return WR_FocusUnit(unit, label) == true
    end
    return false
end

function HF.FocusFlow(castSpell, castSlot, label)
    if not HF.FocusParty or not HF.FocusUntil then return false end
    local now = GetTime()
    if now >= HF.FocusUntil then
        HF.FocusParty = nil; HF.FocusUntil = nil; HF.FocusCastAt = nil
        return false
    end
    if type(UnitIsUnit) == "function" and UnitIsUnit("focus", HF.FocusParty) then
        if not HF.FocusCastAt then
            HF.FocusCastAt = now
        end
        if now - HF.FocusCastAt <= 2.5 then
            return HF.Show(castSpell, castSlot)
        end
        HF.FocusParty = nil; HF.FocusUntil = nil; HF.FocusCastAt = nil
        return false
    end
    if type(WR_FocusUnit) == "function" then
        return WR_FocusUnit(HF.FocusParty, label) == true
    end
    return false
end

-- 小队里有没有蓝（战士/盗贼等无蓝职业不加）
function HF.UnitHasMana(unit)
    if type(UnitPowerMax) ~= "function" then return true end
    local ok, v = pcall(UnitPowerMax, unit, 0)
    if ok and type(v) == "number" then return v > 0 end
    return true
end

function HF.IntellectRemain(unit)
    local a = HF.BuffRemain(unit, "奥术智慧")
    local b = HF.BuffRemain(unit, "奥术光辉")
    if b > a then return b end
    return a
end

function HF.IntellectStep()
    if not HF.On("BF_INT", true) then return false end
    if HF.InCombat() or HF.IsMountedOrVehicle() or HF.EatingDrinking() then return false end
    if HF.On("BF_INT_SELF", true) and HF.IntellectRemain("player") < 60 and HF.CanCast("奥术智慧") then
        return HF.Show("奥术智慧", 108)
    end
    if not HF.On("BF_INT_PARTY", true) then return false end

    if HF.FocusFlow("奥术智慧(队友)", 109, "奥术智慧") then return true end

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
            if alive and connected and inRange and HF.UnitHasMana(unit) and HF.IntellectRemain(unit) < 60 then
                return HF.StartFocus(unit, "奥术智慧")
            end
        end
    end
    return false
end

function HF.DispelStep()
    if not HF.On("BF_QS", true) then return false end
    local function hasCurse(unit)
        if type(WR_UnitDebuffType) ~= "function" then return false end
        local okC, c = pcall(WR_UnitDebuffType, unit, "Curse")
        local okD, d = pcall(WR_UnitDebuffType, unit, "Disease")
        return (okC and c == true) or (okD and d == true)
    end
    if HF.On("BF_QS_SELF", true) and hasCurse("player") and HF.CanCast("解除次级诅咒") then
        return HF.Show("解除次级诅咒", 112)
    end
    if HF.On("BF_QS_PARTY", true) then
        if HF.FocusFlow("解除次级诅咒(队友)", 113, "解除诅咒") then return true end
        for i = 1, 4 do
            local unit = "party" .. i
            if type(UnitExists) == "function" and UnitExists(unit) and hasCurse(unit) then
                return HF.StartFocus(unit, "解除诅咒")
            end
        end
    end
    if HF.On("BF_QS_STEAL", true) and HF.TargetValid and HF.InRange then
        if type(WR_UnitBuffType) == "function" then
            local ok, v = pcall(WR_UnitBuffType, "target", "Magic")
            if ok and v == true and HF.CanCast("法术吸取") then
                return HF.Show("法术吸取", 43)
            end
        end
    end
    return false
end

HF.LastTab = HF.LastTab or 0

function HF.TargetSwitchStep()
    if not HF.On("BF_TAB", true) then return false end
    if HF.TargetValid then return false end
    if not HF.InCombat() then return false end
    if type(WR_CanTab) == "function" then
        local ok, can = pcall(WR_CanTab)
        if ok and can == false then return false end
    end
    local now = GetTime()
    if now - (HF.LastTab or 0) < 1.0 then return false end
    if HF.Show("切换目标", 40) then
        HF.LastTab = now
        return true
    end
    return false
end

function HF.PotionStep()
    local threshold = HF.Val("BF_HXY", 30)
    if threshold <= 0 then return false end
    if not HF.InCombat() then return false end
    local hp = HF.UnitHP("player")
    if not hp or hp >= threshold / 100 then return false end
    if type(WR_Use_ZLYS) == "function" then
        local ok, can = pcall(WR_Use_ZLYS)
        if not ok or can ~= true then return false end
        return HF.Show("治疗药水", 111)
    end
    return false
end

function HF.InterruptStep()
    if type(WR_ShouldInterrupt) ~= "function" then return false end
    local ok, should = pcall(WR_ShouldInterrupt, "target", "BF_FSFZ")
    if not ok or should ~= true then return false end
    if HF.CanCast("法术反制") then return HF.Show("法术反制", 46) end
    return false
end

-- 寒冰护体：冰霜页特有功能开关。护盾消失就补（30 秒 CD，1 分钟盾）。
function HF.BarrierStep()
    if not HF.On("BF_HBT", true) then return false end
    if not HF.SpellKnown("寒冰护体") then return false end
    if HF.BuffRemain("player", "寒冰护体") == 0 and HF.Ready("寒冰护体") and HF.CanCast("寒冰护体") then
        return HF.Show("寒冰护体", 65)
    end
    return false
end

-- ============================================================
-- 6. 爆发：种族爆发
-- ============================================================
function HF.BurstStep()
    -- ★★★ 2026-11-21 三十五次修复：统一走 WR_Forever_RacialBurstStep 补 CD 维。
    -- 旧实现只问 CanCast（→ WR_SpellUsable），而无限战斗中 GetSpellCooldown 是
    -- secret → GCD 门恒成立 → 3 分钟大招被当成随时可用 → 用了还一直亮。
    if type(WR_Forever_RacialBurstStep) == "function" then
        return WR_Forever_RacialBurstStep(HF.Show, HF.CanCast, 181, HF.On("BF_ZZ", true))
    end
    if HF.On("BF_ZZ", true) then
        local list = HF.GetRacialBursts()
        for i = 1, #list do
            local name = list[i]
            if type(name) == "string" and HF.CanCast(name) then
                return HF.Show("种族爆发", 181)
            end
        end
    end
    return false
end

-- ============================================================
-- 7. 奥爆 / 唤醒 / 读条引导（核心）
-- ============================================================
function HF.AoeStep()
    local need = HF.Val("BF_AOBAO", 0)
    if need <= 0 then return false end
    local count = tonumber(UnitCount8) or 0
    if count >= need and HF.CanCast("魔爆术") then
        return HF.Show("魔爆术", 78)
    end
    return false
end

-- 唤醒：不归「读条引导」总开关管；低蓝时自动提示（8 分钟 CD）
function HF.EvocationStep()
    local mp = HF.UnitMP("player") or 0
    if mp < 0.20 and HF.Ready("唤醒") and HF.CanCast("唤醒") then
        return HF.Show("唤醒", 18)
    end
    return false
end

function HF.CastStep()
    if not HF.On("BF_CAST", true) then
        -- 关掉读条引导：不提示任何读条技能，但低蓝时仍让魔杖兜底；
        -- 同时接管本 tick，阻止 Mage_Forever.lua 的分发器插入保底寒冰箭。
        if HF.TargetValid and HF.InRange then
            local mpOff = HF.UnitMP("player") or 1
            local wandOff = HF.Val("BF_MZHL", 50)
            if wandOff > 0 and mpOff < wandOff / 100 then return false end
            HF.Sweep()
            return true
        end
        return false
    end
    if not HF.TargetValid or not HF.InRange then return false end
    if HF.ChannelName then return true end
    if HF.CastingName then return false end

    -- 移动中：瞬发冰枪术填充（8 秒 CD，冻结目标 +300%），读条技能打不出
    if HF.PlayerMoving() then
        if HF.Ready("冰枪术") and HF.CanCast("冰枪术") then
            return HF.Show("冰枪术", 44)
        end
        return false
    end

    -- 读条组（冰霜页截图顺序）：炎爆术 → 灼烧 → 寒冰箭 → 霜火之箭 → 火球术
    if HF.On("BF_CAST_PYRO", true) and HF.CanCast("炎爆术") then
        return HF.Show("炎爆术", 2)
    end
    if HF.On("BF_CAST_SCORCH", false) and HF.CanCast("灼烧") then
        return HF.Show("灼烧", 7)
    end
    if HF.On("BF_CAST_FROSTBOLT", true) and HF.CanCast("寒冰箭") then
        return HF.Show("寒冰箭", 60)
    end
    if HF.On("BF_CAST_FROSTFIRE", true) and HF.CanCast("霜火之箭") then
        return HF.Show("霜火之箭", 20)
    end
    if HF.On("BF_CAST_FIREBALL", true) and HF.CanCast("火球术") then
        return HF.Show("火球术", 5)
    end

    -- 冰枪术填充：读条技能都放不出（CD/蓝量/取消勾选）或没勾任何读条时
    if HF.Ready("冰枪术") and HF.CanCast("冰枪术") then
        return HF.Show("冰枪术", 44)
    end

    -- 蓝量低于魔杖拉条 → 交给 WandStep（魔杖兜底），不要在这里接管
    local mpNow = HF.UnitMP("player") or 1
    local wandThreshold = HF.Val("BF_MZHL", 50)
    if wandThreshold > 0 and mpNow < wandThreshold / 100 then return false end

    -- 有目标且在射程内，但本 tick 所有技能都放不出：
    -- 清掉残留色块，并接管本 tick，阻止 Mage_Forever.lua 的分发器插入保底寒冰箭。
    HF.Sweep()
    return true
end

-- ============================================================
-- 8. 插入（一次性：放完自动取消勾选）
-- ============================================================
function HF.InsertOnce(var, spell, slot)
    if not HF.On(var, false) then return false end
    if not HF.CanCast(spell) then return false end
    if HF.Show(spell, slot) then
        PigSet[var] = false
        HF.SyncCheckbox(var)
        return true
    end
    return false
end

function HF.InsertStep()
    if HF.InsertOnce("BF_CRBH", "冰霜新星", 11) then return true end
    if HF.InsertOnce("BF_CRLYFB", "烈焰风暴", 23) then return true end
    if HF.InsertOnce("BF_CRBFX", "暴风雪", 26) then return true end
    if HF.InsertOnce("BF_CRMB", "魔爆术", 78) then return true end
    if HF.InsertOnce("BF_CRSX", "闪现术", 31) then return true end
    if HF.InsertOnce("BF_CRBZ", "寒冰屏障", 32) then return true end
    if HF.InsertOnce("BF_CRHT", "寒冰护体", 65) then return true end
    return false
end

-- ============================================================
-- 9. 魔杖兜底
-- ============================================================
function HF.WandStep()
    local threshold = HF.Val("BF_MZHL", 50)
    if threshold <= 0 then return false end
    if not HF.TargetValid or not HF.InRange then return false end
    local mp = HF.UnitMP("player") or 1
    if mp >= threshold / 100 then return false end
    return HF.Show("魔杖", 190)
end

-- ============================================================
-- 10. 主循环
-- ============================================================
function HF.Run()
    HF.InitDefaults()
    HF.Base()
    if HF.StopGate() then return false end
    if HF.InsertStep() then return true end
    if HF.PotionStep() then return true end
    if HF.ArmorStep() then return true end
    if HF.IntellectStep() then return true end
    if HF.TargetSwitchStep() then return true end
    if not HF.CombatGate() then HF.Sweep(); return false end
    if HF.InterruptStep() then return true end
    if HF.DispelStep() then return true end
    if HF.BurstStep() then return true end
    if HF.BarrierStep() then return true end
    if HF.EvocationStep() then return true end
    if HF.AoeStep() then return true end
    if HF.CastStep() then return true end
    if HF.WandStep() then return true end
    HF.Sweep()
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

HF.PopupDefs = {
    BF_CAST = {
        title = "读条引导  功能",
        width = 380,
        desc = "开着时按右键里勾上的技能放读条技能，从上到下就是先后：炎爆术、灼烧、寒冰箭、霜火之箭、火球术（上面的放得出来就轮不到下面的，想打下面的就去掉上面的勾）。\n\n"
            .. "名字后面的灰字 = 要点哪一系的天赋才有，没学会的勾了也放不出来。\n\n"
            .. "移动中自动打瞬发的冰枪术填充。\n\n"
            .. "关掉后右键里的读条技能一个都不放（只剩冰枪术和魔杖）。\n"
            .. "宏：/MAGE_CAST 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "BF_CAST", label = "读条引导", default = true },
            { type = "check", var = "BF_CAST_PYRO", label = "炎爆术 -火焰", default = true },
            { type = "check", var = "BF_CAST_SCORCH", label = "灼烧", default = false },
            { type = "check", var = "BF_CAST_FROSTBOLT", label = "寒冰箭", default = true },
            { type = "check", var = "BF_CAST_FROSTFIRE", label = "霜火之箭", default = true },
            { type = "check", var = "BF_CAST_FIREBALL", label = "火球术", default = true },
        },
    },
    BF_ARMOR = {
        title = "护甲  功能",
        width = 340,
        desc = "开着时，自己身上没有右键里选中的那种甲就自动补上（冰甲术 / 魔甲术 二选一）；战斗内外都补。\n\n"
            .. "关掉后不再自动补甲。\n"
            .. "宏：/MAGE_ARMOR_ON 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "BF_ARMOR", label = "护甲", default = true },
            { type = "radio", var = "BF_ARMOR_KIND", default = 1, perRow = 2, indent = 18,
              options = { { id = 1, name = "冰甲术" }, { id = 2, name = "魔甲术" } } },
        },
    },
    BF_INT = {
        title = "奥术智慧  功能",
        width = 360,
        desc = "开着时，脱战后身上没有奥术智慧、或者剩不到 1 分钟，就自动补上；给谁加在右键里勾，两个可以都勾。\n\n"
            .. "自己：给自己加。\n\n"
            .. "小队：给小队里有蓝的队友加，战士、盗贼这类没蓝的不加；队友离得太远、死了、掉线时先不加他。团队里只管自己这个小队。给队友加时会把焦点切到他，加完切回自己；进了战斗会把焦点清掉。\n\n"
            .. "别人加的奥术智慧、奥术光辉也算有；战斗中、骑着坐骑、吃喝时不补。\n\n"
            .. "关掉后不再自动补奥术智慧。\n"
            .. "宏：/MAGE_INTELLECT 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "BF_INT", label = "奥术智慧", default = true },
            { type = "check", var = "BF_INT_SELF", label = "自己", default = true, indent = 18 },
            { type = "check", var = "BF_INT_PARTY", label = "小队", default = true, indent = 18 },
        },
    },
    BF_QS = {
        title = "驱散  功能",
        width = 340,
        desc = "开着时，自己或小队身上有诅咒/疾病就用解除次级诅咒驱散；目标身上有可偷取的魔法增益时自动法术偷取。\n\n"
            .. "右键可分别关闭「自己」「小队」「法术偷取」。\n"
            .. "宏：/MAGE_QS 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "BF_QS", label = "驱散", default = true },
            { type = "check", var = "BF_QS_SELF", label = "自己", default = true, indent = 18 },
            { type = "check", var = "BF_QS_PARTY", label = "小队", default = true, indent = 18 },
            { type = "check", var = "BF_QS_STEAL", label = "法术偷取", default = true, indent = 18 },
        },
    },
}

local function BuildPopup(key)
    local def = HF.PopupDefs[key]
    if not def then return nil end
    local width = def.width or 360
    local f = CreateFrame("Frame", "WR_MageFrostPopup_" .. key, UIParent, "BackdropTemplate")
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
                HF.SyncCheckbox(rowDef.var)
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
            local val = HF.Num(PigSet[rowDef.var], rowDef.default or 0)
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
                local v = HF.Num(PigSet[rec.row.var], rec.row.default or 0)
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

HF.PopupCache = HF.PopupCache or {}

function HF.ShowOptions(key)
    HF.InitDefaults()
    local def = HF.PopupDefs[key]
    if not def then return end
    local f = HF.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        HF.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(HF.PopupCache) do
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
function HF.SetBurst(on)
    if type(PigSet) ~= "table" then return end
    PigSet.BF_ZZ = on and true or false
    HF.SyncCheckbox("BF_ZZ")
end

function WR_MageFrostBurstAllOn()
    if WR_MageFrostFeatures then WR_MageFrostFeatures.SetBurst(true) end
end

function WR_MageFrostBurstAllOff()
    if WR_MageFrostFeatures then WR_MageFrostFeatures.SetBurst(false) end
end

function WR_MageFrostBurstToggle()
    if not WR_MageFrostFeatures then return end
    WR_MageFrostFeatures.SetBurst(not (PigSet.BF_ZZ == true))
end

-- ============================================================
-- 13. 斜杠命令（截图口径；与奥法/火法共用命令，按专精分流）
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
    HF.SyncCheckbox(var)
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
    bySpec["冰霜"] = function(msg) SetVarByCommand(var, msg, label) end
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

BindSharedCommand("MAGE_CAST", "BF_CAST", "读条引导")
BindSharedCommand("MAGE_ARMOR_ON", "BF_ARMOR", "护甲")
BindSharedCommand("MAGE_INTELLECT", "BF_INT", "奥术智慧")
BindSharedCommand("MAGE_QS", "BF_QS", "驱散")
