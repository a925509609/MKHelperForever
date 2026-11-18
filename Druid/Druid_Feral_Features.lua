-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "DRUID" then return end
-- ============================================================
-- Druid_Feral_Features.lua
-- 野性德鲁伊（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 DRUID「野性战斗 / 野性」专精：不写全局、不影响平衡/守护/恢复与其他职业。
-- 共享件 Druid_Forever.lua 零改动（平衡/守护/恢复仍走各自实现）。
--
-- 按「彼岸花-无限服 · 野性页」截图逐项落地：
--   选择：防ADD / 形态（猫形态 / 熊形态）
--   拉条：喝红药 30% / 猫专属 猛虎之怒 30% / 熊专属 槌击 25% / 狂暴回复 40%
--   爆发：全开 / 全关 / 切换按钮 + 狂暴 + 种族爆发
--   功能：变形 / 切换目标 / 精灵之火
--         猫专属：扫击 / 终结技 / 变形之力 / 正面
--         熊专属：挫志咆哮 / 挥击 / 割伤 / 嘲讽 / 野性印记 / 复生 / 激活 / 荆棘术
--   插入：熊专属 冲锋 / 群嘲 / 重击（一次性，放完自关）
--
-- 【本服 60 级野性技能口径】
--   猫：猎豹形态 / 猛虎之怒 / 撕碎 / 爪击 / 斜掠 / 割裂 / 凶猛撕咬 / 扫击 /
--       变形之力（Shifting Power，1322605，8 秒 CD：55% 基础法力换 40 能量）
--   熊：巨熊形态 / 槌击 / 挥击 / 割伤 / 挫志咆哮 / 嘲讽（低吼）/ 狂暴回复 /
--       野性冲锋 / 挑战咆哮 / 重击
--   ★ 80 级 / SoD 技能（野蛮咆哮、割碎、痛击、重殴、横扫（豹/熊）、
--     寒霜刺骨、狂咒、速度药水、炸弹等）本服 60 级不再使用，本层不引用。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "DRUID" then return end

WR_DruidFeralUI = WR_DruidFeralUI or {}
local WF = WR_DruidFeralUI

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ============================================================
WF.Defaults = {
    -- 功能（截图默认全勾，嘲讽除外）
    YD_BX = true,             -- 变形（按形态选择自动补猎豹/巨熊形态）
    YD_TAB = true,            -- 切换目标
    YD_JLZF = true,           -- 精灵之火（野性）
    YD_SJ = true,             -- 扫击（猫 AoE）
    YD_ZJJ = true,            -- 终结技（割裂 / 凶猛撕咬）
    YD_BXZL = true,           -- 变形之力（Shifting Power）
    YD_ZM = true,             -- 正面（允许正面爪击/裂伤）
    YD_CZPX = true,           -- 挫志咆哮（熊）
    YD_HJ = true,             -- 挥击（熊）
    YD_GS = true,             -- 割伤（熊）
    YD_CS = false,            -- 嘲讽（截图未勾）
    YD_YXYZ = true,           -- 野性印记
    YD_FS = true,             -- 复生
    YD_JH_ON = true,          -- 激活
    YD_JH_HP = 20,            --   激活蓝量阈值（%）
    YD_JJS = true,            -- 荆棘术
    -- 拉条
    YD_HXY = 30,              -- 喝红药：血低于 30%
    YD_MHZN_NL = 30,          -- 猛虎之怒：能量低于 30% 时用
    YD_CJ_NL = 25,            -- 槌击：怒气高于 25% 时用
    YD_KBHF_HP = 40,          -- 狂暴回复：血低于 40% 时用
    -- 爆发
    YD_KB = true,             -- 狂暴
    YD_ZDZZ = true,           -- 种族爆发
    -- 插入（一次性，默认关）
    YD_CF = false,            -- 冲锋
    YD_QC = false,            -- 群嘲
    YD_ZJ = false,            -- 重击
}

WF.Migrated = WF.Migrated or false

function WF.InitDefaults()
    if type(PigSet) ~= "table" then return end
    -- ★ 旧档迁移必须先于默认值填充
    if not WF.Migrated then
        WF.Migrated = true
        -- 旧「自动猛虎之怒」布尔开关 → 新能量阈值拉条
        if PigSet.YD_MHZN ~= nil and PigSet.YD_MHZN_NL == nil then
            PigSet.YD_MHZN_NL = (PigSet.YD_MHZN == true) and 30 or 0
        end
        -- 旧「正面裂伤（猫）」开关 → 新「正面」
        if PigSet.YD_ZMLS ~= nil and PigSet.YD_ZM == nil then
            PigSet.YD_ZM = (PigSet.YD_ZMLS == true)
        end
        -- 旧「解定身」常驻开关 → 新「变形」
        if PigSet.YD_CAT_CAT_AUTO ~= nil and PigSet.YD_BX == nil then
            PigSet.YD_BX = (PigSet.YD_CAT_CAT_AUTO == true)
        end
        -- 旧激活滑条 → 新激活阈值
        local oldJh = tonumber(PigSet.YD_JH)
        if oldJh and PigSet.YD_JH_HP == nil then
            PigSet.YD_JH_HP = oldJh
        end
    end
    for k, v in pairs(WF.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
end

-- ============================================================
-- 2. 安全读取小工具
-- ============================================================
function WF.Num(v, d)
    local n = tonumber(v)
    if n == nil then return d end
    return n
end

function WF.Bool(v, d)
    if v == nil then return d end
    return v == true
end

function WF.On(var, default)
    return WF.Bool(PigSet and PigSet[var], default)
end

function WF.Val(var, default)
    return WF.Num(PigSet and PigSet[var], default)
end

function WF.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
end

function WF.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, known = pcall(WR_Forever_IsSpellKnown, name)
        if ok then return known == true end
    end
    return true
end

function WF.Show(spell, slot)
    WF.RawShownSlot = nil
    if WR_ColorFrame_ShowSkill ~= nil then
        return WR_ColorFrame_ShowSkill(spell, slot) == true
    end
    return false
end

function WF.ShowSlot(slot, text)
    if WR_ColorFrame_Show ~= nil then
        local ok, shown = pcall(WR_ColorFrame_Show, slot, text)
        if ok and shown then
            WR_SoD_LastShownSpell = text
            WR_SoD_ShownSkill = text
            WR_SoD_ShownTick = WR_SoD_TickSeq
            WF.RawShownSlot = slot
            return true
        end
    end
    return false
end

function WF.BuffRemain(name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, "player", name)
    if ok then return WF.Num(v, 0) end
    return 0
end

function WF.DebuffRemain(unit, name)
    if type(WR_GetUnitDebuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffTime, unit, name)
    if ok then return WF.Num(v, 0) end
    return 0
end

function WF.IsDead(unit)
    if type(UnitExists) ~= "function" or not UnitExists(unit) then return false end
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, dead = pcall(UnitIsDeadOrGhost, unit)
        if ok and dead == true then return true end
    end
    if type(UnitIsDead) == "function" then
        local ok, dead = pcall(UnitIsDead, unit)
        if ok and dead == true then return true end
    end
    return false
end

function WF.IsFriend(unit)
    if type(UnitExists) ~= "function" or not UnitExists(unit) then return false end
    if type(UnitIsFriend) ~= "function" then return true end
    local ok, friend = pcall(UnitIsFriend, "player", unit)
    return ok and friend == true
end

function WF.GroupUnits()
    local units = {}
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    if raid > 0 then
        for i = 1, math.min(raid, 40) do units[#units + 1] = "raid" .. i end
    else
        local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
        for i = 1, math.min(party, 4) do units[#units + 1] = "party" .. i end
    end
    return units
end

-- 资源百分比：3=能量，1=怒气
function WF.PowerPct(powerType)
    if type(WR_SafePowerPct) == "function" then
        local ok, v = pcall(WR_SafePowerPct, "player", powerType)
        if ok then return WF.Num(v, 1) end
    end
    if type(UnitPower) ~= "function" then return 1 end
    local cur = UnitPower("player", powerType) or 0
    local max = (UnitPowerMax and UnitPowerMax("player", powerType)) or 0
    if max <= 0 then return 1 end
    return cur / max
end

function WF.FormID()
    if type(GetShapeshiftFormID) == "function" then
        local ok, id = pcall(GetShapeshiftFormID)
        if ok and type(id) == "number" then return id end
    end
    if type(GetShapeshiftForm) == "function" then
        local ok, form = pcall(GetShapeshiftForm)
        if ok and type(form) == "number" then return form end
    end
    return 0
end

function WF.IsCat()
    local id = WF.FormID()
    if id == 3 or id == 6 then return true end
    return WF.BuffRemain({ "猎豹形态", "猎豹形态(变形)", "猫形态", "大猫形态" }) > 0
end

function WF.IsBear()
    local id = WF.FormID()
    if id == 1 then return true end
    return WF.BuffRemain({ "熊形态", "巨熊形态", "巨熊形态(变形)" }) > 0
end

-- ============================================================
-- 3. 循环：基础变量 / 停手门 / 收尾清扫
-- ============================================================
function WF.Base()
    GCD = WR_GetGCD("撕碎")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    local cp = 0
    if type(WR_Forever_GetComboPoints) == "function" then
        local ok, v = pcall(WR_Forever_GetComboPoints)
        if ok then cp = WF.Num(v, 0) end
    elseif type(GetComboPoints) == "function" then
        local ok, v = pcall(GetComboPoints, "player", "target")
        if ok then cp = WF.Num(v, 0) end
    end
    WF.ComboPoints = cp
    WF.TargetOK = UnitExists("target")
        and not UnitIsDeadOrGhost("target")
        and UnitCanAttack("player", "target")
    WF.InRange = (TargetRange ~= nil and TargetRange <= 5)
    WF.InCombat = UnitAffectingCombat("player")
    WF.Casting = WR_SafeCastingName("player")
    WF.Channel = WR_SafeChannelName("player")
    WF.Energy = WF.PowerPct(3)
    WF.Rage = WF.PowerPct(1)
end

function WF.HideLastShown()
    local lastShown = WR_SoD_ShownSkill
    local rawSlot = WF.RawShownSlot
    if rawSlot ~= nil and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, rawSlot)
    elseif type(lastShown) == "string" and lastShown ~= "" and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, nil)
    end
    WF.RawShownSlot = nil
    WR_SoD_ShownSkill = nil
end

function WF.StopGate()
    if WF.Casting or WF.Channel then return true end
    local stop = UnitIsDeadOrGhost("player")
        or (IsMounted and IsMounted())
        or (UnitInVehicle and UnitInVehicle("player"))
    if not stop then
        local eatDrink = { "喝水", "进食", "饮用", "食物", "饮料", "饮水" }
        if WR_GetUnitBuffTime("player", eatDrink, nil, "NAME") > 0 then stop = true end
    end
    if stop then
        WF.HideLastShown()
        return true
    end
    return false
end

function WF.Sweep()
    if WR_SoD_ShownTick == WR_SoD_TickSeq then return end
    local lastShown = WR_SoD_ShownSkill
    local rawSlot = WF.RawShownSlot
    if rawSlot ~= nil and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, rawSlot)
    elseif type(lastShown) == "string" and lastShown ~= "" and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, nil)
    end
    WF.RawShownSlot = nil
    WR_SoD_ShownSkill = nil
end

-- ============================================================
-- 4. 功能：变形（按形态选择补猎豹/巨熊）
-- ============================================================
function WF.FormStep()
    if not WF.On("YD_BX", true) then return false end
    if not WF.InCombat and not WF.TargetOK then return false end
    local wantBear = (WF.Val("YD_XTXZ", 1) == 2)
    local name, slot
    if wantBear then
        if WF.IsBear() then return false end
        name, slot = "巨熊形态", 27
    else
        if WF.IsCat() then return false end
        name, slot = "猎豹形态", 1
    end
    -- 变形按宏槽点亮，不依赖 WR_SpellUsable 的名字解析（本服形态名带（变形）后缀）
    if WF.Show(name, slot) then return true end
    return false
end

-- ============================================================
-- 5. 功能：野性印记 / 荆棘术 / 复生 / 激活
-- ============================================================
function WF.MarkStep()
    if not WF.On("YD_YXYZ", true) then return false end
    if WF.BuffRemain({ "野性印记", "野性赐福" }) > 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "野性印记", true)
        if ok and usable == true then
            if WF.Show("野性印记", 149) then return true end
        end
    end
    return false
end

function WF.ThornsStep()
    if not WF.On("YD_JJS", true) then return false end
    if WF.BuffRemain("荆棘术") > 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "荆棘术", true)
        if ok and usable == true then
            if WF.Show("荆棘术", 150) then return true end
        end
    end
    return false
end

WF.RebirthLast = WF.RebirthLast or 0

function WF.RebirthStep()
    if not WF.On("YD_FS", true) then return false end
    if WF.Casting or WF.Channel then return false end
    if WF.IsDead("player") then return false end
    local now = GetTime()
    if now - WF.RebirthLast < 2.0 then return false end
    local targetUnit
    for _, u in ipairs(WF.GroupUnits()) do
        if u ~= "player" and WF.IsDead(u) then
            local range = WR_UnitRange and WR_UnitRange(u) or nil
            if range == nil or range <= 40 then
                targetUnit = u
                break
            end
        end
    end
    if not targetUnit then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "复生", true)
        if ok and usable == true then
            if type(TargetUnit) == "function" then pcall(TargetUnit, targetUnit) end
            if WF.Show("复生", 13) then
                WF.RebirthLast = now
                return true
            end
        end
    end
    return false
end

function WF.ActivateStep()
    if not WF.On("YD_JH_ON", true) then return false end
    local threshold = WF.Val("YD_JH_HP", 20)
    if threshold <= 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "激活", true)
        if not ok or usable ~= true then return false end
    end
    if WF.Num(PlayerMP, 1) < threshold / 100 then
        if WF.Show("激活", 93) then return true end
    end
    if UnitExists("focus") and WF.IsFriend("focus") and not WF.IsDead("focus") then
        local focusMP = WR_GetUnitMP("focus")
        if WF.Num(focusMP, 1) < threshold / 100 then
            if WF.ShowSlot(103, "激活") then return true end
        end
    end
    return false
end

-- ============================================================
-- 6. 猫专属：精灵之火 / 猛虎之怒 / 变形之力
-- ============================================================
function WF.FaerieFireStep()
    if not WF.On("YD_JLZF", true) then return false end
    if not WF.TargetOK then return false end
    if WF.Num(TargetRange, 99) > 30 then return false end
    if WF.DebuffRemain("target", "精灵之火") > 0
       or WF.DebuffRemain("target", "精灵之火（野性）") > 0 then
        return false
    end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "精灵之火（野性）", true)
        if ok and usable == true then
            if WF.Show("精灵之火（野性）", 10) then return true end
        end
    end
    return false
end

function WF.TigerFuryStep()
    if not WF.IsCat() then return false end
    local threshold = WF.Val("YD_MHZN_NL", 30)
    if threshold <= 0 then return false end
    if WF.Energy > threshold / 100 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "猛虎之怒", true)
        if ok and usable == true then
            if WF.Show("猛虎之怒", 2) then return true end
        end
    end
    return false
end

function WF.ShiftingPowerStep()
    if not WF.On("YD_BXZL", true) then return false end
    if not WF.IsCat() then return false end
    if WF.Num(PlayerMP, 1) < 0.15 then return false end
    if WF.Energy > 0.80 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "变形之力", true)
        if ok and usable == true then
            if WF.Show("变形之力", 194) then return true end
        end
    end
    return false
end

-- ============================================================
-- 7. 猫专属：斜掠 / 割裂 / 凶猛撕咬 / 扫击 / 撕碎·爪击
-- ============================================================
function WF.RakeStep()
    if not WF.IsCat() then return false end
    if not WF.TargetOK or not WF.InRange then return false end
    local T = TargetDeathTime or 0
    if T > 0 and T <= 6 then return false end
    if WF.DebuffRemain("target", "斜掠") > 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "斜掠", true)
        if ok and usable == true then
            if WF.Show("斜掠", 7) then return true end
        end
    end
    return false
end

function WF.RipStep()
    if not WF.On("YD_ZJJ", true) then return false end
    if not WF.IsCat() then return false end
    if not WF.TargetOK or not WF.InRange then return false end
    if WF.ComboPoints < 5 then return false end
    local T = TargetDeathTime or 0
    if T > 0 and T <= 6 then return false end
    if WF.DebuffRemain("target", "割裂") > 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "割裂", true)
        if ok and usable == true then
            if WF.Show("割裂", 5) then return true end
        end
    end
    return false
end

function WF.BiteStep()
    if not WF.On("YD_ZJJ", true) then return false end
    if not WF.IsCat() then return false end
    if not WF.TargetOK or not WF.InRange then return false end
    local T = TargetDeathTime or 0
    local hp = WR_SafeHPPct("target")
    local lowHP = (WF.Num(hp, 1) < 0.25)
    if not ((T > 0 and T <= 3 and WF.ComboPoints >= 3) or (lowHP and WF.ComboPoints >= 5)) then
        return false
    end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "凶猛撕咬", true)
        if ok and usable == true then
            if WF.Show("凶猛撕咬", 6) then return true end
        end
    end
    return false
end

function WF.CatSwipeStep()
    if not WF.On("YD_SJ", true) then return false end
    if not WF.IsCat() then return false end
    if not WF.TargetOK or not WF.InRange then return false end
    if WF.Num(UnitCount8, 0) < 3 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "扫击", true)
        if ok and usable == true then
            if WF.Show("扫击", 57) then return true end
        end
    end
    return false
end

function WF.ShredStep()
    if not WF.IsCat() then return false end
    if not WF.TargetOK or not WF.InRange then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "撕碎", true)
        if ok and usable == true then
            if WF.Show("撕碎", 15) then return true end
        end
        if WF.On("YD_ZM", true) then
            local ok2, usable2 = pcall(WR_SpellUsable, "爪击", true)
            if ok2 and usable2 == true then
                if WF.Show("爪击", 14) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 8. 熊专属：狂暴回复 / 挫志咆哮 / 割伤 / 挥击 / 槌击 / 嘲讽
-- ============================================================
function WF.BearRegenStep()
    if not WF.IsBear() then return false end
    local threshold = WF.Val("YD_KBHF_HP", 40)
    if threshold <= 0 then return false end
    if WF.Num(PlayerHP, 1) > threshold / 100 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "狂暴回复", true)
        if ok and usable == true then
            if WF.Show("狂暴回复", 42) then return true end
        end
    end
    return false
end

function WF.DemoRoarStep()
    if not WF.On("YD_CZPX", true) then return false end
    if not WF.IsBear() then return false end
    if not WF.TargetOK then return false end
    if WF.DebuffRemain("target", "挫志咆哮") > 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "挫志咆哮", true)
        if ok and usable == true then
            if WF.Show("挫志咆哮", 79) then return true end
        end
    end
    return false
end

function WF.LacerateStep()
    if not WF.On("YD_GS", true) then return false end
    if not WF.IsBear() then return false end
    if not WF.TargetOK or not WF.InRange then return false end
    -- 小于 5 秒就补，防止意外断 5 层
    if WF.DebuffRemain("target", "割伤") >= 5 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "割伤", true)
        if ok and usable == true then
            if WF.Show("割伤", 31) then return true end
        end
    end
    return false
end

function WF.BearSwipeStep()
    if not WF.On("YD_HJ", true) then return false end
    if not WF.IsBear() then return false end
    if not WF.TargetOK or not WF.InRange then return false end
    if WF.Num(UnitCount8, 0) < 3 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "挥击", true)
        if ok and usable == true then
            if WF.Show("挥击", 53) then return true end
        end
    end
    return false
end

function WF.BearFillerStep()
    if not WF.On("YD_HJ", true) then return false end
    if not WF.IsBear() then return false end
    if not WF.TargetOK or not WF.InRange then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "挥击", true)
        if ok and usable == true then
            if WF.Show("挥击", 53) then return true end
        end
    end
    return false
end

function WF.MaulStep()
    if not WF.IsBear() then return false end
    local threshold = WF.Val("YD_CJ_NL", 25)
    if threshold <= 0 then return false end
    if WF.Rage < threshold / 100 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "槌击", true)
        if ok and usable == true then
            if WF.Show("槌击", 52) then return true end
        end
    end
    return false
end

WF.TauntLast = WF.TauntLast or 0

function WF.TauntStep()
    if not WF.On("YD_CS", false) then return false end
    if not WF.IsBear() then return false end
    if not WF.TargetOK then return false end
    if type(UnitIsUnit) == "function" then
        local ok, same = pcall(UnitIsUnit, "targettarget", "player")
        if ok and same == true then return false end
    end
    local now = GetTime()
    if now - WF.TauntLast < 3.0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "低吼", true)
        if ok and usable == true then
            if WF.Show("低吼", 195) then
                WF.TauntLast = now
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 9. 插入：冲锋 / 群嘲 / 重击（一次性，放完自关）
-- ============================================================
function WF.InsertStep()
    local function fire(var, spell, slot)
        if not WF.On(var, false) then return false end
        if not WF.TargetOK then return false end
        if WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, spell, true)
            if ok and usable == true then
                if WF.Show(spell, slot) then
                    PigSet[var] = false
                    WF.SyncCheckbox(var)
                    return true
                end
            end
        end
        return false
    end
    if fire("YD_CF", "野性冲锋", 196) then return true end
    if fire("YD_QC", "挑战咆哮", 36) then return true end
    if fire("YD_ZJ", "重击", 51) then return true end
    return false
end

-- ============================================================
-- 10. 自保：喝红药（血低于拉条）
-- ============================================================
function WF.SelfPreserve()
    if WF.Num(PlayerHP, 1) >= WF.Val("YD_HXY", 30) / 100 then return false end
    if WR_Use_ZLYS ~= nil then
        local ok, can = pcall(WR_Use_ZLYS)
        if ok and can == true then
            if WR_ColorFrame_Show ~= nil then
                local ok2, shown = pcall(WR_ColorFrame_Show, "CSF", "治疗药水")
                if ok2 and shown then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 11. 切换目标（目标死亡/不存在 + 战斗中）
-- ============================================================
WF.LastTab = WF.LastTab or 0

function WF.TabStep()
    if not WF.On("YD_TAB", true) then return false end
    if not UnitAffectingCombat("player") then return false end
    if WF.TargetOK then return false end
    if WR_CanTab ~= nil and not WR_CanTab() then return false end
    local now = GetTime()
    if now - WF.LastTab < 1.0 then return false end
    if WF.Show("切目标", 46) then
        WF.LastTab = now
        return true
    end
    return false
end

-- ============================================================
-- 12. 战斗门（防ADD）：FANG_ADD_YD 1=是 2=否
-- ============================================================
function WF.CombatGate()
    local preventAdd = (WF.Val("FANG_ADD_YD", 1) == 1)
    local bossFrameActive = false
    for i = 1, 4 do
        if UnitExists("boss" .. i) then bossFrameActive = true; break end
    end
    local inBossEncounter = bossFrameActive
        and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    return inBossEncounter
        or (UnitAffectingCombat("player") and ((not preventAdd) or TargetInCombat))
end

-- ============================================================
-- 13. 爆发：狂暴 + 种族爆发
-- ============================================================
function WF.BurstStep()
    if WF.On("YD_KB", true) and (WF.IsCat() or WF.IsBear()) then
        if WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, "狂暴", true)
            if ok and usable == true then
                if WF.Show("狂暴", 3) then return true end
            end
        end
    end
    if not WF.On("YD_ZDZZ", true) then return false end
    local fn = WR_Forever_GetRacialBursts or WR_Forever_PlayerRacialBursts
    if type(fn) ~= "function" then return false end
    local okB, bursts = pcall(fn)
    if not okB or type(bursts) ~= "table" then return false end
    for i = 1, #bursts do
        local name = bursts[i]
        if type(name) == "string" and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, name, true)
            if ok and usable == true then
                if WF.Show("种族爆发", 181) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 14. 主循环
-- ============================================================
function WF.Run()
    WF.InitDefaults()
    local handled = false
    repeat
        WF.Base()
        if WF.StopGate() then break end
        if WF.FormStep() then handled = true; break end
        if WF.MarkStep() then handled = true; break end
        if WF.ThornsStep() then handled = true; break end
        if WF.RebirthStep() then handled = true; break end
        if WF.ActivateStep() then handled = true; break end
        if WF.InsertStep() then handled = true; break end
        if WF.SelfPreserve() then handled = true; break end
        if WF.TabStep() then handled = true; break end
        if not WF.CombatGate() then break end
        if WF.BurstStep() then handled = true; break end
        if WF.FaerieFireStep() then handled = true; break end
        if WF.IsCat() then
            if WF.TigerFuryStep() then handled = true; break end
            if WF.ShiftingPowerStep() then handled = true; break end
            if WF.RakeStep() then handled = true; break end
            if WF.RipStep() then handled = true; break end
            if WF.BiteStep() then handled = true; break end
            if WF.CatSwipeStep() then handled = true; break end
            if WF.ShredStep() then handled = true; break end
        elseif WF.IsBear() then
            if WF.BearRegenStep() then handled = true; break end
            if WF.DemoRoarStep() then handled = true; break end
            if WF.LacerateStep() then handled = true; break end
            if WF.BearSwipeStep() then handled = true; break end
            if WF.MaulStep() then handled = true; break end
            if WF.TauntStep() then handled = true; break end
            if WF.BearFillerStep() then handled = true; break end
        end
    until true
    if not handled then WF.Sweep() end
    return handled
end

-- ============================================================
-- 15. 爆发按钮（面板 onClick）
-- ============================================================
function WR_DruidFeralBurstAllOn()
    if type(PigSet) ~= "table" then return end
    PigSet.YD_KB = true
    PigSet.YD_ZDZZ = true
    WF.SyncCheckbox("YD_KB")
    WF.SyncCheckbox("YD_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cff00ff00[野性]|r 爆发已全部打开") end
end

function WR_DruidFeralBurstAllOff()
    if type(PigSet) ~= "table" then return end
    PigSet.YD_KB = false
    PigSet.YD_ZDZZ = false
    WF.SyncCheckbox("YD_KB")
    WF.SyncCheckbox("YD_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cffff5040[野性]|r 爆发已全部关闭") end
end

function WR_DruidFeralBurstToggle()
    if type(PigSet) ~= "table" then return end
    if PigSet.YD_KB == true and PigSet.YD_ZDZZ == true then
        WR_DruidFeralBurstAllOff()
    else
        WR_DruidFeralBurstAllOn()
    end
end

-- ============================================================
-- 16. 斜杠命令
-- ============================================================
local function ToggleSwitch(var, label)
    if type(PigSet) ~= "table" then return end
    PigSet[var] = not (PigSet[var] == true)
    WF.SyncCheckbox(var)
    print("|cff00ff00[" .. label .. "]|r " .. (PigSet[var] and "开启" or "关闭"))
end

SLASH_DRUID_FERAL_TIGER1 = "/DRUID_FERAL_TIGER"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_FERAL_TIGER"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.YD_MHZN_NL = 30; WF.SyncCheckbox("YD_MHZN_NL")
        elseif msg == "off" then PigSet.YD_MHZN_NL = 0; WF.SyncCheckbox("YD_MHZN_NL")
        else ToggleSwitch("YD_BXZL", "变形之力") end
    end
end

SLASH_DRUID_FERAL_INNERVATE1 = "/DRUID_FERAL_INNERVATE"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_FERAL_INNERVATE"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.YD_JH_ON = true; WF.SyncCheckbox("YD_JH_ON")
        elseif msg == "off" then PigSet.YD_JH_ON = false; WF.SyncCheckbox("YD_JH_ON")
        else ToggleSwitch("YD_JH_ON", "激活") end
    end
end

SLASH_DRUID_FERAL_THORNS1 = "/DRUID_FERAL_THORNS"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_FERAL_THORNS"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.YD_JJS = true; WF.SyncCheckbox("YD_JJS")
        elseif msg == "off" then PigSet.YD_JJS = false; WF.SyncCheckbox("YD_JJS")
        else ToggleSwitch("YD_JJS", "荆棘术") end
    end
end

SLASH_DRUID_FERAL_MARK1 = "/DRUID_FERAL_MARK"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_FERAL_MARK"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.YD_YXYZ = true; WF.SyncCheckbox("YD_YXYZ")
        elseif msg == "off" then PigSet.YD_YXYZ = false; WF.SyncCheckbox("YD_YXYZ")
        else ToggleSwitch("YD_YXYZ", "野性印记") end
    end
end
