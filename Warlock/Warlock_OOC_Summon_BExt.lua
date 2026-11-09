-- ============================================================
-- Warlock_OOC_Summon_BExt.lua
-- 来源：ZZHELPER B 的 Warlock-HOT.lua「脱战自动召唤宠物系统」
-- 适配：剥离 B 引擎（ZZ_Shared_RuntimeCore_O / ZZ_ColorFrame_Show(数值键)），
--       改用 A 框架原语 WR_SpellUsable / WR_ColorFrame_Show；
--       生物ID / 家族精确匹配逻辑原样保留。
-- 命名规范：WR_*_BExt
-- 说明：
--   1) 支持五种宠物：小鬼、虚空行者、魅魔、地狱猎犬、恶魔卫士
--   2) 通过宠物家族 / 生物ID 精确匹配，避免重复召唤
--   3) 战斗中、读条中、骑乘状态下不触发
--   4) 召唤后 8 秒内不重复尝试（防止卡 GCD）
--   5) 本函数只负责脱战召唤，不涉及目标黑名单（目标过滤由 WR_IsBlacklisted / IsMonsterBlocked 统一处理）
-- ============================================================

-- ★ 宠物配置表（下拉选项值 2~6 对应；1 = 关闭）
--   spell:       召唤法术名称
--   button:      A 侧色块 / 宏按钮编号（对应 Warlock_Macros.lua 的 WR_CreateMacro）
--   family:      宠物家族名称（UnitCreatureFamily 匹配）
--   creatureIds: 宠物生物ID列表（从 GUID 解析精确匹配）
if WR_PlayerClass ~= "WARLOCK" then return end

local WR_WarlockAutoPetOptions_BExt = {
    [2] = { spell = "召唤小鬼",     button = 195, family = "小鬼",     creatureIds = { [416]   = true } },
    [3] = { spell = "召唤虚空行者", button = 197, family = "虚空行者", creatureIds = { [1860]  = true } },
    [4] = { spell = "召唤魅魔",     button = 196, family = "魅魔",     creatureIds = { [1863]  = true } },
    [5] = { spell = "召唤地狱猎犬", button = 198, family = "地狱猎犬", creatureIds = { [417]   = true } },
    [6] = { spell = "召唤恶魔卫士", button = 33,  family = "恶魔卫士", creatureIds = { [17252] = true } },
}

-- ★ 召唤冷却计时器（防止重复召唤，单位：秒）
local WR_WarlockAutoPetNextSummonTime_BExt = 0

-- ============================================================
-- 函数：WR_WarlockPetCreatureId_BExt()
-- 功能：从宠物 GUID 中解析生物ID
-- 返回：number / nil
-- ============================================================
local function WR_WarlockPetCreatureId_BExt()
    local guid = UnitGUID("pet")
    if not guid then
        return nil
    end
    -- 标准 GUID：匹配倒数第二个数字段（生物ID）
    local creatureId = tonumber(guid:match("^[^%-]+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
    if creatureId then
        return creatureId
    end
    -- 备用：提取最后一段数字
    return tonumber(guid:match("%-(%d+)%-%x+$"))
end

-- ============================================================
-- 函数：WR_WarlockPetMatches_BExt(option)
-- 功能：当前宠物是否匹配目标宠物类型
-- 返回：boolean
-- ============================================================
local function WR_WarlockPetMatches_BExt(option)
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then
        return false
    end

    -- 优先用家族匹配（不受生物ID变化影响）
    local family = UnitCreatureFamily and UnitCreatureFamily("pet")
    if family and family ~= "恶魔" then
        return family == option.family
    end

    -- 备选：生物ID 精确匹配
    local creatureId = WR_WarlockPetCreatureId_BExt()
    if creatureId and option.creatureIds then
        return option.creatureIds[creatureId] == true
    end

    -- 兜底：认为匹配（避免无限循环），与 B 原始逻辑一致
    return true
end

-- ============================================================
-- 函数：WR_WarlockAutoSummonPet_BExt(selectedPet)
-- 功能：脱战状态下自动召唤指定宠物（由术士三系主循环调用）
-- 参数：selectedPet (number)
--           1 = 关闭自动召唤
--           2 = 小鬼
--           3 = 虚空行者
--           4 = 魅魔
--           5 = 地狱猎犬
--           6 = 恶魔卫士
-- 返回：boolean —— 已触发召唤（色块显示）返回 true，否则 false
-- ============================================================
function WR_WarlockAutoSummonPet_BExt(selectedPet)
    local option = WR_WarlockAutoPetOptions_BExt[tonumber(selectedPet or 1)]
    if not option then
        return false  -- 关闭或未配置
    end

    -- ★ 安全条件：不进战斗、不读条、不骑乘、未死亡
    if UnitAffectingCombat("player")
       or UnitIsDeadOrGhost("player")
       or UnitCastingInfo("player")
       or UnitChannelInfo("player")
       or (IsMounted and IsMounted()) then
        return false
    end

    -- ★ 冷却：8 秒间隔，防止频繁尝试（卡 GCD）
    local now = GetTime and GetTime() or 0
    if now < WR_WarlockAutoPetNextSummonTime_BExt then
        return false
    end

    -- ★ 当前宠物已匹配目标类型 → 不重复召唤，重置冷却
    if WR_WarlockPetMatches_BExt(option) then
        WR_WarlockAutoPetNextSummonTime_BExt = 0
        return false
    end

    -- ★ 召唤法术可用 → 触发色块（由玩家按对应宏键执行召唤）
    if WR_SpellUsable(option.spell, true) then
        if WR_ColorFrame_Show(option.button, option.spell) then
            WR_WarlockAutoPetNextSummonTime_BExt = now + 8
            return true
        end
    end

    return false
end
