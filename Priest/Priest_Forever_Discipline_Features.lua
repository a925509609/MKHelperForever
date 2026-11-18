-- ============================================================
-- Priest/Priest_Forever_Discipline_Features.lua
-- 《魔兽世界：无限》(Forever 1.60.x) · 牧师【戒律】功能兼容层
-- ------------------------------------------------------------
-- 2026-11-18：戒律牧全部逻辑已合并进 Priest_Forever_Discipline.lua
-- （面板按钮、插入、爆发、驱散、BUFF、输出、治疗链）。
-- 本文件保留：
--   1) 旧接口 WR_PriestForeverDiscipline_Features_Pre/Post/Buffs（夹具与旧调用点兼容）
--   2) 面板按钮点击函数（爆发全开/全关/切换、三个槽位循环设置）
--   3) 斜杠命令 /mkhdisc /mkhdiscburst /mkhdiscslot /mkhdiscbuff
-- 不定义任何治疗逻辑，不污染其他职业/专精。
-- ============================================================

if WR_PlayerClass and WR_PlayerClass ~= "PRIEST" then return end

local PD = WR_PriestForeverPD

local function PD_Call(name)
    if PD and type(PD[name]) == "function" then
        local ok, result = pcall(PD[name])
        return ok and result == true
    end
    return false
end

function WR_PriestForeverDiscipline_Features_Pre()
    return PD_Call("Pre")
end

function WR_PriestForeverDiscipline_Features_Post()
    return PD_Call("Post")
end

function WR_PriestForeverDiscipline_Features_Buffs()
    return PD_Call("BuffStep")
end

function WR_PriestForeverDiscipline_Features()
    if WR_PriestForeverDiscipline_Features_Pre() then return true end
    return WR_PriestForeverDiscipline_Features_Post()
end

-- ---------- 面板按钮：爆发 ----------
function WR_PriestDisciplineBurstAllOn()
    if PD and type(PD.BurstSetAll) == "function" then PD.BurstSetAll(true) end
end

function WR_PriestDisciplineBurstAllOff()
    if PD and type(PD.BurstSetAll) == "function" then PD.BurstSetAll(false) end
end

function WR_PriestDisciplineBurstToggle()
    if PD and type(PD.BurstSetAll) == "function" then PD.BurstSetAll("toggle") end
end

function WR_PriestDisciplineBurstSlot1()
    if PD and type(PD.CycleBurstSlot) == "function" then PD.CycleBurstSlot(1) end
end

function WR_PriestDisciplineBurstSlot2()
    if PD and type(PD.CycleBurstSlot) == "function" then PD.CycleBurstSlot(2) end
end

function WR_PriestDisciplineBurstSlot3()
    if PD and type(PD.CycleBurstSlot) == "function" then PD.CycleBurstSlot(3) end
end

-- ---------- 斜杠命令 ----------
SLASH_MKHDISC1 = "/mkhdisc"
SlashCmdList["MKHDISC"] = function()
    print("|cffFF69B4[MKHelperForever 戒律]|r 功能诊断（2026-11-18 戒律页同步）")
    if type(PigSet) ~= "table" or not PD then return end
    PD.InitDefaults()
    local keys = {
        "JL_FADD","JL_ZLMS","JL_QS",
        "JL_HXY","JL_HZ","JL_ZYSD","JL_KX","JL_LJZL","JL_KSZL",
        "JL_QXZLS","JL_ZLSHU","JL_CJZLS","JL_HF",
        "JL_QS_ON","JL_AYSHM","JL_ZYSR","JL_XLHZ","JL_CJ",
        "JL_CRGNZ","JL_CRXX","JL_CRZLDY",
        "JL_BF_S1","JL_BF_S2","JL_BF_S3","JL_BF_RACE",
        "JL_BF_SLOT1","JL_BF_SLOT2","JL_BF_SLOT3",
    }
    for _, k in ipairs(keys) do
        print("  " .. k .. " = " .. tostring(PigSet[k]))
    end
end

SLASH_MKHDISCBURST1 = "/mkhdiscburst"
SlashCmdList["MKHDISCBURST"] = function(msg)
    local m = tostring(msg or ""):match("^%s*(.-)%s*$")
    if not PD then return end
    if m == "on" or m == "all" or m == "全开" then
        PD.BurstSetAll(true)
    elseif m == "off" or m == "none" or m == "全关" then
        PD.BurstSetAll(false)
    elseif m == "toggle" or m == "切换" then
        PD.BurstSetAll("toggle")
    else
        print("用法: /mkhdiscburst on|off|toggle（对应面板 爆发全开/全关/切换）")
    end
end

SLASH_MKHDISCSLOT1 = "/mkhdiscslot"
SlashCmdList["MKHDISCSLOT"] = function(msg)
    local idx, name = tostring(msg or ""):match("^%s*([123])%s+(.-)%s*$")
    if not idx or type(PigSet) ~= "table" then
        print("用法: /mkhdiscslot <1|2|3> <技能名|off>（off = 恢复未设置）")
        return
    end
    local var = "JL_BF_SLOT" .. tonumber(idx)
    if name == "" or name == "off" or name == "未设置" or name == "nil" then
        PigSet[var] = nil
    else
        PigSet[var] = name
    end
    print("|cffFF69B4[MKHelperForever 戒律]|r 爆发槽位 " .. idx .. " = " .. tostring(PigSet[var] or "未设置"))
end

SLASH_MKHDISCBUFF1 = "/mkhdiscbuff"
SlashCmdList["MKHDISCBUFF"] = function()
    print("2026-11-18 起戒律牧不再需要「韧切」开关：真言术：韧由功能图标统一维持。")
end
