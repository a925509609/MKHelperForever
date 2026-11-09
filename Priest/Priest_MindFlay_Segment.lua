-- ============================================================
-- Priest_MindFlay_Segment.lua
-- 功能：监控精神鞭笞的引导进度，判断是否进入第二段（约33%进度）
--       用于在合适的时机打断施法以优化输出
-- ============================================================

if WR_PlayerClass ~= "PRIEST" then return end

bianchi_shengyushijian = 0   -- 剩余引导时间（秒）
erduanbianzi = false         -- 是否进入第二段

local SPELL_NAME = "精神鞭笞"
local SPELL_NAME_TW = "精神鞭笞"
local totalDuration = 0
local enteredSegment = false

local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.1 then return end
    self.elapsed = 0
    local name, _, _, startTime, endTime = UnitChannelInfo("player")

    if name == SPELL_NAME or name == SPELL_NAME_TW then
        if startTime and endTime then
            local currentTime = GetTime() * 1000
            local remaining = (endTime - currentTime) / 1000
            bianchi_shengyushijian = math.max(0, remaining)

            if totalDuration < remaining then
                totalDuration = remaining
                enteredSegment = false
            end

            -- 判断是否进入第二段（剩余时间 <= 总时间的 1/3）
            local segmentPoint = totalDuration * 0.333
            if not enteredSegment and remaining <= segmentPoint then
                enteredSegment = true
                erduanbianziStart = GetTime()
                erduanbianziEnd = erduanbianziStart + 0.2
            end

            local now = GetTime()
            if enteredSegment and now >= erduanbianziStart and now <= erduanbianziEnd then
                erduanbianzi = true
            else
                erduanbianzi = false
            end
        else
            bianchi_shengyushijian = 0
            erduanbianzi = false
        end
    else
        bianchi_shengyushijian = 0
        erduanbianzi = false
        enteredSegment = false
        totalDuration = 0
    end
end)

-- 初始化
bianchi_shengyushijian = 0
erduanbianzi = false
enteredSegment = false
totalDuration = 0