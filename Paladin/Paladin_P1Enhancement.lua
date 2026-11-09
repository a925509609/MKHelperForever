-- ============================================================
-- Paladin_P1Enhancement.lua
-- 奶骑P1级核心功能增强
-- 包含：
--   1. 潘奇克蓝量保护机制(patchwerkStopCastMana)
--   2. 圣光道标DBM联动(白骨风暴自动切换模式)
--   3. BossDebuff爆发联动(十字军的惩罚易伤期)
--
--   来源文件: C231CE08(patchwerkStopCastMana/autoDaobiao)/D1B06BF3(dbmTimerStart)/DCB46883(bossDebuff)
-- ============================================================

if WR_PlayerClass ~= "PALADIN" then return end

if select(2, UnitClass("player")) ~= "PALADIN" then
    return
end

-- ============================================================
-- ★ 全局变量：P1增强功能配置
-- ============================================================
local patchwerkProtectionActive = false   -- 潘奇克保护激活标记
local daobiaoDBMSwitchActive = false      -- DBM道标切换激活标记
local daobiaoRestoreTimer = nil           -- 道标恢复定时器
local lastBossDebuffCheckTime = 0         -- 上次BossDebuff检测时间

-- antiSpam计时器全局表
if not _G.WR_PL_antiSpamTimers then
    _G.WR_PL_antiSpamTimers = {}
end

-- P1配置菜单(从 PigSet读取)
PigSet.PAL_PATCHWERK_PROTECTION = false   -- 潘奇克模式开关
PigSet.PAL_PATCHWERK_MANA_THRESHOLD = 30  -- 潘奇克阈值(30%)
PigSet.PAL_DAOSHUAI_DBM = true            -- 道标DBM联动开关
PigSet.PAL_BURST_BOSS_DEBUFF = true       -- BossDebuff爆发联动开关

-- ============================================================
-- ★ 辅助函数0: antiSpam防刷机制
-- 功能: 限制同一提示的触发频率(默认10秒冷却)
-- ============================================================
function WR_PL_AntiSpam(key, cooldown)
    cooldown = cooldown or 10
    
    if not _G.WR_PL_antiSpamTimers[key] then
        _G.WR_PL_antiSpamTimers[key] = 0
    end
    
    local now = GetTime()
    if now - _G.WR_PL_antiSpamTimers[key] >= cooldown then
        _G.WR_PL_antiSpamTimers[key] = now
        return true
    end
    
    return false
end

-- ============================================================
-- ★ 辅助函数1: 潘奇克蓝量保护检查
-- 来源: C231CE08 L57 (patchwerkStopCastMana)
-- 功能: 当蓝量低于阈值时,提前停手避免蓝耗尽猝死
-- ============================================================
function WR_PL_PatchwerkProtectionCheck()
    if not PigSet.PAL_PATCHWERK_PROTECTION then
        return false
    end
    
    local manaThreshold = PigSet.PAL_PATCHWERK_MANA_THRESHOLD / 100  -- 30%->0.3
    
    if PlayerMP <= manaThreshold then
        -- 蓝量不足,检查是否应该提前停手
        local remaining = CastingRemainingTime or 0
        
        -- 如果施法剩余时间<=窗口2倍,建议停手
        if remaining <= ((PigSet.SS_GLTCCK or 5) / 10 * 2) then
            return true
        end
    end
    
    return false
end

-- ============================================================
-- ★ 辅助函数2: 获取DBM倒计时(通用)
-- 来源: D1B06BF3(dbmTimerStart回调)
-- 功能: 获取当前Boss事件的DBM倒计时秒数
-- ============================================================
local function WR_PL_GetDBMCountdown()
    return WR_GetDBMCountdown_EM() or 0
end

-- ============================================================
-- ★ 辅助函数3: 检测是否为白骨风暴场景
-- 来源: D1B06BF3(decisionHook/dbmStage)
-- 功能: 判断当前是否为玛洛加尔领主白骨风暴阶段
-- ============================================================
local function WR_PL_IsBoneStormPhase()
    local bossName = UnitName("target")
    if bossName ~= "玛洛加尔领主" and bossName ~= "Marrowgar" then
        return false
    end
    
    -- 检测天灾领主之刺施法
    local castingName, _, _, castingTime, endTime = UnitCastingInfo("target")
    if castingName and (castingName == "天灾领主之刺" or castingTime) then
        return true
    end
    
    return false
end

-- ============================================================
-- ★ 辅助函数4: 白骨风暴道标自动切换
-- 来源: D1B06BF3 L102-L115 (dbmTimerStart/dbmAnnounce)
-- 功能: 
--   - 白骨风暴来临前5秒切到自身道标(方便转火)
--   - 23秒后恢复智能刷新模式(P6)
-- ============================================================
local function WR_PL_BoneStormDaobiaoSwitch()
    if not PigSet.PAL_DAOSHUAI_DBM then
        return
    end
    
    if not WR_PL_IsBoneStormPhase() then
        -- 非白骨风暴阶段,重置道标状态
        if daobiaoDBMSwitchActive then
            if PigSet.SS_SGDB ~= 6 then
                PigSet.SS_SGDB = 6  -- 恢复智能刷新
            end
            daobiaoDBMSwitchActive = false
            
            if daobiaoRestoreTimer then
                daobiaoRestoreTimer:Cancel()
                daobiaoRestoreTimer = nil
            end
        end
        return
    end
    
    -- 白骨风暴阶段检测
    local dbmCountdown = WR_PL_GetDBMCountdown()
    
    if dbmCountdown > 0 and dbmCountdown <= 5 then
        -- 提前5秒切换到自身道标模式(P5)
        if not daobiaoDBMSwitchActive then
            local originalMode = PigSet.SS_SGDB
            PigSet.SS_SGDB = 5  -- 切到自身道标
            
            daobiaoDBMSwitchActive = true
            antiSpamTimer = antiSpamTimer or {}
            
            if WR_PL_AntiSpam("bonesstorm_daobiao_switch", 30) then
                print("|cFF00FF00[奶骑DBM联动]白骨风暴来临,切换到自身道标模式")
            end
            
            -- 23秒后恢复原模式
            if daobiaoRestoreTimer then
                daobiaoRestoreTimer:Cancel()
            end
            
            daobiaoRestoreTimer = C_Timer.NewTimer(23, function ()
                if PigSet.SS_SGDB ~= originalMode then
                    PigSet.SS_SGDB = originalMode
                end
                daobiaoDBMSwitchActive = false
                daobiaoRestoreTimer = nil
                
                if WR_PL_AntiSpam("bonesstorm_daobiao_restore", 30) then
                    print("|cFFFF0000[奶骑DBM联动]白骨风暴结束,恢复道标原模式")
                end
            end)
        end
    end
end

-- ============================================================
-- ★ 辅助函数5: BossDebuff爆发联动检测
-- 来源: DCB46883(bossDebuff联动)+Paladin_Holy.lua WR_PaladinHoly_BF()
-- 功能: 检测到Boss易伤Debuff时,强制开启爆发技能
-- ============================================================
local function WR_PL_BossDebuffBurstCheck()
    if not PigSet.PAL_BURST_BOSS_DEBUFF then
        return false
    end
    
    local now = GetTime()
    -- 每0.5秒检测一次(避免高频)
    if now - lastBossDebuffCheckTime < 0.5 then
        return false
    end
    
    lastBossDebuffCheckTime = now
    
    -- 检测十字军的惩罚(易伤期)
    local crossDebuffTime = WR_GetUnitDebuffTime("target", "十字军的惩罚")
    
    if crossDebuffTime > 10 then
        -- 易伤期剩余>10秒,强制开启爆发
        return true
    end
    
    return false
end

-- ============================================================
-- ★ 公开接口1: 潘奇克蓝量保护(集成WR_StopCast)
-- 调用位置: Paladin_Holy.lua主循环WR_PaladinHoly_Stopcasting()后
-- ============================================================
function WR_PL_PatchwerkStopCast()
    if WR_PL_PatchwerkProtectionCheck() then
        if WR_PL_AntiSpam("patchwerk_stopcast", 5) then
            print("|cFFFF0000[奶骑潘奇克模式]蓝量低于" .. PigSet.PAL_PATCHWERK_MANA_THRESHOLD .. "%,提前停手")
        end
        return true
    end
    
    return false
end

-- ============================================================
-- ★ 公开接口2: 白骨风暴道标更新(每帧调用)
-- 调用位置: Paladin_Holy.lua主循环开头(WR_PaladinHoly())
-- ============================================================
function WR_PL_BoneStormUpdate()
    WR_PL_BoneStormDaobiaoSwitch()
end

-- ============================================================
-- ★ 公开接口3: BossDebuff爆发加成(集成WR_PaladinHoly_BF)
-- 调用位置: Paladin_Holy.lua爆发检测WR_PaladinHoly_BF()内
-- ============================================================
function WR_PL_BossDebuffBurstEnabled()
    return WR_PL_BossDebuffBurstCheck()
end

-- ============================================================
-- ★ 公开接口4: 获取当前P1增强状态(用于UI显示)
-- ============================================================
function WR_PL_GetP1EnhancementStatus()
    return {
        patchwerk_active = WR_PL_PatchwerkProtectionCheck(),
        daobiao_dbm_active = daobiaoDBMSwitchActive,
        burst_boss_debuff = WR_PL_BossDebuffBurstCheck(),
        bonesstorm_remaining = WR_PL_GetDBMCountdown()
    }
end

