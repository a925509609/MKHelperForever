-- ============================================================
-- Warrior_Protection_Features.lua
-- 防护战士（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 WARRIOR「防护」专精，不写全局、不影响武器/狂怒与其他职业。
--
-- 本文件按截图（猪猪 / 彼岸花-无限服 · 防战页，2026-11-16 同步）逐项落地：
--   功能：撕裂 / 雷霆挫志 / 格挡 / 血性狂暴 / 破甲攻击 /
--         切姿态 / 战斗怒吼 / 切换目标 / 嘲讽 / 鲁莽挥击
--   插入：反击风暴 / 震荡猛击 / 挑战怒吼 / 盾墙 / 挫志怒吼 /
--         拦截 / 惩戒痛击 / 狂暴之怒（一次性，放完自关）
--   拉条：顺劈斩 / 英勇打击 / 乘胜追击 / 破釜沉舟 / 喝红药 / 打断
--   额外条件：右键对应图标打开（撕裂/格挡/破甲/雷霆挫志/血性狂暴/切姿态/鲁莽挥击）
--
-- 说明：当前客户端为 60 级法术书（2026-11-13 Data_SpellBook）：
--   撕裂 11574 / 破甲攻击 11597 / 盾牌格挡 2565 / 盾牌猛击 23925 /
--   复仇 25288 / 雷霆一击 11581 / 挫志怒吼 11556 / 战斗怒吼 25289 /
--   盾墙 871 / 嘲讽 355 / 拦截 20617 / 惩戒痛击 20560 / 乘胜追击 402927 /
--   震荡猛击 12809 / 鲁莽挥击 1329555（防护天赋新技能，4 次近战额外 5 怒气/次）。
-- ============================================================

if WR_PlayerClass ~= "WARRIOR" then return end

WR_WarriorProt = WR_WarriorProt or {}
local WP = WR_WarriorProt

-- ============================================================
-- 1. 默认值与旧档兼容
-- ------------------------------------------------------------
-- 规则：只补 nil，绝不覆盖用户已有设置；旧布尔 FZ_CSZJ 迁到 FZ_CSZJ_ON。
-- ============================================================
function WP.InitDefaults()
    if type(PigSet) ~= "table" then return end
    local function setb(k, v) if PigSet[k] == nil then PigSet[k] = v end end
    local function setn(k, v) if type(PigSet[k]) ~= "number" then PigSet[k] = v end end

    -- 主功能开关（默认开启，和截图一致）
    setb("FZ_SILIE", true)       -- 撕裂
    setb("FZ_LTYJ", true)        -- 雷霆挫志（总开关）
    setb("FZ_DPGD", true)        -- 格挡
    setb("FZ_HXKJ", true)        -- 血性狂暴
    setb("FZ_BDPJ", true)        -- 破甲攻击
    setb("FZ_QTZ", true)         -- 切姿态
    setb("FZ_ZDZH", true)        -- 战斗怒吼
    setb("FZ_TAB", false)        -- 切换目标（默认关）
    setb("FZ_CT", false)         -- 嘲讽（默认关，避免抢其他坦克仇恨）
    setb("FZ_LMHJ", true)        -- 鲁莽挥击
    setb("FZ_KG_ZDZZ", true)     -- 种族爆发

    -- 插入（一次性，默认关）
    setb("FZ_FJFB_CR", false)
    setb("FZ_ZCMJ_CR", false)
    setb("FZ_TZNH_CR", false)
    setb("FZ_DQ_CR", false)
    setb("FZ_CZNH_CR", false)
    setb("FZ_JL_CR", false)
    setb("FZ_CJTJ_CR", false)
    setb("FZ_KBZN_CR", false)

    -- 拉条默认值
    setn("FZ_SPZ", 30)           -- 顺劈斩怒气
    setn("FZ_YYDJ", 20)          -- 英勇打击怒气
    setn("FZ_CSZJ", 70)          -- 乘胜追击血量
    setn("FZ_HXY", 30)           -- 喝红药血量
    setn("FZ_KG_PFCZ", 20)       -- 破釜沉舟血量
    setn("FZ_KG_QJ", 60)         -- 打断施法进度

    -- 撕裂额外条件
    setb("FZ_SILIE_NO_ELEMENT", true)
    setb("FZ_SILIE_NO_MECH", true)
    setb("FZ_SILIE_NO_UNDEAD", true)
    setn("FZ_SILIE_LEAD", 6)

    -- 格挡额外条件（默认只勾卡CD，和截图一致）
    setb("FZ_GB_MULTI", true)    -- 格挡多目标（截图默认勾选）
    setn("FZ_GB_MULTI_COUNT", 2)
    setb("FZ_GB_CD", true)
    setb("FZ_GB_HP", false)
    setn("FZ_GB_HP_PCT", 60)

    -- 破甲攻击额外条件
    setb("FZ_PJ_ONLY1", false)
    setb("FZ_PJ_HIGH", false)    -- 破甲高优先级（截图默认不勾）
    setb("FZ_PJ_LOW", false)
    setn("FZ_PJ_REFRESH", 3)

    -- 雷霆挫志额外条件（1=保持 / 2=卡CD / 3=不放）
    setn("FZ_LT_AOE_MODE", 3)    -- 雷霆一击多目标默认「不放」（截图口径）
    setn("FZ_LT_AOE_COUNT", 2)
    setn("FZ_LT_MISS", 0)
    setn("FZ_LT_SINGLE_MODE", 1)
    setn("FZ_CZ_AOE_MODE", 3)
    setn("FZ_CZ_AOE_COUNT", 3)
    setn("FZ_CZ_MISS", 0)
    setn("FZ_CZ_SINGLE_MODE", 3)

    -- 血性狂暴额外条件
    setn("FZ_HXKJ_NQ", 90)
    setn("FZ_HXKJ_XL", 0)

    -- 切姿态额外条件
    setb("FZ_QTZ_OOC", true)
    setb("FZ_QTZ_IC", true)

    -- 鲁莽挥击：怒气低于该值才用
    setn("FZ_LMHJ_NQ", 70)

    -- 乘胜追击旧档：FZ_CSZJ 曾经是「复仇循环」布尔开关，不是真的乘胜追击开关。
    -- 迁移到新的 FZ_CSZJ_ON（默认开）+ FZ_CSZJ（拉条 70）。
    if type(PigSet.FZ_CSZJ) == "boolean" then PigSet.FZ_CSZJ = 70 end
    setb("FZ_CSZJ_ON", true)

    -- 撕裂旧档：FZ_SILIE 曾经是「复仇循环」里的布尔开关（默认关，且旧循环未使用）。
    -- 一次性迁移成新功能的默认开；迁移标记保证之后用户手动关掉不会被重新打开。
    if PigSet.FZ_SILIE_MIGRATED == nil then
        PigSet.FZ_SILIE = true
        PigSet.FZ_SILIE_MIGRATED = true
    end
end

WP.InitDefaults()

-- ============================================================
-- 2. 安全读取小工具
-- ============================================================
function WP.Num(v, d)
    if type(v) == "number" then return v end
    return d
end

function WP.Bool(v, d)
    if type(v) == "boolean" then return v end
    return d
end

function WP.On(var, default)
    return WP.Bool(PigSet and PigSet[var], default)
end

function WP.Val(var, default)
    return WP.Num(PigSet and PigSet[var], default)
end

-- 当前姿态：1 战斗 / 2 防御 / 3 狂暴 / 0 未知
function WP.Stance()
    if type(GetShapeshiftForm) == "function" then
        local ok, form = pcall(GetShapeshiftForm)
        if ok and type(form) == "number" and form > 0 then
            -- 优先用形态信息里的技能名确认（不同客户端 form 序号可能不同）
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

function WP.CreatureType()
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

-- 目标类型过滤：元素 / 机械 / 亡灵（中英双译名都匹配）
function WP.IsCreatureTypeExcluded(noElement, noMech, noUndead)
    local ct = WP.CreatureType()
    if not ct then return false end
    if noElement and (ct == "元素" or ct == "Elemental") then return true end
    if noMech and (ct == "机械" or ct == "Mechanical") then return true end
    if noUndead and (ct == "亡灵" or ct == "Undead") then return true end
    return false
end

function WP.TargetExistsAttackable()
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

-- 目标预计剩余存活秒数（8888 = 读不到按放行）
function WP.TargetTTD()
    if type(WR_GetUnitDeathTime) == "function" then
        local ok, v = pcall(WR_GetUnitDeathTime, "target")
        if ok and type(v) == "number" then return v end
    end
    return 8888
end

function WP.BuffRemain(name, byMe)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local onlyMe = (byMe ~= false)
    local ok, v = pcall(WR_GetUnitBuffTime, "player", name, onlyMe)
    if ok then return WP.Num(v, 0) end
    return 0
end

function WP.DebuffRemain(name)
    if type(WR_GetUnitDebuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffTime, "target", name, true)
    if ok then return WP.Num(v, 0) end
    return 0
end

function WP.DebuffCount(name)
    if type(WR_GetUnitDebuffCount) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffCount, "target", name, true)
    if ok then return WP.Num(v, 0) end
    return 0
end

-- 冷却剩余秒数（读不到返回 999）
function WP.CooldownLeft(spell)
    if type(WR_SpellCooldownInfo) ~= "function" then return 999 end
    local ok, start, duration = pcall(WR_SpellCooldownInfo, spell)
    if not ok then return 999 end
    start = WP.Num(start, 0)
    duration = WP.Num(duration, 0)
    if duration <= 0 then return 0 end
    local left = start + duration - GetTime()
    if left < 0 then left = 0 end
    return left
end

function WP.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, v = pcall(WR_Forever_IsSpellKnown, name)
        if ok then return v == true end
    end
    return false
end

function WP.Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) ~= "function" then return false end
    return WR_ColorFrame_ShowSkill(spell, slot) == true
end

-- 把面板勾选态刷成存档值（一次性插入放完自关时用）
function WP.SyncCheckbox(var)
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
-- 撕裂：目标没有自己施加的撕裂才补；目标流血免疫（元素/机械/亡灵勾选）不打；
--       预判目标活不过 N 秒不打（0=都放）。
function WP.RendWanted()
    if not WP.On("FZ_SILIE", true) then return false end
    if not WP.TargetExistsAttackable() then return false end
    if WP.IsCreatureTypeExcluded(WP.On("FZ_SILIE_NO_ELEMENT", true),
        WP.On("FZ_SILIE_NO_MECH", true), WP.On("FZ_SILIE_NO_UNDEAD", true)) then
        return false
    end
    if WP.DebuffRemain("撕裂") > 0 then return false end
    local lead = WP.Val("FZ_SILIE_LEAD", 6)
    if lead > 0 then
        local ttd = WP.TargetTTD()
        if ttd < 900 and ttd < lead then return false end
    end
    return true
end

-- 格挡：多目标 / 卡CD / 血量，任意一条满足就放（截图原文）
function WP.ShieldBlockWanted()
    if not WP.On("FZ_DPGD", true) then return false end
    if WP.On("FZ_GB_CD", true) then return true end
    if WP.On("FZ_GB_MULTI", false) and (UnitCount8 or 0) >= WP.Val("FZ_GB_MULTI_COUNT", 2) then
        return true
    end
    if WP.On("FZ_GB_HP", false) and PlayerHP and PlayerHP < WP.Val("FZ_GB_HP_PCT", 60) / 100 then
        return true
    end
    return false
end

-- 破甲攻击：返回 0=不打 / 1=只打1破 / 2=高优先级 / 3=低优先级 / 4=续破
function WP.SunderMode()
    if not WP.On("FZ_BDPJ", true) then return 0 end
    -- 目标身上有盗贼的破甲（不同 debuff 名）时不抢
    if WP.DebuffRemain("破甲") > 0 then return 0 end
    local stacks = WP.DebuffCount("破甲攻击")
    local remain = WP.DebuffRemain("破甲攻击")
    local refresh = WP.Val("FZ_PJ_REFRESH", 3)
    if WP.On("FZ_PJ_ONLY1", false) then
        -- 截图口径：目标快死时不放
        local ttd = WP.TargetTTD()
        if ttd < 900 and ttd < 6 then return 0 end
        if stacks <= 0 then return 1 end
        return 0
    end
    if stacks < 5 then
        if WP.On("FZ_PJ_HIGH", true) then return 2 end
        if WP.On("FZ_PJ_LOW", false) then return 3 end
    end
    if stacks >= 5 and remain <= refresh then return 4 end
    return 0
end

-- 雷霆/挫志：返回 true=该放；mode 1保持 / 2卡CD / 3不放
function WP.ThunderWanted()
    if not WP.On("FZ_LTYJ", true) then return false end
    local mode
    if (UnitCount8 or 0) >= WP.Val("FZ_LT_AOE_COUNT", 2) then
        mode = WP.Val("FZ_LT_AOE_MODE", 1)
    else
        mode = WP.Val("FZ_LT_SINGLE_MODE", 1)
    end
    if mode == 3 then return false end
    if mode == 2 then return true end
    local miss = WP.Val("FZ_LT_MISS", 0)
    if miss > 0 and (UnitCount8 or 0) >= miss and WP.DebuffRemain("雷霆一击") <= 0 then return true end
    return WP.DebuffRemain("雷霆一击") <= 1.5
end

function WP.DemoShoutWanted()
    if not WP.On("FZ_LTYJ", true) then return false end
    local mode
    if (UnitCount8 or 0) >= WP.Val("FZ_CZ_AOE_COUNT", 3) then
        mode = WP.Val("FZ_CZ_AOE_MODE", 3)
    else
        mode = WP.Val("FZ_CZ_SINGLE_MODE", 3)
    end
    -- 截图口径：挫志怒吼只有 保持(1) / 不放(3) 两档（旧档卡CD=2 一律按不放处理）
    if mode ~= 1 then return false end
    local miss = WP.Val("FZ_CZ_MISS", 0)
    if miss > 0 and (UnitCount8 or 0) >= miss and WP.DebuffRemain("挫志怒吼") <= 0 then return true end
    return WP.DebuffRemain("挫志怒吼") <= 1.5
end

-- 乘胜追击：击杀敌人后 20 秒内可用，立即攻击并恢复最大生命 10%（30 秒 CD）。
-- 拉条 = 自己血量低于该百分比才用（70 = 70%）；血量读不到时只要客户端可用就用。
function WP.VictoryRushWanted()
    if not WP.On("FZ_CSZJ_ON", true) then return false end
    if type(WR_SpellUsable) ~= "function" or not WR_SpellUsable("乘胜追击", true) then return false end
    local pct = PlayerHP
    if type(pct) ~= "number" then return true end
    -- 血量可读时严格按拉条；读不到（secret）才交给客户端可用性放行
    local known = true
    if type(UnitHealth) == "function" and type(WR_IsSecretValue) == "function" then
        local okH, raw = pcall(UnitHealth, "player")
        if not okH or type(raw) ~= "number" or WR_IsSecretValue(raw) then known = false end
    end
    if not known then return true end
    if pct >= 0.999 then return false end
    return pct <= WP.Val("FZ_CSZJ", 70) / 100
end

-- 血性狂暴：怒气低于拉条、血量高于拉条（0=不看血量）
function WP.BloodrageWanted()
    if not WP.On("FZ_HXKJ", true) then return false end
    if (Rage or 0) >= WP.Val("FZ_HXKJ_NQ", 90) then return false end
    local hpGate = WP.Val("FZ_HXKJ_XL", 0)
    if hpGate > 0 and PlayerHP and PlayerHP < hpGate / 100 then return false end
    return true
end

-- 鲁莽挥击：怒气低于拉条才用；buff 还在就不重复
function WP.RecklessSwingWanted()
    if not WP.On("FZ_LMHJ", true) then return false end
    if WP.BuffRemain("鲁莽挥击") > 0 then return false end
    return (Rage or 0) < WP.Val("FZ_LMHJ_NQ", 70)
end

-- 种族爆发：读当前种族的爆发技能列表，任意一个「真的能打」就提示（宏 181）。
-- ★★★ 2026-11-21 三十五次修复：补 CD 维。旧实现只问 WR_SpellUsable，
--   而无限战斗中 GetSpellCooldown 是 secret → WR_GetGCD 收敛成 0 → GCD 门恒成立
--   → 3 分钟大招（狂暴 20554）被当成随时可用 → 用了还一直亮。
--   现统一走 WR_Forever_RacialBurstReady（已学会 + 本地记账 CD + 客户端冷却 +
--   提示保持窗口 + 客户端可用性）。
function WP.RacialBurstWanted()
    if not WP.On("FZ_KG_ZDZZ", true) then return false end
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
function WP.InsertOnce(var, spell, slot, extraOk)
    if not WP.On(var, false) then return false end
    if extraOk == false then return false end
    if type(WR_SpellUsable) ~= "function" or not WR_SpellUsable(spell, true) then return false end
    if WP.Show(spell, slot) then
        PigSet[var] = false
        WP.SyncCheckbox(var)
        return true
    end
    return false
end

-- 姿态切换辅助：插入的反击/拦截/惩戒痛击开着且快好了时先不切防御姿态
function WP.StanceInsertPending()
    local function readySoon(spell, sec)
        -- 没学会/客户端不存在的技能不参与「等它放出去」的判断，避免卡姿态
        if not WP.SpellKnown(spell) then return false end
        return WP.CooldownLeft(spell) <= (sec or 2)
    end
    if WP.On("FZ_FJFB_CR", false) and readySoon("反击风暴") then return true end
    if WP.On("FZ_CJTJ_CR", false) and readySoon("惩戒痛击") then return true end
    if WP.On("FZ_JL_CR", false) and readySoon("拦截") then return true end
    return false
end

-- ============================================================
-- 5. 右键「额外条件」小窗
-- ------------------------------------------------------------
-- MK 主面板仍是图标+勾选；右键图标弹出与该技能对应的小窗，
-- 控件与原版截图一致（小勾选 / 三态按钮 / 拉条）。
-- ============================================================
WP.PopupDefs = {
    FZ_SILIE = {
        title = "撕裂  功能",
        desc = "开着时，目标身上没有自己施加的撕裂就自动补一次；撕裂还在时不重复补。\n目标流血免疫不打。",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "FZ_SILIE_NO_ELEMENT", label = "不打元素", default = true },
            { type = "check", var = "FZ_SILIE_NO_MECH", label = "不打机械", default = true },
            { type = "check", var = "FZ_SILIE_NO_UNDEAD", label = "不打亡灵", default = true },
            { type = "slider", var = "FZ_SILIE_LEAD", label = "预判", min = 0, max = 30, step = 1, default = 6, suffix = "秒", hint = "0 = 都放" },
        },
    },
    FZ_LTYJ = {
        title = "雷霆挫志  功能",
        desc = "开着时按右键里的设置放雷霆一击和挫志怒吼（各自满足任意一条就放）。\n雷霆一击：「多目标」身边敌人够「怪数」时，选 保持 = 目标身上没有自己的雷霆一击或 1.5 秒内结束就补、选 卡CD = 冷却好就放；「缺数」身边没挂自己雷霆一击的怪够这么多就放；「单体」不看人数，选保持/卡CD。\n挫志怒吼：「多目标」身边敌人够「怪数」、目标没挂或 1.5 秒内结束就补；「缺数」身边没挂自己挫志怒吼的怪够这么多就放；「单体」不看人数，目标没挂就补。\n怒气不够、冷却没好或目标在近战范围外时不会放。\n关掉后两个都不自动放。\n宏：/WARRIOR_THUNDER_DEMO 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "雷霆一击" },
            { type = "radio", var = "FZ_LT_AOE_MODE", label = "多目标", options = { { "保持", 1 }, { "卡CD", 2 }, { "不放", 3 } }, default = 3 },
            { type = "slider", var = "FZ_LT_AOE_COUNT", label = "怪数", min = 1, max = 10, step = 1, default = 2, suffix = "个" },
            { type = "slider", var = "FZ_LT_MISS", label = "缺数", min = 0, max = 10, step = 1, default = 0, suffix = "个", hint = "关闭 = 0" },
            { type = "radio", var = "FZ_LT_SINGLE_MODE", label = "单体", options = { { "保持", 1 }, { "卡CD", 2 }, { "不放", 3 } }, default = 1 },
            { type = "header", text = "挫志怒吼" },
            { type = "radio", var = "FZ_CZ_AOE_MODE", label = "多目标", options = { { "保持", 1 }, { "不放", 3 } }, default = 3 },
            { type = "slider", var = "FZ_CZ_AOE_COUNT", label = "怪数", min = 1, max = 10, step = 1, default = 3, suffix = "个" },
            { type = "slider", var = "FZ_CZ_MISS", label = "缺数", min = 0, max = 10, step = 1, default = 0, suffix = "个", hint = "关闭 = 0" },
            { type = "radio", var = "FZ_CZ_SINGLE_MODE", label = "单体", options = { { "保持", 1 }, { "不放", 3 } }, default = 3 },
        },
    },
    FZ_DPGD = {
        title = "格挡  功能",
        desc = "开着时按右键里的额外条件放盾牌格挡（短时间内格挡几率大幅提高，少挨近战伤害），满足任意一条就放。\n「多目标」身边 8 码内进战的敌人够后面拉条的个数。\n「卡CD」不看人数，冷却好就放。\n「血量」自己血量低于后面拉条的百分比。\n默认只勾「卡CD」= 冷却好就放。要在防御姿态下、手里拿着盾、贴着目标才放得出来。\n关掉后不再自动放盾牌格挡。\n宏：/WARRIOR_SHIELDBLOCK 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "FZ_GB_MULTI", label = "多目标", default = true },
            { type = "slider", var = "FZ_GB_MULTI_COUNT", label = "  怪物数", min = 1, max = 10, step = 1, default = 2, suffix = "个" },
            { type = "check", var = "FZ_GB_CD", label = "卡CD", default = true },
            { type = "check", var = "FZ_GB_HP", label = "血量", default = false },
            { type = "slider", var = "FZ_GB_HP_PCT", label = "  百分比", min = 0, max = 100, step = 5, default = 60, suffix = "%" },
        },
    },
    FZ_HXKJ = {
        title = "血性狂暴  功能",
        desc = "开着时，开打后自动放血性狂暴（掉一点血换怒气，冷却好了就补）。",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "slider", var = "FZ_HXKJ_NQ", label = "怒气", min = 0, max = 100, step = 5, default = 90, suffix = "怒气" },
            { type = "slider", var = "FZ_HXKJ_XL", label = "血量", min = 0, max = 100, step = 5, default = 0, suffix = "%", hint = "0 = 不看血量" },
        },
    },
    FZ_BDPJ = {
        title = "破甲攻击  功能",
        desc = "开着时按右键里的额外条件放破甲攻击（降低目标护甲、拉仇恨），只算自己叠的破甲。\n「只打1破」排在前面，目标身上没有就挂 1 层（目标快死时不放）。\n「高优先级」排在前面，叠到 5 层。\n「低优先级」排在最后，不到 5 层时没别的技能可放才拿破甲填空。\n已经挂上的破甲剩不到「续破秒数」就续。目标身上有盗贼的破甲（和破甲攻击互斥）时不放。\n关掉后不再自动放破甲攻击。\n宏：/WARRIOR_SUNDER 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "FZ_PJ_ONLY1", label = "只打1破", default = false },
            { type = "check", var = "FZ_PJ_HIGH", label = "高优先级", default = false },
            { type = "check", var = "FZ_PJ_LOW", label = "低优先级", default = false },
            { type = "slider", var = "FZ_PJ_REFRESH", label = "续破秒数", min = 0, max = 30, step = 1, default = 3, suffix = "秒" },
        },
    },
    FZ_QTZ = {
        title = "切姿态  功能",
        desc = "开着时按右键里的额外条件自动切姿态。\n「脱战切战斗」脱战后不在战斗姿态就切到战斗姿态，方便开怪用冲锋（点了天赋「先锋」，防御姿态也能冲锋，就不切）。\n「进战切防御」进入战斗后不在防御姿态就切到防御姿态，插入「反击」「拦截」「惩戒痛击」开着、技能快好了时不切，等它放出去。",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "FZ_QTZ_OOC", label = "脱战切战斗", default = true },
            { type = "check", var = "FZ_QTZ_IC", label = "进战切防御", default = true },
        },
    },
    FZ_LMHJ = {
        title = "鲁莽挥击  功能",
        desc = "防护天赋新技能：接下来 4 次近战攻击每次额外产生 5 点怒气，持续 8 秒。\n怒气低于拉条时使用；buff 还在时不重复。",
        rows = {
            { type = "slider", var = "FZ_LMHJ_NQ", label = "怒气低于", min = 0, max = 100, step = 5, default = 70, suffix = "怒气" },
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
    local def = WP.PopupDefs[key]
    if not def then return nil end
    local f = CreateFrame("Frame", "WR_WarriorProtPopup_" .. key, UIParent, "BackdropTemplate")
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
            local val = WP.Num(PigSet[rowDef.var], rowDef.default or 0)
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
                local v = WP.Num(PigSet[rec.row.var], rec.row.default or 0)
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

WP.PopupCache = WP.PopupCache or {}

function WP.ShowOptions(key)
    WP.InitDefaults()
    local def = WP.PopupDefs[key]
    if not def then return end
    local f = WP.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        WP.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    -- 只留一个小窗
    for _, other in pairs(WP.PopupCache) do
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

function WP.AttachOptions(config, key)
    if type(config) == "table" then
        config.onRightClick = function() WP.ShowOptions(key) end
    end
end

-- ============================================================
-- 6. 供循环使用的小工具（避免在旋转文件里塞太多控制流）
-- ============================================================
function WP.AutoAttack()
    if PlayerMove then return false end
    if not WP.TargetExistsAttackable() then return false end
    if TargetRange and TargetRange > 5 and TargetRange < 900 then return false end
    if type(IsCurrentSpell) == "function" then
        local ok, cur = pcall(IsCurrentSpell, "攻击")
        if ok and cur == true then return false end
    end
    if type(WR_SpellUsable) ~= "function" or not WR_SpellUsable("攻击") then return false end
    return WP.Show("攻击", 4)
end

function WP.SpellReadySoon(spell, sec)
    return WP.CooldownLeft(spell) <= (sec or 2)
end

-- ============================================================
-- 7. 爆发按钮（全开 / 全关 / 切换）
-- ============================================================
function WP.SetBurst(on)
    if type(PigSet) ~= "table" then return end
    PigSet.FZ_KG_ZDZZ = on and true or false
    WP.SyncCheckbox("FZ_KG_ZDZZ")
end

function WR_WarriorProtBurstAllOn()
    if WR_WarriorProt then WR_WarriorProt.SetBurst(true) end
end

function WR_WarriorProtBurstAllOff()
    if WR_WarriorProt then WR_WarriorProt.SetBurst(false) end
end

function WR_WarriorProtBurstToggle()
    if not WR_WarriorProt then return end
    WR_WarriorProt.SetBurst(PigSet.FZ_KG_ZDZZ ~= true)
end

-- ============================================================
-- 8. 斜杠命令（对齐截图宏 /WARRIOR_xxx）
-- ------------------------------------------------------------
-- 武器战 / 狂怒战先注册了同名命令：存入共享注册表，防护时走防护变量，
-- 其他专精回落原处理函数，互不覆盖。
-- ============================================================
local function WP_SetVarByCommand(var, msg, label)
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
    WP.SyncCheckbox(var)
    local status = PigSet[var] and "|cff00ff00已开启|r" or "|cffff0000已关闭|r"
    local text = status .. " [" .. label .. "]"
    if type(WR_PrintToVisible) == "function" then
        WR_PrintToVisible(text)
    elseif type(print) == "function" then
        print(text)
    end
end

-- ★ 防护是最后加载的专精：直接捕获当前处理函数（武器→狂怒链）作为回落，
-- 不写 WR_WarriorSharedCommandPrev（那是武器→狂怒链的存储；防护再写会把
-- 狂怒处理函数挤掉，导致狂怒专精下命令回落到武器战变量）。
local function WP_BindSharedCommand(cmd, var, label)
    if type(SlashCmdList) ~= "table" then return end
    local base = SlashCmdList[cmd]
    _G["SLASH_" .. cmd .. "1"] = "/" .. cmd
    SlashCmdList[cmd] = function(msg)
        local spec = nil
        if type(WR_GetMyTalent) == "function" then
            local ok, v = pcall(WR_GetMyTalent)
            if ok and type(v) == "string" then spec = v end
        end
        if spec == "防护" then
            WP_SetVarByCommand(var, msg, label)
        elseif type(base) == "function" then
            base(msg)
        end
    end
end

WP_BindSharedCommand("WARRIOR_REND", "FZ_SILIE", "撕裂")
WP_BindSharedCommand("WARRIOR_SUNDER", "FZ_BDPJ", "破甲攻击")
WP_BindSharedCommand("WARRIOR_BLOODRAGE", "FZ_HXKJ", "血性狂暴")
WP_BindSharedCommand("WARRIOR_THUNDER_DEMO", "FZ_LTYJ", "雷霆挫志")
WP_BindSharedCommand("WARRIOR_STANCE", "FZ_QTZ", "切姿态")
WP_BindSharedCommand("WARRIOR_SHIELDBLOCK", "FZ_DPGD", "格挡")
