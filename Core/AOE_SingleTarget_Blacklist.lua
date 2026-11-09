-- ============================================================
-- AOE_SingleTarget_Blacklist.lua
-- 功能：标记特定目标为"不应使用AOE技能"
--       当目标在黑名单中时，aoepingbi = false
-- ============================================================

aoepingbi = true

local specificTargets = {
    "腐面", "凯雷塞斯王子", "塔达拉姆王子", "瓦拉纳王子", "腐面",
    "死亡使者萨鲁法尔", "教官拉苏维奥斯", "药剂师诺斯", "格罗布鲁斯",
    "格拉斯", "迈克斯纳", "克尔苏加德", "符文大师莫尔基姆",
    "唤雷者布隆迪尔", "断钢者", "维扎克斯将军", "萨隆邪铁畸体",
    "掌炉者伊格尼斯", "观察者奥尔加隆", "坍缩星", "远古监护者",
    "穿刺者戈莫克", "维扎克斯将军", "萨隆邪铁畸体", "护卫鞭笞者",
    "寒冬亡魂", "风暴看守者埃玛尔隆", "风暴爪牙", "托里姆", "锋鳞",
    "穿刺者戈莫克",
}

local function updateAoepingbi()
    local targetName = WR_SafeUnitName("target")
    aoepingbi = true
    if targetName then
        for _, name in ipairs(specificTargets) do
            if targetName == name then
                aoepingbi = false
                break
            end
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        updateAoepingbi()
    end
end)