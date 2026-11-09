-- 仅当玩家是法师时执行
if WR_PlayerClass ~= "MAGE" then return end

if UnitClassBase("player") ~= "MAGE" then
  return
end

-- 全局状态变量
aoshu2 = false   -- 是否达到2层充能
aoshu3 = false   -- 是否达到3层充能
aoshu4 = false   -- 是否达到4层充能
if not aoshucount then aoshucount = 0 end  -- 充能计数
if not aoshutime then aoshutime = 0 end    -- 时间戳（暂未使用）

-- 战斗日志事件处理
local function OnCombatEvent(self, event, ...)
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local timestamp, subEvent, _, sourceGUID, sourceName, _, destGUID, destName, _, _, _, spellId, spellName =
      unpack(WR_CombatLogEvent)

    -- 当玩家施放奥术冲击时，延迟0.3秒后增加计数并更新层数标志
    if subEvent == "SPELL_CAST_START" and spellName == "奥术冲击" and sourceName == UnitName("player") then
      C_Timer.After(0.3, function()
        aoshucount = aoshucount + 1
        if aoshucount >= 4 then
          aoshu4 = true
        elseif aoshucount >= 3 then
          aoshu3 = true
        elseif aoshucount >= 2 then
          aoshu2 = true
        end
      end)
    end

    -- 当奥术飞弹或奥术弹幕施放成功时，重置所有层数标志
    if subEvent == "SPELL_CAST_SUCCESS" and (spellName == "奥术飞弹" or spellName == "奥术弹幕")
       and sourceName == UnitName("player") then
      aoshu2 = false
      aoshu3 = false
      aoshu4 = false
    end
  end
end

-- 创建帧注册事件
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", OnCombatEvent)