-- ============================================================
-- Priest/Priest_Forever_Discipline_Features.lua
-- 《魔兽世界：无限》(Forever 1.60.x) · 牧师【戒律】功能兼容层
-- ------------------------------------------------------------
-- 2026-11-18：戒律牧全部逻辑已合并进 Priest_Forever_Discipline.lua
-- （面板按钮、插入、爆发、驱散、BUFF、输出、治疗链）。
-- 本文件保留：
--   1) 旧接口 WR_PriestForeverDiscipline_Features_Pre/Post/Buffs（夹具与旧调用点兼容）
--   2) 斜杠命令 /mkhdisc /mkhdiscbuff
-- ★ 2026-11-21：面板爆发三槽位（槽位1/2/3 图标 + 爆发全开/全关/切换按钮）整体
--   下线，对应的按钮点击函数与 /mkhdiscburst、/mkhdiscslot 两条斜杠命令一并删除。
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
        "JL_BF_RACE",
    }
    for _, k in ipairs(keys) do
        print("  " .. k .. " = " .. tostring(PigSet[k]))
    end
end

SLASH_MKHDISCBUFF1 = "/mkhdiscbuff"
SlashCmdList["MKHDISCBUFF"] = function()
    print("2026-11-18 起戒律牧不再需要「韧切」开关：真言术：韧由功能图标统一维持。")
end
