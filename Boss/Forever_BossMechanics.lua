-- ============================================================
-- Boss/Forever_BossMechanics.lua
-- 《魔兽世界：无限》首发副本 / BOSS 机制注册表
-- ------------------------------------------------------------
-- 首发内容（2026-09-13 暴雪嘉年华公布）：
--   地下城 9 座 —— 领主大厅 / 洛丹伦废墟 / 发掘现场 / 达拉然城 /
--                  沉没之城 / 克罗多克要塞 / 奥卡兹监狱 / 塑造者之台 / 黑喉要塞
--   团队副本 2 个 —— 深穴（10 人） / 海加尔峰（20 人）
--
-- ★ 关于 BOSS 名与技能名：
--   截至 2026-09-13（嘉年华次日）暴雪只公布了副本名称与等级段，
--   BOSS 个体名与技能名要等 9/17 公开测试开服后才可实测。
--   因此本文件：
--     · 立即提供「副本识别 + 空机制槽 + 注册 API」的完整框架
--     · 机制条目通过 WR_Forever_RegisterBoss() 在测试服实测后填入，
--       或在下方 Forever_Seed 表中直接补写（格式与 WR_BossMechanics 完全一致）
--     · 自动并入全局 WR_BossMechanics，各职业 *BossSpecials.lua 无需改动
--
-- 依赖：本文件须在 Boss\WR_BossMechanics.lua 之后加载（见 TOC 顺序）
-- ============================================================

WR_ForeverBossInstances = {
    -- ==========================================================
    -- 地下城（9）
    -- ==========================================================
    { key = "HallOfThanes",      zh = "领主大厅",   en = "Hall of Thanes",
      kind = "dungeon", levelMin = 13, levelMax = 20, zone = "丹莫罗 · 铁炉堡地下", pending = true },
    { key = "RuinsOfLordaeron",  zh = "洛丹伦废墟", en = "Ruins of Lordaeron",
      kind = "dungeon", levelMin = 15, levelMax = 24, zone = "提瑞斯法林地", pending = true },
    { key = "ExcavationSite",    zh = "发掘现场",   en = "Excavation Site",
      kind = "dungeon", levelMin = 20, levelMax = 30, zone = "湿地 · 维尔加挖掘场上方", pending = true },
    { key = "CityOfDalaran",     zh = "达拉然城",   en = "City of Dalaran",
      kind = "dungeon", levelMin = 20, levelMax = 35, zone = "奥特兰克山脉", pending = true },
    { key = "TheDrownedCity",    zh = "沉没之城",   en = "The Drowned City",
      kind = "dungeon", levelMin = 35, levelMax = 45, zone = "荆棘谷海岸", pending = true },
    { key = "KroldokStronghold", zh = "克罗多克要塞", en = "Krol'dok Stronghold",
      kind = "dungeon", levelMin = 40, levelMax = 55, zone = "河林", pending = true },
    { key = "AlcazIslandPrison", zh = "奥卡兹监狱", en = "Alcaz Island Prison",
      kind = "dungeon", levelMin = 48, levelMax = 53, zone = "尘泥沼泽外海 · 奥卡兹岛", pending = true },
    { key = "ShapersTerrace",    zh = "塑造者之台", en = "Shaper's Terrace",
      kind = "dungeon", levelMin = 55, levelMax = 60, zone = "安戈洛环形山", pending = true },
    { key = "BlackmawHold",      zh = "黑喉要塞",   en = "Blackmaw Hold",
      kind = "dungeon", levelMin = 55, levelMax = 60, zone = "艾萨拉", pending = true },

    -- ==========================================================
    -- 团队副本（2）
    -- ==========================================================
    { key = "BarrowDeeps", zh = "深穴",     en = "The Barrow Deeps",
      kind = "raid", size = 10, levelMin = 60, zone = "海加尔山 · 夜精灵神殿地下",
      hint = "海加尔山下的深穴（Barrow Dens）；剧情指向伊利丹的囚禁之地。", pending = true },
    { key = "HyjalSummit", zh = "海加尔峰", en = "Hyjal Summit",
      kind = "raid", size = 20, levelMin = 60, zone = "海加尔山",
      hint = "阿克蒙德败亡后的海加尔峰；含传说级任务线与全新职业套装。", pending = true },
}

-- 便于按 zoneName（中/英）快速反查
WR_ForeverInstanceByZone = {}
for _, inst in ipairs(WR_ForeverBossInstances) do
    WR_ForeverInstanceByZone[inst.zh] = inst
    WR_ForeverInstanceByZone[inst.en] = inst
end

-- ============================================================
-- ★ BOSS 机制表（格式与 WR_BossMechanics 完全一致）
-- ------------------------------------------------------------
-- 键   = BOSS 中文名；子键 = BOSS 英文名（true）
-- 机制 = { name, checkFunction, applicableRoles, action, colorID, description }
--
-- ★ 实测后补写示例（拿到 BOSS 名后照抄即可生效）：
--   WR_ForeverSeed_Boss = {
--       ["某某 BOSS"] = {
--           ["Some Boss"] = true,
--           id = 0,
--           instance = "HyjalSummit",
--           mechanisms = {
--               {
--                   name = "某某技能-停手",
--                   checkFunction = function()
--                       if PigSet and PigSet.FOR_XXX == false then return false end
--                       local c = GetDebuffCount("player", "某某debuff")
--                       if c and c >= 1 then return true end
--                       return false
--                   end,
--                   applicableRoles = { melee_dps = true, ranged_caster_dps = true },
--                   action = "stop",
--                   colorID = 3,
--                   description = "某某技能-停手",
--               },
--           },
--       },
--   }
-- ============================================================
WR_ForeverSeed_Boss = WR_ForeverSeed_Boss or {}

-- 运行期注册的 BOSS（/mkfboss add 或测试服脚本注入）
WR_ForeverBossMechanics = WR_ForeverBossMechanics or {}

-- ============================================================
-- ★ 注册 API
-- ============================================================

-- 注册 / 覆盖一个 BOSS 机制条目
--   bossZH / bossEN : 中英文 BOSS 名（任一可为 nil，但至少一个）
--   data            : { instance=, id=, mechanisms={...} }
-- 返回：写入后的条目
function WR_Forever_RegisterBoss(bossZH, bossEN, data)
    data = data or {}
    local key = bossZH or bossEN
    if not key then return nil end
    local entry = WR_ForeverBossMechanics[key] or {}
    if bossEN then entry[bossEN] = true end
    entry.id = data.id or entry.id or 0
    entry.instance = data.instance or entry.instance
    entry.mechanisms = data.mechanisms or entry.mechanisms or {}
    WR_ForeverBossMechanics[key] = entry
    WR_Forever_MergeBossMechanics()
    return entry
end

-- 把 Forever 的 BOSS 条目并入全局 WR_BossMechanics
--   冲突策略：已存在同名键则跳过（不覆盖原经典/SoD 条目）
function WR_Forever_MergeBossMechanics()
    if type(WR_BossMechanics) ~= "table" then return 0 end
    local merged = 0
    for _, src in ipairs({ WR_ForeverSeed_Boss, WR_ForeverBossMechanics }) do
        for k, v in pairs(src) do
            if WR_BossMechanics[k] == nil then
                WR_BossMechanics[k] = v
                merged = merged + 1
            end
        end
    end
    return merged
end

-- ============================================================
-- ★ 当前副本识别
-- ============================================================

-- 依据当前区域名判断是否处于无限的副本中
-- 返回：instanceEntry, kind("dungeon"/"raid")  |  未命中返回 nil
function WR_Forever_CurrentInstance()
    local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
    if zone == "" then return nil end
    local inst = WR_ForeverInstanceByZone[zone]
    if inst then return inst, inst.kind end
    -- 容错：区域名包含关系匹配（客户端可能带副标题）
    for key, v in pairs(WR_ForeverInstanceByZone) do
        if type(key) == "string" and key ~= "" and zone:find(key, 1, true) then return v, v.kind end
    end
    return nil
end

-- 是否处于无限的副本内
function WR_Forever_IsInForeverInstance()
    return WR_Forever_CurrentInstance() ~= nil
end

-- 该 BOSS 是否属于无限的副本（供各职业 BossSpecials 做前置过滤）
function WR_Forever_IsForeverBoss(bossName)
    if not bossName then return false end
    local e = WR_ForeverBossMechanics[bossName] or WR_ForeverSeed_Boss[bossName]
    return e ~= nil
end

-- ============================================================
-- ★ 斜杠命令 /mkfboss
-- ============================================================
SLASH_MKFBOSS1 = "/mkfboss"
SlashCmdList["MKFBOSS"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    local sub = msg:lower()

    if sub == "" or sub == "list" then
        print("|cff00ff00[MKHelperForever]|r 无限首发副本（" .. #WR_ForeverBossInstances .. "）：")
        for _, inst in ipairs(WR_ForeverBossInstances) do
            local tag = (inst.kind == "raid") and ("|cffffd100团队 " .. (inst.size or "?") .. "人|r")
                or "|cff00adf0地下城|r"
            local lv = inst.levelMin and ("Lv " .. inst.levelMin .. (inst.levelMax and ("-" .. inst.levelMax) or "+")) or ""
            print(string.format("  %s %-12s %-22s %s%s",
                tag, inst.zh, inst.zone or "", lv,
                inst.pending and "  |cff888888(机制待实测)|r" or ""))
        end
        local n = 0
        for _ in pairs(WR_ForeverBossMechanics) do n = n + 1 end
        for _ in pairs(WR_ForeverSeed_Boss) do n = n + 1 end
        print("  已登记 BOSS 机制条目：" .. n .. " 条")

    elseif sub == "now" then
        local inst = WR_Forever_CurrentInstance()
        if inst then
            print("|cff00ff00[MKHelperForever]|r 当前副本：" .. inst.zh .. " (" .. inst.en .. ")  " .. (inst.kind == "raid" and "团队副本" or "地下城"))
        else
            local zone = (GetRealZoneText and GetRealZoneText()) or "?"
            print("|cff00ff00[MKHelperForever]|r 当前区域「" .. tostring(zone) .. "」不在无限首发副本表内。")
        end

    elseif sub == "merge" then
        local n = WR_Forever_MergeBossMechanics()
        print("|cff00ff00[MKHelperForever]|r 已并入全局 BOSS 表 " .. n .. " 条。")

    else
        print("|cff00ff00[MKHelperForever]|r 用法：")
        print("  /mkfboss list   列出无限首发副本与已登记 BOSS")
        print("  /mkfboss now    报告当前所在副本")
        print("  /mkfboss merge  把 Forever BOSS 表并入全局 WR_BossMechanics")
    end
end
