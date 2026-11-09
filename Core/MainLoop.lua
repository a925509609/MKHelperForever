WR_Addon_Version = "20260420"
PigSet = PigSet or {}
WR_Show = WR_Show or {}

-- ★ 按职业延迟加载：在所有职业模块加载前确定玩家职业
--   各职业文件顶部通过 if WR_PlayerClass ~= "XXX" then return end 守卫跳过非本职业代码
local _, playerClass = UnitClass("player")
WR_PlayerClass = playerClass and strupper(playerClass) or "UNKNOWN"
-- ★ 2026-11-08：跟随默认改为【关闭】。
--   原默认 true + AUTO_FOLLOW_TARGET="focus"，等于「用户从未主动开启，跟随就已激活」，
--   再叠加旧版没有战斗判定 → 战斗中会莫名其妙做焦点跟随并顶掉职业技能提示。
--   现在必须由用户在面板里显式勾选「跟随」才会工作。
if PigSet.AUTO_FOLLOW_ENABLED == nil then
    PigSet.AUTO_FOLLOW_ENABLED = false
end
-- ★ 2026-11-08：跟随目标默认改为 "none"（不再自动从焦点取锚点）。
--   原默认 "focus" + AUTO_FOLLOW_ENABLED=true 的组合，会在每次进游戏/脱战时
--   把「当前焦点队友」自动固化成跟随锚点（写入 AUTO_FOLLOW_GUID 并持久化），
--   随后亮 204 跟随色块 → AHK 按 CTRL-SHIFT-G 执行 /follow <该队友>，
--   表现为「战斗中莫名其妙跟随一下」，且关掉开关后下次开又复发。
--   现在必须由玩家在面板里显式选择跟随目标才会工作。
if PigSet.AUTO_FOLLOW_TARGET == nil then
    PigSet.AUTO_FOLLOW_TARGET = "none"
end
-- ★ 2026-11-05：跟随系统 GUID 锚定（移植自 WotLK 时光服 MKHelper）
--   主跟随目标以 GUID 锚定（小队重排/改名/跨服不丢人），彻底不占游戏焦点槽（奶职业用焦点做治疗焦点不冲突）。
PigSet.AUTO_FOLLOW_GUID   = PigSet.AUTO_FOLLOW_GUID or nil        -- 主跟随目标 GUID（稳定锚点）
PigSet.AUTO_FOLLOW_NAME   = PigSet.AUTO_FOLLOW_NAME or ""          -- 展示名（UI 显示用）
PigSet.AUTO_FOLLOW_MOUNT  = PigSet.AUTO_FOLLOW_MOUNT or true       -- 上马提示(202) 开关
PigSet.AUTO_FOLLOW_REFOCUS= PigSet.AUTO_FOLLOW_REFOCUS or true     -- 主目标不可达时自动换跟
PigSet.ASSIST_COMBAT_ENABLED = PigSet.ASSIST_COMBAT_ENABLED or false -- 协同攻击(205) 开关，默认关
-- ★ 清理早期遗留「自己 GUID」脏数据（避免 201/202 永远解析不到有效跟随单位）
if PigSet.AUTO_FOLLOW_GUID and PigSet.AUTO_FOLLOW_GUID == UnitGUID("player") then
    PigSet.AUTO_FOLLOW_GUID = nil
    PigSet.AUTO_FOLLOW_NAME = ""
end

-- BOSS 特化：按职业直接调度单入口函数（迁移后不再经过 WR_BossRegistry 中间件）
local BOSS_SPECIALS_DISPATCH = {
    WARRIOR     = "WR_Warrior_BossSpecials",
    DEATHKNIGHT = "WR_DeathKnight_BossSpecials",
    DRUID       = "WR_Druid_BossSpecials",
    HUNTER      = "WR_Hunter_BossSpecials",
    MAGE        = "WR_Mage_BossSpecials",
    PALADIN     = "WR_Paladin_BossSpecials",
    PRIEST      = "WR_Priest_BossSpecials",
    ROGUE       = "WR_Rogue_BossSpecials",
    SHAMAN      = "WR_Shaman_BossSpecials",
    WARLOCK     = "WR_Warlock_BossSpecials",
}

-- 跟随状态机变量
-- currentFollowPhase: "idle" | "waiting_focus" | "waiting_follow" | "done"
-- currentFollowUnit: 目标单位token
-- currentFollowMode: "party" | "focus" | "target"
currentFollowPhase = "idle"
currentFollowUnit = nil
currentFollowMode = nil

-- ============================================================
-- ★ A：性能采样模块（默认关闭，用于定位主循环 CPU 热区）
--   用法：游戏中输入 /mkprofile 1 开启采样，打怪/木桩 60 秒后
--        输入 /mkprofile 0 输出各段每 tick 平均耗时与占比。
-- ============================================================
WR_Profiling = false
local WR_ProfileAcc = {}
local WR_ProfileSamples = 0
WR_ClassProfileData = {}  -- ★ 职业循环内部分段累计（由 WR_DeathKnightBlood 等函数写入）

SLASH_MKPROFILE1 = "/mkprofile"
SlashCmdList["MKPROFILE"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$") or ""
    if msg == "1" then
        WR_Profiling = true
        WR_ProfileAcc = {}
        WR_ProfileSamples = 0
        wipe(WR_ClassProfileData)
        print("|cff00ff00[MKHelperForever 性能采样]|r 已开启，打怪/木桩 60 秒后输入 /mkprofile 0 查看各段耗时")
    elseif msg == "0" then
        WR_Profiling = false
        local total = 0
        for _, v in pairs(WR_ProfileAcc) do total = total + v end
        print(string.format("|cff00ff00[MKHelperForever 性能采样]|r 采样 %d ticks，主循环段总耗时 %.2f ms", WR_ProfileSamples, total))
        local sorted = {}
        for k, v in pairs(WR_ProfileAcc) do sorted[#sorted + 1] = { k, v } end
        table.sort(sorted, function(a, b) return a[2] > b[2] end)
        for _, e in ipairs(sorted) do
            local per = WR_ProfileSamples > 0 and (e[2] / WR_ProfileSamples) or 0
            local pct = total > 0 and (100 * e[2] / total) or 0
            print(string.format("  %s: %.4f ms/tick (%.1f%%)", e[1], per, pct))
        end
        -- 输出职业循环内部分段（若存在）
        local classTotal = 0
        for _, v in pairs(WR_ClassProfileData) do classTotal = classTotal + v end
        if classTotal > 0 then
            print(string.format("|cff00ff00[MKHelperForever 性能采样]|r 职业循环内部分段总耗时 %.2f ms", classTotal))
            local cSorted = {}
            for k, v in pairs(WR_ClassProfileData) do cSorted[#cSorted + 1] = { k, v } end
            table.sort(cSorted, function(a, b) return a[2] > b[2] end)
            for _, e in ipairs(cSorted) do
                local per = WR_ProfileSamples > 0 and (e[2] / WR_ProfileSamples) or 0
                local pct = classTotal > 0 and (100 * e[2] / classTotal) or 0
                print(string.format("  %s: %.4f ms/tick (%.1f%%)", e[1], per, pct))
            end
        end
    else
        print("|cff00ff00[MKHelperForever 性能采样]|r 用法：/mkprofile 1 开启采样，/mkprofile 0 输出结果")
    end
end

function WR_ToggleAutoFollow()
    PigSet.AUTO_FOLLOW_ENABLED = not PigSet.AUTO_FOLLOW_ENABLED
    if WR_FollowCheckbox then
        WR_FollowCheckbox:SetChecked(PigSet.AUTO_FOLLOW_ENABLED)
    end
    -- ★ 2026-11-09：跟随开关直接决定 /focus 宏是否生效（见 Core/UI_ColorFrame.lua），
    --   切换后必须立刻重注册，否则「刚开跟随却设不了焦点 / 刚关跟随还在被抢焦点」。
    if type(WR_ReapplyFocusMacros) == "function" then WR_ReapplyFocusMacros() end
    if PigSet.AUTO_FOLLOW_ENABLED then
        WR_PrintToVisible("|cff00ff00自动跟随已开启|r")
    else
        WR_PrintToVisible("|cffff0000自动跟随已关闭|r")
        currentFollowPhase = "idle"
        WR_ResetAutoFollow()
        WR_HideFollowColorFrames()
    end
end

function WR_SetAutoFollow(state)
    PigSet.AUTO_FOLLOW_ENABLED = state
    if WR_FollowCheckbox then
        WR_FollowCheckbox:SetChecked(state)
    end
    -- ★ 2026-11-09：同 WR_ToggleAutoFollow，重注册 /focus 宏
    if type(WR_ReapplyFocusMacros) == "function" then WR_ReapplyFocusMacros() end
    if state then
        WR_PrintToVisible("|cff00ff00自动跟随已开启|r")
    else
        WR_PrintToVisible("|cffff0000自动跟随已关闭|r")
        currentFollowPhase = "idle"
        WR_ResetAutoFollow()
        WR_HideFollowColorFrames()
    end
end

-- 注册 /mkaf 斜杠命令，避免玩家使用 /run 触发暴雪「自定义脚本」确认弹窗
SLASH_MKAUTOFOLLOW1 = "/mkaf"
SlashCmdList["MKAUTOFOLLOW"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$") or ""
    if msg == "" or msg == "toggle" then
        WR_ToggleAutoFollow()
    elseif msg == "on" or msg == "1" or msg == "true" then
        WR_SetAutoFollow(true)
    elseif msg == "off" or msg == "0" or msg == "false" then
        WR_SetAutoFollow(false)
    else
        WR_PrintToVisible("|cff00adf0[跟随]|r 用法：/mkaf on 开启，/mkaf off 关闭，/mkaf 切换")
    end
end

-- ============================================================
-- ★ 新增：全局手套附魔可用性判断（工程学 + 400点）
-- ============================================================
function WR_CanUseGloves()
    -- 检查是否为工程学（专业ID 202）
    local prof1, prof2 = GetProfessions()
    if prof1 ~= 202 and prof2 ~= 202 then
        return false
    end
    -- 检查手套（装备槽 10）的附魔冷却是否可用
    local start, duration, enabled = GetInventoryItemCooldown("player", 10)
    if enabled and (start == 0 or duration == 0) then
        return true
    end
    return false
end

local TestPlayerName = {
    "佳佳骑",
    "佳佳不是熊猫",
    "佳佳德",
    "佳佳萨",
}
-- 全局变量
local currentFollowGUID = nil -- 记录当前正在跟随的单位GUID

-- ★ 焦点跟随提示广播（节流，避免每帧刷屏；尊重 ChatNoticeMode，与复选框切换提示一致）
local WR_FollowChatTipCD = 0
local WR_SetFocusChatTipCD = 0
local function WR_FollowChatTip(msg, isSetFocus)
    local now = GetTime()
    local cd = isSetFocus and WR_SetFocusChatTipCD or WR_FollowChatTipCD
    if now - cd < 5 then return end
    if isSetFocus then WR_SetFocusChatTipCD = now else WR_FollowChatTipCD = now end
    if WR_PrintToVisible then WR_PrintToVisible(msg) end
end

-- 隐藏跟随相关色块（201目标跟随/203设置焦点/204焦点跟随，原115/116/117已迁移至201-210段）
local function WR_HideFollowColorFrames()
    if ColorFrameArrayTopLeft then
        if ColorFrameArrayTopLeft[201] then ColorFrameArrayTopLeft[201]:Hide() end
        if ColorFrameArrayTopLeft[203] then ColorFrameArrayTopLeft[203]:Hide() end
        if ColorFrameArrayTopLeft[204] then ColorFrameArrayTopLeft[204]:Hide() end
    end
end

-- 跟随状态监听帧
local followMonitor = CreateFrame("Frame")
followMonitor:RegisterEvent("AUTOFOLLOW_BEGIN")
followMonitor:RegisterEvent("AUTOFOLLOW_END")
followMonitor:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- 副本/场景切换重置
followMonitor:SetScript("OnEvent", function(self, event, unitID)
    if event == "AUTOFOLLOW_BEGIN" then
        if UnitExists(unitID) then
            currentFollowGUID = UnitGUID(unitID)
            -- 跟随成功，立即清除提示色块
            WR_HideFollowColorFrames()
        end
    elseif event == "AUTOFOLLOW_END" or event == "ZONE_CHANGED_NEW_AREA" then
        currentFollowGUID = nil
        WR_HideFollowColorFrames()
    end
end)

function WR_GetMyTalent()
    local TalentRank = -1
    local TalentName
    local TalentId
    -- ★ 2026-08-21 修复（v3）：本端为 WotLK（接口 38002），无 specialization 概念，
    --   且 GetTalentTabInfo 返回值顺序与标准 WotLK 不同：
    --     返回值1 = 数字 tabID（如 398），返回值2 = 中文页名（如"冰霜"），
    --     返回值5 = 已投入点数（rank）。
    --   之前按标准顺序把第1返回值当名字 → 天赋标题显示数字；
    --   UI_TalentFrame.lua 已用 "_, name = GetTalentTabInfo(i)" 取第2返回值，Boss 文件用 select(5) 取点数，
    --   故本函数同步修正：tabName 取第2返回值，rank 取第5返回值。
    local tabCount = 4
    -- ★ 无限适配：经典天赋 API 已移除，Core/Forever_Compat.lua 会安装同名兜底；
    --   这里仍做存在性 + pcall 守卫，避免缺失/异常时抛错中断整个主循环。
    if type(GetNumTalentTabs) == "function" then
        local ok, n = pcall(GetNumTalentTabs)
        if ok and type(n) == "number" and n >= 1 then tabCount = n end
    end
    for i = 1, tabCount do
        local tabName, extraRank
        if type(GetTalentTabInfo) == "function" then
            local ok, _, name, _, _, rank = pcall(GetTalentTabInfo, i)
            if ok then tabName, extraRank = name, rank end
        end
        tabName = tabName or ""
        -- ★ 无限适配：天赋树改名归一（元素战斗→元素 / 暗影魔法→暗影 / 野性战斗→野性），
        --   并顺带支持 enUS 客户端的英文树名。函数由 Core/Forever_Compat.lua 提供。
        if type(WR_Forever_NormalizeSpec) == "function" then
            tabName = WR_Forever_NormalizeSpec(tabName)
        end
        local rank = extraRank or 0
        if rank > TalentRank then
            TalentRank = rank
            TalentName = tabName or ""
            TalentId = i
        end
    end
    -- ★ 兜底：完全没点天赋（1级/新角色，API 返回 nil 或全 0）时，默认识别为第 1 页（德鲁伊=平衡）；
    --   若第 1 页也拿不到名字（天赋树未激活），按职业默认专精兜底
    if (not TalentName or TalentName == "") and TalentRank <= 0 then
        local tabName
        if type(GetTalentTabInfo) == "function" then
            local ok, _, name = pcall(GetTalentTabInfo, 1)
            if ok then tabName = name end
        end
        if type(WR_Forever_NormalizeSpec) == "function" then
            tabName = WR_Forever_NormalizeSpec(tabName)
        end
        TalentName = tabName or ""
        TalentId = 1
        if (not TalentName or TalentName == "") and type(WR_GetDefaultSpecByClass) == "function" then
            TalentName = WR_GetDefaultSpecByClass() or ""
        end
    end
    -- ★ ZZHELPER 方案：天赋树完全未激活（API 全空且无职业默认）→ TalentId=5 表示未激活
    if (not TalentName or TalentName == "") then
        TalentName = nil
        TalentId = 5
    end
    -- ★ SoD 适配：删除 WotLK「武器天赋+强化复仇≥2 → 改判防护」特判（SoD 专精由天赋页名直接判定）
    return TalentName, TalentId
end
-- ★★★ 安全检测函数（用于技能释放，严格检查） ★★★
local function IsSafeToAct()
    if InCombatLockdown and InCombatLockdown() then return false end
    if UnitIsDeadOrGhost("player") then return false end
    if UnitInVehicle("player") then return false end
    if WR_PlayerMove() then return false end
    if UnitCastingInfo("player") or UnitChannelInfo("player") then return false end
    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType == "pvp" then return false end
    if UnitIsCharmed("player") then return false end
    return true
end

-- ★ 2026-11-05：跟随系统模块级状态。必须声明在 WR_AutoFollow 之前——
--   Lua 5.1 词法作用域下，函数内对「定义在它之后的 local」的引用会在编译期回落到全局 _G，
--   导致 lastAutoRefocus 解析为全局 nil、做算术时崩（见报错 320 行）。
local refocusOutSince   = nil    -- 主目标超距累计起点
local lastAutoRefocus   = 0      -- 上次自动换跟时间（10s 节流）
local mountPromptSince  = nil    -- 上马提示连续计时
local mountPromptBlocked= false  -- 区域禁骑后抑制
local mountPromptArmedAt= nil    -- 上马提示冷静期
local assistPromptSince = nil    -- 协助提示节流
local pendingFollowUnit = nil    -- 战斗中跟随按钮排队落地

function WR_AutoFollow()
    -- 全局跟随总开关关闭：清掉残留跟随色块（防「关闭后仍提示」粘连），直接退出
    if not PigSet.AUTO_FOLLOW_ENABLED then
        WR_HideFollowColorFrames()
        return false
    end
    -- ★ 默认先清掉跟随色块；仅当下方「需要跟随」分支才会重新点亮（WR_ColorFrame_Show 内部先隐后显）。
    --   这样任何提前 return（无目标/超距/不可达/已跟随）都不会残留旧「跟随」色块（slot 204）。
    WR_HideFollowColorFrames()

    -- ★★ 2026-11-08 关键修复：跟随只在【脱战】时工作。
    --   原实现没有任何战斗判定 —— IsSafeToAct() 里用的是 InCombatLockdown()（受保护 UI 锁定，
    --   打怪时通常是 false，与「是否在战斗中」完全是两回事），所以战斗中只要不移动、不施法，
    --   就会满足条件并执行 WR_UpdateFollowButton + 亮 204 跟随色块 + return true 阻塞职业循环，
    --   表现为「战斗中莫名其妙做焦点跟随」，还会把职业技能提示顶掉。
    --   现在：战斗中直接退出（并清掉跟随色块），绝不干预战斗。
    if UnitAffectingCombat("player") or (InCombatLockdown and InCombatLockdown()) then
        return false
    end

    -- ★ 2026-11-05：主目标以 GUID 锚定（移植自 WotLK 时光服），奶职业用焦点做治疗焦点也不冲突。
    --   兼容旧 AUTO_FOLLOW_TARGET（UI 下拉框仍写它）：首次运行把 target→unit→GUID 固化为锚点。
    --
    --   ★★ 2026-11-08 关键修复「战斗中莫名其妙跟随队友」：
    --     旧逻辑会把 AUTO_FOLLOW_TARGET（默认/历史值 = "focus"）解析成当前焦点队友，
    --     然后**自动**把他的 GUID 固化成跟随锚点并持久化 → 亮 204 → AHK 按 CTRL-SHIFT-G
    --     执行 /follow <该队友>。因为焦点在战斗中是随时变化的，这等于「自动跟随当前焦点」，
    --     而且锚点写进存档后会一直生效，关掉开关下次开启又复发。
    --     现在：**只允许玩家显式选择具体队员（partyN/raidN/player）时自动固化锚点**；
    --     "focus"/"target" 这类会随战况漂移的来源一律不再自动固化，必须由面板手动设目标。
    local legacyTarget = PigSet.AUTO_FOLLOW_TARGET
    local anchorGUID = PigSet.AUTO_FOLLOW_GUID
    local autoAnchorAllowed = type(legacyTarget) == "string"
        and (legacyTarget:match("^party%d+$") ~= nil
             or legacyTarget:match("^raid%d+$") ~= nil
             or legacyTarget == "player")
    if not anchorGUID and autoAnchorAllowed then
        local u = WR_ResolveTargetToUnit(legacyTarget)
        if u and UnitExists(u) and UnitIsPlayer(u) and not UnitIsUnit(u, "player") then
            anchorGUID = (WR_SafeUnitGUID and WR_SafeUnitGUID(u)) or nil
            if anchorGUID then
                PigSet.AUTO_FOLLOW_GUID = anchorGUID
                PigSet.AUTO_FOLLOW_NAME = (WR_SafeUnitName and WR_SafeUnitName(u)) or ""
            end
        end
    end
    if not anchorGUID then
        return false
    end

    -- 主目标反查当前 unitID（小队重排/改名/跨服都不丢人）
    local mainUnit = WR_ResolveFollowUnit(anchorGUID)

    -- ★ 主目标不可达判定（防抖）：不存在/死亡 → 立即；超距 25 码持续 5 秒 → 触发换跟
    local mainInvalid = false
    if not mainUnit or not UnitExists(mainUnit) or UnitIsDeadOrGhost(mainUnit) then
        mainInvalid = true
        refocusOutSince = nil
    else
        local r = WR_UnitRange(mainUnit) or 999
        if r > 25 then
            if not refocusOutSince then refocusOutSince = GetTime() end
            if GetTime() - refocusOutSince >= 5 then mainInvalid = true end
        else
            refocusOutSince = nil
        end
    end

    -- ★ 临时换跟：主目标不可达 + 开启换跟 → 仅改「跟随单位」临时跟最近队友，绝不碰游戏焦点槽。
    --   主目标重新可达时，每 tick 重新反查会自然切回主目标（临时目标被丢弃，绝不改写主目标 GUID）。
    local targetUnit = mainUnit
    if (mainInvalid or not mainUnit) and PigSet.AUTO_FOLLOW_REFOCUS then
        if GetTime() - lastAutoRefocus >= 10 then
            local cand = WR_FindRefocusCandidate()
            if cand then
                targetUnit = cand
                lastAutoRefocus = GetTime()
                refocusOutSince = nil
                local cname = UnitName(cand) or cand
                WR_FollowChatTip(string.format(
                    "|cff00adf0[跟随]|r 主目标不可达，临时换跟：%s（主目标回到范围内自动切回）", cname))
            end
        end
    end

    if not targetUnit or not UnitExists(targetUnit) then
        return false
    end
    if UnitIsDeadOrGhost(targetUnit) or not UnitIsPlayer(targetUnit) then
        return false
    end
    local unitGUID = (WR_SafeUnitGUID and WR_SafeUnitGUID(targetUnit)) or nil
    if not unitGUID then return false end
    local unitName = WR_SafeUnitName and WR_SafeUnitName(targetUnit) or (UnitName(targetUnit) or "队友")

    -- 安全校验（整体门槛；上马提示分支已单独放宽，不受"自己移动/施法"影响）
    if not IsSafeToAct() then
        return false
    end

    -- 跟随距离限制25码
    local range = WR_UnitRange(targetUnit) or 999
    if range <= 0 or range > 25 then
        return false
    end

    -- ★ 已跟随判定：优先用游戏层级真实跟随状态 UnitIsUnit(targetUnit,"follow") 作权威信号，
    --   不再只依赖 currentFollowGUID。后者由 AUTOFOLLOW_BEGIN/END 事件投递，时机不可靠——
    --   事件中途到达或抖动会使 currentFollowGUID 在 GUID/nil 间反复翻转，让 204 色块每帧在
    --   「显示/隐藏」间横跳（表现为「已跟随却一直闪」）。游戏层级跟随一旦建立即稳定，故以它为
    --   准。检测到已跟随时同步 currentFollowGUID 保持逻辑自洽（即便 END 事件误触也因 UnitIsUnit 仍为
    --   true 而不会闪烁）。
    local alreadyFollowing = (currentFollowGUID == unitGUID)
    if (not alreadyFollowing) and type(UnitIsUnit) == "function" and targetUnit
       and UnitIsUnit(targetUnit, "follow") then
        alreadyFollowing = true
        currentFollowGUID = unitGUID
    end
    if not alreadyFollowing then
        -- 当前跟随目标和设定不一致 → 动态更新跟随安全按钮（/follow <unitID>）+ 弹 204 提示
        WR_UpdateFollowButton(targetUnit)
        if WR_ColorFrame_Show then
            WR_ColorFrame_Show(204, "跟随")
        end
        WR_FollowChatTip("|cff00adf0[跟随]|r 正在跟随：" .. unitName)
        -- 未跟随，持续显示色块提示，返回true阻塞职业循环让玩家优先跟随
        return true
    end
    -- 已跟随上目标，清除跟随提示色块，返回false让职业循环正常执行
    WR_HideFollowColorFrames()
    return false
end

-- ============================================================
-- ★ 2026-11-05：跟随系统「GUID 锚定 + 动态安全按钮」重构（移植自 WotLK 时光服 MKHelper）
--   设计目标：跟随目标以 GUID 锚定（小队重排/改名/跨服不丢人），204 跟随改由安全按钮
--   WR_FollowSecureBtn 执行 /follow <unitID>，彻底不占用游戏焦点槽（奶职业用焦点做治疗焦点不冲突）。
--   ⚠ 已排除 WotLK 专属的「任务坐骑跟随」（物品44229/风暴峭壁等区域名），该内容在 Infinite 无意义。
-- ============================================================
-- （上述 7 个 local 已上移到 WR_AutoFollow 之前，避免函数内引用回落全局 _G 而 nil）
local pendingAssistUnit = nil    -- 战斗中协助按钮排队落地
local WR_AssistBtnUnit  = nil    -- 已写入协助按钮的 unitID
local WR_AssistBtnGUID  = nil    -- 已写入协助按钮的 GUID

-- 旧 AUTO_FOLLOW_TARGET（UI 下拉框仍写它）解码为 unit token
function WR_ResolveTargetToUnit(t)
    if type(t) ~= "string" then
        if t == 2 then return "focus"
        elseif t == 3 then return "target"
        elseif type(t) == "number" and t >= 4 and t <= 7 then return "party" .. (t - 3)
        elseif type(t) == "number" and t >= 8 and t <= 32 then return "raid" .. (t - 7) end
        return nil
    end
    if t == "none" then return nil end
    return t
end

-- ★ 动态跟随安全按钮（替代原 /follow focus 宏）：macrotext 每 tick 设为 /follow <unitID>，
--   从根上不占焦点槽。SecureActionButton 的 macrotext 属安全属性，战斗中不可改 → pendingFollowUnit 排队，
--   PLAYER_REGEN_ENABLED 后落地（与 /follow 只能脱战触发的硬限制一致）。
local followSecureBtn = CreateFrame("Button", "WR_FollowSecureBtn", UIParent, "SecureActionButtonTemplate")
followSecureBtn:RegisterForClicks("AnyDown", "AnyUp")
followSecureBtn:SetAttribute("type", "macro")
followSecureBtn:SetAttribute("macrotext", "/follow target")  -- 占位，运行时覆盖
SetOverrideBindingClick(followSecureBtn, true, "CTRL-SHIFT-G", "WR_FollowSecureBtn")   -- 204

function WR_UpdateFollowButton(unitID)
    if not unitID then return end
    local mt = "/follow " .. unitID
    if followSecureBtn:GetAttribute("macrotext") == mt then return end
    if InCombatLockdown and InCombatLockdown() then
        pendingFollowUnit = unitID
    else
        followSecureBtn:SetAttribute("macrotext", mt)
    end
end

local followRegenFrame = CreateFrame("Frame")
followRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
followRegenFrame:SetScript("OnEvent", function()
    if pendingFollowUnit and not (InCombatLockdown and InCombatLockdown()) then
        followSecureBtn:SetAttribute("macrotext", "/follow " .. pendingFollowUnit)
        pendingFollowUnit = nil
    end
end)

-- ★ 动态协助攻击安全按钮（205）：macrotext = /dismount + /assist <unitID> + /startattack + /petattack。
local assistSecureBtn = CreateFrame("Button", "WR_AssistSecureBtn", UIParent, "SecureActionButtonTemplate")
assistSecureBtn:RegisterForClicks("AnyDown", "AnyUp")
assistSecureBtn:SetAttribute("type", "macro")
assistSecureBtn:SetAttribute("macrotext", "/assist target")  -- 占位
SetOverrideBindingClick(assistSecureBtn, true, "CTRL-SHIFT-N", "WR_AssistSecureBtn")   -- 205

local function WR_UpdateAssistButton(unitID)
    if not unitID then return end
    local mt = "/dismount [mounted]\n/assist " .. unitID .. "\n/startattack [harm,nodead]\n/petattack [harm,nodead]"
    if assistSecureBtn:GetAttribute("macrotext") == mt then return end
    if InCombatLockdown and InCombatLockdown() then
        pendingAssistUnit = unitID
    else
        assistSecureBtn:SetAttribute("macrotext", mt)
    end
end

local assistRegenFrame = CreateFrame("Frame")
assistRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
assistRegenFrame:SetScript("OnEvent", function()
    if pendingAssistUnit and not (InCombatLockdown and InCombatLockdown()) then
        assistSecureBtn:SetAttribute("macrotext",
            "/dismount [mounted]\n/assist " .. pendingAssistUnit .. "\n/startattack [harm,nodead]\n/petattack [harm,nodead]")
        pendingAssistUnit = nil
    end
end)

-- 跟随状态重置（供 UI 复选框/下拉/斜杠命令调用，跨文件通过全局函数访问 MainLoop 的 local 状态）
function WR_ResetAutoFollow()
    currentFollowGUID = nil
    refocusOutSince = nil
    lastAutoRefocus = 0
    mountPromptSince = nil
    mountPromptBlocked = false
    pendingFollowUnit = nil
end

-- 自动换跟候选扫描：25 码内最近存活玩家（party1-5/raid1-25 覆盖设焦键位范围）
function WR_FindRefocusCandidate()
    local best, bestRange = nil, 26
    local numGroup = GetNumGroupMembers and GetNumGroupMembers() or 0
    if numGroup <= 0 then return nil end
    if IsInRaid and IsInRaid() then
        for i = 1, math.min(numGroup, 25) do
            local u = "raid" .. i
            if UnitExists(u) and not UnitIsUnit(u, "player") and
               UnitIsPlayer(u) and not UnitIsDeadOrGhost(u) then
                local r = WR_UnitRange(u) or 999
                if r > 0 and r < bestRange then best, bestRange = u, r end
            end
        end
    else
        for i = 1, 4 do
            local u = "party" .. i
            if UnitExists(u) and not UnitIsUnit(u, "player") and
               UnitIsPlayer(u) and not UnitIsDeadOrGhost(u) then
                local r = WR_UnitRange(u) or 999
                if r > 0 and r < bestRange then best, bestRange = u, r end
            end
        end
        if UnitExists("party5") and not UnitIsUnit("party5", "player") and
           UnitIsPlayer("party5") and not UnitIsDeadOrGhost("party5") then
            local r = WR_UnitRange("party5") or 999
            if r > 0 and r < bestRange then best, bestRange = "party5", r end
        end
    end
    return best
end

-- ★ GUID → 当前 unitID 反查（稳定跟随核心）：扫 party1-5/raid1-40，再比对 target/focus。0.3s 缓存省去每 tick 全量比对。
local wrFollowResolveCache = { guid = nil, unit = nil, t = 0 }
local WR_FOLLOW_EXTRA_UNITS = { "target", "focus" }  -- 团队外友方玩家的唯一可用句柄
function WR_ResolveFollowUnit(guid)
    if not guid then return nil end
    local now = GetTime()
    if wrFollowResolveCache.guid == guid and now - wrFollowResolveCache.t < 0.3 then
        return wrFollowResolveCache.unit
    end
    local found = nil
    local function SameGUID(u)
        local g = (WR_SafeUnitGUID and WR_SafeUnitGUID(u)) or nil
        return g ~= nil and g == guid
    end
    for i = 1, 5 do
        local u = "party" .. i
        if UnitExists(u) and SameGUID(u) then found = u; break end
    end
    if not found then
        for i = 1, 40 do
            local u = "raid" .. i
            if UnitExists(u) and SameGUID(u) then found = u; break end
        end
    end
    -- 团队外友方玩家：仅经 当前目标 / 焦点 解析（必须是玩家且非自己）
    if not found then
        for _, u in ipairs(WR_FOLLOW_EXTRA_UNITS) do
            if UnitExists(u) and not UnitIsUnit(u, "player") and UnitIsPlayer(u)
               and SameGUID(u) then
                found = u
                break
            end
        end
    end
    wrFollowResolveCache.guid = guid
    wrFollowResolveCache.unit = found
    wrFollowResolveCache.t = now
    return found
end

-- 把「当前目标 / 焦点」设为跟随对象（存 GUID，不占焦点槽）；/mkft /mkff /mkc 斜杠命令
function WR_SetFollowFromUnit(unit, label)
    local g = (WR_SafeUnitGUID and WR_SafeUnitGUID(unit)) or nil
    if UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") and g then
        PigSet.AUTO_FOLLOW_GUID = g
        PigSet.AUTO_FOLLOW_NAME = (WR_SafeUnitName and WR_SafeUnitName(unit)) or UnitName(unit) or ""
        if WR_ResetAutoFollow then WR_ResetAutoFollow() end
        if WR_RefreshFollowUI then WR_RefreshFollowUI() end
        WR_PrintToVisible(string.format("|cff00ff00已设为跟随目标(存GUID): %s|r", PigSet.AUTO_FOLLOW_NAME))
    else
        WR_PrintToVisible(string.format("|cffff0000%s 无效（不存在 / 非玩家 / 是自己）|r", label))
    end
end

SLASH_MKFOLLOW_TARGET1 = "/mkft"
SlashCmdList["MKFOLLOW_TARGET"] = function() WR_SetFollowFromUnit("target", "当前目标") end
SLASH_MKFOLLOW_FOCUS1  = "/mkff"
SlashCmdList["MKFOLLOW_FOCUS"]  = function() WR_SetFollowFromUnit("focus", "当前焦点") end
SLASH_MKFOLLOW_CLEAR1  = "/mkc"
SlashCmdList["MKFOLLOW_CLEAR"]  = function()
    PigSet.AUTO_FOLLOW_GUID = nil
    PigSet.AUTO_FOLLOW_NAME = ""
    if WR_ResetAutoFollow then WR_ResetAutoFollow() end
    WR_HideFollowColorFrames()
    if WR_RefreshFollowUI then WR_RefreshFollowUI() end
    WR_PrintToVisible("|cff00ff00已清除跟随目标|r")
end

-- 协同攻击(205) 开关
SLASH_MKASSIST1 = "/mkassist"
SlashCmdList["MKASSIST"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$") or ""
    if msg == "on" or msg == "1" or msg == "true" then
        PigSet.ASSIST_COMBAT_ENABLED = true
        WR_PrintToVisible("|cff00ff00协同攻击已开启|r")
    elseif msg == "off" or msg == "0" or msg == "false" then
        PigSet.ASSIST_COMBAT_ENABLED = false
        WR_PrintToVisible("|cffff0000协同攻击已关闭|r")
    else
        PigSet.ASSIST_COMBAT_ENABLED = not PigSet.ASSIST_COMBAT_ENABLED
        WR_PrintToVisible(PigSet.ASSIST_COMBAT_ENABLED and "|cff00ff00协同攻击已开启|r" or "|cffff0000协同攻击已关闭|r")
    end
end

-- 同步面板下拉显示（若有）
function WR_RefreshFollowUI()
    if WR_FollowDropdown and UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(WR_FollowDropdown, (PigSet.AUTO_FOLLOW_NAME and PigSet.AUTO_FOLLOW_NAME ~= "") and PigSet.AUTO_FOLLOW_NAME or "无")
    end
end

-- 供 UI 下拉框切换跟随目标时立即刷新协助安全按钮宏（脱战写/战中排队）
function WR_RefreshAssistButton()
    if InCombatLockdown and InCombatLockdown() then return end
    local u = WR_ResolveAssistSubject()
    if u then
        WR_UpdateAssistButton(u)
        WR_AssistBtnUnit = u
    else
        if assistSecureBtn:GetAttribute("macrotext") ~= "/assist target" then
            assistSecureBtn:SetAttribute("macrotext", "/assist target")
        end
        WR_AssistBtnUnit = nil
    end
end

-- 解析协助对象（跟随目标优先；未设则兜底当前目标/焦点中的友方玩家）
function WR_ResolveAssistSubject()
    if PigSet.AUTO_FOLLOW_GUID then
        local u = WR_ResolveFollowUnit(PigSet.AUTO_FOLLOW_GUID)
        if u and UnitExists(u) and UnitIsPlayer(u) then
            return u
        end
    end
    if UnitExists("target") and UnitIsPlayer("target") and UnitIsFriend("player", "target") then
        return "target"
    end
    if UnitExists("focus") and UnitIsPlayer("focus") and UnitIsFriend("player", "focus") then
        return "focus"
    end
    return nil
end

-- ★ 上马提示（202）：独立函数，优先于跟随调用，不依赖「已设跟随目标」。受 AUTO_FOLLOW_MOUNT + AUTO_FOLLOW_ENABLED 双重控制。
function WR_CheckMountFollow()
    if not PigSet.AUTO_FOLLOW_MOUNT then
        mountPromptSince = nil; mountPromptBlocked = false
        return false
    end
    if not PigSet.AUTO_FOLLOW_ENABLED then
        mountPromptSince = nil; mountPromptBlocked = false
        return false
    end
    -- ★ 2026-11-08：战斗中不上马提示（跟随类功能一律只在脱战工作）
    if UnitAffectingCombat("player") then
        mountPromptSince = nil
        return false
    end
    -- 监控对象：优先跟随目标(GUID 反查)，否则焦点 → 当前目标
    local watchUnit = nil
    if PigSet.AUTO_FOLLOW_GUID then
        watchUnit = WR_ResolveFollowUnit(PigSet.AUTO_FOLLOW_GUID)
    end
    if not watchUnit or not UnitExists(watchUnit) or UnitIsDeadOrGhost(watchUnit) or not UnitIsPlayer(watchUnit) then
        if UnitExists("focus") and UnitIsPlayer("focus") and not UnitIsDeadOrGhost("focus") then
            watchUnit = "focus"
        elseif UnitExists("target") and UnitIsPlayer("target") and not UnitIsDeadOrGhost("target") then
            watchUnit = "target"
        else
            watchUnit = nil
        end
    end
    if not watchUnit then
        mountPromptSince = nil; mountPromptBlocked = false
        return false
    end
    local unitName = UnitName(watchUnit) or "队友"
    local unitMounted = WR_IsUnitMounted(watchUnit)
    local playerCanPrompt = unitMounted and (not IsMounted()) and (not UnitInVehicle("player"))
    if not playerCanPrompt then
        mountPromptSince = nil
        if not unitMounted then mountPromptBlocked = false end
        return false
    end
    if mountPromptBlocked then return false end
    -- 安全闸门：玩家死亡/战斗锁/施法/被控制时都不弹（上马提示不能打断施法）
    if UnitIsDeadOrGhost("player") then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    if UnitCastingInfo("player") or UnitChannelInfo("player") then return false end
    if UnitIsCharmed and UnitIsCharmed("player") then return false end
    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType == "pvp" then
        mountPromptSince = nil
        return false
    end
    if not mountPromptSince then mountPromptSince = GetTime() end
    if GetTime() - mountPromptSince >= 8 then
        -- 连续提示 8 秒仍未上坐骑 → 当前区域大概率禁止骑乘，暂停 202 防死循环刷键
        mountPromptBlocked = true
        mountPromptSince = nil
        WR_FollowChatTip("|cff00adf0[跟随上马]|r 多次尝试上马未成功，当前区域可能禁止骑乘，已暂停上马提示")
        return false
    end
    mountPromptArmedAt = GetTime()
    if WR_ColorFrame_Show then
        WR_ColorFrame_Show(202, "上马跟随")
    end
    WR_FollowChatTip(string.format(
        "|cff00adf0[跟随上马]|r %s已上马，请上马跟随（判定速度 %.1f）",
        unitName, WR_SafeNumber((GetUnitSpeed(watchUnit)), 0)))
    return true
end

-- ★ 协同攻击（205）：跟随目标进战 + 其目标可攻击 → 闪 205，由 AHK 按 CTRL-SHIFT-N 触发 WR_AssistSecureBtn。默认关。
local ASSIST_RETRY = 1.5   -- 重发 205 像素的最小间隔，避免 AHK 连点
function WR_CheckCombatAssist()
    if not PigSet.ASSIST_COMBAT_ENABLED then
        assistPromptSince = nil
        return false
    end
    if UnitIsDeadOrGhost("player") then
        assistPromptSince = nil
        return false
    end
    if (UnitInVehicle and UnitInVehicle("player")) or (UnitOnTaxi and UnitOnTaxi("player"))
       or (IsMounted and IsMounted()) then
        assistPromptSince = nil
        return false
    end
    local subjectUnit = WR_ResolveAssistSubject()
    if not subjectUnit then
        assistPromptSince = nil
        return false
    end
    if UnitIsDeadOrGhost(subjectUnit) or not UnitIsConnected(subjectUnit) then
        assistPromptSince = nil
        return false
    end
    -- 解析到协助对象就同步安全按钮宏（脱战写/战中排队），保证手动键随时协助
    if WR_AssistBtnUnit ~= subjectUnit then
        WR_UpdateAssistButton(subjectUnit)
        WR_AssistBtnUnit = subjectUnit
    end
    if not UnitAffectingCombat(subjectUnit) then
        assistPromptSince = nil
        return false
    end
    local subjectTarget = subjectUnit .. "target"
    if not UnitExists(subjectTarget) or UnitIsDeadOrGhost(subjectTarget)
       or not UnitCanAttack("player", subjectTarget) then
        assistPromptSince = nil
        return false
    end
    -- 自己已锁定「队友正在打的同一目标」则跳过，不抢已锁定目标、也不刷键
    if UnitExists("target") and UnitIsUnit("target", subjectTarget) then
        assistPromptSince = nil
        return false
    end
    if not assistPromptSince then assistPromptSince = GetTime() end
    if GetTime() - assistPromptSince < ASSIST_RETRY then
        return false
    end
    assistPromptSince = GetTime()
    if WR_ColorFrame_Show then
        WR_ColorFrame_Show(205, "协同攻击")
    end
    WR_FollowChatTip(string.format("|cff00adf0[协同攻击]|r %s 正在攻击 %s，请求协助",
        UnitName(subjectUnit) or "队友", UnitName(subjectTarget) or "目标"))
    return true
end

function WR_SetFocusFromTarget()
    if not UnitExists("target") then return false end
    if UnitIsDeadOrGhost("target") then return false end
    if not UnitIsPlayer("target") then return false end
    local targetName = WR_SafeUnitName("target")
    if not targetName then return false end
    if targetName == UnitName("player") then return false end
    if WR_ColorFrame_Show then
        WR_ColorFrame_Show(203, "设置焦点")
        C_Timer.After(0.6, function()
            if WR_ColorFrame_Show then
                WR_ColorFrame_Show(203, "设置焦点 ")
            end
        end)
    else
        print("|cff00ff00203 SHIFT--|r 焦点色块触发：" .. targetName)
    end
    WR_FollowChatTip("|cff00adf0[焦点跟随]|r 已标记设置焦点：" .. targetName, true)
    return true
end

-- ★ P0-3 天赋缓存失效：天赋/双天赋/进本时清空缓存，下次 tick 重算
local wrTalentEventFrame = CreateFrame("Frame")
wrTalentEventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
wrTalentEventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
wrTalentEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
wrTalentEventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
wrTalentEventFrame:SetScript("OnEvent", function()
    WR_TalentCache = nil
end)

-- 主循环OnUpdate
local frame = CreateFrame("Frame", "WOW-Robot")
frame:SetScript("OnUpdate", function(self, elapsed)
    if WR_StopTime == nil or GetTime() - WR_StopTime > (WR_TemporaryTtopTime or 0.5) then
        WR_StopTime = nil
        -- ★ P0-2：基于帧 elapsed 累加器的节流（默认 10Hz，引导末段 20Hz，迈克斯纳特例保留）。
        --   原逻辑每帧进入 OnUpdate 都跑 WR_FocusCast / UnitChannelInfo，并在内部用墙上时钟
        --   GetTime()-WR_LastTime 节流；现改为累加器，未达 WR_Delay 直接跳过，WR_StopTime
        --   暂停窗口仍保持每帧响应。
        WR_MainTickAccum = (WR_MainTickAccum or 0) + elapsed
        if WR_MainTickAccum < (WR_Delay or 0.1) then
            return
        end
        WR_MainTickAccum = 0
        if WR_FocusCast() then
            return
        end
        local _, _, _, _, endTimeMS = UnitChannelInfo("player")
        -- ★ 无限适配：引导结束时间在 12.x 可能是 secret value，
        --   先收敛成普通数字，避免除法抛错并把插件打上会话级 taint。
        endTimeMS = WR_SafeNumber(endTimeMS, 0)
        if endTimeMS > 0 and endTimeMS / 1000 - GetTime() < 0.4 then
            -- ★ 性能优化：引导末段原先压到 0.01（100Hz 跑完整循环），代价过高。
            -- 引导中本就无法施法，0.05（20Hz）已足够在引导结束瞬间接续下一个技能。
            WR_Delay = 0.05
        else
            WR_Delay = 0.1
        end
        -- ★ SoD 适配：删除 WotLK「迈克斯纳」特例（20Hz 节流）；SoD 无此 BOSS，引导末段仍走 0.05
        if WR_Show["刷新率"] then
            print("当前刷新率:", WR_Delay, "，当前游戏时间")
        end
        -- ★ P0-2：节流已在外层累加器完成，此处直接执行重逻辑（do 块保留原有 return 语义）
        do
            if WR_Profiling then WR_ProfileSamples = WR_ProfileSamples + 1 end

            -- ★ A：段打点（仅采样开启时计时代价可忽略）
            local p_t0 = WR_Profiling and debugprofilestop() or 0
            WR_UpdateFrameState()
            if WR_Profiling then WR_ProfileAcc["1.UpdateFrameState"] = (WR_ProfileAcc["1.UpdateFrameState"] or 0) + (debugprofilestop() - p_t0) end

            p_t0 = WR_Profiling and debugprofilestop() or 0
            WR_CreateConfigFrame()
            if WR_Profiling then WR_ProfileAcc["2.CreateConfigFrame"] = (WR_ProfileAcc["2.CreateConfigFrame"] or 0) + (debugprofilestop() - p_t0) end
            -- ★ 2026-11-05：跟随系统（移植自 WotLK 时光服 MKHelper，GUID 锚定 + 动态安全按钮）
            --   顺序：上马提示(202) 优先于协同攻击(205) 优先于跟随(204)，任一占用帧则返回。
            if WR_CheckMountFollow() then
                WR_LastTime = GetTime()
                return
            end
            if WR_CheckCombatAssist() then
                WR_LastTime = GetTime()
                return
            end
            if WR_AutoFollow() then
                WR_LastTime = GetTime()
                return
            end
            -- ★ P0-3：天赋战斗中不变，缓存计算结果，仅在天赋变更事件时失效重算（见上方事件帧）
            if not WR_TalentCache then
                -- ★ 无限适配：专精探测失败时也必须把缓存写成表，
                --   否则赋值语句被错误打断 → 下一 tick 重复报错（刷屏 158x）。
                local ok, t1, t2 = pcall(WR_GetMyTalent)
                if ok then
                    WR_TalentCache = { t1, t2 }
                else
                    WR_TalentCache = {
                        (type(WR_GetDefaultSpecByClass) == "function" and WR_GetDefaultSpecByClass()) or "",
                        1,
                    }
                end
            end
            local Talent_Name, Talent_Id = WR_TalentCache[1], WR_TalentCache[2]
            local PlayerClassBase = UnitClassBase("player")
            local ClassMenu = {
                ["PALADIN"]     = Paladin_Menu,
                ["DRUID"]       = Druid_Menu,
                ["MAGE"]        = Mage_Menu,
                ["WARRIOR"]     = Warrior_Menu,
                ["PRIEST"]      = Priest_Menu,
                ["DEATHKNIGHT"] = DeathKnight_Menu,
                ["HUNTER"]      = Hunter_Menu,
                ["ROGUE"]       = Rogue_Menu,
                ["SHAMAN"]      = Shaman_Menu,
                ["WARLOCK"]     = Warlock_Menu,
            }
            -- ★ 性能优化：配置面板隐藏时（战斗中通常如此）跳过每 tick 的 UI 刷新，
            -- 仅在面板可见时才刷新（OnShow 也会触发一次），省去无谓的布局重算。
            -- ★ 但首次构建（注册全部专精斜杠命令）不依赖面板可见性：
            --   确保"不呼出面板也能用命令"（切换输出等命令在面板打开前即已注册）。
            local needBuild = (not WR_TalentFrameCreateOK)
            if WR_ConfigFrame and (WR_ConfigFrame:IsShown() or needBuild) then
                WR_TalentFrame(ClassMenu[PlayerClassBase], Talent_Name, Talent_Id)
            end
            p_t0 = WR_Profiling and debugprofilestop() or 0
            if WR_PriorityCheck() then
                if WR_Profiling then WR_ProfileAcc["3.PriorityCheck"] = (WR_ProfileAcc["3.PriorityCheck"] or 0) + (debugprofilestop() - p_t0) end
                return
            end
            if WR_Profiling then WR_ProfileAcc["3.PriorityCheck"] = (WR_ProfileAcc["3.PriorityCheck"] or 0) + (debugprofilestop() - p_t0) end

            -- ★ BOSS 特化检查（按职业直调单入口 WR_<Class>_BossSpecials，自查在职业文件内完成）
            -- 太阳井等单 BOSS 战默认不触发走位/切目标提示；仅当 WQZ 机制触发时才阻塞循环
            local bossTrig = false
            local dispatchName = BOSS_SPECIALS_DISPATCH[PlayerClassBase]
            local bossFn = dispatchName and _G[dispatchName]
            if bossFn then
                local okB, trig = pcall(bossFn)
                bossTrig = okB and trig
            end
            if bossTrig then
                WR_LastTime = GetTime()
                return
            end

            -- 职业循环
            p_t0 = WR_Profiling and debugprofilestop() or 0
            if PlayerClassBase == "PALADIN" then
                if type(WR_PaladinForeverRotation) == "function" then
                    WR_PaladinForeverRotation()
                end
            elseif PlayerClassBase == "DRUID" then
                -- Forever 原生循环（内部按 isForever 回退旧 SoD 三系）
                if type(WR_DruidForeverRotation) == "function" then
                    WR_DruidForeverRotation()
                end
            elseif PlayerClassBase == "MAGE" then
                if type(WR_MageForeverRotation) == "function" then
                    WR_MageForeverRotation()
                end
            elseif PlayerClassBase == "WARRIOR" then
                if type(WR_WarriorForeverRotation) == "function" then
                    WR_WarriorForeverRotation()
                end
            elseif PlayerClassBase == "PRIEST" then
                if type(WR_PriestForeverRotation) == "function" then
                    WR_PriestForeverRotation()
                end
              elseif PlayerClassBase == "DEATHKNIGHT" then
                if Talent_Name == "鲜血" and type(WR_DeathKnightBlood) == "function" then
                    WR_DeathKnightBlood()
                elseif Talent_Name == "冰霜" and type(WR_DeathKnightFrost) == "function" then
                    WR_DeathKnightFrost()
                elseif Talent_Name == "邪恶" and type(WR_DeathKnightUnholy) == "function" then
                    WR_DeathKnightUnholy()
                end
            elseif PlayerClassBase == "HUNTER" then
                -- Forever 受限 API 完整循环（内部按客户端回退到旧 SoD 三函数）
                if type(WR_HunterForeverRotation) == "function" then
                    WR_HunterForeverRotation()
                elseif Talent_Name == "野兽控制" then
                    WR_HunterBeastMastery()
                elseif Talent_Name == "射击" then
                    WR_HunterMarksmanship()
                elseif Talent_Name == "生存" then
                    WR_HunterSurvival()
                end
            elseif PlayerClassBase == "ROGUE" then
                if type(WR_RogueForeverRotation) == "function" then
                    WR_RogueForeverRotation()
                end
            elseif PlayerClassBase == "SHAMAN" then
                if type(WR_ShamanForeverRotation) == "function" then
                    WR_ShamanForeverRotation()
                end
            elseif PlayerClassBase == "WARLOCK" then
                if type(WR_WarlockForeverRotation) == "function" then
                    WR_WarlockForeverRotation()
                end
            elseif PlayerClassBase == "MONK" then
                if Talent_Name == "酒仙" and WR_MonkBrewmaster then
                    WR_MonkBrewmaster()
                elseif Talent_Name == "织雾" and WR_MonkMistweaver then
                    WR_RunHealerWithFleshPriority(WR_MonkMistweaver)
                elseif Talent_Name == "踏风" and WR_MonkWindwalker then
                    WR_MonkWindwalker()
                end
            end
            if WR_Profiling then WR_ProfileAcc["4.ClassRotation"] = (WR_ProfileAcc["4.ClassRotation"] or 0) + (debugprofilestop() - p_t0) end
            WR_LastTime = GetTime()
            if WR_TestCheckbox ~= nil then
                for _, TempPlayerName in ipairs(TestPlayerName) do
                    if UnitName("player") == TempPlayerName then
                        WR_TestCheckbox:SetChecked("true")
                        break
                    end
                end
                if WR_TestCheckbox:GetChecked() then
                    WR_MaxColorFrame()
                else
                    WR_MinColorFrame()
                end
            end
        end
    end
end)