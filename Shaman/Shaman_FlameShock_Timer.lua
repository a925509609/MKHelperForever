-- ============================================================
-- Shaman_FlameShock_Timer.lua
-- 功能：监控当前目标身上的烈焰震击（ID 49233）剩余时间
--       结果存储在全局变量 ryzj 中（单位：秒）
--       供增强/元素萨输出循环判断是否需要补震击
-- ============================================================

if WR_PlayerClass ~= "SHAMAN" then return end

if UnitClassBase("player") ~= "SHAMAN" then
    return
end

-- ============================================================
-- ★ 全局变量
-- ============================================================
ryzj = nil  -- 烈焰震击剩余时间（秒）

-- ============================================================
-- ★ 更新烈焰震击剩余时间
-- ============================================================
local function UpdateRYZJ()
    local currentTime = GetTime()
    local found = false

    -- 遍历目标身上的所有Debuff，查找烈焰震击（ID 49233）
    for i = 1, 40 do
        local _, _, _, _, _, expiration, _, _, _, spellID = UnitDebuff("target", i)
        if spellID == 49233 then  -- 烈焰震击ID
            if expiration and expiration > currentTime then
                ryzj = expiration - currentTime
                found = true
                break
            end
        end
    end

    if not found then
        ryzj = nil
    end
end

-- ============================================================
-- ★ 事件监听帧
-- ============================================================
local ryzjFrame = CreateFrame("Frame")
ryzjFrame:RegisterEvent("PLAYER_TARGET_CHANGED")   -- 目标切换
ryzjFrame:RegisterEvent("UNIT_AURA")               -- 光环变化
ryzjFrame:RegisterEvent("PLAYER_ENTERING_WORLD")   -- 进入世界

ryzjFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_TARGET_CHANGED" or
       (event == "UNIT_AURA" and unit == "target") or
       event == "PLAYER_ENTERING_WORLD" then
        UpdateRYZJ()
    end
end)

-- ============================================================
-- ★ 定时更新（每0.1秒刷新一次）
-- ============================================================
ryzjFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed > 0.1 then
        UpdateRYZJ()
        self.elapsed = 0
    end
end)