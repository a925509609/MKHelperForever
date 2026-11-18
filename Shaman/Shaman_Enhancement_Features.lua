-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "SHAMAN" then return end
-- ============================================================
-- Shaman_Enhancement_Features.lua
-- 增强萨满（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 SHAMAN「增强」专精：不写全局、不影响元素/恢复与其他职业。
-- 共享件 Shaman_Forever.lua 零改动。
--
-- 按「猪猪 / 彼岸花-无限服 · 增强页」截图逐项落地：
--   选择：防ADD / 护盾（闪电之盾 / 水之盾 / 禁用）
--   拉条：喝红药 30% / 漩涡武器 3层 / 打断 60%
--   爆发：全开 / 全关 / 切换按钮 + 种族爆发
--   功能：震击（右键小窗）/ 自动图腾（右键小窗）/ 切换目标 /
--         火焰新星 / 驱散（净化术）
--   插入：呼吸（水下呼吸）/ 元素（元素的召唤）/ 灵魂（灵魂的召唤）/
--         先知（先知之怒）/ 灼热 / 熔岩（一次性，放完自关）
--
-- 【本服 60 级增强技能口径（Data/Forever_SkillRegistry.lua + 法术书）】
--   风暴打击 17364 / 先知之怒 425336 / 烈焰震击 / 地震术 / 大地震击 /
--   闪电箭 / 火焰新星 408345 / 净化术 8012 / 水下呼吸 131 /
--   元素的召唤 66842 / 灵魂的召唤 66844 / 漩涡武器（被动层数）
--   ★ 80 级技能（野性狼魂、萨满之怒、熔岩猛击、熔岩爆裂、潮汐之力等）
--     本服 60 级不存在，本层不引用。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "SHAMAN" then return end

WR_ShamanEnhancementUI = WR_ShamanEnhancementUI or {}
local SE = WR_ShamanEnhancementUI

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ============================================================
SE.Defaults = {
    -- 选择
    SM_ZQ_FADD = 1,           -- 防ADD：1=是 2=否
    SM_ZQ_HD = 3,             -- 护盾：1=水之护盾 2=闪电之盾 3=禁用（截图默认禁用）
    -- 拉条
    SM_ZQ_HXY = 30,           -- 喝红药：血低于 30%
    SM_ZQ_XWWQ = 3,           -- 漩涡武器：层数达到 3 层打闪电箭（0=关闭）
    SM_ZQ_ZDDD = 60,          -- 打断：施法进度达到 60%
    -- 爆发
    SM_ZQ_ZDZZ = true,        -- 种族爆发
    -- 震击（右键小窗）
    SM_ZQ_ZJ_ON = true,       -- 震击顶层开关
    SM_ZQ_ZJ_LYZJ = true,     -- 烈焰震击
    SM_ZQ_ZJ_YJ = 6,          -- 预判：目标预计能活过这么多秒才补（0=都放）
    SM_ZQ_ZJ_DZS = false,     -- 地震术输出
    SM_ZQ_ZJ_LD = false,      -- 震击留打断：震击一个都不输出
    SM_ZQ_ZJ_RANK = 1,        -- 等级：1=满级 2=1级
    -- 自动图腾（组开关 + 每系勾选的图腾）
    SM_ZQ_TT_ON = true,       -- 自动图腾
    SM_ZQ_TT_FIRE = true,     -- 火系
    SM_ZQ_TT_ZR = true,       --   灼热图腾
    SM_ZQ_TT_RY = true,       --   熔岩图腾
    SM_ZQ_TT_HS = false,      --   火舌图腾
    SM_ZQ_TT_KH = false,      --   抗寒图腾
    SM_ZQ_TT_EARTH = true,    -- 土系
    SM_ZQ_TT_DDZL = true,     --   大地之力图腾
    SM_ZQ_TT_ST = false,      --   石肤图腾
    SM_ZQ_TT_DF = false,      --   地缚图腾
    SM_ZQ_TT_ZL = false,      --   战栗图腾
    SM_ZQ_TT_WATER = true,    -- 水系
    SM_ZQ_TT_FLZQ = true,     --   法力之泉图腾
    SM_ZQ_TT_ZLQ = false,     --   治疗之泉图腾
    SM_ZQ_TT_QD = false,      --   清毒图腾
    SM_ZQ_TT_QB = false,      --   祛病图腾
    SM_ZQ_TT_KF = false,      --   抗火图腾
    SM_ZQ_TT_AIR = true,      -- 风系
    SM_ZQ_TT_FN = true,       --   风怒图腾
    SM_ZQ_TT_FZY = false,     --   风之优雅图腾
    SM_ZQ_TT_GJ = false,      --   根基图腾
    SM_ZQ_TT_ZRKX = false,    --   自然抗性图腾
    -- 功能
    SM_ZQ_TAB = true,         -- 切换目标
    SM_ZQ_HXX = true,         -- 火焰新星
    SM_ZQ_QS = true,          -- 驱散（净化术）
    -- 插入（一次性，默认关）
    SM_ZQ_CRHX = false,       -- 呼吸：水下呼吸
    SM_ZQ_CRYS = false,       -- 元素：元素的召唤
    SM_ZQ_CRLH = false,       -- 灵魂：灵魂的召唤
    SM_ZQ_CRXZ = false,       -- 先知：先知之怒
    SM_ZQ_CRZR = false,       -- 灼热：灼热图腾
    SM_ZQ_CRRY = false,       -- 熔岩：熔岩图腾
}

-- 图腾组定义（GetTotemInfo 槽位：1火 2土 3水 4风）
SE.Totems = {
    { group = "SM_ZQ_TT_FIRE",  slot = 1, items = {
        { var = "SM_ZQ_TT_ZR",   spell = "灼热图腾",     color = 45, dur = 60 },
        { var = "SM_ZQ_TT_RY",   spell = "熔岩图腾",     color = 6,  dur = 60 },
        { var = "SM_ZQ_TT_HS",   spell = "火舌图腾",     color = 96, dur = 120 },
        { var = "SM_ZQ_TT_KH",   spell = "抗寒图腾",     color = 95, dur = 120 },
    } },
    { group = "SM_ZQ_TT_EARTH", slot = 2, items = {
        { var = "SM_ZQ_TT_DDZL", spell = "大地之力图腾", color = 15, dur = 120 },
        { var = "SM_ZQ_TT_ST",   spell = "石肤图腾",     color = 85, dur = 120 },
        { var = "SM_ZQ_TT_DF",   spell = "地缚图腾",     color = 86, dur = 45 },
        { var = "SM_ZQ_TT_ZL",   spell = "战栗图腾",     color = 33, dur = 120 },
    } },
    { group = "SM_ZQ_TT_WATER", slot = 3, items = {
        { var = "SM_ZQ_TT_FLZQ", spell = "法力之泉图腾", color = 105, dur = 60 },
        { var = "SM_ZQ_TT_ZLQ",  spell = "治疗之泉图腾", color = 106, dur = 60 },
        { var = "SM_ZQ_TT_QD",   spell = "清毒图腾",     color = 87,  dur = 120 },
        { var = "SM_ZQ_TT_QB",   spell = "祛病图腾",     color = 88,  dur = 120 },
        { var = "SM_ZQ_TT_KF",   spell = "抗火图腾",     color = 91,  dur = 120 },
    } },
    { group = "SM_ZQ_TT_AIR",   slot = 4, items = {
        { var = "SM_ZQ_TT_FN",   spell = "风怒图腾",     color = 92,  dur = 120 },
        { var = "SM_ZQ_TT_FZY",  spell = "风之优雅图腾", color = 93,  dur = 120 },
        { var = "SM_ZQ_TT_GJ",   spell = "根基图腾",     color = 55,  dur = 45 },
        { var = "SM_ZQ_TT_ZRKX", spell = "自然抗性图腾", color = 94,  dur = 120 },
    } },
}

-- 插入（一次性，放完自关）
SE.Inserts = {
    { var = "SM_ZQ_CRHX", spell = "水下呼吸",   color = 107 },
    { var = "SM_ZQ_CRYS", spell = "元素的召唤", color = 2 },
    { var = "SM_ZQ_CRLH", spell = "灵魂的召唤", color = 39 },
    { var = "SM_ZQ_CRXZ", spell = "先知之怒",   color = 61 },
    { var = "SM_ZQ_CRZR", spell = "灼热图腾",   color = 45 },
    { var = "SM_ZQ_CRRY", spell = "熔岩图腾",   color = 6 },
}

SE.Migrated = SE.Migrated or false

function SE.InitDefaults()
    if type(PigSet) ~= "table" then return end
    if not SE.Migrated then
        SE.Migrated = true
        -- 旧「防ADD」：菜单 FANG_ADD_ZQS（1=是 2=否）或旧循环 FANG_ADD_SM（布尔）
        if PigSet.SM_ZQ_FADD == nil then
            local old = tonumber(PigSet.FANG_ADD_ZQS)
            if old == 1 or old == 2 then
                PigSet.SM_ZQ_FADD = old
            elseif PigSet.FANG_ADD_SM == false then
                PigSet.SM_ZQ_FADD = 2
            end
        end
        -- 旧「漩涡层数」下拉（1=5层 2=4层 3=3层 4=2层）→ 新层数数字
        if PigSet.SM_ZQ_XWWQ == nil then
            local old = tonumber(PigSet.SM_ZQ_XWWQCS)
            if old == 1 then PigSet.SM_ZQ_XWWQ = 5
            elseif old == 2 then PigSet.SM_ZQ_XWWQ = 4
            elseif old == 3 then PigSet.SM_ZQ_XWWQ = 3
            elseif old == 4 then PigSet.SM_ZQ_XWWQ = 2 end
        end
        -- 旧「自动火焰新星」→ 新「火焰新星」
        if PigSet.SM_ZQ_HXX == nil and PigSet.SM_ZQ_ZDHYXX ~= nil then
            PigSet.SM_ZQ_HXX = PigSet.SM_ZQ_ZDHYXX == true
        end
        -- 旧「可以驱散任何魔法」→ 新「驱散」
        if PigSet.SM_ZQ_QS == nil and PigSet.SM_ZQ_ZDQS ~= nil then
            PigSet.SM_ZQ_QS = PigSet.SM_ZQ_ZDQS == true
        end
        -- 旧「火系图腾」下拉（1=熔岩 2=灼热 3=不插）→ 新自动图腾火系
        if PigSet.SM_ZQ_TT_FIRE == nil and PigSet.SM_ZQ_HXTT ~= nil then
            local old = tonumber(PigSet.SM_ZQ_HXTT)
            PigSet.SM_ZQ_TT_FIRE = (old ~= 3)
            PigSet.SM_ZQ_TT_RY = (old == 1)
            PigSet.SM_ZQ_TT_ZR = (old == 2)
        end
        -- 旧「自动根基图腾」→ 新风系根基图腾
        if PigSet.SM_ZQ_TT_GJ == nil and PigSet.SM_ZQ_GJTT ~= nil then
            PigSet.SM_ZQ_TT_GJ = PigSet.SM_ZQ_GJTT == true
            if PigSet.SM_ZQ_TT_GJ then PigSet.SM_ZQ_TT_FN = false end
        end
        -- 旧「切目标」沿用同名变量，无需迁移
    end
    for k, v in pairs(SE.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
end

-- ============================================================
-- 2. 安全读取小工具
-- ============================================================
function SE.Num(v, d)
    local n = tonumber(v)
    if n == nil then return d end
    return n
end

function SE.Bool(v, d)
    if v == nil then return d end
    return v == true
end

function SE.On(var, default)
    return SE.Bool(PigSet and PigSet[var], default)
end

function SE.Val(var, default)
    return SE.Num(PigSet and PigSet[var], default)
end

function SE.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
end

function SE.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, known = pcall(WR_Forever_IsSpellKnown, name)
        if ok then return known == true end
    end
    return true
end

function SE.CanCast(spell)
    if type(WR_SpellUsable) ~= "function" then return false end
    local ok, usable = pcall(WR_SpellUsable, spell, true)
    return ok and usable == true
end

function SE.Show(spell, slot)
    if WR_ColorFrame_ShowSkill ~= nil then
        return WR_ColorFrame_ShowSkill(spell, slot) == true
    end
    return false
end

function SE.BuffRemain(name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, "player", name)
    if ok then return SE.Num(v, 0) end
    return 0
end

-- 漩涡武器层数
function SE.BuffStacks(name)
    if type(WR_GetUnitBuffCount) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffCount, "player", name)
    if ok then return SE.Num(v, 0) end
    return 0
end

function SE.DebuffRemain(unit, name)
    if type(WR_GetUnitDebuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffTime, unit, name)
    if ok then return SE.Num(v, 0) end
    return 0
end

-- 目标预计存活秒数（读不到返回 nil，按未知处理）
function SE.TargetTTD()
    if type(WR_GetUnitDeathTime) ~= "function" then return nil end
    local ok, v = pcall(WR_GetUnitDeathTime, "target")
    if ok and type(v) == "number" and v > 0 and v < 9999 then return v end
    return nil
end

function SE.IsDead(unit)
    if type(UnitExists) ~= "function" then return false end
    local okE, e = pcall(UnitExists, unit)
    if not okE or e ~= true then return false end
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, dead = pcall(UnitIsDeadOrGhost, unit)
        if ok and dead == true then return true end
    end
    return false
end

function SE.HP(unit)
    if type(WR_GetUnitHP) ~= "function" then return 1 end
    local ok, v = pcall(WR_GetUnitHP, unit)
    if ok then return SE.Num(v, 1) end
    return 1
end

function SE.InCombatNow()
    if type(UnitAffectingCombat) ~= "function" then return false end
    local ok, v = pcall(UnitAffectingCombat, "player")
    return ok and v == true
end

function SE.TargetInCombatNow()
    if type(UnitAffectingCombat) ~= "function" then return false end
    local ok, v = pcall(UnitAffectingCombat, "target")
    return ok and v == true
end

-- 目标有效（存在、可攻击、未死亡）
function SE.TargetValid()
    if type(UnitExists) ~= "function" then return false end
    local okE, exists = pcall(UnitExists, "target")
    if not okE or exists ~= true then return false end
    if type(UnitCanAttack) == "function" then
        local okA, can = pcall(UnitCanAttack, "player", "target")
        if okA and can == false then return false end
    end
    if SE.IsDead("target") then return false end
    return true
end

-- ============================================================
-- 3. 循环：基础变量 / 停手门 / 收尾清扫
-- ============================================================
function SE.Base()
    GCD = WR_GetGCD("风暴打击")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    SE.Casting = nil
    SE.Channel = nil
    if type(WR_SafeCastingName) == "function" then
        local ok, v = pcall(WR_SafeCastingName, "player")
        if ok then SE.Casting = v end
    end
    if type(WR_SafeChannelName) == "function" then
        local ok, v = pcall(WR_SafeChannelName, "player")
        if ok then SE.Channel = v end
    end
end

function SE.HideLastShown()
    local lastShown = WR_SoD_ShownSkill
    if type(lastShown) == "string" and lastShown ~= "" and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, nil)
    end
    WR_SoD_ShownSkill = nil
end

function SE.StopGate()
    if SE.Casting or SE.Channel then return true end
    local stop = SE.IsDead("player")
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
        SE.HideLastShown()
        return true
    end
    return false
end

function SE.Sweep()
    if WR_SoD_ShownTick == WR_SoD_TickSeq then return end
    SE.HideLastShown()
end

-- ============================================================
-- 4. 功能：护盾（闪电之盾 / 水之护盾 / 禁用）
-- ============================================================
function SE.ShieldStep()
    local mode = SE.Val("SM_ZQ_HD", 3)
    if mode == 3 then return false end
    if mode == 2 then
        if SE.BuffRemain("闪电之盾") == 0 and SE.SpellKnown("闪电之盾") and SE.CanCast("闪电之盾") then
            return SE.Show("闪电之盾", 7)
        end
        return false
    end
    if SE.BuffRemain("水之护盾") == 0 and SE.SpellKnown("水之护盾") and SE.CanCast("水之护盾") then
        return SE.Show("水之护盾", 22)
    end
    return false
end

-- ============================================================
-- 5. 插入：呼吸 / 元素 / 灵魂 / 先知 / 灼热 / 熔岩（一次性，放完自关）
-- ============================================================
function SE.InsertStep()
    if SE.Casting or SE.Channel then return false end
    for _, ins in ipairs(SE.Inserts) do
        if SE.On(ins.var, false) and SE.SpellKnown(ins.spell) and SE.CanCast(ins.spell) then
            if SE.Show(ins.spell, ins.color) then
                PigSet[ins.var] = false
                SE.SyncCheckbox(ins.var)
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 6. 自保：喝红药（血低于拉条）
-- ============================================================
function SE.PotionStep()
    if SE.HP("player") >= SE.Val("SM_ZQ_HXY", 30) / 100 then return false end
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
SE.LastTab = SE.LastTab or 0

function SE.TabStep()
    if not SE.On("SM_ZQ_TAB", true) then return false end
    if not SE.InCombatNow() then return false end
    if SE.TargetValid() then return false end
    if WR_CanTab ~= nil and not WR_CanTab() then return false end
    local now = GetTime()
    if now - SE.LastTab < 1.0 then return false end
    if SE.Show("切目标", 90) then
        SE.LastTab = now
        return true
    end
    return false
end

-- ============================================================
-- 8. 战斗门（防ADD）：SM_ZQ_FADD 1=是 2=否
--    是：自己和目标都进入战斗才输出（脱战不开怪）
--    否：目标进入战斗就输出
-- ============================================================
function SE.CombatGate()
    if SE.Val("SM_ZQ_FADD", 1) == 2 then
        return SE.InCombatNow() or SE.TargetInCombatNow()
    end
    return SE.InCombatNow() and SE.TargetInCombatNow()
end

-- ============================================================
-- 9. 自动图腾
--    每系总开关开着、身边（自己的图腾槽）没有该系图腾时，
--    插下这一系勾选的第一个图腾（每系只能插一个）。
-- ============================================================
SE.TotemCastAt = SE.TotemCastAt or {}

if type(CreateFrame) == "function" and not SE.TotemEventHooked then
    SE.TotemEventHooked = true
    local spellSet = {}
    for _, group in ipairs(SE.Totems) do
        for _, item in ipairs(group.items) do
            spellSet[item.spell] = item.dur
        end
    end
    local f = CreateFrame("Frame")
    if f and f.RegisterEvent and f.SetScript then
        pcall(f.RegisterEvent, f, "UNIT_SPELLCAST_SUCCEEDED")
        f:SetScript("OnEvent", function(_, _, unit, _, spellID)
            if unit ~= "player" then return end
            if type(GetSpellInfo) ~= "function" or type(spellID) ~= "number" then return end
            local ok, name = pcall(GetSpellInfo, spellID)
            if ok and name and spellSet[name] then
                SE.TotemCastAt[name] = GetTime()
            end
        end)
    end
end

function SE.TotemActive(group, item)
    if type(GetTotemInfo) == "function" then
        local ok, have = pcall(GetTotemInfo, group.slot)
        if ok and have == true then return true end
    end
    local at = SE.TotemCastAt[item.spell]
    if type(at) == "number" and (GetTime() - at) < (item.dur or 60) then return true end
    return false
end

function SE.TotemStep()
    if not SE.On("SM_ZQ_TT_ON", true) then return false end
    if SE.Casting or SE.Channel then return false end
    if type(IsMounted) == "function" then
        local ok, m = pcall(IsMounted)
        if ok and m then return false end
    end
    for _, group in ipairs(SE.Totems) do
        if SE.On(group.group, true) then
            for _, item in ipairs(group.items) do
                if SE.On(item.var, false) then
                    if SE.SpellKnown(item.spell) and SE.CanCast(item.spell)
                       and not SE.TotemActive(group, item) then
                        if SE.Show(item.spell, item.color) then return true end
                    end
                    break
                end
            end
        end
    end
    return false
end

-- ============================================================
-- 10. 爆发：种族爆发
-- ============================================================
function SE.BurstStep()
    if not SE.On("SM_ZQ_ZDZZ", true) then return false end
    local fn = WR_Forever_GetRacialBursts or WR_Forever_PlayerRacialBursts
    if type(fn) ~= "function" then return false end
    local okB, bursts = pcall(fn)
    if not okB or type(bursts) ~= "table" then return false end
    for i = 1, #bursts do
        local name = bursts[i]
        if type(name) == "string" and SE.CanCast(name) then
            if SE.Show("种族爆发", 181) then return true end
        end
    end
    return false
end

-- ============================================================
-- 11. 打断：目标施法进度达到拉条阈值 → 风剪
-- ============================================================
function SE.InterruptStep()
    local threshold = SE.Val("SM_ZQ_ZDDD", 60)
    if threshold <= 0 then return false end
    if type(WR_GetCastProgress) ~= "function" then return false end
    local ok, prog = pcall(WR_GetCastProgress, "target")
    if not ok or type(prog) ~= "number" or prog < threshold then return false end
    if SE.CanCast("风剪") then
        return SE.Show("风剪", 17)
    end
    return false
end

-- ============================================================
-- 12. 功能：驱散（净化术：驱散敌方一个魔法增益）
-- ============================================================
function SE.DispelStep()
    if not SE.On("SM_ZQ_QS", true) then return false end
    if not SE.SpellKnown("净化术") then return false end
    if not SE.CanCast("净化术") then return false end
    if type(WR_UnitBuffType) == "function" then
        local ok, v = pcall(WR_UnitBuffType, "target", "Magic")
        if ok and v == true then
            return SE.Show("净化术", 23)
        end
    end
    return false
end

-- ============================================================
-- 13. 震击（右键小窗口径）：
--     烈焰震击保持（预判秒数）+ 地震术；「震击留打断」时全部让路
-- ============================================================
function SE.ShockStep()
    if not SE.On("SM_ZQ_ZJ_ON", true) then return false end
    if SE.On("SM_ZQ_ZJ_LD", false) then return false end
    local ttd = SE.TargetTTD()
    if SE.On("SM_ZQ_ZJ_LYZJ", true) then
        local predict = SE.Val("SM_ZQ_ZJ_YJ", 6)
        local okTime = (predict <= 0) or (ttd == nil) or (ttd > predict)
        if okTime and SE.DebuffRemain("target", "烈焰震击") == 0 and SE.CanCast("烈焰震击") then
            if SE.Val("SM_ZQ_ZJ_RANK", 1) == 2 then
                return SE.Show("烈焰震击(等级1)", 108)
            end
            return SE.Show("烈焰震击", 5)
        end
    end
    if SE.On("SM_ZQ_ZJ_DZS", false) and SE.CanCast("地震术") then
        return SE.Show("地震术", 109)
    end
    return false
end

-- ============================================================
-- 14. 输出链：风暴打击 → 漩涡武器(闪电箭) → 火焰新星 → 大地震击
-- ============================================================
function SE.StormstrikeStep()
    if SE.CanCast("风暴打击") then
        return SE.Show("风暴打击", 3)
    end
    return false
end

function SE.MaelstromStep()
    local threshold = SE.Val("SM_ZQ_XWWQ", 3)
    if threshold <= 0 then return false end
    if SE.BuffStacks("漩涡武器") < threshold then return false end
    if not SE.CanCast("闪电箭") then return false end
    return SE.Show("闪电箭", 4)
end

function SE.NovaStep()
    if not SE.On("SM_ZQ_HXX", true) then return false end
    if not SE.CanCast("火焰新星") then return false end
    return SE.Show("火焰新星", 26)
end

function SE.EarthShockStep()
    if SE.On("SM_ZQ_ZJ_LD", false) then return false end
    if not SE.CanCast("大地震击") then return false end
    return SE.Show("大地震击", 8)
end

-- ============================================================
-- 15. 主循环：护盾 → 插入 → 自保 → 切目标 → 战斗门 →
--     图腾 → 爆发 → 打断 → 驱散 → 震击 → 风暴打击 →
--     漩涡(闪电箭) → 火焰新星 → 大地震击
-- ============================================================
function SE.Run()
    SE.InitDefaults()
    local handled = false
    repeat
        SE.Base()
        if SE.StopGate() then break end
        if SE.ShieldStep() then handled = true; break end
        if SE.InsertStep() then handled = true; break end
        if SE.PotionStep() then handled = true; break end
        if SE.TabStep() then handled = true; break end
        if not SE.CombatGate() then break end
        if SE.TotemStep() then handled = true; break end
        if SE.BurstStep() then handled = true; break end
        if SE.InterruptStep() then handled = true; break end
        if SE.DispelStep() then handled = true; break end
        if SE.ShockStep() then handled = true; break end
        if SE.StormstrikeStep() then handled = true; break end
        if SE.MaelstromStep() then handled = true; break end
        if SE.NovaStep() then handled = true; break end
        if SE.EarthShockStep() then handled = true; break end
    until true
    if not handled then SE.Sweep() end
    return handled
end

-- ============================================================
-- 16. 右键「额外条件」小窗
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

SE.PopupDefs = {
    SM_ZQ_ZJ_ON = {
        title = "震击  功能",
        width = 320,
        desc = "开着时用震击输出，按右键里的设置放；每个标题前面的勾 = 开不开这一条。\n\n烈焰震击：勾上才放，「预判」= 目标预计能活过这么多秒才补（0 = 都放）。\n\n地震术：要不要用地震术输出。\n\n震击留打断：开着时震击一个都不拿来输出，只留给拉条「打断」。\n\n关掉后不用震击输出（拉条「打断」照常打断）。\n宏：/SHAMAN_SHOCK 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "SM_ZQ_ZJ_ON", label = "震击", default = true },
            { type = "check", var = "SM_ZQ_ZJ_LYZJ", label = "烈焰震击", default = true, indent = 24 },
            { type = "slider", var = "SM_ZQ_ZJ_YJ", label = "预判", default = 6, minv = 0, maxv = 30, suffix = "秒", indent = 48 },
            { type = "check", var = "SM_ZQ_ZJ_DZS", label = "地震术", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_ZJ_LD", label = "震击留打断", default = false, indent = 24 },
            { type = "radio", var = "SM_ZQ_ZJ_RANK", default = 1, options = {
                { text = "满级", value = 1 },
                { text = "1级", value = 2 },
            } },
        },
    },
    SM_ZQ_TT_ON = {
        title = "自动图腾  功能",
        width = 300,
        desc = "开着时，打开后按右键里的设置自动补图腾：火 / 土 / 水 / 风每一系前面的勾是这一系的总开关，勾着的那一系身边没有自己的图腾，就插下这一系选中的那个（每系只能选一个）。\n\n关掉后一个图腾都不自动插（插入「呼吸」「元素」「灵魂」等照常）。\n宏：/SHAMAN_TOTEM 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "SM_ZQ_TT_ON", label = "自动图腾", default = true },
            { type = "check", var = "SM_ZQ_TT_FIRE", label = "火系", default = true },
            { type = "check", var = "SM_ZQ_TT_ZR", label = "灼热", default = true, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_RY", label = "熔岩", default = true, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_HS", label = "火舌", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_KH", label = "抗寒", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_EARTH", label = "土系", default = true },
            { type = "check", var = "SM_ZQ_TT_DDZL", label = "大地之力", default = true, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_ST", label = "石肤", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_DF", label = "地缚", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_ZL", label = "战栗", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_WATER", label = "水系", default = true },
            { type = "check", var = "SM_ZQ_TT_FLZQ", label = "法力之泉", default = true, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_ZLQ", label = "治疗之泉", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_QD", label = "清毒", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_QB", label = "祛病", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_KF", label = "抗火", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_AIR", label = "风系", default = true },
            { type = "check", var = "SM_ZQ_TT_FN", label = "风怒", default = true, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_FZY", label = "风之优雅", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_GJ", label = "根基", default = false, indent = 24 },
            { type = "check", var = "SM_ZQ_TT_ZRKX", label = "自然抗性", default = false, indent = 24 },
        },
    },
}

local function BuildPopup(key)
    local def = SE.PopupDefs[key]
    if not def then return nil end
    local width = def.width or 360
    local f = CreateFrame("Frame", "WR_ShamanEnhancementPopup_" .. key, UIParent, "BackdropTemplate")
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
                SE.SyncCheckbox(rowDef.var)
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
            local val = SE.Num(PigSet[rowDef.var], rowDef.default or 0)
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
                cb:SetChecked(SE.Num(PigSet[rowDef.var], rowDef.default or 1) == opt.value)
                local label = MakeFont(f, opt.text or tostring(opt.value), 12, 0.92, 0.93, 0.95, 200)
                label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
                cb:SetScript("OnClick", function()
                    PigSet[rowDef.var] = opt.value
                    for _, o in ipairs(opts) do
                        if o:GetChecked() and o ~= cb then o:SetChecked(false) end
                    end
                    SE.SyncCheckbox(rowDef.var)
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
                local v = SE.Num(PigSet[rec.row.var], rec.row.default or 0)
                rec.control:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            elseif rec.kind == "radio" then
                rec.control:SetChecked(SE.Num(PigSet[rec.row.var], rec.row.default or 1) == rec.value)
            end
        end
    end
    return f
end

SE.PopupCache = SE.PopupCache or {}

function SE.ShowOptions(key)
    SE.InitDefaults()
    local def = SE.PopupDefs[key]
    if not def then return end
    local f = SE.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        SE.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(SE.PopupCache) do
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
-- 17. 爆发按钮（面板 onClick）
-- ============================================================
function WR_ShamanEnhancementBurstAllOn()
    if type(PigSet) ~= "table" then return end
    PigSet.SM_ZQ_ZDZZ = true
    SE.SyncCheckbox("SM_ZQ_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cff00ff00[增强萨]|r 爆发已全部打开") end
end

function WR_ShamanEnhancementBurstAllOff()
    if type(PigSet) ~= "table" then return end
    PigSet.SM_ZQ_ZDZZ = false
    SE.SyncCheckbox("SM_ZQ_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cffff5040[增强萨]|r 爆发已全部关闭") end
end

function WR_ShamanEnhancementBurstToggle()
    if type(PigSet) ~= "table" then return end
    if PigSet.SM_ZQ_ZDZZ == true then
        WR_ShamanEnhancementBurstAllOff()
    else
        WR_ShamanEnhancementBurstAllOn()
    end
end

-- ============================================================
-- 18. 斜杠命令
--     /SHAMAN_SHOCK 震击开关（增强专属）
--     /SHAMAN_TOTEM 自动图腾（与恢复萨共用，按当前专精分流）
-- ============================================================
local function SE_SetVarByCommand(var, msg, label)
    msg = string.lower(msg or "")
    if msg == "on" then PigSet[var] = true
    elseif msg == "off" then PigSet[var] = false
    elseif msg == "" or msg == "toggle" then PigSet[var] = not (PigSet[var] == true)
    else return end
    SE.SyncCheckbox(var)
    local status = PigSet[var] and "开启" or "关闭"
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cff00ff00[" .. label .. "]|r " .. status) end
end

local function SE_CurrentSpec()
    if type(WR_GetMyTalent) == "function" then
        local ok, v = pcall(WR_GetMyTalent)
        if ok and type(v) == "string" then return v end
    end
    return nil
end

SLASH_SHAMAN_SHOCK1 = "/SHAMAN_SHOCK"
if type(SlashCmdList) == "table" then
    SlashCmdList["SHAMAN_SHOCK"] = function(msg)
        SE_SetVarByCommand("SM_ZQ_ZJ_ON", msg, "震击")
    end
end

-- /SHAMAN_TOTEM：恢复萨已注册（控 SM_HF_TT_ON）。本文件在恢复萨功能层之后加载，
-- 用命令链包一层：当前专精是「增强」时改 SM_ZQ_TT_ON，否则回落恢复萨的处理函数。
if type(SlashCmdList) == "table" then
    local previous = SlashCmdList["SHAMAN_TOTEM"]
    SlashCmdList["SHAMAN_TOTEM"] = function(msg)
        if SE_CurrentSpec() == "增强" then
            SE_SetVarByCommand("SM_ZQ_TT_ON", msg, "自动图腾")
        elseif type(previous) == "function" then
            previous(msg)
        end
    end
end
