-- ============================================================
-- Shaman_ElementalMastery.lua
-- 功能：监控元素掌握的冷却状态
--       当施放元素掌握时设置 yszw = false，并开始182秒倒计时
--       施放闪电箭/闪电链可减少2秒冷却（天赋效果）
--       当倒计时归零时恢复 yszw = true
-- ============================================================

if WR_PlayerClass ~= "SHAMAN" then return end

if UnitClassBase("player") ~= "SHAMAN" then
    return
end

-- ============================================================
-- ★ 全局变量
-- ============================================================
yszw = true          -- 元素掌握是否可用（全局供元素萨使用）
daojishi = 0         -- 剩余冷却时间（秒）

-- ============================================================
-- ★ 战斗日志事件帧
-- ============================================================
local frame = CreateFrame("Frame")
WR_RegisterEventSafe(frame, "COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(self, event, ...)
    -- 脱离战斗时重置元素掌握状态
    if event == "PLAYER_REGEN_ENABLED" then
        yszw = true
        daojishi = 0
        return
    end

    local timestamp, subevent, _, _, sourceName, _, _, _, _, _, _, spellId, spellName = unpack(WR_CombatLogEvent)

    if subevent == "SPELL_CAST_SUCCESS" and sourceName == UnitName("player") then
        if spellName == "元素掌握" then
            yszw = false
            daojishi = 182
        elseif spellName == "闪电箭" or spellName == "闪电链" then
            -- 天赋效果：闪电箭/闪电链可减少2秒冷却
            daojishi = math.max(daojishi - 2, 0)
            if daojishi == 0 then
                yszw = true
            end
        end
    end
end)

-- ============================================================
-- ★ 定时器：每秒更新倒计时
-- ============================================================
frame:SetScript("OnUpdate", function(self, elapsed)
    if not yszw and daojishi > 0 then
        daojishi = math.max(daojishi - elapsed, 0)
        if daojishi <= 0 then
            yszw = true
        end
    end
end)