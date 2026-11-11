-- ============================================================
-- Paladin Forever · Prot 专精循环（坦克：多目标固定优先级 / 目标 ≤1 的 Ready-first 调度）
-- ------------------------------------------------------------
-- ★ 2026-11-10 用户口径：8 码内目标 ≥2 个时切换为「多目标固定优先级」
--     奉献（≥3 目标时）→ 审判 → 神圣打击 → 驱邪术（可用就打）→ 神圣之盾
--   ★★ 2026-11-10 追加口径：奉献仅在 8 码内目标 ≥3 个时使用（2 个目标不铺奉献）。
--   ★ 2026-11-11 追加口径：奉献蓝量下限 30%——蓝量百分比低于 30% 时不施放奉献。
--   常驻圣印按面板「圣印」专区按钮（FH_SEAL：十字军/正义/愤怒/回血光明/回蓝智慧/公正）选择，默认愤怒圣印，
--   多目标不改变补印逻辑，只改变第 6 步主调度的技能先后。
--   目标 ≤1 个时保持「谁 CD 好了先打谁」的 Ready-first 调度；
--   ★★ 2026-11-10 用户口径（方案 2）：目标 ≤1 的链路里「神圣打击」CD 好了永远优先于
--     「审判」——即使审判的 FreeAt 更早，也先尝试神圣打击，只有它不可用才打审判。
--     这会改变审判的仇恨/嘲讽顺序，是用户明确选择的行为。
-- ------------------------------------------------------------
-- 依据本服实际法术书（2026-11-06 实测）：
--   攻击 / 审判 / 神圣打击 / 愤怒圣印 / 正义圣印 / 光明圣印 / 十字军圣印 /
--   智慧圣印 / 公正圣印 /
--   奉献 / 驱邪术 / 制裁之锤 / 圣佑术 / 保护祝福 / 自由祝福 /
--   王者祝福 / 力量祝福 / 智慧祝福 / 圣疗术 / 圣光术 /
--   虔诚光环 / 正义之怒 / 纯净术 / 救赎
-- 参考攻略：
--   wow.gg《WoW Forever: 防护圣骑士》——正义之怒常驻、愤怒圣印常驻、
--     审判=仇恨+嘲讽、神圣打击=主要仇恨、奉献看蓝量；
--   wowf.io《魔兽世界：无限 防护圣骑士指南》——单体优先级
--     审判 > 神圣之盾 > 神圣打击 > 愤怒之锤，法力充足才放奉献，
--     亡灵/恶魔用驱邪术，（手动插入）制裁之锤打断危险施法，低血用圣佑术/圣疗术。
--   ★ 2026-11-10 用户口径（方案 2）覆盖攻略：目标 ≤1 的链路实际按
--     「神圣打击 CD 好了 > 审判」执行，其余技能仍按原优先级。
--   ★★ 2026-11-11 用户口径：目标 ≤1 的链路里「神圣之盾」后移到「奉献」之后
--     （实际顺序：驱邪术 → 奉献（单体链不可达）→ 神圣之盾）；自动循环删除
--     「制裁之锤」提示，仅保留面板「插入 制裁之锤」一次性手动开关。
-- 说明：未学会/本服不存在的技能由 WR_SpellUsable / WR_Forever_IsSpellKnown
--   自动跳过，不影响低等级阶段的循环。
-- ★ 2026-11-06：战斗中 GetSpellCooldown 是 secret，WR_GetGCD 被收敛成 0，
--   WR_SpellUsable 对带 CD 的技能恒 true → 色块会一直卡在审判。
--   本文件所有有 CD 的技能改用「本地冷却计时」提示（WR_PaladinForever_ShowSkillCD）。
--   本地冷却以「UNIT_SPELLCAST_SUCCEEDED 的成功施放时间」为唯一起点，
--   不再以「提示显示时间」起算 —— 否则提示刚好落在 GCD 被吞掉后会锁死整个 CD，
--   出现「神圣打击 CD 好了不打，要等第二个审判之后才亮」。
-- ============================================================

-- ============================================================
-- ★★ 2026-11-11：防骑「光明圣印」常驻开关（原「插入光明圣印」一次性流程改造）
-- ------------------------------------------------------------
-- 用户口径原话：
--   「插入光明圣印修改为光明圣印开关，当勾选优先维持光明圣印，
--     目标有光明圣印debuff时自动切回圣印选择里的圣印」
--   2026-11-11 追加：「还需要增加一个光明圣印buff常驻开关，勾选优先维持光明圣印，
--     目标有光明审判debuff时自动切回圣印选择里的圣印」
-- 行为：
--   · 勾选后是常驻开关（不是一次性插入，不会自动取消勾选）；
--   · 优先维持自己身上的「光明圣印」（30 秒 Buff，掉了照常补）；
--   · 目标身上没有「光明审判」debuff 时，用光明圣印打审判挂 debuff；
--   · 目标已有「光明审判」debuff 时，自动切回常驻圣印（面板「圣印」专区所选）；
--   · 本服「光明审判」持续 40 秒（ForeverDB build 1.60.1.70862，Classic 10 秒），
--     到期后自动重复上述循环。
-- 状态机（WR_PaladinForever_LightSealPhase）：
--   0 = 需要挂光明圣印：不在身上就提示光明圣印，已在身上且审判就绪就提示审判
--   1 = 已提示光明圣印，等 1 秒让切印生效后再提示审判
--   2 = 已提示审判，等成功施放事件 / 目标 debuff / 2 秒兜底 → 准备切回常驻圣印
--   3 = 已提示切回常驻圣印，等成功施放事件确认
--   4 = 目标身上有光明审判，保持常驻圣印；debuff 到期后回到 0
-- ============================================================
WR_PaladinForever_LIGHT_SEAL_NAME = "光明圣印"
WR_PaladinForever_LIGHT_SEAL_SLOT = 54
WR_PaladinForever_LIGHT_JUDGEMENT_SECONDS = 40

-- ★★ 2026-11-11：防骑「十字军审判」buff 维持开关（同「光明圣印」审判功能的状态机）
--   用户口径原话：「删除单体循环，根据光明圣印审判功能，新增十字军审判buff维持」。
WR_PaladinForever_CRUSADER_SEAL_NAME = "十字军圣印"
WR_PaladinForever_CRUSADER_SEAL_SLOT = 30
WR_PaladinForever_CRUSADER_JUDGEMENT_SECONDS = 40

-- ★★ 2026-11-11：防骑「智慧审判」buff 维持开关（同「光明圣印」/「十字军审判」状态机）
--   用户口径原话：「同样的功能，帮我添加智慧审判的buff维持按钮」。
WR_PaladinForever_WISDOM_SEAL_NAME = "智慧圣印"
WR_PaladinForever_WISDOM_SEAL_SLOT = 108
WR_PaladinForever_WISDOM_JUDGEMENT_SECONDS = 40

-- ★★ 2026-11-11 用户口径：奉献蓝量下限 30%。
--   蓝量百分比（0~1）低于该值时不提示/不施放奉献；>= 0.30 才允许。
WR_PaladinForever_PROT_CONSECRATION_MANA_MIN = 0.30

local function WR_PaladinForever_StripSealRankSuffix(nm)
    if type(nm) ~= "string" then return nil end
    local s = string.gsub(nm, "%s*（等级%s*%d+）%s*$", "")
    if s == nm then
        s = string.gsub(nm, "%s*%(等级%s*%d+%)%s*$", "")
    end
    return s
end

-- 目标身上某个「审判」debuff 的剩余时间（通用）：
--   0 = 没读到 / 没有；>0 = 剩余秒数；999 = 有但到期时间不可读
--   names 为候选名称数组，兼容不同客户端/旧版本的翻译差异。
function WR_PaladinForever_JudgementSealDebuffRemain(names)
    if type(WR_GetUnitDebuffTime) ~= "function" then return 0 end
    local best = 0
    for i = 1, #names do
        local ok, t = pcall(WR_GetUnitDebuffTime, "target", names[i])
        if ok and type(t) == "number" and t > 0 then
            if t >= 900 then return 999 end
            if t > best then best = t end
        end
    end
    return best
end

-- 目标身上「光明审判」debuff 剩余时间：
--   0 = 没读到 / 没有；>0 = 剩余秒数；999 = 有但到期时间不可读
--   ★ 名称兼容：本服/不同客户端把 Judgement of Light 可能翻译成「光明审判」或
--     「圣光审判」，旧版本还曾用「光明圣印」当目标 debuff 名；三个名字都查，
--     避免因为名称不一致导致「明明已经挂了审判，却一直不切回常驻圣印」。
function WR_PaladinForever_LightSealDebuffRemain()
    return WR_PaladinForever_JudgementSealDebuffRemain({ "光明审判", "圣光审判", "光明圣印" })
end

-- 目标身上「十字军审判」debuff 剩余时间：
--   本服名称「十字军审判」；「十字军圣印」作为旧名/异常翻译兜底。
function WR_PaladinForever_CrusaderSealDebuffRemain()
    return WR_PaladinForever_JudgementSealDebuffRemain({ "十字军审判", "十字军圣印" })
end

-- 目标身上「智慧审判」debuff 剩余时间：
--   本服名称「智慧审判」；「智慧圣印」作为旧名/异常翻译兜底。
function WR_PaladinForever_WisdomSealDebuffRemain()
    return WR_PaladinForever_JudgementSealDebuffRemain({ "智慧审判", "智慧圣印" })
end

-- 玩家身上是否某个圣印（优先读真实光环；光环不可读时用最近成功施放记账兜底）
function WR_PaladinForever_JudgementSealOnPlayer(sealName, castAt)
    local now = GetTime()
    local state, nm = WR_PaladinForever_SealBuffState()
    local castOK = type(castAt) == "number"
       and (now - castAt) < (WR_PaladinForever_SEAL_BUFF_SECONDS or 30)
       and WR_PaladinForever_LastSealAppliedName == sealName
    if state == "up" and type(nm) == "string" then
        local base = WR_PaladinForever_StripSealRankSuffix(nm)
        if base == sealName then return true end
        -- ★★ 2026-11-11：刚刚成功切到目标圣印的 2 秒内，光环缓存可能还停留在
        --   上一条圣印（UNIT_AURA 失效 → 重扫有延迟）。旧逻辑此时直接判「不是
        --   目标圣印」→ 状态机误以为切印没生效 → 回到 phase0 再点同一条圣印
        --   色块 → AHK 反复施放。切印后 2 秒内以施放成功记录为准。
        if castOK and (now - castAt) <= 2.0 then return true end
        -- 光环可读且明确是别的圣印 → 不是目标圣印
        return false
    end
    if castOK then
        return true
    end
    return false
end

-- 玩家身上是否是光明圣印
function WR_PaladinForever_LightSealOnPlayer()
    return WR_PaladinForever_JudgementSealOnPlayer(
        WR_PaladinForever_LIGHT_SEAL_NAME, WR_PaladinForever_LightSealCastAt)
end

-- 玩家身上是否是十字军圣印
function WR_PaladinForever_CrusaderSealOnPlayer()
    return WR_PaladinForever_JudgementSealOnPlayer(
        WR_PaladinForever_CRUSADER_SEAL_NAME, WR_PaladinForever_CrusaderSealCastAt)
end

-- 玩家身上是否是智慧圣印
function WR_PaladinForever_WisdomSealOnPlayer()
    return WR_PaladinForever_JudgementSealOnPlayer(
        WR_PaladinForever_WISDOM_SEAL_NAME, WR_PaladinForever_WisdomSealCastAt)
end

-- 目标标识：用于「换目标后重新挂审判 debuff」。GUID 读不到时退化为名字。
function WR_PaladinForever_JudgementSealTargetKey()
    local key
    if type(WR_SafeUnitGUID) == "function" then
        key = WR_SafeUnitGUID("target")
    elseif type(UnitGUID) == "function" then
        local ok, v = pcall(UnitGUID, "target")
        if ok then
            if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(v) then v = nil end
            key = v
        end
    end
    if key == nil then
        if type(WR_SafeUnitName) == "function" then
            key = WR_SafeUnitName("target")
        elseif type(UnitName) == "function" then
            local ok, v = pcall(UnitName, "target")
            if ok then
                if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(v) then v = nil end
                key = v
            end
        end
    end
    return key
end

-- 兼容旧名：光明圣印状态机沿用
WR_PaladinForever_LightSealTargetKey = WR_PaladinForever_JudgementSealTargetKey

function WR_PaladinForever_ResetLightSealState()
    WR_PaladinForever_LightSealPhase = nil
    WR_PaladinForever_LightSealAt = nil
    WR_PaladinForever_LightSealJudgeAt = nil
    WR_PaladinForever_LightSealJudgeBase = nil
    WR_PaladinForever_LightSealSwitchAt = nil
    WR_PaladinForever_LightSealSwitchBase = nil
    WR_PaladinForever_LightSealDeadline = nil
    WR_PaladinForever_LightSealDebuffUntil = nil
    WR_PaladinForever_LightSealTarget = nil
    WR_PaladinForever_LightSealMaintainPromptAt = nil
end

function WR_PaladinForever_ResetCrusaderSealState()
    WR_PaladinForever_CrusaderSealPhase = nil
    WR_PaladinForever_CrusaderSealAt = nil
    WR_PaladinForever_CrusaderSealJudgeAt = nil
    WR_PaladinForever_CrusaderSealJudgeBase = nil
    WR_PaladinForever_CrusaderSealSwitchAt = nil
    WR_PaladinForever_CrusaderSealSwitchBase = nil
    WR_PaladinForever_CrusaderSealDeadline = nil
    WR_PaladinForever_CrusaderSealDebuffUntil = nil
    WR_PaladinForever_CrusaderSealTarget = nil
    WR_PaladinForever_CrusaderSealMaintainPromptAt = nil
end

function WR_PaladinForever_ResetWisdomJudgementState()
    WR_PaladinForever_WisdomJudgementPhase = nil
    WR_PaladinForever_WisdomJudgementAt = nil
    WR_PaladinForever_WisdomJudgementJudgeAt = nil
    WR_PaladinForever_WisdomJudgementJudgeBase = nil
    WR_PaladinForever_WisdomJudgementSwitchAt = nil
    WR_PaladinForever_WisdomJudgementSwitchBase = nil
    WR_PaladinForever_WisdomJudgementDeadline = nil
    WR_PaladinForever_WisdomJudgementDebuffUntil = nil
    WR_PaladinForever_WisdomJudgementTarget = nil
    WR_PaladinForever_WisdomJudgementMaintainPromptAt = nil
end

-- 当前循环应该维持哪个圣印：
--   · 光明圣印开关开启且处于「需要光明」阶段（0/1/2）→ 光明圣印
--   · 十字军审判开关开启且处于「需要十字军」阶段（0/1/2）→ 十字军圣印
--   · 智慧审判开关开启且处于「需要智慧」阶段（0/1/2）→ 智慧圣印
--   · 其余情况（未开启 / 目标已有 debuff / 正在切回）→ 常驻圣印（面板「圣印」专区所选）
-- ★★ 2026-11-11：三个 buff 维持开关可与「圣印」专区所选的常驻圣印共存——
--   常驻本身已选光明/十字军/智慧时开关同样有效；这里返回的临时圣印与常驻相同，
--   状态机收尾阶段不会再提示切回同一种圣印。
function WR_PaladinForever_ProtSealGoal(mainSeal, mainSealSlot)
    if PigSet and PigSet.FH_CRGMSY then
        local phase = WR_PaladinForever_LightSealPhase or 0
        if phase == 0 or phase == 1 or phase == 2 then
            return WR_PaladinForever_LIGHT_SEAL_NAME, WR_PaladinForever_LIGHT_SEAL_SLOT
        end
    end
    if PigSet and PigSet.FH_SZJSP then
        local phase = WR_PaladinForever_CrusaderSealPhase or 0
        if phase == 0 or phase == 1 or phase == 2 then
            return WR_PaladinForever_CRUSADER_SEAL_NAME, WR_PaladinForever_CRUSADER_SEAL_SLOT
        end
    end
    if PigSet and PigSet.FH_ZHSP then
        local phase = WR_PaladinForever_WisdomJudgementPhase or 0
        if phase == 0 or phase == 1 or phase == 2 then
            return WR_PaladinForever_WISDOM_SEAL_NAME, WR_PaladinForever_WISDOM_SEAL_SLOT
        end
    end
    return mainSeal, mainSealSlot
end

-- 光明圣印开关状态机：返回 true 表示本 tick 已点亮色块（调用方直接 return true）
function WR_PaladinForever_LightSealToggleStep(mainSeal, mainSealSlot)
    if not (PigSet and PigSet.FH_CRGMSY) then
        WR_PaladinForever_ResetLightSealState()
        return false
    end
    -- ★★ 2026-11-11：常驻圣印本身就是光明圣印时，开关同样有效，不再自动取消——
    --   用户口径「圣印常驻buff按钮，可以与圣印区所选的圣印共存同时」。
    --   状态机照常维持光明圣印并挂光明审判，只是收尾阶段无需提示切回（常驻就是光明本身）。
    local lightKnown = WR_PaladinForever_SpellKnown("光明圣印")
    local judgeKnown = WR_PaladinForever_SpellKnown("审判")
    if (not lightKnown) or (not judgeKnown) then
        PigSet.FH_CRGMSY = false
        WR_PaladinForever_ResetLightSealState()
        if type(WR_SyncConfigCheckbox) == "function" then
            WR_SyncConfigCheckbox("FH_CRGMSY")
        end
        return false
    end
    -- 脱战不干预：保留开关，但清空阶段，进战后从「需要光明」重新开始
    if not UnitAffectingCombat("player") then
        WR_PaladinForever_ResetLightSealState()
        return false
    end

    local now = GetTime()
    local phase = WR_PaladinForever_LightSealPhase or 0
    local lightName = WR_PaladinForever_LIGHT_SEAL_NAME
    local lightSlot = WR_PaladinForever_LIGHT_SEAL_SLOT

    -- 0 → 首次判定：目标可能已经有光明审判（例如开关刚打开 / 重载插件）
    if phase == 0 then
        local remain = WR_PaladinForever_LightSealDebuffRemain()
        if type(remain) == "number" and remain > 0 then
            WR_PaladinForever_LightSealPhase = 4
            WR_PaladinForever_LightSealDebuffUntil = now
                + ((remain >= 900) and WR_PaladinForever_LIGHT_JUDGEMENT_SECONDS
                   or math.min(remain + 0.5, WR_PaladinForever_LIGHT_JUDGEMENT_SECONDS + 1))
            WR_PaladinForever_LightSealTarget = WR_PaladinForever_LightSealTargetKey()
            phase = 4
        end
    end

    if phase == 0 then
        if not WR_PaladinForever_LightSealOnPlayer() then
            -- 需要切光明圣印：显式切印放行一次
            if WR_PaladinForever_CanApplySeal()
               and WR_PaladinForever_CanPrompt(lightName, 1.5) then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(lightName, lightSlot) then
                    WR_PaladinForever_MarkPrompt(lightName, lightSlot)
                    WR_PaladinForever_HideSkillLater(lightName, lightSlot, 1.5)
                    WR_PaladinForever_LightSealPhase = 1
                    WR_PaladinForever_LightSealAt = now
                    return true
                end
            end
        else
            -- 光明圣印已在身上 → 直接进入「等待审判」
            WR_PaladinForever_LightSealPhase = 1
            WR_PaladinForever_LightSealAt = WR_PaladinForever_LightSealAt or (now - 2)
            phase = 1
        end
    end

    if phase == 1 then
        local lightAt = WR_PaladinForever_LightSealAt or now
        if not WR_PaladinForever_LightSealOnPlayer() then
            -- 切印还没生效：等 2 秒仍没有 → 回 phase 0 重新提示
            if (now - lightAt) >= 2.0 then
                WR_PaladinForever_LightSealPhase = 0
                WR_PaladinForever_LightSealAt = nil
            end
        elseif (now - lightAt) >= 1.0 then
            -- ② 给切印留一个 GCD，再提示审判
            local judgeCD = WR_PaladinForever_GetJudgeCooldown()
            if WR_PaladinForever_Ready("审判", judgeCD)
               and WR_PaladinForever_CanHitTarget("审判", "target") then
                if WR_ColorFrame_ShowSkill("审判", 2) then
                    WR_PaladinForever_MarkPrompt("审判", 2)
                    WR_PaladinForever_HideSkillLater("审判", 2, 1.5)
                    WR_PaladinForever_LightSealPhase = 2
                    WR_PaladinForever_LightSealJudgeAt = now
                    WR_PaladinForever_LightSealJudgeBase = WR_PaladinForever_SkillCastAt["审判"] or 0
                    WR_PaladinForever_LightSealDeadline = now + 10
                    return true
                end
            end
        end
    end

    if phase == 2 then
        local judgeAt = WR_PaladinForever_LightSealJudgeAt or now
        local judgeBase = WR_PaladinForever_LightSealJudgeBase or 0
        local castAt = WR_PaladinForever_SkillCastAt["审判"] or 0
        local castConfirmed = type(castAt) == "number" and castAt > judgeBase + 0.001
        local debuffRemain = WR_PaladinForever_LightSealDebuffRemain()
        local debuffConfirmed = type(debuffRemain) == "number" and debuffRemain > 0
        if castConfirmed or debuffConfirmed or (now - judgeAt) >= 2.0 then
            local untilAt
            if castConfirmed and castAt >= judgeAt - 0.2 then
                -- 真实审判施放事件：光明审判从施放时刻起 40 秒
                untilAt = castAt + WR_PaladinForever_LIGHT_JUDGEMENT_SECONDS
            elseif debuffConfirmed and debuffRemain > 0 and debuffRemain < 900 then
                untilAt = now + math.min(debuffRemain + 0.5,
                    WR_PaladinForever_LIGHT_JUDGEMENT_SECONDS + 1)
            else
                -- 事件/光环都读不到：按审判提示时刻兜底 40 秒，绝不卡在光明圣印
                untilAt = judgeAt + WR_PaladinForever_LIGHT_JUDGEMENT_SECONDS
            end
            WR_PaladinForever_LightSealDebuffUntil = untilAt
            WR_PaladinForever_LightSealTarget = WR_PaladinForever_LightSealTargetKey()
            if mainSeal == WR_PaladinForever_LIGHT_SEAL_NAME then
                -- 常驻就是光明圣印：无需切回，直接进入维持期
                WR_PaladinForever_LightSealPhase = 4
                WR_PaladinForever_LightSealSwitchAt = nil
                WR_PaladinForever_LightSealSwitchBase = nil
                WR_PaladinForever_LightSealDeadline = nil
                return false
            end
            WR_PaladinForever_LightSealPhase = 3
            WR_PaladinForever_LightSealSwitchAt = 0   -- 下一 tick 立刻提示切回
            WR_PaladinForever_LightSealSwitchBase = WR_PaladinForever_LastSealAppliedAt() or 0
            WR_PaladinForever_LightSealDeadline = now + 15
            phase = 3
        elseif (now - judgeAt) > 10 then
            -- 审判一直没打出去：回 phase 0 重新来（开关保持勾选）
            WR_PaladinForever_LightSealPhase = 0
            WR_PaladinForever_LightSealAt = nil
            WR_PaladinForever_LightSealJudgeAt = nil
            WR_PaladinForever_LightSealJudgeBase = nil
            WR_PaladinForever_LightSealDeadline = nil
            phase = 0
        end
    end

    if phase == 3 then
        if mainSeal == WR_PaladinForever_LIGHT_SEAL_NAME then
            -- 切回目标与当前常驻相同：直接进入维持期，不重复提示上印
            WR_PaladinForever_LightSealPhase = 4
            WR_PaladinForever_LightSealSwitchAt = nil
            WR_PaladinForever_LightSealSwitchBase = nil
            WR_PaladinForever_LightSealDeadline = nil
            return false
        end
        local base = WR_PaladinForever_LightSealSwitchBase or 0
        local last = WR_PaladinForever_LastSealAppliedAt() or 0
        if last > base + 0.001 then
            -- 已确认切回常驻圣印 → 进入维持阶段
            WR_PaladinForever_LightSealPhase = 4
            WR_PaladinForever_LightSealSwitchAt = nil
            WR_PaladinForever_LightSealSwitchBase = nil
            WR_PaladinForever_LightSealDeadline = nil
            return false
        end
        local deadline = WR_PaladinForever_LightSealDeadline
        if type(deadline) == "number" and now > deadline then
            -- 切回确认超时：进入维持阶段，phase 4 仍会继续尝试切回
            WR_PaladinForever_LightSealPhase = 4
            WR_PaladinForever_LightSealSwitchAt = nil
            WR_PaladinForever_LightSealSwitchBase = nil
            WR_PaladinForever_LightSealDeadline = nil
            return false
        end
        local switchAt = WR_PaladinForever_LightSealSwitchAt or 0
        -- ★ 切回常驻圣印是自身 Buff，不要求目标在近战范围（目标跑远也要换回仇恨圣印）
        if (now - switchAt) >= 2.0 then
            -- 显式切回常驻圣印（面板「圣印」专区所选）
            WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
            if WR_PaladinForever_ShowSealBlock(mainSeal, mainSealSlot) then
                WR_PaladinForever_MarkPrompt(mainSeal, mainSealSlot)
                WR_PaladinForever_HideSkillLater(mainSeal, mainSealSlot, 1.5)
                WR_PaladinForever_LightSealSwitchAt = now
                return true
            end
        end
    end

    if phase == 4 then
        if not UnitExists("target") or UnitIsDead("target") then
            WR_PaladinForever_ResetLightSealState()
            return false
        end
        local targetKey = WR_PaladinForever_LightSealTargetKey()
        local storedKey = WR_PaladinForever_LightSealTarget
        if storedKey and targetKey and storedKey ~= targetKey then
            -- 换目标：重新给新目标挂光明审判
            WR_PaladinForever_ResetLightSealState()
            return false
        end
        local untilAt = WR_PaladinForever_LightSealDebuffUntil
        if type(untilAt) ~= "number" then
            WR_PaladinForever_LightSealDebuffUntil = now + WR_PaladinForever_LIGHT_JUDGEMENT_SECONDS
        elseif now >= untilAt then
            -- 光明审判 40 秒到期：回到「需要光明」，重新切光明圣印 + 审判
            WR_PaladinForever_ResetLightSealState()
            return false
        end
        -- 目标有 debuff 时应保持常驻圣印（圣印专区所选）；若当前仍是光明（切回失败/手动切回），继续提示切回
        -- ★★ 2026-11-11：常驻就是光明圣印时无需切回（两者共存），跳过着色提示
        if mainSeal ~= WR_PaladinForever_LIGHT_SEAL_NAME
           and WR_PaladinForever_LightSealOnPlayer() then
            local promptAt = WR_PaladinForever_LightSealMaintainPromptAt or 0
            if (now - promptAt) >= 3.0 then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(mainSeal, mainSealSlot) then
                    WR_PaladinForever_MarkPrompt(mainSeal, mainSealSlot)
                    WR_PaladinForever_HideSkillLater(mainSeal, mainSealSlot, 1.5)
                    WR_PaladinForever_LightSealMaintainPromptAt = now
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================================
-- ★★ 2026-11-11：防骑「十字军审判」buff 维持开关
-- ------------------------------------------------------------
-- 用户口径原话：「删除单体循环，根据光明圣印审判功能，新增十字军审判buff维持」。
-- 行为（与「光明圣印」常驻开关同款）：
--   · 勾选后是常驻开关（不是一次性插入，不会自动取消勾选）；
--   · 优先维持自己身上的「十字军圣印」（30 秒 Buff，掉了照常补）；
--   · 目标身上没有「十字军审判」debuff 时，用十字军圣印打审判挂 debuff；
--   · 目标已有「十字军审判」debuff 时，自动切回常驻圣印（面板「圣印」专区所选）；
--   · 本服「十字军审判」持续 40 秒，到期后自动重复上述循环。
-- 状态机（WR_PaladinForever_CrusaderSealPhase）：
--   0 = 需要挂十字军圣印：不在身上就提示十字军圣印，已在身上且审判就绪就提示审判
--   1 = 已提示十字军圣印，等 1 秒让切印生效后再提示审判
--   2 = 已提示审判，等成功施放事件 / 目标 debuff / 2 秒兜底 → 准备切回常驻圣印
--   3 = 已提示切回常驻圣印，等成功施放事件确认
--   4 = 目标身上有十字军审判，保持常驻圣印；debuff 到期后回到 0
-- ============================================================
function WR_PaladinForever_CrusaderSealToggleStep(mainSeal, mainSealSlot)
    if not (PigSet and PigSet.FH_SZJSP) then
        WR_PaladinForever_ResetCrusaderSealState()
        return false
    end
    -- ★★ 2026-11-11：常驻圣印本身就是十字军圣印时，开关同样有效，不再自动取消——
    --   用户口径「圣印常驻buff按钮，可以与圣印区所选的圣印共存同时」。
    --   状态机照常维持十字军圣印并挂十字军审判，只是收尾阶段无需提示切回（常驻就是十字军本身）。
    local crusaderKnown = WR_PaladinForever_SpellKnown("十字军圣印")
    local judgeKnown = WR_PaladinForever_SpellKnown("审判")
    if (not crusaderKnown) or (not judgeKnown) then
        PigSet.FH_SZJSP = false
        WR_PaladinForever_ResetCrusaderSealState()
        if type(WR_SyncConfigCheckbox) == "function" then
            WR_SyncConfigCheckbox("FH_SZJSP")
        end
        return false
    end
    -- 脱战不干预：保留开关，但清空阶段，进战后从「需要十字军」重新开始
    if not UnitAffectingCombat("player") then
        WR_PaladinForever_ResetCrusaderSealState()
        return false
    end

    local now = GetTime()
    local phase = WR_PaladinForever_CrusaderSealPhase or 0
    local crusaderName = WR_PaladinForever_CRUSADER_SEAL_NAME
    local crusaderSlot = WR_PaladinForever_CRUSADER_SEAL_SLOT

    -- 0 → 首次判定：目标可能已经有十字军审判（例如开关刚打开 / 重载插件）
    if phase == 0 then
        local remain = WR_PaladinForever_CrusaderSealDebuffRemain()
        if type(remain) == "number" and remain > 0 then
            WR_PaladinForever_CrusaderSealPhase = 4
            WR_PaladinForever_CrusaderSealDebuffUntil = now
                + ((remain >= 900) and WR_PaladinForever_CRUSADER_JUDGEMENT_SECONDS
                   or math.min(remain + 0.5, WR_PaladinForever_CRUSADER_JUDGEMENT_SECONDS + 1))
            WR_PaladinForever_CrusaderSealTarget = WR_PaladinForever_JudgementSealTargetKey()
            phase = 4
        end
    end

    if phase == 0 then
        if not WR_PaladinForever_CrusaderSealOnPlayer() then
            -- 需要切十字军圣印：显式切印放行一次
            if WR_PaladinForever_CanApplySeal()
               and WR_PaladinForever_CanPrompt(crusaderName, 1.5) then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(crusaderName, crusaderSlot) then
                    WR_PaladinForever_MarkPrompt(crusaderName, crusaderSlot)
                    WR_PaladinForever_HideSkillLater(crusaderName, crusaderSlot, 1.5)
                    WR_PaladinForever_CrusaderSealPhase = 1
                    WR_PaladinForever_CrusaderSealAt = now
                    return true
                end
            end
        else
            -- 十字军圣印已在身上 → 直接进入「等待审判」
            WR_PaladinForever_CrusaderSealPhase = 1
            WR_PaladinForever_CrusaderSealAt = WR_PaladinForever_CrusaderSealAt or (now - 2)
            phase = 1
        end
    end

    if phase == 1 then
        local crusaderAt = WR_PaladinForever_CrusaderSealAt or now
        if not WR_PaladinForever_CrusaderSealOnPlayer() then
            -- 切印还没生效：等 2 秒仍没有 → 回 phase 0 重新提示
            if (now - crusaderAt) >= 2.0 then
                WR_PaladinForever_CrusaderSealPhase = 0
                WR_PaladinForever_CrusaderSealAt = nil
            end
        elseif (now - crusaderAt) >= 1.0 then
            -- ② 给切印留一个 GCD，再提示审判
            local judgeCD = WR_PaladinForever_GetJudgeCooldown()
            if WR_PaladinForever_Ready("审判", judgeCD)
               and WR_PaladinForever_CanHitTarget("审判", "target") then
                if WR_ColorFrame_ShowSkill("审判", 2) then
                    WR_PaladinForever_MarkPrompt("审判", 2)
                    WR_PaladinForever_HideSkillLater("审判", 2, 1.5)
                    WR_PaladinForever_CrusaderSealPhase = 2
                    WR_PaladinForever_CrusaderSealJudgeAt = now
                    WR_PaladinForever_CrusaderSealJudgeBase = WR_PaladinForever_SkillCastAt["审判"] or 0
                    WR_PaladinForever_CrusaderSealDeadline = now + 10
                    return true
                end
            end
        end
    end

    if phase == 2 then
        local judgeAt = WR_PaladinForever_CrusaderSealJudgeAt or now
        local judgeBase = WR_PaladinForever_CrusaderSealJudgeBase or 0
        local castAt = WR_PaladinForever_SkillCastAt["审判"] or 0
        local castConfirmed = type(castAt) == "number" and castAt > judgeBase + 0.001
        local debuffRemain = WR_PaladinForever_CrusaderSealDebuffRemain()
        local debuffConfirmed = type(debuffRemain) == "number" and debuffRemain > 0
        if castConfirmed or debuffConfirmed or (now - judgeAt) >= 2.0 then
            local untilAt
            if castConfirmed and castAt >= judgeAt - 0.2 then
                -- 真实审判施放事件：十字军审判从施放时刻起 40 秒
                untilAt = castAt + WR_PaladinForever_CRUSADER_JUDGEMENT_SECONDS
            elseif debuffConfirmed and debuffRemain > 0 and debuffRemain < 900 then
                untilAt = now + math.min(debuffRemain + 0.5,
                    WR_PaladinForever_CRUSADER_JUDGEMENT_SECONDS + 1)
            else
                -- 事件/光环都读不到：按审判提示时刻兜底 40 秒，绝不卡在十字军圣印
                untilAt = judgeAt + WR_PaladinForever_CRUSADER_JUDGEMENT_SECONDS
            end
            WR_PaladinForever_CrusaderSealDebuffUntil = untilAt
            WR_PaladinForever_CrusaderSealTarget = WR_PaladinForever_JudgementSealTargetKey()
            if mainSeal == WR_PaladinForever_CRUSADER_SEAL_NAME then
                -- 常驻就是十字军圣印：无需切回，直接进入维持期
                WR_PaladinForever_CrusaderSealPhase = 4
                WR_PaladinForever_CrusaderSealSwitchAt = nil
                WR_PaladinForever_CrusaderSealSwitchBase = nil
                WR_PaladinForever_CrusaderSealDeadline = nil
                return false
            end
            WR_PaladinForever_CrusaderSealPhase = 3
            WR_PaladinForever_CrusaderSealSwitchAt = 0   -- 下一 tick 立刻提示切回
            WR_PaladinForever_CrusaderSealSwitchBase = WR_PaladinForever_LastSealAppliedAt() or 0
            WR_PaladinForever_CrusaderSealDeadline = now + 15
            phase = 3
        elseif (now - judgeAt) > 10 then
            -- 审判一直没打出去：回 phase 0 重新来（开关保持勾选）
            WR_PaladinForever_CrusaderSealPhase = 0
            WR_PaladinForever_CrusaderSealAt = nil
            WR_PaladinForever_CrusaderSealJudgeAt = nil
            WR_PaladinForever_CrusaderSealJudgeBase = nil
            WR_PaladinForever_CrusaderSealDeadline = nil
            phase = 0
        end
    end

    if phase == 3 then
        if mainSeal == WR_PaladinForever_CRUSADER_SEAL_NAME then
            -- 切回目标与当前常驻相同：直接进入维持期，不重复提示上印
            WR_PaladinForever_CrusaderSealPhase = 4
            WR_PaladinForever_CrusaderSealSwitchAt = nil
            WR_PaladinForever_CrusaderSealSwitchBase = nil
            WR_PaladinForever_CrusaderSealDeadline = nil
            return false
        end
        local base = WR_PaladinForever_CrusaderSealSwitchBase or 0
        local last = WR_PaladinForever_LastSealAppliedAt() or 0
        if last > base + 0.001 then
            -- 已确认切回常驻圣印 → 进入维持阶段
            WR_PaladinForever_CrusaderSealPhase = 4
            WR_PaladinForever_CrusaderSealSwitchAt = nil
            WR_PaladinForever_CrusaderSealSwitchBase = nil
            WR_PaladinForever_CrusaderSealDeadline = nil
            return false
        end
        local deadline = WR_PaladinForever_CrusaderSealDeadline
        if type(deadline) == "number" and now > deadline then
            -- 切回确认超时：进入维持阶段，phase 4 仍会继续尝试切回
            WR_PaladinForever_CrusaderSealPhase = 4
            WR_PaladinForever_CrusaderSealSwitchAt = nil
            WR_PaladinForever_CrusaderSealSwitchBase = nil
            WR_PaladinForever_CrusaderSealDeadline = nil
            return false
        end
        local switchAt = WR_PaladinForever_CrusaderSealSwitchAt or 0
        -- ★ 切回常驻圣印是自身 Buff，不要求目标在近战范围（目标跑远也要换回仇恨圣印）
        if (now - switchAt) >= 2.0 then
            -- 显式切回常驻圣印（面板「圣印」专区所选）
            WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
            if WR_PaladinForever_ShowSealBlock(mainSeal, mainSealSlot) then
                WR_PaladinForever_MarkPrompt(mainSeal, mainSealSlot)
                WR_PaladinForever_HideSkillLater(mainSeal, mainSealSlot, 1.5)
                WR_PaladinForever_CrusaderSealSwitchAt = now
                return true
            end
        end
    end

    if phase == 4 then
        if not UnitExists("target") or UnitIsDead("target") then
            WR_PaladinForever_ResetCrusaderSealState()
            return false
        end
        local targetKey = WR_PaladinForever_JudgementSealTargetKey()
        local storedKey = WR_PaladinForever_CrusaderSealTarget
        if storedKey and targetKey and storedKey ~= targetKey then
            -- 换目标：重新给新目标挂十字军审判
            WR_PaladinForever_ResetCrusaderSealState()
            return false
        end
        local untilAt = WR_PaladinForever_CrusaderSealDebuffUntil
        if type(untilAt) ~= "number" then
            WR_PaladinForever_CrusaderSealDebuffUntil = now + WR_PaladinForever_CRUSADER_JUDGEMENT_SECONDS
        elseif now >= untilAt then
            -- 十字军审判 40 秒到期：回到「需要十字军」，重新切十字军圣印 + 审判
            WR_PaladinForever_ResetCrusaderSealState()
            return false
        end
        -- 目标有 debuff 时应保持常驻圣印（圣印专区所选）；若当前仍是十字军（切回失败/手动切回），继续提示切回
        -- ★★ 2026-11-11：常驻就是十字军圣印时无需切回（两者共存），跳过着色提示
        if mainSeal ~= WR_PaladinForever_CRUSADER_SEAL_NAME
           and WR_PaladinForever_CrusaderSealOnPlayer() then
            local promptAt = WR_PaladinForever_CrusaderSealMaintainPromptAt or 0
            if (now - promptAt) >= 3.0 then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(mainSeal, mainSealSlot) then
                    WR_PaladinForever_MarkPrompt(mainSeal, mainSealSlot)
                    WR_PaladinForever_HideSkillLater(mainSeal, mainSealSlot, 1.5)
                    WR_PaladinForever_CrusaderSealMaintainPromptAt = now
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================================
-- ★★ 2026-11-11：防骑「智慧审判」buff 维持开关
-- ------------------------------------------------------------
-- 用户口径原话：「同样的功能，帮我添加智慧审判的buff维持按钮」。
-- 行为（与「光明圣印」/「十字军审判」开关同款）：
--   · 勾选后是常驻开关（不是一次性插入，不会自动取消勾选）；
--   · 优先维持自己身上的「智慧圣印」（30 秒 Buff，掉了照常补）；
--   · 目标身上没有「智慧审判」debuff 时，用智慧圣印打审判挂 debuff（攻击/法术有几率回蓝）；
--   · 目标已有「智慧审判」debuff 时，自动切回常驻圣印（面板「圣印」专区所选）；
--   · 本服「智慧审判」持续 40 秒（ForeverDB build 1.60.1.70862，Classic 为 10 秒），
--     到期后自动重复上述循环。
-- 状态机（WR_PaladinForever_WisdomJudgementPhase）：
--   0 = 需要挂智慧圣印：不在身上就提示智慧圣印，已在身上且审判就绪就提示审判
--   1 = 已提示智慧圣印，等 1 秒让切印生效后再提示审判
--   2 = 已提示审判，等成功施放事件 / 目标 debuff / 2 秒兜底 → 准备切回常驻圣印
--   3 = 已提示切回常驻圣印，等成功施放事件确认
--   4 = 目标身上有智慧审判，保持常驻圣印；debuff 到期后回到 0
-- 注意：变量名用 WisdomJudgement*，与「插入智慧圣印」一次性流程的 WisdomSealPhase/At 区分开。
-- ============================================================
function WR_PaladinForever_WisdomJudgementToggleStep(mainSeal, mainSealSlot)
    if not (PigSet and PigSet.FH_ZHSP) then
        WR_PaladinForever_ResetWisdomJudgementState()
        return false
    end
    -- ★★ 2026-11-11：常驻圣印本身就是智慧圣印时，开关同样有效，不再自动取消——
    --   用户口径「圣印常驻buff按钮，可以与圣印区所选的圣印共存同时」。
    --   状态机照常维持智慧圣印并挂智慧审判，只是收尾阶段无需提示切回（常驻就是智慧本身）。
    local wisdomKnown = WR_PaladinForever_SpellKnown("智慧圣印")
    local judgeKnown = WR_PaladinForever_SpellKnown("审判")
    if (not wisdomKnown) or (not judgeKnown) then
        PigSet.FH_ZHSP = false
        WR_PaladinForever_ResetWisdomJudgementState()
        if type(WR_SyncConfigCheckbox) == "function" then
            WR_SyncConfigCheckbox("FH_ZHSP")
        end
        return false
    end
    -- 脱战不干预：保留开关，但清空阶段，进战后从「需要智慧」重新开始
    if not UnitAffectingCombat("player") then
        WR_PaladinForever_ResetWisdomJudgementState()
        return false
    end

    local now = GetTime()
    local phase = WR_PaladinForever_WisdomJudgementPhase or 0
    local wisdomName = WR_PaladinForever_WISDOM_SEAL_NAME
    local wisdomSlot = WR_PaladinForever_WISDOM_SEAL_SLOT

    -- 0 → 首次判定：目标可能已经有智慧审判（例如开关刚打开 / 重载插件）
    if phase == 0 then
        local remain = WR_PaladinForever_WisdomSealDebuffRemain()
        if type(remain) == "number" and remain > 0 then
            WR_PaladinForever_WisdomJudgementPhase = 4
            WR_PaladinForever_WisdomJudgementDebuffUntil = now
                + ((remain >= 900) and WR_PaladinForever_WISDOM_JUDGEMENT_SECONDS
                   or math.min(remain + 0.5, WR_PaladinForever_WISDOM_JUDGEMENT_SECONDS + 1))
            WR_PaladinForever_WisdomJudgementTarget = WR_PaladinForever_JudgementSealTargetKey()
            phase = 4
        end
    end

    if phase == 0 then
        if not WR_PaladinForever_WisdomSealOnPlayer() then
            -- 需要切智慧圣印：显式切印放行一次
            if WR_PaladinForever_CanApplySeal()
               and WR_PaladinForever_CanPrompt(wisdomName, 1.5) then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(wisdomName, wisdomSlot) then
                    WR_PaladinForever_MarkPrompt(wisdomName, wisdomSlot)
                    WR_PaladinForever_HideSkillLater(wisdomName, wisdomSlot, 1.5)
                    WR_PaladinForever_WisdomJudgementPhase = 1
                    WR_PaladinForever_WisdomJudgementAt = now
                    return true
                end
            end
        else
            -- 智慧圣印已在身上 → 直接进入「等待审判」
            WR_PaladinForever_WisdomJudgementPhase = 1
            WR_PaladinForever_WisdomJudgementAt = WR_PaladinForever_WisdomJudgementAt or (now - 2)
            phase = 1
        end
    end

    if phase == 1 then
        local wisdomAt = WR_PaladinForever_WisdomJudgementAt or now
        if not WR_PaladinForever_WisdomSealOnPlayer() then
            -- 切印还没生效：等 2 秒仍没有 → 回 phase 0 重新提示
            if (now - wisdomAt) >= 2.0 then
                WR_PaladinForever_WisdomJudgementPhase = 0
                WR_PaladinForever_WisdomJudgementAt = nil
            end
        elseif (now - wisdomAt) >= 1.0 then
            -- ② 给切印留一个 GCD，再提示审判
            local judgeCD = WR_PaladinForever_GetJudgeCooldown()
            if WR_PaladinForever_Ready("审判", judgeCD)
               and WR_PaladinForever_CanHitTarget("审判", "target") then
                if WR_ColorFrame_ShowSkill("审判", 2) then
                    WR_PaladinForever_MarkPrompt("审判", 2)
                    WR_PaladinForever_HideSkillLater("审判", 2, 1.5)
                    WR_PaladinForever_WisdomJudgementPhase = 2
                    WR_PaladinForever_WisdomJudgementJudgeAt = now
                    WR_PaladinForever_WisdomJudgementJudgeBase = WR_PaladinForever_SkillCastAt["审判"] or 0
                    WR_PaladinForever_WisdomJudgementDeadline = now + 10
                    return true
                end
            end
        end
    end

    if phase == 2 then
        local judgeAt = WR_PaladinForever_WisdomJudgementJudgeAt or now
        local judgeBase = WR_PaladinForever_WisdomJudgementJudgeBase or 0
        local castAt = WR_PaladinForever_SkillCastAt["审判"] or 0
        local castConfirmed = type(castAt) == "number" and castAt > judgeBase + 0.001
        local debuffRemain = WR_PaladinForever_WisdomSealDebuffRemain()
        local debuffConfirmed = type(debuffRemain) == "number" and debuffRemain > 0
        if castConfirmed or debuffConfirmed or (now - judgeAt) >= 2.0 then
            local untilAt
            if castConfirmed and castAt >= judgeAt - 0.2 then
                -- 真实审判施放事件：智慧审判从施放时刻起 40 秒
                untilAt = castAt + WR_PaladinForever_WISDOM_JUDGEMENT_SECONDS
            elseif debuffConfirmed and debuffRemain > 0 and debuffRemain < 900 then
                untilAt = now + math.min(debuffRemain + 0.5,
                    WR_PaladinForever_WISDOM_JUDGEMENT_SECONDS + 1)
            else
                -- 事件/光环都读不到：按审判提示时刻兜底 40 秒，绝不卡在智慧圣印
                untilAt = judgeAt + WR_PaladinForever_WISDOM_JUDGEMENT_SECONDS
            end
            WR_PaladinForever_WisdomJudgementDebuffUntil = untilAt
            WR_PaladinForever_WisdomJudgementTarget = WR_PaladinForever_JudgementSealTargetKey()
            if mainSeal == WR_PaladinForever_WISDOM_SEAL_NAME then
                -- 常驻就是智慧圣印：无需切回，直接进入维持期
                WR_PaladinForever_WisdomJudgementPhase = 4
                WR_PaladinForever_WisdomJudgementSwitchAt = nil
                WR_PaladinForever_WisdomJudgementSwitchBase = nil
                WR_PaladinForever_WisdomJudgementDeadline = nil
                return false
            end
            WR_PaladinForever_WisdomJudgementPhase = 3
            WR_PaladinForever_WisdomJudgementSwitchAt = 0   -- 下一 tick 立刻提示切回
            WR_PaladinForever_WisdomJudgementSwitchBase = WR_PaladinForever_LastSealAppliedAt() or 0
            WR_PaladinForever_WisdomJudgementDeadline = now + 15
            phase = 3
        elseif (now - judgeAt) > 10 then
            -- 审判一直没打出去：回 phase 0 重新来（开关保持勾选）
            WR_PaladinForever_WisdomJudgementPhase = 0
            WR_PaladinForever_WisdomJudgementAt = nil
            WR_PaladinForever_WisdomJudgementJudgeAt = nil
            WR_PaladinForever_WisdomJudgementJudgeBase = nil
            WR_PaladinForever_WisdomJudgementDeadline = nil
            phase = 0
        end
    end

    if phase == 3 then
        if mainSeal == WR_PaladinForever_WISDOM_SEAL_NAME then
            -- 切回目标与当前常驻相同：直接进入维持期，不重复提示上印
            WR_PaladinForever_WisdomJudgementPhase = 4
            WR_PaladinForever_WisdomJudgementSwitchAt = nil
            WR_PaladinForever_WisdomJudgementSwitchBase = nil
            WR_PaladinForever_WisdomJudgementDeadline = nil
            return false
        end
        local base = WR_PaladinForever_WisdomJudgementSwitchBase or 0
        local last = WR_PaladinForever_LastSealAppliedAt() or 0
        if last > base + 0.001 then
            -- 已确认切回常驻圣印 → 进入维持阶段
            WR_PaladinForever_WisdomJudgementPhase = 4
            WR_PaladinForever_WisdomJudgementSwitchAt = nil
            WR_PaladinForever_WisdomJudgementSwitchBase = nil
            WR_PaladinForever_WisdomJudgementDeadline = nil
            return false
        end
        local deadline = WR_PaladinForever_WisdomJudgementDeadline
        if type(deadline) == "number" and now > deadline then
            -- 切回确认超时：进入维持阶段，phase 4 仍会继续尝试切回
            WR_PaladinForever_WisdomJudgementPhase = 4
            WR_PaladinForever_WisdomJudgementSwitchAt = nil
            WR_PaladinForever_WisdomJudgementSwitchBase = nil
            WR_PaladinForever_WisdomJudgementDeadline = nil
            return false
        end
        local switchAt = WR_PaladinForever_WisdomJudgementSwitchAt or 0
        -- ★ 切回常驻圣印是自身 Buff，不要求目标在近战范围（目标跑远也要换回仇恨圣印）
        if (now - switchAt) >= 2.0 then
            -- 显式切回常驻圣印（面板「圣印」专区所选）
            WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
            if WR_PaladinForever_ShowSealBlock(mainSeal, mainSealSlot) then
                WR_PaladinForever_MarkPrompt(mainSeal, mainSealSlot)
                WR_PaladinForever_HideSkillLater(mainSeal, mainSealSlot, 1.5)
                WR_PaladinForever_WisdomJudgementSwitchAt = now
                return true
            end
        end
    end

    if phase == 4 then
        if not UnitExists("target") or UnitIsDead("target") then
            WR_PaladinForever_ResetWisdomJudgementState()
            return false
        end
        local targetKey = WR_PaladinForever_JudgementSealTargetKey()
        local storedKey = WR_PaladinForever_WisdomJudgementTarget
        if storedKey and targetKey and storedKey ~= targetKey then
            -- 换目标：重新给新目标挂智慧审判
            WR_PaladinForever_ResetWisdomJudgementState()
            return false
        end
        local untilAt = WR_PaladinForever_WisdomJudgementDebuffUntil
        if type(untilAt) ~= "number" then
            WR_PaladinForever_WisdomJudgementDebuffUntil = now + WR_PaladinForever_WISDOM_JUDGEMENT_SECONDS
        elseif now >= untilAt then
            -- 智慧审判 40 秒到期：回到「需要智慧」，重新切智慧圣印 + 审判
            WR_PaladinForever_ResetWisdomJudgementState()
            return false
        end
        -- 目标有 debuff 时应保持常驻圣印（圣印专区所选）；若当前仍是智慧（切回失败/手动切回），继续提示切回
        -- ★★ 2026-11-11：常驻就是智慧圣印时无需切回（两者共存），跳过着色提示
        if mainSeal ~= WR_PaladinForever_WISDOM_SEAL_NAME
           and WR_PaladinForever_WisdomSealOnPlayer() then
            local promptAt = WR_PaladinForever_WisdomJudgementMaintainPromptAt or 0
            if (now - promptAt) >= 3.0 then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(mainSeal, mainSealSlot) then
                    WR_PaladinForever_MarkPrompt(mainSeal, mainSealSlot)
                    WR_PaladinForever_HideSkillLater(mainSeal, mainSealSlot, 1.5)
                    WR_PaladinForever_WisdomJudgementMaintainPromptAt = now
                    return true
                end
            end
        end
    end

    return false
end

function WR_PaladinForeverProt()
    WR_PaladinForever_ClearStalePrompts(1.0)
    -- ★★ 2026-11-09 第十一次修正：圣印提示保护窗口。
    --   圣印色块亮起后的 0.3 秒内，本函数会每 tick 重亮同一个圣印并直接返回，
    --   防止「神圣打击」等下一 tick 的提示把圣印色块顶掉（AHK 读不到 → 不补印）。
    if WR_PaladinForever_RefreshSealPrompt() then return true end
    -- ★ 进战斗标记（只作为「确实缺印时立刻补」的加速开关，见下方 sealState 判定）
    local inCombatNow = UnitAffectingCombat("player")
    if inCombatNow and not WR_PaladinForever_WasInCombat then
        WR_PaladinForever_ForceSealAtCombat = true
        -- ★ 记下进战时刻：起手 3 秒内审判若就绪，优先打审判（防骑起手仇恨）
        WR_PaladinForever_CombatStartAt = GetTime()
    end
    WR_PaladinForever_WasInCombat = inCombatNow

    -- ★ 常驻圣印：按面板「圣印」专区按钮（FH_SEAL）选择，默认 3=愤怒圣印；共 6 种可选。
    local mainSeal, mainSealSlot, mainSealField = WR_PaladinForever_MainSeal()
    -- ★★ 2026-11-11：光明圣印开关开启且处于「需要光明」阶段时，本 tick 的补印目标
    --   临时改成光明圣印；目标已有光明审判 / 正在切回时仍用常驻圣印（圣印专区所选）。
    local maintainSeal, maintainSealSlot = WR_PaladinForever_ProtSealGoal(mainSeal, mainSealSlot)
    -- ★★ 2026-11-09：先判真实圣印状态，再决定要不要补印。
    --   旧逻辑进战斗无条件亮一次常驻圣印并 return true：
    --   玩家身上明明有圣印，却每场战斗先浪费一个 GCD 补印，
    --   紧接着主调度又要等 GCD → 第一轮审判/神圣打击迟迟不打。
    local sealState = WR_PaladinForever_ProtSealState()

    -- ★★ 2026-11-09 用户口径：补印只在「战斗中 + 近战可攻击」时进行。
    --   ★ 进战强制补印：只要无法确认「身上真有可读圣印光环」(BaseSealUp)，进战且
    --     近战能打到目标时补一次。旧逻辑只认 sealState == "missing"，而战斗中光环是
    --     secret、ProtSealState 会靠「30 分钟本地施放记录」把已消失的圣印判成
    --     up(假 up)/unknown → 进战那一下不补、标记还被下方清掉，表现为
    --     「后续圣印消失了，进战斗中没有补圣印」。现改为以「可读真实光环」为准 + 门控，
    --     并让标记在补印成功前一直保留（见下方 sealDue 段）。
    --   ★ 2026-11-11：删除「单体」循环（FH_DT）后，进战补印不再需要让位给起手状态机。
    if WR_PaladinForever_ForceSealAtCombat
       and not WR_PaladinForever_BaseSealUp()
       and WR_PaladinForever_SealNeedsRefresh(maintainSeal)
       and WR_PaladinForever_CanApplySeal() then
        if WR_PaladinForever_ShowSealBlock(maintainSeal, maintainSealSlot) then
            WR_PaladinForever_ForceSealAtCombat = false
            WR_PaladinForever_MarkPrompt(maintainSeal, maintainSealSlot)
            WR_PaladinForever_HideSkillLater(maintainSeal, maintainSealSlot, 0.3)
            return true
        end
    end
    -- ★★ 2026-11-09 用户反馈「圣印用了还会反复上、身上有 Buff 仍有反复」：
    --   AHK 是「同色常亮就一直按」(随机延迟 50~150ms)，色块亮多久 AHK 就按几次。
    --   因此「身上已有任意圣印」时必须在【下一 tick 立刻】把圣印色块彻底熄灭——
    --   不只 HideSkillVisual（那会留下 PromptHold，色块还会被后续逻辑维持），
    --   而是 HideNow 全部圣印名（清保持标记 + 清已亮标记），把 AHK 连按窗口压到最小。
    --   判据用 AnySealUp()（=BaseSealUp）：真读到任意圣印 / 或 30 秒本地记账内 → 已在身。
    --   注意：不要用 sealState=="up"（含 30 分钟假 up），否则圣印已消失时会把刚亮的
    --   补印色块误灭，导致「所有圣印都不打」。
    -- ★★★ 2026-11-09 第十次修正：条件再加 `not SealNeedsRefresh(mainSeal)`——
    --   只要「不允许补印」，就无条件把常驻圣印色块按槽位强制熄灭（不依赖文字匹配），
    --   彻底杜绝「允许补印=false 但色块还亮着」的情况。
    if WR_PaladinForever_AnySealUp() or not WR_PaladinForever_SealNeedsRefresh(maintainSeal) then
        WR_PaladinForever_HideNow(maintainSeal, maintainSealSlot)  -- 先按槽位硬隐藏（不依赖文字）
        for i = 1, #WR_PaladinForever_SealNames do
            WR_PaladinForever_HideNow(WR_PaladinForever_SealNames[i])
        end
        WR_PaladinForever_HideSkillVisual(maintainSeal, maintainSealSlot)
        WR_PaladinForever_HideSkillVisual("圣印")
    end
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("审判")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)

    -- ★★ 2026-11-11：原「14.5 单体循环起手」整段已删除（用户口径：「删除单体循环」）。
    --   原逻辑为「勾选单体 → 十字军圣印 → 审判 → 切回常驻圣印」的一次性起手；
    --   现由「十字军审判」buff 维持开关（FH_SZJSP）常驻接管，见文件顶部
    --   WR_PaladinForever_CrusaderSealToggleStep。

    -- ============================================================
    -- ★ 0. 插入类技能（最高优先级 —— 勾选即最先执行，命中就 return）
    -- ------------------------------------------------------------
    -- 语义：面板「插入」分组里的复选框都是**一次性**的：
    --   勾选 → 循环立刻优先执行该技能 → 提示后自动取消勾选并同步界面。
    -- 因此它们必须排在所有自动逻辑（生存/光环/圣印/主调度）之前，
    -- 否则会被前面的分支抢走执行机会，出现「勾了没反应」。
    -- 顺序原则：救场类（牺牲/保护/圣疗/圣盾）> 功能类（自由/拯救）> 输出类（神圣愤怒/制裁/光明圣印）。
    -- 未学会对应技能 → 静默取消勾选，不干扰循环。
    -- ============================================================
    do
        -- 统一的「一次性插入」执行器：命中即提示、取消勾选、同步界面
        -- ★ 一次性插入不做 CD 判断：玩家主动勾选就是明确要打这个技能，
        --   若还按 CD 拦一道，会出现「勾了没反应」，与插入语义冲突。
        --   CD 由玩家自己看技能栏，这里只负责把色块亮出来。
        --
        --   ★★★ 2026-11-10：只有「需要敌方目标」的技能才判 CanHitTarget。
        --     自身/队友类技能（圣疗术给自己、圣盾术给自己、各种之手、神圣牺牲、
        --     神圣愤怒=以自身为中心的 AoE）若用 UnitCanAttack("player","target") 判，
        --     在「无目标 / 目标是自己或队友」时恒 false → 会把整组插入功能全部拦死，
        --     属功能回归。这些技能只要能施放就一定成功，不存在「亮了打不出去卡循环」。
        local WR_ProtOneShotNeedsEnemy = {
            ["制裁之锤"] = true,   -- 打敌方目标眩晕（10 码），必须有可攻击目标
        }
        local function WR_ProtOneShot(var, spell, slot)
            if not (PigSet and PigSet[var]) then return false end
            if not WR_PaladinForever_SpellKnown(spell) then
                PigSet[var] = false
                if type(WR_SyncConfigCheckbox) == "function" then
                    WR_SyncConfigCheckbox(var)
                end
                return false
            end
            -- ★★ 2026-11-10 用户口径：不符合条件就不亮色块。
            --   一次性插入若此刻打不出去（目标没了 / 超出射程），
            --   【不点亮、也不取消勾选】—— 保持勾选等下个 tick 条件满足再打。
            --   旧行为是直接亮了打不出去还自动取消勾选，玩家会以为「勾了没反应」。
            if WR_ProtOneShotNeedsEnemy[spell]
               and not WR_PaladinForever_CanHitTarget(spell, "target") then
                return false
            end
            if WR_ColorFrame_ShowSkill(spell, slot) then
                WR_PaladinForever_MarkPrompt(spell, slot)
                WR_PaladinForever_HideSkillLater(spell, slot, 1.5)
                PigSet[var] = false
                if type(WR_SyncConfigCheckbox) == "function" then
                    WR_SyncConfigCheckbox(var)
                end
                return true
            end
            return false
        end

        -- ① 插入 神圣牺牲（25）—— 团队减伤，救场优先
        if WR_ProtOneShot("FH_CRSSXS", "神圣牺牲", 25) then return true end
        -- ② 插入 拯救之手（35）—— 给队友减威胁
        if WR_ProtOneShot("FH_CRZJZS", "拯救之手", 35) then return true end
        -- ③ 插入 自由之手（19）—— 解定身/减速
        if WR_ProtOneShot("FH_CRZYZS", "自由之手", 19) then return true end
        -- ④ 插入 圣疗术（48，对自己）
        if WR_ProtOneShot("FH_CRSLS", "圣疗术", 48) then return true end
        -- ⑤ 插入 圣盾术（18，对自己）
        if WR_ProtOneShot("FH_CRSDS", "圣盾术", 18) then return true end
        -- ⑥ 插入 神圣愤怒（7）—— AoE 伤害/眩晕
        if WR_ProtOneShot("FH_CRSSFN", "神圣愤怒", 7) then return true end
        -- ⑦ 插入 制裁之锤（22）—— 单体眩晕
        if WR_ProtOneShot("FH_CRZCZC", "制裁之锤", 22) then return true end

        -- ⑧ 指向三手：对「鼠标指向」的队友施放（保护/牺牲/拯救），一次性
        --   战斗内外均可（脱战可预读），成功后自动取消勾选。
        --   ★ 这三个技能都用 [@focus] / [target=focus] 宏，会占用焦点槽；
        --     这里只做「提示 + 取消勾选」，真正的施放由 AHK 按对应键完成。
        local mouseoverOK = UnitExists("mouseover") and UnitIsPlayer("mouseover")
                            and not UnitIsDeadOrGhost("mouseover")
                            and not UnitIsUnit("mouseover", "player")
        if mouseoverOK then
            -- 指向保护（64）/ 指向牺牲（23）/ 指向拯救（35）
            if WR_ProtOneShot("FH_ZZBH", "保护之手", 64) then return true end
            if WR_ProtOneShot("FH_ZZXS", "牺牲之手", 23) then return true end
            if WR_ProtOneShot("FH_ZZJZ", "拯救之手", 35) then return true end
        end
    end
    -- ★★ 2026-11-11：开启「智慧审判」buff 维持开关时，一次性「插入智慧圣印」没有意义
    --   （持续维持已覆盖回蓝需求），自动取消勾选，避免两条流程抢同一个审判。
    if PigSet and PigSet.FH_ZHSP and PigSet.FH_CRZHSY then
        PigSet.FH_CRZHSY = false
        WR_PaladinForever_WisdomSealPhase = nil
        WR_PaladinForever_WisdomSealAt = nil
        if type(WR_SyncConfigCheckbox) == "function" then
            WR_SyncConfigCheckbox("FH_CRZHSY")
        end
    end

    -- ★★ 2026-11-11：光明圣印开关（常驻，原「插入光明圣印」一次性流程改造）
    --   完整行为/状态机见文件顶部 WR_PaladinForever_LightSealToggleStep 的注释。
    if WR_PaladinForever_LightSealToggleStep(mainSeal, mainSealSlot) then return true end
    -- ★★ 2026-11-11：十字军审判 buff 维持开关（与光明圣印开关同款状态机）
    if WR_PaladinForever_CrusaderSealToggleStep(mainSeal, mainSealSlot) then return true end
    -- ★★ 2026-11-11：智慧审判 buff 维持开关（与光明圣印/十字军审判开关同款状态机）
    if WR_PaladinForever_WisdomJudgementToggleStep(mainSeal, mainSealSlot) then return true end

    -- ★★ 2026-11-11：常驻圣印已是智慧圣印时，「插入智慧圣印」没有意义（切过去还是同一个、
    --   收尾也无处可切），自动取消勾选，避免白占 GCD / 与常驻补印抢色块。
    if mainSeal == "智慧圣印" and PigSet and PigSet.FH_CRZHSY then
        PigSet.FH_CRZHSY = false
        WR_PaladinForever_WisdomSealPhase = nil
        WR_PaladinForever_WisdomSealAt = nil
        if type(WR_SyncConfigCheckbox) == "function" then
            WR_SyncConfigCheckbox("FH_CRZHSY")
        end
    end
    -- ★ 插入 智慧圣印（2026-11-09 用户需求：加插入智慧圣印功能）
    -- ------------------------------------------------------------
    --   与光明圣印开关共用「切印 → 审判」的两阶段思路：
    --     ① phase=0：确认审判**已就绪** → 提示切「智慧圣印」（槽位 108 / 宏 ALT-SHIFT-F8），进入 1
    --     ② phase=1：等一个 GCD 让切印生效 → 提示「审判」，让这发审判带上智慧圣印效果（回蓝）
    --     ③ 审判提示发出即收尾：自动取消 FH_CRZHSY 勾选并同步界面
    --   ★ 为什么用审判而不是别的：本服圣印的收益由审判一次性释放
    --     （智慧审判 = 按伤害回蓝），所以「切成智慧圣印 → 打一发审判」就是这套插入的全部价值。
    --   ★ 阶段变量独立（WisdomSealPhase/At），不会与光明圣印开关的 state machine 串味。
    if PigSet and PigSet.FH_CRZHSY then
        local wisdomKnown = WR_PaladinForever_SpellKnown("智慧圣印")
        local judgeKnown = WR_PaladinForever_SpellKnown("审判")
        if (not wisdomKnown) or (not judgeKnown) then
            -- 缺技能：关掉开关并同步界面勾选
            PigSet.FH_CRZHSY = false
            WR_PaladinForever_WisdomSealPhase = nil
            if type(WR_SyncConfigCheckbox) == "function" then
                WR_SyncConfigCheckbox("FH_CRZHSY")
            end
        else
            local wphase = WR_PaladinForever_WisdomSealPhase or 0
            local wjudgeCD = WR_PaladinForever_GetJudgeCooldown()

            if wphase == 0 then
                -- ① 触发条件：审判**已就绪** → 切智慧圣印
                --   ★★ 2026-11-10 用户口径：审判此刻真打得出去才切印。
                if WR_PaladinForever_Ready("审判", wjudgeCD)
                   and WR_PaladinForever_CanHitTarget("审判", "target") then
                    -- ★ 插入功能 = 用户主动要求切智慧圣印 → 显式切印放行一次
                    WR_PaladinForever_SealSwitchAllowUntil = GetTime() + 0.5
                    if WR_PaladinForever_ShowSealBlock("智慧圣印", 108) then
                        WR_PaladinForever_MarkPrompt("智慧圣印", 108)
                        WR_PaladinForever_HideSkillLater("智慧圣印", 108, 2.0)
                        WR_PaladinForever_WisdomSealPhase = 1
                        WR_PaladinForever_WisdomSealAt = GetTime()
                        return true
                    end
                end
            elseif wphase == 1 then
                local elapsed = GetTime() - (WR_PaladinForever_WisdomSealAt or GetTime())
                if elapsed > 10 then
                    -- 安全阀：超时放弃，不卡循环
                    WR_PaladinForever_WisdomSealPhase = nil
                    PigSet.FH_CRZHSY = false
                    if type(WR_SyncConfigCheckbox) == "function" then
                        WR_SyncConfigCheckbox("FH_CRZHSY")
                    end
                elseif elapsed >= 1.0 then
                    -- ② 给切印留一个 GCD，再打审判
                    if WR_PaladinForever_Ready("审判", wjudgeCD)
                       and WR_PaladinForever_CanHitTarget("审判", "target") then
                        if WR_ColorFrame_ShowSkill("审判", 2) then
                            WR_PaladinForever_MarkPrompt("审判", 2)
                            WR_PaladinForever_HideSkillLater("审判", 2, 1.5)
                            -- ③ 收尾：取消勾选
                            WR_PaladinForever_WisdomSealPhase = nil
                            PigSet.FH_CRZHSY = false
                            if type(WR_SyncConfigCheckbox) == "function" then
                                WR_SyncConfigCheckbox("FH_CRZHSY")
                            end
                            return true
                        end
                    end
                end
            end
        end
    else
        WR_PaladinForever_WisdomSealPhase = nil
        WR_PaladinForever_WisdomSealAt = nil
    end


    -- 1. 生存自保（防骑低血优先生存）
    --   ★★ 2026-11-10 如实说明（不是 bug，别再来回排查）：
    --     PlayerHP 来自 WR_GetUnitHP → WR_SafeHPPct。无限 12.x 战斗中 UnitHealth 是
    --     secret value，安全层统一降级为 1（= 满血）。所以这两条 `PlayerHP < 0.20 /
    --     < 0.35` 在战斗中【恒不成立】，圣疗术 / 圣佑术 的自动提示在战斗中永远不会亮。
    --     这是客户端硬限制（插件不得基于战斗数值做逻辑），不是这里写错了。
    --     要真正可用只能改成事件/计数驱动（例如记「本场已交过圣疗」），收益远低于
    --     回归风险，暂不做；玩家可手动施放，或走面板「插入 圣疗术 / 圣盾术」一次性开关。
    if PlayerHP < 0.20 and WR_SpellUsable("圣疗术", true) then
        if WR_PaladinForever_ShowSkillCD("圣疗术", 48, 1200) then return true end
    end
    if PlayerHP < 0.35 and WR_SpellUsable("圣佑术", true) then
        if WR_PaladinForever_ShowSkillCD("圣佑术", 78, 300) then return true end
    end

    -- 2. 常驻光环与仇恨姿态
    --    有「惩罚光环」优先（NGA 防骑仇恨机制：惩罚光环反伤提升仇恨）；
    --    未学会时退回「虔诚光环」减伤。
    --   ★ 2026-11-09 用户要求：关闭「开启虔诚光环/惩罚光环」文字提示，
    --     不再弹这条提醒（光环仍可手动开启，不影响其他循环）。
    local auraName = "虔诚光环"
    if WR_PaladinForever_SpellKnown("惩罚光环") then
        auraName = "惩罚光环"
    end
    -- （此段原 PigAlert 提示已按用户要求关闭）
    -- 正义之怒：30 分钟 Buff，缺失时补。
    --   ★ 修复「反复使用正义之怒」：
    --     · 判定改由 FuryUp() 负责（顺序：光环扫描 → 缓存 → 施放成功记录 30 分钟）；
    --     · 提示时间不写进 FuryCastAt —— 提示不代表真的打出去了。
    --   ★ 2026-11-09 用户反馈「补的时机太晚，脱战发现没了应第一时间补，补周期太长」：
    --     旧防抖 60 秒 → 脱战缺 Buff 时第一次补完，若玩家/AHK 漏按，60 秒内不再提示，
    --     感知就是「补得太慢、周期太长」。改为 3 秒防抖：
    --       · 缺失即补（首 tick 立刻亮），漏按也能 3 秒后重试，不再久等；
    --       · 一旦真的施放成功，FuryUp() 由「施放成功记录」判为已开启 → 立即停止提示；
    --       · 成功施放事件里 HideNow("正义之怒") 会立刻灭色块，避免 AHK 连按。
    if (PigSet.FH_ZYZN ~= false)
       and not WR_PaladinForever_FuryUp()
       and WR_SpellUsable("正义之怒")
       and WR_PaladinForever_CanPrompt("正义之怒", 3) then
        if WR_ColorFrame_ShowSkill("正义之怒", 31) then
            WR_PaladinForever_MarkPrompt("正义之怒", 31)
            WR_PaladinForever_HideSkillLater("正义之怒", 31, 1.0)
            return true
        end
    end

    -- 2.6 祝福（战斗外按菜单选择补，力量/智慧/王者/强效）
    if WR_PaladinForever_ProtBlessing() then return true end

    -- ============================================================
    -- 3. 常驻圣印（面板「圣印」专区所选，默认愤怒圣印）
    -- ------------------------------------------------------------
    -- ★★ 2026-11-09 第四次修正：本服圣印是 30 秒短 Buff（截图「剩余25秒」），
    --   而 AHK 是「色块常亮就一直按」（扫描30ms + 冷却33~44ms ≈ 每60ms一次，
    --   3 秒保持 = 约 50 次 /cast 圣印）。所以补印必须做成
    --   「一个 Buff 周期最多亮一次色块」，而不是靠 1/8 秒防抖反复重试：
    --     · SealNeedsRefresh：任意圣印在身上 / Buff 周期内成功上过印 → 一律不补；
    --       硬锁走完（30.2 秒 = Buff 30 + 缓冲 0.2）且光环仍读不到 → 允许补一次。
    --       ★ 2026-11-10 用户口径两次收紧：
    --         ① 「五秒太久了改2秒」→ 缓冲 3 → 1 秒，掉印后 2 秒重新亮；
    --         ② 「圣印空档期太久，我想更快点补圣印」→ 缓冲 1 → 0.2 秒，
    --            加上下面那 0.1 秒缺印确认 = 掉印后 0.3 秒就重新亮色块。
    --     · CanPrompt(mainSeal, 3)：刚亮过色块 3 秒内不再亮（AHK 漏按可较快重试）。
    --       ★ 这一条**不能跟着收紧**：它是「施放成功事件丢失导致记账不推进」时
    --         唯一防连按的闸，收到 0.3 秒会立刻回到「反复上印」的老 bug。
    --     · HideSkillLater 对圣印统一 0.3 秒 + 成功施放事件立即 HideNow。
    --   「何时能亮」仍由 CanApplySeal（战斗中 + 近战可攻击）决定，脱战绝不点亮。
    -- ============================================================
    -- ★★ 2026-11-11：状态机可能在本 tick 已推进阶段（例如刚从「需要光明」切到
    --   「目标已有 debuff」），补印目标要按最新阶段重新取一次。
    maintainSeal, maintainSealSlot = WR_PaladinForever_ProtSealGoal(mainSeal, mainSealSlot)
    local sealAllowed = WR_PaladinForever_SealNeedsRefresh(maintainSeal)
    if sealAllowed then
        WR_PaladinForever_SealMissingSince = WR_PaladinForever_SealMissingSince or GetTime()
    else
        WR_PaladinForever_SealMissingSince = nil
    end
    -- 进战标记只在确实读到圣印时清；否则保留到补印成功（脱战由事件清）
    if WR_PaladinForever_ForceSealAtCombat and WR_PaladinForever_BaseSealUp() then
        WR_PaladinForever_ForceSealAtCombat = false
    end
    -- 0.1 秒缺印确认 + 3 秒重试闩锁。
    --   ★ 2026-11-09 第十一次修正：10 秒太长——AHK 偶尔漏读一次色块，就要再等
    --   10 秒才重试，玩家感知就是「战斗中一直没挂圣印」。3 秒重试足够快；
    --   一旦真的上印成功，SealNeedsRefresh 的硬锁会立即阻止再次点亮，
    --   不会因重试变快而反复上印。
    --   ★★ 2026-11-10 用户口径「圣印空档期太久，我想更快点补圣印」：
    --   缺印确认由 1 秒收到 0.1 秒（只保留一个主循环 tick 的量化余量）。
    --   为什么 0.1 秒还留着、不直接删掉：主循环 tick 是 0.1 秒（MainLoop 的
    --   WR_Delay），0.1 秒正好吃掉「硬锁刚过 → 下一 tick 才判定」的抖动，
    --   删成 0 会让首次判定落在硬锁边界上，容易出现「这一 tick 还差 3ms 不亮、
    --   下一 tick 才亮」的不稳定表现；保留 0.1 秒后总空窗稳定在 0.3 秒。
    local sealDue = sealAllowed
        and (GetTime() - (WR_PaladinForever_SealMissingSince or GetTime())) >= 0.1
        and WR_PaladinForever_CanPrompt(maintainSeal, 3)
    if sealDue and WR_PaladinForever_CanApplySeal() then
        local sealKnown = WR_SpellUsable(maintainSeal)
        if not sealKnown then
            sealKnown = WR_PaladinForever_SpellKnown(maintainSeal)
        end
        if sealKnown then
            if WR_PaladinForever_ShowSealBlock(maintainSeal, maintainSealSlot) then
                WR_PaladinForever_ForceSealAtCombat = false
                WR_PaladinForever_MarkPrompt(maintainSeal, maintainSealSlot)
                WR_PaladinForever_MarkPrompt("切回常驻圣印", maintainSealSlot)
                WR_PaladinForever_HideSkillLater(maintainSeal, maintainSealSlot, 0.3)
                return true
            end
        end
    end

    -- 4. 自动攻击（开怪前提示 + ★ 2026-11-10 战斗中自动平砍重开）
    --    ★ 排在常驻圣印之后：脱战缺印时先补印，别让「攻击」把补印挤掉。
    --    ★★ 补印色块的保持窗口内也不能提示「攻击」：WR_ColorFrame_Show 每次会先
    --      隐藏所有颜色框架，否则刚亮起的圣印色块 0.1 秒后就被攻击色块覆盖，
    --      AHK 读到的永远是 /STARTATTACK 而不是 SHIFT-F7 / CTRL-NUMPAD1，
    --      这正是「所有圣印都不打」在真机上的最后一环。
    local sealHoldUntil = WR_PaladinForever_PromptHold
        and WR_PaladinForever_PromptHold[tostring(maintainSeal)]
    local sealPromptActive = sealHoldUntil and GetTime() < sealHoldUntil
    -- ★★ 2026-11-10 用户口径：不符合条件就不亮色块。
    --   平砍提示同样要过「目标可攻击 + 近战 8 码」门：目标跑出近战还亮「攻击」色块，
    --   AHK 会一直按 /startattack，把后面所有技能环节饿死。
    --   ★★ 2026-11-10 用户口径「战斗中加入自动平砍」：
    --     旧逻辑是 `not AutoAttackActive()`，而 AutoAttackActive 在战斗中恒 true
    --     （无限读不到真实平砍状态）→ 战斗中永远不提示 → 平砍一停就再也不恢复。
    --     现在改为 AutoAttackNeedsRestart()：
    --       · 事件可用（PLAYER_ENTER_COMBAT/LEAVE_COMBAT）→ 按真实状态，停了立刻补；
    --       · 事件不可用 → 限频盲试（3 秒一次），一次 /startattack 就能重开，
    --         重复按无害，且限频保证不会像「常亮」那样饿死技能循环。
    --     同时保留「平砍没停就不亮」的静默：真正在跑时事件会把它关掉，
    --     不会出现色块常亮被 AHK 连按的情况。
    local autoAttackWanted = (not sealPromptActive)
        and not PlayerMove
        and WR_PaladinForever_CanHitTarget("攻击", "target")
        and WR_PaladinForever_AutoAttackNeedsRestart()
        and WR_SpellUsable("攻击")
    if autoAttackWanted then
        -- ★ 开怪前（脱战）优先提示平砍：这时没有别的技能可打。
        --   战斗中不在这里 return，留到所有技能环节之后再兜底（见函数末尾第 15 段）。
        if not UnitAffectingCombat("player") then
            if WR_ColorFrame_ShowSkill("攻击", 15) then
                WR_PaladinForever_MarkPrompt("攻击", 15)
                WR_PaladinForever_HideSkillLater("攻击", 15, 1.0)
                return true
            end
        end
    end

    -- 4.5 神圣打击的独立分支已并入第 6 步调度。
    --   ★★ 2026-11-10 方案 2：单体调度里神圣打击就绪时永远先于审判；
    --      它不在 CD 的时候审判仍会正常轮转，不存在「审判被完全饿死」。

    -- 5. 战斗门（圣印在门之前处理，避免目标未进战斗时补不了印）
    if not (UnitAffectingCombat("player") and TargetInCombat) then return false end

    -- 6. 主循环调度：「谁 CD 好了先打谁」
    --   · 审判：基础 CD 10 秒，点「强化审判」2/2 后为 8 秒（运行时探测，见 GetJudgeCooldown）；
    --     审判要求身上有任意圣印，但不该被「当前常驻圣印的本地计时」卡死。
    --     2026-11-09 修复：门控由 ProtSealUp() 改为「真实圣印状态 + 任意圣印 Buff」，
    --     避免开怪前上的圣印因 30 秒记录过期而被误判缺印、第一轮永远不打审判。
    --   · 神圣打击：本服 CD 6 秒；所有圣骑士 6 级学会的核心填充/仇恨。
    --   两个技能都就绪时按 FreeAt 排序：谁上一次施放后先轮到、就谁先打，
    --   只有一个就绪就只打那个，不再让固定优先级互相挨饿。
    --   面板「自动神圣打击」开关 FH_HS 关闭时退化为只按审判。
    --
    --   ★★ 2026-11-11：删除「单体」循环（FH_DT）后，主调度不再需要为单体起手让出审判。
    -- ★★ 2026-11-09 修复「光明圣印流程永远不触发」：
    --   主调度只要看到审判就绪就立刻打掉 → 审判进入 CD → 光明圣印流程的
    --   Ready("审判") 永远是 false，整条流程永远等不到「审判可用」。
    --   现在：光明圣印开关处于「需要光明 / 已提示审判」阶段（phase 0/1）时，
    --   主调度【让出审判】，把审判留给这条流程使用；phase 2 以后若审判已经提示过，
    --   主调度就不再占它（由提示防抖与本地 CD 兜底）。十字军审判、智慧审判、智慧圣印插入同理。
    --   insertSealRunning：光明圣印 / 十字军审判 / 智慧审判 / 智慧圣印插入四条流程共用同一个「让出审判」判断。
    local lightWaitingJudge = (PigSet and PigSet.FH_CRGMSY)
        and ((WR_PaladinForever_LightSealPhase or 0) < 2)
    local crusaderWaitingJudge = (PigSet and PigSet.FH_SZJSP)
        and ((WR_PaladinForever_CrusaderSealPhase or 0) < 2)
    local wisdomWaitingJudge = (PigSet and PigSet.FH_ZHSP)
        and ((WR_PaladinForever_WisdomJudgementPhase or 0) < 2)
    local insertSealRunning = (PigSet and PigSet.FH_CRZHSY)
        or lightWaitingJudge or crusaderWaitingJudge or wisdomWaitingJudge
    local judgeCD = WR_PaladinForever_GetJudgeCooldown()

    -- ============================================================
    -- ★★ 2026-11-10 用户口径：8 码内目标 ≥2 个 → 多目标固定优先级
    -- ------------------------------------------------------------
    --   顺序：奉献（仅 8 码内目标 ≥3 个时）→ 审判（身上挂着常驻圣印）→
    --         神圣打击 → 驱邪术（亡灵/恶魔，可用就打）→ 神圣之盾
    --   · 圣印本身仍由第 3 段「常驻圣印」负责补/切，本段只决定技能先后；
    --   · 目标 ≤1 个 → 保持原有 Ready-first（谁 CD 好了先打谁），行为不变；
    --   · 两条链共用同一套「此刻能否提示」判定，避免多目标/单体口径分裂。
    --   ★ 为什么要固定顺序：多目标时仇恨与减伤窗口都由奉献/审判起手，
    --     Ready-first 会让先转好的神圣之盾抢在奉献前面，导致小怪散开。
    -- ============================================================
    local aoeMode = (tonumber(UnitCount8) or 0) >= 2

    -- 各技能「此刻是否允许提示」的统一判定（条件与原单目标分支逐条对齐）
    --   ★★ 2026-11-10 用户口径：每条都补上「真打得出去」门（目标存在/可攻击/活着 + 射程），
    --      过不了就不亮色块，交给主循环继续判断下一个环节。
    local judgeEligible = (not insertSealRunning)
        and (sealState ~= "missing" or WR_PaladinForever_SealActive())
        and WR_PaladinForever_CanHitTarget("审判", "target")
        and WR_SpellUsable("审判")
    -- 神圣打击：射程门沿用原 hsRangeOK（<=8，读不到放行），行为不变
    -- ★★ 2026-11-10：不再用 WR_SpellUsable("神圣打击") 做前置门。
    --   本服神圣打击共 8 个 rank，旧版把 Rank3 的 1866 写死；角色升到 28 级后
    --   当前 rank 换成 680/2495/5569…，IsUsableSpell(1866) 返回 false →
    --   hsEligible 恒 false → CD 好了也永远不亮。是否学会改由 SpellKnown 判断
    --   （内部会遍历全部 rank），冷却仍由下面 WR_PaladinForever_Ready 的本地记账判断。
    local hsRangeOK = (TargetRange == nil or TargetRange >= 999 or TargetRange <= 8)
    local hsEligible = hsRangeOK
        and WR_PaladinForever_TargetCastable("target")
        and (PigSet.FH_HS ~= false)
        and WR_PaladinForever_SpellKnown("神圣打击")
    -- 驱邪术（亡灵/恶魔，30 码内；本地 15 秒 CD）
    local exorcismEligible = WR_PaladinForever_IsUndeadOrDemon("target")
        and WR_PaladinForever_CanHitTarget("驱邪术", "target")
        and WR_SpellUsable("驱邪术", true)
    -- 神圣之盾（防护核心减伤；受面板 FH_SZS 开关控制，默认开）
    --   ★ 自身 Buff 类技能，不判射程、也不要求敌方目标（防骑要能给自己套盾）。
    local holyShieldEligible = (PigSet == nil or PigSet.FH_SZS ~= false)
        and WR_PaladinForever_SpellKnown("神圣之盾")
    -- 奉献（受面板「自动 奉献」FH_FX 控制；蓝量 ≥30%、近战 5 码内）
    --   ★ 目标数量门单独由 tryConsecrate(minCount) 传入：
    --     ★★ 2026-11-10 用户口径：奉献仅在 8 码内目标 ≥3 个时使用；
    --     2 个目标的多目标链跳过奉献，直接从审判开始。
    --   ★★ 2026-11-11 用户口径：新增奉献蓝量下限 30%——蓝量百分比低于 30%
    --     时不施放奉献；阈值见 WR_PaladinForever_PROT_CONSECRATION_MANA_MIN。
    --   ★★ 2026-11-10 如实说明：PlayerMP 来自 WR_GetUnitMP → WR_SafePowerPct，
    --     战斗中 UnitPower 是 secret value，安全层降级为 1（= 满蓝）。
    --     所以蓝量门在战斗中可能【恒通过】；这是客户端硬限制，不是漏写。
    --     保留它是因为脱战/可读时仍然有效，且低蓝时能提前停止提示奉献。
    local consecEligible = (PigSet == nil or PigSet.FH_FX ~= false)
        and PlayerMP >= WR_PaladinForever_PROT_CONSECRATION_MANA_MIN
        and WR_PaladinForever_CanHitTarget("奉献", "target")
        and WR_SpellUsable("奉献", true)

    -- 统一「尝试提示」闭包：返回 true 表示本 tick 已点亮色块，调用方直接 return true
    --   ★ 每个闭包内再复核一次射程门：eligible 是 tick 开头算的，本节内不变量，
    --     但保留复核可防止将来有人复用闭包时漏门（开销可忽略）。
    local function tryConsecrate(minCount)
        if not consecEligible then return false end
        if (tonumber(UnitCount8) or 0) < (minCount or 0) then return false end
        if not WR_PaladinForever_CanHitTarget("奉献", "target") then return false end
        return WR_PaladinForever_ShowSkillCD("奉献", 5, 8)
    end
    local function tryJudge()
        if not judgeEligible then return false end
        if not WR_PaladinForever_CanHitTarget("审判", "target") then return false end
        return WR_PaladinForever_ShowSkillCD("审判", 2, judgeCD)
    end
    local function tryHolyStrike()
        if not hsEligible then return false end
        if not WR_PaladinForever_CanHitTarget("神圣打击", "target") then return false end
        return WR_PaladinForever_ShowSkillCD("神圣打击", 74,
            WR_PaladinForever_SkillCD["神圣打击"])
    end
    local function tryExorcism()
        if not exorcismEligible then return false end
        if not WR_PaladinForever_CanHitTarget("驱邪术", "target") then return false end
        return WR_PaladinForever_ShowSkillCD("驱邪术", 20, 15)
    end
    local function tryHolyShield()
        if not holyShieldEligible then return false end
        return WR_PaladinForever_ShowSkillCD("神圣之盾", 24, 10)
    end

    if aoeMode then
        -- ★ 多目标：严格按用户指定顺序，不做 Ready-first 重排
        -- ★★ 2026-11-10 用户口径「奉献改为3目标使用」：2 个目标不铺奉献，从审判开始。
        if tryConsecrate(3) then return true end
        if tryJudge() then return true end
        if tryHolyStrike() then return true end
        if tryExorcism() then return true end
        if tryHolyShield() then return true end
        -- 多目标链全部不可用 → 落到下方通用收尾（愤怒之锤 / 天赋）
    else
        -- ============================================================
        -- ★★ 2026-11-10 用户口径（方案 2）：神圣打击 CD 好了「永远优先」审判
        -- ------------------------------------------------------------
        -- 背景：审判点「强化审判」后是 8 秒 CD，神圣打击是 6 秒 CD，两者
        --   周期不同步。旧的 Ready-first 按 FreeAt 排序，神圣打击刚转好时
        --   经常正好撞上审判或排在后面，只能等下一个 GCD（实测被顺延
        --   1.1~1.2 秒，叠上其他环节可到 3 秒）。
        -- 现在：只要神圣打击「此刻真打得出去」（开关 / 射程 / 目标 / 冷却都过），
        --   就先亮神圣打击；只有它不可用时才轮到审判。
        --   ★ 这是用户明确选择的方案 2：接受审判的仇恨/嘲讽顺序后移。
        --   ★ 冷却判定走本地记录（WR_PaladinForever_Ready），与 ShowSkillCD
        --     的 ① 施放记录通道完全一致，不会出现「以为就绪实际在 CD」。
        local hsReady = hsEligible
            and WR_PaladinForever_Ready("神圣打击", WR_PaladinForever_SkillCD["神圣打击"])
        if hsReady then
            if tryHolyStrike() then return true end
            -- 神圣打击刚亮过、正在等 0.45 秒防抖或 GCD 重试时，不要马上把色块
            -- 让给审判（否则 AHK 会把刚亮的「神圣打击」色块顶掉）。等它自己的
            -- 提示保持窗口走完（PROMPT_HOLD=1.5 秒）再放行下面的调度，既保证
            -- 优先级、又不会因槽位异常等情况永久卡死。
            local lastHsPrompt = WR_PaladinForever_PromptCD["神圣打击"]
            if lastHsPrompt
               and (GetTime() - lastHsPrompt) < (WR_PaladinForever_PROMPT_HOLD or 1.5) then
                return false
            end
        end

        local candidates = {}
        if judgeEligible then candidates["审判"] = judgeCD end
        if hsEligible then
            candidates["神圣打击"] = WR_PaladinForever_SkillCD["神圣打击"]
        end
        -- ★ 2026-11-09：起手 3 秒内优先审判（如果审判本身就绪）。
        --   ★★ 2026-11-10 方案 2 后：上面已先试过神圣打击；这里只处理
        --     神圣打击不可用、审判就绪的起手窗口，避免固定优先级让审判也挨饿。
        local freshCombat = WR_PaladinForever_CombatStartAt
                            and (GetTime() - WR_PaladinForever_CombatStartAt) <= 3
        if freshCombat and candidates["审判"] then
            -- ★★ 2026-11-10：走 tryJudge（含射程/目标门），不再直接调 ShowSkillCD
            if tryJudge() then
                return true
            end
        end
        local scheduled = WR_PaladinForever_PickMostReady(candidates)
        if scheduled then
            local slot = (scheduled == "审判") and 2 or 74
            -- ★★ 2026-11-10：调度选出的技能同样要过「真打得出去」门。
            --   过不了就落到下面逐个环节继续判断，绝不亮了再失败。
            local function tryScheduled()
                if not WR_PaladinForever_CanHitTarget(scheduled, "target") then return false end
                return WR_PaladinForever_ShowSkillCD(scheduled, slot, candidates[scheduled])
            end
            if tryScheduled() then
                return true
            end
        end

        -- 8. 驱邪术（亡灵/恶魔，30 码内；本地 15 秒 CD）
        if tryExorcism() then return true end

        -- 9. 奉献（受面板「自动 奉献」开关 FH_FX 控制；仅目标数量 ≥3、蓝量 ≥30%、近战 5 码内）
        --   ★ 2026-11-10 后本行在单体链里实际不可达：UnitCount8 ≥2 已走上面的多目标链，
        --     而这里要求 ≥3。保留它是作为「多目标阈值将来被调高」时的安全网，
        --     语义与改动前完全一致，不会让奉献在单体场合乱放。
        if tryConsecrate(3) then return true end

        -- 10. 神圣之盾（若已学会；防护核心减伤）
        --   ★★ 2026-11-11 用户口径：从原第 8 步后移到「奉献」之后（本链实际是驱邪术之后）。
        --   ★ 修复「CD 没好也亮色块」：原写法 CanPrompt(8) + Talent() 有两个问题：
        --     ① Talent() 只判「已学会」，完全不查冷却；而 WR_SpellUsable 对带 CD 技能恒 true
        --        （无限战斗中 GetSpellCooldown 是 secret）→ 等于没有冷却门；
        --     ② 8 秒的防抖窗口小于本服真实 CD 10 秒（截图实测 Rank1 / SpellID 20925 / 10 秒）
        --        → 第 8 秒就重新亮块，此时还剩 2 秒 CD。
        --   现改为统一走 ShowSkillCD（本地按「成功施放时刻 + CD」判定），CD 取 10 秒。
        if tryHolyShield() then return true end
    end

    -- 11. 愤怒之锤（<20% 斩杀；本地 6 秒 CD）
    --   ★★ 2026-11-10：补射程门（30 码）。
    if WR_SafeHPPct("target") < 0.20
       and WR_PaladinForever_CanHitTarget("愤怒之锤", "target")
       and WR_SpellUsable("愤怒之锤", true) then
        if WR_PaladinForever_ShowSkillCD("愤怒之锤", 1, 6) then return true end
    end

    -- 12. 无限天赋（已学会才提示，带本地 CD）
    --   ★ 2026-11-08：迅捷审判原用色块 117，而 117 是旧版跟随系统的「焦点跟随」槽位
    --     （AHK 按 ALT-- 执行 /follow focus）→ 点亮它就等于让 AHK 跟随焦点。
    --   ★ 2026-11-10 用户要求：删除「可施放 迅捷审判」文字提示，不再提醒。
    --   ★★ 2026-11-10：圣殿壁垒同样改为只弹文字提示。
    --     原因：它的槽位 118 在 Paladin_Macros.lua:132 绑定的是
    --     /target 凯雷塞斯王子（纳克萨玛斯 BOSS）。点亮 118 号色块 = 让 AHK 连按
    --     15~25 次切目标，战斗中会把当前目标强行切走，毁掉整条循环。
    --     现在 WR_SkillColor 里 ["圣殿壁垒"] 已置 nil，这里也不再调 Talent 占色块。
    if WR_PaladinForever_CanPrompt("圣殿壁垒", 60)
       and WR_PaladinForever_SpellKnown("圣殿壁垒") then
        PigAlert("可施放 圣殿壁垒", 1, 0.8, 0, 1.2)
        WR_PaladinForever_MarkPrompt("圣殿壁垒")
        return true
    end
    -- ★ 2026-11-10 用户要求：删除「可施放 迅捷审判」文字提示，不再提醒。

    -- 13. ★★ 2026-11-10 用户口径「战斗中加入自动平砍」——兜底重开平砍
    -- ------------------------------------------------------------
    --   为什么放在【所有技能环节之后】：
    --     平砍的「是否在跑」在本服读不准（无限 1.60.x 没有可靠的自动攻击状态）。
    --     放在最后，意味着只要有任何一个技能该打，就先打技能；只有整轮都没技能
    --     可打（全都 CD / 条件不满足）时，才用这个色块把平砍接上。
    --     这样即使状态判错，也绝不会抢占技能优先级、更不会饿死主调度。
    --   为什么需要它：
    --     平砍会在「切目标 / 目标死亡换目标 / 被控制 / 手动停了」之后停下，
    --     旧逻辑战斗中恒判「已在平砍」，于是再也不提示 → 整场白丢平砍输出。
    --   限频：
    --     事件可用时停了立刻补（成功收到 ENTER 就停）；事件不可用时 3 秒盲试一次，
    --     一次 /startattack 就能重开，重复按无副作用。
    if autoAttackWanted then
        if WR_ColorFrame_ShowSkill("攻击", 15) then
            WR_PaladinForever_MarkPrompt("攻击", 15)
            WR_PaladinForever_HideSkillLater("攻击", 15, 1.0)
            return true
        end
    end

    return false
end
