-- ============================================================
-- Warlock_Menu.lua
-- 术士全专精配置菜单（痛苦 / 恶魔学识 / 毁灭）
-- 包含各类自动功能、插入技能、爆发等开关
-- ============================================================

if WR_PlayerClass ~= "WARLOCK" then return end

Warlock_Menu = {
    -- ==================== 痛苦专精 ====================
    -- 2026-11-15 按「彼岸花-无限服 · 痛苦页」重做（Forever 60级技能）：
    -- 旧 80 级体系开关（痛苦无常/鬼影缠身/腐蚀之种/痛苦诅咒/厄运诅咒/地狱火/
    -- 灵魂碎裂/暗影烈焰/狂咒停手/TOC一键恐惧/武器石等）全部移除，旧档自动迁移。
    ["痛苦"] = {
        -- ===== 下拉菜单（DM） =====
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
                text = "|cff9482C9生命分流|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 30,
                tooltipText = "蓝量低于该百分比时使用|cff00adf0生命分流|r（血量需高于40%保命下限，默认30）",
                saveVariable = "SS_TK_LTFL",
            },
            {
                text = "|cff9482C9高血分流|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 80,
                tooltipText = "血量高于该百分比且蓝量低于60%时主动|cff00adf0生命分流|r换蓝（默认80）",
                saveVariable = "SS_TK_GXFL",
            },
            {
                text = "|cff9482C9喝红药|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 30,
                tooltipText = "血量低于该百分比时使用|cff00adf0治疗石|r/|cff00adf0治疗药水|r（默认30）",
                saveVariable = "SS_TK_HHY",
            },
            {
                text = "|cff9482C9魔杖回蓝|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 50,
                tooltipText = "蓝量低于该百分比且无技能可打时用|cff00adf0魔杖|r填充（默认50）",
                saveVariable = "SS_TK_MZHL",
            },
            {
                text = "|cff9482C9爆发|r",
                isButton = true, buttonText = "全部打开", buttonWidth = 74, labelWidth = 40,
                tooltipText = "一键打开 种族爆发",
                onClick = "WR_WarlockAfflBurstAllOn"
            },
            {
                text = "|cff9482C9爆发|r",
                isButton = true, buttonText = "全部关闭", buttonWidth = 74, labelWidth = 40,
                tooltipText = "一键关闭 种族爆发",
                onClick = "WR_WarlockAfflBurstAllOff"
            },
            {
                text = "|cff9482C9爆发|r",
                isButton = true, buttonText = "切换", buttonWidth = 74, labelWidth = 40,
                tooltipText = "切换 种族爆发 开/关",
                onClick = "WR_WarlockAfflBurstToggle"
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- ===== 功能（截图：DOT / 读条引导 / 护甲 / 召唤宠物 / 切换目标）=====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", text = "|cff9482C9DOT|r", tooltipText = "DOT总开关：开着时按右键里的设置给目标上DOT、灾祸和诅咒。\n\n|cff00adf0腐蚀术|r/|cff00adf0献祭|r/|cff00adf0生命虹吸|r：勾上才放。\n|cff00adf0灾祸|r（痛苦/末日 2选1）、|cff00adf0诅咒|r（元素/虚弱/鲁莽/语言/疲劳 5选1）：目标身上没有「自己的那一种」就补。\n\n|cffaaffaa右键打开DOT设置（预判秒数、灾祸/诅咒选择）。|r\n宏：/WARLOCK_DOT 切换（on 开 / off 关）", saveVariable = "SS_TK_DOT", section = "功能", defaultState = true,
              onRightClick = function() if WR_WarlockAffl then WR_WarlockAffl.ShowOptions("SS_TK_DOT") end end },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Shadow_Shadowbolt", text = "|cff9482C9读条引导|r", tooltipText = "读条引导总开关：开着时按右键里勾上的技能放引导、读条类技能。\n\n引导类：|cff00adf0吸取灵魂|r → |cff00adf0吸取生命|r → |cff00adf0折磨|r；读条类只有|cff00adf0暗影箭|r填充。\n\n|cffaaffaa右键打开读条引导设置（预判/血量门槛、无脑/看血量）。|r\n宏：/WARLOCK_CAST 切换（on 开 / off 关）", saveVariable = "SS_TK_CAST", section = "功能", defaultState = true,
              onRightClick = function() if WR_WarlockAffl then WR_WarlockAffl.ShowOptions("SS_TK_CAST") end end },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Spell_Shadow_Ragingscream", text = "|cff9482C9护甲|r", tooltipText = "护甲功能：自己身上没有右键里选中的那种甲就自动补上（|cff00adf0恶魔皮肤|r/|cff00adf0魔甲术|r 二选一）；战斗内外都补。\n\n|cffaaffaa右键选择护甲种类。|r\n宏：/WARLOCK_ARMOR 切换（on 开 / off 关）", saveVariable = "SS_TK_ARMOR", section = "功能", defaultState = true,
              onRightClick = function() if WR_WarlockAffl then WR_WarlockAffl.ShowOptions("SS_TK_ARMOR") end end },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Spell_Shadow_SummonImp", text = "|cff9482C9召唤宠物|r", tooltipText = "召唤宠物功能：脱战、站着不动、身边没有宠物（没召唤/死了）就自动召唤右键里选中的那一种（小鬼/虚空行者/魅魔/地狱猎犬 多选，按顺序优先）。\n\n战斗中不召唤（读条10秒）；骑马、吃喝时不召唤。点了|cff00adf0恶魔牺牲|r、要把宠物献祭掉的，把这个开关关掉。\n\n|cffaaffaa右键选择宠物种类。|r\n宏：/WARLOCK_SUMMON 切换（on 开 / off 关）", saveVariable = "SS_TK_SUMMON", section = "功能", defaultState = true,
              onRightClick = function() if WR_WarlockAffl then WR_WarlockAffl.ShowOptions("SS_TK_SUMMON") end end },
            { row = 1, column = 5, IconID = 132293, text = "|cff9482C9切换目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "SS_TK_TAB", section = "功能", defaultState = true },
            -- ===== 插入（截图：死亡缠绕/恐惧术/恐惧嚎叫/地狱烈焰/火焰之雨/生命通道/生命分流）=====
            { row = 2, column = 1, IconID = "Interface\\Icons\\Spell_Shadow_Deathcoil", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0死亡缠绕|r（一次性，放完自关）", saveVariable = "SS_TK_CRSWCR", section = "插入", defaultState = false },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Spell_Shadow_Possession", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0恐惧术|r（一次性，放完自关）", saveVariable = "SS_TK_CRKJ", section = "插入", defaultState = false },
            { row = 2, column = 3, IconID = "Interface\\Icons\\Spell_Shadow_Deathscream", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0恐惧嚎叫|r（一次性，放完自关）", saveVariable = "SS_TK_CRKJHJ", section = "插入", defaultState = false },
            { row = 2, column = 4, IconID = "Interface\\Icons\\Spell_Fire_Incinerate", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0地狱烈焰|r（一次性，放完自关）", saveVariable = "SS_TK_CRDYLY", section = "插入", defaultState = false },
            { row = 3, column = 1, IconID = "Interface\\Icons\\Spell_Shadow_Rainoffire", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0火焰之雨|r（一次性，放完自关）", saveVariable = "SS_TK_CRHYZY", section = "插入", defaultState = false },
            { row = 3, column = 2, IconID = "Interface\\Icons\\Spell_Shadow_Lifedrain", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0生命通道|r（给宠物回血，一次性，放完自关）", saveVariable = "SS_TK_CRSMTD", section = "插入", defaultState = false },
            { row = 3, column = 3, IconID = "Interface\\Icons\\Spell_Shadow_Burningspirit", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0生命分流|r（一次性，放完自关）", saveVariable = "SS_TK_CRLTFL", section = "插入", defaultState = false },
            -- ===== 爆发（截图：种族爆发 + 全开/全关/切换）=====
            { row = 4, column = 1, IconID = 135727, text = "|cff9482C9种族爆|r", tooltipText = "自动使用|cff00adf0种族|r爆发技能（战斗中冷却好即用）", saveVariable = "SS_TK_ZDZZ", section = "爆发", defaultState = true },
        },
    },
    -- ==================== 恶魔学识专精 ====================
    -- 2026-11-15 按「猪猪-无限服 · 恶魔术页」重做（Forever 60级技能）
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
                text = "|cff9482C9生命分流|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 30,
                tooltipText = "蓝量低于该百分比时使用|cff00adf0生命分流|r（血量需高于40%保命下限，默认30）",
                saveVariable = "SS_EM_LTFL",
            },
            {
                text = "|cff9482C9高血分流|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 80,
                tooltipText = "血量高于该百分比且蓝量低于60%时主动|cff00adf0生命分流|r换蓝（默认80）",
                saveVariable = "SS_EM_GXFL",
            },
            {
                text = "|cff9482C9喝红药|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 30,
                tooltipText = "血量低于该百分比时使用|cff00adf0治疗石|r/|cff00adf0治疗药水|r（默认30）",
                saveVariable = "SS_EM_HHY",
            },
            {
                text = "|cff9482C9魔杖回蓝|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 50,
                tooltipText = "蓝量低于该百分比且无技能可打时用|cff00adf0魔杖|r填充（默认50）",
                saveVariable = "SS_EM_MZHL",
            },
            {
                text = "|cff9482C9爆发|r",
                isButton = true, buttonText = "全部打开", buttonWidth = 74, labelWidth = 40,
                tooltipText = "一键打开 种族爆发",
                onClick = "WR_WarlockDemoBurstAllOn"
            },
            {
                text = "|cff9482C9爆发|r",
                isButton = true, buttonText = "全部关闭", buttonWidth = 74, labelWidth = 40,
                tooltipText = "一键关闭 种族爆发",
                onClick = "WR_WarlockDemoBurstAllOff"
            },
            {
                text = "|cff9482C9爆发|r",
                isButton = true, buttonText = "切换", buttonWidth = 74, labelWidth = 40,
                tooltipText = "切换 种族爆发 开/关",
                onClick = "WR_WarlockDemoBurstToggle"
            },
        },
        CB = {
            -- ===== 功能（截图：DOT / 读条引导 / 切换目标）=====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", text = "|cff9482C9DOT|r", tooltipText = "DOT总开关：开着时按右键里的设置给目标上DOT。\n\n|cff00adf0腐蚀术|r/|cff00adf0献祭|r/|cff00adf0生命虹吸|r：勾上才放。\n|cff00adf0灾祸|r（痛苦/末日 2选1）、|cff00adf0诅咒|r（元素/虚弱/鲁莽/语言/疲劳 5选1）：目标身上没有「自己的那一种」就补。\n\n|cffaaffaa右键打开DOT设置（预判秒数、灾祸/诅咒选择）。|r\n宏：/WARLOCKDOT 切换（on 开 / off 关）", saveVariable = "SS_EM_DOT", section = "功能", defaultState = true,
              onRightClick = function() if WR_WarlockDemo then WR_WarlockDemo.ShowOptions("SS_EM_DOT") end end },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Shadow_Shadowbolt", text = "|cff9482C9读条引导|r", tooltipText = "读条引导总开关：开着时按右键里勾上的技能放引导、读条类技能。\n\n引导类：|cff00adf0吸取灵魂|r/|cff00adf0吸取生命|r；读条类从上到下就是先后：|cff00adf0灵魂之火|r → |cff00adf0灼热之痛|r，最后用|cff00adf0暗影箭|r填充。\n\n|cffaaffaa右键打开读条引导设置（血量门槛）。|r\n宏：/WARLOCKCAST 切换（on 开 / off 关）", saveVariable = "SS_EM_CAST", section = "功能", defaultState = true,
              onRightClick = function() if WR_WarlockDemo then WR_WarlockDemo.ShowOptions("SS_EM_CAST") end end },
            { row = 1, column = 3, IconID = 132293, text = "|cff9482C9切换目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "SS_EM_TAB", section = "功能", defaultState = true },
            -- ===== 插入 =====
            { row = 2, column = 1, IconID = "Interface\\Icons\\Spell_Shadow_Ragingscream", text = "|cff9482C9护甲|r", tooltipText = "护甲功能：身上没有右键里选中的那种甲就自动补上（|cff00adf0恶魔皮肤|r/|cff00adf0魔甲术|r 二选一）；战斗内外都补。\n\n|cffaaffaa右键选择护甲种类。|r\n宏：/WARLOCKARMOR 切换（on 开 / off 关）", saveVariable = "SS_EM_ARMOR", section = "插入", defaultState = true,
              onRightClick = function() if WR_WarlockDemo then WR_WarlockDemo.ShowOptions("SS_EM_ARMOR") end end },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Spell_Shadow_SummonImp", text = "|cff9482C9召唤宠物|r", tooltipText = "召唤宠物功能：脱战、站着不动、身边没有宠物（没召唤/死了）就自动召唤右键里选中的那一种（小鬼/虚空行者/魅魔/地狱猎犬 多选，按顺序优先）。\n\n战斗中不召唤（读条10秒）；骑马、吃喝时不召唤。\n点了|cff00adf0恶魔牺牲|r、要把宠物献祭掉的，把这个开关关掉。\n\n|cffaaffaa右键选择宠物种类。|r\n宏：/WARLOCKSUMMON 切换（on 开 / off 关）", saveVariable = "SS_EM_SUMMON", section = "插入", defaultState = true,
              onRightClick = function() if WR_WarlockDemo then WR_WarlockDemo.ShowOptions("SS_EM_SUMMON") end end },
            { row = 2, column = 3, IconID = "Interface\\Icons\\Spell_Shadow_Deathcoil", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0死亡缠绕|r（一次性，放完自关）", saveVariable = "SS_EM_CRSWCR", section = "插入", defaultState = false },
            { row = 2, column = 4, IconID = "Interface\\Icons\\Spell_Shadow_Possession", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0恐惧术|r（一次性，放完自关）", saveVariable = "SS_EM_CRKJ", section = "插入", defaultState = false },
            { row = 2, column = 5, IconID = "Interface\\Icons\\Spell_Shadow_Deathscream", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0恐惧嚎叫|r（一次性，放完自关）", saveVariable = "SS_EM_CRKJHJ", section = "插入", defaultState = false },
            { row = 3, column = 1, IconID = "Interface\\Icons\\Spell_Fire_Incinerate", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0地狱烈焰|r（一次性，放完自关）", saveVariable = "SS_EM_CRDYLY", section = "插入", defaultState = false },
            { row = 3, column = 2, IconID = "Interface\\Icons\\Spell_Shadow_Rainoffire", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0火焰之雨|r（一次性，放完自关）", saveVariable = "SS_EM_CRHYZY", section = "插入", defaultState = false },
            { row = 3, column = 3, IconID = "Interface\\Icons\\Spell_Shadow_Lifedrain", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0生命通道|r（给宠物回血，一次性，放完自关）", saveVariable = "SS_EM_CRSMTD", section = "插入", defaultState = false },
            { row = 3, column = 4, IconID = "Interface\\Icons\\Spell_Shadow_Burningspirit", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0生命分流|r（一次性，放完自关）", saveVariable = "SS_EM_CRLTFL", section = "插入", defaultState = false },
            -- ===== 爆发 =====
            { row = 4, column = 1, IconID = 135727, text = "|cff9482C9种族爆|r", tooltipText = "自动使用|cff00adf0种族|r爆发技能（战斗中冷却好即用）", saveVariable = "SS_EM_ZDZZ", section = "爆发", defaultState = true },
        },
    },
    -- ==================== 毁灭专精 ====================
    -- 2026-11-15 按「猪猪-无限服 · 毁灭页」重做（Forever 60级技能）：
    -- 旧 80 级体系开关（狂咒/魔甲下拉/脱战宠物下拉/武器石/偷药/混沌/距离/
    -- 暗影烈焰/腐蚀之种/厄运诅咒/地狱火/灵魂碎裂/TOC一键恐惧等）全部移除，
    -- 旧档由 Warlock_Destruction_Features.lua 自动迁移。
    ["毁灭"] = {
        -- ===== 下拉菜单（DM） =====
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
                text = "|cff9482C9生命分流|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 30,
                tooltipText = "蓝量低于该百分比时使用|cff00adf0生命分流|r（血量需高于40%保命下限，默认30）",
                saveVariable = "SS_HM_LTFL",
            },
            {
                text = "|cff9482C9高血分流|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 80,
                tooltipText = "血量高于该百分比且蓝量低于60%时主动|cff00adf0生命分流|r换蓝（默认80）",
                saveVariable = "SS_HM_GXFL",
            },
            {
                text = "|cff9482C9喝红药|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 30,
                tooltipText = "血量低于该百分比时使用|cff00adf0治疗石|r/|cff00adf0治疗药水|r（默认30）",
                saveVariable = "SS_HM_HHY",
            },
            {
                text = "|cff9482C9魔杖回蓝|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 50,
                tooltipText = "蓝量低于该百分比且无技能可打时用|cff00adf0魔杖|r填充（默认50）",
                saveVariable = "SS_HM_MZHL",
            },
            {
                text = "|cff9482C9爆发|r",
                isButton = true, buttonText = "全部打开", buttonWidth = 74, labelWidth = 40,
                tooltipText = "一键打开 种族爆发",
                onClick = "WR_WarlockDestBurstAllOn"
            },
            {
                text = "|cff9482C9爆发|r",
                isButton = true, buttonText = "全部关闭", buttonWidth = 74, labelWidth = 40,
                tooltipText = "一键关闭 种族爆发",
                onClick = "WR_WarlockDestBurstAllOff"
            },
            {
                text = "|cff9482C9爆发|r",
                isButton = true, buttonText = "切换", buttonWidth = 74, labelWidth = 40,
                tooltipText = "切换 种族爆发 开/关",
                onClick = "WR_WarlockDestBurstToggle"
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- ===== 功能（截图：DOT / 读条引导 / 护甲 / 召唤宠物 / 切换目标 / 暗灼）=====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", text = "|cff9482C9DOT|r", tooltipText = "DOT总开关：开着时按右键里的设置给目标上DOT、灾祸和诅咒。\n\n|cff00adf0腐蚀术|r/|cff00adf0献祭|r/|cff00adf0生命虹吸|r：勾上才放。\n|cff00adf0灾祸|r（痛苦/末日 2选1）、|cff00adf0诅咒|r（元素/虚弱/鲁莽/语言/疲劳 5选1）：目标身上没有「自己的那一种」就补。\n\n|cffaaffaa右键打开DOT设置（预判秒数、灾祸/诅咒选择）。|r\n宏：/WARLOCK_DOT 切换（on 开 / off 关）", saveVariable = "SS_HM_DOT", section = "功能", defaultState = true,
              onRightClick = function() if WR_WarlockDest then WR_WarlockDest.ShowOptions("SS_HM_DOT") end end },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Shadow_Shadowbolt", text = "|cff9482C9读条引导|r", tooltipText = "读条引导总开关：开着时按右键里勾上的技能放引导、读条类技能。\n\n引导类：|cff00adf0吸取灵魂|r/|cff00adf0吸取生命|r；读条类从上到下就是先后：|cff00adf0烧尽|r，最后用|cff00adf0暗影箭|r填充。\n\n|cffaaffaa右键打开读条引导设置（预判/血量门槛、无脑/看血量）。|r\n宏：/WARLOCK_CAST 切换（on 开 / off 关）", saveVariable = "SS_HM_CAST", section = "功能", defaultState = true,
              onRightClick = function() if WR_WarlockDest then WR_WarlockDest.ShowOptions("SS_HM_CAST") end end },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Spell_Shadow_Ragingscream", text = "|cff9482C9护甲|r", tooltipText = "护甲功能：自己身上没有右键里选中的那种甲就自动补上（|cff00adf0恶魔皮肤|r/|cff00adf0魔甲术|r 二选一）；战斗内外都补。\n\n|cffaaffaa右键选择护甲种类。|r\n宏：/WARLOCK_ARMOR 切换（on 开 / off 关）", saveVariable = "SS_HM_ARMOR", section = "功能", defaultState = true,
              onRightClick = function() if WR_WarlockDest then WR_WarlockDest.ShowOptions("SS_HM_ARMOR") end end },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Spell_Shadow_SummonImp", text = "|cff9482C9召唤宠物|r", tooltipText = "召唤宠物功能：脱战、站着不动、身边没有宠物（没召唤/死了）就自动召唤右键里选中的那一种（小鬼/虚空行者/魅魔/地狱猎犬 多选，按顺序优先）。\n\n战斗中不召唤（读条10秒）；骑马、吃喝时不召唤。点了|cff00adf0恶魔牺牲|r、要把宠物献祭掉的，把这个开关关掉。\n\n|cffaaffaa右键选择宠物种类。|r\n宏：/WARLOCK_SUMMON 切换（on 开 / off 关）", saveVariable = "SS_HM_SUMMON", section = "功能", defaultState = true,
              onRightClick = function() if WR_WarlockDest then WR_WarlockDest.ShowOptions("SS_HM_SUMMON") end end },
            { row = 1, column = 5, IconID = 132293, text = "|cff9482C9切换目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "SS_HM_TAB", section = "功能", defaultState = true },
            { row = 1, column = 6, IconID = 136189, showSpell = "暗影灼烧", text = "|cff9482C9暗灼|r", tooltipText = "暗灼：目标血量低于20%时自动打|cff00adf0暗影灼烧|r（斩杀，需毁灭天赋；没学会不会提示）", saveVariable = "SS_HM_AZS", section = "功能", defaultState = true },
            -- ===== 插入（截图：浩劫/死亡缠绕/恐惧术/恐惧嚎叫/地狱烈焰/火焰之雨/生命通道/生命分流）=====
            { row = 2, column = 1, IconID = 136122, showSpell = "浩劫诅咒", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0浩劫诅咒|r（一次性，放完自关）", saveVariable = "SS_HM_CRHJ", section = "插入", defaultState = false },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Spell_Shadow_Deathcoil", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0死亡缠绕|r（一次性，放完自关）", saveVariable = "SS_HM_CRSWCR", section = "插入", defaultState = false },
            { row = 2, column = 3, IconID = "Interface\\Icons\\Spell_Shadow_Possession", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0恐惧术|r（一次性，放完自关）", saveVariable = "SS_HM_CRKJ", section = "插入", defaultState = false },
            { row = 2, column = 4, IconID = "Interface\\Icons\\Spell_Shadow_Deathscream", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0恐惧嚎叫|r（一次性，放完自关）", saveVariable = "SS_HM_CRKJHJ", section = "插入", defaultState = false },
            { row = 3, column = 1, IconID = "Interface\\Icons\\Spell_Fire_Incinerate", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0地狱烈焰|r（一次性，放完自关）", saveVariable = "SS_HM_CRDYLY", section = "插入", defaultState = false },
            { row = 3, column = 2, IconID = "Interface\\Icons\\Spell_Shadow_Rainoffire", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0火焰之雨|r（一次性，放完自关）", saveVariable = "SS_HM_CRHYZY", section = "插入", defaultState = false },
            { row = 3, column = 3, IconID = "Interface\\Icons\\Spell_Shadow_Lifedrain", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0生命通道|r（给宠物回血，一次性，放完自关）", saveVariable = "SS_HM_CRSMTD", section = "插入", defaultState = false },
            { row = 3, column = 4, IconID = "Interface\\Icons\\Spell_Shadow_Burningspirit", text = "|cff9482C9插入|r", tooltipText = "插入|cff00adf0生命分流|r（一次性，放完自关）", saveVariable = "SS_HM_CRLTFL", section = "插入", defaultState = false },
            -- ===== 爆发（截图：种族爆发 + 全开/全关/切换）=====
            { row = 4, column = 1, IconID = 135727, text = "|cff9482C9种族爆|r", tooltipText = "自动使用|cff00adf0种族|r爆发技能（战斗中冷却好即用）", saveVariable = "SS_HM_ZDZZ", section = "爆发", defaultState = true },
        },
    },
}