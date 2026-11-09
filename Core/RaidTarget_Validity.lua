-- ============================================================
-- RaidTarget_Validity.lua
-- 功能：判断团队中每个成员的目标是否有效（可攻击、在战斗中、非黑名单等）
--       结果存储在全局变量 raidmubiao[i] 中
-- ============================================================

for i = 1, 25 do
    _G["raidmubiao" .. i] = false
end

-- ★ 性能优化（团本）：缓存每个成员目标的昂贵判定结果，避免每 tick 全量扫描光环
--   memberState[i] = { guid=上次目标GUID, skip=上次 ShouldSkipTarget 结果, lastScan=上次光环扫描时间 }
--   原实现每 0.1s 对 25 个成员各做一次 ShouldSkipTarget（最多 40×3 次 UnitBuff/UnitDebuff 扫描），
--   在 25 人团本下约等于 3 万次/秒的 Unit API 调用。改为：便宜字段每 tick 算，
--   昂贵的光环/黑名单扫描仅在「目标 GUID 变化」或「每隔 AURA_RESCAN_INTERVAL 秒」时执行。
local memberState = {}
for i = 1, 25 do
    memberState[i] = { guid = nil, skip = false, lastScan = 0 }
end

-- 重新扫描光环/黑名单的最大间隔（秒）。光环不会每帧变化，0.5s 对目标选择足够。
local AURA_RESCAN_INTERVAL = 0.5

-- ★ 黑名单（完全排除的目标）
local EXCLUDED_MOBS = {
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
    ["黑暗邪使艾蒂丝"] = true,
    ["光明邪使菲奥拉"] = true,
    ["瓦拉纳王子"] = true,
    ["塔达拉姆王子"] = true,
    ["凯雷塞斯王子"] = true,
    ["卑劣的灵魂"] = true,
    ["达尔纳文"] = true,
    ["巫妖王"] = true,
}

-- ★ 目标带有这些buff时跳过
local SKIP_IF_HAS_BUFF = {
    ["玄秘遮蔽"] = true,
    ["暗影屏障"] = true,
}

-- ★ 目标带有这些debuff时跳过
local SKIP_IF_HAS_DEBUFF = {
    ["统御心灵"] = true,
}

-- ★ 检查目标是否带有指定buff
local function HasBuff(unit, buffName)
    for i = 1, 40 do
        local name = UnitBuff(unit, i)
        if not name then break end
        if name == buffName then return true end
    end
    return false
end

-- ★ 检查目标是否带有指定debuff
local function HasDebuff(unit, debuffName)
    for i = 1, 40 do
        local name = UnitDebuff(unit, i)
        if not name then break end
        if name == debuffName then return true end
    end
    return false
end

-- ★ 判断是否应跳过该目标（昂贵：含最多 40×N 次光环扫描）
local function ShouldSkipTarget(unit)
    local targetName = UnitName(unit) or ""

    -- 黑名单
    if EXCLUDED_MOBS[targetName] then
        return true
    end

    -- 检查buff
    for buffName, _ in pairs(SKIP_IF_HAS_BUFF) do
        if HasBuff(unit, buffName) then
            return true
        end
    end

    -- 检查debuff
    for debuffName, _ in pairs(SKIP_IF_HAS_DEBUFF) do
        if HasDebuff(unit, debuffName) then
            return true
        end
    end

    -- 瓦格里暗影戒卫者：血量低于50%时跳过
    if targetName == "瓦格里暗影戒卫者" then
        local currentHP = WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1))
        local maxHP = WR_SafeNumber(UnitHealthMax(unit), 1)
        if maxHP > 0 and (currentHP / maxHP * 100) < 50 then
            return true
        end
    end

    -- 血量低于25%时跳过（防止抢击杀）
    do
        local currentHP = WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1))
        local maxHP = WR_SafeNumber(UnitHealthMax(unit), 1)
        if maxHP > 0 and (currentHP / maxHP * 100) < 25 then
            return true
        end
    end

    -- 血量少于80000时跳过
    if WR_SafeNumber(UnitHealth(unit), WR_SafeNumber(UnitHealthMax(unit), 1)) < 80000 then
        return true
    end

    return false
end

-- ★ 更新所有团队目标的有效性
local function UpdateRaidTargets()
    local now = GetTime()
    local n = IsInRaid() and GetNumGroupMembers() or 0
    if n > 25 then n = 25 end
    for i = 1, n do
        local targetUnit = "raid" .. i .. "target"
        local st = memberState[i]
        if UnitExists(targetUnit) then
            -- 便宜字段：每 tick 都算，开销可忽略（约 3 次 Unit 调用/成员）
            local baseValid = UnitCanAttack("player", targetUnit)
                            and UnitIsEnemy("player", targetUnit)
                            and UnitAffectingCombat(targetUnit)
            if not baseValid then
                _G["raidmubiao" .. i] = false
                st.guid = UnitGUID(targetUnit)   -- 记录以便检测目标变化
            else
                -- 基础有效，需做昂贵的黑名单/光环检查（仅在目标变化或达到重扫间隔时）
                local guid = UnitGUID(targetUnit)
                if guid ~= st.guid or (now - st.lastScan >= AURA_RESCAN_INTERVAL) then
                    st.skip = ShouldSkipTarget(targetUnit)
                    st.guid = guid
                    st.lastScan = now
                end
                _G["raidmubiao" .. i] = not st.skip
            end
        else
            if st.guid ~= nil then
                st.guid = nil
                st.lastScan = 0
            end
            _G["raidmubiao" .. i] = false
        end
    end
end

-- ★ 定时更新（每0.2秒，原0.1秒；目标选择无需 10Hz，半频即可明显降低团本开销）
local frame = CreateFrame("Frame")
frame.timer = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    self.timer = self.timer + elapsed
    if self.timer >= 0.2 then
        UpdateRaidTargets()
        self.timer = 0
    end
end)
