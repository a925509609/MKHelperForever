-- ============================================================
-- WR_Warrior_BossSpecials.lua
-- 战士职业差异化 BOSS 特化逻辑
--
-- 核心设计：
--   1. 区分坦克（防护）/ 近战DPS（狂暴/武器），按角色类型筛选机制
--   2. 基于 WR_BossMechanics 配置库，按角色类型检索适用机制
--   3. 战士特有机制：坦克冰龙吐息开盾墙/破釜、坦克血议会自动切目标等
--   4. 直接使用 WR_ColorFrame_Show 显示颜色（绕过 WR_ColorAdapter）
--   5. 颜色映射：stop=3, target=4, defensive=8, rocketboots=108, lk_contamination=107
--
-- 包含的 BOSS 特化：
--   1. 冰龙辛达苟萨 - 坦克吐息防御/刺骨停手/DPS刺骨停手
--   2. 血议会 - 坦克自动切目标/DPS过滤无效目标
--   3. 灵魂熔炉 - 全角色灵魂倒映停手
--   4. 海里昂 - DPS火箭靴
--   5. 教授普崔希德 - DPS软泥停手
--   6. 萨鲁法尔 - DPS取消保护之手
--   7. 巫妖王 - DPS污染跑位
--   8. 观察者奥尔加隆 - DPS星尘停手
--   9. 尤格萨隆 - DPS精神控制停手
--  10. 血女王 - DPS鲜血镜像停手
--  11. 腐面/烂肠 - DPS突变停手
--  12. 炮舰 - DPS火箭靴
--  13. 翡翠巨龙 - DPS沉睡/燃烧停手
-- ============================================================

if WR_PlayerClass ~= "WARRIOR" then return end

if select(2, UnitClass("player")) ~= "WARRIOR" then
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
local function WR_Warrior_RegisterBoss(spec)
    if not spec or not spec.bossNames or not spec.checkFunction then return end
    local isSW = SW_BOSS_NAMES[spec.bossNames[1]] or false
    for _, name in ipairs(spec.bossNames) do
        BOSS_SPECIALS_BY_NAME[name] = { checkFunction = spec.checkFunction, isSW = isSW }
    end
end

local WS = {}

-- ============================================================
-- ★ 共享工具（来自 WR_BossUtils，避免重复定义）
-- ============================================================
local GetDebuffCount = WR_BossUtils.GetDebuffCount
local HasBuff = WR_BossUtils.HasBuff
local HasDebuff = WR_BossUtils.HasDebuff
local ColorMap = WR_BossUtils.ColorMap
local ShowColor = WR_BossUtils.ShowColor

-- ============================================================
-- ★ 战士角色类型判断
-- ============================================================
local function GetWarriorRole()
    local _, _, _, _, protRank = GetTalentTabInfo(3)
    local _, _, _, _, armsRank = GetTalentTabInfo(1)
    local _, _, _, _, furyRank = GetTalentTabInfo(2)

    if protRank > armsRank and protRank > furyRank then
        return "tank"
    else
        return "melee_dps"
    end
end

-- ============================================================
-- ★ 1. 冰龙辛达苟萨 - 差异化处理
-- ============================================================

local function SindragosaCheck()
    local role = GetWarriorRole()
    local targetName = UnitName("target")

    if targetName ~= "辛达苟萨" and targetName ~= "Sindragosa" then
        return false
    end

    if role == "tank" then
        if HasDebuff("player", "冰冷吐息") or HasDebuff("player", "冰霜吐息") then
            ShowColor("defensive", "冰龙吐息-开盾墙/破釜")
            return true
        end

        local chilledCount = GetDebuffCount("player", "寒霜刺骨")
        if chilledCount >= 5 then
            ShowColor("stop", "冰龙刺骨-坦克停手")
            return true
        end

        if HasDebuff("player", "冰封") then
            ShowColor("stop", "冰龙冰封-坦克停手")
            return true
        end
    else
        local chilledCount = GetDebuffCount("player", "寒霜刺骨")
        local HSCG = PigSet and PigSet.WQZ_HSCG or 0
        local threshold = (HSCG ~= 7) and (HSCG + 4) or 5
        if chilledCount and chilledCount >= threshold then
            ShowColor("stop", "冰龙刺骨-DPS停手")
            return true
        end

        if HasDebuff("player", "冰封") then
            ShowColor("stop", "冰龙冰封-DPS停手")
            return true
        end
    end

    return false
end

-- ============================================================
-- ★ 2. 血议会 - 差异化处理
-- ============================================================

local function BloodCouncilCheck()
    local role = GetWarriorRole()
    local targetName = UnitName("target")

    if role == "tank" then
        if targetName == "动力炸弹" or targetName == "黑暗之核" then
            ShowColor("stop", "血议会-坦克过滤无效目标")
            return true
        end

        if UnitExists("boss1") and UnitExists("boss2") and UnitExists("boss3") then
            local hp1 = WR_GetUnitHP("boss1") or 100
            local hp2 = WR_GetUnitHP("boss2") or 100
            local hp3 = WR_GetUnitHP("boss3") or 100
            local currentHP = WR_GetUnitHP("target") or 100

            if currentHP > 10 and (hp1 < 5 or hp2 < 5 or hp3 < 5) then
                if currentHP > hp1 and currentHP > hp2 and currentHP > hp3 then
                    ShowColor("target", "血议会-坦克切目标")
                    return true
                end
            end
        end
    else
        if targetName == "动力炸弹" or targetName == "黑暗之核" then
            ShowColor("stop", "血议会-DPS过滤无效目标")
            return true
        end
    end

    return false
end

-- ============================================================
-- ★ 3. 灵魂熔炉 - 灵魂倒映（全角色）
-- ============================================================

local function ForgeOfSoulsCheck()
    local targetName = UnitName("target")

    if HasDebuff("player", "灵魂倒映") then
        ShowColor("stop", "灵魂熔炉-灵魂倒映停手")
        return true
    end

    if targetName == "镜像" or targetName == "腐化的灵魂" then
        ShowColor("stop", "灵魂熔炉-过滤镜像目标")
        return true
    end

    if HasBuff("target", "灵魂倒映") or HasBuff("target", "腐蚀之魂") then
        ShowColor("stop", "灵魂熔炉-目标有倒映buff停手")
        return true
    end

    return false
end

-- ============================================================
-- ★ 4. 海里昂 - 低血量火箭靴（DPS）
-- ============================================================

local function HalionCheck()
    local targetName = UnitName("target")
    local role = GetWarriorRole()

    if targetName ~= "海里昂" and targetName ~= "Halion" then
        return false
    end

    if role == "tank" then
        local hp = WR_GetUnitHP("player") or 100
        if hp < 20 then
            ShowColor("defensive", "海里昂-坦克低血量防御")
            return true
        end
    else
        local hp = WR_GetUnitHP("player") or 100
        if hp < 30 then
            ShowColor("rocketboots", "海里昂-DPS火箭靴")
            return true
        end
    end

    return false
end

-- ============================================================
-- ★ 5. 教授普崔希德 - 软泥怪/毒气停手（DPS）
-- ============================================================

local function PutricideCheck()
    local targetName = UnitName("target")

    if targetName == "不稳定的软泥怪" or targetName == "毒气之云" then
        ShowColor("stop", "教授-过滤软泥/毒气")
        return true
    end

    if HasDebuff("player", "催泪毒气") or HasDebuff("player", "腐蚀黏液") then
        ShowColor("stop", "教授-玩家中毒停手")
        return true
    end

    return false
end

-- ============================================================
-- ★ 6. 萨鲁法尔 - 取消保护之手（DPS）
-- ============================================================

local function SaurfangCheck()
    if HasBuff("player", "保护之手") then
        ShowColor("defensive", "萨鲁法尔-取消保护之手")
        return true
    end

    return false
end

-- ============================================================
-- ★ 7. 巫妖王 - 污染/冰封王座跑位（DPS）
-- ============================================================

local function LKCheck()
    local targetName = UnitName("target")

    if targetName ~= "巫妖王" and targetName ~= "The Lich King" and targetName ~= "LK" then
        return false
    end

    if HasDebuff("player", "污染") or HasDebuff("player", "冰封王座") then
        ShowColor("lk_contamination", "巫妖王-污染跑位")
        return true
    end

    local hp = WR_GetUnitHP("player") or 100
    if hp < 15 then
        ShowColor("defensive", "巫妖王-低血量防御")
        return true
    end

    return false
end

-- ============================================================
-- ★ 8. 观察者奥尔加隆 - 宇宙撞击/坍缩之星停手（DPS）
-- ============================================================

local function AlgalonCheck()
    if HasDebuff("player", "宇宙撞击") or HasDebuff("player", "坍缩之星") then
        ShowColor("stop", "奥尔加隆-宇宙撞击停手")
        return true
    end

    if HasBuff("target", "观察者的注意") then
        ShowColor("stop", "奥尔加隆-目标免疫停手")
        return true
    end

    return false
end

-- ============================================================
-- ★ 9. 尤格萨隆 - 精神控制/心灵牢笼停手（DPS）
-- ============================================================

local function YoggCheck()
    local targetName = UnitName("target")

    if HasDebuff("player", "精神控制") or HasDebuff("player", "心灵牢笼") then
        ShowColor("stop", "尤格萨隆-精神控制停手")
        return true
    end

    if targetName == "尤格萨隆的触手" then
        ShowColor("stop", "尤格萨隆-过滤触手")
        return true
    end

    return false
end

-- ============================================================
-- ★ 10. 血女王 - 鲜血镜像停手（DPS）
-- ============================================================

local function BloodQueenCheck()
    if HasDebuff("player", "鲜血镜像") then
        ShowColor("stop", "血女王-鲜血镜像停手")
        return true
    end

    return false
end

-- ============================================================
-- ★ 11. 腐面/烂肠 - 突变停手（DPS）
-- ============================================================

local function MutantCheck()
    if HasDebuff("player", "突变") or HasDebuff("player", "致命突变") then
        ShowColor("stop", "腐面/烂肠-突变停手")
        return true
    end

    return false
end

-- ============================================================
-- ★ 12. 炮舰 - 低血量火箭靴（DPS）
-- ============================================================

local function GunshipCheck()
    local targetName = UnitName("target")

    if targetName == "炮舰" or targetName == "天界飞船" or targetName == "Gunship" then
        local hp = WR_GetUnitHP("player") or 100
        if hp < 30 then
            ShowColor("rocketboots", "炮舰-火箭靴")
            return true
        end
    end

    return false
end

-- ============================================================
-- ★ 13. 翡翠巨龙 - 沉睡/燃烧之血停手（DPS）
-- ============================================================

local function DragonCheck()
    local targetName = UnitName("target")

    if targetName == "翡翠巨龙" or targetName == "绯红巨龙守护者" then
        if HasDebuff("player", "沉睡") or HasDebuff("player", "燃烧之血") then
            ShowColor("stop", "翡翠巨龙-特殊状态停手")
            return true
        end
    end

    return false
end

-- ============================================================
-- ★ BOSS 特化注册（本地派发表，无需 WR_BossRegistry 中间件）
--   注册后由 MainLoop 的 BOSS_SPECIALS_DISPATCH 按职业直调 WR_Warrior_BossSpecials()
--   检查函数返回 true 时阻塞正常职业循环
-- ============================================================

WR_Warrior_RegisterBoss({
    bossNames = {"辛达苟萨", "Sindragosa", "冰霜女王", "The Frost Queen"},
    className = "WARRIOR",
    talent = "武器",
    action = "stop",
    description = "冰龙特化",
    checkFunction = SindragosaCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"辛达苟萨", "Sindragosa"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "stop",
    description = "冰龙特化",
    checkFunction = SindragosaCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"辛达苟萨", "Sindragosa"},
    className = "WARRIOR",
    talent = "防护",
    action = "defensive",
    description = "冰龙特化",
    checkFunction = SindragosaCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"血议会", "鲜血议会", "Blood Council", "塔达拉姆王子", "瓦拉纳王子", "凯雷塞斯王子"},
    className = "WARRIOR",
    talent = "武器",
    action = "target",
    description = "血议会特化",
    checkFunction = BloodCouncilCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"血议会", "鲜血议会", "Blood Council"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "stop",
    description = "血议会特化",
    checkFunction = BloodCouncilCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"血议会", "鲜血议会", "Blood Council"},
    className = "WARRIOR",
    talent = "防护",
    action = "target",
    description = "血议会特化",
    checkFunction = BloodCouncilCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"灵魂熔炉", "锻造之魂", "Forge of Souls", "镜像", "腐化的灵魂"},
    className = "WARRIOR",
    talent = "武器",
    action = "stop",
    description = "灵魂熔炉特化",
    checkFunction = ForgeOfSoulsCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"灵魂熔炉", "锻造之魂", "Forge of Souls"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "stop",
    description = "灵魂熔炉特化",
    checkFunction = ForgeOfSoulsCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"灵魂熔炉", "锻造之魂", "Forge of Souls"},
    className = "WARRIOR",
    talent = "防护",
    action = "stop",
    description = "灵魂熔炉特化",
    checkFunction = ForgeOfSoulsCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"海里昂", "Halion"},
    className = "WARRIOR",
    talent = "武器",
    action = "rocketboots",
    description = "海里昂特化",
    checkFunction = HalionCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"海里昂", "Halion"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "rocketboots",
    description = "海里昂特化",
    checkFunction = HalionCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"海里昂", "Halion"},
    className = "WARRIOR",
    talent = "防护",
    action = "defensive",
    description = "海里昂特化",
    checkFunction = HalionCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"普崔塞德教授", "Professor Putricide", "Putricide", "不稳定的软泥怪", "毒气之云"},
    className = "WARRIOR",
    talent = "武器",
    action = "stop",
    description = "教授特化",
    checkFunction = PutricideCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"普崔塞德教授", "Professor Putricide", "Putricide"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "stop",
    description = "教授特化",
    checkFunction = PutricideCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"死亡使者萨鲁法尔", "Deathbringer Saurfang", "萨鲁法尔", "Saurfang"},
    className = "WARRIOR",
    talent = "武器",
    action = "defensive",
    description = "萨鲁法尔特化",
    checkFunction = SaurfangCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"死亡使者萨鲁法尔", "Deathbringer Saurfang", "萨鲁法尔", "Saurfang"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "defensive",
    description = "萨鲁法尔特化",
    checkFunction = SaurfangCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"巫妖王", "The Lich King", "LK", "阿尔萨斯"},
    className = "WARRIOR",
    talent = "武器",
    action = "lk_contamination",
    description = "巫妖王特化",
    checkFunction = LKCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"巫妖王", "The Lich King", "LK", "阿尔萨斯"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "lk_contamination",
    description = "巫妖王特化",
    checkFunction = LKCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"巫妖王", "The Lich King", "LK", "阿尔萨斯"},
    className = "WARRIOR",
    talent = "防护",
    action = "defensive",
    description = "巫妖王特化",
    checkFunction = LKCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"观察者奥尔加隆", "Algalon the Observer", "奥尔加隆", "Algalon"},
    className = "WARRIOR",
    talent = "武器",
    action = "stop",
    description = "奥尔加隆特化",
    checkFunction = AlgalonCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"观察者奥尔加隆", "Algalon the Observer", "奥尔加隆", "Algalon"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "stop",
    description = "奥尔加隆特化",
    checkFunction = AlgalonCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"尤格萨隆", "Yogg-Saron", "Yogg", "尤格萨隆的触手"},
    className = "WARRIOR",
    talent = "武器",
    action = "stop",
    description = "尤格萨隆特化",
    checkFunction = YoggCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"尤格萨隆", "Yogg-Saron", "Yogg"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "stop",
    description = "尤格萨隆特化",
    checkFunction = YoggCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"鲜血女王兰娜瑟尔", "Blood-Queen Lana'thel", "血女王"},
    className = "WARRIOR",
    talent = "武器",
    action = "stop",
    description = "血女王特化",
    checkFunction = BloodQueenCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"鲜血女王兰娜瑟尔", "Blood-Queen Lana'thel", "血女王"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "stop",
    description = "血女王特化",
    checkFunction = BloodQueenCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"腐面", "Festergut", "烂肠", "Rotface"},
    className = "WARRIOR",
    talent = "武器",
    action = "stop",
    description = "腐面/烂肠特化",
    checkFunction = MutantCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"腐面", "Festergut", "烂肠", "Rotface"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "stop",
    description = "腐面/烂肠特化",
    checkFunction = MutantCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"炮舰", "天界飞船", "Gunship"},
    className = "WARRIOR",
    talent = "武器",
    action = "rocketboots",
    description = "炮舰特化",
    checkFunction = GunshipCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"炮舰", "天界飞船", "Gunship"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "rocketboots",
    description = "炮舰特化",
    checkFunction = GunshipCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"翡翠巨龙", "绯红巨龙守护者", "Valithria"},
    className = "WARRIOR",
    talent = "武器",
    action = "stop",
    description = "翡翠巨龙特化",
    checkFunction = DragonCheck,
})

WR_Warrior_RegisterBoss({
    bossNames = {"翡翠巨龙", "绯红巨龙守护者", "Valithria"},
    className = "WARRIOR",
    talent = "狂怒",
    action = "stop",
    description = "翡翠巨龙特化",
    checkFunction = DragonCheck,
})

-- ============================================================
-- ★ 14. TOC双子 - 黑暗漩涡防御 + 同色攻击切换
--     来源：集成外部插件优化逻辑 + MY插件通用机制
--     战士特化调整：
--       1) 黑暗漩涡出现时使用盾墙/破釜(坦克)
--       2) 同色Essence时提示切目标(DPS)
-- ============================================================
local TwinsDarkVortexActive = false

local function TwinsCheck()
    local role = GetWarriorRole()
    
    -- 1) 同色攻击提示(DPS)
    if role == "melee_dps" then
        if HasDebuff("player", "光明 Essence") or HasDebuff("player", "黑暗 Essence") then
            local cid = ShowColor("target", "双子-同色攻击切换")
            return true, cid
        end
    end
    
    -- 2) 黑暗漩涡防御(坦克)
    if role == "tank" then
        if TwinsDarkVortexActive and HasBuff("player", "圣盾术") then
            local cid = ShowColor("defensive", "双子-黑暗漩涡防御")
            return true, cid
        end
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"双子", "姐妹", "Twins", "Lady Liadrin", "Sister Solastria"},
    className = "WARRIOR",
    action = "stop",
    description = "双子-Twins Essence切换+黑暗漩涡",
    checkFunction = TwinsCheck,
})

-- ============================================================
-- ★ 15. TOC兽王 - Animal Husbandry转火 + 召唤物处理
--     来源：集成外部插件优化逻辑 + MY插件通用机制
--     战士特化调整：
--       1) 兽王召唤物出现时优先处理
--       2) Animal Husbandry debuff时停手
-- ============================================================
local function BeastMasterCheck()
    local targetName = UnitName("target")
    
    -- 1) 召唤物过滤
    if targetName == "狼灵" or targetName == "熊灵" or targetName == "豹灵" then
        local cid = ShowColor("target", "兽王-召唤物过滤")
        return true, cid
    end
    
    -- 2) Animal Husbandry debuff时停手
    if HasDebuff("player", "兽王诅咒") then
        local cid = ShowColor("stop", "兽王-兽王诅咒停手")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"兽王", "野兽之主", "Beast Master", "Archerus"},
    className = "WARRIOR",
    action = "stop",
    description = "兽王-召唤物过滤+兽王诅咒",
    checkFunction = BeastMasterCheck,
})

-- ============================================================
-- ★ 16. ZG耶克里克 - 蝙蝠群AOE智能触发
--     来源：另外循环插件特化\术士\204FF6B1.lua（耶克里克.lua）
--     战士特化调整：
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
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"高阶祭司耶克里克", "HighPriestessJeklik", "祖格耶克里克", "Jeklik"},
    className = "WARRIOR",
    action = "aoe",
    description = "耶克里克-蝙蝠群AOE智能触发",
    checkFunction = JeklikCheck,
})

-- ============================================================
-- ★ 17. ZG曼多基尔 - 威慑凝视停手
--     来源：另外循环插件特化\术士\A320FFE3.lua（曼多基尔.lua）
--     战士特化调整：
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
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"血领主曼多基尔", "BloodlordMandokir", "祖格曼多基尔", "Mandokir"},
    className = "WARRIOR",
    action = "stop",
    description = "曼多基尔-威慑凝视停手",
    checkFunction = MandokirCheck,
})

-- ============================================================
-- ★ 18. ZG哈卡 - 灵魂吞噬处理 + 哈卡之子转火
--     来源：集成外部插件优化逻辑 + MY插件通用机制
--     战士特化调整：
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
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"哈卡尔·灵魂掠夺者", "哈卡", "Hakkar", "ZG哈卡"},
    className = "WARRIOR",
    action = "stop",
    description = "哈卡-灵魂吞噬+哈卡之子转火",
    checkFunction = HakkarCheck,
})

-- ============================================================
-- ★ 19. ZG温诺希斯 - 拉扎什眼镜蛇AOE处理
--     来源：另外循环插件特化\术士\B137416E.lua（温诺希斯.lua）
--     战士特化调整：
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
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"高阶祭司温诺希斯", "Venoxis", "祖格温诺希斯", "Wushoolay"},
    className = "WARRIOR",
    action = "aoe",
    description = "温诺希斯拉扎什眼镜蛇AOE",
    checkFunction = VenoxisCheck,
})

-- ============================================================
-- ★ 20. ZG金度 - 妖术蝙蝠AOE + 放逐传送处理
--     来源：集成外部插件优化逻辑 (JindoBanishTeleport)
--     战士特化调整：
--       1) 妖术蝙蝠群AOE触发
--       2) 放逐debuff时若魔法阵可用则传送解脱
-- ============================================================
local JindoBanished = false

local function JindoCheck()
    -- 1) 妖术蝙蝠AOE
    if UnitName("target") == "妖术师金度" then
        local batCount = 0
        for i = 1, 40 do
            local name = C_NamePlate.GetNamePlateForUnitNumber(i):GetName():GetString()
            if name and string.find(name, "妖术蝙蝠") then
                batCount = batCount + 1
            end
        end
        
        if batCount >= 3 then
            local cid = ShowColor("aoe", "金度-妖术蝙蝠AOE")
            return true, cid
        end
    end
    
    -- 2) 放逐解脱
    if HasDebuff("player", "放逐") then
        JindoBanished = true
        -- 检查是否有恶魔法阵传送门可用
        if IsSpellUsable("恶魔法阵") then
            local cid = ShowColor("teleport", "金度-放逐传送解脱")
            return true, cid
        end
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"妖术师金度", "Jeklik", "祖格金度", "Shirad"},
    className = "WARRIOR",
    action = "stop",
    description = "金度-妖术蝙蝠AOE+放逐传送",
    checkFunction = JindoCheck,
})

-- ★ 奥杜尔阶段新增BOSS(14-18)

-- ============================================================
-- ★ 21. XT002拆解之心 - 重力炸弹防护/炸弹人过滤
--     来源：集成外部插件优化逻辑 + MY插件通用机制
--     战士特化调整：
--       1) 重力炸弹debuff时提示使用防御技能
--       2) XE-321爆破机器人出现时提示转火
-- ============================================================
local function XT002Check()
    local targetName = UnitName("target")
    
    -- 1) 炸弹人过滤
    if targetName == "XE-321爆破机器人" or targetName == "动力炸弹猎" then
        local cid = ShowColor("target", "XT002-炸弹人过滤")
        return true, cid
    end
    
    -- 2) 重力炸弹防护
    if HasDebuff("player", "重力炸弹") then
        local cid = ShowColor("defensive", "XT002-重力炸弹防护")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"拆解者之心", "XT002", "奥杜尔XT002"},
    className = "WARRIOR",
    action = "stop",
    description = "XT002炸弹人种子+重力炸弹防护",
    checkFunction = XT002Check,
})

-- ============================================================
-- ★ 22. 科隆加恩 - 手臂阶段管理
--     来源：另外循环插件特化\术士\5D23ADB2.lua（奥杜尔科隆加恩.lua）
--     战士特化调整：
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
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"科隆加恩", "Kologarn"},
    className = "WARRIOR",
    action = "stop",
    description = "科隆加恩手臂阶段管理",
    checkFunction = KologarnCheck,
})

-- ============================================================
-- ★ 23. 米米尔隆 - 烈焰遏制防断条
--     来源：另外循环插件特化\术士\7E169FC1.lua（灭火机器人.lua）
--     战士特化调整：
--       1) 烈焰遏制debuff时提示暂停引导技能
--       2) 紧急灭火机器人目标过滤（不打）
-- ============================================================
local function MimironCheck()
    local targetName = UnitName("target")
    
    -- 1) 烈焰遏制防断条
    if HasDebuff("player", "烈焰遏制") then
        local cid = ShowColor("stop", "米米尔隆烈焰遏制-暂停输出")
        return true, cid
    end
    
    -- 2) 灭火机器人过滤
    if targetName == "紧急灭火机器人" then
        local cid = ShowColor("stop", "米米尔隆-灭火机器人过滤")
        return true, cid
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"米米尔隆", "Mimiron"},
    className = "WARRIOR",
    action = "stop",
    description = "米米尔隆烈焰遏制+灭火机器人",
    checkFunction = MimironCheck,
})

-- ============================================================
-- ★ 24. 维扎克斯 - 暗影冲击停手 + 无面印记传送
--     来源：另外循环插件特化\术士\B2B75F55.lua（维扎克斯.lua）
--     战士特化调整：
--       1) 暗影冲击debuff时停手（禁止分散技能）
--       2) 无面印记剩余≥8秒时提示火箭靴
-- ============================================================
local function VezaxCheck()
    -- 1) 暗影冲击停手
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
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"维扎克斯将军", "General Vezax", "维扎克斯", "Vezax"},
    className = "WARRIOR",
    action = "stop",
    description = "维扎克斯暗影冲击停手+无面印记传送",
    checkFunction = VezaxCheck,
})

-- ============================================================
-- ★ 25. 铁议会 - 符文力量光环管理
--     来源：另外循环插件特化\术士\F3287AEC.lua（奥杜尔议会.lua）
--     战士特化调整：
--       1) 符文力量debuff≥2层时提示防御性技能
--       2) 电力符文目标过滤（不打无防护目标）
-- ============================================================
local function IronCouncilCheck()
    -- 1) 符文力量debuff计数（≥2层时停止输出）
    local runeCount = GetDebuffCount("player", "符文力量")
    if runeCount >= 2 then
        local cid = ShowColor("defensive", "铁议会-符文力量护甲")
        return true, cid
    end
    
    -- 2) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForWarrior()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Warrior_RegisterBoss({
    bossNames = {"铁议会", "Iron Council"},
    className = "WARRIOR",
    action = "stop",
    description = "铁议会双光环符文力量防护",
    checkFunction = IronCouncilCheck,
})

-- ============================================================
-- ★ 主循环接口：检查所有战士BOSS特化机制
-- 来源：集成TOC/ZG/奥杜尔阶段新增Boss
-- ============================================================
function WR_CheckWarriorBossMechanics()
    local role = GetWarriorRole()

    -- 1) 通用机制(按角色类型过滤)
    local mechanism = WR_CheckBossMechanicsForRole and WR_CheckBossMechanicsForRole(role)
    if mechanism then
        ShowColor(mechanism.action, mechanism.description)
        return true
    end

    local targetName = UnitName("target")
    if not targetName then return false end

    -- 2) ICC阶段(13个Boss)
    if SindragosaCheck() then return true end
    if BloodCouncilCheck() then return true end
    if ForgeOfSoulsCheck() then return true end
    if HalionCheck() then return true end
    if PutricideCheck() then return true end
    if SaurfangCheck() then return true end
    if LKCheck() then return true end
    if AlgalonCheck() then return true end
    if YoggCheck() then return true end
    if BloodQueenCheck() then return true end
    if MutantCheck() then return true end
    if GunshipCheck() then return true end
    if DragonCheck() then return true end

    -- 3) TOC阶段新增(3个Boss)
    if TwinsCheck() then return true end
    if AnubarakCheck() then return true end
    if JaraxxusCheck() then return true end

    -- 4) ZG阶段新增(5个Boss)
    if JeklikCheck() then return true end
    if MandokirCheck() then return true end
    if HakkarCheck() then return true end
    if VenoxisCheck() then return true end
    if JindoCheck() then return true end

    -- 5) 奥杜尔阶段新增(5个Boss)
    if XT002Check() then return true end
    if KologarnCheck() then return true end
    if MimironCheck() then return true end
    if VezaxCheck() then return true end
    if IronCouncilCheck() then return true end

    return false
end

-- ============================================================
-- 加载完成提示
-- ============================================================

-- ============================================================
-- 通用职业机制分发（纯透传）
--   复用全局 WR_CheckBossMechanics() 检查当前 Boss 全部机制，
--   由机制自身 checkFunction 决定触发（多形态职业不硬编码角色）
-- ============================================================
local function CheckBossMechanicsForWarrior()
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

local function CheckBossMechanicsForWarrior()
    local mechanism = WR_CheckBossMechanics()
    if mechanism then
        local colorID = (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap[mechanism.action]) or mechanism.colorID or 1
        local desc = mechanism.description or mechanism.name or UnitName("target") or ""
        WR_ColorFrame_Show(colorID, desc)
        return true, colorID
    end
    return false
end

local function WarriorKLGSCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"卡雷苟斯", "Kalecgos", "太阳井1号", "腐蚀者萨索瓦尔", "Sathrovarr"},
    className = "WARRIOR",
    action = "stop",
    description = "卡雷苟斯-通用机制库(纯透传)",
    checkFunction = WarriorKLGSCheck,
})

local function WarriorBLTLCheck()
    if HasDebuff("player", "陨石打击") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"布鲁塔卢斯", "Brutallus", "太阳井2号"},
    className = "WARRIOR",
    action = "stop",
    description = "布鲁塔卢斯-盾墙减伤 / 通用兜底",
    checkFunction = WarriorBLTLCheck,
})

local function WarriorFMSCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"菲米丝", "Felmyst", "太阳井3号"},
    className = "WARRIOR",
    action = "stop",
    description = "菲米丝-通用机制库(纯透传)",
    checkFunction = WarriorFMSCheck,
})

local function WarriorTWINSCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"艾瑞达双子", "Eredar Twins", "Alythess", "Brannjar", "太阳井4号"},
    className = "WARRIOR",
    action = "stop",
    description = "艾瑞达双子-通用机制库(纯透传)",
    checkFunction = WarriorTWINSCheck,
})

local function WarriorMURUCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"穆鲁", "M'uru", "Muru", "太阳井5号"},
    className = "WARRIOR",
    action = "stop",
    description = "穆鲁-通用机制库(纯透传)",
    checkFunction = WarriorMURUCheck,
})

local function WarriorKJCheck()
    if HasBuff("target", "虚空之盾") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["stop"] or 3)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"基尔加丹", "Kil'jaeden", "Kiljaeden", "太阳井6号"},
    className = "WARRIOR",
    action = "stop",
    description = "基尔加丹-碎裂投掷破虚空之盾 / 通用兜底",
    checkFunction = WarriorKJCheck,
})

local function WarriorYWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"鹰王", "Akil'zon", "Akilzon", "艾基利松", "祖阿曼1号"},
    className = "WARRIOR",
    action = "stop",
    description = "鹰王-通用机制库(纯透传)",
    checkFunction = WarriorYWCheck,
})

local function WarriorXWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"熊王", "Nalorakk", "纳洛拉克", "祖阿曼2号"},
    className = "WARRIOR",
    action = "stop",
    description = "熊王-通用机制库(纯透传)",
    checkFunction = WarriorXWCheck,
})

local function WarriorLHYCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"龙鹰王", "Jan'alai", "Janalai", "贾恩阿拉伊", "祖阿曼3号"},
    className = "WARRIOR",
    action = "stop",
    description = "龙鹰王-通用机制库(纯透传)",
    checkFunction = WarriorLHYCheck,
})

local function WarriorBWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"豹王", "Halazzi", "哈拉兹", "祖阿曼4号"},
    className = "WARRIOR",
    action = "stop",
    description = "豹王-通用机制库(纯透传)",
    checkFunction = WarriorBWCheck,
})

local function WarriorYSLZCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"妖术领主", "Hex Lord Malacrass", "HexLord", "玛拉卡斯", "祖阿曼5号"},
    className = "WARRIOR",
    action = "stop",
    description = "妖术领主-通用机制库(纯透传)",
    checkFunction = WarriorYSLZCheck,
})

local function WarriorZJCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForWarrior()
end

WR_Warrior_RegisterBoss({
    bossNames = {"祖金", "Zul'jin", "祖阿曼6号"},
    className = "WARRIOR",
    action = "stop",
    description = "祖金-通用机制库(纯透传)",
    checkFunction = WarriorZJCheck,
})


-- ============================================================
-- ★ 统一入口（由 MainLoop 直接调用，无注册表中间件）
--   按当前目标名查本地派发表；命中则调用对应检查函数
--   太阳井(1-6号) 默认不触发（SW_BOSS_SPECIALS_OFF 守卫，用户只需输出循环）
-- ============================================================
function WR_Warrior_BossSpecials()
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