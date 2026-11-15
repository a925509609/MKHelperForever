-- ============================================================
-- Paladin Forever · Holy 专精循环（奶骑治疗 · 无限 1.60.x / 60级）
-- 共享 helper 见 Paladin_Forever.lua（公共件）
-- 功能层见 Paladin_Holy_Features.lua（圣印 / 圣光誓约 / 祝福 / 驱散 / 愤怒之锤 / 驱邪术 / 插入）
-- ------------------------------------------------------------
-- 【治疗模型】色块 = 现在该按这个键；治疗目标固定是「焦点」。
--   本职业所有治疗宏都是 [@focus] 形态：
--     109 圣光闪现 / 110 圣光术 / 113 神圣震击 / 150 圣疗术 / 63 清洁术(焦点)
--   焦点不可用时只走自施槽位（18 圣盾术 / 48 圣疗术 / 43 清洁术）。
--
-- 【本服 60 级技能（法术书实测）】
--   圣光术 635 / 圣光闪现 19750 / 神圣震击 1311606 / 神恩术 20216 /
--   圣疗术 633 / 清洁术 4987 / 圣盾术 642 / 圣光守望 1311595 / 圣光誓约 1328548
--   ★ 80 级技能（圣光道标 / 圣洁护盾 / 神圣牺牲 / 光环掌握 / 复仇之怒 /
--     祈求圣光 / 神圣风暴）在无限服不存在，本文件不再引用。
--
-- 【优先级】高 → 低：
--   0 脱战祝福（复用 Paladin_Blessing.lua）
--   1 读条保护：玩家施法中整轮让路，不点亮任何新色块
--   2 自身圣盾术（< SS_SDS）
--   3 自身圣疗术 / 焦点圣疗术（< SS_SLS，默认 69）
--   4 喝红药（< SS_HXY，默认 90）
--   5 神恩术（只有圣光术确实要用时才提示）
--   6 圣光守望（< SS_SGWS，默认 52；≥2 人低血）
--   7 神圣震击（< SS_SSZJ，默认 54；移动中放宽；有守望标记无条件）
--   8 圣光术（< SS_SGS，默认 60）
--   9 圣光闪现（< SS_SGSX，默认 85）
--  10 清洁术（自己 → 焦点 → 指向）
--  11 圣光誓约 / 圣印 / 审判维持 / 切换目标 / 愤怒之锤 / 驱邪术 / 奉献 / 插入
-- ============================================================

WR_PaladinForeverHoly_FavorAt = WR_PaladinForeverHoly_FavorAt or nil
WR_PaladinForeverHoly_VigilAt = WR_PaladinForeverHoly_VigilAt or nil

function WR_PaladinForeverHoly_Cfg(key, def)
    local v = PigSet and PigSet[key]
    if type(v) ~= "number" then return def end
    return v
end

function WR_PaladinForeverHoly_FocusUsable()
    if type(UnitExists) ~= "function" or not UnitExists("focus") then return false end
    local okDead, dead = pcall(UnitIsDeadOrGhost, "focus")
    if okDead and dead then return false end
    if type(UnitIsFriend) == "function" then
        local okF, friend = pcall(UnitIsFriend, "player", "focus")
        if okF and friend == false then return false end
    end
    return true
end

function WR_PaladinForeverHoly_GroupUnits()
    local units = { "player" }
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    if raid > 0 then
        for i = 1, raid do units[#units + 1] = "raid" .. i end
    elseif party > 0 then
        for i = 1, party do units[#units + 1] = "party" .. i end
    end
    return units
end

function WR_PaladinForeverHoly_LowCount(threshold)
    threshold = threshold or 0.70
    local n = 0
    local units = WR_PaladinForeverHoly_GroupUnits()
    for i = 1, #units do
        local u = units[i]
        if UnitExists(u) then
            local okD, dead = pcall(UnitIsDeadOrGhost, u)
            if okD and not dead and WR_GetUnitHP(u) < threshold then
                n = n + 1
            end
        end
    end
    return n
end

-- 清洁术可解：中毒 / 疾病 / 魔法；不能解诅咒。
function WR_PaladinForeverHoly_HasDispel(unit)
    if type(unit) ~= "string" or not UnitExists(unit) then return false end
    if WR_PaladinForever_UnitHasDispel ~= nil then
        local ok, hit = pcall(WR_PaladinForever_UnitHasDispel, unit)
        if ok and hit == true then return true end
        if ok and hit == false then return false end
    end
    local cache = type(WR_AuraCache) == "table" and WR_AuraCache[unit] or nil
    local auras = cache and cache.HARMFUL or nil
    if type(auras) == "table" then
        for i = 1, #auras do
            local aura = auras[i]
            local dt = type(aura) == "table" and aura.dispelType or nil
            if type(dt) == "string" then
                local s = string.lower(dt)
                if s == "poison" or s == "disease" or s == "magic"
                    or dt == "中毒" or dt == "疾病" or dt == "魔法" then
                    return true
                end
            end
        end
    end
    return false
end

function WR_PaladinForeverHoly_OnCooldown(realName, cd)
    if type(realName) ~= "string" or type(cd) ~= "number" or cd <= 0 then return false end
    if type(WR_PaladinForever_GetLastCastAt) ~= "function" then return false end
    local at = WR_PaladinForever_GetLastCastAt(realName)
    if type(at) ~= "number" then return false end
    return (GetTime() - at) < cd
end

function WR_PaladinForeverHoly_FavorActive()
    local remain = WR_GetUnitBuffTime("player", "神恩术")
    if type(remain) == "number" and remain > 0 then return true end
    local at = WR_PaladinForeverHoly_FavorAt
    if type(at) == "number" and (GetTime() - at) < 10 then return true end
    return false
end

-- 圣光守望标记（友方 Buff / 敌方 Debuff 都查；读不到时按 30 秒本地记账兜底）
function WR_PaladinForeverHoly_VigilOn(unit)
    if type(unit) ~= "string" or not UnitExists(unit) then return false end
    local b = WR_GetUnitBuffTime(unit, "圣光守望")
    if type(b) == "number" and b > 0 then return true end
    local d = WR_GetUnitDebuffTime(unit, "圣光守望")
    if type(d) == "number" and d > 0 then return true end
    local at = WR_PaladinForeverHoly_VigilAt
    if type(at) == "number" and (GetTime() - at) < 30 then return true end
    return false
end

function WR_PaladinForeverHoly_FavorUseful(hp, hlPct)
    if hlPct > 0 and hp < hlPct / 100 and WR_SpellUsable("圣光术", true) then return true end
    return false
end

WR_PaladinForeverHoly_LastSample = WR_PaladinForeverHoly_LastSample or nil

function WR_PaladinForeverHoly_ReapOnRise(hp, playerHP, hlPct, flPct, slsPct, sdsPct, focusOK)
    local prev = WR_PaladinForeverHoly_LastSample
    WR_PaladinForeverHoly_LastSample = { hp = hp, php = playerHP }
    if type(prev) ~= "table" then return end
    if focusOK then
        if hlPct > 0 and prev.hp < hlPct / 100 and hp >= hlPct / 100 then
            WR_PaladinForever_HideNow("圣光术", 110)
            WR_PaladinForever_HideNow("神恩术", 114)
        end
        if flPct > 0 and prev.hp < flPct / 100 and hp >= flPct / 100 then
            WR_PaladinForever_HideNow("圣光闪现(焦点)", 109)
        end
        if slsPct > 0 and prev.hp < slsPct / 100 and hp >= slsPct / 100 then
            WR_PaladinForever_HideNow("圣疗术(队友)", 150)
        end
    end
    if slsPct > 0 and prev.php < slsPct / 100 and playerHP >= slsPct / 100 then
        WR_PaladinForever_HideNow("圣疗术", 48)
    end
    if sdsPct > 0 and prev.php < sdsPct / 100 and playerHP >= sdsPct / 100 then
        WR_PaladinForever_HideNow("圣盾术", 18)
    end
end

-- 自动焦点：恢复「点亮色块 → AHK 按宏 → /focus」链路
WR_PaladinForeverHoly_FocusCalcAt = WR_PaladinForeverHoly_FocusCalcAt or 0
WR_PaladinForeverHoly_FocusDecision = WR_PaladinForeverHoly_FocusDecision or nil

function WR_PaladinForeverHoly_FocusSlot(unit)
    if type(unit) ~= "string" then return nil end
    if unit == "player" then return 192 end
    if unit == "target" then return 147 end
    local p = string.match(unit, "^party(%d)$")
    if p then
        local n = tonumber(p)
        if n and n >= 1 and n <= 4 then return 175 + n end
    end
    local r = string.match(unit, "^raid(%d+)$")
    if r then
        local n = tonumber(r)
        if n and n >= 1 and n <= 25 then return 120 + n end
    end
    return nil
end

function WR_PaladinForeverHoly_AutoFocus(flPct)
    if PigSet and PigSet.SS_ZDJD == false then return false end
    if type(WR_GetHealthMaxWeightUnit) ~= "function" then return false end
    local now = GetTime()
    if (now - (WR_PaladinForeverHoly_FocusCalcAt or 0)) < 0.2 then return false end
    WR_PaladinForeverHoly_FocusCalcAt = now
    local ok, unit = pcall(WR_GetHealthMaxWeightUnit)
    if not ok or type(unit) ~= "string" or unit == "Nothing" then return false end
    if not UnitExists(unit) then return false end
    local uh = WR_GetUnitHP(unit)
    local gate = (flPct or 85) / 100
    if uh >= gate then
        WR_PaladinForeverHoly_FocusDecision = string.format("跳过 %s（血量 %.0f%% 未低于阈值）", unit, uh * 100)
        return false
    end
    if unit == "player" then return false end
    if UnitIsUnit(unit, "focus") then return false end
    if WR_PaladinForeverHoly_FocusUsable() then
        local fh = WR_GetUnitHP("focus")
        if fh <= uh then
            WR_PaladinForeverHoly_FocusDecision =
                string.format("保持焦点（%.0f%% 不高于 %s 的 %.0f%%）", fh * 100, unit, uh * 100)
            return false
        end
    end
    local slot = WR_PaladinForeverHoly_FocusSlot(unit)
    if not slot then return false end
    if WR_ColorFrame_Show(slot, "设焦点") then
        WR_PaladinForeverHoly_FocusDecision = string.format("切换 %s（槽 %d，血量 %.0f%%）", unit, slot, uh * 100)
        return true
    end
    return false
end

-- ============================================================
-- 主循环
-- ============================================================
function WR_PaladinForeverHoly()
    WR_PaladinForever_ClearStalePrompts(1.0)

    -- 0. 祝福（脱战自动补）
    if type(WR_PaladinBlessing_Auto) == "function" and WR_PaladinBlessing_Auto() then return true end

    -- 1. 读条保护
    local casting = nil
    if type(WR_SafeCastingName) == "function" then
        casting = WR_SafeCastingName("player")
    end
    if casting then return true end

    -- 2. 采集
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()

    local focusOK = WR_PaladinForeverHoly_FocusUsable()
    local unit = focusOK and "focus" or "player"
    local hp = WR_GetUnitHP(unit)

    local hlPct  = WR_PaladinForeverHoly_Cfg("SS_SGS", 60)
    local flPct  = WR_PaladinForeverHoly_Cfg("SS_SGSX", 85)
    local slsPct = WR_PaladinForeverHoly_Cfg("SS_SLS", 69)
    local sdsPct = WR_PaladinForeverHoly_Cfg("SS_SDS", 30)
    local ssPct  = WR_PaladinForeverHoly_Cfg("SS_SSZJ", 54)
    local qjsMode = WR_PaladinForeverHoly_Cfg("SS_QJS", 2)

    WR_PaladinForeverHoly_ReapOnRise(hp, PlayerHP, hlPct, flPct, slsPct, sdsPct, focusOK)

    -- 2.6 自动焦点
    if WR_PaladinForeverHoly_AutoFocus(flPct) then return true end

    -- 3. 自身圣盾术
    if sdsPct > 0 and PlayerHP < sdsPct / 100
       and WR_SpellUsable("圣盾术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣盾术", 300)
       and WR_PaladinForever_ShowSkillCD("圣盾术", 18, 300) then
        return true
    end

    -- 4. 自身圣疗术
    if slsPct > 0 and PlayerHP < slsPct / 100
       and WR_SpellUsable("圣疗术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣疗术", 1200)
       and WR_PaladinForever_ShowSkillCD("圣疗术", 48, 300) then
        return true
    end

    -- 5. 焦点圣疗术
    if focusOK and slsPct > 0 and hp < slsPct / 100
       and WR_SpellUsable("圣疗术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣疗术", 1200)
       and WR_PaladinForever_ShowSkillCD("圣疗术(队友)", 150, 300) then
        return true
    end

    -- 6. 喝红药
    if type(WR_PaladinHolyUI) == "table" and type(WR_PaladinHolyUI.PotionStep) == "function"
       and WR_PaladinHolyUI.PotionStep() then return true end

    -- 7. 神恩术
    if focusOK and not WR_PaladinForeverHoly_FavorActive()
       and WR_PaladinForeverHoly_FavorUseful(hp, hlPct)
       and WR_SpellUsable("神恩术", true)
       and not WR_PaladinForeverHoly_OnCooldown("神恩术", 120)
       and WR_PaladinForever_ShowSkillCD("神恩术", 114, 120) then
        WR_PaladinForeverHoly_FavorAt = GetTime()
        return true
    end

    -- 8. 圣光守望（Light's Vigil）：群疗准备，30 秒标记
    local sgwsPct = WR_PaladinForeverHoly_Cfg("SS_SGWS", 52)
    local vigilUp = focusOK and WR_PaladinForeverHoly_VigilOn("focus")
    if focusOK and not vigilUp
       and sgwsPct > 0 and hp < sgwsPct / 100
       and WR_PaladinForever_SpellKnown("圣光守望")
       and WR_SpellUsable("圣光守望", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣光守望", 6)
       and WR_PaladinForeverHoly_LowCount(0.70) >= 2
       and WR_PaladinForever_ShowSkillCD("圣光守望", 4, 6) then
        WR_PaladinForeverHoly_VigilAt = GetTime()
        return true
    end

    -- 9. 神圣震击（10 秒 CD，瞬发）
    if focusOK and ssPct > 0
       and WR_SpellUsable("神圣震击", true)
       and not WR_PaladinForeverHoly_OnCooldown("神圣震击", 10) then
        local need = vigilUp or (hp < ssPct / 100) or (PlayerMove == true and hp < 0.98)
        if need and WR_PaladinForever_ShowSkillCD("神圣震击", 113, 10) then
            return true
        end
    end

    -- 10. 圣光术（2.5 秒读条）
    if focusOK and hlPct > 0 and hp < hlPct / 100 and PlayerMP > 0.15
       and WR_SpellUsable("圣光术", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣光术", 2.5)
       and WR_PaladinForever_ShowSkillCD("圣光术", 110, 2.5) then
        return true
    end

    -- 11. 圣光闪现（1.5 秒读条）
    if focusOK and flPct > 0 and hp < flPct / 100 and PlayerMP > 0.08
       and WR_SpellUsable("圣光闪现", true)
       and not WR_PaladinForeverHoly_OnCooldown("圣光闪现", 1.5)
       and WR_PaladinForever_ShowSkillCD("圣光闪现(焦点)", 109, 1.5) then
        return true
    end

    -- 12. 清洁术（驱散）
    local dispelOff = (PigSet and PigSet.SS_QJS_AUTO == true)
        or (PigSet and PigSet.SS_QJS_ON == false) or (qjsMode == 5)
    local cleanseReady
    if WR_PaladinForever_CanCleanseCast ~= nil then
        cleanseReady = WR_PaladinForever_CanCleanseCast()
    else
        cleanseReady = WR_SpellUsable("清洁术", true)
    end
    if not dispelOff and cleanseReady and not WR_PaladinForeverHoly_OnCooldown("清洁术", 8) then
        if WR_PaladinForeverHoly_HasDispel("player")
           and WR_PaladinForever_ShowSkillCD("清洁术(自己)", 43, 8) then
            return true
        end
        if focusOK and WR_PaladinForeverHoly_HasDispel("focus")
           and WR_PaladinForever_ShowSkillCD("清洁术(焦点)", 63, 8) then
            return true
        end
        if qjsMode == 4 and UnitExists("mouseover")
           and WR_PaladinForeverHoly_HasDispel("mouseover")
           and WR_PaladinForever_ShowSkillCD("清洁术(指向)", 59, 8) then
            return true
        end
    end

    -- 13. 圣光誓约（buff 维持）
    if type(WR_PaladinHolyUI) == "table" and type(WR_PaladinHolyUI.OathStep) == "function"
       and WR_PaladinHolyUI.OathStep() then return true end

    -- 14. 圣印 / 审判维持
    if type(WR_PaladinHolyUI) == "table" then
        if type(WR_PaladinHolyUI.SealStep) == "function" and WR_PaladinHolyUI.SealStep() then return true end
        if type(WR_PaladinHolyUI.JudgeStep) == "function" and WR_PaladinHolyUI.JudgeStep() then return true end
    end

    -- 15. 切换目标 / 愤怒之锤 / 驱邪术 / 奉献 / 插入
    if type(WR_PaladinHolyUI) == "table" then
        if type(WR_PaladinHolyUI.TargetSwitchStep) == "function" and WR_PaladinHolyUI.TargetSwitchStep() then return true end
        if type(WR_PaladinHolyUI.HammerStep) == "function" and WR_PaladinHolyUI.HammerStep() then return true end
        if type(WR_PaladinHolyUI.ExorcismStep) == "function" and WR_PaladinHolyUI.ExorcismStep() then return true end
        if type(WR_PaladinHolyUI.ConsecrationStep) == "function" and WR_PaladinHolyUI.ConsecrationStep() then return true end
        if type(WR_PaladinHolyUI.InsertStep) == "function" and WR_PaladinHolyUI.InsertStep() then return true end
    end

    return false
end

-- ============================================================
-- 诊断命令 /mkpalholy
-- ============================================================
SLASH_MKPALHOLY1 = "/mkpalholy"
SlashCmdList["MKPALHOLY"] = function()
    local function spellState(name)
        local known = WR_PaladinForever_SpellKnown(name)
        local usable = WR_SpellUsable(name, true)
        local at = WR_PaladinForever_GetLastCastAt and WR_PaladinForever_GetLastCastAt(name)
        local ago = at and string.format("%.0f秒前", GetTime() - at) or "无记录"
        return string.format("%s(已学=%s 可用=%s 上次=%s)", name, tostring(known), tostring(usable), ago)
    end

    local focusOK = WR_PaladinForeverHoly_FocusUsable()
    local unit = focusOK and "focus" or "player"
    print("|cff00ff00[MKPALHOLY]|r 焦点可用=" .. tostring(focusOK)
        .. " 判定单位=" .. unit
        .. " 血量=" .. string.format("%.0f%%", (WR_GetUnitHP(unit) or 1) * 100)
        .. " 自身=" .. string.format("%.0f%%", (WR_GetUnitHP("player") or 1) * 100)
        .. " 蓝=" .. string.format("%.0f%%", (WR_GetUnitMP("player") or 1) * 100))
    print("|cff00ff00[MKPALHOLY]|r 阈值：圣光术=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SGS", 60))
        .. "% 圣光闪现=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SGSX", 85))
        .. "% 圣疗=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SLS", 69))
        .. "% 圣光守望=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SGWS", 52))
        .. "% 震击=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_SSZJ", 54))
        .. "% 喝红药=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_HXY", 90))
        .. "% 清洁模式=" .. tostring(WR_PaladinForeverHoly_Cfg("SS_QJS", 2)))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("圣光术"))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("圣光闪现"))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("神圣震击")
        .. " 神恩激活=" .. tostring(WR_PaladinForeverHoly_FavorActive()))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("圣疗术"))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("清洁术")
        .. " 自身可驱=" .. tostring(WR_PaladinForeverHoly_HasDispel("player"))
        .. " 焦点可驱=" .. tostring(focusOK and WR_PaladinForeverHoly_HasDispel("focus") or false))
    print("|cff00ff00[MKPALHOLY]|r " .. spellState("圣光守望")
        .. " 标记=" .. tostring(focusOK and WR_PaladinForeverHoly_VigilOn("focus") or false))
    print("|cff00ff00[MKPALHOLY]|r 圣光誓约目标=" .. tostring(PigSet and PigSet.SS_OATH_TARGET)
        .. " 开关=" .. tostring(PigSet and PigSet.SS_OATH_ON)
        .. " 常驻圣印=" .. tostring(WR_PaladinHolyUI and WR_PaladinHolyUI.MainSeal and select(1, WR_PaladinHolyUI.MainSeal()) or "?"))
    print("|cff00ff00[MKPALHOLY]|r 读条中=" .. tostring(WR_SafeCastingName and WR_SafeCastingName("player") or nil))
end
