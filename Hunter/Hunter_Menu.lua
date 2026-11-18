-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "HUNTER" then return end
-- ============================================================
-- Hunter_Menu.lua
-- 猎人菜单总表，包含三个专精的配置
-- 包含：野兽控制、射击、生存
-- ============================================================

--[[
if WR_PlayerClass ~= "HUNTER" then return end

    ★ Hunter_Menu 结构说明：
    DM（下拉菜单）：用于选择模式/阈值，保存为数字值
    CB（复选框）：用于开启/关闭功能，保存为布尔值
    每个专精独立配置，互不干扰
--]]

Hunter_Menu = {
    -- ==========================================================
    -- 1. 野兽控制专精 (Beast Mastery) —— 2026-11-16 按「猪猪 / 彼岸花-无限服 · 兽王页」重做
    -- ==========================================================
    ["野兽控制"] = {
        -- ===== 下拉菜单（DM） =====
        DM = {
            -- 防ADD开关
            {
                text = "|cffABD473防ADD|r",
                menuItems = { { text = "|cffABD473是|r" }, { text = "|cffABD473否|r" } },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_SWLR",
                defaultID = 1,
            },
            -- 共享冷却：瞄准射击 / 多重射击 共享 6 秒冷却，选优先项
            {
                text = "|cffABD473共享冷却|r",
                menuItems = { { text = "|cffABD473瞄准射击|r" }, { text = "|cffABD473多重射击|r" } },
                tooltipText = "瞄准射击与多重射击共享6秒冷却。选「瞄准射击」时优先打瞄准，选「多重射击」时优先打多重。",
                saveVariable = "LR_SWL_DCMZ",
                defaultID = 1,
            },
            -- 喝红药（拉条）
            {
                text = "|cffABD473喝红药|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 30,
                tooltipText = "血量低于该百分比时自动喝治疗药水（0 = 关闭，默认30）",
                saveVariable = "LR_SWL_HXY",
            },
            -- 爆发快捷按钮
            {
                text = "|cffABD473爆发全开|r",
                isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95,
                tooltipText = "一键打开 急速射击 / 狂野怒火 / 种族爆发",
                onClick = "WR_HunterBMBurstAllOn",
            },
            {
                text = "|cffABD473爆发全关|r",
                isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95,
                tooltipText = "一键关闭 急速射击 / 狂野怒火 / 种族爆发",
                onClick = "WR_HunterBMBurstAllOff",
            },
            {
                text = "|cffABD473爆发切换|r",
                isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95,
                tooltipText = "三个爆发开关任意一个开着就全关，全关就全开",
                onClick = "WR_HunterBMBurstToggle",
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 功能（右键图标打开额外条件）
            { row = 1, column = 1, IconID = "Interface\\Icons\\Ability_Marksmanship", text = "|cffABD473远程技能|r", tooltipText = "远程技能总开关：点图标展开右边一栏，这一页会自动放的远程技能（震荡射击、毒蛇钉刺、奥术射击、瞄准射击、多重射击、召唤雄鹰、狙击）一个一行，勾上的才放。\n\n柱顶的「远程技能」去掉勾 = 这些都不放，只留自动射击和近战技能，想留蓝或只想平射时关掉。\n\n猎人印记、急速射击和插入的技能不受影响。\n宏：/HUNTER_RANGED_BM 切换（后面加 on 开、off 关）", saveVariable = "LR_SWL_RANGED_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterBM then WR_HunterBM.ShowOptions("LR_SWL_RANGED_ON") end end },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Ability_Hunter_RaptorStrike", text = "|cffABD473近战技能|r", tooltipText = "近战技能总开关：点图标展开右边一栏，这一页会自动放的近战技能（猫鼬撕咬、摔绊、猛禽一击）一个一行，勾上的才放。\n\n柱顶的「近战技能」去掉勾 = 这些都不放，贴身时只留近战平砍，想把蓝留给远程技能时关掉。\n宏：/HUNTER_MELEE 切换（后面加 on 开、off 关）", saveVariable = "LR_SWL_MELEE_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterBM then WR_HunterBM.ShowOptions("LR_SWL_MELEE_ON") end end },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Ability_Hunter_BeastCall", text = "|cffABD473宠物|r", tooltipText = "宠物总开关：点图标展开右边一栏。\n\n召唤宠物：没有宠物就召唤；宠物死了就复活（下面选战斗中复活，还是脱战才复活）。\n\n治疗宠物：脱战宠物血量低于拉条就给它放治疗宠物。\n\n柱顶的「宠物」去掉勾 = 这些都不管。\n宏：/HUNTER_PET 切换（后面加 on 开、off 关）", saveVariable = "LR_SWL_PET_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterBM then WR_HunterBM.ShowOptions("LR_SWL_PET_ON") end end },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Ability_Hunter_SniperShot", text = "|cffABD473印记|r", tooltipText = "猎人印记总开关：目标身上没有猎人印记就自动补。\n\n右键：只打首领。\n宏：/HUNTER_MARK 切换（后面加 on 开、off 关）", saveVariable = "LR_SWL_MARK_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterBM then WR_HunterBM.ShowOptions("LR_SWL_MARK_ON") end end },
            { row = 2, column = 1, IconID = 132293, text = "|cffABD473切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标", saveVariable = "LR_SWL_TAB", section = "功能", defaultState = true },

            -- 爆发（截图：急速 / 狂野 / 种族爆发）
            { row = 1, column = 1, IconID = "Interface\\Icons\\Ability_Hunter_RapidKilling", text = "|cffABD473急速|r", tooltipText = "自动使用急速射击（CD 好且身上没有急速射击 buff 时）。\n右键：只打首领。\n宏：/HUNTER_RAPID 切换（后面加 on 开、off 关）", saveVariable = "LR_SWL_ZDJSSJ", section = "爆发", defaultState = true,
              onRightClick = function() if WR_HunterBM then WR_HunterBM.ShowOptions("LR_SWL_ZDJSSJ") end end },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Ability_Druid_FerociousBite", text = "|cffABD473狂野|r", tooltipText = "自动使用狂野怒火（宠物活着、CD 好且身上没有狂野怒火 buff 时）。\n右键：只打首领。\n宏：/HUNTER_BW 切换（后面加 on 开、off 关）", saveVariable = "LR_SWL_KYNH", section = "爆发", defaultState = true,
              onRightClick = function() if WR_HunterBM then WR_HunterBM.ShowOptions("LR_SWL_KYNH") end end },
            { row = 1, column = 3, IconID = 135727, text = "|cffABD473种族爆发|r", tooltipText = "自动使用种族爆发技能", saveVariable = "LR_SWL_ZDZZ", section = "爆发", defaultState = true },

            -- 插入（一次性，放完自关）
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Fire_Immolation", text = "|cffABD473献祭|r", tooltipText = "插入 献祭陷阱（一次性，放完自关）", saveVariable = "LR_SWL_CRXJ", section = "插入", defaultState = false },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Frost_FrostNova", text = "|cffABD473冰冻|r", tooltipText = "插入 冰冻陷阱（一次性，放完自关）", saveVariable = "LR_SWL_CRBD", section = "插入", defaultState = false },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Spell_Frost_FrostBolt02", text = "|cffABD473冰霜|r", tooltipText = "插入 冰霜陷阱（一次性，放完自关）", saveVariable = "LR_SWL_CRBS", section = "插入", defaultState = false },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Ability_GolemThunderClap", text = "|cffABD473震荡|r", tooltipText = "插入 震荡射击（一次性，放完自关）", saveVariable = "LR_SWL_CRZS", section = "插入", defaultState = false },
            { row = 2, column = 1, IconID = "Interface\\Icons\\Ability_Hunter_DistractingShot", text = "|cffABD473扰乱|r", tooltipText = "插入 扰乱射击（一次性，放完自关）", saveVariable = "LR_SWL_CRRL", section = "插入", defaultState = false },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Ability_Hunter_MendPet", text = "|cffABD473治疗|r", tooltipText = "插入 治疗宠物（一次性，放完自关）", saveVariable = "LR_SWL_CRZL", section = "插入", defaultState = false },
            { row = 2, column = 3, IconID = "Interface\\Icons\\Ability_Hunter_RapidKilling", text = "|cffABD473急速|r", tooltipText = "插入 急速射击（一次性，放完自关）", saveVariable = "LR_SWL_CRJSSJ", section = "插入", defaultState = false },
            { row = 2, column = 4, IconID = "Interface\\Icons\\Ability_Hunter_Flare", text = "|cffABD473照明|r", tooltipText = "插入 照明弹（一次性，放完自关）", saveVariable = "LR_SWL_CRZM", section = "插入", defaultState = false },
            { row = 3, column = 1, IconID = "Interface\\Icons\\Ability_Marksmanship", text = "|cffABD473乱射|r", tooltipText = "插入 乱射（一次性，放完自关）", saveVariable = "LR_SWL_CRLS", section = "插入", defaultState = false },
            { row = 3, column = 2, IconID = "Interface\\Icons\\Ability_Devour", text = "|cffABD473胁迫|r", tooltipText = "插入 胁迫（一次性，放完自关）", saveVariable = "LR_SWL_CRXP", section = "插入", defaultState = false },
            { row = 3, column = 3, IconID = "Interface\\Icons\\Ability_Druid_FerociousBite", text = "|cffABD473狂野|r", tooltipText = "插入 狂野怒火（一次性，放完自关）", saveVariable = "LR_SWL_CRKY", section = "插入", defaultState = false },
            { row = 3, column = 4, IconID = "Interface\\Icons\\Spell_Fire_Explosion", text = "|cffABD473爆炸陷阱|r", tooltipText = "插入 爆炸陷阱（一次性，放完自关）", saveVariable = "LR_SWL_CRBZXJ", section = "插入", defaultState = false },
            { row = 4, column = 1, IconID = "Interface\\Icons\\Ability_Rogue_FeignDeath", text = "|cffABD473假死|r", tooltipText = "插入 假死（一次性，放完自关）", saveVariable = "LR_SWL_CRJS", section = "插入", defaultState = false },
        },
    },

    -- ==========================================================
    -- 2. 射击专精 (Marksmanship) —— 2026-11-16 按「猪猪 / 彼岸花-无限服 · 射击页」重做
    -- ==========================================================
    ["射击"] = {
        -- ===== 下拉菜单（DM） =====
        DM = {
            -- 防ADD开关
            {
                text = "|cffABD473防ADD|r",
                menuItems = { { text = "|cffABD473是|r" }, { text = "|cffABD473否|r" } },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_SJLR",
                defaultID = 1,
            },
            -- 共享冷却：瞄准射击 / 多重射击 共享 6 秒冷却，选优先项
            {
                text = "|cffABD473共享冷却|r",
                menuItems = { { text = "|cffABD473瞄准射击|r" }, { text = "|cffABD473多重射击|r" } },
                tooltipText = "瞄准射击与多重射击共享6秒冷却。选「瞄准射击」时优先打瞄准，选「多重射击」时优先打多重。",
                saveVariable = "LR_SJL_DCMZ",
                defaultID = 1,
            },
            -- 喝红药（拉条）
            {
                text = "|cffABD473喝红药|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 30,
                tooltipText = "血量低于该百分比时自动喝治疗药水（0 = 关闭，默认30）",
                saveVariable = "LR_SJL_HXY",
            },
            -- 爆发快捷按钮
            {
                text = "|cffABD473爆发全开|r",
                isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95,
                tooltipText = "一键打开 急速射击 / 种族爆发",
                onClick = "WR_HunterMMBurstAllOn",
            },
            {
                text = "|cffABD473爆发全关|r",
                isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95,
                tooltipText = "一键关闭 急速射击 / 种族爆发",
                onClick = "WR_HunterMMBurstAllOff",
            },
            {
                text = "|cffABD473爆发切换|r",
                isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95,
                tooltipText = "两个爆发开关任意一个开着就全关，全关就全开",
                onClick = "WR_HunterMMBurstToggle",
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 功能（右键图标打开额外条件）
            { row = 1, column = 1, IconID = "Interface\\Icons\\Ability_Marksmanship", text = "|cffABD473远程技能|r", tooltipText = "远程技能总开关：点图标展开右边一栏，这一页会自动放的远程技能（震荡射击、毒蛇钉刺、奥术射击、瞄准射击、多重射击、召唤雄鹰、狙击）一个一行，勾上的才放。\n\n柱顶的「远程技能」去掉勾 = 这些都不放，只留自动射击和近战技能，想留蓝或只想平射时关掉。\n\n猎人印记、急速射击和插入的技能不受影响。\n宏：/HUNTER_RANGED_MM 切换（后面加 on 开、off 关）", saveVariable = "LR_SJL_RANGED_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterMM then WR_HunterMM.ShowOptions("LR_SJL_RANGED_ON") end end },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Ability_Hunter_RaptorStrike", text = "|cffABD473近战技能|r", tooltipText = "近战技能总开关：点图标展开右边一栏，这一页会自动放的近战技能（猫鼬撕咬、摔绊、猛禽一击）一个一行，勾上的才放。\n\n柱顶的「近战技能」去掉勾 = 这些都不放，贴身时只留近战平砍，想把蓝留给远程技能时关掉。\n宏：/HUNTER_MELEE 切换（后面加 on 开、off 关）", saveVariable = "LR_SJL_MELEE_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterMM then WR_HunterMM.ShowOptions("LR_SJL_MELEE_ON") end end },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Ability_Hunter_BeastCall", text = "|cffABD473宠物|r", tooltipText = "宠物总开关：点图标展开右边一栏。\n\n召唤宠物：没有宠物就召唤；宠物死了就复活（下面选战斗中复活，还是脱战才复活）。\n\n治疗宠物：脱战宠物血量低于拉条就给它放治疗宠物。\n\n柱顶的「宠物」去掉勾 = 这些都不管。\n宏：/HUNTER_PET 切换（后面加 on 开、off 关）", saveVariable = "LR_SJL_PET_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterMM then WR_HunterMM.ShowOptions("LR_SJL_PET_ON") end end },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Ability_Hunter_SniperShot", text = "|cffABD473印记|r", tooltipText = "猎人印记总开关：目标身上没有猎人印记就自动补。\n\n右键：只打首领。\n宏：/HUNTER_MARK 切换（后面加 on 开、off 关）", saveVariable = "LR_SJL_MARK_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterMM then WR_HunterMM.ShowOptions("LR_SJL_MARK_ON") end end },
            { row = 2, column = 1, IconID = 132293, text = "|cffABD473切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标", saveVariable = "LR_SJL_TAB", section = "功能", defaultState = true },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Ability_Hunter_SniperShot", text = "|cffABD473强击|r", tooltipText = "强击光环总开关：自己身上没有强击光环就自动补（30 分钟团队攻强增益）。\n\n右键：额外条件。\n宏：/HUNTER_QS 切换（后面加 on 开、off 关）", saveVariable = "LR_SJL_QSGH_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterMM then WR_HunterMM.ShowOptions("LR_SJL_QSGH_ON") end end },

            -- 爆发（截图：急速 / 种族爆发）
            { row = 1, column = 1, IconID = "Interface\\Icons\\Ability_Hunter_RapidKilling", text = "|cffABD473急速|r", tooltipText = "自动使用急速射击（CD 好且身上没有急速射击 buff 时）。\n右键：只打首领。\n宏：/HUNTER_RAPID 切换（后面加 on 开、off 关）", saveVariable = "LR_SJL_ZDJSSJ", section = "爆发", defaultState = true,
              onRightClick = function() if WR_HunterMM then WR_HunterMM.ShowOptions("LR_SJL_ZDJSSJ") end end },
            { row = 1, column = 2, IconID = 135727, text = "|cffABD473种族爆发|r", tooltipText = "自动使用种族爆发技能", saveVariable = "LR_SJL_ZDZZ", section = "爆发", defaultState = true },

            -- 插入（一次性，放完自关）
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Fire_Immolation", text = "|cffABD473献祭|r", tooltipText = "插入 献祭陷阱（一次性，放完自关）", saveVariable = "LR_SJL_CRXJ", section = "插入", defaultState = false },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Frost_FrostNova", text = "|cffABD473冰冻|r", tooltipText = "插入 冰冻陷阱（一次性，放完自关）", saveVariable = "LR_SJL_CRBD", section = "插入", defaultState = false },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Spell_Frost_FrostBolt02", text = "|cffABD473冰霜|r", tooltipText = "插入 冰霜陷阱（一次性，放完自关）", saveVariable = "LR_SJL_CRBS", section = "插入", defaultState = false },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Ability_GolemThunderClap", text = "|cffABD473震荡|r", tooltipText = "插入 震荡射击（一次性，放完自关）", saveVariable = "LR_SJL_CRZS", section = "插入", defaultState = false },
            { row = 2, column = 1, IconID = "Interface\\Icons\\Ability_Hunter_DistractingShot", text = "|cffABD473扰乱|r", tooltipText = "插入 扰乱射击（一次性，放完自关）", saveVariable = "LR_SJL_CRRL", section = "插入", defaultState = false },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Ability_Hunter_MendPet", text = "|cffABD473治疗|r", tooltipText = "插入 治疗宠物（一次性，放完自关）", saveVariable = "LR_SJL_CRZL", section = "插入", defaultState = false },
            { row = 2, column = 3, IconID = "Interface\\Icons\\Ability_Hunter_RapidKilling", text = "|cffABD473急速|r", tooltipText = "插入 急速射击（一次性，放完自关）", saveVariable = "LR_SJL_CRJSSJ", section = "插入", defaultState = false },
            { row = 2, column = 4, IconID = "Interface\\Icons\\Ability_Hunter_Flare", text = "|cffABD473照明|r", tooltipText = "插入 照明弹（一次性，放完自关）", saveVariable = "LR_SJL_CRZM", section = "插入", defaultState = false },
            { row = 3, column = 1, IconID = "Interface\\Icons\\Ability_Marksmanship", text = "|cffABD473乱射|r", tooltipText = "插入 乱射（一次性，放完自关）", saveVariable = "LR_SJL_CRLS", section = "插入", defaultState = false },
            { row = 3, column = 2, IconID = "Interface\\Icons\\Spell_Fire_Explosion", text = "|cffABD473爆炸陷阱|r", tooltipText = "插入 爆炸陷阱（一次性，放完自关）", saveVariable = "LR_SJL_CRBZXJ", section = "插入", defaultState = false },
            { row = 3, column = 3, IconID = "Interface\\Icons\\Ability_Rogue_FeignDeath", text = "|cffABD473假死|r", tooltipText = "插入 假死（一次性，放完自关）", saveVariable = "LR_SJL_CRJS", section = "插入", defaultState = false },
        },
    },

    -- ==========================================================
    -- ==========================================================
    -- 3. 生存专精 (Survival) —— 2026-11-16 按「猪猪 / 彼岸花-无限服 · 生存页」重做
    -- ==========================================================
    ["生存"] = {
        -- ===== 下拉菜单（DM） =====
        DM = {
            -- 防ADD开关
            {
                text = "|cffABD473防ADD|r",
                menuItems = { { text = "|cffABD473是|r" }, { text = "|cffABD473否|r" } },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_SCLR",
                defaultID = 1,
            },
            -- 共享冷却：瞄准射击 / 多重射击 共享 6 秒冷却，选优先项
            {
                text = "|cffABD473共享冷却|r",
                menuItems = { { text = "|cffABD473瞄准射击|r" }, { text = "|cffABD473多重射击|r" } },
                tooltipText = "瞄准射击与多重射击共享6秒冷却。选「瞄准射击」时优先打瞄准，选「多重射击」时优先打多重。",
                saveVariable = "LR_SCL_DCMZ",
                defaultID = 1,
            },
            -- 喝红药（拉条）
            {
                text = "|cffABD473喝红药|r",
                isSlider = true, minValue = 0, maxValue = 100, valueStep = 5,
                defaultVal = 30,
                tooltipText = "血量低于该百分比时自动喝治疗药水（0 = 关闭，默认30）",
                saveVariable = "LR_SCL_HXY",
            },
            -- 爆发快捷按钮
            {
                text = "|cffABD473爆发全开|r",
                isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95,
                tooltipText = "一键打开 急速射击 / 种族爆发",
                onClick = "WR_HunterSVBurstAllOn",
            },
            {
                text = "|cffABD473爆发全关|r",
                isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95,
                tooltipText = "一键关闭 急速射击 / 种族爆发",
                onClick = "WR_HunterSVBurstAllOff",
            },
            {
                text = "|cffABD473爆发切换|r",
                isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95,
                tooltipText = "两个爆发开关任意一个开着就全关，全关就全开",
                onClick = "WR_HunterSVBurstToggle",
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 功能（右键图标打开额外条件）
            { row = 1, column = 1, IconID = "Interface\\Icons\\Ability_Marksmanship", text = "|cffABD473远程技能|r", tooltipText = "远程技能总开关：点图标展开右边一栏，这一页会自动放的远程技能（震荡射击、毒蛇钉刺、奥术射击、瞄准射击、多重射击、狙击）一个一行，勾上的才放。\n\n柱顶的「远程技能」去掉勾 = 这些都不放，只留自动射击和近战技能，想留蓝或只想平射时关掉。\n\n猎人印记、急速射击和插入的技能不受影响。\n宏：/HUNTER_RANGED_SV 切换（后面加 on 开、off 关）", saveVariable = "LR_SCL_RANGED_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterSV then WR_HunterSV.ShowOptions("LR_SCL_RANGED_ON") end end },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Ability_Hunter_RaptorStrike", text = "|cffABD473近战技能|r", tooltipText = "近战技能总开关：点图标展开右边一栏，这一页会自动放的近战技能（反击、猫鼬撕咬、陆行鸟踢击、摔绊、猛禽一击）一个一行，勾上的才放。\n\n柱顶的「近战技能」去掉勾 = 这些都不放，贴身时只留近战平砍，想把蓝留给远程技能时关掉。\n宏：/HUNTER_MELEE 切换（后面加 on 开、off 关）", saveVariable = "LR_SCL_MELEE_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterSV then WR_HunterSV.ShowOptions("LR_SCL_MELEE_ON") end end },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Ability_Hunter_BeastCall", text = "|cffABD473宠物|r", tooltipText = "宠物总开关：点图标展开右边一栏。\n\n召唤宠物：没有宠物就召唤；宠物死了就复活（下面选战斗中复活，还是脱战才复活）。\n\n治疗宠物：脱战宠物血量低于拉条就给它放治疗宠物。\n\n柱顶的「宠物」去掉勾 = 这些都不管。\n宏：/HUNTER_PET 切换（后面加 on 开、off 关）", saveVariable = "LR_SCL_PET_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterSV then WR_HunterSV.ShowOptions("LR_SCL_PET_ON") end end },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Ability_Hunter_SniperShot", text = "|cffABD473印记|r", tooltipText = "猎人印记总开关：目标身上没有猎人印记就自动补。\n\n右键：只打首领。\n宏：/HUNTER_MARK 切换（后面加 on 开、off 关）", saveVariable = "LR_SCL_MARK_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_HunterSV then WR_HunterSV.ShowOptions("LR_SCL_MARK_ON") end end },
            { row = 2, column = 1, IconID = 132293, text = "|cffABD473切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标", saveVariable = "LR_SCL_TAB", section = "功能", defaultState = true },

            -- 爆发（截图：急速 / 种族爆发）
            { row = 1, column = 1, IconID = "Interface\\Icons\\Ability_Hunter_RapidKilling", text = "|cffABD473急速|r", tooltipText = "自动使用急速射击（CD 好且身上没有急速射击 buff 时）。\n右键：只打首领。\n宏：/HUNTER_RAPID 切换（后面加 on 开、off 关）", saveVariable = "LR_SCL_ZDJSSJ", section = "爆发", defaultState = true,
              onRightClick = function() if WR_HunterSV then WR_HunterSV.ShowOptions("LR_SCL_ZDJSSJ") end end },
            { row = 1, column = 2, IconID = 135727, text = "|cffABD473种族爆发|r", tooltipText = "自动使用种族爆发技能", saveVariable = "LR_SCL_ZDZZ", section = "爆发", defaultState = true },

            -- 插入（一次性，放完自关）
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Fire_Immolation", text = "|cffABD473献祭|r", tooltipText = "插入 献祭陷阱（一次性，放完自关）", saveVariable = "LR_SCL_CRXJ", section = "插入", defaultState = false },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Frost_FrostNova", text = "|cffABD473冰冻|r", tooltipText = "插入 冰冻陷阱（一次性，放完自关）", saveVariable = "LR_SCL_CRBD", section = "插入", defaultState = false },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Spell_Frost_FrostBolt02", text = "|cffABD473冰霜|r", tooltipText = "插入 冰霜陷阱（一次性，放完自关）", saveVariable = "LR_SCL_CRBS", section = "插入", defaultState = false },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Ability_GolemThunderClap", text = "|cffABD473震荡|r", tooltipText = "插入 震荡射击（一次性，放完自关）", saveVariable = "LR_SCL_CRZS", section = "插入", defaultState = false },
            { row = 2, column = 1, IconID = "Interface\\Icons\\Ability_Hunter_DistractingShot", text = "|cffABD473扰乱|r", tooltipText = "插入 扰乱射击（一次性，放完自关）", saveVariable = "LR_SCL_CRRL", section = "插入", defaultState = false },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Ability_Hunter_MendPet", text = "|cffABD473治疗|r", tooltipText = "插入 治疗宠物（一次性，放完自关）", saveVariable = "LR_SCL_CRZL", section = "插入", defaultState = false },
            { row = 2, column = 3, IconID = "Interface\\Icons\\Ability_Hunter_RapidKilling", text = "|cffABD473急速|r", tooltipText = "插入 急速射击（一次性，放完自关）", saveVariable = "LR_SCL_CRJSSJ", section = "插入", defaultState = false },
            { row = 2, column = 4, IconID = "Interface\\Icons\\Ability_Hunter_Flare", text = "|cffABD473照明|r", tooltipText = "插入 照明弹（一次性，放完自关）", saveVariable = "LR_SCL_CRZM", section = "插入", defaultState = false },
            { row = 3, column = 1, IconID = "Interface\\Icons\\Ability_Marksmanship", text = "|cffABD473乱射|r", tooltipText = "插入 乱射（一次性，放完自关）", saveVariable = "LR_SCL_CRLS", section = "插入", defaultState = false },
            { row = 3, column = 2, IconID = "Interface\\Icons\\Spell_Fire_Explosion", text = "|cffABD473爆炸陷阱|r", tooltipText = "插入 爆炸陷阱（一次性，放完自关）", saveVariable = "LR_SCL_CRBZXJ", section = "插入", defaultState = false },
            { row = 3, column = 3, IconID = "Interface\\Icons\\Ability_Rogue_FeignDeath", text = "|cffABD473假死|r", tooltipText = "插入 假死（一次性，放完自关）", saveVariable = "LR_SCL_CRJS", section = "插入", defaultState = false },
        },
    },
}