-- 法师菜单总表
if WR_PlayerClass ~= "MAGE" then return end

Mage_Menu = {
  -- ==================== 奥术专精 ====================
  -- 2026-11-16 按「猪猪 / 彼岸花-无限服 · 奥法页」重做（Forever 60级技能）：
  -- 旧 80 级体系（奥术弹幕/奥术涌动/法力宝石/镜像/冰冷血脉/偷药/饰品/手套/
  -- 炸弹/隐身术/狂咒等）全部下线，旧档由 Mage_Arcane_Features.lua 迁移。
  ["奥术"] = {
    -- ===== 下拉菜单（DM） =====
    DM = {
      { text = "|cff69CCF0防ADD|r", menuItems = { { text = "|cff69CCF0是|r" }, { text = "|cff69CCF0否|r" } }, tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击", saveVariable = "AF_FADD", defaultID = 1 },
      { text = "|cff69CCF0喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "血量低于该百分比时自动喝治疗药水（0 = 关闭，默认30）", saveVariable = "AF_HXY" },
      { text = "|cff69CCF0打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 60, tooltipText = "目标施法进度达到该百分比时自动法术反制（0 = 关闭，默认60）", saveVariable = "AF_FSFZ" },
      { text = "|cff69CCF0魔杖回蓝|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "蓝量低于该百分比且无技能可打时用魔杖填充（0 = 关闭，默认50）", saveVariable = "AF_MZHL" },
      { text = "|cff69CCF0奥爆|r", isSlider = true, minValue = 0, maxValue = 10, valueStep = 1, defaultVal = 0, tooltipText = "8码内敌人达到该数量时使用魔爆术（0 = 关闭，默认关闭）", saveVariable = "AF_AOBAO" },
      { text = "|cff69CCF0爆发全开|r", isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开 奥术强化 / 气定神闲 / 种族爆发", onClick = "WR_MageArcaneBurstAllOn" },
      { text = "|cff69CCF0爆发全关|r", isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭 奥术强化 / 气定神闲 / 种族爆发", onClick = "WR_MageArcaneBurstAllOff" },
      { text = "|cff69CCF0爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "三个爆发开关任意一个开着就全关，全关就全开", onClick = "WR_MageArcaneBurstToggle" },
    },
    -- ===== 复选框（CB） =====
    CB = {
      -- 功能（右键图标打开额外条件）
      { row = 1, column = 1, IconID = 136096, text = "|cff69CCF0读条引导|r", tooltipText = "读条引导总开关：开着时按右键里的设置放奥术冲击、奥术飞弹、奥术愤怒和勾上的填充技能。\n\n「打法」叠加/无脑/奥术愤怒三选一；叠层层数、愤怒层数、蓝量、有节能就打都在右键小窗里调。\n\n关掉后右键里的技能一个都不放（只剩瞬发技能、唤醒和魔杖）。\n宏：/MAGE_CAST 切换（后面加 on 开、off 关）", saveVariable = "AF_CAST", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageArcaneFeatures then WR_MageArcaneFeatures.ShowOptions("AF_CAST") end end },
      { row = 1, column = 2, IconID = 135843, text = "|cff69CCF0护甲|r", tooltipText = "护甲功能：自己身上没有右键里选中的那种甲就自动补上（冰甲术 / 魔甲术 二选一）；战斗内外都补。\n\n右键选择护甲种类。\n宏：/MAGE_ARMOR_ON 切换（后面加 on 开、off 关）", saveVariable = "AF_ARMOR", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageArcaneFeatures then WR_MageArcaneFeatures.ShowOptions("AF_ARMOR") end end },
      { row = 1, column = 3, IconID = 135932, text = "|cff69CCF0奥术智慧|r", tooltipText = "奥术智慧功能：脱战后身上没有奥术智慧、或者剩不到 1 分钟就自动补；给自己加/给小队加在右键里勾。\n\n右键设置 自己 / 小队。\n宏：/MAGE_INTELLECT 切换（后面加 on 开、off 关）", saveVariable = "AF_INT", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageArcaneFeatures then WR_MageArcaneFeatures.ShowOptions("AF_INT") end end },
      { row = 1, column = 4, IconID = 132293, text = "|cff69CCF0切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标", saveVariable = "AF_TAB", section = "功能", defaultState = true },
      { row = 1, column = 5, IconID = 136082, text = "|cff69CCF0驱散|r", tooltipText = "驱散功能：自己或小队有诅咒/疾病时用解除次级诅咒；目标有魔法增益时法术偷取。\n\n右键可分别关闭 自己 / 小队 / 法术偷取。\n宏：/MAGE_QS 切换（后面加 on 开、off 关）", saveVariable = "AF_QS", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageArcaneFeatures then WR_MageArcaneFeatures.ShowOptions("AF_QS") end end },
      -- 爆发（截图：奥术强化 / 气定神闲 / 种族爆发）
      { row = 1, column = 1, IconID = 136048, text = "|cff69CCF0奥术强化|r", tooltipText = "自动使用奥术强化（15秒内法术伤害+30%，法力消耗+30%）", saveVariable = "AF_ZDASQH", section = "爆发", defaultState = true },
      { row = 1, column = 2, IconID = 135932, text = "|cff69CCF0气定神闲|r", tooltipText = "自动使用气定神闲（下一个施法时间低于10秒的法术变瞬发）", saveVariable = "AF_ZDQDSX", section = "爆发", defaultState = true },
      { row = 1, column = 3, IconID = 135727, text = "|cff69CCF0种族爆发|r", tooltipText = "自动使用种族爆发技能", saveVariable = "AF_ZDZZ", section = "爆发", defaultState = true },
      -- 插入（一次性，放完自关）
      { row = 1, column = 1, IconID = 135848, text = "|cff69CCF0冰环|r", tooltipText = "插入 冰霜新星（一次性，放完自关）", saveVariable = "AF_CRBH", section = "插入", defaultState = false },
      { row = 1, column = 2, IconID = 135826, text = "|cff69CCF0烈焰风暴|r", tooltipText = "插入 烈焰风暴（一次性，放完自关）", saveVariable = "AF_CRLYFB", section = "插入", defaultState = false },
      { row = 1, column = 3, IconID = 135857, text = "|cff69CCF0暴风雪|r", tooltipText = "插入 暴风雪（一次性，放完自关）", saveVariable = "AF_CRBFX", section = "插入", defaultState = false },
      { row = 1, column = 4, IconID = 136116, text = "|cff69CCF0魔爆术|r", tooltipText = "插入 魔爆术（一次性，放完自关）", saveVariable = "AF_CRMB", section = "插入", defaultState = false },
      { row = 1, column = 5, IconID = 135736, text = "|cff69CCF0闪现|r", tooltipText = "插入 闪现术（一次性，放完自关）", saveVariable = "AF_CRSX", section = "插入", defaultState = false },
    },
  },

  -- ==================== 火焰专精 ====================
  -- 2026-11-16 按「猪猪 / 彼岸花-无限服 · 火法页」重做（Forever 60级技能）：
  -- 旧 80 级体系（活动炸弹/镜像/冰冷血脉/法力宝石/冰枪术/速度药水/狂野魔法/
  -- 饰品/手套/炸弹/雪球/偷药/5爆等）全部下线，旧档由 Mage_Fire_Features.lua 迁移。
  ["火焰"] = {
    -- ===== 下拉菜单（DM） =====
    DM = {
      { text = "|cff69CCF0防ADD|r", menuItems = { { text = "|cff69CCF0是|r" }, { text = "|cff69CCF0否|r" } }, tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击", saveVariable = "HY_FADD", defaultID = 1 },
      { text = "|cff69CCF0喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "血量低于该百分比时自动喝治疗药水（0 = 关闭，默认30）", saveVariable = "HY_HXY" },
      { text = "|cff69CCF0打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 60, tooltipText = "目标施法进度达到该百分比时自动法术反制（0 = 关闭，默认60）", saveVariable = "HY_FSFZ" },
      { text = "|cff69CCF0魔杖回蓝|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "蓝量低于该百分比且无技能可打时用魔杖填充（0 = 关闭，默认50）", saveVariable = "HY_MZHL" },
      { text = "|cff69CCF0奥爆|r", isSlider = true, minValue = 0, maxValue = 10, valueStep = 1, defaultVal = 0, tooltipText = "8码内敌人达到该数量时使用魔爆术（0 = 关闭，默认关闭）", saveVariable = "HY_AOBAO" },
      { text = "|cff69CCF0爆发全开|r", isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开 燃烧 / 种族爆发", onClick = "WR_MageFireBurstAllOn" },
      { text = "|cff69CCF0爆发全关|r", isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭 燃烧 / 种族爆发", onClick = "WR_MageFireBurstAllOff" },
      { text = "|cff69CCF0爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "两个爆发开关任意一个开着就全关，全关就全开", onClick = "WR_MageFireBurstToggle" },
    },
    -- ===== 复选框（CB） =====
    CB = {
      -- 功能（右键图标打开额外条件）
      { row = 1, column = 1, IconID = 135812, text = "|cff69CCF0读条引导|r", tooltipText = "读条引导总开关：开着时按右键里勾上的技能放读条技能，从上到下就是先后：炎爆术、灼烧、霜火之箭、火球术、寒冰箭。\n\n名字后面的灰字 = 要点哪一系的天赋才有，没学会的勾了也放不出来。\n\n关掉后右键里的读条技能一个都不放（只剩瞬发技能和魔杖）。\n宏：/MAGE_CAST 切换（后面加 on 开、off 关）", saveVariable = "HY_CAST", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageFireFeatures then WR_MageFireFeatures.ShowOptions("HY_CAST") end end },
      { row = 1, column = 2, IconID = 135843, text = "|cff69CCF0护甲|r", tooltipText = "护甲功能：自己身上没有右键里选中的那种甲就自动补上（冰甲术 / 魔甲术 二选一）；战斗内外都补。\n\n右键选择护甲种类。\n宏：/MAGE_ARMOR_ON 切换（后面加 on 开、off 关）", saveVariable = "HY_ARMOR", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageFireFeatures then WR_MageFireFeatures.ShowOptions("HY_ARMOR") end end },
      { row = 1, column = 3, IconID = 135932, text = "|cff69CCF0奥术智慧|r", tooltipText = "奥术智慧功能：脱战后身上没有奥术智慧、或者剩不到 1 分钟就自动补；给自己加/给小队加在右键里勾。\n\n右键设置 自己 / 小队。\n宏：/MAGE_INTELLECT 切换（后面加 on 开、off 关）", saveVariable = "HY_INT", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageFireFeatures then WR_MageFireFeatures.ShowOptions("HY_INT") end end },
      { row = 1, column = 4, IconID = 132293, text = "|cff69CCF0切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标", saveVariable = "HY_TAB", section = "功能", defaultState = true },
      { row = 1, column = 5, IconID = 136082, text = "|cff69CCF0驱散|r", tooltipText = "驱散功能：自己或小队有诅咒/疾病时用解除次级诅咒；目标有魔法增益时法术偷取。\n\n右键可分别关闭 自己 / 小队 / 法术偷取。\n宏：/MAGE_QS 切换（后面加 on 开、off 关）", saveVariable = "HY_QS", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageFireFeatures then WR_MageFireFeatures.ShowOptions("HY_QS") end end },
      -- 爆发（截图：燃烧 / 种族爆发）
      { row = 1, column = 1, IconID = 135824, text = "|cff69CCF0燃烧|r", tooltipText = "自动使用燃烧（火焰法术暴击率提高，持续到 3 次非周期性爆击）", saveVariable = "HY_ZD_RS", section = "爆发", defaultState = true },
      { row = 1, column = 2, IconID = 135727, text = "|cff69CCF0种族爆发|r", tooltipText = "自动使用种族爆发技能", saveVariable = "HY_ZDZZ", section = "爆发", defaultState = true },
      -- 插入（一次性，放完自关；截图两行：第一行4个，第二行2个）
      { row = 1, column = 1, IconID = 135848, text = "|cff69CCF0冰环|r", tooltipText = "插入 冰霜新星（一次性，放完自关）", saveVariable = "HY_CRBH", section = "插入", defaultState = false },
      { row = 1, column = 2, IconID = 135826, text = "|cff69CCF0烈焰风暴|r", tooltipText = "插入 烈焰风暴（一次性，放完自关）", saveVariable = "HY_CRLYFB", section = "插入", defaultState = false },
      { row = 1, column = 3, IconID = 135857, text = "|cff69CCF0暴风雪|r", tooltipText = "插入 暴风雪（一次性，放完自关）", saveVariable = "HY_CRBFX", section = "插入", defaultState = false },
      { row = 1, column = 4, IconID = 136116, text = "|cff69CCF0魔爆术|r", tooltipText = "插入 魔爆术（一次性，放完自关）", saveVariable = "HY_CRMB", section = "插入", defaultState = false },
      { row = 2, column = 1, IconID = 135736, text = "|cff69CCF0闪现|r", tooltipText = "插入 闪现术（一次性，放完自关）", saveVariable = "HY_CRSX", section = "插入", defaultState = false },
      { row = 2, column = 2, IconID = "Interface\\Icons\\Spell_Holy_Excorcism_02", text = "|cff69CCF0冲击波|r", tooltipText = "插入 冲击波（一次性，放完自关）", saveVariable = "HY_CRCSB", section = "插入", defaultState = false },
    },
  },

  -- ==================== 冰霜专精 ====================
  -- 2026-11-16 按「猪猪 / 彼岸花-无限服 · 冰霜页」重做（Forever 60级技能）：
  -- 旧 80 级体系（隐身术/狂咒/镜像/冰冷血脉/法力宝石/偷药/饰品/手套/炸弹/
  -- 宝宝攻击/2+1冰枪/深冻/寒冰宝珠等）全部下线，旧档由 Mage_Frost_Features.lua 迁移。
  ["冰霜"] = {
    -- ===== 下拉菜单（DM） =====
    DM = {
      { text = "|cff69CCF0防ADD|r", menuItems = { { text = "|cff69CCF0是|r" }, { text = "|cff69CCF0否|r" } }, tooltipText = "是否开启防ADD,打开的情况下需要目标进入战斗才会攻击", saveVariable = "BF_FADD", defaultID = 1 },
      { text = "|cff69CCF0喝红药|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 30, tooltipText = "血量低于该百分比时自动喝治疗药水（0 = 关闭，默认30）", saveVariable = "BF_HXY" },
      { text = "|cff69CCF0打断|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 60, tooltipText = "目标施法进度达到该百分比时自动法术反制（0 = 关闭，默认60）", saveVariable = "BF_FSFZ" },
      { text = "|cff69CCF0魔杖回蓝|r", isSlider = true, minValue = 0, maxValue = 100, valueStep = 5, defaultVal = 50, tooltipText = "蓝量低于该百分比且无技能可打时用魔杖填充（0 = 关闭，默认50）", saveVariable = "BF_MZHL" },
      { text = "|cff69CCF0奥爆|r", isSlider = true, minValue = 0, maxValue = 10, valueStep = 1, defaultVal = 0, tooltipText = "8码内敌人达到该数量时使用魔爆术（0 = 关闭，默认关闭）", saveVariable = "BF_AOBAO" },
      { text = "|cff69CCF0爆发全开|r", isButton = true, buttonText = "全部打开", buttonWidth = 90, labelWidth = 95, tooltipText = "一键打开 种族爆发", onClick = "WR_MageFrostBurstAllOn" },
      { text = "|cff69CCF0爆发全关|r", isButton = true, buttonText = "全部关闭", buttonWidth = 90, labelWidth = 95, tooltipText = "一键关闭 种族爆发", onClick = "WR_MageFrostBurstAllOff" },
      { text = "|cff69CCF0爆发切换|r", isButton = true, buttonText = "切换", buttonWidth = 90, labelWidth = 95, tooltipText = "种族爆发开着就全关，全关就全开", onClick = "WR_MageFrostBurstToggle" },
    },
    -- ===== 复选框（CB） =====
    CB = {
      -- 功能（右键图标打开额外条件）
      { row = 1, column = 1, IconID = 135812, text = "|cff69CCF0读条引导|r", tooltipText = "读条引导总开关：开着时按右键里勾上的技能放读条技能，从上到下就是先后：炎爆术、灼烧、寒冰箭、霜火之箭、火球术。\n\n名字后面的灰字 = 要点哪一系的天赋才有，没学会的勾了也放不出来。\n\n移动中自动打瞬发的冰枪术填充。\n\n关掉后右键里的读条技能一个都不放（只剩冰枪术和魔杖）。\n宏：/MAGE_CAST 切换（后面加 on 开、off 关）", saveVariable = "BF_CAST", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageFrostFeatures then WR_MageFrostFeatures.ShowOptions("BF_CAST") end end },
      { row = 1, column = 2, IconID = 135843, text = "|cff69CCF0护甲|r", tooltipText = "护甲功能：自己身上没有右键里选中的那种甲就自动补上（冰甲术 / 魔甲术 二选一）；战斗内外都补。\n\n右键选择护甲种类。\n宏：/MAGE_ARMOR_ON 切换（后面加 on 开、off 关）", saveVariable = "BF_ARMOR", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageFrostFeatures then WR_MageFrostFeatures.ShowOptions("BF_ARMOR") end end },
      { row = 1, column = 3, IconID = 135932, text = "|cff69CCF0奥术智慧|r", tooltipText = "奥术智慧功能：脱战后身上没有奥术智慧、或者剩不到 1 分钟就自动补；给自己加/给小队加在右键里勾。\n\n右键设置 自己 / 小队。\n宏：/MAGE_INTELLECT 切换（后面加 on 开、off 关）", saveVariable = "BF_INT", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageFrostFeatures then WR_MageFrostFeatures.ShowOptions("BF_INT") end end },
      { row = 1, column = 4, IconID = 132293, text = "|cff69CCF0切换目标|r", tooltipText = "没有目标/目标死亡时，自动选择最近的可攻击目标", saveVariable = "BF_TAB", section = "功能", defaultState = true },
      { row = 2, column = 1, IconID = 136082, text = "|cff69CCF0驱散|r", tooltipText = "驱散功能：自己或小队有诅咒/疾病时用解除次级诅咒；目标有魔法增益时法术偷取。\n\n右键可分别关闭 自己 / 小队 / 法术偷取。\n宏：/MAGE_QS 切换（后面加 on 开、off 关）", saveVariable = "BF_QS", section = "功能", defaultState = true,
        onRightClick = function() if WR_MageFrostFeatures then WR_MageFrostFeatures.ShowOptions("BF_QS") end end },
      { row = 2, column = 2, IconID = 135841, text = "|cff69CCF0寒冰护体|r", tooltipText = "寒冰护体功能：自己身上没有寒冰护体护盾时自动补上（吸收伤害 + 冰霜伤害提高15%，持续1分钟）。\n\n关掉后不再自动补盾。\n插入区的「寒冰护体」不受本开关控制。", saveVariable = "BF_HBT", section = "功能", defaultState = true },
      -- 爆发（截图：种族爆发）
      { row = 1, column = 1, IconID = 135727, text = "|cff69CCF0种族爆发|r", tooltipText = "自动使用种族爆发技能", saveVariable = "BF_ZZ", section = "爆发", defaultState = true },
      -- 插入（一次性，放完自关；截图两行：第一行4个，第二行3个）
      { row = 1, column = 1, IconID = 135848, text = "|cff69CCF0冰环|r", tooltipText = "插入 冰霜新星（一次性，放完自关）", saveVariable = "BF_CRBH", section = "插入", defaultState = false },
      { row = 1, column = 2, IconID = 135826, text = "|cff69CCF0烈焰风暴|r", tooltipText = "插入 烈焰风暴（一次性，放完自关）", saveVariable = "BF_CRLYFB", section = "插入", defaultState = false },
      { row = 1, column = 3, IconID = 135857, text = "|cff69CCF0暴风雪|r", tooltipText = "插入 暴风雪（一次性，放完自关）", saveVariable = "BF_CRBFX", section = "插入", defaultState = false },
      { row = 1, column = 4, IconID = 136116, text = "|cff69CCF0魔爆术|r", tooltipText = "插入 魔爆术（一次性，放完自关）", saveVariable = "BF_CRMB", section = "插入", defaultState = false },
      { row = 2, column = 1, IconID = 135736, text = "|cff69CCF0闪现|r", tooltipText = "插入 闪现术（一次性，放完自关）", saveVariable = "BF_CRSX", section = "插入", defaultState = false },
      { row = 2, column = 2, IconID = 135841, text = "|cff69CCF0寒冰屏障|r", tooltipText = "插入 寒冰屏障（一次性，放完自关）", saveVariable = "BF_CRBZ", section = "插入", defaultState = false },
      { row = 2, column = 3, IconID = 135843, text = "|cff69CCF0寒冰护体|r", tooltipText = "插入 寒冰护体（一次性，放完自关）", saveVariable = "BF_CRHT", section = "插入", defaultState = false },
    },
  },
}
