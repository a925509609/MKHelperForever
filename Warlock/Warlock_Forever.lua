-- ============================================================
-- Warlock_Forever.lua  《魔兽世界：无限》(Forever) WARLOCK 完整循环
-- ------------------------------------------------------------
-- 机械转译自原 SoD 旋转：移除全部 WR_SoD_HasRune 符文门（无限无符文系统），
-- 改走 WR_SpellUsable（已含 WR_Forever_SkillAbsent 缺失闸门）+ WR_Forever_IsSpellKnown。
-- 无限里真实存在的经典/TBC 技能按原名解析；缺失的 WotLK/SoD 专属技能由闸门跳过。
-- ============================================================

function WR_WarlockForeverRotation()
    local spec = WR_GetMyTalent()
    local isForever = WR_Forever_ClientInfo().isForever
    -- 非 Forever 客户端：回退原 SoD 实现
    if not isForever then
        if spec == "痛苦" then WR_WarlockAffliction() end
        if spec == "恶魔学识" then WR_WarlockDemonology() end
        if spec == "毁灭" then WR_WarlockDestruction() end
        return
    end
    -- Forever 路径
    if spec == "痛苦" then WR_WarlockForeverAffliction() end
    if spec == "恶魔学识" then WR_WarlockForeverDemonology() end
    if spec == "毁灭" then WR_WarlockForeverDestruction() end
end
