-- ============================================================
-- Druid_Restoration_Features.lua
-- 恢复德鲁伊（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 DRUID「恢复」专精：不写全局、不影响平衡/野性/守护与其他职业。
-- 共享件 Druid_Forever.lua 零改动（平衡/野性/守护仍走各自实现）。
--
-- 按「彼岸花-无限服 · 恢复页」截图逐项落地：
--   选择：防ADD / 治疗模式（全团）
--   拉条：喝红药 30% / 迅捷治触 30% / 迅捷治愈 50% / 野性成长 80% /
--         回春术 95% / 治疗之触 60% / 愈合 85%
--   爆发：全开 / 全关 / 切换按钮 + 种族爆发
--   功能：野性印记 / 复生 / 激活 / 荆棘术 / 切换目标 / 驱散
--   插入：宁静（一次性，放完自关）
--
-- 【本服 60 级恢复技能口径（Data/Forever_SkillRegistry.lua）】
--   回春术 774 / 治疗之触 5185 / 愈合 8936 / 宁静 740 /
--   野性成长 1238214 / 迅捷治愈（无限天赋）/ 自然迅捷（无限天赋）/
--   激活 / 复生 / 野性印记 / 荆棘术 / 解除诅咒 2782
--   ★ 80 级 / SoD 技能（生命绽放、滋养、野性赐福、治疗之树、起死回生、
--     树皮术、旋风/狂咒/血肉成灰等 ICC 机制）本服 60 级不存在，本层不引用。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "DRUID" then return end

WR_DruidRestorationUI = WR_DruidRestorationUI or {}
local WT = WR_DruidRestorationUI

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ============================================================
WT.Defaults = {
    -- 选择
    FANG_ADD_HF = 1,          -- 防ADD：1=是 2=否
    HF_TREAT_MODE = 1,        -- 治疗模式：1全团 2目标 3预读 4坦克 5脆皮 6~10一~五队
    -- 功能（截图默认全勾）
    HF_YXYZ = true,           -- 野性印记
    HF_FS = true,             -- 复生
    HF_JH_ON = true,          -- 激活
    HF_JH_HP = 20,            --   激活蓝量阈值（%）
    HF_JJS = true,            -- 荆棘术
    HF_TAB = true,            -- 切换目标
    HF_QS_ON = true,          -- 驱散（解除诅咒）
    -- 拉条
    HF_HXY = 30,              -- 喝红药：血低于 30%
    HF_ZRXJ_HP = 30,          -- 迅捷治触（自然迅捷 + 治疗之触）：血低于 30%
    HF_XJZY = 50,             -- 迅捷治愈：血低于 50%
    HF_YZCZ = 80,             -- 野性成长：血低于 80%
    HF_HCS = 95,              -- 回春术：血低于 95%
    HF_ZLZC = 60,             -- 治疗之触：血低于 60%
    HF_YH_HP = 85,            -- 愈合：血低于 85%
    -- 爆发
    HF_ZDZZ = true,           -- 种族爆发
    -- 插入（一次性，默认关）
    HF_NJ_CR = false,         -- 宁静
}

WT.Migrated = WT.Migrated or false

function WT.InitDefaults()
    if type(PigSet) ~= "table" then return end
    -- ★ 旧档迁移必须先于默认值填充（否则旧变量被默认值覆盖）
    if not WT.Migrated then
        WT.Migrated = true
        -- 旧「驱散」下拉（1常规/2优先/3目标/4指向/5禁用）→ 新「驱散」总开关
        if PigSet.HF_QS_ON == nil then
            local oldQs = tonumber(PigSet.HF_QS)
            if oldQs ~= nil then
                PigSet.HF_QS_ON = (oldQs ~= 5)
            end
            -- 旧「驱散总闸」勾选 = 关闭自动驱散，优先级高于下拉
            if PigSet.HF_QS_AUTO == true then
                PigSet.HF_QS_ON = false
            end
        end
        -- 旧「愈合」下拉（1自动/2坦克/3禁用）→ 新愈合阈值
        if PigSet.HF_YH_HP == nil then
            local oldYH = tonumber(PigSet.HF_YH)
            if oldYH == 3 then
                PigSet.HF_YH_HP = 0
            end
        end
        -- 旧「给自己激活」滑条 → 新激活蓝量阈值
        local oldJh = tonumber(PigSet.HF_JH)
        if oldJh and PigSet.HF_JH_HP == nil then
            PigSet.HF_JH_HP = oldJh
        end
        -- 旧「宁静」全团阈值 HF_NJ_HP（0=禁用）→ 新「宁静」插入开关
        if PigSet.HF_NJ_CR == nil then
            local oldNj = tonumber(PigSet.HF_NJ_HP)
            if oldNj and oldNj > 0 then
                PigSet.HF_NJ_CR = true
            end
        end
    end
    for k, v in pairs(WT.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
end

-- ============================================================
-- 2. 安全读取小工具
-- ============================================================
function WT.Num(v, d)
    local n = tonumber(v)
    if n == nil then return d end
    return n
end

function WT.Bool(v, d)
    if v == nil then return d end
    return v == true
end

function WT.On(var, default)
    return WT.Bool(PigSet and PigSet[var], default)
end

function WT.Val(var, default)
    return WT.Num(PigSet and PigSet[var], default)
end

function WT.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
end

function WT.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, known = pcall(WR_Forever_IsSpellKnown, name)
        if ok then return known == true end
    end
    return true
end

function WT.Show(spell, slot)
    WT.RawShownSlot = nil
    if WR_ColorFrame_ShowSkill ~= nil then
        return WR_ColorFrame_ShowSkill(spell, slot) == true
    end
    return false
end

-- 直接按颜色槽位点亮（同名技能有「自己/焦点」两个宏槽时用）
function WT.ShowSlot(slot, text)
    if WR_ColorFrame_Show ~= nil then
        local ok, shown = pcall(WR_ColorFrame_Show, slot, text)
        if ok and shown then
            WR_SoD_LastShownSpell = text
            WR_SoD_ShownSkill = text
            WR_SoD_ShownTick = WR_SoD_TickSeq
            WT.RawShownSlot = slot
            return true
        end
    end
    return false
end

function WT.BuffRemain(name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, "player", name)
    if ok then return WT.Num(v, 0) end
    return 0
end

function WT.UnitBuffRemain(unit, name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, unit, name)
    if ok then return WT.Num(v, 0) end
    return 0
end

function WT.DebuffRemain(unit, name)
    if type(WR_GetUnitDebuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffTime, unit, name)
    if ok then return WT.Num(v, 0) end
    return 0
end

-- 任意诅咒（优先按 dispelType=Curse 判，名字兜底）
function WT.HasCurse(unit)
    if type(WR_UnitDebuffType) == "function" then
        local ok, has = pcall(WR_UnitDebuffType, unit, "Curse")
        if ok and has == true then return true end
    end
    return WT.DebuffRemain(unit, "诅咒") > 0
end

function WT.IsDead(unit)
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

function WT.IsFriend(unit)
    if type(UnitExists) ~= "function" or not UnitExists(unit) then return false end
    if type(UnitIsFriend) ~= "function" then return true end
    local ok, friend = pcall(UnitIsFriend, "player", unit)
    return ok and friend == true
end

function WT.InRaid()
    local n = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    return n > 0
end

-- 队伍/团队成员（含自己）
function WT.GroupUnits()
    local units = { "player" }
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    if raid > 0 then
        for i = 1, math.min(raid, 40) do units[#units + 1] = "raid" .. i end
    else
        local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
        for i = 1, math.min(party, 4) do units[#units + 1] = "party" .. i end
    end
    return units
end

function WT.HP(unit)
    if type(WR_GetUnitHP) ~= "function" then return 1 end
    local ok, v = pcall(WR_GetUnitHP, unit)
    if ok then return WT.Num(v, 1) end
    return 1
end

function WT.MP(unit)
    if type(WR_GetUnitMP) ~= "function" then return 1 end
    local ok, v = pcall(WR_GetUnitMP, unit)
    if ok then return WT.Num(v, 1) end
    return 1
end

function WT.RangeOf(unit)
    if unit == "player" then return 0 end
    if type(WR_UnitRange) ~= "function" then return nil end
    local ok, r = pcall(WR_UnitRange, unit)
    if ok and type(r) == "number" then return r end
    return nil
end

function WT.IsTank(unit)
    if type(UnitGroupRolesAssigned) == "function" then
        local ok, role = pcall(UnitGroupRolesAssigned, unit)
        if ok and role == "TANK" then return true end
    end
    return false
end

function WT.SubgroupOf(unit)
    if not WT.InRaid() then return 1 end
    if type(UnitInRaid) ~= "function" then return nil end
    local ok, idx = pcall(UnitInRaid, unit)
    if not ok or type(idx) ~= "number" or idx <= 0 then return nil end
    if type(GetRaidRosterInfo) ~= "function" then return nil end
    local ok2, _, _, subgroup = pcall(GetRaidRosterInfo, idx)
    if ok2 and type(subgroup) == "number" then return subgroup end
    return nil
end

-- 治疗模式过滤：1全团 2目标 3预读 4坦克 5脆皮 6~10 一~五队
function WT.ModeAllowed(unit)
    local mode = WT.Val("HF_TREAT_MODE", 1)
    if mode == 1 then return true end
    if mode == 2 or mode == 3 then
        if UnitExists("target") and WT.IsFriend("target") and not WT.IsDead("target") then
            if unit == "target" then return true end
            if type(UnitIsUnit) == "function" then
                local ok, same = pcall(UnitIsUnit, unit, "target")
                if ok and same == true then return true end
            end
            return false
        end
        return true
    end
    if mode == 4 then return WT.IsTank(unit) end
    if mode == 5 then return not WT.IsTank(unit) end
    if mode >= 6 and mode <= 10 then
        local want = mode - 5
        local sub = WT.SubgroupOf(unit)
        -- 读不到小队编号时不做限制（宁可治全团，也不能把治疗停掉）
        if sub == nil then return true end
        return sub == want
    end
    return true
end

-- 可治疗的候选单位（活、40 码内、符合治疗模式）
function WT.IsHealable(unit)
    if not UnitExists(unit) or WT.IsDead(unit) then return false end
    if not WT.IsFriend(unit) then return false end
    local range = WT.RangeOf(unit)
    if range ~= nil and range > 40 then return false end
    return WT.ModeAllowed(unit)
end

-- 返回符合条件的最低血单位（低于 threshold）
function WT.LowestBelow(threshold)
    local best, bestHP = nil, threshold
    for _, u in ipairs(WT.GroupUnits()) do
        if WT.IsHealable(u) then
            local hp = WT.HP(u)
            if hp > 0 and hp < bestHP then
                best, bestHP = u, hp
            end
        end
    end
    return best, bestHP
end

-- 统计低于 threshold 的可治疗人数
function WT.CountBelow(threshold)
    local n = 0
    for _, u in ipairs(WT.GroupUnits()) do
        if WT.IsHealable(u) then
            local hp = WT.HP(u)
            if hp > 0 and hp < threshold then n = n + 1 end
        end
    end
    return n
end

-- 迅捷治愈需要目标身上有回春术或愈合
function WT.HasHot(unit)
    if WT.UnitBuffRemain(unit, "回春术") > 0 then return true end
    if WT.UnitBuffRemain(unit, "愈合") > 0 then return true end
    return false
end

-- 把治疗目标设为焦点（[ @focus ] 宏槽施放）
function WT.FocusOn(unit)
    if not unit then return false end
    if UnitExists("focus") and type(UnitIsUnit) == "function" then
        local ok, same = pcall(UnitIsUnit, "focus", unit)
        if ok and same == true then return true end
    end
    if type(FocusUnit) == "function" then
        local ok = pcall(FocusUnit, unit)
        if ok then return true end
    end
    return false
end

-- ============================================================
-- 3. 循环：基础变量 / 停手门 / 收尾清扫
-- ============================================================
function WT.Base()
    GCD = WR_GetGCD("治疗之触")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    WT.TargetOK = UnitExists("target")
        and not UnitIsDeadOrGhost("target")
        and UnitCanAttack("player", "target")
    WT.Casting = WR_SafeCastingName("player")
    WT.Channel = WR_SafeChannelName("player")
    WT.InCombat = UnitAffectingCombat("player")
end

function WT.HideLastShown()
    local lastShown = WR_SoD_ShownSkill
    local rawSlot = WT.RawShownSlot
    if rawSlot ~= nil and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, rawSlot)
    elseif type(lastShown) == "string" and lastShown ~= "" and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, nil)
    end
    WT.RawShownSlot = nil
    WR_SoD_ShownSkill = nil
end

function WT.StopGate()
    if WT.Casting or WT.Channel then return true end
    local stop = UnitIsDeadOrGhost("player")
        or (IsMounted and IsMounted())
        or (UnitInVehicle and UnitInVehicle("player"))
    if not stop then
        local eatDrink = { "喝水", "进食", "饮用", "食物", "饮料", "饮水" }
        if WR_GetUnitBuffTime("player", eatDrink, nil, "NAME") > 0 then stop = true end
    end
    if stop then
        WT.HideLastShown()
        return true
    end
    return false
end

function WT.Sweep()
    if WR_SoD_ShownTick == WR_SoD_TickSeq then return end
    local lastShown = WR_SoD_ShownSkill
    local rawSlot = WT.RawShownSlot
    if rawSlot ~= nil and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, rawSlot)
    elseif type(lastShown) == "string" and lastShown ~= "" and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, nil)
    end
    WT.RawShownSlot = nil
    WR_SoD_ShownSkill = nil
end

-- ============================================================
-- 4. 功能：野性印记 / 荆棘术 / 复生 / 激活
-- ============================================================
function WT.MarkStep()
    if not WT.On("HF_YXYZ", true) then return false end
    if WT.BuffRemain({ "野性印记", "野性赐福" }) > 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "野性印记", true)
        if ok and usable == true then
            if WT.Show("野性印记", 149) then return true end
        end
    end
    return false
end

function WT.ThornsStep()
    if not WT.On("HF_JJS", true) then return false end
    if WT.BuffRemain("荆棘术") > 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "荆棘术", true)
        if ok and usable == true then
            if WT.Show("荆棘术", 150) then return true end
        end
    end
    return false
end

WT.RebirthLast = WT.RebirthLast or 0

function WT.RebirthStep()
    if not WT.On("HF_FS", true) then return false end
    if PigSet and PigSet.ZL_ZDJS == false then return false end
    if WT.Casting or WT.Channel then return false end
    if WT.IsDead("player") then return false end
    local now = GetTime()
    if now - WT.RebirthLast < 2.0 then return false end
    local targetUnit
    for _, u in ipairs(WT.GroupUnits()) do
        if u ~= "player" and WT.IsDead(u) then
            local range = WT.RangeOf(u)
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
            if WT.Show("复生", 13) then
                WT.RebirthLast = now
                return true
            end
        end
    end
    return false
end

function WT.ActivateStep()
    if not WT.On("HF_JH_ON", true) then return false end
    local threshold = WT.Val("HF_JH_HP", 20)
    if threshold <= 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "激活", true)
        if not ok or usable ~= true then return false end
    end
    if WT.MP("player") < threshold / 100 then
        if WT.ShowSlot(93, "激活") then return true end
    end
    if UnitExists("focus") and WT.IsFriend("focus") and not WT.IsDead("focus") then
        if WT.MP("focus") < threshold / 100 then
            if WT.ShowSlot(103, "激活") then return true end
        end
    end
    return false
end

-- ============================================================
-- 5. 功能：切换目标
-- ============================================================
WT.LastTab = WT.LastTab or 0

function WT.TabStep()
    if not WT.On("HF_TAB", true) then return false end
    if not UnitAffectingCombat("player") then return false end
    if WT.TargetOK then return false end
    if WR_CanTab ~= nil and not WR_CanTab() then return false end
    local now = GetTime()
    if now - WT.LastTab < 1.0 then return false end
    if WT.Show("切目标", 46) then
        WT.LastTab = now
        return true
    end
    return false
end

-- ============================================================
-- 6. 功能：驱散（解除诅咒：自己 → 焦点 → 队友）
-- ============================================================
WT.DecurseLast = WT.DecurseLast or 0

function WT.DecurseStep()
    if not WT.On("HF_QS_ON", true) then return false end
    if WT.HasCurse("player") then
        if WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, "解除诅咒", true)
            if ok and usable == true then
                if WT.ShowSlot(75, "解除诅咒") then return true end
            end
        end
    end
    if UnitExists("focus") and WT.IsFriend("focus") and WT.HasCurse("focus") then
        if WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, "解除诅咒", true)
            if ok and usable == true then
                if WT.ShowSlot(74, "解除诅咒") then return true end
            end
        end
    end
    local now = GetTime()
    if now - WT.DecurseLast < 1.0 then return false end
    local targetUnit
    for _, u in ipairs(WT.GroupUnits()) do
        if u ~= "player" and u ~= "focus" and WT.HasCurse(u) then
            local range = WT.RangeOf(u)
            if range == nil or range <= 40 then targetUnit = u; break end
        end
    end
    if not targetUnit then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "解除诅咒", true)
        if ok and usable == true then
            if type(FocusUnit) == "function" then pcall(FocusUnit, targetUnit) end
            if WT.ShowSlot(74, "解除诅咒") then
                WT.DecurseLast = now
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 7. 插入：宁静（一次性，放完自关）
-- ============================================================
function WT.InsertStep()
    if not WT.On("HF_NJ_CR", false) then return false end
    if WT.Casting or WT.Channel then return false end
    local need = WT.InRaid() and 4 or 3
    if WT.CountBelow(0.45) < need then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "宁静", true)
        if ok and usable == true then
            if WT.Show("宁静", 64) then
                PigSet.HF_NJ_CR = false
                WT.SyncCheckbox("HF_NJ_CR")
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 8. 自保：喝红药（血低于拉条）
-- ============================================================
function WT.SelfPreserve()
    if WT.HP("player") >= WT.Val("HF_HXY", 30) / 100 then return false end
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
-- 9. 战斗门（防ADD）：FANG_ADD_HF 1=是 2=否
--    是：只有自己在战斗中才进入治疗循环
--    否：任一队友在战斗中也进入治疗循环
-- ============================================================
function WT.CombatGate()
    if UnitAffectingCombat("player") then return true end
    if WT.Val("FANG_ADD_HF", 1) == 1 then return false end
    for _, u in ipairs(WT.GroupUnits()) do
        if UnitAffectingCombat(u) then return true end
    end
    return false
end

-- ============================================================
-- 10. 爆发：种族爆发
-- ============================================================
function WT.BurstStep()
    if not WT.On("HF_ZDZZ", true) then return false end
    local fn = WR_Forever_GetRacialBursts or WR_Forever_PlayerRacialBursts
    if type(fn) ~= "function" then return false end
    local okB, bursts = pcall(fn)
    if not okB or type(bursts) ~= "table" then return false end
    for i = 1, #bursts do
        local name = bursts[i]
        if type(name) == "string" and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, name, true)
            if ok and usable == true then
                if WT.Show("种族爆发", 181) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 11. 治疗链：迅捷治触 → 迅捷治愈 → 野性成长 → 回春术 →
--     治疗之触 → 愈合
-- ============================================================
function WT.HealShow(spell, slot, unit)
    if not unit then return false end
    if not WT.FocusOn(unit) then return false end
    -- ★ 同一技能在色表里还有「普通/焦点」两个槽（治疗之触 83/104、愈合 80/110），
    --   治疗链必须走焦点槽，所以这里直接按槽位点亮，绕开色表的名字解析。
    return WT.ShowSlot(slot, spell)
end

-- 迅捷治触：自然迅捷 + 治疗之触（急救）
function WT.SwiftTendStep()
    local threshold = WT.Val("HF_ZRXJ_HP", 30)
    if threshold <= 0 then return false end
    local unit = WT.LowestBelow(threshold / 100)
    if not unit then return false end
    if WR_SpellUsable ~= nil then
        local ok1, usable1 = pcall(WR_SpellUsable, "自然迅捷", true)
        if not ok1 or usable1 ~= true then return false end
        local ok2, usable2 = pcall(WR_SpellUsable, "治疗之触", true)
        if not ok2 or usable2 ~= true then return false end
    end
    return WT.HealShow("迅捷治触", 112, unit)
end

-- 迅捷治愈：目标身上有回春术/愈合时才能瞬发治疗
function WT.SwiftmendStep()
    local threshold = WT.Val("HF_XJZY", 50)
    if threshold <= 0 then return false end
    local unit = WT.LowestBelow(threshold / 100)
    if not unit then return false end
    if not WT.HasHot(unit) then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "迅捷治愈", true)
        if not ok or usable ~= true then return false end
    end
    return WT.HealShow("迅捷治愈", 111, unit)
end

-- 野性成长：群体 HOT（低血人数≥2 且最低血<阈值，或单人 <50%）
function WT.WildGrowthStep()
    local threshold = WT.Val("HF_YZCZ", 80)
    if threshold <= 0 then return false end
    local unit, hp = WT.LowestBelow(threshold / 100)
    if not unit then return false end
    local lowN = WT.CountBelow(threshold / 100)
    if lowN < 2 and hp > 0.50 then return false end
    if not WT.SpellKnown("野性成长") then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "野性成长", true)
        if not ok or usable ~= true then return false end
    end
    return WT.HealShow("野性成长", 107, unit)
end

-- 回春术：HOT 覆盖
function WT.RejuvenationStep()
    local threshold = WT.Val("HF_HCS", 95)
    if threshold <= 0 then return false end
    local unit = WT.LowestBelow(threshold / 100)
    if not unit then return false end
    if WT.UnitBuffRemain(unit, "回春术") > 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "回春术", true)
        if not ok or usable ~= true then return false end
    end
    return WT.HealShow("回春术", 109, unit)
end

-- 治疗之触：大治疗
function WT.HealingTouchStep()
    local threshold = WT.Val("HF_ZLZC", 60)
    if threshold <= 0 then return false end
    local unit = WT.LowestBelow(threshold / 100)
    if not unit then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "治疗之触", true)
        if not ok or usable ~= true then return false end
    end
    return WT.HealShow("治疗之触", 104, unit)
end

-- 愈合：中治疗（也补 HOT）
function WT.RegrowthStep()
    local threshold = WT.Val("HF_YH_HP", 85)
    if threshold <= 0 then return false end
    local unit = WT.LowestBelow(threshold / 100)
    if not unit then return false end
    if WT.UnitBuffRemain(unit, "愈合") > 0 and WT.HP(unit) > 0.60 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "愈合", true)
        if not ok or usable ~= true then return false end
    end
    return WT.HealShow("愈合", 110, unit)
end

-- ============================================================
-- 12. 主循环：功能 → 插入 → 自保 → 切目标 → 战斗门 → 爆发 → 治疗链
-- ============================================================
function WT.Run()
    WT.InitDefaults()
    local handled = false
    repeat
        WT.Base()
        if WT.StopGate() then break end
        if WT.MarkStep() then handled = true; break end
        if WT.ThornsStep() then handled = true; break end
        if WT.RebirthStep() then handled = true; break end
        if WT.ActivateStep() then handled = true; break end
        if WT.DecurseStep() then handled = true; break end
        if WT.InsertStep() then handled = true; break end
        if WT.SelfPreserve() then handled = true; break end
        if WT.TabStep() then handled = true; break end
        if not WT.CombatGate() then break end
        if WT.BurstStep() then handled = true; break end
        if WT.SwiftTendStep() then handled = true; break end
        if WT.SwiftmendStep() then handled = true; break end
        if WT.WildGrowthStep() then handled = true; break end
        if WT.RejuvenationStep() then handled = true; break end
        if WT.HealingTouchStep() then handled = true; break end
        if WT.RegrowthStep() then handled = true; break end
    until true
    if not handled then WT.Sweep() end
    return handled
end

-- ============================================================
-- 13. 右键「额外条件」小窗（激活阈值）
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

WT.PopupDefs = {
    HF_JH_ON = {
        title = "激活  功能",
        width = 340,
        desc = "开着时，自己蓝量低于阈值就用激活；焦点是队友且蓝量低于阈值时给焦点激活。\n\n"
            .. "阈值 0 = 不自动激活。\n"
            .. "宏：/DRUID_RESTORE_INNERVATE 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "HF_JH_ON", label = "激活", default = true },
            { type = "slider", var = "HF_JH_HP", label = "蓝量阈值", default = 20, suffix = "%", minv = 0, maxv = 100, indent = 18 },
        },
    },
}

local function BuildPopup(key)
    local def = WT.PopupDefs[key]
    if not def then return nil end
    local width = def.width or 360
    local f = CreateFrame("Frame", "WR_DruidRestorationPopup_" .. key, UIParent, "BackdropTemplate")
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
        if rowDef.type == "check" then
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + indent, y)
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            cb:SetChecked(PigSet[rowDef.var] == true)
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95, 220)
            label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            cb:SetScript("OnClick", function(self)
                PigSet[rowDef.var] = self:GetChecked() and true or false
                WT.SyncCheckbox(rowDef.var)
            end)
            rows[#rows + 1] = { kind = "check", row = rowDef, control = cb }
            addRow(26)
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
            local val = WT.Num(PigSet[rowDef.var], rowDef.default or 0)
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
                local v = WT.Num(PigSet[rec.row.var], rec.row.default or 0)
                rec.control:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            end
        end
    end
    return f
end

WT.PopupCache = WT.PopupCache or {}

function WT.ShowOptions(key)
    WT.InitDefaults()
    local def = WT.PopupDefs[key]
    if not def then return end
    local f = WT.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        WT.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(WT.PopupCache) do
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
-- 14. 爆发按钮（面板 onClick）
-- ============================================================
function WR_DruidRestorationBurstAllOn()
    if type(PigSet) ~= "table" then return end
    PigSet.HF_ZDZZ = true
    WT.SyncCheckbox("HF_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cff00ff00[恢复]|r 爆发已全部打开") end
end

function WR_DruidRestorationBurstAllOff()
    if type(PigSet) ~= "table" then return end
    PigSet.HF_ZDZZ = false
    WT.SyncCheckbox("HF_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cffff5040[恢复]|r 爆发已全部关闭") end
end

function WR_DruidRestorationBurstToggle()
    if type(PigSet) ~= "table" then return end
    if PigSet.HF_ZDZZ == true then
        WR_DruidRestorationBurstAllOff()
    else
        WR_DruidRestorationBurstAllOn()
    end
end

-- ============================================================
-- 15. 斜杠命令
-- ============================================================
local function ToggleSwitch(var, label)
    if type(PigSet) ~= "table" then return end
    PigSet[var] = not (PigSet[var] == true)
    WT.SyncCheckbox(var)
    print("|cff00ff00[" .. label .. "]|r " .. (PigSet[var] and "开启" or "关闭"))
end

SLASH_DRUID_RESTORE_INNERVATE1 = "/DRUID_RESTORE_INNERVATE"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_RESTORE_INNERVATE"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.HF_JH_ON = true; WT.SyncCheckbox("HF_JH_ON")
        elseif msg == "off" then PigSet.HF_JH_ON = false; WT.SyncCheckbox("HF_JH_ON")
        else ToggleSwitch("HF_JH_ON", "激活") end
    end
end

SLASH_DRUID_RESTORE_THORNS1 = "/DRUID_RESTORE_THORNS"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_RESTORE_THORNS"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.HF_JJS = true; WT.SyncCheckbox("HF_JJS")
        elseif msg == "off" then PigSet.HF_JJS = false; WT.SyncCheckbox("HF_JJS")
        else ToggleSwitch("HF_JJS", "荆棘术") end
    end
end

SLASH_DRUID_RESTORE_MARK1 = "/DRUID_RESTORE_MARK"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_RESTORE_MARK"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.HF_YXYZ = true; WT.SyncCheckbox("HF_YXYZ")
        elseif msg == "off" then PigSet.HF_YXYZ = false; WT.SyncCheckbox("HF_YXYZ")
        else ToggleSwitch("HF_YXYZ", "野性印记") end
    end
end

SLASH_DRUID_RESTORE_NJ1 = "/DRUID_RESTORE_NJ"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_RESTORE_NJ"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.HF_NJ_CR = true; WT.SyncCheckbox("HF_NJ_CR")
        elseif msg == "off" then PigSet.HF_NJ_CR = false; WT.SyncCheckbox("HF_NJ_CR")
        else ToggleSwitch("HF_NJ_CR", "宁静插入") end
    end
end
