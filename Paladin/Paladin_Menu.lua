-- ============================================================
-- Paladin_Menu.lua
-- 圣骑士全专精配置菜单（惩戒 / 防护 / 神圣）
-- 包含各类自动功能、插入技能、治疗阈值等开关
-- ============================================================

--[[
if WR_PlayerClass ~= "PALADIN" then return end

    ★ Paladin_Menu 结构说明：
    DM（下拉菜单）：用于选择模式/阈值，保存为数字值
    CB（复选框）：用于开启/关闭功能，保存为布尔值
    每个专精独立配置，互不干扰
--]]

local FC_FS_ShengYin = "|cffF58CBA腐蚀|r"
if UnitFactionGroup("player") == "Alliance" then
    FC_FS_ShengYin = "|cffF58CBA复仇|r"
end

Paladin_Menu = {
    -- ==========================================================
    -- 1. 惩戒专精 (Retribution)
    -- ==========================================================
    ["惩戒"] = {
        -- ===== 下拉菜单（DM） =====
        DM = {
            -- 防ADD开关
            {
                text = "|cffF58CBA防ADD|r",
                menuItems = { { text = "|cffF58CBA是|r" }, { text = "|cffF58CBA否|r" } },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_CJQ",
                defaultID = 1
            },
            -- 寒霜刺骨
            {
                text = "|cffF58CBA寒霜刺骨|r",
                menuItems = {
                    { text = "|cffF58CBA5|r" }, { text = "|cffF58CBA6|r" }, { text = "|cffF58CBA7|r" },
                    { text = "|cffF58CBA8|r" }, { text = "|cffF58CBA9|r" }, { text = "|cffF58CBA10|r" },
                    { text = "|cffF58CBA禁用|r" }
                },
                tooltipText = "|cff00adf0寒霜刺骨|r层数大于等于设定值，自动停手(|cff00adf0冰龙|r技能)\n",
                saveVariable = "CJ_HSCG",
                section = "自动",
                defaultID = 1
            },
            -- 制裁之锤（瓦格里）——已隐藏：本服不再使用该细分功能
            --[[
            {
                text = "|cffF58CBA制裁之锤|r",
                menuItems = { { text = "|cffF58CBA1|r" }, { text = "|cffF58CBA2|r" }, { text = "|cffF58CBA3|r" }, { text = "|cffF58CBA禁用|r" } },
                tooltipText = "使用|cff00adf0制裁之锤|r击晕选中编号的|cff00adf0瓦格里暗影戒卫|r(|cff00adf0巫妖王|r技能)\n",
                saveVariable = "CJ_ZCZC",
                section = "自动",
                defaultID = 1
            },
            ]]
            -- 圣光闪现阈值
            {
                text = "|cffF58CBA圣光闪现|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 0,
                tooltipText = "选择|cff00adf0圣光闪现|r的阈值\n",
                saveVariable = "CJ_SGSX"
            },
            -- 祝福选择
            {
                text = "|cffF58CBA祝福|r",
                menuItems = {
                    { text = "|cffF58CBA力量|r" },
                    { text = "|cffF58CBA智慧|r" },
                    { text = "|cffF58CBA王者|r" },
                    { text = "|cffF58CBA强效力量|r" },
                    { text = "|cffF58CBA强效智慧|r" },
                    { text = "|cffF58CBA强效王者|r" },
                    { text = "|cffF58CBA禁用|r" },
                },
                tooltipText = "|cff00adf0蓝色：普通祝福|r\n|cffffdf00金色：强效祝福。\n★ 祝福仅在战斗外施放，不影响战斗节奏",
                saveVariable = "CJ_ZF",
                defaultID = 7
            },
            -- 清洁术模式
            {
                text = "|cffF58CBA清洁术|r",
                menuItems = {
                    { text = "|cffF58CBA常规|r" },
                    { text = "|cffF58CBA优先|r" },
                    { text = "|cffF58CBA目标|r" },
                    { text = "|cffF58CBA指向|r" },
                    { text = "|cffF58CBA禁用|r" },
                },
                tooltipText = "|cff00adf0常规：驱散所有Debuff。|r\n|cffffdf00优先：驱散所有Debuff(高优先级)。\n|cffadff2f目标：仅驱散当前目标的Debuff。|r\n|cff9bf6ff指向：仅驱散指向队友的Debuff。|r",
                saveVariable = "CJ_QJS",
                defaultID = 5
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 135953, text = "|cffF58CBA全局|r", tooltipText = "使用|cff00adf0清洁术|r，驱散|cff00adf0灵魂尖啸|r和|cff00adf0熔化冲压|r\n", saveVariable = "CJ_QJS_QJ", defaultState = true },
            { row = 1, column = 2, IconID = 135968, text = "|cffF58CBA红玉|r", tooltipText = "使用|cff00adf0自由之手|r，驱散|cff00adf0红玉减速|r\n", saveVariable = "CJ_ZYZS", defaultState = true },
            { row = 1, column = 3, IconID = 135964, text = "|cffF58CBA血沸|r", tooltipText = "自动给沸腾之血目标保护\n", saveVariable = "CJ_BH", defaultState = true },
            { row = 1, column = 4, IconID = 132326, text = "|cffF58CBA全局|r", tooltipText = "全局队友目标自动判断愤怒之锤.注意朝向\n", saveVariable = "CJ_FNZC_QJ", defaultState = true },
            -- ★ 第1行第5列：偷药开关
            { row = 1, column = 5, IconID = 236871, text = "|cffF58CBA偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "CJ_TOUYAO", section = "爆发", defaultState = false },

            -- 第2行
            { row = 2, column = 1, IconID = 135875, text = "|cffF58CBA自动|r", tooltipText = "自动爆发使用|cff00adf0复仇之怒|r\n", saveVariable = "CJ_BF", section = "爆发", defaultState = true },
            { row = 2, column = 2, IconID = 236871, text = "|cffF58CBA自动|r", tooltipText = "使用|cff00adf0速度药水|r\n", saveVariable = "CJ_SDYS", section = "爆发", defaultState = false },
            { row = 2, column = 3, IconID = 133712, text = "|cffF58CBA自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r\n", saveVariable = "CJ_ZD", defaultState = true },
            { row = 2, column = 4, IconID = 136047, text = "|cffF58CBA锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n", saveVariable = "CJ_SUO", defaultState = true },

            -- 第3行
            { row = 3, column = 1, IconID = 135926, text = "|cffF58CBA自动|r", tooltipText = "使用|cff00adf0奉献|r\n", saveVariable = "CJ_FX", defaultState = true },
            { row = 3, column = 2, IconID = 135902, text = "|cffF58CBA自动|r", tooltipText = "使用|cff00adf0神圣愤怒|r\n", saveVariable = "CJ_SSFN", defaultState = true },
            { row = 3, column = 3, IconID = 135933, text = "|cffF58CBA自动|r", tooltipText = "自动|cff00adf0专注光掌|r\n", saveVariable = "CJ_ZD_ZZGH", defaultState = false },

            -- 第4行
            { row = 4, column = 1, IconID = 236262, text = "|cffF58CBA自动|r", tooltipText = "自动|cff00adf0祈求圣光|r\n,根据饰品触发时间自动开启", saveVariable = "CJ_ZD_QQSG", defaultState = true },
            { row = 4, column = 2, IconID = 236262, text = "|cffF58CBA嗜血|r", tooltipText = "自动|cff00adf0祈求圣光|r\n,如果身上有嗜血英勇5层直接开掉", saveVariable = "CJ_ZD_QQSG_SX", defaultState = true },
            -- ★ 第4行第3列：起手2加3祈求开关
            { row = 4, column = 3, IconID = 236262, text = "|cffF58CBA2+3|r", tooltipText = "开启|cff00adf0起手2加3祈求|r模式\n起手阶段使用2层正义+3层虔诚的祈求圣光，优化起手爆发", saveVariable = "CJ_QQSG_QS", defaultState = false },
            { row = 4, column = 4, IconID = 132387, text = "|cffF58CBA自动|r", tooltipText = "使用|cff00adf0雪球|r\n", saveVariable = "CJ_XQ", defaultState = true },
            -- ★ 2026-08-21 ZZ移植：技能提示开关（祈求圣光/十字军/重担 大字提醒）
            { row = 4, column = 5, IconID = 237500, text = "|cffF58CBA提示|r", tooltipText = "开启|cff00adf0技能提示|r\n祈求圣光即将可用时红色大字提醒「别动了」；十字军打击/圣光重担即将结束时提醒站定引导", saveVariable = "CJ_ZD_TIP", defaultState = true },

            -- 第5行（插入类技能）
            { row = 5, column = 1, IconID = 135902, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0神圣愤怒|r\n", saveVariable = "CJ_CRSSFN", section = "插入", defaultState = false },
            { row = 5, column = 2, IconID = 135963, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0制裁之锤|r\n", saveVariable = "CJ_CRZCZC", section = "插入", defaultState = false },
            { row = 5, column = 3, IconID = 253400, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0神圣牺牲|r\n", saveVariable = "CJ_CRSSXS", section = "插入", defaultState = false },
            { row = 5, column = 4, IconID = 135896, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0圣盾术|r\n", saveVariable = "CJ_CRSDS", section = "插入", defaultState = false },
            { row = 5, column = 5, IconID = 135966, text = "|cffF58CBA插入|r", tooltipText = "先开|cff00adf0圣盾术|r对你|cff00adf0目标的目标|r释放|cff00adf0牺牲|r\n", saveVariable = "CJ_CRWDXS", section = "插入", defaultState = false },

            -- 第6行
            { row = 6, column = 1, IconID = 135967, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0拯救之手|r\n", saveVariable = "CJ_CRZJZS", section = "插入", defaultState = false },
            { row = 6, column = 2, IconID = 135968, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0自由之手|r\n", saveVariable = "CJ_CRZYZS", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 236262, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0祈求圣光|r\n", saveVariable = "CJ_CRQQSG", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 7, column = 1, IconID = 132293, text = "|cffF58CBA切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "CJ_TAB", defaultState = false },
            -- ★ 衣服使用加力量开关
            { row = 7, column = 2, IconID = 134326, text = "|cffF58CBA衣服|r", tooltipText = "使用|cff00adf0加力量胸甲|r（如王者壁垒等带\"使用:力量\"效果的胸甲）\n爆发期/目标将死/DBM倒数时提示按下胸甲\"使用\"按键（slot5）", saveVariable = "CJ_YF", section = "爆发", defaultState = false },
            -- ★ 工程手套独立开关
            { row = 7, column = 3, IconID = 132962, text = "|cffF58CBA手套|r", tooltipText = "自动使用|cff00adf0工程手套附魔|r（爆发窗口触发，独立于复仇之怒开关）", saveVariable = "CJ_GCST", section = "爆发", defaultState = true },
        },
    },

    -- ==========================================================
    -- 2. 防护专精 (Protection)
    -- ==========================================================
    ["防护"] = {
        -- ===== 下拉菜单（DM） =====
        DM = {
            -- 防ADD开关
            {
                text = "|cffF58CBA防ADD|r",
                menuItems = { { text = "|cffF58CBA是|r" }, { text = "|cffF58CBA否|r" } },
                tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击",
                saveVariable = "FANG_ADD_FQ",
                defaultID = 1
            },
            -- ★ 祝福选择（防护专精）
            {
                text = "|cffF58CBA祝福|r",
                menuItems = {
                    { text = "|cffF58CBA力量|r" },
                    { text = "|cffF58CBA智慧|r" },
                    { text = "|cffF58CBA王者|r" },
                    { text = "|cffF58CBA强效力量|r" },
                    { text = "|cffF58CBA强效智慧|r" },
                    { text = "|cffF58CBA强效王者|r" },
                    { text = "|cffF58CBA禁用|r" },
                },
                tooltipText = "|cff00adf0蓝色：普通祝福|r\n|cffffdf00金色：强效祝福。\n★ 祝福仅在战斗外施放，不影响战斗节奏",
                saveVariable = "FH_ZF",
                defaultID = 7
            },
            -- 清洁术模式
            {
                text = "|cffF58CBA清洁术|r",
                menuItems = {
                    { text = "|cffF58CBA常规|r" },
                    { text = "|cffF58CBA优先|r" },
                    { text = "|cffF58CBA目标|r" },
                    { text = "|cffF58CBA指向|r" },
                    { text = "|cffF58CBA禁用|r" },
                },
                tooltipText = "|cff00adf0常规：驱散所有Debuff。|r\n|cffffdf00优先：驱散所有Debuff(高优先级)。\n|cffadff2f目标：仅驱散当前目标的Debuff。|r\n|cff9bf6ff指向：仅驱散指向队友的Debuff。|r",
                saveVariable = "FH_QJS",
                defaultID = 5
            },
            -- 圣疗阈值
            {
                text = "|cffF58CBA圣疗|r",
                menuItems = { { text = "|cffF58CBA10%|r" }, { text = "|cffF58CBA20%|r" }, { text = "|cffF58CBA30%|r" }, { text = "|cffF58CBA40%|r" }, { text = "|cffF58CBA50%|r" }, { text = "|cffF58CBA不使用|r" } },
                tooltipText = "选择给自己圣疗的血量%比",
                saveVariable = "FH_SL",
                defaultID = 6
            },
            -- 圣盾术阈值（按血量自动保命）
            {
                text = "|cffF58CBA圣盾|r",
                menuItems = { { text = "|cffF58CBA10%|r" }, { text = "|cffF58CBA20%|r" }, { text = "|cffF58CBA30%|r" }, { text = "|cffF58CBA40%|r" }, { text = "|cffF58CBA50%|r" }, { text = "|cffF58CBA不使用|r" } },
                tooltipText = "选择给自己圣盾术(无敌)的血量%比，低于该值自动开启保命。\n|cffff5040值为“不使用”时不自动放圣盾术。|r",
                saveVariable = "FH_SDS",
                defaultID = 6
            },
            -- ★ 全局保护（自动保护之手）
            {
                text = "|cff00adf0全局保护|r",
                menuItems = { { text = "|cffF58CBA30%|r" }, { text = "|cffF58CBA40%|r" }, { text = "|cffF58CBA50%|r" }, { text = "|cffaaffaa禁用|r" } },
                tooltipText = "开启|cff00adf0全局保护（自动保护之手）|r后，团内非坦克队友血量≤阈值时自动对其施放|cff00adf0保护之手|r\n|cffaaffaa禁用|r：不自动补，仅鼠标指向施放\n（本下拉仅控制团血自动补，与「指向保护」插入复选框相互独立）",
                saveVariable = "FH_ZZBH_HP",
                defaultID = 4
            },
            { text = "|cffF58CBA打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "FH_DD" },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 135964, text = "|cffF58CBA血沸|r", tooltipText = "自动给沸腾之血目标保护\n", saveVariable = "FH_BH", defaultState = false },
            { row = 1, column = 2, IconID = 135968, text = "|cffF58CBA红玉|r", tooltipText = "使用|cff00adf0自由之手|r，驱散|cff00adf0红玉减速|r\n", saveVariable = "FH_QJS_ZYZS_HYJS", defaultState = false },
            { row = 1, column = 3, IconID = 236871, text = "|cffF58CBA自动|r", tooltipText = "使用|cff00adf0速度药水|r\n", saveVariable = "FH_SDYS", section = "爆发", defaultState = false },
            -- ★ 第1行第4列：偷药开关
            { row = 1, column = 4, IconID = 236871, text = "|cffF58CBA偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "FH_TOUYAO", section = "爆发", defaultState = false },
            { row = 1, column = 5, IconID = 133712, text = "|cffF58CBA自动|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r\n", saveVariable = "FH_ZD", defaultState = false },

            -- 第2行            { row = 2, column = 2, IconID = 135962, text = "|cffF58CBA自动|r", tooltipText = "使用|cff00adf0正义之怒|r\n", saveVariable = "FH_ZYZN", defaultState = true },
            { row = 2, column = 4, IconID = 135926, text = "|cffF58CBA自动|r", tooltipText = "奉献", saveVariable = "FH_FX", defaultState = true },
            -- 第3行
            { row = 3, column = 2, IconID = 135963, text = "|cffF58CBA中虫|r", tooltipText = "TOC的中虫打断以及ICC巫妖王P1的大怪|cff00adf0制裁之锤|r\n", saveVariable = "FH_CRZCZC_DG", defaultState = false },
            { row = 3, column = 3, IconID = 135902, text = "|cff00adf0自动|r", tooltipText = "自动对亡灵/恶魔释放|cff00adf0神圣愤怒|r", saveVariable = "FH_SSFN_Auto", defaultState = false },
            -- ★ 清洁术 自己/目标（复选框，与下拉 FH_QJS 并存）
            { row = 3, column = 4, IconID = 135953, text = "|cffF58CBA自己|r", tooltipText = "使用|cff00adf0清洁术|r，驱散|cff00adf0自己|r身上的Debuff（独立于下拉菜单，勾选即生效）\n", saveVariable = "FH_QJS_Player", defaultState = true },
            { row = 3, column = 5, IconID = 135953, text = "|cffF58CBA目标|r", tooltipText = "使用|cff00adf0清洁术|r，驱散|cff00adf0目标|r身上的Debuff（独立于下拉菜单，勾选即生效）\n", saveVariable = "FH_QJS_Target", defaultState = true },

            -- 第4行
            { row = 4, column = 2, IconID = 135902, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0神圣愤怒|r\n", saveVariable = "FH_CRSSFN", section = "插入", defaultState = false },
            { row = 4, column = 3, IconID = 135963, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0制裁之锤|r\n", saveVariable = "FH_CRZCZC", section = "插入", defaultState = false },
            { row = 4, column = 4, IconID = 253400, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0神圣牺牲|r\n", saveVariable = "FH_CRSSXS", section = "插入", defaultState = false },
            { row = 4, column = 5, IconID = 135967, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0拯救之手|r\n", saveVariable = "FH_CRZJZS", section = "插入", defaultState = false },

            -- 第5行
            { row = 5, column = 1, IconID = 135968, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0自由之手|r\n", saveVariable = "FH_CRZYZS", section = "插入", defaultState = false },
            { row = 5, column = 4, IconID = 135928, text = "|cff00adf0插入|r", tooltipText = "插入|cff00adf0圣疗术|r（对自己）\n", saveVariable = "FH_CRSLS", section = "插入", defaultState = false },
            { row = 5, column = 5, IconID = 135896, text = "|cff00adf0插入|r", tooltipText = "插入|cff00adf0圣盾术|r（对自己）\n", saveVariable = "FH_CRSDS", section = "插入", defaultState = false },
            -- ★ 2026-11-07：插入 光明圣印（防骑已学会；宏 CTRL-F11 / 颜色槽 54）
            { row = 5, column = 2, IconID = 135893, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0光明圣印|r（一次性）\n\n|cffaaffaa勾选后，等「审判」CD 转好时执行一次：|r\n1. 提示切到|cff00adf0光明圣印|r（槽位 54，宏 CTRL-F11）\n2. 切印完成后提示|cff00adf0审判|r，让这一发审判挂上「圣光审判」\n3. 目标出现|cff00adf0圣光审判|r后，自动提示切回当前循环的常驻圣印（正义/愤怒圣印）\n4. 确认切回后|cffaaffaa自动取消勾选|r，本次插入结束\n\n|cffff5040注意|r：圣印同一时间只能有一个，切光明会暂时顶掉常驻圣印（仇恨/嘲讽来源），\n所以只在需要光明审判回血时用；平时保持关闭。\n切印后 10 秒内没打出审判会自动放弃；审判后 15 秒内未切回也会自动收尾，不会卡住。\n未学会光明圣印或审判时自动跳过，不影响循环。", saveVariable = "FH_CRGMSY", section = "插入", defaultState = false },
            -- ★ 2026-11-09：插入 智慧圣印（回复法力；宏 ALT-SHIFT-F8 / 颜色槽 108）
            { row = 5, column = 3, IconID = 135970, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0智慧圣印|r（一次性）\n\n|cffaaffaa勾选后，等「审判」CD 转好时执行一次：|r\n1. 提示切到|cff00adf0智慧圣印|r（槽位 108，宏 ALT-SHIFT-F8）\n2. 切印完成后提示|cff00adf0审判|r，让这一发审判带上智慧圣印效果（回蓝）\n3. 审判打出后|cffaaffaa自动取消勾选|r，本次插入结束\n\n|cffff5040注意|r：圣印同一时间只能有一个，切智慧会暂时顶掉常驻圣印（仇恨来源），\n所以只在缺蓝时用；平时保持关闭。\n切印后 10 秒内没打出审判会自动放弃并取消勾选，不会卡住。\n未学会智慧圣印或审判时自动跳过，不影响循环。", saveVariable = "FH_CRZHSY", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 6, column = 1, IconID = 132293, text = "|cffF58CBA切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标（坦克用于快速切目标建立仇恨）", saveVariable = "FH_TAB", defaultState = false },
            -- ★ 指向保护 / 指向牺牲（鼠标指向施放，团血阈值可选）
            { row = 6, column = 2, IconID = 135964, text = "|cff00adf0指向保护|r", tooltipText = "开启后，对|cff00adf0鼠标指向|r的队友施放|cff00adf0保护之手|r（优先级最高）\n战斗内外均可：脱战也可鼠标指向|cff00adf0预读保护|r（开怪前先套）\n|cffaaffaa施放成功后自动取消勾选（一次性），悬停不再反复触发|r\n（本复选框仅控制鼠标指向直接插入；团血自动补由上方「全局保护」下拉独立控制，不受本复选框影响）", saveVariable = "FH_ZZBH", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 135966, text = "|cff00adf0指向牺牲|r", tooltipText = "开启后，对|cff00adf0鼠标指向|r的队友施放|cff00adf0牺牲之手|r（优先级最高）\n战斗内外均可：脱战也可鼠标指向|cff00adf0预读牺牲|r（开怪前先套）\n|cffaaffaa施放成功后自动取消勾选（一次性），悬停不再反复触发|r\n（本复选框仅控制鼠标指向直接插入；团血自动补由上方「全局牺牲」下拉独立控制，不受本复选框影响）", saveVariable = "FH_ZZXS", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 135967, text = "|cff00adf0指向拯救|r", tooltipText = "开启后，对|cff00adf0鼠标指向|r的队友施放|cff00adf0拯救之手|r（减威胁，优先级最高）\n战斗内外均可：脱战也可鼠标指向|cff00adf0预读拯救|r（开怪前先套）\n|cffaaffaa施放成功后自动取消勾选（一次性），悬停不再反复触发|r\n（拯救为减威胁技能，仅鼠标指向直接插入，无团血自动补）", saveVariable = "FH_ZZJZ", section = "插入", defaultState = false },
            -- ★ 2026-11-08：单体循环模式（勾选=开，一直生效；不同于上述「插入」类一次性开关）
            { row = 6, column = 5, IconID = 135993, text = "|cffF58CBA单体|r", tooltipText = "开启后，防护循环切换为|cff00adf0单体循环|r模式：\n1. 先用|cff00adf0十字军圣印|r，打出|cff00adf0审判|r挂上十字军审判 debuff（提升神圣伤害）\n2. 然后切回|cff00adf0愤怒圣印|r常驻，维持仇恨\n3. 之后按常规优先级：神圣打击 / 审判 / 神圣之盾 / 驱邪术 / 奉献 / 愤怒之锤\n\n|cffaaffaa本开关常驻生效（勾选即一直用），不是一次性插入|r\n未学会十字军圣印或审判时自动跳过该前置，直接按常规循环。", saveVariable = "FH_DT", defaultState = false },
            -- ★ 2026-11-08：神圣之盾开关（常驻；默认开 = 保持原有行为）
            { row = 7, column = 1, IconID = 135880, text = "|cffF58CBA神圣之盾|r", tooltipText = "开启后，防护循环会在|cff00adf0神圣之盾|r冷却好时提示施放（防护核心减伤/仇恨）。\n\n|cffaaffaa默认勾选|r，与加入此开关之前的行为一致。\n关闭后循环不再提示神圣之盾，适合想手动控制、或该技能浪费蓝量时。\n未学会神圣之盾时不会提示（与开关无关）。", saveVariable = "FH_SZS", defaultState = true },
            -- ★ 2026-11-08：正义圣印循环（替代愤怒圣印作为常驻圣印）
            { row = 7, column = 2, IconID = 135969, text = "|cffF58CBA正义圣印|r", tooltipText = "开启后，防护循环的|cff00adf0常驻圣印|r由|cff00adf0愤怒圣印|r改为|cff00adf0正义圣印|r。\n\n|cffff5040注意|r：\n· 愤怒圣印的审判带|cffff0000嘲讽|r，换成正义圣印后|cffff0000审判不再嘲讽|r，需自己用别的办法拉怪；\n· 正义圣印每次命中附加额外神圣伤害，适合快速武器 / 单拉稳定输出；\n· 与「单体」开关可同时使用：起手仍是 十字军圣印 → 审判 → 切回正义圣印。\n\n未学会正义圣印时不会补印（其余循环照常），也不会误用愤怒圣印。", saveVariable = "FH_ZYSY", defaultState = false },
        },
    },

    -- ==========================================================
    -- 3. 神圣专精 (Holy)
    -- ==========================================================
    ["神圣"] = {
        -- ===== 下拉菜单（DM） =====
        DM = {
            -- 祝福选择
            {
                text = "|cffF58CBA祝福|r",
                menuItems = {
                    { text = "|cffF58CBA力量|r" },
                    { text = "|cffF58CBA智慧|r" },
                    { text = "|cffF58CBA王者|r" },
                    { text = "|cffF58CBA强效力量|r" },
                    { text = "|cffF58CBA强效智慧|r" },
                    { text = "|cffF58CBA强效王者|r" },
                    { text = "|cffF58CBA禁用|r" },
                },
                tooltipText = "|cff00adf0蓝色：普通祝福|r\n|cffffdf00金色：强效祝福。\n★ 祝福仅在战斗外施放，不影响战斗节奏",
                saveVariable = "SS_ZF",
                defaultID = 7
            },
            -- 清洁术模式
            {
                text = "|cffF58CBA清洁术|r",
                menuItems = {
                    { text = "|cffF58CBA常规|r" },
                    { text = "|cffF58CBA优先|r" },
                    { text = "|cffF58CBA目标|r" },
                    { text = "|cffF58CBA指向|r" },
                    { text = "|cffF58CBA禁用|r" },
                },
                tooltipText = "|cff00adf0常规：驱散所有Debuff。|r\n|cffffdf00优先：驱散所有Debuff(高优先级)。\n|cffadff2f目标：仅驱散当前目标的Debuff。|r\n|cff9bf6ff指向：仅驱散指向队友的Debuff。|r",
                saveVariable = "SS_QJS",
                defaultID = 2
            },
            -- 圣光道标
            {
                text = "|cffF58CBA圣光道标|r",
                menuItems = {
                    { text = "", }, { text = "", }, { text = "", }, { text = "", },
                    { text = "|cffF58CBA自己|r", },
                    { text = "|cffF58CBA刷新|r", },
                    { text = "|cffF58CBA禁用|r" }
                },
                tooltipText = "选择圣光道标的|cff996b1f坦克|r。\n注：当队伍中有|cff996b1f坦克|r的时候，选项才会显示(|cff00ADF0请让团长设置职责|r)。\n注：当队伍|cff996b1f坦克|r变动，选项也会变动，请注意及时调整。\n|cffF58CBA自己：道标保持在自己身上。|r\n|cffadff2f刷新：自己手动上一次道标给他人，当道标时间即将结束，会自动刷新他身上的道标。|r",
                saveVariable = "SS_SGDB",
                defaultID = 1
            },
            -- 圣洁护盾
            {
                text = "|cffF58CBA圣洁护盾|r",
                menuItems = {
                    { text = "", }, { text = "", }, { text = "", }, { text = "", },
                    { text = "|cffF58CBA自己|r", },
                    { text = "|cffF58CBA刷新|r", },
                    { text = "|cffF58CBA禁用|r" }
                },
                tooltipText = "选择圣洁护盾的|cff996b1f坦克|r。\n注：当队伍中有|cff996b1f坦克|r的时候，选项才会显示(|cff00ADF0请让团长设置职责|r)。\n注：当队伍|cff996b1f坦克|r变动，选项也会变动，请注意及时调整。\n|cffF58CBA自己：护盾保持在自己身上。|r\n|cffadff2f刷新：自己手动上一次护盾给他人，当护盾时间即将结束，会自动刷新他身上的护盾。|r",
                saveVariable = "SS_SJHD",
                defaultID = 1
            },
            -- 神圣震击模式
            {
                text = "|cffF58CBA神圣震击|r",
                menuItems = {
                    { text = "|cffF58CBA常规|r" },
                    { text = "|cffF58CBA积极|r" },
                    { text = "|cffF58CBA急救|r" },
                    { text = "|cffF58CBA禁用|r" }
                },
                tooltipText = "|cff00ADF0常规：移动中或急救时使用。|r\n|cffffff00积极：更积极的使用。|r\n|cffadff2f急救：仅限急救低血量友方时使用。|r",
                saveVariable = "SS_SSZJ",
                defaultID = 1
            },
            -- 圣光术阈值
            {
                text = "|cffF58CBA圣光术|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 70,
                tooltipText = "当友方单位血量低于设定值的时候，使用|cffffffb3圣光术|r。\n|cffff5040值为0：不使用|cffffffb3圣光术|r。|r",
                saveVariable = "SS_SGS"
            },
            -- 圣光闪现阈值
            {
                text = "|cffF58CBA圣光闪现|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 90,
                tooltipText = "当友方单位血量低于设定值的时候，使用|cffffffb3圣光闪现|r。\n|cffff5040值为0：不使用|cffffffb3圣光闪现|r。|r",
                saveVariable = "SS_SGSX"
            },
            -- 治疗模式
            {
                text = "|cffF58CBA治疗模式|r",
                menuItems = {
                    { text = "|cffF58CBA自动|r" },
                    { text = "|cffF58CBA目标|r" },
                    { text = "|cffF58CBA预读|r" },
                    { text = "|cffF58CBA泄蓝|r" },
                    { text = "|cffF58CBA坦克|r" },
                    { text = "|cffF58CBA脆皮|r" },
                    { text = "|cffF58CBA一队|r" },
                    { text = "|cffF58CBA二队|r" },
                    { text = "|cffF58CBA三队|r" },
                    { text = "|cffF58CBA四队|r" },
                    { text = "|cffF58CBA五队|r" },
                    { text = "|cffF58CBA萨12|r" },
                    { text = "|cffF58CBA萨34|r" },
                    { text = "|cffF58CBA萨13|r" },
                    { text = "|cffF58CBA萨24|r" },
                },
                tooltipText = "|cff00adf0自动：自动治疗所有单位，切目标不影响治疗。|cffffffff(过量自动打断施法)|r\n|cffffd700目标：有目标时治疗目标，无目标则|cff00adf0治疗全团|r。|cffffffff(过量自动打断施法)|r\n|cffadff2f预读：有目标时治疗目标，无目标则|cff00adf0治疗全团|r。|r|cffffffff(过量自动打断施法)|r\n|cff6a5acd泄蓝：有目标时治疗目标，无目标则|cff00adf0治疗全团|r。|r|cffff5040(过量不会打断施法)|r\n|cff996b1f坦克：仅治疗坦克，需要团长设置\"坦克\"职责。|r|cffffffff(过量自动打断施法)|r\n|cff9C3590脆皮：仅治疗坦克，需要团长设置\"坦克\"职责。|r|cffffffff(过量自动打断施法)|r|cffff5040(切记不要把道标给坦克)|r\n|cfffdffb6队伍：仅治疗选择的队伍（仅团队中生效）。|cffffffff(过量自动打断施法)|r|r\n|cffC31778萨鲁法尔：当|cff00adf0阵亡勇士的印记|r出现，自动道标和治疗选中的编号，无印记则|cff00adf0治疗全团|r。|r",
                saveVariable = "SS_ZLMS",
                defaultID = 1
            },
            -- ★ 过量停条窗口（0.1~0.5秒，默认0.5秒）
            {
                text = "|cffF58CBA过量停条|r",
                menuItems = {
                    { text = "|cffF58CBA0.1秒|r" },
                    { text = "|cffF58CBA0.2秒|r" },
                    { text = "|cffF58CBA0.3秒|r" },
                    { text = "|cffF58CBA0.4秒|r" },
                    { text = "|cffF58CBA0.5秒|r" },
                },
                tooltipText = "设置过量停条的检查窗口。施法剩余时间≤此值时检查目标血量，满血则停止施法避免过量。\n|cffff5040需配合下方「过量停条」开关使用，开关默认关闭。|r",
                saveVariable = "SS_GLTCCK",
                defaultID = 5
            },
            -- 制裁之锤（瓦格里）——已隐藏：本服不再使用该细分功能
            --[[
            {
                text = "|cffF58CBA制裁之锤|r",
                menuItems = {
                    { text = "|cffF58CBA自动|r" },
                    { text = "|cffF58CBA瓦1|r" },
                    { text = "|cffF58CBA瓦2|r" },
                    { text = "|cffF58CBA瓦3|r" },
                    { text = "|cffF58CBA禁用|r" },
                },
                tooltipText = "|cffffd700自动：自动使用|cff00adf0制裁之锤|r击晕危险的怪物。|r\n|cffadff2f瓦格里：使用|cff00adf0制裁之锤|r击晕选中序号的|cff00adf0瓦格里暗影戒卫者|r。(|cff00adf0巫妖王|r)|r",
                saveVariable = "SS_ZCZC",
                section = "自动",
                defaultID = 1
            },
            ]]
            -- 圣疗术目标选择
            {
                text = "|cffF58CBA圣疗术|r",
                menuItems = {
                    { text = "|cff996b1f坦克1 (30%)|r" }, 
                    { text = "|cff996b1f坦克2 (30%)|r" }, 
                    { text = "|cff996b1f坦克3 (30%)|r" }, 
                    { text = "|cff996b1f坦克4 (30%)|r" },
                    { text = "|cffF58CBA自己 (30%)|r", },
                    { text = "|cffadff2f全团检测 (30%)|r", },
                    { text = "|cffF58CBA禁用|r" }
                },
                tooltipText = "选择|cffF58CBA圣疗术|r的治疗目标和阈值。\n注：当队伍中有|cff996b1f坦克|r的时候，选项才会显示(|cff00ADF0请让团长设置职责|r)。\n注：当队伍|cff996b1f坦克|r变动，选项也会变动，请注意及时调整。\n|cff996b1f坦克1-4：治疗对应编号的坦克，默认30%阈值。|r\n|cffF58CBA自己：圣疗术用于自己，默认30%阈值。|r\n|cffadff2f全团检测：检查所有队员（包括坦克和队友），最低血量优先使用，默认30%阈值。|r\n|cffff5040值为0：不使用|cffF58CBA圣疗术|r。|r",
                saveVariable = "SS_SLS_Target",
                defaultID = 1
            },
            -- 圣疗术阈值
            {
                text = "|cffF58CBA圣疗术阈值|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 30,
                tooltipText = "自定义各目标的圣疗术血量阈值。\n数值会根据当前选中的目标模式生效。|r\n|cffff5040值为0：不使用|cffF58CBA圣疗术|r。|r",
                saveVariable = "SS_SLS"
            },
            -- 圣盾术阈值
            {
                text = "|cffF58CBA圣盾术|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 30,
                tooltipText = "当自己血量低于设定值的时候，使用|cffffffb3圣盾术|r。\n|cffff5040值为0：不使用|cffffffb3圣盾术|r。|r",
                saveVariable = "SS_SDS"
            },
            -- 牺牲之手阈值
            {
                text = "|cffF58CBA牺牲之手|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 30,
                tooltipText = "当队友血量低于设定值的时候，使用|cffffffb3牺牲之手|r。\n|cffff5040值为0：不使用|cffffffb3牺牲之手|r。|r",
                saveVariable = "SS_XSZS"
            },
            -- 保护之手阈值
            {
                text = "|cffF58CBA保护之手|r",
                isSlider = true,
                minValue = 0,
                maxValue = 100,
                valueStep = 5,
                defaultVal = 30,
                tooltipText = "当队友中了需要保护的减伤DEBUFF，或者血量低于设定值的时候，使用|cffffffb3保护之手|r。\n|cffff5040值为0：不使用|cffffffb3保护之手|r。|r",
                saveVariable = "SS_BHZS"
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- 第1行
            { row = 1, column = 1, IconID = 135968, text = "|cffF58CBA自由|r", tooltipText = "队友被定身时，使用|cff00adf0自由之手|r。", saveVariable = "SS_ZYZS", defaultState = true },
            { row = 1, column = 2, IconID = 135230, text = "|cffF58CBA治疗石|r", tooltipText = "血量过低使用|cff00adf0治疗石|r。", saveVariable = "SS_ZLS", defaultState = true },
            { row = 1, column = 3, IconID = 135737, text = "|cffF58CBA狂咒|r", tooltipText = "中|cff00adf0狂咒|r后停手(|cff00adf0辛达苟萨|r)", saveVariable = "SS_KZ", defaultState = true },
            -- ★ 第1行第4列：偷药开关
            { row = 1, column = 4, IconID = 236871, text = "|cffF58CBA偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "SS_TOUYAO", section = "爆发", defaultState = false },
            -- 第2行
            { row = 2, column = 1, IconID = 136012, text = "|cffF58CBA爆发|r", tooltipText = "开启|cff00adf0爆发模式|r，使用|cff00adf0手套附魔|r、|cff00adf0速度药水|r、|cff00adf0饰品|r及|cff00adf0神启|r。\n含DBM倒数提前开功能", saveVariable = "SS_BF", section = "爆发", defaultState = false },
            -- ★ 第2行第2列：过量停条开关（默认关闭）
            { row = 2, column = 2, IconID = 135737, text = "|cffF58CBA过停|r", tooltipText = "开启后，施法结束前(按停条窗口设定)目标已满血时自动停止施法，避免过量治疗。\n|cffff5040首领机制(狂咒/血肉成灰等)与特殊治疗模式不受此开关影响，始终生效。|r", saveVariable = "SS_GLTC", defaultState = false },
            -- ★ 第2行第3列：插入神圣牺牲
            { row = 2, column = 3, IconID = 253400, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0神圣牺牲|r\n", saveVariable = "SS_CRSSXS", section = "插入", defaultState = false },
            { row = 2, column = 4, IconID = 135953, text = "|cffF58CBA总闸|r", tooltipText = "勾选后，关闭神圣骑自动|cff00adf0清洁术|r（驱散），优先级高于下拉选项。", saveVariable = "SS_QJS_AUTO", defaultState = false },
            -- 第3行：鼠标指向三手（奶骑主动给队友套保护/牺牲/拯救）
            { row = 3, column = 1, IconID = 135964, text = "|cff00adf0指向保护|r", tooltipText = "开启后，对|cff00adf0鼠标指向|r的队友施放|cff00adf0保护之手|r（颜色提示，按键 ALT-CTRL-F7）\n|cffaaffaa悬停满足条件时持续提示；成功施放后自动取消勾选（一次性）|r", saveVariable = "SS_ZZBH", section = "插入", defaultState = false },
            { row = 3, column = 2, IconID = 135966, text = "|cff00adf0指向牺牲|r", tooltipText = "开启后，对|cff00adf0鼠标指向|r的队友施放|cff00adf0牺牲之手|r（颜色提示，按键 CTRL-SHIFT-F7）\n|cffaaffaa悬停满足条件时持续提示；成功施放后自动取消勾选（一次性）|r", saveVariable = "SS_ZZXS", section = "插入", defaultState = false },
            { row = 3, column = 3, IconID = 135967, text = "|cff00adf0指向拯救|r", tooltipText = "开启后，对|cff00adf0鼠标指向|r的队友施放|cff00adf0拯救之手|r（颜色提示，按键 CTRL-F10）\n|cffaaffaa悬停满足条件时持续提示；成功施放后自动取消勾选（一次性）|r", saveVariable = "SS_ZZJZ", section = "插入", defaultState = false },
        },
    },
}