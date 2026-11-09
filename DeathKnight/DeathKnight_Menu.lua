if WR_PlayerClass ~= "DEATHKNIGHT" then return end

DeathKnight_Menu = {
  ["鲜血"] = {
    DM = {
      { text = "|cffC41E3A防ADD|r", menuItems = { { text = "|cffC41E3A是|r" }, { text = "|cffC41E3A否|r" } }, tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击", saveVariable = "FANG_ADD_Blood", defaultID = 1 },
      { text = "|cffC41E3A天赋|r", menuItems = { { text = "|cffC41E3A坦克练级|r" }, { text = "|cffC41E3A输出|r" } }, tooltipText = "选择|cffff0000坦克|ror|cffff0000输出|r模式,输出循环不一样", saveVariable = "DK_Blood_ZZ", defaultID = 1 },
      -- ★ 新增输出模式下拉菜单
      {
        text = "|cffC41E3A输出模式|r",
        menuItems = {
          { text = "|cffC41E3A单拉模式|r" },
          { text = "|cffC41E3AAOE模式|r" },
        },
        tooltipText = "选择输出循环模式\n|cffff0000单拉模式|r：优先单体仇恨和生存，血液沸腾/枯萎凋零受智能AOE开关控制\n|cffff0000AOE模式|r：优先范围伤害和传染，血液沸腾/枯萎凋零不受智能AOE开关影响（始终尝试）",
        saveVariable = "DK_Blood_OutputMode",
        defaultID = 1
      },
      { text = "|cffC41E3A寒霜刺骨|r", menuItems = { { text = "|cffC41E3A5|r" }, { text = "|cffC41E3A6|r" }, { text = "|cffC41E3A7|r" }, { text = "|cffC41E3A8|r" }, { text = "|cffC41E3A9|r" }, { text = "|cffC41E3A10|r" }, { text = "|cffC41E3A禁用|r" } }, tooltipText = "ICC冰龙的技能|cff00adf0寒霜刺骨|r层数大于等于设定值，自动停手(|cff00adf0冰龙|r技能)", saveVariable = "DK_Blood_HSCG", defaultID = 7 },
      { text = "|cffC41E3A吸血鬼|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "生命值低于设定值使用|cff00adf0吸血鬼之血|r\n", saveVariable = "DK_Blood_ZDXXGZX" },
      { text = "|cffC41E3A符文分流|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "生命值低于设定值使用|cff00adf0符文分流|r\n", saveVariable = "DK_Blood_ZDFWFL" },
      { text = "|cffC41E3A灵界打击|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "非持有蓝绿符文时,生命值低于设定值使用|cff00adf0灵界打击|r\n", saveVariable = "DK_Blood_LJDJHP" },
      { text = "|cffC41E3A符文打击|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 40, tooltipText = "在符文武器使用后.多少能量以上打符文打击", saveVariable = "DK_Blood_FWDJ" },
      { text = "|cffC41E3A凋零缠绕|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 60, tooltipText = "填充的凋零缠绕多少能量以上打凋零缠绕", saveVariable = "DK_Blood_DLCR" },
      { text = "|cffC41E3A打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "DK_Blood_DD" },
    },
    CB = {
            -- ★ SoD 探索赛季：符文/技能总开关（菜单勾选写入 PigSet，WR_SoD_HasRune 读取）
            { row = 50, column = 1, IconID = 136243, text = "|cff00ff00SoD总开关|r", tooltipText = "SoD 探索赛季总开关：取消勾选后抑制全部符文技能提示（回退无符文基线）。默认开启。", saveVariable = "SOD_ENABLE", defaultState = true },
            { row = 51, column = 1, IconID = 136243, text = "|cff00ff00死亡打击|r", tooltipText = "SoD 符文【死亡打击】开关：取消勾选则不再提示该符文技能（需已刻印符文才生效）。默认开启。", saveVariable = "SOD_DeathStrike", defaultState = true },
            { row = 51, column = 2, IconID = 136243, text = "|cff00ff00瘟疫打击|r", tooltipText = "SoD 符文【瘟疫打击】开关：取消勾选则不再提示该符文技能（需已刻印符文才生效）。默认开启。", saveVariable = "SOD_Pestilence", defaultState = true },
      -- ★ 2026-08-21：自动冰霜灵气（DKT 蓝脸，最优先）开关
      { row = 1, column = 6, IconID = 135773, text = "|cffC41E3A蓝脸|r", tooltipText = "自动切回|cff00adf0冰霜灵气|r（锁蓝脸，DKT 坦克标准灵气，提供护甲+仇恨；当前三种灵气均未激活时提示切换）。逻辑优先级为全循环最优先。手动切换按 |cffff0000SHIFT-F10|r（冰霜灵气宏，原空槽50）", saveVariable = "DK_Blood_ZDBHLQ", defaultState = true },
      { row = 1, column = 1, IconID = 136120, text = "|cffC41E3A坦克|r", tooltipText = "巫妖王和冰龙的自动使用|cffff0000反魔法护罩|r抵挡|cffff0000灵魂收割|r和|cffff0000冰霜吐息|r", saveVariable = "DK_Blood_ZDFMFHZ", defaultState = false },
      { row = 1, column = 2, IconID = 237525, text = "|cffC41E3A坦克|r", tooltipText = "巫妖王的对其他都无效,自动使用|cffff0000冰封之韧|r抵挡|cffff0000灵魂收割|r和|cffff0000冰霜吐息|r", saveVariable = "DK_Blood_ZDBFZR", defaultState = true },
      { row = 1, column = 3, IconID = 237523, text = "|cffC41E3A停手|r", tooltipText = "|cffff0000辛达苟萨|r和|cffff0000海里昂|r自动停平砍", saveVariable = "DK_Blood_ZDTS", defaultState = false },
      { row = 1, column = 4, IconID = 237517, text = "|cffC41E3A坦克|r", tooltipText = "蓝绿符文自动使用|cffff0000灵界打击|r\n消耗", saveVariable = "DK_Blood_ZDLJDJ", defaultState = true },
      { row = 1, column = 5, IconID = 135675, text = "|cffC41E3A坦克|r", tooltipText = "自动使用|cffff0000心脏打击|r\n,坦克打开才会用心脏打击.特定情况不想拉到另外个怪用,一般可常开", saveVariable = "DK_Blood_ZDXZDJ", defaultState = true },
      -- ★ 新增偷药开关
      { row = 2, column = 1, IconID = 236871, text = "|cffC41E3A偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "DK_Blood_TOUYAO", section = "爆发", defaultState = false },
      { row = 2, column = 2, IconID = 136146, text = "|cffC41E3A坦克\n插入|r", tooltipText = "插入|cffff0000天灾契约|r,会先招宝宝,再吃是个组合技能.必须有招宝宝雕文", saveVariable = "DK_Blood_CRTZQY", section = "插入", defaultState = false },
      { row = 2, column = 3, IconID = 237526, text = "|cffC41E3A插入\n冰触|r", tooltipText = "插入|cffff0000冰触|r,满级团本起手用的,所有能打冰触的符文先打完冰触还会用掉符文分流和符文武器", saveVariable = "DK_Blood_CR6BC", section = "插入", defaultState = false },
      { row = 2, column = 4, IconID = 136144, text = "|cffC41E3A智能\nAOE|r", tooltipText = "坦克输出共用", saveVariable = "DK_Blood_KWDL", defaultState = true },      { row = 3, column = 1, IconID = 136047, text = "|cffC41E3A锁BOSS|r", tooltipText = "自动锁定可以攻击的BOSS\n,这个是TOC的双子自动锁对应目标和ICC议会", saveVariable = "DK_Blood_Suo", defaultState = false },
      { row = 3, column = 2, IconID = 133712, text = "|cffC41E3A炸弹|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r\n", saveVariable = "DK_Blood_ZD", defaultState = true },
      { row = 3, column = 3, IconID = 237512, text = "|cffC41E3A焦点|r", tooltipText = "坦克/输出模式均可,爆发时对焦点玩家|cffff0000邪恶狂热|r", saveVariable = "DK_Blood_ZDXEKR_F", defaultState = true },
      { row = 3, column = 4, IconID = 135277, text = "|cffC41E3A自动|r", tooltipText = "输出模式专用,自动|cffff0000符文刃舞|r,包括输出模式的符文武器增效", saveVariable = "DK_Blood_ZDFWRW", defaultState = true },
      { row = 3, column = 5, IconID = 237512, text = "|cffC41E3A自己|r", tooltipText = "坦克/输出模式均可。DBM倒数≤3秒(未进战斗)即预拉提前对自己|cffff0000邪恶狂热|r(满攻速起手);进战斗后若未触发则按爆发正常补。对白名单Boss或|cff00adf0木桩(训练假人)|r均生效,木桩也可测试;预开窗口受「偷药预开时间」控制", saveVariable = "DK_Blood_ZDXEKR_P", defaultState = true },
      { row = 4, column = 1, IconID = 135727, text = "|cffC41E3A自动|r", tooltipText = "自动使用|cff00adf0种族|r", saveVariable = "DK_Blood_ZDZZ", section = "爆发", defaultState = true },
      { row = 4, column = 2, IconID = 236871, text = "|cffC41E3A自动|r", tooltipText = "自动使用|cff00adf0速度药水|r\n", saveVariable = "DK_Blood_ZDSDYS", section = "爆发", defaultState = false },
      { row = 4, column = 3, IconID = 132977, text = "|cffC41E3A自动|r", tooltipText = "自动使用|cff00adf0手套|r\n", saveVariable = "DK_Blood_ZDST", section = "爆发", defaultState = true },
      { row = 5, column = 1, IconID = 237511, text = "|cffC41E3A插入|r", tooltipText = "插入|cffff0000亡者大军|r", saveVariable = "DK_Blood_CRWZDJ", showSpell = "亡者大军", section = "插入", defaultState = false },
      { row = 5, column = 2, IconID = 132205, text = "|cffC41E3A插入|r", tooltipText = "插入|cffff0000鲜血印记|r", saveVariable = "DK_Blood_CRXXYJ", showSpell = "鲜血印记", section = "插入", defaultState = false },
      { row = 5, column = 3, IconID = 136144, text = "|cffC41E3A插入|r", tooltipText = "插入|cffff0000枯萎凋零|r", saveVariable = "DK_Blood_CRKWDL", showSpell = "枯萎凋零", section = "插入", defaultState = false },
      { row = 5, column = 4, IconID = 135277, text = "|cffC41E3A插入|r", tooltipText = "插入|cffff0000符文刃舞|r", saveVariable = "DK_Blood_CRFWRW", showSpell = "符文刃舞", section = "插入", defaultState = false },
      -- ★ 自动切目标开关
      { row = 6, column = 1, IconID = 132293, text = "|cffC41E3A切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标（坦克用于快速切目标建立仇恨）", saveVariable = "DK_Blood_TAB", defaultState = false },
    },
  },
  ["冰霜"] = {
    DM = {
      { text = "|cffC41E3A防ADD|r", menuItems = { { text = "|cffC41E3A是|r" }, { text = "|cffC41E3A否|r" } }, tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击", saveVariable = "FANG_ADD_BDK", defaultID = 1 },
      { text = "|cffC41E3A天赋|r", menuItems = { { text = "|cffC41E3A自动识别|r" }, { text = "|cffC41E3A血冰|r" }, { text = "|cffC41E3A邪冰|r" } }, tooltipText = "冰DK 分支循环选择\n|cffff0000自动识别|r：按蔓延天赋/疾病时长自动判定（0点蔓延=血冰，满蔓延=邪冰）\n|cffff0000血冰|r：疾病15s，补病更早、泄能更保守（阈值≈疾病×0.3 / 能量60）\n|cffff0000邪冰|r：疾病24s，补病更晚、AOE/传染更积极（阈值≈疾病×0.35 / 能量80）", saveVariable = "DK_BDK_TF", defaultID = 1 },
      { text = "|cffC41E3A魔印切换|r", menuItems = { { text = "|cffC41E3A首次湮没|r" }, { text = "|cffC41E3A首次触发|r" }, { text = "|cffC41E3A循环切换|r" }, { text = "|cffC41E3A禁用|r" } }, tooltipText = "背包或装备栏同时拥有|cffff0000恶意魔印|r和|cffff0000警觉魔印|r时生效。\n|cffff0000首次湮没|r：开打第一发湮没完成后换警觉魔印。\n|cffff0000首次触发|r：开打第一次触发不洁之力后换警觉魔印。\n|cffff0000循环切换|r：触发不洁之力后换警觉魔印，效果结束后换回恶意魔印。\n前三种模式脱战时都会自动换回恶意魔印", saveVariable = "DK_BDK_MYQH", defaultID = 4 },
      { text = "|cffC41E3A免费凛风|r", menuItems = { { text = "|cffC41E3A湮没前|r" }, { text = "|cffC41E3A湮没后冰打前|r" }, { text = "|cffC41E3A最低填充|r" } }, tooltipText = "调整免费凛风冲击（冰冻之雾触发）的优先级：\n|cffff0000湮没前|r：优先于湮没使用\n|cffff0000湮没后冰打前|r：湮没后用、普通冰霜打击前（默认）\n|cffff0000最低填充|r：放在普通冰霜打击后的最低填充位置", saveVariable = "DK_BDK_LFCJ_YXJ", defaultID = 2 },
      { text = "|cffC41E3A寒霜刺骨|r", menuItems = { { text = "|cffC41E3A5|r" }, { text = "|cffC41E3A6|r" }, { text = "|cffC41E3A7|r" }, { text = "|cffC41E3A8|r" }, { text = "|cffC41E3A9|r" }, { text = "|cffC41E3A10|r" }, { text = "|cffC41E3A禁用|r" } }, tooltipText = "|cff00adf0寒霜刺骨|r层数大于等于设定值，自动停手(|cff00adf0冰龙|r技能)", saveVariable = "DK_BDK_HSCG", defaultID = 7 },
      { text = "|cffC41E3A打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "DK_BDK_DD" },
    },
    CB = {
            -- ★ SoD 探索赛季：符文/技能总开关（菜单勾选写入 PigSet，WR_SoD_HasRune 读取）
            { row = 50, column = 1, IconID = 136243, text = "|cff00ff00SoD总开关|r", tooltipText = "SoD 探索赛季总开关：取消勾选后抑制全部符文技能提示（回退无符文基线）。默认开启。", saveVariable = "SOD_ENABLE", defaultState = true },
            { row = 51, column = 1, IconID = 136243, text = "|cff00ff00死亡打击|r", tooltipText = "SoD 符文【死亡打击】开关：取消勾选则不再提示该符文技能（需已刻印符文才生效）。默认开启。", saveVariable = "SOD_DeathStrike", defaultState = true },
            { row = 51, column = 2, IconID = 136243, text = "|cff00ff00瘟疫打击|r", tooltipText = "SoD 符文【瘟疫打击】开关：取消勾选则不再提示该符文技能（需已刻印符文才生效）。默认开启。", saveVariable = "SOD_Pestilence", defaultState = true },      { row = 1, column = 2, IconID = 136047, text = "|cffC41E3A锁BOSS|r", tooltipText = "96,自动锁定可以攻击的BOSS\n,这个是TOC的双子自动锁对应目标和ICC议会", saveVariable = "DK_BDK_Suo", defaultState = false },
      { row = 1, column = 3, IconID = 133712, text = "|cffC41E3A炸弹|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r\n", saveVariable = "DK_BDK_ZD", defaultState = true },
      { row = 1, column = 4, IconID = 236871, text = "|cffC41E3A自动|r", tooltipText = "使用|cff00adf0速度药水|r\n", saveVariable = "DK_BDK_ZDSDYS", section = "爆发", defaultState = false },
      -- ★ 新增偷药开关
      { row = 1, column = 5, IconID = 236871, text = "|cffC41E3A偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "DK_BDK_TOUYAO", section = "爆发", defaultState = false },
      { row = 2, column = 1, IconID = 132388, text = "|cffC41E3A自动|r", tooltipText = "使用|cff00adf0铜墙铁壁|r\n", saveVariable = "DK_BDK_ZDTQTB", defaultState = true },
      { row = 3, column = 1, IconID = 341980, text = "|cffC41E3A天降|r", tooltipText = "新天赋|cff00adf0死从天降|r：爆发且|cff00adf0铜墙铁壁|r期间、周围≥2怪时插入", saveVariable = "DK_BDK_SCTJ", section = "爆发", defaultState = true },
      { row = 2, column = 2, IconID = 135372, text = "|cffC41E3A自动|r", tooltipText = "使用|cff00adf0符文武器增效|r\n", saveVariable = "DK_BDK_ZDFWWQZX", defaultState = true },
      { row = 2, column = 3, IconID = 135727, text = "|cffC41E3A自动|r", tooltipText = "使用|cff00adf0种族|r\n", saveVariable = "DK_BDK_ZDZZ", section = "爆发", defaultState = true },
      { row = 2, column = 4, IconID = 132977, text = "|cffC41E3A手套|r", tooltipText = "自动使用手套\n", saveVariable = "DK_BDK_ZDST", section = "爆发", defaultState = true },
      { row = 3, column = 2, IconID = 237520, text = "|cffC41E3A能量|r", tooltipText = "冰霜打击是否留20能量,打钩为留20能量", saveVariable = "DK_BDK_BSDJ", defaultState = false },
      { row = 3, column = 3, IconID = 236871, text = "|cffC41E3A不灭|r", tooltipText = "开启后，爆发期间自动使用不灭药水（与速度药水共用逻辑，先喝速度后喝不灭）", saveVariable = "DK_BDK_BMYSH", section = "爆发", defaultState = false },
      { row = 4, column = 1, IconID = 237511, text = "|cffC41E3A插入|r", tooltipText = "插入|cffff0000亡者大军|r", saveVariable = "DK_BDK_CRWZDJ", showSpell = "亡者大军", section = "插入", defaultState = false },
      { row = 4, column = 4, IconID = 237511, text = "|cffC41E3A倒数\n大军|r", tooltipText = "开启后，DBM开怪倒数剩余14至15秒时，如果亡者大军可用会先切换邪恶灵气，再引导亡者大军；引导结束或起手取消后自动切回鲜血灵气。", saveVariable = "DK_BDK_COUNTDOWN_ARMY", section = "插入", defaultState = false },
      { row = 4, column = 2, IconID = 136144, text = "|cffC41E3A插入|r", tooltipText = "插入|cffff0000枯萎凋零|r", saveVariable = "DK_BDK_CRKWDL", showSpell = "枯萎凋零", section = "插入", defaultState = false },
      { row = 4, column = 3, IconID = 237527, text = "|cffC41E3A灵气|r", tooltipText = "自动切回|cff00adf0鲜血灵气|r（锁红脸，三种灵气均未激活时）", saveVariable = "DK_BDK_ZDBSLQ", defaultState = true },
      -- ★ 自动切目标开关
      { row = 5, column = 1, IconID = 132293, text = "|cffC41E3A切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "DK_BDK_TAB", defaultState = false },
      { row = 5, column = 2, IconID = 136213, text = "|cffC41E3A冰寒|r", tooltipText = "新天赋|cff00adf0黑锋冰寒|r：爆发/杀戮机器时自动开，使下次冰触/凛风/冰打/湮没必爆", saveVariable = "DK_BDK_HFCH", section = "爆发", defaultState = true },
      -- ★ ZZ 移植：AOE 总开关 + 铁壁黑锋冰寒联动
      { row = 5, column = 3, IconID = 135974, text = "|cffC41E3AAOE|r", tooltipText = "周围至少2个敌人且未强制单目标时，自动使用|cffff0000传染、凛风冲击、血液沸腾和多目标死从天降|r；部分首领机制怪会被排除", saveVariable = "DK_BDK_AOE", defaultState = true },
      { row = 5, column = 4, IconID = 136213, text = "|cffC41E3A自动|r", tooltipText = "铜墙铁壁期间，湮没满足原有释放条件且黑锋冰寒可用时，先使用黑锋冰寒再打湮没", saveVariable = "DK_BDK_ZDHFBH", defaultState = true },
      -- ★ ZZ 移植：亡者复生自动开关（双死亡符文闸门版）
      { row = 5, column = 5, IconID = 237511, text = "|cffC41E3A复生|r", tooltipText = "ZZ 移植：自动|cffff0000亡者复生|r——双病剩余>7.5s+0.5 且双死亡符文就绪时才召唤（避免卡符文），需亡者复生雕文", saveVariable = "DK_BDK_WZFS_ZD", defaultState = true },
      -- ★ ZZ 移植：一次性插入开关（死从天降 / 铜墙铁壁）
      { row = 6, column = 1, IconID = 136216, text = "|cffC41E3A插入\n死从天降|r", tooltipText = "ZZ 移植：一次性插入|cffff0000死从天降|r——可用即放（无视铜墙/目标数），CD>2s 自动关", saveVariable = "DK_BDK_CRSCTJ", showSpell = "死从天降", section = "插入", defaultState = false },
      { row = 6, column = 2, IconID = 132388, text = "|cffC41E3A插入\n铜墙|r", tooltipText = "ZZ 移植：一次性插入|cffff0000铜墙铁壁|r——CD 剩余≤15s 提前插（双病>1.5s 防断病），施放成功自动关", saveVariable = "DK_BDK_CRTQTB", showSpell = "铜墙铁壁", section = "插入", defaultState = false },
    },
  },
  ["邪恶"] = {
    DM = {
      { text = "|cffC41E3A防ADD|r", menuItems = { { text = "|cffC41E3A是|r" }, { text = "|cffC41E3A否|r" } }, tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击", saveVariable = "FANG_ADD_XDK", defaultID = 1 },
      { text = "|cffC41E3A天赋|r", menuItems = { { text = "|cffC41E3A双手邪|r" }, { text = "|cffC41E3A天打双持邪|r" }, { text = "|cffC41E3A普通双持邪|r" } }, tooltipText = "|cff00adf0天赋|r选择,双手就是拿双手武器,恶意是TOC的一个魔印叫恶意魔印(现在没有),普通双持邪为现在常用天赋", saveVariable = "DK_XDK_TF", defaultID = 3 },
      { text = "|cffC41E3A寒霜刺骨|r", menuItems = { { text = "|cffC41E3A5|r" }, { text = "|cffC41E3A6|r" }, { text = "|cffC41E3A7|r" }, { text = "|cffC41E3A8|r" }, { text = "|cffC41E3A9|r" }, { text = "|cffC41E3A10|r" }, { text = "|cffC41E3A禁用|r" } }, tooltipText = "|cff00adf0寒霜刺骨|r层数大于等于设定值，自动停手(|cff00adf0冰龙|r技能)", saveVariable = "DK_XDK_HSCG", defaultID = 7 },
      { text = "|cffC41E3A打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "施法进度达到该百分比时自动打断（0=关闭，默认50）", saveVariable = "DK_XDK_DD" },
    },
    CB = {
            -- ★ SoD 探索赛季：符文/技能总开关（菜单勾选写入 PigSet，WR_SoD_HasRune 读取）
            { row = 50, column = 1, IconID = 136243, text = "|cff00ff00SoD总开关|r", tooltipText = "SoD 探索赛季总开关：取消勾选后抑制全部符文技能提示（回退无符文基线）。默认开启。", saveVariable = "SOD_ENABLE", defaultState = true },
            { row = 51, column = 1, IconID = 136243, text = "|cff00ff00死亡打击|r", tooltipText = "SoD 符文【死亡打击】开关：取消勾选则不再提示该符文技能（需已刻印符文才生效）。默认开启。", saveVariable = "SOD_DeathStrike", defaultState = true },
            { row = 51, column = 2, IconID = 136243, text = "|cff00ff00瘟疫打击|r", tooltipText = "SoD 符文【瘟疫打击】开关：取消勾选则不再提示该符文技能（需已刻印符文才生效）。默认开启。", saveVariable = "SOD_Pestilence", defaultState = true },      { row = 1, column = 2, IconID = 132977, text = "|cffC41E3A手套|r", tooltipText = "天鬼后3秒.或者天鬼冷却期>60秒自动使用手套\n", saveVariable = "DK_XDK_ZDST", section = "爆发", defaultState = true },
      { row = 1, column = 3, IconID = 135727, text = "|cffC41E3A自动|r", tooltipText = "兽人天鬼前,巨魔天鬼后3秒,其他种族没用.使用|cff00adf0种族|r\n", saveVariable = "DK_XDK_ZDZZ", section = "爆发", defaultState = true },
      { row = 1, column = 4, IconID = 236871, text = "|cffC41E3A自动|r", tooltipText = "天鬼3秒后使用|cff00adf0速度药水|r\n", saveVariable = "DK_XDK_ZDSDYS", section = "爆发", defaultState = false },
      -- ★ 新增偷药开关
      { row = 1, column = 5, IconID = 236871, text = "|cffC41E3A偷药|r", tooltipText = "开启后，爆发期间自动使用速度药水（含DBM倒数提前开）", saveVariable = "DK_XDK_TOUYAO", section = "爆发", defaultState = false },
      { row = 1, column = 6, IconID = 136216, text = "|cffC41E3A攻击|r", tooltipText = "控制|cff00adf0宠物|r", saveVariable = "DK_XDK_KZBB", defaultState = true },
      { row = 2, column = 1, IconID = 133712, text = "|cffC41E3A炸弹|r", tooltipText = "使用|cff00adf0通用热力工程炸药|r或|cff00adf0萨隆邪铁炸弹|r\n", saveVariable = "DK_XDK_ZDZD", defaultState = true },
      { row = 2, column = 2, IconID = 135770, text = "|cffC41E3A自动|r", tooltipText = "使用完|cff00adf0召唤石像鬼|r\n自动回到红脸\n|cff00adf0召唤石像鬼|r\n", saveVariable = "DK_XDK_ZDXXLQ", defaultState = true },
      { row = 2, column = 3, IconID = 135775, text = "|cffC41E3A自动|r", tooltipText = "|cff00adf0召唤石像鬼|r\n在场自动绿脸", saveVariable = "DK_XDK_ZDXELQ", defaultState = true },
      { row = 2, column = 4, IconID = 132182, text = "|cffC41E3A嗜血|r", tooltipText = "嗜血或者英勇期自动召唤天鬼,自己会计算buff能否触发,是否有十字军,buff时间是否够,\n如果你开出来的时机不对大概率是你的被动饰品数据库里没有.请告知我", saveVariable = "DK_XDK_ZHSXG_ZD", section = "爆发", defaultState = true },
      { row = 2, column = 5, IconID = 237511, text = "|cffC41E3A嗜血|r", tooltipText = "天鬼后接王者大军", saveVariable = "DK_XDK_WZDJ_ZD", section = "爆发", defaultState = true },
      { row = 3, column = 1, IconID = 136182, text = "|cffC41E3A自动|r", tooltipText = "是否使用传染技能控制开关", saveVariable = "DK_XDK_CR", showSpell = "传染", defaultState = true },
      { row = 3, column = 2, IconID = 136144, text = "|cffC41E3A自动|r", tooltipText = "自动使用|cffff0000枯萎凋零|r", saveVariable = "DK_XDK_ZDKWDL", defaultState = true },
      { row = 3, column = 3, IconID = 237515, text = "|cffC41E3A自动|r", tooltipText = "自动使用|cffff0000活力分流|r", saveVariable = "DK_XDK_HLFL_ZD", defaultState = true },
      { row = 3, column = 4, IconID = 237530, text = "|cffC41E3A双手邪的|r", tooltipText = "恶意和双手的判定\n,常开即可", saveVariable = "DK_XDK_TZDJ", defaultState = true },
      { row = 3, column = 5, IconID = 136047, text = "|cffC41E3ABOSS锁定|r", tooltipText = "96,自动锁定可以攻击的BOSS\n,这个是TOC的双子自动锁对应目标和ICC议会", saveVariable = "DK_XDK_Suo", defaultState = false },
      { row = 4, column = 1, IconID = 237527, text = "|cffC41E3A换武器|r", tooltipText = "用系统自带的换装系统存一套叫十字军,一套叫黑魔法", saveVariable = "DK_HMF", defaultState = false },
      { row = 4, column = 2, IconID = 135775, text = "|cffC41E3A脱战|r", tooltipText = "|cff00adf0召唤石像鬼|r\n在场自动绿脸", saveVariable = "DK_XDK_ZDXELQ_TZ", defaultState = true },
      { row = 4, column = 3, IconID = 136145, text = "|cffC41E3A自动|r", tooltipText = "|cff00adf0凋零缠绕|r\n控制开关", saveVariable = "DK_XDK_DLCR", defaultState = true },
      { row = 5, column = 1, IconID = 237511, text = "|cffC41E3A插入|r", tooltipText = "插入|cffff0000亡者大军|r", saveVariable = "DK_XDK_CRWZDJ", section = "插入", defaultState = false },
      { row = 5, column = 2, IconID = 136144, text = "|cffC41E3A插入|r", tooltipText = "插入|cffff0000枯萎凋零|r", saveVariable = "DK_XDK_CRKWDL", section = "插入", defaultState = false },
      { row = 5, column = 3, IconID = 132182, text = "|cffC41E3A秒开|r", tooltipText = "插入|cffff0000召唤石像鬼|r", saveVariable = "DK_XDK_CRSXG", defaultState = false },
      { row = 5, column = 4, IconID = 132182, text = "|cffC41E3A带判断|r", tooltipText = "插入带判断buff和十字军的|cffff0000召唤石像鬼|r", saveVariable = "DK_XDK_CRSXG_DPD", defaultState = false },
      { row = 6, column = 1, IconID = 237511, text = "|cffC41E3A自动\n起手|r", tooltipText = "次开关为单次插入起手式 手动先切绿脸 开打10秒前补好骨盾 狂乱,不到10秒就不要补了\n冰>暗>血>凋零>符文武器>天鬼>冰>暗>血>吃药种族手套>大军.传说中的完美起手.触不触发全看脸", saveVariable = "DK_XDK_ZDQS_QJ", defaultState = false },
      { row = 6, column = 2, IconID = 132182, text = "|cffC41E3A自动\n起手|r", tooltipText = "次开关为单次插入起手式 有天鬼无大军版本", saveVariable = "DK_XDK_ZDQS_TG_QJ", defaultState = false },
      { row = 6, column = 5, IconID = 132182, text = "|cffC41E3ATOC\n老一|r", tooltipText = "次开关为单次插入起手式 有天鬼无大军版本", saveVariable = "DK_XDK_ZDQS_TG_TOC", defaultState = false },
      -- ★ 自动切目标开关
      { row = 7, column = 1, IconID = 132293, text = "|cffC41E3A切目标|r", tooltipText = "开启后，自动切换到最近的可攻击目标", saveVariable = "DK_XDK_TAB", defaultState = false },
    },
  },
}