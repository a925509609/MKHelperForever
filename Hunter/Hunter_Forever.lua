-- ============================================================
-- Hunter_Forever.lua  《魔兽世界：无限》(Forever) 猎人完整循环
-- ------------------------------------------------------------
-- 设计：完全不依赖 COMBAT_LOG_EVENT_UNFILTERED（无限已禁用）。
--   所有判定走安全 helper：
--     WR_SpellUsable        —— 冷却 + IsUsableSpell（框架已做 CLEU-free）
--     WR_GetUnitDebuffTime  —— 目标 DOT 剩余（光环缓存，C_UnitAuras）
--     WR_GetUnitBuffTime    —— 自身 BUFF 剩余
--     WR_GetUnitHP          —— 目标血量百分比
--     WR_GetGCD / WR_UnitRange / WR_PlayerMove
--   技能以 WR_SpellUsable 门控，无限未实装的技能自动跳过，天然兼容未来补丁。
--
-- 输出：WR_ColorFrame_ShowSkill(法术名, 槽位) —— 外部 AHK 读屏色按键施法
--   槽位约定（与 MKHelperForever 既有映射保持一致，新增技能在 16~22 段）：
--     85=自动射击 75=毒蛇钉刺 76=雄鹰守护 78=稳固射击 79=瞄准射击
--     77=奇美拉射击 74=多重射击 73=杀戮射击 19=雄狮守护 78b=蝰蛇守护
--     17=狂野怒火 16=杀戮命令 18=急速射击 21=爆炸射击 22=黑箭
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
-- ★ 共享 helper（原单文件内联，拆分后供各专精文件调用；改为全局）
-- ============================================================

function WR_HunterForever_Base()
    ShiFaSuDu = ShiFaSuDu or 0.4
    GCD = WR_GetGCD("毒蛇钉刺")
    PlayerHP = WR_GetUnitHP("player")
    PlayerMP = WR_GetUnitMP("player")
    PlayerMove = WR_PlayerMove()
    TargetRange = WR_UnitRange("target")
    TargetInCombat = WR_UnitInCombat("target")
    UnitCount8 = WR_GetRangeHarmUnitCount(8)
    AutoShotOn = IsAutoRepeatSpell("自动射击")
    return (TargetRange and TargetRange <= 40)
end

-- 共享：进入战斗主循环门（防 ADD，与原 Marksmanship 一致）
function WR_HunterForever_InCombatGate()
    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local allowAdd = (PigSet and PigSet.FANG_ADD_LR ~= 0)
    if not (inBossEncounter or (UnitAffectingCombat("player") and TargetInCombat and allowAdd)) then
        return false
    end
    return true
end

-- 共享：守护管理（雄鹰默认；蓝量<30% 切蝰蛇；雄狮若可用则优先）
function WR_HunterForever_Aspect()
    if WR_Forever_IsSpellKnown and WR_Forever_IsSpellKnown("雄狮守护")
       and WR_GetUnitBuffTime("player", "雄狮守护") == 0 and WR_SpellUsable("雄狮守护") then
        if WR_ColorFrame_ShowSkill("雄狮守护", 19) then return true end
    elseif PlayerMP < 0.30 and WR_GetUnitBuffTime("player", "蝰蛇守护") == 0 and WR_SpellUsable("蝰蛇守护") then
        if WR_ColorFrame_ShowSkill("蝰蛇守护", 78) then return true end
    elseif PlayerMP >= 0.30 and WR_GetUnitBuffTime("player", "雄鹰守护") == 0 and WR_SpellUsable("雄鹰守护") then
        if WR_ColorFrame_ShowSkill("雄鹰守护", 76) then return true end
    end
    return false
end

-- 共享：自动射击保持
function WR_HunterForever_AutoShot(inRange)
    if not AutoShotOn and UnitCanAttack("player", "target") and not UnitIsDead("target")
       and inRange and WR_SpellUsable("自动射击") then
        if WR_ColorFrame_ShowSkill("自动射击", 85) then return true end
    end
    return false
end

-- 共享：毒蛇钉刺保持（目标无则补）
function WR_HunterForever_Serpent(inRange)
    if inRange and WR_GetUnitDebuffTime("target", "毒蛇钉刺") == 0 and WR_SpellUsable("毒蛇钉刺", true) then
        if WR_ColorFrame_ShowSkill("毒蛇钉刺", 75) then return true end
    end
    return false
end

-- 共享：宠物存活时杀戮命令（野兽控制核心）
function WR_HunterForever_KillCommand(inRange)
    if UnitExists("pet") and not UnitIsDead("pet") and inRange
       and WR_SpellUsable("杀戮命令", true) then
        if WR_ColorFrame_ShowSkill("杀戮命令", 16) then return true end
    end
    return false
end

-- 共享：斩杀（杀戮射击，<20% 血量）
function WR_HunterForever_KillShot(inRange)
    if inRange then
        local hpPct = WR_SafeHPPct("target")
        if hpPct < 0.20 and WR_SpellUsable("杀戮射击", true) then
            if WR_ColorFrame_ShowSkill("杀戮射击", 73) then return true end
        end
    end
    return false
end

-- 共享：AoE（3+ 敌）多重射击
function WR_HunterForever_MultiShot(inRange)
    if inRange and UnitCount8 >= 3 and WR_SpellUsable("多重射击", true) then
        if WR_ColorFrame_ShowSkill("多重射击", 74) then return true end
    end
    return false
end
