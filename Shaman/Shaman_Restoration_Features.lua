-- ============================================================
-- Shaman_Restoration_Features.lua
-- 恢复萨满（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 SHAMAN「恢复」专精：不写全局、不影响元素/增强与其他职业。
-- 共享件 Shaman_Forever.lua 零改动（元素/增强仍走各自实现）。
--
-- 按「猪猪 / 彼岸花-无限服 · 恢复萨满页」截图逐项落地：
--   选择：防ADD / 治疗模式（全团） / 护盾（禁用）
--   拉条：喝红药 30% / 迅捷波 30% / 激流 80% / 治疗链 54% /
--         治疗波 60% / 次级治疗波 85% / 打断 60%
--   爆发：全开 / 全关 / 切换按钮 + 种族爆发
--   功能：自动图腾（右键小窗） / 切换目标 / 驱散（右键小窗）
--   插入：呼唤（元素的召唤） / 元素（火元素图腾） /
--         灵魂（土元素图腾） / 法力潮（法力之潮图腾）（一次性，放完自关）
--
-- 治疗优先级（截图口径）：迅捷波 → 激流 → 治疗链 → 治疗波 → 次级治疗波
-- 治疗链排第 3：在激流后、治疗波前，比治疗波优先，所以要比治疗波拉得低。
--
-- 【本服 60 级恢复技能口径（Data/Forever_SkillRegistry.lua）】
--   治疗波 331 / 次级治疗波 8004 / 治疗链 1064 / 激流 22419 /
--   大地之盾 / 净化灵魂 / 净化术 / 自然迅捷（无限天赋）/
--   法力之潮图腾 / 火元素图腾 / 土元素图腾 / 元素的召唤 / 风剪
--   ★ 80 级 / SoD 技能（治疗之雨、潮汐之力、萨隆邪铁炸弹、狂咒/辛达苟萨
--     机制、过量停条等）本服 60 级不存在，本层不引用。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "SHAMAN" then return end

WR_ShamanRestorationUI = WR_ShamanRestorationUI or {}
local SR = WR_ShamanRestorationUI

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ============================================================
SR.Defaults = {
    -- 选择
    SM_HF_FADD = 1,           -- 防ADD：1=是 2=否
    SM_HF_ZLMS = 1,           -- 治疗模式：1全团 2目标 3预读 4坦克 5脆皮 6~10一~五队
    SM_HF_HD = 3,             -- 护盾：1=水之护盾（自己） 2=大地之盾（坦克维持） 3=禁用
    -- 拉条
    SM_HF_HXY = 30,           -- 喝红药：血低于 30%
    SM_HF_XJB = 30,           -- 迅捷波（自然迅捷+治疗波）：血低于 30%
    SM_HF_JL = 80,            -- 激流：血低于 80%
    SM_HF_ZLL = 54,           -- 治疗链：血低于 54%（截图默认 54%，拉到 0 = 关闭）
    SM_HF_ZLB = 60,           -- 治疗波：血低于 60%
    SM_HF_CJZLB = 85,         -- 次级治疗波：血低于 85%
    SM_HF_ZDDD = 60,          -- 打断：施法进度达到 60%
    -- 功能
    SM_HF_TT_ON = true,       -- 自动图腾
    SM_HF_TAB = true,         -- 切换目标
    SM_HF_QS_ON = true,       -- 驱散（净化灵魂）
    SM_HF_QS_SELF = true,     --   驱散：自己
    SM_HF_QS_PARTY = true,    --   驱散：小队/全团
    -- 爆发
    SM_HF_ZDZZ = true,        -- 种族爆发
    -- 治疗链额外条件（右键小窗）
    SM_HF_ZLL_RANK = 1,       -- 等级：1=最高级 2=1级(40级学) 3=2级(46级学) 4=3级(54级学)
    SM_HF_ZLL_NUM = 1,        -- 人数：1=单人 2~6=至少这么多人掉血
    -- 自动图腾（组开关 + 每系勾选的图腾）
    SM_HF_TT_FIRE = true,     -- 火系
    SM_HF_TT_ZR = true,       --   灼热图腾
    SM_HF_TT_RY = true,       --   熔岩图腾
    SM_HF_TT_HS = false,      --   火舌图腾
    SM_HF_TT_KH = false,      --   抗寒图腾
    SM_HF_TT_EARTH = true,    -- 土系
    SM_HF_TT_DDZL = true,     --   大地之力图腾
    SM_HF_TT_ST = true,       --   石肤图腾
    SM_HF_TT_DF = false,      --   地缚图腾
    SM_HF_TT_ZL = false,      --   战栗图腾
    SM_HF_TT_WATER = true,    -- 水系
    SM_HF_TT_FLZQ = true,     --   法力之泉图腾
    SM_HF_TT_ZLQ = true,      --   治疗之泉图腾
    SM_HF_TT_QD = false,      --   清毒图腾
    SM_HF_TT_QB = false,      --   祛病图腾
    SM_HF_TT_KF = false,      --   抗火图腾
    SM_HF_TT_AIR = true,      -- 风系
    SM_HF_TT_FN = true,       --   风怒图腾
    SM_HF_TT_FZY = false,     --   风之优雅图腾
    SM_HF_TT_GJ = false,      --   根基图腾
    SM_HF_TT_ZRKX = false,    --   自然抗性图腾
    -- 插入（一次性，默认关）
    SM_HF_CRHH = false,       -- 呼唤：元素的召唤
    SM_HF_CRYS = false,       -- 元素：火元素图腾
    SM_HF_CRLH = false,       -- 灵魂：土元素图腾
    SM_HF_CRFLC = false,      -- 法力潮：法力之潮图腾
}

-- 图腾组定义（GetTotemInfo 槽位：1火 2土 3水 4风）
SR.Totems = {
    { group = "SM_HF_TT_FIRE",  slot = 1, items = {
        { var = "SM_HF_TT_ZR",   spell = "灼热图腾",     color = 45, dur = 60 },
        { var = "SM_HF_TT_RY",   spell = "熔岩图腾",     color = 6,  dur = 60 },
        { var = "SM_HF_TT_HS",   spell = "火舌图腾",     color = 96, dur = 120 },
        { var = "SM_HF_TT_KH",   spell = "抗寒图腾",     color = 95, dur = 120 },
    } },
    { group = "SM_HF_TT_EARTH", slot = 2, items = {
        { var = "SM_HF_TT_DDZL", spell = "大地之力图腾", color = 15, dur = 120 },
        { var = "SM_HF_TT_ST",   spell = "石肤图腾",     color = 85, dur = 120 },
        { var = "SM_HF_TT_DF",   spell = "地缚图腾",     color = 86, dur = 45 },
        { var = "SM_HF_TT_ZL",   spell = "战栗图腾",     color = 33, dur = 120 },
    } },
    { group = "SM_HF_TT_WATER", slot = 3, items = {
        { var = "SM_HF_TT_FLZQ", spell = "法力之泉图腾", color = 105, dur = 60 },
        { var = "SM_HF_TT_ZLQ",  spell = "治疗之泉图腾", color = 106, dur = 60 },
        { var = "SM_HF_TT_QD",   spell = "清毒图腾",     color = 87,  dur = 120 },
        { var = "SM_HF_TT_QB",   spell = "祛病图腾",     color = 88,  dur = 120 },
        { var = "SM_HF_TT_KF",   spell = "抗火图腾",     color = 91,  dur = 120 },
    } },
    { group = "SM_HF_TT_AIR",   slot = 4, items = {
        { var = "SM_HF_TT_FN",   spell = "风怒图腾",     color = 92,  dur = 120 },
        { var = "SM_HF_TT_FZY",  spell = "风之优雅图腾", color = 93,  dur = 120 },
        { var = "SM_HF_TT_GJ",   spell = "根基图腾",     color = 55,  dur = 45 },
        { var = "SM_HF_TT_ZRKX", spell = "自然抗性图腾", color = 94,  dur = 120 },
    } },
}

SR.Migrated = SR.Migrated or false

function SR.InitDefaults()
    if type(PigSet) ~= "table" then return end
    -- ★ 旧档迁移必须先于默认值填充（否则旧变量被默认值覆盖）
    if not SR.Migrated then
        SR.Migrated = true
        -- 旧「治疗模式」（1自动/2坦克/3脆皮/4目标）→ 新 1全团 2目标 3预读 4坦克 5脆皮 6~10队
        if PigSet.SM_HF_ZLMS == nil then
            local old = tonumber(PigSet.HF_ZLMS)
            if old == 2 then PigSet.SM_HF_ZLMS = 4
            elseif old == 3 then PigSet.SM_HF_ZLMS = 5
            elseif old == 4 then PigSet.SM_HF_ZLMS = 2
            elseif old ~= nil then PigSet.SM_HF_ZLMS = 1 end
        end
        -- 旧拉条 → 新拉条
        local numMap = {
            { old = "HF_ZRXJ",  nw = "SM_HF_XJB" },
            { old = "HF_JL",    nw = "SM_HF_JL" },
            { old = "HF_ZLL",   nw = "SM_HF_ZLL" },
            { old = "HF_ZLB",   nw = "SM_HF_ZLB" },
            { old = "HF_CJZLB", nw = "SM_HF_CJZLB" },
        }
        for _, m in ipairs(numMap) do
            if PigSet[m.nw] == nil then
                local v = tonumber(PigSet[m.old])
                if v ~= nil then PigSet[m.nw] = math.floor(v) end
            end
        end
        if PigSet.SM_HF_ZDDD == nil then
            local v = tonumber(PigSet.HF_ZDDD)
            if v ~= nil then PigSet.SM_HF_ZDDD = math.floor(v) end
        end
        -- 旧「图腾管理」HF_TT → 新「自动图腾」
        if PigSet.SM_HF_TT_ON == nil and PigSet.HF_TT ~= nil then
            PigSet.SM_HF_TT_ON = PigSet.HF_TT == true
        end
        -- 旧「驱散」下拉（1常规/2优先/3目标/4指向/5禁用）→ 新「驱散」开关
        if PigSet.SM_HF_QS_ON == nil then
            if PigSet.HF_QS_AUTO == true then
                PigSet.SM_HF_QS_ON = false
            else
                local old = tonumber(PigSet.HF_QS)
                if old ~= nil then PigSet.SM_HF_QS_ON = (old ~= 5) end
            end
        end
    end
    for k, v in pairs(SR.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
end

-- ============================================================
-- 2. 安全读取小工具
-- ============================================================
function SR.Num(v, d)
    local n = tonumber(v)
    if n == nil then return d end
    return n
end

function SR.Bool(v, d)
    if v == nil then return d end
    return v == true
end

function SR.On(var, default)
    return SR.Bool(PigSet and PigSet[var], default)
end

function SR.Val(var, default)
    return SR.Num(PigSet and PigSet[var], default)
end

function SR.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
end

function SR.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, known = pcall(WR_Forever_IsSpellKnown, name)
        if ok then return known == true end
    end
    return true
end

function SR.CanCast(spell)
    if type(WR_SpellUsable) ~= "function" then return false end
    local ok, usable = pcall(WR_SpellUsable, spell, true)
    return ok and usable == true
end

function SR.Show(spell, slot)
    if WR_ColorFrame_ShowSkill ~= nil then
        return WR_ColorFrame_ShowSkill(spell, slot) == true
    end
    return false
end

-- 直接按颜色槽位点亮（治疗链走 [@focus] 宏槽，同名技能有多个宏槽时用）
function SR.ShowSlot(slot, text)
    if WR_ColorFrame_Show ~= nil then
        local ok, shown = pcall(WR_ColorFrame_Show, slot, text)
        if ok and shown then
            SR.RawShownSlot = slot
            return true
        end
    end
    return false
end

function SR.BuffRemain(name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, "player", name)
    if ok then return SR.Num(v, 0) end
    return 0
end

function SR.UnitBuffRemain(unit, name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, unit, name)
    if ok then return SR.Num(v, 0) end
    return 0
end

function SR.IsDead(unit)
    if type(UnitExists) ~= "function" then
        local ok, e = pcall(UnitExists, unit)
        if not ok or e ~= true then return false end
    else
        if not UnitExists(unit) then return false end
    end
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, dead = pcall(UnitIsDeadOrGhost, unit)
        if ok and dead == true then return true end
    end
    return false
end

function SR.IsFriend(unit)
    if type(UnitExists) ~= "function" then return false end
    local okE, e = pcall(UnitExists, unit)
    if not okE or e ~= true then return false end
    if type(UnitIsFriend) ~= "function" then return true end
    local ok, friend = pcall(UnitIsFriend, "player", unit)
    return ok and friend == true
end

function SR.InRaid()
    if type(GetNumRaidMembers) ~= "function" then return false end
    local ok, n = pcall(GetNumRaidMembers)
    return ok and type(n) == "number" and n > 0
end

-- 队伍/团队成员（含自己）
function SR.GroupUnits()
    local units = { "player" }
    if SR.InRaid() then
        local ok, n = pcall(GetNumRaidMembers)
        for i = 1, math.min(SR.Num(n, 0), 40) do units[#units + 1] = "raid" .. i end
    else
        if type(GetNumPartyMembers) == "function" then
            local ok, n = pcall(GetNumPartyMembers)
            for i = 1, math.min(SR.Num(n, 0), 4) do units[#units + 1] = "party" .. i end
        end
    end
    return units
end

function SR.HP(unit)
    if type(WR_GetUnitHP) ~= "function" then return 1 end
    local ok, v = pcall(WR_GetUnitHP, unit)
    if ok then return SR.Num(v, 1) end
    return 1
end

function SR.MP(unit)
    if type(WR_GetUnitMP) ~= "function" then return 1 end
    local ok, v = pcall(WR_GetUnitMP, unit)
    if ok then return SR.Num(v, 1) end
    return 1
end

function SR.RangeOf(unit)
    if unit == "player" then return 0 end
    if type(WR_UnitRange) ~= "function" then return nil end
    local ok, r = pcall(WR_UnitRange, unit)
    if ok and type(r) == "number" then return r end
    return nil
end

function SR.IsTank(unit)
    if type(UnitGroupRolesAssigned) == "function" then
        local ok, role = pcall(UnitGroupRolesAssigned, unit)
        if ok and role == "TANK" then return true end
    end
    return false
end

function SR.SubgroupOf(unit)
    if not SR.InRaid() then return 1 end
    if type(UnitInRaid) ~= "function" then return nil end
    local ok, idx = pcall(UnitInRaid, unit)
    if not ok or type(idx) ~= "number" or idx <= 0 then return nil end
    if type(GetRaidRosterInfo) ~= "function" then return nil end
    local ok2, _, _, subgroup = pcall(GetRaidRosterInfo, idx)
    if ok2 and type(subgroup) == "number" then return subgroup end
    return nil
end

-- 治疗模式过滤：1全团 2目标 3预读 4坦克 5脆皮 6~10 一~五队
function SR.ModeAllowed(unit)
    local mode = SR.Val("SM_HF_ZLMS", 1)
    if mode == 1 then return true end
    if mode == 2 or mode == 3 then
        if UnitExists and UnitExists("target") and SR.IsFriend("target") and not SR.IsDead("target") then
            if unit == "target" then return true end
            if type(UnitIsUnit) == "function" then
                local ok, same = pcall(UnitIsUnit, unit, "target")
                if ok and same == true then return true end
            end
            return false
        end
        return true
    end
    if mode == 4 then return SR.IsTank(unit) end
    if mode == 5 then return not SR.IsTank(unit) end
    if mode >= 6 and mode <= 10 then
        local want = mode - 5
        local sub = SR.SubgroupOf(unit)
        -- 读不到小队编号时不做限制（宁可治全团，也不能把治疗停掉）
        if sub == nil then return true end
        return sub == want
    end
    return true
end

-- 可治疗的候选单位（活、40 码内、符合治疗模式）
function SR.IsHealable(unit)
    if not SR.IsFriend(unit) or SR.IsDead(unit) then return false end
    local range = SR.RangeOf(unit)
    if range ~= nil and range > 40 then return false end
    return SR.ModeAllowed(unit)
end

-- 返回符合条件的最低血单位（低于 threshold）
function SR.LowestBelow(threshold)
    local best, bestHP = nil, threshold
    for _, u in ipairs(SR.GroupUnits()) do
        if SR.IsHealable(u) then
            local hp = SR.HP(u)
            if hp > 0 and hp < bestHP then
                best, bestHP = u, hp
            end
        end
    end
    return best, bestHP
end

-- 统计受伤（掉血）的可治疗人数
function SR.CountInjured()
    local n = 0
    for _, u in ipairs(SR.GroupUnits()) do
        if SR.IsHealable(u) then
            local hp = SR.HP(u)
            if hp > 0 and hp < 1 then n = n + 1 end
        end
    end
    return n
end

-- 把治疗目标设为焦点（[@focus] 宏槽施放）
function SR.FocusOn(unit)
    if not unit then return false end
    if type(UnitIsUnit) == "function" and UnitExists and UnitExists("focus") then
        local ok, same = pcall(UnitIsUnit, "focus", unit)
        if ok and same == true then return true end
    end
    if type(WR_FocusUnit) == "function" then
        local ok = pcall(WR_FocusUnit, unit)
        if ok then return true end
    end
    return false
end

-- 第一个坦克（含自己），找不到坦克回退自己
function SR.TankUnit()
    for _, u in ipairs(SR.GroupUnits()) do
        if u ~= "player" and SR.IsTank(u) and not SR.IsDead(u) then return u end
    end
    if SR.IsTank("player") then return "player" end
    return "player"
end

-- ============================================================
-- 3. 循环：基础变量 / 停手门 / 收尾清扫
-- ============================================================
function SR.Base()
    GCD = WR_GetGCD("治疗波")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    SR.Casting = nil
    SR.Channel = nil
    if type(WR_SafeCastingName) == "function" then
        local ok, v = pcall(WR_SafeCastingName, "player")
        if ok then SR.Casting = v end
    end
    if type(WR_SafeChannelName) == "function" then
        local ok, v = pcall(WR_SafeChannelName, "player")
        if ok then SR.Channel = v end
    end
    SR.InCombat = false
    if type(UnitAffectingCombat) == "function" then
        local ok, v = pcall(UnitAffectingCombat, "player")
        SR.InCombat = ok and v == true
    end
end

function SR.HideLastShown()
    local lastShown = WR_SoD_ShownSkill
    local rawSlot = SR.RawShownSlot
    if rawSlot ~= nil and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, rawSlot)
    elseif type(lastShown) == "string" and lastShown ~= "" and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, nil)
    end
    SR.RawShownSlot = nil
    WR_SoD_ShownSkill = nil
end

function SR.StopGate()
    if SR.Casting or SR.Channel then return true end
    local stop = SR.IsDead("player")
    if not stop and type(IsMounted) == "function" then
        local ok, m = pcall(IsMounted)
        if ok and m then stop = true end
    end
    if not stop and type(UnitInVehicle) == "function" then
        local ok, v = pcall(UnitInVehicle, "player")
        if ok and v then stop = true end
    end
    if not stop and type(WR_GetUnitBuffTime) == "function" then
        local ok, v = pcall(WR_GetUnitBuffTime, "player", { "喝水", "进食", "饮用", "食物", "饮料", "饮水" }, nil, "NAME")
        if ok and type(v) == "number" and v > 0 then stop = true end
    end
    if stop then
        SR.HideLastShown()
        return true
    end
    return false
end

function SR.Sweep()
    if WR_SoD_ShownTick == WR_SoD_TickSeq then return end
    SR.HideLastShown()
end

-- ============================================================
-- 4. 功能：护盾（水之护盾自己 / 大地之盾坦克维持 / 禁用）
-- ============================================================
function SR.ShieldStep()
    local mode = SR.Val("SM_HF_HD", 3)
    if mode == 3 then return false end
    if mode == 1 then
        if SR.BuffRemain("水之护盾") == 0 and SR.SpellKnown("水之护盾") and SR.CanCast("水之护盾") then
            return SR.Show("水之护盾", 22)
        end
        return false
    end
    -- mode == 2：大地之盾维持（优先坦克，其次自己）
    if SR.UnitBuffRemain(SR.TankUnit(), "大地之盾") > 0 then return false end
    if not SR.CanCast("大地之盾") then return false end
    if SR.FocusOn(SR.TankUnit()) then
        return SR.ShowSlot(79, "大地之盾")
    end
    return false
end

-- ============================================================
-- 5. 插入：呼唤 / 元素 / 灵魂 / 法力潮（一次性，放完自关）
-- ============================================================
SR.Inserts = {
    { var = "SM_HF_CRHH",  spell = "元素的召唤",   color = 2 },
    { var = "SM_HF_CRYS",  spell = "火元素图腾",   color = 59 },
    { var = "SM_HF_CRLH",  spell = "土元素图腾",   color = 25 },
    { var = "SM_HF_CRFLC", spell = "法力之潮图腾", color = 83 },
}

function SR.InsertStep()
    if SR.Casting or SR.Channel then return false end
    for _, ins in ipairs(SR.Inserts) do
        if SR.On(ins.var, false) and SR.SpellKnown(ins.spell) and SR.CanCast(ins.spell) then
            if SR.Show(ins.spell, ins.color) then
                PigSet[ins.var] = false
                SR.SyncCheckbox(ins.var)
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 6. 自保：喝红药（血低于拉条）
-- ============================================================
function SR.SelfPreserve()
    if SR.HP("player") >= SR.Val("SM_HF_HXY", 30) / 100 then return false end
    if type(WR_Use_ZLYS) == "function" then
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
-- 7. 功能：切换目标
-- ============================================================
SR.LastTab = SR.LastTab or 0

function SR.TabStep()
    if not SR.On("SM_HF_TAB", true) then return false end
    if not SR.InCombat then return false end
    if UnitExists and UnitExists("target") and not SR.IsDead("target")
       and type(UnitCanAttack) == "function" then
        local ok, can = pcall(UnitCanAttack, "player", "target")
        if ok and can == true then return false end
    end
    if WR_CanTab ~= nil and not WR_CanTab() then return false end
    local now = GetTime()
    if now - SR.LastTab < 1.0 then return false end
    if SR.Show("切目标", 90) then
        SR.LastTab = now
        return true
    end
    return false
end

-- ============================================================
-- 8. 战斗门（防ADD）：SM_HF_FADD 1=是 2=否
--    是：只有自己在战斗中才进入治疗循环
--    否：任一队友在战斗中也进入治疗循环
-- ============================================================
function SR.CombatGate()
    if SR.InCombat then return true end
    if SR.Val("SM_HF_FADD", 1) == 1 then return false end
    for _, u in ipairs(SR.GroupUnits()) do
        if type(UnitAffectingCombat) == "function" then
            local ok, v = pcall(UnitAffectingCombat, u)
            if ok and v == true then return true end
        end
    end
    return false
end

-- ============================================================
-- 9. 爆发：种族爆发
-- ============================================================
function SR.BurstStep()
    if not SR.On("SM_HF_ZDZZ", true) then return false end
    local fn = WR_Forever_GetRacialBursts or WR_Forever_PlayerRacialBursts
    if type(fn) ~= "function" then return false end
    local okB, bursts = pcall(fn)
    if not okB or type(bursts) ~= "table" then return false end
    for i = 1, #bursts do
        local name = bursts[i]
        if type(name) == "string" and SR.CanCast(name) then
            if SR.Show("种族爆发", 181) then return true end
        end
    end
    return false
end

-- ============================================================
-- 10. 打断：目标施法进度达到拉条阈值 → 风剪
-- ============================================================
function SR.InterruptStep()
    local threshold = SR.Val("SM_HF_ZDDD", 60)
    if threshold <= 0 then return false end
    if type(WR_GetCastProgress) ~= "function" then return false end
    local ok, prog = pcall(WR_GetCastProgress, "target")
    if not ok or type(prog) ~= "number" or prog < threshold then return false end
    if SR.CanCast("风剪") then
        return SR.Show("风剪", 17)
    end
    return false
end

-- ============================================================
-- 11. 功能：驱散（净化灵魂：魔法 / 诅咒；自己 → 队友）
-- ============================================================
SR.DecurseLast = SR.DecurseLast or 0

function SR.HasDispellable(unit)
    if type(WR_UnitDebuffType) == "function" then
        local okM, m = pcall(WR_UnitDebuffType, unit, "Magic")
        if okM and m == true then return true end
        local okC, c = pcall(WR_UnitDebuffType, unit, "Curse")
        if okC and c == true then return true end
    end
    return false
end

function SR.DispelStep()
    if not SR.On("SM_HF_QS_ON", true) then return false end
    if not SR.SpellKnown("净化灵魂") then return false end
    if not SR.CanCast("净化灵魂") then return false end
    -- 自己
    if SR.On("SM_HF_QS_SELF", true) and SR.HasDispellable("player") then
        if SR.FocusOn("player") then
            return SR.ShowSlot(71, "净化灵魂")
        end
    end
    -- 队友
    if SR.On("SM_HF_QS_PARTY", true) then
        local now = GetTime()
        if now - SR.DecurseLast < 1.0 then return false end
        local targetUnit
        for _, u in ipairs(SR.GroupUnits()) do
            if u ~= "player" and SR.IsHealable(u) and SR.HasDispellable(u) then
                targetUnit = u
                break
            end
        end
        if targetUnit and SR.FocusOn(targetUnit) then
            if SR.ShowSlot(71, "净化灵魂") then
                SR.DecurseLast = now
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 12. 功能：自动图腾
--     每系总开关开着、身边（自己的图腾槽）没有该系图腾时，
--     插下这一系勾选的第一个图腾（每系只能插一个）。
-- ============================================================
SR.TotemCastAt = SR.TotemCastAt or {}

-- 施放成功事件：记录本地图腾时间（GetTotemInfo 不可用时的回退口径）
if type(CreateFrame) == "function" and not SR.TotemEventHooked then
    SR.TotemEventHooked = true
    local spellSet = {}
    for _, group in ipairs(SR.Totems) do
        for _, item in ipairs(group.items) do
            spellSet[item.spell] = item.dur
        end
    end
    spellSet["元素的召唤"] = 120
    local f = CreateFrame("Frame")
    if f and f.RegisterEvent and f.SetScript then
        pcall(f.RegisterEvent, f, "UNIT_SPELLCAST_SUCCEEDED")
        f:SetScript("OnEvent", function(_, _, unit, _, spellID)
            if unit ~= "player" then return end
            if type(GetSpellInfo) ~= "function" or type(spellID) ~= "number" then return end
            local ok, name = pcall(GetSpellInfo, spellID)
            if ok and name and spellSet[name] then
                SR.TotemCastAt[name] = GetTime()
            end
        end)
    end
end

function SR.TotemActive(group, item)
    if type(GetTotemInfo) == "function" then
        local ok, have = pcall(GetTotemInfo, group.slot)
        if ok and have == true then return true end
    end
    local at = SR.TotemCastAt[item.spell]
    if type(at) == "number" and (GetTime() - at) < (item.dur or 60) then return true end
    return false
end

function SR.TotemStep()
    if not SR.On("SM_HF_TT_ON", true) then return false end
    if SR.Casting or SR.Channel then return false end
    if type(IsMounted) == "function" then
        local ok, m = pcall(IsMounted)
        if ok and m then return false end
    end
    for _, group in ipairs(SR.Totems) do
        if SR.On(group.group, true) then
            for _, item in ipairs(group.items) do
                -- 每系取第一个勾选的图腾（每系只能插一个）
                if SR.On(item.var, false) then
                    if SR.SpellKnown(item.spell) and SR.CanCast(item.spell)
                       and not SR.TotemActive(group, item) then
                        if SR.Show(item.spell, item.color) then return true end
                    end
                    break
                end
            end
        end
    end
    return false
end

-- ============================================================
-- 13. 治疗链：迅捷波 → 激流 → 治疗链 → 治疗波 → 次级治疗波
-- ============================================================
function SR.HealShow(slot, text, unit)
    if not unit then return false end
    if not SR.FocusOn(unit) then return false end
    return SR.ShowSlot(slot, text)
end

-- 迅捷波：自然迅捷 + 治疗波（急救）
function SR.SwiftWaveStep()
    local threshold = SR.Val("SM_HF_XJB", 30)
    if threshold <= 0 then return false end
    local unit = SR.LowestBelow(threshold / 100)
    if not unit then return false end
    if not SR.SpellKnown("自然迅捷") then return false end
    if not SR.CanCast("自然迅捷") then return false end
    if not SR.CanCast("治疗波") then return false end
    return SR.HealShow(101, "迅捷波", unit)
end

-- 激流：快疗 HOT
function SR.RiptideStep()
    local threshold = SR.Val("SM_HF_JL", 80)
    if threshold <= 0 then return false end
    local unit = SR.LowestBelow(threshold / 100)
    if not unit then return false end
    if SR.UnitBuffRemain(unit, "激流") > 0 then return false end
    if not SR.CanCast("激流") then return false end
    return SR.HealShow(81, "激流", unit)
end

-- 治疗链：人数=1 单人阈值；人数≥2 至少这么多人掉血且最低几人平均血量低于阈值
function SR.ChainHealUnit()
    local threshold = SR.Val("SM_HF_ZLL", 54)
    if threshold <= 0 then return nil end
    local frac = threshold / 100
    local need = math.max(1, math.floor(SR.Val("SM_HF_ZLL_NUM", 1)))
    if need <= 1 then
        local unit = SR.LowestBelow(frac)
        return unit
    end
    local injured = {}
    for _, u in ipairs(SR.GroupUnits()) do
        if SR.IsHealable(u) then
            local hp = SR.HP(u)
            if hp > 0 and hp < 1 then injured[#injured + 1] = { u = u, hp = hp } end
        end
    end
    table.sort(injured, function(a, b) return a.hp < b.hp end)
    if #injured < need then return nil end
    local sum = 0
    for i = 1, need do sum = sum + injured[i].hp end
    if (sum / need) >= frac then return nil end
    return injured[1].u
end

function SR.ChainHealStep()
    local unit = SR.ChainHealUnit()
    if not unit then return false end
    if not SR.CanCast("治疗链") then return false end
    local rank = math.floor(SR.Val("SM_HF_ZLL_RANK", 1))
    if rank == 2 then
        return SR.HealShow(102, "治疗链(等级1)", unit)
    elseif rank == 3 then
        return SR.HealShow(103, "治疗链(等级2)", unit)
    elseif rank == 4 then
        return SR.HealShow(104, "治疗链(等级3)", unit)
    end
    return SR.HealShow(75, "治疗链", unit)
end

-- 治疗波：大治疗
function SR.HealingWaveStep()
    local threshold = SR.Val("SM_HF_ZLB", 60)
    if threshold <= 0 then return false end
    local unit = SR.LowestBelow(threshold / 100)
    if not unit then return false end
    if not SR.CanCast("治疗波") then return false end
    return SR.HealShow(82, "治疗波", unit)
end

-- 次级治疗波：快疗
function SR.LesserWaveStep()
    local threshold = SR.Val("SM_HF_CJZLB", 85)
    if threshold <= 0 then return false end
    local unit = SR.LowestBelow(threshold / 100)
    if not unit then return false end
    if not SR.CanCast("次级治疗波") then return false end
    return SR.HealShow(76, "次级治疗波", unit)
end

-- ============================================================
-- 14. 主循环：护盾 → 插入 → 自保 → 切目标 → 战斗门 →
--     爆发 → 打断 → 驱散 → 图腾 → 治疗链
-- ============================================================
function SR.Run()
    SR.InitDefaults()
    local handled = false
    repeat
        SR.Base()
        if SR.StopGate() then break end
        if SR.ShieldStep() then handled = true; break end
        if SR.InsertStep() then handled = true; break end
        if SR.SelfPreserve() then handled = true; break end
        if SR.TabStep() then handled = true; break end
        if not SR.CombatGate() then break end
        if SR.BurstStep() then handled = true; break end
        if SR.InterruptStep() then handled = true; break end
        if SR.DispelStep() then handled = true; break end
        if SR.TotemStep() then handled = true; break end
        if SR.SwiftWaveStep() then handled = true; break end
        if SR.RiptideStep() then handled = true; break end
        if SR.ChainHealStep() then handled = true; break end
        if SR.HealingWaveStep() then handled = true; break end
        if SR.LesserWaveStep() then handled = true; break end
    until true
    if not handled then SR.Sweep() end
    return handled
end

-- ============================================================
-- 15. 右键「额外条件」小窗
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

SR.PopupDefs = {
    SM_HF_TT_ON = {
        title = "自动图腾  功能",
        width = 300,
        desc = "开着时，打开后按右键里的设置自动补图腾：火 / 土 / 水 / 风每一系前面的勾是这一系的总开关，勾着的那一系身边没有自己的图腾，就插下这一系选中的那个（每系只能选一个）。\n\n关掉后一个图腾都不自动插（插入『呼唤』『元素』『灵魂』等照常）。\n宏：/SHAMAN_TOTEM 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "SM_HF_TT_ON", label = "自动图腾", default = true },
            { type = "check", var = "SM_HF_TT_FIRE", label = "火系", default = true },
            { type = "check", var = "SM_HF_TT_ZR", label = "灼热", default = true, indent = 24 },
            { type = "check", var = "SM_HF_TT_RY", label = "熔岩", default = true, indent = 24 },
            { type = "check", var = "SM_HF_TT_HS", label = "火舌", default = false, indent = 24 },
            { type = "check", var = "SM_HF_TT_KH", label = "抗寒", default = false, indent = 24 },
            { type = "check", var = "SM_HF_TT_EARTH", label = "土系", default = true },
            { type = "check", var = "SM_HF_TT_DDZL", label = "大地之力", default = true, indent = 24 },
            { type = "check", var = "SM_HF_TT_ST", label = "石肤", default = true, indent = 24 },
            { type = "check", var = "SM_HF_TT_DF", label = "地缚", default = false, indent = 24 },
            { type = "check", var = "SM_HF_TT_ZL", label = "战栗", default = false, indent = 24 },
            { type = "check", var = "SM_HF_TT_WATER", label = "水系", default = true },
            { type = "check", var = "SM_HF_TT_FLZQ", label = "法力之泉", default = true, indent = 24 },
            { type = "check", var = "SM_HF_TT_ZLQ", label = "治疗之泉", default = true, indent = 24 },
            { type = "check", var = "SM_HF_TT_QD", label = "清毒", default = false, indent = 24 },
            { type = "check", var = "SM_HF_TT_QB", label = "祛病", default = false, indent = 24 },
            { type = "check", var = "SM_HF_TT_KF", label = "抗火", default = false, indent = 24 },
            { type = "check", var = "SM_HF_TT_AIR", label = "风系", default = true },
            { type = "check", var = "SM_HF_TT_FN", label = "风怒", default = true, indent = 24 },
            { type = "check", var = "SM_HF_TT_FZY", label = "风之优雅", default = false, indent = 24 },
            { type = "check", var = "SM_HF_TT_GJ", label = "根基", default = false, indent = 24 },
            { type = "check", var = "SM_HF_TT_ZRKX", label = "自然抗性", default = false, indent = 24 },
        },
    },
    SM_HF_ZLL = {
        title = "治疗链  拉条",
        width = 300,
        desc = "右键「人数」是 1 时：要治疗的人（焦点）血量低于这个百分比时放治疗链（先治疗焦点，再跳到附近受伤的队友）。\n\n「人数」是 2 以上时：至少这么多人掉血，并且血量最低的这几个平均血量低于这个百分比才放。\n\n治疗里排第 3：在激流后、治疗波前，比治疗波优先，所以要比治疗波拉得低，否则治疗波放不出来。\n\n拉到 0 = 关闭。\n宏 /SHAMAN_CHAINHEAL 空格<数值> 快速设置",
        rows = {
            { type = "label", text = "治疗链" },
            { type = "radio", var = "SM_HF_ZLL_RANK", label = "等级", default = 1, indent = 18, options = {
                { text = "最高级", value = 1 },
                { text = "1级（40级学）", value = 2 },
                { text = "2级（46级学）", value = 3 },
                { text = "3级（54级学）", value = 4 },
            } },
            { type = "slider", var = "SM_HF_ZLL_NUM", label = "人数", default = 1, minv = 1, maxv = 6, suffix = "人", indent = 18 },
        },
    },
    SM_HF_QS = {
        title = "驱散  功能",
        width = 300,
        desc = "开着时自动用净化灵魂驱散魔法 / 诅咒（净化灵魂一次解一个魔法和一个诅咒）。",
        rows = {
            { type = "check", var = "SM_HF_QS_ON", label = "驱散", default = true },
            { type = "check", var = "SM_HF_QS_SELF", label = "自己", default = true, indent = 24 },
            { type = "check", var = "SM_HF_QS_PARTY", label = "小队 / 全团", default = true, indent = 24 },
        },
    },
}

local function BuildPopup(key)
    local def = SR.PopupDefs[key]
    if not def then return nil end
    local width = def.width or 360
    local f = CreateFrame("Frame", "WR_ShamanRestorationPopup_" .. key, UIParent, "BackdropTemplate")
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

    if def.desc then
        local desc = MakeFont(f, def.desc, 11, 0.78, 0.78, 0.78, contentWidth)
        desc:SetPoint("TOPLEFT", f, "TOPLEFT", 12, y)
        desc:SetSpacing(2)
        local h = 60
        if desc.GetStringHeight then
            local ok, measured = pcall(desc.GetStringHeight, desc)
            if ok and type(measured) == "number" and measured > 0 then h = math.ceil(measured) + 6 end
        end
        y = y - (h + 4)
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
                SR.SyncCheckbox(rowDef.var)
            end)
            rows[#rows + 1] = { kind = "check", row = rowDef, control = cb }
            y = y - 26
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
            local val = SR.Num(PigSet[rowDef.var], rowDef.default or 0)
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
            y = y - 30
        elseif rowDef.type == "radio" then
            if rowDef.label then
                local rl = MakeFont(f, rowDef.label, 12, 0.92, 0.93, 0.95, 110)
                rl:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + indent, y - 2)
                y = y - 24
            end
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            local opts = {}
            for _, opt in ipairs(rowDef.options or {}) do
                local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
                cb:SetSize(20, 20)
                cb:SetPoint("TOPLEFT", f, "TOPLEFT", 18 + indent, y)
                cb:SetChecked(SR.Num(PigSet[rowDef.var], rowDef.default or 1) == opt.value)
                local label = MakeFont(f, opt.text or tostring(opt.value), 12, 0.92, 0.93, 0.95, 200)
                label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
                cb:SetScript("OnClick", function()
                    PigSet[rowDef.var] = opt.value
                    for _, o in ipairs(opts) do
                        if o:GetChecked() and o ~= cb then o:SetChecked(false) end
                    end
                    SR.SyncCheckbox(rowDef.var)
                end)
                opts[#opts + 1] = cb
                rows[#rows + 1] = { kind = "radio", row = rowDef, control = cb, value = opt.value }
                y = y - 24
            end
        elseif rowDef.type == "label" then
            local lb = MakeFont(f, rowDef.text or "", 12, 0.35, 0.75, 0.95, 220)
            lb:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y)
            rows[#rows + 1] = { kind = "label", control = lb }
            y = y - 22
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
                local v = SR.Num(PigSet[rec.row.var], rec.row.default or 0)
                rec.control:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            elseif rec.kind == "radio" then
                rec.control:SetChecked(SR.Num(PigSet[rec.row.var], rec.row.default or 1) == rec.value)
            end
        end
    end
    return f
end

SR.PopupCache = SR.PopupCache or {}

function SR.ShowOptions(key)
    SR.InitDefaults()
    local def = SR.PopupDefs[key]
    if not def then return end
    local f = SR.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        SR.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(SR.PopupCache) do
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
-- 16. 爆发按钮（面板 onClick）
-- ============================================================
function WR_ShamanRestorationBurstAllOn()
    if type(PigSet) ~= "table" then return end
    PigSet.SM_HF_ZDZZ = true
    SR.SyncCheckbox("SM_HF_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cff00ff00[恢复萨]|r 爆发已全部打开") end
end

function WR_ShamanRestorationBurstAllOff()
    if type(PigSet) ~= "table" then return end
    PigSet.SM_HF_ZDZZ = false
    SR.SyncCheckbox("SM_HF_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cffff5040[恢复萨]|r 爆发已全部关闭") end
end

function WR_ShamanRestorationBurstToggle()
    if type(PigSet) ~= "table" then return end
    if PigSet.SM_HF_ZDZZ == true then
        WR_ShamanRestorationBurstAllOff()
    else
        WR_ShamanRestorationBurstAllOn()
    end
end

-- ============================================================
-- 17. 斜杠命令
-- ============================================================
SLASH_SHAMAN_TOTEM1 = "/SHAMAN_TOTEM"
if type(SlashCmdList) == "table" then
    SlashCmdList["SHAMAN_TOTEM"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SM_HF_TT_ON = true
        elseif msg == "off" then PigSet.SM_HF_TT_ON = false
        else PigSet.SM_HF_TT_ON = not (PigSet.SM_HF_TT_ON == true) end
        SR.SyncCheckbox("SM_HF_TT_ON")
        print("|cff00ff00[自动图腾]|r " .. (PigSet.SM_HF_TT_ON and "开启" or "关闭"))
    end
end

SLASH_SHAMAN_CHAINHEAL1 = "/SHAMAN_CHAINHEAL"
if type(SlashCmdList) == "table" then
    SlashCmdList["SHAMAN_CHAINHEAL"] = function(msg)
        local v = tonumber(string.match(msg or "", "%d+"))
        if v == nil then
            print("|cffff5040[治疗链]|r 用法：/SHAMAN_CHAINHEAL <0-100>（0=关闭）")
            return
        end
        v = math.max(0, math.min(100, math.floor(v)))
        PigSet.SM_HF_ZLL = v
        print("|cff00ff00[治疗链]|r 拉条已设为 " .. v .. "%")
    end
end
