-- ============================================================
-- Priest_Menu.lua
-- 牧师全专精配置菜单（戒律 / 神圣 / 暗影）
-- 包含各类自动功能、治疗阈值、驱散模式、爆发等开关
--   2026-11-18 戒律专精按「猪猪 / 彼岸花·无限服 戒律页」功能图重做：
--   选择（防ADD/治疗模式）、10 条拉条、功能 5 图标、插入 3 图标、爆发三槽位；
--   旧 80 级菜单项（赞美诗/希望圣歌/痛苦压制/守护之魂等）已全部下线。
-- ============================================================

if WR_PlayerClass ~= "PRIEST" then return end

Priest_Menu = {
    ["戒律"] = {
        -- ★★★ 2026-11-18 按「猪猪 / 彼岸花·无限服 · 戒律页」功能图重做（Forever 60级）
        -- 旧 80 级体系（痛苦压制/守护之魂/神圣赞美诗/希望圣歌/治疗之环/愈合祷言/
        -- 绝望祷言/狂咒/过量停条等）全部从戒律面板下线；治疗/功能/插入按新图重排。
        DM = {
            -- ===== 选择 =====
            {
                text = "|cffFFFFFF防ADD|r",
                menuItems = { { text = "|cffFFFFFF是|r" }, { text = "|cffFFFFFF否|r" } },
                tooltipText = "是否开启防ADD：是 = 只在自己进入战斗后治疗；否 = 任一队友进入战斗就开始治疗",
                saveVariable = "JL_FADD",
                defaultID = 1
            },
            {
                text = "|cffFFFFFF治疗模式|r",
                menuItems = {
                    { text = "|cffFFFFFF全团|r" }, { text = "|cffFFFFFF目标|r" }, { text = "|cffFFFFFF预读|r" },
                    { text = "|cffFFFFFF坦克|r" }, { text = "|cffFFFFFF脆皮|r" }, { text = "|cffFFFFFF一队|r" },
                    { text = "|cffFFFFFF二队|r" }, { text = "|cffFFFFFF三队|r" }, { text = "|cffFFFFFF四队|r" },
                    { text = "|cffFFFFFF五队|r" },
                },
                tooltipText = "全团：治疗所有小队/团队成员\n目标：只治疗当前目标\n预读：优先当前目标，无目标则全团\n坦克：只治疗坦克职责\n脆皮：排除坦克\n一队~五队：只治疗对应小队",
                saveVariable = "JL_ZLMS",
                defaultID = 1
            },
            {
                text = "|cffFFFFFF驱散|r",
                menuItems = {
                    { text = "|cffFFFFFF常规|r" }, { text = "|cffFFFFFF优先|r" }, { text = "|cffFFFFFF目标|r" },
                    { text = "|cffFFFFFF指向|r" }, { text = "|cffFFFFFF禁用|r" },
                },
                tooltipText = "自动驱散模式：常规/优先驱散自己与队友的魔法、疾病；禁用 = 完全不自动驱散",
                saveVariable = "JL_QS",
                defaultID = 2
            },
            -- ===== 拉条（截图默认值） =====
            { text = "|cffFFFFFF喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "血量低于设定值时喝|cff00adf0治疗药水|r。\n|cffff5040值为0：不使用。|r", saveVariable = "JL_HXY" },
            { text = "|cffFFFFFF黑暗献祭|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "自身血量高于设定值时使用|cff00adf0黑暗献祭|r（亡灵牧师种族技能，15 秒扣血换法力；法力高于80%时不用）。\n|cffff5040值为0：不使用。|r", saveVariable = "JL_HZ" },
            { text = "|cffFFFFFF真言术：盾|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 80, tooltipText = "友方血量低于设定值时补|cff00adf0真言术：盾|r（有虚弱灵魂时跳过）。\n|cffff5040值为0：不使用。|r", saveVariable = "JL_ZYSD" },
            { text = "|cffFFFFFF苦修|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 70, tooltipText = "有人血量低于设定值时使用|cff00adf0苦修|r。\n|cffff5040值为0：不使用。|r", saveVariable = "JL_KX" },
            { text = "|cffFFFFFF联结治疗|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 70, tooltipText = "有人血量低于设定值时使用|cff00adf0联结治疗|r（同时治疗自己和目标）。\n|cffff5040值为0：不使用。|r", saveVariable = "JL_LJZL" },
            { text = "|cffFFFFFF快速治疗|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "有人血量低于设定值时使用|cff00adf0快速治疗|r。\n|cffff5040值为0：不使用。|r", saveVariable = "JL_KSZL" },
            { text = "|cffFFFFFF强效治疗术|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 75, tooltipText = "有人血量低于设定值时使用|cff00adf0强效治疗术|r。\n|cffff5040值为0：不使用。|r", saveVariable = "JL_QXZLS" },
            { text = "|cffFFFFFF治疗术|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 75, tooltipText = "有人血量低于设定值时使用|cff00adf0治疗术|r。\n|cffff5040值为0：不使用。|r", saveVariable = "JL_ZLSHU" },
            { text = "|cffFFFFFF次级治疗术|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 75, tooltipText = "有人血量低于设定值时使用|cff00adf0次级治疗术|r。\n|cffff5040值为0：不使用。|r", saveVariable = "JL_CJZLS" },
            { text = "|cffFFFFFF恢复|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 90, tooltipText = "有人血量低于设定值且没有|cff00adf0恢复|r时使用。\n|cffff5040值为0：不使用。|r", saveVariable = "JL_HF" },
            -- ===== 爆发按钮 =====
            { text = "|cffFFFFFF爆发槽位1|r", isButton = true, buttonText = "设置", buttonWidth = 90, labelWidth = 95, tooltipText = "点击循环选择：未设置 → 能量灌注 → 神圣新星 → 心灵专注 → 血性狂怒 → 狂暴 → 狮心", onClick = "WR_PriestDisciplineBurstSlot1" },
            { text = "|cffFFFFFF爆发槽位2|r", isButton = true, buttonText = "设置", buttonWidth = 90, labelWidth = 95, tooltipText = "点击循环选择：未设置 → 能量灌注 → 神圣新星 → 心灵专注 → 血性狂怒 → 狂暴 → 狮心", onClick = "WR_PriestDisciplineBurstSlot2" },
            { text = "|cffFFFFFF爆发槽位3|r", isButton = true, buttonText = "设置", buttonWidth = 90, labelWidth = 95, tooltipText = "点击循环选择：未设置 → 能量灌注 → 神圣新星 → 心灵专注 → 血性狂怒 → 狂暴 → 狮心", onClick = "WR_PriestDisciplineBurstSlot3" },
            { text = "|cffFFFFFF爆发全开|r", isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开三个爆发槽位", onClick = "WR_PriestDisciplineBurstAllOn" },
            { text = "|cffFFFFFF爆发全关|r", isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭三个爆发槽位", onClick = "WR_PriestDisciplineBurstAllOff" },
            { text = "|cffFFFFFF爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "三个槽位开着就全关，全关就全开", onClick = "WR_PriestDisciplineBurstToggle" },
        },
        CB = {
            -- ===== 功能 =====
            { row = 1, column = 1, IconID = 135894, text = "|cffFFFFFF驱散|r", tooltipText = "自动驱散：自己/队友中|cff00adf0魔法|r→驱散魔法；中|cff00adf0疾病|r→驱除疾病。\n与上方「驱散」下拉的禁用/总闸共同生效。", saveVariable = "JL_QS_ON", section = "功能", defaultState = true },
            { row = 1, column = 2, IconID = 136149, text = "|cffFFFFFF暗言术：灭|r", tooltipText = "目标可攻击时使用|cff00adf0暗言术：灭|r（默认关闭，避免反伤）", saveVariable = "JL_AYSHM", section = "功能", defaultState = false },
            { row = 1, column = 3, IconID = 135987, text = "|cffFFFFFF真言术：韧|r", tooltipText = "维持自己身上的|cff00adf0真言术：韧|r", saveVariable = "JL_ZYSR", section = "功能", defaultState = true },
            { row = 1, column = 4, IconID = 135926, text = "|cffFFFFFF心灵之火|r", tooltipText = "维持自己身上的|cff00adf0心灵之火|r", saveVariable = "JL_XLHZ", section = "功能", defaultState = true },
            { row = 1, column = 5, IconID = "Interface\\Icons\\Spell_Holy_HolySmite", text = "|cffFFFFFF惩击|r", tooltipText = "没有治疗目标时对当前目标使用|cff00adf0惩击|r填充输出", saveVariable = "JL_CJ", section = "功能", defaultState = true },
            -- ===== 插入（一次性，放完自关） =====
            { row = 2, column = 1, IconID = 135932, text = "|cffFFFFFF灌注|r", tooltipText = "插入|cff00adf0能量灌注|r（一次性，放完自关）", saveVariable = "JL_CRGNZ", section = "插入", defaultState = false },
            { row = 2, column = 2, IconID = 135981, text = "|cffFFFFFF新星|r", tooltipText = "插入|cff00adf0神圣新星|r（一次性，放完自关）", saveVariable = "JL_CRXX", section = "插入", defaultState = false },
            { row = 2, column = 3, IconID = 135943, text = "|cffFFFFFF治疗祷言|r", tooltipText = "插入|cff00adf0治疗祷言|r（一次性，放完自关）", saveVariable = "JL_CRZLDY", section = "插入", defaultState = false },
            -- ===== 爆发 =====
            { row = 3, column = 1, IconID = 135727, text = "|cffFFFFFF种族爆发|r", tooltipText = "自动使用|cff00adf0种族爆发|r技能", saveVariable = "JL_BF_RACE", section = "爆发", defaultState = true },
            { row = 3, column = 2, IconID = "Interface\\Icons\\INV_Misc_QuestionMark", text = "|cffFFFFFF槽位1|r", tooltipText = "爆发槽位1（右键循环选择技能）", saveVariable = "JL_BF_S1", section = "爆发", defaultState = false, onRightClick = function() if WR_PriestDisciplineBurstSlot1 then WR_PriestDisciplineBurstSlot1() end end },
            { row = 3, column = 3, IconID = "Interface\\Icons\\INV_Misc_QuestionMark", text = "|cffFFFFFF槽位2|r", tooltipText = "爆发槽位2（右键循环选择技能）", saveVariable = "JL_BF_S2", section = "爆发", defaultState = false, onRightClick = function() if WR_PriestDisciplineBurstSlot2 then WR_PriestDisciplineBurstSlot2() end end },
            { row = 3, column = 4, IconID = "Interface\\Icons\\INV_Misc_QuestionMark", text = "|cffFFFFFF槽位3|r", tooltipText = "爆发槽位3（右键循环选择技能）", saveVariable = "JL_BF_S3", section = "爆发", defaultState = false, onRightClick = function() if WR_PriestDisciplineBurstSlot3 then WR_PriestDisciplineBurstSlot3() end end },
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