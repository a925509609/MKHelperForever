-- ============================================================
-- Core/Combat_Tools.lua
-- 模块：战斗工具集（维度5）来源：ZZHELPER_Wrath/Combat.lua 的 ZZ_Shared_CombatUtility_*
-- 适配：重命名为 WR_*_BExt；剥离 ZZ_Shared_RuntimeCore_* / ZZ_Wrath_Priest_ClassShared_* /
--       ZZ_ColorFrame_Show(数值键) / ZZHELPER_IS_TITAN 等引擎依赖。
-- 依赖 A 既有 helper：
--   WR_GetUnitBuffTime / WR_GetUnitDebuffTime / WR_GetItemInfo / WR_ColorFrame_Show /
--   WR_UnitRange / IsUnitValidTarget / WR_GetDBMCountdown_EM / WR_GetSpellNextCharge /
--   WR_GetSpellCharges / WR_SpeedUp / WR_GetPlayerSilenceTime / WR_ZLYS / WR_ZLYS2 /
--   WR_FuHuoYaoShui_ErrorMessage / WR_IsUsingGlyph / WR_InTraining
--   以及本插件 AOE_Count.lua 提供的 WR_GetRaidBurstDebuffMinTime_BExt /
--   WR_GetUnitBurstDebuffMinTime_BExt（用于爆发门控，AOE_Count.lua 须先于本文件加载）。
--
-- 说明：B 专用数据（QZWY_*/DontStunUnitName/StunCastName/StunChannelName/
--   SpeedUpSpellName/YuFangDingShenSpell 等）改为下方模块级配置表，默认空；
--   未配置时相关扫描函数返回安全默认值，不会因缺少 B 引擎数据报错。
-- ============================================================

-- ===== B 专用数据表（默认空，按需填充）=====
local BExt_QZWY_AOE_Name = BExt_QZWY_AOE_Name or {}      -- 群体不可打断 AOE 法术名列表
local BExt_QZWY_Spell_Name = BExt_QZWY_Spell_Name or {}  -- 目标不可打断法术名列表
local BExt_DontStunUnitName = BExt_DontStunUnitName or {}-- 禁止晕/打断的单位名
local BExt_StunCastName = BExt_StunCastName or {}        -- 可晕/打断施法 {name=,id=,time=}
local BExt_StunChannelName = BExt_StunChannelName or {}  -- 可晕/打断引导 {name=,id=,time=}
local BExt_SpeedUpSpellName = BExt_SpeedUpSpellName or {}-- 加速/增益态法术 {id=,name=}
local BExt_YuFangDingShenSpell = BExt_YuFangDingShenSpell or "" -- 防御定身法术名
local BExt_InterruptTime = BExt_InterruptTime or 0              -- 打断时机阈值(0~1，已施放比例；0=任意时刻)

-- ============================================================
-- ★ 本地辅助：扫描某单位正在施放"列表中法术"的剩余时间
-- 参数：Unit, nameList(表), maxRange(可选)
-- 返回：最短剩余秒数；无匹配 999
-- ============================================================
local function BExt_CastRemainingForList(Unit, nameList, maxRange)
    if not Unit or not UnitExists(Unit) then return 999 end
    if maxRange and WR_UnitRange(Unit) > maxRange then return 999 end
    local name, _, _, startTimeMS, endTimeMS = UnitCastingInfo(Unit)
    if name then
        for _, info in pairs(nameList) do
            if info == name or (type(info) == "table" and (info.name == name or info.id)) then
                return endTimeMS / 1000 - GetTime()
            end
        end
    end
    local cname, _, _, cstartMS, cendMS = UnitChannelInfo(Unit)
    if cname then
        for _, info in pairs(nameList) do
            if info == cname or (type(info) == "table" and (info.name == cname or info.id)) then
                return cendMS / 1000 - GetTime()
            end
        end
    end
    return 999
end

-- ============================================================
-- ★ 本地辅助：扫描全部姓名板，返回"正在施放列表中法术"的最短剩余
-- 参数：nameList, maxRange
-- ============================================================
local function BExt_ScanNameplateCasting(nameList, maxRange)
    local best = 999
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitCanAttack("player", unit) then
            local t = BExt_CastRemainingForList(unit, nameList, maxRange)
            if t < best then best = t end
        end
    end
    return best
end

-- ============================================================
-- ★ 本地辅助：爆发时间门控（复用 AOE_Count 的爆发DEBUFF扫描）
-- ============================================================
local function BExt_GetOutburstTime()
    local best = 999
    if WR_GetRaidBurstDebuffMinTime_BExt then
        local t = WR_GetRaidBurstDebuffMinTime_BExt()
        if t < best then best = t end
    end
    if WR_GetUnitBurstDebuffMinTime_BExt then
        local t = WR_GetUnitBurstDebuffMinTime_BExt("player")
        if t < best then best = t end
    end
    return best
end

-- ============================================================
-- 一、A 缺失的"泛型"战斗工具（完整实现）
-- ============================================================

-- ★ 获取施法信息（非引导）（B: CombatUtility_V）
function WR_GetCastInfo_BExt(Unit)
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(Unit)
    if endTimeMS ~= nil then
        return GetTime() - startTimeMS / 1000, endTimeMS / 1000 - GetTime(), not (notInterruptible)
    end
    return nil, nil, nil
end

-- ★ 获取引导法术信息（B: CombatUtility_AA）
function WR_GetChannelInfo_BExt(Unit)
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(Unit)
    if endTimeMS ~= nil then
        return GetTime() - startTimeMS / 1000, endTimeMS / 1000 - GetTime(), not (notInterruptible)
    end
    return nil, nil, nil
end

-- ★ 判断单位是否正在施放"可打断"的法术（B: CombatUtility_J）
-- 参数：Unit, InterruptibleTime(已施放比例阈值，0~1；或绝对秒数>=10)
function WR_IsUnitCastingInterruptible_BExt(Unit, InterruptibleTime)
    if WR_GetUnitBuffTime(Unit, "冲击屏障") > 0 then
        return false
    end
    local castTime, castRemain, interruptible = WR_GetCastInfo_BExt(Unit)
    if castTime ~= nil and castRemain ~= nil and interruptible ~= nil then
        if interruptible
           and (castTime / (castTime + castRemain) >= InterruptibleTime
                or castTime >= InterruptibleTime * 10) then
            return true
        end
    end
    local chTime, chRemain, chInterruptible = WR_GetChannelInfo_BExt(Unit)
    if chTime ~= nil and chRemain ~= nil and chInterruptible ~= nil then
        if chInterruptible and chTime >= InterruptibleTime then
            return true
        end
    end
    return false
end

-- ★ 判断是否需要打断当前目标（B: CombatUtility_D）
-- 参数：Spell(用于取该打断技能冷却做门控)
function WR_ShouldInterruptTarget_BExt(Spell)
    if BExt_ScanNameplateCasting(BExt_QZWY_AOE_Name, 45) < 999 then
        return false  -- 有群体AOE即将到来，不抢断
    end
    if BExt_CastRemainingForList("player", BExt_QZWY_Spell_Name, 45) < 999 then
        return false  -- 玩家身上有不可打断读条
    end
    if Spell then
        local cdRemain = WR_GetSpellNextCharge(Spell)
        if BExt_GetOutburstTime() < cdRemain then
            return true
        end
    else
        if BExt_GetOutburstTime() < 999 then
            return true
        end
    end
    return false
end

-- ★ 范围内可晕/打断目标扫描（B: CombatUtility_AC）
-- 参数：Range, Exclude("机械"时跳过机械单位)
function WR_ScanStunInterruptRange_BExt(Range, Exclude)
    if WR_SafeCastingName("boss1") == "宇宙奇点" then
        return false
    end
    local NowTime = GetTime()
    for i = 1, 40 do
        local unit = "nameplate" .. i
        local Pass = true
        if not UnitCanAttack("player", unit) then
            Pass = false
        elseif Exclude == "机械" and (WR_SafeCreatureType and WR_SafeCreatureType(unit) or UnitCreatureType(unit)) == "机械" then
            Pass = false
        else
            for _, Name in pairs(BExt_DontStunUnitName) do
                if Name == UnitName(unit) then Pass = false end
            end
        end
        if Pass then
            local name, _, _, startTimeMS, endTimeMS, _, _, _, spellId = UnitCastingInfo(unit)
            if name ~= nil then
                local maxRange = WR_UnitRange(unit)
                if maxRange ~= nil and maxRange <= Range then
                    for _, info in pairs(BExt_StunCastName) do
                        if info.name == name or info.id == spellId then
                            if NowTime - startTimeMS / 1000 > info.time then
                                if (BExt_InterruptTime == nil or BExt_InterruptTime == 0
                                    or info.time ~= 0
                                    or (NowTime - startTimeMS / 1000) / ((endTimeMS - startTimeMS) / 1000) >= BExt_InterruptTime) then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
            local cname, _, _, cstartMS, cendMS, _, _, _, cspellId = UnitChannelInfo(unit)
            if cname ~= nil then
                local maxRange = WR_UnitRange(unit)
                if maxRange ~= nil and maxRange <= Range then
                    for _, info in pairs(BExt_StunChannelName) do
                        if info.name == cname or info.id == cspellId then
                            if NowTime - cstartMS / 1000 > info.time then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- ★ 获取网络延迟（秒，取大值）（B: CombatUtility_I）
function WR_GetLatencySeconds_BExt()
    local _, _, latencyHome, latencyWorld = GetNetStats()
    if latencyHome > latencyWorld then
        return latencyHome / 1000
    end
    return latencyWorld / 1000
end

-- ★ 根据急速计算实际 GCD（B: CombatUtility_AH）
function WR_GetHastedGCD_BExt(GCD)
    return GCD / (1 + GetHaste() / 100)
end

-- ★ 判断单位是否为 BOSS（GUID 匹配）（B: CombatUtility_S）
function WR_IsBossUnitByGUID_BExt(Unit)
    local ug = (WR_SafeUnitGUID and WR_SafeUnitGUID(Unit)) or nil
    if not ug then return false end
    for i = 1, 5 do
        local bg = (WR_SafeUnitGUID and WR_SafeUnitGUID("boss" .. i)) or nil
        if bg ~= nil and bg == ug then
            return true
        end
    end
    return false
end

-- ★ 检测场上是否存在 BOSS 单位（B: CombatUtility_U）
function WR_HasBossUnit_BExt()
    for i = 1, 5 do
        if UnitGUID("boss" .. i) ~= nil then
            return true
        end
    end
    return false
end

-- ★ 通过单位名称获取姓名板对应单位血量百分比（B: CombatUtility_O）
function WR_GetNameplateHPPercentByName_BExt(unitName)
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and WR_SafeUnitName(unit) == unitName then
            local maxHealth = WR_SafeNumber(UnitHealthMax(unit), 1)
            if maxHealth > 0 then
                return WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1)) / maxHealth * 100
            end
            return 0
        end
    end
end

-- ★ 倒数窗口判定（未进战斗且处于 DBM 倒数内）（B: CombatUtility_Q）
function WR_IsInPullWindow_BExt(maxSeconds)
    maxSeconds = tonumber(maxSeconds) or 0
    if maxSeconds <= 0 or UnitAffectingCombat("player") then
        return false
    end
    local pullTime = WR_GetDBMCountdown_EM()
    return pullTime > 0 and pullTime < maxSeconds
end

-- ★ 通用偷药/预开物品检测与执行（B: CombatUtility_X）
-- 参数：enabled, itemID, btnKey(颜色帧按钮名), label, excludeStealth
function WR_PrePullPotion_BExt(enabled, itemID, btnKey, label, excludeStealth)
    if not PigSet or not PigSet["DBM_PREPULL_POTION"] then
        return false
    end
    if not enabled or UnitAffectingCombat("player") or not yaoshuicd then
        return false
    end
    if excludeStealth and WR_GetUnitBuffTime("player", "潜行") > 0 then
        return false
    end
    local pullTime = WR_GetDBMCountdown_EM()
    if pullTime <= 0 or pullTime > 1 then
        return false
    end
    if not WR_GetItemInfo(itemID) then
        return false
    end
    return WR_ColorFrame_Show(btnKey, label) or false
end

-- ★ DBM 倒数阶段自动偷药（速度/狂野魔法）（B: CombatUtility_P）
function WR_PrePullPotions_BExt(speedEnabled, wildMagicEnabled)
    if WR_PrePullPotion_BExt(speedEnabled, 40211, "BExt_PullSpeed", "Pull倒计时速度药水", false) then
        return true
    end
    if WR_PrePullPotion_BExt(wildMagicEnabled, 40212, "BExt_PullWild", "Pull倒计时狂野魔法药水", false) then
        return true
    end
    if WR_PrePullPotion_BExt(wildMagicEnabled, 20007, "BExt_PullWild", "Pull倒计时狂野魔法药水", false) then
        return true
    end
    return false
end

-- ============================================================
-- 二、A 已有等价实现 → 提供 WR_*_BExt 委托别名（避免重复逻辑/重复注册事件）
-- ============================================================

-- ★ 技能充能冷却剩余（B: _R）→ A: WR_GetSpellNextCharge
function WR_GetSpellChargesCooldown_BExt(SpellName)
    return WR_GetSpellNextCharge(SpellName)
end

-- ★ 技能当前充能层数（B: _E）→ A: WR_GetSpellCharges
function WR_GetSpellChargesCount_BExt(SpellName)
    return WR_GetSpellCharges(SpellName)
end

-- ★ DBM 倒数剩余时间（B: _AJ）→ A: WR_GetDBMCountdown_EM（事件帧已在 ZZ_Features_Migration 注册）
function WR_GetDBMCountdownRemaining_BExt()
    return WR_GetDBMCountdown_EM()
end

-- ★ 加速/增益态检测（B: _AD）→ A: WR_SpeedUp
function WR_IsSpeedBuffActive_BExt()
    return WR_SpeedUp()
end

-- ★ 沉默/沉默+缴械 最长剩余（B: _C）→ A: WR_GetPlayerSilenceTime
function WR_GetSilenceRemaining_BExt()
    return WR_GetPlayerSilenceTime()
end

-- ★ 自动治疗药水（B: _K）→ A: WR_ZLYS（已含 CSF 颜色帧与可用性门控）
function WR_AutoHealthPotion_BExt(Variable)
    return WR_ZLYS(Variable)
end

-- ★ 自动治疗石（B: _B）→ A: WR_ZLYS2（已含 CST 颜色帧与可用性门控）
function WR_AutoHealthStone_BExt(Variable)
    return WR_ZLYS2(Variable)
end

-- ★ 复活药水冷却错误捕获（B: _L）→ A: WR_FuHuoYaoShui_ErrorMessage（事件已注册，避免重复注册）
function WR_ResurrectionPotionErrorCapture_BExt()
    return WR_FuHuoYaoShui_ErrorMessage()
end

-- ★ 雕文检测（B: CombatUtility(name)）→ A: WR_IsUsingGlyph
function WR_IsUsingGlyph_BExt(name)
    return WR_IsUsingGlyph(name)
end

-- ★ 训练假人检测（B: CombatUtility_Z）→ A: WR_InTraining
function WR_InTrainingDummy_BExt()
    return WR_InTraining()
end
