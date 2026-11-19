-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "PALADIN" then return end
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
        -- ★★★ 2026-11-18 看门狗（用户口径「防骑循环存在失效的情况」）：
        --   Forever 12.x 战斗上下文里单位字段大量 secret 化，任何一处裸比较抛
        --   "attempt to compare a secret ..." 都会让本 tick 的防护循环当场中断，
        --   表现为「循环失效」（该 tick 什么都不提示）。这里用 pcall 包住整个
        --   防护循环：出错时限频打印一次现场（默认 5 秒一次，防刷屏），
        --   循环下一 tick 自动继续，不再被单次抛错打死。
        --   惩戒/神圣分支不包：它们的读条路径不同，保持原派发行为，便于定位。
        local okProt, errProt = pcall(WR_PaladinForeverProt)
        if not okProt then
            local nowW = GetTime()
            if not WR_PaladinForeverProtWatchdogAt
               or (nowW - WR_PaladinForeverProtWatchdogAt) > 5 then
                WR_PaladinForeverProtWatchdogAt = nowW
                print("|cffff8800[防骑看门狗]|r 循环本轮中断：" .. tostring(errProt))
            end
        end
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
-- ★★ 圣印色块专用保持/保护上限（秒）。AHK 是「同色常亮就一直按」：扫描 30ms +
--   随机冷却 33~44ms ⇒ 约 60ms 一次。保持太久会被连按放大成反复施放；
--   保持太短（<0.1s）则 AHK 可能一次都没读到 → 漏按 → 表现为「战斗中又没挂圣印」。
--   ★ 2026-11-09 第十一次修正：0.2 秒名义保持其实只够 1 个游戏帧——主循环下一 tick
--     的「神圣打击」等提示会调用 WR_ColorFrame_Show，而它会先隐藏所有色块，把刚亮
--     的圣印顶掉；AHK 直接漏按。改为 0.3 秒，并由 WR_PaladinForever_RefreshSealPrompt
--     在窗口内每 tick 重亮圣印色块、阻止其他提示覆盖。
--   ★★ 2026-11-14 用户口径「防骑目前上圣印经常被顶，导致无法使用出圣印，将圣印优先级调高」：
--     0.3 → 1.0 秒。0.3 秒在真机上只够 3 个主循环 tick（100ms/tick），AHK 扫屏或
--     按键稍有抖动就会被下一 tick 的审判/神圣打击色块覆盖 → 圣印一直补不上。
--     1.0 秒覆盖约 10 个 tick，远大于 AHK 一次扫屏+按键周期；且严格小于圣骑士
--     1.5 秒 GCD，一个提示窗口内最多只会成功施放一次圣印，不会回到「同色常亮连按
--     50 次」的老问题。成功施放事件到达后 HideNow 仍会立即熄灭，不额外占 GCD。
WR_PaladinForever_SEAL_PROMPT_HOLD = 1.0

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

    -- ★★★ 2026-11-12 用户口径「技能不够蓝释放时，应当不亮色块，导致一直按按键」：
    --   骑士的蓝量在战斗中是 secret（WR_GetUnitMP 恒降级为 1），自己算不出够不够，
    --   但 WR_ColorFrame_ShowSkill 的总闸会拦（资源算术 + 客户端「法力不足」回执）。
    --   这里必须【在拦下时熄灭本技能的色块】：色块模型是「亮着就一直按」，
    --   只 return false 不熄灭的话，上一 tick 亮着的色块会一直挂着 → AHK 连按。
    --   用 pcall 探测（不用 type()=="function"：本仓库夹具里是 userdata）。
    if WR_SoD_NotEnoughPower ~= nil then
        local okN, notEnough = pcall(WR_SoD_NotEnoughPower, spell)
        if okN and notEnough == true then
            WR_PaladinForever_ClearPromptShown(spell)
            if WR_HideSkillColorSlot ~= nil then
                pcall(WR_HideSkillColorSlot, spell, slot)
            end
            return false
        end
    end

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
    -- ★★ 2026-11-16：制裁之锤全部 4 个 rank（Forever 法术书：853/5588/5589/10308）。
    --   打断滑条的本地 60 秒 CD 依赖「施放成功按 ID 记账」，缺 rank 会让战斗内
    --   spellName 为 secret 时记不上账，色块按 20 秒兜底重试。
    ["制裁之锤"] = { 853, 5588, 5589, 10308 },
    -- ★★ 2026-11-13：截图实测 愤怒之锤 Rank1 = 24275（斩杀 <20%，本地 6 秒 CD）。
    --   战斗中 UNIT_SPELLCAST_SUCCEEDED 的 spellName 可能是 secret，按 ID 记账
    --   才能保证愤怒之锤的本地 6 秒 CD 正常推进（与神圣之盾同一处理）。
    -- ★★★ 2026-11-14：补全 Rank2/3（24274/24239，Forever DB 实测：44/52/60 级）。
    --   当前 rank 换级后施放事件上报的是新 rank ID；只登记 Rank1 会让 6 秒本地 CD 断档（色块反复亮）。
    ["愤怒之锤"] = { 24275, 24274, 24239 },
    -- ★★ 2026-11-18：驱邪术全部 rank。战斗中事件按「当前 rank ID」上报；缺表时
    --   本地 15 秒 CD 无记录 → 每次施放后 1.5 秒又重亮 → AHK 同色连按、过量施放。
    ["驱邪术"] = { 879, 699, 1160, 5232, 10404, 10405, 10314 },
    -- ★ 2026-11-15：奶骑 60 级新技能（圣光守望 / 圣光誓约）
    --   战斗中 UNIT_SPELLCAST_SUCCEEDED 的 spellName 可能是 secret，按 ID 记账才能
    --   保证本地 CD / 施放确认正常推进。
    ["圣光守望"] = { 1311595, 1310911 },
    ["圣光誓约"] = { 1328548 },
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

-- ============================================================
-- ★★ 2026-11-12 防骑 buff 维持开关的「切印窗口」
-- ------------------------------------------------------------
-- 用户口径原话：
--   「修正各项维持buff常驻开关切圣印的时机，当审判cd还有2秒钟恢复使用时
--     目标没有对应审判buff，这时候再切选择的对应圣印打审判，
--     不要第一时间开启了维持审判buff的开关后就切对应圣印等审判使用」
-- 含义：
--   ① 勾选「光明圣印 / 十字军审判 / 智慧审判」开关后，**不立刻**切对应圣印；
--   ② 只有「审判 CD 剩余 ≤ 2 秒（含已就绪）」且目标没有对应审判 debuff 时，
--      才切对应圣印 → 打审判；
--   ③ 其余时间一律维持面板「圣印」专区所选常驻圣印（仇恨/嘲讽来源不断档）。
-- 为什么：旧逻辑一勾选（或 40 秒 debuff 一到期）就切走常驻圣印，然后干等
--   审判 CD 转好（最长近 10 秒），这段时间没有常驻圣印的仇恨/嘲讽收益。
-- ============================================================
WR_PaladinForever_JUDGE_SWITCH_LEAD = 2.0

-- 审判距离可用还剩多少秒：0 = 已就绪 / 无记录 / 读不到
--   ★ 每个 tick 内会被多次调用（三个状态机 + ProtSealGoal + 主调度让出判断），
--     用 now 做单 tick 记忆，避免重复走 GetJudgeCooldown 的 API 探测。
function WR_PaladinForever_JudgementRemain(cd)
    local now = GetTime()
    local memo = WR_PaladinForever_JudgeRemainMemo
    if type(memo) == "table" and memo.at == now then
        return memo.value
    end
    -- ★★★ 2026-11-17 用户口径「防骑审判buff维持不灵敏」修复：
    --   客户端剩余冷却【可读】时（脱战 / 非 secret 客户端）直接以客户端为准。
    --   旧版优先用本地账（castAt + cdv），cdv 来自天赋探测（8/10 秒），
    --   探测一有偏差，「审判剩余 ≤ 2 秒」切印窗口就整体提前/延后：
    --     · cdv 偏小 → 窗口提前开，切印后审判实际还在 CD，打不出去；
    --     · cdv 偏大 → 窗口推迟，审判 buff 掉了迟迟不补 —— 表现为「维持不灵敏」。
    --   客户端读不到（战斗中 secret）时仍退回本地账，与旧行为一致。
    local remain
    local left = WR_PaladinForever_ClientCooldownLeft("审判")
    if type(left) == "number" then
        remain = left
        if remain < 0 then remain = 0 end
    else
        local cdv = tonumber(cd)
        if not cdv or cdv <= 0 then
            cdv = WR_PaladinForever_GetJudgeCooldown()
        end
        local castAt = WR_PaladinForever_GetLastCastAt("审判")
        if not castAt then
            remain = 0
        else
            remain = (castAt + cdv) - now
            if remain < 0 then remain = 0 end
        end
    end
    WR_PaladinForever_JudgeRemainMemo = { at = now, value = remain }
    return remain
end

-- 是否进入「可以切 buff 圣印」的窗口（审判剩余 ≤ lead 秒，含已就绪）
function WR_PaladinForever_JudgementSwitchDue(cd, lead)
    local l = tonumber(lead) or WR_PaladinForever_JUDGE_SWITCH_LEAD or 2.0
    return WR_PaladinForever_JudgementRemain(cd) <= l + 1e-6
end

-- ★★★ 2026-11-17 用户口径「防骑审判buff维持不灵敏」：审判「真就绪」双通道判定
--   本地 CD 记账（castAt + cdv）与客户端剩余冷却（脱战 / 非 secret 时可读）交叉：
--   · 客户端可读且仍在 CD → 立即判未就绪（防止本地 cdv 偏小导致的空按/无效提示）；
--   · 客户端可读且已就绪 → 直接判就绪（防止本地账偏大导致的迟迟不提示）；
--   · 客户端读不到（战斗中 secret）→ 退回本地记账，与旧行为一致。
function WR_PaladinForever_JudgeTrulyReady()
    local left = WR_PaladinForever_ClientCooldownLeft("审判")
    if type(left) == "number" then
        return left <= 0.05
    end
    return WR_PaladinForever_Ready("审判", WR_PaladinForever_GetJudgeCooldown())
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
        local cap = WR_PaladinForever_SEAL_PROMPT_HOLD or 1.0
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
    -- ★★★ 2026-11-14 用户口径：「防骑圣印应该修改为能平砍的时候才挂自身圣印，
    --   不然会出现空放圣印的情况」。
    --   不能平砍 = 没有敌对活目标 / 目标在平砍射程外 → 这时点亮圣印色块就是空放：
    --   AHK 会照着色块连按 /cast 圣印，白烧一个 GCD 和蓝，却打不到任何东西。
    --   这里做成统一出口门：所有圣印色块（补印 / 切印 / 切回 / 插入）都必须先过。
    if type(WR_PaladinForever_CanMeleeSwing) == "function"
       and not WR_PaladinForever_CanMeleeSwing() then
        WR_PaladinForever_HideNow(skillName, slot)
        return false
    end
    local shown = WR_ColorFrame_ShowSkill(skillName, slot)
    if shown then
        -- ★★ 2026-11-09 第十一次修正：记录当前「圣印提示保护窗口」。
        --   HideSkillLater 会紧接着补上 Until；窗口内 RefreshSealPrompt 持续重亮，
        --   避免被下一 tick 的其他技能提示瞬间覆盖（AHK 漏按的根因）。
        -- ★★ 2026-11-14：点亮即写入保护截止时间（不再依赖调用方一定调 HideSkillLater）。
        --   保护窗口 = WR_PaladinForever_SEAL_PROMPT_HOLD（现 1.0 秒），期间
        --   RefreshSealPrompt 每 tick 重亮圣印并让循环直接 return true，
        --   任何其它技能提示都顶不掉这块圣印色块。
        WR_PaladinForever_ActiveSealPromptName = skillName
        WR_PaladinForever_ActiveSealPromptSlot = slot
        WR_PaladinForever_ActiveSealPromptBypass =
            (type(bypassUntil) == "number" and GetTime() <= bypassUntil) and true or false
        WR_PaladinForever_ActiveSealPromptUntil =
            GetTime() + (WR_PaladinForever_SEAL_PROMPT_HOLD or 1.0)
        WR_PaladinForever_SealPromptShownCount = (WR_PaladinForever_SealPromptShownCount or 0) + 1
        WR_PaladinForever_SealPromptShownAt = GetTime()
    end
    return shown
end

-- ★★ 2026-11-09 第十一次修正：圣印提示保护窗口。
--   背景：WR_ColorFrame_Show 每次会先隐藏【所有】色块；主循环下一 tick 只要
--   点亮「神圣打击」等任意提示，就会把刚亮起的圣印色块顶掉。0.2 秒的保持在此
--   情况下实际只剩 1 个游戏帧，AHK 扫描不到 → 玩家看到「战斗中又没挂圣印」。
--   现在：圣印色块亮起后的保护窗口内（WR_PaladinForever_SEAL_PROMPT_HOLD，
--   2026-11-14 起为 1.0 秒），Prot/共享循环每 tick 先调用本函数重亮
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
    -- ★★★ 2026-11-14 用户口径：「防骑圣印应该修改为能平砍的时候才挂自身圣印，
    --   不然会出现空放圣印的情况」。
    --   保护窗口内也要每 tick 复查「能平砍」：目标跑远 / 目标死亡 / 切走目标时，
    --   立即熄灭圣印色块并清掉窗口，不能让 AHK 在剩下的窗口里继续连按空放。
    if type(WR_PaladinForever_CanMeleeSwing) == "function"
       and not WR_PaladinForever_CanMeleeSwing() then
        WR_PaladinForever_HideNow(name, slot)
        WR_PaladinForever_ActiveSealPromptName = nil
        WR_PaladinForever_ActiveSealPromptSlot = nil
        WR_PaladinForever_ActiveSealPromptUntil = nil
        WR_PaladinForever_ActiveSealPromptBypass = nil
        return false
    end
    if not WR_ColorFrame_ShowSkill(name, slot) then
        WR_PaladinForever_ActiveSealPromptName = nil
        WR_PaladinForever_ActiveSealPromptSlot = nil
        WR_PaladinForever_ActiveSealPromptUntil = nil
        WR_PaladinForever_ActiveSealPromptBypass = nil
        return false
    end
    return true
end

-- ============================================================
-- ★★★ 2026-11-19 用户口径「防骑正义之怒要第一优先级，buff 一消失第一时间就要补」：
--   判定（FuryUp）修好之后，还剩「点亮了但被顶掉」这一层：
--   WR_ColorFrame_Show 每次会先隐藏【所有】色块 —— 正义之怒色块刚亮起，
--   下一 tick 的圣印保护窗口 / 审判 / 神圣打击任意一处点亮就会把它顶掉，
--   AHK 扫不到 → 不按 → 表现仍是「buff 没了不补」。
--   因此正义之怒也需要自己的短保护窗口（与圣印同一套思路，独立记录，
--   互不覆盖）：窗口内每 tick 重亮同一色块并让循环直接 return true；
--   施放成功（FuryUp 转 true）或窗口到期立即熄灭。
-- ============================================================
WR_PaladinForever_FURY_PROMPT_HOLD = 1.0
WR_PaladinForever_FuryPromptSlot = WR_PaladinForever_FuryPromptSlot or nil

-- 点亮正义之怒色块（单次，不重亮）。
--   ★ 为什么不学圣印做「窗口内每 tick 重亮」：
--     圣印重亮是因为它排在循环末尾、会被前面的技能顶掉；正义之怒现在是
--     全循环第一条，不会有任何分支能顶它。而每 tick 重亮 = 色块常亮 =
--     AHK 每 ~60ms 按一次 /cast 正义之怒（老的「反复施放」bug）。
--     所以只亮一次 + 1.0 秒保持 + 3 秒 CanPrompt 防抖，施放成功立刻熄灭。
function WR_PaladinForever_ShowFuryPrompt(slot)
    local useSlot = slot or 31
    if not WR_ColorFrame_ShowSkill("正义之怒", useSlot) then return false end
    WR_PaladinForever_FuryPromptSlot = useSlot
    return true
end

function WR_PaladinForever_ClearFuryPrompt()
    local slot = WR_PaladinForever_FuryPromptSlot or 31
    WR_PaladinForever_FuryPromptSlot = nil
    WR_PaladinForever_HideNow("正义之怒", slot)
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

-- ★ 2026-11-11 弃用说明：以下 BlessingList / BlessingUp / Blessing / ProtBlessing
--   是旧「祝福下拉框」时代的补祝福实现，循环已全部改走 Paladin_Blessing.lua 的
--   WR_PaladinBlessing_Auto()（独立设置列表 + 单人/小队/团队自动补）。
--   这里保留仅为兼容历史夹具与可能的外部引用，不再被任何专精循环调用。
--   本服法术 ID（2026-11-06 实测；智慧祝福 2026-11-12 按截图修正为 19850）：
--     力量祝福 19834 / 智慧祝福 19850 / 王者祝福 20217
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
            -- ★★★ 2026-11-18：死亡会移除正义之怒（30 分钟 Buff）。旧实现只清圣印计时，
            --   FuryCastAt 仍留着「30 分钟内视为已开启」的记账 → 战斗中战复后 FuryUp()
            --   靠这条记录把「已消失」判成「仍在」，整场战斗都不补。
            --   死亡即清空记账与观测投影，复活后第一时间补。
            WR_PaladinForever_FuryCastAt = nil
            WR_PaladinForever_FuryLastUpAt = nil
            WR_PaladinForever_FuryLastUpRemain = nil
            -- ★ 2026-11-19：tooltip 通道的节流与缓存同步清空，战复后第一 tick 就能重判
            WR_PaladinForever_FuryTooltipAt = 0
            WR_PaladinForever_FuryTooltipCache = nil
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
--      （每 ~60ms 重按一次，色块亮 1.0 秒 = 约 16 次 /cast；施放成功事件会立即熄块，
--      但仍不应靠多点色块来补印）。因此只要插件多点亮
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

-- ★★★ 2026-11-14：由 spellID 反查具体圣印名。
--   战斗中光环 name 可能是 secret，但 spellId 仍是数字：SealBuffState 过去只能
--   返回 "up", nil，导致 LightSealOnPlayer() / 常驻圣印判定不知道身上是哪条
--   （典型：目标已有圣光审判、身上是光明圣印、面板选愤怒 —— 永远不切回愤怒）。
--   这里按 WR_PaladinForever_SealNames 动态解析当前 rank，与 IsSealSpellID 同一数据源。
function WR_PaladinForever_SealNameBySpellID(sid)
    if type(sid) ~= "number" then return nil end
    -- 不写 type(...)=="function"：离线夹具里 WR_ResolveSpellID 可能是可调用 userdata
    if WR_ResolveSpellID == nil then return nil end
    for i = 1, #WR_PaladinForever_SealNames do
        local nm = WR_PaladinForever_SealNames[i]
        local ok, id = pcall(WR_ResolveSpellID, nm)
        if ok and type(id) == "number" and id == sid then return nm end
    end
    return nil
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
            if not Expired(data) then
                -- ★★★ 2026-11-14：返回由 spellID 反查的圣印名（name 可能 secret）
                return "up", WR_PaladinForever_SealNameBySpellID(sid), RemainOf(data)
            end
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
                    -- ★★★ 2026-11-14：名字是 secret 时按 spellId 反查具体圣印名，
                    --   否则 state=up/name=nil 会让「身上是光明圣印」永远判不出来。
                    local displayName = nm
                    if type(displayName) ~= "string" then
                        displayName = WR_PaladinForever_SealNameBySpellID(aura and aura.spellId)
                    end
                    c.state, c.name = "up", displayName
                    WR_PaladinForever_NoteSealBuffRemain(left)
                    WR_PaladinForever_NoteSealAuraReadUp(displayName)
                    if type(displayName) == "string" then
                        WR_PaladinForever_SealAuraSeenUp[displayName] = true
                        -- 兼容「正义圣印（等级 2）」：同时按去后缀基名记一次
                        local base = WR_PaladinForever_StripRankSuffix(displayName)
                        if base ~= displayName then
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
--   返回 true 时调用方仍需过 CanApplySeal（战斗中 + 能平砍）与提示防抖。
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
-- ★★★ 2026-11-14 用户口径：「防骑圣印应该修改为能平砍的时候才挂自身圣印，
--   不然会出现空放圣印的情况」。
--   「能平砍」判定（圣印是自身 Buff，放出去不验证目标，所以必须由插件自己确认
--   这一发打得到东西，否则就是空放）：
--     ① 有敌对活目标：TargetCastable —— 存在 + 可攻击 + 非尸体/ghost；
--        统一尸体判定后，目标已死 / 尸体 / ghost 时不再挂印（旧的裸 UnitIsDead
--        真值判断拿不到 secret 的确认 true，尸体目标会被当活体放行）。
--     ② 目标在近战平砍距离内：复用「攻击」的射程登记（8 码），
--        距离读不到（999 / secret）按全项目口径放行 —— 否则无限服战斗中
--        会退化成永远不补印。
--   返回 false 时：不点亮任何圣印色块（补印 / 切印 / 切回 / 插入统一口径）。
function WR_PaladinForever_CanMeleeSwing()
    if not WR_PaladinForever_TargetCastable("target") then return false end
    if not WR_PaladinForever_InSpellRange("攻击", "target") then return false end
    return true
end

function WR_PaladinForever_CanApplySeal()
    -- 脱战绝不点亮：补印只发生在战斗中（旧口径不变）。
    if not UnitAffectingCombat("player") then return false end
    -- ★★★ 2026-11-14：原实现自带一套 target 存在 / UnitCanAttack / 裸 UnitIsDead /
    --   8 码判定，和「能不能平砍」不是同一套口径（尸体漏判、距离写法分叉）。
    --   现在统一交给 CanMeleeSwing，保证「能平砍才挂自身圣印」。
    return WR_PaladinForever_CanMeleeSwing()
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

-- ============================================================
-- ★★★ 2026-11-13：目标「确认死亡 / 尸体」统一判定（审判 buff 尸体空放修复）
-- ------------------------------------------------------------
--   用户口径：「勾选后，当目标已死亡且显示为尸体时，仍会切换所选圣印并尝试释放审判」。
--   根因：TargetCastable / CanApplySeal / 状态机 phase4 全部只做裸 `if UnitIsDead(...) then`
--     真值判断——① 12.0 战斗中单位状态型接口可能返回 secret boolean（哑值），
--     裸真值拿不到「确认的 true」时，尸体被当成活体放行；② 整条链从未查
--     UnitIsGhost（本服尸体目标可能挂在 ghost 态上，UnitIsDead 读不到 true）。
--   口径（与射程 999/secret 放行一致）：只有【确认死亡】才拦——
--     UnitIsDead / UnitIsDeadOrGhost / UnitIsGhost 任一明确回答 true → 死亡；
--     另加「血量读得到且 ≤0」兜底；读不到（secret / API 缺失 / 抛错）一律放行。
-- ============================================================
function WR_PaladinForever_UnitIsDeadOrGhost(unit)
    if type(unit) ~= "string" or unit == "" then return false end
    -- ① 单位状态三接口：任何一个明确回答 true → 死亡。
    --   ★ secret 比较会抛错：比较本身也要包 pcall（与 WR_PalBless_Plain 兜底探针同思路）；
    --   ★ 兼容层下这些 API 可能是 userdata，只做 ~= nil 判存在（同 InSpellRange 的 WR_UnitRange 口径）。
    local fns = {}
    if UnitIsDead ~= nil then fns[#fns + 1] = UnitIsDead end
    if UnitIsDeadOrGhost ~= nil then fns[#fns + 1] = UnitIsDeadOrGhost end
    if UnitIsGhost ~= nil then fns[#fns + 1] = UnitIsGhost end
    for i = 1, #fns do
        local ok, v = pcall(fns[i], unit)
        if ok then
            local okC, eq = pcall(function() return v == true end)
            if okC and eq == true then return true end
        end
    end
    -- ② 血量兜底：读得到且确认为 0 → 死亡；读不到 / secret → 放行（见上方口径）。
    if UnitHealth ~= nil then
        local okH, hp = pcall(UnitHealth, unit)
        if okH then
            local okN, isZero = pcall(function() return type(hp) == "number" and hp <= 0 end)
            if okN and isZero == true then return true end
        end
    end
    return false
end

-- 目标是否「存在 + 可攻击 + 活着」（射程之外的另一半门）
--   ★ 与 CanApplySeal 一致：UnitExists / UnitCanAttack / UnitIsDead 都是客户端标准 API，
--     主循环本来就裸调用，这里不做 type() 防御（否则 mock/兼容层下会被误判成不可用）。
function WR_PaladinForever_TargetCastable(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end
    if not UnitCanAttack("player", unit) then return false end
    -- ★★★ 2026-11-13：死亡/尸体判定改走统一门 WR_PaladinForever_UnitIsDeadOrGhost——
    --   裸 UnitIsDead 真值判断拿不到 secret 的「确认 true」，且从未查 UnitIsGhost，
    --   尸体（含 ghost 态）目标被当成活体放行 → 审判 buff 状态机对着尸体切圣印/亮审判。
    --   读不到一律放行，口径与射程 999/secret 一致；活体目标行为不变。
    if WR_PaladinForever_UnitIsDeadOrGhost(unit) then return false end
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
-- ★ 2026-11-16：正义之怒「最后确实看到 Buff 还在」的观测记录（用户口径：
--   无论战斗/脱战，只要 Buff 消失了就要立马补）。可读时记录剩余秒数；
--   战斗 secret 读不到光环时按「观测时刻 + 剩余」推算到期，到期即判缺失立刻补。
WR_PaladinForever_FuryLastUpAt = WR_PaladinForever_FuryLastUpAt or nil
WR_PaladinForever_FuryLastUpRemain = WR_PaladinForever_FuryLastUpRemain or nil
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
                               "圣疗术", "圣佑术",
                               "保护之手", "牺牲之手", "自由之手", "拯救之手",
                               -- ★★ 2026-11-13（奶骑）：治疗技能也必须能在
                               --   战斗中按 spellID 反查出名字，否则：
                               --   ① ShowSkillCD 的「施放记录通道」拿不到起点 →
                               --      圣光术/闪现每次施放后还会按 1.5 秒窗口重亮
                               --      → AHK 同色连按 → 反复读条、蓝量雪崩；
                               --   ② 施放成功就收不掉色块，读条期间又亮新色块
                               --      → 打断自己的治疗读条（白烧蓝、治疗量 0）。
                               "圣光术", "圣光闪现", "神圣震击", "神恩术",
                               "清洁术", "圣盾术", "圣光守望", "圣光誓约", "真理之声" }
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
    -- ★★★ 2026-11-15：换目标权威信号。必须在 unit ~= "player" 早退之前处理
    --   （PLAYER_TARGET_CHANGED 的第二参数是 "target"，不是 "player"）。
    --   递增 TargetEpoch + 尽力重建目标 key 快照，供审判按目标记账在
    --   「事件时刻 GUID secret」时仍能落账到正确目标（实战第二版修复）。
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:SetScript("OnEvent", function(_, event, unit, castGUID, spellID, spellName)
        if event == "PLAYER_TARGET_CHANGED" then
            if type(WR_PaladinForever_NoteTargetChanged) == "function" then
                WR_PaladinForever_NoteTargetChanged()
            end
            -- ★★ 2026-11-17：换目标瞬间探测新目标类型（能读就刷新 memo，
            --   读不到就清）——驱邪术「亡灵/恶魔」判定靠它把进战前读到的
            --   类型带进受限战斗上下文，同时防止旧目标类型误套新目标。
            if type(WR_PaladinForever_NoteTargetTypeProbe) == "function" then
                WR_PaladinForever_NoteTargetTypeProbe()
            end
            return
        end
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
                -- ★★★ 2026-11-13（v2）：按施放瞬间身上的圣印记「单审判槽位」本地账，
                --   战斗中目标 debuff 不可读时供 JudgementAllowed 兜底（光明/智慧互斥）。
                if type(WR_PaladinForever_NoteSingleSlotJudgement) == "function" then
                    local judgeSeal = WR_PaladinForever_LastSealAppliedName
                    if judgeSeal == "光明圣印" then
                        WR_PaladinForever_NoteSingleSlotJudgement("light",
                            now + (WR_PaladinForever_SINGLE_JUDGEMENT_SECONDS or 40))
                    elseif judgeSeal == "智慧圣印" then
                        WR_PaladinForever_NoteSingleSlotJudgement("wisdom",
                            now + (WR_PaladinForever_SINGLE_JUDGEMENT_SECONDS or 40))
                    elseif judgeSeal == "十字军圣印" then
                        WR_PaladinForever_NoteSingleSlotJudgement("crusader",
                            now + (WR_PaladinForever_SINGLE_JUDGEMENT_SECONDS or 40))
                    end
                end
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
                -- ★ 重新施放成功：清掉旧观测投影，30 分钟窗口重新起算
                WR_PaladinForever_FuryLastUpAt = nil
                WR_PaladinForever_FuryLastUpRemain = nil
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
            -- ★ 重新施放成功：清掉旧观测投影，30 分钟窗口重新起算
            WR_PaladinForever_FuryLastUpAt = nil
            WR_PaladinForever_FuryLastUpRemain = nil
            -- ★ 2026-11-19：tooltip 判定缓存与节流也一起重置，
            --   否则施放前那一帧「明确不在」的缓存会压住刚打上的 Buff 3 秒。
            WR_PaladinForever_FuryTooltipAt = 0
            WR_PaladinForever_FuryTooltipCache = nil
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

-- ★ 正义之怒是否已存在（30 分钟 Buff）
--   ★★ 2026-11-16 用户口径：无论战斗/脱战，只要 Buff 消失了就要立马补——
--     不再被「30 分钟施放成功记录」硬撑（记录只在完全读不到证据时兜底）。
--   ★ 关键修复（反复施放正义之怒）：
--     ① 原实现把「光环缓存存在」当成权威判据并**提前 return false**，
--        导致「刚施放过」的兜底记录永远轮不到 → 战斗中光环读不到（secret）时反复提示；
--     ② FuryCastAt 只由「施放成功事件」写入，不再由「提示」写入 ——
--        提示只做防刷屏，施放成功才记 30 分钟，这样玩家漏按一次仍能重试。
--   判定顺序：光环扫描 → GetPlayerAuraBySpellID 直查 → 缓存剩余 → 观测投影到期 → 施放成功记录（30 分钟兜底） → false。
--
-- ★★★ 2026-11-18 用户口径「防骑正义之怒 Buff 如果不存在了，一定要第一时间补」：
--   原有判定只剩两条能确认「缺失」的路：光环扫描（战斗 secret 时整条返回未知）
--   和观测投影（只有看到过剩余时间才有效）。两者都失效时靠 ④ 的 30 分钟施放记录
--   硬撑 —— 死亡/战复、被驱散、竞技场重置都会让 Buff 真的消失，却被这条记录判成
--   「仍在」，整场战斗都不补。
--   新增 ②：C_UnitAuras.GetPlayerAuraBySpellID(25780) 直查（与清洁术「已知 ID
--   直查」同一实证）。该 API 的 nil 语义按客户端真实行为区分（EUI
--   EllesmereUIAuraBuffReminders 同源实证，本服 12.x）：
--     · 白名单 ID（NON_SECRET_SPELL_IDS）战斗中可直读；非白名单 ID 战斗中可能被
--       秘密旗挡住 → 返回 nil（哪怕 Buff 还在）。
--     · 因此「nil = 明确不在」只在两种情况成立：① 脱战（OOC 的 nil 就是不在）；
--       ② 本场战斗曾明确读到过这个 ID（说明对该 ID 可见），此后 nil 才是真没了。
--     · 其余情况一律当「未知」，沿用 30 分钟记录兜底 —— 绝不据此反复点亮。
WR_PaladinForever_FuryByIDCombatOK = WR_PaladinForever_FuryByIDCombatOK or false

-- 返回：true = 明确在身上（第二返回值为 auraData）
--       false = 明确不在身上
--       nil   = 读不到/API 缺失/调用被拒/战斗中不可见（未知，绝不作缺失依据）
function WR_PaladinForever_FuryByIDAura(inCombat)
    if type(C_UnitAuras) ~= "table" then return nil end
    local fn = C_UnitAuras.GetPlayerAuraBySpellID
    if fn == nil then return nil end
    local ok, aura = pcall(fn, 25780)
    if not ok then return nil end
    if aura ~= nil then
        -- 正证据：战斗中也能读到 → 记下「本场战斗对该 ID 可见」
        if inCombat then
            WR_PaladinForever_FuryByIDCombatOK = true
        end
        return true, aura
    end
    if inCombat and not WR_PaladinForever_FuryByIDCombatOK then
        return nil   -- 战斗中看不见 ≠ 不在身上
    end
    return false
end

-- ★★★ 2026-11-19 用户口径「防骑正义之怒要第一优先级，buff 一消失第一时间就要补」：
--   前几版「缺失确认」只剩两条路：
--     ① HELPFUL 光环扫描 —— 战斗中 name/spellId 是 secret → 整条返回未知；
--     ② C_UnitAuras.GetPlayerAuraBySpellID —— 非白名单 ID 战斗中可能被秘密旗挡住
--        返回 nil（哪怕 Buff 还在），只有「本场战斗曾读到过」之后 nil 才可信。
--   两条都失效时只能靠 ④「30 分钟施放成功记录」硬撑 → 被驱散 / 战复 /
--   竞技场重置 / 跨场景重载后 Buff 真的没了，却被判成「仍在」，
--   玩家看到的就是「buff 消失了不补」。
--
--   本条新增第三条缺失确认通道：C_TooltipInfo 提示数据流。
--   引擎 C 侧组装 tooltip 数据，不受 DenyTaintedAccessWhenAurasAreSecret 限制 ——
--   与清洁术 CleanseTooltipScan 走 GetUnitDebuffByIndex 是同一实证
--   （!Pig Tooltip.lua 321 / PartyMemberFrame.lua 366 生产可用）。
--   GetUnitBuffByIndex 逐槽位读玩家 HELPFUL 提示：
--     · 顶层 data.id == 25780，或提示行「法术ID: 25780」→ 明确在身（true）；
--     · 扫到第一个空槽位、且全程没有任何 secret / 读不到 → 明确不在（false）；
--     · 出现 secret / 调用被拒 → nil（未知）。绝不用未知判缺失，
--       否则每次点亮后都判「没打上」→ AHK 连按（老的「反复施放正义之怒」bug）。
--   0.5 秒节流：战斗中每 tick（0.1 秒）都扫 40 个槽位没必要，且被拒时会更糟。
WR_PaladinForever_FuryTooltipAt = WR_PaladinForever_FuryTooltipAt or 0
WR_PaladinForever_FuryTooltipCache = WR_PaladinForever_FuryTooltipCache or nil

function WR_PaladinForever_FuryByTooltip()
    local now = GetTime()
    if now - (WR_PaladinForever_FuryTooltipAt or 0) < 0.5 then
        return WR_PaladinForever_FuryTooltipCache
    end
    WR_PaladinForever_FuryTooltipAt = now
    WR_PaladinForever_FuryTooltipCache = nil
    local C_TI = C_TooltipInfo
    if type(C_TI) ~= "table" then return nil end
    -- 兼容序：GetUnitBuffByIndex（12.x）→ GetUnitBuff → GetUnitAuraByIndex
    local scanFn = C_TI.GetUnitBuffByIndex or C_TI.GetUnitBuff or C_TI.GetUnitAuraByIndex
    if scanFn == nil then return nil end
    local sawUnknown = false
    local spellIDFromLines = WR_PaladinForever_SpellIDFromTooltipLines
    for i = 1, 40 do
        local ok, data = pcall(scanFn, "player", i)
        if not ok then
            -- 调用被拒（受限拒绝 / 实现差异）：整条未知，绝不据此判缺失
            return nil
        end
        if data == nil then
            -- 扫到空槽位 = 玩家 HELPFUL 列表结束。全程没有未知 → 明确不在身上。
            local result
            if sawUnknown then result = nil else result = false end
            WR_PaladinForever_FuryTooltipCache = result
            return result
        end
        -- 证据一：顶层 data.id（引擎组装，受限内容里通常仍可读）
        local idReadable = false
        local okId, topId = pcall(function() return data.id end)
        if okId and type(topId) == "number" then
            local idSecret = type(WR_IsSecretValue) == "function" and WR_IsSecretValue(topId)
            if not idSecret then
                idReadable = true
                if topId == 25780 then
                    WR_PaladinForever_FuryTooltipCache = true
                    return true
                end
            end
        end
        -- 证据二：提示行「法术ID: N」（顶层 id 被 secret 挡住时的替代证据）
        local sidReadable = false
        if type(spellIDFromLines) == "function" then
            local sid = spellIDFromLines(data)
            if sid ~= nil then
                sidReadable = true
                if sid == 25780 then
                    WR_PaladinForever_FuryTooltipCache = true
                    return true
                end
            end
        end
        -- 两条证据都读不到这一格 → 无法排除它就是正义之怒 → 整轮记未知。
        -- 只要有一格读得懂，就说明本客户端对 HELPFUL 提示是可读的，
        -- 空槽位才是「列表结束」的可信信号（绝不因 lines 缺失就判未知，
        -- 那会让每一格都变未知 → 永远判不出缺失 → 又不补了）。
        if not idReadable and not sidReadable then
            sawUnknown = true
        end
    end
    -- 40 个槽位全非空（异常/超多 buff）：无法确认列表结束 → 未知
    return nil
end

function WR_PaladinForever_FuryUp()
    local now = GetTime()
    local inCombat = false
    local okC, inC = pcall(UnitAffectingCombat, "player")
    if okC and inC == true then inCombat = true end
    -- ① 直接扫玩家 HELPFUL 光环（脱战/可读时最准）
    local remain, scanOK = WR_PaladinForever_PlayerAuraRemain(25780, "正义之怒")
    if scanOK then
        if remain ~= nil and remain > 0 then
            WR_PaladinForever_FuryLastUpAt = now
            WR_PaladinForever_FuryLastUpRemain = remain
            return true
        end
        -- ★ 明确扫过且没有 → 连同 30 分钟记账与观测投影一起清掉：
        --   否则下面的 ④ 兜底会把「已消失」重新判成「仍在」，Buff 再也补不上。
        WR_PaladinForever_FuryCastAt = nil
        WR_PaladinForever_FuryLastUpAt = nil
        WR_PaladinForever_FuryLastUpRemain = nil
        return false
    end

    -- ② GetPlayerAuraBySpellID 直查（战斗中可读时无需遍历光环，也不受字段 secret 影响）
    local byID, furyAura = WR_PaladinForever_FuryByIDAura(inCombat)
    if byID == true then
        WR_PaladinForever_FuryLastUpAt = now
        local exp = furyAura and furyAura.expirationTime
        local expOK = type(exp) == "number"
            and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(exp))
        if expOK and (exp - now) > 0 then
            WR_PaladinForever_FuryLastUpRemain = exp - now
        end
        return true
    elseif byID == false then
        -- 明确不在身上：清空 30 分钟记账与观测投影 → 本次返回 false，下一 tick 立刻补
        WR_PaladinForever_FuryCastAt = nil
        WR_PaladinForever_FuryLastUpAt = nil
        WR_PaladinForever_FuryLastUpRemain = nil
        return false
    end

    -- ②b ★★★ 2026-11-19：C_TooltipInfo 提示数据流直查（免读回、免秘密旗）。
    --   战斗中 ① 光环扫描与 ② GetPlayerAuraBySpellID 双双返回未知时，
    --   这是唯一还能给出「明确不在」的证据来源。明确不在 → 清空 30 分钟记账
    --   与观测投影，本 tick 立即点亮（用户口径「buff 一消失第一时间补」）。
    local tipState = WR_PaladinForever_FuryByTooltip()
    if tipState == true then
        WR_PaladinForever_FuryLastUpAt = now
        return true
    elseif tipState == false then
        -- ★ 施放宽限窗口：刚成功施放 3 秒内，光环可能还没同步到客户端，
        --   tooltip 这时读到「不在」不代表没打上。直接判缺失会让色块反复点亮
        --   → AHK 连按（老的「反复施放正义之怒」bug）。宽限内按未知处理，
        --   交回 ④「施放成功记录」兜底。
        local castAt = WR_PaladinForever_FuryCastAt
        if castAt and (now - castAt) < 3.0 then
            tipState = nil
        end
    end
    if tipState == false then
        WR_PaladinForever_FuryCastAt = nil
        WR_PaladinForever_FuryLastUpAt = nil
        WR_PaladinForever_FuryLastUpRemain = nil
        return false
    end

    -- ③ 光环缓存里的剩余时间
    --   ★ 2026-11-19：加 type 守卫 —— 该函数由 Core/Core_Functions.lua 提供，
    --   加载顺序/裁剪夹具里可能不存在；裸调会抛错并被防骑看门狗吞掉，
    --   表现为整条循环这一 tick 什么都不提示（「循环失效」）。
    --   ★ 用 ~= nil 而不是 type=="function"：离线夹具与部分客户端把 C API
    --   暴露成可调用 userdata，type() 不一定是 "function"（本文件既有约定）。
    local cached
    if WR_GetUnitBuffTime ~= nil then
        cached = WR_GetUnitBuffTime("player", "正义之怒")
    end
    if cached and cached > 0 then
        WR_PaladinForever_FuryLastUpAt = now
        WR_PaladinForever_FuryLastUpRemain = cached
        return true
    end

    -- ③ 观测投影：secret 战斗态按最后一次真实观测推算到期，到期即缺失
    if WR_PaladinForever_FuryLastUpAt
       and WR_PaladinForever_FuryLastUpRemain
       and (now - WR_PaladinForever_FuryLastUpAt) >= WR_PaladinForever_FuryLastUpRemain then
        return false
    end

    -- ④ 施放成功记录（30 分钟内一律视为已开启）——仅在无任何可读/投影证据时兜底
    if WR_PaladinForever_FuryCastAt
       and (now - WR_PaladinForever_FuryCastAt) < 1800 then
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
-- ★★ 2026-11-17 修复「防骑不打驱邪术（亡灵/恶魔怪不亮）」：
--   Forever 12.x 客户端 UI 文档实证：UnitCreatureType 标注
--   SecretWhenUnitIdentityRestricted —— 战斗/受限上下文里返回值是 secret，
--   旧版 WR_SafeCreatureType 把它收敛成 nil → 本函数恒 false →
--   单体链与多目标链共用的 exorcismEligible 恒 false → 永不提示驱邪术。
--   类型判定只接受直读或由直读建立的缓存证据：
--   ① 直读：UnitCreatureType 返回 {名字, id}。id 是客户端枚举
--      （3=恶魔 / 6=亡灵），比按中文名匹配更稳（免本地化）；
--      名字通道保留 亡灵/恶魔/Undead/Demon 匹配，兼容旧桩与经典客户端。
--   ② 同目标 memo：直读成功时记 {TargetEpoch, 时刻, 结论}；同一目标
--      （TargetEpoch 未变）后续直读失败（进战后变 secret）时沿用 memo。
--      覆盖主流程：进战前选目标（可读，memo 记下）→ 进战 → 仍能判对。
--   ③ 怪名缓存：直读成功且怪名可读时按怪名学习（WR_PaladinForever_CreatureTypeByName）；
--      受限时 UnitName 走的是另一条受限通道（SecretWhenUnitNameIdentityRestricted），
--      名字若仍可读则查缓存命中。
--   ④ 类型全部读不到 → false。技能可用性不等于目标类型，禁止据此放行；
--      IsUsableSpell / C_Spell.IsSpellUsable 仅供独立的技能就绪检查使用。
--   换目标由 PLAYER_TARGET_CHANGED 事件里的 WR_PaladinForever_NoteTargetTypeProbe
--   处理：换目标瞬间尽力直读新目标并刷新 memo；读不到就清 memo——
--   绝不把旧目标的类型误套给新目标。
WR_PaladinForever_TargetTypeMemo = WR_PaladinForever_TargetTypeMemo or nil
WR_PaladinForever_CreatureTypeByName = WR_PaladinForever_CreatureTypeByName or {}

local function WR_PaladinForever_SecretOr(v)
    if type(WR_IsSecretValue) == "function" then
        local ok, s = pcall(WR_IsSecretValue, v)
        if ok and s == true then return nil end
    end
    return v
end

-- 解析 UnitCreatureType 的返回（名字 + id）→ "undead" / "demon" / false / nil
local function WR_PaladinForever_ParseCreatureType(name, id)
    name = WR_PaladinForever_SecretOr(name)
    id = WR_PaladinForever_SecretOr(id)
    if type(name) ~= "string" or name == "" then name = nil end
    id = tonumber(id)
    if id == 6 then return "undead" end
    if id == 3 then return "demon" end
    if name == "亡灵" or name == "Undead" then return "undead" end
    if name == "恶魔" or name == "Demon" then return "demon" end
    if name or id then return false end -- 可读但不是亡灵/恶魔
    return nil                          -- 名字与 id 全读不到（未知）
end

local function WR_PaladinForever_DirectCreatureType(unit)
    if type(UnitCreatureType) ~= "function" then return nil end
    local ok, name, id = pcall(UnitCreatureType, unit)
    if not ok then return nil end
    return WR_PaladinForever_ParseCreatureType(name, id)
end

-- 直读成功时的记账：刷新同目标 memo + 按怪名学习
local function WR_PaladinForever_RecordCreatureType(unit, kind)
    if unit ~= "target" then return end
    WR_PaladinForever_TargetTypeMemo = {
        epoch = WR_PaladinForever_TargetEpoch or 0,
        at = GetTime(),
        kind = kind,
    }
    if type(WR_SafeUnitName) == "function" then
        local okN, nm = pcall(WR_SafeUnitName, unit)
        if okN and type(nm) == "string" and nm ~= "" then
            WR_PaladinForever_CreatureTypeByName[nm] = kind
        end
    end
end

-- 换目标瞬间调用（PLAYER_TARGET_CHANGED）：能读就刷新 memo，读不到就清
function WR_PaladinForever_NoteTargetTypeProbe()
    local kind = WR_PaladinForever_DirectCreatureType("target")
    if kind == "undead" or kind == "demon" or kind == false then
        WR_PaladinForever_RecordCreatureType("target", kind)
    else
        WR_PaladinForever_TargetTypeMemo = nil
    end
end

-- 客户端技能可用性（供技能就绪检查与 /FH_QX_DEBUG 使用，不用于推断目标类型）：
--   返回 true（技能可用）/ false（技能不可用）/ nil（接口缺失或返回 secret）。
--   0.5 秒小缓存避免每 tick 双 pcall；目标类型始终由独立类型门判定。
function WR_PaladinForever_ExorcismUsableChannel()
    local nowU = GetTime()
    local epoch = WR_PaladinForever_TargetEpoch or 0
    local cache = WR_PaladinForever_ExoUsableCache
    if type(cache) == "table" and cache.key == epoch
        and (nowU - (cache.at or 0)) <= 0.5 and cache.result ~= nil then
        if cache.result == "hit" then return true end
        if cache.result == "miss" then return false end
    end
    local exoKey = "驱邪术"
    if type(WR_ResolveSpellID) == "function" then
        local sid = WR_ResolveSpellID("驱邪术")
        if type(sid) == "number" then exoKey = sid end
    end
    local u = nil
    -- ★★★ 2026-11-18：参考 PaladinAssist 的 refreshSpell，优先 C_Spell.IsSpellUsable。
    --   旧实现先问全局 IsUsableSpell；Forever 里该兼容入口可能恒 false / 不认当前
    --   rank，会把 C_Spell 的明确结果挡掉（可用性通道恒 miss → 驱邪术永不亮）。
    --   现在 C_Spell 优先，只有它不存在 / 读不到时才回落 IsUsableSpell。
    if type(C_Spell) == "table" and type(C_Spell.IsSpellUsable) == "function" then
        local ok, v, noMana = pcall(C_Spell.IsSpellUsable, exoKey)
        if ok then
            if type(v) == "table" then
                noMana = v.insufficientPower or v.noMana or noMana
                v = v.isUsable or v.usable
            end
            v = WR_PaladinForever_SecretOr(v)
            noMana = WR_PaladinForever_SecretOr(noMana)
            if noMana == true then
                u = false
            elseif v == true or v == false then
                u = v
            end
        end
    end
    if u ~= true and u ~= false and type(IsUsableSpell) == "function" then
        local ok, a, noMana = pcall(IsUsableSpell, exoKey)
        if ok then
            local val = WR_PaladinForever_SecretOr(a)
            if type(val) == "table" then
                noMana = val.insufficientPower or val.noMana or noMana
                val = WR_PaladinForever_SecretOr(val.isUsable or val.usable)
            end
            noMana = WR_PaladinForever_SecretOr(noMana)
            if noMana == true then
                u = false
            elseif val == true or val == false then
                u = val
            end
        end
    end
    WR_PaladinForever_ExoUsableCache = {
        key = epoch,
        at = nowU,
        result = (u == true and "hit") or (u == false and "miss") or nil,
    }
    if u == true or u == false then return u end
    return nil
end

-- ============================================================
-- ★★★ 2026-11-18：参考 BigHammer PaladinAssist 的「技能状态机」
--   参考实现：PaladinAssist 12CA28C1 的 createSpell/refreshSpell——
--     learned = C_SpellBook.IsSpellKnown(spellId)
--     usable  = C_Spell.IsSpellUsable(spellId)       （引擎执行期求值，不读 secret 字段）
--     left    = C_Spell.GetSpellCooldownDuration(spellId)
--               :EvaluateRemainingDuration(curve2550)（引擎侧算冷却剩余秒数）
--   用途：驱邪术不再走 WR_SpellUsable(..., true) 的 GCD 严格门。那个门把
--   全局 GCD / 施法速度变量当公共冷却，而本职业 GCD=WR_GetGCD("审判") 是审判
--   自己的剩余冷却（8~10 秒），审判一进 CD 驱邪术就永远不亮。
--   这里与 PaladinAssist 一样：可用性交给 C_Spell.IsSpellUsable，冷却交给
--   DurationObject；两者都读不到时由本地施放记账兜底，绝不比较 secret 值。
-- ============================================================
WR_PaladinForever_ExoStateCache = WR_PaladinForever_ExoStateCache or nil
WR_PaladinForever_DurationCurve255 = WR_PaladinForever_DurationCurve255 or nil

-- 当前 rank 的驱邪术 spellID（WR_ResolveSpellID 优先，退化为全 rank 表末项）
function WR_PaladinForever_ExorcismSpellID()
    local sid = nil
    if type(WR_ResolveSpellID) == "function" then
        local ok, v = pcall(WR_ResolveSpellID, "驱邪术")
        if ok and type(v) == "number" then sid = v end
    end
    if type(sid) == "number" then return sid end
    local ids = WR_PaladinForever_SpellRankIDs and WR_PaladinForever_SpellRankIDs["驱邪术"]
    if type(ids) == "table" then
        for i = #ids, 1, -1 do
            if type(ids[i]) == "number" then return ids[i] end
        end
    end
    return nil
end

-- 0~255 秒的标量曲线：EvaluateRemainingDuration 在引擎侧求值，
-- 避免在 Lua 里对 secret 数字做比较（参考 PaladinAssist 的 curve2550）。
local function WR_PaladinForever_GetDurationCurve255()
    if WR_PaladinForever_DurationCurve255 ~= nil then
        return WR_PaladinForever_DurationCurve255 or nil
    end
    if type(C_CurveUtil) ~= "table" or type(C_CurveUtil.CreateCurve) ~= "function" then
        WR_PaladinForever_DurationCurve255 = false
        return nil
    end
    local ok, curve = pcall(C_CurveUtil.CreateCurve)
    if not ok or curve == nil then
        WR_PaladinForever_DurationCurve255 = false
        return nil
    end
    pcall(function()
        curve:AddPoint(0, 0)
        curve:AddPoint(255, 255)
    end)
    WR_PaladinForever_DurationCurve255 = curve
    return curve
end

-- 返回技能冷却剩余秒数；读不到返回 nil；没有冷却返回 0。
-- 全程 pcall：DurationObject 的返回值可能是 secret，参与运算会抛错，
-- 此时返回 nil 交给本地施放记账兜底。
function WR_PaladinForever_SpellCooldownLeft(spell)
    local sid = nil
    if type(spell) == "number" then
        sid = spell
    elseif type(WR_ResolveSpellID) == "function" then
        local okR, v = pcall(WR_ResolveSpellID, spell)
        if okR and type(v) == "number" then sid = v end
    end
    if type(sid) ~= "number" then return nil end
    if type(C_Spell) ~= "table" or type(C_Spell.GetSpellCooldownDuration) ~= "function" then
        return nil
    end
    local okD, durObj = pcall(C_Spell.GetSpellCooldownDuration, sid)
    if not okD then return nil end
    if durObj == nil then return 0 end
    local curve = WR_PaladinForever_GetDurationCurve255()
    if not curve then return nil end
    local okE, res = pcall(function()
        return durObj:EvaluateRemainingDuration(curve)
    end)
    if not okE or res == nil then return nil end
    -- 标量曲线直接给数字；部分客户端返回 Color（取 B 通道 ×255）
    local left = nil
    if type(res) == "number" then
        local okNum, v = pcall(function() return res + 0 end)
        if okNum then left = v end
    elseif type(res) == "table" or type(res) == "userdata" then
        local okRGB, r, g, b = pcall(function() return res:GetRGB() end)
        if okRGB and type(b) == "number" then
            local okScale, v = pcall(function() return b * 255 end)
            if okScale then left = v end
        end
    end
    if type(left) ~= "number" then return nil end
    if left < 0 then left = 0 end
    return left
end

-- 参考 PaladinAssist 的 spell 状态：learned / usable / left（0.1 秒缓存）
function WR_PaladinForever_ExorcismState()
    local nowS = GetTime()
    local epochS = WR_PaladinForever_TargetEpoch or 0
    local cache = WR_PaladinForever_ExoStateCache
    if type(cache) == "table" and cache.epoch == epochS
        and (nowS - (cache.at or 0)) <= 0.10 then
        return cache
    end
    local sid = WR_PaladinForever_ExorcismSpellID()
    local state = {
        at = nowS,
        epoch = epochS,
        spellId = sid,
        learned = nil,
        usable = nil,
        left = nil,
    }
    -- learned：C_SpellBook（参考 PaladinAssist）→ IsPlayerSpell → 共享 SpellKnown
    --   任一通道明确 true 即视为已学会；全部通道都明确 false 才判未学。
    local checkedLearned = false
    local learnedTrue = false
    if type(sid) == "number" then
        if type(C_SpellBook) == "table" and type(C_SpellBook.IsSpellKnown) == "function" then
            local okK, known = pcall(C_SpellBook.IsSpellKnown, sid)
            if okK and type(known) == "boolean" then
                checkedLearned = true
                if known then learnedTrue = true end
            end
        end
        if not learnedTrue and type(IsPlayerSpell) == "function" then
            local okP, known = pcall(IsPlayerSpell, sid)
            if okP and type(known) == "boolean" then
                checkedLearned = true
                if known then learnedTrue = true end
            end
        end
    end
    if not learnedTrue and type(WR_PaladinForever_SpellKnown) == "function" then
        local okS, known = pcall(WR_PaladinForever_SpellKnown, "驱邪术")
        if okS and type(known) == "boolean" then
            checkedLearned = true
            if known then learnedTrue = true end
        end
    end
    if learnedTrue then
        state.learned = true
    elseif checkedLearned then
        state.learned = false
    end
    -- usable：沿用已有的引擎可用性通道（IsUsableSpell / C_Spell.IsSpellUsable）
    state.usable = WR_PaladinForever_ExorcismUsableChannel()
    -- left：参考 PaladinAssist 的 GetSpellCooldownDuration 通道
    state.left = WR_PaladinForever_SpellCooldownLeft("驱邪术")
    WR_PaladinForever_ExoStateCache = state
    return state
end

-- 驱邪术此刻是否「可以提示」：已学会 + 客户端可用 + 冷却就绪（读不到交给本地记账）
function WR_PaladinForever_ExorcismReady()
    local state = WR_PaladinForever_ExorcismState()
    if state.learned == false then return false end
    if state.usable == false then return false end
    if type(state.left) == "number" and state.left > 0.25 then return false end
    -- 本地施放记账兜底（战斗中 C_Spell 冷却不可读时）
    if type(WR_PaladinForever_GetLastCastAt) == "function" then
        local okL, last = pcall(WR_PaladinForever_GetLastCastAt, "驱邪术")
        if okL and type(last) == "number" and last > 0
            and (GetTime() - last) < 14.8 then
            return false
        end
    end
    return true
end

function WR_PaladinForever_IsUndeadOrDemon(unit)
    unit = unit or "target"
    -- ① 直读（可读 = 结论确定：命中 / 明确不是）
    local kind = WR_PaladinForever_DirectCreatureType(unit)
    if kind == "undead" or kind == "demon" or kind == false then
        WR_PaladinForever_RecordCreatureType(unit, kind)
        return kind == "undead" or kind == "demon"
    end
    -- ② 怪名缓存（受限上下文里 UnitName 可能仍是另一条受限通道，能读就查）
    if type(WR_SafeUnitName) == "function" then
        local okN, nm = pcall(WR_SafeUnitName, unit)
        if okN and type(nm) == "string" and nm ~= "" then
            local cached = WR_PaladinForever_CreatureTypeByName[nm]
            if cached == "undead" or cached == "demon" then return true end
            if cached == false then return false end
        end
    end
    -- ③ 同目标 memo（TargetEpoch 未变 = 还是原来那只；120 秒防陈旧）
    if unit == "target" then
        local memo = WR_PaladinForever_TargetTypeMemo
        if type(memo) == "table" and (memo.kind == "undead" or memo.kind == "demon")
            and (memo.epoch or 0) == (WR_PaladinForever_TargetEpoch or 0)
            and (GetTime() - (memo.at or 0)) <= 120 then
            return true
        end
        if type(memo) == "table" and memo.kind == false
            and (memo.epoch or 0) == (WR_PaladinForever_TargetEpoch or 0)
            and (GetTime() - (memo.at or 0)) <= 120 then
            return false -- 同一目标进战前明确读过：不是亡灵/恶魔
        end
    end
    -- ④ 类型未知时不提示。IsSpellUsable 仅表示技能/资源可用，
    --   不证明当前目标是亡灵/恶魔；以它兜底会对其它类型误亮色块。
    return false
end

-- ============================================================
-- ★★★ 2026-11-18：三系共用的驱邪术步骤（参考 PaladinAssist 的 spell 状态）
--   Ret/Holy 的 ExorcismStep 直接复用这里；Prot 的 exorcismEligible 复用
--   WR_PaladinForever_ExorcismReady。所有分支同一判据：
--     开关 → 目标可攻击存活 → 亡灵/恶魔 → 30 码 → learned/usable/left → 点亮
--   不再使用 WR_SpellUsable(..., true)（GCD/施法速度严格门会误杀）。
-- ============================================================
function WR_PaladinForever_ExorcismStep(toggleVar)
    if type(toggleVar) == "string" and PigSet and PigSet[toggleVar] == false then
        return false
    end
    if type(WR_PaladinForever_TargetCastable) == "function"
        and not WR_PaladinForever_TargetCastable("target") then
        return false
    end
    if type(WR_PaladinForever_IsUndeadOrDemon) ~= "function" then return false end
    local okT, hit = pcall(WR_PaladinForever_IsUndeadOrDemon, "target")
    if not okT or hit ~= true then return false end
    if type(WR_PaladinForever_InSpellRange) == "function" then
        local okR, rangeOK = pcall(WR_PaladinForever_InSpellRange, "驱邪术", "target")
        if not okR or rangeOK ~= true then return false end
    end
    if not WR_PaladinForever_ExorcismReady() then return false end
    if type(WR_PaladinForever_ShowSkillCD) == "function" then
        return WR_PaladinForever_ShowSkillCD("驱邪术", 20, 15)
    end
    return false
end

-- 诊断：/FH_QX_DEBUG 打印驱邪术四通道现场，实机核对哪条通道生效
SLASH_FH_QX_DEBUG1 = "/FH_QX_DEBUG"
SlashCmdList["FH_QX_DEBUG"] = function()
    local kind = WR_PaladinForever_DirectCreatureType("target")
    local nm = nil
    if type(WR_SafeUnitName) == "function" then
        local okN, v = pcall(WR_SafeUnitName, "target")
        if okN and type(v) == "string" then nm = v end
    end
    local memo = WR_PaladinForever_TargetTypeMemo
    local memoText = "无"
    if type(memo) == "table" then
        memoText = "kind=" .. tostring(memo.kind)
            .. " epoch=" .. tostring(memo.epoch)
            .. " age=" .. string.format("%.1f", GetTime() - (memo.at or 0)) .. "s"
    end
    local gate = WR_PaladinForever_ExoLastGate
    local gateText = "无（循环未跑过）"
    if type(gate) == "table" then
        gateText = "类型=" .. tostring(gate.typeOK)
            .. " 可攻击=" .. tostring(gate.castable)
            .. " 距离=" .. tostring(gate.range)
            .. " 射程=" .. tostring(gate.rangeOK)
            .. " 可用=" .. tostring(gate.usable)
            .. " 客户端=" .. tostring(gate.clientOK)
            .. " GCD变量=" .. tostring(gate.gcdVar)
            .. " 施法速度=" .. tostring(gate.shifa)
            .. " 年龄=" .. string.format("%.1f", GetTime() - (gate.at or 0)) .. "s"
    end
    local exoStateDbg = WR_PaladinForever_ExorcismState()
    print("|cff00ff00[驱邪术诊断]|r 直读=" .. tostring(kind)
        .. " | 怪名=" .. tostring(nm)
        .. " | 名字缓存=" .. (nm and tostring(WR_PaladinForever_CreatureTypeByName[nm]) or "-")
        .. " | memo=" .. memoText
        .. " | 可用性通道=" .. tostring(type(WR_PaladinForever_ExorcismUsableChannel) == "function" and WR_PaladinForever_ExorcismUsableChannel() or "?")
        .. " | 技能状态(learned=" .. tostring(exoStateDbg.learned)
        .. " usable=" .. tostring(exoStateDbg.usable)
        .. " left=" .. tostring(exoStateDbg.left) .. ")"
        .. " | TargetEpoch=" .. tostring(WR_PaladinForever_TargetEpoch or 0)
        .. " | 最终判定=" .. tostring(WR_PaladinForever_IsUndeadOrDemon("target"))
        .. "\n|cff00ff00[驱邪术门槛]|r " .. gateText)
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

-- ★★★ 2026-11-14 用户口径：「骑士清洁术功能匹配一下，目前插件面板中的清洁术无法使用」
--   面板已有 5 模式下拉（FH_QJS / CJ_QJS）和防护「自己 / 目标」复选框，
--   但 Forever 循环没有读取这些变量 → 面板选项完全不生效。
--   另外公共 HasDispel 把「诅咒」也算进来，而本服 清洁术(4987) 只能驱散
--   中毒 / 疾病 / 魔法（截图实测）—— 点诅咒会白按一次。
--   这里统一：只认三种可驱散类型；模式 1/2/3/4/5 与防护独立复选框全部接入，
--   施放走 43 自己 / 44 目标 / 59 指向（不设焦点）。
--
-- ★★★ 2026-11-14 用户口径：「骑士这个版本清洁术用不了」：
--   真机 debuff 名称是技能名（毒液箭 / 撕裂 / 腐蚀…），不是「中毒 / 疾病 / 魔法」。
--   旧实现用 WR_GetUnitDebuffTime(unit, "中毒") —— 它按【光环名精确匹配】，
--   永远匹配不到真实 debuff → UnitHasDispel 恒 false → 清洁术永远不亮。
--   现改为读取 HARMFUL 光环的 dispelType（Poison / Disease / Magic，
--   同时兼容本地化「中毒 / 疾病 / 魔法」）；诅咒（Curse）依旧排除。
WR_PaladinForever_DISPEL_KINDS = { "Poison", "Disease", "Magic" }
WR_PaladinForever_DISPEL_LEGACY_NAMES = { "中毒", "疾病", "魔法" }
-- 已知本服诅咒（截图：荆棘诅咒 6909）。即使服务端把 dispelName 错标成 Magic，
-- 这个法术也只能由解诅咒技能处理，圣骑士清洁术必须跳过。
WR_PaladinForever_NEVER_CLEANSE_SPELL_IDS = { [6909] = true }

-- private: 任意 secret 值（secret string / boolean / number）检测。
-- secret 值连 == / ~= / 字符串比较都会抛 "... secret ... value"，
-- 所以任何比较之前必须先过这里。
local function WR_PaladinForever_IsSecretValue(v)
    -- WR_IsSecretValue 内部若因 issecretvalue 不可用而返回 false，
    -- 这里继续用全局 issecretvalue 再兜一次，避免漏判后走字符串比较抛错。
    if WR_IsSecretValue ~= nil then
        local ok, sec = pcall(WR_IsSecretValue, v)
        if ok and sec == true then return true end
    end
    if issecretvalue ~= nil then
        local ok, sec = pcall(issecretvalue, v)
        if ok and sec == true then return true end
    end
    return false
end

-- private: 判断一个值是否是 secret string（保留旧名，内部走通用检测）。
local function WR_PaladinForever_IsSecretText(v)
    if type(v) ~= "string" then return false end
    return WR_PaladinForever_IsSecretValue(v)
end

-- dispelType 归一化：英文枚举名与中文显示名都接受；其它（含 Curse）返回 nil
-- ★★★ 2026-11-15 修复用户报错：DebuffFrame.auraInfo[i].debuffType = auraData.dispelName，
-- 战斗中它是 secret string；旧代码第一行写成 type(v) ~= "string" or v == ""，
-- secret 字符串参与 == 比较时直接抛 "attempt to compare local 'v' (a secret string value ...)"。
function WR_PaladinForever_NormalizeDispelType(v)
    -- 整段 pcall 兜底：即使 secret 检测因客户端差异漏判，也不能让任何比较抛到主循环
    local ok, result = pcall(function()
        -- ① 任何比较之前先做 secret 检测（secret string 的 type() 仍是 "string"）
        if type(v) ~= "string" then return nil end
        if WR_PaladinForever_IsSecretText(v) then return nil end
        if v == "" then return nil end
        local okL, s = pcall(string.lower, v)
        if not okL or type(s) ~= "string" then return nil end
        -- ② string.lower 之后再次确认（防御 issecretvalue 未暴露 / 返回值被 secret 包装）
        if WR_PaladinForever_IsSecretText(s) then return nil end
        if s == "poison" or s == "中毒" then return "poison" end
        if s == "disease" or s == "疾病" then return "disease" end
        if s == "magic" or s == "魔法" then return "magic" end
        if s == "curse" or s == "诅咒" then return "curse" end
        if s == "bleed" or s == "流血" then return "bleed" end
        return nil
    end)
    if not ok then return nil end
    return result
end

function WR_PaladinForever_IsCleansableDispelType(v)
    local ok, k = pcall(WR_PaladinForever_NormalizeDispelType, v)
    if not ok or type(k) ~= "string" then return false end
    return k == "poison" or k == "disease" or k == "magic"
end

-- 名称含「诅咒 / Curse」的 debuff 一律按诅咒处理（防止服务端 dispelName 错标）。
local function WR_PaladinForever_IsKnownCurseName(name)
    if type(name) ~= "string" then return false end
    if WR_PaladinForever_IsSecretValue(name) then return false end
    local ok, s = pcall(string.lower, name)
    if not ok or type(s) ~= "string" then return false end
    return string.find(s, "诅咒", 1, true) ~= nil or string.find(s, "curse", 1, true) ~= nil
end

-- 扫描某单位的 HARMFUL 光环缓存，命中任何清洁术可驱散类型即返回 true
local function WR_PaladinForever_CacheHasDispel(unit)
    local cache = type(WR_AuraCache) == "table" and WR_AuraCache[unit] or nil
    local auras = cache and cache.HARMFUL or nil
    if type(auras) ~= "table" then return false end
    for i = 1, #auras do
        local aura = auras[i]
        if type(aura) == "table" then
            local auraName = aura.name
            if type(auraName) == "string" and WR_PaladinForever_IsSecretValue(auraName) then
                -- 名字是 secret，无法核实这条缓存是否已过期/仍是当前 debuff，跳过。
            elseif WR_PaladinForever_IsKnownCurseName(auraName) then
                -- 这条明确是诅咒，跳过；同表里若有毒/病/魔法仍会命中。
            elseif WR_PaladinForever_IsCleansableDispelType(aura.dispelType) then
                return true
            end
        end
    end
    return false
end

function WR_PaladinForever_UnitIsFriendly(unit)
    if type(unit) ~= "string" or unit == "" then return false end
    if unit == "player" then return true end
    -- ★ 直接 pcall：本仓库离线夹具里 UnitIsFriend/UnitIsPlayer 是 userdata 函数，
    --   type(...) == "function" 会误判为不存在（客户端里两者都存在，行为一致）。
    local ok, v = pcall(UnitIsFriend, "player", unit)
    if ok and v then return true end
    if ok and v == false then return false end
    local okP, vP = pcall(UnitIsPlayer, unit)
    if okP and vP then return true end
    return false
end

-- private: 读 AuraData 的可驱散状态。返回 true=明确可驱散 / false=明确不可驱散 / nil=读不到或 secret。
-- ★ 2026-11-16：只做「正向证明」——绝不把「存在一个 debuff」当成可驱散；
--   12.x 的 HARMFUL|RAID 在部分客户端实现里会把诅咒也算进来，存在性判断会误报。
local function WR_PaladinForever_AuraDataDispelState(data)
    if type(data) ~= "table" and type(data) ~= "userdata" then return nil end

    -- ★ 2026-11-16 复查：先读 dispelName / dispelType，诅咒必须优先判死；
    --   旧顺序先信 canActivePlayerDispel，某些客户端的该字段会把诅咒也报成 true。
    local okN, dt = pcall(function() return data.dispelName end)
    if not okN then dt = nil end
    local dtWasSecret = (dt ~= nil and WR_PaladinForever_IsSecretValue(dt))
    local dt2WasSecret = false
    if dt == nil or dtWasSecret then
        local okT, dt2 = pcall(function() return data.dispelType end)
        if okT and not WR_PaladinForever_IsSecretValue(dt2) then
            dt = dt2
        else
            if okT and dt2 ~= nil and WR_PaladinForever_IsSecretValue(dt2) then dt2WasSecret = true end
            dt = nil
        end
    end
    if dt ~= nil and not WR_PaladinForever_IsSecretValue(dt) then
        local k = WR_PaladinForever_NormalizeDispelType(dt)
        if k == "poison" or k == "disease" or k == "magic" then return true end
        if k == "curse" or k == "bleed" then return false end
        return nil
    end

    -- ★ 2026-11-16：dispelName 本身是 secret 时，说明这个光环类型不可读；
    --   此时即使 canActivePlayerDispel 返回 true 也不能当作证据（本服曾把诅咒
    --   报成 true）。只有 dispelName 字段完全缺失时才允许 can 字段兜底。
    if dtWasSecret or dt2WasSecret then
        -- ★ 2026-11-16：战斗内 secret dispelName 改走整条 AuraData 图集探针；
        -- 能读出类型就按类型判（Poison/Disease/Magic=true，Curse/Bleed=false）。
        local secretKind = WR_PaladinForever_ProbeDispelFromAura(data)
        if secretKind == "poison" or secretKind == "disease" or secretKind == "magic" then return true end
        if secretKind == "curse" or secretKind == "bleed" then return false end

        -- ★★★ 2026-11-19 八次修复：名称白名单（名字行通常不是 secret，见截图）。
        do
            local okName, auraName = pcall(function() return data.name end)
            if okName then
                local nameKind = WR_PaladinForever_KindFromAuraName(auraName)
                if nameKind == "poison" or nameKind == "disease" or nameKind == "magic" then
                    return true
                end
            end
        end

        -- ★★★ 2026-11-19 新增 fallback（烈焰震击 23038 截图实锤：图集探针返回 unknown
        -- → ProbeDispellableByFilter 整体返回 nil → UnitHasDispel 全 unknown →
        -- AurasRestricted() 直接 return false）。此处 data.spellId 不一定是 secret
        -- （EllesmereUIAuraBuffReminders NON_SECRET_SPELL_IDS 实证：即使 dispelName
        -- 是 secret，spellId 仍可作为白名单/静态分类入口）：
        --   · spellId 可读 → 先查 CLEANSE_KNOWN_AURA_IDS 白名单，再查 C_TooltipInfo
        --     静态提示，命中则按 kind 判定（poison/disease/magic=true，curse/bleed=false）；
        --   · spellId secret → 无新证据，保留图集探针返回的 unknown。
        local okS, sid = pcall(function() return data.spellId end)
        if okS and type(sid) == "number" and not WR_PaladinForever_IsSecretValue(sid) then
            if WR_PaladinForever_CLEANSE_KNOWN_AURA_IDS then
                local known = WR_PaladinForever_CLEANSE_KNOWN_AURA_IDS[sid]
                if known == "poison" or known == "disease" or known == "magic" then return true end
                if known == "curse" or known == "bleed" then return false end
            end
            -- DispKindBySpellID 依赖 C_TooltipInfo.GetSpellByID 静态提示（无 miss 缓存的白名单直查）
            if type(WR_PaladinForever_DispelKindBySpellID) == "function" then
                local kind = WR_PaladinForever_DispelKindBySpellID(sid)
                if kind == "poison" or kind == "disease" or kind == "magic" then return true end
                if kind == "curse" or kind == "bleed" then return false end
            end
        end

        return nil
    end
    local okC, can = pcall(function() return data.canActivePlayerDispel end)
    if okC and type(can) == "boolean" and not WR_PaladinForever_IsSecretValue(can) then
        if can == true then return true end
        return false
    end
    return nil
end

-- ★★★ 2026-11-16 用户口径「清洁术只能驱散疾病、中毒、魔法，不能驱散诅咒」复查修复：
--   旧探针把 C_UnitAuras.GetAuraSlots(...HARMFUL...) 只要有槽位就返回 true，
--   实测某些客户端该过滤器会包含诅咒（或至少无法保证排除），导致中诅咒后
--   清洁术不断点亮。现在改为：只有真正读到 AuraData 的 dispelName / canActivePlayerDispel
--   并明确是可驱散类型时才返回 true；全部读不到则返回 nil（未知），绝不猜「可驱散」。
-- ★★★ 2026-11-19 九次修复：GameTooltip 直读通道（最强的一条）。
--   用户连续多张截图的共同点：**鼠标悬停时 GameTooltip 能完整显示
--   「烈焰震击 / 魔法 / 法术ID：23038 / 剩余6秒」**。这证明本客户端在战斗中
--   GameTooltip 的数据流是可读的 —— 它由引擎 C 侧填充，不走
--   DenyTaintedAccessWhenAurasAreSecret。
--   与 C_TooltipInfo 的区别：C_TooltipInfo 返回的是「数据表」，受限内容里可能整条
--   被拒或字段 secret；而 GameTooltip:SetUnitDebuff(unit, i) 之后读
--   GameTooltipTextLeftN/RightN 的 **GetText() 字符串** 是引擎写进字体串的普通文本，
--   本仓库 PartyMemberFrame.lua 366 就是这么用的（GX.lua 已有实证记录）。
--   EUI 禁止的是「用 Lua 创建 GameTooltipTemplate 帧」，**复用已存在的 GameTooltip
--   完全合法**（不 CreateFrame、不 SetOwner 到自定义帧）。
--
--   安全约束（必须全部满足才动手）：
--     · 节流 0.5 秒（SetUnitDebuff 会重排 tooltip，不能每 tick 砸）；
--     · 玩家自己正开着 tooltip（GameTooltip:IsOwned/IsShown 且 owner 不是我们）→ 直接跳过，
--       绝不打断玩家正在看的信息；
--     · 只在脱战/战斗都试，但被拒就记 3 秒冷却；
--     · 读完必须恢复：把 GameTooltip 隐藏并清空，避免残留在屏幕上。
WR_PaladinForever_GameTooltipScanAt = {}
WR_PaladinForever_GameTooltipScanCache = {}
WR_PaladinForever_GameTooltipScanDenied = {}

function WR_PaladinForever_ProbeByGameTooltip(unit)
    if type(unit) ~= "string" or unit == "" then return nil end
    local tip = _G.GameTooltip
    if tip == nil then return nil end
    local now = GetTime()
    local atMap = WR_PaladinForever_GameTooltipScanAt
    local cacheMap = WR_PaladinForever_GameTooltipScanCache
    local deniedMap = WR_PaladinForever_GameTooltipScanDenied
    local lastAt = atMap[unit] or 0
    if now - lastAt < 0.5 then return cacheMap[unit] end
    -- 玩家自己正在看 tooltip：本帧完全不动它
    local okShown, shown = pcall(function() return tip:IsShown() end)
    if okShown and shown == true then
        local okOwned, owned = pcall(function()
            local fn = tip.IsOwned
            if fn == nil then return false end
            return tip:IsOwned(UIParent)
        end)
        -- owner 是 UIParent（= 我们上次扫描残留）才允许接管；否则视为玩家在用
        if not (okOwned and owned == true) then return cacheMap[unit] end
    end
    local deniedUntil = deniedMap[unit] or 0
    if now < deniedUntil then return cacheMap[unit] end
    atMap[unit] = now
    local hasDebuffSetter = (tip.SetUnitDebuff ~= nil)
    if not hasDebuffSetter and tip.SetUnitAura == nil then return nil end
    -- 接管前必须先设 owner，否则 SetUnitDebuff 在多数客户端直接报错。
    -- 只用 UIParent + ANCHOR_NONE（不锚到任何可见位置），读完立刻 Hide。
    if tip.SetOwner ~= nil then
        pcall(function() tip:SetOwner(UIParent, "ANCHOR_NONE") end)
    end
    local function readLines()
        local out = {}
        -- 冒号语义：NumLines / GetText 都是方法，必须带 self 调用
        local okN, n = pcall(function() return tip:NumLines() end)
        if not okN or type(n) ~= "number" then return out end
        for j = 1, math.min(n, 20) do
            local lt = _G["GameTooltipTextLeft" .. j]
            local rt = _G["GameTooltipTextRight" .. j]
            local ls, rs = nil, nil
            if lt ~= nil then
                local okL, v = pcall(function() return lt:GetText() end)
                if okL and type(v) == "string" and not WR_PaladinForever_IsSecretValue(v) then ls = v end
            end
            if rt ~= nil then
                local okR, v = pcall(function() return rt:GetText() end)
                if okR and type(v) == "string" and not WR_PaladinForever_IsSecretValue(v) then rs = v end
            end
            if ls ~= nil or rs ~= nil then
                out[#out + 1] = { left = ls or "", right = rs or "" }
            end
        end
        return out
    end
    local function classify(lines)
        -- 顺序：类型短词 → 名称白名单 → 「法术ID: N」行
        for i = 1, #lines do
            local k = WR_PaladinForever_KindFromShortText(lines[i].left)
            if k == nil then k = WR_PaladinForever_KindFromShortText(lines[i].right) end
            if k == "poison" or k == "disease" or k == "magic" then return k end
            if k == "curse" or k == "bleed" then return k end
        end
        for i = 1, #lines do
            local k = WR_PaladinForever_KindFromAuraName(lines[i].left)
            if k == nil then k = WR_PaladinForever_KindFromAuraName(lines[i].right) end
            if k ~= nil then return k end
        end
        for i = 1, #lines do
            local joined = lines[i].left .. " " .. lines[i].right
            local okLow, low = pcall(string.lower, joined)
            if okLow and type(low) == "string"
                and (string.find(low, "法术id", 1, true) or string.find(low, "spell id", 1, true)) then
                local okM, digits = pcall(string.match, joined, "(%d+)")
                if okM and type(digits) == "string" then
                    local okNum, num = pcall(tonumber, digits)
                    if okNum and type(num) == "number" and num > 0 then
                        local known = WR_PaladinForever_CLEANSE_KNOWN_AURA_IDS[num]
                        if known ~= nil then return known end
                        local d = WR_PaladinForever_CLEANSE_DISCOVERED_IDS[num]
                        if d ~= nil then return d end
                        local st = WR_PaladinForever_StaticSpellDispelKind(num)
                        if st ~= nil then
                            WR_PaladinForever_RememberCleansableID(num, st)
                            return st
                        end
                    end
                end
            end
        end
        return nil
    end
    local sawUnknown = false
    local sawKnownNon = false
    for i = 1, 40 do
        local okSet = pcall(function()
            if hasDebuffSetter then
                tip:SetUnitDebuff(unit, i)
            else
                tip:SetUnitAura(unit, i)
            end
        end)
        if not okSet then
            -- 被拒 / 签名不符：3 秒内不再打扰
            deniedMap[unit] = now + 3
            pcall(function() tip:Hide() end)
            return cacheMap[unit]
        end
        local lines = readLines()
        if #lines == 0 then break end
        local kind = classify(lines)
        if kind == "poison" or kind == "disease" or kind == "magic" then
            pcall(function() tip:Hide() end)
            cacheMap[unit] = true
            return true
        end
        if kind == "curse" or kind == "bleed" then sawKnownNon = true else sawUnknown = true end
    end
    pcall(function() tip:Hide() end)
    if sawKnownNon and not sawUnknown then
        cacheMap[unit] = false
        return false
    end
    cacheMap[unit] = nil
    return nil
end
_G.WR_PaladinForever_ProbeByGameTooltip = WR_PaladinForever_ProbeByGameTooltip

-- ★★★ 2026-11-19 八次修复（审计结论）：曾尝试用
--   C_UnitAuras.GetAuraDataByIndex(unit, 1, "HARMFUL|Magic") 这类「驱散类型令牌」
--   做免读回存在性探针，但**已回退**：
--   本服 / 经典客户端的 GetAuraDataByIndex filter 只认 HARMFUL / HELPFUL / RAID /
--   PLAYER 等标准令牌，Magic/Poison 这类不是它的合法取值。令牌不被识别时引擎
--   会**忽略**类型部分，等价于裸 "HARMFUL" → 返回第一条任意 debuff →
--   「中诅咒也点亮清洁术」。GX.lua 已记录过同款事故（旧探针只数槽位 → 诅咒误驱）。
--   结论：类型判定只能走「能读出类型」或「名字/ID 命中白名单」的通道，
--   绝不能用「引擎返回了某条数据」当作「是某种可驱散类型」的证据。

function WR_PaladinForever_ProbeDispellableByFilter(unit)
    if type(unit) ~= "string" or unit == "" then return nil end
    if C_UnitAuras == nil then return nil end

    local sawUnknown = false
    local sawKnownNonCleansable = false

    local function consider(data)
        local state = WR_PaladinForever_AuraDataDispelState(data)
        if state == true then return true end
        if state == false then sawKnownNonCleansable = true else sawUnknown = true end
        return false
    end

    -- ① 槽位枚举 + 按槽位读 AuraData（12.0 推荐路径）
    local slotFn = C_UnitAuras.GetAuraSlots
    local bySlotFn = C_UnitAuras.GetAuraDataBySlot
    -- 用 ~= nil 而不是 type=="function"：部分客户端/离线夹具把 C API 暴露成
    -- 可调用 userdata，type() 不一定是 "function"。
    if slotFn ~= nil and bySlotFn ~= nil then
        local token = nil
        local gotAny = false
        for n = 1, 40 do
            local okS, nextToken, slot = pcall(slotFn, unit, "HARMFUL", 1, token)
            if not okS then sawUnknown = true; break end
            if slot == nil then break end
            gotAny = true
            local okD, data = pcall(bySlotFn, unit, slot)
            if okD and data ~= nil then
                if consider(data) then return true end
            else
                sawUnknown = true
            end
            if nextToken == nil or nextToken == token then break end
            token = nextToken
        end
        -- 没有槽位不代表没有可驱散 debuff（GetAuraSlots 的实现差异/权限差异），
        -- 继续走索引通道和旧缓存，绝不在“未知”时提前判无。
    end

    -- ② 按索引读 AuraData（GetAuraDataBySlot 不存在时）
    if C_UnitAuras.GetAuraDataByIndex ~= nil then
        local any = false
        for i = 1, 40 do
            local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
            if not ok then sawUnknown = true; break end
            if data == nil then break end
            any = true
            if consider(data) then return true end
        end
        -- 同上：索引查询为空只是未知，不能据此判无。
    end

    -- 不再做任何「UnitAura 返回非 nil = 可驱散」的存在性兜底：
    -- 老 API 对过滤器支持不一致，返回的第一条可能是诅咒，正是本次误报来源。

    if sawKnownNonCleansable and not sawUnknown then return false end
    return nil
end

-- 当前是否处于「光环数据 secret」状态（战斗 / 首领战 / 挑战模式 / PVP）。
function WR_PaladinForever_AurasRestricted()
    if C_Secrets == nil or C_Secrets.ShouldAurasBeSecret == nil then return false end
    local ok, restricted = pcall(C_Secrets.ShouldAurasBeSecret)
    return ok and restricted == true
end

-- 扫描单位当前全部 HARMFUL 光环，返回 true=明确有可驱散 / false=明确只有不可驱散 / nil=读不到。
-- 多 API 交叉验证：UnitDebuff / UnitAura 是经典接口，部分客户端战斗内仍可读；
-- 不能只依赖 C_UnitAuras（secret 时会直接抛错）。
local WR_PaladinForever_ScanEUIAuraButtons = nil

-- ★ 2026-11-16：战斗内 data.dispelName 是 secret string，但暴雪自己的
-- AuraUtil.SetAuraBorderAtlas 能把它转成普通图集名。这里用一张隐藏纹理做探针：
-- 成功则按图集名判类型；失败/不可用返回 nil，绝不猜测。
-- 探针纹理缓存走 _G（局部 upvalue 无法被调试/夹具复位，残留旧图集会误判类型）。
local function WR_PaladinForever_EnsureSecretDispelProbeTexture()
    local tex = _G.WR_PaladinForever_SecretDispelProbeTexture
    if tex ~= nil then return tex end
    local parent = _G and _G.UIParent or nil
    if parent == nil or type(parent.CreateTexture) ~= "function" then return nil end
    local okT, created = pcall(function() return parent:CreateTexture(nil, "ARTWORK") end)
    if not okT or created == nil then return nil end
    if type(created.Hide) == "function" then created:Hide() end
    _G.WR_PaladinForever_SecretDispelProbeTexture = created
    return created
end

local function WR_PaladinForever_KindFromProbeAtlas(tex)
    if tex == nil then return nil end
    local okA, atlas = pcall(function() return tex:GetAtlas() end)
    if not okA or type(atlas) ~= "string" or WR_PaladinForever_IsSecretValue(atlas) then return nil end
    local okL, s = pcall(string.lower, atlas)
    if not okL or type(s) ~= "string" then return nil end
    if string.find(s, "curse", 1, true) then return "curse" end
    if string.find(s, "bleed", 1, true) then return "bleed" end
    if string.find(s, "poison", 1, true) then return "poison" end
    if string.find(s, "disease", 1, true) then return "disease" end
    if string.find(s, "magic", 1, true) then return "magic" end
    return nil
end

local function WR_PaladinForever_ProbeSecretDispelType(value)
    -- 不对 secret 做 value == nil 比较；type 是安全的。
    if type(value) ~= "string" then return nil end
    if not WR_PaladinForever_IsSecretValue(value) then return nil end
    if type(AuraUtil) ~= "table" or type(AuraUtil.SetAuraBorderAtlas) ~= "function" then return nil end
    local tex = WR_PaladinForever_EnsureSecretDispelProbeTexture()
    if tex == nil then return nil end
    -- 复用探针纹理前必须清空旧图集，失败路径不能残留上一次的类型。
    pcall(function() tex:SetTexture(nil) end)
    local okSet = pcall(AuraUtil.SetAuraBorderAtlas, tex, value, true)
    if not okSet then return nil end
    return WR_PaladinForever_KindFromProbeAtlas(tex)
end

-- ★ 2026-11-16：整条 AuraData 探针 —— 引擎专为插件提供的
-- AuraUtil.SetAuraBorderAtlasFromAura(tex, auraData, showDispelType)，
-- secret dispelName 在引擎内部解析，插件只读回普通图集名。
-- 本服战斗内中毒 / 疾病的识别走这条（secret 串直传 SetAuraBorderAtlas
-- 在被 taint 拦截的客户端会整条失败，FromAura 不受影响）。
local function WR_PaladinForever_ProbeDispelFromAura(data)
    if data == nil then return nil end
    if type(AuraUtil) ~= "table" or type(AuraUtil.SetAuraBorderAtlasFromAura) ~= "function" then return nil end
    local tex = WR_PaladinForever_EnsureSecretDispelProbeTexture()
    if tex == nil then return nil end
    pcall(function() tex:SetTexture(nil) end)
    local okSet = pcall(AuraUtil.SetAuraBorderAtlasFromAura, tex, data, true)
    if not okSet then return nil end
    return WR_PaladinForever_KindFromProbeAtlas(tex)
end
_G.WR_PaladinForever_ProbeSecretDispelType = WR_PaladinForever_ProbeSecretDispelType
_G.WR_PaladinForever_ProbeDispelFromAura = WR_PaladinForever_ProbeDispelFromAura

local function WR_PaladinForever_ScanUnitDebuffTypes(unit)
    -- 玩家使用 EllesmereUI Player Aura Bars 时优先读它的引擎 dispel 纹理。
    if unit == "player" then
        local euiHit = WR_PaladinForever_ScanEUIAuraButtons()
        if euiHit == true then return true end
        -- ★★★ 2026-11-19：受限战斗里 EUI 的 DebuffBorder 图集可能整段不刷新，
        --   此时 false 是「读不到」而不是「确定没有可驱散」；只有非受限上下文
        --   才采信 false，否则放行给后面的白名单 / 静态分类 / tooltip 通道。
        if euiHit == false and not WR_PaladinForever_AurasRestricted() then return false end
    end
    local sawAny = false
    local sawUnknown = false
    local sawKnownNonCleansable = false

    local function consider(name, dt, spellId, can, data)
        -- name 本身可能是 secret string：不能直接写 name == nil，否则整条
        -- UnitDebuff 返回会被 pcall 丢弃，连可读的 dispelType 也一起错过。
        local okNil, nameIsNil = pcall(function() return name == nil end)
        if okNil and nameIsNil then return nil end
        sawAny = true
        -- 名称兜底：本服部分诅咒（如「荆棘诅咒」6909）即使 dispelName 被错标，
        -- 名称里仍带「诅咒 / Curse」，圣骑士清洁术一律不得处理。
        if type(name) == "string" and not WR_PaladinForever_IsSecretValue(name) then
            local okLower, nameLower = pcall(string.lower, name)
            if okLower and type(nameLower) == "string"
                and (string.find(nameLower, "诅咒", 1, true) or string.find(nameLower, "curse", 1, true)) then
                sawKnownNonCleansable = true
                return nil
            end
        end
        -- ★★★ 2026-11-19 八次修复：名称白名单（名字通常不是 secret，见用户截图）。
        --   名字命中 CLEANSE_KNOWN_AURA_NAMES 即按类型判定；诅咒名已在上面排除。
        if type(name) == "string" and not WR_PaladinForever_IsSecretValue(name) then
            local nameKind = WR_PaladinForever_KindFromAuraName(name)
            if nameKind == "poison" or nameKind == "disease" or nameKind == "magic" then
                return true
            end
        end
        if spellId ~= nil and not WR_PaladinForever_IsSecretValue(spellId) then
            local okNum, num = pcall(tonumber, spellId)
            if okNum and type(num) == "number" and num > 0 then
                if WR_PaladinForever_NEVER_CLEANSE_SPELL_IDS[num] then
                    sawKnownNonCleansable = true
                    return nil
                end
                -- ★★★ 2026-11-18 五次修复：静态 spellID 分类，不依赖 dispelName 是否 secret。
                --   战斗里 5416/744/13298/3427 等 ID 可从 auraData.spellId 直接读到，
                --   类型由 C_TooltipInfo.GetSpellByID 的静态提示行判定（见下方函数）。
                local idKind = WR_PaladinForever_DispelKindBySpellID and WR_PaladinForever_DispelKindBySpellID(num) or nil
                if idKind == "poison" or idKind == "disease" or idKind == "magic" then return true end
                if idKind == "curse" or idKind == "bleed" then
                    sawKnownNonCleansable = true
                    return nil
                end
            end
        end
        if dt == nil or WR_PaladinForever_IsSecretValue(dt) then
            -- ★ 2026-11-16：secret dispelName 先走图集探针；能读出 curse/bleed
            -- 明确判不可驱散，能读出 magic/poison/disease 明确放行。
            local secretKind = WR_PaladinForever_ProbeSecretDispelType(dt)
            if secretKind == nil and data ~= nil then
                secretKind = WR_PaladinForever_ProbeDispelFromAura(data)
            end
            if secretKind == "poison" or secretKind == "disease" or secretKind == "magic" then return true end
            if secretKind == "curse" or secretKind == "bleed" then
                sawKnownNonCleansable = true
                return nil
            end
            -- dispelName 读不到时，名字不是「诅咒」且 canActivePlayerDispel 明确 true
            -- 才可当作可驱散（只在这一条名字可读时使用，避免 secret 名字误信）。
            if can == true and type(name) == "string" and not WR_PaladinForever_IsSecretValue(name) then
                return true
            end
            sawUnknown = true
            return nil
        end
        local k = WR_PaladinForever_NormalizeDispelType(dt)
        if k == "poison" or k == "disease" or k == "magic" then return true end
        if k == "curse" or k == "bleed" then
            sawKnownNonCleansable = true
        else
            sawUnknown = true
        end
        return nil
    end

    -- ① C_UnitAuras：逐条读 name / dispelName；secret 字段由 pcall 隔离。
    if C_UnitAuras ~= nil and C_UnitAuras.GetAuraDataByIndex ~= nil then
        for i = 1, 40 do
            local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
            if not ok then sawUnknown = true; break end
            if data == nil then break end
            local okN, name = pcall(function() return data.name end)
            local okD, dt = pcall(function() return data.dispelName end)
            if not okD or dt == nil or WR_PaladinForever_IsSecretValue(dt) then
                local okT, dt2 = pcall(function() return data.dispelType end)
                if okT and not WR_PaladinForever_IsSecretValue(dt2) then dt = dt2 else dt = nil end
            end
            if not okN then name = nil end
            local okS, spellId = pcall(function() return data.spellId end)
            local okCan, can = pcall(function() return data.canActivePlayerDispel end)
            local okCheck, hit = pcall(consider, name or "aura", dt, spellId, can, data)
            if okCheck and hit == true then return true end
            if not okCheck then sawUnknown = true end
        end
    end

    -- ② UnitDebuff（经典接口 / 兼容 shim）：name, icon, count, dispelType 在第 1/4 位。
    if UnitDebuff ~= nil then
        for i = 1, 40 do
            local ok, name, icon, count, dt, duration, expiration, source, stealable, nameplate, spellId = pcall(UnitDebuff, unit, i)
            if not ok then sawUnknown = true; break end
            local okNil, isNil = pcall(function() return name == nil end)
            if okNil and isNil then break end
            if not okNil then name = "aura" end
            local okCheck, hit = pcall(consider, name, dt, spellId)
            if okCheck and hit == true then return true end
            if not okCheck then sawUnknown = true end
        end
    end

    -- ③ UnitAura（部分客户端仍暴露）：name, icon, count, dispelType 在第 1/4 位。
    if UnitAura ~= nil then
        for i = 1, 40 do
            local ok, name, icon, count, dt, duration, expiration, source, stealable, nameplate, spellId = pcall(UnitAura, unit, i, "HARMFUL")
            if not ok then sawUnknown = true; break end
            local okNil, isNil = pcall(function() return name == nil end)
            if okNil and isNil then break end
            if not okNil then name = "aura" end
            local okCheck, hit = pcall(consider, name, dt, spellId)
            if okCheck and hit == true then return true end
            if not okCheck then sawUnknown = true end
        end
    end

    -- ★ 2026-11-18 复查修复：unknown（secret 类型）存在时绝不能判 false。
    --   疾病（感染之伤等）在战斗中 dispelName/类型全是 secret → 记 sawUnknown；
    --   只要同时有任一可读的诅咒/流血/黑名单 debuff，旧写法一票否决返回 false，
    --   UnitHasDispel 在多API扫描层直接判无 → 清洁术永不点亮。
    --   与严格探针同口径：只有「全部可读且没有一个可驱散类型」才允许判无。
    if sawKnownNonCleansable and not sawUnknown then return false end
    if sawAny and not sawUnknown then return false end
    return nil
end

-- ============================================================
-- ★ 2026-11-16：EllesmereUI Player Aura Bars 桥接
-- 用户使用 EllesmereUI 的 Player Aura Bars 时，Blizzard BuffFrame/DebuffFrame 被隐藏，
-- 且 in-combat C_UnitAuras 读取被拒；自定义 AuraButton 上的引擎 dispel 纹理仍由
-- 非 taint 引擎维护。这里捕获 EUI 的 debuff 容器，扫描按钮的引擎 dispel 纹理，
-- 得到与 DebuffFrame 等价的类型信号。
-- ============================================================
WR_PaladinForever_EUI_DebuffContainer = nil
WR_PaladinForever_EUI_Buttons = WR_PaladinForever_EUI_Buttons or setmetatable({}, { __mode = "k" })
-- ★★★ 2026-11-19 十四次修复：给每枚 EUI 光环按钮打上「容器 / 单位 / 是否减益组」。
--   AddGroupToContainer → MakeInitializer 是同步调用，用这个字段把组信息带进按钮初始化闭包；
--   按钮可能是延迟创建的（池化），所以必须在 MakeInitializer 的闭包里捕获，而不是创建时读取。
WR_PaladinForever_EUI_PendingGroup = nil
-- 诊断：最近一次「减益按钮存在性」扫描结果（shown / scanned / at）
WR_PaladinForever_EUI_PresenceLast = nil

local function WR_PaladinForever_EUI_Install()
    local EUI = _G and _G.EllesmereUI or nil
    if type(EUI) ~= "table" then return end
    -- ★★ 2026-11-16 用户报错修复（Paladin_Forever_Prot.lua:1799 attempt to call a nil value）：
    --   EllesmereUI 的 _pabInternals 由 NewInternals 生成，未登记字段的【读取】会走
    --   __index 直接 error（不是返回 nil）："has no entry __WR_PaladinCleanseSetter"。
    --   旧代码直接 I.__WR_PaladinCleanseSetter 触发该错误；而本 install 是
    --   Paladin_Forever.lua 的文件级调用 —— 一抛错，整个文件后续定义全部中断，
    --   WR_PaladinForever_CleanseStep / Seal / SpellKnown 等全部变成 nil。
    --   所有内部表读取一律 rawget，避免碰到严格 __index；文件级调用再加 pcall 兜底。
    local mods = rawget(EUI, "_ModuleNS")
    local ns = type(mods) == "table" and rawget(mods, "EllesmereUIUnitFrames") or nil
    local I = type(ns) == "table" and rawget(ns, "_pabInternals") or nil
    if type(I) ~= "table" or rawget(I, "broken") then return end
    local list = rawget(I, "debuffsContainerSetters")
    if type(list) ~= "table" then return end
    -- setter 与 AK hook 分开守卫：首次调用如果 AuraKit 尚未加载，不能因为
    -- setter 标记已写就永久跳过 AK hook（后续 ADDON_LOADED 需要补挂）。
    if rawget(I, "__WR_PaladinCleanseSetter") ~= true then
        -- ★ rawset：绕过 NewInternals 的严格 __newindex，标记写入绝不能抛错。
        rawset(I, "__WR_PaladinCleanseSetter", true)
        -- NewInternals 的 fan-out 会在追加时立即回调当前值，因此这行能拿到已创建容器。
        local idx = #list + 1
        if list[idx] == nil then
            list[idx] = function(v)
                WR_PaladinForever_EUI_DebuffContainer = v
            end
        end
    end

    -- ★★★ 2026-11-19 十四次修复：挂 AK.MakeInitializer + AK.AddGroupToContainer。
    --   旧实现只包 group.extraInit —— 但 unit frame 的光环组（DeclareElementGroup）
    --   根本不传 extraInit，整个容器一枚按钮都记录不到，真机 EUI减益容器=true 却扫不到按钮
    --   就是这个原因。改挂 MakeInitializer 后，每一组的每枚按钮（含延迟池化创建的）都能拿到。
    --   同时记录：容器、单位（container.unit）、是否减益组（filter 含 HARMFUL / debuffOnly）。
    --   用途：战斗内光环数据被 secret 拒绝时，用「减益按钮是否处于显示状态」判存在性。
    local AK = rawget(EUI, "AuraKit")
    if type(AK) == "table" and type(AK.AddGroupToContainer) == "function"
        and not rawget(AK, "__WR_PaladinCleanseHooked") then
        rawset(AK, "__WR_PaladinCleanseHooked", true)
        local origMake = rawget(AK, "MakeInitializer")
        if type(origMake) == "function" then
            AK.MakeInitializer = function(styleKey, extra, rec)
                local pending = WR_PaladinForever_EUI_PendingGroup
                local Init = origMake(styleKey, extra, rec)
                if type(Init) ~= "function" then return Init end
                return function(button, d, style)
                    if pending ~= nil and button ~= nil then
                        local info = WR_PaladinForever_EUI_Buttons[button]
                        if info == nil then
                            info = {}
                            WR_PaladinForever_EUI_Buttons[button] = info
                        end
                        info.container = pending.container
                        info.unit = pending.unit
                        if pending.harmful then info.harmful = true end
                        -- 缓存 dispel 纹理引用（战斗内 holder:GetRegions 可能被拒，
                        -- 缓存好的引用仍能读 atlas/颜色）。
                        if type(d) == "table" and d.dispelHolder ~= nil
                            and type(style) == "table"
                            and (style.dispelBorder == true or style.dispelTypeIcon ~= nil) then
                            info.holder = d.dispelHolder
                            info.style = style
                            info.iconTex = d.dispelIconTex
                            info.strips = d.dispelStrips
                        end
                    end
                    return Init(button, d, style)
                end
            end
        end
        local origAdd = AK.AddGroupToContainer
        AK.AddGroupToContainer = function(container, group)
            local harmful = false
            if type(group) == "table" then
                local f = group.filter
                if type(f) == "table" then
                    for fi = 1, #f do
                        local tok = f[fi]
                        if type(tok) == "string"
                            and string.find(string.upper(tok), "HARMFUL", 1, true) then
                            harmful = true
                            break
                        end
                    end
                end
                if not harmful and group.debuffOnly == true then harmful = true end
            end
            local u = nil
            pcall(function()
                u = container.unit
                if type(u) ~= "string" and type(container.GetUnit) == "function" then
                    u = container:GetUnit()
                end
            end)
            if type(u) ~= "string" then u = nil end
            WR_PaladinForever_EUI_PendingGroup = {
                container = container, harmful = harmful, unit = u,
            }
            local okA, ret = pcall(origAdd, container, group)
            WR_PaladinForever_EUI_PendingGroup = nil
            if not okA then error(ret, 0) end
            return ret
        end
    end
end

local function WR_PaladinForever_TextureDispelKind(texture, style)
    if texture == nil then return nil end
    -- 只读当前显示的纹理：同一按钮会保留旧毒/旧魔法的隐藏 strip，不能把旧颜色
    -- 当成本次诅咒的证据。
    -- ★ 2026-11-16：必须先看 IsVisible（父级隐藏也算不可见）。只看 IsShown 时，
    -- EUI 按钮隐藏后子纹理仍可能 IsShown=true，旧诅咒/旧毒的 strip 会被当成当前光环，
    -- 导致战斗内 magic 被旧 curse 证据压成 false。IsVisible 不可用时才回退 IsShown。
    local okVis, visible = pcall(function() return texture:IsVisible() end)
    if okVis and not WR_PaladinForever_IsSecretValue(visible) then
        local okFalse, isFalse = pcall(function() return visible == false end)
        if okFalse and isFalse then return nil end
    else
        local okShow, shown = pcall(function() return texture:IsShown() end)
        if okShow and not WR_PaladinForever_IsSecretValue(shown) then
            local okFalse, isFalse = pcall(function() return shown == false end)
            if okFalse and isFalse then return nil end
        end
    end
    local okA, atlas = pcall(function() return texture:GetAtlas() end)
    if okA and type(atlas) == "string" and not WR_PaladinForever_IsSecretValue(atlas) then
        local okL, s = pcall(string.lower, atlas)
        if okL and type(s) == "string" then
            if string.find(s, "curse", 1, true) then return "curse" end
            if string.find(s, "bleed", 1, true) then return "bleed" end
            if string.find(s, "poison", 1, true) then return "poison" end
            if string.find(s, "disease", 1, true) then return "disease" end
            if string.find(s, "magic", 1, true) then return "magic" end
        end
    end
    local okV, r, g, b = pcall(function() return texture:GetVertexColor() end)
    if not okV or type(r) ~= "number" or WR_PaladinForever_IsSecretValue(r)
        or type(g) ~= "number" or WR_PaladinForever_IsSecretValue(g)
        or type(b) ~= "number" or WR_PaladinForever_IsSecretValue(b) then
        return nil
    end
    -- 优先用 EUI 样式自己的色表（用户改过 dispel 颜色时仍能识别）。
    if type(style) == "table" and type(style.dispelColorMap) == "table" then
        for token, color in pairs(style.dispelColorMap) do
            local okRGB, cr, cg, cb = pcall(function() return color:GetRGB() end)
            if okRGB and type(cr) == "number" and type(cg) == "number" and type(cb) == "number"
                and math.abs(r - cr) < 0.06 and math.abs(g - cg) < 0.06 and math.abs(b - cb) < 0.06 then
                return string.lower(token)
            end
        end
    end
    local colors = {
        { kind = "magic", r = 0.349, g = 0.475, b = 1.0 },
        { kind = "curse", r = 0.636, g = 0.0, b = 0.64 },
        { kind = "disease", r = 0.671, g = 0.384, b = 0.098 },
        { kind = "poison", r = 0.0, g = 0.706, b = 0.286 },
        { kind = "bleed", r = 0.75, g = 0.15, b = 0.15 },
    }
    for i = 1, #colors do
        local c = colors[i]
        if math.abs(r - c.r) < 0.06 and math.abs(g - c.g) < 0.06 and math.abs(b - c.b) < 0.06 then
            return c.kind
        end
    end
    return nil
end

WR_PaladinForever_ScanEUIAuraButtons = function()
    local container = WR_PaladinForever_EUI_DebuffContainer
    if container == nil then return nil end
    local groups = {}
    local okG, groupList = pcall(function() return container.auraGroups end)
    if okG and type(groupList) == "table" then
        for i = 1, #groupList do groups[#groups + 1] = groupList[i] end
    end
    if #groups == 0 then
        pcall(function()
            for _, group in container:EnumerateAuraGroups() do
                groups[#groups + 1] = group
            end
        end)
    end
    if #groups == 0 then return nil end

    -- ★ 2026-11-16 用户报错：EUI 按钮存在、但战斗中纹理类型/颜色读不到时，
    -- 旧代码把「扫到纹理但类型未知」当成「明确无驱散」，直接返回 false，
    -- 于是 UnitHasDispel 提前判无，战斗内魔法/疾病/中毒全部不点亮。
    -- 现在 sawAny 只记录「读到了明确类型」；类型未知一律返回 nil，继续走
    -- DebuffFrame / 严格探针 / 缓存路径，绝不把未知当无。
    local sawAny, sawKnownNon = false, false
    -- ★ 2026-11-17：只要还有「可见按钮但纹理类型读不出来」的未知项，就绝不能
    -- 返回 false（= 明确无驱散）。旧逻辑只看 sawKnownNon，EUI 战斗内 strip
    -- 顶点色是 secret（读不到），此时若另一枚旧诅咒按钮可见，会把当前疾病/
    -- 中毒压成 false，UnitHasDispel 提前判无。未知一律交给后续引擎探测器。
    local sawUnknownButton = false
    local inspectKnown = false
    local function inspectTexture(texture, style)
        if texture == nil then return false end
        local kind = WR_PaladinForever_TextureDispelKind(texture, style)
        if kind == nil then return false end
        sawAny = true
        inspectKnown = true
        if kind == "poison" or kind == "disease" or kind == "magic" then return true end
        if kind == "curse" or kind == "bleed" then sawKnownNon = true end
        return false
    end

    local function inspect(button)
        if button == nil then return false end
        inspectKnown = false
        local info = WR_PaladinForever_EUI_Buttons[button]
        if info == nil then
            info = {}
            WR_PaladinForever_EUI_Buttons[button] = info
        end
        if info.holder ~= nil then
            local okR, regions = pcall(function() return info.holder:GetRegions() end)
            if okR and type(regions) == "table" then
                for _, texture in ipairs(regions) do
                    if inspectTexture(texture, info.style) then return true end
                end
            end
        end
        -- ★ 2026-11-16：hook 缓存的引擎图标纹理 / 四条 strip —— GetRegions
        -- 被拒时的后备通道。图标走图集名（战斗内可读），strip 走颜色（脱战可读）。
        if info.iconTex ~= nil then
            if inspectTexture(info.iconTex, info.style) then return true end
        end
        if info.strips ~= nil then
            for si = 1, 4 do
                if inspectTexture(info.strips[si], info.style) then return true end
            end
        end
        if info.textures ~= nil then
            for _, texture in ipairs(info.textures) do
                if inspectTexture(texture, info.style) then return true end
            end
        end
        local okN, n = pcall(function() return button:GetDispelTypeTextureCount() end)
        if not okN or type(n) ~= "number" or WR_PaladinForever_IsSecretValue(n) then
            if not inspectKnown then sawUnknownButton = true end
            return false
        end
        info.textures = {}
        for i = 1, n do
            local okT, texture = pcall(function() return button:GetDispelTypeTexture(i) end)
            if okT and texture ~= nil then
                info.textures[#info.textures + 1] = texture
                if inspectTexture(texture, info.style) then return true end
            end
        end
        if not inspectKnown then sawUnknownButton = true end
        return false
    end

    for i = 1, #groups do
        local group = groups[i]
        local okF, frames = pcall(function() return group:GetFramesByIndex() end)
        if not okF or type(frames) ~= "table" then
            local okD, direct = pcall(function() return group.framesByIndex end)
            if okD and type(direct) == "table" then frames = direct end
        end
        if type(frames) == "table" then
            for _, button in pairs(frames) do
                if inspect(button) then return true end
            end
        end
    end

    -- ★ 2026-11-16：回调/容器创建顺序不确定时，GetFramesByIndex 可能只有当前
    -- 活跃按钮；补一层容器子按钮扫描，把隐藏按钮的纹理引用也缓存起来。
    -- 只缓存/判断，不把隐藏纹理的旧颜色当类型（inspectTexture 有 IsShown 过滤）。
    local function scanTree(root, depth)
        if root == nil or depth > 4 then return false end
        local okK, kids = pcall(function() return root:GetChildren() end)
        if not okK or type(kids) ~= "table" then return false end
        for _, child in pairs(kids) do
            if inspect(child) then return true end
            if scanTree(child, depth + 1) then return true end
        end
        return false
    end
    if scanTree(container, 0) then return true end
    if sawKnownNon and not sawUnknownButton then return false end
    -- 只有所有可见按钮都读到明确类型、且至少一个明确不可驱散时才返回 false；
    -- 任何未知按钮都返回 nil，交给引擎探测器与后续通道。
    return nil
end

-- ★★★ 2026-11-19 十四次修复：EUI 减益按钮「存在性」探测（不读任何光环字段）。
--   战斗内 C_UnitAuras 对 tainted 插件直接拒绝，UNIT_AURA 数据拿不到；
--   但 EUI 的光环按钮由引擎侧 AuraContainer 驱动，显示状态是普通布尔，
--   所以「有显示中的减益按钮」= 该单位身上有减益。
--   返回：true=有显示中的减益按钮 / false=减益组存在但全部隐藏 / nil=没有减益组按钮信息。
--   ★ 2026-11-19 十五次修复：12.x 里光环按钮的显示状态是 secret，受限战斗中
--     `button:IsShown()` 会被整棵子树拒绝（EUI 源码注释原话："its shown state is secret
--     even out of restriction"）。实机 740 枚减益按钮全部读失败。这里加 5 秒熔断，
--     避免每 tick 对几百枚按钮做无意义的 pcall。
function WR_PaladinForever_EUI_HarmfulPresence(unit)
    local now = GetTime()
    if WR_PaladinForever_EUI_PresenceBlockedUntil
        and now < WR_PaladinForever_EUI_PresenceBlockedUntil then
        WR_PaladinForever_EUI_PresenceLast = {
            shown = false, scanned = 0, tried = 0, blocked = true, unit = unit, at = now,
        }
        return nil
    end
    local shown, scanned, tried = false, 0, 0
    if type(WR_PaladinForever_EUI_Buttons) == "table" then
        for b, info in pairs(WR_PaladinForever_EUI_Buttons) do
            if type(info) == "table" and info.harmful then
                local u = info.unit
                if u == nil or u == unit then
                    tried = tried + 1
                    local okS, s = pcall(function() return b:IsShown() end)
                    if okS and type(s) == "boolean" then
                        scanned = scanned + 1
                        if s then
                            shown = true
                            break
                        end
                    end
                end
            end
        end
    end
    WR_PaladinForever_EUI_PresenceLast = {
        shown = shown, scanned = scanned, tried = tried, unit = unit, at = now,
    }
    if shown then return true end
    if scanned > 0 then return false end
    if tried > 0 then
        -- 全部读失败 = 该客户端禁止读按钮状态 → 熔断 5 秒
        WR_PaladinForever_EUI_PresenceBlockedUntil = now + 5
    end
    return nil
end

_G.WR_PaladinForever_EUI_Install = WR_PaladinForever_EUI_Install
_G.WR_PaladinForever_ScanEUIAuraButtons = WR_PaladinForever_ScanEUIAuraButtons

-- ★ 2026-11-16：文件级 install 必须 pcall —— EllesmereUI 版本差异再出任何异常，
-- 也不能让 Paladin_Forever.lua 的剩余函数定义（CleanseStep/Seal/SpellKnown 等）中断。
pcall(WR_PaladinForever_EUI_Install)
if type(CreateFrame) == "function" then
    local euiWatch = CreateFrame("Frame")
    euiWatch:RegisterEvent("ADDON_LOADED")
    euiWatch:RegisterEvent("PLAYER_LOGIN")
    euiWatch:RegisterEvent("PLAYER_ENTERING_WORLD")
    euiWatch:SetScript("OnEvent", function()
        pcall(WR_PaladinForever_EUI_Install)
        -- 登录/进世界时把容器里所有按钮的 dispel 纹理引用先缓存好；
        -- 之后战斗内 button 本体被 secret 限制时仍能读缓存纹理。
        pcall(WR_PaladinForever_ScanEUIAuraButtons)
    end)
end

-- ★★★ 2026-11-15 用户报错修复：
--   DebuffFrameMixin:UpdateAuras 把 auraData.dispelName 原样存进
--   DebuffFrame.auraInfo[i].debuffType；战斗中 dispelName 仍是 secret string，
--   插件对 secret 字符串做任何 == / ~= 比较都会抛
--   "attempt to compare ... secret string value"（本条报错即此）。
--   所以 auraInfo 只能作为「有 debuff 条目」的存在性信号，绝不能拿 debuffType 比较；
--   真正的驱散类型改读暴雪 AuraButton 的 DebuffBorder 图集名：
--   Blizzard 非 taint 代码已用 secret 的 debuffType 调 AuraUtil.SetAuraBorderAtlas，
--   把普通字符串图集名（ui-debuff-border-poison/-disease/-magic/-curse/-bleed）写在
--   贴图上，插件读 GetAtlas()/GetTexture() 即可安全区分类型。
--   返回：true=有可驱散 debuff / false=没有 / nil=帧不可用（交回旧路径）。
function WR_PaladinForever_PlayerDebuffDispelByBlizzardFrame()
    local frame = _G and _G.DebuffFrame or nil
    if type(frame) ~= "table" and type(frame) ~= "userdata" then return nil end
    local info = frame.auraInfo
    local deadly = frame.deadlyDebuffInfo
    local auraFrames = frame.auraFrames
    local frameVisible = false
    local okVis, vis = pcall(function() return frame:IsVisible() end)
    if okVis and not WR_PaladinForever_IsSecretValue(vis) then frameVisible = vis == true end
    if type(info) ~= "table" and type(deadly) ~= "table" and type(auraFrames) ~= "table" then
        return nil
    end

    local sawSecretType = false
    local sawKnownNonCleansable = false
    local sawAnyEntry = false
    -- ★ 2026-11-18：类型整体读不到（atlas/字段为 nil 或 secret）也必须记为 unknown。
    --   否则「疾病(类型 secret) + 可读诅咒」并存时会被一票否决判无 → 清洁术不亮。

    local function scanValue(v)
        -- 注意：不能先写 v == nil —— secret string 参与 == 比较同样会抛错。
        if type(v) ~= "string" then
            sawUnknownType = true
            return nil
        end
        sawAnyEntry = true
        if WR_PaladinForever_IsSecretText(v) then
            sawSecretType = true
            sawUnknownType = true
            return nil
        end
        local k = WR_PaladinForever_NormalizeDispelType(v)
        if k == "poison" or k == "disease" or k == "magic" then return true end
        -- ★ 2026-11-15：普通字符串明确是诅咒/流血时记下「不可驱散」，
        --   阻止后面「secret 类型」兜底把它当成可驱散而乱放清洁术。
        if k == "curse" or k == "bleed" then
            sawKnownNonCleansable = true
        else
            sawUnknownType = true
        end
        return nil
    end

    -- ① auraInfo / deadlyDebuffInfo：只在非 secret 时按字段直接判类型；
    --    战斗中的 secret debuffType 仅记录「有带类型的 debuff」。
    local function scanList(list)
        if type(list) ~= "table" then return false end
        for i = 1, #list do
            local okE, entry = pcall(function() return list[i] end)
            if okE and type(entry) == "table" then
                sawAnyEntry = true
                local keys = { "dispelType", "debuffType", "dispelName" }
                for j = 1, #keys do
                    local okV, v = pcall(function() return entry[keys[j]] end)
                    if okV then
                        local okScan, hit = pcall(scanValue, v)
                        if okScan and hit == true then return true end
                    end
                end
            end
        end
        return false
    end
    if scanList(info) then return true end
    if scanList(deadly) then return true end

    -- ② 暴雪 DebuffFrame 的 auraFrames[i].DebuffBorder：
    --    引擎/非 taint 代码已按真实 debuffType 设置图集（普通字符串），可安全读取。
    local function borderKind(button)
        local okB, border = pcall(function() return button.DebuffBorder end)
        if not okB or border == nil then return nil end
        local s = nil
        local okA, atlas = pcall(function() return border:GetAtlas() end)
        if okA and type(atlas) == "string" and not WR_PaladinForever_IsSecretText(atlas) then
            local okL, lowered = pcall(string.lower, atlas)
            if okL and type(lowered) == "string" then s = lowered end
        end
        if s == nil then
            local okT, path = pcall(function() return border:GetTexture() end)
            if okT and type(path) == "string" and not WR_PaladinForever_IsSecretText(path) then
                local okL2, lowered2 = pcall(string.lower, path)
                if okL2 and type(lowered2) == "string" then s = lowered2 end
            end
        end
        if s == nil then return nil end
        if string.find(s, "curse", 1, true) then return "curse" end
        if string.find(s, "bleed", 1, true) then return "bleed" end
        if string.find(s, "poison", 1, true) then return "poison" end
        if string.find(s, "disease", 1, true) then return "disease" end
        if string.find(s, "magic", 1, true) then return "magic" end
        return nil
    end

    -- 只检查「当前正在显示」的按钮：隐藏按钮会保留上一次显示时的
    -- DebuffBorder 图集（例如之前的毒），把旧毒图集当成本次诅咒的证据
    -- 正是「中诅咒后清洁术不断亮」的另一条来源。
    local function buttonVisible(button)
        -- IsVisible 会同时考虑父级是否隐藏；IsShown 只看自身标记。
        local okV, visible = pcall(function() return button:IsVisible() end)
        if okV and not WR_PaladinForever_IsSecretValue(visible) then return visible == true end
        local okS, shown = pcall(function() return button:IsShown() end)
        if okS and not WR_PaladinForever_IsSecretValue(shown) then return shown == true end
        -- 没有 IsVisible/IsShown 的极老客户端/测试桩：按可见处理
        return true
    end

    local function scanButtons(list)
        if type(list) ~= "table" then return false end
        for i = 1, #list do
            local okB, button = pcall(function() return list[i] end)
            if okB and button ~= nil and buttonVisible(button) then
                sawAnyEntry = true
                -- ★ 2026-11-15 修复：不再依赖 hasValidInfo == true。
                --   12.x 的 hasValidInfo 可能是 secret boolean，一比较就抛错，
                --   旧写法会把带诅咒边框的按钮整个跳过；随后「secret 类型」
                --   兜底误判为可驱散 → 中诅咒时清洁术异常乱放。
                --   直接读 DebuffBorder 的普通字符串图集名即可安全区分类型。
                local k = borderKind(button)
                if k == nil then sawUnknownType = true end
                if k == "poison" or k == "disease" or k == "magic" then return true end
                if k == "curse" or k == "bleed" then sawKnownNonCleansable = true end
            end
        end
        return false
    end
    if scanButtons(auraFrames) then return true end

    local container = frame.AuraContainer
    if container ~= nil then
        local okC, children = pcall(function() return container:GetChildren() end)
        if okC and type(children) == "table" then
            if scanButtons(children) then return true end
        end
    end

    -- ③ 2026-11-16：不再做「secret 类型 = 可驱散」兜底。
    --   旧兜底是「中诅咒后清洁术不断驱散」的直接来源：诅咒的 debuffType 在战斗中
    --   也是 secret，读不到图集时会把所有 secret debuff 当成可驱散。
    --   现在只有明确证据才放行；读不到类型时返回 nil（未知），交给后续
    --   严格探针/缓存路径，绝不猜可驱散。
    -- ★ 2026-11-18 复查修复：unknown（secret / 读不到类型）优先级高于 known-non。
    --   战斗中疾病/中毒的类型全是 secret；旧写法在「疾病 + 任一可读诅咒」并存时
    --   一票否决判无 → 清洁术不亮。只有全部条目可读且无一个可驱散类型才判无。
    local sawUnknownAny = sawSecretType or sawUnknownType
    if sawKnownNonCleansable and not sawUnknownAny then return false end
    -- 帧可见但只扫到无类型/非可驱散条目 → 可判无；含 unknown 条目时不能判无。
    if frameVisible and sawAnyEntry and not sawUnknownAny then return false end
    return nil
end

-- ============================================================
-- ★★★ 2026-11-17 复查：引擎级「可驱散类型」探测容器
-- 12.x 战斗内光环字段全是 secret，C_UnitAuras 的索引/槽位查询会被
-- RequiresUnitAuraAccess 拒绝；但 AuraContainer 的过滤器由引擎侧求值：
--   filter = "HARMFUL" + candidateFilters.includeDispelTypes = { Magic, Disease, Poison }
--   只保留清洁术能驱散的三种 debuff（诅咒 / 流血不会进来），完全不读 secret 光环字段。
-- 旧版用 "HARMFUL|RAID" 是错误的：该 token 只表示「团队 debuff」，
--   不表示「玩家本人可驱散」。单体 / 5 人本里的疾病、中毒、魔法不会被它命中，
--   探测容器恒为空 → UnitHasDispel 恒 false → 战斗中清洁术永不点亮。
-- 登录/进世界时预创建 1×1 透明容器（战斗内不能创建），每 tick 只读
-- group:GetFramesByIndex() 的数组长度；>0 即说明存在可驱散 debuff。
-- ============================================================
WR_PaladinForever_CLEANSE_PROBE_FILTER = "HARMFUL"
-- 同时带英文枚举与中文显示名：不同客户端 auraData.dispelName 的本地化形态不一致。
WR_PaladinForever_CLEANSE_PROBE_DISPEL_TYPES = {
    -- ★ 2026-11-18：补全大小写变体。auraData.dispelName 的形态在不同客户端
    --   服务端实现里不统一（Magic / magic / MAGIC / 本地化中文），
    --   键差一个大小写引擎侧就匹配不上 → 组恒空 → 疾病/魔法/中毒全部探不到。
    Magic = true, Disease = true, Poison = true,
    magic = true, disease = true, poison = true,
    MAGIC = true, DISEASE = true, POISON = true,
    ["魔法"] = true, ["疾病"] = true, ["中毒"] = true,
}
-- ★★★ 2026-11-18 三次修复：受限内容「免读回」通道。
--   EUI AuraKit 1277-1280 实证：受限内容下引擎给 AuraButton 挂
--   DenyTaintedAccessWhenAurasAreSecret —— 挂牌之后插件侧对按钮的任何读取
--   （GetAtlas / GetVertexColor / IsShown / DebuffBorder / GetDispelTypeTexture）
--   都被拒绝；DBM AuraTracking 870 同款（ShouldAurasBeSecret() 时跳过按钮配置）。
--   前两版「注册图标/边框再读回分类」在真机战斗中结构性失效：
--   离线夹具全绿、真机分类全 unknown。本版改为三条免读回通道：
--   ① WR_CLEANSE_PROBE_YOU 组：filter = "HARMFUL|RAID_PLAYER_DISPELLABLE"
--     （EUI RaidFrames 生产同款，EUI_RaidFrames_AuraContainers 3294/661）。
--     引擎侧按职业/专精判「我本人可驱散」，防骑清洁术属职业驱散；
--     组内有帧 = 引擎已回答「有我能驱散的 debuff」，零读回。
--   ② 已知 debuff ID 存在性直查（EUI AuraBuffReminders NON_SECRET_SPELL_IDS
--     同款，EllesmereUIAuraBuffReminders.lua 499-550）：未上秘密旗的 spellID
--     战斗中 GetPlayerAuraBySpellID 照样返回非 nil；「非 nil 即存在」。
--     nil 一律当未知（秘密旗 ID 返回 nil ≠ 不存在），绝不判无。
--   ③ includeDispelTypes 组保留（脱战 / 非受限内容仍由它精确判型）。
WR_PaladinForever_CLEANSE_PROBE_YOU_FILTER = "HARMFUL|RAID_PLAYER_DISPELLABLE"
-- ★★★ 2026-11-19 八次修复：按【驱散类型】过滤的免读回存在性组。
--   用户连续五次截图实锤（毒药 744 / 暗言术：痛 15654 / 毒药 13298 / 毒性钉刺 5416 /
--   毒性唾液 7125 / 脆弱 12530 / 减速术 11436 / 烈焰震击 23038）：战斗里
--   auraData.dispelName / spellId 是 secret，candidateFilters 读 dispelName 也被
--   REDACTED —— 之前所有「读回类型」的通道在真机战斗中全部落空。
--   但**过滤器令牌是引擎侧求值**的：引擎自己知道每条光环的驱散类型，
--   "HARMFUL|Magic" 这类令牌由引擎筛选，插件只数帧数 —— 零读回、零比较、不吃 secret。
--   组内帧数 > 0 即「明确存在该类型的 debuff」，直接对应清洁术可驱散。
WR_PaladinForever_CLEANSE_TYPE_FILTERS = {
    { key = "magic",   filter = "HARMFUL|Magic",   group = "WR_CLEANSE_TYPE_MAGIC" },
    { key = "disease", filter = "HARMFUL|Disease", group = "WR_CLEANSE_TYPE_DISEASE" },
    { key = "poison",  filter = "HARMFUL|Poison",  group = "WR_CLEANSE_TYPE_POISON" },
}
-- ★ 已知可驱散 debuff ID → 类型（服务端截图实锤 + 经典常见；实测命中后追加）：
--   ★★★ 2026-11-18 四次修复：用户三张截图实锤 744 / 13298 / 15654 全不在
--   第三版白名单内——免读回、免容器的 ID 直查通道（真机唯一不依赖探测容器的
--   通道）对用户真实中的毒形同虚设。补齐截图三 ID + 经典常见 debuff 全 rank
--   家族。白名单多录只是多查几个 ID，查不到静默跳过，无副作用；
--   绝不收录诅咒类 ID（清洁术驱不了诅咒，误收录会空放 GCD）。
WR_PaladinForever_CLEANSE_KNOWN_AURA_IDS = {
    -- 中毒（poison）
    [5416] = "poison",   -- 毒性钉刺（2026-11-18 截图实锤）
    [744] = "poison",    -- 毒药（蜘蛛/野兽类，2026-11-18 截图实锤）
    [13298] = "poison",  -- 毒药（蛇虫类，2026-11-18 截图实锤）
    -- ★★★ 2026-11-19 七次修复：用户截图实锤「毒性唾液 · 法术ID 7125 · 中毒 · 剩余2分钟」
    --   每6秒造成17点自然伤害 + 每6秒吸取20点法力值。该 ID 此前完全没进白名单，
    --   而本服的「毒」家族 ID 极其分散（744/13298/5416/7125 各不相关），
    --   靠逐条截图补录永远补不完 —— 同批修复还给静态提示分类（GetSpellByID）
    --   补了「法术ID」行与顶层 id 两条证据，让未录入的 ID 也能自动判型。
    [7125] = "poison",   -- 毒性唾液（2026-11-19 用户截图实锤）
    -- 疾病（disease）
    [3427] = "disease",  -- 感染之伤（2026-11-17 截图实锤）
    -- 魔法（magic）：暗言术：痛全 rank（15654 为 2026-11-18 截图实锤）
    [589] = "magic", [591] = "magic", [592] = "magic", [970] = "magic",
    [992] = "magic", [2767] = "magic", [10892] = "magic", [10893] = "magic",
    [10894] = "magic", [15654] = "magic",
    -- 魔法：腐蚀术全 rank
    [172] = "magic", [173] = "magic", [6222] = "magic", [6223] = "magic",
    -- 魔法：献祭全 rank
    [348] = "magic", [707] = "magic", [1094] = "magic", [2941] = "magic", [11665] = "magic",
    -- 魔法：控制类
    [118] = "magic",     -- 变形术
    [13710] = "magic",   -- 缓速
    [8122] = "magic",    -- 心灵控制
    -- ★ 2026-11-19 新增：减速术全 rank（11436=Rank1/13173=Rank2/23100=Rank3，用户截图实锤 11436）
    [11436] = "magic",   -- 减速术 Rank 1（2026-11-19 用户截图实锤）
    [13173] = "magic",   -- 减速术 Rank 2
    [23100] = "magic",   -- 减速术 Rank 3
    -- ★ 寒冰箭自带减速（无独立 debuff ID，但寒冰箭本体是魔法 debuff）
    [7322] = "magic",    -- 寒冰箭 Rank 1（减速 debuff 本体）
    [8376] = "magic",    -- 寒冰箭 Rank 2
    -- ★ 奥术减速（奥术飞弹/奥术射击附带）
    [3604] = "magic",    -- 奥术射击 Rank 1（减速 debuff 本体）
    -- ★ 羊/冰环/恐惧类（都是魔法类型，但持续时间短且常免疫，清洁术能驱）
    [118] = "magic",     -- 变形术（之前已收录）
    [28271] = "magic",   -- 变形术：乌龟
    [3355] = "magic",    -- 冰冻陷阱（猎人）
    [12654] = "magic",   -- 冰霜新星（法师冰环）
    -- ★ 2026-11-19 截图实锤：烈焰震击（萨满，全 rank），C_TooltipInfo 静态提示能读到但
    --   战斗里 spellId 也可能是 secret（EllesmereUIAuraBuffReminders NON_SECRET 策略），
    --   直接白名单兜底，让 UnitAuraIDHasDispellable 这条 spellID 通道在任何上下文
    --   下都命中；同时 PlayerAuraIDHasDispellable 也能扫到。
    [23038] = "magic",   -- 烈焰震击 Rank 1（2026-11-19 用户截图实锤）
    [23062] = "magic",   -- 烈焰震击 Rank 2
    [23063] = "magic",   -- 烈焰震击 Rank 3
    -- ★ 2026-11-19 六次修复：用户截图实锤「脆弱 · 法术ID 12530 · 魔法 · 剩余57秒」。
    --   该 debuff 由副本怪物对玩家施加（所有属性降低10点），类型=魔法，
    --   清洁术能驱；但白名单此前完全没收录 12530 → ID 直查/ID 分类两条通道全 miss，
    --   战斗内 spellId 又是 secret → tooltip 顶层 id 也读不到 → 全链 unknown → 不亮。
    [12530] = "magic",   -- 脆弱（2026-11-19 用户截图实锤，所有属性降低10点）
    -- ★★★ 2026-11-19 十八次修复：用户截图实锤「投石 · 法术ID 23380 · 魔法 · 剩余5秒」，
    --   每 3 秒造成一次奥术伤害。战斗中所有读光环字段的通道都被拒，唯一免读回的
    --   GetPlayerAuraBySpellID 只认白名单/已发现表 —— 23380 此前两条都没有 → 不亮。
    [23380] = "magic",   -- 投石（2026-11-19 用户截图实锤，每3秒奥术伤害）
    -- 魔法：诅咒类（注意：清洁术**驱不了诅咒**！以下不收录，别误加 rank 家族）
}
-- ★★★ 2026-11-19 八次修复：debuff 名称 → 驱散类型白名单。
--   受限内容里 auraData.dispelName / spellId 都可能是 secret，但服务端把 debuff
--   名字原样交给 UI（用户截图「烈焰震击 · 法术ID 23038 · 魔法」里的名字就是可读的）。
--   只要名字可读，就能按本表判型 —— 这是第四条不依赖任何秘密字段的通道。
--   只收录清洁术**确实能驱散**的类型（中毒/疾病/魔法）；诅咒类绝不收录。
WR_PaladinForever_CLEANSE_KNOWN_AURA_NAMES = {
    -- 魔法
    ["烈焰震击"] = "magic",
    ["脆弱"] = "magic",
    ["投石"] = "magic",
    ["减速术"] = "magic",
    ["缓速"] = "magic",
    ["暗言术：痛"] = "magic",
    ["暗言术:痛"] = "magic",
    ["腐蚀术"] = "magic",
    ["献祭"] = "magic",
    ["变形术"] = "magic",
    ["冰霜新星"] = "magic",
    ["冰冻陷阱"] = "magic",
    ["寒冰箭"] = "magic",
    ["奥术射击"] = "magic",
    ["心灵控制"] = "magic",
    -- 中毒
    ["毒性唾液"] = "poison",
    ["毒性钉刺"] = "poison",
    ["毒药"] = "poison",
    -- 疾病
    ["感染之伤"] = "disease",
}

-- 名称 → 类型（只认肯定证据：secret / 空 / 不在表内一律 nil）
function WR_PaladinForever_KindFromAuraName(name)
    if type(name) ~= "string" then return nil end
    if WR_PaladinForever_IsSecretValue(name) then return nil end
    local okTrim, s = pcall(string.match, name, "^%s*(.-)%s*$")
    if not okTrim or type(s) ~= "string" or s == "" then return nil end
    local kind = WR_PaladinForever_CLEANSE_KNOWN_AURA_NAMES[s]
    if kind ~= nil then return kind end
    return nil
end
_G.WR_PaladinForever_KindFromAuraName = WR_PaladinForever_KindFromAuraName

WR_PaladinForever_CleanseProbe = WR_PaladinForever_CleanseProbe or {}
WR_PaladinForever_CleanseProbeRetryAt = WR_PaladinForever_CleanseProbeRetryAt or {}
-- 按类型过滤的存在性组缓存（rec.typeGroups[key] = group）
WR_PaladinForever_CleanseTypeGroups = WR_PaladinForever_CleanseTypeGroups or {}

-- ★★★ 2026-11-18 二次修复：探测按钮注册引擎「驱散类型图标」纹理。
--   EUI AuraKit 源码实证（EllesmereUI_AuraKit.lua 251-261 / 690-706 / 940-1002）：
--   引擎 AuraButton 的驱散类型图标是「注册制」——必须在 initializeFrame
--   （按钮创建窗口；创建期之后写按钮被 DenyTaintedAccessWhenAurasAreSecret 拒绝）
--   里建持手 + CreateTexture，再 pcall(button.AddDispelTypeTexture, button, tex,
--   { style = Enum.CustomAuraButtonDispelTypeTextureStyle.Icon, showWhenHarmful
--   = true, showWhenHelpful = false })。引擎随后逐光环盖章
--   RaidFrame-Icon-DebuffPoison/Disease/Magic/Curse/Bleed 图集，
--   受限内容（战斗/首领战/挑战/PVP）内外同一机制。
--   旧版 initializeFrame 空函数什么都不注册 → 帧上无任何可读
--   类型纹理 → kind 全 unknown → 战斗中 AurasRestricted 兜底判无 →
--   中毒（毒性钉刺 5416）/疾病/魔法全部哑火。
WR_PaladinForever_CleanseDispelTex = WR_PaladinForever_CleanseDispelTex
    or setmetatable({}, { __mode = "k" })
WR_PaladinForever_CleanseDispelTexRetry = WR_PaladinForever_CleanseDispelTexRetry
    or setmetatable({}, { __mode = "k" })
function WR_PaladinForever_CleanseProbeInitFrame(button)
    if type(button) ~= "table" and type(button) ~= "userdata" then return end
    if WR_PaladinForever_CleanseDispelTex[button] ~= nil then return end
    local now = GetTime()
    local lastFail = WR_PaladinForever_CleanseDispelTexRetry[button]
    if lastFail ~= nil and (now - lastFail) < 2 then return end
    local iconStyle = Enum and Enum.CustomAuraButtonDispelTypeTextureStyle
        and Enum.CustomAuraButtonDispelTypeTextureStyle.Icon
    if iconStyle == nil then
        -- 无 Icon 枚举的旧客户端：结构上注册不了，永久记 false 防止每帧重试。
        WR_PaladinForever_CleanseDispelTex[button] = false
        return
    end
    local okHolder, holder = pcall(CreateFrame, "Frame", nil, button)
    if not okHolder or holder == nil then
        WR_PaladinForever_CleanseDispelTexRetry[button] = now
        return
    end
    pcall(function()
        holder:SetAllPoints(button)
        if type(holder.EnableMouse) == "function" then holder:EnableMouse(false) end
    end)
    local tex = holder:CreateTexture(nil, "OVERLAY")
    if tex == nil then
        WR_PaladinForever_CleanseDispelTexRetry[button] = now
        return
    end
    tex:Hide()
    local okAdd = pcall(button.AddDispelTypeTexture, button, tex, {
        style = iconStyle,
        showWhenHarmful = true,
        showWhenHelpful = false,
    })
    if not okAdd then
        -- 旧引擎别名（EUI 同款回退）：无 style 语义，靠顶点色分类兜底。
        okAdd = pcall(button.SetAuraBorder, button, tex)
    end
    if not okAdd then
        local okAPI, a1, a2 = pcall(function()
            return button.AddDispelTypeTexture, button.SetAuraBorder
        end)
        if okAPI and (a1 ~= nil or a2 ~= nil) then
            -- API 在但调用被拒（疑似受限拒绝）：2 秒后重试。
            WR_PaladinForever_CleanseDispelTexRetry[button] = now
        else
            -- 结构上没有注册接口：永久跳过，不浪费每次读取。
            WR_PaladinForever_CleanseDispelTex[button] = false
        end
        return
    end
    WR_PaladinForever_CleanseDispelTex[button] = tex
end
_G.WR_PaladinForever_CleanseProbeInitFrame = WR_PaladinForever_CleanseProbeInitFrame

local function WR_PaladinForever_CleanseProbeCandidateFilters()
    -- ★★★ 2026-11-18 四次修复：引擎 includeDispelTypes 候选表只收规范英文
    --   令牌（EUI 生产同款：Magic/Disease/Poison/Bleed/Curse，
    --   EllesmereUI_UnitFrames_AuraContainers CANDIDATE_CLASSES 87-91）。
    --   旧表把 magic/MAGIC/魔法 等变体键也灌给引擎——C 侧候选校验遇到
    --   非规范键可能整表拒绝 → filtered 组连脱战精确判型都哑火。
    --   变体键只留给插件侧字符串比较，不再进引擎候选表。
    return { includeDispelTypes = { Magic = true, Disease = true, Poison = true } }
end

local function WR_PaladinForever_CleanseProbeEnsure(unit)
    if type(unit) ~= "string" or unit == "" then return nil end
    local probes = WR_PaladinForever_CleanseProbe
    local rec = probes[unit]
    if rec ~= nil then
        -- ★ 2026-11-18：已创建的容器幂等补挂 blanket RAW 组（旧会话容器 / 注册失败重试）。
        if rec.rawGroup == nil and rec.frame ~= nil then
            pcall(function()
                rec.rawGroup = rec.frame:AddAuraGroup("WR_CLEANSE_PROBE_RAW", WR_PaladinForever_CLEANSE_PROBE_FILTER, {
                    maxFrameCount = 40,
                    initializeFrame = WR_PaladinForever_CleanseProbeInitFrame,
                })
            end)
        end
        -- ★ 2026-11-18 三次修复/四次修复：幂等补挂 YOU 组（旧会话容器 / 注册失败
        --   重试）；形态对齐 EUI 生产组——maxFrameCount=10、无自定义 initializeFrame。
        if rec.youGroup == nil and rec.frame ~= nil then
            pcall(function()
                rec.youGroup = rec.frame:AddAuraGroup("WR_CLEANSE_PROBE_YOU", WR_PaladinForever_CLEANSE_PROBE_YOU_FILTER, {
                    maxFrameCount = 10,
                })
            end)
        end
        -- ★★★ 2026-11-19 八次修复：幂等补挂「按驱散类型过滤」的存在性组
        --   （magic / disease / poison 各一组，引擎侧求值、插件只数帧）。
        if rec.typeGroups == nil then rec.typeGroups = {} end
        if rec.frame ~= nil then
            local specs = WR_PaladinForever_CLEANSE_TYPE_FILTERS
            for si = 1, #specs do
                local spec = specs[si]
                if rec.typeGroups[spec.key] == nil then
                    pcall(function()
                        rec.typeGroups[spec.key] = rec.frame:AddAuraGroup(
                            spec.group, spec.filter, { maxFrameCount = 10 })
                    end)
                end
            end
        end
        return rec
    end
    local retryAt = WR_PaladinForever_CleanseProbeRetryAt[unit]
    if retryAt ~= nil and GetTime() < retryAt then return nil end
    if type(CreateFrame) ~= "function" then return nil end
    local okCombat, inCombat = pcall(function()
        return type(InCombatLockdown) == "function" and InCombatLockdown() == true
    end)
    if okCombat and inCombat then return nil end

    -- 与 EllesmereUI 相同的加载前置：AuraContainer 模板属于 Blizzard_AuraContainer。
    if type(C_AddOns) == "table" and type(C_AddOns.IsAddOnLoaded) == "function"
        and type(C_AddOns.LoadAddOn) == "function" then
        local okLoaded, loaded = pcall(C_AddOns.IsAddOnLoaded, "Blizzard_AuraContainer")
        if okLoaded and loaded ~= true then
            pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer")
        end
    end
    local okF, frame = pcall(CreateFrame, "AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
    if not okF or frame == nil then
        WR_PaladinForever_CleanseProbeRetryAt[unit] = GetTime() + 5
        return nil
    end
    -- ★★★ 2026-11-18 四次修复：容器必须真的有 AddAuraGroup。旧版不校验——
    --   Blizzard_AuraContainer 未加载成功/模板缺失时 CreateFrame 造出的壳没有
    --   内建方法，后续 AddAuraGroup 全部 pcall 吞错 → 四组全空全哑火。
    local okAddApi, addApiFn = pcall(function() return frame.AddAuraGroup end)
    if not okAddApi or addApiFn == nil then
        WR_PaladinForever_CleanseProbeRetryAt[unit] = GetTime() + 5
        return nil
    end
    pcall(function()
        frame:SetSize(1, 1)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        -- ★ 2026-11-18 四次修复：不再 SetAlpha(0.001)。引擎 AuraContainer 的
        --   解析/排版 OnUpdate 是 run-when-visible 模式（AuraKit 1612-1615 实证），
        --   生产容器从不压 alpha；1×1 尺寸 + EnableMouse(false) 足够隐形。
        if type(frame.EnableMouse) == "function" then frame:EnableMouse(false) end
    end)
    local group = nil
    local okG = pcall(function()
        group = frame:AddAuraGroup("WR_CLEANSE_PROBE", WR_PaladinForever_CLEANSE_PROBE_FILTER, {
            maxFrameCount = 1,
            -- ★ 引擎侧类型过滤：只保留清洁术能驱散的 魔法 / 疾病 / 中毒。
            --   不用 RAID_PLAYER_DISPELLABLE：它按职业/专精模板判定，
            --   某些服务端版本会把防护/惩戒的清洁术能力漏掉；按 debuff 类型过滤最稳。
            candidateFilters = WR_PaladinForever_CleanseProbeCandidateFilters(),
            -- ★ 四次修复：filtered 组也是纯计数通道，摘除装饰初始化器
            --   （对齐生产组形态；类型读回只在 RAW 组保留）。
        })
    end)
    if not okG then
        pcall(function() frame:Hide() end)
        WR_PaladinForever_CleanseProbeRetryAt[unit] = GetTime() + 5
        return nil
    end
    -- ★★★ 2026-11-18：blanket RAW 组（无候选过滤）。
    --   受限内容（战斗/首领战/挑战/PVP）里 candidateFilters 读的
    --   auraData.dispelName 被 REDACTED —— includeDispelTypes 匹配不到任何东西
    --   （EllesmereUI Nameplates 源码同款实证：「the include-Magic candidate
    --   matches nothing」）→ filtered 组战斗中恒空。RAW 组不限类型，
    --   受限内容下引擎照样填充按钮；类型改由 CleanseProbeHasDispellable
    --   逐帧读引擎驱散边框（诅咒/流血照样排除，读不到不猜）。
    local rawGroup = nil
    local okRawGroup = pcall(function()
        rawGroup = frame:AddAuraGroup("WR_CLEANSE_PROBE_RAW", WR_PaladinForever_CLEANSE_PROBE_FILTER, {
            maxFrameCount = 40,
            initializeFrame = WR_PaladinForever_CleanseProbeInitFrame,
        })
    end)
    if not okRawGroup then rawGroup = nil end
    -- ★★★ 2026-11-18 三次修复①：引擎级「本人可驱散」令牌组（免读回通道）。
    --   EUI RaidFrames 生产同款 filter：引擎内部按职业/专精判「我本人可驱散」，
    --   组内有帧即答案；受限内容下由引擎求值，插件零读回。
    --   ★ 四次修复：对齐生产组形态——无自定义 initializeFrame（存在性通道
    --   零读回，不需要按钮装饰，EUI TypeIcons byme 组同款），maxFrameCount=10
    --   对齐引擎 10 按钮批次防指纹下限（AuraKit GROUP_BATCH 同款）。
    local youGroup = nil
    local okYouGroup = pcall(function()
        youGroup = frame:AddAuraGroup("WR_CLEANSE_PROBE_YOU", WR_PaladinForever_CLEANSE_PROBE_YOU_FILTER, {
            maxFrameCount = 10,
        })
    end)
    if not okYouGroup then youGroup = nil end
    -- ★★★ 2026-11-19 八次修复：按驱散类型过滤的存在性组（引擎侧求值、零读回）。
    local typeGroups = {}
    do
        local specs = WR_PaladinForever_CLEANSE_TYPE_FILTERS
        for si = 1, #specs do
            local spec = specs[si]
            pcall(function()
                typeGroups[spec.key] = frame:AddAuraGroup(spec.group, spec.filter, { maxFrameCount = 10 })
            end)
        end
    end
    -- ★★★ 2026-11-17 复查：对齐 EllesmereUI AuraKit 的装配顺序——先加组，
    -- 再 SetUnit + UpdateAllAuras（AK.CreateContainerShell / Stage 3 同款）。
    -- 旧顺序 SetUnit 在 AddAuraGroup 之前：AuraContainer 的 UNIT_AURA 数据管线
    -- 按「当前组列表」装配，之后新增的组可能拿不到该 unit 的光环数据源，
    -- 组永远为空 → 探测器恒 false → UnitHasDispel 一票否决 → 战斗内+脱战清洁术全部哑火。
    -- ★★★ 2026-11-18 四次修复：SetUnit 结果必须校验。旧版 pcall 吞错——
    --   SetUnit 静默失败（受限上下文/时序拒绝）时容器永远绑在引擎
    --   NO_UNIT("none") 上（EUI RaidFrames NO_UNIT 注释同款），所有组恒空，
    --   是真机三次修复全哑火的容器级根因候选。失败不缓存 rec，5 秒后重建。
    local okSetUnit = pcall(frame.SetUnit, frame, unit)
    if not okSetUnit then
        pcall(function() frame:Hide() end)
        WR_PaladinForever_CleanseProbeRetryAt[unit] = GetTime() + 5
        return nil
    end
    pcall(function()
        frame:Show()
        if type(frame.UpdateAllAuras) == "function" then frame:UpdateAllAuras() end
    end)
    rec = { frame = frame, unit = unit, group = group, rawGroup = rawGroup, youGroup = youGroup,
            typeGroups = typeGroups, setUnitOK = true }
    probes[unit] = rec
    WR_PaladinForever_CleanseProbeRetryAt[unit] = nil
    return rec
end

-- ★ 2026-11-18：从引擎维护的光环按钮读「驱散类型」。受限内容下
--   dispelName 是 secret，但按钮的驱散边框/类型纹理由引擎（非 taint 侧）
--   填充 —— 与暴雪 DebuffFrame 的 DebuffBorder 同一机制，读普通字符串
--   图集名即可安全区分类型。返回 poison/disease/magic/curse/bleed 或 nil。
-- ★ EUI 实证的标准驱散色（EllesmereUI_UnitFrames 2778-2782），
--   注册纹理无图集时的顶点色分类兜底（与 EUI 按钮取色同一原理）。
local WR_PaladinForever_CLEANSE_VERT_COLORS = {
    magic = { 0.349, 0.475, 1.0 },
    curse = { 0.636, 0.0, 0.64 },
    disease = { 0.671, 0.384, 0.098 },
    poison = { 0.0, 0.706, 0.286 },
    bleed = { 0.75, 0.15, 0.15 },
}
local function WR_PaladinForever_CleanseProbeKindFromVertex(tex)
    if tex == nil or type(tex.GetVertexColor) ~= "function" then return nil end
    local okC, r, g, b = pcall(tex.GetVertexColor, tex)
    if not okC or r == nil or g == nil or b == nil then return nil end
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return nil end
    if WR_PaladinForever_IsSecretValue(r) or WR_PaladinForever_IsSecretValue(g)
        or WR_PaladinForever_IsSecretValue(b) then return nil end
    local best, bestD = nil, 0.15
    for kind, c in pairs(WR_PaladinForever_CLEANSE_VERT_COLORS) do
        local d = math.abs(r - c[1]) + math.abs(g - c[2]) + math.abs(b - c[3])
        if d < bestD then best, bestD = kind, d end
    end
    return best
end

local function WR_PaladinForever_CleanseProbeFrameKind(frame)
    if frame == nil then return nil end
    local function kindFromTexture(tex)
        if tex == nil then return nil end
        local s = nil
        local okA, atlas = pcall(function() return tex:GetAtlas() end)
        if okA and type(atlas) == "string" and not WR_PaladinForever_IsSecretValue(atlas) then
            local okL, lowered = pcall(string.lower, atlas)
            if okL and type(lowered) == "string" then s = lowered end
        end
        if s == nil then
            local okT, path = pcall(function() return tex:GetTexture() end)
            if okT and type(path) == "string" and not WR_PaladinForever_IsSecretValue(path) then
                local okL2, lowered2 = pcall(string.lower, path)
                if okL2 and type(lowered2) == "string" then s = lowered2 end
            end
        end
        if s == nil then return nil end
        if string.find(s, "curse", 1, true) then return "curse" end
        if string.find(s, "bleed", 1, true) then return "bleed" end
        if string.find(s, "poison", 1, true) then return "poison" end
        if string.find(s, "disease", 1, true) then return "disease" end
        if string.find(s, "magic", 1, true) then return "magic" end
        return nil
    end
    -- ⓪ 2026-11-18 主通道：初始化窗口注册的引擎驱散类型图标纹理。
    --   EUI AuraKit 实证：引擎逐光环盖章 RaidFrame-Icon-Debuff<Type> 图集，
    --   受限内容内外同一机制；未注册的按钮上根本没有这个纹理可读——
    --   旧版 initializeFrame 为空正是战斗中类型全 unknown 的根因。
    local regTex = WR_PaladinForever_CleanseDispelTex[frame]
    if regTex ~= nil and regTex ~= false then
        -- 引擎明确隐藏（且可读）→ 该光环无驱散类型，明确排除。
        -- IsShown 是引擎驱动的 aspect，受限内容下可能是 secret：只信可读布尔。
        local okShown, shown = pcall(regTex.IsShown, regTex)
        if okShown and type(shown) == "boolean"
            and not WR_PaladinForever_IsSecretValue(shown) and shown == false then
            return "untyped"
        end
        local k0 = kindFromTexture(regTex)
        if k0 ~= nil then return k0 end
        local kv = WR_PaladinForever_CleanseProbeKindFromVertex(regTex)
        if kv ~= nil then return kv end
        -- 注册纹理读不到类型 → 继续走旧通道（DebuffBorder / GetDispelTypeTexture）。
    end
    -- ① DebuffBorder（引擎边框，暴雪 DebuffFrame 同款）
    local okB, border = pcall(function() return frame.DebuffBorder end)
    if okB and border ~= nil then
        local k = kindFromTexture(border)
        if k ~= nil then return k end
    end
    -- ② 引擎 dispel 类型纹理（AuraButton mixin：GetDispelTypeTexture）
    local okN, n = pcall(function() return frame:GetDispelTypeTextureCount() end)
    if okN and type(n) == "number" and not WR_PaladinForever_IsSecretValue(n) then
        for i = 1, n do
            local okT, tex = pcall(function() return frame:GetDispelTypeTexture(i) end)
            if okT and tex ~= nil then
                local k = kindFromTexture(tex)
                if k ~= nil then return k end
            end
        end
    end
    return nil
end

-- ★★★ 2026-11-18 三次修复②：已知 debuff ID 存在性直查（免读回、免容器）。
--   EUI AuraBuffReminders 同款通道（NON_SECRET_SPELL_IDS）：未上秘密旗的
--   spellID 在战斗中 GetPlayerAuraBySpellID 照样返回完整 auraData；
--   「非 nil 即存在」——受限内容读不到字段不改变「这个 debuff 在身上」。
--   秘密旗 ID（如 Devotion Aura 465 的 ContextuallySecret）返回 nil：
--   nil 一律当未知（返回 nil），绝不据此判无。仅 player 单位可查。
function WR_PaladinForever_PlayerAuraIDHasDispellable(unit)
    if unit ~= "player" then return nil end
    if type(C_UnitAuras) ~= "table" then return nil end
    -- 用 ~= nil 而不是 type=="function"：离线夹具/部分客户端把 C API 暴露成
    -- 可调用 userdata，type() 不一定是 "function"（ProbeDispellableByFilter 同款约定）。
    local byIdFn = C_UnitAuras.GetPlayerAuraBySpellID
    if byIdFn == nil then return nil end
    local function probeTable(t)
        if type(t) ~= "table" then return nil end
        for sid, kind in pairs(t) do
            if kind == "poison" or kind == "disease" or kind == "magic" then
                local ok, aura = pcall(byIdFn, sid)
                if ok and aura ~= nil then return true end
            end
        end
        return nil
    end
    -- ① 白名单（截图/实测已确认的 ID）
    if probeTable(WR_PaladinForever_CLEANSE_KNOWN_AURA_IDS) == true then return true end
    -- ② ★★★ 2026-11-19 七次修复：运行时「已发现 ID」表。
    --   白名单外的 ID（如毒性唾液 7125）此前永远轮不到这条免读回通道；
    --   现在只要该 ID 曾在任何时刻被判过型（脱战可读 / 静态数据 / tooltip），
    --   就会进表，之后战斗里的 ID 直查自动覆盖它。
    if probeTable(WR_PaladinForever_CLEANSE_DISCOVERED_IDS) == true then return true end
    return nil
end
_G.WR_PaladinForever_PlayerAuraIDHasDispellable = WR_PaladinForever_PlayerAuraIDHasDispellable

-- ============================================================
-- ★★★ 2026-11-19 六次修复：tooltip 数据通用分类（短词类型 + 「法术ID」行反查）
--   用户截图实锤（脆弱 12530 · 魔法 · 剩余 57 秒）：本客户端 aura tooltip 的
--   数据流可用，但旧实现有三处结构性缺口：
--     ① 只认 leftText/rightText **精确等于**「中毒/疾病/魔法」——服务端把类型
--        与名称并排或带空白/颜色码时永远匹配不到；
--     ② 顶层 data.id 在受限内容里可能是 secret（EUI AuraBuffReminders 的
--        NON_SECRET_SPELL_IDS 策略实证）→ 白名单直查这条路整条落空；
--     ③ 截图里明明白白有「法术ID: 12530」这一行，旧实现完全没利用。
--   这里统一成三条可证明证据（读不到一律 nil，绝不猜）：
--     · 短行（≤ 8 字）包含类型词 → 按类型判（长描述行不参与，防「魔法伤害」误判）；
--     · 「法术ID / Spell ID」行取数字 → 白名单 + 静态提示分类；
--     · 顶层 id 可读 → 白名单。
-- ============================================================
-- 顺序敏感：诅咒 / 流血先判（清洁术驱不了，必须能明确排除）。
WR_PaladinForever_TOOLTIP_KIND_WORDS = {
    { "诅咒", "curse" }, { "流血", "bleed" },
    { "中毒", "poison" }, { "疾病", "disease" }, { "魔法", "magic" },
}

-- 短文本 → 类型。只接受「短行」（≤ 8 字）：tooltip 的类型行就是「魔法」这种两字，
-- 而法术描述行（「造成 X 点魔法伤害」）长度远超，不会误判。
-- ★★★ 2026-11-19 七次修复：先剥离颜色码再判长度。
--   tooltip 行文本可能带 |cffXXXXXX ... |r 转义（类型行被染色是常态），
--   旧实现拿**带转义的原串**判「≤8 字」——「|cff1eff00中毒|r」有 15 个字符，
--   直接被长度门挡掉 → 类型行明明可读却判不出类型 → 整条通道落空。
--   长度门同步放宽到 12（颜色码剥掉后仍允许「中毒(自然)」这类短标注），
--   长描述行（「每6秒造成17点自然伤害。」）依旧远超，不会误判。
function WR_PaladinForever_KindFromShortText(v)
    if type(v) ~= "string" then return nil end
    if WR_PaladinForever_IsSecretValue(v) then return nil end
    local okL, s = pcall(string.lower, v)
    if not okL or type(s) ~= "string" or s == "" then return nil end
    -- 剥离颜色/贴图转义：|cAARRGGBB ... |r（AARRGGBB 为 8 位十六进制）
    local okS, stripped = pcall(string.gsub, s, "|c%x%x%x%x%x%x%x%x", "")
    if okS and type(stripped) == "string" then s = stripped end
    local okR, noReset = pcall(string.gsub, s, "|r", "")
    if okR and type(noReset) == "string" then s = noReset end
    local okT, noTex = pcall(string.gsub, s, "|t", "")
    if okT and type(noTex) == "string" then s = noTex end
    -- 去掉首尾空白（服务端会在类型行前后塞空格）
    local okTrim, trimmed = pcall(string.match, s, "^%s*(.-)%s*$")
    if okTrim and type(trimmed) == "string" then s = trimmed end
    if s == "" then return nil end
    if #s > 12 then return nil end
    local words = WR_PaladinForever_TOOLTIP_KIND_WORDS
    for i = 1, #words do
        local pair = words[i]
        if string.find(s, pair[1], 1, true) or string.find(s, pair[2], 1, true) then
            return pair[2]
        end
    end
    return nil
end

-- 从 tooltip 行里抽「法术ID: N」的数字（截图实证行形态）。
--   leftText / rightText 两段都可能承载标签，拼接后再抓数字。
function WR_PaladinForever_SpellIDFromTooltipLines(data)
    if type(data) ~= "table" and type(data) ~= "userdata" then return nil end
    local okL, lines = pcall(function() return data.lines end)
    if not okL or type(lines) ~= "table" then return nil end
    local okN, n = pcall(function() return #lines end)
    if not okN or type(n) ~= "number" or WR_PaladinForever_IsSecretValue(n) then return nil end
    for j = 1, n do
        local line = lines[j]
        if type(line) == "table" then
            local okA, left = pcall(function() return line.leftText end)
            local okB, right = pcall(function() return line.rightText end)
            local ls, rs = "", ""
            if okA and type(left) == "string" and not WR_PaladinForever_IsSecretValue(left) then ls = left end
            if okB and type(right) == "string" and not WR_PaladinForever_IsSecretValue(right) then rs = right end
            local joined = ls .. " " .. rs
            local okLow, low = pcall(string.lower, joined)
            if okLow and type(low) == "string" and low ~= ""
                and (string.find(low, "法术id", 1, true) or string.find(low, "spell id", 1, true)) then
                local okM, digits = pcall(string.match, joined, "(%d+)")
                if okM and type(digits) == "string" then
                    local okNum, num = pcall(tonumber, digits)
                    if okNum and type(num) == "number" and num > 0 then return num end
                end
            end
        end
    end
    return nil
end

-- tooltip 数据 → 类型（poison/disease/magic/curse/bleed）或 nil（未知）。
--   ★ 调用顺序：短词 → 「法术ID」行 → 顶层 id。
--   注意：这里会调用 DispKindBySpellID（静态提示），而 DispKindBySpellID 内部
--   的 KindFromSpellTooltip **只做短词判定、绝不回调本函数**，不会递归。
function WR_PaladinForever_KindFromTooltipData(data)
    if type(data) ~= "table" and type(data) ~= "userdata" then return nil end
    local okL, lines = pcall(function() return data.lines end)
    if okL and type(lines) == "table" then
        local okN, n = pcall(function() return #lines end)
        if okN and type(n) == "number" and not WR_PaladinForever_IsSecretValue(n) then
            for j = 1, n do
                local line = lines[j]
                if type(line) == "table" then
                    local okA, left = pcall(function() return line.leftText end)
                    if okA then
                        local k = WR_PaladinForever_KindFromShortText(left)
                        if k ~= nil then
                            -- ★★★ 2026-11-19 七次修复：短词行是最常见的命中路径，
                            --   必须在这里也把 spellID 记进发现表 —— 否则
                            --   「类型行可读但 ID 没入库」→ 下一场战斗 ID 直查仍然漏。
                            WR_PaladinForever_RememberCleansableID(
                                WR_PaladinForever_SpellIDFromTooltipLines(data), k)
                            return k
                        end
                    end
                    local okB, right = pcall(function() return line.rightText end)
                    if okB then
                        local k = WR_PaladinForever_KindFromShortText(right)
                        if k ~= nil then
                            WR_PaladinForever_RememberCleansableID(
                                WR_PaladinForever_SpellIDFromTooltipLines(data), k)
                            return k
                        end
                    end
                    -- ★★★ 2026-11-19 八次修复：名称白名单证据。
                    --   用户截图「烈焰震击 · 法术ID 23038 · 魔法」里名字行是可读的，
                    --   而类型行「魔法」可能因为颜色码 / 并排布局读不出来。
                    --   名字命中 CLEANSE_KNOWN_AURA_NAMES 即可判型（只认肯定证据）。
                    local kName = WR_PaladinForever_KindFromAuraName(left)
                    if kName == nil and okB then
                        local okR2, r2 = pcall(function() return line.rightText end)
                        if okR2 then kName = WR_PaladinForever_KindFromAuraName(r2) end
                    end
                    if kName ~= nil then
                        WR_PaladinForever_RememberCleansableID(
                            WR_PaladinForever_SpellIDFromTooltipLines(data), kName)
                        return kName
                    end
                    -- ★★★ 2026-11-19 八次修复：名称白名单证据。
                    --   用户截图「烈焰震击 · 法术ID 23038 · 魔法」里名字行是可读的，
                    --   而类型行「魔法」可能因为颜色码/并排布局读不出来。
                    --   名字命中 CLEANSE_KNOWN_AURA_NAMES 即可判型（只认肯定证据）。
                    local kName = WR_PaladinForever_KindFromAuraName(left)
                    if kName == nil and okB then
                        local okR2, r2 = pcall(function() return line.rightText end)
                        if okR2 then kName = WR_PaladinForever_KindFromAuraName(r2) end
                    end
                    if kName ~= nil then
                        WR_PaladinForever_RememberCleansableID(
                            WR_PaladinForever_SpellIDFromTooltipLines(data), kName)
                        return kName
                    end
                end
            end
        end
    end
    local sid = WR_PaladinForever_SpellIDFromTooltipLines(data)
    if sid ~= nil then
        local known = WR_PaladinForever_CLEANSE_KNOWN_AURA_IDS[sid]
        if known ~= nil then return known end
        local discovered = WR_PaladinForever_CLEANSE_DISCOVERED_IDS
        if type(discovered) == "table" then
            local d = discovered[sid]
            if d ~= nil then return d end
        end
        if type(WR_PaladinForever_DispelKindBySpellID) == "function" then
            local k = WR_PaladinForever_DispelKindBySpellID(sid)
            if k ~= nil then return k end
        end
        -- ★★★ 2026-11-19 七次修复：静态法术数据兜底。
        --   截图里的「法术ID: 7125」行可读时，即使这个 ID 从没进过白名单，
        --   也能靠客户端静态数据判出「中毒」→ 当场点亮，并记住这个 ID，
        --   下一场战斗的 ID 直查通道自动覆盖它。这是「不再靠截图补 ID」的闭环。
        local staticKind = WR_PaladinForever_StaticSpellDispelKind(sid)
        if staticKind ~= nil then
            WR_PaladinForever_RememberCleansableID(sid, staticKind)
            return staticKind
        end
    end
    local okId, topId = pcall(function() return data.id end)
    if okId and type(topId) == "number" and not WR_PaladinForever_IsSecretValue(topId) then
        local known = WR_PaladinForever_CLEANSE_KNOWN_AURA_IDS[topId]
        if known ~= nil then
            WR_PaladinForever_RememberCleansableID(topId, known)
            return known
        end
        local staticTop = WR_PaladinForever_StaticSpellDispelKind(topId)
        if staticTop ~= nil then
            WR_PaladinForever_RememberCleansableID(topId, staticTop)
            return staticTop
        end
    end
    return nil
end

-- ★★★ 2026-11-18 四次修复④：C_TooltipInfo 驱散提示扫描（免读回、免容器）。
--   实证：!Pig Tooltip.lua 321（TooltipDataProcessor.UnitAura 读 data.id）+
--   PartyMemberFrame.lua 366（GameTooltip:SetUnitDebuff(unit, j)）——本客户端
--   驱散提示数据流可用，用户截图「法术ID: 744 / 中毒 / 剩余23秒」正是该数据流
--   （引擎 C 侧组装，不受 DenyTaintedAccessWhenAurasAreSecret 限制）。
--   EUI 明令禁止从 Lua 创建扫描 GameTooltipTemplate 帧
--   （EllesmereUIBlizzardSkin 126: reference_tooltip_template_taint），
--   因此只走 C_TooltipInfo（GetUnitDebuffByIndex / GetUnitDebuff 兼容序）。
--   全部 pcall + secret 过滤，只认肯定证据：读不到一律 nil（未知），绝不判无。
--   0.5 秒节流；调用被拒记 2.5 秒冷却（受限拒绝不会在半秒内解除）。
WR_PaladinForever_CleanseTooltipScanAt = {}       -- per-unit 节流时间
WR_PaladinForever_CleanseTooltipScanCache = {}     -- per-unit 缓存
WR_PaladinForever_CleanseTooltipScanDenied = {}    -- per-unit 是否被拒
WR_PaladinForever_CleanseTooltipScanRetryAt = {}   -- per-unit 重试时间
WR_PaladinForever_CleanseTooltipScanHoldAt = {}    -- per-unit「已确认 true」保持起点
function WR_PaladinForever_CleanseTooltipScan(unit)
    if type(unit) ~= "string" or unit == "" then return nil end
    local now = GetTime()
    local atMap = WR_PaladinForever_CleanseTooltipScanAt
    local cacheMap = WR_PaladinForever_CleanseTooltipScanCache
    local deniedMap = WR_PaladinForever_CleanseTooltipScanDenied
    local retryMap = WR_PaladinForever_CleanseTooltipScanRetryAt
    -- ★★★ 2026-11-19 八次修复：节流 0.5 → 0.2 秒，并给「已确认 true」加保持期。
    --   真机上 tooltip 数据流可能间歇性被拒（受限内容下引擎逐帧放行/拒绝）；
    --   旧实现每次重扫都先 cacheMap[unit] = nil，一旦这一帧读不到，
    --   上一帧刚确认的 true 立刻丢失 → 清洁术色块灭掉 → AHK 不按 → 玩家看到
    --   「明明身上有魔法 debuff 却一直不驱」。现在 true 结果保持 1.5 秒
    --   （与色块保持窗口同量级），期间即使重扫被拒也继续判可驱散。
    local lastAt = atMap[unit] or 0
    if now - lastAt < 0.2 then
        return cacheMap[unit]
    end
    atMap[unit] = now
    local denied = deniedMap[unit]
    if denied and now < (retryMap[unit] or 0) then
        return cacheMap[unit]
    end
    deniedMap[unit] = false
    -- ★ 保持期：上一次明确读到可驱散 → 1.5 秒内继续按「有」处理
    local holdMap = WR_PaladinForever_CleanseTooltipScanHoldAt
    local holdAt = holdMap[unit] or 0
    local prevTrue = cacheMap[unit] == true
    if not (prevTrue and (now - holdAt) < 1.5) then
        cacheMap[unit] = nil
    end
    local C_TI = C_TooltipInfo
    if type(C_TI) ~= "table" then return cacheMap[unit] end
    -- ★★★ 2026-11-19 七次修复：
    --   ① 槽位上限 20 → 40。中毒/魔法类 debuff 在一场 boss 战里很容易超过 20 条，
    --      旧上限会把排在后面的毒整条截断（用户看到的「明明中了毒却不驱」）。
    --   ② 兼容序补 GetUnitAuraByIndex（部分客户端只暴露通用版本，
    --      与 FuryByTooltip 的兼容序一致）。
    -- ★★★ 2026-11-19 八次修复：候选函数改为「全部收集 + 逐个尝试」。
    --   旧写法 A or B or C 只取第一个**存在**的函数：只要该函数存在但签名 / 上下文
    --   不对（返回 nil 或直接抛错），整条 tooltip 通道就永久哑火，后面的候选
    --   （GetUnitAura / GetUnitAuraByIndex）根本没机会跑。用户截图「烈焰震击
    --   23038 · 魔法 · 剩余6秒」正是这条通道本该命中的形态。
    --   现在：把存在的候选全部列出来，逐条扫；某条抛错只跳过它自己，
    --   全部候选都被拒才记 denied。
    local scanFns = {}
    local function addFn(fn, extra)
        if fn == nil then return end
        scanFns[#scanFns + 1] = { fn = fn, extra = extra }
    end
    addFn(C_TI.GetUnitDebuffByIndex)
    addFn(C_TI.GetUnitDebuff)
    addFn(C_TI.GetUnitAuraByIndex)
    addFn(C_TI.GetUnitAura)
    addFn(C_TI.GetUnitAura, "HARMFUL")
    addFn(C_TI.GetUnitAuraByIndex, "HARMFUL")
    if #scanFns == 0 then return nil end
    local sawKnownNon, sawUnknown, sawDenied = false, false, false
    local anyCallOK = false
    for fi = 1, #scanFns do
      local cand = scanFns[fi]
      local scanFn = cand.fn
      local extra = cand.extra
      for i = 1, 40 do
        local ok, data
        if extra ~= nil then
            ok, data = pcall(scanFn, unit, i, extra)
        else
            ok, data = pcall(scanFn, unit, i)
        end
        if not ok then
            -- 该候选被拒 / 签名不符：只跳过它自己，继续试下一个候选。
            sawDenied = true
            break
        end
        anyCallOK = true
        if data == nil then break end
        -- ★★★ 2026-11-19 六次修复：统一走 KindFromTooltipData。
        --   旧版只认 leftText/rightText **精确等于**「中毒/疾病/魔法」，并且只查
        --   顶层 data.id 白名单；用户截图「脆弱 12530 · 魔法」里既不是精确等值行、
        --   顶层 id 在受限内容里又是 secret → 整条通道落空 → 清洁术不亮。
        --   新顺序（全部只认肯定证据）：短词类型行 → 「法术ID: N」行反查 → 顶层 id。
        --   诅咒 / 流血必须能明确排除，否则中诅咒时会误放清洁术。
        local kind = WR_PaladinForever_KindFromTooltipData(data)
        if kind == "poison" or kind == "disease" or kind == "magic" then
            cacheMap[unit] = true
            WR_PaladinForever_CleanseTooltipScanHoldAt[unit] = now
            return true
        end
        -- ★ 诅咒 / 流血只记账，**绝不能提前 return false**：
        --   同一单位身上可能「诅咒 + 魔法」并存，第一条是诅咒就停会把后面的
        --   脆弱/烈焰震击整条漏掉（正是「有诅咒在身时魔法 debuff 不驱」的老毛病）。
        if kind == "curse" or kind == "bleed" then
            sawKnownNon = true
        else
            sawUnknown = true
        end
      end
    end
    -- 所有候选都被拒（受限拒绝 / 签名全不符）：本轮未知，2.5 秒内不再打扰引擎。
    -- ★ 2026-11-19 九次修复：保持期内的 true 不能被这里清掉 —— 受限内容下
    --   tooltip 数据流经常「一帧能读、下一帧被拒」，旧写法在被拒分支直接
    --   cacheMap[unit] = nil，导致刚确认的可驱散结论立刻丢失、色块灭掉、
    --   AHK 不按，玩家看到的就是「明明有魔法 debuff 却一直不驱」。
    if not anyCallOK then
        deniedMap[unit] = true
        retryMap[unit] = now + 2.5
        if prevTrue and (now - holdAt) < 1.5 then
            cacheMap[unit] = true
            return true
        end
        cacheMap[unit] = nil
        return nil
    end
    -- 只有「每条都读得懂且全不可清洁」才允许判无；含未知一律返回 nil。
    if sawKnownNon and not sawUnknown and not sawDenied then
        cacheMap[unit] = false
        return false
    end
    return nil
end
_G.WR_PaladinForever_CleanseTooltipScan = WR_PaladinForever_CleanseTooltipScan

-- ============================================================
-- ★★★ 2026-11-18 五次修复：debuff spellID → 驱散类型 静态分类通道
--   受限内容（战斗/首领战/挑战/PVP）里 auraData.dispelName 是 secret，
--   引擎探测容器也可能因为装配时序/第三方 UI 而拿不到纹理，导致
--   「自己/目标/队友身上明明是中毒/疾病/魔法，清洁术却永不点亮」。
--   但 auraData.spellId 是普通数字（本文件 ID 直查通道已多次实锤），
--   而「某法术属于中毒/疾病/魔法/诅咒/流血」是静态数据 —— 用
--   C_TooltipInfo.GetSpellByID 读一次提示行即可判定，不吃单位光环权限、
--   不看战斗状态、对 player/target/party/mouseover 全部通用。
--   只认肯定证据：读不到 → nil（未知），绝不据此判「没有」。
-- ============================================================
WR_PaladinForever_DispelKindByIDCache = WR_PaladinForever_DispelKindByIDCache or {}
WR_PaladinForever_DispelKindByIDMissAt = WR_PaladinForever_DispelKindByIDMissAt or {}
WR_PaladinForever_DispelKindByIDCount = WR_PaladinForever_DispelKindByIDCount or 0

local function WR_PaladinForever_KindFromSpellTooltip(data)
    if type(data) ~= "table" then return nil end
    local okL, lines = pcall(function() return data.lines end)
    if not okL or type(lines) ~= "table" then return nil end
    local okN, n = pcall(function() return #lines end)
    if not okN or type(n) ~= "number" or WR_PaladinForever_IsSecretValue(n) then return nil end
    -- ★ 2026-11-19 六次修复：精确等值 → 短词包含。
    --   静态法术提示里的类型行形态不稳定（「魔法」/「魔法 debuff」/带颜色码），
    --   NormalizeDispelType 的精确比较会全部落空。KindFromShortText 只接受
    --   长度 ≤ 8 的类型行，长描述行不参与，不会把「造成魔法伤害」误判成 debuff 类型。
    for j = 1, n do
        local line = lines[j]
        if type(line) == "table" then
            local okA, left = pcall(function() return line.leftText end)
            if okA then
                local k = WR_PaladinForever_KindFromShortText(left)
                if k == nil then k = WR_PaladinForever_NormalizeDispelType(left) end
                if k ~= nil then return k end
            end
            local okB, right = pcall(function() return line.rightText end)
            if okB then
                local k = WR_PaladinForever_KindFromShortText(right)
                if k == nil then k = WR_PaladinForever_NormalizeDispelType(right) end
                if k ~= nil then return k end
            end
        end
    end
    return nil
end

-- ★★★ 2026-11-19 七次修复：静态法术驱散类型（纯服务端静态数据，不吃光环权限）。
--   用户截图「毒性唾液 7125 · 中毒」暴露的是结构性问题：本服的 debuff ID
--   极其分散（744 / 13298 / 5416 / 7125 彼此毫无关联），靠逐张截图往白名单里
--   补 ID 永远补不完 —— 每次新副本/新怪就再漏一次。
--   这里改用客户端自带的**静态法术数据**判型：C_Spell.GetSpellDispelType 与
--   C_Spell.GetSpellInfo().dispelType 都是按 spellID 查的静态字段，
--   与「单位光环是否 secret / 是否在战斗」完全无关。
--   两个 API 任一存在且能读 → 直接得到类型；都不存在 → nil（不猜，交后续通道）。
--   Enum.DispelType：0=None 1=Magic 2=Curse 3=Disease 4=Poison 5=Bleed。
WR_PaladinForever_DISPEL_ENUM_MAP = {
    [1] = "magic", [2] = "curse", [3] = "disease", [4] = "poison", [5] = "bleed",
}

function WR_PaladinForever_StaticSpellDispelKind(spellId)
    local sid = spellId
    if type(sid) ~= "number" then
        local okN, n = pcall(tonumber, sid)
        if not okN or type(n) ~= "number" then return nil end
        sid = n
    end
    if sid <= 0 then return nil end

    local function mapVal(v)
        if v == nil or WR_PaladinForever_IsSecretValue(v) then return nil end
        if type(v) == "number" then
            return WR_PaladinForever_DISPEL_ENUM_MAP[v]
        end
        return WR_PaladinForever_NormalizeDispelType(v)
    end

    -- ① C_Spell.GetSpellDispelType(spellID)（新客户端直给枚举）
    if type(C_Spell) == "table" then
        local fn = C_Spell.GetSpellDispelType
        if fn ~= nil then
            local ok, v = pcall(fn, sid)
            if ok then
                local k = mapVal(v)
                if k ~= nil then return k end
            end
        end
        -- ② C_Spell.GetSpellInfo(spellID).dispelType（结构体字段）
        local infoFn = C_Spell.GetSpellInfo
        if infoFn ~= nil then
            local ok2, info = pcall(infoFn, sid)
            if ok2 and (type(info) == "table" or type(info) == "userdata") then
                local okD, dt = pcall(function() return info.dispelType end)
                if okD then
                    local k = mapVal(dt)
                    if k ~= nil then return k end
                end
            end
        end
    end
    return nil
end
_G.WR_PaladinForever_StaticSpellDispelKind = WR_PaladinForever_StaticSpellDispelKind

-- ★★★ 2026-11-19 七次修复：运行时「已发现可驱散 ID」记忆表。
--   战斗中 auraData.spellId 是 secret，唯一能用的免读回通道是
--   C_UnitAuras.GetPlayerAuraBySpellID(sid) 逐 ID 直查 —— 但它只遍历白名单，
--   白名单外的 ID（如 7125）永远轮不到。
--   这里把「任何时刻被判定为 poison/disease/magic 的 spellID」记进本表
--   （脱战/可读时由 UnitAuraIDHasDispellable 与 ScanUnitDebuffTypes 自动喂），
--   下一场战斗 ID 直查通道就能覆盖它 —— 不需要再靠截图补录。
--   上限 200 条防无限增长（超出后不再新增，白名单仍优先）。
WR_PaladinForever_CLEANSE_DISCOVERED_IDS = WR_PaladinForever_CLEANSE_DISCOVERED_IDS or {}
WR_PaladinForever_CLEANSE_DISCOVERED_COUNT = WR_PaladinForever_CLEANSE_DISCOVERED_COUNT or 0
WR_PaladinForever_CLEANSE_DISCOVERED_MAX = 200

function WR_PaladinForever_RememberCleansableID(spellId, kind)
    if type(spellId) ~= "number" or spellId <= 0 then return end
    if kind ~= "poison" and kind ~= "disease" and kind ~= "magic" then return end
    local t = WR_PaladinForever_CLEANSE_DISCOVERED_IDS
    if t[spellId] ~= nil then return end
    if WR_PaladinForever_CLEANSE_DISCOVERED_COUNT >= WR_PaladinForever_CLEANSE_DISCOVERED_MAX then return end
    t[spellId] = kind
    WR_PaladinForever_CLEANSE_DISCOVERED_COUNT = WR_PaladinForever_CLEANSE_DISCOVERED_COUNT + 1
end

-- 返回 "poison"/"disease"/"magic"/"curse"/"bleed" 或 nil（未知/无驱散类型）
function WR_PaladinForever_DispelKindBySpellID(spellId)
    local sid = spellId
    if type(sid) ~= "number" then
        local okN, n = pcall(tonumber, sid)
        if not okN or type(n) ~= "number" then return nil end
        sid = n
    end
    local cache = WR_PaladinForever_DispelKindByIDCache
    local hit = cache[sid]
    if hit ~= nil then return hit end

    -- ① 本文件已按截图/实测确认的 debuff ID（不依赖任何 API）
    local known = WR_PaladinForever_CLEANSE_KNOWN_AURA_IDS[sid]
    if known ~= nil then
        cache[sid] = known
        return known
    end

    -- ①b ★★★ 2026-11-19 七次修复：客户端静态法术数据（GetSpellDispelType /
    --   GetSpellInfo().dispelType）。不吃光环权限、不看战斗状态，
    --   未录入白名单的 ID（例如新副本的中毒/魔法）也能自动判型。
    local staticKind = WR_PaladinForever_StaticSpellDispelKind(sid)
    if staticKind ~= nil then
        if WR_PaladinForever_DispelKindByIDCount < 600 then
            cache[sid] = staticKind
            WR_PaladinForever_DispelKindByIDCount = WR_PaladinForever_DispelKindByIDCount + 1
        end
        WR_PaladinForever_RememberCleansableID(sid, staticKind)
        return staticKind
    end

    -- ② 静态法术提示：失败/被拒不缓存，10 秒后重试（避免每 tick 砸引擎）
    local missAt = WR_PaladinForever_DispelKindByIDMissAt
    local now = GetTime()
    if (missAt[sid] or 0) + 10 > now then return nil end
    local TI = C_TooltipInfo
    if TI ~= nil then
        local fn = TI.GetSpellByID
        if fn ~= nil then
            local ok, data = pcall(fn, sid)
            if ok and data ~= nil then
                local kind = WR_PaladinForever_KindFromSpellTooltip(data)
                if kind ~= nil then
                    if WR_PaladinForever_DispelKindByIDCount < 600 then
                        cache[sid] = kind
                        WR_PaladinForever_DispelKindByIDCount = WR_PaladinForever_DispelKindByIDCount + 1
                    end
                    WR_PaladinForever_RememberCleansableID(sid, kind)
                    return kind
                end
            end
        end
    end
    missAt[sid] = now
    return nil
end

-- 逐条 aura 的 spellId 分类（任意单位通用；完全不读 dispelName/dispelType）
--   true  = 明确存在可驱散（毒/病/魔法）
--   false = 全部读得懂且都不需要清洁术（含只有诅咒/流血）
--   nil   = 未知（API 缺失、spellId 双来源都 secret、类型读不到）
--
-- ★★★ 2026-11-19 双来源 spellId：auraData.spellId 在战斗里可能是 secret（用户截图
--   减速术 11436 / 烈焰震击 23038 的实证），但 C_TooltipInfo.GetUnitDebuffByIndex
--   返回的 data.id 是 tooltip 引擎组装的数据，不受 DenyTaintedAccessWhenAurasAreSecret
--   限制（EllesmereUIAuraBuffReminders data.id 同源）。两个来源**同索引位**（C_UnitAuras
--   GetAuraDataByIndex 的 i 就是第 i 个 HARMFUL，C_TooltipInfo.GetUnitDebuffByIndex 的
--   i 也是第 i 个 debuff），所以 auraData.spellId secret 时并行扫 tooltip data.id。
function WR_PaladinForever_UnitAuraIDHasDispellable(unit)
    if type(unit) ~= "string" or unit == "" then return nil end
    if type(C_UnitAuras) ~= "table" then return nil end
    local byIdx = C_UnitAuras.GetAuraDataByIndex
    if byIdx == nil then return nil end
    -- tooltip 引擎第二来源（不强制存在，缺失时直接跳过）
    local C_TI_Tip = C_TooltipInfo
    local tipScan = nil
    if type(C_TI_Tip) == "table" then
        tipScan = C_TI_Tip.GetUnitDebuffByIndex or C_TI_Tip.GetUnitDebuff
    end
    local sawAny, sawUnknown = false, false
    for i = 1, 40 do
        local ok, data = pcall(byIdx, unit, i, "HARMFUL")
        if not ok then return nil end
        if data == nil then break end
        sawAny = true
        local kind = nil
        -- ① 首选：auraData.spellId（非 secret 时最快）
        local okS, sid = pcall(function() return data.spellId end)
        if okS and type(sid) == "number" and not WR_PaladinForever_IsSecretValue(sid) then
            kind = WR_PaladinForever_DispelKindBySpellID(sid)
        end
        -- ② 并行：tooltip data.id（auraData.spellId secret 时可能可读）
        if kind == nil and tipScan ~= nil then
            local okT, tdata = pcall(tipScan, unit, i)
            if okT and tdata ~= nil then
                -- ★★★ 2026-11-19 六次修复：不再只看顶层 data.id。
                --   受限内容里 data.id 可能是 secret，但 tooltip 行文本
                --   （类型行 / 「法术ID: N」行）由引擎 C 侧组装，仍可读；
                --   用户截图「脆弱 12530 · 魔法」正是这条数据流。
                kind = WR_PaladinForever_KindFromTooltipData(tdata)
            end
        end
        if kind == "poison" or kind == "disease" or kind == "magic" then return true end
        if kind ~= "curse" and kind ~= "bleed" then sawUnknown = true end
    end
    if sawAny and not sawUnknown then return false end
    return nil
end

local function WR_PaladinForever_CleanseProbeHasDispellable(unit)
    local rec = WR_PaladinForever_CleanseProbeEnsure(unit)
    if rec == nil then return nil end
    local frames
    local ok = pcall(function()
        local group = rec.group
        if group == nil then
            group = rec.frame:GetAuraGroup("WR_CLEANSE_PROBE")
        end
        if group == nil then return nil end
        frames = group:GetFramesByIndex()
    end)
    if not ok or type(frames) ~= "table" then return nil end
    -- frames 本身可能是引擎安全表；#frames 也可能被 secret 包装，全部 pcall + secret 过滤。
    local okCount, count = pcall(function() return #frames end)
    if not okCount or type(count) ~= "number" or WR_PaladinForever_IsSecretValue(count) then return nil end
    -- ★ 2026-11-17：快照给 /FH_QJS_DEBUG 诊断用（组是否真的在收 frame）。
    --   ★ 四次修复：附 setUnitOK（容器绑定是否成功）与 ttHit（提示扫描缓存）。
    _G.WR_PaladinForever_CleanseProbeDebug = _G.WR_PaladinForever_CleanseProbeDebug or {}
    _G.WR_PaladinForever_CleanseProbeDebug[unit] = { at = GetTime(), frames = count, setUnitOK = rec.setUnitOK, ttHit = WR_PaladinForever_CleanseTooltipScanCache }
    if count > 0 then return true end
    -- ★★★ 2026-11-19 八次修复：按驱散类型过滤的存在性组（引擎侧求值、零读回）。
    --   这是真机战斗里唯一不受 secret 影响的判据：
    --     · filter 令牌由引擎求值，插件只读组内帧数；
    --     · 不读 name / dispelName / spellId / 图集 / 顶点色，一个字段都不碰；
    --     · magic / disease / poison 三组任一有帧 → 明确存在清洁术可驱散的 debuff。
    --   用户截图「烈焰震击 23038 · 魔法」就是 magic 组该有帧的形态。
    local typeGroups = rec.typeGroups
    if type(typeGroups) == "table" then
        local specs = WR_PaladinForever_CLEANSE_TYPE_FILTERS
        local typeSeen = {}
        for si = 1, #specs do
            local spec = specs[si]
            local grp = typeGroups[spec.key]
            if grp == nil then
                local okG, g = pcall(function()
                    return rec.frame:GetAuraGroup(spec.group)
                end)
                if okG then grp = g end
                if grp ~= nil then typeGroups[spec.key] = grp end
            end
            if grp ~= nil then
                local frames2
                local ok2 = pcall(function() frames2 = grp:GetFramesByIndex() end)
                if ok2 and type(frames2) == "table" then
                    local okCnt, cnt = pcall(function() return #frames2 end)
                    if okCnt and type(cnt) == "number"
                        and not WR_PaladinForever_IsSecretValue(cnt) then
                        typeSeen[#typeSeen + 1] = spec.key .. "=" .. tostring(cnt)
                        if cnt > 0 then
                            _G.WR_PaladinForever_CleanseProbeDebug[unit].typeGroups =
                                table.concat(typeSeen, ",")
                            return true
                        end
                    end
                end
            end
        end
        if #typeSeen > 0 then
            _G.WR_PaladinForever_CleanseProbeDebug[unit].typeGroups = table.concat(typeSeen, ",")
        end
    end
    -- ★★★ 2026-11-18 三次修复①：YOU 组命中 = 引擎判定「有我本人可驱散 debuff」
    --   （免读回：组内有帧就是答案，类型字段一个都不读）。
    local youFrames
    local okYou = pcall(function()
        local yg = rec.youGroup
        if yg == nil then
            yg = rec.frame:GetAuraGroup("WR_CLEANSE_PROBE_YOU")
        end
        if yg == nil then return nil end
        youFrames = yg:GetFramesByIndex()
    end)
    if okYou and type(youFrames) == "table" then
        local okYouCount, youCount = pcall(function() return #youFrames end)
        if okYouCount and type(youCount) == "number" and not WR_PaladinForever_IsSecretValue(youCount) then
            _G.WR_PaladinForever_CleanseProbeDebug[unit].youFrames = youCount
            if youCount > 0 then return true end
        end
    end
    -- ★★★ 三次修复②：已知 ID 存在性兜底（主调用点在 UnitHasDispel 链，容器内再兜一次）。
    local okIdHit, idHit = pcall(WR_PaladinForever_PlayerAuraIDHasDispellable, unit)
    if okIdHit then
        _G.WR_PaladinForever_CleanseProbeDebug[unit].idHit = idHit
        if idHit == true then return true end
    end

    -- ★★★ 2026-11-18：filtered 组为空 ≠ 「没有可驱散 debuff」。
    --   受限内容（战斗/首领战/挑战/PVP）里 candidateFilters 读的
    --   auraData.dispelName 被 REDACTED —— includeDispelTypes 匹配不到任何东西
    --   （EllesmereUI Nameplates 源码同款实证）→ filtered 组战斗中恒空。
    --   改读 blanket RAW 组（无候选过滤，受限内容下引擎照样填充按钮），
    --   类型从引擎维护的按钮驱散边框逐帧读取：poison/disease/magic → true；
    --   curse/bleed → 明确排除（诅咒绝不错驱）；读不到 → unknown 交回后续
    --   通道，绝不猜可驱散。
    local rawFrames
    local okRaw = pcall(function()
        local rawGroup = rec.rawGroup
        if rawGroup == nil then
            rawGroup = rec.frame:GetAuraGroup("WR_CLEANSE_PROBE_RAW")
        end
        if rawGroup == nil then return nil end
        rawFrames = rawGroup:GetFramesByIndex()
    end)
    if okRaw and type(rawFrames) == "table" then
        local okRawCount, rawCount = pcall(function() return #rawFrames end)
        if okRawCount and type(rawCount) == "number" and not WR_PaladinForever_IsSecretValue(rawCount) then
            _G.WR_PaladinForever_CleanseProbeDebug[unit].rawFrames = rawCount
            if rawCount > 0 then
                local sawKnownNon = false
                local sawUnknown = false
                local kindsSeen = {}
                for i = 1, rawCount do
                    local okF, frame = pcall(function() return rawFrames[i] end)
                    if okF and frame ~= nil then
                        local k = WR_PaladinForever_CleanseProbeFrameKind(frame)
                        kindsSeen[#kindsSeen + 1] = k or "?"
                        if k == "poison" or k == "disease" or k == "magic" then
                            _G.WR_PaladinForever_CleanseProbeDebug[unit].rawKinds = table.concat(kindsSeen, ",")
                            return true
                        end
                        -- ★ untyped（引擎明确隐藏注册图标）与 curse/bleed 同列明确排除。
                        if k == "curse" or k == "bleed" or k == "untyped" then
                            sawKnownNon = true
                        else
                            sawUnknown = true
                        end
                    else
                        kindsSeen[#kindsSeen + 1] = "err"
                        sawUnknown = true
                    end
                end
                _G.WR_PaladinForever_CleanseProbeDebug[unit].rawKinds = table.concat(kindsSeen, ",")
                -- RAW 组有数据：全部明确 curse/bleed → 明确判无；含 unknown → 未知。
                if sawKnownNon and not sawUnknown then return false end
                return nil
            end
        end
    end

    -- ★ 2026-11-18 自愈：组存在但为空时，每 1 秒强制 UpdateAllAuras 一次。
    --   引擎按 UNIT_AURA 增量维护组；若容器创建时（登录/切图时序）漏过一次
    --   事件，组可能永久停在空状态 → 疾病/魔法/中毒永远探不到。定期强制
    --   重解析自愈，代价可控（1 秒一次，且只在空组时触发）。
    WR_PaladinForever_CleanseProbeRefreshAt = WR_PaladinForever_CleanseProbeRefreshAt or {}
    local nowS = GetTime()
    if (WR_PaladinForever_CleanseProbeRefreshAt[unit] or 0) + 1 < nowS then
        WR_PaladinForever_CleanseProbeRefreshAt[unit] = nowS
        if type(rec.frame.UpdateAllAuras) == "function" then
            pcall(function() rec.frame:UpdateAllAuras() end)
        end
    end
    -- 两组都拿不到有效数据 → 未知（nil），交回后续通道（DebuffFrame /
    -- 多API扫描 / 严格探针），受限内容下由 AurasRestricted 兜底判无。
    -- 旧版此处 return false 的依据（filtered 组空 = 引擎明确答无）只在
    -- 非受限内容成立；受限内容里 filtered 组恒空，会把战斗中的
    -- 疾病/魔法/中毒全部压成假无 —— 正是「战斗中清洁术自身不驱散」的根因。
    return nil
end

_G.WR_PaladinForever_CleanseProbeEnsure = WR_PaladinForever_CleanseProbeEnsure

if type(CreateFrame) == "function" then
    local wrCleanseProbeEvents = CreateFrame("Frame")
    wrCleanseProbeEvents:RegisterEvent("PLAYER_LOGIN")
    wrCleanseProbeEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    wrCleanseProbeEvents:SetScript("OnEvent", function()
        local units = { "player", "target", "focus", "mouseover", "party1", "party2", "party3", "party4" }
        for i = 1, #units do
            pcall(WR_PaladinForever_CleanseProbeEnsure, units[i])
        end
    end)
end

-- ============================================================
-- ★★★ 2026-11-19 十一次修复：受限战斗「纯存在性」通道
-- ------------------------------------------------------------
-- 真机诊断实证（/FH_QJS_DEBUG，战斗内 secret=true）：所有读字段的通道
--   （dispelName/spellId/name/tooltip/静态分类/容器/EUI 图集）全部 nil。
-- 但客户端仍知道「你身上有一条自己能驱散的 debuff」——这正是暴雪团队框架
-- 用来画驱散高亮的信息，走的是 UnitAura 的 **RAID 过滤令牌**：
--   RAID = 「我能施放的增益 + 我能驱散的减益」。
-- 因此 `UnitAura(unit, 1, "HARMFUL|RAID")`（或 `UnitDebuff(unit, 1, "RAID")`）
--   只要返回非 nil，就说明存在一条职业可驱散的减益（圣骑士 = 中毒/疾病/魔法）。
-- 本通道**只判存在性、不读任何字段**，也不做比较/算术，符合 secret 约束。
-- 返回：true=存在可驱散 / false=明确没有 / nil=API 不可用或调用被拒。
-- ★ 当前状态：**仅用于诊断**，不参与 UnitHasDispel 判定。
--   原因：本服 RAID 过滤是否真的排除诅咒/流血尚未在真机验证；
--   一旦滤镜被忽略，按存在性放行就会把诅咒也点亮（历史事故 H4/J28）。
--   验证方法：战斗中只中诅咒时执行 /FH_QJS_DEBUG，看
--     「UnitDebuff存在=1」而「驱散过滤器存在=0」→ 滤镜有效，接线可放行；
--     两者都=1 → 滤镜被忽略，本通道必须保持只读诊断。
-- ============================================================
function WR_PaladinForever_UnitDispelPresence(unit)
    if type(unit) ~= "string" or unit == "" then return nil end
    -- 注意两条 API 的过滤令牌写法不同：
    --   UnitAura 需要完整的 "HARMFUL|RAID"；
    --   UnitDebuff 是兼容包装，内部会自己加 "HARMFUL|"，这里只能给 "RAID"。
    --   照抄 "HARMFUL|RAID" 给 UnitDebuff 会变成非法过滤串 → 恒 nil。
    local probes = {
        { UnitAura, "HARMFUL|RAID" },
        { UnitDebuff, "RAID" },
    }
    local sawAPI = false
    for f = 1, #probes do
        local fn = probes[f][1]
        if fn ~= nil then
            sawAPI = true
            local ok1, a1 = pcall(fn, unit, 1, probes[f][2])
            if ok1 then
                local okN, isNil = pcall(function() return a1 == nil end)
                if okN then
                    if not isNil then return true end
                    return false
                end
            end
        end
    end
    if sawAPI then return nil end
    return nil
end

-- ★★★ 2026-11-19 十三次修复（用户口径：战斗中退化为「有减益就提示」）
-- ------------------------------------------------------------
-- 真机实证（02:01）：战斗内所有光环字段全 nil——UnitAura 不存在（noAPI）、
--   UnitDebuff=0、C_UnitAuras.GetAuraDataByIndex 全 nil、tooltip/静态/图集通道全 nil。
--   也就是说插件在战斗内根本无法区分中毒/疾病/魔法/诅咒。
-- 用户明确选择：此时只要「有任意减益」就点亮清洁术（宁可能驱就驱，接受诅咒空按）。
-- 本函数只判存在性、不读任何字段：
--   ① AuraUtil.ForEachAura("HARMFUL") —— 引擎侧遍历，回调被调用即视为有减益
--      （secret 字段原样传回，我们不读、只记「来过」）；
--   ② EUI 减益按钮里有处于显示状态的按钮（player/target 及所有 EUI 光环容器）；
--   ③ UnitDebuff(unit,1,"HARMFUL") 存在性（本服战斗中通常 =0，留作脱战兜底）。
-- 返回：true=有减益 / false=确认没有 / nil=完全读不到。
-- ★ 2026-11-19：每次结果都写进 WR_PaladinForever_AnyHarmfulLast，供 /FH_QJS_DEBUG
--   区分「循环路径读不到」与「诊断（斜杠命令）路径读不到」——两者 taint 上下文不同。
WR_PaladinForever_AnyHarmfulLast = WR_PaladinForever_AnyHarmfulLast or {}

-- ★★★ 2026-11-19 十五次修复：战斗内唯一可用的「存在性」信号 —— UNIT_AURA 事件。
--   02:41 实机实证：EUI 记录了 740 枚减益按钮，但 IsShown 全部被拒（EUI 源码注释：
--   "its shown state is secret even out of restriction"），C_UnitAuras 三条接口全 ERR，
--   GameTooltip 也读不出 —— 本服战斗内不把任何光环字段交给插件，连「按钮是否显示」都不行。
--   因此退化为：该单位 3 秒内发生过光环变化 → 视为「可能有减益」→ 允许点亮清洁术。
--   代价（用户已确认接受「有减益就提示」口径）：增益刷新也会触发一次，由 8 秒 CD 限流；
--   好处是战斗中真的能驱散，而不是完全哑火。
WR_PaladinForever_AuraEventAt = WR_PaladinForever_AuraEventAt or {}
WR_PaladinForever_AuraEventSeq = WR_PaladinForever_AuraEventSeq or {}
-- 「确认与清洁术相关」的减益变化时刻（区分增益 / 不可驱散减益）
WR_PaladinForever_AuraHarmfulAt = WR_PaladinForever_AuraHarmfulAt or {}
-- 诊断：每个单位最近一次 UNIT_AURA 负载的判定结果（按单位分开，避免被别的单位覆盖）
WR_PaladinForever_AuraPayloadLast = WR_PaladinForever_AuraPayloadLast or {}
-- 诊断：保留最近一次 UNIT_AURA 的 updateInfo 原始表（延迟探针用，不参与判定）
WR_PaladinForever_AuraUpdateInfoLast = WR_PaladinForever_AuraUpdateInfoLast or {}
-- 该单位的负载是否曾经可读（可读后就不再退回「任意变化」口径）
WR_PaladinForever_AuraPayloadKnown = WR_PaladinForever_AuraPayloadKnown or {}
-- 有效窗口：覆盖一次 1.5 秒色块保持 + 一次重试（ShowSkillCD 的 guard）
WR_PaladinForever_AURA_EVENT_WINDOW = 3.0

-- 读 UNIT_AURA 负载字段：secret / 异常 / 非基础类型 一律返回 nil（= 未知，绝不猜）
local function wrAuraField(data, key)
    local ok, v = pcall(function() return data[key] end)
    if not ok or v == nil then return nil end
    if type(WR_PaladinForever_IsSecretValue) == "function"
        and WR_PaladinForever_IsSecretValue(v) then
        return nil
    end
    local t = type(v)
    if t == "string" or t == "boolean" or t == "number" then return v end
    return nil
end

-- 判定一次 UNIT_AURA 的新增光环是否「值得点亮清洁术」。
-- 返回：true=有可驱散减益（魔法/中毒/疾病）/ false=明确无关（增益、诅咒、流血、不可驱散）
--       / nil=负载整体不可读（退回「任意变化」口径）
-- ★ 2026-11-19 十六次修复（用户截图：发霉的书籍陷阱 17134，不可驱散，却亮了清洁术）：
--   负载里能读到 isHelpful / dispelName 时就不再「见变化就亮」。
-- ★ 十七次修复：旧版「负载不可读 → 退回任意变化」在真机上是错的（玩家没中可驱散减益
--   也一直亮），已删掉该兜底；同时返回第二值 shape（诊断用，直接显示本服负载长什么样）。
function WR_PaladinForever_ClassifyUnitAuraPayload(updateInfo)
    local okType, isTbl = pcall(function()
        return type(updateInfo) == "table" or type(updateInfo) == "userdata"
    end)
    if not okType or not isTbl then return nil, "nil" end
    local okA, added = pcall(function() return updateInfo.addedAuras end)
    if not okA then return nil, "add=ERR" end
    if added == nil then
        -- 只有全量刷新、没有新增列表 → 不据此点亮（否则每次开战必然空按一次）
        if wrAuraField(updateInfo, "isFullUpdate") == true then return false, "full" end
        return nil, "add=nil"
    end
    if type(added) ~= "table" then return nil, "add=" .. type(added) end
    local okN, n = pcall(function() return #added end)
    if not okN or type(n) ~= "number" then return nil, "n=ERR" end
    if type(WR_PaladinForever_IsSecretValue) == "function"
        and WR_PaladinForever_IsSecretValue(n) then
        return nil, "n=secret"
    end
    local shapePrefix = "n=" .. tostring(n)
    local sampled = false
    if n == 0 then
        -- 全量刷新（含空的新增列表）：不据此点亮，避免每次开战/切换场景空按一次
        if wrAuraField(updateInfo, "isFullUpdate") == true then return false, shapePrefix .. "/full" end
        return nil, shapePrefix
    end
    local shape = shapePrefix
    for i = 1, n do
        local okI, aura = pcall(function() return added[i] end)
        if okI and (type(aura) == "table" or type(aura) == "userdata") then
            local helpful = wrAuraField(aura, "isHelpful")
            if helpful == nil then
                local harmful = wrAuraField(aura, "isHarmful")
                if harmful == true then helpful = false end
            end
            local dispel = wrAuraField(aura, "dispelName")
            if helpful ~= nil or dispel ~= nil then sampled = true end
            if i == 1 then
                shape = shape .. "/h=" .. (helpful == nil and "nil" or tostring(helpful))
                    .. "/d=" .. (dispel == nil and "nil" or tostring(dispel))
            end
            if helpful ~= true then
                if dispel ~= nil then
                    local kind = WR_PaladinForever_KindFromShortText(dispel)
                    if kind == "magic" or kind == "poison" or kind == "disease" then
                        return true, shape
                    end
                    -- 诅咒 / 流血 / 其它：清洁术驱不掉，明确无关
                elseif helpful == false then
                    -- 明确是减益但没有驱散类型（如「发霉的书籍陷阱」）→ 清洁术无效
                end
            end
        end
    end
    if sampled then return false, shape end
    return nil, shape
end

-- ★★★ 2026-11-19 十八次修复③：负载里「到底有没有新增光环」的免读探针。
--   真机实证：addedAuras 为 nil 的事件（全量刷新/仅更新）没有新增光环；
--   为 table 的事件则一定有，只是长度/字段是 secret 读不到。
--   这条信息不含任何光环内容，不会被 secret 拦截，是本服唯一可用的战斗内信号。
--   语义：true=确有新增（类型未知）；false=确认无新增或字段读不到（不可据此判无）。
function WR_PaladinForever_PayloadHasAddedAura(updateInfo)
    if updateInfo == nil then return false end
    local okA, added = pcall(function() return updateInfo.addedAuras end)
    if not okA then return false end
    if added == nil then return false end
    local t = type(added)
    return t == "table" or t == "userdata"
end

local wrAuraEventFrame = CreateFrame("Frame")
wrAuraEventFrame:RegisterEvent("UNIT_AURA")
wrAuraEventFrame:SetScript("OnEvent", function(_, _, unit, updateInfo)
    if type(unit) ~= "string" then return end
    local now = GetTime()
    WR_PaladinForever_AuraEventAt[unit] = now
    WR_PaladinForever_AuraEventSeq[unit] = (WR_PaladinForever_AuraEventSeq[unit] or 0) + 1
    local verdict, shape = WR_PaladinForever_ClassifyUnitAuraPayload(updateInfo)
    WR_PaladinForever_AuraPayloadLast[unit] = { v = verdict, shape = shape, at = now }
    WR_PaladinForever_AuraUpdateInfoLast[unit] = updateInfo
    if verdict ~= nil then
        WR_PaladinForever_AuraPayloadKnown[unit] = true
    end
    local hasAdded = WR_PaladinForever_PayloadHasAddedAura(updateInfo)
    if verdict == true then
        WR_PaladinForever_AuraHarmfulAt[unit] = now
    elseif verdict == nil and hasAdded then
        -- ★ 用户口径（2026-11-19 05:57 确认）：本服战斗内无法判定驱散类型，
        --   但「有新增光环」是真实信号 → 战斗内按它可以点亮清洁术（8 秒限流）。
        --   只排除两类明确无关的事件：全量刷新（addedAuras=nil）与已判定为
        --   增益/诅咒/无驱散类型的负载（verdict=false）。这是「能驱」与「少误亮」
        --   之间的最终取舍：宁可偶发空按，也不能漏掉魔法/中毒/疾病。
        WR_PaladinForever_AuraHarmfulAt[unit] = now
    end
    -- 注意：verdict=nil 且没有新增光环（全量刷新/更新事件）仍然不点亮 ——
    -- 真机 03:38 的误亮正是「任意事件都算」，这里只认「确实新增了光环」。
end)

-- ★★★ 2026-11-19 十八次修复②：按「驱散类型名」直查（经典 UnitDebuff 的字符串 index）。
--   经典 API 的 UnitDebuff(unit, index, filter) 里 index 允许传字符串：
--     · 驱散类型名（"Magic"/"Poison"/"Disease"/"Curse"）；
--     · 光环名（"投石"）。
--   本服 UnitDebuff 是兼容包装（数字 index 恒返回 0/nil），但字符串形态未必同款实现。
--   一旦支持，这就是「不读任何光环字段」的精确存在性通道：
--   想判魔法就看 UnitDebuff(unit,"Magic") 是否非 nil —— 完全绕开 secret 读数。
--   只认肯定证据：nil → 未知（返回 nil），绝不当「没有」。
function WR_PaladinForever_UnitDebuffByDispelKind(unit)
    if type(unit) ~= "string" or unit == "" then return nil end
    if UnitDebuff == nil then return nil end
    -- 中英双写：本服客户端可能是中文服，包装层可能按本地化名查
    local keys = { "Magic", "Poison", "Disease", "魔法", "中毒", "疾病" }
    local sawAny = false
    for i = 1, #keys do
        local ok, d = pcall(UnitDebuff, unit, keys[i])
        if ok then
            sawAny = true
            local okN, isNil = pcall(function() return d == nil end)
            -- 比较抛错 = 返回值是 secret ⇒ 非 nil ⇒ 该类型减益存在
            if not okN then return true end
            -- 只认「真的返回了亏 aura 对象」：兼容包装对未知 index 可能返回
            -- 0/false 之类的占位值，绝不能当成「有减益」，否则战斗中恒亮。
            if not isNil then
                local t = type(d)
                if t == "table" or t == "userdata" then return true end
            end
        end
    end
    if sawAny then return false end
    return nil
end
_G.WR_PaladinForever_UnitDebuffByDispelKind = WR_PaladinForever_UnitDebuffByDispelKind

function WR_PaladinForever_UnitAuraChangedRecently(unit, window)
    -- 只认「负载明确判定为与清洁术相关」的时刻；不再用「任意光环变化」兜底。
    local at = WR_PaladinForever_AuraHarmfulAt[unit]
    if type(at) ~= "number" then return false end
    return (GetTime() - at) <= (window or WR_PaladinForever_AURA_EVENT_WINDOW)
end

function WR_PaladinForever_UnitHasAnyHarmful(unit)
    if type(unit) ~= "string" or unit == "" then return nil end
    local function fin(v)
        WR_PaladinForever_AnyHarmfulLast[unit] = { v = v, at = GetTime() }
        return v
    end
    -- ⓪ 只有受限战斗才采信事件信号；脱战仍走类型精确判定（诅咒/流血不误放）
    if WR_PaladinForever_AurasRestricted() and WR_PaladinForever_UnitAuraChangedRecently(unit) then
        return fin(true)
    end
    local known = false
    -- ① 引擎侧遍历（unit 可以是 player/target/party1…）
    if type(AuraUtil) == "table" and type(AuraUtil.ForEachAura) == "function" then
        local found = false
        local ok = pcall(AuraUtil.ForEachAura, unit, "HARMFUL", nil, function()
            found = true
            return true
        end, true)
        if ok then
            if found then return fin(true) end
            known = true
        end
    end
    -- ② EUI 减益按钮（player/target 等所有挂在 EUI 光环容器上的减益组）
    if type(WR_PaladinForever_EUI_HarmfulPresence) == "function" then
        local okP, v = pcall(WR_PaladinForever_EUI_HarmfulPresence, unit)
        if okP then
            if v == true then return fin(true) end
            if v == false then known = true end
        end
    end
    -- ③ 经典 UnitDebuff 存在性
    if UnitDebuff ~= nil then
        local okD, d = pcall(UnitDebuff, unit, 1, "HARMFUL")
        if okD then
            local okN, isNil = pcall(function() return d == nil end)
            if okN then
                if not isNil then return fin(true) end
                known = true
            end
        end
    end
    if known then return fin(false) end
    return fin(nil)
end

function WR_PaladinForever_UnitHasDispel(unit)
    if type(unit) ~= "string" or unit == "" then return false end
    local okE, exists = pcall(UnitExists, unit)
    if not okE or not exists then return false end
    local okD, dead = pcall(UnitIsDeadOrGhost, unit)
    if okD and dead then return false end
    if not WR_PaladinForever_UnitIsFriendly(unit) then return false end

    -- ★★★ 2026-11-17：引擎级「玩家本人可驱散」探测器（见上方函数说明）。
    local engineProbe = WR_PaladinForever_CleanseProbeHasDispellable(unit)
    if engineProbe == true then return true end
    -- ★★★ 2026-11-18 三次修复②：已知 debuff ID 存在性直查（不依赖探测容器，
    --   容器装配失败/受限战斗下也能命中；非 nil 即存在，nil 当未知绝不判无）。
    --   PlayerAuraIDHasDispellable 内部只扫玩家自身光环 → 保持 player only。
    if unit == "player" then
        local okID, idHit = pcall(WR_PaladinForever_PlayerAuraIDHasDispellable, unit)
        if okID and idHit == true then return true end
    end
    -- ★★★ 2026-11-19 十八次修复②：经典 UnitDebuff 的「驱散类型名」直查。
    --   真机 05:37 实证：本服战斗内 C_UnitAuras 三条接口全 ERR（连独立执行帧的
    --   C_Timer 延迟探针都一样），EUI 按钮 IsShown 全拒，GameTooltip/提示扫描全 nil，
    --   GetPlayerAuraBySpellID(23380) 也返回 nil —— 任何「读光环」的通道都没了。
    --   唯一没试过的是 UnitDebuff 的字符串 index（经典 API 允许传 "Magic"/"Poison"…），
    --   它不返回光环数据，只回答「有没有这类减益」，正好绕开 secret 读数。
    local okDK, dkHit = pcall(WR_PaladinForever_UnitDebuffByDispelKind, unit)
    if okDK and dkHit == true then return true end
    -- ★★★ 2026-11-18 四次修复④：C_TooltipInfo 提示扫描（免读回、免容器、
    --   绕开 dispelName/spellId 双 secret）。2026-11-19 扩展到所有单位
    --   （原来只对 player，target/party/mouseover 的 debuff 也可能是魔法/毒/病）。
    --   调用被拒在受限战斗里是常态，内部有 2.5 秒冷却自动恢复。
    local okTT, ttHit = pcall(WR_PaladinForever_CleanseTooltipScan, unit)
    if okTT and ttHit == true then return true end
    -- ★★★ 2026-11-19 九次修复：GameTooltip 直读（用户截图就是鼠标悬停 tooltip）。
    --   C_TooltipInfo 数据表在受限内容里可能整条被拒 / 字段 secret；
    --   而 GameTooltip:SetUnitDebuff 之后读字体串 GetText() 是引擎写的普通文本，
    --   本仓库 PartyMemberFrame.lua 366 同款用法。玩家正在看 tooltip 时本函数
    --   自动让路（见函数内守卫），绝不打断玩家操作。
    local okGT, gtHit = pcall(WR_PaladinForever_ProbeByGameTooltip, unit)
    if okGT and gtHit == true then return true end
    -- ★★★ 2026-11-18 五次修复：全单位 spellID 静态分类（不依赖容器/类型字段）。
    --   只要 auraData.spellId 可读，就能靠静态提示判定中毒/疾病/魔法；
    --   target/party/mouseover 与 player 走同一条通道，战斗中同样有效。
    local okSID, sidHit = pcall(WR_PaladinForever_UnitAuraIDHasDispellable, unit)
    if okSID and sidHit == true then return true end
    -- ★★★ 2026-11-17 复查：探测器 false 不再一票否决。
    --   探测容器为空有两种含义：①引擎明确说「没有可驱散 debuff」；
    --   ②容器/组装配失败（SetUnit 顺序、UNIT_AURA 注册被挡等），组恒空。
    --   插件侧区分不了这两种情形，而②会让战斗内+脱战的清洁术全部哑火
    --   （用户实测复现：战斗中脱战都不驱散）。false 一律放行到后续通道；
    --   诅咒误报由各通道自己的类型判定（图集探针/严格探针）防住，不靠本层。


    -- ★★★ 2026-11-15：战斗内自己身上是否有可驱散 debuff 由
    --   WR_PaladinForever_PlayerDebuffDispelByBlizzardFrame 判定：
    --   auraInfo[i].debuffType 在战斗中是 secret，不能比较，只做存在性；
    --   具体类型读暴雪 AuraButton.DebuffBorder 的普通字符串图集名。
    --   脱战仍走下面更完整的缓存/接口路径。
    local uiHit = nil
    if unit == "player" then
        local okUI, ui = pcall(WR_PaladinForever_PlayerDebuffDispelByBlizzardFrame)
        if okUI then uiHit = ui end
    end

    -- ★ 2026-11-16：多 API 类型扫描优先于 DebuffFrame。DebuffFrame 的隐藏按钮
    -- 可能残留上一枚毒/魔法的边框；只要 UnitDebuff/UnitAura/C_UnitAuras 能读到
    -- 当前真实 dispelType（包括诅咒），就用它作为硬证据，避免旧图集把诅咒放行。
    local okDirect, directHit = pcall(WR_PaladinForever_ScanUnitDebuffTypes, unit)
    if not okDirect then directHit = nil end
    if directHit == true then return true end
    if directHit == false then return false end

    -- 多 API 都读不到时才回退 DebuffFrame 的 true/false。
    if unit == "player" then
        if uiHit == true then return true end
        if uiHit == false then return false end
    end

    -- ★★★ 2026-11-15：战斗/副本内光环数据是 secret，缓存扫描不可用；
    --   先走引擎侧 RAID 过滤器问「有没有我能驱散的 debuff」（不读任何光环字段）。
    local filterHit = WR_PaladinForever_ProbeDispellableByFilter(unit)
    if filterHit == true then return true end
    -- ★ 2026-11-16：严格探针返回 false 表示「明确没有可驱散类型」（含只有诅咒），
    --   直接判无；不再只在 AurasRestricted() 时相信，避免后续缓存/旧名字兜底翻案。
    if filterHit == false then return false end

    -- ★★★ 2026-11-19 十三次修复（用户口径：战斗中退化为「有减益就提示」）。
    --   受限战斗里类型字段一律读不到，此时只要能确认「该单位有减益」就放行；
    --   非受限上下文不启用（脱战仍按类型精确判定，诅咒/流血绝不误放）。
    if WR_PaladinForever_AurasRestricted() then
        local anyHarmful = WR_PaladinForever_UnitHasAnyHarmful(unit)
        if anyHarmful == true then return true end
    end

    -- ★ 2026-11-16：secret 状态下 WR_ScanAurasForUnit 失败会保留战斗前的旧缓存
    --   （例如之前的毒），绝不能拿它当当前是否可驱散的证据；到此仍未拿到
    --   DebuffFrame / 严格探针的明确 true，只能判无，避免「旧毒缓存 + 当前诅咒」误放清洁术。
    if WR_PaladinForever_AurasRestricted() then return false end

    if WR_UpdateFrameState ~= nil then pcall(WR_UpdateFrameState) end

    -- ① 主通道：刷新并读取 HARMFUL 光环缓存的 dispelType
    if WR_EnsureAuraCached ~= nil then
        pcall(WR_EnsureAuraCached, unit)
    elseif WR_ForceRefreshAuraCache ~= nil then
        pcall(WR_ForceRefreshAuraCache, unit)
    end
    if WR_PaladinForever_CacheHasDispel(unit) then return true end

    -- ② 公共类型查询（内部同样读缓存 dispelType；DISPEL_KINDS 不含诅咒）
    if WR_UnitDebuffType ~= nil then
        local kinds = WR_PaladinForever_DISPEL_KINDS
        for i = 1, #kinds do
            local ok, hit = pcall(WR_UnitDebuffType, unit, kinds[i])
            if ok and hit == true then return true end
        end
    end

    -- ③ 兜底：缓存缺失（核心层未加载 / 首次扫描失败）时直读 C_UnitAuras
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
            if not ok or not data then break end
            local okN, dt = pcall(function() return data.dispelName end)
            if not okN then dt = nil end
            if dt == nil or WR_PaladinForever_IsSecretValue(dt) then
                local okT, dt2 = pcall(function() return data.dispelType end)
                if okT and not WR_PaladinForever_IsSecretValue(dt2) then dt = dt2 else dt = nil end
            end
            if dt ~= nil and WR_PaladinForever_IsCleansableDispelType(dt) then return true end
        end
    end

    -- ④ 旧名字兜底：个别自定义 debuff 就叫「中毒」
    local legacy = WR_PaladinForever_DISPEL_LEGACY_NAMES
    for i = 1, #legacy do
        local ok, remain = pcall(WR_GetUnitDebuffTime, unit, legacy[i])
        if ok and type(remain) == "number" and remain > 0 then return true end
    end
    return false
end

-- ★★★ 2026-11-17：清洁术诊断（/FH_QJS_DEBUG）。
--   把每个探测通道在当前状态下的判定逐条打到聊天框，
--   用于定位「清洁术不亮」卡在哪一层（面板配置 / 探测器 / 缓存 / secret）。
-- 诊断用：列出当前 HARMFUL 光环的 spellID 与静态分类，便于确认到底哪条读不到
function WR_PaladinForever_DebugAuraKinds(unit)
    if type(unit) ~= "string" or unit == "" then return "n/a" end
    if type(C_UnitAuras) ~= "table" or C_UnitAuras.GetAuraDataByIndex == nil then return "noAPI" end
    local out = {}
    for i = 1, 12 do
        local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
        if not ok or data == nil then break end
        local okS, sid = pcall(function() return data.spellId end)
        if okS and type(sid) == "number" and not WR_PaladinForever_IsSecretValue(sid) then
            local kind = WR_PaladinForever_DispelKindBySpellID(sid)
            out[#out + 1] = tostring(sid) .. "=" .. tostring(kind or "?")
        else
            out[#out + 1] = "?=secret"
        end
    end
    if #out == 0 then return "无" end
    return table.concat(out, " ")
end

-- ★ 诊断格式化：区分「返回 nil（未知）」与「调用抛错（带错误原文）」
local function WR_PaladinForever_DbgFmt(ok, v)
    local okS, s = pcall(tostring, v)
    if not okS then s = "?" end
    if ok then return s end
    if type(s) == "string" and #s > 70 then s = string.sub(s, 1, 70) .. "…" end
    return "ERR[" .. tostring(s) .. "]"
end
_G.WR_PaladinForever_DbgFmt = WR_PaladinForever_DbgFmt

function WR_PaladinForever_CleanseDebugReport()
    local function report(unit)
        local parts = {}
        local okE, exists = pcall(UnitExists, unit)
        parts[#parts + 1] = "存在=" .. tostring(okE and exists or false)
        local restricted = false
        if type(WR_PaladinForever_AurasRestricted) == "function" then
            local okR, v = pcall(WR_PaladinForever_AurasRestricted)
            restricted = okR and v == true
        end
        parts[#parts + 1] = "secret=" .. tostring(restricted)
        local probeRec = type(WR_PaladinForever_CleanseProbe) == "table" and WR_PaladinForever_CleanseProbe[unit] or nil
        parts[#parts + 1] = "probe容器=" .. tostring(probeRec ~= nil)
        local dbg = _G.WR_PaladinForever_CleanseProbeDebug and _G.WR_PaladinForever_CleanseProbeDebug[unit] or nil
        if dbg ~= nil then
            parts[#parts + 1] = "probeFrames=" .. tostring(dbg.frames)
            parts[#parts + 1] = "probeRaw=" .. tostring(dbg.rawFrames)
            if dbg.rawKinds ~= nil then
                parts[#parts + 1] = "rawKinds=" .. tostring(dbg.rawKinds)
            end
            if dbg.youFrames ~= nil then
                parts[#parts + 1] = "youFrames=" .. tostring(dbg.youFrames)
            end
        end
        local okP, probeHit = pcall(WR_PaladinForever_CleanseProbeHasDispellable, unit)
        parts[#parts + 1] = "probe判定=" .. WR_PaladinForever_DbgFmt(okP, probeHit)
        if unit == "player" and type(WR_PaladinForever_PlayerDebuffDispelByBlizzardFrame) == "function" then
            local okUI, ui = pcall(WR_PaladinForever_PlayerDebuffDispelByBlizzardFrame)
            parts[#parts + 1] = "暴雪DebuffFrame=" .. WR_PaladinForever_DbgFmt(okUI, ui)
        end
        local okD, directHit = pcall(WR_PaladinForever_ScanUnitDebuffTypes, unit)
        parts[#parts + 1] = "多API扫描=" .. WR_PaladinForever_DbgFmt(okD, directHit)
        local okSID, sidHit = pcall(WR_PaladinForever_UnitAuraIDHasDispellable, unit)
        parts[#parts + 1] = "ID分类=" .. WR_PaladinForever_DbgFmt(okSID, sidHit)
        parts[#parts + 1] = "aura列表=" .. WR_PaladinForever_DebugAuraKinds(unit)
        if unit == "player" and type(WR_PaladinForever_PlayerAuraIDHasDispellable) == "function" then
            local okI, idHit = pcall(WR_PaladinForever_PlayerAuraIDHasDispellable, unit)
            parts[#parts + 1] = "ID直查=" .. WR_PaladinForever_DbgFmt(okI, idHit)
        end
        -- ★ 2026-11-19 十八次修复②：UnitDebuff 字符串 index（"Magic"/"Poison"/"Disease"）。
        --   ID直查=nil 无法区分「API 不存在」与「ID 是 secret」，这里一起打出来。
        do
            local byIdFn = nil
            if type(C_UnitAuras) == "table" then byIdFn = C_UnitAuras.GetPlayerAuraBySpellID end
            parts[#parts + 1] = "ID直查API=" .. tostring(byIdFn ~= nil)
            local okDK, dkHit = pcall(WR_PaladinForever_UnitDebuffByDispelKind, unit)
            parts[#parts + 1] = "类型直查=" .. WR_PaladinForever_DbgFmt(okDK, dkHit)
        end
        local okF, filterHit = pcall(WR_PaladinForever_ProbeDispellableByFilter, unit)
        parts[#parts + 1] = "严格探针=" .. WR_PaladinForever_DbgFmt(okF, filterHit)
        -- ★ 2026-11-19 九次修复：新增两条通道的诊断（真机排查靠这两行）
        local okTTH, ttHit2 = pcall(WR_PaladinForever_CleanseTooltipScan, unit)
        parts[#parts + 1] = "提示扫描=" .. WR_PaladinForever_DbgFmt(okTTH, ttHit2)
        local okGT, gtHit = pcall(WR_PaladinForever_ProbeByGameTooltip, unit)
        parts[#parts + 1] = "悬停提示=" .. WR_PaladinForever_DbgFmt(okGT, gtHit)
        -- ★★★ 2026-11-19 十一次修复：纯存在性探针（只判 ~= nil，不读任何字段）。
        --   用于回答「受限战斗里光环到底还能不能看到」：
        --     · 数字 = 能看到的 HARMFUL 光环条数；
        --     · SECRET[n] = 第 n 条非 nil 但无法判断是否 nil（secret）；
        --     · ERR[...] = 调用本身抛错（带原文）；
        --     · noAPI = 客户端没有该函数。
        local function presence(fn, filter)
            if fn == nil then return "noAPI" end
            local n = 0
            for i = 1, 40 do
                local okA, a = pcall(fn, unit, i, filter)
                if not okA then
                    local okS2, s2 = pcall(tostring, a)
                    return "ERR[" .. (okS2 and tostring(s2) or "?") .. "]"
                end
                local okN, isNil = pcall(function() return a == nil end)
                if not okN then return "SECRET[" .. tostring(i) .. "]" end
                if isNil then break end
                n = n + 1
            end
            return tostring(n)
        end
        parts[#parts + 1] = "UnitDebuff存在=" .. presence(UnitDebuff, "HARMFUL")
        parts[#parts + 1] = "UnitAura存在=" .. presence(UnitAura, "HARMFUL")
        -- 注意令牌写法：UnitAura 用 "HARMFUL|RAID"；UnitDebuff 兼容包装只给 "RAID"
        parts[#parts + 1] = "驱散过滤器存在=" .. presence(UnitDebuff, "RAID")
        parts[#parts + 1] = "驱散过滤Aura=" .. presence(UnitAura, "HARMFUL|RAID")
        local okPr, pr = pcall(WR_PaladinForever_UnitDispelPresence, unit)
        parts[#parts + 1] = "presence判定=" .. WR_PaladinForever_DbgFmt(okPr, pr)
        -- ★ 十三次修复：退化通道——战斗内只要有任意减益就放行
        -- ★ 十四次修复：先取「循环路径」上一次结果（诊断本身会覆盖缓存）
        local anyPrev = WR_PaladinForever_AnyHarmfulLast and WR_PaladinForever_AnyHarmfulLast[unit]
        local okAny, anyH = pcall(WR_PaladinForever_UnitHasAnyHarmful, unit)
        parts[#parts + 1] = "任意减益=" .. WR_PaladinForever_DbgFmt(okAny, anyH)
        parts[#parts + 1] = "ForEachAura=" .. tostring(type(AuraUtil) == "table" and type(AuraUtil.ForEachAura) == "function")
        parts[#parts + 1] = "EUI减益容器=" .. tostring(WR_PaladinForever_EUI_DebuffContainer ~= nil)
        -- ★ 2026-11-19 十四次修复：EUI 减益按钮记录情况 + 最近一次「存在性」扫描
        do
            local harmfulBtns, allBtns = 0, 0
            if type(WR_PaladinForever_EUI_Buttons) == "table" then
                for _, info in pairs(WR_PaladinForever_EUI_Buttons) do
                    allBtns = allBtns + 1
                    if type(info) == "table" and info.harmful then harmfulBtns = harmfulBtns + 1 end
                end
            end
            parts[#parts + 1] = "EUI按钮=减益" .. tostring(harmfulBtns) .. "/全" .. tostring(allBtns)
            local last = WR_PaladinForever_EUI_PresenceLast
            if type(last) == "table" then
                parts[#parts + 1] = "EUI可见=" .. tostring(last.shown)
                    .. "(" .. tostring(last.scanned) .. "/" .. tostring(last.tried) .. "枚)"
            else
                parts[#parts + 1] = "EUI可见=无记录"
            end
            -- ★ 十五次修复：UNIT_AURA 事件计数 —— 战斗内唯一剩下的存在性信号
            do
                local seq = WR_PaladinForever_AuraEventSeq and WR_PaladinForever_AuraEventSeq[unit] or 0
                local atA = WR_PaladinForever_AuraEventAt and WR_PaladinForever_AuraEventAt[unit]
                parts[#parts + 1] = "光环事件=" .. tostring(seq)
                    .. (type(atA) == "number"
                        and ("@" .. string.format("%.1f", GetTime() - atA) .. "s")
                        or "@无")
                -- ★ 十七次修复：负载判定已改为按单位存储 { v, shape, at }，且 shape
                --   直接暴露「本服负载长什么样」（add=nil / n=1/h=false/d=Poison 等），
                --   是下一步能否做精确过滤的唯一依据。
                local pl = WR_PaladinForever_AuraPayloadLast
                    and WR_PaladinForever_AuraPayloadLast[unit]
                if type(pl) == "table" then
                    parts[#parts + 1] = "光环负载=" .. tostring(pl.v)
                        .. "/" .. tostring(pl.shape)
                        .. "@" .. string.format("%.1f", GetTime() - (pl.at or GetTime())) .. "s"
                else
                    parts[#parts + 1] = "光环负载=无记录"
                end
                -- 十八次修复③：当前单位的最近一次事件是否「确有新增光环」
                -- （战斗内唯一可用的信号；全量刷新事件为 false）
                local uiLast = WR_PaladinForever_AuraUpdateInfoLast
                    and WR_PaladinForever_AuraUpdateInfoLast[unit]
                parts[#parts + 1] = "负载新增="
                    .. tostring(WR_PaladinForever_PayloadHasAddedAura(uiLast) == true)
            end
            local anyLast = anyPrev
            if type(anyLast) == "table" then
                parts[#parts + 1] = "任意减益(循环)=" .. tostring(anyLast.v)
                    .. "@" .. string.format("%.1f", GetTime() - anyLast.at) .. "s"
            else
                parts[#parts + 1] = "任意减益(循环)=无记录"
            end
        end
        -- ★ 2026-11-19 十二次修复：UnitAura 在本服不存在（noAPI），只剩 C_UnitAuras，
        --   这里把「引擎侧带 RAID 过滤能否看到光环」也测出来（只判存在性，不读字段）。
        local function auraDataPresence(filter)
            if type(C_UnitAuras) ~= "table" or C_UnitAuras.GetAuraDataByIndex == nil then
                return "noAPI"
            end
            local okA, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, 1, filter)
            if not okA then
                local okS2, s2 = pcall(tostring, a)
                return "ERR[" .. (okS2 and tostring(s2) or "?") .. "]"
            end
            local okN, isNil = pcall(function() return a == nil end)
            if not okN then return "SECRET" end
            if isNil then return "nil" end
            return "hit"
        end
        parts[#parts + 1] = "AuraData(HARMFUL)=" .. auraDataPresence("HARMFUL")
        parts[#parts + 1] = "AuraData(RAID)=" .. auraDataPresence("HARMFUL|RAID")
        if type(C_UnitAuras) == "table" and C_UnitAuras.GetAuraSlots ~= nil then
            local okSl, cont = pcall(C_UnitAuras.GetAuraSlots, unit, "HARMFUL|RAID")
            parts[#parts + 1] = "AuraSlots(RAID)=" .. WR_PaladinForever_DbgFmt(okSl, cont)
        else
            parts[#parts + 1] = "AuraSlots(RAID)=noAPI"
        end
        parts[#parts + 1] = "战斗中=" .. tostring((function()
            local okC, inC = pcall(UnitAffectingCombat, "player")
            return okC and inC or false
        end)())
        parts[#parts + 1] = "GameTooltip=" .. tostring(_G.GameTooltip ~= nil)
        -- ★ 2026-11-19 十次修复：保护窗口 + 可用性（区分「判定不出来」与「亮了被顶掉」）
        local wAlias = WR_PaladinForever_CleansePromptAlias
        local wUntil = WR_PaladinForever_CleansePromptUntil
        if wAlias and type(wUntil) == "number" then
            parts[#parts + 1] = "提示窗口=" .. tostring(wAlias)
                .. "/槽" .. tostring(WR_PaladinForever_CleansePromptSlot)
                .. "/单位" .. tostring(WR_PaladinForever_CleansePromptUnit)
                .. "/剩" .. string.format("%.1f", math.max(0, wUntil - GetTime())) .. "s"
        else
            parts[#parts + 1] = "提示窗口=无"
        end
        local okCC, cc = pcall(WR_PaladinForever_CanCleanseCast)
        parts[#parts + 1] = "可用=" .. tostring(okCC and cc or "err")
        local okCD, cdHit = pcall(WR_PaladinForever_OnCooldown, "清洁术", 8)
        parts[#parts + 1] = "本地CD中=" .. WR_PaladinForever_DbgFmt(okCD, cdHit)
        parts[#parts + 1] = "最终=" .. tostring(WR_PaladinForever_UnitHasDispel(unit))
        print("|cff00adf0[清洁术诊断]|r " .. unit .. ":  " .. table.concat(parts, "  "))
    end
    report("player")
    report("target")
    -- ★★★ 2026-11-19 十七次修复：延迟探针。
    --   本服报错原文是「Auras cannot be accessed when secret while tainted by
    --   'MKHelperForever'」—— 关键在 tainted：secret 只在「被本插件污染的执行路径」
    --   生效。C_Timer.After 的回调仍属于本插件，但它是独立执行帧，用来验证
    --   「换一个执行时机能否读到 slot 数」。若能读到 → 存在性判定可以做成精确定时轮询；
    --   若依旧被拒 → 战斗内光环对插件彻底封闭，只能靠 UNIT_AURA 负载（当前策略）。
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            local out = {}
            -- ★ 2026-11-19 十八次修复③：secret 值参与 .. 拼接会产出 secret 字符串，
            --   随后 table.concat 直接抛「invalid value (secret)」。真机已实证
            --   updateInfo.isFullUpdate 是 secret（探针第 5 项炸掉）。所有值先过 ss()。
            local function ss(v)
                if type(WR_PaladinForever_IsSecretValue) == "function"
                    and WR_PaladinForever_IsSecretValue(v) then
                    return "SECRET"
                end
                local okS, s = pcall(tostring, v)
                if not okS then return "ERR" end
                if type(WR_PaladinForever_IsSecretValue) == "function"
                    and WR_PaladinForever_IsSecretValue(s) then
                    return "SECRET"
                end
                return s
            end
            local function probe(name, fn)
                local ok, v = pcall(fn)
                if not ok then
                    local okS, s = pcall(tostring, v)
                    out[#out + 1] = name .. "=ERR[" .. (okS and ss(s) or "?") .. "]"
                    return
                end
                local okN, isNil = pcall(function() return v == nil end)
                if not okN then
                    out[#out + 1] = name .. "=SECRET"
                elseif type(v) == "table" then
                    local okL, len = pcall(function() return #v end)
                    out[#out + 1] = name .. "=table(" .. (okL and ss(len) or "?") .. ")"
                else
                    out[#out + 1] = name .. "=" .. ss(v)
                end
            end
            probe("slotsRAID", function()
                return C_UnitAuras and C_UnitAuras.GetAuraSlots
                    and C_UnitAuras.GetAuraSlots("player", "HARMFUL|RAID", 50)
            end)
            probe("dataHARMFUL", function()
                return C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
                    and C_UnitAuras.GetAuraDataByIndex("player", 1, "HARMFUL")
            end)
            do
                local n = 0
                local ok = pcall(function()
                    if AuraUtil and AuraUtil.ForEachAura then
                        AuraUtil.ForEachAura("player", "HARMFUL", nil, function()
                            n = n + 1
                            return true
                        end, true)
                    end
                end)
                out[#out + 1] = "forEach=" .. (ok and tostring(n) or "ERR")
            end
            -- ★ 十八次修复②：UNIT_AURA 负载本身还能读到什么（决定能否做精确过滤）
            do
                local ui = WR_PaladinForever_AuraUpdateInfoLast
                    and WR_PaladinForever_AuraUpdateInfoLast["player"]
                if ui == nil then
                    out[#out + 1] = "payload=无记录"
                else
                    local okA, added = pcall(function() return ui.addedAuras end)
                    if not okA then
                        out[#out + 1] = "payload.add=ERR"
                    elseif added == nil then
                        out[#out + 1] = "payload.add=nil"
                    else
                        -- ① 用 next 枚举（绕开 # 的 secret 长度保护）
                        local cnt, okNext = 0, false
                        local okP = pcall(function()
                            for _ in next, added do cnt = cnt + 1 end
                            okNext = true
                        end)
                        out[#out + 1] = "payload.next=" .. (okNext and ss(cnt) or "ERR")
                        -- ② 单条读取
                        local ok1, a1 = pcall(function() return added[1] end)
                        if not ok1 then
                            out[#out + 1] = "payload[1]=ERR"
                        elseif a1 == nil then
                            out[#out + 1] = "payload[1]=nil"
                        else
                            local okH, h = pcall(function() return a1.isHelpful end)
                            local okD2, d2 = pcall(function() return a1.dispelName end)
                            out[#out + 1] = "payload[1]=h:" .. (okH and ss(h) or "ERR")
                                .. "/d:" .. (okD2 and ss(d2) or "ERR")
                        end
                    end
                    -- ③ 全量刷新标记（真机实证：本服是 secret）
                    local okF, f = pcall(function() return ui.isFullUpdate end)
                    out[#out + 1] = "payload.full=" .. (okF and ss(f) or "ERR")
                end
            end
            -- ★ 十八次修复②：经典 UnitDebuff 字符串 index（类型名 / 光环名）
            do
                local function udb(k)
                    if UnitDebuff == nil then return "noAPI" end
                    local ok, d = pcall(UnitDebuff, "player", k)
                    if not ok then return "ERR" end
                    local okN, isNil = pcall(function() return d == nil end)
                    if not okN then return "SECRET" end
                    if isNil then return "nil" end
                    return "hit"
                end
                out[#out + 1] = "UD(Magic)=" .. udb("Magic")
                out[#out + 1] = "UD(Poison)=" .. udb("Poison")
                out[#out + 1] = "UD(Disease)=" .. udb("Disease")
                out[#out + 1] = "UD(魔法)=" .. udb("魔法")
            end
            -- 兜底：即使还有漏网的 secret，也不能让整次探测无声丢掉
            local okC, line = pcall(table.concat, out, "  ")
            if okC and type(line) == "string" then
                pcall(print, "|cffff8800[清洁术延迟探针]|r " .. line)
            else
                for i = 1, #out do pcall(print, "|cffff8800[清洁术延迟探针]|r " .. ss(out[i])) end
            end
        end)
    end
    local mode = tonumber(PigSet and PigSet.FH_QJS) or 5
    print("|cff00adf0[清洁术诊断]|r 面板: 下拉FH_QJS=" .. mode
        .. "  自己=" .. tostring(PigSet and PigSet.FH_QJS_Player)
        .. "  目标=" .. tostring(PigSet and PigSet.FH_QJS_Target))
    print("|cff00adf0[清洁术诊断]|r 下拉档位: 1=常规 2=优先 3=目标 4=指向 5=不使用；「自己/目标」复选框独立生效（当前档位5时只走复选框）")
end
-- ★★★ 2026-11-19 修复（命令一直无效）：SlashCmdList 的键必须与 SLASH_<KEY><N>
--   完全一致。旧写法 SLASH_FHQJSDBG1 定义的键是 "FHQJSDBG"，
--   而处理函数注册在 "FH_QJS_DEBUG" 下 —— 两边键名不相等，客户端认为
--   该斜杠命令从未注册，输入 /FH_QJS_DEBUG 只会得到「输入 '/help' 以获得
--   命令列表」，11-17 加进来后一直没生效。现统一为 FH_QJS_DEBUG。
SLASH_FH_QJS_DEBUG1 = "/FH_QJS_DEBUG"
SlashCmdList["FH_QJS_DEBUG"] = function()
    pcall(WR_PaladinForever_CleanseDebugReport)
end

function WR_PaladinForever_HasDispel(unit)
    return WR_PaladinForever_UnitHasDispel(unit or "player")
end

-- 本地 8 秒清洁术冷却（战斗中客户端冷却不可读，用施放成功事件记账兜底）
function WR_PaladinForever_OnCooldown(realName, cd)
    if type(realName) ~= "string" or type(cd) ~= "number" or cd <= 0 then return false end
    if type(WR_PaladinForever_GetLastCastAt) ~= "function" then return false end
    local at = WR_PaladinForever_GetLastCastAt(realName)
    if type(at) ~= "number" then return false end
    return (GetTime() - at) < cd
end

-- 清洁术可用性（兼容「需要友方目标」的客户端：IsUsableSpell 在敌方/无目标时
-- 可能返回 false，但技能本身已学会且不在本地冷却 —— 仍允许点亮，蓝量交给色块总闸）。
function WR_PaladinForever_CanCleanseCast()
    -- ★★★ 2026-11-19 九次修复：去掉 GlobalCooldown=true 的严格 GCD 门。
    --   WR_SpellUsable(spell, true) 的第三道门是 (GCD or 0.4) <= (ShiFaSuDu or 0.4)，
    --   而防骑每 tick 把 ShiFaSuDu 设为 0.3、GCD 设为 WR_GetGCD("审判")（= 审判自身
    --   剩余冷却 0~10 秒）→ 该判定 ≈「审判剩余 CD ≤ 0.3 秒」，审判一好就打 →
    --   约 90% 时间恒 false。GX.lua 已记录同源事故（打断滑条 / 全局保护 /
    --   圣疗 / 圣佑四处），本处是第五处残留：清洁术的可用性主通道长期空转，
    --   只能靠后面几条兜底，任何一条兜底在战斗中失效就直接不驱散。
    --   公共冷却由 ShowSkillCD 的提示防抖 + 本地 8 秒施放记账兜住。
    if WR_SpellUsable("清洁术") then return true end
    -- 蓝量不足时不放行（资源可读时）；资源不可读交给色块总闸与客户端回执兜底
    if WR_Forever_NotEnoughPower ~= nil then
        local okN, low = pcall(WR_Forever_NotEnoughPower, "清洁术")
        if okN and low == true then return false end
    end
    local id = 4987
    if WR_ResolveSpellID ~= nil then
        local okR, v = pcall(WR_ResolveSpellID, "清洁术")
        if okR and type(v) == "number" and v > 0 then id = v end
    end
    if IsPlayerSpell ~= nil then
        local okP, known = pcall(IsPlayerSpell, id)
        if okP and known == true then return true end
    end
    -- ★ 2026-11-15：12.x 的 IsPlayerSpell 可能不存在（DeprecatedSpellBook 才提供），
    --   统一走兼容层「技能是否已知」；否则战斗中 IsUsableSpell 对友方目标技能
    --   返回 false 时 CanCleanseCast 会恒 false → 清洁术永远不亮。
    if WR_Forever_IsSpellKnown ~= nil then
        local okK, known2 = pcall(WR_Forever_IsSpellKnown, "清洁术")
        if okK and known2 == true then return true end
    end
    -- ★ 2026-11-15：最后兜底 —— 法术书索引里存在「清洁术」即视为已学会。
    --   法术书索引只收录角色已学会的技能，不依赖 12.x 可能缺失的 IsPlayerSpell。
    if WR_BuildSpellBookIndex ~= nil then
        local okB, idx = pcall(WR_BuildSpellBookIndex)
        if okB and type(idx) == "table" and idx["清洁术"] ~= nil then return true end
    end
    return false
end

-- ============================================================
-- ★★★ 2026-11-19 十次修复：清洁术提示保护窗口（战斗中「亮了但被顶掉」）
-- ------------------------------------------------------------
-- 用户口径：脱战能正常驱散中毒/疾病/魔法，战斗里一次都不驱。
-- 根因（与 11-14「圣印经常被顶」同一类，第三处遗漏）：
--   WR_ColorFrame_ShowSkill 每次点亮前会先隐藏【所有】色块；而 ShowSkillCD
--   点亮一次后 cd=8 走 guard=PROMPT_HOLD(1.5s)，这 1.5 秒内后续调用直接
--   return false（不再重亮）。战斗里几乎每 tick 都有 审判/神圣打击/奉献/
--   圣印/打断 的色块点亮，把 43/44/59 在不到 0.1 秒内顶掉 → AHK（约 60ms
--   一扫）读不到 → 永不按键。脱战没有提示竞争，色块一直亮 → 正常驱散。
-- 修法（与圣印/正义之怒同一套保护窗口）：点亮后记 1.2 秒窗口，窗口内
--   每 tick 重亮同一色块并让调用方 return true；施放成功（本地 8 秒记账
--   生效）/ 单位已无可驱散 / 可用性失效 / 窗口到期 立即熄灭收窗口。
-- ============================================================
WR_PaladinForever_CLEANSE_PROMPT_HOLD = 1.2
WR_PaladinForever_CleansePromptAlias = nil
WR_PaladinForever_CleansePromptSlot = nil
WR_PaladinForever_CleansePromptUnit = nil
WR_PaladinForever_CleansePromptUntil = nil
WR_PaladinForever_CleansePromptRecheckAt = nil

-- 点亮成功后开启窗口（CleanseStep.tryUnit 调用）
function WR_PaladinForever_ArmCleansePrompt(alias, slot, unit)
    WR_PaladinForever_CleansePromptAlias = alias
    WR_PaladinForever_CleansePromptSlot = slot
    WR_PaladinForever_CleansePromptUnit = unit or "player"
    WR_PaladinForever_CleansePromptUntil = GetTime() + (WR_PaladinForever_CLEANSE_PROMPT_HOLD or 1.2)
    WR_PaladinForever_CleansePromptRecheckAt = GetTime() + 0.3
end

function WR_PaladinForever_ClearCleansePrompt()
    WR_PaladinForever_CleansePromptAlias = nil
    WR_PaladinForever_CleansePromptSlot = nil
    WR_PaladinForever_CleansePromptUnit = nil
    WR_PaladinForever_CleansePromptUntil = nil
    WR_PaladinForever_CleansePromptRecheckAt = nil
end

-- 每 tick 由防骑循环最前调用：窗口内重亮并返回 true（本 tick 不再点亮其它技能）
function WR_PaladinForever_RefreshCleansePrompt()
    local alias = WR_PaladinForever_CleansePromptAlias
    local untilAt = WR_PaladinForever_CleansePromptUntil
    if not alias or type(untilAt) ~= "number" then return false end
    local slot = WR_PaladinForever_CleansePromptSlot
    local unit = WR_PaladinForever_CleansePromptUnit or "player"
    local function stop()
        WR_PaladinForever_HideNow(alias, slot)
        WR_PaladinForever_ClearCleansePrompt()
        return false
    end
    if GetTime() >= untilAt then return stop() end
    -- 已经施放成功（本地 8 秒记账生效）→ 立刻收窗口，绝不再亮
    if WR_PaladinForever_OnCooldown("清洁术", 8) then return stop() end
    if not WR_PaladinForever_CanCleanseCast() then return stop() end
    -- 每 0.3 秒复查一次「该单位此刻仍有可驱散 debuff」，掉了解散窗口
    local now = GetTime()
    if not WR_PaladinForever_CleansePromptRecheckAt
       or now >= WR_PaladinForever_CleansePromptRecheckAt then
        WR_PaladinForever_CleansePromptRecheckAt = now + 0.3
        local ok, hit = pcall(WR_PaladinForever_UnitHasDispel, unit)
        if not ok or hit ~= true then return stop() end
    end
    if not WR_ColorFrame_ShowSkill(alias, slot) then return stop() end
    return true
end

-- 清洁术统一步骤（面板 5 模式 + 防护独立自己/目标复选框）
--   phase = "priority"：只跑「优先」模式 + 防护独立复选框
--   phase = "normal"  ：只跑「常规 / 目标 / 指向」模式
--   phase = nil       ：所有模式（预留单入口专精）
function WR_PaladinForever_CleanseStep(modeVar, phase, selfVar, targetVar)
    local mode = tonumber(PigSet and PigSet[modeVar]) or 5
    if mode < 1 or mode > 5 then mode = 5 end

    local function canCast()
        return WR_PaladinForever_CanCleanseCast() and not WR_PaladinForever_OnCooldown("清洁术", 8)
    end
    local function tryUnit(unit, alias, slot)
        if not WR_PaladinForever_UnitHasDispel(unit) then return false end
        if WR_PaladinForever_ShowSkillCD(alias, slot, 8) ~= true then return false end
        -- ★★★ 2026-11-19：点亮后开启保护窗口，由循环最前每 tick 重亮，
        --   避免战斗中立刻被 审判/神圣打击/圣印 的色块顶掉（见窗口函数注释）。
        WR_PaladinForever_ArmCleansePrompt(alias, slot, unit)
        return true
    end

    if phase == "priority" then
        if selfVar and PigSet and PigSet[selfVar] ~= false and canCast() then
            if tryUnit("player", "清洁术(自己)", 43) then return true end
        end
        if targetVar and PigSet and PigSet[targetVar] ~= false and canCast() then
            if tryUnit("target", "清洁术(目标)", 44) then return true end
        end
    end

    local runDropdown
    if phase == "priority" then
        runDropdown = (mode == 2)
    elseif phase == "normal" then
        runDropdown = (mode == 1 or mode == 3 or mode == 4)
    else
        runDropdown = (mode >= 1 and mode <= 4)
    end
    if not runDropdown or not canCast() then return false end

    if mode == 3 then
        return tryUnit("target", "清洁术(目标)", 44)
    elseif mode == 4 then
        return tryUnit("mouseover", "清洁术(指向)", 59)
    end
    if tryUnit("target", "清洁术(目标)", 44) then return true end
    if tryUnit("mouseover", "清洁术(指向)", 59) then return true end
    return tryUnit("player", "清洁术(自己)", 43)
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
    -- 祝福（2026-11-11）：下拉框已删除，改显示独立祝福设置列表的状态
    local bc = PigSet and PigSet.PAL_BLESS
    local bmode = "?"
    if type(WR_PaladinBlessing_GroupState) == "function" then
        bmode = WR_PaladinBlessing_GroupState()
    end
    print("|cff00ff00[MKPAL]|r 祝福：总闸=" .. tostring(bc and bc.enable)
        .. " 单人/小队/团队=" .. tostring(bc and bc.solo) .. "/" .. tostring(bc and bc.party) .. "/" .. tostring(bc and bc.raid)
        .. " 单人选择=" .. tostring(bc and bc.soloPick)
        .. " 当前状态=" .. tostring(bmode)
        .. " 力量/智慧/王者="
        .. tostring(WR_PaladinBlessing_BuffRemain and WR_PaladinBlessing_BuffRemain("player", 1)) .. "/"
        .. tostring(WR_PaladinBlessing_BuffRemain and WR_PaladinBlessing_BuffRemain("player", 2)) .. "/"
        .. tostring(WR_PaladinBlessing_BuffRemain and WR_PaladinBlessing_BuffRemain("player", 3)))
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
    -- ★★ 2026-11-19：打断滑块诊断（排查「设置了滑块但目标读条时不亮制裁之锤」）
    --   统一引擎 WR_GetCastProgress 现在优先走 DurationObject（Forever 12.x 唯一安全通道），
    --   再退原始时间戳；全部 secret safe。此处把每条闸门的实际值打出来，区分是
    --   「阈值关了」「没学会制裁之锤」「不在施法」「进度没到」「技能不可用」还是「距离不够」。
    local ddThr = WR_PaladinForever_InterruptThreshold and WR_PaladinForever_InterruptThreshold() or -1
    local ddSpell = WR_PaladinForever_SpellKnown and WR_PaladinForever_SpellKnown("制裁之锤")
    local ddCast = (function()
        if type(WR_GetCastProgress) ~= "function" then return nil end
        local ok, p = pcall(WR_GetCastProgress, "target")
        if ok and type(p) == "number" then return p end
        return nil
    end)()
    local ddUsable = (function()
        if type(WR_SpellUsable) ~= "function" then return nil end
        local ok, v = pcall(WR_SpellUsable, "制裁之锤")
        if not ok then return nil end
        return v
    end)()
    local ddHit = WR_PaladinForever_CanHitTarget and WR_PaladinForever_CanHitTarget("制裁之锤", "target") or nil
    print("|cff00ff00[MKPAL]|r 打断：滑块阈值=" .. tostring(ddThr)
        .. " 制裁已学=" .. tostring(ddSpell)
        .. " 目标施法进度=" .. tostring(ddCast and string.format("%.0f%%", ddCast) or "无/读不到")
        .. " 技能可用=" .. tostring(ddUsable)
        .. " 目标可命中=" .. tostring(ddHit))
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
