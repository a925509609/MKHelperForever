-- ============================================================
-- DRUID_EssenceOptimization.lua
-- 德鲁伊精华管理与形态切换系统（借鉴外部插件高效逻辑）
-- 包含：
--   1. Essence(精华)实时监控与安全阈值判定
--   2. 精华溢出预警与主动使用策略
--   3. Talent MaxRange动态判定(近战3码/远程35码)
--   4. 形态自动检测(猫/熊/平衡/恢复/旅行)
--
--   来源文件: 03705A54(essenceBloodQueen)/B11BDC21(talentUpdate)/EAB86A35(className初始化)
-- ============================================================

if WR_PlayerClass ~= "DRUID" then return end

if select(2, UnitClass("player")) ~= "DRUID" then
    return
end

-- ============================================================
-- ★ 全局变量
-- ============================================================
local lastEssenceCheckTime = 0      -- 上次精华检测时间
local essenceThresholdLow = 20      -- 低精华阈值
local essenceThresholdHigh = 80     -- 高精华阈值(避免溢出)
local talentMaxRange = 3            -- 默认近战范围
local talentMaxRangeMain = 8        -- 主施法范围

-- ============================================================
-- ★ 辅助函数1: 获取当前精华值
-- 来源: 03705A54-ADCD-46B2-8D7C-E95867800D90.lua (essenceBloodQueen)
-- ============================================================
function WR_DR_GetCurrentEssence()
    -- WotLK德鲁伊没有正式Essence资源,使用特殊Debuff计数模拟
    -- "Blood Queen essence"类型的debuff表示精华积累
    local essenceCount = 0
    
    for i = 1, 40 do
        local name, _, _, _, _, duration, expirationTime, sourceUnit, isStealable, _, spellId = UnitDebuff("player", i)
        if not name then break end
        
        -- 检测精华相关debuff(根据不同Boss战动态变化)
        if string.find(name, "Essence") or spellId == 53739 then  -- 68255是精华绽放
            essenceCount = essenceCount + math.floor(duration / 5)  -- 估算精华值
        end
    end
    
    return math.min(100, essenceCount)  -- 上限100
end

-- ============================================================
-- ★ 辅助函数2: 判断德鲁伊形态
-- 来源: B11BDC21-E32D-4640-A454-124F400ECFBD.lua (talentMaxRange反推)
-- ============================================================
function WR_DR_GetDruidForm()
    if HasBuff("player", "熊形态") then
        return "bear"  -- 坦克
    elseif HasBuff("player", "猫形态") then
        return "cat"   -- 近战DPS
    elseif HasBuff("player", "枭兽形态") then
        return "balance"  -- 远程DPS
    elseif HasBuff("player", "旅行形态") then
        return "travel"
    elseif HasBuff("player", "飞禽形态") or HasBuff("player", "巨飞行形态") then
        return "flight"
    elseif HasBuff("player", "猎豹形态") or HasBuff("player", "大猫形态") then
        return "cat"  -- 变体猫形态
    else
        return "formless"  -- 人形/树人行
    end
end

-- ============================================================
-- ★ 辅助函数3: 获取角色类型
-- 来源: WR_Druid_BossSpecials.lua (GetDruidRole)
-- ============================================================
function WR_DR_GetDruidRole()
    local form = WR_DR_GetDruidForm()
    
    if form == "bear" then
        return "tank"  -- 熊德=坦克
    elseif form == "cat" then
        return "melee_dps"  -- 猫德=近战DPS
    elseif form == "balance" then
        return "ranged_caster_dps"  -- 平衡德=远程DPS
    else
        return "healer"  -- 恢复德=治疗(树人形态)
    end
end

-- ============================================================
-- ★ 辅助函数4: 判断是否在Boss战
-- ============================================================
function WR_DR_InEncounter()
    return IsInInstance() and UnitAffectingCombat("player")
end

-- ============================================================
-- ★ 核心函数1: Talnet MaxRange动态更新
-- 来源: B11BDC21-E32D-4640-A454-124F400ECFBD.lua (L39-L59)
-- 功能: 根据天赋自动切换近战/远程范围
-- ============================================================
function WR_DR_UpdateTalentMaxRange()
    -- ★ 无限适配：经典天赋 API 已移除，且旧代码把「平衡」当作第 3 天赋页
    --   （Boss/WR_BossMechanics.lua 里第 3 页是「恢复」，两处页序假设互相冲突）。
    --   改为直接读兼容层解析出的激活专精名，不再依赖页序号。
    local activeSpec
    if type(WR_Forever_GetActiveSpec) == "function" then
        activeSpec = WR_Forever_GetActiveSpec()
    end
    local isBalance = (activeSpec == "平衡")
    -- 兜底：兼容层未加载时按第 1 页点数判断（平衡=第 1 页，与 Boss 判定一致）
    if not activeSpec and type(GetTalentTabInfo) == "function" then
        local ok, _, _, _, _, rank = pcall(GetTalentTabInfo, 1)
        isBalance = ok and (rank or 0) > 0
    end

    if isBalance then
        -- 点了均衡天赋→远程德
        talentMaxRange = 30
        talentMaxRangeMain = 35
    else
        -- 野性/守护→近战德
        talentMaxRange = 3
        talentMaxRangeMain = 8
    end
    
    return talentMaxRange, talentMaxRangeMain
end

-- ============================================================
-- ★ 核心函数2: 精华安全管理
-- 来源: 03705A54-ADCD-46B2-8D7C-E95867800D90.lua
-- 功能: 低精华主动获取/高精华警告避免浪费
-- ============================================================
function WR_DR_CheckEssenceSafety()
    local now = GetTime()
    
    -- 每1秒检测一次
    if now - lastEssenceCheckTime < 1 then
        return WR_DR_GetCurrentEssence()
    end
    lastEssenceCheckTime = now
    
    local currentEssence = WR_DR_GetCurrentEssence()
    local form = WR_DR_GetDruidForm()
    
    -- ===============================
    -- 低精华策略(<20主动获取)
    -- ===============================
    if currentEssence < essenceThresholdLow then
        -- 猫德/平衡德使用精华绽放
        if form == "cat" or form == "balance" then
            if IsSpellUsable("精华绽放") then
                -- TODO: 提示使用精华绽放
            end
        end
        
        -- 恢复德使用自然愈合/回春回复
        if form == "healer" then
            if IsSpellUsable("自然愈合") then
                -- TODO: 提示使用自然愈合
            end
        end
    end
    
    -- ===============================
    -- 高精华预警(>80警告避免溢出)
    -- ===============================
    if currentEssence > essenceThresholdHigh then
        print(string.format("|cFFFFFF00[德鲁伊]|r 精华过高(%d),尽快使用技能!", currentEssence))
        
        -- 根据形态提示使用对应技能
        if form == "cat" and IsSpellUsable("斜掠") then
            -- TODO: 提示使用斜掠消耗精华
        elseif form == "balance" and IsSpellUsable("月火术") then
            -- TODO: 提示使用月火术消耗精华
        elseif form == "healer" and IsSpellUsable("回春术") then
            -- TODO: 提示使用回春术消耗精华
        end
    end
    
    return currentEssence
end

-- ============================================================
-- ★ 核心函数3: 形态切换安全检查
-- 来源: EAB86A35-908D-42C5-B1D6-82EBCF6AC6C5.lua (className="DRUID")
-- 功能: 战斗中禁止随意变形(疲劳惩罚)
-- ============================================================
function WR_DR_CheckFormSwitchSafety()
    local inCombat = UnitAffectingCombat("player")
    local currentForm = WR_DR_GetDruidForm()
    
    if inCombat then
        -- 战斗中禁止非强制变形
        if currentForm == "formless" then
            print("|cFFFF0000[德鲁伊]|r 战斗中无法变形的!")
            return false
        end
        
        -- 检测是否处于变形状态
        if currentForm ~= "formless" then
            return true  -- 已变形,正常
        end
    end
    
    return true  -- 非战斗或无变形需求
end

-- ============================================================
-- ★ 核心函数4: 范围检查工具(供其他模块调用)
-- 来源: C741ACEA-E58F-4786-B988-3D6219F40E8A.lua (npFind反推)
-- ============================================================
function WR_DR_IsInRange(unitToken, maxDistance)
    local distance = GetDistanceToUnit(unitToken)
    
    if not maxDistance then
        maxDistance = talentMaxRangeMain
    end
    
    return distance <= maxDistance
end

function WR_DR_GetDistanceToUnit(unitToken)
    local playerPos = GetPlayerPosition()
    local unitPos = GetUnitPosition(unitToken)
    
    if not playerPos or not unitPos then
        return 100  -- 默认超出范围
    end
    
    local dx = playerPos.x - unitPos.x
    local dy = playerPos.y - unitPos.y
    local dz = playerPos.z - unitPos.z
    
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- ============================================================
-- ★ 工具函数: 重置所有计时器
-- ============================================================
function WR_DR_ResetEssenceTimers()
    lastEssenceCheckTime = 0
end

-- ============================================================
-- ★ 导出
-- ============================================================
