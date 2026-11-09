-- ============================================================
-- Warlock_Menu.lua
-- 术士全专精配置菜单（痛苦 / 恶魔学识 / 毁灭）
-- 包含各类自动功能、插入技能、爆发等开关
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

Warlock_Menu = {
    -- ==================== 痛苦专精 ====================
    ["痛苦"] = {
        -- 下拉菜单列表
        DM = {
            {
                text = "|cff9482C9防ADD|r",
                menuItems = {
                    { text = "|cff9482C9是|r" },
                    { text = "|cff9482C9否|r" },
                },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_TKS",
                defaultID = 1
            },
            {
                text = "|cff9482C9魔甲|r",
                menuItems = {
                    { text = "|cff9482C9邪甲术|r" },
                    { text = "|cff9482C9魔甲术|r" },
                    { text = "|cff9482C9禁用|r" },
                },
                tooltipText = "使用|cff00adf0?甲|",
                saveVariable = "SS_TK_HJ",
                defaultID = 1
            },
            {
                text = "|cff9482C9狂咒|r",
                menuItems = {
                    { text = "|cff9482C9停手|r" },
                    { text = "|cff9482C91层|r" },
                    { text = "|cff9482C92层|r" },
                    { text = "|cff9482C93层|r" },
                    { text = "|cff9482C94层|r" },
                    { text = "|cff9482C95层|r" },
                    { text = "|cff9482C9不停手|r" },
                },
                tooltipText = "ICC冰龙的debuff中几层|cff00adf0狂咒|r停手",
                saveVariable = "SS_TK_KZ",
                section = "自动",
                defaultID = 1
            },
            {
                text = "|cff9482C9脱战宠物|r",
                menuItems = {
                    { text = "|cff9482C9关闭|r" },
                    { text = "|cff9482C9小鬼|r" },
                    { text = "|cff9482C9虚空行者|r" },
                    { text = "|cff9482C9魅魔|r" },
                    { text = "|cff9482C9地狱猎犬|r" },
                    { text = "|cff9482C9恶魔卫士|r" },
                },
                tooltipText = "脱战且无宝宝时自动召唤指定宠物（覆盖原\"召唤小鬼\"开关，三系统一）",
                saveVariable = "SS_TK_AUTOSUMMON",
                defaultID = 5
            },
            {
                text = "|cff9482C9武器石|r",
                menuItems = {
                    { text = "|cff9482C9关闭|r" },
                    { text = "|cff9482C9法术石|r" },
                    { text = "|cff9482C9火焰石|r" },
                },
                tooltipText = "脱战自动武器石：法术石附魔副手，火焰石附魔主手；背包无则自动制造",
                saveVariable = "WL_AFL_ZDFSS",
                defaultID = 2
            },
        },
        -- 复选框列表
        CB = {
            -- ★ ★ 新增偷药开关（控制自动速度药水和狂野魔法药水的使用）
            { row = 1, column = 1, IconID = 236871, text = "|cff9482C9偷药|r", tooltipText = "开启后，自动药水才会在爆发期使用", saveVariable = "SS_TK_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 2, IconID = 136228, text = "|cff9482C9全局|r", tooltipText = "队友的目标无DOT.自动|cff00adf0痛苦无常|r", saveVariable = "SS_TK_QJTKWC", defaultState = false },
            { row = 1, column = 3, IconID = 136118, text = "|cff9482C9全局|r", tooltipText = "队友的目标无DOT.自动|cff00adf0腐蚀术|r", saveVariable = "SS_TK_QJFSS", defaultState = false },
            { row = 1, column = 4, IconID = 236871, text = "|cff9482C9自动|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "SS_TK_ZDSDYS", section = "爆发", defaultState = false },
            { row = 1, column = 5, IconID = 236868, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0狂野魔法|r", saveVariable = "SS_TK_ZDKYMF", defaultState = false },
            { row = 2, column = 1, IconID = 135727, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0种族|r", saveVariable = "SS_TK_ZDZZ", section = "爆发", defaultState = true },
            { row = 2, column = 2, IconID = 338666, text = "|cff9482C9自动|r", tooltipText = "自动|cff00adf0饰品|r", saveVariable = "SS_TK_ZDSP", section = "爆发", defaultState = true },
            { row = 2, column = 3, IconID = 132962, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0手套|r", saveVariable = "SS_TK_ZDST", section = "爆发", defaultState = true },
            { row = 2, column = 4, IconID = 133712, text = "|cff9482C9自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r", saveVariable = "SS_TK_ZDZD", defaultState = true },
            { row = 2, column = 5, IconID = 136216, text = "|cff9482C9攻击|r", tooltipText = "控制|cff00adf0宠物|r", saveVariable = "SS_TK_KZBB", defaultState = true },
            { row = 3, column = 1, IconID = 136197, text = "|cff9482C9爆|r", tooltipText = "起手|cff00adf05爆|r,手动偷暗影箭起手就别开", saveVariable = "SS_TK_FIVE", defaultState = false },
            { row = 3, column = 2, IconID = 136228, text = "|cff9482C9焦点|r", tooltipText = "自动焦点|cff00adf0痛苦无常|r", saveVariable = "SS_TK_JDTKWC", defaultState = true },
            { row = 3, column = 3, IconID = 136118, text = "|cff9482C9焦点|r", tooltipText = "自动焦点|cff00adf0腐蚀术|r", saveVariable = "SS_TK_JDFSS", defaultState = true },
            { row = 3, column = 4, IconID = 136139, text = "|cff9482C9焦点|r", tooltipText = "自动焦点|cff00adf0痛苦诅咒|r", saveVariable = "SS_TK_JDTKZZ", defaultState = true },
            { row = 3, column = 5, IconID = 136193, text = "|cff9482C9无脑|r", tooltipText = "|cff00adf0腐蚀之种|r,最好做个切换宏方便控制.手动开关.", saveVariable = "SS_TK_FSZZ", defaultState = false },
            { row = 4, column = 1, IconID = 136228, text = "|cff9482C9指向|r", tooltipText = "自动指向|cff00adf0痛苦无常|r", saveVariable = "SS_TK_ZXTKWC", defaultState = true },
            { row = 4, column = 2, IconID = 136118, text = "|cff9482C9指向|r", tooltipText = "自动指向|cff00adf0腐蚀术|r", saveVariable = "SS_TK_ZXFSS", defaultState = true },
            { row = 4, column = 3, IconID = 136139, text = "|cff9482C9指向|r", tooltipText = "自动指向|cff00adf0痛苦诅咒|r", saveVariable = "SS_TK_ZXTKZZ", defaultState = true },
            { row = 4, column = 4, IconID = 136219, text = "|cff9482C9自动|r", tooltipText = "自动|cff00adf0地狱火|r", saveVariable = "SS_TK_ZDDYH", defaultState = false },
            { row = 4, column = 5, IconID = 136047, text = "|cff9482C9锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "SS_TK_SUO", defaultState = true },
            { row = 5, column = 1, IconID = 136118, text = "|cff9482C9刷新|r", tooltipText = "刷新大于5%以上权重|cff00adf0腐蚀术|r", saveVariable = "SS_TK_SXFSS", defaultState = true },
            { row = 5, column = 2, IconID = 136135, text = "|cff9482C9加尔|r", tooltipText = "如果你的焦点是加尔的小怪(手动设置),自动放逐加尔的小怪,此开关干扰全局判断.不用的时候请禁用", saveVariable = "SS_TK_FZS_ZD", defaultState = false },
            { row = 5, column = 3, IconID = 237559, text = "|cff9482C9召唤|r", tooltipText = "|cff00adf0召唤|r", saveVariable = "SS_TK_CRZH", defaultState = false },
            { row = 5, column = 4, IconID = 237560, text = "|cff9482C9传送|r", tooltipText = "|cff00adf0传送|r", saveVariable = "SS_TK_CRCS", defaultState = false },
            { row = 5, column = 5, IconID = 136122, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0厄运诅咒|r", saveVariable = "SS_TK_CREYZZ", section = "插入", defaultState = false },
            { row = 6, column = 1, IconID = 136219, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0地狱火|r", saveVariable = "SS_TK_CRDYH", section = "插入", defaultState = false },
            { row = 6, column = 2, IconID = 236871, text = "|cff9482C9插入||r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "SS_TK_CRSDYS", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 236868, text = "|cff9482C9插入||r", tooltipText = "插入|cff00adf0狂野魔法|r", saveVariable = "SS_TK_CRKYMF", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 135727, text = "|cff9482C9插入||r", tooltipText = "插入|cff00adf0种族|r", saveVariable = "SS_TK_CRZZ", section = "插入", defaultState = false },
            { row = 6, column = 5, IconID = 338666, text = "|cff9482C9插入||r", tooltipText = "插入|cff00adf0饰品|r", saveVariable = "SS_TK_CRSP", section = "插入", defaultState = false },
            { row = 7, column = 1, IconID = 132962, text = "|cff9482C9插入||r", tooltipText = "插入|cff00adf0手套|r", saveVariable = "SS_TK_CRST", section = "插入", defaultState = false },
            { row = 7, column = 2, IconID = 136169, text = "|cff9482C9插入||r", tooltipText = "插入|cff00adf0灵魂碎裂|r", saveVariable = "SS_TK_CRLHSL", section = "插入", defaultState = false },
            { row = 7, column = 3, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0放逐奶德|r (CTRL+SHIFT+F11)", saveVariable = "SS_TK_TOC_FANQID", defaultState = false },
            { row = 7, column = 4, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0恐惧牧师|r (ALT+CTRL+SHIFT+F11)", saveVariable = "SS_TK_TOC_JLMS", defaultState = false },
            { row = 7, column = 5, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0恐惧奶萨|r (ALT+CTRL+SHIFT+F10)", saveVariable = "SS_TK_TOC_JLNS", defaultState = false },
            { row = 8, column = 1, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0选盗贼猎人|r (ALT+SHIFT+F10)", saveVariable = "SS_TK_TOC_XJDZLR", defaultState = false },
            { row = 8, column = 2, IconID = 132580, text = "|cff9482C9小吃|r", tooltipText = "自动给宠物吃香辣猛犸小吃", saveVariable = "SS_TK_XLMMXC", defaultState = false },
            -- ★ 自动切目标开关
            { row = 9, column = 1, IconID = 132293, text = "|cff9482C9切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "SS_TK_TAB", defaultState = true },
        },
    },

    -- ==================== 恶魔学识专精 ====================
    ["恶魔学识"] = {
        DM = {
            {
                text = "|cff9482C9防ADD|r",
                menuItems = {
                    { text = "|cff9482C9是|r" },
                    { text = "|cff9482C9否|r" },
                },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_EMS",
                defaultID = 1
            },
            {
                text = "|cff9482C9狂咒|r",
                menuItems = {
                    { text = "|cff9482C9停手|r" },
                    { text = "|cff9482C91层|r" },
                    { text = "|cff9482C92层|r" },
                    { text = "|cff9482C93层|r" },
                    { text = "|cff9482C94层|r" },
                    { text = "|cff9482C95层|r" },
                    { text = "|cff9482C9不停手|r" },
                },
                tooltipText = "中几层|cff00adf0狂咒|r停手",
                saveVariable = "SS_EM_KZ",
                section = "自动",
                defaultID = 1
            },
            {
                text = "|cff9482C9魔甲|r",
                menuItems = {
                    { text = "|cff9482C9邪甲术|r" },
                    { text = "|cff9482C9魔甲术|r" },
                    { text = "|cff9482C9禁用|r" },
                },
                tooltipText = "使用|cff00adf0?甲|",
                saveVariable = "SS_EM_HJ",
                defaultID = 1
            },
            {
                text = "|cff9482C9脱战宠物|r",
                menuItems = {
                    { text = "|cff9482C9关闭|r" },
                    { text = "|cff9482C9小鬼|r" },
                    { text = "|cff9482C9虚空行者|r" },
                    { text = "|cff9482C9魅魔|r" },
                    { text = "|cff9482C9地狱猎犬|r" },
                    { text = "|cff9482C9恶魔卫士|r" },
                },
                tooltipText = "脱战且无宝宝时自动召唤指定宠物（恶魔学识默认|cff00adf0恶魔卫士|r，三系统一）",
                saveVariable = "SS_EM_AUTOSUMMON",
                defaultID = 6
            },
            {
                text = "|cff9482C9武器石|r",
                menuItems = {
                    { text = "|cff9482C9关闭|r" },
                    { text = "|cff9482C9法术石|r" },
                    { text = "|cff9482C9火焰石|r" },
                },
                tooltipText = "脱战自动武器石：法术石附魔副手，火焰石附魔主手；背包无则自动制造",
                saveVariable = "WL_EM_ZDFSS",
                defaultID = 2
            },
        },
        CB = {
            -- ★ ★ 偷药/偷灭杀 开关
            { row = 1, column = 1, IconID = 236871, text = "|cff9482C9偷药|r", tooltipText = "开启后，自动药水才会在爆发期使用", saveVariable = "SS_EM_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 2, IconID = 135808, text = "|cffFFF569指向|r", tooltipText = "鼠标指向低血目标时自动暗影箭偷灭杀", saveVariable = "SS_EM_ZX_TMS", defaultState = true },
            { row = 1, column = 3, IconID = 135808, text = "|cffFFF569焦点|r", tooltipText = "对焦点目标自动暗影箭偷灭杀", saveVariable = "SS_EM_JD_TMS", defaultState = true },
            { row = 1, column = 4, IconID = 135808, text = "|cffFFF569全局|r", tooltipText = "遍历小队/团队成员目标，自动偷灭杀低血敌人", saveVariable = "SS_EM_TMS_QJ", defaultState = true },
            { row = 1, column = 5, IconID = 237558, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0恶魔变形|r,吃到嗜血自动变身", saveVariable = "SS_EM_ZDEMBX", section = "爆发", defaultState = true },
            { row = 2, column = 1, IconID = 236871, text = "|cff9482C9自动|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "SS_EM_ZDSDYS", section = "爆发", defaultState = false },
            { row = 2, column = 2, IconID = 135727, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0种族|r", saveVariable = "SS_EM_ZDZZ", section = "爆发", defaultState = true },
            { row = 2, column = 3, IconID = 338666, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0饰品|r", saveVariable = "SS_EM_ZDSP", section = "爆发", defaultState = true },
            { row = 2, column = 4, IconID = 236868, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0狂野魔法|r", saveVariable = "SS_EM_ZDKYMF", defaultState = false },
            { row = 2, column = 5, IconID = 132962, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0手套|r", saveVariable = "SS_EM_ZDST", section = "爆发", defaultState = true },
            { row = 3, column = 1, IconID = 133712, text = "|cff9482C9自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r", saveVariable = "SS_EM_ZDZD", defaultState = false },
            { row = 3, column = 2, IconID = 136216, text = "|cff9482C9攻击|r", tooltipText = "控制|cff00adf0宠物|r", saveVariable = "SS_EM_KZBB", defaultState = true },
            { row = 3, column = 3, IconID = 136193, text = "|cff9482C9无脑|r", tooltipText = "腐蚀之种|cff00adf0|r", saveVariable = "SS_EM_FSZZ", defaultState = false },
            { row = 3, column = 4, IconID = 136163, text = "|cff9482C9吸片|r", tooltipText = "吸片|cff00adf0宠物|r", saveVariable = "SS_EM_XQLH", defaultState = false },
            { row = 3, column = 5, IconID = 132368, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0恶魔冲锋|r", saveVariable = "SS_EM_EMCF", defaultState = false },
            { row = 4, column = 1, IconID = 136047, text = "|cff9482C9锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "SS_EM_SUO", defaultState = true },
            { row = 4, column = 2, IconID = 136139, text = "|cff9482C9痛苦|r", tooltipText = "打开以后不再会释放厄运诅咒", saveVariable = "SS_EM_TKZZ", defaultState = false },
            { row = 4, column = 3, IconID = 136135, text = "|cff9482C9加尔|r", tooltipText = "如果你的焦点是加尔的小怪(手动设置),自动放逐加尔的小怪,此开关干扰全局判断.不用的时候请禁用", saveVariable = "SS_EM_FZS_ZD", defaultState = false },
            { row = 4, column = 4, IconID = 132962, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0手套|r", saveVariable = "SS_EM_CRST", section = "插入", defaultState = false },
            { row = 4, column = 5, IconID = 236868, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0狂野魔法|r", saveVariable = "SS_EM_CRKYMF", section = "插入", defaultState = false },
            { row = 5, column = 1, IconID = 136122, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0厄运诅咒|r", saveVariable = "SS_EM_CREYZZ", section = "插入", defaultState = false },
            { row = 5, column = 2, IconID = 136219, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0地狱火|r", saveVariable = "SS_EM_CRDYH", section = "插入", defaultState = false },
            { row = 5, column = 3, IconID = 237559, text = "|cff9482C9召唤|r", tooltipText = "|cff00adf0召唤|r", saveVariable = "SS_EM_CRZH", defaultState = false },
            { row = 5, column = 4, IconID = 237560, text = "|cff9482C9传送|r", tooltipText = "|cff00adf0传送|r", saveVariable = "SS_EM_CRCS", defaultState = false },
            { row = 5, column = 5, IconID = 136216, text = "|cff9482C9召唤|r", tooltipText = "召唤|cff00adf0恶魔卫士|r", saveVariable = "SS_EM_CREMWS", defaultState = true },
            { row = 6, column = 1, IconID = 135728, text = "|cff9482C9插入||r", tooltipText = "插入|cff00adf0灵魂碎裂|r", saveVariable = "SS_EM_CRLHSL", section = "插入", defaultState = false },
            { row = 6, column = 2, IconID = 237558, text = "|cff9482C9插入|r", tooltipText = "使用|cff00adf0恶魔变形|r", saveVariable = "SS_EM_CREMBX", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 236871, text = "|cff9482C9插入|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "SS_EM_CRSDYS", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 135727, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0种族|r", saveVariable = "SS_EM_CRZZ", section = "插入", defaultState = false },
            { row = 6, column = 5, IconID = 338666, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0饰品|r", saveVariable = "SS_EM_CRSP", section = "插入", defaultState = false },
            { row = 7, column = 1, IconID = 136169, text = "|cffFF7777插入|r", tooltipText = "手动插入吸取生命", saveVariable = "SS_EM_CRXS", section = "插入", defaultState = false },
            { row = 7, column = 3, IconID = 136197, text = "|cffFFF569指向|r", tooltipText = "强制对鼠标指向目标施放一级暗影箭（宏48），施放一次后自动关闭", saveVariable = "SS_EM_CRZXAYJ", defaultState = false },
            { row = 7, column = 4, IconID = 136197, text = "|cffFFF569焦点|r", tooltipText = "强制对焦点目标施放一级暗影箭（宏63），施放一次后自动关闭", saveVariable = "SS_EM_CRJDHAYJ", defaultState = false },
            { row = 7, column = 5, IconID = 132580, text = "|cffFFF569小吃|r", tooltipText = "自动给宠物吃香辣猛犸小吃", saveVariable = "SS_EM_XLMMXC", defaultState = false },
            { row = 8, column = 1, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0放逐奶德|r (CTRL+SHIFT+F11)", saveVariable = "SS_EM_TOC_FANQID", defaultState = false },
            { row = 8, column = 2, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0恐惧牧师|r (ALT+CTRL+SHIFT+F11)", saveVariable = "SS_EM_TOC_JLMS", defaultState = false },
            { row = 8, column = 3, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0恐惧奶萨|r (ALT+CTRL+SHIFT+F10)", saveVariable = "SS_EM_TOC_JLNS", defaultState = false },
            { row = 8, column = 4, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0选盗贼猎人|r (ALT+SHIFT+F10)", saveVariable = "SS_EM_TOC_XJDZLR", defaultState = false },
            { row = 8, column = 5, IconID = 136186, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0火焰之雨|r", saveVariable = "SS_EM_CRHYZY", showSpell = "火焰之雨", section = "插入", defaultState = false },
            { row = 8, column = 6, IconID = 136186, text = "|cff9482C9无脑|r", tooltipText = "无脑|cff00adf0火焰之雨|r,满足条件就自动放(开关常开,不自动关闭)", saveVariable = "SS_EM_WBHYZY", defaultState = false },
            -- ★ 自动切目标开关
            { row = 9, column = 1, IconID = 132293, text = "|cff9482C9切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "SS_EM_TAB", defaultState = true },
        },
    },

    -- ==================== 毁灭专精 ====================
    ["毁灭"] = {
        DM = {
            {
                text = "|cff9482C9防ADD|r",
                menuItems = {
                    { text = "|cff9482C9是|r" },
                    { text = "|cff9482C9否|r" },
                },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_HMS",
                defaultID = 1
            },
            {
                text = "|cff9482C9狂咒|r",
                menuItems = {
                    { text = "|cff9482C9停手|r" },
                    { text = "|cff9482C91层|r" },
                    { text = "|cff9482C92层|r" },
                    { text = "|cff9482C93层|r" },
                    { text = "|cff9482C94层|r" },
                    { text = "|cff9482C95层|r" },
                    { text = "|cff9482C9不停手|r" },
                },
                tooltipText = "中几层|cff00adf0狂咒|r停手",
                saveVariable = "SS_HM_KZ",
                section = "自动",
                defaultID = 1
            },
            {
                text = "|cff9482C9魔甲|r",
                menuItems = {
                    { text = "|cff9482C9邪甲术|r" },
                    { text = "|cff9482C9魔甲术|r" },
                    { text = "|cff9482C9禁用|r" },
                },
                tooltipText = "使用|cff00adf0?甲|",
                saveVariable = "SS_HM_HJ",
                defaultID = 1
            },
            {
                text = "|cff9482C9脱战宠物|r",
                menuItems = {
                    { text = "|cff9482C9关闭|r" },
                    { text = "|cff9482C9小鬼|r" },
                    { text = "|cff9482C9虚空行者|r" },
                    { text = "|cff9482C9魅魔|r" },
                    { text = "|cff9482C9地狱猎犬|r" },
                    { text = "|cff9482C9恶魔卫士|r" },
                },
                tooltipText = "脱战且无宝宝时自动召唤指定宠物（替代原\"召唤小鬼\"复选框，默认小鬼）",
                saveVariable = "SS_HM_AUTOSUMMON",
                defaultID = 2
            },
            {
                text = "|cff9482C9武器石|r",
                menuItems = {
                    { text = "|cff9482C9关闭|r" },
                    { text = "|cff9482C9法术石|r" },
                    { text = "|cff9482C9火焰石|r" },
                },
                tooltipText = "脱战自动武器石：法术石附魔副手，火焰石附魔主手；背包无则自动制造",
                saveVariable = "SS_HM_HRS",
                defaultID = 3
            },
        },
        CB = {
            -- ★ ★ 新增偷药开关（控制自动速度药水和狂野魔法药水的使用）
            { row = 1, column = 1, IconID = 236871, text = "|cff9482C9偷药|r", tooltipText = "开启后，自动药水才会在爆发期使用", saveVariable = "SS_HM_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 2, IconID = 135803, text = "|cff9482C9混沌|r", tooltipText = "是否等灼烧", saveVariable = "SS_HM_HDLX", defaultState = true },
            { row = 1, column = 6, IconID = 237500, text = "|cff9482C9距离|r", tooltipText = "开启|cff00adf0混沌距离提示|r\n暗影灼烧打不到目标时屏幕中央红色大字提醒「距离不够」，进入射程提示立即消失", saveVariable = "SS_HM_HD_TIP", defaultState = false },
            { row = 1, column = 3, IconID = 236302, text = "|cff9482C9自动|r", tooltipText = "是否近战位使用暗影烈焰,不影响移动的近战位猪头喷", saveVariable = "SS_HM_AYLY", defaultState = false },
            { row = 1, column = 4, IconID = 236302, text = "|cff9482C9移动|r", tooltipText = "是否近战位的移动中使用暗影烈焰", saveVariable = "SS_HM_AYLY_MOVE", defaultState = false },
            { row = 1, column = 5, IconID = 236871, text = "|cff9482C9自动|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "SS_HM_ZDSDYS", section = "爆发", defaultState = false },
            { row = 2, column = 1, IconID = 135727, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0种族|r", saveVariable = "SS_HM_ZDZZ", section = "爆发", defaultState = true },
            { row = 2, column = 2, IconID = 338666, text = "|cff9482C9自动|r", tooltipText = "自动|cff00adf0饰品|r", saveVariable = "SS_HM_ZDSP", section = "爆发", defaultState = true },
            { row = 2, column = 3, IconID = 236868, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0狂野魔法|r", saveVariable = "SS_HM_ZDKYMF", defaultState = false },
            { row = 2, column = 4, IconID = 132962, text = "|cff9482C9自动|r", tooltipText = "自动使用|cff00adf0手套|r", saveVariable = "SS_HM_ZDST", section = "爆发", defaultState = true },
            { row = 2, column = 5, IconID = 133712, text = "|cff9482C9自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r", saveVariable = "SS_HM_ZDZD", defaultState = true },
            { row = 3, column = 1, IconID = 136216, text = "|cff9482C9攻击|r", tooltipText = "控制|cff00adf0宠物|r", saveVariable = "SS_HM_KZBB", defaultState = true },
            { row = 3, column = 2, IconID = 136193, text = "|cff9482C9无脑|r", tooltipText = "腐蚀之种|cff00adf0|r", saveVariable = "SS_HM_FSZZ", defaultState = false },
            { row = 3, column = 3, IconID = 136163, text = "|cff9482C9吸片|r", tooltipText = "吸片|cff00adf0宠物|r", saveVariable = "SS_HM_XQLH", defaultState = false },
            { row = 3, column = 4, IconID = 136047, text = "|cff9482C9锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "SS_HM_SUO", defaultState = false },
            { row = 3, column = 5, IconID = 136135, text = "|cff9482C9加尔|r", tooltipText = "如果你的焦点是加尔的小怪(手动设置),自动放逐加尔的小怪,此开关干扰全局判断.不用的时候请禁用", saveVariable = "SS_HM_FZS_ZD", defaultState = false },
            { row = 4, column = 1, IconID = 136201, text = "|cff9482C9插自动|r", tooltipText = "在双燃烧轮使用|cff00adf0暗影之怒|r,请把鼠标指向你要打的怪物", saveVariable = "SS_HM_ZDAYZN", defaultState = true },
            { row = 4, column = 2, IconID = 136219, text = "|cff9482C9自动|r", tooltipText = "自动|cff00adf0地狱火|r", saveVariable = "SS_HM_ZDDYH", defaultState = false },
            { row = 4, column = 3, IconID = 136118, text = "|cff9482C9移动|r", tooltipText = "移动的时候补腐蚀术", saveVariable = "SS_HM_YDFFS", defaultState = false },
            { row = 4, column = 4, IconID = 135817, text = "|cff9482C9焦点|r", tooltipText = "焦点献祭,不建议使用.", saveVariable = "SS_HM_XJ_FOCUS", defaultState = false },
            { row = 4, column = 5, IconID = 136122, text = "|cff9482C9自动|r", tooltipText = "自动BOSS|cff00adf0厄运诅咒|r", saveVariable = "SS_HM_EYZZ", defaultState = true },
            -- ★ 预判循环（循环）开关
            { row = 5, column = 1, IconID = 136216, text = "|cff9482C9循环|r", tooltipText = "开启（默认）使用|cff00adf0预判循环|r（烧尽按爆燃/余烬预判填充）；关闭后暗影箭补到4层、暗影灼烧期间补到6层，再用烧尽填充", saveVariable = "SS_HM_TEXT", defaultState = true },
            { row = 5, column = 2, IconID = 132962, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0手套|r", saveVariable = "SS_HM_CRST", section = "插入", defaultState = false },
            { row = 5, column = 3, IconID = 236868, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0狂野魔法|r", saveVariable = "SS_HM_CRKYMF", section = "插入", defaultState = false },
            { row = 5, column = 4, IconID = 136122, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0厄运诅咒|r", saveVariable = "SS_HM_CREYZZ", section = "插入", defaultState = false },
            { row = 5, column = 5, IconID = 136219, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0地狱火|r", saveVariable = "SS_HM_CRDYH", section = "插入", defaultState = false },
            { row = 6, column = 1, IconID = 237559, text = "|cff9482C9召唤|r", tooltipText = "|cff00adf0召唤|r", saveVariable = "SS_HM_CRZH", defaultState = false },
            { row = 6, column = 2, IconID = 237560, text = "|cff9482C9传送|r", tooltipText = "|cff00adf0传送|r", saveVariable = "SS_HM_CRCS", defaultState = false },
            { row = 6, column = 3, IconID = 135728, text = "|cff9482C9插入||r", tooltipText = "插入|cff00adf0灵魂碎裂|r", saveVariable = "SS_HM_CRLHSL", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 236871, text = "|cff9482C9插入|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "SS_HM_CRSDYS", section = "插入", defaultState = false },
            { row = 6, column = 5, IconID = 135727, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0种族|r", saveVariable = "SS_HM_CRZZ", section = "插入", defaultState = false },
            { row = 7, column = 1, IconID = 338666, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0饰品|r", saveVariable = "SS_HM_CRSP", section = "插入", defaultState = false },
            { row = 7, column = 2, IconID = 136201, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0暗影之怒|r", saveVariable = "SS_HM_CRAYZN", section = "插入", defaultState = false },
            { row = 7, column = 3, IconID = 136186, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0火焰之雨|r", saveVariable = "SS_HM_CRHYZY", showSpell = "火焰之雨", section = "插入", defaultState = false },
            { row = 7, column = 4, IconID = 135818, text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0地狱烈焰|r", saveVariable = "SS_HM_CRDYLY", showSpell = "地狱烈焰", section = "插入", defaultState = false },
            { row = 8, column = 1, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0放逐奶德|r (CTRL+SHIFT+F11)", saveVariable = "SS_HM_TOC_FANQID", defaultState = false },
            { row = 8, column = 2, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0恐惧牧师|r (ALT+CTRL+SHIFT+F11)", saveVariable = "SS_HM_TOC_JLMS", defaultState = false },
            { row = 8, column = 3, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0恐惧奶萨|r (ALT+CTRL+SHIFT+F10)", saveVariable = "SS_HM_TOC_JLNS", defaultState = false },
            { row = 8, column = 4, IconID = 626004, text = "|cffff6666TOC|r", tooltipText = "TOC冠军：一键|cff00adf0选盗贼猎人|r (ALT+SHIFT+F10)", saveVariable = "SS_HM_TOC_XJDZLR", defaultState = false },
            { row = 8, column = 5, IconID = 132580, text = "|cff9482C9小吃|r", tooltipText = "自动给宠物吃香辣猛犸小吃", saveVariable = "SS_HM_XLMMXC", defaultState = false },
            -- ★ 自动切目标开关
            { row = 9, column = 1, IconID = 132293, text = "|cff9482C9切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "SS_HM_TAB", defaultState = true },
            { row = 10, column = 1, IconID = 136216, text = "|cff9482C9测试|r", tooltipText = "测试开关：开启后强制打|cff00adf01+1必爆献祭|r（献祭+燃烧连打），仅用于测试循环，实战请保持关闭", saveVariable = "SS_HM_TEST_11", defaultState = false },
            -- ★ 2026-08-30 ZZ主播打法：手套/种族/饰品对齐混沌流星使用（关闭则按原独立优先级释放）
            { row = 10, column = 2, IconID = 136201, text = "|cff9482C9主播打法|r", tooltipText = "固定主播打法：|cff00adf0手套/种族/饰品|r对齐|cff00adf0混沌流星|r窗口使用；关闭则按原优先级（燃烧buff/预计死亡时间）独立释放", saveVariable = "SS_HM_ZHUBODAFA", section = "爆发", defaultState = true },
            -- 原"召唤小鬼"复选框已迁移为上方 DM 下拉 SS_HM_AUTOSUMMON（默认小鬼，支持五宠物），武器石已迁移为 DM 下拉 SS_HM_HRS，此处不再保留。
        },
    },
}