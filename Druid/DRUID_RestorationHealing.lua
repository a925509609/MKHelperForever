-- ============================================================
-- DRUID_RestorationHealing.lua
-- 德鲁伊奶德四级治疗决策链+树人形态监控+团队权重系统
-- 包含：
--   1. 四级治疗优先级队列(decisionLvlUpHealer)
--   2. 树人形态监控与群体治疗(EntreatyOfTheAncients)
--   3. 团队伤害权重计算(healthGapEst)
--   4. 自动选目标治疗智能判断
--
--   来源文件: 18FF444A(L1629-L1635决策链)/EAB86A35(healerMaxRange=40)/C741ACEA(L646-L678权重计算)
-- ============================================================

if WR_PlayerClass ~= "DRUID" then return end

if select(2, UnitClass("player")) ~= "DRUID" then
    return
end

-- ============================================================
-- ★ 全局变量
-- ============================================================
local lastHealCheckTime = 0          -- 上次治疗检测时间
local entreatyActive = false         -- 树人是否激活
local healerMaxRange = 40            -- 治疗最大范围(40码)
local teamWeightData = {}            -- 团队权重数据缓存

-- ============================================================
-- ★ 辅助函数1: 获取队友血量信息
-- 来源: C741ACEA-E58F-4786-B988-3D6219F40E8A.lua (L646-L678)
-- ============================================================
function WR_DR_GetTeamHealthInfo(unitToken)
    local currentHP = WR_SafeNumber(UnitHealth(unitToken), WR_SafeNumber(UnitHealthMax(unitToken), 1)) or 0
    local maxHP = WR_SafeNumber(UnitHealthMax(unitToken), 1) or 1
    
    if maxHP == 0 then
        maxHP = 1
    end
    
    local healthPercent = currentHP / maxHP
    local healthGap = 1 - healthPercent  -- 血量缺口(0~1)
    local healthGapEst = healthGap * 100  -- 百分比估算(0~100)
    
    return {
        unitToken = unitToken,
        currentHP = currentHP,
        maxHP = maxHP,
        healthPercent = healthPercent,
        healthGap = healthGap,
        healthGapEst = healthGapEst,
        isDead = (currentHP == 0)
    }
end

-- ============================================================
-- ★ 辅助函数2: 扫描团队/小队成员
-- 来源: EAB86A35-908D-42C5-B1D6-82EBCF6AC6C5.lua (L29-L40)
-- ============================================================
function WR_DR_ScanTeamMembers()
    local members = {}
    local partySize = GetNumGroupMembers() or 0
    
    if partySize > 0 then
        -- 5人小队模式
        for i = 1, 5 do
            local unitId = "party" .. (i - 1)
            if UnitExists(unitId) and not UnitIsDead(unitId) then
                table.insert(members, unitId)
            end
        end
        
        -- 小队Target模式
        for i = 0, 4 do
            local unitId = "party" .. i .. "target"
            if UnitExists(unitId) and not UnitIsDead(unitId) then
                table.insert(members, unitId)
            end
        end
    else
        -- 单人模式(玩家自己)
        table.insert(members, "player")
        
        -- 5人副本默认5队
        for i = 1, 20 do
            local unitId = "raid" .. i
            if UnitExists(unitId) and not UnitIsDead(unitId) then
                table.insert(members, unitId)
            end
        end
    end
    
    return members
end

-- ============================================================
-- ★ 核心函数1: 四级治疗决策链
-- 来源: 18FF444A-F5CE-49FC-AD49-2D6D29F797BE.lua (L1629-L1635)
-- 功能: 按优先级自动选择治疗技能
-- ============================================================
function WR_DR_GetHealSkillPriority()
    local now = GetTime()
    
    -- 每0.5秒重新评估一次
    if now - lastHealCheckTime < 0.5 then
        return PigSet.DRUID_LAST_HEAL_SKILL or "none"
    end
    lastHealCheckTime = now
    
    local members = WR_DR_ScanTeamMembers()
    
    -- ===============================
    -- P1: 急救药水(xjzy) - 紧急救急
    -- 条件: 队友HP<60% + 回春buff存在
    -- 来源: 18FF444A L1560-L1568
    -- ===============================
    for _, unitId in ipairs(members) do
        local info = WR_DR_GetTeamHealthInfo(unitId)
        
        if info.healthPercent < 0.6 then
            if HasBuff(unitId, "回春术") and IsSpellUsable("急救药水") then
                PigSet.DRUID_TARGET_UNIT = unitId
                PigSet.DRUID_HEAL_SKILL = "xjzy"
                print(string.format("|cFFFFFF00[奶德]|r P1急救药水! %s HP<60%%", UnitName(unitId)))
                return "xjzy"
            end
        end
    end
    
    -- ===============================
    -- P2: 回春术(huichun) - 维持DOT治疗
    -- 条件: 队友HP<85% + 无回春buff
    -- 来源: 18FF444A L1570-L1578
    -- ===============================
    for _, unitId in ipairs(members) do
        local info = WR_DR_GetTeamHealthInfo(unitId)
        
        if info.healthPercent < 0.85 then
            if not HasBuff(unitId, "回春术") then
                if IsSpellUsable("回春术") and WR_DR_IsInRange(unitId) then
                    PigSet.DRUID_TARGET_UNIT = unitId
                    PigSet.DRUID_HEAL_SKILL = "huichun"
                    print(string.format("|cff00ff00[奶德]|r P2回春术! %s HP=%.0f%%", UnitName(unitId), info.healthPercent * 100))
                    return "huichun"
                end
            end
        end
    end
    
    -- ===============================
    -- P3: 愈合(yuhe) - 大面积掉血
    -- 条件: Tank HP<70% / 其他HP<50%
    -- 来源: 18FF444A L1581-L1603
    -- ===============================
    for _, unitId in ipairs(members) do
        local info = WR_DR_GetTeamHealthInfo(unitId)
        
        if not info.isDead then
            local shouldUseYuhe = false
            
            -- 坦克优先级
            if WR_DR_GetDruidRole() == "tank" and unitId == "player" then
                if info.healthPercent < 0.7 and not HasBuff(unitId, "愈合") then
                    shouldUseYuhe = true
                end
            else
                -- 非坦克
                if info.healthPercent < 0.5 and not HasBuff(unitId, "愈合") then
                    shouldUseYuhe = true
                end
            end
            
            if shouldUseYuhe and IsSpellUsable("愈合") and WR_DR_IsInRange(unitId) then
                PigSet.DRUID_TARGET_UNIT = unitId
                PigSet.DRUID_HEAL_SKILL = "yuhe"
                print(string.format("|cFF00FFFF[奶德]|r P3愈合! %s HP=%.0f%%", UnitName(unitId), info.healthPercent * 100))
                return "yuhe"
            end
        end
    end
    
    -- ===============================
    -- P4: 治疗之触(zlzc) - 精细治疗
    -- 条件: Tank HP<70% / 其他HP<50%(无愈合时)
    -- 来源: 18FF444A L1605-L1627
    -- ===============================
    for _, unitId in ipairs(members) do
        local info = WR_DR_GetTeamHealthInfo(unitId)
        
        if not info.isDead then
            local shouldUseZlzc = false
            
            if WR_DR_GetDruidRole() == "tank" and unitId == "player" then
                if info.healthPercent < 0.7 then
                    shouldUseZlzc = true
                end
            else
                if info.healthPercent < 0.5 then
                    shouldUseZlzc = true
                end
            end
            
            if shouldUseZlzc and IsSpellUsable("治疗之触") and WR_DR_IsInRange(unitId) then
                PigSet.DRUID_TARGET_UNIT = unitId
                PigSet.DRUID_HEAL_SKILL = "zlzc"
                print(string.format("|cff8888ff[奶德]|r P4治疗之触! %s HP=%.0f%%", UnitName(unitId), info.healthPercent * 100))
                return "zlzc"
            end
        end
    end
    
    return "none"  -- 无需治疗
end

-- ============================================================
-- ★ 核心函数2: 树人形态监控
-- 来源: EAB86A35-EAB86A35-908D-42C5-B1D6-82EBCF6AC6C5.lua
-- 功能: 检测远古意志buff并激活群体治疗
-- ============================================================
function WR_DR_CheckEntreatyForm()
    local now = GetTime()
    
    -- 每1秒检测一次
    if now - lastHealCheckTime < 1 then
        return entreatyActive
    end
    
    -- 检测远古意志buff(树人激活期间)
    if HasBuff("player", "远古意志") or HasBuff("player", "EntreatyOfTheAncients") then
        if not entreatyActive then
            entreatyActive = true
            print("|cFF00ff00[奶德]|r *** 树人形态激活! ***")
            print("|cFF00ff00[奶德]|r 启用群体回春/愈合模式!")
        end
        
        -- 树人居期间优先使用群体治疗
        if IsSpellUsable("群体回春") then
            local hasLowHPMember = false
            
            local members = WR_DR_ScanTeamMembers()
            for _, unitId in ipairs(members) do
                local info = WR_DR_GetTeamHealthInfo(unitId)
                
                if info.healthPercent < 0.8 and WR_DR_IsInRange(unitId, healerMaxRange) then
                    hasLowHPMember = true
                    break
                end
            end
            
            if hasLowHPMember then
                PigSet.DRUID_AOE_HEAL = true
                print("|cFFFFFF00[奶德]|r 检测到伤血队友,使用群体回春!")
            end
        end
    else
        if entreatyActive then
            entreatyActive = false
            PigSet.DRUID_AOE_HEAL = false
            print("|cff888888[奶德]|r 树人形态结束")
        end
    end
    
    return entreatyActive
end

-- ============================================================
-- ★ 核心函数3: 团队伤害权重计算
-- 来源: C741ACEA-E58F-4786-B988-3D6219F40E8A.lua (L646-L678)
-- 功能: 动态计算每个队友的治疗优先级权重
-- ============================================================
function WR_DR_CalculateTeamWeights()
    local members = WR_DR_ScanTeamMembers()
    local totalGroupGap = 0
    
    -- 清空旧数据
    teamWeightData = {}
    
    -- 计算每个成员权重
    for _, unitId in ipairs(members) do
        local info = WR_DR_GetTeamHealthInfo(unitId)
        
        teamWeightData[unitId] = {
            name = UnitName(unitId),
            healthPercent = info.healthPercent,
            healthGapEst = info.healthGapEst,
            priority = 0  -- 临时优先级(后续计算)
        }
        
        totalGroupGap = totalGroupGap + info.healthGapEst
    end
    
    -- 计算相对优先级(缺口越大优先级越高)
    for unitId, data in pairs(teamWeightData) do
        if totalGroupGap > 0 then
            data.priority = data.healthGapEst / totalGroupGap  -- 占比权重
        else
            data.priority = 0
        end
        
        -- 转换为1~N的排名(1=最高优先级)
        data.rank = 1
        for otherUnitId, otherData in pairs(teamWeightData) do
            if otherData.healthGapEst > data.healthGapEst then
                data.rank = data.rank + 1
            end
        end
    end
    
    return teamWeightData, totalGroupGap
end

-- ============================================================
-- ★ 工具函数: 获取最高优先级治疗目标
-- ============================================================
function WR_DR_GetHighestPriorityTarget()
    if not next(teamWeightData) then
        WR_DR_CalculateTeamWeights()
    end
    
    local bestTarget = nil
    local bestRank = 999
    
    for unitId, data in pairs(teamWeightData) do
        if data.rank < bestRank then
            bestRank = data.rank
            bestTarget = unitId
        end
    end
    
    return bestTarget, teamWeightData[bestTarget]
end

-- ============================================================
-- ★ 工具函数: 重置所有计时器
-- ============================================================
function WR_DR_ResetHealingTimers()
    lastHealCheckTime = 0
    entreatyActive = false
    teamWeightData = {}
end

-- ============================================================
-- ★ 导出
-- ============================================================
