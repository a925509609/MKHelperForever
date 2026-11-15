-- ============================================================
-- Warlock_Demonology_Features.lua
-- 恶魔术（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 WARLOCK「恶魔学识」专精：不写全局、不影响痛苦/毁灭与其他职业。
-- 共享件 Warlock_Forever.lua（痛苦/毁灭在用）零改动。
--
-- 按「猪猪-无限服 · 恶魔术页」截图逐项落地：
-- 功能：DOT（右键）/ 读条引导（右键）/ 切换目标 /
--       护甲（右键：恶魔皮肤/魔甲术）/ 召唤宠物（右键：4宠物多选）
-- 拉条：生命分流 / 高血分流 / 喝红药 / 魔杖回蓝
-- 爆发：种族爆（全开/全关/切换按钮）
-- 插入：死亡缠绕 / 恐惧术 / 恐惧嚎叫 / 地狱烈焰 / 火焰之雨 /
--       生命通道 / 生命分流（一次性，放完自关）
--
-- 【本服真实技能（60级法术书 DungeonsForeverSpell 口径）】
-- 腐蚀术 172 / 献祭 348 / 生命虹吸 18265(痛苦天赋) /
-- 痛苦灾祸 980 / 末日灾祸 603(60级) /
-- 元素诅咒 440892 / 虚弱诅咒 702 / 鲁莽诅咒 704 / 语言诅咒 1714 /
-- 疲劳诅咒 18223(痛苦天赋) /
-- 吸取灵魂 1120 / 吸取生命 689 / 灵魂之火 6353 / 灼热之痛 5676 /
-- 暗影箭 686 / 恶魔皮肤 687 / 魔甲术 706 / 生命通道 755 / 生命分流 1454 /
-- 死亡缠绕 6789 / 恐惧术 5782 / 恐惧嚎叫 5484 / 地狱烈焰 1949 /
-- 火焰之雨 11678 / 召唤小鬼 688 / 虚空行者 697 / 魅魔 712 / 地狱猎犬 691
-- ★ 80级/外服技能（恶魔变形/邪甲术/召唤恶魔卫士/腐蚀之种/痛苦诅咒/
--   厄运诅咒/灵魂碎裂）本服 60 级不存在，本层不再引用（诅咒系已改名「灾祸」）。
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

WR_WarlockDemo = WR_WarlockDemo or {}
local WD = WR_WarlockDemo

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ============================================================
WD.Defaults = {
    -- DOT 窗
    SS_EM_DOT = true,             -- DOT 总开关
    SS_EM_DOT_FSS = true,         -- 腐蚀术
    SS_EM_DOT_FSS_TTD = 6,        --   预判：目标还能活 > 6 秒才上
    SS_EM_DOT_XJ = true,          -- 献祭
    SS_EM_DOT_XJ_TTD = 8,
    SS_EM_DOT_SMHX = false,       -- 生命虹吸（痛苦系天赋）
    SS_EM_DOT_SMHX_TTD = 0,
    SS_EM_BANE_ON = true,         -- 灾祸类总开关
    SS_EM_BANE_KIND = 1,          --   1=痛苦灾祸 2=末日灾祸
    SS_EM_BANE_TTD = 12,          --   预判 12 秒
    SS_EM_CURSE_ON = false,       -- 诅咒类总开关
    SS_EM_CURSE_KIND = 1,         --   1元素 2虚弱 3鲁莽 4语言 5疲劳
    SS_EM_CURSE_TTD = 0,          --   预判（0=都放）
    -- 读条引导窗
    SS_EM_CAST = true,            -- 读条引导总开关
    SS_EM_DS = false,             -- 吸取灵魂
    SS_EM_DS_HP = 0,              --   目标血量低于 X% 才吸（0=关闭）
    SS_EM_XSM = false,            -- 吸取生命
    SS_EM_XSM_HP = 10,            --   自己血量低于 10% 自保
    SS_EM_LHZH = true,            -- 灵魂之火
    SS_EM_LHZH_HP = 50,           --   目标血量低于 50%
    SS_EM_ZRZT = true,            -- 灼热之痛
    SS_EM_AYJ = true,             -- 暗影箭填充
    -- 护甲 / 召唤 / 功能
    SS_EM_ARMOR = true,           -- 护甲总开关
    SS_EM_ARMOR_KIND = 1,         --   1=恶魔皮肤 2=魔甲术
    SS_EM_SUMMON = true,          -- 召唤宠物总开关
    SS_EM_SUM_IMP = true,         --   小鬼
    SS_EM_SUM_VW = false,         --   虚空行者
    SS_EM_SUM_SU = false,         --   魅魔
    SS_EM_SUM_FH = false,         --   地狱猎犬
    SS_EM_TAB = true,             -- 切换目标
    SS_EM_ZDZZ = true,            -- 种族爆
    -- 拉条
    SS_EM_LTFL = 30,              -- 生命分流：蓝低于 30%
    SS_EM_GXFL = 80,              -- 高血分流：血高于 80%
    SS_EM_HHY = 30,               -- 喝红药：血低于 30%
    SS_EM_MZHL = 50,              -- 魔杖回蓝：蓝低于 50%
    -- 插入（一次性，放完自关）
    SS_EM_CRSWCR = false,         -- 死亡缠绕
    SS_EM_CRKJ = false,           -- 恐惧术
    SS_EM_CRKJHJ = false,         -- 恐惧嚎叫
    SS_EM_CRDYLY = false,         -- 地狱烈焰
    SS_EM_CRHYZY = false,         -- 火焰之雨
    SS_EM_CRSMTD = false,         -- 生命通道
    SS_EM_CRLTFL = false,         -- 生命分流
}

WD.Migrated = WD.Migrated or false

function WD.InitDefaults()
    if type(PigSet) ~= "table" then return end
    for k, v in pairs(WD.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
    if not WD.Migrated then
        WD.Migrated = true
        -- 旧档迁移：SS_EM_HJ（1邪甲 2魔甲 3禁用）→ 新护甲 radio
        if PigSet.SS_EM_HJ ~= nil then
            local sel = tonumber(PigSet.SS_EM_HJ)
            if sel == 2 then
                PigSet.SS_EM_ARMOR_KIND = 2
            elseif sel == 3 then
                PigSet.SS_EM_ARMOR = false
            else
                PigSet.SS_EM_ARMOR_KIND = 1   -- 邪甲术本服不存在 → 回退恶魔皮肤
            end
        end
        -- 旧档迁移：SS_EM_AUTOSUMMON（2小鬼 3虚空 4魅魔 5地狱猎犬 6恶魔卫士）→ 多选勾
        local oldSummon = tonumber(PigSet.SS_EM_AUTOSUMMON)
        if oldSummon and oldSummon >= 2 then
            local map = {
                [2] = "SS_EM_SUM_IMP", [3] = "SS_EM_SUM_VW",
                [4] = "SS_EM_SUM_SU",  [5] = "SS_EM_SUM_FH",
            }
            local k = map[oldSummon]
            if k then
                PigSet.SS_EM_SUMMON = true
                PigSet[k] = true
            end
        end
    end
end

-- ============================================================
-- 2. 小工具
-- ============================================================
function WD.Num(v, d)
    local n = tonumber(v)
    if type(n) == "number" then return n end
    return d
end

function WD.Bool(v, d)
    if v == true then return true end
    if v == false then return false end
    return d
end

function WD.On(var, default)
    if type(PigSet) ~= "table" then return default == true end
    return WD.Bool(PigSet[var], default)
end

function WD.Val(var, default)
    if type(PigSet) ~= "table" then return default end
    return WD.Num(PigSet[var], default)
end

function WD.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
end

function WD.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, known = pcall(WR_Forever_IsSpellKnown, name)
        if ok then return known == true end
    end
    return true
end

function WD.Show(spell, slot)
    if WR_ColorFrame_ShowSkill ~= nil then
        return WR_ColorFrame_ShowSkill(spell, slot) == true
    end
    return false
end

-- ============================================================
-- 3. 循环：基础变量 / 停手门
-- ============================================================
function WD.Base()
    GCD = WR_GetGCD("暗影箭")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    WD.TargetOK = UnitExists("target")
        and not UnitIsDeadOrGhost("target")
        and UnitCanAttack("player", "target")
    WD.InRange = (TargetRange ~= nil and TargetRange <= 35)
    WD.Casting = WR_SafeCastingName("player")
    WD.Channel = WR_SafeChannelName("player")
end

-- 引导类技能 → 色块槽位（引导中要熄灭自己的槽，否则 AHK 连按会打断引导）
WD.ChannelSlots = {
    ["吸取灵魂"] = 11,
    ["吸取生命"] = 86,
}

function WD.StopGate()
    local ch = WD.Channel
    if ch and WD.ChannelSlots[ch] then
        -- ★ nil 判定而非 type()=="function"（仓库老坑：跨文件可调用对象可能是 userdata）
        if WR_HideSkillColorSlot ~= nil then
            WR_HideSkillColorSlot(ch, WD.ChannelSlots[ch])
        end
        return true
    end

    local stop = UnitIsDeadOrGhost("player")
        or (IsMounted and IsMounted())
        or (UnitInVehicle and UnitInVehicle("player"))
    if not stop then
        local eatDrink = { "喝水", "进食", "饮用", "食物", "饮料", "饮水" }
        if WR_GetUnitBuffTime("player", eatDrink, nil, "NAME") > 0 then stop = true end
    end
    if stop then
        local lastShown = WR_SoD_ShownSkill
        if type(lastShown) == "string" and lastShown ~= ""
           and WR_HideSkillColorSlot ~= nil then
            WR_HideSkillColorSlot(lastShown, nil)
        end
        return true
    end
    return false
end

-- ============================================================
-- 4. 插入段：一次性（施放成功自关，3 秒超时兜底）
-- ============================================================
WD.PendingInsert = WD.PendingInsert or {}

function WD.InsertStep()
    local now = GetTime()
    -- 先回收已施放成功的 pending（施法成功信号 = WR_Forever_LastPlayerCast）
    local last = WR_Forever_LastPlayerCast
    for key, rec in pairs(WD.PendingInsert) do
        if last and last.spellName == rec.spell and last.time >= rec.since then
            PigSet[key] = false
            WD.PendingInsert[key] = nil
            WD.SyncCheckbox(key)
        elseif now > rec.deadline then
            WD.PendingInsert[key] = nil
        end
    end

    local list = {
        { key = "SS_EM_CRSWCR", spell = "死亡缠绕", slot = 102, needTarget = true },
        { key = "SS_EM_CRKJ",   spell = "恐惧术",   slot = 103, needTarget = true },
        { key = "SS_EM_CRKJHJ", spell = "恐惧嚎叫", slot = 104, needTarget = false },
        { key = "SS_EM_CRDYLY", spell = "地狱烈焰", slot = 77,  needTarget = false },
        { key = "SS_EM_CRHYZY", spell = "火焰之雨", slot = 76,  needTarget = false },
        { key = "SS_EM_CRSMTD", spell = "生命通道", slot = 105, needTarget = false },
        { key = "SS_EM_CRLTFL", spell = "生命分流", slot = 10,  needTarget = false },
    }
    for _, it in ipairs(list) do
        if PigSet[it.key] == true then
            if (not it.needTarget) or WD.TargetOK then
                if WR_SpellUsable ~= nil then
                    local ok, usable = pcall(WR_SpellUsable, it.spell, true)
                    if ok and usable == true then
                        if WD.Show(it.spell, it.slot) then
                            WD.PendingInsert[it.key] = {
                                spell = it.spell, since = now, deadline = now + 3,
                            }
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- ============================================================
-- 5. 自保：喝红药（先治疗石后治疗药水）
-- ============================================================
function WD.SelfPreserve()
    if PlayerHP < WD.Val("SS_EM_HHY", 30) / 100 then
        if WR_Use_ZLS ~= nil then
            local ok, can = pcall(WR_Use_ZLS)
            if ok and can == true then
                if WD.Show("邪能治疗石", 35) then return true end
            end
        end
        if WR_Use_ZLYS ~= nil then
            local ok, can = pcall(WR_Use_ZLYS)
            if ok and can == true then
                if WD.Show("治疗药水", 106) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 6. 护甲：恶魔皮肤 / 魔甲术 二选一；战斗内外都补
-- ============================================================
function WD.ArmorStep()
    if not WD.On("SS_EM_ARMOR", true) then return false end
    local want, slot
    if WD.Val("SS_EM_ARMOR_KIND", 1) == 2 then
        want, slot = "魔甲术", 9
    else
        want, slot = "恶魔皮肤", 93
    end
    if WR_GetUnitBuffTime("player", want) == 0 then
        if WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, want, true)
            if ok and usable == true then
                if WD.Show(want, slot) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 7. 召唤宠物：脱战+静止+无宠物 → 按勾选优先级召唤
--    （复用 BExt：内含 读条/骑乘/吃喝/重复召唤 门）
-- ============================================================
function WD.SummonStep()
    if not WD.On("SS_EM_SUMMON", true) then return false end
    -- 恶魔牺牲流派：牺牲 buff 在身不召唤
    if WR_GetUnitBuffTime("player", "恶魔牺牲") > 0 then return false end
    if UnitExists("pet") and not UnitIsDeadOrGhost("pet") then return false end
    local sel
    if WD.On("SS_EM_SUM_IMP", true) then
        sel = 2
    elseif WD.On("SS_EM_SUM_VW", false) then
        sel = 3
    elseif WD.On("SS_EM_SUM_SU", false) then
        sel = 4
    elseif WD.On("SS_EM_SUM_FH", false) then
        sel = 5
    end
    if not sel then return false end
    if WR_WarlockAutoSummonPet_BExt == nil then return false end
    local ok, done = pcall(WR_WarlockAutoSummonPet_BExt, sel)
    return ok and done == true
end

-- ============================================================
-- 8. 切目标：目标死亡/不存在/不可攻击 + 战斗中（防抖 1 秒）
-- ============================================================
WD.LastTab = WD.LastTab or 0

function WD.TabStep()
    if not WD.On("SS_EM_TAB", true) then return false end
    if not UnitAffectingCombat("player") then return false end
    if WD.TargetOK then return false end
    if WR_CanTab ~= nil and not WR_CanTab() then return false end
    local now = GetTime()
    if now - WD.LastTab < 1.0 then return false end
    if WD.Show("切目标", 56) then
        WD.LastTab = now
        return true
    end
    return false
end

-- ============================================================
-- 9. 战斗门（防ADD）：FANG_ADD_EMS 1=是 2=否
-- ============================================================
function WD.CombatGate()
    local preventAdd = (WD.Val("FANG_ADD_EMS", 1) == 1)
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
-- 10. 爆发：种族爆（种族爆发技能任一可用即点亮全家桶宏槽 8）
-- ============================================================
function WD.BurstStep()
    if not WD.On("SS_EM_ZDZZ", true) then return false end
    if WR_Forever_PlayerRacialBursts == nil then return false end
    local okB, bursts = pcall(WR_Forever_PlayerRacialBursts)
    if not okB or type(bursts) ~= "table" then return false end
    for i = 1, #bursts do
        local name = bursts[i]
        if type(name) == "string" and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, name, true)
            if ok and usable == true then
                if WD.Show("种族爆发", 8) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 11. 拉条：生命分流（蓝低于）/ 高血分流（血高于、蓝未满）
-- ============================================================
function WD.ManaStep()
    if PlayerMove or WD.Casting or WD.Channel then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "生命分流")
        if ok and usable == true then
            -- 蓝低于拉条（保命下限：血 > 40% 才分）
            if PlayerMP < WD.Val("SS_EM_LTFL", 30) / 100 and PlayerHP > 0.40 then
                if WD.Show("生命分流", 10) then return true end
            end
            -- 高血分流：血量富余时主动换蓝（血高于拉条、蓝低于 60%）
            if PlayerHP >= WD.Val("SS_EM_GXFL", 80) / 100 and PlayerMP < 0.60 then
                if WD.Show("生命分流", 10) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 12. DOT：腐蚀术 / 献祭 / 生命虹吸 + 灾祸(2选1) + 诅咒(5选1)
--     只补「自己的」（ByMe）；预判 = 目标还能活 > X 秒才上（0=都放）
-- ============================================================
-- 槽位 = WR_SkillColor["WARLOCK"] 职业槽（1-199）；2026-11-15 全部改绑已填实的空槽宏。
WD.CURSES = {
    [1] = { name = "元素诅咒", slot = 94 },
    [2] = { name = "虚弱诅咒", slot = 95 },
    [3] = { name = "鲁莽诅咒", slot = 96 },
    [4] = { name = "语言诅咒", slot = 101 },
    [5] = { name = "疲劳诅咒", slot = 109, talent = true },
}

function WD.DotStep()
    if not WD.On("SS_EM_DOT", true) then return false end
    if not WD.TargetOK or not WD.InRange then return false end
    if WR_CanDot ~= nil and not WR_CanDot("target") then return false end
    if WR_IsBlacklisted ~= nil and WR_IsBlacklisted("target") then return false end
    local T = TargetDeathTime or 0

    local dts = {
        { on = "SS_EM_DOT_FSS",  ttd = "SS_EM_DOT_FSS_TTD",  dft = 6, name = "腐蚀术",   slot = 41 },  -- 41=SHIFT-F1 本体宏（槽14 是焦点宏，勿用于当前目标）
        { on = "SS_EM_DOT_XJ",   ttd = "SS_EM_DOT_XJ_TTD",   dft = 8, name = "献祭",     slot = 36 },
        { on = "SS_EM_DOT_SMHX", ttd = "SS_EM_DOT_SMHX_TTD", dft = 0, name = "生命虹吸", slot = 81, talent = true },
    }
    for _, d in ipairs(dts) do
        if WD.On(d.on, true) then
            local need = WD.Val(d.ttd, d.dft)
            if (need <= 0 or T > need)
               and (d.talent ~= true or WD.SpellKnown(d.name))
               and WR_GetUnitDebuffTime("target", d.name, true) == 0
               and WR_SpellUsable ~= nil then
                local ok, usable = pcall(WR_SpellUsable, d.name, true)
                if ok and usable == true then
                    if WD.Show(d.name, d.slot) then return true end
                end
            end
        end
    end

    -- 灾祸 2 选 1：目标身上没有「自己的那一种」就补
    if WD.On("SS_EM_BANE_ON", true) then
        local kind = WD.Val("SS_EM_BANE_KIND", 1)
        local bane, slot
        if kind == 2 then
            bane, slot = "末日灾祸", 108
        else
            bane, slot = "痛苦灾祸", 107
        end
        local ttdNeed = WD.Val("SS_EM_BANE_TTD", 12)
        if kind == 2 and ttdNeed < 60 then ttdNeed = 60 end   -- 末日灾祸一跳 60 秒
        if (ttdNeed <= 0 or T > ttdNeed)
           and WR_GetUnitDebuffTime("target", bane, true) == 0
           and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, bane, true)
            if ok and usable == true then
                if WD.Show(bane, slot) then return true end
            end
        end
    end

    -- 诅咒 5 选 1
    if WD.On("SS_EM_CURSE_ON", false) then
        local rec = WD.CURSES[WD.Val("SS_EM_CURSE_KIND", 1)] or WD.CURSES[1]
        local ttdNeed = WD.Val("SS_EM_CURSE_TTD", 0)
        if (ttdNeed <= 0 or T > ttdNeed)
           and (rec.talent ~= true or WD.SpellKnown(rec.name))
           and WR_GetUnitDebuffTime("target", rec.name, true) == 0
           and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, rec.name, true)
            if ok and usable == true then
                if WD.Show(rec.name, rec.slot) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 13. 读条引导：吸取灵魂 / 吸取生命（引导）→
--     灵魂之火 / 灼热之痛 / 暗影箭（读条，从上到下就是先后）
-- ============================================================
function WD.CastStep()
    if not WD.On("SS_EM_CAST", true) then return false end
    if not WD.TargetOK or not WD.InRange then return false end
    if WD.Casting or WD.Channel then return false end
    local T = TargetDeathTime or 0

    -- 引导：吸取灵魂（目标血量低于 X% 才吸，0 = 关闭）
    if WD.On("SS_EM_DS", false) then
        local hpNeed = WD.Val("SS_EM_DS_HP", 0)
        if hpNeed > 0 and WR_SafeHPPct("target") < hpNeed / 100 and T > 5
           and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, "吸取灵魂", true)
            if ok and usable == true then
                if WD.Show("吸取灵魂", 11) then return true end
            end
        end
    end

    -- 引导：吸取生命（自己血量低于 X% 自保回血）
    if WD.On("SS_EM_XSM", false) then
        local hpNeed = WD.Val("SS_EM_XSM_HP", 10)
        if hpNeed > 0 and PlayerHP < hpNeed / 100
           and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, "吸取生命", true)
            if ok and usable == true then
                if WD.Show("吸取生命", 86) then return true end
            end
        end
    end

    -- 读条：灵魂之火（目标血量低于 X%）
    if WD.On("SS_EM_LHZH", true) then
        local hpNeed = WD.Val("SS_EM_LHZH_HP", 50)
        if WR_SafeHPPct("target") < hpNeed / 100
           and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, "灵魂之火", true)
            if ok and usable == true then
                if WD.Show("灵魂之火", 38) then return true end
            end
        end
    end

    -- 读条：灼热之痛（已学会才用）
    if WD.On("SS_EM_ZRZT", true) and not PlayerMove
       and WD.SpellKnown("灼热之痛")
       and WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "灼热之痛", true)
        if ok and usable == true then
            if WD.Show("灼热之痛", 92) then return true end
        end
    end

    -- 填充：暗影箭
    if WD.On("SS_EM_AYJ", true) and not PlayerMove
       and WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "暗影箭", true)
        if ok and usable == true then
            if WD.Show("暗影箭", 6) then return true end
        end
    end
    return false
end

-- ============================================================
-- 14. 魔杖回蓝兜底：蓝低于拉条且本 tick 无技能可打 → /startattack(190)
-- ============================================================
function WD.WandStep()
    if PlayerMP >= WD.Val("SS_EM_MZHL", 50) / 100 then return false end
    if not WD.TargetOK then return false end
    if not (TargetRange and TargetRange <= 30) then return false end
    if WD.Casting or WD.Channel then return false end
    if WD.Show("魔杖射击", 190) then return true end
    return false
end

-- ============================================================
-- 15. 收尾清扫：本 tick 未点亮任何色块时熄灭上一 tick 的残留
-- ============================================================
function WD.Sweep()
    if WR_SoD_ShownTick == WR_SoD_TickSeq then return end
    local lastShown = WR_SoD_ShownSkill
    if type(lastShown) ~= "string" or lastShown == "" then return end
    if WR_HideSkillColorSlot ~= nil then
        WR_HideSkillColorSlot(lastShown, nil)
    end
    WR_SoD_ShownSkill = nil
end

-- ============================================================
-- 16. 主循环：插入 → 自保 → 护甲 → 召唤 → 切目标 → 战斗门 →
--     爆发 → 拉条 → DOT → 读条引导 → 魔杖 → 清扫
-- ============================================================
function WD.Run()
    WD.InitDefaults()
    local handled = false
    repeat
        WD.Base()
        if WD.StopGate() then break end
        if WD.InsertStep() then handled = true; break end
        if WD.SelfPreserve() then handled = true; break end
        if WD.ArmorStep() then handled = true; break end
        if WD.SummonStep() then handled = true; break end
        if WD.TabStep() then handled = true; break end
        if not WD.CombatGate() then break end
        if WD.BurstStep() then handled = true; break end
        if WD.ManaStep() then handled = true; break end
        if WD.DotStep() then handled = true; break end
        if WD.CastStep() then handled = true; break end
        if WD.WandStep() then handled = true; break end
    until true
    if not handled then WD.Sweep() end
    return handled
end

-- ============================================================
-- 17. 右键「额外条件」小窗
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

WD.PopupDefs = {
    SS_EM_DOT = {
        title = "DOT  功能",
        width = 400,
        desc = "开着时按右键里的设置给目标上 DOT。\n\n"
            .. "灾祸和诅咒：目标身上没有「自己的那一种」就补。\n"
            .. "腐蚀术、献祭、生命虹吸：勾上才放。\n"
            .. "灾祸（痛苦/末日）2选1、诅咒（元素/虚弱/鲁莽/语言/疲劳）5选1；"
            .. "「灾祸」「诅咒」前面的勾是这一类的总开关，去掉 = 这一类不放。\n\n"
            .. "预判 = 目标预计还能活 > 这么多秒才上（0 = 都放）。\n\n"
            .. "关掉后右键里的 DOT、灾祸和诅咒一个都不上。\n"
            .. "宏：/WARLOCKDOT 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "cslider", var = "SS_EM_DOT_FSS", pvar = "SS_EM_DOT_FSS_TTD", pdefault = 6, label = "腐蚀术", default = true, suffix = "秒", minv = 0, maxv = 30 },
            { type = "cslider", var = "SS_EM_DOT_XJ", pvar = "SS_EM_DOT_XJ_TTD", pdefault = 8, label = "献祭", default = true, suffix = "秒", minv = 0, maxv = 30 },
            { type = "cslider", var = "SS_EM_DOT_SMHX", pvar = "SS_EM_DOT_SMHX_TTD", pdefault = 0, label = "生命虹吸（痛苦天赋）", default = false, suffix = "秒", minv = 0, maxv = 30 },
            { type = "check", var = "SS_EM_BANE_ON", label = "灾祸", default = true },
            { type = "radio", var = "SS_EM_BANE_KIND", default = 1, perRow = 2, indent = 18,
              options = { { id = 1, name = "痛苦灾祸" }, { id = 2, name = "末日灾祸" } } },
            { type = "slider", var = "SS_EM_BANE_TTD", label = "预判", default = 12, suffix = "秒", minv = 0, maxv = 60, indent = 18 },
            { type = "check", var = "SS_EM_CURSE_ON", label = "诅咒", default = false },
            { type = "radio", var = "SS_EM_CURSE_KIND", default = 1, perRow = 3, indent = 18,
              options = {
                  { id = 1, name = "元素诅咒" }, { id = 2, name = "虚弱诅咒" }, { id = 3, name = "鲁莽诅咒" },
                  { id = 4, name = "语言诅咒" }, { id = 5, name = "疲劳诅咒" },
              } },
            { type = "slider", var = "SS_EM_CURSE_TTD", label = "预判", default = 0, suffix = "秒", minv = 0, maxv = 60, indent = 18 },
        },
    },
    SS_EM_CAST = {
        title = "读条引导  功能",
        width = 380,
        desc = "开着时按右键里勾上的技能放引导、读条类技能。\n\n"
            .. "引导类：吸取灵魂、吸取生命；读条类从上到下就是先后：灵魂之火、灼热之痛，最后用暗影箭填充。\n"
            .. "「引导」「读条」前面的勾是这一类的总开关。\n\n"
            .. "名字后面的灰字 = 要点哪一系的天赋才有，没学会的勾了也放不出来。\n"
            .. "吸取灵魂的「血量」= 目标血量低于该百分比才吸（0 = 关闭）；"
            .. "吸取生命的「血量」= 自己血量低于该百分比才吸。\n\n"
            .. "关掉后右键里的引导、读条技能一个都不放（只剩瞬发技能和魔杖）。\n"
            .. "宏：/WARLOCKCAST 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "header", text = "引导" },
            { type = "cslider", var = "SS_EM_DS", pvar = "SS_EM_DS_HP", pdefault = 0, label = "吸取灵魂", default = false, suffix = "%", minv = 0, maxv = 100 },
            { type = "cslider", var = "SS_EM_XSM", pvar = "SS_EM_XSM_HP", pdefault = 10, label = "吸取生命", default = false, suffix = "%", minv = 0, maxv = 100 },
            { type = "header", text = "读条" },
            { type = "cslider", var = "SS_EM_LHZH", pvar = "SS_EM_LHZH_HP", pdefault = 50, label = "灵魂之火", default = true, suffix = "%", minv = 0, maxv = 100 },
            { type = "check", var = "SS_EM_ZRZT", label = "灼热之痛", default = true },
            { type = "check", var = "SS_EM_AYJ", label = "暗影箭（填充）", default = true },
        },
    },
    SS_EM_SUMMON = {
        title = "召唤宠物  功能",
        width = 340,
        desc = "开着时，脱战、站着不动、身边没有宠物（没召唤/死了）就自动召唤右键里选中的那一种（小鬼/虚空行者/魅魔/地狱猎犬 多选，按顺序优先）。\n\n"
            .. "战斗中不召唤（读条 10 秒）；骑马、吃喝时不召唤。\n"
            .. "点了恶魔牺牲、要把宠物献祭掉的，把这个开关关掉（身上有恶魔牺牲 buff 时也不会召唤）。\n\n"
            .. "关掉后不再自动召唤宠物。\n"
            .. "宏：/WARLOCKSUMMON 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "check", var = "SS_EM_SUM_IMP", label = "小鬼", default = true },
            { type = "check", var = "SS_EM_SUM_VW", label = "虚空行者", default = false },
            { type = "check", var = "SS_EM_SUM_SU", label = "魅魔", default = false },
            { type = "check", var = "SS_EM_SUM_FH", label = "地狱猎犬", default = false },
        },
    },
    SS_EM_ARMOR = {
        title = "护甲  功能",
        width = 340,
        desc = "开着时，自己身上没有右键里选中的那种甲就自动补上（恶魔皮肤/魔甲术 二选一）；战斗内外都补。\n\n"
            .. "关掉后不再自动补甲。\n"
            .. "宏：/WARLOCKARMOR 切换（后面加 on 开、off 关）",
        rows = {
            { type = "header", text = "- 额外条件" },
            { type = "radio", var = "SS_EM_ARMOR_KIND", default = 1, perRow = 2,
              options = { { id = 1, name = "恶魔皮肤" }, { id = 2, name = "魔甲术" } } },
        },
    },
}

local function BuildPopup(key)
    local def = WD.PopupDefs[key]
    if not def then return nil end
    local width = def.width or 360
    local f = CreateFrame("Frame", "WR_WarlockDemoPopup_" .. key, UIParent, "BackdropTemplate")
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
        if rowDef.type == "header" then
            local h = MakeFont(f, rowDef.text or "", 12, 1, 0.65, 0.2)
            h:SetPoint("TOPLEFT", f, "TOPLEFT", 12 + indent, y - 3)
            addRow(20)
        elseif rowDef.type == "check" then
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + indent, y)
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
            local val = WD.Num(PigSet[rowDef.var], rowDef.default or 0)
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
            -- 勾选 + 右侧滑条
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + indent, y)
            if PigSet[rowDef.var] == nil then PigSet[rowDef.var] = rowDef.default end
            cb:SetChecked(PigSet[rowDef.var] == true)
            local label = MakeFont(f, rowDef.label or rowDef.var, 12, 0.92, 0.93, 0.95, 150)
            label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            cb:SetScript("OnClick", function(self)
                PigSet[rowDef.var] = self:GetChecked() and true or false
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
            local val = WD.Num(PigSet[rowDef.pvar], rowDef.pdefault or 0)
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
        elseif rowDef.type == "radio" then
            local buttons = {}
            local perRow = rowDef.perRow or 2
            local optCount = #(rowDef.options or {})
            local lineCount = math.ceil(optCount / perRow)
            local startX = 14 + indent
            for i, opt in ipairs(rowDef.options or {}) do
                local col = (i - 1) % perRow
                local line = math.floor((i - 1) / perRow)
                local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
                btn:SetSize(84, 21)
                btn:SetPoint("TOPLEFT", f, "TOPLEFT", startX + col * 88, y - line * 24)
                if btn.SetBackdrop then
                    btn:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8X8",
                        edgeFile = "Interface\\Buttons\\WHITE8X8",
                        edgeSize = 1,
                    })
                end
                if btn.SetBackdropColor then
                    btn:SetBackdropColor(0.12, 0.13, 0.15, 0.9)
                    btn:SetBackdropBorderColor(0.18, 0.20, 0.23, 1)
                end
                local txt = MakeFont(btn, opt.name, 11, 0.85, 0.85, 0.85)
                txt:SetPoint("CENTER", btn, "CENTER", 0, 0)
                btn:SetScript("OnClick", function()
                    PigSet[rowDef.var] = opt.id
                    for _, b in ipairs(buttons) do
                        local on = (tonumber(PigSet[rowDef.var]) == b.id)
                        if b.btn.SetBackdropColor then
                            if on then b.btn:SetBackdropColor(0.35, 0.27, 0.10, 1)
                            else b.btn:SetBackdropColor(0.12, 0.13, 0.15, 0.9) end
                        end
                        b.txt:SetTextColor(on and 1 or 0.65, on and 0.82 or 0.65, on and 0.2 or 0.65)
                    end
                end)
                buttons[#buttons + 1] = { btn = btn, txt = txt, id = opt.id }
            end
            rows[#rows + 1] = { kind = "radio", row = rowDef, buttons = buttons }
            addRow(lineCount * 24 + 6)
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
                local v = WD.Num(PigSet[rec.row.var], rec.row.default or 0)
                rec.control:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            elseif rec.kind == "cslider" then
                rec.control:SetChecked(PigSet[rec.row.var] == true)
                local v = WD.Num(PigSet[rec.row.pvar], rec.row.pdefault or 0)
                rec.slider:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            elseif rec.kind == "radio" then
                local cur = tonumber(PigSet[rec.row.var]) or rec.row.default or 1
                for _, b in ipairs(rec.buttons) do
                    local on = (cur == b.id)
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

WD.PopupCache = WD.PopupCache or {}

function WD.ShowOptions(key)
    WD.InitDefaults()
    local def = WD.PopupDefs[key]
    if not def then return end
    local f = WD.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        WD.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(WD.PopupCache) do
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
-- 18. 爆发按钮（面板 onClick）
-- ============================================================
function WR_WarlockDemoBurstAllOn()
    if type(PigSet) ~= "table" then return end
    PigSet.SS_EM_ZDZZ = true
    WD.SyncCheckbox("SS_EM_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cff00ff00[恶魔学识]|r 爆发已全部打开") end
end

function WR_WarlockDemoBurstAllOff()
    if type(PigSet) ~= "table" then return end
    PigSet.SS_EM_ZDZZ = false
    WD.SyncCheckbox("SS_EM_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cffff5040[恶魔学识]|r 爆发已全部关闭") end
end

function WR_WarlockDemoBurstToggle()
    if type(PigSet) ~= "table" then return end
    if PigSet.SS_EM_ZDZZ == true then
        WR_WarlockDemoBurstAllOff()
    else
        WR_WarlockDemoBurstAllOn()
    end
end

-- ============================================================
-- 19. 斜杠命令（截图口径：/WARLOCKDOT /WARLOCKCAST /WARLOCKSUMMON /WARLOCKARMOR）
-- ============================================================
local function ToggleSwitch(var, label)
    if type(PigSet) ~= "table" then return end
    PigSet[var] = not (PigSet[var] == true)
    WD.SyncCheckbox(var)
    print("|cff00ff00[" .. label .. "]|r " .. (PigSet[var] and "开启" or "关闭"))
end

SLASH_WARLOCK_DOT1 = "/WARLOCKDOT"
if type(SlashCmdList) == "table" then
    SlashCmdList["WARLOCK_DOT"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SS_EM_DOT = true; WD.SyncCheckbox("SS_EM_DOT")
        elseif msg == "off" then PigSet.SS_EM_DOT = false; WD.SyncCheckbox("SS_EM_DOT")
        else ToggleSwitch("SS_EM_DOT", "DOT") end
    end
end

SLASH_WARLOCK_CAST1 = "/WARLOCKCAST"
if type(SlashCmdList) == "table" then
    SlashCmdList["WARLOCK_CAST"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SS_EM_CAST = true; WD.SyncCheckbox("SS_EM_CAST")
        elseif msg == "off" then PigSet.SS_EM_CAST = false; WD.SyncCheckbox("SS_EM_CAST")
        else ToggleSwitch("SS_EM_CAST", "读条引导") end
    end
end

SLASH_WARLOCK_SUMMON1 = "/WARLOCKSUMMON"
if type(SlashCmdList) == "table" then
    SlashCmdList["WARLOCK_SUMMON"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SS_EM_SUMMON = true; WD.SyncCheckbox("SS_EM_SUMMON")
        elseif msg == "off" then PigSet.SS_EM_SUMMON = false; WD.SyncCheckbox("SS_EM_SUMMON")
        else ToggleSwitch("SS_EM_SUMMON", "召唤宠物") end
    end
end

SLASH_WARLOCK_ARMOR1 = "/WARLOCKARMOR"
if type(SlashCmdList) == "table" then
    SlashCmdList["WARLOCK_ARMOR"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SS_EM_ARMOR = true; WD.SyncCheckbox("SS_EM_ARMOR")
        elseif msg == "off" then PigSet.SS_EM_ARMOR = false; WD.SyncCheckbox("SS_EM_ARMOR")
        else ToggleSwitch("SS_EM_ARMOR", "护甲") end
    end
end

WD.InitDefaults()
