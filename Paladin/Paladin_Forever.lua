-- ============================================================
-- Paladin_Forever.lua  《魔兽世界：无限》(Forever) 圣骑士完整循环
-- ------------------------------------------------------------
-- 设计：完全不依赖 COMBAT_LOG_EVENT_UNFILTERED（无限已禁用）。
--   所有判定走安全 helper（与 Hunter_Forever.lua 同一套契约）：
--     WR_SpellUsable        —— 冷却 + IsUsableSpell（已含 WR_Forever_SkillAbsent 闸门）
--     WR_GetUnitBuffTime    —— 自身 BUFF 剩余
--     WR_GetUnitDebuffTime  —— 目标 DEBUFF 剩余
--     WR_GetUnitHP          —— 单位血量百分比
--     WR_SafeHPPct          —— 目标血量百分比（secret 安全）
--     WR_GetGCD / WR_UnitRange / WR_PlayerMove / WR_GetRangeHarmUnitCount
--     WR_Forever_IsSpellKnown —— 天赋技能是否已学会（IsPlayerSpell 兼容无限天赋）
--
-- ★ 与 SoD 版的关键区别：
--   SoD 版每个核心技能都卡 WR_SoD_HasRune("PALADIN", ...) 符文判定，
--   而无限没有符文系统 → 这些分支全部跳过 → 循环几乎不出技能。
--   本文件**移除全部符文门**，改为按「技能是否可用 / 已学会」直接门控，
--   无限里真实存在的经典/TBC 技能（审判/十字军圣印/正义圣印/驱邪术/奉献/
--   神圣震击/制裁之锤/愤怒之锤/圣盾术/清洁术/各祝福/虔诚光环…）以及无限
--   天赋（神恩术/真理之声/光之守夜/迅捷审判/圣殿壁垒/命令圣印…）按"已学会才提示"接入。
--   未学会/无限不存在的技能由 WR_SpellUsable 闸门自动跳过，绝不报错。
--
-- 输出：WR_ColorFrame_ShowSkill(法术名, 槽位) —— 外部 AHK 读屏色按键施法
--   槽位优先取自 Paladin_Macros.lua 的 WR_SkillColor["PALADIN"]（已为本文件新增技能补全）。
-- ============================================================

-- ★ 防御式职业守卫：WR_PlayerClass 尚未初始化时不提前 return，保证函数一定被定义
if WR_PlayerClass and WR_PlayerClass ~= "PALADIN" then return end

-- ============================================================
-- ★ 统一入口：按专精分派；非 Forever 客户端回退到旧 SoD 三函数
-- ============================================================

function WR_PaladinForeverRotation()
    local spec = WR_GetMyTalent()
    local isForever = WR_Forever_ClientInfo().isForever

    if not isForever then
        -- SoD / 经典客户端：沿用既有实现（它们本身也是 CLEU-free）
        if spec == "神圣" then
            WR_RunHealerWithFleshPriority(WR_PaladinHoly)
        elseif spec == "防护" then
            WR_PaladinProtection()
        elseif spec == "惩戒" then
            WR_PaladinRetribution()
        end
        return
    end

    -- Forever 路径
    if spec == "神圣" then
        WR_RunHealerWithFleshPriority(WR_PaladinForeverHoly)
    elseif spec == "防护" then
        WR_PaladinForeverProt()
    elseif spec == "惩戒" then
        WR_PaladinForeverRet()
    end
end
-- ============================================================
-- ★ 自动攻击是否已在进行（无限 1.60.x 没有全局 IsCurrentSpell）
--   优先用 IsCurrentSpell（若客户端/兼容层提供），否则战斗中视为已在自动攻击，
--   避免「自动攻击」分支每 tick 抢占后续技能循环；非战斗返回 false 保留开怪提示。
function WR_PaladinForever_AutoAttackActive()
    if type(IsCurrentSpell) == "function" then
        local ok, v = pcall(IsCurrentSpell, "攻击")
        if ok and v == true then return true end
    end
    local okC, inC = pcall(UnitAffectingCombat, "player")
    if okC and inC == true then return true end
    return false
end

-- ★★ 2026-11-10 用户口径：「战斗中加入自动平砍」
-- ------------------------------------------------------------
-- 旧行为（也是旧 bug 的来源）：
--   WR_PaladinForever_AutoAttackActive() 在战斗中恒返回 true —— 无限 1.60.x
--   读不到真实的「自动攻击进行中」状态，兼容层只能按 UnitAffectingCombat 兜底。
--   于是循环里唯一的「攻击」提示（Prot 第 4 段）只在脱战出现。
--   平砍一旦在战斗中停下（切目标 / 目标死亡后换目标 / /startattack 被打断 /
--   被控制后恢复），插件再也不会提示，玩家白丢整场平砍输出。
--
-- 现在改为「事件优先 + 限频兜底」：
--   · PLAYER_ENTER_COMBAT / PLAYER_LEAVE_COMBAT 可用时按真实事件维护状态，
--     一收到 ENTER 就立刻停止提示（真实状态优先，不浪费色块）；
--   · 事件不可用（无限可能不派发这两个事件）时，退化为「每 2 秒最多提示一次」——
--     一次 /startattack 就能重开平砍，重复按无害，2 秒限频保证不会饿死技能循环；
--   · 提示位置放在【所有技能环节之后】，所以即使状态判不准也绝不会抢占技能优先级。
--   为什么用「固定 2 秒限频 + 事件优先停止」而不是「状态常亮」：
--     · 色块常亮 = AHK 每 ~60ms 按一次 /startattack，虽然无 GCD 无害，但会长期
--       占着色块；一旦将来有人把它挪到技能之前，就会立刻复现「某环节饿死全循环」。
--     · 固定 2 秒限频 + 1.5 秒保持 = 亮 1.5 秒、暗 0.5 秒，永远不会常亮；
--       而一次 /startattack 就足以把平砍接上，2 秒内必然恢复。
--     · 事件可用时（PLAYER_ENTER_COMBAT）会立刻停止提示，比限频更快。
WR_PaladinForever_AUTOATTACK_RETRY = 2.0   -- 战斗中平砍重开提示的最小间隔（秒）
WR_PaladinForever_AutoAttackOn = false     -- 事件维护的「平砍是否在跑」
WR_PaladinForever_AutoAttackEventKnown = false  -- 是否收到过任何 enter/leave 事件

function WR_PaladinForever_AutoAttackNeedsRestart()
    -- 明确知道平砍在跑（收到 PLAYER_ENTER_COMBAT）→ 不需要重开
    if WR_PaladinForever_AutoAttackOn then return false end
    -- 其余情况统一走限频，避免色块常亮被 AHK 连按
    return WR_PaladinForever_CanPrompt("攻击", WR_PaladinForever_AUTOATTACK_RETRY or 2.0)
end

-- ★ 本地技能冷却计时（无限 12.x 战斗中 GetSpellCooldown 是 secret，
--   WR_GetGCD 会被收敛成 0 → WR_SpellUsable 恒 true → 色块一直卡在第一个技能）。
--   本地记账分两张表：
--     · PromptCD / PromptSlot —— 只做「提示防抖」，避免同一技能每 tick 连闪；
--     · SkillCastAt / FreeAt  —— 真正的冷却判定，起点是「成功施放时刻」。
WR_PaladinForever_PromptCD = WR_PaladinForever_PromptCD or {}
-- ★ 记录每个提示实际使用的颜色槽位（不依赖 WR_SoD_ResolveSlot 的运行时反查）
WR_PaladinForever_PromptSlot = WR_PaladinForever_PromptSlot or {}

function WR_PaladinForever_CanPrompt(key, cd)
    if not cd or cd <= 0 then return true end
    local last = WR_PaladinForever_PromptCD[key]
    if last and (GetTime() - last) < cd then return false end
    return true
end

function WR_PaladinForever_MarkPrompt(key, slot)
    WR_PaladinForever_PromptCD[key] = GetTime()
    if slot then WR_PaladinForever_PromptSlot[key] = slot end
end

-- ★ 取某技能最近一次成功施放时刻（按名 + 按全部 rank ID 两条通道取较晚者）
function WR_PaladinForever_GetLastCastAt(spell)
    local best = WR_PaladinForever_SkillCastAt[spell]
    local ids = WR_PaladinForever_SpellRankIDs and WR_PaladinForever_SpellRankIDs[spell]
    if ids then
        for i = 1, #ids do
            local t = WR_PaladinForever_SkillCastAtByID[ids[i]]
            if t and (not best or t > best) then best = t end
        end
    end
    return best
end

-- ★ 记录某技能成功施放（名字 + 所有关联 rank ID 一起写，双通道冗余）
function WR_PaladinForever_MarkCastAt(spell, t)
    if not spell then return end
    local at = t or GetTime()
    WR_PaladinForever_SkillCastAt[spell] = at
    local ids = WR_PaladinForever_SpellRankIDs and WR_PaladinForever_SpellRankIDs[spell]
    if ids then
        for i = 1, #ids do
            WR_PaladinForever_SkillCastAtByID[ids[i]] = at
        end
    end
end

-- ★ 提示防抖窗口（秒）：只防同一技能同一瞬间连刷。
WR_PaladinForever_PROMPT_DEBOUNCE = 0.45

-- ★ 「本轮已亮过」标记（技能名 → true）。
--   用途：区分「CD 刚好的第一帧」（立刻亮，不等 GCD）与「本轮重试」（必须等 GCD 结束）。
--   清空时机：该技能成功施放 / CD 判定回到未就绪 / 保持到期。
WR_PaladinForever_PromptShown = WR_PaladinForever_PromptShown or {}

function WR_PaladinForever_ClearPromptShown(spell)
    if WR_PaladinForever_PromptShown then
        WR_PaladinForever_PromptShown[tostring(spell)] = nil
    end
end

-- ★ 客户端剩余冷却（脱战 / 非 secret 时可读；战斗中返回 nil）
--   用途：作为本地记账的交叉校验。若本地完全没有记录（事件被 secret 挡住），
--   但客户端明确说「还在 CD 中」，就直接判为未就绪，避免退化成「每 1.1 秒亮一次」。
function WR_PaladinForever_ClientCooldownLeft(spell)
    if type(WR_SpellCooldownInfo) ~= "function" then return nil end
    -- ★★ 2026-11-10：优先查「当前 rank」的 ID（WR_ResolveSpellID 已能从法术书基础名解析），
    --   旧写法固定取 ids[#ids]（最高 rank），角色未满级时查的是没学会的 rank，结果不可靠。
    local sid
    if type(WR_ResolveSpellID) == "function" then
        sid = WR_ResolveSpellID(spell)
    end
    if not sid then
        local ids = WR_PaladinForever_SpellRankIDs and WR_PaladinForever_SpellRankIDs[spell]
        if ids and #ids > 0 then
            sid = ids[#ids] -- 兜底：取最高 rank ID 作为查询代表
        end
    end
    if not sid then return nil end
    local ok, start, dur = pcall(WR_SpellCooldownInfo, sid)
    if not ok then return nil end
    if type(start) ~= "number" or type(dur) ~= "number" or dur <= 0 then return nil end
    if type(WR_IsSecretValue) == "function"
       and (WR_IsSecretValue(start) or WR_IsSecretValue(dur)) then
        return nil
    end
    local left = (start + dur) - GetTime()
    if left > 0 then return left end
    return 0
end

-- ★ 色块保持时长（秒）：亮到打出为止的上限。
--   · 普通循环技能 1.5 秒：覆盖 AHK 读屏 + 按键；打出后由施放成功事件立即清除。
--   · 长 Buff 类（圣印/正义之怒/祝福）沿用各自传入的较长时长。
WR_PaladinForever_PROMPT_HOLD = 1.5
-- ★★ 圣印色块专用保持上限（秒）。AHK 是「同色常亮就一直按」：扫描 30ms +
--   随机冷却 33~44ms ⇒ 约 60ms 一次。保持太久会被连按放大成反复施放；
--   保持太短（<0.1s）则 AHK 可能一次都没读到 → 漏按 → 表现为「战斗中又没挂圣印」。
--   ★ 2026-11-09 第十一次修正：0.2 秒名义保持其实只够 1 个游戏帧——主循环下一 tick
--     的「神圣打击」等提示会调用 WR_ColorFrame_Show，而它会先隐藏所有色块，把刚亮
--     的圣印顶掉；AHK 直接漏按。现在改为 0.3 秒，并且在这 0.3 秒内由
--     WR_PaladinForever_RefreshSealPrompt 每 tick 重亮圣印色块、阻止其他提示覆盖；
--     一旦收到圣印施放成功事件立即 HideNow 提前结束窗口。实际可见 3 个 tick 左右，
--     足够 AHK 扫到 1~2 次；成功即灭，不会回到 3 秒连按 50 次的老问题。
WR_PaladinForever_SEAL_PROMPT_HOLD = 0.3

-- 带本地冷却的技能提示（三层判定 + 两段式重试）：
--   ① 有成功施放记录 → 按「施放时刻 + CD」判定（最准）；
--   ② 无记录但客户端剩余冷却可读 → 直接按客户端判定；
--   ③ 两者都没有 → 短 CD 循环技能只按「提示保持窗口」防连刷，不能按完整 CD 屏蔽。
--      提示 ≠ 施放：若按完整 CD 屏蔽，AHK 漏看/按键被 GCD 吞一次就会整段 CD
--      不再提示，表现为「CD 好了也不打」。长 CD 技能仍按完整 CD 防刷屏。
--
-- ★ 两段式（解决「CD 好了没第一时间亮」）：
--   · 首次提示：CD 一好就立刻亮，**不等 GCD** —— 保证玩家第一时间看到色块；
--   · 重试提示：必须等 GCD 结束才重亮 —— 避免连续白亮（按键被 GCD 吞）。
--   原来只有一段（防抖 1.1 秒 + 保持 1 秒），首亮被吞后要干等 2 秒多才重亮。
function WR_PaladinForever_ShowSkillCD(spell, slot, cd)
    local now = GetTime()
    local lastPrompt = WR_PaladinForever_PromptCD[spell]
    local prompted = WR_PaladinForever_PromptShown and WR_PaladinForever_PromptShown[spell]

    if cd and cd > 0 then
        local castAt = WR_PaladinForever_GetLastCastAt(spell)
        if castAt then
            -- ① 施放记录通道
            if (now - castAt) < cd then
                WR_PaladinForever_ClearPromptShown(spell)
                return false
            end
        else
            -- ② 客户端冷却通道
            local clientLeft = WR_PaladinForever_ClientCooldownLeft(spell)
            if clientLeft and clientLeft > 0 then
                WR_PaladinForever_ClearPromptShown(spell)
                return false
            end
            -- ③ 保守兜底：
            --    · 短 CD 循环技能（<=15 秒）只按提示保持窗口防连刷 ——
            --      提示≠施放，漏看一次不能整段 CD 不再提示；
            --    · 中长 CD 技能：按「有限次重试」而不是完整 CD 屏蔽。
            --   ★★ 2026-11-10 修复「一次漏按锁死整个 CD」：
            --     旧写法长 CD 一律 guard = cd，而 圣疗术 传 1200 秒、圣佑术 传 300 秒。
            --     一旦「施放成功事件」没记上账（战斗中 spellName 可能是 secret）且客户端
            --     冷却也不可读（同为 secret），第一次点亮后 20 分钟 / 5 分钟内不再提示，
            --     即使玩家完全没按 —— 表现为「圣疗术再也没亮过」。
            --     现在：<=15 秒按保持窗口重试；<=300 秒最多每 20 秒重试一次；
            --     更长的（真正的长 CD 大招）才沿用完整 CD 防刷屏。
            local guard = cd
            if cd <= 15 then
                guard = WR_PaladinForever_PROMPT_HOLD or 1.5
            elseif cd <= 300 then
                guard = math.min(cd, 20)
            end
            if lastPrompt and (now - lastPrompt) < guard then return false end
        end
    end

    if lastPrompt then
        local since = now - lastPrompt
        if prompted then
            -- 本轮已经亮过：属于「重试」，要求 GCD 已结束 + 最小间隔
            if since < WR_PaladinForever_PROMPT_DEBOUNCE then return false end
            if not WR_PaladinForever_NotOnGCD() then return false end
        else
            -- 未亮过（新一轮 CD 刚好的第一帧）：立刻亮，不等 GCD
            if since < WR_PaladinForever_PROMPT_DEBOUNCE then return false end
        end
    end

    if WR_ColorFrame_ShowSkill(spell, slot) then
        WR_PaladinForever_PromptCD[spell] = now
        WR_PaladinForever_PromptSlot[spell] = slot
        -- 标记「本轮已亮过」：后续同一轮的提示属于重试，要等 GCD
        WR_PaladinForever_PromptShown = WR_PaladinForever_PromptShown or {}
        WR_PaladinForever_PromptShown[tostring(spell)] = true
        WR_PaladinForever_HideSkillLater(spell, slot, WR_PaladinForever_PROMPT_HOLD)
        return true
    end
    return false
end

-- ============================================================
-- ★「谁 CD 好了先打谁」调度（Ready-first）
-- ------------------------------------------------------------
-- 背景：无限战斗中 GetSpellCooldown 是 secret、WR_GetGCD 收敛成 0，
--   WR_SpellUsable 对带 CD 技能恒 true，所以「谁就绪」只能靠本地记账。
-- 做法：用 UNIT_SPELLCAST_SUCCEEDED 的成功施放时间做唯一起点，
--   每个技能维护 FreeAt = 施放时刻 + 本技能 CD（即「自然冷却结束点」）。
--   同一 tick 多个技能都就绪时，挑 FreeAt 最早的先打 —— 这就是
--   「谁 CD 好了先打谁」，而不是固定优先级死板排队。
-- ============================================================

-- ★ 各技能本地冷却（秒）。审判会被「强化审判」天赋缩短，改用 GetJudgeCooldown 探测。
WR_PaladinForever_SkillCD = {
    -- ★★ 2026-11-11：本服神圣打击实际为 6 秒 CD（等级5 / SpellID 2495 截图实测），
    --   旧值误写 10 秒 → 每次施放后本地多锁 4 秒，6~10 秒这段已经转好却不亮，
    --   表现就是「CD 好了没有第一时间打出」。
    ["神圣打击"] = 6,
    ["审判"]     = 10, -- 基础 10 秒；强化审判 2/2 后 8 秒（见 GetJudgeCooldown）
}

-- 技能名 → 最近一次成功施放时间
WR_PaladinForever_SkillCastAt = WR_PaladinForever_SkillCastAt or {}
-- ★ spellID → 最近一次成功施放时间。
--   无限战斗中 UNIT_SPELLCAST_SUCCEEDED 的 spellName 可能是 secret 字符串（读不到），
--   只按名字记账会导致冷却表恒空 → CD 判定失效 → 色块每 1.1 秒亮一次（「CD 中还在一直打」）。
--   故同时按数字 spellID 记账，作为主通道；名字通道仅作补充。
WR_PaladinForever_SkillCastAtByID = WR_PaladinForever_SkillCastAtByID or {}
-- ★ 每个技能在无限里的全部 rank spellID（施放时上报的是「当前 rank」的 ID）
WR_PaladinForever_SpellRankIDs = {
    -- ★★ 2026-11-10：补齐神圣打击全部 8 个 rank（ForeverDB build 1.60.1.70862）：
    --   678=R1(6级) / 679=R2(12级) / 1866=R3(20级) / 680=R4(28级) /
    --   2495=R5(36级) / 5569=R6(44级) / 10332=R7(52级) / 10333=R8(60级)
    --   旧表缺 680/2495/5569：角色升到 28 级后当前 rank 不在表里，
    --   写死的 1866（R3）又不是当前 rank → 施放事件按 ID 认不出、WR_SpellUsable 判不可用，
    --   表现就是「神圣打击 CD 好了也不打」。
    ["神圣打击"] = { 678, 679, 1866, 680, 2495, 5569, 10332, 10333 },
    ["审判"]     = { 20271 },
    ["愤怒圣印"] = { 1311656, 20423 },
    ["正义之怒"] = { 25780 },
    -- ★ 2026-11-08：截图实测 神圣之盾 Rank1 = 20925（CD 10 秒）
    ["神圣之盾"] = { 20925 },
}
-- 技能名 → 下一次自然冷却结束时间（Ready-first 的排序依据）
WR_PaladinForever_FreeAt = WR_PaladinForever_FreeAt or {}
-- ★ 公共冷却判定
--   ★ 取舍（用户明确要求「CD 好了要第一时间亮」）：
--     · 卡 GCD：提示要等到 GCD 结束才亮，实测比不卡晚 0.35~1.2 秒；
--     · 不卡 GCD：CD 好了立刻亮，若此刻 GCD 未结束，这次按键被客户端拒绝，
--       但色块会保持 1.5 秒且防抖仅 0.45 秒 → 0.45 秒后立刻重亮，玩家再按即可成功。
--   取「不卡 GCD」：CD 好了立刻可见是硬要求，白按一次由快速重试兜住。
--   ★ 2026-11-09：重试判定的 GCD 窗口按圣骑士 1.5 秒公共冷却计算（原 1.2 秒会早 0.3 秒，
--     重试按键仍可能被 GCD 吞掉，表现为「亮了但没打出去」）。
WR_PaladinForever_GCD_WINDOW = WR_PaladinForever_GCD_WINDOW or 1.5

-- ★ 公共冷却是否结束（仅用于 Ready-first 排序的次级比较，不作提示前置门）
function WR_PaladinForever_NotOnGCD()
    local lastCast = WR_Forever_LastPlayerCast and WR_Forever_LastPlayerCast.time
    if type(lastCast) ~= "number" or lastCast <= 0 then return true end
    return (GetTime() - lastCast) >= (WR_PaladinForever_GCD_WINDOW or 1.5)
end

-- ★ 刷新某技能的 FreeAt（施放成功后调用）
function WR_PaladinForever_TouchCooldown(spell, cdSeconds)
    if not spell then return end
    local now = GetTime()
    local cd = tonumber(cdSeconds) or 0
    local castAt = WR_PaladinForever_GetLastCastAt(spell) or now
    local freeAt = castAt + cd
    if freeAt < now then freeAt = now end
    local old = WR_PaladinForever_FreeAt[spell]
    -- 取较大值：保证先后关系单调推进，不会被后来的技能挤到更早
    if not old or freeAt >= old then
        WR_PaladinForever_FreeAt[spell] = freeAt
    end
end

-- ★ 技能是否就绪（只看本地 CD，不看 GCD）
--   ★ CD 好了必须立刻可亮：把 GCD 放进就绪判定会让提示硬等 GCD 结束，
--     玩家感受到的就是「CD 好了没第一时间打」。GCD 只影响本次按键是否被拒，
--     由 0.45 秒防抖 + 1.5 秒色块保持兜住（被吞会很快重亮）。
function WR_PaladinForever_Ready(spell, cd)
    local castAt = WR_PaladinForever_GetLastCastAt(spell)
    if castAt and cd and (castAt + cd) > GetTime() then return false end
    return true
end

-- ★ 从候选里挑出「CD 最先好」的技能
--   排序键 FreeAt；相同则优先 GCD 已结束的（按键更容易成功）
function WR_PaladinForever_PickMostReady(candidates)
    if type(candidates) ~= "table" then return nil end
    local now = GetTime()
    local gcdReady = WR_PaladinForever_NotOnGCD()
    local best, bestFree, bestGCD = nil, nil, nil
    for spell, cd in pairs(candidates) do
        if WR_PaladinForever_Ready(spell, cd) then
            local freeAt = WR_PaladinForever_FreeAt[spell] or (now - 1.8)
            local better
            if bestFree == nil then
                better = true
            elseif freeAt < bestFree - 0.001 then
                better = true
            elseif freeAt > bestFree + 0.001 then
                better = false
            else
                better = (gcdReady and not bestGCD) or false
            end
            if better then
                best, bestFree, bestGCD = spell, freeAt, gcdReady
            end
        end
    end
    return best
end

-- ★ 审判冷却：本服基础 CD 10 秒；惩戒天赋「强化审判」等级 2/2
--   （被动，天赋 SpellID 25956）使其缩短 2 秒 → 8 秒。
--   因 CD 会随天赋变化，不能写死。探测优先级：
--     ① 天赋是否已点（IsPlayerSpell / IsSpellKnown / C_Traits 查 25956）——最可靠；
--     ② 客户端真实冷却（WR_SpellCooldownInfo；战斗中为 secret 时失败）；
--     ③ 「相邻两次审判成功施放的间隔」自动校准（明显短于基础值 ⇒ 已强化）；
--     ④ 都没有才用 10 秒兜底（只影响本地提前亮块的时机，不影响客户端实际施放）。
WR_PaladinForever_JUDGE_CD_BASE = 10
WR_PaladinForever_JUDGE_CD_TALENT = 8 -- 强化审判 2/2 后
WR_PaladinForever_JUDGE_TALENT_SPELLID = 25956 -- 「强化审判」
WR_PaladinForever_JudgeCD = WR_PaladinForever_JudgeCD or WR_PaladinForever_JUDGE_CD_BASE
-- 天赋探测结果缓存：WR_PaladinForever_JudgeTalentKnown
--   nil = 尚未探测（首次取值时才探） / true = 已点强化审判 / false = 未点
--   ★ 刻意不预置为 false：nil 才代表「需要探测」。
-- 重扫描状态位：扫描中防重入 / 待办（战斗中延后到脱战）
WR_PaladinForever_JudgeScanning = WR_PaladinForever_JudgeScanning or false
WR_PaladinForever_JudgeScanPending = WR_PaladinForever_JudgeScanPending or false

-- ★ 是否已点「强化审判」（结果缓存；天赋切换事件会清空缓存）
--   ★ 性能红线：下面的 C_Traits 全树扫描是**重操作**（逐节点 pcall GetNodeInfo，
--     已点节点还要 GetEntryInfo + GetDefinitionInfo，一次几百个 API 调用）。
--     该函数由 GetJudgeCooldown() 每 tick 调用，且位于战斗门之后 —— 若在战斗 tick 里
--     直接扫，会正好在「进战斗第一帧」执行，表现为进战斗卡一下。
--     故：廉价路径先试；重扫描只在**脱战**时执行，战斗中延后到脱战后补做。
function WR_PaladinForever_ScanJudgeTalent()
    if WR_PaladinForever_JudgeScanning then
        return WR_PaladinForever_JudgeTalentKnown == true
    end
    WR_PaladinForever_JudgeScanning = true

    local sid = WR_PaladinForever_JUDGE_TALENT_SPELLID
    local known = false
    if type(C_ClassTalents) == "table" and type(C_Traits) == "table"
       and type(C_ClassTalents.GetActiveConfigID) == "function"
       and type(C_Traits.GetConfigInfo) == "function"
       and type(C_Traits.GetTreeNodes) == "function"
       and type(C_Traits.GetNodeInfo) == "function" then
        local okCfg, cfgID = pcall(C_ClassTalents.GetActiveConfigID)
        if okCfg and type(cfgID) == "number" then
            local okInfo, cfg = pcall(C_Traits.GetConfigInfo, cfgID)
            local treeID = (okInfo and type(cfg) == "table" and type(cfg.treeIDs) == "table")
                           and cfg.treeIDs[1] or nil
            if treeID then
                local okNodes, nodes = pcall(C_Traits.GetTreeNodes, treeID)
                if okNodes and type(nodes) == "table" then
                    for _, nodeID in ipairs(nodes) do
                        local okNode, info = pcall(C_Traits.GetNodeInfo, cfgID, nodeID)
                        if okNode and type(info) == "table"
                           and (tonumber(info.activeRank) or 0) > 0 then
                            local eids = {}
                            if type(info.entryIDs) == "table" then
                                for _, e in ipairs(info.entryIDs) do eids[#eids + 1] = e end
                            end
                            if type(info.activeEntry) == "table" and info.activeEntry.entryID then
                                eids[#eids + 1] = info.activeEntry.entryID
                            end
                            for _, eID in ipairs(eids) do
                                local okE, ei = pcall(C_Traits.GetEntryInfo, cfgID, eID)
                                local defID = okE and type(ei) == "table" and ei.definitionID or nil
                                if defID and type(C_Traits.GetDefinitionInfo) == "function" then
                                    local okD, di = pcall(C_Traits.GetDefinitionInfo, defID)
                                    if okD and type(di) == "table" then
                                        if tonumber(di.spellID) == sid then
                                            known = true
                                        end
                                        if type(di.name) == "string" and di.name == "强化审判" then
                                            known = true
                                        end
                                    end
                                end
                                if known then break end
                            end
                        end
                        if known then break end
                    end
                end
            end
        end
    end

    WR_PaladinForever_JudgeScanning = false
    WR_PaladinForever_JudgeScanPending = false
    WR_PaladinForever_JudgeTalentKnown = known
    if known then
        WR_PaladinForever_JudgeCD = WR_PaladinForever_JUDGE_CD_TALENT
    end
    return known
end

-- ★ 廉价探测（只调 IsPlayerSpell / IsSpellKnown，单次开销可忽略）
--   命中返回 true；未命中返回 nil（表示「还不确定」，需要重扫描）
function WR_PaladinForever_CheapJudgeTalentProbe()
    local sid = WR_PaladinForever_JUDGE_TALENT_SPELLID
    if type(IsPlayerSpell) == "function" then
        local ok, res = pcall(IsPlayerSpell, sid)
        if ok and res then return true end
    end
    if type(IsSpellKnown) == "function" then
        local ok, res = pcall(IsSpellKnown, sid)
        if ok and res then return true end
    end
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, res = pcall(WR_Forever_IsSpellKnown, sid)
        if ok and res then return true end
        local ok2, res2 = pcall(WR_Forever_IsSpellKnown, "强化审判")
        if ok2 and res2 then return true end
    end
    return nil
end

function WR_PaladinForever_IsJudgeTalentKnown()
    -- 已探测过直接返回缓存（战斗内零开销）
    if WR_PaladinForever_JudgeTalentKnown ~= nil then
        return WR_PaladinForever_JudgeTalentKnown
    end

    -- ★ 战斗内且已标记待办：直接按「未确定」返回，连廉价探测都不做（每 tick 零 API）
    if WR_PaladinForever_JudgeScanPending and UnitAffectingCombat("player") then
        return false
    end

    -- ① 廉价路径：天赋法术直接已学
    if WR_PaladinForever_CheapJudgeTalentProbe() then
        WR_PaladinForever_JudgeTalentKnown = true
        WR_PaladinForever_JudgeScanPending = false
        WR_PaladinForever_JudgeCD = WR_PaladinForever_JUDGE_CD_TALENT
        return true
    end

    -- ② 重扫描：战斗中绝不做，标记待办，脱战后补做
    if UnitAffectingCombat("player") then
        WR_PaladinForever_JudgeScanPending = true
        return false
    end
    return WR_PaladinForever_ScanJudgeTalent()
end

-- ★ 审判 CD 校准：由成功施放事件调用（castTime = 本次审判施放时刻）
function WR_PaladinForever_ProbeJudgeCooldown(castTime)
    local t = tonumber(castTime)
    if not t then return end
    local prev = WR_PaladinForever_JudgeLastCastAt
    WR_PaladinForever_JudgeLastCastAt = t
    if not prev then return end
    local gap = t - prev
    -- 过短（一次按键连打 / 宏重复）或过长（战斗间隔）都不作为校准依据
    if gap <= 0.5 or gap >= (WR_PaladinForever_JUDGE_CD_BASE + 0.5) then return end
    if gap < (WR_PaladinForever_JUDGE_CD_BASE - 1) then
        -- 实测明显短于基础 CD ⇒ 确实点了强化审判（同时修正天赋探测缓存）
        WR_PaladinForever_JudgeCD = WR_PaladinForever_JUDGE_CD_TALENT
        WR_PaladinForever_JudgeTalentKnown = true
    else
        WR_PaladinForever_JudgeCD = WR_PaladinForever_JUDGE_CD_BASE
        WR_PaladinForever_JudgeTalentKnown = false
    end
end

-- ★ 审判 CD 读取：天赋 → 客户端真实值 → 事件校准值 → 10 秒兜底
function WR_PaladinForever_GetJudgeCooldown()
    if WR_PaladinForever_IsJudgeTalentKnown() then
        WR_PaladinForever_JudgeCD = WR_PaladinForever_JUDGE_CD_TALENT
        return WR_PaladinForever_JUDGE_CD_TALENT
    end
    local key
    if type(WR_ResolveSpellID) == "function" then key = WR_ResolveSpellID("审判") end
    if key and type(WR_SpellCooldownInfo) == "function" then
        local ok, start, dur = pcall(WR_SpellCooldownInfo, key)
        if ok and type(dur) == "number" and dur >= 5 and dur <= 11
           and type(start) == "number" and start > 0
           and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(dur)) then
            WR_PaladinForever_JudgeCD = dur
        end
    end
    return WR_PaladinForever_JudgeCD or WR_PaladinForever_JUDGE_CD_BASE
end

-- ★ 隐藏某个技能的可视提示：颜色槽位 + 技能图标框（若当前显示的是该技能）
function WR_PaladinForever_HideSkillVisual(spell, slot)
    if slot then
        if ColorFrameArrayTopLeft and ColorFrameArrayTopLeft[slot] then
            ColorFrameArrayTopLeft[slot]:Hide()
        end
        if ColorFrameArrayTopRight and ColorFrameArrayTopRight[slot] then
            ColorFrameArrayTopRight[slot]:Hide()
        end
    end
    -- 兜底：按颜色框文字匹配（防止槽位 key 类型不一致时找不到）
    if spell and ColorFrameArrayTopLeft then
        for key, frame in pairs(ColorFrameArrayTopLeft) do
            local fs = ColorTextArrayTopLeft and ColorTextArrayTopLeft[key]
            if fs then
                local ok, txt = pcall(fs.GetText, fs)
                if ok and type(txt) == "string" and string.find(txt, spell, 1, true) then
                    frame:Hide()
                end
            end
        end
    end
    if spell and ColorFrameArrayTopRight then
        for key, frame in pairs(ColorFrameArrayTopRight) do
            local fs = ColorTextArrayTopRight and ColorTextArrayTopRight[key]
            if fs then
                local ok, txt = pcall(fs.GetText, fs)
                if ok and type(txt) == "string" and string.find(txt, spell, 1, true) then
                    frame:Hide()
                end
            end
        end
    end
    local iconFrame = WR_SkillIconFrame
    if iconFrame and iconFrame.Text then
        local ok, txt = pcall(iconFrame.Text.GetText, iconFrame.Text)
        if ok and type(txt) == "string" and spell and string.find(txt, spell, 1, true) then
            if iconFrame.Icon then iconFrame.Icon:Hide() end
            iconFrame.Text:Hide()
        end
    end
end

-- ★ 色块保持：显示后不主动定时熄灭，而是由「成功施放」或「下一 tick 重判」来收。
--   原因：旧实现 C_Timer.After(1.0) 强制隐藏，若这 1 秒内 AHK 还没读到/按键被 GCD 拒绝，
--   色块就灭了，玩家看到的是「CD 好了但没第一时间亮」。
--   现在保留 delay 参数仅为兼容调用点；实际隐藏交给 ClearStalePrompts 的宽松上限
--   （默认 3 秒）与「施放成功后立刻清」两条路径。
function WR_PaladinForever_HideSkillLater(spell, slot, delay)
    -- ★ 取 max(delay, PROMPT_HOLD)：传 1.0 的调用点也会被拉到 1.5 秒，
    --   传 3.0 的（圣印/正义之怒）保持 3 秒，各自不被压缩。
    WR_PaladinForever_PromptHold = WR_PaladinForever_PromptHold or {}
    local key = tostring(spell)
    local holdFor = delay or 1.0
    if holdFor < (WR_PaladinForever_PROMPT_HOLD or 1.5) then
        holdFor = WR_PaladinForever_PROMPT_HOLD or 1.5
    end
    -- ★★ 2026-11-09：所有圣印色块（常驻/单体/光明插入/共享）统一短保持。
    --   长保持 + AHK 同色连按 = 反复施放同一圣印（截图「Buff 还剩25秒」）。
    if type(spell) == "string" and string.find(spell, "圣印", 1, true) then
        local cap = WR_PaladinForever_SEAL_PROMPT_HOLD or 0.3
        if holdFor > cap then holdFor = cap end
        -- ★ 记录「刚刚点亮过圣印色块」的时刻：战斗中施放成功事件里 spellName/spellId
        --   都是 secret 认不出时，用它兜底判断「这次事件就是按了圣印」→ 记 30 秒窗口，
        --   避免 30 秒记账断档导致下一 tick 又亮、AHK 反复上印。
        WR_PaladinForever_SealPromptLitAt = GetTime()
        -- ★★ 2026-11-11：同时记住「点亮的是哪条圣印」。只记通用时间不够——
        --   十字军审判/光明/智慧 buff 维持状态机判断「目标圣印是否在身上」时，
        --   光环读不到就只能靠各自专用的 CastAt + LastSealAppliedName 兜底；
        --   只写 LastSealCastAt 会让状态机永远判「不在身上」→ 每一两个 tick
        --   重新点亮同一条圣印色块 → AHK 反复施放同一条圣印。
        WR_PaladinForever_SealPromptLitName = spell
        -- ★★ 2026-11-09 第十一次修正：记录「圣印提示保护窗口」的截止时刻。
        --   窗口内由 WR_PaladinForever_RefreshSealPrompt 每 tick 重亮该色块，
        --   不允许其他技能提示把它顶掉（否则 AHK 读不到 → 战斗中一直不上印）。
        if WR_PaladinForever_ActiveSealPromptName == spell then
            WR_PaladinForever_ActiveSealPromptUntil = GetTime() + holdFor
        end
    end
    WR_PaladinForever_PromptHold[key] = GetTime() + holdFor
end

-- ★ 真正隐藏某技能色块并清掉保持标记（施放成功 / 明确不该亮时调用）
function WR_PaladinForever_HideNow(spell, slot)
    if WR_PaladinForever_PromptHold then
        WR_PaladinForever_PromptHold[tostring(spell)] = nil
    end
    -- ★ 清「本轮已亮过」标记：下一次 CD 好时才能走「首亮」路径（立刻亮，不等 GCD）
    WR_PaladinForever_ClearPromptShown(spell)
    -- ★★ 2026-11-09 第十一次修正：施放成功/明确不该亮时，同时结束「圣印提示保护窗口」。
    if WR_PaladinForever_ActiveSealPromptName
       and (tostring(spell) == tostring(WR_PaladinForever_ActiveSealPromptName)
            or (slot and WR_PaladinForever_ActiveSealPromptSlot
                and slot == WR_PaladinForever_ActiveSealPromptSlot)) then
        WR_PaladinForever_ActiveSealPromptName = nil
        WR_PaladinForever_ActiveSealPromptSlot = nil
        WR_PaladinForever_ActiveSealPromptUntil = nil
        WR_PaladinForever_ActiveSealPromptBypass = nil
    end
    WR_PaladinForever_HideSkillVisual(spell, slot)
end

-- ============================================================
-- ★★ 2026-11-09 第十次修正：圣印色块的【唯一出口】硬闸
-- ------------------------------------------------------------
--   用户最终确认：「就是亮了对应的色块，就是正义圣印」——反复上印的源头就是
--   插件把圣印色块点亮了。此前分散在常驻补印 / 单体起手 / 共享圣印保持 3 处调用
--   WR_ColorFrame_ShowSkill，任何一处漏判都会点亮色块并被 AHK 放大成连按。
--
--   本函数把「点亮圣印色块」收敛为唯一出口：
--     · 默认必须通过 WR_PaladinForever_SealNeedsRefresh（身上有任意圣印 / 30 秒
--       硬锁内一律 false）；
--     · 显式切印（光明 / 十字军审判 / 智慧圣印等流程）由调用方设置
--       WR_PaladinForever_SealSwitchAllowUntil 一次性放行；
--     · 被拦截时立刻强制隐藏该槽位色块，并记录诊断计数，便于 /mkseal 排查。
-- ============================================================
function WR_PaladinForever_ShowSealBlock(skillName, slot)
    if type(skillName) ~= "string" then return false end
    local allow = true
    if type(WR_PaladinForever_SealNeedsRefresh) == "function" then
        allow = WR_PaladinForever_SealNeedsRefresh(skillName)
    end
    local bypassUntil = WR_PaladinForever_SealSwitchAllowUntil
    if type(bypassUntil) == "number" and GetTime() <= bypassUntil then
        allow = true
    end
    if not allow then
        WR_PaladinForever_SealBlockedCount = (WR_PaladinForever_SealBlockedCount or 0) + 1
        WR_PaladinForever_SealBlockedAt = GetTime()
        WR_PaladinForever_SealBlockedName = skillName
        -- 兜底：不管之前是谁点亮/残留，强制按槽位熄灭
        WR_PaladinForever_HideNow(skillName, slot)
        return false
    end
    local shown = WR_ColorFrame_ShowSkill(skillName, slot)
    if shown then
        -- ★★ 2026-11-09 第十一次修正：记录当前「圣印提示保护窗口」。
        --   HideSkillLater 会紧接着补上 Until；窗口内 RefreshSealPrompt 持续重亮，
        --   避免被下一 tick 的其他技能提示瞬间覆盖（AHK 漏按的根因）。
        WR_PaladinForever_ActiveSealPromptName = skillName
        WR_PaladinForever_ActiveSealPromptSlot = slot
        WR_PaladinForever_ActiveSealPromptBypass =
            (type(bypassUntil) == "number" and GetTime() <= bypassUntil) and true or false
        WR_PaladinForever_SealPromptShownCount = (WR_PaladinForever_SealPromptShownCount or 0) + 1
        WR_PaladinForever_SealPromptShownAt = GetTime()
    end
    return shown
end

-- ★★ 2026-11-09 第十一次修正：圣印提示保护窗口。
--   背景：WR_ColorFrame_Show 每次会先隐藏【所有】色块；主循环下一 tick 只要
--   点亮「神圣打击」等任意提示，就会把刚亮起的圣印色块顶掉。0.2 秒的保持在此
--   情况下实际只剩 1 个游戏帧，AHK 扫描不到 → 玩家看到「战斗中又没挂圣印」。
--   现在：圣印色块亮起后的 0.3 秒内，Prot/共享循环每 tick 先调用本函数重亮
--   同一圣印并直接 return true，确保窗口内只有圣印色块、AHK 必能读到；
--   一旦施放成功事件到达，HideNow 会立即清掉保护窗口，不会连按 50 次。
function WR_PaladinForever_RefreshSealPrompt()
    local name = WR_PaladinForever_ActiveSealPromptName
    local untilAt = WR_PaladinForever_ActiveSealPromptUntil
    if not name or type(untilAt) ~= "number" then return false end
    if GetTime() >= untilAt then
        -- 窗口结束：清记录，交回正常循环（ClearStalePrompts 会收掉 PromptHold）
        WR_PaladinForever_ActiveSealPromptName = nil
        WR_PaladinForever_ActiveSealPromptSlot = nil
        WR_PaladinForever_ActiveSealPromptUntil = nil
        WR_PaladinForever_ActiveSealPromptBypass = nil
        return false
    end
    local needed
    if WR_PaladinForever_ActiveSealPromptBypass then
        -- 显式切印（光明 / 十字军审判 / 智慧插入）：窗口内无条件保持
        needed = true
    else
        needed = WR_PaladinForever_SealNeedsRefresh(name)
    end
    if not needed then
        WR_PaladinForever_HideNow(name, WR_PaladinForever_ActiveSealPromptSlot)
        return false
    end
    local slot = WR_PaladinForever_ActiveSealPromptSlot
    if not WR_ColorFrame_ShowSkill(name, slot) then
        WR_PaladinForever_ActiveSealPromptName = nil
        WR_PaladinForever_ActiveSealPromptSlot = nil
        WR_PaladinForever_ActiveSealPromptUntil = nil
        WR_PaladinForever_ActiveSealPromptBypass = nil
        return false
    end
    return true
end

-- ★ 兜底清理：色块「亮到打出为止」，只在超过保持上限后才熄灭
--   · 有保持标记（刚提示过）→ 到 PromptHold 时间才清
--   · 没有保持标记（旧逻辑残留）→ 用 maxAge 兜底
--   上限默认 3 秒：给 AHK 足够读屏+按键时间，又不至于长时间挂着。
function WR_PaladinForever_ClearStalePrompts(maxAge)
    local now = GetTime()
    local fallbackAge = maxAge or 1.0
    local hold = WR_PaladinForever_PromptHold or {}
    for spell, t in pairs(WR_PaladinForever_PromptCD or {}) do
        local holdUntil = hold[tostring(spell)]
        local expired
        if holdUntil then
            expired = now >= holdUntil
        else
            expired = (now - t) >= fallbackAge
        end
        if expired then
            local slot = WR_PaladinForever_PromptSlot and WR_PaladinForever_PromptSlot[spell]
            if not slot and type(WR_SoD_ResolveSlot) == "function" then
                slot = WR_SoD_ResolveSlot(spell)
            end
            WR_PaladinForever_HideSkillVisual(spell, slot)
            if WR_PaladinForever_PromptHold then
                WR_PaladinForever_PromptHold[tostring(spell)] = nil
            end
            -- ★ 保持到期即视为「本轮提示结束」：清掉已亮标记，
            --   下次 CD 好时重新走首亮路径（立刻亮，不等 GCD）
            WR_PaladinForever_ClearPromptShown(spell)
        end
    end
end

-- ★ 防护祝福：按菜单「祝福」下拉（FH_ZF）在战斗外给自己补祝福。
--   本服法术 ID（2026-11-06 实测）：
--     力量祝福 19834 / 智慧祝福 19742 / 王者祝福 20217
--   强效祝福沿用同名技能（客户端有则用，无则跳过）。
--   ★ 判定以「身上是否真的有这个 Buff」为准（WR_GetUnitBuffTime）。
--     不要加「施放成功记录 60 分钟」之类的本地兜底：祝福会被驱散/被同类祝福覆盖，
--     本地记录会把「已经被驱散」误判成「还在身上」，导致不再提示补祝福。
WR_PaladinForever_BlessingList = {
    [1] = { name = "力量祝福",     slot = 81 },
    [2] = { name = "智慧祝福",     slot = 82 },
    [3] = { name = "王者祝福",     slot = 83 },
    [4] = { name = "强效力量祝福", slot = 84 },
    [5] = { name = "强效智慧祝福", slot = 85 },
    [6] = { name = "强效王者祝福", slot = 86 },
}

-- ★ 某祝福是否已在身上：只信 Buff 读值（可读且 >0 才算有）
function WR_PaladinForever_BlessingUp(name)
    local remain = WR_GetUnitBuffTime("player", name)
    if remain and remain > 0 then return true end
    return false
end

function WR_PaladinForever_Blessing(setting)
    -- 祝福只在战斗外施放（菜单 tooltip 约定）
    if UnitAffectingCombat("player") then return false end
    local rec = WR_PaladinForever_BlessingList[tonumber(setting) or 7]
    if not rec then return false end
    if WR_PaladinForever_BlessingUp(rec.name) then return false end
    -- ★ 提示防刷屏：同一条祝福 10 秒内只提示一次
    --   （被驱散后仍会重试提示，但不会每 tick 连刷）
    if not WR_PaladinForever_CanPrompt("祝福:" .. rec.name, 10) then return false end
    if WR_SpellUsable(rec.name) then
        if WR_ColorFrame_ShowSkill(rec.name, rec.slot) then
            WR_PaladinForever_MarkPrompt("祝福:" .. rec.name, rec.slot)
            WR_PaladinForever_HideSkillLater(rec.name, rec.slot, 1.0)
            return true
        end
    end
    return false
end

function WR_PaladinForever_ProtBlessing()
    return WR_PaladinForever_Blessing(PigSet and PigSet.FH_ZF)
end

-- ★ 战斗进出事件：记录进战时刻与「缺印加速补」标记（只有明确缺印才补）
--   ★ 天赋变更监听：切换/重置天赋后「强化审判」可能变化，清缓存等下次脱战重探。
--   ★ 脱战时补做待办的天赋重扫描（战斗中绝不扫，避免进战斗卡顿）。
do
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_DEAD")
    f:RegisterEvent("PLAYER_TALENT_UPDATE")
    f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    f:RegisterEvent("CHARACTER_POINTS_CHANGED")
    -- ★★ 2026-11-10 用户口径「战斗中加入自动平砍」：
    --   用真实事件维护「平砍是否在跑」，事件缺失时靠限频兜底（见
    --   WR_PaladinForever_AutoAttackNeedsRestart）。事件不存在也不会报错。
    f:RegisterEvent("PLAYER_ENTER_COMBAT")
    f:RegisterEvent("PLAYER_LEAVE_COMBAT")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTER_COMBAT" then
            -- 平砍已开 → 不再需要提示；同时清掉已亮标记，让「停下后」能立刻重提示
            WR_PaladinForever_AutoAttackOn = true
            WR_PaladinForever_AutoAttackEventKnown = true
            WR_PaladinForever_HideNow("攻击", 15)
            return
        elseif event == "PLAYER_LEAVE_COMBAT" then
            -- 平砍停了（切目标未接上 / 被打断 / 手动停）→ 允许下一 tick 重新提示
            WR_PaladinForever_AutoAttackOn = false
            WR_PaladinForever_AutoAttackEventKnown = true
            -- ★ 同时清掉「已亮标记」与「提示防抖」，否则 2 秒限频会继续挡住，
            --   玩家要白等 2 秒才看到「攻击」色块，平砍空窗被无谓拉长。
            WR_PaladinForever_ClearPromptShown("攻击")
            if WR_PaladinForever_PromptCD then
                WR_PaladinForever_PromptCD["攻击"] = nil
            end
            return
        end
        if event == "PLAYER_REGEN_DISABLED" then
            WR_PaladinForever_ForceSealAtCombat = true
            WR_PaladinForever_WasInCombat = true
            WR_PaladinForever_CombatStartAt = GetTime()
        elseif event == "PLAYER_REGEN_ENABLED" then
            WR_PaladinForever_ForceSealAtCombat = false
            WR_PaladinForever_WasInCombat = false
            WR_PaladinForever_CombatStartAt = nil
            -- ★ 2026-11-09 第四次修正：本服圣印是 30 秒短 Buff，不是 30 分钟。
            --   脱战不清空计时（清空会让下一场战斗误判缺印），圣印是否还在统一由
            --   「最近一次任意圣印成功施放 + 30 秒」与可读光环判定；只有死亡才清。
            -- ★ 脱战补做战斗中延后的天赋重扫描（此时无战斗开销压力）
            if WR_PaladinForever_JudgeScanPending then
                WR_PaladinForever_ScanJudgeTalent()
            end
        elseif event == "PLAYER_DEAD" then
            -- ★ 死亡会移除圣印：清空三种常驻圣印计时与扫描缓存，复活后重新提示补印
            WR_PaladinForever_ProtSealCastAt = nil
            WR_PaladinForever_JusticeSealCastAt = nil
            WR_PaladinForever_LightSealCastAt = nil
            WR_PaladinForever_CrusaderSealCastAt = nil
            WR_PaladinForever_WisdomSealCastAt = nil
            WR_PaladinForever_LastSealCastAt = nil
            WR_PaladinForever_SealBuffKnownUntil = nil
            WR_PaladinForever_SealScanAt = nil
            WR_PaladinForever_SealScanState = nil
            WR_PaladinForever_ActiveSealPromptName = nil
            WR_PaladinForever_ActiveSealPromptSlot = nil
            WR_PaladinForever_ActiveSealPromptUntil = nil
            WR_PaladinForever_ActiveSealPromptBypass = nil
            WR_PaladinForever_SealPromptLitAt = nil
            WR_PaladinForever_SealPromptLitName = nil
            WR_PaladinForever_ForceSealAtCombat = false
            WR_PaladinForever_CombatStartAt = nil
            -- 清掉玩家光环缓存旧值，避免死亡前「圣印还在」的缓存被当成当前状态
            if WR_AuraCache then WR_AuraCache["player"] = nil end
            if type(WR_ForceRefreshAuraCache) == "function" then
                WR_ForceRefreshAuraCache("player")
            end
        else
            -- ★ 天赋变更：清空「强化审判」探测缓存，标记待重探
            WR_PaladinForever_JudgeTalentKnown = nil
            WR_PaladinForever_JudgeScanPending = true
            -- 脱战状态立即重扫；战斗中留到 PLAYER_REGEN_ENABLED
            if not UnitAffectingCombat("player") then
                WR_PaladinForever_ScanJudgeTalent()
            end
        end
    end)
end


-- ★ 2026-11-08：焦点变化追踪器（排查「战斗中自动设焦点」到底是谁干的）
--   用法：/mkpal track 开启 → 复现问题 → /mkpal 查看记录
--   记录内容：时间、新焦点名、是否玩家、是否战斗中、当时的 FocusCast 状态、
--             跟随开关状态、以及最近一次点亮的色块槽位与文字。
WR_PaladinForever_FocusLog = WR_PaladinForever_FocusLog or {}
-- ★ 2026-11-08：默认开启追踪。焦点异常是「偶发且转瞬即逝」的，
--   等想起来再 /mkpaltrack 往往已经错过现场；默认开着，/mkpal 随时能回看最近记录。
--   平时开销极小：仅在追踪开启时记录色块（见下方 PushHist 的开关判断）。
if WR_PaladinForever_FocusTracking == nil then
    WR_PaladinForever_FocusTracking = true
end
WR_PaladinForever_LastShownSlot = WR_PaladinForever_LastShownSlot or nil
WR_PaladinForever_LastShownText = WR_PaladinForever_LastShownText or nil

SLASH_MKPALTRACK1 = "/mkpaltrack"
SlashCmdList["MKPALTRACK"] = function()
    WR_PaladinForever_FocusTracking = not WR_PaladinForever_FocusTracking
    WR_PaladinForever_FocusLog = {}
    print("|cff00ff00[MKPAL]|r 焦点追踪：" ..
        (WR_PaladinForever_FocusTracking and "已开启（复现问题后输入 /mkpal 查看）" or "已关闭"))
end

do
    -- ★ 色块点亮历史（环形缓冲，保留最近 2 秒）
    --   焦点变化时把这段时间内点过的所有色块一起打印，就能看出「是谁触发的」。
    --   ★ 性能：只在 /mkpaltrack 开启追踪时才记录，平时零开销（不建表、不遍历）。
    WR_PaladinForever_ShowHist = WR_PaladinForever_ShowHist or {}
    local HIST_WINDOW = 2.0
    local HIST_MAX = 60
    local histIdx = 0

    local function WR_PaladinForever_PushHist(slot, text)
        local h = WR_PaladinForever_ShowHist
        local now = GetTime()
        -- 环形写：复用固定槽位，避免每次新建表
        histIdx = histIdx % HIST_MAX + 1
        h[histIdx] = { t = now, slot = slot, text = text }
        WR_PaladinForever_LastShownSlot = slot
        WR_PaladinForever_LastShownText = text
    end

    -- 覆盖 WR_ColorFrame_Show：记录每一次色块点亮
    if type(WR_ColorFrame_Show) == "function" then
        local origShow = WR_ColorFrame_Show
        WR_ColorFrame_Show = function(name, text)
            WR_PaladinForever_PushHist(name, text)
            return origShow(name, text)
        end
    end

    -- 覆盖 WR_ColorFrame_ShowSkill：技能名版也记（实际槽位解析后记录）
    if type(WR_ColorFrame_ShowSkill) == "function" then
        local origShowSkill = WR_ColorFrame_ShowSkill
        WR_ColorFrame_ShowSkill = function(skillName, fallbackSlot)
            local slot = fallbackSlot
            if type(WR_SoD_ResolveSlot) == "function" then
                slot = WR_SoD_ResolveSlot(skillName) or fallbackSlot
            end
            WR_PaladinForever_PushHist(slot, skillName)
            return origShowSkill(skillName, fallbackSlot)
        end
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_FOCUS_CHANGED")
    f:SetScript("OnEvent", function()
        if not WR_PaladinForever_FocusTracking then return end
        local now = GetTime()
        local fname = UnitExists("focus") and (UnitName("focus") or "?") or "无"
        local isPlayer = UnitExists("focus") and UnitIsPlayer("focus") or false
        local fci = WR_FocusCast_Info

        -- 把焦点变化前 2 秒内点过的色块拼成序列（环形缓冲，按时间排序）
        local seq = {}
        local h = WR_PaladinForever_ShowHist
        local entries = {}
        for i = 1, #h do
            local e = h[i]
            if e and (now - e.t) <= HIST_WINDOW then
                entries[#entries + 1] = e
            end
        end
        table.sort(entries, function(a, b) return a.t < b.t end)
        for i = 1, #entries do
            seq[#seq + 1] = string.format("%s(%s)", tostring(entries[i].slot), tostring(entries[i].text))
        end
        local seqText = (#seq > 0) and table.concat(seq, " → ") or "（2秒内无色块）"

        local line = string.format(
            "[%.0fs] 焦点→%s 玩家=%s 战斗=%s FocusCast=%s/%s 跟随=%s\n        色块序列: %s",
            now, tostring(fname), tostring(isPlayer),
            tostring(UnitAffectingCombat("player")),
            tostring(fci and fci.active), tostring(fci and fci.spell),
            tostring(PigSet and PigSet.AUTO_FOLLOW_ENABLED),
            seqText)
        table.insert(WR_PaladinForever_FocusLog, line)
        if #WR_PaladinForever_FocusLog > 30 then
            table.remove(WR_PaladinForever_FocusLog, 1)
        end
    end)
end

-- ★ 调试命令：/mkseal（查看圣印判定状态；不需要 /run 自定义脚本）
SLASH_MKSEAL1 = "/mkseal"
SlashCmdList["MKSEAL"] = function()
    local sealName, sealSlot, field = WR_PaladinForever_MainSeal()
    local state = WR_PaladinForever_ProtSealState and WR_PaladinForever_ProtSealState() or "nil"
    local sid = type(WR_ResolveSpellID) == "function" and WR_ResolveSpellID(sealName) or nil
    local usable = type(WR_SpellUsable) == "function" and WR_SpellUsable(sealName) or nil
    local known = (type(IsPlayerSpell) == "function" and sid) and IsPlayerSpell(sid) or nil
    local castAt = field and _G["WR_PaladinForever_" .. field] or nil
    -- ★ 2026-11-09 第十二次修正：999 是「无到期时间/缓存残留」哨兵，不是 999 秒。
    --   不标注会让排查者误以为 Buff 还有 999 秒，正是本次误判的入口。
    local rawBuffRemain = WR_GetUnitBuffTime("player", sealName)
    local buffRemainText = tostring(rawBuffRemain)
    if rawBuffRemain == 999 then
        buffRemainText = "999(哨兵:无到期时间/缓存残留)"
    end
    print("|cff00ff00[MKSEAL]|r mainSeal=" .. tostring(sealName)
        .. " slot=" .. tostring(sealSlot)
        .. " state=" .. tostring(state)
        .. " resolvedID=" .. tostring(sid)
        .. " spellUsable=" .. tostring(usable)
        .. " isPlayerSpell=" .. tostring(known)
        .. " buffRemain=" .. buffRemainText
        .. " castAt=" .. tostring(castAt)
        .. " lastSealCastAt=" .. tostring(WR_PaladinForever_LastSealCastAt)
        .. " now=" .. tostring(GetTime()))
    -- ★ 2026-11-09：排查「所有圣印都不打」时的关键判据（开关 / 真实 Buff / 补印保持窗口）
    print("|cff00ff00[MKSEAL]|r 常驻圣印=" .. tostring(sealName)
        .. " 身上任意圣印=" .. tostring(WR_PaladinForever_BaseSealUp())
        .. " 战斗中=" .. tostring(UnitAffectingCombat("player"))
        .. " 补印保持至=" .. tostring(WR_PaladinForever_PromptHold
            and WR_PaladinForever_PromptHold[tostring(sealName)]))
    -- ★★ 2026-11-09：补印门控（战斗中 + 近战可攻击）诊断，排查「脱战上印 / 进战没补」
    print("|cff00ff00[MKSEAL]|r 补印门控=" .. tostring(WR_PaladinForever_CanApplySeal())
        .. " 目标距离=" .. tostring(WR_UnitRange and WR_UnitRange("target") or "nil")
        .. " 可攻击=" .. tostring(UnitCanAttack("player", "target"))
        .. " 目标存在=" .. tostring(UnitExists("target"))
        .. " 进战补印标记=" .. tostring(WR_PaladinForever_ForceSealAtCombat))
    -- ★★ 2026-11-09：反复上印排查（圣印 30 秒 Buff 时效 + 任意圣印判定）
    local bs, bname = WR_PaladinForever_SealBuffState()
    local lastSeal = WR_PaladinForever_LastSealAppliedAt()
    print("|cff00ff00[MKSEAL]|r 圣印光环=" .. tostring(bs) .. "/" .. tostring(bname)
        .. " 允许补印=" .. tostring(WR_PaladinForever_SealNeedsRefresh(sealName))
        .. " 距上次上印=" .. tostring(lastSeal and (GetTime() - lastSeal) or "nil")
        .. " Buff时长=" .. tostring(WR_PaladinForever_SEAL_BUFF_SECONDS) .. "秒")
    -- ★★★ 2026-11-09 第十二次修正：直扫 vs 缓存对比。
    --   「缓存态=up / 直扫=missing」即本次假 up 根因（缓存里残留过期圣印，999 哨兵）。
    local dst, dnm, dremain = WR_PaladinForever_ScanSealAura()
    print("|cff00ff00[MKSEAL]|r 圣印直扫=" .. tostring(dst) .. "/" .. tostring(dnm)
        .. " 直扫剩余=" .. tostring(dremain and string.format("%.1f", dremain) or "nil")
        .. " 缓存态=" .. tostring(bs) .. "/" .. tostring(bname)
        .. "（buffRemain=999 表示无到期时间哨兵，不是999秒）")
    -- ★★ 2026-11-09 第十一次修正：补印计时/提示窗口诊断。
    --   排查「战斗中又没挂圣印」：看圣印色块到底点亮过没有、点亮后过了多久。
    local knownLeft = WR_PaladinForever_SealBuffKnownUntil
        and (WR_PaladinForever_SealBuffKnownUntil - GetTime()) or 0
    local missFor = WR_PaladinForever_SealMissingSince
        and (GetTime() - WR_PaladinForever_SealMissingSince) or nil
    local promptLeft = WR_PaladinForever_ActiveSealPromptUntil
        and (WR_PaladinForever_ActiveSealPromptUntil - GetTime()) or nil
    local promptAge = WR_PaladinForever_SealPromptShownAt
        and (GetTime() - WR_PaladinForever_SealPromptShownAt) or nil
    print("|cff00ff00[MKSEAL]|r 圣印计时: 确知剩余=" .. string.format("%.1f", knownLeft)
        .. "秒 缺印确认=" .. tostring(missFor and string.format("%.1f", missFor) or "nil")
        .. " 保护窗口剩余=" .. tostring(promptLeft and string.format("%.2f", promptLeft) or "nil")
        .. " 上次点亮圣印=" .. tostring(promptAge and string.format("%.1f", promptAge) or "nil")
        .. " 点亮次数=" .. tostring(WR_PaladinForever_SealPromptShownCount or 0))
    -- ★★★ 2026-11-09 第十次修正：直接报告「圣印色块到底亮没亮」+ 被硬闸拦截次数。
    --   用于真机确认「插件是否点亮了 slot47（正义圣印）」这一唯一根因。
    local shownL, shownR = false, false
    local fl = ColorFrameArrayTopLeft and ColorFrameArrayTopLeft[sealSlot]
    local fr = ColorFrameArrayTopRight and ColorFrameArrayTopRight[sealSlot]
    if fl and type(fl.IsShown) == "function" then
        local ok, v = pcall(fl.IsShown, fl); if ok then shownL = v == true end
    end
    if fr and type(fr.IsShown) == "function" then
        local ok, v = pcall(fr.IsShown, fr); if ok then shownR = v == true end
    end
    print("|cff00ff00[MKSEAL]|r 圣印色块亮=" .. tostring(shownL or shownR)
        .. " 槽位=" .. tostring(sealSlot)
        .. " 上次点亮=" .. tostring(WR_PaladinForever_LastShownSlot)
        .. "/" .. tostring(WR_PaladinForever_LastShownText)
        .. " 硬闸拦截=" .. tostring(WR_PaladinForever_SealBlockedCount or 0)
        .. "次 最近拦截=" .. tostring(WR_PaladinForever_SealBlockedName or "无"))
end

-- ============================================================
-- ★★ 2026-11-09 第四次修正：本服圣印是「30 秒短 Buff」，不是 30 分钟长 Buff
-- ------------------------------------------------------------
--   证据：
--     · 用户截图：正义圣印 / 法术ID 20289 / 「剩余25秒」；
--     · Data/Forever_Abilities.lua 中 Seal of Command 写明 "Lasts 30 sec"；
--     · AHK 只读审计：色块只要常亮，AHK 每 ~60ms 就重按一次（同色连按，
--       无一次性闩锁），3 秒保持 = 约 50 次 /cast 圣印。
--   旧实现把「圣印施放成功记录」按 1800 秒(30 分钟)判 up，又在光环读不到时
--   用 1 秒 / 8 秒防抖反复点亮圣印色块 —— 两者叠加正是「圣印明明在身上却
--   反复上印」以及上一轮「圣印消失进战没补」来回反复的根因。
--   现在统一按 30 秒时效记账：
--     · 光环可读 → 以真实 Buff 为准（任意含「圣印」的光环都算，覆盖所有圣印）；
--     · 明确读到「没有任何圣印」→ 真的缺，允许补一次；
--     · 光环不可读（战斗中 secret）→ 「最近一次任意圣印成功施放 + 30 秒」内
--       一律视为圣印在身上，绝不重复点亮色块；到期才补下一次。
-- ============================================================
WR_PaladinForever_SEAL_BUFF_SECONDS = 30
-- ★★ 2026-11-09 第八次修正（用户最终口径，逐字确认）：
--   「圣印存在30秒，只需要上一次即可，圣印的技能是没有cd的可以一直释放」。
--   —— 本服圣印是 30 秒短 Buff、技能本身没有冷却；AHK 是「同色常亮就一直按」
--      （每 ~60ms 重按一次，色块亮 0.3 秒 = 约 5 次 /cast）。因此只要插件多点亮
--      一次圣印色块，就会被 AHK 放大成「反复上圣印」。
--   之前的 2 秒「提前补」正是罪魁：每次 Buff 还没到期就先点亮色块做预防性刷新 →
--   AHK 一顿连按 → 表现为「用了圣印后还会反复上」。
--   最终策略：**绝不提前补**。每次成功上印后「硬锁」一个完整 Buff 周期 + 少量缓冲；
--   硬锁期间无论光环是否读得到，一律不点亮圣印色块。硬锁走完后：
--     · 光环可读且确有圣印 → 仍在身，不补（尊重玩家手动续的印）；
--     · 光环可读且确认没有 / 光环不可读 → 视为真的掉了，补一次（并重新开始硬锁）。
--   这样一场战斗通常只会上 1~2 次印，彻底消除每 ~28 秒的连按爆发。
--
--   ★★ 2026-11-10 用户口径演变（同一件事，两次收紧）：
--     ① 「五秒太久了改2秒」→ 缓冲 3 秒收到 1 秒，掉印后 2 秒重新亮；
--     ② 「圣印空档期太久，我想更快点补圣印」→ 缓冲再收到 0.2 秒。
--   本常量只负责「硬锁缓冲」，完整空窗 = 缓冲 + Prot 第 3 段那道「缺印确认」：
--     · 缓冲 3 秒（旧）   → 掉印后 3 + 1 = 4 秒才重新亮（体感约 5 秒）；
--     · 缓冲 1 秒（上一版）→ 掉印后 1 + 1 = 2 秒重新亮；
--     · 缓冲 0.2 秒（现）  → 掉印后 0.2 + 0.1 = 0.3 秒重新亮。
--
--   为什么 0.2 秒仍然不会「提前补」也不会「反复上印」：
--     · 硬锁下限 = 30（真实 Buff 时长）+ 0.2 = 30.2 秒，**严格大于** Buff 本身，
--       所以一个 Buff 周期最多点亮一次色块，理论补印频率不变（每 ~30.2 秒一次）；
--     · 0.2 秒的余量只用来吸收「客户端 Buff 到期时刻 vs 本地记账时刻」的偏差
--       （施放成功事件延迟 + 主循环 0.1 秒 tick 量化）；
--     · 真正的防洪闸不是这个缓冲，而是：
--       ① 光环可读时以客户端为准（SealBuffState == "up" 一律不补）；
--       ② Prot 第 3 段的 CanPrompt(mainSeal, 3) —— 色块亮过之后 3 秒内不重亮，
--          专治「施放成功事件丢失导致记账不推进」的洪水。
--   所以缓冲收到 0.2 只是把「掉印到补印」的等待缩短，不会放大连按。
WR_PaladinForever_SEAL_LOCK_GRACE = 0.2   -- 硬锁 = Buff 时长 + 0.2 秒缓冲；+0.1 秒缺印确认 = 掉印后 0.3 秒重新亮
-- ★ 保留旧名（供旧调用点 / 诊断引用），语义改为「硬锁时长」
WR_PaladinForever_SEAL_REFRESH_LEAD = 0
-- ★ 事件全丢导致本地记录异常久远时的极宽兜底（正常永不命中）
--   ★★ 2026-11-10：本常量已【不再参与补印判定】。旧实现让 SEAL_NO_AURA 名单内的
--   愤怒圣印走这个 300 秒兜底，与「30 秒真实 Buff 时效」冲突：31 秒后
--   SealNeedsRefresh=false（不许补）而 ProtSealState=missing（认为没圣印），
--   审判门控 `sealState ~= "missing" or SealActive()` 两条同时不成立 →
--   审判 300 秒点不亮。现在两种圣印统一走「Buff + 硬锁缓冲」硬锁。保留常量仅为兼容旧引用。
WR_PaladinForever_SEAL_MISSING_FALLBACK = 300
-- ★ 本服「不挂可读 HELPFUL 光环」的圣印名单（愤怒圣印 Seal of Fury 1311656：
--   audit 实读确认施放后不产生可被 C_UnitAuras 枚举的具名自增益光环）。
--   第八次修正后，所有圣印统一走「硬锁 + 走完再补」策略，本名单只用于诊断，
--   不再影响是否补印（读不到光环不再触发提前补）。
WR_PaladinForever_SEAL_NO_AURA = {
    ["愤怒圣印"] = true,
}
-- 本服法术书 / 宏里出现过的全部圣印名（按名枚举、按 ID 反查、成功施放记账共用）
WR_PaladinForever_SealNames = {
    "正义圣印", "愤怒圣印", "十字军圣印", "命令圣印", "公正圣印",
    "光明圣印", "智慧圣印", "殉难圣印", "腐蚀圣印", "复仇圣印",
}

-- 已知圣印 spellID 集合（懒构建，只在第一次拿到数字 ID 时解析一次）
WR_PaladinForever_SealSpellIDs = WR_PaladinForever_SealSpellIDs or {}
-- ★★ 2026-11-09 第七次修正（用户：「圣印的技能都会升级，不要设置等级」）：
--   练级阶段圣印会随等级升级 rank / spellID 变化。绝不能写死某个 rank 的 ID
--   （旧的 sid==20289、{1311656,20423} 等只对特定等级成立），否则升级后
--   新 rank 的施放/光环就认不出 → 记账断档 → 反复补印。
--   改为「每次都按当前技能名动态解析 ID」：练级时 WR_ResolveSpellID 自动拿到
--   当前已学 rank 的真实 ID；同时保留「名字含『圣印』」这条与 ID 无关的通道，
--   任何 rank / 自定义 ID 都能命中。解析结果按 (名字→ID) 缓存，等级变化时
--   缓存的是「当前 rank 的 ID」，若未来升到更高 rank，新的施放事件会带来新的
--   sid，届时再走一次 WR_ResolveSpellID 即可重新对齐（缓存只为省调用，不锁死旧 ID）。
function WR_PaladinForever_IsSealSpellID(sid)
    if type(sid) ~= "number" then return false end
    local t = WR_PaladinForever_SealSpellIDs
    if t[sid] ~= nil then return t[sid] end
    local hit = false
    -- ① 动态解析：逐个圣印名 → 当前已学 rank 的 spellID（不写死任何 rank）
    if type(WR_ResolveSpellID) == "function" then
        for i = 1, #WR_PaladinForever_SealNames do
            local ok, id = pcall(WR_ResolveSpellID, WR_PaladinForever_SealNames[i])
            if ok and type(id) == "number" and id == sid then
                hit = true
                break
            end
        end
    end
    -- ② 反查技能名含「圣印」（覆盖动态解析不到的 rank / 自定义 ID；与等级无关）
    if not hit and type(WR_ResolveSpellID) == "function" then
        -- 尝试用客户端把 ID 反解成名字，再判是否圣印
        local okName, nm = pcall(function()
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(sid)
                return info and info.name
            end
            if GetSpellInfo then return (GetSpellInfo(sid)) end
            return nil
        end)
        if okName and type(nm) == "string" and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(nm)) then
            local okFind, found = pcall(string.find, nm, "圣印", 1, true)
            if okFind and found then hit = true end
        end
    end
    t[sid] = hit
    return hit
end

-- 直接扫玩家 HELPFUL 光环，三态返回："up" / "missing" / "unknown"
--   up      = 找到任意圣印光环（名字含「圣印」或 spellId 命中已知圣印）
--   missing = 光环全部可读、确实没有圣印
--   unknown = 出现 secret 值，无法排除「它就是圣印」，交给本地 30 秒记录兜底
--   ★ 2026-11-09 第十一次修正：up 时额外返回「剩余秒数」，用于记住
--     “这条圣印至少还存在多久”，避免审判后光环缓存被清空造成的假 missing。
function WR_PaladinForever_ScanSealAura()
    if type(C_UnitAuras) ~= "table"
       or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then
        return "unknown", nil, nil
    end
    local unknown = false
    local function RemainOf(data)
        local exp = data and data.expirationTime
        if type(exp) == "number"
           and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(exp))
           and exp ~= 0 and exp ~= 999 then
            local left = exp - GetTime()
            if left > 0 and left < 900 then return left end
        end
        return nil
    end
    -- ★★★ 2026-11-09 第十二次修正（审计补充）：直扫列表也可能返回「到期时间
    --   明确已过去」的残留条目。旧版只要名字含「圣印」/ID 命中就判 up，
    --   与缓存分支口径不一致，会再次造成整场假 up。这里明确过期的条目跳过；
    --   exp==0/999 表示「存在但无到期时间」，仍合法视为在身。
    local function Expired(data)
        local exp = data and data.expirationTime
        if type(exp) ~= "number" then return false end
        if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(exp) then return false end
        if exp == 0 or exp == 999 then return false end
        return exp <= GetTime()
    end
    for i = 1, 40 do
        local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok then return "unknown", nil, nil end
        if not data then break end
        local sid = data.spellId
        if type(sid) == "number"
           and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(sid))
           and WR_PaladinForever_IsSealSpellID(sid) then
            if not Expired(data) then return "up", nil, RemainOf(data) end
        end
        local nm = data.name
        if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(nm) then
            unknown = true
        elseif type(nm) == "string" then
            local okFind, found = pcall(string.find, nm, "圣印", 1, true)
            if okFind and found then
                if not Expired(data) then return "up", nm, RemainOf(data) end
            elseif not okFind then
                unknown = true
            end
        else
            unknown = true
        end
    end
    if unknown then return "unknown", nil, nil end
    return "missing", nil, nil
end

-- 统一「身上有没有圣印」判定；返回 state, sealName
--   state: "up" / "missing"（权威） / "unknown"（光环不可读）
--   同一帧内多次调用只算一次（0.05 秒内命中缓存，避免每 tick 扫 40 光环 ×N 次）
WR_PaladinForever_SealBuffStateCache = WR_PaladinForever_SealBuffStateCache or {}
-- ★★ 2026-11-09 第十一次修正：最后确知「圣印还在」的截止时刻。
--   用途：审判成功后旧代码会清 WR_AuraCache["player"]，下一 tick 可能读到假
--   missing/unknown；若此时本地又没有施放记录（例如圣印是插件加载前挂上的），
--   就会在审判后立刻再补一次圣印。这里记住「真实读到的剩余时间」，
--   在这个截止时刻之前一律视为仍在身上，绝不补印。
WR_PaladinForever_SealBuffKnownUntil = WR_PaladinForever_SealBuffKnownUntil or nil
local function WR_PaladinForever_NoteSealBuffRemain(remain)
    if type(remain) ~= "number" or remain <= 0 then return end
    -- ★★★ 2026-11-09 第十二次修正（真机 /mkseal：buffRemain=999 却「确知剩余=32.0秒」）：
    --   WR_GetUnitBuffTime 返回的 999 是「条目存在但没有可读到期时间 / 缓存已过期」的
    --   哨兵值，不是 999 秒剩余。旧代码把它按 Buff 时长封顶成 32 秒，并且每 tick 都
    --   把 SealBuffKnownUntil 推到 now+32 → 永远假 up → 整场战斗允许补印恒 false。
    --   这里拒绝一切明显是哨兵/异常的剩余值（圣印 Buff 只有 30 秒，>120 秒必是哨兵）。
    if remain > 120 then return end
    -- ★★ 2026-11-10：cap 由「Buff + 2 秒」收窄到「Buff + 硬锁缓冲」，与硬锁口径对齐。
    --   旧 cap=32 秒比硬锁（30+缓冲）更宽松，会在「可读光环读到 30~32 秒剩余」时
    --   把 SealBuffKnownUntil 推到 now+32 → 盖过硬锁 → 可读圣印（正义圣印）仍要
    --   等到 31~32 秒才补，缓冲收紧就白做了。收窄后两类圣印走同一时序。
    --   注意：这里只影响「可读光环的上限」，光环明确 up 时仍然一律不补
    --   （SealNeedsRefresh 第 ① 步先 return false），不会因此提前上印。
    local cap = (WR_PaladinForever_SEAL_BUFF_SECONDS or 30)
        + (WR_PaladinForever_SEAL_LOCK_GRACE or 0)
    if remain > cap then remain = cap end
    local untilAt = GetTime() + remain
    local cur = WR_PaladinForever_SealBuffKnownUntil
    if type(cur) ~= "number" or untilAt > cur then
        WR_PaladinForever_SealBuffKnownUntil = untilAt
    end
end

-- ★★ 2026-11-10 新增：记录「最后一次【可读地】读到圣印光环」的时刻与名字。
--   用途见下方 WR_PaladinForever_SealLostEarly：只有「上印之后确实读到过这条圣印，
--   随后又权威读到没有」才算「被提前驱散」，否则一律按未知处理（继续等硬锁）。
WR_PaladinForever_SealAuraLastUpAt = WR_PaladinForever_SealAuraLastUpAt or nil
WR_PaladinForever_SealAuraLastUpName = WR_PaladinForever_SealAuraLastUpName or nil
-- 圣印/技能名归一：去掉「（等级 2）」这类后缀，便于和 MainSeal 的名字比较
-- ★★ 2026-11-10：Lua 5.1 字符类按字节匹配，[（(] 这种写法匹配不了多字节全角括号，
--   之前所有「去掉等级后缀」的地方实际都没生效。这里分两步用字面量匹配：
--   先全角「（等级 N）」，再半角「(等级 N)」。
local function WR_PaladinForever_StripRankSuffix(nm)
    if type(nm) ~= "string" then return nil end
    local s = string.gsub(nm, "%s*（等级%s*%d+）%s*$", "")
    if s == nm then
        s = string.gsub(nm, "%s*%(等级%s*%d+%)%s*$", "")
    end
    return s
end
local function WR_PaladinForever_BaseSealName(nm)
    if type(nm) ~= "string" then return nil end
    return WR_PaladinForever_StripRankSuffix(nm)
end
local function WR_PaladinForever_NoteSealAuraReadUp(name)
    WR_PaladinForever_SealAuraLastUpAt = GetTime()
    local base = WR_PaladinForever_BaseSealName(name)
    if base and base ~= "" then
        WR_PaladinForever_SealAuraLastUpName = base
    end
end
-- ★★ 2026-11-09 第七次修正：区分「两种圣印」——
--   · 会挂可读 HELPFUL 光环的圣印（命令/正义/十字军…）：光环到期读成 missing = 真到期，需补；
--   · 不挂可读光环的自定义圣印（愤怒圣印 Seal of Fury，audit 已确认读不到）：
--       永远读成 missing 也不能据此补，否则每 ~28 秒反复上印。
--   用本标记记录「这条圣印的光环是否曾经被【可读地】读到过」：
--   读到过 → 走「30 秒到期补」逻辑；从没读到过 → 只认「成功施放记录 / 审判清空」，
--   30 秒只作极宽的漏事件兜底，绝不每 28 秒重补。
WR_PaladinForever_SealAuraSeenUp = WR_PaladinForever_SealAuraSeenUp or {}
function WR_PaladinForever_SealBuffState()
    local now = GetTime()
    local c = WR_PaladinForever_SealBuffStateCache
    -- ★ 同一帧内多次调用共享结果（GetTime 每次调用可能差几毫秒，不能用 == now）
    if c.at and (now - c.at) >= 0 and (now - c.at) < 0.05 then
        return c.state, c.name
    end
    c.at = now

    -- ★★★ 2026-11-09 第十二次修正（真机 /mkseal：buffRemain=999 却 state=up）：
    --   WR_GetUnitBuffTime 的 999 是「缓存条目过期 / 无到期时间」哨兵，不能当
    --   「圣印还在」。旧第①步 `t > 0` 把 999 判 up；第②步又不看到期时间，任意
    --   圣印缓存条目都判 up → 开战前挂的圣印到期后，战斗中光环读不到（缓存冻结）
    --   仍永远判 up，SealNeedsRefresh 恒 false → 整场战斗不再补印。
    --   新逻辑：缓存只接受「可读且确实在未来」的到期时间；999/0/已过期一律不作
    --   存在证据，交给直扫（活体光环列表）或本地施放记录兜底。

    -- ① 插件光环缓存：只认可信的未来到期时间（快路径，正常情况命中这里）
    local cache = WR_AuraCache and WR_AuraCache["player"]
    local helpful = cache and cache.HELPFUL
    local cacheUnknown = false
    if helpful and #helpful > 0 then
        for i = 1, #helpful do
            local aura = helpful[i]
            local nm = aura and aura.name
            local secret = type(nm) ~= "string"
                or (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(nm))
            local isSeal = false
            if secret then
                cacheUnknown = true
            elseif type(nm) == "string" then
                local okFind, found = pcall(string.find, nm, "圣印", 1, true)
                if okFind and found then
                    isSeal = true
                elseif not okFind then
                    cacheUnknown = true
                end
            end
            -- 名字不可读时再按 spellId 兜底（正常缓存条目都有名字，避免热路径开销）
            if (not isSeal) and type(nm) ~= "string" then
                local sid = aura and aura.spellId
                if type(sid) == "number"
                   and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(sid))
                   and WR_PaladinForever_IsSealSpellID(sid) then
                    isSeal = true
                end
            end
            if isSeal then
                local exp = aura.expirationTime
                local expOK = type(exp) == "number"
                    and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(exp))
                    and exp ~= 0 and exp ~= 999   -- 0/999 = 无到期时间哨兵
                local left = expOK and (exp - now) or nil
                if left and left > 0 and left < 900 then
                    c.state, c.name = "up", nm
                    WR_PaladinForever_NoteSealBuffRemain(left)
                    WR_PaladinForever_NoteSealAuraReadUp(nm)
                    if type(nm) == "string" then
                        WR_PaladinForever_SealAuraSeenUp[nm] = true
                        -- 兼容「正义圣印（等级 2）」：同时按去后缀基名记一次
                        local base = WR_PaladinForever_StripRankSuffix(nm)
                        if base ~= nm then
                            WR_PaladinForever_SealAuraSeenUp[base] = true
                        end
                    end
                    WR_PaladinForever_SealAuraSeenUp["*"] = true
                    return c.state, c.name
                end
                -- ★ 名字是圣印但到期时间不可信（999/0/已过期）→ 缓存残留或不可读，
                --   绝不能判 up；标记 unknown 让直扫/本地记录接管。
                cacheUnknown = true
            end
        end
        if not cacheUnknown then
            c.state, c.name = "missing", nil
            return c.state, c.name
        end
    end

    -- ② 直扫玩家光环（缓存为空/不可信时；战斗中不可读返回 unknown）
    local st, nm, remain = WR_PaladinForever_ScanSealAura()
    c.state, c.name = st, nm
    if st == "up" then
        if type(remain) == "number" and remain > 0 and remain < 900 then
            WR_PaladinForever_NoteSealBuffRemain(remain)
        else
            -- 只确知「此刻在」：给 2 秒桥接，避免下一帧缓存抖动误判 missing
            WR_PaladinForever_NoteSealBuffRemain(2)
        end
        WR_PaladinForever_NoteSealAuraReadUp(nm)
        WR_PaladinForever_SealAuraSeenUp["*"] = true
        if type(nm) == "string" then
            WR_PaladinForever_SealAuraSeenUp[nm] = true
        end
    end
    return c.state, c.name
end

-- 最近一次「任意圣印」成功施放时刻（三处记账取最晚者）
function WR_PaladinForever_LastSealAppliedAt()
    local last = WR_PaladinForever_LastSealCastAt
    local a, b = WR_PaladinForever_JusticeSealCastAt, WR_PaladinForever_ProtSealCastAt
    if type(a) == "number" and (type(last) ~= "number" or a > last) then last = a end
    if type(b) == "number" and (type(last) ~= "number" or b > last) then last = b end
    return last
end

-- ★★ 2026-11-09 第十一次修正：登记一次「圣印成功施放」。
--   统一写入 LastSealCastAt 与「确知存在截止时刻」，避免各事件分支漏记
--   导致审判后误判缺印、又补一次圣印。
function WR_PaladinForever_NoteSealApplied(at)
    local t = at or GetTime()
    WR_PaladinForever_LastSealCastAt = t
    local untilAt = t + (WR_PaladinForever_SEAL_BUFF_SECONDS or 30)
    local cur = WR_PaladinForever_SealBuffKnownUntil
    if type(cur) ~= "number" or untilAt > cur then
        WR_PaladinForever_SealBuffKnownUntil = untilAt
    end
end

-- ★★ 2026-11-11：记录「某条具体圣印刚刚成功施放」。
--   背景：无限战斗中 UNIT_SPELLCAST_SUCCEEDED 的 spellName / spellID 可能都是
--   secret，事件认不出是哪条圣印。旧逻辑的终极兜底只调用 NoteSealApplied 记录
--   通用时间，没有写 LastSealAppliedName 与各圣印专用的 CastAt 字段。
--   而「十字军审判 / 光明圣印 / 智慧审判」三个 buff 维持状态机判断
--   「目标圣印是否在身上」时，在该圣印光环不可读的战斗场景只能靠这两个字段兜底：
--     · 十字军审判开 → CrusaderSealOnPlayer() 恒 false
--     · 状态机 phase0 每 1.5 秒重新点亮十字军圣印色块
--     · AHK「同色常亮就一直按」→ 反复施放十字军圣印（用户 2026-11-11 反馈）
--   因此这里用「刚刚点亮过的圣印色块名」反推这次按的是哪条圣印，把名字与
--   专用计时一起补上，状态机下一 tick 即可确认切印成功，不再重复提示。
function WR_PaladinForever_RecordSealAppliedByName(sealName, at)
    if type(sealName) ~= "string" or sealName == "" then return false end
    if not string.find(sealName, "圣印", 1, true) then return false end
    -- 去掉「（等级 N）」后缀再和状态机常量比较（1.60.x 客户端可能带后缀）
    local base = WR_PaladinForever_StripRankSuffix(sealName)
    if type(base) == "string" and base ~= "" then sealName = base end
    local t = at or GetTime()
    WR_PaladinForever_LastSealAppliedName = sealName
    WR_PaladinForever_NoteSealApplied(t)
    WR_PaladinForever_SealScanAt = nil
    WR_PaladinForever_SealScanState = nil
    if WR_PaladinForever_SealBuffStateCache then
        WR_PaladinForever_SealBuffStateCache.at = nil
    end
    if sealName == "十字军圣印" then
        WR_PaladinForever_CrusaderSealCastAt = t
    elseif sealName == "光明圣印" then
        WR_PaladinForever_LightSealCastAt = t
    elseif sealName == "智慧圣印" then
        WR_PaladinForever_WisdomSealCastAt = t
    elseif sealName == "正义圣印" then
        WR_PaladinForever_JusticeSealCastAt = t
    elseif sealName == "愤怒圣印" then
        WR_PaladinForever_ProtSealCastAt = t
    end
    return true
end

-- 身上是否有任意圣印（光环不可读 / 读不准时按 30 秒 Buff 时效兜底）
-- ★★ 2026-11-09 第六次修正：本服某些圣印的 HELPFUL 光环读不到，SealBuffState 会
--   权威判成 "missing"，但「刚刚成功施放过」是更强证据。当本地存在一个 Buff 周期内的
--   成功施放记录时，即使 state==missing 也认为「身上有圣印」—— 这与 SealNeedsRefresh
--   的判定保持一致（不然会出现：SealNeedsRefresh 判定「不用补」、但 AnySealUp 判定
--   「没圣印」→ 审判门控被打断 / 安全熄灭分支不生效）。
--   ★ 2026-11-09 第十次修正：本服审判【不消耗】圣印（用户截图与日志证实），
--     因此审判成功不再清空本地记录；圣印到期/被驱散时由可读光环 missing 或硬锁判定。
function WR_PaladinForever_AnySealUp()
    local s = WR_PaladinForever_SealBuffState()
    if s == "up" then return true end
    -- ★ 真实读到过的剩余时间未到 → 即使此刻短暂读成 missing/unknown 也算在身
    local knownUntil = WR_PaladinForever_SealBuffKnownUntil
    if type(knownUntil) == "number" and GetTime() < knownUntil then
        return true
    end
    local last = WR_PaladinForever_LastSealAppliedAt()
    if type(last) == "number"
       and (GetTime() - last) < WR_PaladinForever_SEAL_BUFF_SECONDS then
        return true
    end
    -- 无近期成功记录：只有明确读到「确实没有圣印」才算没圣印
    if s == "missing" then return false end
    return false
end

-- 兼容旧调用点（防护循环 / 共享圣印保持 / 诊断）
function WR_PaladinForever_BaseSealUp()
    return WR_PaladinForever_AnySealUp()
end

-- 审判门控：身上有任意圣印（或 30 秒内成功上过任意圣印）
function WR_PaladinForever_SealActive()
    return WR_PaladinForever_AnySealUp()
end

-- ★★ 2026-11-10 新增：判断「圣印是否被提前驱散/顶掉」（早于 30 秒 Buff 到期）。
-- ------------------------------------------------------------
-- 用户报的问题：圣印被驱散或被别的圣印顶掉时，仍要等满硬锁（30.2 秒）。
--   例：第 10 秒被驱散 → 要等到第 31 秒才补 → 21 秒空窗。
--
-- 为什么不能简单地「读到 missing 就立刻补」：
--   ① 默认愤怒圣印在本服根本不挂可读光环（SEAL_NO_AURA），「读不到」是常态，
--      按 missing 补会立刻回到用户反复反馈的「每 2~3 秒反复上印」老 bug；
--   ② 战斗中玩家光环可能是 secret → 直扫返回 unknown，也不是「真没了」。
--
-- 判据（全部成立才算「真被提前驱散」，宁可不补也不误补）：
--   ① 光环扫描是【权威 missing】（不是 unknown / 缓存不可信）；
--   ② 本次上印之后，确实【可读地读到过】这条圣印光环 —— 证明它本来是可见的，
--      不是 SEAL_NO_AURA 那类天然读不到的圣印；
--   ③ 已过一个小缓冲（SEAL_EARLY_LOST_GRACE），吸收施放成功事件与光环缓存的
--      刷新延迟（UNIT_AURA → 缓存失效 → 下一 tick 重扫），避免刚上印就误判。
--   命中后允许补印，并把本地 30 秒记账一并作废（否则 SealBuffKnownUntil 还会
--   拦住下一次判定）。补印频率上限仍由 CanPrompt(mainSeal, 3) 兜住。
--   ★ 判据 ② 只看「读到过圣印」而不强求名字一致：圣印名可能带等级后缀、
--     也可能是玩家手动切了别的圣印（那也是「被顶掉」，同样该补回常驻圣印）。
--   ★★ 防「提前补印变连按」：额外加一道 10 秒闩锁。万一光环出现「读到 up →
--     下一帧 missing」的瞬时误读（缓存被清 / secret 抖动），没有这道闩锁就会
--     每 ~1 秒补一次 → 正是用户当年反馈的「反复上印」。真实被驱散不可能 10 秒内
--     连续发生多次，所以闩锁不影响正常补印的响应速度。
WR_PaladinForever_SEAL_EARLY_LOST_GRACE = 1.0
WR_PaladinForever_SEAL_EARLY_LOST_COOLDOWN = 10.0
WR_PaladinForever_SealEarlyLossAt = WR_PaladinForever_SealEarlyLossAt or nil

function WR_PaladinForever_SealLostEarly()
    -- ① 必须权威 missing
    local s = WR_PaladinForever_SealBuffState()
    if s ~= "missing" then return false end
    -- ② 本次上印之后确实读到过光环（天然读不到的圣印永远不满足这条）
    local seenAt = WR_PaladinForever_SealAuraLastUpAt
    local last = WR_PaladinForever_LastSealAppliedAt()
    if type(seenAt) ~= "number" then return false end
    if type(last) == "number" and seenAt < last then return false end
    -- ③ 缓冲：吸收事件/缓存刷新延迟
    local grace = WR_PaladinForever_SEAL_EARLY_LOST_GRACE or 1.0
    if type(last) == "number" and (GetTime() - last) < grace then return false end
    -- ④ 闩锁：上一次「提前掉印补印」之后 10 秒内不再走这条路（防瞬时误读连按）
    local prev = WR_PaladinForever_SealEarlyLossAt
    local cool = WR_PaladinForever_SEAL_EARLY_LOST_COOLDOWN or 10.0
    if type(prev) == "number" and (GetTime() - prev) < cool then return false end
    return true
end

-- 提前掉印后作废本地 30 秒记账，让补印立刻可以发生（否则 knownUntil 会拦住）
function WR_PaladinForever_ClearSealLockOnEarlyLoss()
    WR_PaladinForever_LastSealCastAt = nil
    WR_PaladinForever_ProtSealCastAt = nil
    WR_PaladinForever_JusticeSealCastAt = nil
    WR_PaladinForever_LightSealCastAt = nil
    WR_PaladinForever_CrusaderSealCastAt = nil
    WR_PaladinForever_WisdomSealCastAt = nil
    WR_PaladinForever_LastSealAppliedName = nil
    WR_PaladinForever_SealPromptLitAt = nil
    WR_PaladinForever_SealPromptLitName = nil
    WR_PaladinForever_SealBuffKnownUntil = nil
    WR_PaladinForever_SealAuraLastUpAt = nil
    WR_PaladinForever_SealAuraLastUpName = nil
    -- 光环缓存已由事件失效；这里再清一次圣印状态缓存，保证下一 tick 重新判定
    if WR_PaladinForever_SealBuffStateCache then
        WR_PaladinForever_SealBuffStateCache.at = nil
    end
    WR_PaladinForever_SealScanAt = nil
    WR_PaladinForever_SealScanState = nil
end

-- ★★ 防「反复上印」总闸：这一刻是否允许点亮补/切圣印色块
--   mainSeal 参数保留给诊断；判定与「当前常驻是哪个圣印」无关：
--   只要身上有【任意】圣印（含玩家手动切的别的圣印 / 带等级后缀名），
--   就一律不补、不切 —— 不再反复把它换回常驻圣印。
--   返回 true 时调用方仍需过 CanApplySeal（战斗中 + 近战可攻击）与提示防抖。
--
-- ★★ 2026-11-09 第六次修正（用户：「还是存在异常，旧版本都不会反复上buff」+ /mkseal 实测）：
--   /mkseal 连打两条显示：`state=missing buffRemain=0` 且 `距上次上印=0.92`（甚至 0.02），
--   也就是「刚刚成功施放过圣印（事件已记 30 秒窗口）」，但本服这条圣印的 HELPFUL
--   光环**读不到**（SealBuffState 权威判成 missing）。旧版 `if s=="missing" then return true`
--   直接无视本地成功记录 → 每 ~1-3 秒就重新点亮色块 → AHK 同色连按 → 反复上印。
--   这正是用户反馈的死循环：castAt 每 2~3 秒刷新一次、buffRemain 却恒为 0。
--
--   修正原则：**「刚刚成功施放过」比「光环读不到」更可信**。
--     · 有生效中的本地成功施放记录（30 秒窗口 - 2 秒提前量内）→ 一律不补，
--       不管 SealBuffState 是 up / missing / unknown（本服光环读不准时不至于反复刷）。
--     · 记录为空 / 已到期才允许补。
--   ★ 2026-11-09 第十次修正：本服审判【不消耗】圣印，审判成功不再清空任何圣印计时。
--   圣印真正掉了只有两种情形，分别由可读光环 missing 与极宽兜底覆盖，不会漏补。
function WR_PaladinForever_SealNeedsRefresh(mainSeal)
    local s = WR_PaladinForever_SealBuffState()

    -- ① 光环明确读到任意圣印在身上 → 绝不再补（第一优先，任何圣印都算）
    if s == "up" then return false end

    -- ★★★ 2026-11-10 新增（用户口径：「圣印被提前驱散或顶掉时，仍要等满硬锁」）：
    --   圣印在第 10 秒被驱散 / 被别的圣印顶掉时，旧逻辑仍要等满 30.2 秒硬锁
    --   → 最长 21 秒空窗。这里在「权威 missing + 上印后确实读到过光环」时
    --   提前放行，并作废本地记账，让第 3 段的 0.1 秒缺印确认立刻生效。
    --   ★ 放在 knownUntil 判定【之前】：提前掉印必须能覆盖掉本地 30 秒记账，
    --     否则 knownUntil 会一直拦到硬锁结束，等于没修。
    --   ★ 天然读不到光环的圣印（愤怒圣印）永远不满足「读到过」这条，
    --     仍走下面的硬锁，所以不会回到「反复上印」。
    if WR_PaladinForever_SealLostEarly() then
        WR_PaladinForever_SealEarlyLossAt = GetTime()
        WR_PaladinForever_ClearSealLockOnEarlyLoss()
        return true
    end

    -- ★★ 2026-11-09 第十一次修正：之前真实读到过圣印、且其 Buff 尚未到期 →
    --   此刻的 missing/unknown 只是缓存被清空/战斗 secret 的瞬时假象，绝不补印。
    --   这同时修复「挂了圣印打一次审判后又补一次圣印」：审判不再导致误判缺印。
    local knownUntil = WR_PaladinForever_SealBuffKnownUntil
    if type(knownUntil) == "number" and GetTime() < knownUntil then
        return false
    end

    local last = WR_PaladinForever_LastSealAppliedAt()

    -- ★★ 2026-11-10 修正（用户口径：默认愤怒圣印 300 秒不补导致审判连带饿死）：
    --   旧实现把 SEAL_NO_AURA 名单内的圣印（目前仅愤怒圣印 Seal of Fury）单独走
    --   「极宽兜底 300 秒」，理由是「光环读不到 ≠ 没了，别按计时补」。
    --   但本服圣印真实时效就是 30 秒，于是 31 秒后出现一个自相矛盾的状态：
    --     · SealNeedsRefresh  → false（300 秒兜底未到）→ 不允许补印；
    --     · ProtSealState / AnySealUp → missing（30 秒记账已到期）→ 认为身上没圣印。
    --   而审判门控是 `sealState ~= "missing" or SealActive()`，两条同时不成立
    --   → 审判整整 300 秒点不亮，主循环只剩神圣打击/神圣之盾。
    --   实测（模拟 AHK 成功按键）：愤怒圣印仅 t=1s 点亮一次，审判 t=1.5/11.5/21.5
    --   之后 180 秒内再无一次；对照正义圣印每 10 秒一发正常。
    --
    --   现在两种圣印统一走「Buff 时长 + 缓冲」硬锁（30 + 0.2 = 30.2 秒）：
    --     · 一个 Buff 周期最多点亮一次色块 —— 这是理论最小补印频率，
    --       不会回到用户反复反馈的「每 2~3 秒反复上印」（那是旧版 2 秒提前补的锅）；
    --     · 硬锁走完仍读不到光环 → 视为真的掉了，补一次并重新开始硬锁；
    --     · 光环若可读且确有圣印（玩家手动续的印）→ 前面第 ① 步已 return false。
    --   SEAL_NO_AURA 名单保留，但只用于诊断，不再改变补印节奏。
    --   ★★ 2026-11-10 用户口径两次收紧：
    --     ① 「五秒太久了改2秒」→ 缓冲 3 → 1 秒，掉印后 2 秒重新亮；
    --     ② 「圣印空档期太久，我想更快点补圣印」→ 缓冲 1 → 0.2 秒，
    --        完整空窗 = 0.2 秒缓冲 + 第 3 段 0.1 秒缺印确认 = 掉印后 0.3 秒重新亮。
    --   30.2 秒仍严格 > 30 秒真实 Buff，一个 Buff 周期最多亮一次色块，
    --   补印频率不变，所以「反复上印」不会回来。
    if type(last) ~= "number" then return true end
    local lockSeconds = (WR_PaladinForever_SEAL_BUFF_SECONDS or 30)
        + (WR_PaladinForever_SEAL_LOCK_GRACE or 0.2)
    return (GetTime() - last) >= lockSeconds
end

-- ============================================================
-- ★★ 2026-11-09 用户口径：补「常驻圣印」的许可门
-- ------------------------------------------------------------
--   用户真机测试连提两条时机要求：
--     ① 「可以了，但是是脱战的时候上的圣印，我需要在战斗中才使用」
--        —— 补印色块脱战一律不点亮，只在玩家进入战斗后才允许。
--     ② 「并且是近战可以攻击的时候才上圣印」
--        —— 还得有一个存活、可攻击、且在近战范围内的目标；没目标 /
--           目标死了 / 目标够不到（超过 8 码）都不补。
--   与「是否缺印」彻底解耦：缺印判定（ProtSealState / SealMissingSince /
--   fakeUp）照常每 tick 维护，本函数只决定「这一刻能不能把色块亮出去」。
--   这样一进战斗、贴近目标就能立刻补上，不必重新等防抖。
--
--   ★ 距离读不到（WR_UnitRange 返回 999/nil）时按「可攻击」放行：
--     无限 1.60.x 战斗中 unit GUID 可能是 secret，LibRangeCheck 偶尔算不出
--     距离；若据此一律拦截，会出现「进战斗了却永远不补印」的老问题。
--     口径与主循环神圣打击 hsRangeOK 一致（999 视为未知、放行）。
--   ★ 不额外要求 target 已进战斗：圣印本来就在第 5 步战斗门之前处理，
--     玩家进战斗 + 近战能打到目标，即满足「战斗中 + 近战可攻击」。
-- ============================================================
function WR_PaladinForever_CanApplySeal()
    -- 这些全是客户端标准 API / 本插件全局函数，主循环本来就裸调用（见
    -- WR_PaladinForeverProt 开头的 UnitAffectingCombat / WR_UnitRange），
    -- 这里不做 type() 防御，保持与既有代码一致。
    if not UnitAffectingCombat("player") then return false end
    if not UnitExists("target") then return false end
    if not UnitCanAttack("player", "target") then return false end
    if UnitIsDead("target") then return false end
    local range = WR_UnitRange and WR_UnitRange("target") or 999
    range = range or 999
    if type(range) == "number" and range < 999 and range > 8 then
        return false
    end
    return true
end

-- ============================================================
-- ★★ 2026-11-10 用户口径（硬规则）：
--     「循环中任意一个环节，不符合条件就不亮色块，进行下一个循环」
-- ------------------------------------------------------------
--   为什么这条规则是必须的（不是洁癖）：
--     AHK 是「同色常亮就一直按」（约每 60ms 一次）。色块一亮，AHK 就会按键；
--     如果这一发因为「目标太远 / 目标没了 / 目标不可攻击」根本打不出去，
--     客户端就不会回 UNIT_SPELLCAST_SUCCEEDED → 本地 CD 记账不推进 →
--     ShowSkillCD 的 ③ 保守兜底会按 PROMPT_HOLD（1.5 秒）重新点亮 →
--     该环节每 1.5 秒又亮一次，永远排在调度最前面，
--     把后面所有环节全部饿死。真机表现就是「循环卡在一个技能上、别的都不出」。
--
--   所以：凡是需要敌方目标的环节，点亮色块前必须先过本门；
--   过不了就 return false，让主循环继续判断下一个环节（而不是亮了再失败）。
-- ============================================================
-- 各技能有效射程（码）。未登记 = 自身/Buff 类技能，不判射程。
--   ★ 只登记「本服法术书里确有射程限制」的进攻技能；值取经典/TBC 上限，
--     宁宽勿窄：射程判太紧会让技能永远不亮（比亮了打不出去更难排查）。
WR_PaladinForever_SPELL_RANGE = {
    ["攻击"]     = 8,   -- 近战平砍（/startattack）
    ["审判"]     = 10,  -- 神圣伤害审判
    ["神圣打击"] = 8,   -- 近战
    ["制裁之锤"] = 10,  -- 眩晕
    ["愤怒之锤"] = 30,  -- 斩杀
    ["驱邪术"]   = 30,
    ["奉献"]     = 5,   -- 以自身为中心
}

-- 目标是否「存在 + 可攻击 + 活着」（射程之外的另一半门）
--   ★ 与 CanApplySeal 一致：UnitExists / UnitCanAttack / UnitIsDead 都是客户端标准 API，
--     主循环本来就裸调用，这里不做 type() 防御（否则 mock/兼容层下会被误判成不可用）。
function WR_PaladinForever_TargetCastable(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end
    if not UnitCanAttack("player", unit) then return false end
    if UnitIsDead(unit) then return false end
    return true
end

-- 目标是否在某技能射程内。
--   ★ 距离读不到（WR_UnitRange 返回 999/nil）时【放行】：
--     无限 1.60.x 战斗中 unit GUID 可能是 secret，LibRangeCheck 偶尔算不出距离；
--     若据此一律拦截，会退化成「永远不出技能」。口径与 CanApplySeal / hsRangeOK 一致。
function WR_PaladinForever_InSpellRange(spell, unit)
    local maxRange = WR_PaladinForever_SPELL_RANGE and WR_PaladinForever_SPELL_RANGE[spell]
    if not maxRange then return true end          -- 自身/Buff 技能不判射程
    -- ★ 与 CanApplySeal 同一写法：WR_UnitRange 是工程内 Lua 函数，直接按真值调用
    --   （不要用 type()=="function" 判，兼容层下它是 userdata，会被误判成不可用而放行）。
    local range = WR_UnitRange and WR_UnitRange(unit or "target")
    range = tonumber(range) or 999
    if range >= 999 then return true end          -- 读不到 → 放行
    return range <= maxRange
end

-- 统一门：这一刻这一发「真能打出去」吗？
--   返回 false 时，调用方必须【不点亮色块】，并让主循环继续判断下一个环节。
function WR_PaladinForever_CanHitTarget(spell, unit)
    if not WR_PaladinForever_TargetCastable(unit) then return false end
    if not WR_PaladinForever_InSpellRange(spell, unit) then return false end
    return true
end

-- ★ 直接扫描玩家 HELPEFUL 光环，返回：剩余秒数, 扫描是否成功
--   扫描成功但没找到 → (0, true)；API 不可用/secret 抛错 → (nil, false)
local function WR_PaladinForever_PlayerAuraRemain(spellID, auraName)
    if type(C_UnitAuras) ~= "table"
       or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then
        return nil, false
    end
    for i = 1, 40 do
        local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok then return nil, false end
        if not data then return 0, true end
        -- ★ 2026-11-09：无限战斗中 name/spellId 可能是 secret，直接 == 比较会抛错，
        --   必须把比较本身包进 pcall（只包 API 调用不够）。
        local isMatch = false
        if spellID ~= nil then
            local okId, eq = pcall(function() return data.spellId == spellID end)
            if okId and eq then isMatch = true end
        end
        if not isMatch and auraName ~= nil then
            local okName, eq = pcall(function() return data.name == auraName end)
            if okName and eq then isMatch = true end
        end
        if not isMatch then
            -- 名字/ID 是 secret 时无法排除「它就是目标光环」→ 返回未知，不能误判为缺失
            local secretName = type(WR_IsSecretValue) == "function" and WR_IsSecretValue(data.name)
            local secretID = type(WR_IsSecretValue) == "function" and WR_IsSecretValue(data.spellId)
            if secretName or secretID then return nil, false end
        end
        if isMatch then
            local exp = data.expirationTime
            if type(exp) == "number"
               and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(exp)) then
                return exp - GetTime(), true
            end
            return 999, true
        end
    end
    return 0, true
end

-- ★ 监听自己成功施放：记录施放时间（本地冷却 / Ready-first 调度的唯一可靠起点）。
--   ★ 双通道记账：无限战斗中 spellName 可能是 secret 字符串，读不到就什么都记不上，
--     冷却表恒空 → CD 判定失效 → 色块每 1.1 秒亮一次（「CD 中还在一直打」）。
--     因此以数字 spellID 为主通道（按 ID 反查技能名，再写名字+全部 rank ID），
--     事件自带 spellName 可读时作为补充。
WR_PaladinForever_ProtSealCastAt = WR_PaladinForever_ProtSealCastAt or nil
-- ★ 2026-11-08：正义圣印施放计时（旧版常驻圣印兼容回退使用）
WR_PaladinForever_JusticeSealCastAt = WR_PaladinForever_JusticeSealCastAt or nil
-- ★ 2026-11-10：光明圣印施放计时（光明圣印常驻开关使用）
WR_PaladinForever_LightSealCastAt = WR_PaladinForever_LightSealCastAt or nil
-- ★ 2026-11-11：十字军圣印施放计时（十字军审判 buff 维持开关使用）
WR_PaladinForever_CrusaderSealCastAt = WR_PaladinForever_CrusaderSealCastAt or nil
-- ★ 2026-11-11：智慧圣印施放计时（智慧审判 buff 维持开关使用）
WR_PaladinForever_WisdomSealCastAt = WR_PaladinForever_WisdomSealCastAt or nil
-- ★ 2026-11-09：任意圣印最近一次成功施放（审判只要求「有任意圣印」）
WR_PaladinForever_LastSealCastAt = WR_PaladinForever_LastSealCastAt or nil
-- ★★ 2026-11-11：最后一次成功施放的圣印名（「光明圣印」常驻开关判断
--   当前身上是不是光明圣印用；光环不可读时只能靠这条本地记账兜底）
WR_PaladinForever_LastSealAppliedName = WR_PaladinForever_LastSealAppliedName or nil
WR_PaladinForever_FuryCastAt = WR_PaladinForever_FuryCastAt or nil
do
    -- spellID → 技能名（覆盖所有已知 rank；未知 ID 走 C_Spell.GetSpellInfo 兜底）
    local function WR_PaladinForever_NameFromID(sid)
        if type(sid) ~= "number" then return nil end
        local ids = WR_PaladinForever_SpellRankIDs or {}
        for name, list in pairs(ids) do
            for i = 1, #list do
                if list[i] == sid then return name end
            end
        end
        -- ★ 2026-11-09：正义圣印 / 十字军圣印 / 光明圣印等不在静态 rank 表里，
        --   而无限战斗中事件自带的 spellName 可能是 secret（读不到）。
        --   这里用 WR_ResolveSpellID 动态反查当前已学 rank ID，保证本地施放计时不断档。
        --   只在「玩家成功施放」事件里调用，不在每 tick 热路径上，开销可忽略。
        --
        -- ★★ 2026-11-10：补上防护循环的其余技能（奉献 / 驱邪术 / 愤怒之锤 /
        --   制裁之锤 / 圣疗术 / 圣佑术）。
        --   这些技能不在 WR_PaladinForever_SpellRankIDs 静态表里（那里只有 5 项），
        --   一旦战斗中事件自带 spellName 是 secret，本地就完全记不上账：
        --     · ShowSkillCD 的 ① 施放记录通道恒空 → 落到 ③ 保守兜底
        --       （guard = PROMPT_HOLD = 1.5 秒）→ 每次施放成功后仍每 1.5 秒重亮一次
        --       → AHK 同色连按 → 奉献(8s CD)/驱邪术(15s CD) 被明显过量施放；
        --     · 长 CD 的圣疗术(1200s)/圣佑术(300s) 反而反向锁死：一次漏按就整段 CD 不再提示。
        --   这里按「名字→当前 rank ID」动态反查，不写死任何 rank（升级换 rank 也不会失效）。
        if type(WR_ResolveSpellID) == "function" then
            local dynNames = { "正义圣印", "愤怒圣印", "十字军圣印", "命令圣印",
                               "公正圣印", "光明圣印", "智慧圣印", "殉难圣印",
                               "腐蚀圣印", "复仇圣印", "审判", "神圣打击",
                               "奉献", "驱邪术", "愤怒之锤", "制裁之锤",
                               "圣疗术", "圣佑术" }
            for i = 1, #dynNames do
                local nm = dynNames[i]
                local ok, id = pcall(WR_ResolveSpellID, nm)
                if ok and type(id) == "number" and id == sid then return nm end
            end
        end
        local name
        if type(C_Spell) == "table" and type(C_Spell.GetSpellInfo) == "function" then
            local ok, t = pcall(C_Spell.GetSpellInfo, sid)
            if ok and type(t) == "table" and type(t.name) == "string" and t.name ~= "" then
                name = t.name
            end
        end
        if not name and type(GetSpellInfo) == "function" then
            local ok, n = pcall(GetSpellInfo, sid)
            if ok and type(n) == "string" and n ~= "" then name = n end
        end
        if name and type(WR_IsSecretValue) == "function" and WR_IsSecretValue(name) then
            name = nil
        end
        if name then
            name = WR_PaladinForever_StripRankSuffix(name)
        end
        return name
    end

    local function WR_PaladinForever_NormalizeName(nm)
        if type(nm) ~= "string" or nm == "" then return nil end
        if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(nm) then return nil end
        return WR_PaladinForever_StripRankSuffix(nm)
    end

    -- ★★ 2026-11-09：事件自带 spellName 是 secret、且 NameFromID 静态表没覆盖时，
    --   用「已知圣印 ID 反查名字」兜底。否则战斗中成功施放圣印会完全记不上账：
    --   LastSealCastAt 断档 → 下一 tick 又点亮圣印色块 → AHK 反复 /cast 圣印。
    local function WR_PaladinForever_SealNameByID(sid)
        if type(sid) ~= "number" then return nil end
        if type(WR_ResolveSpellID) ~= "function" then return nil end
        for i = 1, #WR_PaladinForever_SealNames do
            local nm = WR_PaladinForever_SealNames[i]
            local ok, id = pcall(WR_ResolveSpellID, nm)
            if ok and type(id) == "number" and id == sid then return nm end
        end
        return nil
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    f:SetScript("OnEvent", function(_, event, unit, castGUID, spellID, spellName)
        if unit ~= "player" then return end
        local sid = spellID
        if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(sid) then
            sid = nil
        end
        sid = tonumber(sid)
        local now = GetTime()

        -- ① 主通道：数字 spellID（先按 ID 记账，保证 CD 判定一定有起点）
        if sid then
            WR_PaladinForever_SkillCastAtByID[sid] = now
        end

        -- ② 解析技能名（事件自带名字优先，其次 ID 反查）
        local name = WR_PaladinForever_NormalizeName(spellName)
        if not name then name = WR_PaladinForever_NameFromID(sid) end
        if not name and sid and WR_PaladinForever_IsSealSpellID(sid) then
            name = WR_PaladinForever_SealNameByID(sid) or "圣印"
        end
        -- ★★ 2026-11-11：若只能认出「这是圣印」但认不出具体哪条
        --   （SealNameByID 反查失败），用刚刚点亮过的圣印色块名补全。
        --   否则 LastSealAppliedName 会被写成泛化的「圣印」，十字军审判 /
        --   光明 / 智慧 buff 维持状态机将永远判「目标圣印不在身上」→ 反复
        --   点亮同一条圣印色块 → AHK 反复施放（用户反馈的「反复使用」）。
        if name == "圣印" then
            local promptedSeal = WR_PaladinForever_ActiveSealPromptName
            if type(promptedSeal) ~= "string" then
                promptedSeal = WR_PaladinForever_SealPromptLitName
            end
            if type(promptedSeal) == "string"
               and string.find(promptedSeal, "圣印", 1, true) then
                name = promptedSeal
            end
        end

        if name then
            WR_PaladinForever_MarkCastAt(name, now)
            -- ★★ 任意圣印成功施放（愤怒/正义/十字军/光明/命令…）都记一笔，
            --   并按 30 秒 Buff 时效阻止重复补印。
            if string.find(name, "圣印", 1, true) then
                WR_PaladinForever_LastSealAppliedName = name
                WR_PaladinForever_NoteSealApplied(now)
                -- ★★ 关键：AHK 是「同色常亮就一直按」（每 ~60ms 一次），
                --   所以打出圣印后必须立刻熄灭【所有】圣印色块，而不是等 3 秒保持到期。
                --   事件名带等级后缀 / 只按 ID 认出时也要能清掉，故按名单全清。
                for i = 1, #WR_PaladinForever_SealNames do
                    WR_PaladinForever_HideNow(WR_PaladinForever_SealNames[i])
                end
                WR_PaladinForever_HideSkillVisual("圣印")
            end
            -- ★ 打出去了就立刻清掉该技能色块（不必等保持时长到期）
            WR_PaladinForever_HideNow(name)
            local cd = WR_PaladinForever_SkillCD and WR_PaladinForever_SkillCD[name]
            if name == "审判" then
                -- 审判 CD 随「强化审判」天赋变化，用实际施放间隔自动校准
                WR_PaladinForever_ProbeJudgeCooldown(now)
                cd = WR_PaladinForever_GetJudgeCooldown()
                -- ★★★ 2026-11-09 第十次修正（最终根因）：本服审判【不消耗】圣印！
                --   证据：用户截图「正义圣印 / 法术ID 20289 / 剩余25秒」时圣印仍在被重上；
                --   且 /mkseal 日志两次上印间隔 8 秒 = 审判 CD（强化审判 2/2）。
                --   旧版（第五次修正）在这里假设「审判消耗圣印」，每次审判成功就把
                --   LastSealCastAt / ProtSealCastAt / JusticeSealCastAt 全部清空 →
                --   下一 tick SealNeedsRefresh 立刻返回 true → 插件点亮 47 号色块
                --   （正义圣印）→ AHK 按 SHIFT-F7 → 重新上印 → 8 秒后审判再来一遍。
                --   这就是用户观察到的「就是亮了对应的色块，就是正义圣印」。
                --   现在：审判成功【绝不清空】圣印计时。圣印是否还在只由
                --   ① 可读光环（up/missing）或 ② 30 秒 Buff 硬锁（unknown 时）判定。
                -- ★★ 2026-11-09 第十一次修正：不再清空玩家光环缓存。
                --   旧代码的 WR_AuraCache["player"] = nil 没有同步清
                --   WR_AuraCacheScanned["player"]，下一 tick 的 WR_EnsureAuraCached
                --   认为已扫描过 → 所有玩家 Buff 短暂读成 0 → 圣印被判 missing。
                --   若此时本地恰好没有施放记录，就会「审判后立刻再补一次圣印」。
                --   审判本来就不消耗圣印，这里无需刷新缓存；即便光环真没了，
                --   0.5 秒的常规缓存刷新也会自然读到 missing。
                WR_PaladinForever_SealScanAt = nil
                WR_PaladinForever_SealScanState = nil
                if WR_PaladinForever_SealBuffStateCache then
                    WR_PaladinForever_SealBuffStateCache.at = nil
                end
            end
            if cd then WR_PaladinForever_TouchCooldown(name, cd) end
            -- ★ 圣印施放成功：愤怒圣印 / 正义圣印 / 光明圣印都记到各自的计时字段，
            --   ProtSealState() 才能正确判断「当前常驻圣印是否在身上」。
            if name == "愤怒圣印" then
                WR_PaladinForever_ProtSealCastAt = now
                WR_PaladinForever_SealScanAt = nil
                WR_PaladinForever_SealScanState = nil
            elseif name == "正义圣印" then
                WR_PaladinForever_JusticeSealCastAt = now
                WR_PaladinForever_SealScanAt = nil
                WR_PaladinForever_SealScanState = nil
            elseif name == "光明圣印" then
                WR_PaladinForever_LightSealCastAt = now
                WR_PaladinForever_SealScanAt = nil
                WR_PaladinForever_SealScanState = nil
            elseif name == "十字军圣印" then
                WR_PaladinForever_CrusaderSealCastAt = now
                WR_PaladinForever_SealScanAt = nil
                WR_PaladinForever_SealScanState = nil
            elseif name == "智慧圣印" then
                WR_PaladinForever_WisdomSealCastAt = now
                WR_PaladinForever_SealScanAt = nil
                WR_PaladinForever_SealScanState = nil
            elseif name == "正义之怒" then
                WR_PaladinForever_FuryCastAt = now
            end
            -- ★ 祝福不在这里做本地记账：祝福会被驱散/被同类祝福覆盖，
            --   本地「刚施放过」记录会把已驱散误判成仍在，导致不再提示补祝福。
            --   祝福是否还在，只由 WR_PaladinForever_BlessingUp() 读 Buff 判定。
        elseif sid == 1311656 or sid == 20423 then
            WR_PaladinForever_ProtSealCastAt = now
            WR_PaladinForever_LastSealAppliedName = "愤怒圣印"
            WR_PaladinForever_NoteSealApplied(now)
            WR_PaladinForever_HideNow("愤怒圣印")
        elseif sid == 25780 then
            WR_PaladinForever_FuryCastAt = now
            WR_PaladinForever_HideNow("正义之怒")
        elseif sid and WR_PaladinForever_IsSealSpellID(sid) then
            -- 只剩数字 ID、名字完全读不到：仍要记一笔并熄灭圣印色块，
            -- 否则本地 30 秒窗口断档 → 下一 tick 又亮 → AHK 反复上印。
            -- ★★ 2026-11-11：按 spellID 反查出具体圣印名（能反查到时），
            --   同时写该圣印的专用计时与 LastSealAppliedName；否则十字军审判等
            --   buff 维持状态机会一直判「圣印不在身上」→ 反复点亮同一条圣印。
            local byID = WR_PaladinForever_SealNameByID(sid)
            if not WR_PaladinForever_RecordSealAppliedByName(byID, now) then
                WR_PaladinForever_NoteSealApplied(now)
            end
            for i = 1, #WR_PaladinForever_SealNames do
                WR_PaladinForever_HideNow(WR_PaladinForever_SealNames[i])
            end
            WR_PaladinForever_HideSkillVisual("圣印")
        else
            -- ★★ 终极兜底：战斗中 spellID / spellName 都是 secret（完全认不出），
            --   但此刻正好亮着圣印色块 / 或刚刚（1 秒内）点亮过圣印色块 —— 那这次事件
            --   几乎必然是 AHK 按下了圣印键。按「圣印已打出」处理：记 30 秒窗口 +
            --   立刻熄灭全部圣印色块。1 秒窗口覆盖「色块已灭但事件回报稍晚」的时序差，
            --   否则 30 秒记账断档 → 下一 tick 又亮 → AHK 反复上印（用户反馈的「反复使用」）。
            local hold = WR_PaladinForever_PromptHold
            local litAt = WR_PaladinForever_SealPromptLitAt
            local litRecently = type(litAt) == "number" and (GetTime() - litAt) < 1.0
            local holdHot = false
            if hold then
                for i = 1, #WR_PaladinForever_SealNames do
                    local untilAt = hold[WR_PaladinForever_SealNames[i]]
                    if untilAt and GetTime() < untilAt then holdHot = true break end
                end
            end
            if holdHot or litRecently then
                -- ★★ 2026-11-11：用「刚刚点亮过的圣印色块名」反推这次事件按的是
                --   哪条圣印，写进它专用的 CastAt 与 LastSealAppliedName。
                --   否则十字军审判/光明/智慧 buff 维持状态机在光环不可读时
                --   永远判「圣印不在身上」→ 每 1~2 秒重新点亮同一条圣印
                --   → AHK 反复施放同一条圣印（用户反馈的「反复使用十字军圣印」）。
                local promptedSeal = WR_PaladinForever_ActiveSealPromptName
                if type(promptedSeal) ~= "string" then
                    promptedSeal = WR_PaladinForever_SealPromptLitName
                end
                if not WR_PaladinForever_RecordSealAppliedByName(promptedSeal, now) then
                    WR_PaladinForever_NoteSealApplied(now)
                end
                for j = 1, #WR_PaladinForever_SealNames do
                    WR_PaladinForever_HideNow(WR_PaladinForever_SealNames[j])
                end
                WR_PaladinForever_HideSkillVisual("圣印")
            end
        end
    end)
end

-- ★ 正义之怒是否已存在（30 分钟 Buff，只在缺失时补一次）
--   ★ 关键修复（反复施放正义之怒）：
--     ① 原实现把「光环缓存存在」当成权威判据并**提前 return false**，
--        导致「刚施放过」的兜底记录永远轮不到 → 战斗中光环读不到（secret）时反复提示；
--     ② FuryCastAt 只由「施放成功事件」写入，不再由「提示」写入 ——
--        提示只做防刷屏，施放成功才记 30 分钟，这样玩家漏按一次仍能重试。
--   判定顺序：光环扫描 → 缓存剩余 → 施放成功记录（30 分钟） → false。
function WR_PaladinForever_FuryUp()
    -- ① 直接扫玩家 HELPFUL 光环（脱战/可读时最准）
    local remain, scanOK = WR_PaladinForever_PlayerAuraRemain(25780, "正义之怒")
    if scanOK then
        return remain ~= nil and remain > 0
    end

    -- ② 光环缓存里的剩余时间
    local cached = WR_GetUnitBuffTime("player", "正义之怒")
    if cached and cached > 0 then return true end

    -- ③ ★ 施放成功记录（30 分钟内一律视为已开启）
    --    必须在「光环缓存缺失」之前，否则战斗中读不到光环时会反复提示。
    if WR_PaladinForever_FuryCastAt
       and (GetTime() - WR_PaladinForever_FuryCastAt) < 1800 then
        return true
    end

    -- ④ 光环缓存明确扫过且没有 → 真的缺
    return false
end

-- ★ 防护：常驻圣印状态（供主调度审判门控 / /mkseal 诊断使用）
--   返回 "up"=有任意圣印 / "missing"=缺印或 Buff 到期。
--   ★★ 2026-11-11：常驻圣印由面板「圣印」专区按钮（FH_SEAL，6 个单选按钮）统一选择；
--     旧的 FH_GMSY / FH_ZYSY 两个复选框已移除（仍保留读取回退，兼容旧存档/夹具）。
--     施放计时由 WR_PaladinForever_LastSealAppliedAt() 统一取最晚者。
--   ★★ 2026-11-09 第四次修正：本服圣印是 30 秒短 Buff（截图剩余25秒），
--     旧版按 1800 秒(30 分钟)记账是错的：要么 Buff 已到期还判 up 不补，
--     要么光环 secret 读不到时靠 1/8 秒防抖反复补印。现按 30 秒时效重写。
--     判定统一走 WR_PaladinForever_SealBuffState()（任意圣印，含等级后缀）。
function WR_PaladinForever_ProtSealState()
    local s = WR_PaladinForever_SealBuffState()
    if s == "up" then return "up" end   -- 任意圣印在身上就算 up（不再强行切回常驻）
    -- ★★ 2026-11-09 第十一次修正：真实读到过的 Buff 未到期 → 判 up，避免审判后假 missing
    local knownUntil = WR_PaladinForever_SealBuffKnownUntil
    if type(knownUntil) == "number" and GetTime() < knownUntil then
        return "up"
    end
    -- ★★ 2026-11-09 第六次修正：本服某些圣印光环读不到（权威 missing），
    --   但「刚成功施放过」更可信。本地记录在一个 Buff 周期内 → 视为 up，
    --   与 AnySealUp / SealNeedsRefresh 判定一致，避免「判定冲突」导致的反复上印。
    --   ★ 2026-11-09 第十次修正：本服审判不消耗圣印，审判成功不再清空本地记录。
    local last = WR_PaladinForever_LastSealAppliedAt()
    if type(last) == "number"
       and (GetTime() - last) < WR_PaladinForever_SEAL_BUFF_SECONDS then
        return "up"
    end
    if s == "missing" then return "missing" end
    -- 光环不可读且无近期记录 → 缺印
    return "missing"
end

function WR_PaladinForever_ProtSealUp()
    return WR_PaladinForever_ProtSealState() == "up"
end

-- ★★ 2026-11-11：防护常驻圣印由面板「圣印」专区的 6 个按钮选择，默认 3=愤怒圣印。
--   用户口径：「圣印我不喜欢下拉框的，给我设置成按钮，单独弄一个圣印专区，
--   此专区在爆发区下，可以折叠」。按钮为单选：点击某个按钮即把 FH_SEAL 写成对应序号。
--   顺序必须与 Paladin_Menu.lua 的 FH_SEAL 六项严格一致：
--   1=十字军圣印(30) 2=正义圣印(47) 3=愤怒圣印(11)
--   4=光明圣印·回血(54) 5=智慧圣印·回蓝(108) 6=公正圣印(9)
--   返回：圣印名, 颜色槽位, 施放成功时间字段名
--   注意：愤怒圣印的审判带嘲讽（坦克仇恨来源）；换正义/光明等后审判不再嘲讽。
--   兼容：旧存档 FH_GMSY / FH_ZYSY 仍作为只读回退（供未走迁移的夹具/旧环境）；
--   正常客户端由 ZZ_Features_Migration 先迁移到 FH_SEAL 并清空旧字段。
WR_PaladinForever_SealOptions = {
    [1] = { "十字军圣印", 30, "CrusaderSealCastAt" },
    [2] = { "正义圣印", 47, "JusticeSealCastAt" },
    [3] = { "愤怒圣印", 11, "ProtSealCastAt" },
    [4] = { "光明圣印", 54, "LightSealCastAt" },
    [5] = { "智慧圣印", 108, "WisdomSealCastAt" },
    [6] = { "公正圣印", 9, "LastSealCastAt" },
}

function WR_PaladinForever_MainSeal()
    local idx = tonumber(PigSet and PigSet.FH_SEAL)
    if not idx then
        -- 兼容旧存档 / 离线夹具：FH_GMSY=true → 4（光明·回血）；FH_ZYSY=true → 2（正义）；否则 3。
        if PigSet and PigSet.FH_GMSY == true then
            idx = 4
        elseif PigSet and PigSet.FH_ZYSY == true then
            idx = 2
        else
            idx = 3
        end
    end
    local opt = WR_PaladinForever_SealOptions[idx]
    if not opt then opt = WR_PaladinForever_SealOptions[3] end
    return opt[1], opt[2], opt[3]
end

-- ★★ 2026-11-11：圣印选择从下拉框改为「圣印」专区按钮后，/FH_SEAL 不再由
--   下拉框控件自动注册，这里保留同名命令（旧宏继续可用）。
--   用法：/FH_SEAL 1..6（1=十字军 2=正义 3=愤怒 4=光明 5=智慧 6=公正）
SLASH_FH_SEAL1 = "/FH_SEAL"
SlashCmdList["FH_SEAL"] = function(msg)
    local n = tonumber(msg or "")
    if n == nil then
        -- 兼容旧下拉命令：不带数字时循环到下一项
        n = (tonumber(PigSet and PigSet.FH_SEAL) or 3) + 1
        if n > #WR_PaladinForever_SealOptions then n = 1 end
    end
    local opt = WR_PaladinForever_SealOptions[n]
    if not opt then
        print("|cff00ff00[圣印]|r 用法：/FH_SEAL 1-6（1=十字军 2=正义 3=愤怒 4=光明 5=智慧 6=公正）")
        return
    end
    PigSet = PigSet or {}
    PigSet.FH_SEAL = n
    if type(WR_ConfigRadio_Refresh) == "function" then
        WR_ConfigRadio_Refresh("FH_SEAL")
    end
    print("|cff00ff00[圣印]|r 已选择常驻圣印：" .. opt[1] .. "（槽 " .. tostring(opt[2]) .. "）")
end

-- ★ 目标是否为亡灵/恶魔（驱邪术仅对这两类有效）
function WR_PaladinForever_IsUndeadOrDemon(unit)
    if type(UnitCreatureType) ~= "function" then return false end
    local ct
    if type(WR_SafeCreatureType) == "function" then
        ct = WR_SafeCreatureType(unit or "target")
    else
        local ok, v = pcall(UnitCreatureType, unit or "target")
        if ok and type(v) == "string"
           and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(v)) then
            ct = v
        end
    end
    if not ct then return false end
    return ct == "亡灵" or ct == "恶魔" or ct == "Undead" or ct == "Demon"
end

-- ★ 目标是否正在可打断的施法/引导（用于制裁之锤）
--   无限 12.x：UnitCastingInfo 的 name 可能是 secret string、
--   notInterruptible 可能是 secret boolean，直接做条件判断会抛错。
function WR_PaladinForever_TargetCasting()
    local function IsSecret(v)
        return type(WR_IsSecretValue) == "function" and WR_IsSecretValue(v) == true
    end
    if type(UnitCastingInfo) == "function" then
        local ok, name, _, _, _, _, _, _, notInterruptible = pcall(UnitCastingInfo, "target")
        if ok and type(name) == "string" and not IsSecret(name) and not IsSecret(notInterruptible) then
            if notInterruptible ~= true then return true end
        end
    end
    if type(UnitChannelInfo) == "function" then
        local ok, name, _, _, _, _, _, notInterruptible = pcall(UnitChannelInfo, "target")
        if ok and type(name) == "string" and not IsSecret(name) and not IsSecret(notInterruptible) then
            if notInterruptible ~= true then return true end
        end
    end
    return false
end

function WR_PaladinForever_InCombatGate(allowAddFlag)
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    if inBossEncounter then return true end
    if UnitAffectingCombat("player") and TargetInCombat then
        if allowAddFlag == nil or allowAddFlag then return true end
    end
    return false
end

function WR_PaladinForever_HasDispel()
    return (WR_GetUnitDebuffTime("player", "中毒") > 0)
        or (WR_GetUnitDebuffTime("player", "疾病") > 0)
        or (WR_GetUnitDebuffTime("player", "魔法") > 0)
        or (WR_GetUnitDebuffTime("player", "诅咒") > 0)
end

-- ★ 共享：圣印保持（无限：无符文限制，按单体/多目标选印）
--   战斗中外加 8 秒本地提示 CD，避免圣印 buff 不可读时每 tick 重复提示。
function WR_PaladinForever_Seal(unitCount8)
    -- ★★ 2026-11-09 第十一次修正：圣印提示保护窗口（与防护循环一致），
    --   防止刚亮的圣印色块被下一 tick 的其他技能提示顶掉。
    if WR_PaladinForever_RefreshSealPrompt() then return true end
    -- ★★ 2026-11-09 用户口径：与防护循环一致，补印只在「战斗中 + 近战可攻击」时进行，
    --   脱战 / 没目标 / 够不到目标一律不点亮圣印色块（换专精时行为一致）。
    if not WR_PaladinForever_CanApplySeal() then return false end
    -- ★★ 2026-11-09：任意圣印在身上 / 30 秒内刚上过印 → 一律不再补。
    --   旧版只枚举 6 个圣印名 + 8 秒防抖，光明/智慧/腐蚀/复仇等圣印在身上时
    --   仍会每 8 秒提示一次别的圣印，AHK 同色连按就会反复施放。
    if not WR_PaladinForever_SealNeedsRefresh(nil) then return false end
    if not WR_PaladinForever_CanPrompt("圣印", 3) then return false end
    if unitCount8 and unitCount8 >= 3 and WR_SpellUsable("正义圣印") then
        if WR_PaladinForever_ShowSealBlock("正义圣印", 47) then
            WR_PaladinForever_MarkPrompt("圣印", 47)
            WR_PaladinForever_MarkPrompt("正义圣印", 47)
            WR_PaladinForever_HideSkillLater("正义圣印", 47, 1.0)
            return true
        end
    end
    if WR_SpellUsable("十字军圣印") then
        if WR_PaladinForever_ShowSealBlock("十字军圣印", 30) then
            WR_PaladinForever_MarkPrompt("圣印", 30)
            WR_PaladinForever_MarkPrompt("十字军圣印", 30)
            WR_PaladinForever_HideSkillLater("十字军圣印", 30, 1.0)
            return true
        end
    elseif WR_SpellUsable("命令圣印") then
        if WR_PaladinForever_ShowSealBlock("命令圣印", 12) then
            WR_PaladinForever_MarkPrompt("圣印", 12)
            WR_PaladinForever_MarkPrompt("命令圣印", 12)
            WR_PaladinForever_HideSkillLater("命令圣印", 12, 1.0)
            return true
        end
    end
    return false
end

-- ★ 共享：审判（必须有圣印才亮色块；不再判断目标 debuff）
--   CD 不写死：随「强化审判」天赋在 10 / 8 秒之间变化，由 GetJudgeCooldown 运行时探测。
function WR_PaladinForever_Judge()
    if WR_PaladinForever_SealActive() and WR_SpellUsable("审判", true) then
        if WR_PaladinForever_ShowSkillCD("审判", 33, WR_PaladinForever_GetJudgeCooldown()) then
            return true
        end
    end
    return false
end

-- ★ 共享：判断某技能是否已学会（中文名安全版）
--   ★ 关键：无限 1.60.x 的 IsPlayerSpell / C_Spell.* 只认数字 spellID，
--     直接传中文名恒返回 false。所以必须先把名字解析成 ID 再问客户端。
--   顺序：① WR_ResolveSpellID 解析出 ID → ② 依次问 IsPlayerSpell / IsSpellKnown
--         ③ 解析不到 ID 时，退回 WR_Forever_IsSpellKnown（它内部会再试一次）
--         ④ 全部失败且该名字在「无限存在」名单里 → 保守返回 true
--            （宁可提示一次让玩家自己判断，也不要因为 API 不认名字而永久静默）
function WR_PaladinForever_SpellKnown(spellName)
    if type(spellName) ~= "string" or spellName == "" then return false end

    -- ① 先解析成 spellID
    local sid
    if type(WR_ResolveSpellID) == "function" then
        local okR, v = pcall(WR_ResolveSpellID, spellName)
        if okR and type(v) == "number" then sid = v end
    end

    -- ② 有 ID：直接问客户端（无限下这是唯一可靠的路径）
    if sid then
        if type(IsPlayerSpell) == "function" then
            local ok, res = pcall(IsPlayerSpell, sid)
            if ok and res then return true end
        end
        if type(IsSpellKnown) == "function" then
            local ok, res = pcall(IsSpellKnown, sid)
            if ok and res then return true end
        end
        -- ★★ 2026-11-10：单 ID 查不到时，按该技能的全部 rank 再问一遍。
        --   有些技能（神圣打击 8 个 rank）解析到的 ID 可能不是角色当前 rank；
        --   只要任意一个 rank 已学会，就不能把整个技能判死。
        local ids = WR_PaladinForever_SpellRankIDs and WR_PaladinForever_SpellRankIDs[spellName]
        if ids then
            for i = #ids, 1, -1 do
                local id = ids[i]
                if type(IsPlayerSpell) == "function" then
                    local ok, res = pcall(IsPlayerSpell, id)
                    if ok and res then return true end
                end
                if type(IsSpellKnown) == "function" then
                    local ok, res = pcall(IsSpellKnown, id)
                    if ok and res then return true end
                end
            end
        end
        -- ★★ 2026-11-10：最后兜底——法术书里确实存在这个 spellID 就视为已学会。
        --   无限客户端的 IsPlayerSpell / IsSpellKnown 对部分 rank 可能返回不可靠的 false，
        --   但法术书索引来自客户端真实数据，存在即已学（尤其用于神圣打击换 rank 后的识别）。
        if type(WR_Forever_SpellBookList) == "table" then
            local knownIDs = {}
            for i = 1, #WR_Forever_SpellBookList do
                local e = WR_Forever_SpellBookList[i]
                if type(e) == "table" and type(e.id) == "number" then
                    knownIDs[e.id] = true
                end
            end
            if knownIDs[sid] then return true end
            if ids then
                for i = 1, #ids do
                    if knownIDs[ids[i]] then return true end
                end
            end
        end
        return false
    end

    -- ③ 解析不到 ID：退回通用检测（含按名/按 ID 多级兜底）
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, res = pcall(WR_Forever_IsSpellKnown, spellName)
        if ok and res then return true end
    end

    -- ④ 最后兜底：不在「无限不存在」名单里就当作可用
    if WR_Forever_SkillAbsent and WR_Forever_SkillAbsent[spellName] then
        return false
    end
    return true
end

-- ★ 共享：无限天赋技能（已学会才提示），避免把没点天赋的技能硬塞给玩家
function WR_PaladinForever_Talent(spellName, slot)
    if WR_PaladinForever_SpellKnown(spellName) and WR_SpellUsable(spellName, true) then
        if WR_ColorFrame_ShowSkill(spellName, slot) then
            WR_PaladinForever_MarkPrompt(spellName, slot)
            WR_PaladinForever_HideSkillLater(spellName, slot, 1.0)
            return true
        end
    end
    return false
end

-- ★ 调试命令：/mkpal（查看正义之怒 / 审判 CD / 神圣打击 的判定实况）
--   用于区分「光环读不到」与「本地记账失效」两类问题，避免再盲改。
SLASH_MKPAL1 = "/mkpal"
SlashCmdList["MKPAL"] = function()
    local now = GetTime()
    -- ★ 2026-11-08 修复：原此处直接调 WR_PaladinForever_PlayerAuraRemain，
    --   但那是文件内 local 函数、且定义在第 837 行（本命令之前）→ 运行时为 nil 报错。
    --   改用公开的 FuryUp() 判定，并只展示安全可读的信息。
    local furyUp = WR_PaladinForever_FuryUp()
    local furyCast = WR_PaladinForever_FuryCastAt
    local furyAgo = furyCast and string.format("%.0f秒前", now - furyCast) or "无记录"
    print("|cff00ff00[MKPAL]|r 正义之怒：判定已开启=" .. tostring(furyUp)
        .. " 上次施放=" .. furyAgo
        .. " 光环剩余=" .. tostring(WR_GetUnitBuffTime("player", "正义之怒")))
    print("|cff00ff00[MKPAL]|r 审判CD=" .. tostring(WR_PaladinForever_GetJudgeCooldown())
        .. " 天赋已点=" .. tostring(WR_PaladinForever_IsJudgeTalentKnown())
        .. " 上次施放=" .. tostring(WR_PaladinForever_GetLastCastAt("审判") and
            string.format("%.0f秒前", now - WR_PaladinForever_GetLastCastAt("审判")) or "无"))
    local hsAt = WR_PaladinForever_GetLastCastAt("神圣打击")
    print("|cff00ff00[MKPAL]|r 神圣打击：上次施放=" .. (hsAt and string.format("%.0f秒前", now - hsAt) or "无")
        .. " 客户端剩余=" .. tostring(WR_PaladinForever_ClientCooldownLeft("神圣打击"))
        .. " 解析ID=" .. tostring(type(WR_ResolveSpellID) == "function" and WR_ResolveSpellID("神圣打击") or "?")
        .. " 已学会=" .. tostring(WR_PaladinForever_SpellKnown("神圣打击")))
    -- ★ 2026-11-09：常驻圣印诊断（排查「进战斗第一轮不打审判」）
    local sealName, sealSlot, sealField = WR_PaladinForever_MainSeal()
    local sealState = WR_PaladinForever_ProtSealState()
    local sealAt = sealField and _G["WR_PaladinForever_" .. sealField] or nil
    print("|cff00ff00[MKPAL]|r 常驻圣印：" .. tostring(sealName)
        .. " 槽位=" .. tostring(sealSlot)
        .. " 状态=" .. tostring(sealState)
        .. " 任意圣印=" .. tostring(WR_PaladinForever_SealActive())
        .. " Buff剩余=" .. tostring(WR_GetUnitBuffTime("player", sealName))
        .. " 上次施放=" .. (sealAt and string.format("%.0f秒前", now - sealAt) or "无记录"))
    -- 祝福：当前菜单选中的那条 + Buff 读值（祝福只信 Buff 判定，被驱散后应重新提示）
    local zf = tonumber(PigSet and PigSet.FH_ZF) or 7
    local rec = WR_PaladinForever_BlessingList[zf]
    if rec then
        print("|cff00ff00[MKPAL]|r 祝福：菜单选中=" .. rec.name
            .. " 判定已上=" .. tostring(WR_PaladinForever_BlessingUp(rec.name))
            .. " Buff剩余=" .. tostring(WR_GetUnitBuffTime("player", rec.name)))
    end
    -- ★ 2026-11-11：十字军审判 buff 维持开关诊断（原单体循环诊断已随功能删除）
    local crusaderID
    if type(WR_ResolveSpellID) == "function" then
        local ok1, v1 = pcall(WR_ResolveSpellID, "十字军圣印")
        if ok1 then crusaderID = v1 end
    end
    print("|cff00ff00[MKPAL]|r 十字军审判：开关=" .. tostring(PigSet and PigSet.FH_SZJSP)
        .. " 阶段=" .. tostring(WR_PaladinForever_CrusaderSealPhase)
        .. " 十字军圣印ID=" .. tostring(crusaderID)
        .. " 已学=" .. tostring(WR_PaladinForever_SpellKnown("十字军圣印"))
        .. " 审判已学=" .. tostring(WR_PaladinForever_SpellKnown("审判")))
    -- ★★ 2026-11-11：智慧审判 buff 维持开关诊断
    local wisdomID
    if type(WR_ResolveSpellID) == "function" then
        local ok2, v2 = pcall(WR_ResolveSpellID, "智慧圣印")
        if ok2 then wisdomID = v2 end
    end
    print("|cff00ff00[MKPAL]|r 智慧审判：开关=" .. tostring(PigSet and PigSet.FH_ZHSP)
        .. " 阶段=" .. tostring(WR_PaladinForever_WisdomJudgementPhase)
        .. " 智慧圣印ID=" .. tostring(wisdomID)
        .. " 已学=" .. tostring(WR_PaladinForever_SpellKnown("智慧圣印"))
        .. " 审判已学=" .. tostring(WR_PaladinForever_SpellKnown("审判")))
    -- ★ 2026-11-08：焦点异常诊断（排查「战斗中自动设焦点」）
    local focusName = UnitExists("focus") and (UnitName("focus") or "?") or "无"
    local focusIsPlayer = UnitExists("focus") and UnitIsPlayer("focus") or false
    local fci = WR_FocusCast_Info
    print("|cff00ff00[MKPAL]|r 焦点：当前=" .. tostring(focusName)
        .. " 是玩家=" .. tostring(focusIsPlayer)
        .. " FocusCast活跃=" .. tostring(fci and fci.active)
        .. " 目标=" .. tostring(fci and fci.unit)
        .. " 技能=" .. tostring(fci and fci.spell))
    -- 跟随系统状态（另一个会自动设/跟随焦点的来源）
    print("|cff00ff00[MKPAL]|r 跟随：开关=" .. tostring(PigSet and PigSet.AUTO_FOLLOW_ENABLED)
        .. " 锚点GUID=" .. tostring(PigSet and PigSet.AUTO_FOLLOW_GUID and "有" or "无")
        .. " 目标设置=" .. tostring(PigSet and PigSet.AUTO_FOLLOW_TARGET))
    -- ★ 2026-11-09：/focus 宏门控状态（AHK 误发键时的最后一道防线）
    --   跟随关闭 → 所有 /focus 宏被降级为空宏，AHK 误发只是空按；
    --   跟随开启 → 宏恢复原文，正常设焦点。
    local reg = WR_FocusMacroRegistry
    if reg then
        local gated = 0
        for i = 1, #reg do
            if WR_ShouldGateFocusMacro and WR_ShouldGateFocusMacro(reg[i].text) then
                gated = gated + 1
            end
        end
        print("|cff00ff00[MKPAL]|r /focus 宏门控：已登记=" .. #reg
            .. " 当前被拦截=" .. gated
            .. (gated > 0 and "（跟随关闭 → 这些键按下也不执行任何动作）" or "（跟随开启 → 设焦键正常）"))
    end
    -- ★ 2026-11-08：/focus 类宏触发记录（决定性证据：谁按了 /focus）
    local ml = WR_FocusMacroLog
    if ml and #ml > 0 then
        print("|cff00ff00[MKPAL]|r /focus 宏触发记录（共 " .. #ml .. " 条，最新在后）：")
        local from = math.max(1, #ml - 5)
        for i = from, #ml do
            print("   " .. ml[i])
        end
    else
        print("|cff00ff00[MKPAL]|r /focus 宏触发记录：无（说明焦点不是由插件宏设置的）")
    end
    -- 最近一次焦点变化记录（由 /mkpaltrack 开启的追踪器捕获）
    local lg = WR_PaladinForever_FocusLog
    if lg and #lg > 0 then
        print("|cff00ff00[MKPAL]|r 最近焦点变化（共 " .. #lg .. " 条，最新在后）：")
        local from = math.max(1, #lg - 3)
        for i = from, #lg do
            print("   " .. lg[i])
        end
    else
        print("|cff00ff00[MKPAL]|r 焦点变化记录：无（先输入 /mkpaltrack 开启追踪）")
    end
end
