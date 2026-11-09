-- ============================================================
-- Core/SoD_Runes.lua
-- 探索赛季(Season of Discovery, SoD) 符文检测层
-- ------------------------------------------------------------
-- 设计要点：
--   * SoD 的「符文刻印」把新技能刻在装备槽（Chest/Legs/Hands/Belt/
--     Boots/Helm/Bracers/Cloak/Ring）。刻上后该技能进入法术书，
--     因此 IsPlayerSpell(spellID) 为真。
--   * 经典客户端 IsPlayerSpell 只接受整数 ID，故用 GetSpellInfo(中文名)
--     解析 ID 并缓存（WR_SoD_GetSpellID）。
--   * 各职业旋转通过 WR_SoD_HasRune(class, key) 门控：装备了某符文
--     才把对应技能纳入优先级链。→ 一套代码天然覆盖 P1–P4：
--     你装备了哪个阶段的符文，就自动解锁哪些技能（未装备则分支跳过）。
--
-- 注意：符文→法术中文名来自 SoD 符文资料（mmogah 符文表 + Icy-Veins）。
--   若某中文名在你的 zhCN 客户端与法术书不完全一致，该符文分支只是
--   「不触发」，不会报错。上线后用 /sodrunes 核对实际已激活符文即可。
-- ============================================================

-- ★ 每职业：符文 key = 中文法术名（刻上符文后法术书里的名字）
--   注释标出该符文默认所属装备槽与解锁阶段（P1=25级…P4=60级）
WR_SoD_RUNE_MAP = {
    -- ===================== 圣骑士 PALADIN =====================
    PALADIN = {
        -- 输出循环核心（惩戒）
        CrusaderStrike   = "十字军打击",   -- 手(P1)  核心循环
        DivineStorm      = "神圣风暴",     -- 胸(P1)  AoE/单体爆发
        Exorcist         = "驱邪",         -- 腿(P1)  常驻输出（Exorcist 符文）
        SealOfMartyrdom  = "殉难圣印",     -- 胸(P1)  常驻圣印
        TheArtOfWar      = "战神之力",     -- 脚(P2)  暴击/急速增益
        SheathOfLight    = "圣光之鞘",     -- 腰(P2)  自我治疗
        Wrath            = "愤怒之锤",     -- 头(P3)  强化版（<20%斩杀）
        ImprovedHammer   = "强化愤怒之锤", -- 腕(P3)  愤怒之锤强化
        AuraMastery      = "光环掌握",     -- 光环强化（符文/天赋，按需核对名）
        -- 防御 / 辅助
        BeaconOfLight    = "光明之信标",   -- 手(P1)  辅助治疗
        Rebuke           = "责难",         -- 腿(P1)  打断
        Inspiration      = "灵感",         -- 腿(P1)
        HornOfLordaeron  = "洛丹伦之角",   -- 胸(P1)  团队增益
        Aegis            = "庇护",         -- 胸(P1)  减伤
        Exemplar         = "典范",         -- 腿(P1)  威胁/减伤
        SealOfCommand    = "命令圣印",     -- 手(P1)  seal twisting 用
        SealOfTheCrusader= "十字军圣印",   -- 腿(P1)  上 debuff 用
    },

    -- ===================== 战士 WARRIOR =====================
    WARRIOR = {
        Flagellation      = "鞭笞",        -- 胸(P1)  狂怒爆发
        RagingBlow        = "狂暴打击",     -- 胸(P1)  核心输出
        BloodFrenzy       = "血之狂热",     -- 胸(P1)  致死/嗜血增伤
        Warbringer        = "战争使者",     -- 胸(P1)  冲锋/拦截强化
        Devastate         = "毁灭打击",     -- 手(P1)  防战起手
        EndlessRage       = "无尽狂怒",     -- 手(P1)  怒气
        SingleMindedFury  = "单手狂怒",     -- 手(P1)  双持增伤
        VictoryRush       = "胜利冲锋",     -- 手(P1)  续航
        QuickStrike       = "迅捷打击",     -- 手(P1)  副手
        ConsumedByRage    = "愤怒吞噬",     -- 腿(P1)  斩杀增伤
        FrenziedAssault   = "狂乱攻击",     -- 腿(P1)  攻速
        FuriousThunder    = "狂怒雷霆",     -- 腿(P1)  雷霆强化
        -- P2/P3/P4 扩展槽（按客户端实际符文名补全）
        -- Belt/Boots/Helm/Bracers：如「Righteous Fury」「Shield Block」等，待补
    },

    -- ===================== 以下为 P2 阶段其余职业符文集（基于 mmogah 符文表，待客户端核对） =====================
    MAGE = {
        LivingFlame    = "活体烈焰",   -- 腿(P1)
        ArcaneSurge    = "奥术涌动",   -- 腿(P1)
        MassRegen      = "群体再生",   -- 腿(P1)
        IcyVeins       = "冰冷之血",   -- 腿(P1)  (SoD 冰脉符文)
        Regeneration   = "再生",       -- 胸(P1)
        Burnout        = "燃烧",       -- 胸(P1)
        Enlightenment  = "启明",       -- 胸(P1)
        FingersOfFrost = "冰霜之指",   -- 手(P1)
        RewindTime     = "时光逆转",   -- 手(P1)
        IceLance       = "冰枪术",     -- 手(P1)
        ArcaneBlast    = "奥术冲击",   -- 手(P1)
        LivingBomb     = "活体炸弹",   -- 手(P1)
    },
    WARLOCK = {
        LakeOfFire     = "烈焰之湖",   -- 胸(P1)
        Metamorphosis  = "魔变",       -- 手(P1)
        ChaosBolt      = "混乱箭",     -- 手(P1)
        Haunt          = "鬼影缠身",   -- 手(P1)
        EverlastingAff = "持久痛苦",   -- 腿(P1)
        Incinerate     = "烧尽",       -- 腿(P1)
        DemonicGrace   = "恶魔之赐",   -- 腿(P1)
        DemonicPact    = "恶魔契约",   -- 腿(P1)
        ShadowBoltVolley="暗影箭雨",   -- 手(P1)
        MasterChanneler= "大师channel", -- 胸(P1)
        SoulSiphon     = "灵魂虹吸",   -- 胸(P1)
        DemonicTactics = "恶魔战术",   -- 胸(P1)
    },
    DRUID = {
        FuryOfStormrage= "风暴之怒",   -- 胸(P1)
        WildStrikes    = "野性打击",   -- 胸(P1)
        SurvivalOfFittest="生存本能",  -- 胸(P1)
        LivingSeed     = "生命种子",   -- 胸(P1)
        WildGrowth      = "野性成长",  -- 手(P1)
        Mangle          = "裂伤",      -- 手(P1)
        Lacerate        = "割伤",      -- 手(P1)
        Sunfire         = "阳炎术",    -- 手(P1)
        SkullBash       = "迎头痛击",  -- 腿(P1)
        Lifebloom       = "生命绽放",  -- 腿(P1)
        SavageRoar      = "野蛮咆哮",  -- 腿(P1)
        Starsurge       = "星涌术",    -- 腿(P1)
    },
    HUNTER = {
        CobraStrikes    = "眼镜蛇打击", -- 胸(P1)
        LoneWolf        = "孤狼",       -- 胸(P1)
        MasterMarksman  = "神射手",     -- 胸(P1)
        AspectOfLion    = "雄狮守护",   -- 胸(P1)
        BeastMastery    = "野兽控制",   -- 手(P1)
        Carve           = "削砍",       -- 手(P1)
        ChimeraShot     = "奇美拉射击", -- 手(P1)
        ExplosiveShot   = "爆炸射击",   -- 手(P1)
        FlankingStrike  = "侧翼打击",   -- 腿(P1)
        KillCommand     = "杀戮命令",   -- 腿(P1)
        SerpentSpread   = "毒蛇蔓延",   -- 腿(P1)
        SniperTraining  = "狙击训练",   -- 腿(P1)
    },
    ROGUE = {
        DeadlyBrew      = "致命毒药",   -- 胸(P1)
        JustAFleshWound = "仅是皮肉伤", -- 胸(P1)
        QuickDraw       = "快速拔枪",   -- 胸(P1)
        SlaughterFromShadows="暗影杀戮", -- 胸(P1)
        Mutilate        = "毁伤",       -- 手(P1)
        Shadowstrike    = "暗影步",     -- 手(P1)
        SaberSlash      = "军刀猛刺",   -- 手(P1)
        Shiv            = "破甲",       -- 手(P1)
        BetweenTheEyes  = "要害打击",   -- 腿(P1)
        BladeDance      = "刀扇",       -- 腿(P1)
        Envenom         = "致命药膏",   -- 腿(P1)
    },
    PRIEST = {
        StrengthOfSoul  = "灵魂之力",   -- 胸(P1)
        Serendipity     = "意外好运",   -- 胸(P1)
        VoidPlague      = "虚空瘟疫",   -- 胸(P1)
        TwistedFaith    = "扭曲信仰",   -- 胸(P1)
        ShadowWordDeath = "暗言术：死", -- 手(P1)
        CircleOfHealing = "治疗之环",   -- 手(P1)
        Penance         = "苦修",       -- 手(P1)
        MindSear        = "心灵灼烧",   -- 手(P1)
        PrayerOfMending = "愈合祷言",   -- 腿(P1)
        Homunculi       = "魔像",       -- 腿(P1)
        SharedPain      = "痛苦分担",   -- 腿(P1)
        PowerWordBarrier= "真言术：障", -- 腿(P1)
    },
    SHAMAN = {
        DualWieldSpec   = "双武器专精", -- 胸(P1)
        HealingRain     = "治疗之雨",   -- 胸(P1)
        Overload        = "过载",       -- 胸(P1)
        ShieldMastery   = "盾牌精通",   -- 胸(P1)
        LavaBurst       = "熔岩爆裂",   -- 手(P1)
        LavaLash        = "熔岩猛击",   -- 手(P1)
        MoltenBlast     = "熔融爆破",   -- 手(P1)
        WaterShield     = "水之护盾",   -- 手(P1)
        AncestralGuidance="先祖指引",   -- 腿(P1)
        EarthShield     = "大地之盾",   -- 腿(P1)
        ShamanisticRage = "萨满之怒",   -- 腿(P1)
        WayOfEarth      = "大地之道",   -- 腿(P1)
    },
    DEATHKNIGHT = {
        -- 注意：DK 在 SoD 经典客户端仍用 GetRuneCooldown(1..6) 原生符文系统，
        -- 以下为 SoD 新增「符文技能」（与原始符文槽并存）
        DeathStrike     = "死亡打击",   -- 原生符文
        Pestilence      = "瘟疫打击",   -- 原生符文
        -- SoD 符文（待客户端核对中文名与槽位）
        -- 例：EmpowerRuneWeapon / Conversion 等
    },
}

-- ============================================================
-- ★ 解析中文法术名 → spellID（缓存）
-- ============================================================
local WR_SoD_IDCache = {}
function WR_SoD_GetSpellID(name)
    if WR_SoD_IDCache[name] ~= nil then return WR_SoD_IDCache[name] end
    local id = select(7, GetSpellInfo(name))  -- GetSpellInfo 第7返回为 spellID
    WR_SoD_IDCache[name] = id or false
    return id
end

-- ============================================================
-- ★ 核心：是否装备了某符文（对应法术是否在法术书中）
--   用法：if WR_SoD_HasRune("PALADIN", "CrusaderStrike") then ... end
-- ============================================================
function WR_SoD_HasRune(class, key)
    -- ★ SoD 总开关：菜单勾选 SOD_ENABLE=false 时抑制全部符文技能（回退无符文基线）
    if PigSet["SOD_ENABLE"] == false then return false end
    -- ★ 单符文开关：菜单勾选 SOD_<RuneKey>=false 时单独禁用该符文技能
    if PigSet["SOD_" .. key] == false then return false end
    local map = WR_SoD_RUNE_MAP[class]
    if not map then return false end
    local name = map[key]
    if not name then return false end
    local id = WR_SoD_GetSpellID(name)
    if not id then return false end
    return IsPlayerSpell(id)
end

-- ★ 任一符文存在
function WR_SoD_HasAnyRune(class, ...)
    for _, key in ipairs({ ... }) do
        if WR_SoD_HasRune(class, key) then return true end
    end
    return false
end

-- ★ 全部符文存在
function WR_SoD_HasAllRunes(class, ...)
    for _, key in ipairs({ ... }) do
        if not WR_SoD_HasRune(class, key) then return false end
    end
    return true
end

-- ============================================================
-- ★ 治疗目标选择：返回当前队伍/团队中血量最低且低于阈值的友方单位
--   用于各治疗职业旋转（颜色块模型下由玩家用 mouseover/指向宏施放）
--   依赖经典客户端 GetNumRaidMembers / GetNumPartyMembers（SoD 1.15 仍有效）
-- ============================================================
function WR_SoD_GetLowestFriendly(threshold)
    threshold = threshold or 0.85
    local best, bestHP = nil, 1
    local units = { "player" }
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    if raid > 0 then
        for i = 1, raid do units[#units + 1] = "raid" .. i end
    elseif party > 0 then
        for i = 1, party do units[#units + 1] = "party" .. i end
    end
    for _, u in ipairs(units) do
        if UnitExists(u) and not UnitIsDead(u) and UnitIsVisible(u) then
            local hp = WR_GetUnitHP(u)
            if hp < threshold and hp < bestHP then best, bestHP = u, hp end
        end
    end
    return best
end

-- ============================================================
-- ★ 色块槽位优先取自各职业 _Macros.lua（宏槽层）
-- ------------------------------------------------------------
-- 背景：WR_ColorFrame_Show(Name, Text) 的 Name 必须是「数值颜色槽位」
--   （1–240，见 Core/UI_ColorFrame.lua 的 ColorTable）。各职业 *Macros.lua
--   里每行 WR_CreateMacro("键位", "/CAST 技能") 后带注释 -- N，那个 N 就是
--   该技能在 AHK ColorMap 中对应的颜色槽位（职业专用 1–200；200–240 为
--   Core/Global_Macros.lua 全局保留，职业文件不可占用）。
-- 机制：各职业 *Macros.lua 在加载时用 WR_SkillColor[职业] = { ["技能名"]=槽位 }
--   登记；旋转统一调用 WR_ColorFrame_ShowSkill(技能名, 回退槽位)，优先从
--   _Macros.lua 取槽位，缺失时回退到调用处传入的默认槽位，保证不会因漏登而崩。
-- 这样颜色块显示与 AHK 按键保持一一对应（改键/加符文技能只需在 _Macros.lua 调）。
-- ============================================================
WR_SkillColor = WR_SkillColor or {}   -- 由各职业 *Macros.lua 填充；键为大写职业 token

-- ★ 解析技能中文名 → 颜色槽位号（优先 _Macros.lua；找不到返回 nil）
function WR_SoD_ResolveSlot(skillName)
    local cls = WR_PlayerClass
    if not cls then return nil end
    local map = WR_SkillColor[cls]
    if map and map[skillName] then return map[skillName] end
    return nil
end

-- ★ 便捷封装：旋转统一调用，色块槽位优先来自职业 _Macros.lua
--   skillName   ：技能中文名（同时作为色块显示文字）
--   fallbackSlot：_Macros.lua 未登记时的回退槽位（建议保留原旋转里的数值）
--   返回 true（供旋转作为该分支的命中标志，与 WR_ColorFrame_Show 一致）
--
--   ★★ 2026-11-08 重要修复：原「极端兜底」会把技能名哈希成 1–200 的任意槽位，
--     这极易撞上「跟随/焦点」等特殊键位（如 115=跟随目标 / 116=设焦点 / 117=跟随焦点），
--     导致 AHK 误按 /follow、/focus —— 正是「莫名其妙跟随/设焦点」的根源之一。
--     现在改为：解析不到槽位时**不点亮任何色块**，只输出文字告警，
--     让开发者明确知道「该技能没登记槽位」，而不是静默撞到随机键位上。
function WR_ColorFrame_ShowSkill(skillName, fallbackSlot)
    local slot = WR_SoD_ResolveSlot(skillName) or fallbackSlot
    if not slot then
        -- 不猜槽位：静默跳过并只提示一次，避免误触其他功能键位
        WR_SoD_UnmappedWarned = WR_SoD_UnmappedWarned or {}
        local key = tostring(skillName)
        if not WR_SoD_UnmappedWarned[key] then
            WR_SoD_UnmappedWarned[key] = true
            print("|cffff8040[MKHelper]|r 技能未登记色块槽位，已跳过提示：" .. key)
        end
        return false
    end
    return WR_ColorFrame_Show(slot, skillName)
end

-- ============================================================
-- ★ 调试命令 /sodrunes：列出当前已激活符文（测试用）
-- ============================================================
SLASH_SODRUNES1 = "/sodrunes"
SlashCmdList["SODRUNES"] = function()
    local class = UnitClassBase("player")
    local map = WR_SoD_RUNE_MAP[class]
    if not map then
        print("|cff00ff00[MKHelperForever SoD]|r 当前职业无符文映射表")
        return
    end
    print("|cff00ff00[MKHelperForever SoD]|r 已激活符文：")
    local found = 0
    for key, name in pairs(map) do
        if WR_SoD_HasRune(class, key) then
            print("  |cff00adf0" .. key .. "|r = " .. name)
            found = found + 1
        end
    end
    if found == 0 then
        print("  (无 — 请确认符文已刻印且中文名与法术书一致)")
    end
end
