-- ============================================================
-- 雄鹰射击BUFF计时器（Forever 受限 API 版）
-- 功能：追踪玩家身上"雄鹰射击"BUFF的剩余时间，支持最多同时记录2个BUFF实例
-- 改动：原版用 COMBAT_LOG_EVENT_UNFILTERED（无限已禁用）检测 BUFF 施加；
--       现改为 UNIT_AURA + 光环缓存（WR_GetUnitBuffTime）判定剩余时间，完全去除 CLEU 依赖。
-- ============================================================

if WR_PlayerClass ~= "HUNTER" then return end

local EAGLE_SHOT_BUFF_ID = 1284379  -- 雄鹰射击BUFF的ID
local EAGLE_SHOT_BUFF_DURATION = 18 -- 雄鹰射击BUFF持续18秒
local MAX_TRACKED_BUFFS = 2         -- 最多追踪2个BUFF（通常同一时间只有1个，但以防刷新）

WR_EagleShotTimers = {}             -- 全局表，存储所有BUFF的预期过期时间（Unix时间戳）

-- 创建帧监听事件（不再监听 COMBAT_LOG_EVENT_UNFILTERED）
local WR_Frame = CreateFrame("Frame")
WR_Frame:RegisterEvent("UNIT_AURA")                 -- 光环变化（含玩家获得/失去雄鹰射击）
WR_Frame:RegisterEvent("PLAYER_REGEN_DISABLED")      -- 进入战斗
WR_Frame:RegisterEvent("PLAYER_DEAD")               -- 死亡
WR_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")     -- 进入世界

-- 重算雄鹰射击计时表：直接读光环缓存里的剩余时间，写入预期过期时间戳
local function RefreshEagleShotTimers()
    local remaining = 0
    if WR_GetUnitBuffTime then
        remaining = WR_GetUnitBuffTime("player", EAGLE_SHOT_BUFF_ID, nil, "ID")
    else
        -- 兜底：直接走 C_UnitAuras
        local data
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            for i = 1, 40 do
                data = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
                if not data then break end
                if data.spellId == EAGLE_SHOT_BUFF_ID then
                    remaining = (data.expirationTime or 0) - GetTime()
                    break
                end
            end
        end
    end

    local now = GetTime()
    WR_EagleShotTimers = {}
    if remaining and remaining > 0 then
        table.insert(WR_EagleShotTimers, now + remaining)
        -- BUFF 可被刷新叠加，按持续时间补齐第 2 个实例（上限 MAX_TRACKED_BUFFS）
        while #WR_EagleShotTimers < MAX_TRACKED_BUFFS do
            local last = WR_EagleShotTimers[#WR_EagleShotTimers]
            if last + EAGLE_SHOT_BUFF_DURATION <= now + EAGLE_SHOT_BUFF_DURATION * 2 then
                table.insert(WR_EagleShotTimers, last + EAGLE_SHOT_BUFF_DURATION)
            else
                break
            end
        end
    end
    table.sort(WR_EagleShotTimers)
end

-- 事件处理
WR_Frame:SetScript("OnEvent", function(self, event, ...)
    -- 进入战斗、死亡、换地图时清空所有计时（BUFF消失）
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_DEAD" or event == "PLAYER_ENTERING_WORLD" then
        WR_EagleShotTimers = {}
        return
    end

    if event == "UNIT_AURA" then
        local unit = ...
        -- 仅关心玩家自身光环变化（雄鹰射击作用于玩家）
        if unit == "player" or unit == nil then
            RefreshEagleShotTimers()
        end
    end
end)

-- 对外函数：返回最早的雄鹰射击剩余时间（秒），如果没有则返回0
function WR_GetEarliestEagleShotRemaining()
    -- 实时重算，避免依赖事件触发的缓存过期不及时
    RefreshEagleShotTimers()
    local currentTime = GetTime()
    if #WR_EagleShotTimers > 0 then
        local remaining = WR_EagleShotTimers[1] - currentTime
        if remaining > 0 then
            return remaining
        end
    end
    return 0
end
