-- ============================================================
-- 工程学技能检测器
-- 功能：检测玩家是否具备 "通用热力工程炸药" 使用条件（工程学 >= 400）
-- 用途：在插件逻辑中判断是否能使用工程学炸药/道具
-- 特色：提供 /checkeng 聊天命令，可随时手动刷新状态
-- ============================================================

-- ===== 全局变量：表示是否掌握"通用热力"（工程学 >= 400） =====
tongyongreli = false

-- ===== 更新工程学状态的核心函数 =====
local function UpdateEngineeringStatus()
  -- ★ 无限适配：1.60.x 已移除 GetNumSkillLines / GetSkillLineInfo 全局函数，
  --   原实现在 PLAYER_LOGIN / SKILL_LINES_CHANGED 时必抛
  --   "attempt to call a nil value"。统一转调本文件后半段的多 API 鲁棒实现
  --   （GetProfessions → GetSkillLineInfo → IsPlayerSpell），由后者刷新 tongyongreli。
  --   注：WR_CheckEngineering_BExt 在事件触发时必然已定义。
  if type(WR_CheckEngineering_BExt) == "function" then
    WR_CheckEngineering_BExt()
    return
  end
  tongyongreli = false
end

-- ===== 创建事件监听帧 =====
local frame = CreateFrame("Frame")

-- 注册两个事件：
--   PLAYER_LOGIN          ：玩家登录时触发（首次进入游戏）
--   SKILL_LINES_CHANGED   ：专业技能变化时触发（升级工程学、遗忘/学习专业等）
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("SKILL_LINES_CHANGED")

-- 绑定事件处理函数：每次触发事件都重新检测工程学等级
frame:SetScript("OnEvent", UpdateEngineeringStatus)

-- ===== 添加游戏内聊天命令：/checkeng =====
-- 玩家在聊天框输入 /checkeng 即可手动刷新工程学状态（用于调试或验证）
SLASH_CHECKENG1 = "/checkeng"
SlashCmdList["CHECKENG"] = UpdateEngineeringStatus

-- ============================================================
-- 使用说明：
--   1. 全局变量 tongyongreli 为 true 表示玩家工程学 >= 400
--   2. 其他模块可以直接读取 tongyongreli 来决定是否使用工程学道具
--   3. 如果升级了工程学，无需重载界面，系统会自动更新状态
--   4. 手动输入 /checkeng 可以立即强制刷新状态，方便调试
-- ============================================================

-- ============================================================
-- ★ 维度4 装备/物品管理 BExt 扩展（来源：ZZHELPER_Wrath/Equipment.lua）
-- 命名 WR_*_BExt；已剥离 ZZ_Shared_ItemAndProfessionHelpers_* / ZZHELPER_IS_TITAN 依赖。
-- 说明：以下 _H（通用装备槽冷却检测）→ A 已有 WR_GetEquipCD；
--       ZZ_CanUseGloves（工程手套可用性）→ A 已有 WR_CanUseGloves（MainLoop.lua:60）。
--       二者无需重复实现，本段仅补充 B 其余装备/工程检测函数。
-- ============================================================

-- ★ 工程学检测（多 API 兼容，鲁棒版）（B: ItemAndProfessionHelpers_G）
-- 返回：learned, skillLevel, source, reliable；并同步刷新全局 tongyongreli（工程学>=400）
-- 注：时光服(WLK)按 Titan 分支处理，要求工程学 >= 400 点。
function WR_CheckEngineering_BExt()
    local ENGINEERING_SKILL_LINE_ID = 202
    local ENGINEERING_RANK_SPELL_IDS = { 4036, 4037, 4038, 12656, 30350, 51306 }
    local engineeringName = GetSpellInfo and GetSpellInfo(4036) or "工程学"
    local function localMatch(name, engName)
        if not name then return false end
        if engName and name == engName then return true end
        return GetLocale and GetLocale() == "zhCN" and string.find(name, "工程", 1, true) ~= nil
    end
    if GetProfessions and GetProfessionInfo then
        local p1, p2 = GetProfessions()
        for _, p in pairs({ p1, p2 }) do
            if p then
                local name, _, skillLevel, _, _, _, skillLine, _, _, _, skillLineName = GetProfessionInfo(p)
                if skillLine == ENGINEERING_SKILL_LINE_ID
                   or localMatch(name, engineeringName)
                   or localMatch(skillLineName, engineeringName) then
                    tongyongreli = (skillLevel >= 400)
                    return true, tonumber(skillLevel) or 0, "GetProfessionInfo", true
                end
            end
        end
    end
    if GetNumSkillLines and GetSkillLineInfo then
        local ready = false
        for i = 1, GetNumSkillLines() do
            local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
            if skillName then ready = true end
            if not isHeader and localMatch(skillName, engineeringName) then
                tongyongreli = (skillRank >= 400)
                return true, tonumber(skillRank) or 0, "GetSkillLineInfo", true
            end
        end
        if ready then
            tongyongreli = false
            return false, 0, "GetSkillLineInfo", true
        end
    end
    if IsPlayerSpell then
        for i = 1, #ENGINEERING_RANK_SPELL_IDS do
            if IsPlayerSpell(ENGINEERING_RANK_SPELL_IDS[i]) then
                tongyongreli = true
                return true, 0, "IsPlayerSpell", true
            end
        end
    end
    tongyongreli = false
    return false, 0, "职业数据未就绪", false
end

-- ★ 检查是否装备了指定 ID 的物品（B: ItemAndProfessionHelpers_C）
function WR_CheckEquipItemID_BExt(ID)
    for i = 1, 19 do
        if GetInventoryItemID("player", i) == ID then
            return true
        end
    end
    return false
end

-- ★ 获取当前主手武器类型（B: ItemAndProfessionHelpers_I）
--   无限 12.x 安全：GetItemInfo 可能缺失，回退 C_Item.GetItemInfo
local function WR_ItemSubType_BExt(itemLink)
    if not itemLink then return nil end
    if type(GetItemInfo) == "function" then
        local ok, _, _, subtype = pcall(GetItemInfo, itemLink)
        if ok and type(subtype) == "string" then return subtype end
    end
    if type(C_Item) == "table" and type(C_Item.GetItemInfo) == "function" then
        local ok, t = pcall(C_Item.GetItemInfo, itemLink)
        if ok then
            if type(t) == "table" then return t.itemSubType or t.subType or t.classID end
            if type(t) == "string" then return t end
        end
    end
    return nil
end

function WR_GetMainHandType_BExt()
    local link = GetInventoryItemLink("player", 16)
    if link == nil then
        return "没有武器"
    end
    local subType = WR_ItemSubType_BExt(link)
    if subType == "INVTYPE_2HWEAPON" then
        return "双手武器"
    elseif subType == "INVTYPE_WEAPON" then
        return "单手武器"
    end
    return false
end

-- ★ 统计当前装备中匹配特定物品 ID 列表的数量（B: ItemAndProfessionHelpers_J）
function WR_CountEquipItemIDs_BExt(TName)
    local TCount = 0
    for i = 1, 19 do
        local itemID = GetInventoryItemID("player", i)
        for _, id in pairs(TName) do
            if itemID == id then
                TCount = TCount + 1
            end
        end
    end
    return TCount
end

-- ★ 获取指定专业技能等级（B: ItemAndProfessionHelpers_D）
function WR_GetProfessionRank_BExt(Skill)
    -- ★ 无限适配：旧技能条 API 已移除时改走 GetProfessions / GetProfessionInfo
    if type(GetNumSkillLines) ~= "function" or type(GetSkillLineInfo) ~= "function" then
        if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
            local p1, p2 = GetProfessions()
            for _, p in pairs({ p1, p2 }) do
                if p then
                    local name, _, skillLevel = GetProfessionInfo(p)
                    if name and (name == Skill or
                       (GetLocale and GetLocale() == "zhCN" and
                        string.find(name, Skill, 1, true) ~= nil)) then
                        return WR_SafeNumber(skillLevel, 0)
                    end
                end
            end
        end
        return 0
    end
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
        if not isHeader and skillName == Skill then
            return WR_SafeNumber(skillRank, 0)
        end
    end
    return 0
end
