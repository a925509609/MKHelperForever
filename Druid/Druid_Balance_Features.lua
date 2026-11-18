-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "DRUID" then return end
-- ============================================================
-- Druid_Balance_Features.lua
-- 平衡德鲁伊（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 DRUID「平衡」专精：不写全局、不影响野性/守护/恢复与其他职业。
--
-- 按「彼岸花-无限服 · 平衡页」截图逐项落地：
--   选择：防ADD（沿用 FANG_ADD_PH 下拉）
--   拉条：喝红药 30%
--   爆发：全开 / 全关 / 切换按钮 + 种族爆发
--   功能：枭兽 / DOT / 野性印记 / 复生 / 激活 / 荆棘术 / 切换目标 / 驱散
--   插入：飓风（一次性，放完自关）
--
-- 【本服 60 级平衡技能口径（Data/Forever_SkillRegistry.lua）】
--   愤怒 5176 / 星火术 2912 / 月火术 8921 / 飓风 16914 /
--   虫群 5570（平衡天赋）/ 枭兽形态 24858（平衡天赋）/
--   星涌术 1280472（无限新增）/ 野性印记 / 荆棘术 / 复生 / 激活 / 解除诅咒
--   ★ 80 级 / SoD 技能（星落、月神轨道炮、星辰坠落、阳炎术、自然之力、
--     台风、树皮术插入等）本服 60 级不存在，本层不再引用。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "DRUID" then return end

WR_DruidBalanceUI = WR_DruidBalanceUI or {}
local WB = WR_DruidBalanceUI

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ============================================================
WB.Defaults = {
    -- 功能（截图默认全勾）
    PH_XN = true,             -- 枭兽形态
    PH_DOT = true,            -- DOT 总开关
    PH_DOT_YHS = true,        --   月火术
    PH_DOT_YHS_TTD = 6,       --   预判秒数（0=都放）
    PH_DOT_CQ = true,         --   虫群（平衡天赋）
    PH_DOT_CQ_TTD = 8,        --   预判秒数
    PH_YXYZ = true,           -- 野性印记
    PH_FS = true,             -- 复生
    PH_JH_ON = true,          -- 激活
    PH_JH_HP = 20,            --   激活蓝量阈值（%）
    PH_JJS = true,            -- 荆棘术
    PH_TAB = true,            -- 切换目标
    PH_QS = true,             -- 驱散（解除诅咒）
    -- 拉条
    PH_HXY = 30,              -- 喝红药：血低于 30%
    -- 爆发
    PH_ZDZZ = true,           -- 种族爆发
    -- 插入（一次性，默认关）
    PH_CRJF = false,          -- 飓风
}

WB.Migrated = WB.Migrated or false

function WB.InitDefaults()
    if type(PigSet) ~= "table" then return end
    -- ★ 旧档迁移必须先于默认值填充（否则旧变量被默认值覆盖）
    if not WB.Migrated then
        WB.Migrated = true
        -- 旧 80 级「解除诅咒」两个开关 → 新「驱散」总开关
        if PigSet.PH_QS == nil then
            if PigSet.PH_JCZZ == true or PigSet.PH_JCWR_P == true then
                PigSet.PH_QS = true
            end
        end
        -- 旧「给自己激活」滑条 → 新激活蓝量阈值
        local oldJh = tonumber(PigSet.PH_JH_PLAYER) or tonumber(PigSet.PH_JH)
        if oldJh and PigSet.PH_JH_HP == nil then
            PigSet.PH_JH_HP = oldJh
        end
    end
    for k, v in pairs(WB.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
end

-- ============================================================
-- 2. 安全读取小工具
-- ============================================================
function WB.Num(v, d)
    local n = tonumber(v)
    if n == nil then return d end
    return n
end

function WB.Bool(v, d)
    if v == nil then return d end
    return v == true
end

function WB.On(var, default)
    return WB.Bool(PigSet and PigSet[var], default)
end

function WB.Val(var, default)
    return WB.Num(PigSet and PigSet[var], default)
end

function WB.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
end

function WB.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, known = pcall(WR_Forever_IsSpellKnown, name)
        if ok then return known == true end
    end
    return true
end

function WB.Show(spell, slot)
    WB.RawShownSlot = nil
    if WR_ColorFrame_ShowSkill ~= nil then
        return WR_ColorFrame_ShowSkill(spell, slot) == true
    end
    return false
end

-- 直接按颜色槽位点亮（用于同名技能有「自己/焦点」两个宏槽的情况）
function WB.ShowSlot(slot, text)
    if WR_ColorFrame_Show ~= nil then
        local ok, shown = pcall(WR_ColorFrame_Show, slot, text)
        if ok and shown then
            WR_SoD_LastShownSpell = text
            WR_SoD_ShownSkill = text
            WR_SoD_ShownTick = WR_SoD_TickSeq
            WB.RawShownSlot = slot
            return true
        end
    end
    return false
end

function WB.BuffRemain(name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, "player", name)
    if ok then return WB.Num(v, 0) end
    return 0
end

function WB.DebuffRemain(unit, name)
    if type(WR_GetUnitDebuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitDebuffTime, unit, name)
    if ok then return WB.Num(v, 0) end
    return 0
end

-- 任意诅咒（优先按 dispelType=Curse 判，名字兜底）
function WB.HasCurse(unit)
    if type(WR_UnitDebuffType) == "function" then
        local ok, has = pcall(WR_UnitDebuffType, unit, "Curse")
        if ok and has == true then return true end
    end
    return WB.DebuffRemain(unit, "诅咒") > 0
end

function WB.IsDead(unit)
    if type(UnitExists) ~= "function" or not UnitExists(unit) then return false end
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, dead = pcall(UnitIsDeadOrGhost, unit)
        if ok and dead == true then return true end
    end
    if type(UnitIsDead) == "function" then
        local ok, dead = pcall(UnitIsDead, unit)
        if ok and dead == true then return true end
    end
    return false
end

function WB.IsFriend(unit)
    if type(UnitExists) ~= "function" or not UnitExists(unit) then return false end
    if type(UnitIsFriend) ~= "function" then return true end
    local ok, friend = pcall(UnitIsFriend, "player", unit)
    return ok and friend == true
end

function WB.GroupUnits()
    local units = {}
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    if raid > 0 then
        for i = 1, math.min(raid, 40) do units[#units + 1] = "raid" .. i end
    else
        local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
        for i = 1, math.min(party, 4) do units[#units + 1] = "party" .. i end
    end
    return units
end

-- ============================================================
-- 3. 循环：基础变量 / 停手门 / 收尾清扫
-- ============================================================
function WB.Base()
    GCD = WR_GetGCD("愤怒")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)
    WB.TargetOK = UnitExists("target")
        and not UnitIsDeadOrGhost("target")
        and UnitCanAttack("player", "target")
    WB.InRange = (TargetRange ~= nil and TargetRange <= 35)
    WB.Casting = WR_SafeCastingName("player")
    WB.Channel = WR_SafeChannelName("player")
end

function WB.HideLastShown()
    local lastShown = WR_SoD_ShownSkill
    local rawSlot = WB.RawShownSlot
    if rawSlot ~= nil and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, rawSlot)
    elseif type(lastShown) == "string" and lastShown ~= "" and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, nil)
    end
    WB.RawShownSlot = nil
    WR_SoD_ShownSkill = nil
end

function WB.StopGate()
    local ch = WB.Channel
    if ch == "飓风" then
        if WR_HideSkillColorSlot ~= nil then
            pcall(WR_HideSkillColorSlot, "飓风", 24)
        end
        return true
    end
    if WB.Casting or WB.Channel then return true end
    local stop = UnitIsDeadOrGhost("player")
        or (IsMounted and IsMounted())
        or (UnitInVehicle and UnitInVehicle("player"))
    if not stop then
        local eatDrink = { "喝水", "进食", "饮用", "食物", "饮料", "饮水" }
        if WR_GetUnitBuffTime("player", eatDrink, nil, "NAME") > 0 then stop = true end
    end
    if stop then
        WB.HideLastShown()
        return true
    end
    return false
end

function WB.Sweep()
    if WR_SoD_ShownTick == WR_SoD_TickSeq then return end
    local lastShown = WR_SoD_ShownSkill
    local rawSlot = WB.RawShownSlot
    if rawSlot ~= nil and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, rawSlot)
    elseif type(lastShown) == "string" and lastShown ~= "" and WR_HideSkillColorSlot ~= nil then
        pcall(WR_HideSkillColorSlot, lastShown, nil)
    end
    WB.RawShownSlot = nil
    WR_SoD_ShownSkill = nil
end

-- ============================================================
-- 4. 功能：枭兽形态（缺形态就补，平衡天赋）
-- ============================================================
function WB.MoonkinStep()
    if not WB.On("PH_XN", true) then return false end
    if not WB.SpellKnown("枭兽形态") then return false end
    if WB.BuffRemain("枭兽形态") > 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "枭兽形态", true)
        if ok and usable == true then
            if WB.Show("枭兽形态", 16) then return true end
        end
    end
    return false
end

-- ============================================================
-- 5. 功能：野性印记（自己缺印记/赐福就补）
-- ============================================================
function WB.MarkStep()
    if not WB.On("PH_YXYZ", true) then return false end
    if WB.BuffRemain({ "野性印记", "野性赐福" }) > 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "野性印记", true)
        if ok and usable == true then
            if WB.Show("野性印记", 149) then return true end
        end
    end
    return false
end

-- ============================================================
-- 6. 功能：荆棘术（自己缺荆棘就补）
-- ============================================================
function WB.ThornsStep()
    if not WB.On("PH_JJS", true) then return false end
    if WB.BuffRemain("荆棘术") > 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "荆棘术", true)
        if ok and usable == true then
            if WB.Show("荆棘术", 150) then return true end
        end
    end
    return false
end

-- ============================================================
-- 7. 功能：复生（队友死亡时选中并复生）
-- ============================================================
WB.RebirthLast = WB.RebirthLast or 0

function WB.RebirthStep()
    if not WB.On("PH_FS", true) then return false end
    if WB.Casting or WB.Channel then return false end
    if WB.IsDead("player") then return false end
    local now = GetTime()
    if now - WB.RebirthLast < 2.0 then return false end
    local targetUnit
    for _, u in ipairs(WB.GroupUnits()) do
        if u ~= "player" and WB.IsDead(u) then
            local range = WR_UnitRange and WR_UnitRange(u) or nil
            if range == nil or range <= 40 then
                targetUnit = u
                break
            end
        end
    end
    if not targetUnit then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "复生", true)
        if ok and usable == true then
            if type(TargetUnit) == "function" then pcall(TargetUnit, targetUnit) end
            if WB.Show("复生", 13) then
                WB.RebirthLast = now
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 8. 功能：激活（自己/焦点蓝量低于阈值）
-- ============================================================
function WB.ActivateStep()
    if not WB.On("PH_JH_ON", true) then return false end
    local threshold = WB.Val("PH_JH_HP", 20)
    if threshold <= 0 then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "激活", true)
        if not ok or usable ~= true then return false end
    end
    if WB.Num(PlayerMP, 1) < threshold / 100 then
        if WB.Show("激活", 93) then return true end
    end
    if UnitExists("focus") and WB.IsFriend("focus") and not WB.IsDead("focus") then
        local focusMP = WR_GetUnitMP("focus")
        if WB.Num(focusMP, 1) < threshold / 100 then
            if WB.ShowSlot(103, "激活") then return true end
        end
    end
    return false
end

-- ============================================================
-- 9. 功能：驱散（解除诅咒：自己 → 焦点 → 队友）
-- ============================================================
WB.DecurseLast = WB.DecurseLast or 0

function WB.DecurseStep()
    if not WB.On("PH_QS", true) then return false end
    if WB.HasCurse("player") then
        if WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, "解除诅咒", true)
            if ok and usable == true then
                if WB.ShowSlot(75, "解除诅咒") then return true end
            end
        end
    end
    if UnitExists("focus") and WB.IsFriend("focus") and WB.HasCurse("focus") then
        if WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, "解除诅咒", true)
            if ok and usable == true then
                if WB.ShowSlot(74, "解除诅咒") then return true end
            end
        end
    end
    local now = GetTime()
    if now - WB.DecurseLast < 1.0 then return false end
    local targetUnit
    for _, u in ipairs(WB.GroupUnits()) do
        if u ~= "player" and u ~= "focus" and WB.HasCurse(u) then
            local range = WR_UnitRange and WR_UnitRange(u) or nil
            if range == nil or range <= 40 then targetUnit = u; break end
        end
    end
    if not targetUnit then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "解除诅咒", true)
        if ok and usable == true then
            if type(FocusUnit) == "function" then pcall(FocusUnit, targetUnit) end
            if WB.ShowSlot(74, "解除诅咒") then
                WB.DecurseLast = now
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 10. 插入：飓风（一次性，施放后自关）
-- ============================================================
function WB.InsertStep()
    if not WB.On("PH_CRJF", false) then return false end
    if not WB.TargetOK or not WB.InRange then return false end
    if WB.Casting or WB.Channel then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "飓风", true)
        if ok and usable == true then
            if WB.Show("飓风", 24) then
                PigSet.PH_CRJF = false
                WB.SyncCheckbox("PH_CRJF")
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- 11. 自保：喝红药（血低于拉条）
-- ============================================================
function WB.SelfPreserve()
    if WB.Num(PlayerHP, 1) >= WB.Val("PH_HXY", 30) / 100 then return false end
    if WR_Use_ZLYS ~= nil then
        local ok, can = pcall(WR_Use_ZLYS)
        if ok and can == true then
            if WR_ColorFrame_Show ~= nil then
                local ok2, shown = pcall(WR_ColorFrame_Show, "CSF", "治疗药水")
                if ok2 and shown then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 12. 切换目标（目标死亡/不存在 + 战斗中）
-- ============================================================
WB.LastTab = WB.LastTab or 0

function WB.TabStep()
    if not WB.On("PH_TAB", true) then return false end
    if not UnitAffectingCombat("player") then return false end
    if WB.TargetOK then return false end
    if WR_CanTab ~= nil and not WR_CanTab() then return false end
    local now = GetTime()
    if now - WB.LastTab < 1.0 then return false end
    if WB.Show("切目标", 46) then
        WB.LastTab = now
        return true
    end
    return false
end

-- ============================================================
-- 13. 战斗门（防ADD）：FANG_ADD_PH 1=是 2=否
-- ============================================================
function WB.CombatGate()
    local preventAdd = (WB.Val("FANG_ADD_PH", 1) == 1)
    local bossFrameActive = false
    for i = 1, 4 do
        if UnitExists("boss" .. i) then bossFrameActive = true; break end
    end
    local inBossEncounter = bossFrameActive
        and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    return inBossEncounter
        or (UnitAffectingCombat("player") and ((not preventAdd) or TargetInCombat))
end

-- ============================================================
-- 14. 爆发：种族爆发（当前种族爆发技能任一可用即提示）
-- ============================================================
function WB.BurstStep()
    if not WB.On("PH_ZDZZ", true) then return false end
    local fn = WR_Forever_GetRacialBursts or WR_Forever_PlayerRacialBursts
    if type(fn) ~= "function" then return false end
    local okB, bursts = pcall(fn)
    if not okB or type(bursts) ~= "table" then return false end
    for i = 1, #bursts do
        local name = bursts[i]
        if type(name) == "string" and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, name, true)
            if ok and usable == true then
                if WB.Show("种族爆发", 181) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 15. AoE：8 码内 3+ 目标 → 飓风
-- ============================================================
function WB.AoeStep()
    if not WB.TargetOK or not WB.InRange then return false end
    if WB.Num(UnitCount8, 0) < 3 then return false end
    if WB.Casting or WB.Channel then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "飓风", true)
        if ok and usable == true then
            if WB.Show("飓风", 24) then return true end
        end
    end
    return false
end

-- ============================================================
-- 16. DOT：月火术 / 虫群（只补自己的；预判 = 目标还能活 > X 秒才上）
-- ============================================================
function WB.DotStep()
    if not WB.On("PH_DOT", true) then return false end
    if not WB.TargetOK or not WB.InRange then return false end
    if WR_CanDot ~= nil and not WR_CanDot("target") then return false end
    if WR_IsBlacklisted ~= nil and WR_IsBlacklisted("target") then return false end
    local T = TargetDeathTime or 0

    local dts = {
        { on = "PH_DOT_YHS", ttd = "PH_DOT_YHS_TTD", dft = 6, name = "月火术", slot = 26 },
        { on = "PH_DOT_CQ",  ttd = "PH_DOT_CQ_TTD",  dft = 8, name = "虫群",   slot = 19, talent = true },
    }
    for _, d in ipairs(dts) do
        if WB.On(d.on, true) then
            local need = WB.Val(d.ttd, d.dft)
            if (need <= 0 or T > need)
               and (d.talent ~= true or WB.SpellKnown(d.name))
               and WR_GetUnitDebuffTime("target", d.name, true) == 0
               and WR_SpellUsable ~= nil then
                local ok, usable = pcall(WR_SpellUsable, d.name, true)
                if ok and usable == true then
                    if WB.Show(d.name, d.slot) then return true end
                end
            end
        end
    end
    return false
end

-- ============================================================
-- 17. 读条：星涌术 → 星火术 / 愤怒填充
-- ============================================================
function WB.CastStep()
    if not WB.TargetOK or not WB.InRange then return false end
    if WB.Casting or WB.Channel then return false end
    if PlayerMove then return false end

    -- 星涌术（无限新增，spellID 1280472；瞬发高优先）
    if WB.SpellKnown("星涌术") and WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "星涌术", true)
        if ok and usable == true then
            if WB.Show("星涌术", 86) then return true end
        end
    end

    -- 填充：存活久/蓝量足 → 星火术；否则愤怒（读条快、省蓝）
    local T = TargetDeathTime or 0
    local starfireOK = (WB.Num(PlayerMP, 1) > 0.20) and (T <= 0 or T > 6)
    local filler = starfireOK and "星火术" or "愤怒"
    local slot = starfireOK and 21 or 20
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, filler, true)
        if ok and usable == true then
            if WB.Show(filler, slot) then return true end
        end
    end
    return false
end

-- ============================================================
-- 18. 主循环：功能 → 插入 → 自保 → 切目标 → 战斗门 → 爆发 →
--     AoE → DOT → 读条 → 清扫
-- ============================================================
function WB.Run()
    WB.InitDefaults()
    local handled = false
    repeat
        WB.Base()
        if WB.StopGate() then break end
        if WB.MoonkinStep() then handled = true; break end
        if WB.MarkStep() then handled = true; break end
        if WB.ThornsStep() then handled = true; break end
        if WB.RebirthStep() then handled = true; break end
        if WB.ActivateStep() then handled = true; break end
        if WB.DecurseStep() then handled = true; break end
        if WB.InsertStep() then handled = true; break end
        if WB.SelfPreserve() then handled = true; break end
        if WB.TabStep() then handled = true; break end
        if not WB.CombatGate() then break end
        if WB.BurstStep() then handled = true; break end
        if WB.AoeStep() then handled = true; break end
        if WB.DotStep() then handled = true; break end
        if WB.CastStep() then handled = true; break end
    until true
    if not handled then WB.Sweep() end
    return handled
end

-- ============================================================
-- 19. 右键「额外条件」小窗
-- ============================================================
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

WB.PopupDefs = {
    PH_DOT = {
        title = "DOT  功能",
        width = 400,
        desc = "开着时按右键里的设置给目标上月火术、虫群：目标身上没有自己的那一个就补。\n\n"
            .. "月火术、虫群：勾上才放。\n"
            .. "「预判」= 目标预计还能活过这么多秒才放（0=都放）。\n\n"
            .. "关掉后右键里的 DOT 一个都不上。\n"
            .. "宏：/DRUID_DOT 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "PH_DOT", label = "DOT", default = true },
            { type = "cslider", var = "PH_DOT_YHS", pvar = "PH_DOT_YHS_TTD", pdefault = 6, label = "月火术", default = true, suffix = "秒", minv = 0, maxv = 30, indent = 18 },
            { type = "cslider", var = "PH_DOT_CQ",  pvar = "PH_DOT_CQ_TTD",  pdefault = 8, label = "虫群（平衡天赋）", default = true, suffix = "秒", minv = 0, maxv = 30, indent = 18 },
        },
    },
    PH_JH_ON = {
        title = "激活  功能",
        width = 340,
        desc = "开着时，自己蓝量低于阈值就用激活；焦点是队友且蓝量低于阈值时给焦点激活。\n\n"
            .. "阈值 0 = 不自动激活。\n"
            .. "宏：/DRUID_INNERVATE 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "PH_JH_ON", label = "激活", default = true },
            { type = "slider", var = "PH_JH_HP", label = "蓝量阈值", default = 20, suffix = "%", minv = 0, maxv = 100, indent = 18 },
        },
    },
}

local function BuildPopup(key)
    local def = WB.PopupDefs[key]
    if not def then return nil end
    local width = def.width or 360
    local f = CreateFrame("Frame", "WR_DruidBalancePopup_" .. key, UIParent, "BackdropTemplate")
    f:SetSize(width, 120)
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
    local contentWidth = width - 30
    local function addRow(h) y = y - h end

    if def.desc then
        local desc = MakeFont(f, def.desc, 11, 0.78, 0.78, 0.78, contentWidth)
        desc:SetPoint("TOPLEFT", f, "TOPLEFT", 12, y)
        desc:SetSpacing(2)
        local h = 60
        if desc.GetStringHeight then
            local ok, measured = pcall(desc.GetStringHeight, desc)
            if ok and type(measured) == "number" and measured > 0 then h = math.ceil(measured) + 6 end
        end
        addRow(h + 4)
    end

    for _, rowDef in ipairs(def.rows or {}) do
        local indent = rowDef.indent or 0
        if rowDef.type == "check" then
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + indent, y)
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            cb:SetChecked(PigSet[rowDef.var] == true)
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95, 220)
            label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            cb:SetScript("OnClick", function(self)
                PigSet[rowDef.var] = self:GetChecked() and true or false
                WB.SyncCheckbox(rowDef.var)
            end)
            rows[#rows + 1] = { kind = "check", row = rowDef, control = cb }
            addRow(26)
        elseif rowDef.type == "slider" then
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95, 110)
            label:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + indent, y - 2)
            local slider = CreateFrame("Slider", nil, f)
            slider:SetOrientation("HORIZONTAL")
            slider:SetSize(110, 10)
            slider:SetPoint("LEFT", label, "RIGHT", 8, 0)
            slider:SetMinMaxValues(rowDef.minv or 0, rowDef.maxv or 100)
            slider:SetValueStep(rowDef.step or 1)
            slider:SetObeyStepOnDrag(true)
            slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
            local thumb = slider:GetThumbTexture()
            if thumb then thumb:SetSize(6, 14); thumb:SetVertexColor(0.82, 0.84, 0.87, 1) end
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            local val = WB.Num(PigSet[rowDef.var], rowDef.default or 0)
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
        elseif rowDef.type == "cslider" then
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + indent, y)
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            cb:SetChecked(PigSet[rowDef.var] == true)
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95, 150)
            label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            cb:SetScript("OnClick", function(self)
                PigSet[rowDef.var] = self:GetChecked() and true or false
                WB.SyncCheckbox(rowDef.var)
            end)
            local slider = CreateFrame("Slider", nil, f)
            slider:SetOrientation("HORIZONTAL")
            slider:SetSize(80, 10)
            slider:SetPoint("TOPLEFT", f, "TOPLEFT", width - 150, y - 5)
            slider:SetMinMaxValues(rowDef.minv or 0, rowDef.maxv or 100)
            slider:SetValueStep(rowDef.step or 1)
            slider:SetObeyStepOnDrag(true)
            slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
            local thumb = slider:GetThumbTexture()
            if thumb then thumb:SetSize(6, 14); thumb:SetVertexColor(0.82, 0.84, 0.87, 1) end
            if PigSet[rowDef.pvar] == nil then PigSet[rowDef.pvar] = rowDef.pdefault end
            local val = WB.Num(PigSet[rowDef.pvar], rowDef.pdefault or 0)
            slider:SetValue(val)
            local valText = MakeFont(f, tostring(val) .. (rowDef.suffix or ""), 12, 0.62, 0.65, 0.69, 46)
            valText:SetPoint("LEFT", slider, "RIGHT", 6, 0)
            local function update(v)
                v = math.floor((v or 0) + 0.5)
                PigSet[rowDef.pvar] = v
                valText:SetText(tostring(v) .. (rowDef.suffix or ""))
            end
            update(val)
            slider:SetScript("OnValueChanged", function(self, v) update(v) end)
            rows[#rows + 1] = { kind = "cslider", row = rowDef, control = cb, slider = slider, valText = valText }
            addRow(27)
        end
    end

    local contentH = math.abs(y) + 12
    f:SetHeight(math.max(100, contentH + 18))
    f.rows = rows
    f.defKey = key

    function f:Refresh()
        for _, rec in ipairs(self.rows or {}) do
            if rec.kind == "check" then
                rec.control:SetChecked(PigSet[rec.row.var] == true)
            elseif rec.kind == "slider" then
                local v = WB.Num(PigSet[rec.row.var], rec.row.default or 0)
                rec.control:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            elseif rec.kind == "cslider" then
                rec.control:SetChecked(PigSet[rec.row.var] == true)
                local v = WB.Num(PigSet[rec.row.pvar], rec.row.pdefault or 0)
                rec.slider:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            end
        end
    end
    return f
end

WB.PopupCache = WB.PopupCache or {}

function WB.ShowOptions(key)
    WB.InitDefaults()
    local def = WB.PopupDefs[key]
    if not def then return end
    local f = WB.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        WB.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(WB.PopupCache) do
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
-- 20. 爆发按钮（面板 onClick）
-- ============================================================
function WR_DruidBalanceBurstAllOn()
    if type(PigSet) ~= "table" then return end
    PigSet.PH_ZDZZ = true
    WB.SyncCheckbox("PH_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cff00ff00[平衡]|r 爆发已全部打开") end
end

function WR_DruidBalanceBurstAllOff()
    if type(PigSet) ~= "table" then return end
    PigSet.PH_ZDZZ = false
    WB.SyncCheckbox("PH_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cffff5040[平衡]|r 爆发已全部关闭") end
end

function WR_DruidBalanceBurstToggle()
    if type(PigSet) ~= "table" then return end
    if PigSet.PH_ZDZZ == true then
        WR_DruidBalanceBurstAllOff()
    else
        WR_DruidBalanceBurstAllOn()
    end
end

-- ============================================================
-- 21. 斜杠命令：/DRUID_DOT /DRUID_INNERVATE /DRUID_THORNS /DRUID_MARK
-- ============================================================
local function ToggleSwitch(var, label)
    if type(PigSet) ~= "table" then return end
    PigSet[var] = not (PigSet[var] == true)
    WB.SyncCheckbox(var)
    print("|cff00ff00[" .. label .. "]|r " .. (PigSet[var] and "开启" or "关闭"))
end

SLASH_DRUID_DOT1 = "/DRUID_DOT"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_DOT"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.PH_DOT = true; WB.SyncCheckbox("PH_DOT")
        elseif msg == "off" then PigSet.PH_DOT = false; WB.SyncCheckbox("PH_DOT")
        else ToggleSwitch("PH_DOT", "DOT") end
    end
end

SLASH_DRUID_INNERVATE1 = "/DRUID_INNERVATE"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_INNERVATE"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.PH_JH_ON = true; WB.SyncCheckbox("PH_JH_ON")
        elseif msg == "off" then PigSet.PH_JH_ON = false; WB.SyncCheckbox("PH_JH_ON")
        else ToggleSwitch("PH_JH_ON", "激活") end
    end
end

SLASH_DRUID_THORNS1 = "/DRUID_THORNS"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_THORNS"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.PH_JJS = true; WB.SyncCheckbox("PH_JJS")
        elseif msg == "off" then PigSet.PH_JJS = false; WB.SyncCheckbox("PH_JJS")
        else ToggleSwitch("PH_JJS", "荆棘术") end
    end
end

SLASH_DRUID_MARK1 = "/DRUID_MARK"
if type(SlashCmdList) == "table" then
    SlashCmdList["DRUID_MARK"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.PH_YXYZ = true; WB.SyncCheckbox("PH_YXYZ")
        elseif msg == "off" then PigSet.PH_YXYZ = false; WB.SyncCheckbox("PH_YXYZ")
        else ToggleSwitch("PH_YXYZ", "野性印记") end
    end
end
