-- ============================================================
-- Core/Forever_SecretGuard.lua
-- 《魔兽世界：无限》(1.60.x / Midnight 12.x 同源框架) 受限数值安全层
-- ------------------------------------------------------------
-- 背景：
--   12.0 起，UnitHealth / UnitPower / UnitHealthMax 等战斗数值在受污染
--   (tainted) 的插件代码里返回 secret value。secret 值可以赋值、传递、
--   塞给白名单控件 API，但一旦参与算术、比较、字符串拼接或作为表键，
--   立刻抛 "attempt to perform arithmetic on a secret number value"，
--   并把插件标记为会话级 taint —— 此后连 Frame:RegisterEvent 这类
--   保护函数都会被拦成 ADDON_ACTION_FORBIDDEN。
--   同理 12.0 起 COMBAT_LOG_EVENT_UNFILTERED 对插件禁用，直接注册即报错。
--
-- 本层职责（纯附加，SoD / 经典客户端上全部退化为直通）：
--   【1】WR_IsSecretValue   —— 带存在性兜底的 secret 检测
--   【2】WR_SafeNumber      —— 把可能为 secret 的值收敛成普通 number
--   【3】WR_SafeHPPct       —— 血量百分比（含吸收盾），secret 时降级
--   【4】WR_SafePowerPct    —— 资源百分比，secret 时降级
--   【5】WR_SafeUnitHealth  —— 绝对血量安全读取
--   【6】WR_IsCLEUBlocked / WR_RegisterEventSafe —— CLEU 注册闸门
--
-- ★ 降级策略（重要）：secret 时统一返回 1（视为满血 / 满资源 / 未知）。
--   这样所有 "HP < 阈值" 的斩杀、低血治疗、危险判定都静默不触发，
--   不会误放技能，也不会因为返回 0 导致斩杀与治疗常开。
--   代价：无限客户端上依赖血量的自动化判定无法工作 —— 这是 12.x 的
--   客户端硬限制（插件不得基于战斗数值做逻辑），不是可绕过的缺陷。
--
-- 加载顺序：必须晚于 Core/Forever_Compat.lua（依赖 WR_Forever_ClientInfo），
--           早于 Core/Core_Functions.lua 与 Core/MainLoop.lua（提供工具函数）。
-- ============================================================

-- ============================================================
-- 【1】secret 值检测
-- 参数：v —— 任意值，允许 nil
-- 返回：boolean，v 为 secret value 时 true；12.0 之前的客户端恒为 false
-- 说明：必须「先检测、后比较」；对 secret 值做 v == nil 本身就会抛错。
-- ============================================================
function WR_IsSecretValue(v)
    if type(issecretvalue) ~= "function" then return false end
    local ok, res = pcall(issecretvalue, v)
    return ok and res == true
end

-- ============================================================
-- 【2】通用数值收敛
-- 参数：v        —— 待收敛的值（可为 secret / nil / 非数字）
--       fallback —— v 不可用时代替返回的普通数字
-- 返回：普通 number（保证调用方可以安全地做算术、比较、拼接）
-- ============================================================
function WR_SafeNumber(v, fallback)
    if WR_IsSecretValue(v) then return fallback end
    if v == nil then return fallback end
    if type(v) ~= "number" then return fallback end
    return v
end

-- ============================================================
-- 【3】单位血量百分比（含吸收盾分支）
-- 参数：unit       —— 单位 token，如 "player" / "target" / "nameplate1"
--       subAbsorb  —— true 时减去 UnitGetTotalHealAbsorbs（对应「吸收盾」「盾」）
-- 返回：0~1 的普通 number；单位不存在、血量不可读、上限为 0 时返回 1
-- 说明：原 WR_GetUnitHP 直接做 UnitHealth / UnitHealthMax，是 508x 刷屏
--       报错的根因；此处在所有算术之前先做 secret 检测。
-- ============================================================
function WR_SafeHPPct(unit, subAbsorb)
    unit = unit or "player"
    if type(UnitExists) == "function" and not UnitExists(unit) then return 1 end

    local hp = UnitHealth(unit)
    local maxHP = UnitHealthMax(unit)
    -- secret 判定必须早于任何算术 / 比较
    if WR_IsSecretValue(hp) or WR_IsSecretValue(maxHP) then return 1 end
    hp = WR_SafeNumber(hp, nil)
    maxHP = WR_SafeNumber(maxHP, 0)
    if hp == nil or maxHP == 0 then return 1 end

    if subAbsorb then
        local absorb = 0
        if type(UnitGetTotalHealAbsorbs) == "function" then
            local raw = UnitGetTotalHealAbsorbs(unit)
            if WR_IsSecretValue(raw) then return 1 end
            absorb = WR_SafeNumber(raw, 0)
        end
        hp = hp - absorb
    end
    return hp / maxHP
end

-- ============================================================
-- 【4】单位资源百分比
-- 参数：unit      —— 单位 token
--       powerType —— Enum.PowerType 枚举值，nil 时退回 0（法力）
-- 返回：0~1 的普通 number；不可读或上限为 0 时返回 1（视为满资源）
-- 说明：UnitPower / UnitPowerMax 在 12.x 同样是 secret-affected API。
-- ============================================================
function WR_SafePowerPct(unit, powerType)
    unit = unit or "player"
    if type(UnitExists) == "function" and not UnitExists(unit) then return 1 end
    local pt = powerType or 0
    local cur = UnitPower(unit, pt)
    local max = UnitPowerMax(unit, pt)
    if WR_IsSecretValue(cur) or WR_IsSecretValue(max) then return 1 end
    cur = WR_SafeNumber(cur, nil)
    max = WR_SafeNumber(max, 0)
    if cur == nil or max == 0 then return 1 end
    return cur / max
end

-- ============================================================
-- 【5】绝对血量安全读取
-- 参数：unit     —— 单位 token
--       fallback —— 血量不可读时的代替值；省略时取「最大血量」= 视为满血
-- 返回：普通 number
-- 用途：替换 "UnitHealth(unit) < 80000"、"UnitHealth + 即将治疗" 等
--       以绝对值为起点的算式，避免把 secret 值带入算术链。
-- 说明：默认降级为满血而非 0，这样低血 / 斩杀 / 治疗权重分支统一不触发。
-- ============================================================
function WR_SafeUnitHealth(unit, fallback)
    unit = unit or "player"
    local v = UnitHealth(unit)
    if WR_IsSecretValue(v) then
        if fallback ~= nil then return fallback end
        local maxHP = UnitHealthMax(unit)
        if WR_IsSecretValue(maxHP) then return 1 end
        return WR_SafeNumber(maxHP, 1)
    end
    return WR_SafeNumber(v, 0)
end

-- 最大血量安全读取；不可读时返回 1（保证分母不为 0）
function WR_SafeUnitMaxHealth(unit)
    return WR_SafeNumber(UnitHealthMax(unit or "player"), 1)
end

-- 当前资源 / 资源上限安全读取；不可读时返回 0
function WR_SafeUnitPower(unit, powerType)
    return WR_SafeNumber(UnitPower(unit or "player", powerType or 0), 0)
end

function WR_SafeUnitPowerMax(unit, powerType)
    return WR_SafeNumber(UnitPowerMax(unit or "player", powerType or 0), 0)
end

-- ============================================================
-- 【6】CLEU 注册闸门
-- 返回：boolean，true 表示当前客户端禁止插件注册 COMBAT_LOG_EVENT_UNFILTERED
-- 判定依据：12.0 引入的 issecretvalue 全局函数；再叠加无限客户端识别与
--           正式服 12.x 接口号兜底，避免只靠单一特征误判。
-- ============================================================
function WR_IsCLEUBlocked()
    if type(issecretvalue) == "function" then return true end
    if type(WR_Forever_ClientInfo) == "function" then
        local ok, info = pcall(WR_Forever_ClientInfo)
        if ok and type(info) == "table" then
            if info.isForever then return true end
            local iface = tonumber(info.interface) or 0
            if iface >= 120000 then return true end
        end
    end
    return false
end

-- ============================================================
-- 安全事件注册入口
-- 参数：frame —— 已创建且已设置 OnEvent 的 Frame
--       event —— 事件名字符串
-- 返回：boolean，是否真的注册了事件
-- 说明：CLEU 在 12.x 直接注册会触发 ADDON_ACTION_FORBIDDEN；此处静默
--       跳过，战斗日志职责由 Core/Forever_APIShim.lua 的安全事件桥接
--       （UNIT_SPELLCAST_* / UNIT_POWER_UPDATE 合成伪事件）承担。
--       其它事件一律原样注册，SoD / 经典客户端行为完全不变。
-- ============================================================
function WR_RegisterEventSafe(frame, event)
    if type(frame) ~= "table" and type(frame) ~= "userdata" then return false end
    if event == "COMBAT_LOG_EVENT_UNFILTERED" and WR_IsCLEUBlocked() then
        return false
    end
    frame:RegisterEvent(event)
    return true
end
