-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "PALADIN" then return end
-- ============================================================
-- Paladin_Holy_Features.lua
-- 神圣骑士（奶骑 · WoW Forever 60级）功能层
-- ------------------------------------------------------------
-- 只服务 PALADIN「神圣」专精：不写全局战斗状态、不影响防护/惩戒与其他职业。
--
-- 按「彼岸花-无限服 · 奶骑页」截图逐项落地：
--   功能：圣印 / 圣光誓约 / 祝福 / 切换目标 / 驱散 / 愤怒之锤 / 驱邪术
--   插入：制裁 / 圣佑 / 审判 / 奉献（一次性，放完自关）
--   拉条：喝红药 / 圣疗术 / 奉献目标数 / 圣光守望 / 神圣震击 / 圣光术 / 圣光闪现
--
-- 【本服真实技能（60级法术书）】
--   圣光术 635 / 圣光闪现 19750 / 神圣震击 1311606 / 神恩术 20216 /
--   圣疗术 633 / 清洁术 4987 / 圣盾术 642 / 圣光守望 1311595 /
--   圣光誓约 1328548 / 审判 20271 / 愤怒之锤 24239 / 驱邪术 879 /
--   奉献 20116 / 制裁之锤 853 / 圣佑术 498
--   ★ 80 级技能（圣光道标 / 圣洁护盾 / 神圣牺牲 / 光环掌握 / 复仇之怒 /
--     祈求圣光 / 神圣风暴）在无限服不存在，本层不再引用。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "PALADIN" then return end

WR_PaladinHolyUI = WR_PaladinHolyUI or {}
local HS = WR_PaladinHolyUI

-- ============================================================
-- 1. 常量：常驻圣印与审判表
-- ============================================================
-- 顺序与右键「圣印」窗口完全一致（截图 7 项）：
--   1 正义 / 2 十字军 / 3 命令 / 4 愤怒 / 5 公正 / 6 光明 / 7 智慧
HS.SEAL_OPTIONS = {
    { id = 1, name = "正义圣印",   slot = 47 },
    { id = 2, name = "十字军圣印", slot = 30 },
    { id = 3, name = "命令圣印",   slot = 12 },
    { id = 4, name = "愤怒圣印",   slot = 11 },
    { id = 5, name = "公正圣印",   slot = 9 },
    { id = 6, name = "光明圣印",   slot = 54 },
    { id = 7, name = "智慧圣印",   slot = 108 },
}

-- 审判维持表：key 与公共件 JudgementMemory 的 light/wisdom/crusader 对齐。
-- names = 目标 debuff 候选名（含旧翻译兜底）。
HS.JUDGEMENTS = {
    { key = "crusader", label = "十字军审判", seal = "十字军圣印", sealSlot = 30,
      var = "SS_SY_J_CRUSADER", pvar = "SS_SY_J_CRUSADER_N", pdefault = 3,
      names = { "十字军审判", "十字军圣印" } },
    { key = "wisdom",   label = "智慧审判",   seal = "智慧圣印",   sealSlot = 108,
      var = "SS_SY_J_WISDOM",   pvar = "SS_SY_J_WISDOM_N",   pdefault = 2,
      names = { "智慧审判", "智慧圣印" } },
    { key = "light",    label = "光明审判",   seal = "光明圣印",   sealSlot = 54,
      var = "SS_SY_J_LIGHT",    pvar = "SS_SY_J_LIGHT_N",    pdefault = 1,
      names = { "光明审判", "圣光审判", "光明圣印" } },
}

-- ============================================================
-- 2. 默认值与旧档迁移
-- ============================================================
function HS.Num(v, d)
    local n = tonumber(v)
    if n == nil then return d end
    return n
end

function HS.Bool(v, d)
    if v == nil then return d end
    return v == true
end

function HS.On(var, default)
    return HS.Bool(PigSet and PigSet[var], default)
end

function HS.Val(var, default)
    return HS.Num(PigSet and PigSet[var], default)
end

function HS.InitDefaults()
    if type(PigSet) ~= "table" then return end
    local function setb(k, v) if PigSet[k] == nil then PigSet[k] = v end end
    local function setn(k, v) if type(PigSet[k]) ~= "number" then PigSet[k] = v end end

    -- 旧档迁移：SS_SSZJ 旧版是下拉模式 1/2/3/4，新版是血量阈值滑块（截图 54%）
    if PigSet.SS_HOLY_MIGRATED == nil then
        local old = tonumber(PigSet.SS_SSZJ)
        if old ~= nil and old >= 1 and old <= 4 then
            local map = { [1] = 54, [2] = 60, [3] = 40, [4] = 0 }
            PigSet.SS_SSZJ = map[old] or 54
        end
        PigSet.SS_HOLY_MIGRATED = true
    end

    -- 功能开关（截图默认勾选）
    setb("SS_SY_ON", true)          -- 圣印总开关
    setb("SS_SY_MAIN_ON", true)     -- 常驻圣印
    setb("SS_SY_KCD", true)         -- 卡CD使用（审判好了就用常驻圣印打）
    setb("SS_SY_KEEP_JUDGE", true)  -- 保持审判总闸
    setb("SS_OATH_ON", true)        -- 圣光誓约（默认开，未选人什么都不做）
    setb("SS_BLESS_ON", true)       -- 祝福总开关
    setb("SS_TAB", true)            -- 切换目标
    setb("SS_QJS_ON", true)         -- 驱散
    setb("SS_FNZS", true)           -- 愤怒之锤
    setb("SS_QXS", true)            -- 驱邪术

    -- 插入（一次性，默认关）
    setb("SS_CRZC", false)          -- 制裁
    setb("SS_CRSY", false)          -- 圣佑
    setb("SS_CRSP", false)          -- 审判
    setb("SS_CRFL", false)          -- 奉献

    -- 拉条默认值（截图口径）
    setn("SS_HXY", 90)              -- 喝红药
    setn("SS_SLS", 69)              -- 圣疗术
    setn("SS_FL_COUNT", 4)          -- 奉献·目标数
    setn("SS_SGWS", 52)             -- 圣光守望
    setn("SS_SSZJ", 54)             -- 神圣震击
    setn("SS_SGS", 60)              -- 圣光术
    setn("SS_SGSX", 85)             -- 圣光闪现
    setn("SS_SDS", 30)              -- 圣盾术（保命，不在截图但保留）

    -- ★ 2026-11-17 奶骑加血逻辑：治疗模式 / 自动焦点 / 过量停条
    setn("SS_ZLMS", 1)              -- 治疗模式：1全团 / 2目标 / 3预读 / 4泄蓝 / 5坦克 / 6脆皮 / 7-11一~五队 / 12-15萨12/34/13/24
    setb("SS_ZDJD", true)           -- 自动焦点（有人低于阈值才切，保留手动焦点优先）
    setb("SS_GLTC", false)          -- 过量停条（默认关，参照旧版奶骑默认）
    setn("SS_GLTCCK", 5)            -- 过量停条窗口：1=0.1秒 ... 5=0.5秒

    -- 圣印 / 审判默认
    setn("SS_SY_SEAL", 7)           -- 常驻：智慧圣印（截图高亮）
    setn("SS_SY_J_CRUSADER_N", 3)
    setn("SS_SY_J_WISDOM_N", 2)
    setn("SS_SY_J_LIGHT_N", 1)
    setb("SS_SY_J_CRUSADER", false)
    setb("SS_SY_J_WISDOM", false)
    setb("SS_SY_J_LIGHT", false)

    -- 圣光誓约：给谁加（空 = 什么都不做）
    if PigSet.SS_OATH_TARGET == nil then PigSet.SS_OATH_TARGET = "" end
end

HS.InitDefaults()

function HS.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then pcall(WR_SyncConfigCheckbox, var) end
    if type(WR_SyncFrameCheckboxes) == "function" and WR_ConfigFrame then
        pcall(WR_SyncFrameCheckboxes, WR_ConfigFrame, var)
    end
end

-- ============================================================
-- 3. 基础判定
-- ============================================================
function HS.SpellKnown(name)
    if type(WR_PaladinForever_SpellKnown) == "function" then
        local ok, v = pcall(WR_PaladinForever_SpellKnown, name)
        if ok then return v == true end
    end
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

function HS.Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) ~= "function" then return false end
    return WR_ColorFrame_ShowSkill(spell, slot) == true
end

function HS.TargetExistsAttackable()
    if type(UnitExists) ~= "function" then return false end
    local ok, exists = pcall(UnitExists, "target")
    if not ok or exists ~= true then return false end
    if type(UnitIsDead) == "function" then
        local okD, dead = pcall(UnitIsDead, "target")
        if okD and dead == true then return false end
    end
    if type(UnitIsDeadOrGhost) == "function" then
        local okG, ghost = pcall(UnitIsDeadOrGhost, "target")
        if okG and ghost == true then return false end
    end
    if type(UnitCanAttack) == "function" then
        local okA, attackable = pcall(UnitCanAttack, "player", "target")
        if okA and attackable == false then return false end
    end
    return true
end

function HS.IsFocusUnit(unit)
    if type(UnitIsUnit) ~= "function" then return false end
    local ok, v = pcall(UnitIsUnit, "focus", unit)
    return ok and v == true
end

function HS.FocusSlot(unit)
    if type(unit) ~= "string" then return nil end
    if unit == "player" then return 192 end
    if unit == "target" then return 147 end
    local p = string.match(unit, "^party(%d)$")
    if p then
        local n = tonumber(p)
        if n and n >= 1 and n <= 4 then return 175 + n end
    end
    local r = string.match(unit, "^raid(%d+)$")
    if r then
        local n = tonumber(r)
        if n and n >= 1 and n <= 25 then return 120 + n end
    end
    return nil
end

function HS.TargetKey()
    if type(WR_PaladinForever_JudgementSealTargetKey) == "function" then
        local ok, key = pcall(WR_PaladinForever_JudgementSealTargetKey)
        if ok then return key end
    end
    return nil
end

function HS.InCombat()
    if type(UnitAffectingCombat) ~= "function" then return false end
    local ok, v = pcall(UnitAffectingCombat, "player")
    return ok and v == true
end

-- ============================================================
-- 4. 圣印：常驻圣印
-- ============================================================
function HS.SealOption(index)
    index = tonumber(index) or 7
    for i = 1, #HS.SEAL_OPTIONS do
        if HS.SEAL_OPTIONS[i].id == index then return HS.SEAL_OPTIONS[i] end
    end
    return HS.SEAL_OPTIONS[7]
end

function HS.MainSeal()
    local opt = HS.SealOption(PigSet and PigSet.SS_SY_SEAL)
    return opt.name, opt.slot
end

-- 玩家身上是否是指定圣印（光环可读优先；不可读时用最近成功施放记录兜底）
function HS.SealOnPlayer(name)
    if type(name) ~= "string" then return false end
    if type(WR_PaladinForever_SealBuffState) == "function" then
        local ok, state, cur = pcall(WR_PaladinForever_SealBuffState)
        if ok then
            if state == "up" and (cur == nil or cur == name) then return true end
            if state == "up" and cur ~= nil then return false end
        end
    end
    if type(WR_PaladinForever_GetLastCastAt) == "function" then
        local at = WR_PaladinForever_GetLastCastAt(name)
        if type(at) == "number" and (GetTime() - at) < 30 then return true end
    end
    return false
end

-- 常驻圣印维持：只在没有圣印 / 快到 / 被顶掉时补一次
-- 奶骑专用圣印点亮：圣印是自身 Buff，不要求近战目标（治疗可以站在远处）
function HS.ShowSeal(name, slot)
    if type(WR_SpellUsable) == "function" then
        local okU, usable = pcall(WR_SpellUsable, name, true)
        if okU and usable == false then return false end
    end
    if type(WR_ColorFrame_ShowSkill) ~= "function" then return false end
    if WR_ColorFrame_ShowSkill(name, slot) == true then
        if type(WR_PaladinForever_MarkPrompt) == "function" then
            WR_PaladinForever_MarkPrompt(name, slot)
        end
        if type(WR_PaladinForever_HideSkillLater) == "function" then
            WR_PaladinForever_HideSkillLater(name, slot, 1.5)
        end
        return true
    end
    return false
end

function HS.SealStep()
    if not HS.On("SS_SY_ON", true) then return false end
    if not HS.On("SS_SY_MAIN_ON", true) then return false end
    if (HS.JudgePhase or 0) ~= 0 then return false end

    local name, slot = HS.MainSeal()
    if not HS.SpellKnown(name) then return false end
    if type(WR_PaladinForever_SealNeedsRefresh) == "function" then
        local ok, need = pcall(WR_PaladinForever_SealNeedsRefresh, name)
        if not ok or need ~= true then return false end
    end

    if type(WR_PaladinForever_CanPrompt) == "function"
       and not WR_PaladinForever_CanPrompt("HS_MAIN_SEAL", 3) then return false end

    return HS.ShowSeal(name, slot)
end

-- ============================================================
-- 5. 审判维持（按优先级补十字军/智慧/光明审判）
-- ============================================================
HS.JudgePhase = HS.JudgePhase or 0
HS.JudgeKind = HS.JudgeKind or nil
HS.JudgeTargetKey = HS.JudgeTargetKey or nil
HS.JudgeAt = HS.JudgeAt or 0
HS.JudgeBase = HS.JudgeBase or 0
HS.JudgeDeadline = HS.JudgeDeadline or 0
HS.JudgeSwitchAt = HS.JudgeSwitchAt or 0

function HS.ResetJudgeState()
    HS.JudgePhase = 0
    HS.JudgeKind = nil
    HS.JudgeTargetKey = nil
    HS.JudgeAt = 0
    HS.JudgeBase = 0
    HS.JudgeDeadline = 0
    HS.JudgeSwitchAt = 0
end

function HS.JudgementRemain(rec)
    if type(WR_PaladinForever_JudgementSealDebuffRemain) == "function" then
        local ok, remain = pcall(WR_PaladinForever_JudgementSealDebuffRemain, rec.names, rec.key)
        if ok and type(remain) == "number" then return remain end
    end
    return 0
end

-- 返回需要补的第一个审判记录（按玩家设置的数字从小到大；同数字按表顺序）
function HS.PickMissingJudgement()
    local list = {}
    for i = 1, #HS.JUDGEMENTS do
        local rec = HS.JUDGEMENTS[i]
        if HS.On(rec.var, false) then
            local remain = HS.JudgementRemain(rec)
            if type(remain) ~= "number" or remain <= 0 then
                list[#list + 1] = { rec = rec, order = HS.Val(rec.pvar, rec.pdefault), index = i }
            end
        end
    end
    if #list == 0 then return nil end
    table.sort(list, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        return a.index < b.index
    end)
    return list[1].rec
end

function HS.JudgeStep()
    if not HS.On("SS_SY_ON", true) then
        HS.ResetJudgeState()
        return false
    end
    if not HS.TargetExistsAttackable() then
        HS.ResetJudgeState()
        return false
    end

    local now = GetTime()
    local targetKey = HS.TargetKey()
    if HS.JudgePhase ~= 0 and HS.JudgeTargetKey ~= nil and targetKey ~= nil
       and HS.JudgeTargetKey ~= targetKey then
        HS.ResetJudgeState()
    end

    local judgeCD = 10
    if type(WR_PaladinForever_GetJudgeCooldown) == "function" then
        local ok, cd = pcall(WR_PaladinForever_GetJudgeCooldown)
        if ok and type(cd) == "number" then judgeCD = cd end
    end

    -- 保持审判：按优先级找目标身上缺的那条
    if HS.On("SS_SY_KEEP_JUDGE", true) then
        local phase = HS.JudgePhase or 0

        if phase == 0 then
            local rec = HS.PickMissingJudgement()
            if rec then
                -- 审判没快好时不提前占用其他圣印
                local due = true
                if type(WR_PaladinForever_JudgementSwitchDue) == "function" then
                    local ok, v = pcall(WR_PaladinForever_JudgementSwitchDue, judgeCD)
                    if ok then due = v == true end
                end
                if due then
                    if type(WR_PaladinForever_CanHitTarget) == "function" then
                        local okR, inRange = pcall(WR_PaladinForever_CanHitTarget, "审判", "target")
                        if okR and inRange ~= true then return false end
                    end
                    if HS.SealOnPlayer(rec.seal) then
                        HS.JudgeKind = rec.key
                        HS.JudgeTargetKey = targetKey
                        HS.JudgeAt = now - 2
                        HS.JudgeBase = (type(WR_PaladinForever_SkillCastAt) == "table"
                                        and WR_PaladinForever_SkillCastAt["审判"]) or 0
                        HS.JudgePhase = 1
                        HS.JudgeDeadline = now + 10
                        phase = 1
                    elseif HS.SpellKnown(rec.seal) then
                        if type(WR_PaladinForever_CanApplySeal) == "function" then
                            local okC, can = pcall(WR_PaladinForever_CanApplySeal)
                            if okC and can ~= true then return false end
                        end
                        if HS.ShowSeal(rec.seal, rec.sealSlot) then
                            HS.JudgeKind = rec.key
                            HS.JudgeTargetKey = targetKey
                            HS.JudgeAt = now
                            HS.JudgePhase = 1
                            HS.JudgeDeadline = now + 10
                            return true
                        end
                    end
                end
            end
        end

        if phase == 1 then
            local rec = nil
            for i = 1, #HS.JUDGEMENTS do
                if HS.JUDGEMENTS[i].key == HS.JudgeKind then rec = HS.JUDGEMENTS[i]; break end
            end
            if not rec then HS.ResetJudgeState() return false end
            local sealAt = HS.JudgeAt or now
            if HS.SealOnPlayer(rec.seal) and (now - sealAt) >= 0.8 then
                local ready = true
                if type(WR_PaladinForever_Ready) == "function" then
                    local okR, v = pcall(WR_PaladinForever_Ready, "审判", judgeCD)
                    if okR then ready = v == true end
                end
                if ready and type(WR_PaladinForever_ShowSkillCD) == "function"
                   and WR_PaladinForever_ShowSkillCD("审判", 2, judgeCD) then
                    HS.JudgePhase = 2
                    HS.JudgeBase = (type(WR_PaladinForever_SkillCastAt) == "table"
                                    and WR_PaladinForever_SkillCastAt["审判"]) or 0
                    HS.JudgeDeadline = now + 10
                    return true
                end
            elseif (now - sealAt) > 4 then
                HS.ResetJudgeState()
                return false
            end
        end

        if phase == 2 then
            local castAt = (type(WR_PaladinForever_SkillCastAt) == "table"
                            and WR_PaladinForever_SkillCastAt["审判"]) or 0
            local castConfirmed = type(castAt) == "number" and castAt > (HS.JudgeBase or 0) + 0.001
            if castConfirmed then
                local rec = nil
                for i = 1, #HS.JUDGEMENTS do
                    if HS.JUDGEMENTS[i].key == HS.JudgeKind then rec = HS.JUDGEMENTS[i]; break end
                end
                if rec and type(WR_PaladinForever_NoteSingleSlotJudgement) == "function" then
                    pcall(WR_PaladinForever_NoteSingleSlotJudgement, rec.key, GetTime() + 40)
                end
                HS.JudgePhase = 3
                HS.JudgeSwitchAt = 0
                HS.JudgeDeadline = now + 15
                phase = 3
            elseif now > (HS.JudgeDeadline or (now + 1)) then
                HS.ResetJudgeState()
                return false
            end
        end

        if phase == 3 then
            local mainName, mainSlot = HS.MainSeal()
            if HS.SealOnPlayer(mainName) then
                HS.ResetJudgeState()
            elseif (now - (HS.JudgeSwitchAt or 0)) >= 2.0 then
                if HS.ShowSeal(mainName, mainSlot) then
                    HS.JudgeSwitchAt = now
                    return true
                end
            end
            if now > (HS.JudgeDeadline or (now + 1)) then HS.ResetJudgeState() end
            return false
        end
    end

    -- 卡CD使用：没有要补的审判时，用常驻圣印打审判（只补伤害/回蓝）
    if HS.On("SS_SY_KCD", true) and (HS.JudgePhase or 0) == 0 then
        local mainName = HS.MainSeal()
        if HS.SealOnPlayer(mainName) and type(WR_PaladinForever_ShowSkillCD) == "function"
           and type(WR_PaladinForever_SealActive) == "function" then
            local okA, active = pcall(WR_PaladinForever_SealActive)
            if okA and active == true and WR_PaladinForever_ShowSkillCD("审判", 2, judgeCD) then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 6. 圣光誓约（Oath of Light）
-- ============================================================
function HS.FindGroupUnitByName(name)
    if type(name) ~= "string" or name == "" then return nil end
    local units = { "player" }
    if type(WR_PaladinForeverHoly_GroupUnits) == "function" then
        local ok, list = pcall(WR_PaladinForeverHoly_GroupUnits)
        if ok and type(list) == "table" then units = list end
    end
    for i = 1, #units do
        local u = units[i]
        if type(u) == "string" and UnitExists and UnitExists(u) then
            local okN, n = pcall(UnitName, u)
            if okN and type(n) == "string" and n == name then return u end
        end
    end
    return nil
end

-- 圣光誓约维持：没 buff 或剩余 <15 秒时，把焦点切到指定队友再放
function HS.OathStep()
    if not HS.On("SS_OATH_ON", true) then return false end
    local name = PigSet and PigSet.SS_OATH_TARGET
    if type(name) ~= "string" or name == "" then return false end
    if not HS.SpellKnown("圣光誓约") then return false end

    local unit = HS.FindGroupUnitByName(name)
    if not unit then return false end
    if type(WR_PaladinForeverHoly_LowCount) == "function" and type(UnitIsDeadOrGhost) == "function" then
        local okD, dead = pcall(UnitIsDeadOrGhost, unit)
        if okD and dead == true then return false end
    end

    -- buff 还够 15 秒以上 → 不补
    if type(WR_GetUnitBuffTime) == "function" then
        local okB, remain = pcall(WR_GetUnitBuffTime, unit, "圣光誓约")
        if okB and type(remain) == "number" and remain > 15 then return false end
    end

    -- 刚提示过（还没确认施放）→ 3 秒内不重复
    local now = GetTime()
    if type(HS.OathPromptAt) == "number" and (now - HS.OathPromptAt) < 3 then return false end

    -- 治疗模式选「目标」且有人要奶时，不抢焦点
    if HS.Val("SS_ZLMS", 1) == 2 and type(WR_PaladinForeverHoly_LowCount) == "function" then
        local okL, low = pcall(WR_PaladinForeverHoly_LowCount, HS.Val("SS_SGSX", 85) / 100)
        if okL and type(low) == "number" and low > 0 then
            if not HS.IsFocusUnit(unit) then return false end
        end
    end

    -- 焦点不是他 → 先点亮设焦点色块
    local focusOK = HS.IsFocusUnit(unit)
    if not focusOK then
        local slot = nil
        if type(WR_PaladinForeverHoly_FocusSlot) == "function" then
            local okS, v = pcall(WR_PaladinForeverHoly_FocusSlot, unit)
            if okS and v then slot = v end
        end
        if not slot then slot = HS.FocusSlot(unit) end
        if slot and type(WR_ColorFrame_Show) == "function" and WR_ColorFrame_Show(slot, "设焦点") then
            HS.OathPromptAt = now
            return true
        end
        return false
    end

    if type(WR_PaladinForever_ShowSkillCD) == "function"
       and WR_PaladinForever_ShowSkillCD("圣光誓约", 112, 300) then
        HS.OathPromptAt = now
        HS.OathTarget = name
        return true
    end
    return false
end

-- ============================================================
-- 7. 其他功能
-- ============================================================
function HS.TargetSwitchStep()
    if not HS.On("SS_TAB", true) then return false end
    if HS.TargetExistsAttackable() then return false end
    if type(WR_PaladinForever_CanPrompt) == "function"
       and not WR_PaladinForever_CanPrompt("HS_TAB", 1.5) then return false end
    if HS.Show("切换目标", 90) then
        if type(WR_PaladinForever_MarkPrompt) == "function" then
            WR_PaladinForever_MarkPrompt("HS_TAB", 90)
        end
        return true
    end
    return false
end

function HS.PotionStep()
    local hp = HS.Val("SS_HXY", 90)
    if hp <= 0 then return false end
    local cur = 1
    if type(WR_GetUnitHP) == "function" then
        local ok, v = pcall(WR_GetUnitHP, "player")
        if ok and type(v) == "number" then cur = v end
    end
    if cur >= hp / 100 then return false end
    if type(WR_Use_ZLYS) ~= "function" then return false end
    local okU, can = pcall(WR_Use_ZLYS)
    if not okU or can ~= true then return false end
    return HS.Show("治疗药水", 79)
end

function HS.HammerStep()
    if not HS.On("SS_FNZS", true) then return false end
    if not HS.TargetExistsAttackable() then return false end
    if type(WR_PaladinForever_HammerExecuteReady) == "function" then
        local ok, ready = pcall(WR_PaladinForever_HammerExecuteReady)
        if not ok or ready ~= true then return false end
    elseif type(WR_SpellUsable) == "function" then
        local ok, usable = pcall(WR_SpellUsable, "愤怒之锤", true)
        if not ok or usable ~= true then return false end
    end
    if type(WR_PaladinForever_ShowSkillCD) == "function" then
        return WR_PaladinForever_ShowSkillCD("愤怒之锤", 1, 6)
    end
    return false
end

function HS.ExorcismStep()
    if not HS.On("SS_QXS", true) then return false end
    -- ★★★ 2026-11-18：参考 PaladinAssist 的 spell 状态机
    --   （C_Spell.IsSpellUsable + GetSpellCooldownDuration）。
    --   旧写法 WR_SpellUsable("驱邪术", true) 的 GCD 严格门使用全局 GCD /
    --   施法速度（奶骑会沿用上一个循环留下的 GCD），驱邪术会被永久判死。
    --   统一走共享步骤：三系同一口径，不再传 GlobalCooldown=true。
    if type(WR_PaladinForever_ExorcismStep) == "function" then
        return WR_PaladinForever_ExorcismStep()
    end
    if not HS.TargetExistsAttackable() then return false end
    if type(WR_PaladinForever_IsUndeadOrDemon) == "function" then
        local ok, hit = pcall(WR_PaladinForever_IsUndeadOrDemon, "target")
        if not ok or hit ~= true then return false end
    end
    if type(WR_SpellUsable) == "function" then
        local ok, usable = pcall(WR_SpellUsable, "驱邪术")
        if not ok or usable ~= true then return false end
    end
    if type(WR_PaladinForever_ShowSkillCD) == "function" then
        return WR_PaladinForever_ShowSkillCD("驱邪术", 20, 15)
    end
    return false
end

function HS.ConsecrationStep()
    local need = HS.Val("SS_FL_COUNT", 4)
    if need <= 0 then return false end
    if type(WR_GetRangeHarmUnitCount) ~= "function" then return false end
    local okC, count = pcall(WR_GetRangeHarmUnitCount, 8)
    if not okC or type(count) ~= "number" or count < need then return false end
    if type(WR_SpellUsable) == "function" then
        local ok, usable = pcall(WR_SpellUsable, "奉献", true)
        if not ok or usable ~= true then return false end
    end
    if type(WR_PaladinForever_ShowSkillCD) == "function" then
        return WR_PaladinForever_ShowSkillCD("奉献", 5, 8)
    end
    return false
end

-- 一次性插入：点亮色块后自动取消勾选
function HS.InsertOnce(var, spell, slot, cd)
    if not HS.On(var, false) then return false end
    if type(WR_SpellUsable) == "function" then
        local ok, usable = pcall(WR_SpellUsable, spell, true)
        if not ok or usable ~= true then return false end
    end
    local shown
    if cd and type(WR_PaladinForever_ShowSkillCD) == "function" then
        shown = WR_PaladinForever_ShowSkillCD(spell, slot, cd)
    else
        shown = HS.Show(spell, slot)
    end
    if shown then
        PigSet[var] = false
        HS.SyncCheckbox(var)
        return true
    end
    return false
end

function HS.InsertStep()
    -- 制裁：目标正在读条且 10 码内
    if HS.On("SS_CRZC", false) then
        local casting = false
        if type(WR_PaladinForever_TargetCasting) == "function" then
            local ok, v = pcall(WR_PaladinForever_TargetCasting)
            if ok and v == true then casting = true end
        end
        if casting then
            if HS.InsertOnce("SS_CRZC", "制裁之锤", 22, 60) then return true end
        end
    end
    -- 圣佑：自己血量低于 SS_SDS
    if HS.On("SS_CRSY", false) then
        local hp = 1
        if type(WR_GetUnitHP) == "function" then
            local ok, v = pcall(WR_GetUnitHP, "player")
            if ok and type(v) == "number" then hp = v end
        end
        if hp < HS.Val("SS_SDS", 30) / 100 then
            if HS.InsertOnce("SS_CRSY", "圣佑术", 78, 300) then return true end
        end
    end
    -- 审判：身上有圣印时打一发
    if HS.On("SS_CRSP", false) then
        local active = false
        if type(WR_PaladinForever_SealActive) == "function" then
            local ok, v = pcall(WR_PaladinForever_SealActive)
            if ok and v == true then active = true end
        end
        if active then
            local cd = 10
            if type(WR_PaladinForever_GetJudgeCooldown) == "function" then
                local ok, v = pcall(WR_PaladinForever_GetJudgeCooldown)
                if ok and type(v) == "number" then cd = v end
            end
            if HS.InsertOnce("SS_CRSP", "审判", 2, cd) then return true end
        end
    end
    -- 奉献：按拉条的怪数检查
    if HS.On("SS_CRFL", false) then
        local need = HS.Val("SS_FL_COUNT", 4)
        if need > 0 and type(WR_GetRangeHarmUnitCount) == "function" then
            local ok, count = pcall(WR_GetRangeHarmUnitCount, 8)
            if ok and type(count) == "number" and count >= need then
                if HS.InsertOnce("SS_CRFL", "奉献", 5, 8) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 8. 右键「额外条件」小窗
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

HS.PopupDefs = {
    SS_SY = {
        title = "圣印  功能",
        width = 400,
        desc = "圣印总开关：开着时按右键里的设置管圣印。\n\n"
            .. "常驻圣印：平时身上保持哪个圣印（没有或快到时就补）；标题前面的勾去掉 = 平时不补圣印。\n"
            .. "「卡CD使用」勾着 = 审判冷却好就常拿常驻圣印审判。\n\n"
            .. "保持审判：给目标补哪种审判——每行前面的勾 = 参不参加，后面的拉条 = 第几个挂，数字小的先挂（两个数字一样时按从上到下）；标题前面的勾去掉 = 都不挂。\n\n"
            .. "自己只能在目标身上挂一种审判：目标身上已经有你挂的就不管；没有就按顺序找第一个目标身上还没有的（别的圣骑士挂的也算有），审判快好的时候临时换上那个圣印、审判一次，挂完换回常驻圣印。\n\n"
            .. "默认开，审判默认都不勾。\n"
            .. "宏：/PALADIN_SEAL_ON 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "SS_SY_ON", label = "圣印", default = true },
            { type = "check", var = "SS_SY_MAIN_ON", label = "常驻圣印", default = true, indent = 18 },
            { type = "check", var = "SS_SY_KCD", label = "卡CD使用", default = true, indent = 34 },
            { type = "seal", var = "SS_SY_SEAL", default = 7, indent = 34 },
            { type = "check", var = "SS_SY_KEEP_JUDGE", label = "保持审判", default = true },
            { type = "judge", var = "SS_SY_J_CRUSADER", pvar = "SS_SY_J_CRUSADER_N", label = "十字军审判", default = false, pdefault = 3 },
            { type = "judge", var = "SS_SY_J_WISDOM", pvar = "SS_SY_J_WISDOM_N", label = "智慧审判", default = false, pdefault = 2 },
            { type = "judge", var = "SS_SY_J_LIGHT", pvar = "SS_SY_J_LIGHT_N", label = "光明审判", default = false, pdefault = 1 },
        },
    },
    SS_OATH = {
        title = "圣光誓约  功能",
        width = 360,
        desc = "开着时右键「给谁加」里勾的那个人保持圣光誓约：他身上没有、或剩不到 15 秒，就先把焦点切到他再放（有人要奶、治疗模式选「目标」时不切焦点）。\n\n"
            .. "一次只能挂一个人，换人就在右键名单里勾别人；没勾人、他不在队里或死了不放。\n\n"
            .. "默认开（2026-11-11 起），没勾人就什么都不做。\n"
            .. "宏：/PALADIN_OATH 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "SS_OATH_ON", label = "圣光誓约", default = true },
            { type = "edit", var = "SS_OATH_TARGET", label = "给谁加", width = 170 },
        },
    },
}

local function BuildPopup(key)
    local def = HS.PopupDefs[key]
    if not def then return nil end
    local width = def.width or 360
    local f = CreateFrame("Frame", "WR_PaladinHolyPopup_" .. key, UIParent, "BackdropTemplate")
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
            slider:SetMinMaxValues(rowDef.min or 0, rowDef.max or 100)
            slider:SetValueStep(rowDef.step or 1)
            slider:SetObeyStepOnDrag(true)
            slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
            local thumb = slider:GetThumbTexture()
            if thumb then thumb:SetSize(6, 14); thumb:SetVertexColor(0.82, 0.84, 0.87, 1) end
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            local val = HS.Num(PigSet[rowDef.var], rowDef.default or 0)
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
        elseif rowDef.type == "seal" then
            local buttons = {}
            local startX = 14 + indent
            for i = 1, #HS.SEAL_OPTIONS do
                local opt = HS.SEAL_OPTIONS[i]
                local col = (i - 1) % 4
                local line = math.floor((i - 1) / 4)
                local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
                btn:SetSize(82, 21)
                btn:SetPoint("TOPLEFT", f, "TOPLEFT", startX + col * 86, y - line * 24)
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
            rows[#rows + 1] = { kind = "seal", row = rowDef, buttons = buttons }
            addRow(54)
        elseif rowDef.type == "judge" then
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", f, "TOPLEFT", 24 + indent, y)
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            cb:SetChecked(PigSet[rowDef.var] == true)
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95, 120)
            label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            cb:SetScript("OnClick", function(self)
                PigSet[rowDef.var] = self:GetChecked() and true or false
            end)
            local slider = CreateFrame("Slider", nil, f)
            slider:SetOrientation("HORIZONTAL")
            slider:SetSize(80, 10)
            slider:SetPoint("TOPLEFT", f, "TOPLEFT", width - 136, y - 5)
            slider:SetMinMaxValues(1, 10)
            slider:SetValueStep(1)
            slider:SetObeyStepOnDrag(true)
            slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
            local thumb = slider:GetThumbTexture()
            if thumb then thumb:SetSize(6, 14); thumb:SetVertexColor(0.82, 0.84, 0.87, 1) end
            if PigSet[rowDef.pvar] == nil then PigSet[rowDef.pvar] = rowDef.pdefault end
            local val = HS.Num(PigSet[rowDef.pvar], rowDef.pdefault or 1)
            slider:SetValue(val)
            local valText = MakeFont(f, tostring(val) .. "号", 12, 0.62, 0.65, 0.69, 40)
            valText:SetPoint("LEFT", slider, "RIGHT", 6, 0)
            local function update(v)
                v = math.floor((v or 0) + 0.5)
                PigSet[rowDef.pvar] = v
                valText:SetText(tostring(v) .. "号")
            end
            update(val)
            slider:SetScript("OnValueChanged", function(self, v) update(v) end)
            rows[#rows + 1] = { kind = "judge", row = rowDef, control = cb, slider = slider, valText = valText }
            addRow(27)
        elseif rowDef.type == "edit" then
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95, 80)
            label:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + indent, y - 4)
            local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
            eb:SetSize(rowDef.width or 170, 22)
            eb:SetPoint("LEFT", label, "RIGHT", 8, 0)
            eb:SetAutoFocus(false)
            eb:SetMaxLetters(40)
            eb:SetText(tostring(PigSet[rowDef.var] or ""))
            eb:SetScript("OnTextChanged", function(self)
                PigSet[rowDef.var] = self:GetText() or ""
            end)
            eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
            rows[#rows + 1] = { kind = "edit", row = rowDef, control = eb }
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
                local v = HS.Num(PigSet[rec.row.var], rec.row.default or 0)
                rec.control:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            elseif rec.kind == "seal" then
                local cur = tonumber(PigSet[rec.row.var]) or rec.row.default or 7
                for _, b in ipairs(rec.buttons) do
                    local on = (cur == b.id)
                    if b.btn.SetBackdropColor then
                        if on then b.btn:SetBackdropColor(0.35, 0.27, 0.10, 1)
                        else b.btn:SetBackdropColor(0.12, 0.13, 0.15, 0.9) end
                    end
                    b.txt:SetTextColor(on and 1 or 0.65, on and 0.82 or 0.65, on and 0.2 or 0.65)
                end
            elseif rec.kind == "judge" then
                rec.control:SetChecked(PigSet[rec.row.var] == true)
                local v = HS.Num(PigSet[rec.row.pvar], rec.row.pdefault or 1)
                rec.slider:SetValue(v)
                rec.valText:SetText(tostring(v) .. "号")
            elseif rec.kind == "edit" then
                rec.control:SetText(tostring(PigSet[rec.row.var] or ""))
            end
        end
    end
    return f
end

HS.PopupCache = HS.PopupCache or {}

function HS.ShowOptions(key)
    HS.InitDefaults()
    local def = HS.PopupDefs[key]
    if not def then return end
    local f = HS.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        HS.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(HS.PopupCache) do
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

function HS.AttachOptions(config, key)
    if type(config) == "table" then
        config.onRightClick = function() HS.ShowOptions(key) end
    end
end

-- ============================================================
-- 9. 斜杠命令
-- ============================================================
local function ToggleSwitch(var, label)
    if type(PigSet) ~= "table" then return end
    PigSet[var] = not (PigSet[var] == true)
    HS.SyncCheckbox(var)
    print("|cff00ff00[" .. label .. "]|r " .. (PigSet[var] and "开启" or "关闭"))
end

SLASH_PALADIN_SEAL_ON1 = "/PALADIN_SEAL_ON"
SLASH_PALADIN_SEAL_ON2 = "/PALADIN_SEALON"
if type(SlashCmdList) == "table" then
    SlashCmdList["PALADIN_SEAL_ON"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SS_SY_ON = true; HS.SyncCheckbox("SS_SY_ON")
        elseif msg == "off" then PigSet.SS_SY_ON = false; HS.SyncCheckbox("SS_SY_ON")
        else ToggleSwitch("SS_SY_ON", "圣印") end
    end
end

SLASH_PALADIN_OATH1 = "/PALADIN_OATH"
if type(SlashCmdList) == "table" then
    SlashCmdList["PALADIN_OATH"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SS_OATH_ON = true; HS.SyncCheckbox("SS_OATH_ON")
        elseif msg == "off" then PigSet.SS_OATH_ON = false; HS.SyncCheckbox("SS_OATH_ON")
        else ToggleSwitch("SS_OATH_ON", "圣光誓约") end
    end
end

SLASH_PALADIN_BLESS1 = "/PALADIN_BLESS"
if type(SlashCmdList) == "table" then
    SlashCmdList["PALADIN_BLESS"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SS_BLESS_ON = true; HS.SyncCheckbox("SS_BLESS_ON")
        elseif msg == "off" then PigSet.SS_BLESS_ON = false; HS.SyncCheckbox("SS_BLESS_ON")
        else ToggleSwitch("SS_BLESS_ON", "祝福") end
    end
end