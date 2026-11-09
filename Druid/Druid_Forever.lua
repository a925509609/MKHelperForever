-- ============================================================
-- Druid_Forever.lua  《魔兽世界：无限》(Forever) DRUID 完整循环
-- ------------------------------------------------------------
-- 机械转译自原 SoD 旋转：移除全部 WR_SoD_HasRune 符文门（无限无符文系统），
-- 改走 WR_SpellUsable（已含 WR_Forever_SkillAbsent 缺失闸门）+ WR_Forever_IsSpellKnown。
-- 无限里真实存在的经典/TBC 技能按原名解析；缺失的 WotLK/SoD 专属技能由闸门跳过。
-- ============================================================

function WR_DruidForeverRotation()
    local spec = WR_GetMyTalent()
    local isForever = WR_Forever_ClientInfo().isForever
    -- 非 Forever 客户端：回退原 SoD 实现
    if not isForever then
        if spec == "平衡" then WR_DruidBalance() end
        if spec == "野性战斗" or spec == "野性" then WR_DruidFeral() end
        if spec == "守护" then WR_DruidGuardian() end
        if spec == "恢复" then WR_RunHealerWithFleshPriority(WR_DruidRestoration) end
        return
    end
    -- Forever 路径
    if spec == "平衡" then WR_DruidForeverBalance() end
    if spec == "野性战斗" or spec == "野性" then WR_DruidForeverFeral() end
    if spec == "守护" then WR_DruidForeverGuardian() end
    if spec == "恢复" then WR_RunHealerWithFleshPriority(WR_DruidForeverRestoration) end
end
