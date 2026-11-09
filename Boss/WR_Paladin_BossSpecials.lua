-- ============================================================
-- WR_Paladin_BossSpecials.lua
-- 圣骑士职业差异化 BOSS 特化逻辑
--
-- 核心设计：
--   1. 区分坦克（防护）/ DPS（惩戒）/ 治疗（神圣），按角色类型筛选机制
--   2. 治疗（神圣）自动跳过 BOSS 特化检查
--   3. 基于 WR_BossMechanics 配置库，按角色类型检索适用机制
--   4. 圣骑士特有机制：坦克冰龙吐息开圣盾术/圣佑术、坦克血议会自动切目标等
--   5. 直接使用 WR_ColorFrame_Show 显示颜色（绕过 WR_ColorAdapter）
--   6. 颜色映射：stop=3, target=4, defensive=8, rocketboots=108, lk_contamination=107
--
-- 包含的 BOSS 特化：
--   1. 冰龙辛达苟萨 - 坦克吐息防御/刺骨停手/DPS刺骨停手
--   2. 血议会 - 坦克自动切目标/DPS过滤无效目标
--   3. 灵魂熔炉 - 坦克灵魂倒映停手/DPS灵魂倒映停手
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

if WR_PlayerClass ~= "PALADIN" then return end

if select(2, UnitClass("player")) ~= "PALADIN" then
    return
end

-- ============================================================
-- ★ 本地 BOSS 特化派发表（替代已删除的 WR_BossRegistry 注册表中间件）
--   每个 BOSS 名 → 对应检查函数，MainLoop 直接按目标名查表调用
-- ============================================================
local BOSS_SPECIALS_BY_NAME = {}
local function WR_Paladin_RegisterBoss(spec)
    if not spec or not spec.bossNames or not spec.checkFunction then return end
    for _, name in ipairs(spec.bossNames) do
        BOSS_SPECIALS_BY_NAME[name] = spec.checkFunction
    end
end

-- ============================================================
-- ★ 共享工具（来自 WR_BossUtils，避免重复定义）
-- ============================================================
local GetDebuffCount = WR_BossUtils.GetDebuffCount
local HasBuff = WR_BossUtils.HasBuff
local HasDebuff = WR_BossUtils.HasDebuff
local GetPlayerHP = WR_BossUtils.GetPlayerHP
local ColorMap = WR_BossUtils.ColorMap
local ShowColor = WR_BossUtils.ShowColor

-- ============================================================
-- ★ 圣骑士角色类型判断
--   防护(tank) / 惩戒(melee_dps) / 神圣(healer)
-- ============================================================
local function GetPaladinRole()
    local holyRank = select(5, GetTalentTabInfo(1))
    local protRank = select(5, GetTalentTabInfo(2))
    local retRank = select(5, GetTalentTabInfo(3))

    if protRank > holyRank and protRank > retRank then
        return "tank"
    elseif holyRank > protRank and holyRank > retRank then
        return "healer"
    else
        return "melee_dps"
    end
end

local function IsPaladinTank()
    return GetPaladinRole() == "tank"
end

local function IsPaladinDPS()
    return GetPaladinRole() == "melee_dps"
end

-- ============================================================
-- ★ 1. 冰龙辛达苟萨 - 差异化处理
-- ============================================================

local function SindragosaCheck()
    local role = GetPaladinRole()
    local targetName = UnitName("target")

    if targetName ~= "辛达苟萨" and targetName ~= "Sindragosa" then
        return false
    end

    if role == "tank" then
        -- 坦克：冰冷吐息开圣盾术/圣佑术
        if HasDebuff("player", "冰冷吐息") or HasDebuff("player", "冰霜吐息") then
            ShowColor("defensive", "冰龙吐息-开圣盾术/圣佑术")
            return true
        end

        -- 坦克：刺骨层数达标停手
        local chilledCount = GetDebuffCount("player", "寒霜刺骨")
        if chilledCount >= 5 then
            ShowColor("stop", "冰龙刺骨-坦克停手")
            return true
        end

        -- 坦克：冰封停手
        if HasDebuff("player", "冰封") then
            ShowColor("stop", "冰龙冰封-坦克停手")
            return true
        end
    elseif role == "melee_dps" then
        -- DPS：刺骨停手
        local chilledCount = GetDebuffCount("player", "寒霜刺骨")
        local HSCG = PigSet and PigSet.WQZ_HSCG or 0
        local threshold = (HSCG ~= 7) and (HSCG + 4) or 5
        if chilledCount and chilledCount >= threshold then
            ShowColor("stop", "冰龙刺骨-DPS停手")
            return true
        end

        -- DPS：冰封停手
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
    local role = GetPaladinRole()
    local targetName = UnitName("target")

    if role == "tank" then
        -- 坦克：过滤无效目标 + 自动切目标
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
    elseif role == "melee_dps" then
        -- DPS：过滤无效目标
        if targetName == "动力炸弹" or targetName == "黑暗之核" then
            ShowColor("stop", "血议会-DPS过滤无效目标")
            return true
        end
    end

    return false
end

-- ============================================================
-- ★ 3. 灵魂熔炉 - 灵魂倒映（坦克 + DPS）
-- ============================================================

local function ForgeOfSoulsCheck()
    local role = GetPaladinRole()
    local targetName = UnitName("target")

    -- 坦克和 DPS 都需要处理灵魂倒映
    if role == "tank" or role == "melee_dps" then
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
    end

    return false
end

-- ============================================================
-- ★ 4. 海里昂 - 低血量火箭靴（DPS）/ 坦克低血量防御
-- ============================================================

local function HalionCheck()
    local targetName = UnitName("target")
    local role = GetPaladinRole()

    if targetName ~= "海里昂" and targetName ~= "Halion" then
        return false
    end

    if role == "tank" then
        local hp = GetPlayerHP()
        if hp < 20 then
            ShowColor("defensive", "海里昂-坦克低血量防御")
            return true
        end
    elseif role == "melee_dps" then
        local hp = GetPlayerHP()
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
    local role = GetPaladinRole()
    if role ~= "melee_dps" then
        return false
    end

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
    local role = GetPaladinRole()
    if role ~= "melee_dps" then
        return false
    end

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
    local role = GetPaladinRole()
    local targetName = UnitName("target")

    if targetName ~= "巫妖王" and targetName ~= "The Lich King" and targetName ~= "LK" then
        return false
    end

    if role == "melee_dps" then
        if HasDebuff("player", "污染") or HasDebuff("player", "冰封王座") then
            ShowColor("lk_contamination", "巫妖王-污染跑位")
            return true
        end
    elseif role == "tank" then
        -- 坦克低血量防御
        local hp = GetPlayerHP()
        if hp < 15 then
            ShowColor("defensive", "巫妖王-坦克低血量防御")
            return true
        end
    end

    return false
end

-- ============================================================
-- ★ 8. 观察者奥尔加隆 - 宇宙撞击/坍缩之星停手（DPS）
-- ============================================================

local function AlgalonCheck()
    local role = GetPaladinRole()
    if role ~= "melee_dps" then
        return false
    end

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
    local role = GetPaladinRole()
    if role ~= "melee_dps" then
        return false
    end

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
    local role = GetPaladinRole()
    if role ~= "melee_dps" then
        return false
    end

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
    local role = GetPaladinRole()
    if role ~= "melee_dps" then
        return false
    end

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
    local role = GetPaladinRole()
    if role ~= "melee_dps" then
        return false
    end

    local targetName = UnitName("target")

    if targetName == "炮舰" or targetName == "天界飞船" or targetName == "Gunship" then
        local hp = GetPlayerHP()
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
    local role = GetPaladinRole()
    if role ~= "melee_dps" then
        return false
    end

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
--   检查函数返回 true 时阻塞正常职业循环
-- ============================================================

WR_Paladin_RegisterBoss({
    bossNames = {"辛达苟萨", "Sindragosa", "冰霜女王", "The Frost Queen"},
    className = "PALADIN",
    talent = "防护",
    action = "defensive",
    description = "冰龙特化-坦克",
    checkFunction = SindragosaCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"辛达苟萨", "Sindragosa"},
    className = "PALADIN",
    talent = "惩戒",
    action = "stop",
    description = "冰龙特化-DPS",
    checkFunction = SindragosaCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"血议会", "鲜血议会", "Blood Council", "塔达拉姆王子", "瓦拉纳王子", "凯雷塞斯王子"},
    className = "PALADIN",
    talent = "防护",
    action = "target",
    description = "血议会特化-坦克",
    checkFunction = BloodCouncilCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"血议会", "鲜血议会", "Blood Council"},
    className = "PALADIN",
    talent = "惩戒",
    action = "stop",
    description = "血议会特化-DPS",
    checkFunction = BloodCouncilCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"灵魂熔炉", "锻造之魂", "Forge of Souls", "镜像", "腐化的灵魂"},
    className = "PALADIN",
    talent = "防护",
    action = "stop",
    description = "灵魂熔炉特化-坦克",
    checkFunction = ForgeOfSoulsCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"灵魂熔炉", "锻造之魂", "Forge of Souls"},
    className = "PALADIN",
    talent = "惩戒",
    action = "stop",
    description = "灵魂熔炉特化-DPS",
    checkFunction = ForgeOfSoulsCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"海里昂", "Halion"},
    className = "PALADIN",
    talent = "防护",
    action = "defensive",
    description = "海里昂特化-坦克",
    checkFunction = HalionCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"海里昂", "Halion"},
    className = "PALADIN",
    talent = "惩戒",
    action = "rocketboots",
    description = "海里昂特化-DPS",
    checkFunction = HalionCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"普崔塞德教授", "Professor Putricide", "Putricide", "不稳定的软泥怪", "毒气之云"},
    className = "PALADIN",
    talent = "惩戒",
    action = "stop",
    description = "教授特化-DPS",
    checkFunction = PutricideCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"死亡使者萨鲁法尔", "Deathbringer Saurfang", "萨鲁法尔", "Saurfang"},
    className = "PALADIN",
    talent = "惩戒",
    action = "defensive",
    description = "萨鲁法尔特化-DPS",
    checkFunction = SaurfangCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"巫妖王", "The Lich King", "LK", "阿尔萨斯"},
    className = "PALADIN",
    talent = "防护",
    action = "defensive",
    description = "巫妖王特化-坦克",
    checkFunction = LKCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"巫妖王", "The Lich King", "LK", "阿尔萨斯"},
    className = "PALADIN",
    talent = "惩戒",
    action = "lk_contamination",
    description = "巫妖王特化-DPS",
    checkFunction = LKCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"观察者奥尔加隆", "Algalon the Observer", "奥尔加隆", "Algalon"},
    className = "PALADIN",
    talent = "惩戒",
    action = "stop",
    description = "奥尔加隆特化-DPS",
    checkFunction = AlgalonCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"尤格萨隆", "Yogg-Saron", "Yogg", "尤格萨隆的触手"},
    className = "PALADIN",
    talent = "惩戒",
    action = "stop",
    description = "尤格萨隆特化-DPS",
    checkFunction = YoggCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"鲜血女王兰娜瑟尔", "Blood-Queen Lana'thel", "血女王"},
    className = "PALADIN",
    talent = "惩戒",
    action = "stop",
    description = "血女王特化-DPS",
    checkFunction = BloodQueenCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"腐面", "Festergut", "烂肠", "Rotface"},
    className = "PALADIN",
    talent = "惩戒",
    action = "stop",
    description = "腐面/烂肠特化-DPS",
    checkFunction = MutantCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"炮舰", "天界飞船", "Gunship"},
    className = "PALADIN",
    talent = "惩戒",
    action = "rocketboots",
    description = "炮舰特化-DPS",
    checkFunction = GunshipCheck,
})

WR_Paladin_RegisterBoss({
    bossNames = {"翡翠巨龙", "绯红巨龙守护者", "Valithria"},
    className = "PALADIN",
    talent = "惩戒",
    action = "stop",
    description = "翡翠巨龙特化-DPS",
    checkFunction = DragonCheck,
})

-- ============================================================
-- ★ 14. TOC双子 - 光明/黑暗Essence切换 + 黑暗漩涡防御
--     来源：集成外部插件优化逻辑 + MY插件通用机制
--     骑士特化调整：
--       1) 光明Essence时提示切换目标(DPS)
--       2) 黑暗漩涡出现时使用圣盾术/圣佑术(坦克)
-- ============================================================
local TwinsDarkVortexActive = false

local function TwinsCheck()
    -- 1) 同色攻击提示(DPS)
    local role = GetPaladinRole()
    if role == "melee_dps" then
        if HasDebuff("player", "光明 Essence") or HasDebuff("player", "黑暗 Essence") then
            local cid = ShowColor("target", "双子-同色攻击切换")
            return true, cid
        end
    end
    
    -- 2) 黑暗漩涡防御(坦克)
    if role == "tank" then
        if TwinsDarkVortexActive and HasDebuff("player", "光明 Essence") then
            -- 光明Essence期间如果有黑暗漩涡,使用圣盾术/圣佑术
            if HasBuff("player", "圣盾术") or HasBuff("player", "圣佑术") then
                local cid = ShowColor("defensive", "双子-黑暗漩涡防御")
                return true, cid
            end
        end
    end
    
    -- 3) 通用Boss机制检查
    local triggered, overrideColor = CheckBossMechanicsForPaladin()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Paladin_RegisterBoss({
    bossNames = {"双子", "姐妹", "Twins", "Lady Liadrin", "Sister Solastria"},
    className = "PALADIN",
    action = "stop",
    description = "双子-Twins Essence切换+黑暗漩涡",
    checkFunction = TwinsCheck,
})

-- ============================================================
-- ★ 15. TOC兽王 - Animal Husbandry转火 + 召唤物处理
--     来源：集成外部插件优化逻辑 + MY插件通用机制
--     骑士特化调整：
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
    local triggered, overrideColor = CheckBossMechanicsForPaladin()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Paladin_RegisterBoss({
    bossNames = {"兽王", "野兽之主", "Beast Master", "Archerus"},
    className = "PALADIN",
    action = "stop",
    description = "兽王-召唤物过滤+兽王诅咒",
    checkFunction = BeastMasterCheck,
})

-- ============================================================
-- ★ 16. ZG耶克里克 - 蝙蝠群AOE智能触发
--     来源：另外循环插件特化\术士\204FF6B1.lua（耶克里克.lua）
--     骑士特化调整：
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
    local triggered, overrideColor = CheckBossMechanicsForPaladin()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Paladin_RegisterBoss({
    bossNames = {"高阶祭司耶克里克", "HighPriestessJeklik", "祖格耶克里克", "Jeklik"},
    className = "PALADIN",
    action = "aoe",
    description = "耶克里克-蝙蝠群AOE智能触发",
    checkFunction = JeklikCheck,
})

-- ============================================================
-- ★ 17. ZG曼多基尔 - 威慑凝视停手
--     来源：另外循环插件特化\术士\A320FFE3.lua（曼多基尔.lua）
--     骑士特化调整：
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
    local triggered, overrideColor = CheckBossMechanicsForPaladin()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Paladin_RegisterBoss({
    bossNames = {"血领主曼多基尔", "BloodlordMandokir", "祖格曼多基尔", "Mandokir"},
    className = "PALADIN",
    action = "stop",
    description = "曼多基尔-威慑凝视停手",
    checkFunction = MandokirCheck,
})

-- ============================================================
-- ★ 18. ZG哈卡 - 灵魂吞噬处理 + 哈卡之子转火
--     来源：集成外部插件优化逻辑 + MY插件通用机制
--     骑士特化调整：
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
    local triggered, overrideColor = CheckBossMechanicsForPaladin()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Paladin_RegisterBoss({
    bossNames = {"哈卡尔·灵魂掠夺者", "哈卡", "Hakkar", "ZG哈卡"},
    className = "PALADIN",
    action = "stop",
    description = "哈卡-灵魂吞噬+哈卡之子转火",
    checkFunction = HakkarCheck,
})

-- ============================================================
-- ★ 19. ZG温诺希斯 - 拉扎什眼镜蛇AOE处理
--     来源：另外循环插件特化\术士\B137416E.lua（温诺希斯.lua）
--     骑士特化调整：
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
    local triggered, overrideColor = CheckBossMechanicsForPaladin()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Paladin_RegisterBoss({
    bossNames = {"高阶祭司温诺希斯", "Venoxis", "祖格温诺希斯", "Wushoolay"},
    className = "PALADIN",
    action = "aoe",
    description = "温诺希斯拉扎什眼镜蛇AOE",
    checkFunction = VenoxisCheck,
})

-- ============================================================
-- ★ 20. ZG金度 - 妖术蝙蝠AOE + 放逐传送处理
--     来源：集成外部插件优化逻辑 (JindoBanishTeleport)
--     骑士特化调整：
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
    local triggered, overrideColor = CheckBossMechanicsForPaladin()
    if triggered then
        return true, overrideColor
    end
    
    return false
end

WR_Paladin_RegisterBoss({
    bossNames = {"妖术师金度", "Jeklik", "祖格金度", "Shirad"},
    className = "PALADIN",
    action = "stop",
    description = "金度-妖术蝙蝠AOE+放逐传送",
    checkFunction = JindoCheck,
})


-- ============================================================
-- 通用职业机制分发（纯透传）
--   复用全局 WR_CheckBossMechanics() 检查当前 Boss 全部机制，
--   由机制自身 checkFunction 决定触发（多形态职业不硬编码角色）
-- ============================================================
local function CheckBossMechanicsForPaladin()
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
-- ============================================================

local function PaladinKLGSCheck()
    if HasDebuff("player", "腐蚀") or HasDebuff("player", "燃烧") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"卡雷苟斯", "Kalecgos", "太阳井1号", "腐蚀者萨索瓦尔", "Sathrovarr"},
    className = "PALADIN",
    action = "stop",
    description = "卡雷苟斯-清洁/无敌解腐蚀燃烧 / 通用兜底",
    checkFunction = PaladinKLGSCheck,
})

local function PaladinBLTLCheck()
    if HasDebuff("player", "燃烧之血") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"布鲁塔卢斯", "Brutallus", "太阳井2号"},
    className = "PALADIN",
    action = "stop",
    description = "布鲁塔卢斯-清洁/无敌解燃烧 / 通用兜底",
    checkFunction = PaladinBLTLCheck,
})

local function PaladinFMSCheck()
    if HasDebuff("player", "腐蚀气体") or HasDebuff("player", "腐蚀吐息") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"菲米丝", "Felmyst", "太阳井3号"},
    className = "PALADIN",
    action = "stop",
    description = "菲米丝-清洁/无敌解腐蚀吐息 / 通用兜底",
    checkFunction = PaladinFMSCheck,
})

local function PaladinTWINSCheck()
    if HasDebuff("player", "暗影之痛") or HasDebuff("player", "火焰之痛") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"艾瑞达双子", "Eredar Twins", "Alythess", "Brannjar", "太阳井4号"},
    className = "PALADIN",
    action = "stop",
    description = "艾瑞达双子-清洁/无敌解双子之痛 / 通用兜底",
    checkFunction = PaladinTWINSCheck,
})

local function PaladinMURUCheck()
    if HasDebuff("player", "熵") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"穆鲁", "M'uru", "Muru", "太阳井5号"},
    className = "PALADIN",
    action = "stop",
    description = "穆鲁-清洁/无敌解熵 / 通用兜底",
    checkFunction = PaladinMURUCheck,
})

local function PaladinKJCheck()
    if HasDebuff("player", "暗影之矛") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"基尔加丹", "Kil'jaeden", "Kiljaeden", "太阳井6号"},
    className = "PALADIN",
    action = "stop",
    description = "基尔加丹-清洁/无敌解暗影之矛 / 通用兜底",
    checkFunction = PaladinKJCheck,
})

local function PaladinYWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"鹰王", "Akil'zon", "Akilzon", "艾基利松", "祖阿曼1号"},
    className = "PALADIN",
    action = "stop",
    description = "鹰王-通用机制库(纯透传)",
    checkFunction = PaladinYWCheck,
})

local function PaladinXWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"熊王", "Nalorakk", "纳洛拉克", "祖阿曼2号"},
    className = "PALADIN",
    action = "stop",
    description = "熊王-通用机制库(纯透传)",
    checkFunction = PaladinXWCheck,
})

local function PaladinLHYCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"龙鹰王", "Jan'alai", "Janalai", "贾恩阿拉伊", "祖阿曼3号"},
    className = "PALADIN",
    action = "stop",
    description = "龙鹰王-通用机制库(纯透传)",
    checkFunction = PaladinLHYCheck,
})

local function PaladinBWCheck()
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"豹王", "Halazzi", "哈拉兹", "祖阿曼4号"},
    className = "PALADIN",
    action = "stop",
    description = "豹王-通用机制库(纯透传)",
    checkFunction = PaladinBWCheck,
})

local function PaladinYSLZCheck()
    if HasDebuff("player", "妖术") or HasDebuff("player", "变青蛙") or HasDebuff("player", "灵魂吸取") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"妖术领主", "Hex Lord Malacrass", "HexLord", "玛拉卡斯", "祖阿曼5号"},
    className = "PALADIN",
    action = "stop",
    description = "妖术领主-清洁/无敌解妖术/灵魂吸取 / 通用兜底",
    checkFunction = PaladinYSLZCheck,
})

local function PaladinZJCheck()
    if HasDebuff("player", "毒") or HasDebuff("player", "致命毒液") then
        return true, (WR_BossUtils.ColorMap and WR_BossUtils.ColorMap["defensive"] or 8)
    end
    -- 通用机制库兜底（停手/走位/减伤等按角色）
    return CheckBossMechanicsForPaladin()
end

WR_Paladin_RegisterBoss({
    bossNames = {"祖金", "Zul'jin", "祖阿曼6号"},
    className = "PALADIN",
    action = "stop",
    description = "祖金-清洁解毒 / 通用兜底",
    checkFunction = PaladinZJCheck,
})


-- ============================================================
-- ★ 统一入口（由 MainLoop 直接调用，无注册表中间件）
--   按当前目标名查本地派发表；命中则调用对应检查函数
--   检查函数内部已按角色(坦克/DPS/治疗)自过滤，治疗直接跳过
-- ============================================================
function WR_Paladin_BossSpecials()
    -- 治疗（神圣）自动跳过 BOSS 特化检查
    if GetPaladinRole() == "healer" then
        return false
    end
    local targetName = UnitName("target")
    if not targetName then
        return false
    end
    local fn = BOSS_SPECIALS_BY_NAME[targetName]
    if fn then
        local ok, trig = pcall(fn)
        if ok and trig then
            return true
        end
    end
    return false
end