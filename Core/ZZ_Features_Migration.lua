-- ============================================================
-- ZZ_Features_Migration.lua
-- 从 ZZHELPER_TITAN 迁移的功能模块
-- 包含：DBM倒计时、预开药水、职业颜色、FocusCast、
--       Boss阶段配置、CVar锁定、怪物屏蔽系统
-- ============================================================

-- ============================================================
-- ★ 1. DBM 倒计时系统
-- ============================================================

-- ★ 切换提示信息输出（统一供下拉菜单/复选框切换调用，与6冰触提示方式一致）
--    ChatNoticeMode：0=关闭 1=默认窗口 2=所有可见窗口
--    （文件级定义，上移至此以便文件前部的怪物屏蔽总开关等也能捕获）
local function PrintToVisible(msg)
    -- ★★ 2026-11-11：屏幕文字提示总闸（默认关闭）。关闭时聊天框切换提示也不输出。
    -- 兼容：总闸函数未定义时按「关闭」处理，避免加载顺序异常导致报错。
    if type(WR_ScreenTextNoticeEnabled) ~= "function"
        or not WR_ScreenTextNoticeEnabled() then return end
    local mode = PigSet["ChatNoticeMode"]
    if mode == 0 then return end
    if mode == 1 then print(msg); return end
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame"..i]
        if cf and cf:IsVisible() then cf:AddMessage(msg) end
    end
end

-- ★ 怪物屏蔽总开关统一设置（复选框 OnClick 与 /monster 命令共用，所有职业可用）
--    ZZ_MonsterBlockMasterChk：主控复选框引用（现为左侧全局面板内的"启用怪物屏蔽"框，由 Core/UI_Config.lua 赋值；
--        改为全局变量，使 ZZ_SetMonsterBlock 与 /monster 命令可跨文件同步其勾选态）
ZZ_MonsterBlockMasterChk = nil
function ZZ_SetMonsterBlock(enabled)
    PigSet.MONSTER_BLOCK_ENABLED = enabled and true or false
    if ZZ_MonsterBlockMasterChk and ZZ_MonsterBlockMasterChk.SetChecked then
        ZZ_MonsterBlockMasterChk:SetChecked(PigSet.MONSTER_BLOCK_ENABLED)
    end
    local status = PigSet.MONSTER_BLOCK_ENABLED and "|cff00ff00启用|r" or "|cffff0000关闭|r"
    PrintToVisible(string.format("|cff00adf0[怪物屏蔽]|r 怪物屏蔽总开关: %s", status))
end

local dbmPullEndTime = 0
local dbmPullFrame = CreateFrame("Frame")
dbmPullFrame:RegisterEvent("START_PLAYER_COUNTDOWN")
dbmPullFrame:RegisterEvent("CANCEL_PLAYER_COUNTDOWN")
dbmPullFrame:SetScript("OnEvent", function(_, event, _, timeSeconds)
    if event == "START_PLAYER_COUNTDOWN" then
        timeSeconds = tonumber(timeSeconds) or 0
        dbmPullEndTime = timeSeconds > 0 and (GetTime() + timeSeconds) or 0
    else
        dbmPullEndTime = 0
    end
end)

function GetPullCountdownRemaining()
    if dbmPullEndTime <= 0 then
        return 0
    end
    local remaining = dbmPullEndTime - GetTime()
    if remaining <= 0 then
        dbmPullEndTime = 0
        return 0
    end
    return remaining
end

function IsPullCountdownActive(maxSeconds)
    maxSeconds = tonumber(maxSeconds) or 0
    if maxSeconds <= 0 or UnitAffectingCombat("player") then
        return false
    end
    local pullTime = GetPullCountdownRemaining()
    return pullTime > 0 and pullTime < maxSeconds
end

function WR_GetDBMCountdown_EM()
    if DBM and DBM.GetCountdown then
        local _, timeLeft = DBM:GetCountdown()
        if timeLeft and timeLeft > 0 then
            return timeLeft
        end
    end
    return GetPullCountdownRemaining()
end

-- ★ 偷药/爆发预开窗口（DBM倒数秒数阈值，0-3 秒可调，默认3）
--   全职业统一：返回当前 DBM 倒数是否落在预开窗口内
function WR_PrepullInWindow(dbmCountdown)
    local t = PigSet["TOUYAO_TIME"]
    if type(t) ~= "number" then t = 3 end
    if t < 0 then t = 0 end
    if t > 3 then t = 3 end
    return dbmCountdown > 0 and dbmCountdown <= t
end

-- ============================================================
-- ★ 2. 预开药水逻辑
-- ============================================================
function TryPrePullPotion(enabled, itemID, colorIndex, label, excludeStealth)
    if not PigSet or not PigSet["DBM_PREPULL_POTION"] then
        return false
    end
    if not enabled or UnitAffectingCombat("player") or not yaoshuicd then
        return false
    end
    if excludeStealth and GetBuffTime("player", "潜行") > 0 then
        return false
    end
    local pullTime = GetPullCountdownRemaining()
    if pullTime <= 0 or pullTime > 1 then
        return false
    end
    if not CanUseItem(itemID) then
        return false
    end
    return WR_ColorFrame_Show(colorIndex, label) or false
end

function TryPrePullSpeedPotion(speedEnabled, wildMagicEnabled)
    if TryPrePullPotion(speedEnabled, 40211, 183, "Pull倒计时速度药水") then
        return true
    end
    if TryPrePullPotion(wildMagicEnabled, 40212, 184, "Pull倒计时狂野魔法药水") then
        return true
    end
    if TryPrePullPotion(wildMagicEnabled, 20007, 184, "Pull倒计时狂野魔法药水") then
        return true
    end
    return false
end

-- ============================================================
-- ★ 3. 职业颜色函数
-- ============================================================
function ZZ_ClassesColor(Unit)
    local unitClass = UnitClassBase(Unit)
    if unitClass == "WARRIOR" then
        return "|cffC79C6E"
    elseif unitClass == "MAGE" then
        return "|cff40C7EB"
    elseif unitClass == "HUNTER" then
        return "|cffA9D271"
    elseif unitClass == "ROGUE" then
        return "|cffFFF569"
    elseif unitClass == "SHAMAN" then
        return "|cff0070DE"
    elseif unitClass == "EVOKER" then
        return "|cff33937F"
    elseif unitClass == "WARLOCK" then
        return "|cff8787ED"
    elseif unitClass == "DEATHKNIGHT" then
        return "|cffC41F3B"
    elseif unitClass == "PRIEST" then
        return "|cffFFFFFF"
    elseif unitClass == "MONK" then
        return "|cff00FF96"
    elseif unitClass == "PALADIN" then
        return "|cffF58CBA"
    elseif unitClass == "DRUID" then
        return "|cffFF7D0A"
    elseif unitClass == "DEMONHUNTER" then
        return "|cffA330C9"
    end
    return ""
end

-- ============================================================
-- ★ 4. FocusCast 焦点施法系统
-- ============================================================
if not ZZ_FocusCast_Info then
    ZZ_FocusCast_Info = {}
end

function SetFocusCastInfo(Unit, Button, Spell, Text)
    if Unit and Button and Spell and Text then
        ZZ_FocusCast_Info.active = true
        ZZ_FocusCast_Info.unit = Unit
        ZZ_FocusCast_Info.button = Button
        ZZ_FocusCast_Info.spell = Spell
        ZZ_FocusCast_Info.text = Text
        ZZ_FocusCast_Info.time = GetTime()
    end
    if not ZZ_FocusCast_EventFrame then
        ZZ_FocusCast_EventFrame = true
        local frame = CreateFrame("Frame")
        WR_RegisterEventSafe(frame, "COMBAT_LOG_EVENT_UNFILTERED")
        frame:SetScript("OnEvent", function()
            if not ZZ_FocusCast_Info.active then return end
            local timestamp, subevent, _, sourceGUID, _, _, _, _, _, _, _, _, spellName = unpack(WR_CombatLogEvent)
            if (subevent == "SPELL_CAST_SUCCESS" or subevent == "SPELL_CAST_START") and
               sourceGUID == UnitGUID("player") and spellName == ZZ_FocusCast_Info.spell then
                ZZ_FocusCast_Info.active = false
            end
        end)
    end
    if ZZ_FocusCast_Info.active then
        if GetTime() - ZZ_FocusCast_Info.time <= (GCD and math.max(GCD, 0.1) or 0.1) then
            if UnitIsUnit(ZZ_FocusCast_Info.unit, "focus") then
                if WR_ColorFrame_Show(ZZ_FocusCast_Info.button, ZZ_FocusCast_Info.text .. "\n" .. ZZ_FocusCast_Info.unit) then
                    return true
                end
            else
                if ShowFocusHealthFrame(ZZ_FocusCast_Info.unit, ZZ_FocusCast_Info.text) then
                    return true
                end
            end
        else
            ZZ_FocusCast_Info.active = false
        end
    end
    return false
end

-- ============================================================
-- ★ 5. Boss 阶段配置表（怪物屏蔽系统）
-- ============================================================
PigSet = PigSet or {}
-- ★ 怪物屏蔽系统迁移（原 WCL 冲分模式已并入怪物屏蔽，见 IsMonsterBlocked / TARGET_BLOCKED / AOE_EXCLUDED）
-- MONSTER_BLOCK_ENABLED: 怪物屏蔽总开关（布尔）
-- 默认关闭（用户要求"默认不启用"）。旧版以 WCL_MODE 数字 1（冲分模式）或布尔 true（旧怪物屏蔽总开关）开启的，
-- 迁移为开启怪物屏蔽，保留"不打不计分单位"的行为；其余（全新用户/旧版正常模式）默认关闭。
if PigSet.MONSTER_BLOCK_ENABLED == nil then
    if PigSet.WCL_MODE == true or PigSet.WCL_MODE == 1 then
        PigSet.MONSTER_BLOCK_ENABLED = true   -- 旧版冲分/旧怪物屏蔽，保留开启
    else
        PigSet.MONSTER_BLOCK_ENABLED = false  -- 默认不启用
    end
end
-- 清理已废弃的 WCL_MODE 字段（功能已并入怪物屏蔽系统）
PigSet.WCL_MODE = nil
-- 清理已删除的防骑「自动保持圣洁护盾」(FH_SJHD) 旧存档字段（菜单开关与斜杠命令均已移除）
PigSet.FH_SJHD = nil
-- 清理已删除的防骑「单体循环」(FH_DT) 旧存档字段（2026-11-11 用户要求删除，改为「十字军审判」buff 维持）
PigSet.FH_DT = nil
-- 清理已删除的「全局区-AOE」两个开关旧存档字段（2026-11-11 用户要求删除全局区 AOE 功能与选项）
PigSet.WR_GLOBAL_SMART_AOE = nil
PigSet.WR_GLOBAL_MANUAL_AOE = nil
-- 清理已删除的防骑「自动正义之锤」(FH_ZYZC) 旧存档字段（菜单开关与斜杠命令均已移除）
PigSet.FH_ZYZC = nil
-- 清理已删除的防骑「插入复仇者之盾」(FH_CRFD) 旧存档字段（菜单开关与斜杠命令均已移除）
PigSet.FH_CRFD = nil
-- 清理已删除的防骑「自动保持庇护祝福 / 强效庇护祝福」旧存档字段
PigSet.FH_BHZF = nil
PigSet.FH_WZYJ = nil
-- 清理已删除的「审判」细分下拉（技能改版：不再区分圣光/智慧/公正审判）
PigSet.CJ_SP = nil
PigSet.FH_SP = nil
PigSet.SS_SP = nil
-- 清理已删除的「神圣恳求」（本服无此技能，三系相关功能全部移除）
PigSet.FH_CRSSKQ = nil
PigSet.SS_SSKQ = nil
PigSet.SS_SSKQ_MP = nil
-- 清理旧版「圣印」下拉框字段（旧 CJ_SY/FH_SY/SS_SY；三系各自的旧下拉）
PigSet.CJ_SY = nil
PigSet.FH_SY = nil
PigSet.SS_SY = nil
-- ★★ 2026-11-11：防护「圣印」改为「圣印」专区按钮（FH_SEAL 六项，默认 3=愤怒圣印）
--   旧存档迁移：FH_GMSY=true → 4（光明·回血）；否则 FH_ZYSY=true → 2（正义）；否则 3。
--   已有显式 FH_SEAL 时不被旧开关覆盖；迁移只执行一次（FH_SEAL_MIGRATED 标记）。
if not PigSet.FH_SEAL_MIGRATED then
    if PigSet.FH_SEAL == nil then
        if PigSet.FH_GMSY == true then
            PigSet.FH_SEAL = 4
        elseif PigSet.FH_ZYSY == true then
            PigSet.FH_SEAL = 2
        else
            PigSet.FH_SEAL = 3
        end
    end
    PigSet.FH_SEAL_MIGRATED = true
end
PigSet.FH_GMSY = nil
PigSet.FH_ZYSY = nil

-- ★ 防骑祝福下拉索引迁移（2026-11-06：删除「庇护/强效庇护」两项，9 项 → 7 项）
--   旧: 1力量 2智慧 3王者 4庇护 5强效力量 6强效智慧 7强效王者 8强效庇护 9禁用
--   新: 1力量 2智慧 3王者 4强效力量 5强效智慧 6强效王者 7禁用
--   新旧值域重叠(1-7)，必须一次性执行，用 FH_ZF_V2 标记防重复映射。
--   旧 4/8（庇护类）与旧 9（禁用）统一回落到 7（禁用）。
if not PigSet.FH_ZF_V2 then
    local _oldFHZF = tonumber(PigSet.FH_ZF)
    local _fhZFMap = { [1]=1, [2]=2, [3]=3, [4]=7, [5]=4, [6]=5, [7]=6, [8]=7, [9]=7 }
    PigSet.FH_ZF = _fhZFMap[_oldFHZF] or 7
    PigSet.FH_ZF_V2 = true
end
if PigSet.DBM_PREPULL_POTION == nil then
    PigSet.DBM_PREPULL_POTION = false
end

-- ============================================================
-- ★ BOSS 机制应对开关（WQZ_ 前缀）
-- 命名规范: WQZ_ + BOSS拼音缩写 + _ + 机制缩写
-- 布尔开关: true=启用(默认), false=关闭
-- 数值阈值: 数字(如刺骨层数)
-- ============================================================

-- ★ ICC - 辛达苟萨 (XDG)
if PigSet.WQZ_XDG_HSCG_FX == nil then PigSet.WQZ_XDG_HSCG_FX = 3 end     -- 法系刺骨停读条阈值
if PigSet.WQZ_XDG_HSCG == nil then PigSet.WQZ_XDG_HSCG = 5 end            -- 物理刺骨停手阈值
if PigSet.WQZ_XDG_BF == nil then PigSet.WQZ_XDG_BF = true end             -- 冰封停手
if PigSet.WQZ_XDG_KZ == nil then PigSet.WQZ_XDG_KZ = true end             -- 狂咒停手(治疗+法系)
if PigSet.WQZ_XDG_TX == nil then PigSet.WQZ_XDG_TX = true end             -- 冰冷吐息坦克减伤
if PigSet.WQZ_XDG_FJ == nil then PigSet.WQZ_XDG_FJ = true end             -- 反魔法护盾法系停手
if PigSet.WQZ_XDG_BZ == nil then PigSet.WQZ_XDG_BZ = true end             -- 冰霜炸弹走位

-- ★ ICC - 玛尔加隆 (MEJL)
if PigSet.WQZ_MEJL_CS == nil then PigSet.WQZ_MEJL_CS = true end           -- 骨刺转火
if PigSet.WQZ_MEJL_GF == nil then PigSet.WQZ_MEJL_GF = true end           -- 骨风暴近战停手+坦克减伤
if PigSet.WQZ_MEJL_LY == nil then PigSet.WQZ_MEJL_LY = true end           -- 冷焰走位

-- ★ ICC - 亡语女士 (WY)
if PigSet.WQZ_WY_MBYZ == nil then PigSet.WQZ_WY_MBYZ = true end           -- 麻痹诅咒停手
if PigSet.WQZ_WY_GZ == nil then PigSet.WQZ_WY_GZ = true end               -- 免疫小怪过滤(玄秘/狂热/追随者)

-- ★ ICC - 萨鲁法尔 (SLFE)
if PigSet.WQZ_SLFE_XS == nil then PigSet.WQZ_SLFE_XS = true end           -- 血兽转火提示
if PigSet.WQZ_SLFE_BH == nil then PigSet.WQZ_SLFE_BH = true end           -- 保护之手取消(物理)

-- ★ ICC - 烂肠 (LC)
if PigSet.WQZ_LC_BY == nil then PigSet.WQZ_LC_BY = true end               -- 突变停读条/跑位
if PigSet.WQZ_LC_DQ == nil then PigSet.WQZ_LC_DQ = true end               -- 毒气坦克减伤

-- ★ ICC - 腐面 (FM)
if PigSet.WQZ_FM_BY == nil then PigSet.WQZ_FM_BY = true end               -- 突变停读条/跑位

-- ★ ICC - 血议会 (XYH)
if PigSet.WQZ_XYH_HAZ == nil then PigSet.WQZ_XYH_HAZ = true end           -- 黑暗之核过滤
if PigSet.WQZ_XYH_DLB == nil then PigSet.WQZ_XYH_DLB = true end           -- 动力炸弹过滤
if PigSet.WQZ_XYH_QM == nil then PigSet.WQZ_XYH_QM = true end             -- 三王子切目标

-- ★ ICC - 普崔塞德教授 (PTC)
if PigSet.WQZ_PTC_RN == nil then PigSet.WQZ_PTC_RN = true end             -- 软泥怪过滤
if PigSet.WQZ_PTC_CL == nil then PigSet.WQZ_PTC_CL = true end             -- 催泪毒气停手

-- ★ ICC - 鲜血女王 (XN)
if PigSet.WQZ_XN_XJ == nil then PigSet.WQZ_XN_XJ = true end               -- 鲜血镜像停手

-- ★ ICC - 炮舰 (PJ)
if PigSet.WQZ_PJ_HJ == nil then PigSet.WQZ_PJ_HJ = true end               -- 火箭靴逃生

-- ★ ICC - 翡翠巨龙 (FCJL)
if PigSet.WQZ_FCJL_RZ == nil then PigSet.WQZ_FCJL_RZ = true end           -- 燃烧之血停手(法系)
if PigSet.WQZ_FCJL_CZ == nil then PigSet.WQZ_FCJL_CZ = true end           -- 沉睡停手

-- ★ ICC - 灵魂熔炉 (LRRG)
if PigSet.WQZ_LRRG_LDRY == nil then PigSet.WQZ_LRRG_LDRY = true end       -- 灵魂倒映停手
if PigSet.WQZ_LRRG_JX == nil then PigSet.WQZ_LRRG_JX = true end           -- 镜像过滤

-- ★ ICC - 巫妖王 (LK)
if PigSet.WQZ_LK_PW == nil then PigSet.WQZ_LK_PW = true end               -- 污染跑位(全角色)

-- ★ TOC - 加拉克苏斯大王 (JLKS)
if PigSet.WQZ_JLKS_RZ == nil then PigSet.WQZ_JLKS_RZ = true end           -- 燃烧之血停手
if PigSet.WQZ_JLKS_CM == nil then PigSet.WQZ_JLKS_CM = true end           -- 传送门/火山过滤

-- ★ TOC - 阵营冠军 (ZYJ)
if PigSet.WQZ_ZYJ_KZ == nil then PigSet.WQZ_ZYJ_KZ = true end             -- 被控制停手

-- ★ TOC - 瓦格里双子 (WGL)
if PigSet.WQZ_WGL_TZ == nil then PigSet.WQZ_WGL_TZ = true end             -- 暗影/光明之痛停手

-- ★ TOC - 阿努巴拉克 (ANB)
if PigSet.WQZ_ANB_TG == nil then PigSet.WQZ_ANB_TG = true end             -- 透骨之寒跑位
if PigSet.WQZ_ANB_XG == nil then PigSet.WQZ_ANB_XG = true end             -- 小怪过滤

-- ★ ULD - 奥尔加隆 (EJG)
if PigSet.WQZ_EJG_YZ == nil then PigSet.WQZ_EJG_YZ = true end             -- 宇宙撞击/坍缩之星停手

-- ★ ULD - 尤格萨隆 (YGS)
if PigSet.WQZ_YGS_XL == nil then PigSet.WQZ_YGS_XL = true end             -- 心灵牢笼/精神控制停手
if PigSet.WQZ_YGS_CS == nil then PigSet.WQZ_YGS_CS = true end             -- 触手过滤

-- ★ ULD - 霍迪尔 (HDE)
if PigSet.WQZ_HDE_BD == nil then PigSet.WQZ_HDE_BD = true end             -- 冰冻停手+坦克减伤

-- ★ ULD - 弗蕾亚 (FLY)
if PigSet.WQZ_FLY_GS == nil then PigSet.WQZ_FLY_GS = true end             -- 古树三老过滤
if PigSet.WQZ_FLY_YG == nil then PigSet.WQZ_FLY_YG = true end             -- 阳光走位

-- ★ ULD - 维扎克斯将军 (WZKS)
if PigSet.WQZ_WZKS_AY == nil then PigSet.WQZ_WZKS_AY = true end           -- 暗影狂暴停手
if PigSet.WQZ_WZKS_JT == nil then PigSet.WQZ_WZKS_JT = true end           -- 萨隆邪铁畸体过滤

-- ★ ULD - 钢铁议会 (GTGH)
if PigSet.WQZ_GTGH_FX == nil then PigSet.WQZ_GTGH_FX = true end           -- 符文大师法系过滤
if PigSet.WQZ_GTGH_ZH == nil then PigSet.WQZ_GTGH_ZH = true end           -- 召唤者莫林物理过滤
if PigSet.WQZ_GTGH_CF == nil then PigSet.WQZ_GTGH_CF = true end           -- 超负荷停手

-- ★ ULD - 科隆加恩 (KLJE)
if PigSet.WQZ_KLJE_SS == nil then PigSet.WQZ_KLJE_SS = true end           -- 碎石过滤
if PigSet.WQZ_KLJE_SX == nil then PigSet.WQZ_KLJE_SX = true end           -- 石印视线走位

-- ★ Naxx - 憎恶缝合者 (ESFZ)
if PigSet.WQZ_ESFZ_CH == nil then PigSet.WQZ_ESFZ_CH = true end           -- 仇恨打击减伤(坦克)

-- ★ Naxx - 克尔苏加德 (KLSJD)
if PigSet.WQZ_KLSJD_XL == nil then PigSet.WQZ_KLSJD_XL = true end         -- 心灵狂乱停手
if PigSet.WQZ_KLSJD_AL == nil then PigSet.WQZ_KLSJD_AL = true end         -- 暗影裂隙走位

-- ★ Naxx - 四骑士 (SQS)
if PigSet.WQZ_SQS_YJ == nil then PigSet.WQZ_SQS_YJ = true end             -- 印记减伤(坦克)

-- ★ Naxx - 海根 (HGN)
if PigSet.WQZ_HGN_WY == nil then PigSet.WQZ_HGN_WY = true end             -- 瘟疫停手

-- ★ Naxx - 戈提克 (GTK)
if PigSet.WQZ_GTK_XG == nil then PigSet.WQZ_GTK_XG = true end             -- 小怪过滤

-- ★ 太阳井 - 卡雷苟斯 (KLGS)
if PigSet.WQZ_KLGS_HM == nil then PigSet.WQZ_KLGS_HM = true end           -- 黑暗之门停手
if PigSet.WQZ_KLGS_FS == nil then PigSet.WQZ_KLGS_FS = true end           -- 腐蚀/燃烧走位

-- ★ 太阳井 - 布鲁塔卢斯 (BLTL)
if PigSet.WQZ_BLTL_XS == nil then PigSet.WQZ_BLTL_XS = true end           -- 陨石打击近战停手+坦克减伤
if PigSet.WQZ_BLTL_RZ == nil then PigSet.WQZ_BLTL_RZ = true end           -- 燃烧之血走位

-- ★ 太阳井 - 艾瑞达双子 (ARD)
if PigSet.WQZ_ARD_ZT == nil then PigSet.WQZ_ARD_ZT = true end             -- 暗影/火焰之痛停手
if PigSet.WQZ_ARD_JX == nil then PigSet.WQZ_ARD_JX = true end             -- 镜像过滤

-- ★ 太阳井 - 穆鲁 (ML)
if PigSet.WQZ_ML_XK == nil then PigSet.WQZ_ML_XK = true end               -- 虚空哨兵过滤
if PigSet.WQZ_ML_S == nil then PigSet.WQZ_ML_S = true end                 -- 熵debuff法系停手

-- ★ 太阳井 - 基尔加丹 (JED)
if PigSet.WQZ_JED_QH == nil then PigSet.WQZ_JED_QH = true end             -- 千魂停手
if PigSet.WQZ_JED_AL == nil then PigSet.WQZ_JED_AL = true end             -- 暗影之矛/炽焰弹幕停手

-- ★ 祖阿曼 - 鹰王 (YW)
if PigSet.WQZ_YW_DQ == nil then PigSet.WQZ_YW_DQ = true end               -- 电气风暴集合

-- ★ 祖阿曼 - 豹王 (BW)
if PigSet.WQZ_BW_SB == nil then PigSet.WQZ_BW_SB = true end               -- 闪避近战停手
if PigSet.WQZ_BW_TT == nil then PigSet.WQZ_BW_TT = true end               -- 图腾过滤

-- ★ 祖阿曼 - 熊王 (XW)
if PigSet.WQZ_XW_CF == nil then PigSet.WQZ_XW_CF = true end               -- 冲锋近战停手
if PigSet.WQZ_XW_BX == nil then PigSet.WQZ_XW_BX = true end               -- 熊形态远程注意

-- ★ 祖阿曼 - 龙鹰王 (LHY)
if PigSet.WQZ_LHY_HY == nil then PigSet.WQZ_LHY_HY = true end             -- 火焰新星停手
if PigSet.WQZ_LHY_XY == nil then PigSet.WQZ_LHY_XY = true end             -- 小龙鹰过滤

-- ★ 祖阿曼 - 妖术领主 (YSLZ)
if PigSet.WQZ_YSLZ_YZ == nil then PigSet.WQZ_YSLZ_YZ = true end           -- 妖术停手

-- ★ 祖阿曼 - 祖金 (ZJ)
if PigSet.WQZ_ZJ_D == nil then PigSet.WQZ_ZJ_D = true end                 -- 毒debuff走位
-- ★ 祖尔格拉布 - 哈卡 (HK)
if PigSet.WQZ_HK_XC == nil then PigSet.WQZ_HK_XC = true end               -- 鲜血虹吸停手
if PigSet.WQZ_HK_XL == nil then PigSet.WQZ_HK_XL = true end               -- 心灵控制停手
if PigSet.WQZ_HK_XZ == nil then PigSet.WQZ_HK_XZ = true end               -- 哈卡之子过滤

-- ★ 祖尔格拉布 - 金度 (JD)
if PigSet.WQZ_JD_YZ == nil then PigSet.WQZ_JD_YZ = true end               -- 妖术停手
if PigSet.WQZ_JD_YL == nil then PigSet.WQZ_JD_YL = true end               -- 幽灵过滤

-- ★ 祖尔格拉布 - 血领主 (XLZ)
if PigSet.WQZ_XLZ_NS == nil then PigSet.WQZ_XLZ_NS = true end             -- 凝视停手

-- ★ 祖尔格拉布 - 祭司泰卡尔 (JSKE)
if PigSet.WQZ_JSKE_BX == nil then PigSet.WQZ_JSKE_BX = true end           -- 豹形态停手
if PigSet.WQZ_JSKE_XG == nil then PigSet.WQZ_JSKE_XG = true end           -- 复活小怪过滤

-- ★ 红玉圣殿 - 海里昂 (HLA)
if PigSet.WQZ_HLA_YZ == nil then PigSet.WQZ_HLA_YZ = true end                 -- 陨石跑位(法系)

-- ★ 五治疗过量停条窗口统一配置（默认关闭，窗口值5=0.5秒）
-- SS_GLTC/SS_GLTCCK：奶骑+神牧（共用SS_前缀）
-- HF_GLTC/HF_GLTCCK：奶萨+奶德（共用HF_前缀）
-- JL_GLTC/JL_GLTCCK：戒律牧（独立JL_前缀）
if PigSet.SS_GLTC == nil then PigSet.SS_GLTC = false end
if PigSet.SS_GLTCCK == nil then PigSet.SS_GLTCCK = 5 end
if PigSet.HF_GLTC == nil then PigSet.HF_GLTC = false end
if PigSet.HF_GLTCCK == nil then PigSet.HF_GLTCCK = 5 end
if PigSet.JL_GLTC == nil then PigSet.JL_GLTC = false end
if PigSet.JL_GLTCCK == nil then PigSet.JL_GLTCCK = 5 end

-- ★ 猎人三系输出模式变量迁移（2项：1=单体/2=AOE）
-- 迁移原因：菜单从3项(单体/AOE1/AOE2)缩减为2项(单体/AOE)
--   旧版3=AOE2 → 新版2=AOE
--   旧版2=AOE1 → 新版2=AOE（AOE1已移除，归入AOE）
--   旧版1=单体 → 新版1=单体（不变）
-- 同时清理布尔值/nil/非数字污染（防止 mode==2 比较失败）
for _, _cycleVar in ipairs({"LR_SWL_CYCLE_MODE", "LR_SJL_CYCLE_MODE", "LR_SCL_CYCLE_MODE"}) do
    local _v = PigSet[_cycleVar]
    if _v == true or _v == false or _v == nil or type(_v) ~= "number" then
        PigSet[_cycleVar] = 1
    elseif _v == 3 then
        PigSet[_cycleVar] = 2  -- 旧版AOE2 → 新版AOE
    elseif _v > 2 or _v < 1 then
        PigSet[_cycleVar] = 1
    end
end

-- ★ 猎人三系宝宝攻击模式迁移（复选框布尔值 → 下拉菜单数字：1=跟随/2=不跟随/3=不控制）
for _, _petModeVar in ipairs({"LR_SWL_KZBB", "LR_SJL_KZBB", "LR_SCL_KZBB"}) do
    local _v = PigSet[_petModeVar]
    if _v == true then
        PigSet[_petModeVar] = 1  -- 旧版开启 → 跟随
    elseif _v == false then
        PigSet[_petModeVar] = 3  -- 旧版关闭 → 不控制
    elseif _v == nil or type(_v) ~= "number" or _v < 1 or _v > 3 then
        PigSet[_petModeVar] = 1  -- 默认跟随
    end
end

-- ★ 术士三系武器石迁移（复选框布尔值 → 下拉菜单数字：1=关闭/2=法术石[副手]/3=火焰石[主手]）
--   旧版 true(已勾选) → 默认石种（痛苦/恶魔学识为法术石=2，毁灭为火焰石=3）
--   旧版 false(未勾选) → 关闭(1)
local _wlStoneDef = { WL_AFL_ZDFSS = 2, WL_EM_ZDFSS = 2, SS_HM_HRS = 3 }
for _stoneVar, _defStone in pairs(_wlStoneDef) do
    local _v = PigSet[_stoneVar]
    if _v == true then
        PigSet[_stoneVar] = _defStone
    elseif _v == false then
        PigSet[_stoneVar] = 1  -- 关闭
    elseif _v == nil or type(_v) ~= "number" or _v < 1 or _v > 3 then
        PigSet[_stoneVar] = _defStone
    end
end

-- ★ 惩戒骑清洁术变量迁移（CJ_QJS 从复选框布尔值改为下拉菜单数字）
-- 迁移原因：清洁术从复选框改为下拉菜单（5模式：常规/优先/目标/指向/禁用）
--   旧版 true(已勾选) → 新版 1(常规)
--   旧版 false(未勾选) → 新版 5(禁用)
if PigSet.CJ_QJS == true then PigSet.CJ_QJS = 1 end
if PigSet.CJ_QJS == false or PigSet.CJ_QJS == nil then PigSet.CJ_QJS = 5 end
if type(PigSet.CJ_QJS) ~= "number" or PigSet.CJ_QJS < 1 or PigSet.CJ_QJS > 5 then
    PigSet.CJ_QJS = 5
end
-- 惩戒骑全局清洁术复选框变量重命名: CJ_QJS → CJ_QJS_QJ
if PigSet.CJ_QJS_QJ == nil then
    if PigSet.CJ_QJS_QJ == nil then PigSet.CJ_QJS_QJ = true end
end

-- ★ 防护骑清洁术变量初始化（FH_QJS 下拉菜单默认值）
if PigSet.FH_QJS == nil then PigSet.FH_QJS = 5 end
-- ★ 防护骑清洁术 自己/目标 复选框恢复（与下拉 FH_QJS 并存）
-- 旧版被下拉菜单完全替代删除，现恢复为独立开关；默认开启以还原旧行为
if PigSet.FH_QJS_Player == nil then PigSet.FH_QJS_Player = true end
if PigSet.FH_QJS_Target == nil then PigSet.FH_QJS_Target = true end
-- ★ 防护骑指向保护/牺牲（2026-08-09 新增）
if PigSet.FH_ZZBH == nil then PigSet.FH_ZZBH = false end        -- 指向保护之手总开关（默认关）
if PigSet.FH_ZZXS == nil then PigSet.FH_ZZXS = false end        -- 指向牺牲之手总开关（默认关）
if PigSet.FH_ZZBH_HP == nil then PigSet.FH_ZZBH_HP = 4 end     -- 团血阈值（4=禁用）
-- ★ 2026-11-06：已删除的防骑下拉（制裁之锤/团本循环/全局牺牲）
PigSet.FH_ZCZC = nil
PigSet.FH_RAID_MODE = nil
PigSet.FH_ZZXS_HP = nil
-- 惩戒/神圣「制裁之锤」下拉已隐藏（注释保留在 Menu/CommandList）
PigSet.CJ_ZCZC = nil
PigSet.SS_ZCZC = nil
-- 已删除：防护「循环模式/循环模板」下拉框
PigSet.FH_PRIORITY_MODE = nil
if PigSet.FH_ZZJZ == nil then PigSet.FH_ZZJZ = false end        -- 指向拯救之手总开关（默认关）

-- ★ 战士自动缴械开关（2026-08-12 构建项，10 防战缴械 / 15·22 武器战强化缴械合并）
-- B 更新日志计划新增"自动缴械/强化缴械"，B 源码无对应实现，按 WotLK 机制构建。
-- 触发条件：目标为可缴械的敌对近战/人型（WotLK 仅对人型/ beasts 等可缴械，亡灵/元素/机械不可）
--   且当前处于爆发列表目标（boss/精英）或玩家开启的手动触发场景；自动缴械在爆发期/斩杀期择机释放。
if PigSet.FZ_JF == nil then PigSet.FZ_JF = false end             -- 防战自动缴械（默认关）
if PigSet.WQZ_JF == nil then PigSet.WQZ_JF = false end           -- 武器战自动缴械/强化缴械（默认关）

local PHASES = {
    {
        key = "P1",
        title = "P1 MC",
        tabWidth = 72,
        raids = {
            { name = "熔火之心", first = "鲁西弗隆" }
        },
        bosses = {
            { name = "鲁西弗隆", mobs = {"烈焰行者护卫"} },
            { name = "玛格曼达", mobs = {} },
            { name = "基赫纳斯", mobs = {"烈焰行者"} },
            { name = "加尔", mobs = {"火誓者"} },
            { name = "沙斯拉尔", mobs = {} },
            { name = "迦顿男爵", mobs = {} },
            { name = "萨弗隆先驱者", mobs = {"烈焰行者祭司"} },
            { name = "焚化者古雷曼格", mobs = {"熔火怒犬"} },
            { name = "管理者埃克索图斯", mobs = {"烈焰行者医师", "烈焰行者精英"} },
            { name = "拉格纳罗斯", mobs = {"烈焰之子"} },
        },
    },
    {
        key = "P2",
        title = "P2 SSC/TK",
        tabWidth = 88,
        raids = {
            { name = "毒蛇神殿", first = "不稳定的海度斯" },
            { name = "风暴要塞", first = "奥" },
        },
        bosses = {
            { name = "不稳定的海度斯", mobs = {"纯净的海度斯爪牙", "被污染的海度斯爪牙"} },
            { name = "鱼斯拉", mobs = {"盘牙伏击者", "盘牙守护者"} },
            { name = "盲眼者莱欧瑟拉斯", mobs = {"内心之魔", "莱欧瑟拉斯之影"} },
            { name = "深水领主卡拉瑟雷斯", mobs = {"溅火图腾"} },
            { name = "莫洛格里·踏潮者", mobs = {"水泡", "鱼人潮行者"} },
            { name = "瓦丝琪", mobs = {"被污染的元素", "被污染的水元素", "盘牙精英", "盘牙巡逻者", "剧毒孢子蝠"} },
            { name = "奥", mobs = {"奥的灰烬"} },
            { name = "空灵机甲", mobs = {} },
            { name = "大星术师索兰莉安", mobs = {"日晷祭司", "日晷密探"} },
            { name = "凯尔萨斯·逐日者", mobs = {"灵弦长弓", "毁灭", "宇宙灌注者", "无尽之刃", "迁跃切割者", "相位壁垒", "瓦解法杖", "凤凰", "凤凰卵"} },
        },
    },
    {
        key = "P3",
        title = "P3 NAXX/OS/EOE",
        tabWidth = 122,
        raids = {
            { name = "纳克萨玛斯", first = "阿努布雷坎" },
            { name = "黑曜石圣所", first = "萨塔里奥" },
            { name = "永恒之眼", first = "玛里苟斯" },
        },
        bosses = {
            { name = "阿努布雷坎", mobs = {"地穴卫士", "尸甲虫"} },
            { name = "黑女巫法琳娜", mobs = {"纳克萨玛斯追随者", "纳克萨玛斯膜拜者"} },
            { name = "迈克斯纳", mobs = {"迈克斯纳的小蜘蛛"} },
            { name = "瘟疫使者诺斯", mobs = {"天灾卫士", "染疫勇士", "染疫战士"} },
            { name = "肮脏的希尔盖", mobs = {} },
            { name = "洛欧塞布", mobs = {"孢子"} },
            { name = "帕奇维克", mobs = {} },
            { name = "格罗布鲁斯", mobs = {"辐射软泥怪"} },
            { name = "格拉斯", mobs = {"僵尸食尸鬼"} },
            { name = "塔迪乌斯", mobs = {"斯塔拉格", "费尔根"} },
            { name = "教官拉苏维奥斯", mobs = {"死亡骑士学员"} },
            { name = "收割者戈提克", mobs = {"无情的学徒", "无情的死亡骑士", "无情的骑兵", "鬼灵学徒", "鬼灵死亡骑士", "鬼灵战马", "鬼灵骑兵"} },
            { name = "天启四骑士", mobs = {"大领主莫格莱尼", "库尔塔兹领主", "女公爵布劳缪克丝", "瑟里耶克爵士", "瑞文戴尔男爵"} },
            { name = "萨菲隆", mobs = {} },
            { name = "克尔苏加德", mobs = {"冰冷废土的士兵", "势不可挡的憎恶", "灵魂编织者", "冰冠卫士"} },
            { name = "萨塔里奥", mobs = {"熔岩烈焰", "维斯匹隆", "沙德隆", "塔尼布隆", "暮光雏龙"} },
            { name = "玛里苟斯", mobs = {"永恒子嗣", "魔枢领主", "能量火花", "龙眠联军载具"} },
        },
    },
    {
        key = "P4",
        title = "P4 TOC/ZG",
        tabWidth = 88,
        raids = {
            { name = "十字军试炼", first = "诺森德猛兽" },
            { name = "祖尔格拉布", first = "高阶祭司温诺希斯" },
        },
        bosses = {
            { name = "诺森德猛兽", mobs = {"雪地狗头人奴隶", "火焰炸弹"} },
            { name = "加拉克苏斯大王", mobs = {"痛苦女王", "虚空传送门", "地狱火山", "魔焰地狱火"} },
            { name = "阵营冠军", mobs = {"根基图腾", "治疗之泉图腾", "灼热图腾", "风怒图腾", "猫", "恶魔仆从"} },
            { name = "瓦格里双子", mobs = {"光明光球", "黑暗光球"} },
            { name = "阿努巴拉克", mobs = {"冰霜之球", "虫群甲虫", "蛛魔掘地者"} },
            { name = "高阶祭司温诺希斯", mobs = {"拉扎什眼镜蛇", "寄居蛇", "蛇"} },
            { name = "高阶祭司耶克里克", mobs = {"疯狂的觅血蝠", "觅血者前锋", "觅血蝙蝠"} },
            { name = "高阶祭司玛尔里", mobs = {"枯木部族演讲者", "玛尔里的爪牙", "蜘蛛"} },
            { name = "血领主曼多基尔", mobs = {"奥根", "蛇"} },
            { name = "疯狂之缘", mobs = {"梦魇幻象", "地狱火爪牙"} },
            { name = "高阶祭司塞卡尔", mobs = {"祖利安猛虎"} },
            { name = "加兹兰卡", mobs = {"巨型喷泉", "拉扎什毒蛇", "拉扎什蝰蛇", "钩齿狂鱼", "蛇"} },
            { name = "高阶祭司娅尔罗", mobs = {"祖利安徘徊者"} },
            { name = "妖术师金度", mobs = {"强力治疗结界", "洗脑图腾", "祭品巨魔", "金度之影", "老鼠"} },
            { name = "哈卡", mobs = {"哈卡之子", "古拉巴什狂暴者", "古拉巴什饮血者", "祭品巨魔", "灵魂掠夺者"} },
        },
    },
    {
        key = "P5",
        title = "P5 SWP/ZA",
        tabWidth = 98,
        raids = {
            { name = "太阳井高地", first = "卡雷苟斯" },
            { name = "祖阿曼", first = "埃基尔松" },
        },
        bosses = {
            { name = "卡雷苟斯", mobs = {"腐蚀者萨索瓦尔"} },
            { name = "布鲁塔卢斯", mobs = {} },
            { name = "菲米丝", mobs = {"顽强的死尸", "不屈的死者", "恶魔蒸汽"} },
            { name = "艾瑞达双子", mobs = {"萨洛拉丝女王", "高阶术士奥蕾塞丝"} },
            { name = "穆鲁", mobs = {"熵魔", "暗誓狂暴者", "暗誓怒火法师", "虚空戒卫", "虚空爪牙", "黑暗魔"} },
            { name = "基尔加丹", mobs = {"基尔加丹之手", "邪焰爆裂魔", "护盾宝珠", "邪恶镜像"} },
            { name = "埃基尔松", mobs = {"阿曼尼雄鹰"} },
            { name = "纳洛拉克", mobs = {} },
            { name = "加亚莱", mobs = {"阿曼尼孵化者", "阿曼尼龙鹰幼崽", "龙鹰卵"} },
            { name = "哈尔拉兹", mobs = {"山猫之灵", "哈尔拉兹（分裂形态）", "腐化闪电图腾", "火焰新星图腾"} },
            { name = "妖术领主玛拉卡斯", mobs = {"阿莱松·安提雷", "索尔格", "滑行者", "兰尔丹", "卡扎克洛斯", "沼泽猎手", "黑心", "库拉格", "玛拉卡斯随从"} },
            { name = "祖尔金", mobs = {"羽毛漩涡"} },
        },
    },
    {
        key = "P6",
        title = "P6 ULDAR",
        tabWidth = 88,
        raids = {
            { name = "奥杜尔", first = "烈焰巨兽" },
        },
        bosses = {
            { name = "烈焰巨兽", mobs = {"攻城车", "坦克车", "摩托车"} },
            { name = "掌炉者伊格尼斯", mobs = {"铁魔像", "熔炉造物"} },
            { name = "锋鳞", mobs = {"黑暗符文守卫", "黑暗符文哨兵", "黑翼技师"} },
            { name = "XT-002拆解者", mobs = {"XM-024击打者", "XE-321爆破机器人", "XB-488清理机器人"} },
            { name = "钢铁议会", mobs = {"符文大师莫尔基姆", "唤雷者布隆迪尔", "断钢者"} },
            { name = "科隆加恩", mobs = {"科隆加恩之臂", "碎石", "符文蚀刻哨兵"} },
            { name = "欧尔莉亚", mobs = {"萨纳姆守卫", "野性防御者", "黑翼卫士"} },
            { name = "霍迪尔", mobs = {"冰冻土灵", "冰霜巨人", "寒冬亡魂"} },
            { name = "托里姆", mobs = {"巨型冰虫", "被俘的雇佣兵", "黑暗符文斗兽", "闪电充能铁矮人"} },
            { name = "弗蕾亚", mobs = {"远古守护者", "爆炸鞭笞者", "风暴鞭笞者", "撕咬鞭打者", "古代水元素", "爆裂鞭笞者", "远古视察者"} },
            { name = "米米尔隆", mobs = {"巨兽二型", "VX-001", "空中指挥单位", "地雷", "灭火机器人", "XB-488清理机器人"} },
            { name = "维扎克斯将军", mobs = {"萨隆邪铁畸体", "萨隆邪铁蒸汽", "尤格萨隆的仆从"} },
            { name = "尤格萨隆", mobs = {"萨拉", "尤格萨隆卫士", "触须", "不朽守护者", "死亡信使", "束缚触须", "腐蚀触须", "碾压触须"} },
            { name = "观察者奥尔加隆", mobs = {"坍缩星", "黑暗物质", "有生命的星座"} },
        },
    },
    {
        key = "P7",
        title = "P7 GLR/MAG/KARA",
        tabWidth = 136,
        raids = {
            { name = "格鲁尔的巢穴", first = "莫加尔大王" },
            { name = "玛瑟里顿的巢穴", first = "玛瑟里顿" },
            { name = "卡拉赞", first = "猎手阿图门" },
        },
        bosses = {
            { name = "莫加尔大王", mobs = {"疯狂的基戈尔", "盲眼先知", "欧尔莫克", "召唤者沃尔姆"} },
            { name = "屠龙者格鲁尔", mobs = {} },
            { name = "玛瑟里顿", mobs = {"地狱火议会成员", "地狱火幼崽", "恶魔卫士", "魅魔", "恶魔领主"} },
            { name = "猎手阿图门", mobs = {"午夜"} },
            { name = "莫罗斯", mobs = {"莫罗斯的随从"} },
            { name = "贞节圣女", mobs = {} },
            { name = "歌剧院", mobs = {"大灰狼", "桃乐丝", "稻草人", "铁皮人", "胆小的狮子", "朱丽叶", "罗密欧", "老巫婆"} },
            { name = "馆长", mobs = {"奥术闪电球", "火焰元素"} },
            { name = "特雷斯坦·邪蹄", mobs = {"小鬼", "恶魔之链", "基尔里克"} },
            { name = "埃兰之影", mobs = {"水元素", "暗影魔"} },
            { name = "虚空幽龙", mobs = {"虚空光球"} },
            { name = "夜之魇", mobs = {} },
            { name = "国际象棋", mobs = {"棋子"} },
            { name = "玛克扎尔王子", mobs = {"地狱火", "纳斯雷兹姆"} },
        },
    },
    {
        key = "P8",
        title = "P8 BWL/AQ20/ONY",
        tabWidth = 124,
        raids = {
            { name = "黑翼之巢", first = "狂野的拉佐格尔" },
            { name = "安其拉废墟", first = "库林纳克斯" },
            { name = "奥妮克希亚的巢穴", first = "奥妮克希亚" },
        },
        bosses = {
            { name = "狂野的拉佐格尔", mobs = {"黑翼法师", "死爪军团士兵", "死爪龙人", "龙蛋"} },
            { name = "堕落的瓦拉斯塔兹", mobs = {} },
            { name = "勒什雷尔", mobs = {"黑翼兽人", "小龙", "龙人"} },
            { name = "费尔默", mobs = {"死爪龙人护卫", "黑翼管理者", "黑翼技师", "黑翼缚法者", "地精"} },
            { name = "埃博诺克", mobs = {} },
            { name = "弗莱格尔", mobs = {} },
            { name = "克洛玛古斯", mobs = {} },
            { name = "奈法利安", mobs = {"红色龙兽", "蓝色龙兽", "绿色龙兽", "青铜龙兽", "黑色龙兽", "多彩龙兽", "骷髅"} },
            { name = "库林纳克斯", mobs = {"其拉战士", "其拉蝎虫"} },
            { name = "拉贾克斯将军", mobs = {"阿努比萨斯战士", "其拉士兵", "其拉黄蜂"} },
            { name = "莫阿姆", mobs = {"法力恶魔"} },
            { name = "吞咽者布鲁", mobs = {"幼虫", "巨虫"} },
            { name = "狩猎者阿亚米斯", mobs = {"幼蜂", "其拉幼虫"} },
            { name = "无疤者奥斯里安", mobs = {"其拉战士", "其拉蝎虫"} },
            { name = "奥妮克希亚", mobs = {"奥妮克希亚幼龙", "奥妮克希亚守卫"} },
        },
    },
    {
        key = "P9",
        title = "P9 AQ40/NMD",
        tabWidth = 110,
        raids = {
            { name = "安其拉神庙", first = "预言者斯克拉姆" },
            { name = "梦魇巨龙", first = "伊森德雷" },
        },
        bosses = {
            { name = "预言者斯克拉姆", mobs = {"斯克拉姆的幻象", "其拉洗脑者", "维克尼守护者"} },
            { name = "安其拉三宝", mobs = {"克里勋爵", "亚尔基公主", "维姆", "亚尔基的血脉"} },
            { name = "沙尔图拉", mobs = {"沙尔图拉皇家卫兵"} },
            { name = "顽强的范克瑞斯", mobs = {"维克尼斯雏虫", "范克瑞斯的爪牙"} },
            { name = "维希度斯", mobs = {"维希度斯水滴"} },
            { name = "哈霍兰公主", mobs = {} },
            { name = "双子皇帝", mobs = {"维克尼拉斯大帝", "维克洛尔大帝", "变异幼虫", "爆炸幼虫"} },
            { name = "奥罗", mobs = {"奥罗甲虫", "土堆"} },
            { name = "克苏恩", mobs = {"眼球触须", "巨钩触须", "巨眼触须", "利爪触须", "克苏恩之眼"} },
            { name = "伊森德雷", mobs = {"腐化的青铜雏龙", "腐化的绿龙"} },
            { name = "泰拉尔", mobs = {"腐化的青铜雏龙", "泰拉尔之影"} },
            { name = "艾莫莉丝", mobs = {"腐化的青铜雏龙", "孢子云"} },
            { name = "莱索恩", mobs = {"腐化的青铜雏龙", "莱索恩之魂"} },
        },
    },
    {
        key = "P10",
        title = "P10 ICC/RS",
        tabWidth = 96,
        raids = {
            { name = "冰冠堡垒", first = "玛洛加尔领主" },
            { name = "红玉圣殿", first = "海里昂" },
        },
        bosses = {
            { name = "玛洛加尔领主", mobs = {"白骨风暴", "冷焰"} },
            { name = "亡语者女士", mobs = {"教派狂热者", "教派追随者", "畸形的狂热者", "亢奋的追随者", "被统御的玩家"} },
            { name = "死亡使者萨鲁法尔", mobs = {"血兽", "血符文"} },
            { name = "烂肠", mobs = {"软泥怪", "不稳定的软泥怪"} },
            { name = "腐面", mobs = {"小软泥怪", "大软泥怪", "不稳定的软泥怪"} },
            { name = "普崔塞德教授", mobs = {"软泥怪", "毒气软泥怪", "瘟疫软泥怪", "畸形怪"} },
            { name = "鲜血议会", mobs = {"瓦拉纳王子", "塔达拉姆王子", "凯雷塞斯王子", "黑暗之核", "动能炸弹"} },
            { name = "鲜血女王兰娜瑟尔", mobs = {"鲜血镜像", "被咬的玩家"} },
            { name = "踏梦者瓦莉瑟瑞娅", mobs = {"镇压者", "贪食的憎恶", "腐蛆", "复生的大法师", "灼热骷髅", "脓疮僵尸"} },
            { name = "辛达苟萨", mobs = {"寒冰坟墓", "冰霜道标"} },
            { name = "巫妖王", mobs = {"食尸鬼苦工", "蹒跚的血僵尸", "华尔琪", "冷酷寒冬", "污染", "亵渎"} },
            { name = "海里昂", mobs = {"陨石", "暮光突袭", "灵魂吞噬"} },
        },
    },
    {
        key = "P11",
        title = "终章 HS/BT",
        tabWidth = 100,
        raids = {
            { name = "海加尔山", first = "雷基·冬寒" },
            { name = "黑暗神殿", first = "高阶督军纳因图斯" },
        },
        bosses = {
            { name = "雷基·冬寒", mobs = {"食尸鬼", "亡灵法师", "大蜘蛛", "憎恶"} },
            { name = "安纳塞隆", mobs = {"食尸鬼", "亡灵法师", "女妖", "憎恶", "地狱火"} },
            { name = "卡兹洛加", mobs = {"食尸鬼", "亡灵法师", "石像鬼", "冰龙", "憎恶"} },
            { name = "阿兹加洛", mobs = {"食尸鬼", "亡灵法师", "地狱火", "地狱犬", "憎恶"} },
            { name = "阿克蒙德", mobs = {"地狱火", "恐惧魔王"} },
            { name = "高阶督军纳因图斯", mobs = {} },
            { name = "苏普雷姆斯", mobs = {} },
            { name = "阿卡玛之影", mobs = {"灰舌引导者", "灰舌巫师", "灰舌元素师", "灰舌盗贼", "灰舌缚灵者", "灰舌防御者"} },
            { name = "塔隆·血魔", mobs = {"阴暗构造体", "复仇之灵"} },
            { name = "古尔图格·血沸", mobs = {} },
            { name = "灵魂之匣", mobs = {"苦痛精华", "欲望精华", "愤怒精华", "被奴役的灵魂", "饥饿的灵魂碎块"} },
            { name = "莎赫拉丝主母", mobs = {} },
            { name = "伊利达雷议会", mobs = {"高等灵术师塞勒沃尔", "击碎者加西奥斯", "玛兰德女士", "扭曲预言者萨拉瑞德"} },
            { name = "伊利丹·怒风", mobs = {"伊利达雷精英", "寄生暗影魔", "玛维·影歌", "恶魔之火", "埃辛诺斯烈焰"} },
        },
    },
}

local NAME_ALIASES = {
    ["盘牙伏击者"] = {"盘牙腹肌者"},
    ["尸甲虫"] = {"死尸甲虫"},
    ["迈克斯纳的小蜘蛛"] = {"小蜘蛛"},
    ["染疫勇士"] = {"瘟疫勇士"},
    ["染疫战士"] = {"瘟疫战士"},
    ["僵尸食尸鬼"] = {"肉用僵尸"},
    ["冰冷废土的士兵"] = {"冰冻废土的士兵"},
    ["势不可挡的憎恶"] = {"憎恶"},
    ["冰霜之球"] = {"寒冰之球"},
    ["顽强的死尸"] = {"不屈的死者"},
    ["暗誓狂暴者"] = {"影刃狂暴者", "影剑狂战士"},
    ["暗誓怒火法师"] = {"影刃怒火法师", "影剑怒火法师"},
    ["虚空戒卫"] = {"虚空哨兵"},
    ["基尔加丹之手"] = {"欺诈者之手"},
    ["阿曼尼雄鹰"] = {"翱翔的雄鹰", "飞翔的雄鹰"},
    ["腐化闪电图腾"] = {"腐化的闪电图腾", "堕落的闪电图腾"},
    -- P4 TOC/ZG 别名（对齐 ZZ 自动爆发名单：TOC 阵营冠军随机成员 / 加拉克苏斯随从 / 祖格加兹兰卡毒蛇）
    -- 阵营冠军每场随机出场 5 名成员，其单位名为下列随机成员之一，必须全部挂为别名才能命中爆发
    ["阵营冠军"] = {"严肃的凯普斯", "伊林·雾蹄", "凋零者吉塞尔", "努兹尔·啸钉", "卡雯娜·林歌", "塞瑞莎·术轮", "安塔尔·缮炉者", "布瑞娜·沉夜", "布罗恩·粗角", "戈瑞姆·影斩", "暗语者维维尼", "比莱纳·雷蹄", "沙拜德", "深水卫士卡莉蒂丝", "深水卫士沙克基斯", "狂热者扎斯", "狂热者洛卡恩", "玛兹迪娜", "索库尔", "维兰纳", "莉安德拉·唤日者", "鲁姬卡", "麦拉多·深谷游者"},
    ["加拉克苏斯大王"] = {"萨卡加尔", "萨缪尔"},
    ["加兹兰卡"] = {"阿曼尼毒蛇"},
    -- P6 奥杜尔别名
    ["铁魔像"] = {"铁魔像"},
    ["黑暗符文守卫"] = {"黑暗符文守护者"},
    ["XM-024击打者"] = {"击打者"},
    ["XE-321爆破机器人"] = {"爆破机器人"},
    ["XB-488清理机器人"] = {"清理机器人"},
    ["符文大师莫尔基姆"] = {"莫尔基姆"},
    ["唤雷者布隆迪尔"] = {"布隆迪尔"},
    ["断钢者"] = {"断钢"},
    ["科隆加恩之臂"] = {"巨石之臂"},
    ["碎石"] = {"碎石块"},
    ["萨纳姆守卫"] = {"萨纳姆铁卫士"},
    ["野性防御者"] = {"防御者"},
    ["冰冻土灵"] = {"冰冻元素"},
    ["冰霜巨人"] = {"冰巨人"},
    ["寒冬亡魂"] = {"寒冬之魂"},
    ["巨型冰虫"] = {"巨型蠕虫"},
    ["被俘的雇佣兵"] = {"雇佣兵"},
    ["黑暗符文斗兽"] = {"斗兽"},
    ["闪电充能铁矮人"] = {"铁矮人"},
    ["远古守护者"] = {"远古保护者", "古树"},
    ["爆炸鞭笞者"] = {"爆炸藤蔓", "鞭笞者"},
    ["风暴鞭笞者"] = {"风暴藤蔓"},
    ["撕咬鞭打者"] = {"撕咬藤蔓"},
    ["古代水元素"] = {"远古水元素"},
    ["爆裂鞭笞者"] = {"爆裂藤蔓"},
    ["远古视察者"] = {"视察者"},
    ["巨兽二型"] = {"巨兽MKII"},
    ["VX-001"] = {"VX001"},
    ["空中指挥单位"] = {"空中单位"},
    ["灭火机器人"] = {"消防机器人"},
    ["萨隆邪铁畸体"] = {"萨钢畸体", "萨隆邪铁畸变体"},
    ["萨隆邪铁蒸汽"] = {"萨钢蒸汽"},
    ["尤格萨隆的仆从"] = {"尤格仆从"},
    ["萨拉"] = {"萨拉之声"},
    ["尤格萨隆卫士"] = {"尤格卫士"},
    ["不朽守护者"] = {"不朽者"},
    ["死亡信使"] = {"信使"},
    ["束缚触须"] = {"束缚触手"},
    ["腐蚀触须"] = {"腐蚀触手"},
    ["碾压触须"] = {"碾压触手", "粉碎触须"},
    ["坍缩星"] = {"坍缩之星", "坍缩恒星"},
    ["黑暗物质"] = {"暗物质"},
    ["有生命的星座"] = {"活化星座"},
    -- P7 T4团本别名
    ["疯狂的基戈尔"] = {"基戈尔"},
    ["盲眼先知"] = {"先知"},
    ["欧尔莫克"] = {"术士"},
    ["召唤者沃尔姆"] = {"沃尔姆"},
    ["地狱火议会成员"] = {"议会成员"},
    ["地狱火幼崽"] = {"幼崽地狱火"},
    ["奥术闪电球"] = {"闪电球", "奥术球"},
    ["小鬼"] = {"邪能小鬼", "恶魔小鬼"},
    ["恶魔之链"] = {"恶魔锁链"},
    ["基尔里克"] = {"恶魔猎犬"},
    ["水元素"] = {"召唤水元素"},
    ["暗影魔"] = {"暗影恶魔"},
    ["虚空光球"] = {"虚空球"},
    ["棋子"] = {"象棋棋子"},
    ["地狱火"] = {"召唤地狱火"},
    ["纳斯雷兹姆"] = {"恐惧魔王"},
    -- P8 BWL/AQ20/ONY别名
    ["黑翼法师"] = {"黑翼缚法者"},
    ["死爪军团士兵"] = {"军团士兵"},
    ["死爪龙人"] = {"龙人"},
    ["龙蛋"] = {"黑龙蛋"},
    ["黑翼兽人"] = {"黑石兽人"},
    ["小龙"] = {"幼龙"},
    ["死爪龙人护卫"] = {"龙人护卫"},
    ["黑翼管理者"] = {"管理员"},
    ["黑翼技师"] = {"技师"},
    ["黑翼缚法者"] = {"缚法者"},
    ["地精"] = {"哥布林"},
    ["红色龙兽"] = {"红龙兽"},
    ["蓝色龙兽"] = {"蓝龙兽"},
    ["绿色龙兽"] = {"绿龙兽"},
    ["青铜龙兽"] = {"青铜龙"},
    ["黑色龙兽"] = {"黑龙兽"},
    ["多彩龙兽"] = {"多彩龙"},
    ["其拉战士"] = {"其拉士兵"},
    ["其拉蝎虫"] = {"其拉蝎子"},
    ["阿努比萨斯战士"] = {"阿努比萨斯"},
    ["其拉士兵"] = {"战士"},
    ["其拉黄蜂"] = {"黄蜂"},
    ["法力恶魔"] = {"法力元素"},
    ["幼虫"] = {"其拉幼虫"},
    ["巨虫"] = {"巨型蠕虫"},
    ["幼蜂"] = {"蜂群"},
    ["其拉幼虫"] = {"幼虫群"},
    ["奥妮克希亚幼龙"] = {"幼龙"},
    ["奥妮克希亚守卫"] = {"守卫"},
    -- P9 AQ40/梦魇巨龙别名
    ["斯克拉姆的幻象"] = {"幻象"},
    ["其拉洗脑者"] = {"洗脑者"},
    ["维克尼守护者"] = {"守护者"},
    ["克里勋爵"] = {"克里"},
    ["亚尔基公主"] = {"亚尔基"},
    ["维姆"] = {"维姆大王"},
    ["亚尔基的血脉"] = {"血脉"},
    ["沙尔图拉皇家卫兵"] = {"皇家卫兵"},
    ["维克尼斯雏虫"] = {"雏虫"},
    ["范克瑞斯的爪牙"] = {"爪牙"},
    ["维希度斯水滴"] = {"水滴"},
    ["维克尼拉斯大帝"] = {"维克尼拉斯"},
    ["维克洛尔大帝"] = {"维克洛尔"},
    ["变异幼虫"] = {"变异虫"},
    ["爆炸幼虫"] = {"爆炸虫"},
    ["奥罗甲虫"] = {"甲虫"},
    ["土堆"] = {"沙堆"},
    ["眼球触须"] = {"眼球触手"},
    ["巨钩触须"] = {"巨钩触手"},
    ["巨眼触须"] = {"巨眼触手"},
    ["利爪触须"] = {"利爪触手"},
    ["克苏恩之眼"] = {"克苏恩眼球"},
    ["腐化的青铜雏龙"] = {"腐化雏龙", "青铜雏龙"},
    ["腐化的绿龙"] = {"腐化绿龙"},
    ["泰拉尔之影"] = {"阴影"},
    ["孢子云"] = {"毒云"},
    ["莱索恩之魂"] = {"灵魂"},
    -- P10 ICC/RS别名
    ["白骨风暴"] = {"骨风暴"},
    ["冷焰"] = {"冰焰"},
    ["教派狂热者"] = {"狂热者"},
    ["教派追随者"] = {"追随者"},
    ["畸形的狂热者"] = {"畸形狂热者"},
    ["亢奋的追随者"] = {"亢奋追随者"},
    ["被统御的玩家"] = {"被控制的玩家", "心控玩家"},
    ["血兽"] = {"鲜血兽"},
    ["血符文"] = {"鲜血符文"},
    ["软泥怪"] = {"软泥"},
    ["不稳定的软泥怪"] = {"不稳定软泥"},
    ["小软泥怪"] = {"小型软泥怪"},
    ["大软泥怪"] = {"大型软泥怪"},
    ["毒气软泥怪"] = {"毒气软泥"},
    ["瘟疫软泥怪"] = {"瘟疫软泥"},
    ["畸形怪"] = {"憎恶体"},
    ["瓦拉纳王子"] = {"瓦拉纳"},
    ["塔达拉姆王子"] = {"塔达拉姆"},
    ["凯雷塞斯王子"] = {"凯雷塞斯"},
    ["动能炸弹"] = {"动力炸弹"},
    ["鲜血镜像"] = {"暗影镜像"},
    ["被咬的玩家"] = {"被感染的玩家"},
    ["镇压者"] = {"压制者"},
    ["贪食的憎恶"] = {"暴食憎恶"},
    ["腐蛆"] = {"腐烂蛆虫"},
    ["复生的大法师"] = {"复活大法师"},
    ["灼热骷髅"] = {"火焰骷髅"},
    ["脓疮僵尸"] = {"瘟疫僵尸"},
    ["寒冰坟墓"] = {"寒冰之墓"},
    ["冰霜道标"] = {"冰霜信标"},
    ["食尸鬼苦工"] = {"苦工食尸鬼"},
    ["蹒跚的血僵尸"] = {"血僵尸"},
    ["华尔琪"] = {"瓦格里"},
    ["冷酷寒冬"] = {"刺骨之寒"},
    ["污染"] = {"亵渎"},
    ["亵渎"] = {"亵渎之地"},
    ["陨石"] = {"燃烧陨石"},
    ["暮光突袭"] = {"暮光切割"},
    ["灵魂吞噬"] = {"灵魂吸取"},
    -- P11 终章HS/BT别名
    ["食尸鬼"] = {"天灾食尸鬼", "亡灵食尸鬼"},
    ["亡灵法师"] = {"天灾法师"},
    ["大蜘蛛"] = {"巨型蜘蛛", "地穴恶魔"},
    ["憎恶"] = {"缝合憎恶"},
    ["女妖"] = {"哀嚎女妖"},
    ["地狱火"] = {"魔能地狱火"},
    ["石像鬼"] = {"天灾石像鬼"},
    ["冰龙"] = {"霜冻巨龙"},
    ["地狱犬"] = {"恶魔猎犬"},
    ["恐惧魔王"] = {"纳斯雷兹姆恐惧魔王"},
    ["灰舌引导者"] = {"引导者"},
    ["灰舌巫师"] = {"暗影巫师"},
    ["灰舌元素师"] = {"元素师"},
    ["灰舌盗贼"] = {"刺客"},
    ["灰舌缚灵者"] = {"缚灵者"},
    ["灰舌防御者"] = {"防御者"},
    ["阴暗构造体"] = {"阴影构造体"},
    ["复仇之灵"] = {"复仇灵魂"},
    ["苦痛精华"] = {"痛苦精华"},
    ["欲望精华"] = {"贪欲精华"},
    ["愤怒精华"] = {"狂怒精华"},
    ["被奴役的灵魂"] = {"奴役之魂"},
    ["饥饿的灵魂碎块"] = {"灵魂碎片"},
    ["高等灵术师塞勒沃尔"] = {"塞勒沃尔"},
    ["击碎者加西奥斯"] = {"加西奥斯"},
    ["玛兰德女士"] = {"玛兰德"},
    ["扭曲预言者萨拉瑞德"] = {"萨拉瑞德"},
    ["伊利达雷精英"] = {"伊利达雷卫兵"},
    ["寄生暗影魔"] = {"暗影魔"},
    ["玛维·影歌"] = {"玛维"},
    ["恶魔之火"] = {"邪能烈焰"},
    ["埃辛诺斯烈焰"] = {"埃辛诺斯之火"},
    -- P4 TOC：战名 → 实际单位名别名（修复 自动爆发/自动种族 在 冰吼·双子 不触发）
    -- WR_IsBurstListTarget 用 BOSS_NAME_SET（按战名匹配），但野兽/双子战斗中实际选中单位是子单位，
    -- 需把子单位名补进别名使其命中第一道闸；whitelistedTargets 中这些单位名本就已存在。
    ["诺森德猛兽"] = {"穿刺者戈莫克", "冰吼", "酸喉", "恐鳞"},
    ["瓦格里双子"] = {"光明邪使菲奥拉", "黑暗邪使艾蒂丝"},
    --   P4 祖尔格拉布：隐藏BOSS战名"疯狂之缘"，实际单位是轮换的四个隐藏BOSS
    ["疯狂之缘"] = {"乌苏雷", "格里雷克", "哈扎拉尔", "雷纳塔基"},
    -- ★ 多单位战统一补别名（战斗中选中子是子单位而非战名，需命中第一道闸 BOSS_NAME_SET）
    --   这些子单位名本就已在 whitelistedTargets（Burst_Whitelist.lua）中，仅差 BOSS_NAME_SET 收录；
    --   补别名后自动爆发/自动种族不再依赖不可靠的 boss 框兜底（WR_IsBurstListTarget 优先于 WCL_BURST_LIST 覆盖，安全）。
    --   P3 纳克萨玛斯
    ["天启四骑士"] = {"大领主莫格莱尼", "库尔塔兹领主", "瑟里耶克爵士", "女公爵布劳缪克丝", "瑞文戴尔男爵"},
    ["瘟疫使者诺斯"] = {"药剂师诺斯"},  -- 战名"瘟疫使者诺斯"，游戏内单位名实为"药剂师诺斯"（坏木杨手册佐证）
    ["萨塔里奥"] = {"维斯匹隆", "沙德隆", "塔尼布隆"},
    --   P5 太阳井：艾瑞达双子（whitelistedTargets 用"阿丽塞丝"，PHASES 用"奥蕾塞丝"，两者都补以防拼写分歧）
    ["艾瑞达双子"] = {"萨洛拉丝女王", "高阶术士阿丽塞丝", "高阶术士奥蕾塞丝"},
    --   P5 太阳井/祖阿曼：分身与形态战（玩家会选中这些单位，第一道闸需收录）
    ["卡雷苟斯"] = {"腐蚀者萨索瓦尔"},
    ["穆鲁"] = {"熵魔"},
    ["哈尔拉兹"] = {"哈尔拉兹（分裂形态）"},
    --   P6 奥杜尔
    ["钢铁议会"] = {"符文大师莫尔基姆", "唤雷者布隆迪尔", "断钢者"},
    ["科隆加恩"] = {"左臂", "右臂"},
    ["米米尔隆"] = {"巨兽二型", "VX-001", "空中指挥单位"},
    ["尤格萨隆"] = {"尤格-萨隆", "尤格-萨隆的大脑", "萨拉"},  -- 战名"尤格萨隆"无连字符，游戏内单位名为"尤格-萨隆"（含连字符）
    --   P10 冰冠堡垒：鲜血议会（血王子议会）
    ["鲜血议会"] = {"瓦拉纳王子", "塔达拉姆王子", "凯雷塞斯王子"},
    --   P11 黑暗神殿：伊利达雷议会
    ["伊利达雷议会"] = {"高等灵术师塞勒沃尔", "击碎者加西奥斯", "玛兰德女士", "扭曲预言者萨拉瑞德"},
    --   P8/P9 安其拉：三宝 / 双子皇帝
    ["安其拉三宝"] = {"克里勋爵", "亚尔基公主", "维姆"},
    ["双子皇帝"] = {"维克尼拉斯大帝", "维克洛尔大帝"},
}

local TARGET_BLOCKED = {
    ["维扎克斯将军"] = true,
    ["萨隆邪铁畸体"] = true,
    ["坍缩星"] = true,
    ["萨隆邪铁蒸汽"] = true,
    ["有生命的星座"] = true,
    ["暗物质"] = true,
    ["小软泥怪"] = true,
    ["大软泥怪"] = true,
    ["动力炸弹"] = true,
    ["黑暗之核"] = true,
    ["寒冰之墓"] = true,
    ["食尸鬼苦工"] = true,
    ["蹒跚的血僵尸"] = true,
    ["弗蕾亚"] = true,
    ["瓦拉纳王子"] = true,
    ["塔达拉姆王子"] = true,
    ["凯雷塞斯王子"] = true,
    ["卑劣的灵魂"] = true,
    ["达尔纳文"] = true,
    ["管理者埃克索图斯"] = true,
    ["穆拉丁·铜须"] = true,
    ["萨鲁法尔大王"] = true,
    ["寒冰之球"] = true,
    ["骨针"] = true,
    ["盘牙腹肌者"] = true,
    ["火誓者"] = true,
    ["熔火怒犬"] = true,
    ["溅火图腾"] = true,
    ["日晷祭司"] = true,
    ["日晷密探"] = true,
    ["天灾卫士"] = true,
    ["死尸甲虫"] = true,
    ["纳克萨玛斯膜拜者"] = true,
    ["小蜘蛛"] = true,
    ["辐射软泥怪"] = true,
    ["肉用僵尸"] = true,
    ["瘟疫勇士"] = true,
    ["瘟疫战士"] = true,
    ["冰冠卫士"] = true,
    ["憎恶"] = true,
    ["冰冻废土的士兵"] = true,
    ["疯狂的觅血蝠"] = true,
    ["拉扎什眼镜蛇"] = true,
    ["祖利安猛虎"] = true,
    ["哈卡之子"] = true,
    ["奥根"] = true,
    ["蛛魔掘地者"] = true,
    ["虫群甲虫"] = true,
    ["痛苦女王"] = true,
    ["虚空传送门"] = true,
    ["地狱火山"] = true,
    ["魔焰地狱火"] = true,
    ["玛尔里的爪牙"] = true,
    ["枯木部族演讲者"] = true,
    ["雪地狗头人奴隶"] = true,
    ["黑暗魔"] = true,
    -- ★ 从旧 WR_IsWCLBlacklisted 不计分名单并入：原 WCL 黑名单独有、INDEX 尚未收录的单位
    ["骨刺"] = true,
    ["血兽"] = true,
}

local AOE_EXCLUDED = {
    ["食尸鬼苦工"] = true,
    ["蹒跚的血僵尸"] = true,
    ["风暴爪牙"] = true,
    ["坍缩星"] = true,
    ["萨隆邪铁蒸汽"] = true,
    ["有生命的星座"] = true,
    ["暗物质"] = true,
    ["小软泥怪"] = true,
    ["大软泥怪"] = true,
    ["动力炸弹"] = true,
    ["黑暗之核"] = true,
    ["寒冰之墓"] = true,
    ["卑劣的灵魂"] = true,
    ["火誓者"] = true,
    ["熔火怒犬"] = true,
    ["管理者埃克索图斯"] = true,
    ["踏潮潜伏者"] = true,
    ["瘟疫勇士"] = true,
    ["瘟疫战士"] = true,
    ["肉用僵尸"] = true,
    ["辐射软泥怪"] = true,
    ["小蜘蛛"] = true,
    ["纳克萨玛斯膜拜者"] = true,
    ["死尸甲虫"] = true,
    ["天灾战士"] = true,
    ["死亡骑士学员"] = true,
    ["祖利安徘徊者"] = true,
    ["洗脑图腾"] = true,
    ["强力治疗结界"] = true,
    ["疯狂的觅血蝠"] = true,
    ["拉扎什眼镜蛇"] = true,
    ["哈卡之子"] = true,
    ["奥根"] = true,
    ["蛛魔掘地者"] = true,
    ["虫群甲虫"] = true,
    ["痛苦女王"] = true,
    ["虚空传送门"] = true,
    ["地狱火山"] = true,
    ["魔焰地狱火"] = true,
    ["玛尔里的爪牙"] = true,
    ["枯木部族演讲者"] = true,
    ["雪地狗头人奴隶"] = true,
    ["黑暗魔"] = true,
}

-- WCL_DAMAGE_TARGETS：默认"计入伤害/不屏蔽"的小怪列表
-- 对应截图中"默认排除(勾选计入)"被勾选的项目；未勾选的默认排除项不要放在这里
local WCL_DAMAGE_TARGETS = {
    -- P3 计入目标
    ["斯塔拉格"] = true,         -- NAXX 塔迪乌斯(勾选计入)
    ["费尔根"] = true,           -- NAXX 塔迪乌斯(勾选计入)
    -- P4 计入目标
    ["雪地狗头人奴隶"] = true,         -- TOC 加拉克苏斯大王(勾选计入)
    ["痛苦女王"] = true,         -- TOC 加拉克苏斯大王(勾选计入)
    ["魔焰地狱火"] = true,       -- TOC 加拉克苏斯大王(勾选计入)
    ["虫群甲虫"] = true,         -- TOC 阿努巴拉克(勾选计入)
    ["冰霜之球"] = true,         -- TOC 阿努巴拉克(勾选计入)
    ["蛛魔掘地者"] = true,         -- TOC 阿努巴拉克(勾选计入)
    -- P5 计入目标
    ["腐蚀者萨索瓦尔"] = true,   -- SW 卡雷苟斯(勾选计入)
    ["熵魔"] = true,             -- SW 穆鲁(勾选计入)
    ["山猫之灵"] = true,         -- ZA 哈尔拉兹(勾选计入)
    ["哈尔拉兹（分裂形态）"] = true, -- ZA 哈尔拉兹(勾选计入)
    -- ZG 计入目标
    ["金度之影"] = true,         -- ZG 妖术师金度(勾选计入)
}

local INDEX = {}
local function BuildIndex(name, ruleSet)
    if ruleSet[name] then
        return true
    end
    for _, alias in ipairs(NAME_ALIASES[name] or {}) do
        if ruleSet[alias] then
            return true
        end
    end
    return false
end

for _, phase in ipairs(PHASES) do
    for _, boss in ipairs(phase.bosses) do
        for _, name in ipairs(boss.mobs) do
            local entry = INDEX[name]
            if not entry then
                local isDamageTarget = WCL_DAMAGE_TARGETS[name] and true or false
                entry = {
                    key = name,
                    -- WCL_DAMAGE_TARGETS 中的小怪对应截图"默认排除(勾选计入)"项，默认计入伤害、不屏蔽；
                    -- 其余 PHASES 小怪对应截图"默认排除(未勾选)"项，默认屏蔽多线目标+近战AOE
                    target = not isDamageTarget,
                    aoe = not isDamageTarget,
                    wclDamage = isDamageTarget,
                }
                INDEX[name] = entry
                for _, alias in ipairs(NAME_ALIASES[name] or {}) do
                    INDEX[alias] = entry
                end
            end
        end
    end
end

for name in pairs(TARGET_BLOCKED) do
    if not INDEX[name] then
        INDEX[name] = {
            key = name,
            target = true,
            aoe = AOE_EXCLUDED[name] and true or false,
            wclDamage = false,
        }
    end
end

for name in pairs(AOE_EXCLUDED) do
    if not INDEX[name] then
        INDEX[name] = {
            key = name,
            target = TARGET_BLOCKED[name] and true or false,
            aoe = true,
            wclDamage = false,
        }
    end
end

ZZ_MonsterBlockPhases = PHASES
ZZ_MonsterBlockIndex = INDEX

-- ============================================================
-- ★ 5.1 BOSS 目标屏蔽检测（太阳井等单 BOSS 战防呆）
-- 构建 BOSS 名称集合（主名 + 别名），用于快速判定某目标是否为真实 BOSS
-- 参考 PigToGo_Decoded 风格：表驱动 + 本地辅助函数 + 中文注释
-- ============================================================
local BOSS_NAME_SET = {}
for _, phase in ipairs(PHASES) do
    for _, boss in ipairs(phase.bosses) do
        BOSS_NAME_SET[boss.name] = true
        for _, alias in ipairs(NAME_ALIASES[boss.name] or {}) do
            BOSS_NAME_SET[alias] = true
        end
    end
end

-- 判定目标名称是否为副本 BOSS（含别名）；非 BOSS 返回 false
function ZZ_IsBossName(name)
    if not name then return false end
    return BOSS_NAME_SET[name] and true or false
end

function IsMonsterBlocked(name, blockType)
    -- ★ 无限适配：name 为 nil（UnitName 是 secret 时已降级）直接放行，
    --   避免后续 name == UnitName("target") 对 secret string 做比较抛错。
    if not name then
        return false
    end
    -- ★ BOSS 目标永远不被怪物屏蔽系统拦截（防呆）
    -- 太阳井等单 BOSS 战不会因误屏蔽而反复提示切目标、丢失输出提示
    if ZZ_IsBossName(name) then
        return false
    end
    -- ★ 白名单优先级高于怪物屏蔽：白名单目标（shoutaokacd，即当前目标命中 Target_Whitelist）永不屏蔽
    -- 这样即使某怪物在怪物屏蔽名单中，只要在白名单内也会被强制放行（白名单 > 怪物屏蔽）
    if shoutaokacd then
        local tName = UnitName("target")
        if type(WR_IsSecretValue) == "function" and WR_IsSecretValue(tName) then
            tName = nil
        end
        if tName ~= nil and name == tName then
            return false
        end
    end
    if PigSet and PigSet.MONSTER_BLOCK_ENABLED == false then
        return false
    end
    local entry = INDEX[name]
    if not entry then
        return false
    end
    local overrides = PigSet and PigSet.WCL_MONSTER_BLOCKS
    local override = overrides and overrides[entry.key]
    if override ~= nil then
        return override and true or false
    end
    return entry[blockType] and true or false
end

-- ★ 命令行诊断：/checkboss —— 检测当前目标是否为 BOSS、是否被屏蔽输出提示
-- 选中目标后输入 /checkboss 即可。BOSS 目标应始终豁免屏蔽，正常进入输出循环。
SLASH_CHECKBOSS1 = "/checkboss"
SlashCmdList["CHECKBOSS"] = function()
    local name = WR_SafeUnitName and WR_SafeUnitName("target") or UnitName("target")
    if not name then
        print("|cffff0000[检测] 当前没有目标，无法检测|r")
        return
    end
    local isBoss = ZZ_IsBossName(name)
    local blockedTarget = IsMonsterBlocked(name, "target")
    local blockedAoe = IsMonsterBlocked(name, "aoe")
    print(string.format(
        "|cff00ff00[检测]|r 目标: %s | BOSS: %s | 屏蔽输出(target): %s | 屏蔽AOE: %s",
        name,
        isBoss and "|cff00ff00是|r" or "|cff808080否|r",
        blockedTarget and "|cffff0000是|r" or "|cff00ff00否|r",
        blockedAoe and "|cffff0000是|r" or "|cff00ff00否|r"
    ))
    if isBoss and (blockedTarget or blockedAoe) then
        print("|cffff0000[检测] 警告：BOSS 目标本应豁免屏蔽，已自动保护输出不被拦截|r")
    elseif isBoss then
        print("|cff00ff00[检测] 正常：该 BOSS 不会触发切目标/屏蔽，输出循环正常进行|r")
    end
end


-- ============================================================
-- ★ 6. CVar 锁定系统
-- ============================================================
local lockedCVars = {
    ["Contrast"] = "50",
    ["Brightness"] = "50",
    ["gamma"] = "1.0",
    ["colorblindMode"] = "0",
    ["Colorblindsimulator"] = "0",
    ["doNotFlashLowHealthWarning"] = "1",
    ["secureAbilityToggle"] = "1",
    ["findYourselfAnywhereOnlyInCombat"] = "0",
    ["findYourselfAnywhere"] = "1",
    ["autoUnshift"] = "1",
    ["equipmentManager"] = "1",
    ["cameraDistanceMaxZoomFactor"] = "4",
}

local lockedInstanceCVars = {
    ["nameplateShowAll"] = "1",
    ["nameplateShowEnemies"] = "1",
    ["nameplateShowEnemyMinions"] = "1",
    ["nameplateShowEnemyMinus"] = "1",
    ["nameplateTargetRadialPosition"] = "1",
    ["nameplateOtherTopInset"] = "0.05",
    ["nameplateOtherBottomInset"] = "0.1",
    ["nameplateLargeTopInset"] = "0.05",
    ["nameplateLargeBottomInset"] = "0.15",
    ["nameplateMaxDistance"] = "40",
    ["clampTargetNameplateToScreen"] = "1",
}

local function CVarEqual(cvarName, targetValue)
    local currentValue = GetCVar(cvarName)
    if not currentValue then
        return false
    end
    local currentNum = tonumber(currentValue)
    local targetNum = tonumber(targetValue)
    if currentNum and targetNum then
        return math.abs(currentNum - targetNum) < 0.0001
    else
        return tostring(currentValue) == tostring(targetValue)
    end
end

local cvarLockFrame = CreateFrame("Frame")
local cvarUpdatePending = false
local isSettingCVars = false

cvarLockFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
cvarLockFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
cvarLockFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

cvarLockFrame:SetScript("OnEvent", function(self, event, arg1)
    if isSettingCVars then
        return
    end
    if UnitAffectingCombat("player") then
        cvarUpdatePending = true
        return
    end
    if event == "PLAYER_REGEN_ENABLED" and not cvarUpdatePending then
        return
    end
    isSettingCVars = true
    cvarUpdatePending = false

    for cvar, reqValue in pairs(lockedCVars) do
        if not CVarEqual(cvar, reqValue) then
            SetCVar(cvar, reqValue)
        end
    end

    if IsInInstance() then
        for cvar, reqValue in pairs(lockedInstanceCVars) do
            if not CVarEqual(cvar, reqValue) then
                SetCVar(cvar, reqValue)
            end
        end
    end

    local action = GetBindingAction("CTRL-S")
    if action and action ~= "" then
        SetBinding("CTRL-S", nil)
    end
    isSettingCVars = false
end)

-- ============================================================
-- ★ 7. 怪物屏蔽配置界面
-- ============================================================
local configFrame
local monsterChecks = {}

-- ★ 2026-08-19：把 sectionTabs/sectionPanels/SelectSection 改为模块级，使 Core_PS08_F008 与
--   新增 ZZ_OpenMonsterBlockSection(idx) 能跨函数调用（之前 SelectSection 是 F007 内 local）。
local sectionTabs, sectionPanels = {}, {}

-- ★ 2026-08-19：模块级 SelectSection，原 F007 内 local function 提到此处
local function SelectSection(index)
    for i, panel in ipairs(sectionPanels) do
        if i == index then
            panel:Show()
        else
            panel:Hide()
        end
    end
    for i, tab in ipairs(sectionTabs) do
        if i == index then
            tab:LockHighlight()
            tab:GetFontString():SetTextColor(0.2, 0.8, 1)
        else
            tab:UnlockHighlight()
            tab:GetFontString():SetTextColor(1, 0.82, 0)
        end
    end
end

local function Core_PS08_F001(name, ruleSet)
    if ruleSet[name] then
        return true
    end
    for _, alias in ipairs(NAME_ALIASES[name] or {}) do
        if ruleSet[alias] then
            return true
        end
    end
    return false
end

local function Core_PS08_F002(name, enabled)
    local entry = INDEX[name]
    if not entry then
        return
    end
    PigSet.WCL_MONSTER_BLOCKS = PigSet.WCL_MONSTER_BLOCKS or {}
    local defaultEnabled = entry.target or entry.aoe
    PigSet.WCL_MONSTER_BLOCKS[entry.key] = enabled == defaultEnabled and nil or (enabled and true or false)
    for _, cb in ipairs(monsterChecks[entry.key] or {}) do
        cb:SetChecked(enabled)
    end
end

local function Core_PS08_F003(name)
    local entry = INDEX[name]
    if not entry then
        return false
    end
    local override = PigSet.WCL_MONSTER_BLOCKS and PigSet.WCL_MONSTER_BLOCKS[entry.key]
    if override ~= nil then
        return override and true or false
    end
    return entry.target or entry.aoe
end

local function Core_PS08_F004()
    PigSet.WCL_MONSTER_BLOCKS = {}
    for key, checks in pairs(monsterChecks) do
        local entry = INDEX[key]
        local enabled = entry and (entry.target or entry.aoe) or false
        for _, cb in ipairs(checks) do
            cb:SetChecked(enabled)
        end
    end
end

local function Core_PS08_F005(parent, name, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetChecked(Core_PS08_F003(name))
    cb.name = name
    local entry = INDEX[name]
    monsterChecks[entry.key] = monsterChecks[entry.key] or {}
    monsterChecks[entry.key][#monsterChecks[entry.key] + 1] = cb
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetFont(text:GetFont(), 13)
    text:SetPoint("LEFT", cb, "RIGHT", -1, 0)
    text:SetWidth(235)
    text:SetJustifyH("LEFT")
    text:SetText(name)
    cb:SetHitRectInsets(0, -235, 0, 0)
    cb:SetScript("OnClick", function(self)
        Core_PS08_F002(self.name, self:GetChecked() and true or false)
    end)
    cb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.name .. "\n手动勾选后:多线目标屏蔽+近战aoe数量屏蔽")
        GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    return cb
end

local function Core_PS08_F006(scroll, phase)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(574)
    local y = -8
    local raidAtBoss = {}
    for _, raid in ipairs(phase.raids or {}) do
        raidAtBoss[raid.first] = raid.name
    end
    for _, boss in ipairs(phase.bosses) do
        local raidName = raidAtBoss[boss.name]
        if raidName then
            local raidHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            raidHeader:SetPoint("TOPLEFT", 4, y)
            raidHeader:SetText("|cff00adf0" .. raidName .. "|r")
            y = y - 28
        end
        local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", 8, y)
        header:SetText("|cffffd100" .. boss.name .. "|r")
        y = y - 23
        if #boss.mobs == 0 then
            local none = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            none:SetPoint("TOPLEFT", 20, y - 3)
            none:SetText("无额外小怪")
            y = y - 22
        else
            for index, name in ipairs(boss.mobs) do
                local column = (index - 1) % 2
                local row = math.floor((index - 1) / 2)
                Core_PS08_F005(content, name, 14 + column * 282, y - row * 24)
            end
            y = y - math.ceil(#boss.mobs / 2) * 24
        end
        y = y - 12
    end
    content:SetHeight(math.max(1, -y + 8))
    return content
end

-- ============================================================
-- ★ 爆发列表系统（★ 2026-08-21 新增，独立于怪物屏蔽）
--   参考 ZZHELPER Main.lua "设置允许触发自动爆发的团本目标"
--   结构复刻怪物屏蔽：PHASES 阶段 → 团本 → BOSS → 小怪，全部可勾选；
--   存储 PigSet.WCL_BURST_LIST[name] = true/false，
--   ★ 2026-08-21 v2：默认只勾选 BOSS（=允许爆发），小怪/其他默认不勾选（=不爆发）
--   未显式配置的名字：BOSS 默认允许，非 BOSS 默认禁止
-- ============================================================
local burstChecks = {}

local function BurstList_IsChecked(name, isMob)
    local override = PigSet.WCL_BURST_LIST and PigSet.WCL_BURST_LIST[name]
    if override ~= nil then return override and true or false end
    -- ★ v2：默认 BOSS 允许爆发，小怪默认不勾选（未配置时按是否 BOSS 判定）
    if isMob then return false end
    return ZZ_IsBossName(name) or false
end

local function BurstList_Set(name, checked)
    PigSet.WCL_BURST_LIST = PigSet.WCL_BURST_LIST or {}
    PigSet.WCL_BURST_LIST[name] = checked and true or false
    for _, cb in ipairs(burstChecks[name] or {}) do
        cb:SetChecked(checked)
    end
end

local function BurstList_MakeCheck(parent, name, x, y, isMob)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetChecked(BurstList_IsChecked(name, isMob))
    cb.name = name
    cb.isMob = isMob and true or false
    burstChecks[name] = burstChecks[name] or {}
    burstChecks[name][#burstChecks[name] + 1] = cb
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetFont(text:GetFont(), 13)
    text:SetPoint("LEFT", cb, "RIGHT", -1, 0)
    text:SetWidth(235)
    text:SetJustifyH("LEFT")
    text:SetText(name)
    cb:SetHitRectInsets(0, -235, 0, 0)
    cb:SetScript("OnClick", function(self)
        BurstList_Set(self.name, self:GetChecked() and true or false)
    end)
    cb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.name .. "\n勾选=允许自动爆发目标；取消=爆发循环跳过该目标")
        GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    return cb
end

local function BurstList_BuildPhaseContent(scroll, phase)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(574)
    local y = -8
    local raidAtBoss = {}
    for _, raid in ipairs(phase.raids or {}) do
        raidAtBoss[raid.first] = raid.name
    end
    for bossIdx, boss in ipairs(phase.bosses) do
        local raidName = raidAtBoss[boss.name]
        if raidName then
            local raidHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            raidHeader:SetPoint("TOPLEFT", 4, y)
            raidHeader:SetText("|cff00adf0" .. raidName .. "|r")
            y = y - 28
        end
        -- ★ 2026-08-21 v3：BOSS 黄色编号标题（参考 ZZHELPER："1号 鲁西弗隆"），与下方 BOSS 本体勾选分开显示
        local bossHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bossHeader:SetPoint("TOPLEFT", 8, y)
        bossHeader:SetText("|cffffd100" .. bossIdx .. "号 " .. boss.name .. "|r")
        y = y - 22
        -- BOSS 本体可勾选（默认允许爆发）
        BurstList_MakeCheck(content, boss.name, 8, y, false)
        y = y - 26
        if #boss.mobs == 0 then
            local none = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            none:SetPoint("TOPLEFT", 20, y - 3)
            none:SetText("无额外小怪")
            y = y - 22
        else
            for index, name in ipairs(boss.mobs) do
                local column = (index - 1) % 2
                local row = math.floor((index - 1) / 2)
                -- ★ v2：小怪默认不勾选（=默认不触发爆发）
                BurstList_MakeCheck(content, name, 14 + column * 282, y - row * 24, true)
            end
            y = y - math.ceil(#boss.mobs / 2) * 24
        end
        y = y - 12
    end
    content:SetHeight(math.max(1, -y + 8))
    return content
end

local function BurstList_ResetDefaults()
    PigSet.WCL_BURST_LIST = {}
    for name, checks in pairs(burstChecks) do
        for _, cb in ipairs(checks) do
            -- ★ v2：BOSS 默认勾选（允许爆发），小怪默认不勾选
            cb:SetChecked(cb.isMob and false or true)
        end
    end
end

-- ★ 2026-08-21：全局查询函数（供 Trinket_Burst.lua 及各职业爆发循环调用）
--   判断目标名是否在爆发列表（BOSS 默认允许爆发；小怪/未勾选目标默认禁止；显式配置优先）
function WR_IsBurstListTarget(name)
    if not name or name == "" then return true end
    local override = PigSet.WCL_BURST_LIST and PigSet.WCL_BURST_LIST[name]
    if override ~= nil then return override and true or false end
    -- ★ v2：未显式配置时默认只允许 BOSS 目标爆发
    return ZZ_IsBossName(name) or false
end

-- 取目标名（含别名展开）的爆发列表判定：target 单位名称优先，其次 UNIT 名
function WR_IsBurstListTargetUnit(unit)
    local name = UnitName(unit)
    return WR_IsBurstListTarget(name)
end

local function Core_PS08_F007()
    -- ★ 2026-08-21：去掉 UIPanelDialogTemplate 外框体，仅用 BackdropTemplate 画深色底（与主面板风格一致）
    local frame = CreateFrame("Frame", "ZZ_MonsterBlockFrame", UIParent, "BackdropTemplate")
    frame:SetSize(740, 620)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = nil,
            tile = true,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        frame:SetBackdropColor(0.28, 0.28, 0.28, 1)
    else
        local darkBg = frame:CreateTexture(nil, "BACKGROUND")
        darkBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        darkBg:SetVertexColor(0.28, 0.28, 0.28, 1)
        darkBg:SetAllPoints(frame)
    end
    -- ★ 2026-08-21：标题放左上角、字号放大
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    frame.title:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    frame.title:SetText("|cffffd100功能设置|r")
    frame.title:SetShadowOffset(0, 0)
    frame.title:SetShadowColor(0, 0, 0, 0)
    -- ★ 2026-08-21：自建关闭按钮（去掉 UIPanelDialogTemplate 后无内置 Close）
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- ============================================
    -- 顶层分区选项卡（3个分区）
    -- ============================================
    -- ★ 2026-08-19：sectionTabs/sectionPanels/SelectSection 移到模块级（见上文）
    local function SelectSection_local(index)
        -- 兼容别名：F007 内部仍可能引用 SelectSection
        return SelectSection(index)
    end

    -- ★ 2026-11-11：删除「命令清单」分区；现为 怪物屏蔽 / 爆发列表 / 更新公告
    local sectionNames = {"怪物屏蔽", "爆发列表", "更新公告"}

    local secPrevious
    for i, secName in ipairs(sectionNames) do
        local tab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        tab:SetSize(76, 26)
        if secPrevious then
            tab:SetPoint("LEFT", secPrevious, "RIGHT", 4, 0)
        else
            tab:SetPoint("TOPLEFT", 18, -50)
        end
        tab:SetText(secName)
        tab:SetScript("OnClick", function()
            SelectSection(i)
        end)
        sectionTabs[i] = tab
        secPrevious = tab

        local panel = CreateFrame("Frame", nil, frame)
        panel:SetPoint("TOPLEFT", 18, -84)
        panel:SetPoint("BOTTOMRIGHT", -18, 18)
        panel:Hide()
        sectionPanels[i] = panel
    end

    -- ============================================
    -- ★ 分区1: 怪物屏蔽
    -- ============================================
    local panel1 = sectionPanels[1]
    -- ★ "启用怪物屏蔽"主控开关已迁至主界面左侧"全局"面板（爆发总闸下方），其点击逻辑经 ZZ_SetMonsterBlock 处理。

    local resetMonsters = CreateFrame("Button", nil, panel1, "UIPanelButtonTemplate")
    resetMonsters:SetSize(100, 22)
    resetMonsters:SetPoint("RIGHT", panel1, "RIGHT", -4, 4)
    resetMonsters:SetText("名单恢复默认")
    resetMonsters:SetScript("OnClick", function()
        Core_PS08_F004()
        print("|cff00ff00[MKHelperForever]|r 怪物屏蔽名单已恢复默认值。")
    end)
    resetMonsters:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("只恢复当前副本怪物名单的默认勾选状态。")
        GameTooltip:Show()
    end)
    resetMonsters:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- ★ 职业屏蔽开关（近战AOE / 远程多线 / 坦克 三个独立子开关）已迁至主界面左侧"全局"面板（爆发总闸下方），
    --   其默认值初始化与点击逻辑在 Core/UI_Config.lua 的全局区构建中处理；本面板仅保留怪物名单与名单恢复默认。

    -- 分隔线（开关移除后整体上移 100px，使团本阶段按钮与怪物名单滚动区顶置、界面紧凑）
    local phaseDivider = panel1:CreateTexture(nil, "ARTWORK")
    phaseDivider:SetTexture("Interface\\Buttons\\WHITE8x8")
    phaseDivider:SetVertexColor(0.35, 0.35, 0.35, 0.85)
    phaseDivider:SetHeight(1)
    phaseDivider:SetPoint("TOPLEFT", 0, -30)
    phaseDivider:SetPoint("TOPRIGHT", 0, -30)

    -- 先创建滚动框（SelectPhase/phase loop 都会引用它）
    local scroll = CreateFrame("ScrollFrame", "ZZ_MonsterBlockScrollFrame", panel1, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -102)
    scroll:SetPoint("BOTTOMRIGHT", -16, 0)
    WR_StyleScrollBarBlack(scroll)

    -- Phase 选项卡分两排
    -- Row1: P1-P6 (index 1-6), Row2: P7-P11 (index 7-11)
    local ROW1_COUNT = 6
    local phaseContents = {}
    local tabs = {}
    local function SelectPhase(index)
        scroll:SetVerticalScroll(0)
        for i, content in ipairs(phaseContents) do
            if i == index then
                content:Show()
            else
                content:Hide()
            end
        end
        scroll:SetScrollChild(phaseContents[index])
        for i, button in ipairs(tabs) do
            if i == index then
                button:LockHighlight()
                button:GetFontString():SetTextColor(0.2, 0.8, 1)
            else
                button:UnlockHighlight()
                button:GetFontString():SetTextColor(1, 0.82, 0)
            end
        end
    end

    -- ★ 间距对齐职业按钮（BTN_GAP=4，起始x=4，垂直间隔4）
    --   随 phaseDivider 整体上移 100px，填补原开关所占空间。
    local row1Gap, row2Gap = 4, 4
    local row1X, row1Y = 4, -36
    local row2X, row2Y = 4, -62

    local row1Previous, row2Previous
    for index, phase in ipairs(PHASES) do
        local isRow1 = index <= ROW1_COUNT
        local tabW = math.min(phase.tabWidth or 76, 100)
        local tab = CreateFrame("Button", nil, panel1, "UIPanelButtonTemplate")
        tab:SetSize(tabW, 22)
        if isRow1 then
            if row1Previous then
                tab:SetPoint("LEFT", row1Previous, "RIGHT", row1Gap, 0)
            else
                tab:SetPoint("TOPLEFT", row1X, row1Y)
            end
            row1Previous = tab
        else
            if row2Previous then
                tab:SetPoint("LEFT", row2Previous, "RIGHT", row2Gap, 0)
            else
                tab:SetPoint("TOPLEFT", row2X, row2Y)
            end
            row2Previous = tab
        end
        tab:SetText(phase.title)
        -- 缩小字号防止文本超出按钮边界导致视觉重叠
        local tfs = tab:GetFontString()
        if tfs then
            tfs:SetFont(STANDARD_TEXT_FONT, 10, "")
        end
        tab:SetScript("OnClick", function()
            SelectPhase(index)
        end)
        tabs[index] = tab
        phaseContents[index] = Core_PS08_F006(scroll, phase)
    end

    -- ============================================
    -- ★ 分区2: 爆发列表（★ 2026-08-21 新增）
    --   结构复刻怪物屏蔽：P1~P11 阶段 → 团本 → BOSS/小怪 全部可勾选
    --   勾选=允许自动爆发目标；取消=爆发循环跳过。存储 PigSet.WCL_BURST_LIST
    -- ============================================
    local panel2 = sectionPanels[2]
    -- 分区2 分隔线
    local burstDivider = panel2:CreateTexture(nil, "ARTWORK")
    burstDivider:SetTexture("Interface\\Buttons\\WHITE8x8")
    burstDivider:SetVertexColor(0.35, 0.35, 0.35, 0.85)
    burstDivider:SetHeight(1)
    burstDivider:SetPoint("TOPLEFT", 0, -30)
    burstDivider:SetPoint("TOPRIGHT", 0, -30)

    -- 恢复默认按钮
    local resetBurst = CreateFrame("Button", nil, panel2, "UIPanelButtonTemplate")
    resetBurst:SetSize(100, 22)
    resetBurst:SetPoint("RIGHT", panel2, "RIGHT", -4, 4)
    resetBurst:SetText("名单恢复默认")
    resetBurst:SetScript("OnClick", function()
        BurstList_ResetDefaults()
        print("|cff00ff00[MKHelperForever]|r 爆发列表名单已恢复默认（全部勾选）。")
    end)
    resetBurst:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("恢复当前副本爆发名单为默认（全部允许爆发）。")
        GameTooltip:Show()
    end)
    resetBurst:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- 滚动框
    local burstScroll = CreateFrame("ScrollFrame", "ZZ_BurstListScrollFrame", panel2, "UIPanelScrollFrameTemplate")
    burstScroll:SetPoint("TOPLEFT", 0, -102)
    burstScroll:SetPoint("BOTTOMRIGHT", -16, 0)
    WR_StyleScrollBarBlack(burstScroll)

    -- Phase 选项卡（两排，与怪物屏蔽一致）
    local burstPhaseContents = {}
    local burstTabs = {}
    local function SelectBurstPhase(index)
        burstScroll:SetVerticalScroll(0)
        for i, content in ipairs(burstPhaseContents) do
            if i == index then
                content:Show()
            else
                content:Hide()
            end
        end
        burstScroll:SetScrollChild(burstPhaseContents[index])
        for i, button in ipairs(burstTabs) do
            if i == index then
                button:LockHighlight()
                button:GetFontString():SetTextColor(0.2, 0.8, 1)
            else
                button:UnlockHighlight()
                button:GetFontString():SetTextColor(1, 0.82, 0)
            end
        end
    end

    local burstRow1Previous, burstRow2Previous
    for index, phase in ipairs(PHASES) do
        local isRow1 = index <= ROW1_COUNT
        local tabW = math.min(phase.tabWidth or 76, 100)
        local tab = CreateFrame("Button", nil, panel2, "UIPanelButtonTemplate")
        tab:SetSize(tabW, 22)
        if isRow1 then
            if burstRow1Previous then
                tab:SetPoint("LEFT", burstRow1Previous, "RIGHT", row1Gap, 0)
            else
                tab:SetPoint("TOPLEFT", row1X, row1Y)
            end
            burstRow1Previous = tab
        else
            if burstRow2Previous then
                tab:SetPoint("LEFT", burstRow2Previous, "RIGHT", row2Gap, 0)
            else
                tab:SetPoint("TOPLEFT", row2X, row2Y)
            end
            burstRow2Previous = tab
        end
        tab:SetText(phase.title)
        local tfs = tab:GetFontString()
        if tfs then
            tfs:SetFont(STANDARD_TEXT_FONT, 10, "")
        end
        tab:SetScript("OnClick", function()
            SelectBurstPhase(index)
        end)
        burstTabs[index] = tab
        burstPhaseContents[index] = BurstList_BuildPhaseContent(burstScroll, phase)
    end
    -- 默认选中第 1 阶段（P1），保证打开面板即有内容
    SelectBurstPhase(1)

    -- ============================================
    -- ★ 分区3: 更新公告（内联显示）
    -- ★ 2026-11-11：删除「命令清单」功能后，更新公告前移为分区3 → sectionPanels[3]
    -- ============================================
    local panel3 = sectionPanels[3]

    local noticeScroll = CreateFrame("ScrollFrame", nil, panel3, "UIPanelScrollFrameTemplate")
    noticeScroll:SetPoint("TOPLEFT", 0, -4)
    noticeScroll:SetPoint("BOTTOMRIGHT", -16, 0)
    WR_StyleScrollBarBlack(noticeScroll)
    local noticeScrollChild = CreateFrame("Frame", nil, noticeScroll)
    noticeScrollChild:SetWidth(660)

    local function RefreshNoticeInline()
        if not noticeScrollChild then return end
        noticeScrollChild:Hide()
        -- 销毁旧子控件，避免反复打开时堆积隐藏 FontString 导致渲染异常
        for _, child in ipairs({noticeScrollChild:GetChildren()}) do
            child:SetParent(nil)
        end

        local y = -4
        -- 优先使用 GX.lua 暴露的全局变量
        local updateText = MyAddonUpdateContent
        if not updateText or updateText == "" then
            -- 回落: 尝试从已加载的更新框提取文本
            local updateFrame = MyAddonUpdateFrame
            if updateFrame and updateFrame.ScrollFrame then
                local scrollChild = updateFrame.ScrollFrame:GetScrollChild()
                if scrollChild then
                    updateText = scrollChild:GetText() or ""
                end
                if not updateText or updateText == "" then
                    -- 遍历滚动子框架中的字体串
                    local children = {scrollChild:GetChildren()}
                    for _, c in ipairs(children) do
                        if c.GetText then
                            local t = c:GetText()
                            if t and t ~= "" then
                                updateText = t
                                break
                            end
                        end
                    end
                end
            end
        end

        if updateText and updateText ~= "" then
            -- 清理不间断空格与回车，避免部分客户端闪烁/乱码
            updateText = string.gsub(updateText, "\194\160", " ")
            updateText = string.gsub(updateText, "\r", "")

            local content = noticeScrollChild:CreateFontString(nil, "ARTWORK")
            content:SetFont(STANDARD_TEXT_FONT, 13, "")
            content:SetTextColor(1, 0.82, 0)
            content:SetPoint("TOPLEFT", 4, y)
            content:SetWidth(636)
            content:SetJustifyH("LEFT")
            content:SetJustifyV("TOP")
            content:SetText(updateText)
            content:SetNonSpaceWrap(true)
            y = y - content:GetStringHeight() - 8
        else
            local title = noticeScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            title:SetPoint("TOPLEFT", 4, y)
            title:SetText("|cffffd700MKHelperForever 更新公告|r")
            y = y - 28
            local desc = noticeScrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            desc:SetPoint("TOPLEFT", 8, y)
            desc:SetWidth(636)
            desc:SetJustifyH("LEFT")
            desc:SetText("更新公告内容暂未加载。\n\n请确认 GX.lua 已正确加载，或在游戏内使用 /gx 命令查看。")
            y = y - 60
        end

        noticeScrollChild:SetHeight(math.max(1, -y + 8))
        noticeScrollChild:Show()
        noticeScroll:SetScrollChild(noticeScrollChild)
    end

    -- ============================================
    -- ★ OnShow 刷新所有面板
    -- ============================================
    frame:SetScript("OnShow", function()
        -- "启用怪物屏蔽"主控框已迁至主界面左侧全局面板（ZZ_MonsterBlockMasterChk），此处同步其勾选态
        if ZZ_MonsterBlockMasterChk and ZZ_MonsterBlockMasterChk.SetChecked then
            ZZ_MonsterBlockMasterChk:SetChecked(PigSet.MONSTER_BLOCK_ENABLED ~= false)
        end
        -- 职业屏蔽（近战AOE/远程多线/坦克）三个子开关已迁至左侧全局面板，创建时即读取 PigSet，无需在此重复刷新
        RefreshNoticeInline()
    end)

    SelectSection(1)
    SelectPhase(1)
    return frame
end

function Core_PS08_F008(sectionIdx)
    if not configFrame then
        configFrame = Core_PS08_F007()
    end
    -- ★ 2026-11-11：支持指定 tab（sectionIdx 1=怪物屏蔽 / 2=爆发列表 / 3=更新公告）。
    --  若当前已显示且 tab 与请求一致 → 隐藏（再次点击同 tab 关闭弹窗）；
    --  若指定不同 tab → 仅切 tab 不重新 Show/Hide。
    if sectionIdx then
        SelectSection(sectionIdx)
    end
    if configFrame:IsShown() then
        if not sectionIdx then configFrame:Hide() end
    else
        configFrame:Show()
        if sectionIdx then SelectSection(sectionIdx) end
    end
end

ZZ_ToggleMonsterBlockFrame = Core_PS08_F008

-- ★ 2026-08-19：三个独立按钮入口（替代原单一"功能设置"按钮）
function ZZ_OpenMonsterBlockSection(sectionIdx)
    Core_PS08_F008(sectionIdx)
end

-- ★ 怪物屏蔽总开关命令（所有职业可用，无需呼出面板）
--   用法: /monster [on|off|toggle]  不填或 toggle 则切换当前状态
SLASH_MONSTER1 = "/monster"
SlashCmdList["MONSTER"] = function(msg)
    msg = strlower(msg or "")
    local enabled
    if msg == "on" then
        enabled = true
    elseif msg == "off" then
        enabled = false
    elseif msg == "" or msg == "toggle" then
        enabled = not (PigSet.MONSTER_BLOCK_ENABLED ~= false)
    else
        PrintToVisible("|cff00adf0[怪物屏蔽]|r 用法: /monster [on|off|toggle]")
        return
    end
    ZZ_SetMonsterBlock(enabled)
end

-- ============================================================
-- ★ 8. 焦点施法辅助系统
-- ============================================================
function ShowFocusHealthFrame(Unit, Text)
    if not UnitIsUnit("focus", Unit) then
        if GCD > 0.5 then
            ZZ_FocusHealthMaxWeightUnit_LastTime = GetTime() + GCD
        else
            ZZ_FocusHealthMaxWeightUnit_LastTime = GetTime() + 0.5
        end
        if Unit == "player" then
            if WR_ColorFrame_Show(111, Text .. "\n焦点P") then
                return true
            end
        elseif Unit == "target" then
            if WR_ColorFrame_Show(112, Text .. "\n焦点T") then
                return true
            end
        elseif Unit == "mouseover" then
            if WR_ColorFrame_Show(113, Text .. "\n焦点F") then
                return true
            end
        else
            for i = 1, 4 do
                if Unit == "party" .. i then
                    if WR_ColorFrame_Show(175 + i, Text .. "\n焦点P" .. i) then
                        return true
                    end
                end
            end
            for i = 1, 4 do
                if Unit == "party" .. i .. "target" then
                    if WR_ColorFrame_Show(105 + i, Text .. "\n焦点P" .. i .. "T") then
                        return true
                    end
                end
            end
            for i = 1, 25 do
                if Unit == "raid" .. i then
                    if WR_ColorFrame_Show(120 + i, Text .. "\n焦点R" .. i) then
                        return true
                    end
                end
                if Unit == "raid" .. i .. "target" then
                    if WR_ColorFrame_Show(150 + i, Text .. "\n焦点R" .. i .. "T") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 9. 治疗权重计算系统
-- ============================================================
local priorityHealthDebuff = {
    [69065] = "白骨贯体",
    [72385] = "沸腾之血",
    [72293] = "阵亡勇士的印记",
    [69240] = "邪恶毒气",
    [69290] = "枯萎的孢子",
    [69674] = "畸变感染",
    [69789] = "软泥洪流",
    [69778] = "粘稠的软泥",
    [71278] = "窒息毒气",
    [72451] = "畸变瘟疫",
    [70447] = "不稳定的软泥怪粘合剂",
    [71807] = "闪耀火花",
    [71265] = "蜂拥之影",
    [71623] = "疯狂斩杀",
    [71304] = "黑暗堕落者的契约",
    [70744] = "酸性爆炸",
    [70633] = "胆汁喷溅",
    [72963] = "血肉腐烂",
    [69766] = "动荡",
    [70126] = "冰霜道标",
    [70106] = "寒霜刺骨",
    [72546] = "收割灵魂",
    [69409] = "灵魂收割",
    [69242] = "灵魂尖啸",
    [68980] = "收割灵魂",
    [72754] = "污染",
}

local highestPriorityDebuff = {
    [72149] = "血肉成灰",
    [72150] = "血肉成灰",
    [66237] = "血肉成灰",
    [66013] = "刺骨之寒",
}

local zzMaxWeight = -math.huge
local zzMaxWeightUnit = "Nothing"
local zzMaxWeightIsTank = false
local zzWeightSeenGUID = {}

local function EvaluateUnitHealWeight(Unit, ID)
    local playerClass = UnitClassBase("player")
    local TempUnit = Unit
    if ID then
        if Unit == "raid" and raidUnits then
            TempUnit = raidUnits[ID] or (Unit .. ID)
        elseif Unit == "party" and partyUnits then
            TempUnit = partyUnits[ID] or (Unit .. ID)
        else
            TempUnit = Unit .. ID
        end
    end

    local IsRaidMember = Unit == "raid" and ID ~= nil
    if UnitExists(TempUnit) and not UnitIsDeadOrGhost(TempUnit) and not UnitIsCharmed(TempUnit) and
       (not UnitIsPlayer(TempUnit) or UnitIsConnected(TempUnit)) and
       not UnitCanAttack(TempUnit, "player") and GetUnitRange(TempUnit) <= 40 then

        local guid = UnitGUID(TempUnit)
        if not guid or zzWeightSeenGUID[guid] then
            return
        end
        zzWeightSeenGUID[guid] = true

        local maxHp = WR_SafeNumber(UnitHealthMax(TempUnit), 1)
        if maxHp <= 0 then
            return
        end

        local UnitHP = (WR_SafeNumber(UnitHealth(TempUnit), WR_SafeNumber(UnitHealthMax(TempUnit), 1)) + (WR_SafeNumber(UnitGetIncomingHeals(TempUnit), 0) or 0)) / maxHp
        local UnitWeight = UnitHP * 100
        if UnitWeight > 100 then
            UnitWeight = 100
        end
        UnitWeight = 100 - UnitWeight

        local hasHighestPriorityDebuff = GetDebuffTime(TempUnit, highestPriorityDebuff) > 0
        local UnitIsTank = false
        if UnitGroupRolesAssigned(TempUnit) == "TANK" then
            UnitIsTank = true
        end

        local currentTime = GetTime()
        if OutOfSight_ErrorMessageTime ~= nil and OutOfSight_FocusID ~= nil and
           (currentTime - OutOfSight_ErrorMessageTime) < 1.5 and OutOfSight_FocusID == guid then
            return
        elseif ZZ_GetHealthMaxWeightUnit_CurrentBossName == "阿努巴拉克" and not UnitIsTank and
               GetDebuffTime(TempUnit, 66118) > 0 and GetDebuffTime(TempUnit, 66013) == 0 then
            return
        else
            if playerClass ~= "PRIEST" then
                if UnitIsUnit(TempUnit, "player") and UnitHP < 0.50 then
                    UnitWeight = UnitWeight + (50 - UnitHP * 100) / 2
                end
            end

            if GetDebuffTime(TempUnit, priorityHealthDebuff) > 0 then
                UnitWeight = UnitWeight + 1000
            end
            if hasHighestPriorityDebuff then
                UnitWeight = UnitWeight + 10000
            end

            if playerClass == "PALADIN" then
                local BuffTime_SGDB = GetBuffTime(TempUnit, "圣光道标", true)
                if BuffTime_SGDB > 0 then
                    if not hasHighestPriorityDebuff then
                        UnitWeight = UnitWeight - 10000
                    end
                else
                    local zlms = PigSet.SS_ZLMS
                    if UnitHP < 0.7 and UnitIsTank and IsRaidMember then
                        UnitWeight = UnitWeight + 100
                    end
                    if zlms == 2 or zlms == 3 or zlms == 4 then
                        if UnitIsUnit(TempUnit, "target") then
                            UnitWeight = UnitWeight + 1000
                        end
                    elseif zlms == 5 then
                        if UnitIsTank then
                            UnitWeight = UnitWeight + 1000
                        end
                    elseif zlms == 6 then
                        if not UnitIsTank then
                            UnitWeight = UnitWeight + 1000
                        end
                    end
                    if IsRaidMember then
                        local groupID = math.ceil(ID / 5)
                        if zlms == groupID + 6 then
                            UnitWeight = UnitWeight + 1000
                        end
                    end
                end
            elseif playerClass == "PRIEST" then
                local zlms = PigSet.JL_ZLMS
                if zlms == 2 and UnitIsTank then
                    UnitWeight = UnitWeight + 1000
                elseif zlms == 3 and not UnitIsTank then
                    UnitWeight = UnitWeight + 1000
                elseif zlms == 4 and UnitIsUnit(TempUnit, "target") then
                    UnitWeight = UnitWeight + 1000
                end
            elseif playerClass == "DRUID" or playerClass == "SHAMAN" then
                local zlms = PigSet.HF_ZLMS
                if zlms == 2 and UnitIsTank then
                    UnitWeight = UnitWeight + 1000
                elseif zlms == 3 and not UnitIsTank then
                    UnitWeight = UnitWeight + 1000
                elseif zlms == 4 and UnitIsUnit(TempUnit, "target") then
                    UnitWeight = UnitWeight + 1000
                end
            end
        end

        UnitWeight = math.ceil(UnitWeight)
        local candidateIsFocus = UnitIsUnit(TempUnit, "focus")
        local bestIsFocus = UnitExists(zzMaxWeightUnit) and UnitIsUnit(zzMaxWeightUnit, "focus")
        if UnitWeight > zzMaxWeight or
           (UnitWeight == zzMaxWeight and ((candidateIsFocus and not bestIsFocus) or (not bestIsFocus and UnitIsTank and not zzMaxWeightIsTank))) then
            zzMaxWeight = UnitWeight
            zzMaxWeightUnit = TempUnit
            zzMaxWeightIsTank = UnitIsTank
        end
    end
end

function GetHealthMaxWeightUnit()
    if not IsEncounterInProgress() then
        ZZ_GetHealthMaxWeightUnit_CurrentBossName = nil
    end

    if not ZZ_GetHealthMaxWeightUnit_Event then
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("UI_ERROR_MESSAGE")
        frame:SetScript("OnEvent", function(self, event, messageType, message)
            local errorText = type(message) == "string" and message or messageType
            if type(errorText) == "string" and string.find(errorText, "目标不在视野中") then
                OutOfSight_ErrorMessageTime = GetTime()
                OutOfSight_FocusID = UnitGUID("focus")
            end
        end)
        RegisterCombatLogHandler(function()
            local _, subevent, _, _, _, _, _, _, destName = GetCombatLogEventInfo()
            if subevent == "SPELL_CAST_SUCCESS" then
                if destName == "阿努巴拉克" then
                    ZZ_GetHealthMaxWeightUnit_CurrentBossName = destName
                end
            end
        end)
        ZZ_GetHealthMaxWeightUnit_Event = true
    end

    zzMaxWeight = -math.huge
    zzMaxWeightUnit = "Nothing"
    zzMaxWeightIsTank = false
    wipe(zzWeightSeenGUID)

    local RaidOrParty = GetGroupType()
    if RaidOrParty == "raid" then
        local raidCount = math.min(GetNumGroupMembers(), 25)
        for i = 1, raidCount do
            EvaluateUnitHealWeight("raid", i)
        end
    else
        EvaluateUnitHealWeight("player")
    end

    if RaidOrParty == "party" then
        local partyCount = math.max(GetNumGroupMembers() - 1, 0)
        for i = 1, partyCount do
            EvaluateUnitHealWeight("party", i)
        end
    end

    EvaluateUnitHealWeight("target")
    return zzMaxWeightUnit
end

-- ============================================================
-- ★ 10. 焦点最大权重显示
-- ============================================================
local zzPlayerClassCache = nil
local zzHealthMaxWeightUnit = nil
local zzHealthMaxWeightUnitLastCalcTime = nil

function ShowFocusHealthMaxWeightUnit()
    if not zzPlayerClassCache then
        zzPlayerClassCache = UnitClassBase("player")
    end

    if GCD > ShiFaSuDu then
        return false
    end

    if zzPlayerClassCache == "PRIEST" and (WR_SafeCastingName and WR_SafeCastingName("player") ~= nil) then
        return false
    end
    if zzPlayerClassCache == "PALADIN" and (WR_SafeCastingName and WR_SafeCastingName("player") ~= nil) and PigSet.SS_ZLMS ~= 4 then
        return false
    end

    if ZZ_FocusHealthMaxWeightUnit_LastTime ~= nil and GetTime() - ZZ_FocusHealthMaxWeightUnit_LastTime <= 0 and UnitExists("focus") then
        return false
    end

    local now = GetTime()
    if not zzHealthMaxWeightUnitLastCalcTime or (now - zzHealthMaxWeightUnitLastCalcTime) > 0.15 then
        zzHealthMaxWeightUnit = GetHealthMaxWeightUnit()
        zzHealthMaxWeightUnitLastCalcTime = now
    end

    if UnitIsUnit(zzHealthMaxWeightUnit, "focus") then
        return false
    end

    if zzHealthMaxWeightUnit == "player" then
        if WR_ColorFrame_Show(111, "焦点P") then
            return true
        end
    elseif zzHealthMaxWeightUnit == "target" then
        if WR_ColorFrame_Show(112, "焦点T") then
            return true
        end
    else
        for i = 1, 4 do
            if zzHealthMaxWeightUnit == "party" .. i then
                if WR_ColorFrame_Show(175 + i, "焦点P" .. i) then
                    return true
                end
                break
            end
        end
        for i = 1, 25 do
            if zzHealthMaxWeightUnit == "raid" .. i then
                if WR_ColorFrame_Show(120 + i, "焦点R" .. i) then
                    return true
                end
                break
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 11. 饰品爆发窗口检测
-- ============================================================
local TrinketData = {
    ["雪怒圣物"] = { BuffName = "天神祝福", Cooldown = 55 },
    ["玉珑圣物"] = { BuffName = "天神祝福", Cooldown = 55 },
    ["雷神的遗诏"] = { BuffName = "鼎力", Cooldown = 55 },
    ["秩序之光"] = { BuffName = "升华", Cooldown = 55 },
    ["黑雾漩涡"] = { BuffName = "敏锐", Cooldown = 55 },
    ["碳酸红宝石"] = { BuffName = "蓄力一击", Cooldown = 115 },
    ["玉质御者俑"] = { BuffName = "提速", Cooldown = 55 },
    ["萦雾之恐"] = { BuffName = "无情打击", Cooldown = 55 },
    ["群星之瓶"] = { BuffName = "敏捷", Cooldown = 55 },
    ["惊怖精华"] = { BuffName = "迅疾如风", Cooldown = 55 },
    ["基洛普泰里克的印记"] = { BuffName = "敏捷", Cooldown = 55 },
    ["灭世之魔眼"] = { BuffName = "泰坦之力", Cooldown = 55 },
    ["末代龙裔之源"] = { BuffName = "洞悉弱点", Cooldown = 55 },
    ["灾变角斗士的征服徽记"] = { BuffName = "征服之涌", Cooldown = 55 },
    ["灾变角斗士的胜利徽记"] = { BuffName = "胜利之涌", Cooldown = 55 },
    ["灾变角斗士的统御徽记"] = { BuffName = "统御之涌", Cooldown = 55 },
    ["拉夏的左眼"] = { BuffName = "复仇之眼", Cooldown = 55 },
    ["瓦罗森的胸针"] = { BuffName = "瓦罗针的饰针", Cooldown = 55 },
    ["摘星罗盘"] = { BuffName = "提速", Cooldown = 55 },
    ["真实之镜"] = { BuffName = "痛苦反射", Cooldown = 55 },
    ["恐惧小盒"] = { BuffName = "触须", Cooldown = 55 },
    ["泰坦之砧"] = { BuffName = "痛苦反射", Cooldown = 45 },
    ["暗月卡片：伟大"] = { BuffName = "伟大", Cooldown = 45 },
}

function CheckTrinketBurstWindow(Classes)
    local Trinket1_Name, Trinket2_Name
    local Trinket1_ID = GetInventoryItemID("player", 13)
    local Trinket2_ID = GetInventoryItemID("player", 14)
    local TrinketSum = 0
    local TrinketBuffSum = 0
    local Trinket1_BuffTime = 0
    local Trinket2_BuffTime = 0

    -- ★ 无限 12.x 安全：GetItemInfo 可能缺失，先做存在性守卫 + pcall
    if Trinket1_ID and type(GetItemInfo) == "function" then
        local ok, n = pcall(GetItemInfo, Trinket1_ID)
        Trinket1_Name = ok and n or nil
    end
    if Trinket2_ID and type(GetItemInfo) == "function" then
        local ok, n = pcall(GetItemInfo, Trinket2_ID)
        Trinket2_Name = ok and n or nil
    end

    if Trinket1_Name then
        if TrinketData[Trinket1_Name] then
            TrinketSum = TrinketSum + 1
            Trinket1_BuffTime = GetBuffTime("player", TrinketData[Trinket1_Name].BuffName)
            if Trinket1_BuffTime > 0 then
                TrinketBuffSum = TrinketBuffSum + 1
                if not ZZ_Trinket1_NextTime or ZZ_Trinket1_NextTime < GetTime() then
                    ZZ_Trinket1_NextTime = GetTime() + TrinketData[Trinket1_Name].Cooldown
                end
            end
        end
    end
    if Trinket2_Name then
        if TrinketData[Trinket2_Name] then
            TrinketSum = TrinketSum + 1
            Trinket2_BuffTime = GetBuffTime("player", TrinketData[Trinket2_Name].BuffName)
            if Trinket2_BuffTime > 0 then
                TrinketBuffSum = TrinketBuffSum + 1
                if not ZZ_Trinket2_NextTime or ZZ_Trinket2_NextTime < GetTime() then
                    ZZ_Trinket2_NextTime = GetTime() + TrinketData[Trinket2_Name].Cooldown
                end
            end
        end
    end

    if Trinket1_BuffTime > 0 and Trinket1_BuffTime < 3 then
        return true
    end
    if Trinket2_BuffTime > 0 and Trinket2_BuffTime < 3 then
        return true
    end

    local BuffTime_BJZL = 0
    if Classes == "DK" then
        BuffTime_BJZL = GetBuffTime("player", "不洁之力")
    end

    if TrinketSum == 0 then
        if Classes == "DK" then
            if BuffTime_BJZL > 0 then
                return true
            end
        else
            return true
        end
    end

    if TrinketSum == 1 then
        if TrinketBuffSum == 1 then
            if Classes == "DK" then
                if BuffTime_BJZL > 0 then
                    return true
                end
            else
                return true
            end
        end
        if Trinket1_Name then
            if ZZ_Trinket1_NextTime then
                if ZZ_Trinket1_NextTime > GetTime() then
                    if Classes == "DK" then
                        if BuffTime_BJZL > 0 then
                            return true
                        end
                    else
                        return true
                    end
                end
            end
        end
        if Trinket2_Name then
            if ZZ_Trinket2_NextTime then
                if ZZ_Trinket2_NextTime > GetTime() then
                    if Classes == "DK" then
                        if BuffTime_BJZL > 0 then
                            return true
                        end
                    else
                        return true
                    end
                end
            end
        end
    end

    if TrinketSum == 2 then
        if TrinketBuffSum == 2 then
            if Classes == "DK" then
                if BuffTime_BJZL > 0 then
                    return true
                end
            else
                return true
            end
        end
        if TrinketBuffSum == 1 then
            if Trinket1_BuffTime > 0 then
                if ZZ_Trinket2_NextTime then
                    if ZZ_Trinket2_NextTime - GetTime() > Trinket1_BuffTime - 2 then
                        return true
                    end
                end
            end
            if Trinket2_BuffTime > 0 then
                if ZZ_Trinket1_NextTime then
                    if ZZ_Trinket1_NextTime - GetTime() > Trinket2_BuffTime - 2 then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- ============================================================
-- ★ 12. 单目标战斗判断
-- ============================================================
local SingleUnitName = {
    [1] = "教官拉苏维奥斯",
    [2] = "药剂师诺斯",
    [3] = "格罗布鲁斯",
    [4] = "格拉斯",
    [5] = "迈克斯纳",
    [6] = "克尔苏加德",
    [7] = "符文大师莫尔基姆",
    [8] = "唤雷者布隆迪尔",
    [9] = "断钢者",
    [10] = "维扎克斯将军",
    [11] = "萨隆邪铁畸体",
    [12] = "掌炉者伊格尼斯",
    [13] = "观察者奥尔加隆",
    [14] = "坍缩星",
    [15] = "远古监护者",
    [16] = "护卫鞭笞者",
    [17] = "寒冬亡魂",
    [18] = "风暴看守者埃玛尔隆",
    [19] = "风暴爪牙",
    [20] = "安哈卡的守护者",
    [21] = "腐面",
    [22] = "凯雷塞斯王子",
    [23] = "塔达拉姆王子",
    [24] = "瓦拉纳王子",
    [25] = "死亡使者萨鲁法尔",
    [26] = "血兽",
}

function IsSingleUnitFight()
    local UName = WR_SafeUnitName and WR_SafeUnitName("target") or UnitName("target")
    for _, name in pairs(SingleUnitName) do
        if name == UName then
            return true
        end
    end
    return false
end

-- ============================================================
-- ★ 13. 停止施法判断
-- ============================================================
local StopCastName = {
    "恐怖咆哮",
    "烈焰喷射",
    "大地震颤",
    "震耳咆哮",
}

function IsStopCastSpellIncoming(StopCastTime)
    if FindEnemyCastingSpellInRange(45, StopCastName) < StopCastTime + 0.4 then
        return true
    end
    return false
end

-- ============================================================
-- ★ 14. 法力宝石可用性
-- ============================================================
function HasManaGemReady()
    local count = GetItemCount("法力青玉")
    if count ~= nil and count >= 1 then
        local ZLS = { [1] = 33312 }
        for _, ZLS_ID in ipairs(ZLS) do
            local start, duration, enable = C_Container.GetItemCooldown(ZLS_ID)
            if start + duration - GetTime() <= 0 then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 15. 焦点施法信息设置 (已在★4中实现，此处保留兼容)
-- ============================================================

-- ============================================================
-- ★ 16. 框架透明度控制 (Core_IconID functions)
-- ============================================================
local alphaWindows = setmetatable({}, {__mode = "k"})

function Iconid_F001(frame, alphaValue)
    if not frame then return end
    local alpha = math.max(10, math.min(100, tonumber(alphaValue) or 100)) / 100
    local backdropApplied = false
    if frame.GetBackdrop and frame.GetBackdropColor and frame.SetBackdropColor then
        local backdrop = frame:GetBackdrop()
        if backdrop and backdrop.bgFile then
            if not frame.ZZ_BackdropColor then
                local r, g, b = frame:GetBackdropColor()
                frame.ZZ_BackdropColor = {r or 1, g or 1, b or 1}
            end
            frame:SetBackdropColor(frame.ZZ_BackdropColor[1], frame.ZZ_BackdropColor[2], frame.ZZ_BackdropColor[3], alpha)
            backdropApplied = true
        end
    end
    if not backdropApplied then
        for _, region in ipairs({frame:GetRegions()}) do
            if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
                region:SetAlpha(alpha)
            end
        end
    end
end

function Iconid_F002(frame)
    if not frame then return end
    alphaWindows[frame] = true
    Iconid_F001(frame, PigSet and PigSet.FrameAlpha or 100)
    if not frame.ZZ_AlphaOnShowHooked then
        frame:HookScript("OnShow", function(self)
            Iconid_F001(self, PigSet and PigSet.FrameAlpha or 100)
        end)
        frame.ZZ_AlphaOnShowHooked = true
    end
end

function Iconid_F003(alphaValue)
    for frame in pairs(alphaWindows) do
        if frame:IsShown() then
            Iconid_F001(frame, alphaValue)
        end
    end
end

-- ============================================================
-- ★ 17. 配置界面构建器 (Core_IconID functions)
-- ============================================================
local classColorCache = nil
local function GetClassColorRGB()
    if classColorCache then return classColorCache end
    local _, playerClass = UnitClass("player")
    classColorCache = RAID_CLASS_COLORS[playerClass] or {r = 1, g = 0.82, b = 0}
    return classColorCache
end

-- ★ 切换提示信息输出 PrintToVisible 已上移至文件顶部（见文件头注释后），此处不再重复定义

local function Iconid_F004(config)
    local classColor = GetClassColorRGB()
    local yOffset = -12 - 25 * (config.row - 1)
    local textFrame = config.parentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    textFrame:SetTextColor(classColor.r, classColor.g, classColor.b)
    textFrame:SetText(config.text)
    textFrame:SetShadowOffset(0, 0)
    textFrame:SetShadowColor(0, 0, 0, 0)
    textFrame:SetPoint("TOPRIGHT", config.parentFrame, "BOTTOMRIGHT", 0, yOffset)

    local dropdown = CreateFrame("Frame", config.dropdownName, config.parentFrame, "UIDropDownMenuTemplate")
    -- ★ 2026-08-21：取消下拉框外框边缘
    if type(WR_StyleDropdownFlat) == "function" then
        WR_StyleDropdownFlat(dropdown)
    end
    -- 外框已取消，无需 -16 缩进；左边缘与标签右边缘对齐
    dropdown:SetPoint("LEFT", textFrame, "RIGHT", 0, -2)
    dropdown.config = config
    dropdown.menuItems = config.menuItems
    UIDropDownMenu_SetWidth(dropdown, config.width or 80)

    local overlayBtn = CreateFrame("Button", nil, dropdown)
    -- 点击区直接占满整个下拉框
    overlayBtn:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, 0)
    overlayBtn:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", 0, 0)
    local btn = _G[dropdown:GetName().."Button"]
    overlayBtn:SetScript("OnClick", function() if btn then btn:Click() end end)

    local function InitializeDropdown()
        for i, item in ipairs(dropdown.menuItems) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.checked = ((PigSet[config.saveVariable] or config.defaultID) == i)
            info.minWidth = config.width or 80
            info.func = function()
                UIDropDownMenu_SetSelectedID(dropdown, i)
                UIDropDownMenu_SetText(dropdown, item.text)
                if config.saveVariable then
                    PigSet[config.saveVariable] = i
                end
            end
            UIDropDownMenu_AddButton(info)
        end
        local selectedID = UIDropDownMenu_GetSelectedID(dropdown) or 1
        UIDropDownMenu_SetText(dropdown, dropdown.menuItems[selectedID].text)
    end
    dropdown.Initialize = InitializeDropdown
    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")

    local dropdownText = _G[dropdown:GetName().."Text"]
    if dropdownText then
        dropdownText:SetScale(0.85)
        dropdownText:ClearAllPoints()
        dropdownText:SetPoint("LEFT", dropdown:GetName().."Left", "LEFT", 41, 2)
        dropdownText:SetShadowOffset(0, 0)
        dropdownText:SetShadowColor(0, 0, 0, 0)
    end

    if PigSet[config.saveVariable] == nil or type(PigSet[config.saveVariable]) ~= "number" then
        PigSet[config.saveVariable] = config.defaultID
    end
    UIDropDownMenu_SetSelectedID(dropdown, PigSet[config.saveVariable] or config.defaultID)
    UIDropDownMenu_SetText(dropdown, config.menuItems[PigSet[config.saveVariable]].text or config.menuItems[config.defaultID].text)

    if config.saveVariable then
        local function SetDropdownSelection(selection)
            local id = tonumber(selection)
            if id == nil then
                id = PigSet[config.saveVariable] + 1
                if id > #config.menuItems then id = 1 end
            end
            if id and id >= 1 and id <= #config.menuItems then
                UIDropDownMenu_SetSelectedID(dropdown, id)
                UIDropDownMenu_SetText(dropdown, config.menuItems[id].text)
                PigSet[config.saveVariable] = id
                print(string.format("|cff00ff00%s|r 已设置为：|cffffd700%s|r", config.text, config.menuItems[id].text))
            end
        end
        _G["SLASH_"..config.saveVariable.."1"] = "/"..config.saveVariable
        SlashCmdList[config.saveVariable] = function(msg) SetDropdownSelection(msg) end
    end

    function dropdown.UpdateMenuItems(newItems)
        dropdown.menuItems = newItems
        dropdown.Initialize()
    end
    function dropdown.UpdateMenuItem(index, newText)
        if index >= 1 and index <= #dropdown.menuItems then
            dropdown.menuItems[index].text = newText
            dropdown.Initialize()
        end
    end
    return textFrame, dropdown
end

local function Iconid_F005(config)
    local classColor = GetClassColorRGB()
    local anchorPoint = "TOPRIGHT"
    local relativePoint = "BOTTOMRIGHT"
    local xOffset = -30 + 39 * (config.column - 1)
    local yOffset = -12 - 64 * (config.row - 1)
    local iconFrame = CreateFrame("Button", nil, config.parentFrame)
    iconFrame:SetSize(34, 34)
    iconFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    iconFrame:SetPoint(anchorPoint, config.anchorTo, relativePoint, xOffset, yOffset)

    local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(iconFrame)
    iconTexture:SetAlpha(0.8)
    iconTexture:SetTexture(config.IconID)
    local text = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
    text:SetText(config.text or "")
    -- 关闭 GameFontNormalSmall 自带阴影，避免功能设置面板图标文字出现重影
    text:SetShadowOffset(0, 0)
    text:SetShadowColor(0, 0, 0, 0)

    local checkbox = CreateFrame("CheckButton", config.checkboxName, config.parentFrame, "UICheckButtonTemplate")
    checkbox:SetSize(26, 26)
    checkbox:SetPoint("TOP", iconTexture, "BOTTOM", 0, 3)
    checkbox:SetAlpha(0.8)
    if PigSet[config.saveVariable] == nil then
        PigSet[config.saveVariable] = config.defaultState
    end
    checkbox:SetChecked(PigSet[config.saveVariable])
    -- ★ 勾选状态联动：未勾选时图标去饱和+变暗，勾选时恢复彩色（借鉴 ZZ 风格）
    local function ApplyIconEnableState()
        if checkbox:GetChecked() then
            iconTexture:SetVertexColor(1, 1, 1)
            iconTexture:SetAlpha(0.85)
        else
            iconTexture:SetVertexColor(0.45, 0.45, 0.45)
            iconTexture:SetAlpha(0.28)
        end
    end
    ApplyIconEnableState()
    iconFrame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    local function ShowTooltip(self)
        iconTexture:SetVertexColor(1, 1, 1)
        iconTexture:SetAlpha(1)
        checkbox:SetAlpha(1)
        iconFrame:LockHighlight()
        if config.tooltipText then
            GameTooltip:SetOwner(self, config.tooltipAnchor or "ANCHOR_RIGHT")
            GameTooltip:SetText(config.tooltipText.."\n宏/"..config.saveVariable.."切换开和关")
            GameTooltip:Show()
        end
    end
    local function HideTooltip(self)
        ApplyIconEnableState()
        checkbox:SetAlpha(0.8)
        iconFrame:UnlockHighlight()
        GameTooltip:Hide()
    end
    checkbox:SetScript("OnEnter", ShowTooltip)
    checkbox:SetScript("OnLeave", HideTooltip)
    iconFrame:SetScript("OnEnter", ShowTooltip)
    iconFrame:SetScript("OnLeave", HideTooltip)

    local function PrintToVisible(msg)
        -- ★★ 2026-11-11：屏幕文字提示总闸（默认关闭）。关闭时聊天框切换提示也不输出。
        -- 兼容：总闸函数未定义时按「关闭」处理，避免加载顺序异常导致报错。
        if type(WR_ScreenTextNoticeEnabled) ~= "function"
            or not WR_ScreenTextNoticeEnabled() then return end
        local mode = PigSet["ChatNoticeMode"]
        if mode == 0 then return end
        if mode == 1 then print(msg); return end
        for i = 1, NUM_CHAT_WINDOWS do
            local cf = _G["ChatFrame"..i]
            if cf and cf:IsVisible() then cf:AddMessage(msg) end
        end
    end
    local function OnToggleClick(self, button)
        local newState = not PigSet[config.saveVariable]
        PigSet[config.saveVariable] = newState
        checkbox:SetChecked(newState)
        ApplyIconEnableState()
        local statusText = newState and "|cff00ff00开启|r" or "|cffff0000关闭|r"
        PrintToVisible(string.format(statusText.." [%s]", config.tooltipText or config.checkboxName))
    end
    checkbox:RegisterForClicks("AnyUp")
    checkbox:SetScript("OnClick", OnToggleClick)
    checkbox:SetScript("OnMouseUp", nil)
    iconFrame:SetScript("OnClick", OnToggleClick)
    iconFrame:SetScript("OnMouseUp", nil)

    if config.saveVariable then
        local function HandleCommand(msg)
            msg = strlower(msg or "")
            if msg == "on" then
                PigSet[config.saveVariable] = true
                checkbox:SetChecked(true)
                ApplyIconEnableState()
                PrintToVisible(string.format("|cff00ff00已启用 [%s]|r", config.tooltipText or config.checkboxName))
            elseif msg == "off" then
                PigSet[config.saveVariable] = false
                checkbox:SetChecked(false)
                ApplyIconEnableState()
                PrintToVisible(string.format("|cffff0000已关闭 [%s]|r", config.tooltipText or config.checkboxName))
            elseif msg == "" or msg == "toggle" then
                local newState = not PigSet[config.saveVariable]
                PigSet[config.saveVariable] = newState
                checkbox:SetChecked(newState)
                OnToggleClick()
            end
        end
        _G["SLASH_"..config.saveVariable.."1"] = "/"..config.saveVariable
        SlashCmdList[config.saveVariable] = HandleCommand
    end
    return iconFrame, checkbox
end

-- SLASH_PIGCHAT 聊天框通知模式切换
SLASH_PIGCHAT1 = "/pigchat"
SlashCmdList["PIGCHAT"] = function(msg)
    msg = strtrim(strlower(msg or ""))
    -- ★ 2026-11-11：除「关闭」外，设置聊天提示模式时顺带打开屏幕文字提示总闸，
    -- 避免总闸关闭导致 /pigchat 设了模式却看不到任何提示。
    if type(PigSet) == "table" and msg ~= "0" and msg ~= "off" then
        PigSet["ScreenTextNotice"] = true
        if type(WR_RefreshScreenTextCheckbox) == "function" then WR_RefreshScreenTextCheckbox() end
    end
    if msg == "0" or msg == "off" then
        PigSet["ChatNoticeMode"] = 0
        print("|cff00ff00[MKHelperForever]|r 开关提示已完全|cffff0000关闭|r。")
    elseif msg == "1" then
        PigSet["ChatNoticeMode"] = 1
        print("|cff00ff00[MKHelperForever]|r 开关提示现在只显示在|cffffd700默认聊天框|r。")
    elseif msg == "2" or msg == "on" then
        PigSet["ChatNoticeMode"] = 2
        print("|cff00ff00[MKHelperForever]|r 开关提示现在显示在|cff00ff00所有可见的聊天框|r。")
    else
        local current = PigSet["ChatNoticeMode"]
        if current == nil then current = 2 end
        if current == 2 then
            PigSet["ChatNoticeMode"] = 1
            print("|cff00ff00[MKHelperForever]|r 开关提示现在只显示在|cffffd700默认聊天框|r。")
        elseif current == 1 then
            PigSet["ChatNoticeMode"] = 0
            print("|cff00ff00[MKHelperForever]|r 开关提示已完全|cffff0000关闭|r。")
        else
            PigSet["ChatNoticeMode"] = 2
            print("|cff00ff00[MKHelperForever]|r 开关提示现在显示在|cff00ff00所有可见的聊天框|r。")
        end
        print("可用命令: /pigchat 0(关闭), /pigchat 1(默认窗口), /pigchat 2(全部可见窗口)")
    end
end

-- ============================================================
-- ★ 19. 插件过期检查 + 更新日志面板 (Core_Savedata)
-- ============================================================
local EXPIRATION_DATE_HOUR = 2099123100
local expirationNoticeFrame

local function GetCurrentTimeAsNumber()
    if C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
        local ok, calendar = pcall(C_DateAndTime.GetCurrentCalendarTime)
        if ok and calendar and calendar.year and calendar.month and calendar.monthDay then
            return (calendar.year * 10000 + calendar.month * 100 + calendar.monthDay) * 100 + (calendar.hour or 0)
        end
    end
    if CalendarGetDate then
        local ok, _, month, monthDay, year = pcall(CalendarGetDate)
        if ok and year and month and monthDay then
            local hour = 0
            if GetGameTime then hour = GetGameTime() or 0 end
            return (year * 10000 + month * 100 + monthDay) * 100 + hour
        end
    end
    if date then
        local timestamp = GetServerTime and GetServerTime() or nil
        local ok, calendar = pcall(date, "*t", timestamp)
        if ok and calendar and calendar.year and calendar.month and calendar.day then
            return (calendar.year * 10000 + calendar.month * 100 + calendar.day) * 100 + (calendar.hour or 0)
        end
    end
    return 0
end

local function ShowExpirationNotice()
    if expirationNoticeFrame then
        expirationNoticeFrame:Show()
        return
    end
    local frame = CreateFrame("Frame", "ZZHELPERExpirationNoticeFrame", UIParent, "BackdropTemplate")
    expirationNoticeFrame = frame
    frame:SetSize(520, 220)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(10000)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11},
    })
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", 0, -38)
    title:SetText("|cffff2020插件已停止更新|r")
    local message = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    message:SetPoint("TOP", title, "BOTTOM", 0, -34)
    message:SetWidth(450)
    message:SetJustifyH("CENTER")
    message:SetText("有需要新版请联系微信\n|cff00ff00chengjnuu|r")
    frame:SetScript("OnHide", function(self)
        C_Timer.After(0, function()
            if GetCurrentTimeAsNumber() >= EXPIRATION_DATE_HOUR and not self:IsShown() then
                self:Show()
            end
        end)
    end)
    frame:Show()
end

local expirationLogicFrame = CreateFrame("Frame")
expirationLogicFrame:RegisterEvent("PLAYER_LOGIN")
expirationLogicFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
expirationLogicFrame:SetScript("OnEvent", function()
    if GetCurrentTimeAsNumber() >= EXPIRATION_DATE_HOUR then
        ShowExpirationNotice()
    end
end)

function GetSpellBaseGCD()
    return 1.5
end

function Myaddon_SD_F001(updateContent, faqContent, fontSize)
    updateContent = updateContent or ""
    faqContent = faqContent or ""
    fontSize = fontSize or 16

    local UpdateFrame = CreateFrame("Frame", "MKHelperForeverUpdateFrame", UIParent, "BackdropTemplate")
    UpdateFrame:SetSize(450, 480)
    UpdateFrame:SetPoint("CENTER")
    UpdateFrame:SetFrameStrata("DIALOG")
    UpdateFrame:Hide()
    UpdateFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11},
    })
    if Iconid_F002 then Iconid_F002(UpdateFrame) end
    UpdateFrame:SetMovable(true)
    UpdateFrame:EnableMouse(true)
    UpdateFrame:RegisterForDrag("LeftButton")
    UpdateFrame:SetScript("OnDragStart", UpdateFrame.StartMoving)
    UpdateFrame:SetScript("OnDragStop", UpdateFrame.StopMovingOrSizing)

    local Title = UpdateFrame:CreateFontString("MKHelperForeverUpdateFrameTitle", "OVERLAY", "GameFontNormalLarge")
    Title:SetPoint("TOP", UpdateFrame, "TOP", 0, -20)
    Title:SetWidth(400)
    Title:SetJustifyH("CENTER")
    Title:SetSpacing(4)
    Title:SetText("|cffFFD100猪猪助手更新日志|r")

    local CloseBtn = CreateFrame("Button", nil, UpdateFrame, "UIPanelCloseButton")
    CloseBtn:SetPoint("TOPRIGHT", -5, -5)

    local OkayBtn = CreateFrame("Button", nil, UpdateFrame, "UIPanelButtonTemplate")
    OkayBtn:SetSize(120, 30)
    OkayBtn:SetPoint("BOTTOM", 0, 15)
    OkayBtn:SetText("我知道了")
    OkayBtn:SetScript("OnClick", function() UpdateFrame:Hide() end)

    local ScrollFrame = CreateFrame("ScrollFrame", "MyAddonScrollFrame", UpdateFrame, "UIPanelScrollFrameTemplate")
    ScrollFrame:SetPoint("TOPLEFT", 25, -90)
    ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 55)
    WR_StyleScrollBarBlack(ScrollFrame)
    local ScrollChild = CreateFrame("Frame", nil, ScrollFrame)
    ScrollChild:SetSize(ScrollFrame:GetWidth(), 1)
    ScrollFrame:SetScrollChild(ScrollChild)

    local ContentText = ScrollChild:CreateFontString(nil, "ARTWORK")
    ContentText:SetFont(STANDARD_TEXT_FONT, fontSize, "")
    ContentText:SetJustifyH("LEFT")
    ContentText:SetJustifyV("TOP")
    ContentText:SetNonSpaceWrap(true)
    ContentText:SetWordWrap(true)
    ContentText:SetWidth(360)
    ContentText:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 5, -5)

    local function RefreshDisplay()
        -- 替换不可见字符为普通空格（避免部分客户端乱码/闪烁）
        local safeContent = string.gsub(updateContent, "\194\160", " ")
        safeContent = string.gsub(safeContent, "\r", "")
        ContentText:SetText(safeContent)

        -- 延迟计算文本高度，确保滚动区域正确
        C_Timer.After(0.05, function()
            local rawHeight = ContentText:GetStringHeight() or 100
            if rawHeight < 50 then rawHeight = 100 end
            ScrollChild:SetHeight(rawHeight + 30)
        end)
    end

    hooksecurefunc("ReloadUI", function()
        if type(MyAddon_SaveData) ~= "table" then MyAddon_SaveData = {} end
        MyAddon_SaveData.IsReloading = true
    end)

    local LogicFrame = CreateFrame("Frame")
    LogicFrame:RegisterEvent("PLAYER_LOGIN")
    LogicFrame:SetScript("OnEvent", function()
        if type(MyAddon_SaveData) ~= "table" then MyAddon_SaveData = {} end
        RefreshDisplay()
        if not MyAddon_SaveData.IsReloading then UpdateFrame:Show() end
        MyAddon_SaveData.IsReloading = false
    end)

    local FAQFrame = CreateFrame("Frame", "MKHelperForeverFAQFrame", UIParent, "BackdropTemplate")
    FAQFrame:SetSize(450, 480)
    FAQFrame:SetPoint("CENTER")
    FAQFrame:SetFrameStrata("DIALOG")
    FAQFrame:Hide()
    FAQFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11},
    })
    if Iconid_F002 then Iconid_F002(FAQFrame) end
    FAQFrame:SetMovable(true)
    FAQFrame:EnableMouse(true)
    FAQFrame:RegisterForDrag("LeftButton")
    FAQFrame:SetScript("OnDragStart", FAQFrame.StartMoving)
    FAQFrame:SetScript("OnDragStop", FAQFrame.StopMovingOrSizing)

    local FAQTitle = FAQFrame:CreateFontString("MKHelperForeverFAQFrameTitle", "OVERLAY", "GameFontNormalLarge")
    FAQTitle:SetPoint("TOP", FAQFrame, "TOP", 0, -20)
    FAQTitle:SetWidth(400)
    FAQTitle:SetJustifyH("CENTER")
    FAQTitle:SetSpacing(4)
    FAQTitle:SetText("|cffFFD100猪猪助手常见问题与使用帮助|r")

    local FAQCloseBtn = CreateFrame("Button", nil, FAQFrame, "UIPanelCloseButton")
    FAQCloseBtn:SetPoint("TOPRIGHT", -5, -5)

    local FAQOkayBtn = CreateFrame("Button", nil, FAQFrame, "UIPanelButtonTemplate")
    FAQOkayBtn:SetSize(120, 30)
    FAQOkayBtn:SetPoint("BOTTOM", 0, 15)
    FAQOkayBtn:SetText("我知道了")
    FAQOkayBtn:SetScript("OnClick", function() FAQFrame:Hide() end)

    local FAQScrollFrame = CreateFrame("ScrollFrame", "MyAddonFAQScrollFrame", FAQFrame, "UIPanelScrollFrameTemplate")
    FAQScrollFrame:SetPoint("TOPLEFT", 25, -60)
    FAQScrollFrame:SetPoint("BOTTOMRIGHT", -30, 55)
    local FAQScrollChild = CreateFrame("Frame", nil, FAQScrollFrame)
    FAQScrollChild:SetSize(FAQScrollFrame:GetWidth(), 1)
    FAQScrollFrame:SetScrollChild(FAQScrollChild)

    local FAQContentText = FAQScrollChild:CreateFontString(nil, "ARTWORK")
    FAQContentText:SetFont(STANDARD_TEXT_FONT, fontSize, "")
    FAQContentText:SetJustifyH("LEFT")
    FAQContentText:SetJustifyV("TOP")
    FAQContentText:SetNonSpaceWrap(true)
    FAQContentText:SetWordWrap(true)
    FAQContentText:SetWidth(360)
    FAQContentText:SetPoint("TOPLEFT", FAQScrollChild, "TOPLEFT", 5, -5)

    local function RefreshFAQDisplay()
        local safeContent = string.gsub(faqContent, "\194\160", " ")
        safeContent = string.gsub(safeContent, "\r", "")
        FAQContentText:SetText(safeContent)
        C_Timer.After(0.05, function()
            local rawHeight = FAQContentText:GetStringHeight() or 100
            if rawHeight < 50 then rawHeight = 100 end
            FAQScrollChild:SetHeight(rawHeight + 30)
        end)
    end

    local FAQLogicFrame = CreateFrame("Frame")
    FAQLogicFrame:RegisterEvent("PLAYER_LOGIN")
    FAQLogicFrame:SetScript("OnEvent", function() RefreshFAQDisplay() end)
end

-- ============================================================
-- ★ 20. 按键绑定检查系统 (Core_Binding)
-- ============================================================
ZZ_BindingRegistry = ZZ_BindingRegistry or {}
ZZ_BindingRegistrationIndex = ZZ_BindingRegistrationIndex or 0

local EXPECTED_BINDING_COUNTS = {
    TITAN = { PALADIN = 200, DRUID = 200, MAGE = 200, WARRIOR = 200, PRIEST = 200, DEATHKNIGHT = 200, HUNTER = 200, ROGUE = 200, SHAMAN = 200, WARLOCK = 200 },
    MOP = { PALADIN = 200, DRUID = 200, MAGE = 200, WARRIOR = 200, PRIEST = 200, DEATHKNIGHT = 200, HUNTER = 200, ROGUE = 200, SHAMAN = 200, WARLOCK = 200, MONK = 200 },
}

local function Core_Bind_F001(classToken)
    local flavorCounts = EXPECTED_BINDING_COUNTS[ZZHELPER_FLAVOR or ""]
    return flavorCounts and flavorCounts[classToken] or nil
end

function InitBindingRegistry(classToken)
    ZZ_BindingRegistry = {}
    ZZ_BindingRegistrationIndex = 0
    ZZ_BindingRegistrationClass = classToken
    ZZ_BindingExpectedCount = Core_Bind_F001(classToken)
end

local function Core_Bind_F002(buttonName)
    return "CLICK "..buttonName..":LeftButton"
end

function CheckBindingByKey(key, printResult)
    local entry = ZZ_BindingRegistry and ZZ_BindingRegistry[key]
    if not entry then
        if printResult then
            print("|cffff0000[ZZ] 未登记按键：|r"..tostring(key))
        end
        return false, "未登记"
    end
    local button = _G[entry.buttonName]
    local actualAction = GetBindingAction(key, true) or ""
    local expectedAction = Core_Bind_F002(entry.buttonName)
    local actualText = button and button:GetAttribute("macrotext") or nil
    local reasons = {}
    if not button then reasons[#reasons + 1] = "按钮不存在" end
    if actualAction ~= expectedAction then reasons[#reasons + 1] = "实际绑定="..(actualAction ~= "" and actualAction or "无绑定") end
    if button and button:GetAttribute("type") ~= "macro" then reasons[#reasons + 1] = "按钮类型错误" end
    if actualText ~= entry.macroText then reasons[#reasons + 1] = "宏内容不一致" end
    local ok = #reasons == 0
    if printResult then
        local prefix = ok and "|cff00ff00绑定正确|r" or "|cffff0000绑定错误|r"
        print(string.format("[ZZ] %03d %s：%s%s", entry.index or 0, key, prefix, ok and "" or "（"..table.concat(reasons, "，").."）"))
    end
    return ok, table.concat(reasons, "，"), actualAction, actualText
end

function CheckAllBindings(showAll)
    local entries = {}
    for _, entry in pairs(ZZ_BindingRegistry or {}) do
        entries[#entries + 1] = entry
    end
    table.sort(entries, function(a, b) return (a.index or 0) < (b.index or 0) end)
    local passed = 0
    local failed = {}
    for _, entry in ipairs(entries) do
        local ok, reason = CheckBindingByKey(entry.key, false)
        if ok then passed = passed + 1
        else failed[#failed + 1] = {entry = entry, reason = reason} end
    end
    local registered = #entries
    local classToken = ZZ_BindingRegistrationClass or (UnitClassBase and UnitClassBase("player"))
    local expected = ZZ_BindingExpectedCount or Core_Bind_F001(classToken)
    local classText = classToken or "未知职业"
    local registrationComplete = expected ~= nil and ZZ_BindingRegistrationClass == classToken and (ZZ_BindingRegistrationIndex or 0) > 0
    local allPassed = registrationComplete and registered == expected and passed == expected
    if not allPassed then
        if not expected then
            print(string.format("|cffff0000[ZZ] %s按键检查：缺少独立期望数量配置。|r", classText))
        elseif not registrationComplete then
            print(string.format("|cffff0000[ZZ] %s按键检查：宏尚未完成初始化（已登记%d，应登记%d）。|r", classText, registered, expected))
        else
            print(string.format("|cffff0000[ZZ] %s按键检查：通过%d，失败%d，已登记%d，应登记%d。|r", classText, passed, #failed, registered, expected))
        end
    end
    if showAll then
        for _, entry in ipairs(entries) do CheckBindingByKey(entry.key, true) end
    elseif #failed > 0 then
        local limit = math.min(#failed, 20)
        for i = 1, limit do
            local failure = failed[i]
            print(string.format("|cffff0000  %03d %s：%s|r", failure.entry.index or 0, failure.entry.key, failure.reason))
        end
        if #failed > limit then
            print(string.format("|cffff0000  其余%d项未显示，使用 /zzcheckbind all 查看。|r", #failed - limit))
        end
    end
    return allPassed, passed, expected, failed
end

local OriginalCreateMacro = ZZ_CreateMacro
ZZ_CreateMacro = function(keyBinding, macroText)
    ZZ_BindingRegistrationIndex = (ZZ_BindingRegistrationIndex or 0) + 1
    local buttonName = "ZZ_HiddenMacroBtn_"..keyBinding
    ZZ_BindingRegistry = ZZ_BindingRegistry or {}
    ZZ_BindingRegistry[keyBinding] = {
        index = ZZ_BindingRegistrationIndex,
        key = keyBinding,
        buttonName = buttonName,
        macroText = macroText,
    }
    return OriginalCreateMacro(keyBinding, macroText)
end

function RegisterClassBinding(classToken, initializer)
    if type(initializer) ~= "function" then return end
    local initialized = false
    local checkSerial = 0
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("UPDATE_BINDINGS")
    local function ScheduleBindingCheck(delay)
        checkSerial = checkSerial + 1
        local serial = checkSerial
        C_Timer.After(delay or 1, function()
            if serial == checkSerial and initialized and CheckAllBindings then
                CheckAllBindings(false)
            end
        end)
    end
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "UPDATE_BINDINGS" then
            if initialized then ScheduleBindingCheck(0.5) end
            return
        end
        if initialized or UnitClassBase("player") ~= classToken or InCombatLockdown() then return end
        if InitBindingRegistry then InitBindingRegistry(classToken) end
        initializer()
        initialized = true
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        ScheduleBindingCheck(2)
    end)
    return eventFrame
end

SLASH_ZZCHECKBIND1 = "/zzcheckbind"
SlashCmdList.ZZCHECKBIND = function(msg)
    if not CheckAllBindings then
        print("|cffff0000[ZZ] 按键检查功能尚未加载。|r")
        return
    end
    CheckAllBindings(strlower(msg or "") == "all")
end

-- ============================================================
-- ★ 21. API 兼容性初始化代码
-- ============================================================
local apiInitialized = false

local function Core_InitAPI()
    if apiInitialized then return end
    apiInitialized = true

    if not GetSpellInfo then
        GetSpellInfo = function(spellIdentifier)
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(spellIdentifier)
                if info then
                    return info.name, nil, info.iconID, info.castTime, info.minCastTime, info.maxCastTime, info.cooldown, info.minRange, info.maxRange
                end
            end
            return nil
        end
    end

    if not GetSpellDescription then
        GetSpellDescription = function(spellIdentifier)
            if C_Spell and C_Spell.GetSpellDescription then
                return C_Spell.GetSpellDescription(spellIdentifier)
            end
            return nil
        end
    end

    if not GetSpellTexture then
        GetSpellTexture = function(spellIdentifier)
            if C_Spell and C_Spell.GetSpellTexture then
                local info = C_Spell.GetSpellInfo(spellIdentifier)
                if info then return info.iconID end
            end
            return nil
        end
    end

    if not GetSpellCooldown then
        GetSpellCooldown = function(spellIdentifier)
            if C_Spell and C_Spell.GetSpellCooldown then
                return C_Spell.GetSpellCooldown(spellIdentifier)
            end
            return 0, 0, 0, 0
        end
    end

    if not GetItemCooldown then
        GetItemCooldown = function(itemIdentifier)
            if C_Container and C_Container.GetItemCooldown then
                return C_Container.GetItemCooldown(itemIdentifier)
            elseif GetInventoryItemCooldown then
                return GetInventoryItemCooldown("player", itemIdentifier)
            end
            return 0, 0, 0, 0
        end
    end

    if not GetItemCount then
        GetItemCount = function(itemIdentifier, includeBank)
            if C_Container and C_Container.GetItemCount then
                return C_Container.GetItemCount(itemIdentifier, includeBank) or 0
            end
            return 0
        end
    end

    if not C_Timer then
        C_Timer = {}
        C_Timer.After = function(duration, callback)
            local f = CreateFrame("Frame")
            local elapsed = 0
            f:SetScript("OnUpdate", function(self, delta)
                elapsed = elapsed + delta
                if elapsed >= duration then
                    self:SetScript("OnUpdate", nil)
                    callback()
                end
            end)
        end
        C_Timer.NewTicker = function(interval, callback, iterations)
            local f = CreateFrame("Frame")
            local elapsed = 0
            local count = 0
            f:SetScript("OnUpdate", function(self, delta)
                elapsed = elapsed + delta
                if elapsed >= interval then
                    elapsed = 0
                    count = count + 1
                    callback()
                    if iterations and count >= iterations then
                        self:SetScript("OnUpdate", nil)
                    end
                end
            end)
            return f
        end
    end

    if not InCombatLockdown then
        InCombatLockdown = function()
            return UnitAffectingCombat("player")
        end
    end

    if not GetSpellCharges then
        GetSpellCharges = function(spellIdentifier)
            if C_Spell and C_Spell.GetSpellCharges then
                local charges, maxCharges, cooldownStart, cooldownDuration = C_Spell.GetSpellCharges(spellIdentifier)
                if charges then return charges, maxCharges, cooldownStart, cooldownDuration end
            end
            return nil
        end
    end
end

Core_InitAPI()

-- ============================================================
-- ★ 22. 滑块配置创建器 (Iconid_F006)
-- ============================================================
local function Iconid_F006(config)
    local classColor = GetClassColorRGB()
    local yOffset = -12 - 25 * (config.row - 1)

    local textFrame = config.parentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    textFrame:SetTextColor(classColor.r, classColor.g, classColor.b)
    textFrame:SetText(config.text)
    textFrame:SetShadowOffset(0, 0)
    textFrame:SetShadowColor(0, 0, 0, 0)
    textFrame:SetPoint("TOPRIGHT", config.parentFrame, "BOTTOMRIGHT", -config.width - 40, yOffset)

    local slider = CreateFrame("Slider", config.sliderName, config.parentFrame, "OptionsSliderTemplate")
    slider:SetPoint("LEFT", textFrame, "RIGHT", 8, yOffset + 14)
    slider:SetSize(config.width or 120, 20)
    slider:SetMinMaxValues(config.minValue or 0, config.maxValue or 100)
    slider:SetValueStep(config.step or 1)

    local currentValue = config.currentValue
    if currentValue == nil then
        currentValue = PigSet and PigSet[config.saveVariable] or config.defaultValue or 0
    end
    slider:SetValue(currentValue)

    local lowText = _G[slider:GetName().."Low"]
    local highText = _G[slider:GetName().."High"]
    if lowText then lowText:SetText(config.minLabel or tostring(config.minValue or 0)) end
    if highText then highText:SetText(config.maxLabel or tostring(config.maxValue or 100)) end

    local valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueText:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    valueText:SetTextColor(classColor.r, classColor.g, classColor.b)
    valueText:SetText(tostring(currentValue))
    valueText:SetShadowOffset(0, 0)
    valueText:SetShadowColor(0, 0, 0, 0)

    if config.tooltipText then
        slider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(config.tooltipText)
            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    slider:SetScript("OnValueChanged", function(self, value)
        valueText:SetText(tostring(math.floor(value + 0.5)))
        if config.onChange then
            config.onChange(math.floor(value + 0.5))
        end
    end)

    if config.saveVariable then
        slider:SetScript("OnMouseUp", function(self)
            local value = math.floor(self:GetValue() + 0.5)
            PigSet[config.saveVariable] = value
            if config.onSave then
                config.onSave(value)
            end
            if config.printOnSave ~= false then
                print(string.format("|cff00ff00%s|r 已设置为：|cffffd700%s|r", config.text, tostring(value)))
            end
        end)
    end

    if config.saveVariable then
        _G["SLASH_"..config.saveVariable.."1"] = "/"..config.saveVariable
        SlashCmdList[config.saveVariable] = function(msg)
            msg = strtrim(strlower(msg or ""))
            if msg == "" then
                print(string.format("当前值: |cffffd700%s|r", tostring(PigSet[config.saveVariable])))
                print(string.format("范围: %d - %d", config.minValue or 0, config.maxValue or 100))
                return
            end
            local val = tonumber(msg)
            if val then
                val = math.max(config.minValue or 0, math.min(config.maxValue or 100, val))
                PigSet[config.saveVariable] = val
                slider:SetValue(val)
                if config.onSave then config.onSave(val) end
                print(string.format("|cff00ff00%s|r 已设置为：|cffffd700%s|r", config.text, tostring(val)))
            end
        end
    end

    return slider, valueText
end

-- ============================================================
-- ★ 23. 配置面板创建 (Iconid_F007)
-- ============================================================
local function Iconid_F007(config)
    local classColor = GetClassColorRGB()
    local yOffset = -12 - 25 * (config.row - 1)
    local xOffset = config.xOffset or 0

    local sectionFrame = config.parentFrame:CreateFrame("Frame", nil, config.parentFrame)
    sectionFrame:SetPoint("TOPLEFT", config.parentFrame, "BOTTOMLEFT", xOffset, yOffset)
    sectionFrame:SetSize(config.sectionWidth or 380, config.sectionHeight or 24)

    local sectionBg = sectionFrame:CreateTexture(nil, "BACKGROUND")
    sectionBg:SetAllPoints(sectionFrame)
    sectionBg:SetColorTexture(classColor.r * 0.3, classColor.g * 0.3, classColor.b * 0.3, 0.5)

    local sectionText = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sectionText:SetPoint("LEFT", sectionFrame, "LEFT", 8, 0)
    sectionText:SetText(config.sectionTitle or "")
    sectionText:SetTextColor(classColor.r, classColor.g, classColor.b)
    sectionText:SetShadowOffset(0, 0)
    sectionText:SetShadowColor(0, 0, 0, 0)

    local dropdownItems = config.dropdownItems or {}
    local dropdown = nil
    if dropdownItems[1] then
        dropdown = CreateFrame("Frame", config.dropdownName, sectionFrame, "UIDropDownMenuTemplate")
        -- ★ 2026-08-21：取消下拉框外框边缘
        if type(WR_StyleDropdownFlat) == "function" then
            WR_StyleDropdownFlat(dropdown)
        end
        dropdown:SetPoint("RIGHT", sectionFrame, "RIGHT", -8, 0)
        dropdown:SetWidth(config.dropdownWidth or 120)

        local overlayBtn = CreateFrame("Button", nil, dropdown)
        -- 点击区直接占满整个下拉框
        overlayBtn:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, 0)
        overlayBtn:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", 0, 0)
        local btn = _G[dropdown:GetName().."Button"]
        overlayBtn:SetScript("OnClick", function() if btn then btn:Click() end end)

        local function InitializeDropdown()
            for i, item in ipairs(dropdownItems) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = item.text
                info.checked = ((PigSet[config.saveVariable] or config.defaultDropdownIndex or 1) == i)
                info.minWidth = config.dropdownWidth or 120
                info.func = function()
                    UIDropDownMenu_SetSelectedID(dropdown, i)
                    UIDropDownMenu_SetText(dropdown, item.text)
                    if config.saveVariable then
                        PigSet[config.saveVariable] = i
                        PrintToVisible(string.format("|cff00ff00%s|r 已设置为：|cffffd700%s|r", config.sectionTitle or config.text or "", item.text))
                    end
                    if config.onDropdownChange then
                        config.onDropdownChange(i, item.text)
                    end
                end
                UIDropDownMenu_AddButton(info)
            end
            local selectedID = UIDropDownMenu_GetSelectedID(dropdown) or config.defaultDropdownIndex or 1
            UIDropDownMenu_SetText(dropdown, dropdownItems[selectedID].text)
        end
        dropdown.Initialize = InitializeDropdown
        UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
        UIDropDownMenu_JustifyText(dropdown, "LEFT")

        local dropdownText = _G[dropdown:GetName().."Text"]
        if dropdownText then
            dropdownText:SetScale(0.85)
            dropdownText:ClearAllPoints()
            dropdownText:SetPoint("LEFT", dropdown:GetName().."Left", "LEFT", 41, 2)
            dropdownText:SetShadowOffset(0, 0)
            dropdownText:SetShadowColor(0, 0, 0, 0)
        end

        if config.saveVariable then
            if PigSet[config.saveVariable] == nil or type(PigSet[config.saveVariable]) ~= "number" then
                PigSet[config.saveVariable] = config.defaultDropdownIndex or 1
            end
            UIDropDownMenu_SetSelectedID(dropdown, PigSet[config.saveVariable])
            local sel = PigSet[config.saveVariable]
            if sel >= 1 and sel <= #dropdownItems then
                UIDropDownMenu_SetText(dropdown, dropdownItems[sel].text)
            end

            _G["SLASH_"..config.saveVariable.."1"] = "/"..config.saveVariable
            SlashCmdList[config.saveVariable] = function(msg)
                msg = strtrim(strlower(msg or ""))
                local id = tonumber(msg)
                if id and id >= 1 and id <= #dropdownItems then
                    PigSet[config.saveVariable] = id
                    UIDropDownMenu_SetSelectedID(dropdown, id)
                    UIDropDownMenu_SetText(dropdown, dropdownItems[id].text)
                    if config.onDropdownChange then
                        config.onDropdownChange(id, dropdownItems[id].text)
                    end
                    PrintToVisible(string.format("|cff00ff00%s|r 已设置为：|cffffd700%s|r", config.sectionTitle or config.text or "", dropdownItems[id].text))
                else
                    print("用法: /"..config.saveVariable.." <数字> (1-"..#dropdownItems..")")
                end
            end
        end
    end

    local checkboxes = {}
    if config.checkboxList then
        for i, cbConfig in ipairs(config.checkboxList) do
            local cb = CreateFrame("CheckButton", nil, sectionFrame, "UICheckButtonTemplate")
            local cbX = cbConfig.xOffset or (dropdown and 160 or 10) + (i - 1) * 100
            cb:SetPoint("LEFT", sectionFrame, "LEFT", cbX, 0)
            cb:SetSize(22, 22)

            local saveVar = cbConfig.saveVariable
            if saveVar then
                if PigSet[saveVar] == nil then
                    PigSet[saveVar] = cbConfig.defaultState or false
                end
                cb:SetChecked(PigSet[saveVar])
            end

            local cbText = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cbText:SetFont(cbText:GetFont(), 13)
            cbText:SetPoint("LEFT", cb, "RIGHT", 0, 0)
            cbText:SetText(cbConfig.label or "")
            cbText:SetWidth(cbConfig.labelWidth or 60)
            cbText:SetShadowOffset(0, 0)
            cbText:SetShadowColor(0, 0, 0, 0)

            if cbConfig.tooltipText then
                cb:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(cbConfig.tooltipText)
                    GameTooltip:Show()
                end)
                cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end

            cb:SetScript("OnClick", function(self)
                local state = self:GetChecked() and true or false
                if saveVar then
                    PigSet[saveVar] = state
                end
                if cbConfig.onChange then
                    cbConfig.onChange(state)
                end
                if cbConfig.printOnChange ~= false then
                    local statusText = state and "|cff00ff00开启|r" or "|cffff0000关闭|r"
                    print(string.format(statusText.." [%s]", cbConfig.label or saveVar))
                end
            end)

            if saveVar then
                _G["SLASH_"..saveVar.."1"] = "/"..saveVar
                SlashCmdList[saveVar] = function(msg)
                    msg = strtrim(strlower(msg or ""))
                    if msg == "on" then
                        PigSet[saveVar] = true
                        cb:SetChecked(true)
                        if cbConfig.onChange then cbConfig.onChange(true) end
                        print(string.format("|cff00ff00已启用 [%s]|r", cbConfig.label or saveVar))
                    elseif msg == "off" then
                        PigSet[saveVar] = false
                        cb:SetChecked(false)
                        if cbConfig.onChange then cbConfig.onChange(false) end
                        print(string.format("|cffff0000已关闭 [%s]|r", cbConfig.label or saveVar))
                    elseif msg == "" or msg == "toggle" then
                        local newState = not (PigSet[saveVar] or false)
                        PigSet[saveVar] = newState
                        cb:SetChecked(newState)
                        if cbConfig.onChange then cbConfig.onChange(newState) end
                    end
                end
            end

            checkboxes[i] = cb
        end
    end

    if config.showResetButton then
        local resetBtn = CreateFrame("Button", nil, sectionFrame, "UIPanelButtonTemplate")
        resetBtn:SetSize(72, 22)
        resetBtn:SetPoint("RIGHT", sectionFrame, "RIGHT", -8, 0)
        resetBtn:SetText("重置")
        resetBtn:SetScript("OnClick", function()
            if config.onReset then
                config.onReset()
            end
            for _, cb in ipairs(checkboxes) do
                cb:SetChecked(false)
            end
            print("|cff00ff00[MKHelperForever]|r "..(config.resetMessage or "配置已重置"))
        end)
        if dropdown then
            resetBtn:SetPoint("RIGHT", dropdown, "LEFT", -8, 0)
        end
    end

    return sectionFrame, dropdown, checkboxes
end

-- ============================================================
-- ★ 24. 初始化配置界面 (Iconid_F008/009/010)
-- ============================================================
local configUIInitialized = false

-- 核心配置默认值表（首次初始化与"恢复所有默认设置"共用，避免重复维护）
local CoreDefaults = {
    FrameAlpha = 100,
    ChatNoticeMode = 2,
    ScreenTextNotice = false,  -- ★ 2026-11-11：屏幕文字提示总闸，默认全部关闭（/screentip on 或面板复选框开启）
    MONSTER_BLOCK_ENABLED = false,  -- 怪物屏蔽总开关（原 WCL 冲分模式已并入此开关）
    DBM_PREPULL_POTION = false,
    TOUYAO_TIME = 3,       -- 全职业偷药/爆发预开窗口（DBM倒数秒数，0-3 可调，默认3）
    SS_ZLMS = 1,
    JL_ZLMS = 1,
    HF_ZLMS = 1,
    -- ★ 五治疗过量停条窗口（默认关闭，窗口值5=0.5秒）
    SS_GLTC = false,    -- 奶骑/神牧 过量停条开关
    SS_GLTCCK = 5,      -- 奶骑/神牧 停条窗口(1=0.1秒 ~ 5=0.5秒)
    HF_GLTC = false,    -- 奶萨/奶德 过量停条开关
    HF_GLTCCK = 5,      -- 奶萨/奶德 停条窗口
    JL_GLTC = false,    -- 戒律牧 过量停条开关
    JL_GLTCCK = 5,      -- 戒律牧 停条窗口
    -- ★ 治疗职业自动救人开关（全局，所有治疗专精共用）
    ZL_ZDJS = true,     -- 治疗职业脱战自动救人
    -- ★ 自动切目标开关（默认关闭，各专精独立控制）
    -- 坦克
    DK_Blood_TAB = false,   -- 血DK 自动切目标
    FZ_TAB = false,         -- 防战 自动切目标
    FH_TAB = false,         -- 防骑 自动切目标
    -- 近战DPS
    DK_BDK_TAB = false,     -- 冰DK 自动切目标
    DK_XDK_TAB = false,     -- 邪DK 自动切目标
    WQZ_TAB = false,        -- 武器战 自动切目标
    KN_TAB = false,         -- 狂暴战 自动切目标
    CJ_TAB = false,         -- 惩戒骑 自动切目标
    DZ_CS_TAB = false,      -- 奇袭贼 自动切目标
    DZ_ZD_TAB = false,      -- 战斗贼 自动切目标
    DZ_MR_TAB = false,      -- 敏锐贼 自动切目标
    YD_TAB = false,         -- 野性德(猫) 自动切目标
    SM_ZQ_TAB = false,      -- 增强萨 自动切目标
    -- 远程DPS（默认开启）
    PH_TAB = true,          -- 平衡德 自动切目标
    AF_TAB = true,          -- 奥法 自动切目标
    HY_TAB = true,          -- 火法 自动切目标
    BF_TAB = true,          -- 冰法 自动切目标
    LR_SWL_TAB = true,      -- 兽王猎 自动切目标
    LR_SJL_TAB = true,      -- 射击猎 自动切目标
    LR_SCL_TAB = true,      -- 生存猎 自动切目标
    SS_TK_TAB = true,       -- 痛苦术 自动切目标
    SS_EM_TAB = true,       -- 恶魔术 自动切目标
    SS_HM_TAB = true,       -- 毁灭术 自动切目标
    -- ★ 术士武器石选择（1=关闭/2=法术石[副手]/3=火焰石[主手]）
    WL_AFL_ZDFSS = 2,   -- 痛苦 默认法术石
    WL_EM_ZDFSS  = 2,   -- 恶魔学识 默认法术石
    SS_HM_HRS    = 3,   -- 毁灭 默认火焰石
    MS_TAB = true,          -- 暗牧 自动切目标
    SM_YS_TAB = true,       -- 元素萨 自动切目标
}

-- 首次初始化：仅在字段为 nil 时补默认值（插件加载/首次开面板时调用）
local function Core_ConfigUI_Init()
    if configUIInitialized then return end
    configUIInitialized = true

    if PigSet == nil then PigSet = {} end
    for k, v in pairs(CoreDefaults) do
        if PigSet[k] == nil then
            PigSet[k] = v
        end
    end
end

-- 强制重置：把所有核心配置覆盖为默认值（"恢复所有默认设置"按钮调用）
-- 与 Core_ConfigUI_Init 不同：不判断 nil，直接覆盖
local function Core_ConfigUI_Reset()
    if PigSet == nil then PigSet = {} end
    for k, v in pairs(CoreDefaults) do
        PigSet[k] = v
    end
end

function Iconid_F008()
    Core_ConfigUI_Init()

    local classColor = GetClassColorRGB()
    -- ★ 2026-08-21：去掉 UIPanelDialogTemplate 外框体，仅用 BackdropTemplate 画深色底
    local configFrame = CreateFrame("Frame", "ZZ_ConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(600, 500)
    configFrame:SetPoint("CENTER")
    configFrame:SetFrameStrata("DIALOG")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:Hide()

    if configFrame.SetBackdrop then
        configFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = nil,
            tile = true,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        configFrame:SetBackdropColor(0.28, 0.28, 0.28, 1)
    else
        local darkBg = configFrame:CreateTexture(nil, "BACKGROUND")
        darkBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        darkBg:SetVertexColor(0.28, 0.28, 0.28, 1)
        darkBg:SetAllPoints(configFrame)
    end

    -- ★ 2026-08-21：标题放左上角、字号放大
    configFrame.title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    configFrame.title:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 16, -14)
    configFrame.title:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    configFrame.title:SetText("|cffffd100猪猪助手 - 功能配置|r")
    configFrame.title:SetShadowOffset(0, 0)
    configFrame.title:SetShadowColor(0, 0, 0, 0)

    -- ★ 2026-08-21：自建关闭按钮（去掉 UIPanelDialogTemplate 后无内置 Close）
    local close = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() configFrame:Hide() end)

    local scroll = CreateFrame("ScrollFrame", "ZZ_ConfigScrollFrame", configFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -40)
    scroll:SetPoint("BOTTOMRIGHT", -16, 16)
    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(scroll:GetWidth(), 1)
    scroll:SetScrollChild(scrollChild)

    local configSections = {}
    local yPos = 0

    local function AddSection(title, items)
        local sectionFrame = scrollChild:CreateFrame("Frame", nil, scrollChild)
        sectionFrame:SetSize(scrollChild:GetWidth() - 20, 30)
        sectionFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yPos)

        local titleBg = sectionFrame:CreateTexture(nil, "BACKGROUND")
        titleBg:SetAllPoints(sectionFrame)
        titleBg:SetColorTexture(classColor.r * 0.2, classColor.g * 0.2, classColor.b * 0.2, 0.6)

        local titleText = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleText:SetPoint("LEFT", sectionFrame, "LEFT", 10, 0)
        titleText:SetText("|cffffd100"..title.."|r")
        titleText:SetShadowOffset(0, 0)
        titleText:SetShadowColor(0, 0, 0, 0)

        yPos = yPos + 35

        if items then
            for _, item in ipairs(items) do
                if item.type == "dropdown" then
                    Iconid_F007({
                        parentFrame = scrollChild,
                        row = math.floor(yPos / 25),
                        sectionTitle = item.label,
                        saveVariable = item.saveVariable,
                        dropdownItems = item.options,
                        defaultDropdownIndex = item.defaultIndex,
                        xOffset = 10,
                        sectionWidth = 350,
                        dropdownWidth = 120,
                        onDropdownChange = item.onChange,
                    })
                    yPos = yPos + 25
                elseif item.type == "slider" then
                    Iconid_F006({
                        parentFrame = scrollChild,
                        row = math.floor(yPos / 25),
                        text = item.label,
                        saveVariable = item.saveVariable,
                        minValue = item.min,
                        maxValue = item.max,
                        step = item.step,
                        defaultValue = item.default,
                        tooltipText = item.tooltip,
                        width = 150,
                    })
                    yPos = yPos + 25
                elseif item.type == "checkbox" then
                    local cb = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
                    cb:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yPos)
                    cb:SetSize(22, 22)
                    if PigSet[item.saveVariable] == nil then
                        PigSet[item.saveVariable] = item.defaultState or false
                    end
                    cb:SetChecked(PigSet[item.saveVariable])
                    local cbText = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    cbText:SetFont(cbText:GetFont(), 13)
                    cbText:SetPoint("LEFT", cb, "RIGHT", 4, 0)
                    cbText:SetText(item.label)
                    cbText:SetWidth(200)
                    cbText:SetShadowOffset(0, 0)
                    cbText:SetShadowColor(0, 0, 0, 0)
                    cb:SetScript("OnEnter", function(self)
                        if item.tooltip then
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:SetText(item.tooltip)
                            GameTooltip:Show()
                        end
                    end)
                    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
                    cb:SetScript("OnClick", function(self)
                        local newState = self:GetChecked() and true or false
                        PigSet[item.saveVariable] = newState
                        if item.onChange then item.onChange(newState) end
                        local statusText = newState and "|cff00ff00开启|r" or "|cffff0000关闭|r"
                        PrintToVisible(string.format(statusText .. " [%s]", item.label))
                    end)
                    yPos = yPos + 25
                end
            end
        end
    end

    local paladinItems = {
        { type = "dropdown", label = "治疗权重模式", saveVariable = "SS_ZLMS", options = {{text="默认"},{text="坦克优先"},{text="非坦克优先"},{text="当前目标优先"},{text="焦点目标"},{text="组1+1"},{text="组2+1"},{text="组3+1"},{text="组4+1"},{text="组5+1"}}, defaultIndex = 1 },
    }
    local priestItems = {
        { type = "dropdown", label = "治疗权重模式", saveVariable = "JL_ZLMS", options = {{text="默认"},{text="坦克优先"},{text="非坦克优先"},{text="当前目标优先"}}, defaultIndex = 1 },
    }
    local druidShamanItems = {
        { type = "dropdown", label = "治疗权重模式", saveVariable = "HF_ZLMS", options = {{text="默认"},{text="坦克优先"},{text="非坦克优先"},{text="当前目标优先"}}, defaultIndex = 1 },
    }

    local _, playerClass = UnitClass("player")
    if playerClass == "PALADIN" then
        AddSection("圣骑士设置", paladinItems)
    elseif playerClass == "PRIEST" then
        AddSection("牧师设置", priestItems)
    elseif playerClass == "DRUID" or playerClass == "SHAMAN" then
        AddSection("德鲁伊/萨满设置", druidShamanItems)
    end

    AddSection("通用设置", {
        { type = "slider", label = "框架透明度", saveVariable = "FrameAlpha", min = 10, max = 100, step = 5, default = 100, tooltip = "调整所有框架的透明度" },
        { type = "checkbox", label = "启用怪物屏蔽", saveVariable = "MONSTER_BLOCK_ENABLED", defaultState = false, tooltip = "开启后按规则屏蔽指定怪物的目标选择" },
    })

    local resetAllBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    resetAllBtn:SetSize(120, 28)
    resetAllBtn:SetPoint("BOTTOM", configFrame, "BOTTOM", 0, 45)
    resetAllBtn:SetText("恢复所有默认设置")
    resetAllBtn:SetScript("OnClick", function()
        Core_ConfigUI_Reset()
        print("|cff00ff00[MKHelperForever]|r 所有设置已恢复默认值。")
    end)

    local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    closeBtn:SetSize(120, 28)
    closeBtn:SetPoint("BOTTOM", configFrame, "BOTTOM", 0, 12)
    closeBtn:SetText("关闭")
    closeBtn:SetScript("OnClick", function() configFrame:Hide() end)

    scrollChild:SetHeight(yPos + 60)

    configFrame:SetScript("OnShow", function()
        Core_ConfigUI_Init()
    end)

    return configFrame
end

function Iconid_F009()
    local frame = Iconid_F008()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

function Iconid_F010()
    Core_ConfigUI_Init()
    local frame = Iconid_F008()
    frame:Show()
    print("|cff00ff00[MKHelperForever]|r 配置面板已打开。")
    print("输入 /pigconfig 或 /pigcfg 打开/关闭配置面板")
end

SLASH_PIGCONFIG1 = "/pigconfig"
SLASH_PIGCONFIG2 = "/pigcfg"
SlashCmdList["PIGCONFIG"] = function()
    Iconid_F009()
end

-- ============================================================
-- ★ 25. Core_GroupRoles 辅助函数
-- ============================================================

-- 获取法术描述中的数值（提取括号内的数字）
function GetSpellDescriptionValue(spellName, pattern)
    if not spellName then return nil end
    local desc = GetSpellDescription(spellName)
    if not desc then return nil end
    if pattern then
        local value = string.match(desc, pattern)
        if value then return tonumber(value) end
    end
    local value = string.match(desc, "(%d+%.?%d*)")
    if value then return tonumber(value) end
    return nil
end

-- ============================================================
-- ★ 天赋查询缓存（避免每帧重复调用 GetTalentInfo 等高开销 API）
-- ============================================================
local WR_TalentCache = {}
local WR_TalentCacheTime = 0
local TALENT_CACHE_TTL = 30  -- 30秒 TTL，天赋不会频繁变化

local function WR_InvalidateTalentCache()
    wipe(WR_TalentCache)
    WR_TalentCacheTime = 0
end

-- 监听天赋变化事件，自动清除缓存
do
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHARACTER_POINTS_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function() WR_InvalidateTalentCache() end)
end

-- 获取天赋描述中的数值
function GetTalentDescriptionValue(talentID, pattern)
    if not talentID then return nil end
    local cacheKey = "desc_" .. tostring(talentID) .. "_" .. tostring(pattern or "")
    local now = GetTime()
    if now > WR_TalentCacheTime then
        wipe(WR_TalentCache)
        WR_TalentCacheTime = now + TALENT_CACHE_TTL
    end
    if WR_TalentCache[cacheKey] ~= nil then
        return WR_TalentCache[cacheKey]
    end
    local name, _, _, _, _, _, _, _, desc = GetTalentInfoByID(talentID)
    if not desc then
        local _, _, _, _, _, info = GetTalentInfo(talentID)
        if info then
            desc = info.description
        end
    end
    if not desc then
        WR_TalentCache[cacheKey] = false
        return nil
    end
    local result
    if pattern then
        local value = string.match(desc, pattern)
        if value then result = tonumber(value) end
    end
    if not result then
        local value = string.match(desc, "(%d+%.?%d*)")
        if value then result = tonumber(value) end
    end
    WR_TalentCache[cacheKey] = result or false
    return result
end

-- 检查单位是否有绑定物品
function UnitHasBindNet(unit)
    if not unit or not UnitExists(unit) then return false end
    for slot = 1, 18 do
        local itemID = GetInventoryItemID(unit, slot)
        if itemID then
            local itemBondingType = select(7, C_Container.GetItemInfo(itemID))
            if itemBondingType and itemBondingType ~= 0 then
                return true
            end
        end
    end
    return false
end

-- 获取单位损失的生命值（绝对值）
function GetLostHealth(unit)
    if not unit or not UnitExists(unit) then return 0 end
    local maxHP = WR_SafeNumber(UnitHealthMax(unit), 1)
    local currentHP = WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1))
    if maxHP <= 0 then return 0 end
    return math.max(0, maxHP - currentHP)
end

-- WR版本获取单位损失的生命值
-- 注：Core_Functions.lua 中已有一版（含吸收盾，精度更高），本文件加载更晚会覆盖它。
-- 用 if not 守卫，保留 Core 版作为权威实现，避免精度下降。
if not WR_GetUnitLostHealth then
    function WR_GetUnitLostHealth(unit)
        return GetLostHealth(unit)
    end
end

-- 获取团队平均损失生命值百分比
function GetGroupAvgLostHealthPct()
    local totalLostPct = 0
    local memberCount = 0
    local groupType = GetGroupType and GetGroupType() or "none"

    if groupType == "raid" then
        for i = 1, math.min(GetNumGroupMembers() or 0, 25) do
            local unit = "raid"..i
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
                local maxHP = WR_SafeNumber(UnitHealthMax(unit), 1)
                if maxHP > 0 then
                    local lostPct = (maxHP - WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1))) / maxHP * 100
                    totalLostPct = totalLostPct + lostPct
                    memberCount = memberCount + 1
                end
            end
        end
    elseif groupType == "party" then
        if UnitExists("player") and not UnitIsDeadOrGhost("player") then
            local maxHP = WR_SafeNumber(UnitHealthMax("player"), 1)
            if maxHP > 0 then
                totalLostPct = (maxHP - WR_SafeNumber(UnitHealth("player"), WR_SafeNumber(UnitHealthMax("player"), 1))) / maxHP * 100
                memberCount = 1
            end
        end
        for i = 1, math.max((GetNumGroupMembers() or 0) - 1, 0) do
            local unit = "party"..i
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
                local maxHP = WR_SafeNumber(UnitHealthMax(unit), 1)
                if maxHP > 0 then
                    local lostPct = (maxHP - WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1))) / maxHP * 100
                    totalLostPct = totalLostPct + lostPct
                    memberCount = memberCount + 1
                end
            end
        end
    end

    if memberCount == 0 then return 0 end
    return totalLostPct / memberCount
end

-- 判断目标是否为Boss
function IsTargetBoss()
    if not UnitExists("target") then return false end
    local classification = UnitClassification("target")
    if classification == "worldboss" or classification == "elite" then
        return true
    end
    local level = UnitLevel("target")
    if level and level > 0 then
        local playerLevel = UnitLevel("player")
        if playerLevel and level >= playerLevel + 3 then
            return true
        end
    end
    return false
end

-- 获取抵抗法术的时间
function GetResistSpellTime(unit, spellName)
    if not unit or not spellName then return 0 end
    local resistTime = GetDebuffTime(unit, "法术易伤")
    if resistTime and resistTime > 0 then return resistTime end
    return 0
end

-- 检查治疗药水是否可用
function HasHealingPotionReady()
    local potions = { [1] = 40087, [2] = 40088, [3] = 40089 }
    for _, id in ipairs(potions) do
        local count = GetItemCount(id)
        if count and count > 0 then
            local start, duration = GetItemCooldown(id)
            if start + duration - GetTime() <= 0 then
                return true
            end
        end
    end
    return false
end

-- 检查洞穴居民药水是否可用
function HasCaveDwellerPotionReady()
    local id = 58058
    local count = GetItemCount(id)
    if count and count > 0 then
        local start, duration = GetItemCooldown(id)
        if start + duration - GetTime() <= 0 then
            return true
        end
    end
    return false
end

-- 检查清醒药水是否可用
function HasQuenchingPotionReady()
    local id = 67841
    local count = GetItemCount(id)
    if count and count > 0 then
        local start, duration = GetItemCooldown(id)
        if start + duration - GetTime() <= 0 then
            return true
        end
    end
    return false
end

-- 注册事件通知
function RegisterEventNotifications(eventList)
    if not eventList or type(eventList) ~= "table" then return end
    if not ZZ_EventNotifierFrame then
        ZZ_EventNotifierFrame = CreateFrame("Frame")
        ZZ_EventNotifierFrame:SetScript("OnEvent", function(self, event, ...)
            local handlers = ZZ_EventNotifierFrame.handlers and ZZ_EventNotifierFrame.handlers[event]
            if handlers then
                for _, handler in ipairs(handlers) do
                    local ok, err = pcall(handler, ...)
                    if not ok then
                        print("|cffff0000[ZZ事件]|r 处理错误: "..tostring(err))
                    end
                end
            end
        end)
        ZZ_EventNotifierFrame.handlers = {}
    end
    local frame = ZZ_EventNotifierFrame
    for event, handler in pairs(eventList) do
        frame:RegisterEvent(event)
        frame.handlers[event] = frame.handlers[event] or {}
        frame.handlers[event][#frame.handlers[event] + 1] = handler
    end
end

-- 注册危险法术追踪器
function RegisterDangerSpellTracker(spellIDs, callback)
    if not spellIDs or not callback then return end
    if not ZZ_DangerSpellFrame then
        ZZ_DangerSpellFrame = CreateFrame("Frame")
        WR_RegisterEventSafe(ZZ_DangerSpellFrame, "COMBAT_LOG_EVENT_UNFILTERED")
        ZZ_DangerSpellFrame:SetScript("OnEvent", function(self)
            local timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = unpack(WR_CombatLogEvent)
            if subevent == "SPELL_CAST_START" or subevent == "SPELL_CAST_SUCCESS" then
                if ZZ_DangerSpellFrame.trackedSpells and ZZ_DangerSpellFrame.trackedSpells[spellID] then
                    local ok, err = pcall(callback, spellID, spellName, sourceName, destName, subevent)
                    if not ok then
                        print("|cffff0000[ZZ危险法术]|r 回调错误: "..tostring(err))
                    end
                end
            end
        end)
        ZZ_DangerSpellFrame.trackedSpells = {}
    end
    for _, id in ipairs(spellIDs) do
        ZZ_DangerSpellFrame.trackedSpells[id] = true
    end
end

-- 检查是否需要团队Buff
function NeedGroupBuff(buffName)
    if not buffName then return false end
    local groupType = GetGroupType and GetGroupType() or "none"
    local needCount = 0
    local totalCount = 0

    local function CheckUnit(unit)
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            totalCount = totalCount + 1
            if GetBuffTime(unit, buffName, true) <= 0 then
                needCount = needCount + 1
            end
        end
    end

    if groupType == "raid" then
        for i = 1, math.min(GetNumGroupMembers() or 0, 25) do
            CheckUnit("raid"..i)
        end
    elseif groupType == "party" then
        CheckUnit("player")
        for i = 1, math.max((GetNumGroupMembers() or 0) - 1, 0) do
            CheckUnit("party"..i)
        end
    end

    return needCount > 0 and math.ceil(totalCount * 0.2) < needCount
end

-- 检查是否可以驱散单位
function CanDispelUnit(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsDeadOrGhost(unit) then return false end
    local _, playerClass = UnitClass("player")
    local dispelDebuffs = {
        PALADIN = { "疾病", "毒素" },
        PRIEST = { "疾病", "魔法" },
        SHAMAN = { "疾病", "毒素", "魔法" },
        DRUID = { "疾病", "毒素", "诅咒" },
        MAGE = { "诅咒" },
        WARLOCK = { "魔法" },
        MONK = { "疾病", "毒素" },
    }
    local types = dispelDebuffs[playerClass]
    if not types then return false end
    for _, debuffType in ipairs(types) do
        if GetDebuffTimeByType(unit, debuffType) > 0 then
            return true
        end
    end
    return false
end

-- 判断是否应驱散危险减益
function ShouldDispelDangerousDebuff(unit)
    if not unit then return false end
    local dangerousDebuffs = {
        [72149] = "血肉成灰",
        [72150] = "血肉成灰",
        [66237] = "血肉成灰",
        [66013] = "刺骨之寒",
        [71278] = "窒息毒气",
        [72451] = "畸变瘟疫",
        [69240] = "邪恶毒气",
        [69290] = "枯萎的孢子",
    }
    for debuffID, name in pairs(dangerousDebuffs) do
        if GetDebuffTime(unit, debuffID) > 0 then
            return true, name
        end
    end
    return false
end

-- 获取最后施放的法术名称
function GetLastSpellName()
    if ZZ_LastSpellInfo and ZZ_LastSpellInfo.name then
        return ZZ_LastSpellInfo.name, ZZ_LastSpellInfo.time
    end
    return nil, 0
end

-- 注册暮光斩杀追踪器
function RegisterTwilightSlaughterTracker()
    if ZZ_TwilightSlaughterRegistered then return end
    ZZ_TwilightSlaughterRegistered = true
    local frame = CreateFrame("Frame")
    WR_RegisterEventSafe(frame, "COMBAT_LOG_EVENT_UNFILTERED")
    frame:SetScript("OnEvent", function(self)
        local timestamp, subevent, _, _, sourceName, _, _, _, destName = unpack(WR_CombatLogEvent)
        if subevent == "SPELL_CAST_SUCCESS" and destName == "阿努巴拉克" then
            if GetDebuffTime("target", 66013) > 0 then
                print("|cffff0000[ZZ] 阿努巴拉克施放暮光斩杀！|r")
            end
        end
    end)
end

-- 注册疯狂Buff追踪器
function RegisterCrazyBuffTracker(buffNames, callback)
    if not buffNames then return end
    if not ZZ_CrazyBuffFrame then
        ZZ_CrazyBuffFrame = CreateFrame("Frame")
        ZZ_CrazyBuffFrame.buffList = {}
        ZZ_CrazyBuffFrame.callbacks = {}
        ZZ_CrazyBuffFrame.elapsed = 0
        ZZ_CrazyBuffFrame:SetScript("OnUpdate", function(self, delta)
            self.elapsed = self.elapsed + delta
            if self.elapsed >= 0.2 then
                self.elapsed = 0
                for unit in pairs(ZZ_GroupUnits or {}) do
                    for _, buffName in ipairs(self.buffList) do
                        if GetBuffTime(unit, buffName) > 0 then
                            for _, cb in ipairs(self.callbacks) do
                                local ok, err = pcall(cb, unit, buffName)
                                if not ok then print("|cffff0000[ZZ追踪]|r "..tostring(err)) end
                            end
                        end
                    end
                end
            end
        end)
    end
    for _, name in ipairs(buffNames) do
        ZZ_CrazyBuffFrame.buffList[#ZZ_CrazyBuffFrame.buffList + 1] = name
    end
    if callback then
        ZZ_CrazyBuffFrame.callbacks[#ZZ_CrazyBuffFrame.callbacks + 1] = callback
    end
end

-- 注册光环应用追踪器（通过共享 UNIT_AURA 调度器）
function RegisterAuraAppliedTracker(auraNames, callback)
    if not auraNames or not callback then return end
    local trackerData = {
        auraList = {},
        callback = callback,
    }
    for _, name in ipairs(auraNames) do
        trackerData.auraList[#trackerData.auraList + 1] = name
    end
    WR_RegisterUnitAuraHandler(function(unit)
        if not UnitExists(unit) then return end
        for _, auraName in ipairs(trackerData.auraList) do
            if GetBuffTime(unit, auraName) > 0 or GetDebuffTime(unit, auraName) > 0 then
                local ok, err = pcall(trackerData.callback, unit, auraName)
                if not ok then print("|cffff0000[ZZ光环]|r "..tostring(err)) end
            end
        end
    end, "player")
end

-- 计算团队Buff数量
function CountGroupBuff(buffName)
    if not buffName then return 0 end
    local count = 0
    local groupType = GetGroupType and GetGroupType() or "none"

    local function CheckUnit(unit)
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            if GetBuffTime(unit, buffName, true) > 0 then
                count = count + 1
            end
        end
    end

    if groupType == "raid" then
        for i = 1, math.min(GetNumGroupMembers() or 0, 25) do
            CheckUnit("raid"..i)
        end
    elseif groupType == "party" then
        CheckUnit("player")
        for i = 1, math.max((GetNumGroupMembers() or 0) - 1, 0) do
            CheckUnit("party"..i)
        end
    end
    return count
end

-- 计算队伍范围内成员数量
function CountPartyInRange(range)
    range = range or 40
    local count = 0
    local groupType = GetGroupType and GetGroupType() or "none"

    local function CheckUnit(unit)
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            if GetUnitRange(unit) <= range then
                count = count + 1
            end
        end
    end

    if groupType == "raid" then
        for i = 1, math.min(GetNumGroupMembers() or 0, 25) do
            CheckUnit("raid"..i)
        end
    elseif groupType == "party" then
        CheckUnit("player")
        for i = 1, math.max((GetNumGroupMembers() or 0) - 1, 0) do
            CheckUnit("party"..i)
        end
    end
    return count
end

-- 单位是否无敌
function IsUnitInvincible(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsInvulnerable(unit) then return true end
    if GetBuffTime(unit, "圣盾术") > 0 then return true end
    if GetBuffTime(unit, "保护之手") > 0 then return true end
    if GetBuffTime(unit, "寒冰屏障") > 0 then return true end
    if GetBuffTime(unit, "虚空偏好") > 0 then return true end
    return false
end

-- 单位是否在战斗中
function IsUnitInCombat(unit)
    if not unit or not UnitExists(unit) then return false end
    if unit == "player" then return UnitAffectingCombat("player") end
    return UnitAffectingCombat(unit)
end

-- 玩家是否在移动
function IsMoving()
    local speed = GetPlayerMapSpeed and GetPlayerMapSpeed() or 0
    if speed and speed > 0 then return true end
    local _, vertical = GetPlayerWorldTransform and GetPlayerWorldTransform() or 0, 0
    if vertical and (math.abs(vertical) > 0.01) then return true end
    return false
end

-- 计算范围内敌人数量
function CountEnemiesInRange(range)
    range = range or 10
    local count = 0
    if EnemiesInRange then
        count = #EnemiesInRange
    else
        for i = 1, 4 do
            local unit = "party"..i.."target"
            if UnitExists(unit) and UnitCanAttack("player", unit) then
                if GetUnitRange(unit) <= range then
                    count = count + 1
                end
            end
        end
        if UnitExists("target") and UnitCanAttack("player", "target") then
            if GetUnitRange("target") <= range then
                local alreadyCounted = false
                for i = 1, 4 do
                    if UnitIsUnit("party"..i.."target", "target") then
                        alreadyCounted = true
                        break
                    end
                end
                if not alreadyCounted then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- 计算框架高度
function CalcFrameHeight(baseHeight, rowCount, rowHeight)
    baseHeight = baseHeight or 20
    rowHeight = rowHeight or 24
    return baseHeight + math.max(0, rowCount - 1) * rowHeight
end

-- 获取顶级天赋信息
function GetTopTalentInfo()
    local cacheKey = "topTalent"
    local now = GetTime()
    if now > WR_TalentCacheTime then
        wipe(WR_TalentCache)
        WR_TalentCacheTime = now + TALENT_CACHE_TTL
    end
    if WR_TalentCache[cacheKey] ~= nil then
        return WR_TalentCache[cacheKey] or nil
    end
    local _, playerClass = UnitClass("player")
    if not playerClass then
        WR_TalentCache[cacheKey] = false
        return nil
    end
    local maxTier = 0
    local topTalent = nil

    if GetSpecialization then
        local specIndex = GetSpecialization()
        if specIndex then
            for tier = 1, 10 do
                for col = 1, 3 do
                    local talentID, _, _, _, _, _, _, _, name, _, _, _ = GetTalentInfo(tier, col, specIndex)
                    if talentID and name then
                        local _, _, _, _, _, points = GetTalentInfo(tier, col, specIndex)
                        if points and points > 0 then
                            if tier > maxTier or (tier == maxTier and col == 2) then
                                maxTier = tier
                                topTalent = { id = talentID, name = name, tier = tier, col = col }
                            end
                        end
                    end
                end
            end
        end
    end
    WR_TalentCache[cacheKey] = topTalent or false
    return topTalent
end

-- 检查治疗石是否可用
function HasHealthstoneReady()
    local id = 5512
    local count = GetItemCount(id)
    if count and count > 0 then
        return true
    end
    return false
end

-- 检查鼠标悬停是否适合AOE
function IsMouseoverValidForAM()
    if not UnitExists("mouseover") then return false end
    if not UnitCanAttack("player", "mouseover") then return false end
    if UnitIsDead("mouseover") then return false end
    if IsMonsterBlocked(UnitName("mouseover"), "target") then return false end
    return true
end

-- 获取天赋等级
function GetTalentRank(talentID)
    if not talentID then return 0 end
    local cacheKey = "rank_" .. tostring(talentID)
    local now = GetTime()
    if now > WR_TalentCacheTime then
        wipe(WR_TalentCache)
        WR_TalentCacheTime = now + TALENT_CACHE_TTL
    end
    if WR_TalentCache[cacheKey] ~= nil then
        return WR_TalentCache[cacheKey]
    end
    local result = 0
    if GetSpecialization then
        local specIndex = GetSpecialization()
        if specIndex then
            for tier = 1, 10 do
                for col = 1, 3 do
                    local id, _, _, _, _, _, _, _, _, _, _, _, points = GetTalentInfo(tier, col, specIndex)
                    if id == talentID then
                        result = points or 0
                        break
                    end
                end
                if result > 0 then break end
            end
        end
    end
    WR_TalentCache[cacheKey] = result
    return result
end

-- 判断是否应眩晕单位
function ShouldStunUnit(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsDeadOrGhost(unit) then return false end
    if IsUnitInvincible(unit) then return false end
    local classification = UnitClassification(unit)
    if classification == "worldboss" then
        local _, playerClass = UnitClass("player")
        if playerClass ~= "ROGUE" and playerClass ~= "DRUID" then
            return false
        end
    end
    if UnitCanAttack("player", unit) then
        return true
    end
    return false
end

-- 单位是否有最高优先级Debuff
function UnitHasHighestPriorityDebuff(unit)
    if not unit then return false end
    local highestPriorityDebuff = {
        [72149] = "血肉成灰",
        [72150] = "血肉成灰",
        [66237] = "血肉成灰",
        [66013] = "刺骨之寒",
    }
    for debuffID in pairs(highestPriorityDebuff) do
        if GetDebuffTime(unit, debuffID) > 0 then
            return true
        end
    end
    return false
end

-- 焦点是否有最高优先级Debuff
function FocusHasHighestPriorityDebuff()
    return UnitHasHighestPriorityDebuff("focus")
end

-- 获取水元素状态
function GetHydrossState()
    local hydrossNames = { "不稳定的海度斯", "纯净的海度斯爪牙", "被污染的海度斯爪牙" }
    for _, name in ipairs(hydrossNames) do
        if UnitExists("target") and (WR_SafeUnitName and WR_SafeUnitName("target") or UnitName("target")) == name then
            if GetBuffTime("target", "腐蚀") > 0 then
                return "corrupted"
            end
            return "pure"
        end
    end
    return "unknown"
end

-- 检查单位是否为有效目标
function IsUnitValidTarget(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsDeadOrGhost(unit) then return false end
    if UnitIsCharmed(unit) then return false end
    if not UnitCanAttack("player", unit) then return false end
    if IsMonsterBlocked(UnitName(unit), "target") then return false end
    return true
end

-- 获取形态名称
function GetShapeshiftFormName()
    local form = GetShapeshiftFormID and GetShapeshiftFormID() or 0
    if form == 0 then return "人形态" end
    local formNames = {
        [1] = "熊形态",
        [2] = "水生形态",
        [3] = "猎豹形态",
        [4] = "旅行形态",
        [5] = "树形态",
        [6] = "猫形态",
        [7] = "飞行形态",
    }
    return formNames[form] or ("形态"..form)
end

-- 获取寒冰箭施法时间
function GetFrostboltCastTime()
    local _, _, _, castTime = GetSpellInfo("寒冰箭")
    if castTime then
        return castTime / 1000
    end
    return 3.0
end

-- 取消保护祝福
function CancelBlessingOfProtection()
    local buffTime = GetBuffTime("player", "保护之手")
    if buffTime and buffTime > 0 then
        CancelBuff("保护之手")
        print("|cff00ff00[ZZ]|r 已取消保护之手")
        return true
    end
    return false
end

-- 取消灌注
function CancelPowerInfusion()
    local buffTime = GetBuffTime("player", "灌注")
    if buffTime and buffTime > 0 then
        CancelBuff("灌注")
        print("|cff00ff00[ZZ]|r 已取消灌注")
        return true
    end
    return false
end

-- 法师取消灌注
function MageCancelPowerInfusion()
    return CancelPowerInfusion()
end

-- 获取药水冷却状态
function GetPotionCooldownStatus(itemID)
    if not itemID then return "unknown", 0 end
    local count = GetItemCount(itemID)
    local start, duration, enabled, modRate = GetItemCooldown(itemID)
    local ready = false
    local remaining = 0
    if start and duration then
        local endTime = start + duration
        if endTime <= GetTime() then
            ready = true
        else
            remaining = endTime - GetTime()
        end
    end
    if not count or count <= 0 then
        return "no_item", 0
    end
    if ready then
        return "ready", 0
    end
    return "cooldown", remaining
end

-- 判断是否应切换目标处理软泥
function ShouldSwitchTargetForOoze()
    local oozeNames = {
        "小软泥怪", "大软泥怪",
        "辐射软泥怪", "畸变软泥怪",
        "不稳定的软泥怪粘合剂",
    }
    if not UnitExists("target") then return false end
    local targetName = WR_SafeUnitName and WR_SafeUnitName("target") or UnitName("target")
    for _, name in ipairs(oozeNames) do
        if targetName == name then
            return true
        end
    end
    return false
end

-- 获取团队生命值百分比
function GetGroupHealthPercent()
    local groupType = GetGroupType and GetGroupType() or "none"
    local units = {}

    if groupType == "raid" then
        for i = 1, math.min(GetNumGroupMembers() or 0, 25) do
            if UnitExists("raid"..i) then
                units[#units + 1] = "raid"..i
            end
        end
    elseif groupType == "party" then
        if UnitExists("player") then
            units[#units + 1] = "player"
        end
        for i = 1, math.max((GetNumGroupMembers() or 0) - 1, 0) do
            if UnitExists("party"..i) then
                units[#units + 1] = "party"..i
            end
        end
    end

    if #units == 0 then return 100 end
    local totalPct = 0
    local validCount = 0
    for _, unit in ipairs(units) do
        if not UnitIsDeadOrGhost(unit) then
            local maxHP = WR_SafeNumber(UnitHealthMax(unit), 1)
            if maxHP > 0 then
                totalPct = totalPct + (WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1)) / maxHP * 100)
                validCount = validCount + 1
            end
        end
    end
    if validCount == 0 then return 0 end
    return totalPct / validCount
end

-- ============================================================
-- ★ 26. Core_TempText 调试工具
-- ============================================================

-- Temptext_F001: 调试计时工具
local tempTextTimers = {}
function Temptext_F001(label)
    label = label or "debug"
    local now = GetTime()
    if tempTextTimers[label] then
        local elapsed = now - tempTextTimers[label].startTime
        local lapCount = (tempTextTimers[label].lapCount or 0) + 1
        tempTextTimers[label].lapCount = lapCount
        local total = now - tempTextTimers[label].baseTime
        print(string.format("|cff00ff00[计时]|r %s: 第%d次调用, 本帧耗时=%.4fs, 累计=%.4fs",
            label, lapCount, elapsed, total))
        tempTextTimers[label].startTime = now
    else
        tempTextTimers[label] = {
            startTime = now,
            baseTime = now,
            lapCount = 1,
        }
        print(string.format("|cff00ff00[计时]|r %s: 开始计时 (时间戳=%.4f)", label, now))
    end
    return tempTextTimers[label]
end

SLASH_TEMPTEXT1 = "/temptext"
SlashCmdList["TEMPTEXT"] = function(msg)
    msg = strtrim(strlower(msg or ""))
    if msg == "reset" then
        wipe(tempTextTimers)
        print("|cff00ff00[计时]|r 所有计时器已重置")
    elseif msg == "list" then
        print("|cff00ff00[计时]|r 当前活动计时器:")
        for label, data in pairs(tempTextTimers) do
            local elapsed = GetTime() - data.baseTime
            print(string.format("  %s: %d次, 累计%.4fs", label, data.lapCount or 0, elapsed))
        end
    elseif msg ~= "" then
        Temptext_F001(msg)
    else
        print("用法: /temptext <标签> | /temptext reset | /temptext list")
    end
end

-- Temptext_F002: 团队图标目标选择调试
local tempTextGroupIcon = {}
function Temptext_F002(unit)
    unit = unit or "target"
    if not UnitExists(unit) then
        print("|cffff0000[图标调试]|r 单位不存在: "..tostring(unit))
        return
    end
    local unitName = UnitName(unit) or "未知"
    local className = select(2, UnitClass(unit)) or "未知"
    local raidIndex = UnitInRaid(unit)
    local partyIndex = UnitInParty(unit)
    local groupRole = UnitGroupRolesAssigned(unit) or "NONE"
    local healthPct = WR_SafeHPPct(unit) * 100
    local range = GetUnitRange(unit)
    local inRangeText = range and range <= 40 and "|cff00ff00范围内|r" or "|cffff0000范围外|r"

    print(string.format("|cff00ff00[图标调试]|r 单位=%s 职业=%s 团队=%s 队伍=%s 角色=%s 血量=%.1f%% 距离=%s",
        unitName,
        ZZ_ClassesColor(unit)..className.."|r",
        raidIndex and "R"..raidIndex or "-",
        partyIndex and "P"..partyIndex or "-",
        groupRole,
        healthPct,
        inRangeText))

    local colorFrameIndex = nil
    if unit == "player" then colorFrameIndex = 111
    elseif unit == "target" then colorFrameIndex = 112
    elseif unit == "mouseover" then colorFrameIndex = 113
    else
        for i = 1, 4 do
            if unit == "party"..i then colorFrameIndex = 175 + i break end
            if unit == "party"..i.."target" then colorFrameIndex = 105 + i break end
        end
        if not colorFrameIndex then
            for i = 1, 25 do
                if unit == "raid"..i then colorFrameIndex = 120 + i break end
                if unit == "raid"..i.."target" then colorFrameIndex = 150 + i break end
            end
        end
    end
    if colorFrameIndex then
        print(string.format("  对应色块索引: %d", colorFrameIndex))
    else
        print("  未找到对应色块索引")
    end
end

SLASH_GROUPICON1 = "/groupicon"
SlashCmdList["GROUPICON"] = function(msg)
    msg = strtrim(strlower(msg or ""))
    if msg == "target" or msg == "" then
        Temptext_F002("target")
    elseif msg == "focus" then
        Temptext_F002("focus")
    elseif msg == "mouseover" then
        Temptext_F002("mouseover")
    elseif msg == "player" then
        Temptext_F002("player")
    else
        local id = tonumber(msg)
        if id and id >= 1 and id <= 25 then
            Temptext_F002("raid"..id)
        elseif id and id >= 101 and id <= 125 then
            Temptext_F002("raid"..(id - 101).."target")
        else
            print("用法: /groupicon [target|focus|mouseover|player|1-25]")
        end
    end
end

-- Temptext_F003: 单位名称匹配调试
local tempTextNameMatch = {}
function Temptext_F003(namePattern)
    if not namePattern or namePattern == "" then
        print("|cff0000[名称匹配]|r 请提供名称模式")
        print("用法: /namematch <名称或部分名称>")
        return
    end
    namePattern = strlower(namePattern)
    local matches = {}

    local function CheckUnit(unit)
        if UnitExists(unit) then
            local name = UnitName(unit) or ""
            if string.find(strlower(name), namePattern, 1, true) then
                matches[#matches + 1] = { unit = unit, name = name }
            end
        end
    end

    CheckUnit("player")
    CheckUnit("target")
    CheckUnit("focus")
    CheckUnit("mouseover")

    local groupType = GetGroupType and GetGroupType() or "none"
    if groupType == "raid" then
        for i = 1, math.min(GetNumGroupMembers() or 0, 25) do
            CheckUnit("raid"..i)
            CheckUnit("raid"..i.."target")
        end
    elseif groupType == "party" then
        for i = 1, math.max((GetNumGroupMembers() or 0) - 1, 0) do
            CheckUnit("party"..i)
            CheckUnit("party"..i.."target")
        end
    end

    if #matches == 0 then
        print(string.format("|cffff0000[名称匹配]|r 未找到匹配 [%s] 的单位", namePattern))
    else
        print(string.format("|cff00ff00[名称匹配]|r 找到 %d 个匹配 [%s] 的单位:", #matches, namePattern))
        for _, m in ipairs(matches) do
            local hp = WR_SafeHPPct(m.unit) * 100
            local deadText = UnitIsDeadOrGhost(m.unit) and "|cffff0000[死亡]|r" or "|cff00ff00[存活]|r"
            print(string.format("  %s (血量=%.1f%%) %s", m.name, hp, deadText))
        end
    end

    tempTextNameMatch.lastResults = matches
    return matches
end

SLASH_NAMEMATCH1 = "/namematch"
SlashCmdList["NAMEMATCH"] = function(msg)
    msg = strtrim(strlower(msg or ""))
    if msg == "last" then
        if tempTextNameMatch.lastResults and #tempTextNameMatch.lastResults > 0 then
            print("|cff00ff00[名称匹配]|r 上次匹配结果:")
            for _, m in ipairs(tempTextNameMatch.lastResults) do
                print(string.format("  %s -> %s", m.unit, m.name))
            end
        else
            print("|cffff0000[名称匹配]|r 无上次结果")
        end
    else
        Temptext_F003(msg)
    end
end