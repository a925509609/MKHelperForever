-- ============================================================
-- WR_BossMechanics.lua
-- 统一 BOSS 机制配置库（v2.0 - 法系/物理远程区分版）
-- 
-- 本文件定义所有 WotLK ICC/TOC BOSS 的机制和应对逻辑
-- 各职业的 BossSpecials 文件通过引用此配置来实现差异化处理
-- 
-- 架构设计：
--   1. BossMechanics[bossName] - 定义每个 BOSS 的机制
--   2. 每个机制包含：触发条件、适用角色、触发动作、颜色 ID
--   3. 角色类型（细化6种）：
--      - tank(坦克)
--      - melee_dps(近战DPS)
--      - ranged_caster_dps(法系远程DPS:法师/术士/暗牧/平衡德/元素萨)
--      - ranged_physical_dps(物理远程DPS:猎人)
--      - healer(治疗)
--   4. 各职业根据自身定位，选择适用的机制
--   5. 适用角色支持"同时适用多种角色"（通过applicableRoles多key配置）
-- ============================================================

local WR_BossMechanics = {}

-- ============================================================
-- ★ 角色类型定义（细化版）
-- ============================================================
local ROLE_TANK = "tank"
local ROLE_MELEE_DPS = "melee_dps"
local ROLE_RANGED_DPS = "ranged_dps"  -- 保留兼容旧代码
local ROLE_RANGED_CASTER_DPS = "ranged_caster_dps"  -- 法系远程DPS:法师/术士/暗牧/平衡德/元素萨
local ROLE_RANGED_PHYSICAL_DPS = "ranged_physical_dps"  -- 物理远程DPS:猎人
local ROLE_HEALER = "healer"

-- 导出角色常量供 BossSpecials 文件使用
WR_BossMechanics.ROLE_TANK = ROLE_TANK
WR_BossMechanics.ROLE_MELEE_DPS = ROLE_MELEE_DPS
WR_BossMechanics.ROLE_RANGED_DPS = ROLE_RANGED_DPS
WR_BossMechanics.ROLE_RANGED_CASTER_DPS = ROLE_RANGED_CASTER_DPS
WR_BossMechanics.ROLE_RANGED_PHYSICAL_DPS = ROLE_RANGED_PHYSICAL_DPS
WR_BossMechanics.ROLE_HEALER = ROLE_HEALER

-- 兼容函数：如果某机制适用 ranged_dps，同时检查 ranged_caster_dps 和 ranged_physical_dps
local function CheckRoleApplicable(mechanism, playerRole)
    if not mechanism or not mechanism.applicableRoles then
        return false
    end
    
    -- 直接匹配
    if mechanism.applicableRoles[playerRole] then
        return true
    end
    
    -- 兼容旧的 ROLE_RANGED_DPS：如果机制写了 ranged_dps，同时适用于两种远程DPS
    if mechanism.applicableRoles[ROLE_RANGED_DPS] then
        if playerRole == ROLE_RANGED_CASTER_DPS or playerRole == ROLE_RANGED_PHYSICAL_DPS then
            return true
        end
    end
    
    -- 反向兼容：如果某机制写了 ranged_caster_dps 或 ranged_physical_dps，检查玩家是 ranged_dps（旧代码）
    if playerRole == ROLE_RANGED_DPS then
        if mechanism.applicableRoles[ROLE_RANGED_CASTER_DPS] or 
           mechanism.applicableRoles[ROLE_RANGED_PHYSICAL_DPS] then
            return true
        end
    end
    
    return false
end

-- ============================================================
-- ★ 角色类型判断工具（精细化）
-- ============================================================

-- 判断玩家角色类型（区分法系/物理远程DPS）
function WR_GetPlayerRole()
    local class = UnitClassBase("player")
    local _, _, _, _, talentRank = GetTalentTabInfo(1)
    
    -- 根据职业和最高天赋判断
    if class == "WARRIOR" then
        local armsRank = select(5, GetTalentTabInfo(1))
        local furyRank = select(5, GetTalentTabInfo(2))
        local protRank = select(5, GetTalentTabInfo(3))
        if protRank > armsRank and protRank > furyRank then
            return ROLE_TANK
        elseif furyRank > armsRank then
            return ROLE_MELEE_DPS
        else
            return ROLE_MELEE_DPS  -- 武器战也是近战
        end
    elseif class == "DEATHKNIGHT" then
        local bloodRank = select(5, GetTalentTabInfo(1))
        local frostRank = select(5, GetTalentTabInfo(2))
        local unholyRank = select(5, GetTalentTabInfo(3))
        if bloodRank > frostRank and bloodRank > unholyRank then
            return ROLE_TANK
        else
            return ROLE_MELEE_DPS
        end
    elseif class == "PALADIN" then
        local holyRank = select(5, GetTalentTabInfo(1))
        local protRank = select(5, GetTalentTabInfo(2))
        local retRank = select(5, GetTalentTabInfo(3))
        if protRank > holyRank and protRank > retRank then
            return ROLE_TANK
        elseif holyRank > protRank and holyRank > retRank then
            return ROLE_HEALER
        else
            return ROLE_MELEE_DPS
        end
    elseif class == "DRUID" then
        local balanceRank = select(5, GetTalentTabInfo(1))
        local feralRank = select(5, GetTalentTabInfo(2))
        local restoRank = select(5, GetTalentTabInfo(3))
        if restoRank > balanceRank and restoRank > feralRank then
            return ROLE_HEALER
        elseif feralRank > balanceRank then
            -- 野性：如果是熊形态则是坦克，否则是猫DPS
            if WR_IsBearForm() then
                return ROLE_TANK
            else
                return ROLE_MELEE_DPS
            end
        else
            -- 平衡德 = 法系远程DPS
            return ROLE_RANGED_CASTER_DPS
        end
    elseif class == "SHAMAN" then
        local elementalRank = select(5, GetTalentTabInfo(1))
        local enhancementRank = select(5, GetTalentTabInfo(2))
        local restoRank = select(5, GetTalentTabInfo(3))
        if restoRank > elementalRank and restoRank > enhancementRank then
            return ROLE_HEALER
        elseif enhancementRank > elementalRank then
            return ROLE_MELEE_DPS
        else
            -- 元素萨 = 法系远程DPS
            return ROLE_RANGED_CASTER_DPS
        end
    elseif class == "PRIEST" then
        local discRank = select(5, GetTalentTabInfo(1))
        local holyRank = select(5, GetTalentTabInfo(2))
        local shadowRank = select(5, GetTalentTabInfo(3))
        if shadowRank > discRank and shadowRank > holyRank then
            -- 暗牧 = 法系远程DPS
            return ROLE_RANGED_CASTER_DPS
        else
            return ROLE_HEALER
        end
    elseif class == "MAGE" then
        return ROLE_RANGED_CASTER_DPS  -- 法师 = 法系远程DPS
    elseif class == "WARLOCK" then
        return ROLE_RANGED_CASTER_DPS  -- 术士 = 法系远程DPS
    elseif class == "ROGUE" then
        return ROLE_MELEE_DPS
    elseif class == "HUNTER" then
        return ROLE_RANGED_PHYSICAL_DPS  -- 猎人 = 物理远程DPS
    end
    
    return ROLE_MELEE_DPS  -- 默认近战
end

-- 判断是否为熊形态
function WR_IsBearForm()
    local form = GetShapeshiftForm()
    return form == 1  -- 熊形态
end

-- ============================================================
-- ★ 辅助工具函数
-- ============================================================

local function GetDebuffCount(unit, debuffName)
    return WR_GetUnitDebuffCount and WR_GetUnitDebuffCount(unit, debuffName) or 0
end

local function GetBuffCount(unit, buffName)
    return WR_GetUnitBuffCount and WR_GetUnitBuffCount(unit, buffName) or 0
end

local function GetPlayerHP()
    return WR_GetUnitHP and WR_GetUnitHP("player") or 100
end

-- ★ BOSS 机制配置（SoD 探索赛季版）
-- 按 熔火之心/黑深渊/祖尔格拉布/祖尔阿曼/黑翼之巢 组织；匹配与查询逻辑见下方 API
-- ============================================================
WR_BossMechanics = {
    ["鲁西弗隆"] = {
        ["Lucifron"] = true,
        id = 0,
        mechanisms = {
            {
                name = "鲁西弗隆的诅咒-驱散",
                checkFunction = function()
    if PigSet and PigSet.WQZ_LXFL_ZZ == false then return false end
    local c = GetDebuffCount("player", "鲁西弗隆的诅咒")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true },
                action = "dispel",
                colorID = 6,
                description = "鲁西弗隆的诅咒(魔法)-治疗驱散",
            },
            {
                name = "暗影魔王缴械",
                checkFunction = function()
    if PigSet and PigSet.WQZ_LXFL_JX == false then return false end
    local c = GetDebuffCount("player", "缴械")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true },
                action = "defensive",
                colorID = 8,
                description = "暗影魔王-近战被缴械-开自保",
            },
        },
    },
    ["玛格曼达"] = {
        ["Magmadar"] = true,
        id = 0,
        mechanisms = {
            {
                name = "恐慌-防恐",
                checkFunction = function()
    if PigSet and PigSet.WQZ_MGM_PK == false then return false end
    local c = GetDebuffCount("player", "恐慌")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "玛格曼达恐惧-防恐/坦克开狂暴",
            },
        },
    },
    ["基赫纳斯"] = {
        ["Gehennas"] = true,
        id = 0,
        mechanisms = {
            {
                name = "暗影箭雨-减命中",
                checkFunction = function()
    if PigSet and PigSet.WQZ_GHN_SY == false then return false end
    local c = GetDebuffCount("player", "暗影箭雨")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "基赫纳斯暗影箭雨-减命中-开暗抗",
            },
            {
                name = "火球-移动",
                checkFunction = function()
    if PigSet and PigSet.WQZ_GHN_HQ == false then return false end
    local c = GetDebuffCount("player", "灼烧")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true },
                action = "move",
                colorID = 3,
                description = "基赫纳斯火球-走位规避",
            },
        },
    },
    ["加尔"] = {
        ["Garr"] = true,
        id = 0,
        mechanisms = {
            {
                name = "火小鬼-冰暗集火",
                checkFunction = function()
    if PigSet and PigSet.WQZ_GE_HXG == false then return false end
    local c = GetBuffCount("target", "燃烧之盾")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_RANGED_CASTER_DPS] = true },
                action = "target",
                colorID = 4,
                description = "加尔火小鬼-法师/术士冰暗优先",
            },
            {
                name = "加尔-击退自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_GE_JT == false then return false end
    local c = GetDebuffCount("player", "击退")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true },
                action = "defensive",
                colorID = 8,
                description = "加尔击退-坦克自保",
            },
        },
    },
    ["迦顿男爵"] = {
        ["BaronGeddon"] = true,
        ["Baron Geddon"] = true,
        id = 0,
        mechanisms = {
            {
                name = "炸弹人-跑开",
                checkFunction = function()
    if PigSet and PigSet.WQZ_JD_BZR == false then return false end
    local c = GetDebuffCount("player", "生命流失")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "stop",
                colorID = 3,
                description = "迦顿炸弹人(生命流失)-立即跑开",
            },
            {
                name = "燃烧-散开",
                checkFunction = function()
    if PigSet and PigSet.WQZ_JD_RSZ == false then return false end
    local c = GetDebuffCount("player", "燃烧")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "迦顿燃烧-散开自保",
            },
            {
                name = "沉默-停手",
                checkFunction = function()
    if PigSet and PigSet.WQZ_JD_CM == false then return false end
    local c = GetDebuffCount("player", "沉默")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "迦顿沉默-法系停读条",
            },
        },
    },
    ["沙斯拉尔"] = {
        ["Sulfuron"] = true,
        ["SulfuronHarbinger"] = true,
        id = 0,
        mechanisms = {
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_SLSL_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "interrupt",
                colorID = 3,
                description = "沙斯拉尔治疗-打断",
            },
            {
                name = "火雨-移动",
                checkFunction = function()
    if PigSet and PigSet.WQZ_SLSL_HY == false then return false end
    local c = GetDebuffCount("player", "火焰之雨")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "move",
                colorID = 3,
                description = "沙斯拉尔火雨-走位",
            },
        },
    },
    ["戈勒玛格"] = {
        ["Golemagg"] = true,
        id = 0,
        mechanisms = {
            {
                name = "践踏-坦克自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_GLMG_JT == false then return false end
    local c = GetDebuffCount("player", "践踏")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true },
                action = "defensive",
                colorID = 8,
                description = "戈勒玛格践踏-坦克开盾墙",
            },
            {
                name = "火狗-冰霜集火",
                checkFunction = function()
    if PigSet and PigSet.WQZ_GLMG_HG == false then return false end
    local c = GetBuffCount("target", "燃烧之盾")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_RANGED_CASTER_DPS] = true },
                action = "target",
                colorID = 4,
                description = "戈勒玛格火狗-法师冰霜优先",
            },
        },
    },
    ["马格努斯"] = {
        ["Majordomo"] = true,
        ["MajordomoExecutus"] = true,
        id = 0,
        mechanisms = {
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_MGN_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "interrupt",
                colorID = 3,
                description = "马格努斯治疗-打断",
            },
            {
                name = "传送-集合",
                checkFunction = function()
    if PigSet and PigSet.WQZ_MGN_CS == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "target",
                colorID = 4,
                description = "马格努斯传送-被传送后集合",
            },
        },
    },
    ["拉格纳罗斯"] = {
        ["Ragnaros"] = true,
        id = 0,
        mechanisms = {
            {
                name = "击飞-换坦",
                checkFunction = function()
    if PigSet and PigSet.WQZ_LGN_JF == false then return false end
    local c = GetDebuffCount("player", "击飞")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true },
                action = "tank_swap",
                colorID = 8,
                description = "拉格纳罗斯击飞坦克-换坦",
            },
            {
                name = "子嗣-集火",
                checkFunction = function()
    if PigSet and PigSet.WQZ_LGN_ZS == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "target",
                colorID = 4,
                description = "拉格子嗣出现-8秒集火",
            },
            {
                name = "熔火飓风-移动",
                checkFunction = function()
    if PigSet and PigSet.WQZ_LGN_HF == false then return false end
    local c = GetDebuffCount("player", "熔火飓风")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "move",
                colorID = 3,
                description = "熔火飓风-走位规避",
            },
        },
    },
    ["阿奎尼斯男爵"] = {
        ["BaronAquanis"] = true,
        id = 0,
        mechanisms = {
            {
                name = "冰冻-定身自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_AQN_BD == false then return false end
    local c = GetDebuffCount("player", "冰冻")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "阿奎尼斯冰冻-定身开自由",
            },
            {
                name = "水箭-打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_AQN_SJ == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "阿奎尼斯水箭-打断",
            },
        },
    },
    ["加摩拉"] = {
        ["GhamooRa"] = true,
        ["Ghamoo-Ra"] = true,
        id = 0,
        mechanisms = {
            {
                name = "践踏-坦克自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_GML_JT == false then return false end
    local c = GetDebuffCount("player", "践踏")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true },
                action = "defensive",
                colorID = 8,
                description = "加摩拉践踏-坦克自保",
            },
            {
                name = "狂暴-换坦",
                checkFunction = function()
    if PigSet and PigSet.WQZ_GML_KB == false then return false end
    local c = GetBuffCount("target", "狂暴")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true },
                action = "tank_swap",
                colorID = 8,
                description = "加摩拉狂暴-换坦",
            },
        },
    },
    ["纳兹夏尔女士"] = {
        ["LadyNazjar"] = true,
        ["Nazjar"] = true,
        id = 0,
        mechanisms = {
            {
                name = "催眠-控制自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_NZX_SM == false then return false end
    local c = GetDebuffCount("player", "催眠")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "纳兹夏尔催眠-被控开自保",
            },
            {
                name = "海浪-移动",
                checkFunction = function()
    if PigSet and PigSet.WQZ_NZX_HL == false then return false end
    local c = GetDebuffCount("player", "海浪")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "move",
                colorID = 3,
                description = "纳兹夏尔海浪-走位",
            },
        },
    },
    ["格里雷克"] = {
        ["Gelihast"] = true,
        id = 0,
        mechanisms = {
            {
                name = "蛛网-定身",
                checkFunction = function()
    if PigSet and PigSet.WQZ_GLK_ZW == false then return false end
    local c = GetDebuffCount("player", "蛛网")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true },
                action = "defensive",
                colorID = 8,
                description = "格里雷克蛛网-近战定身自保",
            },
        },
    },
    ["洛古斯"] = {
        ["Lorgus"] = true,
        id = 0,
        mechanisms = {
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_LGS_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "interrupt",
                colorID = 3,
                description = "洛古斯治疗-打断",
            },
        },
    },
    ["暮光领主克尔里斯"] = {
        ["TwilightLordKelris"] = true,
        ["Kelris"] = true,
        id = 0,
        mechanisms = {
            {
                name = "精神控制-治疗自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_KLS_JK == false then return false end
    local c = GetDebuffCount("player", "精神控制")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "克尔里斯精神控制-被控治疗自保",
            },
            {
                name = "暗影箭-打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_KLS_SY == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "克尔里斯暗影箭-打断",
            },
        },
    },
    ["耶克里克"] = {
        ["Jeklik"] = true,
        ["HighPriestessJeklik"] = true,
        id = 0,
        mechanisms = {
            {
                name = "蝙蝠阶段-移动",
                checkFunction = function()
    if PigSet and PigSet.WQZ_YKL_SD == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "move",
                colorID = 3,
                description = "耶克里克蝙蝠阶段-走位",
            },
            {
                name = "蝙蝠治疗-打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_YKL_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "耶克里克蝙蝠治疗-打断",
            },
        },
    },
    ["温诺希斯"] = {
        ["Venoxis"] = true,
        ["HighPriestVenoxis"] = true,
        id = 0,
        mechanisms = {
            {
                name = "毒-驱散",
                checkFunction = function()
    if PigSet and PigSet.WQZ_WNHS_DU == false then return false end
    local c = GetDebuffCount("player", "毒")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true },
                action = "dispel",
                colorID = 6,
                description = "温诺希斯毒-治疗驱散",
            },
            {
                name = "变形-自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_WNHS_BX == false then return false end
    local c = GetDebuffCount("player", "变羊")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true },
                action = "defensive",
                colorID = 8,
                description = "温诺希斯蛇变形-近战自保",
            },
        },
    },
    ["玛尔里"] = {
        ["Marli"] = true,
        ["HighPriestessMarli"] = true,
        id = 0,
        mechanisms = {
            {
                name = "蛛网-定身",
                checkFunction = function()
    if PigSet and PigSet.WQZ_MEL_ZW == false then return false end
    local c = GetDebuffCount("player", "蛛网")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true },
                action = "defensive",
                colorID = 8,
                description = "玛尔里蜘蛛网-近战自保",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_MEL_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "玛尔里治疗-打断",
            },
        },
    },
    ["塞卡尔"] = {
        ["Thekal"] = true,
        ["HighPriestThekal"] = true,
        id = 0,
        mechanisms = {
            {
                name = "老虎-换坦",
                checkFunction = function()
    if PigSet and PigSet.WQZ_SKE_LH == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_TANK] = true },
                action = "tank_swap",
                colorID = 8,
                description = "塞卡尔老虎-换坦",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_SKE_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "塞卡尔治疗-打断",
            },
        },
    },
    ["阿鲁尔"] = {
        ["Arlokk"] = true,
        ["HighPriestessArlokk"] = true,
        id = 0,
        mechanisms = {
            {
                name = "消失-猎人标记",
                checkFunction = function()
    if PigSet and PigSet.WQZ_AEL_XS == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "target",
                colorID = 4,
                description = "阿鲁尔消失-猎人标记拉回",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_AEL_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "阿鲁尔治疗-打断",
            },
        },
    },
    ["曼多基尔"] = {
        ["Mandokir"] = true,
        ["BloodlordMandokir"] = true,
        id = 0,
        mechanisms = {
            {
                name = "凝视-停止",
                checkFunction = function()
    if PigSet and PigSet.WQZ_MDKK_ZS == false then return false end
    local c = GetDebuffCount("player", "曼多基尔的凝视")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "stop",
                colorID = 3,
                description = "曼多基尔凝视-立刻停手",
            },
            {
                name = "战复-打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_MDKK_ZF == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "interrupt",
                colorID = 3,
                description = "曼多基尔战复-打断",
            },
        },
    },
    ["金度"] = {
        ["Jindo"] = true,
        ["JinDo"] = true,
        id = 0,
        mechanisms = {
            {
                name = "妖术-变蛙自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_JD_YS == false then return false end
    local c = GetDebuffCount("player", "妖术")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "金度妖术-变蛙开自保",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_JD_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "金度治疗-打断",
            },
        },
    },
    ["哈卡"] = {
        ["Hakkar"] = true,
        id = 0,
        mechanisms = {
            {
                name = "吸血-减治疗自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_HK_XX == false then return false end
    local c = GetDebuffCount("player", "哈卡的吸血")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "哈卡吸血-治疗减疗自保",
            },
            {
                name = "意识控制-自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_HK_YS == false then return false end
    local c = GetDebuffCount("player", "意识控制")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "哈卡意识控制-被控自保",
            },
        },
    },
    ["加兹兰卡"] = {
        ["Gazranka"] = true,
        ["Gahzranka"] = true,
        id = 0,
        mechanisms = {
            {
                name = "喷吐-移动",
                checkFunction = function()
    if PigSet and PigSet.WQZ_GZL_PT == false then return false end
    local c = GetDebuffCount("player", "喷吐")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "move",
                colorID = 3,
                description = "加兹兰卡喷吐-走位",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_GZL_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "加兹兰卡治疗-打断",
            },
        },
    },
    ["纳洛拉克"] = {
        ["Nalorakk"] = true,
        id = 0,
        mechanisms = {
            {
                name = "熊阶段-换坦",
                checkFunction = function()
    if PigSet and PigSet.WQZ_NLR_X == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_TANK] = true },
                action = "tank_swap",
                colorID = 8,
                description = "纳洛拉克熊形态-换坦",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_NLR_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "纳洛拉克治疗-打断",
            },
        },
    },
    ["阿奎尔宗"] = {
        ["Akilzon"] = true,
        ["Akil'zon"] = true,
        id = 0,
        mechanisms = {
            {
                name = "电击-天上自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_AKE_JD == false then return false end
    local c = GetDebuffCount("player", "电击")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "阿奎尔宗电击-天上开自保",
            },
        },
    },
    ["哈拉萨"] = {
        ["Halazzi"] = true,
        id = 0,
        mechanisms = {
            {
                name = "妖魂-集火",
                checkFunction = function()
    if PigSet and PigSet.WQZ_HLS_YH == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "target",
                colorID = 4,
                description = "哈拉萨妖魂-集火",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_HLS_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "哈拉萨治疗-打断",
            },
        },
    },
    ["贾纳莱"] = {
        ["Janalai"] = true,
        ["Jan'alai"] = true,
        id = 0,
        mechanisms = {
            {
                name = "火焰-散开",
                checkFunction = function()
    if PigSet and PigSet.WQZ_JNL_HY == false then return false end
    local c = GetDebuffCount("player", "火焰")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "move",
                colorID = 3,
                description = "贾纳莱火-散开走位",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_JNL_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "贾纳莱治疗-打断",
            },
        },
    },
    ["达卡拉"] = {
        ["Daakara"] = true,
        id = 0,
        mechanisms = {
            {
                name = "狂暴-换坦",
                checkFunction = function()
    if PigSet and PigSet.WQZ_DKL_KB == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_TANK] = true },
                action = "tank_swap",
                colorID = 8,
                description = "达卡拉狂暴-换坦",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_DKL_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "达卡拉治疗-打断",
            },
        },
    },
    ["拉佐格尔"] = {
        ["Razorgore"] = true,
        ["TheUntamed"] = true,
        id = 0,
        mechanisms = {
            {
                name = "龙人-德鲁伊休眠/猎人凝神",
                checkFunction = function()
    if PigSet and PigSet.WQZ_LZG_LR == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_RANGED_CASTER_DPS] = true, [ROLE_HEALER] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "target",
                colorID = 4,
                description = "拉佐格尔龙人-德鲁伊休眠/猎人凝神",
            },
            {
                name = "砸蛋-集火",
                checkFunction = function()
    if PigSet and PigSet.WQZ_LZG_D == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "target",
                colorID = 4,
                description = "拉佐格尔优先砸蛋",
            },
        },
    },
    ["瓦拉斯塔兹"] = {
        ["Vaelastrasz"] = true,
        ["VaelastrasztheCorrupt"] = true,
        id = 0,
        mechanisms = {
            {
                name = "燃烧-计时爆发",
                checkFunction = function()
    if PigSet and PigSet.WQZ_WLS_RSZ == false then return false end
    local c = GetDebuffCount("player", "燃烧")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "瓦拉斯塔兹燃烧-计时自保",
            },
            {
                name = "换坦",
                checkFunction = function()
    if PigSet and PigSet.WQZ_WLS_HT == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_TANK] = true },
                action = "tank_swap",
                colorID = 8,
                description = "瓦拉斯塔兹换坦",
            },
        },
    },
    ["勒什雷尔"] = {
        ["Lashlayer"] = true,
        ["BroodlordLashlayer"] = true,
        id = 0,
        mechanisms = {
            {
                name = "顺劈-坦克自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_LSL_SP == false then return false end
    local c = GetDebuffCount("player", "顺劈斩")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true },
                action = "defensive",
                colorID = 8,
                description = "勒什雷尔顺劈-坦克开盾墙",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_LSL_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "勒什雷尔治疗-打断",
            },
        },
    },
    ["费尔默"] = {
        ["Firemaw"] = true,
        id = 0,
        mechanisms = {
            {
                name = "火焰-移动自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_FM_HY == false then return false end
    local c = GetDebuffCount("player", "燃烧")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "move",
                colorID = 3,
                description = "费尔默火焰-走位",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_FM_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "费尔默治疗-打断",
            },
        },
    },
    ["克洛玛古斯"] = {
        ["Chromaggus"] = true,
        id = 0,
        mechanisms = {
            {
                name = "5debuff-中断/火伤自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_KLMG_5DB == false then return false end
    local c = GetDebuffCount("player", "时间流逝")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "defensive",
                colorID = 8,
                description = "克洛玛古斯五重debuff-开自保",
            },
            {
                name = "治疗打断",
                checkFunction = function()
    if PigSet and PigSet.WQZ_KLMG_ZL == false then return false end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name and notInterruptible == false then return true end
    return false
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true },
                action = "interrupt",
                colorID = 3,
                description = "克洛玛古斯治疗-打断",
            },
        },
    },
    ["奈法利安"] = {
        ["Nefarian"] = true,
        id = 0,
        mechanisms = {
            {
                name = "职业召唤-战士狂暴",
                checkFunction = function()
    if PigSet and PigSet.WQZ_NFL_ZS_WAR == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_MELEE_DPS] = true },
                applicableClasses = { ["WARRIOR"] = true },
                action = "defensive",
                colorID = 8,
                description = "奈法利安职业召唤-战士强制狂暴开自保",
            },
            {
                name = "职业召唤-猎人摘武器",
                checkFunction = function()
    if PigSet and PigSet.WQZ_NFL_ZS_HUN == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_RANGED_PHYSICAL_DPS] = true },
                applicableClasses = { ["HUNTER"] = true },
                action = "stop",
                colorID = 3,
                description = "奈法利安职业召唤-猎人摘武器防爆破碎",
            },
            {
                name = "职业召唤-圣骑强刷保护",
                checkFunction = function()
    if PigSet and PigSet.WQZ_NFL_ZS_PAL == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_HEALER] = true, [ROLE_TANK] = true },
                applicableClasses = { ["PALADIN"] = true },
                action = "defensive",
                colorID = 8,
                description = "奈法利安职业召唤-圣骑强刷保护",
            },
            {
                name = "职业召唤-牧师Renew盾",
                checkFunction = function()
    if PigSet and PigSet.WQZ_NFL_ZS_PRI == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_HEALER] = true },
                applicableClasses = { ["PRIEST"] = true },
                action = "defensive",
                colorID = 8,
                description = "奈法利安职业召唤-牧师Renew+盾防腐蚀",
            },
            {
                name = "职业召唤-术士放逐地狱火",
                checkFunction = function()
    if PigSet and PigSet.WQZ_NFL_ZS_WARL == false then return false end
    return true
                end,
                applicableRoles = { [ROLE_RANGED_CASTER_DPS] = true },
                applicableClasses = { ["WARLOCK"] = true },
                action = "target",
                colorID = 4,
                description = "奈法利安职业召唤-术士放逐地狱火",
            },
            {
                name = "龙骨-P2火自保",
                checkFunction = function()
    if PigSet and PigSet.WQZ_NFL_LG == false then return false end
    local c = GetDebuffCount("player", "龙骨")
    if c and c >= 1 then return true end
    return false
                end,
                applicableRoles = { [ROLE_TANK] = true, [ROLE_MELEE_DPS] = true, [ROLE_RANGED_CASTER_DPS] = true, [ROLE_RANGED_PHYSICAL_DPS] = true, [ROLE_HEALER] = true },
                action = "move",
                colorID = 3,
                description = "奈法利安P2龙骨-走位",
            },
        },
    },
}
-- ============================================================
-- ★ BOSS 机制查询 API
-- ============================================================

-- 获取指定 BOSS 的所有机制
function WR_GetBossMechanics(bossName)
    if not bossName then return nil end
    
    -- 直接匹配
    if WR_BossMechanics[bossName] then
        return WR_BossMechanics[bossName]
    end
    
    -- 遍历查找别名匹配
    for bossKey, bossData in pairs(WR_BossMechanics) do
        if type(bossData) == "table" and bossData[bossName] then
            return bossData
        end
    end
    
    return nil
end

-- 查找当前目标对应的 BOSS 机制
function WR_FindCurrentBossMechanics()
    local targetName = UnitName("target")
    if not targetName then return nil end
    
    -- 直接匹配
    if WR_BossMechanics[targetName] then
        return WR_BossMechanics[targetName]
    end
    
    -- 查找所有别名
    for bossKey, bossData in pairs(WR_BossMechanics) do
        if bossData[targetName] then
            return bossData
        end
    end
    
    return nil
end

-- 检查当前 BOSS 机制是否触发（仅检查指定角色类型适用的机制）
function WR_CheckBossMechanicsForRole(playerRole)
    local bossData = WR_FindCurrentBossMechanics()
    if not bossData or not bossData.mechanisms then
        return nil  -- 没有 BOSS 机制触发
    end
    
    for _, mechanism in ipairs(bossData.mechanisms) do
        -- 检查该机制是否适用于当前角色（使用精细化角色检查）
        if CheckRoleApplicable(mechanism, playerRole) then
            -- 执行检查函数
            if mechanism.checkFunction and mechanism.checkFunction() then
                return mechanism  -- 返回触发的机制
            end
        end
    end
    
    return nil  -- 没有机制触发
end

-- 简化版：检查 BOSS 机制（按当前角色+职业过滤，与 WR_CheckBossMechanicsForRole 行为一致）
--   - applicableClasses 存在时：仅对白名单职业生效（奈法利安职业召唤等职业专属机制）
--   - 否则按 applicableRoles 精细化角色过滤（无 applicableRoles 视为全角色）
function WR_CheckBossMechanics()
    local bossData = WR_FindCurrentBossMechanics()
    if not bossData or not bossData.mechanisms then
        return nil
    end
    local role = WR_GetPlayerRole and WR_GetPlayerRole() or ROLE_MELEE_DPS
    local class = UnitClassBase and UnitClassBase("player")
    for _, mechanism in ipairs(bossData.mechanisms) do
        if mechanism.checkFunction and mechanism.checkFunction() then
            -- 职业专属优先判定
            if mechanism.applicableClasses then
                if class and mechanism.applicableClasses[class] then
                    return mechanism
                end
                -- 有职业限制但不匹配当前职业 -> 跳过（不回落到角色过滤）
            elseif (not mechanism.applicableRoles) or CheckRoleApplicable(mechanism, role) then
                return mechanism
            end
        end
    end
    return nil
end

-- ============================================================
-- ★ 共享工具库（供各职业 BossSpecials 文件使用）
-- 避免每个文件重复定义相同的辅助函数
-- ============================================================
local WR_BossUtils = {}

-- 通用 Debuff/Buff 计数
function WR_BossUtils.GetDebuffCount(unit, debuffName)
    return WR_GetUnitDebuffCount and WR_GetUnitDebuffCount(unit, debuffName) or 0
end

function WR_BossUtils.GetBuffCount(unit, buffName)
    return WR_GetUnitBuffCount and WR_GetUnitBuffCount(unit, buffName) or 0
end

-- 通用 Buff/Debuff 存在性检查
function WR_BossUtils.HasBuff(unit, buffName)
    if WR_GetUnitBuffTime then
        local t = WR_GetUnitBuffTime(unit, buffName)
        return t and t > 0
    end
    return false
end

function WR_BossUtils.HasDebuff(unit, debuffName)
    if WR_GetUnitDebuffTime then
        local t = WR_GetUnitDebuffTime(unit, debuffName)
        return t and t > 0
    end
    return false
end

-- 通用血量获取
function WR_BossUtils.GetPlayerHP()
    return WR_GetUnitHP and WR_GetUnitHP("player") or 100
end

-- 统一颜色映射表（动作名 → 颜色ID）
WR_BossUtils.ColorMap = {
    stop             = 3,
    target           = 4,
    defensive        = 8,
    rocketboots      = 108,
    lk_contamination = 107,
}

-- 统一颜色显示函数
function WR_BossUtils.ShowColor(action, description)
    local colorID = WR_BossUtils.ColorMap[action] or 1
    if WR_ColorFrame_Show then
        WR_ColorFrame_Show(colorID, description or action)
    end
    return colorID
end

-- 通用 BOSS 数据查找（根据当前目标名匹配 WR_BossMechanics）
function WR_BossUtils.FindBossData(targetName)
    if not targetName or not WR_BossMechanics then
        return nil
    end
    if WR_BossMechanics[targetName] then
        return WR_BossMechanics[targetName]
    end
    for _, data in pairs(WR_BossMechanics) do
        if type(data) == "table" and data[targetName] then
            return data
        end
    end
    return nil
end

-- 按角色类型检查 BOSS 机制（简化版，直接返回触发的机制）
function WR_BossUtils.CheckMechanismsForRole(role)
    local bossData = WR_FindCurrentBossMechanics and WR_FindCurrentBossMechanics()
    if not bossData or not bossData.mechanisms then
        return nil
    end
    for _, mech in ipairs(bossData.mechanisms) do
        if WR_CheckRoleApplicable and WR_CheckRoleApplicable(mech, role) then
            if mech.checkFunction and mech.checkFunction() then
                return mech
            end
        end
    end
    return nil
end

-- 导出
_G.WR_BossUtils = WR_BossUtils

-- 导出角色检查函数（供职业文件使用）
_G.WR_CheckRoleApplicable = CheckRoleApplicable

-- 导出
_G.WR_BossMechanics = WR_BossMechanics
_G.WR_GetPlayerRole = WR_GetPlayerRole
_G.WR_GetBossMechanics = WR_GetBossMechanics
_G.WR_FindCurrentBossMechanics = WR_FindCurrentBossMechanics
_G.WR_CheckBossMechanicsForRole = WR_CheckBossMechanicsForRole
_G.WR_CheckBossMechanics = WR_CheckBossMechanics


