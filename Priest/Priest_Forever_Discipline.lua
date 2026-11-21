-- ============================================================
-- Priest/Priest_Forever_Discipline.lua
-- Priest Forever · Discipline 专精循环（无限 1.60.x / 60级）
-- ------------------------------------------------------------
-- 2026-11-18 按「猪猪 / 彼岸花·无限服 · 戒律页」功能图重做：
--   选择：防ADD（是/否）、治疗模式（全团/目标/预读/坦克/脆皮/一队~五队）
--   拉条：喝红药 30 / 黑暗献祭 30 / 真言术：盾 80 / 苦修 70 /
--         联结治疗 70 / 快速治疗 50 / 强效治疗术 75 / 治疗术 75 /
--         次级治疗术 75 / 恢复 90
--   功能：驱散、暗言术：灭、真言术：韧、心灵之火、惩击
--   插入：能量灌注、神圣新星、治疗祷言（一次性，放完自关）
--   爆发：种族爆发（三个可配置槽位已于 2026-11-21 下线）
-- 旧 80 级 / 本服不存在技能（痛苦压制、守护之魂、神圣赞美诗、希望圣歌、
-- 治疗之环、愈合祷言、绝望祷言等）全部从戒律循环与面板下线。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "PRIEST" then return end

local PD = {}
WR_PriestForeverPD = PD

-- ============================================================
-- 1. 默认值 / 旧档迁移
-- ============================================================
PD.Defaults = {
    -- 选择
    JL_FADD = 1,            -- 防ADD：1=是 2=否
    JL_ZLMS = 1,            -- 治疗模式：1全团 2目标 3预读 4坦克 5脆皮 6~10一~五队
    JL_QS   = 2,            -- 驱散模式：1常规 2优先 3目标 4指向 5禁用
    -- 拉条
    JL_HXY   = 30,          -- 喝红药：血低于 30%
    JL_HZ    = 30,          -- 黑暗献祭：法力低于 30%（自身血量低于35%时不用）
    JL_ZYSD  = 80,          -- 真言术：盾：血低于 80%
    JL_KX    = 70,          -- 苦修：血低于 70%
    JL_LJZL  = 70,          -- 联结治疗：血低于 70%
    JL_KSZL  = 50,          -- 快速治疗：血低于 50%
    JL_QXZLS = 75,          -- 强效治疗术：血低于 75%
    JL_ZLSHU = 75,          -- 治疗术：血低于 75%
    JL_CJZLS = 75,          -- 次级治疗术：血低于 75%
    JL_HF    = 90,          -- 恢复：血低于 90%
    -- 功能
    JL_QS_ON = true,        -- 自动驱散
    JL_AYSHM = false,       -- 暗言术：灭（默认关）
    JL_ZYSR  = true,        -- 真言术：韧
    JL_XLHZ  = true,        -- 心灵之火
    JL_CJ    = true,        -- 惩击
    -- 插入（一次性，默认关）
    JL_CRGNZ  = false,      -- 插入 能量灌注
    JL_CRXX   = false,      -- 插入 神圣新星
    JL_CRZLDY = false,      -- 插入 治疗祷言
    -- 爆发：面板只保留「种族爆发」一项（三槽位已下线，2026-11-21）
    JL_BF_RACE = true,      -- 种族爆发
}

PD.Migrated = false

local function PD_Num(v, def)
    v = tonumber(v)
    if v == nil then return def end
    return v
end

function PD.Val(key, def)
    return PD_Num(PigSet and PigSet[key], def)
end

function PD.On(key, def)
    local v = PigSet and PigSet[key]
    if v == nil then return def end
    return v == true
end

function PD.SyncCheckbox(var)
    if type(WR_SyncConfigCheckbox) == "function" then
        pcall(WR_SyncConfigCheckbox, var)
    end
end

function PD.InitDefaults()
    if type(PigSet) ~= "table" then return end
    if PD.DefaultsDone then return end
    if not PD.Migrated then
        PD.Migrated = true
        -- ★★★ 2026-11-21 三十九次修复：「真言术：盾使用要严格受滑块控制」。
        -- ------------------------------------------------------------
        -- 旧迁移只有会话内存旗标 PD.Migrated，**每次登录/重载都会重跑**：
        --   · 盾滑块合法值 5/10/15/20（%）被当成旧档位改写成 50/91/96/0 ——
        --     用户设 10% 下次登录变 91%（几乎满血就补盾）、设 20% 变 0（被禁用），
        --     循环用的阈值与面板滑块显示对不上，正是「不严格受滑块控制」的根因；
        --   · 治疗模式 2↔4 也会每次登录来回翻转（同源问题，一并堵上）。
        -- 现在用**存档旗标 JL_MIG_V2** 保证整段旧档迁移历史上只执行一次。
        if PigSet.JL_MIG_V2 ~= true then
            PigSet.JL_MIG_V2 = true
            -- 旧治疗模式（1自动/2坦克/3脆皮/4目标）→ 新（1全团/2目标/3预读/4坦克/5脆皮/6~10队）
            if PigSet.JL_ZLMS ~= nil then
                local old = tonumber(PigSet.JL_ZLMS)
                if old == 2 then PigSet.JL_ZLMS = 4
                elseif old == 3 then PigSet.JL_ZLMS = 5
                elseif old == 4 then PigSet.JL_ZLMS = 2
                elseif old == 1 then PigSet.JL_ZLMS = 1 end
            end
            -- 旧盾档位 1~20（10%~99% / 积极 / 禁用）→ 新百分比 0~100。
            -- ★ 只认「真正的旧档位」：1~20 且**不是新滑块的合法步进值**（步进 5）。
            --   5/10/15/20 既是旧档位也是合法百分比，无法区分 —— 一律按用户
            --   面板上设的百分比对待（严格滑块口径优先，宁可少迁一次不可改写用户值）。
            local oldShield = tonumber(PigSet.JL_ZYSD)
            if oldShield ~= nil and oldShield >= 1 and oldShield <= 20 and (oldShield % 5) ~= 0 then
                if oldShield <= 9 then PigSet.JL_ZYSD = oldShield * 10
                elseif oldShield <= 18 then PigSet.JL_ZYSD = 90 + (oldShield - 9)
                else PigSet.JL_ZYSD = 100 end
            end
            -- 旧恢复布尔 → 90 / 0
            if type(PigSet.JL_HF) == "boolean" then
                PigSet.JL_HF = PigSet.JL_HF and 90 or 0
            end
            -- 旧「快速治疗/联结治疗/强效治疗术」总开关 → 三个独立拉条
            if type(PigSet.JL_ZL) == "boolean" then
                local on = PigSet.JL_ZL
                if PigSet.JL_KSZL  == nil then PigSet.JL_KSZL  = on and 50 or 0 end
                if PigSet.JL_LJZL  == nil then PigSet.JL_LJZL  = on and 70 or 0 end
                if PigSet.JL_QXZLS == nil then PigSet.JL_QXZLS = on and 75 or 0 end
            end
            -- ★ 2026-11-21：爆发三槽位从面板与循环下线，旧档残留键一并清掉
            -- （JL_BF_S1~S3 是槽位开关，JL_BF_SLOT1~3 是槽位技能名），只保留种族爆发。
            for i = 1, 3 do
                PigSet["JL_BF_S" .. i] = nil
                PigSet["JL_BF_SLOT" .. i] = nil
            end
        end
    end
    for k, v in pairs(PD.Defaults) do
        if PigSet[k] == nil then PigSet[k] = v end
    end
    PD.DefaultsDone = true
end

-- ============================================================
-- 2. 通用辅助（全部 pcall 包裹，读不到按保守值处理）
-- ============================================================
function PD.SpellAbsent(name)
    return type(WR_Forever_SkillAbsent) == "table" and WR_Forever_SkillAbsent[name] == true
end

-- ★★★ 2026-11-21 三十四次修复：把「有没有这个技能」和「此刻能不能放」分开。
--   WR_SpellUsable 只回答后者（C_Spell.IsSpellUsable 只判资源/CD/形态，
--   私服还会对解析不出的名字直接回 true），于是「玩家根本没有的技能」被判成可用
--   → 色块点亮 → AHK 连按 → 宏里一条 /cast 都打不出去 → 色块卡死不灭。
--   这里补上「已学会」这一维：true=已学会 / false=确认没学会 / nil=读不到。
function PD.Learned(spell)
    if type(WR_Forever_SpellLearned) ~= "function" then return nil end
    local ok, v = pcall(WR_Forever_SpellLearned, spell)
    if not ok then return nil end
    return v
end

function PD.CanCast(spell)
    if PD.SpellAbsent(spell) then return false end
    -- 确认没学会 → 直接判死（读不到 nil 不拦，保持全仓「宁可少判不可误杀」口径）
    if PD.Learned(spell) == false then return false end
    if type(WR_SpellUsable) ~= "function" then return false end
    local ok, usable = pcall(WR_SpellUsable, spell)
    return ok and usable == true
end

function PD.IsDead(unit)
    if type(UnitExists) ~= "function" then return false end
    local okE, exists = pcall(UnitExists, unit)
    if not okE or exists ~= true then return false end
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, dead = pcall(function() return UnitIsDeadOrGhost(unit) == true end)
        if ok and dead == true then return true end
    end
    return false
end

function PD.IsFriend(unit)
    if type(UnitExists) ~= "function" then return false end
    local okE, exists = pcall(UnitExists, unit)
    if not okE or exists ~= true then return false end
    if type(UnitIsFriend) ~= "function" then return true end
    local ok, friend = pcall(function() return UnitIsFriend("player", unit) == true end)
    return ok and friend == true
end

function PD.HP(unit)
    if type(WR_GetUnitHP) ~= "function" then return 1 end
    local ok, v = pcall(WR_GetUnitHP, unit)
    if ok then return PD_Num(v, 1) end
    return 1
end

function PD.MP(unit)
    if type(WR_GetUnitMP) ~= "function" then return 1 end
    local ok, v = pcall(WR_GetUnitMP, unit)
    if ok then return PD_Num(v, 1) end
    return 1
end

function PD.RangeOf(unit)
    if unit == "player" then return 0 end
    if type(WR_UnitRange) ~= "function" then return nil end
    local ok, r = pcall(WR_UnitRange, unit)
    if ok and type(r) == "number" then return r end
    return nil
end

function PD.InRaid()
    if type(GetNumRaidMembers) ~= "function" then return false end
    local ok, n = pcall(GetNumRaidMembers)
    return ok and type(n) == "number" and n > 0
end

function PD.GroupUnits()
    local units = { "player" }
    if PD.InRaid() then
        local ok, n = pcall(GetNumRaidMembers)
        local count = ok and PD_Num(n, 0) or 0
        for i = 1, math.min(count, 40) do units[#units + 1] = "raid" .. i end
    else
        if type(GetNumPartyMembers) == "function" then
            local ok, n = pcall(GetNumPartyMembers)
            local count = ok and PD_Num(n, 0) or 0
            for i = 1, math.min(count, 4) do units[#units + 1] = "party" .. i end
        end
    end
    return units
end

function PD.IsTank(unit)
    if type(UnitGroupRolesAssigned) == "function" then
        local ok, role = pcall(UnitGroupRolesAssigned, unit)
        if ok and role == "TANK" then return true end
    end
    return false
end

function PD.SubgroupOf(unit)
    if not PD.InRaid() then return 1 end
    if type(UnitInRaid) ~= "function" then return nil end
    local ok, idx = pcall(UnitInRaid, unit)
    if not ok or type(idx) ~= "number" or idx <= 0 then return nil end
    if type(GetRaidRosterInfo) ~= "function" then return nil end
    local ok2, _, _, subgroup = pcall(GetRaidRosterInfo, idx)
    if ok2 and type(subgroup) == "number" then return subgroup end
    return nil
end

-- 治疗模式过滤：1全团 2目标 3预读 4坦克 5脆皮 6~10 一~五队
function PD.ModeAllowed(unit)
    local mode = PD.Val("JL_ZLMS", 1)
    if mode == 1 then return true end
    if mode == 2 or mode == 3 then
        if type(UnitExists) == "function" and UnitExists("target") and PD.IsFriend("target") and not PD.IsDead("target") then
            if unit == "target" then return true end
            if type(UnitIsUnit) == "function" then
                local ok, same = pcall(UnitIsUnit, unit, "target")
                if ok and same == true then return true end
            end
            return false
        end
        return true
    end
    if mode == 4 then return PD.IsTank(unit) end
    if mode == 5 then return not PD.IsTank(unit) end
    if mode >= 6 and mode <= 10 then
        local want = mode - 5
        local sub = PD.SubgroupOf(unit)
        if sub == nil then return true end
        return sub == want
    end
    return true
end

function PD.IsHealable(unit)
    if not PD.IsFriend(unit) or PD.IsDead(unit) then return false end
    local range = PD.RangeOf(unit)
    -- 999 = 读不到（secret/无目标），按未知放行；只有明确 >40 码才排除
    if range ~= nil and range > 40 and range < 999 then return false end
    return PD.ModeAllowed(unit)
end

function PD.LowestBelow(threshold)
    if threshold == nil or threshold <= 0 then return nil end
    local units = PD.GroupUnits()
    -- 目标/预读模式：把当前目标也纳入候选（队伍列表本身不含 target）
    local mode = PD.Val("JL_ZLMS", 1)
    if (mode == 2 or mode == 3) and type(UnitExists) == "function" and UnitExists("target") then
        units[#units + 1] = "target"
    end
    local best, bestHP = nil, threshold
    for _, u in ipairs(units) do
        if PD.IsHealable(u) then
            local hp = PD.HP(u)
            if hp > 0 and hp < bestHP then
                best, bestHP = u, hp
            end
        end
    end
    return best, bestHP
end

function PD.Moving()
    if type(WR_PlayerMove) ~= "function" then return false end
    local ok, moving = pcall(WR_PlayerMove)
    return ok and moving == true
end

function PD.BuffRemain(name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, "player", name)
    if ok then return PD_Num(v, 0) end
    return 0
end

function PD.UnitBuffRemain(unit, name)
    if type(WR_GetUnitBuffTime) ~= "function" then return 0 end
    local ok, v = pcall(WR_GetUnitBuffTime, unit, name)
    if ok then return PD_Num(v, 0) end
    return 0
end

-- 该单位此刻「有没有盾」。true = 有（不该再上）。
-- ★★★ 2026-11-21 三十七次修复：「牧师上了盾后还会继续亮盾」。
-- ------------------------------------------------------------
-- 旧实现只走 PD.UnitBuffRemain / WR_GetUnitDebuffTime → 帧级光环缓存。
-- 受限战斗里那条缓存会因为 GetAuraDataByIndex 抛「Auras cannot be accessed
-- when secret」而整段失败并保留旧值（往往是 nil），而 aura.name 若是 secret
-- 还会让名字比较抛错被 pcall 吞掉 → 一律返回「不存在」→ 每 tick 重亮 59。
-- 现在改走 Core 的多通道件（免读回 ID 直查 / 名字族直查 / 经典 UnitBuff /
-- 既有缓存 + 本地施放记账），**只采信肯定证据**；读不到一律当「没有」继续
-- 上盾（宁可多上一次，也不让色块挂死被 AHK 连按）。
function PD.ShieldUp(unit)
    if type(WR_Forever_ShieldUp) == "function" then
        local ok, v = pcall(WR_Forever_ShieldUp, unit)
        if ok and v == true then return true end
        return false
    end
    if PD.UnitBuffRemain(unit, "真言术：盾") > 0 then return true end
    if type(WR_GetUnitDebuffTime) == "function" then
        local ok, v = pcall(WR_GetUnitDebuffTime, unit, "虚弱灵魂")
        if ok and PD_Num(v, 0) > 0 then return true end
    end
    return false
end

function PD.HasShield(unit)
    return PD.ShieldUp(unit)
end

function PD.HasDispelType(unit, kind)
    if type(WR_UnitDebuffType) ~= "function" then return false end
    local names
    if kind == "Magic" then names = { "Magic", "魔法" }
    elseif kind == "Disease" then names = { "Disease", "疾病" }
    else names = { kind } end
    for _, name in ipairs(names) do
        local ok, hit = pcall(WR_UnitDebuffType, unit, name)
        if ok and hit == true then return true end
    end
    return false
end

-- 焦点是否已经是该单位
function PD.IsFocus(unit)
    if not unit then return false end
    if type(UnitExists) == "function" and UnitExists("focus") and type(UnitIsUnit) == "function" then
        local ok, same = pcall(function() return UnitIsUnit("focus", unit) == true end)
        return ok and same == true
    end
    return false
end

-- 设置焦点：优先走既有 WR_FocusUnit（与 AHK 宏槽一致），失败时手工点槽
function PD.FocusOn(unit, text)
    if not unit or unit == "" then return false end
    if PD.IsFocus(unit) then return true end
    if type(WR_FocusUnit) == "function" then
        local ok, done = pcall(WR_FocusUnit, unit, text or "治疗")
        if ok and done == true then return true end
    end
    local slot
    if unit == "player" then slot = 192
    elseif unit == "target" then slot = 147
    else
        local p = string.match(unit, "^party(%d)$")
        if p then slot = 175 + PD_Num(p, 0) end
        if not slot then
            local r = string.match(unit, "^raid(%d+)$")
            if r then slot = 120 + PD_Num(r, 0) end
        end
    end
    if slot and type(WR_ColorFrame_Show) == "function" then
        local ok, shown = pcall(WR_ColorFrame_Show, slot, (text or "治疗") .. "\n" .. unit)
        return ok and shown == true
    end
    return false
end

function PD.Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) == "function" then
        local ok, shown = pcall(WR_ColorFrame_ShowSkill, spell, slot)
        return ok and shown == true
    end
    if slot and type(WR_ColorFrame_Show) == "function" then
        local ok, shown = pcall(WR_ColorFrame_Show, slot, spell)
        return ok and shown == true
    end
    return false
end

-- ★★★ 2026-11-21 三十六次修复：「牧师脱战了还会亮惩击色块」。
-- ------------------------------------------------------------
-- 色块模型是「亮着 = 现在该按这个键」，但 WR_ColorFrame_Show 只在自己被调用的
-- 那一刻先隐藏全部再点亮一个 —— 也就是说：**本 tick 一个色块都没点亮时，上一 tick
-- 的色块不会自己消失**。MainLoop 的收尾清扫 WR_SoD_SweepPowerBlocked 只处理
-- 「资源不足」一种情形（Core/SoD_Runes.lua 注释写明：CD 中 / 无目标 / 脱战
-- 各有自己的机制，不在总闸层扩大改动面）。
-- 而戒律循环的脱战分支是「补完 BUFF 就 return false」，从来不熄灭任何槽位：
--   · 战斗最后一 tick 亮的 196 惩击 就此常亮；
--   · AHK 读到同色继续按 CTRL-NUMPADMINUS（/cast 惩击），脱战后真的把惩击打出去，
--     一打就又进战斗 → 用户看到的就是「脱战了还在亮、还在放」。
-- 修法：给「只在战斗中才有意义」的槽位一个显式熄灭入口，脱战时（以及本步判定
-- 不该亮时）主动收掉，不依赖别的步骤顺手覆盖。

-- 熄灭某个技能的色块（两侧 + 技能图标框），用于「本步此刻不该亮」时主动收掉
-- 上一 tick 的残留。优先走 Core 的 WR_HideSkillColorSlot（与总闸同一实现）。
function PD.Hide(spell, slot)
    if type(spell) ~= "string" or spell == "" then return false end
    if type(WR_HideSkillColorSlot) == "function" then
        local ok = pcall(WR_HideSkillColorSlot, spell, slot)
        if ok then return true end
    end
    -- 兜底：Core 未加载新函数时直接按槽位熄灭
    local s = slot
    if s == nil and type(WR_SoD_ResolveSlot) == "function" then
        local ok, v = pcall(WR_SoD_ResolveSlot, spell)
        if ok then s = v end
    end
    if s == nil then return false end
    local function hideOne(t)
        if type(t) == "table" and t[s] and t[s].Hide then pcall(t[s].Hide, t[s]) end
    end
    hideOne(ColorFrameArrayTopLeft)
    hideOne(ColorFrameArrayTopRight)
    hideOne(ColorTextArrayTopLeft)
    hideOne(ColorTextArrayTopRight)
    return false
end

-- 只在战斗中才有意义的输出 / 爆发槽位。脱战后必须主动熄灭：
--   196 惩击 / 87 暗言术：灭（输出）、197 黑暗献祭（种族技能）、181 种族爆发。
-- 治疗 / BUFF / 驱散类槽位不在此列：那些在脱战时本来就可能需要提示。
PD.CombatOnlySlots = {
    { spell = "惩击",       slot = 196 },
    { spell = "暗言术：灭", slot = 87  },
    { spell = "黑暗献祭",   slot = 197 },
    { spell = "种族爆发",   slot = 181 },
}

function PD.HideCombatOnly()
    local any = false
    for i = 1, #PD.CombatOnlySlots do
        local it = PD.CombatOnlySlots[i]
        if PD.Hide(it.spell, it.slot) then any = true end
    end
    return any
end

function PD.CastHeal(spell, slot, unit)
    if not unit then return false end
    if not PD.CanCast(spell) then return false end
    -- 本 tick 只负责把焦点切过去；治疗色块下一 tick 再亮（避免判旧焦点/打新焦点）
    if not PD.IsFocus(unit) then
        PD.FocusOn(unit)
        return true   -- 本 tick 只负责设焦点（AHK 下一 tick 才按 /focus）
    end
    return PD.Show(spell, slot)
end

-- 刚点亮盾、还在等 AHK 按键的保持窗口（由 Core 记账判定）。
function PD.ShieldHold(unit)
    if type(WR_Forever_ShieldPromptHold) ~= "function" then return false end
    local ok, v = pcall(WR_Forever_ShieldPromptHold, unit)
    return ok and v == true
end

-- ★★★ 2026-11-21 三十七次修复：「牧师上了盾后还会继续亮盾」。
-- ------------------------------------------------------------
-- 旧实现把盾当成普通 HealStep：选**最低血**的人 → extra 判他有盾就整步跳过。
-- 两个结构性问题：
--   ① 有盾判定本身在受限战斗里恒为「没有」（见 PD.ShieldUp 注释）→ 每 tick 重亮 59；
--   ② 即使判对了，只要「最低血的那个人」已经有盾，整步就跳过 —— 别人缺盾也不补，
--      而 AHK 读到 59 常亮时打的是焦点，往往把盾重复套在同一个人身上（白烧蓝 + GCD）。
-- 现在拆成专用步：
--   · 候选 = 低于拉条阈值 **且此刻没盾** 的人里血最少的那个；
--   · 判定有盾走 PD.ShieldUp（多通道 + 本地施放记账），只采信肯定证据；
--   · 点亮后记一笔 NoteShieldPrompt，保持窗口内继续亮但不重新记账
--     （防重入，否则窗口被无限续命 → 永久常亮）；
--   · 本 tick 不该亮（没候选 / 不可用 / 没焦点）→ **主动熄灭 59**，
--     不让上一 tick 的色块挂在那里被 AHK 连按。
function PD.ShieldStep()
    -- ★★★ 2026-11-21 三十九次修复：盾严格受滑块控制。
    --   ① 滑块=0（禁用）不仅要 return false，还必须**熄灭残留 59** ——
    --     否则把滑块拉到 0 后，上一 tick 亮的色块挂着被 AHK 连按，
    --     表现为「关了滑块还在上盾」；
    --   ② 阈值钳制到 0~100：存档异常值（>100）不允许把满血也判成低血；
    --   ③ 候选每 tick 都以**当前滑块值**重新过滤（下方循环），
    --     滑块调低后保持窗口不会续亮已高于阈值的目标。
    local threshold = PD.Val("JL_ZYSD", 80)
    if threshold > 100 then threshold = 100 end
    if threshold <= 0 then
        PD.Hide("真言术：盾", 59)
        return false
    end

    local units = PD.GroupUnits()
    local mode = PD.Val("JL_ZLMS", 1)
    if (mode == 2 or mode == 3) and type(UnitExists) == "function" and UnitExists("target") then
        units[#units + 1] = "target"
    end

    local best, bestHP = nil, threshold / 100
    for _, u in ipairs(units) do
        if PD.IsHealable(u) then
            local hp = PD.HP(u)
            if hp > 0 and hp < bestHP and not PD.ShieldUp(u) then
                best, bestHP = u, hp
            end
        end
    end

    if not best then
        PD.Hide("真言术：盾", 59)
        return false
    end

    -- 保持窗口内：继续亮（给 AHK 读屏按键的时间），但不重新记账
    if PD.ShieldHold(best) then
        return PD.Show("真言术：盾", 59)
    end

    if not PD.CanCast("真言术：盾") then
        PD.Hide("真言术：盾", 59)
        return false
    end
    if not PD.IsFocus(best) then
        PD.FocusOn(best)
        return true   -- 本 tick 只负责设焦点，色块下一 tick 再亮
    end

    local shown = PD.Show("真言术：盾", 59)
    if shown and type(WR_Forever_NoteShieldPrompt) == "function" then
        pcall(WR_Forever_NoteShieldPrompt, best)
    end
    if not shown then PD.Hide("真言术：盾", 59) end
    return shown
end

-- 单个治疗步骤：阈值拉条（0=关闭）→ 选最低血 → 焦点施法
function PD.HealStep(spell, slot, key, default, blockMoving, extra)
    local threshold = PD.Val(key, default)
    if threshold <= 0 then return false end
    local unit = PD.LowestBelow(threshold / 100)
    if not unit then return false end
    if blockMoving and PD.Moving() then return false end
    if extra and not extra(unit) then return false end
    return PD.CastHeal(spell, slot, unit)
end

-- ============================================================
-- 3. 基础状态 / 停手门
-- ============================================================
function PD.Base()
    GCD = (type(WR_GetGCD) == "function" and WR_GetGCD("治疗术")) or 0
    PlayerHP = PD.HP("player")
    PlayerMP = PD.MP("player")
    PD.Casting = nil
    PD.Channel = nil
    if type(WR_SafeCastingName) == "function" then
        local ok, v = pcall(WR_SafeCastingName, "player")
        if ok then PD.Casting = v end
    end
    if type(WR_SafeChannelName) == "function" then
        local ok, v = pcall(WR_SafeChannelName, "player")
        if ok then PD.Channel = v end
    end
    PD.InCombat = false
    if type(UnitAffectingCombat) == "function" then
        local ok, v = pcall(UnitAffectingCombat, "player")
        PD.InCombat = ok and v == true
    end
end

function PD.StopGate()
    if PD.Casting or PD.Channel then return true end
    local stop = PD.IsDead("player")
    if not stop and type(IsMounted) == "function" then
        local ok, mounted = pcall(IsMounted)
        if ok and mounted then stop = true end
    end
    if not stop and type(UnitInVehicle) == "function" then
        local ok, v = pcall(UnitInVehicle, "player")
        if ok and v then stop = true end
    end
    if not stop and type(WR_GetUnitBuffTime) == "function" then
        local ok, v = pcall(WR_GetUnitBuffTime, "player", { "喝水", "进食", "饮用", "食物", "饮料", "饮水" }, nil, "NAME")
        if ok and type(v) == "number" and v > 0 then stop = true end
    end
    return stop
end

-- 防ADD：1=是（只在自己战斗中治疗） 2=否（任一队友战斗中即治疗）
function PD.CombatGate()
    if PD.InCombat then return true end
    if PD.Val("JL_FADD", 1) == 1 then return false end
    for _, u in ipairs(PD.GroupUnits()) do
        if type(UnitAffectingCombat) == "function" then
            local ok, v = pcall(UnitAffectingCombat, u)
            if ok and v == true then return true end
        end
    end
    return false
end

-- ============================================================
-- 4. 自保 / 黑暗献祭 / BUFF / 驱散 / 输出
-- ============================================================
function PD.SelfPotion()
    if PD.HP("player") >= PD.Val("JL_HXY", 30) / 100 then return false end
    if type(WR_Use_ZLYS) ~= "function" then return false end
    local ok, can = pcall(WR_Use_ZLYS)
    if ok and can == true and type(WR_ColorFrame_Show) == "function" then
        local ok2, shown = pcall(WR_ColorFrame_Show, "CSF", "治疗药水")
        if ok2 and shown then return true end
    end
    return false
end

-- 黑暗献祭：亡灵牧师种族技能，15 秒扣血换法力；血量高于拉条（安全下限）且法力低于80%时使用
function PD.DarkSacrificeStep()
    if not PD.InCombat then return false end
    local threshold = PD.Val("JL_HZ", 30)
    if threshold <= 0 then return false end
    if PD.HP("player") < threshold / 100 then return false end
    -- 法力高于 80% 不用；UNIT_POWER 可读时取真实比例，读不到（战斗 secret）
    -- 时按 WR_GetUnitMP 的安全口径（满蓝）处理，不在满蓝时白扣血。
    local mpPct = PD.MP("player")
    if type(UnitPower) == "function" and type(UnitPowerMax) == "function" then
        local ok1, cur = pcall(UnitPower, "player", 0)
        local ok2, max = pcall(UnitPowerMax, "player", 0)
        if ok1 and ok2 and type(cur) == "number" and type(max) == "number" and max > 0
           and not (type(WR_IsSecretValue) == "function" and (WR_IsSecretValue(cur) or WR_IsSecretValue(max))) then
            mpPct = cur / max
        end
    end
    if mpPct > 0.80 then return false end
    if not PD.CanCast("黑暗献祭") then return false end
    return PD.Show("黑暗献祭", 197)
end

-- ============================================================
-- 4. 自身增益维持（真言术：韧 / 心灵之火）
-- ============================================================
--
-- ★★★ 2026-11-21 四十二次修复：「韧 / 心灵之火 连补两下」。
-- ------------------------------------------------------------
-- 色块模型：亮着 = 现在该按这个键；外部 AHK 每 ~60ms 扫一次，
-- 同色常亮就一直按（见 Core/GX.lua 既有记录）。
-- 旧实现把「已生效 → 主动熄灭 52」这条判定压在 **2 秒节流之后**：
--   点亮 52 之后，色块要一直挂到下一个节流窗口（2 秒）才被收掉，
--   而 GCD 只有 1.5 秒 → GCD 一过 AHK 就再按一次 → 韧被打了两下。
-- 现在把「已生效」的判定抽成**每 tick 的收口路径**（PD.SelfBuffSettle）：
--   确认已生效 / 已打出 → 立刻熄色块，绝不让色块跨过 GCD；
--   2 秒节流只约束「点亮」，不再约束「熄灭」。
PD.SETTLE_GAP = 0.25        -- 收口路径的最小间隔（秒）
PD.SettleAt = 0
-- 点亮窗口上限（秒）：**必须小于 GCD 1.5 秒**。
-- 色块跨过 GCD 仍亮着 → AHK 在 GCD 转好后的下一次扫描会再按一次 → 补两下。
PD.FORT_LIT_MAX = 1.0
-- 熄色块后的重试闩锁（秒）：这一发没打出去也不要立刻重亮。
PD.FORT_RETRY_GAP = 2.5
PD.FortLitAt = nil          -- 52 本轮连续亮起的起点
PD.FortRetryAt = 0          -- 下次允许点亮 52 的时刻
-- 自身增益（心灵之火）同构参数
PD.SELF_LIT_MAX = 1.0
PD.SELF_RETRY_GAP = 2.5
PD.SelfLitAt = {}           -- 名字 → 本轮连续亮起的起点
PD.SelfRetryAt = {}         -- 名字 → 下次允许点亮的时刻

-- 韧此刻是否已生效（多通道：ID 直查 / 名字族 / 经典 UnitBuff / 本地施放记账）
function PD.FortitudeUp()
    if type(WR_Forever_FortitudeUp) == "function" then
        local ok, v = pcall(WR_Forever_FortitudeUp, "player")
        if ok and v == true then return true end
        return false
    end
    return PD.BuffRemain("真言术：韧") > 0
end

-- 自身增益此刻是否已生效（通用件：心灵之火等）
function PD.SelfBuffUp(name, duration)
    if type(WR_Forever_SelfBuffUp) == "function" then
        local ok, v = pcall(WR_Forever_SelfBuffUp, name, duration, "player")
        if ok and v == true then return true end
        return false
    end
    return PD.BuffRemain(name) > 0
end

-- 「这一发已经打出去」（本地施放记账，零 API 调用）→ 色块该灭了。
function PD.FortitudeLanded()
    if type(WR_Forever_FortitudeCastLanded) ~= "function" then return false end
    local ok, v = pcall(WR_Forever_FortitudeCastLanded, "player")
    return ok and v == true
end

function PD.SelfBuffLanded(name)
    if type(WR_Forever_SelfBuffCastLanded) ~= "function" then return false end
    local ok, v = pcall(WR_Forever_SelfBuffCastLanded, name, "player")
    return ok and v == true
end

-- 点亮窗口是否仍然开着（用于「窗口内续亮，等 AHK 扫到」）。
function PD.LitWindowOpen(litAt, maxLit)
    if type(litAt) ~= "number" then return false end
    local now = type(GetTime) == "function" and GetTime() or 0
    return (now - litAt) < (maxLit or 1.0)
end

-- 每 tick 收口：已生效 → 立刻熄灭对应色块。
-- 绝不因为「本 tick 一个色块都没点亮」而让上一 tick 的 52/31 挂屏被 AHK 连按。
-- 顺序：① 轻量记账（这一发已出去，零 API，最快）→ ② 光环复查（提示还在等时）。
function PD.SelfBuffSettle()
    local now = type(GetTime) == "function" and GetTime() or 0
    if (now - (PD.SettleAt or -1e9)) < (PD.SETTLE_GAP or 0.25) then return false end
    PD.SettleAt = now
    local any = false
    -- 韧
    if PD.On("JL_ZYSR", true) then
        if PD.FortitudeLanded() then
            -- 这一发确实打出去了 → 立刻熄色块（否则 GCD 一过 AHK 再按一次 → 补两下）
            PD.Hide("真言术：韧", 52)
            PD.FortLitAt = nil
            PD.FortRetryAt = 0
            any = true
        elseif type(PD.FortLitAt) == "number"
            and (now - PD.FortLitAt) >= (PD.FORT_LIT_MAX or 1.0) then
            -- 点亮窗口到期仍未确认施放 → 熄色块 + 进重试闩锁
            -- （窗口 1.0 秒 < GCD 1.5 秒 → 必然在 GCD 转好之前熄灭）
            PD.Hide("真言术：韧", 52)
            PD.FortLitAt = nil
            local untilAt = now + (PD.FORT_RETRY_GAP or 2.5)
            if (PD.FortRetryAt or 0) < untilAt then PD.FortRetryAt = untilAt end
            any = true
        end
    else
        PD.Hide("真言术：韧", 52)
        PD.FortLitAt = nil
    end
    -- 心灵之火（与真言术：韧同构）
    if PD.On("JL_XLHZ", true) then
        if PD.SelfBuffLanded("心灵之火") then
            PD.Hide("心灵之火", 31)
            PD.SelfLitAt["心灵之火"] = nil
            PD.SelfRetryAt["心灵之火"] = 0
            any = true
        elseif type(PD.SelfLitAt["心灵之火"]) == "number"
            and (now - PD.SelfLitAt["心灵之火"]) >= (PD.SELF_LIT_MAX or 1.0) then
            PD.Hide("心灵之火", 31)
            PD.SelfLitAt["心灵之火"] = nil
            local untilAt = now + (PD.SELF_RETRY_GAP or 2.5)
            if (PD.SelfRetryAt["心灵之火"] or 0) < untilAt then PD.SelfRetryAt["心灵之火"] = untilAt end
            any = true
        end
    else
        PD.Hide("心灵之火", 31)
        PD.SelfLitAt["心灵之火"] = nil
    end
    return any
end

function PD.BuffStep()
    local now = type(GetTime) == "function" and GetTime() or 0
    -- ★ 四十二次修复：收口先行，**不受 2 秒节流约束** ——
    --   已生效就立刻熄 52/31，否则色块会跨过 GCD 被 AHK 连按（连补两下）。
    PD.SelfBuffSettle()
    -- 2 秒节流：只约束「点亮」，不再约束「熄灭」
    if now - (PD.LastBuffAt or -1e9) < 2.0 then return false end
    PD.LastBuffAt = now
    -- ★★★ 2026-11-21 四十一次修复：「维持真言术：韧没兼容低级法术」。
    -- 截图实证：1级小号身上的韧是「真言术：韧 等级1 · spellID 1243」。
    -- 旧实现只走 PD.BuffRemain("真言术：韧") → 光环缓存名字精确匹配：
    --   低 rank 光环名带「(等级 1)」后缀 / 战斗中缓存 secret 失败时一律判「没韧」
    --   → 每 2 秒重亮 52 → AHK 反复补一个已经挂着的 buff。
    -- 现在走 Core 的韧全 rank 专用件（WR_Forever_FortitudeUp）：
    --   全 rank ID 直查（1243~25389 + 坚韧祷言群体版）→ 名字族（含带等级后缀写法）
    --   → 经典 UnitBuff → 缓存 → 本地施放记账（spellID 通道，名字 secret 也能记）。
    -- 有韧（任意 rank / 群体韧）→ 不亮且**主动熄灭 52**；保持窗口内继续亮不重记账。
    if PD.On("JL_ZYSR", true) then
        local fortUp = PD.FortitudeUp()
        if fortUp then
            PD.Hide("真言术：韧", 52)
            PD.FortLitAt = nil
            PD.FortRetryAt = 0
        elseif not PD.IsFocus("player") then
            -- 宏 52 是 [@focus] 真言术：韧：焦点没到位就补会把韧刷到别人身上
            -- （白烧蓝 + 补错人）。本 tick 只亮「设焦点」色块（192）——
            -- 色块模型下 Show 会先隐藏全部，52 自然被熄掉。
            PD.FocusOn("player", "韧")
            PD.FortLitAt = nil
            return true
        elseif now < (PD.FortRetryAt or 0) then
            -- 重试闩锁内：不点亮（上一发没打出去也别马上重来）
            PD.Hide("真言术：韧", 52)
        elseif PD.LitWindowOpen(PD.FortLitAt, PD.FORT_LIT_MAX) then
            -- 还在点亮窗口内：续亮，让 AHK 扫到（不重新记账）
            return PD.Show("真言术：韧", 52)
        elseif PD.CanCast("真言术：韧") then
            local shown = PD.Show("真言术：韧", 52)
            if shown then
                PD.FortLitAt = now
                if type(WR_Forever_NoteFortPrompt) == "function" then
                    pcall(WR_Forever_NoteFortPrompt, "player")
                end
            end
            return shown
        else
            PD.Hide("真言术：韧", 52)
        end
    else
        PD.Hide("真言术：韧", 52)
        PD.FortLitAt = nil
    end
    -- ★★★ 2026-11-21 四十一次修复（同构收口）：「心灵之火」也走多通道 + 保持窗口。
    -- 旧写法 PD.BuffRemain("心灵之火") 只认光环缓存的精确名字 → 低 rank 名字带
    -- 「(等级 N)」后缀时永远判「没有」→ 每 2 秒重亮 31 槽位反复施放；
    -- 且「已经挂着」时不熄灭、「技能不可用」时不熄灭 → 残留色块挂屏被 AHK 连按。
    -- 现在走 Core 的通用自身增益专用件（多通道存在性 + 本地施放记账 + 提示保持窗口），
    -- 与真言术：韧同构；判定「已经挂着 / 开关关 / 不可用」都主动熄灭 31。
    if PD.On("JL_XLHZ", true) then
        local fireUp = PD.SelfBuffUp("心灵之火", 30)
        if fireUp then
            PD.Hide("心灵之火", 31)
            PD.SelfLitAt["心灵之火"] = nil
            PD.SelfRetryAt["心灵之火"] = 0
        elseif now < (PD.SelfRetryAt["心灵之火"] or 0) then
            PD.Hide("心灵之火", 31)
        elseif PD.LitWindowOpen(PD.SelfLitAt["心灵之火"], PD.SELF_LIT_MAX) then
            -- 还在点亮窗口内：续亮，让 AHK 扫到（不重新记账）
            return PD.Show("心灵之火", 31)
        elseif PD.CanCast("心灵之火") then
            local shown = PD.Show("心灵之火", 31)
            if shown then
                PD.SelfLitAt["心灵之火"] = now
                if type(WR_Forever_NoteSelfBuffPrompt) == "function" then
                    pcall(WR_Forever_NoteSelfBuffPrompt, "心灵之火")
                end
            end
            return shown
        else
            PD.Hide("心灵之火", 31)
        end
    else
        PD.Hide("心灵之火", 31)
        PD.SelfLitAt["心灵之火"] = nil
    end
    return false
end

-- 驱散：自己优先，其次队友；魔法用驱散魔法，疾病用驱除疾病
function PD.DispelStep()
    if not PD.On("JL_QS_ON", true) then return false end
    if PD.Val("JL_QS", 2) == 5 then return false end
    local now = type(GetTime) == "function" and GetTime() or 0
    if now - (PD.LastDispelAt or -1e9) < 0.5 then return false end
    -- 自己
    if PD.HasDispelType("player", "Magic") and PD.CanCast("驱散魔法") then
        PD.LastDispelAt = now
        return PD.Show("驱散魔法", 79)
    end
    if PD.HasDispelType("player", "Disease") and PD.CanCast("驱除疾病") then
        if not PD.IsFocus("player") then
            PD.FocusOn("player", "驱病")
            return false
        end
        PD.LastDispelAt = now
        return PD.Show("驱除疾病", 62)
    end
    -- 队友
    for _, u in ipairs(PD.GroupUnits()) do
        if u ~= "player" and PD.IsHealable(u) then
            local magic = PD.HasDispelType(u, "Magic") and PD.CanCast("驱散魔法")
            local disease = (not magic) and PD.HasDispelType(u, "Disease") and PD.CanCast("驱除疾病")
            if magic or disease then
                if not PD.IsFocus(u) then
                    PD.FocusOn(u, "驱散")
                    return false
                end
                PD.LastDispelAt = now
                if magic then return PD.Show("驱散魔法", 63) end
                return PD.Show("驱除疾病", 62)
            end
        end
    end
    return false
end

function PD.OffenseStep()
    -- ★★★ 2026-11-21 三十六次修复：本步「不该亮」时必须主动熄灭自己的槽位。
    -- 色块不会因为 return false 就消失（WR_ColorFrame_Show 只在自己被调用时才
    -- 先隐藏全部），而 MainLoop 的收尾清扫只管「资源不足」一种情形。
    -- 于是「没有可攻击目标 / 目标已死 / 目标敌对不成立 / 超出射程」这些早退路径
    -- 全部会把上一 tick 的 196 惩击留在屏幕上 → AHK 继续按 → 脱战了还在放惩击。
    local function bail()
        PD.Hide("惩击", 196)
        PD.Hide("暗言术：灭", 87)
        return false
    end
    -- 脱战不输出：防ADD=否时主循环脱战分支会继续往下走，最终经 PD.Post 到本步；
    -- 若此时留着目标，旧实现会一直亮 196 惩击 → AHK 连按 → 脱战了还在放惩击。
    if not PD.InCombat then return bail() end
    if type(UnitExists) ~= "function" or not UnitExists("target") then return bail() end
    if PD.IsDead("target") then return bail() end
    if type(UnitCanAttack) == "function" then
        local ok, attack = pcall(UnitCanAttack, "player", "target")
        if not ok or attack ~= true then return bail() end
    end
    local range = PD.RangeOf("target")
    if range ~= nil and range > 30 then return bail() end
    if PD.On("JL_AYSHM", false) and PD.CanCast("暗言术：灭") then
        if PD.Show("暗言术：灭", 87) then return true end
        return bail()
    end
    if PD.On("JL_CJ", true) and PD.CanCast("惩击") then
        if PD.Show("惩击", 196) then return true end
        return bail()
    end
    return bail()
end

-- ============================================================
-- 5. 插入（一次性，放完自关）
-- ============================================================
PD.Inserts = {
    { var = "JL_CRGNZ",  spell = "能量灌注", slot = 149, needFocus = false },
    { var = "JL_CRXX",   spell = "神圣新星", slot = 49,  needFocus = false },
    { var = "JL_CRZLDY", spell = "治疗祷言", slot = 53,  needFocus = true  },
}

function PD.InsertStep()
    for _, item in ipairs(PD.Inserts) do
        if PD.On(item.var, false) then
            if PD.SpellAbsent(item.spell) then
                PigSet[item.var] = false
                PD.SyncCheckbox(item.var)
                return false
            end
            if not PD.CanCast(item.spell) then return false end
            if item.needFocus then
                local unit = nil
                if PD.IsFriend("focus") and not PD.IsDead("focus") then unit = "focus"
                else unit = PD.LowestBelow(1.01) or "player" end
                if not PD.IsFocus(unit) then
                    PD.FocusOn(unit, item.spell)
                    return false
                end
            end
            if PD.Show(item.spell, item.slot) then
                PigSet[item.var] = false
                PD.SyncCheckbox(item.var)
                return true
            end
            return false
        end
    end
    return false
end

-- ============================================================
-- 6. 爆发：种族爆发
-- ------------------------------------------------------------
-- ★ 2026-11-21：面板上的「爆发槽位1/2/3」「爆发全开/全关/切换」六个按钮、
--   以及爆发分组里的「槽位1/2/3」三个图标全部删除，只留「种族爆发」。
--   循环里对应的三槽位分支（PD.BurstSlotValue / BurstSetAll / CycleBurstSlot
--   / PD.BurstChoices）同步下线，本步只剩种族爆发一条路径。
-- ============================================================
-- ★★★ 2026-11-21 四十次修复：「种族技能只在目标是怪物时才释放」。
-- ------------------------------------------------------------
-- 用户口径：牧师种族技能添加限制 —— 当目标是**怪物**的时候才释放。
-- 怪物 = 目标存在 + 存活 + 可攻击 + 不是玩家 + 不是玩家控制的单位
-- （宠物 / 被精神控制的玩家）。敌对玩家（PVP）与友方 NPC 都不算。
-- 任何一环读不到都按「不是怪物」处理（宁可不放，符合限制口径）。
function PD.TargetIsMonster()
    if type(UnitExists) ~= "function" then return false end
    local okE, exists = pcall(UnitExists, "target")
    if not okE or exists ~= true then return false end
    if PD.IsDead("target") then return false end
    if type(UnitCanAttack) ~= "function" then return false end
    local okA, attack = pcall(UnitCanAttack, "player", "target")
    if not okA or attack ~= true then return false end
    if type(UnitIsPlayer) == "function" then
        local okP, isPlayer = pcall(UnitIsPlayer, "target")
        if not okP or isPlayer == true then return false end
    end
    -- 玩家宠物 / 被控制单位不算怪物（API 缺失时跳过这一环）
    if type(UnitPlayerControlled) == "function" then
        local okC, controlled = pcall(UnitPlayerControlled, "target")
        if okC and controlled == true then return false end
    end
    return true
end

function PD.BurstStep()
    -- ★ 四十次修复：种族爆发只在「目标是怪物」时点亮；不满足时走本步
    -- 尾部的主动熄灭（181 不残留），与既有 CD / 已学会 / 保持窗口门叠加。
    if PD.On("JL_BF_RACE", true) and PD.TargetIsMonster() then
        -- ★★★ 2026-11-21 三十四次修复：「1级小号牧师卡种族爆发色块」。
        -- ------------------------------------------------------------
        -- 旧实现：优先用 WR_Forever_GetRacialBursts（按**阵营**返回，部落固定是
        -- {血性狂怒, 狂暴}），再逐个问 CanCast。两个坑叠在一起：
        --   ① 按阵营取列表 → 亡灵/牛头牧师也会去试「血性狂怒」「狂暴」，
        --      这两个技能它根本没有；
        --   ② 旧 WR_SpellUsable 对「不存在的技能」不判死（C_Spell.IsSpellUsable
        --      只判资源/CD，私服还会对解析不出的名字直接回 true）→ 恒可用；
        --   于是每 tick 都点亮宏槽 181。而宏体三条 /cast 全是没学会的技能，
        --   客户端一条都不执行 → 色块不灭 → AHK 连按 → 主循环永远停在爆发步，
        --   后面的惩击/治疗一步都轮不到。用户看到的就是「卡种族爆发色块」。
        --
        -- 现在：先按**种族**取列表（WR_Forever_PlayerRacialBursts），再对每个
        -- 真实技能名做一次「已学会」硬门（WR_Forever_SpellLearned），最后才
        -- 问可用性。三道门全过才点亮；全都没学会 → 本步直接跳过，不影响循环。
        --
        -- ★★★ 2026-11-21 三十五次修复：「使用了种族技能还是一直亮」。
        -- ------------------------------------------------------------
        -- 三十四次修复只堵了「没学会」这一维，CD 维度仍是漏的：
        --   · 用户截图实证的 狂暴（种族特长，spellID 20554）是 **3 分钟** 冷却，
        --     打出去之后本步每 tick 仍判「可用」→ 每 tick 重亮槽位 181；
        --   · 根因：无限战斗中 GetSpellCooldown 是 secret → WR_GetGCD 收敛成 0 →
        --     WR_SpellUsable 的 GCD 门恒成立；而全仓此前**没有任何本地施放记账**，
        --     技能真打出去了插件完全不知道。
        -- 现在改走 WR_Forever_BurstReady（Core/Forever_Compat.lua）：
        --   已学会 → 本地记账 CD → 客户端冷却 → 提示保持窗口 → 客户端可用性，
        --   任一门判死就不点亮；并且**主动熄灭 181 槽位**，不让上一 tick 的
        --   色块挂在那里被 AHK 连按。
        -- 统一走 WR_Forever_RacialBurstReady（Core/Forever_Compat.lua）：
        -- 按种族精确取列表 → 已学会 → 本地施放记账 CD → 客户端冷却 →
        -- 提示保持窗口 → 客户端可用性，任一门判死都不点亮。
        local hit
        if type(WR_Forever_RacialBurstReady) == "function" then
            local okR, v = pcall(WR_Forever_RacialBurstReady)
            if okR and type(v) == "string" then hit = v end
        else
            -- 兼容回退（旧 Core 未加载新函数时仍按原口径工作）
            local fn = WR_Forever_PlayerRacialBursts or WR_Forever_GetRacialBursts
            if type(fn) == "function" then
                local ok, bursts = pcall(fn)
                if ok and type(bursts) == "table" then
                    for i = 1, #bursts do
                        local name = bursts[i]
                        if type(name) == "string" and name ~= "" and PD.CanCast(name) then
                            hit = name
                            break
                        end
                    end
                end
            end
        end
        if hit then
            if PD.Show("种族爆发", 181) then
                if type(WR_Forever_NoteBurstPrompt) == "function" then
                    pcall(WR_Forever_NoteBurstPrompt, hit,
                         (type(WR_Forever_RacialBurstCD) == "table"
                          and WR_Forever_RacialBurstCD[hit])
                         or WR_Forever_RACIAL_BURST_DEFAULT_CD or 180)
                end
                return true
            end
        end
    end
    -- 本步不亮 = 此刻不该按爆发键。上一 tick 的 181 色块不会自己消失
    -- （WR_ColorFrame_Show 只在「有别的步骤点亮」时才顺手隐藏全部），
    -- 必须主动熄灭，否则 AHK 读到同色继续按 → 用户看到的「一直亮」。
    if type(WR_Forever_HideRacialBurst) == "function" then
        pcall(WR_Forever_HideRacialBurst, 181)
    elseif type(WR_HideSkillColorSlot) == "function" then
        pcall(WR_HideSkillColorSlot, "种族爆发", 181)
    end
    return false
end

-- ============================================================
-- 7. Pre / Post
-- ============================================================
function PD.Pre()
    if PD.InsertStep() then return true end
    if PD.BurstStep() then return true end
    return false
end

function PD.Post()
    if PD.DispelStep() then return true end
    if PD.OffenseStep() then return true end
    return false
end

-- ============================================================
-- 8. 主循环
-- ============================================================
function WR_PriestForeverDiscipline()
    PD.InitDefaults()
    PD.Base()
    -- ★★★ 2026-11-21 三十九次修复：滑块=0（禁用）时，无论后面哪道门早退
    -- （施法/引导/坐骑/脱战/防ADD），残留的 59 盾色块都在第一时间收掉，
    -- 保证「关滑块 = 立刻不再上盾」严格成立。
    if PD.Val("JL_ZYSD", 80) <= 0 then PD.Hide("真言术：盾", 59) end
    -- ★★★ 2026-11-21 四十二次修复：自增益色块（52 韧 / 31 心灵之火）每 tick 收口。
    --   BuffStep 里的「已生效 → 主动熄灭」判定被 2 秒节流压着，色块会挂满 2 秒；
    --   而 GCD 只有 1.5 秒 → GCD 一过 AHK 就再按一次 → 「补的时候会连补两下」。
    --   这里把收口提到战斗/脱战都每 tick 跑（PD.SelfBuffSettle 自带 0.25 秒节流），
    --   一旦确认韧/心灵之火已生效就立刻熄色块，绝不让它跨过 GCD。
    PD.SelfBuffSettle()
    -- ★★★ 2026-11-21 三十六次修复：脱战熄灭必须排在 StopGate **之前**。
    -- 原实现只 return false，不熄灭任何东西 → 战斗最后一 tick 亮的 196 惩击
    -- 常亮不灭，AHK 读到同色继续按 → 脱战后还在放惩击（一打就又进战斗）。
    -- 放在 StopGate 前还有一层意义：坐下喝水/施法中 StopGate 会早退，
    -- 若排在后面，这些状态下残留色块同样收不掉。
    if not PD.InCombat then
        PD.HideCombatOnly()
        -- ★ 三十九次修复：防ADD=是 → 脱战完全不治疗，ShieldStep 不会执行；
        --   战斗最后一 tick 的盾色块必须在这里收掉（放在 BuffStep 之前 ——
        --   BuffStep 命中会 return true 早退，排后面就轮不到熄灭）。
        if PD.Val("JL_FADD", 1) == 1 then PD.Hide("真言术：盾", 59) end
    end
    if PD.StopGate() then return true end

    -- 脱战：只维持自身 BUFF；防ADD=是 时不进入治疗
    if not PD.InCombat then
        if PD.BuffStep() then return true end
        if PD.Val("JL_FADD", 1) == 1 then return false end
    end

    if PD.SelfPotion() then return true end
    if PD.DarkSacrificeStep() then return true end

    if not PD.CombatGate() then return false end
    if PD.Pre() then return true end

    -- 驱散「优先」模式：先驱散再治疗
    if PD.Val("JL_QS", 2) == 2 then
        if PD.DispelStep() then return true end
    end

    -- 治疗链：盾 → 苦修 → 联结治疗 → 快速治疗 → 强效治疗术 → 治疗术 → 次级治疗术 → 恢复
    -- ★ 三十七次修复：盾走专用步（候选 = 低于阈值且此刻没盾的人；本步不亮时主动熄灭 59）
    if PD.ShieldStep() then return true end
    if PD.HealStep("苦修", 54, "JL_KX", 70, true) then return true end
    if PD.HealStep("联结治疗", 56, "JL_LJZL", 70, true) then return true end
    if PD.HealStep("快速治疗", 57, "JL_KSZL", 50, true) then return true end
    if PD.HealStep("强效治疗术", 77, "JL_QXZLS", 75, true) then return true end
    if PD.HealStep("治疗术", 194, "JL_ZLSHU", 75, true) then return true end
    if PD.HealStep("次级治疗术", 195, "JL_CJZLS", 75, true) then return true end
    if PD.HealStep("恢复", 55, "JL_HF", 90, false, function(u) return PD.UnitBuffRemain(u, "恢复") <= 0 end) then return true end

    if PD.Post() then return true end
    return false
end

-- ============================================================
-- 9. 诊断命令
-- ============================================================
SLASH_MKPDISC1 = "/mkpdisc"
SlashCmdList["MKPDISC"] = function()
    print("|cffFF69B4[MKHelperForever 戒律]|r 全团治疗诊断")
    print("  防ADD JL_FADD=" .. tostring(PD.Val("JL_FADD",1)) .. "（1是/2否）"
        .. "  治疗模式 JL_ZLMS=" .. tostring(PD.Val("JL_ZLMS",1)))
    print("  拉条：喝红药=" .. tostring(PD.Val("JL_HXY",30))
        .. " 黑暗献祭=" .. tostring(PD.Val("JL_HZ",30))
        .. " 盾=" .. tostring(PD.Val("JL_ZYSD",80))
        .. " 苦修=" .. tostring(PD.Val("JL_KX",70))
        .. " 联结=" .. tostring(PD.Val("JL_LJZL",70))
        .. " 快速=" .. tostring(PD.Val("JL_KSZL",50))
        .. " 强效=" .. tostring(PD.Val("JL_QXZLS",75))
        .. " 治疗=" .. tostring(PD.Val("JL_ZLSHU",75))
        .. " 次级=" .. tostring(PD.Val("JL_CJZLS",75))
        .. " 恢复=" .. tostring(PD.Val("JL_HF",90)))
    local unit, hp = PD.LowestBelow(1.01)
    if unit then
        print("  当前最低血 = " .. tostring(unit) .. string.format("（%.0f%%）", (hp or 1) * 100))
    else
        print("  当前最低血 = 无（全团满血或读不到）")
    end
    print("  焦点可用 = " .. tostring(PD.IsFriend("focus") and not PD.IsDead("focus")))
end
