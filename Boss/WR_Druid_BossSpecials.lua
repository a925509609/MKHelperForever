-- ============================================================
-- WR_Druid_BossSpecials.lua
-- 德鲁伊职业差异化 BOSS 特化逻辑
--
-- 架构设计：
--   1. 区分坦克（熊形态）/近战DPS（猫形态）/远程DPS（平衡）/治疗（恢复）
--   2. 治疗自动跳过 BOSS 特化检查（恢复天赋不处理BOSS机制）
--   3. 使用 WR_BossMechanics 配置中的机制，按角色类型筛选
--   4. 直接用 WR_ColorFrame_Show 显示颜色
--
-- 颜色映射：stop=3, target=4, defensive=8, rocketboots=108, lk_contamination=107
--
-- 熊坦克（守护者）特化：
--   - 冰龙冰冷吐息 → 树皮/狂暴恢复 (defensive)
--   - 血议会 → 自动切目标 (target)
--
-- 猫DPS（野性）特化：
--   - 冰龙刺骨停手 (stop)
--   - 血议会过滤无效目标 (stop)
--
-- 平衡DPS特化：
--   - 冰龙刺骨停手 (stop)
--   - 灵魂熔炉灵魂倒映停手 (stop)
-- ============================================================

if WR_PlayerClass ~= "DRUID" then return end

if select(2, UnitClass("player")) ~= "DRUID" then
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
local function WR_Druid_RegisterBoss(spec)
    if not spec or not spec.bossNames or not spec.checkFunction then return end
    local isSW = SW_BOSS_NAMES[spec.bossNames[1]] or false
    for _, name in ipairs(spec.bossNames) do
        BOSS_SPECIALS_BY_NAME[name] = { checkFunction = spec.checkFunction, isSW = isSW }
    end
end


local Druid = {}

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
local ROLE_RANGED_CASTER_DPS = WR_BossMechanics.ROLE_RANGED_CASTER_DPS
local ROLE_HEALER = WR_BossMechanics.ROLE_HEALER

local function GetDruidRole()
    return WR_GetPlayerRole and WR_GetPlayerRole() or ROLE_MELEE_DPS
end

local function IsBearTank()
    return GetDruidRole() == ROLE_TANK
end

local function IsCatDPS()
    local role = GetDruidRole()
    return role == ROLE_MELEE_DPS
end

local function IsBalanceDPS()
    return GetDruidRole() == ROLE_RANGED_CASTER_DPS
end

local function IsRestoHealer()
    return GetDruidRole() == ROLE_HEALER
end

local function ShouldSkipBossCheck()
    return IsRestoHealer()
end

-- ============================================================
-- ★ 熊坦克专属检查（守护者）
-- ============================================================

local function SindragosaBearTankCheck()
    local targetName = UnitName("target")
    if targetName ~= "辛达苟萨" and targetName ~= "Sindragosa" then
        return false
    end

    if HasDebuff("player", "冰冷吐息") then
        return true, "defensive"
    end

    if HasDebuff("player", "冰封") then
        return true, "defensive"
    end

    local chilledCount = GetDebuffCount("player", "寒霜刺骨")
    local threshold = PigSet and PigSet.WQZ_HSCG or 5
    if chilledCount and chilledCount >= threshold then
        return true, "defensive"
    end

    return false
end

local function BloodCouncilBearTankCheck()
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

-- ============================================================
-- ★ 猫DPS专属检查（野性）
-- ============================================================

local function SindragosaCatDPSCheck()
    local targetName = UnitName("target")
    if targetName ~= "辛达苟萨" and targetName ~= "Sindragosa" then
        return false
    end

    local chilledCount = GetDebuffCount("player", "寒霜刺骨")
    local threshold = PigSet and PigSet.WQZ_HSCG or 5
    if chilledCount and chilledCount >= threshold then
        return true, "stop"
    end

    if HasDebuff("player", "冰封") then
        return true, "stop"
    end

    return false
end

local function BloodCouncilCatDPSCheck()
    local targetName = UnitName("target")

    if targetName == "动力炸弹" or targetName == "黑暗之核" then
        return true, "stop"
    end

    return false
end

-- ============================================================
-- ★ 平衡DPS专属检查
-- ============================================================

local function SindragosaBalanceDPSCheck()
    local targetName = UnitName("target")
    if targetName ~= "辛达苟萨" and targetName ~= "Sindragosa" then
        return false
    end

    local chilledCount = GetDebuffCount("player", "寒霜刺骨")
    local threshold = PigSet and PigSet.WQZ_HSCG or 3
    if chilledCount and chilledCount >= threshold then
        return true, "stop"
    end

    if HasDebuff("player", "冰封") then
        return true, "stop"
    end

    return false
end

local function ForgeOfSoulsBalanceDPSCheck()
    if HasDebuff("player", "灵魂倒映") then
        return true, "stop"
    end

    local targetName = UnitName("target")
    if targetName == "镜像" or targetName == "腐化的灵魂" then
        return true, "stop"
    end

    if HasBuff("target", "灵魂倒映") then
        return true, "stop"
    end

    return false
end

-- ============================================================
-- ★ 14-25. TOC/ZG/奥杜尔阶段新增Boss (12个)
--     来源：集成外部插件优化逻辑 + MY插件通用机制
--     德鲁伊特化调整：完整覆盖TOC(3个)+ZG(5个)+奥杜尔(4个)
-- ============================================================
local TwinsDarkVortexActive = false

-- ★ 14. TOC双子 - 同色攻击切换 + 黑暗漩涡防御
local function TwinsCheck()
    local role = GetDruidRole()
    if (role == "melee_dps" or role == "ranged_caster_dps") and (HasDebuff("player", "光明 Essence") or HasDebuff("player", "黑暗 Essence")) then
        return true, "target"
    end
    if role == "tank" and TwinsDarkVortexActive and HasBuff("player", "熊形态") and (HasBuff("player", "树皮术") or HasBuff("player", "狂暴回复")) then
        return true, "defensive"
    end
    return false
end

-- ★ 15. TOC阿努巴拉克 - 虫群停手 + 召唤物处理
local function AnubarakCheck()
    if HasDebuff("player", "虫群感染") or HasDebuff("player", "虫群之怒") then
        return true, "stop"
    end
    local targetName = UnitName("target")
    if string.find(targetName, "小虫") or string.find(targetName, "Infested") then
        return true, "turnfire"
    end
    return false
end

-- ★ 16. TOC贾克瑟斯 - 王子转火 + 暗影烈焰规避
local function JaraxxusCheck()
    local targetName = UnitName("target")
    if string.find(targetName, "王子") or string.find(targetName, "Prince") then
        return true, "turnfire"
    end
    local castName, castTime = UnitCastingInfo("target")
    if castName and (string.find(castName, "暗影烈焰") or string.find(castName, "Cauterize")) and castTime > 1.5 then
        return true, "move"
    end
    return false
end

-- ★ 17. ZG耶克里克 - 蝙蝠群AOE智能触发
local function JeklikCheck()
    local batCount = 0
    for i = 1, 40 do
        local name = C_NamePlate.GetNamePlateForUnitNumber(i):GetName():GetString()
        if name and string.find(name, "觅血蝙蝠") then
            batCount = batCount + 1
        end
    end
    if (UnitName("target") == "高阶祭司耶克里克" or UnitName("target") == "High Priestess Jeklik") and batCount >= 3 then
        PigSet.DRUID_AOE_MODE = true
        return true, "aoe"
    else
        PigSet.DRUID_AOE_MODE = false
    end
    return false
end

-- ★ 18. ZG曼多基尔 - 威慑凝视停手
local function MandokirCheck()
    local castName, castTime = UnitCastingInfo("target")
    if castName and (string.find(castName, "凝视") or string.find(castName, "Staring") or string.find(castName, "Intimidating Gaze")) and castTime > 1 then
        return true, "stop"
    end
    local channelName, channelTime = UnitChannelInfo("target")
    if channelName and string.find(channelName, "凝视") then
        return true, "stop"
    end
    return false
end

-- ★ 19. ZG哈卡 - 灵魂吞噬处理 + 哈卡之子转火
local function HakkarCheck()
    if HasDebuff("player", "灵魂吞噬") or HasDebuff("player", "Soul Flay") then
        return true, "stop"
    end
    local targetName = UnitName("target")
    if string.find(targetName, "哈卡之子") or string.find(targetName, "Hakkar's Child") then
        return true, "turnfire"
    end
    return false
end

-- ★ 20. ZG韦诺克斯 - 瘟疫传播停止散开
local function VenoxisCheck()
    if HasDebuff("player", "瘟疫印记") or HasDebuff("player", "Plague") then
        return true, "no_dispersion"
    end
    return false
end

-- ★ 21. ZG金度 - 审判阶段停手
local function JindoCheck()
    local castName, castTime = UnitCastingInfo("target")
    if castName and (string.find(castName, "审判") or string.find(castName, "Judgment") or string.find(castName, "Anub'zhul")) and castTime > 2 then
        return true, "stop"
    end
    if HasDebuff("player", "精神控制") or HasDebuff("player", "Mind Control") then
        return true, "stop"
    end
    return false
end

-- ★ 22. XT002 - 重力炸弹防护 + 炸弹人过滤
local function XT002Check()
    if HasDebuff("player", "重力炸弹") or HasDebuff("player", "Gravity Bomb") then
        if IsBearTank() and HasBuff("player", "树皮术") then
            return true, "defensive"
        end
    end
    local targetName = UnitName("target")
    if string.find(targetName, "XE-321") or string.find(targetName, "爆破机器人") then
        return true, "turnfire"
    end
    return false
end

-- ★ 23. 科隆加恩 - 手臂阶段管理
local function KologarnCheck()
    local targetName = UnitName("target")
    if string.find(targetName, "右臂") or string.find(targetName, "Left Arm") or string.find(targetName, "左臂") or string.find(targetName, "Right Arm") then
        return true, "focus_arm"
    end
    if not string.find(targetName, "身体") and not string.find(targetName, "Body") then
        return true, "return_body"
    end
    return false
end

-- ★ 24. 米米尔隆 - 电拳/机械爪处理
local function MimironCheck()
    local castName, castTime = UnitCastingInfo("target")
    if castName and (string.find(castName, "电拳") or string.find(castName, "Lightning Punch") or string.find(castName, "60K")) and castTime > 1.5 and IsBearTank() and (HasBuff("player", "树皮术") or HasBuff("player", "铁肤术")) then
        return true, "defensive"
    end
    if castName and (string.find(castName, "机械爪") or string.find(castName, "Mechanical Grab") or string.find(castName, "Hookpoint")) then
        return true, "move_away_edge"
    end
    return false
end

-- ★ 25. 维扎克斯 - 暗影冲击停手 + 无面印记传送
local function VezaxCheck()
    if HasDebuff("player", "暗影冲击") or HasDebuff("player", "Shadow Burst") then
        return true, "stop"
    end
    local _, _, _, _, duration, expirationTime, _, _, _, spellId = UnitDebuff("player", "无面印记")
    if duration and duration >= 8 then
        print("|cFFFFFF00[德鲁伊]|r 无面印记剩余时间长,准备火箭靴逃生!")
        return true, "rocketboots_prep"
    end
    return false
end

-- ============================================================
-- ★ 通用 BOSS 检查（坦克 + DPS 共用，恢复跳过）
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
    if IsBalanceDPS() then
        return false
    end
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
--   整合 WR_BossMechanics 通用机制 + 德鲁伊专属差异化逻辑
-- ============================================================
function WR_DruidBossCheck()
    if ShouldSkipBossCheck() then
        return false
    end

    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        return false
    end

    -- 1. 优先检查 WR_BossMechanics 中的通用机制（按角色类型筛选）
    local bossData = WR_FindCurrentBossMechanics and WR_FindCurrentBossMechanics()
    if bossData and bossData.mechanisms then
        local role = GetDruidRole()
        for _, mechanism in ipairs(bossData.mechanisms) do
            if WR_CheckRoleApplicable and WR_CheckRoleApplicable(mechanism, role) then
                if mechanism.checkFunction and mechanism.checkFunction() then
                    local colorID = ColorMap[mechanism.action] or mechanism.colorID or 1
                    WR_ColorFrame_Show(colorID, mechanism.description or mechanism.name)
                    return true
                end
            end
        end
    end

    -- 2. 德鲁伊专属差异化检查
    local isBear = IsBearTank()
    local isCat = IsCatDPS()
    local isBalance = IsBalanceDPS()

    -- 熊坦克专属
    if isBear then
        local triggered, action = SindragosaBearTankCheck()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.defensive
            WR_ColorFrame_Show(colorID, "冰龙坦克防御(树皮/狂暴恢复)")
            return true
        end

        triggered, action = BloodCouncilBearTankCheck()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.stop
            WR_ColorFrame_Show(colorID, "血议会坦克切目标")
            return true
        end
    end

    -- 猫DPS专属
    if isCat then
        local triggered, action = SindragosaCatDPSCheck()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.stop
            WR_ColorFrame_Show(colorID, "冰龙猫DPS刺骨停手")
            return true
        end

        triggered, action = BloodCouncilCatDPSCheck()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.stop
            WR_ColorFrame_Show(colorID, "血议会猫DPS过滤无效目标")
            return true
        end
    end

    -- 平衡DPS专属
    if isBalance then
        local triggered, action = SindragosaBalanceDPSCheck()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.stop
            WR_ColorFrame_Show(colorID, "冰龙平衡DPS刺骨停手")
            return true
        end

        triggered, action = ForgeOfSoulsBalanceDPSCheck()
        if triggered then
            local colorID = ColorMap[action] or ColorMap.stop
            WR_ColorFrame_Show(colorID, "灵魂熔炉平衡DPS倒映停手")
            return true
        end
    end

    -- 3. 通用检查（坦克 + DPS 共用）
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
        
        -- ★ TOC阶段新增(3个Boss)
        { TwinsCheck, "双子同色攻击切换" },
        { AnubarakCheck, "阿努巴拉克虫群停手" },
        { JaraxxusCheck, "贾克瑟斯王子转火" },
        
        -- ★ ZG阶段新增(5个Boss)
        { JeklikCheck, "耶克里克蝙蝠群AOE" },
        { MandokirCheck, "曼多基尔凝视停手" },
        { HakkarCheck, "哈卡灵魂吞噬停手" },
        { VenoxisCheck, "韦诺克斯瘟疫传播" },
        { JindoCheck, "金度审判停手" },
        
        -- ★ 奥杜尔阶段新增(4个Boss)
        { XT002Check, "XT002重力炸弹防护" },
        { KologarnCheck, "科隆加恩手臂阶段" },
        { MimironCheck, "米米尔隆机械爪处理" },
        { VezaxCheck, "维扎克斯暗影冲击停手" },
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
--   MainLoop 的 BOSS_SPECIALS_DISPATCH 按职业直调 WR_Druid_BossSpecials() 入口
-- ============================================================
WR_Druid_RegisterBoss({    bossNames = {
        -- ICC阶段(7个)
        "辛达苟萨", "Sindragosa", "冰霜女王",
        "血议会", "鲜血议会", "Blood Council",
        "灵魂熔炉", "锻造之魂", "Forge of Souls",
        "巫妖王", "The Lich King", "LK",
        "炮舰", "天界飞船", "Gunship",
        "海里昂", "Halion",
        "死亡使者萨鲁法尔", "Deathbringer Saurfang", "萨鲁法尔",
        
        -- TOC阶段(3个) - 新增
        "双子", "姐妹", "Twin Empresses",
        "阿努巴拉克", "Anub'arak", "虫群",
        "贾克瑟斯王子", "王子", "Jaraxxus",
        
        -- ZG阶段(5个) - 新增
        "高阶祭司耶克里克", "Jeklik", "蝙蝠",
        "曼多基尔", "Mandokir", "凝视",
        "高阶祭司哈卡", "Hakkar", "灵魂吞噬",
        "高阶祭司韦诺克斯", "Venoxis", "瘟疫",
        "高阶祭司金度", "Jindo", "审判",
        
        -- 奥杜尔阶段(4个) - 新增
        "XT002拆解之心", "XT-002", "重力炸弹",
        "科隆加恩", "Kologarn", "手臂",
        "米米尔隆", "观察者的机械主人", "Mimiron",
        "维扎克斯指挥官", "Vezax", "暗影冲击",
        
        -- 其他
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
    className = "DRUID",
    talent = nil,
    action = "idle",
    description = "德鲁伊差异化 BOSS 特化",
    checkFunction = function()
        return WR_DruidBossCheck()
    end,
})


-- ============================================================
-- 通用职业机制分发（纯透传）
--   复用全局 WR_CheckBossMechanics() 检查当前 Boss 全部机制，
--   由机制自身 checkFunction 决定触发（多形态职业不硬编码角色）
-- ============================================================
local function CheckBossMechanicsForDruid()
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

local function CheckBossMechanicsForDruid()
    local mechanism = WR_CheckBossMechanics()
    if mechanism then
        local colorID = (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap[mechanism.action]) or mechanism.colorID or 1
        local desc = mechanism.description or mechanism.name or UnitName("target") or ""
        WR_ColorFrame_Show(colorID, desc)
        return true, colorID
    end
    return false
end

local function DruidKLGSCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"卡雷苟斯", "Kalecgos", "太阳井1号", "腐蚀者萨索瓦尔", "Sathrovarr"},
    className = "DRUID",
    action = "stop",
    description = "卡雷苟斯-通用机制库(纯透传)",
    checkFunction = DruidKLGSCheck,
})

local function DruidBLTLCheck()
    if HasDebuff("player", "陨石打击") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"布鲁塔卢斯", "Brutallus", "太阳井2号"},
    className = "DRUID",
    action = "stop",
    description = "布鲁塔卢斯-树皮术减伤 / 通用兜底",
    checkFunction = DruidBLTLCheck,
})

local function DruidFMSCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"菲米丝", "Felmyst", "太阳井3号"},
    className = "DRUID",
    action = "stop",
    description = "菲米丝-通用机制库(纯透传)",
    checkFunction = DruidFMSCheck,
})

local function DruidTWINSCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"艾瑞达双子", "Eredar Twins", "Alythess", "Brannjar", "太阳井4号"},
    className = "DRUID",
    action = "stop",
    description = "艾瑞达双子-通用机制库(纯透传)",
    checkFunction = DruidTWINSCheck,
})

local function DruidMURUCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"穆鲁", "M'uru", "Muru", "太阳井5号"},
    className = "DRUID",
    action = "stop",
    description = "穆鲁-通用机制库(纯透传)",
    checkFunction = DruidMURUCheck,
})

local function DruidKJCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"基尔加丹", "Kil'jaeden", "Kiljaeden", "太阳井6号"},
    className = "DRUID",
    action = "stop",
    description = "基尔加丹-通用机制库(纯透传)",
    checkFunction = DruidKJCheck,
})

local function DruidYWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"鹰王", "Akil'zon", "Akilzon", "艾基利松", "祖阿曼1号"},
    className = "DRUID",
    action = "stop",
    description = "鹰王-通用机制库(纯透传)",
    checkFunction = DruidYWCheck,
})

local function DruidXWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"熊王", "Nalorakk", "纳洛拉克", "祖阿曼2号"},
    className = "DRUID",
    action = "stop",
    description = "熊王-通用机制库(纯透传)",
    checkFunction = DruidXWCheck,
})

local function DruidLHYCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"龙鹰王", "Jan'alai", "Janalai", "贾恩阿拉伊", "祖阿曼3号"},
    className = "DRUID",
    action = "stop",
    description = "龙鹰王-通用机制库(纯透传)",
    checkFunction = DruidLHYCheck,
})

local function DruidBWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"豹王", "Halazzi", "哈拉兹", "祖阿曼4号"},
    className = "DRUID",
    action = "stop",
    description = "豹王-通用机制库(纯透传)",
    checkFunction = DruidBWCheck,
})

local function DruidYSLZCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"妖术领主", "Hex Lord Malacrass", "HexLord", "玛拉卡斯", "祖阿曼5号"},
    className = "DRUID",
    action = "stop",
    description = "妖术领主-通用机制库(纯透传)",
    checkFunction = DruidYSLZCheck,
})

local function DruidZJCheck()
    if HasDebuff("player", "毒") or HasDebuff("player", "致命毒液") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForDruid()
end

WR_Druid_RegisterBoss({
    bossNames = {"祖金", "Zul'jin", "祖阿曼6号"},
    className = "DRUID",
    action = "stop",
    description = "祖金-消除腐蚀解毒 / 通用兜底",
    checkFunction = DruidZJCheck,
})

-- ============================================================
-- ★ 统一入口（由 MainLoop 直接调用，无注册表中间件）
--   按当前目标名查本地派发表；命中则调用对应检查函数
--   太阳井(1-6号) 默认不触发（SW_BOSS_SPECIALS_OFF 守卫，用户只需输出循环）
-- ============================================================
function WR_Druid_BossSpecials()
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

