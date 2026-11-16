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

-- ============================================================
-- ★★★ 2026-11-12 用户口径：「技能不够蓝释放时，应当不亮色块，导致一直按按键」
-- ------------------------------------------------------------
-- 这是「蓝不够不亮色块」的【总闸层】：所有职业旋转都经由
-- WR_ColorFrame_ShowSkill 点亮色块，即使某个循环忘了自己判 WR_SpellUsable，
-- 也会在这里被拦下。
--
-- 两条独立证据（任一命中即判死）：
--   ① 资源算术：技能消耗（GetSpellPowerCost）× 当前资源（UnitPower）
--      —— 由 Core/Forever_Compat.lua 的 WR_Forever_NotEnoughPower 提供；
--   ② 客户端回执：AHK 按键被客户端拒绝时弹出的「法力不足 / 能量不足…」
--      错误文字。资源在战斗中可能是 secret 读不到，这时只有客户端知道
--      到底缺不缺，所以把「刚亮过的那个技能」记进短期黑名单。
-- 两者都「读不到就放行」——宁可少判，不可把整条循环误杀。
-- ============================================================

-- 技能名 → 解禁时刻。客户端明确回执「资源不足」后写入。
WR_SoD_PowerBlocked = WR_SoD_PowerBlocked or {}
-- 最近一次点亮色块时用的技能名（供错误回执归因）
WR_SoD_LastShownSpell = WR_SoD_LastShownSpell or nil
-- 回执黑名单时长（秒）。太长会漏放、太短会被 AHK 连按放大，取 2.5 秒。
WR_SoD_POWER_BLOCK_SEC = 2.5

-- ★ 每 tick 的「本轮是否点亮过」标记。
-- 色块模型是「亮着 = 现在该按这个键」：一次 WR_ColorFrame_Show 会先把所有色块
-- 隐藏再显示一个，所以「本轮没点亮任何色块」= 此刻不该按任何技能键。
-- 但上一 tick 亮着的那个色块不会自己消失 → AHK 读到同色继续按。
-- 这正是「蓝不够还在一直按」的直接成因，需要每 tick 收尾清扫（见下）。
WR_SoD_TickSeq = 0
WR_SoD_ShownTick = -1
WR_SoD_ShownSkill = nil

function WR_SoD_BeginTick()
    WR_SoD_TickSeq = (WR_SoD_TickSeq or 0) + 1
end

-- 资源不足色块的统一收口：
--   force=false → 每 tick 收尾清扫（MainLoop 调用）：本轮没点亮任何色块时，
--                 把「上一 tick 残留且现在资源不足」的色块熄灭；
--   force=true  → 资源变化事件立即刷新（2026-11-13）：跳过「本轮已亮过」短路 ——
--                 蓝量在点亮之后又被其它动作吃掉时，本 tick 刚亮的色块同样要
--                 立即熄灭，tick 间隙里 AHK 仍会读色按键，等下一个 tick 就是空按。
-- 只处理资源不足这一种情形：其它原因（CD 中 / 无目标 / 脱战）各有自己的
-- ClearStalePrompts / HideSkillLater 机制，不在总闸层擅自扩大改动面。
function WR_SoD_RefreshPowerBlocks(force)
    if not force and WR_SoD_ShownTick == WR_SoD_TickSeq then return false end   -- 本轮亮过，交给正常覆盖
    local name = WR_SoD_ShownSkill
    if type(name) ~= "string" or name == "" then return false end
    if not WR_SoD_NotEnoughPower(name) then return false end
    WR_HideSkillColorSlot(name, nil)
    WR_SoD_ShownSkill = nil
    return true
end

-- 每 tick 收尾清扫（保持旧签名，MainLoop 的调用点不变）
function WR_SoD_SweepPowerBlocked()
    return WR_SoD_RefreshPowerBlocks(false)
end

-- 该技能此刻是否「资源不足」→ true 表示必须不亮（并熄灭残留色块）
function WR_SoD_NotEnoughPower(skillName)
    if type(skillName) ~= "string" or skillName == "" then return false end

    -- ① 客户端回执黑名单
    local t = WR_SoD_PowerBlocked
    if type(t) == "table" then
        local untilAt = t[skillName]
        if type(untilAt) == "number" then
            if GetTime() < untilAt then return true end
            t[skillName] = nil          -- 过期即清，避免表无限增长
        end
    end

    -- ② 资源算术（Core/Forever_Compat.lua 提供；离线夹具未加载时跳过）
    --   用 pcall 探测而不是 type()=="function"：本仓库老坑 —— 夹具里 WoW/跨文件
    --   可调用对象可能是 userdata，type 守卫会让整段静默跳过。
    if WR_Forever_NotEnoughPower ~= nil then
        local ok, notEnough = pcall(WR_Forever_NotEnoughPower, skillName)
        if ok and notEnough == true then return true end
    end
    return false
end

-- 熄灭「某技能自己的」色块（两侧 + 技能图标框），不清别的槽位。
-- 用途：资源不足时把上一 tick 已经亮着的色块收掉 —— 只 return false 不熄灭的话，
-- 色块会一直挂着，AHK 读到同色就继续按，正是用户看到的「不够蓝还一直按」。
function WR_HideSkillColorSlot(skillName, slot)
    local s = slot
    if not s and type(WR_SoD_ResolveSlot) == "function" then
        s = WR_SoD_ResolveSlot(skillName)
    end
    if s ~= nil then
        if ColorFrameArrayTopLeft and ColorFrameArrayTopLeft[s] then
            ColorFrameArrayTopLeft[s]:Hide()
        end
        if ColorFrameArrayTopRight and ColorFrameArrayTopRight[s] then
            ColorFrameArrayTopRight[s]:Hide()
        end
        if ColorTextArrayTopLeft and ColorTextArrayTopLeft[s] then
            ColorTextArrayTopLeft[s]:Hide()
        end
        if ColorTextArrayTopRight and ColorTextArrayTopRight[s] then
            ColorTextArrayTopRight[s]:Hide()
        end
    end
    -- 技能图标框：当前显示的正是该技能时才收
    local iconFrame = WR_SkillIconFrame
    if iconFrame and iconFrame.Text and type(skillName) == "string" then
        local ok, txt = pcall(iconFrame.Text.GetText, iconFrame.Text)
        if ok and type(txt) == "string" and string.find(txt, skillName, 1, true) then
            if iconFrame.Icon then iconFrame.Icon:Hide() end
            iconFrame.Text:Hide()
        end
    end
end

-- 客户端「资源不足」回执监听：把刚亮过的技能记进短期黑名单并立刻熄灭。
-- 覆盖 12.x / 无限 / 经典三种文案（中文 + 英文），不依赖 UI_ERROR_MESSAGE 的数字常量。
--
-- ★ 匹配必须「资源词 + 不足词」同时命中，不能只匹配「能量 / mana」：
--   只匹配资源词的话，「能量涌动」「Mana Tide Totem」这类正常提示也会被当成
--   缺资源 → 把刚亮过的技能误拉黑 2.5 秒 → 表现为「技能偶尔莫名不亮」。
--   这里按「资源词 × 不足词」组合判定，宁可漏判（漏判只退化成本次空按一次，
--   下一次资源算术闸仍会挡住）也不误判。
do
    local POWER_WORDS = { "法力", "魔法值", "能量", "怒气", "符文能量", "集中值" }
    local LOW_WORDS   = { "不足", "不够", "缺少", "太低" }
    local EN_POWER    = { "mana", "energy", "rage", "focus", "runic power" }
    local EN_LOW      = { "not enough", "insufficient", "low on", "requires more" }

    local function Lower(s) return string.lower(s) end

    -- 对外暴露（夹具断言用；也让 /mk 诊断能查这条判定）
    function WR_SoD_IsPowerError(message)
        if type(message) ~= "string" or message == "" then return false end
        -- 中文：资源词 + 不足词
        for i = 1, #POWER_WORDS do
            if string.find(message, POWER_WORDS[i], 1, true) then
                for j = 1, #LOW_WORDS do
                    if string.find(message, LOW_WORDS[j], 1, true) then return true end
                end
                return false
            end
        end
        -- 英文：客户端 zhCN 缺译文时会回落英文
        local low = Lower(message)
        for i = 1, #EN_POWER do
            if string.find(low, EN_POWER[i], 1, true) then
                for j = 1, #EN_LOW do
                    if string.find(low, EN_LOW[j], 1, true) then return true end
                end
                return false
            end
        end
        return false
    end

    local frame = CreateFrame("Frame")
    if frame and frame.RegisterEvent then
        frame:RegisterEvent("UI_ERROR_MESSAGE")
        frame:SetScript("OnEvent", function(_, _, _, message)
            if not WR_SoD_IsPowerError(message) then return end
            local name = WR_SoD_LastShownSpell
            if type(name) ~= "string" or name == "" then return end
            WR_SoD_PowerBlocked[name] = GetTime() + WR_SoD_POWER_BLOCK_SEC
            WR_HideSkillColorSlot(name, nil)
        end)
    end
end

-- ============================================================
-- ★★★ 2026-11-13 用户口径「确保在蓝量变化、技能消耗变化或相关状态更新时，
--   及时刷新所有技能色块的显示」—— 资源变化事件驱动的立即刷新层。
-- ------------------------------------------------------------
-- 色块的亮/灭判定本来就每 tick 重算（0.1 秒），事件层补的是 tick 间隙：
--   · 蓝量下降 → 此刻亮着的技能已经付不起 → 立即熄灭（AHK 在 tick 间隙也在
--     读色按键，等下一个 tick 就是一到两次空按）；
--   · 蓝量回升 → 判定自然放行，下一 tick 循环照常重新点亮；事件层绝不做
--     「主动点亮」，点亮权始终在职业循环手里（与总闸「宁灭不误亮」口径一致）。
-- 事件名按客户端代际并集注册（注册不存在的 event 新客户端会抛错，所以逐个
-- pcall）：UNIT_POWER_UPDATE（新）/ UNIT_POWER（中间代）/ UNIT_MANA /
-- UNIT_RAGE / UNIT_ENERGY（经典）。
-- 事件带 unitToken 时只关心玩家自己的资源变化；战斗中资源读不到（secret）
-- 时判定自动放行，不会误灭 —— 与总闸「宁可少判不可误挡」口径一致。
-- ============================================================
do
    local POWER_EVENTS = {
        "UNIT_POWER_UPDATE", "UNIT_POWER", "UNIT_MANA", "UNIT_RAGE", "UNIT_ENERGY",
    }
    local frame = CreateFrame("Frame")
    if frame and frame.RegisterEvent then
        for i = 1, #POWER_EVENTS do
            pcall(frame.RegisterEvent, frame, POWER_EVENTS[i])
        end
        frame:SetScript("OnEvent", function(_, event, unit)
            if unit ~= nil and unit ~= "player" then return end
            -- 立即失效「当前资源」的 0.05 秒帧缓存：事件已证明资源变了，缓存里
            -- 的旧读数不能再喂给判定（冻结时钟的离线夹具也依赖这一步生效）。
            if type(WR_Forever_PowerNowCache) == "table" then
                for k in pairs(WR_Forever_PowerNowCache) do
                    WR_Forever_PowerNowCache[k] = nil
                end
            end
            -- force=true：本 tick 刚点亮的色块同样复查（点亮之后蓝被吃掉的情况）
            WR_SoD_RefreshPowerBlocks(true)
        end)
    end
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
    -- ★ 2026-11-16：槽位合法性闸。ColorTable 只到 240，任何 301/302… 这类历史遗留
    --   越界值都会让 WR_CreateSingleColorSlot → PIG_BGRtoBGR(nil) 抛错，整个循环 tick
    --   崩掉。这里统一按「未登记」处理：不点亮、只告警一次，绝不把错误槽位传给 UI。
    if slot ~= nil and (type(slot) ~= "number" or slot < 1 or slot > 240) then
        WR_SoD_UnmappedWarned = WR_SoD_UnmappedWarned or {}
        local badKey = tostring(skillName) .. "(" .. tostring(slot) .. ")"
        if not WR_SoD_UnmappedWarned[badKey] then
            WR_SoD_UnmappedWarned[badKey] = true
            print("|cffff8040[MKHelper]|r 技能色块槽位越界，已跳过提示：" .. badKey)
        end
        -- 主动熄灭上一 tick 的残留色块，避免 AHK 继续按旧键
        if type(WR_HideColorFrame) == "function" then WR_HideColorFrame(zhandoumoshi) end
        return false
    end
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

    -- ★★★ 2026-11-12 用户口径：「技能不够蓝释放时，应当不亮色块，导致一直按按键」
    -- ------------------------------------------------------------
    -- 这是「蓝不够不亮」的【总闸】：所有职业旋转都经由本函数点亮色块，
    -- 即使某个循环忘了自己判 WR_SpellUsable，也会在这里被拦下。
    --
    -- 关键点：拦下时必须【主动熄灭该槽位】。
    --   色块是「上一 tick 亮着就一直亮」的模型 —— WR_ColorFrame_Show 只在
    --   成功点亮时先隐藏全部再显示一个；如果本 tick 直接 return false 而不
    --   熄灭，上一 tick 的色块会一直挂着，AHK 读到同色就继续按 → 正是用户
    --   看到的「不够蓝还一直按」。所以这里必须 Hide 掉该技能自己的槽位。
    if WR_SoD_NotEnoughPower(skillName) then
        WR_HideSkillColorSlot(skillName, slot)
        return false
    end

    local shown = WR_ColorFrame_Show(slot, skillName)
    if shown then
        -- 记录「最近一次点亮的技能名」：客户端弹出「法力不足」回执时据此归因，
        -- 把该技能记进短期黑名单（资源在战斗中可能是 secret，只有客户端知道）。
        WR_SoD_LastShownSpell = skillName
        WR_SoD_ShownSkill = skillName
        WR_SoD_ShownTick = WR_SoD_TickSeq
    end
    return shown
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
