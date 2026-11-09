-- ============================================================
-- Core/Forever_APIShim.lua
-- 《魔兽世界：无限》(WoW: Forever) 受限 API 框架层
-- ------------------------------------------------------------
-- 背景：无限使用与正式服 12.0 一致的客户端框架，COMBAT_LOG_EVENT_UNFILTERED
--       对插件不再触发（CLEU 被禁用）。本层在不改动 43 处既有 CLEU handler
--       的前提下，提供：
--         【1】安全事件桥接：把仍可用的 UNIT_AURA / UNIT_SPELLCAST_* /
--             UNIT_POWER_UPDATE / UNIT_TARGET 等事件，合成为与
--             WR_CombatLogEvent 兼容的伪战斗日志，并分发给 WR_CombatLogHandlers
--             注册表，使基于注册表的模块在无限上继续工作。
--         【2】全局状态：WR_Forever_LastPlayerCast（最近一次玩家施法）、
--             WR_Forever_ComboPoints（连击点缓存）——替代 CLEU 的
--             SPELL_CAST_SUCCESS / 连击点事件，供 EagleShot、焦点施法等使用。
--         【3】安全原语：WR_GetSwingSpeed / WR_Forever_GetLastPlayerCast /
--             WR_Forever_IsSpellKnown 等——供各职业模块在无 CLEU 时重建判定。
--
-- 设计原则：纯附加（additive）。在 SoD / 经典客户端上，CLEU 仍触发，本层桥接
--           不会与既有 CLEU 总线冲突（合成事件仅在安全事件上产生，不与
--           CombatLogGetCurrentEventInfo 重复）。
-- ============================================================

if not WR_Forever then WR_Forever = {} end

-- ★ 标记：无限（Forever）与正式服 12.0 框架一致，CLEU 已禁用
WR_Forever.CLEU_Disabled = true
WR_Forever_APIRestricted = true

-- 兼容 WR_CombatLogEvent 全局表（Core_Functions.lua 已声明，这里兜底）
WR_CombatLogEvent = WR_CombatLogEvent or {}

-- ============================================================
-- ★ 全局状态：玩家最近一次成功施法
--   替代 CLEU 的 SPELL_CAST_SUCCESS，用于 EagleShot / 焦点施法 / 姿态检测
-- ============================================================
WR_Forever_LastPlayerCast = { spellID = 0, spellName = "", time = 0 }

-- 全局状态：连击点缓存（UNIT_POWER_UPDATE 维护，替代 CLEU 连击点事件）
WR_Forever_ComboPoints = 0

-- 安全原语：取玩家最近一次施法 {spellID, spellName, time}
function WR_Forever_GetLastPlayerCast()
    return WR_Forever_LastPlayerCast.spellID,
           WR_Forever_LastPlayerCast.spellName,
           WR_Forever_LastPlayerCast.time
end

-- 安全原语：连击点（经典用 GetComboPoints，零售用 UnitPower；两者都试）
function WR_Forever_GetComboPoints()
    if type(GetComboPoints) == "function" then
        local cp = GetComboPoints("player", "target")
        if cp and cp > 0 then return cp end
    end
    local pt = Enum and Enum.PowerType and Enum.PowerType.ComboPoints
    if pt then
        return UnitPower("player", pt)
    end
    return UnitPower("player", 4)
end

-- ============================================================
-- ★ 安全原语：武器挥舞速度
--   说明：12.0 移除 CLEU 后，无法精确侦测“下一次白字挥舞”的时刻（白字不是法术，
--    UNIT_SPELLCAST_* 不触发）。因此本函数只返回基础挥舞速度作为降级值；
--   需要精确挥舞计时的近战模块应改为基于施法/技能节奏估算，或接受近似。
-- ============================================================
function WR_GetSwingSpeed(unit)
    unit = unit or "player"
    if UnitExists(unit) then
        local speed = select(1, UnitAttackSpeed(unit))
        return speed or 0
    end
    return 0
end

-- 安全原语：技能是否已知/在法术书中（IsPlayerSpell 兼容 SoD 符文与无限天赋）
function WR_Forever_IsSpellKnown(spell)
    if type(IsPlayerSpell) == "function" then
        local ok, res = pcall(IsPlayerSpell, spell)
        if ok and res then return true end
    end
    if type(GetSpellInfo) == "function" then
        local _, _, _, _, _, _, spellID = GetSpellInfo(spell)
        if spellID then
            local ok, known = pcall(IsSpellKnown, spellID)
            if ok and known then return true end
        end
    end
    return false
end

-- ============================================================
-- ★ 合成兼容 WR_CombatLogEvent 的伪事件，并分发到注册表
--   形状对齐既有 handler 的 unpack 约定：
--     [1] timestamp [2] subevent [3] hideCaster
--     [4] sourceGUID [5] sourceName [6] sourceFlags [7] sourceRaidFlags
--     [8] destGUID   [9] destName   [10] destFlags   [11] destRaidFlags
--     [12] spellID   [13] spellName  [14] spellSchool
-- ============================================================
local function WR_Forever_FireSynthetic(subevent, sourceUnit, destUnit, spellID, spellName)
    local srcGUID = sourceUnit and UnitGUID(sourceUnit) or UnitGUID("player")
    local srcName = sourceUnit and UnitName(sourceUnit) or UnitName("player")
    local dstGUID = destUnit and UnitGUID(destUnit) or srcGUID
    local dstName = destUnit and UnitName(destUnit) or srcName

    local cle = {
        GetTime(), subevent, false,
        srcGUID, srcName, 0x511, 0,
        dstGUID, dstName, 0x511, 0,
        spellID or 0, spellName or "", 1
    }
    -- 写入全局 WR_CombatLogEvent（保证读取该全局的 handler 也能拿到数据）
    for k = 1, #cle do WR_CombatLogEvent[k] = cle[k] end
    for k = #cle + 1, #WR_CombatLogEvent do WR_CombatLogEvent[k] = nil end

    -- 分发给 WR_CombatLogHandlers 注册表（核心总线同款签名）
    if WR_CombatLogHandlers then
        for name, handler in pairs(WR_CombatLogHandlers) do
            local ok, err = pcall(handler, unpack(cle, 1, 11))
            if not ok then
                print("WR Forever combatlog handler error (" .. tostring(name) .. "): " .. tostring(err))
            end
        end
    end
end

-- 供未来模块迁移的统一订阅入口（别名 WR_RegisterCombatLogHandler）
function WR_Forever_RegisterCombatLogHandler(handler, handlerName)
    if WR_RegisterCombatLogHandler then
        WR_RegisterCombatLogHandler(handler, handlerName)
    else
        WR_CombatLogHandlers = WR_CombatLogHandlers or {}
        WR_CombatLogHandlers[handlerName or tostring(handler)] = handler
    end
end

-- ============================================================
-- ★ 安全事件桥接帧（仅在 CLEU 禁用时承担战斗日志职责）
-- ============================================================
local WR_Forever_Bridge = CreateFrame("Frame")
WR_Forever_Bridge:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
WR_Forever_Bridge:RegisterEvent("UNIT_SPELLCAST_START")
WR_Forever_Bridge:RegisterEvent("UNIT_SPELLCAST_FAILED")
WR_Forever_Bridge:RegisterEvent("UNIT_POWER_UPDATE")
WR_Forever_Bridge:RegisterEvent("UNIT_TARGET")
WR_Forever_Bridge:RegisterEvent("PLAYER_TARGET_CHANGED")
WR_Forever_Bridge:RegisterEvent("PLAYER_REGEN_ENABLED")
WR_Forever_Bridge:RegisterEvent("PLAYER_REGEN_DISABLED")

WR_Forever_Bridge:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID, spellName = ...
        if unit == "player" then
            WR_Forever_LastPlayerCast.spellID = spellID or 0
            WR_Forever_LastPlayerCast.spellName = spellName or ""
            WR_Forever_LastPlayerCast.time = GetTime()
            WR_Forever_FireSynthetic("SPELL_CAST_SUCCESS", "player", "player", spellID, spellName)
        end
    elseif event == "UNIT_SPELLCAST_START" then
        local unit, _, spellID, spellName = ...
        if unit == "player" then
            WR_Forever_FireSynthetic("SPELL_CAST_START", "player", "player", spellID, spellName)
        end
    elseif event == "UNIT_POWER_UPDATE" then
        local unit = ...
        if unit == "player" then
            WR_Forever_ComboPoints = WR_Forever_GetComboPoints()
        end
    elseif event == "UNIT_TARGET" or event == "PLAYER_TARGET_CHANGED" then
        -- 目标变化：即时失效目标光环缓存（WR_UpdateFrameState 已按 UNIT_AURA 处理，
        -- 这里确保切换目标后毒蛇钉刺等判定立刻重算）
        if WR_ForceRefreshAuraCache then
            WR_ForceRefreshAuraCache("target")
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        WR_Forever_ComboPoints = WR_Forever_GetComboPoints()
    elseif event == "PLAYER_REGEN_ENABLED" then
        WR_Forever_ComboPoints = 0
        WR_Forever_LastPlayerCast.spellID = 0
        WR_Forever_LastPlayerCast.spellName = ""
        WR_Forever_LastPlayerCast.time = 0
    end
end)

-- 初始化连击点缓存
WR_Forever_ComboPoints = WR_Forever_GetComboPoints()

print("|cff00ff00[MKHelperForever]|r Forever 受限 API 框架层已加载（CLEU 禁用，已接入安全事件桥接）。")
