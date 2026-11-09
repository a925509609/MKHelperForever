-- ============================================================
-- DeathKnight_Blood.lua  (★ SoD 探索赛季改编版)
-- 鲜血死亡骑士（血坦）自动循环 —— 符文自适应（P1-P4）
-- 参考：Icy-Veins SoD 血DK优先级 + 赛季P3 WA
-- 输出模型：仅 WR_ColorFrame_Show 显示色块，外部 AHK 读屏色按键施法
-- 符文系统：DK 保留经典 GetRuneCooldown(1..6) 原符文；
--   SoD 新增符文技能经 WR_SoD_HasRune 门控（如装备则解锁）
-- 槽位约定（AHK 据此映射按键）：
--   201=疾病(血液沸腾/爆发) 202=心脏打击 203=符文打击 204=死亡打击
--   205=吸血鬼之血 206=反魔法护罩 207=符文武器增效 208=凋零缠绕
-- ============================================================

function WR_DeathKnightBlood()
    -- ===== 1. 基础变量 =====
    ShiFaSuDu = 0.3
    GCD = WR_GetGCD("心脏打击")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")   -- DK 用符文能量，此处仅占位
    RunicPower = UnitPower("player", 6) or UnitPower("player", 3) or 0  -- 符文能量(6=Runic)
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8  = WR_GetRangeHarmUnitCount(8)
    UnitCount10 = WR_GetRangeHarmUnitCount(10)

    -- ===== 2. 进入战斗主循环门（防ADD）=====
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet.FANG_ADD_DK ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end

    local inRange = (TargetRange and TargetRange <= 5)

    -- ===== 3. 保命（优先）=====
    if PlayerHP < 0.50 and WR_SpellUsable("吸血鬼之血", true) then
        if WR_ColorFrame_ShowSkill("吸血鬼之血", 38) then return true end
    end
    if PlayerHP < 0.65 and WR_SpellUsable("反魔法护罩", true) then
        if WR_ColorFrame_ShowSkill("反魔法护罩", 29) then return true end
    end

    -- ===== 4. 仇恨/输出核心（近战，仅当在射程）=====
    if inRange then
        -- 4.1 双疾病保持（血液沸腾 单/群 或 爆发）
        if (WR_GetUnitDebuffTime("target", "血之疫病") == 0 or WR_GetUnitDebuffTime("target", "冰霜疫病") == 0)
           and WR_SpellUsable("血液沸腾", true) then
            if WR_ColorFrame_ShowSkill("血液沸腾", 6) then return true end
        elseif (WR_GetUnitDebuffTime("target", "血之疫病") == 0 or WR_GetUnitDebuffTime("target", "冰霜疫病") == 0)
           and WR_SpellUsable("爆发", true) then
            if WR_ColorFrame_ShowSkill("爆发", 17) then return true end
        end

        -- 4.2 符文打击（Rune Strike；符文能量反应技，可用即放）
        if RunicPower >= 30 and WR_SpellUsable("符文打击", true) then
            if WR_ColorFrame_ShowSkill("符文打击", 23) then return true end
        end

        -- 4.3 心脏打击（核心，消耗鲜血符文）
        if WR_SpellUsable("心脏打击", true) then
            if WR_ColorFrame_ShowSkill("心脏打击", 39) then return true end
        end

        -- 4.4 死亡打击（自疗，符文能量充裕时）
        if RunicPower >= 40 and WR_SpellUsable("死亡打击", true) then
            if WR_ColorFrame_ShowSkill("死亡打击", 20) then return true end
        end

        -- 4.5 凋零缠绕（符文能量溢出填充）
        if RunicPower >= 55 and WR_SpellUsable("凋零缠绕", true) then
            if WR_ColorFrame_ShowSkill("凋零缠绕", 9) then return true end
        end
    end

    -- ===== 5. 符文武器增效（长 CD 爆发）=====
    if WR_SpellUsable("符文武器增效", true) then
        if WR_ColorFrame_ShowSkill("符文武器增效", 18) then return true end
    end

    return false
end
