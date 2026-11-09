-- ============================================================
-- DRUID_EclipseSystem.lua
-- 德鲁伊月蚀/日蚀系统（平衡德核心机制）
-- 包含：
--   1. Eclipse(月蚀/日蚀)状态监控与对轴检测
--   2. 能量条管理(Moon Energy/Star Energy)
--   3. 轨道炮(Moonfire Nova)智能释放时机
--   4. 对轴期间DOT刷新策略优化
--
--   来源文件: 18FF444A(L739-L921 eclipse判断)/EF225593(L56-L59 buff定义)/AC63E95B(eclipseTime)
-- ============================================================

if WR_PlayerClass ~= "DRUID" then return end

if select(2, UnitClass("player")) ~= "DRUID" then
    return
end

-- ============================================================
-- ★ 全局变量
-- ============================================================
local lastEclipseCheckTime = 0      -- 上次Eclipse检测时间
local eclipseState = "none"          -- 当前Eclipse状态(none/solar/lunar)
local eclipseEnergy = 0              -- Eclipse能量(0~100)
local eclipseDuration = 0            -- Eclipse剩余持续时间
local eclipseOnOrbit = false         -- 是否在对轴上(Ready-to-use)
local moonEnergyValue = 0            -- 月神能量值

-- Eclipse buff ID定义
-- Solar Eclipse = 日蚀(SpellId: 33831) - 星火术伤害+50%,读条-50%
-- Lunar Eclipse = 月蚀(SpellId: 33832) - 愤怒伤害+50%,读条-50%
-- Eclipse Buff = 日蚀激活(SpellId: 48517)
-- Eclipse Time = Eclipse持续时间(SpellId: 1309556)

-- ============================================================
-- ★ 辅助函数1: 获取Eclipse状态
-- 来源: EF225593-484B-4DBF-8986-EF83A5D1D56D.lua (L56-L59)
-- 功能: 检测当前是日蚀/月蚀/无Eclipse
-- ============================================================
function WR_DR_GetEclipseState()
    local now = GetTime()
    
    -- 每0.5秒检测一次
    if now - lastEclipseCheckTime < 0.5 then
        return eclipseState, eclipseEnergy, eclipseOnOrbit
    end
    lastEclipseCheckTime = now
    
    -- 检测日蚀buff
    if HasBuff("player", "日蚀") or HasBuff("player", "Solar Eclipse") then
        eclipseState = "solar"
        
        -- 获取剩余持续时间
        eclipseDuration = 0
        for i = 1, 40 do
            local name, _, _, _, _, duration, expirationTime, sourceUnit = UnitBuff("player", i)
            if not name then break end
            if name == "日蚀" or name == "Solar Eclipse" then
                eclipseDuration = expirationTime - GetTime()
                break
            end
        end
        
        -- 检测是否在对轴(Restoration/Arms天赋影响)
        eclipseOnOrbit = true  -- TODO: 根据天赋和能量条计算
        
        print("|cFFFFFF00[平衡德]|r 日蚀激活! 优先使用星火术!")
        return "solar", eclipseDuration, eclipseOnOrbit
    end
    
    -- 检测月蚀buff
    if HasBuff("player", "月蚀") or HasBuff("player", "Lunar Eclipse") then
        eclipseState = "lunar"
        
        -- 获取剩余持续时间
        eclipseDuration = 0
        for i = 1, 40 do
            local name, _, _, _, _, duration, expirationTime, sourceUnit = UnitBuff("player", i)
            if not name then break end
            if name == "月蚀" or name == "Lunar Eclipse" then
                eclipseDuration = expirationTime - GetTime()
                break
            end
        end
        
        eclipseOnOrbit = true  -- TODO: 根据天赋和能量条计算
        
        print("|cff8888ff[平衡德]|r 月蚀激活! 优先使用愤怒!")
        return "lunar", eclipseDuration, eclipseOnOrbit
    end
    
    -- 无Eclipse
    eclipseState = "none"
    eclipseDuration = 0
    eclipseOnOrbit = false
    
    return "none", 0, false
end

-- ============================================================
-- ★ 辅助函数2: 获取月神能量值
-- 来源: EF225593(EF225593-484B-4DBF-8986-EF83A5D1D56D.lua L57)
-- 功能: Moon Energy用于Eclipse触发判定
-- ============================================================
function WR_DR_GetMoonEnergy()
    -- WotLK没有正式Moon Energy资源,使用Eclipse能量估算
    local energy = 0
    
    -- 基于最近10次技能施放估算
    local castName, castTime = UnitCastingInfo("player")
    if castName then
        if string.find(castName, "星火") or string.find(castName, "Starfire") then
            energy = 50  -- 在施放星火,接近日蚀
        elseif string.find(castName, "愤怒") or string.find(castName, "Wrath") then
            energy = -50  -- 在施放愤怒,接近月蚀
        end
    end
    
    moonEnergyValue = math.max(-100, math.min(100, energy))
    return moonEnergyValue
end

-- ============================================================
-- ★ 核心函数1: Eclipse对轴检测(Ready-to-use判定)
-- 来源: AC63E95B-5D66-4681-94F2-69EE0EB6D1B0.lua (L168-L237)
-- 功能: 检测是否在对轴上(Eclipse结束前Ready时间点)
-- ============================================================
function WR_DR_CheckEclipseOnOrbit()
    local state, duration, onOrbit = WR_DR_GetEclipseState()
    
    if state == "none" then
        -- 不在任何Eclipse状态
        eclipseOnOrbit = false
        return false
    end
    
    -- 检查是否在Ready窗口期
    -- 外部插件逻辑: eclipseTime.left > 0且技能可用
    if duration > 0 and duration <= 3 then
        -- 剩余时间≤3秒时进入Ready窗口
        if IsSpellUsable("星火术") or IsSpellUsable("愤怒") then
            eclipseOnOrbit = true
            print(string.format("|cFF00ff00[平衡德]|r Eclipse进入Ready窗口! 剩余%.1f秒", duration))
            return true
        end
    end
    
    -- 超过5秒未使用则脱轴
    if duration > 5 then
        eclipseOnOrbit = false
    end
    
    return eclipseOnOrbit
end

-- ============================================================
-- ★ 核心函数2: 轨道炮(Moonfire Nova)智能释放
-- 来源: 18FF444A(L739-L799 eclipseTime判断)
-- 功能: 在Eclipse结束时释放轨道炮以最大化伤害
-- ============================================================
function WR_DR_AutoMoonfireNova()
    local state, duration, onOrbit = WR_DR_GetEclipseState()
    
    if state == "none" then
        return false
    end
    
    -- 检查是否有足够的目标(至少2个)
    local enemyCount = WR_DR_UpdateAttackingEnemiesCount()
    
    if enemyCount < 2 then
        return false  -- 单体模式不使用轨道炮
    end
    
    -- 检测月神轨道炮是否可用
    if IsSpellUsable("月神轨道炮") or IsSpellUsable("Moonfire Nova") then
        -- 在Eclipse剩余1-2秒时释放(最大化伤害加成)
        if duration >= 1 and duration <= 2 then
            if not CastingInfo() then  -- 避免打断当前施法
                -- 对齐 MK 主循环：统一走 WR_ColorFrame_Show(86) 入口施放
                if WR_ColorFrame_ShowSkill("月神轨道炮", 86) then
                    eclipseEnergy = 0  -- 重置能量
                    return true
                end
            end
        end
    end
    
    return false
end

-- ============================================================
-- ★ 核心函数3: 对轴期间DOT刷新策略
-- 来源: 18FF444A(L1529-L1558 decisionListWrapper)
-- 功能: Eclipse期间优先保持DOT,然后使用强化技能
-- ============================================================
function WR_DR_DOTRefreshInEclipse()
    local state, duration, onOrbit = WR_DR_GetEclipseState()
    
    if state == "none" then
        return false
    end
    
    local targetName = UnitName("target")
    if not targetName then
        return false
    end
    
    -- ===============================
    -- 日蚀期间: 优先维持DOT,然后星火术
    -- 来源: 18FF444A(L1553-L1558 balance decisionList)
    -- ===============================
    if state == "solar" then
        -- 1) 月火术刷新
        if not HasDebuff("target", "月火术") then
            if IsSpellUsable("月火术") then
                CastSpellByName("月火术")
                return true
            end
        end
        
        -- 2) 枯萎虫群刷新
        if not HasDebuff("target", "枯萎虫群") then
            if IsSpellUsable("枯萎虫群") then
                CastSpellByName("枯萎虫群")
                return true
            end
        end
        
        -- 3) 日蚀期间星火术优先级最高
        PigSet.DRUID_STARFIRE_PRIORITY = true
        PigSet.DRUID_WRATH_PRIORITY = false
        
    -- ===============================
    -- 月蚀期间: 优先维持DOT,然后愤怒
    -- ===============================
    elseif state == "lunar" then
        -- 1) 月火术刷新
        if not HasDebuff("target", "月火术") then
            if IsSpellUsable("月火术") then
                CastSpellByName("月火术")
                return true
            end
        end
        
        -- 2) 枯萎虫群刷新
        if not HasDebuff("target", "枯萎虫群") then
            if IsSpellUsable("枯萎虫群") then
                CastSpellByName("枯萎虫群")
                return true
            end
        end
        
        -- 3) 月蚀期间愤怒优先级最高
        PigSet.DRUID_WRATH_PRIORITY = true
        PigSet.DRUID_STARFIRE_PRIORITY = false
    end
    
    return false
end

-- ============================================================
-- ★ 工具函数: 获取Eclipse信息
-- ============================================================
function WR_DR_GetEclipseInfo()
    return {
        state = eclipseState,
        duration = eclipseDuration,
        onOrbit = eclipseOnOrbit,
        moonEnergy = moonEnergyValue,
        canUseMoonfireNova = IsSpellUsable("月神轨道炮")
    }
end

-- ============================================================
-- ★ 工具函数: 重置所有计时器
-- ============================================================
function WR_DR_ResetEclipseTimers()
    lastEclipseCheckTime = 0
    eclipseState = "none"
    eclipseDuration = 0
    eclipseOnOrbit = false
    moonEnergyValue = 0
end

-- ============================================================
-- ★ 导出
-- ============================================================
