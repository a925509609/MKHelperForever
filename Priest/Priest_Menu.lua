-- ============================================================
-- Priest_Menu.lua
-- 牧师全专精配置菜单（戒律 / 神圣 / 暗影）
-- 包含各类自动功能、治疗阈值、驱散模式、爆发等开关
--   2026-08-15 戒律专精新增神圣赞美诗 (JL_SMZS)、焦点补盾 (JL_JDSD) 复选框
--   2026-08-15 戒律新增插入神圣赞美诗 (JL_CRSSZMS)、插入希望圣歌 (JL_CRXWSG) 复选框
-- ============================================================

if WR_PlayerClass ~= "PRIEST" then return end

Priest_Menu = {
    ["戒律"] = {
        DM = {
            {
                text = "|cffFFFFFF驱散|r",
                menuItems = {
                    { text = "|cffFFFFFF常规|r" },
                    { text = "|cffFFFFFF优先|r" },
                    { text = "|cffFFFFFF目标|r" },
                    { text = "|cffFFFFFF指向|r" },
                    { text = "|cffFFFFFF禁用|r" },
                },
                tooltipText = "|cff00adf0常规：驱散所有Debuff。|r\n|cffffdf00优先：驱散所有Debuff(高优先级)。\n|cffadff2f目标：仅驱散当前目标的Debuff。|r\n|cff9bf6ff指向：仅驱散指向队友的Debuff。|r",
                saveVariable = "JL_QS",
                defaultID = 2
            },
            {
                text = "|cffFFFFFF真言术盾|r",
                menuItems = {
                    { text = "|cffFFFFFF10%|r" },
                    { text = "|cffFFFFFF20%|r" },
                    { text = "|cffFFFFFF30%|r" },
                    { text = "|cffFFFFFF40%|r" },
                    { text = "|cffFFFFFF50%|r" },
                    { text = "|cffFFFFFF60%|r" },
                    { text = "|cffFFFFFF70%|r" },
                    { text = "|cffFFFFFF80%|r" },
                    { text = "|cffFFFFFF90%|r" },
                    { text = "|cffFFFFFF91%|r" },
                    { text = "|cffFFFFFF92%|r" },
                    { text = "|cffFFFFFF93%|r" },
                    { text = "|cffFFFFFF94%|r" },
                    { text = "|cffFFFFFF95%|r" },
                    { text = "|cffFFFFFF96%|r" },
                    { text = "|cffFFFFFF97%|r" },
                    { text = "|cffFFFFFF98%|r" },
                    { text = "|cffFFFFFF99%|r" },
                    { text = "|cffFFFFFF积极|r" },
                    { text = "|cffFFFFFF禁用|r" },
                },
                tooltipText = "当友方血量低于设定值，对其使用|cff00adf0真言术盾|r\n|cffE80060积极：任何时候都积极使用|cff00adf0真言术盾|r|r\n|cffff5040禁用：完全不使用|cff00adf0真言术盾|r|r\n|cffFF7D0A1-5或5-1：按照选择的队伍循序全团套盾|r",
                saveVariable = "JL_ZYSD",
                defaultID = 8
            },
            {
                text = "|cffFFFFFF盾的等级|r",
                menuItems = {
                    { text = "|cffFFFFFF满级|r" },
                    { text = "|cffFFFFFF13|r" },
                    { text = "|cffFFFFFF12|r" },
                    { text = "|cffFFFFFF11|r" },
                },
                tooltipText = "选择|cff00ADF0真言术：盾|r的等级\n如无特殊情况，选择|cff00ADF0满级|r即可",
                saveVariable = "JL_DDDJ",
                defaultID = 1
            },
            {
                text = "|cffFFFFFF团盾顺序|r",
                menuItems = {
                    { text = "|cffFFFFFF正序|r" },
                    { text = "|cffFFFFFF倒序|r" },
                },
                tooltipText = "选择对|cff00adf0全团套盾|r的顺序。",
                saveVariable = "JL_TDSX",
                defaultID = 1
            },
            {
                text = "|cffFFFFFF治疗模式|r",
                menuItems = {
                    { text = "|cffFFFFFF自动|r" },
                    { text = "|cffFFFFFF坦克|r" },
                    { text = "|cffFFFFFF脆皮|r" },
                    { text = "|cffFFFFFF目标|r" },
                },
                tooltipText = "|cff00adf0自动：治疗所有单位(可应对大部分情况)|r\n|cff996b1f坦克：仅治疗坦克，需要团长设置\"坦克\"职责|r\n|cff9C3590脆皮：排除坦克，治疗其他职业，需要团长设置\"坦克\"职责|r\n|cffffd700目标：仅治疗当前目标，无目标则|cff00adf0 自动 |r|cffffd700",
                saveVariable = "JL_ZLMS",
                defaultID = 1
            },
            -- ★ 过量停条窗口（0.1~0.5秒，默认0.5秒）
            {
                text = "|cffFFFFFF过量停条|r",
                menuItems = {
                    { text = "|cffFFFFFF0.1秒|r" },
                    { text = "|cffFFFFFF0.2秒|r" },
                    { text = "|cffFFFFFF0.3秒|r" },
                    { text = "|cffFFFFFF0.4秒|r" },
                    { text = "|cffFFFFFF0.5秒|r" },
                },
                tooltipText = "设置过量停条的检查窗口。施法剩余时间≤此值时检查目标血量，满血则停止施法避免过量。\n|cffff5040需配合下方「过量停条」开关使用，开关默认关闭。|r",
                saveVariable = "JL_GLTCCK",
                defaultID = 5
            },
        },
        CB = {
            { row = 1, column = 1, IconID = 135987, text = "", tooltipText = "使用|cff00adf0真言术：韧|r", saveVariable = "JL_ZYSR", defaultState = true },
            { row = 1, column = 2, IconID = 135898, text = "", tooltipText = "使用|cff00adf0神圣之灵|r", saveVariable = "JL_SSZL", defaultState = true },
            { row = 1, column = 3, IconID = 136121, text = "", tooltipText = "使用|cff00adf0暗影防护|r", saveVariable = "JL_AYFH", defaultState = true },
            { row = 1, column = 4, IconID = 133750, text = "", tooltipText = "消耗|cff00adf0虔诚蜡烛|r(|cff00adf0大BUFF|r)", saveVariable = "JL_QCLZ", defaultState = true },
            { row = 1, column = 5, IconID = 135943, text = "", tooltipText = "使用|cff00adf0治疗祷言|r", saveVariable = "JL_ZLDY", defaultState = true },
            { row = 2, column = 1, IconID = 135944, text = "", tooltipText = "使用|cff00adf0愈合祷言|r", saveVariable = "JL_YHDY", defaultState = true },
            { row = 2, column = 2, IconID = 135907, text = "", tooltipText = "使用|cff00adf0快速治疗|r及|cff00adf0联结治疗|r", saveVariable = "JL_ZL", defaultState = true },
            { row = 2, column = 3, IconID = 135953, text = "", tooltipText = "使用|cff00adf0恢复|r", saveVariable = "JL_HF", defaultState = true },
            { row = 2, column = 4, IconID = 135936, text = "", tooltipText = "队友血量过低时，使用|cff00adf0痛苦压制|r", saveVariable = "JL_TKYZ", defaultState = true },
            { row = 2, column = 5, IconID = 135954, text = "", tooltipText = "自身血量过低时，使用|cff00adf0绝望祷言|r", saveVariable = "JL_JWDY", defaultState = true },
            { row = 3, column = 1, IconID = 135230, text = "", tooltipText = "血量过低使用|cff00adf0治疗石|r。", saveVariable = "JL_ZLS", defaultState = true },
            { row = 3, column = 2, IconID = 135737, text = "|cffFFFFFF狂咒|r", tooltipText = "中|cff00adf0狂咒|r后停手(|cff00adf0辛达苟萨|r)", saveVariable = "JL_KZ", defaultState = true },
            { row = 3, column = 3, IconID = 135940, text = "|cffFFFFFF全团|r", tooltipText = "勾选后，开始|cff00adf0全团套盾|r", saveVariable = "JL_QTTD", defaultState = false },
            { row = 3, column = 4, IconID = 136012, text = "|cffFFFFFF爆发|r", tooltipText = "开启|cff00adf0爆发模式|r，使用|cff00adf0手套附魔|r、|cff00adf0速度药水|r、|cff00adf0饰品|r、|cff00adf0能量灌注|r及|cff00adf0暗影魔|r。", saveVariable = "JL_BF", section = "爆发", defaultState = false },
            { row = 4, column = 1, IconID = 135944, text = "|cffFFFFFF目标祷言|r", tooltipText = "有选目标时，满足血量条件(|cff00adf0≤80%|r)优先将|cff00adf0愈合祷言|r扔给目标，然后才是坦克。", saveVariable = "JL_YHDY_TARGET", defaultState = false },
            { row = 4, column = 2, IconID = 236871, text = "|cffFFFFFF偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "JL_TOUYAO", section = "爆发", defaultState = false },
            -- ★ 第4行第3列：过量停条开关（默认关闭）
            { row = 4, column = 3, IconID = 135737, text = "|cffFFFFFF过量停条|r", tooltipText = "开启后，施法结束前(按停条窗口设定)目标已满血时自动停止施法，避免过量治疗。\n|cffff5040首领机制(狂咒/血肉成灰等)与特殊治疗模式不受此开关影响，始终生效。|r", saveVariable = "JL_GLTC", defaultState = false },
            { row = 4, column = 4, IconID = 135941, text = "|cffFFFFFF群体驱散|r", tooltipText = "当队友身上有|cff00adf0魔法|r类减益时，在光标处插入|cff00adf0群体驱散|r（点一下放一次）", saveVariable = "JL_QTQS", defaultState = true },
            { row = 4, column = 5, IconID = 135894, text = "|cffFFFFFF总闸|r", tooltipText = "勾选后，关闭戒律牧所有自动驱散（常规/进攻/群体），优先级高于各分项开关。\n用于紧急情况一键停手，不依赖下拉的禁用选项。", saveVariable = "JL_QS_AUTO", defaultState = false },
            -- ★ 神圣赞美诗（团血低团刷）
            { row = 5, column = 1, IconID = 237540, text = "|cffFFFFFF赞美诗|r", tooltipText = "团血低时自动|cff00adf0神圣赞美诗|r团刷救场（团队≥4人或小队≥2人血量≤50%时触发）", saveVariable = "JL_SMZS", defaultState = false },
            -- ★ 焦点补盾
            { row = 5, column = 2, IconID = 135940, text = "|cffFFFFFF焦点盾|r", tooltipText = "给|cff00adf0焦点|r目标持续补|cff00adf0真言术：盾|r（焦点无盾且非虚弱灵魂时）", saveVariable = "JL_JDSD", defaultState = false },
            -- ★ 插入神圣赞美诗（释放后自动关开关）
            { row = 5, column = 3, IconID = 237540, text = "|cffFFFFFF插入|r", tooltipText = "插入|cff00adf0神圣赞美诗|r（释放后自动关闭开关）", saveVariable = "JL_CRSSZMS", section = "插入", defaultState = false },
            -- ★ 插入希望圣歌（释放后自动关开关）
            { row = 5, column = 4, IconID = 135982, text = "|cffFFFFFF插入|r", tooltipText = "插入|cff00adf0希望圣歌|r（释放后自动关闭开关）", saveVariable = "JL_CRXWSG", section = "插入", defaultState = false },
            -- ★ 坦克盾独立开关
            { row = 5, column = 5, IconID = 135940, text = "|cffFFFFFF坦克盾|r", tooltipText = "开启后给|cff00adf0坦克|r持续套|cff00adf0真言术：盾|r；关闭则不覆盖坦克（由常规盾逻辑排除）", saveVariable = "JL_TKZD", defaultState = true },
            -- ★ 指向痛苦压制（鼠标指向，无条件）
            { row = 6, column = 1, IconID = 135936, text = "|cffFFFFFF指向压制|r", tooltipText = "勾选后，对|cff00adf0鼠标指向|r的友方队友|cff00adf0无条件|r施放|cff00adf0痛苦压制|r（无需血量阈值，开关开启且指向友方即在射程内即释放）", saveVariable = "JL_TKYZ_MOUSEOVER", defaultState = false },
        },
    },
    ["神圣"] = {
        DM = {
            {
                text = "|cffFFFFFF驱散|r",
                menuItems = {
                    { text = "|cffFFFFFF常规|r" },
                    { text = "|cffFFFFFF优先|r" },
                    { text = "|cffFFFFFF目标|r" },
                    { text = "|cffFFFFFF指向|r" },
                    { text = "|cffFFFFFF禁用|r" },
                },
                tooltipText = "|cff00adf0常规：驱散所有Debuff。|r\n|cffffdf00优先：驱散所有Debuff(高优先级)。\n|cffadff2f目标：仅驱散当前目标的Debuff。|r\n|cff9bf6ff指向：仅驱散指向队友的Debuff。|r",
                saveVariable = "SS_QS",
                defaultID = 2
            },
            {
                text = "|cffFFFFFF恢复|r",
                menuItems = {
                    { text = "|cffFFFFFF10%|r" },
                    { text = "|cffFFFFFF20%|r" },
                    { text = "|cffFFFFFF30%|r" },
                    { text = "|cffFFFFFF40%|r" },
                    { text = "|cffFFFFFF50%|r" },
                    { text = "|cffFFFFFF60%|r" },
                    { text = "|cffFFFFFF70%|r" },
                    { text = "|cffFFFFFF80%|r" },
                    { text = "|cffFFFFFF90%|r" },
                    { text = "|cffFFFFFF91%|r" },
                    { text = "|cffFFFFFF92%|r" },
                    { text = "|cffFFFFFF93%|r" },
                    { text = "|cffFFFFFF94%|r" },
                    { text = "|cffFFFFFF95%|r" },
                    { text = "|cffFFFFFF96%|r" },
                    { text = "|cffFFFFFF97%|r" },
                    { text = "|cffFFFFFF98%|r" },
                    { text = "|cffFFFFFF99%|r" },
                    { text = "|cffFFFFFF禁用|r" },
                },
                tooltipText = "当血量低于设定值的时候，使用|cff00adf0恢复|r。",
                saveVariable = "SS_HF",
                defaultID = 9
            },
            {
                text = "|cffFFFFFF过量治疗|r",
                menuItems = {
                    { text = "|cffFFFFFF10%|r" },
                    { text = "|cffFFFFFF20%|r" },
                    { text = "|cffFFFFFF30%|r" },
                    { text = "|cffFFFFFF40%|r" },
                    { text = "|cffFFFFFF50%|r" },
                    { text = "|cffFFFFFF60%|r" },
                    { text = "|cffFFFFFF70%|r" },
                    { text = "|cffFFFFFF80%|r" },
                    { text = "|cffFFFFFF90%|r" },
                },
                tooltipText = "设置允许过量治疗的比例",
                saveVariable = "SS_YXGL",
                defaultID = 3
            },
            {
                text = "|cffFFFFFF治疗模式|r",
                menuItems = {
                    { text = "|cffFFFFFF自动|r" },
                    { text = "|cffFFFFFF坦克|r" },
                    { text = "|cffFFFFFF脆皮|r" },
                    { text = "|cffFFFFFF目标|r" },
                },
                tooltipText = "|cff00adf0自动：治疗所有单位(可应对大部分情况)|r\n|cff996b1f坦克：仅治疗坦克，需要团长设置\"坦克\"职责|r\n|cff9C3590脆皮：排除坦克，治疗其他职业，需要团长设置\"坦克\"职责|r\n|cffffd700目标：仅治疗当前目标，无目标则|cff00adf0 自动 |r|cffffd700",
                saveVariable = "SS_ZLMS",
                defaultID = 1
            },
            -- ★ 过量停条窗口（0.1~0.5秒，默认0.5秒）
            {
                text = "|cffFFFFFF过量停条|r",
                menuItems = {
                    { text = "|cffFFFFFF0.1秒|r" },
                    { text = "|cffFFFFFF0.2秒|r" },
                    { text = "|cffFFFFFF0.3秒|r" },
                    { text = "|cffFFFFFF0.4秒|r" },
                    { text = "|cffFFFFFF0.5秒|r" },
                },
                tooltipText = "设置过量停条的检查窗口。施法剩余时间≤此值时检查目标血量，满血则停止施法避免过量。\n|cffff5040需配合下方「过量停条」开关使用，开关默认关闭。|r",
                saveVariable = "SS_GLTCCK",
                defaultID = 5
            },
        },
        CB = {
            { row = 1, column = 1, IconID = 135987, text = "", tooltipText = "使用|cff00adf0真言术：韧|r", saveVariable = "SS_ZYSR", defaultState = true },
            { row = 1, column = 2, IconID = 135898, text = "", tooltipText = "使用|cff00adf0神圣之灵|r", saveVariable = "SS_SSZL", defaultState = true },
            { row = 1, column = 3, IconID = 136121, text = "", tooltipText = "使用|cff00adf0暗影防护|r", saveVariable = "SS_AYFH", defaultState = true },
            { row = 1, column = 4, IconID = 133750, text = "", tooltipText = "消耗|cff00adf0虔诚蜡烛|r(|cff00adf0大BUFF|r)", saveVariable = "SS_QCLZ", defaultState = true },
            { row = 1, column = 5, IconID = 237542, text = "", tooltipText = "队友血量过低时，使用|cff00adf0守护之魂|r", saveVariable = "SS_SHZH", defaultState = true },
            { row = 2, column = 1, IconID = 135954, text = "", tooltipText = "自身血量过低时，使用|cff00adf0绝望祷言|r", saveVariable = "SS_JWDY", defaultState = true },
            { row = 2, column = 2, IconID = 135230, text = "", tooltipText = "血量过低使用|cff00adf0治疗石|r。", saveVariable = "SS_ZLS", defaultState = true },
            { row = 2, column = 3, IconID = 135907, text = "", tooltipText = "使用|cff00adf0快速治疗|r、|cff00adf0联结治疗|r和|cff00adf0强效治疗术|r。\n此选项并不会影响|cff00adf0圣光涌动|r触发的|cff00adf0免费快疗|r", saveVariable = "SS_ZL", defaultState = true },
            { row = 2, column = 4, IconID = 135943, text = "", tooltipText = "使用|cff00adf0治疗祷言|r。", saveVariable = "SS_ZLDY", defaultState = true },
            { row = 2, column = 5, IconID = 135737, text = "|cffFFFFFF狂咒|r", tooltipText = "中|cff00adf0狂咒|r后停手(|cff00adf0辛达苟萨|r)", saveVariable = "SS_KZ", defaultState = true },
            { row = 3, column = 1, IconID = 136012, text = "|cffFFFFFF爆发|r", tooltipText = "开启|cff00adf0爆发模式|r，使用|cff00adf0手套附魔|r、|cff00adf0速度药水|r、|cff00adf0饰品|r及|cff00adf0暗影魔|r。", saveVariable = "SS_BF", section = "爆发", defaultState = false },
            { row = 3, column = 2, IconID = 236871, text = "|cffFFFFFF偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "SS_TOUYAO", section = "爆发", defaultState = false },
            -- ★ 第3行第3列：过量停条开关（默认关闭）
            { row = 3, column = 3, IconID = 135737, text = "|cffFFFFFF过量停条|r", tooltipText = "开启后，施法结束前(按停条窗口设定)目标已满血时自动停止施法，避免过量治疗。\n|cffff5040首领机制(狂咒/血肉成灰等)与特殊治疗模式不受此开关影响，始终生效。|r", saveVariable = "SS_GLTC", defaultState = false },
            -- ★ 治疗职业自动救人已统一上提到主面板左侧「全局区」，此处不再重复
        },
    },
    ["暗影"] = {
        DM = {
            -- ★ ZZ 移植：精神鞭笞打断阈值 8 档
            {
                text = "|cffFFFFFF鞭笞阈值|r",
                menuItems = {
                    { text = "|cffFFFFFF1|r" }, { text = "|cffFFFFFF2|r" }, { text = "|cffFFFFFF3|r" },
                    { text = "|cffFFFFFF4|r" }, { text = "|cffFFFFFF5|r" }, { text = "|cffFFFFFF6|r" },
                    { text = "|cffFFFFFF7|r" }, { text = "|cffFFFFFF8|r" },
                },
                tooltipText = "ZZ 移植：精神鞭笞打断阈值档位\n1=0.05s / 2=0.075s / 3=0.1s / 4=0.125s / 5=0.10s / 6=0.175s / 7=0.2s / 8=0s\n值越小越晚打断（吃满引导）",
                saveVariable = "MS_AY_JSBCTIME",
                defaultID = 4,
            },
            {
                text = "|cffFFFFFF防ADD|r",
                menuItems = {
                    { text = "|cffFFFFFF是|r" },
                    { text = "|cffFFFFFF否|r" },
                },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_AM",
                defaultID = 1
            },
            {
                text = "|cffFFFFFF狂咒|r",
                menuItems = {
                    { text = "|cffFFFFFF停手|r" },
                    { text = "|cffFFFFFF1层|r" },
                    { text = "|cffFFFFFF2层|r" },
                    { text = "|cffFFFFFF3层|r" },
                    { text = "|cffFFFFFF4层|r" },
                    { text = "|cffFFFFFF5层|r" },
                    { text = "|cffFFFFFF不停手|r" },
                },
                tooltipText = "中几层|cff00adf0狂咒|r停手",
                saveVariable = "MS_AY_KZ",
                section = "自动",
                defaultID = 1
            },
        },
        CB = {
            { row = 1, column = 1, IconID = 135978, text = "|cffFFFFFF全局|r", tooltipText = "全局自动上|cff00adf0吸血鬼之触|r", saveVariable = "MS_AY_QJXXGZC", defaultState = false },
            { row = 1, column = 2, IconID = 136207, text = "|cffFFFFFF全局|r", tooltipText = "全局自动上|cff00adf0痛|r", saveVariable = "MS_AY_QJTONG", defaultState = false },
            { row = 1, column = 3, IconID = 135894, text = "|cffFFFFFF全局|r", tooltipText = "驱散队友任何可以驱散的debuff", saveVariable = "MS_AY_QJQS", defaultState = false },
            { row = 2, column = 1, IconID = 236871, text = "|cffFFFFFF自动|r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "MS_AY_ZDSDYS", section = "爆发", defaultState = false },
            { row = 2, column = 2, IconID = 236868, text = "|cffFFFFFF自动|r", tooltipText = "自动使用|cff00adf0狂野魔法|r", saveVariable = "MS_AY_ZDKYMF", defaultState = false },
            { row = 2, column = 3, IconID = 135727, text = "|cffFFFFFF自动|r", tooltipText = "自动使用|cff00adf0种族|r", saveVariable = "MS_AY_ZDZZ", section = "爆发", defaultState = true },
            { row = 2, column = 4, IconID = 338666, text = "|cffFFFFFF自动|r", tooltipText = "自动|cff00adf0饰品|r", saveVariable = "MS_AY_ZDSP", section = "爆发", defaultState = true },
            { row = 2, column = 5, IconID = 132962, text = "|cffFFFFFF自动|r", tooltipText = "自动使用|cff00adf0手套|r", saveVariable = "MS_AY_ZDST", section = "爆发", defaultState = true },
            { row = 3, column = 1, IconID = 136047, text = "|cffFFFFFF锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "MS_AY_SUO", defaultState = true },
            { row = 3, column = 2, IconID = 237565, text = "|cffFFFFFFAOE|r", tooltipText = "打开开关不停精神灼烧\n", saveVariable = "MS_AY_JSZS", defaultState = false },
            { row = 3, column = 3, IconID = 136199, text = "|cffFFFFFF起手|r", tooltipText = "起手暗影魔\n", saveVariable = "MS_AY_AYMQS", defaultState = false },
            { row = 3, column = 4, IconID = 135978, text = "|cffFFFFFF焦点|r", tooltipText = "焦点触功能\n", saveVariable = "MS_AY_XXGZC_JD", defaultState = true },
            { row = 3, column = 5, IconID = 136207, text = "|cffFFFFFF焦点|r", tooltipText = "焦点痛功能\n", saveVariable = "MS_AY_TONG_JD", defaultState = true },
            { row = 4, column = 1, IconID = 136208, text = "|cffFFFFFF焦点|r", tooltipText = "精神鞭笞续焦点痛功能\n", saveVariable = "MS_AY_JXBC_JD_XU", defaultState = true },
            { row = 4, column = 2, IconID = 136075, text = "|cffFFFFFF目标|r", tooltipText = "可以驱散目标任何魔法", saveVariable = "MS_AY_ZDQS", defaultState = false },
            { row = 4, column = 3, IconID = 135978, text = "|cffFFFFFF指向|r", tooltipText = "指向触功能\n", saveVariable = "MS_AY_XXGZC_ZX", defaultState = true },
            { row = 4, column = 4, IconID = 136207, text = "|cffFFFFFF指向|r", tooltipText = "指向痛功能\n", saveVariable = "MS_AY_TONG_ZX", defaultState = true },
            { row = 4, column = 5, IconID = 136208, text = "|cffFFFFFF指向|r", tooltipText = "精神鞭笞续指向痛功能\n", saveVariable = "MS_AY_JXBC_ZX_XU", defaultState = true },
            { row = 5, column = 1, IconID = 237563, text = "|cffFFFFFF自动|r", tooltipText = "规避各种技能\n", saveVariable = "MS_AY_ZDXS", defaultState = true },
            { row = 5, column = 2, IconID = 136149, text = "|cffFFFFFF移动|r", tooltipText = "移动打灭\n", saveVariable = "MS_AY_YDMIE", defaultState = true },
            { row = 5, column = 3, IconID = 133712, text = "|cffFFFFFF自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r", saveVariable = "MS_AY_ZDZD", defaultState = true },
            { row = 5, column = 4, IconID = 135894, text = "|cffFFFFFF自己|r", tooltipText = "驱散自己任何可以驱散的debuff", saveVariable = "MS_AY_QS_P", defaultState = false },
            { row = 5, column = 5, IconID = 237570, text = "|cffFFFFFF自动|r", tooltipText = "是否施自动释放渊", saveVariable = "MS_AY_AYSY", defaultState = true },
            -- ★ ZZ 移植：渊 BOSS 限定开关
            { row = 8, column = 3, IconID = 237570, text = "|cffFFFFFF渊BOSS|r", tooltipText = "ZZ 移植：开启后|cff00adf0暗言术：渊|r仅对 BOSS 生效；关闭则全目标可用", saveVariable = "MS_AY_AYSY_BOSS", defaultState = true },
            { row = 6, column = 1, IconID = 236871, text = "|cffFFFFFF插入||r", tooltipText = "使用|cff00adf0速度药水|r", saveVariable = "MS_AY_CRSDYS", section = "插入", defaultState = false },
            { row = 6, column = 2, IconID = 236868, text = "|cffFFFFFF插入||r", tooltipText = "插入|cff00adf0狂野魔法|r", saveVariable = "MS_AY_CRKYMF", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 135727, text = "|cffFFFFFF插入||r", tooltipText = "插入|cff00adf0种族|r", saveVariable = "MS_AY_CRZZ", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 338666, text = "|cffFFFFFF插入||r", tooltipText = "插入|cff00adf0饰品|r", saveVariable = "MS_AY_CRSP", section = "插入", defaultState = false },
            { row = 6, column = 5, IconID = 132962, text = "|cffFFFFFF插入||r", tooltipText = "插入|cff00adf0手套|r", saveVariable = "MS_AY_CRST", section = "插入", defaultState = false },
            { row = 7, column = 1, IconID = 136199, text = "|cffFFFFFF插入||r", tooltipText = "插入|cff00adf0暗影魔|r", saveVariable = "MS_AY_CRAYM", section = "插入", defaultState = false },
            { row = 7, column = 2, IconID = 237540, text = "|cffFFFFFF插入||r", tooltipText = "插入|cff00adf0神圣赞美诗|r", saveVariable = "MS_AY_CRSSZMS", section = "插入", defaultState = false },
            { row = 7, column = 3, IconID = 135982, text = "|cffFFFFFF插入||r", tooltipText = "插入|cff00adf0希望圣歌|r", saveVariable = "MS_AY_CRXWSG", section = "插入", defaultState = false },
            { row = 7, column = 4, IconID = 135739, text = "|cffFFFFFF插入||r", tooltipText = "插入|cff00adf0群体驱散|r", saveVariable = "MS_AY_CRQTQS", section = "插入", defaultState = false },
            { row = 7, column = 5, IconID = 237563, text = "|cffFFFFFF插入||r", tooltipText = "插入|cff00adf0消散|r", saveVariable = "MS_AY_CRXS", section = "插入", defaultState = false },
            { row = 8, column = 1, IconID = 237570, text = "|cffFFFFFF插入|r", tooltipText = "是否施自动释放渊", saveVariable = "MS_AY_AYSY_CR", showSpell = "暗影恶魔", section = "插入", defaultState = false },
            { row = 8, column = 2, IconID = 236871, text = "|cffFFFFFF偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "MS_AY_TOUYAO", section = "爆发", defaultState = false },
            { row = 9, column = 3, IconID = 136149, text = "|cffFFFFFF优先|r", tooltipText = "死神慈悲剩余<2s且目标可斩杀时优先打|cff00adf0暗言术：灭|r", saveVariable = "MS_AY_MIE_CS_PRI", defaultState = false },
            { row = 8, column = 4, IconID = 136149, text = "|cffFFFFFF卡CD|r", tooltipText = "|cff00adf0暗言术：灭|r CD 转好即放（不判断血量，可能反伤自身）", saveVariable = "MS_AY_MIE_CD", defaultState = false },
            -- ★ 自动切目标开关
            { row = 9, column = 1, IconID = 132293, text = "|cffFFFFFF切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "MS_TAB", defaultState = true },
        },
    },
}