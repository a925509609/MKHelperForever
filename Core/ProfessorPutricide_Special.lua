-- ============================================================
-- ProfessorPutricide_Special.lua
-- 功能：判断普崔塞德教授战斗中，玩家的软泥特性/异变毒气buff
--       对应的目标（不稳定的软泥怪/毒气之云）是否可攻击
-- ============================================================

jiaoshouruanni = false

function CheckSpecialTargets()
    local hasSoftDebuff = WR_GetUnitDebuffTime("player", "软泥特性") > 0
    local hasGasDebuff = WR_GetUnitDebuffTime("player", "异变毒气") > 0

    if not hasSoftDebuff and not hasGasDebuff then
        return true
    end

    jiaoshouruanni = false

    for i = 1, 25 do
        local unit = "raid" .. i .. "target"
        if UnitExists(unit) then
            local unitName = UnitName(unit)
            if hasSoftDebuff and unitName == "不稳定的软泥怪" then
                jiaoshouruanni = true
                break
            end
            if hasGasDebuff and unitName == "毒气之云" then
                jiaoshouruanni = true
                break
            end
        end
    end

    return jiaoshouruanni
end