-- ============================================================
-- DRUID_AOE_Optimization.lua
-- 德鲁伊AOE智能触发系统（借鉴外部插件高效逻辑）
-- 包含：
--   1. 跳怪检测与范围统计(每0.3秒更新)
--   2. 横扫(AoE)自动释放判定
--   3. AOE/单体模式自动切换
--   4. 月光/昆虫群DOT刷新优化
--
--   来源文件: C741ACEA(L165-L207跳转检测)/18FF444A(L1723决策链)
-- ============================================================

if WR_PlayerClass ~= "DRUID" then return end

if select(2, UnitClass("player")) ~= "DRUID" then
    return
end

-- ============================================================
-- ★ 全局变量
-- ============================================================
local lastAoeCheckTime = 0          -- 上次AOE检测时间
local attackingEnemiesCount = 0     -- 威胁目标数量
local lastSwipeCastTime = 0         -- 上次横扫施法时间

-- ============================================================
-- ★ 辅助函数1: 威胁目标统计(跳怪检测)
-- 来源: C741ACEA-E58F-4786-B988-3D6219F40E8A.lua (L165-L207 npFind)
-- 功能: 遍历名字面板扫描威胁目标
-- ============================================================
function WR_DR_UpdateAttackingEnemiesCount()
    local now = GetTime()
    
    -- 每0.3秒扫描一次(性能优化)
    if now - lastAoeCheckTime < 0.3 then
        return attackingEnemiesCount
    end
    lastAoeCheckTime = now
    
    attackingEnemiesCount = 0
    local myRange = WR_DR_GetTalentMaxRange() or 30
    
    for i = 1, math.min(50, C_NamePlate.GetNamePlateCount()) do
        local nameplate = C_NamePlate.GetNamePlateForUnitNumber(i)
        if nameplate and nameplate.unitToken then
            local unitToken = nameplate.unitToken
            
            -- 检查是否能攻击
            if UnitCanAttack("player", unitToken) then
                -- 检查是否在范围内
                local distance = WR_DR_GetDistanceToUnit(unitToken)
                
                if distance <= myRange then
                    -- 检查是否有威胁(UnitThreatSituation)
                    local threatStatus = UnitThreatSituation("player", unitToken)
                    
                    if threatStatus and threatStatus > 0 then
                        attackingEnemiesCount = attackingEnemiesCount + 1
                    end
                end
            end
        end
    end
    
    return attackingEnemiesCount
end

-- ============================================================
-- ★ 辅助函数2: 获取天赋最大范围
-- ============================================================
function WR_DR_GetTalentMaxRange()
    -- 从P0-1模块导入
    if WR_DR_UpdateTalentMaxRange then
        WR_DR_UpdateTalentMaxRange()
        return talentMaxRangeMain or 35
    end
    
    --  fallback: 根据形态判断
    local form = WR_DR_GetDruidForm()
    
    if form == "balance" then
        return 35  -- 远程德
    else
        return 8   -- 近战德(猫/熊)
    end
end

-- ============================================================
-- ★ 核心函数1: 横扫(AoE)自动释放判定
-- 来源: 18FF444A-F5CE-49FC-AD49-2D6D29F797BE.lua (L1649-L1663 bear swipe)
-- 功能: 根据威胁目标数量自动触发横扫
-- ============================================================
function WR_DR_AutoSwipe()
    local form = WR_DR_GetDruidForm()
    
    -- 只有熊形态和猫形态有横扫技能
    if form ~= "bear" and form ~= "cat" then
        return false
    end
    
    -- 检测威胁目标数量
    local enemyCount = WR_DR_UpdateAttackingEnemiesCount()
    
    if enemyCount >= 2 then
        -- 2只或以上怪物时,使用横扫
        local swipeSpellName = (form == "bear") and "横扫（熊）" or "横扫（豹）"
        
        if IsSpellUsable(swipeSpellName) then
            -- 检查是否正在施法(避免打断当前技能)
            if not CastingInfo() then
                CastSpellByName(swipeSpellName)
                lastSwipeCastTime = GetTime()
                print(string.format("|cFFFFFF00[德鲁伊]|r 检测到%d只威胁目标,使用横扫!", enemyCount))
                return true
            end
        end
    end
    
    return false
end

-- ============================================================
-- ★ 核心函数2: AOE/单体模式自动切换
-- 来源: 外部插件通用逻辑反推(基于npFind系统)
-- ============================================================
function WR_DR_SwitchAOEMode()
    local enemyCount = WR_DR_UpdateAttackingEnemiesCount()
    
    if enemyCount >= 3 then
        -- 切换到AOE模式
        if PigSet.DRUID_AOE_MODE ~= true then
            PigSet.DRUID_AOE_MODE = true
            print("|cFFFFFF00[德鲁伊]|r *** 进入AOE模式 ***")
            print("|cFFFFFF00[德鲁伊]|r 威胁目标≥3只,优先横扫/月火/昆虫群")
        end
        
        -- AOE模式下提高月亮火焰优先级
        PigSet.DRUID_MOONFIRE_PRIORITY = true
        PigSet.DRUID_INSECT_SWARM_PRIORITY = true
        
    elseif enemyCount < 2 then
        -- 切换到单体模式
        if PigSet.DRUID_AOE_MODE ~= false then
            PigSet.DRUID_AOE_MODE = false
            print("|cff888888[德鲁伊]|r 返回单体模式")
        end
        
        -- 单体模式下保持DOT,专注单目标输出
        PigSet.DRUID_MOONFIRE_PRIORITY = false
        PigSet.DRUID_INSECT_SWARM_PRIORITY = false
    end
    
    return enemyCount
end

-- ============================================================
-- ★ 核心函数3: 月光/昆虫群DOT刷新策略
-- 来源: 18FF444A-F5CE-49FC-AD49-2D6D29F797BE.lua (L1553-L1558 balance decisionList)
-- ============================================================
function WR_DR_DOTRefreshStrategy()
    local form = WR_DR_GetDruidForm()
    
    -- 只有平衡德需要管理DOT
    if form ~= "balance" then
        return false
    end
    
    local targetName = UnitName("target")
    if not targetName then
        return false
    end
    
    -- ===============================
    -- 月火术(Moonfire)刷新
    -- 来源: L1554
    -- ===============================
    if not HasDebuff("target", "月火术") then
        if IsSpellUsable("月火术") then
            CastSpellByName("月火术")
            print("[奶德]|r DOT刷新: 月火术")
            return true
        end
    end
    
    -- ===============================
    -- 枯萎虫群(Insect Swarm)刷新
    -- 来源: L1553
    -- ===============================
    if not HasDebuff("target", "枯萎虫群") then
        if IsSpellUsable("枯萎虫群") then
            CastSpellByName("枯萎虫群")
            print("[奶德]|r DOT刷新: 枯萎虫群")
            return true
        end
    end
    
    return false
end

-- ============================================================
-- ★ 工具函数: 获取当前AOE信息
-- ============================================================
function WR_DR_GetAOEInfo()
    return {
        enemyCount = attackingEnemiesCount,
        inAOEMode = PigSet.DRUID_AOE_MODE or false,
        lastSwipeCastTime = lastSwipeCastTime,
        timeSinceLastSwipe = GetTime() - lastSwipeCastTime
    }
end

-- ============================================================
-- ★ 工具函数: 重置所有计时器
-- ============================================================
function WR_DR_ResetAOETimers()
    lastAoeCheckTime = 0
    attackingEnemiesCount = 0
    lastSwipeCastTime = 0
end

-- ============================================================
-- ★ 导出
-- ============================================================
