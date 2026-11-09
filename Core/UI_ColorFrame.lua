-- ============================================================
-- UI_ColorFrame.lua
-- 功能：创建两组彩色提示框（左上/右上），用于显示当前施放的技能或状态，
--       每个技能对应一个预定义的颜色值（BGR格式）
-- ============================================================

-- 创建宏（绑定按键执行宏命令）
-- 说明：纯 /run 或 /script 自定义脚本宏不走宏文本（否则暴雪会弹“自定义脚本”确认框），
--       而是用普通按钮的 OnClick 直接执行 Lua；按键触发时经过的是 addon 按键回调而非宏解析，故无弹窗，
--       且在战斗中也可由 addon 按键回调正常执行（不依赖安全动作按钮）。
local function WR_ExtractRunLua(Text)
    if not Text or Text == "" then return nil end
    -- 仅当整段宏就是单一 /run 或 /script 语句时才提取（混合 /cast 等指令的宏仍走正常宏文本路径）
    return Text:match("^%s*/run%s+(.-)%s*$") or Text:match("^%s*/script%s+(.-)%s*$")
end

-- ★★ 2026-11-09 关键修复「莫名其妙把队友/目标设成焦点」
-- ------------------------------------------------------------
-- 现象（/mkpal 实证）：脱战状态下 AHK 发了 ALT-SHIFT-PAGEUP
--   → 宏 ALT-SHIFT-PAGEUP → /focus [@party2,exists,nodead,nocombat]
--   → 焦点被设成队伍第 2 人。而当时插件只点亮过「神圣之盾」（色块槽 24），
--   插件从未点亮任何焦点色块，FocusCast 也未激活。
--
-- 已确认的两个问题：
--   ① 【探针重复挂载 · 日志放大】原实现在 WR_CreateMacro 里无条件
--      HookScript("PreClick")。而各职业 *_Macros.lua 的 CreateClassesMacro()
--      会在 PLAYER_ENTERING_WORLD 与每次 PLAYER_REGEN_ENABLED 重跑，
--      于是每脱战一次就多挂一个探针 → 同一次按键被记成 N 条。
--      这就是 /mkpal 里「同一时间戳连出 6 条」的真正来源：
--      不是 AHK 连发 6 次，而是 1 次按键被 6 个探针各记了一遍。
--      → 已改为「每个按钮只挂一次」，并在探针里实时读门控状态。
--
--   ② 【AHK 误发键无任何防线】AHK 启动器按「取色 → 就近匹配 → 发键」工作，
--      取色点是窗口客户区左上角；HUD/提示框/鼠标/边框压住采样点、或
--      PrintWindow 拿到偏色帧时，都可能匹配到别的颜色并发出对应按键。
--      一旦发出的正好是 /focus 键位，玩家的焦点就被抢走。
--      （已核对：插件 ColorTable 与 AHK ColorMap 逐槽一致，1 单位相邻对
--        在 AHK 侧「精确命中优先 + 反序匹配 + 就近取最小」的算法下不会串键，
--        所以这不是颜色表错位，而是取色本身不可靠。详见 .workbuddy/ahk_full_match.py）
--
-- 插件侧无法约束 AHK 的取色精度，但可以约束「这个键到底做不做事」：
--   把「只为跟随系统服务」的那批 /focus 宏（[@partyN] / [@raidN] 系列，
--   即色块 96-100 / 121-145 / 151-179 对应的键位）在跟随关闭时降级为空宏：
--   键位仍在（不破坏 AHK 按键表），但不执行任何动作，AHK 误发只是空按一下，
--   绝不会再把队伍成员设成焦点。
--   ★ 不动这两类，避免破坏正常功能：
--     · CTRL-SHIFT-F（色块 203「设置焦点」，[@target,...,help]）—— 玩家手动设焦点；
--     · SHIFT--（色块 116，[@target,...,help]）—— 手动设焦点。
--   跟随开启时行为与原来完全一致；PreClick 探针保留，/mkpal 仍能看到
--   「AHK 按了这个键，但被门控拦下」。
--   所有被门控的 /focus 宏原始文本登记在 WR_FocusMacroRegistry，
--   跟随开关切换时由 WR_ReapplyFocusMacros() 重新按当前状态注册。
WR_FocusMacroRegistry = WR_FocusMacroRegistry or {}

-- 判断是否属于「跟随系统专用」的 /focus 宏（partyN / raidN 系列）
local function WR_IsFollowFocusMacroText(Text)
    if type(Text) ~= "string" then return false end
    if not Text:find("/focus", 1, true) then return false end
    return (Text:find("[@party", 1, true) ~= nil)
        or (Text:find("[@raid", 1, true) ~= nil)
end

function WR_ShouldGateFocusMacro(Text)
    if not WR_IsFollowFocusMacroText(Text) then return false end
    return not (PigSet and PigSet.AUTO_FOLLOW_ENABLED)
end

-- 原注册实现（不加门控），供 WR_CreateMacro / WR_ReapplyFocusMacros 共用。
-- 参数：KeyBinding 键位；Text 实际生效的宏文本；ProbeText 原始宏文本（记账用）；
--       Gated 是否被门控降级（记账用）。
local function WR_CreateMacroRaw(KeyBinding, Text, ProbeText, Gated)
    local btnName = "WR_HiddenMacroBtn_" .. KeyBinding

    -- ★ 纯 /run /script 自定义脚本：普通按钮 + OnClick 直接执行 Lua，避免宏脚本确认弹窗
    local luaCode = WR_ExtractRunLua(Text)
    if luaCode then
        local LuaBtn = _G[btnName]
        if not LuaBtn then
            LuaBtn = CreateFrame("Button", btnName, UIParent)  -- 普通按钮（非 Secure 模板），OnClick 执行 Lua 不触发宏脚本弹窗
        end
        LuaBtn:RegisterForClicks("AnyDown", "AnyUp")
        local fn, err = loadstring(luaCode)
        if fn then
            LuaBtn:SetScript("OnClick", function()
                local ok, e = pcall(fn)
                if not ok then print("|cffff0000[宏执行错误 " .. KeyBinding .. "]|r " .. tostring(e)) end
            end)
        else
            print("|cffff0000[宏语法错误 " .. KeyBinding .. "]|r " .. tostring(err))
        end
        SetOverrideBindingClick(LuaBtn, true, KeyBinding, btnName)
        return
    end

    -- 其余：安全动作按钮 + 宏文本（支持 /cast /use /target /focus /click /console 等安全指令）
    local MacroButton = _G[btnName]
    if not MacroButton then
        MacroButton = CreateFrame("Button", btnName, UIParent, "SecureActionButtonTemplate")
    end
    MacroButton:RegisterForClicks("AnyDown", "AnyUp")
    MacroButton:SetAttribute("type", "macro")
    MacroButton:SetAttribute("macrotext", Text)

    -- ★★ 2026-11-08 焦点异常取证：给 /focus 与 /follow 类宏挂 PreClick 探针。
    --   背景：这些宏用 SetOverrideBindingClick(btn, true, ...) 以「优先级覆盖」注册，
    --   会盖过同键位的普通绑定。若 AHK 误发这些键，游戏就会直接执行 /focus，
    --   表现为「莫名其妙把队友设为焦点」。此处记录：触发时刻、键位、宏文本、
    --   是否战斗中、以及**当时的当前目标**（/focus 无参时就是设当前目标为焦点）。
    --   ★ 2026-11-09：① 被门控降级的 /focus 宏也要记（否则「AHK 按了但没执行」
    --     就完全查不到，等于把证据一起关掉）；② 探针只装一次 —— 原实现每次
    --     CreateClassesMacro 都会再 HookScript 一遍，进出战斗几次后同一次按键
    --     会写出十几条重复日志，把真正有用的记录挤掉。
    local probeText = ProbeText or Text
    if type(probeText) == "string"
       and (probeText:find("/focus", 1, true) or probeText:find("/follow", 1, true)) then
        WR_FocusMacroLog = WR_FocusMacroLog or {}
        -- 门控状态挂按钮上，供探针实时读取（跟随开关切换后无需重装探针）
        MacroButton.WR_FocusGated = Gated and true or false
        MacroButton.WR_FocusProbeText = probeText
        if MacroButton.HookScript and not MacroButton.WR_FocusProbeHooked then
            MacroButton.WR_FocusProbeHooked = true
            MacroButton:HookScript("PreClick", function(self)
                local lg = WR_FocusMacroLog
                local tgt = UnitExists("target") and (UnitName("target") or "?") or "无"
                local tgtIsPlayer = UnitExists("target") and UnitIsPlayer("target") or false
                lg[#lg + 1] = string.format(
                    "[%.0fs] 宏 %s → %s%s | 战斗=%s 目标=%s(玩家=%s)",
                    GetTime(), tostring(KeyBinding), tostring(self.WR_FocusProbeText or "?"),
                    self.WR_FocusGated and "  【已拦截：跟随未开启，未执行】" or "",
                    tostring(UnitAffectingCombat("player")), tostring(tgt), tostring(tgtIsPlayer))
                if #lg > 20 then table.remove(lg, 1) end
            end)
        end
    end

    SetOverrideBindingClick(MacroButton, true, KeyBinding, btnName)
end

function WR_CreateMacro(KeyBinding, Text)
    -- 登记「跟随专用 /focus 宏」的原始文本（同键位只留一条），
    -- 供跟随开关切换时重注册
    if WR_IsFollowFocusMacroText(Text) then
        local rec
        for i = 1, #WR_FocusMacroRegistry do
            if WR_FocusMacroRegistry[i].key == KeyBinding then rec = WR_FocusMacroRegistry[i] break end
        end
        if rec then
            rec.text = Text
        else
            WR_FocusMacroRegistry[#WR_FocusMacroRegistry + 1] = { key = KeyBinding, text = Text }
        end
    end

    -- ★ 2026-11-09：跟随未开启时，跟随专用 /focus 宏降级为空宏（键位占位、零动作）
    local gated = WR_ShouldGateFocusMacro(Text)
    WR_CreateMacroRaw(KeyBinding, gated and "" or Text, Text, gated)
end

-- ★ 2026-11-09：按当前跟随开关状态，重新注册所有已登记的 /focus 宏。
--   由 WR_ToggleAutoFollow / WR_SetAutoFollow / 跟随复选框 OnClick 调用，
--   保证「勾上跟随 → 设焦键立刻可用；取消跟随 → 设焦键立刻失效」。
--   战斗中 SetAttribute 受限，故战斗内跳过（下次脱战/重注册时自动对齐）。
function WR_ReapplyFocusMacros()
    if InCombatLockdown and InCombatLockdown() then return false end
    for i = 1, #WR_FocusMacroRegistry do
        local rec = WR_FocusMacroRegistry[i]
        local gated = WR_ShouldGateFocusMacro(rec.text)
        WR_CreateMacroRaw(rec.key, gated and "" or rec.text, rec.text, gated)
    end
    return true
end

-- BGR转RGB（颜色表存储为BGR格式）
local function PIG_BGRtoBGR(bgrColor)
    local blue  = math.floor(bgrColor / 0x10000) % 0x100
    local green = math.floor(bgrColor / 0x100) % 0x100
    local red   = bgrColor % 0x100
    red   = red / 255
    green = green / 255
    blue  = blue / 255
    return blue, green, red
end

-- 颜色表（索引 -> BGR颜色值）
local ColorTable = {
    [1]   = 0x801888, [2]   = 0x178888, [3]   = 0x803888, [4]   = 0x180888,
    [5]   = 0x805888, [6]   = 0x182888, [7]   = 0x807888, [8]   = 0x184888,
    [9]   = 0x809888, [10]  = 0x186888, [11]  = 0x811888, [12]  = 0x188888,
    [13]  = 0x813888, [14]  = 0x190888, [15]  = 0x815888, [16]  = 0x192888,
    [17]  = 0x817888, [18]  = 0x162888, [19]  = 0x819888, [20]  = 0x164888,
    [21]  = 0x821888, [22]  = 0x166888, [23]  = 0x823888, [24]  = 0x168888,
    [25]  = 0x825888, [26]  = 0x170888, [27]  = 0x827888, [28]  = 0x172888,
    [29]  = 0x829888, [30]  = 0x174888, [31]  = 0x831888, [32]  = 0x176888,
    [33]  = 0x833888, [34]  = 0x146888, [35]  = 0x835888, [36]  = 0x148888,
    [37]  = 0x837888, [38]  = 0x150888, [39]  = 0x839888, [40]  = 0x152888,
    [41]  = 0x841888, [42]  = 0x154888, [43]  = 0x843888, [44]  = 0x156888,
    [45]  = 0x845888, [46]  = 0x158888, [47]  = 0x847888, [48]  = 0x160888,
    [49]  = 0x849888, [50]  = 0x130888, [51]  = 0x851888, [52]  = 0x132888,
    [53]  = 0x853888, [54]  = 0x134888, [55]  = 0x855888, [56]  = 0x136888,
    [57]  = 0x857888, [58]  = 0x138888, [59]  = 0x859888, [60]  = 0x140888,
    [61]  = 0x861888, [62]  = 0x142888, [63]  = 0x863888, [64]  = 0x144888,
    [65]  = 0x865888, [66]  = 0x114888, [67]  = 0x867888, [68]  = 0x116888,
    [69]  = 0x869888, [70]  = 0x118888, [71]  = 0x871888, [72]  = 0x120888,
    [73]  = 0x873888, [74]  = 0x122888, [75]  = 0x875888, [76]  = 0x124888,
    [77]  = 0x877888, [78]  = 0x126888, [79]  = 0x879888, [80]  = 0x128888,
    [81]  = 0x881888, [82]  = 0x898888, [83]  = 0x883888, [84]  = 0x100888,
    [85]  = 0x885888, [86]  = 0x102888, [87]  = 0x887888, [88]  = 0x104888,
    [89]  = 0x889888, [90]  = 0x106888, [91]  = 0x891888, [92]  = 0x108888,
    [93]  = 0x893888, [94]  = 0x110888, [95]  = 0x895888, [96]  = 0x112888,
    [97]  = 0x897888, [98]  = 0x882888, [99]  = 0x899888, [100] = 0x884888,
    [101] = 0x101888, [102] = 0x886888, [103] = 0x103888, [104] = 0x888888,
    [105] = 0x105888, [106] = 0x890888, [107] = 0x107888, [108] = 0x892888,
    [109] = 0x109888, [110] = 0x894888, [111] = 0x111888, [112] = 0x896888,
    [113] = 0x113888, [114] = 0x866888, [115] = 0x115888, [116] = 0x868888,
    [117] = 0x117888, [118] = 0x870888, [119] = 0x119888, [120] = 0x872888,
    [121] = 0x121888, [122] = 0x874888, [123] = 0x123888, [124] = 0x876888,
    [125] = 0x125888, [126] = 0x878888, [127] = 0x127888, [128] = 0x880888,
    [129] = 0x129888, [130] = 0x850888, [131] = 0x131888, [132] = 0x852888,
    [133] = 0x133888, [134] = 0x854888, [135] = 0x135888, [136] = 0x856888,
    [137] = 0x137888, [138] = 0x858888, [139] = 0x139888, [140] = 0x860888,
    [141] = 0x141888, [142] = 0x862888, [143] = 0x143888, [144] = 0x864888,
    [145] = 0x145888, [146] = 0x834888, [147] = 0x147888, [148] = 0x836888,
    [149] = 0x149888, [150] = 0x838888, [151] = 0x151888, [152] = 0x840888,
    [153] = 0x153888, [154] = 0x842888, [155] = 0x155888, [156] = 0x844888,
    [157] = 0x157888, [158] = 0x846888, [159] = 0x159888, [160] = 0x848888,
    [161] = 0x161888, [162] = 0x818888, [163] = 0x163888, [164] = 0x820888,
    [165] = 0x165888, [166] = 0x822888, [167] = 0x167888, [168] = 0x824888,
    [169] = 0x169888, [170] = 0x826888, [171] = 0x171888, [172] = 0x828888,
    [173] = 0x173888, [174] = 0x830888, [175] = 0x175888, [176] = 0x832888,
    [177] = 0x177888, [178] = 0x802888, [179] = 0x179888, [180] = 0x804888,
    [181] = 0x181888, [182] = 0x806888, [183] = 0x183888, [184] = 0x808888,
    [185] = 0x185888, [186] = 0x810888, [187] = 0x187888, [188] = 0x812888,
    [189] = 0x189888, [190] = 0x814888, [191] = 0x191888, [192] = 0x816888,
    [193] = 0x193888, [194] = 0x194888, [195] = 0x195888, [196] = 0x196888,
    [197] = 0x197888, [198] = 0x198888, [199] = 0x199888, [200] = 0x200888,
    [201] = 0x202888, -- ★ 2026-08-30：目标跟随（迁移自115；DKT冰霜灵气实际用颜色50，201 此前空闲可复用）
    -- ★ 2026-08-30：通用跟随/上马三件套色块（201-210 段，供 AHK 直接映射）
    [202] = 0x2088C8, -- 焦点上马
    [203] = 0x20C888, -- 设置焦点
    [204] = 0x88C820, -- 焦点跟随
    [205] = 0xC88820, -- 预留
    [206] = 0x8820C8, -- 预留
    [207] = 0x20C8C8, -- 预留
    [208] = 0xC82088, -- 预留
    [209] = 0xC8C820, -- 预留
    [210] = 0x2088F0, -- 预留
    -- ★ 2026-08-30：跟随系统专用「设置焦点」色块（211-240 段）
    --   与战斗循环焦点色块（176=party1 / 121-145=raid1-25）隔离，避免两套逻辑抢同一颜色导致 AHK 误识别。
    --   映射：party1-5 → 211-215；raid1-25 → 216-240。
    [211] = 0x211A1A, [212] = 0x212A2A, [213] = 0x213A3A, [214] = 0x214A4A, [215] = 0x215A5A,
    [216] = 0x221A1A, [217] = 0x222A2A, [218] = 0x223A3A, [219] = 0x224A4A, [220] = 0x225A5A,
    [221] = 0x226A6A, [222] = 0x227A7A, [223] = 0x228A8A, [224] = 0x229A9A, [225] = 0x22AA0A,
    [226] = 0x22BA1A, [227] = 0x22CA2A, [228] = 0x22DA3A, [229] = 0x22EA4A, [230] = 0x22FA5A,
    [231] = 0x221A6A, [232] = 0x222A7A, [233] = 0x223A8A, [234] = 0x224A9A, [235] = 0x225A0A,
    [236] = 0x226A1A, [237] = 0x227A2A, [238] = 0x228A3A, [239] = 0x229A4A, [240] = 0x22AA5A,
}

-- 全局颜色表
local WR_Frame_Color = {}
for i, v in pairs(ColorTable) do
    WR_Frame_Color[i] = v
end

-- 存储所有框架和文本的数组
ColorFrameArrayTopLeft  = {}
ColorTextArrayTopLeft   = {}
ColorFrameArrayTopRight = {}
ColorTextArrayTopRight  = {}

-- ★ 2026-08-21：固定色块位置的「定位锚点」Frame（左上/右上各一）
--   仅用于保持原 ColorFrame 位置，不再可拖动。
local function WR_CreateColorFrameAnchor(side)
    local anchor = CreateFrame("Frame", "WR_ColorFrame_Anchor_" .. side, UIParent)
    anchor:SetSize(42, 42)
    anchor:SetFrameStrata("TOOLTIP")

    -- 恢复上次保存的位置（默认与游戏内一致：左上/右上锚点均为 0.0 坐标）
    local saved = PigSet["SkillIconPos" .. side]
    if saved and type(saved) == "table" and saved.x and saved.y then
        anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", saved.x, saved.y)
    else
        if side == "L" then
            anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        else
            anchor:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
        end
    end
    return anchor
end

WR_ColorFrame_AnchorL = WR_CreateColorFrameAnchor("L")
WR_ColorFrame_AnchorR = WR_CreateColorFrameAnchor("R")

-- ============================================================
-- ★ 按需创建：仅在实际使用某槽位时才创建对应 UI 对象
--   启动时不再全量预建 1206 个 Frame/Texture/FontString，
--   预计节省 10-15MB 运行时内存。
-- ============================================================

local function WR_CreateSingleColorSlot(Name, side)
    -- side: "Left" or "Right"
    local arrayFrame = (side == "Left") and ColorFrameArrayTopLeft or ColorFrameArrayTopRight
    local arrayText  = (side == "Left") and ColorTextArrayTopLeft  or ColorTextArrayTopRight
    local anchor     = (side == "Left") and WR_ColorFrame_AnchorL    or WR_ColorFrame_AnchorR

    arrayFrame[Name] = CreateFrame("Frame", Name .. "_FrameTop" .. side)
    arrayFrame[Name]:SetSize(42, 42)
    arrayFrame[Name]:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
    arrayFrame[Name]:SetFrameStrata("TOOLTIP")

    local texture = arrayFrame[Name]:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(arrayFrame[Name])
    texture:SetColorTexture(PIG_BGRtoBGR(WR_Frame_Color[Name]))

    arrayText[Name] = arrayFrame[Name]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrayText[Name]:SetPoint("BOTTOM", arrayFrame[Name], "BOTTOM")
    arrayText[Name]:SetText(Name)
    arrayText[Name]:SetFont(arrayText[Name]:GetFont(), 9)
    arrayText[Name]:SetShadowOffset(0, 0)
    arrayText[Name]:SetShadowColor(0, 0, 0, 0)
    arrayFrame[Name]:Hide()
end

-- 确保指定槽位的 UI 对象已存在（按需创建入口）
function WR_EnsureColorSlot(Name, side)
    local arrayFrame = (side == "Left") and ColorFrameArrayTopLeft or ColorFrameArrayTopRight
    if not arrayFrame[Name] then
        WR_CreateSingleColorSlot(Name, side)
    end
end

-- ★ 不再在加载时全量调用 WR_Create_ColorFrame
-- WR_Create_ColorFrame(WR_Frame_Color)  -- 已移除，改为按需创建

-- ============================================================
-- ★ 2026-08-21：新增独立的「技能提示图标」框体
--   - 与原来的 ColorFrame 色块完全分离，色块位置保持不变。
--   - 该框体显示当前提示技能的图标，可自由拖动，位置持久化。
-- ============================================================
WR_SkillIconFrame = CreateFrame("Frame", "WR_SkillIconFrame", UIParent)
WR_SkillIconFrame:SetSize(42, 42)
WR_SkillIconFrame:SetFrameStrata("TOOLTIP")
WR_SkillIconFrame:SetMovable(true)
WR_SkillIconFrame:EnableMouse(true)
WR_SkillIconFrame:RegisterForDrag("LeftButton")

-- 恢复/设定默认位置：默认放在左上角色块右侧
local skillIconSaved = PigSet["SkillIconPos"]
if skillIconSaved and type(skillIconSaved) == "table" and skillIconSaved.x and skillIconSaved.y then
    WR_SkillIconFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", skillIconSaved.x, skillIconSaved.y)
else
    WR_SkillIconFrame:SetPoint("TOPLEFT", WR_ColorFrame_AnchorL, "TOPRIGHT", 4, 0)
end

-- ★ 拖拽逻辑（OnDragStart/OnDragStop + OnMouseDown/OnMouseUp 双重兜底，确保一定可拖动）
local function WR_SkillIcon_StartDrag(self)
    self:StartMoving()
end
local function WR_SkillIcon_StopDrag(self)
    self:StopMovingOrSizing()
    local px, py = self:GetLeft(), self:GetTop()
    if px and py then
        local uiLeft, uiTop = UIParent:GetLeft(), UIParent:GetTop()
        PigSet["SkillIconPos"] = { x = px - (uiLeft or 0), y = py - (uiTop or 0) }
    end
end
WR_SkillIconFrame:SetScript("OnDragStart", WR_SkillIcon_StartDrag)
WR_SkillIconFrame:SetScript("OnDragStop", WR_SkillIcon_StopDrag)
WR_SkillIconFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then WR_SkillIcon_StartDrag(self) end
end)
WR_SkillIconFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then WR_SkillIcon_StopDrag(self) end
end)

-- 暗色半透明背景，方便观察图标边界
local iconBg = WR_SkillIconFrame:CreateTexture(nil, "BACKGROUND")
iconBg:SetAllPoints(WR_SkillIconFrame)
iconBg:SetTexture("Interface\\Buttons\\WHITE8x8")
iconBg:SetVertexColor(0, 0, 0, 0.5)

-- 可拖动手柄边框（常驻显示，提示用户此处可拖动）
local iconBorder = WR_SkillIconFrame:CreateTexture(nil, "BORDER")
iconBorder:SetAllPoints(WR_SkillIconFrame)
iconBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
iconBorder:SetVertexColor(1, 1, 1, 0.4)

-- 图标纹理（尺寸与调试模式色块一致：42x42）
WR_SkillIconFrame.Icon = WR_SkillIconFrame:CreateTexture(nil, "ARTWORK")
WR_SkillIconFrame.Icon:SetSize(42, 42)
WR_SkillIconFrame.Icon:SetPoint("TOPLEFT", WR_SkillIconFrame, "TOPLEFT", 0, 0)
WR_SkillIconFrame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
WR_SkillIconFrame.Icon:Hide()

-- ★ 图标下方显示当前提示文字（与色块内的文字字样一致）
WR_SkillIconFrame.Text = WR_SkillIconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
WR_SkillIconFrame.Text:SetPoint("TOP", WR_SkillIconFrame, "BOTTOM", 0, -2)
WR_SkillIconFrame.Text:SetFont(WR_SkillIconFrame.Text:GetFont(), 13)
WR_SkillIconFrame.Text:SetShadowOffset(0, 0)
WR_SkillIconFrame.Text:SetShadowColor(0, 0, 0, 0)
WR_SkillIconFrame.Text:SetTextColor(1, 1, 1, 1)
WR_SkillIconFrame.Text:Hide()
-- ★ 2026-08-21：技能图标默认不勾选 → 创建后默认隐藏，仅当复选开启（SkillIconShow==true）时显示。
--   显隐完全由 WR_ShowColorFrame / 复选框 OnClick 控制，避免默认在屏幕上露出空边框占位。
WR_SkillIconFrame:Hide()