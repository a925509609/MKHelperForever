-- ============================================================
-- Warrior_Arms_Features.lua
-- 武器战士（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 WARRIOR「武器」专精，不写全局、不影响狂怒/防护与其他职业。
--
-- 本文件按截图（彼岸花-无限服 · 武器页）逐项落地：
--   功能：撕裂 / 雷霆挫志 / 血性狂暴 / 破甲攻击 / 致死打击 /
--         横扫攻击 / 旋风斩 / 战斗怒吼 / 切换目标 / 猛击
--   插入：反击 / 穿刺 / 横扫 / 狂暴之怒（一次性，放完自关）
--   拉条：顺劈斩 / 英勇打击 / 斩杀 / 乘胜追击 / 喝红药 / 打断
--   爆发：鲁莽 / 种族爆发（全开 / 全关 / 切换）
--   额外条件：右键对应图标打开（撕裂/雷霆挫志/血性狂暴/破甲攻击/
--             致死打击/横扫攻击/旋风斩）
--
-- 说明：当前客户端为 60 级法术书（2026-11-13 Data_SpellBook）：
--   英勇打击 25286 / 撕裂 11574 / 雷霆一击 11581 / 反击风暴 20230 /
--   乘胜追击 402927 / 战斗怒吼 25289 / 挫志怒吼 11556 / 顺劈斩 20569 /
--   猛击 11605 / 斩杀 20662 / 狂暴之怒 18499 / 狂暴姿态 2458 /
--   旋风斩 1680 / 拳击 6554 / 鲁莽 1719 / 血性狂暴 2687 /
--   破甲攻击 11597 / 致死打击 21553 / 横扫攻击 12292 / 穿刺打击 1310222。
-- ============================================================

if WR_PlayerClass ~= "WARRIOR" then return end

WR_WarriorArmsUI = WR_WarriorArmsUI or {}
local WA = WR_WarriorArmsUI

-- ============================================================
-- 1. 默认值与旧档兼容
-- ------------------------------------------------------------
-- 规则：只补 nil，绝不覆盖用户已有设置。
-- 旧档：WQZ_PJGJ（破甲下拉 1=打破甲/2=禁用）→ WQZ_BDPJ；
--       WQZ_NH（怒吼 1=命令/2=战斗/3=禁用）→ WQZ_ZDZH；
--       WQZ_CRLM（插入鲁莽）→ WQZ_LM；WQZ_ZHANSHA（自动斩杀）→ WQZ_ZS。
-- ============================================================
function WA.InitDefaults()
    if type(PigSet) ~= "table" then return end
    local function setb(k, v) if PigSet[k] == nil then PigSet[k] = v end end
    local function setn(k, v) if type(PigSet[k]) ~= "number" then PigSet[k] = v end end

    -- 旧档迁移（先做，避免下面的 setb 把新变量提前填成默认值）
    if PigSet.WQZ_ARMS_MIGRATED == nil then
        if PigSet.WQZ_PJGJ ~= nil and PigSet.WQZ_BDPJ == nil then
            PigSet.WQZ_BDPJ = (tonumber(PigSet.WQZ_PJGJ) ~= 2)
        end
        if PigSet.WQZ_NH ~= nil and PigSet.WQZ_ZDZH == nil then
            PigSet.WQZ_ZDZH = (tonumber(PigSet.WQZ_NH) ~= 3)
        end
        if PigSet.WQZ_CRLM == true and PigSet.WQZ_LM == nil then
            PigSet.WQZ_LM = true
        end
        if PigSet.WQZ_ZHANSHA == true and PigSet.WQZ_ZS == nil then
            PigSet.WQZ_ZS = 15
        end
        PigSet.WQZ_ARMS_MIGRATED = true
    end

    -- 主功能开关（默认开启，和截图一致）
    setb("WQZ_SILIE", true)       -- 撕裂
    setb("WQZ_LTYJ", true)        -- 雷霆挫志（总开关）
    setb("WQZ_HXKJ", true)        -- 血性狂暴
    setb("WQZ_BDPJ", true)        -- 破甲攻击
    setb("WQZ_MS_POOL", true)     -- 致死打击让怒
    setb("WQZ_HSGJ", true)        -- 横扫攻击（自动）
    setb("WQZ_XLZ_AUTO", true)    -- 旋风斩（自动切姿态）
    setb("WQZ_ZDZH", true)        -- 战斗怒吼
    setb("WQZ_TAB", true)         -- 切换目标
    setb("WQZ_MJ", true)          -- 猛击
    setb("WQZ_CSZJ_ON", true)     -- 乘胜追击（由拉条控制血量门槛）

    -- 插入（一次性，默认关）
    setb("WQZ_CRFJFB", false)     -- 反击（反击风暴）
    setb("WQZ_CCDJ_CR", false)    -- 穿刺（穿刺打击）
    setb("WQZ_CRHS", false)       -- 横扫（横扫攻击）
    setb("WQZ_KBZN_CR", false)    -- 狂暴之怒

    -- 爆发（默认开启，和截图勾选一致）
    setb("WQZ_LM", true)          -- 鲁莽
    setb("WQZ_ZDZZ", true)        -- 种族爆发

    -- 拉条默认值（截图口径）
    setn("WQZ_SPZ", 30)           -- 顺劈斩怒气
    setn("WQZ_YYDJ", 20)          -- 英勇打击怒气
    setn("WQZ_ZS", 15)            -- 斩杀目标血量
    setn("WQZ_CSZJ", 70)          -- 乘胜追击自己血量
    setn("WQZ_HXY", 30)           -- 喝红药血量
    setn("WQZ_QJ", 60)            -- 打断施法进度

    -- 撕裂额外条件
    setb("WQZ_SILIE_NO_ELEMENT", true)
    setb("WQZ_SILIE_NO_MECH", true)
    setb("WQZ_SILIE_NO_UNDEAD", true)
    setn("WQZ_SILIE_LEAD", 6)

    -- 雷霆挫志额外条件（1=保持 / 2=卡CD / 3=不放）
    setn("WQZ_LT_AOE_MODE", 3)
    setn("WQZ_LT_AOE_COUNT", 2)
    setn("WQZ_LT_MISS", 0)
    setn("WQZ_LT_SINGLE_MODE", 1)
    setn("WQZ_CZ_AOE_MODE", 3)
    setn("WQZ_CZ_AOE_COUNT", 3)
    setn("WQZ_CZ_MISS", 0)
    setn("WQZ_CZ_SINGLE_MODE", 3)

    -- 血性狂暴额外条件
    setn("WQZ_HXKJ_NQ", 90)
    setn("WQZ_HXKJ_XL", 0)

    -- 破甲攻击额外条件
    setb("WQZ_PJ_ONLY1", false)
    setb("WQZ_PJ_HIGH", true)
    setb("WQZ_PJ_LOW", false)
    setn("WQZ_PJ_REFRESH", 3)

    -- 致死打击让怒
    setn("WQZ_MS_POOL_SEC", 2)
    setn("WQZ_MS_POOL_RAGE", 60)

    -- 旋风斩姿态舞
    setn("WQZ_XLZ_COUNT", 2)
    setn("WQZ_XLZ_RAGE", 25)

    -- 横扫攻击额外条件（1=强制留怒 / 2=随缘）
    setn("WQZ_HSGJ_COUNT", 2)
    setn("WQZ_HSGJ_RAGE_MODE", 2)
end

WA.InitDefaults()

-- ============================================================
-- 2. 安全读取小工具
-- ============================================================
function WA.Num(v, d)
    if type(v) == "number" then return v end
    return d
end

function WA.Bool(v, d)
    if type(v) == "boolean" then return v end
    return d
end

function WA.On(var, default)
    return WA.Bool(PigSet and PigSet[var], default)
end

function WA.Val(var, default)
    return WA.Num(PigSet and PigSet[var], default)
end

-- 当前姿态：1 战斗 / 2 防御 / 3 狂暴 / 0 未知
function WA.Stance()
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

function WA.CreatureType()
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

function WA.IsCreatureTypeExcluded(noElement, noMech, noUndead)
    local ct = WA.CreatureType()
    if not ct then return false end
    if noElement and (ct == "元素" or ct == "Elemental") then return true end
    if noMech and (ct == "机械" or ct == "Mechanical") then return true end
    if noUndead and (ct == "亡灵" or ct == "Undead") then return true end
    return false
end

function WA.TargetExistsAttackable()
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

function WA.TargetTTD()
    if type(WR_GetUnitDeathTime) == "function" then
        local ok, v = pcall(WR_GetUnitDeathTime, "target")
        if ok and type(v) == "number" then return v end
    end
    return 8888
end

function WA.TargetHPPct()
    if type(WR_SafeHPPct) == "function" then
        local ok, v = pcall(WR_SafeHPPct, "target")
        if ok and type(v) == "number" then return v end
    end
    return 1
end

function WA.TargetBleedImmune()
    if type(UnitIsImmune) == "function" then
        local ok, v = pcall(UnitIsImmune, "target", "流血")
        if ok and v == true then return true end
        local ok2, v2 = pcall(UnitIsImmune, "target", "物理")
        if ok2 and v2 == true then return true end
    end
    return false
end

function WA.BuffRemain(name, byMe)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local onlyMe = (byMe ~= false)
    local ok, v = pcall(WR_GetUnitBuffTime, "player", name, onlyMe)
    if ok then return WA.Num(v, 0) end
    return 0
end

function WA.DebuffRemain(name)
    if type(WR_GetUnitDebuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffTime, "target", name, true)
    if ok then return WA.Num(v, 0) end
    return 0
end

-- 任意来源的 debuff（例如盗贼的破甲，不是自己施放的）
function WA.DebuffRemainAny(name)
    if type(WR_GetUnitDebuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffTime, "target", name, false)
    if ok then return WA.Num(v, 0) end
    return 0
end

function WA.DebuffCount(name)
    if type(WR_GetUnitDebuffCount) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffCount, "target", name, true)
    if ok then return WA.Num(v, 0) end
    return 0
end

function WA.CooldownLeft(spell)
    if type(WR_SpellCooldownInfo) ~= "function" then return 999 end
    local ok, start, duration = pcall(WR_SpellCooldownInfo, spell)
    if not ok then return 999 end
    start = WA.Num(start, 0)
    duration = WA.Num(duration, 0)
    if duration <= 0 then return 0 end
    local left = start + duration - GetTime()
    if left < 0 then left = 0 end
    return left
end

function WA.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, v = pcall(WR_Forever_IsSpellKnown, name)
        if ok and v == true then return true end
    end
    -- 回退：法术书索引能解析出 ID，也视为已学会（兼容 IsPlayerSpell 对中文字符串失效的客户端）
    if type(WR_ResolveSpellID) == "function" then
        local ok, sid = pcall(WR_ResolveSpellID, name)
        if ok and sid ~= nil then return true end
    end
    return false
end

function WA.Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) ~= "function" then return false end
    return WR_ColorFrame_ShowSkill(spell, slot) == true
end

function WA.SyncCheckbox(var)
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
function WA.RendWanted()
    if not WA.On("WQZ_SILIE", true) then return false end
    if not WA.TargetExistsAttackable() then return false end
    if WA.TargetBleedImmune() then return false end
    if WA.IsCreatureTypeExcluded(WA.On("WQZ_SILIE_NO_ELEMENT", true),
        WA.On("WQZ_SILIE_NO_MECH", true), WA.On("WQZ_SILIE_NO_UNDEAD", true)) then
        return false
    end
    if WA.DebuffRemain("撕裂") > 0 then return false end
    local lead = WA.Val("WQZ_SILIE_LEAD", 6)
    if lead > 0 then
        local ttd = WA.TargetTTD()
        if ttd < 900 and ttd < lead then return false end
    end
    return true
end

-- 破甲攻击：返回 0=不打 / 1=只打1破 / 2=高优先级 / 3=低优先级 / 4=续破
function WA.SunderMode()
    if not WA.On("WQZ_BDPJ", true) then return 0 end
    -- 目标身上有盗贼的破甲（和破甲攻击互斥）时不放
    if WA.DebuffRemainAny("破甲") > 0 then return 0 end
    local stacks = WA.DebuffCount("破甲攻击")
    local remain = WA.DebuffRemain("破甲攻击")
    local refresh = WA.Val("WQZ_PJ_REFRESH", 3)
    if WA.On("WQZ_PJ_ONLY1", false) then
        local ttd = WA.TargetTTD()
        if ttd < 900 and ttd < 6 then return 0 end
        if stacks <= 0 then return 1 end
        return 0
    end
    if stacks < 5 then
        if WA.On("WQZ_PJ_HIGH", true) then return 2 end
        if WA.On("WQZ_PJ_LOW", false) then return 3 end
    end
    if stacks >= 5 and remain <= refresh then return 4 end
    return 0
end

-- 雷霆一击：mode 1保持 / 2卡CD / 3不放
function WA.ThunderWanted()
    if not WA.On("WQZ_LTYJ", true) then return false end
    local mode
    if (UnitCount8 or 0) >= WA.Val("WQZ_LT_AOE_COUNT", 2) then
        mode = WA.Val("WQZ_LT_AOE_MODE", 3)
    else
        mode = WA.Val("WQZ_LT_SINGLE_MODE", 1)
    end
    if mode == 3 then return false end
    if mode == 2 then return true end
    local miss = WA.Val("WQZ_LT_MISS", 0)
    if miss > 0 and (UnitCount8 or 0) >= miss and WA.DebuffRemain("雷霆一击") <= 0 then return true end
    return WA.DebuffRemain("雷霆一击") <= 1.5
end

function WA.DemoShoutWanted()
    if not WA.On("WQZ_LTYJ", true) then return false end
    local mode
    if (UnitCount8 or 0) >= WA.Val("WQZ_CZ_AOE_COUNT", 3) then
        mode = WA.Val("WQZ_CZ_AOE_MODE", 3)
    else
        mode = WA.Val("WQZ_CZ_SINGLE_MODE", 3)
    end
    if mode == 3 then return false end
    if mode == 2 then return true end
    local miss = WA.Val("WQZ_CZ_MISS", 0)
    if miss > 0 and (UnitCount8 or 0) >= miss and WA.DebuffRemain("挫志怒吼") <= 0 then return true end
    return WA.DebuffRemain("挫志怒吼") <= 1.5
end

-- 乘胜追击：击杀后 20 秒内可用；自己血量低于拉条才用。
function WA.VictoryRushWanted()
    if not WA.On("WQZ_CSZJ_ON", true) then return false end
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
    return pct <= WA.Val("WQZ_CSZJ", 70) / 100
end

-- 血性狂暴：怒气低于拉条、血量高于拉条（0=不看血量）
function WA.BloodrageWanted()
    if not WA.On("WQZ_HXKJ", true) then return false end
    if (Rage or 0) >= WA.Val("WQZ_HXKJ_NQ", 90) then return false end
    local hpGate = WA.Val("WQZ_HXKJ_XL", 0)
    if hpGate > 0 and PlayerHP and PlayerHP < hpGate / 100 then return false end
    return true
end

-- 斩杀：面板拉条控制目标血量百分比；客户端 IsSpellUsable 再保证斩杀窗口。
function WA.ExecuteWanted()
    if not WA.TargetExistsAttackable() then return false end
    local threshold = WA.Val("WQZ_ZS", 15)
    if threshold <= 0 then return false end
    if type(WR_SpellUsable) ~= "function" or not WR_SpellUsable("斩杀", true) then return false end
    local hp = WA.TargetHPPct()
    if type(hp) ~= "number" or hp >= 0.999 then return true end
    return hp <= threshold / 100
end

-- 种族爆发：读当前种族的爆发技能列表，任意一个可用就提示（宏 181）。
function WA.RacialBurstWanted()
    if not WA.On("WQZ_ZDZZ", true) then return false end
    if type(WR_Forever_GetRacialBursts) ~= "function" then return false end
    local ok, list = pcall(WR_Forever_GetRacialBursts)
    if not ok or type(list) ~= "table" then return false end
    for _, s in ipairs(list) do
        if type(WR_SpellUsable) == "function" and WR_SpellUsable(s, true) then return true end
    end
    return false
end

-- 致死打击让怒：致死打击冷却快好时，英勇/顺劈要怒气够才排。
function WA.MSPoolActive()
    if not WA.On("WQZ_MS_POOL", true) then return false end
    if not WA.SpellKnown("致死打击") then return false end
    return WA.CooldownLeft("致死打击") <= WA.Val("WQZ_MS_POOL_SEC", 2)
end

function WA.RageDumpAllowed()
    if not WA.MSPoolActive() then return true end
    return (Rage or 0) >= WA.Val("WQZ_MS_POOL_RAGE", 60)
end

-- 横扫攻击：战斗姿态、怪数够、冷却好才放
function WA.SweepWanted()
    if not WA.On("WQZ_HSGJ", true) then return false end
    if WA.Stance() ~= 1 then return false end
    if (UnitCount8 or 0) < WA.Val("WQZ_HSGJ_COUNT", 2) then return false end
    if not WA.SpellKnown("横扫攻击") then return false end
    if WA.CooldownLeft("横扫攻击") > 0.3 then return false end
    return type(WR_SpellUsable) == "function" and WR_SpellUsable("横扫攻击", true)
end

-- 横扫攻击「强制留怒」：冷却好了但怒气不够时，先不平砍泄怒，等它放出去
function WA.SweepPooling()
    if WA.Val("WQZ_HSGJ_RAGE_MODE", 2) ~= 1 then return false end
    if not WA.On("WQZ_HSGJ", true) then return false end
    if WA.Stance() ~= 1 then return false end
    if (UnitCount8 or 0) < WA.Val("WQZ_HSGJ_COUNT", 2) then return false end
    if not WA.SpellKnown("横扫攻击") then return false end
    return WA.CooldownLeft("横扫攻击") <= 0.3
end

-- 旋风斩姿态舞：战斗姿态下满足条件先切狂暴，再放旋风斩，放完切回战斗
function WA.WhirlwindWanted()
    if not WA.On("WQZ_XLZ_AUTO", true) then return false end
    -- 横扫攻击「强制留怒」优先：先攒怒气给横扫，不切姿态打旋风斩
    if WA.SweepPooling() then return false end
    if WA.Stance() ~= 1 then return false end
    if (UnitCount8 or 0) < WA.Val("WQZ_XLZ_COUNT", 2) then return false end
    if (Rage or 0) > WA.Val("WQZ_XLZ_RAGE", 25) then return false end
    if not WA.SpellKnown("旋风斩") then return false end
    return WA.CooldownLeft("旋风斩") <= 0.3
end

WA._whirlwindState = WA._whirlwindState or 0
function WA.GetWhirlwindState() return WA._whirlwindState or 0 end
function WA.SetWhirlwindState(v) WA._whirlwindState = tonumber(v) or 0 end

-- ============================================================
-- 4. 一次性插入
-- ============================================================
function WA.InsertOnce(var, spell, slot, extraOk)
    if not WA.On(var, false) then return false end
    if extraOk == false then return false end
    if type(WR_SpellUsable) ~= "function" or not WR_SpellUsable(spell, true) then return false end
    if WA.Show(spell, slot) then
        PigSet[var] = false
        WA.SyncCheckbox(var)
        return true
    end
    return false
end

-- 插入反击风暴时，若在狂暴/防御姿态先切战斗姿态（反击风暴要求战斗姿态）
function WA.StanceInsertPending()
    if WA.On("WQZ_CRFJFB", false) and WA.SpellKnown("反击风暴") and WA.CooldownLeft("反击风暴") <= 2 then
        return true
    end
    return false
end

-- ============================================================
-- 5. 右键「额外条件」小窗
-- ============================================================
WA.PopupDefs = {
    WQZ_SILIE = {
        title = "撕裂  功能",
        desc = "开着时，目标身上没有自己施加的撕裂就自动补一次；撕裂还在时不重复补。\n右键里的额外条件：「不打元素」「不打机械」「不打亡灵」勾上时目标是那类就不打；「预判」= 目标预计能活过这么多秒才上（0 = 都放）。\n目标流血免疫不打。\n关掉后不再自动放撕裂。\n宏：/WARRIOR_REND 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "WQZ_SILIE", label = "撕裂", default = true },
            { type = "check", var = "WQZ_SILIE_NO_ELEMENT", label = "不打元素", default = true },
            { type = "check", var = "WQZ_SILIE_NO_MECH", label = "不打机械", default = true },
            { type = "check", var = "WQZ_SILIE_NO_UNDEAD", label = "不打亡灵", default = true },
            { type = "slider", var = "WQZ_SILIE_LEAD", label = "预判", min = 0, max = 30, step = 1, default = 6, suffix = "秒", hint = "0 = 都放" },
        },
    },
    WQZ_LTYJ = {
        title = "雷霆挫志  功能",
        desc = "开着时按右键里的设置放雷霆一击和挫志怒吼（各自满足任意一条就放）。\n雷霆一击：「多目标」身边敌人够「怪数」时，选 保持 = 目标身上没有自己的雷霆一击或1.5秒内结束就补、选 卡CD = 冷却好就放；「缺数」身边没挂自己雷霆一击的怪够这么多就放；「单体」不看人数，选 保持/卡CD。\n挫志怒吼：「多目标」身边敌人够「怪数」、目标没挂或1.5秒内结束就补；「缺数」身边没挂自己挫志怒吼的怪够这么多就放；「单体」不看人数，目标没挂就补。\n怒气不够、冷却没好或目标在近战范围外时不会放。\n关掉后两个都不自动放。\n宏：/WARRIOR_THUNDER_DEMO 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "WQZ_LTYJ", label = "雷霆挫志", default = true },
            { type = "header", text = "雷霆一击" },
            { type = "radio", var = "WQZ_LT_AOE_MODE", label = "多目标", options = { { "保持", 1 }, { "卡CD", 2 }, { "不放", 3 } }, default = 3 },
            { type = "slider", var = "WQZ_LT_AOE_COUNT", label = "怪数", min = 1, max = 10, step = 1, default = 2, suffix = "个" },
            { type = "slider", var = "WQZ_LT_MISS", label = "缺数", min = 0, max = 10, step = 1, default = 0, suffix = "个", hint = "0 = 关闭" },
            { type = "radio", var = "WQZ_LT_SINGLE_MODE", label = "单体", options = { { "保持", 1 }, { "卡CD", 2 }, { "不放", 3 } }, default = 1 },
            { type = "header", text = "挫志怒吼" },
            { type = "radio", var = "WQZ_CZ_AOE_MODE", label = "多目标", options = { { "保持", 1 }, { "卡CD", 2 }, { "不放", 3 } }, default = 3 },
            { type = "slider", var = "WQZ_CZ_AOE_COUNT", label = "怪数", min = 1, max = 10, step = 1, default = 3, suffix = "个" },
            { type = "slider", var = "WQZ_CZ_MISS", label = "缺数", min = 0, max = 10, step = 1, default = 0, suffix = "个", hint = "0 = 关闭" },
            { type = "radio", var = "WQZ_CZ_SINGLE_MODE", label = "单体", options = { { "保持", 1 }, { "卡CD", 2 }, { "不放", 3 } }, default = 3 },
        },
    },
    WQZ_HXKJ = {
        title = "血性狂暴  功能",
        desc = "开着时，开打后自动放血性狂暴（掉一点血换怒气，冷却好了就补）。\n右键：「怒气」怒气低于这个数才放（默认 90），「血量」自己血量高于这个百分比才放（默认 0 = 不看血量）。\n关掉后不再自动放血性狂暴。\n宏：/WARRIOR_BLOODRAGE 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "WQZ_HXKJ", label = "血性狂暴", default = true },
            { type = "slider", var = "WQZ_HXKJ_NQ", label = "怒气", min = 0, max = 100, step = 5, default = 90, suffix = "怒气" },
            { type = "slider", var = "WQZ_HXKJ_XL", label = "血量", min = 0, max = 100, step = 5, default = 0, suffix = "%", hint = "0 = 不看血量" },
        },
    },
    WQZ_BDPJ = {
        title = "破甲攻击  功能",
        desc = "开着时按右键里的额外条件放破甲攻击（降低目标护甲、拉仇恨），只算自己叠的破甲。\n「只打1破」排在前面，目标身上没有就挂 1 层（目标快死时不放）。\n「高优先级」排在前面，叠到 5 层。\n「低优先级」排在最后，不到 5 层时没别的技能才放。\n已经挂上的破甲剩不到「续破秒数」就续。目标身上有盗贼的破甲（和破甲攻击互斥）时不放。\n关掉后不再自动放破甲攻击。\n宏：/WARRIOR_SUNDER_DPS 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "WQZ_BDPJ", label = "破甲攻击", default = true },
            { type = "check", var = "WQZ_PJ_ONLY1", label = "只打1破", default = false },
            { type = "check", var = "WQZ_PJ_HIGH", label = "高优先级", default = true },
            { type = "check", var = "WQZ_PJ_LOW", label = "低优先级", default = false },
            { type = "slider", var = "WQZ_PJ_REFRESH", label = "续破秒数", min = 0, max = 30, step = 1, default = 3, suffix = "秒" },
        },
    },
    WQZ_MS_POOL = {
        title = "致死打击  功能",
        desc = "开着时给致死打击留怒气：致死打击冷却剩不到「让怒秒数」时，英勇打击、顺劈斩要怒气够「让怒怒气」才排，免得怒气被吃掉、致死打击好了放不出来。\n致死打击本身照常放，不归这个开关管。\n关掉后英勇打击、顺劈斩只看自己的拉条。\n宏：/WARRIOR_MS_POOL 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "WQZ_MS_POOL", label = "致死打击", default = true },
            { type = "slider", var = "WQZ_MS_POOL_SEC", label = "让怒秒数", min = 0, max = 10, step = 1, default = 2, suffix = "秒" },
            { type = "slider", var = "WQZ_MS_POOL_RAGE", label = "让怒怒气", min = 0, max = 100, step = 5, default = 60, suffix = "怒气" },
        },
    },
    WQZ_XLZ_AUTO = {
        title = "旋风斩  功能",
        desc = "开着时，平时在战斗姿态打，旋风斩冷却好了、身边 8 码内进战的敌人有「怪数」这么多以上、怒气不高于「怒气」，就切到狂暴姿态放一次旋风斩，放完自动切回战斗姿态。\n已经切到狂暴姿态后不再看怪数，打完旋风斩就切回去；切过去怒气不够时先攒着，放完再切回。\n右键：「怪数」几个敌人以上才切；「怒气」怒气在这个数以下才切（切姿态会丢怒气）。\n关掉后不再为旋风斩切姿态。\n宏：/WARRIOR_WHIRLWIND 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "WQZ_XLZ_AUTO", label = "旋风斩", default = true },
            { type = "slider", var = "WQZ_XLZ_COUNT", label = "怪数", min = 1, max = 10, step = 1, default = 2, suffix = "个" },
            { type = "slider", var = "WQZ_XLZ_RAGE", label = "怒气", min = 0, max = 100, step = 5, default = 25, suffix = "怒气" },
        },
    },
    WQZ_HSGJ = {
        title = "横扫攻击  功能",
        desc = "开着时，在战斗姿态下、身边 8 码内进战的敌人有「怪数」这么多以上，就自动放横扫攻击（接下来几次近战攻击会多打一个身边的敌人）。\n右键：「怪数」几个敌人以上才放；「怒气」二选——强制留怒 = 横扫攻击冷却好了就只平砍、别的耗怒气技能都不放，等它放出去；随缘 = 不给它留怒气，别的技能照常放，轮到它时怒气够就放。\n关掉后不再自动放；想单独放一次用插入「横扫」。\n宏：/WARRIOR_SWEEP_AUTO 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "WQZ_HSGJ", label = "横扫攻击", default = true },
            { type = "slider", var = "WQZ_HSGJ_COUNT", label = "怪数", min = 1, max = 10, step = 1, default = 2, suffix = "个" },
            { type = "radio", var = "WQZ_HSGJ_RAGE_MODE", label = "怒气", options = { { "强制留怒", 1 }, { "随缘", 2 } }, default = 2 },
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
    local def = WA.PopupDefs[key]
    if not def then return nil end
    local f = CreateFrame("Frame", "WR_WarriorArmsPopup_" .. key, UIParent, "BackdropTemplate")
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
            local val = WA.Num(PigSet[rowDef.var], rowDef.default or 0)
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
                local v = WA.Num(PigSet[rec.row.var], rec.row.default or 0)
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

WA.PopupCache = WA.PopupCache or {}

function WA.ShowOptions(key)
    WA.InitDefaults()
    local def = WA.PopupDefs[key]
    if not def then return end
    local f = WA.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        WA.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(WA.PopupCache) do
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
function WA.SetBurst(on)
    if type(PigSet) ~= "table" then return end
    PigSet.WQZ_LM = on and true or false
    PigSet.WQZ_ZDZZ = on and true or false
    WA.SyncCheckbox("WQZ_LM")
    WA.SyncCheckbox("WQZ_ZDZZ")
end

function WR_WarriorArmsBurstAllOn()
    if WR_WarriorArmsUI then WR_WarriorArmsUI.SetBurst(true) end
end

function WR_WarriorArmsBurstAllOff()
    if WR_WarriorArmsUI then WR_WarriorArmsUI.SetBurst(false) end
end

function WR_WarriorArmsBurstToggle()
    if not WR_WarriorArmsUI then return end
    local any = (PigSet.WQZ_LM == true) or (PigSet.WQZ_ZDZZ == true)
    WR_WarriorArmsUI.SetBurst(not any)
end

-- ============================================================
-- 7. 斜杠命令别名（对齐截图里的 /WARRIOR_xxx）
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
    WA.SyncCheckbox(var)
    local status = PigSet[var] and "|cff00ff00已开启|r" or "|cffff0000已关闭|r"
    local text = status .. " [" .. label .. "]"
    if type(WR_PrintToVisible) == "function" then
        WR_PrintToVisible(text)
    elseif type(print) == "function" then
        print(text)
    end
end

local function BindCommand(cmd, var, label)
    _G["SLASH_" .. cmd .. "1"] = "/" .. cmd
    SlashCmdList[cmd] = function(msg) SetVarByCommand(var, msg, label) end
end

BindCommand("WARRIOR_REND", "WQZ_SILIE", "撕裂")
BindCommand("WARRIOR_SUNDER_DPS", "WQZ_BDPJ", "破甲攻击")
BindCommand("WARRIOR_MS_POOL", "WQZ_MS_POOL", "致死打击让怒")
BindCommand("WARRIOR_WHIRLWIND", "WQZ_XLZ_AUTO", "旋风斩")
BindCommand("WARRIOR_BLOODRAGE", "WQZ_HXKJ", "血性狂暴")
BindCommand("WARRIOR_SWEEP_AUTO", "WQZ_HSGJ", "横扫攻击")
BindCommand("WARRIOR_THUNDER_DEMO", "WQZ_LTYJ", "雷霆挫志")

-- ============================================================
-- 8. 供循环使用的小工具
-- ============================================================
function WA.AutoAttack()
    if PlayerMove then return false end
    if not WA.TargetExistsAttackable() then return false end
    if TargetRange and TargetRange > 5 and TargetRange < 900 then return false end
    if type(IsCurrentSpell) == "function" then
        local ok, cur = pcall(IsCurrentSpell, "攻击")
        if ok and cur == true then return false end
    end
    if type(WR_SpellUsable) ~= "function" or not WR_SpellUsable("攻击") then return false end
    return WA.Show("攻击", 4)
end
