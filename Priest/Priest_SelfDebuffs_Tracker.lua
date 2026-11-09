-- ============================================================
-- Priest_SelfDebuffs_Tracker.lua
-- 功能：追踪牧师自身对目标、焦点、鼠标指向施加的
--       吸血鬼之触、暗言术：痛、噬灵疫病的剩余时间
--       结果存储在全局变量中（chu/tong/shiling 等）
-- ============================================================

if WR_PlayerClass ~= "PRIEST" then return end

if UnitClassBase("player") ~= "PRIEST" then
    return
end

chu, tong, shiling = nil, nil, nil
fchu, ftong, fshiling = nil, nil, nil
mchu, mtong, mshiling = nil, nil, nil

local function GetMyDebuffs(unit)
    local localChu, localTong, localShiling

    for i = 1, 40 do
        local name, _, _, _, _, expirationTime, source = UnitDebuff(unit, i)
        if not name then break end

        if source == "player" then
            if name == "吸血鬼之触" then
                localChu = expirationTime - GetTime()
            elseif name == "暗言术：痛" then
                localTong = expirationTime - GetTime()
            elseif name == "噬灵疫病" then
                localShiling = expirationTime - GetTime()
            end
        end

        if localChu and localTong and localShiling then
            break
        end
    end

    return localChu, localTong, localShiling
end

local frame = CreateFrame("Frame", "MyDebuffWatcher", UIParent)
frame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.1 then return end
    self.elapsed = 0
    chu, tong, shiling = GetMyDebuffs("target")
    fchu, ftong, fshiling = GetMyDebuffs("focus")
    mchu, mtong, mshiling = GetMyDebuffs("mouseover")
end)