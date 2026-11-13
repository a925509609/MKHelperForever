-- ============================================================
-- Hunter_Forever_MM.lua  《魔兽世界：无限》(Forever) 射击专精循环
-- 改动日期：2026-11-13（Forever 适配重建）
-- 本次重建内容：
--   1. 按 Forever 骨架重建优先级：射击天赋主动技能按可用性插入
--      （强击光环常驻 buff / 狙击伤害增益 / 散射射击贴脸控制）
--      → 雄鹰射击窗口联动 → 毒蛇钉刺保持 → 多重射击(AoE) → 瞄准射击
--      → 急速射击(爆发) → 填充（爆炸射击，无限存在、已学即打）。
--   2. 原 SoD 版引用的三个无限不存在的经典射击技能（Chimera/Steady/Kill 系，
--      见 Data/Forever_SkillRegistry.lua 缺失口径）连同调用整体移除；
--      同时删除 SoD 符文存在性门控调用（该门控在 Forever 恒 false，会屏蔽
--      真实存在的技能）。
--   3. 接入无限新增射击天赋主动技能（Data/Forever_Abilities.lua）：
--      强击光环(Trueshot Aura) / 散射射击(Scatter Shot) / 狙击(Sniper Shot)，
--      以 WR_Forever_IsSpellKnown(中文名) 且 WR_SpellUsable(中文名, true) 双重
--      门控，未学/没点天赋自动跳过——天然支持练级。
--   4. 雄鹰射击 buff 窗口联动：窗口将断(<6s)时先打瞄准射击刷续窗口（置于
--      DOT 之前）；窗口充裕时把爆发急速射击提到钉刺之前倾泻高伤害；空窗按
--      正常优先级照常输出，不因等待触发而卡循环。
--   5. 防ADD战斗门按专精传"射击"（公共件读 FANG_ADD_SJLR）。
--   6. 任务#6 BUG-1 修复：AutoShot 前置于 gate 的调用传入 specName，由公共件按
--      「防ADD关闭 或 目标已进战斗」约束点亮，脱战防ADD开启时不再平射拉怪；
--      回退槽与宏层终值对齐（雄鹰守护=1 蝰蛇守护=34 自动射击=40，守护/平射走公共件）。
-- 依赖：Hunter_Forever.lua 公共件全部 helper（WR_SpellUsable/光环时间/色块
--   槽位口径见公共件头注释；回退槽与宏层 WR_SkillColor["HUNTER"] 终值对齐：
--   强击光环=102 狙击=93 散射射击=94，钉刺/多重/瞄准/急速/爆炸走公共件槽位）。
-- ============================================================

if WR_PlayerClass ~= "HUNTER" then return end

function WR_HunterForeverMM()
    local specName = "射击"
    local inRange = WR_HunterForever_Base()
    if not inRange then return false end
    if WR_HunterForever_AutoShot(inRange, specName) then return true end
    if not WR_HunterForever_InCombatGate(specName) then return false end
    if WR_HunterForever_Aspect() then return true end

    -- ===== 射击天赋主动技能（按已学插入；未学自动跳过） =====
    -- 强击光环：30 分钟团队增益，不在身上且可用即补（常驻类优先级最高）
    if WR_Forever_IsSpellKnown("强击光环")
       and WR_GetUnitBuffTime("player", "强击光环") == 0
       and WR_SpellUsable("强击光环") then
        if WR_ColorFrame_ShowSkill("强击光环", 102) then return true end
    end
    -- 狙击：高伤稳射，CD 好即放
    if WR_Forever_IsSpellKnown("狙击") and WR_SpellUsable("狙击", true) then
        if WR_ColorFrame_ShowSkill("狙击", 93) then return true end
    end
    -- 散射射击：短程控制（"Turns off your attack"），仅贴脸(≤10码)时用于自保
    if inRange and type(TargetRange) == "number" and TargetRange <= 10
       and WR_Forever_IsSpellKnown("散射射击") and WR_SpellUsable("散射射击", true) then
        if WR_ColorFrame_ShowSkill("散射射击", 94) then return true end
    end

    -- ===== 雄鹰射击窗口联动（type()+pcall 保护由公共件封装） =====
    -- 将断(<6s)：瞄准射击优先刷续窗口
    if WR_HunterForever_EagleFading() then
        if WR_HunterForever_Aimed() then return true end
    end

    -- ===== DOT 保持：毒蛇钉刺 =====
    if WR_HunterForever_Serpent(inRange) then return true end

    -- 窗口充裕(>=6s)：爆发急速射击前提，倾泻高伤害填充
    if WR_HunterForever_EagleWindow() and WR_HunterForever_RapidShot() then return true end

    -- ===== AoE：多重射击（宏表槽位 20；低等级由公共件自动放宽到 2+ 敌） =====
    if WR_HunterForever_MultiShot(inRange) then return true end

    -- ===== 单体核心：瞄准射击（未学自动跳过，低等级降级为钉刺+平射） =====
    if WR_HunterForever_Aimed() then return true end

    -- ===== 爆发兜底：急速射击（空窗/常规节奏下 CD 好即放） =====
    if WR_HunterForever_RapidShot() then return true end

    -- ===== 填充：爆炸射击（无限存在；宏表槽位 7；已学即可用即打） =====
    if WR_SpellUsable("爆炸射击", true) then
        if WR_ColorFrame_ShowSkill("爆炸射击", 7) then return true end
    end

    return false
end
