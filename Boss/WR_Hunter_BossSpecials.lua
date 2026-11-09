-- ============================================================
-- WR_Hunter_BossSpecials.lua
-- 猎人职业差异化 BOSS 特化逻辑
-- 物理远程DPS（ROLE_RANGED_PHYSICAL_DPS），无坦克/治疗
--
-- 架构：
--   1. 优先使用 WR_BossMechanics 配置中的机制，按 ROLE_RANGED_PHYSICAL_DPS 筛选
--   2. 补充 WR_BossMechanics 中未覆盖的猎人特有机制
--   3. 直接用 WR_ColorFrame_Show 显示颜色
--   4. 检查函数返回 true, colorID 以支持 WR_BossRegistry 颜色覆盖
--
-- 颜色映射：
--   stop=3, target=4, defensive=8, rocketboots=108, lk_contamination=107
--
-- 关注的 BOSS 特化：
--   1. 冰龙辛达苟萨 - 刺骨停手(阈值5层)、冰封停手
--   2. 血议会 - 过滤黑暗之核/动力炸弹 + 三王子切目标
--   3. 灵魂熔炉 - 灵魂倒映停手
--   4. 巫妖王 - 污染停手
--   5. 教授普崔希德 - 软泥怪停手
--   6. 海里昂 - 低血量火箭靴（猎人优先）
--   7. 血女王 - 鲜血镜像
--   8. 腐面/烂肠 - 突变停手
--   9. 观察者奥尔加隆 - 星尘阶段停手
--  10. 尤格萨隆 - 精神控制停手
--  11. 翡翠巨龙 - 沉睡处理（跳过燃烧之血，猎人无蓝条）
--  12. 炮舰 - 火箭靴
--  13. 萨鲁法尔 - 保护之手物理免疫停手
-- ============================================================

if WR_PlayerClass ~= "HUNTER" then return end

if select(2, UnitClass("player")) ~= "HUNTER" then
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
local function WR_Hunter_RegisterBoss(spec)
    if not spec or not spec.bossNames or not spec.checkFunction then return end
    local isSW = SW_BOSS_NAMES[spec.bossNames[1]] or false
    for _, name in ipairs(spec.bossNames) do
        BOSS_SPECIALS_BY_NAME[name] = { checkFunction = spec.checkFunction, isSW = isSW }
    end
end


local HS = {}

-- 角色常量（从 WR_BossMechanics 导入）
local ROLE_RANGED_PHYSICAL_DPS = WR_BossMechanics.ROLE_RANGED_PHYSICAL_DPS

-- ============================================================
-- 共享工具（来自 WR_BossUtils，避免重复定义）
-- ============================================================
local GetDebuffCount = WR_BossUtils.GetDebuffCount
local HasBuff = WR_BossUtils.HasBuff
local HasDebuff = WR_BossUtils.HasDebuff
local ColorMap = WR_BossUtils.ColorMap
local ShowColor = WR_BossUtils.ShowColor

-- ============================================================
-- 核心：从 WR_BossMechanics 配置中按远程DPS筛选机制
-- 返回：true, colorID 或 false
-- ============================================================
local function CheckBossMechanicsForHunter()
    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        return false
    end

    local bossData = WR_BossUtils.FindBossData(targetName)

    if not bossData or not bossData.mechanisms then
        return false
    end

    for _, mech in ipairs(bossData.mechanisms) do
        if WR_CheckRoleApplicable and WR_CheckRoleApplicable(mech, ROLE_RANGED_PHYSICAL_DPS) then
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
-- 1. 灵魂熔炉 - 灵魂倒映停手
-- ============================================================
local function ForgeOfSoulsCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
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

WR_Hunter_RegisterBoss({
    bossNames = {"灵魂熔炉", "锻造之魂", "Forge of Souls"},
    className = "HUNTER",
    action = "stop",
    description = "灵魂熔炉停手",
    checkFunction = ForgeOfSoulsCheck,
})

-- ============================================================
-- 2. 血议会 - 过滤无效目标 + 切目标
-- ============================================================
local function BloodCouncilCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
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

WR_Hunter_RegisterBoss({
    bossNames = {"血议会", "鲜血议会", "Blood Council"},
    className = "HUNTER",
    action = "target",
    description = "血议会切目标",
    checkFunction = BloodCouncilCheck,
})

-- ============================================================
-- 3. 教授普崔希德 - 软泥怪停手
-- ============================================================
local function PutricideCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
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

WR_Hunter_RegisterBoss({
    bossNames = {"普崔塞德教授", "Professor Putricide", "Putricide"},
    className = "HUNTER",
    action = "stop",
    description = "教授软泥停手",
    checkFunction = PutricideCheck,
})

-- ============================================================
-- 4. 巫妖王 - 污染停手
-- ============================================================
local function LKCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "污染") or HasDebuff("player", "冰封王座") then
        local cid = ShowColor("lk_contamination", "巫妖王污染停手")
        return true, cid
    end

    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"巫妖王", "The Lich King", "LK"},
    className = "HUNTER",
    action = "lk_contamination",
    description = "巫妖王污染停手",
    checkFunction = LKCheck,
})

-- ============================================================
-- 5. 海里昂 - 低血量火箭靴（猎人优先）
-- ============================================================
local function HalionCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end

    local targetName = UnitName("target")
    if targetName == "海里昂" then
        local hp = WR_GetUnitHP("player") or 100
        if hp < 30 then
            local cid = ShowColor("rocketboots", "海里昂火箭靴")
            return true, cid
        end
    end

    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"海里昂", "Halion"},
    className = "HUNTER",
    action = "rocketboots",
    description = "海里昂火箭靴",
    checkFunction = HalionCheck,
})

-- ============================================================
-- 6. 绿龙/红龙 - 特殊处理
-- ============================================================
local function DragonCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "沉睡") then
        local cid = ShowColor("stop", "巨龙沉睡处理")
        return true, cid
    end

    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"翡翠巨龙", "绯红巨龙守护者", "Valithria"},
    className = "HUNTER",
    action = "stop",
    description = "巨龙特殊处理",
    checkFunction = DragonCheck,
})

-- ============================================================
-- 7. 血女王 - 鲜血镜像
-- ============================================================
local function BloodQueenCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "鲜血镜像") then
        local cid = ShowColor("stop", "血女王镜像停手")
        return true, cid
    end

    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"鲜血女王兰娜瑟尔", "Blood-Queen Lana'thel", "血女王"},
    className = "HUNTER",
    action = "stop",
    description = "血女王镜像停手",
    checkFunction = BloodQueenCheck,
})

-- ============================================================
-- 8. 腐面/烂肠 - 突变停手
-- ============================================================
local function MutantCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "突变") or HasDebuff("player", "致命突变") then
        local cid = ShowColor("stop", "腐面突变停手")
        return true, cid
    end

    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"腐面", "Festergut", "烂肠", "Rotface"},
    className = "HUNTER",
    action = "stop",
    description = "腐面突变停手",
    checkFunction = MutantCheck,
})

-- ============================================================
-- 9. 观察者奥尔加隆 - 星尘阶段停手
-- ============================================================
local function AlgalonCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
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

WR_Hunter_RegisterBoss({
    bossNames = {"观察者奥尔加隆", "Algalon the Observer", "奥尔加隆"},
    className = "HUNTER",
    action = "stop",
    description = "奥尔加隆星尘停手",
    checkFunction = AlgalonCheck,
})

-- ============================================================
-- 10. 尤格萨隆 - 精神控制停手
-- ============================================================
local function YoggCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end

    if HasDebuff("player", "精神控制") or HasDebuff("player", "心灵牢笼") then
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

WR_Hunter_RegisterBoss({
    bossNames = {"尤格萨隆", "Yogg-Saron", "Yogg"},
    className = "HUNTER",
    action = "stop",
    description = "尤格萨隆精神控制",
    checkFunction = YoggCheck,
})

-- ============================================================
-- 11. 冰龙辛达苟萨 - 刺骨停手 / 冰封停手
-- ============================================================
local function SindragosaCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end

    local HSCG = PigSet and PigSet.WQZ_HSCG or 5
    local chilledCount = GetDebuffCount("player", "寒霜刺骨")
    if chilledCount >= HSCG then
        local cid = ShowColor("stop", "冰龙刺骨停手")
        return true, cid
    end

    if HasDebuff("player", "冰封") then
        local cid = ShowColor("stop", "冰龙冰封停手")
        return true, cid
    end

    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"辛达苟萨", "Sindragosa", "冰霜女王"},
    className = "HUNTER",
    action = "stop",
    description = "冰龙刺骨停手",
    checkFunction = SindragosaCheck,
})

-- ============================================================
-- 12. 炮舰 - 火箭靴
-- ============================================================
local function GunshipCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
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

WR_Hunter_RegisterBoss({
    bossNames = {"炮舰", "天界飞船", "Gunship"},
    className = "HUNTER",
    action = "rocketboots",
    description = "炮舰火箭靴",
    checkFunction = GunshipCheck,
})

-- ============================================================
-- 13. 萨鲁法尔 - 血兽处理
-- ============================================================
local function SaurfangCheck()
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end

    if HasBuff("player", "保护之手") then
        local cid = ShowColor("stop", "保护之手物理免疫停手")
        return true, cid
    end

    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"死亡使者萨鲁法尔", "Deathbringer Saurfang", "萨鲁法尔"},
    className = "HUNTER",
    action = "defensive",
    description = "萨鲁法尔血兽处理",
    checkFunction = SaurfangCheck,
})

-- ============================================================
-- 14. 弗蕾雅 - 大地震颤停手 + 蘑菇自然之力提示
--     来源：另外循环插件特化\术士\43CF22BE.lua（奥杜尔芙蕾雅.lua）
--     猎人特化调整：
--       1) 大地震颤时停手（猎人同样适用）
--       2) 自然之力buff时提示对弗蕾雅放毒蛇钉刺/射击
-- ============================================================
local function FreyaCheck()
    -- 1) 大地震颤停手
    if HasDebuff("player", "大地震颤") then
        local cid = ShowColor("stop", "弗蕾雅大地震震颤停手")
        return true, cid
    end
    
    -- 2) 自然之力buff时提示对弗蕾雅输出
    if HasBuff("player", "自然之力") then
        local targetName = UnitName("target")
        if targetName ~= "弗蕾雅" and targetName ~= "Freya" then
            local cid = ShowColor("target", "自然之力-转火弗蕾雅")
            return true, cid
        end
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"弗蕾雅", "Freya", "奥杜尔弗蕾雅"},
    className = "HUNTER",
    action = "stop",
    description = "弗蕾雅大地震震颤停手+自然之力",
    checkFunction = FreyaCheck,
})

-- ============================================================
-- 15. 铁议会 - 符文力量光环管理
--     来源：另外循环插件特化\术士\F3287AEC.lua（奥杜尔议会.lua）
--     猎人特化调整：
--       1) 符文力量debuff≥2层时提示防御性技能
--       2) 电力符文目标过滤（不打无防护目标）
-- ============================================================
local function IronCouncilCheck()
    -- 1) 符文力量debuff计数（≥2层时停止输出）
    local runeCount = GetDebuffCount("player", "符文力量")
    if runeCount >= 2 then
        local cid = ShowColor("defensive", "双光环-符文力量防御")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"断钢者", "符文大师莫尔基姆", "唤雷者布隆迪尔", "Iron Council", "铁议会"},
    className = "HUNTER",
    action = "stop",
    description = "铁议会双光环符文力量",
    checkFunction = IronCouncilCheck,
})

-- ============================================================
-- 16. 科隆加恩 - 手臂阶段管理
--     来源：另外循环插件特化\术士\5D23ADB2.lua（奥杜尔科隆加恩.lua）
--     猎人特化调整：
--       1) 右臂/左臂出现时转火处理
--       2) 主目标身体死亡后自动切手臂
-- ============================================================
local function KologarnCheck()
    local targetName = UnitName("target")
    
    -- 1) 右臂/左臂出现时提示
    if targetName == "右臂" or targetName == "左臂" then
        local cid = ShowColor("target", "科隆加恩-手臂转火")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"科隆加恩", "Kologarn"},
    className = "HUNTER",
    action = "stop",
    description = "科隆加恩手臂阶段管理",
    checkFunction = KologarnCheck,
})

-- ============================================================
-- 17. XT002拆解之心 - 炸弹人处理 + 重力炸弹防护
--     来源：另外循环插件特化\术士\4FEB707C.lua（奥杜尔拆解之心.lua）
--     猎人特化调整：
--       1) XE-321爆破机器人出现时提示转火
--       2) 重力炸弹debuff时提示使用防御技能
-- ============================================================
local function XT002Check()
    local targetName = UnitName("target")
    
    -- 1) 炸弹人出现时提示转火
    if targetName == "XE-321爆破机器人" or targetName == "动力炸弹猎" then
        local cid = ShowColor("target", "XT002-炸弹人转火")
        return true, cid
    end
    
    -- 2) 重力炸弹debuff时提示防御
    if HasDebuff("player", "重力炸弹") then
        local cid = ShowColor("defensive", "重力炸弹-防御结界")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"拆解者之心", "XT002", "奥杜尔XT002"},
    className = "HUNTER",
    action = "stop",
    description = "XT002炸弹人种子+重力炸弹防护",
    checkFunction = XT002Check,
})

-- ============================================================
-- 18. 米米尔隆 - 烈焰遏制防断条
--     来源：另外循环插件特化\术士\7E169FC1.lua（灭火机器人.lua）
--     猎人特化调整：
--       1) 烈焰遏制debuff时提示暂停引导技能
--       2) 紧急灭火机器人目标过滤（不打）
-- ============================================================
local function MimironCheck()
    local targetName = UnitName("target")
    
    -- 1) 烈焰遏制debuff时提示暂停输出
    if HasDebuff("player", "烈焰遏制") then
        local cid = ShowColor("stop", "米米尔隆烈焰遏制-暂停输出")
        return true, cid
    end
    
    -- 2) 紧急灭火机器人目标过滤
    if targetName == "紧急灭火机器人" then
        local cid = ShowColor("stop", "灭火机器人-不打分")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"米米尔隆", "Mimiron", "奥杜尔米米尔隆"},
    className = "HUNTER",
    action = "stop",
    description = "米米尔隆烈焰遏制不断条+灭火机器人过滤",
    checkFunction = MimironCheck,
})

-- ============================================================
-- 19. 维扎克斯 - 暗影冲击停手 + 无面印记传送
--     来源：另外循环插件特化\术士\B2B75F55.lua（维扎克斯.lua）
--     猎人特化调整：
--       1) 暗影冲击debuff时停手（禁止分散技能）
--       2) 无面印记剩余≥8秒时提示火箭靴
-- ============================================================
local function VezaxCheck()
    -- 1) 暗影冲击debuff时停手
    if HasDebuff("player", "暗影冲击") then
        local cid = ShowColor("stop", "维扎克斯暗影冲击-停手禁分流")
        return true, cid
    end
    
    -- 2) 无面印记传送提示
    if HasDebuff("player", "无面印记") then
        local markLeft = WR_GetUnitDebuffTime("player", "无面印记")
        if markLeft and markLeft >= 8 then
            local cid = ShowColor("rocketboots", "无面印记-火箭靴")
            return true, cid
        end
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"维扎克斯将军", "General Vezax", "维扎克斯", "Vezax"},
    className = "HUNTER",
    action = "stop",
    description = "维扎克斯暗影冲击停手+无面印记传送",
    checkFunction = VezaxCheck,
})

-- ============================================================
-- 20. 魔枢 - 镜像过滤 + 能量虹吸处理
--     来源：集成MY插件术士特化通用逻辑
--     猎人特化调整：
--       1) 过滤镜像目标
--       2) 能量虹吸debuff时停止输出
-- ============================================================
local function ArcatombCheck()
    local targetName = UnitName("target")
    
    -- 1) 镜像目标过滤
    if targetName == "镜像" or targetName == "腐化的灵魂" then
        local cid = ShowColor("stop", "魔枢-镜像过滤")
        return true, cid
    end
    
    -- 2) 能量虹吸debuff时停手
    if HasDebuff("player", "能量虹吸") then
        local cid = ShowColor("stop", "魔枢-能量虹吸停手")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"魔枢", "Arcatomb", "玛里苟斯"},
    className = "HUNTER",
    action = "stop",
    description = "魔枢镜像过滤+能量虹吸",
    checkFunction = ArcatombCheck,
})

-- ============================================================
-- 21. 乌巅 (玉峰顶) - glaciate冰霜地面自动跑路
--     来源：集成MY插件术士特化通用逻辑
--     猎人特化调整：
--       1) glaciate冰霜地面出现时提示移动
--       2) 冰冻debuff时优先使用闪避
-- ============================================================
local function JadeSatyrCheck()
    -- 1) glaciate冰霜地面debuff时提示移动
    if HasDebuff("player", "glaciate") or HasDebuff("player", "冰霜凝结") then
        local cid = ShowColor("defensive", "乌巅-冰霜地面跑路")
        return true, cid
    end
    
    -- 2) 冰冻debuff时提示防御
    if HasDebuff("player", "冰冻") then
        local cid = ShowColor("defensive", "乌巅-冰冻防御")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"玉峰顶", "Jade Satyr", "乌巅"},
    className = "HUNTER",
    action = "stop",
    description = "乌巅冰霜地面处理",
    checkFunction = JadeSatyrCheck,
})

-- ============================================================
-- 22. 巴尔萨鲁斯 (ICC炮舰) - DOT暂停管理
--     来源：集成MY插件术士特化通用逻辑
--     猎人特化调整：
--       1) DOT技能暂停释放
--       2) 炮舰阶段低血量火箭靴
-- ============================================================
local function BalnazzarCheck()
    local targetName = UnitName("target")
    
    -- 1) DOT暂停阶段判断
    --    猎人毒蛇钉刺在特定阶段应该暂停
    if HasDebuff("player", "诅咒") or HasDebuff("player", "黑暗力量") then
        local cid = ShowColor("stop", "巴尔萨鲁斯-DOT暂停")
        return true, cid
    end
    
    -- 2) 炮舰阶段低血量火箭靴
    if targetName == "炮舰" or targetName == "天界飞船" then
        local hp = WR_BossUtils.GetPlayerHP()
        if hp < 30 then
            local cid = ShowColor("rocketboots", "炮舰火箭靴")
            return true, cid
        end
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"巴尔萨鲁斯", "Balnazzar", "ICC炮舰"},
    className = "HUNTER",
    action = "stop",
    description = "巴尔萨鲁斯DOT暂停+炮舰火箭靴",
    checkFunction = BalnazzarCheck,
})


-- ============================================================
-- 23. TOC双子 - 同色攻击处理 + 黑暗漩涡防御
--     来源：集成术士特化通用逻辑 + 外部插件优化
--     猎人特化调整：
--       1) 光明/黑暗Essence时提示切换目标
--       2) 黑暗漩涡出现时使用防御技能
-- ============================================================
local TwinsDarkVortexActive = false  -- 黑暗漩涡状态标记

local function TwinsCheck()
    -- 1) 同色攻击提示
    if HasDebuff("player", "光明 Essence") or HasDebuff("player", "黑暗 Essence") then
        local cid = ShowColor("target", "双子-同色攻击切换")
        return true, cid
    end
    
    -- 2) 黑暗漩涡防御
    --    光明Essence期间如果有黑暗漩涡,需要暗影防护
    if TwinsDarkVortexActive and HasDebuff("player", "光明 Essence") then
        local cid = ShowColor("defensive", "黑暗漩涡-暗影防护")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"光明邪使菲奥拉", "黑暗邪使艾蒂丝", "TOC双子", "Twins", "Fiery", "Adhis"},
    className = "HUNTER",
    action = "stop",
    description = "TOC双子同色攻击+黑暗漩涡",
    checkFunction = TwinsCheck,
})

-- ============================================================
-- 24. TOC阿努巴拉克 - 中虫刺骨寒冷处理
--     来源：集成术士特化通用逻辑
--     猎人特化调整：
--       1) 蛛魔掘地者(中虫)出现时转火
--       2) 刺骨寒冷debuff时使用防御技能
-- ============================================================
local function AnubarakCheck()
    local targetName = UnitName("target")
    
    -- 1) 中虫出现时提示转火
    if targetName == "蛛魔掘地者" then
        local cid = ShowColor("target", "阿努巴拉克-中虫转火")
        return true, cid
    end
    
    -- 2) 刺骨寒冷debuff时停手使用防御
    --    猎人没有生命分流,改用闪避/逃脱
    if HasDebuff("player", "刺骨寒冷") then
        local cid = ShowColor("defensive", "刺骨寒冷-使用闪避")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"阿努巴拉克", "Anubarak", "TOC老五"},
    className = "HUNTER",
    action = "stop",
    description = "阿努巴拉克中虫转火+刺骨防御",
    checkFunction = AnubarakCheck,
})

-- ============================================================
-- 25. TOC Jaraxxus(加拉克苏斯) - 女王之吻 + 地狱火处理
--     来源：集成术士特化通用逻辑
--     猎人特化调整：
--       1) 女王之吻时停手(无光环掌握时)
--       2) 魔焰地狱火出现时转火处理
-- ============================================================
local function JaraxxusCheck()
    -- 1) 女王之吻时停手
    --    猎人没有光环掌握,但有闪避/生存本能
    if HasDebuff("player", "女王之吻") then
        local cid = ShowColor("stop", "女王之吻-停手使用闪避")
        return true, cid
    end
    
    -- 2) 魔焰地狱火出现时转火
    if UnitName("target") == "魔焰地狱火" then
        local cid = ShowColor("target", "地狱火-转火处理")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"加拉克苏斯大王", "Lord Jaraxxus", "TOC老二", "Jaraxxus"},
    className = "HUNTER",
    action = "stop",
    description = "Jaraxxus女王之吻+地狱火转火",
    checkFunction = JaraxxusCheck,
})


-- ============================================================
-- 26. 祖格-耶克里克 - 蝙蝠群AOE智能触发
--     来源：另外循环插件特化\术士\204FF6B1.lua（耶克里克.lua）
--     猎人特化调整：
--       1) 觅血蝙蝠≥3只时启用AOE模式
--       2) 主目标耶克里克，副目标蝙蝠参与TTD
-- ============================================================
local function JeklikCheck()
    -- 1) 蝙蝠群AOE检测
    local batCount = 0
    for i = 1, 40 do
        local name = C_NamePlate.GetNamePlateForUnitNumber(i):GetName():GetString()
        if name and string.find(name, "觅血蝙蝠") then
            batCount = batCount + 1
        end
    end
    
    if UnitName("target") == "高阶祭司耶克里克" and batCount >= 3 then
        local cid = ShowColor("aoe", "耶克里克-蝙蝠群AOE")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"高阶祭司耶克里克", "HighPriestessJeklik", "祖格耶克里克", "Jeklik"},
    className = "HUNTER",
    action = "aoe",
    description = "耶克里克蝙蝠群AOE智能触发",
    checkFunction = JeklikCheck,
})

-- ============================================================
-- 27. 祖格-曼多基尔 - 威慑凝视停手
--     来源：另外循环插件特化\术士\A320FFE3.lua（曼多基尔.lua）
--     猎人特化调整：
--       1) 威慑凝视读条/引导时立即停手
--       2) 凝视解除后恢复输出
-- ============================================================
local function MandokirCheck()
    -- 1) 威慑凝视停手
    if HasDebuff("player", "威慑凝视") then
        if UnitCastingInfo("player") or UnitChannelInfo("player") then
            local cid = ShowColor("stop", "曼多基尔-威慑凝视停手")
            return true, cid
        end
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"血领主曼多基尔", "BloodlordMandokir", "祖格曼多基尔", "Mandokir"},
    className = "HUNTER",
    action = "stop",
    description = "曼多基尔威慑凝视停手",
    checkFunction = MandokirCheck,
})

-- ============================================================
-- 28. 祖格-哈卡 - 灵魂吞噬处理 + 哈卡之子转火
--     来源：集成外部插件优化逻辑 + MY插件通用机制
--     猎人特化调整：
--       1) 灵魂吞噬debuff时停手
--       2) 哈卡之子指向转火提示
-- ============================================================
local HakkarSoulEatActive = false

local function HakkarCheck()
    -- 1) 灵魂吞噬停手
    if HasDebuff("player", "灵魂吞噬") then
        HakkarSoulEatActive = true
        local cid = ShowColor("stop", "哈卡-灵魂吞噬停手")
        return true, cid
    end
    
    -- 2) 哈卡之子转火提示
    local targetName = UnitName("target")
    if targetName == "哈卡之子" then
        local cid = ShowColor("target", "哈卡-哈卡之子转火")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"哈卡尔·灵魂掠夺者", "哈卡", "Hakkar", "ZG哈卡"},
    className = "HUNTER",
    action = "stop",
    description = "哈卡灵魂吞噬+哈卡之子转火",
    checkFunction = HakkarCheck,
})

-- ============================================================
-- 29. 祖格-温诺希斯 - 拉扎什眼镜蛇AOE处理
--     来源：另外循环插件特化\术士\B137416E.lua（温诺希斯.lua）
--     猎人特化调整：
--       1) 拉扎什眼镜蛇≥2只时启用智能AOE
--       2) 主目标温诺希斯，副目标蛇参与TTD和技能计数
-- ============================================================
local function VenoxisCheck()
    -- 1) 眼镜蛇AOE检测
    local snakeCount = 0
    for i = 1, 40 do
        local name = C_NamePlate.GetNamePlateForUnitNumber(i):GetName():GetString()
        if name and string.find(name, "拉扎什眼镜蛇") then
            snakeCount = snakeCount + 1
        end
    end
    
    if UnitName("target") == "高阶祭司温诺希斯" and snakeCount >= 2 then
        local cid = ShowColor("aoe", "温诺希斯-眼镜蛇AOE")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"高阶祭司温诺希斯", "Venoxis", "祖格温诺希斯", "Wushoolay"},
    className = "HUNTER",
    action = "aoe",
    description = "温诺希斯拉扎什眼镜蛇AOE",
    checkFunction = VenoxisCheck,
})

-- ============================================================
-- 30. 祖格-金度 - 妖术蝙蝠AOE + 放逐传送处理
--     来源：集成外部插件优化逻辑 (JindoBanishTeleport)
--     猎人特化调整：
--       1) 妖术蝙蝠群AOE触发
--       2) 放逐debuff时若魔法阵可用则传送解脱
-- ============================================================
local JindoBanished = false

local function JeklikBatAoe()
    local batCount = 0
    for i = 1, 40 do
        local name = C_NamePlate.GetNamePlateForUnitNumber(i):GetName():GetString()
        if name and string.find(name, "妖术蝙蝠") then
            batCount = batCount + 1
        end
    end
    return batCount
end

local function JindoCheck()
    -- 1) 妖术蝙蝠AOE
    if UnitName("target") == "妖术师金度" then
        local batCount = JindoBatAoe()
        if batCount >= 3 then
            local cid = ShowColor("aoe", "金度-妖术蝙蝠AOE")
            return true, cid
        end
    end
    
    -- 2) 放逐解脱
    if HasDebuff("player", "放逐") then
        JindoBanished = true
        -- 检查是否有恶魔法阵传送门可用
        if WR_SpellUsable("恶魔法阵", true) then
            local cid = ShowColor("teleport", "金度-放逐传送解脱")
            return true, cid
        end
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"妖术师金度", "Jeklik", "祖格金度", "Shirad"},
    className = "HUNTER",
    action = "stop",
    description = "金度妖术蝙蝠AOE+放逐传送",
    checkFunction = JindoCheck,
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

local function HunterKLGSCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"卡雷苟斯", "Kalecgos", "太阳井1号", "腐蚀者萨索瓦尔", "Sathrovarr"},
    className = "HUNTER",
    action = "stop",
    description = "卡雷苟斯-通用机制库(纯透传)",
    checkFunction = HunterKLGSCheck,
})

local function HunterBLTLCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"布鲁塔卢斯", "Brutallus", "太阳井2号"},
    className = "HUNTER",
    action = "stop",
    description = "布鲁塔卢斯-通用机制库(纯透传)",
    checkFunction = HunterBLTLCheck,
})

local function HunterFMSCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"菲米丝", "Felmyst", "太阳井3号"},
    className = "HUNTER",
    action = "stop",
    description = "菲米丝-通用机制库(纯透传)",
    checkFunction = HunterFMSCheck,
})

local function HunterTWINSCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"艾瑞达双子", "Eredar Twins", "Alythess", "Brannjar", "太阳井4号"},
    className = "HUNTER",
    action = "stop",
    description = "艾瑞达双子-通用机制库(纯透传)",
    checkFunction = HunterTWINSCheck,
})

local function HunterMURUCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"穆鲁", "M'uru", "Muru", "太阳井5号"},
    className = "HUNTER",
    action = "stop",
    description = "穆鲁-通用机制库(纯透传)",
    checkFunction = HunterMURUCheck,
})

local function HunterKJCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"基尔加丹", "Kil'jaeden", "Kiljaeden", "太阳井6号"},
    className = "HUNTER",
    action = "stop",
    description = "基尔加丹-通用机制库(纯透传)",
    checkFunction = HunterKJCheck,
})

local function HunterYWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"鹰王", "Akil'zon", "Akilzon", "艾基利松", "祖阿曼1号"},
    className = "HUNTER",
    action = "stop",
    description = "鹰王-通用机制库(纯透传)",
    checkFunction = HunterYWCheck,
})

local function HunterXWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"熊王", "Nalorakk", "纳洛拉克", "祖阿曼2号"},
    className = "HUNTER",
    action = "stop",
    description = "熊王-通用机制库(纯透传)",
    checkFunction = HunterXWCheck,
})

local function HunterLHYCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"龙鹰王", "Jan'alai", "Janalai", "贾恩阿拉伊", "祖阿曼3号"},
    className = "HUNTER",
    action = "stop",
    description = "龙鹰王-通用机制库(纯透传)",
    checkFunction = HunterLHYCheck,
})

local function HunterBWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"豹王", "Halazzi", "哈拉兹", "祖阿曼4号"},
    className = "HUNTER",
    action = "stop",
    description = "豹王-通用机制库(纯透传)",
    checkFunction = HunterBWCheck,
})

local function HunterYSLZCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"妖术领主", "Hex Lord Malacrass", "HexLord", "玛拉卡斯", "祖阿曼5号"},
    className = "HUNTER",
    action = "stop",
    description = "妖术领主-通用机制库(纯透传)",
    checkFunction = HunterYSLZCheck,
})

local function HunterZJCheck()
    if HasDebuff("player", "祖金的愤怒") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["stop"] or 3)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForHunter()
end

WR_Hunter_RegisterBoss({
    bossNames = {"祖金", "Zul'jin", "祖阿曼6号"},
    className = "HUNTER",
    action = "stop",
    description = "祖金-宁神射击解狂暴 / 通用兜底",
    checkFunction = HunterZJCheck,
})


-- ============================================================
-- 23. TOC双子 - 同色攻击处理 + 黑暗漩涡防御
--     来源：集成术士特化通用逻辑 + 外部插件优化
--     猎人特化调整：
--       1) 光明/黑暗Essence时提示切换目标
--       2) 黑暗漩涡出现时使用防御技能
-- ============================================================
local TwinsDarkVortexActive = false  -- 黑暗漩涡状态标记

local function TwinsCheck()
    -- 1) 同色攻击提示
    if HasDebuff("player", "光明 Essence") or HasDebuff("player", "黑暗 Essence") then
        local cid = ShowColor("target", "双子-同色攻击切换")
        return true, cid
    end
    
    -- 2) 黑暗漩涡防御
    --    光明Essence期间如果有黑暗漩涡,需要暗影防护
    if TwinsDarkVortexActive and HasDebuff("player", "光明 Essence") then
        local cid = ShowColor("defensive", "黑暗漩涡-暗影防护")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"光明邪使菲奥拉", "黑暗邪使艾蒂丝", "TOC双子", "Twins", "Fiery", "Adhis"},
    className = "HUNTER",
    action = "stop",
    description = "TOC双子同色攻击+黑暗漩涡",
    checkFunction = TwinsCheck,
})

-- ============================================================
-- 24. TOC阿努巴拉克 - 中虫刺骨寒冷处理
--     来源：集成术士特化通用逻辑
--     猎人特化调整：
--       1) 蛛魔掘地者(中虫)出现时转火
--       2) 刺骨寒冷debuff时使用防御技能
-- ============================================================
local function AnubarakCheck()
    local targetName = UnitName("target")
    
    -- 1) 中虫出现时提示转火
    if targetName == "蛛魔掘地者" then
        local cid = ShowColor("target", "阿努巴拉克-中虫转火")
        return true, cid
    end
    
    -- 2) 刺骨寒冷debuff时停手使用防御
    --    猎人没有生命分流,改用闪避/逃脱
    if HasDebuff("player", "刺骨寒冷") then
        local cid = ShowColor("defensive", "刺骨寒冷-使用闪避")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"阿努巴拉克", "Anubarak", "TOC老五"},
    className = "HUNTER",
    action = "stop",
    description = "阿努巴拉克中虫转火+刺骨防御",
    checkFunction = AnubarakCheck,
})

-- ============================================================
-- 25. TOC Jaraxxus(加拉克苏斯) - 女王之吻 + 地狱火处理
--     来源：集成术士特化通用逻辑
--     猎人特化调整：
--       1) 女王之吻时停手(无光环掌握时)
--       2) 魔焰地狱火出现时转火处理
-- ============================================================
local function JaraxxusCheck()
    -- 1) 女王之吻时停手
    --    猎人没有光环掌握,但有闪避/生存本能
    if HasDebuff("player", "女王之吻") then
        local cid = ShowColor("stop", "女王之吻-停手使用闪避")
        return true, cid
    end
    
    -- 2) 魔焰地狱火出现时转火
    if UnitName("target") == "魔焰地狱火" then
        local cid = ShowColor("target", "地狱火-转火处理")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"加拉克苏斯大王", "Lord Jaraxxus", "TOC老二", "Jaraxxus"},
    className = "HUNTER",
    action = "stop",
    description = "Jaraxxus女王之吻+地狱火转火",
    checkFunction = JaraxxusCheck,
})

-- ============================================================
-- ★ 统一入口（由 MainLoop 直接调用，无注册表中间件）
--   按当前目标名查本地派发表；命中则调用对应检查函数
--   太阳井(1-6号) 默认不触发（SW_BOSS_SPECIALS_OFF 守卫，用户只需输出循环）
-- ============================================================
function WR_Hunter_BossSpecials()
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


-- ============================================================
-- 26. 祖格-耶克里克 - 蝙蝠群AOE智能触发
--     来源：另外循环插件特化\术士\204FF6B1.lua（耶克里克.lua）
--     猎人特化调整：
--       1) 觅血蝙蝠≥3只时启用AOE模式
--       2) 主目标耶克里克，副目标蝙蝠参与TTD
-- ============================================================
local function JeklikCheck()
    -- 1) 蝙蝠群AOE检测
    local batCount = 0
    for i = 1, 40 do
        local name = C_NamePlate.GetNamePlateForUnitNumber(i):GetName():GetString()
        if name and string.find(name, "觅血蝙蝠") then
            batCount = batCount + 1
        end
    end
    
    if UnitName("target") == "高阶祭司耶克里克" and batCount >= 3 then
        local cid = ShowColor("aoe", "耶克里克-蝙蝠群AOE")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"高阶祭司耶克里克", "HighPriestessJeklik", "祖格耶克里克", "Jeklik"},
    className = "HUNTER",
    action = "aoe",
    description = "耶克里克蝙蝠群AOE智能触发",
    checkFunction = JeklikCheck,
})

-- ============================================================
-- 27. 祖格-曼多基尔 - 威慑凝视停手
--     来源：另外循环插件特化\术士\A320FFE3.lua（曼多基尔.lua）
--     猎人特化调整：
--       1) 威慑凝视读条/引导时立即停手
--       2) 凝视解除后恢复输出
-- ============================================================
local function MandokirCheck()
    -- 1) 威慑凝视停手
    if HasDebuff("player", "威慑凝视") then
        if UnitCastingInfo("player") or UnitChannelInfo("player") then
            local cid = ShowColor("stop", "曼多基尔-威慑凝视停手")
            return true, cid
        end
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"血领主曼多基尔", "BloodlordMandokir", "祖格曼多基尔", "Mandokir"},
    className = "HUNTER",
    action = "stop",
    description = "曼多基尔威慑凝视停手",
    checkFunction = MandokirCheck,
})

-- ============================================================
-- 28. 祖格-哈卡 - 灵魂吞噬处理 + 哈卡之子转火
--     来源：集成外部插件优化逻辑 + MY插件通用机制
--     猎人特化调整：
--       1) 灵魂吞噬debuff时停手
--       2) 哈卡之子指向转火提示
-- ============================================================
local HakkarSoulEatActive = false

local function HakkarCheck()
    -- 1) 灵魂吞噬停手
    if HasDebuff("player", "灵魂吞噬") then
        HakkarSoulEatActive = true
        local cid = ShowColor("stop", "哈卡-灵魂吞噬停手")
        return true, cid
    end
    
    -- 2) 哈卡之子转火提示
    local targetName = UnitName("target")
    if targetName == "哈卡之子" then
        local cid = ShowColor("target", "哈卡-哈卡之子转火")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"哈卡尔·灵魂掠夺者", "哈卡", "Hakkar", "ZG哈卡"},
    className = "HUNTER",
    action = "stop",
    description = "哈卡灵魂吞噬+哈卡之子转火",
    checkFunction = HakkarCheck,
})

-- ============================================================
-- 29. 祖格-温诺希斯 - 拉扎什眼镜蛇AOE处理
--     来源：另外循环插件特化\术士\B137416E.lua（温诺希斯.lua）
--     猎人特化调整：
--       1) 拉扎什眼镜蛇≥2只时启用智能AOE
--       2) 主目标温诺希斯，副目标蛇参与TTD和技能计数
-- ============================================================
local function VenoxisCheck()
    -- 1) 眼镜蛇AOE检测
    local snakeCount = 0
    for i = 1, 40 do
        local name = C_NamePlate.GetNamePlateForUnitNumber(i):GetName():GetString()
        if name and string.find(name, "拉扎什眼镜蛇") then
            snakeCount = snakeCount + 1
        end
    end
    
    if UnitName("target") == "高阶祭司温诺希斯" and snakeCount >= 2 then
        local cid = ShowColor("aoe", "温诺希斯-眼镜蛇AOE")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"高阶祭司温诺希斯", "Venoxis", "祖格温诺希斯", "Wushoolay"},
    className = "HUNTER",
    action = "aoe",
    description = "温诺希斯拉扎什眼镜蛇AOE",
    checkFunction = VenoxisCheck,
})

-- ============================================================
-- 30. 祖格-金度 - 妖术蝙蝠AOE + 放逐传送处理
--     来源：集成外部插件优化逻辑 (JindoBanishTeleport)
--     猎人特化调整：
--       1) 妖术蝙蝠群AOE触发
--       2) 放逐debuff时若魔法阵可用则传送解脱
-- ============================================================
local JindoBanished = false

local function JeklikBatAoe()
    local batCount = 0
    for i = 1, 40 do
        local name = C_NamePlate.GetNamePlateForUnitNumber(i):GetName():GetString()
        if name and string.find(name, "妖术蝙蝠") then
            batCount = batCount + 1
        end
    end
    return batCount
end

local function JindoCheck()
    -- 1) 妖术蝙蝠AOE
    if UnitName("target") == "妖术师金度" then
        local batCount = JindoBatAoe()
        if batCount >= 3 then
            local cid = ShowColor("aoe", "金度-妖术蝙蝠AOE")
            return true, cid
        end
    end
    
    -- 2) 放逐解脱
    if HasDebuff("player", "放逐") then
        JindoBanished = true
        -- 检查是否有恶魔法阵传送门可用
        if WR_SpellUsable("恶魔法阵", true) then
            local cid = ShowColor("teleport", "金度-放逐传送解脱")
            return true, cid
        end
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForHunter()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Hunter_RegisterBoss({
    bossNames = {"妖术师金度", "Jeklik", "祖格金度", "Shirad"},
    className = "HUNTER",
    action = "stop",
    description = "金度妖术蝙蝠AOE+放逐传送",
    checkFunction = JindoCheck,
})

