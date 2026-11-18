-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "WARRIOR" then return end
-- ============================================================
-- Warrior_Menu.lua
-- 战士全专精配置菜单（武器 / 狂怒 / 防护）
-- 包含各类自动功能、插入技能、爆发阈值等开关
-- ============================================================

--[[
if WR_PlayerClass ~= "WARRIOR" then return end

    ★ Warrior_Menu 结构说明：
    DM（下拉菜单）：用于选择模式/阈值，保存为数字值
    CB（复选框）：用于开启/关闭功能，保存为布尔值
    每个专精独立配置，互不干扰
--]]

Warrior_Menu = {
    -- ==========================================================
    -- 1. 武器专精 (Arms) —— 2026-11-15 按「彼岸花-无限服 · 武器页」重做
    -- ==========================================================
    ["武器"] = {
        -- ===== 下拉菜单（DM） =====
        DM = {
            -- 防ADD开关
            {
                text = "|cffC79C6E防ADD|r",
                menuItems = { { text = "|cffC79C6E是|r" }, { text = "|cffC79C6E否|r" } },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_WQZ",
                defaultID = 1
            },
            -- 拉条（截图口径）
            { text = "|cffC79C6E顺劈斩|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "多少怒气以上使用顺劈斩（默认30）", saveVariable = "WQZ_SPZ" },
            { text = "|cffC79C6E英勇打击|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 20, tooltipText = "多少怒气以上使用英勇打击（默认20）", saveVariable = "WQZ_YYDJ" },
            { text = "|cffC79C6E斩杀|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 1, defaultVal = 15, tooltipText = "目标血量低于该百分比时使用斩杀（0 = 关闭，默认15）", saveVariable = "WQZ_ZS" },
            { text = "|cffC79C6E乘胜追击|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 10, defaultVal = 70, tooltipText = "自己血量低于该百分比时才使用乘胜追击（击杀后 20 秒内可用，回 10% 最大生命）", saveVariable = "WQZ_CSZJ" },
            { text = "|cffC79C6E喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 10, defaultVal = 30, tooltipText = "血量低于该百分比时自动喝治疗药水（0 = 关闭）", saveVariable = "WQZ_HXY" },
            { text = "|cffC79C6E打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 60, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认60）", saveVariable = "WQZ_QJ" },
            -- 爆发快捷按钮
            { text = "|cffC79C6E爆发全开|r", isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开 鲁莽 / 种族爆发", onClick = "WR_WarriorArmsBurstAllOn" },
            { text = "|cffC79C6E爆发全关|r", isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭 鲁莽 / 种族爆发", onClick = "WR_WarriorArmsBurstAllOff" },
            { text = "|cffC79C6E爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "两个爆发开关任意一个开着就全关，全关就全开", onClick = "WR_WarriorArmsBurstToggle" },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 自动：武器功能（右键图标打开额外条件）
            { row = 1, column = 1, IconID = 132155, text = "|cffC79C6E撕裂|r", tooltipText = "开着时，目标身上没有自己施加的撕裂就自动补一次；撕裂还在时不重复补。\n右键：不打元素 / 不打机械 / 不打亡灵 / 预判秒数", saveVariable = "WQZ_SILIE", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorArmsUI then WR_WarriorArmsUI.ShowOptions("WQZ_SILIE") end end },
            { row = 1, column = 2, IconID = 136105, text = "|cffC79C6E雷霆挫志|r", tooltipText = "雷霆一击 + 挫志怒吼。\n右键：雷霆/挫志各自设置 多目标（保持/卡CD/不放）、怪数、缺数、单体（保持/卡CD/不放）", saveVariable = "WQZ_LTYJ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorArmsUI then WR_WarriorArmsUI.ShowOptions("WQZ_LTYJ") end end },
            { row = 1, column = 3, IconID = 136009, text = "|cffC79C6E血性狂暴|r", tooltipText = "开着时自动放血性狂暴（掉血换怒气）。\n右键：怒气低于多少 / 血量高于多少才放", saveVariable = "WQZ_HXKJ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorArmsUI then WR_WarriorArmsUI.ShowOptions("WQZ_HXKJ") end end },
            { row = 1, column = 4, IconID = 132363, text = "|cffC79C6E破甲攻击|r", tooltipText = "开着时按额外条件放破甲攻击（降低护甲、拉仇恨）。\n右键：只打1破 / 高优先级 / 低优先级 / 续破秒数", saveVariable = "WQZ_BDPJ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorArmsUI then WR_WarriorArmsUI.ShowOptions("WQZ_BDPJ") end end },

            { row = 2, column = 1, IconID = 132355, text = "|cffC79C6E致死打击|r", tooltipText = "开着时给致死打击留怒气：致死打击冷却快好时，英勇/顺劈要怒气够才排。\n右键：让怒秒数 / 让怒怒气", saveVariable = "WQZ_MS_POOL", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorArmsUI then WR_WarriorArmsUI.ShowOptions("WQZ_MS_POOL") end end },
            { row = 2, column = 2, IconID = 132306, text = "|cffC79C6E横扫攻击|r", tooltipText = "开着时，多目标自动放横扫攻击。\n右键：怪数 / 怒气（强制留怒或随缘）", saveVariable = "WQZ_HSGJ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorArmsUI then WR_WarriorArmsUI.ShowOptions("WQZ_HSGJ") end end },
            { row = 2, column = 3, IconID = 132338, text = "|cffC79C6E旋风斩|r", tooltipText = "开着时，多目标自动切狂暴姿态放旋风斩，放完切回战斗姿态。\n右键：怪数 / 怒气上限", saveVariable = "WQZ_XLZ_AUTO", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorArmsUI then WR_WarriorArmsUI.ShowOptions("WQZ_XLZ_AUTO") end end },
            { row = 2, column = 4, IconID = 132333, text = "|cffC79C6E战斗怒吼|r", tooltipText = "没有战斗怒吼时自动补。", saveVariable = "WQZ_ZDZH", section = "自动", defaultState = true },

            { row = 3, column = 1, IconID = 132293, text = "|cffC79C6E切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标", saveVariable = "WQZ_TAB", section = "自动", defaultState = true },
            { row = 3, column = 2, IconID = 132340, text = "|cffC79C6E猛击|r", tooltipText = "猛击 15 秒冷却，转好就打。", saveVariable = "WQZ_MJ", section = "自动", defaultState = true },

            -- 爆发（默认和截图一致：鲁莽/种族爆发都开）
            { row = 1, column = 1, IconID = 132109, text = "|cffC79C6E鲁莽|r", tooltipText = "自动使用鲁莽（爆发 CD 好了就开）", saveVariable = "WQZ_LM", section = "爆发", defaultState = true },
            { row = 1, column = 2, IconID = 135727, text = "|cffC79C6E种族爆发|r", tooltipText = "自动使用种族爆发技能", saveVariable = "WQZ_ZDZZ", section = "爆发", defaultState = true },

            -- 插入（一次性，放完自关）
            { row = 1, column = 1, IconID = 132336, text = "|cffC79C6E反击|r", tooltipText = "插入 反击风暴（一次性，施放后自关）", saveVariable = "WQZ_CRFJFB", section = "插入", defaultState = false },
            { row = 1, column = 2, IconID = 135124, text = "|cffC79C6E穿刺|r", tooltipText = "插入 穿刺打击（一次性，施放后自关）", saveVariable = "WQZ_CCDJ_CR", section = "插入", defaultState = false },
            { row = 1, column = 3, IconID = 132306, text = "|cffC79C6E横扫|r", tooltipText = "插入 横扫攻击（一次性，施放后自关）", saveVariable = "WQZ_CRHS", section = "插入", defaultState = false },
            { row = 1, column = 4, IconID = 132275, text = "|cffC79C6E狂暴之怒|r", tooltipText = "插入 狂暴之怒（一次性，施放后自关）", saveVariable = "WQZ_KBZN_CR", section = "插入", defaultState = false },
        },
    },

    -- ==========================================================
    -- 2. 狂怒专精 (Fury) —— 2026-11-16 按「猪猪 / 彼岸花-无限服 · 狂暴页」重做
    -- ==========================================================
    ["狂怒"] = {
        -- ===== 下拉菜单（DM） =====
        DM = {
            -- 防ADD开关
            {
                text = "|cffC79C6E防ADD|r",
                menuItems = { { text = "|cffC79C6E是|r" }, { text = "|cffC79C6E否|r" } },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_KBZ",
                defaultID = 1
            },
            -- 拉条
            { text = "|cffC79C6E顺劈斩|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "多少怒气以上使用顺劈斩（默认30）", saveVariable = "KN_SPZ" },
            { text = "|cffC79C6E英勇打击|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 20, tooltipText = "多少怒气以上使用英勇打击（默认20）", saveVariable = "KN_YYDJ" },
            { text = "|cffC79C6E斩杀|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 1, defaultVal = 15, tooltipText = "目标血量低于该百分比时使用斩杀（0 = 关闭，默认15）", saveVariable = "KN_ZS" },
            { text = "|cffC79C6E乘胜追击|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 10, defaultVal = 70, tooltipText = "自己血量低于该百分比时才使用乘胜追击（击杀后 20 秒内可用，回 10% 最大生命）", saveVariable = "KN_CSZJ" },
            { text = "|cffC79C6E喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 10, defaultVal = 30, tooltipText = "血量低于该百分比时自动喝治疗药水（0 = 关闭）", saveVariable = "KN_HXY" },
            { text = "|cffC79C6E打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 60, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认60）", saveVariable = "KN_QJ" },
            -- 爆发快捷按钮
            { text = "|cffC79C6E爆发全开|r", isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开 鲁莽 / 死亡之愿 / 种族爆发", onClick = "WR_WarriorFuryBurstAllOn" },
            { text = "|cffC79C6E爆发全关|r", isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭 鲁莽 / 死亡之愿 / 种族爆发", onClick = "WR_WarriorFuryBurstAllOff" },
            { text = "|cffC79C6E爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "三个爆发开关任意一个开着就全关，全关就全开", onClick = "WR_WarriorFuryBurstToggle" },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 自动：狂怒功能（右键图标打开额外条件）
            { row = 1, column = 1, IconID = 132155, text = "|cffC79C6E撕裂|r", tooltipText = "开着时，目标身上没有自己施加的撕裂就自动补一次；撕裂还在时不重复补。\n右键：不打元素 / 不打机械 / 不打亡灵 / 预判秒数", saveVariable = "KN_SILIE", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorFuryUI then WR_WarriorFuryUI.ShowOptions("KN_SILIE") end end },
            { row = 1, column = 2, IconID = 136105, text = "|cffC79C6E雷霆挫志|r", tooltipText = "雷霆一击 + 挫志怒吼。\n右键：雷霆（多目标 保持/卡CD/不放、单体 保持/卡CD/不放）；挫志（多目标/单体 保持/不放）", saveVariable = "KN_LTYJ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorFuryUI then WR_WarriorFuryUI.ShowOptions("KN_LTYJ") end end },
            { row = 1, column = 3, IconID = 136009, text = "|cffC79C6E血性狂暴|r", tooltipText = "开着时自动放血性狂暴（掉血换怒气）。\n右键：怒气低于多少 / 血量高于多少才放", saveVariable = "KN_HXKJ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorFuryUI then WR_WarriorFuryUI.ShowOptions("KN_HXKJ") end end },
            { row = 1, column = 4, IconID = 132363, text = "|cffC79C6E破甲攻击|r", tooltipText = "开着时按额外条件放破甲攻击（降低护甲、拉仇恨）。\n右键：只打1破 / 高优先级 / 低优先级 / 续破秒数", saveVariable = "KN_BDPJ", section = "自动", defaultState = false,
                onRightClick = function() if WR_WarriorFuryUI then WR_WarriorFuryUI.ShowOptions("KN_BDPJ") end end },

            { row = 2, column = 1, IconID = 132090, text = "|cffC79C6E切姿态|r", tooltipText = "开着时自动切姿态。\n右键：脱战切战斗 / 进战切狂暴（插入反击、反击风暴快好时先不切）", saveVariable = "KN_QTZ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorFuryUI then WR_WarriorFuryUI.ShowOptions("KN_QTZ") end end },
            { row = 2, column = 2, IconID = 132333, text = "|cffC79C6E战斗怒吼|r", tooltipText = "没有战斗怒吼时自动补。", saveVariable = "KN_ZDZH", section = "自动", defaultState = true },
            { row = 2, column = 3, IconID = 132293, text = "|cffC79C6E切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标", saveVariable = "KN_TAB", section = "自动", defaultState = true },
            { row = 2, column = 4, IconID = 132342, text = "|cffC79C6E鲁莽挥击|r", tooltipText = "狂怒天赋新技能：接下来 4 次近战攻击每次额外产生 5 点怒气，持续 8 秒。\n右键：怒气低于多少才用", saveVariable = "KN_LMHJ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorFuryUI then WR_WarriorFuryUI.ShowOptions("KN_LMHJ") end end },

            -- 爆发（截图口径：鲁莽/死愿/种族爆发）
            { row = 1, column = 1, IconID = 132109, text = "|cffC79C6E鲁莽|r", tooltipText = "自动使用鲁莽（狂暴姿态，爆发 CD 好了就开）", saveVariable = "KN_LM", section = "爆发", defaultState = true },
            { row = 1, column = 2, IconID = 136146, text = "|cffC79C6E死愿|r", tooltipText = "自动使用死亡之愿（+20% 物理伤害，30 秒）", saveVariable = "KN_SWZY", section = "爆发", defaultState = true },
            { row = 1, column = 3, IconID = 135727, text = "|cffC79C6E种族爆发|r", tooltipText = "自动使用种族爆发技能", saveVariable = "KN_ZDZZ", section = "爆发", defaultState = true },

            -- 插入（一次性，放完自关）
            { row = 1, column = 1, IconID = 132336, text = "|cffC79C6E反击|r", tooltipText = "插入 反击风暴（一次性，施放后自关）", saveVariable = "KN_FJFB_CR", section = "插入", defaultState = false },
            { row = 1, column = 2, IconID = 132109, text = "|cffC79C6E鲁莽|r", tooltipText = "插入 鲁莽（一次性，施放后自关）", saveVariable = "KN_LM_CR", section = "插入", defaultState = false },
            { row = 1, column = 3, IconID = 132275, text = "|cffC79C6E狂暴之怒|r", tooltipText = "插入 狂暴之怒（一次性，施放后自关）", saveVariable = "KN_KBZN_CR", section = "插入", defaultState = false },
        },
    },

    -- ==========================================================
    -- 3. 防护专精 (Protection) —— 2026-11-16 按「猪猪 / 彼岸花-无限服 · 防战页」同步
    -- ==========================================================
    ["防护"] = {
        -- ===== 下拉菜单（DM） =====
        DM = {
            -- 防ADD开关
            {
                text = "|cffC79C6E防ADD|r",
                menuItems = { { text = "|cffC79C6E是|r" }, { text = "|cffC79C6E否|r" } },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_FZ",
                defaultID = 1
            },
            -- 破釜沉舟阈值
            {
                text = "|cffC79C6E破釜沉舟|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 10,
                defaultVal = 20,
                tooltipText = "血量低于该百分比时使用|cff00adf0破釜沉舟|r\n",
                saveVariable = "FZ_KG_PFCZ"
            },
            -- 顺劈斩阈值
            {
                text = "|cffC79C6E顺劈斩|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 10,
                defaultVal = 30,
                tooltipText = "多少怒气以上使用顺劈斩",
                saveVariable = "FZ_SPZ"
            },
            -- 英勇打击阈值
            {
                text = "|cffC79C6E英勇打击|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 10,
                defaultVal = 20,
                tooltipText = "多少怒气以上使用英勇打击",
                saveVariable = "FZ_YYDJ"
            },
            -- 乘胜追击阈值
            {
                text = "|cffC79C6E乘胜追击|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 10,
                defaultVal = 70,
                tooltipText = "自己血量低于该百分比时才使用|cff00adf0乘胜追击|r（击杀后 20 秒内可用，回 10% 最大生命）",
                saveVariable = "FZ_CSZJ"
            },
            -- 喝红药阈值
            {
                text = "|cffC79C6E喝红药|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 10,
                defaultVal = 30,
                tooltipText = "血量低于该百分比时自动喝治疗药水（0 = 关闭）",
                saveVariable = "FZ_HXY"
            },
            { text = "|cffC79C6E打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 60, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认60）", saveVariable = "FZ_KG_QJ" },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 自动：防护功能（右键图标打开额外条件）
            { row = 1, column = 1, IconID = 132155, text = "|cffC79C6E撕裂|r", tooltipText = "开着时，目标身上没有自己施加的撕裂就自动补一次；撕裂还在时不重复补。\n右键：不打元素 / 不打机械 / 不打亡灵 / 预判秒数", saveVariable = "FZ_SILIE", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorProt then WR_WarriorProt.ShowOptions("FZ_SILIE") end end },
            { row = 1, column = 2, IconID = 136105, text = "|cffC79C6E雷霆挫志|r", tooltipText = "雷霆一击 + 挫志怒吼。\n右键：雷霆/挫志各自设置 多目标（保持/卡CD/不放）、怪物数、缺数、单体（保持/卡CD/不放）", saveVariable = "FZ_LTYJ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorProt then WR_WarriorProt.ShowOptions("FZ_LTYJ") end end },
            { row = 1, column = 3, IconID = 132110, text = "|cffC79C6E格挡|r", tooltipText = "开着时按额外条件放盾牌格挡。\n右键：多目标（8码内敌人数量）/ 卡CD / 血量，满足任意一条就放", saveVariable = "FZ_DPGD", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorProt then WR_WarriorProt.ShowOptions("FZ_DPGD") end end },
            { row = 1, column = 4, IconID = 136009, text = "|cffC79C6E血性狂暴|r", tooltipText = "开着时自动放血性狂暴（掉血换怒气）。\n右键：怒气低于多少 / 血量高于多少才放", saveVariable = "FZ_HXKJ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorProt then WR_WarriorProt.ShowOptions("FZ_HXKJ") end end },
            { row = 1, column = 5, IconID = 132363, text = "|cffC79C6E破甲攻击|r", tooltipText = "开着时按额外条件放破甲攻击（降低护甲、拉仇恨）。\n右键：只打1破 / 高优先级 / 低优先级 / 续破秒数", saveVariable = "FZ_BDPJ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorProt then WR_WarriorProt.ShowOptions("FZ_BDPJ") end end },

            { row = 2, column = 1, IconID = 132090, text = "|cffC79C6E切姿态|r", tooltipText = "开着时自动切姿态。\n右键：脱战切战斗 / 进战切防御（插入反击、拦截、惩戒痛击快好时先不切）", saveVariable = "FZ_QTZ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorProt then WR_WarriorProt.ShowOptions("FZ_QTZ") end end },
            { row = 2, column = 2, IconID = 132333, text = "|cffC79C6E战斗怒吼|r", tooltipText = "没有战斗怒吼时自动补。", saveVariable = "FZ_ZDZH", section = "自动", defaultState = true },
            { row = 2, column = 3, IconID = 132293, text = "|cffC79C6E切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标（坦克快速建立仇恨）", saveVariable = "FZ_TAB", section = "自动", defaultState = false },
            { row = 2, column = 4, IconID = 132366, text = "|cffC79C6E嘲讽|r", tooltipText = "目标仇恨不在自己身上时自动嘲讽（默认关，避免抢其他坦克仇恨）", saveVariable = "FZ_CT", section = "自动", defaultState = false },
            { row = 2, column = 5, IconID = 132342, text = "|cffC79C6E鲁莽挥击|r", tooltipText = "防护天赋新技能：接下来 4 次近战攻击每次额外产生 5 点怒气，持续 8 秒。\n右键：怒气低于多少才用", saveVariable = "FZ_LMHJ", section = "自动", defaultState = true,
                onRightClick = function() if WR_WarriorProt then WR_WarriorProt.ShowOptions("FZ_LMHJ") end end },

            -- 爆发（截图口径：全开 / 全关 / 切换 + 种族爆发）
            { text = "|cffC79C6E爆发全开|r", isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开 种族爆发", onClick = "WR_WarriorProtBurstAllOn" },
            { text = "|cffC79C6E爆发全关|r", isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭 种族爆发", onClick = "WR_WarriorProtBurstAllOff" },
            { text = "|cffC79C6E爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "种族爆发开着就全关，关着就全开", onClick = "WR_WarriorProtBurstToggle" },
            { row = 1, column = 1, IconID = 135727, text = "|cffC79C6E种族爆发|r", tooltipText = "自动使用种族爆发技能（宏 181）", saveVariable = "FZ_KG_ZDZZ", section = "爆发", defaultState = true },

            -- 插入（一次性，放完自关）
            { row = 1, column = 1, IconID = 132336, text = "|cffC79C6E反击|r", tooltipText = "插入 反击风暴（一次性，施放后自关）", saveVariable = "FZ_FJFB_CR", section = "插入", defaultState = false },
            { row = 1, column = 2, IconID = 132325, text = "|cffC79C6E震荡|r", tooltipText = "插入 震荡猛击（一次性，施放后自关）", saveVariable = "FZ_ZCMJ_CR", section = "插入", defaultState = false },
            { row = 1, column = 3, IconID = 132091, text = "|cffC79C6E挑战|r", tooltipText = "插入 挑战怒吼（一次性，施放后自关）", saveVariable = "FZ_TZNH_CR", section = "插入", defaultState = false },
            { row = 1, column = 4, IconID = 132331, text = "|cffC79C6E盾墙|r", tooltipText = "插入 盾墙（一次性，施放后自关）", saveVariable = "FZ_DQ_CR", section = "插入", defaultState = false },
            { row = 2, column = 1, IconID = 132366, text = "|cffC79C6E挫志|r", tooltipText = "插入 挫志怒吼（一次性，施放后自关）", saveVariable = "FZ_CZNH_CR", section = "插入", defaultState = false },
            { row = 2, column = 2, IconID = 132183, text = "|cffC79C6E拦截|r", tooltipText = "插入 拦截（8~25码，一次性；自动切战斗姿态，放完自关）", saveVariable = "FZ_JL_CR", section = "插入", defaultState = false },
            { row = 2, column = 3, IconID = 132350, text = "|cffC79C6E惩戒痛击|r", tooltipText = "插入 惩戒痛击（一次性，施放后自关）", saveVariable = "FZ_CJTJ_CR", section = "插入", defaultState = false },
            { row = 2, column = 4, IconID = 132275, text = "|cffC79C6E狂暴之怒|r", tooltipText = "插入 狂暴之怒（一次性，施放后自关）", saveVariable = "FZ_KBZN_CR", section = "插入", defaultState = false },
        },
    },
}

-- 注册菜单
if WR_RegisterMenu then
    WR_RegisterMenu("WARRIOR", Warrior_Menu)
end