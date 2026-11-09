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
    -- 1. 野兽控制专精 (Beast Mastery)
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
            -- 瞄准 or 多重选择
            {
                text = "|cffABD473瞄准or多重|r",
                menuItems = { { text = "|cffABD473多重|r" }, { text = "|cffABD473瞄准|r" } },
                tooltipText = "选择|cffff0000多重|ror|cffff0000瞄准|r",
                saveVariable = "LR_SWL_DCMZ",
                defaultID = 1,
            },
            -- 召唤宠物
            {
                text = "|cffABD473召唤宠物|r",
                menuItems = {
                    { text = "|cffABD4731号|r" }, { text = "|cffABD4732号|r" },
                    { text = "|cffABD4733号|r" }, { text = "|cffABD4734号|r" },
                    { text = "|cffABD4735号|r" }, { text = "|cffABD473不召唤|r" },
                },
                tooltipText = "无宝宝时自动召唤哪个宝宝",
                saveVariable = "LR_SW_ZHBB",
                defaultID = 1,
            },
            -- 治疗宠物（滑条）
            {
                text = "|cffABD473治疗宠物|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 80,
                tooltipText = "多少血量治疗宠物",
                saveVariable = "LR_SWL_ZLCW",
            },
            -- ★ 循环模式选择（单体/AOE）
            {
                text = "|cffABD473输出模式|r",
                menuItems = {
                    { text = "|cffABD473单体|r" },
                    { text = "|cffABD473AOE|r" },
                },
                tooltipText = "选择输出循环模式\n|cffff0000单体|r：正常单体输出，稳固填充\n|cffff0000AOE|r：只放多重、乱射、爆炸陷阱的极限AOE",
                saveVariable = "LR_SWL_CYCLE_MODE",
                defaultID = 1,
            },
            -- ★ 宝宝攻击模式（1=跟随/2=不跟随/3=不控制）
            {
                text = "|cffABD473宝宝模式|r",
                menuItems = {
                    { text = "|cffABD473跟随|r" },
                    { text = "|cffABD473不跟随|r" },
                    { text = "|cffABD473不控制|r" },
                },
                tooltipText = "选择宝宝控制模式\n|cffff0000跟随|r：自动让宝宝攻击目标并跟随主人（危险目标自动召回）\n|cffff0000不跟随|r：宝宝跟随主人但不自动攻击（黏主人，从战斗中切回会召回）\n|cffff0000不控制|r：宝宝原地待命，完全由玩家手动控制（不攻击不召回）",
                saveVariable = "LR_SWL_KZBB",
                defaultID = 1,
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 132208, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000急速射击|r", saveVariable = "LR_SWL_ZDJSSJ", defaultState = true },
            { row = 1, column = 2, IconID = 135727, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000种族|r", saveVariable = "LR_SWL_ZDZZ", section = "爆发", defaultState = true },
            { row = 1, column = 3, IconID = 236871, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000速度药水|r", saveVariable = "LR_SWL_ZDSRYS", section = "爆发", defaultState = false },
            -- ★ 第1行第4列：偷药开关
            { row = 1, column = 4, IconID = 236871, text = "|cffABD473偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "LR_SWL_TOUYAO", section = "爆发", defaultState = false },
            -- ★ 第1行第5列：毒蛇钉刺BOSS ONLY开关（适配T16）
            { row = 1, column = 5, IconID = 132204, text = "|cffABD473BOSS|r", tooltipText = "开启后，毒蛇钉刺只对BOSS目标施放（适配T16套装）", saveVariable = "LR_SWL_DSDC_BOSS_ONLY", defaultState = false },
            { row = 1, column = 6, IconID = 338666, text = "|cffABD473饰品|r", tooltipText = "自动|cff00adf0饰品|r（爆发/斩杀/DBM倒数时触发）", saveVariable = "LR_SWL_ZDSP", section = "爆发", defaultState = true },

            -- 第2行
            { row = 2, column = 1, IconID = 336779, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000手套|r", saveVariable = "LR_SWL_ZDST", section = "爆发", defaultState = true },
            { row = 2, column = 2, IconID = 133712, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000炸弹|r", saveVariable = "LR_SWL_ZDZD", defaultState = true },
            { row = 2, column = 3, IconID = 132188, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000守护切换|r", saveVariable = "LR_SWL_ZDSH", defaultState = true },
            { row = 2, column = 4, IconID = 132212, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000猎人印记,只对boss生效|r", saveVariable = "LR_SWL_ZDLRYJ", defaultState = true },

            -- 第3行
            { row = 3, column = 1, IconID = 132204, text = "|cffABD473指向|r", tooltipText = "自动指向|cffff0000毒蛇钉刺|r", saveVariable = "LR_SWL_ZXDSDC", defaultState = true },
            { row = 3, column = 2, IconID = 132204, text = "|cffABD473焦点|r", tooltipText = "自动焦点|cffff0000毒蛇钉刺|r", saveVariable = "LR_SWL_JDDSDC", defaultState = true },
            { row = 3, column = 3, IconID = 132204, text = "|cffABD473目标|r", tooltipText = "自动目标|cffff0000毒蛇钉刺|r", saveVariable = "LR_SWL_MBDSDC", defaultState = true },
            { row = 3, column = 4, IconID = 132330, text = "|cffABD473屏蔽|r", tooltipText = "议会屏蔽|cffff0000多重射击|r", saveVariable = "LR_SWL_YHDSSJ", defaultState = true },
            { row = 3, column = 5, IconID = 136047, text = "|cffABD473锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n,这个是TOC的双子自动锁对应目标和ICC议会", saveVariable = "LR_SWL_SUO", defaultState = false },

            -- 第4行
            { row = 4, column = 1, IconID = 132188, text = "|cffABD473蝰蛇舞|r", tooltipText = "自动|cffff0000蝰蛇舞|r,在射出多重的时候切蝰蛇,在多重击中的时候会到雄鹰,长续航但是会降低dps.如果蓝够的boss不要开", saveVariable = "LR_SWL_ZDSH_KSW", defaultState = true },
            { row = 4, column = 2, IconID = 135826, text = "|cffABD473全自动|r", tooltipText = "基本无用,推荐插入.全自动|cffff0000爆炸陷阱|r,CD好了就朝鼠标指向的位置扔", saveVariable = "LR_SWL_QZDBZXJ", defaultState = false },
            { row = 4, column = 3, IconID = 135826, text = "|cffABD473半自动|r", tooltipText = "基本无用,推荐插入.半自动|cffff0000爆炸陷阱|r,需要自己按左键", saveVariable = "LR_SWL_BZDBZXJ", defaultState = false },
            { row = 4, column = 4, IconID = 132163, text = "|cffABD473自动|r", tooltipText = "复活宠物", saveVariable = "LR_SW_FHCW_ZD", defaultState = true },
            { row = 4, column = 5, IconID = 136020, text = "|cffABD473自动|r", tooltipText = "是否对特定的怪自动凝神", saveVariable = "LR_SWL_ZDNS", defaultState = true },

            -- 第5行
            { row = 5, column = 1, IconID = 132160, text = "|cffABD473脱战|r", tooltipText = "脱战蝰蛇.满蓝龙鹰", saveVariable = "LR_SWL_TZKS", defaultState = true },
            { row = 5, column = 2, IconID = 132180, text = "|cffABD473目标\n的\n目标|r", tooltipText = "给目标的目标上误导", saveVariable = "LR_SW_WD_TARGETTARGET", defaultState = true },
            -- ★ 第8行第3列：奥术射击总闸（2026-8-15 新增）。原误放在第5行第3列，与焦点误导冲突导致两个复选框闪烁，已移开。
            { row = 8, column = 3, IconID = 136096, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000奥术射击|r", saveVariable = "LR_SWL_ASSJ", defaultState = true },
            { row = 5, column = 3, IconID = 132180, text = "|cffABD473焦点|r", tooltipText = "给焦点目标上误导", saveVariable = "LR_SWL_WD_FOCUS", defaultState = false },
            { row = 5, column = 4, IconID = 132180, text = "|cffABD473宠物|r", tooltipText = "给宠物目标上误导", saveVariable = "LR_SWL_WD_PET", defaultState = false },
            { row = 5, column = 5, IconID = 132222, text = "|cffABD473无脑|r", tooltipText = "无脑乱射，满足条件就自动放", saveVariable = "LR_SW_WLS", defaultState = false },

            -- 第6行（插入类技能）
            { row = 6, column = 1, IconID = 132294, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000逃脱|r", saveVariable = "LR_SWL_CRTT", section = "插入", defaultState = false },
            { row = 6, column = 2, IconID = 132208, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000急速射击|r", saveVariable = "LR_SWL_CRJSSJ", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 132180, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000误导|r", saveVariable = "LR_SWL_CRWD", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 135826, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000爆炸陷阱|r", saveVariable = "LR_SWL_CRBZXJ", section = "插入", defaultState = false },
            { row = 6, column = 5, IconID = 132222, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000乱射|r", saveVariable = "LR_SWL_CRLS", section = "插入", defaultState = false },

            -- 第7行
            { row = 7, column = 1, IconID = 135840, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000冰箱陷阱|r", saveVariable = "LR_SWL_CRBSXJ", section = "插入", defaultState = false },
            { row = 7, column = 2, IconID = 237347, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000豪猪诱饵|r", saveVariable = "LR_SWL_CRHZYR", section = "插入", defaultState = false },
            { row = 7, column = 3, IconID = 132294, text = "|cffABD473瓦格里|r", tooltipText = "插入|cffff0000瓦格里逃脱|r\n使用方法为插入以后按住左键,视野朝崖外", saveVariable = "LR_SWL_CRWGLTT", defaultState = false },
            -- ★ 第7行第4列：冰冻之箭
            { row = 7, column = 4, IconID = 135837, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000冰冻之箭|r\n需要鼠标指向目标位置\n适合用于定身特定BOSS技能", saveVariable = "LR_SWL_BZJJ", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 8, column = 2, IconID = 132580, text = "|cffABD473小吃|r", tooltipText = "自动给宠物吃香辣猛犸小吃", saveVariable = "LR_SWL_XLMMXC", defaultState = false },
            { row = 8, column = 1, IconID = 132293, text = "|cffABD473切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "LR_SWL_TAB", defaultState = true },
            -- ★ ⑧ 杀戮停等开关（宝宝平砍状态判断）
            { row = 8, column = 3, IconID = 132329, text = "|cffABD473杀戮停等|r", tooltipText = "宝宝超过两个实际平砍间隔未攻击当前目标时，杀戮命令停止提示，避免卡路或离开目标后持续挡住杀戮射击（MK原创·非ZZ对齐）", saveVariable = "LR_SWL_SLMK_PINGKAN", defaultState = true },
        },
    },

    -- ==========================================================
    -- 2. 射击专精 (Marksmanship)
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
            -- 瞄准 or 多重选择
            {
                text = "|cffABD473瞄准or多重|r",
                menuItems = { { text = "|cffABD473多重|r" }, { text = "|cffABD473瞄准|r" } },
                tooltipText = "选择|cffff0000多重|ror|cffff0000瞄准|r",
                saveVariable = "LR_SJL_DCMZ",
                defaultID = 1,
            },
            -- 召唤宠物
            {
                text = "|cffABD473召唤宠物|r",
                menuItems = {
                    { text = "|cffABD4731号|r" }, { text = "|cffABD4732号|r" },
                    { text = "|cffABD4733号|r" }, { text = "|cffABD4734号|r" },
                    { text = "|cffABD4735号|r" }, { text = "|cffABD473不召唤|r" },
                },
                tooltipText = "无宝宝时自动召唤哪个宝宝",
                saveVariable = "LR_SJ_ZHBB",
                defaultID = 1,
            },
            -- 治疗宠物（滑条）
            {
                text = "|cffABD473治疗宠物|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 80,
                tooltipText = "多少血量治疗宠物",
                saveVariable = "LR_SJL_ZLCW",
            },
            -- ★ 循环模式选择（单体/AOE）
            {
                text = "|cffABD473输出模式|r",
                menuItems = {
                    { text = "|cffABD473单体|r" },
                    { text = "|cffABD473AOE|r" },
                },
                tooltipText = "选择输出循环模式\n|cffff0000单体|r：正常单体输出，稳固填充\n|cffff0000AOE|r：只放多重、乱射、爆炸陷阱的极限AOE",
                saveVariable = "LR_SJL_CYCLE_MODE",
                defaultID = 1,
            },
            -- ★ 宝宝攻击模式（1=跟随/2=不跟随/3=不控制）
            {
                text = "|cffABD473宝宝模式|r",
                menuItems = {
                    { text = "|cffABD473跟随|r" },
                    { text = "|cffABD473不跟随|r" },
                    { text = "|cffABD473不控制|r" },
                },
                tooltipText = "选择宝宝控制模式\n|cffff0000跟随|r：自动让宝宝攻击目标并跟随主人（危险目标自动召回）\n|cffff0000不跟随|r：宝宝跟随主人但不自动攻击（黏主人，从战斗中切回会召回）\n|cffff0000不控制|r：宝宝原地待命，完全由玩家手动控制（不攻击不召回）",
                saveVariable = "LR_SJL_KZBB",
                defaultID = 1,
            },
            { text = "|cffABD473打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）。开启后输出模式部分会失效（与输出模式互斥）", saveVariable = "LR_SJL_ZDCMSJDD" },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 132208, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000急速射击|r", saveVariable = "LR_SJL_ZDJSSJ", defaultState = true },
            { row = 1, column = 2, IconID = 135727, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000种族|r", saveVariable = "LR_SJL_ZDZZ", section = "爆发", defaultState = true },
            { row = 1, column = 3, IconID = 236871, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000速度药水|r", saveVariable = "LR_SJL_ZDSRYS", section = "爆发", defaultState = false },
            -- ★ 第1行第4列：偷药开关
            { row = 1, column = 4, IconID = 236871, text = "|cffABD473偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "LR_SJL_TOUYAO", section = "爆发", defaultState = false },
            -- ★ 第1行第5列：沉默射击（输出模式）
            { row = 1, column = 5, IconID = 132323, text = "|cffABD473输出|r", tooltipText = "自动|cffff0000沉默射击|r当输出打\n（与打断模式互斥，建议只开一个）", saveVariable = "LR_SJL_ZDCMSJ", defaultState = false },
            { row = 1, column = 6, IconID = 338666, text = "|cffABD473饰品|r", tooltipText = "自动|cff00adf0饰品|r（爆发/斩杀/DBM倒数时触发）", saveVariable = "LR_SJL_ZDSP", section = "爆发", defaultState = true },

            -- 第2行
            { row = 2, column = 1, IconID = 336779, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000手套|r", saveVariable = "LR_SJL_ZDST", section = "爆发", defaultState = true },
            { row = 2, column = 2, IconID = 133712, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000炸弹|r", saveVariable = "LR_SJL_ZDZD", defaultState = true },
            { row = 2, column = 3, IconID = 132188, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000守护切换|r", saveVariable = "LR_SJL_ZDSH", defaultState = true },
            { row = 2, column = 4, IconID = 132212, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000猎人印记,只对boss生效|r", saveVariable = "LR_SJL_ZDLRYJ", defaultState = true },

            -- 第3行
            { row = 3, column = 1, IconID = 132204, text = "|cffABD473指向|r", tooltipText = "自动指向|cffff0000毒蛇钉刺|r", saveVariable = "LR_SJL_ZXDSDC", defaultState = true },
            { row = 3, column = 2, IconID = 132204, text = "|cffABD473焦点|r", tooltipText = "自动焦点|cffff0000毒蛇钉刺|r", saveVariable = "LR_SJL_JDDSDC", defaultState = true },
            { row = 3, column = 3, IconID = 132204, text = "|cffABD473目标|r", tooltipText = "自动目标|cffff0000毒蛇钉刺|r", saveVariable = "LR_SJL_MBDSDC", defaultState = true },
            { row = 3, column = 4, IconID = 132330, text = "|cffABD473屏蔽|r", tooltipText = "议会屏蔽|cffff0000多重射击|r", saveVariable = "LR_SJL_YHDSSJ", defaultState = true },
            { row = 3, column = 5, IconID = 136047, text = "|cffABD473锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n,这个是TOC的双子自动锁对应目标和ICC议会", saveVariable = "LR_SJL_SUO", defaultState = true },

            -- 第4行            -- ★ 第4行第2列：准备就绪自动使用（优化）
            { row = 4, column = 2, IconID = 132206, text = "|cffABD473准备\n就绪|r", tooltipText = "自动|cffff0000准备就绪|r,爆发技能冷却时自动刷新\n含DBM倒数提前开功能", saveVariable = "LR_SJL_ZDZBJX", section = "爆发", defaultState = true },
            { row = 4, column = 3, IconID = 132188, text = "|cffABD473蝰蛇舞|r", tooltipText = "自动|cffff0000蝰蛇舞|r,在射出多重的时候切蝰蛇,在多重击中的时候会到雄鹰,长续航但是会降低dps.如果蓝够的boss不要开", saveVariable = "LR_SJL_ZDSH_KSW", defaultState = false },
            { row = 4, column = 4, IconID = 135826, text = "|cffABD473全自动|r", tooltipText = "基本无用,推荐手动插入.全自动|cffff0000爆炸陷阱|r,朝鼠标指向的位置扔", saveVariable = "LR_SJL_QZDBZXJ", defaultState = false },
            { row = 4, column = 5, IconID = 135826, text = "|cffABD473半自动|r", tooltipText = "基本无用,推荐手动插入.半自动|cffff0000爆炸陷阱|r,需要自己按左键", saveVariable = "LR_SJL_BZDBZXJ", defaultState = false },

            -- 第5行
            { row = 5, column = 1, IconID = 132160, text = "|cffABD473脱战|r", tooltipText = "脱战蝰蛇.满蓝龙鹰", saveVariable = "LR_SJL_TZKS", defaultState = false },
            { row = 5, column = 2, IconID = 132163, text = "|cffABD473自动|r", tooltipText = "复活宠物", saveVariable = "LR_SJ_FHCW_ZD", defaultState = true },
            { row = 5, column = 3, IconID = 136020, text = "|cffABD473自动|r", tooltipText = "是否对特定的怪自动凝神", saveVariable = "LR_SJL_ZDNS", defaultState = true },
            { row = 5, column = 4, IconID = 132180, text = "|cffABD473目标\n的\n目标|r", tooltipText = "给目标的目标上误导", saveVariable = "LR_SJL_WD_TARGETTARGET", defaultState = true },
            { row = 5, column = 5, IconID = 132180, text = "|cffABD473焦点|r", tooltipText = "给焦点目标上误导", saveVariable = "LR_SJL_WD_FOCUS", defaultState = false },

            -- 第6行
            { row = 6, column = 1, IconID = 132180, text = "|cffABD473宠物|r", tooltipText = "给宠物目标上误导", saveVariable = "LR_SJL_WD_PET", defaultState = false },
            { row = 6, column = 2, IconID = 132294, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000逃脱|r", saveVariable = "LR_SJL_CRTT", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 132208, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000急速射击|r", saveVariable = "LR_SJL_CRJSSJ", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 132180, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000误导|r", saveVariable = "LR_SJL_CRWD", section = "插入", defaultState = false },
            { row = 6, column = 5, IconID = 135826, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000爆炸陷阱|r", saveVariable = "LR_SJL_CRBZXJ", section = "插入", defaultState = false },

            -- 第7行
            { row = 7, column = 1, IconID = 132222, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000乱射|r", saveVariable = "LR_SJL_CRLS", section = "插入", defaultState = false },
            { row = 7, column = 2, IconID = 135840, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000冰箱陷阱|r", saveVariable = "LR_SJL_CRBSXJ", section = "插入", defaultState = false },
            { row = 7, column = 3, IconID = 132206, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000准备就绪|r", saveVariable = "LR_SJL_CRZBJX", section = "爆发", defaultState = false },
            { row = 7, column = 4, IconID = 132294, text = "|cffABD473瓦格里|r", tooltipText = "插入|cffff0000瓦格里逃脱|r\n使用方法为插入以后按住左键,视野朝崖外", saveVariable = "LR_SJL_CRWGLTT", defaultState = false },
            -- ★ 第7行第5列：冰冻之箭
            { row = 7, column = 5, IconID = 135837, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000冰冻之箭|r\n需要鼠标指向目标位置\n适合用于定身特定BOSS技能", saveVariable = "LR_SJL_BZJJ", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 8, column = 2, IconID = 132580, text = "|cffABD473小吃|r", tooltipText = "自动给宠物吃香辣猛犸小吃", saveVariable = "LR_SJL_XLMMXC", defaultState = false },
            { row = 8, column = 1, IconID = 132293, text = "|cffABD473切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "LR_SJL_TAB", defaultState = true },
            -- ★ ⑧ 杀戮停等开关（宝宝平砍状态判断）
            { row = 8, column = 3, IconID = 132329, text = "|cffABD473杀戮停等|r", tooltipText = "宝宝超过两个实际平砍间隔未攻击当前目标时，杀戮命令停止提示，避免卡路或离开目标后持续挡住杀戮射击（MK原创·非ZZ对齐）", saveVariable = "LR_SWL_SLMK_PINGKAN", defaultState = true },
        },
    },

    -- ==========================================================
    -- 3. 生存专精 (Survival)
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
            -- 瞄准 or 多重选择
            {
                text = "|cffABD473瞄准or多重|r",
                menuItems = { { text = "|cffABD473多重|r" }, { text = "|cffABD473瞄准|r" } },
                tooltipText = "选择|cffff0000多重|ror|cffff0000瞄准|r",
                saveVariable = "LR_SCL_DCMZ",
                defaultID = 1,
            },
            -- 召唤宠物
            {
                text = "|cffABD473召唤宠物|r",
                menuItems = {
                    { text = "|cffABD4731号|r" }, { text = "|cffABD4732号|r" },
                    { text = "|cffABD4733号|r" }, { text = "|cffABD4734号|r" },
                    { text = "|cffABD4735号|r" }, { text = "|cffABD473不召唤|r" },
                },
                tooltipText = "无宝宝时自动召唤哪个宝宝",
                saveVariable = "LR_SC_ZHBB",
                defaultID = 1,
            },
            -- 治疗宠物（滑条）
            {
                text = "|cffABD473治疗宠物|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 80,
                tooltipText = "多少血量治疗宠物",
                saveVariable = "LR_SCL_ZLCW",
            },
            -- ★ 循环模式选择（单体/AOE）
            {
                text = "|cffABD473输出模式|r",
                menuItems = {
                    { text = "|cffABD473单体|r" },
                    { text = "|cffABD473AOE|r" },
                },
                tooltipText = "选择输出循环模式\n|cffff0000单体|r：正常单体输出，稳固填充\n|cffff0000AOE|r：只放多重、乱射、爆炸陷阱的极限AOE",
                saveVariable = "LR_SCL_CYCLE_MODE",
                defaultID = 1,
            },
            -- ★ 宝宝攻击模式（1=跟随/2=不跟随/3=不控制）
            {
                text = "|cffABD473宝宝模式|r",
                menuItems = {
                    { text = "|cffABD473跟随|r" },
                    { text = "|cffABD473不跟随|r" },
                    { text = "|cffABD473不控制|r" },
                },
                tooltipText = "选择宝宝控制模式\n|cffff0000跟随|r：自动让宝宝攻击目标并跟随主人（危险目标自动召回）\n|cffff0000不跟随|r：宝宝跟随主人但不自动攻击（黏主人，从战斗中切回会召回）\n|cffff0000不控制|r：宝宝原地待命，完全由玩家手动控制（不攻击不召回）",
                saveVariable = "LR_SCL_KZBB",
                defaultID = 1,
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 132208, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000急速射击|r", saveVariable = "LR_SCL_ZDJSSJ", defaultState = true },
            { row = 1, column = 2, IconID = 135727, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000种族|r", saveVariable = "LR_SCL_ZDZZ", section = "爆发", defaultState = true },
            { row = 1, column = 3, IconID = 236871, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000速度药水|r", saveVariable = "LR_SCL_ZDSRYS", section = "爆发", defaultState = false },
            -- ★ 第1行第4列：偷药开关
            { row = 1, column = 4, IconID = 236871, text = "|cffABD473偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "LR_SCL_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 6, IconID = 338666, text = "|cffABD473饰品|r", tooltipText = "自动|cff00adf0饰品|r（爆发/斩杀/DBM倒数时触发）", saveVariable = "LR_SCL_ZDSP", section = "爆发", defaultState = true },

            -- 第2行
            { row = 2, column = 1, IconID = 336779, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000手套|r", saveVariable = "LR_SCL_ZDST", section = "爆发", defaultState = true },
            { row = 2, column = 2, IconID = 133712, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000炸弹|r", saveVariable = "LR_SCL_ZDZD", defaultState = true },
            { row = 2, column = 3, IconID = 132188, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000守护切换|r", saveVariable = "LR_SCL_ZDSH", defaultState = true },
            { row = 2, column = 4, IconID = 132212, text = "|cffABD473自动|r", tooltipText = "自动|cffff0000猎人印记,只对boss生效|r", saveVariable = "LR_SCL_ZDLRYJ", defaultState = true },

            -- 第3行
            { row = 3, column = 1, IconID = 132204, text = "|cffABD473指向|r", tooltipText = "自动指向|cffff0000毒蛇钉刺|r", saveVariable = "LR_SCL_ZXDSDC", defaultState = true },
            { row = 3, column = 2, IconID = 132204, text = "|cffABD473焦点|r", tooltipText = "自动焦点|cffff0000毒蛇钉刺|r", saveVariable = "LR_SCL_JDDSDC", defaultState = true },
            { row = 3, column = 3, IconID = 132204, text = "|cffABD473目标|r", tooltipText = "自动目标|cffff0000毒蛇钉刺|r", saveVariable = "LR_SCL_MBDSDC", defaultState = true },
            { row = 3, column = 4, IconID = 132330, text = "|cffABD473屏蔽|r", tooltipText = "议会屏蔽|cffff0000多重射击|r", saveVariable = "LR_SCL_YHDSSJ", defaultState = true },
            { row = 3, column = 5, IconID = 136047, text = "|cffABD473锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n,这个是TOC的双子自动锁对应目标和ICC议会", saveVariable = "LR_SCL_SUO", defaultState = false },

            -- 第4行
            { row = 4, column = 1, IconID = 132188, text = "|cffABD473蝰蛇舞|r", tooltipText = "自动|cffff0000蝰蛇舞|r,在射出多重的时候切蝰蛇,在多重击中的时候会到雄鹰,长续航但是会降低dps.如果蓝够的boss不要开", saveVariable = "LR_SCL_ZDSH_KSW", defaultState = false },
            { row = 4, column = 2, IconID = 135826, text = "|cffABD473全自动|r", tooltipText = "基本无用,推荐手动插入.全自动|cffff0000爆炸陷阱|r,朝鼠标指向的位置扔", saveVariable = "LR_SCL_QZDBZXJ", defaultState = false },
            { row = 4, column = 3, IconID = 135826, text = "|cffABD473半自动|r", tooltipText = "基本无用,推荐手动插入.半自动|cffff0000爆炸陷阱|r,需要自己按左键", saveVariable = "LR_SCL_BZDBZXJ", defaultState = false },
            { row = 4, column = 4, IconID = 132163, text = "|cffABD473自动|r", tooltipText = "复活宠物", saveVariable = "LR_SC_FHCW_ZD", defaultState = true },
            { row = 4, column = 5, IconID = 136020, text = "|cffABD473自动|r", tooltipText = "是否对特定的怪自动凝神", saveVariable = "LR_SCL_ZDNS", defaultState = true },

            -- 第5行
            { row = 5, column = 1, IconID = 132160, text = "|cffABD473脱战|r", tooltipText = "脱战蝰蛇.满蓝龙鹰", saveVariable = "LR_SCL_TZKS", defaultState = false },
            { row = 5, column = 2, IconID = 132180, text = "|cffABD473目标\n的\n目标|r", tooltipText = "给目标的目标上误导", saveVariable = "LR_SCL_WD_TARGETTARGET", defaultState = true },
            { row = 5, column = 3, IconID = 132180, text = "|cffABD473焦点|r", tooltipText = "给焦点目标上误导", saveVariable = "LR_SCL_WD_FOCUS", defaultState = false },
            { row = 5, column = 4, IconID = 132180, text = "|cffABD473宠物|r", tooltipText = "给宠物目标上误导", saveVariable = "LR_SCL_WD_PET", defaultState = false },
            { row = 5, column = 5, IconID = 132222, text = "|cffABD473无脑|r", tooltipText = "无脑乱射，满足条件就自动放", saveVariable = "LR_SCL_WLS", defaultState = false },

            -- 第6行（插入类技能）
            { row = 6, column = 1, IconID = 132294, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000逃脱|r", saveVariable = "LR_SCL_CRTT", section = "插入", defaultState = false },
            { row = 6, column = 2, IconID = 132208, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000急速射击|r", saveVariable = "LR_SCL_CRJSSJ", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 132180, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000误导|r", saveVariable = "LR_SCL_CRWD", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 135826, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000爆炸陷阱|r", saveVariable = "LR_SCL_CRBZXJ", section = "插入", defaultState = false },
            { row = 6, column = 5, IconID = 132222, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000乱射|r", saveVariable = "LR_SCL_CRLS", section = "插入", defaultState = false },

            -- 第7行
            { row = 7, column = 1, IconID = 136181, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000黑箭|r", saveVariable = "LR_SCL_CRHJ", section = "插入", defaultState = false },
            { row = 7, column = 2, IconID = 135840, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000冰箱陷阱|r", saveVariable = "LR_SCL_CRBSXJ", section = "插入", defaultState = false },
            { row = 7, column = 3, IconID = 132294, text = "|cffABD473瓦格里|r", tooltipText = "插入|cffff0000瓦格里逃脱|r\n使用方法为插入以后按住左键,视野朝崖外", saveVariable = "LR_SCL_CRWGLTT", defaultState = false },
            -- ★ 第7行第4列：冰冻之箭
            { row = 7, column = 4, IconID = 135837, text = "|cffABD473插入|r", tooltipText = "插入|cffff0000冰冻之箭|r\n需要鼠标指向目标位置\n适合用于定身特定BOSS技能", saveVariable = "LR_SCL_BZJJ", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 8, column = 2, IconID = 132580, text = "|cffABD473小吃|r", tooltipText = "自动给宠物吃香辣猛犸小吃", saveVariable = "LR_SCL_XLMMXC", defaultState = false },
            { row = 8, column = 1, IconID = 132293, text = "|cffABD473切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "LR_SCL_TAB", defaultState = true },
            -- ★ ⑧ 杀戮停等开关（宝宝平砍状态判断）
            { row = 8, column = 3, IconID = 132329, text = "|cffABD473杀戮停等|r", tooltipText = "宝宝超过两个实际平砍间隔未攻击当前目标时，杀戮命令停止提示，避免卡路或离开目标后持续挡住杀戮射击（MK原创·非ZZ对齐）", saveVariable = "LR_SWL_SLMK_PINGKAN", defaultState = true },
        },
    },
}