-- ============================================================
-- Priest/Priest_Forever_Discipline_Features.lua
-- 《魔兽世界：无限》(Forever 1.60.x) · 牧师【戒律】专精
--   功能 / 插入 / 爆发 三块（本次优化交付）
-- ------------------------------------------------------------
-- 交付：功能·插入·爆发模块 + 天赋技能兼容核对
-- 落地：已于 2026-11-16 接入 MKHelperForever.toc（紧跟 Priest_Forever_Discipline.lua）
--
-- 【硬约束 / 与现有架构的关系】
-- 1. 加血方式 100% 沿用「焦点权重 + 治疗法术」：本文件不重写
--    WR_PriestForeverDiscipline，不定义任何治疗目标选取，不触碰
--    WR_RunHealerWithFleshPriority / WR_SoD_GetLowestFriendly。
--    只在治疗循环之外补「功能开关 / 一次性插入 / 爆发槽位」三类色块，
--    统一经既有 WR_ColorFrame_ShowSkill(技能名, 槽位) 输出。
--    · Pre（优先于常规加血）：一次性插入、爆发 —— 玩家主动动作
--    · 原治疗循环（焦点权重 + 治疗法术）—— 原样调用，逐字不变
--    · Post（仅治疗未命中时）：驱散、buff 维持、填充输出
-- 2. 只影响戒律专精 + Forever 客户端：
--    只 hook WR_PriestForeverDiscipline（Priest/Priest_Forever.lua 仅在
--    spec == "戒律" 时经 WR_RunHealerWithFleshPriority 调用它）。
--    非 Forever 客户端直接透传原函数，行为逐字不变；神圣/暗影不经过本文件。
-- 3. 纯新增文件，不删除、不覆盖任何既有文件；未在 .toc 注册时完全
--    inert（不加载）。回滚 = 删除本文件 + 撤销 .toc 新增的一行。
-- 4. 法术名 / 槽位 / 事件名 / SavedVariables 键名一律沿用现有源码：
--    PigSet(## SavedVariablesPerCharacter: PigSet)、JL_* 前缀、WR_* 函数。
--    未在插件既有代码/客户端实测报告中出现的 spellID 一律不臆造。
--
-- 【补丁 A · MKHelperForever.toc（已完成 2026-11-16）】
--   已登记在「# 4. 职业模块」段，紧跟
--       Priest\Priest_Forever_Discipline.lua
--   之后：
--       Priest\Priest_Forever_Discipline_Features.lua
--   必须晚于 Priest_Forever_Discipline.lua（本文件要 hook 它的全局函数）。
--
-- 【精简兼容表（详见交付文档；标「待核实」者不得当既定事实使用）】
--   苦修       Penance            戒律天赋  ID 1240720(7位新增段,SkillRegistry) 存在/天赋
--   能量灌注   Power Infusion     戒律天赋  SpellScan实测10060；Mouseover_Cast注释48160(冲突,待核实)
--   心灵专注   Inner Focus        戒律天赋  SpellScan实测14751                存在/天赋
--   神圣新星   Holy Nova          神圣天赋  SpellScan实测15237  存在/天赋(戒律锁定下是否可学 待核实)
--   联结治疗   Binding Heal       神圣天赋  ClassKit标记存在,无实测ID         待核实
--   愈合祷言   Prayer of Mending  神圣天赋  SpellScan实测41637 / Registry41637
--   治疗祷言   Prayer of Healing  基础技能  Registry 596                     存在
--   真言术：韧 Power Word: Fortitude 基础  无实测ID(宏槽52)                  待核实ID
--   心灵之火   Inner Fire         基础技能  无实测ID(宏槽31)                  待核实ID
--   惩击       Smite              基础技能  无实测ID且Priest_Macros.lua无宏绑定 → 见补丁C
--   暗言术：灭 Shadow Word: Death 基础/天赋 宏槽6/41/87；SkillAbsent把「暗言术：死」标缺失(译名冲突,待核实)
--   驱散魔法   Dispel Magic       基础技能  无实测ID(宏槽63/78/79/85)         待核实ID
--   群体驱散   Mass Dispel        基础技能  无实测ID(宏槽46/47/193)           待核实ID
-- ============================================================

if WR_PlayerClass ~= "PRIEST" then return end

-- ---------- 1) 键名常量：既有键逐字沿用；新增键以 JL_ 前缀命名 ----------
local FEAT = {
    -- 既有（Priest/Priest_Menu.lua 的 ["戒律"] 已定义）
    QS        = "JL_QS",        -- 驱散下拉 1常规/2优先/3目标/4指向/5禁用(defaultID=2)
    QS_AUTO   = "JL_QS_AUTO",   -- 自动驱散总闸：勾选 = 关闭全部自动驱散(默认false)
    QTQS      = "JL_QTQS",      -- 群体驱散(默认true)
    ZYSR      = "JL_ZYSR",      -- 真言术：韧(默认true)
    BF        = "JL_BF",        -- 爆发总闸(默认false)
    -- 新增（见补丁 B：Priest_Menu.lua 菜单项）
    XLHZ      = "JL_XLHZ",      -- 心灵之火(默认true, 截图启用)
    CJ        = "JL_CJ",        -- 惩击(默认true, 截图启用)
    AYSHM     = "JL_AYSHM",     -- 暗言术：灭(默认false, 截图打叉)
    ZYSR_MODE = "JL_ZYSR_MODE", -- 韧「切」: 1=真言术：韧 / 2=坚韧祷言(默认1)
    -- 插入(一次性, 释放后自动关; 沿用现有 JL_CR* 命名, 见补丁 B)
    CR_GNZ    = "JL_CRGNZ",     -- 插入 能量灌注
    CR_XX     = "JL_CRXX",      -- 插入 神圣新星
    CR_ZLDY   = "JL_CRZLDY",    -- 插入 治疗祷言
    -- 爆发槽位(截图: 三个「未设置」槽位 + 种族爆发勾选)
    BF_S1     = "JL_BF_S1",     -- 槽位1 启用
    BF_S2     = "JL_BF_S2",
    BF_S3     = "JL_BF_S3",
    BF_SLOT1  = "JL_BF_SLOT1",  -- 槽位1 技能名(nil/空 = 「未设置」)
    BF_SLOT2  = "JL_BF_SLOT2",
    BF_SLOT3  = "JL_BF_SLOT3",
    BF_RACE   = "JL_BF_RACE",   -- 种族爆发(默认true, 截图已勾选)
}

-- 技能名 -> 回退色块槽位。
-- 槽位只取 Priest/Priest_Macros.lua 既有 WR_CreateMacro 绑定值或
-- 既有 WR_SkillColor["PRIEST"] 登记值；查不到就不给回退，
-- 交给 WR_ColorFrame_ShowSkill 的「不猜槽位」安全分支。
local SLOT = {
    ["驱散魔法"]   = 78,  -- Priest_Macros.lua:81  "/cast 驱散魔法"
    ["群体驱散"]   = 46,  -- :49  "/cast [@player]群体驱散"
    ["真言术：韧"] = 52,  -- :55  "/cast [@focus] 真言术：韧"
    ["坚韧祷言"]   = 51,  -- :54  "/cast [@focus] 坚韧祷言"
    ["心灵之火"]   = 31,  -- :34  "/CAST [nochanneling:暗言术：渊]心灵之火"
    ["暗言术：灭"] = 87,  -- :90  "/cast 暗言术：灭"
    ["能量灌注"]   = 149, -- Priest_Macros.lua:152 ALT-SHIFT-,（原 302 越界，2026-11-16 修正）
    ["神圣新星"]   = 49,  -- Priest_Macros.lua SHIFT-F12（原 303 越界，宏原为空槽，2026-11-16 补）
    ["心灵专注"]   = 23,  -- Priest_Macros.lua:26 ALT-NUMPAD3（原 301 越界，2026-11-16 修正）
    ["联结治疗"]   = 56,  -- Priest_Macros.lua:59 CTRL-F6（原 304 越界，2026-11-16 修正）
    ["治疗祷言"]   = 53,
    ["苦修"]       = 54,
    ["愈合祷言"]   = 58,
    ["暗影魔"]     = 7,
}
-- 惩击：Priest_Macros.lua 全文件无 WR_CreateMacro 绑定、WR_SkillColor 亦无登记，
--      故 SLOT["惩击"] 故意留空 → 见补丁 C 补宏，补之前不点亮(不猜槽位)。
-- 301~304 为历史越界槽（ColorTable 只有 1~240，会被 WR_ColorFrame_ShowSkill
--      直接拦截）；2026-11-16 已按当前 Priest_Macros.lua 的真实宏槽改回 23/149/49/56。

local RACE_BURST_SLOT = 181  -- Priest_Macros.lua 槽位181 / ALT-CTRL-SHIFT-PAGEDOWN
                             -- 种族三连宏(血性狂怒/狂暴/狮心)；
                             -- Core/Forever_Hooks.lua 钩2 会把无限新增种族技能注入该宏体

-- ★ 去重总闸：若整合者确认 ZZ_Features_Migration 的通用驱散调度已消费
--   JL_QS / JL_QS_AUTO / JL_QTQS 并已输出驱散色块，把本行改 false 即可
--   单独关闭本文件的驱散段，功能/插入/爆发其余两块不受影响。
local MKF_DISC_ENABLE_DISPEL = true

local BURST_ON_VARS   = { FEAT.BF_S1,    FEAT.BF_S2,    FEAT.BF_S3 }
local BURST_SLOT_VARS = { FEAT.BF_SLOT1, FEAT.BF_SLOT2, FEAT.BF_SLOT3 }

-- ---------- 2) 安全原语：任何辅助函数缺失/异常都不影响治疗循环 ----------
local function MKF_Disc_IsForever()
    if type(WR_Forever_ClientInfo) ~= "function" then return false end
    local ok, info = pcall(WR_Forever_ClientInfo)
    return ok and type(info) == "table" and info.isForever == true
end

local function MKF_Disc_Default(var, val)
    if type(PigSet) ~= "table" then return val end
    if PigSet[var] == nil then PigSet[var] = val end
    return PigSet[var]
end

local defaultsDone = false
local function MKF_Disc_EnsureDefaults()
    if defaultsDone or type(PigSet) ~= "table" then return end
    defaultsDone = true
    MKF_Disc_Default(FEAT.XLHZ,      true)   -- 心灵之火 启用
    MKF_Disc_Default(FEAT.CJ,        true)   -- 惩击     启用
    MKF_Disc_Default(FEAT.AYSHM,     false)  -- 暗言术：灭 默认禁用(截图打叉)
    MKF_Disc_Default(FEAT.ZYSR_MODE, 1)
    MKF_Disc_Default(FEAT.CR_GNZ,    false)
    MKF_Disc_Default(FEAT.CR_XX,     false)
    MKF_Disc_Default(FEAT.CR_ZLDY,   false)
    MKF_Disc_Default(FEAT.BF_S1,     false)
    MKF_Disc_Default(FEAT.BF_S2,     false)
    MKF_Disc_Default(FEAT.BF_S3,     false)
    MKF_Disc_Default(FEAT.BF_RACE,   true)   -- 种族爆发 勾选
    -- 三个爆发槽位默认「未设置」= 键不存在，不写入 PigSet
    -- 插入键显式登记进既有脱战统一关闭表(Core/Core_Functions.lua)，
    -- 因其未以 "_CR" 结尾、不会被 WR_CollectInsertToggles 自动收集。
    if type(WR_RegisterInsertToggle) == "function" then
        pcall(WR_RegisterInsertToggle, FEAT.CR_GNZ)
        pcall(WR_RegisterInsertToggle, FEAT.CR_XX)
        pcall(WR_RegisterInsertToggle, FEAT.CR_ZLDY)
    end
end

local function MKF_Disc_On(var, def)
    if type(PigSet) ~= "table" then return def end
    local v = PigSet[var]
    if v == nil then return def end
    return v and true or false
end

-- 缺失闸门：WR_Forever_SkillAbsent(Data/Forever_SkillRegistry.lua) 命中直接判死。
-- 天赋技能未点/未学会时 WR_SpellUsable 亦会返回 false，自然跳过，不臆造。
local function MKF_Disc_Usable(spell)
    if type(WR_Forever_SkillAbsent) == "table" and WR_Forever_SkillAbsent[spell] then
        return false
    end
    if type(WR_SpellUsable) ~= "function" then return false end
    local ok, r = pcall(WR_SpellUsable, spell, true)
    return ok and r == true
end

local function MKF_Disc_HasSlot(spell)
    if SLOT[spell] then return true end
    if type(WR_SoD_ResolveSlot) == "function" then
        local ok, r = pcall(WR_SoD_ResolveSlot, spell)
        if ok and r then return true end
    end
    return false
end

local function MKF_Disc_Show(spell, slot)
    if type(WR_ColorFrame_ShowSkill) ~= "function" then return false end
    local ok, shown = pcall(WR_ColorFrame_ShowSkill, spell, slot or SLOT[spell])
    return ok and shown == true
end

-- 非紧急提示节流：避免无限服光环读不到(secret)时每帧刷屏
local lastShown = {}
local function MKF_Disc_Throttle(key, secs)
    local now = (type(GetTime) == "function") and GetTime() or 0
    local last = lastShown[key] or -1e9
    if now - last < (secs or 2) then return false end
    lastShown[key] = now
    return true
end

-- ---------- 3) 插入：灌注 / 新星 / 治疗祷言（一次性，释放后自动关） ----------
-- 写法对齐 Paladin/Paladin_Forever_Prot.lua 的 WR_ProtOneShot：
--   · 明确不存在的技能(缺失闸门) → 自动关开关，避免卡住
--   · 此刻打不出去(未学/未点天赋/CD/蓝/无登记槽位) → 不点亮、也不取消
--     勾选，等下个 tick（不误报「勾了没反应」）
--   · 点亮成功 → PigSet[var]=false + WR_SyncConfigCheckbox(var) 回弹面板
local function MKF_Disc_OneShot(var, spell)
    if not MKF_Disc_On(var, false) then return false end

    if type(WR_Forever_SkillAbsent) == "table" and WR_Forever_SkillAbsent[spell] then
        PigSet[var] = false
        if type(WR_SyncConfigCheckbox) == "function" then pcall(WR_SyncConfigCheckbox, var) end
        return false
    end
    if not MKF_Disc_HasSlot(spell) then return false end
    if not MKF_Disc_Usable(spell) then return false end

    if MKF_Disc_Show(spell, SLOT[spell]) then
        PigSet[var] = false
        if type(WR_SyncConfigCheckbox) == "function" then pcall(WR_SyncConfigCheckbox, var) end
        return true
    end
    return false
end

-- ---------- 4) 功能：驱散 / 真言术：韧(切) / 心灵之火 / 惩击 / 暗言术：灭 ----------
local function MKF_Disc_DispelUnits()
    local t = { "player" }
    local raid  = (GetNumRaidMembers  and GetNumRaidMembers())  or 0
    local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    if raid > 0 then
        for i = 1, raid do t[#t + 1] = "raid" .. i end
    elseif party > 0 then
        for i = 1, party do t[#t + 1] = "party" .. i end
    end
    return t
end

-- 无限服战斗中 C_UnitAuras 对 secret 路径会抛错(见 Healer_FocusWeight.lua 注释)，
-- 连续 3 次读取异常即熔断本段，不再每帧无效扫描。
local dispelAuraFailed = 0
local function MKF_Disc_Dispel()
    if not MKF_DISC_ENABLE_DISPEL or dispelAuraFailed >= 3 then return false end
    if MKF_Disc_On(FEAT.QS_AUTO, false) then return false end  -- 总闸：勾选 = 全关
    local mode = tonumber(type(PigSet) == "table" and PigSet[FEAT.QS] or nil) or 2
    if mode == 5 then return false end                          -- 驱散「禁用」
    if not MKF_Disc_Throttle("QS_SCAN", 0.2) then return false end
    if type(WR_UnitDebuffType) ~= "function" then return false end
    if not MKF_Disc_Usable("驱散魔法") then return false end

    local hit = 0
    for _, u in ipairs(MKF_Disc_DispelUnits()) do
        if UnitExists(u) and not UnitIsDead(u) then
            local ok, has = pcall(WR_UnitDebuffType, u, "Magic")
            if not ok then
                dispelAuraFailed = dispelAuraFailed + 1
                if dispelAuraFailed >= 3 then
                    print("|cffff8040[MKHelperForever 戒律]|r 光环读取受限，自动驱散段已停用；其余功能不受影响")
                end
                return false
            end
            if has then hit = hit + 1 end
        end
    end
    if hit == 0 then return false end

    -- 群体驱散：≥2 名队友有魔法减益且 JL_QTQS 开 → 提示群体驱散(点一下放一次)
    if hit >= 2 and MKF_Disc_On(FEAT.QTQS, true) and MKF_Disc_Usable("群体驱散") then
        if MKF_Disc_Show("群体驱散", SLOT["群体驱散"]) then return true end
    end
    -- 单体驱散：沿用既有色块通道。焦点/指向由既有 JL_QS 下拉(常规/优先/目标/
    -- 指向)与通用驱散调度负责，本模块不重复设焦点，避免与治疗引擎抢焦点。
    if MKF_Disc_Show("驱散魔法", SLOT["驱散魔法"]) then return true end
    return false
end

-- 自身 buff 读取：读不到(secret/nil)就静默跳过，不误报补 buff
local function MKF_Disc_NeedsBuff(spell)
    if type(WR_GetUnitBuffTime) ~= "function" then return false end
    local ok, t = pcall(WR_GetUnitBuffTime, "player", spell)
    if not ok or t == nil then return false end
    return not (type(t) == "number" and t > 0)
end

local function MKF_Disc_BuffZYSR()
    if not MKF_Disc_On(FEAT.ZYSR, true) then return false end
    local mode = tonumber(type(PigSet) == "table" and PigSet[FEAT.ZYSR_MODE] or nil) or 1
    local spell = (mode == 2) and "坚韧祷言" or "真言术：韧"
    if not MKF_Disc_Usable(spell) then return false end
    if not MKF_Disc_NeedsBuff(spell) then return false end
    if MKF_Disc_Throttle("ZYSR", 3) and MKF_Disc_Show(spell, SLOT[spell]) then
        return true
    end
    return false
end

local function MKF_Disc_BuffXLHZ()
    if not MKF_Disc_On(FEAT.XLHZ, true) then return false end
    if not MKF_Disc_Usable("心灵之火") then return false end
    if not MKF_Disc_NeedsBuff("心灵之火") then return false end
    if MKF_Disc_Throttle("XLHZ", 3) and MKF_Disc_Show("心灵之火", SLOT["心灵之火"]) then
        return true
    end
    return false
end

local function MKF_Disc_Offense()
    local hasEnemy = false
    if UnitExists("target") and type(UnitCanAttack) == "function" then
        local ok, r = pcall(UnitCanAttack, "player", "target")
        hasEnemy = ok and r or false
    end
    if not hasEnemy then return false end

    -- 惩击(截图启用)：补宏前无登记槽位 → MKF_Disc_HasSlot 拦下，不猜槽位
    if MKF_Disc_On(FEAT.CJ, true) and MKF_Disc_HasSlot("惩击")
       and MKF_Disc_Usable("惩击") and MKF_Disc_Throttle("CJ", 1.5) then
        if MKF_Disc_Show("惩击", nil) then return true end
    end
    -- 暗言术：灭(截图打叉，默认禁用)
    if MKF_Disc_On(FEAT.AYSHM, false) and MKF_Disc_Usable("暗言术：灭")
       and MKF_Disc_Throttle("AYSHM", 1.5) then
        if MKF_Disc_Show("暗言术：灭", SLOT["暗言术：灭"]) then return true end
    end
    return false
end

-- ---------- 5) 爆发：全升/全关/切换 + 三个槽位 + 种族爆发 ----------
local function MKF_Disc_BurstAllowed()
    if not MKF_Disc_On(FEAT.BF, false) then return false end
    if zidongbaofa == true then return true end           -- Core/Burst_Whitelist.lua
    if type(PIG_Zidongbaofa) == "function" then           -- Core/Trinket_Burst.lua
        local ok, r = pcall(PIG_Zidongbaofa)
        if ok and r then return true end
    end
    return false
end

local function MKF_Disc_BurstSlots()
    if type(PigSet) ~= "table" then return false end
    for i = 1, 3 do
        if MKF_Disc_On(BURST_ON_VARS[i], false) then
            local name = PigSet[BURST_SLOT_VARS[i]]
            if type(name) == "string" and name ~= "" and MKF_Disc_HasSlot(name)
               and MKF_Disc_Usable(name) then
                if MKF_Disc_Show(name, SLOT[name]) then return true end
            end
        end
    end
    return false
end

local function MKF_Disc_RacialBurst()
    if not MKF_Disc_On(FEAT.BF_RACE, true) then return false end
    if type(WR_Forever_PlayerRacialBursts) ~= "function" then return false end
    local ok, bursts = pcall(WR_Forever_PlayerRacialBursts)
    if not ok or type(bursts) ~= "table" or #bursts == 0 then return false end
    -- 种族爆发走既有「种族三连宏」槽 181，不按单个技能名点亮，
    -- 避开「艾露恩之光 / 尤里卡！」中文译名尚未在客户端核定的风险。
    if MKF_Disc_Throttle("RACE", 1.0)
       and MKF_Disc_Show(bursts[1], RACE_BURST_SLOT) then
        return true
    end
    return false
end

local function MKF_Disc_BurstSetAll(mode)
    if type(PigSet) ~= "table" then return end
    MKF_Disc_EnsureDefaults()
    for i = 1, 3 do
        local v = BURST_ON_VARS[i]
        if mode == "toggle" then
            PigSet[v] = not MKF_Disc_On(v, false)
        else
            PigSet[v] = (mode == true)
        end
        if type(WR_SyncConfigCheckbox) == "function" then pcall(WR_SyncConfigCheckbox, v) end
    end
    -- 全升顺带打开既有爆发总闸 JL_BF；全关不动总闸(避免误关其他爆发项)
    if mode == true then
        PigSet[FEAT.BF] = true
        if type(WR_SyncConfigCheckbox) == "function" then pcall(WR_SyncConfigCheckbox, FEAT.BF) end
    end
    print("|cffFF69B4[MKHelperForever 戒律]|r 爆发槽位："
          .. tostring(mode) .. " → "
          .. tostring(PigSet[FEAT.BF_S1]) .. "/"
          .. tostring(PigSet[FEAT.BF_S2]) .. "/"
          .. tostring(PigSet[FEAT.BF_S3]))
end

-- ---------- 6) 三块汇总：两个优先级挂点，均不改动治疗引擎 ----------
-- Pre：一次性插入 / 爆发（玩家主动或条件触发，优先于常规加血）
function WR_PriestForeverDiscipline_Features_Pre()
    if type(PigSet) ~= "table" then return false end
    MKF_Disc_EnsureDefaults()

    if MKF_Disc_OneShot(FEAT.CR_GNZ,  "能量灌注") then return true end
    if MKF_Disc_OneShot(FEAT.CR_XX,   "神圣新星") then return true end
    if MKF_Disc_OneShot(FEAT.CR_ZLDY, "治疗祷言") then return true end

    if MKF_Disc_BurstAllowed() then
        if MKF_Disc_BurstSlots()  then return true end
        if MKF_Disc_RacialBurst() then return true end
    end
    return false
end

-- Post：仅当治疗循环未命中时的自动功能（驱散 / buff 维持 / 填充输出）
function WR_PriestForeverDiscipline_Features_Post()
    if type(PigSet) ~= "table" then return false end
    if MKF_Disc_Dispel()     then return true end
    if MKF_Disc_BuffZYSR()   then return true end
    if MKF_Disc_BuffXLHZ()   then return true end
    if MKF_Disc_Offense()    then return true end
    return false
end

-- 兼容单一入口（诊断/外部调用）：语义 = Pre or Post
function WR_PriestForeverDiscipline_Features()
    if WR_PriestForeverDiscipline_Features_Pre() then return true end
    return WR_PriestForeverDiscipline_Features_Post()
end

-- ---------- 7) 自挂载 hook：不修改任何既有文件 ----------
-- 仅在 WR_PriestForeverDiscipline 已定义时安装（依赖补丁 A 的 .toc 顺序）。
-- 用 if 包裹而非顶层 return，保证第 8 节斜杠命令始终注册；
-- 若加载顺序被放错，打印一条明确告警，便于整合者定位。
if type(WR_PriestForeverDiscipline) == "function" then
    local MKF_OrigDiscipline = WR_PriestForeverDiscipline
    WR_PriestForeverDiscipline = function(...)
        -- SoD 客户端：完全透传，戒律既有行为逐字不变
        if not MKF_Disc_IsForever() then return MKF_OrigDiscipline(...) end
        -- (1) 插入 / 爆发（新逻辑出错也不影响游戏）
        local okPre, pre = pcall(WR_PriestForeverDiscipline_Features_Pre)
        if okPre and pre then return true end
        -- (2) 原「焦点权重 + 治疗法术」循环，原样调用(异常照常上抛)
        if MKF_OrigDiscipline(...) then return true end
        -- (3) 仅治疗未命中时补自动功能
        local okPost, post = pcall(WR_PriestForeverDiscipline_Features_Post)
        return (okPost and post) or false
    end
else
    print("|cffff8040[MKHelperForever 戒律]|r Features 模块加载过早：.toc 中请把本文件放在 Priest_Forever_Discipline.lua 之后")
end

-- ---------- 8) 斜杠命令（/reload 后验证 & 三个爆发按钮可绑定） ----------
SLASH_MKHDISC1 = "/mkhdisc"
SlashCmdList["MKHDISC"] = function()
    print("|cffFF69B4[MKHelperForever 戒律]|r 功能/插入/爆发 诊断")
    print("  客户端  : " .. (MKF_Disc_IsForever() and "无限(Forever)·模块生效" or "非无限·模块不生效"))
    print("  当前专精: " .. tostring((type(WR_GetMyTalent) == "function") and WR_GetMyTalent() or "?"))
    if type(PigSet) == "table" then
        MKF_Disc_EnsureDefaults()
        local keys = { FEAT.QS, FEAT.QS_AUTO, FEAT.QTQS, FEAT.ZYSR, FEAT.ZYSR_MODE,
                       FEAT.XLHZ, FEAT.CJ, FEAT.AYSHM, FEAT.BF, FEAT.BF_RACE,
                       FEAT.CR_GNZ, FEAT.CR_XX, FEAT.CR_ZLDY,
                       FEAT.BF_S1, FEAT.BF_S2, FEAT.BF_S3,
                       FEAT.BF_SLOT1, FEAT.BF_SLOT2, FEAT.BF_SLOT3 }
        for _, k in ipairs(keys) do
            print("  " .. k .. " = " .. tostring(PigSet[k]))
        end
    end
    print("  法术解析（ID 以本服客户端为准；槽位来自既有宏/SkillColor）：")
    local names = { "苦修", "联结治疗", "能量灌注", "神圣新星", "心灵专注",
                    "治疗祷言", "真言术：韧", "坚韧祷言", "心灵之火", "惩击",
                    "暗言术：灭", "暗言术：死", "驱散魔法", "群体驱散" }
    for _, s in ipairs(names) do
        local id = "待核实"
        if type(WR_ResolveSpellID) == "function" then
            local ok, r = pcall(WR_ResolveSpellID, s)
            if ok and r then id = tostring(r) end
        end
        local slot = "未登记"
        if type(WR_SoD_ResolveSlot) == "function" then
            local ok, r = pcall(WR_SoD_ResolveSlot, s)
            if ok and r then slot = tostring(r) end
        end
        local absent = (type(WR_Forever_SkillAbsent) == "table" and WR_Forever_SkillAbsent[s])
                       and "缺失闸门" or "-"
        print("    " .. s .. "  ID=" .. id .. "  槽位=" .. slot .. "  " .. absent)
    end
end

SLASH_MKHDISCBURST1 = "/mkhdiscburst"
SlashCmdList["MKHDISCBURST"] = function(msg)
    local m = tostring(msg or ""):match("^%s*(.-)%s*$")
    if m == "on" or m == "all" or m == "全升" then
        MKF_Disc_BurstSetAll(true)
    elseif m == "off" or m == "none" or m == "全关" then
        MKF_Disc_BurstSetAll(false)
    elseif m == "toggle" or m == "切换" then
        MKF_Disc_BurstSetAll("toggle")
    else
        print("用法: /mkhdiscburst on|off|toggle （对应截图 全升/全关/切换）")
    end
end

-- 三个可直接绑定 UI 按钮的命令别名（截图：全升 / 全关 / 切换）
SLASH_MKHDISCBFALL1 = "/mkhdiscbfall"
SlashCmdList["MKHDISCBFALL"] = function() MKF_Disc_BurstSetAll(true) end
SLASH_MKHDISCBFNONE1 = "/mkhdiscbfnone"
SlashCmdList["MKHDISCBFNONE"] = function() MKF_Disc_BurstSetAll(false) end
SLASH_MKHDISCBFTOGGLE1 = "/mkhdiscbftoggle"
SlashCmdList["MKHDISCBFTOGGLE"] = function() MKF_Disc_BurstSetAll("toggle") end

-- 爆发槽位设置：/mkhdiscslot <1|2|3> <技能名|off>
SLASH_MKHDISCSLOT1 = "/mkhdiscslot"
SlashCmdList["MKHDISCSLOT"] = function(msg)
    local idx, name = tostring(msg or ""):match("^%s*([123])%s+(.-)%s*$")
    if not idx or type(PigSet) ~= "table" then
        print("用法: /mkhdiscslot <1|2|3> <技能名|off>   (off = 恢复「未设置」)")
        return
    end
    local var = BURST_SLOT_VARS[tonumber(idx)]
    if name == "" or name == "off" or name == "未设置" or name == "nil" then
        PigSet[var] = nil
    else
        PigSet[var] = name
    end
    print("|cffFF69B4[MKHelperForever 戒律]|r 爆发槽位 " .. idx
          .. " = " .. tostring(PigSet[var] or "未设置"))
end

-- 真言术：韧「切」：/mkhdiscbuff 1|2|toggle
SLASH_MKHDISCBUFF1 = "/mkhdiscbuff"
SlashCmdList["MKHDISCBUFF"] = function(msg)
    local m = tostring(msg or ""):match("^%s*(.-)%s*$")
    if type(PigSet) ~= "table" then return end
    MKF_Disc_EnsureDefaults()
    if m == "1" or m == "真言术：韧" then
        PigSet[FEAT.ZYSR_MODE] = 1
    elseif m == "2" or m == "坚韧祷言" then
        PigSet[FEAT.ZYSR_MODE] = 2
    else
        PigSet[FEAT.ZYSR_MODE] = (tonumber(PigSet[FEAT.ZYSR_MODE]) == 2) and 1 or 2
    end
    print("|cffFF69B4[MKHelperForever 戒律]|r 韧「切」= "
          .. ((tonumber(PigSet[FEAT.ZYSR_MODE]) == 2) and "坚韧祷言(群体)" or "真言术：韧(单体)"))
end
