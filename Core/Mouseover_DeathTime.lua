-- 全局变量，用于记录鼠标悬停目标的信息
mouseoverTodeathtime = nil   -- 预计死亡时间（秒）
mouseoverGUID = nil          -- 目标的唯一ID（用来判断是否换了目标）
mouseoverbegintime = nil     -- 开始记录血量的时间点
mouseoverhealth = nil        -- 开始记录时的血量
UnitHealthProportion = 0.9   -- 血量阈值（90%），超过此值会重置计时

-- 计算鼠标悬停目标的预估死亡时间
function CalculateMouseOverDeathTime()
  local unit = "mouseover"                 -- 固定为鼠标悬停单位
  -- ★ 无限适配：战斗中 UnitGUID 可能是 secret string，比较会抛
  --   "attempt to compare ... secret string"，统一降级为 nil。
  local currentGUID = WR_SafeUnitGUID(unit)
  local currentHealth = WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1))   -- 当前血量
  local currentHealthMax = WR_SafeNumber(UnitHealthMax(unit), 1) -- 最大血量
  local currentTime = GetTime()            -- 当前游戏时间

  -- 如果没有悬停目标，清空记录
  if not currentGUID then
    mouseoverTodeathtime = nil
    mouseoverGUID = nil
    mouseoverbegintime = nil
    mouseoverhealth = nil
    return
  end

  local prevGUID = mouseoverGUID
  if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(prevGUID) then
    prevGUID = nil
  end

  -- 如果换了目标，或者当前血量 ≥ 90%最大血量，则重新开始计时
  if prevGUID ~= currentGUID or currentHealth >= currentHealthMax * UnitHealthProportion then
    mouseoverbegintime, mouseoverhealth = currentTime, currentHealth
  -- 如果已有开始记录，且血量在下降（比记录时少）
  elseif mouseoverbegintime and mouseoverhealth and mouseoverhealth > currentHealth then
    local healthChange = mouseoverhealth - currentHealth   -- 掉血量
    local timeChange = currentTime - mouseoverbegintime    -- 耗时
    mouseoverTodeathtime = currentHealth / (healthChange / timeChange) -- 按当前速率估算剩余秒数
  end

  mouseoverGUID = currentGUID  -- 更新GUID
end

-- ★ B-3：鼠标悬停死亡时间计算已并入统一辅助 ticker（Core_Functions.lua 末尾 WR_AuxTicker），
--   由每帧无节流改为 0.1s（10Hz）刷新。CalculateMouseOverDeathTime() 仍保持全局函数。