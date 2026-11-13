-- ============================================================
-- Hunter_Forever_BM.lua  《魔兽世界：无限》(Forever) 野兽控制专精循环
-- 改动日期：2026-11-13（Forever 适配重建）
-- 本次重建内容：
--   1. 按 Forever 骨架重建优先级：爆发窗口（狂野怒火+胁迫+召唤猎鹰，宠物存活
--      门控）→ 毒蛇钉刺保持 → 多重射击(AoE) → 瞄准射击 → 急速射击(爆发)
--      → 填充（爆炸射击，无限存在、已学即打）。
--   2. 无限中不存在的经典巫妖王技能（宠物指令/斩杀/读条填充类，详见
--      Data/Forever_SkillRegistry.lua 缺失清单）连同调用整体移除。
--   3. 接入无限新增野兽控制天赋主动技能（Data/Forever_Abilities.lua）：
--      狂野怒火(Bestial Wrath) / 胁迫(Intimidation) / 召唤猎鹰(Summon Hawk)，
--      以 WR_Forever_IsSpellKnown(中文名) 且 WR_SpellUsable(中文名, true) 双重
--      门控，未学/没点天赋自动跳过——天然支持练级。
--   4. 雄鹰射击 buff 窗口联动：窗口将断(<6s)且瞄准可用时暂缓爆发、先瞄准刷窗；
--      窗口充裕或空窗时爆发 CD 好即放（空窗不等待，防循环停摆）。
--   5. 防ADD战斗门按专精传"野兽控制"（公共件读 FANG_ADD_SWLR）。
--   6. 任务#6 BUG-1 修复：AutoShot 前置于 gate 的调用传入 specName，由公共件按
--      「防ADD关闭 或 目标已进战斗」约束点亮，脱战防ADD开启时不再平射拉怪；
--      回退槽与宏层终值对齐（雄鹰守护=1 蝰蛇守护=34 自动射击=40，守护/平射走公共件）。
-- 依赖：Hunter_Forever.lua 公共件全部 helper（WR_SpellUsable/光环时间/色块
--   槽位口径见公共件头注释；回退槽与宏层 WR_SkillColor["HUNTER"] 终值对齐：
--   狂野怒火=24 胁迫=90 召唤猎鹰=92，钉刺/多重/瞄准/急速/爆炸走公共件槽位）。
-- ============================================================

if WR_PlayerClass ~= "HUNTER" then return end

function WR_HunterForeverBM()
    local specName = "野兽控制"
    local inRange = WR_HunterForever_Base()
    if not inRange then return false end
    if WR_HunterForever_AutoShot(inRange, specName) then return true end
    if not WR_HunterForever_InCombatGate(specName) then return false end
    if WR_HunterForever_Aspect() then return true end

    -- ===== 爆发窗口：狂野怒火 + 胁迫 + 召唤猎鹰（宠物存活门控） =====
    -- 雄鹰射击窗口将断且瞄准可用 → 本 tick 暂缓爆发，让位给瞄准刷续窗口；
    -- 窗口充裕(>=6s)或空窗 → 爆发 CD 好即放。
    local petAlive = UnitExists("pet") and not UnitIsDead("pet")
    local holdBurst = WR_HunterForever_EagleFading()
        and WR_SpellUsable("瞄准射击", true)
    if petAlive and not holdBurst then
        if WR_SpellUsable("狂野怒火", true)
           and WR_GetUnitBuffTime("player", "狂野怒火") == 0 then
            if WR_ColorFrame_ShowSkill("狂野怒火", 24) then return true end
        end
        if WR_Forever_IsSpellKnown("胁迫") and WR_SpellUsable("胁迫", true) then
            if WR_ColorFrame_ShowSkill("胁迫", 90) then return true end
        end
        if WR_Forever_IsSpellKnown("召唤猎鹰") and WR_SpellUsable("召唤猎鹰", true) then
            if WR_ColorFrame_ShowSkill("召唤猎鹰", 92) then return true end
        end
    end

    -- ===== DOT 保持：毒蛇钉刺 =====
    if WR_HunterForever_Serpent(inRange) then return true end

    -- ===== AoE：多重射击（宏表槽位 20；低等级由公共件自动放宽到 2+ 敌） =====
    if WR_HunterForever_MultiShot(inRange) then return true end

    -- ===== 单体核心：瞄准射击（未学自动跳过，低等级降级为钉刺+平射） =====
    if WR_HunterForever_Aimed() then return true end

    -- ===== 爆发填充：急速射击（CD 好且 buff 不在期） =====
    if WR_HunterForever_RapidShot() then return true end

    -- ===== 填充：爆炸射击（无限存在；宏表槽位 7；已学即可用即打） =====
    if WR_SpellUsable("爆炸射击", true) then
        if WR_ColorFrame_ShowSkill("爆炸射击", 7) then return true end
    end

    return false
end
