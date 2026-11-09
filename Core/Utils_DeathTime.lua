-- ============================================================
-- Utils_DeathTime.lua
-- 死亡时间预测与杂项工具函数
-- 从 Core_Functions.lua 拆分
-- 包含：TTD死亡预测、饰品触发检测、
--       DOT合法性、取消保护/灌注、沉默时间、
--       复活药水、全局状态变量、加拉克苏斯血肉成灰
-- ============================================================

-- ============================================================
-- ★ Nameplate目标死亡时间预测（TTD）
-- ============================================================
if not NPGUID then
    NPGUID = {}
    NPLevel = {}
    NPHP = {}
    NPMaxHealth = {}
    NPHealth = {}
    NPbegintime = {}
    NPdeathtime = {}
end

function WR_GetUnitDeathTime(Unit)
    WR_GetNPDeathTime()
    local targetGUID = WR_SafeUnitGUID(Unit)
    if not targetGUID then return 0 end

    for i = 1, 40 do
        local cachedGUID = NPGUID[i]
        if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(cachedGUID) then
            cachedGUID = nil
        end
        if cachedGUID == targetGUID and NPdeathtime[i] then
            local ttd = NPdeathtime[i]
            if ttd >= 999 then
                return 8888
            end
            if ttd < 0 then
                return 0
            end
            return ttd
        end
    end
    return 8888
end

function WR_GetRangeAvgDeathTime(Range)
    if WR_InTraining() then
        return 999
    end

    WR_GetNPDeathTime()
    local sum = 0
    local count = 0

    for i = 1, 40 do
        if NPGUID[i] and UnitAffectingCombat("nameplate" .. i) and NPdeathtime[i] then
            local maxRange = WR_UnitRange("nameplate" .. i)
            local name = WR_SafeUnitName and WR_SafeUnitName("nameplate" .. i) or UnitName("nameplate" .. i)
            if maxRange and maxRange <= Range and NPdeathtime[i] < 900 and name ~= "爆炸物" then
                sum = sum + NPdeathtime[i]
                count = count + 1
            end
        end
    end

    local result = 999
    if count > 0 then
        result = sum / count
    end

    return result
end

function WR_GetNPDeathTime()
    local currentTime = GetTime()
    if LastTime_WR_GetNPDeathTime and currentTime - LastTime_WR_GetNPDeathTime <= 0.15 then
        return
    end
    LastTime_WR_GetNPDeathTime = currentTime

    for i = 1, 40 do
        local unit = "nameplate" .. i
        local currentGUID = WR_SafeUnitGUID(unit)
        local cachedGUID = NPGUID[i]
        if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(cachedGUID) then
            cachedGUID = nil
        end

        if not currentGUID or not UnitAffectingCombat(unit) or
           WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1)) == WR_SafeNumber(UnitHealthMax(unit), 1) or
           (cachedGUID and cachedGUID ~= currentGUID) then
            NPGUID[i] = nil
            NPLevel[i] = nil
            NPHP[i] = nil
            NPMaxHealth[i] = nil
            NPHealth[i] = nil
            NPbegintime[i] = nil
            NPdeathtime[i] = 999

            if currentGUID and UnitAffectingCombat(unit) then
                NPGUID[i] = currentGUID
            end
        else
            NPGUID[i] = currentGUID
            NPMaxHealth[i] = WR_SafeNumber(UnitHealthMax(unit), 1)
            local currentHP = WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1))

            if not NPHealth[i] then
                NPHealth[i] = currentHP
                NPbegintime[i] = currentTime
                NPdeathtime[i] = 999
            else
                local deltaT = currentTime - NPbegintime[i]
                if deltaT >= 0.2 then
                    local deltaHP = NPHealth[i] - currentHP
                    if deltaHP > 0 then
                        local currentDPS = deltaHP / deltaT
                        local instantTTD = currentHP / currentDPS

                        if NPdeathtime[i] >= 900 then
                            NPdeathtime[i] = instantTTD
                        else
                            NPdeathtime[i] = (NPdeathtime[i] * 0.7) + (instantTTD * 0.3)
                        end
                    else
                        if NPdeathtime[i] < 999 then
                            NPdeathtime[i] = NPdeathtime[i] + deltaT
                        end
                    end
                    NPHealth[i] = currentHP
                    NPbegintime[i] = currentTime
                end
            end
        end
    end
end

-- ============================================================
-- ★ 饰品触发检测
-- ============================================================
function WR_SpecialTrinketActivate(Classes)
    local TrinketData = {
        ["雪怒圣物"] = { BuffName = "天神祝福", Cooldown = 55 },
        ["玉珑圣物"] = { BuffName = "天神祝福", Cooldown = 55 },
        ["雷神的遗诏"] = { BuffName = "鼎力", Cooldown = 55 },
        ["秩序之光"] = { BuffName = "升华", Cooldown = 55 },
        ["黑雾漩涡"] = { BuffName = "敏锐", Cooldown = 55 },
        ["碳酸红宝石"] = { BuffName = "蓄力一击", Cooldown = 115 },
        ["玉质御者俑"] = { BuffName = "提速", Cooldown = 55 },
        ["萦雾之恐"] = { BuffName = "无情打击", Cooldown = 55 },
        ["群星之瓶"] = { BuffName = "敏捷", Cooldown = 55 },
        ["惊怖精华"] = { BuffName = "迅疾如风", Cooldown = 55 },
        ["基洛普泰里克的印记"] = { BuffName = "敏捷", Cooldown = 55 },
        ["灭世之魔眼"] = { BuffName = "泰坦之力", Cooldown = 55 },
        ["末代龙裔之源"] = { BuffName = "洞悉弱点", Cooldown = 55 },
        ["灾变角斗士的征服徽记"] = { BuffName = "征服之涌", Cooldown = 55 },
        ["灾变角斗士的胜利徽记"] = { BuffName = "胜利之涌", Cooldown = 55 },
        ["灾变角斗士的统御徽记"] = { BuffName = "统御之涌", Cooldown = 55 },
        ["拉夏的左眼"] = { BuffName = "复仇之眼", Cooldown = 55 },
        ["瓦罗森的胸针"] = { BuffName = "瓦罗针的饰针", Cooldown = 55 },
        ["摘星罗盘"] = { BuffName = "提速", Cooldown = 55 },
        ["真实之镜"] = { BuffName = "痛苦反射", Cooldown = 55 },
        ["恐惧小盒"] = { BuffName = "触须", Cooldown = 55 },
        ["泰坦之砧"] = { BuffName = "痛苦反射", Cooldown = 45 },
        ["暗月卡片：伟大"] = { BuffName = "伟大", Cooldown = 45 },
    }

    local Trinket1_Name, Trinket2_Name
    local Trinket1_ID = GetInventoryItemID("player", 13)
    local Trinket2_ID = GetInventoryItemID("player", 14)
    local TrinketSum = 0
    local TrinketBuffSum = 0
    local Trinket1_BuffTime = 0
    local Trinket2_BuffTime = 0

    -- ★ 无限 12.x 安全：GetItemInfo 可能缺失，先做存在性守卫 + pcall
    if Trinket1_ID and type(GetItemInfo) == "function" then
        local ok, n = pcall(GetItemInfo, Trinket1_ID)
        Trinket1_Name = ok and n or nil
    end
    if Trinket2_ID and type(GetItemInfo) == "function" then
        local ok, n = pcall(GetItemInfo, Trinket2_ID)
        Trinket2_Name = ok and n or nil
    end

    if Trinket1_Name then
        if TrinketData[Trinket1_Name] then
            TrinketSum = TrinketSum + 1
            Trinket1_BuffTime = WR_GetUnitBuffTime("player", TrinketData[Trinket1_Name].BuffName)
            if Trinket1_BuffTime > 0 then
                TrinketBuffSum = TrinketBuffSum + 1
                if not WR_Trinket1_NextTime or WR_Trinket1_NextTime < GetTime() then
                    WR_Trinket1_NextTime = GetTime() + TrinketData[Trinket1_Name].Cooldown
                end
            end
        end
    end

    if Trinket2_Name then
        if TrinketData[Trinket2_Name] then
            TrinketSum = TrinketSum + 1
            Trinket2_BuffTime = WR_GetUnitBuffTime("player", TrinketData[Trinket2_Name].BuffName)
            if Trinket2_BuffTime > 0 then
                TrinketBuffSum = TrinketBuffSum + 1
                if not WR_Trinket2_NextTime or WR_Trinket2_NextTime < GetTime() then
                    WR_Trinket2_NextTime = GetTime() + TrinketData[Trinket2_Name].Cooldown
                end
            end
        end
    end

    if Trinket1_BuffTime > 0 and Trinket1_BuffTime < 3 then
        return true
    end
    if Trinket2_BuffTime > 0 and Trinket2_BuffTime < 3 then
        return true
    end

    local BuffTime_BJZL = 0
    if Classes == "DK" then
        BuffTime_BJZL = WR_GetUnitBuffTime("player", "不洁之力")
    end

    if TrinketSum == 0 then
        if Classes == "DK" then
            if BuffTime_BJZL > 0 then
                return true
            end
        else
            return true
        end
    end

    if TrinketSum == 1 then
        if TrinketBuffSum == 1 then
            if Classes == "DK" then
                if BuffTime_BJZL > 0 then
                    return true
                end
            else
                return true
            end
        end

        if Trinket1_Name then
            if WR_Trinket1_NextTime then
                if WR_Trinket1_NextTime > GetTime() then
                    if Classes == "DK" then
                        if BuffTime_BJZL > 0 then
                            return true
                        end
                    else
                        return true
                    end
                end
            end
        end

        if Trinket2_Name then
            if WR_Trinket2_NextTime then
                if WR_Trinket2_NextTime > GetTime() then
                    if Classes == "DK" then
                        if BuffTime_BJZL > 0 then
                            return true
                        end
                    else
                        return true
                    end
                end
            end
        end
    end

    if TrinketSum == 2 then
        if TrinketBuffSum == 2 then
            if Classes == "DK" then
                if BuffTime_BJZL > 0 then
                    return true
                end
            else
                return true
            end
        end

        if TrinketBuffSum == 1 then
            if Trinket1_BuffTime > 0 then
                if WR_Trinket2_NextTime then
                    if WR_Trinket2_NextTime - GetTime() > Trinket1_BuffTime - 2 then
                        if Classes == "DK" then
                            if BuffTime_BJZL > 0 then
                                return true
                            end
                        else
                            return true
                        end
                    end
                end
            end

            if Trinket2_BuffTime > 0 then
                if WR_Trinket1_NextTime then
                    if WR_Trinket1_NextTime - GetTime() > Trinket2_BuffTime - 2 then
                        if Classes == "DK" then
                            if BuffTime_BJZL > 0 then
                                return true
                            end
                        else
                            return true
                        end
                    end
                end
            end
        end

        if TrinketBuffSum == 0 then
            if WR_Trinket1_NextTime and WR_Trinket1_NextTime > GetTime() and
               WR_Trinket2_NextTime and WR_Trinket2_NextTime > GetTime() then
                if Classes == "DK" then
                    if BuffTime_BJZL > 0 then
                        return true
                    end
                else
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================================
-- ★ DOT目标合法性检测
-- ============================================================
function WR_ZHAYU(Unit)
    if not UnitExists(Unit) then
        return false
    end

    local name = WR_SafeUnitName(Unit)
    if not name then
        return false
    end

    local BlackList_Names = { "魔化元素" }
    for _, blockName in ipairs(BlackList_Names) do
        if strfind(name, blockName) then
            return false
        end
    end
    return true
end

-- ============================================================
-- ★ 当前光环获取
-- ============================================================
function GetGH()
    local formIndex = GetShapeshiftForm()
    if formIndex == 0 then
        return nil
    end

    local _, _, _, spellID = GetShapeshiftFormInfo(formIndex)
    if spellID then
        local auraName = GetSpellInfo(spellID)
        return auraName
    end
    return nil
end

-- ============================================================
-- ★ 当前GCD获取
-- ============================================================
function GetNowGCD()
    local _, _, _, castTime = GetSpellInfo("寒冰箭")
    if castTime and castTime > 0 then
        return castTime / 1000
    end
    return 2.5
end

-- ============================================================
-- ★ 全局取消保护之手
-- ============================================================
function WR_ALL_QXBH()
    local qxbhTarget = WR_SafeUnitName("target")
    if WR_GetUnitBuffTime("player", "保护之手") > 0 and
       qxbhTarget ~= "冰喉" and qxbhTarget ~= "血领主曼多基尔" then
        if WR_ColorFrame_Show(191, "取消保护") then
            return true
        end
    end
end

-- ============================================================
-- ★ 沉默时间获取
-- ============================================================
function WR_GetPlayerSilenceTime()
    local maxTime = 0
    if C_LossOfControl then
        local num = C_LossOfControl.GetNumEvents and C_LossOfControl.GetNumEvents() or 0
        for i = 1, num do
            local locType, spellID, text, iconTexture, startTime, timeRemaining,
                  duration, lockoutSchool, priority, displayType

            if C_LossOfControl.GetEventInfo then
                locType, spellID, text, iconTexture, startTime, timeRemaining,
                duration, lockoutSchool, priority, displayType = C_LossOfControl.GetEventInfo(i)
            elseif C_LossOfControl.GetActiveLossOfControlData then
                locType, spellID, text, iconTexture, startTime, timeRemaining,
                duration, lockoutSchool, priority, displayType =
                C_LossOfControl.GetActiveLossOfControlData(i)
            end

            if locType == "SILENCE" or locType == "PACIFYSILENCE" then
                local currentRemaining = 0
                if timeRemaining and timeRemaining > 0 then
                    currentRemaining = timeRemaining
                elseif startTime and duration and duration > 0 then
                    currentRemaining = (startTime + duration) - GetTime()
                end
                if currentRemaining > maxTime then
                    maxTime = currentRemaining
                end
            end
        end
    end
    return maxTime
end

-- ============================================================
-- ★ Nameplate血量百分比获取（使用缓存版本）
-- ============================================================
function WR_GetNamePlateHealth(unitName)
    WR_UpdateFrameState()
    WR_EnsureNameplatesCached()

    for i = 1, 40 do
        local entry = WR_NameplateCache[i]
        if entry and entry.name == unitName then
            local current = WR_SafeNumber(UnitHealth(entry.unit), WR_SafeNumber(UnitHealthMax(entry.unit), 1))
            local max = WR_SafeNumber(UnitHealthMax(entry.unit), 1)
            if max > 0 then
                return (current / max) * 100
            end
            return 0
        end
    end
    return nil
end

-- ============================================================
-- ★ 复活药水冷却监控
-- ============================================================
FuHuoYaoShui = true

function WR_FuHuoYaoShui_ErrorMessage()
    if WR_YaoShui_ErrorMessageInfo then return end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UI_ERROR_MESSAGE")
    frame:SetScript("OnEvent", function(self, event, messageType, message)
        if message == "物品还没有准备好。" then
            FuHuoYaoShui = false
            C_Timer.After(60, function() FuHuoYaoShui = true end)
        end
    end)
    WR_YaoShui_ErrorMessageInfo = true
end

-- ============================================================
-- ★ 全局状态变量初始化
-- ============================================================
WR_AYJ_Focus_XU = true
WR_DSDCTIME = true
WR_LR_BZSJCTIME = true
WR_FS_RSTIME = true
WR_DK_WZFSTIME = false
WR_DK_FWRW_BC_TIME = true
WR_DK_FWRW_AD_TIME = true
WR_DK_CR_TIME = true
WR_DK_CR_TQTB_TIME = true
WR_MS_XXGZC_TIMW = true
WR_SM_YSZW_TIME = true
WR_SS_XJ_TIME = true
WR_SS_XJ_TIME_FOCUS = true
WR_DK_TZDJ_TIME = true

function JIAO_SHOU_RUAN_NI()
    local focusName = WR_SafeUnitName("focus")
    if (WR_GetUnitDebuffTime("player", "软泥特性") > 0 and focusName == "毒气之云") or
       (WR_GetUnitDebuffTime("player", "异变毒气") > 0 and focusName == "不稳定的软泥怪") or
       UnitIsPlayer("focus") then
        return false
    else
        return true
    end
end

WR_HJX_CastStartTime = nil
FS_AF_ASCJ = false
FS_HF_9LY = true
WR_TKWCTIME = true

-- ============================================================
-- ★ 加拉克苏斯大王血肉成灰检测
-- ============================================================
local WR_JaraxxusFleshSpellIds = {
    [66237] = true, [67049] = true, [67050] = true, [67051] = true,
    [72149] = true, [72150] = true,
}

-- secret 读取失败后的短暂抑制表（单位 → 抑制到的 GetTime 时间点）
--   战斗中被 taint 时读取必然失败，若每帧对每个队友重试，25800x 级别刷屏虽被
--   pcall 吞掉，仍会白白产生大量错误对象；0.5s 抑制足以避免，且脱战后 0.5s 内恢复。
local WR_JaraxxusFleshFailUntil = {}

function WR_UnitHasJaraxxusFleshToAshes(Unit)
    if not UnitExists(Unit) then
        return false
    end
    -- ★ 无限适配：与 Core_Functions.lua 的 WR_ScanAurasForUnit 同一契约——
    --   C_UnitAuras.GetAuraDataByIndex 在路径被 taint 时【直接抛错】（不是返回
    --   secret 值），报 "Auras cannot be accessed when secret"。此处是每帧必经路径
    --   （Paladin_Forever.lua → WR_RunHealerWithFleshPriority → 本函数），
    --   不包 pcall 会以 25749x 级别刷屏。
    --   降级策略：读取失败即视为「没有血肉成灰」（保守：不误报，不会触发过量刷血），
    --   并按单位抑制 0.5s，避免每帧重复抛错。
    local now = GetTime()
    local untilTime = WR_JaraxxusFleshFailUntil[Unit]
    if untilTime and now < untilTime then
        return false
    end

    local ok, hasFlesh = pcall(function()
        for i = 1, 40, 1 do
            local name, spellId
            if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
                local debuffData = C_UnitAuras.GetAuraDataByIndex(Unit, i, "HARMFUL")
                if debuffData == nil then break end
                name, spellId = debuffData.name, debuffData.spellId
            else
                -- 经典/SoD 客户端兜底：与 Core_Functions.WR_ScanAurasForUnit 同构
                if type(UnitDebuff) ~= "function" then break end
                local n, _, _, _, _, _, _, _, _, sid = UnitDebuff(Unit, i)
                if not n then break end
                name, spellId = n, sid
            end
            if WR_JaraxxusFleshSpellIds[spellId] or
               name == "血肉成灰" or name == "Incinerate Flesh" then
                return true
            end
        end
        return false
    end)
    if not ok then
        WR_JaraxxusFleshFailUntil[Unit] = now + 0.5
        return false
    end
    WR_JaraxxusFleshFailUntil[Unit] = nil
    return hasFlesh == true
end

-- 查找当前团/队中身上有「血肉成灰」Debuff 的单位（用于优先过量治疗）
-- 已在下方实现并接入 Core/Healer_FocusWeight.lua:40（WR_FindJaraxxusFleshUnit()），功能非死代码。
-- 实现：优先沿用已是血肉目标的焦点，再按 WR_GetInRaidOrParty 遍历 raid(1-25)/party(含玩家自身) 找第一个中 debuff 的单位。
function WR_FindJaraxxusFleshUnit()
    -- 焦点已是血肉目标则直接沿用，避免反复改焦点抖动
    if UnitExists("focus") and WR_UnitHasJaraxxusFleshToAshes("focus") then
        return "focus"
    end

    local prefix = WR_GetInRaidOrParty()
    if prefix == "raid" then
        for i = 1, 25 do
            local u = prefix .. i
            if UnitExists(u) and WR_UnitHasJaraxxusFleshToAshes(u) then
                return u
            end
        end
    elseif prefix == "party" then
        if UnitExists("player") and WR_UnitHasJaraxxusFleshToAshes("player") then
            return "player"
        end
        for i = 1, 4 do
            local u = prefix .. i
            if UnitExists(u) and WR_UnitHasJaraxxusFleshToAshes(u) then
                return u
            end
        end
    else
        -- 非团非队（单人）：只检查玩家自身
        if UnitExists("player") and WR_UnitHasJaraxxusFleshToAshes("player") then
            return "player"
        end
    end

    return nil
end

function WR_UnitIsGroupTank(Unit)
    if not UnitExists(Unit) or UnitIsUnit(Unit, "player") then
        return false
    end
    local prefix = WR_GetInRaidOrParty()
    if prefix == "raid" then
        for i = 1, 25 do
            if UnitIsUnit(prefix .. i, Unit) then
                return WR_NumIsTank(i)
            end
        end
    elseif prefix == "party" then
        for i = 1, 4 do
            if UnitIsUnit(prefix .. i, Unit) then
                return WR_NumIsTank(i)
            end
        end
    end
    return false
end

-- 血肉成灰优先过量治疗总开关（由统一菜单 ZL_XRCYX 控制，跨所有治疗职业生效）
-- 已在下方实现（返回 PigSet.ZL_XRCYX ~= false）并接入 Core/Healer_FocusWeight.lua:34；功能非死代码。
-- ZL_XRCYX 的 defaultState 为 true，故未初始化（nil）时按开启处理。
function WR_JaraxxusFleshHealEnabled()
    return PigSet.ZL_XRCYX ~= false
end

function WR_UnitNeedsFleshOverheal(Unit)
    return WR_JaraxxusFleshHealEnabled() and WR_UnitHasJaraxxusFleshToAshes(Unit)
end

-- 当前是否处于加拉克苏斯大王(Jaraxxus)战斗
-- 已在下方实现并接入 Core/Utils_HealerWeight.lua:145（WR_JaraxxusFleshAnyoneActive() 闸门），功能非死代码。
function WR_JaraxxusFleshAnyoneActive()
    local boss = WR_SafeUnitName("target")
    if boss and type(boss) == "string" then
        local b = string.lower(boss)
        if string.find(b, "jaraxxus") or string.find(b, "加拉克苏斯") then
            return true
        end
    end
    return false
end
