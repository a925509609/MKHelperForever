-- ============================================================
-- Warrior Forever · Arms 专精循环
-- 共享 helper 见 Warrior_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_WarriorForeverArms()
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("英勇打击")
    PlayerHP = WR_GetUnitHP("player")
    PlayerRage = WR_SafeNumber(UnitPower("player", 1), 0)  -- 怒气 powerType=1
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)

    -- 生存/解控最高优先级
    if WR_WarriorArms_KZ() then return true end        -- 狂暴之怒（解恐/解控）
    if WR_WarriorArms_GongJi() then return true end    -- 自动攻击

    -- 战斗门
    if not (UnitAffectingCombat("player") and TargetInCombat) then return false end

    -- 爆发（符文）
    if WR_WarriorArms_BZ() then return true end        -- 鞭笞（胸符文）

    -- 核心输出
    if WR_WarriorArms_ZS() then return true end        -- 斩杀（<20%）
    if WR_WarriorArms_YZ() then return true end        -- 压制（触发）
    if WR_WarriorArms_XLZ() then return true end       -- 旋风斩（AoE）
    if WR_WarriorArms_SPP() then return true end       -- 顺劈斩（AoE 怒气充裕）
    if WR_WarriorArms_MJ() then return true end        -- 猛击（触发）
    if WR_WarriorArms_HXJB() then return true end      -- 致死打击（常驻）
    if WR_WarriorArms_MP() then return true end        -- 英勇打击（怒气填充）

    return false
end
