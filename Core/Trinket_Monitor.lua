-- ============================================================
-- Trinket_Monitor.lua
-- 功能：持续监控玩家饰品buff和冷却状态（通过 OnUpdate 轮询）
--       实时更新全局爆发标志：baofa3, baofa10, baofa15, baofa20, baofamax
--       支持多版本饰品（含熊猫人之谜版本）
-- ============================================================

-- ============================================================
-- ★ 饰品数据表（含熊猫人之谜版本）
-- ============================================================
local trinketData = {
    -- ===== SoD 探索赛季饰品（P1-P4，buff 名为使用时自身增益名，待客户端核对）=====
    { trinketName = "陀螺实验420b", buffName = "超频", cooldown = 60, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "暗月卡片：沙暴", buffName = "沙暴", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "复仇者虚空珍珠", buffName = "虚空灌注", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "野兽之广袤", buffName = "野兽之广袤", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "苏醒之血", buffName = "苏醒", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "窒息之握", buffName = "窒息", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "龙人之牙", buffName = "龙人之牙", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "黑铁之烟", buffName = "黑铁之烟", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "雪怒圣物", buffName = "天神祝福", cooldown = 55, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "玉珑圣物", buffName = "天神祝福", cooldown = 55, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "雷神的遗诏", buffName = "鼎力", cooldown = 55, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "秩序之光", buffName = "升华", cooldown = 55, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "黑雾漩涡", buffName = "敏锐", cooldown = 55, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "碳酸红宝石", buffName = "蓄力一击", cooldown = 115, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "玉质御者俑", buffName = "提速", cooldown = 55, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "萦雾之恐", buffName = "无情打击", cooldown = 55, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "群星之瓶", buffName = "敏捷", cooldown = 55, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "惊怖精华", buffName = "迅疾如风", cooldown = 55, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "无名巫妖的护符匣", buffName = "虹吸能量", cooldown = 100, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "被摘除的外物", buffName = "能量涌动", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "岩幔的恩惠", buffName = "恩惠", cooldown = 120, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "哈里森的炫目徽章", buffName = "硬化之壳", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "死亡的选择", buffName = "杰出", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "死亡的裁决", buffName = "杰出", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "暗月卡片：伟大", buffName = "伟大", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "密语尖牙颅骨", buffName = "寒怒", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "死神的意志", buffName = { "牦牛人的锋芒", "维库人的迅捷", "铁矮人的精准", "铁矮人的专注", "维库人的急速", "牦牛人的蛮力" }, cooldown = 105, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "锐锋暮光龙鳞", buffName = "光影穿刺", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "焦黑暮光龙鳞", buffName = "暮光烈焰", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "兽魂狂暴之石", buffName = "大师之能", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "兽魂狂暴雕像", buffName = "虎豹之敏", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "消逝的诅咒", buffName = "濒死诅咒", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "彗星之痕", buffName = "彗星之痕", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "安努尔之书", buffName = "圣歌之力", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "海洋之力", buffName = "台风", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "卡德罗斯的印记", buffName = "非凡战力", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "磁力之镜", buffName = "极化", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "巫术沙漏", buffName = "巫术时刻", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "黑暗潜藏卷须", buffName = "黑暗卷须", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "土灵领主徽记", buffName = "土灵怒火", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "装备探测器", buffName = "侦测到装备！", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "司克诺兹的统御奖章", buffName = "硬化之壳", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "抚慰之心", buffName = "振奋", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "磁力之镜", buffName = "极化", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "海洋之力", buffName = "台风", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "提亚的优雅", buffName = "恩赐", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "拉夏的右眼", buffName = "末日之眼", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "无尽密室之匙", buffName = "终极密钥", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "邪恶命令护符", buffName = "硬化之壳", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "暗月卡片：火山", buffName = "火山毁灭", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "杀戮执照", buffName = "斩杀者", cooldown = 45, lastTrigger = -math.huge, stacks = 10 },
    { trinketName = "青春的躁动", buffName = "胜利之悦", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "穿流之亡", buffName = "死亡之河", cooldown = 45, lastTrigger = -math.huge, stacks = 10 },
    { trinketName = "脓血莓嗅盐", buffName = "精神充沛", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "狂怒之心", buffName = "狂怒之心", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "压顶之力", buffName = "生死极速", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "普瑞斯托的诡计护符", buffName = "邪恶意图", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "雕像 - 野猪之王", buffName = "野猪之王", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "怒炉之怒", buffName = "铸炼怒火", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "缚魂之匣", buffName = "灵魂之力", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "气旋精华", buffName = "扭曲", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "灵魂之恸", buffName = "台风", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "消逝的诅咒", buffName = "濒死诅咒", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "蜘蛛的拥抱", buffName = "蜘蛛之拥", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "流放者的日晷", buffName = "就是现在！", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "真实之镜", buffName = "痛苦反射", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "死亡之钟", buffName = "死亡之钟", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "命运之鳞", buffName = "命运之鳞", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "古神之血", buffName = "古神之血", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "蓝铁灌注器", buffName = "蓝铁灌注", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "龙母之眼", buffName = "龙母之眼", cooldown = 45, lastTrigger = -math.huge, stacks = 5 },
    { trinketName = "天堂之焰", buffName = "天堂之焰", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "黑暗物质", buffName = "内爆", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "龙魂图典", buffName = "巨龙之魂", cooldown = 45, lastTrigger = -math.huge, stacks = 10 },
    { trinketName = "天谴之石", buffName = "天谴之石", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "雷神符石", buffName = "雷神符石", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "潘多拉的恳求", buffName = "潘多拉的恳求", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "科林的铬银杯垫", buffName = "折磨反射", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "秘银怀表", buffName = "就是现在！", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "远古卤蛋", buffName = "生命精华", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "深渊符文", buffName = "能量动荡", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "穆拉丁的望远镜", buffName = "蓄能", cooldown = 45, lastTrigger = -math.huge, stacks = 10 },
    { trinketName = "圣战徽记", buffName = "阵亡者之怒", cooldown = 45, lastTrigger = -math.huge, stacks = 20 },
    { trinketName = "陨星磨石", buffName = "陨星磨石", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "海啸护符", buffName = "波涛之怒", cooldown = 60, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "逆流六分仪", buffName = "不稳定急流", cooldown = 60, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "星界螺旋", buffName = "察觉弱点", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
}

-- ============================================================
-- ★ 全局状态变量
-- ============================================================
shipin13   = 0
shipin14   = 0
shipincd13 = 0
shipincd14 = 0
baofa10    = false
baofa3     = false
baofamax   = false
baofa15    = false
baofa20    = false

-- ============================================================
-- ★ 饰品检测函数
-- ============================================================

-- ★ 安全取物品名（无限 1.60.x 客户端可能没有全局 GetItemInfo）
--   兜底顺序：GetItemInfo(itemLink) → C_Item.GetItemInfo(itemLink) → GetItemInfo(物品ID)
--   全部失败或抛错时返回 nil，调用方按「未匹配」处理，绝不向上抛异常。
local function WR_Forever_ItemName(itemLink)
    if not itemLink then return nil end

    -- ① 旧全局 GetItemInfo（存在才调）
    if type(GetItemInfo) == "function" then
        local ok, name = pcall(GetItemInfo, itemLink)
        if ok and type(name) == "string" and name ~= "" then return name end
    end

    -- ② 12.x 新命名空间 C_Item.GetItemInfo（存在才调）
    if type(C_Item) == "table" and type(C_Item.GetItemInfo) == "function" then
        local ok, name = pcall(C_Item.GetItemInfo, itemLink)
        if ok and type(name) == "string" and name ~= "" then return name end
        if ok and type(name) == "table" then
            local n = name.name or name.itemName
            if type(n) == "string" and n ~= "" then return n end
        end
    end

    -- ③ 从链接里提取物品 ID，再用 ID 查（部分客户端只认 ID）
    local itemID
    if type(itemLink) == "string" then itemID = tonumber(itemLink:match("item:(%d+)")) end
    if itemID then
        if type(C_Item) == "table" and type(C_Item.GetItemInfo) == "function" then
            local ok, name = pcall(C_Item.GetItemInfo, itemID)
            if ok and type(name) == "string" and name ~= "" then return name end
        end
        if type(GetItemInfo) == "function" then
            local ok, name = pcall(GetItemInfo, itemID)
            if ok and type(name) == "string" and name ~= "" then return name end
        end
    end

    return nil
end

-- ★ 安全读玩家一条 Buff：返回 name, count, expirationTime
--   无限 12.x 战斗中 UnitBuff 读玩家自身光环也会抛 secret 错，
--   且可能只返回 C_UnitAuras 的 table 形态，这里统一兜住；读不到返回 nil。
local function WR_Forever_PlayerBuff(index)
    local ok, a, b, c, d, e, f = pcall(UnitBuff, "player", index)
    if ok then
        -- 经典多返回值形态：name, icon, count, dispelType, duration, expirationTime
        if type(a) == "string" and a ~= "" then
            return a, tonumber(c), tonumber(f)
        end
        -- 12.x table 形态：{ name, applications, expirationTime, ... }
        if type(a) == "table" then
            return a.name, tonumber(a.applications), tonumber(a.expirationTime)
        end
    end
    return nil
end

local function checkTrinketActivation(slot)
    local itemLink = GetInventoryItemLink("player", slot)
    if not itemLink then
        if slot == 13 then
            shipin13, shipincd13 = 0, 0
        else
            shipin14, shipincd14 = 0, 0
        end
        return false, false
    end

    -- ★ 无限适配：本地 GetItemInfo 可能不存在（客户端差异），
    --   统一走 WR_Forever_ItemName 安全封装；拿不到名字按「未匹配」处理，不抛错。
    local itemName = WR_Forever_ItemName(itemLink)
    local matched = false

    for _, trinket in ipairs(trinketData) do
        if itemName == trinket.trinketName then
            matched = true
            local buffFound = false

            for j = 1, 40 do
                -- ★ 无限 12.x：UnitBuff 需 pcall 兜住（secret 值/参数形态差异）
                local buffName, count, expirationTime = WR_Forever_PlayerBuff(j)
                if not buffName then break end
                if type(expirationTime) ~= "number" then break end

                if type(trinket.buffName) == "table" then
                    for _, name in ipairs(trinket.buffName) do
                        if buffName == name and (trinket.stacks == nil or count >= trinket.stacks) then
                            local currentTime = GetTime()
                            local remainingTime = expirationTime - currentTime
                            if slot == 13 then
                                shipin13 = remainingTime
                            else
                                shipin14 = remainingTime
                            end
                            if (currentTime - trinket.lastTrigger) > trinket.cooldown then
                                trinket.lastTrigger = currentTime
                            end
                            buffFound = true
                            break
                        end
                    end
                elseif buffName == trinket.buffName and (trinket.stacks == nil or count >= trinket.stacks) then
                    local currentTime = GetTime()
                    local remainingTime = expirationTime - currentTime
                    if slot == 13 then
                        shipin13 = remainingTime
                    else
                        shipin14 = remainingTime
                    end
                    if (currentTime - trinket.lastTrigger) > trinket.cooldown then
                        trinket.lastTrigger = currentTime
                    end
                    buffFound = true
                end

                if buffFound then break end
            end

            if not buffFound then
                if slot == 13 then
                    shipin13 = 0
                else
                    shipin14 = 0
                end
            end

            local timeSinceLastTrigger = GetTime() - trinket.lastTrigger
            local cooldownRemaining = trinket.cooldown - timeSinceLastTrigger
            if slot == 13 then
                shipincd13 = math.max(0, cooldownRemaining)
            else
                shipincd14 = math.max(0, cooldownRemaining)
            end

            return true, true
        end
    end

    if slot == 13 then
        shipin13, shipincd13 = 0, 0
    else
        shipin14, shipincd14 = 0, 0
    end
    return false, true
end

-- ============================================================
-- ★ 饰品监控刷新（全局函数，供统一辅助 ticker 以 0.1s 调用）
-- ============================================================
function WR_TrinketMonitorTick()
        local matched13, has13 = checkTrinketActivation(13)
        local matched14, has14 = checkTrinketActivation(14)

        if not matched13 and not matched14 then
            baofa10, baofa3, baofamax, baofa15, baofa20 = true, true, true, true, true
        elseif matched13 and not matched14 then
            baofa10  = (shipin13 > 6)
            baofa15  = (shipin13 > 6)
            baofa20  = (shipin13 > 15)
            baofa3   = (shipin13 > 0)
            baofamax = (shipin13 > 6)
        elseif matched14 and not matched13 then
            baofa10  = (shipin14 > 6)
            baofa15  = (shipin14 > 6)
            baofa20  = (shipin14 > 15)
            baofa3   = (shipin14 > 0)
            baofamax = (shipin14 > 6)
        elseif matched13 and matched14 then
            baofa10 = (shipin13 > 0 and shipin14 > 0) or
                      (shipin13 <= 10 or shipin13 > 6) or
                      (shipin14 <= 10 or shipin14 > 6)

            baofa15 = (shipin13 > 0 and shipin14 > 0) or
                      (shipin13 <= 15 and shipin13 > 3) or
                      (shipin14 <= 15 and shipin14 > 3)

            baofa20 = (shipin13 > 0 and shipin14 > 0) or
                      (shipin13 <= 20 and shipin13 > 15) or
                      (shipin14 <= 20 and shipin14 > 15)

            baofa3 = (shipin13 > 0 and shipin14 > 0) or
                     (shipin13 > 0 and shipin13 <= 3) or
                     (shipin14 > 0 and shipin14 <= 3) or
                     (shipin13 > 0 and shipincd14 >= shipin13 - 3) or
                     (shipin14 > 0 and shipincd13 >= shipin14 - 3)

            baofamax = (shipin13 > 0 and shipin14 > 0) or
                       (shipin13 > 6) or
                       (shipin14 > 6)
        end
end

-- ============================================================
-- ★ 维度4 装备/物品管理 BExt 扩展（来源：ZZHELPER_Wrath/Equipment.lua 的 _H 饰品槽冷却）
-- 说明：B 的 ZZ_Shared_ItemAndProfessionHelpers_H(Num) 检测"指定装备槽位是否冷却完毕"，
--       饰品即槽位 13 / 14。A 已有等价实现 WR_GetEquipCD(ItemNum)（Core_Functions.lua:3144，
--       已含 enable==1 与 GCD 容差判断），此处仅做 WR_*_BExt 命名封装，便于 B 衍生逻辑统一
--       调用，不重复实现、不新增事件。_H 的"工程学门槛"仅作用于手套槽(10)，饰品槽不涉及。
-- ============================================================

-- ★ 饰品槽（13/14）是否可用（冷却已转好）（B: _H 应用于饰品槽）
function WR_GetTrinketReady_BExt(slot)
    if slot ~= 13 and slot ~= 14 then return false end
    return WR_GetEquipCD(slot)
end

-- ★ 两个饰品槽是否任一可用
function WR_GetAnyTrinketReady_BExt()
    return WR_GetEquipCD(13) or WR_GetEquipCD(14)
end