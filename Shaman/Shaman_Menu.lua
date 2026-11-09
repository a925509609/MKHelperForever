-- ============================================================
-- Shaman_Menu.lua
-- 萨满祭司全专精配置菜单（元素 / 增强 / 恢复）
-- 包含各类自动功能、插入技能、治疗阈值等开关
-- ============================================================

if WR_PlayerClass ~= "SHAMAN" then return end

Shaman_Menu = {
    ["元素"] = {
        DM = {
            {
                text = "|cff0070DE防ADD|r",
                menuItems = {
                    { text = "|cff0070DE是|r" },
                    { text = "|cff0070DE否|r" },
                },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_YSS",
                defaultID = 1
            },
            {
                text = "|cff0070DE狂咒|r",
                menuItems = {
                    { text = "|cff0070DE停手|r" },
                    { text = "|cff0070DE1层|r" },
                    { text = "|cff0070DE2层|r" },
                    { text = "|cff0070DE3层|r" },
                    { text = "|cff0070DE4层|r" },
                    { text = "|cff0070DE5层|r" },
                    { text = "|cff0070DE不停手|r" },
                },
                tooltipText = "中几层|cff00adf0狂咒|r停手",
                saveVariable = "SM_YS_KZ",
                section = "自动",
                defaultID = 1
            },
            {
                text = "|cff0070DE护盾|r",
                menuItems = {
                    { text = "|cff0070DE水盾|r" },
                    { text = "|cff0070DE闪电盾|r" },
                    { text = "|cff0070DE不补盾|r" },
                },
                tooltipText = "|cff00adf0护盾|r选择",
                saveVariable = "SM_YS_HD",
                defaultID = 1
            },
            { text = "|cff0070DE打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "SM_YS_ZDDD" },
        },
        CB = {
            -- ★ ★ 新增偷药开关（控制自动速度药水和狂野魔法药水的使用）
            { row = 1, column = 1, IconID = 236871, text = "|cff0070DE偷药|r", tooltipText = "开启后，自动药水才会在爆发期使用", saveVariable = "SM_YS_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 2, IconID = 236871, text = "|cff0070DE自动|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "SM_YS_ZDSDYS", section = "爆发", defaultState = false },
            { row = 1, column = 3, IconID = 236868, text = "|cff0070DE自动|r", tooltipText = "自动使用|cff00adf0狂野魔法|r", saveVariable = "SM_YS_ZDKYMF", defaultState = false },
            { row = 1, column = 4, IconID = 135727, text = "|cff0070DE自动|r", tooltipText = "自动使用|cff00adf0种族|r", saveVariable = "SM_YS_ZDZZ", section = "爆发", defaultState = true },
            { row = 1, column = 5, IconID = 338666, text = "|cff0070DE自动|r", tooltipText = "自动|cff00adf0饰品|r", saveVariable = "SM_YS_ZDSP", section = "爆发", defaultState = true },
            { row = 2, column = 1, IconID = 132962, text = "|cff0070DE自动|r", tooltipText = "自动使用|cff00adf0手套|r", saveVariable = "SM_YS_ZDST", section = "爆发", defaultState = true },
            { row = 2, column = 2, IconID = 136047, text = "|cff0070DE锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "SM_YS_SUO", defaultState = true },
            { row = 2, column = 3, IconID = 133712, text = "|cff0070DE自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r", saveVariable = "SM_YS_ZDZD", defaultState = true },            { row = 2, column = 5, IconID = 135790, text = "|cff0070DE自动|r", tooltipText = "自动|cff00adf0火元素|r", saveVariable = "SM_YS_ZDHYS", defaultState = true },
            { row = 3, column = 1, IconID = 136115, text = "|cff0070DE自动|r", tooltipText = "自动|cff00adf0元素掌握|r", saveVariable = "SM_YS_ZDYSZW", defaultState = true },
            { row = 3, column = 2, IconID = 310730, text = "|cff0070DE开局|r", tooltipText = "自动开局插一次|cff00adf0元素的召唤|r", saveVariable = "SM_YS_ZDYSDZH", defaultState = true },
            { row = 3, column = 3, IconID = 136015, text = "|cff0070DE自动|r", tooltipText = "多目标再打开|cff00adf0闪电链|r", saveVariable = "SM_YS_ZDSDL", defaultState = false },
            { row = 3, column = 4, IconID = 136075, text = "|cff0070DE自动|r", tooltipText = "可以驱散任何魔法", saveVariable = "SM_YS_ZDQS", defaultState = false },
            { row = 3, column = 5, IconID = 136039, text = "|cff0070DE自动|r", tooltipText = "自动一直释放根基图腾", saveVariable = "SM_YS_GJTT", defaultState = false },
            { row = 4, column = 1, IconID = 135813, text = "|cff0070DE指向|r", tooltipText = "指向开关", saveVariable = "SM_YS_ZXLYZJ", defaultState = false },
            { row = 4, column = 2, IconID = 135813, text = "|cff0070DE焦点|r", tooltipText = "焦点开关", saveVariable = "SM_YS_JDLYZJ", defaultState = false },
            { row = 5, column = 1, IconID = 132962, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0手套|r", saveVariable = "SM_YS_CRST", section = "插入", defaultState = false },
            { row = 5, column = 2, IconID = 136012, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0嗜血|ror|cff00adf0英勇|r", saveVariable = "SM_YS_CRSSYY", section = "爆发", defaultState = false },
            { row = 5, column = 3, IconID = 135790, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0火元素图腾|r", saveVariable = "SM_YS_CRHYSTT", section = "插入", defaultState = false },
            { row = 5, column = 4, IconID = 136024, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0土元素图腾|r", saveVariable = "SM_YS_CRTYSTT", section = "插入", defaultState = false },
            { row = 5, column = 5, IconID = 310730, text = "|cff0070DE插入|r", tooltipText = "|cffFF69B4当没有火元素土元素存在的时候是插入元素的召唤(红色图腾组),\n当火元素存在的时候是插入先祖的召唤(蓝色图腾组),请把蓝色图腾组的火系留空防止盖掉火元素,\n当土元素存在的时候是插入灵魂的召唤(紫色图腾组),请把紫色图腾组的土系留空防止盖掉土元素|r", saveVariable = "SM_YS_CRYSDZH", section = "插入", defaultState = false },
            { row = 6, column = 1, IconID = 236871, text = "|cff0070DE插入|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "SM_YS_CRSDYS", section = "插入", defaultState = false },
            { row = 6, column = 2, IconID = 236868, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0狂野魔法|r", saveVariable = "SM_YS_CRKYMF", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 135727, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0种族|r", saveVariable = "SM_YS_CRZZ", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 338666, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0饰品|r", saveVariable = "SM_YS_CRSP", section = "插入", defaultState = false },
            { row = 6, column = 5, IconID = 136115, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0元素掌握|r", saveVariable = "SM_YS_CRYSZW", section = "插入", defaultState = false },
            { row = 7, column = 1, IconID = 237589, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0雷霆风暴|r", saveVariable = "SM_YS_CRLTFB", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 8, column = 1, IconID = 132293, text = "|cff0070DE切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "SM_YS_TAB", defaultState = true },
        },
    },
    ["增强"] = {
        DM = {
            {
                text = "|cff0070DE防ADD|r",
                menuItems = {
                    { text = "|cff0070DE是|r" },
                    { text = "|cff0070DE否|r" },
                },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_ZQS",
                defaultID = 1
            },
            {
                text = "|cff0070DE寒霜刺骨|r",
                menuItems = {
                    { text = "|cff0070DE5|r" },
                    { text = "|cff0070DE6|r" },
                    { text = "|cff0070DE7|r" },
                    { text = "|cff0070DE8|r" },
                    { text = "|cff0070DE9|r" },
                    { text = "|cff0070DE10|r" },
                    { text = "|cff0070DE禁用|r" },
                },
                tooltipText = "|cff00adf0寒霜刺骨|r层数大于等于设定值，自动停手(|cff00adf0冰龙|r技能)",
                saveVariable = "SM_ZQ_HSCG",
                section = "自动",
                defaultID = 7
            },
            {
                text = "|cff0070DE护盾|r",
                menuItems = {
                    { text = "|cff0070DE水盾|r" },
                    { text = "|cff0070DE闪电盾|r" },
                    { text = "|cff0070DE不补盾|r" },
                },
                tooltipText = "|cff00adf0护盾|r选择",
                saveVariable = "SM_ZQ_HD",
                defaultID = 2
            },
            {
                text = "|cff0070DE漩涡层数|r",
                menuItems = {
                    { text = "|cff0070DE5层|r" },
                    { text = "|cff0070DE4层|r" },
                    { text = "|cff0070DE3层|r" },
                    { text = "|cff0070DE2层|r" },
                },
                tooltipText = "漩涡舞的|cff00adf0漩涡武器层数|r选择,看几层开始判断",
                saveVariable = "SM_ZQ_XWWQCS",
                defaultID = 2
            },
            {
                text = "|cff0070DE调试|r",
                tooltipText = "开启|cff00adf0漩涡终结技调试|r\n每1秒输出当前漩涡层数/终结技档位到聊天框，用于调试循环",
                saveVariable = "SM_ZQ_XWWQCS_DEBUG",
                defaultState = false,
                isCheckBox = true
            },
            {
                text = "|cff0070DE火系图腾|r",
                menuItems = {
                    { text = "|cff0070DE熔岩图腾|r" },
                    { text = "|cff0070DE灼热图腾%|r" },
                    { text = "|cff0070DE不插|r" },
                },
                tooltipText = "一般常驻熔岩.练级可以用用灼热省蓝",
                saveVariable = "SM_ZQ_HXTT",
                defaultID = 1
            },
            {
                text = "|cff0070DE武器附魔|r",
                menuItems = {
                    { text = "|cff0070DE主风|r" },
                    { text = "|cff0070DE主火|r" },
                    { text = "|cff0070DE不补|r" },
                },
                tooltipText = "主手选择,有副手都是火舌",
                saveVariable = "SM_ZQ_WQFM",
                defaultID = 2
            },
            {
                text = "|cff0070DE治疗链|r",
                menuItems = {
                    { text = "|cff0070DE10%|r" },
                    { text = "|cff0070DE20%|r" },
                    { text = "|cff0070DE30%|r" },
                    { text = "|cff0070DE40%|r" },
                    { text = "|cff0070DE50%|r" },
                    { text = "|cff0070DE60%|r" },
                    { text = "|cff0070DE70%|r" },
                    { text = "|cff0070DE80%|r" },
                },
                tooltipText = "|cff00adf0治疗链|r血量设置",
                saveVariable = "SM_ZQ_ZLL_XL",
                defaultID = 8
            },
            { text = "|cff0070DE打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "SM_ZQ_ZDDD" },
        },
        CB = {
            -- ★ ★ 新增偷药开关（控制自动速度药水和狂野魔法药水的使用）
            { row = 1, column = 1, IconID = 236871, text = "|cff0070DE偷药|r", tooltipText = "开启后，自动药水才会在爆发期使用", saveVariable = "SM_ZQ_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 2, IconID = 236871, text = "|cff0070DE自动|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "SM_ZQ_ZDSDYS", section = "爆发", defaultState = false },
            { row = 1, column = 3, IconID = 236868, text = "|cff0070DE自动|r", tooltipText = "自动使用|cff00adf0狂野魔法|r", saveVariable = "SM_ZQ_ZDKYMF", defaultState = false },
            { row = 1, column = 4, IconID = 135727, text = "|cff0070DE自动|r", tooltipText = "自动使用|cff00adf0种族|r", saveVariable = "SM_ZQ_ZDZZ", section = "爆发", defaultState = true },
            { row = 1, column = 5, IconID = 338666, text = "|cff0070DE自动|r", tooltipText = "自动|cff00adf0饰品|r", saveVariable = "SM_ZQ_ZDSP", section = "爆发", defaultState = true },
            { row = 2, column = 1, IconID = 132962, text = "|cff0070DE自动|r", tooltipText = "自动使用|cff00adf0手套|r", saveVariable = "SM_ZQ_ZDST", section = "爆发", defaultState = true },
            { row = 2, column = 2, IconID = 136047, text = "|cff0070DE锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "SM_ZQ_SUO", defaultState = true },
            { row = 2, column = 3, IconID = 133712, text = "|cff0070DE自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r", saveVariable = "SM_ZQ_ZDZD", defaultState = true },            { row = 2, column = 5, IconID = 135790, text = "|cff0070DE自动|r", tooltipText = "自动|cff00adf0火元素|r", saveVariable = "SM_ZQ_ZDHYS", defaultState = true },
            { row = 3, column = 1, IconID = 237577, text = "|cff0070DE自动|r", tooltipText = "自动|cff00adf0野性狼魂|r", saveVariable = "SM_ZQ_YXLH_ZD", defaultState = true },
            { row = 3, column = 2, IconID = 136042, text = "|cff0070DE指向|r", tooltipText = "自动5星|cff00adf0治疗链|r,根据你拉条设置的生命值", saveVariable = "SM_ZQ_ZLL_ZX", defaultState = false },
            { row = 3, column = 3, IconID = 136042, text = "|cff0070DE自己|r", tooltipText = "自动5星|cff00adf0治疗链|r,根据你拉条设置的生命值", saveVariable = "SM_ZQ_ZLL_ZJ", defaultState = false },
            { row = 3, column = 4, IconID = 136015, text = "|cff0070DE自动|r", tooltipText = "自动|cff00adf0闪电链|r,根据你拉条设置的层数", saveVariable = "SM_ZQ_ZDSDL", defaultState = true },
            { row = 3, column = 5, IconID = 136088, text = "|cff0070DE自动|r", tooltipText = "自动|cff00adf0萨满之怒|r", saveVariable = "SM_ZQ_ZDSMZN", defaultState = true },
            { row = 4, column = 1, IconID = 310730, text = "|cff0070DE开局|r", tooltipText = "自动开局插一次|cff00adf0元素的召唤|r,只有你没有插任何图腾的情况下BOSS生效.", saveVariable = "SM_ZQ_ZDYSDZH", defaultState = true },
            { row = 4, column = 2, IconID = 135824, text = "|cff0070DE自动|r", tooltipText = "自动|cff00adf0火焰新星|r", saveVariable = "SM_ZQ_ZDHYXX", defaultState = true },
            { row = 4, column = 3, IconID = 136075, text = "|cff0070DE自动|r", tooltipText = "可以驱散任何魔法", saveVariable = "SM_ZQ_ZDQS", defaultState = false },
            { row = 4, column = 4, IconID = 136039, text = "|cff0070DE自动|r", tooltipText = "自动一直释放根基图腾", saveVariable = "SM_ZQ_GJTT", defaultState = false },
            { row = 5, column = 1, IconID = 136012, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0嗜血|ror|cff00adf0英勇|r", saveVariable = "SM_ZQ_CRSSYY", section = "爆发", defaultState = false },
            { row = 5, column = 2, IconID = 135790, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0火元素图腾|r", saveVariable = "SM_ZQ_CRHYSTT", section = "插入", defaultState = false },
            { row = 5, column = 3, IconID = 136024, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0土元素图腾|r", saveVariable = "SM_ZQ_CRTYSTT", section = "插入", defaultState = false },
            { row = 5, column = 4, IconID = 136088, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0萨满之怒|r", saveVariable = "SM_ZQ_CRSMZN", section = "插入", defaultState = false },
            { row = 5, column = 5, IconID = 310730, text = "|cff0070DE插入|r", tooltipText = "|cffFF69B4当没有火元素土元素存在的时候是插入元素的召唤(红色图腾组),\n当火元素存在的时候是插入先祖的召唤(蓝色图腾组),请把蓝色图腾组的火系留空防止盖掉火元素,\n当土元素存在的时候是插入灵魂的召唤(紫色图腾组),请把紫色图腾组的土系留空防止盖掉土元素|r,", saveVariable = "SM_ZQ_CRYSDZH", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 6, column = 1, IconID = 132293, text = "|cff0070DE切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "SM_ZQ_TAB", defaultState = false },
        },
    },
    ["恢复"] = {
        DM = {
            {
                text = "|cff0070DE驱散|r",
                menuItems = {
                    { text = "|cff0070DE常规|r" },
                    { text = "|cff0070DE优先|r" },
                    { text = "|cff0070DE目标|r" },
                    { text = "|cff0070DE指向|r" },
                    { text = "|cff0070DE禁用|r" },
                },
                tooltipText = "|cff00adf0常规：驱散所有Debuff。|r\n|cffffdf00优先：驱散所有Debuff(高优先级)。\n|cffadff2f目标：仅驱散当前目标的Debuff。|r\n|cff9bf6ff指向：仅驱散指向队友的Debuff。|r",
                saveVariable = "HF_QS",
                defaultID = 1
            },
            {
                text = "|cff0070DE大地之盾|r",
                menuItems = {
                    { text = "", },
                    { text = "", },
                    { text = "", },
                    { text = "", },
                    { text = "|cff0070DE禁用|r", },
                },
                tooltipText = "选择|cff00adf0大地之盾|r的|cff996b1f坦克|r。\n注：当队伍中有|cff996b1f坦克|r的时候，选项才会显示(|cff00ADF0请让团长设置职责|r)。\n注：当队伍|cff996b1f坦克|r变动，选项也会变动，请注意及时调整。",
                saveVariable = "HF_DDZD",
                defaultID = 1
            },
            {
                text = "|cff0070DE治疗模式|r",
                menuItems = {
                    { text = "|cff0070DE自动|r" },
                    { text = "|cff0070DE坦克|r" },
                    { text = "|cff0070DE脆皮|r" },
                    { text = "|cff0070DE目标|r" },
                },
                tooltipText = "|cff00adf0自动：治疗所有单位(可应对大部分情况)|r\n|cff996b1f坦克：仅治疗坦克，需要团长设置\"坦克\"职责|r\n|cff9C3590脆皮：排除坦克，治疗其他职业，需要团长设置\"坦克\"职责|r\n|cffffd700目标：仅治疗当前目标，无目标则|cff00adf0 自动 |r|cffffd700",
                saveVariable = "HF_ZLMS",
                defaultID = 1
            },
            -- ★ 过量停条窗口（0.1~0.5秒，默认0.5秒）
            {
                text = "|cff0070DE过量停条|r",
                menuItems = {
                    { text = "|cff0070DE0.1秒|r" },
                    { text = "|cff0070DE0.2秒|r" },
                    { text = "|cff0070DE0.3秒|r" },
                    { text = "|cff0070DE0.4秒|r" },
                    { text = "|cff0070DE0.5秒|r" },
                },
                tooltipText = "设置过量停条的检查窗口。施法剩余时间≤此值时检查目标血量，满血则停止施法避免过量。\n|cffff5040需配合下方「过量停条」开关使用，开关默认关闭。|r",
                saveVariable = "HF_GLTCCK",
                defaultID = 5
            },
            {
                text = "|cff0070DE自然迅捷|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 35,
                tooltipText = "当目标血量低于设定值的时候，使用|cff00adf0自然迅捷|r。\n|cffff5040值为0：不使用。|r",
                saveVariable = "HF_ZRXJ",
            },
            {
                text = "|cff0070DE激流|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 80,
                tooltipText = "当目标血量低于设定值的时候，使用|cff00adf0激流|r。\n|cffff5040值为0：不使用。|r",
                saveVariable = "HF_JL",
            },
            {
                text = "|cff0070DE治疗链|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 100,
                tooltipText = "当目标血量低于设定值的时候，使用|cff00adf0治疗链|r。\n|cffff5040值为0：不使用。|r",
                saveVariable = "HF_ZLL",
            },
            {
                text = "|cff0070DE潮汐之力|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 50,
                tooltipText = "当目标血量低于设定值的时候，使用|cff00adf0潮汐之力|r。\n|cffff5040值为0：不使用。开到100是无脑治疗链|r",
                saveVariable = "HF_CXZL",
            },
            {
                text = "|cff0070DE次级治疗波|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 0,
                tooltipText = "当目标血量低于设定值的时候，使用|cff00adf0次级治疗波|r。\n|cffff5040值为0：不使用。|r",
                saveVariable = "HF_CJZLB",
            },
            {
                text = "|cff0070DE治疗波|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 60,
                tooltipText = "当目标血量低于设定值的时候，使用|cff00adf0治疗波|r。\n|cffff5040值为0：不使用。|r",
                saveVariable = "HF_ZLB",
            },
            {
                text = "|cff0070DE法力之潮|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 40,
                tooltipText = "当自身蓝量低于设定值的时候，使用|cff00adf0法力之潮图腾|r。\n|cffff5040值为0：不使用。|r",
                saveVariable = "HF_FLZCTT",
            },
            { text = "|cff0070DE打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "HF_ZDDD" },
        },
        CB = {
            -- ★ ★ 新增偷药开关（恢复萨爆发期药水控制）
            { row = 1, column = 1, IconID = 236871, text = "|cff0070DE偷药|r", tooltipText = "开启后，自动药水才会在爆发期使用", saveVariable = "SM_HF_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 2, IconID = 310730, text = "", tooltipText = "当图腾消失，使用|cff00adf0元素的召唤|r\n请将需要的图腾预设在|cff00adf0元素的召唤|r", saveVariable = "HF_TT", defaultState = true },
            { row = 1, column = 3, IconID = 135230, text = "", tooltipText = "血量危险时，使用|cff00adf0治疗石|r", saveVariable = "HF_ZLS", defaultState = true },
            { row = 1, column = 4, IconID = 135737, text = "|cff0070DE狂咒|r", tooltipText = "中|cff00adf0狂咒|r后停手(|cff00adf0辛达苟萨|r)", saveVariable = "HF_KZ", defaultState = true },
            { row = 1, column = 5, IconID = 135727, text = "|cff0070DE爆发|r", tooltipText = "开启|cff00adf0爆发模式|r，使用|cff00adf0手套附魔|r、|cff00adf0速度药水|r、|cff00adf0饰品|r及|cff00adf0潮汐之力|r", saveVariable = "HF_BF", section = "爆发", defaultState = false },
            { row = 2, column = 1, IconID = 136012, text = "|cff0070DE插入|r", tooltipText = "插入|cff00adf0嗜血|ror|cff00adf0英勇|r", saveVariable = "SM_HF_CRSXYY", section = "爆发", defaultState = false },
            { row = 2, column = 2, IconID = 136040, text = "|cff0070DE进攻驱散|r", tooltipText = "开启后，优先对|cff00adf0焦点|r、其次对当前敌方目标自动使用|cff00adf0净化术|r驱散其魔法增益（仅射程内，保留当前目标作为治疗目标）。", saveVariable = "HF_JHQS", defaultState = false },
            -- ★ 第2行第3列：过量停条开关（默认关闭）
            { row = 2, column = 3, IconID = 135737, text = "|cff0070DE过量停条|r", tooltipText = "开启后，施法结束前(按停条窗口设定)目标已满血时自动停止施法，避免过量治疗。\n|cffff5040首领机制(狂咒/血肉成灰等)与特殊治疗模式不受此开关影响，始终生效。|r", saveVariable = "HF_GLTC", defaultState = false },
            { row = 2, column = 4, IconID = 135894, text = "|cff0070DE总闸|r", tooltipText = "勾选后，关闭恢复萨自动|cff00adf0净化灵魂|r（常规驱散），优先级高于下拉选项。", saveVariable = "HF_QS_AUTO", defaultState = false },
            { row = 2, column = 5, IconID = 136040, text = "|cff0070DE进攻总闸|r", tooltipText = "勾选后，关闭恢复萨自动|cff00adf0净化术|r（进攻驱散），优先级高于分项开关。", saveVariable = "HF_JHQS_AUTO", defaultState = false },        },
    },
}