-- ============================================================
-- Warlock_Forever.lua  《魔兽世界：无限》(Forever) WARLOCK 循环公共件
-- ------------------------------------------------------------
-- 2026-11-13 重写：旧机械转译循环删除，按参考图语义重建功能模块：
--   DOT 维持 / 读条引导 / 护甲 / 召唤宠物 / 拉条阈值 / 插入 / 切目标 / 宠物攻击。
-- 面板（Warlock_Menu.lua）零改动：全部语义通过读取现有 PigSet 键实现；
--   参考图有而面板无键的阈值（生命分流30% / 高血分流80% / 喝红药30% /
--   魔杖回蓝50%）用固定默认值，来源=参考图，见 WR_WarlockForever_Thresholds。
-- 无限服兼容：血蓝走 WR_GetUnitHP/MP、光环走 WR_GetUnit*Time、可用性走
--   WR_SpellUsable、色块走 WR_ColorFrame_ShowSkill；不注册 CLEU、不裸算 secret。
-- 作用域：仅 WARLOCK（文件头守卫）；共享 helper 全部全局（跨文件调用）。
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

-- ★ 拉条阈值（参考图默认值；面板无对应滑块键，故固定）
WR_WarlockForever_Thresholds = {
    LifeTapMP   = 0.30,  -- 生命分流：蓝低于 30%
    LifeTapHP   = 0.40,  -- 生命分流：血高于 40% 才分流（保命下限）
    HighTapHP   = 0.80,  -- 高血分流：血高于 80%
    HighTapMP   = 0.60,  -- 高血分流：蓝低于 60% 时主动换蓝
    RedPotionHP = 0.30,  -- 喝红药：血低于 30%（邪能治疗石）
    WandMP      = 0.50,  -- 魔杖回蓝：蓝低于 50% 且无技能可打时 /startattack
}

-- ★ 一次性插入记账：{ [PigSet键] = { spell=技能名, since=点亮时刻, deadline=超时时刻 } }
--   字段名不可用 until：Lua 保留字（repeat...until），作表键会语法报错。
WR_WarlockForever_PendingInsert = WR_WarlockForever_PendingInsert or {}
-- ★ 切目标防抖（秒）
WR_WarlockForever_LastTab = WR_WarlockForever_LastTab or 0

-- ★ 引导类技能 → 色块槽位（引导中要熄灭自己的槽，否则 AHK 连按会打断引导）
WR_WarlockForever_ChannelSlots = {
    ["吸取灵魂"] = 11,
    ["吸取生命"] = 86,
    ["折磨"]     = 91,
}

-- ------------------------------------------------------------
-- 基础变量：每 tick 采集一次，供各段共用（全部走无限安全层）
-- ★ 必须在任何消费这些全局的分支之前调用（薄壳不得提前读）
-- ------------------------------------------------------------
function WR_WarlockForever_Base()
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("暗影箭")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    TargetDeathTime = WR_GetUnitDeathTime("target")
    WR_WarlockForever_TargetOK = UnitExists("target")
        and not UnitIsDeadOrGhost("target")
        and UnitCanAttack("player", "target")
    WR_WarlockForever_InRange = (TargetRange and TargetRange <= 35)
    WR_WarlockForever_Casting = WR_SafeCastingName("player")
    WR_WarlockForever_Channel = WR_SafeChannelName("player")
end

-- ------------------------------------------------------------
-- 停手门：死亡/骑乘/载具/吃喝 → 不提示；
-- 引导续接：正在引导 吸取灵魂/吸取生命/折磨 时熄灭该槽并结束本 tick（不打断）。
-- ★ 色块是「亮着就一直按」模型：只 return false 不熄灭，AHK 会连按打断引导。
-- 返回：true=本 tick 应直接结束（外层 return false）
-- ------------------------------------------------------------
function WR_WarlockForever_StopGate()
    local ch = WR_WarlockForever_Channel
    if ch and WR_WarlockForever_ChannelSlots[ch] then
        -- ★ nil 判定而非 type()=="function"：仓库老坑——跨文件可调用对象可能
        --   是 userdata（lupa 夹具/旧版客户端），type 守卫会让整段静默跳过。
        if WR_HideSkillColorSlot ~= nil then
            WR_HideSkillColorSlot(ch, WR_WarlockForever_ChannelSlots[ch])
        end
        return true
    end

    local stop = UnitIsDeadOrGhost("player")
        or (IsMounted and IsMounted())
        or (UnitInVehicle and UnitInVehicle("player"))
    if not stop then
        local eatDrink = { "喝水", "进食", "饮用", "进食饮水", "食物", "饮料", "饮水" }
        if WR_GetUnitBuffTime("player", eatDrink, nil, "NAME") > 0 then stop = true end
    end
    if stop then
        -- 只熄灭「上一次自己点亮的那个技能」槽位，不整片清（跟随/焦点共用槽）
        local lastShown = WR_SoD_ShownSkill
        if type(lastShown) == "string" and lastShown ~= ""
           and WR_HideSkillColorSlot ~= nil then
            WR_HideSkillColorSlot(lastShown, nil)
        end
        return true
    end
    return false
end

-- ------------------------------------------------------------
-- 插入段：一次性插入（施放成功自关）+ 恶魔无脑火焰之雨（常开）
-- 返回：true=已点亮色块
-- ------------------------------------------------------------
function WR_WarlockForever_Inserts(spec)
    local now = GetTime()
    -- 先回收已施放成功的 pending（施法成功信号=WR_Forever_LastPlayerCast，非 CLEU）
    local last = WR_Forever_LastPlayerCast
    for key, rec in pairs(WR_WarlockForever_PendingInsert) do
        if last and last.spellName == rec.spell and last.time >= rec.since then
            PigSet[key] = false
            WR_WarlockForever_PendingInsert[key] = nil
            if type(WR_SyncConfigCheckbox) == "function" then
                pcall(WR_SyncConfigCheckbox, key)   -- 同步面板勾选，不改面板结构
            end
        elseif now > rec.deadline then
            WR_WarlockForever_PendingInsert[key] = nil
        end
    end

    local list
    if spec == "痛苦" then
        list = {
            { key = "SS_TK_CREYZZ", spell = "厄运诅咒", slot = 24, needTarget = true },
            { key = "SS_TK_CRDYH",  spell = "地狱火",   slot = 25, needTarget = false },
            { key = "SS_TK_CRLHSL", spell = "灵魂碎裂", slot = 40, needTarget = false },
        }
    elseif spec == "恶魔学识" then
        list = {
            { key = "SS_EM_CREYZZ", spell = "厄运诅咒", slot = 24, needTarget = true },
            { key = "SS_EM_CRDYH",  spell = "地狱火",   slot = 25, needTarget = false },
            { key = "SS_EM_CRHYZY", spell = "火焰之雨", slot = 76, needTarget = false },
            { key = "SS_EM_CRLHSL", spell = "灵魂碎裂", slot = 40, needTarget = false },
            { key = "SS_EM_CRXS",   spell = "吸取生命", slot = 86, needTarget = true },
        }
    else
        list = {
            { key = "SS_HM_CREYZZ", spell = "厄运诅咒", slot = 24, needTarget = true },
            { key = "SS_HM_CRDYH",  spell = "地狱火",   slot = 25, needTarget = false },
            { key = "SS_HM_CRHYZY", spell = "火焰之雨", slot = 76, needTarget = false },
            { key = "SS_HM_CRDYLY", spell = "地狱烈焰", slot = 77, needTarget = false },
            { key = "SS_HM_CRLHSL", spell = "灵魂碎裂", slot = 40, needTarget = false },
        }
    end

    for _, it in ipairs(list) do
        if PigSet[it.key] == true then
            if (not it.needTarget) or WR_WarlockForever_TargetOK then
                if WR_SpellUsable(it.spell, true) then
                    if WR_ColorFrame_ShowSkill(it.spell, it.slot) then
                        WR_WarlockForever_PendingInsert[it.key] = {
                            spell = it.spell, since = now, deadline = now + 3,
                        }
                        return true
                    end
                end
            end
        end
    end

    -- 恶魔「无脑火焰之雨」：常开开关，满足条件就放，不自关
    if spec == "恶魔学识" and PigSet.SS_EM_WBHYZY == true then
        if WR_SpellUsable("火焰之雨", true) then
            if WR_ColorFrame_ShowSkill("火焰之雨", 76) then return true end
        end
    end
    return false
end

-- ------------------------------------------------------------
-- 自保段：喝红药（治疗石）/ 恶魔吸取生命自保
-- ------------------------------------------------------------
function WR_WarlockForever_SelfPreserve(spec)
    local T = WR_WarlockForever_Thresholds
    if PlayerHP < T.RedPotionHP and WR_Use_ZLS ~= nil and WR_Use_ZLS() then
        if WR_ColorFrame_ShowSkill("邪能治疗石", 35) then return true end
    end
    if spec == "恶魔学识" and PlayerHP < 0.50
       and WR_WarlockForever_TargetOK
       and WR_Forever_IsSpellKnown("吸取生命")
       and WR_SpellUsable("吸取生命", true) then
        if WR_ColorFrame_ShowSkill("吸取生命", 86) then return true end
    end
    return false
end

-- ------------------------------------------------------------
-- 护甲段：下拉 1=邪甲术(未学会回退恶魔皮肤) 2=魔甲术 3=禁用；战斗内外都补
-- ------------------------------------------------------------
function WR_WarlockForever_Armor(spec)
    local key = (spec == "痛苦") and "SS_TK_HJ" or (spec == "恶魔学识") and "SS_EM_HJ" or "SS_HM_HJ"
    local sel = tonumber(PigSet[key]) or 1
    if sel == 3 then return false end
    local want, slot
    if sel == 2 then
        want, slot = "魔甲术", 9
    elseif WR_Forever_IsSpellKnown("邪甲术") then
        want, slot = "邪甲术", 1
    else
        want, slot = "恶魔皮肤", 93
    end
    if WR_GetUnitBuffTime("player", want) == 0 and WR_SpellUsable(want, true) then
        if WR_ColorFrame_ShowSkill(want, slot) then return true end
    end
    return false
end

-- ------------------------------------------------------------
-- 召唤宠物段：脱战+静止+无宠物 才召（BExt 内含 移动/吃喝/牺牲/骑乘/读条 门）
-- ------------------------------------------------------------
function WR_WarlockForever_Summon(spec)
    local key = (spec == "痛苦") and "SS_TK_AUTOSUMMON"
        or (spec == "恶魔学识") and "SS_EM_AUTOSUMMON" or "SS_HM_AUTOSUMMON"
    local sel = tonumber(PigSet[key]) or 1
    if sel <= 1 then return false end
    if WR_WarlockAutoSummonPet_BExt == nil then return false end
    return WR_WarlockAutoSummonPet_BExt(sel) == true
end

-- ------------------------------------------------------------
-- 宠物攻击段：战斗中+有宠物+宠物目标≠当前目标 → /petattack(30)
-- 排除双子 BOSS；非战斗不触发（防提前开怪）
-- ------------------------------------------------------------
function WR_WarlockForever_PetAttack(spec)
    local key = (spec == "痛苦") and "SS_TK_KZBB" or (spec == "恶魔学识") and "SS_EM_KZBB" or "SS_HM_KZBB"
    if PigSet[key] == false then return false end
    if not UnitAffectingCombat("player") then return false end
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then return false end
    if not WR_WarlockForever_TargetOK then return false end
    local tn = WR_SafeUnitName("target")
    if tn == "光明邪使菲奥拉" or tn == "黑暗邪使艾蒂丝" then return false end
    if UnitExists("pettarget") and UnitIsUnit("pettarget", "target") then return false end
    if WR_ColorFrame_ShowSkill("宠物攻击", 30) then return true end
    return false
end

-- ------------------------------------------------------------
-- 切目标段：目标死亡/不存在/不可攻击 + 战斗中 + 黑名单允许 → /targetenemy(56)
-- ------------------------------------------------------------
function WR_WarlockForever_Tab(spec)
    local key = (spec == "痛苦") and "SS_TK_TAB" or (spec == "恶魔学识") and "SS_EM_TAB" or "SS_HM_TAB"
    if PigSet[key] == false then return false end
    if not UnitAffectingCombat("player") then return false end
    if WR_WarlockForever_TargetOK then return false end
    if WR_CanTab ~= nil and not WR_CanTab() then return false end
    local now = GetTime()
    if now - WR_WarlockForever_LastTab < 1.0 then return false end
    if WR_ColorFrame_ShowSkill("切目标", 56) then
        WR_WarlockForever_LastTab = now
        return true
    end
    return false
end

-- ------------------------------------------------------------
-- 战斗门（防ADD）：下拉 1=是(需目标进战斗才攻击) 2=否；nil 默认按 是。
-- ★ 旧循环误读不存在的 FANG_ADD_WL；此处按专精读真实面板键。
--   口径（面板 tooltip）：「打开的情况下需要目标进入战斗才会攻击」→
--   是 → 玩家战斗中 且 目标进战斗 才放行；否 → 玩家战斗中即放行。
-- ------------------------------------------------------------
function WR_WarlockForever_CombatGate(spec)
    local key = (spec == "痛苦") and "FANG_ADD_TKS" or (spec == "恶魔学识") and "FANG_ADD_EMS" or "FANG_ADD_HMS"
    local preventAdd = (tonumber(PigSet[key]) or 1) == 1
    local bossFrameActive = false
    for i = 1, 4 do
        if UnitExists("boss" .. i) then bossFrameActive = true; break end
    end
    local inBossEncounter = bossFrameActive
        and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    return inBossEncounter or (UnitAffectingCombat("player") and ((not preventAdd) or TargetInCombat))
end

-- ------------------------------------------------------------
-- 爆发段：恶魔变形（SS_EM_ZDEMBX 默认开，战斗中 CD 好即放）
-- ★ 放在战斗门之后：由 Base 采集的全局此时已就绪，且脱战不乱变身
-- ------------------------------------------------------------
function WR_WarlockForever_Burst(spec, specCfg)
    if specCfg.metaMorph and PigSet.SS_EM_ZDEMBX ~= false
       and WR_SpellUsable("恶魔变形", true) then
        if WR_ColorFrame_ShowSkill("恶魔变形", 32) then return true end
    end
    return false
end

-- ------------------------------------------------------------
-- 拉条段：生命分流 / 高血分流（喝红药在自保段；魔杖在循环末尾兜底）
-- ------------------------------------------------------------
function WR_WarlockForever_Mana(spec)
    local T = WR_WarlockForever_Thresholds
    if PlayerMove or WR_WarlockForever_Casting or WR_WarlockForever_Channel then return false end
    if PlayerMP < T.LifeTapMP and PlayerHP > T.LifeTapHP and WR_SpellUsable("生命分流") then
        if WR_ColorFrame_ShowSkill("生命分流", 10) then return true end
    end
    if PlayerHP >= T.HighTapHP and PlayerMP < T.HighTapMP and WR_SpellUsable("生命分流") then
        if WR_ColorFrame_ShowSkill("生命分流", 10) then return true end
    end
    return false
end

-- ------------------------------------------------------------
-- 魔杖回蓝兜底：蓝低于 50% 且「本 tick 没有任何技能可打」时才 /startattack(190)
-- ★ 必须放在读条/填充之后：否则蓝<50% 时每 tick 抢占循环，输出全丢
-- ------------------------------------------------------------
function WR_WarlockForever_Wand()
    local T = WR_WarlockForever_Thresholds
    if PlayerMP >= T.WandMP then return false end
    if not WR_WarlockForever_TargetOK then return false end
    if not (TargetRange and TargetRange <= 30) then return false end
    if WR_WarlockForever_Casting or WR_WarlockForever_Channel then return false end
    if WR_ColorFrame_ShowSkill("魔杖射击", 190) then return true end
    return false
end

-- ------------------------------------------------------------
-- DOT 段：只补「自己的」DOT（ByMe=true）；灾祸二选一互斥
-- specCfg.dotList = { {name, slot, ttd} ... }；curse = "痛苦诅咒"/"厄运诅咒"/nil
-- specCfg.bossDoom = true 时（毁灭 SS_HM_EYZZ）BOSS/假人长战斗补厄运诅咒
-- ------------------------------------------------------------
function WR_WarlockForever_Dots(spec, specCfg)
    if not WR_WarlockForever_TargetOK or not WR_WarlockForever_InRange then return false end
    if WR_CanDot ~= nil and not WR_CanDot("target") then return false end
    if WR_IsBlacklisted ~= nil and WR_IsBlacklisted("target") then return false end

    for _, d in ipairs(specCfg.dotList) do
        if WR_GetUnitDebuffTime("target", d.name, true) == 0
           and TargetDeathTime > d.ttd
           and WR_SpellUsable(d.name, true) then
            if WR_ColorFrame_ShowSkill(d.name, d.slot) then return true end
        end
    end

    -- 灾祸（诅咒）二选一：同一目标只上一种；已有任一自己诅咒则不补
    local curse = specCfg.curse
    if curse then
        local hasAny = WR_GetUnitDebuffTime("target", "痛苦诅咒", true) > 0
            or WR_GetUnitDebuffTime("target", "厄运诅咒", true) > 0
        if not hasAny then
            local ttdNeed = (curse == "厄运诅咒") and 60 or 12
            local slot = (curse == "厄运诅咒") and 24 or 3
            if TargetDeathTime > ttdNeed and WR_SpellUsable(curse, true) then
                if WR_ColorFrame_ShowSkill(curse, slot) then return true end
            end
        end
    end

    -- 毁灭「自动 BOSS 厄运诅咒」：BOSS/假人 且 TTD>60 且无自己厄运
    -- 厄运诅咒在无限缺失闸门内 → WR_SpellUsable 恒 false 自然跳过，不绕闸
    if specCfg.bossDoom and PigSet.SS_HM_EYZZ ~= false then
        local cls = UnitClassification("target")
        local isBoss = (cls == "boss" or cls == "worldboss")
            or (WR_InTraining ~= nil and WR_InTraining())
        if isBoss and TargetDeathTime > 60
           and WR_GetUnitDebuffTime("target", "厄运诅咒", true) == 0
           and WR_SpellUsable("厄运诅咒", true) then
            if WR_ColorFrame_ShowSkill("厄运诅咒", 24) then return true end
        end
    end
    return false
end

-- ------------------------------------------------------------
-- 读条引导段：吸取灵魂斩杀 > 灵魂之火(灭杀/低血) > 烧尽 > 灼热之痛(移动) >
--             折磨(痛苦填充) > 暗影箭
-- 引导续接已在停手门处理；此处只负责「发起」
-- ------------------------------------------------------------
function WR_WarlockForever_Casts(spec, specCfg)
    if not WR_WarlockForever_TargetOK or not WR_WarlockForever_InRange then return false end
    if WR_WarlockForever_Casting or WR_WarlockForever_Channel then return false end

    -- 吸取灵魂：<20% 斩杀（已学会才用）
    if specCfg.drainSoul and WR_SafeHPPct("target") < 0.20
       and TargetDeathTime > 5
       and WR_Forever_IsSpellKnown("吸取灵魂")
       and WR_SpellUsable("吸取灵魂", true) then
        if WR_ColorFrame_ShowSkill("吸取灵魂", 11) then return true end
    end

    -- 灵魂之火：灭杀触发或目标低血（恶魔/毁灭）
    if specCfg.soulFire then
        local decimate = WR_GetUnitBuffTime("player", "灭杀") > 0
        if (decimate or WR_SafeHPPct("target") < 0.25) and WR_SpellUsable("灵魂之火", true) then
            if WR_ColorFrame_ShowSkill("灵魂之火", 38) then return true end
        end
    end

    -- 烧尽：毁灭需目标有献祭（否则 DOT 段已先补）；恶魔直接填充
    if specCfg.incinerate then
        local ok = (spec ~= "毁灭") or WR_GetUnitDebuffTime("target", "献祭", true) > 0
        if ok and not PlayerMove and WR_SpellUsable("烧尽", true) then
            if WR_ColorFrame_ShowSkill("烧尽", 39) then return true end
        end
    end

    -- 灼热之痛：毁灭移动填充（已学会才用）
    if specCfg.searingPain and PlayerMove
       and WR_Forever_IsSpellKnown("灼热之痛")
       and WR_SpellUsable("灼热之痛", true) then
        if WR_ColorFrame_ShowSkill("灼热之痛", 92) then return true end
    end

    -- 折磨：痛苦填充（无限新技能，已学会才用）
    if specCfg.torment and not PlayerMove
       and WR_Forever_IsSpellKnown("折磨")
       and WR_SpellUsable("折磨", true) then
        if WR_ColorFrame_ShowSkill("折磨", 91) then return true end
    end

    -- 暗影箭：通用填充（移动中不用）
    if not PlayerMove and WR_SpellUsable("暗影箭", true) then
        if WR_ColorFrame_ShowSkill("暗影箭", 6) then return true end
    end
    return false
end

-- ------------------------------------------------------------
-- 收尾清扫：本 tick 一个色块都没点亮时，熄灭「上一次自己点亮的那个」槽位。
-- ★ 色块是「亮着就一直按」模型：WR_ColorFrame_Show 只在成功点亮时才先隐藏全部；
--   若本 tick 直接 return false 而不熄灭，上一 tick 的色块会一直挂着 →
--   AHK 读到同色继续按（目标超距 / 技能全 CD / DOT 已齐时表现为持续空按）。
-- ★ 只熄灭自己那一个槽位，绝不整片 WR_HideColorFrame（跟随/焦点/BOSS 共用槽）。
-- ------------------------------------------------------------
function WR_WarlockForever_Sweep()
    if WR_SoD_ShownTick == WR_SoD_TickSeq then return end   -- 本轮亮过，交给正常覆盖
    local lastShown = WR_SoD_ShownSkill
    if type(lastShown) ~= "string" or lastShown == "" then return end
    -- ★ nil 判定（仓库老坑：可调用对象可能是 userdata，type 守卫会静默跳过）
    if WR_HideSkillColorSlot ~= nil then
        WR_HideSkillColorSlot(lastShown, nil)
    end
    WR_SoD_ShownSkill = nil
end

-- ------------------------------------------------------------
-- 主循环骨架：三专精薄壳共用；specCfg 见各专精文件
-- 顺序：基础变量→停手门→插入→自保→护甲→召唤→宠物攻击→切目标→战斗门→
--       爆发→拉条→DOT→读条填充→魔杖兜底→收尾清扫
-- ★ 用 do-block + 单一出口，保证任何 return 路径都经过 Sweep。
-- ------------------------------------------------------------
function WR_WarlockForever_Run(spec, specCfg)
    local handled = false
    repeat
        WR_WarlockForever_Base()
        if WR_WarlockForever_StopGate() then break end
        if WR_WarlockForever_Inserts(spec) then handled = true; break end
        if WR_WarlockForever_SelfPreserve(spec) then handled = true; break end
        if WR_WarlockForever_Armor(spec) then handled = true; break end
        if WR_WarlockForever_Summon(spec) then handled = true; break end
        if WR_WarlockForever_PetAttack(spec) then handled = true; break end
        if WR_WarlockForever_Tab(spec) then handled = true; break end
        if not WR_WarlockForever_CombatGate(spec) then break end
        if WR_WarlockForever_Burst(spec, specCfg) then handled = true; break end
        if WR_WarlockForever_Mana(spec) then handled = true; break end
        if WR_WarlockForever_Dots(spec, specCfg) then handled = true; break end
        if WR_WarlockForever_Casts(spec, specCfg) then handled = true; break end
        if WR_WarlockForever_Wand() then handled = true; break end
    until true
    if not handled then WR_WarlockForever_Sweep() end
    return handled
end

-- ------------------------------------------------------------
-- 派发器：Forever 走新循环；非 Forever 回退旧 SoD 三函数（保持不动）
-- ★ 客户端判定只认 WR_Forever_ClientInfo().isForever（WR_Forever.info 是假字段）
-- ------------------------------------------------------------
function WR_WarlockForeverRotation()
    local spec = WR_GetMyTalent()
    local isForever = WR_Forever_ClientInfo().isForever
    if not isForever then
        if spec == "痛苦" then WR_WarlockAffliction() end
        if spec == "恶魔学识" then WR_WarlockDemonology() end
        if spec == "毁灭" then WR_WarlockDestruction() end
        return
    end
    if spec == "痛苦" then WR_WarlockForeverAffliction() end
    if spec == "恶魔学识" then WR_WarlockForeverDemonology() end
    if spec == "毁灭" then WR_WarlockForeverDestruction() end
end