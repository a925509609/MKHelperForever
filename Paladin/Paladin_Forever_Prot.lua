-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "PALADIN" then return end
-- ============================================================
-- Paladin Forever · Prot 专精循环（坦克：多目标固定优先级 / 目标 ≤1 的 Ready-first 调度）
-- ------------------------------------------------------------
-- ★ 2026-11-10 用户口径：8 码内目标 ≥2 个时切换为「多目标固定优先级」
--     奉献（≥3 目标时）→ 审判 → 神圣打击 → 驱邪术（可用就打）→ 神圣之盾
--   ★★ 2026-11-13 追加口径：目标生命 <20% 时「愤怒之锤」插入 审判 之后、
--     神圣打击 之前（30 码斩杀收尾；单体链插在 Ready-first 之后、驱邪术之前）。
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
--     （实际顺序：驱邪术 → 奉献（单体链不可达）→ 神圣之盾）。
--   ★★ 2026-11-16 用户口径：自动「制裁之锤」打断恢复，由面板「打断」滑块 FH_DD
--     控制（0=关闭，5~100=目标施法进度百分比，默认 50）；「插入 制裁之锤」
--     一次性手动开关仍保留。
--   ★★ 2026-11-13 用户口径：单体链新增「愤怒之锤」分支——目标生命 <20% 且
--     审判/神圣打击都不可用时优先斩杀收尾（在驱邪术之前），受面板 FH_FNZC 控制。
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
--   · 目标已有「光明审判」debuff 时，自动切回「上一次圣印」（点火前正在用的圣印）；
--   · 本服「光明审判」持续 40 秒（ForeverDB build 1.60.1.70862，Classic 10 秒），
--     到期后自动重复上述循环。
-- ★★ 2026-11-12 用户口径（切印时机）：
--   「修正各项维持buff常驻开关切圣印的时机，当审判cd还有2秒钟恢复使用时
--     目标没有对应审判buff，这时候再切选择的对应圣印打审判，
--     不要第一时间开启了维持审判buff的开关后就切对应圣印等审判使用」
--   实现：phase 0 在切印前先过「审判剩余冷却 ≤ 2 秒」窗口
--   （WR_PaladinForever_JudgementSwitchDue）；未到窗口就【维持常驻圣印】、
--   不切印、直接 return false。窗口内才切对应圣印，然后等审判就绪打出去。
--   这样勾选开关 / debuff 到期后不会长时间占着 buff 圣印干等审判 CD。
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

-- ============================================================
-- ★★★ 2026-11-13 用户口径：「光明/智慧审判互斥」——一身只能挂一种审判
-- ------------------------------------------------------------
-- 用户原话：
--   「防骑目前还存在一个问题，当圣印选择了光明，审判buff选择了智慧审判，
--     会导致智慧审判和身上的光明审判互相顶，圣印选择了智慧也存在这样的问题，
--     需要设置限制光明和智慧圣印时目标有智慧或光明审判buff将不使用审判」
--
-- 背景（本服法术书实测，talentsforever.com/export/paladin.json）：
--   「审判」描述：Unleash the energy of a Seal spell upon an enemy.
--               Only one Judgement per Paladin can be active at any one time.
--   「光明圣印」：Unleashing this Seal's energy will judge an enemy for 40 sec,
--               granting melee attacks ... a chance of healing the attacker.
--   「智慧圣印」：Unleashing this Seal's energy will judge an enemy for 40 sec,
--               granting attacks and spells ... a chance to restore mana.
--   即：光明审判 / 智慧审判 **同属 Paladin 自己的「审判」debuff 槽位**，
--   每人同时只能存在一条。身上是光明圣印 / 智慧圣印时打审判，会用**当下**的
--   圣印覆盖目标身上已有的那条审判 —— 于是：
--     · 开着「智慧审判」维持开关，目标刚被常驻光明圣印挂上光明审判，
--       状态机一打审判就把光明审判顶成智慧审判；
--     · 开着「光明圣印」维持开关，目标刚被常驻智慧圣印挂上智慧审判，同理被顶。
--   表现就是「智慧审判和身上的光明审判互相顶」。
--
-- 修法（本条限制）：只要
--   ① 面板「圣印」专区所选常驻圣印是光明圣印或智慧圣印，**或**
--   ② 光明圣印 / 智慧审判 两个维持开关有一个勾着（即循环会把你切到光明或智慧圣印），
--   那么目标身上已经存在「光明审判」或「智慧审判」任意一条时，
--   本次审判**不再施放**（不点亮审判色块），让那条审判自然吃完 40 秒。
-- 不做的事（避免误伤）：
--   · 不限制十字军圣印 / 正义圣印 / 愤怒圣印等其它圣印——它们的审判不是这两条，
--     不会互相顶；
--   · 不因此切圣印、不改 phase、不取消勾选：只是这一发审判先不打，
--     其它技能照常轮转，40 秒到期后状态机按原节奏重新挂审判。
-- ============================================================
-- 目标身上「单审判槽位」debuff 的两条候选名（不同客户端/版本翻译不同）
WR_PaladinForever_SINGLE_JUDGEMENT_NAMES = {
    "光明审判", "圣光审判",
    "智慧审判", "智慧圣印",
}


-- ★★ 2026-11-11 用户口径：奉献蓝量下限 30%。
--   蓝量百分比（0~1）低于该值时不提示/不施放奉献；>= 0.30 才允许。
WR_PaladinForever_PROT_CONSECRATION_MANA_MIN = 0.30
-- ★★★ 2026-11-13：愤怒之锤（斩杀）蓝量下限 20%——目标生命 <20% 且蓝量 ≥20% 才点亮。
--   本服 Rank1 耗蓝 295（截图实测 SpellID 24275 / 0.87 秒读条 / 6 秒 CD）；
--   20% 档比奉献（30%）宽松，保证斩杀窗口内低蓝也优先收尾。
--   ★ 如实说明（与奉献蓝量门同一口径）：战斗中 UnitPower 是 secret →
--   WR_GetUnitMP 降级为 1（=满蓝），此门在战斗中恒通过；保留它是因为
--   脱战/可读时仍然有效，且低蓝时能提前停止提示斩杀读条。
WR_PaladinForever_PROT_HOW_MANA_MIN = 0.20

-- ★★★ 2026-11-14 修复：愤怒之锤从未点亮（Forever 隐藏目标血量）
-- ------------------------------------------------------------
-- 现象：防骑「愤怒之锤」开关一直勾着，目标进斩杀线后也从不亮色块、从没打出去。
-- 根因：无限/WoW Forever 的 UnitHealth / UnitHealthMax 对插件恒为 secret 值，
--   WR_SafeHPPct 按安全层口径降级为 1（=满血）→ 旧门
--   `WR_SafeHPPct("target") < 0.20` 永远不成立 → hammerEligible 恒 false。
--   这不是触发条件写错，而是本服血量不可读。
-- 修法（两条通道都不比较 secret 值）：
--   · 血量可读（经典 / SoD / 离线夹具）→ 仍按 <20% 判定；
--   · 血量不可读（Forever 常态）→ 用 C_Spell.IsSpellUsable(当前 rank) 判定。
--     本服 IsUsableSpell 已映射到 C_Spell.IsSpellUsable（Core_Functions.lua:158），
--     而「愤怒之锤」是仅斩杀期可施放的技能：客户端的可用性本身就是执行期信号，
--     且该返回值在 12.x 里不是 secret（不能拿血量做比较，但可拿 IsSpellUsable 判）。
--   · 再加 C_SpellActivationOverlay.IsSpellOverlayed（暴雪给执行期技能的原生发光）兜底。
-- 说明：宁可少打一次，也不在非斩杀期空放读条（0.87 秒 / 295 蓝）。
-- secret 检测：夹具里 WR_IsSecretValue 可能是 userdata，必须 pcall 探测
local function WR_PaladinForever_IsSecret(v)
    if WR_IsSecretValue == nil then return false end
    local ok, r = pcall(WR_IsSecretValue, v)
    return ok and r == true
end

-- ★★ 2026-11-18：secret 安全的布尔收敛（true / false / nil=读不到）。
-- 背景：Forever 12.x 在战斗/副本受限上下文里，UnitIsPlayer / UnitIsDeadOrGhost /
--   UnitIsUnit / UnitIsFriend 的返回值可能是 secret boolean。裸真值判断拿不到
--   「确认的 true」，裸 == 比较直接抛 "attempt to compare a secret boolean value"，
--   整条防骑 tick 被看门狗吞掉（表现就是循环失效）。
-- 口径（与 Paladin_Forever.lua:1987 UnitIsDeadOrGhost 一致）：比较本身包 pcall，
--   只有【确认 true】才算 true；secret / 抛错一律返回 nil，由调用方决定放行还是跳过。
local function WR_PaladinForever_SafeBool(v)
    if type(v) == "boolean" then return v end
    if v == nil then return nil end
    if WR_PaladinForever_IsSecret(v) then return nil end
    local okT, isTrue = pcall(function() return v == true end)
    if okT and isTrue == true then return true end
    local okF, isFalse = pcall(function() return v == false end)
    if okF and isFalse == true then return false end
    return nil
end

function WR_PaladinForever_HammerRankIDs()
    local ids = { 24275, 24274, 24239 }   -- 愤怒之锤 Rank1/2/3（Forever DB：44/52/60 级）
    if WR_ResolveSpellID ~= nil then
        local ok, cur = pcall(WR_ResolveSpellID, "愤怒之锤")
        if ok and type(cur) == "number" then
            -- ★ 当前 rank 必须放第一位：C_Spell.IsSpellUsable 对「未学会的 rank」返回 false，
            --   若先用 Rank1 探测而角色已换到 Rank2/3，会误判为不可用而永远不点亮。
            table.insert(ids, 1, cur)
        end
    end
    return ids
end

-- 目标血量百分比：可读返回 0~1；secret / API 缺失 / 读失败返回 nil（绝不猜 0 或 1）
function WR_PaladinForever_TargetHealthPctSafe()
    if UnitHealth == nil or UnitHealthMax == nil then
        return nil
    end
    local okH, hp = pcall(UnitHealth, "target")
    local okM, maxHP = pcall(UnitHealthMax, "target")
    if not okH or not okM then return nil end
    if WR_PaladinForever_IsSecret(hp) or WR_PaladinForever_IsSecret(maxHP) then
        return nil
    end
    hp = (type(hp) == "number") and hp or nil
    maxHP = (type(maxHP) == "number") and maxHP or 0
    if hp == nil or maxHP <= 0 then return nil end
    return hp / maxHP
end

-- 愤怒之锤此刻是否处于「可提示」状态（执行期 + 学会 + 冷却 + 蓝量）
--   ★ 全部在普通 number / boolean 上比较，绝不把 secret 值带进判断。
function WR_PaladinForever_HammerExecuteReady()
    -- ① 环境没有 UnitHealth（离线夹具 / 极旧客户端）：沿用 WR_SafeHPPct 桩判定
    if UnitHealth == nil or UnitHealthMax == nil then
        local pct = 1
        if WR_SafeHPPct ~= nil then
            local okP, v = pcall(WR_SafeHPPct, "target")
            if okP and type(v) == "number" then pct = v end
        end
        if type(pct) == "number" and pct < 0.20 then
            if WR_SpellUsable == nil then return false end
            local okU, usable = pcall(WR_SpellUsable, "愤怒之锤", true)
            return okU and usable == true
        end
        return false
    end

    -- ② 血量可读：传统 <20% 门（SoD / 经典）
    local pct = WR_PaladinForever_TargetHealthPctSafe()
    if pct ~= nil then
        if pct >= 0.20 then return false end
        if WR_SpellUsable == nil then return false end
        local okU, usable = pcall(WR_SpellUsable, "愤怒之锤", true)
        return okU and usable == true
    end

    -- ③ 血量不可读（Forever 常态）：C_Spell.IsSpellUsable 是执行期的权威非 secret 信号
    local ids = WR_PaladinForever_HammerRankIDs()
    if C_Spell ~= nil and C_Spell.IsSpellUsable ~= nil then
        for i = 1, #ids do
            local ok, usable, noMana = pcall(C_Spell.IsSpellUsable, ids[i])
            if ok then
                local u = usable
                if type(u) == "table" then
                    local raw = u.isUsable
                    if raw == nil then raw = u.usable end
                    if WR_PaladinForever_IsSecret(raw) then raw = nil end
                    u = raw
                end
                if WR_PaladinForever_IsSecret(u) then u = nil end
                if WR_PaladinForever_IsSecret(noMana) then noMana = nil end
                if u == true then return true end
                if u == false then
                    -- false 可能是 CD / 蓝不够 / 不在斩杀线：本函数一律判死，
                    -- 让主循环继续走别的技能；冷却由 ShowSkillCD 的本地记账再兜一层。
                    return false
                end
            end
        end
    end

    -- ④ 原生「技能发光」兜底（某些客户端只给按钮发光，不暴露 usable）
    if C_SpellActivationOverlay ~= nil and C_SpellActivationOverlay.IsSpellOverlayed ~= nil then
        for i = 1, #ids do
            local ok, lit = pcall(C_SpellActivationOverlay.IsSpellOverlayed, ids[i])
            if ok and lit == true then return true end
        end
    end
    return false
end

-- ★★★ 2026-11-14 用户口径「防骑再新增一个愤怒之锤的按钮，控制愤怒之锤目标为精英怪，
--   boss 的时候才用」：新增「愤怒之锤·精英」开关 FH_FNZC_JY。
--   · 关闭（默认）：保持原行为，进入斩杀期就对当前目标提示，不限怪物类型；
--   · 开启：只对精英怪 / BOSS 提示，普通小怪不浪费 0.87 秒读条与 295 蓝。
--   判定来源（任一命中即算精英/BOSS）：
--     ① UnitClassification：elite / rareelite / worldboss / boss；
--     ② WR_UnitIsBoss（boss1~5 单位帧、骷髅级、UnitIsBoss、副本战斗兜底）；
--     ③ UnitLevel < 0（骷髅级）。
--   说明：分类读不到 / 是 secret 时，野外按「不是精英」处理（宁可不打，也不把
--   斩杀读条浪费在小怪身上）；5 人本/团本按副本精英放行；玩家随时可关掉开关恢复全目标行为。
function WR_PaladinForever_HammerTargetIsEliteOrBoss(unit)
    if type(unit) ~= "string" or unit == "" then unit = "target" end

    -- ★ 2026-11-17 修复：Forever 12.x 在战斗/副本里会把 UnitClassification、UnitLevel
    --   变成 secret 值；旧代码直接比较 / 直接 if 判断会抛
    --   "attempt to compare a secret string/number"，整条防骑循环当场中断。
    --   所有读取先 pcall + secret 过滤，读不到就继续看下一个信号。
    if WR_UnitIsBoss ~= nil then
        local okB, isBoss = pcall(WR_UnitIsBoss, unit)
        if okB and not WR_PaladinForever_IsSecret(isBoss) and isBoss == true then
            return true
        end
    end
    if UnitClassification ~= nil then
        local okC, cls = pcall(UnitClassification, unit)
        if okC and not WR_PaladinForever_IsSecret(cls) and type(cls) == "string" then
            if cls == "elite" or cls == "rareelite" or cls == "worldboss" or cls == "boss" then
                return true
            end
        end
    end
    if UnitLevel ~= nil then
        local okL, lvl = pcall(UnitLevel, unit)
        if okL and not WR_PaladinForever_IsSecret(lvl) and type(lvl) == "number" and lvl < 0 then
            return true
        end
    end
    if UnitIsBoss ~= nil then
        local okB, isBoss = pcall(UnitIsBoss, unit)
        if okB and not WR_PaladinForever_IsSecret(isBoss) and isBoss == true then
            return true
        end
    end

    -- ★ 2026-11-17：副本兜底。Forever 在 5 人本/团本里把 UnitClassification / UnitLevel
    --   也设为 secret，但副本里的敌对目标按设计全部是精英（普通小怪只存在于野外）。
    --   分类读不到时按「在队伍副本/团本里」放行，保证精英开关在副本内仍然有效。
    if IsInInstance ~= nil then
        local okI, inInstance, instanceType = pcall(IsInInstance)
        if okI and not WR_PaladinForever_IsSecret(inInstance) and inInstance == true
            and not WR_PaladinForever_IsSecret(instanceType) and type(instanceType) == "string"
            and (instanceType == "party" or instanceType == "raid") then
            return true
        end
    end

    return false
end

-- 愤怒之锤目标类型门：FH_FNZC_JY 关闭时全部放行（保持原行为）；
-- 开启时只允许精英怪 / BOSS。主链与第 11 档兜底共用 hammerEligible。
function WR_PaladinForever_HammerTargetAllowed(unit)
    if PigSet == nil or PigSet.FH_FNZC_JY ~= true then return true end
    return WR_PaladinForever_HammerTargetIsEliteOrBoss(unit)
end

local function WR_PaladinForever_StripSealRankSuffix(nm)
    if type(nm) ~= "string" then return nil end
    local s = string.gsub(nm, "%s*（等级%s*%d+）%s*$", "")
    if s == nm then
        s = string.gsub(nm, "%s*%(等级%s*%d+%)%s*$", "")
    end
    return s
end

-- ★★★ 2026-11-15：按「目标」分别记录自己打出的审判 debuff 到期时刻。
--   背景：战斗中目标光环是 secret，WR_GetUnitDebuffTime 对新目标可能读不到；
--   旧的单条本地账只记录「最后一次审判的目标」，A→B→A 切回 A 时旧账还停在 B，
--   状态机误判 A 没有智慧审判 → 再次切智慧圣印重打（用户实测截图：A 身上明明
--   还有 39 秒「智慧审判」）。现在按 targetKey 分目标记账，换目标后仍能兜底。
WR_PaladinForever_JudgementMemory = WR_PaladinForever_JudgementMemory or {}

function WR_PaladinForever_PruneJudgementMemory(now)
    local mem = WR_PaladinForever_JudgementMemory
    if type(mem) ~= "table" then
        WR_PaladinForever_JudgementMemory = {}
        return
    end
    now = tonumber(now) or GetTime()
    local kinds = { "light", "wisdom", "crusader" }
    for key, rec in pairs(mem) do
        if type(rec) ~= "table" then
            mem[key] = nil
        else
            local any = false
            for i = 1, #kinds do
                local kind = kinds[i]
                local untilAt = tonumber(rec[kind])
                if type(untilAt) == "number" and untilAt > now then
                    rec[kind] = untilAt
                    any = true
                else
                    rec[kind] = nil
                end
            end
            if not any then mem[key] = nil end
        end
    end
end

-- 当前目标身上的本地审判记忆剩余秒数（只认自己实际打出过的审判）
function WR_PaladinForever_LocalJudgementRemain(kind)
    if type(kind) ~= "string" then return 0 end
    local key = WR_PaladinForever_JudgementSealTargetKey()
    if key == nil then return 0 end
    local mem = WR_PaladinForever_JudgementMemory
    local rec = type(mem) == "table" and mem[key] or nil
    if type(rec) ~= "table" then return 0 end
    local untilAt = tonumber(rec[kind])
    if type(untilAt) ~= "number" then return 0 end
    local remain = untilAt - GetTime()
    if remain <= 0 then
        rec[kind] = nil
        return 0
    end
    return remain
end

-- 目标身上某个「审判」debuff 的剩余时间（通用）：
--   0 = 没读到 / 没有；>0 = 剩余秒数；999 = 有但到期时间不可读
--   names 为候选名称数组，兼容不同客户端/旧版本的翻译差异。
--   kind（可选）：light / wisdom / crusader —— 光环读不到时按该目标本地账兜底。
function WR_PaladinForever_JudgementSealDebuffRemain(names, kind)
    if type(WR_GetUnitDebuffTime) ~= "function" then
        if kind ~= nil then
            local localRemain = WR_PaladinForever_LocalJudgementRemain(kind)
            if type(localRemain) == "number" and localRemain > 0 then
                return math.min(localRemain, 999), "local"
            end
        end
        return 0, "aura"
    end
    local best = 0
    for i = 1, #names do
        local ok, t = pcall(WR_GetUnitDebuffTime, "target", names[i])
        if ok and type(t) == "number" and t > 0 then
            if t >= 900 then return 999, "aura" end
            if t > best then best = t end
        end
    end
    if best <= 0 and kind ~= nil then
        local localRemain = WR_PaladinForever_LocalJudgementRemain(kind)
        if type(localRemain) == "number" and localRemain > 0 then
            return math.min(localRemain, 999), "local"
        end
    end
    return best, "aura"
end

-- 目标身上「光明审判」debuff 剩余时间：
--   0 = 没读到 / 没有；>0 = 剩余秒数；999 = 有但到期时间不可读
--   ★ 名称兼容：本服/不同客户端把 Judgement of Light 可能翻译成「光明审判」或
--     「圣光审判」，旧版本还曾用「光明圣印」当目标 debuff 名；三个名字都查，
--     避免因为名称不一致导致「明明已经挂了审判，却一直不切回常驻圣印」。
function WR_PaladinForever_LightSealDebuffRemain()
    return WR_PaladinForever_JudgementSealDebuffRemain({ "光明审判", "圣光审判", "光明圣印" }, "light")
end

-- 目标身上「十字军审判」debuff 剩余时间：
--   本服名称「十字军审判」；「十字军圣印」作为旧名/异常翻译兜底。
function WR_PaladinForever_CrusaderSealDebuffRemain()
    return WR_PaladinForever_JudgementSealDebuffRemain({ "十字军审判", "十字军圣印" }, "crusader")
end

-- 目标身上「智慧审判」debuff 剩余时间：
--   本服名称「智慧审判」；「智慧圣印」作为旧名/异常翻译兜底。
function WR_PaladinForever_WisdomSealDebuffRemain()
    return WR_PaladinForever_JudgementSealDebuffRemain({ "智慧审判", "智慧圣印" }, "wisdom")
end

-- ★ 2026-11-13：以下三个门控函数必须定义在
--   WR_PaladinForever_JudgementSealDebuffRemain 之后。
--   原先它们放在本文件顶部（常量区），那里 JudgementSealDebuffRemain 尚未定义，
--   于是 SingleSlotJudgementUp 里的 type(...) ~= "function" 恒成立 → 永远
--   return false → JudgementAllowed 恒为 true → 「互斥限制」静默失效
--   （目标已有光明/智慧审判时仍会打审判，把它顶掉）。
-- 本次审判会不会占用「光明/智慧审判」那一个共享槽位
--   sealName = 本次审判实际消耗的圣印：
--              · 主调度传面板「圣印」专区所选常驻圣印；
--              · 光明/智慧 buff 维持状态机传自己当前切过去的那条圣印。
--   返回 true 表示：此刻打出去的审判只会是光明审判或智慧审判之一。
--   ★★★ 2026-11-14 用户口径「愤怒和正义不会顶审判buff，要正常打审判」：
--     正义圣印 / 愤怒圣印的审判不产生审判 debuff，不占这个槽位，
--     不能被 FH_CRGMSY / FH_ZHSP 之类的审判buff开关误伤——只有本次真的用
--     光明圣印 / 智慧圣印打审判时才算单槽位。
function WR_PaladinForever_JudgementUsesSingleSlot(sealName)
    if sealName == WR_PaladinForever_LIGHT_SEAL_NAME then return true end
    if sealName == WR_PaladinForever_WISDOM_SEAL_NAME then return true end
    return false
end

-- ★★★ 2026-11-13（v2）：战斗中 target 光环是 secret，WR_GetUnitDebuffTime 读不到
--   光明/智慧审判 debuff → 旧门控恒判「没有审判」，主调度照常打审判。
--   常驻光明圣印时这一发就是光明审判，会把刚挂上的智慧审判顶掉（用户实测冲突）。
--   修法：审判成功时按「施放瞬间身上的圣印」记一条 40 秒本地账（kind = light/wisdom），
--   光环可读时以光环为准；不可读时用本地账兜底。
-- ★★★ 2026-11-15：本地账改为「按目标 key 分开记」（见文件上方 JudgementMemory），
--   不再因为换目标就把别的目标的账覆盖；单条旧字段保留给无法读到 targetKey 的场景。
WR_PaladinForever_SINGLE_JUDGEMENT_SECONDS = 40

function WR_PaladinForever_NoteSingleSlotJudgement(kind, untilAt)
    if kind ~= "light" and kind ~= "wisdom" and kind ~= "crusader" then return end
    local t = tonumber(untilAt) or (GetTime() + WR_PaladinForever_SINGLE_JUDGEMENT_SECONDS)
    if kind == "light" or kind == "wisdom" then
        WR_PaladinForever_SingleSlotJudgementUntil = t
        WR_PaladinForever_SingleSlotJudgementKind = kind
        WR_PaladinForever_SingleSlotJudgementTarget = WR_PaladinForever_JudgementSealTargetKey()
    end
    local key = WR_PaladinForever_JudgementSealTargetKey()
    if key == nil then return end
    local mem = WR_PaladinForever_JudgementMemory
    if type(mem) ~= "table" then
        mem = {}
        WR_PaladinForever_JudgementMemory = mem
    end
    local rec = mem[key]
    if type(rec) ~= "table" then
        rec = {}
        mem[key] = rec
    end
    -- ★★★ 2026-11-18：光明 / 智慧 / 十字军审判三条审判同属目标身上的一个
    --   「审判」槽位：打上其中一条时另外两条都已被顶掉，本地账同步互清。
    --   旧账只在光明↔智慧之间互清，十字军审判被智慧/光明审判顶掉后
    --   rec.crusader 还挂着旧账 → 十字军状态机误以为 buff 还在，
    --   40 秒内不再续挂（用户实测「审判buff被顶掉」的放大器）。
    if kind == "light" then
        rec.wisdom = nil
        rec.crusader = nil
    elseif kind == "wisdom" then
        rec.light = nil
        rec.crusader = nil
    elseif kind == "crusader" then
        rec.light = nil
        rec.wisdom = nil
    end
    rec[kind] = t
    WR_PaladinForever_PruneJudgementMemory(GetTime())
end

function WR_PaladinForever_ClearSingleSlotJudgement()
    WR_PaladinForever_SingleSlotJudgementUntil = nil
    WR_PaladinForever_SingleSlotJudgementKind = nil
    WR_PaladinForever_SingleSlotJudgementTarget = nil
end

-- 返回：kind（"light"/"wisdom"/nil）、剩余秒数、来源（"aura"/"local"/nil）
function WR_PaladinForever_SingleSlotJudgementInfo()
    local lightRemain, lightSource = WR_PaladinForever_LightSealDebuffRemain()
    if type(lightRemain) == "number" and lightRemain > 0 then
        return "light", lightRemain, lightSource or "aura"
    end
    local wisdomRemain, wisdomSource = WR_PaladinForever_WisdomSealDebuffRemain()
    if type(wisdomRemain) == "number" and wisdomRemain > 0 then
        return "wisdom", wisdomRemain, wisdomSource or "aura"
    end
    -- ★★★ 2026-11-15：目标光环读不到（战斗中 secret / 刚换目标缓存未刷新）时，
    --   按「当前目标 key」取本地账；这样 A→B→A 切回 A 仍知道 A 身上的智慧审判还没到期。
    local localLight = WR_PaladinForever_LocalJudgementRemain("light")
    if type(localLight) == "number" and localLight > 0 then
        return "light", localLight, "local"
    end
    local localWisdom = WR_PaladinForever_LocalJudgementRemain("wisdom")
    if type(localWisdom) == "number" and localWisdom > 0 then
        return "wisdom", localWisdom, "local"
    end
    local untilAt = WR_PaladinForever_SingleSlotJudgementUntil
    if type(untilAt) == "number" and GetTime() < untilAt then
        local stored = WR_PaladinForever_SingleSlotJudgementTarget
        local current = WR_PaladinForever_JudgementSealTargetKey()
        -- 换目标（两边都能读到且不同）→ 旧账作废
        if not (stored and current and stored ~= current) then
            return WR_PaladinForever_SingleSlotJudgementKind or "unknown",
                untilAt - GetTime(), "local"
        end
    end
    return nil, 0, nil
end

-- 目标身上当前是否已有「光明审判」或「智慧审判」任意一条（同槽位占用）
--   ★ 用基础名剥离等级后缀，兼容「光明审判（等级 2）」这类本服写法
function WR_PaladinForever_SingleSlotJudgementUp()
    local kind = WR_PaladinForever_SingleSlotJudgementInfo()
    return kind ~= nil
end

-- 审判门控（供主调度与三个 buff 维持状态机统一使用）
--   sealName   = 本次审判实际消耗的圣印（主调度传常驻圣印；状态机传自己切过去的圣印）
--   desiredKind：
--     nil      = 主调度通用审判：任何已有的光明/智慧审判都不许顶
--     "light"  = 本次要打光明审判：目标已有智慧审判 → 不许顶
--     "wisdom" = 本次要打智慧审判：允许把光明审判顶成智慧审判（用户要的就是智慧）
--   返回 true  = 此刻可以打审判
function WR_PaladinForever_JudgementAllowed(sealName, desiredKind)
    if not WR_PaladinForever_JudgementUsesSingleSlot(sealName) then return true end
    local kind = WR_PaladinForever_SingleSlotJudgementInfo()
    if kind == nil then return true end
    if desiredKind == "wisdom" then
        -- 智慧审判可以顶掉光明审判；同类已有无需重复施放
        return kind == "light"
    end
    -- 光明审判 / 主调度通用审判：存在光明或智慧审判时都不打
    return false
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

-- 玩家身上是否是「面板圣印专区所选」的常驻圣印。
-- ★★★ 2026-11-14：buff 维持状态机 phase4（目标已有审判 debuff）用它判断
--   「是否已经切回常驻」。旧逻辑只判 LightSealOnPlayer()，一旦战斗中光明圣印
--   光环读不到 / 名字 secret，就误判「不在光明」→ 永不提示切回愤怒圣印。
function WR_PaladinForever_MainSealOnPlayer()
    local name, _, field = WR_PaladinForever_MainSeal()
    local castAt = nil
    if type(field) == "string" then
        -- 各圣印的施放计时是全局变量 WR_PaladinForever_<field>（不是表字段）
        castAt = _G["WR_PaladinForever_" .. field]
    end
    return WR_PaladinForever_JudgementSealOnPlayer(name, castAt)
end

-- 当前是否应该从「另一条 buff 圣印」切回面板所选常驻圣印。
-- ★★★ 2026-11-14 用户口径：目标已有圣光审判、身上是光明圣印、面板选愤怒，
--   此时必须切回面板所选的愤怒圣印。判定只针对「审判 buff 维持类」圣印
--   （光明 / 十字军 / 智慧）且目标身上已经有它对应的审判 debuff——这时继续
--   维持该 buff 圣印已无收益；其它圣印（正义/公正等）不触发强切，保持旧行为。
--   光环名字读不到时退回最近一次成功施放的圣印名；都读不到返回 false。
function WR_PaladinForever_SealShouldSwitchToMain(mainSeal)
    if type(mainSeal) ~= "string" or mainSeal == "" then return false end
    local state, nm = WR_PaladinForever_SealBuffState()
    -- 光环不可读（unknown/missing）时不能直接判死：只要本地账认为「有圣印」
    -- 且最近一次成功施放的是另一条圣印，就按「身上是另一条」处理。
    if state ~= "up" and not WR_PaladinForever_AnySealUp() then return false end
    local name = nm
    if type(name) ~= "string" or name == "" then
        name = WR_PaladinForever_LastSealAppliedName
    end
    if type(name) ~= "string" or name == "" then return false end
    local base = WR_PaladinForever_StripSealRankSuffix(name)
    if type(base) ~= "string" or base == "" or base == mainSeal then return false end
    if base == WR_PaladinForever_LIGHT_SEAL_NAME then
        local remain = WR_PaladinForever_LightSealDebuffRemain()
        if type(remain) == "number" and remain > 0 then return true end
        local kind = WR_PaladinForever_SingleSlotJudgementInfo()
        return kind == "light"
    end
    if base == WR_PaladinForever_CRUSADER_SEAL_NAME then
        local remain = WR_PaladinForever_CrusaderSealDebuffRemain()
        if type(remain) == "number" and remain > 0 then return true end
        local kind = WR_PaladinForever_SingleSlotJudgementInfo()
        return kind == "crusader"
    end
    if base == WR_PaladinForever_WISDOM_SEAL_NAME then
        local remain = WR_PaladinForever_WisdomSealDebuffRemain()
        if type(remain) == "number" and remain > 0 then return true end
        local kind = WR_PaladinForever_SingleSlotJudgementInfo()
        return kind == "wisdom"
    end
    return false
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
-- ★★★ 2026-11-15（实战第二版）：目标 key 的「时序性 secret」盲区。
--   实战复现（用户实测「夹具全绿但游戏里依旧重复切智慧圣印」）：
--   审判施放事件回报的那一刻（事件回调里记账），战斗中 UnitGUID/UnitName
--   恰好处于 secret 状态 → key=nil → NoteSingleSlotJudgement 直接 return，
--   A 的按目标账【根本没记上】；之后切回 A 时 GUID 恢复可读 → mem[keyA]
--   查不到 + 旧单条账又被目标检查判无效（stored=B, current=A）→ 误判
--   「A 没有智慧审判」→ 再次切智慧圣印重打。
--   修法（三件套，全部不依赖事件时刻的 GUID 可读性）：
--   ① PLAYER_TARGET_CHANGED 递增 TargetEpoch（事件必触发，是换目标的权威信号）；
--   ② 每个 epoch 内第一次读到 key（GUID 或名字）就锁定快照，整个 epoch 复用
--      同一把钥匙（防 GUID/名字来源中途漂移导致账键对不上）；
--   ③ 直接读取读不到时回退快照（epoch 必须一致）。审判前一瞬主循环 tick
--      已锁定的快照，让事件回调记账也能落到正确目标头上。
WR_PaladinForever_TargetEpoch = WR_PaladinForever_TargetEpoch or 0
WR_PaladinForever_TargetKeySnapshot = WR_PaladinForever_TargetKeySnapshot or nil

local function WR_PaladinForever_RawTargetKey()
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

-- PLAYER_TARGET_CHANGED 回调：epoch+1 并尽力重建快照。
-- 由 Paladin_Forever.lua 的事件帧调用；离线夹具可直接手动调用模拟换目标。
function WR_PaladinForever_NoteTargetChanged()
    WR_PaladinForever_TargetEpoch = (WR_PaladinForever_TargetEpoch or 0) + 1
    WR_PaladinForever_TargetKeySnapshot = nil
    local key = WR_PaladinForever_RawTargetKey()
    if type(key) == "string" and key ~= "" then
        WR_PaladinForever_TargetKeySnapshot = { key = key, epoch = WR_PaladinForever_TargetEpoch }
    end
end

function WR_PaladinForever_JudgementSealTargetKey()
    local epoch = WR_PaladinForever_TargetEpoch or 0
    local snap = WR_PaladinForever_TargetKeySnapshot
    -- ★ 2026-11-15：先读实时值。实时值可读时永远以它为准——即使换目标事件
    --   漏发 / 夹具直接改 GUID，也不会被上一目标的快照锁死；快照只用于
    --   「事件时刻 GUID/Name 全 secret」时兜底。
    local key = WR_PaladinForever_RawTargetKey()
    if key ~= nil and key ~= "" then
        if type(snap) ~= "table" or snap.epoch ~= epoch or snap.key ~= key then
            WR_PaladinForever_TargetKeySnapshot = { key = key, epoch = epoch }
        end
        return key
    end
    if type(snap) == "table" and snap.epoch == epoch and type(snap.key) == "string"
        and snap.key ~= "" then
        return snap.key
    end
    return nil
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
    WR_PaladinForever_LightSealBackSeal = nil
    WR_PaladinForever_LightSealBackSlot = nil
    WR_PaladinForever_LightSealJudgeRetries = 0
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
    WR_PaladinForever_CrusaderSealBackSeal = nil
    WR_PaladinForever_CrusaderSealBackSlot = nil
    WR_PaladinForever_CrusaderSealJudgeRetries = 0
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
    WR_PaladinForever_WisdomJudgementTargetEpoch = nil
    WR_PaladinForever_WisdomJudgementMaintainPromptAt = nil
    WR_PaladinForever_WisdomJudgementBackSeal = nil
    WR_PaladinForever_WisdomJudgementBackSlot = nil
    WR_PaladinForever_WisdomJudgementJudgeRetries = 0
end

-- 某个 buff 维持状态机此刻是否「应该占着 buff 圣印」（切印/维持阶段）
-- ★★ 2026-11-12 用户口径：只有进入「审判剩余 ≤ 2 秒」窗口后才允许切 buff 圣印。
--   phase 1/2 已经切过去了，继续占着直到审判打出并切回；
--   phase 0 则必须等窗口到了才占（否则一直维持常驻圣印）。
function WR_PaladinForever_BuffSealHolds(phase, judgeCD)
    local ph = tonumber(phase) or 0
    if ph == 1 or ph == 2 then return true end
    if ph == 0 then
        return WR_PaladinForever_JudgementSwitchDue(judgeCD)
    end
    return false
end

-- ★★★ 2026-11-18 用户口径「切回上一次圣印」：
--   三个 buff 维持状态机的「切回」目标 = 点火（切到 buff 圣印）之前玩家
--   正在用的那条圣印（点火时记录为 BackSeal/BackSlot），而不是实时读取
--   面板「圣印」专区所选（FH_SEAL）。这样即使战斗中玩家改了面板选择，
--   收尾仍然切回切换前的那条圣印，与「之前版本」行为一致。
--   记录为空（旧存档/异常）时由调用方回退常驻圣印。
--   返回值：nil = 没有状态机处于收尾阶段；否则返回 backSeal, backSlot。
function WR_PaladinForever_BuffSealBackTarget()
    local checks = {
        { phase = WR_PaladinForever_LightSealPhase,       seal = WR_PaladinForever_LightSealBackSeal,       slot = WR_PaladinForever_LightSealBackSlot },
        { phase = WR_PaladinForever_CrusaderSealPhase,    seal = WR_PaladinForever_CrusaderSealBackSeal,    slot = WR_PaladinForever_CrusaderSealBackSlot },
        { phase = WR_PaladinForever_WisdomJudgementPhase, seal = WR_PaladinForever_WisdomJudgementBackSeal, slot = WR_PaladinForever_WisdomJudgementBackSlot },
    }
    for i = 1, #checks do
        local ph = tonumber(checks[i].phase) or 0
        if (ph == 3 or ph == 4)
           and type(checks[i].seal) == "string" and checks[i].seal ~= "" then
            return checks[i].seal, checks[i].slot
        end
    end
    return nil
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
    local judgeCD = WR_PaladinForever_GetJudgeCooldown()
    if PigSet and PigSet.FH_CRGMSY then
        local phase = WR_PaladinForever_LightSealPhase or 0
        if WR_PaladinForever_BuffSealHolds(phase, judgeCD) then
            return WR_PaladinForever_LIGHT_SEAL_NAME, WR_PaladinForever_LIGHT_SEAL_SLOT
        end
    end
    if PigSet and PigSet.FH_SZJSP then
        local phase = WR_PaladinForever_CrusaderSealPhase or 0
        if WR_PaladinForever_BuffSealHolds(phase, judgeCD) then
            return WR_PaladinForever_CRUSADER_SEAL_NAME, WR_PaladinForever_CRUSADER_SEAL_SLOT
        end
    end
    if PigSet and PigSet.FH_ZHSP then
        local phase = WR_PaladinForever_WisdomJudgementPhase or 0
        if WR_PaladinForever_BuffSealHolds(phase, judgeCD) then
            return WR_PaladinForever_WISDOM_SEAL_NAME, WR_PaladinForever_WISDOM_SEAL_SLOT
        end
    end
    -- ★★★ 2026-11-18：收尾（phase 3/4）的补印/切回目标改为「上一次圣印」
    --   （点火时记录），不再实时读面板「圣印」专区所选；记录为空时
    --   保持回退常驻圣印的原行为。
    local backSeal, backSlot = WR_PaladinForever_BuffSealBackTarget()
    if backSeal then return backSeal, backSlot or mainSealSlot end
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
    -- ★★★ 2026-11-13 用户口径「战斗中怪没有在近战位置，打不到也会切审判 buff 对应的圣印，
    --   导致和选择的圣印互顶，浪费了蓝」——状态机总门【打得到才切印】，（代码在下方脱战清零之后）：
    --   切 buff 圣印的唯一目的是「马上打一发审判挂 debuff」。目标不在审判射程（10 码）内时
    --   这一发根本打不出去，切过去只会白顶掉常驻圣印 + 白烧一次切印的蓝，零收益。
    --   ★ 只拦「新点火」（phase 为 nil 或 0）；已进入 phase 1/2/3/4 的流程照常收尾。
    if not UnitAffectingCombat("player") then
        WR_PaladinForever_ResetLightSealState()
        return false
    end

    -- ★★★ 2026-11-13 用户口径「勾选后，当目标已死亡且显示为尸体时，仍会切换所选圣印
    --   并尝试释放审判」——状态机总门【尸体不切印】：
    --   目标已确认死亡（含 ghost 态尸体）→ 整条流程直接放弃：重置阶段、本 tick
    --   不点亮任何色块——既不点火切 buff 圣印，也不会卡在 phase1~4 对着尸体空等超时；
    --   常驻圣印由主循环的圣印维持逻辑（CanApplySeal）自行恢复。
    --   口径：只拦【确认死亡】——读不到（secret / API 缺失）一律放行，与射程门一致。
    if WR_PaladinForever_UnitIsDeadOrGhost("target") then
        WR_PaladinForever_ResetLightSealState()
        return false
    end

    local now = GetTime()
    local phase = WR_PaladinForever_LightSealPhase or 0
    -- ★ 打得到才切印总门（2026-11-13，完整说明见上方 2026-11-13 注释块）：
    --   新点火（phase 0）且目标不在审判射程内 → 本 tick 直接不切印，维持常驻圣印。
    if phase == 0
       and not WR_PaladinForever_CanHitTarget("审判", "target") then
        return false
    end
    local lightName = WR_PaladinForever_LIGHT_SEAL_NAME
    local lightSlot = WR_PaladinForever_LIGHT_SEAL_SLOT
    -- ★★★ 2026-11-18 用户口径「切回上一次圣印」：切回目标 = 点火前正在用的圣印，
    --   不是实时读面板「圣印」专区所选；记录为空时回退常驻圣印。
    local backSeal = WR_PaladinForever_LightSealBackSeal or mainSeal
    local backSlot = WR_PaladinForever_LightSealBackSlot or mainSealSlot

    -- 0 → 首次判定：目标可能已经有光明审判（例如开关刚打开 / 重载插件）
    if phase == 0 then
        local remain = WR_PaladinForever_LightSealDebuffRemain()
        -- ★★★ 2026-11-13（v2）：战斗中目标光环不可读 → 用单审判槽位本地账兜底，
        --   已有光明审判就别再切光明圣印重打（避免 phase1 空等 / 白顶常驻圣印）。
        if type(remain) ~= "number" or remain <= 0 then
            local kind, localRemain = WR_PaladinForever_SingleSlotJudgementInfo()
            if kind == "light" then remain = localRemain end
        end
        if type(remain) == "number" and remain > 0 then
            -- ★ 2026-11-18：点火即记录「上一次圣印」（收尾切回用它）
            WR_PaladinForever_LightSealBackSeal = WR_PaladinForever_LightSealBackSeal or mainSeal
            WR_PaladinForever_LightSealBackSlot = WR_PaladinForever_LightSealBackSlot or mainSealSlot
            WR_PaladinForever_LightSealPhase = 4
            WR_PaladinForever_LightSealDebuffUntil = now
                + ((remain >= 900) and WR_PaladinForever_LIGHT_JUDGEMENT_SECONDS
                   or math.min(remain + 0.5, WR_PaladinForever_LIGHT_JUDGEMENT_SECONDS + 1))
            WR_PaladinForever_LightSealTarget = WR_PaladinForever_LightSealTargetKey()
            phase = 4
        end
    end

    if phase == 0 then
        -- ★★ 2026-11-12 用户口径：审判 CD 还有 2 秒以上时不切光明圣印，
        --   继续维持面板「圣印」专区所选常驻圣印；只有进入「审判剩余 ≤ 2 秒」
        --   窗口（含已就绪）且目标没有光明审判时，才切光明圣印去打审判。
        if not WR_PaladinForever_JudgementSwitchDue(WR_PaladinForever_GetJudgeCooldown()) then
            -- 兜底：身上若还挂着光明圣印（窗口外被手动切/上一轮残留），提示切回常驻圣印
            if backSeal ~= lightName and WR_PaladinForever_LightSealOnPlayer() then
                local promptAt = WR_PaladinForever_LightSealMaintainPromptAt or 0
                if (now - promptAt) >= 3.0 then
                    WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                    if WR_PaladinForever_ShowSealBlock(backSeal, backSlot) then
                        WR_PaladinForever_MarkPrompt(backSeal, backSlot)
                        WR_PaladinForever_HideSkillLater(backSeal, backSlot, 1.5)
                        WR_PaladinForever_LightSealMaintainPromptAt = now
                        return true
                    end
                end
            end
            return false
        end
        if not WR_PaladinForever_LightSealOnPlayer() then
            -- 需要切光明圣印：显式切印放行一次
            if WR_PaladinForever_CanApplySeal()
               and WR_PaladinForever_CanPrompt(lightName, 1.5) then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(lightName, lightSlot) then
                    WR_PaladinForever_MarkPrompt(lightName, lightSlot)
                    WR_PaladinForever_HideSkillLater(lightName, lightSlot, 1.5)
                    -- ★ 2026-11-18：点火即记录「上一次圣印」（收尾切回用它）
                    WR_PaladinForever_LightSealBackSeal = WR_PaladinForever_LightSealBackSeal or mainSeal
                    WR_PaladinForever_LightSealBackSlot = WR_PaladinForever_LightSealBackSlot or mainSealSlot
                    WR_PaladinForever_LightSealPhase = 1
                    WR_PaladinForever_LightSealAt = now
                    return true
                end
            end
        else
            -- 光明圣印已在身上 → 直接进入「等待审判」
            -- ★ 2026-11-18：同样记录「上一次圣印」（身上已是光明时收尾无需切回）
            WR_PaladinForever_LightSealBackSeal = WR_PaladinForever_LightSealBackSeal or mainSeal
            WR_PaladinForever_LightSealBackSlot = WR_PaladinForever_LightSealBackSlot or mainSealSlot
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
            -- ★★★ 2026-11-17：审判「真就绪」双通道判定（JudgeTrulyReady）。
            --   本地 cdv（天赋探测 8/10 秒）有偏差时，旧版会在审判实际还在 CD 中时
            --   反复点亮色块 → AHK 空按 → phase 2 确认不了 → 表现为「维持不灵敏」。
            if WR_PaladinForever_JudgeTrulyReady()
               and WR_PaladinForever_CanHitTarget("审判", "target")
               and WR_PaladinForever_JudgementAllowed(WR_PaladinForever_LIGHT_SEAL_NAME, "light") then
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
        if castConfirmed or debuffConfirmed then
            WR_PaladinForever_LightSealJudgeRetries = 0
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
            WR_PaladinForever_NoteSingleSlotJudgement("light", untilAt)
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
        elseif (now - judgeAt) >= 2.0 then
            -- ★★★ 2026-11-17 用户口径「防骑审判buff维持不灵敏」修复：
            --   2 秒内施放事件与目标光环都没确认 = 审判多半没打出去
            --   （提示时审判实际还在 CD / 被 GCD 吞 / AHK 漏按）。
            --   旧版在这里直接按「提示时刻 + 40 秒」进维持期——审判没打出去时
            --   目标 buff 空窗近 40 秒没人管，正是「维持不灵敏」的主因。
            --   现改为：立即回 phase 1 重试（审判一就绪马上重新提示，1 个 tick 内反应）；
            --   连续 3 次仍无任何确认才按旧兜底记 40 秒并切回常驻，防止全程 secret
            --   读不到施放事件的极端场景死循环。
            local retries = (tonumber(WR_PaladinForever_LightSealJudgeRetries) or 0) + 1
            WR_PaladinForever_LightSealJudgeRetries = retries
            if retries >= 3 then
                WR_PaladinForever_LightSealJudgeRetries = 0
                local untilAt = judgeAt + WR_PaladinForever_LIGHT_JUDGEMENT_SECONDS
                WR_PaladinForever_LightSealDebuffUntil = untilAt
                WR_PaladinForever_LightSealTarget = WR_PaladinForever_LightSealTargetKey()
                WR_PaladinForever_NoteSingleSlotJudgement("light", untilAt)
                if mainSeal == WR_PaladinForever_LIGHT_SEAL_NAME then
                    WR_PaladinForever_LightSealPhase = 4
                    WR_PaladinForever_LightSealSwitchAt = nil
                    WR_PaladinForever_LightSealSwitchBase = nil
                    WR_PaladinForever_LightSealDeadline = nil
                    return false
                end
                WR_PaladinForever_LightSealPhase = 3
                WR_PaladinForever_LightSealSwitchAt = 0
                WR_PaladinForever_LightSealSwitchBase = WR_PaladinForever_LastSealAppliedAt() or 0
                WR_PaladinForever_LightSealDeadline = now + 15
                phase = 3
            else
                -- 回 phase 1 重试：buff 圣印保持在身上，审判一就绪马上重新提示
                WR_PaladinForever_LightSealPhase = 1
                WR_PaladinForever_LightSealAt = now - 1.0  -- 跳过「等切印生效」的 1 秒
                WR_PaladinForever_LightSealJudgeAt = nil
                WR_PaladinForever_LightSealJudgeBase = nil
                WR_PaladinForever_LightSealDeadline = nil
                phase = 1
            end
        end
    end

    if phase == 3 then
        if backSeal == WR_PaladinForever_LIGHT_SEAL_NAME then
            -- 切回目标就是光明圣印（上一次圣印本身）：直接进入维持期，不重复提示上印
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
        -- ★ 2026-11-14 用户口径：能平砍的时候才挂自身圣印（切回也是挂印），
        --   不能平砍就不切，避免目标跑远 / 死亡时空放圣印；能平砍后下一 tick 会自动切回。
        if (now - switchAt) >= 2.0 then
            -- ★ 2026-11-18：显式切回「上一次圣印」（点火前正在用的圣印），不再实时读面板
            WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
            if WR_PaladinForever_ShowSealBlock(backSeal, backSlot) then
                WR_PaladinForever_MarkPrompt(backSeal, backSlot)
                WR_PaladinForever_HideSkillLater(backSeal, backSlot, 1.5)
                WR_PaladinForever_LightSealSwitchAt = now
                return true
            end
        end
    end

    if phase == 4 then
        if not UnitExists("target") or WR_PaladinForever_UnitIsDeadOrGhost("target") then
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
        -- 目标有 debuff 时应保持「上一次圣印」（点火前正在用的圣印）；尚未确认切回则继续提示
        -- ★★ 2026-11-11：上一次圣印就是光明圣印时无需切回（两者共存），跳过着色提示
        -- ★★★ 2026-11-14：反向确认「切回目标圣印是否已在身上」，读不到不误判（3 秒防抖）。
        -- ★★★ 2026-11-18 用户口径「切回上一次圣印」：切回目标 = 点火时记录的
        --   上一次圣印（BackSeal），不再实时读面板「圣印」专区所选。
        if backSeal ~= WR_PaladinForever_LIGHT_SEAL_NAME
           and not WR_PaladinForever_JudgementSealOnPlayer(
               backSeal, WR_PaladinForever_LastSealAppliedAt()) then
            local promptAt = WR_PaladinForever_LightSealMaintainPromptAt or 0
            if (now - promptAt) >= 3.0 then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(backSeal, backSlot) then
                    WR_PaladinForever_MarkPrompt(backSeal, backSlot)
                    WR_PaladinForever_HideSkillLater(backSeal, backSlot, 1.5)
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
--   · 目标已有「十字军审判」debuff 时，自动切回「上一次圣印」（点火前正在用的圣印）；
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

    -- ★★★ 2026-11-13 用户口径「勾选后，当目标已死亡且显示为尸体时，仍会切换所选圣印
    --   并尝试释放审判」——状态机总门【尸体不切印】：
    --   目标已确认死亡（含 ghost 态尸体）→ 整条流程直接放弃：重置阶段、本 tick
    --   不点亮任何色块——既不点火切 buff 圣印，也不会卡在 phase1~4 对着尸体空等超时；
    --   常驻圣印由主循环的圣印维持逻辑（CanApplySeal）自行恢复。
    --   口径：只拦【确认死亡】——读不到（secret / API 缺失）一律放行，与射程门一致。
    if WR_PaladinForever_UnitIsDeadOrGhost("target") then
        WR_PaladinForever_ResetCrusaderSealState()
        return false
    end

    local now = GetTime()
    local phase = WR_PaladinForever_CrusaderSealPhase or 0
    -- ★★★ 2026-11-13 用户口径「战斗中怪没有在近战位置，打不到也会切审判 buff 对应的圣印，
    --   导致和选择的圣印互顶，浪费了蓝」——状态机总门【打得到才切印】：
    --   切 buff 圣印的唯一目的是「马上打一发审判挂 debuff」。目标不在审判射程（10 码）内时
    --   这一发根本打不出去，切过去只会白顶掉常驻圣印 + 白烧一次切印的蓝，零收益。
    --   ★ 只拦「新点火」（phase 为 nil 或 0）；已进入 phase 1/2/3/4 的流程照常收尾。
    --   ★ 口径与主调度 judgeEligible 的 CanHitTarget 一致：距离读不到（999/secret）→ 放行。
    if phase == 0
       and not WR_PaladinForever_CanHitTarget("审判", "target") then
        return false
    end
    local crusaderName = WR_PaladinForever_CRUSADER_SEAL_NAME
    local crusaderSlot = WR_PaladinForever_CRUSADER_SEAL_SLOT
    -- ★★★ 2026-11-18 用户口径「切回上一次圣印」：同光明状态机。
    local backSeal = WR_PaladinForever_CrusaderSealBackSeal or mainSeal
    local backSlot = WR_PaladinForever_CrusaderSealBackSlot or mainSealSlot

    -- 0 → 首次判定：目标可能已经有十字军审判（例如开关刚打开 / 重载插件）
    if phase == 0 then
        local remain = WR_PaladinForever_CrusaderSealDebuffRemain()
        if type(remain) == "number" and remain > 0 then
            -- ★ 2026-11-18：点火即记录「上一次圣印」（收尾切回用它）
            WR_PaladinForever_CrusaderSealBackSeal = WR_PaladinForever_CrusaderSealBackSeal or mainSeal
            WR_PaladinForever_CrusaderSealBackSlot = WR_PaladinForever_CrusaderSealBackSlot or mainSealSlot
            WR_PaladinForever_CrusaderSealPhase = 4
            WR_PaladinForever_CrusaderSealDebuffUntil = now
                + ((remain >= 900) and WR_PaladinForever_CRUSADER_JUDGEMENT_SECONDS
                   or math.min(remain + 0.5, WR_PaladinForever_CRUSADER_JUDGEMENT_SECONDS + 1))
            WR_PaladinForever_CrusaderSealTarget = WR_PaladinForever_JudgementSealTargetKey()
            phase = 4
        end
    end

    if phase == 0 then
        -- ★★ 2026-11-12 用户口径：审判 CD 还有 2 秒以上时不切十字军圣印，
        --   继续维持面板「圣印」专区所选常驻圣印；只有进入「审判剩余 ≤ 2 秒」
        --   窗口（含已就绪）且目标没有十字军审判时，才切十字军圣印去打审判。
        if not WR_PaladinForever_JudgementSwitchDue(WR_PaladinForever_GetJudgeCooldown()) then
            if backSeal ~= crusaderName and WR_PaladinForever_CrusaderSealOnPlayer() then
                local promptAt = WR_PaladinForever_CrusaderSealMaintainPromptAt or 0
                if (now - promptAt) >= 3.0 then
                    WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                    if WR_PaladinForever_ShowSealBlock(backSeal, backSlot) then
                        WR_PaladinForever_MarkPrompt(backSeal, backSlot)
                        WR_PaladinForever_HideSkillLater(backSeal, backSlot, 1.5)
                        WR_PaladinForever_CrusaderSealMaintainPromptAt = now
                        return true
                    end
                end
            end
            return false
        end
        if not WR_PaladinForever_CrusaderSealOnPlayer() then
            -- 需要切十字军圣印：显式切印放行一次
            if WR_PaladinForever_CanApplySeal()
               and WR_PaladinForever_CanPrompt(crusaderName, 1.5) then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(crusaderName, crusaderSlot) then
                    WR_PaladinForever_MarkPrompt(crusaderName, crusaderSlot)
                    WR_PaladinForever_HideSkillLater(crusaderName, crusaderSlot, 1.5)
                    -- ★ 2026-11-18：点火即记录「上一次圣印」（收尾切回用它）
                    WR_PaladinForever_CrusaderSealBackSeal = WR_PaladinForever_CrusaderSealBackSeal or mainSeal
                    WR_PaladinForever_CrusaderSealBackSlot = WR_PaladinForever_CrusaderSealBackSlot or mainSealSlot
                    WR_PaladinForever_CrusaderSealPhase = 1
                    WR_PaladinForever_CrusaderSealAt = now
                    return true
                end
            end
        else
            -- 十字军圣印已在身上 → 直接进入「等待审判」
            -- ★ 2026-11-18：同样记录「上一次圣印」
            WR_PaladinForever_CrusaderSealBackSeal = WR_PaladinForever_CrusaderSealBackSeal or mainSeal
            WR_PaladinForever_CrusaderSealBackSlot = WR_PaladinForever_CrusaderSealBackSlot or mainSealSlot
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
            -- ★★★ 2026-11-17：审判「真就绪」双通道判定（JudgeTrulyReady），同光明状态机。
            if WR_PaladinForever_JudgeTrulyReady()
               and WR_PaladinForever_CanHitTarget("审判", "target")
               and WR_PaladinForever_JudgementAllowed(mainSeal) then
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
        if castConfirmed or debuffConfirmed then
            WR_PaladinForever_CrusaderSealJudgeRetries = 0
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
            WR_PaladinForever_NoteSingleSlotJudgement("crusader", untilAt)
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
        elseif (now - judgeAt) >= 2.0 then
            -- ★★★ 2026-11-17 用户口径「防骑审判buff维持不灵敏」修复：
            --   2 秒内施放事件与目标光环都没确认 = 审判多半没打出去
            --   （提示时审判实际还在 CD / 被 GCD 吞 / AHK 漏按）。
            --   旧版在这里直接按「提示时刻 + 40 秒」进维持期——审判没打出去时
            --   目标 buff 空窗近 40 秒没人管，正是「维持不灵敏」的主因。
            --   现改为：立即回 phase 1 重试（审判一就绪马上重新提示，1 个 tick 内反应）；
            --   连续 3 次仍无任何确认才按旧兜底记 40 秒并切回常驻，防止全程 secret
            --   读不到施放事件的极端场景死循环。
            local retries = (tonumber(WR_PaladinForever_CrusaderSealJudgeRetries) or 0) + 1
            WR_PaladinForever_CrusaderSealJudgeRetries = retries
            if retries >= 3 then
                WR_PaladinForever_CrusaderSealJudgeRetries = 0
                local untilAt = judgeAt + WR_PaladinForever_CRUSADER_JUDGEMENT_SECONDS
                WR_PaladinForever_CrusaderSealDebuffUntil = untilAt
                WR_PaladinForever_CrusaderSealTarget = WR_PaladinForever_JudgementSealTargetKey()
                WR_PaladinForever_NoteSingleSlotJudgement("crusader", untilAt)
                if mainSeal == WR_PaladinForever_CRUSADER_SEAL_NAME then
                    WR_PaladinForever_CrusaderSealPhase = 4
                    WR_PaladinForever_CrusaderSealSwitchAt = nil
                    WR_PaladinForever_CrusaderSealSwitchBase = nil
                    WR_PaladinForever_CrusaderSealDeadline = nil
                    return false
                end
                WR_PaladinForever_CrusaderSealPhase = 3
                WR_PaladinForever_CrusaderSealSwitchAt = 0
                WR_PaladinForever_CrusaderSealSwitchBase = WR_PaladinForever_LastSealAppliedAt() or 0
                WR_PaladinForever_CrusaderSealDeadline = now + 15
                phase = 3
            else
                -- 回 phase 1 重试：buff 圣印保持在身上，审判一就绪马上重新提示
                WR_PaladinForever_CrusaderSealPhase = 1
                WR_PaladinForever_CrusaderSealAt = now - 1.0  -- 跳过「等切印生效」的 1 秒
                WR_PaladinForever_CrusaderSealJudgeAt = nil
                WR_PaladinForever_CrusaderSealJudgeBase = nil
                WR_PaladinForever_CrusaderSealDeadline = nil
                phase = 1
            end
        end
    end

    if phase == 3 then
        if backSeal == WR_PaladinForever_CRUSADER_SEAL_NAME then
            -- 切回目标就是十字军圣印（上一次圣印本身）：直接进入维持期，不重复提示上印
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
        -- ★ 2026-11-14 用户口径：能平砍的时候才挂自身圣印（切回也是挂印），
        --   不能平砍就不切，避免目标跑远 / 死亡时空放圣印；能平砍后下一 tick 会自动切回。
        if (now - switchAt) >= 2.0 then
            -- ★ 2026-11-18：显式切回「上一次圣印」（点火前正在用的圣印），不再实时读面板
            WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
            if WR_PaladinForever_ShowSealBlock(backSeal, backSlot) then
                WR_PaladinForever_MarkPrompt(backSeal, backSlot)
                WR_PaladinForever_HideSkillLater(backSeal, backSlot, 1.5)
                WR_PaladinForever_CrusaderSealSwitchAt = now
                return true
            end
        end
    end

    if phase == 4 then
        if not UnitExists("target") or WR_PaladinForever_UnitIsDeadOrGhost("target") then
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
        -- 目标有 debuff 时应保持「上一次圣印」（点火前正在用的圣印）；尚未确认切回则继续提示
        -- ★★ 2026-11-11：上一次圣印就是十字军圣印时无需切回（两者共存），跳过着色提示
        -- ★★★ 2026-11-14：反向确认「切回目标圣印是否已在身上」，读不到不误判（3 秒防抖）。
        -- ★★★ 2026-11-18 用户口径「切回上一次圣印」：切回目标 = 点火时记录的 BackSeal。
        if backSeal ~= WR_PaladinForever_CRUSADER_SEAL_NAME
           and not WR_PaladinForever_JudgementSealOnPlayer(
               backSeal, WR_PaladinForever_LastSealAppliedAt()) then
            local promptAt = WR_PaladinForever_CrusaderSealMaintainPromptAt or 0
            if (now - promptAt) >= 3.0 then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(backSeal, backSlot) then
                    WR_PaladinForever_MarkPrompt(backSeal, backSlot)
                    WR_PaladinForever_HideSkillLater(backSeal, backSlot, 1.5)
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
--   · 目标已有「智慧审判」debuff 时，自动切回「上一次圣印」（点火前正在用的圣印）；
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

    -- ★★★ 2026-11-13 用户口径「勾选后，当目标已死亡且显示为尸体时，仍会切换所选圣印
    --   并尝试释放审判」——状态机总门【尸体不切印】：
    --   目标已确认死亡（含 ghost 态尸体）→ 整条流程直接放弃：重置阶段、本 tick
    --   不点亮任何色块——既不点火切 buff 圣印，也不会卡在 phase1~4 对着尸体空等超时；
    --   常驻圣印由主循环的圣印维持逻辑（CanApplySeal）自行恢复。
    --   口径：只拦【确认死亡】——读不到（secret / API 缺失）一律放行，与射程门一致。
    if WR_PaladinForever_UnitIsDeadOrGhost("target") then
        WR_PaladinForever_ResetWisdomJudgementState()
        return false
    end

    local now = GetTime()
    local phase = WR_PaladinForever_WisdomJudgementPhase or 0
    -- ★★★ 2026-11-13 用户口径「战斗中怪没有在近战位置，打不到也会切审判 buff 对应的圣印，
    --   导致和选择的圣印互顶，浪费了蓝」——状态机总门【打得到才切印】：
    --   切 buff 圣印的唯一目的是「马上打一发审判挂 debuff」。目标不在审判射程（10 码）内时
    --   这一发根本打不出去，切过去只会白顶掉常驻圣印 + 白烧一次切印的蓝，零收益。
    --   ★ 只拦「新点火」（phase 为 nil 或 0）；已进入 phase 1/2/3/4 的流程照常收尾。
    --   ★ 口径与主调度 judgeEligible 的 CanHitTarget 一致：距离读不到（999/secret）→ 放行。
    if phase == 0
       and not WR_PaladinForever_CanHitTarget("审判", "target") then
        return false
    end
    local wisdomName = WR_PaladinForever_WISDOM_SEAL_NAME
    local wisdomSlot = WR_PaladinForever_WISDOM_SEAL_SLOT
    -- ★★★ 2026-11-18 用户口径「切回上一次圣印」：同光明状态机。
    local backSeal = WR_PaladinForever_WisdomJudgementBackSeal or mainSeal
    local backSlot = WR_PaladinForever_WisdomJudgementBackSlot or mainSealSlot

    -- 0 → 首次判定：目标可能已经有智慧审判（例如开关刚打开 / 重载插件）
    if phase == 0 then
        local remain = WR_PaladinForever_WisdomSealDebuffRemain()
        -- ★★★ 2026-11-13（v2）：战斗中目标光环不可读 → 用单审判槽位本地账兜底，
        --   已有智慧审判就别再切智慧圣印重打（避免 phase1 空等 / 白顶常驻圣印）。
        if type(remain) ~= "number" or remain <= 0 then
            local kind, localRemain = WR_PaladinForever_SingleSlotJudgementInfo()
            if kind == "wisdom" then remain = localRemain end
        end
        if type(remain) == "number" and remain > 0 then
            -- ★ 2026-11-18：点火即记录「上一次圣印」（收尾切回用它）
            WR_PaladinForever_WisdomJudgementBackSeal = WR_PaladinForever_WisdomJudgementBackSeal or mainSeal
            WR_PaladinForever_WisdomJudgementBackSlot = WR_PaladinForever_WisdomJudgementBackSlot or mainSealSlot
            WR_PaladinForever_WisdomJudgementPhase = 4
            WR_PaladinForever_WisdomJudgementDebuffUntil = now
                + ((remain >= 900) and WR_PaladinForever_WISDOM_JUDGEMENT_SECONDS
                   or math.min(remain + 0.5, WR_PaladinForever_WISDOM_JUDGEMENT_SECONDS + 1))
            WR_PaladinForever_WisdomJudgementTarget = WR_PaladinForever_JudgementSealTargetKey()
            WR_PaladinForever_WisdomJudgementTargetEpoch = WR_PaladinForever_TargetEpoch or 0
            phase = 4
        end
    end

    if phase == 0 then
        -- ★★ 2026-11-12 用户口径：审判 CD 还有 2 秒以上时不切智慧圣印，
        --   继续维持面板「圣印」专区所选常驻圣印；只有进入「审判剩余 ≤ 2 秒」
        --   窗口（含已就绪）且目标没有智慧审判时，才切智慧圣印去打审判。
        if not WR_PaladinForever_JudgementSwitchDue(WR_PaladinForever_GetJudgeCooldown()) then
            if backSeal ~= wisdomName and WR_PaladinForever_WisdomSealOnPlayer() then
                local promptAt = WR_PaladinForever_WisdomJudgementMaintainPromptAt or 0
                if (now - promptAt) >= 3.0 then
                    WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                    if WR_PaladinForever_ShowSealBlock(backSeal, backSlot) then
                        WR_PaladinForever_MarkPrompt(backSeal, backSlot)
                        WR_PaladinForever_HideSkillLater(backSeal, backSlot, 1.5)
                        WR_PaladinForever_WisdomJudgementMaintainPromptAt = now
                        return true
                    end
                end
            end
            return false
        end
        if not WR_PaladinForever_WisdomSealOnPlayer() then
            -- 需要切智慧圣印：显式切印放行一次
            if WR_PaladinForever_CanApplySeal()
               and WR_PaladinForever_CanPrompt(wisdomName, 1.5) then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(wisdomName, wisdomSlot) then
                    WR_PaladinForever_MarkPrompt(wisdomName, wisdomSlot)
                    WR_PaladinForever_HideSkillLater(wisdomName, wisdomSlot, 1.5)
                    -- ★ 2026-11-18：点火即记录「上一次圣印」（收尾切回用它）
                    WR_PaladinForever_WisdomJudgementBackSeal = WR_PaladinForever_WisdomJudgementBackSeal or mainSeal
                    WR_PaladinForever_WisdomJudgementBackSlot = WR_PaladinForever_WisdomJudgementBackSlot or mainSealSlot
                    WR_PaladinForever_WisdomJudgementPhase = 1
                    WR_PaladinForever_WisdomJudgementAt = now
                    return true
                end
            end
        else
            -- 智慧圣印已在身上 → 直接进入「等待审判」
            -- ★ 2026-11-18：同样记录「上一次圣印」
            WR_PaladinForever_WisdomJudgementBackSeal = WR_PaladinForever_WisdomJudgementBackSeal or mainSeal
            WR_PaladinForever_WisdomJudgementBackSlot = WR_PaladinForever_WisdomJudgementBackSlot or mainSealSlot
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
            -- ★★★ 2026-11-17：审判「真就绪」双通道判定（JudgeTrulyReady），同光明状态机。
            if WR_PaladinForever_JudgeTrulyReady()
               and WR_PaladinForever_CanHitTarget("审判", "target")
               and WR_PaladinForever_JudgementAllowed(WR_PaladinForever_WISDOM_SEAL_NAME, "wisdom") then
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
        if castConfirmed or debuffConfirmed then
            WR_PaladinForever_WisdomJudgementJudgeRetries = 0
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
            WR_PaladinForever_WisdomJudgementTargetEpoch = WR_PaladinForever_TargetEpoch or 0
            WR_PaladinForever_NoteSingleSlotJudgement("wisdom", untilAt)
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
        elseif (now - judgeAt) >= 2.0 then
            -- ★★★ 2026-11-17 用户口径「防骑审判buff维持不灵敏」修复：
            --   2 秒内施放事件与目标光环都没确认 = 审判多半没打出去
            --   （提示时审判实际还在 CD / 被 GCD 吞 / AHK 漏按）。
            --   旧版在这里直接按「提示时刻 + 40 秒」进维持期——审判没打出去时
            --   目标 buff 空窗近 40 秒没人管，正是「维持不灵敏」的主因。
            --   现改为：立即回 phase 1 重试（审判一就绪马上重新提示，1 个 tick 内反应）；
            --   连续 3 次仍无任何确认才按旧兜底记 40 秒并切回常驻，防止全程 secret
            --   读不到施放事件的极端场景死循环。
            local retries = (tonumber(WR_PaladinForever_WisdomJudgementJudgeRetries) or 0) + 1
            WR_PaladinForever_WisdomJudgementJudgeRetries = retries
            if retries >= 3 then
                WR_PaladinForever_WisdomJudgementJudgeRetries = 0
                local untilAt = judgeAt + WR_PaladinForever_WISDOM_JUDGEMENT_SECONDS
                WR_PaladinForever_WisdomJudgementDebuffUntil = untilAt
                WR_PaladinForever_WisdomJudgementTarget = WR_PaladinForever_JudgementSealTargetKey()
                WR_PaladinForever_WisdomJudgementTargetEpoch = WR_PaladinForever_TargetEpoch or 0
                WR_PaladinForever_NoteSingleSlotJudgement("wisdom", untilAt)
                if mainSeal == WR_PaladinForever_WISDOM_SEAL_NAME then
                    WR_PaladinForever_WisdomJudgementPhase = 4
                    WR_PaladinForever_WisdomJudgementSwitchAt = nil
                    WR_PaladinForever_WisdomJudgementSwitchBase = nil
                    WR_PaladinForever_WisdomJudgementDeadline = nil
                    return false
                end
                WR_PaladinForever_WisdomJudgementPhase = 3
                WR_PaladinForever_WisdomJudgementSwitchAt = 0
                WR_PaladinForever_WisdomJudgementSwitchBase = WR_PaladinForever_LastSealAppliedAt() or 0
                WR_PaladinForever_WisdomJudgementDeadline = now + 15
                phase = 3
            else
                -- 回 phase 1 重试：buff 圣印保持在身上，审判一就绪马上重新提示
                WR_PaladinForever_WisdomJudgementPhase = 1
                WR_PaladinForever_WisdomJudgementAt = now - 1.0  -- 跳过「等切印生效」的 1 秒
                WR_PaladinForever_WisdomJudgementJudgeAt = nil
                WR_PaladinForever_WisdomJudgementJudgeBase = nil
                WR_PaladinForever_WisdomJudgementDeadline = nil
                phase = 1
            end
        end
    end

    if phase == 3 then
        if backSeal == WR_PaladinForever_WISDOM_SEAL_NAME then
            -- 切回目标就是智慧圣印（上一次圣印本身）：直接进入维持期，不重复提示上印
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
        -- ★ 2026-11-14 用户口径：能平砍的时候才挂自身圣印（切回也是挂印），
        --   不能平砍就不切，避免目标跑远 / 死亡时空放圣印；能平砍后下一 tick 会自动切回。
        if (now - switchAt) >= 2.0 then
            -- ★ 2026-11-18：显式切回「上一次圣印」（点火前正在用的圣印），不再实时读面板
            WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
            if WR_PaladinForever_ShowSealBlock(backSeal, backSlot) then
                WR_PaladinForever_MarkPrompt(backSeal, backSlot)
                WR_PaladinForever_HideSkillLater(backSeal, backSlot, 1.5)
                WR_PaladinForever_WisdomJudgementSwitchAt = now
                return true
            end
        end
    end

    if phase == 4 then
        if not UnitExists("target") or WR_PaladinForever_UnitIsDeadOrGhost("target") then
            WR_PaladinForever_ResetWisdomJudgementState()
            return false
        end
        local targetKey = WR_PaladinForever_JudgementSealTargetKey()
        local storedKey = WR_PaladinForever_WisdomJudgementTarget
        local storedEpoch = WR_PaladinForever_WisdomJudgementTargetEpoch
        -- ★ 2026-11-15（第二版）：epoch 兜底——两边 key 都读不到（全程 secret）时，
        --   PLAYER_TARGET_CHANGED 的 epoch 仍能检测到换目标，避免把 B 的维持期
        --   错套在切回来的 A 头上（DebuffUntil 是 B 的时间）。
        if (storedKey and targetKey and storedKey ~= targetKey)
            or (type(storedEpoch) == "number" and storedEpoch ~= (WR_PaladinForever_TargetEpoch or 0)) then
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
        -- 目标有 debuff 时应保持「上一次圣印」（点火前正在用的圣印）；尚未确认切回则继续提示
        -- ★★ 2026-11-11：上一次圣印就是智慧圣印时无需切回（两者共存），跳过着色提示
        -- ★★★ 2026-11-14：反向确认「切回目标圣印是否已在身上」，读不到不误判（3 秒防抖）。
        -- ★★★ 2026-11-18 用户口径「切回上一次圣印」：切回目标 = 点火时记录的 BackSeal。
        if backSeal ~= WR_PaladinForever_WISDOM_SEAL_NAME
           and not WR_PaladinForever_JudgementSealOnPlayer(
               backSeal, WR_PaladinForever_LastSealAppliedAt()) then
            local promptAt = WR_PaladinForever_WisdomJudgementMaintainPromptAt or 0
            if (now - promptAt) >= 3.0 then
                WR_PaladinForever_SealSwitchAllowUntil = now + 0.5
                if WR_PaladinForever_ShowSealBlock(backSeal, backSlot) then
                    WR_PaladinForever_MarkPrompt(backSeal, backSlot)
                    WR_PaladinForever_HideSkillLater(backSeal, backSlot, 1.5)
                    WR_PaladinForever_WisdomJudgementMaintainPromptAt = now
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================================
-- ★ 2026-11-16：神圣之盾「目标为我」判定（面板 FH_SZS_TARGETME）
--   当前目标（怪）的目标是否正是玩家本人。
--   UnitIsUnit 可能返回 secret boolean（不能直接比较），此时用 UnitThreatSituation 兜底；任何 API 缺失、
--   目标不是可攻击活体、没有目标或抛错都按「不满足」处理（绝不误放）。
-- ============================================================
function WR_PaladinForever_TargetTargetIsPlayer()
    local okCast, castable = pcall(WR_PaladinForever_TargetCastable, "target")
    if not okCast or castable ~= true then return false end
    local okTT, hasTT = pcall(UnitExists, "targettarget")
    if not okTT then return false end
    -- ★ 2026-11-17 二次加固：即使 issecretvalue 不可用，布尔比较也包在 pcall 里，绝不抛错
    if not WR_PaladinForever_IsSecret(hasTT) then
        local okExists, exists = pcall(function() return hasTT == true end)
        if okExists and exists ~= true then return false end
    end

    -- ① 常规判断：UnitIsUnit("targettarget","player")。
    --   ★ 2026-11-17 修复：Forever 12.x 在副本/战斗限制下这里返回 secret boolean，
    --     旧写法 same == true 会抛 "attempt to compare local same (a secret boolean value)"，
    --     整条防骑循环中断 → 神圣之盾永远不亮。先过滤 secret；普通 boolean 才作为权威结果。
    if UnitIsUnit ~= nil then
        local ok, same = pcall(UnitIsUnit, "targettarget", "player")
        if ok and not WR_PaladinForever_IsSecret(same) then
            -- ★ 2026-11-17 二次加固：比较本身 pcall，secret 布尔即使漏检也不会抛错
            local okCmp, isSame = pcall(function() return same == true end)
            if okCmp then return isSame == true end
        end
    end

    -- ② secret 兜底：UnitThreatSituation 的 2/3 都表示「玩家是该怪的主目标」
    --   （2=主目标但非高威胁，3=主目标且高威胁），等价于怪的目标是玩家本人。
    --   DBM 在 Forever 同样用该 API 代替被 secret 化的 UnitDetailedThreatSituation。
    if UnitThreatSituation ~= nil then
        local okT, status = pcall(UnitThreatSituation, "player", "target")
        if okT and not WR_PaladinForever_IsSecret(status) and type(status) == "number" then
            return status >= 2
        end
    end
    return false
end

-- ============================================================
-- ★ 2026-11-16：防骑「打断」滑块（面板 FH_DD）→ 制裁之锤
--   用户口径：防骑打断滑条目前无效，需要修复；滑条控制制裁之锤用作施法打断。
--   0 = 关闭；5~100 = 目标施法/引导进度达到该百分比时提示制裁之锤（默认 50）。
--   兼容旧布尔存档：true → 50（开启），false → 关闭。
-- ============================================================
function WR_PaladinForever_InterruptThreshold()
    local raw = PigSet and PigSet.FH_DD
    if raw == false then return 0 end
    local thr = tonumber(raw)
    if thr == nil then thr = 50 end
    if thr <= 0 then return 0 end
    if thr > 100 then thr = 100 end
    return thr
end

-- ★ 2026-11-16：Forever 12.x 的 UnitCastingInfo/UnitChannelInfo 时间戳是 secret number，
-- 不能做算术。优先走 DurationObject：UnitCastingDuration / UnitChannelDuration 返回
-- secret-safe 对象，EvaluateElapsedPercent(CurveConstants.ScaleTo100) 在 C 侧算出 0~100
-- 的施法进度；该通道不可用时再退回原始时间戳（经典客户端 / 离线夹具）。
function WR_PaladinForever_DurationCastPercent(unit)
    unit = unit or "target"
    local curve = nil
    if type(CurveConstants) == "table" then curve = CurveConstants.ScaleTo100 end
    if curve == nil and type(C_CurveUtil) == "table" and type(C_CurveUtil.CreateCurve) == "function" then
        local okC, c = pcall(C_CurveUtil.CreateCurve)
        if okC and c ~= nil then
            if type(c.SetType) == "function" and type(Enum) == "table" and Enum.LuaCurveType ~= nil then
                pcall(c.SetType, c, Enum.LuaCurveType.Linear)
            end
            pcall(c.AddPoint, c, 0.0, 0)
            pcall(c.AddPoint, c, 1.0, 100)
            curve = c
        end
    end
    if curve == nil then return nil end
    local function eval(fn)
        if type(fn) ~= "function" then return nil end
        local okD, duration = pcall(fn, unit)
        if not okD or duration == nil then return nil end
        local okE, pct = pcall(function()
            return duration:EvaluateElapsedPercent(curve)
        end)
        if not okE or type(pct) ~= "number" then return nil end
        if WR_IsSecretValue ~= nil then
            local okS, isSecret = pcall(WR_IsSecretValue, pct)
            if okS and isSecret == true then return nil end
        end
        return pct
    end
    local pct = eval(UnitCastingDuration)
    if pct ~= nil then return pct end
    return eval(UnitChannelDuration)
end

-- 目标当前施法 / 引导进度（0~100）；读不到或不可打断返回 nil。
-- 仅作为 WR_ShouldInterrupt 不可用 / 抛错时的兜底；所有 secret 比较都包在 pcall 内。
function WR_PaladinForever_TargetCastProgress()
    -- ① 首选 DurationObject（Forever 12.x 战斗内唯一安全的进度来源）
    local durationPct = WR_PaladinForever_DurationCastPercent("target")
    if type(durationPct) == "number" then return durationPct end
    -- ② 退回原始时间戳（经典客户端 / 离线夹具）
    local now = GetTime()
    local function secret(v)
        if WR_IsSecretValue ~= nil then
            local ok, s = pcall(WR_IsSecretValue, v)
            if ok and s == true then return true end
        end
        return false
    end
    local function calc(startMS, endMS)
        local ok, pct = pcall(function()
            local s = tonumber(startMS)
            local e = tonumber(endMS)
            if type(s) ~= "number" or type(e) ~= "number" or e <= s then return nil end
            local p = (now - s / 1000) / ((e - s) / 1000) * 100
            if p < 0 then p = 0 elseif p > 100 then p = 100 end
            return p
        end)
        if ok then return pct end
        return nil
    end
    if type(UnitCastingInfo) == "function" then
        local ok, name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible = pcall(UnitCastingInfo, "target")
        if ok then
            local usable, pct = pcall(function()
                if name == nil then return nil end
                if secret(name) or secret(notInterruptible) then return nil end
                if notInterruptible == true then return nil end
                return calc(startMS, endMS)
            end)
            if usable and type(pct) == "number" then return pct end
        end
    end
    if type(UnitChannelInfo) == "function" then
        local ok, name, text, texture, startMS, endMS, isTradeSkill, notInterruptible = pcall(UnitChannelInfo, "target")
        if ok then
            local usable, pct = pcall(function()
                if name == nil then return nil end
                if secret(name) or secret(notInterruptible) then return nil end
                if notInterruptible == true then return nil end
                return calc(startMS, endMS)
            end)
            if usable and type(pct) == "number" then return pct end
        end
    end
    return nil
end

-- 制裁之锤实际冷却：基础 60 秒，防护天赋「强化制裁之锤」每级 -5 秒（最多 3 级）。
-- GetTalentRank 由 Core/ZZ_Features_Migration.lua 在职业文件之前加载；查不到按基础 60 秒。
function WR_PaladinForever_HammerCooldown()
    local cd = 60
    if type(GetTalentRank) == "function" then
        local ok, rank = pcall(GetTalentRank, 20487)
        if ok and type(rank) == "number" and rank > 0 then
            if rank > 3 then rank = 3 end
            cd = cd - rank * 5
        end
    end
    return cd
end

function WR_PaladinForever_InterruptStep()
    local threshold = WR_PaladinForever_InterruptThreshold()
    if threshold <= 0 then return false end
    if not WR_PaladinForever_SpellKnown("制裁之锤") then return false end
    -- 技能可用性（蓝量 / 沉默 / 真冷却等）；战斗内 CD 读不到时 WR_SpellUsable 会放行，
    -- 再由 WR_PaladinForever_ShowSkillCD 的本地冷却记账兜底。
    -- ★ 2026-11-18：不能传 GlobalCooldown=true。本文件每 tick 把全局 GCD 设为
    --   WR_GetGCD("审判")（= 审判剩余冷却 0~10 秒），ShiFaSuDu=0.3，于是「true 版」
    --   第三道门 ≈「审判剩余 CD ≤ 0.3 秒」——审判一好就打，几乎整场被拦，
    --   打断滑块形同关闭。与驱邪术/奉献/愤怒之锤同一口径：只查自身冷却。
    if type(WR_SpellUsable) == "function" then
        local okU, usable = pcall(WR_SpellUsable, "制裁之锤")
        if not okU or usable ~= true then return false end
    end
    if not WR_PaladinForever_CanHitTarget("制裁之锤", "target") then return false end

    -- ① 统一打断引擎（Core/InterruptController.lua）：与战士/法师同一口径
    local should = false
    if type(WR_ShouldInterrupt) == "function" then
        local ok, v = pcall(WR_ShouldInterrupt, "target", "FH_DD")
        if ok and v == true then should = true end
    end
    -- ② 引擎不可用 / 抛错时，用本地 UnitCastingInfo / UnitChannelInfo 进度兜底
    if not should then
        local okP, progress = pcall(WR_PaladinForever_TargetCastProgress)
        if okP and type(progress) == "number" then
            local okCmp, passed = pcall(function() return progress >= threshold end)
            if okCmp and passed == true then should = true end
        end
    end
    if not should then return false end

    if type(WR_PaladinForever_ShowSkillCD) == "function" then
        return WR_PaladinForever_ShowSkillCD("制裁之锤", 22, WR_PaladinForever_HammerCooldown())
    end
    return WR_ColorFrame_ShowSkill("制裁之锤", 22) == true
end

-- ============================================================
-- ★★ 2026-11-17：全局保护（自动保护之手）
-- ------------------------------------------------------------
-- 面板「防护 → 全局保护」下拉 saveVariable = FH_ZZBH_HP：
--   1 = 30% / 2 = 40% / 3 = 50% / 4 = 禁用（默认 4）。
-- 语义：团内非坦克队友血量 ≤ 阈值时，自动对其施放「保护之手」（槽位 64）。
-- 实现：复用焦点施法框架 WR_FocusCast —— 先亮对应队伍的「设焦点」色块，
--       下一 tick 焦点已切到该队友后亮 64 号「保护之手」色块；
--       与「指向保护」一次性复选框完全独立（后者走 mouseover 分支）。
-- 注意：保护之手会让目标物理免疫，不能给坦克（会丢仇恨），因此跳过 TANK 职责；
--       自身由防骑自己的圣疗/圣盾处理，也不进入候选。
-- ============================================================
local WR_PROT_GLOBAL_PROTECTION_THRESHOLDS = { 0.30, 0.40, 0.50 }

local function WR_PaladinForever_ProtGlobalProtectionThreshold()
    local v = tonumber(PigSet and PigSet.FH_ZZBH_HP)
    if not v then return nil end
    return WR_PROT_GLOBAL_PROTECTION_THRESHOLDS[v]
end

local WR_PROT_GLOBAL_UNITS_CACHE, WR_PROT_GLOBAL_UNITS_CACHE_KEY
local function WR_PaladinForever_ProtGlobalProtectionGroupUnits()
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    local cacheKey = tostring(raid) .. ":" .. tostring(party)
    if WR_PROT_GLOBAL_UNITS_CACHE and WR_PROT_GLOBAL_UNITS_CACHE_KEY == cacheKey then
        return WR_PROT_GLOBAL_UNITS_CACHE
    end
    local units = {}
    if raid > 0 then
        for i = 1, math.min(raid, 25) do
            units[#units + 1] = "raid" .. i
        end
    elseif party > 0 then
        for i = 1, math.min(party, 4) do
            units[#units + 1] = "party" .. i
        end
    end
    WR_PROT_GLOBAL_UNITS_CACHE = units
    WR_PROT_GLOBAL_UNITS_CACHE_KEY = cacheKey
    return units
end

local function WR_PaladinForever_ProtGlobalProtectionIsTank(unit, index)
    -- 优先按单位 token 查职责；读不到再按序号走仓库既有的 WR_NumIsTank 缓存。
    if type(UnitGroupRolesAssigned) == "function" then
        local okRole, role = pcall(UnitGroupRolesAssigned, unit)
        -- ★★ 2026-11-18：role 在受限上下文里可能是 secret string，
        --   裸 == "TANK" 比较会抛错（EUI EllesmereUI.lua:2333 同款实证：
        --   issecretvalue(role) 时角色不可读）。比较包 pcall，读不到按未知处理。
        if okRole and role ~= nil and not WR_PaladinForever_IsSecret(role) then
            local okT, isTankRole = pcall(function() return role == "TANK" end)
            if okT and isTankRole == true then return true end
            local okOther, isOther = pcall(function() return role == "HEALER" or role == "DAMAGER" end)
            if okOther and isOther == true then return false end
        end
    end
    if index and type(WR_NumIsTank) == "function" then
        local okTank, isTank = pcall(WR_NumIsTank, index)
        if okTank and isTank == true then return true end
    end
    return false
end

local function WR_PaladinForever_ProtGlobalProtectionInRange(unit)
    if type(IsSpellInRange) == "function" then
        local ok, inRange = pcall(IsSpellInRange, "保护之手", unit)
        if ok and type(inRange) == "number" then return inRange == 1 end
    end
    if type(UnitInRange) == "function" then
        local ok, inRange = pcall(UnitInRange, unit)
        if ok and inRange ~= nil then return inRange == true end
    end
    -- 读不到距离时放行（与循环其它射程门一致：读不到不判死）
    return true
end

local function WR_PaladinForever_ProtGlobalProtectionEligible(unit, index, threshold)
    if type(unit) ~= "string" or unit == "" then return false end
    if type(UnitExists) ~= "function" or not UnitExists(unit) then return false end
    -- ★★ 2026-11-18：身份门全部走 secret 安全的布尔收敛（pcall 调用 + pcall 比较）。
    --   旧写法裸真值 / 裸 not 判断：战斗中这些 API 返回 secret boolean 时，
    --   ① 「不确认」被当成「不是」，② 裸 == 比较直接抛错打断整条循环。
    if type(UnitIsUnit) == "function" then
        local okSame, same = pcall(UnitIsUnit, unit, "player")
        if okSame and WR_PaladinForever_SafeBool(same) == true then return false end
    end
    if type(UnitIsDeadOrGhost) == "function" then
        local okDead, dead = pcall(UnitIsDeadOrGhost, unit)
        if okDead and WR_PaladinForever_SafeBool(dead) == true then return false end
    end
    if type(UnitIsPlayer) == "function" then
        local okPlayer, isPlayer = pcall(UnitIsPlayer, unit)
        if okPlayer and WR_PaladinForever_SafeBool(isPlayer) == false then return false end
    end
    if type(UnitIsFriend) == "function" then
        local okFriend, isFriend = pcall(UnitIsFriend, "player", unit)
        if okFriend and WR_PaladinForever_SafeBool(isFriend) == false then return false end
    end
    if WR_PaladinForever_ProtGlobalProtectionIsTank(unit, index) then return false end
    if type(WR_GetUnitBuffTime) == "function" and WR_GetUnitBuffTime(unit, "保护之手") > 1.5 then
        return false
    end
    -- 自律（Forbearance）期间保护之手无法施放，直接跳过避免白按。
    if type(WR_GetUnitDebuffTime) == "function" and WR_GetUnitDebuffTime(unit, "自律") > 0 then
        return false
    end
    local hp = WR_GetUnitHP(unit)
    if type(hp) ~= "number" or hp > threshold then return false end
    if not WR_PaladinForever_ProtGlobalProtectionInRange(unit) then return false end
    return true
end

local function WR_PaladinForever_ProtGlobalProtectionPrompt(unit)
    -- ★ 2026-11-18：UnitIsUnit 在受限上下文里返回 secret boolean，裸真值 / 裸比较
    --   都会失效或抛错，统一走 SafeBool（只认确认 true）。
    local focusIsUnit = false
    if type(UnitIsUnit) == "function" then
        local okSame, same = pcall(UnitIsUnit, "focus", unit)
        focusIsUnit = okSame and WR_PaladinForever_SafeBool(same) == true
    end
    if focusIsUnit then
        -- 已经是焦点：直接亮 64 号技能块，并走 ShowSkillCD 的本地 5 分钟冷却记账，
        -- 避免保护之手冷却中每 tick 重复亮块、AHK 反复空按。
        if type(WR_PaladinForever_ShowSkillCD) == "function" then
            return WR_PaladinForever_ShowSkillCD("保护之手", 64, 300) == true
        end
        if type(WR_ColorFrame_ShowSkill) == "function" then
            return WR_ColorFrame_ShowSkill("保护之手", 64) == true
        end
        return false
    end
    if type(WR_FocusCast) == "function" then
        return WR_FocusCast(unit, 64, "保护之手", "全局保护") == true
    end
    return false
end

function WR_PaladinForever_ProtGlobalProtectionStep()
    local threshold = WR_PaladinForever_ProtGlobalProtectionThreshold()
    if not threshold then return false end
    -- 自动保护只在战斗中生效：脱战低血不浪费 5 分钟保护之手 CD（鼠标指向预读仍走 FH_ZZBH）。
    if type(UnitAffectingCombat) == "function" and not UnitAffectingCombat("player") then return false end
    if not WR_PaladinForever_SpellKnown("保护之手") then return false end
    -- ★ 2026-11-18：去掉 GlobalCooldown=true（同上：全局 GCD 是审判剩余冷却，
    --   传 true 等于「审判不在 CD 才允许保护之手」，会让全局保护几乎永不触发）。
    if type(WR_SpellUsable) == "function" then
        local okUsable, usable = pcall(WR_SpellUsable, "保护之手")
        if not okUsable or usable ~= true then return false end
    end

    local units = WR_PaladinForever_ProtGlobalProtectionGroupUnits()

    -- 当前焦点已经满足条件时，优先把技能打在焦点上，避免每 tick 来回切焦点。
    local focusIndex
    for i = 1, #units do
        if type(UnitIsUnit) == "function" then
            local okSame, same = pcall(UnitIsUnit, "focus", units[i])
            if okSame and WR_PaladinForever_SafeBool(same) == true then
                focusIndex = i
                break
            end
        end
    end
    if focusIndex and WR_PaladinForever_ProtGlobalProtectionEligible("focus", focusIndex, threshold) then
        return WR_PaladinForever_ProtGlobalProtectionPrompt("focus")
    end

    local bestUnit, bestHP
    for i = 1, #units do
        local unit = units[i]
        if WR_PaladinForever_ProtGlobalProtectionEligible(unit, i, threshold) then
            local hp = WR_GetUnitHP(unit)
            if type(hp) == "number" and (bestHP == nil or hp < bestHP) then
                bestUnit, bestHP = unit, hp
            end
        end
    end
    if not bestUnit then return false end
    return WR_PaladinForever_ProtGlobalProtectionPrompt(bestUnit)
end

function WR_PaladinForeverProt()
    WR_PaladinForever_ClearStalePrompts(1.0)
    -- ★★ 2026-11-09 第十一次修正：圣印提示保护窗口。
    --   圣印色块亮起后的保护窗口内（WR_PaladinForever_SEAL_PROMPT_HOLD，
    --   2026-11-14 由 0.3 秒提高到 1.0 秒），本函数会每 tick 重亮同一个圣印并直接返回，
    --   防止「神圣打击」「审判」等下一 tick 的提示把圣印色块顶掉（AHK 读不到 → 不补印）。
    --   ★ 用户口径「上圣印经常被顶，将圣印优先级调高」：该窗口就是圣印的最高优先级闸门，
    --     窗口内任何其它技能分支都不会执行，AHK 必然读到圣印色块。
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
    -- ★★★ 2026-11-14 用户口径：改为「能平砍的时候才挂自身圣印」（CanApplySeal → CanMeleeSwing），
    --   目标是敌对活体且在平砍射程内才允许点亮圣印色块，否则一律空放。
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
        -- ★★ 2026-11-18：身份门 secret 安全（pcall 调用 + pcall 比较，读不到即判否，
        --   一次性开关宁可这次不亮，也不能因为 secret 比较抛错打断整条循环）。
        local mouseoverOK = false
        do
            local okE, exists = pcall(UnitExists, "mouseover")
            if okE and WR_PaladinForever_SafeBool(exists) == true then
                local okP, isPlayer = pcall(UnitIsPlayer, "mouseover")
                local okD, dead = pcall(UnitIsDeadOrGhost, "mouseover")
                local okS, same = pcall(UnitIsUnit, "mouseover", "player")
                mouseoverOK = WR_PaladinForever_SafeBool(isPlayer) == true
                             and WR_PaladinForever_SafeBool(dead) ~= true
                             and WR_PaladinForever_SafeBool(same) ~= true
            end
        end
        if mouseoverOK then
            -- 指向保护（64）/ 指向牺牲（23）/ 指向拯救（35）
            if WR_ProtOneShot("FH_ZZBH", "保护之手", 64) then return true end
            if WR_ProtOneShot("FH_ZZXS", "牺牲之手", 23) then return true end
            if WR_ProtOneShot("FH_ZZJZ", "拯救之手", 35) then return true end
        end
    end

    -- ★★ 2026-11-14：清洁术「优先」模式 + 防护独立「自己/目标」复选框
    --   面板 FH_QJS=2 勾选后走这里，高于圣印维持/生存；复选框则勾选即生效。
    if WR_PaladinForever_CleanseStep("FH_QJS", "priority", "FH_QJS_Player", "FH_QJS_Target") then return true end

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
    -- ★ 2026-11-18：去掉 WR_SpellUsable 的 GlobalCooldown=true（全局 GCD 是审判剩余冷却，
    --   传 true 等于「审判不在 CD 才能自保」，生存分支几乎永不触发）。
    if PlayerHP < 0.20 and WR_SpellUsable("圣疗术") then
        if WR_PaladinForever_ShowSkillCD("圣疗术", 48, 1200) then return true end
    end
    if PlayerHP < 0.35 and WR_SpellUsable("圣佑术") then
        if WR_PaladinForever_ShowSkillCD("圣佑术", 78, 300) then return true end
    end

    -- ★★ 2026-11-17：全局保护（自动保护之手）—— 团内非坦克队友低血救场
    if WR_PaladinForever_ProtGlobalProtectionStep() then return true end

    -- ★★ 2026-11-16：面板「打断」滑块（FH_DD）→ 制裁之锤
    --   0=关闭；5~100=目标施法进度达到该百分比时提示制裁之锤（默认 50）。
    --   放在生存自保之后、清洁术之前：读条打断优先于常规仇恨循环。
    if WR_PaladinForever_InterruptStep() then return true end

    -- ★★ 2026-11-14：清洁术「常规 / 目标 / 指向」模式（生存之后，不抢圣疗/圣盾）
    if WR_PaladinForever_CleanseStep("FH_QJS", "normal", "FH_QJS_Player", "FH_QJS_Target") then return true end

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
    --   ★ 2026-11-16 用户口径：战斗/脱战，只要 Buff 消失了就要立马补——
    --     可读光环缺失 / 观测投影到期都会立刻判缺失，30 分钟施放成功记录
    --     只在完全读不到任何证据时兜底（判定见 Paladin_Forever.lua FuryUp）。
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

    -- 2.6 祝福（2026-11-11：下拉框已删除，改走独立祝福设置列表 + 脱战自动补）
    --   type 保护：离线夹具未加载 Paladin_Blessing.lua 时安全跳过，真实客户端该函数必存在
    if type(WR_PaladinBlessing_Auto) == "function" and WR_PaladinBlessing_Auto() then return true end

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
    --     · HideSkillLater 对圣印统一 1.0 秒（WR_PaladinForever_SEAL_PROMPT_HOLD）
    --       + 成功施放事件立即 HideNow；1.0 秒 < 1.5 秒 GCD，不会连按出第二发。
    --   「何时能亮」仍由 CanApplySeal（战斗中 + 能平砍）决定，脱战绝不点亮。
    -- ============================================================
    -- ★★ 2026-11-11：状态机可能在本 tick 已推进阶段（例如刚从「需要光明」切到
    --   「目标已有 debuff」），补印目标要按最新阶段重新取一次。
    maintainSeal, maintainSealSlot = WR_PaladinForever_ProtSealGoal(mainSeal, mainSealSlot)
    -- ★★★ 2026-11-14：身上明确是另一条可读圣印（如面板选愤怒、身上光明圣印）时，
    --   SealNeedsRefresh 的「任意圣印在身一律不补」会把它挡住 → 永远不切回所选常驻。
    --   这里单独放行「从别的圣印切回面板所选」这一种情况；切回成功后由 30 秒本地
    --   记账和 CanPrompt(maintainSeal, 3) 双重防连按，不会回到反复上印。
    local sealSwitchFromOther = WR_PaladinForever_SealShouldSwitchToMain(maintainSeal)
    local sealAllowed = WR_PaladinForever_SealNeedsRefresh(maintainSeal) or sealSwitchFromOther
    if sealAllowed then
        if sealSwitchFromOther then
            -- 明确是另一条可读圣印：不需要 0.1 秒缺印确认，本 tick 直接切回
            WR_PaladinForever_SealMissingSince = GetTime() - 1.0
        else
            WR_PaladinForever_SealMissingSince = WR_PaladinForever_SealMissingSince or GetTime()
        end
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
            if sealSwitchFromOther then
                -- 明确穿着另一条可读圣印：显式切回常驻，放行 ShowSealBlock 的补印硬闸
                WR_PaladinForever_SealSwitchAllowUntil = GetTime() + 0.5
            end
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
    --   ★★ 2026-11-12 用户口径（切印时机）补充：只有状态机真的占着 buff 圣印
    --     （phase 1/2，或 phase 0 已进入「审判剩余 ≤ 2 秒」窗口）时，主调度才让出审判；
    --     窗口之外的 phase 0 视为「维持常驻圣印」——审判照常由主调度正常打。
    --     否则旧逻辑会让审判被一条还没到窗口的流程长期占住 → 审判反而打不出去。
    local judgeCDForYield = WR_PaladinForever_GetJudgeCooldown()
    local lightWaitingJudge = (PigSet and PigSet.FH_CRGMSY)
        and WR_PaladinForever_BuffSealHolds(WR_PaladinForever_LightSealPhase or 0, judgeCDForYield)
    local crusaderWaitingJudge = (PigSet and PigSet.FH_SZJSP)
        and WR_PaladinForever_BuffSealHolds(WR_PaladinForever_CrusaderSealPhase or 0, judgeCDForYield)
    local wisdomWaitingJudge = (PigSet and PigSet.FH_ZHSP)
        and WR_PaladinForever_BuffSealHolds(WR_PaladinForever_WisdomJudgementPhase or 0, judgeCDForYield)
    local insertSealRunning = (PigSet and PigSet.FH_CRZHSY)
        or lightWaitingJudge or crusaderWaitingJudge or wisdomWaitingJudge
    local judgeCD = judgeCDForYield

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
        -- ★★★ 2026-11-13（v2）：光明圣印 / 智慧审判 buff 维持开关开启、且
        --   常驻圣印本身就是光明/智慧时，主调度不打审判，由状态机独占，避免
        --   主调度按常驻光明/智慧打出一发把状态机刚挂好的另一条审判顶掉。
        -- ★★★ 2026-11-14 用户口径「愤怒和正义不会顶审判buff，要正常打审判」：
        --   常驻是正义/愤怒等不产生审判 debuff 的圣印时，审判不产生审判 debuff，
        --   即使对应 buff 维持开关开着，主调度仍应正常打审判；
        --   状态机只在切印/挂 debuff 的窗口内先 return true 抢占，phase4 维持期放行。
        -- ★★★ 2026-11-18 用户口径「审判buff选十字军、圣印选智慧/光明时不要打审判，
        --   会顶掉审判buff」：防顶掉门补上十字军审判开关 FH_SZJSP——旧门只写了
        --   FH_CRGMSY / FH_ZHSP，十字军审判开关开着、常驻圣印选智慧/光明时，
        --   主调度这一发就是智慧/光明审判，会把状态机刚挂好的十字军审判顶掉。
        --   审判的续挂由十字军状态机独占（切十字军圣印 → 审判 → 切回）；
        --   常驻十字军（同一条审判）与愤怒/正义（不产生审判 debuff）照常打审判。
        and not (PigSet and (PigSet.FH_CRGMSY or PigSet.FH_ZHSP or PigSet.FH_SZJSP)
            and WR_PaladinForever_JudgementUsesSingleSlot(mainSeal))
        -- ★★★ 2026-11-13 用户口径「光明/智慧审判互斥」：本次审判会打光明/智慧审判
        --   （常驻圣印是光明/智慧，或状态机把自己切到光明/智慧）且目标身上已有
        --   光明审判或智慧审判时，这一发审判会顶掉那条 debuff → 不提示审判。
        --   放在 eligible 里（而不是只放 tryJudge 里），单体的 Ready-first 调度
        --   与下面的兜底环节也会自动跟着跳过审判，不会绕道再点亮。
        and WR_PaladinForever_JudgementAllowed(mainSeal)
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
    -- ★★★ 2026-11-18 修复「驱邪术永不点亮」：
    --   旧写法 WR_SpellUsable("驱邪术", true) 的第三道门是
    --   `(GCD or 0.4) <= (ShiFaSuDu or 0.4)`，而本函数的全局 GCD 来自
    --   WR_GetGCD("审判")——它返回的是【审判自己的剩余冷却】（8~10 秒），
    --   不是公共冷却。于是审判一进 CD，驱邪术的可用性恒 false：
    --   单体链每次轮到它都在审判刚打完的 8~10 秒窗口里 → 永远不亮；
    --   多目标链同理（审判之后必然进入该窗口）。
    --   修复：不再把 GlobalCooldown=true 传进来（公共冷却由 ShowSkillCD 的
    --   提示防抖 + 1.5 秒保持窗口兜底），并保留客户端可用性通道作为兜底。
    local exoTypeOK = WR_PaladinForever_IsUndeadOrDemon("target")
    local exoCastable = WR_PaladinForever_TargetCastable("target")
    local exoRangeOK = WR_PaladinForever_InSpellRange("驱邪术", "target")
    -- ★★★ 2026-11-18：参考 PaladinAssist 的 spell 状态（learned/usable/left）。
    --   旧写法即使不传 GlobalCooldown=true，WR_SpellUsable 的第一道门仍拿
    --   全局 GCD（本函数 GCD=WR_GetGCD("审判")，8~10 秒）做比较；统一走共享状态。
    local exoState = nil
    if type(WR_PaladinForever_ExorcismState) == "function" then
        exoState = WR_PaladinForever_ExorcismState()
    end
    local exoUsable
    if type(WR_PaladinForever_ExorcismReady) == "function" then
        exoUsable = WR_PaladinForever_ExorcismReady()
    else
        exoUsable = WR_SpellUsable("驱邪术")
    end
    local exoClientOK = (exoState ~= nil and exoState.usable == true)
    WR_PaladinForever_ExoLastGate = {
        typeOK = exoTypeOK,
        castable = exoCastable,
        range = TargetRange,
        rangeOK = exoRangeOK,
        usable = exoUsable,
        clientOK = exoClientOK,
        learned = exoState and exoState.learned or nil,
        left = exoState and exoState.left or nil,
        gcdVar = GCD,
        shifa = ShiFaSuDu,
        at = GetTime(),
    }
    local exorcismEligible = exoTypeOK and exoCastable and exoRangeOK and exoUsable
    -- 愤怒之锤（斩杀收尾；受面板「愤怒之锤」FH_FNZC 控制，默认开）
    --   ★★ 2026-11-13 用户口径「新增愤怒之锤的使用分支，明确触发条件/冷却/资源限制」：
    --   触发条件（全部满足才点亮）：
    --     ① 面板开关 FH_FNZC（默认勾选，关闭后主链与兜底都不再提示）；
    --     ② 目标进入斩杀期：
    --        · 血量可读（SoD/经典/夹具）→ 目标生命 <20%；
    --        · 血量不可读（Forever 常态，UnitHealth 是 secret）→ 由
    --          C_Spell.IsSpellUsable(愤怒之锤) 判定（该技能仅斩杀期可施放，
    --          客户端可用性即执行期信号，且该返回值不是 secret）；
    --        见 WR_PaladinForever_HammerExecuteReady。
    --     ③ 目标存在/可攻击/存活（TargetCastable，斩杀读条不打尸体）；
    --     ④ 30 码射程（WR_PaladinForever_SPELL_RANGE["愤怒之锤"]=30，
    --        近战位丢失/卡位时 30 码内仍能收尾）；
    --     ⑤ 已学会 + 冷却就绪（C_Spell.IsSpellUsable / WR_SpellUsable）；
    --     ⑥ 蓝量 ≥20%（WR_PaladinForever_PROT_HOW_MANA_MIN，资源下限见常量区说明）。
    --   冷却：本地 6 秒记账（ShowSkillCD 三层判定：① 成功施放 +6 秒 →
    --     ② 客户端冷却 → ③ 提示保持窗口兜底，与其它循环技能一致）。
    --   优先级衔接：多目标链插在 审判 之后、神圣打击 之前；单体链插在
    --     Ready-first 之后、驱邪术 之前；原第 11 档兜底保留并同样受开关控制。
    -- ★★★ 2026-11-14 修复：不再直接写 `WR_SafeHPPct("target") < 0.20`。
    --   本服 UnitHealth 恒为 secret → WR_SafeHPPct 恒 1（满血），该门永远不成立，
    --   愤怒之锤从未点亮过。改为统一走 WR_PaladinForever_HammerExecuteReady：
    --   血量可读走 <20%，血量不可读走 C_Spell.IsSpellUsable（执行期信号，非 secret）。
    local hammerEligible = (PigSet == nil or PigSet.FH_FNZC ~= false)
        and WR_PaladinForever_HammerExecuteReady()
        and WR_SpellUsable("愤怒之锤")   -- ★ 2026-11-18：去掉误用审判剩余冷却的 GCD 门（见驱邪术注释）
        and WR_PaladinForever_TargetCastable("target")
        and WR_PaladinForever_CanHitTarget("愤怒之锤", "target")
        and WR_PaladinForever_HammerTargetAllowed("target")   -- ★ 2026-11-14：「精英」开关开启时只打精英/BOSS
        and PlayerMP >= WR_PaladinForever_PROT_HOW_MANA_MIN
    -- 神圣之盾（防护核心减伤；受面板 FH_SZS 开关控制，默认开）
    --   ★ 自身 Buff 类技能，不判射程、也不要求敌方目标（防骑要能给自己套盾）。
    --   ★★ 2026-11-16 用户新增「目标为我」开关 FH_SZS_TARGETME：
    --     勾选后只有当前目标（怪）的目标是玩家本人时才提示；
    --     目标不是自己 / 无目标 / 目标的目标读不到 → 一律不提示。
    local holyShieldEligible = (PigSet == nil or PigSet.FH_SZS ~= false)
        and WR_PaladinForever_SpellKnown("神圣之盾")
        and (PigSet == nil or PigSet.FH_SZS_TARGETME ~= true
             or WR_PaladinForever_TargetTargetIsPlayer())
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
        and WR_SpellUsable("奉献")   -- ★ 2026-11-18：同上，避免被审判剩余冷却误挡

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
        -- ★★ 2026-11-18 复核（用户口径「普通怪也亮驱邪术」回归）：
        --   exorcismEligible 是 tick 开头算的快照；tryExorcism 是唯一点亮入口，
        --   这里每 tick 复核一次类型门，绝不把「技能可用」当类型证据。
        --   类型明确不是亡灵/恶魔 → 一票否决；未知（全 secret）→ 维持
        --   exorcismEligible 的通道④口径，交给调用方决定。
        local okType, typeOK = pcall(WR_PaladinForever_IsUndeadOrDemon, "target")
        if okType and typeOK == false then return false end
        if not WR_PaladinForever_CanHitTarget("驱邪术", "target") then return false end
        return WR_PaladinForever_ShowSkillCD("驱邪术", 20, 15)
    end
    local function tryHammer()
        if not hammerEligible then return false end
        if not WR_PaladinForever_CanHitTarget("愤怒之锤", "target") then return false end
        return WR_PaladinForever_ShowSkillCD("愤怒之锤", 1, 6)
    end
    local function tryHolyShield()
        if not holyShieldEligible then return false end
        return WR_PaladinForever_ShowSkillCD("神圣之盾", 24, 10)
    end

    -- ★★★ 2026-11-13：愤怒之锤 0.87 秒读条保护（读条不被自己人打断）。
    --   WR_ColorFrame_ShowSkill 会先隐藏所有色块：读条期间只要任何环节点亮
    --   别的技能，AHK 按下新按键 = 打断愤怒之锤读条 → 白烧 295 蓝零收益。
    --   处理：点亮后的 PROMPT_HOLD（1.5 秒 ≥ 0.87 秒读条 + GCD）窗口内，
    --   两条主链整体让路——只尝试重亮愤怒之锤自身（读条中 ShowSkillCD 按防抖
    --   返回 false，色块由 HideSkillLater 保持常亮），窗口走完或施放成功
    --   （成功事件 HideNow + 6 秒本地 CD 记账）后自动恢复常规调度。
    --   与单体「神圣打击提示保持窗口不让审判抢块」同一处理模式（见下方方案 2）。
    local hammerHolding = WR_PaladinForever_PromptCD["愤怒之锤"] ~= nil
        and (GetTime() - WR_PaladinForever_PromptCD["愤怒之锤"])
            < (WR_PaladinForever_PROMPT_HOLD or 1.5)
    if hammerHolding then
        if tryHammer() then return true end
        return false
    end

    if aoeMode then
        -- ★ 多目标：严格按用户指定顺序，不做 Ready-first 重排
        -- ★★ 2026-11-10 用户口径「奉献改为3目标使用」：2 个目标不铺奉献，从审判开始。
        if tryConsecrate(3) then return true end
        if tryJudge() then return true end
        -- ★★★ 2026-11-13：愤怒之锤（<20% 斩杀）插在审判之后、神圣打击之前：
        --   审判仍是仇恨/嘲讽 backbone 第一位；目标进入斩杀线后，6 秒 CD 的
        --   愤怒之锤尽快打出，加快击杀、减少小怪存活期间的输出窗口；
        --   目标 ≥20% 时本分支整体跳过，多目标链行为与改动前完全一致。
        if tryHammer() then return true end
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

        -- 7.5 愤怒之锤（<20% 斩杀；本地 6 秒 CD）
        --   ★ 2026-11-13 单体链衔接：方案 2 的「神圣打击 CD 好了永远优先」不动
        --     （上面已先试），审判/神圣打击 Ready-first 也不动；愤怒之锤插在
        --     它们之后、驱邪术之前——两个填充技能都在 CD 的间隙里尽快斩杀收尾，
        --     30 码射程在近战位丢失时也够得着。
        if tryHammer() then return true end

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

    -- 11. 愤怒之锤兜底（<20% 斩杀；本地 6 秒 CD）
    --   ★★ 2026-11-13：已接入上面两条主链（多目标：审判之后；单体：Ready-first
    --     之后、驱邪术之前）。这里保留为最后兜底——两条链全部不可用时
    --     （例如插入流程占住审判、目标超近战位等）仍能完成斩杀收尾；
    --     触发条件与主链完全一致（hammerEligible，含 FH_FNZC 开关/血量/射程/蓝量）。
    if hammerEligible then
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
