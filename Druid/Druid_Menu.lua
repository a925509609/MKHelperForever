-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "DRUID" then return end
-- ============================================================
-- Druid_Menu.lua
-- 德鲁伊菜单总表
-- 包含四个专精：平衡、野性战斗、恢复、野性、守护
-- 每个专精包含 DM（下拉菜单）和 CB（复选框）两种配置
-- ============================================================

--[[
if WR_PlayerClass ~= "DRUID" then return end

    ★ Druid_Menu 结构说明：
    DM（下拉菜单）：用于选择模式/阈值，保存为数字值
    CB（复选框）：用于开启/关闭功能，保存为布尔值
    每个专精独立配置，互不干扰
--]]

Druid_Menu = {
    -- ==========================================================
    -- 1. 平衡专精（鸟德）—— 2026-11-15 按「彼岸花-无限服 · 平衡页」重做（Forever 60级）
    -- ==========================================================
    ["平衡"] = {
        -- ===== 下拉菜单（DM）：选择 / 拉条 / 爆发按钮 =====
        DM = {
            -- 防ADD开关
            {
                text = "|cffFF7D0A防ADD|r",
                menuItems = { { text = "|cffFF7D0A是|r" }, { text = "|cffFF7D0A否|r" } },
                tooltipText = "是否开启防ADD：打开时，需要目标进入战斗才会主动攻击",
                saveVariable = "FANG_ADD_PH",
                defaultID = 1
            },
            -- 拉条：喝红药
            { text = "|cffFF7D0A喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 10, defaultVal = 30,
              tooltipText = "自己血量低于该百分比时自动喝治疗药水（0 = 关闭）", saveVariable = "PH_HXY" },
            -- 爆发快捷按钮
            { text = "|cffFF7D0A爆发全开|r", isButton = true, buttonText = "全开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开 种族爆发", onClick = "WR_DruidBalanceBurstAllOn" },
            { text = "|cffFF7D0A爆发全关|r", isButton = true, buttonText = "全关", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭 种族爆发", onClick = "WR_DruidBalanceBurstAllOff" },
            { text = "|cffFF7D0A爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "种族爆发开着就全关，全关就全开", onClick = "WR_DruidBalanceBurstToggle" },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- ===== 功能（截图 8 个图标，默认全勾） =====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Nature_ForceOfNature", text = "|cffFF7D0A枭兽|r", tooltipText = "没有枭兽形态时自动补（平衡天赋，未学会自动跳过）", saveVariable = "PH_XN", section = "功能", defaultState = true },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Nature_InsectSwarm", text = "|cffFF7D0ADOT|r", tooltipText = "按右键设置给目标上月火术、虫群。\n右键：月火术 / 虫群 / 预判秒数", saveVariable = "PH_DOT", section = "功能", defaultState = true,
              onRightClick = function() if WR_DruidBalanceUI then WR_DruidBalanceUI.ShowOptions("PH_DOT") end end },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Spell_Nature_Regeneration", text = "|cffFF7D0A野性印记|r", tooltipText = "自己身上没有野性印记/野性赐福时自动补", saveVariable = "PH_YXYZ", section = "功能", defaultState = true },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Spell_Nature_Reincarnation", text = "|cffFF7D0A复生|r", tooltipText = "队友死亡时自动选中并复生（40 码内）", saveVariable = "PH_FS", section = "功能", defaultState = true },
            { row = 2, column = 1, IconID = "Interface\\Icons\\Spell_Nature_Lightning", text = "|cffFF7D0A激活|r", tooltipText = "蓝量低于阈值时给自己激活；焦点队友蓝量低时给焦点激活。\n右键：开关 / 蓝量阈值", saveVariable = "PH_JH_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_DruidBalanceUI then WR_DruidBalanceUI.ShowOptions("PH_JH_ON") end end },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Spell_Nature_Thorns", text = "|cffFF7D0A荆棘术|r", tooltipText = "自己身上没有荆棘术时自动补", saveVariable = "PH_JJS", section = "功能", defaultState = true },
            { row = 2, column = 3, IconID = 132293, text = "|cffFF7D0A切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标", saveVariable = "PH_TAB", section = "功能", defaultState = true },
            { row = 2, column = 4, IconID = "Interface\\Icons\\Spell_Nature_RemoveCurse", text = "|cffFF7D0A驱散|r", tooltipText = "自动解除自己/焦点/队友身上的诅咒", saveVariable = "PH_QS", section = "功能", defaultState = true },

            -- ===== 爆发（默认和截图一致：种族爆发勾选） =====
            { row = 1, column = 1, IconID = 135727, text = "|cffFF7D0A种族爆发|r", tooltipText = "自动使用种族爆发技能", saveVariable = "PH_ZDZZ", section = "爆发", defaultState = true },

            -- ===== 插入（一次性，放完自关） =====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Nature_Cyclone", text = "|cffFF7D0A飓风|r", tooltipText = "插入 飓风（一次性，施放后自关）", saveVariable = "PH_CRJF", section = "插入", defaultState = false },
        },
    },

    -- ==========================================================
    -- 2. 野性战斗专精（野德/猫德/熊德）—— 2026-11-16 按「彼岸花-无限服 · 野性页」重做（Forever 60级）
    -- ==========================================================
    ["野性战斗"] = {
        -- ===== 下拉菜单（DM）：选择 / 拉条 / 爆发按钮 =====
        DM = {
            {
                text = "|cffFF7D0A防ADD|r",
                menuItems = { { text = "|cffFF7D0A是|r" }, { text = "|cffFF7D0A否|r" } },
                tooltipText = "是否开启防ADD：打开时，需要目标进入战斗才会主动攻击",
                saveVariable = "FANG_ADD_YD",
                defaultID = 1,
            },
            {
                text = "|cffFF7D0A形态|r",
                menuItems = { { text = "|cffFF7D0A猫形态|r" }, { text = "|cffFF7D0A熊形态|r" } },
                tooltipText = "选择野德形态\n猫形态：输出循环\n熊形态：坦克循环",
                saveVariable = "YD_XTXZ",
                defaultID = 1,
            },
            -- 拉条：喝红药
            { text = "|cffFF7D0A喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 10, defaultVal = 30,
              tooltipText = "自己血量低于该百分比时自动喝治疗药水（0 = 关闭）", saveVariable = "YD_HXY" },
            -- 拉条：猫专属 猛虎之怒
            { text = "|cffFF7D0A猛虎之怒|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30,
              tooltipText = "猫专属：能量低于该百分比时使用猛虎之怒（0 = 关闭）", saveVariable = "YD_MHZN_NL" },
            -- 拉条：熊专属 槌击 / 狂暴回复
            { text = "|cffFF7D0A槌击|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 25,
              tooltipText = "熊专属：怒气高于该百分比时用槌击倾泻怒气（0 = 关闭）", saveVariable = "YD_CJ_NL" },
            { text = "|cffFF7D0A狂暴回复|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 40,
              tooltipText = "熊专属：自己血量低于该百分比时使用狂暴回复（0 = 关闭）", saveVariable = "YD_KBHF_HP" },
            -- 爆发快捷按钮
            { text = "|cffFF7D0A爆发全开|r", isButton = true, buttonText = "全开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开 狂暴 / 种族爆发", onClick = "WR_DruidFeralBurstAllOn" },
            { text = "|cffFF7D0A爆发全关|r", isButton = true, buttonText = "全关", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭 狂暴 / 种族爆发", onClick = "WR_DruidFeralBurstAllOff" },
            { text = "|cffFF7D0A爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "狂暴/种族爆发都开着就全关，否则全开", onClick = "WR_DruidFeralBurstToggle" },
        },
        CB = {
            -- ===== 功能：通用 3 个 =====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Ability_Druid_CatForm", text = "|cffFF7D0A变形|r", tooltipText = "按「形态」选择自动补猎豹形态/巨熊形态", saveVariable = "YD_BX", section = "功能", defaultState = true },
            { row = 1, column = 2, IconID = 132293, text = "|cffFF7D0A切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标", saveVariable = "YD_TAB", section = "功能", defaultState = true },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Spell_Nature_FaerieFire", text = "|cffFF7D0A精灵之火|r", tooltipText = "目标没有精灵之火（野性）时自动补", saveVariable = "YD_JLZF", section = "功能", defaultState = true },
            -- ===== 功能：猫专属 4 个 =====
            { row = 2, column = 1, IconID = "Interface\\Icons\\Ability_Druid_Swipe", text = "|cffFF7D0A扫击|r", tooltipText = "猫专属：8 码内 3+ 目标时使用扫击（AoE）", saveVariable = "YD_SJ", section = "功能", defaultState = true },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Ability_Druid_FerociousBite", text = "|cffFF7D0A终结技|r", tooltipText = "猫专属：维持 5 星割裂；目标快死/低血时用凶猛撕咬", saveVariable = "YD_ZJJ", section = "功能", defaultState = true },
            { row = 2, column = 3, IconID = "Interface\\Icons\\Spell_Druid_Displacement", text = "|cffFF7D0A变形之力|r", tooltipText = "猫专属：能量不溢出时使用变形之力（8 秒 CD，法力换 40 能量）", saveVariable = "YD_BXZL", section = "功能", defaultState = true },
            { row = 2, column = 4, IconID = "Interface\\Icons\\Ability_Druid_Mangle", text = "|cffFF7D0A正面|r", tooltipText = "猫专属：不能打背时允许用爪击正面输出", saveVariable = "YD_ZM", section = "功能", defaultState = true },
            -- ===== 功能：熊专属 8 个 =====
            { row = 3, column = 1, IconID = "Interface\\Icons\\Ability_Druid_DemoralizingRoar", text = "|cffFF7D0A挫志咆哮|r", tooltipText = "熊专属：目标没有挫志咆哮时自动补", saveVariable = "YD_CZPX", section = "功能", defaultState = true },
            { row = 3, column = 2, IconID = "Interface\\Icons\\Ability_Druid_Maul", text = "|cffFF7D0A挥击|r", tooltipText = "熊专属：8 码内 3+ 目标时使用挥击（AoE）", saveVariable = "YD_HJ", section = "功能", defaultState = true },
            { row = 3, column = 3, IconID = "Interface\\Icons\\Ability_Druid_Lacerate", text = "|cffFF7D0A割伤|r", tooltipText = "熊专属：割伤剩余小于 5 秒就补，保持 5 层", saveVariable = "YD_GS", section = "功能", defaultState = true },
            { row = 3, column = 4, IconID = "Interface\\Icons\\Ability_Physical_Taunt", text = "|cffFF7D0A嘲讽|r", tooltipText = "熊专属：目标不在打自己时用低吼嘲讽（默认关闭）", saveVariable = "YD_CS", section = "功能", defaultState = false },
            { row = 4, column = 1, IconID = "Interface\\Icons\\Spell_Nature_Regeneration", text = "|cffFF7D0A野性印记|r", tooltipText = "自己身上没有野性印记/野性赐福时自动补", saveVariable = "YD_YXYZ", section = "功能", defaultState = true },
            { row = 4, column = 2, IconID = "Interface\\Icons\\Spell_Nature_Reincarnation", text = "|cffFF7D0A复生|r", tooltipText = "队友死亡时自动选中并复生（40 码内）", saveVariable = "YD_FS", section = "功能", defaultState = true },
            { row = 4, column = 3, IconID = "Interface\\Icons\\Spell_Nature_Lightning", text = "|cffFF7D0A激活|r", tooltipText = "自己/焦点蓝量低于阈值时使用激活", saveVariable = "YD_JH_ON", section = "功能", defaultState = true },
            { row = 4, column = 4, IconID = "Interface\\Icons\\Spell_Nature_Thorns", text = "|cffFF7D0A荆棘术|r", tooltipText = "自己身上没有荆棘术时自动补", saveVariable = "YD_JJS", section = "功能", defaultState = true },

            -- ===== 爆发（截图默认两项都勾） =====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Ability_Druid_Berserk", text = "|cffFF7D0A狂暴|r", tooltipText = "自动使用狂暴（爆发）", saveVariable = "YD_KB", section = "爆发", defaultState = true },
            { row = 1, column = 2, IconID = 135727, text = "|cffFF7D0A种族爆发|r", tooltipText = "自动使用种族爆发技能", saveVariable = "YD_ZDZZ", section = "爆发", defaultState = true },

            -- ===== 插入（熊专属，一次性放完自关） =====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Ability_Druid_FeralCharge", text = "|cffFF7D0A冲锋|r", tooltipText = "插入 野性冲锋（一次性，施放后自关）", saveVariable = "YD_CF", section = "插入", defaultState = false },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Ability_Druid_ChallengingRoar", text = "|cffFF7D0A群嘲|r", tooltipText = "插入 挑战咆哮（一次性，施放后自关）", saveVariable = "YD_QC", section = "插入", defaultState = false },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Ability_Druid_Bash", text = "|cffFF7D0A重击|r", tooltipText = "插入 重击（一次性，施放后自关）", saveVariable = "YD_ZJ", section = "插入", defaultState = false },
        },
    },
    -- ==========================================================
    -- 3. 恢复专精（奶德）—— 2026-11-16 按「彼岸花-无限服 · 恢复页」重做（Forever 60级）
    -- ==========================================================
    ["恢复"] = {
        -- ===== 下拉菜单（DM）：选择 / 拉条 / 爆发按钮 =====
        DM = {
            {
                text = "|cffFF7D0A防ADD|r",
                menuItems = { { text = "|cffFF7D0A是|r" }, { text = "|cffFF7D0A否|r" } },
                tooltipText = "是否开启防ADD：打开时，需要自己进入战斗才会主动治疗；关闭时队友战斗中也会治疗",
                saveVariable = "FANG_ADD_HF",
                defaultID = 1,
            },
            {
                text = "|cffFF7D0A治疗模式|r",
                menuItems = {
                    { text = "|cffFF7D0A全团|r" },
                    { text = "|cffFF7D0A目标|r" },
                    { text = "|cffFF7D0A预读|r" },
                    { text = "|cffFF7D0A坦克|r" },
                    { text = "|cffFF7D0A脆皮|r" },
                    { text = "|cffFF7D0A一队|r" },
                    { text = "|cffFF7D0A二队|r" },
                    { text = "|cffFF7D0A三队|r" },
                    { text = "|cffFF7D0A四队|r" },
                    { text = "|cffFF7D0A五队|r" },
                },
                tooltipText = "|cff00adf0全团：自动治疗所有单位，切目标不影响治疗。|r\n|cffffd700目标：有目标时只治疗目标，无目标则治疗全团。|r\n|cffadff2f预读：有目标时只治疗目标，无目标则治疗全团。|r\n|cff996b1f坦克：仅治疗坦克职责。|r\n|cff9C3590脆皮：仅治疗非坦克单位。|r\n|cfffdffb6一队~五队：仅治疗对应小队（仅团队中生效）。|r",
                saveVariable = "HF_TREAT_MODE",
                defaultID = 1,
            },
            -- 拉条
            { text = "|cffFF7D0A喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30,
              tooltipText = "自己血量低于该百分比时自动喝治疗药水（0 = 关闭）", saveVariable = "HF_HXY" },
            { text = "|cffFF7D0A迅捷治触|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30,
              tooltipText = "目标血量低于该百分比时，用自然迅捷 + 治疗之触急救（0 = 关闭）", saveVariable = "HF_ZRXJ_HP" },
            { text = "|cffFF7D0A迅捷治愈|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50,
              tooltipText = "目标血量低于该百分比且身上有回春/愈合时用迅捷治愈（0 = 关闭）", saveVariable = "HF_XJZY" },
            { text = "|cffFF7D0A野性成长|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 80,
              tooltipText = "群体 HOT：低血人数≥2 且目标血量低于该百分比时使用（0 = 关闭）", saveVariable = "HF_YZCZ" },
            { text = "|cffFF7D0A回春术|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 95,
              tooltipText = "目标血量低于该百分比且没有回春术时补 HOT（0 = 关闭）", saveVariable = "HF_HCS" },
            { text = "|cffFF7D0A治疗之触|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 60,
              tooltipText = "目标血量低于该百分比时用大治疗治疗之触（0 = 关闭）", saveVariable = "HF_ZLZC" },
            { text = "|cffFF7D0A愈合|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 85,
              tooltipText = "目标血量低于该百分比时用愈合（0 = 关闭）", saveVariable = "HF_YH_HP" },
            -- 爆发快捷按钮
            { text = "|cffFF7D0A爆发全开|r", isButton = true, buttonText = "全开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开 种族爆发", onClick = "WR_DruidRestorationBurstAllOn" },
            { text = "|cffFF7D0A爆发全关|r", isButton = true, buttonText = "全关", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭 种族爆发", onClick = "WR_DruidRestorationBurstAllOff" },
            { text = "|cffFF7D0A爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "种族爆发开着就全关，全关就全开", onClick = "WR_DruidRestorationBurstToggle" },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- ===== 功能（截图 6 个图标，默认全勾） =====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Nature_Regeneration", text = "|cffFF7D0A野性印记|r", tooltipText = "自己身上没有野性印记/野性赐福时自动补", saveVariable = "HF_YXYZ", section = "功能", defaultState = true },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Nature_Reincarnation", text = "|cffFF7D0A复生|r", tooltipText = "队友死亡时自动选中并复生（40 码内）", saveVariable = "HF_FS", section = "功能", defaultState = true },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Spell_Nature_Lightning", text = "|cffFF7D0A激活|r", tooltipText = "蓝量低于阈值时给自己激活；焦点队友蓝量低时给焦点激活。\n右键：开关 / 蓝量阈值", saveVariable = "HF_JH_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_DruidRestorationUI then WR_DruidRestorationUI.ShowOptions("HF_JH_ON") end end },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Spell_Nature_Thorns", text = "|cffFF7D0A荆棘术|r", tooltipText = "自己身上没有荆棘术时自动补", saveVariable = "HF_JJS", section = "功能", defaultState = true },
            { row = 2, column = 1, IconID = 132293, text = "|cffFF7D0A切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标", saveVariable = "HF_TAB", section = "功能", defaultState = true },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Spell_Nature_RemoveCurse", text = "|cffFF7D0A驱散|r", tooltipText = "自动解除自己/焦点/队友身上的诅咒", saveVariable = "HF_QS_ON", section = "功能", defaultState = true },

            -- ===== 爆发（截图默认勾选） =====
            { row = 1, column = 1, IconID = 135727, text = "|cffFF7D0A种族爆发|r", tooltipText = "自动使用种族爆发技能", saveVariable = "HF_ZDZZ", section = "爆发", defaultState = true },

            -- ===== 插入（一次性，放完自关） =====
            { row = 1, column = 1, IconID = 136107, text = "|cffFF7D0A宁静|r", tooltipText = "插入 宁静（团队≥4人 / 小队≥3人低于45%时施放，放完自关）", saveVariable = "HF_NJ_CR", showSpell = "宁静", section = "插入", defaultState = false },
        },
    },

    -- ==========================================================
    -- 4. 野性专精（占位/模版）
    -- 注：此专精在正式服已合并，仅保留模版配置
    -- ==========================================================
    ["野性"] = {
        DM = {
            {
                text = "|cffFF7D0A模版|r",
                menuItems = { { text = "|cffFF7D0A模版1|r" }, { text = "|cffFF7D0A模版2|r" } },
                tooltipText = "模版提示",
                saveVariable = "YX_MBDM",
                defaultID = 1,
            },
        },
        CB = {
            { row = 1, column = 1, IconID = 135962, text = "|cffFF7D0A模版|r", tooltipText = "模版提示", saveVariable = "YX_MBCB", defaultState = true },
        },
    },

    -- ==========================================================
    -- 5. 守护专精（占位/模版）
    -- 注：此专精在正式服已合并，仅保留模版配置
    -- ==========================================================
    ["守护"] = {
        DM = {
            {
                text = "|cffFF7D0A模版|r",
                menuItems = { { text = "|cffFF7D0A模版1|r" }, { text = "|cffFF7D0A模版2|r" } },
                tooltipText = "模版提示",
                saveVariable = "SH_MBDM",
                defaultID = 1,
            },
        },
        CB = {
            { row = 1, column = 1, IconID = 135962, text = "|cffFF7D0A模版|r", tooltipText = "模版提示", saveVariable = "SH_MBCB", defaultState = true },
        },
    },
}