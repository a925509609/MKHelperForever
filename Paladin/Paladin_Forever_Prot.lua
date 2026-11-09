-- ============================================================
-- Paladin Forever · Prot 专精循环（单体坦克）
-- ------------------------------------------------------------
-- 依据本服实际法术书（2026-11-06 实测）：
--   攻击 / 审判 / 神圣打击 / 愤怒圣印 / 正义圣印 / 十字军圣印 /
--   奉献 / 驱邪术 / 制裁之锤 / 圣佑术 / 保护祝福 / 自由祝福 /
--   王者祝福 / 力量祝福 / 智慧祝福 / 圣疗术 / 圣光术 /
--   虔诚光环 / 正义之怒 / 纯净术 / 救赎
-- 参考攻略：
--   wow.gg《WoW Forever: 防护圣骑士》——正义之怒常驻、愤怒圣印常驻、
--     审判=仇恨+嘲讽、神圣打击=主要仇恨、奉献看蓝量；
--   wowf.io《魔兽世界：无限 防护圣骑士指南》——单体优先级
--     审判 > 神圣之盾 > 神圣打击 > 愤怒之锤，法力充足才放奉献，
--     亡灵/恶魔用驱邪术，制裁之锤打断危险施法，低血用圣佑术/圣疗术。
-- 说明：未学会/本服不存在的技能由 WR_SpellUsable / WR_Forever_IsSpellKnown
--   自动跳过，不影响低等级阶段的循环。
-- ★ 2026-11-06：战斗中 GetSpellCooldown 是 secret，WR_GetGCD 被收敛成 0，
--   WR_SpellUsable 对带 CD 的技能恒 true → 色块会一直卡在审判。
--   本文件所有有 CD 的技能改用「本地冷却计时」提示（WR_PaladinForever_ShowSkillCD）。
--   本地冷却以「UNIT_SPELLCAST_SUCCEEDED 的成功施放时间」为唯一起点，
--   不再以「提示显示时间」起算 —— 否则提示刚好落在 GCD 被吞掉后会锁死整个 CD，
--   出现「神圣打击 CD 好了不打，要等第二个审判之后才亮」。
-- ============================================================

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

    -- ★ 常驻圣印：默认愤怒圣印；面板勾选「正义圣印」（FH_ZYSY）时改为正义圣印。
    local mainSeal, mainSealSlot, mainSealField = WR_PaladinForever_MainSeal()
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
    --   ★ 勾选「单体」时改由下方 14.5 段状态机接管，这里必须让位并清掉强制标记。
    if PigSet and PigSet.FH_DT then
        WR_PaladinForever_ForceSealAtCombat = false
    elseif WR_PaladinForever_ForceSealAtCombat
           and not WR_PaladinForever_BaseSealUp()
           and WR_PaladinForever_SealNeedsRefresh(mainSeal)
           and WR_PaladinForever_CanApplySeal() then
        if WR_PaladinForever_ShowSealBlock(mainSeal, mainSealSlot) then
            WR_PaladinForever_ForceSealAtCombat = false
            WR_PaladinForever_MarkPrompt(mainSeal, mainSealSlot)
            WR_PaladinForever_HideSkillLater(mainSeal, mainSealSlot, 0.3)
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
    if WR_PaladinForever_AnySealUp() or not WR_PaladinForever_SealNeedsRefresh(mainSeal) then
        WR_PaladinForever_HideNow(mainSeal, mainSealSlot)  -- 先按槽位硬隐藏（不依赖文字）
        for i = 1, #WR_PaladinForever_SealNames do
            WR_PaladinForever_HideNow(WR_PaladinForever_SealNames[i])
        end
        WR_PaladinForever_HideSkillVisual(mainSeal, mainSealSlot)
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

    -- ★ 14.5 单体循环起手（面板「单体」= PigSet.FH_DT，常驻开关）
    --   用途：开怪前先挂十字军圣印 → 打出审判挂「十字军审判」debuff → 切回常驻圣印。
    --   阶段（WR_PaladinForever_SinglePhase）：
    --     0 = 起手：提示「十字军圣印」
    --     1 = 已提示切印，等 3 秒（切印 + 一个 GCD）且审判 CD 就绪后提示「审判」挂 debuff
    --     2 = 已提示审判，等 2 秒（审判生效）后提示常驻圣印切回（愤怒圣印 / 正义圣印）
    --     3 = 流程完成，本次战斗不再干预（脱战重置为 0）
    --   ★ 不读十字军圣印 Buff：无限战斗中玩家光环是 secret，读不到会死循环，改用本地计时。
    --   ★ 放在变量初始化之后：本段要用 TargetInCombat，提前读会拿到 nil。
    --   ★「是否已学会」判定必须先把中文名解析成 spellID 再问 IsPlayerSpell：
    --     无限 1.60.x 的 IsPlayerSpell / C_Spell.* 只认数字 ID，直接传中文名恒 false，
    --     会让整段前置被误判为「技能缺失」而永久跳过（这就是之前单体循环不生效的原因）。
    if PigSet and PigSet.FH_DT then
        if not (UnitAffectingCombat("player") and TargetInCombat) then
            -- 脱战或目标丢失：重置阶段，下一场重新起手
            WR_PaladinForever_SinglePhase = 0
            WR_PaladinForever_SingleStageAt = nil
        else
            local phase = WR_PaladinForever_SinglePhase or 0
            -- ★ 用 WR_PaladinForever_SpellKnown 统一判定（内部先解析 ID 再问客户端）
            local crusaderOK = WR_PaladinForever_SpellKnown("十字军圣印")
            local judgeOK = WR_PaladinForever_SpellKnown("审判")
            if (not crusaderOK) or (not judgeOK) then
                -- 前置技能确实未学会（低等级）：跳过整段
                phase = 3
            end
            if phase < 3 then
                if phase == 0 then
                    -- ★ 显式切印：十字军起手是「主动换印」，放行一次（只此一次）
                    WR_PaladinForever_SealSwitchAllowUntil = GetTime() + 0.5
                    if WR_PaladinForever_ShowSealBlock("十字军圣印", 30) then
                        WR_PaladinForever_MarkPrompt("十字军圣印", 30)
                        WR_PaladinForever_HideSkillLater("十字军圣印", 30, 1.5)
                        WR_PaladinForever_SinglePhase = 1
                        WR_PaladinForever_SingleStageAt = GetTime()
                        return true
                    end
                elseif phase == 1 then
                    -- ② 等十字军圣印切好（3 秒 ≈ 切印 + 一个 GCD），
                    --    且必须确认审判本身真的就绪（本地 CD 通道），才提示挂 debuff。
                    --    ★ 不能只按时间推进：审判可能被其他分支消耗，盲提示会亮在 CD 中。
                    if (GetTime() - (WR_PaladinForever_SingleStageAt or GetTime())) >= 3
                       and WR_PaladinForever_Ready("审判", WR_PaladinForever_GetJudgeCooldown()) then
                        if WR_ColorFrame_ShowSkill("审判", 2) then
                            WR_PaladinForever_MarkPrompt("审判", 2)
                            WR_PaladinForever_HideSkillLater("审判", 2, 1.5)
                            WR_PaladinForever_SinglePhase = 2
                            WR_PaladinForever_SingleStageAt = GetTime()
                            return true
                        end
                    end
                elseif phase == 2 then
                    if (GetTime() - (WR_PaladinForever_SingleStageAt or GetTime())) >= 2 then
                        -- ③ 切回常驻圣印（愤怒圣印 / 正义圣印，由 FH_ZYSY 决定）
                        -- ★ 显式切印（十字军 → 常驻）：放行一次
                        WR_PaladinForever_SealSwitchAllowUntil = GetTime() + 0.5
                        if WR_PaladinForever_ShowSealBlock(mainSeal, mainSealSlot) then
                            WR_PaladinForever_MarkPrompt(mainSeal, mainSealSlot)
                            WR_PaladinForever_HideSkillLater(mainSeal, mainSealSlot, 1.5)
                            WR_PaladinForever_SinglePhase = 3
                            return true
                        end
                    end
                end
            end
        end
    else
        -- 未勾选单体：清空阶段，勾上即重新起手
        WR_PaladinForever_SinglePhase = nil
        WR_PaladinForever_SingleStageAt = nil
    end

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
        local function WR_ProtOneShot(var, spell, slot)
            if not (PigSet and PigSet[var]) then return false end
            if not WR_PaladinForever_SpellKnown(spell) then
                PigSet[var] = false
                if type(WR_SyncConfigCheckbox) == "function" then
                    WR_SyncConfigCheckbox(var)
                end
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
    -- ★ 插入 光明圣印（第一优先级，与上面插入类技能同级）
    -- ------------------------------------------------------------
    -- ★★ 2026-11-10 按用户口径补全流程：
    --   目标身上出现「圣光审判」debuff 后 → 自动切回当前循环的常驻圣印 → 取消勾选。
    --   为什么必须显式切回：本服审判【不消耗】圣印，打完审判后玩家身上仍是光明圣印；
    --   而常驻补印逻辑遵循「任意圣印在身一律不切」，不会自动把光明圣印换回来。
    --   阶段：
    --     0 = 审判就绪 → 提示切「光明圣印」（槽位 54 / 宏 CTRL-F11）
    --     1 = 等一个 GCD → 提示「审判」，让这发审判挂上「圣光审判」
    --     2 = 等目标出现「圣光审判」debuff（读不到则 2 秒兜底）→ 提示切回常驻圣印
    --     3 = 确认常驻圣印施放成功 → 取消勾选，本次插入结束
    --   安全阀：审判提示后 15 秒仍未完成 → 收尾取消勾选，不卡循环。
    --   ★ 位置很关键：必须在第 6 步主调度之前，否则主调度会先把审判打掉。
    if PigSet and PigSet.FH_CRGMSY then
        local lightKnown = WR_PaladinForever_SpellKnown("光明圣印")
        local judgeKnown = WR_PaladinForever_SpellKnown("审判")
        if (not lightKnown) or (not judgeKnown) then
            -- 缺技能：关掉开关并同步界面勾选
            PigSet.FH_CRGMSY = false
            WR_PaladinForever_LightSealPhase = nil
            WR_PaladinForever_LightSealAt = nil
            WR_PaladinForever_LightSealJudgeAt = nil
            WR_PaladinForever_LightSealSwitchAt = nil
            WR_PaladinForever_LightSealSwitchBase = nil
            WR_PaladinForever_LightSealDeadline = nil
            if type(WR_SyncConfigCheckbox) == "function" then
                WR_SyncConfigCheckbox("FH_CRGMSY")
            end
        else
            local lphase = WR_PaladinForever_LightSealPhase or 0
            local ljudgeCD = WR_PaladinForever_GetJudgeCooldown()
            local now = GetTime()

            if lphase == 0 then
                -- ① 触发条件：审判**已就绪** → 切光明圣印
                if WR_PaladinForever_Ready("审判", ljudgeCD) then
                    -- ★ 插入功能 = 用户主动要求切光明圣印 → 显式切印放行一次
                    WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                    if WR_PaladinForever_ShowSealBlock("光明圣印", 54) then
                        WR_PaladinForever_MarkPrompt("光明圣印", 54)
                        WR_PaladinForever_HideSkillLater("光明圣印", 54, 2.0)
                        WR_PaladinForever_LightSealPhase = 1
                        WR_PaladinForever_LightSealAt = now
                        return true
                    end
                end
            elseif lphase == 1 then
                local elapsed = now - (WR_PaladinForever_LightSealAt or now)
                if elapsed > 10 then
                    -- 安全阀：切印后 10 秒仍没打出审判 → 放弃并取消勾选
                    WR_PaladinForever_LightSealPhase = nil
                    WR_PaladinForever_LightSealAt = nil
                    PigSet.FH_CRGMSY = false
                    if type(WR_SyncConfigCheckbox) == "function" then
                        WR_SyncConfigCheckbox("FH_CRGMSY")
                    end
                elseif elapsed >= 1.0 then
                    -- ② 给切印留一个 GCD，再打审判
                    if WR_PaladinForever_Ready("审判", ljudgeCD) then
                        if WR_ColorFrame_ShowSkill("审判", 2) then
                            WR_PaladinForever_MarkPrompt("审判", 2)
                            WR_PaladinForever_HideSkillLater("审判", 2, 1.5)
                            WR_PaladinForever_LightSealPhase = 2
                            WR_PaladinForever_LightSealJudgeAt = now
                            WR_PaladinForever_LightSealDeadline = now + 15
                            return true
                        end
                    end
                end
            elseif lphase == 2 then
                local sinceJudge = now - (WR_PaladinForever_LightSealJudgeAt or now)
                -- 目标身上的「圣光审判」= 光明圣印的审判效果；兼容目标 Buff 直接叫「光明圣印」的情况。
                -- 战斗中目标光环可能不可读（返回 0/999），所以最多等 2 秒就兜底切回，
                -- 绝不把玩家卡在光明圣印上。
                local lightDebuffUp = false
                if type(WR_GetUnitDebuffTime) == "function" then
                    local ok1, t1 = pcall(WR_GetUnitDebuffTime, "target", "圣光审判")
                    if ok1 and type(t1) == "number" and t1 > 0 then lightDebuffUp = true end
                    if not lightDebuffUp then
                        local ok2, t2 = pcall(WR_GetUnitDebuffTime, "target", "光明圣印")
                        if ok2 and type(t2) == "number" and t2 > 0 then lightDebuffUp = true end
                    end
                end
                if lightDebuffUp or sinceJudge >= 2.0 then
                    -- ③ 切回当前循环的常驻圣印（FH_ZYSY ? 正义圣印 : 愤怒圣印）
                    --    ★ 显式切印：玩家此刻身上是光明圣印，必须绕过「任意圣印在身不切」总闸
                    WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                    if WR_PaladinForever_ShowSealBlock(mainSeal, mainSealSlot) then
                        WR_PaladinForever_MarkPrompt(mainSeal, mainSealSlot)
                        WR_PaladinForever_HideSkillLater(mainSeal, mainSealSlot, 1.5)
                        WR_PaladinForever_LightSealPhase = 3
                        WR_PaladinForever_LightSealSwitchAt = now
                        WR_PaladinForever_LightSealSwitchBase = WR_PaladinForever_LastSealAppliedAt() or 0
                        return true
                    end
                end
                if sinceJudge > 10 then
                    -- 安全阀：审判一直没打出 / 目标始终读不到 → 结束插入
                    WR_PaladinForever_LightSealPhase = nil
                    WR_PaladinForever_LightSealJudgeAt = nil
                    WR_PaladinForever_LightSealDeadline = nil
                    PigSet.FH_CRGMSY = false
                    if type(WR_SyncConfigCheckbox) == "function" then
                        WR_SyncConfigCheckbox("FH_CRGMSY")
                    end
                end
            elseif lphase == 3 then
                local base = WR_PaladinForever_LightSealSwitchBase or 0
                local last = WR_PaladinForever_LastSealAppliedAt() or 0
                if last > base + 0.001 then
                    -- ④ 已确认切回常驻圣印 → 收尾
                    WR_PaladinForever_LightSealPhase = nil
                    WR_PaladinForever_LightSealAt = nil
                    WR_PaladinForever_LightSealJudgeAt = nil
                    WR_PaladinForever_LightSealSwitchAt = nil
                    WR_PaladinForever_LightSealSwitchBase = nil
                    WR_PaladinForever_LightSealDeadline = nil
                    PigSet.FH_CRGMSY = false
                    if type(WR_SyncConfigCheckbox) == "function" then
                        WR_SyncConfigCheckbox("FH_CRGMSY")
                    end
                else
                    local deadline = WR_PaladinForever_LightSealDeadline
                    local expired = type(deadline) == "number" and now > deadline
                    if expired then
                        -- 安全阀：色块多次重试仍没切回（AHK 漏读等）→ 收尾，不永久占用插入状态
                        WR_PaladinForever_LightSealPhase = nil
                        WR_PaladinForever_LightSealAt = nil
                        WR_PaladinForever_LightSealJudgeAt = nil
                        WR_PaladinForever_LightSealSwitchAt = nil
                        WR_PaladinForever_LightSealSwitchBase = nil
                        WR_PaladinForever_LightSealDeadline = nil
                        PigSet.FH_CRGMSY = false
                        if type(WR_SyncConfigCheckbox) == "function" then
                            WR_SyncConfigCheckbox("FH_CRGMSY")
                        end
                    elseif (now - (WR_PaladinForever_LightSealSwitchAt or now)) >= 3 then
                        -- 重试点亮常驻圣印色块（AHK 可能漏读一次）
                        WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                        if WR_PaladinForever_ShowSealBlock(mainSeal, mainSealSlot) then
                            WR_PaladinForever_MarkPrompt(mainSeal, mainSealSlot)
                            WR_PaladinForever_HideSkillLater(mainSeal, mainSealSlot, 1.5)
                            WR_PaladinForever_LightSealSwitchAt = now
                        end
                    end
                end
            end
        end
    else
        WR_PaladinForever_LightSealPhase = nil
        WR_PaladinForever_LightSealAt = nil
        WR_PaladinForever_LightSealJudgeAt = nil
        WR_PaladinForever_LightSealSwitchAt = nil
        WR_PaladinForever_LightSealSwitchBase = nil
        WR_PaladinForever_LightSealDeadline = nil
    end

    -- ★ 插入 智慧圣印（2026-11-09 用户需求：加插入智慧圣印功能）
    -- ------------------------------------------------------------
    --   与上面「插入光明圣印」同一套两阶段模板：
    --     ① phase=0：确认审判**已就绪** → 提示切「智慧圣印」（槽位 108 / 宏 ALT-SHIFT-F8），进入 1
    --     ② phase=1：等一个 GCD 让切印生效 → 提示「审判」，让这发审判带上智慧圣印效果（回蓝）
    --     ③ 审判提示发出即收尾：自动取消 FH_CRZHSY 勾选并同步界面
    --   ★ 为什么用审判而不是别的：本服圣印的收益由审判一次性释放
    --     （智慧审判 = 按伤害回蓝），所以「切成智慧圣印 → 打一发审判」就是这套插入的全部价值。
    --   ★ 阶段变量独立（WisdomSealPhase/At），光明与智慧各有自己的 phase，
    --     不会出现「切了智慧却按光明 phase=1 去打审判」串味。
    --   ★ 让位逻辑放在同一个 if/elseif 里：主调度只需判断任一 insertSealRunning 为真即让出审判，
    --     无需在候选表那段再加一个变量。
    local insertSealRunning = (PigSet and PigSet.FH_CRGMSY) or (PigSet and PigSet.FH_CRZHSY)
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
                if WR_PaladinForever_Ready("审判", wjudgeCD) then
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
                    if WR_PaladinForever_Ready("审判", wjudgeCD) then
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
    -- 3. 常驻圣印（愤怒圣印 / 正义圣印，由 FH_ZYSY 决定）
    -- ------------------------------------------------------------
    -- ★★ 2026-11-09 第四次修正：本服圣印是 30 秒短 Buff（截图「剩余25秒」），
    --   而 AHK 是「色块常亮就一直按」（扫描30ms + 冷却33~44ms ≈ 每60ms一次，
    --   3 秒保持 = 约 50 次 /cast 圣印）。所以补印必须做成
    --   「一个 Buff 周期最多亮一次色块」，而不是靠 1/8 秒防抖反复重试：
    --     · SealNeedsRefresh：任意圣印在身上 / 30 秒内成功上过印 → 一律不补；
    --       硬锁走完（33 秒）且光环仍读不到 → 允许补一次。
    --     · CanPrompt(mainSeal, 3)：刚亮过色块 3 秒内不再亮（AHK 漏按可较快重试）。
    --     · HideSkillLater 对圣印统一 0.3 秒 + 成功施放事件立即 HideNow。
    --   「何时能亮」仍由 CanApplySeal（战斗中 + 近战可攻击）决定，脱战绝不点亮。
    -- ============================================================
    local sealAllowed = WR_PaladinForever_SealNeedsRefresh(mainSeal)
    if sealAllowed then
        WR_PaladinForever_SealMissingSince = WR_PaladinForever_SealMissingSince or GetTime()
    else
        WR_PaladinForever_SealMissingSince = nil
    end
    -- 进战标记只在确实读到圣印时清；否则保留到补印成功（脱战由事件清）
    if WR_PaladinForever_ForceSealAtCombat and WR_PaladinForever_BaseSealUp() then
        WR_PaladinForever_ForceSealAtCombat = false
    end
    -- 1 秒缺印确认 + 3 秒重试闩锁。
    --   ★ 2026-11-09 第十一次修正：10 秒太长——AHK 偶尔漏读一次色块，就要再等
    --   10 秒才重试，玩家感知就是「战斗中一直没挂圣印」。3 秒重试足够快；
    --   一旦真的上印成功，SealNeedsRefresh 的 30 秒硬锁会立即阻止再次点亮，
    --   不会因重试变快而反复上印。
    local sealDue = sealAllowed
        and (GetTime() - (WR_PaladinForever_SealMissingSince or GetTime())) >= 1
        and WR_PaladinForever_CanPrompt(mainSeal, 3)
    if sealDue and WR_PaladinForever_CanApplySeal() then
        local sealKnown = WR_SpellUsable(mainSeal)
        if not sealKnown then
            sealKnown = WR_PaladinForever_SpellKnown(mainSeal)
        end
        if sealKnown then
            if WR_PaladinForever_ShowSealBlock(mainSeal, mainSealSlot) then
                WR_PaladinForever_ForceSealAtCombat = false
                WR_PaladinForever_MarkPrompt(mainSeal, mainSealSlot)
                WR_PaladinForever_MarkPrompt("切回常驻圣印", mainSealSlot)
                WR_PaladinForever_HideSkillLater(mainSeal, mainSealSlot, 0.3)
                return true
            end
        end
    end

    -- 4. 自动攻击（仅开怪前提示；战斗中视为已激活，不抢占技能）
    --    ★ 排在常驻圣印之后：脱战缺印时先补印，别让「攻击」把补印挤掉。
    --    ★★ 补印色块的保持窗口内也不能提示「攻击」：WR_ColorFrame_Show 每次会先
    --      隐藏所有颜色框架，否则刚亮起的圣印色块 0.1 秒后就被攻击色块覆盖，
    --      AHK 读到的永远是 /STARTATTACK 而不是 SHIFT-F7 / CTRL-NUMPAD1，
    --      这正是「所有圣印都不打」在真机上的最后一环。
    local sealHoldUntil = WR_PaladinForever_PromptHold
        and WR_PaladinForever_PromptHold[tostring(mainSeal)]
    local sealPromptActive = sealHoldUntil and GetTime() < sealHoldUntil
    if (not sealPromptActive)
       and not PlayerMove and UnitCanAttack("player", "target") and not UnitIsDead("target")
       and not WR_PaladinForever_AutoAttackActive() and WR_SpellUsable("攻击") then
        if WR_ColorFrame_ShowSkill("攻击", 15) then
            WR_PaladinForever_MarkPrompt("攻击", 15)
            WR_PaladinForever_HideSkillLater("攻击", 15, 1.0)
            return true
        end
    end

    -- 4.5 神圣打击的独立分支已并入第 6 步调度（避免固定优先级让审判挨饿）

    -- 5. 战斗门（圣印在门之前处理，避免目标未进战斗时补不了印）
    if not (UnitAffectingCombat("player") and TargetInCombat) then return false end

    -- 6. 主循环调度：「谁 CD 好了先打谁」
    --   · 审判：基础 CD 10 秒，点「强化审判」2/2 后为 8 秒（运行时探测，见 GetJudgeCooldown）；
    --     审判要求身上有任意圣印，但不该被「当前常驻圣印的本地计时」卡死。
    --     2026-11-09 修复：门控由 ProtSealUp() 改为「真实圣印状态 + 任意圣印 Buff」，
    --     避免开怪前上的圣印因 30 秒记录过期而被误判缺印、第一轮永远不打审判。
    --   · 神圣打击：本服 CD 10 秒；所有圣骑士 6 级学会的核心填充/仇恨。
    --   两个技能都就绪时按 FreeAt 排序：谁上一次施放后先轮到、就谁先打，
    --   只有一个就绪就只打那个，不再让固定优先级互相挨饿。
    --   面板「自动神圣打击」开关 FH_HS 关闭时退化为只按审判。
    --
    --   ★★ 2026-11-08 修复「十字军审判挂不上」：
    --     勾选「单体」时，起手流程（第 14.5 段）需要用审判把「十字军审判」debuff 打出去。
    --     但主调度原来无条件把审判放进候选 → 审判 CD 被主调度先消耗掉，
    --     轮到起手要打审判挂 debuff 时审判还在 CD，表现为「十字军审判没有审判的 CD」。
    --     现在：单体流程未完成（phase < 3）期间，主调度【不占用审判】，
    --     把审判 CD 完整留给起手那一次；phase 到达 3 后恢复正常调度。
    local singleTargetRunning = (PigSet and PigSet.FH_DT)
                               and ((WR_PaladinForever_SinglePhase or 0) < 3)
    -- ★★ 2026-11-09 修复「插入光明圣印永远不触发」：
    --   第 14 段（插入光明圣印）在函数末尾，而本段主调度在它之前。
    --   主调度只要看到审判就绪就立刻打掉 → 审判进入 CD → 第 14 段的
    --   Ready("审判") 永远是 false，整条流程永远等不到「审判可用」。
    --   现在：勾选「插入」期间主调度【让出审判】，把审判留给插入流程使用
    --   （插入流程会先切光明圣印、再打审判，打完自动取消勾选，10 秒上限）。
    --   insertSealRunning：光明 / 智慧两条插入流程共用同一个「让出审判」判断，
    --   否则任一流程勾选期间，主调度都会把它要用的那发审判先打掉。
    --   ★ 2026-11-10：光明插入只在「还没提示审判」前（phase 0/1）让出；
    --     一旦审判已提示（phase 2/3 只等目标 debuff / 切回常驻圣印），就交还审判调度。
    local lightWaitingJudge = (PigSet and PigSet.FH_CRGMSY)
        and ((WR_PaladinForever_LightSealPhase or 0) < 2)
    local insertSealRunning = (PigSet and PigSet.FH_CRZHSY) or lightWaitingJudge
    local judgeCD = WR_PaladinForever_GetJudgeCooldown()
    local candidates = {}
    if (not singleTargetRunning)
       and (not insertSealRunning)
       and (sealState ~= "missing" or WR_PaladinForever_SealActive())
       and WR_SpellUsable("审判") then
        candidates["审判"] = judgeCD
    end
    local hsRangeOK = (TargetRange == nil or TargetRange >= 999 or TargetRange <= 8)
    if hsRangeOK
       and (PigSet.FH_HS ~= false)
       and WR_SpellUsable("神圣打击") then
        candidates["神圣打击"] = WR_PaladinForever_SkillCD["神圣打击"]
    end
    -- ★ 2026-11-09：起手 3 秒内优先审判（如果审判本身就绪）。
    --   只在这一小段窗口强行置顶，之后仍按「谁 CD 先好谁先打」调度，
    --   避免固定优先级让神圣打击挨饿。若审判被防抖/CD 挡住，本 tick 仍会落到下方调度。
    local freshCombat = WR_PaladinForever_CombatStartAt
                        and (GetTime() - WR_PaladinForever_CombatStartAt) <= 3
    if freshCombat and candidates["审判"] then
        if WR_PaladinForever_ShowSkillCD("审判", 2, judgeCD) then
            return true
        end
    end
    local scheduled = WR_PaladinForever_PickMostReady(candidates)
    if scheduled then
        local slot = (scheduled == "审判") and 2 or 74
        if WR_PaladinForever_ShowSkillCD(scheduled, slot, candidates[scheduled]) then
            return true
        end
    end

    -- 8. 神圣之盾（若已学会；防护核心减伤）
    --   ★ 受面板「神圣之盾」开关 FH_SZS 控制（默认 true = 保持原有行为）
    --   ★ 修复「CD 没好也亮色块」：原写法 CanPrompt(8) + Talent() 有两个问题：
    --     ① Talent() 只判「已学会」，完全不查冷却；而 WR_SpellUsable 对带 CD 技能恒 true
    --        （无限战斗中 GetSpellCooldown 是 secret）→ 等于没有冷却门；
    --     ② 8 秒的防抖窗口小于本服真实 CD 10 秒（截图实测 Rank1 / SpellID 20925 / 10 秒）
    --        → 第 8 秒就重新亮块，此时还剩 2 秒 CD。
    --   现改为统一走 ShowSkillCD（本地按「成功施放时刻 + CD」判定），CD 取 10 秒。
    if (PigSet == nil or PigSet.FH_SZS ~= false)
       and WR_PaladinForever_SpellKnown("神圣之盾")
       and WR_PaladinForever_ShowSkillCD("神圣之盾", 24, 10) then
        return true
    end

    -- 9. 驱邪术（亡灵/恶魔，30 码内；本地 15 秒 CD）
    if WR_PaladinForever_IsUndeadOrDemon("target")
       and TargetRange ~= nil and TargetRange <= 30
       and WR_SpellUsable("驱邪术", true) then
        if WR_PaladinForever_ShowSkillCD("驱邪术", 20, 15) then return true end
    end

    -- 10. 奉献（受面板「自动 奉献」开关 FH_FX 控制；仅目标数量 >2、蓝量 >55%、近战 5 码内）
    if (PigSet.FH_FX ~= false)
       and UnitCount8 >= 3
       and PlayerMP > 0.55
       and TargetRange ~= nil and TargetRange <= 5
       and WR_SpellUsable("奉献", true) then
        if WR_PaladinForever_ShowSkillCD("奉献", 5, 8) then return true end
    end

    -- 11. 制裁之锤（打断危险施法；冷却 60 秒）
    if WR_PaladinForever_TargetCasting() and WR_SpellUsable("制裁之锤", true) then
        if WR_PaladinForever_ShowSkillCD("制裁之锤", 22, 60) then return true end
    end

    -- 12. 愤怒之锤（<20% 斩杀；本地 6 秒 CD）
    if WR_SafeHPPct("target") < 0.20 and WR_SpellUsable("愤怒之锤", true) then
        if WR_PaladinForever_ShowSkillCD("愤怒之锤", 1, 6) then return true end
    end

    -- 13. 无限天赋（已学会才提示，带本地 CD）
    --   ★ 2026-11-08：迅捷审判原用色块 117，而 117 是旧版跟随系统的「焦点跟随」槽位
    --     （AHK 按 ALT-- 执行 /follow focus）→ 点亮它就等于让 AHK 跟随焦点。
    --     已改为只弹文字提示（PigAlert），不再占用色块槽位，避免与跟随键位撞车。
    if WR_PaladinForever_CanPrompt("圣殿壁垒", 60)
       and WR_PaladinForever_Talent("圣殿壁垒", 118) then
        WR_PaladinForever_MarkPrompt("圣殿壁垒")
        return true
    end
    if WR_PaladinForever_CanPrompt("迅捷审判", 60)
       and WR_PaladinForever_SpellKnown("迅捷审判") then
        -- 只文字提示，不点亮色块（117 与 /follow focus 撞车）
        PigAlert("可施放 迅捷审判", 1, 0.8, 0, 1.2)
        WR_PaladinForever_MarkPrompt("迅捷审判")
        return true
    end


    return false
end
