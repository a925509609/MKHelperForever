-- ============================================================
-- Priest Forever · Discipline 专精循环（无限 1.60.x）
-- ------------------------------------------------------------
-- 【治疗模型：焦点目标加血】与时光服老版 Priest_Discipline.lua 相同
--   本职业所有治疗宏都是 [@focus] 形态（Priest_Macros.lua：
--   53 治疗祷言 / 54 苦修 / 55 恢复 / 56 联结治疗 / 57 快速治疗 /
--   58 愈合祷言 / 59 真言术：盾 / 64 痛苦压制 / 150 绝望祷言）。
--   插件只负责：选目标 → 点亮「设焦点」色块（192/147/176-179/121-145）
--   → AHK 按 /focus → 下一 tick 再点亮 [@focus] 治疗色块。
--   老版靠 WR_FocusMaxWeightUnit() 每 0.15 秒按权重选人；本文件在
--   Forever 客户端上把这条链路补回，并按无限实际技能/天赋重建循环。
--
-- 【无限可用技能（Data/Forever_Abilities.lua + Forever_SkillRegistry.lua）】
--   真言术：盾 17 / 苦修 1240720 / 快速治疗 2061 / 治疗祷言 596 /
--   愈合祷言 41637 / 恢复 139 / 绝望祷言 13908 / 心灵专注 / 能量灌注
--   痛苦压制、守护之魂在无限被标记为缺失（false），循环不再提示。
--
-- 【优先级】高 → 低
--   1 自身绝望祷言（<30%，JL_JWDY）
--   2 自动焦点（有人低于治疗阈值才切，尊重玩家手动焦点）
--   3 痛苦压制（<30%，无限缺失时自动跳过）
--   4 治疗祷言（3 人以上低于 70%，JL_ZLDY）
--   5 愈合祷言（目标无 buff，JL_YHDY）
--   6 真言术：盾（按 JL_ZYSD 档位 / 全团套盾 JL_QTTD / 坦克盾 JL_TKZD / 焦点盾 JL_JDSD）
--   7 苦修（<90%）
--   8 快速治疗 / 联结治疗（<85%，JL_ZL）
--   9 恢复（<95%，蓝 >20%，JL_HF）
-- ============================================================

local function P_Disc_Num(key, def)
    local v = PigSet and PigSet[key]
    v = tonumber(v)
    if v == nil then return def end
    return v
end

local function P_Disc_On(key, def)
    local v = PigSet and PigSet[key]
    if v == nil then return def end
    return v == true
end

-- 队伍单位列表（团队优先，其次小队，含 player）
local function P_Disc_Units()
    local list = { { unit = "player", index = 0 } }
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    if raid > 0 then
        for i = 1, raid do list[#list + 1] = { unit = "raid" .. i, index = i } end
    elseif party > 0 then
        for i = 1, party do list[#list + 1] = { unit = "party" .. i, index = i } end
    end
    return list
end

local function P_Disc_IsTank(entry)
    local unit, idx = entry.unit, entry.index
    if type(UnitGroupRolesAssigned) == "function" then
        local ok, role = pcall(UnitGroupRolesAssigned, unit)
        if ok and role == "TANK" then return true end
    end
    if idx and idx > 0 and type(WR_NumIsTank) == "function" then
        local ok, tank = pcall(WR_NumIsTank, idx)
        if ok and tank then return true end
    end
    return false
end

-- 存活 / 友方 / 40 码内
local function P_Disc_Valid(unit)
    if type(unit) ~= "string" or unit == "" then return false end
    if type(UnitExists) ~= "function" or not UnitExists(unit) then return false end
    local okDead, dead = pcall(UnitIsDeadOrGhost, unit)
    if okDead and dead then return false end
    if type(UnitCanAttack) == "function" then
        local okAtk, atk = pcall(UnitCanAttack, "player", unit)
        if okAtk and atk then return false end
    end
    if type(WR_UnitRange) == "function" then
        local okR, range = pcall(WR_UnitRange, unit)
        if okR and type(range) == "number" and range > 40 and range < 999 then return false end
    end
    return true
end

-- 按面板「治疗模式」选目标：1 自动 / 2 坦克 / 3 脆皮 / 4 当前目标
local function P_Disc_PickBest(threshold)
    local mode = P_Disc_Num("JL_ZLMS", 1)

    if mode == 4 then
        if P_Disc_Valid("target")
           and (type(UnitIsPlayer) ~= "function" or UnitIsPlayer("target")) then
            local hp = WR_GetUnitHP("target")
            if type(hp) == "number" and hp < threshold then return "target", hp end
        end
        mode = 1   -- 目标不可用 → 退回自动
    end

    local best, bestHP = nil, threshold
    for _, entry in ipairs(P_Disc_Units()) do
        local unit = entry.unit
        if P_Disc_Valid(unit) then
            local tank = P_Disc_IsTank(entry)
            local allowed = true
            if mode == 2 and not tank then allowed = false end
            if mode == 3 and tank then allowed = false end
            if allowed then
                local hp = WR_GetUnitHP(unit)
                if type(hp) == "number" and hp < threshold and hp < bestHP then
                    best, bestHP = unit, hp
                end
            end
        end
    end
    return best, bestHP
end

-- 单位 token → 设焦点色块槽位（与 Priest_Macros.lua 一一对应）
local function P_Disc_FocusSlot(unit)
    if type(unit) ~= "string" then return nil end
    if unit == "player" then return 192 end     -- /focus player
    if unit == "target" then return 147 end     -- /focus target
    local p = string.match(unit, "^party(%d)$")
    if p then
        local n = tonumber(p)
        if n and n >= 1 and n <= 4 then return 175 + n end   -- 176-179
    end
    local r = string.match(unit, "^raid(%d+)$")
    if r then
        local n = tonumber(r)
        if n and n >= 1 and n <= 25 then return 120 + n end  -- 121-145
    end
    return nil
end

local function P_Disc_FocusUsable()
    if type(UnitExists) ~= "function" or not UnitExists("focus") then return false end
    local okDead, dead = pcall(UnitIsDeadOrGhost, "focus")
    if okDead and dead then return false end
    if type(UnitCanAttack) == "function" then
        local okAtk, atk = pcall(UnitCanAttack, "player", "focus")
        if okAtk and atk then return false end
    end
    return true
end

-- 点亮「设焦点」色块：AHK 识别后按对应 /focus 宏，下一 tick 焦点即到位
local function P_Disc_SetFocus(unit, text)
    local slot = P_Disc_FocusSlot(unit)
    if not slot then return false end
    if type(WR_ColorFrame_Show) ~= "function" then return false end
    local ok, shown = pcall(WR_ColorFrame_Show, slot, (text or "设焦点") .. "\n" .. unit)
    return ok and shown == true
end

local function P_Disc_ShowSkill(spell, slot)
    -- 盾的等级宏（JL_DDDJ）会传入 60/61/50，而 WR_SkillColor 只登记了 59；
    -- 这时必须直接按「数值槽位」点亮，不能走技能名映射，否则等级选择失效。
    local mapped = nil
    if type(WR_SoD_ResolveSlot) == "function" then
        local okMap, v = pcall(WR_SoD_ResolveSlot, spell)
        if okMap then mapped = v end
    end
    if slot and mapped and mapped ~= slot and type(WR_ColorFrame_Show) == "function" then
        local ok, shown = pcall(WR_ColorFrame_Show, slot, spell)
        return ok and shown == true
    end
    if type(WR_ColorFrame_ShowSkill) == "function" then
        local ok, shown = pcall(WR_ColorFrame_ShowSkill, spell, slot)
        return ok and shown == true
    end
    if type(WR_ColorFrame_Show) == "function" and slot then
        local ok, shown = pcall(WR_ColorFrame_Show, slot, spell)
        return ok and shown == true
    end
    return false
end

-- 焦点目标施法：焦点已是目标 → 点亮治疗色块；否则先点亮设焦点色块
local function P_Disc_Cast(unit, slot, spell, text)
    if not unit then return false end
    if UnitIsUnit(unit, "focus") then
        return P_Disc_ShowSkill(spell, slot)
    end
    return P_Disc_SetFocus(unit, text or spell)
end

-- 自动焦点：只有「确实有人低于治疗阈值」时才切；当前焦点更危急则保持
local P_Disc_LastFocusTry = 0
local function P_Disc_AutoFocus(threshold, unit, hp)
    local now = GetTime()
    if now - (P_Disc_LastFocusTry or 0) < 0.15 then return false end
    P_Disc_LastFocusTry = now

    -- 优先复用老版「焦点权重」选人（Utils_HealerWeight.lua），它包含
    -- 坦克/脆皮/目标模式与优先级 debuff（刺骨之寒/血肉成灰等）。
    -- 只有 0.15 秒节流窗口内才做全团权重扫描，避免每 tick 双扫。
    if type(WR_GetHealthMaxWeightUnit) == "function" then
        local okW, wu = pcall(WR_GetHealthMaxWeightUnit)
        if okW and type(wu) == "string" and wu ~= "Nothing" and P_Disc_Valid(wu) then
            local whp = WR_GetUnitHP(wu)
            if type(whp) == "number" and whp < threshold then unit, hp = wu, whp end
        end
    end
    if not unit then unit, hp = P_Disc_PickBest(threshold) end
    if not unit then return false end
    if UnitIsUnit(unit, "focus") then return false end
    if P_Disc_FocusUsable() then
        local fh = WR_GetUnitHP("focus")
        if type(fh) == "number" and fh <= hp then return false end
    end
    return P_Disc_SetFocus(unit)
end

local function P_Disc_LowCount(threshold)
    local n = 0
    for _, entry in ipairs(P_Disc_Units()) do
        if P_Disc_Valid(entry.unit) and WR_GetUnitHP(entry.unit) < threshold then
            n = n + 1
        end
    end
    return n
end

local function P_Disc_BuffTime(unit, spell)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, t = pcall(WR_GetUnitBuffTime, unit, spell)
    if ok and type(t) == "number" then return t end
    return 0
end

local function P_Disc_DebuffTime(unit, spell)
    if type(WR_GetUnitDebuffTime) ~= "function" then return 0 end
    local ok, t = pcall(WR_GetUnitDebuffTime, unit, spell)
    if ok and type(t) == "number" then return t end
    return 0
end

local function P_Disc_AnyBuff(spell)
    for _, entry in ipairs(P_Disc_Units()) do
        if P_Disc_Valid(entry.unit) and P_Disc_BuffTime(entry.unit, spell) > 0 then
            return true
        end
    end
    return false
end

-- 真言术：盾档位（JL_ZYSD：1-18 = 10%~99%，19 = 积极，20 = 禁用）
local function P_Disc_ShieldThreshold()
    local v = P_Disc_Num("JL_ZYSD", 8)
    if v == 20 then return nil end
    if v == 19 then return 1.0 end
    if v <= 9 then return v / 10 end
    if v <= 18 then return 0.9 + (v - 9) / 100 end
    return 0.8
end

-- 盾的等级（JL_DDDJ：1 满级=59 / 2 十三级=60 / 3 十二级=61 / 4 十一级=50）
local function P_Disc_ShieldSlot()
    local v = P_Disc_Num("JL_DDDJ", 1)
    if v == 2 then return 60 end
    if v == 3 then return 61 end
    if v == 4 then return 50 end
    return 59
end

local function P_Disc_HasShield(unit)
    if P_Disc_BuffTime(unit, "真言术：盾") > 0 then return true end
    if P_Disc_DebuffTime(unit, "虚弱灵魂") > 0 then return true end
    return false
end

local function P_Disc_ShieldUnit(unit)
    if not P_Disc_Valid(unit) then return false end
    if P_Disc_HasShield(unit) then return false end
    if not WR_SpellUsable("真言术：盾", true) then return false end
    return P_Disc_Cast(unit, P_Disc_ShieldSlot(), "真言术：盾", "真言术：盾")
end

local function P_Disc_Moving()
    if type(WR_PlayerMove) ~= "function" then return false end
    local ok, moving = pcall(WR_PlayerMove)
    return ok and moving == true
end

-- ============================================================
-- 主循环
-- ============================================================
function WR_PriestForeverDiscipline()
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")

    -- 0. 正在读条：整轮让路，避免点亮新色块打断自己的治疗
    if type(WR_SafeCastingName) == "function" then
        local okCast, casting = pcall(WR_SafeCastingName, "player")
        if okCast and casting then return true end
    end

    -- 1. 自身保命（绝望祷言是自施宏，不受焦点影响）
    if PlayerHP < 0.30 and P_Disc_On("JL_JWDY", true) and WR_SpellUsable("绝望祷言", true) then
        if P_Disc_ShowSkill("绝望祷言", 150) then return true end
    end

    local moving = P_Disc_Moving()
    local lowCount = P_Disc_LowCount(0.70)
    local shieldThreshold = P_Disc_ShieldThreshold()

    -- 自动焦点候选血量门：覆盖治疗阈值与盾档位
    local pickGate = 0.90
    if shieldThreshold and shieldThreshold >= 1.0 then
        pickGate = 1.01   -- 「积极」盾：满血目标也要纳入候选
    elseif shieldThreshold and shieldThreshold > pickGate then
        pickGate = shieldThreshold
    end

    local healUnit, healHP = P_Disc_PickBest(pickGate)

    -- 2. 自动焦点（本 tick 只设焦点，下一 tick 再治疗，避免「判旧焦点、打新焦点」）
    if P_Disc_AutoFocus(pickGate, healUnit, healHP) then return true end

    -- 3. 痛苦压制（无限标记缺失，WR_SpellUsable 会拦下；保留给其它客户端/后续版本）
    if healUnit and healHP < 0.30 and P_Disc_On("JL_TKYZ", true)
       and WR_SpellUsable("痛苦压制", true) then
        if P_Disc_Cast(healUnit, 64, "痛苦压制", "痛苦压制") then return true end
    end

    -- 4. 群体治疗：3 人以上低于 70%
    if healUnit and lowCount >= 3 and not moving
       and P_Disc_On("JL_ZLDY", true) and WR_SpellUsable("治疗祷言", true) then
        if P_Disc_Cast(healUnit, 53, "治疗祷言", "治疗祷言") then return true end
    end

    -- 5. 愈合祷言（同一个圣言只能存在一个，任一队友已有就跳过）
    if healUnit and healHP < 0.92 and P_Disc_On("JL_YHDY", true)
       and WR_SpellUsable("愈合祷言", true)
       and P_Disc_BuffTime(healUnit, "愈合祷言") == 0
       and not P_Disc_AnyBuff("愈合祷言") then
        if P_Disc_Cast(healUnit, 58, "愈合祷言", "愈合祷言") then return true end
    end

    -- 6. 真言术：盾（按面板档位）
    if healUnit and shieldThreshold and healHP <= shieldThreshold then
        if P_Disc_ShieldUnit(healUnit) then return true end
    end

    -- 6.1 全团套盾（JL_QTTD）
    if shieldThreshold and P_Disc_On("JL_QTTD", false) then
        for _, entry in ipairs(P_Disc_Units()) do
            if not P_Disc_IsTank(entry) and P_Disc_ShieldUnit(entry.unit) then return true end
        end
    end

    -- 6.2 坦克盾（JL_TKZD 默认开）
    if shieldThreshold and P_Disc_On("JL_TKZD", true) then
        for _, entry in ipairs(P_Disc_Units()) do
            if P_Disc_IsTank(entry) and P_Disc_ShieldUnit(entry.unit) then return true end
        end
    end

    -- 6.3 焦点盾（JL_JDSD）：给玩家手动设置的焦点持续补盾
    if shieldThreshold and P_Disc_On("JL_JDSD", false) and P_Disc_FocusUsable() then
        if P_Disc_ShieldUnit("focus") then return true end
    end

    -- 7. 苦修（主力单疗，引导 3 跳）
    if healUnit and healHP < 0.90 and not moving and WR_SpellUsable("苦修", true) then
        if P_Disc_Cast(healUnit, 54, "苦修", "苦修") then return true end
    end

    -- 8. 快速治疗 / 联结治疗（联结治疗同时治疗自己和目标）
    if healUnit and healHP < 0.85 and not moving and P_Disc_On("JL_ZL", true) then
        if PlayerHP < 0.85 and WR_SpellUsable("联结治疗", true) then
            if P_Disc_Cast(healUnit, 56, "联结治疗", "联结治疗") then return true end
        end
        if WR_SpellUsable("快速治疗", true) then
            if P_Disc_Cast(healUnit, 57, "快速治疗", "快速治疗") then return true end
        end
    end

    -- 9. 恢复（瞬发，移动中也可用）
    if healUnit and healHP < 0.95 and P_Disc_On("JL_HF", true) and PlayerMP > 0.20
       and WR_SpellUsable("恢复", true)
       and P_Disc_BuffTime(healUnit, "恢复") == 0 then
        if P_Disc_Cast(healUnit, 55, "恢复", "恢复") then return true end
    end

    return false
end

-- ============================================================
-- 诊断：/mkpdisc
-- ============================================================
SLASH_MKPDISC1 = "/mkpdisc"
SlashCmdList["MKPDISC"] = function()
    print("|cffFF69B4[MKHelperForever 戒律]|r 焦点目标加血诊断")
    print("  治疗模式 JL_ZLMS = " .. tostring(P_Disc_Num("JL_ZLMS", 1))
          .. "（1自动 / 2坦克 / 3脆皮 / 4目标）")
    print("  盾档位 JL_ZYSD = " .. tostring(P_Disc_Num("JL_ZYSD", 8))
          .. "  盾阈值 = " .. tostring(P_Disc_ShieldThreshold())
          .. "  盾槽位 = " .. tostring(P_Disc_ShieldSlot()))
    local ok, unit, hp = pcall(P_Disc_PickBest, 0.90)
    if ok and unit then
        print("  当前候选 = " .. tostring(unit) .. string.format("（%.0f%%）", (hp or 1) * 100))
    else
        print("  当前候选 = 无（无人低于 90%）")
    end
    local focusOK = P_Disc_FocusUsable()
    print("  焦点可用 = " .. tostring(focusOK)
          .. "  焦点 = " .. (focusOK and "有" or "无"))
    print("  焦点血量 = " .. (focusOK and string.format("%.0f%%", WR_GetUnitHP("focus") * 100) or "?"))
end
