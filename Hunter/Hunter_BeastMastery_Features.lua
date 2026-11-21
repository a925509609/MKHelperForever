-- ============================================================
-- Hunter_BeastMastery_Features.lua
-- 兽王猎（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 HUNTER「野兽控制」专精：不写全局战斗状态、不影响射击/生存与其他职业。
--
-- 按「猪猪 / 彼岸花-无限服 · 兽王页」截图逐项落地：
--   功能：远程技能（右键：震荡/毒蛇/奥术/瞄准/多重/召唤雄鹰/狙击）
--         近战技能（右键：猫鼬撕咬/摔绊/猛禽一击）
--         宠物（右键：召唤/复活模式/脱战治疗）
--         印记（右键：只打首领）/ 切换目标
--   拉条：喝红药 30%
--   爆发：急速射击 / 狂野怒火 / 种族爆发（全开/全关/切换）
--   插入：献祭陷阱 / 冰冻陷阱 / 冰霜陷阱 / 震荡射击 / 扰乱射击 /
--         治疗宠物 / 急速射击 / 照明弹 / 乱射 / 胁迫 / 狂野怒火 /
--         爆炸陷阱 / 假死（一次性，放完自关）
--
-- 【本服真实技能（60级法术书）】
--   自动射击 75 / 毒蛇钉刺 1978 / 多重射击 2643 / 急速射击 3045 /
--   爆炸射击 6997 / 雄鹰守护 13165 / 瞄准射击 19434 / 狂野怒火 19574 /
--   蝰蛇守护 34074；猎人印记 / 奥术射击 / 震荡射击 / 猫鼬撕咬 /
--   猛禽一击 / 摔绊 / 治疗宠物 / 召唤宠物 / 复活宠物 / 假死 /
--   乱射 / 冰霜陷阱 / 冰冻陷阱 / 献祭陷阱 / 爆炸陷阱 / 照明弹 均为经典 60 级技能。
-- ★ 80级/外服技能（杀戮射击 / 杀戮命令 / 眼镜蛇射击 / 奇美拉射击 /
--   稳固射击 / 爆炸射击以外的读条填充等）本服不存在，本层不再引用。
-- ============================================================

if WR_PlayerClass ~= "HUNTER" then return end

WR_HunterBM = WR_HunterBM or {}
local HB = WR_HunterBM

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ------------------------------------------------------------
-- 规则：只补 nil，绝不覆盖用户已有设置。
-- 旧档：
--   LR_SWL_DCMZ（旧「瞄准or多重」1=多重/2=瞄准）→ 新「共享冷却」1=瞄准/2=多重
--   LR_SW_ZHBB（旧召唤宠物下拉 1~5=召唤/6=不召唤）→ LR_SWL_PET_SUMMON
--   LR_SW_FHCW_ZD（旧自动复活宠物）→ LR_SWL_PET_REVIVE_MODE（关=脱战复活）
--   LR_SWL_ZDLRYJ（旧自动猎人印记，只对BOSS）→ LR_SWL_MARK_ON / LR_SWL_MARK_BOSS_ONLY
-- ============================================================
HB.Defaults = {
    -- 功能总开关（截图默认勾选）
    LR_SWL_RANGED_ON = true,          -- 远程技能
    LR_SWL_MELEE_ON = true,           -- 近战技能
    LR_SWL_PET_ON = true,             -- 宠物
    LR_SWL_MARK_ON = true,            -- 印记
    LR_SWL_MARK_BOSS_ONLY = false,    -- 印记只打首领
    LR_SWL_TAB = true,                -- 切换目标
    LR_SWL_DCMZ = 1,                  -- 共享冷却：1=瞄准射击 / 2=多重射击

    -- 远程技能（右键小窗，逐项勾选）
    LR_SWL_RS_ZS = true,              -- 震荡射击
    LR_SWL_RS_DSDC = true,            -- 毒蛇钉刺
    LR_SWL_RS_DSDC_NO_MECH = true,    -- 毒蛇钉刺 不打机械
    LR_SWL_RS_DSDC_LEAD = 7,          -- 毒蛇钉刺 预判秒数
    LR_SWL_RS_ASSJ = true,            -- 奥术射击
    LR_SWL_RS_MZ = true,              -- 瞄准射击
    LR_SWL_RS_DC = true,              -- 多重射击
    LR_SWL_RS_ZLJY = true,            -- 召唤猎鹰（截图写作召唤雄鹰）
    LR_SWL_RS_JJ = true,              -- 狙击

    -- 近战技能（右键小窗，逐项勾选）
    LR_SWL_ML_MGSY = true,            -- 猫鼬撕咬
    LR_SWL_ML_ST = false,             -- 摔绊
    LR_SWL_ML_MQYJ = true,            -- 猛禽一击

    -- 宠物（右键小窗）
    LR_SWL_PET_SUMMON = true,         -- 召唤宠物
    LR_SWL_PET_REVIVE_MODE = 1,       -- 1=无脑复活 / 2=脱战复活
    LR_SWL_PET_HEAL = true,           -- 治疗宠物（脱战）
    LR_SWL_ZLCW = 50,                 -- 治疗宠物血量阈值（%）

    -- 爆发
    LR_SWL_ZDJSSJ = true,             -- 急速射击
    LR_SWL_JJSSJ_BOSS = false,        -- 急速射击只打首领
    LR_SWL_KYNH = true,               -- 狂野怒火
    LR_SWL_KYNH_BOSS = false,         -- 狂野怒火只打首领
    LR_SWL_ZDZZ = true,               -- 种族爆发

    -- 拉条
    LR_SWL_HXY = 30,                  -- 喝红药（%）

    -- 插入（一次性，放完自关）
    LR_SWL_CRXJ = false,              -- 献祭陷阱
    LR_SWL_CRBD = false,              -- 冰冻陷阱
    LR_SWL_CRBS = false,              -- 冰霜陷阱
    LR_SWL_CRZS = false,              -- 震荡射击
    LR_SWL_CRRL = false,              -- 扰乱射击
    LR_SWL_CRZL = false,              -- 治疗宠物
    LR_SWL_CRJSSJ = false,            -- 急速射击
    LR_SWL_CRZM = false,              -- 照明弹
    LR_SWL_CRLS = false,              -- 乱射
    LR_SWL_CRXP = false,              -- 胁迫
    LR_SWL_CRKY = false,              -- 狂野怒火
    LR_SWL_CRBZXJ = false,            -- 爆炸陷阱
    LR_SWL_CRJS = false,              -- 假死
}

HB.Migrated = HB.Migrated or false

function HB.Num(v, d)
    local n = tonumber(v)
    if type(n) == "number" then return n end
    return d
end

function HB.Bool(v, d)
    if v == true then return true end
    if v == false then return false end
    return d
end

function HB.On(var, default)
    if type(PigSet) ~= "table" then return default == true end
    return HB.Bool(PigSet[var], default == true)
end

function HB.Val(var, default)
    if type(PigSet) ~= "table" then return default end
    return HB.Num(PigSet[var], default)
end

function HB.InitDefaults()
    if type(PigSet) ~= "table" then return end

    -- 旧档迁移（先做，避免下面的默认值把新变量提前填死）
    if PigSet.LR_SWL_BM_MIGRATED ~= true then
        local oldDcmz = tonumber(PigSet.LR_SWL_DCMZ)
        if oldDcmz == 1 then
            PigSet.LR_SWL_DCMZ = 2          -- 旧 1=多重 → 新 2=多重
        elseif oldDcmz == 2 then
            PigSet.LR_SWL_DCMZ = 1          -- 旧 2=瞄准 → 新 1=瞄准
        else
            PigSet.LR_SWL_DCMZ = 1
        end

        local oldPet = tonumber(PigSet.LR_SW_ZHBB)
        if oldPet ~= nil then
            PigSet.LR_SWL_PET_SUMMON = (oldPet ~= 6)
        end
        if PigSet.LR_SW_FHCW_ZD == false then
            PigSet.LR_SWL_PET_REVIVE_MODE = 2
        end
        if PigSet.LR_SWL_CRBSXJ == true then
            PigSet.LR_SWL_CRBD = true          -- 旧「冰箱陷阱」→ 新「冰冻陷阱」
        end
        if PigSet.LR_SWL_ZDLRYJ == true then
            PigSet.LR_SWL_MARK_BOSS_ONLY = true
        elseif PigSet.LR_SWL_ZDLRYJ == false then
            PigSet.LR_SWL_MARK_ON = false
        end

        PigSet.LR_SWL_BM_MIGRATED = true
    end

    for k, v in pairs(HB.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
end

HB.InitDefaults()

-- ============================================================
-- 2. 安全读取小工具
-- ============================================================
function HB.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
    if type(WR_SyncFrameCheckboxes) == "function" and WR_ConfigFrame then
        pcall(WR_SyncFrameCheckboxes, WR_ConfigFrame, var)
    end
end

function HB.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, v = pcall(WR_Forever_IsSpellKnown, name)
        if ok and v == true then return true end
    end
    if type(WR_ResolveSpellID) == "function" then
        local ok, sid = pcall(WR_ResolveSpellID, name)
        if ok and sid ~= nil then return true end
    end
    return false
end

function HB.Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) ~= "function" then return false end
    return WR_ColorFrame_ShowSkill(spell, slot) == true
end

function HB.UnitHP(unit)
    if type(WR_GetUnitHP) ~= "function" then return nil end
    local ok, v = pcall(WR_GetUnitHP, unit)
    if ok and type(v) == "number" then return v end
    return nil
end

function HB.InCombat()
    if type(UnitAffectingCombat) ~= "function" then return false end
    local ok, v = pcall(UnitAffectingCombat, "player")
    return ok and v == true
end

function HB.PlayerMoving()
    if type(WR_PlayerMove) ~= "function" then return false end
    local ok, v = pcall(WR_PlayerMove)
    return ok and v == true
end

function HB.IsMountedOrVehicle()
    if type(IsMounted) == "function" then
        local ok, v = pcall(IsMounted)
        if ok and v == true then return true end
    end
    if type(UnitInVehicle) == "function" then
        local ok, v = pcall(UnitInVehicle, "player")
        if ok and v == true then return true end
    end
    return false
end

function HB.PetExists()
    if type(UnitExists) ~= "function" then return false end
    local ok, v = pcall(UnitExists, "pet")
    return ok and v == true
end

function HB.PetDead()
    if not HB.PetExists() then return false end
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, v = pcall(UnitIsDeadOrGhost, "pet")
        if ok then return v == true end
    end
    if type(UnitIsDead) == "function" then
        local ok, v = pcall(UnitIsDead, "pet")
        if ok then return v == true end
    end
    if HB.PetExists() then
        local hp = HB.UnitHP("pet")
        if hp and hp <= 0 then return true end
    end
    return false
end

function HB.PetAlive()
    return HB.PetExists() and not HB.PetDead()
end

function HB.TargetExistsAttackable()
    if type(UnitExists) ~= "function" then return false end
    local okEx, exists = pcall(UnitExists, "target")
    if not okEx or exists ~= true then return false end
    if type(UnitIsDeadOrGhost) == "function" then
        local okG, ghost = pcall(UnitIsDeadOrGhost, "target")
        if okG and ghost == true then return false end
    elseif type(UnitIsDead) == "function" then
        local okD, dead = pcall(UnitIsDead, "target")
        if okD and dead == true then return false end
    end
    if type(UnitCanAttack) == "function" then
        local okA, can = pcall(UnitCanAttack, "player", "target")
        if okA and can == false then return false end
    end
    return true
end

function HB.CreatureType()
    if type(WR_SafeCreatureType) == "function" then
        local ok, ct = pcall(WR_SafeCreatureType, "target")
        if ok and type(ct) == "string" then return ct end
    end
    if type(UnitCreatureType) == "function" then
        local ok, ct = pcall(UnitCreatureType, "target")
        if ok and type(ct) == "string" then return ct end
    end
    return nil
end

function HB.IsCreatureTypeExcluded(noElement, noMech, noUndead)
    local ct = HB.CreatureType()
    if not ct then return false end
    if noElement and (ct == "元素" or ct == "Elemental") then return true end
    if noMech and (ct == "机械" or ct == "Mechanical") then return true end
    if noUndead and (ct == "亡灵" or ct == "Undead") then return true end
    return false
end

function HB.TargetTTD()
    if type(WR_GetUnitDeathTime) ~= "function" then return 8888 end
    local ok, v = pcall(WR_GetUnitDeathTime, "target")
    if ok then return HB.Num(v, 8888) end
    return 8888
end

function HB.TTDEnough(lead)
    lead = HB.Num(lead, 0)
    if lead <= 0 then return true end
    local ttd = HB.TargetTTD()
    if ttd >= 900 then return true end
    return ttd >= lead
end

function HB.BuffRemain(unit, name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, unit, name)
    if ok then return HB.Num(v, 0) end
    return 0
end

function HB.DebuffRemain(name, byMe)
    if type(WR_GetUnitDebuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffTime, "target", name, byMe ~= false)
    if ok then return HB.Num(v, 0) end
    return 0
end

function HB.IsBossTarget()
    if type(UnitExists) ~= "function" then return false end
    for i = 1, 4 do
        local unit = "boss" .. i
        if UnitExists(unit) then
            if type(UnitIsUnit) == "function" then
                local ok, same = pcall(UnitIsUnit, "target", unit)
                if ok and same == true then return true end
            end
        end
    end
    if type(UnitClassification) == "function" then
        local ok, c = pcall(UnitClassification, "target")
        if ok and c == "worldboss" then return true end
    end
    return false
end

function HB.GetRacialBursts()
    local fn = WR_Forever_GetRacialBursts or WR_Forever_PlayerRacialBursts
    if type(fn) ~= "function" then return {} end
    local ok, list = pcall(fn)
    if ok and type(list) == "table" then return list end
    return {}
end

function HB.InCombatGate()
    if type(WR_HunterForever_InCombatGate) == "function" then
        return WR_HunterForever_InCombatGate("野兽控制") == true
    end
    return HB.InCombat()
end

-- ============================================================
-- 3. 宠物：召唤 / 复活 / 脱战治疗
-- ============================================================
function HB.PetStep()
    if not HB.On("LR_SWL_PET_ON", true) then return false end
    if HB.IsMountedOrVehicle() then return false end

    if HB.PetAlive() then
        -- 治疗宠物：截图口径「脱战宠物血量低于拉条才放」
        if HB.On("LR_SWL_PET_HEAL", true) and not HB.InCombat() and not HB.PlayerMoving() then
            local hp = HB.UnitHP("pet")
            local threshold = HB.Val("LR_SWL_ZLCW", 50)
            if hp and threshold > 0 and hp < threshold / 100 then
                if type(WR_SpellUsable) == "function" and WR_SpellUsable("治疗宠物", true) then
                    return HB.Show("治疗宠物", 31)
                end
            end
        end
        return false
    end

    if not HB.On("LR_SWL_PET_SUMMON", true) then return false end
    local mode = HB.Val("LR_SWL_PET_REVIVE_MODE", 1)
    local petDead = HB.PetDead()
    if petDead and HB.InCombat() and mode ~= 1 then return false end
    if HB.PlayerMoving() then return false end

    local spell = "召唤宠物"
    if petDead then spell = "复活宠物" end
    if type(WR_SpellUsable) == "function" and WR_SpellUsable(spell, true) then
        return HB.Show(spell, spell == "复活宠物" and 71 or 72)
    end
    return false
end

-- ============================================================
-- 4. 功能：印记 / 切换目标 / 喝红药
-- ============================================================
function HB.MarkStep()
    if not HB.On("LR_SWL_MARK_ON", true) then return false end
    if not HB.TargetExistsAttackable() then return false end
    if HB.On("LR_SWL_MARK_BOSS_ONLY", false) and not HB.IsBossTarget() then return false end
    if HB.DebuffRemain("猎人印记", false) > 0 then return false end
    if type(WR_SpellUsable) == "function" and WR_SpellUsable("猎人印记", true) then
        return HB.Show("猎人印记", 38)
    end
    return false
end

HB.LastTab = HB.LastTab or 0

function HB.TargetSwitchStep()
    if not HB.On("LR_SWL_TAB", true) then return false end
    if HB.TargetExistsAttackable() then return false end
    if not HB.InCombat() then return false end
    if type(WR_CanTab) == "function" then
        local ok, can = pcall(WR_CanTab)
        if ok and can == false then return false end
    end
    local now = GetTime()
    if now - (HB.LastTab or 0) < 1.0 then return false end
    if HB.Show("切换目标", 26) then
        HB.LastTab = now
        return true
    end
    return false
end

function HB.PotionStep()
    local threshold = HB.Val("LR_SWL_HXY", 30)
    if threshold <= 0 then return false end
    local hp = HB.UnitHP("player")
    if not hp or hp >= threshold / 100 then return false end
    if type(WR_Use_ZLYS) == "function" then
        local ok, can = pcall(WR_Use_ZLYS)
        if not ok or can ~= true then return false end
        return HB.Show("治疗药水", 105)
    end
    return false
end

-- ============================================================
-- 5. 爆发：狂野怒火 / 急速射击 / 种族爆发
-- ============================================================
function HB.BurstStep()
    if HB.On("LR_SWL_KYNH", true)
       and HB.PetAlive()
       and (not HB.On("LR_SWL_KYNH_BOSS", false) or HB.IsBossTarget())
       and HB.BuffRemain("player", "狂野怒火") == 0
       and HB.BuffRemain("pet", "狂野怒火") == 0
       and type(WR_SpellUsable) == "function"
       and WR_SpellUsable("狂野怒火", true) then
        return HB.Show("狂野怒火", 24)
    end

    if HB.On("LR_SWL_ZDJSSJ", true)
       and (not HB.On("LR_SWL_JJSSJ_BOSS", false) or HB.IsBossTarget())
       and HB.BuffRemain("player", "急速射击") == 0
       and type(WR_SpellUsable) == "function"
       and WR_SpellUsable("急速射击", true) then
        return HB.Show("急速射击", 22)
    end

    if HB.On("LR_SWL_ZDZZ", true) then
        -- ★★★ 2026-11-21 三十五次修复：统一走 WR_Forever_RacialBurstReady 补 CD 维
        if type(WR_Forever_RacialBurstReady) == "function" then
            local okR, hit = pcall(WR_Forever_RacialBurstReady)
            if okR and type(hit) == "string" then
                if HB.Show("种族爆发", 181) then
                    if type(WR_Forever_NoteBurstPrompt) == "function" then
                        pcall(WR_Forever_NoteBurstPrompt, hit,
                             (type(WR_Forever_RacialBurstCD) == "table"
                              and WR_Forever_RacialBurstCD[hit])
                             or WR_Forever_RACIAL_BURST_DEFAULT_CD or 180)
                    end
                    return true
                end
                return false
            end
            if type(WR_Forever_HideRacialBurst) == "function" then
                pcall(WR_Forever_HideRacialBurst, 181)
            end
            return false
        end
        local list = HB.GetRacialBursts()
        for i = 1, #list do
            local name = list[i]
            if type(name) == "string" and type(WR_SpellUsable) == "function"
               and WR_SpellUsable(name, true) then
                return HB.Show("种族爆发", 181)
            end
        end
    end
    return false
end

-- ============================================================
-- 6. 远程技能（按右键小窗勾选，逐项放）
-- ------------------------------------------------------------
-- 顺序：毒蛇钉刺 → 召唤猎鹰 → 奥术射击 → 瞄准/多重（共享冷却二选一优先）
--       → 狙击 → 震荡射击
-- 说明：召唤猎鹰与奥术射击共享冷却，猎鹰优先；瞄准射击与多重射击共享冷却，
--       由面板「共享冷却」下拉决定谁优先（1=瞄准 / 2=多重）。
-- ============================================================
function HB.RemoteStep(inRange)
    if not HB.On("LR_SWL_RANGED_ON", true) then return false end
    if not inRange then return false end
    -- 猎人 8 码内无法远程射击，交给近战段
    if type(TargetRange) == "number" and TargetRange <= 8 then return false end

    -- 1) 毒蛇钉刺：没有自己施加的钉刺才补；不打机械；预判秒数
    if HB.On("LR_SWL_RS_DSDC", true)
       and not (HB.On("LR_SWL_RS_DSDC_NO_MECH", true)
                and HB.IsCreatureTypeExcluded(false, true, false))
       and HB.DebuffRemain("毒蛇钉刺", true) == 0
       and HB.TTDEnough(HB.Val("LR_SWL_RS_DSDC_LEAD", 7))
       and type(WR_SpellUsable) == "function"
       and WR_SpellUsable("毒蛇钉刺", true) then
        return HB.Show("毒蛇钉刺", 6)
    end

    -- 2) 召唤猎鹰（截图写作召唤雄鹰）：与奥术射击共冷却；目标活不够久就不放
    if HB.On("LR_SWL_RS_ZLJY", true)
       and HB.SpellKnown("召唤猎鹰")
       and HB.TTDEnough(8)
       and type(WR_SpellUsable) == "function"
       and WR_SpellUsable("召唤猎鹰", true) then
        return HB.Show("召唤猎鹰", 92)
    end

    -- 3) 奥术射击：瞬发填充，与召唤猎鹰共冷却
    if HB.On("LR_SWL_RS_ASSJ", true)
       and type(WR_SpellUsable) == "function"
       and WR_SpellUsable("奥术射击", true) then
        return HB.Show("奥术射击", 17)
    end

    -- 4) 瞄准射击 / 多重射击：共享 6 秒冷却，按面板「共享冷却」决定优先
    local preferAimed = HB.Val("LR_SWL_DCMZ", 1) == 1
    local function tryAimed()
        if HB.On("LR_SWL_RS_MZ", true)
           and type(WR_SpellUsable) == "function"
           and WR_SpellUsable("瞄准射击", true) then
            return HB.Show("瞄准射击", 13)
        end
        return false
    end
    local function tryMulti(force)
        local count = tonumber(UnitCount8) or 0
        if HB.On("LR_SWL_RS_DC", true)
           and (force or count >= 2)
           and type(WR_SpellUsable) == "function"
           and WR_SpellUsable("多重射击", true) then
            return HB.Show("多重射击", 20)
        end
        return false
    end
    if preferAimed then
        if tryAimed() then return true end
        if tryMulti(false) then return true end
    else
        if tryMulti(true) then return true end
        if tryAimed() then return true end
    end

    -- 5) 狙击（射击系天赋，未学自动跳过）
    if HB.On("LR_SWL_RS_JJ", true)
       and HB.SpellKnown("狙击")
       and type(WR_SpellUsable) == "function"
       and WR_SpellUsable("狙击", true) then
        return HB.Show("狙击", 93)
    end

    -- 6) 震荡射击（最后补位）
    if HB.On("LR_SWL_RS_ZS", true)
       and type(WR_SpellUsable) == "function"
       and WR_SpellUsable("震荡射击", true) then
        return HB.Show("震荡射击", 52)
    end

    return false
end

-- ============================================================
-- 7. 近战技能（贴身 8 码内，按右键小窗勾选）
-- ============================================================
function HB.MeleeStep(inRange)
    if not HB.On("LR_SWL_MELEE_ON", true) then return false end
    if not inRange then return false end
    if type(TargetRange) ~= "number" or TargetRange > 8 or TargetRange >= 900 then return false end

    if HB.On("LR_SWL_ML_MGSY", true)
       and type(WR_SpellUsable) == "function"
       and WR_SpellUsable("猫鼬撕咬", true) then
        return HB.Show("猫鼬撕咬", 106)
    end
    if HB.On("LR_SWL_ML_ST", false)
       and type(WR_SpellUsable) == "function"
       and WR_SpellUsable("摔绊", true) then
        return HB.Show("摔绊", 79)
    end
    if HB.On("LR_SWL_ML_MQYJ", true)
       and type(WR_SpellUsable) == "function"
       and WR_SpellUsable("猛禽一击", true) then
        return HB.Show("猛禽一击", 107)
    end
    return false
end

-- ============================================================
-- 8. 插入（一次性：放完自动取消勾选）
-- ============================================================
function HB.InsertOnce(var, spell, slot)
    if not HB.On(var, false) then return false end
    if type(WR_SpellUsable) ~= "function" or not WR_SpellUsable(spell, true) then return false end
    if HB.Show(spell, slot) then
        PigSet[var] = false
        HB.SyncCheckbox(var)
        return true
    end
    return false
end

function HB.InsertStep()
    -- 保命类优先
    if HB.InsertOnce("LR_SWL_CRJS", "假死", 53) then return true end
    if HB.InsertOnce("LR_SWL_CRZL", "治疗宠物", 31) then return true end
    -- 陷阱类
    if HB.InsertOnce("LR_SWL_CRBD", "冰冻陷阱", 110) then return true end
    if HB.InsertOnce("LR_SWL_CRBS", "冰霜陷阱", 2) then return true end
    if HB.InsertOnce("LR_SWL_CRXJ", "献祭陷阱", 108) then return true end
    if HB.InsertOnce("LR_SWL_CRBZXJ", "爆炸陷阱", 111) then return true end
    -- 射击 / 控制类
    if HB.InsertOnce("LR_SWL_CRZS", "震荡射击", 52) then return true end
    if HB.InsertOnce("LR_SWL_CRRL", "扰乱射击", 51) then return true end
    if HB.InsertOnce("LR_SWL_CRZM", "照明弹", 109) then return true end
    if HB.InsertOnce("LR_SWL_CRLS", "乱射", 37) then return true end
    if HB.InsertOnce("LR_SWL_CRXP", "胁迫", 90) then return true end
    if HB.InsertOnce("LR_SWL_CRKY", "狂野怒火", 24) then return true end
    if HB.InsertOnce("LR_SWL_CRJSSJ", "急速射击", 22) then return true end
    return false
end

-- ============================================================
-- 9. 右键「额外条件」小窗
-- ============================================================
HB.PopupDefs = {
    LR_SWL_RANGED_ON = {
        title = "远程技能  功能",
        desc = "远程技能总开关：点图标展开右边一栏，这一页会自动放的远程技能（震荡射击、毒蛇钉刺、奥术射击、瞄准射击、多重射击、召唤雄鹰、狙击）一个一行，勾上的才放。\n\n柱顶的「远程技能」去掉勾 = 这些都不放，只留自动射击和近战技能，想留蓝或只想平射时关掉。\n\n猎人印记、急速射击和插入的技能不受影响。\n宏：/HUNTER_RANGED_BM 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "LR_SWL_RANGED_ON", label = "远程技能", default = true },
            { type = "check", var = "LR_SWL_RS_ZS", label = "震荡射击", default = true },
            { type = "check", var = "LR_SWL_RS_DSDC", label = "毒蛇钉刺", default = true },
            { type = "check", var = "LR_SWL_RS_DSDC_NO_MECH", label = "不打机械", default = true },
            { type = "slider", var = "LR_SWL_RS_DSDC_LEAD", label = "预判", min = 0, max = 30, step = 1, default = 7, suffix = "秒", hint = "0 = 都放" },
            { type = "check", var = "LR_SWL_RS_ASSJ", label = "奥术射击", default = true },
            { type = "check", var = "LR_SWL_RS_MZ", label = "瞄准射击", default = true },
            { type = "check", var = "LR_SWL_RS_DC", label = "多重射击", default = true },
            { type = "check", var = "LR_SWL_RS_ZLJY", label = "召唤雄鹰", default = true },
            { type = "check", var = "LR_SWL_RS_JJ", label = "狙击 -射击", default = true },
        },
    },
    LR_SWL_MELEE_ON = {
        title = "近战技能  功能",
        desc = "近战技能总开关：点图标展开右边一栏，这一页会自动放的近战技能（猫鼬撕咬、摔绊、猛禽一击）一个一行，勾上的才放。\n\n柱顶的「近战技能」去掉勾 = 这些都不放，贴身时只留近战平砍，想把蓝留给远程技能时关掉。\n宏：/HUNTER_MELEE 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "LR_SWL_MELEE_ON", label = "近战技能", default = true },
            { type = "check", var = "LR_SWL_ML_MGSY", label = "猫鼬撕咬", default = true },
            { type = "check", var = "LR_SWL_ML_ST", label = "摔绊", default = false },
            { type = "check", var = "LR_SWL_ML_MQYJ", label = "猛禽一击", default = true },
        },
    },
    LR_SWL_PET_ON = {
        title = "宠物  功能",
        desc = "宠物总开关：点图标展开右边一栏。\n\n召唤宠物：没有宠物就召唤；宠物死了就复活（下面选战斗中复活，还是脱战才复活）。\n\n治疗宠物：脱战宠物血量低于拉条就给它放治疗宠物。\n\n柱顶的「宠物」去掉勾 = 这些都不管。\n宏：/HUNTER_PET 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "LR_SWL_PET_ON", label = "宠物", default = true },
            { type = "check", var = "LR_SWL_PET_SUMMON", label = "召唤宠物", default = true },
            { type = "radio", var = "LR_SWL_PET_REVIVE_MODE", label = "宠物死了", options = { { "无脑复活", 1 }, { "脱战复活", 2 } }, default = 1 },
            { type = "check", var = "LR_SWL_PET_HEAL", label = "治疗宠物", default = true },
            { type = "slider", var = "LR_SWL_ZLCW", label = "血量", min = 0, max = 100, step = 5, default = 50, suffix = "%" },
        },
    },
    LR_SWL_MARK_ON = {
        title = "印记  功能",
        desc = "猎人印记总开关：目标身上没有猎人印记就自动补。\n\n右键「只打首领」勾上时，只给首领目标补印记，小怪不补。\n\n关掉后不再自动补印记。\n宏：/HUNTER_MARK 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "LR_SWL_MARK_ON", label = "印记", default = true },
            { type = "check", var = "LR_SWL_MARK_BOSS_ONLY", label = "只打首领", default = false },
        },
    },
    LR_SWL_ZDJSSJ = {
        title = "急速射击  功能",
        desc = "开着时，急速射击冷却好了、身上没有急速射击 buff 就自动放。\n\n右键「只打首领」勾上时，只对首领目标放。\n\n关掉后不再自动放急速射击。\n宏：/HUNTER_RAPID 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "LR_SWL_ZDJSSJ", label = "急速射击", default = true },
            { type = "check", var = "LR_SWL_JJSSJ_BOSS", label = "只打首领", default = false },
        },
    },
    LR_SWL_KYNH = {
        title = "狂野怒火  功能",
        desc = "开着时，宠物活着、狂野怒火冷却好了、身上没有狂野怒火 buff 就自动放（18 秒宠物伤害 +50%）。\n\n右键「只打首领」勾上时，只对首领目标放。\n\n关掉后不再自动放狂野怒火。\n宏：/HUNTER_BW 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "LR_SWL_KYNH", label = "狂野怒火", default = true },
            { type = "check", var = "LR_SWL_KYNH_BOSS", label = "只打首领", default = false },
        },
    },
}

local function MakeFont(parent, text, size, r, g, b, width)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size or 12, "")
    fs:SetTextColor(r or 0.92, g or 0.93, b or 0.95, 1)
    fs:SetText(text or "")
    if width then fs:SetWidth(width); fs:SetJustifyH("LEFT") end
    return fs
end

local function ApplyPopupBackdrop(f)
    if type(WR_UI_ApplyBackdrop) == "function" then
        WR_UI_ApplyBackdrop(f, "panel")
        return
    end
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        f:SetBackdropColor(0.05, 0.05, 0.07, 0.97)
        f:SetBackdropBorderColor(0.55, 0.42, 0.18, 0.95)
    end
end

local function BuildPopup(key)
    local def = HB.PopupDefs[key]
    if not def then return nil end
    local f = CreateFrame("Frame", "WR_HunterBMPopup_" .. key, UIParent, "BackdropTemplate")
    f:SetSize(330, 120)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    ApplyPopupBackdrop(f)

    local title = MakeFont(f, def.title or "额外条件", 14, 1, 0.82, 0.2)
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -9)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() f:Hide() end)

    local rows = {}
    local y = -34
    local contentWidth = 300
    local function addRow(h)
        y = y - h
    end

    if def.desc then
        local desc = MakeFont(f, def.desc, 11, 0.78, 0.78, 0.78, contentWidth)
        desc:SetPoint("TOPLEFT", f, "TOPLEFT", 12, y)
        desc:SetSpacing(2)
        local h = 40
        if desc.GetStringHeight then
            local ok, measured = pcall(desc.GetStringHeight, desc)
            if ok and type(measured) == "number" and measured > 0 then h = math.ceil(measured) + 6 end
        end
        addRow(h + 4)
    end

    for _, rowDef in ipairs(def.rows or {}) do
        if rowDef.type == "header" then
            local h = MakeFont(f, rowDef.text or "", 12, 1, 0.65, 0.2)
            h:SetPoint("TOPLEFT", f, "TOPLEFT", 12, y - 3)
            addRow(20)
        elseif rowDef.type == "check" then
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y)
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            cb:SetChecked(PigSet[rowDef.var] == true)
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95)
            label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            cb:SetScript("OnClick", function(self)
                PigSet[rowDef.var] = self:GetChecked() and true or false
            end)
            rows[#rows + 1] = { kind = "check", row = rowDef, control = cb }
            addRow(24)
        elseif rowDef.type == "slider" then
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95, 110)
            label:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y - 2)
            local slider = CreateFrame("Slider", nil, f)
            slider:SetOrientation("HORIZONTAL")
            slider:SetSize(110, 10)
            slider:SetPoint("LEFT", label, "RIGHT", 8, 0)
            slider:SetMinMaxValues(rowDef.min or 0, rowDef.max or 100)
            slider:SetValueStep(rowDef.step or 1)
            slider:SetObeyStepOnDrag(true)
            slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
            local thumb = slider:GetThumbTexture()
            if thumb then thumb:SetSize(6, 14); thumb:SetVertexColor(0.82, 0.84, 0.87, 1) end
            local track = slider:CreateTexture(nil, "BACKGROUND")
            track:SetTexture("Interface\\Buttons\\WHITE8x8")
            track:SetVertexColor(0.16, 0.18, 0.21, 1)
            track:SetAllPoints()
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            local val = HB.Num(PigSet[rowDef.var], rowDef.default or 0)
            if val < (rowDef.min or 0) then val = rowDef.min or 0 end
            if val > (rowDef.max or 100) then val = rowDef.max or 100 end
            slider:SetValue(val)
            local valText = MakeFont(f, tostring(val) .. (rowDef.suffix or ""), 12, 0.62, 0.65, 0.69, 52)
            valText:SetPoint("LEFT", slider, "RIGHT", 8, 0)
            local function update(v)
                v = math.floor((v or 0) + 0.5)
                PigSet[rowDef.var] = v
                valText:SetText(tostring(v) .. (rowDef.suffix or ""))
            end
            update(val)
            slider:SetScript("OnValueChanged", function(self, v) update(v) end)
            rows[#rows + 1] = { kind = "slider", row = rowDef, control = slider, valText = valText }
            addRow(30)
        elseif rowDef.type == "radio" then
            local label = MakeFont(f, rowDef.label or "", 12, 0.92, 0.93, 0.95, 64)
            label:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y - 3)
            local buttons = {}
            local startX = 72
            for i, opt in ipairs(rowDef.options or {}) do
                local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
                btn:SetSize(54, 20)
                btn:SetPoint("TOPLEFT", f, "TOPLEFT", startX + (i - 1) * 58, y)
                if btn.SetBackdrop then
                    btn:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 1,
                    })
                end
                if btn.SetBackdropColor then
                    btn:SetBackdropColor(0.12, 0.13, 0.15, 0.9)
                    btn:SetBackdropBorderColor(0.18, 0.20, 0.23, 1)
                end
                local txt = MakeFont(btn, opt[1], 11, 0.85, 0.85, 0.85)
                txt:SetPoint("CENTER", btn, "CENTER", 0, 0)
                btn:SetScript("OnClick", function()
                    PigSet[rowDef.var] = opt[2]
                    for _, b in ipairs(buttons) do
                        local on = (tonumber(PigSet[rowDef.var]) == b.value)
                        if b.btn.SetBackdropColor then
                            if on then b.btn:SetBackdropColor(0.35, 0.27, 0.10, 1)
                            else b.btn:SetBackdropColor(0.12, 0.13, 0.15, 0.9) end
                        end
                        b.txt:SetTextColor(on and 1 or 0.65, on and 0.82 or 0.65, on and 0.2 or 0.65)
                    end
                end)
                buttons[#buttons + 1] = { btn = btn, txt = txt, value = opt[2] }
            end
            rows[#rows + 1] = { kind = "radio", row = rowDef, buttons = buttons }
            addRow(27)
        end
    end

    local contentH = math.abs(y) + 12
    f:SetHeight(math.max(90, contentH + 18))
    f.rows = rows
    f.defKey = key

    function f:Refresh()
        for _, rec in ipairs(self.rows or {}) do
            if rec.kind == "check" then
                rec.control:SetChecked(PigSet[rec.row.var] == true)
            elseif rec.kind == "slider" then
                local v = HB.Num(PigSet[rec.row.var], rec.row.default or 0)
                rec.control:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            elseif rec.kind == "radio" then
                local cur = tonumber(PigSet[rec.row.var]) or rec.row.default or 1
                for _, b in ipairs(rec.buttons) do
                    local on = (cur == b.value)
                    if b.btn.SetBackdropColor then
                        if on then b.btn:SetBackdropColor(0.35, 0.27, 0.10, 1)
                        else b.btn:SetBackdropColor(0.12, 0.13, 0.15, 0.9) end
                    end
                    b.txt:SetTextColor(on and 1 or 0.65, on and 0.82 or 0.65, on and 0.2 or 0.65)
                end
            end
        end
    end

    return f
end

HB.PopupCache = HB.PopupCache or {}

function HB.ShowOptions(key)
    HB.InitDefaults()
    local def = HB.PopupDefs[key]
    if not def then return end
    local f = HB.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        HB.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(HB.PopupCache) do
        if other ~= f and other.Hide then other:Hide() end
    end
    f:Refresh()
    local x, y = 0, 0
    if type(GetCursorPosition) == "function" then
        local okX, cx, cy = pcall(GetCursorPosition)
        if okX and type(cx) == "number" and type(cy) == "number" then
            local scale = 1
            if UIParent and UIParent.GetEffectiveScale then
                local okS, s = pcall(UIParent.GetEffectiveScale, UIParent)
                if okS and type(s) == "number" and s > 0 then scale = s end
            end
            x, y = cx / scale, cy / scale
        end
    end
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + 12, y - 12)
    f:Show()
end

-- ============================================================
-- 10. 爆发按钮（全开 / 全关 / 切换）
-- ============================================================
function HB.SetBurst(on)
    if type(PigSet) ~= "table" then return end
    PigSet.LR_SWL_ZDJSSJ = on and true or false
    PigSet.LR_SWL_KYNH = on and true or false
    PigSet.LR_SWL_ZDZZ = on and true or false
    HB.SyncCheckbox("LR_SWL_ZDJSSJ")
    HB.SyncCheckbox("LR_SWL_KYNH")
    HB.SyncCheckbox("LR_SWL_ZDZZ")
end

function WR_HunterBMBurstAllOn()
    if WR_HunterBM then WR_HunterBM.SetBurst(true) end
end

function WR_HunterBMBurstAllOff()
    if WR_HunterBM then WR_HunterBM.SetBurst(false) end
end

function WR_HunterBMBurstToggle()
    if not WR_HunterBM then return end
    local any = (PigSet.LR_SWL_ZDJSSJ == true)
        or (PigSet.LR_SWL_KYNH == true)
        or (PigSet.LR_SWL_ZDZZ == true)
    WR_HunterBM.SetBurst(not any)
end

-- ============================================================
-- 11. 斜杠命令别名（对齐截图里的 /HUNTER_xxx）
-- ============================================================
local function SetVarByCommand(var, msg, label)
    msg = string.lower(msg or "")
    if msg == "on" then
        PigSet[var] = true
    elseif msg == "off" then
        PigSet[var] = false
    elseif msg == "" or msg == "toggle" then
        PigSet[var] = not PigSet[var]
    else
        return
    end
    HB.SyncCheckbox(var)
    local status = PigSet[var] and "|cff00ff00已开启|r" or "|cffff0000已关闭|r"
    local text = status .. " [" .. label .. "]"
    if type(WR_PrintToVisible) == "function" then
        WR_PrintToVisible(text)
    elseif type(print) == "function" then
        print(text)
    end
end

local function BindCommand(cmd, var, label)
    _G["SLASH_" .. cmd .. "1"] = "/" .. cmd
    SlashCmdList[cmd] = function(msg) SetVarByCommand(var, msg, label) end
end

BindCommand("HUNTER_RANGED_BM", "LR_SWL_RANGED_ON", "远程技能")
BindCommand("HUNTER_MELEE", "LR_SWL_MELEE_ON", "近战技能")
BindCommand("HUNTER_PET", "LR_SWL_PET_ON", "宠物")
BindCommand("HUNTER_MARK", "LR_SWL_MARK_ON", "印记")
BindCommand("HUNTER_RAPID", "LR_SWL_ZDJSSJ", "急速射击")
BindCommand("HUNTER_BW", "LR_SWL_KYNH", "狂野怒火")
