-- ============================================================
-- Trinket_Burst.lua
-- 功能：管理饰品自动爆发逻辑
-- 包含：
--   1. BOSS白名单（哪些BOSS需要自动爆发）
--   2. 饰品数据表（饰品名称、触发buff、冷却时间、叠层要求）
--   3. 饰品激活检测与爆发窗口计算
--   4. 圣骑/法师/术士特殊机制监控
-- ============================================================

-- ============================================================
-- ★ 1. BOSS白名单
-- ============================================================
function PIG_Zidongbaofa()
    -- ★ 2026-08-21：爆发列表目标过滤（参考 ZZHELPER "设置允许触发自动爆发的团本目标"）。
    --   默认只允许 BOSS 目标爆发（BOSS 默认勾选、小怪默认不勾选）；
    --   目标不在爆发列表（含未勾选的小怪/PvP 目标）→ 直接判定不可爆发。
    if not WR_IsBurstListTarget(WR_SafeUnitName("target")) then return false end
    local BF_Name = {
        ["海里昂"] = {},
        ["训练假人"] = {},
        ["克伯鲁斯"] = {},
        ["岩皮"] = {},
        ["欧泽鲁克"] = {},
        ["高阶女祭司艾苏尔"] = {},
        ["灰葬男爵"] = {},
        ["席瓦莱恩男爵"] = {},
        ["指挥官斯普林瓦尔"] = {},
        ["沃登勋爵"] = {},
        ["高弗雷勋爵"] = {},
        ["胡辛姆将军"] = {},
        ["锁喉"] = {},
        ["高阶预言者巴林姆"] = {},
        ["希亚玛特"] = {},
        ["大宰相埃尔坦"] = {},
        ["阿尔泰鲁斯"] = {},
        ["阿萨德"] = {},
        ["乌比斯将军"] = {},
        ["铸炉之主索朗格斯"] = {},
        ["达加·燃影者"] = {},
        ["埃鲁达克"] = {},
        ["格拉布托克"] = {},
        ["赫利克斯·破甲"] = {},
        ["死神5000"] = {},
        ["撕心狼将军"] = {},
        ["焚妮莎·范克里夫"] = {},
        ["纳兹夏尔女士"] = {},
        ["指挥官乌尔索克"] = {},
        ["蛊心魔厄夏"] = {},
        ["厄祖玛特"] = {},
        ["神殿守护者安努尔"] = {},
        ["地怒者塔赫"] = {},
        ["安拉斐特"] = {},
        ["伊希斯特"] = {},
        ["阿穆纳伊"] = {},
        ["赛特斯"] = {},
        ["拉夏"] = {},
        ["摧骨者罗姆欧格"] = {},
        ["柯尔拉，暮光之兆"] = {},
        ["卡尔什·断钢"] = {},
        ["如花"] = {},
        ["升腾者领主奥西迪斯"] = {},
        ["奥弗"] = {},
        ["伐木场巨怪"] = {},
        ["高阶预言者吧林姆"] = {},
        ["梵妮莎·范克里夫"] = {},
        ["尼希尔"] = {},
        ["安舍尔"] = {},
        ["洛哈西"] = {},
        ["奥拉基尔"] = {},
        ["熔喉暴露的头部"] = {},
        ["熔喉"] = {},
        ["炽焰白骨结构体"] = {},
        ["剧毒金刚"] = {},
        ["电荷金刚"] = {},
        ["奥能金刚"] = {},
        ["熔岩金刚"] = {},
        ["奇美隆"] = {},
        ["艾卓曼德斯"] = {},
        ["马洛拉克"] = {},
        ["邪恶废液"] = {},
        ["畸变怪"] = {},
        ["奈法利安"] = {},
        ["奥妮克希亚"] = {},
        ["原型多彩龙人"] = {},
        ["复生的坚骨战士"] = {},
        ["哈尔弗斯·碎龙者"] = {},
        ["孤单的翡翠雏龙"] = {},
        ["虚空之子"] = {},
        ["风暴骑手"] = {},
        ["瓦里昂娜"] = {},
        ["瑟纳利昂"] = {},
        ["伊格纳休斯"] = {},
        ["费伦迪乌斯"] = {},
        ["源质畸体"] = {},
        ["泰拉斯卓"] = {},
        ["艾里昂"] = {},
        ["古加尔"] = {},
        ["希奈丝特拉"] = {},
        ["阿尔加洛斯"] = {},
        ["纳多克斯长老"] = {},
        ["埃曼尼塔"] = {},
        ["耶戈达·觅影者"] = {},
        ["传令官沃拉兹"] = {},
        ["看门者克里克希尔"] = {},
        ["哈多诺克斯"] = {},
        ["托尔戈"] = {},
        ["召唤者诺沃斯"] = {},
        ["暴龙之王爵德"] = {},
        ["先知萨隆亚"] = {},
        ["斯拉德兰"] = {},
        ["达克莱巨像"] = {},
        ["莫拉比"] = {},
        ["凶残的伊克"] = {},
        ["迦尔达拉"] = {},
        ["比亚格里将军"] = {},
        ["沃尔坎"] = {},
        ["艾欧纳尔"] = {},
        ["洛肯"] = {},
        ["克莱斯塔卢斯"] = {},
        ["悲伤圣女"] = {},
        ["塑铁者斯约尼尔"] = {},
        ["肉钩"] = {},
        ["塑血者沙尔拉姆"] = {},
        ["时光领主埃博克"] = {},
        ["玛尔加尼斯"] = {},
        ["永恒腐蚀者"] = {},
        ["指挥官库鲁尔格"] = {},
        ["大魔导师泰蕾丝塔"] = {},
        ["阿诺玛鲁斯"] = {},
        ["塑树者奥莫洛克"] = {},
        ["克莉斯塔萨"] = {},
        ["审讯者达库斯"] = {},
        ["瓦尔洛斯·云击"] = {},
        ["法师领主伊洛姆"] = {},
        ["魔网守护者埃雷苟斯"] = {},
        ["埃雷克姆"] = {},
        ["湮灭者祖拉玛特"] = {},
        ["谢沃兹"] = {},
        ["艾库隆"] = {},
        ["摩拉格"] = {},
        ["拉文索尔"] = {},
        ["塞安妮苟萨"] = {},
        ["凯尔塞斯王子"] = {},
        ["控制者达尔隆"] = {},
        ["建筑师斯卡瓦尔德"] = {},
        ["劫掠者因格瓦尔"] = {},
        ["席瓦拉·索格蕾"] = {},
        ["戈托克·苍蹄"] = {},
        ["残忍的斯卡迪"] = {},
        ["伊米隆国王"] = {},
        ["纯洁者耶德瑞克"] = {},
        ["银色神官帕尔崔丝"] = {},
        ["黑骑士"] = {},
        ["布隆亚姆"] = {},
        ["噬魂者"] = {},
        ["熔炉之主加弗斯特"] = {},
        ["科瑞克"] = {},
        ["伊克"] = {},
        ["天灾领主泰兰努斯"] = {},
        ["法瑞克"] = {},
        ["马维恩"] = {},
        ["阿努布雷坎"] = {},
        ["黑女巫法琳娜"] = {},
        ["迈克斯纳"] = {},
        ["药剂师诺斯"] = {},
        ["肮脏的希尔盖"] = {},
        ["洛欧塞布"] = {},
        ["教官拉苏维奥斯"] = {},
        ["收割者戈提克"] = {},
        ["帕奇维克"] = {},
        ["格罗布鲁斯"] = {},
        ["格拉斯"] = {},
        ["塔迪乌斯"] = {},
        ["萨菲隆"] = {},
        ["克尔苏加德"] = {},
        ["大领主莫格莱尼"] = {},
        ["库尔塔兹领主"] = {},
        ["瑟里耶克爵士"] = {},
        ["女公爵布劳缪克丝"] = {},
        ["玛里苟斯"] = {},
        ["萨塔里奥"] = {},
        ["掌炉者伊格尼斯"] = {},
        ["锋鳞"] = {},
        ["拆解者之心"] = {},
        ["科隆加恩"] = {},
        ["左臂"] = {},
        ["右臂"] = {},
        ["观察者奥尔加隆"] = {},
        ["欧尔莉亚"] = {},
        ["霍迪尔"] = {},
        ["托里姆"] = {},
        ["VX-001"] = {},
        ["巨兽二型"] = {},
        ["空中指挥单位"] = {},
        ["维扎克斯将军"] = {},
        ["萨隆邪铁畸体"] = {},
        ["尤格-萨隆"] = {},
        ["尤格-萨隆的大脑"] = {},
        ["风暴看守者埃玛尔隆"] = {},
        ["远古监护者"] = {},
        ["雪地狗头人奴隶"] = {},
        ["穿刺者戈莫克"] = {},
        ["加拉克苏斯大王"] = {},
        ["光明邪使菲奥拉"] = {},
        ["黑暗邪使艾蒂丝"] = {},
        ["玛洛加尔领主"] = {},
        ["亡语者女士"] = {},
        ["死亡使者萨鲁法尔"] = {},
        ["腐面"] = {},
        ["烂肠"] = {},
        ["普崔塞德教授"] = {},
        ["凯雷塞斯王子"] = {},
        ["瓦拉纳王子"] = {},
        ["塔达拉姆王子"] = {},
        ["鲜血女王兰娜瑟尔"] = {},
        ["辛达苟萨"] = {},
        ["巫妖王"] = {},
        ["寒冰看守者图拉旺"] = {},
        ["大领主的训练假人"] = {},
        ["新兵的训练假人"] = {},
        ["精兵的的训练假人"] = {},
        ["黑锋骑士的训练假人"] = {},
        ["学徒的训练假人"] = {},
        ["专家的训练假人"] = {},
        ["英雄训练假人"] = {},
        ["大师的训练假人"] = {},
        ["XT-002拆解者"] = { BuffName = "心碎" },
        ["冰吼"] = { BuffName = "重击眩晕" },
        ["断钢者"] = { BuffName = "增压", BuffCount = 2 },
        ["符文大师莫尔基姆"] = { BuffName = "增压", BuffCount = 2 },
        ["唤雷者布隆迪尔"] = { BuffName = "增压", BuffCount = 2 },
        ["弗蕾亚"] = { NotBuffName = "自然协调" },
        ["阿努巴拉克"] = { MaxHP = 0.9, MinHP = 0.3 },
    }

    local targetName = WR_SafeUnitName("target")
    if targetName and BF_Name[targetName] then
        if next(BF_Name[targetName]) == nil then
            return true
        end
        if BF_Name[targetName].BuffName then
            local buff_time, buff_count = WR_GetUnitBuffInfo("target", BF_Name[targetName].BuffName)
            if buff_time > 0 and buff_count >= (BF_Name[targetName].BuffCount or 1) then
                return true
            end
        end
        if BF_Name[targetName].NotBuffName then
            local buff_time = WR_GetUnitBuffInfo("target", BF_Name[targetName].NotBuffName)
            if buff_time == 0 then
                return true
            end
        end
        if BF_Name[targetName].MaxHP then
            if WR_GetUnitHP("target") >= BF_Name[targetName].MaxHP then
                return true
            end
        end
        if BF_Name[targetName].MinHP then
            if WR_GetUnitHP("target") <= BF_Name[targetName].MinHP then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- ★ 2. 饰品数据表
-- ============================================================
local PIG_trinketData = {
    { trinketName = "无名巫妖的护符匣", buffName = "虹吸能量", cooldown = 100, lastTrigger = -math.huge, stacks = 0, itemID = 50360 },
    { trinketName = "被摘除的外物", buffName = "能量涌动", cooldown = 45, lastTrigger = -math.huge, stacks = 0, itemID = 50351 },
    { trinketName = "岩幔的恩惠", buffName = "恩惠", cooldown = 120, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "哈里森的炫目徽章", buffName = "硬化之壳", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "死亡的选择", buffName = "杰出", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "死亡的裁决", buffName = "杰出", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "暗月卡片：伟大", buffName = "伟大", cooldown = 45, lastTrigger = -math.huge, stacks = 0, itemID = 42989 },
    { trinketName = "密语尖牙颅骨", buffName = "寒怒", cooldown = 45, lastTrigger = -math.huge, stacks = 0, itemID = 50342 },
    { trinketName = "死神的意志", buffName = { "牦牛人的锋芒", "维库人的迅捷", "铁矮人的精准", "铁矮人的专注", "维库人的急速", "牦牛人的蛮力" }, cooldown = 105, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "锐锋暮光龙鳞", buffName = "光影穿刺", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "焦黑暮光龙鳞", buffName = "暮光烈焰", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "兽魂狂暴之石", buffName = "大师之能", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "兽魂狂暴雕像", buffName = "虎豹之敏", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "消逝的诅咒", buffName = "濒死诅咒", cooldown = 45, lastTrigger = -math.huge, stacks = 0, itemID = 40255 },
    { trinketName = "彗星之痕", buffName = "彗星之痕", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "安努尔之书", buffName = "圣歌之力", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "海洋之力", buffName = "台风", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "卡德罗斯的印记", buffName = "非凡战力", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "磁力之镜", buffName = "极化", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "巫术沙漏", buffName = "巫术时刻", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "黑暗潜藏卷须", buffName = "黑暗卷须", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "土灵领主徽记", buffName = "土灵怒火", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "装备探测器", buffName = "侦测到装备！", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "司克诺兹的统御奖章", buffName = "硬化之壳", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "抚慰之心", buffName = "振奋", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "磁力之镜", buffName = "极化", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "海洋之力", buffName = "台风", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "提亚的优雅", buffName = "恩赐", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "拉夏的右眼", buffName = "末日之眼", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "无尽密室之匙", buffName = "终极密钥", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "邪恶命令护符", buffName = "硬化之壳", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "暗月卡片：火山", buffName = "火山毁灭", cooldown = 45, lastTrigger = -math.huge, stacks = 0, itemID = 42991 },
    { trinketName = "杀戮执照", buffName = "斩杀者", cooldown = 45, lastTrigger = -math.huge, stacks = 10 },
    { trinketName = "青春的躁动", buffName = "胜利之悦", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "穿流之亡", buffName = "死亡之河", cooldown = 45, lastTrigger = -math.huge, stacks = 10 },
    { trinketName = "脓血莓嗅盐", buffName = "精神充沛", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "狂怒之心", buffName = "狂怒之心", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "压顶之力", buffName = "生死极速", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "普瑞斯托的诡计护符", buffName = "邪恶意图", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "雕像 - 野猪之王", buffName = "野猪之王", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "怒炉之怒", buffName = "铸炼怒火", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "缚魂之匣", buffName = "灵魂之力", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "气旋精华", buffName = "扭曲", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "灵魂之恸", buffName = "台风", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "赞达拉英雄护符", buffName = "能量无常", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "消逝的诅咒", buffName = "濒死诅咒", cooldown = 45, lastTrigger = -math.huge, stacks = 0, itemID = 40255 },
    { trinketName = "蜘蛛的拥抱", buffName = "蜘蛛之拥", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "流放者的日晷", buffName = "就是现在！", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "真实之镜", buffName = "痛苦反射", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "死亡之钟", buffName = "死亡之钟", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "命运之鳞", buffName = "命运之鳞", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "古神之血", buffName = "古神之血", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "蓝铁灌注器", buffName = "蓝铁灌注", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "龙母之眼", buffName = "龙母之眼", cooldown = 45, lastTrigger = -math.huge, stacks = 5 },
    { trinketName = "天堂之焰", buffName = "天堂之焰", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "黑暗物质", buffName = "内爆", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "龙魂图典", buffName = "巨龙之魂", cooldown = 45, lastTrigger = -math.huge, stacks = 10 },
    { trinketName = "天谴之石", buffName = "天谴之石", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "雷神符石", buffName = "雷神符石", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "潘多拉的恳求", buffName = "潘多拉的恳求", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "科林的铬银杯垫", buffName = "痛苦反射", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "秘银怀表", buffName = "就是现在！", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "远古卤蛋", buffName = "生命精华", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "深渊符文", buffName = "能量动荡", cooldown = 45, lastTrigger = -math.huge, stacks = 0 },
    { trinketName = "穆拉丁的望远镜", buffName = "蓄能", cooldown = 45, lastTrigger = -math.huge, stacks = 10 },
    { trinketName = "圣战徽记", buffName = "阵亡者之怒", cooldown = 45, lastTrigger = -math.huge, stacks = 20, itemID = 0 },
}

-- ★ 2026-08-30：按 itemID 建立索引（ZZ 8-29 饰品系统统一用 名称+itemID 资料库）
--   itemID 优先匹配，查不到再回退名称，避免重名饰品（如「磁力之镜」「海洋之力」）误判。
local PIG_trinketByID = {}
for _, t in ipairs(PIG_trinketData) do
    if t.itemID and t.itemID > 0 then
        PIG_trinketByID[t.itemID] = t
    end
end

-- 从 itemLink 解析 itemID（WotLK 链接格式：|Hitem:itemID:...）
local function PIG_GetItemIDFromLink(itemLink)
    if not itemLink then return nil end
    local id = string.match(itemLink, "item:(%d+):")
    return id and tonumber(id) or nil
end

-- 根据装备槽查找饰品资料（itemID 优先，名称回退）
local function PIG_FindTrinketEntry(slot)
    local itemLink = GetInventoryItemLink("player", slot)
    if not itemLink then return nil end
    local id = PIG_GetItemIDFromLink(itemLink)
    if id and PIG_trinketByID[id] then
        return PIG_trinketByID[id]
    end
    -- ★ 无限 12.x 安全：GetItemInfo 可能不存在，回退 C_Item.GetItemInfo；失败按未匹配处理
    local itemName
    if type(GetItemInfo) == "function" then
        local ok, n = pcall(GetItemInfo, itemLink)
        if ok and type(n) == "string" and n ~= "" then itemName = n end
    end
    if not itemName and type(C_Item) == "table" and type(C_Item.GetItemInfo) == "function" then
        local okC, nC = pcall(C_Item.GetItemInfo, itemLink)
        if okC and type(nC) == "string" and nC ~= "" then itemName = nC end
        if not itemName and id then
            local okI, nI = pcall(C_Item.GetItemInfo, id)
            if okI and type(nI) == "string" and nI ~= "" then itemName = nI end
        end
    end
    if itemName then
        for _, trinket in ipairs(PIG_trinketData) do
            if itemName == trinket.trinketName then
                return trinket
            end
        end
    end
    return nil
end

-- ============================================================
-- ★ 3. 饰品激活检测
-- ============================================================
function PIG_checkTrinketActivation(slot)
    -- ★ 2026-08-30：itemID 优先匹配，名称回退（ZZ 8-29 饰品系统统一用 名称+itemID 资料库）
    local entry = PIG_FindTrinketEntry(slot)
    if entry then
        local buffFound = false
        for j = 1, 40 do
            local buffName, _, count, _, _, expirationTime = UnitBuff("player", j)
            if type(entry.buffName) == "table" then
                for _, name in ipairs(entry.buffName) do
                    if buffName == name and (entry.stacks == nil or count >= entry.stacks) then
                        local currentTime = GetTime()
                        local remainingTime = expirationTime - currentTime
                        if slot == 13 then
                            PIG_shipin13 = remainingTime
                        elseif slot == 14 then
                            PIG_shipin14 = remainingTime
                        end
                        if (currentTime - entry.lastTrigger) > entry.cooldown then
                            entry.lastTrigger = currentTime
                        end
                        buffFound = true
                        break
                    end
                end
            elseif buffName == entry.buffName and (entry.stacks == nil or count >= entry.stacks) then
                local currentTime = GetTime()
                local remainingTime = expirationTime - currentTime
                if slot == 13 then
                    PIG_shipin13 = remainingTime
                elseif slot == 14 then
                    PIG_shipin14 = remainingTime
                end
                if (currentTime - entry.lastTrigger) > entry.cooldown then
                    entry.lastTrigger = currentTime
                end
                buffFound = true
                break
            end
        end

        if not buffFound then
            if slot == 13 then
                PIG_shipin13 = 0
            elseif slot == 14 then
                PIG_shipin14 = 0
            end
        end

        local timeSinceLastTrigger = GetTime() - entry.lastTrigger
        local cooldownRemaining = entry.cooldown - timeSinceLastTrigger
        if slot == 13 then
            PIG_shipincd13 = max(0, cooldownRemaining)
        elseif slot == 14 then
            PIG_shipincd14 = max(0, cooldownRemaining)
        end
        return
    else
        if slot == 13 then
            PIG_shipin13 = 0
            PIG_shipincd13 = 0
        elseif slot == 14 then
            PIG_shipin14 = 0
            PIG_shipincd14 = 0
        end
    end
end

-- ============================================================
-- ★ 4. 爆发窗口计算
-- ============================================================
function PIG_checkTrinketsAndTriggerBurst()
    if not PIG_checkTrinketsAndTriggerBurst_OK then
        PIG_shipin13 = 0
        PIG_shipin14 = 0
        PIG_shipincd13 = 0
        PIG_shipincd14 = 0
        PIG_baofa10 = false
        PIG_baofa3 = false
        PIG_baofamax = false
        PIG_baofa15 = false
        PIG_checkTrinketsAndTriggerBurst_OK = true
    end

    PIG_checkTrinketActivation(13)
    PIG_checkTrinketActivation(14)

    PIG_baofa10 = (PIG_shipin13 > 0 and PIG_shipin14 > 0) or
                  (PIG_shipin13 > 0 and PIG_shipin13 <= 10.5) or
                  (PIG_shipin14 > 0 and PIG_shipin14 <= 10.5)

    PIG_baofa3 = (PIG_shipin13 > 0 and PIG_shipin14 > 0) or
                 (PIG_shipin13 > 0 and PIG_shipin13 <= 3) or
                 (PIG_shipin14 > 0 and PIG_shipin14 <= 3) or
                 (PIG_shipin13 > 0 and PIG_shipincd14 ~= 0) or
                 (PIG_shipin14 > 0 and PIG_shipincd13 ~= 0)

    PIG_baofamax = (PIG_shipin13 > 0 and PIG_shipin14 > 0) or
                   (PIG_shipin13 > 7) or
                   (PIG_shipin14 > 7)

    PIG_baofa15 = (PIG_shipin13 > 0 and PIG_shipin14 > 0) or
                  (PIG_shipin13 > 0 and PIG_shipin13 <= 15) or
                  (PIG_shipin14 > 0 and PIG_shipin14 <= 15)
end

-- ============================================================
-- ★ 5. 圣骑士平砍计时器（用于饰品触发判断）
-- ============================================================
if UnitClassBase("player") == "PALADIN" then
    local PIG_LastMainHandTime = 0
    local PIG_LastOffHandTime = 0
    PIG_NextMainHandTime = 0
    PIG_NextOffHandTime = 0

    local TempFrame = CreateFrame("Frame")
    WR_RegisterEventSafe(TempFrame, "COMBAT_LOG_EVENT_UNFILTERED")
    TempFrame:SetScript("OnEvent", function(self, event, ...)
        local _, subevent, _, sourceGUID, _, _, _, _, _, _, _, _, _, _, _, isOffHand = unpack(WR_CombatLogEvent)
        if sourceGUID == UnitGUID("player") and (subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED") then
            if subevent == "SWING_DAMAGE" then
                isOffHand = select(21, unpack(WR_CombatLogEvent))
            elseif subevent == "SWING_MISSED" then
                isOffHand = select(13, unpack(WR_CombatLogEvent))
            end
            if isOffHand then
                PIG_LastOffHandTime = GetTime()
            else
                PIG_LastMainHandTime = GetTime()
            end
        end
    end)

    TempFrame:SetScript("OnUpdate", function(self, elapsed)
        local mainSpeed, offSpeed = UnitAttackSpeed("player")
        if PIG_LastMainHandTime ~= 0 and mainSpeed then
            PIG_NextMainHandTime = PIG_LastMainHandTime + mainSpeed - GetTime()
            if PIG_NextMainHandTime < 0 then
                PIG_NextMainHandTime = 0
            end
        end
        if PIG_LastOffHandTime ~= 0 and offSpeed then
            PIG_NextOffHandTime = PIG_LastOffHandTime + offSpeed - GetTime()
            if PIG_NextOffHandTime < 0 then
                PIG_NextOffHandTime = 0
            end
        end
    end)
end

-- ============================================================
-- ★ 6. 法师 - 火法连击监控
-- ============================================================
if UnitClassBase("player") == "MAGE" then
    WR_FS_Fire_LianJi = 0
    WR_FS_Fire_LianJichufa = false
    local timerActive = false

    local spellNames = {
        ["灼烧"] = true,
        ["火球术"] = true,
        ["火焰冲击"] = true,
        ["霜火之箭"] = true,
    }
    local spellIDs = { [55362] = true }  -- 霜火之箭ID

    local function checkSpell(spellId, spellName, isCritical)
        if spellNames[spellName] or spellIDs[spellId] then
            if isCritical then
                WR_FS_Fire_LianJi = WR_FS_Fire_LianJi + 1
                if WR_FS_Fire_LianJi >= 2 then
                    WR_FS_Fire_LianJichufa = true
                    WR_FS_Fire_LianJi = 0
                    if not timerActive then
                        timerActive = true
                        C_Timer.After(9.9, function()
                            if WR_FS_Fire_LianJichufa then
                                WR_FS_Fire_LianJichufa = false
                            end
                            timerActive = false
                        end)
                    end
                end
            else
                WR_FS_Fire_LianJi = 0
            end
        end
    end

    local function OnCombatEvent(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local timestamp, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName,
                  _, _, _, _, _, _, _, isCritical = unpack(WR_CombatLogEvent)
            if subEvent == "SPELL_DAMAGE" and sourceGUID == UnitGUID("player") then
                checkSpell(spellId, spellName, isCritical)
            elseif subEvent == "SPELL_CAST_SUCCESS" and spellName == "炎爆术" and sourceGUID == UnitGUID("player") then
                WR_FS_Fire_LianJichufa = false
            end
        end
    end

    local frame = CreateFrame("Frame")
    WR_RegisterEventSafe(frame, "COMBAT_LOG_EVENT_UNFILTERED")
    frame:SetScript("OnEvent", OnCombatEvent)
end

-- WR_GetNamePlateHealth、复活药水监控、全局状态变量已移至 Utils_DeathTime.lua