-- ============================================================
-- BLACKLIST.lua
-- 功能：管理怪物黑名单，用于近战AOE屏蔽/远程多线屏蔽DIY
--       默认屏蔽常见怪物，支持用户自定义添加/移除/列表查看
-- ============================================================

local function tContains(t, val)
    for _, v in ipairs(t) do
        if v == val then return true end
    end
    return false
end

-- 初始化黑名单存储
-- ★ 确保 PigSet 存在（防止 SavedVariables 未加载时 PigSet 为 nil）
if not PigSet then PigSet = {} end
PigSet.BLACKLIST = PigSet.BLACKLIST or {}

-- 默认屏蔽列表（可在此扩展）
local defaultBlacklist = {
    "动力炸弹",
    "黑暗之核",
    "寒冰之墓",
    -- 可继续添加默认屏蔽的怪物名称
}

-- ★ 在 ADDON_LOADED 事件中初始化默认黑名单
-- 原因：SavedVariables 在 ADDON_LOADED 时才会被加载，可能覆盖文件开头的初始化
-- 所以默认黑名单必须在 SavedVariables 加载后再添加
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "MKHelperForever" then
        -- SavedVariables 已加载，现在初始化黑名单
        if not PigSet then PigSet = {} end
        if not PigSet.BLACKLIST then PigSet.BLACKLIST = {} end
        -- 添加默认黑名单（只添加不存在的）
        for _, name in ipairs(defaultBlacklist) do
            if not tContains(PigSet.BLACKLIST, name) then
                table.insert(PigSet.BLACKLIST, name)
            end
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- 判断目标是否在黑名单中
-- checkType: "melee"=近战AOE屏蔽, "ranged"=远程多线屏蔽, "tank"=坦克屏蔽, nil=仅检查黑名单
function WR_IsBlacklisted(unit, checkType)
    if not unit or not UnitExists(unit) then return false end
    local name = UnitName(unit)
    if not name then return false end

    -- ★ 怪物屏蔽层（附加过滤，不替代黑名单）【阶段三·第二步】
    -- 优先级链：白名单(shoutaokacd) > BOSS豁免(ZZ_IsBossName) > 怪物屏蔽(IsMonsterBlocked) > 黑名单(下方)
    -- IsMonsterBlocked 内部已实现 白名单/BOSS 优先 与 MONSTER_BLOCK_ENABLED 总开关；
    -- 关闭 / 不在名单 / 白名单 / BOSS 时返回 false，不影响既有黑名单逻辑。
    -- 置于 checkType 开关判断之前，使怪物屏蔽对 melee/ranged/tank 各攻击类型均生效（与 18 处职业调用点共用此中枢）。
    if IsMonsterBlocked(name, "target") then
        return true
    end

    -- 根据检查类型判断对应开关是否开启
    if checkType == "melee" and not PigSet.MELEE_AOE_BLACKLIST then
        return false
    end
    if checkType == "ranged" and not PigSet.RANGED_MULTILINE_BLACKLIST then
        return false
    end
    if checkType == "tank" and not PigSet.TANK_BLACKLIST then
        return false
    end

    for _, black in ipairs(PigSet.BLACKLIST) do
        if string.find(name, black) then
            return true
        end
    end
    return false
end

-- 斜杠命令：/pigblacklist add/remove/list
-- ★ 使用极其独特的命令名，防止与其他插件的 /blacklist 命令冲突
-- 同时保留 /blacklist 和 /mkhbl 作为别名（在无冲突的战网里仍可使用）
SLASH_BLACKLIST1 = "/blacklist"
SLASH_BLACKLIST2 = "/mkhbl"
SLASH_BLACKLIST3 = "/pigblacklist" -- ★ 推荐使用这个，绝不会被抢
SlashCmdList["BLACKLIST"] = function(msg)
    -- ★ 运行时保护：确保 PigSet 和 PigSet.BLACKLIST 存在
    -- （SavedVariables 可能在 ADDON_LOADED 时重新赋值 PigSet，导致 BLACKLIST 字段丢失）
    if not PigSet then PigSet = {} end
    if not PigSet.BLACKLIST then PigSet.BLACKLIST = {} end

    local args = {}
    for w in string.gmatch(msg or "", "%S+") do
        table.insert(args, w)
    end

    if #args == 0 then
        print("|cff00adf0[黑名单]|r 用法：")
        print("  /pigblacklist add 怪物名 (推荐，无冲突)")
        print("  /pigblacklist remove 怪物名")
        print("  /pigblacklist list")
        print("  （/blacklist 和 /mkhbl 可能会与其他插件冲突）")
        return
    end

    local cmd = args[1]
    if cmd == "add" then
        if #args < 2 then print("|cffff0000错误|r: 请指定怪物名") return end
        local name = table.concat(args, " ", 2)
        if not tContains(PigSet.BLACKLIST, name) then
            table.insert(PigSet.BLACKLIST, name)
            print(string.format("|cff00ff00已添加黑名单|r: %s", name))
        else
            print(string.format("|cffff8800黑名单已存在|r: %s", name))
        end
    elseif cmd == "remove" then
        if #args < 2 then print("|cffff0000错误|r: 请指定怪物名") return end
        local name = table.concat(args, " ", 2)
        for i, v in ipairs(PigSet.BLACKLIST) do
            if v == name then
                table.remove(PigSet.BLACKLIST, i)
                print(string.format("|cff00ff00已移除黑名单|r: %s", name))
                return
            end
        end
        print(string.format("|cffff0000未找到黑名单|r: %s", name))
    elseif cmd == "list" then
        if #PigSet.BLACKLIST == 0 then
            print("黑名单为空")
        else
            print("|cff00adf0当前黑名单|r:")
            for i, v in ipairs(PigSet.BLACKLIST) do
                print(string.format("  %d. %s", i, v))
            end
        end
    else
        print(string.format("|cffff0000未知命令|r: %s", cmd))
    end
end