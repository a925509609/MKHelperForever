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
        -- 2026-11-16 按「猪猪 / 彼岸花-无限服 · 增强页」重做（Forever 60级技能）：
        -- 旧 80 级体系（野性狼魂/萨满之怒/熔岩猛击/熔岩爆裂/寒霜刺骨/武器附魔/
        -- 偷药/饰品/手套/治疗链五星）全部下线，旧档由 Shaman_Enhancement_Features.lua 迁移。
        DM = {
            {
                text = "|cff0070DE防ADD|r",
                menuItems = {
                    { text = "|cff0070DE是|r" },
                    { text = "|cff0070DE否|r" },
                },
                tooltipText = "是否开启防ADD,打开的情况下需要自己和目标都进入战斗才输出（脱战不开怪）",
                saveVariable = "SM_ZQ_FADD",
                defaultID = 1
            },
            {
                text = "|cff0070DE护盾|r",
                menuItems = {
                    { text = "|cff0070DE水之护盾|r" },
                    { text = "|cff0070DE闪电之盾|r" },
                    { text = "|cff0070DE禁用|r" },
                },
                tooltipText = "|cff00adf0水之护盾：自动补水之护盾|r\n|cff996b1f闪电之盾：自动补闪电之盾（增强常驻）|r\n|cffff5040禁用：不自动补盾|r",
                saveVariable = "SM_ZQ_HD",
                defaultID = 3
            },
            { text = "|cff0070DE喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "血量低于设定值时喝|cff00adf0治疗药水|r。\n|cffff5040值为0：不使用。|r", saveVariable = "SM_ZQ_HXY" },
            { text = "|cff0070DE漩涡武器|r", isSlider = true, minValue = 0, maxValue = 5, valueStep = 1, defaultVal = 3, tooltipText = "漩涡武器层数达到设定值后，用|cff00adf0闪电箭|r消耗层数。\n|cffff5040值为0：不使用闪电箭消耗层数。|r", saveVariable = "SM_ZQ_XWWQ" },
            { text = "|cff0070DE打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 60, tooltipText = "施法进度达到该百分比时自动打断|cff00adf0风剪|r（0=关闭）", saveVariable = "SM_ZQ_ZDDD" },
            -- ===== 爆发按钮 =====
            { text = "|cff0070DE爆发全开|r", isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开 种族爆发", onClick = "WR_ShamanEnhancementBurstAllOn" },
            { text = "|cff0070DE爆发全关|r", isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭 种族爆发", onClick = "WR_ShamanEnhancementBurstAllOff" },
            { text = "|cff0070DE爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "种族爆发开着就全关，全关就全开", onClick = "WR_ShamanEnhancementBurstToggle" },
        },
        CB = {
            -- ===== 功能（右键图标打开额外条件） =====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Nature_Earthshock", text = "|cff0070DE震击|r", tooltipText = "开着时用震击输出：烈焰震击保持（预判秒数）+ 地震术（右键勾选）。\n右键：烈焰震击 / 预判 / 地震术 / 震击留打断 / 等级（满级 / 1级）\n宏：/SHAMAN_SHOCK 切换（后面加 on 开、off 关）", saveVariable = "SM_ZQ_ZJ_ON", section = "自动", defaultState = true,
                onRightClick = function() if WR_ShamanEnhancementUI then WR_ShamanEnhancementUI.ShowOptions("SM_ZQ_ZJ_ON") end end },
            { row = 1, column = 2, IconID = 136115, text = "|cff0070DE自动图腾|r", tooltipText = "开着时按右键里的设置自动补图腾：火/土/水/风每系身边没有自己的图腾就插该系选中的图腾。\n右键：每系总开关 + 图腾勾选（每系只能选一个）\n宏：/SHAMAN_TOTEM 切换（后面加 on 开、off 关）", saveVariable = "SM_ZQ_TT_ON", section = "自动", defaultState = true,
                onRightClick = function() if WR_ShamanEnhancementUI then WR_ShamanEnhancementUI.ShowOptions("SM_ZQ_TT_ON") end end },
            { row = 1, column = 3, IconID = 132293, text = "|cff0070DE切换目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "SM_ZQ_TAB", section = "自动", defaultState = true },
            { row = 1, column = 4, IconID = 135824, text = "|cff0070DE火焰新星|r", tooltipText = "开启后按冷却使用|cff00adf0火焰新星|r", saveVariable = "SM_ZQ_HXX", section = "自动", defaultState = true },
            { row = 1, column = 5, IconID = 136075, text = "|cff0070DE驱散|r", tooltipText = "开启后目标身上有可驱散的|cff00adf0魔法增益|r时，自动用|cff00adf0净化术|r驱散", saveVariable = "SM_ZQ_QS", section = "自动", defaultState = true },
            -- ===== 爆发 =====
            { row = 2, column = 1, IconID = 135727, text = "|cff0070DE种族爆发|r", tooltipText = "自动使用|cff00adf0种族爆发|r技能", saveVariable = "SM_ZQ_ZDZZ", section = "爆发", defaultState = true },
            -- ===== 插入（一次性，放完自关） =====
            { row = 3, column = 1, IconID = "Interface\\Icons\\Spell_Shadow_Demonbreath", text = "|cff0070DE呼吸|r", tooltipText = "插入|cff00adf0水下呼吸|r（一次性，放完自关）", saveVariable = "SM_ZQ_CRHX", section = "插入", defaultState = false },
            { row = 3, column = 2, IconID = 310730, text = "|cff0070DE元素|r", tooltipText = "插入|cff00adf0元素的召唤|r（一次性，放完自关）", saveVariable = "SM_ZQ_CRYS", section = "插入", defaultState = false },
            { row = 3, column = 3, IconID = "Interface\\Icons\\Spell_Shaman_Dropall_03", text = "|cff0070DE灵魂|r", tooltipText = "插入|cff00adf0灵魂的召唤|r（一次性，放完自关）", saveVariable = "SM_ZQ_CRLH", section = "插入", defaultState = false },
            { row = 3, column = 4, IconID = "Interface\\Icons\\Spell_Nature_Bloodlust", text = "|cff0070DE先知|r", tooltipText = "插入|cff00adf0先知之怒|r（一次性，放完自关）", saveVariable = "SM_ZQ_CRXZ", section = "插入", defaultState = false },
            { row = 4, column = 1, IconID = "Interface\\Icons\\Spell_Fire_Searingtotem", text = "|cff0070DE灼热|r", tooltipText = "插入|cff00adf0灼热图腾|r（一次性，放完自关）", saveVariable = "SM_ZQ_CRZR", section = "插入", defaultState = false },
            { row = 4, column = 2, IconID = "Interface\\Icons\\Spell_Fire_Selfdestruct", text = "|cff0070DE熔岩|r", tooltipText = "插入|cff00adf0熔岩图腾|r（一次性，放完自关）", saveVariable = "SM_ZQ_CRRY", section = "插入", defaultState = false },
        },
    },
    ["恢复"] = {
        -- 2026-11-16 按「猪猪 / 彼岸花-无限服 · 恢复萨满页」重做（Forever 60级技能）：
        -- 旧 80 级体系（狂咒/辛达苟萨、过量停条、潮汐之力、进攻驱散、手套/饰品/偷药、
        -- 萨隆邪铁炸弹类开关）全部下线，旧档由 Shaman_Restoration_Features.lua 迁移。
        DM = {
            {
                text = "|cff0070DE防ADD|r",
                menuItems = {
                    { text = "|cff0070DE是|r" },
                    { text = "|cff0070DE否|r" },
                },
                tooltipText = "是否开启防ADD,打开的情况下需要自己进入战斗才开始治疗",
                saveVariable = "SM_HF_FADD",
                defaultID = 1
            },
            {
                text = "|cff0070DE治疗模式|r",
                menuItems = {
                    { text = "|cff0070DE全团|r" },
                    { text = "|cff0070DE目标|r" },
                    { text = "|cff0070DE预读|r" },
                    { text = "|cff0070DE坦克|r" },
                    { text = "|cff0070DE脆皮|r" },
                    { text = "|cff0070DE一队|r" },
                    { text = "|cff0070DE二队|r" },
                    { text = "|cff0070DE三队|r" },
                    { text = "|cff0070DE四队|r" },
                    { text = "|cff0070DE五队|r" },
                },
                tooltipText = "|cff00adf0全团：治疗所有单位(可应对大部分情况)|r\n|cff996b1f坦克：仅治疗坦克，需要团长设置\"坦克\"职责|r\n|cff9C3590脆皮：排除坦克，治疗其他职业|r\n|cffffd700目标：仅治疗当前目标，无目标则全团|r",
                saveVariable = "SM_HF_ZLMS",
                defaultID = 1
            },
            {
                text = "|cff0070DE护盾|r",
                menuItems = {
                    { text = "|cff0070DE水之护盾|r" },
                    { text = "|cff0070DE大地之盾|r" },
                    { text = "|cff0070DE禁用|r" },
                },
                tooltipText = "|cff00adf0水之护盾：自动给自己补水之护盾|r\n|cff996b1f大地之盾：自动给坦克维持大地之盾|r\n|cffff5040禁用：不自动补盾|r",
                saveVariable = "SM_HF_HD",
                defaultID = 3
            },
            { text = "|cff0070DE喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "血量低于设定值时喝|cff00adf0治疗药水|r。\n|cffff5040值为0：不使用。|r", saveVariable = "SM_HF_HXY" },
            { text = "|cff0070DE迅捷波|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "有人血量低于设定值时用|cff00adf0自然迅捷|r+|cff00adf0治疗波|r瞬发急救。\n|cffff5040值为0：不使用。|r", saveVariable = "SM_HF_XJB" },
            { text = "|cff0070DE激流|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 80, tooltipText = "有人血量低于设定值且没有|cff00adf0激流|r时，使用|cff00adf0激流|r。\n|cffff5040值为0：不使用。|r", saveVariable = "SM_HF_JL" },
            { text = "|cff0070DE治疗链|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 1, defaultVal = 54, tooltipText = "人数为1：有人血量低于设定值时放|cff00adf0治疗链|r（先治疗焦点，再跳到附近受伤的队友）。\n人数为2以上：至少这么多人掉血，且最低几人平均血量低于设定值才放。\n治疗里排第3：激流后、治疗波前。\n|cff00adf0右键图标|r设置 等级/人数。\n|cffff5040拉到0=关闭。宏 /SHAMAN_CHAINHEAL 空格<数值> 快速设置|r", saveVariable = "SM_HF_ZLL" },
            { text = "|cff0070DE治疗波|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 60, tooltipText = "有人血量低于设定值时，使用|cff00adf0治疗波|r。\n|cffff5040值为0：不使用。|r", saveVariable = "SM_HF_ZLB" },
            { text = "|cff0070DE次级治疗波|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 85, tooltipText = "有人血量低于设定值时，使用|cff00adf0次级治疗波|r。\n|cffff5040值为0：不使用。|r", saveVariable = "SM_HF_CJZLB" },
            { text = "|cff0070DE打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 60, tooltipText = "施法进度达到该百分比时自动打断|cff00adf0风剪|r（0=关闭）", saveVariable = "SM_HF_ZDDD" },
            -- ===== 爆发按钮 =====
            { text = "|cff0070DE爆发全开|r", isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开 种族爆发", onClick = "WR_ShamanRestorationBurstAllOn" },
            { text = "|cff0070DE爆发全关|r", isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭 种族爆发", onClick = "WR_ShamanRestorationBurstAllOff" },
            { text = "|cff0070DE爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "种族爆发开着就全关，全关就全开", onClick = "WR_ShamanRestorationBurstToggle" },
        },
        CB = {
            -- ===== 功能（右键图标打开额外条件） =====
            { row = 1, column = 1, IconID = 136115, text = "|cff0070DE自动图腾|r", tooltipText = "开着时按右键里的设置自动补图腾：火/土/水/风每系身边没有自己的图腾就插该系选中的图腾。\n右键：每系总开关 + 图腾勾选（每系只能选一个）\n宏：/SHAMAN_TOTEM 切换（后面加 on 开、off 关）", saveVariable = "SM_HF_TT_ON", section = "自动", defaultState = true,
                onRightClick = function() if WR_ShamanRestorationUI then WR_ShamanRestorationUI.ShowOptions("SM_HF_TT_ON") end end },
            { row = 1, column = 2, IconID = 132293, text = "|cff0070DE切换目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "SM_HF_TAB", section = "自动", defaultState = true },
            { row = 1, column = 3, IconID = 136075, text = "|cff0070DE驱散|r", tooltipText = "自动用|cff00adf0净化灵魂|r驱散魔法/诅咒。\n右键：自己 / 小队(全团) 分开控制", saveVariable = "SM_HF_QS_ON", section = "自动", defaultState = true,
                onRightClick = function() if WR_ShamanRestorationUI then WR_ShamanRestorationUI.ShowOptions("SM_HF_QS") end end },
            -- ===== 爆发 =====
            { row = 2, column = 1, IconID = 135727, text = "|cff0070DE种族爆发|r", tooltipText = "自动使用|cff00adf0种族爆发|r技能", saveVariable = "SM_HF_ZDZZ", section = "爆发", defaultState = true },
            -- ===== 插入（一次性，放完自关） =====
            { row = 3, column = 1, IconID = 310730, text = "|cff0070DE呼唤|r", tooltipText = "插入|cff00adf0元素的召唤|r（一次性，放完自关）", saveVariable = "SM_HF_CRHH", section = "插入", defaultState = false },
            { row = 3, column = 2, IconID = 135790, text = "|cff0070DE元素|r", tooltipText = "插入|cff00adf0火元素图腾|r（一次性，放完自关）", saveVariable = "SM_HF_CRYS", section = "插入", defaultState = false },
            { row = 3, column = 3, IconID = 136024, text = "|cff0070DE灵魂|r", tooltipText = "插入|cff00adf0土元素图腾|r（一次性，放完自关）", saveVariable = "SM_HF_CRLH", section = "插入", defaultState = false },
            { row = 3, column = 4, IconID = 237589, text = "|cff0070DE法力潮|r", tooltipText = "插入|cff00adf0法力之潮图腾|r（一次性，放完自关）", saveVariable = "SM_HF_CRFLC", section = "插入", defaultState = false },
        },
    },
}