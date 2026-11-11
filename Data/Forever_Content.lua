-- ============================================================
-- Data/Forever_Content.lua
-- 《魔兽世界：无限》(WoW: Forever) 首发内容注册表
-- ------------------------------------------------------------
-- 数据来源：2026 暴雪嘉年华开幕式 + 首发内容 panel（2026-09-13）
--   · 新区域 4 个：海加尔山 / 泽风岛 / 辛德拉 / 河林
--   · 新地下城 9 座（覆盖 13→60 全等级段）
--   · 团队副本 2 个（10 人「深穴」 / 20 人「海加尔峰」）
--   · 新战场 1 个：暗矛群岛（15v15）
--   · 等级上限永久 60，横向更新，无飞行坐骑，无等级缩放
--
-- 用途：
--   1. WR_ForeverContent.IsForeverZone(zoneName)  —— 判断当前是否处于无限的新区域
--   2. WR_ForeverContent.FindInstanceByZone(zone) —— 由区域名反查地下城/团本条目
--   3. WR_ForeverContent.GetLevelBracket(level)   —— 由等级反推适合的地下城
--   4. 主面板「内容」页直接遍历本表渲染
-- ============================================================

WR_ForeverContent = {
    -- ★ 版本标识：随客户端补丁推进可手工 bump
    version        = "2026.11.05",
    launchDate     = "2026-11-05",
    levelCap       = 60,
    betaStart      = "2026-09-17",   -- 国际服公开测试
    betaEnd        = "2026-10-21",
    cnBetaStart    = "2026-10-06",   -- 国服删档测试
    namePickStart  = "2026-10-27",   -- 名称预留开放

    -- ==========================================================
    -- ★ 新区域（4 个）
    -- ==========================================================
    zones = {
        { key = "ZephrasIsle", en = "Zephras Isle",     zh = "泽风岛",
          kind = "起始区域", level = "1-12",
          note = "天裔的起始区域，融合经典美学与天空之墙风格的建筑；必须走完才能分阵营。" },
        { key = "Riverglades", en = "The Riverglades",  zh = "河林",
          kind = "荒野边疆", level = "30-45",
          note = "遍布河流、草原与贸易路线的边疆；有艰难求存的聚落与延续已久的恩怨。" },
        { key = "Shendralas",  en = "Shen'dralas",      zh = "辛德拉",
          kind = "谜团区域", level = "20-40",
          note = "长期隐藏于莫高雷与凄凉之地之间，涉及多个种族的故事线。" },
        { key = "MountHyjal",  en = "Mount Hyjal",      zh = "海加尔山",
          kind = "终局区域", level = "50-60",
          note = "阿克蒙德败亡后的复苏之地；世界之树与 20 人团本「海加尔峰」所在。" },
    },

    -- ==========================================================
    -- ★ 新地下城（9 座）
    --   levelMin 为该地下城的最低进入等级（官方 panel 口径）
    -- ==========================================================
    dungeons = {
        { key = "HallOfThanes",     en = "Hall of Thanes",       zh = "领主大厅",
          zone = "丹莫罗 · 铁炉堡地下",       levelMin = 13, levelMax = 20,
          note = "铁炉堡地下的领主大厅，低等级副本双起点之一。" },
        { key = "RuinsOfLordaeron", en = "Ruins of Lordaeron",   zh = "洛丹伦废墟",
          zone = "提瑞斯法林地",             levelMin = 15, levelMax = 24,
          note = "洛丹伦废墟，低等级副本双起点之一（与领主大厅对应）。" },
        { key = "ExcavationSite",   en = "Excavation Site",      zh = "发掘现场",
          zone = "湿地 · 维尔加挖掘场上方",   levelMin = 20, levelMax = 30,
          note = "探险者协会的发掘现场，填补 20 级段副本空缺。" },
        { key = "CityOfDalaran",    en = "City of Dalaran",      zh = "达拉然城",
          zone = "奥特兰克山脉",             levelMin = 20, levelMax = 35,
          note = "陷入混乱的达拉然城；官方 panel 给出的等级段为 20–35。" },
        { key = "TheDrownedCity",   en = "The Drowned City",     zh = "沉没之城",
          zone = "荆棘谷海岸",               levelMin = 35, levelMax = 45,
          note = "荆棘谷外海的沉没巨魔遗迹，填补 35+ 段副本空缺。" },
        { key = "KroldokStronghold",en = "Krol'dok Stronghold",  zh = "克罗多克要塞",
          zone = "河林",                     levelMin = 40, levelMax = 55,
          note = "河林边疆的要塞，覆盖 40–55 的长等级段。" },
        { key = "AlcazIslandPrison",en = "Alcaz Island Prison",  zh = "奥卡兹监狱",
          zone = "尘泥沼泽外海 · 奥卡兹岛",   levelMin = 48, levelMax = 53,
          note = "奥卡兹岛监狱，中期终局过渡副本。" },
        { key = "ShapersTerrace",   en = "Shaper's Terrace",     zh = "塑造者之台",
          zone = "安戈洛环形山",             levelMin = 55, levelMax = 60,
          note = "满级前最后一个副本（55–60）。" },
        { key = "BlackmawHold",     en = "Blackmaw Hold",        zh = "黑喉要塞",
          zone = "艾萨拉",                   levelMin = 55, levelMax = 60,
          note = "熊怪城市黑喉要塞；官方未公布其等级区间，此处按终局副本暂定。" },
    },

    -- ==========================================================
    -- ★ 团队副本（2 个）
    -- ==========================================================
    raids = {
        { key = "BarrowDeeps", en = "The Barrow Deeps", zh = "深穴",
          size = 10, levelMin = 60,
          zone = "海加尔山 · 夜精灵神殿地下",
          note = "满级 10 人挑战；地点为海加尔山下的深穴（Barrow Dens）。" },
        { key = "HyjalSummit", en = "Hyjal Summit",     zh = "海加尔峰",
          size = 20, levelMin = 60,
          zone = "海加尔山",
          note = "满级 20 人核心团本；含传说级任务线与全新职业套装。" },
    },

    -- ==========================================================
    -- ★ 战场
    -- ==========================================================
    battlegrounds = {
        { key = "DarkspearIslands", en = "Darkspear Islands", zh = "暗矛群岛",
          size = "15v15",
          zone = "卡利姆多近海",
          note = "融合战略要地争夺 + 旗帜占领与防守玩法（阿拉希盆地式）。" },
    },

    -- ==========================================================
    -- ★ 首发系统（影响插件行为的项）
    -- ==========================================================
    systems = {
        { key = "Legacy",      zh = "传承系统",   desc = "面向升级玩家与小号的账号级进度系统，覆盖 1–60 全程。" },
        { key = "Camping",     zh = "露营系统",   desc = "野外搭建营火，其他玩家可用专业技能为营地作贡献并共享增益。" },
        { key = "Transmog",    zh = "幻化系统",   desc = "可选择是否启用幻化，并可控制是否显示他人的幻化外观。" },
        { key = "VisualToggle",zh = "视觉预设",   desc = "可切换现代/经典视觉预设、HD/SD 角色模型，HD 模型可还原经典动画。" },
        { key = "Hardcore",    zh = "硬核模式",   desc = "可选永久死亡规则集（独立于经典硬核服）。" },
        { key = "Gamepad",     zh = "手柄支持",   desc = "官方手柄支持。" },
        { key = "Honor",       zh = "荣誉系统重做",desc = "荣誉系统与 PvP 奖励链重构。" },
        { key = "TalentRework",zh = "天赋重做",   desc = "移除纯属性加点型天赋，写入 Classic 时代从未出现的技能（含 WotLK 系天赋下沉）。" },
        { key = "RacialRework",zh = "种族特长重做",desc = "全种族特长重写，武器专精由职业天赋移入种族特长。" },
    },

    -- ==========================================================
    -- ★ 新种族 / 新职业组合
    -- ==========================================================
    races = {
        { key = "Skyborne", en = "Skyborne", zh = "天裔",
          neutral = true,
          hordeName = "天裔 · 御风者", allianceName = "天裔 · 高阶议会",
          startZone = "泽风岛",
          note = "中立的精灵族，来自新发现的泽风岛；起始区必须走完才会分阵营。" },
    },

    -- 首发确认的新职业组合（含天裔）
    combos = {
        -- {race, class, faction}
        { race = "Skyborne", raceZh = "天裔", class = "SHAMAN",  classZh = "萨满祭司", faction = "Horde" },
        { race = "Skyborne", raceZh = "天裔", class = "MAGE",    classZh = "法师",     faction = "Alliance" },
        { race = "Skyborne", raceZh = "天裔", class = "WARRIOR", classZh = "战士",     faction = "Both" },
        { race = "Skyborne", raceZh = "天裔", class = "HUNTER",  classZh = "猎人",     faction = "Both" },
        { race = "Skyborne", raceZh = "天裔", class = "ROGUE",   classZh = "潜行者",   faction = "Both" },
        { race = "Skyborne", raceZh = "天裔", class = "DRUID",   classZh = "德鲁伊",   faction = "Both" },
        { race = "Undead",   raceZh = "被遗忘者", class = "PALADIN", classZh = "圣骑士", faction = "Horde" },
        { race = "Dwarf",    raceZh = "矮人",  class = "SHAMAN",  classZh = "萨满祭司", faction = "Alliance" },
    },
}

-- ============================================================
-- ★ 查询辅助
-- ============================================================

-- 区域名归一化：英文小写去空格 / 保留中文原样
local function WR_Forever_NormZone(s)
    if not s then return "" end
    s = tostring(s)
    if s:find("[\228-\233]") then return s end          -- 含中文，原样返回
    return s:lower():gsub("[%s'’%-]", "")
end

-- 是否属于无限的新区域（用于野外/区域专属逻辑）
function WR_ForeverContent.IsForeverZone(zoneName)
    local n = WR_Forever_NormZone(zoneName)
    if n == "" then return false end
    for _, z in ipairs(WR_ForeverContent.zones) do
        if WR_Forever_NormZone(z.zh) == n or WR_Forever_NormZone(z.en) == n then return true, z end
    end
    return false
end

-- 由区域名反查副本条目（先匹配地下城，再匹配团本）；返回 entry, kind
function WR_ForeverContent.FindInstanceByZone(zoneName)
    local n = WR_Forever_NormZone(zoneName)
    if n == "" then return nil end
    for _, d in ipairs(WR_ForeverContent.dungeons) do
        if WR_Forever_NormZone(d.zh) == n or WR_Forever_NormZone(d.en) == n then return d, "dungeon" end
    end
    for _, r in ipairs(WR_ForeverContent.raids) do
        if WR_Forever_NormZone(r.zh) == n or WR_Forever_NormZone(r.en) == n then return r, "raid" end
    end
    return nil
end

-- 是否为无限的新副本（地下城或团本）
function WR_ForeverContent.IsForeverInstance(zoneName)
    return WR_ForeverContent.FindInstanceByZone(zoneName) ~= nil
end

-- 由当前等级返回所有可用地下城
function WR_ForeverContent.GetLevelBracket(level)
    level = tonumber(level) or 0
    local out = {}
    for _, d in ipairs(WR_ForeverContent.dungeons) do
        if level >= d.levelMin and level <= (d.levelMax or 60) then out[#out + 1] = d end
    end
    return out
end

-- 全部首发副本名（中文）——供黑名单/白名单批量登记
function WR_ForeverContent.GetAllInstanceNamesCN()
    local out = {}
    for _, d in ipairs(WR_ForeverContent.dungeons) do out[#out + 1] = d.zh end
    for _, r in ipairs(WR_ForeverContent.raids) do out[#out + 1] = r.zh end
    return out
end

-- 全部首发副本名（英文）——中文名与客户端不一致时兜底匹配
function WR_ForeverContent.GetAllInstanceNamesEN()
    local out = {}
    for _, d in ipairs(WR_ForeverContent.dungeons) do out[#out + 1] = d.en end
    for _, r in ipairs(WR_ForeverContent.raids) do out[#out + 1] = r.en end
    return out
end
