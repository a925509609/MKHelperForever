-- ============================================================
-- Mage_Forever.lua  《魔兽世界：无限》(Forever) MAGE 完整循环
-- ------------------------------------------------------------
-- 机械转译自原 SoD 旋转：移除全部 WR_SoD_HasRune 符文门（无限无符文系统），
-- 改走 WR_SpellUsable（已含 WR_Forever_SkillAbsent 缺失闸门）+ WR_Forever_IsSpellKnown。
-- 无限里真实存在的经典/TBC 技能按原名解析；缺失的 WotLK/SoD 专属技能由闸门跳过。
-- ============================================================

function WR_MageForeverRotation()
    local spec = WR_GetMyTalent()
    local isForever = WR_Forever_ClientInfo().isForever
    -- 非 Forever 客户端：回退原 SoD 实现
    if not isForever then
        if spec == "奥术" then WR_MageArcane() end
        if spec == "火焰" then WR_MageFire() end
        if spec == "冰霜" then WR_MageFrost() end
        return
    end
    -- Forever 路径：先让专精循环处理。
    -- ★ 关键修复（2026-11-05）：专精循环内部有「进入战斗门」，选怪未开打会直接 return false，
    --   若把保底写在循环末尾则永远到不了。故在分发器捕获返回值：仅当专精循环一行技能都没提示
    --   （1 级未解锁专精 / 选怪未开打被进战门挡掉 / spec 解析为空）时，由保底火球术顶上。
    local handled = false
    if spec == "奥术" then handled = WR_MageForeverArcane() end
    if spec == "火焰" then handled = WR_MageForeverFire() end
    if spec == "冰霜" then handled = WR_MageForeverFrost() end
    if not handled then WR_MageForever_FallbackFireball(spec) end
end

-- ★ 法师防ADD 判定（2026-11-05 修复：原 Forever 路径读 FANG_ADD_MAGE，但菜单从未赋值该变量，
--   且 `val~=0` 在菜单存 1/2 时恒为 true，导致防ADD 开关对法师完全失效）。
--   菜单 1=是(开), 2=否(关)；三个专精菜单变量名不同：奥术=AF_FADD, 火焰=FANG_ADD_HUOFA, 冰霜=FADD_BF。
--   返回 true 表示「防ADD关 / 允许 ADD / 允许起手」，false 表示防ADD开。
function WR_MageForever_AllowAdd(spec)
    local var = "AF_FADD"
    if spec == "火焰" then var = "FANG_ADD_HUOFA"
    elseif spec == "冰霜" then var = "FADD_BF" end
    return (PigSet[var] == 2)
end

-- ============================================================
-- ★ 保底基础攻击（2026-11-05 三次修复：法师 1 级选怪不提示技能）
-- 触发场景：分发器里专精循环返回 false（没提示任何技能）时调用，典型情况：
--   · 1 级未解锁专精/未投天赋点 → WR_GetMyTalent 落入「奥术」但循环无 1 级技能；
--   · 选怪未开打 → 专精循环「进入战斗门」直接 return false；
--   · spec 解析为空（TalentId=5）→ 三个 if 分支全不命中。
-- 火球术是法师 1 级即会（spellID 133）、不依赖专精的通用攻击，作为兜底最合适。
--
-- ★ 三次修复核心：之前用 WR_SpellUsable("火球术") 判定，而它依赖 WR_ResolveSpellID 把
--   中文名解析成 spellID。无限 1.60.x 下「中文名→ID」解析不可靠（C_Spell.* 不认名字，
--   法术书索引 key 也可能对不上），一旦解析为 nil，WR_SpellUsable 直接 false → 保底失效。
--   故改用数字 ID 133 直查（IsPlayerSpell/IsUsableSpell 都认数字 ID），彻底绕开名字解析。
--   射程不卡门（由玩家自行判断，提示只是建议起手）；但「法力不足」按用户需求会拦截提示，
--   走 IsUsableSpell 的 noMana 第二返回值（与整套旋转的 WR_SpellUsable 行为一致）。
--   「起手提示」另受防ADD 约束：仅防ADD关(allowAdd)时，未进战选怪才提示（见 WR_MageForever_AllowAdd）。
-- ============================================================
function WR_MageForever_FallbackFireball(spec)
    -- ★ 每 tick 先清除火球术自身色块，仅当满足提示条件时才点亮；
    --   否则无目标/脱战时旧色块会残留（WR_ColorFrame_Show 只在成功 ShowSkill 时才清旧框，
    --   未成功调用时框体不会被隐藏 → 「没选怪也显示火球术」的粘连现象）。
    WR_MageForever_HideFireball()

    -- ★ 用数字 ID 133（火球术）直接判「是否已学会」，绕开不可靠的中文名解析。
    -- IsUsableSpell 返回 (usable, noMana)：usable 受 GCD/冷却影响（不卡起手提示），
    -- noMana=true 表示已学会但法力不足。整体与 WR_SpellUsable 的吃法力门槛保持一致。
    local fireballID = 133
    local usable, noMana = false, false
    if type(IsUsableSpell) == "function" then
        local ok, a, b = pcall(IsUsableSpell, fireballID)
        if ok then usable, noMana = a and true or false, b and true or false end
    end
    local learned = false
    if type(IsPlayerSpell) == "function" then learned = IsPlayerSpell(fireballID) end
    if not learned then learned = usable end
    if not learned then return false end

    -- ★ 蓝量门槛（2026-11-05 用户需求：法力不足时不提示技能）。
    -- 已学会但蓝不够 → 不提示（与整套旋转 WR_SpellUsable 行为一致）。
    if noMana then return false end

    local bossFrameActive = false
    for i = 1, 4 do if UnitExists("boss" .. i) then bossFrameActive = true; break end end
    local inBossEncounter = bossFrameActive and (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    local inCombat = UnitAffectingCombat("player")
    -- ★ 防ADD（2026-11-05 修复）：读正确的按专精变量；菜单 1=开 2=关。
    -- allowAdd=true 表示防ADD关（允许 ADD/起手）。门逻辑：
    --   防ADD开 → 只打已在战斗中的目标 / BOSS；防ADD关 → 战斗中可打任意目标。
    local allowAdd = WR_MageForever_AllowAdd(spec)
    local combatGate = inBossEncounter
        or (inCombat and (allowAdd or WR_UnitInCombat("target")))

    -- ★ 开怪前选怪起手：仅防ADD关(allowAdd=true)时，未进战选中存活敌对目标才提示（不卡距离）
    local startGate = allowAdd
        and (not inCombat)
        and UnitExists("target")
        and UnitCanAttack("player", "target")
        and not UnitIsDead("target")

    if combatGate then
        -- 战斗中按距离严格检查（火球术 35 码）
        local tr = WR_UnitRange("target")
        if tr and tr <= 35 then
            if WR_ColorFrame_ShowSkill("火球术", 5) then return true end
        end
    elseif startGate then
        -- 选怪起手：只要求选中存活敌对目标，不卡距离
        if WR_ColorFrame_ShowSkill("火球术", 5) then return true end
    end
    return false
end

-- ★ 仅清除法师保底火球术的色块（按与 ShowSkill 相同的槽位精确隐藏，
--   不影响焦点/跟随/BOSS 特化/治疗等其它提示框），避免「没选怪还显示火球术」。
-- 槽位解析与 WR_ColorFrame_ShowSkill 一致：WR_SoD_ResolveSlot("火球术") or 5。
function WR_MageForever_HideFireball()
    local slot = (WR_SoD_ResolveSlot and WR_SoD_ResolveSlot("火球术")) or 5
    if ColorFrameArrayTopLeft and ColorFrameArrayTopLeft[slot] then
        ColorFrameArrayTopLeft[slot]:Hide()
    end
    if ColorFrameArrayTopRight and ColorFrameArrayTopRight[slot] then
        ColorFrameArrayTopRight[slot]:Hide()
    end
end

-- ============================================================
-- ★ 诊断命令 /mkmagedbg：排查法师 1 级选怪不提示火球术
--   跑一次把输出发回，可精准定位是「专精分派 / 名字解析 / 可用性判定 / 门禁」哪一步断了。
-- ============================================================
SLASH_MKMAGEDBG1 = "/mkmagedbg"
SlashCmdList["MKMAGEDBG"] = function()
    local function fmt(v) return tostring(v) end
    local spec = WR_GetMyTalent()
    local isForever = WR_Forever_ClientInfo().isForever
    local ridName = WR_ResolveSpellID and WR_ResolveSpellID("火球术")
    local ridNum  = WR_ResolveSpellID and WR_ResolveSpellID(133)
    local suName  = WR_SpellUsable and WR_SpellUsable("火球术")
    local suNum   = WR_SpellUsable and WR_SpellUsable(133)
    local isuName = WR_IsSpellUsableCompat and WR_IsSpellUsableCompat("火球术")
    local isuNum  = WR_IsSpellUsableCompat and WR_IsSpellUsableCompat(133)
    print("|cff00adf0[MKHelperForever 法师诊断]|r")
    print("  spec=" .. fmt(spec) .. "  isForever=" .. fmt(isForever))
    print("  ResolveSpellID: 火球术=" .. fmt(ridName) .. "  133=" .. fmt(ridNum))
    print("  SpellUsable: 火球术=" .. fmt(suName) .. "  133=" .. fmt(suNum))
    print("  IsSpellUsableCompat: 火球术=" .. fmt(isuName) .. "  133=" .. fmt(isuNum))
    local inCombat = UnitAffectingCombat("player")
    print("  targetExists=" .. fmt(UnitExists("target")) .. "  canAttack=" .. fmt(UnitCanAttack("player", "target")) ..
          "  targetDead=" .. fmt(UnitIsDead("target")) .. "  inCombat=" .. fmt(inCombat))
    print("  IsPlayerSpell(133)=" .. fmt(IsPlayerSpell and IsPlayerSpell(133)))
    -- 蓝量辅助判定：IsUsableSpell 的 noMana 第二返回值 + 当前法力，验证「蓝不够不提示」
    local u, nm
    if type(IsUsableSpell) == "function" then
        local ok, a, b = pcall(IsUsableSpell, 133)
        if ok then u, nm = a, b end
    end
    local mana = (type(UnitPower) == "function") and UnitPower("player", 0) or nil
    print("  IsUsableSpell(133): usable=" .. fmt(u) .. "  noMana=" .. fmt(nm) .. "  mana=" .. fmt(mana))
    -- 防ADD 状态（2026-11-05 修复后）：菜单 1=是(开) 2=否(关)；按专精变量不同
    local faddVar = (spec == "火焰") and "FANG_ADD_HUOFA" or (spec == "冰霜") and "FADD_BF" or "AF_FADD"
    local allowAddNow = (PigSet[faddVar] == 2)
    print("  防ADD: var=" .. faddVar .. "  val=" .. fmt(PigSet[faddVar]) .. "  allowAdd(关才true)=" .. fmt(allowAddNow))
    -- 直接跑一次保底，看它进到哪一步、能否点亮
    local handled = false
    if spec == "奥术" then handled = WR_MageForeverArcane() end
    if spec == "火焰" then handled = WR_MageForeverFire() end
    if spec == "冰霜" then handled = WR_MageForeverFrost() end
    local fb = (not handled) and WR_MageForever_FallbackFireball(spec)
    print("  专精循环 handled=" .. fmt(handled) .. "  保底火球术=" .. fmt(fb))
end
