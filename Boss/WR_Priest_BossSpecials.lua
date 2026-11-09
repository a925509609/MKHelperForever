-- ============================================================
-- WR_Priest_BossSpecials.lua
-- 牧师职业差异化 BOSS 特化逻辑
--
-- 架构：
--   1. 区分远程DPS（暗影）/治疗（戒律/神圣）
--   2. 治疗自动跳过 BOSS 特化检查（戒律/神圣天赋不处理BOSS机制）
--   3. 暗牧DPS：优先使用 WR_BossMechanics 配置中的机制，按远程DPS筛选
--   4. 补充 WR_BossMechanics 中未覆盖的暗牧特有机制
--   5. 直接用 WR_ColorFrame_Show 显示颜色
--   6. 检查函数返回 true, colorID 以支持 WR_BossRegistry 颜色覆盖
--
-- 颜色映射：
--   stop=3, target=4, defensive=8, rocketboots=108, lk_contamination=107
--
-- 关注的 BOSS 特化（暗牧DPS）：
--   1. 冰龙辛达苟萨 - 刺骨停手、冰封停手
--   2. 血议会 - 过滤无效目标、切目标
--   3. 灵魂熔炉 - 灵魂倒映停手
--   4. 巫妖王 - 污染停手
--   5. 教授普崔希德 - 软泥怪停手
--   6. 海里昂 - 低血量火箭靴
--   7. 血女王 - 鲜血镜像
--   8. 腐面/烂肠 - 突变停手
--   9. 观察者奥尔加隆 - 星尘阶段停手
--  10. 尤格萨隆 - 精神控制停手
--  11. 绿龙/红龙 - 特殊处理
--  12. 炮舰 - 火箭靴
--  13. 萨鲁法尔 - 血兽处理
-- ============================================================

if WR_PlayerClass ~= "PRIEST" then return end

if select(2, UnitClass("player")) ~= "PRIEST" then
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
local function WR_Priest_RegisterBoss(spec)
    if not spec or not spec.bossNames or not spec.checkFunction then return end
    local isSW = SW_BOSS_NAMES[spec.bossNames[1]] or false
    for _, name in ipairs(spec.bossNames) do
        BOSS_SPECIALS_BY_NAME[name] = { checkFunction = spec.checkFunction, isSW = isSW }
    end
end


local PS = {}

-- 角色常量（从 WR_BossMechanics 导入）
local ROLE_RANGED_CASTER_DPS = WR_BossMechanics.ROLE_RANGED_CASTER_DPS

-- ============================================================
-- 共享工具（来自 WR_BossUtils，避免重复定义）
-- ============================================================
local GetDebuffCount = WR_BossUtils.GetDebuffCount
local HasBuff = WR_BossUtils.HasBuff
local HasDebuff = WR_BossUtils.HasDebuff
local ColorMap = WR_BossUtils.ColorMap
local ShowColor = WR_BossUtils.ShowColor

-- ============================================================
-- 天赋判断：是否为治疗天赋（戒律/神圣）
-- ============================================================
local function IsHealerPriest()
    local discRank = select(5, GetTalentTabInfo(1))
    local holyRank = select(5, GetTalentTabInfo(2))
    local shadowRank = select(5, GetTalentTabInfo(3))
    if shadowRank and shadowRank > (discRank or 0) and shadowRank > (holyRank or 0) then
        return false
    end
    return true
end

local function ShouldSkipBossCheck()
    return IsHealerPriest()
end

-- ============================================================
-- 核心：从 WR_BossMechanics 配置中按远程DPS筛选机制
-- 返回：true, colorID 或 false
-- ============================================================
local function CheckBossMechanicsForPriest()
    if ShouldSkipBossCheck() then
        return false
    end

    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        return false
    end

    local bossData = WR_BossUtils.FindBossData(targetName)

    if not bossData or not bossData.mechanisms then
        return false
    end

    for _, mech in ipairs(bossData.mechanisms) do
        if WR_CheckRoleApplicable(mech, ROLE_RANGED_CASTER_DPS) then
            if mech.checkFunction and mech.checkFunction() then
                local colorID = ColorMap[mech.action] or mech.colorID or 3
                WR_ColorFrame_Show(colorID, mech.name or mech.description or targetName)
                return true, colorID
            end
        end
    end

    return false
end

-- ============================================================
-- 1. 冰龙辛达苟萨 - 刺骨停手 / 冰封停手
-- ============================================================
local function SindragosaCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    local HSCG = PigSet and PigSet.WQZ_HSCG or 3
    local chilledCount = GetDebuffCount("player", "寒霜刺骨")
    if HSCG ~= 7 and chilledCount >= HSCG then
        local cid = ShowColor("stop", "冰龙刺骨停手")
        return true, cid
    end

    if HasDebuff("player", "冰封") then
        local cid = ShowColor("stop", "冰龙冰封停手")
        return true, cid
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"辛达苟萨", "Sindragosa", "冰霜女王"},
    className = "PRIEST",
    action = "stop",
    description = "冰龙刺骨停手",
    checkFunction = SindragosaCheck,
})

-- ============================================================
-- 2. 血议会 - 过滤无效目标 + 切目标
-- ============================================================
local function BloodCouncilCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    local targetName = UnitName("target")

    if targetName == "动力炸弹" or targetName == "黑暗之核" then
        local cid = ShowColor("stop", "过滤无效目标")
        return true, cid
    end

    if UnitExists("boss1") and UnitExists("boss2") and UnitExists("boss3") then
        local hp1 = WR_GetUnitHP("boss1") or 100
        local hp2 = WR_GetUnitHP("boss2") or 100
        local hp3 = WR_GetUnitHP("boss3") or 100
        local currentHP = WR_GetUnitHP("target") or 100

        if currentHP > 10 and (hp1 < 5 or hp2 < 5 or hp3 < 5) then
            if currentHP > hp1 and currentHP > hp2 and currentHP > hp3 then
                local cid = ShowColor("target", "血议会切目标")
                return true, cid
            end
        end
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"血议会", "鲜血议会", "Blood Council"},
    className = "PRIEST",
    action = "target",
    description = "血议会切目标",
    checkFunction = BloodCouncilCheck,
})

-- ============================================================
-- 3. 灵魂熔炉 - 灵魂倒映停手
-- ============================================================
local function ForgeOfSoulsCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "灵魂倒映") then
        local cid = ShowColor("stop", "灵魂倒映停手")
        return true, cid
    end

    local targetName = UnitName("target")
    if targetName == "镜像" or targetName == "腐化的灵魂" then
        local cid = ShowColor("stop", "过滤镜像目标")
        return true, cid
    end

    if HasBuff("target", "灵魂倒映") then
        local cid = ShowColor("stop", "目标有灵魂倒映")
        return true, cid
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"灵魂熔炉", "锻造之魂", "Forge of Souls"},
    className = "PRIEST",
    action = "stop",
    description = "灵魂熔炉停手",
    checkFunction = ForgeOfSoulsCheck,
})

-- ============================================================
-- 4. 巫妖王 - 污染停手
-- ============================================================
local function LKCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "污染") or HasDebuff("player", "冰封王座") then
        local cid = ShowColor("lk_contamination", "巫妖王污染停手")
        return true, cid
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"巫妖王", "The Lich King", "LK"},
    className = "PRIEST",
    action = "lk_contamination",
    description = "巫妖王污染停手",
    checkFunction = LKCheck,
})

-- ============================================================
-- 5. 教授普崔希德 - 软泥怪停手
-- ============================================================
local function PutricideCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    local targetName = UnitName("target")
    if targetName == "不稳定的软泥怪" or targetName == "毒气之云" then
        local cid = ShowColor("stop", "教授软泥停手")
        return true, cid
    end

    if HasDebuff("player", "催泪毒气") then
        local cid = ShowColor("stop", "催泪毒气停手")
        return true, cid
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"普崔塞德教授", "Professor Putricide", "Putricide"},
    className = "PRIEST",
    action = "stop",
    description = "教授软泥停手",
    checkFunction = PutricideCheck,
})

-- ============================================================
-- 6. 海里昂 - 低血量火箭靴
-- ============================================================
local function HalionCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    local targetName = UnitName("target")
    if targetName == "海里昂" then
        local hp = WR_GetUnitHP("player") or 100
        if hp < 25 then
            local cid = ShowColor("rocketboots", "海里昂火箭靴")
            return true, cid
        end
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"海里昂", "Halion"},
    className = "PRIEST",
    action = "rocketboots",
    description = "海里昂火箭靴",
    checkFunction = HalionCheck,
})

-- ============================================================
-- 7. 血女王 - 鲜血镜像
-- ============================================================
local function BloodQueenCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "鲜血镜像") then
        local cid = ShowColor("stop", "血女王镜像停手")
        return true, cid
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"鲜血女王兰娜瑟尔", "Blood-Queen Lana'thel", "血女王"},
    className = "PRIEST",
    action = "stop",
    description = "血女王镜像停手",
    checkFunction = BloodQueenCheck,
})

-- ============================================================
-- 8. 腐面/烂肠 - 突变停手
-- ============================================================
local function MutantCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "突变") or HasDebuff("player", "致命突变") then
        local cid = ShowColor("stop", "腐面突变停手")
        return true, cid
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"腐面", "Festergut", "烂肠", "Rotface"},
    className = "PRIEST",
    action = "stop",
    description = "腐面突变停手",
    checkFunction = MutantCheck,
})

-- ============================================================
-- 9. 观察者奥尔加隆 - 星尘阶段停手
-- ============================================================
local function AlgalonCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "宇宙撞击") or HasDebuff("player", "坍缩之星") then
        local cid = ShowColor("stop", "奥尔加隆星尘停手")
        return true, cid
    end

    if HasBuff("target", "观察者的注意") then
        local cid = ShowColor("stop", "观察者的注意停手")
        return true, cid
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"观察者奥尔加隆", "Algalon the Observer", "奥尔加隆"},
    className = "PRIEST",
    action = "stop",
    description = "奥尔加隆星尘停手",
    checkFunction = AlgalonCheck,
})

-- ============================================================
-- 10. 尤格萨隆 - 精神控制停手
-- ============================================================
local function YoggCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "心灵牢笼") then
        local cid = ShowColor("stop", "心灵牢笼沉默停手")
        return true, cid
    end

    if HasDebuff("player", "精神控制") then
        local cid = ShowColor("stop", "尤格萨隆精神控制")
        return true, cid
    end

    local targetName = UnitName("target")
    if targetName == "尤格萨隆的触手" then
        local cid = ShowColor("stop", "过滤触手目标")
        return true, cid
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"尤格萨隆", "Yogg-Saron", "Yogg"},
    className = "PRIEST",
    action = "stop",
    description = "尤格萨隆精神控制",
    checkFunction = YoggCheck,
})

-- ============================================================
-- 11. 绿龙/红龙 - 特殊处理
-- ============================================================
local function DragonCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "燃烧之血") then
        local cid = ShowColor("stop", "燃烧之血停手省蓝")
        return true, cid
    end

    if HasDebuff("player", "沉睡") then
        local cid = ShowColor("stop", "巨龙沉睡停手")
        return true, cid
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"翡翠巨龙", "绯红巨龙守护者", "Valithria"},
    className = "PRIEST",
    action = "stop",
    description = "巨龙特殊处理",
    checkFunction = DragonCheck,
})

-- ============================================================
-- 12. 炮舰 - 火箭靴
-- ============================================================
local function GunshipCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    local targetName = UnitName("target")
    if targetName == "炮舰" then
        local hp = WR_GetUnitHP("player") or 100
        if hp < 30 then
            local cid = ShowColor("rocketboots", "炮舰火箭靴")
            return true, cid
        end
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"炮舰", "天界飞船", "Gunship"},
    className = "PRIEST",
    action = "rocketboots",
    description = "炮舰火箭靴",
    checkFunction = GunshipCheck,
})

-- ============================================================
-- 13. 萨鲁法尔 - 血兽处理
-- ============================================================
local function SaurfangCheck()
    if ShouldSkipBossCheck() then return false end

    local triggered, overrideColor = CheckBossMechanicsForPriest()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Priest_RegisterBoss({
    bossNames = {"死亡使者萨鲁法尔", "Deathbringer Saurfang", "萨鲁法尔"},
    className = "PRIEST",
    action = "defensive",
    description = "萨鲁法尔血兽处理",
    checkFunction = SaurfangCheck,
})


-- ============================================================
-- ============================================================
-- 太阳井(1-6号) + 祖阿曼(1-6号) 职业特化入口（职业专属增强版）
-- 【迁移说明】以下职业专属增强的"规范/数据驱动版本"现已位于 AI_RuleEngine
--   （按 BOSS属性标签 × 职业能力映射，见 AI_BossTaxonomy + AI_ClassRegistry）。
--   当 PigSet.BOSS_AI_EXTENSIONS_ENABLED 开启时由新系统接管；
--   此处为默认开启的兼容层，请勿删除，以免回退默认行为。
--   机制由 WR_BossMechanics + BossAI 按角色通用覆盖；此处叠加职业工具箱增强
-- ============================================================

local function PriestKLGSCheck()
    if HasDebuff("player", "腐蚀") or HasDebuff("player", "燃烧") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"卡雷苟斯", "Kalecgos", "太阳井1号", "腐蚀者萨索瓦尔", "Sathrovarr"},
    className = "PRIEST",
    action = "stop",
    description = "卡雷苟斯-驱散魔法解腐蚀燃烧 / 通用兜底",
    checkFunction = PriestKLGSCheck,
})

local function PriestBLTLCheck()
    if HasDebuff("player", "燃烧之血") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"布鲁塔卢斯", "Brutallus", "太阳井2号"},
    className = "PRIEST",
    action = "stop",
    description = "布鲁塔卢斯-驱散魔法解燃烧 / 通用兜底",
    checkFunction = PriestBLTLCheck,
})

local function PriestFMSCheck()
    if HasDebuff("player", "腐蚀气体") or HasDebuff("player", "腐蚀吐息") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"菲米丝", "Felmyst", "太阳井3号"},
    className = "PRIEST",
    action = "stop",
    description = "菲米丝-驱散魔法解腐蚀吐息 / 通用兜底",
    checkFunction = PriestFMSCheck,
})

local function PriestTWINSCheck()
    if HasDebuff("player", "暗影之痛") or HasDebuff("player", "火焰之痛") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"艾瑞达双子", "Eredar Twins", "Alythess", "Brannjar", "太阳井4号"},
    className = "PRIEST",
    action = "stop",
    description = "艾瑞达双子-驱散魔法解双子之痛 / 通用兜底",
    checkFunction = PriestTWINSCheck,
})

local function PriestMURUCheck()
    if HasDebuff("player", "熵") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"穆鲁", "M'uru", "Muru", "太阳井5号"},
    className = "PRIEST",
    action = "stop",
    description = "穆鲁-驱散魔法解熵 / 通用兜底",
    checkFunction = PriestMURUCheck,
})

local function PriestKJCheck()
    if HasDebuff("player", "暗影之矛") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"基尔加丹", "Kil'jaeden", "Kiljaeden", "太阳井6号"},
    className = "PRIEST",
    action = "stop",
    description = "基尔加丹-驱散魔法解暗影之矛 / 通用兜底",
    checkFunction = PriestKJCheck,
})

local function PriestYWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"鹰王", "Akil'zon", "Akilzon", "艾基利松", "祖阿曼1号"},
    className = "PRIEST",
    action = "stop",
    description = "鹰王-通用机制库(纯透传)",
    checkFunction = PriestYWCheck,
})

local function PriestXWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"熊王", "Nalorakk", "纳洛拉克", "祖阿曼2号"},
    className = "PRIEST",
    action = "stop",
    description = "熊王-通用机制库(纯透传)",
    checkFunction = PriestXWCheck,
})

local function PriestLHYCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"龙鹰王", "Jan'alai", "Janalai", "贾恩阿拉伊", "祖阿曼3号"},
    className = "PRIEST",
    action = "stop",
    description = "龙鹰王-通用机制库(纯透传)",
    checkFunction = PriestLHYCheck,
})

local function PriestBWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"豹王", "Halazzi", "哈拉兹", "祖阿曼4号"},
    className = "PRIEST",
    action = "stop",
    description = "豹王-通用机制库(纯透传)",
    checkFunction = PriestBWCheck,
})

local function PriestYSLZCheck()
    if HasDebuff("player", "妖术") or HasDebuff("player", "变青蛙") or HasDebuff("player", "灵魂吸取") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"妖术领主", "Hex Lord Malacrass", "HexLord", "玛拉卡斯", "祖阿曼5号"},
    className = "PRIEST",
    action = "stop",
    description = "妖术领主-驱散魔法解妖术/灵魂吸取 / 通用兜底",
    checkFunction = PriestYSLZCheck,
})

local function PriestZJCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPriest()
end

WR_Priest_RegisterBoss({
    bossNames = {"祖金", "Zul'jin", "祖阿曼6号"},
    className = "PRIEST",
    action = "stop",
    description = "祖金-通用机制库(纯透传)",
    checkFunction = PriestZJCheck,
})

-- ============================================================
-- ★ 统一入口（由 MainLoop 直接调用，无注册表中间件）
--   按当前目标名查本地派发表；命中则调用对应检查函数
--   太阳井(1-6号) 默认不触发（SW_BOSS_SPECIALS_OFF 守卫，用户只需输出循环）
-- ============================================================
function WR_Priest_BossSpecials()
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

