-- ============================================================
-- Rogue_Menu.lua
-- 盗贼全专精配置菜单（奇袭 / 战斗 / 敏锐）
-- 包含各类自动功能、插入技能、AOE阈值等开关
-- ============================================================

if WR_PlayerClass ~= "ROGUE" then return end

Rogue_Menu = {
    -- ==================== 奇袭专精 ====================
    ["奇袭"] = {
        -- 下拉菜单列表
        DM = {
            {
                text = "|cffFFF569防ADD|r",
                menuItems = {
                    { text = "|cffFFF569是|r" },
                    { text = "|cffFFF569否|r" },
                },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_CSZ",
                defaultID = 1
            },
            {
                text = "|cffFFF569寒霜刺骨|r",
                menuItems = {
                    { text = "|cffFFF5695|r" },
                    { text = "|cffFFF5696|r" },
                    { text = "|cffFFF5697|r" },
                    { text = "|cffFFF5698|r" },
                    { text = "|cffFFF5699|r" },
                    { text = "|cffFFF56910|r" },
                    { text = "|cffFFF569禁用|r" },
                },
                tooltipText = "|cff00adf0寒霜刺骨|r层数大于等于设定值，自动停手(|cff00adf0冰龙|r技能)",
                saveVariable = "DZ_CS_HSCG",
                section = "自动",
                defaultID = 7
            },
            {
                text = "|cffFFF569毒伤星数|r",
                menuItems = {
                    { text = "|cffFFF5693+|r" },
                    { text = "|cffFFF5694+|r" },
                },
                tooltipText = "|cff00adf0毒伤|r打>=3还是>=4)",
                saveVariable = "DZ_CS_DSXS",
                defaultID = 2
            },
            {
                text = "|cffFFF569刀扇数量|r",
                menuItems = {
                    { text = "|cffFFF5693+|r" },
                    { text = "|cffFFF5694+|r" },
                    { text = "|cffFFF5695+|r" },
                    { text = "|cffFFF5696+|r" },
                },
                tooltipText = "|cff00adf0几个目标开始打刀扇|r3+包括3)",
                saveVariable = "DZ_CS_DSSL",
                defaultID = 2
            },
            {
                text = "|cffFFF569剑刃乱舞|r",
                menuItems = {
                    { text = "|cffFFF569触发|r" },
                    { text = "|cffFFF569多目标|r" },
                    { text = "|cffFFF569触发 OR 多目标|r" },
                },
                tooltipText = "|cff00adf0剑刃乱舞|r触发模式,必须要打开启动乱舞的那个开关才会生效",
                saveVariable = "DZ_CS_JRLW_MODE",
                defaultID = 3
            },
            {
                text = "|cffFFF569灭绝|r",
                menuItems = {
                    { text = "|cffFFF569触发|r" },
                    { text = "|cffFFF569嗜血|r" },
                    { text = "|cffFFF569触发 OR 嗜血|r" },
                },
                tooltipText = "|cff00adf0剑刃乱舞|r触发模式,必须要打开启动乱舞的那个开关才会生效",
                saveVariable = "DZ_CS_MJ_MODE",
                defaultID = 3
            },
            { text = "|cffFFF569打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "DZ_CS_ZDDD" },
        },
        -- 复选框列表
        CB = {
            -- ★ ★ 新增偷药开关（控制自动速度药水的使用）
            { row = 1, column = 1, IconID = 236871, text = "|cffFFF569偷药|r", tooltipText = "开启后，自动药水才会在爆发期使用", saveVariable = "DZ_CS_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 2, IconID = 236871, text = "|cffFFF569自动|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "DZ_CS_ZDSDYS", section = "爆发", defaultState = false },
            { row = 1, column = 3, IconID = 135727, text = "|cffFFF569自动|r", tooltipText = "自动使用|cff00adf0种族|r", saveVariable = "DZ_CS_ZDZZ", section = "爆发", defaultState = true },
            { row = 1, column = 4, IconID = 338666, text = "|cffFFF569自动|r", tooltipText = "自动|cff00adf0饰品|r", saveVariable = "DZ_CS_ZDSP", section = "爆发", defaultState = true },
            { row = 1, column = 5, IconID = 132962, text = "|cffFFF569自动|r", tooltipText = "自动使用|cff00adf0手套|r", saveVariable = "DZ_CS_ZDST", section = "爆发", defaultState = true },
            { row = 2, column = 1, IconID = 136047, text = "|cffFFF569锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "DZ_CS_SUO", defaultState = true },
            { row = 2, column = 2, IconID = 133712, text = "|cffFFF569自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r", saveVariable = "DZ_CS_ZDZD", defaultState = true },            { row = 2, column = 4, IconID = 132331, text = "|cffFFF569无敌|r", tooltipText = "自动|cff00adf0消失|r躲技能", saveVariable = "DZ_CS_ZDXS", defaultState = true },
            { row = 2, column = 5, IconID = 136177, text = "|cffFFF569自动|r", tooltipText = "自动|cff00adf0斗篷|r解技能", saveVariable = "DZ_CS_ZDAYDP", defaultState = true },
            { row = 3, column = 1, IconID = 132273, text = "|cffFFF569上毒|r", tooltipText = "自动", saveVariable = "DZ_CS_ZDDY", defaultState = true },
            { row = 3, column = 2, IconID = 132302, text = "|cffFFF569循环|r", tooltipText = "|cff00adf0割裂|r循环,需要使用割裂天赋,这版本装备好了以后可以开启体验\n", saveVariable = "DZ_CS_GLXH", defaultState = false },
            { row = 3, column = 3, IconID = 132302, text = "|cffFFF569饥渴|r", tooltipText = "自己打饥渴需要的流血,团里没战士,其他贼.猫的话可以打开\n", saveVariable = "DZ_CS_GLJK", defaultState = false },
            { row = 3, column = 4, IconID = 236273, text = "|cffFFF569自动|r", tooltipText = "自动使用|cff00adf0刀扇|r,\n", saveVariable = "DZ_CS_ZDDS", defaultState = false },
            { row = 3, column = 5, IconID = 236273, text = "|cffFFF569强制|r", tooltipText = "强制使用|cff00adf0刀扇|r,\n", saveVariable = "DZ_CS_QZDS", defaultState = false },
            { row = 4, column = 1, IconID = 132306, text = "|cffFFF569刀扇|r", tooltipText = "|cff00adf0刀扇|r是否需要补切割,打钩为补\n", saveVariable = "DZ_CS_DSQG", defaultState = true },
            { row = 4, column = 2, IconID = 132354, text = "|cffFFF569破甲|r", tooltipText = "插破甲雕文,点破甲天赋,1星无脑破甲骗能量", saveVariable = "DZ_CS_PJ", defaultState = false },
            { row = 4, column = 3, IconID = 236283, text = "|cffFFF569目标的\n目标|r", tooltipText = "直接对目标的目标释放,优先级高于焦点.用焦点请关闭这个", saveVariable = "DZ_CS_JHJQ_TARGETTARGET", defaultState = true },
            { row = 4, column = 4, IconID = 236283, text = "|cffFFF569焦点|r", tooltipText = "需要自己设置焦点", saveVariable = "DZ_CS_JHJQ_FOCUS", defaultState = false },
            { row = 4, column = 5, IconID = 132350, text = "|cffFFF569自动|r", tooltipText = "BOSS目标有切割多目标自动开启|cff00adf0剑刃乱舞|r", saveVariable = "DZ_CS_ZDJRLW", defaultState = true },
            { row = 5, column = 1, IconID = 132331, text = "|cffFFF569灭绝|r", tooltipText = "续灭绝", saveVariable = "DZ_CS_MJ", defaultState = true },
            { row = 5, column = 2, IconID = 132350, text = "|cffFFF569插入|r", tooltipText = "插入|cff00adf0剑刃乱舞|r", saveVariable = "DZ_CS_CRJRLW", section = "插入", defaultState = false },
            { row = 5, column = 3, IconID = 132294, text = "|cffFFF569插入|r", tooltipText = "插入|cff00adf0佯攻|r", saveVariable = "DZ_CS_CRYG", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 6, column = 1, IconID = 132293, text = "|cffFFF569切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "DZ_CS_TAB", defaultState = false },
        },
    },

    -- ==================== 战斗专精 ====================
    ["战斗"] = {
        -- 下拉菜单列表
        DM = {
            {
                text = "|cffFFF569防ADD|r",
                menuItems = {
                    { text = "|cffFFF569是|r" },
                    { text = "|cffFFF569否|r" },
                },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_ZDZ",
                defaultID = 1
            },
            {
                text = "|cffFFF569寒霜刺骨|r",
                menuItems = {
                    { text = "|cffFFF5695|r" },
                    { text = "|cffFFF5696|r" },
                    { text = "|cffFFF5697|r" },
                    { text = "|cffFFF5698|r" },
                    { text = "|cffFFF5699|r" },
                    { text = "|cffFFF56910|r" },
                    { text = "|cffFFF569禁用|r" },
                },
                tooltipText = "|cff00adf0寒霜刺骨|r层数大于等于设定值，自动停手(|cff00adf0冰龙|r技能)",
                saveVariable = "DZ_ZD_HSCG",
                section = "自动",
                defaultID = 7
            },
            {
                text = "|cffFFF569刀扇数量|r",
                menuItems = {
                    { text = "|cffFFF5693+|r" },
                    { text = "|cffFFF5694+|r" },
                    { text = "|cffFFF5695+|r" },
                    { text = "|cffFFF5696+|r" },
                },
                tooltipText = "|cff00adf0几个目标开始打刀扇|r3+包括3)",
                saveVariable = "DZ_ZD_DSSL",
                defaultID = 2
            },
            {
                text = "|cffFFF569剑刃乱舞|r",
                menuItems = {
                    { text = "|cffFFF569触发|r" },
                    { text = "|cffFFF569多目标|r" },
                    { text = "|cffFFF569触发 OR 多目标|r" },
                },
                tooltipText = "|cff00adf0剑刃乱舞|r触发模式,必须要打开启动乱舞的那个开关才会生效",
                saveVariable = "DZ_ZD_JRLW_MODE",
                defaultID = 3
            },
            { text = "|cffFFF569打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "DZ_ZD_ZDDD" },
        },
        -- 复选框列表
        CB = {
            -- ★ ★ 新增偷药开关（控制自动速度药水的使用）
            { row = 1, column = 1, IconID = 236871, text = "|cffFFF569偷药|r", tooltipText = "开启后，自动药水才会在爆发期使用", saveVariable = "DZ_ZD_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 2, IconID = 236871, text = "|cffFFF569自动|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "DZ_ZD_ZDSDYS", section = "爆发", defaultState = false },
            { row = 1, column = 3, IconID = 135727, text = "|cffFFF569自动|r", tooltipText = "自动使用|cff00adf0种族|r", saveVariable = "DZ_ZD_ZDZZ", section = "爆发", defaultState = true },
            { row = 1, column = 4, IconID = 338666, text = "|cffFFF569自动|r", tooltipText = "自动|cff00adf0饰品|r", saveVariable = "DZ_ZD_ZDSP", section = "爆发", defaultState = true },
            { row = 1, column = 5, IconID = 132962, text = "|cffFFF569自动|r", tooltipText = "自动使用|cff00adf0手套|r", saveVariable = "DZ_ZD_ZDST", section = "爆发", defaultState = true },
            { row = 2, column = 1, IconID = 136047, text = "|cffFFF569锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "DZ_ZD_SUO", defaultState = true },
            { row = 2, column = 2, IconID = 133712, text = "|cffFFF569自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r", saveVariable = "DZ_ZD_ZDZD", defaultState = true },            { row = 2, column = 4, IconID = 132331, text = "|cffFFF569无敌|r", tooltipText = "自动|cff00adf0消失|r躲技能", saveVariable = "DZ_ZD_ZDXS", defaultState = true },
            { row = 2, column = 5, IconID = 136177, text = "|cffFFF569自动|r", tooltipText = "自动|cff00adf0斗篷|r解技能", saveVariable = "DZ_ZD_ZDAYDP", defaultState = true },
            { row = 3, column = 1, IconID = 132273, text = "|cffFFF569上毒|r", tooltipText = "自动", saveVariable = "DZ_ZD_ZDDY", defaultState = true },
            { row = 3, column = 2, IconID = 132354, text = "|cffFFF569破甲|r", tooltipText = "自动1-2星|cff00adf0破甲|r,\n", saveVariable = "DZ_ZD_ZDPJ", defaultState = false },
            { row = 3, column = 3, IconID = 136206, text = "|cffFFF569冲动|r", tooltipText = "能量小于60饰品触发|cff00adf0冲动|r,\n", saveVariable = "DZ_ZD_ZDCD", section = "爆发", defaultState = true },
            { row = 3, column = 4, IconID = 132350, text = "|cffFFF569自动|r", tooltipText = "有切割多目标|cff00adf0剑刃乱舞|r", saveVariable = "DZ_ZD_ZDJRLW", defaultState = true },
            { row = 3, column = 5, IconID = 236277, text = "|cffFFF569自动|r", tooltipText = "自动|cff00adf0杀戮盛筵|r,\n", saveVariable = "DZ_ZD_ZDSLSY", defaultState = true },
            { row = 4, column = 1, IconID = 236273, text = "|cffFFF569自动|r", tooltipText = "自动使用|cff00adf0刀扇|r,\n", saveVariable = "DZ_ZD_ZDDS", defaultState = false },
            { row = 4, column = 2, IconID = 236273, text = "|cffFFF569强制|r", tooltipText = "强制使用|cff00adf0刀扇|r,\n", saveVariable = "DZ_ZD_QZDS", defaultState = false },
            { row = 4, column = 3, IconID = 132306, text = "|cffFFF569刀扇|r", tooltipText = "|cff00adf0刀扇|r是否需要补切割,打钩为补\n", saveVariable = "DZ_ZD_DSQG", defaultState = true },
            { row = 4, column = 4, IconID = 236283, text = "|cffFFF569目标的\n目标|r", tooltipText = "直接对目标的目标释放,优先级高于焦点.用焦点请关闭这个", saveVariable = "DZ_ZD_JHJQ_TARGETTARGET", defaultState = true },
            { row = 4, column = 5, IconID = 236283, text = "|cffFFF569焦点|r", tooltipText = "需要自己设置焦点", saveVariable = "DZ_ZD_JHJQ_FOCUS", defaultState = false },
            { row = 5, column = 1, IconID = 132350, text = "|cffFFF569插入|r", tooltipText = "插入|cff00adf0剑刃乱舞|r", saveVariable = "DZ_ZD_CRJRLW", section = "插入", defaultState = false },
            { row = 5, column = 2, IconID = 132294, text = "|cffFFF569插入|r", tooltipText = "插入|cff00adf0佯攻|r", saveVariable = "DZ_ZD_CRYG", section = "插入", defaultState = false },
            { row = 5, column = 3, IconID = 136206, text = "|cffFFF569插入|r", tooltipText = "插入|cff00adf0冲动|r,\n", saveVariable = "DZ_ZD_CRCD", section = "爆发", defaultState = false },
            { row = 5, column = 4, IconID = 236277, text = "|cffFFF569插入|r", tooltipText = "插入|cff00adf0杀戮盛筵|r,\n", saveVariable = "DZ_ZD_CRSLSY", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 6, column = 1, IconID = 132293, text = "|cffFFF569切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "DZ_ZD_TAB", defaultState = false },
        },
    },

    -- ==================== 敏锐专精 ====================
    ["敏锐"] = {
        -- 下拉菜单列表
        DM = {
            {
                text = "|cffFFF569防ADD|r",
                menuItems = {
                    { text = "|cffFFF569是|r" },
                    { text = "|cffFFF569否|r" },
                },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_MRZ",
                defaultID = 1
            },
            {
                text = "|cffFFF569寒霜刺骨|r",
                menuItems = {
                    { text = "|cffFFF5695|r" },
                    { text = "|cffFFF5696|r" },
                    { text = "|cffFFF5697|r" },
                    { text = "|cffFFF5698|r" },
                    { text = "|cffFFF5699|r" },
                    { text = "|cffFFF56910|r" },
                    { text = "|cffFFF569禁用|r" },
                },
                tooltipText = "|cff00adf0寒霜刺骨|r层数大于等于设定值，自动停手(|cff00adf0冰龙|r技能)",
                saveVariable = "DZ_MR_HSCG",
                section = "自动",
                defaultID = 7
            },
            {
                text = "|cffFFF56935%印记|r",
                menuItems = {
                    { text = "|cffFFF56910秒以下|r" },
                    { text = "|cffFFF56911秒以下|r" },
                    { text = "|cffFFF56912秒以下|r" },
                    { text = "|cffFFF56913秒以下|r" },
                    { text = "|cffFFF56914秒以下|r" },
                    { text = "|cffFFF569正常|r" },
                },
                tooltipText = "35%以下的时候割裂小于多少才用印记刷新.",
                saveVariable = "DZ_MR_YJ",
                defaultID = 6
            },
            {
                text = "|cffFFF569刀扇数量|r",
                menuItems = {
                    { text = "|cffFFF5693+|r" },
                    { text = "|cffFFF5694+|r" },
                    { text = "|cffFFF5695+|r" },
                    { text = "|cffFFF5696+|r" },
                },
                tooltipText = "|cff00adf0几个目标开始打刀扇|r3+包括3)",
                saveVariable = "DZ_MR_DSSL",
                defaultID = 2
            },
            {
                text = "|cffFFF569剑刃乱舞|r",
                menuItems = {
                    { text = "|cffFFF569触发|r" },
                    { text = "|cffFFF569多目标|r" },
                    { text = "|cffFFF569触发 OR 多目标|r" },
                },
                tooltipText = "|cff00adf0剑刃乱舞|r触发模式,必须要打开启动乱舞的那个开关才会生效",
                saveVariable = "DZ_MR_JRLW_MODE",
                defaultID = 3
            },
            {
                text = "|cffFFF569切割|r",
                isSlider = true,
                minValue = 1,
                maxValue = 5,
                valueStep = 1,
                defaultVal = 5,
                tooltipText = "大于等于几星补切割",
                saveVariable = "DZ_MR_QG_SZ",
            },
            { text = "|cffFFF569打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "DZ_MR_ZDDD" },
        },
        -- 复选框列表
        CB = {
            -- ★ ★ 新增偷药开关（控制自动速度药水的使用）
            { row = 1, column = 1, IconID = 236871, text = "|cffFFF569偷药|r", tooltipText = "开启后，自动药水才会在爆发期使用", saveVariable = "DZ_MR_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 2, IconID = 236871, text = "|cffFFF569自动|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "DZ_MR_ZDSDYS", section = "爆发", defaultState = false },
            { row = 1, column = 3, IconID = 135727, text = "|cffFFF569自动|r", tooltipText = "自动使用|cff00adf0种族|r", saveVariable = "DZ_MR_ZDZZ", section = "爆发", defaultState = true },
            { row = 1, column = 4, IconID = 338666, text = "|cffFFF569自动|r", tooltipText = "自动|cff00adf0饰品|r", saveVariable = "DZ_MR_ZDSP", section = "爆发", defaultState = true },
            { row = 1, column = 5, IconID = 132962, text = "|cffFFF569自动|r", tooltipText = "自动使用|cff00adf0手套|r", saveVariable = "DZ_MR_ZDST", section = "爆发", defaultState = true },
            { row = 2, column = 1, IconID = 136047, text = "|cffFFF569锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "DZ_MR_SUO", defaultState = true },
            { row = 2, column = 2, IconID = 133712, text = "|cffFFF569自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r", saveVariable = "DZ_MR_ZDZD", defaultState = true },            { row = 2, column = 4, IconID = 132331, text = "|cffFFF569无敌|r", tooltipText = "自动|cff00adf0消失|r躲技能", saveVariable = "DZ_MR_ZDXS", defaultState = true },
            { row = 2, column = 5, IconID = 136177, text = "|cffFFF569自动|r", tooltipText = "自动|cff00adf0斗篷|r解技能", saveVariable = "DZ_MR_ZDAYDP", defaultState = true },
            { row = 3, column = 1, IconID = 236279, text = "|cffFFF569自动|r", tooltipText = "自动使用|cffff0000暗影之舞|r", saveVariable = "DZ_MR_AYZW_ZD", defaultState = false },
            { row = 3, column = 2, IconID = 132331, text = "|cffFFF569自动|r", tooltipText = "自动使用|cffff0000消失|r", saveVariable = "DZ_MR_XS", defaultState = false },
            { row = 3, column = 3, IconID = 136121, text = "|cffFFF569自动|r", tooltipText = "自动使用|cffff0000伺机待发|r", saveVariable = "DZ_MR_SJDF", defaultState = false },
            { row = 3, column = 4, IconID = 236273, text = "|cffFFF569自动|r", tooltipText = "自动使用|cff00adf0刀扇|r,\n", saveVariable = "DZ_MR_ZDDS", defaultState = false },
            { row = 3, column = 5, IconID = 236273, text = "|cffFFF569强制|r", tooltipText = "强制使用|cff00adf0刀扇|r,\n", saveVariable = "DZ_MR_QZDS", defaultState = false },
            { row = 4, column = 1, IconID = 132306, text = "|cffFFF569刀扇|r", tooltipText = "|cff00adf0刀扇|r是否需要补切割,打钩为补\n", saveVariable = "DZ_MR_DSQG", defaultState = true },
            { row = 4, column = 2, IconID = 132354, text = "|cffFFF569破甲|r", tooltipText = "自动破甲", saveVariable = "DZ_MR_PJ", defaultState = false },
            { row = 4, column = 3, IconID = 132320, text = "|cffFFF569自动|r", tooltipText = "脱战自动潜行.", saveVariable = "DZ_MR_QX_ZD", defaultState = true },
            { row = 4, column = 4, IconID = 132303, text = "|cffFFF569自动|r", tooltipText = "起手自动暗影步.剔骨自动暗影步", saveVariable = "DZ_MR_AYB_ZD", defaultState = true },
            { row = 4, column = 5, IconID = 132350, text = "|cffFFF569自动|r", tooltipText = "BOSS目标有切割多目标自动开启|cff00adf0剑刃乱舞|r", saveVariable = "DZ_MR_ZDJRLW", defaultState = false },
            { row = 5, column = 1, IconID = 132273, text = "|cffFFF569上毒|r", tooltipText = "自动", saveVariable = "DZ_MR_ZDDY", defaultState = true },
            { row = 5, column = 2, IconID = 236283, text = "|cffFFF569目标的\n目标|r", tooltipText = "直接对目标的目标释放,优先级高于焦点.用焦点请关闭这个", saveVariable = "DZ_MR_JHJQ_TARGETTARGET", defaultState = true },
            { row = 5, column = 3, IconID = 236283, text = "|cffFFF569焦点|r", tooltipText = "需要自己设置焦点", saveVariable = "DZ_MR_JHJQ_FOCUS", defaultState = false },
            { row = 5, column = 4, IconID = 236283, text = "|cffFFF569暗影\n之舞|r", tooltipText = "打开会关联暗影之舞,关闭是卡CD", saveVariable = "DZ_MR_JHJQ_AYZW", defaultState = false },
            { row = 5, column = 5, IconID = 132297, text = "|cffFFF569锁喉|r", tooltipText = "是否使用锁喉,正面的话会连续锁喉", saveVariable = "DZ_MR_SH", defaultState = false },
            { row = 6, column = 1, IconID = 132294, text = "|cffFFF569插入|r", tooltipText = "插入|cff00adf0佯攻|r", saveVariable = "DZ_MR_CRYG", section = "插入", defaultState = false },
            { row = 6, column = 2, IconID = 132350, text = "|cffFFF569插入|r", tooltipText = "插入|cff00adf0剑刃乱舞|r", saveVariable = "DZ_MR_CRJRLW", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 236274, text = "|cffFFF569起手\n10星|r", tooltipText = "先自己吸5个星,手里有N星都可以,潜行", saveVariable = "DZ_MR_AUTOQS", defaultState = false },
            -- ★ 自动切目标开关
            { row = 7, column = 1, IconID = 132293, text = "|cffFFF569切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "DZ_MR_TAB", defaultState = false },
        },
    },
}