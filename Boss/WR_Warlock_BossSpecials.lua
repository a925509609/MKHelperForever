-- ============================================================
-- WR_Warlock_BossSpecials.lua
-- 术士职业 BOSS 特化逻辑
-- 法系远程DPS (ROLE_RANGED_CASTER_DPS)，无坦克/治疗
--
-- 架构：
--   1. 优先使用 WR_BossMechanics 配置中的机制，按法系远程DPS筛选
--   2. 补充术士特有强化检查（如血议会黑暗之核双重验证）
--   3. 直接用 WR_ColorFrame_Show 显示颜色
--   4. 通过 WR_Warlock_RegisterBoss() 注册每个 BOSS
--
-- 颜色映射：stop=3, target=4, defensive=8, rocketboots=108, lk_contamination=107
--
-- 关注的 BOSS 特化：
--   1. 冰龙辛达苟萨 - 刺骨≥3停读条、冰封停手、反魔法护盾停手省蓝
--   2. 血议会 - 过滤黑暗之核(法系不能打，强化双重验证)
--   3. 灵魂熔炉 - 灵魂倒映停手
--   4. 巫妖王 - 污染停手
--   5. 教授普崔希德 - 软泥怪停手
--   6. 海里昂 - 低血量火箭靴
--   7. 血女王 - 鲜血镜像
--   8. 腐面/烂肠 - 突变停手
--   9. 观察者奥尔加隆 - 星尘阶段停手
--  10. 尤格萨隆 - 精神控制停手
--  11. 翡翠巨龙 - 燃烧之血停手省蓝
--  12. 炮舰 - 火箭靴
--  13. 萨鲁法尔 - 法系无需处理保护之手
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

if select(2, UnitClass("player")) ~= "WARLOCK" then
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
local function WR_Warlock_RegisterBoss(spec)
    if not spec or not spec.bossNames or not spec.checkFunction then return end
    local isSW = SW_BOSS_NAMES[spec.bossNames[1]] or false
    for _, name in ipairs(spec.bossNames) do
        BOSS_SPECIALS_BY_NAME[name] = { checkFunction = spec.checkFunction, isSW = isSW }
    end
end


-- ============================================================
-- 角色类型：术士始终为法系远程DPS
-- ============================================================
local PLAYER_ROLE = WR_BossMechanics.ROLE_RANGED_CASTER_DPS

-- ============================================================
-- 共享工具（来自 WR_BossUtils，避免重复定义）
-- ============================================================
local GetDebuffCount = WR_BossUtils.GetDebuffCount
local GetBuffCount = WR_BossUtils.GetBuffCount
local HasBuff = WR_BossUtils.HasBuff
local HasDebuff = WR_BossUtils.HasDebuff
local ColorMap = WR_BossUtils.ColorMap
local ShowColor = WR_BossUtils.ShowColor

-- ============================================================
-- 核心：从 WR_BossMechanics 配置中按法系远程DPS筛选机制
-- 返回：true, colorID 或 false
-- ============================================================
local function CheckBossMechanicsForWarlock()
    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        return false
    end

    local bossData = WR_BossUtils.FindBossData(targetName)
    if not bossData or not bossData.mechanisms then
        return false
    end

    for _, mech in ipairs(bossData.mechanisms) do
        if WR_CheckRoleApplicable and WR_CheckRoleApplicable(mech, PLAYER_ROLE) then
            if mech.checkFunction and mech.checkFunction() then
                local colorID = ColorMap[mech.action] or mech.colorID or 3
                local desc = mech.description or mech.name or targetName
                -- 术士特化描述：反魔法护盾时提示省蓝
                if mech.name == "反魔法护盾" or mech.name == "法系BOSS护盾停手" then
                    desc = "反魔法护盾-法系停手省蓝"
                end
                WR_ColorFrame_Show(colorID, desc)
                return true, colorID
            end
        end
    end

    return false
end

-- ============================================================
-- 术士强化检查：血议会黑暗之核双重验证
--   目标名匹配 + BOSS/目标有相关buff双重验证
-- ============================================================
local function WarlockEnhancedDarkCoreCheck()
    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        return false
    end

    -- 目标名为黑暗之核
    if targetName == "黑暗之核" then
        local cid = ShowColor("stop", "法系-黑暗之核吸收魔法，停手")
        return true, cid
    end
    -- 额外检查：目标是否有黑暗之核相关buff（防止名字翻译/别名问题）
    if HasBuff("target", "黑暗之核") or HasDebuff("target", "黑暗之核") then
        local cid = ShowColor("stop", "法系-目标有黑暗之核，停手")
        return true, cid
    end

    return false
end

-- ============================================================
-- 1. 冰龙辛达苟萨 - 刺骨停读条 + 狂咒停手 + 秘法打击传送
--    来源：另外循环插件特化\术士\A294491F.lua（巫妖王冰龙.lua）
--    功能：
--      1) 刺骨debuff计数≥N停手（法系停读条）
--      2) 狂咒（反魔法护盾）停手省蓝
--      3) 秘法打击层数低时传送
--      4) 冰封停手
-- ============================================================
local function SindragosaCheck()
    -- 1) 刺骨debuff计数停手（从PigSet读取阈值，默认3）
    local chilledCount = GetDebuffCount("player", "寒霜刺骨")
    local HSCG = PigSet and PigSet.WQZ_HSCG or 3
    if HSCG ~= 7 and chilledCount >= HSCG then
        local cid = ShowColor("stop", "冰龙刺骨停手(法系停读条)")
        return true, cid
    end
    
    -- 2) 狂咒（反魔法护盾）停手省蓝
    --    来源：术士特化中 decisionMainList.map.sb.suspend = true
    if HasDebuff("player", "反魔法护盾") then
        local cid = ShowColor("defensive", "狂咒停手-法系停读条省蓝")
        return true, cid
    end
    
    -- 3) 冰封停手
    if HasDebuff("player", "冰封") then
        local cid = ShowColor("stop", "冰龙冰封停手")
        return true, cid
    end
    
    -- 4) 秘法打击传送（剩余时间<1.9秒且无狂咒时）
    --    来源：术士特化中 player.debuff.mysticBuffet.left < 1.9
    if HasDebuff("player", "秘法打击") then
        local buffetLeft = WR_GetUnitDebuffTime("player", "秘法打击")
        if buffetLeft and buffetLeft < 1.9 and not HasDebuff("player", "反魔法护盾") then
            local cid = ShowColor("rocketboots", "秘法打击-传送")
            return true, cid
        end
    end
    
    -- 5) 通用Boss机制检查（从WR_BossMechanics配置中筛选）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"辛达苟萨", "Sindragosa", "冰霜女王"},
    className = "WARLOCK",
    action = "stop",
    description = "冰龙刺骨≥3停手+狂咒停手+秘法打击传送",
    checkFunction = SindragosaCheck,
})

-- ============================================================
-- 2. 血议会 - 强化黑暗之核过滤(法系不能打)
-- ============================================================
local function BloodCouncilCheck()
    -- 术士强化检查优先
    local triggered, overrideColor = WarlockEnhancedDarkCoreCheck()
    if triggered then
        return true, overrideColor
    end

    triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    local targetName = UnitName("target")
    if targetName == "动力炸弹" then
        local cid = ShowColor("stop", "过滤动力炸弹")
        return true, cid
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"血议会", "鲜血议会", "Blood Council"},
    className = "WARLOCK",
    action = "stop",
    description = "血议会过滤黑暗之核",
    checkFunction = BloodCouncilCheck,
})

-- ============================================================
-- 3. 灵魂熔炉 - 灵魂倒映停手
-- ============================================================
local function ForgeOfSoulsCheck()
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
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

WR_Warlock_RegisterBoss({
    bossNames = {"灵魂熔炉", "锻造之魂", "Forge of Souls"},
    className = "WARLOCK",
    action = "stop",
    description = "灵魂熔炉停手",
    checkFunction = ForgeOfSoulsCheck,
})

-- ============================================================
-- 4. 教授普崔希德 - 软泥怪停手 + 毒气计时停手
--    来源：另外循环插件特化\术士\B6699804.lua（巫妖王教授.lua）
--    功能：
--      1) 软泥怪（红软/绿软）目标停手
--      2) 毒气debuff 4.1-4.9秒时停手（避免打断施法）
--      3) 催泪毒气停手
-- ============================================================
local PutricideGasStartTime = nil  -- 毒气开始时间

local function PutricideCheck()
    local targetName = UnitName("target")
    
    -- 1) 软泥怪目标停手（红软/绿软）
    --    来源：术士特化中 targetInfo.name == "不稳定的软泥怪" or "毒气之云"
    if targetName == "不稳定的软泥怪" or targetName == "毒气之云" then
        local cid = ShowColor("stop", "教授软泥怪停手")
        return true, cid
    end
    
    -- 2) 毒气debuff计时停手（4.1-4.9秒）
    --    来源：术士特化中 gasVariable debuff 持续 4.1~4.9 秒，已暂停技能
    local gasDebuff = HasDebuff("player", "毒气变异") or HasDebuff("player", "软泥变异")
    if gasDebuff then
        if not PutricideGasStartTime then
            PutricideGasStartTime = GetTime()
        end
        local gasDuration = GetTime() - PutricideGasStartTime
        if gasDuration >= 4.1 and gasDuration <= 4.9 then
            local cid = ShowColor("stop", "毒气4.1-4.9秒停手")
            return true, cid
        end
    else
        PutricideGasStartTime = nil
    end
    
    -- 3) 催泪毒气停手
    if HasDebuff("player", "催泪毒气") then
        local cid = ShowColor("stop", "催泪毒气停手")
        return true, cid
    end
    
    -- 4) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"普崔塞德教授", "Professor Putricide", "Putricide"},
    className = "WARLOCK",
    action = "stop",
    description = "教授软泥停手+毒气计时停手",
    checkFunction = PutricideCheck,
})

-- ============================================================
-- 5. 巫妖王 - 污染停手 + 瓦格里处理 + 灵魂收割
--    来源：另外循环插件特化\术士\BD8102FB.lua（巫妖王灵魂.lua）
--    功能：
--      1) 污染停手+立刻跑+火箭靴
--      2) 瓦格里暗影戒卫者处理（种子/停手）
--      3) 灵魂收割阶段停手
--      4) 卑劣的灵魂过滤
-- ============================================================
local LKHarvestSoulActive = false  -- 灵魂收割状态

local function LKCheck()
    local targetName = UnitName("target")
    
    -- 1) 污染停手+立刻跑
    --    来源：术士特化中 insertTimeoutSkill("火箭靴") + setAction2("startMove")
    if HasDebuff("player", "污染") then
        local cid = ShowColor("lk_contamination", "污染停手立刻跑")
        return true, cid
    end
    
    -- 2) 瓦格里暗影戒卫者处理
    --    来源：术士特化中 targetInfo.name == "瓦格里暗影戒卫者"
    if targetName == "瓦格里暗影戒卫者" then
        local cid = ShowColor("target", "瓦格里-种子处理")
        return true, cid
    end
    
    -- 3) 灵魂收割阶段停手（英雄模式）
    --    来源：术士特化中 player.debuff.harvestSoul.exist
    if HasDebuff("player", "收割灵魂") then
        LKHarvestSoulActive = true
        local cid = ShowColor("stop", "灵魂收割停手")
        return true, cid
    else
        LKHarvestSoulActive = false
    end
    
    -- 4) 卑劣的灵魂过滤
    --    来源：术士特化中 noScoreMob["卑劣的灵魂"] = true
    if targetName == "卑劣的灵魂" then
        local cid = ShowColor("stop", "卑劣的灵魂过滤")
        return true, cid
    end
    
    -- 5) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"巫妖王", "The Lich King", "LK", "阿尔萨斯"},
    className = "WARLOCK",
    action = "lk_contamination",
    description = "巫妖王污染停手+瓦格里处理+灵魂收割",
    checkFunction = LKCheck,
})

-- ============================================================
-- 6. 海里昂 - 低血量火箭靴
-- ============================================================
local function HalionCheck()
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    local hp = WR_BossUtils.GetPlayerHP()
    if hp < 30 then
        local cid = ShowColor("rocketboots", "海里昂火箭靴")
        return true, cid
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"海里昂", "Halion"},
    className = "WARLOCK",
    action = "rocketboots",
    description = "海里昂火箭靴",
    checkFunction = HalionCheck,
})

-- ============================================================
-- 7. 血女王 - 鲜血镜像停手 + 恐惧解除
--    来源：另外循环插件特化\术士\AB17AD4B.lua（巫妖王鲜血女王.lua）
--    功能：
--      1) 鲜血镜像/鲜血烙印停手
--      2) 煽动惊恐时解除恐惧
--      3) 蜂拥之影自动跑路
-- ============================================================
local function BloodQueenCheck()
    -- 1) 鲜血镜像/鲜血烙印停手
    if HasDebuff("player", "鲜血镜像") or HasDebuff("player", "鲜血烙印") then
        local cid = ShowColor("stop", "血女王镜像停手")
        return true, cid
    end
    
    -- 2) 煽动惊恐时解除恐惧
    --    来源：术士特化中 player.debuff.inciteTerror.exist
    if HasDebuff("player", "煽动惊恐") then
        local cid = ShowColor("defensive", "煽动惊恐-解除恐惧")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"鲜血女王兰娜瑟尔", "Blood-Queen Lana'thel", "血女王"},
    className = "WARLOCK",
    action = "stop",
    description = "血女王镜像停手+恐惧解除",
    checkFunction = BloodQueenCheck,
})

-- ============================================================
-- 8. 腐面/烂肠 - 突变停手 + 孢子男特化
--    来源：另外循环插件特化\术士\F4A663D0.lua（孢子男.lua - 洛欧塞布）
--    功能：
--      1) 突变/气体云停手
--      2) 死疽debuff时禁止移动生命分流
--      3) 真菌蠕动buff时自动传送到安全位置
-- ============================================================
local function MutantCheck()
    -- 1) 突变/气体云停手
    if HasDebuff("player", "突变") or HasDebuff("player", "气体云") then
        local cid = ShowColor("stop", "突变停手")
        return true, cid
    end
    
    -- 2) 死疽debuff时禁止移动生命分流
    --    来源：术士特化中 player.debuff.necrotic.exist
    if HasDebuff("player", "死疽") then
        local cid = ShowColor("stop", "死疽-禁止移动生命分流")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"腐面", "Festergut", "烂肠", "Rotface"},
    className = "WARLOCK",
    action = "stop",
    description = "腐面/烂肠突变停手+死疽禁止分流",
    checkFunction = MutantCheck,
})

-- ============================================================
-- 8.5 玛洛加尔领主 - 骨针种子 + 白骨风暴停手
--     来源：另外循环插件特化\术士\2E742925.lua（巫妖王老一骨针.lua）
--     功能：
--       1) 骨针出现时提示种子
--       2) 白骨风暴时停手
-- ============================================================
local MarrowgarWhirlwindActive = false  -- 白骨风暴状态

local function MarrowgarCheck()
    local targetName = UnitName("target")
    
    -- 1) 骨针出现时提示种子
    --    来源：术士特化中 seedBoneSpike
    if targetName == "骨针" then
        local cid = ShowColor("target", "骨针-种子处理")
        return true, cid
    end
    
    -- 2) 白骨风暴时停手
    --    来源：术士特化中 whirlwind845
    if MarrowgarWhirlwindActive then
        local cid = ShowColor("stop", "白骨风暴停手")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"玛洛加尔领主", "Lord Marrowgar", "玛洛加尔"},
    className = "WARLOCK",
    action = "stop",
    description = "玛洛加尔骨针种子+白骨风暴停手",
    checkFunction = MarrowgarCheck,
})

-- ============================================================
-- 9. 观察者奥尔加隆 - 大爆炸停厄运 + 坍缩星暗影防护
--    来源：另外循环插件特化\术士\000D60AA.lua（修星.lua）
--    功能：
--      1) 大爆炸前停止厄运诅咒（避免浪费GCD）
--      2) 坍缩星血量低时暗影防护
-- ============================================================
local AlgalonBeforeBigBang = true  -- 大爆炸前状态

local function AlgalonCheck()
    -- 1) 大爆炸前停手提示（暂停DOT）
    --    来源：术士特化中 beforeFirstBigBang → decisionDemoList.map.doom.suspend = true
    --    注意：完整修星逻辑属于循环层，此处只做停手提示
    
    -- 2) 坍缩星血量低时暗影防护
    --    来源：术士特化中 config.AlgalonShadowWard + "坍缩星血量低"
    if HasDebuff("player", "坍缩之星") then
        local cid = ShowColor("defensive", "坍缩星-暗影防护")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"观察者奥尔加隆", "Algalon the Observer", "奥尔加隆", "Algalon"},
    className = "WARLOCK",
    action = "stop",
    description = "奥尔加隆坍缩星暗影防护+大爆炸管理",
    checkFunction = AlgalonCheck,
})

-- ============================================================
-- 10. 尤格萨隆 - 精神控制停手 + 暗影屏障过滤 + 转身机制
--     来源：另外循环插件特化\术士\43CF22BE.lua（尤克萨隆.lua）
--     功能：
--       1) 精神控制/心灵牢笼停手
--       2) 暗影屏障目标过滤（不打）
--       3) 理智值低时停止面向施法
--       4) 震耳咆哮时停手
-- ============================================================
local YoggSanityLow = false  -- 理智值低状态

local function YoggCheck()
    local targetName = UnitName("target")
    
    -- 1) 精神控制/心灵牢笼停手
    if HasDebuff("player", "精神控制") or HasDebuff("player", "心灵牢笼") then
        local cid = ShowColor("stop", "尤格萨隆精神控制停手")
        return true, cid
    end
    
    -- 2) 震耳咆哮时停手
    --    来源：术士特化中 player.debuff.deafeningRoar.exist
    if HasDebuff("player", "震耳咆哮") then
        local cid = ShowColor("stop", "震耳咆哮停手")
        return true, cid
    end
    
    -- 3) 暗影屏障目标过滤
    --    来源：术士特化中 u.buff.shadowyBarrier.exist → u.noAttack = true
    if targetName == "尤格萨隆的触手" or targetName == "腐蚀触须" or targetName == "重压触须" then
        local cid = ShowColor("stop", "尤格萨隆触手过滤")
        return true, cid
    end
    
    -- 4) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"尤格萨隆", "Yogg-Saron", "Yogg", "尤格萨隆的触手"},
    className = "WARLOCK",
    action = "stop",
    description = "尤格萨隆精神控制停手+触手过滤+震耳咆哮",
    checkFunction = YoggCheck,
})

-- ============================================================
-- 11. 翡翠巨龙 - 燃烧之血/沉睡停手省蓝
-- ============================================================
local function DragonCheck()
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
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

WR_Warlock_RegisterBoss({
    bossNames = {"翡翠巨龙", "绯红巨龙守护者", "Valithria"},
    className = "WARLOCK",
    action = "stop",
    description = "巨龙特殊处理",
    checkFunction = DragonCheck,
})

-- ============================================================
-- 12. 炮舰 - 火箭靴
-- ============================================================
local function GunshipCheck()
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    local targetName = UnitName("target")
    if targetName == "炮舰" then
        local hp = WR_BossUtils.GetPlayerHP()
        if hp < 30 then
            local cid = ShowColor("rocketboots", "炮舰火箭靴")
            return true, cid
        end
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"炮舰", "天界飞船", "Gunship"},
    className = "WARLOCK",
    action = "rocketboots",
    description = "炮舰火箭靴",
    checkFunction = GunshipCheck,
})

-- ============================================================
-- 13. 萨鲁法尔 - 法系无需处理保护之手 + 血兽转火提示
--     来源：另外循环插件特化\术士\08B950D4.lua（巫妖王萨鲁法尔.lua）
--     功能：
--       1) 法系无需取消保护之手（物理免疫不影响法系）
--       2) 血兽出现时提示撒DOT
-- ============================================================
local SaurfangBloodBeastActive = false  -- 血兽状态

local function SaurfangCheck()
    local targetName = UnitName("target")
    
    -- 1) 血兽出现时提示
    --    来源：术士特化中检测到召唤血兽时开撒腐蚀
    if targetName == "血兽" then
        SaurfangBloodBeastActive = true
        local cid = ShowColor("target", "血兽-撒腐蚀")
        return true, cid
    else
        SaurfangBloodBeastActive = false
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"死亡使者萨鲁法尔", "Deathbringer Saurfang", "萨鲁法尔"},
    className = "WARLOCK",
    action = "stop",
    description = "萨鲁法尔法系特化+血兽转火",
    checkFunction = SaurfangCheck,
})

-- ============================================================
-- 14. TOC双子 - 同色攻击 + 暗影防护 + 恶魔法阵
--     来源：另外循环插件特化\术士\DBF81AB6.lua（TOC双子.lua）
--     功能：
--       1) 同色攻击提示（光明/黑暗 Essence）
--       2) 黑暗漩涡时暗影防护
--       3) 恶魔法阵传送提示
-- ============================================================
local TwinsDarkVortexActive = false  -- 黑暗漩涡状态

local function TwinsCheck()
    -- 1) 同色攻击提示
    --    来源：术士特化中 player.debuff.lightEssence/darkEssence
    if HasDebuff("player", "光明 Essence") or HasDebuff("player", "黑暗 Essence") then
        local cid = ShowColor("target", "双子-同色攻击")
        return true, cid
    end
    
    -- 2) 黑暗漩涡时暗影防护
    --    来源：术士特化中 darkVortex641
    if TwinsDarkVortexActive and HasDebuff("player", "光明 Essence") then
        local cid = ShowColor("defensive", "黑暗漩涡-暗影防护")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"光明邪使菲奥拉", "黑暗邪使艾蒂丝", "TOC双子", "Twins"},
    className = "WARLOCK",
    action = "stop",
    description = "TOC双子同色攻击+暗影防护",
    checkFunction = TwinsCheck,
})

-- ============================================================
-- 15. TOC阿努巴拉克 - 中虫种子 + 刺骨低级技能
--     来源：另外循环插件特化\术士\974C0528.lua（TOC阿努巴拉克.lua）
--     功能：
--       1) 蛛魔掘地者（中虫）出现时提示种子
--       2) 刺骨debuff时使用低级生命分流
-- ============================================================
local function AnubarakCheck()
    local targetName = UnitName("target")
    
    -- 1) 中虫出现时提示种子
    --    来源：术士特化中 seed 蛛魔掘地者
    if targetName == "蛛魔掘地者" then
        local cid = ShowColor("target", "中虫-种子处理")
        return true, cid
    end
    
    -- 2) 刺骨debuff时使用低级生命分流
    --    来源：术士特化中 player.debuff.penetratingCold.exist
    if HasDebuff("player", "刺骨寒冷") then
        local cid = ShowColor("stop", "刺骨-使用低级生命分流")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"阿努巴拉克", "Anubarak", "TOC老五"},
    className = "WARLOCK",
    action = "stop",
    description = "阿努巴拉克中虫种子+刺骨低级分流",
    checkFunction = AnubarakCheck,
})

-- ============================================================
-- 16. TOC Jaraxxus - 女王之吻 + 地狱火跟踪
--     来源：另外循环插件特化\术士\8E2F6BF1.lua（TOC老二.lua）
--     功能：
--       1) 女王之吻时停手（无光环掌握时）
--       2) 魔焰地狱火出现时提示
-- ============================================================
local function JaraxxusCheck()
    local targetName = UnitName("target")
    
    -- 1) 女王之吻时停手
    --    来源：术士特化中 player.debuff.mistressKiss.exist
    if HasDebuff("player", "女王之吻") and not HasBuff("player", "光环掌握") then
        local cid = ShowColor("stop", "女王之吻-停手")
        return true, cid
    end
    
    -- 2) 魔焰地狱火出现时提示
    --    来源：术士特化中 first inferno / second inferno
    if targetName == "魔焰地狱火" then
        local cid = ShowColor("target", "地狱火-转火处理")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"加拉克苏斯大王", "Lord Jaraxxus", "TOC老二", "Jaraxxus"},
    className = "WARLOCK",
    action = "stop",
    description = "Jaraxxus女王之吻+地狱火转火",
    checkFunction = JaraxxusCheck,
})

-- ============================================================
-- 17. 弗蕾雅 - 大地震颤停手 + 蘑菇腐蚀提示
--     来源：另外循环插件特化\术士\43CF22BE.lua（奥杜尔芙蕾雅.lua）
--     功能：
--       1) 大地震颤时停手（1.6秒后停施法）
--       2) 蘑菇buff时提示对弗蕾雅撒腐蚀
--       3) 第二阶段前暂停种子
-- ============================================================
local function FreyaCheck()
    -- 1) 大地震颤停手
    --    来源：术士特化中 dbmTimerStart cd 62859 → setAction2("stopCasting")
    if HasDebuff("player", "大地震颤") then
        local cid = ShowColor("stop", "弗蕾雅大地震震颤停手")
        return true, cid
    end
    
    -- 2) 蘑菇buff时提示对弗蕾雅撒腐蚀
    --    来源：术士特化中 player.buff.mushroom.exist → spam corruption on 弗蕾雅
    if HasBuff("player", "自然之力") then
        local targetName = UnitName("target")
        if targetName ~= "弗蕾雅" then
            local cid = ShowColor("target", "蘑菇buff-撒腐蚀弗蕾雅")
            return true, cid
        end
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"弗蕾雅", "Freya", "奥杜尔弗蕾雅"},
    className = "WARLOCK",
    action = "stop",
    description = "弗蕾雅大地震震颤停手+蘑菇腐蚀",
    checkFunction = FreyaCheck,
})

-- ============================================================
-- 18. 铁议会 - 双光环腐蚀术 + 符文力量停手
--     来源：另外循环插件特化\术士\F3287AEC.lua（奥杜尔议会.lua）
--     功能：
--       1) 符文力量debuff≥2层时提示撒腐蚀
--       2) 电力符文目标过滤
-- ============================================================
local function IronCouncilCheck()
    -- 1) 符文力量debuff计数
    --    来源：术士特化中 runeOfPower计数 ≥2 → spam corruption
    local runeCount = GetDebuffCount("player", "符文力量")
    if runeCount >= 2 then
        local cid = ShowColor("target", "双光环-撒腐蚀")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"断钢者", "符文大师莫尔基姆", "唤雷者布隆迪尔", "Iron Council", "铁议会"},
    className = "WARLOCK",
    action = "stop",
    description = "铁议会双光环腐蚀术+符文力量",
    checkFunction = IronCouncilCheck,
})

-- ============================================================
-- 19. 科隆加恩 - 三目标管理提示
--     来源：另外循环插件特化\术士\5D23ADB2.lua（奥杜尔科隆加恩.lua）
--     功能：
--       1) 提示焦点右臂+宠物左臂的三目标设置
--       2) 右臂/左臂过滤（死亡后不再计分）
-- ============================================================
local function KologarnCheck()
    local targetName = UnitName("target")
    
    -- 1) 右臂/左臂出现时提示
    --    来源：术士特化中 KologarnAuto3 → kologarnTarget3
    if targetName == "右臂" or targetName == "左臂" then
        local cid = ShowColor("target", "科隆加恩-手臂管理")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"科隆加恩", "Kologarn"},
    className = "WARLOCK",
    action = "stop",
    description = "科隆加恩三目标管理",
    checkFunction = KologarnCheck,
})

-- ============================================================
-- 20. XT002拆解之心 - 炸弹人种子 + 重力炸弹传送
--     来源：另外循环插件特化\术士\4FEB707C.lua（奥杜尔拆解之心.lua）
--     功能：
--       1) XE-321爆破机器人出现时提示种子
--       2) 重力炸弹debuff消失时提示传送
-- ============================================================
local function XT002Check()
    local targetName = UnitName("target")
    
    -- 1) 炸弹人出现时提示种子
    --    来源：术士特化中 config.XT002FocusBomber + seedBomber
    if targetName == "XE-321爆破机器人" then
        local cid = ShowColor("target", "拆解之心-炸弹人种子")
        return true, cid
    end
    
    -- 2) 重力炸弹debuff时提示
    --    来源：术士特化中 player.debuff.gravityBomb.exist → shadowWard
    if HasDebuff("player", "重力炸弹") then
        local cid = ShowColor("defensive", "重力炸弹-防护结界")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"拆解者之心", "XT002", "奥杜尔XT002"},
    className = "WARLOCK",
    action = "stop",
    description = "XT002炸弹人种子+重力炸弹防护",
    checkFunction = XT002Check,
})

-- ============================================================
-- 21. 米米尔隆 - 烈焰遏制不断条 + 灭火机器人过滤
--     来源：另外循环插件特化\术士\7E169FC1.lua（灭火机器人.lua）
--     功能：
--       1) 烈焰遏制debuff时提示用吸取灵魂不断条
--       2) 紧急灭火机器人目标过滤
-- ============================================================
local function MimironCheck()
    local targetName = UnitName("target")
    
    -- 1) 烈焰遏制debuff时提示吸取灵魂不断条
    --    来源：术士特化中 player.debuff.flameSuppressant.exist + drainSoulOnTheFly
    --    → noClipDs = true（吸取灵魂不断条）
    if HasDebuff("player", "烈焰遏制") then
        local cid = ShowColor("stop", "米米尔隆烈焰遏制-吸取灵魂不断条")
        return true, cid
    end
    
    -- 2) 紧急灭火机器人目标过滤
    --    来源：术士特化中 noScoreMob["紧急灭火机器人"] = true
    if targetName == "紧急灭火机器人" then
        local cid = ShowColor("stop", "灭火机器人-不打分")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"米米尔隆", "Mimiron", "奥杜尔米米尔隆"},
    className = "WARLOCK",
    action = "stop",
    description = "米米尔隆烈焰遏制不断条+灭火机器人过滤",
    checkFunction = MimironCheck,
})

-- ============================================================
-- 22. 维扎克斯 - 暗影冲击停手 + 无面印记传送
--     来源：另外循环插件特化\术士\B2B75F55.lua（维扎克斯.lua）
--     功能：
--       1) 暗影冲击debuff时停手（禁止生命分流）
--       2) 无面印记剩余≥8秒时提示传送
-- ============================================================
local function VezaxCheck()
    -- 1) 暗影冲击debuff时停手
    --    来源：术士特化中 disableLifeTap = true + player.debuff.shadowCrash.exist
    if HasDebuff("player", "暗影冲击") then
        local cid = ShowColor("stop", "维扎克斯暗影冲击-停手禁分流")
        return true, cid
    end
    
    -- 2) 无面印记传送提示
    --    来源：术士特化中 player.debuff.markOfTheFaceless.left >= 8 + teleport
    if HasDebuff("player", "无面印记") then
        local markLeft = WR_GetUnitDebuffTime("player", "无面印记")
        if markLeft and markLeft >= 8 then
            local cid = ShowColor("rocketboots", "无面印记-传送")
            return true, cid
        end
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"维扎克斯将军", "General Vezax", "维扎克斯", "Vezax"},
    className = "WARLOCK",
    action = "stop",
    description = "维扎克斯暗影冲击停手+无面印记传送",
    checkFunction = VezaxCheck,
})

-- ============================================================
-- 23. 血领主曼多基尔（祖格） - 威慑凝视停手
--     来源：另外循环插件特化\术士\A320FFE3.lua（祖格停手.lua）
--     功能：
--       1) 被威慑凝视时立即停手（读条/引导中断）
--       2) 防止新的施法直到凝视解除
-- ============================================================
local function MandokirCheck()
    -- 1) 威慑凝视停手
    --    来源：术士特化中 player.debuff.intimidatingGaze.exist
    --    → stopCasting if reading/channeling, else prevent new cast
    if HasDebuff("player", "威慑凝视") then
        local cid = ShowColor("stop", "曼多基尔威慑凝视停手")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"血领主曼多基尔", "Bloodlord Mandokir", "祖格曼多基尔"},
    className = "WARLOCK",
    action = "stop",
    description = "曼多基尔威慑凝视停手",
    checkFunction = MandokirCheck,
})

-- ============================================================
-- 24. 高阶祭司温诺希斯（祖格） - 眼镜蛇AOE提示
--     来源：另外循环插件特化\术士\B137416E.lua（祖格祭司.lua）
--     功能：
--       1) 场上拉扎什眼镜蛇≥2只时提示智能AOE
--       2) 主目标温诺希斯，副目标蛇
-- ============================================================
local function VenoxisCheck()
    -- 1) 蛇群AOE提示
    --    来源：术士特化中 VenoxisSnakeAoe + P("拉扎什眼镜蛇") >= 2
    --    → setDestAoeProfile(温诺希斯主目标+蛇副目标)
    local targetName = UnitName("target")
    if targetName == "高阶祭司温诺希斯" then
        -- 计算场上蛇的数量（简化版，遍历名字面板前20个）
        local snakeCount = 0
        local nameplates = C_NamePlate.GetNamePlates()
        if nameplates then
            for i = 1, math.min(#nameplates, 20) do
                local unitToken = nameplates[i].unitToken
                if unitToken then
                    local name = UnitName(unitToken)
                    if name == "拉扎什眼镜蛇" and IsUnitInRange(unitToken, "player") then
                        snakeCount = snakeCount + 1
                    end
                end
            end
        end
        
        if snakeCount >= 2 then
            local cid = ShowColor("aoe", "温诺希斯-蛇群AOE")
            return true, cid
        end
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"高阶祭司温诺希斯", "High Priest Venoxis", "祖格温诺希斯"},
    className = "WARLOCK",
    action = "stop",
    description = "温诺希斯眼镜蛇AOE提示",
    checkFunction = VenoxisCheck,
})

-- ============================================================
-- 25. 哈卡（祖格） - 哈卡之子指向转火
--     来源：另外循环插件特化\术士\79441B25.lua（哈卡之子.lua）
--     功能：
--       1) 哈卡之子出现时过滤（不打）
--       2) 鼠标指向哈卡之子时转火撒DOT
-- ============================================================
local function HakkarCheck()
    local targetName = UnitName("target")
    
    -- 1) 哈卡之子过滤
    --    来源：术士特化中 noScoreMob["哈卡之子"] = true
    if targetName == "哈卡之子" then
        local cid = ShowColor("stop", "哈卡之子-不打分")
        return true, cid
    end
    
    -- 2) 哈卡之子指向转火（如果有鼠标指向）
    --    来源：术士特化中 HakkarSonRedirect + mouseInfo.name == "哈卡之子"
    --    → corruptionmouseover / immomouseover
    local mouseTarget = UnitName("mouseover")
    if mouseTarget and mouseTarget ~= "nil" and mouseTarget == "哈卡之子" then
        local cid = ShowColor("target", "哈卡之子-指向转火")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"哈卡", "Hakkar", "祖格哈卡"},
    className = "WARLOCK",
    action = "stop",
    description = "哈卡哈卡之子管理",
    checkFunction = HakkarCheck,
})

-- ============================================================
-- 26. 灵魂熔炉（ICC5人本） - 灵魂倒映/腐败灵魂停手
--     来源：另外循环插件特化\术士\3449BAB1.lua（灵魂熔炉.lua）
--     功能：
--       1) 镜像灵魂buff的目标标记为不可攻击
--       2) 护身符符文buff的目标不适合攻击
-- ============================================================
local function ForgeOfSoulsCheck()
    local targetName = UnitName("target")
    
    -- 1) 镜像灵魂buff的目标停止攻击
    --    来源：术士特化中 mobsInfo.buff.mirroredSoul.exist → A.noAttack = true
    if HasBuff("target", "镜像灵魂") or HasBuff("target", "mirroredSoul") then
        local cid = ShowColor("stop", "灵魂熔炉-镜像灵魂停止攻击")
        return true, cid
    end
    
    -- 2) 护身符符文buff的目标不适合法系攻击
    --    来源：术士特化中 targetInfo.buff.shroudRunes.exist → stopCasting
    if HasBuff("target", "护身符符文") or HasBuff("target", "shroudRunes") then
        local cid = ShowColor("stop", "灵魂熔炉-护身符符文停止法术")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"灵魂熔炉", "锻造之魂", "Forge of Souls"},
    className = "WARLOCK",
    action = "stop",
    description = "灵魂熔炉镜像灵魂+护身符符文处理",
    checkFunction = ForgeOfSoulsCheck,
})

-- ============================================================
-- 27. 海里昂（ICC5人本） - 活体余烬种子 + 低血量火箭靴
--     来源：另外循环插件特化\术士\8FBD04FF.lua（海里昂.lua）
--     功能：
--       1) 海加尔生存者出现时提示种子
--       2) 低血量时使用火箭靴逃跑
-- ============================================================
local function HalionEnhancedCheck()
    local targetName = UnitName("target")
    
    -- 1) 海加尔生存者出现时提示种子
    --    来源：术士特化中 seed 海加尔生存者
    if targetName == "海加尔生存者" then
        local cid = ShowColor("target", "海里昂-生存者种子")
        return true, cid
    end
    
    -- 2) 低血量火箭靴
    --    来源：术士特化中 hp < 30% → rocketboots
    local playerHP = WR_BossUtils.GetPlayerHP()
    if playerHP and playerHP < 30 then
        local cid = ShowColor("rocketboots", "海里昂低血量火箭靴")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"海里昂", "Halion", "ICC5人本海里昂"},
    className = "WARLOCK",
    action = "stop",
    description = "海里昂生存者种子+低血量火箭靴",
    checkFunction = HalionEnhancedCheck,
})

-- ============================================================
-- 28. 魔枢（ICC 10人本） - 镜像过滤
--     来源：另外循环插件特化\术士\912CFAC9.lua（魔枢.lua）
--     功能：
--       1) 场上有镜像时提示（不打镜像）
-- ============================================================
local function MagusCheck()
    -- 1) 镜像过滤
    --    来源：术士特化中 npFind(1,30,nil,"镜像") → 返回true表示场上有镜像
    local targetName = UnitName("target")
    if targetName == "镜像" then
        local cid = ShowColor("stop", "魔枢-镜像不攻击")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"魔枢", "Magus", "Malygee", "ICC魔枢", "ICC10魔枢"},
    className = "WARLOCK",
    action = "stop",
    description = "魔枢镜像过滤",
    checkFunction = MagusCheck,
})

-- ============================================================
-- 29. 乌巅（ICC 10人本） - 冰霜地面自动跑路
--     来源：另外循环插件特化\术士\9C735F4A.lua（乌巅.lua）
--     功能：
--       1) glaciate de buff时自动移动（避免持续冰冻伤害）
-- ============================================================
local function UudimCheck()
    -- 1) glaciate debuff时自动跑路
    --    来源：术士特化中 player.debuff.glaciate.exist → setAction2("startMove")
    if HasDebuff("player", "glaciate") or HasDebuff("player", "冰霜地面") then
        local cid = ShowColor("move", "乌巅-冰霜地面自动跑路")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"乌巅", "Uudim", "ICC乌巅", "ICC10乌巅"},
    className = "WARLOCK",
    action = "stop",
    description = "乌巅冰霜地面自动跑路",
    checkFunction = UudimCheck,
})

-- ============================================================
-- 30. 巴尔萨鲁斯（ICC炮舰） - DOT暂停
--     来源：另外循环插件特化\术士\EF6D7CD1.lua（巴尔萨鲁斯.lua）
--     功能：
--       1) BOSS战中暂停所有DOT刷新（spam关闭）
-- ============================================================
local function BaltharusCheck()
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end
    
    -- 注意：完整的DOT暂停逻辑属于循环层，此处仅做Boss存在性标记
    -- 完整实现需要在Init中禁用DOT刷新，Destroy中恢复
    
    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"巴尔萨鲁斯", "Baltharus", "Baltharus Warborn", "ICC炮舰"},
    className = "WARLOCK",
    action = "stop",
    description = "巴尔萨鲁斯DOT管理",
    checkFunction = BaltharusCheck,
})

-- ============================================================
-- 31. 卡雷苟斯（太阳井1号） - 黑暗之门停手 + 腐蚀/燃烧走位
--     来源：WR_BossMechanics 太阳井机制库（卡雷苟斯条目）
--     术士增强：黑暗之门时提示传送规避；腐蚀/燃烧时火箭靴走位
-- ============================================================
local function KalecgosCheck()
    -- 1) 术士专属：黑暗之门提示传送（替代纯停手，术士可用恶魔法阵/火箭靴）
    local doorCount = GetDebuffCount("player", "黑暗之门") + GetBuffCount("player", "黑暗之门")
    if doorCount > 0 then
        local cid = ShowColor("rocketboots", "卡雷苟斯-黑暗之门传送规避")
        return true, cid
    end

    -- 2) 通用机制库筛选（腐蚀/燃烧法系走位等，自动按术士角色套用）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"卡雷苟斯", "Kalecgos", "太阳井1号", "腐蚀者萨索瓦尔", "Sathrovarr"},
    className = "WARLOCK",
    action = "stop",
    description = "卡雷苟斯黑暗之门传送+腐蚀燃烧走位",
    checkFunction = KalecgosCheck,
})

-- ============================================================
-- 32. 布鲁塔卢斯（太阳井2号） - 燃烧之血法系走位
--     来源：WR_BossMechanics 太阳井机制库（布鲁塔卢斯条目）
--     说明：近战陨石打击/坦克减伤由机制库按角色过滤，术士只吃燃烧之血走位
-- ============================================================
local function BrutallusCheck()
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"布鲁塔卢斯", "Brutallus", "太阳井2号"},
    className = "WARLOCK",
    action = "rocketboots",
    description = "布鲁塔卢斯燃烧之血法系走位",
    checkFunction = BrutallusCheck,
})

-- ============================================================
-- 33. 菲米丝（太阳井3号前） - 腐蚀气体走位 + 空战阶段种子管理
--     来源：WR_BossMechanics 太阳井机制库（菲米丝条目，本次新增）
--     术士增强：空战阶段提示对地面小怪撒种子（顺其自然处理空中未能读条）
-- ============================================================
local function FelmystCheck()
    local targetName = UnitName("target")

    -- 1) 空战阶段提示种子（地面有残血小怪时持续AOE）
    if targetName == "菲米丝" then
        local flyingCount = GetBuffCount("target", "飞行") + GetDebuffCount("player", "空战")
        if flyingCount > 0 then
            local cid = ShowColor("aoe", "菲米丝-空战阶段种子管理")
            return true, cid
        end
    end

    -- 2) 通用机制库筛选（腐蚀气体走位等）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"菲米丝", "Felmyst", "太阳井3号"},
    className = "WARLOCK",
    action = "rocketboots",
    description = "菲米丝腐蚀气体走位+空战种子管理",
    checkFunction = FelmystCheck,
})

-- ============================================================
-- 34. 艾瑞达双子（太阳井3号） - 暗影/火焰之痛停读条 + 同色攻击
--     来源：WR_BossMechanics 太阳井机制库（艾瑞达双子条目）
--     说明：机制库按术士角色过滤暗影之痛系；此处加同色攻击目标提示
-- ============================================================
local function EredarTwinsCheck()
    -- 1) 同色攻击提示（术士需打与自身debuff同色Boss）
    if HasDebuff("player", "暗影之痛") or HasDebuff("player", "火焰之痛") then
        local cid = ShowColor("target", "双子-同色攻击")
        return true, cid
    end

    -- 2) 通用机制库筛选（暗影之痛/火焰之痛法系停读条）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"艾瑞达双子", "Eredar Twins", "萨洛拉丝女王", "高阶术士阿丽塞丝", "太阳井4号"},
    className = "WARLOCK",
    action = "stop",
    description = "艾瑞达双子同色攻击+痛苦debuff停读条",
    checkFunction = EredarTwinsCheck,
})

-- ============================================================
-- 35. 穆鲁（太阳井4号） - 过滤虚空哨兵/熵 + 熵debuff停读条
--     来源：WR_BossMechanics 太阳井机制库（穆鲁条目）
--     术士增强：熵阶段暗影防护提示（熵debuff法系停读条已覆盖）
-- ============================================================
local function MuruCheck()
    -- 1) 熵debuff时暗影防护（术士专属，减少暗影伤害）
    if HasDebuff("player", "熵") then
        local cid = ShowColor("defensive", "穆鲁-熵debuff暗影防护")
        return true, cid
    end

    -- 2) 通用机制库筛选（过滤虚空哨兵/熵 + 熵debuff法系停读条）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"穆鲁", "M'uru", "Muru", "太阳井5号"},
    className = "WARLOCK",
    action = "stop",
    description = "穆鲁过滤虚空哨兵+熵debuff停读条/暗影防护",
    checkFunction = MuruCheck,
})

-- ============================================================
-- 36. 基尔加丹（太阳井5号） - 千魂停手 + 暗影之矛/虚空之盾停读条
--     来源：WR_BossMechanics 太阳井机制库（基尔加丹条目）
--     术士增强：千魂/暗影之矛/虚空之盾已由机制库覆盖，此处加镜像转火提示
-- ============================================================
local function KiljaedenCheck()
    local targetName = UnitName("target")

    -- 1) 镜像出现时提示转火撒DOT（基尔加丹召唤镜像阶段）
    if targetName == "基尔加丹镜像" or targetName == "镜像" then
        local cid = ShowColor("target", "基尔加丹-镜像转火撒DOT")
        return true, cid
    end

    -- 2) 通用机制库筛选（千魂/暗影之矛/炽焰弹幕/虚空之盾）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"基尔加丹", "Kil'jaeden", "Kiljaeden", "太阳井6号"},
    className = "WARLOCK",
    action = "stop",
    description = "基尔加丹千魂/暗影之矛/虚空之盾+镜像转火",
    checkFunction = KiljaedenCheck,
})

-- ============================================================
-- 37. 鹰王艾基利松（祖阿曼1号） - 电气风暴集合 + 雷霆风暴法系停手
--     来源：WR_BossMechanics 祖阿曼机制库（鹰王条目）
--     术士增强：雷霆风暴时停读条（机制库已覆盖）；电气风暴集合时提示靠近集合点（不分散）
--     说明：Akil'zon 的雷霆风暴对法系威胁最大（停止读条），电气风暴要求全团集合
-- ============================================================
local function AkilzonCheck()
    local targetName = UnitName("target")

    -- 1) 术士专属：电气风暴集合走位（靠近场地中心，避免被点名远离）
    --    来源：祖阿曼攻略 - 电气风暴全团集合，术士法系远程需到位
    if HasDebuff("player", "电气风暴") or HasBuff("target", "电气风暴") then
        local cid = ShowColor("target", "鹰王-电气风暴集合走位")
        return true, cid
    end

    -- 2) 通用机制库筛选（雷霆风暴法系停读条 + 电气风暴集合）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"鹰王", "Akil'zon", "Akilzon", "艾基利松", "祖阿曼1号"},
    className = "WARLOCK",
    action = "stop",
    description = "鹰王雷霆风暴停读条+电气风暴集合走位",
    checkFunction = AkilzonCheck,
})

-- ============================================================
-- 38. 熊王纳洛拉克（祖阿曼2号） - 熊形态远程拉开距离
--     来源：WR_BossMechanics 祖阿曼机制库（熊王条目）
--     术士增强：熊形态时远程必须拉开距离（机制库已覆盖stop），此处强化火箭靴走位提示
--     说明：纳洛拉克 熊形态物理伤害大幅提高，术士法系需保持最大距离输出
-- ============================================================
local function NalorakkCheck()
    -- 1) 术士专属：熊形态时主动拉开距离（火箭靴/走位，减少顺劈/横扫伤害）
    if HasBuff("target", "熊形态") then
        local cid = ShowColor("rocketboots", "熊王-熊形态术士拉开距离")
        return true, cid
    end

    -- 2) 通用机制库筛选（冲锋近战停手 + 熊形态远程保持距离）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"熊王", "Nalorakk", "纳洛拉克", "祖阿曼2号"},
    className = "WARLOCK",
    action = "rocketboots",
    description = "熊王熊形态术士拉开距离",
    checkFunction = NalorakkCheck,
})

-- ============================================================
-- 39. 龙鹰王贾恩阿拉伊（祖阿曼3号） - 火焰新星停读条 + 孵化小龙鹰种子AOE
--     来源：WR_BossMechanics 祖阿曼机制库（龙鹰王条目）
--     术士增强：龙鹰卵孵化出小龙鹰时，提示腐蚀之种AOE（队友集火+种子）
--     说明：Jan'alai 龙鹰卵定时孵化，术士可用种子高效清理小龙鹰
-- ============================================================
local function JanalaiCheck()
    local targetName = UnitName("target")

    -- 1) 术士专属：场上小龙鹰(孵化)≥2只时提示种子AOE
    --    来源：祖阿曼攻略 - 龙鹰王卵孵化小龙鹰，术士种子AOE处理
    if targetName == "龙鹰王" or targetName == "贾恩阿拉伊" or targetName == "Jan'alai" then
        local hatchlingCount = 0
        local nameplates = C_NamePlate.GetNamePlates()
        if nameplates then
            for i = 1, math.min(#nameplates, 20) do
                local unitToken = nameplates[i].unitToken
                if unitToken then
                    local name = UnitName(unitToken)
                    if (name == "小龙鹰" or name == "幼龙鹰") and IsUnitInRange(unitToken, "player") then
                        hatchlingCount = hatchlingCount + 1
                    end
                end
            end
        end
        if hatchlingCount >= 2 then
            local cid = ShowColor("aoe", "龙鹰王-小龙鹰种子AOE")
            return true, cid
        end
    end

    -- 2) 通用机制库筛选（火焰新星法系停读条 + 过滤小龙鹰）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"龙鹰王", "Jan'alai", "Janalai", "贾恩阿拉伊", "祖阿曼3号"},
    className = "WARLOCK",
    action = "stop",
    description = "龙鹰王火焰新星停读条+小龙鹰种子AOE",
    checkFunction = JanalaiCheck,
})

-- ============================================================
-- 40. 豹王哈拉兹（祖阿曼4号） - 分身灵魂阶段转火 + 过滤图腾
--     来源：WR_BossMechanics 祖阿曼机制库（豹王条目）
--     术士增强：哈拉兹分裂出灵魂(哈尔拉兹之魂)时，提示转火击杀灵魂（术士持续DOT）
--     说明：Halazzi 在分身阶段本体+灵魂同时存在，需优先击杀灵魂，术士DOT可双目标铺设
-- ============================================================
local function HalazziCheck()
    local targetName = UnitName("target")

    -- 1) 术士专属：分裂灵魂阶段，提示转火击杀"哈尔拉兹之魂"
    --    来源：祖阿曼攻略 - 豹王分身，集火灵魂；术士DOT铺满本体+灵魂
    if targetName == "哈尔拉兹之魂" or targetName == "豹王之魂" or targetName == "Halazzi's Spirit" then
        local cid = ShowColor("target", "豹王-转火击杀灵魂")
        return true, cid
    end

    -- 2) 通用机制库筛选（闪避近战停手 + 过滤图腾）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"豹王", "Halazzi", "哈拉兹", "祖阿曼4号"},
    className = "WARLOCK",
    action = "stop",
    description = "豹王分身转火灵魂+过滤图腾",
    checkFunction = HalazziCheck,
})

-- ============================================================
-- 41. 妖术领主玛拉卡斯（祖阿曼5号） - 妖术/变青蛙停手 + 灵魂吸取暗影防护
--     来源：WR_BossMechanics 祖阿曼机制库（妖术领主条目）
--     术士增强：灵魂吸取debuff时暗影防护（减少暗影伤害，术士持续输出）
--     说明：Malacrass 妖术使全团变青蛙无法行动；灵魂吸取对法系造成暗影伤害，术士开暗影防护
-- ============================================================
local function MalacrassCheck()
    -- 1) 术士专属：灵魂吸取时暗影防护（减伤，保持DPS）
    --    来源：祖阿曼攻略 - 妖术领主灵魂吸取暗影伤害，术士暗影防护
    if HasDebuff("player", "灵魂吸取") then
        local cid = ShowColor("defensive", "妖术领主-灵魂吸取暗影防护")
        return true, cid
    end

    -- 2) 通用机制库筛选（妖术/变青蛙停手 + 灵魂吸取法系停读条）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"妖术领主", "Hex Lord Malacrass", "HexLord", "玛拉卡斯", "祖阿曼5号"},
    className = "WARLOCK",
    action = "stop",
    description = "妖术领主妖术停手+灵魂吸取暗影防护",
    checkFunction = MalacrassCheck,
})

-- ============================================================
-- 42. 祖金（祖阿曼6号） - 毒debuff走位 + 愤怒形态近战停手
--     来源：WR_BossMechanics 祖阿曼机制库（祖金条目）
--     说明：Zul'jin 四形态变身(人/熊/鹰/山猫/龙鹰)，毒debuff阶段法系远程必须走位
--           （机制库已覆盖火箭靴走位）；愤怒形态近战停手由机制库按角色过滤
--           术士纯走机制库路线，确保毒阶段强制走位被正确处理
-- ============================================================
local function ZuljinCheck()
    -- 通用机制库筛选（祖金愤怒近战停手 + 毒debuff远程走位）
    local triggered, overrideColor = CheckBossMechanicsForWarlock()
    if triggered then
        return true, overrideColor
    end

    return false
end

WR_Warlock_RegisterBoss({
    bossNames = {"祖金", "Zul'jin", "祖阿曼6号"},
    className = "WARLOCK",
    action = "rocketboots",
    description = "祖金毒debuff走位+愤怒形态近战停手",
    checkFunction = ZuljinCheck,
})

-- ============================================================
-- ★ 统一入口（由 MainLoop 直接调用，无注册表中间件）
--   按当前目标名查本地派发表；命中则调用对应检查函数
--   太阳井(1-6号) 默认不触发（SW_BOSS_SPECIALS_OFF 守卫，用户只需输出循环）
-- ============================================================
function WR_Warlock_BossSpecials()
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

