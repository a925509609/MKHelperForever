-- ============================================================
-- Mage Forever · Frost 专精循环（2026-11-12 按 Forever 冰霜天赋树重写）
-- ------------------------------------------------------------
-- ★ 权威数据源：https://talentsforever.com/export/mage.json
--   （直接从 Forever 客户端数据文件导出，build 1.60.1.70755）
--
-- ★★ Forever 冰霜天赋树共 18 条，其中【只有 4 条是主动技能】(passive=false)：
--   · 冰枪术 Ice Lance    r3c3  45 Mana | 30 yd | 瞬发 | 8 秒 CD
--       "Deals 28 to 32 Frost damage to an enemy target.
--        Deals 300% increased damage to Frozen targets."
--   · 寒冰屏障 Ice Block   r4c2  15 Mana | 瞬发 | 5 分钟 CD（保命，期间无法行动）
--   · 急速冷却 Cold Snap   r5c2  瞬发 | 10 分钟 CD（结束其它冰霜法术的剩余 CD）
--   · 寒冰护盾 Ice Barrier r7c2  305 Mana | 瞬发 | 30 秒 CD
--       "吸收伤害 + 冰霜伤害 +15%，持续 1 分钟；护盾期间额外 +5% 且不被打断"
--   其余 14 条全部 passive=true，只作判定条件，绝不进优先级链：
--     Frost Warding / Improved Frostbolt / Precision / Ice Shards / Frostbite /
--     Improved Frost Nova / Permafrost / Frost Channeling / Improved Blizzard /
--     Arctic Reach / Shatter / Improved Cone of Cold / Fingers of Frost /
--     Winter's Chill
--   法术书（Frost 页）里的主动技能另含：寒冰箭 / 暴风雪 / 冰锥术 / 冰霜新星 /
--   霜甲术 / 冰甲术 / 防护冰霜结界。
--
-- ★★★ 原实现的三处硬伤（本次修复）：
--   1) 冰枪术被当成「无 CD 技能」无条件排第一 —— 判断写成 `(fofProc or true)`，
--      恒为真。本服冰枪术带 8 秒 CD；而 Forever 战斗中 GetSpellCooldown 是
--      secret、WR_GetGCD 被收敛成 0 → WR_SpellUsable 恒 true → 每 tick 都点亮
--      冰枪术色块（44 号槽）→ AHK 连按 → 冰枪术在 CD 中一直施放失败，
--      整条循环永远卡在第一行，寒冰箭 / 暴风雪 / 冰锥术一次都轮不到。
--   2) 「冰冷之血」(Icy Veins) 在 Forever 冰霜树里【根本不存在】—— 那是 SoD
--      腿符文；而且 WR_SkillColor 给它分的 4 号槽在本服绑的是 /CAST 活动炸弹。
--      已整条删除。
--   3) 寒冰屏障 / 急速冷却 / 寒冰护盾 分别点亮 304 / 305 / 306 号槽，而
--      Core/UI_ColorFrame.lua 的 ColorTable 只到 240 —— WR_Frame_Color[304]
--      是 nil，PIG_BGRtoBGR(nil) 会直接抛错。现在改回 Mage_Macros.lua 里
--      真实绑定宏的 32 / 63 / 65 号槽（宏分别是 /cast 寒冰屏障、急速冷却、寒冰护体）。
--
-- ★ 本地冷却记账（与 Paladin_Forever.lua 同一套已验证做法）：
--   本服战斗中读不到客户端 CD，因此以「UNIT_SPELLCAST_SUCCEEDED 的成功施放
--   时刻」为唯一起点，按技能名 + 全部 rank spellID 双通道记账；提示前先过
--   本地 CD 判定，再叠加「提示防抖」与「色块保持」两道闸，避免 AHK 同色连按。
--
-- ★★★ 2026-11-13 二次核对（NGA 攻略《[无限服] AFK回归，浅析无限服法师
--   天赋与升级天赋分享》，7 页纯图片版，逐页渲染后逐条人工核对）：
--   权威数据仍以 mage.json 为准，攻略只作交叉验证，二者没有冲突：
--     · 冰枪术「对冻结目标伤害提高 300%」+「新增 8sCD」→ 与 CD 表一致 ✓
--     · 寒冰指（等级 2/2，下 2 次法术视为冻结，15 秒）→ 触发判定见下 ✓
--     · 寒冰护体列入核心天赋改动、要求「注意冰盾的保持」→ 补 buff 链 ✓
--     · 强化冰锥术 +35% / 深冬之寒让冰锥术再 +20% → 冰锥术应进单体循环 ✓
--     · 冰霜新星用来「提供冰冻效果增加清怪效率」→ 开碎裂窗口 ✓
--     · 「三系输出循环都有一定复杂度，不存在一个技能搓到底」→ 多分支链 ✓
--   据此落地两处修正：① Fingers of Frost 名称兼容；② 冰锥术单体收尾。
-- ============================================================

-- ============================================================
-- 一、常量表：CD / 槽位 / 蓝量下限 / 冻结判定 / rank-ID 反查
-- ============================================================

-- ★ 本服各主动技能真实 CD（秒）。0 = 无 CD（可每 tick 提示）。
WR_MageFrost_CD = {
    ["冰枪术"]   = 8,    -- 天赋主动，8 秒 CD（不是无 CD！）
    ["冰锥术"]   = 10,   -- 法术书：Instant | 10 sec cooldown
    ["冰霜新星"] = 25,   -- 法术书：Instant | 25 sec cooldown
    ["寒冰护体"] = 30,   -- 天赋主动 Ice Barrier：Instant | 30 sec cooldown
    ["寒冰屏障"] = 300,  -- 天赋主动 Ice Block：Instant | 5 min cooldown
    ["急速冷却"] = 600,  -- 天赋主动 Cold Snap：Instant | 10 min cooldown
    ["唤醒"]     = 480,  -- 8 分钟引导
    ["寒冰箭"]   = 0,
    ["暴风雪"]   = 0,
}

-- ★ 色块槽位（回退值；实际优先取 Mage_Macros.lua 的 WR_SkillColor["MAGE"]）。
--   注释里是该槽位在 Mage_Macros.lua 中绑定的宏，便于人工核对。
-- ★★ 每个槽位都必须同时满足两个条件，否则绝不能点亮：
--   (a) Core/UI_ColorFrame.lua 的 ColorTable 里有这个 key（只有 1..240）；
--       缺 key 时 WR_CreateSingleColorSlot 会拿 nil 去 PIG_BGRtoBGR 里做算术 → 直接抛错。
--   (b) Mage_Macros.lua 里这个槽位确实绑定了本技能的宏；
--       否则 AHK 读到该颜色会去按一个完全无关的技能。
--   核对结果（逐条 grep 过 Mage_Macros.lua）：
--     60 CTRL-F10 /cast 寒冰箭        ✓
--     44 SHIFT-F11 /cast [target=mouseover] 冰枪术 ✓
--     27 ALT-NUMPAD7 /cast 冰锥术      ✓
--     26 ALT-NUMPAD6 /cast [target=cursor] 暴风雪 ✓
--     11 CTRL-NUMPAD1 /cast 冰霜新星   ✓
--     65 ALT-CTRL-F5 /cast 寒冰护体    ✓（本服 Ice Barrier 客户端名，见下）
--     32 ALT-CTRL-NUMPAD2 /cast 寒冰屏障 ✓
--     63 ALT-CTRL-F3 /cast 急速冷却    ✓
--     18 CTRL-NUMPAD8 /cast 唤醒       ✓
--   ★ 已剔除「魔爆术 = 75」：Mage_Macros.lua 里【没有】任何宏绑魔爆术，
--     而 75 号槽实际绑的是 `/petautocaston 水箭` —— 点亮它会让 AHK 去开关
--     水元素自动施法，而不是打魔爆术。既然没有宏能真正放出这个技能，
--     就不该让它进优先级（本服法师也没有稳定的近身 AOE 需求）。
WR_MageFrost_SLOT = {
    ["寒冰箭"]   = 60,   -- CTRL-F10        /cast 寒冰箭
    ["冰枪术"]   = 44,   -- SHIFT-F11       /cast [target=mouseover] 冰枪术
    ["冰锥术"]   = 27,   -- ALT-NUMPAD7     /cast 冰锥术
    ["暴风雪"]   = 26,   -- ALT-NUMPAD6     /cast [target=cursor] 暴风雪
    ["冰霜新星"] = 11,   -- CTRL-NUMPAD1    /cast 冰霜新星
    ["寒冰护体"] = 65,   -- ALT-CTRL-F5     /cast 寒冰护体
    ["寒冰屏障"] = 32,   -- ALT-CTRL-NUMPAD2 /cast 寒冰屏障
    ["急速冷却"] = 63,   -- ALT-CTRL-F3     /cast 急速冷却
    ["唤醒"]     = 18,   -- CTRL-NUMPAD8    /cast 唤醒
}

-- ★ 槽位合法性表：只允许 ColorTable 里真实存在的 key（1..240 且非 nil）
--   加载时按 UI_ColorFrame.lua 的 ColorTable 长度建一次；拿不到时按 240 上限兜底。
WR_MageFrost_SLOT_MAX = WR_MageFrost_SLOT_MAX or 240

function WR_MageFrost_SlotUsable(slot)
    if type(slot) ~= "number" then return false end
    if slot < 1 or slot > (WR_MageFrost_SLOT_MAX or 240) then return false end
    -- 有 ColorTable 引用时精确校验 key 是否存在（防止 1..240 之间有空洞）
    if type(WR_Frame_Color) == "table" and WR_Frame_Color[slot] == nil then
        return false
    end
    return true
end

-- ★ 蓝量下限（法力百分比）。低于该值时不提示该技能。
WR_MageFrost_MANA_FLOOR = {
    ["暴风雪"]   = 0.25,
    ["寒冰护体"] = 0.20,
    ["冰锥术"]   = 0.15,
    ["寒冰箭"]   = 0.08,
    ["冰枪术"]   = 0.05,
    ["冰霜新星"] = 0.05,
}

-- ★ 「目标处于冻结状态」的 debuff 名候选。
--   Forever 里能造成 Freeze 的来源：冰霜新星（直接冻结）、Frostbite 天赋
--   （Chill 效果有 15% 概率 Freeze 5 秒）、以及其它冰系控制。
--   名字读不到时按「未冻结」处理（保守：冰枪术留给真正的碎裂窗口）。
WR_MageFrost_FROZEN_DEBUFFS = {
    "冻结", "冰冻", "冰霜新星", "霜寒刺骨", "Frostbite", "Frozen",
}

-- ★ Fingers of Frost（r5c3，被动天赋）触发判定。
--   效果：Chill 效果有 15% 概率获得「寒冰指」，使下 2 次法术把目标视为已
--   Frozen，持续 15 秒（NGA 攻略 P2 天赋截图：等级 2/2）。有它时冰枪术按冻结处理。
-- ★★ 2026-11-13 名称兼容（攻略核对修正①）：
--   同一条天赋/光环在不同数据源里中文名不一致：
--     · NGA 攻略截图、游戏内 tooltip →「寒冰指」
--     · Data/Forever_Abilities.lua 的 zh、Core/SoD_Runes.lua →「冰霜之指」
--     · 英文客户端 → "Fingers of Frost"
--   只查单一名字时，若客户端实际用另一个名字，FoF 触发永远读不到 →
--   冰枪术碎裂窗口全部丢失（不掉血、不报错，最难查的一类静默 bug）。
--   故改为候选名列表，任一命中即视为触发；仓库既有名字放第一，原行为零回归。
WR_MageFrost_FOF_BUFFS = { "冰霜之指", "寒冰指", "Fingers of Frost" }
-- 兼容别名：保留旧全局名，避免其它模块按旧名引用时拿到 nil。
WR_MageFrost_FOF_BUFF = WR_MageFrost_FOF_BUFFS[1]

-- ★ 需要「已学会」才能提示的技能。
--   Forever 冰霜天赋树里的 4 条主动技能都是【天赋】而非天生技能：
--     冰枪术 r3c3 / 寒冰屏障 r4c2 / 急速冷却 r5c2 / 寒冰护体 r7c2
--   没点天赋就点亮色块 → AHK 按了也放不出来 → 色块常亮、AHK 连按空键。
--   寒冰箭 / 暴风雪 / 冰锥术 / 冰霜新星 是法术书基础技能（1 级起逐级学），
--   WR_SpellUsable 自身已带缺失闸门，故不再重复判。
WR_MageFrost_KNOWN_GATE = {
    ["冰枪术"]   = true,
    ["寒冰屏障"] = true,
    ["急速冷却"] = true,
    ["寒冰护体"] = true,
}

-- ★ 提示防抖（秒）：同一「带 CD 的技能」两次点亮之间的最小间隔。
WR_MageFrost_PROMPT_DEBOUNCE = 0.4
-- ★ 色块保持（秒）：点亮后认为「刚刚亮过」的时长上限。
WR_MageFrost_PROMPT_HOLD = 1.5

-- ★ 技能名 → 全部 rank spellID（战斗中 UNIT_SPELLCAST_SUCCEEDED 的
--   spellName 可能是 secret 字符串，只能靠 spellID 记账）。
--   数据来源：mage.json 的 spell_desc / spellbook.levels。
WR_MageFrost_RANK_IDS = {
    ["寒冰箭"]   = { 116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304 },
    ["冰枪术"]   = { 1312002, 400640, 1240044, 1240045, 1240046, 1240047 },
    ["暴风雪"]   = { 10, 6141, 8427, 10185, 10186, 10187 },
    ["冰锥术"]   = { 120, 8492, 10159, 10160 },
    ["冰霜新星"] = { 122, 865, 6131, 10230 },
    ["寒冰屏障"] = { 11958 },
    ["急速冷却"] = { 12472 },
    -- ★ 寒冰护体 = Ice Barrier（Forever 客户端里这条技能的中文名是「寒冰护体」，
    --   Mage_Macros.lua 的 65 号槽宏也是 `/cast 寒冰护体`；
    --   注意 Data/Forever_Abilities.lua 的 zh 字段写的是「寒冰护盾」，两者是同一个
    --   spellID 系列，这里用客户端真实名字，避免 WR_SpellUsable 解析不到）。
    ["寒冰护体"] = { 11426, 13031, 13032, 13033 },
    ["唤醒"]     = { 12051 },
}

-- spellID → 技能基础名（反查表，加载时一次性建好）
WR_MageFrost_ID_NAME = WR_MageFrost_ID_NAME or {}
do
    for nm, ids in pairs(WR_MageFrost_RANK_IDS) do
        for i = 1, #ids do
            WR_MageFrost_ID_NAME[ids[i]] = nm
        end
    end
end

-- ============================================================
-- 二、本地冷却记账状态
-- ============================================================
-- CastAt[技能名] = 最近一次「成功施放」时刻（本地 CD 判定的唯一依据）
WR_MageFrost_CastAt = WR_MageFrost_CastAt or {}
-- CastAtByID[spellID] = 同上，按 rank ID 冗余一份
WR_MageFrost_CastAtByID = WR_MageFrost_CastAtByID or {}
-- PromptCD[技能名] = 最近一次「点亮色块」时刻（提示防抖）
WR_MageFrost_PromptCD = WR_MageFrost_PromptCD or {}
-- PromptSlot[技能名] = 该技能实际使用的槽位
WR_MageFrost_PromptSlot = WR_MageFrost_PromptSlot or {}
-- HoldUntil[技能名] = 色块保持截止时刻
WR_MageFrost_HoldUntil = WR_MageFrost_HoldUntil or {}

-- ★ 去掉光环/技能名可能带的「（等级 N）」后缀（全角 + 半角两种）
--   注意：Lua 5.1 的字符类按字节匹配，[（(] 这种写法不生效，
--   所以必须分两次 gsub（与 Paladin_Forever.lua 的做法一致）。
function WR_MageFrost_StripRankSuffix(nm)
    if type(nm) ~= "string" then return nil end
    local s = string.gsub(nm, "%s*（等级%s*%d+）%s*$", "")
    if s == nm then
        s = string.gsub(nm, "%s*%(等级%s*%d+%)%s*$", "")
    end
    return s
end

-- ============================================================
-- 三、成功施放记账（UNIT_SPELLCAST_SUCCEEDED）
-- ------------------------------------------------------------
-- 本服战斗中事件里的 spellName / spellID 都可能读不到，所以两条通道都写：
--   · 数字 spellID 通道（主通道，一定有起点）
--   · 名字通道（事件自带名字优先，其次用 ID 反查基础名）
-- ============================================================
function WR_MageFrost_NoteCast(spellName, spellID, at)
    local now = at or GetTime()
    local sid = tonumber(spellID)

    -- ① 主通道：数字 ID
    if sid and sid > 0 then
        WR_MageFrost_CastAtByID[sid] = now
        -- 同时按 ID 反查到的名字记一笔（事件名字是 secret 时全靠这条）
        local byId = WR_MageFrost_ID_NAME[sid]
        if byId then WR_MageFrost_CastAt[byId] = now end
    end

    -- ② 名字通道
    local nm = WR_MageFrost_StripRankSuffix(spellName)
    if type(nm) == "string" and nm ~= "" and WR_MageFrost_CD[nm] ~= nil then
        WR_MageFrost_CastAt[nm] = now
    end
end

-- 取某技能最近一次成功施放时刻（名字 + 全部 rank ID 取较晚者）
function WR_MageFrost_LastCastAt(spell)
    local best = WR_MageFrost_CastAt[spell]
    local ids = WR_MageFrost_RANK_IDS[spell]
    if ids then
        for i = 1, #ids do
            local t = WR_MageFrost_CastAtByID[ids[i]]
            if t and (not best or t > best) then best = t end
        end
    end
    return best
end

-- 客户端剩余冷却（脱战可读；战斗中通常是 secret → 返回 nil）
function WR_MageFrost_ClientCDLeft(spell)
    if type(WR_SpellCooldownInfo) ~= "function" then return nil end
    local sid
    if type(WR_ResolveSpellID) == "function" then
        local ok, v = pcall(WR_ResolveSpellID, spell)
        if ok and type(v) == "number" then sid = v end
    end
    if not sid then
        local ids = WR_MageFrost_RANK_IDS[spell]
        if ids and #ids > 0 then sid = ids[#ids] end
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

-- ★ 技能是否「本地 CD 已就绪」
--   ① 有成功施放记录 → 按「施放时刻 + CD」判定（最准）
--   ② 无记录但客户端剩余冷却可读 → 按客户端判定
--   ③ 两者都没有 → 视为就绪（CD 未知，不能凭猜屏蔽，否则永远不提示）
function WR_MageFrost_Ready(spell)
    local cd = WR_MageFrost_CD[spell]
    if not cd or cd <= 0 then return true end
    local now = GetTime()
    local castAt = WR_MageFrost_LastCastAt(spell)
    if castAt then
        return (now - castAt) >= cd
    end
    local clientLeft = WR_MageFrost_ClientCDLeft(spell)
    if clientLeft and clientLeft > 0 then return false end
    return true
end

-- ============================================================
-- 四、点亮色块（提示防抖 + 保持标记）
-- ------------------------------------------------------------
-- ★ 2026-11-13 OA 审查更正：HoldUntil 目前只在 Show 里写、HideNow 里清，
--   全文没有按「到期」读取并自动熄灭的逻辑。真正的熄灭靠
--   WR_ColorFrame_ShowSkill 的「隐藏全部 → 显示一个」以及 ClearPrompts()。
--   故标题不再宣称「保持到期自动熄灭」，避免误导后续维护者（11-12 遗留）。
-- 带 CD 的技能：本地 CD 未就绪 / 防抖窗口内 → 不点亮。
-- 无 CD 的填充技能（寒冰箭）：不做 CD 判定，但同样过防抖，
--   保证「同一 tick 内不会重复点亮同一技能」。
-- ============================================================
function WR_MageFrost_HideNow(spell)
    local key = tostring(spell)
    WR_MageFrost_HoldUntil[key] = nil
    local slot = WR_MageFrost_PromptSlot[spell]
    if slot then
        if ColorFrameArrayTopLeft and ColorFrameArrayTopLeft[slot] then
            ColorFrameArrayTopLeft[slot]:Hide()
        end
        if ColorFrameArrayTopRight and ColorFrameArrayTopRight[slot] then
            ColorFrameArrayTopRight[slot]:Hide()
        end
    end
end

-- ★★ 2026-11-12：熄灭本循环点亮过的【全部】色块。
-- 背景：WR_ColorFrame_Show 每次成功点亮都会「隐藏全部 → 显示一个」，所以战斗中
--   每 tick 自然覆盖旧色块；但当整条链返回 false（脱战 / 超射程 / 无目标）时，
--   没有任何 Show 调用，上一 tick 的色块会一直常亮。AHK 是「同色常亮就一直按」，
--   于是脱战后仍在按寒冰箭键（甚至可能在防ADD开的情况下自动开怪）。
-- 做法：只按 WR_MageFrost_PromptSlot 里记录的槽位精确 Hide，不碰焦点/跟随/BOSS
--   等其它系统的色块；同时清掉 HoldUntil，让下一轮重新进战时干净起步。
-- ★ 只在「确认不该输出」的 return false 路径调用，绝不在防抖空窗(return true)调用
--   —— 后者正是要靠色块常亮让 AHK 连按打寒冰箭。
function WR_MageFrost_ClearPrompts()
    if type(WR_MageFrost_PromptSlot) == "table" then
        for spell, slot in pairs(WR_MageFrost_PromptSlot) do
            WR_MageFrost_HideNow(spell)
        end
    end
    -- 顺带清掉防抖计时：下一轮重新进战时不残留 0.4s 空窗，能立刻点亮。
    WR_MageFrost_PromptCD = {}
end

function WR_MageFrost_Show(spell, slot)
    local now = GetTime()
    local key = tostring(spell)
    local useSlot = slot or WR_MageFrost_SLOT[spell]

    -- ⓪ 槽位合法性闸：ColorTable 里没有的 key 绝不放行
    --    （否则 WR_CreateSingleColorSlot 会拿 nil 进 PIG_BGRtoBGR 做算术 → 抛错）
    if not WR_MageFrost_SlotUsable(useSlot) then return false end

    -- ① 已学会闸：没学会的技能不能提示（否则色块常亮、AHK 一直按空键）
    --    Forever 冰霜天赋里的主动技能（冰枪术 r3c3 / 寒冰屏障 r4c2 /
    --    急速冷却 r5c2 / 寒冰护体 r7c2）都要点天赋才有，不是天生就会。
    -- ★ 这里统一用 pcall 而不是 `type(f) == "function"` 守卫：
    --   pcall 对 nil / 任何可调用对象都安全，而 type() 守卫会漏掉
    --   C 侧导出的 callable（离线夹具里尤其明显）。
    if WR_MageFrost_KNOWN_GATE[spell] then
        local known = false
        local ok, v = pcall(WR_Forever_IsSpellKnown, spell)
        if ok and v == true then known = true end
        if not known then
            -- 兜底：WR_SpellUsable 内含 WR_Forever_SkillAbsent 缺失闸门
            local ok2, v2 = pcall(WR_SpellUsable, spell)
            if ok2 and v2 == true then known = true end
        end
        if not known then return false end
    end

    -- ② 本地 CD 闸
    if not WR_MageFrost_Ready(spell) then return false end

    -- ③ 提示防抖闸：同一技能在防抖窗口内不重复点亮
    local lastPrompt = WR_MageFrost_PromptCD[key]
    if lastPrompt and (now - lastPrompt) < WR_MageFrost_PROMPT_DEBOUNCE then
        return false
    end

    -- ④ 蓝量闸
    -- ★★★ 2026-11-12 用户口径「技能不够蓝释放时，应当不亮色块，导致一直按按键」：
    --   旧写法只 return false，上一 tick 亮着的色块不会消失 → AHK 读到同色继续按。
    --   现在拦下时顺手熄灭该技能自己的槽位（两侧 + 技能图标框）。
    local mp = WR_GetUnitMP("player")
    if type(mp) == "number" then
        local floor = WR_MageFrost_MANA_FLOOR[spell] or 0.05
        if mp < floor then
            -- 用 pcall 探测（不用 type()=="function"：本仓库夹具里是 userdata）
            if WR_HideSkillColorSlot ~= nil then
                pcall(WR_HideSkillColorSlot, spell, useSlot)
            end
            return false
        end
    end

    if WR_ColorFrame_ShowSkill(spell, useSlot) then
        WR_MageFrost_PromptCD[key] = now
        WR_MageFrost_PromptSlot[spell] = useSlot
        WR_MageFrost_HoldUntil[key] = now + WR_MageFrost_PROMPT_HOLD
        return true
    end
    return false
end

-- ============================================================
-- 五、事件接线：成功施放 → 记账
-- ============================================================
if type(CreateFrame) == "function" then
    local f = CreateFrame("Frame")
    if f and f.RegisterEvent then
        f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        if f.SetScript then
            f:SetScript("OnEvent", function(_, event, unit, castGUID, spellID, spellName)
                if unit ~= "player" then return end
                WR_MageFrost_NoteCast(spellName, spellID, GetTime())
            end)
        end
    end
end

-- ============================================================
-- 六、主循环
-- ============================================================
function WR_MageForeverFrost()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("寒冰箭")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)

    -- ===== 2. 冻结判定（Forever 冰枪术碎裂窗口）=====
    -- 目标身上有冻结类 debuff，或自己身上有 Fingers of Frost 类 buff
    -- （多别名兼容，见 WR_MageFrost_FOF_BUFFS）→ 视为 Frozen
    -- ★ 统一用 pcall 而非 type() 守卫（见 WR_MageFrost_Show 里的说明）
    local targetFrozen = false
    for i = 1, #WR_MageFrost_FROZEN_DEBUFFS do
        local ok, t = pcall(WR_GetUnitDebuffTime, "target", WR_MageFrost_FROZEN_DEBUFFS[i])
        if ok and type(t) == "number" and t > 0 then
            targetFrozen = true
            break
        end
    end
    local fofProc = false
    for i = 1, #WR_MageFrost_FOF_BUFFS do
        local ok, t = pcall(WR_GetUnitBuffTime, "player", WR_MageFrost_FOF_BUFFS[i])
        if ok and type(t) == "number" and t > 0 then
            fofProc = true
            break
        end
    end
    local frozen = targetFrozen or fofProc

    -- ===== 3. 进入战斗主循环门（防ADD，与三个专精一致）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FADD_BF == 2)   -- 菜单 1=防ADD开 2=关；关时允许 ADD/起手
    if not (inBossEncounter or (UnitAffectingCombat("player") and (allowAdd or TargetInCombat))) then
        -- ★ 脱战 / 未进战：熄灭本循环残留的色块，否则 AHK 会继续按上一 tick 的技能键
        --   （甚至可能在防ADD开的情况下自动开怪）。只清冰法自己的槽位。
        WR_MageFrost_ClearPrompts()
        return false
    end

    -- 射程门
    local inRange30 = (TargetRange ~= nil and TargetRange <= 32)   -- 寒冰箭/冰枪术/暴风雪 30 码
    local inMelee10 = (TargetRange ~= nil and TargetRange <= 10)   -- 冰霜新星/冰锥术 近身

    -- 面板开关（Mage_Menu.lua 冰霜段）
    local allowAoe    = (PigSet.BF_JZMODE ~= false)   -- 智能AOE模式，默认勾选
    local forceBlizz  = (PigSet.BF_BFX_CR == true)    -- 插入暴风雪
    local allowIceBlk = (PigSet.BF_BX ~= false)       -- 自动冰箱，默认勾选
    local allowSnap   = (PigSet.BF_JSLQ ~= false)     -- 自动急速冷却，默认勾选

    -- ===== 4. 保命链（最高优先级；只在真正危险时才提示）=====
    -- 4.1 寒冰屏障（Ice Block，5 分钟 CD）：血量 <30% 且面板「自动冰箱」开着。
    --     开启期间无法攻击/移动/施法，所以必须放在最前面、且门槛很严。
    if allowIceBlk and type(PlayerHP) == "number" and PlayerHP < 0.30 then
        if WR_MageFrost_Show("寒冰屏障", 32) then return true end
    end

    -- ===== 5. 法力管理：唤醒（8 分钟 CD，低蓝才用）=====
    if type(PlayerMP) == "number" and PlayerMP < 0.25 then
        if WR_MageFrost_Show("唤醒", 18) then return true end
    end

    -- ===== 6. ★ 冰枪术 · 碎裂窗口（最高输出优先级）=====
    -- Forever 天赋描述：「Deals 28 to 32 Frost damage... Deals 300% increased
    -- damage to Frozen targets.」—— 对冻结目标 4 倍伤害，且只有 8 秒 CD。
    -- 所以：只有「目标 Frozen（含 FoF 触发）」时才打；非冻结时绝不为了
    -- 「CD 好了」而浪费这一发（这是原实现最大的 bug）。
    if frozen and inRange30 then
        if WR_MageFrost_Show("冰枪术", 44) then return true end
    end

    -- ===== 7. 冰霜新星（25 秒 CD，冻结 8 秒）—— 开碎裂窗口 =====
    -- 只在目标贴身、且当前还没冻结时用：冻住 → 下一 tick 冰枪术就能吃 4 倍。
    if inMelee10 and (not frozen) then
        if WR_MageFrost_Show("冰霜新星", 11) then return true end
    end

    -- ===== 8. 寒冰护体（Ice Barrier，30 秒 CD）=====
    -- 天赋主动：吸收伤害 + 冰霜伤害 +15%（持续 1 分钟，护盾在时再 +5%）。
    -- ★ 放在伤害链【之后】：它是 1 分钟的 buff，晚一个 tick 补不会损失输出，
    --   但放在前面会抢走 AOE/碎裂窗口的第一个 tick（尤其 30 秒 CD 意味着
    --   它几乎总是「就绪」，会永久霸占链首）。
    -- 未学会时被 KNOWN_GATE 挡住，不会乱亮。

    -- ===== 9. AoE 分支 =====
    -- 9.1 暴风雪（引导 AOE，30 码）：面板「智能AOE模式」开 或「插入暴风雪」勾选。
    --      智能模式要求 3+ 目标；插入模式无条件（玩家显式要求）。
    if inRange30 and (allowAoe or forceBlizz) and (UnitCount8 >= 3 or forceBlizz) then
        if WR_MageFrost_Show("暴风雪", 26) then return true end
    end

    -- 9.2 冰锥术（10 秒 CD，瞬发锥形，减速 40%）—— 贴身即用（含单体收尾）
    -- ★★ 2026-11-13 按 NGA 攻略核对修正②：
    --   旧条件 `inMelee10 and UnitCount8 >= 2` 把冰锥术锁死在多目标，单体
    --   永远轮不到。但攻略 P3 明确「现在冰锥术可以作为收尾技能加入冰法的
    --   循环中并能提供非常不错的伤害」、P4「灵活使用冰锥术收尾」，且天赋
    --   强化冰锥术 +35%、深冬之寒让冰锥术再 +20%，单体打它同样是净收益。
    --   本服冰锥术 10 秒 CD / 瞬发 / 246 蓝（Data/Forever_MageSpells.lua:63），
    --   单体贴身时排在寒冰箭填充之前，作为瞬发补充伤害 + 40% 减速。
    --   仍保留 inMelee10 射程门（锥形近身技能，30 码外打不到）；
    --   蓝量下限 0.15、10 秒本地 CD 记账、提示防抖都在 Show 里照常生效，
    --   挡住时继续往下走寒冰护体 / 急速冷却 / 寒冰箭，不会卡住整条链。
    if inMelee10 then
        if WR_MageFrost_Show("冰锥术", 27) then return true end
    end

    -- ===== 10. 寒冰护体（补 buff，排在伤害之后）=====
    if WR_MageFrost_Show("寒冰护体", 65) then return true end

    -- ===== 11. 急速冷却（Cold Snap，10 分钟 CD）=====
    -- 效果：结束其它冰霜法术的剩余 CD。
    -- ★ 只用来「多开一个碎裂窗口」：必须同时满足
    --   (a) 面板「自动急速冷却」开着（BF_JSLQ）；
    --   (b) 目标处于 Frozen（否则重置了也没东西可打）；
    --   (c) 冰枪术确实还在 CD 里。
    -- 绝不为了刷新寒冰护体这种 30 秒小 buff 交掉 10 分钟大招。
    if allowSnap and frozen and (not WR_MageFrost_Ready("冰枪术")) then
        if WR_MageFrost_Show("急速冷却", 63) then return true end
    end

    -- ===== 12. 寒冰箭（常驻填充；无 CD）=====
    -- 唯一一个「无 CD、每 tick 都可以提示」的技能，作为整条链的兜底。
    if inRange30 then
        if WR_MageFrost_Show("寒冰箭", 60) then return true end
        -- ★★ 2026-11-12 修复「冰法输出被保底火球术穿插」：
        --   寒冰箭带 WR_MageFrost_PROMPT_DEBOUNCE(0.4s) 提示防抖，而主循环是
        --   10Hz（0.1s/tick）。防抖期内的 tick 上面这行返回 false，分发器
        --   WR_MageForeverRotation() 一看到 false 就点亮「保底火球术」(槽 5)，
        --   于是冰法每 4 tick 有 3 tick 被 3.5 秒读条的火球术占掉 → 输出链被污染。
        --   防抖期内【不点亮新色块】本身是正确的：WR_ColorFrame_Show 只在成功
        --   点亮时才「隐藏全部再显示一个」，不点亮则上一 tick 的寒冰箭色块保持
        --   常亮、AHK 同色连按继续打寒冰箭。故仅当确实是「防抖空窗」时返回 true
        --   表示冰法链已接管，阻止分发器插入保底火球术。
        --   其它失败原因（槽位非法 / 蓝量不足）仍返回 false，交给分发器保底判断
        --   （保底火球术自身有 noMana 门槛，蓝不足时同样不会点亮）。
        --   脱战 / 超射程时战斗门或 inRange30 已挡在前面，起手保底不受影响。
        local last = WR_MageFrost_PromptCD["寒冰箭"]
        if last and (GetTime() - last) < WR_MageFrost_PROMPT_DEBOUNCE then
            return true
        end
    end

    -- ★ 战斗门已通过、但整条链一个技能都没点亮（超射程 / 全部被 CD·蓝量·已学会闸
    --   挡住）→ 熄灭本循环残留的色块，避免 AHK 在停手状态下继续连按。
    WR_MageFrost_ClearPrompts()
    return false
end
