-- ============================================================
-- Warrior_Fury_Features.lua
-- 狂怒战士（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 WARRIOR「狂怒」专精，不写全局、不影响武器/防护与其他职业。
--
-- 本文件按「猪猪 / 彼岸花-无限服 · 狂暴页」截图逐项落地：
--   功能：撕裂 / 雷霆挫志 / 血性狂暴 / 破甲攻击 /
--         切姿态 / 战斗怒吼 / 切换目标 / 鲁莽挥击
--   插入：反击风暴 / 鲁莽 / 狂暴之怒（一次性，放完自关）
--   拉条：顺劈斩 / 英勇打击 / 斩杀 / 乘胜追击 / 喝红药 / 打断
--   爆发：鲁莽 / 死亡之愿 / 种族爆发（全开 / 全关 / 切换）
--   额外条件：右键对应图标打开（撕裂/雷霆挫志/血性狂暴/破甲/切姿态/鲁莽挥击）
--
-- 说明：当前客户端为 60 级法术书（2026-11-13 Data_SpellBook）：
--   英勇打击 25286 / 撕裂 11574 / 雷霆一击 11581 / 反击风暴 20230 /
--   乘胜追击 402927 / 战斗怒吼 25289 / 挫志怒吼 11556 / 顺劈斩 20569 /
--   猛击 11605 / 斩杀 20662 / 狂暴之怒 18499 / 狂暴姿态 2458 /
--   拦截 20617 / 旋风斩 1680 / 拳击 6554 / 嗜血 23894 / 鲁莽 1719 /
--   死亡之愿 12328 / 血性狂暴 2687 / 破甲攻击 11597。
--   鲁莽挥击 1329555 为狂怒天赋主动技能（4 次近战额外 5 怒气/次）。
-- ============================================================

if WR_PlayerClass ~= "WARRIOR" then return end

WR_WarriorFuryUI = WR_WarriorFuryUI or {}
local WF = WR_WarriorFuryUI

-- ============================================================
-- 1. 默认值与旧档兼容
-- ------------------------------------------------------------
-- 规则：只补 nil，绝不覆盖用户已有设置；旧勾选 KN_CRFJFB / KN_CRLM
--       迁移到新的插入变量，旧破甲下拉 KN_PJGJ 迁移为新的破甲模式。
-- ============================================================
function WF.InitDefaults()
    if type(PigSet) ~= "table" then return end
    local function setb(k, v) if PigSet[k] == nil then PigSet[k] = v end end
    local function setn(k, v) if type(PigSet[k]) ~= "number" then PigSet[k] = v end end

    -- 主功能开关（按截图：破甲攻击默认关闭，其余默认开启）
    setb("KN_SILIE", true)       -- 撕裂
    setb("KN_LTYJ", true)        -- 雷霆挫志（总开关）
    setb("KN_HXKJ", true)        -- 血性狂暴
    setb("KN_BDPJ", false)       -- 破甲攻击（截图默认不勾）
    setb("KN_QTZ", true)         -- 切姿态
    setb("KN_ZDZH", true)        -- 战斗怒吼
    setb("KN_TAB", true)         -- 切换目标（截图默认勾选）
    setb("KN_LMHJ", true)        -- 鲁莽挥击
    setb("KN_CSZJ_ON", true)     -- 乘胜追击（由拉条控制血量门槛）

    -- 插入（一次性，默认关）
    setb("KN_FJFB_CR", false)    -- 反击风暴
    setb("KN_LM_CR", false)      -- 鲁莽
    setb("KN_KBZN_CR", false)    -- 狂暴之怒

    -- 爆发（默认开启，和截图勾选一致）
    setb("KN_LM", true)          -- 鲁莽
    setb("KN_SWZY", true)        -- 死亡之愿
    setb("KN_ZDZZ", true)        -- 种族爆发

    -- 拉条默认值
    setn("KN_SPZ", 30)           -- 顺劈斩怒气
    setn("KN_YYDJ", 20)          -- 英勇打击怒气
    setn("KN_ZS", 15)            -- 斩杀目标血量
    setn("KN_CSZJ", 70)          -- 乘胜追击自己血量
    setn("KN_HXY", 30)           -- 喝红药血量
    setn("KN_QJ", 60)            -- 打断施法进度

    -- 撕裂额外条件
    setb("KN_SILIE_NO_ELEMENT", true)
    setb("KN_SILIE_NO_MECH", true)
    setb("KN_SILIE_NO_UNDEAD", true)
    setn("KN_SILIE_LEAD", 6)

    -- 雷霆挫志额外条件（雷霆：1=保持 / 2=卡CD / 3=不放；挫志：1=保持 / 2=不放）
    -- 旧档迁移：挫志旧版为 3 档（1=保持 / 2=卡CD / 3=不放），按截图改成 2 档（1=保持 / 2=不放）
    if PigSet.KN_CZ_MODE_V2 == nil then
        local oldAoe = tonumber(PigSet.KN_CZ_AOE_MODE)
        local oldSingle = tonumber(PigSet.KN_CZ_SINGLE_MODE)
        if oldAoe == 1 then PigSet.KN_CZ_AOE_MODE = 1 else PigSet.KN_CZ_AOE_MODE = 2 end
        if oldSingle == 1 then PigSet.KN_CZ_SINGLE_MODE = 1 else PigSet.KN_CZ_SINGLE_MODE = 2 end
        PigSet.KN_CZ_MODE_V2 = true
    end
    setn("KN_LT_AOE_MODE", 3)
    setn("KN_LT_AOE_COUNT", 2)
    setn("KN_LT_MISS", 0)
    setn("KN_LT_SINGLE_MODE", 1)
    setn("KN_CZ_AOE_MODE", 2)
    setn("KN_CZ_AOE_COUNT", 3)
    setn("KN_CZ_MISS", 0)
    setn("KN_CZ_SINGLE_MODE", 2)

    -- 血性狂暴额外条件
    setn("KN_HXKJ_NQ", 90)
    setn("KN_HXKJ_XL", 0)

    -- 破甲攻击额外条件
    setb("KN_PJ_ONLY1", false)
    setb("KN_PJ_HIGH", false)
    setb("KN_PJ_LOW", false)
    setn("KN_PJ_REFRESH", 3)

    -- 切姿态额外条件
    setb("KN_QTZ_OOC", true)
    setb("KN_QTZ_IC", true)

    -- 鲁莽挥击：怒气低于该值才用
    setn("KN_LMHJ_NQ", 70)

    -- 旧档：插入变量改名（KN_CRFJFB -> KN_FJFB_CR，KN_CRLM -> KN_LM_CR）
    -- 注意：上面的 setb 已把新变量补成 false，这里按旧变量 true 做一次性迁移。
    if PigSet.KN_FJFB_MIGRATED == nil then
        if PigSet.KN_CRFJFB == true then PigSet.KN_FJFB_CR = true end
        PigSet.KN_FJFB_MIGRATED = true
    end
    if PigSet.KN_LM_CR_MIGRATED == nil then
        if PigSet.KN_CRLM == true then PigSet.KN_LM_CR = true end
        PigSet.KN_LM_CR_MIGRATED = true
    end

    -- 旧档：破甲下拉（1 优先 / 2 填充 / 3 禁用）迁移到新破甲开关与优先级
    if PigSet.KN_BDPJ_MIGRATED == nil then
        local old = tonumber(PigSet.KN_PJGJ)
        if old == 1 then
            PigSet.KN_BDPJ = true
            PigSet.KN_PJ_HIGH = true
            PigSet.KN_PJ_LOW = false
        elseif old == 2 then
            PigSet.KN_BDPJ = true
            PigSet.KN_PJ_HIGH = false
            PigSet.KN_PJ_LOW = true
        elseif old == 3 then
            PigSet.KN_BDPJ = false
        end
        PigSet.KN_BDPJ_MIGRATED = true
    end
end

WF.InitDefaults()

-- ============================================================
-- 2. 安全读取小工具
-- ============================================================
function WF.Num(v, d)
    if type(v) == "number" then return v end
    return d
end

function WF.Bool(v, d)
    if type(v) == "boolean" then return v end
    return d
end

function WF.On(var, default)
    return WF.Bool(PigSet and PigSet[var], default)
end

function WF.Val(var, default)
    return WF.Num(PigSet and PigSet[var], default)
end

-- 当前姿态：1 战斗 / 2 防御 / 3 狂暴 / 0 未知
function WF.Stance()
    if type(GetShapeshiftForm) == "function" then
        local ok, form = pcall(GetShapeshiftForm)
        if ok and type(form) == "number" and form > 0 then
            if type(GetShapeshiftFormInfo) == "function" then
                local ok2, _, _, _, spellID = pcall(GetShapeshiftFormInfo, form)
                if ok2 and spellID then
                    local ok3, name = pcall(GetSpellInfo, spellID)
                    if ok3 and type(name) == "string" then
                        if name == "战斗姿态" then return 1 end
                        if name == "防御姿态" then return 2 end
                        if name == "狂暴姿态" then return 3 end
                    end
                end
            end
            return form
        end
    end
    if type(WR_GetUnitBuffTime) == "function" then
        if WR_GetUnitBuffTime("player", "防御姿态") > 0 then return 2 end
        if WR_GetUnitBuffTime("player", "战斗姿态") > 0 then return 1 end
        if WR_GetUnitBuffTime("player", "狂暴姿态") > 0 then return 3 end
    end
    return 0
end

function WF.CreatureType()
    if type(WR_SafeCreatureType) == "function" then
        local ok, ct = pcall(WR_SafeCreatureType, "target")
        if ok and type(ct) == "string" then return ct end
    end
    if type(UnitCreatureType) == "function" then
        local ok, ct = pcall(UnitCreatureType, "target")
        if ok and type(ct) == "string" then return ct end
    end
    return nil
end

function WF.IsCreatureTypeExcluded(noElement, noMech, noUndead)
    local ct = WF.CreatureType()
    if not ct then return false end
    if noElement and (ct == "元素" or ct == "Elemental") then return true end
    if noMech and (ct == "机械" or ct == "Mechanical") then return true end
    if noUndead and (ct == "亡灵" or ct == "Undead") then return true end
    return false
end

function WF.TargetExistsAttackable()
    if type(UnitExists) ~= "function" then return false end
    local okEx, exists = pcall(UnitExists, "target")
    if not okEx or exists ~= true then return false end
    if type(UnitIsDead) == "function" then
        local okDead, dead = pcall(UnitIsDead, "target")
        if okDead and dead == true then return false end
    end
    if type(UnitCanAttack) == "function" then
        local okAtk, can = pcall(UnitCanAttack, "player", "target")
        if okAtk and can == false then return false end
    end
    return true
end

function WF.TargetTTD()
    if type(WR_GetUnitDeathTime) == "function" then
        local ok, v = pcall(WR_GetUnitDeathTime, "target")
        if ok and type(v) == "number" then return v end
    end
    return 8888
end

function WF.TargetHPPct()
    if type(WR_SafeHPPct) == "function" then
        local ok, v = pcall(WR_SafeHPPct, "target")
        if ok and type(v) == "number" then return v end
    end
    return 1
end

function WF.BuffRemain(name, byMe)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local onlyMe = (byMe ~= false)
    local ok, v = pcall(WR_GetUnitBuffTime, "player", name, onlyMe)
    if ok then return WF.Num(v, 0) end
    return 0
end

function WF.DebuffRemain(name)
    if type(WR_GetUnitDebuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffTime, "target", name, true)
    if ok then return WF.Num(v, 0) end
    return 0
end

function WF.DebuffCount(name)
    if type(WR_GetUnitDebuffCount) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffCount, "target", name, true)
    if ok then return WF.Num(v, 0) end
    return 0
end

function WF.CooldownLeft(spell)
    if type(WR_SpellCooldownInfo) ~= "function" then return 999 end
    local ok, start, duration = pcall(WR_SpellCooldownInfo, spell)
    if not ok then return 999 end
    start = WF.Num(start, 0)
    duration = WF.Num(duration, 0)
    if duration <= 0 then return 0 end
    local left = start + duration - GetTime()
    if left < 0 then left = 0 end
    return left
end

function WF.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, v = pcall(WR_Forever_IsSpellKnown, name)
        if ok then return v == true end
    end
    return false
end

function WF.Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) ~= "function" then return false end
    return WR_ColorFrame_ShowSkill(spell, slot) == true
end

function WF.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
    if type(WR_SyncFrameCheckboxes) == "function" and WR_ConfigFrame then
        pcall(WR_SyncFrameCheckboxes, WR_ConfigFrame, var)
    end
end

-- ============================================================
-- 3. 功能判定
-- ============================================================
-- 撕裂：目标没有自己施加的撕裂才补；不打元素/机械/亡灵；预判目标活不过 N 秒不打。
function WF.RendWanted()
    if not WF.On("KN_SILIE", true) then return false end
    if not WF.TargetExistsAttackable() then return false end
    if WF.IsCreatureTypeExcluded(WF.On("KN_SILIE_NO_ELEMENT", true),
        WF.On("KN_SILIE_NO_MECH", true), WF.On("KN_SILIE_NO_UNDEAD", true)) then
        return false
    end
    if WF.DebuffRemain("撕裂") > 0 then return false end
    local lead = WF.Val("KN_SILIE_LEAD", 6)
    if lead > 0 then
        local ttd = WF.TargetTTD()
        if ttd < 900 and ttd < lead then return false end
    end
    return true
end

-- 破甲攻击：返回 0=不打 / 1=只打1破 / 2=高优先级 / 3=低优先级 / 4=续破
function WF.SunderMode()
    if not WF.On("KN_BDPJ", false) then return 0 end
    if WF.DebuffRemain("破甲") > 0 then return 0 end
    local stacks = WF.DebuffCount("破甲攻击")
    local remain = WF.DebuffRemain("破甲攻击")
    local refresh = WF.Val("KN_PJ_REFRESH", 3)
    if WF.On("KN_PJ_ONLY1", false) then
        -- 截图口径：目标快死时不放
        local ttd = WF.TargetTTD()
        if ttd < 900 and ttd < 6 then return 0 end
        if stacks <= 0 then return 1 end
        return 0
    end
    if stacks < 5 then
        if WF.On("KN_PJ_HIGH", false) then return 2 end
        if WF.On("KN_PJ_LOW", false) then return 3 end
    end
    if stacks >= 5 and remain <= refresh then return 4 end
    return 0
end

-- 雷霆一击：mode 1保持 / 2卡CD / 3不放
function WF.ThunderWanted()
    if not WF.On("KN_LTYJ", true) then return false end
    local mode
    if (UnitCount8 or 0) >= WF.Val("KN_LT_AOE_COUNT", 2) then
        mode = WF.Val("KN_LT_AOE_MODE", 3)
    else
        mode = WF.Val("KN_LT_SINGLE_MODE", 1)
    end
    if mode == 3 then return false end
    if mode == 2 then return true end
    local miss = WF.Val("KN_LT_MISS", 0)
    if miss > 0 and (UnitCount8 or 0) >= miss and WF.DebuffRemain("雷霆一击") <= 0 then return true end
    return WF.DebuffRemain("雷霆一击") <= 1.5
end

function WF.DemoShoutWanted()
    if not WF.On("KN_LTYJ", true) then return false end
    local mode
    if (UnitCount8 or 0) >= WF.Val("KN_CZ_AOE_COUNT", 3) then
        mode = WF.Val("KN_CZ_AOE_MODE", 2)
    else
        mode = WF.Val("KN_CZ_SINGLE_MODE", 2)
    end
    -- 截图口径：挫志怒吼只有 保持(1) / 不放(2) 两档
    if mode ~= 1 then return false end
    local miss = WF.Val("KN_CZ_MISS", 0)
    if miss > 0 and (UnitCount8 or 0) >= miss and WF.DebuffRemain("挫志怒吼") <= 0 then return true end
    return WF.DebuffRemain("挫志怒吼") <= 1.5
end

-- 乘胜追击：击杀后 20 秒内可用；自己血量低于拉条才用。
function WF.VictoryRushWanted()
    if not WF.On("KN_CSZJ_ON", true) then return false end
    if type(WR_SpellUsable) ~= "function" or not WR_SpellUsable("乘胜追击", true) then return false end
    local pct = PlayerHP
    if type(pct) ~= "number" then return true end
    local known = true
    if type(UnitHealth) == "function" and type(WR_IsSecretValue) == "function" then
        local okH, raw = pcall(UnitHealth, "player")
        if not okH or type(raw) ~= "number" or WR_IsSecretValue(raw) then known = false end
    end
    if not known then return true end
    if pct >= 0.999 then return false end
    return pct <= WF.Val("KN_CSZJ", 70) / 100
end

-- 血性狂暴：怒气低于拉条、血量高于拉条（0=不看血量）
function WF.BloodrageWanted()
    if not WF.On("KN_HXKJ", true) then return false end
    if (Rage or 0) >= WF.Val("KN_HXKJ_NQ", 90) then return false end
    local hpGate = WF.Val("KN_HXKJ_XL", 0)
    if hpGate > 0 and PlayerHP and PlayerHP < hpGate / 100 then return false end
    return true
end

-- 鲁莽挥击：怒气低于拉条才用；buff 还在就不重复
function WF.RecklessSwingWanted()
    if not WF.On("KN_LMHJ", true) then return false end
    if WF.BuffRemain("鲁莽挥击") > 0 then return false end
    return (Rage or 0) < WF.Val("KN_LMHJ_NQ", 70)
end

-- 斩杀：面板拉条控制目标血量百分比；客户端 IsSpellUsable 再保证斩杀窗口。
function WF.ExecuteWanted()
    if not WF.TargetExistsAttackable() then return false end
    local threshold = WF.Val("KN_ZS", 15)
    if threshold <= 0 then return false end
    if type(WR_SpellUsable) ~= "function" or not WR_SpellUsable("斩杀", true) then return false end
    local hp = WF.TargetHPPct()
    if type(hp) ~= "number" or hp >= 0.999 then return true end
    return hp <= threshold / 100
end

-- 种族爆发：读当前种族的爆发技能列表，任意一个「真的能打」就提示（宏 181）。
-- ★★★ 2026-11-21 三十五次修复：补 CD 维。旧实现只问 WR_SpellUsable，
--   而无限战斗中 GetSpellCooldown 是 secret → WR_GetGCD 收敛成 0 → GCD 门恒成立
--   → 3 分钟大招（狂暴 20554）被当成随时可用 → 用了还一直亮。
--   现统一走 WR_Forever_RacialBurstReady（已学会 + 本地记账 CD + 客户端冷却 +
--   提示保持窗口 + 客户端可用性）。
function WF.RacialBurstWanted()
    if not WF.On("KN_ZDZZ", true) then return false end
    if type(WR_Forever_RacialBurstReady) == "function" then
        local okR, hit = pcall(WR_Forever_RacialBurstReady)
        return okR and type(hit) == "string"
    end
    if type(WR_Forever_GetRacialBursts) ~= "function" then return false end
    local ok, list = pcall(WR_Forever_GetRacialBursts)
    if not ok or type(list) ~= "table" then return false end
    for _, s in ipairs(list) do
        if type(WR_SpellUsable) == "function" and WR_SpellUsable(s, true) then return true end
    end
    return false
end

-- ============================================================
-- 4. 一次性插入
-- ============================================================
function WF.InsertOnce(var, spell, slot, extraOk)
    if not WF.On(var, false) then return false end
    if extraOk == false then return false end
    if type(WR_SpellUsable) ~= "function" or not WR_SpellUsable(spell, true) then return false end
    if WF.Show(spell, slot) then
        PigSet[var] = false
        WF.SyncCheckbox(var)
        return true
    end
    return false
end

-- 插入反击风暴时，若在狂暴/防御姿态先切战斗姿态（反击风暴要求战斗姿态）
function WF.StanceInsertPending()
    if WF.On("KN_FJFB_CR", false) and WF.SpellKnown("反击风暴") and WF.CooldownLeft("反击风暴") <= 2 then
        return true
    end
    return false
end

-- ============================================================
-- 5. 右键「额外条件」小窗
-- ============================================================
WF.PopupDefs = {
    KN_SILIE = {
        title = "撕裂  功能",
        desc = "开着时，目标身上没有自己施加的撕裂就自动补一次；撕裂还在时不重复补。\n右键里的额外条件：「不打元素」「不打机械」「不打亡灵」勾上时目标是那类就不打；「预判」= 目标预计能活过这么多秒才上（0 = 都放）。\n目标流血免疫不打。\n关掉后不再自动放撕裂。\n宏：/WARRIOR_REND 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "KN_SILIE", label = "撕裂", default = true },
            { type = "check", var = "KN_SILIE_NO_ELEMENT", label = "不打元素", default = true },
            { type = "check", var = "KN_SILIE_NO_MECH", label = "不打机械", default = true },
            { type = "check", var = "KN_SILIE_NO_UNDEAD", label = "不打亡灵", default = true },
            { type = "slider", var = "KN_SILIE_LEAD", label = "预判", min = 0, max = 30, step = 1, default = 6, suffix = "秒", hint = "0 = 都放" },
        },
    },
    KN_LTYJ = {
        title = "雷霆挫志  功能",
        desc = "开着时按右键里的设置放雷霆一击和挫志怒吼（各自满足任意一条就放）。\n雷霆一击：「多目标」身边敌人够「怪数」时，选 保持 = 目标身上没有自己的雷霆一击或1.5秒内结束就补、选 卡CD = 冷却好就放；「缺数」身边没挂自己雷霆一击的怪够这么多就放；「单体」不看人数，选 保持/卡CD。\n挫志怒吼：「多目标」身边敌人够「怪数」、目标没挂或1.5秒内结束就补；「缺数」身边没挂自己挫志怒吼的怪够这么多就放；「单体」不看人数，目标没挂就补。\n怒气不够、冷却没好或目标在近战范围外时不会放。\n关掉后两个都不自动放。\n宏：/WARRIOR_THUNDER_DEMO 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "KN_LTYJ", label = "雷霆挫志", default = true },
            { type = "header", text = "雷霆一击" },
            { type = "radio", var = "KN_LT_AOE_MODE", label = "多目标", options = { { "保持", 1 }, { "卡CD", 2 }, { "不放", 3 } }, default = 3 },
            { type = "slider", var = "KN_LT_AOE_COUNT", label = "怪数", min = 1, max = 10, step = 1, default = 2, suffix = "个" },
            { type = "slider", var = "KN_LT_MISS", label = "缺数", min = 0, max = 10, step = 1, default = 0, suffix = "个", hint = "0 = 关闭" },
            { type = "radio", var = "KN_LT_SINGLE_MODE", label = "单体", options = { { "保持", 1 }, { "卡CD", 2 }, { "不放", 3 } }, default = 1 },
            { type = "header", text = "挫志怒吼" },
            { type = "radio", var = "KN_CZ_AOE_MODE", label = "多目标", options = { { "保持", 1 }, { "不放", 2 } }, default = 2 },
            { type = "slider", var = "KN_CZ_AOE_COUNT", label = "怪数", min = 1, max = 10, step = 1, default = 3, suffix = "个" },
            { type = "slider", var = "KN_CZ_MISS", label = "缺数", min = 0, max = 10, step = 1, default = 0, suffix = "个", hint = "0 = 关闭" },
            { type = "radio", var = "KN_CZ_SINGLE_MODE", label = "单体", options = { { "保持", 1 }, { "不放", 2 } }, default = 2 },
        },
    },
    KN_HXKJ = {
        title = "血性狂暴  功能",
        desc = "开着时，开打后自动放血性狂暴（掉一点血换怒气，冷却好了就补）。\n右键：「怒气」怒气低于这个数才放（默认 90），「血量」自己血量高于这个百分比才放（默认 0 = 不看血量）。\n关掉后不再自动放血性狂暴。\n宏：/WARRIOR_BLOODRAGE 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "KN_HXKJ", label = "血性狂暴", default = true },
            { type = "slider", var = "KN_HXKJ_NQ", label = "怒气", min = 0, max = 100, step = 5, default = 90, suffix = "怒气" },
            { type = "slider", var = "KN_HXKJ_XL", label = "血量", min = 0, max = 100, step = 5, default = 0, suffix = "%", hint = "0 = 不看血量" },
        },
    },
    KN_BDPJ = {
        title = "破甲攻击  功能",
        desc = "开着时按右键里的额外条件放破甲攻击（降低目标护甲、拉仇恨），只算自己叠的破甲。\n「只打1破」排在前面，目标身上没有就挂 1 层（目标快死时不放）。\n「高优先级」排在前面，叠到 5 层。\n「低优先级」排在最后，不到 5 层时没别的技能才放。\n已经挂上的破甲剩不到「续破秒数」就续。目标身上有盗贼的破甲（和破甲攻击互斥）时不放。\n关掉后不再自动放破甲攻击。\n宏：/WARRIOR_SUNDER_DPS 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "KN_BDPJ", label = "破甲攻击", default = false },
            { type = "check", var = "KN_PJ_ONLY1", label = "只打1破", default = false },
            { type = "check", var = "KN_PJ_HIGH", label = "高优先级", default = false },
            { type = "check", var = "KN_PJ_LOW", label = "低优先级", default = false },
            { type = "slider", var = "KN_PJ_REFRESH", label = "续破秒数", min = 0, max = 30, step = 1, default = 3, suffix = "秒" },
        },
    },
    KN_QTZ = {
        title = "切姿态  功能",
        desc = "开着时按右键里的额外条件自动切姿态。\n「脱战切战斗」脱战后不在战斗姿态就切到战斗姿态，方便开怪用冲锋（人在防御姿态、点了天赋「先锋」时不切）。\n「进战切狂暴」进入战斗后不在狂暴姿态就切到狂暴姿态，插入「反击」开着、反击风暴快好了时不切，等它放出去。\n关掉后不再自动切姿态。\n宏：/WARRIOR_STANCE 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "KN_QTZ", label = "切姿态", default = true },
            { type = "check", var = "KN_QTZ_OOC", label = "脱战切战斗", default = true },
            { type = "check", var = "KN_QTZ_IC", label = "进战切狂暴", default = true },
        },
    },
    KN_LMHJ = {
        title = "鲁莽挥击  功能",
        desc = "狂怒天赋新技能：接下来 4 次近战攻击每次额外产生 5 点怒气，持续 8 秒。\n怒气低于拉条时使用；buff 还在时不重复。",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "KN_LMHJ", label = "鲁莽挥击", default = true },
            { type = "slider", var = "KN_LMHJ_NQ", label = "怒气低于", min = 0, max = 100, step = 5, default = 70, suffix = "怒气" },
        },
    },
}

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

local function BuildPopup(key)
    local def = WF.PopupDefs[key]
    if not def then return nil end
    local f = CreateFrame("Frame", "WR_WarriorFuryPopup_" .. key, UIParent, "BackdropTemplate")
    f:SetSize(330, 120)
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
    local contentWidth = 300
    local function addRow(h)
        y = y - h
    end

    if def.desc then
        local desc = MakeFont(f, def.desc, 11, 0.78, 0.78, 0.78, contentWidth)
        desc:SetPoint("TOPLEFT", f, "TOPLEFT", 12, y)
        desc:SetSpacing(2)
        local h = 40
        if desc.GetStringHeight then
            local ok, measured = pcall(desc.GetStringHeight, desc)
            if ok and type(measured) == "number" and measured > 0 then h = math.ceil(measured) + 6 end
        end
        addRow(h + 4)
    end

    for _, rowDef in ipairs(def.rows or {}) do
        if rowDef.type == "header" then
            local h = MakeFont(f, rowDef.text or "", 12, 1, 0.65, 0.2)
            h:SetPoint("TOPLEFT", f, "TOPLEFT", 12, y - 3)
            addRow(20)
        elseif rowDef.type == "check" then
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y)
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            cb:SetChecked(PigSet[rowDef.var] == true)
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95)
            label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            cb:SetScript("OnClick", function(self)
                PigSet[rowDef.var] = self:GetChecked() and true or false
                WF.SyncCheckbox(rowDef.var)
            end)
            rows[#rows + 1] = { kind = "check", row = rowDef, control = cb }
            addRow(24)
        elseif rowDef.type == "slider" then
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95, 110)
            label:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y - 2)
            local slider = CreateFrame("Slider", nil, f)
            slider:SetOrientation("HORIZONTAL")
            slider:SetSize(110, 10)
            slider:SetPoint("LEFT", label, "RIGHT", 8, 0)
            slider:SetMinMaxValues(rowDef.min or 0, rowDef.max or 100)
            slider:SetValueStep(rowDef.step or 1)
            slider:SetObeyStepOnDrag(true)
            slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
            local thumb = slider:GetThumbTexture()
            if thumb then thumb:SetSize(6, 14); thumb:SetVertexColor(0.82, 0.84, 0.87, 1) end
            local track = slider:CreateTexture(nil, "BACKGROUND")
            track:SetTexture("Interface\\Buttons\\WHITE8x8")
            track:SetVertexColor(0.16, 0.18, 0.21, 1)
            track:SetAllPoints()
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            local val = WF.Num(PigSet[rowDef.var], rowDef.default or 0)
            if val < (rowDef.min or 0) then val = rowDef.min or 0 end
            if val > (rowDef.max or 100) then val = rowDef.max or 100 end
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
            local label = MakeFont(f, rowDef.label or "", 12, 0.92, 0.93, 0.95, 64)
            label:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y - 3)
            local buttons = {}
            local startX = 72
            for i, opt in ipairs(rowDef.options or {}) do
                local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
                btn:SetSize(54, 20)
                btn:SetPoint("TOPLEFT", f, "TOPLEFT", startX + (i - 1) * 58, y)
                if btn.SetBackdrop then
                    btn:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 1,
                    })
                end
                if btn.SetBackdropColor then
                    btn:SetBackdropColor(0.12, 0.13, 0.15, 0.9)
                    btn:SetBackdropBorderColor(0.18, 0.20, 0.23, 1)
                end
                local txt = MakeFont(btn, opt[1], 11, 0.85, 0.85, 0.85)
                txt:SetPoint("CENTER", btn, "CENTER", 0, 0)
                btn:SetScript("OnClick", function()
                    PigSet[rowDef.var] = opt[2]
                    for _, b in ipairs(buttons) do
                        local on = (tonumber(PigSet[rowDef.var]) == b.value)
                        if b.btn.SetBackdropColor then
                            if on then b.btn:SetBackdropColor(0.35, 0.27, 0.10, 1)
                            else b.btn:SetBackdropColor(0.12, 0.13, 0.15, 0.9) end
                        end
                        b.txt:SetTextColor(on and 1 or 0.65, on and 0.82 or 0.65, on and 0.2 or 0.65)
                    end
                end)
                buttons[#buttons + 1] = { btn = btn, txt = txt, value = opt[2] }
            end
            rows[#rows + 1] = { kind = "radio", row = rowDef, buttons = buttons }
            addRow(27)
        end
    end

    local contentH = math.abs(y) + 12
    f:SetHeight(math.max(90, contentH + 18))
    f.rows = rows
    f.defKey = key

    function f:Refresh()
        for _, rec in ipairs(self.rows or {}) do
            if rec.kind == "check" then
                rec.control:SetChecked(PigSet[rec.row.var] == true)
            elseif rec.kind == "slider" then
                local v = WF.Num(PigSet[rec.row.var], rec.row.default or 0)
                rec.control:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            elseif rec.kind == "radio" then
                local cur = tonumber(PigSet[rec.row.var]) or rec.row.default or 1
                for _, b in ipairs(rec.buttons) do
                    local on = (cur == b.value)
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

WF.PopupCache = WF.PopupCache or {}

function WF.ShowOptions(key)
    WF.InitDefaults()
    local def = WF.PopupDefs[key]
    if not def then return end
    local f = WF.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        WF.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(WF.PopupCache) do
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
-- 6. 爆发按钮（全开 / 全关 / 切换）
-- ============================================================
function WF.SetBurst(on)
    if type(PigSet) ~= "table" then return end
    PigSet.KN_LM = on and true or false
    PigSet.KN_SWZY = on and true or false
    PigSet.KN_ZDZZ = on and true or false
    WF.SyncCheckbox("KN_LM")
    WF.SyncCheckbox("KN_SWZY")
    WF.SyncCheckbox("KN_ZDZZ")
end

function WR_WarriorFuryBurstAllOn()
    if WR_WarriorFuryUI then WR_WarriorFuryUI.SetBurst(true) end
end

function WR_WarriorFuryBurstAllOff()
    if WR_WarriorFuryUI then WR_WarriorFuryUI.SetBurst(false) end
end

function WR_WarriorFuryBurstToggle()
    if not WR_WarriorFuryUI then return end
    local any = (PigSet.KN_LM == true) or (PigSet.KN_SWZY == true) or (PigSet.KN_ZDZZ == true)
    WR_WarriorFuryUI.SetBurst(not any)
end

-- ============================================================
-- 7. 斜杠命令别名（对齐截图里的 /WARRIOR_xxx）
-- ------------------------------------------------------------
-- 与武器战共享的命令（撕裂 / 破甲 / 血性狂暴 / 雷霆挫志）按当前专精分流：
-- 狂怒时改狂怒变量，武器时调用武器战原处理函数，互不覆盖。
-- ============================================================
local function WF_SetVarByCommand(var, msg, label)
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
    WF.SyncCheckbox(var)
    local status = PigSet[var] and "|cff00ff00已开启|r" or "|cffff0000已关闭|r"
    local text = status .. " [" .. label .. "]"
    if type(WR_PrintToVisible) == "function" then
        WR_PrintToVisible(text)
    elseif type(print) == "function" then
        print(text)
    end
end

local function WF_BindCommand(cmd, var, label)
    if type(SlashCmdList) ~= "table" then return end
    _G["SLASH_" .. cmd .. "1"] = "/" .. cmd
    SlashCmdList[cmd] = function(msg) WF_SetVarByCommand(var, msg, label) end
end

-- 武器战先加载并注册了同名命令：保存原处理函数，狂怒时走狂怒变量，其他专精回落原实现。
WR_WarriorSharedCommandPrev = WR_WarriorSharedCommandPrev or {}
local function WF_BindSharedCommand(cmd, var, label)
    if type(SlashCmdList) ~= "table" then return end
    local previous = SlashCmdList[cmd]
    if type(previous) == "function" and WR_WarriorSharedCommandPrev[cmd] == nil then
        WR_WarriorSharedCommandPrev[cmd] = previous
    end
    local base = WR_WarriorSharedCommandPrev[cmd]
    _G["SLASH_" .. cmd .. "1"] = "/" .. cmd
    SlashCmdList[cmd] = function(msg)
        local spec = nil
        if type(WR_GetMyTalent) == "function" then
            local ok, v = pcall(WR_GetMyTalent)
            if ok and type(v) == "string" then spec = v end
        end
        if spec == "狂怒" then
            WF_SetVarByCommand(var, msg, label)
        elseif type(base) == "function" then
            base(msg)
        end
    end
end

WF_BindSharedCommand("WARRIOR_REND", "KN_SILIE", "撕裂")
WF_BindSharedCommand("WARRIOR_SUNDER_DPS", "KN_BDPJ", "破甲攻击")
WF_BindSharedCommand("WARRIOR_BLOODRAGE", "KN_HXKJ", "血性狂暴")
WF_BindSharedCommand("WARRIOR_THUNDER_DEMO", "KN_LTYJ", "雷霆挫志")
WF_BindSharedCommand("WARRIOR_STANCE", "KN_QTZ", "切姿态")

-- ============================================================
-- 8. 供循环使用的小工具
-- ============================================================
function WF.AutoAttack()
    if PlayerMove then return false end
    if not WF.TargetExistsAttackable() then return false end
    if TargetRange and TargetRange > 5 and TargetRange < 900 then return false end
    if type(IsCurrentSpell) == "function" then
        local ok, cur = pcall(IsCurrentSpell, "攻击")
        if ok and cur == true then return false end
    end
    if type(WR_SpellUsable) ~= "function" or not WR_SpellUsable("攻击") then return false end
    return WF.Show("攻击", 4)
end
