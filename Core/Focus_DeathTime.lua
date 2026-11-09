-- ============================================================
-- 焦点目标预计死亡时间计算器
-- 功能：通过追踪焦点目标的血量下降速度，估算其剩余存活时间
-- 用途：帮助玩家判断是否需要转火、补DOT或调整技能优先级
-- 原理：持续记录血量变化，用线性插值估算剩余时间
-- ============================================================

-- ===== 全局变量（用于存储焦点目标的状态数据） =====
JDtodeathtime = nil      -- 焦点目标预计死亡剩余时间（秒），nil表示无效
focusGUID = nil          -- 焦点目标的唯一GUID（用于判断是否切换了目标）
focusbegintime = nil     -- 开始记录血量的时间点（GetTime()返回值）
focushealth = nil        -- 开始记录时的血量数值
UnitHealthProportion = 0.9  -- 血量重置阈值：当前血量 >= 最大血量 * 0.9 时重置计时器
                          -- （表示目标被治疗过，原有的掉速估算已失效）

-- ===== 核心计算函数 =====
function CalculateFocusDeathTime()
  local unit = "focus"                   -- 固定监控"焦点"单位
  -- ★ 无限适配：战斗中 UnitGUID 可能是 secret string，比较会抛错
  local currentGUID = WR_SafeUnitGUID(unit)
  local currentHealth = WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1)) -- 当前血量
  local currentHealthMax = WR_SafeNumber(UnitHealthMax(unit), 1) -- 最大血量
  local currentTime = GetTime()          -- 当前游戏时间（秒）

  -- 如果不存在焦点目标，清空所有记录
  if not currentGUID then
    JDtodeathtime = nil
    focusGUID = nil
    focusbegintime = nil
    focushealth = nil
    return
  end

  local prevGUID = focusGUID
  if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(prevGUID) then
    prevGUID = nil
  end

  -- 判断是否需要重置计时基准
  -- 两种情况会重置：
  --   1. 焦点目标发生了切换（GUID不同）
  --   2. 当前血量 >= 最大血量的 90%（说明被治疗过，掉速已不准）
  if prevGUID ~= currentGUID or currentHealth >= currentHealthMax * UnitHealthProportion then
    -- 重置：记录当前时间和血量作为新的基准点
    focusbegintime, focushealth = currentTime, currentHealth

  -- 如果存在有效的基准点，且血量在持续下降（小于记录时的血量）
  elseif focusbegintime and focushealth and focushealth > currentHealth then
    -- 计算从基准点到现在的掉血总量和时间差
    local healthChange = focushealth - currentHealth   -- 掉了多少血
    local timeChange = currentTime - focusbegintime    -- 经过了多少秒

    -- 估算剩余存活时间：当前血量 / 每秒掉血量
    -- 注意：当 healthChange 为 0 时不会进入此分支（因为有 focushealth > currentHealth 判断）
    JDtodeathtime = currentHealth / (healthChange / timeChange)
  end

  -- 更新GUID记录（用于下次判断是否切换目标）
  focusGUID = currentGUID
end

-- ★ B-3：焦点死亡时间计算已并入统一辅助 ticker（Core_Functions.lua 末尾 WR_AuxTicker），
--   由每帧无节流改为 0.1s（10Hz）刷新，团本中显著降低无效开销。
--   CalculateFocusDeathTime() 仍保持全局函数，供统一 ticker 调用。

-- ============================================================
-- 使用说明：
--   1. 设置好焦点目标后，该脚本会自动追踪其血量变化
--   2. 全局变量 JDtodeathtime 中存储了预计剩余存活秒数
--   3. 其他插件或脚本可以直接读取 JDtodeathtime 来判断是否转火
--   4. 如果目标被治疗导致血量回满（≥90%），计时器会自动重置
-- ============================================================