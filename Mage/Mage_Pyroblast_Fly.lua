-- 仅当玩家是法师时才执行
if WR_PlayerClass ~= "MAGE" then return end

if UnitClassBase("player") ~= "MAGE" then
  return
end

yanbaofly = true  -- 全局变量：true=没有飞行中的炎爆，false=炎爆正在飞行

local PYROBLAST_ID = 42891  -- 炎爆术法术ID

-- 创建帧监听战斗日志
local frame = CreateFrame("Frame")
WR_RegisterEventSafe(frame, "COMBAT_LOG_EVENT_UNFILTERED")

frame:SetScript("OnEvent", function(self, event, ...)
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    -- 获取战斗日志信息：子事件、施法者GUID、法术ID等
    local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = unpack(WR_CombatLogEvent)

    -- 只处理玩家自己施放的法术
    if sourceGUID ~= UnitGUID("player") then
      return
    end

    -- 只处理炎爆术
    if spellId ~= PYROBLAST_ID then
      return
    end

    -- 根据子事件更新飞行状态
    if subEvent == "SPELL_CAST_SUCCESS" then
      yanbaofly = false  -- 施放成功，炎爆还在飞行中
    elseif subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_MISSED" then
      yanbaofly = true   -- 命中或未命中，飞行已结束
    end
  end
end)