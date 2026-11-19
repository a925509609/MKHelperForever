-- ============================================================
-- Core/InterruptController.lua
-- 统一打断阈值控制：将「目标/焦点读条即打断」升级为
-- 「按施法进度百分比打断」，所有职业共用同一引擎。
--
-- 菜单项改为滑块（0~100，步长5，默认50）：
--     0      = 关闭打断
--     5~100  = 在目标施法进度达到该百分比时打断（默认50）
-- 兼容旧布尔存档：true→50（开），false→关闭。
--
-- ★★★ 2026-11-19 用户口径「防骑打断滑块设置后无效，目标读条时不亮制裁之锤」：
--   根因：WR_GetCastProgress 把 UnitCastingInfo / UnitChannelInfo 返回的 startTimeMS /
--   endTimeMS 直接当普通 number 做算术。但 Forever 12.x 里这些时间戳是 secret value
--   （EllesmereUINameplates PlatePool.lua:568 同一实证注释），C 侧会拦截算术 →
--   要么 pcall 吞掉 → 返回 nil → WR_ShouldInterrupt=false → 防骑 InterruptStep 不亮；
--   要么直接抛 secret 比较错误 → 被外层看门狗吞掉 → 表现就是「滑块设了但一直无效」。
--
--   修法（本文件）：
--     ① 把防骑本地 WR_PaladinForever_DurationCastPercent 的 DurationObject 路径
--        （UnitCastingDuration / UnitChannelDuration + EvaluateElapsedPercent）提到
--        这里先试，让所有职业共用同一 secret-safe 进度来源；
--     ② DurationObject 不可用（经典客户端 / 离线夹具 / API 缺失）时退回原始时间戳，
--        所有算术与比较都包进 pcall + IsSecretValue 检测；
--     ③ 统一引擎能工作后，防骑 InterruptStep 里的 ①（WR_ShouldInterrupt）直接命中，
--        不再走到 ② 的兜底分支（兜底分支也同步改为调 WR_GetCastProgress，不再重复写
--        一套 DurationObject）。
-- ============================================================

-- secret 安全的 DurationObject 进度：先 cast，再 channel；EvaluateElapsedPercent
-- 用 CurveConstants.ScaleTo100（0~1 → 0~100）。全程包 pcall，任何一步失败都返回 nil。
--
-- ★ 重要前置：DurationObject 本身不带 notInterruptible 信息，需要先从
--   UnitCastingInfo / UnitChannelInfo 取 name + notInterruptible 作为闸门：
--     · name 非空 + notInterruptible=false → 允许走 DurationObject；
--     · name 是 secret / nil / 抛错 → 读不到施法类型，保守返回 nil（宁可不打断也不浪费制裁）；
--     · notInterruptible=true → 明确不可打断，返回 nil；
--     · notInterruptible 是 secret → 读不到是否可打断，保守返回 nil。
--   与 RawProgress 路径完全同口径，两条路都不会在「不确定可打断」的情况下乱亮制裁。
local function WR_Interrupt_CastGate(unit)
    local function secret(v)
        if WR_IsSecretValue ~= nil then
            local ok, s = pcall(WR_IsSecretValue, v)
            if ok and s == true then return true end
        end
        return false
    end
    -- UnitCastingInfo 返回 9 个值：name, text, tex, startMS, endMS, isTradeSkill, castID, notInterruptible, spellId
    -- UnitChannelInfo 返回 8 个值：name, text, tex, startMS, endMS, isTradeSkill, notInterruptible, spellId
    -- 两者 notInterruptible 的位置不同，必须分别解包。
    local function checkCasting()
        if type(UnitCastingInfo) ~= "function" then return nil end
        local ok, name, _, _, _, _, _, notInterruptible = pcall(UnitCastingInfo, unit)
        -- 上一行 _ 接住 text, texture, startMS, endMS, isTradeSkill, castID → notInterruptible 是第 8 个
        if not ok then return nil end
        if name == nil then return nil end
        if secret(name) then return nil end
        if secret(notInterruptible) then return nil end
        if notInterruptible == true then return nil end
        return "cast"
    end
    local function checkChannel()
        if type(UnitChannelInfo) ~= "function" then return nil end
        -- UnitChannelInfo: name, text, tex, startMS, endMS, isTradeSkill, notInterruptible, spellId
        -- isTradeSkill=false 必须用 _ 接住，否则会把它当成 notInterruptible
        local ok, name, _, _, _, _, _, notInterruptible = pcall(UnitChannelInfo, unit)
        if not ok then return nil end
        if name == nil then return nil end
        if secret(name) then return nil end
        if secret(notInterruptible) then return nil end
        if notInterruptible == true then return nil end
        return "channel"
    end
    return checkCasting() or checkChannel()
end

local function WR_Interrupt_DurationProgress(unit)
    -- 前置闸门：必须明确知道「正在施法 + 可打断」才往下走
    local kind = WR_Interrupt_CastGate(unit)
    if kind == nil then return nil end
    local curve = nil
    if type(CurveConstants) == "table" then
        curve = CurveConstants.ScaleTo100
    end
    if curve == nil and type(C_CurveUtil) == "table" and type(C_CurveUtil.CreateCurve) == "function" then
        local okC, c = pcall(C_CurveUtil.CreateCurve)
        if okC and c ~= nil then
            pcall(c.AddPoint, c, 0.0, 0)
            pcall(c.AddPoint, c, 1.0, 100)
            curve = c
        end
    end
    if curve == nil then return nil end
    local function eval(fn)
        if type(fn) ~= "function" then return nil end
        local okD, duration = pcall(fn, unit)
        if not okD or duration == nil then return nil end
        local okE, pct = pcall(function()
            return duration:EvaluateElapsedPercent(curve)
        end)
        if not okE or type(pct) ~= "number" then return nil end
        if WR_IsSecretValue ~= nil then
            local okS, isSecret = pcall(WR_IsSecretValue, pct)
            if okS and isSecret == true then return nil end
        end
        if pct < 0 then pct = 0 elseif pct > 100 then pct = 100 end
        return pct
    end
    local pct = eval(UnitCastingDuration)
    if pct ~= nil then return pct end
    return eval(UnitChannelDuration)
end

-- 把原始时间戳算成 0~100 进度；全部 secret safe。
local function WR_Interrupt_RawProgress(unit)
    local now = GetTime()
    local function secret(v)
        if WR_IsSecretValue ~= nil then
            local ok, s = pcall(WR_IsSecretValue, v)
            if ok and s == true then return true end
        end
        return false
    end
    local function calc(name, startMS, endMS, notInterruptible)
        if name == nil then return nil end
        if secret(name) or secret(startMS) or secret(endMS) then return nil end
        local okC, pct = pcall(function()
            if secret(notInterruptible) then return nil end
            if notInterruptible == true then return nil end
            local s = tonumber(startMS)
            local e = tonumber(endMS)
            if type(s) ~= "number" or type(e) ~= "number" or e <= s then return nil end
            local p = (now - s / 1000) / ((e - s) / 1000) * 100
            if p < 0 then p = 0 elseif p > 100 then p = 100 end
            return p
        end)
        if okC then return pct end
        return nil
    end
    if type(UnitCastingInfo) == "function" then
        -- UnitCastingInfo: name, text, tex, startMS, endMS, isTradeSkill, castID, notInterruptible, spellId
        local ok, name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible =
            pcall(UnitCastingInfo, unit)
        -- 上一行把 spellId 丢了（第 9 个）—— 不影响，notInterruptible 正确落在第 8 个位置
        if ok then
            local p = calc(name, startMS, endMS, notInterruptible)
            if p ~= nil then return p end
        end
    end
    if type(UnitChannelInfo) == "function" then
        -- UnitChannelInfo: name, text, tex, startMS, endMS, isTradeSkill, notInterruptible, spellId
        -- 必须用 _ 接住 isTradeSkill，否则 notInterruptible 会错位一个位置
        local ok, name, text, texture, startMS, endMS, _, notInterruptible =
            pcall(UnitChannelInfo, unit)
        if ok then
            local p = calc(name, startMS, endMS, notInterruptible)
            if p ~= nil then return p end
        end
    end
    return nil
end

-- 计算单位当前施法/引导进度（0~100），不可打断或不存在返回 nil
-- ★ 顺序：DurationObject（Forever 12.x 唯一安全通道）→ 原始时间戳（经典/离线）
function WR_GetCastProgress(unit)
    if not unit or not UnitExists(unit) then return nil end
    local okE, durPct = pcall(WR_Interrupt_DurationProgress, unit)
    if okE and type(durPct) == "number" then return durPct end
    local okR, rawPct = pcall(WR_Interrupt_RawProgress, unit)
    if okR and type(rawPct) == "number" then return rawPct end
    return nil
end

-- 统一打断判定：返回是否应在当前施法进度打断
--   unit    : "target" / "focus"
--   saveVar : 该职业打断滑块的存档变量名
-- 说明：
--   nil/true  → 阈值 50（旧布尔 true 兼容，等同开启）
--   false     → 关闭打断（旧布尔 false 兼容）
--   数字      → 该百分比为阈值；<=0 视为关闭
function WR_ShouldInterrupt(unit, saveVar)
    if not unit or not UnitExists(unit) then return false end
    local raw = PigSet[saveVar]
    if raw == false then return false end
    local thr = tonumber(raw)
    if thr == nil then thr = 50 end
    if thr <= 0 then return false end          -- 0 = 关闭打断
    local pct = WR_GetCastProgress(unit)
    if pct == nil then return false end
    local okCmp, should = pcall(function() return pct >= thr end)
    if not okCmp then return false end
    return should == true
end
