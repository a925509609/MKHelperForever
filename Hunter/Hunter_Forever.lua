-- ============================================================
-- Hunter_Forever.lua  《魔兽世界：无限》(Forever) 猎人公共件
-- ------------------------------------------------------------
-- 改动日期：2026-11-13（Forever 适配重建）
-- 本次重建内容：
--   1. 删除自动射击状态检测 API 调用——该 API 在本仓库与无限客户端均不存在，
--      原代码每 tick 抛错（主要 bug）。自动射击是常驻平射，色块逻辑本就只在
--      满足条件时点亮，无需检测"是否已开启"；改为直接依赖
--      WR_SpellUsable("自动射击") + 目标存在/可选中/可攻击/未死亡判断。
--   2. 防ADD战斗门不再误读菜单中不存在的旧共享键，按专精读菜单真实键
--      （Hunter_Menu.lua 已核实）：野兽控制=FANG_ADD_SWLR / 射击=FANG_ADD_SJLR /
--      生存=FANG_ADD_SCLR；pcall+tonumber 存在性保护。键值口径：读不到/非数字
--      或显式值==1 → 防ADD开启（与菜单 defaultID=1"是"一致，需玩家+目标都进
--      战斗）；仅显式值 ~= 1（如 2"否"）→ 防ADD关闭（玩家战斗中即放行）。
--      2026-11-13 任务#6（BUG-1 修复）：上述按专精读键逻辑从 InCombatGate 抽出
--      为可复用函数 WR_HunterForever_AddAllowed(specName)，InCombatGate 改为调用
--      它，判定顺序/语义逐行保持等价（QA 夹具 9 例推演验收口径不变）。
--   3. 无限中不存在的宠物指令类/斩杀类/读条填充类经典技能，其共享 helper 连同
--      调用点整体删除，不留注释死代码（技能名见专精文件重建说明）。
--   4. 守护管理删除无限不存在的旧守护分支（该守护技能无限未实装）；保留既定口径：
--      雄鹰守护默认 / 蓝量<30% 切蝰蛇守护（PlayerMP 为 WR_GetUnitMP 百分比 0-1）。
--   5. 新增雄鹰射击 buff 窗口联动 helper（依赖 Hunter_EagleShot.lua 全局
--      WR_GetEarliestEagleShotRemaining，调用点 type()+pcall 双保护）：
--      WR_HunterForever_EagleRemaining / _EagleFading / _EagleWindow。
--   6. 新增练级动态 helper WR_HunterForever_PlayerLevel（UnitLevel 存在性+
--      返回值兜底）；AoE 阈值在 <40 级由"3+敌"放宽到"2+敌"。整个循环采用
--      "谁可用打谁"的降级式优先级：每技能挂 WR_SpellUsable 门控，低等级未学
--      / 无限不存在的技能自动跳过，天然适配任意等级，不写死等级阈值列表。
-- 依赖 helper（全部安全封装，禁止裸调原 API）：
--   WR_SpellUsable / WR_GetUnitBuffTime / WR_GetUnitDebuffTime / WR_GetUnitHP /
--   WR_GetUnitMP / WR_GetGCD / WR_UnitRange / WR_GetRangeHarmUnitCount /
--   WR_PlayerMove / WR_UnitInCombat / WR_SafeHPPct / WR_Forever_IsSpellKnown /
--   WR_Forever_ClientInfo / WR_ColorFrame_ShowSkill
-- 色块口径：统一 WR_ColorFrame_ShowSkill(技能名, 回退槽位)。
--   Hunter_Macros.lua WR_SkillColor["HUNTER"] 映射终值（宏层 engineer-2 已落地，
--   表命中优先；本件与三个专精文件的回退槽全部与之对齐，双保险）：
--   毒蛇钉刺=6 爆炸射击=7 黑箭=8 瞄准射击=13 多重射击=20 急速射击=22
--   狂野怒火=24 雄鹰守护=1 蝰蛇守护=34 自动射击=40 胁迫=90 召唤猎鹰=92
--   狙击=93 散射射击=94 威慑=95 长足踢击=96 反击=101 强击光环=102。
--   （2026-11-13 任务#6 WARN-1：雄鹰守护/蝰蛇守护/自动射击 回退槽由存量错位的
--   76/78/85 同步为宏层修正终值 1/34/40，其余槽位不变。）
--   无限未实装的旧经典技能已全部从映射表与循环移除，循环不再引用；
--   103/104 备用爆发宏行不进映射表（同技能单键）。
-- ============================================================

if WR_PlayerClass ~= "HUNTER" then return end

-- ============================================================
-- ★ 统一入口：按专精分派；非 Forever 客户端回退到旧 SoD 三函数
-- ============================================================

function WR_HunterForeverRotation()
    local spec = WR_GetMyTalent()
    local isForever = WR_Forever_ClientInfo().isForever

    if not isForever then
        -- SoD / 经典客户端：沿用既有实现（它们本身也是 CLEU-free）
        if spec == "野兽控制" and type(WR_HunterBeastMastery) == "function" then
            return WR_HunterBeastMastery()
        elseif spec == "射击" and type(WR_HunterMarksmanship) == "function" then
            return WR_HunterMarksmanship()
        elseif spec == "生存" and type(WR_HunterSurvival) == "function" then
            return WR_HunterSurvival()
        end
        return false
    end

    -- Forever 路径
    if spec == "野兽控制" then
        return WR_HunterForeverBM()
    elseif spec == "射击" then
        return WR_HunterForeverMM()
    elseif spec == "生存" then
        return WR_HunterForeverSV()
    end
    return false
end

-- ============================================================
-- ★ 共享 helper（供三个专精文件调用；改为全局）
-- ============================================================

-- 基础变量采集 + 射程判断。
-- 返回 inRange：目标存在、可攻击、未死亡，且 40 码内。
-- WR_UnitRange 读不到（999）时视为远程可打 = 放行，避免射程库缺席导致循环瘫痪。
function WR_HunterForever_Base()
    ShiFaSuDu = ShiFaSuDu or 0.4
    GCD = WR_GetGCD("毒蛇钉刺")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)

    if not UnitExists("target") then return false end
    if not UnitCanAttack("player", "target") then return false end
    if UnitIsDead("target") then return false end
    if type(TargetRange) == "number" and TargetRange < 999 and TargetRange > 40 then
        return false
    end
    return true
end

-- 共享：按专精读取菜单"防ADD"设置，返回"当前设置是否放行 ADD 行为"。
-- 返回值语义（严格区分于 InCombatGate 的放行判定）：
--   true  → 防ADD 关闭（菜单显式 2"否"/0/其他非 1 数字）→ 允许先行开怪；
--   false → 防ADD 开启（默认/读不到/非数字/显式 1"是"）→ 不允许主动 ADD。
-- 键值口径与菜单 defaultID=1 一致；type(PigSet)+pcall+tonumber 三重保护不裸读。
-- 键名映射：野兽控制=FANG_ADD_SWLR / 射击=FANG_ADD_SJLR / 生存=FANG_ADD_SCLR。
function WR_HunterForever_AddAllowed(specName)
    local key = "FANG_ADD_SWLR"                       -- 野兽控制（默认）
    if specName == "射击" then key = "FANG_ADD_SJLR"
    elseif specName == "生存" then key = "FANG_ADD_SCLR" end

    local preventAdd = true                           -- 默认防ADD开启（=defaultID 1"是"）
    if type(PigSet) == "table" then
        local ok, raw = pcall(function() return PigSet[key] end)
        local val = ok and tonumber(raw) or nil
        if val then preventAdd = (val == 1) end       -- 显式 ~=1（菜单"否"=2、旧口径 0）才关闭防ADD
    end
    return not preventAdd
end

-- 共享：进入战斗主循环门（防 ADD）。
-- 键值口径（与菜单 defaultID=1 一致，team-lead 2026-11-13 修正下发）：
--   读不到/非数字          → 防ADD 开启（默认与菜单默认值"是"一致），
--                            需玩家与目标都进战斗才放行；
--   显式值 == 1（"是"）    → 同上，防ADD 开启；
--   显式值 ~= 1（如 2"否"）→ 防ADD 关闭，玩家战斗中即放行。
-- gate 内逻辑：boss 框存活（且玩家或目标 in combat）直接放行。
-- 任务#6：读键部分抽到 WR_HunterForever_AddAllowed，本函数判定顺序/结果与抽前等价。
function WR_HunterForever_InCombatGate(specName)
    local bossFrameActive = false
    for i = 1, 4 do
        if UnitExists("boss" .. i) then bossFrameActive = true; break end
    end
    if bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target")) then
        return true
    end
    if not UnitAffectingCombat("player") then return false end

    if WR_HunterForever_AddAllowed(specName) then return true end
    return TargetInCombat and true or false
end

-- 共享：守护管理（雄鹰守护默认；蓝量<30% 切蝰蛇守护；旧无限未实装守护已移除）
function WR_HunterForever_Aspect()
    local mp = tonumber(PlayerMP) or 1
    if mp < 0.30 then
        if WR_GetUnitBuffTime("player", "蝰蛇守护") == 0 and WR_SpellUsable("蝰蛇守护") then
            if WR_ColorFrame_ShowSkill("蝰蛇守护", 34) then return true end
        end
    else
        if WR_GetUnitBuffTime("player", "雄鹰守护") == 0 and WR_SpellUsable("雄鹰守护") then
            if WR_ColorFrame_ShowSkill("雄鹰守护", 1) then return true end
        end
    end
    return false
end

-- 共享：自动射击保持（无限无法检测 AutoShot 开关状态，直接按可用提示）。
-- 任务#6 BUG-1 修复：本 helper 在专精文件中先于 InCombatGate 调用（保留"防ADD关闭
-- 时可平射开怪"能力），故此处自带防ADD语义约束——仅当
--   防ADD关闭（AddAllowed=true，玩家主动选择允许开怪）或
--   目标已进战斗（TargetInCombat：队友已拉怪/ADD 已被打上，需即刻起手）
-- 二者之一成立时才点亮色块；否则脱战仅选中目标不再平射，防ADD 门不被击穿。
-- TargetInCombat 由 WR_HunterForever_Base() 每次 tick 先行全局缓存（专精文件均先调
-- Base 且 inRange 为假即 return，故执行到此处时该缓存必然新鲜）。
function WR_HunterForever_AutoShot(inRange, specName)
    if not (WR_HunterForever_AddAllowed(specName) or TargetInCombat) then return false end
    if inRange and WR_SpellUsable("自动射击") then
        if WR_ColorFrame_ShowSkill("自动射击", 40) then return true end
    end
    return false
end

-- 共享：毒蛇钉刺保持（目标无 DOT 则补）
function WR_HunterForever_Serpent(inRange)
    if inRange and WR_GetUnitDebuffTime("target", "毒蛇钉刺") == 0
       and WR_SpellUsable("毒蛇钉刺", true) then
        if WR_ColorFrame_ShowSkill("毒蛇钉刺", 6) then return true end
    end
    return false
end

-- 共享：多重射击 AoE。练级动态：<40 级 2+ 敌即放，≥40 级维持 3+ 敌。
-- 多重未学会时 WR_SpellUsable 直接 false，低等级自然降级为单体链。
function WR_HunterForever_MultiShot(inRange)
    local need = 3
    local lv = WR_HunterForever_PlayerLevel()
    if lv > 0 and lv < 40 then need = 2 end
    if inRange and (tonumber(UnitCount8) or 0) >= need and WR_SpellUsable("多重射击", true) then
        if WR_ColorFrame_ShowSkill("多重射击", 20) then return true end
    end
    return false
end

-- 共享：瞄准射击（单体核心填充，宏表槽位 13）
function WR_HunterForever_Aimed()
    if WR_SpellUsable("瞄准射击", true) then
        if WR_ColorFrame_ShowSkill("瞄准射击", 13) then return true end
    end
    return false
end

-- 共享：急速射击（爆发型急速 buff，CD 好且自身 buff 不在期才放；宏表槽 22）
function WR_HunterForever_RapidShot()
    if WR_SpellUsable("急速射击", true) and WR_GetUnitBuffTime("player", "急速射击") == 0 then
        if WR_ColorFrame_ShowSkill("急速射击", 22) then return true end
    end
    return false
end

-- ============================================================
-- ★ 雄鹰射击 buff 窗口联动（无限专属机制）
--   数据来源：Hunter_EagleShot.lua 全局 WR_GetEarliestEagleShotRemaining()
--   返回身上"雄鹰射击"buff 最早到期的剩余秒数（无则 0）。
--   联动口径：
--     窗口充裕(>=6s) → 倾泻高伤害填充与爆发（正常优先级即可全放）；
--     窗口将断(<6s)  → 优先瞄准射击刷续窗口，并暂缓爆发，避免爆发打在空窗上；
--     无窗口(=0)     → 不等待触发，按正常优先级照常输出（防循环停摆）。
--   "暂缓爆发"仅在瞄准射击当前可施放时生效：未学/不可用则不压爆发。
-- ============================================================

local EAGLE_REFRESH_SEC = 6

function WR_HunterForever_EagleRemaining()
    if type(WR_GetEarliestEagleShotRemaining) == "function" then
        local ok, remaining = pcall(WR_GetEarliestEagleShotRemaining)
        if ok and type(remaining) == "number" and remaining > 0 then
            return remaining
        end
    end
    return 0
end

-- 窗口将断（0 < 剩余 < 6 秒）
function WR_HunterForever_EagleFading()
    local remaining = WR_HunterForever_EagleRemaining()
    return remaining > 0 and remaining < EAGLE_REFRESH_SEC
end

-- 窗口充裕（剩余 >= 6 秒）
function WR_HunterForever_EagleWindow()
    return WR_HunterForever_EagleRemaining() >= EAGLE_REFRESH_SEC
end

-- ============================================================
-- ★ 练级动态：玩家等级读取（存在性 + 返回值双重兜底，读不到按 0）
--   等级仅用于放宽低等级 AoE 阈值；技能可用性一律靠 WR_SpellUsable
--   运行时探测（"已学即可用"），不写死等级阈值列表。
-- ============================================================
function WR_HunterForever_PlayerLevel()
    if type(UnitLevel) ~= "function" then return 0 end
    local ok, lv = pcall(UnitLevel, "player")
    if ok and tonumber(lv) then return tonumber(lv) end
    return 0
end
