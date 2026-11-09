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
    -- 1. 平衡专精（鸟德 / 月神轨道炮流）
    -- ==========================================================
    ["平衡"] = {
        -- ===== 下拉菜单（DM） =====
        DM = {
            -- 防ADD开关
            {
                text = "|cffFF7D0A防ADD|r",
                menuItems = { { text = "|cffFF7D0A是|r" }, { text = "|cffFF7D0A否|r" } },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_PH",
                defaultID = 1,
            },
            -- 狂咒停手层数（冰龙技能）
            {
                text = "|cffFF7D0A狂咒|r",
                menuItems = {
                    { text = "|cffFF7D0A停手|r" },
                    { text = "|cffFF7D0A1层|r" },
                    { text = "|cffFF7D0A2层|r" },
                    { text = "|cffFF7D0A3层|r" },
                    { text = "|cffFF7D0A4层|r" },
                    { text = "|cffFF7D0A5层|r" },
                    { text = "|cffFF7D0A不停手|r" },
                },
                tooltipText = "中几层|cff00adf0狂咒|r停手",
                saveVariable = "PH_KZ",
                section = "自动",
                defaultID = 1,
            },
            -- 给队友激活（蓝量阈值滑条）
            {
                text = "|cffFF7D0A选目标激活|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 80,
                tooltipText = "选中的队友后使用|cff00adf0激活|r\n(当队友蓝量低于设定值时才使用)",
                saveVariable = "PH_JH",
            },
            -- 给自己激活（蓝量阈值滑条）
            {
                text = "|cffFF7D0A给自己激活|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 80,
                tooltipText = "选中的队友后使用|cff00adf0激活|r\n(当队友蓝量低于设定值时才使用)",
                saveVariable = "PH_JH_PLAYER",
            },
            -- 愈合给自己加血（血量阈值滑条）
            {
                text = "|cffFF7D0A愈合|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 0,
                tooltipText = "给自己加血)",
                saveVariable = "PH_YH",
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 136018, text = "|cffFF7D0A全局|r", tooltipText = "ICC2号的功能,对被|cff00adf0统御心灵|r的队友使用|cff00adf0旋风|r\n", saveVariable = "PH_XF", defaultState = false },
            { row = 1, column = 2, IconID = 135952, text = "|cffFF7D0A全局r|", tooltipText = "对被|cff00adf0麻痹诅咒|r或者|cff00adf0MC1老1诅咒|r的队友使用|cff00adf0解除诅咒|r\n", saveVariable = "PH_JCZZ", defaultState = false },
            { row = 1, column = 3, IconID = 136045, text = "|cffFF7D0A全局|r", tooltipText = "对队友的目标|cff00adf0虫群|r\n", saveVariable = "PH_CQ_QJ", defaultState = false },
            { row = 1, column = 4, IconID = 136096, text = "|cffFF7D0A全局|r", tooltipText = "对队友的目标|cff00adf0月火术|r\n", saveVariable = "PH_YHS_QJ", defaultState = false },
            { row = 1, column = 5, IconID = 429383, text = "|cffFF7D0ABOSS|r", tooltipText = "只有在boss目标开启轨道炮", saveVariable = "PH_GDP_BOSS", defaultState = false },

            -- 第2行
            { row = 2, column = 1, IconID = 236868, text = "|cffFF7D0A自动|r", tooltipText = "BOSS战自动吃|cff00adf0狂野魔法药水|r\n", saveVariable = "PH_KYMFYS1", defaultState = false },
            { row = 2, column = 2, IconID = 136045, text = "|cffFF7D0A目标|r", tooltipText = "对目标使用|cff00adf0虫群|r\n", saveVariable = "PH_CQ1", defaultState = true },
            { row = 2, column = 3, IconID = 136045, text = "|cffFF7D0A指向|r", tooltipText = "对指向单位使用|cff00adf0虫群|r\n", saveVariable = "PH_CQ2", defaultState = true },
            { row = 2, column = 4, IconID = 136045, text = "|cffFF7D0A移动|r", tooltipText = "移动时使用|cff00adf0虫群|r\n", saveVariable = "PH_CQ3", defaultState = true },
            { row = 2, column = 5, IconID = 136047, text = "|cffFF7D0A锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n,这个是TOC的双子自动锁对应目标和ICC议会", saveVariable = "PH_Suo", defaultState = true },

            -- 第3行
            { row = 3, column = 1, IconID = 136096, text = "|cffFF7D0A目标|r", tooltipText = "对目标使用|cff00adf0月火术|r\n", saveVariable = "PH_YHS1", defaultState = true },
            { row = 3, column = 2, IconID = 136096, text = "|cffFF7D0A指向|r", tooltipText = "对指向单位使用|cff00adf0月火术|r\n", saveVariable = "PH_YHS2", defaultState = true },
            { row = 3, column = 3, IconID = 136096, text = "|cffFF7D0A移动|r", tooltipText = "移动时使用|cff00adf0月火术|r\n", saveVariable = "PH_YHS3", defaultState = true },
            { row = 3, column = 4, IconID = 133712, text = "|cffFF7D0A移动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r\n", saveVariable = "PH_ZD", defaultState = false },
            { row = 3, column = 5, IconID = 136033, text = "|cffFF7D0ABOSS|r", tooltipText = "对团本BOSS才会使用|cff00adf0精灵之火|r\n", saveVariable = "PH_JLZH", defaultState = true },

            -- 第4行
            { row = 4, column = 1, IconID = 132129, text = "|cffFF7D0A自动|r", tooltipText = "使用|cff00adf0自然之力|r\n", saveVariable = "PH_ZRZL", defaultState = true },
            { row = 4, column = 2, IconID = 135952, text = "|cffFF7D0A自己|r", tooltipText = "对自己解|cff00adf0麻痹诅咒|r\n", saveVariable = "PH_JCWR_P", defaultState = true },
            { row = 4, column = 3, IconID = 429383, text = "|cffFF7D0A自动|r", tooltipText = "轨道炮好了就用", saveVariable = "PH_YSGDP_ZD", defaultState = true },
            { row = 4, column = 4, IconID = 236168, text = "|cffFF7D0A自动|r", tooltipText = "自动使用|cff00adf0星辰坠落|r\n", saveVariable = "PH_XCZL_ZD", defaultState = true },
            -- ★ 第4行第5列：新增偷药开关
            { row = 4, column = 5, IconID = 236871, text = "|cffFF7D0A偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "PH_TOUYAO", section = "爆发", defaultState = false },

            -- 第5行（插入类技能）
            { row = 5, column = 1, IconID = 236868, text = "|cffFF7D0A插入|r", tooltipText = "插入|cff00adf0狂野魔法药水|r\n", saveVariable = "PH_KYMFYS2", section = "插入", defaultState = false },
            { row = 5, column = 2, IconID = 132962, text = "|cffFF7D0A插入|r", tooltipText = "插入|cff00adf0手套|r\n", saveVariable = "PH_ST", section = "插入", defaultState = false },
            { row = 5, column = 3, IconID = 134228, text = "|cffFF7D0A插入|r", tooltipText = "插入|cff00adf0饰品|r\n", saveVariable = "PH_SP", section = "插入", defaultState = false },
            { row = 5, column = 4, IconID = 136097, text = "|cffFF7D0A插入|r", tooltipText = "插入|cff00adf0树皮术|r\n", saveVariable = "PH_SPS", section = "插入", defaultState = false },
            { row = 5, column = 5, IconID = 132129, text = "|cffFF7D0A插入|r", tooltipText = "使用|cff00adf0自然之力|r\n", saveVariable = "PH_CRZRZL", section = "插入", defaultState = false },

            -- 第6行（插入类技能）
            { row = 6, column = 1, IconID = 236170, text = "|cffFF7D0A插入|r", tooltipText = "使用|cff00adf0台风|r\n", saveVariable = "PH_CRTF", section = "插入", defaultState = false },
            { row = 6, column = 2, IconID = 136018, text = "|cffFF7D0A插入|r", tooltipText = "使用|cff00adf0飓风|r\n", saveVariable = "PH_CRJF", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 236168, text = "|cffFF7D0A插入|r", tooltipText = "使用|cff00adf0星辰坠落|r\n", saveVariable = "PH_CRXCZL", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 429383, text = "|cffFF7D0A插入|r", tooltipText = "使用|cff00adf0月神轨道炮|r\n", saveVariable = "PH_YSGDP_CR", showSpell = "月神轨道炮", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 7, column = 1, IconID = 132293, text = "|cffFF7D0A切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "PH_TAB", defaultState = true },
        },
    },

    -- ==========================================================
    -- 2. 野性战斗专精（猫德/熊德）
    -- ==========================================================
    ["野性战斗"] = {
        DM = {
            -- 防ADD开关
            {
                text = "|cffFF7D0A防ADD|r",
                menuItems = { { text = "|cffFF7D0A是|r" }, { text = "|cffFF7D0A否|r" } },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_YD",
                defaultID = 1,
            },
            -- 形态选择：猫形态 / 熊形态
            {
                text = "|cffFF7D0A形态选择|r",
                menuItems = { { text = "|cffFF7D0A猫形态|r" }, { text = "|cffFF7D0A熊形态|r" } },
                tooltipText = "选择野德形态\n",
                saveVariable = "YD_XTXZ",
                defaultID = 1,
            },
            -- 寒霜刺骨停手层数（冰龙技能）
            {
                text = "|cffFF7D0A寒霜刺骨|r",
                menuItems = {
                    { text = "|cffFF7D0A5|r" }, { text = "|cffFF7D0A6|r" },
                    { text = "|cffFF7D0A7|r" }, { text = "|cffFF7D0A8|r" },
                    { text = "|cffFF7D0A9|r" }, { text = "|cffFF7D0A10|r" },
                    { text = "|cffFF7D0A禁用|r" },
                },
                tooltipText = "|cff00adf0寒霜刺骨|r层数大于等于设定值，自动停手(|cff00adf0冰龙|r技能)",
                saveVariable = "YD_HSCG",
                section = "自动",
                defaultID = 7,  -- 默认禁用
            },
            -- 给队友激活（蓝量阈值滑条）
            {
                text = "|cffFF7D0A激活|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 0,
                tooltipText = "选中的队友后使用|cff00adf0激活|r\n(当队友蓝量低于设定值时才使用)\n",
                saveVariable = "YD_JH",
            },
            -- 愈合（仅野外有迅捷时生效）
            {
                text = "|cffFF7D0A愈合|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 0,
                tooltipText = "只在野外有迅捷的情况下生效",
                saveVariable = "YD_YH",
            },
            { text = "|cffFF7D0A打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "YD_DD" },
        },
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 136018, text = "|cffFF7D0A全局|r", tooltipText = "对被|cff00adf0统御心灵|r的队友使用|cff00adf0旋风|r\n", saveVariable = "YD_XF", defaultState = false },
            { row = 1, column = 2, IconID = 135952, text = "|cffFF7D0A全局|r", tooltipText = "对被|cff00adf0麻痹诅咒|r或者|cff00adf0MC1老1诅咒|r的队友使用|cff00adf0解除诅咒|r\n", saveVariable = "YD_JCZZ", defaultState = false },
            { row = 1, column = 3, IconID = 136085, text = "|cffFF7D0A2T5|r", tooltipText = "是否开启2T5愈合功能,实战好像并不怎么样.不要问我开不开我不知道", saveVariable = "YD_YH_2T5", defaultState = false },
            { row = 1, column = 4, IconID = 236149, text = "|cffFF7D0A自动|r", tooltipText = "会在猛虎以后使用|cff00adf0狂暴|r\n,只对boss生效", saveVariable = "YD_KB", section = "爆发", defaultState = true },
            -- ★ 第1行第5列：新增偷药开关
            { row = 1, column = 5, IconID = 236871, text = "|cffFF7D0A偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "YD_TOUYAO", section = "爆发", defaultState = false },

            -- 第2行
            { row = 2, column = 1, IconID = 132242, text = "|cffFF7D0A自动|r", tooltipText = "使用|cff00adf0猛虎之怒|r\n", saveVariable = "YD_MHZN", defaultState = true },
            { row = 2, column = 2, IconID = 236871, text = "|cffFF7D0A自动|r", tooltipText = "使用|cff00adf0速度药水|r\n", saveVariable = "YD_ZDSDYS", section = "爆发", defaultState = false },
            { row = 2, column = 3, IconID = 133712, text = "|cffFF7D0A自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r\n", saveVariable = "YD_ZD", defaultState = false },
            { row = 2, column = 4, IconID = 132122, text = "|cffFF7D0A自动|r", tooltipText = "|cff00adf0斜掠|r控制开关\n", saveVariable = "YD_XL", defaultState = true },
            { row = 2, column = 5, IconID = 134296, text = "|cffFF7D0A自动|r", tooltipText = "开启|cff00adf0自动横扫|r\n", saveVariable = "YD_ZDHS", defaultState = true },

            -- 第3行
            { row = 3, column = 1, IconID = 134296, text = "|cffFF7D0A屏蔽|r", tooltipText = "ICC老2附近有玩家自动屏蔽|cff00adf0横扫|r\n", saveVariable = "YD_WJPB", defaultState = true },
            { row = 3, column = 2, IconID = 134296, text = "|cffFF7D0A强制|r", tooltipText = "开启|cff00adf0强制横扫|r\n", saveVariable = "YD_QZHS", defaultState = false },
            { row = 3, column = 3, IconID = 136047, text = "|cffFF7D0A锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n,这个是TOC的双子自动锁对应目标和ICC议会", saveVariable = "YD_SUO", defaultState = false },
            { row = 3, column = 4, IconID = 135964, text = "|cffFF7D0A取消|r", tooltipText = "自动取消|cff00adf0保护|r\n", saveVariable = "YD_QXBH", defaultState = true },
            { row = 3, column = 5, IconID = 132135, text = "|cffFF7D0A正面|r", tooltipText = "正面|cff00adf0裂伤(猫)|r控制开关\n,基本无用不用开.只在完全无法打背面的boss有用,", saveVariable = "YD_ZMLS", defaultState = false },

            -- 第4行
            { row = 4, column = 1, IconID = 135952, text = "|cffFF7D0A自己|r", tooltipText = "对自己解|cff00adf0麻痹诅咒|r\n", saveVariable = "YD_JCWR_P", defaultState = true },
            -- ★ 工程手套独立开关
            { row = 4, column = 2, IconID = 132962, text = "|cffFF7D0A手套|r", tooltipText = "自动使用|cff00adf0工程手套附魔|r（爆发窗口触发，独立于其他开关）", saveVariable = "YD_GCST", section = "爆发", defaultState = true },
            -- ★ ZZ 移植：猫变猫解定身（自动常驻开关）
            { row = 4, column = 3, IconID = 132121, text = "|cffFF7D0A解定身|r", tooltipText = "ZZ 移植：自动检测| cff00adf0纠缠、包围之网和火焰之花|r，被控时重进猎豹形态解除（常驻开关）", saveVariable = "YD_CAT_CAT_AUTO", defaultState = true },
            -- ★ ZZ 移植：猫变猫（一次性插入开关）
            { row = 4, column = 4, IconID = 132121, text = "|cffFF7D0A插入猫|r", tooltipText = "ZZ 移植：一次性——已处于猎豹形态且技能可用时重进一次（解控/刷新），用完自动关", saveVariable = "YD_CAT_CAT_CR", defaultState = false },

            -- 第5行（插入类技能）
            { row = 5, column = 1, IconID = 236149, text = "|cffFF7D0A插入|r", tooltipText = "插入|cff00adf0狂暴|r\n", saveVariable = "YD_CRKB", section = "爆发", defaultState = false },
            { row = 5, column = 2, IconID = 132276, text = "|cffFF7D0A搭脉|r", tooltipText = "插入|cff00adf0教授搭脉|r\n,ICC教授用的.切熊模式减伤全开群嘲.", saveVariable = "YD_CRDM", defaultState = false },
            { row = 5, column = 3, IconID = 236149, text = "|cffFF7D0A插入\n猛虎\n后|r", tooltipText = "下一个猛虎以后插入|cff00adf0狂暴|r\n", saveVariable = "YD_CRKB_MHH", section = "爆发", defaultState = false },

            -- 第6行（插入类技能，熊德专用）
            { row = 6, column = 1, IconID = 132114, text = "|cffFF7D0A插入|r", tooltipText = "插入|cff00adf0猛击|r\n", saveVariable = "YD_MJ_CR", showSpell = "猛击", section = "插入", defaultState = false },
            { row = 6, column = 2, IconID = 132117, text = "|cffFF7D0A插入|r", tooltipText = "插入|cff00adf0挑战咆哮|r\n", saveVariable = "YD_TZPX_CR", showSpell = "挑战咆哮", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 132091, text = "|cffFF7D0A插入|r", tooltipText = "插入|cff00adf0狂暴回复|r\n", saveVariable = "YD_KBHF_CR", showSpell = "狂暴回复", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 132121, text = "|cffFF7D0A插入|r", tooltipText = "插入|cff00adf0挫志咆哮|r\n", saveVariable = "YD_CZPX_CR", showSpell = "挫志咆哮", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 7, column = 1, IconID = 132293, text = "|cffFF7D0A切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "YD_TAB", defaultState = false },
        },
    },

    -- ==========================================================
    -- 3. 恢复专精（奶德）
    -- ==========================================================
    ["恢复"] = {
        DM = {
            -- 驱散模式选择
            {
                text = "|cffFF7D0A驱散|r",
                menuItems = {
                    { text = "|cffFF7D0A常规|r" },
                    { text = "|cffFF7D0A优先|r" },
                    { text = "|cffFF7D0A目标|r" },
                    { text = "|cffFF7D0A指向|r" },
                    { text = "|cffFF7D0A禁用|r" },
                },
                tooltipText = "|cff00adf0常规：驱散所有Debuff。|r\n|cffffdf00优先：驱散所有Debuff(高优先级)。\n|cffadff2f目标：仅驱散当前目标的Debuff。|r\n|cff9bf6ff指向：仅驱散指向队友的Debuff。|r",
                saveVariable = "HF_QS",
                defaultID = 1,
            },
            -- 野性印记 / 野性赐福
            {
                text = "|cffFF7D0A野性|r",
                menuItems = {
                    { text = "|cffFF7D0A印记|r" },
                    { text = "|cffFF7D0A赐福|r" },
                    { text = "|cffFF7D0A禁用|r" },
                },
                tooltipText = "使用|cff00adf0野性印记|r或|cff00adf0野性赐福|r",
                saveVariable = "HF_YX",
                defaultID = 2,  -- 默认赐福
            },
            -- 愈合模式
            {
                text = "|cffFF7D0A愈合|r",
                menuItems = {
                    { text = "|cffFF7D0A自动|r" },
                    { text = "|cffFF7D0A坦克|r" },
                    { text = "|cffFF7D0A禁用|r" },
                },
                tooltipText = "|cff00adf0自动|r：对所有人使用|cff00adf0愈合|r\n|cff996b1f坦克|r：仅对|cff996b1f坦克|r使用|cff00adf0愈合|r|r",
                saveVariable = "HF_YH",
                defaultID = 2,  -- 默认仅坦克
            },
            -- ★ ZZ 移植：愈合坦克 HP% 阈值滑块（配合 HF_YH_TANK 开关）
            {
                text = "|cffFF7D0A愈合坦阈值|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 70,
                tooltipText = "|cff00adf0愈合坦克 HP% 阈值|r：坦克/焦点 HP% ≤ 设定值时补愈合（默认 70）。\n|cffff5040值为0：只看目标优先级 debuff（血肉成灰等）才补。|r",
                saveVariable = "HF_YH_HP",
            },
            -- ★ ZZ 移植：愈合坦克 HP% 模式总开关
            {
                text = "|cffFF7D0A愈合坦模式|r",
                isCheckBox = true,
                tooltipText = "ZZ 移植：开启后按| cff00adf0HF_YH_HP|r 阈值给坦克/焦点补愈合（HP%≤阈值）；关闭则走原失血量判定",
                saveVariable = "HF_YH_TANK",
            },
            -- ★ ZZ 移植：荆棘术自动给坦克
            {
                text = "|cffFF7D0A荆棘术|r",
                isCheckBox = true,
                tooltipText = "战斗中自动给坦克补|cff00adf0荆棘术|r（TankUnit 列表第一个满足距离条件的）",
                saveVariable = "HF_JJS",
            },
            -- 过量治疗容忍度（滑条）
            {
                text = "|cffFF7D0A过量治疗|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 30,
                tooltipText = "设置的过量比例越高，越积极加血。\n|cffff5040值为0：不容忍过量，队友必须掉满技能血量才加血。|r",
                saveVariable = "HF_YXGL",
            },
            -- 树皮术目标选择
            {
                text = "|cffFF7D0A树皮术|r",
                menuItems = {
                    { text = "|cffFF7D0A坦克1|r" },
                    { text = "|cffFF7D0A坦克2|r" },
                    { text = "|cffFF7D0A坦克3|r" },
                    { text = "|cffFF7D0A坦克4|r" },
                    { text = "|cffFF7D0A自己|r" },
                    { text = "|cffFF7D0A全团|r" },
                    { text = "|cffFF7D0A禁用|r" },
                },
                tooltipText = "设置|cff00adf0树皮术|r的释放目标（魔改版）",
                saveVariable = "HF_SPS",
                defaultID = 5,  -- 默认自己
            },
            -- 树皮术触发血量阈值（滑条）
            {
                text = "|cffFF7D0A树皮血量|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 35,
                tooltipText = "设置触发|cff00adf0树皮术|r的血量百分比。",
                saveVariable = "HF_SPS_HP",
            },
            -- 自然迅捷模式
            {
                text = "|cffFF7D0A自然迅捷|r",
                menuItems = {
                    { text = "|cffFF7D0A自动|r" },
                    { text = "|cffFF7D0A重要|r" },
                    { text = "|cffFF7D0A禁用|r" },
                },
                tooltipText = "当队友血量过低，对其使用|cff00adf0自然迅捷+治疗之触|r\n|cff00adf0自动|r：对所有人使用|cff00adf0自然迅捷|r\n|cffadff2f重要|r：仅对|cff996b1f坦克|r和|cffFF7D0A自己|r使用|cff00adf0自然迅捷|r|r",
                saveVariable = "HF_ZRXJ",
                defaultID = 1,  -- 默认自动
            },
            -- 自然迅捷触发血量阈值（滑条）
            {
                text = "|cffFF7D0A自然迅捷|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 35,
                tooltipText = "设置触发|cff00adf0自然迅捷|r的血量百分比。",
                saveVariable = "HF_ZRXJ_HP",
            },
            -- 迅捷治愈触发血量阈值（滑条）
            {
                text = "|cffFF7D0A迅捷治愈|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 50,
                tooltipText = "当友方单位血量低于设定值的时候，使用|cff00adf0迅捷治愈|r。\n|cffff5040值为0：不使用|cff00adf0迅捷治愈|r。|r",
                saveVariable = "HF_XJZY",
            },
            -- 回春术触发血量阈值（滑条）
            {
                text = "|cffFF7D0A回春术|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 90,
                tooltipText = "当友方单位血量低于设定值的时候，使用|cff00adf0回春术|r。\n|cffff5040值为0：不使用|cff00adf0回春术|r。|r",
                saveVariable = "HF_HCS",
            },
            -- 激活自身蓝量阈值（滑条）
            {
                text = "|cffFF7D0A激活|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 15,
                tooltipText = "当自身蓝量低于设定值的时候，给自己使用|cff00adf0激活|r。\n|cffff5040值为0：不使用|cff00adf0激活|r。|r",
                saveVariable = "HF_JH",
            },
            -- ★ 宁静全团血量阈值（滑条）- 增强说明
            {
                text = "|cffFF7D0A宁静|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 0,
                tooltipText = "当全团/全队总血量百分比低于设定值时，自动使用|cff00adf0宁静|r。\n包含全团血量预测功能，避免过量治疗浪费。\n|cffff5040值为0：禁用自动宁静。|r",
                saveVariable = "HF_NJ_HP",
            },
            -- ★ 过量停条窗口（0.1~0.5秒，默认0.5秒）
            {
                text = "|cffFF7D0A过量停条|r",
                menuItems = {
                    { text = "|cffFF7D0A0.1秒|r" },
                    { text = "|cffFF7D0A0.2秒|r" },
                    { text = "|cffFF7D0A0.3秒|r" },
                    { text = "|cffFF7D0A0.4秒|r" },
                    { text = "|cffFF7D0A0.5秒|r" },
                },
                tooltipText = "设置过量停条的检查窗口。施法剩余时间≤此值时检查目标血量，满血则停止施法避免过量。\n|cffff5040需配合下方「过量停条」开关使用，开关默认关闭。|r",
                saveVariable = "HF_GLTCCK",
                defaultID = 5
            },
        },
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 136080, text = "|cffFF7D0A复生|r", tooltipText = "战斗中选中死亡队友自动对其使用|cff00adf0复生|r", saveVariable = "HF_FS", defaultState = true },
            { row = 1, column = 2, IconID = 134206, text = "|cffFF7D0A生命绽放|r", tooltipText = "使用|cff00adf0生命绽放|r(仅对当前|cff996b1f坦克|r)", saveVariable = "HF_SMZF", defaultState = true },
            { row = 1, column = 3, IconID = 135230, text = "|cffFF7D0A治疗石|r", tooltipText = "血量过低使用|cff00adf0治疗石|r", saveVariable = "HF_ZLS", defaultState = true },
            { row = 1, column = 4, IconID = 136018, text = "|cffFF7D0A旋风|r", tooltipText = "对被|cff00adf0统御心灵|r的队友使用|cff00adf0旋风|r(|cff00adf0亡语者女士|r)", saveVariable = "HF_XF", defaultState = true },
            { row = 1, column = 5, IconID = 135737, text = "|cffFF7D0A狂咒|r", tooltipText = "中|cff00adf0狂咒|r后停手(|cff00adf0辛达苟萨|r)", saveVariable = "HF_KZ", defaultState = true },

            -- 第2行
            { row = 2, column = 1, IconID = 136081, text = "|cffFF7D0A无脑回春|r", tooltipText = "开启|cff00adf0无脑回春模式|r，只要有队友不满血就会铺回春|r", saveVariable = "HF_HCS_WN", defaultState = false },
            { row = 2, column = 2, IconID = 136012, text = "|cffFF7D0A爆发|r", tooltipText = "开启|cff00adf0爆发模式|r，使用|cff00adf0手套附魔|r、|cff00adf0速度药水|r及|cff00adf0饰品|r\n含DBM倒数提前开功能", saveVariable = "HF_BF", section = "爆发", defaultState = false },
            -- ★ ★ 第2行第3列：新增99%无脑回春开关
            { row = 2, column = 3, IconID = 136081, text = "|cffFF7D0A99%回春|r", tooltipText = "开启|cff00adf099%无脑回春模式|r，只要有队友血量低于99%就会铺回春\n适用于高压AOE环境，最大化HOT覆盖", saveVariable = "HF_HCS_WN_99", defaultState = false },
            -- ★ ★ 第2行第4列：新增偷药开关
            { row = 2, column = 4, IconID = 236871, text = "|cffFF7D0A偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "HF_TOUYAO", section = "爆发", defaultState = false },
            -- ★ ★ 第2行第5列：新增血肉成灰处理开关
            { row = 2, column = 5, IconID = 135737, text = "|cffFF7D0A血肉成灰|r", tooltipText = "开启后，当目标有|cff00adf0血肉成灰|rDebuff时自动停手，避免传染", saveVariable = "HF_XRCZ", defaultState = true },

            -- 第3行
            { row = 3, column = 1, IconID = 136107, text = "|cffFF7D0A宁静插入|r", tooltipText = "插入宁静（用户强制开启）", saveVariable = "HF_NJ_CR", showSpell = "宁静", section = "插入", defaultState = false },
            -- ★ 第3行第2列：过量停条开关（默认关闭）
            { row = 3, column = 2, IconID = 135737, text = "|cffFF7D0A过量停条|r", tooltipText = "开启后，施法结束前(按停条窗口设定)目标已满血时自动停止施法，避免过量治疗。\n|cffff5040首领机制(狂咒/血肉成灰等)与特殊治疗模式不受此开关影响，始终生效。|r", saveVariable = "HF_GLTC", defaultState = false },
            { row = 3, column = 3, IconID = 135894, text = "|cffFF7D0A总闸|r", tooltipText = "勾选后，关闭恢复德自动驱散（解诅咒/消毒术），优先级高于下拉选项。", saveVariable = "HF_QS_AUTO", defaultState = false },
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