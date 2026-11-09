-- ============================================================
-- Warrior Forever · Fury 专精循环
-- 共享 helper 见 Warrior_Forever.lua（公共件）
-- 由程序从原单文件物理拆分，逻辑未改动
-- ============================================================

function WR_WarriorForeverFury()
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("英勇打击")
    PlayerHP = WR_GetUnitHP("player")
    PlayerRage = WR_SafeNumber(UnitPower("player", 1), 0)
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)

    -- 生存/解控
    if WR_WarriorFury_KZ() then return true end        -- 狂暴之怒（解恐/解控）
    if WR_WarriorFury_GongJi() then return true end    -- 自动攻击

    -- 战斗门
    if not (UnitAffectingCombat("player") and TargetInCombat) then return false end

    -- 爆发
    if WR_WarriorFury_LM() then return true end        -- 鲁莽
    if WR_WarriorFury_KZ2() then return true end       -- 狂暴之怒（爆发）
    if WR_WarriorFury_BZ() then return true end        -- 狂暴打击（胸符文）

    -- 核心输出
    if WR_WarriorFury_ZS() then return true end        -- 斩杀（<20%）
    if WR_WarriorFury_XLZ() then return true end       -- 旋风斩（AoE）
    if WR_WarriorFury_SPP() then return true end       -- 顺劈斩（AoE）
    if WR_WarriorFury_XJ() then return true end        -- 迅捷打击（手符文副手）
    if WR_WarriorFury_MJ() then return true end        -- 猛击（触发）
    if WR_WarriorFury_XX() then return true end        -- 嗜血（常驻）
    if WR_WarriorFury_MP() then return true end        -- 英勇打击（怒气填充）

    return false
end
