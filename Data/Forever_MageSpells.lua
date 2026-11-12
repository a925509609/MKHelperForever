-- ============================================================
-- Data/Forever_MageSpells.lua
-- 法师法术书 ID 速查表（SpellID / IconID）
-- ------------------------------------------------------------
-- ★ 数据来源：2026-11-12 游戏内「法术书」截图 29 张
--   （fengfeng\*.jpg，手机拍摄）。每条 tooltip 上的 SpellID /
--   IconID 均按截图原样照抄，未做任何推测。
--
-- ★ 用途（供后续法师功能开发）：
--   1. 面板条目 IconID（Mage_Menu.lua 的 IconID 字段）
--   2. 技能中文名 → 数字 spellID 反查（绕开 WR_ResolveSpellID
--      在无限 1.60.x 下「中文名→ID」不可靠的问题）
--   3. 技能图标 / 等级 / 消耗 / 施法时间 / CD / 射程 速查
--
-- ★ 已做一致性校验：SpellID 与截图里的法术等级完全吻合
--   （例：火球术 8402 = Rank7、寒冰箭 8408 = Rank7、
--     奥术飞弹 8416 = Rank4、冰锥术 8492 = Rank2、
--     暴风雪 8427 = Rank3、冰霜新星 865 = Rank2、
--     变形术 12824 = Rank2、奥术智慧 1461 = Rank3、
--     造水术 6127 = Rank4、造食术 6129 = Rank4、
--     魔爆术 8439 = Rank4、烈焰风暴 8422 = Rank3、
--     火焰冲击 8413 = Rank5、法力护盾 8495 = Rank3、
--     霜甲术 7301 = Rank3、冰甲术 7302 = Rank1），
--   说明 OCR 取到的数字可信。
--
-- ★ 注意：冰枪术 spellID = 1240044 属 7 位「无限新增段」
--   （见 MKHelperForever.toc 顶部关于 1200000..1400000 段的说明），
--   不是经典段的 30455 / 42872。
--
-- ★ 注意：霜甲术(7301) 与 冰甲术(7302) 在本服共用图标 135843，
--   按图标反查名字时两者会撞，需优先用名字查。
-- ============================================================

WR_Forever_MageSpells = {
    -- ===================== 奥术 =====================
    { name = "奥术智慧",       spellID = 1461,    iconID = 135932, rank = 3,  cost = 520,  cast = "瞬发",   cd = 0,   range = 30, school = "奥术", note = "智力 +15，持续 1 小时" },
    { name = "奥术飞弹",       spellID = 8416,    iconID = 136096, rank = 4,  cost = 320,  cast = "引导",   cd = 0,   range = 30, school = "奥术", note = "每秒 84 点奥术伤害，持续 5 秒" },
    { name = "魔爆术",         spellID = 8439,    iconID = 136116, rank = 4,  cost = 250,  cast = "瞬发",   cd = 0,   range = 0,  school = "奥术", note = "以自身为中心 10 码 AOE，137~150 奥术伤害" },
    { name = "法力护盾",       spellID = 8495,    iconID = 136153, rank = 3,  cost = 80,   cast = "瞬发",   cd = 0,   range = 0,  school = "奥术", note = "吸收 300 物理伤害，每吸收 1 点消耗 2 法力，持续 1 分钟" },
    { name = "法术反制",       spellID = 2139,    iconID = 135856, rank = 0,  cost = 100,  cast = "瞬发",   cd = 30,  range = 30, school = "奥术", note = "打断施法，使其 10 秒内无法施放同系法术，高仇恨" },
    { name = "缓落术",         spellID = 130,     iconID = 135992, rank = 0,  cost = 40,   cast = "瞬发",   cd = 0,   range = 0,  school = "奥术", note = "需材料「轻羽毛」，减慢下落速度 30 秒" },
    { name = "解除次级诅咒",   spellID = 475,     iconID = 136082, rank = 0,  cost = 81,   cast = "瞬发",   cd = 0,   range = 30, school = "奥术", note = "移除友方 1 个诅咒或疾病（单次一种，非群体）" },
    { name = "变形术",         spellID = 12824,   iconID = 136071, rank = 2,  cost = 90,   cast = "1.5秒",  cd = 0,   range = 30, school = "奥术", note = "变羊最多 30 秒，受伤害即恢复；同时只能变一个；仅野兽/人型/小动物" },
    { name = "闪现术",         spellID = 1953,    iconID = 135736, rank = 0,  cost = 284,  cast = "瞬发",   cd = 15,  range = 0,  school = "奥术", note = "前移 20 码（途中有障碍则失败），同时解除昏迷与定身" },
    { name = "唤醒",           spellID = 12051,   iconID = 136075, rank = 0,  cost = 0,    cast = "引导",   cd = 480, range = 0,  school = "奥术", note = "引导期间法力回复速度 +1500%，持续 8 秒；CD 8 分钟" },
    { name = "制造魔法玛瑙",   spellID = 759,     iconID = 134104, rank = 0,  cost = 530,  cast = "3秒",    cd = 0,   range = 0,  school = "奥术", note = "制造魔法玛瑙，使用后立即恢复 375~425 法力；登出 15 分钟后消失" },
    { name = "制造魔法翡翠",   spellID = 3552,    iconID = 134105, rank = 0,  cost = 800,  cast = "3秒",    cd = 0,   range = 0,  school = "奥术", note = "制造魔法翡翠，使用后立即恢复 550~650 法力；登出 15 分钟后消失" },
    { name = "造水术",         spellID = 6127,    iconID = 132797, rank = 4,  cost = 285,  cast = "3秒",    cd = 0,   range = 0,  school = "奥术", note = "合成 18 瓶魔法泉水；登出 15 分钟后消失" },
    { name = "造食术",         spellID = 6129,    iconID = 133950, rank = 4,  cost = 285,  cast = "3秒",    cd = 0,   range = 0,  school = "奥术", note = "合成 14 块魔法面包；登出 15 分钟后消失" },
    { name = "魔甲术",         spellID = 6117,    iconID = 135991, rank = 1,  cost = 270,  cast = "瞬发",   cd = 0,   range = 0,  school = "奥术", note = "全系魔法抗性 +5，任意情况保持 50% 法力回复；持续 30 分钟" },
    { name = "传送：奥格瑞玛", spellID = 3567,    iconID = 135759, rank = 0,  cost = 120,  cast = "10秒",   cd = 0,   range = 0,  school = "奥术", note = "需材料「传送符文」" },
    { name = "传送：幽暗城",   spellID = 3563,    iconID = 135766, rank = 0,  cost = 120,  cast = "10秒",   cd = 0,   range = 0,  school = "奥术", note = "需材料「传送符文」" },
    { name = "传送：雷霆崖",   spellID = 3566,    iconID = 135765, rank = 0,  cost = 120,  cast = "10秒",   cd = 0,   range = 0,  school = "奥术", note = "需材料「传送符文」" },

    -- ===================== 火焰 =====================
    { name = "火球术",         spellID = 8402,    iconID = 135812, rank = 7,  cost = 220,  cast = "3.5秒",  cd = 0,   range = 35, school = "火焰", note = "222~273 火焰伤害，并在 8 秒内额外造成 24 点 DoT" },
    { name = "火焰冲击",       spellID = 8413,    iconID = 135807, rank = 5,  cost = 220,  cast = "瞬发",   cd = 8,   range = 20, school = "火焰", note = "239~282 火焰伤害，瞬发，移动中也可打出" },
    { name = "烈焰风暴",       spellID = 8422,    iconID = 135826, rank = 3,  cost = 490,  cast = "3秒",    cd = 0,   range = 30, school = "火焰", note = "地面 AOE 167~206，并在 8 秒内额外 139 点；每名法师同时只能有一个生效" },

    -- ===================== 冰霜 =====================
    { name = "寒冰箭",         spellID = 8408,    iconID = 135846, rank = 7,  cost = 136,  cast = "2.5秒",  cd = 0,   range = 33, school = "冰霜", note = "219~235 冰霜伤害，并降低目标移动速度 40%，持续 8 秒" },
    { name = "冰枪术",         spellID = 1240044, iconID = 135844, rank = 3,  cost = 51,   cast = "瞬发",   cd = 8,   range = 33, school = "冰霜", note = "43~51 冰霜伤害；对已冰冻目标伤害提高 300%（7 位 spellID，无限新增段）" },
    { name = "冰锥术",         spellID = 8492,    iconID = 135852, rank = 2,  cost = 246,  cast = "瞬发",   cd = 10,  range = 0,  school = "冰霜", note = "面前锥形 148~162 冰霜伤害并减速 40% 持续 8 秒；前 4 个目标额外再减速 10%、减速延长 3 秒" },
    { name = "暴风雪",         spellID = 8427,    iconID = 135857, rank = 3,  cost = 612,  cast = "引导",   cd = 0,   range = 33, school = "冰霜", note = "8 秒内对目标区域内敌人共造成 518 点冰霜伤害（地面 AOE）" },
    { name = "冰霜新星",       spellID = 865,     iconID = 135848, rank = 2,  cost = 72,   cast = "瞬发",   cd = 25,  range = 0,  school = "冰霜", note = "自身周围 36~40 冰霜伤害并把敌人冻结在原地，最多 8 秒" },
    { name = "寒冰屏障",       spellID = 11958,   iconID = 135841, rank = 0,  cost = 13,   cast = "瞬发",   cd = 300, range = 0,  school = "冰霜", note = "10 秒内免疫所有物理攻击与法术影响，期间无法攻击/移动/施法；CD 5 分钟" },
    { name = "霜甲术",         spellID = 7301,    iconID = 135843, rank = 3,  cost = 144,  cast = "瞬发",   cd = 0,   range = 0,  school = "冰霜", note = "护甲 +200；被近战攻击时可能降低攻击者移速 30%、攻击间隔延长 25%（5 秒）；持续 30 分钟" },
    { name = "冰甲术",         spellID = 7302,    iconID = 135843, rank = 1,  cost = 204,  cast = "瞬发",   cd = 0,   range = 0,  school = "冰霜", note = "护甲 +290、冰霜抗性 +6；被近战攻击时可能降低攻击者移速 30%、攻击间隔延长 25%（5 秒）；持续 30 分钟" },
}

-- ============================================================
-- 索引与查询 helper
-- ------------------------------------------------------------
-- 名字索引：WR_Forever_MageSpellIndex["火球术"] = 上面那条表项
-- 图标索引：WR_Forever_MageIconIndex[135812] = { "火球术", ... }
-- ============================================================
WR_Forever_MageSpellIndex = WR_Forever_MageSpellIndex or {}
WR_Forever_MageIconIndex  = WR_Forever_MageIconIndex  or {}

for _, e in ipairs(WR_Forever_MageSpells) do
    WR_Forever_MageSpellIndex[e.name] = e
    local bucket = WR_Forever_MageIconIndex[e.iconID]
    if not bucket then
        bucket = {}
        WR_Forever_MageIconIndex[e.iconID] = bucket
    end
    bucket[#bucket + 1] = e.name
end

-- 取整条表项（找不到返回 nil）
function WR_Forever_MageSpell(name)
    if type(name) ~= "string" then return nil end
    return WR_Forever_MageSpellIndex[name]
end

-- 技能中文名 → 数字 spellID（找不到返回 nil）
-- ★ 优先用这个，别依赖 WR_ResolveSpellID 的中文名解析
function WR_Forever_MageSpellID(name)
    local e = WR_Forever_MageSpellIndex[name]
    return e and e.spellID or nil
end

-- 技能中文名 → 图标 ID（可直接喂给 Mage_Menu.lua 的 IconID 字段）
function WR_Forever_MageIconID(name)
    local e = WR_Forever_MageSpellIndex[name]
    return e and e.iconID or nil
end

-- 图标 ID → 使用该图标的技能名列表（用于排查图标撞车）
function WR_Forever_MageNamesByIcon(iconID)
    return WR_Forever_MageIconIndex[iconID]
end

-- ============================================================
-- 调试命令 /mkmagespells：打印法师法术书 ID 表
-- ============================================================
SLASH_MKMAGESPELLS1 = "/mkmagespells"
SlashCmdList["MKMAGESPELLS"] = function()
    print("|cff69CCF0[MKHelperForever]|r 法师法术书 ID 表（共 " .. #WR_Forever_MageSpells .. " 条）")
    local lastSchool = nil
    for _, e in ipairs(WR_Forever_MageSpells) do
        if e.school ~= lastSchool then
            lastSchool = e.school
            print("  |cffffd100" .. lastSchool .. "|r")
        end
        print(string.format("    %s   spellID=%d  iconID=%d  rank=%d  %s",
            e.name, e.spellID, e.iconID, e.rank or 0, e.cast or "-"))
    end
end
