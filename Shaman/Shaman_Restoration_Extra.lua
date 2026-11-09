-- ============================================================
-- Shaman_Restoration_Extra.lua
-- 功能：对恢复萨满的图腾管理和爆发功能进行条件增强
--       仅在副本BOSS战斗或团队战斗中触发
-- ============================================================

if WR_PlayerClass ~= "SHAMAN" then return end

local _WR_ShamanRestoration_BF = WR_ShamanRestoration_BF
local _WR_ShamanRestoration_TT = WR_ShamanRestoration_TT

-- ============================================================
-- ★ 判断是否应该管理图腾（仅在BOSS战或团队战斗中）
-- ============================================================
local function WR_ShamanRestoration_ShouldManageTotems()
    if not UnitAffectingCombat("player") then
        return false
    end
    if IsEncounterInProgress() or WR_InBossCombat() then
        return true
    end
    if IsInInstance() and WR_PartyInCombat() then
        return true
    end
    return false
end

-- ============================================================
-- ★ 覆盖图腾管理函数（增加条件判断）
-- ============================================================
function WR_ShamanRestoration_TT()
    if not PigSet.HF_TT then return false end
    if not WR_ShamanRestoration_ShouldManageTotems() then return false end
    if PlayerMove then return false end
    return _WR_ShamanRestoration_TT()
end

-- ============================================================
-- ★ 覆盖爆发函数（增加条件判断 + 偷药开关）
-- ============================================================
function WR_ShamanRestoration_BF()
    if not PigSet.HF_BF then return false end
    if not UnitAffectingCombat("player") then return false end
    if not IsEncounterInProgress() and not WR_InBossCombat() then return false end
    if PlayerMove then return false end

    -- ★ 手套（工程+400点检测）
    if WR_CanUseGloves() then
        if WR_ColorFrame_ShowSkill("手套", 180) then return true end
    end

    -- ★ 速度药水（受偷药开关控制）
    if PigSet.SM_HF_TOUYAO and
       (WR_ShamanRestoration_UseTime_JSYS == nil or GetTime() - WR_ShamanRestoration_UseTime_JSYS > 60) and
       (WR_ShamanRestoration_ErrorMessageTime_NotUse == nil or GetTime() - WR_ShamanRestoration_ErrorMessageTime_NotUse > 10) and
       WR_GetItemInfo(40211) then
        if WR_ColorFrame_ShowSkill("速度药水", 183) then return true end
    end

    -- 饰品
    if WR_GetEquipCD(13) or WR_GetEquipCD(14) then
        if WR_ColorFrame_ShowSkill("饰品", 14) then return true end
    end

    -- 潮汐之力
    if WR_SpellUsable("潮汐之力") then
        if WR_ColorFrame_ShowSkill("潮汐之力", 72) then return true end
    end

    return false
end