-- ============================================================
-- Paladin_Retribution_Features.lua
-- 惩戒骑士（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 PALADIN「惩戒」专精：不写全局战斗状态、不影响防护/神圣与其他职业。
--
-- 按「彼岸花-无限服 · 惩戒页」截图逐项落地：
--   选择：防ADD（沿用 FANG_ADD_CJQ 下拉）
--   拉条：喝红药 / 圣疗术 / 奉献（目标数）
--   功能：圣印 / 祝福 / 切换目标 / 驱散 / 愤怒之锤 / 驱邪术
--   插入：制裁 / 圣佑 / 审判 / 奉献（一次性，放完自关）
--
-- 圣印右键设置（截图口径）：
--   解封之怒（要点了天赋才能作用）：命令圣印、正义圣印轮流叠回响，
--   叠满 3 层就换另一个，审判冷却好就打；它起作用时常驻圣印/保持审判都不管。
--   下拉选「不管」= 舞印期间不补审判；选十字军/智慧/光明 = 审判快好时
--   临时换上对应圣印、审判一次，挂完换回舞印。
--   常驻圣印：平时保持哪个圣印（7 选 1）+「卡CD使用」。
--   保持审判：十字军/智慧/光明审判按「第几号」优先级补。
--
-- 【本服真实技能（60级法术书）】
--   审判 20271 / 神圣打击(60级 Rank8=10333) / 命令圣印(天赋 20920) /
--   正义圣印 / 十字军圣印 / 愤怒圣印 / 公正圣印 / 光明圣印 / 智慧圣印 /
--   驱邪术 / 愤怒之锤 24239 / 奉献 / 制裁之锤 / 圣佑术 / 圣疗术 /
--   清洁术 4987 / 解封之怒（惩戒第7行被动天赋 1310735）
--   ★ 80 级技能（复仇之怒 / 祈求圣光 / 神圣牺牲 / 十字军打击 /
--     神圣震击 / 神恩术 / 真理之声 / 光之守夜 / 圣殿壁垒）在无限服
--     惩戒不存在或非惩戒天赋，本层不再引用。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "PALADIN" then return end

WR_PaladinRetUI = WR_PaladinRetUI or {}
local RT = WR_PaladinRetUI

-- ============================================================
-- 1. 常量：常驻圣印 / 审判表 / 解封之怒舞印对
-- ============================================================
-- 顺序与右键「圣印」窗口完全一致（截图 7 项）：
--   1 正义 / 2 十字军 / 3 命令 / 4 愤怒 / 5 公正 / 6 光明 / 7 智慧
RT.SEAL_OPTIONS = {
    { id = 1, name = "正义圣印",   slot = 47 },
    { id = 2, name = "十字军圣印", slot = 30 },
    { id = 3, name = "命令圣印",   slot = 12 },
    { id = 4, name = "愤怒圣印",   slot = 11 },
    { id = 5, name = "公正圣印",   slot = 9 },
    { id = 6, name = "光明圣印",   slot = 54 },
    { id = 7, name = "智慧圣印",   slot = 108 },
}

-- 审判维持表：key 与公共件 JudgementMemory 的 light/wisdom/crusader 对齐。
RT.JUDGEMENTS = {
    { key = "crusader", label = "十字军审判", seal = "十字军圣印", sealSlot = 30,
      var = "CJ_SY_J_CRUSADER", pvar = "CJ_SY_J_CRUSADER_N", pdefault = 3,
      names = { "十字军审判", "十字军圣印" } },
    { key = "wisdom",   label = "智慧审判",   seal = "智慧圣印",   sealSlot = 108,
      var = "CJ_SY_J_WISDOM",   pvar = "CJ_SY_J_WISDOM_N",   pdefault = 2,
      names = { "智慧审判", "智慧圣印" } },
    { key = "light",    label = "光明审判",   seal = "光明圣印",   sealSlot = 54,
      var = "CJ_SY_J_LIGHT",    pvar = "CJ_SY_J_LIGHT_N",    pdefault = 1,
      names = { "光明审判", "圣光审判", "光明圣印" } },
}

-- 解封之怒舞印对：命令 ↔ 正义轮流（截图口径）
RT.DANCE_PAIR = {
    { name = "命令圣印", slot = 12 },
    { name = "正义圣印", slot = 47 },
}

-- 解封之怒·审判编织：1 不管 / 2 十字军 / 3 智慧 / 4 光明（截图单选项）
RT.JF_KINDS = {
    { id = 1, label = "不管" },
    { id = 2, label = "十字军", rec = 1 },
    { id = 3, label = "智慧",   rec = 2 },
    { id = 4, label = "光明",   rec = 3 },
}

-- 驱散模式（MK 清洁术下拉语义，搬进右键小窗）
RT.QJS_MODES = {
    { id = 1, label = "常规" },
    { id = 2, label = "优先" },
    { id = 3, label = "目标" },
    { id = 4, label = "指向" },
}

-- ============================================================
-- 2. 默认值与旧档迁移
-- ============================================================
function RT.Num(v, d)
    local n = tonumber(v)
    if n == nil then return d end
    return n
end

function RT.Bool(v, d)
    if v == nil then return d end
    return v == true
end

function RT.On(var, default)
    return RT.Bool(PigSet and PigSet[var], default)
end

function RT.Val(var, default)
    return RT.Num(PigSet and PigSet[var], default)
end

function RT.InitDefaults()
    if type(PigSet) ~= "table" then return end
    local function setb(k, v) if PigSet[k] == nil then PigSet[k] = v end end
    local function setn(k, v) if type(PigSet[k]) ~= "number" then PigSet[k] = v end end

    -- 旧档迁移：插入制裁旧变量 CJ_CRZCZC → CJ_CRZC（只迁移一次）
    if PigSet.CJ_RET_MIGRATED == nil then
        if PigSet.CJ_CRZC == nil and PigSet.CJ_CRZCZC == true then
            PigSet.CJ_CRZC = true
        end
        PigSet.CJ_RET_MIGRATED = true
    end

    -- 功能开关（截图默认勾选）
    setb("CJ_SY_ON", true)          -- 圣印总开关
    setb("CJ_SY_JF", true)          -- 解封之怒（未点天赋自动不生效）
    setb("CJ_SY_MAIN_ON", true)     -- 常驻圣印
    setb("CJ_SY_KCD", true)         -- 卡CD使用（审判好就拿常驻圣印审判）
    setb("CJ_SY_KEEP_JUDGE", true)  -- 保持审判总闸（子项默认不勾）
    setb("CJ_BLESS_ON", true)       -- 祝福
    setb("CJ_TAB", true)            -- 切换目标
    setb("CJ_QJS_ON", true)         -- 驱散
    setb("CJ_FNZS", true)           -- 愤怒之锤
    setb("CJ_QXS", true)            -- 驱邪术

    -- 插入（一次性，默认关）
    setb("CJ_CRZC", false)          -- 制裁
    setb("CJ_CRSYS", false)         -- 圣佑
    setb("CJ_CRSP", false)          -- 审判
    setb("CJ_CRFL", false)          -- 奉献

    -- 拉条默认值（截图口径：喝红药90 / 圣疗术69 / 奉献4目标）
    setn("CJ_HXY", 90)
    setn("CJ_SLLS", 69)
    setn("CJ_FX_COUNT", 4)

    -- 圣印 / 审判默认
    setn("CJ_SY_SEAL", 3)           -- 常驻：命令圣印（惩戒输出印；截图 7 选 1）
    setn("CJ_SY_JF_KIND", 1)        -- 解封之怒·审判编织：不管
    setn("CJ_SY_J_CRUSADER_N", 3)
    setn("CJ_SY_J_WISDOM_N", 2)
    setn("CJ_SY_J_LIGHT_N", 1)
    setb("CJ_SY_J_CRUSADER", false)
    setb("CJ_SY_J_WISDOM", false)
    setb("CJ_SY_J_LIGHT", false)

    -- 驱散模式（旧档已有数值则保留；新装默认常规）
    setn("CJ_QJS", 1)
end

RT.InitDefaults()

function RT.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then pcall(WR_SyncConfigCheckbox, var) end
    if type(WR_SyncFrameCheckboxes) == "function" and WR_ConfigFrame then
        pcall(WR_SyncFrameCheckboxes, WR_ConfigFrame, var)
    end
end

-- ============================================================
-- 3. 基础判定
-- ============================================================
function RT.SpellKnown(name)
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

function RT.Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) ~= "function" then return false end
    return WR_ColorFrame_ShowSkill(spell, slot) == true
end

function RT.TargetExistsAttackable()
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

function RT.TargetKey()
    if type(WR_PaladinForever_JudgementSealTargetKey) == "function" then
        local ok, key = pcall(WR_PaladinForever_JudgementSealTargetKey)
        if ok then return key end
    end
    return nil
end

function RT.CanHitJudge()
    if type(WR_PaladinForever_CanHitTarget) == "function" then
        local ok, v = pcall(WR_PaladinForever_CanHitTarget, "审判", "target")
        if ok then return v == true end
    end
    return true
end

function RT.JudgeDue(judgeCD)
    if type(WR_PaladinForever_JudgementSwitchDue) == "function" then
        local ok, v = pcall(WR_PaladinForever_JudgementSwitchDue, judgeCD)
        if ok then return v == true end
    end
    return true
end

function RT.JudgementRemain(rec)
    if type(WR_PaladinForever_JudgementSealDebuffRemain) == "function" then
        local ok, remain = pcall(WR_PaladinForever_JudgementSealDebuffRemain, rec.names, rec.key)
        if ok and type(remain) == "number" then return remain end
    end
    return 0
end

-- ============================================================
-- 4. 圣印：常驻圣印 / 解封之怒回响层数
-- ============================================================
function RT.SealOption(index)
    index = tonumber(index) or 3
    for i = 1, #RT.SEAL_OPTIONS do
        if RT.SEAL_OPTIONS[i].id == index then return RT.SEAL_OPTIONS[i] end
    end
    return RT.SEAL_OPTIONS[3]
end

function RT.MainSeal()
    local opt = RT.SealOption(PigSet and PigSet.CJ_SY_SEAL)
    return opt.name, opt.slot
end

-- 玩家身上是否是指定圣印（光环可读优先；不可读时用最近成功施放记录兜底）
function RT.SealOnPlayer(name)
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

-- 圣印点亮（含防刷屏提示登记）
function RT.ShowSeal(name, slot)
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

-- 解封之怒回响层数（读不到返回 nil，走时间兜底）
function RT.EchoStacks()
    if type(WR_GetUnitBuffInfo) ~= "function" then return nil end
    local candidates = { "解封之怒", "回响" }
    for i = 1, #candidates do
        local ok, _, count = pcall(WR_GetUnitBuffInfo, "player", candidates[i])
        if ok and type(count) == "number" and count > 0 then return count end
    end
    return nil
end

-- ============================================================
-- 5. 审判编织状态机（切审判印 → 审判 → 换回）
--    供「保持审判」与「解封之怒·审判编织」共用。
-- ============================================================
RT.Weave = { phase = 0 }

function RT.ResetWeave()
    RT.Weave.phase = 0
    RT.Weave.kind = nil
    RT.Weave.seal = nil
    RT.Weave.slot = nil
    RT.Weave.returnSeal = nil
    RT.Weave.returnSlot = nil
    RT.Weave.targetKey = nil
    RT.Weave.at = 0
    RT.Weave.base = 0
    RT.Weave.deadline = 0
    RT.Weave.switchAt = 0
end

function RT.WeaveStart(rec, returnName, returnSlot)
    local now = GetTime()
    RT.Weave.kind = rec.key
    RT.Weave.seal = rec.seal
    RT.Weave.slot = rec.sealSlot
    RT.Weave.returnSeal = returnName
    RT.Weave.returnSlot = returnSlot
    RT.Weave.targetKey = RT.TargetKey()
    RT.Weave.at = now
    RT.Weave.base = (type(WR_PaladinForever_SkillCastAt) == "table"
                     and WR_PaladinForever_SkillCastAt["审判"]) or 0
    RT.Weave.deadline = now + 10
    RT.Weave.switchAt = 0
    RT.Weave.phase = 1

    if not RT.SealOnPlayer(rec.seal) then
        if type(WR_PaladinForever_CanApplySeal) == "function" then
            local okC, can = pcall(WR_PaladinForever_CanApplySeal)
            if okC and can ~= true then
                RT.ResetWeave()
                return false
            end
        end
        if not RT.ShowSeal(rec.seal, rec.sealSlot) then
            RT.ResetWeave()
            return false
        end
    else
        RT.Weave.at = now - 2   -- 已在身上，下一拍直接审判
    end
    return true
end

function RT.WeaveStep(judgeCD)
    local w = RT.Weave
    local now = GetTime()
    if w.phase ~= 0 and w.targetKey ~= nil then
        local key = RT.TargetKey()
        if key ~= nil and key ~= w.targetKey then
            RT.ResetWeave()
            return false
        end
    end

    local rec = nil
    for i = 1, #RT.JUDGEMENTS do
        if RT.JUDGEMENTS[i].key == w.kind then rec = RT.JUDGEMENTS[i]; break end
    end
    if not rec then
        RT.ResetWeave()
        return false
    end

    if w.phase == 1 then
        if RT.SealOnPlayer(rec.seal) and (now - (w.at or now)) >= 0.8 then
            local ready = true
            if type(WR_PaladinForever_Ready) == "function" then
                local okR, v = pcall(WR_PaladinForever_Ready, "审判", judgeCD)
                if okR then ready = v == true end
            end
            if ready and type(WR_PaladinForever_ShowSkillCD) == "function"
               and WR_PaladinForever_ShowSkillCD("审判", 2, judgeCD) then
                w.base = (type(WR_PaladinForever_SkillCastAt) == "table"
                          and WR_PaladinForever_SkillCastAt["审判"]) or 0
                w.deadline = now + 10
                w.phase = 2
                return true
            end
        elseif (now - (w.at or now)) > 6 then
            RT.ResetWeave()
        end
        return false
    end

    if w.phase == 2 then
        local castAt = (type(WR_PaladinForever_SkillCastAt) == "table"
                        and WR_PaladinForever_SkillCastAt["审判"]) or 0
        if type(castAt) == "number" and castAt > (w.base or 0) + 0.001 then
            if type(WR_PaladinForever_NoteSingleSlotJudgement) == "function" then
                pcall(WR_PaladinForever_NoteSingleSlotJudgement, rec.key, GetTime() + 40)
            end
            w.switchAt = 0
            w.deadline = now + 15
            w.phase = 3
            return false
        elseif now > (w.deadline or now) then
            RT.ResetWeave()
        end
        return false
    end

    if w.phase == 3 then
        if w.returnSeal and RT.SealOnPlayer(w.returnSeal) then
            RT.ResetWeave()
            return false
        elseif (now - (w.switchAt or 0)) >= 2.0 then
            if w.returnSeal and RT.ShowSeal(w.returnSeal, w.returnSlot) then
                w.switchAt = now
                return true
            end
        end
        if now > (w.deadline or now) then RT.ResetWeave() end
        return false
    end

    RT.ResetWeave()
    return false
end

-- ============================================================
-- 6. 解封之怒舞：命令 ↔ 正义轮流叠 3 层回响换印，审判好就打
-- ============================================================
RT.DanceSeal = RT.DanceSeal or nil
RT.DanceSince = RT.DanceSince or 0

function RT.ResetDanceState()
    RT.DanceSeal = nil
    RT.DanceSince = 0
end

function RT.DanceStep(judgeCD)
    if not RT.TargetExistsAttackable() then
        RT.ResetWeave()
        return false
    end
    local now = GetTime()

    local cur, other
    for i = 1, #RT.DANCE_PAIR do
        if RT.DANCE_PAIR[i].name == RT.DanceSeal then
            cur = RT.DANCE_PAIR[i]
            other = RT.DANCE_PAIR[3 - i]
            break
        end
    end
    if not cur then
        cur = RT.DANCE_PAIR[1]
        other = RT.DANCE_PAIR[2]
        RT.DanceSeal = cur.name
        RT.DanceSince = now
    end

    -- 1) 编织：勾了十字军/智慧/光明时，审判快好先补那个审判
    local kindId = RT.Val("CJ_SY_JF_KIND", 1)
    if kindId >= 2 and RT.JudgeDue(judgeCD) then
        local rec = RT.JUDGEMENTS[kindId - 1]
        if rec and RT.SpellKnown(rec.seal) then
            local remain = RT.JudgementRemain(rec)
            if (type(remain) ~= "number" or remain <= 0) and RT.CanHitJudge() then
                if RT.WeaveStart(rec, cur.name, cur.slot) then return true end
            end
        end
    end

    -- 2) 换印：回响叠满 3 层（可读）或同印超过 12 秒（层数读不到的兜底）
    local stacks = RT.EchoStacks()
    if (stacks ~= nil and stacks >= 3) or (now - (RT.DanceSince or now)) >= 12 then
        if RT.SpellKnown(other.name) and RT.ShowSeal(other.name, other.slot) then
            RT.DanceSeal = other.name
            RT.DanceSince = now
            return true
        end
    end

    -- 3) 当前舞印没了 / 快到期 → 补
    if type(WR_PaladinForever_SealNeedsRefresh) == "function" then
        local ok, need = pcall(WR_PaladinForever_SealNeedsRefresh, cur.name)
        if ok and need == true and RT.ShowSeal(cur.name, cur.slot) then
            RT.DanceSince = now
            return true
        end
    end

    -- 4) 「不管」：审判冷却好就拿当前舞印审判
    if kindId <= 1 and RT.JudgeDue(judgeCD) then
        if type(WR_PaladinForever_SealActive) == "function" then
            local okA, active = pcall(WR_PaladinForever_SealActive)
            if okA and active == true and RT.CanHitJudge()
               and type(WR_PaladinForever_ShowSkillCD) == "function"
               and WR_PaladinForever_ShowSkillCD("审判", 2, judgeCD) then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 7. 保持审判 + 卡CD审判（非舞模式）
-- ============================================================
function RT.PickMissingJudgement()
    local list = {}
    for i = 1, #RT.JUDGEMENTS do
        local rec = RT.JUDGEMENTS[i]
        if RT.On(rec.var, false) then
            local remain = RT.JudgementRemain(rec)
            if type(remain) ~= "number" or remain <= 0 then
                list[#list + 1] = { rec = rec, order = RT.Val(rec.pvar, rec.pdefault), index = i }
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

function RT.KeepJudgeStep(judgeCD)
    if not RT.TargetExistsAttackable() then return false end

    -- 保持审判：按玩家设置的优先级补第一个缺的审判
    if RT.On("CJ_SY_KEEP_JUDGE", true) then
        local rec = RT.PickMissingJudgement()
        if rec and RT.SpellKnown(rec.seal) and RT.JudgeDue(judgeCD) and RT.CanHitJudge() then
            local name, slot = RT.MainSeal()
            if RT.WeaveStart(rec, name, slot) then return true end
        end
    end

    -- 卡CD使用：没有要补的审判时，用常驻圣印打审判
    if RT.On("CJ_SY_KCD", true) then
        local mainName = RT.MainSeal()
        if RT.SealOnPlayer(mainName) and type(WR_PaladinForever_SealActive) == "function" then
            local okA, active = pcall(WR_PaladinForever_SealActive)
            if okA and active == true and type(WR_PaladinForever_ShowSkillCD) == "function"
               and WR_PaladinForever_ShowSkillCD("审判", 2, judgeCD) then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 8. 圣印层总入口
-- ============================================================
function RT.SealStep()
    if not RT.On("CJ_SY_ON", true) then
        RT.ResetWeave()
        return false
    end

    local judgeCD = 10
    if type(WR_PaladinForever_GetJudgeCooldown) == "function" then
        local ok, cd = pcall(WR_PaladinForever_GetJudgeCooldown)
        if ok and type(cd) == "number" then judgeCD = cd end
    end

    -- 编织进行中：优先推进（切审判印 → 审判 → 换回）
    if (RT.Weave.phase or 0) ~= 0 then
        return RT.WeaveStep(judgeCD)
    end

    -- 解封之怒舞（要点了天赋才生效）
    if RT.On("CJ_SY_JF", true) and RT.SpellKnown("解封之怒") then
        return RT.DanceStep(judgeCD)
    end

    -- 常驻圣印维持
    if RT.On("CJ_SY_MAIN_ON", true) then
        local name, slot = RT.MainSeal()
        if RT.SpellKnown(name) and type(WR_PaladinForever_SealNeedsRefresh) == "function" then
            local ok, need = pcall(WR_PaladinForever_SealNeedsRefresh, name)
            if ok and need == true then
                if type(WR_PaladinForever_CanPrompt) == "function"
                   and not WR_PaladinForever_CanPrompt("RT_MAIN_SEAL", 3) then
                    return false
                end
                if RT.ShowSeal(name, slot) then return true end
            end
        end
    end

    -- 保持审判 + 卡CD审判
    return RT.KeepJudgeStep(judgeCD)
end

-- ============================================================
-- 9. 其他功能
-- ============================================================
function RT.TargetSwitchStep()
    if not RT.On("CJ_TAB", true) then return false end
    if RT.TargetExistsAttackable() then return false end
    if type(WR_PaladinForever_CanPrompt) == "function"
       and not WR_PaladinForever_CanPrompt("RT_TAB", 1.5) then return false end
    if RT.Show("切换目标", 90) then
        if type(WR_PaladinForever_MarkPrompt) == "function" then
            WR_PaladinForever_MarkPrompt("RT_TAB", 90)
        end
        return true
    end
    return false
end

function RT.PotionStep()
    local hp = RT.Val("CJ_HXY", 90)
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
    return RT.Show("治疗药水", 75)
end

function RT.HammerStep()
    if not RT.On("CJ_FNZS", true) then return false end
    if not RT.TargetExistsAttackable() then return false end
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

function RT.ExorcismStep()
    if not RT.On("CJ_QXS", true) then return false end
    if not RT.TargetExistsAttackable() then return false end
    if type(WR_PaladinForever_IsUndeadOrDemon) == "function" then
        local ok, hit = pcall(WR_PaladinForever_IsUndeadOrDemon, "target")
        if not ok or hit ~= true then return false end
    end
    if type(WR_SpellUsable) == "function" then
        local ok, usable = pcall(WR_SpellUsable, "驱邪术", true)
        if not ok or usable ~= true then return false end
    end
    if type(WR_PaladinForever_ShowSkillCD) == "function" then
        return WR_PaladinForever_ShowSkillCD("驱邪术", 20, 10)
    end
    return false
end

function RT.ConsecrationStep()
    local need = RT.Val("CJ_FX_COUNT", 4)
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
function RT.InsertOnce(var, spell, slot, cd)
    if not RT.On(var, false) then return false end
    if type(WR_SpellUsable) == "function" then
        local ok, usable = pcall(WR_SpellUsable, spell, true)
        if not ok or usable ~= true then return false end
    end
    local shown
    if cd and type(WR_PaladinForever_ShowSkillCD) == "function" then
        shown = WR_PaladinForever_ShowSkillCD(spell, slot, cd)
    else
        shown = RT.Show(spell, slot)
    end
    if shown then
        PigSet[var] = false
        RT.SyncCheckbox(var)
        return true
    end
    return false
end

function RT.InsertStep()
    -- 制裁：目标正在读条且能打
    if RT.On("CJ_CRZC", false) then
        local casting = false
        if type(WR_PaladinForever_TargetCasting) == "function" then
            local ok, v = pcall(WR_PaladinForever_TargetCasting)
            if ok and v == true then casting = true end
        end
        if casting and RT.TargetExistsAttackable() then
            if RT.InsertOnce("CJ_CRZC", "制裁之锤", 22, 60) then return true end
        end
    end
    -- 圣佑：自己血量低于 30%
    if RT.On("CJ_CRSYS", false) then
        local hp = 1
        if type(WR_GetUnitHP) == "function" then
            local ok, v = pcall(WR_GetUnitHP, "player")
            if ok and type(v) == "number" then hp = v end
        end
        if hp < 0.30 then
            if RT.InsertOnce("CJ_CRSYS", "圣佑术", 78, 300) then return true end
        end
    end
    -- 审判：身上有圣印时打一发
    if RT.On("CJ_CRSP", false) then
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
            if RT.InsertOnce("CJ_CRSP", "审判", 2, cd) then return true end
        end
    end
    -- 奉献：按拉条的怪数检查
    if RT.On("CJ_CRFL", false) then
        local need = RT.Val("CJ_FX_COUNT", 4)
        if need > 0 and type(WR_GetRangeHarmUnitCount) == "function" then
            local ok, count = pcall(WR_GetRangeHarmUnitCount, 8)
            if ok and type(count) == "number" and count >= need then
                if RT.InsertOnce("CJ_CRFL", "奉献", 5, 8) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 10. 右键「额外条件」小窗
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

RT.PopupDefs = {
    CJ_SY = {
        title = "圣印  功能",
        width = 430,
        desc = "圣印总开关：开着时按右键里的设置管圣印。\n\n"
            .. "解封之怒（要点了天赋才能作用）：勾着时命令圣印、正义圣印轮流叠回响，叠满 3 层就换另一个，审判冷却好就打；它起作用时下面「常驻圣印」「保持审判」两组都不管。下拉选「不管」= 舞印期间不补审判；选十字军/智慧/光明 = 审判快好时临时换上对应圣印、审判一次，挂完换回舞印。\n\n"
            .. "常驻圣印：平时身上保持哪个圣印（没有或快到时就补）；标题前面的勾去掉 = 平时不补圣印。\n「卡CD使用」勾着 = 审判冷却好就拿常驻圣印审判。\n\n"
            .. "保持审判：给目标补哪种审判——每行前面的勾 = 参不参加，后面的拉条 = 第几个挂，数字小的先挂（两个数字一样时按从上到下）；标题前面的勾去掉 = 都不挂。\n\n"
            .. "自己只能在目标身上挂一种审判：目标身上已经有你挂的就不管；没有就按顺序找第一个目标身上还没有的（别的圣骑士挂的也算有），审判快好的时候临时换上那个圣印、审判一次，挂完换回常驻圣印。\n\n"
            .. "默认开，审判默认都不勾。\n"
            .. "宏：/PALADIN_RET_SEAL 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "CJ_SY_ON", label = "圣印", default = true },
            { type = "check", var = "CJ_SY_JF", label = "解封之怒", default = true, indent = 18 },
            { type = "radio", var = "CJ_SY_JF_KIND", default = 1, options = RT.JF_KINDS, indent = 34 },
            { type = "check", var = "CJ_SY_MAIN_ON", label = "常驻圣印", default = true, indent = 18 },
            { type = "check", var = "CJ_SY_KCD", label = "卡CD使用", default = true, indent = 34 },
            { type = "seal", var = "CJ_SY_SEAL", default = 3, indent = 34 },
            { type = "check", var = "CJ_SY_KEEP_JUDGE", label = "保持审判", default = true },
            { type = "judge", var = "CJ_SY_J_CRUSADER", pvar = "CJ_SY_J_CRUSADER_N", label = "十字军审判", default = false, pdefault = 3 },
            { type = "judge", var = "CJ_SY_J_WISDOM", pvar = "CJ_SY_J_WISDOM_N", label = "智慧审判", default = false, pdefault = 2 },
            { type = "judge", var = "CJ_SY_J_LIGHT", pvar = "CJ_SY_J_LIGHT_N", label = "光明审判", default = false, pdefault = 1 },
        },
    },
    CJ_QJS = {
        title = "驱散  功能",
        width = 380,
        desc = "开着时自动用清洁术驱散（清洁术只能解中毒/疾病/魔法，解不了诅咒）。\n\n"
            .. "常规：全队有 debuff 就驱散。\n优先：同样全队驱散，但排在输出技能前面。\n"
            .. "目标：只驱散当前目标身上的 debuff。\n指向：只驱散鼠标指向队友的 debuff。\n"
            .. "标题勾去掉 = 完全关闭驱散。\n\n"
            .. "模式也可用上方「清洁术」下拉调整（两处同一存档）。",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "CJ_QJS_ON", label = "驱散", default = true },
            { type = "radio", var = "CJ_QJS", default = 1, options = RT.QJS_MODES, indent = 18 },
        },
    },
}

local function BuildPopup(key)
    local def = RT.PopupDefs[key]
    if not def then return nil end
    local width = def.width or 360
    local f = CreateFrame("Frame", "WR_PaladinRetPopup_" .. key, UIParent, "BackdropTemplate")
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
        elseif rowDef.type == "radio" then
            local buttons = {}
            local startX = 14 + indent
            for i = 1, #(rowDef.options or {}) do
                local opt = rowDef.options[i]
                local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
                btn:SetSize(74, 21)
                btn:SetPoint("TOPLEFT", f, "TOPLEFT", startX + (i - 1) * 78, y)
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
                local txt = MakeFont(btn, opt.label or tostring(opt.id), 11, 0.85, 0.85, 0.85)
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
            addRow(26)
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
            local val = RT.Num(PigSet[rowDef.var], rowDef.default or 0)
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
            for i = 1, #RT.SEAL_OPTIONS do
                local opt = RT.SEAL_OPTIONS[i]
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
            local val = RT.Num(PigSet[rowDef.pvar], rowDef.pdefault or 1)
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
            elseif rec.kind == "slider" then
                local v = RT.Num(PigSet[rec.row.var], rec.row.default or 0)
                rec.control:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            elseif rec.kind == "seal" then
                local cur = tonumber(PigSet[rec.row.var]) or rec.row.default or 3
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
                local v = RT.Num(PigSet[rec.row.pvar], rec.row.pdefault or 1)
                rec.slider:SetValue(v)
                rec.valText:SetText(tostring(v) .. "号")
            end
        end
    end
    return f
end

RT.PopupCache = RT.PopupCache or {}

function RT.ShowOptions(key)
    RT.InitDefaults()
    local def = RT.PopupDefs[key]
    if not def then return end
    local f = RT.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        RT.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(RT.PopupCache) do
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
-- 11. 斜杠命令
-- ============================================================
local function ToggleSwitch(var, label)
    if type(PigSet) ~= "table" then return end
    PigSet[var] = not (PigSet[var] == true)
    RT.SyncCheckbox(var)
    print("|cff00ff00[" .. label .. "]|r " .. (PigSet[var] and "开启" or "关闭"))
end

SLASH_PALADIN_RET_SEAL1 = "/PALADIN_RET_SEAL"
SLASH_PALADIN_RET_SEAL2 = "/PALADIN_RETSEAL"
if type(SlashCmdList) == "table" then
    SlashCmdList["PALADIN_RET_SEAL"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.CJ_SY_ON = true; RT.SyncCheckbox("CJ_SY_ON")
        elseif msg == "off" then PigSet.CJ_SY_ON = false; RT.SyncCheckbox("CJ_SY_ON")
        else ToggleSwitch("CJ_SY_ON", "惩戒·圣印") end
    end
end

SLASH_PALADIN_RET_BLESS1 = "/PALADIN_RET_BLESS"
if type(SlashCmdList) == "table" then
    SlashCmdList["PALADIN_RET_BLESS"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.CJ_BLESS_ON = true; RT.SyncCheckbox("CJ_BLESS_ON")
        elseif msg == "off" then PigSet.CJ_BLESS_ON = false; RT.SyncCheckbox("CJ_BLESS_ON")
        else ToggleSwitch("CJ_BLESS_ON", "惩戒·祝福") end
    end
end
