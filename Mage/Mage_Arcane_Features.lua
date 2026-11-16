-- ============================================================
-- Mage_Arcane_Features.lua
-- 奥法（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 MAGE「奥术」专精：不写全局战斗状态、不影响火焰/冰霜与其他职业。
--
-- 按「猪猪 / 彼岸花-无限服 · 奥法页」截图逐项落地：
--   选择：防ADD
--   拉条：喝红药 30% / 打断 60% / 魔杖回蓝 50% / 奥爆 关闭
--   爆发：奥术强化 / 气定神闲 / 种族爆发（全开 / 全关 / 切换）
--   功能：读条引导 / 护甲 / 奥术智慧 / 切换目标 / 驱散
--   插入：冰环 / 烈焰风暴 / 暴风雪 / 魔爆术 / 闪现（一次性，放完自关）
--
-- 【本服真实技能（Forever 60级奥术天赋/法术书）】
--   奥术冲击（天赋）、奥术愤怒（天赋，3.5秒/6秒CD）、奥术飞弹、
--   寒冰箭、霜火之箭、火球术、奥术智慧、冰甲术、魔甲术、冰霜新星、
--   烈焰风暴、暴风雪、魔爆术、闪现术、法术反制、解除次级诅咒、法术吸取。
--   ★ 80级/SoD 特有技能（奥术弹幕/奥术涌动/法力宝石/镜像等）本服不存在，
--     本层不再引用。
-- ============================================================

if WR_PlayerClass ~= "MAGE" then return end

WR_MageArcaneFeatures = WR_MageArcaneFeatures or {}
local MA = WR_MageArcaneFeatures

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ------------------------------------------------------------
-- 规则：只补 nil，绝不覆盖用户已有设置。
-- 旧档：
--   AF_ASQH（旧「自动奥术强化」）→ AF_ZDASQH
--   AF_JCZZ / AF_JCZZ_P / AF_ZDFSTQ → AF_QS / AF_QS_PARTY / AF_QS_SELF / AF_QS_STEAL
--   AF_CRLYFB / AF_CRSX 等旧插入键保留名称继续可用
-- ============================================================
MA.Defaults = {
    -- 选择 / 拉条
    AF_FADD = 1,                 -- 防ADD：1=是（开） 2=否（关）
    AF_HXY = 30,                 -- 喝红药（血量 %，0=关闭）
    AF_FSFZ = 60,                -- 打断（施法进度 %，0=关闭）
    AF_MZHL = 50,                -- 魔杖回蓝（蓝量 %，0=关闭）
    AF_AOBAO = 0,                -- 奥爆（8码内目标数，0=关闭）

    -- 读条引导（右键小窗）
    AF_CAST = true,              -- 读条引导总开关
    AF_CAST_MODE = 1,            -- 1=叠加 / 2=无脑 / 3=奥术愤怒
    AF_CAST_STACKS = 0,          -- 叠层层数（0=自动按4层）
    AF_CAST_WRATH_STACKS = 4,    -- 愤怒层数（奥术愤怒模式：叠到该层数后转奥术愤怒）
    AF_CAST_MANA = 40,           -- 蓝量（低于该百分比不再使用奥术系主力法术）
    AF_CAST_CLEARCAST = true,    -- 有节能就打（节能施法时优先打奥术冲击）
    AF_CAST_AB = true,           -- 奥术冲击
    AF_CAST_AM = true,           -- 奥术飞弹
    AF_CAST_FROSTBOLT = true,    -- 寒冰箭
    AF_CAST_FROSTFIRE = true,    -- 霜火之箭
    AF_CAST_FIREBALL = true,     -- 火球术

    -- 护甲（右键小窗）
    AF_ARMOR = true,             -- 护甲总开关
    AF_ARMOR_KIND = 1,           -- 1=冰甲术 / 2=魔甲术

    -- 奥术智慧（右键小窗）
    AF_INT = true,               -- 奥术智慧总开关
    AF_INT_SELF = true,          -- 自己
    AF_INT_PARTY = true,         -- 小队

    -- 驱散（右键小窗）
    AF_QS = true,                -- 驱散总开关
    AF_QS_SELF = true,           -- 自己（解除次级诅咒）
    AF_QS_PARTY = true,          -- 小队（解除次级诅咒）
    AF_QS_STEAL = true,          -- 法术偷取

    -- 爆发
    AF_ZDASQH = true,            -- 奥术强化
    AF_ZDQDSX = true,            -- 气定神闲
    AF_ZDZZ = true,              -- 种族爆发

    -- 插入（一次性，放完自关）
    AF_CRBH = false,             -- 冰环（冰霜新星）
    AF_CRLYFB = false,           -- 烈焰风暴
    AF_CRBFX = false,            -- 暴风雪
    AF_CRMB = false,             -- 魔爆术
    AF_CRSX = false,             -- 闪现
}

MA.Migrated = MA.Migrated or false

function MA.Num(v, d)
    local n = tonumber(v)
    if type(n) == "number" then return n end
    return d
end

function MA.Bool(v, d)
    if v == true then return true end
    if v == false then return false end
    return d
end

function MA.On(var, default)
    if type(PigSet) ~= "table" then return default == true end
    return MA.Bool(PigSet[var], default == true)
end

function MA.Val(var, default)
    if type(PigSet) ~= "table" then return default end
    return MA.Num(PigSet[var], default)
end

function MA.InitDefaults()
    if type(PigSet) ~= "table" then return end

    if not MA.Migrated then
        -- 旧「自动奥术强化」→ 新爆发开关
        if PigSet.AF_ASQH ~= nil and PigSet.AF_ZDASQH == nil then
            PigSet.AF_ZDASQH = (PigSet.AF_ASQH == true)
        end
        -- 旧「解除诅咒/法术偷取」→ 新驱散总开关 + 子项
        if PigSet.AF_JCZZ ~= nil then
            if PigSet.AF_QS == nil then PigSet.AF_QS = (PigSet.AF_JCZZ == true) end
            if PigSet.AF_QS_PARTY == nil then PigSet.AF_QS_PARTY = (PigSet.AF_JCZZ == true) end
        end
        if PigSet.AF_JCZZ_P ~= nil and PigSet.AF_QS_SELF == nil then
            PigSet.AF_QS_SELF = (PigSet.AF_JCZZ_P == true)
        end
        if PigSet.AF_ZDFSTQ ~= nil and PigSet.AF_QS_STEAL == nil then
            PigSet.AF_QS_STEAL = (PigSet.AF_ZDFSTQ == true)
        end
        -- 旧「插入」键名兼容：AF_CRSX / AF_CRLYFB 原样保留；其余旧键不再展示。
        MA.Migrated = true
        PigSet.AF_ARCANE_MIGRATED = true
    end

    for k, v in pairs(MA.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
end

MA.InitDefaults()

-- ============================================================
-- 2. 通用小工具
-- ============================================================
function MA.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
    if type(WR_SyncFrameCheckboxes) == "function" and WR_ConfigFrame then
        pcall(WR_SyncFrameCheckboxes, WR_ConfigFrame, var)
    end
end

function MA.SpellKnown(name)
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

function MA.CanCast(spell)
    if not MA.SpellKnown(spell) then return false end
    if type(WR_SpellUsable) == "function" then
        local ok, v = pcall(WR_SpellUsable, spell, true)
        if ok then return v == true end
    end
    return true
end

function MA.Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) ~= "function" then return false end
    local ok, v = pcall(WR_ColorFrame_ShowSkill, spell, slot)
    if ok and v == true then
        MA.Shown[spell] = slot
        return true
    end
    return false
end

MA.Shown = MA.Shown or {}

function MA.HideOne(spell)
    local slot = MA.Shown[spell]
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
    MA.Shown[spell] = nil
end

function MA.Sweep()
    for spell in pairs(MA.Shown) do
        MA.HideOne(spell)
    end
end

function MA.UnitHP(unit)
    if type(WR_GetUnitHP) ~= "function" then return nil end
    local ok, v = pcall(WR_GetUnitHP, unit)
    if ok and type(v) == "number" then return v end
    return nil
end

function MA.UnitMP(unit)
    if type(WR_GetUnitMP) ~= "function" then return nil end
    local ok, v = pcall(WR_GetUnitMP, unit)
    if ok and type(v) == "number" then return v end
    return nil
end

function MA.InCombat()
    if type(UnitAffectingCombat) ~= "function" then return false end
    local ok, v = pcall(UnitAffectingCombat, "player")
    return ok and v == true
end

function MA.PlayerMoving()
    if type(WR_PlayerMove) ~= "function" then return false end
    local ok, v = pcall(WR_PlayerMove)
    return ok and v == true
end

function MA.IsMountedOrVehicle()
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

function MA.EatingDrinking()
    if type(WR_GetUnitBuffTime) ~= "function" then return false end
    local names = { "喝水", "进食", "饮用", "进食饮水", "食物", "饮料" }
    for i = 1, #names do
        local ok, v = pcall(WR_GetUnitBuffTime, "player", names[i], nil, "NAME")
        if ok and type(v) == "number" and v > 0 then return true end
    end
    return false
end

function MA.BuffRemain(unit, name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, unit, name)
    if ok then return MA.Num(v, 0) end
    return 0
end

function MA.HasAnyBuff(names)
    for i = 1, #names do
        local ok, v = pcall(WR_GetUnitBuffTime, "player", names[i])
        if ok and type(v) == "number" and v > 0 then return true end
    end
    return false
end

function MA.TargetOK()
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

function MA.IsBossTarget()
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

function MA.GetRacialBursts()
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
MA.CD = {
    ["奥术愤怒"] = 6,
    ["奥术强化"] = 180,
    ["气定神闲"] = 120,
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

MA.RANK_IDS = {
    ["奥术冲击"] = { 400574, 1239696, 1239697, 1239699, 1239700 },
    ["奥术愤怒"] = { 1326079, 1326080, 1326081, 1326082 },
    ["奥术飞弹"] = { 5143, 5144, 5145, 8416, 8417, 10211, 10212, 25345 },
    ["寒冰箭"] = { 116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304 },
    ["火球术"] = { 133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151, 25306 },
    ["霜火之箭"] = { 44614, 44615, 44616, 44617, 44618, 44619, 44620, 44621 },
    ["奥术智慧"] = { 1459, 1460, 1461, 10156, 10157 },
    ["冰甲术"] = { 7302, 7320, 10220 },
    ["魔甲术"] = { 6117, 22782, 22783 },
    ["奥术强化"] = { 12042 },
    ["气定神闲"] = { 12043 },
    ["唤醒"] = { 12051 },
    ["法术反制"] = { 2139 },
    ["冰霜新星"] = { 122, 865, 6131, 10230 },
    ["闪现术"] = { 1953 },
    ["解除次级诅咒"] = { 475 },
}

MA.ID_NAME = MA.ID_NAME or {}
for nm, ids in pairs(MA.RANK_IDS) do
    for i = 1, #ids do MA.ID_NAME[ids[i]] = nm end
end

MA.CastAt = MA.CastAt or {}
MA.CastAtByID = MA.CastAtByID or {}
-- 奥术冲击层数本地记账（战斗内 aura count 读不到时兜底）
MA.BlastLocalCount = MA.BlastLocalCount or 0
MA.BlastFirstAt = MA.BlastFirstAt

function MA.StripRankSuffix(nm)
    if type(nm) ~= "string" then return nil end
    local s = string.gsub(nm, "%s*（等级%s*%d+）%s*$", "")
    if s == nm then s = string.gsub(nm, "%s*%(等级%s*%d+%)%s*$", "") end
    return s
end

function MA.NoteCast(spellName, spellID, at)
    local now = at or GetTime()
    local sid = tonumber(spellID)
    if sid and sid > 0 then
        MA.CastAtByID[sid] = now
        local byId = MA.ID_NAME[sid]
        if byId then MA.CastAt[byId] = now end
    end
    local nm = MA.StripRankSuffix(spellName)
    if type(nm) == "string" and nm ~= "" and MA.CD[nm] ~= nil then
        MA.CastAt[nm] = now
    end
    -- 奥术冲击：每次成功施放 +1 层，18 秒窗口重新起算；最多 4 层
    local isBlast = (nm == "奥术冲击") or (sid and MA.ID_NAME[sid] == "奥术冲击")
    if isBlast then
        if not MA.BlastFirstAt or (now - MA.BlastFirstAt) > 18 then
            MA.BlastFirstAt = now
            MA.BlastLocalCount = 1
        else
            MA.BlastLocalCount = math.min(4, (MA.BlastLocalCount or 0) + 1)
        end
    end
end

function MA.LastCastAt(spell)
    local best = MA.CastAt[spell]
    local ids = MA.RANK_IDS[spell]
    if ids then
        for i = 1, #ids do
            local t = MA.CastAtByID[ids[i]]
            if t and (not best or t > best) then best = t end
        end
    end
    return best
end

function MA.ClientCDLeft(spell)
    if type(WR_SpellCooldownInfo) ~= "function" then return nil end
    local sid
    if type(WR_ResolveSpellID) == "function" then
        local ok, v = pcall(WR_ResolveSpellID, spell)
        if ok and type(v) == "number" then sid = v end
    end
    if not sid then
        local ids = MA.RANK_IDS[spell]
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

function MA.Ready(spell)
    local cd = MA.CD[spell]
    if not cd or cd <= 0 then return true end
    local now = GetTime()
    local castAt = MA.LastCastAt(spell)
    if castAt then return (now - castAt) >= cd end
    local clientLeft = MA.ClientCDLeft(spell)
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
                MA.NoteCast(spellName, spellID, GetTime())
            end)
        end
    end
end

-- ============================================================
-- 4. 奥术冲击层数 / 节能施法
-- ============================================================
MA.ARCANE_BLAST_BUFFS = { "奥术冲击", "奥术冲击效果", "奥术能量" }
MA.CLEARCAST_BUFFS = { "节能施法", "节能施法状态", "Clearcasting" }
MA.MISSILE_BARRAGE_BUFFS = { "飞弹连射", "奥术飞弹速射", "Missile Barrage" }

function MA.ArcaneBlastStacks()
    local best = 0
    if type(WR_GetUnitBuffCount) == "function" then
        for i = 1, #MA.ARCANE_BLAST_BUFFS do
            local ok, v = pcall(WR_GetUnitBuffCount, "player", MA.ARCANE_BLAST_BUFFS[i])
            if ok and type(v) == "number" and v > best then best = v end
        end
    end
    -- 本地记账只在 18 秒窗口内有效
    if MA.BlastFirstAt and (GetTime() - MA.BlastFirstAt) <= 18 then
        local localCount = MA.BlastLocalCount or 0
        if localCount > best then best = localCount end
    end
    return best
end

function MA.ArcaneBlastRemain()
    for i = 1, #MA.ARCANE_BLAST_BUFFS do
        local v = MA.BuffRemain("player", MA.ARCANE_BLAST_BUFFS[i])
        if v > 0 then return v end
    end
    if MA.BlastFirstAt and (GetTime() - MA.BlastFirstAt) <= 18 then
        return 18 - (GetTime() - MA.BlastFirstAt)
    end
    return 0
end

-- ============================================================
-- 5. 基础状态 / 停手门 / 防ADD门
-- ============================================================
function MA.Base()
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("奥术冲击")
    PlayerHP = MA.UnitHP("player")
    PlayerMP = MA.UnitMP("player")
    PlayerMove = MA.PlayerMoving()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)
    MA.CasterOK = true
    MA.CastingName = nil
    MA.ChannelName = nil
    if type(WR_SafeCastingName) == "function" then
        local ok, v = pcall(WR_SafeCastingName, "player")
        if ok and type(v) == "string" then MA.CastingName = v end
    elseif type(UnitCastingInfo) == "function" then
        local ok, v = pcall(UnitCastingInfo, "player")
        if ok and type(v) == "string" then MA.CastingName = v end
    end
    if type(WR_SafeChannelName) == "function" then
        local ok, v = pcall(WR_SafeChannelName, "player")
        if ok and type(v) == "string" then MA.ChannelName = v end
    elseif type(UnitChannelInfo) == "function" then
        local ok, v = pcall(UnitChannelInfo, "player")
        if ok and type(v) == "string" then MA.ChannelName = v end
    end
    MA.TargetValid = MA.TargetOK()
    MA.InRange = (type(TargetRange) == "number" and TargetRange <= 35)
end

function MA.StopGate()
    local stop = false
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, dead = pcall(UnitIsDeadOrGhost, "player")
        if ok and dead == true then stop = true end
    end
    if not stop and MA.IsMountedOrVehicle() then stop = true end
    if not stop and MA.EatingDrinking() then stop = true end
    if stop then MA.Sweep(); return true end
    return false
end

function MA.CombatGate()
    local bossFrameActive = false
    for i = 1, 4 do
        if type(UnitExists) == "function" and UnitExists("boss" .. i) then bossFrameActive = true; break end
    end
    local inBossEncounter = bossFrameActive and (MA.InCombat() or (type(UnitAffectingCombat) == "function" and UnitAffectingCombat("target")))
    if inBossEncounter then return true end
    if not MA.InCombat() then return false end
    local preventAdd = (MA.Val("AF_FADD", 1) == 1)
    if preventAdd then
        return TargetInCombat == true
    end
    return true
end

-- ============================================================
-- 6. 功能段：护甲 / 奥术智慧 / 驱散 / 切换目标 / 喝红药 / 打断
-- ============================================================
function MA.ArmorStep()
    if not MA.On("AF_ARMOR", true) then return false end
    local kind = MA.Val("AF_ARMOR_KIND", 1)
    local spell, slot
    if kind == 2 then spell, slot = "魔甲术", 107 else spell, slot = "冰甲术", 106 end
    if not MA.SpellKnown(spell) then
        if kind == 2 then spell, slot = "冰甲术", 106 else spell, slot = "魔甲术", 107 end
    end
    if not MA.SpellKnown(spell) then return false end
    if MA.BuffRemain("player", spell) == 0 and MA.CanCast(spell) then
        return MA.Show(spell, slot)
    end
    return false
end

MA.FocusParty = nil
MA.FocusUntil = nil
MA.FocusCastAt = nil

function MA.StartFocus(unit, label)
    MA.FocusParty = unit
    MA.FocusUntil = GetTime() + 6
    MA.FocusCastAt = nil
    if type(WR_FocusUnit) == "function" then
        return WR_FocusUnit(unit, label) == true
    end
    return false
end

function MA.FocusFlow(castSpell, castSlot, label)
    if not MA.FocusParty or not MA.FocusUntil then return false end
    local now = GetTime()
    if now >= MA.FocusUntil then
        MA.FocusParty = nil; MA.FocusUntil = nil; MA.FocusCastAt = nil
        return false
    end
    if type(UnitIsUnit) == "function" and UnitIsUnit("focus", MA.FocusParty) then
        if not MA.FocusCastAt then
            MA.FocusCastAt = now
        end
        if now - MA.FocusCastAt <= 2.5 then
            return MA.Show(castSpell, castSlot)
        end
        MA.FocusParty = nil; MA.FocusUntil = nil; MA.FocusCastAt = nil
        return false
    end
    if type(WR_FocusUnit) == "function" then
        return WR_FocusUnit(MA.FocusParty, label) == true
    end
    return false
end

-- 小队里有没有蓝（战士/盗贼等无蓝职业不加）
function MA.UnitHasMana(unit)
    if type(UnitPowerMax) ~= "function" then return true end
    local ok, v = pcall(UnitPowerMax, unit, 0)
    if ok and type(v) == "number" then return v > 0 end
    return true
end

function MA.IntellectRemain(unit)
    local a = MA.BuffRemain(unit, "奥术智慧")
    local b = MA.BuffRemain(unit, "奥术光辉")
    if b > a then return b end
    return a
end

function MA.IntellectStep()
    if not MA.On("AF_INT", true) then return false end
    if MA.InCombat() or MA.IsMountedOrVehicle() or MA.EatingDrinking() then return false end
    if type(UnitExists) == "function" and UnitExists("target") and type(UnitCanAttack) == "function" and UnitCanAttack("player", "target") then
        -- 战斗中先不打 buff；有敌对目标时也不抢
    end
    if MA.On("AF_INT_SELF", true) and MA.IntellectRemain("player") < 60 and MA.CanCast("奥术智慧") then
        return MA.Show("奥术智慧", 108)
    end
    if not MA.On("AF_INT_PARTY", true) then return false end

    if MA.FocusFlow("奥术智慧(队友)", 109, "奥术智慧") then return true end

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
            if alive and connected and inRange and MA.UnitHasMana(unit) and MA.IntellectRemain(unit) < 60 then
                return MA.StartFocus(unit, "奥术智慧")
            end
        end
    end
    return false
end

function MA.DispelStep()
    if not MA.On("AF_QS", true) then return false end
    local function hasCurse(unit)
        if type(WR_UnitDebuffType) ~= "function" then return false end
        local okC, c = pcall(WR_UnitDebuffType, unit, "Curse")
        local okD, d = pcall(WR_UnitDebuffType, unit, "Disease")
        return (okC and c == true) or (okD and d == true)
    end
    if MA.On("AF_QS_SELF", true) and hasCurse("player") and MA.CanCast("解除次级诅咒") then
        return MA.Show("解除次级诅咒", 112)
    end
    if MA.On("AF_QS_PARTY", true) then
        if MA.FocusFlow("解除次级诅咒(队友)", 113, "解除诅咒") then return true end
        for i = 1, 4 do
            local unit = "party" .. i
            if type(UnitExists) == "function" and UnitExists(unit) and hasCurse(unit) then
                return MA.StartFocus(unit, "解除诅咒")
            end
        end
    end
    if MA.On("AF_QS_STEAL", true) and MA.TargetValid and MA.InRange then
        if type(WR_UnitBuffType) == "function" then
            local ok, v = pcall(WR_UnitBuffType, "target", "Magic")
            if ok and v == true and MA.CanCast("法术吸取") then
                return MA.Show("法术吸取", 43)
            end
        end
    end
    return false
end

MA.LastTab = MA.LastTab or 0

function MA.TargetSwitchStep()
    if not MA.On("AF_TAB", true) then return false end
    if MA.TargetValid then return false end
    if not MA.InCombat() then return false end
    if type(WR_CanTab) == "function" then
        local ok, can = pcall(WR_CanTab)
        if ok and can == false then return false end
    end
    local now = GetTime()
    if now - (MA.LastTab or 0) < 1.0 then return false end
    if MA.Show("切换目标", 40) then
        MA.LastTab = now
        return true
    end
    return false
end

function MA.PotionStep()
    local threshold = MA.Val("AF_HXY", 30)
    if threshold <= 0 then return false end
    if not MA.InCombat() then return false end
    local hp = MA.UnitHP("player")
    if not hp or hp >= threshold / 100 then return false end
    if type(WR_Use_ZLYS) == "function" then
        local ok, can = pcall(WR_Use_ZLYS)
        if not ok or can ~= true then return false end
        return MA.Show("治疗药水", 111)
    end
    return false
end

function MA.InterruptStep()
    if type(WR_ShouldInterrupt) ~= "function" then return false end
    local ok, should = pcall(WR_ShouldInterrupt, "target", "AF_FSFZ")
    if not ok or should ~= true then return false end
    if MA.CanCast("法术反制") then return MA.Show("法术反制", 46) end
    return false
end

-- ============================================================
-- 7. 爆发：奥术强化 / 气定神闲 / 种族爆发
-- ============================================================
function MA.BurstStep()
    if MA.On("AF_ZDASQH", true)
       and MA.Ready("奥术强化")
       and MA.BuffRemain("player", "奥术强化") == 0
       and MA.CanCast("奥术强化") then
        return MA.Show("奥术强化", 16)
    end
    if MA.On("AF_ZDQDSX", true)
       and MA.Ready("气定神闲")
       and MA.BuffRemain("player", "气定神闲") == 0
       and MA.CanCast("气定神闲") then
        return MA.Show("气定神闲", 15)
    end
    if MA.On("AF_ZDZZ", true) then
        local list = MA.GetRacialBursts()
        for i = 1, #list do
            local name = list[i]
            if type(name) == "string" and MA.CanCast(name) then
                return MA.Show("种族爆发", 181)
            end
        end
    end
    return false
end

-- ============================================================
-- 8. 奥爆 / 读条引导（核心）
-- ============================================================
function MA.AoeStep()
    local need = MA.Val("AF_AOBAO", 0)
    if need <= 0 then return false end
    local count = tonumber(UnitCount8) or 0
    if count >= need and MA.CanCast("魔爆术") then
        return MA.Show("魔爆术", 78)
    end
    return false
end

-- 唤醒：不归「读条引导」总开关管；低蓝时自动提示（8 分钟 CD）
function MA.EvocationStep()
    local mp = MA.UnitMP("player") or 0
    if mp < 0.20 and MA.Ready("唤醒") and MA.CanCast("唤醒") then
        return MA.Show("唤醒", 18)
    end
    return false
end

function MA.CastStep()
    if not MA.On("AF_CAST", true) then
        -- 关掉读条引导：不提示任何读条技能，但低蓝时仍让魔杖兜底；
        -- 同时接管本 tick，阻止 Mage_Forever.lua 的分发器插入保底火球术。
        if MA.TargetValid and MA.InRange then
            local mpOff = MA.UnitMP("player") or 1
            local wandOff = MA.Val("AF_MZHL", 50)
            if wandOff > 0 and mpOff < wandOff / 100 then return false end
            MA.Sweep()
            return true
        end
        return false
    end
    if not MA.TargetValid or not MA.InRange then return false end
    if MA.ChannelName == "奥术飞弹" then return true end
    if MA.CastingName or MA.ChannelName then return false end
    if MA.PlayerMoving() then return false end

    local mp = MA.UnitMP("player") or 0
    local clearcasting = MA.HasAnyBuff(MA.CLEARCAST_BUFFS)
    local manaFloor = MA.Val("AF_CAST_MANA", 40) / 100
    local arcaneOK = clearcasting or (mp >= manaFloor)

    local mode = MA.Val("AF_CAST_MODE", 1)
    local stackTarget = MA.Val("AF_CAST_STACKS", 0)
    if stackTarget <= 0 then stackTarget = 4 end
    local wrathTarget = MA.Val("AF_CAST_WRATH_STACKS", 4)
    if wrathTarget <= 0 then wrathTarget = 1 end
    local stacks = MA.ArcaneBlastStacks()
    local blastRemain = MA.ArcaneBlastRemain()

    -- 8.1 奥术冲击：叠层 / 无脑 / 奥术愤怒模式下的补层
    if MA.On("AF_CAST_AB", true) and arcaneOK then
        local needStack = false
        if mode == 2 then
            needStack = true
        elseif mode == 3 then
            needStack = (blastRemain <= 3) or (stacks < wrathTarget)
        else
            needStack = (blastRemain <= 0) or (stacks < stackTarget)
        end
        if needStack and MA.CanCast("奥术冲击") then
            return MA.Show("奥术冲击", 13)
        end
    end

    -- 8.1b 有节能就打：节能施法（下一发伤害法术免费）优先奥术冲击
    if clearcasting and MA.On("AF_CAST_AB", true) and MA.CanCast("奥术冲击") then
        return MA.Show("奥术冲击", 13)
    end

    -- 8.2 奥术飞弹：飞弹连射触发时优先（免费/快速）
    if MA.On("AF_CAST_AM", true) and arcaneOK and MA.HasAnyBuff(MA.MISSILE_BARRAGE_BUFFS) then
        if MA.CanCast("奥术飞弹") then
            return MA.Show("奥术飞弹", 14)
        end
    end

    -- 8.3 奥术愤怒模式：叠到「愤怒层数」后转奥术愤怒，Buff 快到时间再补奥术冲击
    if mode == 3 and arcaneOK and stacks >= wrathTarget then
        if MA.Ready("奥术愤怒") and MA.CanCast("奥术愤怒") then
            return MA.Show("奥术愤怒", 110)
        end
    end

    -- 8.4 填充技能：寒冰箭 → 霜火之箭 → 火球术（从上到下就是先后）
    if mp >= 0.05 then
        if MA.On("AF_CAST_FROSTBOLT", true) and MA.CanCast("寒冰箭") then
            return MA.Show("寒冰箭", 60)
        end
        if MA.On("AF_CAST_FROSTFIRE", true) and MA.CanCast("霜火之箭") then
            return MA.Show("霜火之箭", 20)
        end
        if MA.On("AF_CAST_FIREBALL", true) and MA.CanCast("火球术") then
            return MA.Show("火球术", 5)
        end
    end
    -- 蓝量低于魔杖拉条 → 交给 WandStep（魔杖兜底），不要在这里接管
    local mpNow = MA.UnitMP("player") or 1
    local wandThreshold = MA.Val("AF_MZHL", 50)
    if wandThreshold > 0 and mpNow < wandThreshold / 100 then return false end

    -- 有目标且在射程内，但本 tick 所有技能都放不出（CD/蓝量/全部取消勾选）：
    -- 清掉残留色块，并接管本 tick，阻止 Mage_Forever.lua 的分发器插入保底火球术。
    MA.Sweep()
    return true
end

-- ============================================================
-- 9. 插入（一次性：放完自动取消勾选）
-- ============================================================
function MA.InsertOnce(var, spell, slot)
    if not MA.On(var, false) then return false end
    if not MA.CanCast(spell) then return false end
    if MA.Show(spell, slot) then
        PigSet[var] = false
        MA.SyncCheckbox(var)
        return true
    end
    return false
end

function MA.InsertStep()
    if MA.InsertOnce("AF_CRBH", "冰霜新星", 11) then return true end
    if MA.InsertOnce("AF_CRLYFB", "烈焰风暴", 23) then return true end
    if MA.InsertOnce("AF_CRBFX", "暴风雪", 26) then return true end
    if MA.InsertOnce("AF_CRMB", "魔爆术", 78) then return true end
    if MA.InsertOnce("AF_CRSX", "闪现术", 31) then return true end
    return false
end

-- ============================================================
-- 10. 魔杖兜底
-- ============================================================
function MA.WandStep()
    local threshold = MA.Val("AF_MZHL", 50)
    if threshold <= 0 then return false end
    if not MA.TargetValid or not MA.InRange then return false end
    local mp = MA.UnitMP("player") or 1
    if mp >= threshold / 100 then return false end
    return MA.Show("魔杖", 190)
end

-- ============================================================
-- 11. 主循环
-- ============================================================
function MA.Run()
    MA.InitDefaults()
    MA.Base()
    if MA.StopGate() then return false end
    if MA.InsertStep() then return true end
    if MA.PotionStep() then return true end
    if MA.ArmorStep() then return true end
    if MA.IntellectStep() then return true end
    if MA.TargetSwitchStep() then return true end
    if not MA.CombatGate() then MA.Sweep(); return false end
    if MA.InterruptStep() then return true end
    if MA.DispelStep() then return true end
    if MA.BurstStep() then return true end
    if MA.EvocationStep() then return true end
    if MA.AoeStep() then return true end
    if MA.CastStep() then return true end
    if MA.WandStep() then return true end
    MA.Sweep()
    return false
end

-- ============================================================
-- 12. 右键「额外条件」小窗
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

MA.PopupDefs = {
    AF_CAST = {
        title = "读条引导  功能",
        width = 360,
        desc = "开着时按右键里的设置放奥术冲击、奥术飞弹、奥术愤怒和勾上的填充技能。\n\n"
            .. "上面是奥术冲击这一套怎么打：「打法」三选一、两条层数（叠层、奥术愤怒各用的）、「蓝量」「有节能就打」；下面每个技能一个勾 = 放不放，填充技能从上到下就是先后：寒冰箭、霜火之箭、火球术（上面的放得出来就轮不到下面的）。\n\n"
            .. "唤醒不归这个开关管。\n\n"
            .. "关掉后右键里的技能一个都不放（只剩瞬发技能、唤醒和魔杖）。\n"
            .. "宏：/MAGE_CAST 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "AF_CAST", label = "读条引导", default = true },
            { type = "header", text = "打法" },
            { type = "radio", var = "AF_CAST_MODE", default = 1, perRow = 1, indent = 18,
              options = { { id = 1, name = "叠加" }, { id = 2, name = "无脑" }, { id = 3, name = "奥术愤怒" } } },
            { type = "slider", var = "AF_CAST_STACKS", label = "叠层层数", minv = 0, maxv = 4, step = 1, default = 0, suffix = "层" },
            { type = "slider", var = "AF_CAST_WRATH_STACKS", label = "愤怒层数", minv = 0, maxv = 4, step = 1, default = 4, suffix = "层" },
            { type = "slider", var = "AF_CAST_MANA", label = "蓝量", minv = 0, maxv = 100, step = 5, default = 40, suffix = "%" },
            { type = "check", var = "AF_CAST_CLEARCAST", label = "有节能就打", default = true },
            { type = "header", text = "技能" },
            { type = "check", var = "AF_CAST_AB", label = "奥术冲击 -奥术", default = true },
            { type = "check", var = "AF_CAST_AM", label = "奥术飞弹", default = true },
            { type = "check", var = "AF_CAST_FROSTBOLT", label = "寒冰箭", default = true },
            { type = "check", var = "AF_CAST_FROSTFIRE", label = "霜火之箭", default = true },
            { type = "check", var = "AF_CAST_FIREBALL", label = "火球术", default = true },
        },
    },
    AF_ARMOR = {
        title = "护甲  功能",
        width = 340,
        desc = "开着时，自己身上没有右键里选中的那种甲就自动补上（冰甲术 / 魔甲术 二选一）；战斗内外都补。\n\n"
            .. "关掉后不再自动补甲。\n"
            .. "宏：/MAGE_ARMOR_ON 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "AF_ARMOR", label = "护甲", default = true },
            { type = "radio", var = "AF_ARMOR_KIND", default = 1, perRow = 2, indent = 18,
              options = { { id = 1, name = "冰甲术" }, { id = 2, name = "魔甲术" } } },
        },
    },
    AF_INT = {
        title = "奥术智慧  功能",
        width = 360,
        desc = "开着时，脱战后身上没有奥术智慧、或者剩不到 1 分钟，就自动补上；给谁加在右键里勾，两个可以都勾。\n\n"
            .. "自己：给自己加。\n\n"
            .. "小队：给小队里有蓝的队友加，战士、盗贼这类没蓝的不加；队友离得太远、死了、掉线时先不加他。团队里只管自己这个小队。给队友加时会把焦点切到他，加完切回自己；进了战斗会把焦点清掉。\n\n"
            .. "别人加的奥术智慧、奥术光辉也算有；战斗中、骑着坐骑、吃喝时不补。\n\n"
            .. "关掉后不再自动补奥术智慧。\n"
            .. "宏：/MAGE_INTELLECT 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "AF_INT", label = "奥术智慧", default = true },
            { type = "check", var = "AF_INT_SELF", label = "自己", default = true, indent = 18 },
            { type = "check", var = "AF_INT_PARTY", label = "小队", default = true, indent = 18 },
        },
    },
    AF_QS = {
        title = "驱散  功能",
        width = 340,
        desc = "开着时，自己或小队身上有诅咒/疾病就用解除次级诅咒驱散；目标身上有可偷取的魔法增益时自动法术偷取。\n\n"
            .. "右键可分别关闭「自己」「小队」「法术偷取」。\n"
            .. "宏：/MAGE_QS 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "AF_QS", label = "驱散", default = true },
            { type = "check", var = "AF_QS_SELF", label = "自己", default = true, indent = 18 },
            { type = "check", var = "AF_QS_PARTY", label = "小队", default = true, indent = 18 },
            { type = "check", var = "AF_QS_STEAL", label = "法术偷取", default = true, indent = 18 },
        },
    },
}

local function BuildPopup(key)
    local def = MA.PopupDefs[key]
    if not def then return nil end
    local width = def.width or 360
    local f = CreateFrame("Frame", "WR_MageArcanePopup_" .. key, UIParent, "BackdropTemplate")
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
                MA.SyncCheckbox(rowDef.var)
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
            local val = MA.Num(PigSet[rowDef.var], rowDef.default or 0)
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
                local v = MA.Num(PigSet[rec.row.var], rec.row.default or 0)
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

MA.PopupCache = MA.PopupCache or {}

function MA.ShowOptions(key)
    MA.InitDefaults()
    local def = MA.PopupDefs[key]
    if not def then return end
    local f = MA.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        MA.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(MA.PopupCache) do
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
-- 13. 爆发按钮（全开 / 全关 / 切换）
-- ============================================================
function MA.SetBurst(on)
    if type(PigSet) ~= "table" then return end
    PigSet.AF_ZDASQH = on and true or false
    PigSet.AF_ZDQDSX = on and true or false
    PigSet.AF_ZDZZ = on and true or false
    MA.SyncCheckbox("AF_ZDASQH")
    MA.SyncCheckbox("AF_ZDQDSX")
    MA.SyncCheckbox("AF_ZDZZ")
end

function WR_MageArcaneBurstAllOn()
    if WR_MageArcaneFeatures then WR_MageArcaneFeatures.SetBurst(true) end
end

function WR_MageArcaneBurstAllOff()
    if WR_MageArcaneFeatures then WR_MageArcaneFeatures.SetBurst(false) end
end

function WR_MageArcaneBurstToggle()
    if not WR_MageArcaneFeatures then return end
    local any = (PigSet.AF_ZDASQH == true) or (PigSet.AF_ZDQDSX == true) or (PigSet.AF_ZDZZ == true)
    WR_MageArcaneFeatures.SetBurst(not any)
end

-- ============================================================
-- 14. 斜杠命令（截图口径）
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
    MA.SyncCheckbox(var)
    local status = PigSet[var] and "|cff00ff00已开启|r" or "|cffff0000已关闭|r"
    local text = status .. " [" .. label .. "]"
    if type(WR_PrintToVisible) == "function" then
        pcall(WR_PrintToVisible, text)
    elseif type(print) == "function" then
        print(text)
    end
end

local function BindCommand(cmd, var, label)
    -- 与火法共用命令：注册到专精分发表，按当前专精分流。
    _G["SLASH_" .. cmd .. "1"] = "/" .. cmd
    local registry = _G.WR_MageCommandRegistry
    if type(registry) ~= "table" then registry = {}; _G.WR_MageCommandRegistry = registry end
    local bySpec = registry[cmd]
    if type(bySpec) ~= "table" then bySpec = {}; registry[cmd] = bySpec end
    bySpec["奥术"] = function(msg) SetVarByCommand(var, msg, label) end
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

BindCommand("MAGE_CAST", "AF_CAST", "读条引导")
BindCommand("MAGE_ARMOR_ON", "AF_ARMOR", "护甲")
BindCommand("MAGE_INTELLECT", "AF_INT", "奥术智慧")
BindCommand("MAGE_QS", "AF_QS", "驱散")