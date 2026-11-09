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
    -- 1. 武器专精 (Arms)
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
            -- 怒吼选择
            {
                text = "|cffC79C6E怒吼|r",
                menuItems = { { text = "|cffC79C6E命令|r" }, { text = "|cffC79C6E战斗|r" }, { text = "|cffC79C6E禁用|r" } },
                tooltipText = "使用(|cff00adf0怒吼|r技能\n)",
                saveVariable = "WQZ_NH",
                defaultID = 1
            },
            -- 寒霜刺骨
            {
                text = "|cffC79C6E寒霜刺骨|r",
                menuItems = {
                    { text = "|cffC79C6E5|r" }, { text = "|cffC79C6E6|r" }, { text = "|cffC79C6E7|r" },
                    { text = "|cffC79C6E8|r" }, { text = "|cffC79C6E9|r" }, { text = "|cffC79C6E10|r" },
                    { text = "|cffC79C6E禁用|r" }
                },
                tooltipText = "|cff00adf0寒霜刺骨|r层数大于等于设定值，自动停手(|cff00adf0冰龙|r技能)\n",
                saveVariable = "WQZ_HSCG",
                section = "自动",
                defaultID = 7
            },
            -- 破甲模式
            {
                text = "|cffC79C6E破甲|r",
                menuItems = { { text = "|cffC79C6E打破甲|r" }, { text = "|cffC79C6E禁用|r" } },
                tooltipText = "|cff00adf0破甲攻击|r优先级\n",
                saveVariable = "WQZ_PJGJ",
                defaultID = 2
            },
            -- 英勇打击阈值
            {
                text = "|cffC79C6E英勇打击|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 1,
                defaultVal = 80,
                tooltipText = "多少怒气以上使用英勇打击,越高越好.在怒气不溢出的情况下",
                saveVariable = "WQZ_YYDJ"
            },
            -- 顺劈斩阈值
            {
                text = "|cffC79C6E顺劈斩|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 1,
                defaultVal = 20,
                tooltipText = "多少怒气以上使用顺劈斩,越高越好.在怒气不溢出的情况下",
                saveVariable = "WQZ_SPZ"
            },
            { text = "|cffC79C6E打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "WQZ_QJ" },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 236871, text = "|cffC79C6E自动|r", tooltipText = "使用|cff00adf0速度药水|r\n", saveVariable = "WQZ_ZDSDYS", section = "爆发", defaultState = false },
            -- ★ 第1行第2列：偷药开关
            { row = 1, column = 2, IconID = 236871, text = "|cffC79C6E偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "WQZ_TOUYAO", section = "爆发", defaultState = false },
            -- ★ 第1行第3列：不灭药水开关
            { row = 1, column = 3, IconID = 236871, text = "|cffC79C6E不灭|r", tooltipText = "开启后，爆发期间自动使用不灭药水（与速度药水共用逻辑，先喝速度后喝不灭）", saveVariable = "WQZ_BMYSH", section = "爆发", defaultState = false },
            { row = 1, column = 4, IconID = 135727, text = "|cffC79C6E自动|r", tooltipText = "自动使用|cff00adf0种族|r\n", saveVariable = "WQZ_ZDZZ", section = "爆发", defaultState = true },
            { row = 1, column = 5, IconID = 338666, text = "|cffC79C6E自动|r", tooltipText = "自动使用入|cff00adf0饰品|r", saveVariable = "WQZ_ZDSP", section = "爆发", defaultState = false },

            -- 第2行
            { row = 2, column = 1, IconID = 132962, text = "|cffC79C6E自动|r", tooltipText = "自动使用|cff00adf0手套|r\n", saveVariable = "WQZ_ZDST", section = "爆发", defaultState = true },
            { row = 2, column = 2, IconID = 236303, text = "|cffC79C6E自动|r", tooltipText = "在打完致死低怒期,自动大风车", saveVariable = "WQZ_DFC", defaultState = true },            { row = 2, column = 4, IconID = 132338, text = "|cffC79C6E智能|r", tooltipText = "智能使用|cff00adf0顺劈|r\n", saveVariable = "WQZ_ZNSP", defaultState = true },
            { row = 2, column = 5, IconID = 132338, text = "|cffC79C6E屏蔽|r", tooltipText = "ICC老2屏蔽|cff00adf0旋风斩|r和|cff00adf0顺劈|r\n", saveVariable = "WQZ_WJPB", defaultState = false },

            -- 第3行
            { row = 3, column = 1, IconID = 132338, text = "|cffC79C6E强制|r", tooltipText = "强制使用|cff00adf0顺劈|r\n", saveVariable = "WQZ_QZSP", defaultState = false },
            { row = 3, column = 2, IconID = 136047, text = "|cffC79C6E锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "WQZ_SUO", defaultState = true },
            { row = 3, column = 3, IconID = 132306, text = "|cffC79C6E自动|r", tooltipText = "自动多目标横扫\n", saveVariable = "WQZ_HSGJ", defaultState = true },
            { row = 3, column = 4, IconID = 132316, text = "|cffC79C6E自动|r", tooltipText = "使用断筋", saveVariable = "ZS_WQ_DJ", defaultState = false },
            { row = 3, column = 5, IconID = 136105, text = "|cffC79C6E自动|r", tooltipText = "3目标自动雷霆", saveVariable = "ZS_WQ_LTYJ", defaultState = true },

            -- 第4行
            { row = 4, column = 1, IconID = 311430, text = "|cffC79C6E自动|r", tooltipText = "使用|cff00adf0碎裂投掷|r\n", saveVariable = "WQZ_SLTZ", defaultState = false },
            { row = 4, column = 2, IconID = 135358, text = "|cffC79C6E自动|r", tooltipText = "是否使用|cff00adf0斩杀|r\n", saveVariable = "WQZ_ZHANSHA", defaultState = false },
            { row = 4, column = 3, IconID = 133712, text = "|cffC79C6E自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r\n", saveVariable = "WQZ_ZDZD", defaultState = false },
            { row = 4, column = 4, IconID = 236303, text = "|cffC79C6E插入|r", tooltipText = "使用|cff00adf0利刃风暴|r\n", saveVariable = "WQZ_LRFB_CR", section = "插入", defaultState = false },
            { row = 4, column = 5, IconID = 311430, text = "|cffC79C6E插入|r", tooltipText = "使用|cff00adf0碎裂投掷|r\n", saveVariable = "WQZ_CRSLTZ", section = "插入", defaultState = false },

            -- 第5行
            { row = 5, column = 1, IconID = 132336, text = "|cffC79C6E插入|r", tooltipText = "使用|cff00adf0反击风暴|r\n", saveVariable = "WQZ_CRFJFB", section = "插入", defaultState = false },
            -- ★ 2026-08-25 #13：武器战插入缴械（与自动缴械双模式，语义对齐防战）
            { row = 5, column = 3, IconID = 132320, text = "|cffC79C6E插入|r", tooltipText = "插入 缴械（一次性，仅人型/野兽，施放后自关）", saveVariable = "WQZ_JF_CR", section = "插入", defaultState = false },
            { row = 5, column = 2, IconID = 132109, text = "|cffC79C6E插入|r", tooltipText = "使用|cff00adf0鲁莽|r\n", saveVariable = "WQZ_CRLM", section = "爆发", defaultState = false },
            -- ★ 自动切目标开关
            { row = 6, column = 1, IconID = 132293, text = "|cffC79C6E切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "WQZ_TAB", defaultState = false },
            { row = 6, column = 2, IconID = 132320, text = "|cffC79C6E自动|r", tooltipText = "自动缴械（仅人型/野兽，爆发或斩杀期释放）", saveVariable = "WQZ_JF", defaultState = false },
        },
    },

    -- ==========================================================
    -- 2. 狂怒专精 (Fury)
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
            -- 怒吼选择
            {
                text = "|cffC79C6E怒吼|r",
                menuItems = { { text = "|cffC79C6E命令|r" }, { text = "|cffC79C6E战斗|r" }, { text = "|cffC79C6E禁用|r" } },
                tooltipText = "使用(|cff00adf0怒吼|r技能\n)",
                saveVariable = "KN_NH",
                defaultID = 1
            },
            -- 寒霜刺骨
            {
                text = "|cffC79C6E寒霜刺骨|r",
                menuItems = {
                    { text = "|cffC79C6E5|r" }, { text = "|cffC79C6E6|r" }, { text = "|cffC79C6E7|r" },
                    { text = "|cffC79C6E8|r" }, { text = "|cffC79C6E9|r" }, { text = "|cffC79C6E10|r" },
                    { text = "|cffC79C6E禁用|r" }
                },
                tooltipText = "|cff00adf0寒霜刺骨|r层数大于等于设定值，自动停手(|cff00adf0冰龙|r技能)\n",
                saveVariable = "KN_HSCG",
                section = "自动",
                defaultID = 7
            },
            -- 破甲模式
            {
                text = "|cffC79C6E破甲|r",
                menuItems = { { text = "|cffC79C6E优先|r" }, { text = "|cffC79C6E填充|r" }, { text = "|cffC79C6E禁用|r" } },
                tooltipText = "|cff00adf0破甲攻击|r优先级\n",
                saveVariable = "KN_PJGJ",
                defaultID = 3
            },
            -- 猛击模式
            {
                text = "|cffC79C6E猛击|r",
                menuItems = { { text = "|cffC79C6E优先|r" }, { text = "|cffC79C6E填充|r" } },
                tooltipText = "|cff00adf0猛击|r优先级\n,推荐填充,优先纯赌脸可能反向提升",
                saveVariable = "KN_MJ",
                defaultID = 2
            },
            { text = "|cffC79C6E打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "KN_QJ" },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 236871, text = "|cffC79C6E自动|r", tooltipText = "使用|cff00adf0速度药水|r\n", saveVariable = "KN_ZDSDYS", section = "爆发", defaultState = false },
            -- ★ 第1行第2列：偷药开关
            { row = 1, column = 2, IconID = 236871, text = "|cffC79C6E偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "KN_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 3, IconID = 135727, text = "|cffC79C6E自动|r", tooltipText = "自动使用|cff00adf0种族|r\n", saveVariable = "KN_ZDZZ", section = "爆发", defaultState = true },
            { row = 1, column = 4, IconID = 338666, text = "|cffC79C6E自动|r", tooltipText = "自动使用入|cff00adf0饰品|r", saveVariable = "KN_ZDSP", section = "爆发", defaultState = true },
            { row = 1, column = 5, IconID = 132962, text = "|cffC79C6E自动|r", tooltipText = "自动使用|cff00adf0手套|r\n", saveVariable = "KN_ZDST", section = "爆发", defaultState = true },

            -- 第2行
            { row = 2, column = 1, IconID = 136146, text = "|cffC79C6E自动|r", tooltipText = "使用|cff00adf0死亡之愿|r\n", saveVariable = "KN_SWZY", section = "爆发", defaultState = false },            { row = 2, column = 3, IconID = 132109, text = "|cffC79C6E自动|r", tooltipText = "使用|cff00adf0鲁莽|r\n", saveVariable = "KN_LM", section = "爆发", defaultState = false },
            { row = 2, column = 4, IconID = 132369, text = "|cffC79C6E自动|r", tooltipText = "是否使用|cff00adf0旋风斩|r\n", saveVariable = "KN_XFZ", defaultState = true },
            { row = 2, column = 5, IconID = 132338, text = "|cffC79C6E智能|r", tooltipText = "智能使用|cff00adf0顺劈|r\n", saveVariable = "KN_ZNSP", defaultState = true },

            -- 第3行
            { row = 3, column = 1, IconID = 132369, text = "|cffC79C6E屏蔽|r", tooltipText = "老2屏蔽|cff00adf0旋风斩|r和|cff00adf0顺劈|r\n", saveVariable = "KN_WJPB", defaultState = false },
            { row = 3, column = 2, IconID = 132338, text = "|cffC79C6E强制|r", tooltipText = "强制使用|cff00adf0顺劈|r\n", saveVariable = "KN_QZSP", defaultState = false },
            { row = 3, column = 3, IconID = 136047, text = "|cffC79C6E锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "KN_SUO", defaultState = true },
            { row = 3, column = 4, IconID = 132316, text = "|cffC79C6E自动|r", tooltipText = "对玩家使用断筋", saveVariable = "ZS_KN_DJ", defaultState = false },
            { row = 3, column = 5, IconID = 311430, text = "|cffC79C6E自动|r", tooltipText = "使用|cff00adf0碎裂投掷|r\n", saveVariable = "ZS_KN_SLTZ", defaultState = false },

            -- 第4行
            { row = 4, column = 1, IconID = 132363, text = "|cffC79C6E焦点|r", tooltipText = "焦点破甲,多用于双子,无损只用怒气不占用GCD的情况下给副目标打破甲", saveVariable = "ZS_KN_JDPJ", defaultState = false },
            { row = 4, column = 2, IconID = 133712, text = "|cffC79C6E自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r\n", saveVariable = "KN_ZDZD", defaultState = false },
            -- ★ 第4行第3列：无脑英勇开关
            { row = 4, column = 3, IconID = 132282, text = "|cffC79C6E无脑|r", tooltipText = "开启无脑英勇模式（毕业装适用，不丢平A）。\n装备好的冲锋直接打，不会因英勇顺劈导致丢平A。\nTOC毕业装一般已经不太缺怒气。",
                saveVariable = "KN_YYDJ_WN", defaultState = false },
            -- ★ 第4行第4列：狂风填充说明（功能已集成，无需额外开关）
            { row = 4, column = 4, IconID = 132282, text = "|cffC79C6E狂风|r", tooltipText = "非斩杀期自动使用狂风作为最低级填充技能\n（功能已集成，无需手动开关）",
                saveVariable = "KN_FENGNU", defaultState = true },

            -- 第5行（插入类技能）
            { row = 5, column = 1, IconID = 136146, text = "|cffC79C6E插入|r", tooltipText = "使用|cff00adf0死亡之愿|r\n", saveVariable = "KN_CRSWZY", section = "爆发", defaultState = false },
            { row = 5, column = 2, IconID = 311430, text = "|cffC79C6E插入|r", tooltipText = "使用|cff00adf0碎裂投掷|r\n", saveVariable = "KN_CRSLTZ", section = "插入", defaultState = false },
            { row = 5, column = 3, IconID = 132336, text = "|cffC79C6E插入|r", tooltipText = "使用|cff00adf0反击风暴|r\n", saveVariable = "KN_CRFJFB", section = "插入", defaultState = false },
            { row = 5, column = 4, IconID = 132109, text = "|cffC79C6E插入|r", tooltipText = "使用|cff00adf0鲁莽|r\n", saveVariable = "KN_CRLM", section = "爆发", defaultState = false },
            { row = 5, column = 5, IconID = 136147, text = "|cffC79C6E插入|r", tooltipText = "使用|cff00adf0刺耳怒吼|r\n", saveVariable = "KN_CRCENH", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 6, column = 1, IconID = 132293, text = "|cffC79C6E切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "KN_TAB", defaultState = false },
        },
    },

    -- ==========================================================
    -- 3. 防护专精 (Protection)
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
            -- 怒吼选择
            {
                text = "|cffC79C6E怒吼|r",
                menuItems = { { text = "|cffC79C6E命令|r" }, { text = "|cffC79C6E战斗|r" }, { text = "|cffC79C6E禁用|r" } },
                tooltipText = "使用(|cff00adf0怒吼|r技能)",
                saveVariable = "FZ_KG_NH",
                defaultID = 1
            },
            -- 破釜沉舟阈值
            {
                text = "|cffC79C6E破釜沉舟|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 10,
                defaultVal = 30,
                tooltipText = "使用(|cff00adf0破釜沉舟|r技能)\n",
                saveVariable = "FZ_KG_PFCZ"
            },
            -- 狂怒回复阈值
            {
                text = "|cffC79C6E狂怒回复|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 10,
                defaultVal = 50,
                tooltipText = "多少血量以下使用",
                saveVariable = "FZ_KNHF"
            },
            -- 自动盾墙阈值
            {
                text = "|cffC79C6E自动盾墙|r",
                menuItems = {
                    { text = "|cffC79C6E10%|r" }, { text = "|cffC79C6E20%|r" },
                    { text = "|cffC79C6E30%|r" }, { text = "|cffC79C6E40%|r" },
                    { text = "|cffC79C6E50%|r" }, { text = "|cffC79C6E60%|r" },
                    { text = "|cffC79C6E70%|r" }, { text = "|cffC79C6E80%|r" },
                    { text = "|cffC79C6E90%|r" }, { text = "|cffC79C6E禁用|r" }
                },
                tooltipText = "自动盾墙血量阈值",
                saveVariable = "FZ_KG_SHIELDWALL",
                defaultID = 3
            },
            -- 英勇打击阈值
            {
                text = "|cffC79C6E英勇打击|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 10,
                defaultVal = 50,
                tooltipText = "多少怒气以上使用英勇打击",
                saveVariable = "FZ_YYDJ"
            },
            -- 顺劈斩阈值
            {
                text = "|cffC79C6E顺劈斩|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 10,
                defaultVal = 50,
                tooltipText = "多少怒气以上使用顺劈斩",
                saveVariable = "FZ_SPZ"
            },
            -- 输出循环模式
            {
                text = "|cffC79C6E输出循环|r",
                menuItems = {
                    { text = "|cffC79C6E常规循环|r" },
                    { text = "|cffC79C6E复仇循环|r" }
                },
                tooltipText = "选择输出循环模式\n|cffff0000常规循环|r：标准仇恨+伤害，适合大多数场合\n|cffff0000复仇循环|r：优先复仇，适合多目标或高仇恨需求",
                saveVariable = "FZ_OUTPUT_MODE",
                defaultID = 1
            },
            { text = "|cffC79C6E打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "FZ_KG_QJ" },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 236871, text = "|cffC79C6E自动|r", tooltipText = "使用|cff00adf0速度药水|r\n", saveVariable = "FZ_KG_ZDSDYS", section = "爆发", defaultState = false },
            -- ★ 第1行第2列：偷药开关
            { row = 1, column = 2, IconID = 236871, text = "|cffC79C6E偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "FZ_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 3, IconID = 135727, text = "|cffC79C6E自动|r", tooltipText = "自动使用|cff00adf0种族|r\n", saveVariable = "FZ_KG_ZDZZ", section = "爆发", defaultState = true },
            { row = 1, column = 4, IconID = 132962, text = "|cffC79C6E自动|r", tooltipText = "自动使用|cff00adf0手套|r\n", saveVariable = "FZ_KG_ZDST", section = "爆发", defaultState = true },
            { row = 1, column = 5, IconID = 136047, text = "|cffC79C6E锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "FZ_KG_SUO", defaultState = true },

            -- 第2行
            { row = 2, column = 1, IconID = 133712, text = "|cffC79C6E自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r\n", saveVariable = "FZ_KG_ZDZD", defaultState = false },            { row = 2, column = 3, IconID = 132338, text = "|cffC79C6E强制|r", tooltipText = "强制使用|cff00adf0顺劈|r\n", saveVariable = "FZ_KG_QZSP", defaultState = false },
            { row = 2, column = 4, IconID = 132338, text = "|cffC79C6E智能|r", tooltipText = "智能使用|cff00adf0顺劈|r\n", saveVariable = "FZ_KG_ZNSP", defaultState = true },
            { row = 2, column = 5, IconID = 132363, text = "|cffC79C6E破甲|r", tooltipText = "关闭开关不打|cff00adf0破甲|r\n", saveVariable = "FZ_BDPJ", defaultState = true },

            -- 第3行
            { row = 3, column = 1, IconID = 132110, text = "|cffC79C6E自动|r", tooltipText = "关闭开关不打|cff00adf0盾牌格挡|r\n", saveVariable = "FZ_DPGD", defaultState = true },
            { row = 3, column = 2, IconID = 132306, text = "|cffC79C6E自动|r", tooltipText = "关闭开关不打|cff00adf0横扫攻击|r\n", saveVariable = "FZ_HSGJ", defaultState = true },
            { row = 3, column = 3, IconID = 136224, text = "|cffC79C6E自动|r", tooltipText = "自动解恐惧,如果你发现你中了恐惧不会解请把这个debuff名字告诉我", saveVariable = "FZ_KBZN", defaultState = true },
            { row = 3, column = 4, IconID = 132453, text = "|cffC79C6E自动|r", tooltipText = "自动使用英勇投掷功能.5码以上或者目标不是你", saveVariable = "FZ_YYTZ", defaultState = true },
            { row = 3, column = 5, IconID = 136105, text = "|cffC79C6E单|r", tooltipText = "单目标是否保持雷霆", saveVariable = "FZ_LTYJ", defaultState = true },

            -- 第4行
            { row = 4, column = 1, IconID = 132366, text = "|cffC79C6E自动|r", tooltipText = "是否保持挫志怒吼", saveVariable = "FZ_CZNH", defaultState = true },
            { row = 4, column = 2, IconID = 236312, text = "|cffC79C6E插入|r", tooltipText = "插入 震荡波", saveVariable = "FZ_ZDB_CR", section = "插入", defaultState = false },
            { row = 4, column = 3, IconID = 132091, text = "|cffC79C6E插入|r", tooltipText = "插入 挑战怒吼", saveVariable = "FZ_TZNH_CR", section = "插入", defaultState = false },
            { row = 4, column = 4, IconID = 132336, text = "|cffC79C6E插入|r", tooltipText = "插入 反击风暴", saveVariable = "FZ_FJFB_CR", section = "插入", defaultState = false },
            { row = 4, column = 5, IconID = 132350, text = "|cffC79C6E插入|r", tooltipText = "插入 惩戒痛击", saveVariable = "FZ_CJTJ_CR", section = "插入", defaultState = false },

            -- 第5行
            { row = 5, column = 1, IconID = 311430, text = "|cffC79C6E插入|r", tooltipText = "使用|cff00adf0碎裂投掷|r\n", saveVariable = "FZ_CRSLTZ", section = "插入", defaultState = false },
            -- ★ 第5行第2-5列：复仇循环专属选项
            { row = 5, column = 2, IconID = 132357, text = "|cffC79C6E盾猛|r", tooltipText = "盾牌猛击（复仇循环）", saveVariable = "FZ_DUNMENG", defaultState = false },
            { row = 5, column = 3, IconID = 132369, text = "|cffC79C6E乘胜|r", tooltipText = "乘胜追击（复仇循环）", saveVariable = "FZ_CSZJ", defaultState = false },
            { row = 5, column = 4, IconID = 132329, text = "|cffC79C6E致死|r", tooltipText = "致死打击（复仇循环）", saveVariable = "FZ_ZHISI", defaultState = false },
            { row = 5, column = 5, IconID = 132361, text = "|cffC79C6E撕裂|r", tooltipText = "撕裂（复仇循环）", saveVariable = "FZ_SILIE", defaultState = false },
            -- ★ 自动切目标开关
            { row = 6, column = 1, IconID = 132293, text = "|cffC79C6E切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标（坦克用于快速切目标建立仇恨）", saveVariable = "FZ_TAB", defaultState = false },
            { row = 6, column = 2, IconID = 132320, text = "|cffC79C6E自动|r", tooltipText = "自动缴械（仅人型/野兽，爆发或斩杀期释放）", saveVariable = "FZ_JF", defaultState = false },
            -- ★ 2026-08-25 #6：防战插入震荡猛击 / 插入缴械（与自动缴械双模式）
            { row = 6, column = 3, IconID = 132325, text = "|cffC79C6E插入|r", tooltipText = "插入 震荡猛击（一次性，施放后自关）", saveVariable = "FZ_ZCMJ_CR", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 132343, text = "|cffC79C6E插入|r", tooltipText = "插入 缴械（一次性，仅人型/野兽，施放后自关）", saveVariable = "FZ_JF_CR", section = "插入", defaultState = false },
        },
    },
}

-- 注册菜单
if WR_RegisterMenu then
    WR_RegisterMenu("WARRIOR", Warrior_Menu)
end