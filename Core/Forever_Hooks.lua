-- ============================================================
-- Core/Forever_Hooks.lua
-- 《魔兽世界：无限》适配挂钩层（TOC 最后加载）
-- ------------------------------------------------------------
-- 本文件在全部 Core / Boss / 职业模块加载完毕后执行，负责「缝合」。
-- ★ 钩子必须在本文件「加载时」立即安装（而非 PLAYER_LOGIN 事件里），
--   因为各职业 *_Macros.lua 在 PLAYER_ENTERING_WORLD 时才调用
--   WR_CreateMacro 建宏；只要挂钩在加载期完成，就能覆盖全部建宏调用。
--
--   【钩 1】WR_GetRuneCount  → 非死亡骑士返回 0
--           （无限首发无 DK；该函数实际调用 DK 符文 API GetRuneCount）
--
--   【钩 2】WR_CreateMacro   → 向「种族爆发宏」注入无限新增种族技能
--           （经典爆发种族只有 狂暴 / 血性狂怒 / 狮心；
--             无限新增 艾露恩之光（暗夜精灵）/ 尤里卡！（侏儒）等，
--             按玩家实际种族精确注入，避免 /cast 未知技能刷屏，
--             并做 255 字节宏长度保护）
--
--   【钩 3】WR_SoD_HasRune   → 已知在无限中不存在的符文键短路返回 false
--           （省掉死键的 GetSpellInfo 解析开销）
--
--   【钩 4】登录横幅 + Forever BOSS 表并入 + /mkfforever 状态面板
-- ============================================================

WR_Forever_HookCount = 0

-- ★ 无限适配：Lua 的函数值没有默认元表，不能往函数上挂字段。
--   原先 WR_GetRuneCount.__foreverWrapped 会抛
--   "attempt to index global 'WR_GetRuneCount' (a function value)"，
--   导致三个钩子全部安装失败。改用独立标记表记录已包装状态。
WR_Forever_Wrapped = WR_Forever_Wrapped or {}

-- ============================================================
-- ★ 种族技能译名可配置表
-- ------------------------------------------------------------
-- 下列中文名为依据官方英文名预先译定的「预期客户端名」。
-- 9/17 公开测试开服、真实 zhCN 客户端可读后，若发现名称不符，
-- 只需修正本表即可，无需改动任何逻辑。
-- ============================================================
WR_Forever_RacialSpellNameOverride = WR_Forever_RacialSpellNameOverride or {
    -- 英文名 → 预期 zhCN 客户端名（留空则使用 Data/Forever_Racials.lua 中的译名）
    -- ["Elune's Light"] = "艾露恩之光",
    -- ["Eureka!"]       = "尤里卡！",
}

-- ============================================================
-- ★ 钩 1：死亡骑士符文数量守卫
-- ============================================================
local function InstallRuneCountGuard()
    if type(WR_GetRuneCount) ~= "function" then return false end
    if WR_Forever_Wrapped["WR_GetRuneCount"] then return true end
    local orig = WR_GetRuneCount
    WR_GetRuneCount = function(...)
        local cls = UnitClassBase and UnitClassBase("player")
        -- 无限无 DK：非 DK 职业直接返回 0，不回落到 DK 专用 API
        if cls ~= "DEATHKNIGHT"
            and type(WR_Forever_ClientInfo) == "function"
            and WR_Forever_ClientInfo().isForever then
            return 0
        end
        return orig(...)
    end
    WR_Forever_Wrapped["WR_GetRuneCount"] = true
    return true
end

-- ============================================================
-- ★ 钩 2：种族爆发宏注入
-- ============================================================

-- 取「当前玩家种族」在无限中的爆发向种族技能（仅返回本种族实际拥有的）
function WR_Forever_PlayerRacialBursts()
    local out = {}
    if type(WR_ForeverRacials) ~= "table" then return out end
    if type(WR_Forever_PlayerRace) ~= "function" then return out end
    local race = WR_Forever_PlayerRace()
    if not race then return out end

    local faction = (UnitFactionGroup and UnitFactionGroup("player")) or "Horde"
    local side = (faction == "Alliance") and "ALLIANCE" or "HORDE"
    local list = WR_ForeverRacials[side] or {}

    local override = WR_Forever_RacialSpellNameOverride or {}
    for _, r in ipairs(list) do
        local hit = (r.race == race) or (r.isNewRace and race == "Skyborne")
        if hit then
            for _, ab in ipairs(r.abilities or {}) do
                if ab.role == "burst" then
                    out[#out + 1] = override[ab.en] or ab.zh
                end
            end
        end
    end
    return out
end

-- 把注入行拼进宏体：插在最后一条含「种族特长」的行之后
local MAX_MACRO_LEN = 240   -- 暴雪宏上限 255 字节，留 15 字节安全余量
local function InjectRacialLines(body)
    if type(body) ~= "string" or body == "" then return body end
    -- 仅处理「种族爆发宏」：宏体内必须已出现种族技能
    if not (body:find("种族特长", 1, true) or body:find("血性狂怒", 1, true)) then
        return body
    end

    local extra = WR_Forever_PlayerRacialBursts()
    if #extra == 0 then return body end

    -- 过滤掉宏里已有的技能，避免重复
    local add = {}
    for _, name in ipairs(extra) do
        if name and name ~= "" and not body:find(name, 1, true) then
            add[#add + 1] = "/cast " .. name
        end
    end
    if #add == 0 then return body end

    -- 拆行 → 定位最后一条种族技能行 → 其后插入
    local lines = {}
    for line in (body .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end

    local lastRacial = nil
    for i = 1, #lines do
        if lines[i]:find("种族特长", 1, true) then lastRacial = i end
    end

    local out = {}
    for i = 1, #lines do
        out[#out + 1] = lines[i]
        if lastRacial and i == lastRacial then
            for _, l in ipairs(add) do out[#out + 1] = l end
        end
    end
    if not lastRacial then
        for _, l in ipairs(add) do out[#out + 1] = l end
    end

    local result = table.concat(out, "\n")
    -- ★ 宏长度保护：超限则放弃注入，保持原宏可用
    if #result > MAX_MACRO_LEN then return body end
    return result
end

local function InstallMacroInjector()
    if type(WR_CreateMacro) ~= "function" then return false end
    if WR_Forever_Wrapped["WR_CreateMacro"] then return true end
    local orig = WR_CreateMacro
    WR_CreateMacro = function(key, body, ...)
        -- 仅无限模式下注入；SoD 客户端保持原样
        if type(WR_Forever_ClientInfo) == "function"
            and WR_Forever_ClientInfo().isForever then
            body = InjectRacialLines(body)
        end
        return orig(key, body, ...)
    end
    WR_Forever_Wrapped["WR_CreateMacro"] = true
    return true
end

-- ============================================================
-- ★ 钩 3：SoD 符文键短路
-- ------------------------------------------------------------
-- Data/Forever_Abilities.lua 的 WR_Forever_RuneToTalent 标注了每个符文键
-- 在无限中的存活状态（talent / ability / referenced / absent）。
-- 状态 absent 的键在无限中必然拿不到技能 → 直接返回 false，跳过解析。
-- ============================================================
local function InstallRuneShortCircuit()
    if type(WR_SoD_HasRune) ~= "function" then return false end
    if WR_Forever_Wrapped["WR_SoD_HasRune"] then return true end
    local orig = WR_SoD_HasRune
    WR_SoD_HasRune = function(class, key)
        if type(WR_Forever_RuneToTalent) == "table"
            and type(WR_Forever_ClientInfo) == "function"
            and WR_Forever_ClientInfo().isForever then
            local cls = WR_Forever_RuneToTalent[class]
            local rec = cls and cls[key]
            -- absent：无限中不存在该技能，无需再走 GetSpellInfo + IsPlayerSpell
            if rec and rec.status == "absent" then
                return false
            end
        end
        return orig(class, key)
    end
    WR_Forever_Wrapped["WR_SoD_HasRune"] = true
    return true
end

-- ============================================================
-- ★ 钩 4：登录横幅 + BOSS 表并入
-- ============================================================
local FOREVER_BANNER_KEY = "MKF_BANNER_SHOWN"

local function PrintBanner()
    if type(WR_Forever_ClientInfo) ~= "function" then return end
    local info = WR_Forever_ClientInfo()
    local tag = "|cffFF69B4 MKHelperForever|r"
    if info.isForever then
        print(tag .. " |cff00ff00已启用《魔兽世界：无限》适配|r")
    elseif info.isSoD then
        print(tag .. " |cffffd100检测到探索赛季客户端，按 SoD 行为运行|r")
    else
        print(tag .. " |cff888888客户端模式：" .. tostring(info.mode) .. "|r")
    end
    if type(WR_Forever_IsNewRaceCombo) == "function" and WR_Forever_IsNewRaceCombo() then
        print("  |cffffd100本角色使用无限新增种族/职业组合，适配分支已全部启用。|r")
    end
    local bursts = WR_Forever_PlayerRacialBursts()
    if #bursts > 0 then
        print("  种族爆发技能：" .. table.concat(bursts, " / "))
    end
    print("  |cff888888输入 /mkfforever 查看完整适配状态|r")
end

-- ============================================================
-- ★ 加载期立即安装钩子（必须早于 PLAYER_ENTERING_WORLD 建宏）
-- ============================================================
do
    local n = 0
    if InstallRuneCountGuard()   then n = n + 1 end
    if InstallMacroInjector()    then n = n + 1 end
    if InstallRuneShortCircuit() then n = n + 1 end
    WR_Forever_HookCount = n
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event)
    -- BOSS 表并入（延迟到事件期，确保 WR_BossMechanics 已就绪）
    if type(WR_Forever_MergeBossMechanics) == "function" then
        if WR_Forever_MergeBossMechanics() > 0 then
            WR_Forever_HookCount = (WR_Forever_HookCount or 0) + 1
        end
    end
    if event == "PLAYER_LOGIN" and not WR_Show[FOREVER_BANNER_KEY] then
        WR_Show[FOREVER_BANNER_KEY] = true
        PrintBanner()
    end
end)

-- ============================================================
-- ★ /mkfforever 适配状态面板
-- ============================================================
SLASH_MKFFOREVER1 = "/mkfforever"
SlashCmdList["MKFFOREVER"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    if msg == "rehook" then
        local n = 0
        if InstallRuneCountGuard()   then n = n + 1 end
        if InstallMacroInjector()    then n = n + 1 end
        if InstallRuneShortCircuit() then n = n + 1 end
        WR_Forever_HookCount = n
        print("|cff00ff00[MKHelperForever]|r 已重新校验适配钩子，当前 " .. n .. " 个生效。")
        return
    end

    local info = WR_Forever_GetClientInfo()
    _clientInfo = info
    print("|cffFF69B4[MKHelperForever]|r 适配状态：")
    print("  客户端      : " .. tostring(info.mode) .. "   (" .. tostring(info.modeSource) .. ")")
    print("  已装钩子    : " .. tostring(WR_Forever_HookCount or 0) .. " 个")

    if type(WR_GetTalent) == "function" then
        local name = WR_GetTalent()
        print("  当前专精    : " .. tostring(name))
    end
    if type(WR_Forever_PlayerRace) == "function" then
        local race = WR_Forever_PlayerRace()
        local newCombo = type(WR_Forever_IsNewRaceCombo) == "function" and WR_Forever_IsNewRaceCombo()
        print("  种族        : " .. tostring(race) .. (newCombo and "  |cffffd100(无限新增)|r" or ""))
    end

    local token = UnitClassBase and UnitClassBase("player")
    local abs = (type(WR_ForeverAbilities) == "table" and token and WR_ForeverAbilities[token]) or {}
    print("  天赋主动技能: " .. #abs .. " 个（本职业，见 Data/Forever_Abilities.lua）")

    if type(WR_Forever_RuneToTalent) == "table" and token then
        local cls = WR_Forever_RuneToTalent[token]
        if cls then
            local t = { talent = 0, ability = 0, referenced = 0, absent = 0 }
            for _, v in pairs(cls) do
                if t[v.status] then t[v.status] = t[v.status] + 1 end
            end
            print(string.format("  SoD 符文存活: 天赋同名 %d / 技能命中 %d / 描述引用 %d / 未见于天赋数据 %d",
                t.talent, t.ability, t.referenced, t.absent))
        end
    end

    if type(WR_ForeverBossInstances) == "table" then
        print("  无限首发副本: " .. #WR_ForeverBossInstances .. " 座（/mkfboss list 查看）")
    end

    print("  |cff888888命令：/mkfclient 客户端诊断 · /mkfmode 手工指定模式 · /mkfboss 副本 · /mkfforever rehook 校验钩子|r")
end
