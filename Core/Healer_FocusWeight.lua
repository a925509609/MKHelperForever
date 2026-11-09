-- ============================================================
-- 治疗焦点权重：为TOC加拉克苏斯大王"血肉成灰"提供高优先级治疗
-- 功能：当有人中血肉成灰时，强制对该目标过量刷血直到DEBUFF消失
-- ============================================================

-- 各职业对应的高效治疗技能（用于刷血肉）
local WR_JaraxxusFleshHealSpell = {
  PRIEST   = { button = 57,  spell = "快速治疗" },
  PALADIN  = { button = 110, spell = "圣光术" },
  DRUID    = { button = 106, spell = "滋养" },
  SHAMAN   = { button = 76,  spell = "次级治疗波" },
}

-- 获取当前职业的治疗技能配置
local function WR_JaraxxusFleshGetHealSpell()
  return WR_JaraxxusFleshHealSpell[UnitClassBase("player")]
end

-- 核心治疗动作：调用WR_ColorFrame_Show通知插件施放技能
local function WR_JaraxxusFleshCastOnly()
  local heal = WR_JaraxxusFleshGetHealSpell()
  if not heal then
    return true  -- 职业不支持则返回true（跳过后续逻辑）
  end
  if WR_ColorFrame_Show then
    WR_ColorFrame_Show(heal.button, "血肉")  -- 通过按钮ID触发治疗技能
  end
  return true
end

-- 主函数：判断是否需要刷血肉，并执行治疗
function WR_JaraxxusFleshOverhealHeal()
  -- 检查功能是否启用（外部函数，由菜单控制）
  if not WR_JaraxxusFleshHealEnabled or not WR_JaraxxusFleshHealEnabled() then
    WR_JaraxxusFleshSpamActive = false
    return false
  end

  -- 查找中血肉成灰的目标（外部函数）
  local fleshUnit = WR_FindJaraxxusFleshUnit and WR_FindJaraxxusFleshUnit()
  if not fleshUnit then
    WR_JaraxxusFleshSpamActive = false
    return false
  end

  WR_JaraxxusFleshSpamActive = true

  -- 如果焦点不是该目标，则把焦点设为该目标（方便监视）
  if not UnitIsUnit("focus", fleshUnit) then
    if WR_FocusUnit and WR_FocusUnit(fleshUnit, "血肉") then
      return true
    end
    if WR_FocusMaxWeightUnit and WR_FocusMaxWeightUnit() then
      return true
    end
    return true
  end

  -- 焦点单位是否仍有血肉成灰DEBUFF，如果没有则停止治疗
  if not WR_UnitHasJaraxxusFleshToAshes("focus") then
    WR_JaraxxusFleshSpamActive = false
    return false
  end

  -- 计算损失血量，确保有过量治疗空间
  local maxHp = WR_SafeNumber(UnitHealthMax("focus"), 1) or 30000
  FocusLostHealth = math.max(WR_GetUnitLostHealth("focus"), maxHp)
  FocusHP = WR_GetUnitHP("focus", "盾")

  -- 执行治疗动作
  return WR_JaraxxusFleshCastOnly()
end

-- 包装函数：用于替换常规治疗循环，当有血肉时优先处理
function WR_RunHealerWithFleshPriority(healerFunc)
  if not healerFunc or type(healerFunc) ~= "function" then
    -- 如果传入的不是有效函数,跳过
    return false
  end

  -- ★ 无限适配（1.60.x / 12.x 同源）：战斗中 C_UnitAuras.GetAuraDataByIndex 对
  --   受 taint 路径直接抛 "Auras cannot be accessed when secret"，「血肉成灰」
  --   判定在无限服战斗中不可能得到真实结果，该优先治疗链永远无法生效。
  --   这里在分发器层直接跳过整条链：既保持治疗循环行为不变，又避免每帧对
  --   全队（raid 最多 25 人）做无效光环扫描（原 25749x 报错的触发源）。
  --   经典/SoD 客户端不受影响，仍走下方原逻辑。
  if type(WR_Forever_ClientInfo) == "function" then
    local ok, info = pcall(WR_Forever_ClientInfo)
    if ok and type(info) == "table" and info.isForever then
      return healerFunc()
    end
  end

  if WR_JaraxxusFleshOverhealHeal() then
    return   -- 如果已经处理了血肉，则不再执行常规治疗
  end
  return healerFunc()  -- 否则执行常规治疗函数
end