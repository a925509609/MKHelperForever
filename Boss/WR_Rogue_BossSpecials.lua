-- ============================================================
-- WR_Rogue_BossSpecials.lua
-- 盗贼职业差异化 BOSS 特化逻辑
--
-- 定位：近战DPS（无坦克/治疗）
-- 数据来源：WR_BossMechanics 配置（按 ROLE_MELEE_DPS 筛选）
-- 显示方式：WR_ColorFrame_Show 直接显示颜色
--
-- 核心机制（近战DPS过滤）：
--   1. 冰龙辛达苟萨 - 寒霜刺骨停手 / 冰封停手
--   2. 血议会 - 过滤无效目标（动力炸弹/黑暗之核）
--   3. 灵魂熔炉 - 灵魂倒映停手（含镜像过滤）
--   4. 巫妖王 - 污染停手（lk_contamination）
--   5. 萨鲁法尔 - 保护之手提示取消（defensive）
--   6. 海里昂 - 低血量火箭靴（rocketboots）
--   7. 教授普崔希德 - 软泥怪过滤 / 催泪毒气停手
--   8. 观察者奥尔加隆 - 宇宙撞击/坍缩之星停手
--   9. 尤格萨隆 - 精神控制/心灵牢笼停手
--  10. 血女王 - 鲜血镜像停手
--  11. 腐面/烂肠 - 突变停手
--  12. 炮舰 - 火箭靴
--  13. 翡翠巨龙/绯红巨龙守护者 - 沉睡/燃烧之血停手
-- ============================================================

if WR_PlayerClass ~= "ROGUE" then return end

if select(2, UnitClass("player")) ~= "ROGUE" then
    return
end
-- ============================================================
-- ★ 本地 BOSS 特化派发表（替代已删除的 WR_BossRegistry 注册表中间件）
--   每个 BOSS 名 → 对应检查函数，MainLoop 直接按目标名查表调用
-- ============================================================
local BOSS_SPECIALS_BY_NAME = {}
local SW_BOSS_NAMES = {
    ["卡雷苟斯"] = true, ["布鲁塔卢斯"] = true, ["菲米丝"] = true,
    ["艾瑞达双子"] = true, ["穆鲁"] = true, ["基尔加丹"] = true,
}
local function WR_Rogue_RegisterBoss(spec)
    if not spec or not spec.bossNames or not spec.checkFunction then return end
    local isSW = SW_BOSS_NAMES[spec.bossNames[1]] or false
    for _, name in ipairs(spec.bossNames) do
        BOSS_SPECIALS_BY_NAME[name] = { checkFunction = spec.checkFunction, isSW = isSW }
    end
end


-- ============================================================
-- ★ 角色类型锁定：盗贼恒为近战DPS
-- ============================================================
local PLAYER_ROLE = "melee_dps"
local ROLE_MELEE_DPS = "melee_dps"

-- ============================================================
-- ★ 共享工具（来自 WR_BossUtils，避免重复定义）
-- ============================================================
local GetDebuffCount = WR_BossUtils.GetDebuffCount
local HasBuff = WR_BossUtils.HasBuff
local HasDebuff = WR_BossUtils.HasDebuff
local ACTION_TO_COLOR = WR_BossUtils.ColorMap
local function GetColorID(action)
    return ACTION_TO_COLOR[action] or 3
end

-- ============================================================
-- ★ 机制检查核心：从 WR_BossMechanics 按角色类型筛选
-- ============================================================
local function CheckBossMechanicsForRogue()
    local bossData = WR_FindCurrentBossMechanics and WR_FindCurrentBossMechanics()
    if not bossData or not bossData.mechanisms then
        return nil
    end

    for _, mech in ipairs(bossData.mechanisms) do
        if mech.applicableRoles and mech.applicableRoles[ROLE_MELEE_DPS] then
            if mech.checkFunction and mech.checkFunction() then
                return mech
            end
        end
    end

    return nil
end

-- ============================================================
-- ★ 颜色显示入口（供主循环调用）
--   命中机制则返回 true 并显示对应颜色，否则返回 nil
-- ============================================================
function WR_Rogue_BossSpecials_Update()
    local mech = CheckBossMechanicsForRogue()
    if not mech then
        return nil
    end

    local colorID = GetColorID(mech.action)
    local text = mech.description or mech.name or mech.action
    return WR_ColorFrame_Show(colorID, text)
end

-- ============================================================
-- ★ 各 BOSS 近战DPS 特化封装（直接调用 WR_BossMechanics 配置）
--   说明：以下 check 函数均直接复用 WR_BossMechanics 的机制定义
--        通过 WR_ColorFrame_Show 输出颜色，返回 true 表示已触发
-- ============================================================

-- 1. 冰龙辛达苟萨：寒霜刺骨停手 / 冰封停手
local function SindragosaCheck()
    local HSCG = PigSet and PigSet.WQZ_HSCG or 5

    -- 寒霜刺骨：按配置阈值停手
    local chilledCount = GetDebuffCount("player", "寒霜刺骨")
    if chilledCount and chilledCount >= HSCG and HSCG ~= 7 then
        return WR_ColorFrame_Show(GetColorID("stop"), "冰龙刺骨停手")
    end

    -- 冰封：被冰封时立即停手
    if HasDebuff("player", "冰封") then
        return WR_ColorFrame_Show(GetColorID("stop"), "冰龙冰封停手")
    end

    return false
end

-- 2. 血议会：过滤无效目标 / 低血量切目标
local function BloodCouncilCheck()
    local targetName = UnitName("target")

    -- 无效目标过滤：动力炸弹 / 黑暗之核 不要攻击
    if targetName == "动力炸弹" or targetName == "黑暗之核" then
        return WR_ColorFrame_Show(GetColorID("stop"), "血议会过滤无效目标")
    end

    -- 血量严重不均衡时提示切目标
    if UnitExists("boss1") and UnitExists("boss2") and UnitExists("boss3") then
        local hp1 = WR_GetUnitHP("boss1") or 100
        local hp2 = WR_GetUnitHP("boss2") or 100
        local hp3 = WR_GetUnitHP("boss3") or 100
        local cur = WR_GetUnitHP("target") or 100
        if cur > 10 and (hp1 < 5 or hp2 < 5 or hp3 < 5) then
            if cur > hp1 and cur > hp2 and cur > hp3 then
                return WR_ColorFrame_Show(GetColorID("target"), "血议会切目标")
            end
        end
    end

    return false
end

-- 3. 灵魂熔炉：灵魂倒映停手（含镜像/腐化之魂过滤）
local function ForgeOfSoulsCheck()
    if HasDebuff("player", "灵魂倒映") then
        return WR_ColorFrame_Show(GetColorID("stop"), "灵魂倒映停手")
    end

    local targetName = UnitName("target")
    if targetName == "镜像" or targetName == "腐化的灵魂" then
        return WR_ColorFrame_Show(GetColorID("stop"), "灵魂熔炉过滤镜像")
    end

    if HasBuff("target", "灵魂倒映") then
        return WR_ColorFrame_Show(GetColorID("stop"), "目标有灵魂倒映")
    end

    return false
end

-- 4. 巫妖王：污染停手
local function LKCheck()
    if HasDebuff("player", "污染") or HasDebuff("player", "冰封王座") then
        return WR_ColorFrame_Show(GetColorID("lk_contamination"), "巫妖王污染停手")
    end
    return false
end

-- 5. 萨鲁法尔：保护之手提示取消
local function SaurfangCheck()
    if HasBuff("player", "保护之手") then
        return WR_ColorFrame_Show(GetColorID("defensive"), "萨鲁法尔取消保护之手")
    end
    return false
end

-- 6. 海里昂：低血量火箭靴
local function HalionCheck()
    if UnitName("target") == "海里昂" then
        local hp = WR_GetUnitHP("player") or 100
        if hp < 30 then
            return WR_ColorFrame_Show(GetColorID("rocketboots"), "海里昂火箭靴")
        end
    end
    return false
end

-- 7. 教授普崔希德：软泥怪过滤 / 催泪毒气停手
local function PutricideCheck()
    local targetName = UnitName("target")
    if targetName == "不稳定的软泥怪" or targetName == "毒气之云" then
        return WR_ColorFrame_Show(GetColorID("stop"), "教授过滤软泥怪")
    end

    if HasDebuff("player", "催泪毒气") then
        return WR_ColorFrame_Show(GetColorID("stop"), "教授催泪毒气停手")
    end

    return false
end

-- 8. 观察者奥尔加隆：宇宙撞击 / 坍缩之星停手
local function AlgalonCheck()
    if HasDebuff("player", "宇宙撞击") or HasDebuff("player", "坍缩之星") then
        return WR_ColorFrame_Show(GetColorID("stop"), "奥尔加隆停手")
    end
    return false
end

-- 9. 尤格萨隆：精神控制 / 心灵牢笼停手
local function YoggCheck()
    if HasDebuff("player", "精神控制") or HasDebuff("player", "心灵牢笼") then
        return WR_ColorFrame_Show(GetColorID("stop"), "尤格萨隆精神控制停手")
    end

    if UnitName("target") == "尤格萨隆的触手" then
        return WR_ColorFrame_Show(GetColorID("stop"), "尤格萨隆过滤触手")
    end

    return false
end

-- 10. 血女王：鲜血镜像停手
local function BloodQueenCheck()
    if HasDebuff("player", "鲜血镜像") then
        return WR_ColorFrame_Show(GetColorID("stop"), "血女王鲜血镜像停手")
    end
    return false
end

-- 11. 腐面/烂肠：突变停手
local function MutantCheck()
    if HasDebuff("player", "突变") or HasDebuff("player", "致命突变") then
        return WR_ColorFrame_Show(GetColorID("stop"), "腐面突变停手")
    end
    return false
end

-- 12. 炮舰：火箭靴
local function GunshipCheck()
    if UnitName("target") == "炮舰" then
        local hp = WR_GetUnitHP("player") or 100
        if hp < 30 then
            return WR_ColorFrame_Show(GetColorID("rocketboots"), "炮舰火箭靴")
        end
    end
    return false
end

-- 13. 翡翠巨龙 / 绯红巨龙守护者：沉睡 / 燃烧之血停手
local function DragonCheck()
    if HasDebuff("player", "沉睡") or HasDebuff("player", "燃烧之血") then
        return WR_ColorFrame_Show(GetColorID("stop"), "巨龙特殊停手")
    end
    return false
end

-- ============================================================
-- ★ BOSS 特化注册（本地派发表，由主循环统一调度）
--   所有 BOSS 均声明 className="ROGUE"，action 对应颜色映射
-- ============================================================
local BOSS_SPECIAL_DEFS = {
    {
        bossNames = { "辛达苟萨", "Sindragosa", "冰霜女王" },
        action = "stop",
        description = "冰龙刺骨/冰封停手",
        checkFunction = SindragosaCheck,
    },
    {
        bossNames = { "血议会", "鲜血议会", "Blood Council", "塔达拉姆王子", "瓦拉纳王子", "凯雷塞斯王子" },
        action = "target",
        description = "血议会过滤无效目标/切目标",
        checkFunction = BloodCouncilCheck,
    },
    {
        bossNames = { "灵魂熔炉", "锻造之魂", "Forge of Souls", "镜像", "腐化的灵魂" },
        action = "stop",
        description = "灵魂倒映停手",
        checkFunction = ForgeOfSoulsCheck,
    },
    {
        bossNames = { "巫妖王", "The Lich King", "LK", "阿尔萨斯" },
        action = "lk_contamination",
        description = "巫妖王污染停手",
        checkFunction = LKCheck,
    },
    {
        bossNames = { "死亡使者萨鲁法尔", "Deathbringer Saurfang", "萨鲁法尔", "Saurfang" },
        action = "defensive",
        description = "萨鲁法尔保护之手提示取消",
        checkFunction = SaurfangCheck,
    },
    {
        bossNames = { "海里昂", "Halion" },
        action = "rocketboots",
        description = "海里昂火箭靴",
        checkFunction = HalionCheck,
    },
    {
        bossNames = { "普崔塞德教授", "Professor Putricide", "Putricide", "不稳定的软泥怪", "毒气之云" },
        action = "stop",
        description = "教授软泥/毒气停手",
        checkFunction = PutricideCheck,
    },
    {
        bossNames = { "观察者奥尔加隆", "Algalon the Observer", "奥尔加隆", "Algalon" },
        action = "stop",
        description = "奥尔加隆星尘停手",
        checkFunction = AlgalonCheck,
    },
    {
        bossNames = { "尤格萨隆", "Yogg-Saron", "Yogg", "尤格萨隆的触手" },
        action = "stop",
        description = "尤格萨隆精神控制停手",
        checkFunction = YoggCheck,
    },
    {
        bossNames = { "鲜血女王兰娜瑟尔", "Blood-Queen Lana'thel", "血女王" },
        action = "stop",
        description = "血女王鲜血镜像停手",
        checkFunction = BloodQueenCheck,
    },
    {
        bossNames = { "腐面", "Festergut", "烂肠", "Rotface" },
        action = "stop",
        description = "腐面突变停手",
        checkFunction = MutantCheck,
    },
    {
        bossNames = { "炮舰", "天界飞船", "Gunship" },
        action = "rocketboots",
        description = "炮舰火箭靴",
        checkFunction = GunshipCheck,
    },
    {
        bossNames = { "翡翠巨龙", "绯红巨龙守护者", "Valithria" },
        action = "stop",
        description = "巨龙沉睡/燃烧之血停手",
        checkFunction = DragonCheck,
    },
}

for _, def in ipairs(BOSS_SPECIAL_DEFS) do
    WR_Rogue_RegisterBoss({
        bossNames = def.bossNames,
        className = "ROGUE",
        action = def.action,
        description = def.description,
        checkFunction = def.checkFunction,
    })
end

-- ============================================================
-- ★ 导出入口
-- ============================================================
_G.WR_Rogue_BossSpecials_Update = WR_Rogue_BossSpecials_Update
_G.WR_Rogue_BossSpecials = {
    Role = PLAYER_ROLE,
    ColorMap = ACTION_TO_COLOR,
    CheckMechanics = CheckBossMechanicsForRogue,
}


-- ============================================================
-- ============================================================
-- 太阳井(1-6号) + 祖阿曼(1-6号) 职业特化入口（职业专属增强版）
-- 【迁移说明】以下职业专属增强的"规范/数据驱动版本"现已位于 AI_RuleEngine
--   （按 BOSS属性标签 × 职业能力映射，见 AI_BossTaxonomy + AI_ClassRegistry）。
--   当 PigSet.BOSS_AI_EXTENSIONS_ENABLED 开启时由新系统接管；
--   此处为默认开启的兼容层，请勿删除，以免回退默认行为。
--   机制由 WR_BossMechanics + BossAI 按角色通用覆盖；此处叠加职业工具箱增强
-- ============================================================

local function RogueKLGSCheck()
    if HasDebuff("player", "腐蚀") or HasDebuff("player", "燃烧") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"卡雷苟斯", "Kalecgos", "太阳井1号", "腐蚀者萨索瓦尔", "Sathrovarr"},
    className = "ROGUE",
    action = "stop",
    description = "卡雷苟斯-斗篷解腐蚀/燃烧 / 通用兜底",
    checkFunction = RogueKLGSCheck,
})

local function RogueBLTLCheck()
    if HasDebuff("player", "燃烧之血") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    if HasDebuff("player", "陨石打击") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"布鲁塔卢斯", "Brutallus", "太阳井2号"},
    className = "ROGUE",
    action = "stop",
    description = "布鲁塔卢斯-斗篷解燃烧之血 / 闪避/佯攻减伤 / 通用兜底",
    checkFunction = RogueBLTLCheck,
})

local function RogueFMSCheck()
    if HasDebuff("player", "腐蚀气体") or HasDebuff("player", "腐蚀吐息") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"菲米丝", "Felmyst", "太阳井3号"},
    className = "ROGUE",
    action = "stop",
    description = "菲米丝-斗篷解腐蚀吐息 / 通用兜底",
    checkFunction = RogueFMSCheck,
})

local function RogueTWINSCheck()
    if HasDebuff("player", "暗影之痛") or HasDebuff("player", "火焰之痛") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"艾瑞达双子", "Eredar Twins", "Alythess", "Brannjar", "太阳井4号"},
    className = "ROGUE",
    action = "stop",
    description = "艾瑞达双子-斗篷解双子之痛 / 通用兜底",
    checkFunction = RogueTWINSCheck,
})

local function RogueMURUCheck()
    if HasDebuff("player", "熵") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"穆鲁", "M'uru", "Muru", "太阳井5号"},
    className = "ROGUE",
    action = "stop",
    description = "穆鲁-斗篷解熵 / 通用兜底",
    checkFunction = RogueMURUCheck,
})

local function RogueKJCheck()
    if HasDebuff("player", "暗影之矛") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"基尔加丹", "Kil'jaeden", "Kiljaeden", "太阳井6号"},
    className = "ROGUE",
    action = "stop",
    description = "基尔加丹-斗篷解暗影之矛 / 通用兜底",
    checkFunction = RogueKJCheck,
})

local function RogueYWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"鹰王", "Akil'zon", "Akilzon", "艾基利松", "祖阿曼1号"},
    className = "ROGUE",
    action = "stop",
    description = "鹰王-通用机制库(纯透传)",
    checkFunction = RogueYWCheck,
})

local function RogueXWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"熊王", "Nalorakk", "纳洛拉克", "祖阿曼2号"},
    className = "ROGUE",
    action = "stop",
    description = "熊王-通用机制库(纯透传)",
    checkFunction = RogueXWCheck,
})

local function RogueLHYCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"龙鹰王", "Jan'alai", "Janalai", "贾恩阿拉伊", "祖阿曼3号"},
    className = "ROGUE",
    action = "stop",
    description = "龙鹰王-通用机制库(纯透传)",
    checkFunction = RogueLHYCheck,
})

local function RogueBWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"豹王", "Halazzi", "哈拉兹", "祖阿曼4号"},
    className = "ROGUE",
    action = "stop",
    description = "豹王-通用机制库(纯透传)",
    checkFunction = RogueBWCheck,
})

local function RogueYSLZCheck()
    if HasDebuff("player", "妖术") or HasDebuff("player", "变青蛙") or HasDebuff("player", "灵魂吸取") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"妖术领主", "Hex Lord Malacrass", "HexLord", "玛拉卡斯", "祖阿曼5号"},
    className = "ROGUE",
    action = "stop",
    description = "妖术领主-斗篷解妖术/灵魂吸取 / 通用兜底",
    checkFunction = RogueYSLZCheck,
})

local function RogueZJCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForRogue()
end

WR_Rogue_RegisterBoss({
    bossNames = {"祖金", "Zul'jin", "祖阿曼6号"},
    className = "ROGUE",
    action = "stop",
    description = "祖金-通用机制库(纯透传)",
    checkFunction = RogueZJCheck,
})

-- ============================================================
-- ★ 统一入口（由 MainLoop 直接调用，无注册表中间件）
--   按当前目标名查本地派发表；命中则调用对应检查函数
--   太阳井(1-6号) 默认不触发（SW_BOSS_SPECIALS_OFF 守卫，用户只需输出循环）
-- ============================================================
function WR_Rogue_BossSpecials()
    local targetName = UnitName("target")
    if not targetName then return false end
    local entry = BOSS_SPECIALS_BY_NAME[targetName]
    if entry then
        if entry.isSW and PigSet and PigSet.SW_BOSS_SPECIALS_OFF ~= false then
            return false
        end
        local ok, trig = pcall(entry.checkFunction)
        if ok and trig then
            return true
        end
    end
    return false
end

