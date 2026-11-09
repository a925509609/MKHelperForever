-- ============================================================
-- Utils_UnitAura_Dispatcher.lua
-- 共享 UNIT_AURA 事件调度器
-- 提供单一帧注册、多回调分发，减少 UNIT_AURA 帧数量
-- ============================================================

local WR_UnitAura_Frame = CreateFrame("Frame")
WR_UnitAura_Frame:RegisterEvent("UNIT_AURA")

local WR_UnitAura_Handlers = {}

-- 注册 UNIT_AURA 回调
-- callback(unit, ...) - 光环变化时调用
-- unitFilter (可选) - 仅当 UNIT_AURA 的 unit 匹配此值时才触发，nil 表示所有单位
function WR_RegisterUnitAuraHandler(callback, unitFilter)
    if not callback then return end
    WR_UnitAura_Handlers[callback] = unitFilter
end

-- 移除已注册的回调
function WR_UnregisterUnitAuraHandler(callback)
    WR_UnitAura_Handlers[callback] = nil
end

WR_UnitAura_Frame:SetScript("OnEvent", function(self, event, unit, ...)
    if event ~= "UNIT_AURA" then return end
    for callback, unitFilter in pairs(WR_UnitAura_Handlers) do
        if not unitFilter or unit == unitFilter then
            local ok, err = pcall(callback, unit, ...)
            if not ok then
                print("|cffff0000[WR UnitAura]|r " .. tostring(err))
            end
        end
    end
end)
