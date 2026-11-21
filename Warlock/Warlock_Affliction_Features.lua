-- ============================================================
-- Warlock_Affliction_Features.lua
-- 痛苦术（WoW Forever / 60级）功能层
-- ------------------------------------------------------------
-- 只服务 WARLOCK「痛苦」专精：不写全局、不影响恶魔学识/毁灭与其他职业。
-- 共享件 Warlock_Forever.lua 零改动（毁灭仍在用）。
--
-- 按「彼岸花-无限服 · 痛苦页」截图逐项落地：
-- 功能：DOT（右键）/ 读条引导（右键）/ 护甲（右键：恶魔皮肤/魔甲术）/
--       召唤宠物（右键：4宠物多选）/ 切换目标
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
-- 吸取灵魂 1120 / 吸取生命 689 / 折磨(无限新增) / 暗影箭 686 /
-- 恶魔皮肤 687 / 魔甲术 706 / 生命通道 755 / 生命分流 1454 /
-- 死亡缠绕 6789 / 恐惧术 5782 / 恐惧嚎叫 5484 / 地狱烈焰 1949 /
-- 火焰之雨 11678 / 召唤小鬼 688 / 虚空行者 697 / 魅魔 712 / 地狱猎犬 691
-- ★ 80级/外服技能（痛苦无常/鬼影缠身/腐蚀之种/痛苦诅咒/厄运诅咒/
--   灵魂碎裂/地狱火/暗影烈焰/烧尽/混乱之箭/邪甲术/召唤恶魔卫士/灵魂链接）
--   本服 60 级不存在或非痛苦循环所需，本层不再引用（DOT 诅咒系已改名「灾祸」）。
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

WR_WarlockAffl = WR_WarlockAffl or {}
local WA = WR_WarlockAffl

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ============================================================
WA.Defaults = {
    -- DOT 窗（截图：腐蚀术/献祭/生命虹吸 勾上才放；灾祸2选1；诅咒5选1）
    SS_TK_DOT = true,             -- DOT 总开关
    SS_TK_DOT_FSS = true,         -- 腐蚀术
    SS_TK_DOT_FSS_TTD = 6,        --   预判：目标还能活 > 6 秒才上
    SS_TK_DOT_XJ = true,          -- 献祭
    SS_TK_DOT_XJ_TTD = 8,
    SS_TK_DOT_SMHX = true,        -- 生命虹吸（痛苦天赋）
    SS_TK_DOT_SMHX_TTD = 0,       --   预判 关闭 = 都放
    SS_TK_BANE_ON = true,         -- 灾祸类总开关
    SS_TK_BANE_KIND = 1,          --   1=痛苦灾祸 2=末日灾祸
    SS_TK_BANE_TTD = 12,          --   预判 12 秒
    SS_TK_CURSE_ON = true,        -- 诅咒类总开关（截图默认勾）
    SS_TK_CURSE_KIND = 1,         --   1元素 2虚弱 3鲁莽 4语言 5疲劳
    SS_TK_CURSE_TTD = 0,          --   预判 关闭 = 都放
    -- 读条引导窗（截图：引导=吸灵魂/吸生命/折磨；读条=暗影箭）
    SS_TK_CAST = true,            -- 读条引导总开关
    SS_TK_CAST_CH = true,         -- 「引导」组总开关
    SS_TK_DS = true,              -- 吸取灵魂
    SS_TK_DS_TTD = 5,             --   预判：目标还能活 > 5 秒才吸
    SS_TK_DS_HP = 10,             --   目标血量低于 10% 才吸（0 = 不限）
    SS_TK_XSM = true,             -- 吸取生命
    SS_TK_XSM_MODE = 1,           --   1=无脑 2=看血量
    SS_TK_XSM_HP = 50,            --   看血量：自己血量低于 50% 才吸
    SS_TK_ZM = true,              -- 折磨（引导填充，无限新增技能）
    SS_TK_CAST_RD = true,         -- 「读条」组总开关
    SS_TK_AYJ = true,             -- 暗影箭（读条填充）
    -- 护甲 / 召唤 / 功能
    SS_TK_ARMOR = true,           -- 护甲总开关
    SS_TK_ARMOR_KIND = 2,         --   1=恶魔皮肤 2=魔甲术（截图默认魔甲术）
    SS_TK_SUMMON = true,          -- 召唤宠物总开关
    SS_TK_SUM_IMP = true,         --   小鬼
    SS_TK_SUM_VW = false,         --   虚空行者
    SS_TK_SUM_SU = false,         --   魅魔
    SS_TK_SUM_FH = false,         --   地狱猎犬
    SS_TK_TAB = true,             -- 切换目标
    SS_TK_ZDZZ = true,            -- 种族爆
    -- 拉条
    SS_TK_LTFL = 30,              -- 生命分流：蓝低于 30%
    SS_TK_GXFL = 80,              -- 高血分流：血高于 80%
    SS_TK_HHY = 30,               -- 喝红药：血低于 30%
    SS_TK_MZHL = 50,              -- 魔杖回蓝：蓝低于 50%
    -- 插入（一次性，放完自关）
    SS_TK_CRSWCR = false,         -- 死亡缠绕
    SS_TK_CRKJ = false,           -- 恐惧术
    SS_TK_CRKJHJ = false,         -- 恐惧嚎叫
    SS_TK_CRDYLY = false,         -- 地狱烈焰
    SS_TK_CRHYZY = false,         -- 火焰之雨
    SS_TK_CRSMTD = false,         -- 生命通道
    SS_TK_CRLTFL = false,         -- 生命分流
}

WA.Migrated = WA.Migrated or false

function WA.InitDefaults()
    if type(PigSet) ~= "table" then return end
    for k, v in pairs(WA.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
    if not WA.Migrated then
        WA.Migrated = true
        -- 旧档迁移：SS_TK_HJ（1邪甲 2魔甲 3禁用）→ 新护甲 radio
        -- 邪甲术本服 60 级不存在 → 回退魔甲术（与截图默认一致）
        if PigSet.SS_TK_HJ ~= nil then
            local sel = tonumber(PigSet.SS_TK_HJ)
            if sel == 3 then
                PigSet.SS_TK_ARMOR = false
            else
                PigSet.SS_TK_ARMOR_KIND = 2
            end
            PigSet.SS_TK_HJ = nil
        end
        -- 旧档迁移：SS_TK_AUTOSUMMON（2小鬼 3虚空 4魅魔 5地狱猎犬 6恶魔卫士）→ 多选勾
        local oldSummon = tonumber(PigSet.SS_TK_AUTOSUMMON)
        if oldSummon and oldSummon >= 2 then
            local map = {
                [2] = "SS_TK_SUM_IMP", [3] = "SS_TK_SUM_VW",
                [4] = "SS_TK_SUM_SU",  [5] = "SS_TK_SUM_FH",
            }
            local k = map[oldSummon]
            if k then
                PigSet.SS_TK_SUMMON = true
                -- 先关默认小鬼，再勾旧档选的那种（多选一语义）
                for _, v in pairs(map) do PigSet[v] = false end
                PigSet[k] = true
            end
            PigSet.SS_TK_AUTOSUMMON = nil
        end
    end
end

-- ============================================================
-- 2. 小工具
-- ============================================================
function WA.Num(v, d)
    local n = tonumber(v)
    if type(n) == "number" then return n end
    return d
end

function WA.Bool(v, d)
    if v == true then return true end
    if v == false then return false end
    return d
end

function WA.On(var, default)
    if type(PigSet) ~= "table" then return default == true end
    return WA.Bool(PigSet[var], default)
end

function WA.Val(var, default)
    if type(PigSet) ~= "table" then return default end
    return WA.Num(PigSet[var], default)
end

function WA.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
end

function WA.SpellKnown(name)
    if type(WR_Forever_IsSpellKnown) == "function" then
        local ok, known = pcall(WR_Forever_IsSpellKnown, name)
        if ok then return known == true end
    end
    return true
end

function WA.Show(spell, slot)
    if WR_ColorFrame_ShowSkill ~= nil then
        return WR_ColorFrame_ShowSkill(spell, slot) == true
    end
    return false
end

-- ============================================================
-- 3. 循环：基础变量 / 停手门
-- ============================================================
function WA.Base()
    GCD = WR_GetGCD("暗影箭")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    WA.TargetOK = UnitExists("target")
        and not UnitIsDeadOrGhost("target")
        and UnitCanAttack("player", "target")
    WA.InRange = (TargetRange ~= nil and TargetRange <= 35)
    WA.Casting = WR_SafeCastingName("player")
    WA.Channel = WR_SafeChannelName("player")
end

-- 引导类技能 → 色块槽位（引导中要熄灭自己的槽，否则 AHK 连按会打断引导）
WA.ChannelSlots = {
    ["吸取灵魂"] = 11,
    ["吸取生命"] = 86,
    ["折磨"] = 91,
}

function WA.StopGate()
    local ch = WA.Channel
    if ch and WA.ChannelSlots[ch] then
        -- ★ nil 判定而非 type()=="function"（仓库老坑：跨文件可调用对象可能是 userdata）
        if WR_HideSkillColorSlot ~= nil then
            WR_HideSkillColorSlot(ch, WA.ChannelSlots[ch])
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
WA.PendingInsert = WA.PendingInsert or {}

function WA.InsertStep()
    local now = GetTime()
    -- 先回收已施放成功的 pending（施法成功信号 = WR_Forever_LastPlayerCast）
    local last = WR_Forever_LastPlayerCast
    for key, rec in pairs(WA.PendingInsert) do
        if last and last.spellName == rec.spell and last.time >= rec.since then
            PigSet[key] = false
            WA.PendingInsert[key] = nil
            WA.SyncCheckbox(key)
        elseif now > rec.deadline then
            WA.PendingInsert[key] = nil
        end
    end

    local list = {
        { key = "SS_TK_CRSWCR", spell = "死亡缠绕", slot = 102, needTarget = true },
        { key = "SS_TK_CRKJ",   spell = "恐惧术",   slot = 103, needTarget = true },
        { key = "SS_TK_CRKJHJ", spell = "恐惧嚎叫", slot = 104, needTarget = false },
        { key = "SS_TK_CRDYLY", spell = "地狱烈焰", slot = 77,  needTarget = false },
        { key = "SS_TK_CRHYZY", spell = "火焰之雨", slot = 76,  needTarget = false },
        { key = "SS_TK_CRSMTD", spell = "生命通道", slot = 105, needTarget = false },
        { key = "SS_TK_CRLTFL", spell = "生命分流", slot = 10,  needTarget = false },
    }
    for _, it in ipairs(list) do
        if PigSet[it.key] == true then
            if (not it.needTarget) or WA.TargetOK then
                if WR_SpellUsable ~= nil then
                    local ok, usable = pcall(WR_SpellUsable, it.spell, true)
                    if ok and usable == true then
                        if WA.Show(it.spell, it.slot) then
                            WA.PendingInsert[it.key] = {
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
function WA.SelfPreserve()
    if PlayerHP < WA.Val("SS_TK_HHY", 30) / 100 then
        if WR_Use_ZLS ~= nil then
            local ok, can = pcall(WR_Use_ZLS)
            if ok and can == true then
                if WA.Show("邪能治疗石", 35) then return true end
            end
        end
        if WR_Use_ZLYS ~= nil then
            local ok, can = pcall(WR_Use_ZLYS)
            if ok and can == true then
                if WA.Show("治疗药水", 106) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 6. 护甲：恶魔皮肤 / 魔甲术 二选一；战斗内外都补（截图默认魔甲术）
-- ============================================================
function WA.ArmorStep()
    if not WA.On("SS_TK_ARMOR", true) then return false end
    local want, slot
    if WA.Val("SS_TK_ARMOR_KIND", 2) == 1 then
        want, slot = "恶魔皮肤", 93
    else
        want, slot = "魔甲术", 9
    end
    if WR_GetUnitBuffTime("player", want) == 0 then
        if WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, want, true)
            if ok and usable == true then
                if WA.Show(want, slot) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 7. 召唤宠物：脱战+静止+无宠物 → 按勾选优先级召唤
--    （复用 BExt：内含 读条/骑乘/吃喝/重复召唤 门）
-- ============================================================
function WA.SummonStep()
    if not WA.On("SS_TK_SUMMON", true) then return false end
    -- 恶魔牺牲流派：牺牲 buff 在身不召唤（截图口径：要把宠物献祭掉的关掉开关）
    if WR_GetUnitBuffTime("player", "恶魔牺牲") > 0 then return false end
    if UnitExists("pet") and not UnitIsDeadOrGhost("pet") then return false end
    local sel
    if WA.On("SS_TK_SUM_IMP", true) then
        sel = 2
    elseif WA.On("SS_TK_SUM_VW", false) then
        sel = 3
    elseif WA.On("SS_TK_SUM_SU", false) then
        sel = 4
    elseif WA.On("SS_TK_SUM_FH", false) then
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
WA.LastTab = WA.LastTab or 0

function WA.TabStep()
    if not WA.On("SS_TK_TAB", true) then return false end
    if not UnitAffectingCombat("player") then return false end
    if WA.TargetOK then return false end
    if WR_CanTab ~= nil and not WR_CanTab() then return false end
    local now = GetTime()
    if now - WA.LastTab < 1.0 then return false end
    if WA.Show("切目标", 56) then
        WA.LastTab = now
        return true
    end
    return false
end

-- ============================================================
-- 9. 战斗门（防ADD）：FANG_ADD_TKS 1=是 2=否
-- ============================================================
function WA.CombatGate()
    local preventAdd = (WA.Val("FANG_ADD_TKS", 1) == 1)
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
function WA.BurstStep()
    if not WA.On("SS_TK_ZDZZ", true) then return false end
    -- ★★★ 2026-11-21 三十五次修复：统一走 WR_Forever_RacialBurstStep 补 CD 维。
    if type(WR_Forever_RacialBurstStep) == "function" then
        return WR_Forever_RacialBurstStep(WA.Show, nil, 8, true)
    end
    if WR_Forever_PlayerRacialBursts == nil then return false end
    local okB, bursts = pcall(WR_Forever_PlayerRacialBursts)
    if not okB or type(bursts) ~= "table" then return false end
    for i = 1, #bursts do
        local name = bursts[i]
        if type(name) == "string" and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, name, true)
            if ok and usable == true then
                if WA.Show("种族爆发", 8) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 11. 拉条：生命分流（蓝低于）/ 高血分流（血高于、蓝未满）
-- ============================================================
function WA.ManaStep()
    if PlayerMove or WA.Casting or WA.Channel then return false end
    if WR_SpellUsable ~= nil then
        local ok, usable = pcall(WR_SpellUsable, "生命分流")
        if ok and usable == true then
            -- 蓝低于拉条（保命下限：血 > 40% 才分）
            if PlayerMP < WA.Val("SS_TK_LTFL", 30) / 100 and PlayerHP > 0.40 then
                if WA.Show("生命分流", 10) then return true end
            end
            -- 高血分流：血量富余时主动换蓝（血高于拉条、蓝低于 60%）
            if PlayerHP >= WA.Val("SS_TK_GXFL", 80) / 100 and PlayerMP < 0.60 then
                if WA.Show("生命分流", 10) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 12. DOT：腐蚀术 / 献祭 / 生命虹吸 + 灾祸(2选1) + 诅咒(5选1)
--     只补「自己的」（ByMe）；预判 = 目标还能活 > X 秒才上（0=都放）
-- ============================================================
-- 槽位 = WR_SkillColor["WARLOCK"] 职业槽（1-199）。
WA.CURSES = {
    [1] = { name = "元素诅咒", slot = 94 },
    [2] = { name = "虚弱诅咒", slot = 95 },
    [3] = { name = "鲁莽诅咒", slot = 96 },
    [4] = { name = "语言诅咒", slot = 101 },
    [5] = { name = "疲劳诅咒", slot = 109, talent = true },
}

function WA.DotStep()
    if not WA.On("SS_TK_DOT", true) then return false end
    if not WA.TargetOK or not WA.InRange then return false end
    if WR_CanDot ~= nil and not WR_CanDot("target") then return false end
    if WR_IsBlacklisted ~= nil and WR_IsBlacklisted("target") then return false end
    local T = TargetDeathTime or 0

    local dts = {
        { on = "SS_TK_DOT_FSS",  ttd = "SS_TK_DOT_FSS_TTD",  dft = 6, name = "腐蚀术",   slot = 41 },  -- 41=SHIFT-F1 本体宏（槽14 是焦点宏，勿用于当前目标）
        { on = "SS_TK_DOT_XJ",   ttd = "SS_TK_DOT_XJ_TTD",   dft = 8, name = "献祭",     slot = 36 },
        { on = "SS_TK_DOT_SMHX", ttd = "SS_TK_DOT_SMHX_TTD", dft = 0, name = "生命虹吸", slot = 81, talent = true },
    }
    for _, d in ipairs(dts) do
        if WA.On(d.on, true) then
            local need = WA.Val(d.ttd, d.dft)
            if (need <= 0 or T > need)
               and (d.talent ~= true or WA.SpellKnown(d.name))
               and WR_GetUnitDebuffTime("target", d.name, true) == 0
               and WR_SpellUsable ~= nil then
                local ok, usable = pcall(WR_SpellUsable, d.name, true)
                if ok and usable == true then
                    if WA.Show(d.name, d.slot) then return true end
                end
            end
        end
    end

    -- 灾祸 2 选 1：目标身上没有「自己的那一种」就补
    if WA.On("SS_TK_BANE_ON", true) then
        local kind = WA.Val("SS_TK_BANE_KIND", 1)
        local bane, slot
        if kind == 2 then
            bane, slot = "末日灾祸", 108
        else
            bane, slot = "痛苦灾祸", 107
        end
        local ttdNeed = WA.Val("SS_TK_BANE_TTD", 12)
        if kind == 2 and ttdNeed < 60 then ttdNeed = 60 end   -- 末日灾祸一跳 60 秒
        if (ttdNeed <= 0 or T > ttdNeed)
           and WR_GetUnitDebuffTime("target", bane, true) == 0
           and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, bane, true)
            if ok and usable == true then
                if WA.Show(bane, slot) then return true end
            end
        end
    end

    -- 诅咒 5 选 1
    if WA.On("SS_TK_CURSE_ON", false) then
        local rec = WA.CURSES[WA.Val("SS_TK_CURSE_KIND", 1)] or WA.CURSES[1]
        local ttdNeed = WA.Val("SS_TK_CURSE_TTD", 0)
        if (ttdNeed <= 0 or T > ttdNeed)
           and (rec.talent ~= true or WA.SpellKnown(rec.name))
           and WR_GetUnitDebuffTime("target", rec.name, true) == 0
           and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, rec.name, true)
            if ok and usable == true then
                if WA.Show(rec.name, rec.slot) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 13. 读条引导（痛苦页口径）：
--     引导类：吸取灵魂 → 吸取生命 → 折磨（从上到下就是先后）
--     读条类：只有暗影箭填充
--     「关掉后右键里的引导、读条技能一个都不放（只剩瞬发技能和魔杖）」
-- ============================================================
function WA.CastStep()
    if not WA.On("SS_TK_CAST", true) then return false end
    if not WA.TargetOK or not WA.InRange then return false end
    if WA.Casting or WA.Channel then return false end
    local T = TargetDeathTime or 0

    -- 引导组
    if WA.On("SS_TK_CAST_CH", true) then
        -- 吸取灵魂：目标血量低于 血量% 才吸（0 = 不限），
        -- 且目标预计还能活 > 预判秒（0 = 不限）
        if WA.On("SS_TK_DS", true) then
            local hpNeed = WA.Val("SS_TK_DS_HP", 10)
            local ttdNeed = WA.Val("SS_TK_DS_TTD", 5)
            local hpOK = (hpNeed <= 0) or (WR_SafeHPPct("target") < hpNeed / 100)
            local ttdOK = (ttdNeed <= 0) or T > ttdNeed
            if hpOK and ttdOK and WR_SpellUsable ~= nil then
                local ok, usable = pcall(WR_SpellUsable, "吸取灵魂", true)
                if ok and usable == true then
                    if WA.Show("吸取灵魂", 11) then return true end
                end
            end
        end
        -- 吸取生命：无脑 = 蓝量不足就吸；看血量 = 自己血量低于 血量% 才吸
        if WA.On("SS_TK_XSM", true) then
            local mode = WA.Val("SS_TK_XSM_MODE", 1)
            local hpNeed = WA.Val("SS_TK_XSM_HP", 50)
            local hpOK = (mode ~= 2) or (PlayerHP < hpNeed / 100)
            if hpOK and WR_SpellUsable ~= nil then
                local ok, usable = pcall(WR_SpellUsable, "吸取生命", true)
                if ok and usable == true then
                    if WA.Show("吸取生命", 86) then return true end
                end
            end
        end
        -- 折磨：引导填充（无限新增技能；没学会按可用性门自动跳过）
        if WA.On("SS_TK_ZM", true) and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, "折磨", true)
            if ok and usable == true then
                if WA.Show("折磨", 91) then return true end
            end
        end
    end

    -- 读条组：暗影箭填充
    if WA.On("SS_TK_CAST_RD", true) then
        if WA.On("SS_TK_AYJ", true) and not PlayerMove
           and WR_SpellUsable ~= nil then
            local ok, usable = pcall(WR_SpellUsable, "暗影箭", true)
            if ok and usable == true then
                if WA.Show("暗影箭", 6) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- 14. 魔杖回蓝兜底：蓝低于拉条且本 tick 无技能可打 → 魔杖(190)
-- ============================================================
function WA.WandStep()
    if PlayerMP >= WA.Val("SS_TK_MZHL", 50) / 100 then return false end
    if not WA.TargetOK then return false end
    if not (TargetRange and TargetRange <= 30) then return false end
    if WA.Casting or WA.Channel then return false end
    if WA.Show("魔杖射击", 190) then return true end
    return false
end

-- ============================================================
-- 15. 收尾清扫：本 tick 未点亮任何色块时熄灭上一 tick 的残留
-- ============================================================
function WA.Sweep()
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
function WA.Run()
    WA.InitDefaults()
    local handled = false
    repeat
        WA.Base()
        if WA.StopGate() then break end
        if WA.InsertStep() then handled = true; break end
        if WA.SelfPreserve() then handled = true; break end
        if WA.ArmorStep() then handled = true; break end
        if WA.SummonStep() then handled = true; break end
        if WA.TabStep() then handled = true; break end
        if not WA.CombatGate() then break end
        if WA.BurstStep() then handled = true; break end
        if WA.ManaStep() then handled = true; break end
        if WA.DotStep() then handled = true; break end
        if WA.CastStep() then handled = true; break end
        if WA.WandStep() then handled = true; break end
    until true
    if not handled then WA.Sweep() end
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

WA.PopupDefs = {
    SS_TK_DOT = {
        title = "DOT  功能",
        width = 420,
        desc = "开着时按右键里的设置给目标上 DOT、灾祸和诅咒：目标身上没有自己的那一个就补。\n\n"
            .. "腐蚀术、献祭、生命虹吸：勾上才放。\n"
            .. "灾祸（痛苦/末日）2选1、诅咒（元素/虚弱/鲁莽/语言/疲劳）5选1：「灾祸」「诅咒」前面的勾是这一类的总开关，去掉 = 这一类不放。\n\n"
            .. "「预判」= 目标预计还能活过这么多秒才放（0=都放）。\n\n"
            .. "关掉后右键里的 DOT、灾祸和诅咒一个都不上。\n"
            .. "宏：/WARLOCK_DOT 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "SS_TK_DOT", label = "DOT", default = true },
            { type = "cslider", var = "SS_TK_DOT_FSS", pvar = "SS_TK_DOT_FSS_TTD", pdefault = 6, label = "腐蚀术", default = true, suffix = "秒", minv = 0, maxv = 30, indent = 18 },
            { type = "cslider", var = "SS_TK_DOT_XJ", pvar = "SS_TK_DOT_XJ_TTD", pdefault = 8, label = "献祭", default = true, suffix = "秒", minv = 0, maxv = 30, indent = 18 },
            { type = "cslider", var = "SS_TK_DOT_SMHX", pvar = "SS_TK_DOT_SMHX_TTD", pdefault = 0, label = "生命虹吸（痛苦天赋）", default = true, suffix = "秒", minv = 0, maxv = 30, indent = 18 },
            { type = "check", var = "SS_TK_BANE_ON", label = "灾祸", default = true, indent = 18 },
            { type = "radio", var = "SS_TK_BANE_KIND", default = 1, perRow = 2, indent = 36,
              options = { { id = 1, name = "痛苦灾祸" }, { id = 2, name = "末日灾祸" } } },
            { type = "slider", var = "SS_TK_BANE_TTD", label = "预判", default = 12, suffix = "秒", minv = 0, maxv = 60, indent = 36 },
            { type = "check", var = "SS_TK_CURSE_ON", label = "诅咒", default = true, indent = 18 },
            { type = "radio", var = "SS_TK_CURSE_KIND", default = 1, perRow = 3, indent = 36,
              options = {
                  { id = 1, name = "元素诅咒" }, { id = 2, name = "虚弱诅咒" }, { id = 3, name = "鲁莽诅咒" },
                  { id = 4, name = "语言诅咒" }, { id = 5, name = "疲劳诅咒" },
              } },
            { type = "slider", var = "SS_TK_CURSE_TTD", label = "预判", default = 0, suffix = "秒", minv = 0, maxv = 60, indent = 36 },
        },
    },
    SS_TK_CAST = {
        title = "读条引导  功能",
        width = 400,
        desc = "开着时按右键里勾上的技能放引导、读条类技能。\n\n"
            .. "引导类：吸取灵魂、吸取生命、折磨；读条类从上到下就是先后：只有暗影箭填充。\n"
            .. "「引导」「读条」前面的勾是这一类的总开关。\n\n"
            .. "名字后面的灰字 = 要点哪一系的天赋才有，没学会的勾了也放不出来。\n"
            .. "吸取灵魂的「血量」= 目标血量低于该百分比才吸（0 = 不限）；「预判」= 目标还能活过这么多秒才吸。\n"
            .. "吸取生命的「无脑」= 蓝量不足就吸；「看血量」= 自己血量低于该百分比才吸。\n\n"
            .. "关掉后右键里的引导、读条技能一个都不放（只剩瞬发技能和魔杖）。\n"
            .. "宏：/WARLOCK_CAST 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "SS_TK_CAST", label = "读条引导", default = true },
            { type = "check", var = "SS_TK_CAST_CH", label = "引导", default = true, indent = 18 },
            { type = "cslider", var = "SS_TK_DS", pvar = "SS_TK_DS_TTD", pdefault = 5, label = "吸取灵魂", default = true, suffix = "秒", minv = 0, maxv = 30, indent = 36 },
            { type = "slider", var = "SS_TK_DS_HP", label = "血量", default = 10, suffix = "%", minv = 0, maxv = 100, indent = 54 },
            { type = "cslider", var = "SS_TK_XSM", pvar = "SS_TK_XSM_HP", pdefault = 50, label = "吸取生命", default = true, suffix = "%", minv = 0, maxv = 100, indent = 36 },
            { type = "radio", var = "SS_TK_XSM_MODE", default = 1, perRow = 2, indent = 54,
              options = { { id = 1, name = "无脑" }, { id = 2, name = "看血量" } } },
            { type = "check", var = "SS_TK_ZM", label = "折磨", default = true, indent = 36 },
            { type = "check", var = "SS_TK_CAST_RD", label = "读条", default = true, indent = 18 },
            { type = "check", var = "SS_TK_AYJ", label = "暗影箭（填充）", default = true, indent = 36 },
        },
    },
    SS_TK_SUMMON = {
        title = "召唤宠物  功能",
        width = 340,
        desc = "开着时，脱战、站着不动、身边没有宠物（没召唤/死了）就自动召唤右键里选中的那一种（小鬼/虚空行者/魅魔/地狱猎犬 多选，按顺序优先）。\n\n"
            .. "战斗中不召唤（读条 10 秒）；骑马、吃喝时不召唤。\n"
            .. "点了恶魔牺牲、要把宠物献祭掉的，把这个开关关掉（身上有恶魔牺牲 buff 时也不会召唤）。\n\n"
            .. "关掉后不再自动召唤宠物。\n"
            .. "宏：/WARLOCK_SUMMON 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "SS_TK_SUMMON", label = "召唤宠物", default = true },
            { type = "check", var = "SS_TK_SUM_IMP", label = "小鬼", default = true, indent = 18 },
            { type = "check", var = "SS_TK_SUM_VW", label = "虚空行者", default = false, indent = 18 },
            { type = "check", var = "SS_TK_SUM_SU", label = "魅魔", default = false, indent = 18 },
            { type = "check", var = "SS_TK_SUM_FH", label = "地狱猎犬", default = false, indent = 18 },
        },
    },
    SS_TK_ARMOR = {
        title = "护甲  功能",
        width = 340,
        desc = "开着时，自己身上没有右键里选中的那种甲就自动补上（恶魔皮肤/魔甲术 二选一）；战斗内外都补。\n\n"
            .. "关掉后不再自动补甲。\n"
            .. "宏：/WARLOCK_ARMOR 切换（后面加 on 开、off 关）",
        rows = {
            { type = "check", var = "SS_TK_ARMOR", label = "护甲", default = true },
            { type = "radio", var = "SS_TK_ARMOR_KIND", default = 2, perRow = 2, indent = 18,
              options = { { id = 1, name = "恶魔皮肤" }, { id = 2, name = "魔甲术" } } },
        },
    },
}

local function BuildPopup(key)
    local def = WA.PopupDefs[key]
    if not def then return nil end
    local width = def.width or 360
    local f = CreateFrame("Frame", "WR_WarlockAfflPopup_" .. key, UIParent, "BackdropTemplate")
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
                WA.SyncCheckbox(rowDef.var)
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
            local val = WA.Num(PigSet[rowDef.var], rowDef.default or 0)
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
                WA.SyncCheckbox(rowDef.var)
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
            local val = WA.Num(PigSet[rowDef.pvar], rowDef.pdefault or 0)
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
                local v = WA.Num(PigSet[rec.row.var], rec.row.default or 0)
                rec.control:SetValue(v)
                rec.valText:SetText(tostring(v) .. (rec.row.suffix or ""))
            elseif rec.kind == "cslider" then
                rec.control:SetChecked(PigSet[rec.row.var] == true)
                local v = WA.Num(PigSet[rec.row.pvar], rec.row.pdefault or 0)
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

WA.PopupCache = WA.PopupCache or {}

function WA.ShowOptions(key)
    WA.InitDefaults()
    local def = WA.PopupDefs[key]
    if not def then return end
    local f = WA.PopupCache[key]
    if not f then
        f = BuildPopup(key)
        WA.PopupCache[key] = f
    end
    if not f then return end
    if f:IsShown() then
        f:Hide()
        return
    end
    for _, other in pairs(WA.PopupCache) do
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
function WR_WarlockAfflBurstAllOn()
    if type(PigSet) ~= "table" then return end
    PigSet.SS_TK_ZDZZ = true
    WA.SyncCheckbox("SS_TK_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cff00ff00[痛苦]|r 爆发已全部打开") end
end

function WR_WarlockAfflBurstAllOff()
    if type(PigSet) ~= "table" then return end
    PigSet.SS_TK_ZDZZ = false
    WA.SyncCheckbox("SS_TK_ZDZZ")
    if WR_PrintToVisible then pcall(WR_PrintToVisible, "|cffff5040[痛苦]|r 爆发已全部关闭") end
end

function WR_WarlockAfflBurstToggle()
    if type(PigSet) ~= "table" then return end
    if PigSet.SS_TK_ZDZZ == true then
        WR_WarlockAfflBurstAllOff()
    else
        WR_WarlockAfflBurstAllOn()
    end
end

-- ============================================================
-- 19. 斜杠命令（截图口径：/WARLOCK_DOT /WARLOCK_CAST /WARLOCK_SUMMON /WARLOCK_ARMOR）
--     ★ 带下划线命令与恶魔术的 /WARLOCKDOT（无下划线）并存，互不覆盖：
--     恶魔术注册的 SlashCmdList 键是 WARLOCK_DOT / WARLOCK_CAST / ...（文本无下划线），
--     本层用 WARLOCK_AFFL_* 键 + 带下划线文本，两组命令同时可用。
-- ============================================================
local function ToggleSwitch(var, label)
    if type(PigSet) ~= "table" then return end
    PigSet[var] = not (PigSet[var] == true)
    WA.SyncCheckbox(var)
    print("|cff00ff00[" .. label .. "]|r " .. (PigSet[var] and "开启" or "关闭"))
end

SLASH_WARLOCK_AFFL_DOT1 = "/WARLOCK_DOT"
if type(SlashCmdList) == "table" then
    SlashCmdList["WARLOCK_AFFL_DOT"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SS_TK_DOT = true; WA.SyncCheckbox("SS_TK_DOT")
        elseif msg == "off" then PigSet.SS_TK_DOT = false; WA.SyncCheckbox("SS_TK_DOT")
        else ToggleSwitch("SS_TK_DOT", "DOT") end
    end
end

SLASH_WARLOCK_AFFL_CAST1 = "/WARLOCK_CAST"
if type(SlashCmdList) == "table" then
    SlashCmdList["WARLOCK_AFFL_CAST"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SS_TK_CAST = true; WA.SyncCheckbox("SS_TK_CAST")
        elseif msg == "off" then PigSet.SS_TK_CAST = false; WA.SyncCheckbox("SS_TK_CAST")
        else ToggleSwitch("SS_TK_CAST", "读条引导") end
    end
end

SLASH_WARLOCK_AFFL_SUMMON1 = "/WARLOCK_SUMMON"
if type(SlashCmdList) == "table" then
    SlashCmdList["WARLOCK_AFFL_SUMMON"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SS_TK_SUMMON = true; WA.SyncCheckbox("SS_TK_SUMMON")
        elseif msg == "off" then PigSet.SS_TK_SUMMON = false; WA.SyncCheckbox("SS_TK_SUMMON")
        else ToggleSwitch("SS_TK_SUMMON", "召唤宠物") end
    end
end

SLASH_WARLOCK_AFFL_ARMOR1 = "/WARLOCK_ARMOR"
if type(SlashCmdList) == "table" then
    SlashCmdList["WARLOCK_AFFL_ARMOR"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "on" then PigSet.SS_TK_ARMOR = true; WA.SyncCheckbox("SS_TK_ARMOR")
        elseif msg == "off" then PigSet.SS_TK_ARMOR = false; WA.SyncCheckbox("SS_TK_ARMOR")
        else ToggleSwitch("SS_TK_ARMOR", "护甲") end
    end
end
