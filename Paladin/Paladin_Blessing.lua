-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "PALADIN" then return end
-- ============================================================
-- Paladin_Blessing.lua
-- 圣骑士「祝福」独立设置列表 + 脱战自动补祝福
-- ------------------------------------------------------------
-- 2026-11-11 用户口径：
-- 「骑士将祝福下拉框删除，更改为祝福按钮，放在打断下方，
--   按钮打开后是一个祝福设置的单独列表，列表如图所示功能」
--
-- 截图功能（逐条落实）：
-- · 开着时脱战自动补祝福；给谁加哪个在列表里点格子：
--   一个格子一种祝福（力量 / 智慧 / 王者），每行只能亮一个，再点一下取消。
-- · 单人：给自己加（普通祝福）。
-- · 小队：一人一行，加普通祝福；没单独点过的人按团队那张职业表加；
--   点「无」= 这个人不加。
-- · 团队：一个职业一行，加强效祝福。
-- · 每段标题前面的勾 = 该段的祝福对象补不补；三段互相独立。
--   比如去掉「团队」的勾：团队队友不补，但「个人」段仍按自己的勾选生效。
-- · 身上没有或快到期才补，别的圣骑士加了同一种也算有；
--   战斗中、骑着坐骑、吃喝时不补；补祝福全程不占用游戏焦点。
-- · 额外条件：总闸「祝福」。
--
-- 实现要点：
-- · ★ 2026-11-12 起全程不切焦点（用户口径「单人/小队/团队祝福都可以不用
--   焦点直接加」）：
--     单人      = 自施宏槽 91~93（/cast [target=player] 普通祝福，ALT-F1/F2/F3）；
--     小队/团队 = 动态直施宏槽 95（/cast [target=partyN|raidN] 祝福名，ALT-F5），
--                 每次补祝福前把宏文本指到该单位再点亮；
--     宏系统不可用（离线夹具/异常）时才回落旧的「切焦点 + @focus 宏 102~107」流程。
--   动态宏更新是同步动作（SetAttribute 立即生效）且只在脱战执行；连发撞 GCD 由
--   AHK 对常亮色块连续按键自愈（同色一直按，GCD 转好后自然打出）。
-- · 存档全部走 PigSet.PAL_BLESS（角色级 SavedVariables），惰性初始化，
--   不依赖 ADDON_LOADED 时序。
-- · 本文件顶层只定义常量/函数，窗口在第一次打开时惰性创建，便于离线夹具加载。
-- ============================================================

-- ★ 三种祝福（0 = 无 / 不设置，1 力量 / 2 智慧 / 3 王者）
--   normalSlot/greaterSlot = [@focus] 宏（102~107，给队友加时先切焦点）；
--   selfSlot = 单人自施宏（91~93，/cast [target=player] …，Paladin_Macros.lua
--   的 ALT-F1/F2/F3，2026-11-12 由空占位启用）—— 单人补祝福直接点亮它，
--   不切焦点、不受当前目标影响（用户口径：单人可以不用设置焦点直接加祝福）。
WR_PAL_BLESS_KINDS = {
    [1] = { key = "力量", normal = "力量祝福", greater = "强效力量祝福",
            short = "力", r = 0.95, g = 0.55, b = 0.15,
            normalSlot = 102, greaterSlot = 103, selfSlot = 91 },
    [2] = { key = "智慧", normal = "智慧祝福", greater = "强效智慧祝福",
            short = "智", r = 0.25, g = 0.60, b = 0.95,
            normalSlot = 104, greaterSlot = 105, selfSlot = 92 },
    [3] = { key = "王者", normal = "王者祝福", greater = "强效王者祝福",
            short = "王", r = 0.75, g = 0.45, b = 0.95,
            normalSlot = 106, greaterSlot = 107, selfSlot = 93 },
}

-- ★ 团队表：一个职业一行（本服首发 9 职业，无死亡骑士）
WR_PAL_BLESS_CLASSES = {
    { token = "WARRIOR",  zh = "战士" },
    { token = "PALADIN",  zh = "圣骑士" },
    { token = "HUNTER",   zh = "猎人" },
    { token = "ROGUE",    zh = "盗贼" },
    { token = "PRIEST",   zh = "牧师" },
    { token = "SHAMAN",   zh = "萨满" },
    { token = "MAGE",     zh = "法师" },
    { token = "WARLOCK",  zh = "术士" },
    { token = "DRUID",    zh = "德鲁伊" },
}

-- 剩余时间低于该值视为「快到期」，需要补（秒）
WR_PAL_BLESS_REFRESH_LEAD = 60
-- 同一单位 + 同一祝福的提示防刷屏（秒）
-- ★★★ 2026-11-12 用户口径「补的时机太晚」：10 秒 → 3 秒。
--   原来 10 秒的初衷是「怕反复刷」，但反复刷的真正源头是「光环读不到被当成
--   没有」（已由 CacheUnreadable 指数退避单独处理），不是这个重试间隔。
-- ★★★ 2026-11-18 用户口径「脱战后，小队祝福刷的太慢了」：3 → 1.5 秒。
--   「读得到 + 确实没有」= AHK 漏按或祝福被驱散，1.5 秒（一个 GCD 量级）重试；
--   pending（1.8 秒）与单位记账（3 秒宽限）双重收口，不会变成连刷。
WR_PAL_BLESS_PROMPT_CD = 1.5
-- ★★ 2026-11-12 修复「祝福反复刷」核心二：刚打出这条祝福后的宽限（秒）
-- ------------------------------------------------------------
-- 就算名字匹配修好了，只要**任何一次**光环读值失败（战斗中 secret、
-- 缓存扫描被 pcall 放弃、扫描时条目还没写入），BuffRemain 就会返回 0
-- → Needs 恒 true → 每 WR_PAL_BLESS_PROMPT_CD(10 秒) 重新点亮一次色块
-- → AHK 连按 → 每 10 秒重刷一次祝福。这正是用户描述的「反复刷」。
-- 「读值失败」与「真的没有」必须分开处理：
--   · 用真实施放事件（Core/Forever_APIShim.lua 的 WR_Forever_LastPlayerCast，
--     由 UNIT_SPELLCAST_SUCCEEDED 维护）作为「刚刚确实打出去了」的证据；
--   · 宽限期内一律不再提示补同一条祝福。
-- 取值远小于祝福实际时长（30 分钟），被驱散时最多晚这么久才补，无实际损失。
-- ★★★ 2026-11-18 用户口径「脱战后，小队祝福刷的太慢了」：8 → 3 秒。
--   光环读不到时按「刚施放过」宽限的时间。祝福 30 分钟长 buff，3 秒宽限
--   足够挡住同一 GCD 内的重复提示；施放事件丢了 / 光环没跟上时 3 秒就能重试，
--   不再让一个队友干等 8 秒。
WR_PAL_BLESS_AFTER_CAST_GRACE = 3
-- 同一单位 + 同一祝福「已点亮、等待 buff 上身确认」的状态保持（秒）
-- ★★★ 2026-11-12 用户口径「补的时机太晚」：8 秒 → 2.5 秒。
--   8 秒的假设是「AHK 会一直按同一个色块，早晚打出去」，但真机不是这样：
--   色块只保持 1.0~1.5 秒，AHK 按下的那一下如果正好撞在**上一个祝福的 GCD**
--   里，这次施放就直接被客户端拒掉 —— 色块灭了、buff 没上身，而 pending 却
--   还要再锁 8 秒才允许重试 → 玩家看到的就是「点了半天不补」。
--   ★★★ 2026-11-18 用户口径「脱战后，小队祝福刷的太慢了」：2.5 → 1.8 秒。
--   漏按重试节奏 = max(PENDING_TTL, PROMPT_CD)。压到 1.8 秒（≈ GCD 1.5 秒
--   + AHK 读屏余量）后，漏按的队友约 1.8 秒就能重亮，整队补刷明显变快。
WR_PAL_BLESS_PENDING_TTL = 1.8
-- ★★★ 2026-11-12 新增：祝福是**占 GCD 的主动技能**，两个不同单位之间必须
--   隔开一个 GCD，否则后一个的按键必然被客户端拒绝（色块白亮一次）。
--   旧实现完全没有这层节流：每 0.1 秒就点亮下一个队友的色块，
--   实际只有第一个能打出去，其余全撞 GCD，还要被 pending 再锁 8 秒 ——
--   4 个队友就要 0.1 / 8.2 / 16.3 / 24.4 / 32.5 秒（离线实测）。
--   现在点亮后统一等一个 GCD 再处理下一个单位。
WR_PAL_BLESS_CAST_GAP = 1.2
-- 焦点已切到目标后，等这个时间再点亮祝福色块（给 AHK/客户端一点反应时间，秒）
WR_PAL_BLESS_FOCUS_SETTLE = 0.15

-- ============================================================
-- ★★★ 2026-11-12 用户口径「当队友不在技能释放范围的时候，不在卡着使用祝福buff」
-- ------------------------------------------------------------
-- 旧实现的距离门只有 UnitInRange（40 码「连线距离」），而且读不到就放行：
--   · 普通祝福真实射程只有 30 码 → 30~40 码的队友仍然被点亮色块，
--     AHK 按下去客户端拒绝（距离不够），buff 不上身；
--   · 这次点亮还占掉本 tick 的唯一返回点 + 记 pending（2.5 秒）+ 记施放单位
--     （JustCast 8 秒）→ 后面的队友全被这条「打不出去的祝福」卡住；
--   · 于是表现就是「卡着反复对一个够不着的队友用祝福」。
-- 现在补一道**真实射程门**（按技能自己的射程，不是 40 码连线距离）：
--   普通祝福 30 码 / 强效祝福 40 码（数据源：talentsforever.com/export/paladin.json
--   —— Blessing of * = "30 yd range"，Greater Blessing of * = "40 yd range"）。
-- 判定顺序（任一层明确给答案就用它，全部读不到才放行）：
--   ① IsSpellInRange(spellName, unit) → 1 = 在射程内，0 = 超射程（最准，按技能算）
--   ② UnitInRange(unit) → false = 超 40 码（保守：只用来否决「肯定够不着」）
--   ③ WR_UnitRange(unit) → 数值距离，> 射程 + 余量 即超程（LibRangeCheck）
-- 「读不到就放行」保持不变：脱战可读，读不到时宁可放过也不要整队不补。
-- ============================================================
WR_PAL_BLESS_RANGE = 30              -- 普通祝福（Blessing of *）真实射程 30 码
WR_PAL_BLESS_RANGE_GREATER = 40      -- 强效祝福（Greater Blessing of *）真实射程 40 码
-- 数值距离判定的余量（码）：LibRangeCheck 是分桶估算，给 2 码容差，
-- 避免「刚好 30 码」被分桶误差误判成超程。
WR_PAL_BLESS_RANGE_SLACK = 2

-- ============================================================
-- ★★ 2026-11-12 修复「祝福反复刷」核心五：光环**读不到**时的指数退避
-- ------------------------------------------------------------
-- 前面四条（基础名匹配 / JustCast 宽限 / pending 待确认 / 缓存自愈）解决的是
-- 「读得到但不精确」与「短时间读不到」。还剩最后一条真机路径没堵住：
--
--   WR_AuraCache[unit] 为 nil（战斗中 C_UnitAuras 抛 secret、扫描被 pcall 放弃、
--   单位刚出现还没扫过）时，WR_GetAuraInfoCore 直接 return 0,0,0
--   → BuffRemain 恒 0 → Needs 恒 true。
--   而 JustCast 宽限只有 8 秒、pending 只有 8 秒，两者一过就回到
--   「每 WR_PAL_BLESS_PROMPT_CD(10 秒) 亮一次色块」→ AHK 每 10 秒按一次
--   → 玩家看到的仍然是「反复刷 buff」。
--
-- 关键区分（不能混为一谈）：
--   · 缓存**存在**但里面没有这条祝福  = 真的没有 → 每 10 秒重试是对的
--     （AHK 漏按 / 祝福被驱散后要能尽快补上）；
--   · 缓存**整块缺失**（WR_AuraCache[unit] 不是 table）= 读不到，
--     「没有」和「有」无法区分 → 绝不能按 10 秒节奏刷，必须退避。
-- 退避序列（秒）：第 1 次仍按常规 10 秒，之后逐级放大到 5 分钟。
-- 祝福本身持续 30~60 分钟，最坏情况晚 5 分钟补上，远好过每 10 秒刷一次。
-- 一旦光环恢复可读 / buff 确认上身，退避立刻清零，回到正常节奏。
-- ============================================================
WR_PAL_BLESS_UNREADABLE_BACKOFF = { 10, 30, 60, 120, 300 }
-- [unit|kind] = { level = 已连续退避次数, nextAt = 下一次允许点亮的时刻 }
WR_PaladinBlessing_Backoff = WR_PaladinBlessing_Backoff or {}

-- 吃喝 / 假死 / 影遁等停手 Buff（与 WR_PriorityCheck 一致）
WR_PAL_BLESS_STOP_BUFFS = {
    "喝水", "进食", "饮用", "进食饮水", "假死", "影遁",
    "食物", "饮料", "食物和饮料", "饮水",
}

-- ★★ 2026-11-11：接口可用性判定（替代裸写 type(x) == "function"）
-- ------------------------------------------------------------
-- 真实客户端里 WoW 接口都是 Lua function；但离线夹具用 Python 实现这些
-- 接口，Lupa 暴露给 Lua 的 type() 是 "userdata"，直接写
--     if type(UnitClass) == "function"
-- 在夹具里恒为假 —— 代码会静默走「接口不存在 → 降级/回退」分支：
-- 存档每次被重建（玩家设置丢失）、队伍状态恒判 solo、Buff 剩余恒 0 等。
-- 这些分支在夹具里是错的，所以能力检测统一走本函数：
--   function     → 真客户端接口
--   userdata     → 夹具注入的 Python 可调用 / 其它 C 侧可调用
-- 其余（nil、boolean、number、string、table）→ 不可调用。
-- 注意：本函数只回答「能不能调用」，不保证调用一定成功；调用点仍带 pcall。
function WR_PalBless_Fn(v)
    local t = type(v)
    return t == "function" or t == "userdata"
end

-- ============================================================
-- ★★ 2026-11-11：pcall 结果安全读取
-- ------------------------------------------------------------
-- 本文件大量调用可能为 nil / 可能抛错 / 可能返回 secret 的 WoW API，
-- 统一用 pcall 包一层。但直接写 `local ok, v = pcall(f, ...)` 在**离线夹具**
-- （Python + Lupa 驱动）里会静默出错：
--   · 夹具里这些 API 是 Python 可调用对象，
--   · Lupa 会把 pcall 的多个返回值打包成一个 tuple 交回 Lua，
--   · 于是 `local ok, v = <tuple>` 只取到元组第 1 个元素（true），v 变成 nil。
-- 结果就是「值永远读不到」→ BuffRemain 恒 0、Blocked 恒 false、UnitPick 恒回退。
-- 真实客户端里这样写是没问题的，但夹具同样是验收手段，不能让它静默失真。
-- 下面这个取值器两种情况都正确：
--   · Lua 真客户端：res 是第一个返回值本身（非 table），原样返回；
--   · 夹具 tuple：res 是 table，按数组下标取第 i 个返回值。
-- ============================================================
function WR_PalBless_Pick(res, idx)
    idx = idx or 1
    if type(res) == "table" then
        local v = res[idx]
        if v ~= nil then return v end
        -- 元组长度不足（原函数返回值少于 idx）→ 就是 nil
        return nil
    end
    if idx == 1 then return res end
    return nil
end

-- ★★ 2026-11-12：secret 值收敛（nil 化）
-- ------------------------------------------------------------
-- 12.0 起，插件代码在战斗中读 UnitInRange / UnitIsConnected / UnitExists /
-- UnitIsDeadOrGhost 等接口可能拿到 secret boolean。secret 值是「哑值」：
-- 赋值、传递、再传给别人都没事，但一旦参与比较、布尔取反、算术、字符串
-- 拼接、table 索引就会抛
--   attempt to compare local 'v' (a secret boolean value, while execution
--   tainted by 'MKHelperForever')
-- 并且整个插件会被打上会话级 taint（后续连 RegisterEvent 都会被拦）。
-- 本函数不做任何转换，只回答「这个值能不能安全地拿去判断」——
-- 不能就返回 nil，让调用方的 not v / v == false 全部天然不命中。
function WR_PalBless_Plain(v)
    if v == nil then return nil end
    -- 路径 1：12.0 原生 issecretvalue（对 secret 值本身调用是安全的）
    if type(issecretvalue) == "function" then
        local okS, sec = pcall(issecretvalue, v)
        if okS and sec == true then return nil end
    end
    -- 路径 2：WR_IsSecretValue（Core/Forever_SecretGuard.lua 提供，带存在性兜底；
    --         离线夹具未加载 Core 时它可能不存在，因此仍走路径 3）
    if type(WR_IsSecretValue) == "function" then
        local okW, secW = pcall(WR_IsSecretValue, v)
        if okW and secW == true then return nil end
    end
    -- 路径 3：兜底探针。secret 值连 type() 都不给正常答案（抛错或返回 nil），
    --         pcall 包一层就能把「读得动」和「读不动」区分开，且不污染 taint。
    local okT, t = pcall(type, v)
    if not okT or t == nil then return nil end
    return v
end

-- ★★ 2026-11-12：数值收敛（secret / nil / 字符串 → fallback）
-- ------------------------------------------------------------
-- 用途：把可能为 secret 的数值（技能剩余时间、Buff 剩余秒数、队内人数）
-- 在**进入任何比较或算术之前**收敛成普通 number。
-- 注意与 WR_SafeNumber 的区别：这里不依赖 Core/Forever_SecretGuard.lua
-- （离线夹具只加载本文件时它可能不存在），走 pcall(type, v) 兜底探针。
function WR_PalBless_Num(v, fallback)
    if v == nil then return fallback end
    local okT, t = pcall(type, v)
    if not okT or t ~= "number" then return fallback end
    return v
end

-- 统一封装：安全调用 + 取第 n 个返回值。
-- 原写法 `local ok, v = pcall(fn, ...)` 在离线夹具（Lupa）下只拿到元组第 1 项，
-- v 恒为 nil。改成 WR_PalSafe_Call 后：
--   ok  = 调用是否成功（布尔）
--   v   = 被调函数的第 n 个返回值（n 默认 2；失败时为 nil）
-- ★ 夹具下 pcall 的返回值会被 Lupa 打包成元组并落到 res[1]，因此先按
--   「res[1] 是元组」解一层：tuple[1]=ok，tuple[2..]=原函数返回值。
--   真客户端里 res 就是 Lua 的普通序列 {ok, v1, v2, ...}，结构一致，无需分支。
function WR_PalSafe_Call(n, fn, ...)
    -- ★★ 2026-11-12 修复 secret 报错（Paladin_Blessing.lua:277 attempt to compare local 'v'）：
    --   12.0 起 UnitInRange / UnitIsConnected / UnitExists / UnitIsDeadOrGhost 等
    --   「单位状态型」接口在战斗中（含战斗锁定期）可能返回 **secret boolean**。
    --   secret 值一进比较（v == false / not v / v == true）就抛
    --   "attempt to compare ... a secret boolean value"。
    --   原写法先把 pcall 结果塞进表 `{ pcall(fn, ...) }` 再逐个比较——表构造 / 索引
    --   本身不比较，但 **pairs/ipairs 与 table 版 unpack 会读 #res，而 #res 会对元素
    --   做续接比较**，夹具 Lupa 元组分支拿到的是 Python 元组对象，同样会退化；
    --   更关键的是调用方（UnitUsable 等）总会对取回来的 v 做判断。
    --   所以这里在**交付前**就把 secret 收敛成 nil：
    --     · 能拿到 issecretvalue（12.x 客户端 / 夹具）→ 精确检测；
    --     · 拿不到 → 用 pcall(type, v) 兜底（secret 值连 type() 都拒绝对话，返回失败）。
    --   回调方随后只需要写 `v == true` / `type(v) == "string"`，nil 天然不命中，
    --   无需每条比较再加 issecretvalue 判断，也就不会再有人漏写一处又炸一次。
    --   注意：这里**只**做「收敛成 nil」，不把 secret 强行转成 false——
    --   「读不到」和「读到 false」语义必须分开，否则距离门 / 连线门会把队友全挡掉。
    local res = { pcall(fn, ...) }
    local ok = res[1]
    if type(ok) == "table" then
        -- Lupa 元组：res[1] 是 {true, v1, v2, ...}
        local tuple = ok
        local suc = tuple[1] and true or false
        local v = tuple[(n or 2) - 1]
        return suc, WR_PalBless_Plain(v)
    end
    local suc = ok and true or false
    return suc, WR_PalBless_Plain(WR_PalBless_Pick(res, n or 2))
end

-- ============================================================
-- 存档（惰性初始化，避免依赖 SavedVariables 加载时序）
-- ============================================================
function WR_PaladinBlessing_Cfg()
    if type(PigSet) ~= "table" then PigSet = {} end
    local c = PigSet.PAL_BLESS
    if type(c) ~= "table" then
        c = {}
        PigSet.PAL_BLESS = c
    end
    if c.enable == nil then c.enable = false end           -- 总闸：默认关
    if c.solo == nil then c.solo = true end                 -- 单人段：默认开
    if c.party == nil then c.party = true end               -- 小队段：默认开
    if c.raid == nil then c.raid = true end                 -- 团队段：默认开
    if c.soloPick == nil then c.soloPick = 0 end            -- 单人：0=无
    if type(c.partyPick) ~= "table" then c.partyPick = {} end  -- [队员名] = 0/1/2/3
    if type(c.raidPick) ~= "table" then c.raidPick = {} end    -- [职业token] = 0/1/2/3
    return c
end

-- 读格子：scope = "solo" | "party" | "raid"，key = 名字 / 职业token（单人可省略）
function WR_PaladinBlessing_GetPick(scope, key)
    local c = WR_PaladinBlessing_Cfg()
    if scope == "solo" then
        return tonumber(c.soloPick) or 0
    elseif scope == "party" then
        return tonumber(c.partyPick[key])
    elseif scope == "raid" then
        return tonumber(c.raidPick[key])
    end
    return nil
end

-- ★ 点格子：每行只能亮一个，再点一下取消；第 4 格「无」= 明确不加（0）
--   value = 1/2/3 = 祝福；value = 0 = 「无」（显式不加）；再点同格 → nil（未设置）
function WR_PaladinBlessing_Toggle(scope, key, value)
    local c = WR_PaladinBlessing_Cfg()
    -- 小队空行 / 未命名行：key 为 nil 时禁止写表（table index is nil 会报错）
    -- ★★ 2026-11-12：这里原来**静默** return false —— 玩家点了格子既不亮也不报错，
    --   看上去就是「点了没用」。现在给一句可见提示，把「这行还没有队友」讲清楚。
    if scope ~= "solo" and key == nil then
        if type(print) == "function" then
            print("|cffffd200[祝福]|r 这一行还没有队友（队伍里没这个人），先组队再点。")
        end
        return false
    end
    local cur
    if scope == "solo" then
        cur = tonumber(c.soloPick) or 0
        if cur == value then
            c.soloPick = 0                       -- 再点取消（单人：回到「无」）
        else
            c.soloPick = value
        end
    elseif scope == "party" then
        cur = tonumber(c.partyPick[key])
        if cur == value then
            c.partyPick[key] = nil               -- 再点取消 → 未设置（按职业表）
        else
            c.partyPick[key] = value
        end
    elseif scope == "raid" then
        cur = tonumber(c.raidPick[key])
        if cur == value then
            c.raidPick[key] = nil
        else
            c.raidPick[key] = value
        end
    end
    if WR_PaladinBlessing_Refresh then WR_PaladinBlessing_Refresh() end
    return true
end

function WR_PaladinBlessing_SectionEnabled(scope, value)
    local c = WR_PaladinBlessing_Cfg()
    if value == nil then
        if scope == "solo" then return c.solo == true end
        if scope == "party" then return c.party == true end
        if scope == "raid" then return c.raid == true end
        return c.enable == true
    end
    if scope == "enable" then c.enable = value == true
    elseif scope == "solo" then c.solo = value == true
    elseif scope == "party" then c.party = value == true
    elseif scope == "raid" then c.raid = value == true end
    if WR_PaladinBlessing_Refresh then WR_PaladinBlessing_Refresh() end
end

-- ============================================================
-- 队伍状态 / 单位枚举 / 职业
-- ============================================================
function WR_PaladinBlessing_GroupState()
    local inRaid = false
    local inParty = false
    local count = 0
    -- ★ 2026-11-12：这里一律用「布尔字面量比较」，不用真假值判断：
    --   v and true or false 会把 secret boolean 当条件用，
    --   not inRaid 同样是条件判断，都会抛 secret 值错误。
    --   WR_PalSafe_Call 已把 secret 收敛成 nil，nil 与 true 比较恒为 false，安全。
    if WR_PalBless_Fn(IsInRaid) then
        local ok, v = WR_PalSafe_Call(2, IsInRaid)
        if ok and v == true then inRaid = true end
    end
    if not inRaid and WR_PalBless_Fn(GetNumRaidMembers) then
        local ok, v = WR_PalSafe_Call(2, GetNumRaidMembers)
        if ok and (tonumber(v) or 0) > 0 then inRaid = true end
    end
    if WR_PalBless_Fn(IsInGroup) then
        local ok, v = WR_PalSafe_Call(2, IsInGroup)
        if ok and v == true then inParty = true end
    end
    if not inParty and WR_PalBless_Fn(GetNumPartyMembers) then
        local ok, v = WR_PalSafe_Call(2, GetNumPartyMembers)
        if ok and (tonumber(v) or 0) > 0 then inParty = true end
    end
    if WR_PalBless_Fn(GetNumGroupMembers) then
        local ok, v = WR_PalSafe_Call(2, GetNumGroupMembers)
        if ok then count = WR_PalBless_Num(tonumber(v), 0) end
    end
    if inRaid then
        if count <= 0 then count = 40 end
        return "raid", count
    elseif inParty then
        if count <= 0 then count = 5 end
        return "party", count
    end
    return "solo", 0
end

local function WR_PaladinBlessing_ClassToken(unit)
    if not WR_PalBless_Fn(UnitClass) then return nil end
    local ok, token = WR_PalSafe_Call(3, UnitClass, unit)
    if ok and type(token) == "string" then return token end
    return nil
end

local function WR_PaladinBlessing_UnitName(unit)
    if not WR_PalBless_Fn(UnitName) then return nil end
    local ok, name = WR_PalSafe_Call(2, UnitName, unit)
    if ok and type(name) == "string" and name ~= "" then return name end
    return nil
end

-- ★★ 2026-11-12 修复「小队队友加不上选择的祝福」核心：小队行的 key 必须「实时取」
-- ------------------------------------------------------------
-- 用户口径原话：「目前不给小队队友加选择的对应祝福buff」。
--
-- 根因（已用离线脚本复现）：小队 4 行的存档 key 用的是 `row.curName`，
-- 而 `row.curName` 只在 `WR_PaladinBlessing_Refresh()` 里被赋值一次
-- （= 窗口打开的那一刻）。真实流程几乎必然是：
--   ① 单人/刚上线时打开祝福窗口 → 此时还没组队，4 行全部显示「（空）」，
--      `row.curName` 全是 nil；
--   ② 之后才被拉进小队 → 窗口没重开，`row.curName` 仍是 nil；
--   ③ 玩家点「力 / 智 / 王」→ `Toggle("party", nil, 1)` 第一行就
--      `if scope ~= "solo" and key == nil then return false end` 直接返回 false
--      → 存档里什么都没写；
--   ④ 循环 Auto() 里 partyPick[队友名] 查不到 → 落到团队职业表 raidPick
--      → 职业表没配就是 0（不加）→ 表现为「选了也不给队友加」。
--   更糟的是 ③ 是静默失败：格子既不亮也不报错，玩家只会觉得「点了没用」。
--
-- 修法：小队行的 key 改为**每次点击 / 每次刷新都现场向客户端要一次名字**
-- （下面的 WR_PaladinBlessing_PartyName），不再依赖打开窗口那一刻的快照；
-- 同时挂上队伍名单变化事件，成员进出时自动刷新行标签与格子亮灭。
function WR_PaladinBlessing_PartyName(index)
    local i = tonumber(index) or 0
    if i < 1 or i > 4 then return nil end
    return WR_PaladinBlessing_UnitName("party" .. i)
end

local function WR_PaladinBlessing_UnitUsable(unit)
    -- ★★ 2026-11-12：12.0 战斗锁定期，下面这几个单位状态接口返回 secret boolean。
    --   原写法 `if ok and v then` / `v == false` 一比较就抛 secret 值错误
    --   （崩溃点就是 277 行的 UnitInRange）。现在统一：
    --     · 明确的 true / false 才用于判定（== true / == false 对 nil 恒假，安全）；
    --     · secret → WR_PalSafe_Call 已收敛成 nil → 三处门全部「放行」。
    --   距离门的方向是保命用的：读不到时宁可放过，也不能把全队挡掉不补祝福。
    if WR_PalBless_Fn(UnitExists) then
        local ok, v = WR_PalSafe_Call(2, UnitExists, unit)
        if ok and v == false then return false end
    end
    -- 死亡/灵魂之门：明确 true 才排除
    if WR_PalBless_Fn(UnitIsDeadOrGhost) then
        local ok, v = WR_PalSafe_Call(2, UnitIsDeadOrGhost, unit)
        if ok and v == true then return false end
    end
    -- 连线门：明确 false 才排除
    if WR_PalBless_Fn(UnitIsConnected) then
        local ok, v = WR_PalSafe_Call(2, UnitIsConnected, unit)
        if ok and v == false then return false end
    end
    -- 距离门：只给 40 码内的队友补，读不到就放行（脱战可读，secret 时按可读处理）
    -- ★★★ 2026-11-12：这里只是**粗门**（40 码连线距离，防「完全够不着」）。
    --   真实射程门在 WR_PaladinBlessing_InCastRange（普通 30 / 强效 40 码），
    --   因为普通祝福只有 30 码 —— 30~40 码之间这一层会放行，必须由射程门拦。
    if WR_PalBless_Fn(UnitInRange) then
        local ok, v = WR_PalSafe_Call(2, UnitInRange, unit)
        if ok and v == false then return false end
    end
    return true
end

-- ============================================================
-- ★★★ 2026-11-12 用户口径「当队友不在技能释放范围的时候，不在卡着使用祝福buff」
-- ------------------------------------------------------------
-- 真实射程门：按**这条祝福自己的射程**判断该单位此刻够不够得着。
--   · 普通祝福 = 30 码，强效祝福（团队段）= 40 码；
--   · 超程 → 返回 false，调用方「跳过这个单位」：
--     不点亮色块、不占本 tick 返回点、不记 pending / JustCast，
--     队列直接推进到下一个够得着的队友（不再被够不着的人卡住）。
-- 三层判定，任一层能明确给答案就用它；全部读不到 → 放行（保持原语义）：
--   ① IsSpellInRange(spell, unit)：1=在射程 / 0=超射程（最准，按技能算）
--   ② UnitInRange(unit)：false = 超 40 码 → 对两种祝福都算超程（保守否决）
--   ③ WR_UnitRange(unit)：数值距离，> 射程 + 余量 即超程（LibRangeCheck 分桶）
-- 为什么必须区分「读不到」和「读到超程」：
--   脱战补祝福时这些接口可读；战斗中可能 secret → WR_PalSafe_Call 收敛成 nil。
--   nil 时放行是**故意**的：宁可多点亮一次（AHK 按一下被拒绝，代价小），
--   也不要因为读不到就把全队永久挡在门外（那才是「补不上祝福」）。
-- ============================================================
function WR_PaladinBlessing_CastRange(spellName, greater)
    if greater then
        return WR_PAL_BLESS_RANGE_GREATER or 40
    end
    return WR_PAL_BLESS_RANGE or 30
end

-- 返回 true = 够得着 / 读不到（放行）；false = 明确超程
function WR_PaladinBlessing_InCastRange(unit, spellName, greater)
    if type(unit) ~= "string" or unit == "" then return true end
    -- 自己永远够得着（自施不受距离限制）
    if unit == "player" then return true end

    local range = WR_PaladinBlessing_CastRange(spellName, greater)

    -- ① 按技能查射程：最准的一层（普通 30 / 强效 40 由客户端自己算）
    if type(spellName) == "string" and spellName ~= "" then
        local fn = nil
        if WR_PalBless_Fn(IsSpellInRange) then
            fn = IsSpellInRange
        elseif type(C_Spell) == "table" and WR_PalBless_Fn(C_Spell.IsSpellInRange) then
            fn = C_Spell.IsSpellInRange
        end
        if fn then
            local ok, v = WR_PalSafe_Call(2, fn, spellName, unit)
            v = WR_PalBless_Num(v, nil)
            -- 1 = 在射程内；0 = 超出射程；nil/其它 = 读不到（法术名没解析出来等）
            if ok and v == 1 then return true end
            if ok and v == 0 then return false end
        end
    end

    -- ② 40 码连线距离：明确 false 说明连强效祝福都够不着 → 一定超程
    if WR_PalBless_Fn(UnitInRange) then
        local ok, v = WR_PalSafe_Call(2, UnitInRange, unit)
        if ok and v == false then return false end
    end

    -- ③ 数值距离兜底（LibRangeCheck 分桶估算，带余量）
    if WR_PalBless_Fn(WR_UnitRange) then
        local ok, d = WR_PalSafe_Call(2, WR_UnitRange, unit)
        d = WR_PalBless_Num(d, nil)
        -- 999 = 库不可用 / 读不到 → 放行
        if ok and d ~= nil and d < 900 then
            if d > range + (WR_PAL_BLESS_RANGE_SLACK or 2) then return false end
        end
    end

    return true
end

-- ★★★ 2026-11-13 用户口径「小队祝福只作用于范围内的队友」——射程**确认**闸：
--   InCastRange 的旧口径是「三层全部读不到 → 放行」（11-12 为保补祝福速度定的）。
--   但真机证据表明：目标超程 / 条件回退时友善法术会退化落到玩家自己身上
--   （选中敌方目标时尤甚）——「读不到」再放行就等于允许盲施。
--   本函数按同一套三层判定，但语义反过来：**必须有一层明确回答「在射程内」**
--   才算确认；明确超程或全部读不到 → false（调用方跳过该单位，宁可不补不误施）。
function WR_PaladinBlessing_RangeConfirmed(unit, spellName, greater)
    if type(unit) ~= "string" or unit == "" then return false end
    if unit == "player" then return true end               -- 自己永远够得着
    local range = WR_PaladinBlessing_CastRange(spellName, greater)
    -- ① 按技能查射程：读到 1/0 都算「拿到了明确答案」
    if type(spellName) == "string" and spellName ~= "" then
        local fn = nil
        if WR_PalBless_Fn(IsSpellInRange) then
            fn = IsSpellInRange
        elseif type(C_Spell) == "table" and WR_PalBless_Fn(C_Spell.IsSpellInRange) then
            fn = C_Spell.IsSpellInRange
        end
        if fn then
            local ok, v = WR_PalSafe_Call(2, fn, spellName, unit)
            v = WR_PalBless_Num(v, nil)
            if ok and v ~= nil then return v == 1 end
        end
    end
    -- ③ 数值距离（LibRangeCheck 分桶）：读到 → 与射程+余量比较，拿到明确答案
    if WR_PalBless_Fn(WR_UnitRange) then
        local ok, d = WR_PalSafe_Call(2, WR_UnitRange, unit)
        d = WR_PalBless_Num(d, nil)
        if ok and d ~= nil and d < 900 then
            return d <= range + (WR_PAL_BLESS_RANGE_SLACK or 2)
        end
    end
    -- ② UnitInRange 只有「否决」能力（false=超40码），给不出「在射程内」的确认
    -- 全部读不到 → 无法确认 → 按超程处理（strict，不再放行）
    return false
end

-- 该单位应有的祝福种类（返回 0/nil = 不加）+ 是否用强效
function WR_PaladinBlessing_UnitPick(unit, mode, classToken)
    local c = WR_PaladinBlessing_Cfg()
    if mode == "solo" then
        return tonumber(c.soloPick) or 0, false
    elseif mode == "party" then
        -- ★ 2026-11-16：个人段没勾 → 自己不再参与祝福队列（Auto 也不会把自己放进 units）。
        if unit == "player" and c.solo ~= true then return 0, false end
        local name = WR_PaladinBlessing_UnitName(unit)
        local explicit = name and tonumber(c.partyPick[name]) or nil
        if explicit ~= nil then
            -- 显式点过（含「无」=0）→ 用普通祝福
            return explicit, false
        end
        -- ★ 2026-11-12 修复「单人我选择了智慧还是只会亮力量」：
        --   小队 4 行只列 party1~4，没有「自己」这一行 → partyPick[自己名字]
        --   永远点不了；不在这里兜底的话，多开组队时自己在小队状态下
        --   只会落到职业表，单人行（行标签就是角色名）选的格子被完全忽略。
        --   单人行选了 1/2/3 → 自己跟着用（普通祝福，与小队段一致）。
        if unit == "player" and (tonumber(c.soloPick) or 0) >= 1 then
            return tonumber(c.soloPick), false
        end
        -- 没单独点过 → 按团队那张职业表（但小队段用普通祝福）
        local byClass = classToken and tonumber(c.raidPick[classToken]) or 0
        return byClass or 0, false
    elseif mode == "raid" then
        -- ★ 2026-11-16：个人段没勾 → 自己在团队里也不再参与。
        if unit == "player" and c.solo ~= true then return 0, true end
        -- ★ 2026-11-12 修复一「团队裹自己不跟随单人行选择」：
        --   团队模式原来只按职业表 raidPick[classToken] 算自己 → 单人行（行标签
        --   就是角色名）选的格子被完全忽略，与小队修复前同样的表现。
        --   自己在团队里仍用强效祝福（团队段口径），只是种类跟随单人行。
        if unit == "player" and (tonumber(c.soloPick) or 0) >= 1 then
            return tonumber(c.soloPick), true
        end
        local byClass = classToken and tonumber(c.raidPick[classToken]) or 0
        return byClass or 0, true           -- 团队段：强效祝福
    end
    return 0, false
end

-- ============================================================
-- Buff 判定：身上没有或快到期才补，别的骑士加的「同一种」也算有
--   （同族 = 普通名 + 强效名，任一存在即算有）
-- ============================================================
-- ★★ 2026-11-12 修复「祝福反复刷」核心一：本服光环名带「（等级 N）」后缀
-- ------------------------------------------------------------
-- 本服（无限服）的法术书 / 光环名带等级后缀，例如「正义圣印（等级 2）」
-- 「智慧祝福（等级 3）」。而 WR_GetUnitBuffTime 是按名字**精确匹配**的
-- （Core/Core_Functions.lua 的 WR_GetAuraInfoCore：`name == AuraName`），
-- "智慧祝福" ~= "智慧祝福（等级 3）" → 恒返回 0
--   → WR_PaladinBlessing_Needs 恒 true
--   → 每 WR_PAL_BLESS_PROMPT_CD(10 秒) 重新点亮一次祝福色块
--   → AHK 读到常亮色块再按一次 → 用户看到的「反复刷 buff」。
-- 圣印模块（Paladin_Forever.lua:1391）踩过同一个坑，做法照搬：
--   Lua 5.1 字符类按字节匹配，[（(] 这种写法匹配不了多字节全角括号，
--   必须分两步用字面量匹配 —— 先全角「（等级 N）」，再半角「(等级 N)」。
function WR_PalBless_StripRankSuffix(nm)
    if type(nm) ~= "string" then return nil end
    local s = string.gsub(nm, "%s*（等级%s*%d+）%s*$", "")
    if s == nm then
        s = string.gsub(nm, "%s*%(等级%s*%d+%)%s*$", "")
    end
    return s
end

-- 光环名归一成「基础名」；名字读不到（secret / nil / 非字符串）→ nil
function WR_PalBless_BaseName(nm)
    local plain = WR_PalBless_Plain(nm)
    if type(plain) ~= "string" then return nil end
    return WR_PalBless_StripRankSuffix(plain)
end

-- 第二通道：直接扫插件光环缓存（WR_AuraCache[unit].HELPFUL），按基础名比较。
-- 返回该种祝福剩余秒数：0 = 缓存里没有 / 缓存不可用；999 = 有但到期时间不可读。
-- ★ 语义约定（与首通道一致）：这里只回答「明确看到了什么」。
--   「缓存不可用 / 名字读不到」一律返回 0，让 Needs 保持原来的保守语义
--   （脱战补 buff，漏补比多补更糟）；重复提示由 JustCast 宽限 + pending 收口，
--   不靠这里把「读不到」猜成「有」。
function WR_PaladinBlessing_BuffRemainFromCache(unit, kind)
    local rec = WR_PAL_BLESS_KINDS[kind]
    if not rec then return 0 end
    local cache = type(WR_AuraCache) == "table" and WR_AuraCache[unit] or nil
    local helpful = cache and cache.HELPFUL
    if type(helpful) ~= "table" or #helpful <= 0 then return 0 end

    local want = {}
    want[rec.normal] = true
    want[rec.greater] = true
    local now = GetTime()
    local best = 0
    for i = 1, #helpful do
        local aura = helpful[i]
        if type(aura) == "table" then
            local base = WR_PalBless_BaseName(aura.name)
            if base ~= nil and want[base] then
                local exp = WR_PalBless_Num(aura.expirationTime, 999)
                if exp == 999 or exp == 0 then
                    -- 存在但到期时间不可读 → 999 哨兵（Needs 里按「已有」处理）
                    if best < 999 then best = 999 end
                else
                    local left = exp - now
                    if left > 0 then
                        if left > best then best = left end
                    end
                    -- left <= 0：缓存残留的已过期条目 → 不算有
                end
            end
        end
    end
    return best
end

function WR_PaladinBlessing_BuffRemain(unit, kind)
    local rec = WR_PAL_BLESS_KINDS[kind]
    if not rec then return 0 end
    local best = 0

    -- ① 快路径：精确名匹配（WR_GetUnitBuffTime 读的也是同一份缓存）
    if WR_PalBless_Fn(WR_GetUnitBuffTime) then
        local names = { rec.normal, rec.greater }
        for i = 1, #names do
            local ok, t = WR_PalSafe_Call(2, WR_GetUnitBuffTime, unit, names[i])
            -- ★ 2026-11-12：secret / 非数字一律当「读不到」，不得进比较
            t = WR_PalBless_Num(t, 0)
            if ok and t > best then best = t end
        end
    end

    -- ② 第二通道：缓存基础名扫描（容错「（等级 N）」后缀 / 全角半角括号）
    local cached = WR_PaladinBlessing_BuffRemainFromCache(unit, kind)
    if cached > best then best = cached end
    return best
end

function WR_PaladinBlessing_Needs(unit, kind)
    local remain = WR_PaladinBlessing_BuffRemain(unit, kind)
    -- 999 = 存在但到期时间不可读（secret 兜底）→ 视为已有，不补
    if remain >= 900 then return false end
    if remain <= 0 then return true end                          -- 没有
    return remain < (WR_PAL_BLESS_REFRESH_LEAD or 60)           -- 快到期
end

-- ============================================================
-- ★★ 2026-11-12 修复「祝福反复刷」核心五：光环「整块读不到」的指数退避
-- ------------------------------------------------------------
-- 区分两种「BuffRemain == 0」，语义完全不同：
--   ① WR_AuraCache[unit] 是 table，只是里面没有这条祝福
--      = 真的没有 → 每 WR_PAL_BLESS_PROMPT_CD(10 秒) 重试一次是对的
--        （AHK 漏按 / 祝福被驱散后要能尽快补上）；
--   ② WR_AuraCache[unit] 不是 table（战斗中 C_UnitAuras 抛 secret、扫描被
--      pcall 放弃、单位刚出现还没扫过）
--      = 读不到 →「有」和「没有」无法区分 → 绝不能按 10 秒节奏刷。
-- 旧实现两种都按 10 秒刷，而 JustCast/pending 宽限只有 8 秒，
-- 一过就回到「每 10 秒亮一次色块」→ AHK 每 10 秒按一次 → 反复刷 buff。
-- 现在 ② 走指数退避：10 → 30 → 60 → 120 → 300 秒封顶。
-- 祝福本身持续 30~60 分钟，最坏晚 5 分钟补上，远好过每 10 秒白刷一次。
-- 一旦光环恢复可读，退避立刻清零，回到正常 10 秒节奏。
-- ============================================================
function WR_PaladinBlessing_CacheUnreadable(unit)
    if type(WR_AuraCache) ~= "table" then return true end
    local cache = WR_AuraCache[unit]
    if type(cache) ~= "table" then return true end
    if type(cache.HELPFUL) ~= "table" then return true end
    return false
end

local function WR_PaladinBlessing_BackoffKey(unit, kind)
    return tostring(unit) .. "|" .. tostring(kind)
end

-- 退避闸：true = 本 tick 允许点亮
function WR_PaladinBlessing_BackoffAllow(unit, kind)
    local t = WR_PaladinBlessing_Backoff
    if type(t) ~= "table" then return true end
    local rec = t[WR_PaladinBlessing_BackoffKey(unit, kind)]
    if type(rec) ~= "table" then return true end
    local nextAt = WR_PalBless_Num(rec.nextAt, 0)
    if nextAt <= 0 then return true end
    return GetTime() >= nextAt
end

-- 在「读不到」状态下点亮了一次 → 推进退避等级
function WR_PaladinBlessing_BackoffBump(unit, kind)
    if type(WR_PaladinBlessing_Backoff) ~= "table" then
        WR_PaladinBlessing_Backoff = {}
    end
    local key = WR_PaladinBlessing_BackoffKey(unit, kind)
    local rec = WR_PaladinBlessing_Backoff[key]
    if type(rec) ~= "table" then rec = {} end
    local seq = WR_PAL_BLESS_UNREADABLE_BACKOFF or { 10 }
    local lv = (WR_PalBless_Num(rec.level, 0) or 0) + 1
    if lv > #seq then lv = #seq end
    rec.level = lv
    rec.nextAt = GetTime() + (seq[lv] or 10)
    WR_PaladinBlessing_Backoff[key] = rec
end

-- 光环恢复可读 / 确认不需要补 → 清零退避，回到正常节奏
function WR_PaladinBlessing_BackoffClear(unit, kind)
    local t = WR_PaladinBlessing_Backoff
    if type(t) ~= "table" then return end
    t[WR_PaladinBlessing_BackoffKey(unit, kind)] = nil
end

-- ============================================================
-- ★★ 2026-11-12 修复「祝福反复刷」核心二：真实施放事件兜底
-- ------------------------------------------------------------
-- 光环读值失败时（secret / 缓存未命中 / 扫描被放弃）BuffRemain=0，
-- 与「真的没有」无法区分。WR_Forever_LastPlayerCast 由
-- UNIT_SPELLCAST_SUCCEEDED（unit == "player"）维护，是比光环读值可靠的证据：
-- 只要刚刚确实打出过这条祝福，就认为它在身，宽限期内不再提示。
--
-- ★ 为什么要再加一层「本地闩锁」：
--   WR_Forever_LastPlayerCast 只保留**最近一次**施法。玩家打出祝福后往往立刻
--   接一个圣印 / 审判 / 攻击，这个全局记录马上被覆盖 → JustCast 立刻变 false
--   → 保护在 0.1 秒内失效，等于没加。
--   所以每次轮询到「最近一次施法是某条祝福」就把它记进本模块自己的表，
--   之后即使全局记录被别的技能覆盖，宽限期内仍认这条祝福刚施放过。
-- ============================================================
WR_PaladinBlessing_LastCastAt = WR_PaladinBlessing_LastCastAt or {}
-- ★★★ 2026-11-12：同表配套的「这次点亮是给哪个单位的」。
--   JustCast 必须按单位判定（见函数内注释），但施放成功事件里读不到 unit，
--   所以用「最近一次点亮该祝福时写的单位」作为该条记录的归属单位。
WR_PaladinBlessing_LastCastUnit = WR_PaladinBlessing_LastCastUnit or {}

-- 记录「这条祝福刚刚被点亮、点亮目标是 unit」（供 JustCast 按单位判定）
function WR_PaladinBlessing_NoteCastUnit(spellName, unit)
    if type(spellName) ~= "string" or spellName == "" then return end
    if type(unit) ~= "string" or unit == "" then return end
    if type(WR_PaladinBlessing_LastCastUnit) ~= "table" then
        WR_PaladinBlessing_LastCastUnit = {}
    end
    WR_PaladinBlessing_LastCastUnit[spellName] = unit
end

-- 把「最近一次施法」里属于祝福的那条闩锁下来（每 tick 调一次，开销极小）
local function WR_PaladinBlessing_LatchLastCast()
    local rec = WR_Forever_LastPlayerCast
    if type(rec) ~= "table" then return end
    local t = WR_PalBless_Num(rec.time, 0)
    if t <= 0 then return end
    local nm = WR_PalBless_Plain(rec.spellName)
    if type(nm) ~= "string" then return end
    local base = WR_PalBless_StripRankSuffix(nm)
    if type(base) ~= "string" then return end
    if type(WR_PaladinBlessing_LastCastAt) ~= "table" then
        WR_PaladinBlessing_LastCastAt = {}
    end
    local tbl = WR_PaladinBlessing_LastCastAt
    local cur = WR_PalBless_Num(tbl[base], 0)
    if t > cur then tbl[base] = t end
    -- 顺便清理过期条目，避免表无限增长
    local now = GetTime()
    for k, v in pairs(tbl) do
        if (now - WR_PalBless_Num(v, 0)) > (WR_PAL_BLESS_AFTER_CAST_GRACE or 8) * 2 then
            tbl[k] = nil
        end
    end
end

function WR_PaladinBlessing_JustCast(spellName, unit)
    if type(spellName) ~= "string" or spellName == "" then return false end
    local grace = WR_PAL_BLESS_AFTER_CAST_GRACE or 8
    local now = GetTime()

    -- ★★★ 2026-11-12 用户口径「给队友加也是这样，补的时机太晚」：
    --   本函数原来**只按法术名**判定 —— 给 player 打出「智慧祝福」后，
    --   接下来 8 秒内 JustCast("智慧祝福") 对**所有单位**都返回 true，
    --   于是每个队友都要排队等 8 秒（修复前实测 0.1/8.2/16.3/24.4/32.5 秒）。
    --   祝福是按单位生效的：给 A 加过，跟 B 一点关系都没有。
    --   现在按「最近一次点亮是为哪个单位」分流：
    --     · 记录里的单位 == 当前单位 → 才是「这个单位刚加过」，抑制；
    --     · 记录里的单位 ≠ 当前单位 → 完全放行（别的单位刚加，不影响这个单位）；
    --     · 单位未知（旧调用点 / 夹具只传法术名）→ 保持原语义，抑制。
    local function otherUnitLit(base)
        local u = WR_PaladinBlessing_LastCastUnit
        if type(u) ~= "table" then return false end
        local who = u[base]
        if type(who) ~= "string" then return false end
        if type(unit) ~= "string" or unit == "" then return false end
        return who ~= unit
    end

    -- ① 本地闩锁（不受后续别的技能覆盖影响）
    local tbl = WR_PaladinBlessing_LastCastAt
    if type(tbl) == "table" then
        local at = WR_PalBless_Num(tbl[spellName], 0)
        if at > 0 and (now - at) <= grace then
            return not otherUnitLit(spellName)
        end
    end

    -- ② 全局「最近一次施法」（闩锁还没建立时的即时通道）
    local rec = WR_Forever_LastPlayerCast
    if type(rec) ~= "table" then return false end
    local t = WR_PalBless_Num(rec.time, 0)
    if t <= 0 then return false end
    if (now - t) > grace then return false end
    local nm = WR_PalBless_Plain(rec.spellName)
    if type(nm) ~= "string" then return false end
    -- 名字可能带「（等级 N）」后缀 → 用基础名比较
    local base = WR_PalBless_StripRankSuffix(nm)
    if not (base == spellName or nm == spellName) then return false end
    return not otherUnitLit(spellName)
end

-- ============================================================
-- ★★ 2026-11-12 修复「祝福反复刷」核心三：同单位同祝福「已点亮待确认」状态
-- ------------------------------------------------------------
-- 色块点亮后 AHK 需要一点时间读色再按键；这期间 Buff 还没上身，
-- 下一 tick 的 Needs 仍为 true → 又亮一次（AHK 连按 → 反复刷）。
-- 记录 pendingAt 做两道收口：
--   · 宽限期内（PENDING_TTL）不再重复点亮同一单位同一祝福；
--   · 一旦 Needs 变 false（buff 真的上身了）→ 立刻 HideNow 熄灭色块，
--     不再等 HideSkillLater 的保持到期（那 1.5 秒里 AHK 会继续连按）。
-- 表结构：[unit .. "|" .. kind] = { at = GetTime(), slot = 槽位, spell = 法术名 }
-- ============================================================
WR_PaladinBlessing_PendingLit = WR_PaladinBlessing_PendingLit or {}

local function WR_PaladinBlessing_PendingKey(unit, kind)
    return tostring(unit) .. "|" .. tostring(kind)
end

-- 记录一次点亮
function WR_PaladinBlessing_NoteLit(unit, kind, spellName, slot)
    if type(WR_PaladinBlessing_PendingLit) ~= "table" then
        WR_PaladinBlessing_PendingLit = {}
    end
    WR_PaladinBlessing_PendingLit[WR_PaladinBlessing_PendingKey(unit, kind)] = {
        at = GetTime(),
        slot = slot,
        spell = spellName,
    }
    -- ★★★ 2026-11-12：同步登记「这条祝福这次是给哪个单位的」，
    --   供 JustCast 按单位判定（避免给一个人加完就挡住其他人 8 秒）。
    if type(WR_PaladinBlessing_NoteCastUnit) == "function" then
        WR_PaladinBlessing_NoteCastUnit(spellName, unit)
    end
end

-- 该单位该祝福是否「刚刚点亮、还在待确认窗口内」
function WR_PaladinBlessing_IsPendingLit(unit, kind)
    local t = WR_PaladinBlessing_PendingLit
    if type(t) ~= "table" then return false end
    local rec = t[WR_PaladinBlessing_PendingKey(unit, kind)]
    if type(rec) ~= "table" then return false end
    local at = WR_PalBless_Num(rec.at, 0)
    if at <= 0 then return false end
    if (GetTime() - at) > (WR_PAL_BLESS_PENDING_TTL or 8) then
        -- 超时自动清掉，避免表无限增长
        t[WR_PaladinBlessing_PendingKey(unit, kind)] = nil
        return false
    end
    return true
end

-- 清掉 pending（buff 已确认上身 / 施放成功时调用）
function WR_PaladinBlessing_ClearPendingLit(unit, kind)
    local t = WR_PaladinBlessing_PendingLit
    if type(t) ~= "table" then return nil end
    local key = WR_PaladinBlessing_PendingKey(unit, kind)
    local rec = t[key]
    t[key] = nil
    return rec
end

-- ============================================================
-- 停手条件：战斗中 / 坐骑 / 吃喝 / 死亡 / 打字中不补
-- ============================================================
function WR_PaladinBlessing_Blocked()
    -- ★ 2026-11-12：全部改成「明确 true 才拦」的字面量比较。
    --   这些接口在 12.0 战斗锁定期会回 secret boolean，直接 `if v` 当条件用就抛
    --   secret 值错误。secret 已被 WR_PalSafe_Call 收敛成 nil，nil == true 恒假，
    --   语义上 = 读不到就按「不阻止」处理（Blocked 只在脱战补祝福时被调用，
    --   读不到时放过比整段罢工更安全）。
    -- ★★★ 2026-11-13：InCombatLockdown 是最可靠的战斗判定。UnitAffectingCombat
    --   在战斗 secret 化时读回 nil → 旧逻辑会误判「不在战斗」→ 祝福模块继续跑，
    --   CastDirect 因战斗锁返回 false → 回落焦点流程 → 防骑每 tick 设焦点 party2。
    --   这里直接用 InCombatLockdown 兜底，战斗中一律不补祝福。
    if WR_PalBless_Fn(InCombatLockdown) then
        local okL, locked = WR_PalSafe_Call(2, InCombatLockdown)
        if okL and locked == true then return true end
    end
    if WR_PalBless_Fn(UnitAffectingCombat) then
        local ok, v = WR_PalSafe_Call(2, UnitAffectingCombat, "player")
        if ok and v == true then return true end
    end
    if WR_PalBless_Fn(UnitIsDeadOrGhost) then
        local ok, v = WR_PalSafe_Call(2, UnitIsDeadOrGhost, "player")
        if ok and v == true then return true end
    end
    if WR_PalBless_Fn(IsMounted) then
        local ok, v = WR_PalSafe_Call(2, IsMounted)
        if ok and v == true then return true end
    end
    if WR_PalBless_Fn(UnitInVehicle) then
        local ok, v = WR_PalSafe_Call(2, UnitInVehicle, "player")
        if ok and v == true then return true end
    end
    if WR_PalBless_Fn(ChatEdit_GetActiveWindow) then
        -- 返回的是输入框 frame 对象（非布尔），nil / false 都表示没在打字
        local ok, v = WR_PalSafe_Call(2, ChatEdit_GetActiveWindow)
        if ok and v ~= nil and v ~= false then return true end
    end
    if WR_PalBless_Fn(WR_GetUnitBuffTime) then
        local ok, t = WR_PalSafe_Call(2, WR_GetUnitBuffTime, "player", WR_PAL_BLESS_STOP_BUFFS, nil, "NAME")
        t = WR_PalBless_Num(t, 0)                               -- secret / nil → 0
        if ok and t > 0 then return true end
    end
    return false
end

-- ============================================================
-- 焦点槽：给队友加时先切焦点（含自己 → 焦点设为自己）
-- ============================================================
-- ============================================================
-- ★★ 2026-11-12：小队/团队「直施动态宏」—— 全程不切焦点
-- ------------------------------------------------------------
-- 色块槽 95（键位 ALT-F5，原空占位，Paladin_Macros.lua 已启用）：每次补
-- 小队/团队祝福前，先把该键位的宏文本重写为
--     /cast [target=partyN 或 raidN] 祝福名
-- 再点亮槽 95，AHK 识别颜色后按 ALT-F5 → 宏直接对该单位施放祝福，
-- 与当前目标、焦点完全无关。宏更新走 WR_CreateMacro（SetAttribute 同步生效，
-- 只在脱战调用，无战斗锁限制）；同键幂等覆盖，不产生宏文件垃圾。
-- ============================================================
WR_PAL_BLESS_UNIT_SLOT = 95
WR_PAL_BLESS_UNIT_KEY = "ALT-F5"   -- 槽 95 对应的宏键位（与 Paladin_Macros.lua 注册一致）

function WR_PaladinBlessing_FocusSlot(unit)
    if unit == "player" then return 146 end                   -- /focus [@player,nocombat]
    local i = tonumber(string.match(unit or "", "^party(%d+)$"))
    if i and i >= 1 and i <= 4 then return 175 + i end       -- 176~179
    local j = tonumber(string.match(unit or "", "^raid(%d+)$"))
    if j and j >= 1 and j <= 25 then return 120 + j end      -- 121~145
    return nil
end

-- ★★★ 2026-11-13 修复（防骑被奶骑自动焦点牵连）：
--   祝福的「焦点流程」本质只服务于神圣骑的 [@focus] 祝福宏。防护/惩戒没有
--   [@focus] 祝福宏；一旦共享祝福模块在直施不可用（战斗锁定 / 回读失败）时
--   回落到焦点流程，就会点亮 176-179 焦点色块 → AHK 按下 → 把队友设成焦点。
--   非神圣专精直接禁止回落：宁可不补祝福，也绝不抢焦点。
function WR_PaladinBlessing_FocusFlowAllowed()
    local fn = WR_GetMyTalent
    -- type(fn)=="userdata" 兼容离线夹具里的 Python 可调用对象（同 WR_PalBless_Fn 口径）
    if type(fn) ~= "function" and type(fn) ~= "userdata" then return true end
    local ok, spec = pcall(fn)
    if not ok then return true end
    return spec == "神圣"
end

-- ★★★ 2026-11-12 用户口径「队友不在附近时，队友的祝福会上到自己身上」：
--   「焦点是不是该单位」的判定原来只看 UnitIsUnit("focus", unit)，而且
--   **读不到就返回 true（当作已切好）**。后者正是自施的来源：
--     · 战斗中 UnitIsUnit 可能返回 secret → WR_PalSafe_Call 收敛成 nil；
--     · 于是 FocusIs 返回 true → 走「焦点已就位」分支 → 点亮 [@focus] 祝福宏；
--     · 而焦点此刻完全可能**还停在自己身上**（单人行 146 号槽就是
--       /focus [@player]，给队友切焦点失败时焦点就留在自己）
--       → 祝福打到自己身上，与单人选的那条互相顶掉 = 用户说的「冲突」。
--   修法：给队友补祝福时，先独立探测一次「焦点是不是自己」。
--     焦点=自己 → 一律返回 false（强制走切焦点流程），绝不进 [@focus] 分支。
local function WR_PaladinBlessing_FocusIs(unit)
    if not WR_PalBless_Fn(UnitIsUnit) then return true end    -- 接口不存在：无从判断
    local isSelf = nil
    -- ① 给队友补时，先确认焦点没停在自己身上（这是自施的直接来源）
    if unit ~= "player" then
        local okP, selfV = WR_PalSafe_Call(2, UnitIsUnit, "focus", "player")
        if okP and selfV == true then return false end
        if okP and selfV == false then isSelf = false end
    end
    -- ② 正常判定：焦点是否就是目标单位
    local ok, v = WR_PalSafe_Call(2, UnitIsUnit, "focus", unit)
    -- ★ 原写法 `return v and true or false` 会把 secret boolean 当条件，
    --   这里必须用字面量比较；secret（→nil）视为「读不到」。
    if ok and v == true then return true end
    if ok and v == false then return false end
    -- ③ 读不到：原本「当作已切好」→ 但给队友补时这会把祝福打给自己。
    --   现在改成「只有确认焦点不是自己才放行」，否则强制走切焦点流程。
    if unit ~= "player" then
        if isSelf == false then return true end
        return false            -- 无法确认焦点不是自己 → 宁可不点亮
    end
    return true
end

local function WR_PaladinBlessing_Show(slot, text)
    -- ★★★ 2026-11-12 用户口径「技能不够蓝释放时，应当不亮色块，导致一直按按键」：
    --   祝福也吃法力（普通祝福 30 级 rank 约 45~90 蓝）。这里与 WR_ColorFrame_ShowSkill
    --   的总闸共用同一判定；拦下时必须熄灭该槽位 —— 色块是「亮着就一直按」的模型，
    --   只 return false 不熄灭的话上一 tick 的色块会一直挂着 → AHK 连按空键。
    --   用 pcall 探测（不用 type()=="function"：本文件夹具里是 userdata）。
    if WR_SoD_NotEnoughPower ~= nil and type(text) == "string" then
        local okN, notEnough = pcall(WR_SoD_NotEnoughPower, text)
        if okN and notEnough == true then
            if WR_HideSkillColorSlot ~= nil then
                pcall(WR_HideSkillColorSlot, text, slot)
            end
            return false
        end
    end
    if WR_PalBless_Fn(WR_ColorFrame_Show) then
        return WR_ColorFrame_Show(slot, text)
    end
    -- 离线夹具 / 无色彩框架时退化为 WR_ColorFrame_ShowSkill
    if WR_PalBless_Fn(WR_ColorFrame_ShowSkill) then
        return WR_ColorFrame_ShowSkill(text, slot)
    end
    return false
end

-- ============================================================
-- ★★★ 2026-11-12 用户口径「队友不在附近时，队友的祝福会上到自己身上
--   导致与个人选择的祝福冲突」—— 直施/焦点宏的「条件回退」硬闸
-- ------------------------------------------------------------
-- 【根因：WoW 宏的条件回退（macro fallthrough）】
--   `/cast [@party1] 力量祝福` 里的 `[@party1]` 只是**条件**，不是硬目标：
--     · 条件成立 → 对该单位施放；
--     · 条件不成立（离队 / 死亡 / 单位 token 失效）→ 该条件被**丢弃**，
--       `/cast` 退化成「无目标施放」→ 落到当前目标；没有目标时，
--       友善法术就落到**自己**身上。
--   于是「给队友补祝福」变成了「给自己补祝福」，与单人选的那条互相顶掉
--   = 用户看到的「祝福冲突」。
--
-- 【修法】宏文本改成两段式，第一条 /stopmacro 是**硬闸**：
--     /stopmacro [@party1,noexists] [@party1,dead] [@party1,harm]
--     /cast [@party1,help] 力量祝福
--   · 目标无效时，/stopmacro 让**整条宏立刻结束**（什么都不做），
--     绝不会走到 /cast，也就不存在「回退成自施」；
--   · /cast 行再带 [,help] 双保险：即使 stopmacro 因故没拦住，
--     非友善目标也不会被施放，而且带条件的目标行不会退化成无目标施放
--     （只要条件里含 help/exists 这类「选择性」条件，客户端就不会回退）。
--   · 单人自施（91~93）不受影响：那是明确的 [@player] 自施宏。
-- ============================================================
function WR_PaladinBlessing_DirectMacroText(unit, spellName)
    if type(unit) ~= "string" or unit == "" then return nil end
    if type(spellName) ~= "string" or spellName == "" then return nil end
    local u = "@" .. unit
    -- 前置闸：不存在 / 死亡 / 非友善 → 整条宏直接结束（绝不回退成自施）
    local guard = string.format(
        "/stopmacro [%s,noexists] [%s,dead] [%s,nohelp]", u, u, u)
    -- 施放行：显式 help 限定 + 显式单位，条件不成立时客户端不会退化成无目标施放
    local cast = string.format("/cast [%s,help] %s", u, spellName)
    return guard .. "\n" .. cast
end

-- ★★ 2026-11-12：直施执行 —— 重写槽 95 宏文本指向 unit，再点亮色块。
--   返回 true = 已点亮（AHK 按 ALT-F5 即对该单位施放）；
--   返回 false = 宏系统不可用 / 宏文本没写进去，调用方回落焦点流程。
--   · WR_CreateMacro 同键幂等覆盖、SetAttribute 同步生效，且只在脱战调用；
--   · 槽 95 的宏初始注册在 Paladin_Macros.lua（ALT-F5），这里只做重写。
--   · ★★★ 2026-11-12：写完后**回读 macrotext 校验**。SetAttribute 在战斗锁定
--     期会被静默丢弃，写不进去时宏还是上一次的旧目标（甚至初始自施文本）——
--     这时点亮色块 = AHK 按下去把祝福打给了错误的人。宁可不补，也不能误施。
function WR_PaladinBlessing_CastDirect(unit, spellName)
    -- ★★★ 2026-11-13：战斗锁定硬闸。
    --   槽 95 是 SecureActionButtonTemplate，战斗中 SetAttribute("macrotext")
    --   会被**静默丢弃**（写不进去）；此时点亮 = AHK 按下去执行上一次的旧文本
    --   —— 旧文本可能是 [@player,...] 自施文本，这就是「小队祝福上到自己、
    --   顶掉个人祝福」的主通道。战斗锁定期一律拒绝直施（回落焦点流程：
    --   焦点宏是注册期写好的静态文本，不依赖战斗中重写）。
    if WR_PalBless_Fn(InCombatLockdown) then
        local okL, locked = WR_PalSafe_Call(2, InCombatLockdown)
        if okL and locked == true then return false end
    end
    if not WR_PalBless_Fn(WR_CreateMacro) then return false end
    if type(unit) ~= "string" or unit == "" then return false end
    if type(spellName) ~= "string" or spellName == "" then return false end
    local text = WR_PaladinBlessing_DirectMacroText(unit, spellName)
    if not text then return false end

    -- ★★★ 2026-11-13 用户口径「队友不在身边、小队祝福开着、选中敌方目标时祝福刷到自己身上，
    --   把个人祝福顶掉」—— 点亮之前的**目标合法性硬闸**。
    --   根因：直施是「盲点亮」。宏里的 /stopmacro [@partyN,nohelp] 只管客户端拿到手之后往哪泼，
    --   管不了 AHK 这一次按键最终落到谁身上：
    --     ① 玩家当前选中的是敌方目标 —— 给友方补祝福的语境根本不成立；
    --     ② 宏文本回读失败（战斗锁定 / SetAttribute 被丢），槽 95 还是上一次的旧目标，
    --        甚至初始那行「自施」文本 —— 点亮后按键直接落到玩家自己身上；
    --   两种情况的共同结果都是「祝福打到自己」→ 与单人行 / 常驻那条互相顶掉 = 冲突。
    --   处理：命中任一不合法条件就**不点亮**，队列推进到下一个单位。
    --   读不到（secret → nil）一律放行：脱战可读，宁可放过也不要整队不补。
    if type(unit) == "string" and unit ~= "player" then
        if WR_PalBless_Fn(UnitIsDeadOrGhost) then
            local okD, deadD = WR_PalSafe_Call(2, UnitIsDeadOrGhost, unit)
            if okD and deadD == true then return false end
        end
        if WR_PalBless_Fn(UnitIsUnit) then
            local okS, isSelfU = WR_PalSafe_Call(2, UnitIsUnit, unit, "player")
            if okS and isSelfU == true then return false end      -- 单位 token 已被压成自己
            local isPlr = nil
            if WR_PalBless_Fn(UnitIsPlayer) then
                local okQ, vQ = WR_PalSafe_Call(2, UnitIsPlayer, unit)
                if okQ then isPlr = vQ end
            end
            if isPlr == false then
                local okT, isTgt = WR_PalSafe_Call(2, UnitIsUnit, unit, "target")
                if okT and isTgt == true then return false end   -- 当前目标就是它，且不是玩家 → 敌方
            end
        end
    end

    local key = WR_PAL_BLESS_UNIT_KEY or "ALT-F5"
    WR_CreateMacro(key, text)

    -- 回读校验：宏文本必须真的变成我们要的那条，否则不点亮
    if type(_G) == "table" then
        local btn = _G["WR_HiddenMacroBtn_" .. key]
        if btn and WR_PalBless_Fn(btn.GetAttribute) then
            local ok, cur = WR_PalSafe_Call(2, btn.GetAttribute, btn, "macrotext")
            cur = WR_PalBless_Plain(cur)
            -- ★★★ 2026-11-13：回读校验改为**严格**——「读不到 / 空」同样视为写失败。
            --   旧写法只在「读到了且不同」时拦截；回读本身被 secret 化 / 返回空时
            --   会放行点亮 → 按键执行旧宏文本（可能是 [@player] 自施）→ 误施到自己。
            if (not ok) or type(cur) ~= "string" or cur == "" or cur ~= text then
                return false        -- 写不进去（战斗锁定 / 异常）→ 不点亮
            end
        end
    end

    return WR_PaladinBlessing_Show(WR_PAL_BLESS_UNIT_SLOT or 95, spellName)
end

-- ============================================================
-- ★★ 2026-11-12 修复「祝福反复刷」核心四：光环缓存缺失时自愈重扫
-- ------------------------------------------------------------
-- Core/Core_Functions.lua 的 WR_ScanAurasForUnit（:312）用 pcall(doScan) 包住
-- 整段扫描：一旦命中 secret 单位（战斗中很常见）就放弃本次扫描、保留旧缓存
-- （可能为 nil），但仍把 WR_AuraCacheScanned[unit] 标成 true。之后
-- WR_GetAuraInfoCore 读到 `not cache` 直接 return 0,0,0
--   → BuffRemain = 0 → Needs 恒 true → 每 10 秒重亮一次色块 → 反复刷祝福。
-- 处理：cache 为 nil 时补一次强制重扫；带 2 秒节流，避免「缓存永远填不上」
-- 时把热路径变成每 tick 全量扫描（不修改 Core，那是全职业共享路径）。
-- ============================================================
WR_PaladinBlessing_CacheRepairAt = WR_PaladinBlessing_CacheRepairAt or 0
WR_PaladinBlessing_WasInCombat = WR_PaladinBlessing_WasInCombat or false

local function WR_PaladinBlessing_RepairPlayerAuraCache(force)
    if type(WR_AuraCache) ~= "table" then return end
    if WR_AuraCache["player"] ~= nil and not force then return end
    local now = GetTime()
    if not force and (now - (WR_PaladinBlessing_CacheRepairAt or 0)) < 2 then return end
    WR_PaladinBlessing_CacheRepairAt = now
    if WR_PalBless_Fn(WR_ForceRefreshAuraCache) then
        pcall(WR_ForceRefreshAuraCache, "player")
    elseif type(WR_AuraCacheScanned) == "table" then
        WR_AuraCacheScanned["player"] = false
    end
end

-- ★★★ 2026-11-12 用户口径「给队友加也是这样，补的时机太晚」——队友缓存自愈。
-- ------------------------------------------------------------
-- 旧实现的自愈重扫**只针对 player**（WR_PaladinBlessing_RepairPlayerAuraCache）。
-- 而 Core/Core_Functions.lua 的 WR_ScanAurasForUnit（:312）把整段扫描包在
-- pcall 里：战斗中一旦命中 secret 单位就放弃本次扫描、保留旧缓存（可能是 nil），
-- 但仍把 WR_AuraCacheScanned[unit] 标成 true —— 之后 WR_EnsureAuraCached
-- 看到「已扫描」就再也不会重扫这个单位。
-- 结果：player 因为有脱战 force 重扫能自愈，**队友却永久读不到**：
--   · BuffRemain 恒 0 → Needs 恒 true（看起来「队友一直缺祝福」）；
--   · 走进 CacheUnreadable 指数退避 → 10/30/60/120/300 秒才试一次；
--   · 而且每次点亮都会被 pending 收口，实际「补一次要等好几分钟」。
-- 处理：把自愈重扫扩展到所有被遍历的单位（仍带节流，避免热路径全量扫描）。
WR_PaladinBlessing_UnitRepairAt = WR_PaladinBlessing_UnitRepairAt or {}

local function WR_PaladinBlessing_RepairUnitAuraCache(unit)
    if type(unit) ~= "string" or unit == "" then return end
    -- ★ player 走上面专用的 RepairPlayerAuraCache（含「脱战瞬间 force / 战斗 secret
    --   态只走节流」的语义），这里不重复处理，避免把战斗热路径变成全量扫描。
    if unit == "player" then return end
    if type(WR_AuraCache) ~= "table" then return end
    if WR_AuraCache[unit] ~= nil then return end          -- 缓存正常，无需重扫
    if type(WR_PaladinBlessing_UnitRepairAt) ~= "table" then
        WR_PaladinBlessing_UnitRepairAt = {}
    end
    local now = GetTime()
    -- 每个单位独立节流 2 秒，避免「全队都读不到」时每 tick 扫 25 个单位
    if (now - WR_PalBless_Num(WR_PaladinBlessing_UnitRepairAt[unit], 0)) < 2 then return end
    WR_PaladinBlessing_UnitRepairAt[unit] = now
    if WR_PalBless_Fn(WR_ForceRefreshAuraCache) then
        pcall(WR_ForceRefreshAuraCache, unit)
    elseif type(WR_AuraCacheScanned) == "table" then
        WR_AuraCacheScanned[unit] = false
    end
end

-- ★★★ 2026-11-12 用户口径「脱战了没有第一时间补祝福」「给队友加也是这样，
--   补的时机太晚」——GCD 间隔闸。
-- ------------------------------------------------------------
-- 祝福是占 GCD 的主动技能。旧实现完全没有这层节流：
--   · 脱战瞬间 tick 把 player 点亮 → AHK 按 ALT-F1/F2/F3 → 祝福打出（吃 GCD）；
--   · 0.1 秒后 tick 又点亮 party1（重写 ALT-F5 宏 + 亮色块）→ AHK 立刻按
--     → **此时 GCD 还没转完，客户端直接拒绝** → 色块灭了但 buff 没上身；
--   · pending 再把该单位锁住（旧值 8 秒）→ 才轮到 party2……如此排队。
--   离线实测（修复前）：4 个队友分别在第 0.1 / 8.2 / 16.3 / 24.4 / 32.5 秒
--   才拿到祝福 —— 这就是「补得太晚」。
--   现在点亮一次后，统一等 WR_PAL_BLESS_CAST_GAP（一个 GCD）再处理下一个单位；
--   既不浪费按键（不会撞 GCD），也不会让队列变成 8 秒一跳。
--   修复后实测：0.1 / 1.4 / 2.7 / 4.0 / 5.3 秒，相邻间隔稳定 ≈ 一个 GCD。
function WR_PaladinBlessing_CastGapReady()
    local at = WR_PaladinBlessing_LastLightAt
    if type(at) ~= "number" or at <= 0 then return true end
    local now = GetTime()
    -- 防御：时钟倒退（离线夹具 reset 时间 / 极端情况下 GetTime 回绕）时，
    -- 绝不能把「上次点亮」永远当成未来而永久卡住补祝福。
    if now < at then
        WR_PaladinBlessing_LastLightAt = nil
        return true
    end
    return (now - at) >= (WR_PAL_BLESS_CAST_GAP or 1.2)
end

function WR_PaladinBlessing_NoteLightAt()
    WR_PaladinBlessing_LastLightAt = GetTime()
end

-- ============================================================
-- ★★ 2026-11-12：点亮后「待确认」状态的收口
-- ------------------------------------------------------------
-- 每 tick 检查一次：某条已点亮的祝福如果 Needs 已经变 false（buff 真的上身），
-- 立刻 HideNow 熄灭色块 —— 不再等 HideSkillLater 的保持到期，那 1.5 秒里
-- AHK 会继续连按同一个色块 → 用户看到的「反复刷」。
-- 超时（PENDING_TTL）仍为 true 的条目直接清掉，允许下一轮重新提示（不能永久卡死）。
-- ============================================================
function WR_PaladinBlessing_SettlePending()
    local t = WR_PaladinBlessing_PendingLit
    if type(t) ~= "table" then return end
    local now = GetTime()
    for key, rec in pairs(t) do
        if type(rec) ~= "table" then
            t[key] = nil
        else
            local unit, kindStr = string.match(tostring(key), "^(.-)|(%d+)$")
            local kind = tonumber(kindStr)
            if not unit or not kind then
                t[key] = nil
            elseif not WR_PaladinBlessing_Needs(unit, kind) then
                -- buff 已上身 / 已确认不需要 → 立刻熄灭
                if WR_PalBless_Fn(WR_PaladinForever_HideNow) then
                    WR_PaladinForever_HideNow(rec.spell, rec.slot)
                end
                t[key] = nil
                -- ★★ 2026-11-12 核心五：确认不需要补了 → 退避清零
                WR_PaladinBlessing_BackoffClear(unit, kind)
            elseif (now - WR_PalBless_Num(rec.at, 0)) > (WR_PAL_BLESS_PENDING_TTL or 2.5) then
                t[key] = nil                 -- 超时：Needs 仍 true，允许下一轮重新提示
            end
        end
    end
end

-- ★ 点亮祝福色块并登记「已点亮待确认」状态（统一出口）
local function WR_PaladinBlessing_Light(unit, kind, spellName, slot, key)
    if not WR_PaladinBlessing_Show(slot, spellName) then return false end
    if WR_PalBless_Fn(WR_PaladinForever_MarkPrompt) then
        WR_PaladinForever_MarkPrompt(key, slot)
    end
    -- 短保持：给 AHK 一点时间读色块再按键；真正的收口在下一 tick：
    -- buff 上身 → Needs 变 false → SettlePending 立刻 HideNow。
    if WR_PalBless_Fn(WR_PaladinForever_HideSkillLater) then
        WR_PaladinForever_HideSkillLater(spellName, slot, 1.0)
    end
    WR_PaladinBlessing_NoteLit(unit, kind, spellName, slot)
    WR_PaladinBlessing_NoteLightAt()
    WR_PaladinBlessing_PendingFocusAt = nil
    return true
end

-- ★ 尝试给一个单位补一次祝福。
--   返回 true  = 本 tick 已点亮（调用方立刻 return true）
--   返回 false = 这个单位此刻不能处理（冷却中 / 焦点未就绪 / 宏不可用且无焦点槽）
--                → 调用方继续遍历下一个单位（修复二：跳过而不是结束整个 tick）
-- ★★★ 2026-11-13 用户口径「选中敌方目标时小队祝福刷到自己身上、顶掉个人祝福」：
--   玩家当前选中的目标是否**明确为敌对**（读得到才判；无目标 / 读不到 → false 放行）。
--   敌对目标在身时，给队友补祝福的语境不成立：直施/焦点宏一旦条件回退，
--   友善法术会退化成无目标施放 → 当前是敌对目标时按本服规则直接自施
--   —— 这正是「小队祝福上到自己、顶掉个人祝福」的通道之一。
function WR_PaladinBlessing_PlayerTargetHostile()
    if not WR_PalBless_Fn(UnitExists) then return false end
    local okE, e = WR_PalSafe_Call(2, UnitExists, "target")
    if not (okE and e == true) then return false end      -- 无目标 / 读不到 → 不算敌方
    if WR_PalBless_Fn(UnitIsFriend) then
        local okF, f = WR_PalSafe_Call(2, UnitIsFriend, "player", "target")
        if okF and f == false then return true end        -- 明确非友善 → 敌对
    end
    if WR_PalBless_Fn(UnitCanAttack) then
        local okA, a = WR_PalSafe_Call(2, UnitCanAttack, "player", "target")
        if okA and a == true then return true end         -- 明确可攻击 → 敌对
    end
    return false
end

local function WR_PaladinBlessing_TryUnit(unit, mode, kind, greater)
    local rec = WR_PAL_BLESS_KINDS[kind]
    if not rec then return false end
    local spellName = greater and rec.greater or rec.normal
    local slot = greater and rec.greaterSlot or rec.normalSlot

    -- ★★★ 2026-11-13 用户口径「选中敌方目标时小队祝福刷到自己身上、顶掉个人祝福」：
    --   给**队友**补祝福前先看玩家当前目标：明确敌对 → 本 tick 不点亮
    --   （直施 / 焦点两条路都在这道闸后面，一并拦住）。
    --   个人祝福（unit=player）不受影响，照常点亮 —— 两类祝福互不牵连。
    --   读不到（secret → nil）放行，由 CastDirect 战斗锁/回读闸 + 射程确认闸兜底。
    if unit ~= "player" and WR_PaladinBlessing_PlayerTargetHostile() then
        return false
    end

    -- ★★ 2026-11-12：单人自施分支（用户口径「单人可以不用设置焦点直接使用加祝福buff」）
    --   直接点亮 selfSlot（91~93，宏 /cast [target=player] 普通祝福），
    --   不切焦点、不走 [@focus]，也不受当前目标 / 已有焦点影响；
    --   自施宏本身就是普通祝福，与单人段「普通祝福」的语义一致。
    --   宏系统不可用（WR_CreateMacro 缺失，自施宏未注册）→ 落回焦点流程。
    -- ★★★ 2026-11-13：小队/团队模式下「自己」的普通祝福也走自施宏（91~93）。
    --   自施宏是注册期写好的静态 [target=player] 文本，战斗锁定下按键照常生效；
    --   不再借用槽 95 动态宏 → 槽 95 从此只承载「队友」文本，
    --   即使出现残留宏文本也**结构上不可能**落到玩家自己身上。
    --   （团队段 unit=player 的强效祝福无自施宏，仍走槽 95 直施，但只在脱战可写时点亮。）
    if (mode == "solo" or (unit == "player" and not greater))
       and rec.selfSlot and WR_PalBless_Fn(WR_CreateMacro) then
        local key = "祝福:自施:" .. tostring(kind)
        if WR_PalBless_Fn(WR_PaladinForever_CanPrompt)
           and not WR_PaladinForever_CanPrompt(key, WR_PAL_BLESS_PROMPT_CD) then
            return false            -- 防刷屏冷却中 → 跳过（绝不落回焦点流程乱点亮）
        end
        if WR_PaladinBlessing_Light(unit, kind, spellName, rec.selfSlot, key) then
            return true
        end
        -- 点亮失败（色块框架不可用）→ 落回下方焦点流程兜底
    end

    -- ★★ 2026-11-12：小队/团队直施分支（用户口径「小队，团队祝福也
    --   可以不用焦点直接加」）—— 重写槽 95 动态宏指向该单位再点亮，
    --   AHK 按 ALT-F5 直接对该单位施放，不切焦点；
    --   宏系统不可用（WR_CreateMacro 缺失，如离线夹具）才落回焦点流程。
    if mode ~= "solo" then
        local key = "祝福:直施:" .. tostring(unit) .. ":" .. tostring(kind)
        if WR_PalBless_Fn(WR_PaladinForever_CanPrompt)
           and not WR_PaladinForever_CanPrompt(key, WR_PAL_BLESS_PROMPT_CD) then
            return false            -- 冷却中 → 跳过，继续下一个单位（修复二核心）
        end
        if WR_PaladinBlessing_CastDirect(unit, spellName) then
            if WR_PalBless_Fn(WR_PaladinForever_MarkPrompt) then
                WR_PaladinForever_MarkPrompt(key, WR_PAL_BLESS_UNIT_SLOT)
            end
            if WR_PalBless_Fn(WR_PaladinForever_HideSkillLater) then
                WR_PaladinForever_HideSkillLater(spellName, WR_PAL_BLESS_UNIT_SLOT, 1.0)
            end
            WR_PaladinBlessing_NoteLit(unit, kind, spellName, WR_PAL_BLESS_UNIT_SLOT)
            WR_PaladinBlessing_NoteLightAt()
            WR_PaladinBlessing_PendingFocusAt = nil
            return true
        end
        -- 直施不可用 → 落回焦点流程
    end

    -- ★★★ 2026-11-13：非神圣专精禁止回落焦点流程。
    --   防骑/惩戒的祝福只走直施（槽 91-93/95）；直施不可用就跳过该单位，
    --   绝不点亮 176-179 焦点色块（防骑「自动设置焦点到 party2」的直接来源）。
    if not WR_PaladinBlessing_FocusFlowAllowed() then return false end

    -- ① 焦点没切到该单位 → 先切焦点（含自己；直施不可用时才走到这里）
    if not WR_PaladinBlessing_FocusIs(unit) then
        local fs = WR_PaladinBlessing_FocusSlot(unit)
        if fs then
            WR_PaladinBlessing_PendingFocusAt = GetTime()
            if WR_PaladinBlessing_Show(fs, "祝福焦点") then return true end
        end
        -- 没有对应焦点宏（如 raid26+）→ 跳过该单位，不反复尝试
        return false
    end

    -- ② 焦点已就位 → 点亮 [@focus] 祝福色块
    local pending = WR_PaladinBlessing_PendingFocusAt
    if pending and (GetTime() - pending) < (WR_PAL_BLESS_FOCUS_SETTLE or 0.15) then
        return false                -- 给焦点切换留一瞬
    end
    local key = "祝福:" .. tostring(unit) .. ":" .. tostring(kind)
    if WR_PalBless_Fn(WR_PaladinForever_CanPrompt)
       and not WR_PaladinForever_CanPrompt(key, WR_PAL_BLESS_PROMPT_CD) then
        return false                -- 冷却中 → 跳过，继续下一个单位
    end
    return WR_PaladinBlessing_Light(unit, kind, spellName, slot, key)
end

-- ★ 自动补祝福主入口：每 tick 最多点亮一个色块。
-- ★★ 2026-11-12 修复二（Auto() 结构缺陷）：原来遍历单位时一遇到「在防刷屏
--   冷却中」就 `return false` 直接结束整个 tick —— 而 units[1] 永远是 player，
--   自己的 10 秒冷却会把后面所有队友一起挡掉：实测「自己缺智慧 + 队友甲缺力量」
--   时，队友甲永远轮不到（自己冷却到期又抢先占掉唯一的 tick 返回点）。
--   现在改为「跳过」：冷却中的单位直接 continue，tick 继续推进到下一个单位。
function WR_PaladinBlessing_Auto()
    -- ★ 2026-11-15：奶骑面板「祝福」功能图标 = 自动祝福总开关（SS_BLESS_ON）
    if PigSet and PigSet.SS_BLESS_ON == false then return false end
    local c = WR_PaladinBlessing_Cfg()
    if PigSet and PigSet.SS_BLESS_ON == true and c.enable ~= true then
        c.enable = true          -- 面板「祝福」勾着即视为总闸打开（新面板单一入口）
    end
    if c.enable ~= true then return false end                 -- 总闸

    -- ① 先收口「已点亮待确认」的色块（buff 上身就立刻熄灭）
    WR_PaladinBlessing_SettlePending()

    -- ② 把「最近一次施法」里属于祝福的那条闩锁下来（供 JustCast 使用）
    WR_PaladinBlessing_LatchLastCast()

    -- ② 脱战瞬间 + 缓存缺失时自愈重扫 player 光环（读值失败时兜底）
    -- ★ 必须区分「明确读到 false」与「读不到（secret → nil）」：
    --   secret 时 inCombatNow 也是 false，若据此判「刚脱战」就会每 tick 走
    --   一次 force 重扫（绕过节流）→ 把热路径变成全量扫描。所以只在
    --   「上一次明确读到 true、这一次明确读到 false」时才算脱战瞬间。
    local inCombatNow, combatKnown = false, false
    if WR_PalBless_Fn(UnitAffectingCombat) then
        local ok, v = WR_PalSafe_Call(2, UnitAffectingCombat, "player")
        if ok and v == true then inCombatNow, combatKnown = true, true
        elseif ok and v == false then inCombatNow, combatKnown = false, true end
    end
    local justLeftCombat = false
    if combatKnown then
        if WR_PaladinBlessing_WasInCombat == true and not inCombatNow then
            justLeftCombat = true
            WR_PaladinBlessing_RepairPlayerAuraCache(true)    -- 刚脱战：强制重扫一次
        else
            WR_PaladinBlessing_RepairPlayerAuraCache(false)   -- 缓存缺失：节流重扫
        end
        WR_PaladinBlessing_WasInCombat = inCombatNow
    else
        WR_PaladinBlessing_RepairPlayerAuraCache(false)       -- 读不到战斗态：只走节流通道
    end

    if WR_PaladinBlessing_Blocked() then return false end

    local mode, count = WR_PaladinBlessing_GroupState()

    -- ★★★ 2026-11-16 修复「只勾个人、小队不勾 → 个人祝福不生效」：
    --   段勾选只决定该段的目标是否参与本轮，不能按「当前队伍状态」整体短路。
    --   旧写法 mode=="party" and c.party~=true 直接 return false，把单人段（自己）
    --   也一起挡掉了 —— 玩家在小队里只勾「个人」时什么都不补，个人选的祝福失效。
    --   现在：单人段独立生效（player 永远第一优先），小队/团队段按各自勾选追加。
    local units = {}
    if c.solo == true then
        units[#units + 1] = "player"       -- 单人段：自己（任何队伍状态下都生效）
    end
    if mode == "party" and c.party == true then
        for i = 1, 4 do units[#units + 1] = "party" .. i end
    elseif mode == "raid" and c.raid == true then
        local n = count
        if n > 25 then n = 25 end                              -- 焦点宏覆盖 raid1~25
        for i = 1, n do units[#units + 1] = "raid" .. i end
    end
    if #units == 0 then return false end

    -- ★★★ 2026-11-18 用户口径「脱战后，小队祝福刷的太慢了」：
    --   刚脱战瞬间原来只强扫 player 的光环缓存；队友的缓存还是战斗中扫描失败
    --   留下的 nil/旧值 → 脱战后头几个 tick 里队友要么被判「读不到」吃指数退避
    --   （10/30/60...秒才试一次），要么空亮一次色块白费一个 GCD —— 整队补刷被拖慢。
    --   现在脱战瞬间把本轮全部候选单位（自己 + 小队/团队）的光环缓存一次性强制
    --   重扫（一次性标记，只在「明确 true→false 脱战」时触发），Needs 立即按
    --   真实光环判定，随后按正常 GCD 间隔节奏逐个补，不再吃退避。
    if justLeftCombat and WR_PaladinBlessing_OOCRescanDone ~= true then
        WR_PaladinBlessing_OOCRescanDone = true
        for i = 1, #units do
            local u = units[i]
            if u == "player" then
                -- player 已在上面 RepairPlayerAuraCache(true) 强扫过，这里不重复
            elseif WR_PalBless_Fn(WR_ForceRefreshAuraCache) then
                pcall(WR_ForceRefreshAuraCache, u)
            elseif type(WR_AuraCacheScanned) == "table" then
                WR_AuraCacheScanned[u] = false
            end
        end
    end
    if (inCombatNow == true) or (combatKnown == false) then
        WR_PaladinBlessing_OOCRescanDone = nil   -- 回到战斗/未知态：复位一次性标记
    end

    -- ★★★ 2026-11-12 用户口径「脱战了没有第一时间补祝福」「给队友加也是这样，
    --   补的时机太晚」：GCD 间隔闸。
    --   祝福占 GCD，上一次点亮后 AHK 按下就吃掉了 GCD；这期间再点亮**另一个**
    --   单位的色块，AHK 按下去必然被客户端拒绝（色块白亮一次、buff 不上身），
    --   还要被 pending 锁住 → 队列变成 8 秒一跳（离线实测 4 队友 32.5 秒）。
    --   现在统一隔一个 GCD 再处理下一个单位：按键不浪费，队列也不被 pending 拉长。
    if not WR_PaladinBlessing_CastGapReady() then return false end

    for i = 1, #units do
        local unit = units[i]
        if WR_PaladinBlessing_UnitUsable(unit) then
            local classToken = WR_PaladinBlessing_ClassToken(unit)
            local kind, greater = WR_PaladinBlessing_UnitPick(unit, mode, classToken)
            if kind and kind >= 1 and kind <= 3 then
                local rec = WR_PAL_BLESS_KINDS[kind]
                local spellName = greater and rec.greater or rec.normal

                -- ★★★ 2026-11-12 用户口径「当队友不在技能释放范围的时候，
                --   不在卡着使用祝福buff」：
                --   够不着就**跳过这个单位**（不点亮、不记 pending、不占 tick），
                --   队列继续推进到下一个够得着的队友。
                --   放在 Needs 之前：连距离都不够，就没必要去扫光环 / 判退避。
                --   超程时顺手收口这个单位的残留状态，否则它上一次的 pending
                --   会让它「看起来还在等」，并且色块可能还亮着被 AHK 连按。
                local inRange = WR_PaladinBlessing_InCastRange(unit, spellName, greater)
                -- ★★★ 2026-11-13 用户口径「小队祝福只作用于范围内的队友」：
                --   InCastRange「读不到放行」的旧口径保留；这里对**队友**追加
                --   「确认在射程内」硬闸——三层全读不到（战斗 secret）也按超程
                --   处理，绝不点亮一个可能退化落到自己身上的祝福。
                if inRange and unit ~= "player"
                   and not WR_PaladinBlessing_RangeConfirmed(unit, spellName, greater) then
                    inRange = false
                end
                if not inRange then
                    WR_PaladinBlessing_ClearPendingLit(unit, kind)
                    if WR_PalBless_Fn(WR_PaladinForever_HideNow) then
                        WR_PaladinForever_HideNow(spellName,
                            greater and rec.greaterSlot or rec.normalSlot)
                        WR_PaladinForever_HideNow(spellName, WR_PAL_BLESS_UNIT_SLOT)
                        WR_PaladinForever_HideNow(spellName, rec.selfSlot)
                    end
                end

                if inRange then
                    -- ★★ 「读值失败」≠「真的没有」：两道非光环证据
                    --   ③ 已点亮、等待 buff 上身确认 → 宽限期内不重复点亮
                    --   ④ 刚刚确实打出过这条祝福（UNIT_SPELLCAST_SUCCEEDED）→ 不重复提示
                    --   两条都是「跳过这个单位」，不是 return false（修复二口径）。
                    local skipUnit = false
                    -- ★★★ 2026-11-12：先给这个单位一次缓存自愈机会。
                    --   队友光环缓存一旦在战斗中扫描失败（nil + 已标记 scanned），
                    --   就永久读不到 → 永远判「缺祝福」。这里带节流重扫。
                    WR_PaladinBlessing_RepairUnitAuraCache(unit)
                    if WR_PaladinBlessing_Needs(unit, kind) then
                        if WR_PaladinBlessing_IsPendingLit(unit, kind)
                           or WR_PaladinBlessing_JustCast(spellName, unit) then
                            skipUnit = true
                        elseif WR_PaladinBlessing_CacheUnreadable(unit) then
                            -- ★★ 2026-11-12 核心五：光环整块读不到 → 走指数退避，
                            --   不再每 10 秒白刷一次色块（AHK 会跟着每 10 秒按一次）。
                            if not WR_PaladinBlessing_BackoffAllow(unit, kind) then
                                skipUnit = true
                            end
                        end
                    else
                        skipUnit = true      -- 已有祝福（含 999 哨兵）→ 不需要补
                        -- 读得到且确认不需要补 → 退避清零，回到正常节奏
                        WR_PaladinBlessing_BackoffClear(unit, kind)
                    end

                    -- ★★★ 2026-11-13 用户口径「选中敌方目标时祝福刷到自己身上，个人祝福被顶掉」
                    --   最后一层：给队友补祝福的这一刻，如果玩家的当前目标是**另一个友方玩家**
                    --   （战斗中常见：BOSS 加光环前先点队友读血 / 鼠标悬停目标切换），
                    --   部分客户端会把带条件的 [@partyN] 施放落到当前友善目标上。
                    --   这不是我们要的结果 —— 跳过这一 tick 等下一 tick，避免顶掉其他人身上的祝福。
                    --   只拦「明确读到也是友方玩家且不是本单位」的情况；读不到一律放行。
                    if not skipUnit and unit ~= "player" and WR_PalBless_Fn(UnitIsUnit) and WR_PalBless_Fn(UnitIsPlayer) then
                        local okPt, isPlrT = WR_PalSafe_Call(2, UnitIsPlayer, "target")
                        if okPt and isPlrT == true then
                            local okTt, tgtIsUnit = WR_PalSafe_Call(2, UnitIsUnit, "target", unit)
                            if okTt and tgtIsUnit == false then
                                skipUnit = true      -- 目标是别的友方玩家 → 这一 tick 不动，免得祝福落到他身上
                            end
                        end
                    end

                    if not skipUnit then
                        local unreadable = WR_PaladinBlessing_CacheUnreadable(unit)
                        if WR_PaladinBlessing_TryUnit(unit, mode, kind, greater) then
                            if unreadable then
                                WR_PaladinBlessing_BackoffBump(unit, kind)
                            else
                                WR_PaladinBlessing_BackoffClear(unit, kind)
                            end
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- ============================================================
-- 独立设置窗口（惰性创建）
-- ============================================================
WR_PaladinBlessingFrame = nil

local function WR_PaladinBlessing_MakeFontString(parent, text, size, r, g, b, width)
    local fs = parent:CreateFontString(nil, "ARTWORK")
    fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size or 12, "")
    fs:SetTextColor(r or 1, g or 1, b or 1)
    fs:SetText(text or "")
    if width then
        fs:SetWidth(width)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
    end
    return fs
end

local function WR_PaladinBlessing_MakeCheck(parent, x, y, label, tooltip, scope)
    local chk = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    chk:SetSize(22, 22)
    chk:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    -- ★ 2026-11-12 UI 修复：标题文字原先用 "LEFT" 锚到复选框右侧，锚在复选框的
    --   垂直中点、再带上文字自身锚点后，13px 大字与 22px 图标在视觉上上下错开一截
    --   （截图里「祝福（总开关）」明显比勾选框低半行）。改为锚在 RIGHT + 垂直居中，
    --   并整体微调 -1px，让文字重心与勾选图标中心重合。
    local txt = WR_PaladinBlessing_MakeFontString(parent, label, 13, 0.95, 0.82, 0.35)
    txt:SetPoint("LEFT", chk, "RIGHT", 2, -1)
    txt:SetJustifyV("MIDDLE")
    chk.label = txt
    chk:SetScript("OnClick", function(self)
        WR_PaladinBlessing_SectionEnabled(scope, self:GetChecked() and true or false)
    end)
    if tooltip then
        chk:SetScript("OnEnter", function(self)
            if GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tooltip)
                GameTooltip:Show()
            end
        end)
        chk:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    end
    return chk
end

-- ★ 一行 = 标签 + 4 个格子（力量 / 智慧 / 王者 / 无）
--   每行只能亮一个，再点一下取消；「无」= 明确不加
--   ★ 2026-11-12 UI 修复：行高统一按 WR_PAL_BLESS_ROW_H 递推，标签与格子共用
--   同一顶边基线（不再给标签单独 -2 偏移），名字与色块才在同一条水平线上。
local function WR_PaladinBlessing_MakeRow(parent, x, y, label, scope, keyFn)
    local row = { scope = scope, keyFn = keyFn, cells = {}, y = y }
    row.label = WR_PaladinBlessing_MakeFontString(parent, label, 12, 0.85, 0.85, 0.85, 108)
    row.label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local cellX = x + 112
    local labels = { "力", "智", "王", "无" }
    for i = 1, 4 do
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(30, 20)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", cellX + (i - 1) * 34, y)
        local tex = btn:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints()
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        local rec = WR_PAL_BLESS_KINDS[i]
        if rec then
            tex:SetVertexColor(rec.r, rec.g, rec.b, 0.9)
        else
            tex:SetVertexColor(0.35, 0.35, 0.35, 0.9)
        end
        local fs = WR_PaladinBlessing_MakeFontString(btn, labels[i], 12, 1, 1, 1)
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
        local value = (i == 4) and 0 or i
        btn:SetScript("OnClick", function()
            local key = keyFn and keyFn() or nil
            WR_PaladinBlessing_Toggle(scope, key, value)
        end)
        btn:SetScript("OnEnter", function(self)
            local tip
            if rec then
                tip = (scope == "raid") and rec.greater or rec.normal
            else
                tip = "「无」= 明确不给这一行加祝福"
            end
            if GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tip)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        row.cells[i] = { btn = btn, tex = tex, fs = fs, value = value }
    end
    return row
end

-- ★★ 2026-11-12 UI 修复：窗口高度按内容反算，不再硬写 640。
--   原问题：团队 9 个职业行末行在 y=-644，占到 -664，而窗口只有 640 高 →
--   「德鲁伊」整行被裁在窗口外（截图底部只剩半截色块，下面透出界面）。
--   做法：所有行挂进 ScrollFrame 的内容容器，行坐标集中由常量递推；
--   容器高 = 末行底边 + 底部留白，窗口高 = min(容器高 + 标题栏, 屏幕可用高)，
--   屏幕矮时由滚动条 / 滚轮承接，不再裁切。
local WR_PAL_BLESS_WINDOW_W = 430
local WR_PAL_BLESS_WIN_H = 640          -- 初始值；真正高度创建时按内容设定
local WR_PAL_BLESS_ROW_H = 24           -- 行高（含行间距）
local WR_PAL_BLESS_BOTTOM_PAD = 14      -- 最后一行下方留白
local WR_PAL_BLESS_HEADER_H = 40        -- 标题栏高度（内容区从这里开始）
local WR_PAL_BLESS_TOP = 4              -- 内容区顶部留白

function WR_PaladinBlessing_BuildFrame()
    local f = CreateFrame("Frame", "WR_PaladinBlessingFrame", UIParent, "BackdropTemplate")
    f:SetSize(WR_PAL_BLESS_WINDOW_W, WR_PAL_BLESS_WIN_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        f:SetBackdropColor(0.04, 0.04, 0.06, 0.96)
        f:SetBackdropBorderColor(0.55, 0.42, 0.18, 0.95)
    end
    f:Hide()

    local title = WR_PaladinBlessing_MakeFontString(f, "祝福  功能", 16, 1, 0.82, 0.2)
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -10)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() f:Hide() end)

    -- 内容容器：所有行都挂在这里，窗口只负责边框 / 标题 / 滚动
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -WR_PAL_BLESS_HEADER_H)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -26, 2)
    f.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WR_PAL_BLESS_WINDOW_W - 30, WR_PAL_BLESS_WIN_H)
    scroll:SetScrollChild(content)
    f.content = content

    local desc = WR_PaladinBlessing_MakeFontString(content,
        "开着时脱战自动补祝福，给谁加哪个在下面点格子：一个格子一种祝福"
        .. "（力量 / 智慧 / 王者），每行只能亮一个，再点一下取消。\n"        .. "单人：给自己加（普通祝福）。\n"
        .. "小队：一人一行，加普通祝福；没单独点过的人按团队那张职业表加，点「无」= 这个人不加。\n"
        .. "团队：一个职业一行，加强效祝福。\n"
        .. "每段标题前面的勾 = 该段对象补不补；三段互相独立（去掉「小队」只停队友，个人段仍按自己的勾选生效）。\n"
        .. "身上没有或快到期才补，别的圣骑士加了同一种也算有；战斗中、骑着坐骑、吃喝时不补。"
        .. "补祝福不占用焦点：单人直接对自己施放，小队/团队由直施宏指向对应队友。\n"
        .. "★ 距离条件：队友不在祝福射程内（普通祝福 30 码 / 强效祝福 40 码）时"
        .. "直接跳过，不点亮、不占按键，继续给够得着的队友补；走近了自动补上。",
        12, 0.82, 0.82, 0.82, 380)
    desc:SetPoint("TOPLEFT", content, "TOPLEFT", 12, -WR_PAL_BLESS_TOP)
    desc:SetSpacing(3)

    -- ★★ 2026-11-12 UI 修复：说明段高度改为实测，下方控件跟着说明块实际高度排。
    --   原问题：说明文字 6 行在 380px 宽度内自动折行成约 10 行（11px 中文 +
    --   行距 3，实际高约 170px），而下方「- 额外条件 / 祝福（总开关）/ 单人」
    --   仍按写死的 +110px 起排 → 说明文的后几行正好被这三行控件压住，
    --   看起来就是「文字异常 / 被掩盖」。
    --   做法：SetSpacing 之后用 GetStringHeight 实测说明块高度，+8px 间隙再往下排；
    --   实测不到（离线夹具 stub 没有该方法）时保持 110 不变，旧行为与旧断言不受影响；
    --   实测值比 110 还小也仍按 110，绝不比旧版排得更挤。
    local descH = 110
    if desc.GetStringHeight then
        local okH, h = pcall(desc.GetStringHeight, desc)
        if okH and type(h) == "number" and h > 0 then
            descH = math.max(110, math.ceil(h) + 8)
        end
    end

    -- 以下 y 都是「距内容区顶边的负偏移」，逐个累加得到绝对位置
    local yDesc      = WR_PAL_BLESS_TOP
    local yExtra     = yDesc + descH
    local yMaster    = yExtra + 31
    local ySolo      = yMaster + 32
    local ySoloRow   = ySolo + 28
    local yParty     = ySoloRow + 32
    local yPartyNote = yParty + 23
    local yPartyRow0 = yPartyNote + 19

    local extra = WR_PaladinBlessing_MakeFontString(content, "- 额外条件", 12, 1, 0.65, 0.2)
    extra:SetPoint("TOPLEFT", content, "TOPLEFT", 12, -yExtra)
    local master = WR_PaladinBlessing_MakeCheck(content, 18, -yMaster, "祝福（总开关）",
        "不勾选时整个自动补祝福功能不生效", "enable")

    local soloChk = WR_PaladinBlessing_MakeCheck(content, 18, -ySolo, "单人（普通祝福）当前",
        "去掉勾：自己的个人祝福不自动补", "solo")
    local soloRow = WR_PaladinBlessing_MakeRow(content, 42, -ySoloRow,
        UnitName and (select(1, UnitName("player")) or "当前角色") or "当前角色",
        "solo", function() return nil end)

    local partyChk = WR_PaladinBlessing_MakeCheck(content, 18, -yParty, "小队（普通祝福，一人一行）",
        "去掉勾：小队队友不自动补祝福（个人段仍独立生效）", "party")
    local partyNote = WR_PaladinBlessing_MakeFontString(content,
        "进了小队才列出队友；没单独点的人按下面的职业表", 12, 0.6, 0.6, 0.6, 360)
    partyNote:SetPoint("TOPLEFT", content, "TOPLEFT", 42, -yPartyNote)
    local partyRows = {}
    for i = 1, 4 do
        -- ★ 2026-11-11 修复：keyFn 闭包必须引用「已声明」的局部变量。
        --   原写法 local row = MakeRow(..., function() return row.curName end)
        --   闭包内 row 是另一个（未赋值的）局部，捕获到 nil → Refresh() 里
        --   row.keyFn() 读 row.curName 直接 "attempt to index a nil value"。
        --   先声明再赋值，闭包捕获同一个变量。
        -- ★★ 2026-11-12 修复「小队队友加不上祝福」：keyFn 不再读 row.curName
        --   （那是「窗口打开那一刻」的快照，单人时打开 → 全是 nil → 点格子静默
        --   失败），改为每次点击/刷新都现场问客户端要 partyN 的名字。
        --   序号 i 用 do 块固定住，避免闭包共享同一个 i。
        local row
        local idx = i
        row = WR_PaladinBlessing_MakeRow(content, 42,
            -(yPartyRow0 + (idx - 1) * WR_PAL_BLESS_ROW_H),
            "（空）", "party", function() return WR_PaladinBlessing_PartyName(idx) end)
        partyRows[idx] = row
    end

    -- 团队段
    local yRaid = yPartyRow0 + 4 * WR_PAL_BLESS_ROW_H + 18
    local raidChk = WR_PaladinBlessing_MakeCheck(content, 18, -yRaid, "团队（强效祝福，一个职业一行）",
        "去掉勾：团队队友不自动补祝福（个人段仍独立生效）", "raid")
    local yRaidRow0 = yRaid + 28
    local raidRows = {}
    for i = 1, #WR_PAL_BLESS_CLASSES do
        local cls = WR_PAL_BLESS_CLASSES[i]
        local row = WR_PaladinBlessing_MakeRow(content, 42,
            -(yRaidRow0 + (i - 1) * WR_PAL_BLESS_ROW_H),
            cls.zh, "raid", function() return cls.token end)
        raidRows[i] = row
    end

    f.master  = master
    f.soloChk = soloChk
    f.partyChk = partyChk
    f.raidChk = raidChk
    f.soloRow = soloRow
    f.partyRows = partyRows
    f.raidRows  = raidRows
    f.allRows = { soloRow }
    for i = 1, #partyRows do f.allRows[#f.allRows + 1] = partyRows[i] end
    for i = 1, #raidRows  do f.allRows[#f.allRows + 1] = raidRows[i]  end

    -- ★ 内容高 = 末行顶边 + 行高（20）+ 底部留白 —— 由坐标反算，不再手写
    local lastTop = yRaidRow0 + (#raidRows - 1) * WR_PAL_BLESS_ROW_H
    local contentH = lastTop + 20 + WR_PAL_BLESS_BOTTOM_PAD
    content:SetHeight(contentH)

    -- ★ 窗口高 = 标题栏 + 内容高，屏幕矮时封顶并交给滚动条
    local screenH = 768
    if UIParent and UIParent.GetHeight then
        local okH, h = pcall(UIParent.GetHeight, UIParent)
        if okH and type(h) == "number" and h > 0 then screenH = h end
    end
    local wantH = WR_PAL_BLESS_HEADER_H + contentH + 6
    local maxH  = math.max(320, screenH - 120)
    f:SetHeight(math.min(wantH, maxH))

    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(self, delta)
        local sb = self.scroll and self.scroll.ScrollBar
        if not sb and self.scroll and self.scroll.GetName then
            local name = self.scroll:GetName()
            sb = name and _G[name .. "ScrollBar"]
        end
        if sb and sb.GetValue and sb.SetValue then
            sb:SetValue(sb:GetValue() - delta * (WR_PAL_BLESS_ROW_H * 2))
        end
    end)

    WR_PaladinBlessingFrame = f
    return f
end

-- 刷新窗口：勾选态、每行格子亮灭、小队行名字
function WR_PaladinBlessing_Refresh()
    local f = WR_PaladinBlessingFrame
    if not f then return end
    local c = WR_PaladinBlessing_Cfg()
    if f.master and f.master.SetChecked then f.master:SetChecked(c.enable == true) end
    if f.soloChk and f.soloChk.SetChecked then f.soloChk:SetChecked(c.solo == true) end
    if f.partyChk and f.partyChk.SetChecked then f.partyChk:SetChecked(c.party == true) end
    if f.raidChk and f.raidChk.SetChecked then f.raidChk:SetChecked(c.raid == true) end

    -- 小队行：按当前队伍成员刷新名字并绑定存档 key
    -- ★★ 2026-11-12：名字改由 WR_PaladinBlessing_PartyName 现场取（与 keyFn 同源），
    --   保证「标签显示的名字」和「点格子写进存档的 key」永远是同一个名字。
    local mode = WR_PaladinBlessing_GroupState()
    for i = 1, #f.partyRows do
        local row = f.partyRows[i]
        local name = nil
        if mode ~= "solo" then name = WR_PaladinBlessing_PartyName(i) end
        row.curName = name
        if row.label and row.label.SetText then
            row.label:SetText(name or "（空）")
        end
    end

    for i = 1, #f.allRows do
        local row = f.allRows[i]
        local key = row.keyFn and row.keyFn() or nil
        local pick = WR_PaladinBlessing_GetPick(row.scope, key)
        for j = 1, #row.cells do
            local cell = row.cells[j]
            local on = (pick ~= nil and tonumber(pick) == cell.value)
            if cell.tex and cell.tex.SetAlpha then cell.tex:SetAlpha(on and 1 or 0.28) end
            if cell.fs and cell.fs.SetTextColor then
                if on then cell.fs:SetTextColor(1, 1, 0.4)
                else cell.fs:SetTextColor(0.85, 0.85, 0.85) end
            end
        end
    end
end

function WR_OpenPaladinBlessing()
    local f = WR_PaladinBlessingFrame
    if not f then f = WR_PaladinBlessing_BuildFrame() end
    if f:IsShown() then
        f:Hide()
    else
        WR_PaladinBlessing_Refresh()
        f:Show()
    end
end

function WR_TogglePaladinBlessing()
    WR_OpenPaladinBlessing()
end

-- ============================================================
-- ★★ 2026-11-12 修复「小队队友加不上祝福」配套：队伍名单变化 → 自动刷新窗口
-- ------------------------------------------------------------
-- 修好 keyFn（现场取名）之后还剩一个体验缺口：窗口开着的时候队友进出，
-- 行标签仍显示旧名字（直到手动关掉重开）。这里挂事件，成员变动就刷一次。
--   · GROUP_ROSTER_UPDATE   —— 小队/团队名单变化（12.x 仍在）
--   · PARTY_MEMBERS_CHANGED / RAID_ROSTER_UPDATE —— 旧接口，存在才注册
--   · PLAYER_ENTERING_WORLD —— 上线/进本后名单可能才就绪
-- 只刷「窗口已存在」的情况；窗口没建过就什么都不做（惰性创建，不提前吃资源）。
-- ============================================================
WR_PaladinBlessing_RosterFrame = nil

local function WR_PaladinBlessing_InstallRosterWatch()
    if WR_PaladinBlessing_RosterFrame then return end
    -- ★ 用 WR_PalBless_Fn 而不是 type(CreateFrame)=="function"：
    --   离线夹具里 WoW 接口是 Python 可调用对象，type() 是 "userdata"，
    --   写死 "function" 会让整段在夹具里被静默跳过（本文件顶部的老坑，别再踩）。
    if not WR_PalBless_Fn(CreateFrame) then return end
    local ok, f = pcall(CreateFrame, "Frame")
    if not ok or not f or not f.RegisterEvent then return end
    local function tryReg(ev)
        pcall(f.RegisterEvent, f, ev)
    end
    tryReg("GROUP_ROSTER_UPDATE")
    tryReg("PARTY_MEMBERS_CHANGED")
    tryReg("RAID_ROSTER_UPDATE")
    tryReg("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        if WR_PaladinBlessingFrame and WR_PaladinBlessing_Refresh then
            pcall(WR_PaladinBlessing_Refresh)
        end
    end)
    WR_PaladinBlessing_RosterFrame = f
end

WR_PaladinBlessing_InstallRosterWatch()

-- 斜杠命令：/palbless 或 /祝福 打开列表
SLASH_PALBLESS1 = "/palbless"
SLASH_PALBLESS2 = "/祝福"
if type(SlashCmdList) == "table" then
    SlashCmdList["PALBLESS"] = function() WR_OpenPaladinBlessing() end
end
