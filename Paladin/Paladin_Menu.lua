-- ★ 2026-11-17 职业隔离：非本职业直接跳过，避免职业代码/全局符号污染
if WR_PlayerClass and WR_PlayerClass ~= "PALADIN" then return end
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
    -- 1. 惩戒专精 (Retribution) —— 2026-11-15 按「彼岸花-无限服 · 惩戒页」重做
    -- ==========================================================
    ["惩戒"] = {
        -- ===== 下拉菜单（DM）：选择 / 拉条 =====
        DM = {
            -- 防ADD
            {
                text = "|cffF58CBA防ADD|r",
                menuItems = { { text = "|cffF58CBA是|r" }, { text = "|cffF58CBA否|r" } },
                tooltipText = "是否开启防ADD：打开时，需要目标已进入战斗才会主动攻击。",
                saveVariable = "FANG_ADD_CJQ",
                defaultID = 1
            },
            -- 拉条（截图口径：喝红药 90 / 圣疗术 69 / 奉献 4目标）
            { text = "|cffF58CBA喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 90,
              tooltipText = "自己血量低于设定值时自动喝治疗药水（0 = 不喝）。", saveVariable = "CJ_HXY" },
            { text = "|cffF58CBA圣疗术|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 1, defaultVal = 69,
              tooltipText = "自己血量低于设定值时使用圣疗术自疗（0 = 不使用）。", saveVariable = "CJ_SLLS" },
            { text = "|cffF58CBA奉献|r", isSlider = true, minValue = 0, maxValue = 10, valueStep = 1, defaultVal = 4,
              tooltipText = "身边 8 码内敌人达到该数量时自动使用奉献（0 = 不使用）。", saveVariable = "CJ_FX_COUNT" },
            -- 祝福设置按钮（三专精统一入口；功能区的「祝福」图标也能右键打开）
            {
                text = "",
                isButton = true,
                buttonText = "祝福设置",
                onClick = "WR_OpenPaladinBlessing",
                tooltipText = "打开|cff00adf0祝福设置列表|r：单人 / 小队 / 团队分别配置力量·智慧·王者祝福，脱战自动补祝福。",
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- ===== 功能 =====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Ability_Warrior_Innerrage", text = "|cffF58CBA圣印|r", tooltipText = "圣印总开关：管理常驻圣印 / 解封之怒舞 / 审判维持。\n右键打开额外条件。\n宏：/PALADIN_RET_SEAL 切换", saveVariable = "CJ_SY_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_PaladinRetUI and WR_PaladinRetUI.ShowOptions then WR_PaladinRetUI.ShowOptions("CJ_SY") end end },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings", text = "|cffF58CBA祝福|r", tooltipText = "脱战自动补祝福。\n右键打开祝福设置列表（单人 / 小队 / 团队）。\n宏：/PALADIN_RET_BLESS 切换", saveVariable = "CJ_BLESS_ON", section = "功能", defaultState = true,
              onRightClick = function() if type(WR_OpenPaladinBlessing) == "function" then WR_OpenPaladinBlessing() end end },
            { row = 1, column = 3, IconID = 132293, text = "|cffF58CBA切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标。", saveVariable = "CJ_TAB", section = "功能", defaultState = true },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Spell_Holy_DispelMagic", text = "|cffF58CBA驱散|r", tooltipText = "自动使用清洁术驱散中毒 / 疾病 / 魔法（不能解诅咒）。\n右键选驱散模式（常规 / 优先 / 目标 / 指向）。", saveVariable = "CJ_QJS_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_PaladinRetUI and WR_PaladinRetUI.ShowOptions then WR_PaladinRetUI.ShowOptions("CJ_QJS") end end },
            { row = 2, column = 1, IconID = "Interface\\Icons\\Ability_ThunderClap", text = "|cffF58CBA愤怒之锤|r", tooltipText = "目标进入斩杀期时自动使用愤怒之锤。", saveVariable = "CJ_FNZS", section = "功能", defaultState = true },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Spell_Holy_Excorcism_02", text = "|cffF58CBA驱邪术|r", tooltipText = "目标为亡灵/恶魔时自动使用驱邪术。", saveVariable = "CJ_QXS", section = "功能", defaultState = true },

            -- ===== 插入（一次性，放完自关） =====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Holy_SealOfMight", text = "|cffF58CBA制裁|r", tooltipText = "插入制裁之锤：目标正在读条时使用一次，放完自动关闭。", saveVariable = "CJ_CRZC", section = "插入", defaultState = false },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Holy_Restoration", text = "|cffF58CBA圣佑|r", tooltipText = "插入圣佑术：自己血量过低（30%）时使用一次，放完自动关闭。", saveVariable = "CJ_CRSYS", section = "插入", defaultState = false },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Spell_Holy_RighteousnessAura", text = "|cffF58CBA审判|r", tooltipText = "插入审判：身上有圣印时使用一次，放完自动关闭。", saveVariable = "CJ_CRSP", section = "插入", defaultState = false },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Spell_Holy_Innerfire", text = "|cffF58CBA奉献|r", tooltipText = "插入奉献：身边怪数达到「奉献」拉条时使用一次，放完自动关闭。", saveVariable = "CJ_CRFL", section = "插入", defaultState = false },
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
            -- ★ 2026-11-11：圣印选择已从下拉框改为「圣印」专区的按钮（见 CB 列表末尾）。
            --   顺序必须与 Paladin_Forever.lua 的 WR_PaladinForever_SealOptions 严格一致：
            --   1=十字军圣印(30) 2=正义圣印(47) 3=愤怒圣印(11)
            --   4=光明圣印·回血(54) 5=智慧圣印·回蓝(108) 6=公正圣印(9)
            -- ★ 祝福选择（防护专精）：下拉框已删除，改为「祝福设置」按钮，
            --   位置按用户口径放在「打断」滑块下方（见本 DM 列表末尾）。
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
                tooltipText = "|cff00adf0常规：驱散所有Debuff。|r\n|cffffdf00优先：驱散所有Debuff(高优先级)。\n|cffadff2f目标：仅驱散当前目标的Debuff。|r\n|cff9bf6ff指向：仅驱散指向队友的Debuff。|r\n|cffff5040（清洁术只能驱散中毒/疾病/魔法，不能解诅咒）|r",
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
                tooltipText = "开启|cff00adf0全局保护（自动保护之手）|r后，战斗内团内非坦克队友血量≤阈值时自动对其施放|cff00adf0保护之手|r（自律期间不会施放）\n|cffaaffaa禁用|r：不自动补，仅鼠标指向施放\n（本下拉仅控制团血自动补，与「指向保护」插入复选框相互独立）",
                saveVariable = "FH_ZZBH_HP",
                defaultID = 4
            },
            { text = "|cffF58CBA打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动用制裁之锤打断（0=关闭，默认50）", saveVariable = "FH_DD" },
            -- ★ 2026-11-11：按用户口径放在「打断」下方：祝福下拉框 → 「祝福设置」按钮
            {
                -- 用户口径「祝福设置保留，祝福两个字剔除」：按钮保名「祝福设置」，左侧标签不再写「祝福」
                text = "",
                isButton = true,
                buttonText = "祝福设置",
                onClick = "WR_OpenPaladinBlessing",
                tooltipText = "打开|cff00adf0祝福设置列表|r：单人 / 小队 / 团队分别配置力量·智慧·王者祝福，脱战自动补祝福。\n（原「祝福」下拉框已删除）",
            },
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
            { row = 2, column = 4, IconID = 135926, text = "|cffF58CBA自动|r", tooltipText = "使用|cff00adf0奉献|r\n\n|cffaaffaa多目标循环（8 码内目标 ≥2 个）|r：\n审判 → 神圣打击 → 驱邪术（可用就打）→ 神圣之盾\n|cffaaffaa奉献仅在 8 码内目标 ≥3 个时使用|r，作为第一优先，需要蓝量 ≥30%（低于 30% 不施放）且目标在近战 5 码内。\n\n|cffaaffaa目标 ≤1 个|r：奉献降到最后一档，需目标 ≥3 个、蓝量 ≥30%（低于 30% 不施放）。", saveVariable = "FH_FX", defaultState = true },
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
            -- ==========================================================
            -- ★★ 2026-11-11：审判buff 专区（三个 buff 维持开关，可折叠；位于「圣印」专区上方）
            --   光明圣印 / 十字军审判 / 智慧审判，三者互斥（PAL_PROT_JUDGEMENT_SEAL）。
            -- ==========================================================
            -- ★★ 2026-11-11：原「插入 光明圣印」一次性流程改为「光明圣印」常驻开关
            { row = 1, column = 1, IconID = 135917, text = "|cffF58CBA光明圣印|r", tooltipText = "光明圣印|cff00adf0 buff 常驻开关|r（原「插入光明圣印」改造，宏 CTRL-F11 / 颜色槽 54）\n\n|cffaaffaa勾选后一直生效（不会自动取消）：|r\n1. 平时维持面板「圣印」专区所选常驻圣印（仇恨/嘲讽来源不断档）\n2. |cff00adf0审判 CD 只剩 2 秒（含已就绪）|r 且目标没有「光明审判 / 圣光审判」debuff 时，才切光明圣印 → 提示|cff00adf0审判|r 挂 debuff\n3. 目标已有|cff00adf0光明审判 / 圣光审判|r 时，自动提示切回当前常驻圣印（面板选愤怒就切愤怒）\n4. 光明审判持续 40 秒，到期后重新等下一个「审判 CD ≤2 秒」窗口\n\n|cffff5040注意|r：圣印同一时间只能有一个，切光明会暂时顶掉常驻圣印（仇恨/嘲讽来源），\n|cffaaffaa切印时机已修正|r：不再一勾选就切印干等审判 CD，只在审判快好时才切；\n与「十字军审判」「智慧审判」开关互斥（同时只能开一个），\n但可与「圣印」专区所选圣印共存（常驻已选光明圣印时同样有效）。\n未学会光明圣印或审判时自动跳过，不影响循环。", saveVariable = "FH_CRGMSY", section = "审判buff", defaultState = false, exclusiveGroup = "PAL_PROT_JUDGEMENT_SEAL" },
            -- ★ 2026-11-09：插入 智慧圣印（回复法力；宏 ALT-SHIFT-F8 / 颜色槽 108）
            { row = 5, column = 3, IconID = 135970, text = "|cffF58CBA插入|r", tooltipText = "插入|cff00adf0智慧圣印|r（一次性）\n\n|cffaaffaa勾选后，等「审判」CD 转好时执行一次：|r\n1. 提示切到|cff00adf0智慧圣印|r（槽位 108，宏 ALT-SHIFT-F8）\n2. 切印完成后提示|cff00adf0审判|r，让这一发审判带上智慧圣印效果（回蓝）\n3. 审判打出后|cffaaffaa自动取消勾选|r，本次插入结束\n\n|cffff5040注意|r：圣印同一时间只能有一个，切智慧会暂时顶掉常驻圣印（仇恨来源），\n所以只在缺蓝时用；平时保持关闭。\n切印后 10 秒内没打出审判会自动放弃并取消勾选，不会卡住。\n未学会智慧圣印或审判时自动跳过，不影响循环。", saveVariable = "FH_CRZHSY", section = "插入", defaultState = false },
            -- ★ 自动切目标开关
            { row = 6, column = 1, IconID = 132293, text = "|cffF58CBA切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标（坦克用于快速切目标建立仇恨）", saveVariable = "FH_TAB", defaultState = false },
            -- ★ 指向保护 / 指向牺牲（鼠标指向施放，团血阈值可选）
            { row = 6, column = 2, IconID = 135964, text = "|cff00adf0指向保护|r", tooltipText = "开启后，对|cff00adf0鼠标指向|r的队友施放|cff00adf0保护之手|r（优先级最高）\n战斗内外均可：脱战也可鼠标指向|cff00adf0预读保护|r（开怪前先套）\n|cffaaffaa施放成功后自动取消勾选（一次性），悬停不再反复触发|r\n（本复选框仅控制鼠标指向直接插入；团血自动补由上方「全局保护」下拉独立控制，不受本复选框影响）", saveVariable = "FH_ZZBH", section = "插入", defaultState = false },
            { row = 6, column = 3, IconID = 135966, text = "|cff00adf0指向牺牲|r", tooltipText = "开启后，对|cff00adf0鼠标指向|r的队友施放|cff00adf0牺牲之手|r（优先级最高）\n战斗内外均可：脱战也可鼠标指向|cff00adf0预读牺牲|r（开怪前先套）\n|cffaaffaa施放成功后自动取消勾选（一次性），悬停不再反复触发|r\n（本复选框仅控制鼠标指向直接插入；不参与团血自动补，与「全局保护」下拉相互独立）", saveVariable = "FH_ZZXS", section = "插入", defaultState = false },
            { row = 6, column = 4, IconID = 135967, text = "|cff00adf0指向拯救|r", tooltipText = "开启后，对|cff00adf0鼠标指向|r的队友施放|cff00adf0拯救之手|r（减威胁，优先级最高）\n战斗内外均可：脱战也可鼠标指向|cff00adf0预读拯救|r（开怪前先套）\n|cffaaffaa施放成功后自动取消勾选（一次性），悬停不再反复触发|r\n（拯救为减威胁技能，仅鼠标指向直接插入，无团血自动补）", saveVariable = "FH_ZZJZ", section = "插入", defaultState = false },
            -- ★★ 2026-11-11：删除「单体」循环开关（FH_DT）。原「十字军圣印 → 审判 → 切回」起手
            --   由下方「十字军审判」buff 维持开关取代（常驻维持，不再是一次性起手）。
            -- ★★ 2026-11-11：十字军审判 buff 维持开关（与「光明圣印」常驻开关同款状态机）
            { row = 1, column = 2, IconID = 135924, text = "|cffF58CBA十字军审判|r", tooltipText = "十字军审判|cff00adf0 buff 维持开关|r（十字军圣印，宏 ALT-NUMPAD0 / 颜色槽 30）\n\n|cffaaffaa勾选后一直生效（不会自动取消）：|r\n1. 平时维持面板「圣印」专区所选常驻圣印（仇恨/嘲讽来源不断档）\n2. |cff00adf0审判 CD 只剩 2 秒（含已就绪）|r 且目标没有「十字军审判」debuff 时，才切十字军圣印 → 提示|cff00adf0审判|r 挂 debuff\n3. 目标已有「十字军审判」debuff 时，自动提示切回当前常驻圣印\n4. 十字军审判持续 40 秒，到期后重新等下一个「审判 CD ≤2 秒」窗口\n\n|cffff5040注意|r：圣印同一时间只能有一个，切十字军会暂时顶掉常驻圣印（仇恨/嘲讽来源），\n|cffaaffaa切印时机已修正|r：不再一勾选就切印干等审判 CD，只在审判快好时才切；\n与「光明圣印」「智慧审判」开关互斥（同时只能开一个），\n但可与「圣印」专区所选圣印共存（常驻已选十字军圣印时同样有效）。\n未学会十字军圣印或审判时自动跳过，不影响循环。", saveVariable = "FH_SZJSP", section = "审判buff", defaultState = false, exclusiveGroup = "PAL_PROT_JUDGEMENT_SEAL" },
            -- ★★ 2026-11-11：智慧审判 buff 维持开关（与「光明圣印」「十字军审判」同款状态机）
            { row = 1, column = 3, IconID = 135970, text = "|cffF58CBA智慧审判|r", tooltipText = "智慧审判|cff00adf0 buff 维持开关|r（智慧圣印，宏 ALT-SHIFT-F8 / 颜色槽 108）\n\n|cffaaffaa勾选后一直生效（不会自动取消）：|r\n1. 平时维持面板「圣印」专区所选常驻圣印（仇恨/嘲讽来源不断档）\n2. |cff00adf0审判 CD 只剩 2 秒（含已就绪）|r 且目标没有「智慧审判」debuff 时，才切智慧圣印 → 提示|cff00adf0审判|r 挂 debuff（攻击/法术有几率回蓝）\n3. 目标已有「智慧审判」debuff 时，自动提示切回当前常驻圣印\n4. 智慧审判持续 40 秒，到期后重新等下一个「审判 CD ≤2 秒」窗口\n\n|cffff5040注意|r：圣印同一时间只能有一个，切智慧会暂时顶掉常驻圣印（仇恨/嘲讽来源），\n|cffaaffaa切印时机已修正|r：不再一勾选就切印干等审判 CD，只在审判快好时才切；\n与「光明圣印」「十字军审判」开关互斥（同时只能开一个），\n但可与「圣印」专区所选圣印共存（常驻已选智慧圣印时同样有效）。\n未学会智慧圣印或审判时自动跳过，不影响循环。", saveVariable = "FH_ZHSP", section = "审判buff", defaultState = false, exclusiveGroup = "PAL_PROT_JUDGEMENT_SEAL" },
            -- ★ 2026-11-08：神圣之盾开关（常驻；默认开 = 保持原有行为）
            { row = 7, column = 1, IconID = 135880, text = "|cffF58CBA神圣之盾|r", tooltipText = "开启后，防护循环会在|cff00adf0神圣之盾|r冷却好时提示施放（防护核心减伤/仇恨）。\n\n|cffaaffaa默认勾选|r，与加入此开关之前的行为一致。\n关闭后循环不再提示神圣之盾，适合想手动控制、或该技能浪费蓝量时。\n未学会神圣之盾时不会提示（与开关无关）。", saveVariable = "FH_SZS", defaultState = true },
            -- ★★ 2026-11-16：神圣之盾「目标为我」开关（默认关 = 原行为）
            { row = 7, column = 2, IconID = 135880, text = "|cffF58CBA目标为我|r", tooltipText = "|cff00adf0神圣之盾·目标为我|r（勾选本项会自动开启左侧「神圣之盾」总开关）\n\n|cffaaffaa开启后：|r只有当前目标（怪）的目标是|cff00adf0玩家自己|r时才提示神圣之盾；目标打别人、没有目标或读不到目标的目标时都不提示。\n\n|cffaaffaa关闭时：|r保持原行为——神圣之盾冷却好且已学会就提示，不检查怪物的目标。\n\n适合只在怪确实打你（被围 / 聚怪）时开盾，避免怪打别人时浪费蓝量和 GCD。", saveVariable = "FH_SZS_TARGETME", defaultState = false, requiresVariable = "FH_SZS" },
            -- ★★ 2026-11-13：愤怒之锤斩杀开关（默认开 = 目标 <20% 自动收尾）
            { row = 7, column = 3, IconID = 132326, text = "|cffF58CBA愤怒之锤|r", tooltipText = "开启后，目标进入|cff00adf0斩杀期|r时自动提示|cff00adf0愤怒之锤|r斩杀收尾（30 码，宏 NUMPAD1 / 颜色槽 1，本地 6 秒 CD，读条 0.87 秒，耗蓝 295）。\n\n|cffaaffaa触发条件：|r面板开关开 + 目标进入斩杀期（本服隐藏目标血量：血量可读时按 <20%，不可读时按客户端「愤怒之锤可用」判定，等价于生命 <20%）+ 目标可攻击且存活 + 30 码内 + 冷却转好 + 蓝量 ≥20%（低于 20% 不点亮，防止斩杀读条拖垮资源）。\n\n|cffaaffaa优先级衔接：|r多目标链：奉献（≥3 目标）→ 审判 → 愤怒之锤 → 神圣打击 → 驱邪术 → 神圣之盾；\n单体链：神圣打击（CD 好永远优先）→ 审判/神圣打击 Ready-first → 愤怒之锤 → 驱邪术 → 奉献 → 神圣之盾。\n\n|cffaaffaa读条保护：|r读条 0.87 秒 + 提示保持 1.5 秒窗口内整条循环让路，其它技能色块不会覆盖打断（打断 = 白烧 295 蓝零收益）。\n\n|cffff5040关闭后|r：主链与兜底环节都不再提示愤怒之锤。\n\n|cffaaffaa精英限定：|r右侧「精英」开关勾选后，只对精英怪 / BOSS 提示（详见该按钮说明）。", saveVariable = "FH_FNZC", defaultState = true },
            -- ★★ 2026-11-14：愤怒之锤「精英/BOSS 限定」开关（默认关 = 原行为）
            { row = 7, column = 4, IconID = 132326, text = "|cffF58CBA精英|r", tooltipText = "|cff00adf0愤怒之锤·精英/BOSS 限定|r（勾选本项会自动开启左侧「愤怒之锤」总开关）\n\n|cffaaffaa开启后：|r只对|cff00adf0精英怪 / BOSS|r提示愤怒之锤；普通小怪即使进入斩杀期也不提示（省 0.87 秒读条 + 295 蓝）。\n\n|cffaaffaa判定（任一命中即算）：|r目标分类 elite / rareelite / worldboss / boss、boss1~5 单位帧、骷髅级（等级 -1）、UnitIsBoss。\n\n|cffaaffaa关闭时：|r保持原行为——进入斩杀期就对当前目标提示，不限怪物类型。", saveVariable = "FH_FNZC_JY", defaultState = false, requiresVariable = "FH_FNZC" },

            -- ==========================================================
            -- ★★ 2026-11-11：圣印专区（按钮，可折叠；位于「审判buff」专区下方）
            -- ----------------------------------------------------------
            -- 用户口径：「圣印我不喜欢下拉框的，给我设置成按钮，单独弄一个
            -- 圣印专区，此专区在爆发区下，可以折叠」。
            -- 单选按钮：点击即写 PigSet.FH_SEAL = 序号（1十字军30/2正义47/3愤怒11/
            -- 4光明54/5智慧108/6公正9），同组其它按钮自动取消勾选；默认 3=愤怒圣印。
            -- ==========================================================
            { row = 1, column = 1, IconID = 135924, text = "|cffF58CBA十字军|r", tooltipText = "选择|cff00adf0十字军圣印|r作为常驻圣印（槽 30）。\n\n|cffaaffaa点击即选中，同一时间只能选一个；掉了会自动补。|r\n|cffaaffaa可与「十字军审判」buff 维持开关同时生效（两者共存）。|r", radioVariable = "FH_SEAL", radioValue = 1, radioDefault = 3, section = "圣印" },
            { row = 1, column = 2, IconID = 132325, text = "|cffF58CBA正义|r", tooltipText = "选择|cff00adf0正义圣印|r作为常驻圣印（槽 47）。\n\n|cffaaffaa点击即选中，同一时间只能选一个；掉了会自动补。\n审判不产生审判 debuff，不会顶掉光明/智慧审判，正常打。|r", radioVariable = "FH_SEAL", radioValue = 2, radioDefault = 3, section = "圣印" },
            { row = 1, column = 3, IconID = 135957, text = "|cffF58CBA愤怒|r", tooltipText = "选择|cff00adf0愤怒圣印|r作为常驻圣印（槽 11，默认）。\n\n|cffaaffaa点击即选中，同一时间只能选一个；掉了会自动补。|r\n|cffffdf00审判带嘲讽，是防护坦克的仇恨来源。|r\n|cffaaffaa审判不产生审判 debuff，不会顶掉光明/智慧审判，正常打。|r", radioVariable = "FH_SEAL", radioValue = 3, radioDefault = 3, section = "圣印" },
            { row = 1, column = 4, IconID = 135917, text = "|cffF58CBA光明|r", tooltipText = "选择|cff00adf0光明圣印|r作为常驻圣印（槽 54，回血）。\n\n|cffaaffaa点击即选中，同一时间只能选一个；掉了会自动补。|r\n|cffaaffaa可与「光明圣印」buff 常驻开关同时生效（两者共存）。|r", radioVariable = "FH_SEAL", radioValue = 4, radioDefault = 3, section = "圣印" },
            { row = 1, column = 5, IconID = "Interface\\Icons\\Spell_Holy_SealOfWisdom", text = "|cffF58CBA智慧|r", tooltipText = "选择|cff00adf0智慧圣印|r作为常驻圣印（槽 108，回蓝）。\n\n|cffaaffaa点击即选中，同一时间只能选一个；掉了会自动补。|r\n|cffaaffaa可与「智慧审判」buff 维持开关同时生效（两者共存）。|r\n|cffff5040选它时「插入智慧圣印」会自动取消（常驻已经是智慧圣印）。|r", radioVariable = "FH_SEAL", radioValue = 5, radioDefault = 3, section = "圣印" },
            { row = 1, column = 6, IconID = "Interface\\Icons\\Spell_Holy_SealOfJustice", text = "|cffF58CBA公正|r", tooltipText = "选择|cff00adf0公正圣印|r作为常驻圣印（槽 9）。\n\n|cffaaffaa点击即选中，同一时间只能选一个；掉了会自动补。|r", radioVariable = "FH_SEAL", radioValue = 6, radioDefault = 3, section = "圣印" },
        },
    },

    -- ==========================================================
    -- 3. 神圣专精 (Holy) —— 2026-11-15 按「彼岸花-无限服 · 奶骑页」重做
    -- ==========================================================
    ["神圣"] = {
        -- ===== 下拉菜单（DM）：选择 / 拉条 =====
        DM = {
            -- 防ADD
            {
                text = "|cffF58CBA防ADD|r",
                menuItems = { { text = "|cffF58CBA是|r" }, { text = "|cffF58CBA否|r" } },
                tooltipText = "是否开启防ADD：打开时，需要目标已进入战斗才会主动攻击（愤怒之锤/驱邪术/审判等）。",
                saveVariable = "FANG_ADD_SS",
                defaultID = 1
            },
            -- 治疗模式
            {
                text = "|cffF58CBA治疗模式|r",
                menuItems = {
                    { text = "|cffF58CBA全团|r" },
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
                tooltipText = "|cff00adf0全团：自动治疗所有单位，切目标不影响治疗。|r\n|cffffd700目标：有目标时治疗目标，无目标则治疗全团。|r\n|cffadff2f预读：有目标时治疗目标，无目标则治疗全团。|r\n|cff6a5acd泄蓝：有目标时治疗目标，无目标则治疗全团。|r\n|cff996b1f坦克：仅治疗坦克，需要团长设置\"坦克\"职责。|r\n|cff9C3590脆皮：仅治疗脆皮，需要团长设置\"坦克\"职责。|r\n|cfffdffb6队伍：仅治疗选择的队伍（仅团队中生效）。|r",
                saveVariable = "SS_ZLMS",
                defaultID = 1
            },
            -- 拉条
            { text = "|cffF58CBA喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 90,
              tooltipText = "自己血量低于设定值时自动喝治疗药水（0 = 不喝）。", saveVariable = "SS_HXY" },
            { text = "|cffF58CBA圣疗术|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 1, defaultVal = 69,
              tooltipText = "目标/自己血量低于设定值时使用圣疗术（0 = 不使用）。", saveVariable = "SS_SLS" },
            { text = "|cffF58CBA奉献|r", isSlider = true, minValue = 0, maxValue = 10, valueStep = 1, defaultVal = 4,
              tooltipText = "身边 8 码内敌人达到该数量时自动使用奉献（0 = 不使用）。", saveVariable = "SS_FL_COUNT" },
            { text = "|cffF58CBA圣光守望|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 1, defaultVal = 52,
              tooltipText = "目标血量低于设定值时施加圣光守望，为后续神圣震击的小队治疗做准备（0 = 不使用）。", saveVariable = "SS_SGWS" },
            { text = "|cffF58CBA神圣震击|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 1, defaultVal = 54,
              tooltipText = "目标血量低于设定值时使用神圣震击（0 = 不使用）。", saveVariable = "SS_SSZJ" },
            { text = "|cffF58CBA圣光术|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 1, defaultVal = 60,
              tooltipText = "目标血量低于设定值时使用圣光术（0 = 不使用）。", saveVariable = "SS_SGS" },
            { text = "|cffF58CBA圣光闪现|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 1, defaultVal = 85,
              tooltipText = "目标血量低于设定值时使用圣光闪现（0 = 不使用）。", saveVariable = "SS_SGSX" },
            { text = "|cffF58CBA停条窗口|r", isSlider = true, minValue = 1, maxValue = 5, valueStep = 1, defaultVal = 5,
              tooltipText = "过量停条判定窗口：施法剩余时间 ≤ 窗口时，若目标有效血量已满就停止施法。\n1=0.1秒 / 2=0.2秒 / 3=0.3秒 / 4=0.4秒 / 5=0.5秒。\n仅在下方功能「过量停条」开启时生效。", saveVariable = "SS_GLTCCK" },
            -- ★ 2026-11-15：保留「祝福设置」按钮（三专精统一入口；功能区的「祝福」图标也能右键打开）
            {
                text = "",
                isButton = true,
                buttonText = "祝福设置",
                onClick = "WR_OpenPaladinBlessing",
                tooltipText = "打开|cff00adf0祝福设置列表|r：单人 / 小队 / 团队分别配置力量·智慧·王者祝福，脱战自动补祝福。",
            },
        },
        -- ===== 复选框（CB） =====
        CB = {
            -- ===== 功能 =====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Holy_SealOfWisdom", text = "|cffF58CBA圣印|r", tooltipText = "圣印总开关：管理常驻圣印与审判维持。\n右键打开额外条件。", saveVariable = "SS_SY_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_PaladinHolyUI and WR_PaladinHolyUI.ShowOptions then WR_PaladinHolyUI.ShowOptions("SS_SY") end end },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Holy_Greaterblessingoflight", text = "|cffF58CBA圣光誓约|r", tooltipText = "给指定队友保持圣光誓约，没 buff 或剩不到 15 秒时切焦点补。\n右键打开额外条件（给谁加）。", saveVariable = "SS_OATH_ON", section = "功能", defaultState = true,
              onRightClick = function() if WR_PaladinHolyUI and WR_PaladinHolyUI.ShowOptions then WR_PaladinHolyUI.ShowOptions("SS_OATH") end end },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings", text = "|cffF58CBA祝福|r", tooltipText = "脱战自动补祝福。\n右键打开祝福设置列表（单人 / 小队 / 团队）。", saveVariable = "SS_BLESS_ON", section = "功能", defaultState = true,
              onRightClick = function() if type(WR_OpenPaladinBlessing) == "function" then WR_OpenPaladinBlessing() end end },
            { row = 1, column = 4, IconID = 132293, text = "|cffF58CBA切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标。", saveVariable = "SS_TAB", section = "功能", defaultState = true },
            { row = 2, column = 1, IconID = "Interface\\Icons\\Spell_Holy_DispelMagic", text = "|cffF58CBA驱散|r", tooltipText = "自动使用清洁术驱散中毒 / 疾病 / 魔法（不能解诅咒）。", saveVariable = "SS_QJS_ON", section = "功能", defaultState = true },
            { row = 2, column = 2, IconID = "Interface\\Icons\\Ability_ThunderClap", text = "|cffF58CBA愤怒之锤|r", tooltipText = "目标进入斩杀期时自动使用愤怒之锤。", saveVariable = "SS_FNZS", section = "功能", defaultState = true },
            { row = 2, column = 3, IconID = "Interface\\Icons\\Spell_Holy_Excorcism_02", text = "|cffF58CBA驱邪术|r", tooltipText = "目标为亡灵/恶魔时自动使用驱邪术。", saveVariable = "SS_QXS", section = "功能", defaultState = true },
            { row = 2, column = 4, IconID = "Interface\\Icons\\Spell_Holy_HealingAura", text = "|cffF58CBA过量停条|r", tooltipText = "开启后，圣光术/圣光闪现读条到最后一段（窗口由左侧「停条窗口」设置）时，如果目标有效血量已满，就点亮 101 停止施法，避免过量治疗。\n\n|cffff5040泄蓝模式（治疗模式=泄蓝）不受此开关限制。|r", saveVariable = "SS_GLTC", section = "功能", defaultState = false },

            -- ===== 插入（一次性，放完自关） =====
            { row = 1, column = 1, IconID = "Interface\\Icons\\Spell_Holy_SealOfMight", text = "|cffF58CBA制裁|r", tooltipText = "插入制裁之锤：目标正在读条时使用一次，放完自动关闭。", saveVariable = "SS_CRZC", section = "插入", defaultState = false },
            { row = 1, column = 2, IconID = "Interface\\Icons\\Spell_Holy_Restoration", text = "|cffF58CBA圣佑|r", tooltipText = "插入圣佑术：自己血量过低时使用一次，放完自动关闭。", saveVariable = "SS_CRSY", section = "插入", defaultState = false },
            { row = 1, column = 3, IconID = "Interface\\Icons\\Spell_Holy_RighteousnessAura", text = "|cffF58CBA审判|r", tooltipText = "插入审判：身上有圣印时使用一次，放完自动关闭。", saveVariable = "SS_CRSP", section = "插入", defaultState = false },
            { row = 1, column = 4, IconID = "Interface\\Icons\\Spell_Holy_InnerFire", text = "|cffF58CBA奉献|r", tooltipText = "插入奉献：身边敌人达到拉条数量时使用一次，放完自动关闭。", saveVariable = "SS_CRFL", section = "插入", defaultState = false },
        },
    },
}