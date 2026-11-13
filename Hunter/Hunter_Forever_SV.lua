-- ============================================================
-- Hunter_Forever_SV.lua  《魔兽世界：无限》(Forever) 生存专精循环
-- 改动日期：2026-11-13（Forever 适配重建）
-- 本次重建内容：
--   1. 按 Forever 骨架重建优先级：自保/近战天赋技能（威慑·反击·长足踢击，
--      按已学触发）→ DOT 双保持（爆炸射击 / 黑箭，均为无限真实存在技能）
--      → 毒蛇钉刺保持 → 多重射击(AoE) → 瞄准射击 → 填充（自动射击已在 base）。
--   2. 删除 SoD 符文存在性门控调用——它在 Forever 恒 false，会把真实存在的
--      爆炸射击/黑箭整条屏蔽（原主要 bug 之一）；改用 WR_SpellUsable 直接
--      门控（"已学即可用"，无限不存在的技能自动跳过）。
--   3. 原 SoD 版引用的多个无限不存在技能（Kill 斩杀系 / Steady 读条系 /
--      Chimera 系 / 近战连击系）连同调用整体移除。
--   4. 接入无限新增生存天赋主动技能（Data/Forever_Abilities.lua）：
--      威慑(Deterrence) / 反击(Counterattack) / 长足踢击(Strider Kick)，
--      以 WR_Forever_IsSpellKnown(中文名) 且 WR_SpellUsable(中文名, true) 双重
--      门控：威慑低血自保；反击/长足踢击近战位(≤8码)倾泻。未学自动跳过——
--      天然支持练级。
--   5. 雄鹰射击 buff 窗口联动：窗口将断(<6s)先瞄准刷续窗口；窗口充裕时
--      爆炸射击/黑箭高伤 DOT 优先铺满（贴合 buff 窗口）。
--   6. 防ADD战斗门按专精传"生存"（公共件读 FANG_ADD_SCLR）。
--   7. 任务#6 BUG-1 修复：AutoShot 前置于 gate 的调用传入 specName，由公共件按
--      「防ADD关闭 或 目标已进战斗」约束点亮，脱战防ADD开启时不再平射拉怪；
--      回退槽与宏层终值对齐（雄鹰守护=1 蝰蛇守护=34 自动射击=40，守护/平射走公共件）。
-- 依赖：Hunter_Forever.lua 公共件全部 helper（WR_SpellUsable/光环时间/色块
--   槽位口径见公共件头注释；回退槽与宏层 WR_SkillColor["HUNTER"] 终值对齐：
--   威慑=95 长足踢击=96 反击=101 黑箭=8，钉刺/多重/瞄准/急速/爆炸走公共件槽位）。
-- ============================================================

if WR_PlayerClass ~= "HUNTER" then return end

function WR_HunterForeverSV()
    local specName = "生存"
    local inRange = WR_HunterForever_Base()
    if not inRange then return false end
    if WR_HunterForever_AutoShot(inRange, specName) then return true end
    if not WR_HunterForever_InCombatGate(specName) then return false end
    if WR_HunterForever_Aspect() then return true end

    -- ===== 生存天赋主动技能：自保 + 近战位（按已学触发，未学自动跳过） =====
    -- 威慑：25% 招架/闪避 10 秒，低血（<35%）时优先自保
    local hp = tonumber(PlayerHP) or 1
    if hp < 0.35 and WR_Forever_IsSpellKnown("威慑")
       and WR_GetUnitBuffTime("player", "威慑") == 0
       and WR_SpellUsable("威慑", true) then
        if WR_ColorFrame_ShowSkill("威慑", 95) then return true end
    end
    -- 反击 / 长足踢击：近战武器伤害技能，贴身(≤8码)时优先倾泻
    if inRange and type(TargetRange) == "number" and TargetRange <= 8 then
        if WR_Forever_IsSpellKnown("反击") and WR_SpellUsable("反击", true) then
            if WR_ColorFrame_ShowSkill("反击", 101) then return true end
        end
        if WR_Forever_IsSpellKnown("长足踢击") and WR_SpellUsable("长足踢击", true) then
            if WR_ColorFrame_ShowSkill("长足踢击", 96) then return true end
        end
    end

    -- ===== 雄鹰射击窗口联动：将断(<6s)先瞄准刷续窗口 =====
    if WR_HunterForever_EagleFading() then
        if WR_HunterForever_Aimed() then return true end
    end

    -- ===== DOT 双保持：爆炸射击 / 黑箭（无限真实存在，WR_SpellUsable 门控） =====
    -- 窗口充裕时优先铺满高伤 DOT；空窗也照常保持（不等待触发）。
    if inRange and WR_GetUnitDebuffTime("target", "爆炸射击") == 0
       and WR_SpellUsable("爆炸射击", true) then
        if WR_ColorFrame_ShowSkill("爆炸射击", 7) then return true end
    end
    if inRange and WR_GetUnitDebuffTime("target", "黑箭") == 0
       and WR_SpellUsable("黑箭", true) then
        if WR_ColorFrame_ShowSkill("黑箭", 8) then return true end
    end

    -- ===== DOT 保持：毒蛇钉刺 =====
    if WR_HunterForever_Serpent(inRange) then return true end

    -- ===== AoE：多重射击（宏表槽位 20；低等级由公共件自动放宽到 2+ 敌） =====
    if WR_HunterForever_MultiShot(inRange) then return true end

    -- ===== 单体核心：瞄准射击（未学自动跳过，低等级降级为钉刺+平射） =====
    if WR_HunterForever_Aimed() then return true end

    -- ===== 爆发填充：急速射击（CD 好且 buff 不在期） =====
    if WR_HunterForever_RapidShot() then return true end

    return false
end
