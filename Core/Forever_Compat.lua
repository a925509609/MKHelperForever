-- ============================================================
-- Core/Forever_Compat.lua
-- 《魔兽世界：无限》(WoW: Forever) 客户端兼容层
-- ------------------------------------------------------------
-- 本层解决 MKHelperSoD（探索赛季）→ MKHelperForever（无限）迁移中的
-- 四类硬性问题：
--
--   【1】专精树改名
--       无限的天赋树沿用经典布局，但部分树名与经典/SoD 不同：
--         萨满 2 系  Elemental Combat → 元素战斗（经典为「元素」）
--         牧师 3 系  Shadow Magic     → 暗影魔法（经典为「暗影」）
--         德鲁伊 2 系 Feral Combat    → 野性战斗（经典为「野性」）
--       主循环 Core/MainLoop.lua 的 WR_GetMyTalent() 完全依赖中文树名
--       做专精分派，树名对不上 → 该职业整套循环不注册。
--       解决：WR_Forever_NormalizeSpec() 统一归一为经典规范名，
--             并对 enUS 客户端的英文树名做同样归一（顺带支持英文端）。
--
--   【2】符文机制消失
--       无限没有符文刻印。Core/SoD_Runes.lua 的 WR_SoD_HasRune() 实际
--       走 IsPlayerSpell()（法术书检测），天赋点出的技能同样返回 true，
--       因此该函数天然兼容；但 SoD 独有的符文技能在无限不存在，
--       对应分支只会「不触发」，不会报错（安全降级）。
--
--   【3】死亡骑士不存在
--       无限首发 9 职业（无 DK）。WR_GetRuneCount() 调用 DK 符文 API
--       GetRuneCount()，在无 DK 的客户端上可能返回异常值。
--       解决：Core/Forever_Hooks.lua 中按职业守卫。
--
--   【4】新种族 / 新职业组合 / 种族特长重做
--       天裔（Skyborne）、被遗忘者圣骑士、矮人萨满；
--       种族爆发技能新增「艾露恩之光」「尤里卡！」，防御新增「碎咒」，
--       「石像形态」重新纳入。
--       数据见 Data/Forever_Racials.lua。
--
-- 设计原则：**纯附加（additive）**。
--   本层不删除、不覆盖任何 SoD 行为；所有新增内容在 SoD 客户端上
--   均表现为「无副作用」（例如宏里多一行 /cast 不存在的技能）。
-- ============================================================

WR_Forever = WR_Forever or {}
local F = WR_Forever

-- ============================================================
-- ★ 0-. 屏幕文字提示总闸（PigSet.ScreenTextNotice）
-- ------------------------------------------------------------
-- 用户口径：「把插件中屏幕文字提示都关闭了」。
-- 放在最先加载的兼容层，保证后续所有文件在加载/运行时都能调用。
-- 默认关闭：字段为 nil / false 时一律不显示任何屏幕文字提示；
-- 只有显式置 true（全局区「屏幕文字提示」复选框或 /screentip on）才放行。
-- 覆盖：PigAlert 屏幕中央大字、色块/技能图标上的技能名文字、聊天框
--       开关提示、WR_MessageWindows 弹窗、调试 HUD 文字。
-- 不覆盖：色块颜色本身（AHK 取色依赖）、手动执行的诊断/调试命令输出。
-- ============================================================
function WR_ScreenTextNoticeEnabled()
    return type(PigSet) == "table" and PigSet["ScreenTextNotice"] == true
end

-- ============================================================
-- ★ 0. 旧光环 API 兜底（UnitBuff / UnitDebuff）
-- ------------------------------------------------------------
-- 背景：无限使用与正式服 Mainline 12.1.5 同源的 UI 架构，经典期的
--       UnitBuff / UnitDebuff 在受限框架下可能已被移除。而本插件有 18 处
--       直接裸调这两个全局函数（光环缓存、饰品监控、DOT 快照、团队标记
--       有效性、日月蚀、腐蚀快照等），一旦全局为 nil，每次光环扫描都会
--       报 "attempt to call a nil value" 并刷屏。
-- 方案：仅在【原生函数不存在】时，用 C_UnitAuras.GetAuraDataByIndex 按
--       经典返回值顺序补全同名全局函数——18 处调用点一行都不用改。
-- 经典返回值顺序（两函数一致）：
--       name, icon, count, dispelType, duration, expirationTime,
--       source, isStealable, nameplateShowPersonal, spellId
-- 设计原则：纯附加——原生函数存在时本段完全不介入。
-- ============================================================
local function WR_Forever_MakeAuraShim(auraFilter)
    -- 按经典 UnitBuff/UnitDebuff 的返回值顺序包装 C_UnitAuras 的单条光环
    return function(unit, index)
        if type(C_UnitAuras) ~= "table" or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then
            return nil
        end
        local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, auraFilter)
        if not ok or not data then
            return nil
        end
        return data.name, data.icon, data.applications or 0, data.dispelName,
               data.duration or 0, data.expirationTime or 0, data.sourceUnit,
               false, false, data.spellId
    end
end

-- ★★★ 2026-11-20：给包装层打标记。
--   受限战斗里 GetAuraDataByIndex 会抛「Auras cannot be accessed when secret」，
--   shim 只能返回 nil —— 但 nil 的语义是「读不到」，**不是**「没有这条光环」。
--   业务层（Paladin 的 UnitDebuffByDispelKind / UnitHasAnyHarmful /
--   UnitDispelPresence）若把 shim 的 nil 当成「明确没有」，就会在真机战斗中
--   把「中了疾病」判成 false，清洁术永远不亮。
--   标记出来，让业务层在受限上下文里不要采信 shim 的否定结论。
WR_Forever_UnitBuffShim = false
WR_Forever_UnitDebuffShim = false
if type(UnitBuff) ~= "function" then
    UnitBuff = WR_Forever_MakeAuraShim("HELPFUL")
    WR_Forever_UnitBuffShim = true
end
if type(UnitDebuff) ~= "function" then
    UnitDebuff = WR_Forever_MakeAuraShim("HARMFUL")
    WR_Forever_UnitDebuffShim = true
end

-- ============================================================
-- ★ 1. 专精树名归一化
-- ------------------------------------------------------------
-- 键 = 客户端实际返回的树名（中/英，含无限的新名）
-- 值 = 主循环使用的经典规范中文名
-- ============================================================
F.SPEC_ALIAS = {
    -- ---- 无限新增/改名的树（★ 关键） ----
    ["元素战斗"]        = "元素",     -- Shaman  Elemental Combat
    ["暗影魔法"]        = "暗影",     -- Priest  Shadow Magic
    ["野性战斗"]        = "野性",     -- Druid   Feral Combat

    -- ---- enUS 客户端英文树名 → 经典中文规范名（顺带支持英文端） ----
    ["Arms"]            = "武器",
    ["Fury"]            = "狂怒",
    ["Protection"]      = "防护",
    ["Holy"]            = "神圣",
    ["Retribution"]     = "惩戒",
    ["Beast Mastery"]   = "野兽控制",
    ["Marksmanship"]    = "射击",
    ["Survival"]        = "生存",
    ["Assassination"]   = "奇袭",
    ["Combat"]          = "战斗",
    ["Subtlety"]        = "敏锐",
    ["Discipline"]      = "戒律",
    ["Shadow"]          = "暗影",
    ["Shadow Magic"]    = "暗影",
    ["Elemental"]       = "元素",
    ["Elemental Combat"]= "元素",
    ["Enhancement"]     = "增强",
    ["Restoration"]     = "恢复",
    ["Balance"]         = "平衡",
    ["Feral"]           = "野性",
    ["Feral Combat"]    = "野性",
    ["Arcane"]          = "奥术",
    ["Fire"]            = "火焰",
    ["Frost"]           = "冰霜",
    ["Affliction"]      = "痛苦",
    ["Demonology"]      = "恶魔学识",
    ["Destruction"]     = "毁灭",
}

-- ★ 2026-11-06：本服法术 ID 变动覆盖表（技能名 → 本服实际 spellID）
--   仅当该 ID 确实已学会时使用；否则仍走法术书索引（兼容其它 rank）。
F.SPELL_ID_OVERRIDES = {
    ["力量祝福"] = 19834,
    ["智慧祝福"] = 19850,  -- ★ 2026-11-12：截图实测（buff 工具提示法术ID 19850，每5秒恢复18点法力值/60分钟）；19742 为旧 rank1
    ["王者祝福"] = 20217,
    -- ★ 2026-11-06：防护循环核心技能（按本服法术书实测 ID）
    ["神圣打击"] = 1866,     -- Holy Strike Rank 3（等级20）
    ["审判"] = 20271,        -- Judgement
    ["愤怒圣印"] = 1311656,  -- Seal of Fury
    ["正义之怒"] = 25780,    -- Righteous Fury
    ["虔诚光环"] = 465,      -- Devotion Aura
    ["奉献"] = 20116,        -- Consecration Rank 1
    -- ★★ 2026-11-18：删除 ["驱邪术"] = 879（Exorcism Rank 1）覆盖。
    --   旧逻辑只要玩家「学过 Rank1」就永远返回 Rank1；60 级角色实际使用的是
    --   高 rank（如 10314），Rank1 的 IsUsableSpell 在部分客户端判 false /
    --   冷却查询也对不上 → WR_SpellUsable("驱邪术") 恒 false。改由法术书索引
    --   解析当前 rank（缺失时 GetSpellInfo 兜底）。
    ["制裁之锤"] = 853,      -- Hammer of Justice Rank 1
    ["攻击"] = 6603,         -- Auto Attack
}

-- ★ 强制 ID：这些技能本服 `IsPlayerSpell` 返回值不可靠，直接按实测 ID 解析
F.SPELL_ID_FORCE = {
    ["神圣打击"] = 1866,
    ["审判"] = 20271,
    ["愤怒圣印"] = 1311656,
}

-- ★ 把任意来源的专精树名归一为经典规范中文名
--   参数：name 客户端 GetTalentTabInfo 返回的第 2 个值
--   返回：规范化后的名称（未命中别名表时原样返回，保证不破坏 SoD 行为）
function WR_Forever_NormalizeSpec(name)
    if type(name) ~= "string" or name == "" then return name end
    local alias = F.SPEC_ALIAS[name]
    if alias then return alias end
    -- 容错：去掉首尾空白后再试一次
    local trimmed = name:match("^%s*(.-)%s*$")
    if trimmed ~= name and F.SPEC_ALIAS[trimmed] then return F.SPEC_ALIAS[trimmed] end
    return name
end

-- 反向：经典规范名 → 无限树名（供 UI 显示「无限天赋树」原名）
F.SPEC_REVERSE = {
    ["元素"] = "元素战斗",
    ["暗影"] = "暗影魔法",
    ["野性"] = "野性战斗",
}

-- ============================================================
-- ★ 2. 客户端识别
-- ------------------------------------------------------------
-- 说明：无限与 SoD 同属经典系客户端，上线前无法拿到确定的项目 ID。
--   因此采用「多信号 + 可手工覆盖」策略，并在 /mkfclient 输出诊断。
--   注意：识别结果只影响日志与提示，不影响功能（本层为纯附加）。
-- ============================================================

-- 已知 WOW_PROJECT_ID 常量（Blizzard 未公开无限的项目 ID，留空待补）
local PROJECT_NAMES = {
    [1]  = "正式服 (Mainline)",
    [2]  = "经典旧世系 (Classic / 探索赛季类)",
    [5]  = "燃烧的远征经典 (TBC Classic)",
    [11] = "巫妖王之怒经典 (WotLK Classic)",
    [14] = "大灾变经典 (Cata Classic)",
    [19] = "熊猫人之谜经典 (Mists Classic)",
}

-- 是否拥有探索赛季专属 API（符文刻印）——SoD 的强特征
local function HasEngravingAPI()
    return type(C_Engraving) == "table" or type(C_Engraving) == "userdata"
end

-- 读取客户端信息
function WR_Forever_GetClientInfo()
    local info = {}
    info.build, info.version, info.date, info.toc = GetBuildInfo()
    info.interface = tonumber(info.toc) or 0
    info.projectID = WOW_PROJECT_ID
    info.projectName = PROJECT_NAMES[info.projectID] or ("未知项目 (" .. tostring(info.projectID) .. ")")
    info.hasEngraving = HasEngravingAPI()
    info.class = UnitClassBase and UnitClassBase("player") or "UNKNOWN"

    -- 判定：'forever' | 'sod' | 'classic-era' | 'other'
    local override = PigSet and PigSet.FOREVER_MODE
    if override == "forever" or override == "sod" then
        info.mode = override
        info.modeSource = "手工设置 (PigSet.FOREVER_MODE)"
    elseif info.hasEngraving then
        info.mode = "sod"
        info.modeSource = "自动：检测到符文刻印 API (C_Engraving)"
    elseif info.interface >= 16000 and info.interface <= 16999 then
        -- ★ 无限：客户端版本 1.60.x，beta 期实测接口号为 16001
        --   （此前「无限属于 1.15.x 经典区间」的假设已作废）
        info.mode = "forever"
        info.modeSource = "自动：接口号 " .. info.interface .. " 命中无限分支（客户端 1.60.x）"
    elseif info.interface >= 12000 and info.interface <= 15999 then
        -- 正式服分支：不是无限，也不是探索赛季
        info.mode = "other"
        info.modeSource = "自动：接口号 " .. info.interface .. " 属正式服分支（非无限）"
        info.uncertain = true
    elseif info.interface >= 11500 and info.interface <= 11999 then
        -- 经典区间且无符文 API → 经典旧世（无限已确认不属于此区间）
        info.mode = "classic-era"
        info.modeSource = "自动：经典区间接口 " .. info.interface .. " 且无符文刻印 API"
        info.uncertain = true
    else
        info.mode = "classic-era"
        info.modeSource = "自动：经典旧世基线接口 " .. info.interface
    end
    info.isForever = (info.mode == "forever")
    info.isSoD     = (info.mode == "sod")
    return info
end

-- 缓存（首次调用后固定，ZONE 变化不重算）
local _clientInfo = nil
function WR_Forever_ClientInfo()
    if not _clientInfo then _clientInfo = WR_Forever_GetClientInfo() end
    return _clientInfo
end

function F.IsForever() return WR_Forever_ClientInfo().isForever end
function F.IsSoD()     return WR_Forever_ClientInfo().isSoD end
function F.IsClassicEra() return WR_Forever_ClientInfo().mode == "classic-era" end

-- ============================================================
-- ★ 3. 统一技能检测
-- ------------------------------------------------------------
-- 无限无符文，技能来自「天赋 + 基础技能 + 种族特长」；
-- 经典客户端 IsPlayerSpell 只接受整数 ID，故先解析中文名 → ID。
-- 本函数对 SoD / 无限 均为「法术书里有没有这个技能」的语义。
-- ============================================================

-- 参数：idOrName = number(spellID) 或 string(技能名，中/英)
-- 返回：boolean
function WR_Forever_HasAbility(idOrName)
    if idOrName == nil then return false end
    local id = idOrName
    if type(idOrName) == "string" then
        if type(WR_SoD_GetSpellID) == "function" then
            id = WR_SoD_GetSpellID(idOrName)
        end
        if not id then
            -- 兜底：直接问一次 GetSpellInfo
            local ok, _, _, _, _, _, sid = pcall(GetSpellInfo, idOrName)
            id = ok and sid or nil
        end
    end
    if type(id) ~= "number" then return false end
    if type(IsPlayerSpell) == "function" then
        local ok, res = pcall(IsPlayerSpell, id)
        if ok then return res and true or false end
    end
    if type(IsSpellKnown) == "function" then
        local ok, res = pcall(IsSpellKnown, id)
        if ok then return res and true or false end
    end
    return false
end

-- 批量：任一存在
function WR_Forever_HasAnyAbility(...)
    for i = 1, select("#", ...) do
        if WR_Forever_HasAbility((select(i, ...))) then return true end
    end
    return false
end

-- ============================================================
-- ★ 4. API 安全兜底
-- ------------------------------------------------------------
-- 无限客户端可能移除/改名部分经典 API。提供安全调用封装，
-- 避免因某个 API 缺失导致整个职业模块加载中断。
-- ============================================================

-- 取全局函数；不存在则返回 noop（可安全调用，返回 nil）
function WR_Forever_SafeFn(name)
    local fn = _G[name]
    if type(fn) == "function" then return fn end
    return function() return nil end
end

-- 是否存在某全局（函数或表）
function WR_Forever_HasAPI(name)
    return _G[name] ~= nil
end

-- 安全读取 DK 符文数量：无限无 DK，非 DK 职业一律返回 0
function WR_Forever_SafeRuneCount()
    local cls = UnitClassBase and UnitClassBase("player")
    if cls ~= "DEATHKNIGHT" then return 0 end
    if type(GetRuneCount) ~= "function" then return 0 end
    local total = 0
    for i = 1, 6 do
        local ok, n = pcall(GetRuneCount, i)
        if ok and type(n) == "number" then total = total + n end
    end
    return total
end

-- ============================================================
-- ★ 4.1 经典天赋树 API 兼容层（无限 1.60.x）
-- ------------------------------------------------------------
-- 背景：无限移除了经典天赋 API（GetTalentTabInfo / GetNumTalentTabs /
--       GetNumTalents / GetTalentInfo / GetTalentInfoByID）。本插件有 40+
--       处裸调：主循环专精分派、5 个 Boss 角色判定、天赋面板、
--       Core_Functions 的天赋点数查询。任一处被调即
--       "attempt to call a nil value"；且 MainLoop 里 WR_TalentCache 的
--       赋值语句被错误打断 → 下一 tick 继续重试 → 刷屏 158x。
-- 方案：仅在【原生函数缺失】时安装同名全局兜底函数，40+ 调用点一行不改。
--       · 页数/树名：按职业静态表（与 MainLoop 分派名、各职业 Menu 键一致）
--       · 已投入点数：由「当前激活专精」推导，命中树返回 1、其余返回 0。
--         旧代码一律按「点数最多的一棵树」判专精，1 > 0 足以稳定胜出；
--         Boss 文件的 protRank > armsRank 一类比较同样成立。
--       · 激活专精探测顺序：手工覆盖 → 现代专精 API（名字优先）
--         → GetPrimaryTalentTree（索引）→ 职业默认专精
-- 设计原则：纯附加——原生 API 存在时本段完全不介入。
-- ============================================================

-- 现代客户端专精名 → 经典规范中文名（并入别名表，复用 WR_Forever_NormalizeSpec）
for k, v in pairs({
    ["刺杀"]           = "奇袭",     -- retail zhCN Assassination
    ["狂徒"]           = "战斗",     -- retail zhCN Outlaw（经典为「战斗」）
    ["兽王"]           = "野兽控制",
    ["Outlaw"]         = "战斗",
    ["Guardian"]       = "守护",
    ["Unholy"]         = "邪恶",
    ["Blood"]          = "鲜血",
    ["Brewmaster"]     = "酒仙",
    ["Mistweaver"]     = "织雾",
    ["Windwalker"]     = "踏风",
    ["Assassination"]  = "奇袭",
    ["Beast Mastery"]  = "野兽控制",
}) do
    F.SPEC_ALIAS[k] = v
end

-- 经典天赋树名，数组下标 = 插件内部 Talent_Id / TabId。
-- 顺序沿用 Boss 角色判定里的 1/2/3 索引；德鲁伊第 4 页放「守护」
-- （MainLoop 的德鲁伊分派与 Druid_Menu 均有「守护」键）。
F.SPEC_TREES = {
    PALADIN     = { "神圣", "防护", "惩戒" },
    WARRIOR     = { "武器", "狂怒", "防护" },
    PRIEST      = { "戒律", "神圣", "暗影" },
    MAGE        = { "奥术", "火焰", "冰霜" },
    WARLOCK     = { "痛苦", "恶魔学识", "毁灭" },
    HUNTER      = { "野兽控制", "射击", "生存" },
    ROGUE       = { "奇袭", "战斗", "敏锐" },
    SHAMAN      = { "元素", "增强", "恢复" },
    DEATHKNIGHT = { "鲜血", "冰霜", "邪恶" },
    DRUID       = { "平衡", "野性战斗", "恢复", "守护" },
    MONK        = { "酒仙", "织雾", "踏风" },
}

-- 取当前职业的树名表。
-- 延迟读取 UnitClassBase：插件加载期角色数据可能尚未就绪，不能在加载时缓存。
-- 返回：数组（未知职业返回空表，让上层走「默认专精 / 未激活」兜底）
function WR_Forever_SpecTrees()
    local cls
    if type(UnitClassBase) == "function" then
        cls = UnitClassBase("player")
    end
    if not cls and type(UnitClass) == "function" then
        cls = select(2, UnitClass("player"))
    end
    return F.SPEC_TREES[cls] or {}
end

-- ============================================================
-- ★ 3.1 专精签名技能表（2026-11-06 新增，用于「按已学会技能反推专精」）
-- ------------------------------------------------------------
-- 背景：无限 1.60.x 客户端 GetSpecialization() 恒为 1、
--   GetSpecializationInfo(1) 只返回「1486 / 圣骑士」（职业名）、
--   C_Traits 树名/配置名也都是职业名，所有「按名字」的专精探测路径
--   全部失效，最终只能落到「索引映射 index=1 → 第一页」，
--   圣骑士第一页是神圣 → 防护/惩戒都被误判成神圣。
-- 方案：各专精都有「只有点该系天赋才学得到」的签名技能。扫描玩家
--   法术书（WR_BuildSpellBookIndex）命中数量，取命中最多且无并列的系。
--   只列专精专属技能，不列各系共享的基础技能（如 圣光术/火球术）。
-- 注意：技能名以本服中文客户端为准；不存在的名字不会命中，不影响判断。
-- ============================================================
F.SPEC_SIGNATURE_SPELLS = {
    PALADIN = {
        ["神圣"] = { "神圣震击", "圣光道标", "神圣之光", "神恩术", "真理之声", "光之守夜", "圣光重担" },
        ["防护"] = { "神圣之盾", "正义盾击", "复仇者之盾", "正义之锤", "神圣牺牲", "圣殿壁垒", "迅捷审判", "庇护", "圣光之鞘" },
        ["惩戒"] = { "十字军打击", "忏悔", "命令圣印", "神圣愤怒", "复仇之怒" },
    },
    WARRIOR = {
        ["武器"] = { "致死打击", "横扫攻击", "利刃风暴", "破甲攻击", "撕裂" },
        ["狂怒"] = { "嗜血", "死亡之愿", "鲁莽", "狂暴之怒" },
        ["防护"] = { "盾牌猛击", "破釜沉舟", "震荡猛击", "盾牌格挡", "复仇", "毁灭打击" },
    },
    MAGE = {
        ["奥术"] = { "奥术冲击", "奥术飞弹", "奥术强化", "气定神闲", "奥术弹幕" },
        ["火焰"] = { "炎爆术", "燃烧", "龙息术", "冲击波" },
        ["冰霜"] = { "冰枪术", "寒冰屏障", "急速冷却", "冰冷血脉", "寒冰护体" },
    },
    PRIEST = {
        ["戒律"] = { "苦修", "痛苦压制", "神圣新星", "能量灌注" },
        ["神圣"] = { "治疗祷言", "愈合祷言", "神圣专注", "圣光涌动" },
        ["暗影"] = { "精神鞭笞", "暗影形态", "吸血鬼之触", "暗言术：死", "消散" },
    },
    DRUID = {
        ["平衡"] = { "星涌术", "飓风", "月蚀", "星辰坠落" },
        ["野性战斗"] = { "撕碎", "凶猛撕咬", "割裂", "斜掠", "猛虎之怒" },
        ["恢复"] = { "回春术", "治疗之触", "野性成长", "迅捷治愈", "生命绽放" },
        ["守护"] = { "槌击", "横扫（熊）", "狂暴恢复", "生存本能" },
    },
    ROGUE = {
        ["奇袭"] = { "毁伤", "毒伤", "冷血", "致命投掷" },
        ["战斗"] = { "剑刃乱舞", "冲动", "还击" },
        ["敏锐"] = { "暗影步", "预谋", "出血" },
    },
    SHAMAN = {
        ["元素"] = { "闪电链", "元素掌握", "雷霆风暴", "熔岩爆裂" },
        ["增强"] = { "风暴打击", "熔岩猛击", "野性狼魂", "怒火释放" },
        ["恢复"] = { "激流", "治疗之潮", "大地之盾", "自然迅捷" },
    },
    HUNTER = {
        ["野兽控制"] = { "狂野怒火", "胁迫", "杀戮命令", "野兽守护" },
        ["射击"] = { "瞄准射击", "奇美拉射击", "强击光环", "准备就绪" },
        ["生存"] = { "爆炸射击", "黑蚀箭", "陷阱掌握" },
    },
    WARLOCK = {
        ["痛苦"] = { "痛苦无常", "腐蚀之种", "吸取灵魂", "生命虹吸" },
        ["恶魔学识"] = { "恶魔变形", "召唤恶魔卫士", "灵魂链接", "恶魔牺牲" },
        ["毁灭"] = { "烧尽", "混乱箭", "暗影灼烧", "燃烧" },
    },
}

-- ============================================================
-- ★ 3.2 专精「签名天赋」按 SpellID 识别（2026-11-06，用户实测确认）
-- ------------------------------------------------------------
-- 无限天赋树用 C_Traits 存储，每个天赋节点的 definition.spellID 就是该天赋
-- 对应的法术 ID（客户端天赋窗口的 tooltip 里直接可见）。只要某节点的
-- activeRank > 0，即表示已投入该天赋。
-- 用户确认：圣骑士「盾牌壁垒」= SpellID 20127，等级 5/5，是防护系的标志天赋；
-- 因此该天赋有任意点数时直接判为防护，优先于「总点数最多」的推断
-- （低等级混点时总点数会被惩戒反超）。
-- ============================================================
F.SPEC_TALENT_SIGNATURES = {
    PALADIN = {
        { spec = "防护", spellID = 20127, name = "盾牌壁垒" },
    },
}

-- 职责 → 专精 兜底映射（仅在技能推断失败时使用；UnitGroupRolesAssigned）
F.SPEC_ROLE_MAP = {    PALADIN = { TANK = "防护", HEALER = "神圣", DAMAGER = "惩戒" },
    WARRIOR = { TANK = "防护" },
    DRUID   = { TANK = "守护", HEALER = "恢复" },
    PRIEST  = { HEALER = "神圣" },
    SHAMAN  = { HEALER = "恢复" },
    MONK    = { TANK = "酒仙", HEALER = "织雾" },
}

-- 专精 ID → 经典规范名（部分客户端 GetSpecialization 直接返回 specID 而非 1..N 索引）
local SPEC_ID_TO_NAME = {
    [71] = "武器",   [72] = "狂怒",   [73] = "防护",
    [65] = "神圣",   [66] = "防护",   [70] = "惩戒",
    [253] = "野兽控制", [254] = "射击", [255] = "生存",
    [259] = "奇袭",  [260] = "战斗",  [261] = "敏锐",
    [256] = "戒律",  [257] = "神圣",  [258] = "暗影",
    [250] = "鲜血",  [251] = "冰霜",  [252] = "邪恶",
    [262] = "元素",  [263] = "增强",  [264] = "恢复",
    [62] = "奥术",   [63] = "火焰",   [64] = "冰霜",
    [265] = "痛苦",  [266] = "恶魔学识", [267] = "毁灭",
    [102] = "平衡",  [103] = "野性",  [104] = "守护", [105] = "恢复",
    [268] = "酒仙",  [270] = "织雾",  [269] = "踏风",
}

-- 安全调用函数：不存在或抛错时返回 nil，不把错误冒泡到主循环。
-- 参数：fn = 待调函数（可为 nil），... = 原样透传的参数
-- 返回：最多 5 个返回值（pcall 的 ok 已剥离）
local function WR_Forever_TryCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e
end

-- 把任意候选字符串归一，并校验它确实是「本职业的某一棵天赋树」。
-- ★ 1.60.1 实测：C_SpecializationInfo.GetSpecializationInfo(1) 返回的 name
--   是职业名「圣骑士」而非专精名；若不做校验，会把职业名当成专精收下，
--   后续更可靠的 C_Traits / 索引映射路径全部被短路，专精分派永远落到第一页。
-- 参数：raw —— 待校验名字（中/英，可为「职业名+专精名」组合名）
-- 返回：规范中文专精名；不是专精名返回 nil
local function WR_Forever_MatchSpecCandidate(raw)
    if type(raw) ~= "string" or raw == "" then return nil end
    -- 明确排除本地化职业名
    if type(UnitClass) == "function" then
        local localizedClass = UnitClass("player")
        if raw == localizedClass then return nil end
    end
    local cand = WR_Forever_NormalizeSpec(raw)
    local trees = WR_Forever_SpecTrees()
    -- 1) 精确命中（含中/英别名归一）
    for _, treeName in ipairs(trees) do
        if WR_Forever_NormalizeSpec(treeName) == cand then return cand end
    end
    -- 2) 中文组合名，如「圣骑士-防护」
    for _, treeName in ipairs(trees) do
        local norm = WR_Forever_NormalizeSpec(treeName)
        if cand:find(norm, 1, true) then return norm end
    end
    -- 3) 英文组合名，如「Protection Paladin」
    for alias, norm in pairs(F.SPEC_ALIAS) do
        if cand:find(alias, 1, true) then
            for _, treeName in ipairs(trees) do
                if WR_Forever_NormalizeSpec(treeName) == norm then return norm end
            end
        end
    end
    return nil
end

-- 解析当前激活专精。
-- 返回：规范中文名（识别失败返回 nil）、来源说明字符串。
-- 说明：Boss 文件每 tick 会多次调 GetTalentTabInfo，这里按 1 秒 TTL 缓存探测结果；
--       切天赋/换专精最多 1 秒后自动生效。
local _activeSpec = { name = "", source = "", time = -1 }

function WR_Forever_GetActiveSpec()
    -- 手工覆盖优先级最高（/mkfspec <专精名>）
    local override = type(PigSet) == "table" and PigSet.FOREVER_SPEC or nil
    if type(override) == "string" and override ~= "" then
        return WR_Forever_NormalizeSpec(override), "手工覆盖 (/mkfspec)"
    end

    local now = (type(GetTime) == "function" and GetTime()) or 0
    -- 成功与失败都缓存 1 秒：失败时不缓存会导致 Boss 文件每次调
    -- GetTalentTabInfo 都重跑整条探测链，白白消耗 CPU。
    if _activeSpec.time >= 0 and now - _activeSpec.time < 1 then
        if _activeSpec.name ~= "" then
            return _activeSpec.name, _activeSpec.source
        end
        return nil, _activeSpec.source
    end

    -- 每次真实探测都留一份明细，供 /mkfspec 排错（只在 1 秒缓存失效时创建）
    local probe = {}
    F.LAST_PROBE = probe

    local CSI = (type(C_SpecializationInfo) == "table" or type(C_SpecializationInfo) == "userdata")
                and C_SpecializationInfo or nil
    local name, source
    local cls
    if type(UnitClassBase) == "function" then cls = UnitClassBase("player") end
    if not cls and type(UnitClass) == "function" then cls = select(2, UnitClass("player")) end

    -- 路径 1：现代专精 API（C_SpecializationInfo 命名空间或同名全局函数）。
    -- ★ 所有候选名字必须过 WR_Forever_MatchSpecCandidate，避免把「职业名」误收为专精名。
    local specIndex = WR_Forever_TryCall(CSI and CSI.GetSpecialization)
    if type(specIndex) ~= "number" and type(GetSpecialization) == "function" then
        specIndex = WR_Forever_TryCall(GetSpecialization)
    end
    probe.specIndex = tostring(specIndex)
    if type(specIndex) == "number" and specIndex >= 1 and specIndex <= 20 then
        local a, b, c = WR_Forever_TryCall(CSI and CSI.GetSpecializationInfo, specIndex)
        probe.specInfoCSI = (type(a) == "table" and tostring(a.name or a.specName))
                            or (tostring(a) .. " / " .. tostring(b))
        if a == nil and type(GetSpecializationInfo) == "function" then
            a, b, c = WR_Forever_TryCall(GetSpecializationInfo, specIndex)
            probe.specInfoGlobal = tostring(a) .. " / " .. tostring(b)
        end

        -- 收集所有可能的名字字段，逐一校验；任一命中即采用
        local specID, candidates = nil, {}
        if type(a) == "table" then
            specID = a.id or a.specID or a.specializationID
            candidates[#candidates + 1] = a.name
            candidates[#candidates + 1] = a.specName
            candidates[#candidates + 1] = a.localizedName
            candidates[#candidates + 1] = a.className
        end
        candidates[#candidates + 1] = (type(b) == "string" and b) or nil
        candidates[#candidates + 1] = (type(c) == "string" and c) or nil
        candidates[#candidates + 1] = (type(a) == "string" and a) or nil
        for _, raw in ipairs(candidates) do
            local matched = WR_Forever_MatchSpecCandidate(raw)
            if matched then
                name   = matched
                source = "专精 API (index=" .. tostring(specIndex) .. ", raw=" .. tostring(raw) .. ")"
                break
            end
        end
        if not name and specID and SPEC_ID_TO_NAME[specID] then
            name = WR_Forever_MatchSpecCandidate(SPEC_ID_TO_NAME[specID])
            if name then source = "专精 ID 映射 (" .. tostring(specID) .. ")" end
        end

        -- 路径 1.5：按 classID + specIndex 精确查询（retail 的返回名就是专精名，最可靠）
        if not name then
            local classID
            if type(UnitClass) == "function" then classID = select(3, UnitClass("player")) end
            probe.classID = tostring(classID)
            if type(classID) == "number" then
                local fn = CSI and CSI.GetSpecializationInfoForClassID
                if type(fn) ~= "function" and type(GetSpecializationInfoForClassID) == "function" then
                    fn = GetSpecializationInfoForClassID
                end
                local x, y = WR_Forever_TryCall(fn, classID, specIndex)
                probe.specInfoForClassID = tostring(x) .. " / " .. tostring(y)
                -- 诊断：枚举 1..4 号专精位，确认该 API 是否真能区分专精
                local enumParts = {}
                for _si = 1, 4 do
                    local _x, _y = WR_Forever_TryCall(fn, classID, _si)
                    if _x ~= nil then
                        enumParts[#enumParts + 1] = tostring(_si) .. ":" .. tostring(_x)
                                                       .. "/" .. tostring(_y)
                    end
                end
                if #enumParts > 0 then
                    probe.specInfoEnum = table.concat(enumParts, " | ")
                end
                local matched = WR_Forever_MatchSpecCandidate((type(x) == "table" and x.name) or y)
                              or WR_Forever_MatchSpecCandidate(x)
                if matched then
                    name   = matched
                    source = "GetSpecializationInfoForClassID (" .. tostring(classID) .. ","
                             .. tostring(specIndex) .. ")"
                end
            end
        end
    end

    -- 路径 2：GetSpecialization 直接返回 specID（>20，不可能是 1..N 的专精序号）
    if not name and type(specIndex) == "number" and specIndex > 20 then
        if SPEC_ID_TO_NAME[specIndex] then
            name = WR_Forever_MatchSpecCandidate(SPEC_ID_TO_NAME[specIndex])
            if name then source = "专精 ID 映射 (GetSpecialization)" end
        else
            local a, b = WR_Forever_TryCall(CSI and CSI.GetSpecializationInfoByID, specIndex)
            if a == nil and type(GetSpecializationInfoByID) == "function" then
                a, b = WR_Forever_TryCall(GetSpecializationInfoByID, specIndex)
            end
            local raw = (type(a) == "table" and (a.name or a.specName))
                        or (type(b) == "string" and b)
                        or (type(a) == "string" and a) or nil
            local matched = WR_Forever_MatchSpecCandidate(raw)
            if matched then
                name, source = matched, "GetSpecializationInfoByID"
            end
        end
    end

    -- 路径 2.4：C_Traits 经典天赋树点数（★ 本客户端唯一权威来源）
    -- ------------------------------------------------------------
    -- 依据客户端自带的经典天赋窗口实现
    -- （EllesmereUIForeverEssentials_ClassicTalents.lua）：
    --   configID = C_ClassTalents.GetActiveConfigID()
    --   treeID   = C_Traits.GetConfigInfo(configID).treeIDs[1]
    --   groups   = C_Traits.GetGroupDisplayInfoByTreeID(treeID)   -- 三系分组
    --   nodes    = C_Traits.GetTreeNodes(treeID)
    --   info     = C_Traits.GetNodeInfo(configID, nodeID)
    --              info.activeRank / info.groupIDs / info.maxRanks
    -- 按 groupIDs 归组累加 activeRank，点数最高的一系即当前主修天赋。
    -- 这是客户端自己的天赋窗口所用的同一套数据，不存在「API 不上报专精」的问题。
    if not name and type(C_ClassTalents) == "table" and type(C_Traits) == "table"
       and type(C_ClassTalents.GetActiveConfigID) == "function"
       and type(C_Traits.GetConfigInfo) == "function"
       and type(C_Traits.GetGroupDisplayInfoByTreeID) == "function"
       and type(C_Traits.GetTreeNodes) == "function"
       and type(C_Traits.GetNodeInfo) == "function" then
        local cfgID = WR_Forever_TryCall(C_ClassTalents.GetActiveConfigID)
        local cfg = cfgID and WR_Forever_TryCall(C_Traits.GetConfigInfo, cfgID)
        local treeID = (type(cfg) == "table" and type(cfg.treeIDs) == "table") and cfg.treeIDs[1] or nil
        if treeID then
            local groups = WR_Forever_TryCall(C_Traits.GetGroupDisplayInfoByTreeID, treeID)
            if type(groups) == "table" then
                local byGroup, order = {}, {}
                for _, g in ipairs(groups) do
                    if type(g) == "table" and g.groupID then
                        byGroup[g.groupID] = {
                            name   = g.displayName or g.name,
                            points = 0,
                            order  = g.orderIndex or 0,
                        }
                        order[#order + 1] = g.groupID
                    end
                end

                local nodes = WR_Forever_TryCall(C_Traits.GetTreeNodes, treeID)
                if type(nodes) == "table" then
                    -- ★ 先做「签名天赋」SpellID 识别（用户实测：盾牌壁垒 SpellID 20127 = 防护标志）
                    local sigList = F.SPEC_TALENT_SIGNATURES and F.SPEC_TALENT_SIGNATURES[cls]
                    local sigHits = {}
                    for _, nodeID in ipairs(nodes) do
                        local info = WR_Forever_TryCall(C_Traits.GetNodeInfo, cfgID, nodeID)
                        if type(info) == "table" then
                            local rank = tonumber(info.activeRank) or 0
                            if rank > 0 then
                                if type(sigList) == "table" then
                                    -- 遍历该节点的全部 rank entry：天赋各等级可能是不同 spellID，
                                    -- 只要任一 entry 的 definition.spellID 命中签名 ID 即算命中
                                    local eids = {}
                                    if type(info.entryIDs) == "table" then
                                        for _, e in ipairs(info.entryIDs) do eids[#eids + 1] = e end
                                    end
                                    if type(info.activeEntry) == "table" and info.activeEntry.entryID then
                                        eids[#eids + 1] = info.activeEntry.entryID
                                    end
                                    local matchedSig = nil
                                    for _, eID in ipairs(eids) do
                                        local ei = WR_Forever_TryCall(C_Traits.GetEntryInfo, cfgID, eID)
                                        local defID = type(ei) == "table" and ei.definitionID or nil
                                        local di = defID and WR_Forever_TryCall(C_Traits.GetDefinitionInfo, defID) or nil
                                        local sid = type(di) == "table" and tonumber(di.spellID) or nil
                                        local dname = type(di) == "table" and (di.name or di.overrideName) or nil
                                        if sid or dname then
                                            for _, sig in ipairs(sigList) do
                                                if (sid ~= nil and sig.spellID == sid)
                                                   or (dname ~= nil and dname == sig.name) then
                                                    matchedSig = sig
                                                    break
                                                end
                                            end
                                        end
                                        if matchedSig then break end
                                    end
                                    if matchedSig then
                                        sigHits[#sigHits + 1] = tostring(matchedSig.name) .. "=" .. tostring(rank)
                                        if not name then
                                            name   = matchedSig.spec
                                            source = "签名天赋 " .. tostring(matchedSig.name) .. " (" .. tostring(rank) .. "点)"
                                        end
                                    end
                                end
                                -- 累加各系点数（用于诊断与「点数最多」兜底）
                                if type(info.groupIDs) == "table" then
                                    for _, gid in ipairs(info.groupIDs) do
                                        if byGroup[gid] then
                                            byGroup[gid].points = byGroup[gid].points + rank
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if #sigHits > 0 then probe.talentSig = table.concat(sigHits, " / ") end
                end

                local parts, bestName2, bestPts, tied = {}, nil, 0, false
                for _, gid in ipairs(order) do
                    local g = byGroup[gid]
                    parts[#parts + 1] = tostring(g.name) .. "=" .. tostring(g.points)
                    local matched = WR_Forever_MatchSpecCandidate(g.name)
                    if matched then
                        if g.points > bestPts then
                            bestName2, bestPts, tied = matched, g.points, false
                        elseif g.points == bestPts then
                            tied = true
                        end
                    end
                end
                table.sort(parts)
                if #parts > 0 then probe.talentPoints = table.concat(parts, " / ") end
                if not name and bestName2 and bestPts >= 1 and not tied then
                    name   = bestName2
                    source = "天赋树点数 (" .. bestName2 .. "=" .. tostring(bestPts) .. ")"
                end
            end
        end
    end

    -- 路径 2.5：现代类天赋树（C_ClassTalents + C_Traits）。
    -- 12.x 的类天赋树 name 通常就是专精名（enUS），经 SPEC_ALIAS 归一即可；
    -- 只接受能对应到「本职业树名表」的结果，滤掉职业通用树等噪声。
    if not name and type(C_ClassTalents) == "table"
       and type(C_ClassTalents.GetActiveConfigID) == "function"
       and type(C_Traits) == "table"
       and type(C_Traits.GetConfigInfo) == "function"
       and type(C_Traits.GetTreeInfo) == "function" then
        local configID = WR_Forever_TryCall(C_ClassTalents.GetActiveConfigID)
        probe.configID = tostring(configID)
        if type(configID) == "number" then
            local cfg = WR_Forever_TryCall(C_Traits.GetConfigInfo, configID)
            -- 配置名兜底：部分客户端 C_Traits 树名为 nil，但配置名（默认按专精命名）可用
            local cfgName = (type(cfg) == "table" and (cfg.name or cfg.displayName)) or nil
            probe.configName = tostring(cfgName)
            if not name then
                local matchedCfg = WR_Forever_MatchSpecCandidate(cfgName)
                if matchedCfg then
                    name   = matchedCfg
                    source = "C_Traits 配置名 (" .. tostring(cfgName) .. ")"
                end
            end
            local treeIDs = (type(cfg) == "table" and (cfg.treeIDs or cfg.trees)) or nil
            probe.treeIDCount = (type(treeIDs) == "table" and tostring(#treeIDs)) or "0"
            if type(treeIDs) == "table" then
                local seenNames = {}
                for _, treeID in ipairs(treeIDs) do
                    local tree = WR_Forever_TryCall(C_Traits.GetTreeInfo, treeID)
                    local raw = (type(tree) == "table" and (tree.name or tree.displayName)) or nil
                    seenNames[#seenNames + 1] = tostring(raw)
                    local matched = WR_Forever_MatchSpecCandidate(raw)
                    if matched then
                        name   = matched
                        source = "C_Traits 类天赋树 (" .. tostring(raw) .. ")"
                        break
                    end
                end
                probe.treeNames = table.concat(seenNames, " / ")
            end
        end
    end

    -- 路径 2.6：已学技能反推专精（★ 无限 1.60.1 实测关键修复）
    --   本客户端 GetSpecialization() 恒为 1、GetSpecializationInfo(1) 只返回
    --   「1486 / 圣骑士」（职业名）、C_Traits 树名与配置名也都是职业名 ——
    --   所有「按名字」的路径全部失效，最终会落到路径 3.5 的索引映射，
    --   把任何职业都判成第一页（圣骑士 = 神圣），于是防骑被当成奶骑。
    --   本路径扫描玩家法术书（WR_BuildSpellBookIndex），统计
    --   F.SPEC_SIGNATURE_SPELLS 与 WR_ForeverAbilities 中各专精专属技能的命中数，
    --   取命中最多且无并列的系。只有投入该系天赋才学得到这些技能，信号可靠。
    if not name and cls then
        local bookIdx = {}
        if type(WR_BuildSpellBookIndex) == "function" then
            local ok, t = pcall(WR_BuildSpellBookIndex)
            if ok and type(t) == "table" then bookIdx = t end
        end
        probe.spellbookCount = tostring(#(WR_Forever_SpellBookList or {}))

        local function WR_Forever_KnowsByName(zh)
            if type(zh) ~= "string" or zh == "" then return false end
            -- ① 法术书索引直接按名字命中（最可靠，含任意等级/rank）
            if bookIdx[zh] ~= nil then return true end
            -- ② 回退：名字 → spellID → IsPlayerSpell / IsSpellKnown
            local sid
            if type(WR_ResolveSpellID) == "function" then
                local ok, v = pcall(WR_ResolveSpellID, zh)
                if ok then sid = v end
            end
            if type(sid) ~= "number" then return false end
            if type(IsPlayerSpell) == "function" then
                local ok, res = pcall(IsPlayerSpell, sid)
                if ok and res then return true end
            end
            if type(IsSpellKnown) == "function" then
                local ok, res = pcall(IsSpellKnown, sid)
                if ok and res then return true end
            end
            return false
        end

        local score, detail = {}, {}
        local function WR_Forever_AddSpecScore(treeRaw, zh)
            local treeZh = treeRaw and WR_Forever_NormalizeSpec(treeRaw) or nil
            local matchedTree = treeZh and WR_Forever_MatchSpecCandidate(treeZh) or nil
            if matchedTree and WR_Forever_KnowsByName(zh) then
                score[matchedTree] = (score[matchedTree] or 0) + 1
                detail[#detail + 1] = matchedTree .. ":" .. tostring(zh)
            end
        end

        -- ① 专精专属技能表（本服经典/无限技能名）
        local sig = F.SPEC_SIGNATURE_SPELLS and F.SPEC_SIGNATURE_SPELLS[cls]
        if type(sig) == "table" then
            for treeName, list in pairs(sig) do
                if type(list) == "table" then
                    for _, zh in ipairs(list) do WR_Forever_AddSpecScore(treeName, zh) end
                end
            end
        end
        -- ② Forever 天赋数据（若该客户端确有这套天赋，可额外加权）
        if type(WR_ForeverAbilities) == "table" and type(WR_ForeverAbilities[cls]) == "table" then
            for _, rec in ipairs(WR_ForeverAbilities[cls]) do
                WR_Forever_AddSpecScore(rec.tree, rec.zh)
            end
        end

        local bestName, bestCount, tied = nil, 0, false
        for treeName, count in pairs(score) do
            if count > bestCount then
                bestName, bestCount, tied = treeName, count, false
            elseif count == bestCount then
                tied = true
            end
        end
        table.sort(detail)
        if #detail > 0 then
            probe.specSignature = table.concat(detail, " / ")
        else
            probe.specSignature = "无已学会签名技能（法术书" .. tostring(probe.spellbookCount) .. "条）"
        end
        if bestName and bestCount >= 1 and not tied then
            name   = bestName
            source = "已学专精技能推断 (" .. bestName .. "×" .. tostring(bestCount) .. ")"
        end
    end

    -- 路径 2.7：职责兜底（UnitGroupRolesAssigned）。
    --   圣骑士「TANK→防护 / HEALER→神圣 / DAMAGER→惩戒」三系可完全区分，
    --   在技能推断失败（低等级尚未学专精技能）时兜底。
    if not name and type(UnitGroupRolesAssigned) == "function" then
        local okRole, role = pcall(UnitGroupRolesAssigned, "player")
        if okRole and type(role) == "string" then
            probe.roleAssigned = role
            local map = F.SPEC_ROLE_MAP and F.SPEC_ROLE_MAP[cls]
            local mapped = map and map[role]
            if mapped then
                name   = mapped
                source = "职责推断 (" .. role .. ")"
            end
        end
    end

    -- 路径 3：经典系 GetPrimaryTalentTree（部分经典客户端仍保留）
    if not name and type(GetPrimaryTalentTree) == "function" then
        local group = 1
        if type(GetActiveTalentGroup) == "function" then
            group = WR_Forever_TryCall(GetActiveTalentGroup) or 1
        end
        local tree = WR_Forever_TryCall(GetPrimaryTalentTree, false, false, group)
        if type(tree) == "number" and tree >= 1 then
            local tabName = WR_Forever_SpecTrees()[tree]
            if tabName then
                name   = WR_Forever_NormalizeSpec(tabName)
                source = "GetPrimaryTalentTree (" .. tostring(tree) .. ")"
            end
        end
    end

    -- 路径 3.5：GetSpecialization() 的索引本身就是「当前激活专精序号」。
    -- 前面所有名字路径都失败时启用；德鲁伊现代顺序 3=守护 / 4=恢复，
    -- 与本项目树名表 3=恢复 / 4=守护 对调，需单独修正。
    if not name and type(specIndex) == "number" and specIndex >= 1 and specIndex <= 20 then
        local idxName = WR_Forever_SpecTrees()[specIndex]
        if cls == "DRUID" then
            if specIndex == 3 then idxName = "守护"
            elseif specIndex == 4 then idxName = "恢复" end
        end
        local matched = WR_Forever_MatchSpecCandidate(idxName)
        if matched then
            name   = matched
            source = "专精索引映射 (index=" .. tostring(specIndex) .. ")"
        end
        probe.indexMapped = tostring(idxName) .. " -> " .. tostring(matched)
    end

    -- 路径 4：职业默认专精（Core_Functions.lua 定义，比本文件晚加载；运行时调用即可）
    if not name and type(WR_GetDefaultSpecByClass) == "function" then
        local ok, def = pcall(WR_GetDefaultSpecByClass)
        if ok then
            local matched = WR_Forever_MatchSpecCandidate(def)
            if matched then name, source = matched, "职业默认专精兜底" end
        end
    end

    _activeSpec.name   = name or ""
    _activeSpec.source = source or "未识别"
    _activeSpec.time   = now
    if _activeSpec.name == "" then
        return nil, _activeSpec.source
    end
    return _activeSpec.name, _activeSpec.source
end

-- 记录哪些全局是本层补的，供 /mkfspec 诊断输出
F.TALENT_SHIM = {}

if type(GetNumTalentTabs) ~= "function" then
    F.TALENT_SHIM.GetNumTalentTabs = true
    -- 返回：当前职业的天赋页数
    function GetNumTalentTabs()
        return #WR_Forever_SpecTrees()
    end
end

if type(GetTalentTabInfo) ~= "function" then
    F.TALENT_SHIM.GetTalentTabInfo = true
    -- 参数：index —— 天赋页序号（1 起）
    -- 返回：tabID, 页名, nil, nil, 已投入点数, ...
    --       严格对齐本插件既有取值约定（第 2 返回值取名、第 5 返回值取点数）。
    --       越界序号返回空名 + 0 点数，保证 select(5, ...) 永远拿到数字。
    function GetTalentTabInfo(index)
        local i = tonumber(index) or 0
        local tabName = WR_Forever_SpecTrees()[i]
        if not tabName then
            return i, "", nil, nil, 0, nil, nil, nil
        end
        local active = WR_Forever_GetActiveSpec()
        local rank = (active and WR_Forever_NormalizeSpec(tabName) == active) and 1 or 0
        return i, tabName, nil, nil, rank, nil, nil, nil
    end
end

if type(GetNumTalents) ~= "function" then
    F.TALENT_SHIM.GetNumTalents = true
    -- 经典「逐条遍历天赋」在无限不可用；返回 0 让调用方循环空转（安全降级）
    function GetNumTalents() return 0 end
end

if type(GetTalentInfo) ~= "function" then
    F.TALENT_SHIM.GetTalentInfo = true
    -- 返回 nil：调用方均写成 local name, ... = GetTalentInfo(...)，nil 即「查不到」
    function GetTalentInfo() return nil end
end

if type(GetTalentInfoByID) ~= "function" then
    F.TALENT_SHIM.GetTalentInfoByID = true
    -- 返回 nil：天赋描述查询降级为「无描述」，不抛错
    function GetTalentInfoByID() return nil end
end

-- /mkfspec [auto|专精名] —— 查看天赋 API 状态、当前专精；自动探测失败时可手工指定
SLASH_MKFSPEC1 = "/mkfspec"
SlashCmdList["MKFSPEC"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    if msg ~= "" then
        if type(PigSet) ~= "table" then PigSet = {} end
        if msg:lower() == "auto" then
            PigSet.FOREVER_SPEC = nil
            print("|cff00ff00[MKHelperForever]|r 已清除专精手工覆盖，恢复自动探测。")
        else
            PigSet.FOREVER_SPEC = msg
            print("|cff00ff00[MKHelperForever]|r 激活专精已手工设为 |cffffd100" .. msg
                  .. "|r（/mkfspec auto 恢复自动）。")
        end
    end
    -- 每次执行都强制重新探测（绕开 1 秒 TTL），并让主循环下一 tick 用新结果重算缓存
    _activeSpec.name, _activeSpec.time = "", -1
    WR_TalentCache = nil

    local n, src = WR_Forever_GetActiveSpec()
    local function tag(key) return F.TALENT_SHIM[key] and "兼容层" or "原生" end
    local function exists(v) return v and "存在" or "缺失" end
    print("|cff00ff00[MKHelperForever]|r 天赋 API 诊断：")
    print("  GetTalentTabInfo     : " .. tag("GetTalentTabInfo"))
    print("  GetNumTalentTabs     : " .. tag("GetNumTalentTabs"))
    print("  GetNumTalents        : " .. tag("GetNumTalents"))
    print("  GetTalentInfo        : " .. tag("GetTalentInfo"))
    print("  GetTalentInfoByID    : " .. tag("GetTalentInfoByID"))
    print("  GetSpecialization    : " .. exists(type(GetSpecialization) == "function"))
    print("  C_SpecializationInfo : " .. exists(type(C_SpecializationInfo) == "table"
                                              or type(C_SpecializationInfo) == "userdata"))
    print("  GetPrimaryTalentTree : " .. exists(type(GetPrimaryTalentTree) == "function"))
    print("  C_ClassTalents/C_Traits: " .. exists(type(C_ClassTalents) == "table" and type(C_Traits) == "table"))
    print("  当前专精 : |cffffd100" .. tostring(n) .. "|r  ← " .. tostring(src))
    local trees = WR_Forever_SpecTrees()
    print("  天赋页数 : " .. tostring(#trees) .. "  [" .. table.concat(trees, " / ") .. "]")

    -- 探测明细：一次输出足够定位「名字解析失败」类问题，便于下一轮收敛探测链
    local CSI = (type(C_SpecializationInfo) == "table" or type(C_SpecializationInfo) == "userdata")
                and C_SpecializationInfo or nil
    local p = F.LAST_PROBE or {}
    local function pline(key, label)
        print("  " .. label .. " : " .. tostring(p[key] or "n/a"))
    end
    print("  --- 探测明细 ---")
    print("  C_SpecInfo.GetSpecialization : " .. exists(type(CSI and CSI.GetSpecialization) == "function"))
    print("  GetSpecializationInfoForClassID : " .. exists(type(CSI and CSI.GetSpecializationInfoForClassID) == "function"
                                                       or type(GetSpecializationInfoForClassID) == "function"))
    print("  C_ClassTalents.GetActiveConfigID : " .. exists(type(C_ClassTalents) == "table"
                                                         and type(C_ClassTalents.GetActiveConfigID) == "function"))
    print("  C_Traits.GetConfigInfo/GetTreeInfo : " .. exists(type(C_Traits) == "table"
                                                           and type(C_Traits.GetConfigInfo) == "function"
                                                           and type(C_Traits.GetTreeInfo) == "function"))
    print("  C_Traits 分组/节点/节点信息 : " .. exists(type(C_Traits) == "table"
                                                           and type(C_Traits.GetGroupDisplayInfoByTreeID) == "function"
                                                           and type(C_Traits.GetTreeNodes) == "function"
                                                           and type(C_Traits.GetNodeInfo) == "function"))
    pline("specIndex",            "GetSpecialization()")
    pline("specInfoCSI",          "C_SpecInfo.GetSpecializationInfo(1)")
    pline("specInfoGlobal",       "全局 GetSpecializationInfo(1)")
    pline("classID",              "UnitClass classID")
    pline("specInfoForClassID",   "GetSpecializationInfoForClassID")
    pline("specInfoEnum",         "专精位枚举 1-4")
    pline("configID",             "C_ClassTalents 激活配置")
    pline("configName",           "C_Traits 配置名")
    pline("treeIDCount",          "C_Traits 树数量")
    pline("treeNames",            "C_Traits 树名")
    pline("talentPoints",         "C_Traits 天赋树点数")
    pline("talentSig",            "签名天赋识别")
    pline("spellbookCount",       "法术书条目数")
    pline("specSignature",        "已学专精技能推断")
    pline("roleAssigned",         "UnitGroupRolesAssigned")
    pline("indexMapped",          "专精索引映射")
end

-- ============================================================
-- ★ 5. 种族 / 职业组合便捷查询（数据在 Data/Forever_Racials.lua）
-- ============================================================

-- 当前玩家种族 token（中文客户端 UnitRace 返回中文，做映射；未知返回原值）
function WR_Forever_PlayerRace()
    local ok, _, race = pcall(UnitRace, "player")
    if not ok or not race then return nil end
    local map = WR_Forever_RaceToken
    if map and map[race] then return map[race] end
    return race
end

-- 当前玩家是否为无限新增种族/组合
function WR_Forever_IsNewRaceCombo()
    local race = WR_Forever_PlayerRace()
    if not race then return false end
    if race == "Skyborne" then return true end          -- 天裔（新种族）
    local cls = UnitClassBase and UnitClassBase("player")
    for _, c in ipairs(WR_Forever_NewCombos or {}) do
        if c.class == cls then
            if c.race == "被遗忘者" and race == "Scourge" then return true end  -- 被遗忘者圣骑士
            if c.race == "矮人"     and race == "Dwarf"   then return true end  -- 矮人萨满
        end
    end
    return false
end

-- 取当前种族的爆发技能名（供 GX.lua 的 ZDZZ/CRZZ 使用）
-- ★★★ 2026-11-21 三十四次修复：从「按阵营」改为「按种族精确」。
-- ------------------------------------------------------------
-- 旧实现按阵营返回：部落恒为 {血性狂怒, 狂暴}，联盟恒为 {艾露恩之光, 尤里卡！}，
-- 再并上 BOTH（四个全给）。结果**每个角色都会拿到自己没有的种族技能**：
--   · 亡灵牧师会去试「血性狂怒」「狂暴」；
--   · 兽人战士会去试「艾露恩之光」「尤里卡！」。
-- 配合「C_Spell.IsSpellUsable 不判是否学会」（私服还会对解析不出的名字回 true），
-- 这些根本放不出来的技能被判成可用 → 每 tick 点亮种族爆发色块 → AHK 连按 →
-- 主循环永远停在爆发步。这是「1级小号牧师卡种族爆发色块」的同源根因。
--
-- 现在：优先走 WR_Forever_PlayerRacialBursts（Data/Forever_Racials.lua 里按
-- race 精确匹配，只返回本种族真实拥有的 burst 技能）；只有拿不到种族信息时
-- 才退回旧的阵营表兜底，保证极端情况下行为不退化。
function WR_Forever_GetRacialBursts()
    -- ★ 关键：种族**能解析出来**时就完全信任精确结果，哪怕是空表。
    --   亡灵/牛头/人类等种族本身没有 burst 向特长，精确结果必然是 {}；
    --   此时若退回阵营表，就等于又把「血性狂怒/狂暴」塞回去 —— 正是本次要修的坑。
    --   只有「种族读不到」（UnitRace 失败 / 数据表未加载）才退回阵营兜底。
    local list = nil
    if type(WR_Forever_PlayerRacialBursts) == "function" then
        local okP, precise = pcall(WR_Forever_PlayerRacialBursts)
        if okP and type(precise) == "table" then
            local raceOK = false
            if type(WR_Forever_PlayerRace) == "function" then
                local okR, race = pcall(WR_Forever_PlayerRace)
                raceOK = okR and type(race) == "string" and race ~= ""
            end
            if raceOK or #precise > 0 then
                list = precise
            end
        end
    end
    if list == nil then
        local tbl = WR_Forever_RacialSpells
        if not tbl or not tbl.burst then return {} end
        local faction = (UnitFactionGroup and UnitFactionGroup("player")) or "Horde"
        local side = (faction == "Alliance") and "ALLIANCE" or "HORDE"
        list = {}
        for _, s in ipairs(tbl.burst[side] or {}) do list[#list + 1] = s end
        for _, s in ipairs(tbl.burst.BOTH or {}) do list[#list + 1] = s end
    end

    -- ★★★ 2026-11-21 三十五次修复：「种族爆发用了还一直亮」——CD 维在源头收口。
    -- ------------------------------------------------------------
    -- 各职业的种族爆发步（战士三系 / 德鲁伊三系 / 猎人三系 / 法师三系 / 萨满两系 /
    -- 术士三系 / 牧师戒律）都从本函数取列表，然后逐个问 WR_SpellUsable。而
    -- 无限战斗中 GetSpellCooldown 是 secret → WR_GetGCD 收敛成 0 →
    -- WR_SpellUsable 的 GCD 门恒成立 → 3 分钟冷却的种族大招（狂暴 spellID 20554）
    -- 打出去之后仍然被判「可用」→ 每 tick 重亮同一槽位 → AHK 连按 → 用户看到的
    -- 「使用了种族技能还是一直亮」。
    -- 这里在**取列表的源头**就按 CD 过滤掉还没好的技能：只要这里剔掉，所有职业
    -- 一次性修好，不用逐份职业文件改（三十四次修复的「已学会」过滤同理）。
    -- 注意：**只过滤本函数**。宏注入（Core/Forever_Hooks.lua 的 InjectRacialLines）
    -- 用的是 WR_Forever_PlayerRacialBursts，那条路在建宏时（登录 / 切天赋）执行，
    -- 此刻不可能有 CD，不能被这里影响，否则会漏注入 /cast 行。
    if type(WR_Forever_BurstReady) == "function" then
        local cdTbl = WR_Forever_RacialBurstCD
        local defCD = WR_Forever_RACIAL_BURST_DEFAULT_CD or 180
        local out = {}
        for i = 1, #list do
            local name = list[i]
            if type(name) == "string" and name ~= "" then
                local cd = (type(cdTbl) == "table" and cdTbl[name]) or defCD
                local okB, ready = pcall(WR_Forever_BurstReady, name, cd)
                -- 读不到（pcall 失败）一律保留，宁可多给一个候选也不误杀
                if not okB or ready == true then out[#out + 1] = name end
            end
        end
        return out
    end
    return list
end

-- ============================================================
-- ★ 6. 斜杠命令
-- ============================================================

-- /mkfclient —— 输出客户端识别诊断
SLASH_MKFCLIENT1 = "/mkfclient"
SlashCmdList["MKFCLIENT"] = function()
    local i = WR_Forever_GetClientInfo()
    _clientInfo = i
    print("|cff00ff00[MKHelperForever]|r 客户端识别：")
    print("  项目 ID   : " .. tostring(i.projectID) .. "  (" .. i.projectName .. ")")
    print("  构建号    : " .. tostring(i.build) .. " / " .. tostring(i.version))
    print("  接口版本  : " .. tostring(i.interface))
    print("  符文 API  : " .. (i.hasEngraving and "|cff00ff00存在|r（探索赛季）" or "|cff888888不存在|r"))
    print("  判定模式  : |cffffd100" .. tostring(i.mode) .. "|r  ← " .. tostring(i.modeSource))
    if i.uncertain then
        print("  |cffff8800注意：该判定为推测值，若与实际不符请执行 /mkfmode forever 或 /mkfmode sod 手工指定。|r")
    end
    print("  当前职业  : " .. tostring(i.class))
end

-- /mkfmode <auto|forever|sod> —— 手工指定客户端模式
SLASH_MKFMODE1 = "/mkfmode"
SlashCmdList["MKFMODE"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$"):lower()
    if msg == "forever" or msg == "sod" or msg == "auto" then
        PigSet.FOREVER_MODE = (msg == "auto") and nil or msg
        _clientInfo = nil
        print("|cff00ff00[MKHelperForever]|r 客户端模式已设为 |cffffd100" .. msg .. "|r，重新识别：")
        SlashCmdList["MKFCLIENT"]()
    else
        print("|cff00ff00[MKHelperForever]|r 用法：/mkfmode auto | forever | sod")
    end
end


-- ============================================================
-- ★ 6. 12.x 法术 API 归一化层（技能名 → spellID 解析 + 返回值形状归一）
-- ------------------------------------------------------------
-- 背景（「很多技能没和无限版本匹配 / 技能全不亮」的直接技术根因）：
--   1) 插件 296 处 WR_SpellUsable / WR_GetGCD / GetSpellCooldown 全部传入
--      **中文技能名**。12.x 的 C_Spell.GetSpellInfo / IsSpellUsable /
--      GetSpellCooldown 只接受 spellID（或英文标识符），传中文名返回 nil，
--      于是 WR_SpellUsable 恒 false，整条职业循环一个技能都不出。
--   2) Core/Core_Functions.lua:143 与 Core/ZZ_Features_Migration.lua:3568
--      已把旧全局映射到 C_Spell，但都把返回值当经典多返回值透传；
--      12.x 的 C_Spell.GetSpellInfo 恒返回 table，冷却/充能在不同补丁里
--      可能是 table 或多值 → 解构处拿到 start=table、duration=nil，
--      WR_GetGCD 的 GCD 恒 0，Paladin_Retribution_Check 对 table 做算术报错。
-- 方案（纯附加，SoD 客户端上退化为直通，不改既有行为）：
--   · 一次性遍历法术书建立「本地化名字 → spellID」索引并缓存；
--   · WR_ResolveSpellID() 把中文名解析成 ID，解析失败才原样透传；
--   · WR_SpellCooldownInfo / WR_SpellChargesInfo / WR_SpellInfoCompat /
--     WR_IsSpellUsableCompat 自适应 table 与多值两种返回形状；
--   · 关键调用点显式改用上述归一化函数（见 Core_Functions.lua 等）。
-- ============================================================

WR_Forever_SpellBookIndex = WR_Forever_SpellBookIndex or nil  -- 名字 → spellID
WR_Forever_SpellBookList  = WR_Forever_SpellBookList  or nil  -- 法术书全量条目
WR_Forever_SpellIDCache   = WR_Forever_SpellIDCache   or {}   -- 名字 → ID / false

-- 受保护的 API 调用：任何异常都降级为 nil，绝不让职业循环因单个 API 中断
local function WR_Forever_Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g, h
end

-- 数字归一：table / nil / secret value / 非数字一律取默认值
local function WR_Forever_Num(v, dflt)
    -- ★ 无限适配：secret number 不能参与算术/比较，必须先收敛
    if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(v) then
        return dflt or 0
    end
    local ok, n = pcall(tonumber, v)
    if ok and type(n) == "number" then
        if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(n) then
            return dflt or 0
        end
        return n
    end
    return dflt or 0
end

-- 遍历法术书，建立本地化技能名 → spellID 索引。
-- 参数：force —— true 时强制重建（登录 / 天赋变更 / /mkfspells 时使用）
-- 返回：索引表（可能为空表，表示法术书 API 全不可用或尚未就绪）
-- 说明：同时兼容 C_SpellBook 新版命名空间与经典 GetSpellTabInfo /
--       GetSpellBookItemName 全局，全部经 WR_Forever_Call 保护。
function WR_BuildSpellBookIndex(force)
    if WR_Forever_SpellBookIndex and not force then return WR_Forever_SpellBookIndex end
    local idx, list = {}, {}
    -- ★ 2026-11-10：法术书条目的名字通常带「（等级 N）」后缀（例如「神圣打击（等级 5）」），
    --   旧的 idx[nm] 只能精确匹配全名，导致 WR_ResolveSpellID("神圣打击") 查不到当前 rank，
    --   只能退回写死的 Rank3 ID 1866 —— 角色升到 28 级以上后旧 rank 失效，
    --   IsUsableSpell(1866) 返回 false，整条神圣打击链路都不亮。
    --   这里额外建立「去掉等级后缀的基础名 → 最高 rank 条目」索引，供 WR_ResolveSpellID 使用。
    local baseRank = {}  -- 基础名 → { id = spellID, rank = 等级数字 }
    local CSB = (type(C_SpellBook) == "table") and C_SpellBook or nil
    local CSP = (type(C_Spell) == "table") and C_Spell or nil
    local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player)
                 or BOOKTYPE_SPELL or "spell"

    local numTabs = 0
    if CSB and type(CSB.GetNumSpellBookSkillLines) == "function" then
        numTabs = WR_Forever_Num(WR_Forever_Call(CSB.GetNumSpellBookSkillLines), 0)
    elseif type(GetNumSpellTabs) == "function" then
        numTabs = WR_Forever_Num(WR_Forever_Call(GetNumSpellTabs), 0)
    end
    if numTabs > 40 then numTabs = 40 end

    for tab = 1, numTabs do
        local offset, count, tabName = 0, 0, nil
        if CSB and type(CSB.GetSpellBookSkillLineInfo) == "function" then
            local t = WR_Forever_Call(CSB.GetSpellBookSkillLineInfo, tab)
            if type(t) == "table" then
                offset  = WR_Forever_Num(t.itemIndexOffset, 0)
                count   = WR_Forever_Num(t.numSpellBookItems, 0)
                tabName = t.name
            end
        end
        if count == 0 and type(GetSpellTabInfo) == "function" then
            local name, icon, off, cnt = WR_Forever_Call(GetSpellTabInfo, tab)
            if cnt then
                tabName = name or tabName
                offset  = WR_Forever_Num(off, 0)
                count   = WR_Forever_Num(cnt, 0)
            end
        end
        local limit = math.min(count, 200)
        for j = 1, limit do
            local slot = offset + j
            local sid, nm = nil, nil
            if CSB and type(CSB.GetSpellBookItemInfo) == "function" then
                local t = WR_Forever_Call(CSB.GetSpellBookItemInfo, slot, bank)
                if type(t) == "table" then
                    sid = t.spellID
                    if type(t.name) == "string" then nm = t.name end
                elseif type(t) == "number" then
                    sid = t
                end
            end
            if not sid and type(GetSpellBookItemInfo) == "function" then
                local typ, id = WR_Forever_Call(GetSpellBookItemInfo, slot, bank)
                if type(id) == "number" then sid = id end
            end
            if type(GetSpellBookItemName) == "function" then
                -- 经典版返回 name, subName；零售版多一个 spellID，两种都收
                local n, sub, nID = WR_Forever_Call(GetSpellBookItemName, slot, bank)
                if type(n) == "string" and n ~= "" then nm = n end
                if not sid and type(nID) == "number" then sid = nID end
            end
            if sid and (not nm or nm == "") and CSP and type(CSP.GetSpellInfo) == "function" then
                local t = WR_Forever_Call(CSP.GetSpellInfo, sid)
                if type(t) == "table" then nm = t.name end
            end
            if sid then
                if nm and nm ~= "" then
                    idx[nm] = sid
                    -- ★ 注意：Lua 5.1 的字符类按字节匹配，不能把多字节全角括号放进 [...]
                    --   里（[（(] 只匹配单字节）。这里分两步用字面量多字节串去剥后缀：
                    --   先全角「（等级 N）」，再半角「(等级 N)」。
                    local base = string.gsub(nm, "%s*（等级%s*%d+）%s*$", "")
                    if base == nm then
                        base = string.gsub(nm, "%s*%(等级%s*%d+%)%s*$", "")
                    end
                    if base ~= "" and base ~= nm then
                        local rankNo = tonumber(string.match(nm, "等级%s*(%d+)")) or 0
                        local cur = baseRank[base]
                        if not cur or rankNo >= cur.rank then
                            baseRank[base] = { id = sid, rank = rankNo }
                        end
                    end
                end
                list[#list + 1] = { id = sid, name = nm or "", tab = tabName or "", slot = slot }
            end
        end
    end
    for base, rec in pairs(baseRank) do
        idx[base] = rec.id
    end
    WR_Forever_SpellBookIndex = idx
    WR_Forever_SpellBookList  = list
    return idx
end

-- 中文技能名 → spellID。带缓存（含「确认不存在」的负缓存），避免每 tick 反复查 API。
-- 返回：spellID（number）或 nil；法术书尚未就绪时不写负缓存，防止登录后被永久判死。
function WR_ResolveSpellID(spell)
    if type(spell) == "number" then return spell end
    if type(spell) ~= "string" or spell == "" then return nil end
    -- ★ 无限适配（方案 A 全局技能存在性注册表）：已知无限客户端法术库里
    --   不存在的技能名（WotLK/SoD 专属，如 复仇之怒/神圣风暴/圣光道标/正义之锤/
    --   复仇者之盾/星落/裂伤/野蛮咆哮/杀戮射击/混乱箭…）直接判死，跳过运行时
    --   API 探测与负缓存抖动，所有下游冷却/可用性/充能查询同步跳过。
    --   注册表由 Data/Forever_SkillRegistry.lua 提供，未覆盖的引用名仍走运行时兜底。
    if WR_Forever_SkillAbsent and WR_Forever_SkillAbsent[spell] then
        WR_Forever_SpellIDCache[spell] = false
        return nil
    end
    -- ★ 2026-11-06：强制 ID（IsPlayerSpell 不可靠的核心技能）
    -- ★★ 2026-11-10：强制 ID 只作兜底，优先用「法术书基础名索引」里的当前 rank。
    --   原因：神圣打击共 8 个 rank（678/679/1866/680/2495/5569/10332/10333），
    --   写死 Rank3 的 1866 后，角色升到 28 级以上会换 rank，旧 rank 不再可用；
    --   IsUsableSpell(1866) 返回 false → WR_SpellUsable("神圣打击") 恒 false →
    --   防护循环 hsEligible 恒 false，神圣打击 CD 好了也永远不亮色块。
    if F.SPELL_ID_FORCE and F.SPELL_ID_FORCE[spell] then
        local idx = WR_BuildSpellBookIndex()
        local current = idx and idx[spell]
        if type(current) == "number" then
            WR_Forever_SpellIDCache[spell] = current
            return current
        end
        return F.SPELL_ID_FORCE[spell]
    end
    -- ★ 2026-11-06：本服法术 ID 变动覆盖（祝福类）。已学会才采用，否则继续按法术书索引。
    local fixedID = F.SPELL_ID_OVERRIDES and F.SPELL_ID_OVERRIDES[spell]
    if fixedID then
        if type(IsPlayerSpell) ~= "function" then return fixedID end
        local okKnown, known = pcall(IsPlayerSpell, fixedID)
        if okKnown and known then return fixedID end
    end
    local cached = WR_Forever_SpellIDCache[spell]
    if cached ~= nil then
        return (cached ~= false) and cached or nil
    end

    local sid
    local idx = WR_BuildSpellBookIndex()
    if idx then sid = idx[spell] end
    if not sid and type(C_Spell) == "table" and type(C_Spell.GetSpellInfo) == "function" then
        local t = WR_Forever_Call(C_Spell.GetSpellInfo, spell)
        if type(t) == "table" then sid = t.spellID end
    end
    if not sid and type(GetSpellInfo) == "function" then
        local a, b, c, d, e, f, g = WR_Forever_Call(GetSpellInfo, spell)
        if type(a) == "table" then sid = a.spellID
        elseif type(g) == "number" then sid = g end
    end
    if sid or (WR_Forever_SpellBookList and #WR_Forever_SpellBookList > 0) then
        WR_Forever_SpellIDCache[spell] = sid or false
    end
    return sid
end

-- 冷却信息归一：恒返回 4 个普通 number（start, duration, isEnabled, modRate）
function WR_SpellCooldownInfo(spell)
    local key = WR_ResolveSpellID(spell) or spell
    if key == nil then return 0, 0, true, 1 end
    local a, b, c, d
    if type(C_Spell) == "table" and type(C_Spell.GetSpellCooldown) == "function" then
        a, b, c, d = WR_Forever_Call(C_Spell.GetSpellCooldown, key)
    end
    if a == nil and type(GetSpellCooldown) == "function" then
        a, b, c, d = WR_Forever_Call(GetSpellCooldown, key)
    end
    if type(a) == "table" then
        local t = a
        return WR_Forever_Num(t.startTime or t.start or 0, 0),
               WR_Forever_Num(t.duration or 0, 0),
               (t.isEnabled == nil) and true or t.isEnabled,
               WR_Forever_Num(t.modRate or 1, 1)
    end
    return WR_Forever_Num(a, 0), WR_Forever_Num(b, 0),
           (c == nil) and true or c, WR_Forever_Num(d, 1)
end

-- 充能信息归一：恒返回 (charges, maxCharges, cdStart, cdDuration)
function WR_SpellChargesInfo(spell)
    local key = WR_ResolveSpellID(spell) or spell
    if key == nil then return nil end
    local a, b, c, d
    if type(C_Spell) == "table" and type(C_Spell.GetSpellCharges) == "function" then
        a, b, c, d = WR_Forever_Call(C_Spell.GetSpellCharges, key)
    end
    if a == nil and type(GetSpellCharges) == "function" then
        a, b, c, d = WR_Forever_Call(GetSpellCharges, key)
    end
    if type(a) == "table" then
        local t = a
        return WR_Forever_Num(t.charges or t.currentCharges, 0),
               WR_Forever_Num(t.maxCharges, 0),
               WR_Forever_Num(t.cooldownStart or t.chargeStart or t.startTime, 0),
               WR_Forever_Num(t.cooldownDuration or t.chargeDuration or t.duration, 0)
    end
    return WR_Forever_Num(a, 0), WR_Forever_Num(b, 0), WR_Forever_Num(c, 0), WR_Forever_Num(d, 0)
end

-- 法术信息归一：恒返回经典 8 值（name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon）
function WR_SpellInfoCompat(spell)
    local key = (type(spell) == "string") and (WR_ResolveSpellID(spell) or spell) or spell
    local a, b, c, d, e, f, g, h
    if type(C_Spell) == "table" and type(C_Spell.GetSpellInfo) == "function" then
        a, b, c, d, e, f, g, h = WR_Forever_Call(C_Spell.GetSpellInfo, key)
    end
    if a == nil and type(GetSpellInfo) == "function" then
        a, b, c, d, e, f, g, h = WR_Forever_Call(GetSpellInfo, key)
    end
    if type(a) == "table" then
        local t = a
        return t.name, nil, t.iconID, WR_Forever_Num(t.castTime, 0),
               WR_Forever_Num(t.minRange, 0), WR_Forever_Num(t.maxRange, 0),
               t.spellID, t.originalIconID
    end
    return a, b, c, WR_Forever_Num(d, 0), WR_Forever_Num(e, 0), WR_Forever_Num(f, 0), g, h
end

-- ============================================================
-- ★★★ 2026-11-12 用户口径：「技能不够蓝释放时，应当不亮色块，导致一直按按键」
-- ------------------------------------------------------------
-- 现象：法力不够 → 色块仍然亮 → AHK 按该色块对应的键 → 客户端拒绝施放
--       → 色块不灭（循环每 tick 又点亮）→ AHK 继续按，形成空按死循环。
--
-- 旧实现的三个缺陷（都在本段修掉）：
--   ① IsUsableSpell / C_Spell.IsSpellUsable 返回 (usable, noMana) 两个值，
--      旧代码只取第 1 个 `a`，把「缺法力」的第二返回值彻底丢掉。
--      很多客户端在法力不足时第 1 个返回值仍是 true（第 2 个才报缺资源），
--      于是 WR_SpellUsable 恒 true → 色块常亮。
--   ② 12.x 的 C_Spell.IsSpellUsable 可能返回 **table**
--      { isUsable=?, insufficientPower=? }；旧代码把 table 直接当真值
--      （`a and true or false`）→ 恒 true。
--   ③ 完全没有「当前资源 vs 技能消耗」的比对，只能等客户端报错。
--
-- 现在：缺资源信号一律优先判死；客户端不给信号时自己用 GetSpellPowerCost 比一次。
-- ============================================================

-- ★★ 注意（本文件的老坑，别再踩）：这里**不能**用 `type(f) == "function"` 守卫。
--   真实客户端里 WoW 接口是 Lua function，但离线夹具（Python + Lupa）里是
--   Python 可调用对象，`type()` 返回 "userdata" → 守卫恒 false → 整段被静默
--   跳过，夹具里「蓝不够不亮」永远测不出来。统一改用 pcall 探测：
--   pcall 对 nil / 任意 callable 都安全，返回 ok=false 即视为「接口不可用」。
local function WR_Forever_TryCall(fn, ...)
    if fn == nil then return false end
    return pcall(fn, ...)
end

-- 布尔归一：secret / nil / 非布尔 → nil（= 读不到，绝不猜成 true/false）
local function WR_Forever_Bool(v)
    if v == nil then return nil end
    if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(v) then return nil end
    if v == true then return true end
    if v == false then return false end
    if type(v) == "number" then return v ~= 0 end
    return nil
end

-- 可用性返回形状归一：
--   经典客户端：IsUsableSpell(id) → usable, noMana（多返回值）
--   12.x 客户端：C_Spell.IsSpellUsable(id) → 可能是 table { isUsable, insufficientPower }
local function WR_Forever_ParseUsable(a, b)
    if type(a) == "table" then
        local u = a.isUsable
        if u == nil then u = a.usable end
        local np = a.insufficientPower
        if np == nil then np = a.noMana end
        return u, np
    end
    return a, b
end

-- 解析一次可用性结果 → usable(bool/nil), blockedByPower(bool), unreadable(bool)
local function WR_Forever_TakeUsable(a, b)
    local u, np = WR_Forever_ParseUsable(a, b)
    if WR_Forever_Bool(np) == true then return nil, true, false end
    local ub = WR_Forever_Bool(u)
    if ub ~= nil then return ub, false, false end
    if u ~= nil then return nil, false, true end   -- secret 值：读不到，不算 true
    return nil, false, false
end

-- 技能资源消耗（按 spellID 缓存；取不到缓存 false，绝不当 0）
WR_Forever_PowerCostCache = WR_Forever_PowerCostCache or {}

-- 允许做「够不够」判断的资源类型：法力0 / 怒气1 / 集中值2 / 能量3 / 符文能量6。
-- 其它（连击点4 / 符文5 / 灵魂碎片7 / 圣能9 …）一律不判，避免误挡。
local WR_FOREVER_POWER_TYPES = { [0] = true, [1] = true, [2] = true, [3] = true, [6] = true }

local function WR_Forever_ParsePowerCost(t)
    if type(t) ~= "table" then return nil end
    local bestCost, bestType
    for _, e in ipairs(t) do
        if type(e) == "table" then
            local c = WR_Forever_Num(e.cost, 0)
            local rawType = e.type
            if rawType == nil then rawType = e.powerType end
            local pt = WR_Forever_Num(rawType, 0)
            if c > 0 and WR_FOREVER_POWER_TYPES[pt] then
                if not bestCost or c > bestCost then
                    bestCost, bestType = c, pt
                end
            end
        end
    end
    if bestCost then return bestCost, bestType end
    return nil
end

-- 返回 cost, powerType；取不到返回 nil（调用方必须按「不判断」处理）
--
-- ★★ 负缓存必须带过期时间：
--   登录初期法术书尚未就绪 / 换天赋换 rank 之后，GetSpellPowerCost 会有一段时间
--   返回空。如果像旧实现那样把「取不到」永久记成 false，这个技能就再也不会被
--   「资源够不够」检查一次 —— 蓝不够时色块照样常亮，正是用户反馈的现象。
--   现在负缓存 3 秒过期，之后自动重探。
WR_FOREVER_POWER_COST_NEG_TTL = 3
function WR_Forever_SpellPowerCost(spell)
    if spell == nil then return nil end
    local cached = WR_Forever_PowerCostCache[spell]
    if cached ~= nil then
        if cached == false then return nil end
        if cached.neg then
            if (GetTime() - (cached.at or 0)) < WR_FOREVER_POWER_COST_NEG_TTL then
                return nil
            end
            WR_Forever_PowerCostCache[spell] = nil   -- 负缓存过期 → 重探
        else
            return cached.cost, cached.ptype
        end
    end
    local cost, ptype
    local okG, t = WR_Forever_TryCall(GetSpellPowerCost, spell)
    if okG and type(t) == "table" then
        cost, ptype = WR_Forever_ParsePowerCost(t)
    end
    if not cost and type(C_Spell) == "table" then
        local okC, t2 = WR_Forever_TryCall(C_Spell.GetSpellPowerCost, spell)
        if okC and type(t2) == "table" then
            cost, ptype = WR_Forever_ParsePowerCost(t2)
        end
    end
    if cost then
        WR_Forever_PowerCostCache[spell] = { cost = cost, ptype = ptype }
        return cost, ptype
    end
    WR_Forever_PowerCostCache[spell] = { neg = true, at = GetTime() }
    return nil
end

-- 当前资源值（同一帧内按 powerType 缓存 0.05 秒，避免热路径反复读）
WR_Forever_PowerNowCache = WR_Forever_PowerNowCache or {}
local function WR_Forever_CurrentPower(ptype)
    local now = GetTime()
    local c = WR_Forever_PowerNowCache[ptype]
    if c and (now - (c.at or 0)) < 0.05 then return c.cur end
    local ok, v = pcall(UnitPower, "player", ptype)
    local cur = nil
    if ok then
        if type(WR_SafeNumber) == "function" then
            cur = WR_SafeNumber(v, nil)
        elseif type(v) == "number" and not (type(WR_IsSecretValue) == "function" and WR_IsSecretValue(v)) then
            cur = v
        end
    end
    WR_Forever_PowerNowCache[ptype] = { at = now, cur = cur }
    return cur
end

-- ★★★ 核心判定：返回 true = 资源确实不够（调用方必须判死）；
--   false = 够 / 无消耗 / 读不到（一律放行，宁可少判不可误挡）。
function WR_Forever_NotEnoughPower(spell)
    local key = spell
    if type(key) == "string" then
        -- 同样不能用 type() 守卫（夹具里 WR_ResolveSpellID 可能是 userdata）
        local okR, v = WR_Forever_TryCall(WR_ResolveSpellID, key)
        if not okR then return false end
        key = v
    end
    if type(key) ~= "number" then return false end
    local cost, ptype = WR_Forever_SpellPowerCost(key)
    if not cost or cost <= 0 then return false end
    local cur = WR_Forever_CurrentPower(ptype or 0)
    if type(cur) ~= "number" then return false end
    return cur < cost
end

-- ============================================================
-- ★★★ 2026-11-21 三十四次修复：「是否已学会」独立判据
-- ------------------------------------------------------------
-- 用户口径：「1级小号牧师会卡种族爆发色块」。
--
-- 根因：把「此刻能不能放」和「有没有这个技能」混成了一件事。
--   · 12.x 的 C_Spell.IsSpellUsable(spellID) 只判资源/CD/形态，**不判是否学会**；
--     私服实现甚至对解析不出的名字直接回 true。
--   · 旧 WR_IsSpellUsableCompat 在 usable==true 时直接放行，于是「玩家根本
--     没有的种族技能」（例：亡灵牧师没有 血性狂怒 / 狂暴）被判成可用。
--   · 种族爆发步随即点亮宏槽 181 → AHK 连按 ALT-CTRL-SHIFT-PAGEDOWN →
--     宏里三条 /cast 全是没学会的技能，客户端一个都不执行 → 色块每 tick 又亮
--     → 主循环永远停在爆发步，后面的惩击/治疗一步都轮不到。
--
-- 本函数把「已学会」抽成独立判据，供可用性闸与各职业种族爆发步共用：
--   返回 true  = 确认已学会（法术书能解析出 spellID）
--   返回 false = 确认没学会（法术书已就绪且解析不到）
--   返回 nil   = 读不到（法术书尚未就绪 / 名字非法）→ 调用方一律放行
-- 口径与全仓一致：宁可少判，不可把正常技能误杀。
-- ============================================================
function WR_Forever_SpellLearned(spell)
    if spell == nil then return nil end

    -- ① 已经是 spellID：不再猜，直接认为存在（调用方自己拿到了 ID）
    if type(spell) == "number" then return true end
    if type(spell) ~= "string" or spell == "" then return nil end

    -- ② 名字 → spellID。解析成功 = 该技能在当前角色法术书里（或强制/覆盖表里）
    local okR, sid = WR_Forever_TryCall(WR_ResolveSpellID, spell)
    if okR and type(sid) == "number" then return true end

    -- ③ 兜底直查：法术书索引可能因遍历不全 / 战斗中未重建而漏项，
    --   这时直接问客户端「这个技能你会不会」。任一回答 true 就放行。
    local okP, isPlayer = WR_Forever_TryCall(IsPlayerSpell, spell)
    if okP and WR_Forever_Bool(isPlayer) == true then return true end
    if type(C_Spell) == "table" then
        local okK, known = WR_Forever_TryCall(C_Spell.IsSpellKnown, spell)
        if okK and WR_Forever_Bool(known) == true then return true end
    end

    -- ④ 解析失败：只有「法术书已就绪」才敢判「没学会」。
    --   登录初期法术书为空 / 换天赋瞬间索引被清空，此时列表为空 → 返回 nil 放行，
    --   避免把整条循环误杀成「一个技能都不亮」。
    local list = WR_Forever_SpellBookList
    if type(list) == "table" and #list > 0 then
        return false
    end
    return nil
end

-- 技能可用性归一：先把名字换成 ID，再逐级尝试；仅当 API 返回 nil（不认参数）时降级。
-- 明确返回 false 或「缺资源」时一律判死，避免「蓝不够还点亮色块」被 AHK 放大成空按。
function WR_IsSpellUsableCompat(spell)
    local key = WR_ResolveSpellID(spell) or spell
    if key == nil then return false end

    local usable

    -- ★ 用 pcall 探测，不用 type() 守卫（见本段顶部说明）
    local ok1, a, b = WR_Forever_TryCall(IsUsableSpell, key)
    if ok1 then
        local u, blocked = WR_Forever_TakeUsable(a, b)
        if blocked then return false end
        if u ~= nil then usable = u end
    end
    if usable == nil and type(C_Spell) == "table" then
        local ok2, a2, b2 = WR_Forever_TryCall(C_Spell.IsSpellUsable, key)
        if ok2 then
            local u, blocked = WR_Forever_TakeUsable(a2, b2)
            if blocked then return false end
            if u ~= nil then usable = u end
        end
    end

    -- ★★★ 精确资源比对：客户端没给「缺资源」信号（或直接返回 true）时自己比一次。
    --   这是「蓝不够不亮色块」的最后一道闸，所有 WR_SpellUsable 调用点自动受益。
    if WR_Forever_NotEnoughPower(key) then return false end

    if usable == nil and type(key) == "number" then
        local okP, aP = WR_Forever_TryCall(IsPlayerSpell, key)
        if okP then usable = WR_Forever_Bool(aP) end
    end
    return usable == true
end

-- ============================================================
-- ★★★ 2026-11-21 三十五次修复：「种族爆发色块用了还一直亮」
-- ------------------------------------------------------------
-- 用户口径：「牧师一直亮种族爆发色块，使用了种族技能还是一直亮，存在异常」
--   （截图实证：狂暴 · 种族特长 · 3 分钟冷却 · spellID 20554）
--
-- 这次是 **CD 维度**上的洞，与三十四次修复（1 级小号「没学会」）不是同一件事：
--   ① 无限战斗中 GetSpellCooldown 是 secret → WR_GetGCD 收敛成 0 →
--      WR_SpellUsable 的 GCD 门 `WR_GetGCD(Spell) <= 0.4` 恒成立；
--   ② WR_IsSpellUsableCompat 只判「资源 / 客户端可用性 / 形态」。本服私服实现里
--      IsSpellUsable 对 CD 中的技能也可能回 true，而种族爆发是 3 分钟 CD 的大招 ——
--      一旦判成「可用」，下一 tick 立刻再点亮同一槽位；
--   ③ 全仓此前**没有本地施放记账**：技能真打出去了（用户说的「使用了」），
--      插件却完全不知道 → 每 tick 点亮 → AHK 连按 → 用户看到「一直亮」。
--
-- 修法：给大招类提示补一条与圣骑士 WR_PaladinForever_ShowSkillCD 同源的三层
--   冷却证据链（那套口径已在骑士侧验证过）：
--     ① 本地施放记账（UNIT_SPELLCAST_SUCCEEDED，经 Core/Forever_APIShim.lua 桥）；
--     ② 客户端冷却（C_Spell.GetSpellCooldownDuration + EvaluateRemainingDuration
--        引擎侧求值，不吃 secret；再退 WR_SpellCooldownInfo 的 start+duration）；
--     ③ 提示保持窗口（点亮后 N 秒内不重亮，防 AHK 漏看一次就整段 CD 不提示）。
--   三条一律「读不到就放行」，与全仓「宁可少判不可误杀」口径一致。
-- ============================================================

-- 本服种族爆发技能的实测 spellID（用户截图实证：狂暴 = 20554）。
-- 用途：法术书索引解析不到带 / 不带「(种族特长)」后缀的名字时，仍能查到冷却。
-- 只给种族爆发链路用，**不写进 F.SPELL_ID_OVERRIDES** —— 那张表是全局覆盖，
-- 会把德鲁伊的「狂暴」(Berserk) 也顶成巨魔的种族 ID。
WR_Forever_RacialBurstSpellIDs = WR_Forever_RacialBurstSpellIDs or {
    ["狂暴"]     = 20554,   -- 巨魔 · 种族特长（3 分钟 CD / 施法与攻击速度 +10% / 15 秒）
    ["血性狂怒"] = 20572,   -- 兽人 · 种族特长
}

-- 技能名归一：去掉「(种族特长)」「（种族特长）」「(等级 N)」这类客户端后缀，
-- 让「狂暴」与「狂暴(种族特长)」共用同一份记账 / ID 表。
-- ★ 铁律：secret string 的 type() 仍是 "string"，gsub 也可能抛错 ——
--   必须先过 WR_IsSecretValue，整段再包 pcall。
function WR_Forever_NormalizeSpellKey(spell)
    if type(spell) ~= "string" or spell == "" then return nil end
    if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(spell) then return nil end
    local ok, out = pcall(function()
        local s = spell
        -- ★ 多字节字符不能进 Lua 字符类（[%(%（] 在 5.1 里会按字节匹配，中文全角括号
        --   是 3 字节，字符类行为不可靠）→ 半角 / 全角分两次用字面量剥。
        local stripped = s:gsub("%s*%(%s*种族特长%s*%)%s*$", "")
        if stripped == s then stripped = s:gsub("%s*（%s*种族特长%s*）%s*$", "") end
        if stripped == s then stripped = s:gsub("%s*%(%s*等级%s*%d+%s*%)%s*$", "") end
        if stripped == s then stripped = s:gsub("%s*（%s*等级%s*%d+%s*）%s*$", "") end
        stripped = stripped:gsub("^%s+", ""):gsub("%s+$", "")
        if stripped == "" then return s end
        return stripped
    end)
    if ok and type(out) == "string" and out ~= "" then return out end
    return nil
end

-- 种族爆发 / 大招的 spellID 解析：先查本服实测表，再走法术书索引。
-- 独立于 WR_ResolveSpellID 的原因：种族技能名带不带后缀两种写法都可能让
-- 法术书索引落空，而实测 ID 是确定的（截图给的就是 20554）。
function WR_Forever_BurstSpellID(spell)
    if type(spell) == "number" then return spell end
    if type(spell) ~= "string" or spell == "" then return nil end
    local base = WR_Forever_NormalizeSpellKey(spell)
    local tbl = WR_Forever_RacialBurstSpellIDs
    if base and type(tbl) == "table" and type(tbl[base]) == "number" then
        return tbl[base]
    end
    if type(WR_ResolveSpellID) == "function" then
        local ok1, v1 = pcall(WR_ResolveSpellID, spell)
        if ok1 and type(v1) == "number" then return v1 end
        if base and base ~= spell then
            local ok2, v2 = pcall(WR_ResolveSpellID, base)
            if ok2 and type(v2) == "number" then return v2 end
        end
    end
    return nil
end

-- 0~255 秒标量曲线：EvaluateRemainingDuration 在引擎侧求值，
-- 避免在 Lua 里对 secret 数字做比较（同圣骑士 curve2550 口径）。
local function WR_Forever_DurationCurve255()
    if WR_Forever_DurationCurve255Cache ~= nil then
        return WR_Forever_DurationCurve255Cache or nil
    end
    if type(C_CurveUtil) ~= "table" or type(C_CurveUtil.CreateCurve) ~= "function" then
        WR_Forever_DurationCurve255Cache = false
        return nil
    end
    local ok, curve = pcall(C_CurveUtil.CreateCurve)
    if not ok or curve == nil then
        WR_Forever_DurationCurve255Cache = false
        return nil
    end
    pcall(function()
        curve:AddPoint(0, 0)
        curve:AddPoint(255, 255)
    end)
    WR_Forever_DurationCurve255Cache = curve
    return curve
end

-- 技能冷却剩余秒数。返回 nil = 读不到（调用方必须放行）；0 = 没有冷却。
-- 两条通道依次尝试，任一给出可信数字即返回。
function WR_Forever_SpellCooldownLeft(spell)
    if spell == nil then return nil end
    local sid = WR_Forever_BurstSpellID(spell)

    -- ① 引擎侧求值（最可靠：不吃 secret）
    if type(sid) == "number" and type(C_Spell) == "table"
       and type(C_Spell.GetSpellCooldownDuration) == "function" then
        local okD, durObj = pcall(C_Spell.GetSpellCooldownDuration, sid)
        if okD then
            if durObj == nil then return 0 end   -- 明确没有冷却
            local curve = WR_Forever_DurationCurve255()
            if curve then
                local okE, res = pcall(function() return durObj:EvaluateRemainingDuration(curve) end)
                if okE and res ~= nil then
                    local left = nil
                    if type(res) == "number" then
                        local okNum, v = pcall(function() return res + 0 end)
                        if okNum and type(v) == "number" then left = v end
                    elseif type(res) == "table" or type(res) == "userdata" then
                        -- 部分客户端返回 Color：取 B 通道 ×255
                        local okRGB, _, _, b = pcall(function() return res:GetRGB() end)
                        if okRGB and type(b) == "number" then
                            local okScale, v = pcall(function() return b * 255 end)
                            if okScale and type(v) == "number" then left = v end
                        end
                    end
                    if type(left) == "number" then
                        if left < 0 then left = 0 end
                        return left
                    end
                end
            else
                -- 没有曲线工具（经典客户端无 C_CurveUtil）：对象存在说明确实在冷却，
                -- 但秒数读不出来 → 不返回占位数字，落到通道②继续取精确值。
                -- 只有通道②也失败时才用保守正数兜住「正在冷却」这个事实。
                local okC0, s0, d0 = pcall(WR_SpellCooldownInfo, sid)
                if okC0 and type(s0) == "number" and type(d0) == "number" and d0 > 0 then
                    local left0 = (s0 + d0) - GetTime()
                    if left0 < 0 then left0 = 0 end
                    return left0
                end
                return 1
            end
        end
    end

    -- ② start + duration - now（WR_SpellCooldownInfo 已把 secret 收敛成 0）
    if type(WR_SpellCooldownInfo) == "function" then
        local key = sid or spell
        local okC, start, dur = pcall(WR_SpellCooldownInfo, key)
        if okC and type(start) == "number" and type(dur) == "number" and dur > 0 then
            local left = (start + dur) - GetTime()
            if left < 0 then left = 0 end
            return left
        end
    end
    return nil
end

-- 本地施放记账：技能基础名 → 最近一次确认打出的时刻。
-- 由 Core/Forever_APIShim.lua 的 UNIT_SPELLCAST_SUCCEEDED 写入
-- （名字可能是 secret，读不到时只记 spellID；两者都读不到就放弃本次记账，
--   交给客户端冷却通道 —— 绝不因为读不到就猜「没放过」）。
WR_Forever_CastLog = WR_Forever_CastLog or {}
WR_Forever_CastLogByID = WR_Forever_CastLogByID or {}

function WR_Forever_NotePlayerCast(spellName, spellID, at)
    local now = at
    if type(now) ~= "number" then now = GetTime() end
    -- ★ 三十八次修复：secret number 的 type() 仍是 "number"，但 > 0 比较会抛错，
    --   旧写法一抛就把整笔记账（含名字通道）一起丢掉。先收敛再写表。
    local okID, sid = pcall(function()
        if type(spellID) ~= "number" then return nil end
        if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(spellID) then return nil end
        if spellID <= 0 then return nil end
        return spellID
    end)
    if okID and type(sid) == "number" then
        WR_Forever_CastLogByID[sid] = now
    end
    local base = WR_Forever_NormalizeSpellKey(spellName)
    if base then
        WR_Forever_CastLog[base] = now
        -- 原样也记一份：归一规则若因客户端改名失效，原串仍能命中
        if type(spellName) == "string" and spellName ~= base then
            WR_Forever_CastLog[spellName] = now
        end
    end
end

-- 本地记账推出的剩余冷却；没有记录返回 nil（调用方放行）。
function WR_Forever_CastCooldownLeft(spell, cd)
    if type(cd) ~= "number" or cd <= 0 then return nil end
    local now = GetTime()
    local at = nil
    local base = WR_Forever_NormalizeSpellKey(spell)
    if base and WR_Forever_CastLog[base] then at = WR_Forever_CastLog[base] end
    if at == nil and type(spell) == "string" and WR_Forever_CastLog[spell] then
        at = WR_Forever_CastLog[spell]
    end
    if at == nil then
        local sid = WR_Forever_BurstSpellID(spell)
        if type(sid) == "number" and WR_Forever_CastLogByID[sid] then
            at = WR_Forever_CastLogByID[sid]
        end
    end
    if type(at) ~= "number" then return nil end
    local left = cd - (now - at)
    if left < 0 then left = 0 end
    return left
end

-- 大招提示保持窗口（秒）：点亮后这段时间内不重复点亮。
--   太短 → AHK 漏看一次就整段 CD 不再提示；太长 → 同色常亮被 AHK 连按放大。
WR_Forever_BURST_PROMPT_HOLD = 1.5
WR_Forever_BurstPromptAt = WR_Forever_BurstPromptAt or {}

-- 重试门（秒）：保持窗口过了之后，要等这么久才允许再亮一次。
--   <=15 秒的短 CD 技能按保持窗口重试；<=300 秒每 20 秒重试；更长的按完整 CD。
--   ★ BurstReady ④ 与 NoteBurstPrompt 必须共用本函数 —— 两处口径一旦分叉，
--     「窗口到期就重新起算」会让色块每 1.5 秒续命一次 → 永久常亮。
function WR_Forever_BurstRetryGuard(cd)
    local cdSec = (type(cd) == "number" and cd > 0) and cd or 180
    local hold = WR_Forever_BURST_PROMPT_HOLD or 1.5
    if cdSec <= 15 then return hold end
    if cdSec <= 300 then return math.min(cdSec, 20) end
    return cdSec
end
_G.WR_Forever_BurstRetryGuard = WR_Forever_BurstRetryGuard

-- 记一次「已经点亮过大招提示」，供下一 tick 的保持窗口判断。
-- ★★★ 必须防重入：BurstReady 在保持窗口内返回 true（继续亮），调用方每 tick 都会
--   点亮并调本函数；若无条件刷新时间戳，窗口会被无限续期 → 色块永久常亮 ——
--   正是本次要修的「用了还是一直亮」。所以只在**重试门到期**时才写入：
--   首次点亮起算 1.5 秒保持，之后 20 秒内不再起算，到点才允许再亮一次。
-- 参数 cd（可选）：该技能真实冷却，用于算重试门；不给按 180 秒（→ 20 秒门）。
function WR_Forever_NoteBurstPrompt(spell, cd)
    local base = WR_Forever_NormalizeSpellKey(spell)
    if not base then return end
    local now = GetTime()
    local at = WR_Forever_BurstPromptAt[base]
    if type(at) == "number" and (now - at) < WR_Forever_BurstRetryGuard(cd) then return end
    WR_Forever_BurstPromptAt[base] = now
end

-- 种族爆发「是否已学会」。返回 true / false / nil（读不到，调用方放行）。
-- ★ 2026-11-21 三十五次修复：按实测 spellID 直查优先于按名字推断。
--   本服种族主动技能在法术书里常带「(种族特长)」后缀，WR_ResolveSpellID 按纯名
--   解析不到 → 名字口径的 SpellLearned 会误判「没学会」→ 巨魔牧师的「狂暴」被
--   整条剔掉 → 种族爆发永远不亮（比「一直亮」更糟的反向故障）。
--   实测 ID 是确定证据，先用 ID 问客户端「会不会」：
--     · IsPlayerSpell(sid) / C_SpellBook.IsSpellKnown(sid) / C_Spell.IsSpellKnown(sid)
--       任一明确 true → 已学会；全部明确 false → 没学会；
--     · 全都读不到 → 退回名字口径 SpellLearned，再读不到就 nil 放行。
function WR_Forever_BurstLearned(spell)
    if spell == nil then return nil end
    local base = WR_Forever_NormalizeSpellKey(spell)
    local tbl = WR_Forever_RacialBurstSpellIDs
    if base and type(tbl) == "table" and type(tbl[base]) == "number" then
        -- 实测 ID 命中：这是「玩家自己打出来过、截图核对过 spellID」的证据，
        -- 优先级高于任何按名字的推断 → 直接判已学会。
        -- 安全前提：调用方（Hooks 的种族列表 / 各职业种族爆发步）都已经先按
        -- **种族**过滤过列表，所以这里只会是「本种族真有的技能」。
        return true
    end
    if type(WR_Forever_SpellLearned) == "function" then
        local okL, learned = pcall(WR_Forever_SpellLearned, spell)
        if okL then return learned end
    end
    return nil
end
_G.WR_Forever_BurstLearned = WR_Forever_BurstLearned

-- 大招「此刻该不该点亮」。返回 true = 该亮（调用方点亮并记 NoteBurstPrompt）。
--   spell ：技能中文名（可带「(种族特长)」后缀）
--   cd    ：该技能的真实冷却秒数（种族爆发 180）；<=0 表示不按 CD 屏蔽
--
-- ★ 语义对齐圣骑士 WR_PaladinForever_ShowSkillCD（那套已在真机验证过）：
--   色块模型是「亮着 = 现在该按这个键」。点亮后必须**保持一段时间**让 AHK
--   有足够时间读到并按键（AHK 扫屏 ~60ms 一次，主循环 100ms 一 tick）；
--   若点亮当 tick 就把保持窗口判死并熄灭，色块会变成「亮 100ms / 灭 1.5s」的
--   闪烁，AHK 很可能一次都没读到 → 表现为「爆发永远按不出来」。
--   因此 ③ 保持窗口内返回 **true（继续亮）**，而不是 false。
function WR_Forever_BurstReady(spell, cd)
    if spell == nil then return false end
    local now = GetTime()
    local cdSec = (type(cd) == "number" and cd > 0) and cd or 0
    local base = WR_Forever_NormalizeSpellKey(spell)
    local promptAt = (base and WR_Forever_BurstPromptAt[base]) or nil

    -- ① 已学会硬门：确认没学会 → 不亮（读不到 nil 放行）
    if type(WR_Forever_BurstLearned) == "function" then
        local okL, learned = pcall(WR_Forever_BurstLearned, spell)
        if okL and learned == false then return false end
    end

    -- ② 真实冷却（本地施放记账优先：最准，且是「用了就立刻灭」的即时通道）
    if cdSec > 0 then
        local localLeft = WR_Forever_CastCooldownLeft(spell, cdSec)
        if type(localLeft) == "number" and localLeft > 0 then return false end
        local clientLeft = WR_Forever_SpellCooldownLeft(spell)
        if type(clientLeft) == "number" and clientLeft > 0 then return false end
    end

    -- ③ 提示保持窗口：刚点亮过 → 继续亮（给 AHK 足够的读屏 + 按键时间）
    local hold = WR_Forever_BURST_PROMPT_HOLD or 1.5
    if type(promptAt) == "number" and (now - promptAt) < hold then
        return true
    end

    -- ④ 保守兜底：保持窗口过了但「既没记上账、也读不到客户端冷却」。
    --   这通常是「施放成功事件里名字和 spellID 都是 secret」的场景 ——
    --   技能其实可能已经打出去了，只是插件不知道。此时按有限次重试而不是
    --   完整 CD 屏蔽（完整屏蔽会退化成「一次漏记锁死 3 分钟不再提示」）：
    --   中长 CD 大招最多每 20 秒重试一次，短 CD 技能按保持窗口重试。
    if type(promptAt) == "number" and cdSec > 0 then
        if (now - promptAt) < WR_Forever_BurstRetryGuard(cdSec) then return false end
    end

    -- ⑤ 客户端可用性（资源 / 形态 / 残余 CD 兜底）
    if type(WR_SpellUsable) == "function" then
        local okU, usable = pcall(WR_SpellUsable, spell)
        if okU and usable ~= true then return false end
    end
    return true
end
_G.WR_Forever_NormalizeSpellKey = WR_Forever_NormalizeSpellKey
_G.WR_Forever_BurstSpellID = WR_Forever_BurstSpellID
_G.WR_Forever_SpellCooldownLeft = WR_Forever_SpellCooldownLeft
_G.WR_Forever_NotePlayerCast = WR_Forever_NotePlayerCast
_G.WR_Forever_CastCooldownLeft = WR_Forever_CastCooldownLeft
_G.WR_Forever_NoteBurstPrompt = WR_Forever_NoteBurstPrompt
_G.WR_Forever_BurstReady = WR_Forever_BurstReady

-- 种族爆发技能的真实冷却（秒）。全职业共用一张表：
--   · 这里是**真实 CD**，不是 GCD。无限战斗中 GetSpellCooldown 是 secret →
--     WR_GetGCD 收敛成 0 → WR_SpellUsable 的 GCD 门恒成立，只有这张表能挡住
--     「3 分钟大招被当成随时可用」。
--   · 未登记的种族技能按 180 秒保守处理（本作 burst 向种族特长普遍 2~3 分钟）。
WR_Forever_RacialBurstCD = WR_Forever_RacialBurstCD or {
    ["狂暴"]       = 180,   -- 巨魔 · 截图实证 3 分钟 / spellID 20554
    ["血性狂怒"]   = 120,   -- 兽人 · 2 分钟
    ["狮心"]       = 180,   -- 人类 · 3 分钟
    ["艾露恩之光"] = 180,   -- 暗夜精灵 · 3 分钟
    ["尤里卡！"]   = 180,   -- 侏儒 · 3 分钟
}
WR_Forever_RACIAL_BURST_DEFAULT_CD = 180

-- 取当前种族「此刻真的可以打」的爆发技能名；没有就返回 nil。
-- 全职业种族爆发步统一走这里，避免每份职业文件各写一套 CD 判定
-- （三十四次修复的「按种族精确 + 已学会」已经在源头做了，本函数再补 CD 维）。
function WR_Forever_RacialBurstReady()
    local fn = WR_Forever_PlayerRacialBursts or WR_Forever_GetRacialBursts
    if type(fn) ~= "function" then return nil end
    local ok, list = pcall(fn)
    if not ok or type(list) ~= "table" then return nil end
    local cdTbl = WR_Forever_RacialBurstCD
    for i = 1, #list do
        local name = list[i]
        if type(name) == "string" and name ~= "" then
            local cd = (type(cdTbl) == "table" and cdTbl[name])
                       or WR_Forever_RACIAL_BURST_DEFAULT_CD
            local okR, ready = pcall(WR_Forever_BurstReady, name, cd)
            if okR and ready == true then return name end
        end
    end
    return nil
end
_G.WR_Forever_RacialBurstReady = WR_Forever_RacialBurstReady

-- 熄灭种族爆发色块（槽位 181）。
-- 色块模型是「亮着就一直按」：本 tick 判定不亮时必须主动熄，否则上一 tick 的
-- 色块会一直挂着被 AHK 连按 —— 这正是「用了种族技能还是一直亮」的可见现象。
function WR_Forever_HideRacialBurst(slot)
    if type(WR_HideSkillColorSlot) ~= "function" then return false end
    local s = (type(slot) == "number") and slot or 181
    local ok = pcall(WR_HideSkillColorSlot, "种族爆发", s)
    return ok
end
_G.WR_Forever_HideRacialBurst = WR_Forever_HideRacialBurst

-- ============================================================
-- ★★★ 2026-11-21 三十七次修复：通用「光环存在性」多通道判定
-- ------------------------------------------------------------
-- 用户口径：「牧师上了盾后还会继续亮盾，存在异常」。
-- 截图实证：玩家身上挂着「虚弱灵魂 · 法术ID 6788 · 无法从真言术：盾中获得益处 ·
-- 剩余5秒」—— 盾明明刚上过，59 槽位却还在亮。
--
-- 根因不在判定式写错，而在**判定通道全部失效却都返回了「不存在」**：
--   PD.HasShield 只有两条路，都经 WR_GetUnitBuffTime / WR_GetUnitDebuffTime
--   → WR_GetAuraInfoCore → 帧级光环缓存。三个坑叠在一起：
--   ① 受限战斗里 C_UnitAuras.GetAuraDataByIndex 抛
--      "Auras cannot be accessed when secret" → WR_ScanAurasForUnit 整段 pcall
--      失败 → 缓存保留上一次（往往是 nil）→ 所有按名字查的光环一律「不存在」；
--   ② 缓存里 aura.name 可能是 secret string，WR_GetAuraInfoCore 的
--      `name == AuraName` 比较会抛错（它没包 pcall）→ PD.UnitBuffRemain 的
--      pcall 把整次查询吞成 0 → 又是「不存在」；
--   ③ 全仓没有「我刚给这个单位上过盾」的本地记账 —— 技能真打出去了，插件不知道。
--   三条都返回「不存在」→ HasShield=false → 每 tick 重亮 59 槽位 → AHK 连按。
--
-- 修法与种族爆发（三十五次修复）同构，但这里做成**增益/减益通用件**，供全仓复用：
--   ① 免读回 ID 直查：GetPlayerAuraBySpellID / GetUnitAuraBySpellID
--      （RequiresNonSecretAura 族：只按 ID 问「在不在」，不枚举、不读字段）；
--   ② 名字族直查：GetPlayerAuraBySpellName / GetUnitAuraBySpellName /
--      GetAuraDataBySpellName（同族，只按名字问「在不在」）；
--   ③ 经典 UnitBuff / UnitDebuff(unit, 名字)；
--   ④ 既有缓存通道（脱战时它最准）。
--   **只采信肯定证据**：任一通道明确 true → true；全都读不到 → nil（未知）。
--   绝不把「读不到」当成「没有」—— 那正是本次故障的形态。
-- ============================================================

-- 问「某条光环此刻在不在」。返回 true / nil（未知），永不返回 false。
--   unit   ：单位 token
--   name   ：光环中文名（nil = 只按 ID 查）
--   ids    ：spellID 数组（nil = 只按名字查）
--   filter ："HELPFUL" / "HARMFUL"（经典分支与 GetAuraDataBySpellName 用）
function WR_Forever_AuraPresence(unit, name, ids, filter)
    if type(unit) ~= "string" or unit == "" then return nil end
    -- secret 表的 `obj == nil` 本身也可能抛 → 比较也包 pcall
    local function isUp(obj)
        local ok, isNil = pcall(function() return obj == nil end)
        if not ok then return nil end
        if isNil then return nil end
        return true
    end
    local cu = (type(C_UnitAuras) == "table") and C_UnitAuras or nil

    -- ① 免读回 ID 直查
    if cu ~= nil and type(ids) == "table" then
        for i = 1, #ids do
            local sid = ids[i]
            if type(sid) == "number" and sid > 0 then
                if unit == "player" and cu.GetPlayerAuraBySpellID ~= nil then
                    local ok1, a1 = pcall(cu.GetPlayerAuraBySpellID, sid)
                    if ok1 and isUp(a1) == true then return true end
                end
                if cu.GetUnitAuraBySpellID ~= nil then
                    local ok2, a2 = pcall(cu.GetUnitAuraBySpellID, unit, sid)
                    if ok2 and isUp(a2) == true then return true end
                end
            end
        end
    end

    -- ② 名字族直查
    if cu ~= nil and type(name) == "string" and name ~= "" then
        if unit == "player" and cu.GetPlayerAuraBySpellName ~= nil then
            local ok3, a3 = pcall(cu.GetPlayerAuraBySpellName, name)
            if ok3 and isUp(a3) == true then return true end
        end
        if cu.GetUnitAuraBySpellName ~= nil then
            local ok4, a4 = pcall(cu.GetUnitAuraBySpellName, unit, name)
            if ok4 and isUp(a4) == true then return true end
        end
        if cu.GetAuraDataBySpellName ~= nil then
            local ok5, a5 = pcall(cu.GetAuraDataBySpellName, unit, name, filter)
            if ok5 and isUp(a5) == true then return true end
        end
    end

    -- ③ 经典 UnitBuff / UnitDebuff(unit, 名字)（脱战可用；战斗中本服可能返回 nil）
    local legacy = (filter == "HARMFUL") and UnitDebuff or UnitBuff
    if type(legacy) == "function" and type(name) == "string" and name ~= "" then
        local ok6, d = pcall(legacy, unit, name)
        if ok6 then
            local okN, isNil = pcall(function() return d == nil end)
            if okN and not isNil then
                local t = type(d)
                if t == "table" or t == "userdata" or t == "string" then return true end
            end
        end
    end

    -- ④ 既有缓存通道（脱战最准；战斗中可能因 secret 恒返回 0）
    local timeFn = (filter == "HARMFUL") and WR_GetUnitDebuffTime or WR_GetUnitBuffTime
    if type(timeFn) == "function" and type(name) == "string" and name ~= "" then
        local ok7, v = pcall(timeFn, unit, name)
        if ok7 and type(v) == "number" and v > 0 then return true end
    end

    return nil
end
_G.WR_Forever_AuraPresence = WR_Forever_AuraPresence

-- ------------------------------------------------------------
-- 真言术：盾 / 虚弱灵魂 专用件
-- ------------------------------------------------------------
-- 盾的各 rank spellID（经典 17/592/600/3747/6066/10898~10901/25217/25218/48065/48066）。
-- 本服宏里出现过「真言术：盾(等级 11/12/13)」= 25218 / 48065 / 48066。
WR_Forever_ShieldSpellIDs = WR_Forever_ShieldSpellIDs or {
    17, 592, 600, 3747, 6066, 10898, 10899, 10900, 10901,
    25217, 25218, 48065, 48066,
}
-- 虚弱灵魂 6788（截图实证）：盾刚上过的权威证据 —— 盾被打爆后它仍在。
WR_Forever_WeakenedSoulSpellIDs = WR_Forever_WeakenedSoulSpellIDs or { 6788 }
-- 盾的持续时间（秒）。虚弱灵魂 15 秒、盾本体 30 秒 → 按较长的一侧兜底，
-- 宁可少提示一次，也不要因为记账过期而重复上盾（重复上盾是纯浪费蓝 + GCD）。
WR_Forever_SHIELD_DURATION = 30
-- 点亮盾后的保持窗口（秒）：这段时间内不重复提示（AHK 扫屏 ~60ms / tick 100ms）。
WR_Forever_SHIELD_PROMPT_HOLD = 1.5
-- 点亮后等施放成功的宽限（秒）。超时仍无施放记账 → 认为这次提示没打出去，
-- 清掉 pending 让循环继续提示（不要因为一次空按就永远不亮）。
WR_Forever_SHIELD_PENDING_TTL = 5

-- 本地记账：unit → 最近一次「给它点亮过盾」的时刻。
WR_Forever_ShieldPending = WR_Forever_ShieldPending or {}

-- 取「最近一次盾施放成功」的时刻（APIShim 的本地记账）。
-- ★★★ 2026-11-21 三十八次修复：必须同时查 spellID 通道。
--   受限战斗里 UNIT_SPELLCAST_SUCCEEDED 的 spellName 是 secret →
--   WR_Forever_CastLog（名字键）永远为空；只有 CastLogByID[17] 有值。
--   旧实现只查名字键 → 盾的记账通道整条失效 → 「上了盾还一直亮」。
local function WR_Forever_ShieldCastAt()
    local best = nil
    local function consider(v)
        if type(v) == "number" and (best == nil or v > best) then best = v end
    end
    if type(WR_Forever_CastLog) == "table" then
        consider(WR_Forever_CastLog["真言术：盾"])
    end
    if type(WR_Forever_CastLogByID) == "table" then
        for i = 1, #WR_Forever_ShieldSpellIDs do
            consider(WR_Forever_CastLogByID[WR_Forever_ShieldSpellIDs[i]])
        end
    end
    return best
end

-- 已确认「盾落在该单位身上」的记账：unit → 施放成功时刻。
-- 归属两条路（都不依赖事件首参语义）：
--   ① 提示归属：我们刚给该单位点亮过盾（3 秒内），随后读到施放成功 → 就是它；
--   ② 焦点归属：宏 59/50/60/61 全是 [@focus] 形态 → 没有提示记录时（手动施放），
--      盾必然落在当前焦点上。
WR_Forever_ShieldConfirmed = WR_Forever_ShieldConfirmed or {}
WR_Forever_ShieldCastSeenAt = WR_Forever_ShieldCastSeenAt or 0

local function WR_Forever_ShieldConsumeCast()
    local castAt = WR_Forever_ShieldCastAt()
    if type(castAt) ~= "number" or castAt <= WR_Forever_ShieldCastSeenAt then return end
    WR_Forever_ShieldCastSeenAt = castAt
    local pu = WR_Forever_ShieldLastPromptUnit
    local pat = WR_Forever_ShieldLastPromptAt
    if type(pu) == "string" and pu ~= "" and type(pat) == "number"
        and castAt >= (pat - 0.5) and (castAt - pat) <= 3.0 then
        WR_Forever_ShieldConfirmed[pu] = castAt
        return
    end
    if type(UnitExists) == "function" then
        local okF, has = pcall(UnitExists, "focus")
        if okF and has == true then
            WR_Forever_ShieldConfirmed["focus"] = castAt
        end
    end
end

local function WR_Forever_ShieldConfirmedUp(unit)
    local now = GetTime()
    local at = WR_Forever_ShieldConfirmed[unit]
    if type(at) ~= "number" and unit ~= "focus" then
        local fa = WR_Forever_ShieldConfirmed["focus"]
        if type(fa) == "number" and type(UnitIsUnit) == "function" then
            local okU, same = pcall(UnitIsUnit, "focus", unit)
            if okU and same == true then at = fa end
        end
    end
    if type(at) ~= "number" then return nil end
    if (WR_Forever_SHIELD_DURATION - (now - at)) > 0 then return true end
    WR_Forever_ShieldConfirmed[unit] = nil
    return nil
end

-- 点亮盾时调用（由各职业治疗步在 Show 成功之后写）。
-- ★ 防重入：保持窗口内重复点亮**不续期**，否则窗口被无限续命 → 色块永久常亮
--   （与 WR_Forever_NoteBurstPrompt 同一口径，见三十五次修复的 T1/T2 用例）。
-- ★ 归属：施放成功事件只说「玩家放了个盾」，不说是给谁的。所以额外记下
--   「最近一次被提示的单位」，只有它才能把这次施放认作自己的 —— 否则给 A 上盾
--   会让 B 也以为「我已经有盾了」，30 秒内都不补（跨单位假阴性）。
function WR_Forever_NoteShieldPrompt(unit)
    if type(unit) ~= "string" or unit == "" then return end
    local now = GetTime()
    local pend = WR_Forever_ShieldPending[unit]
    if type(pend) == "number" and (now - pend) < WR_Forever_SHIELD_PROMPT_HOLD then return end
    WR_Forever_ShieldPending[unit] = now
    WR_Forever_ShieldLastPromptUnit = unit
    WR_Forever_ShieldLastPromptAt = now
end
_G.WR_Forever_NoteShieldPrompt = WR_Forever_NoteShieldPrompt

-- 该单位此刻「真的有盾吗」。true = 有（不该再提示）/ nil = 没有或读不到。
-- 判据顺序：盾本体（多通道）→ 虚弱灵魂 → 本地「已确认施放」记账。
-- ★ 绝不在「读不到」时返回 false —— 那正是「上了盾还一直亮」的形态；
--   这里返回 nil，调用方按「没有」继续上盾（多上一次远好过色块挂死）。
function WR_Forever_ShieldUp(unit)
    if type(unit) ~= "string" or unit == "" then return nil end

    -- ① 盾本体真的挂着（多通道，只采信肯定证据）
    if WR_Forever_AuraPresence(unit, "真言术：盾", WR_Forever_ShieldSpellIDs, "HELPFUL") == true then
        return true
    end
    -- ② 虚弱灵魂 = 盾刚上过（盾被打爆后它仍在，仍然不该立刻补）
    if WR_Forever_AuraPresence(unit, "虚弱灵魂", WR_Forever_WeakenedSoulSpellIDs, "HARMFUL") == true then
        return true
    end

    -- ③ 已确认施放记账（spellID 通道 + 提示/焦点归属）。
    --   受限战斗里光环四通道全读不到时，这是唯一可靠的「盾已上身」证据。
    WR_Forever_ShieldConsumeCast()
    if WR_Forever_ShieldConfirmedUp(unit) == true then return true end

    -- ④ 本地记账：给它点亮过盾，且随后确实读到了施放成功
    local pend = WR_Forever_ShieldPending[unit]
    if type(pend) == "number" then
        local now = GetTime()
        local castAt = WR_Forever_ShieldCastAt()
        -- ★ 归属校验：施放成功不带单位，只有「最近提示的正是本单位」才认领，
        --   否则给 A 上盾会让 B 也以为自己有盾 → 30 秒内不补（跨单位假阴性）。
        local owned = (WR_Forever_ShieldLastPromptUnit == unit)
        if owned and type(castAt) == "number" and castAt >= (pend - 0.5) then
            -- 这次提示确实打出去了：盾持续时间内都算「有盾」
            if (WR_Forever_SHIELD_DURATION - (now - castAt)) > 0 then return true end
            WR_Forever_ShieldPending[unit] = nil
        elseif (now - pend) > WR_Forever_SHIELD_PENDING_TTL then
            -- 点亮后一直没等到施放成功（被拒 / 空按）→ 清账，让循环重新提示
            WR_Forever_ShieldPending[unit] = nil
        end
    end

    return nil
end
_G.WR_Forever_ShieldUp = WR_Forever_ShieldUp

-- 刚点亮、还在等 AHK 按键的保持窗口。true = 本 tick 继续亮（但不要重新记账）。
-- 作用：色块点亮后要留够时间给 AHK 扫屏按键（~60ms 扫一次 / 主循环 100ms 一 tick）；
--   若点亮当 tick 就判死并熄灭，会变成「亮 100ms / 灭 1.5s」的闪烁，AHK 可能一次都没
--   读到 → 表现为「盾永远按不出来」（与三十五次修复的 ③ 保持窗口同源）。
function WR_Forever_ShieldPromptHold(unit)
    if type(unit) ~= "string" or unit == "" then return false end
    local pend = WR_Forever_ShieldPending[unit]
    if type(pend) ~= "number" then return false end
    local now = GetTime()
    -- ★★★ 三十八次修复：保持窗口只覆盖「点亮后等 AHK 按键」的 1.5 秒。
    --   旧实现在施放成功后把窗口延长到整个盾持续时间（30 秒）→ 盾明明上身，
    --   色块却被本函数强行续亮 30 秒 —— 正是「上了盾还一直亮」的另一半根因。
    --   「盾已上身 → 不亮」由 WR_Forever_ShieldUp 的确认记账负责，这里不再续期。
    if (now - pend) < WR_Forever_SHIELD_PROMPT_HOLD then return true end
    return false
end
_G.WR_Forever_ShieldPromptHold = WR_Forever_ShieldPromptHold

-- ------------------------------------------------------------
-- ★★★ 2026-11-21 四十一次修复：真言术：韧 全 rank 专用件
-- ------------------------------------------------------------
-- 用户口径：「牧师维持真言术：韧没兼容低级法术」。
-- 截图实证：1级小号身上的韧是「真言术：韧 等级1 · spellID 1243」（+4耐力）。
-- 旧 PD.BuffStep 只走 PD.BuffRemain("真言术：韧") → 光环缓存名字精确匹配：
--   ① 低 rank 光环名带「(等级 1)」后缀时永远匹配不上 → 判「没韧」→ 反复补；
--   ② 没有 spellID 族直查通道（盾有 ShieldSpellIDs，韧没有）；
--   ③ 受限战斗里缓存 secret 失败时也没有本地施放记账兜底；
--   ④ 坚韧祷言（群体韧）挂着时也应视为「有韧」，不该再单体补。
-- 修法与盾（三十七/三十八次修复）同构：全 rank ID 表 + WR_Forever_AuraPresence
-- 多通道（ID 直查 / 名字族 / 经典 UnitBuff / 缓存）+ 本地施放记账 + 保持窗口。
WR_Forever_FortitudeSpellIDs = WR_Forever_FortitudeSpellIDs or {
    -- Power Word: Fortitude 单体全 rank（1243 = 等级1，截图实证）
    1243, 1244, 1245, 2791, 10937, 10938, 25389,
    -- Prayer of Fortitude 群体韧（挂着它也算有韧，不重复单体补）
    21562, 21564, 25392,
}

-- 实际生效的 spellID 族：静态全 rank 表 + **玩家当前真正学会的那个 rank**
-- （运行时从法术书解析；本服法术 ID 可能与经典表不一致，不能只靠写死的表）。
-- 注意：表名 WR_Forever_FortitudeSpellIDs 保持不变（外部可能引用），
--   取「运行时族」的函数另起名，避免表/函数同名互相覆盖。
-- ★ 运行时 rank 只在法术书索引换表时重解析（否则每 tick 建表 + 反复解析）。
WR_Forever_FortitudeRuntimeID = nil
WR_Forever_FortitudeRuntimeIndex = nil

function WR_Forever_FortitudeSpellIDSet()
    local out = {}
    for i = 1, #WR_Forever_FortitudeSpellIDs do out[#out + 1] = WR_Forever_FortitudeSpellIDs[i] end
    if type(WR_ResolveSpellID) == "function" then
        local idx = WR_Forever_SpellBookIndex
        if idx ~= WR_Forever_FortitudeRuntimeIndex then
            WR_Forever_FortitudeRuntimeIndex = idx
            WR_Forever_FortitudeRuntimeID = nil
            local ok, sid = pcall(WR_ResolveSpellID, "真言术：韧")
            if ok and type(sid) == "number" and sid > 0 then
                WR_Forever_FortitudeRuntimeID = sid
            end
        end
        local sid = WR_Forever_FortitudeRuntimeID
        if type(sid) == "number" and sid > 0 then
            local dup = false
            for i = 1, #out do if out[i] == sid then dup = true end end
            if not dup then out[#out + 1] = sid end
        end
    end
    return out
end
-- 名字族候选：基础名 + 群体版 + 低 rank 常见写法（本服括号风格半角/全角都有先例）
WR_Forever_FortitudeNames = WR_Forever_FortitudeNames or {
    "真言术：韧", "坚韧祷言",
    "真言术：韧(等级 1)", "真言术：韧(等级 2)", "真言术：韧(等级 3)",
    "真言术：韧(等级 4)", "真言术：韧(等级 5)", "真言术：韧(等级 6)", "真言术：韧(等级 7)",
    "真言术：韧（等级 1）", "真言术：韧（等级 2）", "真言术：韧（等级 3）",
    "真言术：韧（等级 4）", "真言术：韧（等级 5）", "真言术：韧（等级 6）", "真言术：韧（等级 7）",
}
-- 韧持续 30 分钟；本地记账兜底按 30 分钟（低 rank 时长一致，只加耐力数值不同）。
WR_Forever_FORT_DURATION = 1800
-- 点亮后的保持窗口 / 等施放成功宽限（与盾同口径）。
WR_Forever_FORT_PROMPT_HOLD = 1.5
WR_Forever_FORT_PENDING_TTL = 5
WR_Forever_FortPending = WR_Forever_FortPending or {}
WR_Forever_FortConfirmed = WR_Forever_FortConfirmed or {}
WR_Forever_FortCastSeenAt = WR_Forever_FortCastSeenAt or 0

local function WR_Forever_FortCastAt()
    local best = nil
    local function consider(v)
        if type(v) == "number" and (best == nil or v > best) then best = v end
    end
    if type(WR_Forever_CastLog) == "table" then
        consider(WR_Forever_CastLog["真言术：韧"])
        consider(WR_Forever_CastLog["坚韧祷言"])
    end
    if type(WR_Forever_CastLogByID) == "table" then
        local ids = WR_Forever_FortitudeSpellIDSet()
        for i = 1, #ids do
            consider(WR_Forever_CastLogByID[ids[i]])
        end
    end
    return best
end

-- 归属与盾同构：提示归属（3 秒内给该单位点亮过）→ 焦点归属（宏 52 是 [@focus]）。
local function WR_Forever_FortConsumeCast()
    local castAt = WR_Forever_FortCastAt()
    if type(castAt) ~= "number" or castAt <= WR_Forever_FortCastSeenAt then return end
    WR_Forever_FortCastSeenAt = castAt
    local pu = WR_Forever_FortLastPromptUnit
    local pat = WR_Forever_FortLastPromptAt
    if type(pu) == "string" and pu ~= "" and type(pat) == "number"
        and castAt >= (pat - 0.5) and (castAt - pat) <= 3.0 then
        WR_Forever_FortConfirmed[pu] = castAt
        return
    end
    if type(UnitExists) == "function" then
        local okF, has = pcall(UnitExists, "focus")
        if okF and has == true then
            WR_Forever_FortConfirmed["focus"] = castAt
        end
    end
end

local function WR_Forever_FortConfirmedUp(unit)
    local now = GetTime()
    local at = WR_Forever_FortConfirmed[unit]
    if type(at) ~= "number" and unit ~= "focus" then
        local fa = WR_Forever_FortConfirmed["focus"]
        if type(fa) == "number" and type(UnitIsUnit) == "function" then
            local okU, same = pcall(UnitIsUnit, "focus", unit)
            if okU and same == true then at = fa end
        end
    end
    if type(at) ~= "number" then return nil end
    if (WR_Forever_FORT_DURATION - (now - at)) > 0 then return true end
    WR_Forever_FortConfirmed[unit] = nil
    return nil
end

-- 点亮韧时调用（BuffStep 在 Show 成功后写）。防重入：保持窗口内不续期。
function WR_Forever_NoteFortPrompt(unit)
    if type(unit) ~= "string" or unit == "" then return end
    local now = GetTime()
    local pend = WR_Forever_FortPending[unit]
    if type(pend) == "number" and (now - pend) < WR_Forever_FORT_PROMPT_HOLD then return end
    WR_Forever_FortPending[unit] = now
    WR_Forever_FortLastPromptUnit = unit
    WR_Forever_FortLastPromptAt = now
end
_G.WR_Forever_NoteFortPrompt = WR_Forever_NoteFortPrompt

-- 该单位此刻「真的有韧吗」。true = 有（含任意 rank / 群体韧）/ nil = 没有或读不到。
function WR_Forever_FortitudeUp(unit)
    if type(unit) ~= "string" or unit == "" then return nil end
    -- ① 全 rank ID 直查（免读回，RequiresNonSecretAura 族）+ 基础名/群体名多通道
    if WR_Forever_AuraPresence(unit, "真言术：韧", WR_Forever_FortitudeSpellIDSet(), "HELPFUL") == true then
        return true
    end
    if WR_Forever_AuraPresence(unit, "坚韧祷言", nil, "HELPFUL") == true then
        return true
    end
    -- ② 低 rank 带后缀的名字族直查（ID 通道被秘密旗挡住时的补充）
    for i = 3, #WR_Forever_FortitudeNames do
        if WR_Forever_AuraPresence(unit, WR_Forever_FortitudeNames[i], nil, "HELPFUL") == true then
            return true
        end
    end
    -- ③ 已确认施放记账（spellID 通道 + 提示/焦点归属）
    WR_Forever_FortConsumeCast()
    if WR_Forever_FortConfirmedUp(unit) == true then return true end
    -- ④ 点亮过且随后确实读到施放成功（归属校验，防跨单位假阴性）
    local pend = WR_Forever_FortPending[unit]
    if type(pend) == "number" then
        local now = GetTime()
        local castAt = WR_Forever_FortCastAt()
        local owned = (WR_Forever_FortLastPromptUnit == unit)
        if owned and type(castAt) == "number" and castAt >= (pend - 0.5) then
            if (WR_Forever_FORT_DURATION - (now - castAt)) > 0 then return true end
            WR_Forever_FortPending[unit] = nil
        elseif (now - pend) > WR_Forever_FORT_PENDING_TTL then
            WR_Forever_FortPending[unit] = nil
        end
    end
    return nil
end
_G.WR_Forever_FortitudeUp = WR_Forever_FortitudeUp

-- 刚点亮、还在等 AHK 按键的保持窗口（1.5 秒，不覆盖整个 buff 时长）。
function WR_Forever_FortPromptHold(unit)
    if type(unit) ~= "string" or unit == "" then return false end
    local pend = WR_Forever_FortPending[unit]
    if type(pend) ~= "number" then return false end
    if (GetTime() - pend) < WR_Forever_FORT_PROMPT_HOLD then return true end
    return false
end
_G.WR_Forever_FortPromptHold = WR_Forever_FortPromptHold

-- 「这一发韧已经打出去」的轻量判定：只查本地施放记账，**零 API 调用**。
-- ★ 四十二次修复的落地件：色块点亮后必须在 GCD 转好之前熄灭，
--   否则外部 AHK（同色常亮就一直按，约 60ms 一次）会在 GCD 一过就再按一次
--   → 韧被打两下（「连补两下」）。受限战斗里光环四通道全读不到时，
--   本地记账是唯一能立刻确认「这一发已经出去了」的信号。
-- 归属：只认「我们刚给该单位点亮过韧、且 3 秒内确实读到施放成功」的那一次，
--   否则上一次的手动施放会被误认成这一发（跨时假阳性 → 30 分钟不补）。
function WR_Forever_FortitudeCastLanded(unit)
    unit = unit or "player"
    local pat = WR_Forever_FortLastPromptAt
    if type(pat) ~= "number" then return false end
    if WR_Forever_FortLastPromptUnit ~= unit then return false end
    local castAt = WR_Forever_FortCastAt()
    if type(castAt) ~= "number" then return false end
    if castAt < (pat - 0.5) then return false end
    if (castAt - pat) > 3.0 then return false end
    return true
end
_G.WR_Forever_FortitudeCastLanded = WR_Forever_FortitudeCastLanded

-- ============================================================
-- 通用「自身增益」专用件（维持类增益：心灵之火等）
-- ------------------------------------------------------------
-- 与「真言术：盾」「真言术：韧」专用件同构，抽成可复用的通用版：
--   ① 多通道存在性：ID 直查（运行时解析玩家实际学会的 rank，**不猜 ID**）/
--      名字族直查 / 经典 UnitBuff / 归一后的缓存通道
--      （Core_Functions 的 WR_AuraNameBase 已让「真言术：韧(等级 1)」这种
--        带等级后缀的名字能命中基础名查询）；
--   ② 本地施放记账：名字在受限战斗里是 secret 时靠 spellID 通道记；
--   ③ 提示保持窗口：刚点亮时继续亮（等 AHK 按键），防重入不续期
--      （否则窗口被无限续期 → 色块永久常亮）；
--   ④ 只采信肯定证据：读不到一律 nil —— 绝不把「读不到」当成「没有」。
-- 参数：name = 增益中文名；duration = 记账兜底时长（秒）；unit = 目标单位。
WR_Forever_SELF_PROMPT_HOLD = 1.5
WR_Forever_SelfBuffExtraIDs = WR_Forever_SelfBuffExtraIDs or {}
WR_Forever_SelfBuffState = WR_Forever_SelfBuffState or {}

-- 该增益的 spellID 集合：额外登记 + 运行时解析「玩家实际学会的那个 rank」。
function WR_Forever_SelfBuffSpellIDs(name)
    local out = {}
    local extra = WR_Forever_SelfBuffExtraIDs[name]
    if type(extra) == "table" then
        for i = 1, #extra do
            local v = extra[i]
            if type(v) == "number" and v > 0 then out[#out + 1] = v end
        end
    end
    if type(WR_ResolveSpellID) == "function" then
        local ok, sid = pcall(WR_ResolveSpellID, name)
        if ok and type(sid) == "number" and sid > 0 then
            local dup = false
            for i = 1, #out do
                if out[i] == sid then dup = true end
            end
            if not dup then out[#out + 1] = sid end
        end
    end
    return out
end

-- 记一次「已经点亮过这个自身增益」（供保持窗口判断）。
function WR_Forever_NoteSelfBuffPrompt(name)
    if type(name) ~= "string" or name == "" then return end
    local st = WR_Forever_SelfBuffState[name]
    if not st then st = {}; WR_Forever_SelfBuffState[name] = st end
    local now = GetTime()
    if type(st.promptAt) == "number" and (now - st.promptAt) < WR_Forever_SELF_PROMPT_HOLD then return end
    st.promptAt = now
end
_G.WR_Forever_NoteSelfBuffPrompt = WR_Forever_NoteSelfBuffPrompt

-- 刚点亮、还在等 AHK 按键的保持窗口（防重入：窗口内不续期）。
function WR_Forever_SelfBuffPromptHold(name)
    if type(name) ~= "string" or name == "" then return false end
    local st = WR_Forever_SelfBuffState[name]
    if not st or type(st.promptAt) ~= "number" then return false end
    return (GetTime() - st.promptAt) < WR_Forever_SELF_PROMPT_HOLD
end
_G.WR_Forever_SelfBuffPromptHold = WR_Forever_SelfBuffPromptHold

-- 该单位此刻「真的有这个自身增益吗」。true = 有 / nil = 没有或读不到。
function WR_Forever_SelfBuffUp(name, duration, unit)
    if type(name) ~= "string" or name == "" then return nil end
    unit = unit or "player"
    local ids = WR_Forever_SelfBuffSpellIDs(name)
    -- ① 多通道存在性（ID 直查 / 名字族 / 经典 UnitBuff / 归一缓存）
    if type(WR_Forever_AuraPresence) == "function" then
        local ok, v = pcall(WR_Forever_AuraPresence, unit, name, (#ids > 0) and ids or nil, "HELPFUL")
        if ok and v == true then return true end
    end
    -- ② 本地施放记账（名字 secret 时靠 spellID 通道）
    local castAt = nil
    if type(WR_Forever_CastLog) == "table" then
        local v = WR_Forever_CastLog[name]
        if type(v) == "number" then castAt = v end
    end
    if type(WR_Forever_CastLogByID) == "table" then
        for i = 1, #ids do
            local v = WR_Forever_CastLogByID[ids[i]]
            if type(v) == "number" and (castAt == nil or v > castAt) then castAt = v end
        end
    end
    if type(castAt) == "number" then
        local dur = tonumber(duration) or 30
        if (dur - (GetTime() - castAt)) > 0 then return true end
    end
    return nil
end
_G.WR_Forever_SelfBuffUp = WR_Forever_SelfBuffUp

-- 「这一发自身增益已经打出去」的轻量判定（只查本地施放记账，零 API 调用）。
-- 同构于 WR_Forever_FortitudeCastLanded：色块点亮后必须尽快熄灭，
-- 否则 AHK 会跨过 GCD 连按 → 增益被打两下。
function WR_Forever_SelfBuffCastLanded(name, unit)
    if type(name) ~= "string" or name == "" then return false end
    unit = unit or "player"
    local st = WR_Forever_SelfBuffState[name]
    if not st or type(st.promptAt) ~= "number" then return false end
    local pat = st.promptAt
    local castAt = nil
    if type(WR_Forever_CastLog) == "table" then
        local v = WR_Forever_CastLog[name]
        if type(v) == "number" then castAt = v end
    end
    if castAt == nil and type(WR_Forever_CastLogByID) == "table" then
        local ids = WR_Forever_SelfBuffSpellIDs(name)
        for i = 1, #ids do
            local v = WR_Forever_CastLogByID[ids[i]]
            if type(v) == "number" and (castAt == nil or v > castAt) then castAt = v end
        end
    end
    if type(castAt) ~= "number" then return false end
    if castAt < (pat - 0.5) then return false end
    if (castAt - pat) > 3.0 then return false end
    return true
end
_G.WR_Forever_SelfBuffCastLanded = WR_Forever_SelfBuffCastLanded

-- ============================================================
-- ★★★ 2026-11-21 三十五次修复：全职业「种族爆发步」统一入口
-- ------------------------------------------------------------
-- 之前每个职业各写一套「遍历列表 + WR_SpellUsable」，只有牧师 / 战士三系 /
-- 德鲁伊野性 / 猎人兽王改到了 CD 维，法师三系 / 猎人射击·生存 / 萨满两系 /
-- 术士三系 / 德鲁伊平衡·恢复 仍是旧口径 —— 同一个「用了还一直亮」的坑。
-- 本函数把七道门收成一处，各职业只需传自己的 Show / CanCast：
--   按种族精确列表 → 已学会 → 本地施放记账 CD → 客户端冷却 →
--   提示保持窗口 → 客户端可用性，任一门判死都不点亮；
-- 并且**本步不亮时主动熄灭槽位**，不让上一 tick 的色块挂在那里被 AHK 连按。
-- want：调用方的面板开关（false 时同样要熄灭残留色块）。
-- 返回 true = 已点亮（调用方直接 return true）。
function WR_Forever_RacialBurstStep(showFn, canCastFn, slot, want)
    local s = slot or 181
    local function hide()
        if type(WR_Forever_HideRacialBurst) == "function" then
            pcall(WR_Forever_HideRacialBurst, s)
        elseif type(WR_HideSkillColorSlot) == "function" then
            pcall(WR_HideSkillColorSlot, "种族爆发", s)
        end
    end
    if want == false then hide() return false end

    local hit
    if type(WR_Forever_RacialBurstReady) == "function" then
        local okR, v = pcall(WR_Forever_RacialBurstReady)
        if okR and type(v) == "string" then hit = v end
    else
        -- 兼容回退（旧 Core 未加载新函数时仍按原口径工作）
        local fn = WR_Forever_PlayerRacialBursts or WR_Forever_GetRacialBursts
        if type(fn) == "function" then
            local ok, bursts = pcall(fn)
            if ok and type(bursts) == "table" then
                for i = 1, #bursts do
                    local name = bursts[i]
                    if type(name) == "string" and name ~= "" then
                        local okc = false
                        if type(canCastFn) == "function" then
                            local okp, v2 = pcall(canCastFn, name)
                            okc = (okp and v2 == true)
                        elseif type(WR_SpellUsable) == "function" then
                            local okp, v2 = pcall(WR_SpellUsable, name, true)
                            okc = (okp and v2 == true)
                        end
                        if okc then hit = name break end
                    end
                end
            end
        end
    end

    if hit and type(showFn) == "function" then
        local okS, shown = pcall(showFn, "种族爆发", s)
        if okS and shown == true then
            if type(WR_Forever_NoteBurstPrompt) == "function" then
                local cd = (type(WR_Forever_RacialBurstCD) == "table" and WR_Forever_RacialBurstCD[hit])
                    or WR_Forever_RACIAL_BURST_DEFAULT_CD or 180
                pcall(WR_Forever_NoteBurstPrompt, hit, cd)
            end
            return true
        end
    end
    hide()
    return false
end
_G.WR_Forever_RacialBurstStep = WR_Forever_RacialBurstStep

-- 法术书变更时使缓存失效（登录完成后重建，避免加载期拿到空法术书）。
-- 战斗中不重建：重建需遍历数百个法术书槽位并逐个 pcall，会造成可感知的掉帧；
-- 仅置脏标记，等脱战（PLAYER_REGEN_ENABLED）后再一次性刷新。
WR_Forever_SpellIndexDirty = false
do
    local function WR_Forever_ResetSpellIndex()
        WR_Forever_SpellBookIndex = nil
        WR_Forever_SpellBookList  = nil
        WR_Forever_SpellIDCache   = {}
        WR_Forever_SpellIndexDirty = false
    end
    local WR_Forever_SpellInvalidator = CreateFrame("Frame")
    WR_Forever_SpellInvalidator:RegisterEvent("SPELLS_CHANGED")
    WR_Forever_SpellInvalidator:RegisterEvent("PLAYER_ENTERING_WORLD")
    WR_Forever_SpellInvalidator:RegisterEvent("PLAYER_TALENT_UPDATE")
    WR_Forever_SpellInvalidator:RegisterEvent("PLAYER_REGEN_ENABLED")
    WR_Forever_SpellInvalidator:SetScript("OnEvent", function(self, event)
        -- ★★★ 2026-11-13 用户口径「技能消耗变化……时及时刷新所有技能色块」：
        --   技能消耗正缓存（WR_Forever_PowerCostCache）此前永不过期 —— 升级
        --   （新客户端同一 spellID 的消耗按等级缩放）、换天赋/雕文修正都会改消耗，
        --   旧消耗留着会出现「蓝不够还亮（旧消耗低）」或「够蓝却不亮（旧消耗高）」。
        --   清空零成本：下一次点亮时按需逐技能重探（每技能一次 pcall），战斗中
        --   也不掉帧；PLAYER_REGEN_ENABLED 只是重建索引，消耗缓存已在变更事件清过。
        if event ~= "PLAYER_REGEN_ENABLED" then
            WR_Forever_PowerCostCache = {}
        end
        if event == "PLAYER_REGEN_ENABLED" then
            if WR_Forever_SpellIndexDirty then WR_Forever_ResetSpellIndex() end
            return
        end
        if UnitAffectingCombat("player") then
            WR_Forever_SpellIndexDirty = true
            return
        end
        WR_Forever_ResetSpellIndex()
    end)
end

-- ============================================================
-- ★ 7. /mkfspells —— 一次性游戏内采集（法术书 / 技能名匹配 / API 存在性）
-- ------------------------------------------------------------
-- 用途：无限是新版本，法术书内容（技能名 + spellID）只存在于客户端，
--       本地没有任何数据源可以推断。跑一次本命令即可把三份数据写入
--       PigSet.MKFSpellScan（复用 TOC 已有的 SavedVariablesPerCharacter，
--       **不需要改 TOC、不需要完全重进**），/reload 后落盘到角色级存档：
--         WTF\\Account\\<账号>\\<服务器>\\<角色>\\SavedVariables\\MKHelperForever.lua
--       每个角色一份，9 个职业各跑一次即可集齐全职业技能表。
-- 用法：/mkfspells        —— 采集并打印第 1 页未匹配技能名
--       /mkfspells 2      —— 只看第 2 页未匹配清单
--       /mkfspells api    —— 只打印 API 存在性明细
-- ============================================================

-- 由职业模块静态提取的中文技能/配置名候选（去重），用于逐个核对客户端能否解析
local WR_FOREVER_PROBE_NAMES = {
    "中毒", "伏击", "使用断筋", "偷袭",
    "元素", "元素掌握", "光环掌握", "军刀猛刺",
    "冰冷之血", "冰冷血脉", "冰枪术", "冰霜",
    "冰霜之指", "冰霜新星", "净化术", "凶猛撕咬",
    "出血", "刀扇", "切割", "别乱动",
    "削砍", "剔骨", "割裂", "力量祝福",
    "十字军圣印", "十字军打击", "十字军打击(回蓝)", "十字军的惩罚",
    "厄运诅咒", "压制", "召唤地狱猎犬", "召唤小鬼",
    "召唤恶魔卫士", "召唤虚空行者", "召唤魅魔", "可以驱散任何魔法",
    "可以驱散目标任何魔法", "吸取灵魂", "吸取生命", "吸血鬼之触",
    "唤醒", "嗜血", "噬灵疫病", "回春术",
    "圣光术", "圣光裁决", "圣光道标", "圣光重担",
    "圣光闪现", "圣洁光环", "圣洁护盾", "圣疗术",
    "圣盾术", "地狱烈焰", "地狱猎犬", "增强",
    "复仇", "复仇之怒", "复仇之手", "复仇者之盾",
    "复活宠物", "多少血量以下使用", "多少血量治疗宠物", "多重射击",
    "大于等于几星补切割", "大地之盾", "大地震击", "大猫形态",
    "天灾领主之刺", "奇美拉射击", "奇袭", "奉献",
    "奥术", "奥术冲击", "奥术弹幕", "奥术强化",
    "奥术涌动", "奥术飞弹", "奥术飞弹速射", "宁静",
    "守护", "守护之魂", "审判", "寒冰护体",
    "寒冰箭", "对玩家使用断筋", "射击", "小鬼",
    "巨飞行形态", "平衡", "强效治疗术", "影袭",
    "心灵震爆", "快速治疗", "急救药水", "急速冷却",
    "急速射击", "恐惧", "恢复", "恶魔",
    "恶魔卫士", "恶魔变形", "恶魔学识", "惩戒",
    "愈合", "愈合祷言", "愤怒", "愤怒之锤",
    "戒律", "战斗", "手动插入吸取生命", "手套",
    "指向痛功能\n", "指向触功能\n", "按键（slot5）", "挑战咆哮",
    "挑战怒吼", "挫志咆哮", "插入", "揭示打击",
    "撕碎", "攻击", "敏锐", "斜掠",
    "斩击", "斩杀", "旅行形态", "旋风斩",
    "日蚀", "昏迷", "星涌术", "星火",
    "星火术", "星落", "智慧祝福", "暗影",
    "暗影恶魔", "暗影步", "暗影灼烧", "暗影箭",
    "暗影魔", "暗言术：死", "暗言术：痛", "暴风雪",
    "月火术", "月神轨道炮", "月蚀", "杀戮命令",
    "杀戮射击", "枭兽形态", "枯萎虫群", "树皮术",
    "横扫", "横扫（熊）", "横扫（豹）", "次级治疗波",
    "正义", "正义之锤", "武器", "殉难圣印",
    "毁伤", "毁灭", "毁灭打击", "毒伤",
    "毒刃", "毒蛇钉刺", "治疗之环", "治疗之触",
    "治疗之雨", "治疗波", "治疗祷言", "治疗链",
    "法力宝石", "法术连击", "洁净术", "活动炸弹",
    "消散", "混乱箭", "清洁术", "漩涡武器",
    "潮汐之力", "激活", "激流", "火元素图腾",
    "火焰", "火焰之雨", "火球术", "灭杀",
    "灵魂之火", "灼烧", "炎爆术", "烈焰震击",
    "烧尽", "焦点痛功能\n", "焦点触功能\n", "熊形态",
    "熔岩爆裂", "熔岩猛击", "燃烧", "爆发",
    "爆炸射击", "爪击", "狂怒", "狂暴之怒",
    "狂暴之怒(解控)", "狂暴回复", "狂暴打击", "狂野怒火",
    "猎豹形态", "猛击", "猫形态", "献祭",
    "玛洛加尔领主", "生命分流", "生命绽放", "生存",
    "疾病", "痛击", "痛苦", "痛苦压制",
    "痛苦无常", "痛苦诅咒", "盾牌格挡", "盾牌猛击",
    "真言术：盾", "眼镜蛇射击", "瞄准射击", "破釜沉舟",
    "碎裂投掷", "祈求圣光", "神圣", "神圣之盾",
    "神圣恳求", "神圣牺牲", "神圣震击", "神圣风暴",
    "移动打灭\n", "移动的时候补腐蚀术", "稳固射击", "精华绽放",
    "精灵之火", "精神鞭笞", "给宠物目标上误导", "给焦点目标上误导",
    "给目标的目标上误导", "给自己加血)", "绝望祷言", "绞喉",
    "续灭绝", "群体回春", "肾击", "背刺",
    "脱战蝰蛇.满蓝龙鹰", "腐蚀之种", "腐蚀术", "自动射击",
    "自然愈合", "自由", "自由之手", "致命投掷",
    "致死打击", "苦修", "英勇打击", "英勇投掷",
    "荆棘光环", "萨满之怒", "虔诚", "虔诚光环",
    "虚空行者", "蝰蛇守护", "血性狂暴", "裂伤",
    "要害打击", "规避各种技能\n", "解除诅咒", "诅咒",
    "赤红风暴", "起手暗影魔\n", "轨道炮好了就用", "转嫁",
    "迅捷打击", "远古意志", "速度药水", "邪恶攻击",
    "重殴", "野兽控制", "野性", "野性成长",
    "野性战斗", "野性狼魂", "野蛮咆哮", "闪电箭",
    "闪电链", "防护", "阳炎术", "雄狮守护",
    "雄鹰守护", "雷霆一击", "鞭笞", "顺劈斩",
    "风暴打击", "飓风", "飞禽形态", "饰品",
    "驱邪", "鬼影缠身", "魅魔", "魔法",
    "魔爆术", "鲁莽", "黑箭",
}

-- 采集客户端实际暴露的 API（含上一轮悬而未决的 secret value / 专精 / CLEU 相关项）
local function WR_Forever_CollectAPI()
    local CS = (type(C_Spell) == "table") and C_Spell or nil
    local CB = (type(C_SpellBook) == "table") and C_SpellBook or nil
    local CA = (type(C_UnitAuras) == "table") and C_UnitAuras or nil
    local CT = (type(C_Traits) == "table") and C_Traits or nil
    local CC = (type(C_ClassTalents) == "table") and C_ClassTalents or nil
    local function f(t, k) return type(t) == "table" and type(t[k]) == "function" end
    local rows = {
        { "C_Spell",                                  type(CS) == "table" },
        { "C_Spell.GetSpellInfo",                     f(CS, "GetSpellInfo") },
        { "C_Spell.GetSpellCooldown",                 f(CS, "GetSpellCooldown") },
        { "C_Spell.GetSpellCharges",                  f(CS, "GetSpellCharges") },
        { "C_Spell.GetSpellTexture",                  f(CS, "GetSpellTexture") },
        { "C_Spell.IsSpellUsable",                    f(CS, "IsSpellUsable") },
        { "C_Spell.IsSpellInRange",                   f(CS, "IsSpellInRange") },
        { "C_SpellBook",                              type(CB) == "table" },
        { "C_SpellBook.GetNumSpellBookSkillLines",    f(CB, "GetNumSpellBookSkillLines") },
        { "C_SpellBook.GetSpellBookSkillLineInfo",    f(CB, "GetSpellBookSkillLineInfo") },
        { "C_SpellBook.GetSpellBookItemInfo",         f(CB, "GetSpellBookItemInfo") },
        { "C_UnitAuras.GetAuraDataByIndex",           f(CA, "GetAuraDataByIndex") },
        { "GetSpellInfo (原生/兜底)",                  type(GetSpellInfo) == "function" },
        { "GetSpellCooldown",                         type(GetSpellCooldown) == "function" },
        { "GetSpellCharges",                          type(GetSpellCharges) == "function" },
        { "IsUsableSpell",                            type(IsUsableSpell) == "function" },
        { "IsPlayerSpell",                            type(IsPlayerSpell) == "function" },
        { "UnitBuff",                                 type(UnitBuff) == "function" },
        { "UnitDebuff",                               type(UnitDebuff) == "function" },
        { "GetNumSpellTabs",                          type(GetNumSpellTabs) == "function" },
        { "GetSpellBookItemName",                     type(GetSpellBookItemName) == "function" },
        { "C_SpecializationInfo",                     type(C_SpecializationInfo) == "table" },
        { "C_ClassTalents/C_Traits",                  type(CC) == "table" and type(CT) == "table" },
        { "GetSpecialization",                        type(GetSpecialization) == "function" },
        { "GetPrimaryTalentTree",                     type(GetPrimaryTalentTree) == "function" },
        { "issecretvalue",                            type(issecretvalue) == "function" },
        { "canaccessvalue",                           type(canaccessvalue) == "function" },
        { "UnitHealthPercent",                        type(UnitHealthPercent) == "function" },
        { "C_CurveUtil",                              type(C_CurveUtil) == "table" },
        { "CombatLogGetCurrentEventInfo",             type(CombatLogGetCurrentEventInfo) == "function" },
    }
    local out = {}
    for i, r in ipairs(rows) do
        out[i] = { name = r[1], ok = (r[2] and true or false) }
    end
    return out
end

SLASH_MKFSPELLS1 = "/mkfspells"
SlashCmdList["MKFSPELLS"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    local apiOnly = (msg:lower() == "api")
    if type(PigSet) ~= "table" then PigSet = {} end

    -- 强制重建，保证拿到的是当前角色最新法术书
    WR_Forever_SpellBookIndex = nil
    WR_Forever_SpellBookList  = nil
    WR_Forever_SpellIDCache   = {}
    local idx  = WR_BuildSpellBookIndex(true)
    local list = WR_Forever_SpellBookList or {}

    -- 逐个核对插件硬编码技能名能否解析到 spellID
    local probe = {}
    for _, name in ipairs(WR_FOREVER_PROBE_NAMES) do
        local sid = idx[name] or WR_ResolveSpellID(name)
        probe[#probe + 1] = { name = name, id = sid or 0, ok = (sid and true or false) }
    end
    local api = WR_Forever_CollectAPI()

    local _, class = UnitClass("player")
    -- 保留此前 /mkfspellscan 的全量结果，避免本命令二次运行时把 spellDB 冲掉
    local prev = PigSet.MKFSpellScan
    local prevSpellDB = (type(prev) == "table" and type(prev.spellDB) == "table") and prev.spellDB or nil
    -- 保留 /mkfspellscan 的全量成果：spellDB 及分段记录、两轮反查结果
    local keep = function(k)
        return (type(prev) == "table") and prev[k] or nil
    end
    PigSet.MKFSpellScan = {
        spellDB       = prevSpellDB,
        scanSegments  = keep("scanSegments"),
        probeResolved = keep("probeResolved"),
        newAbilityIDs = keep("newAbilityIDs"),
        time      = date("%Y-%m-%d %H:%M:%S"),
        class     = class or "?",
        level     = UnitLevel("player") or 0,
        build     = select(4, GetBuildInfo()) or "?",
        locale    = GetLocale() or "?",
        spellbook = list,
        probe     = probe,
        api       = api,
    }

    local hit, miss = 0, 0
    for _, p in ipairs(probe) do
        if p.ok then hit = hit + 1 else miss = miss + 1 end
    end
    print("|cff00ff00[MKHelperForever]|r 技能 / API 采集完成：")
    print("  客户端      : " .. tostring(PigSet.MKFSpellScan.build)
          .. " / " .. tostring(PigSet.MKFSpellScan.locale)
          .. " / " .. tostring(class) .. " Lv" .. tostring(PigSet.MKFSpellScan.level))
    print("  法术书条目  : |cffffd100" .. #list .. "|r 条")
    if #list == 0 then
        print("  |cffff8800法术书为空（低等级 / 尚未学习技能）：这是正常的，不影响 API 探测。|r")
        print("  |cffff8800全量技能名请用 /mkfspellscan —— 它读客户端静态数据，不依赖角色等级。|r")
    end
    print("  插件技能名  : 命中 |cff00ff00" .. hit .. "|r / 未匹配 |cffff6666" .. miss
          .. "|r（共 " .. #probe .. "）")

    local missingAPI = {}
    for _, r in ipairs(api) do
        if not r.ok then missingAPI[#missingAPI + 1] = r.name end
    end
    print("  缺失 API    : " .. (#missingAPI == 0 and "无" or table.concat(missingAPI, ", ")))
    if apiOnly then
        for _, r in ipairs(api) do
            print("    " .. (r.ok and "|cff00ff00[有]|r " or "|cffff6666[无]|r ") .. r.name)
        end
    end

    if not apiOnly then
        local missNames = {}
        for _, p in ipairs(probe) do
            if not p.ok then missNames[#missNames + 1] = p.name end
        end
        local page = tonumber(msg:match("^(%d+)$") or "1") or 1
        local per  = 30
        local pages = math.max(1, math.ceil(#missNames / per))
        if page > pages then page = pages end
        local from = (page - 1) * per + 1
        if from <= #missNames then
            local chunk = {}
            for i = from, math.min(from + per - 1, #missNames) do
                chunk[#chunk + 1] = missNames[i]
            end
            print("  未匹配清单 (第 " .. page .. "/" .. pages .. " 页): " .. table.concat(chunk, "、"))
        end
    end
    print("  |cffffd100数据已存 PigSet.MKFSpellScan；输入 /reload 即写入本角色 SavedVariables/MKHelperForever.lua。|r")
end


-- ============================================================
-- ★ 7.1 /mkfspellscan —— 不依赖角色等级 / 已学技能的全量法术名扫描
-- ------------------------------------------------------------
-- 背景：/mkfspells 走 C_SpellBook 遍历「当前角色法术书」，低等级角色
--       尚未学习技能时几乎是空表，导不出可用的技能名 → spellID 数据。
-- 方案：C_Spell.GetSpellInfo(spellID) 查询的是**客户端静态法术数据**，
--       与角色等级、是否学会、当前职业、当前天赋完全无关。按 ID 区间
--       分段遍历即可拿到「spellID → 本地化技能名」全量表，一次覆盖全职业，
--       也因此**不需要 9 个角色各跑一遍**。
-- 性能：每帧固定批次（默认 400 个 ID），用 OnUpdate 摊到多帧，避免卡死；
--       仅手动触发时运行，可随时 /mkfspellscan stop 中止并保留已扫结果。
-- ★ 2026-11-05 实测修正（/mkfspellscan 首轮采集结论）：
--   1.60.1 的经典法术 ID 集中在 1..130000（有效 16470 条），但**无限新增的
--   法术使用 7 位 spellID**：4 级圣骑士法术书里已见 1260189「哀伤之触」、
--   1293657「语言」、1293712「护甲精通」。旧版 100 万硬上限把这一整段漏掉，
--   导致「复仇之怒 / 神圣风暴 / 圣光道标 / 正义盾击 / 复仇者之盾 / 黎明之光 /
--   荣耀圣令」等 WotLK 后续技能在反查里全部误判为「已移除」。
--   故新增 high 预设专扫 1200000..1400000，并与首轮结果增量合并。
--
-- 输出（写入 PigSet.MKFSpellScan）：
--       spellDB       全量 {id, name}（high / merge 模式累积）
--       scanSegments  已完成的扫描区间列表
--       probeResolved 插件硬编码技能名 → spellID（含同名全部 ID 列表 ids）
--       newAbilityIDs Data/Forever_Abilities.lua 的无限新天赋技能 → spellID
-- 用法：/mkfspellscan high        —— 补扫 1200000..1400000 并合并（推荐）
--       /mkfspellscan             —— 扫描经典段 1 .. 130000（会覆盖）
--       /mkfspellscan 1 300000   —— 自定义区间（会覆盖）
--       /mkfspellscan 1 300000 m —— 自定义区间且合并到已有 spellDB
--       /mkfspellscan stop       —— 中止并保留已扫结果
-- ============================================================

WR_Forever_SpellScan = WR_Forever_SpellScan or {
    active = false, from = 1, to = 130000, cur = 1, batch = 400,
    results = {}, maxResults = 80000, nextReport = 0, merge = false,
}

local WR_Forever_SpellScanFrame = CreateFrame("Frame")
WR_Forever_SpellScanFrame:Hide()

-- 扫描收尾：落数据到 PigSet，并在插件内部完成两轮反查（避免把匹配工作留到外部）
local function WR_Forever_FinishSpellScan(aborted)
    local s = WR_Forever_SpellScan
    s.active = false
    WR_Forever_SpellScanFrame:Hide()
    if type(PigSet) ~= "table" then PigSet = {} end
    PigSet.MKFSpellScan = PigSet.MKFSpellScan or {}
    local db = PigSet.MKFSpellScan
    db.spellDB   = s.results
    db.scanRange = { from = s.from, to = s.to, scanned = s.cur - 1 }
    db.scanTime  = date("%Y-%m-%d %H:%M:%S")
    -- 记录所有已扫区间：首轮经典段 + 后续 high 补扫，避免误以为数据完整
    db.scanSegments = db.scanSegments or {}
    local segs = db.scanSegments
    local dup = false
    for _, seg in ipairs(segs) do
        if seg.from == s.from and seg.to == s.to then dup = true; break end
    end
    if not dup then
        segs[#segs + 1] = { from = s.from, to = s.to, count = #s.results,
                            time = db.scanTime, merged = s.merge and true or false }
    end

    -- 本地化名字 → spellID。
    -- ★ 同名法术在静态库里往往有几十个 ID（不同等级 / NPC 版 / 测试版），
    --   单取最小 ID 会把「审判」解成 10321 而不是法术书里的 20271。
    --   因此同时保留 ids 列表，id 字段仍取最小值作保守默认，外部可据 ids 精确挑选。
    local nameToID, nameToIDs = {}, {}
    for _, e in ipairs(s.results) do
        if not nameToID[e.name] then nameToID[e.name] = e.id end
        local bucket = nameToIDs[e.name]
        if not bucket then bucket = {}; nameToIDs[e.name] = bucket end
        if #bucket < 16 then bucket[#bucket + 1] = e.id end
    end
    local function copyIDs(nm)
        local src = nameToIDs[nm]
        if not src then return nil end
        local out = {}
        for i = 1, #src do out[i] = src[i] end
        return out
    end

    -- 1) 插件硬编码技能名 → spellID
    local resolved, hit = {}, 0
    for _, name in ipairs(WR_FOREVER_PROBE_NAMES) do
        local id = nameToID[name]
        if id then hit = hit + 1 end
        resolved[#resolved + 1] = { name = name, id = id or 0, ids = copyIDs(name) }
    end
    db.probeResolved = resolved

    -- 2) 无限新天赋主动技能（Data/Forever_Abilities.lua，83 项）→ spellID
    local newIDs, newHit, seen = {}, 0, {}
    if type(WR_ForeverAbilities) == "table" then
        for classToken, list in pairs(WR_ForeverAbilities) do
            if type(list) == "table" then
                for _, a in ipairs(list) do
                    local zh = a.zh
                    if zh and not seen[zh] then
                        seen[zh] = true
                        local id = nameToID[zh] or (a.en and nameToID[a.en]) or nil
                        if id then newHit = newHit + 1 end
                        newIDs[#newIDs + 1] = {
                            name = zh, en = a.en or "", class = classToken, id = id or 0,
                            ids = copyIDs(zh) or (a.en and copyIDs(a.en)) or nil,
                        }
                    end
                end
            end
        end
    end
    db.newAbilityIDs = newIDs

    -- 顺带记录当前专精及来源，供 /mkfspec 修复效果的离线验证。
    -- 这样只需跑一条扫描命令，就能同时拿到技能表与专精识别结论。
    if type(WR_Forever_GetActiveSpec) == "function" then
        _activeSpec.name, _activeSpec.time = "", -1   -- 强制重探，不读 TTL 缓存
        local ok, n, src = pcall(WR_Forever_GetActiveSpec)
        if ok then
            db.activeSpec = { name = n or "", source = src or "" }
            print("  当前专精    : |cffffd100" .. tostring(n) .. "|r  ← " .. tostring(src))
        end
    end

    print("|cff00ff00[MKHelperForever]|r 法术名扫描" .. (aborted and "已中止" or "完成") .. "：")
    print("  扫描区间    : " .. s.from .. " .. " .. tostring(s.cur - 1) .. " / " .. s.to
          .. (s.merge and "  [合并模式]" or ""))
    print("  累计法术名  : |cffffd100" .. #s.results .. "|r 条"
          .. "（已完成 " .. #(db.scanSegments or {}) .. " 段扫描）")
    print("  插件技能名  : 精确命中 |cff00ff00" .. hit .. "|r / " .. #resolved)
    print("  无限新天赋  : 精确命中 |cff00ff00" .. newHit .. "|r / " .. #newIDs)
    if #s.results == 0 then
        print("  |cffff6666注意：一条都没取到，说明 C_Spell.GetSpellInfo 在本客户端受限")
        print("  （只接受玩家已知法术 / 返回 secret）。请跑 /mkfspells api 并把输出反馈。|r")
    end
    print("  |cffffd100输入 /reload 写入本角色 SavedVariables/MKHelperForever.lua。|r")
end

WR_Forever_SpellScanFrame:SetScript("OnUpdate", function(self)
    local s = WR_Forever_SpellScan
    if not s.active then self:Hide(); return end
    if not s.seen then s.seen = {} end
    local GetInfo = (type(C_Spell) == "table") and C_Spell.GetSpellInfo or nil
    if type(GetInfo) ~= "function" then
        WR_Forever_FinishSpellScan(true)
        print("|cffff6666[MKHelperForever]|r C_Spell.GetSpellInfo 不可用，已中止扫描。")
        return
    end

    local n = 0
    while s.cur <= s.to and n < s.batch do
        local id = s.cur
        s.cur = s.cur + 1
        n = n + 1
        local ok, info = pcall(GetInfo, id)
        if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
            local nm = info.name
            -- 过滤 NPC 长描述 / 装饰性字符串，只保留技能名长度的量级；
            -- 合并模式额外按 spellID 去重，避免重复区间把同名条目堆进存档。
            if #nm <= 36 and #s.results < s.maxResults and not s.seen[id] then
                s.seen[id] = true
                s.results[#s.results + 1] = { id = id, name = nm }
            end
        end
    end

    local done  = s.cur - s.from
    local total = s.to - s.from + 1
    if done >= s.nextReport then
        s.nextReport = done + math.max(1, math.floor(total / 4))
        print("|cff00ff00[MKHelperForever]|r 扫描进度 "
              .. math.min(100, math.floor(done / total * 100)) .. "%（已收录 " .. #s.results .. " 条）")
    end
    if s.cur > s.to or #s.results >= s.maxResults then
        WR_Forever_FinishSpellScan(false)
    end
end)

SLASH_MKFSPELLSCAN1 = "/mkfspellscan"
SlashCmdList["MKFSPELLSCAN"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    if msg:lower() == "stop" then
        if WR_Forever_SpellScan.active then
            WR_Forever_FinishSpellScan(true)
        else
            print("|cff00ff00[MKHelperForever]|r 当前没有进行中的扫描。")
        end
        return
    end
    if WR_Forever_SpellScan.active then
        print("|cffff8800[MKHelperForever]|r 扫描进行中；如需中止请输入 /mkfspellscan stop。")
        return
    end
    if type(C_Spell) ~= "table" or type(C_Spell.GetSpellInfo) ~= "function" then
        print("|cffff6666[MKHelperForever]|r C_Spell.GetSpellInfo 不可用，无法扫描；")
        print("  请先跑 /mkfspells api 查看本客户端实际暴露的接口。")
        return
    end
    local s = WR_Forever_SpellScan
    local low = msg:lower()
    -- 末尾合并标志与其前导空白均为可选，保证 "/mkfspellscan 1 300000" 能命中
    local a, b, mflag = msg:match("^(%d+)%s+(%d+)%s*([mM]?)$")
    local merge, from, to = false, tonumber(a), tonumber(b)
    if low == "high" then
        -- 无限新增法术的 7 位 ID 段（已实测 1260189 / 1293657 / 1293712）
        from, to, merge = 1200000, 1400000, true
    elseif from and to then
        merge = (mflag ~= nil and mflag ~= "")
    else
        from, to, merge = 1, 130000, false
    end
    s.from, s.to = from, to
    if s.to < s.from then s.from, s.to = s.to, s.from end
    if s.to > 2000000 then s.to = 2000000 end
    s.merge = merge
    s.cur   = s.from
    s.batch = merge and 800 or 400

    -- 合并模式：把此前落盘/内存中的 spellDB 复制到新表，并按 id 去重。
    -- 不直接引用 PigSet 里的表，避免扫描中途 stop 时把半截状态写回存档。
    s.results, s.seen = {}, {}
    if merge then
        local prev = (type(PigSet) == "table" and type(PigSet.MKFSpellScan) == "table")
                     and PigSet.MKFSpellScan.spellDB or nil
        if type(prev) == "table" then
            for _, e in ipairs(prev) do
                if type(e) == "table" and type(e.id) == "number" and not s.seen[e.id] then
                    s.seen[e.id] = true
                    s.results[#s.results + 1] = { id = e.id, name = e.name }
                end
            end
        end
    end
    s.nextReport = 0
    s.active     = true
    WR_Forever_SpellScanFrame:Show()
    print("|cff00ff00[MKHelperForever]|r 开始扫描 spellID " .. s.from .. " .. " .. s.to
          .. "（每帧 " .. s.batch .. " 个，期间可能轻微掉帧）。")
    if merge then
        print("  |cffffd100合并模式：已载入 " .. #s.results .. " 条历史结果，新命中会追加。|r")
    end
    print("  读取客户端静态法术数据，**不依赖角色等级、已学技能或当前职业**。")
    print("  随时可输入 /mkfspellscan stop 中止并保留已扫结果。")
end
