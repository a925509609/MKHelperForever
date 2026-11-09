-- ============================================================
-- Data/Forever_Racials.lua
-- 《魔兽世界：无限》种族特长全表（10 种族 / 40 项）
-- ------------------------------------------------------------
-- 数据来源：talentsforever.com racials 数据（官方口径） + 暴雪嘉年华 2026 panel
--
-- ★ 与经典版的差异要点（直接影响插件爆发/防御分支）：
--   1. 武器专精（斧/锤/剑/匕首…）从职业天赋移入种族特长 → 变为被动暴击加成
--   2. 兽人 新增「碎咒」（免疫诅咒/灾祸 + 减魔法伤害）
--   3. 被遗忘者「被遗忘者的意志」不再是免疫，改为普通解控
--   4. 暗夜精灵 新增「艾露恩之光」：+10% 暴击 15 秒（★ 新爆发种族技能）
--   5. 侏儒 新增「尤里卡！」：接下来 3 个技能减耗 +10% 伤害/治疗（★ 新爆发）
--   6. 牛头人 新增「栽培 / 平原奔跑 / 耐久」；巨魔 新增「急速回复」
--   7. 天裔（新种族）4 项特长，部落/联盟各一套命名
--
-- 本表 role 字段语义（供爆发宏/防御宏分组）：
--   burst     = 爆发向，应纳入 ZDZZ/CRZZ（自动/插入种族技能）
--   defensive = 防御向，纳入受压/减伤分支
--   control   = 控制/反控
--   utility   = 功能/机动
--   passive   = 被动，无需施放
-- ============================================================

WR_ForeverRacials = {
    -- ==========================================================
    -- 部落
    -- ==========================================================
    HORDE = {
        {
            race = "Orc", zh = "兽人",
            classes = { "WARRIOR", "HUNTER", "MAGE", "ROGUE", "WARLOCK", "SHAMAN" },
            abilities = {
                { en = "Blood Fury",         zh = "血性狂怒",   role = "burst",
                  desc = "+10% Attack Power & Spell Power for 15 sec.",
                  zhDesc = "攻击强度与法术强度提高 10%，持续 15 秒。" },
                { en = "Shatter Curse",      zh = "碎咒",       role = "defensive",
                  desc = "Immune to Curses and Banes; reduced Magical damage taken for 8 sec.",
                  zhDesc = "免疫诅咒与灾祸效果；受到的魔法伤害降低，持续 8 秒。", isNew = true },
                { en = "Axe Specialization", zh = "斧专精",     role = "passive",
                  desc = "While wielding an axe, +1% spell and ability critical strike chance.",
                  zhDesc = "持斧时，法术与技能暴击几率提高 1%。", moved = true },
                { en = "Hardiness",          zh = "坚韧",       role = "passive",
                  desc = "Stun duration reduced by 20%.",
                  zhDesc = "昏迷持续时间缩短 20%。" },
            },
        },
        {
            race = "Undead", zh = "被遗忘者",
            -- ★ 被遗忘者圣骑士为本作新增组合
            classes = { "WARRIOR", "MAGE", "ROGUE", "PRIEST", "WARLOCK", "PALADIN" },
            abilities = {
                { en = "Will of the Forsaken", zh = "被遗忘者的意志", role = "control",
                  desc = "Removes Charm, Fear and Sleep effects. (No longer an immunity.)",
                  zhDesc = "移除魅惑、恐惧与睡眠效果。（不再是免疫）", changed = true },
                { en = "Cannibalize",          zh = "食尸",           role = "utility",
                  desc = "Regenerate 35% Health and Mana from corpses.",
                  zhDesc = "从尸体上恢复 35% 生命与法力。" },
                { en = "Underwater Breathing", zh = "水下呼吸",       role = "passive",
                  desc = "Breathe underwater 300% longer.",
                  zhDesc = "水下呼吸时间延长 300%。" },
                { en = "Touch of the Grave",   zh = "坟墓之触",       role = "passive",
                  desc = "Attacks sometimes drain health.",
                  zhDesc = "攻击有时会吸取生命。" },
            },
        },
        {
            race = "Tauren", zh = "牛头人",
            classes = { "WARRIOR", "HUNTER", "DRUID", "SHAMAN" },
            abilities = {
                { en = "War Stomp",     zh = "战争践踏", role = "control",
                  desc = "Stuns nearby enemies for 2 sec.",
                  zhDesc = "眩晕附近敌人 2 秒。" },
                { en = "Cultivation",   zh = "栽培",     role = "utility",
                  desc = "Grow bonus herbs without Herbalism.",
                  zhDesc = "无需草药学也能获得额外草药。", isNew = true },
                { en = "Plainsrunning", zh = "平原奔跑", role = "utility",
                  desc = "Gain increased movement speed the longer you keep moving.",
                  zhDesc = "持续移动时移动速度逐渐提高。", isNew = true },
                { en = "Endurance",     zh = "耐久",     role = "passive",
                  desc = "+5% total Health, +1% Hit Chance.",
                  zhDesc = "总生命值提高 5%，命中几率提高 1%。", changed = true },
            },
        },
        {
            race = "Troll", zh = "巨魔",
            classes = { "WARRIOR", "HUNTER", "MAGE", "ROGUE", "PRIEST", "WARLOCK", "SHAMAN" },
            abilities = {
                { en = "Berserking",          zh = "狂暴",       role = "burst",
                  desc = "+10% attack and cast speed for 10 sec.",
                  zhDesc = "攻击与施法速度提高 10%，持续 10 秒。" },
                { en = "Rapid Regeneration",  zh = "急速回复",   role = "utility",
                  desc = "Regenerate 50% max Health over time.",
                  zhDesc = "在持续时间内恢复 50% 最大生命值。", isNew = true },
                { en = "Beast Slaying",       zh = "野兽杀手",   role = "passive",
                  desc = "+5% damage vs Beasts.",
                  zhDesc = "对野兽造成的伤害提高 5%。" },
                { en = "Regeneration",        zh = "再生",       role = "passive",
                  desc = "10% of Health regen continues in combat.",
                  zhDesc = "战斗中仍保留 10% 的生命回复。" },
            },
        },
        {
            race = "Skyborne (Windshaper)", zh = "天裔 · 御风者",
            classes = { "WARRIOR", "HUNTER", "ROGUE", "DRUID", "SHAMAN" },
            isNewRace = true,
            abilities = {
                { en = "Walk on Air",       zh = "踏空而行", role = "utility",
                  desc = "Glide downward through the air for 10 seconds.",
                  zhDesc = "在空中滑翔下降，持续 10 秒。", isNew = true },
                { en = "Skysight",          zh = "天视",     role = "utility",
                  desc = "Receive an Elemental Blessing increasing run speed by 10%.",
                  zhDesc = "获得元素赐福，移动速度提高 10%。", isNew = true },
                { en = "Wind Blessed",      zh = "风之赐福", role = "passive",
                  desc = "Passive. 1% increased melee, ranged, and spellcasting Haste.",
                  zhDesc = "被动。近战、远程与施法急速提高 1%。", isNew = true },
                { en = "Elemental Insight", zh = "元素洞察", role = "passive",
                  desc = "Passive. Damage to Elementals increased by 5%.",
                  zhDesc = "被动。对元素生物造成的伤害提高 5%。", isNew = true },
            },
        },
    },

    -- ==========================================================
    -- 联盟
    -- ==========================================================
    ALLIANCE = {
        {
            race = "Human", zh = "人类",
            classes = { "WARRIOR", "HUNTER", "MAGE", "ROGUE", "PRIEST", "WARLOCK", "PALADIN" },
            abilities = {
                { en = "Will to Survive",     zh = "求生意志",   role = "control",
                  desc = "Removes Stun effects.",
                  zhDesc = "移除眩晕效果。" },
                { en = "Perception",          zh = "感知",       role = "utility",
                  desc = "Detect stealth for 20 sec.",
                  zhDesc = "侦测潜行，持续 20 秒。" },
                { en = "Sword Specialization",zh = "剑专精",     role = "passive",
                  desc = "While wielding a sword, +2% spell and ability critical strike chance.",
                  zhDesc = "持剑时，法术与技能暴击几率提高 2%。", moved = true },
                { en = "The Human Spirit",    zh = "人类精魂",   role = "passive",
                  desc = "+5% Spirit.",
                  zhDesc = "精神提高 5%。" },
            },
        },
        {
            race = "Dwarf", zh = "矮人",
            -- ★ 矮人萨满为本作新增组合
            classes = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "PALADIN", "SHAMAN" },
            abilities = {
                { en = "Stoneform",           zh = "石像形态",   role = "defensive",
                  desc = "Immune to Bleeds, Poison and Disease; reduced Physical damage taken for 8 sec.",
                  zhDesc = "免疫流血、中毒与疾病；受到的物理伤害降低，持续 8 秒。" },
                { en = "Find Treasure",       zh = "寻找财宝",   role = "utility",
                  desc = "Track treasure chests.",
                  zhDesc = "追踪宝箱。" },
                { en = "Mace Specialization", zh = "锤专精",     role = "passive",
                  desc = "While wielding a mace, +1% spell and ability critical strike chance.",
                  zhDesc = "持锤时，法术与技能暴击几率提高 1%。", moved = true },
                { en = "Big Game Hunter",     zh = "巨兽猎手",   role = "passive",
                  desc = "+5% damage vs Beasts.",
                  zhDesc = "对野兽造成的伤害提高 5%。" },
            },
        },
        {
            race = "Night Elf", zh = "暗夜精灵",
            classes = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "DRUID" },
            abilities = {
                { en = "Elune's Light", zh = "艾露恩之光", role = "burst",
                  desc = "+10% critical strike chance for 15 sec.",
                  zhDesc = "暴击几率提高 10%，持续 15 秒。", isNew = true },
                { en = "Shadowmeld",    zh = "影遁",       role = "utility",
                  desc = "Stealth while immobile.",
                  zhDesc = "静止时进入潜行。" },
                { en = "Quickness",     zh = "迅捷",       role = "passive",
                  desc = "+1% Dodge, +2% run speed.",
                  zhDesc = "闪避提高 1%，移动速度提高 2%。" },
                { en = "Wisp Spirit",   zh = "小精灵之魂", role = "passive",
                  desc = "+75% speed while dead.",
                  zhDesc = "死亡后移动速度提高 75%。" },
            },
        },
        {
            race = "Gnome", zh = "侏儒",
            classes = { "WARRIOR", "MAGE", "ROGUE", "PRIEST", "WARLOCK" },
            abilities = {
                { en = "Escape Artist",              zh = "逃命专家",   role = "utility",
                  desc = "Briefly immune to Roots and Snares.",
                  zhDesc = "短暂免疫定身与减速。" },
                { en = "Eureka!",                    zh = "尤里卡！",   role = "burst",
                  desc = "Reduced cost and +10% damage/healing on your next 3 abilities.",
                  zhDesc = "接下来 3 个技能降低消耗，并使其伤害/治疗提高 10%。", isNew = true },
                { en = "Expansive Mind",             zh = "开阔思维",   role = "passive",
                  desc = "+5% Mana, Rage and Energy.",
                  zhDesc = "法力、怒气与能量上限提高 5%。" },
                { en = "Engineering Specialization", zh = "工程学专精", role = "passive",
                  desc = "More reliable engineering devices.",
                  zhDesc = "工程学装置更可靠。" },
            },
        },
        {
            race = "Skyborne (High Order)", zh = "天裔 · 高阶议会",
            classes = { "WARRIOR", "HUNTER", "MAGE", "ROGUE", "DRUID" },
            isNewRace = true,
            abilities = {
                { en = "Walk on Air",       zh = "踏空而行", role = "utility",
                  desc = "Glide downward through the air for 10 seconds.",
                  zhDesc = "在空中滑翔下降，持续 10 秒。", isNew = true },
                { en = "Read Ley Line",     zh = "解读地脉", role = "utility",
                  desc = "Activate a ley line to gain 100% increased Health and Mana regeneration.",
                  zhDesc = "激活地脉，使生命与法力回复速度提高 100%。", isNew = true },
                { en = "Wind Blessed",      zh = "风之赐福", role = "passive",
                  desc = "Passive. 1% increased melee, ranged, and spellcasting Haste.",
                  zhDesc = "被动。近战、远程与施法急速提高 1%。", isNew = true },
                { en = "Elemental Insight", zh = "元素洞察", role = "passive",
                  desc = "Passive. Damage to Elementals increased by 5%.",
                  zhDesc = "被动。对元素生物造成的伤害提高 5%。", isNew = true },
            },
        },
    },
}

-- ============================================================
-- ★ 派生的爆发/防御技能名表（供 GX.lua 的 ZDZZ / CRZZ 分支使用）
-- ------------------------------------------------------------
-- 经典版的种族爆发只有「狂暴 / 血性狂怒 / 狮心」三项；
-- 无限新增了「艾露恩之光」「尤里卡！」，并把「石像形态」重新纳入防御链。
-- ============================================================
WR_Forever_RacialSpells = {
    -- 爆发向（应纳入自动种族 ZDZZ / 插入种族 CRZZ）
    burst = {
        HORDE    = { "血性狂怒", "狂暴" },
        ALLIANCE = { "艾露恩之光", "尤里卡！" },
        BOTH     = { "狂暴", "血性狂怒", "艾露恩之光", "尤里卡！" },
    },
    -- 防御向（受压/减伤分支）
    defensive = {
        BOTH = { "石像形态", "碎咒" },
    },
    -- 反控/功能向
    control = {
        BOTH = { "被遗忘者的意志", "求生意志", "逃命专家", "战争践踏" },
    },
}

-- 种族中文名 → 英文 token（UnitRace 返回值可能是中文，做双向映射）
WR_Forever_RaceToken = {
    ["兽人"]       = "Orc",
    ["被遗忘者"]   = "Scourge",
    ["亡灵"]       = "Scourge",
    ["牛头人"]     = "Tauren",
    ["巨魔"]       = "Troll",
    ["天裔"]       = "Skyborne",
    ["人类"]       = "Human",
    ["矮人"]       = "Dwarf",
    ["暗夜精灵"]   = "NightElf",
    ["侏儒"]       = "Gnome",
}

-- 新种族/新组合速查（用于菜单提示与日志）
WR_Forever_NewCombos = {
    { race = "被遗忘者", class = "PALADIN", zh = "被遗忘者圣骑士（部落首个圣骑士）" },
    { race = "矮人",     class = "SHAMAN",  zh = "矮人萨满（联盟首个萨满）" },
    { race = "天裔",     class = "SHAMAN",  zh = "天裔萨满（部落）" },
    { race = "天裔",     class = "MAGE",    zh = "天裔法师（联盟）" },
    { race = "天裔",     class = "DRUID",   zh = "天裔德鲁伊（专属形态）" },
}

-- ============================================================
-- ★ 查询辅助
-- ============================================================

-- 遍历全部种族（部落 + 联盟）
function WR_Forever_EachRace(fn)
    for _, faction in ipairs({ "HORDE", "ALLIANCE" }) do
        for _, r in ipairs(WR_ForeverRacials[faction] or {}) do fn(r, faction) end
    end
end

-- 按英文/中文种族名取种族条目
function WR_Forever_GetRace(raceName)
    if not raceName then return nil end
    local found
    WR_Forever_EachRace(function(r)
        if r.race == raceName or r.zh == raceName
            or (raceName == "Skyborne" and r.isNewRace) then found = r end
    end)
    return found
end

-- 该种族能否选某职业（返回 true/false）
function WR_Forever_RaceHasClass(raceName, classToken)
    local r = WR_Forever_GetRace(raceName)
    if not r or not classToken then return false end
    for _, c in ipairs(r.classes or {}) do
        if c == classToken then return true end
    end
    return false
end
