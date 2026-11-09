-- 仅当玩家是法师时才执行（select(2, UnitClass("player")) 返回职业名称）
if WR_PlayerClass ~= "MAGE" then return end

if select(2, UnitClass("player")) ~= "MAGE" then
  return
end

WR_FS_Fire_RanShao = 0  -- 全局变量：燃烧剩余可触发的暴击次数

-- 关键法术ID
local BURNING_ID = 28682     -- 燃烧BUFF的ID
local FIREBALL_ID = 42833    -- 火球术ID
local PYROBLAST_ID = 42891   -- 炎爆术ID
-- 55362 是瞬发炎爆术（来自法术连击）的ID，也会消耗燃烧次数

-- 创建帧监听事件
local f = CreateFrame("Frame")
f:RegisterEvent("UNIT_AURA")                -- 监听光环变化（BUFF增减）
WR_RegisterEventSafe(f, "COMBAT_LOG_EVENT_UNFILTERED") -- 监听战斗日志（伤害事件）

-- 检查玩家身上是否有燃烧BUFF，并更新剩余次数（使用缓存）
local function CheckBurningBuff()
  WR_ForceRefreshAuraCache("player")

  local found = false
  local cache = WR_AuraCache["player"]
  if cache then
    local auras = cache.HELPFUL or {}
    for i = 1, #auras do
      if auras[i].spellId == BURNING_ID then
        found = true
        break
      end
    end
  end

  if found then
    if WR_FS_Fire_RanShao == 0 then
      WR_FS_Fire_RanShao = 3
    end
  else
    if WR_FS_Fire_RanShao > 0 then
      WR_FS_Fire_RanShao = 0
    end
  end
end

-- 事件处理函数
f:SetScript("OnEvent", function(self, event, ...)
  if event == "UNIT_AURA" then
    -- UNIT_AURA事件会传递单位参数，只处理玩家自身的光环变化
    local unit = ...
    if unit == "player" then
      CheckBurningBuff()
    end

  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    -- 解析战斗日志，提取关键信息
    local timestamp, eventType, _, sourceGUID, _, _, _, _, _, _, _, spellId, _, _, _, _, _, _, _, _, critical =
      unpack(WR_CombatLogEvent)

    -- 只处理玩家造成的法术伤害，且必须是暴击，且剩余次数大于0
    if eventType == "SPELL_DAMAGE" and sourceGUID == UnitGUID("player") and critical and WR_FS_Fire_RanShao > 0 then
      -- 如果法术是火球术、炎爆术或瞬发炎爆术，则消耗一次燃烧次数
      if spellId == FIREBALL_ID or spellId == PYROBLAST_ID or spellId == 55362 then
        WR_FS_Fire_RanShao = WR_FS_Fire_RanShao - 1
      end
    end
  end
end)