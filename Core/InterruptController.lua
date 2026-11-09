-- ============================================================
-- Core/InterruptController.lua
-- 统一打断阈值控制：将「目标/焦点读条即打断」升级为
-- 「按施法进度百分比打断」，所有职业共用同一引擎。
--
-- 菜单项改为滑块（0~100，步长5，默认50）：
--     0      = 关闭打断
--     5~100  = 在目标施法进度达到该百分比时打断（默认50）
-- 兼容旧布尔存档：true→50（开），false→关闭。
-- ============================================================

-- 计算单位当前施法/引导进度（0~100），不可打断或不存在返回 nil
function WR_GetCastProgress(unit)
    if not unit or not UnitExists(unit) then return nil end
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID,
          notInterruptible, spellId = UnitCastingInfo(unit)
    if endTimeMS then
        if notInterruptible then return nil end
        local total = (endTimeMS - startTimeMS) / 1000
        if total <= 0 then return 0 end
        local pct = (GetTime() - startTimeMS / 1000) / total * 100
        if pct < 0 then pct = 0 elseif pct > 100 then pct = 100 end
        return pct
    end
    local cname, ctext, ctexture, cstartMS, cendMS, cisTradeSkill, ccastID,
          cnotInterruptible, cspellId = UnitChannelInfo(unit)
    if cendMS then
        if cnotInterruptible then return nil end
        local ctotal = (cendMS - cstartMS) / 1000
        if ctotal <= 0 then return 0 end
        local pct = (GetTime() - cstartMS / 1000) / ctotal * 100
        if pct < 0 then pct = 0 elseif pct > 100 then pct = 100 end
        return pct
    end
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
    return pct >= thr
end
