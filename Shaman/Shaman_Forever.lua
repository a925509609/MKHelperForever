-- ============================================================
-- Shaman_Forever.lua  《魔兽世界：无限》(Forever) SHAMAN 完整循环
-- ------------------------------------------------------------
-- 机械转译自原 SoD 旋转：移除全部 WR_SoD_HasRune 符文门（无限无符文系统），
-- 改走 WR_SpellUsable（已含 WR_Forever_SkillAbsent 缺失闸门）+ WR_Forever_IsSpellKnown。
-- 无限里真实存在的经典/TBC 技能按原名解析；缺失的 WotLK/SoD 专属技能由闸门跳过。
-- ============================================================

function WR_ShamanForeverRotation()
    local spec = WR_GetMyTalent()
    local isForever = WR_Forever_ClientInfo().isForever
    -- 非 Forever 客户端：回退原 SoD 实现
    if not isForever then
        if spec == "元素" then WR_ShamanElemental() end
        if spec == "增强" then WR_ShamanEnhancement() end
        if spec == "恢复" then WR_RunHealerWithFleshPriority(WR_ShamanRestoration) end
        return
    end
    -- Forever 路径
    if spec == "元素" then WR_ShamanForeverElemental() end
    if spec == "增强" then WR_ShamanForeverEnhancement() end
    if spec == "恢复" then WR_RunHealerWithFleshPriority(WR_ShamanForeverRestoration) end
end
