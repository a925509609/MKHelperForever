-- ============================================================
-- WR_DeathKnight_BossSpecials.lua
-- 死亡骑士职业差异化 BOSS 特化逻辑
--
-- 架构设计：
--   1. 区分坦克（鲜血）/DPS（冰霜/邪恶）角色类型
--   2. 使用 WR_BossMechanics 配置中的机制，按角色类型筛选
--   3. 直接用 WR_ColorFrame_Show 显示颜色
--
-- 颜色映射：stop=3, target=4, defensive=8, rocketboots=108, lk_contamination=107
--
-- 坦克（鲜血）特化：
--   - 冰龙：反魔法护盾+冰冷吐息 → 吸血鬼之血/冰封之韧
--   - 血议会：自动切目标
--
-- DPS（冰霜/邪恶）特化：
--   - 冰龙：刺骨停手
--   - 血议会：过滤无效目标
--   - 灵魂熔炉：灵魂倒映停手
-- ============================================================

if WR_PlayerClass ~= "DEATHKNIGHT" then return end

if select(2, UnitClass("player")) ~= "DEATHKNIGHT" then
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
local function WR_DeathKnight_RegisterBoss(spec)
    if not spec or not spec.bossNames or not spec.checkFunction then return end
    local isSW = SW_BOSS_NAMES[spec.bossNames[1]] or false
    for _, name in ipairs(spec.bossNames) do
        BOSS_SPECIALS_BY_NAME[name] = { checkFunction = spec.checkFunction, isSW = isSW }
    end
end

local DK = {}

-- ============================================================
-- ★ 共享工具（来自 WR_BossUtils，避免重复定义）
-- ============================================================
local GetDebuffCount = WR_BossUtils.GetDebuffCount
local HasBuff = WR_BossUtils.HasBuff
local HasDebuff = WR_BossUtils.HasDebuff
local GetPlayerHP = WR_BossUtils.GetPlayerHP
local ColorMap = WR_BossUtils.ColorMap

-- ============================================================
-- ★ 角色类型判断
-- ============================================================
local ROLE_TANK = WR_BossMechanics.ROLE_TANK
local ROLE_MELEE_DPS = WR_BossMechanics.ROLE_MELEE_DPS
local ROLE_RANGED_DPS = WR_BossMechanics.ROLE_RANGED_DPS

local function GetDKRole()
    return WR_GetPlayerRole and WR_GetPlayerRole() or ROLE_MELEE_DPS
end

local function IsDKTank()
    return GetDKRole() == ROLE_TANK
end

local function IsDKDPS()
    local role = GetDKRole()
    return role == ROLE_MELEE_DPS or role == ROLE_RANGED_DPS
end

-- ============================================================
-- ★ 坦克专属检查（鲜血）
-- ============================================================

local function SindragosaTankCheck()
    local targetName = UnitName("target")
    if targetName ~= "辛达苟萨" and targetName ~= "Sindragosa" then
        return false
    end

    if HasDebuff("player", "反魔法护盾") then
        return true, "defensive"
    end

    if HasDebuff("player", "冰封") then
        return true, "defensive"
    end

    local chilledCount = GetDebuffCount("player", "寒霜刺骨")
    if chilledCount >= 5 then
        return true, "defensive"
    end

    return false
end

local function BloodCouncilTankCheck()
    local targetName = UnitName("target")

    if targetName == "动力炸弹" or targetName == "黑暗之核" then
        return true, "stop"
    end

    return false
end

-- ============================================================
-- ★ DPS 专属检查（冰霜/邪恶）
-- ============================================================

local function SindragosaDPSCheck()
    local targetName = UnitName("target")
    if targetName ~= "辛达苟萨" and targetName ~= "Sindragosa" then
        return false
    end

    local chilledCount = GetDebuffCount("player", "寒霜刺骨")
    local threshold = PigSet and PigSet.WQZ_HSCG or 5
    if chilledCount >= threshold then
        return true, "stop"
    end

    if HasDebuff("player", "冰封") then
        return true, "stop"
    end

    return false
end

local function BloodCouncilDPSCheck()
    local targetName = UnitName("target")

    if targetName == "动力炸弹" or targetName == "黑暗之核" then
        return true, "stop"
    end

    if UnitExists("boss1") and UnitExists("boss2") and UnitExists("boss3") then
        local hp1 = WR_GetUnitHP("boss1") or 100
        local hp2 = WR_GetUnitHP("boss2") or 100
        local hp3 = WR_GetUnitHP("boss3") or 100
        local currentHP = WR_GetUnitHP("target") or 100

        if currentHP > 10 and (hp1 < 5 or hp2 < 5 or hp3 < 5) then
            if currentHP > hp1 and currentHP > hp2 and currentHP > hp3 then
                return true, "target"
            end
        end
    end

    return false
end

local function ForgeOfSoulsDPSCheck()
    if HasDebuff("player", "灵魂倒映") then
        return true, "stop"
    end

    local targetName = UnitName("target")
    if targetName == "镜像" or targetName == "腐化的灵魂" then
        return true, "stop"
    end

    if HasBuff("target", "灵魂倒映") or HasBuff("target", "腐蚀之魂") then
        return true, "stop"
    end

    return false
end

-- ============================================================
-- ★ 通用 BOSS 检查（坦克 + DPS 共用）
-- ============================================================

local function LKCheck()
    if HasDebuff("player", "污染") or HasDebuff("player", "冰封王座") then
        return true, "lk_contamination"
    end

    local hp = GetPlayerHP()
    if hp < 15 and UnitName("target") == "巫妖王" then
        return true, "stop"
    end

    return false
end

local function RocketBootCheck()
    local targetName = UnitName("target")
    if targetName == "炮舰" or targetName == "天界飞船" or
       targetName == "海里昂" or targetName == "Halion" then
        local hp = GetPlayerHP()
        if hp < 30 then
            return true, "rocketboots"
        end
    end
    return false
end

local function SaurfangCheck()
    if HasBuff("player", "保护之手") then
        return true, "defensive"
    end
    return false
end

local function PutricideCheck()
    local targetName = UnitName("target")
    if targetName == "不稳定的软泥怪" or targetName == "毒气之云" then
        return true, "stop"
    end

    if HasDebuff("player", "催泪毒气") or HasDebuff("player", "腐蚀黏液") then
        return true, "stop"
    end

    return false
end

local function BloodQueenCheck()
    if HasDebuff("player", "鲜血镜像") then
        return true, "stop"
    end
    return false
end

local function MutantCheck()
    if HasDebuff("player", "突变") or HasDebuff("player", "致命突变") then
        return true, "stop"
    end
    return false
end

local function AlgalonCheck()
    if HasDebuff("player", "宇宙撞击") or HasDebuff("player", "坍缩之星") then
        return true, "stop"
    end

    if HasBuff("target", "观察者的注意") then
        return true, "stop"
    end

    return false
end

local function YoggCheck()
    if HasDebuff("player", "精神控制") or HasDebuff("player", "心灵牢笼") then
        return true, "stop"
    end

    local targetName = UnitName("target")
    if targetName == "尤格萨隆的触手" then
        return true, "stop"
    end

    return false
end

local function DragonCheck()
    if HasDebuff("player", "沉睡") or HasDebuff("player", "燃烧之血") then
        return true, "stop"
    end
    return false
end

-- ============================================================
-- ★ 主检查入口
--   整合 WR_BossMechanics 通用机制 + DK 专属差异化逻辑
-- ============================================================
function WR_DeathKnightBossCheck()
    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        return false
    end

    -- 1. 优先检查 WR_BossMechanics 中的通用机制（按角色类型筛选）
    local bossData = WR_FindCurrentBossMechanics and WR_FindCurrentBossMechanics()
    if bossData and bossData.mechanisms then
        local role = GetDKRole()
        for _, mechanism in ipairs(bossData.mechanisms) do
            if mechanism.applicableRoles and mechanism.applicableRoles[role] then
                if mechanism.checkFunction and mechanism.checkFunction() then
                    local colorID = ColorMap[mechanism.action] or mechanism.colorID or 1
                    WR_ColorFrame_Show(colorID, mechanism.description or mechanism.name)
                    return true
                end
            end
        end
    end

    -- 2. DK 专属差异化检查
    local isTank = IsDKTank()
    local isDPS = IsDKDPS()

    -- 坦克专属
    if isTank then
        local triggered, action = SindragosaTankCheck()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.defensive
            WR_ColorFrame_Show(colorID, "冰龙坦克防御(吸血鬼之血/冰封之韧)")
            return true
        end

        triggered, action = BloodCouncilTankCheck()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.stop
            WR_ColorFrame_Show(colorID, "血议会坦克过滤")
            return true
        end
    end

    -- DPS 专属
    if isDPS then
        local triggered, action = SindragosaDPSCheck()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.stop
            WR_ColorFrame_Show(colorID, "冰龙DPS刺骨停手")
            return true
        end

        triggered, action = BloodCouncilDPSCheck()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.target
            WR_ColorFrame_Show(colorID, "血议会DPS切目标")
            return true
        end

        triggered, action = ForgeOfSoulsDPSCheck()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.stop
            WR_ColorFrame_Show(colorID, "灵魂熔炉DPS停手")
            return true
        end
    end

    -- 3. 通用检查（所有角色共用）
    local sharedChecks = {
        { LKCheck, "巫妖王污染停手" },
        { RocketBootCheck, "火箭靴逃生" },
        { SaurfangCheck, "萨鲁法尔血兽" },
        { PutricideCheck, "教授软泥停手" },
        { BloodQueenCheck, "血女王镜像停手" },
        { MutantCheck, "腐面突变停手" },
        { AlgalonCheck, "奥尔加隆星尘停手" },
        { YoggCheck, "尤格萨隆精神控制" },
        { DragonCheck, "巨龙特殊处理" },
    }

    for _, entry in ipairs(sharedChecks) do
        local fn, desc = unpack(entry)
        local triggered, action = fn()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.stop
            WR_ColorFrame_Show(colorID, desc)
            return true
        end
    end

    return false
end

-- ============================================================
-- ★ BOSS 特化注册（本地派发表，无需 WR_BossRegistry 中间件）
--   MainLoop 的 BOSS_SPECIALS_DISPATCH 按职业直调 WR_DeathKnight_BossSpecials() 入口
-- ============================================================
WR_DeathKnight_RegisterBoss({
    bossNames = {
        "辛达苟萨", "Sindragosa", "冰霜女王",
        "血议会", "鲜血议会", "Blood Council",
        "灵魂熔炉", "锻造之魂", "Forge of Souls",
        "巫妖王", "The Lich King", "LK",
        "炮舰", "天界飞船", "Gunship",
        "海里昂", "Halion",
        "死亡使者萨鲁法尔", "Deathbringer Saurfang", "萨鲁法尔",
        "普崔塞德教授", "Professor Putricide",
        "鲜血女王兰娜瑟尔", "血女王",
        "腐面", "Festergut", "烂肠", "Rotface",
        "观察者奥尔加隆", "奥尔加隆", "Algalon",
        "尤格萨隆", "Yogg-Saron",
        "翡翠巨龙", "绯红巨龙守护者", "Valithria",
        "镜像", "腐化的灵魂",
        "动力炸弹", "黑暗之核",
        "不稳定的软泥怪", "毒气之云",
    },
    className = "DEATHKNIGHT",
    talent = nil,
    action = "idle",
    description = "DK 差异化 BOSS 特化",
    checkFunction = function()
        return WR_DeathKnightBossCheck()
    end,
})


-- ============================================================
-- 通用职业机制分发（纯透传）
--   复用全局 WR_CheckBossMechanics() 检查当前 Boss 全部机制，
--   由机制自身 checkFunction 决定触发（多形态职业不硬编码角色）
-- ============================================================
local function CheckBossMechanicsForDeathknight()
    local mechanism = WR_CheckBossMechanics()
    if mechanism then
        local colorID = WR_BossUtils.ColorMap[mechanism.action] or mechanism.colorID or 1
        local desc = mechanism.description or mechanism.name or UnitName("target") or ""
        WR_ColorFrame_Show(colorID, desc)
        return true, colorID
    end
    return false
end

-- ============================================================
-- ============================================================
-- 太阳井(1-6号) + 祖阿曼(1-6号) 职业特化入口（职业专属增强版）
-- 【迁移说明】以下职业专属增强的"规范/数据驱动版本"现已位于 AI_RuleEngine
--   （按 BOSS属性标签 × 职业能力映射，见 AI_BossTaxonomy + AI_ClassRegistry）。
--   当 PigSet.BOSS_AI_EXTENSIONS_ENABLED 开启时由新系统接管；
--   此处为默认开启的兼容层，请勿删除，以免回退默认行为。
--   机制由 WR_BossMechanics + BossAI 按角色通用覆盖；此处叠加职业工具箱增强
-- ============================================================

local function CheckBossMechanicsForDeathknight()
    local mechanism = WR_CheckBossMechanics()
    if mechanism then
        local colorID = (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap[mechanism.action]) or mechanism.colorID or 1
        local desc = mechanism.description or mechanism.name or UnitName("target") or ""
        WR_ColorFrame_Show(colorID, desc)
        return true, colorID
    end
    return false
end

local function DeathknightKLGSCheck()
    if HasDebuff("player", "腐蚀") or HasDebuff("player", "燃烧") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"卡雷苟斯", "Kalecgos", "太阳井1号", "腐蚀者萨索瓦尔", "Sathrovarr"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "卡雷苟斯-反魔法护盾吸收 / 通用兜底",
    checkFunction = DeathknightKLGSCheck,
})

local function DeathknightBLTLCheck()
    if HasDebuff("player", "燃烧之血") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    if HasDebuff("player", "陨石打击") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"布鲁塔卢斯", "Brutallus", "太阳井2号"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "布鲁塔卢斯-反魔法护盾吸收燃烧 / 冰固减伤 / 通用兜底",
    checkFunction = DeathknightBLTLCheck,
})

local function DeathknightFMSCheck()
    if HasDebuff("player", "腐蚀气体") or HasDebuff("player", "腐蚀吐息") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"菲米丝", "Felmyst", "太阳井3号"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "菲米丝-反魔法护盾吸收 / 通用兜底",
    checkFunction = DeathknightFMSCheck,
})

local function DeathknightTWINSCheck()
    if HasDebuff("player", "暗影之痛") or HasDebuff("player", "火焰之痛") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"艾瑞达双子", "Eredar Twins", "Alythess", "Brannjar", "太阳井4号"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "艾瑞达双子-反魔法护盾吸收 / 通用兜底",
    checkFunction = DeathknightTWINSCheck,
})

local function DeathknightMURUCheck()
    if HasDebuff("player", "熵") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"穆鲁", "M'uru", "Muru", "太阳井5号"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "穆鲁-反魔法护盾吸收 / 通用兜底",
    checkFunction = DeathknightMURUCheck,
})

local function DeathknightKJCheck()
    if HasDebuff("player", "暗影之矛") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"基尔加丹", "Kil'jaeden", "Kiljaeden", "太阳井6号"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "基尔加丹-反魔法护盾吸收 / 通用兜底",
    checkFunction = DeathknightKJCheck,
})

local function DeathknightYWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"鹰王", "Akil'zon", "Akilzon", "艾基利松", "祖阿曼1号"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "鹰王-通用机制库(纯透传)",
    checkFunction = DeathknightYWCheck,
})

local function DeathknightXWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"熊王", "Nalorakk", "纳洛拉克", "祖阿曼2号"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "熊王-通用机制库(纯透传)",
    checkFunction = DeathknightXWCheck,
})

local function DeathknightLHYCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"龙鹰王", "Jan'alai", "Janalai", "贾恩阿拉伊", "祖阿曼3号"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "龙鹰王-通用机制库(纯透传)",
    checkFunction = DeathknightLHYCheck,
})

local function DeathknightBWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"豹王", "Halazzi", "哈拉兹", "祖阿曼4号"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "豹王-通用机制库(纯透传)",
    checkFunction = DeathknightBWCheck,
})

local function DeathknightYSLZCheck()
    if HasDebuff("player", "妖术") or HasDebuff("player", "变青蛙") or HasDebuff("player", "灵魂吸取") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"妖术领主", "Hex Lord Malacrass", "HexLord", "玛拉卡斯", "祖阿曼5号"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "妖术领主-反魔法护盾吸收 / 通用兜底",
    checkFunction = DeathknightYSLZCheck,
})

local function DeathknightZJCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDeathknight()
end

WR_DeathKnight_RegisterBoss({
    bossNames = {"祖金", "Zul'jin", "祖阿曼6号"},
    className = "DEATHKNIGHT",
    action = "stop",
    description = "祖金-通用机制库(纯透传)",
    checkFunction = DeathknightZJCheck,
})


-- ============================================================
-- ★ 统一入口（由 MainLoop 直接调用，无注册表中间件）
--   按当前目标名查本地派发表；命中则调用对应检查函数
--   太阳井(1-6号) 默认不触发（SW_BOSS_SPECIALS_OFF 守卫，用户只需输出循环）
-- ============================================================
function WR_DeathKnight_BossSpecials()
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