-- ============================================================
-- 恢复德鲁伊增强补丁 (Druid-Restoration-Extra)
-- 功能：优化宁静、激活、停止施法判断，引入更智能的战斗检测
-- 用法：将此文件放在 WR 脚本目录，确保在"恢复德"主脚本之后加载
-- 注意：本补丁会覆盖原函数，建议先备份原文件
-- ============================================================

-- 保存原始函数引用，用于补丁中的回退调用
if WR_PlayerClass ~= "DRUID" then return end

local _WR_DruidRestoration = WR_DruidRestoration
local _WR_DruidRestoration_JH = WR_DruidRestoration_JH
local _WR_DruidRestoration_Stopcasting = WR_DruidRestoration_Stopcasting

-- ------------------------------------------------------------------
-- 辅助函数：判断玩家是否处于需要治疗的战斗状态
-- 返回 true 表示处于有效治疗战斗（boss战、副本内战斗等）
-- ------------------------------------------------------------------
local function WR_DruidRestoration_InHealCombat()
    if not UnitAffectingCombat("player") then
        return false
    end
    -- 如果处于首领战或系统判定为Boss战斗，视为有效战斗
    if IsEncounterInProgress() or WR_InBossCombat() then
        return true
    end
    -- 如果在副本内且队伍/团队处于战斗，也视为有效
    if IsInInstance() and WR_PartyInCombat() then
        return true
    end
    return false
end

-- ------------------------------------------------------------------
-- 辅助函数：统计团队/小队中生命值低于阈值的成员数量
-- @threshold: 血量百分比阈值（如 0.45 表示 45%）
-- @return: 符合条件的成员数量
-- ------------------------------------------------------------------
local function WR_DruidRestoration_CountLowGroupHP(threshold)
    local prefix = RaidOrParty or WR_GetInRaidOrParty()
    if prefix == "single" then
        return 0
    end
    local groupSum = GroupSum or (prefix == "raid" and 25 or 4)
    local count = 0
    for i = 1, groupSum do
        local unit = prefix .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and WR_GetUnitHP(unit) < threshold then
            count = count + 1
        end
    end
    return count
end

-- ------------------------------------------------------------------
-- 重写宁静插入逻辑（覆盖原函数）
-- 增强：只有在有效战斗中、且低血量队友达到一定数量时才施放宁静
-- 避免在非关键场合浪费技能
-- ------------------------------------------------------------------
function WR_DruidRestoration_CRNJ()
    -- 若用户未开启宁静插入，直接跳过
    if not PigSet.HF_NJ_CR then return false end
    -- 必须处于有效治疗战斗
    if not WR_DruidRestoration_InHealCombat() then return false end
    -- 检查宁静是否可用，若冷却中且剩余时间 >10秒则关闭插入开关（避免反复尝试）
    if not WR_SpellUsable("宁静", true) then
        if WR_GetGCD("宁静") > 10 then
            SlashCmdList["HF_NJ_CR"]("off")
        end
        return false
    end

    local prefix = RaidOrParty or WR_GetInRaidOrParty()
    -- 团队需要至少4个低血量(45%以下)队友，小队则需要3个
    local needCount = prefix == "raid" and 4 or 3
    if WR_DruidRestoration_CountLowGroupHP(0.45) < needCount then
        return false
    end

    -- 通过颜色框架显示提示并施放宁静
    if WR_ColorFrame_ShowSkill("宁静", 64) then
        return true
    end
    return false
end

-- ------------------------------------------------------------------
-- 重写激活逻辑（覆盖原函数）
-- 增强：只有处于有效战斗且自身蓝量低于8%时才施放激活
-- 同时检查是否已有激活buff防止重复
-- ------------------------------------------------------------------
function WR_DruidRestoration_JH()
    if not PigSet.HF_JH then return false end          -- 用户未开启激活自动使用
    if not WR_DruidRestoration_InHealCombat() then return false end

    local playerMP = PlayerMP
    if playerMP == nil and WR_GetUnitMP then
        playerMP = WR_GetUnitMP("player")
    end
    if not playerMP or playerMP > 0.08 then
        return false                                   -- 蓝量高于8%时无需激活
    end
    if WR_GetUnitBuffTime("player", "激活") > 0 then
        return false                                   -- 已有激活buff
    end

    -- 调用原始激活函数执行实际施放
    return _WR_DruidRestoration_JH()
end

-- ------------------------------------------------------------------
-- 重写停止施法判断（覆盖原函数）
-- 增强：只在玩家进入战斗后才执行停止施法检测，避免非战斗误停
-- ------------------------------------------------------------------
function WR_DruidRestoration_Stopcasting()
    if not UnitAffectingCombat("player") then
        return false
    end
    return _WR_DruidRestoration_Stopcasting()
end

-- ------------------------------------------------------------------
-- 重写主循环入口（覆盖原函数）
-- 在原有逻辑前优先执行新增的宁静插入逻辑
-- 若插入成功则直接返回，否则调用原始主函数
-- ------------------------------------------------------------------
function WR_DruidRestoration()
    if WR_DruidRestoration_CRNJ() then
        return true
    end
    return _WR_DruidRestoration()
end