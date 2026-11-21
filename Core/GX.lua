-- ==========================================
-- 【游戏助手】更新日志配置区
-- ==========================================

-- 当前版本号（用于显示和哈希校验）
local CurrentVersion = "2026-11-21"

-- 销售标识（防盗版标记）
local _GxSaleTag = "9"

-- 日志内容字体大小
local FontSize = 16

-- ==========================================
-- 更新日志正文（按时间倒序排列）
-- ==========================================
local UpdateContent = [[
【防骑】2026-11-21（清洁术战斗中不驱散：判型配额死锁 —— 空 ID 烧光判型预算）
- 用户口径：「防骑战斗中依旧没有使用清洁术驱散这个中毒」。
- 真机 /FH_QJS_DEBUG 实证（10:09，战斗中，player/target 都中着毒）：
    轮询候选=146/剔0/可信/源=区间扫描/secretAPI=true
    轮询判定=false  轮询游标=1/扫完4713/命中6136
    提示判型=试60001/中176/拒0/静态产出98   不存在=40000/存档=-
    名称轮询=nil  名称候选=58  已发现名字=39/已发现ID=103  最终=false
- 根因（四条配额死锁，与「通道不够」完全无关 —— 通道已经够用，是判型预算被空 ID 烧光）：
  ① **不存在表 4 万上限打满**（诊断「不存在=40000」）：区间扫描要走完 1..130000，
     其中绝大多数 ID 根本不存在；表一满，后面的空 ID 全部返回「未知」→ 每条都要
     真调一次 C_TooltipInfo → 把判型预算烧空。
  ② **miss 表 6 万上限打满 → TIP_FULL=true**（诊断「试60001」）：从那一刻起**整个会话**
     一次都不再判型，静态产出永远停在 98 条，之后哪怕扫到真 debuff 也不再判型。
  ③ **可信门槛只看数量不看产出**：98 条静态产出 + 146 条候选 → trusted=true →
     一轮扫完零命中 → idScanVeto → 判定链尾部「AurasRestricted 就 return false」
     → 用户中的毒（不在那 98 条里）**必然**一次都不驱。
  ④ **受限旗 ID 的 nil 被当成「不在」**：GetPlayerAuraBySpellID 对被限制旗标的法术
     即使光环挂着也返回 ZERO VALUES（Lua 里就是 nil）；旧代码 isUp(nil)=false，
     于是「明明中着毒」的 ID 被当成「不在」，还顺带把整轮扫描标成 denied。
- 修法（Paladin/Paladin_Forever.lua）：
  ① 新增 WR_PaladinForever_CleanseTipWorth：提示判型只对「真实 debuff 会落到的 ID 段」
     开放（1..130000 经典段 + 1200000..1400000 无限新增段），段外一律不花提示配额。
  ② 不存在表上限 4 万 → 20 万（> 13 万扫描区间）：整段扫完也不会打满，空 ID 全程走
     「不存在」快路，判型配额只花在**真实存在**的法术上。
  ③ miss 表打满改为**清空重来**（内存恒定），并删除 TIP_FULL 永久关死闸 ——
     判型能力不会再被一堆空 ID 永久剥夺。
  ④ 候选集新增两道门槛：CLEANSE_CAND_SAVED_MIN（落盘静态产出不足即作废重扫）、
     CLEANSE_CAND_TRUSTED_MIN（静态产出不足 200 条时**不得**给权威 false，
     绝不因候选集不全而一票否决引擎通道）。存档版本号 ver 2 → 3，旧档一律作废。
  ⑤ 受限旗 ID 的 nil 一律当「未知」（不再判「不在」），且不再把整轮扫描标 denied。
  ⑥ 轮询命中改用「近期命中复核表」st.hits 取代「命中停游标」：命中时游标正常推进，
     函数入口先复核最近命中的 ID（真问一次 API），既保证主循环任何时候问都能拿到
     true，又不会让长 debuff 把游标永久钉死（诊断「命中6136 但判定=false」的另一半）。
- 验证：新增夹具 .workbuddy/test_paladin_cleanse_tip_quota.py（46 项全通过）；
  清洁术家族夹具全通过；全量 Lua 语法 215 文件 0 错。

【防骑】2026-11-21（清洁术战斗中不驱散：候选集落盘死锁 + 命中被游标吞掉）
- 用户口径：「防骑战斗中依旧没有使用清洁术驱散这个中毒」。
- 真机 /FH_QJS_DEBUG 实证（09:44，战斗中，player/target 都中着毒）：
    轮询候选=49/剔0/建库中/源=落盘/secretAPI=true   建库进度=区间4@1
    提示判型=试0/中0/拒0/静态产出0
    轮询游标=1/扫完7257/命中16458   轮询判定=nil   名称轮询=nil   最终=false
- 根因（两条结构性漏洞，与「通道不够」无关）：
  ① **落盘死锁**：候选集存档（PigSet.MKFCleanseCand）里没有 staticHits 字段（旧版本写的），
     加载后 staticHits=0 → staticComplete 恒 false → built 永远 false；
     而加载分支无条件把 source 设成「落盘」、rangeIndex 设成 #ranges+1（声明区间扫描已完成），
     越界重置又按 source 判断而跳过 → **区间扫描与提示判型永不重跑**。
     于是候选集永远钉在白名单 49 条，用户中的毒不在其中 → spellID 轮询恒 miss
     → 名称表也没有这个名 → 全链 nil → 受限战斗末尾 return false → 一次都不驱。
     诊断里「源=落盘 / 建库进度=区间4@1 / 提示判型=试0 / 静态产出0」就是死锁的原样。
  ② **命中被游标吞掉**：命中后旧实现执行 st.cursor = i + 1。而命中往往是独立驱动帧
     （0.12 秒一次）抓到的，等主循环的 UnitHasDispel 在 0.03 秒同 tick 缓存之外问过来时，
     游标已经越过那个 ID → 返回 nil → hit() 没被触发 → 色块不亮。
     诊断「扫完7257次/命中16458」却「轮询判定=nil、最终=false」正是这个形态。
- 修法（Paladin/Paladin_Forever.lua）：
  ① 候选集存档加版本号 CLEANSE_CAND_VER=2；加载时 ver 不符 / staticHits<=0 一律判无效并清档，
     让区间扫描从头重建一次（跨版本不再带着死锁状态登录）。
  ② 越界重置的判据从「source 是不是落盘/spellDB」改成「staticHits 是否 >0」——
     静态判型没产出就说明候选集不可信，必须重扫，不再被 source 挡住。
  ③ 加载分支：staticHits<=0 时不再声明「已完成」，rangeIndex 归 1、source 清空。
  ④ 新增「存在性前置筛」WR_PaladinForever_CleanseSpellExists：先用 GetSpellInfo 的名字判
     这个 spellID 到底存不存在。不存在的直接跳过，**不消耗提示配额、不写 miss 表**；
     两个接口都调过且都没名字才敢记「不存在」；接口从未成功返回过名字时一律 nil（绝不记不存在）。
     配合 miss 表上限 6000 → 60000，提示判型不会再被空 ID 瞬间打满后整会话关闭。
  ⑤ 提示判型命中时，把客户端给出的**法术名**一并记进已发现名字表，
     名称族轮询（GetUnitAuraBySpellName）随之扩大 —— 这是唯一不依赖 spellID 的通道。
  ⑥ 命中后**游标停在命中的那个 ID 上**，不再 +1：debuff 还在就继续命中（任何时候问都能拿到
     true），debuff 没了下一次自然 miss 并推进。全程仍然每次真问 API，不引入「记住的 true」，
     零假阳性。
  ⑦ 诊断新增「不存在=N / 存档=过期|有效|-」两项，用来区分「建库没跑」「旧档重建中」与「确实没有」。
- 验证：新增夹具 .workbuddy/test_paladin_cleanse_cand_lock.py（35 项全通过，覆盖旧档判无效、
  staticHits=0 重扫、本版本落盘正常复用、存在性筛三种分支、提示判型记名字、命中不推进游标、
  毒消失后不再返回 true）；清洁术家族 + 圣骑士家族夹具全通过；全量 Lua 语法 216 文件 0 失败。

【防骑】2026-11-21（清洁术战斗中不驱散：候选集建不起来 —— 静态判型全灭 + 白名单并入太晚）
- 用户口径：「防骑战斗中依旧没有使用清洁术驱散这个中毒」。
- 真机 /FH_QJS_DEBUG 实证（战斗中，player/target 都中着毒）：
    轮询候选=47/剔0/建库中/源=区间扫描/secretAPI=true   建库进度=区间3@0
    轮询判定=nil   名称轮询=nil   名称候选=25   最终=false
- 根因（三条叠在一起，与「通道不够」无关，是**候选集根本建不起来**）：
  ① 本服 C_Spell.GetSpellDispelType / GetSpellInfo().dispelType 对绝大多数 ID
     返回 nil（私服静态表不全）→ 区间扫描 33 万个 ID 全走完，poison/disease/magic
     **一条都判不出来**（staticHits=0）→ 候选集只剩白名单几十条 →
     staticComplete 恒 false → built 永远 false → spellID 轮询只可能给 true/nil，
     永远不会命中用户中的毒。
  ② 白名单 / 已发现表的 merge 被放在区间扫描**之后**，而区间扫描一旦没扫完就
     return false —— merge 永远轮不到执行，候选集被钉在 47 条上。
  ③ 数量门槛 200 在「静态判型全灭」时永远达不到 → 每 60 秒重建一次，白烧 CPU。
- 修法（Paladin/Paladin_Forever.lua）：
  ① 新增「提示判型」通道 WR_PaladinForever_CleanseKindByIDFast：
     静态 API 判不出型时，退回客户端自己的法术提示（C_TooltipInfo.GetSpellByID
     → 类型行「中毒 / 疾病 / 魔法」）。用户多次截图里的「毒性唾液 · 7125 · 中毒」
     「冰冻 · 15850 · 魔法」正是这条数据流，真机一直是明文。判型命中即记进
     已发现 ID 表，免读回的 GetPlayerAuraBySpellID 轮询立刻覆盖它。
     被拒只记 3 秒全局冷却（绝不把被拒写成「该 ID 判不出型」，否则 33 万个 ID
     会被永久标死）；判不出型记 10 分钟 miss，防重复砸引擎。
  ② 白名单 / 已发现表改到区间扫描**之前**并入，候选集首帧就有几十条可问。
  ③ 数量门槛 200 → 30（staticHits>0 仍是硬前提，白名单-only 依旧不可信）；
     落盘复用门槛 50 → 20。
  ④ 区间分段：1..30000 先扫（本服 debuff 的 ID 绝大多数落在这一段：
     5416 / 744 / 7125 / 12541 / 15850 / 589 全在里面），几秒内即可覆盖。
  ⑤ 区间表变更时重置进度，但「落盘 / spellDB」完成态不被重置清掉。
  ⑥ 诊断补「提示判型=试/中/拒/静态产出」四项。
- 验证：新增夹具 .workbuddy/test_paladin_cleanse_cand_tip.py（PASS=33 / FAIL=0）；
  清洁术家族 30 个夹具全通过；圣骑士家族夹具全通过；全量 Lua 语法 215 文件 0 错。

- 用户口径：「防骑战斗中依旧没有使用清洁术驱散这个中毒」。
- 根因（这次不是「通道不够」，而是**权威否定被误用**，把唯一还能判定的引擎通道一起掐掉了）：
  候选集靠区间扫描建（WR_PaladinForever_CleanseCandStep）。本服 C_Spell.GetSpellDispelType /
  GetSpellInfo 若不可用（私服常见），扫描一条都判不出型 → 候选集只剩「白名单 + 已发现表」
  约 60 条。旧判据 trusted = (count>=50) and secretApi and flagged==0 对这 60 条**成立**：
  白名单 merge 用 skipFlag=false → flagged=0；只要 C_Secrets 存在 → secretApi=true。
  于是「白名单-only」被判成权威可信 → 一轮扫完零命中 → idScanVeto=true →
  UnitHasDispel 里 `if AurasRestricted() and not presenceVeto` 整段被跳过 →
  唯一能按职业判定「我本人能驱散」的引擎通道（SecureForEachPresence / ForEachAura，
  filter="HARMFUL|RAID"）也一起被跳过 → 最后 `if AurasRestricted() then return false` 判无。
  用户中的毒只要不在那 60 条白名单里（本服自定义 debuff 全部不在）就**必然**一次都不驱，
  与「又加了多少条免读回通道」完全无关 —— 这就是反复修复都无效的原因。
- 修法①（候选集可信判据，Paladin/Paladin_Forever.lua）：
  · 新增 C.staticHits 计数：区间扫描 / spellDB 里真正判出 poison/disease/magic 的条数；
    staticHits == 0 = 静态库判不出型 = 白名单-only，这是唯一可靠的区分信号。
  · staticComplete = staticHits>0 且 count>=200 且 source ∈ {区间扫描, spellDB, 落盘}；
    只有 staticComplete 才置 built=true，才允许 trusted；否则 built=false、trusted=false，
    候选集退化为「渐进覆盖」（CleanseIDScan 对 !built 只给 true/nil，**绝不给权威 false**）。
  · 白名单-only **不落盘**：否则下次登录以 source="落盘" 复用它，同一个漏洞跨登录复现。
  · 白名单-only 设 retryAt = now+60，CleanseCandKick 允许 60 秒后重建
    （登录初期 C_Spell 未就绪时能自愈，不再永久钉死在 60 条白名单上）。
  · 顺带修 source 标记：旧实现只在「本帧没扫完」分支里写 source="区间扫描"，
    一帧扫完的区间会让 source 永远为空 → 完整静态结果反被当成「白名单」。
- 修法②（debuff 名字自动发现，见下）：补上「白名单外的自定义 debuff 怎么被认识」。
- 修法③（名字轮询分批）：名字表扩到「白名单 ∪ 已发现名字」（上限 400）后，
  每 0.25 秒把 400 条 × 2 单位全问一遍是 1600 次 C 调用/秒 → 改为游标分批
  （CLEANSE_NAME_POLL_BUDGET=80，一轮约 1.2 秒扫完）；UNIT_AURA 时名字游标同步回绕。

【防骑】2026-11-21（清洁术 debuff 名字自动发现：见一次就永久认识）
- 背景：本服自定义 debuff 的 spellID 不在客户端静态库可判型的范围内、也不在手写白名单里；
  而受限战斗里 auraData 的 name / spellId / dispelName 全被 secret 挡住，
  插件没有任何办法「在战斗中第一次见它」就认出来。
- 但**名字**在非受限上下文（脱战 / 非首领战 / 非挑战 / 非 PVP）是可读的，
  auraData.spellId 在那里同样可读 —— 于是新增 WR_PaladinForever_CleanseNameDiscoveryTick：
  ① 只在 AurasRestricted() == false 时跑（战斗中字段全 secret，白跑），自带 1 秒节流；
  ② 遍历 player/target/focus/mouseover 的 HARMFUL 光环，读 name + spellId + dispelName；
  ③ 用「名字白名单 → 静态分类 → 运行时分类 → dispelName」四条证据判型，只认毒/病/魔法；
  ④ 名字记进 CLEANSE_DISCOVERED_NAMES（同时记「去等级后缀」的基础名），
     ID 记进 CLEANSE_DISCOVERED_IDS；
  ⑤ 下一场战斗里名字族轮询（RequiresNonSecretAura，不受 secret 限制）按名字问「在不在」
     即可命中 → 精确点亮清洁术。
- WR_PaladinForever_KindFromAuraName 也认「已发现名字」（含去等级后缀的基础名）：
  战斗中若名字可读（用户截图实证名字通常是明文），ScanUnitDebuffTypes / tooltip 扫描
  拿到名字即可判型，不再依赖 spellID 白名单。
- 新增本地 WR_PaladinForever_AuraNameBase（去「（等级 N）」/「(等级 N)」，全角半角、空格可有可无）：
  不用 Core 的 WR_AuraNameBase —— 它在 Core 层，裁剪夹具 / 极端加载顺序下可能后加载。
- 诊断（/FH_QJS_DEBUG）新增「已发现名字=N/已发现ID=N/上次发现扫描=t」：
  真机上若长期为 0，说明脱战也读不到任何 HARMFUL 光环名字，是更上游的问题。
- 验证：新增夹具 .workbuddy/test_paladin_cleanse_auth_negation.py（S1-S5、T1-T11 全通过）；
  test_paladin_cleanse_id_scan.py 断言按新口径更新（非完整候选集只给 nil）；
  清洁术家族 29 个夹具 0 失败、圣骑士家族 0 失败、全量 Lua 语法 216 文件 0 失败。

【牧师】2026-11-21（韧 / 心灵之火「连补两下」：色块跨过 GCD 被 AHK 连按）
- 用户口径：「牧师韧消失了，为什么补的时候会连补两下」。
- 现象链（色块模型）：亮着 = 现在该按这个键；外部 AHK 每 ~60ms 扫一次，同色常亮就一直按。
  韧消失后插件点亮 52 → AHK 第一次按键成功补上韧；但「已生效 → 主动熄灭 52」这条判定
  被压在 **2 秒节流之后**（PD.BuffStep 顶部），色块要一直挂到 2 秒后才被收掉，
  而 GCD 只有 1.5 秒 → GCD 一转 AHK 的下一次扫描就又按一次 → 韧被打了两下。
- 修法（Priest/Priest_Forever_Discipline.lua）：
  ① 新增 PD.SelfBuffSettle()：**每 tick**（自带 0.25 秒节流，战斗/脱战都跑，
     且排在 2 秒节流**之前**）判定「韧 / 心灵之火是否已生效」：
     多通道 ID 直查 + 名字族 + 经典 UnitBuff + 本地施放记账，已生效 → **立刻熄灭 52 / 31**；
     开关关 → 同样立刻熄灭。2 秒节流从此**只约束点亮**，不再约束熄灭。
  ② 点亮窗口硬上限 1.0 秒（**必须小于 GCD 1.5 秒**）：点亮后无论 AHK 按没按到，
     1.0 秒后一律熄色块 —— 色块绝不跨过 GCD，AHK 就没有第二次成功按键的机会。
     这是「记账通道也读不到施放成功」（受限战斗 / 名字与 ID 都是 secret）时的兜底。
  ③ 重试闩锁 2.5 秒：这一发没打出去也不立刻重亮，等 GCD 完全转好再提示，
     避免「GCD 一过就补第二下」的另一半形态。
  ④ 焦点优先：宏 52 是 [@focus] 真言术：韧，焦点没到位时**只亮设焦点色块（192）**，
     下一 tick 焦点到位了才亮 52 —— 不再在同一 tick 里既设焦点又亮 52
     （否则这一发会打在别人身上：白烧蓝 + 把韧刷到错人身上）。
  ⑤ 心灵之火（31）同构收口，判定统一走 PD.SelfBuffUp（通用自身增益件）。
  ⑥ Core/Forever_Compat.lua 新增 WR_Forever_FortitudeCastLanded /
     WR_Forever_SelfBuffCastLanded：**零 API 调用**的「这一发已经打出去了」判定
     （只查本地施放记账 + 提示归属窗口），供收口路径最快熄色块；
     另加 WR_Forever_FortitudeSpellIDSet()：静态全 rank 表 + 运行时解析玩家
     真正学会的那个 rank（本服法术 ID 可能与经典表不一致，不能只靠写死的表）。

【牧师】2026-11-21（维持真言术：韧兼容低级法术：全 rank ID 族 + 光环名归一 + 群体坚韧祷言）
- 用户口径：「牧师还有维持真言术韧没兼容低级法术」。
- 截图实证：1 级小号身上的韧是「真言术：韧 等级 1 · spellID 1243」（+4 耐力）。
- 根因：判「有没有韧」只走 PD.BuffRemain("真言术：韧") → 帧级光环缓存的名字精确
  比较（name == AuraName）：本服低 rank 光环名带等级后缀（「真言术：韧(等级 1)」），
  基础名永远匹配不上 → 判「没韧」→ 每 2 秒重亮 52 → AHK 反复补韧；同时没有按
  spellID 族（1243/1244/1245/2791/10937/10938/25389 + 群体坚韧祷言 21562）判定，
  群体韧挂着时也会再单体补一次。
- 修法：
  ① Core/Core_Functions.lua 新增 WR_AuraNameBase：剥掉光环名的「(等级 N)」「（等级 N）」
     后缀并做全角/半角归一；WR_GetAuraInfoCore 的字符串比较改走归一比较（ID 通道
     不变）→ 低 rank 光环名也能命中基础名查询。
  ② Core/Forever_Compat.lua 新增「真言术：韧 / 坚韧祷言 全 rank 专用件」：ID 族
     （1243/1244/1245/2791/10937/10938/25389 + 群体 21562）、多通道存在性判定
     （免读回 ID 直查 / 名字族直查 / 经典 UnitBuff / 既有缓存通道）、本地施放记账、
     提示保持窗口（防重入，避免窗口被无限续期 → 永久常亮）。
  ③ Priest/Priest_Forever_Discipline.lua 的 BuffStep 韧分支改走多通道判定：已挂韧
     （任意 rank）或群体坚韧祷言 → 不点亮并主动熄灭 52；开关关 / 技能不可用 → 同样
     主动熄灭，不再挂屏被 AHK 连按。
  ④ 同构收口「心灵之火」（31 槽，同一行里的另一个维持类增益）：旧写法同样是
     PD.BuffRemain 精确名字（低 rank 漏判）且「已经挂着 / 开关关 / 不可用」时
     都不熄灭 → 残留色块挂屏被 AHK 连按。
     Core/Forever_Compat.lua 新增通用「自身增益」专用件
     WR_Forever_SelfBuffUp / WR_Forever_NoteSelfBuffPrompt /
     WR_Forever_SelfBuffPromptHold：多通道存在性 + 本地施放记账（spellID 通道，
     名字 secret 也能记）+ 提示保持窗口（防重入）+ 运行时解析玩家实际学会的 rank
     （不写死 ID）。心灵之火分支改走该专用件，判定「已经挂着 / 开关关 / 不可用」
     都主动熄灭 31。
- 验证：test_priest_fortitude_lowrank.py 41/41 通过（低/高 rank ID 直查、群体韧、
  半角/全角后缀名、secret 守卫不崩、本地记账过期、保持窗口防重入、BuffStep
  点亮/熄灭回归、WR_AuraNameBase 归一用例、通用自身增益专用件与心灵之火分支）；
  全量 Lua 语法 216 文件 0 失败；
  全量夹具 180 个，仅 4 个既有失败（法师冰法 x3 / 术士 x1），这 4 个的失败条数在
  git stash 前后完全一致（1 / 2 / 13 / 29），与本次改动无关。

【牧师】2026-11-21（种族技能加限制：目标必须是怪物才释放）
- 用户口径：「牧师种族技能能添加限制，当目标是怪物的时候才释放吗」。
- 实现（Priest/Priest_Forever_Discipline.lua）：
  ① 新增 PD.TargetIsMonster()：目标存在 + 存活 + 可攻击（UnitCanAttack）
     + 非玩家（UnitIsPlayer=false，PVP 敌对玩家不算怪物）
     + 非玩家控制单位（UnitPlayerControlled=false，猎人宠物/被精神控制的
     玩家不算怪物；API 缺失时跳过这一环）。任何一环读不到都按「不是怪物」
     处理 —— 宁可不放，符合限制口径。
  ② PD.BurstStep 的种族爆发分支加此硬门：目标不是怪物 → 不点亮 181，
     并走本步尾部主动熄灭（残留色块不挂屏）。与既有 已学会/本地记账 CD/
     客户端冷却/提示保持窗口 门叠加，只加严不放宽。
  ③ 面板「种族爆发」tooltip 同步注明「仅当目标是怪物时释放」。
- 验证：test_priest_racial_burst_gate.py（B3~B7：玩家/无目标/已死/不可攻击/
  宠物 → 全部不点亮）、test_priest_racial_burst_cd.py（B3 玩家目标不点亮
  且熄灭 181；B1/B2 怪物目标回归）。

【牧师】2026-11-21（真言术：盾严格受滑块控制：迁移重跑改写滑块值 + 禁用/脱战不熄色块）
- 用户口径：「真言术盾使用要严格受滑块控制」。
- 根因：
  ① 旧档迁移只有会话内存旗标 PD.Migrated，每次登录/重载都重跑 —— 盾滑块
     合法值 5/10/15/20（%）被当成旧档位改写成 50/91/96/0：设 10% 下次登录变 91%
     （几乎满血就补盾）、设 20% 变 0（被禁用），循环阈值与面板滑块显示对不上；
     治疗模式 2↔4 也每次登录来回翻转（同源）。
  ② 滑块拉到 0 后 ShieldStep 只 return false 不熄灭 —— 上一 tick 亮的 59 挂着
     被 AHK 连按，表现为「关了滑块还在上盾」。
  ③ 防ADD=是 + 脱战时主循环早退，ShieldStep 不执行，战斗最后一 tick 的盾色块
     无人收掉，脱战后仍在补盾。
- 修法（Priest/Priest_Forever_Discipline.lua）：
  ① 迁移改用存档旗标 JL_MIG_V2，历史上只执行一次；且盾值 1~20 中属于新滑块
     合法步进值（5 的倍数）的一律按用户百分比对待，不再改写；真正的旧档位
     （7→70 等非步进值）仍迁移一次；
  ② ShieldStep：滑块=0 → 主动熄灭 59；阈值钳制 0~100（存档异常值不把满血判低血）；
     候选每 tick 按当前滑块值重新过滤，调低滑块后保持窗口不续亮高于阈值的目标；
  ③ 主循环开头：滑块=0 → 无条件熄灭 59（任何早退门之前）；防ADD=是 + 脱战 →
     在 BuffStep 之前熄灭 59（BuffStep 命中会早退，排后面轮不到）。
- 面板（Priest_Menu.lua）：盾滑块 tooltip 更新为「严格低于设定值（等于不补）；
  值每次登录保持不变；0=不使用且立即熄灭已亮色块」。
- 验证：test_priest_shield_aura_multichannel.py 46/46 通过（新增 E1~E8：
  禁用熄灭 / 阈值边界等于不亮 / 调低不续亮 / 异常值钳制 / 迁移只跑一次 /
  旧档位仍迁移 / 脱战两条早退路径都熄灭）；牧师家族夹具回归通过；全量 Lua 语法 0 失败。

【牧师】2026-11-21（上了盾还一直亮盾·二修：记账只认名字不认 ID + 事件桥丢非自施 + 保持窗口反向续亮）
- 用户口径：「牧师上了盾后，还是依旧会亮盾的色块」。截图实证：真言术：盾 · SpellID 17 ·
  IconID 135940 · 4 秒冷却 —— 盾确实打出去了，59 槽位仍常亮。
- 根因（三十七次修复补了「盾存在性」多通道，但受限战斗里光环四通道全读不到，
  唯一可靠的本地记账通道自己又有三个洞，叠在一起仍是「上了盾还一直亮」）：
  ① 记账只认名字不认 ID：UNIT_SPELLCAST_SUCCEEDED 的 spellName 在受限战斗里是 secret →
     WR_Forever_CastLog（名字键）永远为空；WR_Forever_ShieldCastAt 只查名字键，
     从不查唯一有值的 WR_Forever_CastLogByID[17] → 盾的记账通道整条失效；
  ② 事件桥丢非自施：Core/Forever_APIShim.lua 把整笔记账关在 unit == "player" 门里，
     而本事件首参是「施放落点单位」——宏 59 是 [@focus] 真言术：盾，落在 party1/target
     上时 unit ~= "player"，整笔丢弃 → 给队友上盾永远记不上账；
  ③ 保持窗口反向续亮：WR_Forever_ShieldPromptHold 在施放成功后把窗口延长到整个盾
     持续时间（30 秒）→ 盾明明上身，色块却被强行续亮 30 秒；
  ④ secret number 的 type() 仍是 "number"，NotePlayerCast 里 spellID > 0 比较一抛错，
     整笔记账（含名字通道）一起被 pcall 丢掉。
- 修法：
  ① WR_Forever_ShieldCastAt 同时查名字键与全部 13 个 rank 的 CastLogByID（取最新）；
  ② 事件桥记账移出 unit == "player" 门（LastPlayerCast 语义保持不变），落点无关都记账；
  ③ 新增「已确认施放」记账 WR_Forever_ShieldConfirmed：提示归属（3 秒内点亮过该单位）
     优先，无提示记录时按 [@focus] 宏形态归属当前焦点（手动施放也认）；
     WR_Forever_ShieldUp 在光环通道之后先查确认记账 → 盾上身即不亮；
  ④ 保持窗口只覆盖「点亮后等 AHK 按键」的 1.5 秒，施放成功后不再续期；
  ⑤ NotePlayerCast 的 spellID 先过 WR_IsSecretValue + pcall 收敛再写表。
- 验证：盾夹具 29/29（新增 D1-D6：名字 secret 只靠 ID 记账、secret 守卫不丢账、
  焦点归属/跨单位不假阳、保持窗口不续期、ShieldStep 盾上身后不点亮且主动熄灭 59、
  事件桥落点非 player 也记账）；全量 Lua 语法 216 文件 0 失败；牧师家族夹具 0 失败。

【牧师】2026-11-21（上了盾还一直亮盾：补「盾存在性」维 —— 多通道免读回直查 + 本地施放记账）
- 用户口径：「牧师上了盾后还会继续亮盾，存在异常」。
  截图实证：玩家身上挂着「虚弱灵魂 · 法术ID 6788 · 无法从真言术：盾中获得益处 · 剩余5秒」，
  盾明明刚上过，59 槽位却还在亮。
- 根因（与三十四/三十五/三十六次修复的「没学会」「CD 中」「脱战」都不是同一件事，
  这次是 **盾有没有真的上身** 这一维）：PD.HasShield 只有两条路，都经
  WR_GetUnitBuffTime / WR_GetUnitDebuffTime → WR_GetAuraInfoCore → 帧级光环缓存。
  三个坑叠在一起，全部返回「不存在」：
  ① 受限战斗里 C_UnitAuras.GetAuraDataByIndex 抛「Auras cannot be accessed when
     secret」→ WR_ScanAurasForUnit 整段 pcall 失败 → 缓存保留上一次（往往是 nil）；
  ② 缓存里 aura.name 可能是 secret string，WR_GetAuraInfoCore 的 `name == AuraName`
     比较会抛错（它没包 pcall）→ PD.UnitBuffRemain 的 pcall 把整次查询吞成 0；
  ③ 全仓没有「我刚给这个单位上过盾」的本地记账 —— 技能真打出去了，插件不知道。
  三条都返回「不存在」→ HasShield=false → 每 tick 重亮 59 槽位 → AHK 连按。
- 修法（Core/Forever_Compat.lua，做成**增益/减益通用件**，全仓可复用）：
  ① 新增 WR_Forever_AuraPresence(unit, name, ids, filter)：四类通道依次问「在不在」——
     免读回 ID 直查（GetPlayerAuraBySpellID / GetUnitAuraBySpellID）、
     名字族直查（GetPlayerAuraBySpellName / GetUnitAuraBySpellName / GetAuraDataBySpellName）、
     经典 UnitBuff / UnitDebuff(unit, 名字)、既有缓存通道。
     **只采信肯定证据**：任一明确 true → true；全都读不到 → nil（未知），
     绝不把「读不到」当成「没有」—— 那正是本次故障的形态；
  ② 新增 WR_Forever_ShieldUp(unit)：盾本体（13 个 rank ID）→ 虚弱灵魂 6788 →
     本地「已确认施放」记账，三层依次判；
  ③ 新增 WR_Forever_NoteShieldPrompt / WR_Forever_ShieldPromptHold：
     点亮后记一笔并留 1.5 秒保持窗口（给 AHK 扫屏按键的时间），
     **保持窗口内重复点亮不续期**（防重入，否则窗口被无限续命 → 色块永久常亮）；
     施放成功 30 秒内算「有盾」，5 秒还没等到施放就清账（空按不会锁死）。
- 修法（Priest/Priest_Forever_Discipline.lua）：
  ① PD.HasShield 改走 PD.ShieldUp → WR_Forever_ShieldUp（读不到一律按「没有」继续上盾，
     宁可多上一次，也不让色块挂死被 AHK 连按）；
  ② 新增 PD.ShieldStep()：候选 = 低于拉条阈值 **且此刻没盾** 的人里血最少的那个。
     旧实现把盾当普通 HealStep（选最低血的人 → 有盾就整步跳过），只要「最低血的那个人」
     已经有盾，别人缺盾也不补，而 AHK 读到 59 常亮时打的是焦点，往往把盾重复套在
     同一个人身上（白烧蓝 + GCD）；
  ③ 本 tick 不该亮（没候选 / 不可用 / 点亮失败）→ **主动熄灭 59**；
  ④ 主循环盾步改为 PD.ShieldStep()。
- 新增离线夹具 .workbuddy/test_priest_shield_aura_multichannel.py（A1-A8 / B1-B5 / C1-C5，20 项全过）：
  多通道命中、secret 抛错不崩、读不到回 nil、保持窗口防重入、跨单位归属
  （给 party1 上盾不会让 party2 也以为自己有盾）、ShieldStep 选人/熄灭。

【牧师】2026-11-21（脱战了还亮惩击色块：补「脱战熄灭」维 —— 输出/爆发槽位必须主动收）
- 用户口径：「牧师脱战了还会亮惩击色块，放ADD是选的是，存在异常」。
- 根因（与三十四/三十五次修复的「没学会」「CD 中」都不是同一件事，这次是
  **脱战维度**上的洞）：
  ① 色块模型是「亮着 = 该按这个键」，而 WR_ColorFrame_Show 只在**自己**被调用
     的那一刻先隐藏全部再点亮一个 —— 本 tick 一个色块都没点亮时，上一 tick 的
     色块不会自己消失；
  ② MainLoop 的收尾清扫 WR_SoD_SweepPowerBlocked 只处理「资源不足」一种情形
     （Core/SoD_Runes.lua 注释写明：CD 中 / 无目标 / 脱战各有自己的机制，
     不在总闸层擅自扩大改动面）；
  ③ 而戒律循环的脱战分支原本是「补完 BUFF 就 return false」，从不熄灭任何槽位
     → 战斗最后一 tick 亮的 196 惩击常亮不灭 → AHK 读到同色继续按
     CTRL-NUMPADMINUS（/cast 惩击）→ 脱战后真的把惩击打出去，一打又进战斗。
- 修法（Priest_Forever_Discipline.lua）：
  ① 新增 PD.Hide(spell, slot)：走 Core 的 WR_HideSkillColorSlot（与总闸同一实现），
     兜底按槽位直接熄灭两侧色块 + 文本；
  ② 新增 PD.CombatOnlySlots / PD.HideCombatOnly()：196 惩击 / 87 暗言术：灭 /
     197 黑暗献祭 / 181 种族爆发 —— 只在战斗中才有意义的槽位，脱战统一收掉；
  ③ 主循环把「脱战熄灭」排在 PD.StopGate **之前**：坐下喝水 / 施法中 StopGate
     会早退，排在后面这些状态下残留色块同样收不掉；
  ④ PD.OffenseStep 补脱战门 + 每条早退路径（无目标 / 目标已死 / 不可攻击 /
     超射程 / 点亮失败）主动 bail() 熄灭自己的槽位 —— 这是「惩击」这一类输出
     色块不再挂屏的正面保证，而不是指望别的步骤顺手覆盖；
  ⑤ 治疗 / BUFF / 驱散类槽位不在熄灭集合内：那些在脱战时本来就可能需要提示。
- 同构修复（Priest_Forever_Shadow.lua）：暗影牧的战斗进入门同样是「不满足就
  return false」，一样会把上一 tick 的输出色块留在屏幕上。现于该早退路径统一
  熄灭 11 个战斗专用槽位（痛/触/疫病/震爆/死/鞭笞/暗影魔/消散/拥抱/沉默/暗影形态）。
- 验证：新增 .workbuddy/test_priest_out_of_combat_colorblock.py，18 项全过
  （脱战不亮 + 主动熄灭 + 战斗中仍正常点亮 + 无目标/超射程/不可攻击三条早退
  熄灭 + StopGate 早退仍熄灭 + 脱战仍能补 BUFF + 暗影牧同构）；
  牧师家族与种族爆发三套夹具回归通过，全量 216 个 Lua 文件语法 0 失败。

【种族爆发】2026-11-21（用了还一直亮：补 CD 维 —— 本地施放记账 + 客户端冷却 + 提示保持窗口）
- 用户口径：「牧师一直亮种族爆发色块，使用了种族技能还是一直亮，存在异常」。
  截图实证：狂暴 · 种族特长 · 3 分钟冷却 · spellID 20554。
- 根因（与三十四次修复的「没学会」不是同一件事，这次是 **CD 维度**上的洞）：
  ① 无限战斗中 GetSpellCooldown 是 secret → WR_GetGCD 收敛成 0 →
     WR_SpellUsable 的 GCD 门 `WR_GetGCD(Spell) <= 0.4` 恒成立；
  ② WR_IsSpellUsableCompat 只判资源 / 客户端可用性 / 形态，本服私服实现对 CD 中
     的技能也可能回 true；
  ③ 全仓此前**没有任何本地施放记账** —— 技能真打出去了，插件完全不知道，
     下一 tick 立刻再点亮同一槽位 181 → AHK 连按 → 用户看到「一直亮」。
- 修复①（Core/Forever_Compat.lua）：新增种族爆发专用冷却证据链。
  · WR_Forever_NormalizeSpellKey：剥「(种族特长)」/「（种族特长）」/「(等级 N)」
    后缀，半角全角分两次字面量剥（多字节不能进 Lua 字符类）；secret 名字返回 nil。
  · WR_Forever_RacialBurstSpellIDs：本服实测 ID 表（狂暴 20554 / 血性狂怒 20572）。
    **不写进 SPELL_ID_OVERRIDES** —— 那张表是全局覆盖，会把德鲁伊的「狂暴」
    (Berserk) 也顶成巨魔的种族 ID。
  · WR_Forever_SpellCooldownLeft：C_Spell.GetSpellCooldownDuration +
    EvaluateRemainingDuration 引擎侧求值（不吃 secret）→ 退 WR_SpellCooldownInfo
    的 start+duration → 无曲线工具时落到通道②取精确值，只有都失败才用 1 秒兜底。
  · WR_Forever_NotePlayerCast / WR_Forever_CastCooldownLeft：本地施放记账
    （按归一名字 + spellID 双键，名字是 secret 时只靠 ID 记账，都读不到就放弃）。
  · WR_Forever_BurstReady：已学会 → 本地记账 CD → 客户端冷却 → 提示保持窗口
    → 客户端可用性。**保持窗口内返回 true（继续亮）**，不是 false ——
    点亮当 tick 就判死会变成「亮 100ms / 灭 1.5s」的闪烁，AHK 很可能一次都没读到。
    窗口过后按有限次重试（<=15 秒按保持窗口、<=300 秒每 20 秒、更长按完整 CD），
    避免「一次漏记锁死 3 分钟不再提示」。
  · WR_Forever_RacialBurstCD：全职业共用真实 CD 表（狂暴/狮心/艾露恩之光/尤里卡！
    180 秒、血性狂怒 120 秒），未登记按 180 秒保守处理。
  · WR_Forever_RacialBurstReady / WR_Forever_HideRacialBurst：共享的「取一个真能打
    的技能名」与「熄灭 181」入口。
- 修复②（Core/Forever_APIShim.lua）：UNIT_SPELLCAST_SUCCEEDED 接本地记账。
  这是唯一的施法成功入口，在这里统一记一笔即可覆盖全职业；名字是 secret 时
  归一函数内部已过 WR_IsSecretValue 并包 pcall，读不到就只靠 spellID。
- 修复③（Core/Forever_Compat.lua 的 WR_Forever_GetRacialBursts）：
  在**取列表的源头**按 CD 过滤。各职业的种族爆发步（战士三系 / 德鲁伊三系 /
  猎人三系 / 法师三系 / 萨满两系 / 术士三系 / 牧师戒律）都吃这个列表，
  在源头剔掉还没好的技能即可全职业一次性修好（与三十四次修复的「已学会」过滤同源）。
  **只过滤本函数**：宏注入（Forever_Hooks 的 InjectRacialLines）用的是
  WR_Forever_PlayerRacialBursts，那条路在建宏期（登录 / 切天赋）执行，
  此刻不可能有 CD，不能被影响，否则会漏注入 /cast 行。
- 修复④（Core/Forever_Compat.lua + Forever_Hooks.lua）：抽出 WR_Forever_BurstLearned
  作为「已学会」判据，实测 spellID 命中即直接判已学会。
  原因：本服种族主动技能在法术书里常带「(种族特长)」后缀，WR_ResolveSpellID 按纯名
  解析不到 → 名字口径的 SpellLearned 误判「没学会」→ 把巨魔牧师的「狂暴」整条剔掉 →
  种族爆发永远不亮（比「一直亮」更糟的反向故障）。实测 ID 是「自己打出来过、截图核对
  过 spellID」的确定证据，优先于任何按名字的推断；安全前提是调用方都已先按**种族**
  过滤过列表，所以只会是本种族真有的技能。Hooks 的源头过滤与 BurstReady 共用此判据。
- 修复⑤（各职业种族爆发步）：牧师 / 战士三系 / 德鲁伊野性 / 猎人兽王 统一改走
  WR_Forever_RacialBurstReady，并在本步判定「不亮」时**主动熄灭 181 槽位**。
  色块模型是「亮着就一直按」，只 return false 不熄灭的话上一 tick 的色块会一直
  挂着被 AHK 连按 —— 正是用户看到的「用了还是一直亮」。
- 修复⑥（Core/Forever_Compat.lua 新增 WR_Forever_RacialBurstStep）：把「七道门」
  收成一个全职业共用入口 —— 按种族精确列表 → 已学会 → 本地施放记账 CD →
  客户端冷却 → 提示保持窗口 → 客户端可用性 → 点亮后记提示时间戳；
  本步不亮（含面板开关关闭、Show 失败）一律主动熄灭槽位。
  上一轮只改到牧师 / 战士三系 / 德鲁伊野性 / 猎人兽王，**法师三系、猎人射击·生存、
  萨满两系、术士三系、德鲁伊平衡·恢复仍是旧的「只问 WR_SpellUsable」口径** ——
  同一个「用了还一直亮」的坑，这次一次性收口：
  · Mage_Frost/Fire/Arcane_Features.lua（槽位 181）
  · Hunter_Marksmanship/Survival_Features.lua（槽位 181）
  · Shaman_Enhancement/Restoration_Features.lua（槽位 181）
  · Warlock_Affliction/Demonology/Destruction_Features.lua（槽位 8）
  · Druid_Balance/Restoration_Features.lua（槽位 181）
  旧实现全部保留为「Core 未加载新函数」时的兼容回退分支。
- 验证：新增 test_racial_burst_step_unified.py（U1-U6，12 条全绿：CD 中不亮且熄灭 /
  CD 好了点亮并记账 / 开关关不亮且熄灭 / Show 失败熄灭 / 旧 Core 回退 /
  术士槽位 8）；test_priest_racial_burst_cd.py 27 条、test_priest_racial_burst_gate.py
  15 条仍全绿；全量 216 个 Lua 文件语法 0 失败。

【牧师】2026-11-21（戒律面板爆发只留「种族爆发」：三槽位图标 + 六个按钮全部删除）
- 用户口径：「牧师面板中爆发按钮，只留第一个爆发按钮，其他删除，连带的其他 6 个按钮也删除」。
- 面板（Priest/Priest_Menu.lua）：
  · 爆发分组只保留「种族爆发」（JL_BF_RACE，默认开）；
  · 删除图标「槽位1 / 槽位2 / 槽位3」（JL_BF_S1~S3，含右键循环选技能）；
  · 删除按钮「爆发槽位1 / 2 / 3（设置）」「爆发全开（全部打开）」「爆发全关（全部关闭）」
    「爆发切换（切换）」共 6 个。
- 循环（Priest/Priest_Forever_Discipline.lua）：
  · PD.BurstStep 删掉三槽位分支，只剩种族爆发一条路径（按种族取列表 + 已学会硬门，
    全都没学会则本步跳过，不卡主循环）；
  · PD.BurstSlotValue / PD.BurstSetAll / PD.CycleBurstSlot / PD.BurstChoices 一并下线；
  · 旧档迁移：清掉残留的 JL_BF_S1~S3 与 JL_BF_SLOT1~3（只执行一次），只保留 JL_BF_RACE。
- 功能层（Priest/Priest_Forever_Discipline_Features.lua）：
  · 删除 WR_PriestDisciplineBurstAllOn/AllOff/Toggle 与 BurstSlot1/2/3 六个按钮函数；
  · 删除已无对应面板项的斜杠命令 /mkhdiscburst 与 /mkhdiscslot；
  · /mkhdisc 诊断输出只保留 JL_BF_RACE。
- 验证：test_priest_discipline_image_sync.py（A7 断言三槽位已下线，PASS=63 FAIL=0）、
  test_priest_discipline_features_load.py（T6 断言按钮函数与命令已下线，0/6 失败）、
  test_priest_racial_burst_gate.py（R1-R9/L1-L3/B1-B2 全过）。

【牧师】2026-11-21（1 级小号卡种族爆发色块：种族列表改为按种族精确 + 已学会硬门）
- 用户口径：「1级小号牧师会卡种族爆发色块」。
- 根因（两个坑叠在一起，且不只在牧师身上）：
  ① Core/Forever_Compat.lua 的 WR_Forever_GetRacialBursts 按**阵营**返回 ——
     部落恒为 {血性狂怒, 狂暴}、联盟恒为 {艾露恩之光, 尤里卡！}，再并上 BOTH
     （四个全给）。于是每个角色都会拿到自己没有的种族技能：亡灵牧师去试
     「血性狂怒」「狂暴」，兽人战士去试「艾露恩之光」「尤里卡！」。
  ② 12.x 的 C_Spell.IsSpellUsable(spellID) 只判资源/CD/形态，**不判是否学会**
     （私服还会对解析不出的名字直接回 true），旧 WR_IsSpellUsableCompat 拿到
     usable==true 就放行 → 「玩家根本没有的技能」被判成可用。
  结果：种族爆发步每 tick 点亮宏槽 181，而宏体三条 /cast 全是没学会的技能，
  客户端一条都不执行 → 色块不灭 → AHK 连按 → 主循环永远停在爆发步，
  后面的惩击/治疗一步都轮不到。
- 修复①（Core/Forever_Hooks.lua）：种族名归一 + 按种族精确取列表。
  WR_Forever_RaceToken 产出 "NightElf"/"Scourge"，数据表写的是
  "Night Elf"/"Undead"，两套名字对不上导致精确匹配恒落空；新增
  WR_Forever_RaceAlias / WR_Forever_NormalizeRaceName 做别名归一（大小写与空格
  不敏感），并改为两个阵营表都扫（不再依赖 UnitFactionGroup）。天裔的两个分支
  （高阶议会 / 御风者）统一按 Skyborne 命中。
- 修复②（Core/Forever_Hooks.lua）：列表源头过滤「没学会」。
  各职业的种族爆发步（战士 / 德鲁伊 / 猎人 / 法师 / 萨满 / 术士 / 牧师）都直接
  吃这个列表，在源头剔掉没学会的技能即可全职业一次修好。判据只剔「确认没学会
  (false)」，读不到 (nil) 一律保留。
- 修复③（Core/Forever_Compat.lua）：新增 WR_Forever_SpellLearned(spell) ——
  「有没有这个技能」的独立判据。返回 true = 已学会（法术书解析出 spellID，
  或 IsPlayerSpell / C_Spell.IsSpellKnown 直查命中）；false = 确认没学会
  （法术书已就绪且解析不到）；nil = 读不到（登录初期法术书为空 / 换天赋瞬间
  索引被清）→ 调用方一律放行，避免把整条循环误杀成「一个技能都不亮」。
- 修复④（Core/Forever_Compat.lua）：WR_Forever_GetRacialBursts 改为优先走
  按种族精确的 WR_Forever_PlayerRacialBursts；且**种族能解析出来时就完全信任
  精确结果**（哪怕是空表）—— 亡灵/牛头/人类本身没有 burst 向特长，此时若退回
  阵营表就等于又把「血性狂怒/狂暴」塞回去。只有种族读不到才退回阵营兜底。
- 修复⑤（Priest/Priest_Forever_Discipline.lua）：新增 PD.Learned(spell) 薄封装，
  并把「确认没学会」并入 PD.CanCast —— 从此牧师所有施法判定（治疗链、驱散、
  输出、插入、三个爆发槽位、种族爆发）都同时具备「有没有这个技能」与
  「此刻能不能放」两维；读不到（nil）不拦。种族爆发步改为优先按种族取列表，
  全都没学会则本步直接跳过，不再卡住主循环。
- 兼容：WR_Forever_SpellLearned 只做「是否拥有」判断，不改变任何技能的冷却、
  资源、形态判定；WR_SoD_NotEnoughPower / WR_ColorFrame_ShowSkill 的既有语义
  完全不动（曾试过在色块总闸加这道门，会误杀「种族爆发」这类描述型伪技能名，
  已回退，只在真实技能名所在的位置判）。
- 验证：新增 .workbuddy/test_priest_racial_burst_gate.py（R1-R9 / L1-L3 / B1-B2
  共 14 项全绿：亡灵/人类空列表、兽人只给血性狂怒、巨魔只给狂暴、暗夜精灵归一
  命中艾露恩之光、种族读不到才退回阵营、源头过滤与放行、已学会三态、牧师爆发步
  不点亮/点亮）；全量 Lua 语法 216 文件 FAIL=0；牧师与圣骑士家族夹具回归全绿。

【防骑】2026-11-21（清洁术战斗驱散：名称族轮询 + 轮询独立驱动，两条结构性漏洞堵上）
- 用户口径：「只要能实现骑士清洁术在战斗中正确的驱散魔法，疾病，中毒即可」。
- 三十一次修复的 spellID 全集轮询语义是对的，但有两个与 API 权限无关的漏洞，
  会让它在真机上继续哑火：
  · 候选集靠扫静态库建（区间 1..130000 + 1200000..1400000）。本服自定义 debuff
    若不在区间内、或客户端没有 C_Spell.GetSpellDispelType / GetSpellInfo，
    候选集就覆盖不到它 → 轮询再好也问不到那个 ID。
  · 轮询只在 CleanseStep 的 tryUnit 里推进。而防骑主循环里 鼠标指向保护 /
    圣印窗口（1.0 秒重亮）/ 正义之怒 / 审判与神圣打击色块 都会每 tick 提前
    return true → CleanseStep 不被调用 → 游标原地不动 → 一轮永远扫不完 →
    轮询恒 nil → 永不驱散。
- 修复①（名称族轮询）：GetAuraDataBySpellName / GetUnitAuraBySpellName 与
  GetUnitAuraBySpellID 同属 RequiresNonSecretAura 族 —— 只按「名字」问「在不在」，
  不枚举光环、不读任何字段。白名单名字表只有几十条，0.25 秒问一遍开销可忽略；
  本服 debuff 名字在截图里一直是明文。它正好补上「候选集漏 ID」的漏。
- 修复②（轮询独立驱动）：专用 OnUpdate 帧按 0.12 秒节流推进
  「名字族（player/target）」+「spellID 游标（player 每轮必扫，其余单位轮转一个）」，
  完全不经过主循环分支；只在「清洁术功能开着 + 战斗中或光环受限」时运行，
  脱战零开销。这样无论循环怎么 return true，一轮扫描都能在固定时间内走完，
  2 秒级的短 debuff（冰冻 15850 等）也来得及点亮。
- 语义不变：两条通道都只认肯定证据，读不到一律 nil，绝不判无；
  诅咒 / 流血仍由白名单与名字表排除（名字表只收毒 / 病 / 魔法）。
- 诊断 /FH_QJS_DEBUG 新增「名称轮询=命中名/扫描次数」。


【防骑】2026-11-21（清洁术「战斗中精准驱散」最终解法：按 spellID 全集精确轮询）
- 用户口径：「这么多次修复都无法实现在战斗中精准驱散」。
- 本轮先把客户端源码逐条核对完（wow-ui-source 12.1.0），确认**光环系统内部的一切读回
  在受限战斗里都被封死**，所以此前十几轮「加读通道」注定落空：
  · C_UnitAuras.GetAuraDataByIndex / GetAuraSlots / GetUnitAuras /
    GetUnitAuraInstanceIDs 全部标 RequiresUnitAuraAccess = true
    → 污染插件在受限战斗里一律抛「Auras cannot be accessed when secret while
      tainted by 'MKHelperForever'」（诊断里那三条 ERR 就是它们）。
  · 每枚 AuraButton 创建后挂 DenyTaintedAccessWhenAurasAreSecret
    （CustomAuraContainerConstants.AccessRestrictionFlags）→ IsShown / GetAtlas /
    GetVertexColor 在战斗里全被拒（诊断「EUI可见=false(0/0枚)」即此）。
  · 容器尺寸由 CustomAuraContainerFlowLayoutMixin:OnLayoutComplete 用
    SetSize(secretwrap(w,h)) 写入 → 也是 secret，不能比较。
  · 组的 GetAuraGroup 只在 Private 分区，插件侧调不到（「probe判定=nil」）；
    公有 GetAuraGroupFrameCount 返回 #ownedFrames（批量预分配高水位，恒 ≥10），
    不是当前条数 —— 所以「数组内帧数」这条路从原理上就不成立。
- 唯一被客户端明确允许的是 RequiresNonSecretAura 族：
    C_UnitAuras.GetPlayerAuraBySpellID(spellID) / GetUnitAuraBySpellID(unit, spellID)
  EUI 生产代码原文实证（EllesmereUIQoL_Bloodlust.lua 435-441）：
    "GetPlayerAuraBySpellID is RequiresNonSecretAura and returns ZERO VALUES for a
     restriction-FLAGGED spell while its aura is up"
  即：**没被限制旗的 ID，战斗中照样精确回答「在 / 不在」**。
- 于是把问题反过来问：清洁术能驱散的 debuff 就那些 spellID，逐个问在不在。
  · 候选集（一次性，后台分摊建库、可落盘）：扫客户端静态法术库，取
    dispelType ∈ {Magic, Disease, Poison} 的全部 ID；限制旗 ID 仍保留轮询
    （问它只会假阴性，不会假阳性），只用于判定候选集是否「可信」。
  · 每 tick 轮询 320 个 ID，按单位独立游标，30ms 同 tick 缓存；
    UNIT_AURA 时游标回绕，刚上的短 debuff 下一 tick 就被问到。
  · 命中 → 精确 true（并把这个 ID 记进已发现表）；
    一轮扫完零命中且候选集可信 → 精确 false（直接熄灭）。
- 这条 false 是「没中 debuff 不亮」的正解：不再需要任何「有减益就放行」的降级口径，
  也不再依赖任何被封死的容器/按钮读回。受限战斗内外同一套语义。
- 诊断 /FH_QJS_DEBUG 新增：轮询候选=数量/剔N/可信/源/secretAPI、建库进度、
  轮询判定、轮询游标（含命中 ID）。
- 夹具：新增 test_paladin_cleanse_id_scan.py（S1-S5 静态、D1-D3 建库、
  P1-P7 轮询语义），清洁术全家族 25 个夹具全绿。


【防骑】2026-11-21（撤销「战斗盲驱」：不要盲驱散，读不到就判无）
- 用户口径（原话）：「不要盲驱散」。
- 撤销内容：上一条日志里的「战斗盲驱」层 —— 按清洁术本地 8 秒 CD 试驱、
  靠客户端「没有可驱散的法术」回执自校准。该口径会让没中 debuff 时也周期性
  点亮色块 → AHK 按下 → 空放 GCD，用户明确不要。
- 现在的口径（UnitHasDispel 受限段）：
  · 只采信能证明「清洁术驱得掉」的肯定证据：白名单 ID 直查 / 类型名直查 /
    引擎「我本人能驱散」组 / RAID 存在性 / EUI 驱散纹理 / 严格探针；
  · 以上全部读不到 → **判无（不亮）**。本服战斗中很可能一次都不驱 —— 这是
    用户选择的行为：宁可漏驱，也不空按。
  · 已删除：CleanseBlindAt / CleanseBlindCount 计时、回执对盲驱节奏的推后、
    面板「盲驱」复选框（FH_QJS_Blind）；迁移把旧存档残留的 FH_QJS_Blind
    显式清成 false，确保没有任何历史配置能重新打开它。
- 保留不动：客户端「没有可驱散的法术」回执仍接成 20~60 秒退避 ——
  它只在**已有证据放行后打空**时兜底（例如容器/类型组给了一次误判），
  不会主动产生空按。
- 夹具：test_paladin_cleanse_blind.py 改为「禁止盲驱」契约（B1-B3、E1-E7）。

【防骑】2026-11-21（战斗中「没 debuff 也按清洁术」的根治：盲驱开关 + 回执自校准；EUI 通道修好单位解析）
- 用户口径：12:46 战斗内 /FH_QJS_DEBUG（勾「自己」、下拉=5）显示 ——
  AuraData(HARMFUL/RAID)=ERR「Auras cannot be accessed when secret while tainted
  by 'MKHelperForever'」、AuraSlots(RAID)=ERR、ID直查/ID分类/类型直查/严格探针/
  提示扫描/悬停提示 全 nil、probe 四组恒空、EUI按钮=减益1280/全2010 但 EUI可见=false(0/0枚)、
  光环负载=nil/add=nil → 最终=false，可本地CD中=true。也就是「刚驱过、还在 CD」，
  但只要 CD 一转好就会再亮一次 —— 因为战斗内根本读不到「到底有没有可驱散的减益」。
- 结论（本服硬约束，不再靠加读通道解决）：战斗中客户端把光环数据整段锁成 secret，
  C_UnitAuras / GetAuraSlots / AuraUtil.ForEachAura / 探测容器 / EUI 按钮 IsShown /
  tooltip / UNIT_AURA 负载 **全部**读不到。前 28 次修复加的任何一条读通道在真机上
  都只能得到 nil；继续加只会继续得到 nil。唯一还握有权威答案的是客户端自己。
- 修复①（**已于同日三十次修复撤销**，见上一条：用户口径「不要盲驱散」）：
  曾新增「战斗盲驱」层（按本地 8 秒 CD 试驱 + 客户端回执自校准），
  现已整段移除，受限战斗回到「只认证据，读不到就判无」。
- 修复②：EUI 减益按钮「单位解析」——这条通道此前从未真正执行过。
  · 根因：Blizzard_AuraContainer.xml 的默认 KeyValue 是 unitToken = "none"，
    而 AK.AddGroupToContainer 在 SetUnit 之前调用 → container:GetUnit() 返回 "none"。
    旧代码只挡非字符串，于是每枚按钮都记成 unit="none"，
    EUI_HarmfulPresence 里 (u == nil or u == unit) 永不成立 → tried 恒 0。
    真机「EUI按钮=减益1280/全2010」但「EUI可见=false(0/0枚)」正是这条。
  · 修法：建组时把 "none"/"" 归一成 nil；扫描时按容器当前 unitToken 惰性解析并回填；
    解析不出单位的按钮**不再**被当成「任何单位的按钮」（旧写法会让一枚残留显示
    按钮把该单位判成「有减益」），改为计入「未解析」并在诊断里显示。
- 诊断增强：/FH_QJS_DEBUG 新增「战斗盲驱=开/关 + 距上次 Ns + 累计 N 次」，
  EUI可见 后追加「/未解析N枚」，可直接看出盲驱节奏与 EUI 单位解析情况。
- 夹具：新增 test_paladin_cleanse_blind.py（B1-B3、E1-E6，16 条）与
  test_paladin_cleanse_eui_unit.py（U1-U6，7 条）；清洁术家族 25 个夹具全绿，
  全量 Lua 语法 216 文件 0 失败。

【防骑】2026-11-21（报错刷屏 6 次：secret string 参与比较 → 修 2900 处 + 整条探测链加 pcall）
- 用户报错原文：
  Paladin_Forever.lua:2900: attempt to compare local 'v' (a secret string value,
  while execution tainted by 'MKHelperForever')
  调用链：TurnOrActionStop → PLAYER_TARGET_CHANGED → NoteTargetTypeProbe
  → CreatureTypeByGameTooltip → ParseCreatureTypeText
- 根因（顺序写反）：ParseCreatureTypeText 第一行是
  `if type(v) ~= "string" or v == "" then return nil end`。
  secret string 的 type() **仍然是 "string"**，第一段守卫直接放行，
  接着执行 v == "" —— 对 secret 值做 == 立刻抛错。secret 检测写在第二行，顺序反了。
  与 2026-11-15 NormalizeDispelType 那次是同一个病根，当时只修了那一个函数。
- 为什么危害大（不只是刷屏）：异常从 PLAYER_TARGET_CHANGED 冒到 TurnOrActionStop，
  NoteTargetTypeProbe 后半段的记账全部中断 —— 新目标的类型证据没刷新、旧 memo
  也没清 → 同时出现「亡灵/恶魔不打驱邪术」和「旧目标类型误套新目标」。
- 修复：
  · ParseCreatureTypeText：secret 检测提到**任何比较之前**，整段再包 pcall；
  · KindFromShortText（同类隐患，string.lower 的返回值也可能是 secret）同样处理；
  · CreatureTypeFromTooltipInfo 的 leftText / rightText、CreatureTypeByGameTooltip
    的 GetText() 都在**源头**收敛 secret → nil，不再把 secret 往下传；
  · NoteTargetTypeProbe 整段 pcall 并返回 okBody，绝不向外抛；
  · IsUndeadOrDemon 的两条提示通道各包 pcall，读不到只是 nil，不打断循环 tick；
  · PLAYER_TARGET_CHANGED 处理器里再包一层 pcall（最后一道保险）；
  · 顺手修 NormalizeName / GetSpellInfo 反查名的同类顺序问题
    （UNIT_SPELLCAST_SUCCEEDED 的 spellName 在受限战斗里也是 secret）。
- 铁律记录：secret string 的 type() 仍是 "string"，**任何** == / ~= / 字符串比较
  之前必须先过 WR_IsSecretValue / issecretvalue；整段再包 pcall 兜底。
- 夹具：新增 test_paladin_secret_compare.py（S1–S6 静态 + D1–D8 动态，15 条全绿），
  验证 secret 文本不抛错、正常文本仍判对、探测被 pcall 包住后记账照常。

【防骑】2026-11-21（驱邪术：目标为亡灵 / 恶魔仍不打 —— 补两条「提示数据」类型通道）
- 用户口径：「防骑驱邪术目标为亡灵，恶魔怪的时候，没有打这个技能」。
- 根因（不是漏写类型词，是通道覆盖不全）：前三通道 —— ①直读 UnitCreatureType、
  ②怪名缓存、③同目标 memo —— 全都依赖「进战前或脱战时读到过一次」。实战里最常见的
  恰恰是「战斗中才选中目标」：被 ADD 拉怪、追击换目标、tab 切目标、目标死亡后自动换
  下一只。此时 UnitCreatureType 是 SecretWhenUnitIdentityRestricted（读不到），UnitName
  走另一条受限通道，memo 刚被 PLAYER_TARGET_CHANGED 清空 → 三条全废 →
  IsUndeadOrDemon 恒 false → 单体链 / 多目标链共用的 exorcismEligible 恒 false →
  驱邪术整场不亮。
- 修法（本客户端把「单位提示」交给引擎组装成数据表 / 帧文本，这条数据流不吃身份
  与光环的 secret 旗；本仓库清洁术早已用同源的 C_TooltipInfo.GetUnitDebuffByIndex
  拿到 spellID，EllesmereUINameplates / Lueur 生产代码同样用 C_TooltipInfo.GetUnit 读
  单位提示行）：
  · 新增 ③ WR_PaladinForever_CreatureTypeFromTooltipInfo：C_TooltipInfo.GetUnit(unit)
    → .lines 扫前 4 行（名字 / 「70 级 亡灵」/ 公会 / 精英标注），短行门 ≤32 字符；
    纯数据表，零帧操作、零 taint 风险。分级缓存：命中 2 秒、可读未命中 3 秒、
    读不到或被拒 0.5 秒重试 + 3 秒退避；换目标（TargetEpoch 变化）立即失效。
  · 新增 ④ WR_PaladinForever_CreatureTypeByGameTooltip：C_TooltipInfo 被拒时用
    GameTooltip:SetUnit 读前 4 行文本，复用既有 ProbeByGameTooltip 的安全范式
    （不 CreateFrame、不抢玩家正在看的 tooltip、2 秒节流、读完立刻 Hide）。
  · 命中即记账（刷新同目标 memo + 按怪名学习），后续 tick 走 memo 零开销；
    memo 提到提示通道之前，避免每 tick 重复构建 tooltip。
  · PLAYER_TARGET_CHANGED 的 NoteTargetTypeProbe 改为「直读 → 提示数据 → 提示帧」
    三级探测：旧实现直读失败就直接清 memo，等于把新目标的类型证据彻底丢掉；
    现在三条全读不到才清（仍然绝不把旧目标类型套到新目标）。
  · 可用性通道补「全 rank 兜底」：解析到的当前 rank 因法术书索引过期 / 换 rank
    瞬间给出 false 时，逐 rank 再问一遍，任一 rank 明确可用即视为可用
    （已学会但 rank 对不上 ≠ 打不出去）。
  · 口径不变：类型读不到一律判 false（宁可不打），绝不把「技能可用」当类型证据，
    不会引入「普通怪也亮驱邪术」的回归。
- 诊断：/FH_QX_DEBUG 新增「提示数据=」「提示帧=」「命中通道=」三项，
  一眼看出本次是靠哪条通道判定的。
- 夹具：新增 test_paladin_exorcism_tooltip_type.py（T1-T13：亡灵/恶魔/人型/两条
  通道互备/只扫前 4 行/颜色码/换目标探测记账与清空/epoch 失效/端到端点亮槽 20）；
  驱邪术 6 个夹具 + 圣骑士全家族夹具 0 失败，全量 Lua 语法 216/216。
【防骑】2026-11-20（战斗中「没中 debuff 也用清洁术」：删掉两处弱信号判据）
- 用户口径：「战斗中还是有个问题，没中debuff也会用清洁术」。
- 根因（两条，都是把弱信号当点亮判据；前几次修的都是「读不到」，这次是「读到了但不够格」）：
  · R1 UNIT_AURA 处理器在 presence=nil（本服战斗中恒为 nil）时仍写候选闩锁
    （AuraHarmfulAt + 2.5 秒 CleansePendingUntil），靠「不是自己刚打的增益」兜底。
    但队伍 buff / 图腾 / 天赋触发 / 别的单位刷新的增益都不是本插件施放的，
    于是每次增益刷新都换一次空放 GCD —— 正是用户看到的「没中 debuff 也在按」。
  · R2 UnitHasDispel 的受限降级段仍保留「有任意减益就放行」这一档
    （11-19 十三次修复的历史口径，当时为了「中毒了不驱」宁可误驱）。
    中诅咒 / 流血 / 不可驱散的机关 debuff 都会点亮，而清洁术只能解中毒/疾病/魔法。
- 修法（精度优先：宁可不驱，也不空放 GCD）：
  · 候选闩锁的唯一写入条件改为 eventTrusted（引擎「我本人能驱散」组可读 = 本 tick
    真能判型）。本服战斗中该组不可读 → 事件彻底不参与点亮，只留诊断。
  · 删掉「有任意减益就放行」。受限战斗只认能证明类型的肯定证据：
    白名单 ID 直查 / 类型名直查 / 引擎「我本人能驱散」组 / RAID 存在性
    （RAID+HARMFUL = 引擎按职业判定的「我能驱散」，诅咒/流血进不来）/ EUI 驱散纹理。
    以上全部读不到 → 判无（不亮）。
  · EUI 引擎驱散纹理（poison/disease/magic 图集）提到「me 组 = 0 判无」之前：
    me 组是本插件私有探测容器，真机从不填帧，它的 0 不能盖掉 EUI 的肯定证据。
- 影响：真减益（中毒/疾病/魔法，含已录入的 7125 / 15850 / 12541 等）照常点亮；
  纯增益刷新、诅咒、流血、不可驱散减益一律不点亮。
- 夹具：新增 test_paladin_cleanse_no_false_positive.py（G1-G10）；
  同步更新 event_trust / pending_latch / combat(J28) / presence_filter(R6) 的契约。
  清洁术 24 个夹具全绿，圣骑士全家族夹具 0 失败，全量 Lua 语法 215 通过。

【防骑】2026-11-20（战斗内清洁术：事件分不出增益/减益 → 改由引擎回执裁决）
- 用户真机诊断（08:40，战斗中，勾「自己」+ 下拉=5）：
    光环负载=nil/add=nil   负载新增=false   减益存在=nil   容器已验证=false
    事件减益=nil   任意减益=true   最终=true   待处理=剩6.7s   光环读取=被拒
  即：本服战斗里 updateInfo.addedAuras 连读都读不到。
- 根因（同一个信息缺失的两面，用户先后报的两个症状都出自这里）：
  · 「没中毒也亮」：只要事件被当成「确有新增」，闩锁就被写 → 增益刷新
    （圣印/祝福/正义之怒/队伍 buff）也会点亮 → AHK 连按 → 空放 GCD。
  · 「中毒了不驱」：闩锁的唯一写入点依赖 addedAuras 可读，本服读不到 →
    中立候选永不产生；「任意减益=true」其实是闩锁自证，闩锁一过期就再无信号。
- 修法（不再让事件决定「该不该驱」，改由引擎裁决）：
  · 新增 WR_PaladinForever_CleanseCanTrustEvent：只有「脱战/非受限」或
    「引擎 HARMFUL 组可读」时，事件才有资格写闩锁；本服战斗中一律不可信。
  · 闩锁窗口分级：可信 8 秒（够 AHK 走完一次施放）；不可判 2.5 秒（一次性试驱）。
  · 新增引擎「无可驱散」回执监听（UI_ERROR_MESSAGE）：
    ERR_NOTHING_TO_DISPEL / 「没有可驱散的法术」= 本服唯一可得的**权威否定证据**。
    收到即把刚点亮过的单位置入退避（20→30→40 秒，上限 60），并立刻收色块。
  · 退避只压弱信号：白名单 ID 直查 / 类型名直查 / tooltip / 引擎组这些**肯定证据**
    命中时先清退避再放行 —— 真中了中毒/疾病/魔法绝不被退避挡住。
  · 清洁术施放成功 → 立刻作废三个单位的闩锁（旧版要等 8 秒自然过期，
    这 8 秒里 AHK 会持续按键，把 GCD 全空放掉）。
- 诊断新增：「事件可信=」「无可驱散退避=剩Ns/N次」，一眼看出事件能否当判据。
- 夹具：新增 test_paladin_cleanse_event_trust.py（16 条：E1-E3 事件可信、
  N1-N4 回执文案、B1-B2 退避与肯定证据优先、C1-C2 施放清闩锁）。
  全量清洁术夹具 24 个全绿，圣骑士全家族 0 失败，全量 Lua 语法 216/216。

【防骑】2026-11-20（撤掉 securecallfunction：它既不解决战斗内读不到光环，还让 57 条报错刷满屏幕）
- 用户报错（真机原文，一次会话 57 条）：
    GetAuraSlots(): Auras cannot be accessed when secret while tainted by
    'MKHelperForever'   Lua Taint: MKHelperForever
    [Paladin_Forever.lua]:6642 ← 6640 ← 6615（SecureForEachPresence）
    ← 7042（UnitHasDispel）← 7666 ← 7676（CleanseStep）← Prot:2498
  Locals: unit="player"  f="HARMFUL|RAID"
- 根因（二十四次修复的前提被真机否掉）：
  · 上一版把「Auras cannot be accessed when secret while tainted by ...」理解成
    「拦截条件是 taint，secure 上下文里照常可读」，于是把光环读取整段包进
    securecallfunction。真机结果：报错**原文一字未变**，一条都没少。
  · 而且比改之前更糟：securecallfunction 是**不可被 pcall 跨越的边界**，异常不再
    返回给 pcall，直接进全局错误处理器（带 Locals + Lua Taint 标记）刷屏 ——
    之前是静默 nil，现在是满屏红字。
  · 机制上 securecallfunction 只阻止「被调函数的污染传回调用者」，不会把调用者
    变成 secure 上下文；本服战斗内光环读取按**调用者**判 taint，所以照旧被拒。
- 修复（六处，全部改回普通 pcall）：
  · WR_PaladinForever_UnitDispelPresence 的 ForEachAura / GetAuraSlots 两处；
  · WR_PaladinForever_ForEachHarmfulPresence；
  · WR_PaladinForever_UnitHasAnyHarmful；
  · WR_PaladinForever_SecureScanDispellable（含去掉「没有 securecallfunction 就
    直接返回 nil」的前置门 —— 那会让整条通道在本服彻底失效）；
  · WR_PaladinForever_SecureForEachPresence 的 GetAuraSlots / ForEachAura 两处。
  语义完全不变：读得到 = 精确证据（true），读不到 = nil（未知），绝不判无。
- 顺带修掉一处**误驱**：SecureScanDispellable 判型时只看 dispelName，而本服
  「荆棘诅咒 6909」的 dispelName 被服务端错标成 Magic（历史截图实证）→ 判成 magic
  → 空放清洁术。现在与 ScanUnitDebuffTypes 同口径：**先过诅咒黑名单**
  （NEVER_CLEANSE_SPELL_IDS 6909 / 名字含「诅咒」「curse」），再看
  dispelName → 名字白名单 → spellID 静态分类。
- 诊断增强：/FH_QJS_DEBUG 新增「光环读取=被拒/可用」一行 —— 直接告诉你本服此刻
  到底给不给读光环。显示「被拒」就说明不是白名单漏了，而是引擎整段拒绝，
  此时靠 UNIT_AURA 事件 + 待处理闩锁这条**不读光环**的路径工作。
- 验证：清洁术夹具 24 个全绿（含新增静态断言「必须不包 securecallfunction」）；
  圣骑士全家族夹具 0 失败；全量 Lua 语法 216/216 通过。

【防骑】2026-11-20（「脱战能驱散、战斗内不驱散」：secure 上下文引擎侧存在性通道 + 修掉两处 ForEachAura 假阴性）
- 用户口径：「脱战后能正常驱散」——说明判定链本身没错，只有**战斗内**失效。
- 真机 /FH_QJS_DEBUG（04:01）把拦截机制写得很清楚：
  AuraData(HARMFUL)=ERR[GetAuraDataByIndex(): Auras cannot be accessed when secret
  while **tainted by 'MKHelperForever'**]；AuraData(RAID) / AuraSlots(RAID) 同款；
  presence判定=false；RAID通道=false；任意减益=false。
- 根因（两条，都是假阴性）：
  · R1 拦截条件是 **tainted**（被本插件污染的执行上下文），不是「战斗内一律不可读」。
    旧实现全程在污染上下文里读光环 → 必然被拒。暴雪自己就用 securecallfunction
    调用 addon 的 initializeFrame（Blizzard_AuraContainerFrameProviders.lua:CreateFrame），
    说明 secure 上下文里引擎侧求值照常工作。
  · R2 更致命：AuraUtil.ForEachAura 在受限战斗里可能**不抛错但返回空**（secret 下
    「不给你值」而不是报错）。旧代码把「不命中」当成「引擎明确说没有减益」→
    UnitHasAnyHarmful 返回 false → UnitHasDispel 的降级通道被一票否决 → 战斗中永不点亮。
- 修复：
  · 新增 WR_PaladinForever_SecureForEachPresence(unit, filter)：把
    C_UnitAuras.GetAuraSlots / AuraUtil.ForEachAura + "HARMFUL|RAID" 整段包进
    securecallfunction。RAID + HARMFUL 的暴雪语义（API types/AuraFilters 原文）
    =「只含玩家本人能驱散的减益」，由 C 侧按职业/专精过滤，诅咒/流血进不来；
    只读槽位号与回调次数，一个光环字段都不碰。只采信 true，false/抛错/API 缺失
    一律 nil（读不到），绝不判无。
  · 该通道接在 UnitHasDispel 的**受限降级段**：前面所有肯定证据通道（精确组 /
    白名单 ID / tooltip / 类型直查 / DebuffFrame / 严格探针）先跑完，它们命中就返回；
    严格探针明确答「全是诅咒/流血」时也已 return false —— 所以不会把诅咒放行。
    脱战（非受限）不启用该降级，保持原有精度契约。
  · UnitDispelPresence / UnitHasAnyHarmful / ForEachHarmfulPresence 三处的
    ForEachAura 全部改走 securecallfunction，且「不命中即判无」统一改为 nil。
- 诊断：/FH_QJS_DEBUG 新增「secure引擎=」「secure引擎通道=」两行，真机可一眼看出
  secure 上下文里引擎到底答了什么。
- 夹具：新增 test_paladin_cleanse_secure_combat.py（S1-S7 静态 + F1-F6 函数级 +
  E1-E3 端到端）；test_paladin_cleanse_presence_filter.py 的 R2 契约更新为
  「ForEachAura 不回调 → nil（读不到，不判无）」；frost_15850 的 S3 断言改为 secure 形态。
  清洁术 23 个夹具全绿，圣骑士全家族夹具 0 失败，全量 Lua 语法 216/216。

【防骑】2026-11-20（毒性唾液 7125 · 中毒，战斗中一直不驱散：修掉「读不到就当没有」的最后一环）
- 用户口径：实测截图「毒性唾液 · 法术ID 7125 · 中毒 · 每6秒17点自然伤害 / 每6秒吸取20点法力 · 剩余2分钟」，
  战斗中防骑全程没亮清洁术 → 没驱散。而 7125 早在 11-19 就进了白名单，说明问题不在白名单。
- 根因（三条，与前几次「没中毒也亮」是同一处代码的两面）：
  · R1 本服战斗内 auraData 字段全 secret，探测容器在真机上从未真正工作过
    （Blizzard 源码实证：AddAuraGroup **没有返回值**，GetAuraGroup 不在公有分区，
      公有接口只有 HasAuraGroup / GetAuraGroupFrame / GetAuraGroupFrameCount）——
    所以 CleanseProbeHarmfulPresence 在真机上恒为 nil（诊断「减益存在=nil」）。
  · R2 旧实现在 presence=nil 时「什么都不做」→ AuraHarmfulAt 永远不被写 →
    降级通道「有任意减益就放行」拿不到任何信号 → 战斗中清洁术一次都不亮。
  · R3 即使写了一次，UNIT_AURA 在减益挂上后就不再派发（2 分钟 / 10 分钟的 debuff 只派发一次），
    3 秒事件窗口一过就熄，8 秒 CD 内再也不亮 → 用户看到「中了毒却没驱」。
- 修复（三处，都是「只认肯定证据、读不到绝不判无」）：
  · F1 presence=nil 时改用「确有新增光环 + **不是自己刚打的增益**」放行：
    增益刷新的绝大多数来源是本插件自己的施放（圣印 / 正义之怒 / 神圣之盾 / 祝福 / 光环），
    成功施放事件与 UNIT_AURA 相隔 < 0.8 秒，用施法账本（SELF_BUFF_SPELLS + 全部圣印名）
    滤掉；剩下的「凭空新增的光环」在战斗中只能是怪物/环境施加的减益。
  · F2 新增「待处理闩锁」CleansePendingUntil = now + 8（= 清洁术本地 CD），
    让 AHK 有一次完整的施放机会；闩锁过期后由**精确通道续期**（见 F3）：
    secure 读取明确答「身上确有可驱散减益」才续，读不到 / 明确没有（诅咒、流血、增益）一律不续。
  · F3 新增 secure 上下文读取通道 WR_PaladinForever_SecureScanDispellable：
    真机报错原文是「Auras cannot be accessed when secret while tainted by 'MKHelperForever'」
    —— 拦截条件是 **taint**，不是「战斗内一律不可读」。securecallfunction 让被调函数在
    不向调用者传播污染的前提下执行，暴雪自己就用它调用 addon 的 initializeFrame
    （Blizzard_AuraContainerFrameProviders.lua:CreateFrame）。在 secure 上下文里重试
    GetAuraDataByIndex（类型名 / 名字 / spellId 三条判型）与 GetPlayerAuraBySpellID
    （白名单 + 已发现 ID 直查）。命中即真精确（毒/病/魔法）；false/nil 一律**不据此判无**。
- 另修一处同源降级：把「引擎侧 HARMFUL 存在性」（AuraUtil.ForEachAura + "HARMFUL"）
  摆在「任意光环变化」之前。ForEachAura 的过滤器由引擎求值，增益永远进不了 HARMFUL 集合，
  回调里一个字段都不读（不受 secret 限制），只采信 true —— 比「有变化就亮」干净得多。
- 诊断（/FH_QJS_DEBUG）新增三行：secure读取= / 待处理=剩Ns / 自身增益刚施放=，
  真机上可以直接看出是哪一环在起作用。
- 夹具：新增 test_paladin_cleanse_pending_latch.py（S1-S5 + T1-T12，17 条）覆盖
  presence=nil 放行、增益抑制、闩锁续期与过期、secure 通道的 true/false/nil 三态、
  以及 UnitHasDispel 的放行语义。全部 22 个清洁术夹具 + 圣骑士全家族 + 216 个 Lua 文件语法检查通过。

【防骑】2026-11-20（中了「食尸鬼腐气 12541 · 疾病」不驱散：白名单补录 + 修掉三处「读不到当成没有」的假阴性）
- 用户口径：实测截图「食尸鬼腐气 · 法术ID 12541 · 疾病 · 攻击命中几率降低10% · 剩余10分钟」，
  战斗中清洁术全程没亮 → 没驱散。这条是长 debuff（10 分钟），漏判就是整场带病输出。
- 根因（三条，全是「把读不到当成明确没有」）：
  · R1 12541 与名字「食尸鬼腐气」都不在任何白名单 → 免读回 ID 直查通道（战斗中唯一
    还能工作的通道）对它完全失效 → 全链 unknown → 不亮。
    诊断 /FH_QJS_DEBUG 里「ID直查=nil  ID分类=nil」就是这条通道全 miss 的直接证据。
  · R2 本服原生 UnitDebuff 不存在，它由 Core/Forever_Compat.lua 用
    C_UnitAuras.GetAuraDataByIndex 包装实现。受限战斗里那条 API 抛
    「Auras cannot be accessed when secret」→ 包装层只能返回 nil。
    但 nil 的语义是「读不到」，**不是**「没有这条光环」；旧实现 sawAny 之后
    return false，等于向 UnitHasDispel 报告「明确没有可驱散减益」→ 战斗中的清洁术被
    一票判死。诊断里「类型直查=false」就是这条假阴性。
  · R3 同款假阴性还在另外两条通道里：「任意减益=false」（UnitHasAnyHarmful）与
    「RAID通道=false」（UnitDispelPresence）。用户此前明确接受「战斗中至少按有减益就提示」
    的降级口径，结果连这条降级也被假阴性掐死，最终「最终=false」。
- 修复：
  · 白名单补 12541=疾病（ID 表 + 名字表双写）。名字在本服通常可读，两条通道互为备份，
    任一命中即点亮；白名单是免读回的，战斗中照样生效。
  · Core/Forever_Compat.lua 给包装层打标记 WR_Forever_UnitDebuffShim。业务层据此区分
    「原生 API 说没有」与「包装层读不到」：受限 + 包装层时，nil 一律当未知，不再当否定。
  · UnitDebuffByDispelKind / UnitHasAnyHarmful / UnitDispelPresence 三处接入该标记。
    UnitDispelPresence 同时改为：全通道读不到时明确返回 nil（未知），绝不返回 false。
  · 非受限上下文行为完全不变：包装层的 nil 仍可采信为「明确没有」，脱战仍精确判型，
    诅咒 / 流血 / 不可驱散减益照旧排除，不会退化成「有减益就亮」。
- 夹具：新增 test_paladin_cleanse_ghoul_12541.py（10 项）。W1-W4 白名单与判型；
  W5-W6 战斗中免读回 ID 直查命中 → UnitHasDispel=true（本次核心断言）；
  S1-S3 受限 + 包装层时三条通道都返回 nil 而不是 false；S4 非受限仍返回 false。
  全部 21 个清洁术夹具 + 全量圣骑士夹具通过，全量 Lua 语法 216/216 通过。

【防骑】2026-11-20（中了「冰冻 15850 · 魔法」不驱散：ID/名字进白名单 + 悬停学习通道）
- 用户口径：实测截图「冰冻 · 法术ID 15850 · 魔法 · 攻击间隔延长25% · 移速降低30% · 剩余2秒」，
  清洁术全程没亮 → 没驱散。
- 根因（两条）：
  · R1 15850 与名字「冰冻」此前都不在任何白名单里。战斗中 auraData.spellId / dispelName
    是 secret → ID 直查、多 API 扫描、tooltip 槽位扫描全部读不到 → 全链 unknown → 不亮。
    而这条 debuff 剩余只有 2 秒，任何「慢通道」都来不及。
  · R2 玩家肉眼能看到 tooltip 的类型和法术ID，说明引擎已经把这两个值交给了
    TooltipDataProcessor.UnitAura 数据流；但插件只在「自己主动扫描」时才去读，
    战斗里那条调用常被拒 → 白名单外的新 ID 永远学不进来。
- 修复：
  · ① 白名单补 [15850] = "magic"（CLEANSE_KNOWN_AURA_IDS）与 ["冰冻"] = "magic"
    （CLEANSE_KNOWN_AURA_NAMES）。这两张表只认**已确认**的 ID/名字，
    走 GetPlayerAuraBySpellID 免读回直查 —— 战斗中同样命中，且不会把诅咒放进来。
  · ② 新增「悬停学习通道」WR_PaladinForever_LearnAuraFromTooltipData：
    挂 TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura)，
    玩家自己悬停看 debuff 时，把可读的「法术ID + 类型」抄进 CLEANSE_DISCOVERED_IDS，
    下一场战斗 ID 直查自动覆盖它 —— 不用再靠截图逐条补录。
    只记毒/病/魔法；诅咒/流血一律不记（清洁术驱不了）。只学习，不在回调里点亮色块。
  · ③ RAID 存在性通道（UnitDispelPresence）改为 ForEachAura("HARMFUL|RAID") 优先 +
    GetAuraSlots 回退 + UnitAura/UnitDebuff 兜底，**仍只做诊断**（不接判定）：
    本服对未知过滤令牌的处理是「整段忽略」，接进判定会让中诅咒也照驱（历史 H4/J28）。
    现在 /FH_QJS_DEBUG 会直接打出「RAID通道=true/false/无记录 + 走的哪条 API」，
    供真机确认本服 RAID 滤镜是否生效。
- 夹具：新增 test_paladin_cleanse_frost_15850.py（S1–S4 静态 / P1–P5 RAID 通道 /
  E1–E3 端到端 / L1–L5 悬停学习），17 条全绿；清洁术 20 个夹具全绿，
  圣骑士全家族 0 失败，全量 Lua 语法 794 文件（仅 .agents 历史 worktree 里 3 个旧副本报错，非本次改动）。

【防骑】2026-11-20（圣印选智慧 + 审判buff选智慧审判：确认会打审判，并修掉「反复点圣印不打审判」）
- 用户口径：「当审判buff选择智慧审判，圣印选择智慧圣印是否会打审判」。
- 结论：会打。三条路径都实测点亮审判（槽 2）：
  · 只选圣印=智慧、不勾审判buff开关 → 主调度按常驻智慧圣印正常打审判（目标已有智慧审判时不重复打）；
  · 圣印=智慧 + 勾「智慧审判」开关 → 由智慧审判状态机打（切印阶段跳过、直接提示审判），
    审判成功后直接进 phase4 维持（常驻就是智慧，无需切回）；
  · 目标已有光明审判 + desired=wisdom → 允许用智慧审判顶掉（光明/智慧同属一个审判槽位，用户要的是智慧）。
- 顺带修掉一个同源 bug：常驻圣印本身就是「智慧 / 光明 / 十字军」时，状态机 phase0/phase1 仍要求
  「光环确认该圣印在身上」。战斗中光环是 secret 读不到 → 反复点圣印 → 2 秒确认不到 → 回 phase0
  → 再点…… 审判永远打不出去（与 11-17「审判buff维持不灵敏」同源）。现在：常驻就是该圣印
  且光环是 unknown（不是权威 missing）时，跳过确认直接进入「等待审判」，补印交给主循环维持段。
  三条状态机（智慧审判 / 光明圣印 / 十字军审判）同款处理。
- 夹具：新增 test_paladin_wisdom_seal_judge_conflict.py（A1/B1/C1-C3/D1-D3/E1-E2/F1/G1/H1-H3 共 14 条）；
  审判家族 10 个夹具、全量圣骑士夹具 0 失败；全量 Lua 语法 794 文件 0 错。

【防骑】2026-11-20（战斗内清洁术改为**精确**：引擎原生「我本人能驱散」组 + 修正三处非法过滤令牌）
- 用户口径：战斗里要**精确**用清洁术 —— 中了中毒/疾病/魔法才亮；诅咒、流血、只挂
  不可驱散减益、以及增益刷新，一律不许亮（旧版这些都会亮 → AHK 空放 GCD）。
- 根因（三处，全在引擎侧过滤令牌/判据上，不是 secret 读不到的问题）：
  · R1 探测容器的 YOU 组 filter 写成 "HARMFUL|RAID_PLAYER_DISPELLABLE"。按暴雪 AuraFilters
    语义，RAID_PLAYER_DISPELLABLE + HARMFUL = 「我所在**团队里有人**能驱散」，不是「我本人
    能驱散」——队里有德/法/牧时诅咒也进组，于是中诅咒照样点亮。
    真正表示「我本人能驱散」的是 **RAID** 令牌（原文：with HARMFUL → "Include only
    auras the player can dispel"）。项目历史上曾判定「RAID 只表示团队 debuff、单人/
    5 人本不命中」，该判定与暴雪文档不符，正是「战斗内永不点亮」的老病根。
  · R2 类型组把 Magic / Disease / Poison 当成**过滤令牌**写进 filter 串
    （"HARMFUL|Magic"）。暴雪令牌表里没有这三个令牌（合法令牌只有 HELPFUL / HARMFUL /
    PLAYER / RAID / RAID_PLAYER_DISPELLABLE / RAID_IN_COMBAT / CANCELABLE /
    INCLUDE_NAME_PLATE_ONLY / MAW / EXTERNAL_DEFENSIVE / CROWD_CONTROL /
    BIG_DEFENSIVE / IMPORTANT / DISPELLABLE）。被忽略时整组退化成裸 HARMFUL（诅咒
    进组 → 误亮）；被整串拒绝时三组恒空。正确写法是 filter="HARMFUL" +
    candidateFilters.includeDispelTypes={X=true}（EUI UnitFrames 生产同款）。
  · R3 判「没有」只认 blanket HARMFUL 组的 0，而 blanket 里的帧可能是诅咒 / 不可驱散
    减益 → 旧版被迫退化成「有减益就点亮」，于是没中毒也亮。
- 修复①（核心）：新增 WR_CLEANSE_PROBE_ME 组，filter = "HARMFUL|RAID"。引擎在 C 侧按
  玩家**当前职业/专精的驱散能力**过滤，圣骑士只放中毒 / 疾病 / 魔法，诅咒 / 流血由引擎
  自己排除；插件只数组内帧数 —— 零读回、零比较、不吃 secret，受限战斗内外同一套求值
  （暴雪团队框架画驱散高亮用的就是这条数据源）。这是唯一能同时给出两个方向权威答案的
  通道：>0 → 确有可驱散减益（点亮）；=0 且该组曾填过帧 → 引擎明确答「没有」（熄灭）。
- 修复②：类型组改为 filter="HARMFUL" + candidateFilters.includeDispelTypes（三键）。
  它的候选过滤读 auraData.dispelName，受限内容被 REDACTED → 战斗中恒空，因此只在
  非受限上下文才敢把它的 0 当「明确没有」。
- 修复③：presence 判定重排为「精确优先」——ME 组 → 类型组 → YOU 组 → blanket 帧类型
  回读（图集/顶点色）→ 都不行才 nil。**彻底删掉「blanket 有帧就点亮」和「DebuffFrame
  有条目就点亮」两条降级**：它们分不出类型，是诅咒误亮与增益刷新误亮的根源。
  用户已确认取舍：宁可暂时不亮，也不空放 GCD；真实减益由「有肯定证据才 true」的通道
  （白名单 ID 直查 / C_TooltipInfo 扫描 / UnitDebuff 类型名 / spellID 静态分类）兜回。
- 修复④：UnitHasDispel 接入 presence 作为精确门 —— true 直接放行；false 置否决标记，
  压掉最后的「有任意减益就放行」降级路径（精确组明确说没有时，不允许「有减益」翻案）。
  肯定证据类通道仍先跑完（容器增量维护有一帧延迟，以肯定证据为准）。
- 修复⑤：ME 组「曾填过帧」的凭据（WR_PaladinForever_CleanseMeLive）在 presence 与
  CleanseProbeHasDispellable 两条路径间共享，否则只走其中一条时永远不敢判无。
- 诊断：/FH_QJS_DEBUG 新增「可驱散组=N」（ME 组帧数），直接看出引擎此刻认不认。
- 夹具：新增 test_paladin_cleanse_me_group.py（M1-M12 / E1-E3 / D1 共 17 条：令牌静态
  校验、ME 组四态、判无凭据、精确优先、端到端不翻案）；清洁术全套 18 个夹具 0 失败，
  全量 Lua 语法通过（4 个 Core/*_DeathTime.lua 的历史 BOM 问题与本次无关）。

【防骑】2026-11-20（战斗内清洁术「没中疾病/中毒/魔法也亮色块」：新增光环降级为候选，必须由引擎 HARMFUL 组确认）
- 用户口径：清洁术战斗内能用，但身上没有疾病/中毒/魔法时也亮色块 → AHK 常按 → 空放 GCD。
- 根因：11-19「十八次修复③」把「UNIT_AURA 确有新增光环」直接当点亮依据。战斗里增益
  一直在刷新（圣印 / 祝福 / 正义之怒 / 队伍 buff / 天赋触发），每次新增都写
  WR_PaladinForever_AuraHarmfulAt → 色块几乎常亮。负载里的 isHelpful / dispelName 在本服
  战斗内是 secret，插件无法从负载区分增益与减益 —— 这条信号本身不够格当判据。
- 修复：新增 WR_PaladinForever_CleanseProbeHarmfulPresence(unit) —— 只读引擎 AuraContainer
  的组内帧数（零读回：不碰 name / dispelName / spellId / 图集 / 顶点色），按「精确优先」判定：
  · ① 类型组 magic / disease / poison 任一 > 0 → true（只收可驱散类型，诅咒进不来）；
  · ② RAID_PLAYER_DISPELLABLE 组 > 0 → true（引擎按职业判「我本人可驱散」）；
  · ③ 都不读不到时看 blanket HARMFUL 组：> 0 → true（只知有减益、不知能不能驱），
    = 0 且该容器此前确实填过帧（WR_PaladinForever_CleanseProbeLive）→ false；
  · ④ 容器整段读不到时再看暴雪 DebuffFrame（BuffFrame 装增益、DebuffFrame 装减益，
    两个帧本身就是引擎给的分界）：有条目 → true，空 → false；
  · 其它读不到 → nil（不猜）。
- 性能：presence 只读**已存在**的探测容器，绝不在 UNIT_AURA 里新建 —— 该事件会对
  party1-4 / raid1-40 / targettarget / boss1-5 等几十个单位派发，逐单位 Ensure 会在
  脱战时批量创建 AuraContainer。
- 接线：UNIT_AURA 处理器里 verdict=nil + 确有新增光环时，**只有 presence==true 才**记录
  触发时刻；false / nil 一律不点亮。增益永远进不了 HARMFUL 组，这就是「增益刷新」与
  「真中减益」的分界。漏掉的真实减益仍由白名单 ID 直查 / tooltip 提示扫描 / 类型直查
  这些「有证据才 true」的通道兜回来。
- 为什么要「容器已验证」：组恒为 0 有两种含义 —— ①真没减益；②引擎根本没往容器填帧
  （模板缺失 / SetUnit 被拒 / 时序漏事件）。只有先见过组内出现过帧，才敢把 0 当成
  「明确没有」，否则会把真实的毒/病/魔法一起压死（11-19 之前「一次都不驱」的老事故）。
- 诊断：/FH_QJS_DEBUG 新增「减益存在=true/false/nil」「减益组=magic=0,disease=0,poison=0,raw=1」
  「容器已验证=true/false」「事件减益=true/false/nil@Xs」，可直接看出本轮为什么亮/不亮。
- 夹具：新增 test_paladin_cleanse_no_debuff_prompt.py（P1-P9 / E1-E6 / A1-A2 / S1-S3 共 20 条：
  精确组命中 / blanket 兜底 / 容器未验证不判无 / DebuffFrame 第二通道 / 增益刷新不亮 /
  全量刷新不亮 / 可读毒照常亮 / 端到端两态 / 静态接线与诊断）；
  清洁术全套 17 个夹具 0 失败，全量 Lua 语法 215/215。

【全局】2026-11-19（插件列表标题改为「插件名 + 时间」）
- 用户口径：插件列表里显示的标题应为 MK 插件名称 + 时间。
- 旧值：`## Title:|cffFF69B4MKHelperForever|r` 与 `## Title-zhCN: |cffFF69B4 MKHelperForever|cff00ff00[魔兽世界：无限]v1.0`——
  中文本地化条目把客户端名与写死的 v1.0 拼在标题里，版本永远不随发版变化。
- 新值：两条都改为 `|cffFF69B4 MKHelperForever|cff00ff00 2026-11-19`（粉名 + 绿时间），
  并把 `## Version` 同步为 `1.0-forever.20261119`，标题时间与版本号同源。
- 新增夹具 test_toc_title_datetime.py（T1-T6），断言标题含插件名、含 YYYY-MM-DD、
  不再含旧字样、zhCN 与英文条目同款、Version 与时间同源、颜色码保留。

【防骑】2026-11-19（战斗内清洁术最终口径：确有新增光环即提示，全量刷新不再误亮）
- 用户确认取舍（AskUserQuestion）：「有新增光环就亮」——能驱 > 少误亮。
- 实现：新增 WR_PaladinForever_PayloadHasAddedAura(updateInfo)
  · addedAuras == nil（全量刷新/仅更新事件）→ false，不点亮；
  · addedAuras 是 table（哪怕长度/字段是 secret）→ true，点亮。
  两者都只读「表是否存在」，不读任何光环内容，因此不会被 secret 拦截。
- 事件处置：verdict==true（可读且明确可驱散）→ 记录；verdict==nil 且确有新增 →
  记录（8 秒限流）；verdict==false（增益/诅咒/无驱散类型）→ 记录也不点亮。
- 与 03:38 误亮的分界：那时「任何 UNIT_AURA 都算」，现在只认「确实新增了光环」；
  开战、切场景、增益到期等全量刷新事件不再触发清洁术。
- 脱战路径完全不变（仍然是逐条读 dispelName 的精确判定）。
- 夹具：E24-E27（secret 长度仍判有新增 / n=ERR 判未知 / 无负载判无新增 /
  增益 verdict=false 不亮）+ E8g/E8h 静态；圣骑士全量 0 失败，Lua 语法 215/215。

【防骑】2026-11-19（修复清洁术延迟探针报错：secret 值不能参与字符串拼接）
- 用户报错：Paladin_Forever.lua:6411 invalid value (secret) at index 5 for 'concat'。
- 根因：本服 UNIT_AURA 的 updateInfo.isFullUpdate 本身就是 secret，`..` 拼接会把
  secret 传染给整条字符串，table.concat 直接抛错，整次探针输出丢失。
- 修复：探针内所有值先过 ss()（secret → "SECRET"，tostring 失败 → "ERR"）；
  table.concat 再包一层 pcall，失败时逐条打印兜底。
- 同批实测结论（用户 05:37 完整输出）：C_UnitAuras 三条接口全 ERR、C_Timer 独立帧
  同样被拒、AuraUtil.ForEachAura 抛错、UnitDebuff 类型名直查全部 nil、负载
  addedAuras 为 nil —— 战斗内光环数据对插件完全封闭，精确判定在技术上不可行。

【防骑】2026-11-19（战斗中清洁术：新增「UnitDebuff 类型名直查」通道 + 延迟探针扩测）
- 真机 05:37 实证（用户完整诊断）：player/target 两侧 C_UnitAuras 三条接口全 ERR，
  连 C_Timer(0) 独立执行帧的延迟探针也同样被拒 —— 说明 taint 是**整个插件**级别的，
  不存在「换个执行时机就能读」；EUI IsShown 全拒、tooltip 通道全 nil、
  GetPlayerAuraBySpellID(23380) 返回 nil（ID 是秘密，白名单也没救）。
- 结论：战斗内「读光环数据」这条路在本服彻底封死，只剩「不读数据的 API」可用。
- 新增通道：WR_PaladinForever_UnitDebuffByDispelKind —— 经典的 UnitDebuff(unit, index)
  允许 index 传字符串（"Magic"/"Poison"/"Disease"/"魔法"/"中毒"/"疾病"），
  它只回答「有没有这类减益」，不返回光环字段，正好绕开 secret。
  · 只认肯定证据：返回 table/userdata → 有；返回 nil → 未知（绝不判无）；
  · 兼容包装返回 0/false 等占位值不算命中（防止战斗中恒亮误驱）。
  已接入 UnitHasDispel，位于 ID 直查之后、tooltip 扫描之前。
- 诊断①：新增「ID直查API=true/false」（区分 API 缺失与 ID 秘密）、「类型直查=true/false/nil」。
- 诊断②：延迟探针扩测「UnitDebuff 类型名」与「UNIT_AURA 负载内部」
  （payload.next 用 next 枚举绕开 secret 长度、payload[1] 的 isHelpful/dispelName、
  payload.full），用来回答「负载到底能不能做精确过滤」。
- 夹具：test_paladin_cleanse_eui_buttons.py 新增 D1-D5（英文/中文类型名命中 /
  全 nil→false / 占位 0 不算 / 全被拒→nil）；全量 Lua 语法 215/215。

【防骑】2026-11-19（战斗中清洁术：补录「投石 23380」魔法 debuff）
- 用户反馈+截图：「投石 · 法术ID 23380 · 魔法 · 剩余5秒」（每3秒一次奥术伤害），
  战斗中防骑不驱散。
- 根因：战斗内读光环字段的通道全部被 secret 拒绝，唯一免读回的
  C_UnitAuras.GetPlayerAuraBySpellID 只遍历「已知ID白名单 + 运行时已发现表」，
  而 23380 两处都没有 → ID 直查 miss → 全链 unknown → 不亮。
- 修复：白名单补 [23380]="magic"；名称白名单补「投石」=magic
  （脱战/可读时由名字通道喂进已发现表，之后战斗内也能自动覆盖）。
- 夹具：test_paladin_cleanse_spellid_channel.py 新增 S9a-S9d（白名单值 / 名称判型 /
  免读回 ID 直查命中 / UnitHasDispel 端到端）；全量 Lua 语法 215/215。

【防骑】2026-11-19（战斗中清洁术：负载不可读时不再瞎猜，宁可暂时不亮也不乱驱）
- 用户反馈（03:38）：战斗中没有魔法/疾病/中毒等 debuff 时也会使用清洁术。
  诊断给出关键一行：光环负载=nil/targettarget@0.2s —— 即 updateInfo.addedAuras
  在本服可能整块不可读；而上一版对「负载不可读」保留了「退回任意光环变化」的兜底，
  于是开战时的增益刷新、场景切换、以及 targettarget 的负载变化都会点亮清洁术。
- 修复①：删除「负载不可读 → 视作有减益」的兜底。现在只有负载被明确判定为
  魔法/中毒/疾病时才记录触发时刻（WR_PaladinForever_AuraHarmfulAt）；
  增益、诅咒、流血、不可驱散减益、负载不可读，一律不点亮。
- 修复②：WR_PaladinForever_AuraPayloadLast 改为按单位存储 { v, shape, at }，
  避免最后一条事件（常在 targettarget 上）覆盖掉 player/target 的真实判定。
- 诊断①：「光环负载=」改为按当前单位读取，并输出 shape（形如 n=1/h=false/d=Poison、
  add=nil、n=0/full、add=ERR），可直接看出本服负载到底可不可读、读到什么形状。
- 诊断②：新增「[清洁术延迟探针]」——用 C_Timer.After(0) 在独立执行帧里重试
  GetAuraSlots / GetAuraDataByIndex / AuraUtil.ForEachAura。
  本服报错原文含「while tainted by 'MKHelperForever'」，据此验证 taint 是否只作用于
  当前执行路径：能读到 slot 数 → 后续可做精确定时轮询；仍被拒 → 只能靠负载判定。
- 口径：宁可战斗内暂时不亮（用户当前症状是误亮），也不乱驱。
- 夹具：test_paladin_cleanse_eui_buttons.py 更新为 E9/E10 只认 AuraHarmfulAt，
  新增 E21（仅光环变化不点亮，03:38 回归）、E22/E23（shape 形态）、E8d/E8e/E8f 静态；
  圣骑士 68 个夹具 0 失败，全量 Lua 语法 215/215。

【防骑】2026-11-19（战斗中清洁术：按 UNIT_AURA 负载过滤，增益/不可驱散减益不再点亮）
- 用户反馈（02:45）：「发霉的书籍陷阱」17134（不可驱散，只减移动速度/延长攻击间隔）也亮了清洁术。
  原因是上一版把「任何光环变化」都当成有减益——UNIT_AURA 增益刷新、不可驱散减益也会触发。
- 修复：监听 UNIT_AURA 时解析新增光环负载（updateInfo.addedAuras）：
  · isHelpful=true（增益）→ 无关；
  · dispelName 为魔法/中毒/疾病 → 与清洁术相关，点亮；
  · dispelName 为诅咒/流血或明确为空（如陷阱类无驱散类型）→ 无关，不点亮；
  · 全量刷新（isFullUpdate）→ 不据此点亮，避免每次开战空按一次；
  · 负载整体不可读（字段 secret/拿不到）→ 才退回上一版「任意变化」口径，保证战斗中不哑火。
- 「负载可读」按单位记忆一次：一旦读过真实负载，该单位就不再退回「任意变化」。
- 诊断：新增「光环负载=true/false/nil/单位/秒数」，可直接看到本轮事件被判成哪一类。
- 夹具：test_paladin_cleanse_eui_buttons.py 扩到 E1-E20 共 22 条（中毒相关 / 魔法增益无关 /
  陷阱类减益无关 / 诅咒无关 / 空列表未知 / 全量刷新无关 / 无负载未知 / 可读后不退回);
  圣骑士 68 个夹具 0 失败，全量 Lua 语法 215/215。

【防骑】2026-11-19（战斗中清洁术：按钮可见性也是 secret → 改用 UNIT_AURA 事件作为存在性信号）
- 真机证据（/FH_QJS_DEBUG，02:41）：EUI按钮=减益740/全1110（记录成功），但 EUI可见=false(0枚)，
  IsShown 780 次全部被拒。EUI 源码注释原文：「its shown state is secret even out of restriction」
  —— 12.x 里光环按钮的显示状态本身是 secret，插件读不到。C_UnitAuras 三条接口依旧全 ERR。
  结论：本服战斗内任何「光环/按钮状态」都不可读，插件侧只剩事件。
- 修复：新增 UNIT_AURA 监听（player/target/…按单位记录时刻与计数）。受限战斗里，
  该单位 3 秒内发生过光环变化 → 视为「可能有减益」→ 允许点亮清洁术（8 秒 CD 限流）。
  窗口 3 秒 = 覆盖一次 1.5 秒色块保持 + 一次重试，避免 AHK 漏看一次就整场不驱。
- 边界：只在 WR_PaladinForever_AurasRestricted() 为真（受限战斗）时采信；脱战一律走类型精确判定，
  诅咒/流血绝不误放。代价：战斗内增益刷新也会触发一次提示（用户已确认接受「有减益就提示」口径）。
- 性能：EUI 按钮存在性探测加 5 秒熔断 —— 一旦发现所有 IsShown 都被拒，5 秒内不再对几百枚按钮做 pcall。
- 诊断：新增「光环事件=N@Xs」+「EUI可见=false(读成功/尝试)」。
  若真机「光环事件」计数一直为 0，说明本服连 UNIT_AURA 都不派发给插件，那就只能改为
  「战斗中每 8 秒无条件提示一次」，届时按该口径再改。
- 夹具：test_paladin_cleanse_eui_buttons.py 扩到 E1-E11 共 13 条（事件窗口采信 / 过期不采信 /
  非受限不采信）；圣骑士 68 个夹具 0 失败，全量 Lua 语法 215/215。

【防骑】2026-11-19（战斗中清洁术：EUI 光环按钮存在性通道——旧钩子漏了 unit frame 的减益组）
- 真机证据（/FH_QJS_DEBUG，02:29）：EUI减益容器=true，但「任意减益=false」「多API扫描=nil」；
  C_UnitAuras 三条读接口全部 ERR[Auras cannot be accessed when secret while tainted by 'MKHelperForever']，
  UnitAura=noAPI、UnitDebuff存在=0。结论：战斗内读光环字段这条路在本服对本插件是关闭的。
- 根因（本轮定位）：旧 EUI 桥接只包 group.extraInit。但 EUI 的 unit frame 光环组
  （EUI_UnitFrames_AuraContainers.lua 的 DeclareElementGroup）根本不传 extraInit，
  于是整组按钮一枚都没被记录 → 存在性扫描永远扫不到 → 退化通道恒 false。
- 修复：改挂 EllesmereUI.AuraKit.MakeInitializer（每组每枚按钮、包括延迟池化创建的都会经过它），
  并在 AddGroupToContainer 里给按钮打上「容器 / 单位（container.unit）/ 是否减益组（filter 含 HARMFUL）」；
  新增 WR_PaladinForever_EUI_HarmfulPresence(unit)：只读按钮 IsShown 布尔（非 secret），
  有显示中的减益按钮 = 该单位有减益；只有增益组按钮时不参与（绝不把 Buff 当减益）。
- 接线：WR_PaladinForever_UnitHasAnyHarmful 的 EUI 分支改用上面的按钮记录（player/target 都覆盖），
  仍然只在 WR_PaladinForever_AurasRestricted() 为真（受限战斗）时由 UnitHasDispel 采信；
  脱战仍走类型精确判定，诅咒/流血不会误放。
- 诊断：新增「EUI按钮=减益N/全N」「EUI可见=true(N枚)」「任意减益(循环)=v@Xs」，
  可区分「循环路径读不到」与「斜杠命令（taint 上下文）读不到」——这是本轮最关键的新证据点。
- 夹具：新增 test_paladin_cleanse_eui_buttons.py（E1-E8 共 10 条：两组按钮记录 / 可见即 true /
  全隐藏 false / 增益组不算 / player-target 单位隔离 / 受限战斗端到端 true+false / 静态接线）；
  圣骑士夹具 68 个文件 0 失败，全量 Lua 语法 215/215。

【防骑】2026-11-19（战斗中清洁术：确认本服光环不可读 → 按用户口径「有减益就提示」）
- 真机实证（/FH_QJS_DEBUG，02:01，战斗中有 debuff 时执行）：player/target 两侧
  probe判定 / 暴雪DebuffFrame / 多API扫描 / ID分类 / ID直查 / 严格探针 / 提示扫描 / 悬停提示 全 = nil；
  UnitAura=noAPI、UnitDebuff存在=0、C_UnitAuras.GetAuraDataByIndex 无数据、GameTooltip 存在但读不出。
  结论：本服战斗内光环数据对插件完全不可见，任何「读类型」的通道都不可能工作。
- 用户选择：战斗中退化为「有减益就提示」。
- 修复：新增 WR_PaladinForever_UnitHasAnyHarmful(unit) —— 只判存在性、不读任何字段：
  ① AuraUtil.ForEachAura("HARMFUL") 回调被调用即视为有减益（secret 字段原样传回但不读）；
  ② EUI 减益按钮容器里存在显示中的按钮（仅 player）；
  ③ UnitDebuff(unit,1,"HARMFUL") 存在性（脱战兜底）。
  在 UnitHasDispel 的「严格探针判无」之后、AurasRestricted 兜底之前接入，且只在
  WR_PaladinForever_AurasRestricted() 为真时启用 —— 脱战仍按类型精确判定，诅咒/流血不误放。
- 代价（用户已确认接受）：战斗中中诅咒/流血时也会点亮清洁术空按一次（8 秒 CD 限流）。
- 诊断新增：任意减益= / ForEachAura= / EUI减益容器= / AuraData(HARMFUL|RAID)= / AuraSlots(RAID)= / 战斗中=；
  并把「本地CD中」改用 DbgFmt（此前只显示 err，看不到错误原文）。
- 夹具：扩展 test_paladin_cleanse_presence_filter.py（R1-R6：ForEachAura 三态 / 受限退化放行 / 非受限不污染 / 接线顺序）；
  test_paladin_cleanse_combat.py 的 J28 按新口径更新为「受限战斗类型不可读 → 退化放行」，J29/J30 仍保证严格探针说无时不放行。
  圣骑士夹具 67 个文件 0 失败，全量 Lua 语法 215/215。

【防骑】2026-11-19（诊断升级：区分「返回 nil」与「调用抛错」+ 新增纯存在性探针）
- 用户实测（/FH_QJS_DEBUG）：player/target 两行所有通道全显示 err，secret=true，最终=false。
  但旧诊断把 `pcall 成功且返回 nil` 与 `调用抛错` 都打成 "err"，看不出到底是「读不到（未知）」还是「接口炸了」。
- 诊断①：新增 WR_PaladinForever_DbgFmt —— 返回 nil 直接显示 nil，抛错显示 ERR[错误原文]，两者不再混淆。
- 诊断②：新增纯存在性探针（不读任何字段）：UnitDebuff存在 / UnitAura存在（HARMFUL）+ 驱散过滤器存在（RAID）
  + presence判定。用途：确认受限战斗里光环到底还能不能看到，以及本服 RAID 过滤（= 我能驱散的减益）是否有效。
- 诊断③：新增「提示窗口=/可用=/本地CD中=」，配合上一版保护窗口，可直接区分「根本没判定出来」与「亮了被顶掉」。
- 说明：上一版清洁术保护窗口 + 今晚这次诊断都要求客户端重新加载（/reload 或重进游戏）才生效；
  用户这次贴出的输出里没有「提示窗口=」字段，说明跑的还是旧版本。
- 纯存在性探针**不参与判定**（历史事故 H4/J28：按存在性放行会把诅咒也点亮）。待真机确认
  「只中诅咒时 驱散过滤器存在=0」后再决定是否接线；两条 UnitAura/UnitDebuff 的过滤令牌写法不同
  （UnitAura 用 HARMFUL|RAID，UnitDebuff 兼容包装只给 RAID），诊断里已按此区分。
- 夹具：新增 test_paladin_cleanse_presence_filter.py（Q1-Q7 共 10 条）；圣骑士夹具 67 个文件 0 失败，全量 Lua 语法 215/215。

【防骑】2026-11-19（战斗中清洁术不生效、脱战正常：色块被其它技能顶掉 → 新增清洁术提示保护窗口）
- 用户口径：脱战能正常驱散中毒/疾病/魔法，战斗里一次都不驱（前面几轮全都在查「类型判定」，方向偏了）。
- 根因（与类型判定无关，是色块竞争）：WR_ColorFrame_ShowSkill 每次点亮前会先隐藏【所有】色块；而 ShowSkillCD 点亮一次后按 cd=8 → guard=PROMPT_HOLD(1.5 秒)，
  这 1.5 秒内后续调用直接 return false（不再重亮）。战斗中几乎每 tick 都有 审判/神圣打击/奉献/圣印/打断 的色块把 43/44/59 顶掉 →
  清洁术色块只存在不到 0.1 秒，AHK（约 60ms 一扫）读不到 → 永不按键。脱战没有任何提示竞争，色块一直亮 → 三种类型都能正常驱散。
  这与 11-14 用户提过的「圣印经常被顶」是同一类 bug（圣印/正义之怒已用保护窗口修好），清洁术是第三处遗漏。
- 修复①（主）：新增清洁术提示保护窗口 WR_PaladinForever_CLEANSE_PROMPT_HOLD=1.2 秒。CleanseStep.tryUnit 点亮成功后 ArmCleansePrompt(alias, slot, unit)；
  防骑循环最前（正义之怒之后、圣印保护之前）调用 WR_PaladinForever_RefreshCleansePrompt()：窗口内每 tick 重亮同一色块并 return true，
  确保 AHK 必然读到；施放成功（本地 8 秒记账生效）/ 单位已无可驱散（每 0.3 秒复查）/ 可用性失效 / 窗口到期 → 立即 HideNow 收窗口。
- 修复②（加固）：ScanUnitDebuffTypes 的 EUI 图集 false 只在非受限上下文采信——受限战斗里 EUI 的 DebuffBorder 可能整段不刷新，
  旧写法一个假 false 就一票否决后面的白名单/静态分类/tooltip 通道。
- 接线：防骑在正义之怒之后、圣印保护之前接入该窗口；惩戒 Ret 循环顶部同样调用（带 nil 守卫）；不改类型判定、白名单、CanCleanseCast，也不改 WR_ColorFrame_ShowSkill 本身。
- 诊断：/FH_QJS_DEBUG 新增「提示窗口=/可用=/本地CD中=」，战斗中可直接区分「没判定出来」与「亮了被顶掉」。
- 夹具：新增 test_paladin_cleanse_prompt_hold.py（P1-P8 共 15 条：窗口重亮 / 单位转不可驱散即收窗 / 已施放即收窗 / 到期收窗 / 诅咒不 arm / Prot 接线顺序 / 惩戒接线 / tryUnit 静态）；圣骑士夹具 66 个文件 0 失败，全量 Lua 语法 215/215。

【防骑】2026-11-19（诊断命令 /FH_QJS_DEBUG 一直无效：SLASH_ 键名与 SlashCmdList 键名错配）
- 用户口径：按提示输入 /FH_QJS_DEBUG，聊天框只回「输入 '/help' 以获得命令列表」，诊断一条都没打出来。
- 根因（注册期就错，与清洁术判定链无关）：客户端注册斜杠命令的规则是 SlashCmdList 的键 K 必须与 SLASH_<K><N> 里的 K 完全一致。旧代码写的是
  `SLASH_FHQJSDBG1 = "/FH_QJS_DEBUG"` 配 `SlashCmdList["FH_QJS_DEBUG"] = function() ... end`——
  前者定义出的键是 "FHQJSDBG"，后者注册在 "FH_QJS_DEBUG" 下，两边键名不相等，客户端认为该命令从未注册，
  于是 11-17 加进来到现在一直打不出任何东西（中间几轮真机排查全靠它，全都拿不到输出）。
- 修复：改为 `SLASH_FH_QJS_DEBUG1 = "/FH_QJS_DEBUG"`，与 SlashCmdList["FH_QJS_DEBUG"] 严格对齐；命令体不变，仍 pcall 包住 WR_PaladinForever_CleanseDebugReport。
- 顺带全仓审计：对全部 lua 文件做 SLASH_<K><N> ↔ SlashCmdList[K] 双向配对检查，修复后 0 错配（此前仅此一处单向孤儿）；/FH_QX_DEBUG、/mkpal、/FH_SEAL 等其它诊断命令均正常。
- 夹具：新增 test_paladin_slash_cmd_registration.py（K0-K5 共 9 条：双向配对静态审计 / SLASH 变量值 / SlashCmdList 函数存在 / 调用后真的执行到诊断报告 / 其它诊断命令未受影响）。圣骑士夹具全绿，全量 Lua 语法 216/216。

【防骑】2026-11-19（清洁术漏驱「烈焰震击」23038 六次修复：GameTooltip 直读 + 名称白名单 + 多候选扫描 + 保持期）
- 用户口径：防骑战斗中依旧没有驱散烈焰震击（截图实锤：烈焰震击 · 法术ID 23038 · 魔法 · 每3秒受到一次火焰伤害 · 剩余6秒）。前几轮已把 23038 写进白名单，真机仍不驱。
- 根因（六处结构性缺口，白名单从来不是瓶颈）：
  ① CleanseTooltipScan 的候选函数写成 `A or B or C`——只取第一个**存在**的函数。该函数存在但签名/上下文不对时整条 tooltip 通道永久哑火，后面的 GetUnitAura/GetUnitAuraByIndex 根本没机会跑；
  ② 每次重扫都先 `cacheMap[unit] = nil`——受限内容里 tooltip 数据流逐帧放行/拒绝，一旦这一帧被拒，上一帧刚确认的 true 立刻丢失 → 色块灭 → AHK 不按 → 玩家看到「一直不驱」；
  ③ 类型判定只认「短词类型行 / 法术ID 行 / 顶层 id」，没有用**名称**——用户截图里「烈焰震击」这行名字是可读的，而「魔法」类型行常因颜色码/并排布局读不出；
  ④ C_TooltipInfo 返回的是数据表，受限内容里可能整条被拒；而用户截图的形态本身就是 **GameTooltip 鼠标悬停提示**——引擎 C 侧写进字体串的普通文本，本仓库 PartyMemberFrame.lua 366 同款用法，此前完全没用；
  ⑤ CanCleanseCast 用 `WR_SpellUsable("清洁术", true)`，第三道门 ≈「审判剩余 CD ≤ 0.3 秒」→ 约 90% 时间恒 false（GX 已记录同款四处：打断滑条/全局保护/圣疗/圣佑，这是第五处残留），可用性主通道长期空转；
  ⑥ 曾尝试用 `GetAuraDataByIndex(unit, 1, "HARMFUL|Magic")` 做类型令牌探针——**已回退**：本服 filter 只认 HARMFUL/HELPFUL/RAID 等标准令牌，类型部分被忽略 → 等价裸 HARMFUL → 中诅咒也点亮清洁术（GX 已有同款事故记录）。
- 修复①（GameTooltip 直读，最强通道）：新增 WR_PaladinForever_ProbeByGameTooltip——复用**已存在的 GameTooltip**（不 CreateFrame、不建模板帧，EUI 禁止的只是后者）：SetOwner(UIParent,"ANCHOR_NONE") → 逐槽 SetUnitDebuff(unit,i) → 读 GameTooltipTextLeftN/RightN 的 GetText() 普通字符串 → 短词类型行 / 名称白名单 / 「法术ID：N」行三条证据判型。读完立即 Hide。守卫：玩家自己正开着 tooltip（IsShown 且非我们 owner）→ 本帧完全不动它；被拒记 3 秒冷却；0.5 秒节流。
- 修复②（名称白名单）：新增 CLEANSE_KNOWN_AURA_NAMES + WR_PaladinForever_KindFromAuraName——受限内容里 name 通常不是 secret（用户截图可证），名字命中即判型。只收录清洁术确实能驱散的毒/病/魔法，诅咒类绝不收录。三条 tooltip 通道（KindFromTooltipData / ScanUnitDebuffTypes / GameTooltip）全部接入。
- 修复③（多候选扫描）：CleanseTooltipScan 候选改为「全部收集 + 逐个尝试」（GetUnitDebuffByIndex / GetUnitDebuff / GetUnitAuraByIndex / GetUnitAura + HARMFUL 变体），某条抛错只跳过它自己，全部候选都被拒才记 denied（2.5 秒）。
- 修复④（true 保持期）：节流 0.5 → 0.2 秒，并新增 CleanseTooltipScanHoldAt——明确读到可驱散后 1.5 秒内即使重扫被拒也继续判 true（与色块保持窗口同量级），杜绝「一帧读不到就整段不驱」。
- 修复⑤（可用性门）：CanCleanseCast 去掉 GlobalCooldown=true 的严格 GCD 门，只查技能自身冷却；公共冷却由 ShowSkillCD 防抖 + 本地 8 秒施放记账兜住。
- 修复⑥（诊断）：/FH_QJS_DEBUG 新增「提示扫描=」「悬停提示=」两段，可直接看到这两条通道在真机上的返回值。
- 夹具：新增 test_paladin_cleanse_flame_shock_e2e.py（N1-N8 共 10 条：名称白名单 / 只有名字行可读 / 多候选容错 / 保持期 / GameTooltip 直读 / 玩家占用让路 / 主循环端到端仅靠 GameTooltip 点亮 43 清洁术(自己) / 诅咒不误放）；同步 test_paladin_cleanse_fury_shock.py（诅咒用例名字改「痛苦诅咒」，与真机形态一致）、test_paladin_cleanse_fourth_channels.py（T15 节流 0.2 秒）、test_paladin_cleanse_saliva.py（T14 静态断言改为多候选形态）。圣骑士全部夹具 67 个文件 0 失败，全量 Lua 语法 216/216。

【防骑】2026-11-19（清洁术漏驱「毒性唾液」7125：白名单补录 + 静态法术类型通道 + 已发现 ID 记忆闭环）
- 用户口径：防骑战斗中这个中毒（毒性唾液 · 法术ID 7125 · 中毒 · 每6秒造成17点自然伤害、每6秒吸取20点法力值 · 剩余2分钟）没有使用清洁术驱散。
- 根因（结构性，不是单点漏 ID）：
  ① 白名单是「截图补录制」——本服中毒 ID 彼此毫无关联（744 / 13298 / 5416 / 7125），每遇到一个新怪就再漏一次；7125 从未进表 → ID 直查与 ID 分类两条免读回通道全 miss。
  ② KindFromShortText 拿**带颜色码的原串**判「≤8 字」——「|cff1eff00中毒|r」有 15 个字符，直接被长度门挡掉 → 类型行明明可读却判不出类型。
  ③ 静态法术提示分类（GetSpellByID）只看短词行，没有「法术ID: N」行与顶层 id 两条证据 → 静态数据这条路对未录入 ID 同样落空。
  ④ 免读回的 ID 直查通道只遍历白名单——未录入的 ID 永远轮不到它，等于把「本场没录入 = 整场不驱」写死。
  ⑤ CleanseTooltipScan 槽位上限只有 20——boss 战 debuff 超过 20 条时排在后面的毒被整条截断。
- 修复①（白名单）：补 [7125] = "poison"（毒性唾液，2026-11-19 用户截图实锤）。
- 修复②（短词分类加固）：KindFromShortText 先剥离 |cAARRGGBB 颜色码 / |r / |t 再判长度，长度门 8 → 12 并去首尾空白——带颜色码的类型行不再被长度门挡掉。
- 修复③（静态法术类型通道）：新增 WR_PaladinForever_StaticSpellDispelKind —— C_Spell.GetSpellDispelType 与 C_Spell.GetSpellInfo().dispelType 都是按 spellID 查的**静态数据**，与「光环是否 secret / 是否在战斗」完全无关；任一可读即得类型，两个都缺则返回 nil（不猜）。DispKindBySpellID 在白名单之后先走它。
- 修复④（已发现 ID 记忆闭环，终结「截图补 ID」）：新增 WR_PaladinForever_CLEANSE_DISCOVERED_IDS + RememberCleansableID（上限 200 条）。任何时刻被判过型（静态数据 / 静态提示 / tooltip 类型行 / tooltip 法术ID 行 / 顶层 id）的 ID 都会入库，PlayerAuraIDHasDispellable 的免读回直查同时遍历白名单与发现表——判过一次型的 ID，下一场战斗自动被覆盖，不必再等截图。
- 修复⑤（tooltip 通道）：KindFromTooltipData 的「法术ID」分支加静态数据兜底并入库；短词行与顶层 id 命中点也补记忆（旧版短词命中直接返回，是最常见的断链点）；CleanseTooltipScan 槽位上限 20 → 40、兼容序补 GetUnitAuraByIndex。
- 夹具：新增 .workbuddy/test_paladin_cleanse_saliva.py（T1-T14 共 19 条：白名单 / 静态通道两 API / 双 API 缺失不猜 / 抛错降级 / 颜色码剥离 / 未录入 ID 判型入库 / 发现表免读回直查 / tooltip 法术ID 行 / 槽位 25 不截断 / 全链 / 诅咒不误放 / 静态接线）与 .workbuddy/test_paladin_cleanse_saliva_loop.py（L1-L5 端到端：真跑 WR_PaladinForeverProt，在「光环全 secret + C_UnitAuras 抛错 + 探测容器为空」的战斗里仅靠提示数据流点亮 43 清洁术(自己)，并验证诅咒不亮、未录入 ID 仍亮、发现表闭环）。圣骑士全部夹具 64 个文件 0 失败，全量 Lua 语法 216/216。

【防骑】2026-11-19（正义之怒提到第一优先级 + tooltip 通道确认缺失，buff 一消失立刻补）
- 用户口径：防骑正义之怒要第一优先级，buff 一消失第一时间就要补。
- 根因链（两层）：
  ① 优先级：补 Buff 段虽在 11-18 提到「圣印提示保护窗口之后」，但该窗口每 tick 都会 return true，窗口一开正义之怒整段被吃掉，等窗口结束才轮到它 → 感知「buff 没了不补」。现整段移到循环【第一条】（ClearStalePrompts 之后、圣印窗口之前）。
  ② 判定：战斗中 ① HELPFUL 光环扫描（name/spellId 是 secret → 整条未知）与 ② C_UnitAuras.GetPlayerAuraBySpellID（非白名单 ID 被秘密旗挡住返回 nil，只有「本场战斗曾读到过」之后 nil 才可信）双双返回未知时，只剩 ④「30 分钟施放成功记录」硬撑 → 被驱散 / 战复 / 竞技场重置 / 跨场景后 Buff 真没了却判「仍在」，整场不补。
- 修复①（判定）：新增 WR_PaladinForever_FuryByTooltip —— C_TooltipInfo 提示数据流直查（GetUnitBuffByIndex → GetUnitBuff → GetUnitAuraByIndex 兼容序）。引擎 C 侧组装 tooltip 数据，不受 DenyTaintedAccessWhenAurasAreSecret 限制（与清洁术 GetUnitDebuffByIndex 同一实证：!Pig Tooltip.lua 321 / PartyMemberFrame.lua 366）。逐槽位读玩家 HELPFUL：顶层 data.id == 25780 或提示行「法术ID: 25780」→ 明确在身；扫到空槽位且全程无未知 → 明确不在；出现读不到的格子 / 调用被拒 → 未知。**绝不用未知判缺失**，否则每次点亮后都判「没打上」→ AHK 连按（老的「反复施放正义之怒」）。0.5 秒节流。
- 修复②（防连按）：tooltip 判「不在」加 3 秒施放宽限 —— 刚成功施放 3 秒内光环可能还没同步，此时判缺失会让色块反复点亮。宽限内按未知处理，交回 30 分钟记录兜底。
- 修复③（优先级）：整段移到 WR_PaladinForeverProt 最前；点亮改走新的 WR_PaladinForever_ShowFuryPrompt（单次点亮，不学圣印做「窗口内每 tick 重亮」—— 正义之怒现在没有任何分支能顶掉它，重亮等于色块常亮 = AHK 每 60ms 连按）。
- 修复④（健壮性）：FuryUp 的 WR_GetUnitBuffTime、循环里的 WR_SpellUsable 都改为 nil 守卫（~= nil，不用 type=="function"——离线夹具/部分客户端把 C API 暴露成可调用 userdata）。裸调抛错会被防骑看门狗吞掉，表现为整 tick 无提示。
- 修复⑤（缓存一致性）：施放成功事件（按名 / 按 spellID 25780）与 PLAYER_DEAD 都清空 FuryTooltipAt / FuryTooltipCache，避免施放前那一帧「明确不在」的缓存压住刚打上的 Buff。
- 夹具：新增 .workbuddy/test_paladin_fury_priority.py（T1-T10 共 20 条：顶层 id 命中 / 明确不在清账 / 被拒不误判 / 未知不判缺失 / 「法术ID」行反查 / 施放宽限 / 0.5 秒节流 / 事件清缓存 / 循环第一条静态检查）；test_paladin_fury_reprompt.py 25/25、test_paladin_fury_refill.py 13/13；圣骑士全部夹具回归 0 失败，全量 Lua 语法 216/216。

【防骑】2026-11-19（清洁术漏驱「脆弱」12530：白名单补录 + tooltip 三证据分类 + 诅咒不再提前否决）
- 用户口径：防骑战斗中没有使用清洁术驱散「脆弱」这个 buff（截图实锤：脆弱 · 法术ID 12530 · 魔法 · 剩余 57 秒 · 所有属性降低10点）。
- 根因链（三处叠加）：
  ① CLEANSE_KNOWN_AURA_IDS 白名单没有 12530 → UnitAuraIDHasDispellable 与 PlayerAuraIDHasDispellable 两条 ID 通道全 miss；
  ② 受限内容里 tooltip 顶层 data.id 也可能是 secret（EUI AuraBuffReminders NON_SECRET_SPELL_IDS 策略实证）→ CleanseTooltipScan 的「顶层 id 查白名单」整条落空；
  ③ CleanseTooltipScan 只认 leftText/rightText **精确等于**「中毒/疾病/魔法」，且一旦在某个槽位读到诅咒就提前 return false —— 「诅咒 + 魔法」并存时，排在诅咒后面的魔法整条被漏掉。截图里的「法术ID：12530」行旧实现完全没利用。
- 修复①：白名单补 [12530] = "magic"（脆弱，所有属性降低10点），ID 直查 / ID 分类两条通道立即命中。
- 修复②：新增 WR_PaladinForever_KindFromShortText（只接受 ≤8 字的类型行，短行包含「中毒/疾病/魔法/诅咒/流血」即判定；长描述行「所有属性降低10点」不参与，杜绝「魔法伤害」误判）。
- 修复③：新增 WR_PaladinForever_SpellIDFromTooltipLines —— 抓 tooltip 里的「法术ID / Spell ID」行取数字，再走白名单 + C_TooltipInfo.GetSpellByID 静态分类；顶层 data.id secret 时仍有证据。
- 修复④：新增 WR_PaladinForever_KindFromTooltipData（短词 → 法术ID 行 → 顶层 id 三段证据，顺序敏感：诅咒/流血先判）。CleanseTooltipScan 与 UnitAuraIDHasDispellable 的 tooltip 源统一改走它。
- 修复⑤：CleanseTooltipScan 的诅咒/流血改为只记账，**绝不提前 return false**；只有「每条都读得懂且全不可清洁」才判无，含未知一律 nil（与 UnitHasDispel 其余通道同口径）。
- 修复⑥：KindFromSpellTooltip（静态法术提示分类）精确等值 → 短词包含，静态提示行的颜色码/空白不再导致分类 miss。
- 夹具：新增 .workbuddy/test_paladin_cleanse_fragile.py（F1-F9 共 21 条，含白名单、短词分类边界、法术ID行反查、截图行形态、顶层 id secret、UnitHasDispel 全链、槽位1诅咒+槽位2魔法、只诅咒不误放、静态接线）；清洁术全套 10 个夹具全绿，全量 Lua 语法 216/216。

【防骑】2026-11-19（减速术/烈焰震击连续漏驱：spellId 双来源 + CleanseTooltipScan 全单位化）
- 用户口径：减速术 11436（截图实锤 11436·魔法·剩余6秒）、烈焰震击 23038 战斗里都不亮清洁术。
- 根因链（三层叠加）：
  ① CLEANSE_KNOWN_AURA_IDS 白名单没有 11436（减速术）/13173/23100（减速术全 rank）+ 23038/23062/23063（烈焰震击）/ 寒冰箭减速 7322/8376 / 奥术减速 3604 / 羊/冰环/恐惧类 → UnitAuraIDHasDispellable 里 auraData.spellId 可读时走白名单直接命中这条通道完全废掉；
  ② auraData.spellId 在战斗里也被 secret 挡住（EllesmereUIAuraBuffReminders NON_SECRET_SPELL_IDS 实证）→ UnitAuraIDHasDispellable 里 `WR_PaladinForever_IsSecretValue(sid)` 过滤掉 → 走不到 DispKindBySpellID 的 C_TooltipInfo.GetSpellByID 静态提示分类 → sawUnknown=true → 返回 nil；
  ③ CleanseTooltipScan 只对 player 开放（`if unit ~= "player" then return nil end`）→ target/party/mouseover 的 debuff 即使 C_TooltipInfo 能读到也被拒之门外；节流是全局一个 map，改多单位前也无法并行。
- 修复① 白名单补全：减速术全 rank（11436/13173/23100）+ 寒冰箭减速（7322/8376）+ 奥术减速（3604）+ 羊/冰环/恐惧类（28271 变形乌龟 / 3355 冰冻陷阱 / 12654 冰霜新星）。让 auraData.spellId 非 secret 时直接命中白名单，不走静态提示。
- 修复② spellId 双来源（UnitAuraIDHasDispellable）：auraData.spellId secret 时并行用 C_TooltipInfo.GetUnitDebuffByIndex(unit, i) 拿 data.id——tooltip 引擎组装的数据不受 DenyTaintedAccessWhenAurasAreSecret 限制（EllesmereUIAuraBuffReminders data.id 同源）。两个来源同索引位，一个 secret 另一个可能可读。
- 修复③ CleanseTooltipScan 全单位化：去掉 `if unit ~= "player"` 限制，UnitHasDispel 里 CleanseTooltipScan 从 `if unit == "player"` 块里提到外面，所有单位都能走 tooltip data.id 白名单 + 行文本「中毒/疾病/魔法」扫描。节流从全局变量改成 per-unit map（CleanseTooltipScanAt/Cache/Denied/RetryAt 都是 `{[unit]=...}`），player/target/party 互不干扰。
- 夹具：test_paladin_cleanse_fury_shock.py 9/9 + test_paladin_cleanse_spellid_channel.py 11/11；全量语法 215/215；圣骑士夹具全部回归。

【防骑】2026-11-19（清洁术漏驱烈焰震击 23038：白名单 + AuraDataDispelState spellId fallback）
- 用户口径：防骑在战斗中没有使用清洁术驱散烈焰震击（截图实锤：法术 ID 23038，类型=魔法，剩余 4 秒）。
- 根因链：UnitHasDispel 所有通道在战斗里都返回 unknown → AurasRestricted() 检查直接 return false。拆解：
  ① CLEANSE_KNOWN_AURA_IDS 白名单漏了 23038（烈焰震击全 rank 23038/23062/23063） → UnitAuraIDHasDispellable 这条 spellID 通道在 ② 静态提示 miss（C_TooltipInfo.GetSpellByID 10 秒冷却未过或受限）时只能返回 unknown；
  ② 更关键：ProbeDispellableByFilter（UnitHasDispel 里排在受限检查之前的主通道）内部 AuraDataDispelState 只走 dispelName/dispelType → 图集探针，**完全没走 spellId 白名单/静态分类**；战斗里 dispelName 是 secret → 图集探针 unknown → ProbeDispellableByFilter 返回 nil → UnitHasDispel 全 unknown → AurasRestricted() 为 true → 直接 return false。
- 修复①：白名单补 23038/23062/23063（烈焰震击全 rank，类型=魔法），让 UnitAuraIDHasDispellable 这条通道在任何上下文下都能命中。
- 修复②：AuraDataDispelState 新增 spellId fallback（在图集探针返回 unknown 后）：如果 data.spellId 可读（EllesmereUIAuraBuffReminders NON_SECRET_SPELL_IDS 实证：即使 dispelName 是 secret，spellId 仍可作为入口），先查 CLEANSE_KNOWN_AURA_IDS 白名单，命中按 kind 判定；再走 C_TooltipInfo.GetSpellByID 静态提示分类。命中 poison/disease/magic → true，curse/bleed → false，都不命中 → 保留图集探针返回的 unknown。
- 这样战斗里 dispelName secret 也能靠 spellId（烈焰震击 23038）命中白名单 → AuraDataDispelState 返回 true → ProbeDispellableByFilter 返回 true → UnitHasDispel 直接 return true → 清洁术点亮。
- 夹具：新增 test_paladin_cleanse_fury_shock.py（C1-C8：白名单存在性 / ProbeDispellableByFilter dispelName secret+spellId 可读 / UnitHasDispel 全链 / 诅咒类不误报 / 静态检查），9/9 通过；全量语法 215/215，圣骑士夹具全部回归。

【防骑】2026-11-19（打断滑块 FH_DD 无效修复：统一引擎 WR_GetCastProgress 先 DurationObject，再退原始时间戳；notInterruptible 位置修正）
- 用户口径：防骑设置了打断滑条后，目标施法时没有按照设置打断使用制裁之锤。
- 根因 ①（统一引擎全程用原始时间戳）：Core/InterruptController.lua WR_GetCastProgress 把 UnitCastingInfo / UnitChannelInfo 返回的 startTimeMS/endTimeMS 直接当普通 number 做算术（EllesmereUINameplates PlatePool.lua:568 同一实证注释：Forever 12.x 里这些时间戳是 secret value，C 侧拦截算术 → pcall 吞掉返回 nil → WR_ShouldInterrupt=false → InterruptStep 不亮；或直接抛 secret 比较被看门狗吞掉）。
- 根因 ②（notInterruptible 位置解包错位）：UnitCastingInfo 返回 9 个值（notInterruptible 在第 8 位），UnitChannelInfo 返回 8 个值（notInterruptible 在第 7 位，没有 castID），但 RawProgress 里两个 API 都按 9 个值统一解包 → UnitChannelInfo 的 isTradeSkill(false) 被当成 notInterruptible（永远 false），真正的 notInterruptible 被丢掉 → 引导不可打断永远判成可打断；而 UnitCastingInfo 解出来的是 spellId，永远不是 boolean → 永远跳过检查。两个根因叠加：DurationObject 路径缺失 + 原始路径位置错位 → 两种施法类型都失效。
- 修复①（统一引擎先 DurationObject）：把防骑本地 WR_PaladinForever_DurationCastPercent 的 DurationObject 路径（UnitCastingDuration/UnitChannelDuration + EvaluateElapsedPercent(CurveConstants.ScaleTo100)）下沉到 Core/InterruptController.lua，新增 WR_Interrupt_DurationProgress 优先调用；Forever 12.x 唯一安全的施法进度来源，所有职业共用。失败再退回 RawProgress（原始时间戳算术，全部 secret safe）。
- 修复②（CastGate 前置闸门 + 位置修正）：新增 WR_Interrupt_CastGate 独立解包 UnitCastingInfo 与 UnitChannelInfo，按各自正确位置（CastingInfo 9 位 / ChannelInfo 8 位）取 notInterruptible；DurationObject 路径必须先通过 CastGate（明确 name 非空 + notInterruptible=false）才取进度——宁可不打断也不浪费制裁。RawProgress 同步按正确位置重写两个 API 的解包。
- 修复③（/mkpal 打断诊断）：SlashCmdList["MKPAL"] 新增打断段，打印滑块阈值、制裁之锤是否学会、目标施法进度、技能可用、目标可命中。进游戏后 /mkpal 即可一眼看出哪条闸门拦掉了点亮。
- 夹具：新增 test_interrupt_controller.py（I1-I12：DurationObject 优先 / 退回 raw / 时间戳 secret / notInterruptible=true / name secret / 阈值比较 / UnitExists=false / notInterruptible secret / channel DurationObject / 阈值关闭 / 旧布尔兼容 / DurationObject 抛错回退）；test_paladin_interrupt_slider.py 原有 24 条全通过（R10b 引导不可打断由「解包错位永远漏过」改为「正确拦截」）；全量语法 215/215，圣骑士夹具全部回归。


【防骑】2026-11-18（正义之怒缺失「第一时间补」：判定加 GetPlayerAuraBySpellID 直查 + 提到循环最前 + 死亡清账）
- 用户口径：防骑正义之怒 buff 如果不存在了，一定要第一时间补。
- 根因①（判定误判为仍在）：FuryUp 只有「光环扫描可读」与「观测投影」两条路能确认缺失；战斗中光环字段是 secret 时整条扫描返回未知、观测投影又只在读到过剩余时间时才有效，最后只能靠 ④「30 分钟施放成功记录」硬撑。死亡/战复、被驱散、竞技场重置后 Buff 真的没了，却被判成仍在 → 整场战斗都不补。
- 修复①：新增 WR_PaladinForever_FuryByIDAura（C_UnitAuras.GetPlayerAuraBySpellID(25780) 直查，与清洁术「已知 ID 直查」同一实证），插在光环扫描之后。nil 语义按客户端真实行为区分（EUI EllesmereUIAuraBuffReminders 同源：非白名单 ID 战斗中可能被秘密旗挡住返回 nil，哪怕 Buff 还在）：
  · 非 nil → 明确在身上（到期时间可读时顺带刷新观测投影）；战斗中读到过就记下 WR_PaladinForever_FuryByIDCombatOK；
  · 脱战 nil 或「本场战斗曾明确读到过该 ID」之后的 nil → 明确不在，清空 FuryCastAt / 观测投影并返回 false，下一 tick 立即点亮；
  · 战斗中从未读到过该 ID 的 nil → 只当未知（避免满了还反复点亮连按），沿用 30 分钟兜底；
  · 光环扫描「明确扫过且没有」时也一并清空 30 分钟记账，避免 ④ 兜底把它重新判成仍在。
- 根因②（被抢占）：补 Buff 段原在 WR_PaladinForeverProt 靠后位置（清洁术/制裁/生存/祝福/圣印/审判之后），任何高优先级分支 return true 都会挤掉它。
- 修复②：整段上移到循环最前（保留圣印提示保护窗口 RefreshSealPrompt 之后），缺失即本 tick 点亮；3 秒 CanPrompt 防抖 + 成功施放 HideNow 防连按不变。
- 根因③（死亡不清账）：PLAYER_DEAD 分支只清圣印计时，FuryCastAt 仍留 30 分钟记账 → 战斗中战复后仍判「已开启」。
- 修复③：PLAYER_DEAD 同时清空 FuryCastAt / FuryLastUpAt / FuryLastUpRemain，复活后第一时间补。
- 夹具：新增 test_paladin_fury_reprompt.py（F1-F9：直查命中 / 脱战明确缺失 / 战斗中不可见不误报 / 曾可见后缺失 / 死亡清账 / API 缺失与被拒 / 扫描缺失清账 / 循环最前优先级静态检查）。

【防骑】2026-11-18（清洁术战斗中不驱散中毒五次修复：spellID → 静态驱散类型分类通道）
- 用户口径：前四次修复后，战斗中防骑依旧不会对中毒/疾病/魔法使用清洁术。
- 根因：前四条通道各有硬依赖——① 读 dispelName/dispelType（战斗内被 secret）；② 引擎 AuraButton 容器（装配/读回被拒）；③ 已知 ID 白名单（只覆盖已录入的 debuff）；④ C_TooltipInfo.GetUnitDebuffByIndex（只对 player，且依赖提示数据流）。截图里的毒/病/魔法只要不在白名单，战斗中仍全部落到 unknown → UnitHasDispel=false → 不点亮。
- 修复：新增「静态 spellID 分类」通道，绕开上述全部依赖：
  ① WR_PaladinForever_DispelKindBySpellID(spellID)：先查本文件已实锤的 CLEANSE_KNOWN_AURA_IDS，未命中则用 C_TooltipInfo.GetSpellByID 读静态法术提示行（中毒/疾病/魔法/诅咒/流血），按 spellID 缓存；读不到只记 10 秒重试、绝不缓存否定、绝不据此判「没有」。
  ② WR_PaladinForever_UnitAuraIDHasDispellable(unit)：逐条 C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL") 取 auraData.spellId 交给上面的分类器；player/target/party/mouseover 同一通道，战斗内外结果一致；只有「读到的每条都明确不可清洁」才返回 false。
- 接线：UnitHasDispel 链在 ID 直查/提示扫描之后新增该通道；ScanUnitDebuffTypes 的 consider() 在 secret dispelName 分支之前先做静态分类（命中毒/病/魔法立即 true，诅咒/流血记为不可清洁）。
- 诊断：/FH_QJS_DEBUG 新增「ID分类=」与「aura列表=spellID=类型」两段，可直接看到哪条 debuff 读不到/归不了类。
- 夹具：新增 test_paladin_cleanse_spellid_channel.py（S1-S8，覆盖战斗 secret 场景、未知 ID、目标单位、诅咒排除、缓存与 API 缺失不误判）。

【防骑】2026-11-18（循环静态审计：WR_SpellUsable 严格 GCD 门四处残留 + 单位身份 API secret 安全）
- 用户口径：帮我检查防骑循环是否还有存在错误的地方。
- 根因①（严格 GCD 门残留，功能性失效）：Core WR_SpellUsable(spell, true) 的第三道门是 (GCD or 0.4) <= (ShiFaSuDu or 0.4)。防骑每 tick 把全局 GCD 设为 WR_GetGCD("审判")——返回的是【审判自己的剩余冷却 0~10 秒】而不是公共冷却，ShiFaSuDu=0.3，于是「true 版」可用性 ≈「审判剩余 CD ≤ 0.3 秒」。审判一好就打 → 审判约 90% 时间在 CD → 传 true 的调用点几乎整场被拦。四处活路径中招：① 打断滑条 → 制裁之锤（InterruptStep）；② 全局保护 → 保护之手（ProtGlobalProtectionStep）；③ 生存自保 → 圣疗术；④ 生存自保 → 圣佑术。表现为「打断滑块无效」「全局保护永不触发」「低血不自动圣疗/圣佑」。
- 修复①：四处全部去掉 GlobalCooldown=true（只查技能自身冷却），与 2026-11-18 已修的 驱邪术/奉献/愤怒之锤 同一口径；公共冷却仍由 ShowSkillCD 的提示防抖 + 本地冷却记账兜底。
- 根因②（secret 安全缺口，可致整条循环被打断）：Forever 12.x 在战斗/副本受限上下文里，UnitIsPlayer / UnitIsDeadOrGhost / UnitIsUnit / UnitIsFriend / UnitGroupRolesAssigned 的返回值可能是 secret boolean / secret string。旧代码裸真值判断（拿不到「确认的 true」）与裸 == 比较（直接抛 "attempt to compare a secret boolean value"）并存，抛错会被 Paladin_Forever.lua 的防骑看门狗吞掉 —— 用户感知就是「循环失效」。
- 修复②：新增 WR_PaladinForever_SafeBool（pcall 调用 + pcall 比较，只认确认 true/false，读不到返回 nil，口径与 Paladin_Forever.lua:1987 UnitIsDeadOrGhost 一致），并接入：全局保护身份门（UnitIsUnit/UnitIsDeadOrGhost/UnitIsPlayer/UnitIsFriend）、焦点识别两处 UnitIsUnit、指向三手 mouseover 门、职责判定 UnitGroupRolesAssigned 的 role 比较（EUI EllesmereUI.lua:2333 同款 issecretvalue(role) 实证）；另把光明圣印 / 十字军审判 / 智慧审判三条状态机 phase4 的裸 UnitIsDead("target") 统一改为 WR_PaladinForever_UnitIsDeadOrGhost（裸 UnitIsDead 在 secret 下拿不到确认 true，尸体被当活体继续挂审判）。
- 夹具：新增 test_paladin_prot_strict_gcd_gates.py（I1-I3 / G1-G3 / S1-S4 / X1，含「忠实复刻 WR_SpellUsable 门语义」的桩，不再用恒 true 桩）与 test_paladin_identity_secret.py（S1-S8，含 secret 哨兵运行期不抛错验证）；另修两处夹具自身缺陷（lupa 把 Python 回调暴露成 userdata 导致 type() 守卫整体判否 → 统一包 Lua 闭包；focus_calls 返回 lupa 表需按索引转字符串）。
- 验证：防骑 23 套夹具全绿（含清洁 6 套、驱邪 5 套、圣印/审判 5 套、防护 3 套、看门狗、身份 secret）；全量夹具 144 套 140 通过，4 个失败为既有 mage_frost×3 / warlock 漂移（与本次改动无关）；全量 Lua 语法 215 文件全通过。

【防骑】2026-11-18（清洁术战斗中不驱散中毒四次修复：白名单补截图三毒ID + C_TooltipInfo 免读回扫描 + 探测容器对齐 EUI 生产形态）
- 用户口径：战斗中防骑中毒后依旧没有使用清洁术。三张截图实锤：毒药(744)·中毒·剩余23秒 / 暗言术：痛(15654)·魔法·剩余14秒 / 毒药(13298)·中毒·剩余20秒。
- 根因①：已知ID白名单只有 7 个 ID，截图三个 ID 全不在表内——免读回、免容器的 ID 直查通道（真机唯一不依赖探测容器的通道）对真实中的毒形同虚设。修复：补齐 744/13298/15654 + 暗言术：痛/腐蚀术/献祭全 rank 家族（多录只是多查几个 ID，查不到静默跳过，无副作用；绝不收录诅咒类 ID 防空放 GCD）。
- 根因②：引擎 includeDispelTypes 候选表混入 magic/MAGIC/魔法 等变体键——EUI 生产只用规范 Magic/Disease/Poison（EllesmereUI_UnitFrames CANDIDATE_CLASSES 87-91 实证），C 侧候选校验遇非规范键可能整表拒绝 → filtered 组连脱战精确判型都哑火。修复：候选表改规范三键，变体键只留给插件侧字符串比较。
- 根因③：探测容器与 EUI 生产形态三处差异——SetAlpha(0.001)（引擎排版 OnUpdate 是 run-when-visible 模式，AuraKit 1612-1615，生产从不压 alpha）；YOU 组 maxFrameCount=1 + 自定义 initializeFrame（生产组 maxFrameCount=10、无初始化器，AuraKit GROUP_BATCH 10 按钮批次防指纹下限）；SetUnit 结果 pcall 吞错——静默失败时容器永远绑在引擎 NO_UNIT("none") 上（RaidFrames NO_UNIT 注释同款）全组恒空，是真机三次修复全哑火的容器级根因候选。修复：去 alpha、YOU 组对齐生产形态、SetUnit 校验失败不缓存 rec 5 秒重建、AddAuraGroup 缺失显式重试、filtered 组摘除装饰初始化器（仅 RAW 保留读回分类用）。
- 新增通道④：C_TooltipInfo 驱散提示扫描（免读回、免容器）——!Pig Tooltip.lua 321 / PartyMemberFrame.lua 366 实证本客户端 TooltipDataProcessor.UnitAura 数据流可用，用户截图「法术ID/中毒/剩余X秒」正是该数据流；GetUnitDebuffByIndex/GetUnitDebuff 兼容序逐格扫描，顶层 id 命中白名单或行文本「中毒/疾病/魔法」即点亮；0.5 秒节流、被拒 2.5 秒冷却；EUI 明令禁止 Lua 创建扫描 GameTooltipTemplate 帧（reference_tooltip_template_taint）所以只走 C_TooltipInfo；读不到一律未知绝不判无。
- /FH_QJS_DEBUG 附 setUnitOK（容器绑定是否成功）与 ttHit（提示扫描缓存）。新增夹具 test_paladin_cleanse_fourth_channels.py（T1-T16），清洁/驱邪/防护/圣印全家族夹具回归全绿，全量语法 215 通过。

【防骑】2026-11-18（清洁术战斗中不驱散中毒三次修复：受限内容改「免读回」通道——RAID_PLAYER_DISPELLABLE 令牌组 + 已知 debuff ID 存在性直查）
- 用户口径：修改后防骑依旧没有驱散中毒（截图：毒性钉刺 5416 · 中毒 · 剩余41秒，战斗中）。
- 根因（三次实锤）：受限内容下引擎给 AuraButton 挂 DenyTaintedAccessWhenAurasAreSecret（EUI AuraKit 1277-1280 实证；DBM AuraTracking 870 同款门）——挂牌后插件侧对按钮的任何读取（GetAtlas/GetVertexColor/IsShown/DebuffBorder/GetDispelTypeTexture）都被拒绝。前两版「RAW 边框读回」「注册图标读回」都依赖读回类型，离线夹具全绿、真机分类全 unknown；candidateFilters.includeDispelTypes 又由引擎读被 REDACTED 的 dispelName（Nameplates 实证）→ filtered 组战斗中恒空。
- 修复①：探测容器新增 WR_CLEANSE_PROBE_YOU 组，filter = "HARMFUL|RAID_PLAYER_DISPELLABLE"（EUI RaidFrames 生产同款）——引擎侧按职业/专精判「我本人可驱散」（防骑清洁术属职业驱散），组内有帧即答案，零读回；创建 + 幂等回填双接线。
- 修复②：新增 WR_PaladinForever_PlayerAuraIDHasDispellable（EUI AuraBuffReminders NON_SECRET_SPELL_IDS 同款）：已知 debuff ID 存在性直查——5416 毒性钉刺（中毒）、3427 感染之伤（疾病）、172/348/118/13710/8122（魔法）；战斗中 GetPlayerAuraBySpellID 对未上秘密旗的 ID 照样返回非 nil，「非 nil 即存在」；nil 一律当未知绝不判无；仅 player 单位，接入 UnitHasDispel 链（容器装配失败也能命中）。
- 修复③：API 存在性守卫沿用 ~= nil 约定（可调用 userdata 的 type() 不是 "function"）；/FH_QJS_DEBUG 新增 youFrames= 与 ID直查= 字段。
- 夹具：新增 test_paladin_cleanse_restricted_channels.py（Y1-Y12），restricted_probe P8 接线数 3→5；防骑 23 套夹具全绿，全量语法 215 通过。
【防骑】2026-11-18 二次修复（战斗中依旧不驱散中毒：探测按钮未注册引擎「驱散类型图标」纹理）
- 用户口径：清洁术战斗中依旧没有驱散中毒（真机截图：毒性钉刺 · 法术ID 5416 · 中毒 · 剩余44秒）。
- 根因（二次实锤，EUI AuraKit 源码实证）：引擎 AuraButton 的驱散类型图标是「注册制」——必须在 initializeFrame（按钮创建窗口；创建期之后写按钮被 DenyTaintedAccessWhenAurasAreSecret 拒绝）里建持手 + CreateTexture，再 pcall(button.AddDispelTypeTexture, button, tex, { style = Enum.CustomAuraButtonDispelTypeTextureStyle.Icon, showWhenHarmful = true, showWhenHelpful = false })，引擎随后才逐光环盖章 RaidFrame-Icon-DebuffPoison/Disease/Magic/Curse/Bleed 图集（受限内容内外同一机制）。上一版探测组 initializeFrame 是空函数 → 帧上没有任何可读类型纹理 → kind 全 unknown → 战斗中 AurasRestricted 兜底判无 → 中毒/疾病/魔法全部哑火。
- 修复：①探测组（filtered + RAW 双组）initializeFrame 换成 WR_PaladinForever_CleanseProbeInitFrame——创建持手 + 纹理 + AddDispelTypeTexture(Icon style)（旧引擎回退 SetAuraBorder），弱表登记，结构缺失记 false 防重试、疑似受限拒绝 2 秒重试；②CleanseProbeFrameKind 新增 ⓪ 主通道读注册纹理：引擎明确隐藏（IsShown 可读且 false）→ untyped 明确排除，图集含 debuff<type> → 分类，顶点色兜底（EUI 标准驱散色），读不到 → 交回旧通道绝不猜；③untyped 与 curse/bleed 同列明确排除；④/FH_QJS_DEBUG 新增 rawKinds 逐帧类型诊断。
- 夹具：test_paladin_cleanse_restricted_probe.py 扩到 R1-R16 + P1-P10 共 26 项（引擎注册图标 中毒/疾病/魔法点亮、诅咒/流血/无图集/secret/引擎隐藏不点亮、三处接线静态检查），全绿；cleanse 家族 + 驱邪 + 防护门 11 套夹具全绿；全量 Lua 语法 215 通过。

【防骑】2026-11-18（清洁术自身战斗中不驱散魔法/疾病/中毒：受限内容 includeDispelTypes 恒空 + blanket RAW 组边框探针）
- 用户口径：防骑清洁术自身功能要求战斗中也要驱散魔法，疾病，中毒。
- 根因（实锤）：受限内容（战斗/首领战/挑战模式/PVP）里 AuraContainer 的 candidateFilters 读的 auraData.dispelName 被引擎 REDACTED——EllesmereUI Nameplates 源码同款实证「candidate filters read auraData.dispelName ... there the include-Magic candidate matches nothing」。旧引擎探测器只有 includeDispelTypes 类型过滤组（WR_CLEANSE_PROBE），战斗中恒空 → 判 false；多API扫描 / DebuffFrame / 严格探针全 nil → 最后 AurasRestricted() 兜底判无 → 自身/目标清洁术战斗中永不点亮（脱战正常，所以只在战斗中观察到）。
- 修复：探测器容器补挂无候选过滤的 blanket HARMFUL 组 WR_CLEANSE_PROBE_RAW（maxFrameCount=40，受限内容下引擎照样填充按钮；登录/进世界预建 + 每 tick 幂等回填）；WR_PaladinForever_CleanseProbeHasDispellable 在 filtered 组为空时逐帧读引擎维护的驱散边框/类型纹理（DebuffBorder 图集 / GetDispelTypeTexture，与暴雪 DebuffFrame 同一引擎机制）：中毒/疾病/魔法 → 点亮清洁术（自己=43 / 目标=44）；诅咒/流血 → 明确排除（绝不错驱诅咒）；读不到 → 未知交回后续通道，绝不猜。filtered 组为空不再直接判无。/FH_QJS_DEBUG 诊断新增 probeRaw 计数。
- 夹具：新增 .workbuddy/test_paladin_cleanse_restricted_probe.py（R1-R16：疾病/魔法/中毒点亮、诅咒/流血/未知不点亮、双组注册参数、注册失败安全、filtered 快通道回归）；test_paladin_cleanse_engine_probe.py E5 适配双组注册。防骑 21 套夹具全绿，全量 Lua 语法 216 通过。

【防骑】2026-11-18（审判buff选十字军 + 常驻圣印选智慧/光明：循环不再打审判顶掉十字军审判 buff）
- 用户口径：防骑审判buff当选择十字军的时候，圣印选择智慧圣印、光明圣印的时候不要打审判，会顶掉审判buff。
- 根因①：主调度 judgeEligible 的「防顶掉审判buff」门（2026-11-13 v2）只写了光明圣印 / 智慧审判开关（FH_CRGMSY / FH_ZHSP），漏了十字军审判开关 FH_SZJSP——十字军审判开关开着、常驻圣印选智慧/光明时，主调度照常打审判，这一发就是智慧/光明审判，把状态机刚挂好的十字军审判顶掉。
- 修复①：防顶掉门补上 FH_SZJSP。十字军审判开关开启且常驻圣印会产生另一条审判 debuff（光明/智慧）时，主调度不打审判，审判续挂由十字军状态机独占（切十字军圣印 → 审判 → 切回）；常驻十字军（同一条审判）与常驻愤怒/正义（审判不产生审判 debuff，2026-11-14 口径）照常正常打审判。
- 根因②：审判成功后的本地记账只在「光明↔智慧」之间互清；十字军审判被顶掉后 rec.crusader 旧账还挂着，十字军状态机会误以为 buff 还在，最长 40 秒不再续挂。
- 修复②：本地账按目标三条审判（光明 / 智慧 / 十字军）互清——打上任意一条时清掉另外两条（三条审判同属目标身上一个「审判」槽位）。
- 夹具：新增 test_paladin_crusader_buff_no_overwrite.py（X1-X3 主循环不打审判 / Y1-Y5 不误伤对照 / N1-N4 本地账互清）；审判/圣印相关 52 套夹具全绿；全量 Lua 语法检查 216 通过。

【防骑】2026-11-18（驱邪术「普通怪也亮」回归修复 + 防骑循环看门狗）
- 用户口径：防骑循环存在失效的情况，并且驱邪术依旧是没有对亡灵，恶魔怪使用。
- 根因一（普通怪误亮）：Paladin_Forever_Prot.lua 的 tryExorcism 是驱邪术唯一点亮入口，但闭包只判 exorcismEligible 快照，未再复核类型门——快照算完到点亮之间类型判定被跳过时，非亡灵/恶魔目标也可能亮色块。
- 根因二（循环失效）：Forever 12.x 战斗上下文单位字段大量 secret 化，防护循环内部任何一处裸比较抛 "attempt to compare a secret ..." 都会让本 tick 整条循环当场中断，表现即「循环失效」（该 tick 什么都不提示）。
- 修复：
  ① tryExorcism 闭包内每 tick 复核 WR_PaladinForever_IsUndeadOrDemon：类型明确不是亡灵/恶魔 → 一票否决；类型未知（全 secret）→ 维持通道④口径（可用性不证明类型，宁可不亮）。
  ② Paladin_Forever.lua Forever 防护分支加看门狗：pcall 包住 WR_PaladinForeverProt，抛错时限频（5 秒一次）打印「[防骑看门狗] 循环本轮中断：<错误>」，下一 tick 自动继续，单次 secret 抛错不再打死整条循环；惩戒/神圣分支保持原派发行为。
- 实机指引：再遇「循环失效」看聊天栏 [防骑看门狗] 输出即可定位抛错点；驱邪术依旧可打 /FH_QX_DEBUG 核对 类型/可用性通道/技能状态(learned/usable/left)/门槛快照。
- 夹具：新增 .workbuddy/test_paladin_exorcism_step_gate.py（S1 类型门回归）与 .workbuddy/test_paladin_prot_watchdog.py（W1-W3）；全量 216 文件语法通过；防护/驱邪/圣印 10 套夹具全绿；奶骑/法师/术士/猎人的既有失败与本改动无关（回退对照实验证明）。

【牧师·戒律】2026-11-18（按猪猪 / 彼岸花·无限服 戒律功能图同步重做）
- 用户口径：这是猪猪的戒律牧功能图，你根据图示来同步修正mk插件中的戒律牧专精，不要污染其他职业，当前版本是魔兽世界无限服60级天赋和技能，当前mk插件的技能许多都是80级的技能不需要使用了，UI界面以MK插件为主，请同步修正。
- 根因：旧戒律面板/循环仍是 80 级体系（痛苦压制、守护之魂、神圣赞美诗、希望圣歌、治疗之环、愈合祷言、绝望祷言、狂咒、过量停条等），与无限 60 级实际技能不符；图中的 10 条拉条（喝红药/黑暗献祭/真言术盾/苦修/联结治疗/快速治疗/强效治疗术/治疗术/次级治疗术/恢复）与功能（驱散/暗言术灭/真言术韧/心灵之火/惩击）及插入（灌注/新星/治疗祷言）大多未接线。
- 修复：
  ① Priest_Menu.lua 戒律专区按图重排：选择（防ADD/治疗模式）、10 条拉条（默认值与图一致）、爆发三槽位 + 全开/全关/切换、功能 5 图标、插入 3 图标；旧 80 级菜单项全部移除。
  ② Priest_Forever_Discipline.lua 重写为 60 级戒律循环：喝红药→黑暗献祭→真言术盾→苦修→联结治疗→快速治疗→强效治疗术→治疗术→次级治疗术→恢复；治疗模式支持全团/目标/预读/坦克/脆皮/一队~五队；BUFF、驱散（魔法/疾病）、惩击/暗言术灭、插入与爆发全部接通。
  ③ Priest_Macros.lua 补 治疗术(194) / 次级治疗术(195) / 惩击(196) / 黑暗献祭(197) 宏与 WR_SkillColor 槽位。
  ④ Priest_Forever_Discipline_Features.lua 改为兼容层：保留 Pre/Post 接口、/mkhdisc 系列命令与爆发按钮。
- 验证：新增 .workbuddy/test_priest_discipline_image_sync.py（56 项）；戒律相关夹具与全量 Lua 语法检查通过。

【骑士】2026-11-18（驱邪术参考 PaladinAssist 重构：三系统一 spell 状态机）
- 用户口径：可以根据 PaladinAssist 这个插件进行修复，修复骑士的驱邪术功能。
- 参考实现：PaladinAssist 12CA28C1 的 createSpell/refreshSpell——learned = C_SpellBook.IsSpellKnown(spellId)；usable = C_Spell.IsSpellUsable(spellId)；left = C_Spell.GetSpellCooldownDuration(spellId):EvaluateRemainingDuration(curve2550)（引擎侧求值，不读 secret 字段）。
- 根因：惩戒 / 神圣的 ExorcismStep 仍用 WR_SpellUsable("驱邪术", true)；防护虽然去掉了 true，但 WR_SpellUsable("驱邪术") 的第一道门仍拿全局 GCD（本职业 GCD = WR_GetGCD("审判")，8~10 秒）当公共冷却比较 → 审判一进 CD，驱邪术永久判死。该 GCD 严格门在 2026-7-31 猎人复活 / 血 DK 起手 BB 已踩过同款坑（见 GX 旧记录）。
- 修复：
  ① Paladin_Forever.lua 新增 WR_PaladinForever_ExorcismState（learned / usable / left，0.1 秒缓存）、WR_PaladinForever_SpellCooldownLeft（C_Spell.GetSpellCooldownDuration + EvaluateRemainingDuration 曲线）、WR_PaladinForever_ExorcismReady、WR_PaladinForever_ExorcismStep（三系共用：开关 → 目标可攻击存活 → 亡灵/恶魔 → 30 码 → learned/usable/left → 点亮）。
  ② 惩戒 RT.ExorcismStep / 神圣 HS.ExorcismStep 改为调用共享 WR_PaladinForever_ExorcismStep，移除 WR_SpellUsable("驱邪术", true)。
  ③ 防护 exorcismEligible 改走 WR_PaladinForever_ExorcismReady，不再用 WR_SpellUsable("驱邪术") 的 GCD 门。
  ④ /FH_QX_DEBUG 增加「技能状态(learned / usable / left)」输出；门槛快照补 learned / left。
- 夹具：新增 .workbuddy/test_paladin_exorcism_assist.py 14 项（三系接线 / 状态机 / 共享步骤 / 缓存）；全部 47 个骑士夹具 + 全量 Lua 语法检查通过。

【防骑】2026-11-18（驱邪术「永不使用」实机根因：可用性门的 GlobalCooldown 误用审判剩余冷却）
- 用户口径：防骑驱邪术没有使用；/FH_QX_DEBUG 显示五通道判定=true，但色块仍不亮。
- 根因：Paladin_Forever_Prot.lua 的 exorcismEligible 用 WR_SpellUsable("驱邪术", true) 做可用性门。WR_SpellUsable 的第三道门是 `(GCD or 0.4) <= (ShiFaSuDu or 0.4)`，而本函数的全局 GCD = WR_GetGCD("审判")——WR_GetGCD 返回的是【该技能自己的剩余冷却】而不是公共冷却（Core_Functions.lua:3445-3487）。审判一进 8~10 秒 CD，驱邪术可用性恒 false：单体链每次轮到它都在审判刚打完的窗口里，多目标链审判之后同理 → 判定通道全 true 也永远不亮。
- 修复：
  ① exorcismEligible 去掉 GlobalCooldown=true（改 WR_SpellUsable("驱邪术")），公共冷却交给 ShowSkillCD 的提示防抖 + 1.5 秒保持窗口；同时保留 WR_PaladinForever_ExorcismUsableChannel() 客户端可用性作为兜底。
  ② 同款误门一并修正：WR_SpellUsable("奉献", true)、WR_SpellUsable("愤怒之锤", true) → 去掉 true（否则审判 CD 期间奉献/愤怒之锤同样被判不可用）。
  ③ Core/Forever_Compat.lua 删除 ["驱邪术"] = 879（Exorcism Rank1）覆盖：60 级实际使用高 rank（10314），Rank1 的 IsUsableSpell / 冷却查询对不上会让 WR_SpellUsable 恒 false；改由法术书索引解析当前 rank。
  ④ Paladin_Forever.lua 补 WR_PaladinForever_SpellRankIDs["驱邪术"] 全 rank，保证施放成功按当前 rank ID 记账、本地 15 秒 CD 不再断档。
  ⑤ /FH_QX_DEBUG 新增「驱邪术门槛」输出：类型/可攻击/距离/射程/可用/GCD变量/施法速度，下次一眼定位。
- 夹具：test_paladin_exorcism_gcd_gate.py（X1 审判冷却变量=8 → 驱邪术仍点亮；X2 奉献仍点亮；X3 源码静态）；全部 46 个骑士夹具 + 语法 215 全过。

【防骑】2026-11-18（驱邪术复查：新增「客户端可用性」通道，战斗中也能判亡灵/恶魔）
- 用户口径：防骑驱邪术没有使用（截图驱邪术 ID 10314 / 等级6 / 15秒CD / 30码）。
- 根因：2026-11-17 的四通道（直读/怪名缓存/同目标memo）都依赖「进战前读过」；目标在战斗中才被选中（被ADD拉怪、追击换目标）时，UnitCreatureType / UnitName 全是 secret、memo 与怪名缓存都没有 → WR_PaladinForever_IsUndeadOrDemon 恒 false → 亡灵/恶魔怪照样不亮驱邪术。
- 修复（Paladin/Paladin_Forever.lua）：新增通道④「客户端可用性」（WR_PaladinForever_ExorcismUsableChannel）——经典机制下驱邪术只对亡灵/恶魔可施放，IsUsableSpell / C_Spell.IsSpellUsable(当前rank) 的 usable 是客户端执行期求值信号（非 secret，与「愤怒之锤」斩杀期判定同一性质）：usable=true → 必为亡灵/恶魔；usable=false → 客户端明确拒绝；读不到 → 维持宁可不打。0.5 秒小缓存避免每 tick 双 pcall；/FH_QX_DEBUG 诊断新增「可用性通道」字段。
- 夹具：test_paladin_exorcism_type.py 新增 E16-E21；全量骑士夹具 + 语法检查全过。

【防骑】2026-11-18（审判buff维持收尾切回目标改为「上一次圣印」）
- 用户口径：防骑审判buff功能修改为之前版本的上一次圣印，切回选中的常驻圣印功能。
- 行为：光明圣印 / 十字军审判 / 智慧审判三个 buff 维持状态机在点火（切到 buff 圣印）时，先记录玩家当时正在用的圣印（BackSeal/BackSlot）；审判挂上 debuff 后的收尾（phase 3/4）与主循环补印目标（ProtSealGoal）都切回这条「上一次圣印」，不再实时读取面板「圣印」专区所选（FH_SEAL）——战斗中改了面板选择也不受影响；记录为空（旧存档/异常）时保持回退面板所选的原行为。
- 修改（Paladin/Paladin_Forever_Prot.lua）：新增 WR_PaladinForever_BuffSealBackTarget；三台状态机点火即记录 BackSeal，phase 0 兜底提示 / phase 3 显式切回 / phase 4 维持提示与反向确认（JudgementSealOnPlayer）全部改用 BackSeal；三个 Reset 函数清空记录。
- 夹具：新增 .workbuddy/test_paladin_seal_switchback_prev.py 14 项（含「战斗中改面板仍切回上一次圣印」回归）。

【防骑】2026-11-18（清洁术疾病复查：unknown 一票否决清除 + 探测器自愈）
- 用户口径：防骑疾病依旧是没驱散。
- 根因（本次实锤）：三处「known-non 一票否决」漏了 unknown 守卫——①多API扫描 ScanUnitDebuffTypes 的 `if sawKnownNonCleansable then return false end`（缺 `and not sawUnknown`）；②暴雪 DebuffFrame 扫描同款（且 borderKind 读不到类型时不记 unknown）；③严格探针本就正确。战斗中疾病（如感染之伤）的类型全是 secret（=unknown），只要身上同时挂着任一可读的诅咒/流血/黑名单 debuff，①②就把整条判定一票否决成 false，UnitHasDispel 直接判无 → 清洁术永不点亮。这与『单独中毒能驱、有诅咒/流血并存的疾病驱不掉』的实战表现完全吻合。
- 修复①：ScanUnitDebuffTypes 否决加 `and not sawUnknown`，与严格探针同口径（全部可读且无一个可驱散类型才判无）。
- 修复②：DebuffFrame 扫描新增 sawUnknownType（secret/nil 类型条目、borderKind 读不到都记 unknown），否决改为 `not sawUnknownAny`。
- 修复③：引擎探测器 includeDispelTypes 补全 magic/disease/poison 与 MAGIC/DISEASE/POISON 大小写变体（auraData.dispelName 形态不同客户端不统一，差一个大小写组恒空）。
- 修复④：探测容器组空时每 1 秒强制 UpdateAllAuras 自愈（登录/切图时序漏事件导致组永久为空的兜底）。
- 夹具：test_paladin_cleanse_combat 新增 K51（诅咒+secret 疾病并存 → nil）与 G6/G7/G8 静态断言；清洁术四夹具 + 全量语法 215 通过。
- 诊断：中疾病后游戏内输入 /FH_QJS_DEBUG，看『多API扫描/暴雪DebuffFrame/严格探针/probe判定』各通道；若要驱散【目标】身上的疾病，需勾面板「目标」复选框（当前存档 FH_QJS_Target=false 只走「自己」通道）。

【防骑】2026-11-18（脱战后小队祝福补刷提速）
- 用户口径：防骑脱战后，小队祝福刷的太慢了。
- 根因一：漏按 / 未确认的重试节奏被三层闸拖住——PENDING_TTL(2.5 秒) + PROMPT_CD(3 秒) + 施放宽限(8 秒)，最坏一个队友要等 3~8 秒才重试一次。
- 根因二：刚脱战只强扫 player 的光环缓存；队友缓存还是战斗中扫描失败留下的 nil，脱战初期被判「读不到」吃指数退避（10/30/60...秒）或空亮色块白费一个 GCD，整队补刷被拖慢。
- 修复（Paladin/Paladin_Blessing.lua）：PROMPT_CD 3→1.5 秒、PENDING_TTL 2.5→1.8 秒、施放宽限 8→3 秒——漏按的队友约 1.8 秒即重试；脱战瞬间对本轮全部候选单位（自己 + 小队/团队）光环缓存一次性强制重扫（一次性标记，进战/未知态自动复位），Needs 立即按真实光环判定，不再吃退避。
- 收口不变：buff 上身立即熄灭色块、CacheUnreadable 指数退避仍在，提速不会变回「反复刷」。夹具 test_blessing_ooc_speedup.py 新增（V1-V4），rebuff_stress/paladin_blessing/cast_range/no_self_cast_dyn 全过，语法 215 全过。

【防骑】2026-11-17（修复「审判buff维持不灵敏」：无确认重试 + 审判真就绪双通道判定）
- 用户口径：防骑审判buff维持不灵敏了，需要修正。
- 根因一（主因）：光明/十字军/智慧三个 buff 维持状态机的 phase 2 在「审判提示后 2 秒内施放事件与目标光环都读不到」时，旧版直接按「提示时刻 + 40 秒」进维持期——审判实际没打出去（CD 偏差 / 被 GCD 吞 / AHK 漏按）时目标审判 buff 空窗近 40 秒没人管，表现为维持不灵敏。
- 根因二：JudgementRemain 优先用本地账（castAt + cdv），cdv 来自天赋探测（强化审判 8 秒 / 基础 10 秒），探测一有偏差，「审判剩余 ≤ 2 秒」切印窗口整体提前/延后：偏小→切印后审判打不出去；偏大→buff 掉了迟迟不补。
- 修复（Paladin/Paladin_Forever.lua + Paladin_Forever_Prot.lua 三台状态机同改）：①phase 2 两秒无确认改为立即回 phase 1 重试（审判一就绪 1 个 tick 内重新提示），连续 3 次仍无确认才按旧兜底记 40 秒并切回常驻（防全程 secret 死循环）；②JudgementRemain 客户端剩余冷却可读时（脱战 / 非 secret）直接以客户端为准，读不到（战斗中）退回本地账；③phase 1 提示审判改用 JudgeTrulyReady 双通道判定：客户端说还在 CD 就不点亮（不再空按），客户端说就绪立刻放行。
- 测试：新增 .workbuddy/test_paladin_judgebuff_retry.py（R1-R8 三台状态机重试/兜底/双通道判定全场景）；test_justice_seal_loop T4/T6 按新口径改写；防骑全部夹具（44 个）与全量 Lua 语法检查通过。
- 用户口径：防骑循环出现异常，不打驱邪术了，当怪是亡灵和恶魔的时候没有用。
- 根因：Forever 12.x 客户端 UI 文档实证 UnitCreatureType 标注 SecretWhenUnitIdentityRestricted——战斗/受限上下文里返回 secret，WR_SafeCreatureType 收敛成 nil → WR_PaladinForever_IsUndeadOrDemon 恒 false → 单体链与多目标链共用的 exorcismEligible 恒 false → 亡灵/恶魔怪永远不亮驱邪术色块。离线夹具 G15 一直通过是因为夹具桩里类型可读。
- 修复（Paladin/Paladin_Forever.lua 四通道判定）：①直读 UnitCreatureType 返回的 id（3=恶魔/6=亡灵，免本地化）+ 名字（亡灵/恶魔/Undead/Demon）；②同目标 memo：进战前选目标可读时记 {TargetEpoch,时刻,结论}，进战变 secret 后同一目标沿用 memo（120 秒防陈旧）；③怪名缓存 WR_PaladinForever_CreatureTypeByName：直读成功按怪名学习，受限时名字仍可读则查缓存；④全部读不到 → false（宁可不打）。PLAYER_TARGET_CHANGED 挂 WR_PaladinForever_NoteTargetTypeProbe：换目标瞬间能读就刷新 memo、读不到就清，绝不把旧目标类型误套新目标。
- 诊断：新增 /FH_QX_DEBUG 打印直读/怪名/名字缓存/memo/TargetEpoch/最终判定，实机核对哪条通道生效。
- 测试：新增 .workbuddy/test_paladin_exorcism_type.py（E1-E14 四通道全场景）；防骑全部夹具与全量 Lua 语法检查通过。

【防骑】2026-11-17（清洁术战斗内+脱战仍不驱散：探测器一票否决与装配顺序修复）
- 用户口径：防骑的清洁术战斗中脱战还是没有驱散魔法，中毒，疾病。
- 根因一：2026-11-17 上一版把引擎探测器（AuraContainer WR_CLEANSE_PROBE 组）的 false 当成一票否决——容器组为空既可能是「引擎明确说没有可驱散 debuff」，也可能是「容器装配失败组恒空」，插件侧分不出来；装配失败时它把脱战本可用的多 API 直读/缓存通道全部拦死，战斗内+脱战全部哑火。
- 根因二：探测器创建时 SetUnit 在 AddAuraGroup 之前；对照 EllesmereUI AuraKit（CreateContainerShell → AddAuraGroup → Stage3 SetUnit + UpdateAllAuras） AuraContainer 的 UNIT_AURA 数据管线按当前组列表装配，顺序反了新组可能拿不到光环数据源 → 组恒空。
- 修复（Paladin/Paladin_Forever.lua）：①探测器 false 不再否决，一律放行后续通道（true 仍直接点亮；诅咒误报由各通道类型判定防住）；②装配顺序改为 先 AddAuraGroup → 再 SetUnit → Show + UpdateAllAuras（EUI 同款）；③新增 /FH_QJS_DEBUG 诊断命令：逐条打印 存在/secret/probe容器/probeFrames/probe判定/暴雪DebuffFrame/多API扫描/严格探针/最终判定 与面板 FH_QJS 下拉档位、「自己/目标」复选框状态。
- 提醒：当前存档 FH_QJS=5（下拉=不使用）、FH_QJS_Player=true、FH_QJS_Target=false——只有「自己」复选框在生效；要驱散目标请勾面板第3行第5列「目标」。


【奶骑】2026-11-17（参考 PaladinAssist 修复加血逻辑：自动选人 + 治疗模式 + 过量停条）
- 用户口径：奶骑加血逻辑参照另一个插件（PaladinAssist）修复一下。
- 根因：①旧奶骑只看「焦点」血量，没有焦点/焦点满血时整轮不加血，队友低血无人管；②圣光术/圣光闪现宏是纯 [@focus]，焦点无效时按下等于没按；③自动焦点把「最该治的是自己」直接跳过；④无过量停条、无治疗模式过滤、无在途治疗（incoming heals）判定。
- 修复（Paladin/Paladin_Forever_Holy.lua 重写选人层）：
  · 新增 WR_PaladinForeverHoly_PickBest / EffectiveHP / ValidHealUnit / ModeAllowed：每 tick 扫描 focus/target/player/party1-4/raid1-25，按「有效血量=当前血量+在途治疗」选最低者，死亡/敌对/超40码/离线/被魅惑全过滤；优先复用 Core 治疗权重（WR_GetHealthMaxWeightUnit，含优先 Debuff / 坦克 / 队伍加权），权重不可用时本地扫描兜底（优先 Debuff -0.75、坦克 -0.02、焦点 -0.01）。
  · 治疗模式 SS_ZLMS 全量落地：1全团/2目标/3预读/4泄蓝/5坦克/6脆皮/7-11一~五队/12-15萨12/34/13/24（萨X档沿用 ZWYSDYJ_Unit 指定名单）；预读/泄蓝允许满血起手圣光术，泄蓝不受停条限制。
  · 自动焦点：候选含自己（192 槽）——「最该治的是自己」不再被跳过；焦点更危急时保持不动；模式过滤同样作用于焦点。
  · 过量停条：新增 WR_PaladinForeverHoly_Stopcasting（SS_GLTC 开关 + SS_GLTCCK 窗口），圣光术/圣光闪现读条尾段目标有效血量已满时点亮 101 停止施法；优先 Debuff 强刷不打断。
  · 优先治疗 Debuff：Core/Utils_HealerWeight.lua 新增 WR_UnitHasPriorityHealthDebuff（血肉成灰等），命中时无视血线强刷圣光术、跳过停条。
  · 移动判定：移动中不点圣光术；圣光闪现仅战争艺术/瞬发例外。
- 修复（Paladin/Paladin_Macros.lua）：109/110/150 三条 [@focus] 治疗宏改为「[@focus,help,nodead] 技能; 技能」两段式——焦点无效自动落回自己。
- 面板（Paladin/Paladin_Menu.lua）：神圣页新增「停条窗口」拉条（1=0.1秒~5=0.5秒）与「过量停条」复选框；默认值 SS_ZLMS=1 / SS_ZDJD=true / SS_GLTC=false / SS_GLTCCK=5 写入 Paladin_Holy_Features.InitDefaults。
- 诊断：/mkpalholy 增加治疗模式、选中目标与焦点决策输出。
- 验证：新增 .workbuddy/test_paladin_holy_heal_logic.py 25 项全过（选人/模式/在途治疗/超距/保命/移动/预读/泄蓝/停条/优先Debuff）；全量 Lua 语法 216/216。

【防骑】2026-11-17（圣印功能参考 PaladinAssist：惩戒圣印舞层数；起手圣印已按需求移除）
- 惩戒「解封之怒舞」新增层数档位（CJ_SY_JF_STACKS：一层/二层/三层，默认三层）：回响叠到设定层数换印，层数读不到时按 N×4 秒兜底；对应参考插件「一层泄蓝 / 二层平稳 / 三层爆发」。

【防骑】2026-11-17（清洁术战斗内复查：AuraContainer 过滤器纠正为 HARMFUL + 可驱散类型）
- 用户口径：参考 BigHammer PaladinAssist 的清洁术，修复 MK 插件战斗中仍无法驱散魔法 / 疾病 / 中毒。
- 根因：上一版引擎探测器把 filter 写成 "HARMFUL|RAID"；"RAID" 只表示「团队 debuff」，不表示「玩家本人可驱散」。单人 / 5 人本中的疾病、中毒、魔法不会被它命中，group:GetFramesByIndex() 恒为空 → 清洁术战斗中永不点亮。参考 PaladinAssist 的做法：AuraContainer 的过滤交给引擎按候选过滤器求值，不读 secret 光环字段。
- 修复（Paladin/Paladin_Forever.lua）：
  ① WR_PaladinForever_CleanseProbe 改为 filter = "HARMFUL" + candidateFilters.includeDispelTypes = { Magic = true, Disease = true, Poison = true }，只保留清洁术可驱散的三种类型，诅咒 / 流血不会进入，也不需要按职业模板猜可驱散能力。
  ② GetFramesByIndex() > 0 返回 true；组正常但为空返回 false（引擎明确「没有可驱散」），不再回落到战斗中可能残留旧毒/旧病的缓存路径。
  ③ WR_PaladinForever_ProbeDispellableByFilter 的 GetAuraSlots / GetAuraDataByIndex 同步从 "HARMFUL|RAID" 改为 "HARMFUL"，由 AuraData 的 dispelName / dispelType 明确判类型。
- 验证：test_paladin_cleanse_engine_probe.py（过滤器=HARMFUL、候选类型=Magic/Disease/Poison、命中/为空/不可用）、test_paladin_cleanse_combat.py（过滤器参数 HARMFUL、诅咒不误放）全绿；全量 Lua 语法通过。

【防骑】2026-11-17（修复「神圣之盾·目标为我」与「愤怒之锤·精英」失效）
- 用户口径：防骑这两个功能失效，目标是精英的时候没有生效。
- 根因：① 「目标为我」直接比较 UnitIsUnit("targettarget","player") 的返回值；Forever 12.x 在副本/战斗限制下该返回值是 secret boolean，旧写法 same == true 触发 Lua 错误「attempt to compare local same (a secret boolean value)」，整条防骑循环中断，神圣之盾自然不亮（BugGrabber 已抓到 Paladin_Forever_Prot.lua:1645 的实机错误）；② 「精英」判定直接比较 UnitClassification / UnitLevel，副本内同样是 secret，且旧存档可能只勾「精英」而父开关「愤怒之锤」未开，导致愤怒之锤永远不提示。
- 修复：Paladin_Forever_Prot.lua 的 WR_PaladinForever_TargetTargetIsPlayer 先过滤 secret，普通 boolean 才采用；secret 时用 UnitThreatSituation("player","target") 的 2/3（主目标）兜底，等价于「怪的目标是我」。WR_PaladinForever_HammerTargetIsEliteOrBoss 的 UnitClassification / UnitLevel / UnitIsBoss / WR_UnitIsBoss 全部 pcall + secret 过滤，并在 5 人本/团本（IsInInstance party/raid）分类被 secret 化时按副本精英兜底。
- 面板：两个子项增加 requiresVariable（目标为我→神圣之盾，精英→愤怒之锤），勾选子项自动打开父总开关；旧存档在 ZZ_Features_Migration 中于登录时同步；tooltip 文案同步改为「勾选本项会自动开启左侧总开关」。
- 验证：test_paladin_holy_shield_targetme.py 增加 secret boolean + UnitThreatSituation 兜底用例；test_paladin_hammer_wrath_elite.py 增加 secret 分类 + 副本兜底用例；全量 Lua 语法与圣骑士夹具回归。

【防骑】2026-11-17（修复「全局保护」下拉无消费：自动保护之手）
- 用户口径：防骑全局保护功能是否正常，检查一下。
- 根因：Paladin_Menu.lua 的「全局保护」下拉 saveVariable = FH_ZZBH_HP（1=30% / 2=40% / 3=50% / 4=禁用），但 Paladin_Forever_Prot.lua 从未读取该变量，选任何档位都不会自动施放，属于死设置。
- 修复：Paladin_Forever_Prot.lua 新增 WR_PaladinForever_ProtGlobalProtectionStep：按 FH_ZZBH_HP 把 1/2/3 映射为 30/40/50%，扫描小队/团队成员，跳过玩家自己、坦克职责、死亡/离线/非玩家、超出保护之手射程、已有保护之手 Buff、自律期间的目标；选择血量最低的非坦克队友，复用 WR_FocusCast 焦点施法框架（先设焦点，再亮 64 号保护之手色块）；同时把保护/牺牲/自由/拯救之手加入施放成功事件 ID 反查，保证 5 分钟本地冷却记账不断档。排在自身圣疗/圣盾之后、打断之前。
- 验证：新增 .workbuddy/test_paladin_global_protection.py（P1-P17 共 19 项）全绿；全量 Lua 语法 215/215。

【全局】2026-11-17（职业隔离 + 主循环性能优化）
- 用户口径：在不影响职业专精的情况下，避免职业污染，需要提高插件运行的性能。
- 职业隔离：全部职业目录 Lua 文件补齐真实生效的 WR_PlayerClass 早退守卫（149 个文件）；非本职业不再定义职业函数/职业常量/职业 UI，消除 HS / WF / WA / quanzhong 等同名全局函数被后加载职业覆盖的隐患。守卫版本兼容无 WR_PlayerClass 的离线夹具（nil 时按原样加载）。
- 性能：MainLoop 每个 tick 不再新建 ClassMenu 大表与重复 UnitClassBase；职业菜单与循环入口首次 tick 解析后缓存；WR_GetGCD / WR_SpellUsable / WR_UnitRange 增加 50ms 同 tick 缓存（同 tick 内同技能/同单位只查一次，跨 tick 自动过期）；WR_UpdateFrameState 的 UnitCastingInfo / UnitChannelInfo 由每 tick 4 次降为 2 次并供 WR_GetGCD 复用；WR_PriorityCheck 停手 Buff/Debuff 表提升为文件级常量。
- 兼容：职业循环优先级、专精分支、色块槽位与所有面板逻辑均未改动；新增 .workbuddy/test_class_isolation_all.py 与 .workbuddy/test_core_perf_cache.py 验证。

【全局】2026-11-17（色块下方显示对应技能名）
- 用户口径：1级小号猎人看到左上角一直亮着的色块，不知道是什么技能；要求色块都写上对应技能。
- 实现（Core/UI_ColorFrame.lua / Core/UI_ColorFrame_1.lua）：每个色块（左上/右上）的 FontString 改为锚定在 42×42 色块区（含 2px 黑保护底）的下方，绝不压住 AHK 主采样点 (1,1) 与备用采样点；字号 10、白字黑描边。WR_ShowColorFrame 写入技能名（「指向保护/填充奉献」等描述型提示映射为真实技能名），默认常显。
- 开关：PigSet.ColorBlockNameShow（默认开，Core/ZZ_Features_Migration 的 CoreDefaults 已登记），与「屏幕文字提示」总闸独立；置 false 即隐藏色块技能名。
- 结论：1 级猎人左上角常亮色块 = 槽位 40 = 自动射击（Auto Shot）。

【防骑】2026-11-17（清洁术战斗内不驱散疾病/中毒：引擎级「玩家本人可驱散」探测容器）
- 用户口径：骑士清洁术还是无法在战斗中驱散疾病和中毒（截图「感染之伤」法术ID 3427，类型：疾病，剩余5分钟）。
- 根因：12.x 战斗内 name / dispelName / dispelType 全部 secret，C_UnitAuras 的 GetAuraDataByIndex / GetAuraSlots 被 RequiresUnitAuraAccess 拒绝；AuraUtil.SetAuraBorderAtlas 写入的图集也是 secret（GetAtlas 读不出类型），旧「secret 串 / 整条 AuraData」双探针在战斗内必然失败；EUI 战斗内 solid strip 的顶点色同样是 secret，旧扫描还可能被另一枚可见诅咒按钮压成 false。
- 修复（Paladin/Paladin_Forever.lua）：
  ① 新增 WR_PaladinForever_CleanseProbe 引擎级探测容器：登录/进世界时预创建 1×1 透明 AuraContainer（战斗内不能创建），声明 filter = "HARMFUL|RAID"（注：此写法有误，实际只匹配团队 debuff；已在 2026-11-17 复查条目中纠正为 HARMFUL + includeDispelTypes）。每 tick 只读 group:GetFramesByIndex() 的数组长度，>0 即存在可驱散，完全不读任何 secret 光环字段。
  ② UnitHasDispel 在友方检查后优先调用该探测器，命中直接返回 true，不再被 EUI / DebuffFrame / secret 探针的 false 提前否决。
  ③ EUI 扫描新增 sawUnknownButton：只要存在「可见按钮但纹理类型读不出」的未知项就不再返回 false，避免旧诅咒按钮把当前疾病 / 中毒压成「无驱散」。
- 验证：新增 .workbuddy/test_paladin_cleanse_engine_probe.py（探测器命中/未命中/不可用/容器绑定/UnitHasDispel 早返回/诅咒不误放）；全部圣骑士夹具与全量 Lua 语法通过。

【防骑】2026-11-16（修复「打断」滑条无效：滑条控制制裁之锤施法打断）
- 用户口径：防骑打断滑条目前无效，需要修复；打断滑块控制制裁之锤用作施法打断。
- 根因：Paladin_Menu.lua 防护 DM 的「打断」滑块 saveVariable = "FH_DD"，但 Paladin_Forever_Prot.lua 从未读取 FH_DD，滑条没有任何消费点；旧版自动制裁之锤提示又已在 2026-11-11 删除，只剩「插入 制裁之锤」一次性手动开关。
- 修复：Paladin_Forever_Prot.lua 新增 WR_PaladinForever_InterruptStep / WR_PaladinForever_DurationCastPercent / WR_PaladinForever_TargetCastProgress；按 FH_DD 阈值（0=关闭，5~100=目标施法/引导进度百分比，默认50，兼容旧布尔 true=50 / false=关闭）在目标可打断读条达到阈值时提示制裁之锤（槽22 / ALT-NUMPAD2，本地冷却按「基础60秒 - 强化制裁之锤天赋每级5秒」计算）；排在生存自保之后、清洁术之前，沿用 Core/InterruptController 的 WR_ShouldInterrupt；Forever 12.x 优先用 UnitCastingDuration/UnitChannelDuration 的 EvaluateElapsedPercent 做 secret-safe 进度判断（原始时间戳是 secret number，不能做算术），该通道不可用时退回 UnitCastingInfo/UnitChannelInfo 时间戳。
- 面板（Paladin/Paladin_Menu.lua）：打断滑块 tooltip 明确「自动用制裁之锤打断」。
- 验证：.workbuddy/test_paladin_interrupt_slider.py（R1-R18、R10b、M1-M2 共 24 项）全绿；全量 Lua 语法 215/215。

【防骑】2026-11-16（神圣之盾新增「目标为我」开关）
- 用户口径：防骑神圣之盾添加一个按钮，控制当怪的目标为自己的时候才释放神圣之盾，否则不用。
- 面板（Paladin/Paladin_Menu.lua）：防护「自动」组神圣之盾右侧新增「目标为我」复选框（FH_SZS_TARGETME，默认关 = 原行为），愤怒之锤/精英顺延到第 3/4 列。
- 逻辑（Paladin/Paladin_Forever_Prot.lua）：新增 WR_PaladinForever_TargetTargetIsPlayer（目标必须是可攻击活体 + targettarget 存在 + UnitIsUnit("targettarget","player") 为真，任何读不到/抛错按不满足）；holyShieldEligible 在勾选该开关时追加此条件，未勾选完全保持原逻辑。
- 验证：.workbuddy/test_paladin_holy_shield_targetme.py（R1-R10、M1-M2 共 14 项）全绿；全量 Lua 语法 215/215。

【防骑】2026-11-16（正义之怒：战斗/脱战只要 Buff 消失就立马补）
- 用户口径：防骑正义之怒不管战斗还是脱战，只要是 buff 消失了，就要立马补。
- 根因：旧 WR_PaladinForever_FuryUp 在光环不可读（战斗中 secret）时先靠「30 分钟施放成功记录」硬判已开启，Buff 中途被驱散或提前到期后仍要等记录过期才补，表现为「消失了很久不补」。
- 修复（Paladin/Paladin_Forever.lua）：新增 FuryLastUpAt / FuryLastUpRemain 观测记录；光环可读且缺失 → 立即判缺失（下一 tick 就亮）；可读且存在 → 记录观测时刻与剩余；光环缓存剩余 >0 同样记录；战斗中光环 secret 读不到时按「最后观测时刻 + 剩余」推算到期，一到即判缺失立刻补；30 分钟施放成功记录降级为「完全没有任何可读/投影证据」时的兜底。施放成功事件（按名 / 按 spellID 25780）同步清空旧观测，避免旧投影压住新 Buff。
- 回归：.workbuddy/test_paladin_fury_refill.py（L/F1–F9 共 13 项）全绿；全量 Lua 语法 215/215。
【增强萨】2026-11-16（按猪猪 / 彼岸花-无限服增强页重做增强萨功能与循环）
- 用户口径：图片为增强萨满专精；当前客户端 60 级天赋与技能；按图匹配功能并移除 80 级旧开关，界面仍走 MK 面板，不污染元素/恢复与其他职业。
- 新增 Shaman/Shaman_Enhancement_Features.lua（登记进 TOC）：增强萨默认值/旧档迁移（FANG_ADD_ZQS/FANG_ADD_SM→SM_ZQ_FADD、SM_ZQ_XWWQCS 漩涡层数下拉→SM_ZQ_XWWQ 拉条、SM_ZQ_ZDHYXX→SM_ZQ_HXX、SM_ZQ_ZDQS→SM_ZQ_QS、SM_ZQ_HXTT 火系图腾下拉→自动图腾火系勾选、SM_ZQ_GJTT→SM_ZQ_TT_GJ）；选择 防ADD/护盾(水之护盾/闪电之盾/禁用，截图默认禁用)；拉条 喝红药30%/漩涡武器3层(层数达到打闪电箭，0=关闭)/打断60%；功能 震击（右键小窗：烈焰震击+预判6秒/地震术/震击留打断/等级满级1级，宏 /SHAMAN_SHOCK）/自动图腾（右键小窗：火/土/水/风每系总开关+图腾勾选每系一个，与恢复萨共用 /SHAMAN_TOTEM 按专精分流）/切换目标/火焰新星/驱散（净化术驱散敌方魔法增益）；爆发 种族爆发+全开/全关/切换；插入 呼吸(水下呼吸)/元素(元素的召唤)/灵魂(灵魂的召唤)/先知(先知之怒)/灼热/熔岩 一次性放完自关。
- 输出优先级：烈焰震击保持(预判)→风暴打击→漩涡武器层数闪电箭→火焰新星→大地震击；震击留打断开着时烈焰震击/地震术/大地震击全部让路给打断。
- 移除 80 级/不存在技能引用：野性狼魂、萨满之怒、熔岩猛击、熔岩爆裂、寒霜刺骨、武器附魔下拉、治疗链五星；宏补槽 107=水下呼吸、108=烈焰震击(等级1)、109=地震术。

【防骑】2026-11-16（清洁术战斗内不驱散魔法/中毒/疾病：EUI 未读类型不再判无 + secret dispelName 双探针）：EUI 未读类型不再判无 + secret dispelName 图集探针）
- 用户口径：骑士战斗中清洁术再次失效，魔法 debuff 不驱散；诅咒仍绝不能解。
- 根因：EllesmereUI 自定义按钮的 dispel 纹理在战斗中或隐藏按钮上读不到图集/颜色时，旧实现把「扫到纹理但类型未知」当作「明确无驱散」返回 false；隐藏按钮子纹理只看 IsShown 也会把旧诅咒 strip 当当前类型，导致战斗内魔法/中毒/疾病被提前否决。
- 修复：EUI 扫描未知类型一律返回 nil（只有明确 curse/bleed 才 false）；纹理可见性改用 IsVisible（父级隐藏也过滤）；AK hook 覆盖 dispelBorder 与 dispelTypeIcon 两条通道并缓存 iconTex/strips 引用，登录/进世界预热；secret dispelName 双探针 —— AuraUtil.SetAuraBorderAtlas(secret 串) 与 AuraUtil.SetAuraBorderAtlasFromAura(整条 AuraData，引擎内部解析 secret，中毒/疾病在战斗内的识别主通道)，探针纹理缓存走 _G 并在每次探测前清空旧图集。清洁术仍只放行 Poison/Disease/Magic，6909 与 Curse/Bleed 永不驱动。
- 验证：test_paladin_cleanse_combat.py 新增 J31-J42 全过（含 Poison/Disease 图集、FromAura 探针、战斗端到端 secret AuraData）；全量圣骑士夹具通过；全量 Lua 语法 215 文件通过。

【恢复萨】2026-11-16（按猪猪 / 彼岸花-无限服恢复萨满页重做恢复萨功能与循环）
- 用户口径：图片为恢复萨满专精；当前客户端 60 级天赋与技能；按图匹配功能并移除 80 级旧开关，界面仍走 MK 面板，不污染元素/增强与其他职业。
- 新增 Shaman/Shaman_Restoration_Features.lua（登记进 TOC）：恢复萨默认值/旧档迁移（HF_ZLMS 旧治疗模式→SM_HF_ZLMS、HF_ZRXJ/HF_JL/HF_ZLL/HF_ZLB/HF_CJZLB 拉条→SM_HF_*、HF_TT→SM_HF_TT_ON、HF_QS 驱散下拉→SM_HF_QS_ON）；选择 防ADD/治疗模式(全团~五队)/护盾(水之护盾/大地之盾/禁用)；拉条 喝红药30%/迅捷波30%/激流80%/治疗链54%/治疗波60%/次级治疗波85%/打断60%；治疗优先级 迅捷波→激流→治疗链→治疗波→次级治疗波；功能 自动图腾（右键小窗：火/土/水/风每系总开关+图腾勾选，每系只插一个，GetTotemInfo 检测缺图腾自动补）/切换目标/驱散（右键小窗：自己/小队）；爆发 种族爆发+全开/全关/切换；插入 呼唤(元素的召唤)/元素(火元素图腾)/灵魂(土元素图腾)/法力潮(法力之潮图腾) 一次性放完自关。
- 治疗链右键小窗按截图：等级（最高级/1级40级学/2级46级学/3级54级学，走宏 75/102/103/104）+ 人数（1=单人阈值，2以上=至少这么多人掉血且最低几人平均血量低于阈值）；宏 /SHAMAN_TOTEM 与 /SHAMAN_CHAINHEAL<数值>。
- 重写 Shaman/Shaman_Forever_Restoration.lua（仅 Forever 恢复）：薄壳派发到功能层；移除治疗之雨/潮汐之力/狂咒/过量停条等 80 级/SoD 遗留。Shaman_Macros.lua 补 图腾/迅捷波/治疗链等级 宏槽 85-88/91-96/101-106 与色表登记（灼热45/熔岩6/火舌96/抗寒95/抗火91/大地之力15/石肤85/地缚86/战栗33/法力之泉105/治疗之泉106/清毒87/祛病88/风怒92/风之优雅93/自然抗性94/根基55/元素的召唤2/土元素25/迅捷波101/治疗链等级102-104/风剪17/净化灵魂71）。
【防护】2026-11-16（按猪猪 / 彼岸花-无限服防战页同步防护功能与循环）
- 用户口径：图片为防护战专精；当前客户端 60 级天赋与技能；按图匹配功能并移除 80 级旧开关，界面仍走 MK 面板，不污染武器/狂怒与其他职业。
- Warrior_Protection_Features.lua：默认值对齐截图——雷霆一击多目标默认「不放」、单体「保持」；挫志怒吼只保留 保持/不放 两档且多目标/单体默认「不放」；格挡额外条件默认勾「多目标(2个)+卡CD」、血量不勾；破甲攻击「只打1破/高优先级/低优先级」默认全不勾（普通优先位），只打1破补充「目标快死时不放」；撕裂/血性狂暴/切姿态默认值与截图一致；右键小窗文案同步截图（含宏命令 /WARRIOR_REND、/WARRIOR_SUNDER、/WARRIOR_BLOODRAGE、/WARRIOR_THUNDER_DEMO、/WARRIOR_STANCE、/WARRIOR_SHIELDBLOCK）。
- Warrior_Menu.lua：防护页 DM 移除 怒吼/狂怒回复/自动盾墙/输出循环 旧项，只保留 防ADD + 顺劈斩30/英勇打击20/乘胜追击70/破釜沉舟20/喝红药30/打断60；自动组移除 英勇投掷/自动缴械；爆发组收敛为 全开/全关/切换 按钮 + 种族爆发（FZ_KG_ZDZZ）；插入组移除 碎裂投掷/缴械，保留 反击/震荡/挑战/盾墙/挫志怒吼/拦截/惩戒痛击/狂暴之怒 八项。
- Warrior_Forever_Protection.lua：下线 80 级遗留逻辑（自动盾墙、英勇投掷、缴械插入、狂暴之怒自动解控）；新增种族爆发步（宏 181，与狂怒同一 WR_Forever_GetRacialBursts 口径）；破甲 攻击按 只打1破/高优先/低优先/续破 四档接入循环。
- 命令分流修复：防护最后加载，共享命令直接捕获当前处理函数作为回落（不再写 WR_WarriorSharedCommandPrev），修复防护注册后狂怒专精 /WARRIOR_REND 会回落到武器战变量的问题。
- 验证：test_warrior_prot_rotation.py 22 项、test_warrior_prot_menu.py、test_warrior_prot_commands.py 10 项新增，狂怒 27 项 / 武器 45 项回归全过；全量 Lua 语法检查通过。
【狂怒】2026-11-16（按猪猪 / 彼岸花-无限服狂暴页重做狂怒功能与循环）
- 用户口径：图片为狂暴战专精；当前客户端 60 级天赋与技能；按图匹配功能并移除 80 级旧开关，界面仍走 MK 面板，不污染武器/防护与其他职业。
- Warrior_Fury_Features.lua：右键「额外条件」小窗对齐截图（撕裂/雷霆挫志/血性狂暴/破甲攻击/切姿态/鲁莽挥击均带顶层开关）；破甲攻击默认关闭，只打1破/高优先级/低优先级默认关闭；挫志怒吼按截图只保留保持/不放两档；新增 /WARRIOR_REND、/WARRIOR_SUNDER_DPS、/WARRIOR_BLOODRAGE、/WARRIOR_THUNDER_DEMO、/WARRIOR_STANCE 命令，与武器战按专精分流不互相覆盖。
- Warrior_Menu.lua：狂怒页按截图收敛为 8 个功能图标 + 3 个爆发开关（鲁莽/死愿/种族爆发）+ 3 个插入图标，移除速度药水/偷药/工程手套/饰品等 80 级遗留开关；破甲攻击默认不勾。
- Warrior_Forever_Fury.lua：切换目标默认开启；脱战切战斗补充「防御姿态 + 天赋先锋」豁免。
- 验证：test_warrior_fury_rotation.py 27 项、test_warrior_fury_menu.py、test_warrior_fury_ui.py、test_warrior_fury_commands.py 11 项全过；全量 Lua 语法检查通过。
【防骑】2026-11-16（修复 Paladin_Forever_Prot.lua:1799 attempt to call a nil value：EUI 严格表读取导致整文件加载中断）
- 用户报错：防护循环反复在 Paladin_Forever_Prot.lua:1799 报 attempt to call a nil value，局部变量 FH_QJS / priority / FH_QJS_Player / FH_QJS_Target。
- 根因：Paladin_Forever.lua 的 WR_PaladinForever_EUI_Install 读取 EllesmereUI._pabInternals.__WR_PaladinCleanseSetter。_pabInternals 由 NewInternals 生成，未登记字段的读取会走 __index 直接 error（不是返回 nil）；而该 install 是文件级调用，一抛错 Paladin_Forever.lua 从该行起后续全部未加载，CleanseStep / Seal / SpellKnown / UnitHasDispel 等全部变成 nil。
- 修复：EUI / _pabInternals 的所有字段读取改用 rawget（不改 EllesmereUI 文件）；文件级 install 与 ADDON_LOADED 重试均包 pcall，任何 EUI 版本差异都不再中断 Paladin_Forever.lua 的剩余函数定义。
- 验证：新增 .workbuddy/test_paladin_eui_load.py 12 项全过（strict _pabInternals / AuraKit hook / 无 EUI / 全异常 EUI 四种场景）；清洁术三套夹具与全量 Lua 语法检查通过。
【生存】2026-11-16（按猪猪 / 彼岸花-无限服生存页重做生存猎功能与循环）
- 用户口径：图片为生存猎专精；当前客户端 60 级天赋与技能；按图匹配功能并移除 80 级旧开关，界面仍走 MK 面板，不污染兽王/射击与其他职业。
- 新增 Hunter/Hunter_Survival_Features.lua（登记进 TOC）：生存默认值/旧档迁移（LR_SCL_DCMZ 旧「1=多重/2=瞄准」→ 新「共享冷却 1=瞄准/2=多重」、LR_SC_ZHBB 召唤宠物下拉→开关、LR_SC_FHCW_ZD→复活模式、LR_SCL_ZDLRYJ→只打首领、LR_SCL_CRBSXJ→冰冻陷阱）；功能 5 项（远程技能/近战技能/宠物/印记/切换目标），右键「额外条件」小窗 5 个（远程技能：震荡/毒蛇/奥术/瞄准/多重/狙击 + 毒蛇不打机械/预判7秒；近战技能：反击/猫鼬撕咬/陆行鸟踢击/摔绊/猛禽一击；宠物：召唤/无脑复活或脱战复活/脱战治疗50%；印记：只打首领；急速：只打首领）；拉条 喝红药30%；爆发 急速/种族爆发 + 全开/全关/切换；插入 献祭/冰冻/冰霜/震荡/扰乱/治疗/急速/照明/乱射/爆炸陷阱/假死（一次性放完自关）。
- 重写 Hunter/Hunter_Forever_SV.lua（仅 Forever 生存）：宠物维护 → 切换目标 → 自动射击 → 防ADD门 → 守护 → 插入 → 喝红药 → 猎人印记 → 爆发 → 远程技能 → 近战技能；移除杀戮射击/杀戮命令/眼镜蛇射击/奇美拉射击/稳固射击/爆炸射击/黑箭/削砍等 80 级/SoD 技能。
- Hunter_Menu.lua 生存页按截图重做：防ADD / 共享冷却下拉、喝红药拉条、爆发三按钮、功能 5 复选框、插入 11 项（献祭/冰冻/冰霜/震荡/扰乱/治疗/急速/照明/乱射/爆炸陷阱/假死）。
- Hunter_Macros.lua：SV 天赋「陆行鸟踢击」替换旧「长足踢击」宏文本（槽 96），WR_SkillColor 新增「陆行鸟踢击」=96（旧名保留兼容）；近战反击=101 / 猫鼬=106 / 猛禽=107 / 摔绊=79 沿用。
- 验证：test_hunter_sv_rotation.py / test_hunter_sv_menu.py / test_hunter_sv_ui.py / test_hunter_sv_migration.py / test_hunter_shared_cmd.py 全过；全量 Lua 语法检查通过。
【冰霜】2026-11-16（按猪猪 / 彼岸花-无限服冰霜页重做冰法专精功能与循环）
- 用户口径：图片为冰法专精；当前客户端 60 级天赋与技能；按图匹配功能并移除 80 级旧开关，界面仍走 MK 面板，不污染奥法/火法与其他职业。
- 新增 Mage/Mage_Frost_Features.lua（登记进 TOC）：冰法默认值/旧档迁移（FADD_BF→BF_FADD、BF_ZDZZ→BF_ZZ、BF_JCZZ*/BF_ZDFSTQ→BF_QS*、BF_BFX_CR→BF_CRBFX）；功能 6 项（读条引导/护甲/奥术智慧/切换目标/驱散/寒冰护体），右键「额外条件」小窗 4 个（读条引导：炎爆术-火焰/灼烧/寒冰箭/霜火之箭/火球术 + 移动中冰枪填充；护甲：冰甲术/魔甲术二选一；奥术智慧：自己/小队；驱散：自己/小队/法术偷取）；拉条 喝红药30%/打断60%/魔杖回蓝50%/奥爆关闭；爆发 种族爆发 + 全开/全关/切换；插入 冰环/烈焰风暴/暴风雪/魔爆术/闪现/寒冰屏障/寒冰护体（一次性放完自关）。
- 重写 Mage/Mage_Forever_Frost.lua（仅 Forever 冰霜）：停手门 → 插入 → 喝红药 → 护甲 → 奥术智慧 → 切换目标 → 防ADD门 → 打断 → 驱散 → 种族爆发 → 寒冰护体保持 → 唤醒 → 奥爆 → 读条引导（炎爆术→灼烧→寒冰箭→霜火之箭→火球术 + 冰枪填充，本地 CD 记账）→ 魔杖回蓝 → 清色块；移除狂咒/镜像/冰冷血脉/法力宝石/隐身术/深冻/寒冰宝珠/召唤水元素等 80 级/SoD 技能。
- Mage_Forever.lua：冰霜防ADD改读 BF_FADD（旧 FADD_BF 兼容）；MAGE_CAST / MAGE_ARMOR_ON / MAGE_INTELLECT / MAGE_QS 命令分流表新增「冰霜」专精，三系互不覆盖。
- Mage_Menu.lua 冰霜页按截图重做：防ADD 下拉、喝红药/打断/魔杖回蓝/奥爆拉条、爆发三按钮、功能 6 复选框（含寒冰护体）、插入 7 项（冰环/烈焰风暴/暴风雪/魔爆术/闪现/寒冰屏障/寒冰护体）。
- 离线夹具：test_mage_frost_rotation.py / test_mage_frost_ui.py / test_mage_frost_migration.py / test_mage_shared_cmd.py（冰霜加入分流表）。
【火焰】2026-11-16（按猪猪 / 彼岸花-无限服火法页重做火焰专精功能与循环）
- 用户口径：图片为火法专精；当前客户端 60 级天赋与技能；按图匹配功能并移除 80 级旧开关，界面仍走 MK 面板，不污染奥术/冰霜与其他职业。
- 新增 Mage/Mage_Fire_Features.lua（登记进 TOC）：火法默认值/旧档迁移（FANG_ADD_HUOFA→HY_FADD、HY_HQS→HY_CAST_FIREBALL/HY_CAST_FROSTFIRE、HY_ZDRS→HY_ZD_RS、HY_JCZZ*→HY_QS*、HY_ZDFSTQ→HY_QS_STEAL）；功能 5 项（读条引导/护甲/奥术智慧/切换目标/驱散），右键「额外条件」小窗 4 个（读条引导：炎爆术-火焰/灼烧/霜火之箭/火球术/寒冰箭；护甲：冰甲术/魔甲术二选一；奥术智慧：自己/小队；驱散：自己/小队/法术偷取）；拉条 喝红药30%/打断60%/魔杖回蓝50%/奥爆关闭；爆发 燃烧/种族爆发 + 全开/全关/切换；插入 冰环/烈焰风暴/暴风雪/魔爆术/闪现/冲击波（一次性放完自关）。
- 重写 Mage/Mage_Forever_Fire.lua（仅 Forever 火焰）：停手门 → 插入 → 喝红药 → 护甲 → 奥术智慧 → 切换目标 → 防ADD门 → 打断 → 驱散 → 爆发 → 唤醒 → 奥爆 → 读条引导（炎爆术→灼烧→霜火之箭→火球术→寒冰箭，本地 CD 记账）→ 魔杖回蓝 → 清色块；移除活动炸弹/镜像/冰冷血脉/法力宝石/法术连击等 80 级/SoD 技能。
- Mage_Forever.lua：火焰防ADD改读 HY_FADD（旧 FANG_ADD_HUOFA 兼容）；MAGE_CAST / MAGE_ARMOR_ON / MAGE_INTELLECT / MAGE_QS 命令按专精分流，奥法与火法互不覆盖。
- 验证：新增 test_mage_fire_rotation.py / test_mage_fire_ui.py / test_mage_fire_migration.py 离线夹具全过；全量 Lua 语法检查通过。

【奥法】2026-11-16（按猪猪 / 彼岸花-无限服奥法页重做奥术专精功能与循环）
- 用户口径：图片为奥法专精；当前客户端 60 级天赋与技能；按图匹配功能并移除 80 级旧开关，界面仍走 MK 面板，不污染火焰/冰霜与其他职业。
- 新增 Mage/Mage_Arcane_Features.lua（登记进 TOC）：奥法默认值/旧档迁移（AF_ASQH→AF_ZDASQH、AF_JCZZ*→AF_QS*、AF_ZDFSTQ→AF_QS_STEAL）；功能 5 项（读条引导/护甲/奥术智慧/切换目标/驱散），右键「额外条件」小窗 4 个（读条引导：打法叠加/无脑/奥术愤怒、叠层层数 0 层、愤怒层数 4 层、蓝量 40%、有节能就打、奥术冲击/奥术飞弹/寒冰箭/霜火之箭/火球术；护甲：冰甲术/魔甲术二选一；奥术智慧：自己/小队；驱散：自己/小队/法术偷取）；拉条 喝红药30%/打断60%/魔杖回蓝50%/奥爆关闭；爆发 奥术强化/气定神闲/种族爆发 + 全开/全关/切换；插入 冰环/烈焰风暴/暴风雪/魔爆术/闪现（一次性放完自关）。
- 重写 Mage/Mage_Forever_Arcane.lua（仅 Forever 奥术）：停手门 → 插入 → 喝红药 → 护甲 → 奥术智慧 → 切换目标 → 防ADD门 → 打断 → 驱散 → 爆发 → 奥爆 → 读条引导（叠加/无脑/奥术愤怒，本地 CD 记账）→ 魔杖回蓝 → 清色块；移除奥术弹幕/奥术涌动/法力宝石/镜像/冰冷血脉等 80 级/SoD 技能。
- Mage_Macros.lua：新增 106 冰甲术 / 107 魔甲术 / 108 奥术智慧 / 109 奥术智慧(队友) / 110 奥术愤怒 / 111 治疗药水 / 112 解除次级诅咒 / 113 解除次级诅咒(队友) 宏槽与 WR_SkillColor 映射（含霜火之箭 20 / 烈焰风暴 23 / 闪现 31 / 法术反制 46 / 法术吸取 43 / 切换目标 40）。
- 验证：新增 test_mage_arcane_rotation.py 49 项、test_mage_arcane_ui.py 面板与 4 个右键小窗全过；全量 Lua 语法检查通过。

【射击】2026-11-16（按猪猪 / 彼岸花-无限服射击页重做射击猎功能与循环）
- 用户口径：图片为射击猎专精；当前客户端 60 级技能与天赋；按图匹配功能并移除 80 级旧开关，界面仍走 MK 面板，不污染兽王/生存与其他职业。
- 新增 Hunter/Hunter_Marksmanship_Features.lua（登记进 TOC）：射击默认值/旧档迁移（LR_SJL_DCMZ 旧「1=多重/2=瞄准」→ 新「共享冷却 1=瞄准/2=多重」、LR_SJ_ZHBB 召唤宠物下拉→开关、LR_SJ_FHCW_ZD→复活模式、LR_SJL_ZDLRYJ→只打首领、LR_SJL_CRBSXJ→冰冻陷阱）；功能 6 项（远程技能/近战技能/宠物/印记/切换目标/强击），右键「额外条件」小窗 6 个（远程技能：震荡/毒蛇/奥术/瞄准/多重/召唤雄鹰/狙击 + 毒蛇不打机械/预判7秒；近战技能：猫鼬撕咬/摔绊/猛禽一击；宠物：召唤/无脑复活或脱战复活/脱战治疗50%；印记：只打首领；急速：只打首领；强击：强击光环）；拉条 喝红药30%；爆发 急速/种族爆发 + 全开/全关/切换按钮；插入 献祭陷阱/冰冻陷阱/冰霜陷阱/震荡射击/扰乱射击/治疗宠物/急速射击/照明弹/乱射/爆炸陷阱/假死（一次性放完自关）。
- 重写 Hunter/Hunter_Forever_MM.lua（仅 Forever 射击）：宠物维护（脱战召唤/复活/治疗）→ 切换目标 → 自动射击 → 防ADD门 → 守护 → 强击光环 → 插入 → 喝红药 → 猎人印记 → 爆发 → 远程技能（毒蛇→召唤猎鹰→奥术→瞄准/多重共享冷却二选一→狙击→震荡）→ 近战技能（猫鼬→摔绊→猛禽）；「共享冷却」下拉 1=瞄准射击/2=多重射击。
- 移除 80 级/无限不存在技能开关：杀戮射击/杀戮命令/眼镜蛇射击/奇美拉射击/稳固射击/爆炸射击填充/准备就绪/沉默射击/偷药/速度药水/饰品/手套/炸弹/蝰蛇舞/杀戮停等旧项全部下线（旧档由功能层迁移）。
- 验证：新增 test_hunter_mm_rotation.py / test_hunter_mm_menu.py / test_hunter_mm_ui.py / test_hunter_mm_migration.py 离线夹具全过；全量 Lua 语法检查通过。

【全局】2026-11-16（色块增加黑色保护底色：防游戏背景色误识别）
- 用户口径：MK 插件目前没有色块保护底色，游戏中的背景颜色会导致脚本误识别；需要在色块出现的位置添加黑色底色，防止识别到其他颜色。
- 实现（Core/UI_ColorFrame.lua）：左上/右上两个色块定位锚点各挂一张纯黑 BACKGROUND 纹理（左上常驻；右上在该侧首次出现色块时亮起并常驻），不随 WR_HideColorFrame 隐藏；锚点 FrameLevel=0，所有色块 FrameLevel=2，实色块永远压在黑底之上。
- 覆盖范围：保护底色比 42×42 色块区向外扩 2px（46×46），覆盖 AHK 主采样点 (1,1) 与备用采样点 (8,8)/(21,21)/(34,34)/(8,34)/(34,8)；色块未点亮时全部采样点读黑，不会再匹配到任何技能颜色。
- 不变项：ColorTable 240 个颜色值、槽位映射、WR_ShowColorFrame/WR_HideColorFrame 显隐逻辑全部不变，AHK 侧颜色表无需改动。
- 验证：新增 .workbuddy/test_color_guard.py（G1~G8）通过；全量 Lua 语法检查通过。

【防骑】2026-11-16（清洁术再复查：脱战诅咒不触发，战斗内可驱散类型要能触发）
- 用户口径：截图「荆棘诅咒」法术ID 6909；脱战后仍会用清洁术；战斗中魔法/疾病/中毒反而不用清洁术。
- 根因：① 只看 DebuffFrame / 只读 C_UnitAuras 的旧路径在部分 UI（或 secret 战斗态）下拿不到真实类型，隐藏按钮/旧缓存还保留旧毒图集；② canActivePlayerDispel 在部分客户端会把诅咒误报为 true；③ 之前 AurasRestricted() 一律提前判无，导致战斗中可驱散类型也不亮。
- 修复：① 新增 WR_PaladinForever_ScanUnitDebuffTypes，交叉读取 C_UnitAuras / UnitDebuff / UnitAura；名称含「诅咒/Curse」或 spellID 6909 直接判不可驱散；② 多 API 扫描优先于 DebuffFrame，DebuffFrame 只作为回退；③ DebuffFrame 只在帧可见且确实扫到条目时判无，隐藏帧/被其他 UI 接管不再误判；④ AuraData 先读 dispelName/dispelType，secret 时不信任 canActivePlayerDispel=true；⑤ 战斗内 UnitDebuff/UnitAura 可读时不因 AurasRestricted 一律判无；⑥ 新增 EllesmereUI Player Aura Bars 桥接：捕获其 debuffsContainer，扫描自定义 AuraButton 的引擎 dispel 纹理/颜色，处理 EUI 替代 Blizzard BuffFrame 后读不到类型的情况。
- 回归：test_paladin_cleanse_combat.py 新增 J27-J32（UnitDebuff Poison 可用、荆棘诅咒 6909 名称/ID、canActivePlayerDispel 误报、spellId 6909、EUI dispel 图集 Magic/Curse）；三个清洁术夹具全过；全部 35 个圣骑士夹具与全量 Lua 语法通过。

【兽王】2026-11-16（按猪猪 / 彼岸花-无限服兽王页重做兽王猎功能与循环）
- 用户口径：图片为兽王猎专精；当前客户端 60 级技能与天赋；按图匹配功能并移除 80 级旧开关，界面仍走 MK 面板，不污染射击/生存与其他职业。
- 新增 Hunter/Hunter_BeastMastery_Features.lua（登记进 TOC）：兽王默认值/旧档迁移（LR_SWL_DCMZ 旧「瞄准or多重」→「共享冷却」1=瞄准/2=多重、LR_SW_ZHBB 召唤宠物下拉→开关、LR_SW_FHCW_ZD→复活模式、LR_SWL_ZDLRYJ→印记只打首领）；功能 5 项（远程技能/近战技能/宠物/印记/切换目标），右键「额外条件」小窗 6 个（远程技能：震荡/毒蛇/奥术/瞄准/多重/召唤雄鹰/狙击 + 毒蛇不打机械/预判7秒；近战技能：猫鼬撕咬/摔绊/猛禽一击；宠物：召唤/无脑复活或脱战复活/脱战治疗50%；印记：只打首领；急速/狂野：只打首领）；拉条 喝红药30%；爆发 急速/狂野/种族爆发 + 全开/全关/切换按钮；插入 献祭陷阱/冰冻陷阱/冰霜陷阱/震荡射击/扰乱射击/治疗宠物/急速射击/照明弹/乱射/胁迫/狂野怒火/爆炸陷阱/假死（一次性放完自关）。
- 重写 Hunter/Hunter_Forever_BM.lua（仅 Forever 野兽控制）：宠物维护（脱战召唤/复活/治疗）→ 切换目标 → 自动射击 → 防ADD门 → 守护 → 插入 → 喝红药 → 猎人印记 → 爆发 → 远程技能（毒蛇→召唤猎鹰→奥术→瞄准/多重共享冷却二选一→狙击→震荡）→ 近战技能（猫鼬→摔绊→猛禽）；「共享冷却」下拉 1=瞄准射击/2=多重射击。
- 移除 80 级/无限不存在技能开关：杀戮射击/杀戮命令/眼镜蛇射击/奇美拉射击/稳固射击/爆炸射击填充/偷药/速度药水/饰品/手套/炸弹/蝰蛇舞/杀戮停等旧项全部下线（旧档由功能层迁移）。
- Hunter_Macros.lua：新增 105 治疗药水 / 106 猫鼬撕咬 / 107 猛禽一击 / 108 献祭陷阱 / 109 照明弹 / 110 冰冻陷阱 / 111 爆炸陷阱 宏槽与 WR_SkillColor 映射（种族爆发复用既有 181 宏）。
- 验证：新增 test_hunter_bm_rotation.py / test_hunter_bm_menu.py / test_hunter_bm_ui.py 离线夹具全过；全量 Lua 语法检查通过。

【防骑】2026-11-16（复查清洁术：诅咒绝不再触发清洁术）
- 用户口径：清洁术只能驱散疾病 / 中毒 / 魔法，不能驱散诅咒；实战中中了诅咒后会不断使用清洁术。
- 根因一：WR_PaladinForever_PlayerDebuffDispelByBlizzardFrame 旧兜底「secret debuffType + 无边框 = 可驱散」，诅咒的 debuffType 在战斗中同样是 secret，读不到图集时被误判为可驱散。
- 根因二：DebuffBorder 扫描遍历所有 auraFrames（含隐藏按钮），隐藏按钮保留上一次的中毒图集，会把旧毒图集当成本次诅咒的证据。
- 根因三：WR_PaladinForever_ProbeDispellableByFilter 只要 HARMFUL|RAID 有槽位就返回 true，存在性判断会把诅咒算进来。
- 根因四：旧 SoD 路径 Paladin_Holy / Paladin_Protection / Paladin_Retribution 仍用 WR_GetUnitDebuffTime("player", "诅咒") 判驱散。
- 修复：① 删除「secret 类型 = 可驱散」兜底，类型读不到一律返回 nil，绝不猜；② DebuffBorder 只扫描 IsVisible()/IsShown()==true 的按钮，隐藏按钮旧图集不再参与；③ 探针改为读 AuraData 的 canActivePlayerDispel / dispelName，只有明确 Poison/Disease/Magic 才返回 true，明确 Curse/Bleed 返回 false，其余 nil；④ NormalizeDispelType 补 Bleed/流血；⑤ 旧 SoD 三文件移除诅咒条件。
- 回归：test_paladin_cleanse.py / test_paladin_cleanse_dispeltype.py / test_paladin_cleanse_combat.py 全过（含 J21 隐藏旧毒图集 + 可见诅咒、J22 过滤器返回诅咒 AuraData、J24 过滤器返回 Poison AuraData）；全量 Lua 语法 207/207。

【戒律】2026-11-16（戒律牧功能层接入 TOC）
- 用户口径：戒律牧功能层从未接入 TOC，这一步先做。
- MKHelperForever.toc 在 Priest\Priest_Forever_Discipline.lua 之后追加 Priest\Priest_Forever_Discipline_Features.lua，保证功能层加载时 WR_PriestForeverDiscipline 已存在并可被 hook。
- 功能层内 301~304 历史越界回退槽按当前 Priest_Macros.lua 改为 23/149/49/56（ColorTable 仅 1-240）。
- 验证：新增 .workbuddy/test_priest_discipline_features_load.py（T1~T5）通过；test_priest_discipline_focus.py 回归通过；全量 Lua 语法 207/207。

【修复】2026-11-16（全项目静态审计：色块槽位越界 / 错键与宏绑定）
- 用户口径：阅读整个项目，修复能确认的损坏、不一致与低效项，其余列清单复核。
- 色块槽位越界（ColorTable 仅 1-240，越界会让 PIG_BGRtoBGR(nil) 抛错并崩掉整个循环 tick）：Priest 心灵专注/能量灌注/神圣新星/联结治疗/吸血鬼的拥抱/沉默/暗影形态 301-307 → 23/149/49/56/10/80/8；Rogue 冷血/淬毒/还击/剑刃乱舞/冲动/幽魂击/预谋/伺机待发/出血 301-309 → 1/54/59/60/37/64/40/47/33；Shaman 先知之怒/水之护盾/法力之潮图腾/自然迅捷 301-304 → 61/22/83/74。
- 错键修复：Priest 守护之魂 187（萨隆邪铁炸弹）→64；Shaman 火元素图腾 116（SHIFT-- 设焦点）→59、漩涡武器 120（/target 瓦拉纳王子）→4；Druid 裂伤 137（/focus raid17）→8（新增裂伤(熊)=30）、痛击 144（/focus raid24）→197（新增宏）、横扫 143（/focus raid23）→11；Warrior 狂暴之怒(解控) 58 空槽→11、迅捷打击 70（/focus 双子）→77（新增宏）、鞭笞 59 空槽补宏、攻击 4 /stopattack→/startattack；Rogue 要害打击/军刀猛刺/剔骨 156/154/160（/focus raidN）→71/72/73（新增宏）；Paladin 治疗药水 75（[@focus] 庇护祝福）→79（新增药水宏）、复仇之怒 28（制裁之锤）→32。
- 防御闸：WR_ColorFrame_ShowSkill / WR_ColorFrame_Show 对 1-240 之外的数值统一拦截并熄灭残留色块，任何职业再遇越界槽都不会崩 tick。
- 卫生：删除 Menu_Healer_TOC 的 Monk_Menu 死引用；/mkfear 对未定义的 WR_FZ_KBZN 加守卫。

【恢复】2026-11-16（按彼岸花-无限服恢复页重做恢复德功能与循环）
- 用户口径：图片为恢复德（奶德）专精；当前客户端 60 级技能与天赋；按图匹配功能并移除 80 级旧开关（生命绽放/滋养/野性赐福/治疗之树/起死回生/树皮术/旋风/狂咒/血肉成灰/无脑回春/99%回春/偷药/爆发手套饰品/过量停条等），界面仍走 MK 面板，不污染其他专精与职业。
- 新增 Druid/Druid_Restoration_Features.lua（登记进 TOC）：恢复默认值/旧档迁移（HF_QS 驱散下拉→HF_QS_ON 开关、HF_YH 愈合模式→HF_YH_HP 阈值、HF_JH→HF_JH_HP、HF_NJ_HP→HF_NJ_CR）；选择 防ADD/治疗模式（全团/目标/预读/坦克/脆皮/一~五队）；拉条 喝红药30%/迅捷治触30%/迅捷治愈50%/野性成长80%/回春术95%/治疗之触60%/愈合85%；功能 6 项（野性印记/复生/激活/荆棘术/切换目标/驱散）；爆发 种族爆发 + 全开/全关/切换按钮；插入 宁静（一次性放完自关）；激活右键阈值小窗。
- 重写 Druid/Druid_Forever_Restoration.lua（仅 Forever 恢复）：停手门 → 野性印记/荆棘术/复生/激活/驱散 → 插入宁静 → 喝红药 → 切目标 → 防ADD门 → 种族爆 → 迅捷治触（自然迅捷+治疗之触）→ 迅捷治愈 → 野性成长 → 回春术 → 治疗之触 → 愈合（焦点宏施放）；共享件 Druid_Forever.lua 零改动。
- 宏表/色表：迅捷治愈 307（越界）→ 111、自然迅捷 308（越界）→ 112，新增「迅捷治触」=112；其余复用现有宏槽（回春术109/愈合110/治疗之触104/野性成长107/宁静64/激活93/103/复生13/野性印记149/荆棘术150/切目标46/种族爆发181）。
- 移除 80 级/SoD 技能引用：生命绽放/滋养/野性赐福/治疗之树/起死回生/树皮术/旋风/狂咒/血肉成灰等本服 60 级不存在技能不再出现在面板与循环。
- 验证：新增 .workbuddy/test_druid_restoration_rotation.py / test_druid_restoration_menu.py / test_druid_restoration_ui.py 离线夹具全过；全量 Lua 语法检查通过。

【野性】2026-11-16（按彼岸花-无限服野性页重做野德功能与循环）
- 用户口径：图片为野德（野性）专精；当前客户端 60 级技能与天赋；按图匹配功能并移除 80 级旧开关（寒霜刺骨/愈合/打断/2T5/偷药/速度药水/炸弹/自动横扫/屏蔽横扫/强制横扫/锁BOSS/工程手套/解定身/插入猫/搭脉等），界面仍走 MK 面板，不污染其他专精与职业。
- 新增 Druid/Druid_Feral_Features.lua（登记进 TOC）：野性默认值/旧档迁移（YD_MHZN 布尔→YD_MHZN_NL 能量阈值、YD_ZMLS→YD_ZM、YD_CAT_CAT_AUTO→YD_BX、YD_JH→YD_JH_HP）；功能 15 项（变形/切换目标/精灵之火 + 猫专属 扫击/终结技/变形之力/正面 + 熊专属 挫志咆哮/挥击/割伤/嘲讽/野性印记/复生/激活/荆棘术）；拉条 喝红药30%/猛虎之怒30%/槌击25%/狂暴回复40%；爆发 狂暴+种族爆发 + 全开/全关/切换按钮；插入 冲锋/群嘲/重击（一次性放完自关）。
- 重写 Druid/Druid_Forever_Feral.lua（仅 Forever 野性）：停手门 → 变形 → 野性印记/荆棘术/复生/激活 → 插入 → 喝红药 → 切目标 → 防ADD门 → 狂暴/种族爆 → 猫：精灵之火→猛虎之怒→变形之力→斜掠→割裂→凶猛撕咬→扫击→撕碎/爪击；熊：狂暴回复→挫志咆哮→割伤→挥击→槌击→嘲讽；共享件 Druid_Forever.lua 零改动。
- 宏表：194 变形之力 / 195 低吼 / 196 野性冲锋 三个空槽启用；色表补 猛虎之怒=2、变形之力=194、低吼=195、野性冲锋=196、挫志咆哮=79、割伤=31、重击=51、挥击=53、扫击=57、槌击=52、精灵之火（野性）=10、狂暴=3。
- 移除 80 级/SoD 技能引用：野蛮咆哮/割碎/痛击/重殴/横扫（豹/熊）/寒霜刺骨/狂咒等本服 60 级不存在技能不再出现在面板与循环。
- 验证：新增 .workbuddy/test_druid_feral_rotation.py / test_druid_feral_menu.py / test_druid_feral_ui.py 离线夹具全过；全量 Lua 语法检查通过。

【防骑】2026-11-16（祝福段勾选互相独立：仅勾「个人」时个人所选祝福生效）
- 用户口径：防骑在小队中，祝福设置里不勾「小队」、只勾「个人」并选好特定祝福时，实际施放没有应用个人所选 buff。
- 根因：Paladin/Paladin_Blessing.lua 的 WR_PaladinBlessing_Auto() 按当前队伍状态整体短路——mode=="party" 且 c.party~=true 时直接 return false，把「单人（个人）」段也一并挡掉；团队段关闭同理。
- 修复：段勾选改为只控制该段目标是否参与本轮；单人段（自己）独立生效并保持第一优先，小队/团队段按各自勾选追加目标。仅勾个人时个人所选祝福正常点亮（小队内为普通祝福自施槽 91~93，团队内按团队口径强效祝福）。
- 验证：test_paladin_blessing.py 新增 T1~T6 回归段（小队关闭+个人开、个人关闭+小队开、团队关闭+个人开、静态接线）全过；全部祝福相关夹具与全量 Lua 语法检查通过。

【平衡】2026-11-15（按彼岸花-无限服平衡页重做平衡德功能与循环）
- 用户口径：图片为鸟德（平衡）专精；当前客户端 60 级技能与天赋；按图匹配功能并移除 80 级旧开关（狂咒 / ICC 统御心灵旋风 / 麻痹诅咒 / 虫群月火三连 / 轨道炮 / 星辰坠落 / 自然之力 / 台风 / 树皮插入等），界面仍走 MK 面板，不污染其他职业。
- 新增 Druid/Druid_Balance_Features.lua（登记进 TOC）：平衡默认值/旧档迁移（PH_JCZZ、PH_JCWR_P→PH_QS；PH_JH/PH_JH_PLAYER→PH_JH_HP）；功能 8 项（枭兽形态、DOT 月火/虫群右键预判、野性印记、复生、激活右键阈值、荆棘术、切换目标、驱散）；拉条 喝红药30%；爆发 种族爆发 + 全开/全关/切换按钮；插入 飓风（一次性放完自关）；右键「额外条件」小窗 2 个。
- 重写 Druid/Druid_Forever_Balance.lua（仅 Forever 平衡）：停手门 → 枭兽/野性印记/荆棘术/复生/激活/驱散 → 插入 → 喝红药 → 切目标 → 防ADD门 → 种族爆 → 飓风AoE → 月火/虫群 DOT → 星涌术 → 星火术/愤怒 → 清扫；共享件 Druid_Forever.lua 零改动。
- 宏表：新增 149 野性印记 / 150 荆棘术 / 193 治疗药水 宏槽，86 原月神轨道炮改 星涌术；WR_SkillColor 原 301/302 越界槽改为真实 19/16，星涌术 132（原为 /focus raid12）改 86，并登记 切目标=46、种族爆发=181、复生=13、激活=93。
- 移除 80 级/SoD 技能引用：星落 / 月神轨道炮 / 星辰坠落 / 阳炎术 / 自然之力 / 台风 / 树皮术插入等本服 60 级不存在技能不再出现在面板与循环。
- 验证：新增 .workbuddy/test_druid_balance_rotation.py / test_druid_balance_menu.py / test_druid_balance_ui.py 离线夹具全过；全量 Lua 语法检查通过。

【毁灭】2026-11-15（按猪猪-无限服毁灭页重做毁灭术功能与循环）
- 用户口径：图片为毁灭术专精；当前客户端 60 级技能与天赋；按图匹配功能并移除 80 级旧开关（狂咒/邪甲/武器石/暗影烈焰/腐蚀之种/厄运诅咒/地狱火/灵魂碎裂/TOC一键恐惧等），界面仍走 MK 面板，不污染痛苦/恶魔与其他职业。
- 新增 Warlock/Warlock_Destruction_Features.lua（登记进 TOC）：毁灭默认值/旧档迁移（SS_HM_HJ 护甲下拉→恶魔皮肤/魔甲术二选一、SS_HM_AUTOSUMMON→四宠多选勾）；DOT 右键小窗（腐蚀术/献祭/生命虹吸 + 灾祸痛苦/末日2选1 + 诅咒元素/虚弱/鲁莽/语言/疲劳5选1，预判秒数）；读条引导右键小窗（引导：吸取灵魂预判5秒+目标血量10%、吸取生命无脑/看血量50%；读条：烧尽 → 暗影箭填充）；护甲右键（默认魔甲术）；召唤宠物右键（小鬼/虚空行者/魅魔/地狱猎犬）；切换目标；暗灼（暗影灼烧 <20% 斩杀）；拉条（生命分流30%/高血分流80%/喝红药30%/魔杖回蓝50%）；种族爆全开/全关/切换按钮；插入 浩劫诅咒/死亡缠绕/恐惧术/恐惧嚎叫/地狱烈焰/火焰之雨/生命通道/生命分流（一次性放完自关）。
- 重写 Warlock/Warlock_Forever_Destruction.lua（仅 Forever 毁灭）：停手门 → 插入 → 自保 → 护甲 → 召唤宠物 → 切目标 → 防ADD门 → 种族爆 → 拉条 → DOT → 燃烧 → 暗灼 → 读条引导 → 魔杖兜底 → 清扫；共享件 Warlock_Forever.lua 零改动。
- 宏：/WARLOCK_DOT、/WARLOCK_CAST、/WARLOCK_SUMMON、/WARLOCK_ARMOR（与痛苦共用注册，按当前专精派发）；宏表槽位 78 由旧「暗影烈焰」改「浩劫诅咒」，色表补 暗影灼烧=54、浩劫诅咒=78。
- 验证：新增 .workbuddy/test_warlock_destr_rotation.py / test_warlock_destr_menu.py / test_warlock_destr_ui.py 离线夹具全过；全量 Lua 语法检查通过。

【痛苦】2026-11-15（按彼岸花-无限服痛苦页重做痛苦术功能与循环）
- 用户口径：图片为痛苦术专精；当前客户端 60 级技能与天赋；按图匹配功能并移除 80 级旧技能（痛苦无常/鬼影缠身/腐蚀之种/痛苦诅咒/厄运诅咒/地狱火/灵魂碎裂/暗影烈焰/烧尽/混乱之箭），界面仍走 MK 面板，不污染恶魔/毁灭与其他职业。
- 新增 Warlock/Warlock_Affliction_Features.lua（登记进 TOC）：痛苦默认值/旧档迁移（SS_TK_HJ 护甲下拉→恶魔皮肤/魔甲术二选一、SS_TK_AUTOSUMMON→四宠多选勾）；DOT 右键小窗（腐蚀术/献祭/生命虹吸 + 灾祸痛苦/末日 2选1 + 诅咒元素/虚弱/鲁莽/语言/疲劳 5选1，预判秒数）；读条引导右键小窗（引导：吸取灵魂预判5秒+目标血量10%、吸取生命无脑/看血量50%、折磨；读条：暗影箭填充）；护甲右键（默认魔甲术）；召唤宠物右键（小鬼/虚空行者/魅魔/地狱猎犬）；切换目标；拉条（生命分流30%/高血分流80%/喝红药30%/魔杖回蓝50%）；种族爆全开/全关/切换按钮；插入 死亡缠绕/恐惧术/恐惧嚎叫/地狱烈焰/火焰之雨/生命通道/生命分流（一次性放完自关）。
- 重写 Warlock/Warlock_Forever_Affliction.lua（仅 Forever 痛苦）：停手门 → 插入 → 自保 → 护甲 → 召唤宠物 → 切目标 → 防ADD门 → 种族爆 → 拉条 → DOT → 读条引导 → 魔杖兜底 → 清扫；共享件 Warlock_Forever.lua 零改动，毁灭/恶魔不受影响。
- 宏：/WARLOCK_DOT、/WARLOCK_CAST、/WARLOCK_SUMMON、/WARLOCK_ARMOR（带下划线文本，与恶魔术 /WARLOCKDOT 等并存不冲突）；宏槽/色表全部复用现有登记，零改动。
- 爆发「全开/全关/切换」按钮改挂 DM 行：isButton 按钮属于 DM 渲染路径（无 saveVariable，走 menuButtons），放 CB 段会走 CreateCheckbox 触发 PigSet[nil] 崩溃；恶魔学识段上一轮同款隐患一并修复。
- 验证：新增 .workbuddy/test_warlock_affl_rotation.py / test_warlock_affl_menu.py / test_warlock_affl_ui.py 离线夹具全过（UI 夹具同时构建痛苦与恶魔学识两段面板）；全量 Lua 语法检查通过。

【恶魔术】2026-11-15（按猪猪-无限服恶魔术页重做恶魔学识功能与循环）
- 用户口径：图片为恶魔术专精；当前客户端 60 级技能与天赋；按图匹配功能并修复 MK 插件中已不存在/已改动的技能循环，界面仍走 MK 面板，不污染痛苦/毁灭与其他职业。
- 新增 Warlock/Warlock_Demonology_Features.lua（登记进 TOC）：恶魔默认值/旧档迁移（SS_EM_HJ 护甲下拉→恶魔皮肤/魔甲术二选一、SS_EM_AUTOSUMMON→四宠多选勾）；DOT（腐蚀/献祭/生命虹吸 + 灾祸2选1 + 诅咒5选1，右键预判秒数）、读条引导（吸取灵魂/吸取生命引导，灵魂之火/灼热之痛/暗影箭读条，右键血量门槛）、护甲（恶魔皮肤/魔甲术）、召唤宠物（小鬼/虚空行者/魅魔/地狱猎犬多选）、切换目标、种族爆、拉条（生命分流/高血分流/喝红药/魔杖回蓝）、插入（死亡缠绕/恐惧术/恐惧嚎叫/地狱烈焰/火焰之雨/生命通道/生命分流，一次性放完自关）；右键「额外条件」小窗 4 个；宏 /WARLOCKDOT /WARLOCKCAST /WARLOCKSUMMON /WARLOCKARMOR；爆发全开/全关/切换按钮。
- 60 级技能口径：痛苦灾祸/末日灾祸（旧 痛苦诅咒/厄运诅咒 本服不存在）；移除 80 级引用（恶魔变形/邪甲术/召唤恶魔卫士/腐蚀之种/灵魂碎裂等）。
- 宏表：补 13 个职业槽宏（元素/虚弱/鲁莽/语言/疲劳诅咒、痛苦/末日灾祸、生命虹吸、死亡缠绕、恐惧术、恐惧嚎叫、生命通道、治疗药水）；色表 301-309 越界登记改绑 1-199 合法槽；腐蚀术色表改指 41 本体宏（原 14 为焦点宏，对当前目标补 DOT 错位）。
- 循环顺序：停手门 → 插入 → 自保 → 护甲 → 召唤宠物 → 切目标 → 防ADD门 → 种族爆 → 拉条 → DOT → 读条引导 → 魔杖兜底 → 清扫。
- 验证：新增 .workbuddy/test_warlock_demo_rotation.py 与 test_warlock_demo_menu.py 离线夹具全过；全量 Lua 语法检查通过。

【惩戒】2026-11-15（按彼岸花-无限服惩戒页重做惩戒功能与循环）
- 用户口径：图片为惩戒骑专精；当前客户端 60 级技能与天赋；按图匹配功能并删除 MK 插件中 80 级才有的技能，界面仍走 MK 面板。
- 新增 Paladin/Paladin_Retribution_Features.lua：圣印总开关（右键设置：解封之怒舞[命令↔正义轮流叠3层回响换印、审判好就打、可编十字军/智慧/光明审判]、常驻圣印[7选1+卡CD使用]、保持审判[十字军3号/智慧2号/光明1号按优先级补]）；祝福总开关；切换目标；驱散（右键选常规/优先/目标/指向）；愤怒之锤斩杀；驱邪术（亡灵/恶魔）；拉条 喝红药90/圣疗术69/奉献4目标；插入 制裁/圣佑/审判/奉献（一次性自关）。宏 /PALADIN_RET_SEAL、/PALADIN_RET_BLESS。
- 重写 Paladin/Paladin_Forever_Ret.lua（仅 Forever 惩戒）：祝福 → 圣疗术自疗 → 喝红药 → 插入 → 驱散 → 自动攻击 → 切换目标 → 防ADD → 圣印层 → 神圣打击 → 审判兜底 → 驱邪术 → 愤怒之锤 → 奉献。
- 移除 80 级技能引用：复仇之怒/祈求圣光/神圣牺牲/神圣震击/神恩术/真理之声/光之守夜/圣殿壁垒/十字军打击/寒霜刺骨等旧惩戒面板项与循环分支全部下线。
- 验证：新增 .workbuddy/test_paladin_ret_features.py 与 test_paladin_ret_rotation.py 离线夹具，全量 Lua 语法检查通过。

【防骑】2026-11-15（实战第二版：智慧审判换目标记账的「时序性 secret」盲区）
- 用户口径：上一版修复后游戏实战依旧复现「切回 A 再次切智慧圣印，A 身上明明还有智慧审判」。
- 根因（上一版盲区）：审判施放事件回报的那一刻，战斗中 UnitGUID/UnitName 恰好处于
  secret 状态 → NoteSingleSlotJudgement 里 targetKey=nil 直接 return → A 的按目标账
  根本没记上；之后切回 A 时 GUID 恢复可读 → mem[keyA] 查不到 + 旧单条账（B 的）又被
  目标检查判无效（stored=B≠current=A）→ 误判 A 没有智慧审判 → 再次切智慧圣印重打。
  上一版离线夹具 UnitGUID 恒可读、IsSecretValue 恒 False，从未覆盖
  「事件记账时刻 secret、查询时刻恢复可读」的时序组合。
- 修复三件套（Paladin_Forever_Prot.lua + Paladin_Forever.lua 事件帧）：
  ① PLAYER_TARGET_CHANGED 递增 TargetEpoch（事件必然触发，是换目标的权威信号；
    事件帧注册，放在 unit~="player" 早退之前处理）；
  ② 每个 epoch 内第一次读到目标 key（GUID 或名字）即锁定快照，整个 epoch 复用
    同一把钥匙（防 GUID/名字来源中途漂移导致账键对不上）；
  ③ 直接读取读不到时回退快照（epoch 必须一致）——审判前一瞬主循环 tick 已锁定的
    快照，让事件回调记账在 GUID secret 时也能落到正确目标；查询侧同样受益。
  另：智慧审判维持 phase4 的换目标检查补 TargetEpoch 兜底（两边 key 都读不到时
  也能检测换目标，不再把 B 的维持期错套在切回的 A 头上）。
- 验证：新增 .workbuddy/test_paladin_wisdom_target_secret.py（S1-S5：事件时刻
  secret 落账、A→B→A 全流程不误判不点亮智慧圣印、epoch 保护不把 A 的 key 错给 B、
  全程 secret 旧单条账兜底、GUID 恢复后 mem[keyA] 命中 39 秒）13 项全过；
  test_paladin_wisdom_target_switch.py 14 项全过（换目标模拟补发
  PLAYER_TARGET_CHANGED，与真实客户端行为一致）；全量圣骑士夹具 38 个全绿；
  全量 Lua 语法 200/200。
- 夹具工具链修正：lupa 的 Python lambda 在 Lua 侧 type() 是 userdata，
  会让被测代码里的 type(...)=="function" 守卫失效 → secret 判定 mock 必须用
  lua.eval 定义 Lua function（此缺陷同样影响所有旧夹具的 secret 模拟可信度）。

【奶骑】2026-11-15（按彼岸花-无限服奶骑页重做神圣专精功能与循环）
- 用户口径：图片为奶骑（神圣）专精；当前客户端 60 级技能与天赋；按图同步功能并修正 MK 插件中 80 级技能；不污染其他职业。
- 新增 Paladin/Paladin_Holy_Features.lua：圣印（常驻圣印/卡CD审判/保持十字军·智慧·光明审判，按数字优先级补审判并自动切回常驻圣印）、圣光誓约（右键指定队友，缺 buff 或剩 <15 秒切焦点补，治疗模式「目标」有人要奶时不抢焦点）、祝福总开关、切换目标、驱散、愤怒之锤、驱邪术、奉献目标数、喝红药、一次性插入（制裁/圣佑/审判/奉献）；右键「额外条件」小窗。
- 重写 Paladin/Paladin_Forever_Holy.lua（仅 Forever 神圣）：圣光术/圣光闪现/神圣震击（10 秒 CD）/神恩术/圣疗术/清洁术/圣盾术/圣光守望/圣光誓约；移除圣光道标、圣洁护盾、神圣牺牲、光环掌握、复仇之怒、祈求圣光、神圣风暴等本服不存在技能；新增 90 槽切换目标、112 槽圣光誓约、4 槽圣光守望宏与色表。
- 面板：神圣页改为「选择（防ADD/治疗模式）+ 拉条（喝红药/圣疗/奉献目标数/圣光守望/神圣震击/圣光术/圣光闪现）+ 功能 7 图标 + 插入 4 图标」，保留祝福设置按钮；技能槽位只落在神圣专精使用的别名上，防护/惩戒与其他职业不变。
- 验证：新增 .workbuddy/test_paladin_holy_features.py 29 项全过；全量 Lua 语法 201 文件 0 失败；圣骑士既有夹具回归通过（菜单分区/祝福设置等）。

【防骑】2026-11-15（修复智慧审判维持换目标 A→B→A 重复切智慧圣印）
- 用户口径：选择「智慧审判」buff 维持，给 A 打上智慧审判后切 B 正常打；再切回 A 时 A 身上明明还有 39 秒「智慧审判」，插件却再次切智慧圣印准备重打。
- 根因：战斗中目标光环是 secret，WR_GetUnitDebuffTime 对新目标可能读不到；原单审判本地账只有一条，记录的是「最后一次审判的目标 B」，切回 A 时旧账目标不等于 A，状态机判 A 没有 debuff → phase0 重新切智慧圣印。
- 修复（Paladin/Paladin_Forever_Prot.lua）：新增 WR_PaladinForever_JudgementMemory，按 targetKey 分别记录 light/wisdom/crusader 的 40 秒到期时刻；WR_PaladinForever_NoteSingleSlotJudgement 写入对应目标；JudgementSealDebuffRemain / SingleSlotJudgementInfo 在光环读不到时按当前目标本地账兜底；光明/智慧同槽位互相清账，十字军审判同步补记账。
- 验证：新增 .workbuddy/test_paladin_wisdom_target_switch.py 15 项全过；全部圣骑士夹具 + 全量 Lua 语法 199 文件 0 失败。

【武器】2026-11-15（按彼岸花-无限服武器页重做武器功能与循环）
- 用户口径：图片为武器战专精；当前客户端 60 级技能与天赋；按图匹配功能并修复 MK 插件中已不存在/已改动的技能循环，界面仍走 MK 面板；不污染其他职业。
- 新增 Warrior/Warrior_Arms_Features.lua：武器默认值/旧档迁移；撕裂/雷霆挫志/血性狂暴/破甲攻击/致死打击/横扫攻击/旋风斩/战斗怒吼/切换目标/猛击 功能判定；右键「额外条件」小窗（撕裂不打元素/机械/亡灵、预判秒数；破甲只打1破/高/低优先/续破秒数；致死打击让怒秒数/怒气；横扫攻击怪数/强制留怒或随缘；旋风斩怪数/怒气；血性狂暴怒气/血量；雷霆挫志多目标·单体 保持/卡CD/不放、怪数/缺数）；爆发全开/全关/切换按钮；/WARRIOR_REND、/WARRIOR_SUNDER_DPS、/WARRIOR_MS_POOL、/WARRIOR_WHIRLWIND、/WARRIOR_BLOODRAGE、/WARRIOR_SWEEP_AUTO、/WARRIOR_THUNDER_DEMO 别名。
- 重写 Warrior/Warrior_Forever_Arms.lua（仅 Forever 武器）：斩杀（目标血量拉条）> 致死打击 > 压制（触发）> 撕裂 > 破甲（只打1破/高/低/续破）> 雷霆/挫志 > 横扫攻击 > 猛击（15秒冷却）> 顺劈/英勇（怒气拉条）；功能 乘胜追击/血性狂暴/战斗怒吼/切换目标/旋风斩姿态舞（战斗→狂暴→旋风斩→战斗）；爆发 鲁莽/种族爆发；插入 反击风暴/穿刺打击/横扫攻击/狂暴之怒（一次性放完自关）；保命 喝红药/狂暴之怒解控。
- Warrior_Menu.lua：武器页重建为 10 个功能图标（撕裂/雷霆挫志/血性狂暴/破甲攻击/致死打击/横扫攻击/旋风斩/战斗怒吼/切换目标/猛击）+ 4 个插入图标（反击/穿刺/横扫/狂暴之怒）+ 2 个爆发开关（鲁莽/种族爆发）+ 3 个爆发按钮（全开/全关/切换）+ 6 条拉条（顺劈斩/英勇打击/斩杀/乘胜追击/喝红药/打断）；移除旧破甲/怒吼/寒霜/大风车等失效下拉与开关。
- Warrior_Macros.lua：新增 61 穿刺打击 宏槽与 WR_SkillColor 映射；Warrior_Arms_Features.lua 已加入 TOC。
- 验证：新增 test_warrior_arms_rotation.py 45 项、test_warrior_arms_menu.py 7 个右键小窗、test_warrior_arms_ui.py 面板构建全过；全量 Lua 语法 199 文件 0 失败。

【防骑】2026-11-15（清洁术不再误驱散诅咒：修复 secret hasValidInfo 导致诅咒边框被跳过）
- 用户口径：骑士清洁术无法驱散诅咒，中了这个诅咒会异常使用清洁术。
- 根因：DebuffFrame 的 auraFrames[i].hasValidInfo 在 12.x 可能是 secret boolean，旧代码用 == true 比较直接抛错并被 pcall 吞掉，整个 DebuffBorder 扫描被跳过；随后「secret debuffType 无边框」兜底把所有 secret debuff（含诅咒）当可驱散 → 清洁术对诅咒乱放。
- 修复：DebuffBorder 扫描不再依赖 hasValidInfo，直接读普通字符串图集名；auraInfo / deadlyDebuffInfo 中明确是 Curse / Bleed 的普通字符串记入 sawKnownNonCleansable，阻止 secret 兜底误判。清洁术仍只认 Poison / Disease / Magic。
- 验证：test_paladin_cleanse_combat.py 新增 J17-J20（诅咒图集 + hasValidInfo secret / 无 hasValidInfo；毒图集正常）全过；全量 Lua 语法 198 文件 0 失败。

【狂怒】2026-11-15（按彼岸花-无限服狂暴页重做狂怒功能与循环）
- 用户口径：图片为狂怒（狂暴）专精；当前客户端 60 级技能与天赋；按图匹配功能并修复 MK 插件中已不存在/已改动的技能循环，界面仍走 MK 面板。
- 新增 Warrior/Warrior_Fury_Features.lua：狂怒默认值/旧档迁移；撕裂/雷霆挫志/血性狂暴/破甲攻击/切姿态/战斗怒吼/切换目标/鲁莽挥击功能判定；右键「额外条件」小窗（不打元素/机械/亡灵、预判秒数；雷霆/挫志分多目标·单体 保持/卡CD/不放、怪物数/缺数；血性狂暴怒气/血量；破甲只打1破/高优先级/低优先级/续破秒数；切姿态脱战切战斗/进战切狂暴）；爆发全开/全关/切换按钮。
- 重写 Warrior/Warrior_Forever_Fury.lua（仅 Forever 狂怒）：斩杀（目标血量拉条）> 嗜血 > 旋风斩 > 压制（触发）> 猛击 > 顺劈（2+ 目标、怒气拉条）> 英勇（怒气拉条）；功能 乘胜追击/破甲/撕裂/雷霆/挫志；爆发 死亡之愿/鲁莽/种族爆发；插入 反击风暴/鲁莽/狂暴之怒（一次性放完自关）；保命 喝红药/狂暴之怒解控/切姿态。
- Warrior_Menu.lua：狂怒页重建为 8 个功能图标（撕裂/雷霆挫志/血性狂暴/破甲攻击/切姿态/战斗怒吼/切换目标/鲁莽挥击）+ 3 个插入图标（反击/鲁莽/狂暴之怒）+ 3 个爆发开关（鲁莽/死愿/种族爆发）+ 3 个爆发按钮（全开/全关/切换）+ 6 条拉条（顺劈斩/英勇打击/斩杀/乘胜追击/喝红药/打断）；移除旧破甲/猛击/怒吼/寒霜等失效下拉。
- Warrior_Macros.lua：60 死亡之愿、64 贯刺打击 宏槽；WR_SkillColor 原 301/302/303/304 越界槽改为真实 64/42/53/60，并登记「种族爆发」=181。
- 验证：新增 test_warrior_fury_rotation.py 24 项、test_warrior_fury_menu.py 6 项全过；全量 Lua 语法 198 文件 0 失败。

【防战】2026-11-15（按彼岸花-无限服防战页重做防护功能与循环）
- 用户口径：按图片所示功能优化兼容当前 MK 插件，修复防战循环；只针对防护专精，不污染其他职业；当前客户端为 60 级技能、天赋有改动。
- 新增 Warrior/Warrior_Protection_Features.lua：防护默认值/旧档兼容、撕裂/雷霆挫志/格挡/血性狂暴/破甲攻击/切姿态/战斗怒吼/切换目标/嘲讽/鲁莽挥击 的功能判定，以及右键「额外条件」小窗（多目标/卡CD/血量、保持/卡CD/不放、只打1破/高/低优先、续破秒数、预判、脱战切战斗/进战切防御）。
- 重写 Warrior/Warrior_Forever_Protection.lua（仅 Forever 防护）：盾牌猛击 > 复仇 > 盾牌格挡 > 乘胜追击 > 破甲（5层/续破/只打1破/高低优先）> 撕裂 > 雷霆 > 挫志 > 鲁莽挥击 > 顺劈/英勇（怒气拉条）；保命 破釜/盾墙/喝红药；插入 反击/震荡/挑战/盾墙/挫志/拦截/惩戒/狂暴之怒/缴械（一次性放完自关）；切姿态按脱战/进战分支并在插入快好时让路。
- Warrior_Macros.lua：新增 74 缴械 / 75 治疗药水 / 76 嘲讽 / 78 鲁莽挥击 / 89 震荡猛击 宏槽与 WR_SkillColor 映射；Warrior_Menu.lua：防护页新增 10 个功能图标与 9 个插入图标、补 乘胜追击/喝红药/顺劈/英勇/破釜/打断 拉条，其他专精不受影响。
- Core/UI_Config.lua：CreateCheckbox 新增 onRightClick（右键打开额外条件，左键仍切换开关；tooltip 自动加右键提示）。
- 验证：新增 test_warrior_prot_rotation.py 17 项、test_warrior_prot_menu.py 菜单/小窗 5 项全过；test_config_exclusive.py 全过；全量 Lua 语法 197 文件 0 失败。

【防骑】2026-11-15（修复清洁术报错：DebuffFrame.auraInfo.debuffType 是 secret string）
- 用户报错：Paladin/Paladin_Forever.lua:2521: attempt to compare local 'v' (a secret string value, while execution tainted by 'MKHelperForever')，调用链 WR_PaladinForever_NormalizeDispelType ← IsCleansableDispelType ← PlayerDebuffDispelByBlizzardFrame ← UnitHasDispel ← CleanseStep。
- 根因：DebuffFrameMixin:UpdateAuras 把 auraData.dispelName 原样存进 DebuffFrame.auraInfo[i].debuffType；战斗中 dispelName 仍是 secret string。旧 NormalizeDispelType 第一行 type(v) ~= "string" or v == "" 对 secret 字符串做 == 比较直接抛错；上一版「DebuffFrame 已解包成普通字符串」的判断不成立。
- 修复（Paladin/Paladin_Forever.lua）：① NormalizeDispelType 在任何比较前先做 secret 检测（WR_PaladinForever_IsSecretText，含 issecretvalue 兜底），string.lower 结果再检一次；IsCleansableDispelType 全程 pcall。② PlayerDebuffDispelByBlizzardFrame 对 auraInfo / deadlyDebuffInfo 只做「有 debuff 条目」的存在性判断，具体类型改读暴雪 AuraButton 的 DebuffBorder 图集名（ui-debuff-border-poison/-disease/-magic/-curse/-bleed，普通字符串）；诅咒 / 流血图集不误判，无边框的极老客户端才按 secret 条目兜底。
- 验证：test_paladin_cleanse_combat.py 新增 J10–J16（secret debuffType + 毒 / 诅咒 / 流血图集、无边框兜底、Normalize / IsCleansable 不抛错）全过；全部 29 个圣骑士夹具、57 个离线夹具、197 个 Lua 语法 0 失败。

【防骑】2026-11-15（清洁术战斗中能驱散自己：读暴雪 DebuffFrame 已解包的 debuffType）
- 用户口径：「防骑没有驱散自己，战斗中毒了」。
- 根因：Forever 12.1 的 C_UnitAuras.UnitAuraSlots / GetAuraDataByIndex 都带 RequiresUnitAuraAccess，战斗 / 首领战 / 挑战模式 / PVP 中光环 secret 时，tainted 插件调用会直接抛 “Auras cannot be accessed when secret while tainted”，pcall 也拿不到任何结果。上一版按 HARMFUL|RAID 过滤器探针在真机因此恒为空 → 自身中毒也不亮清洁术。
- 修复（Paladin/Paladin_Forever.lua）：新增 WR_PaladinForever_PlayerDebuffDispelByBlizzardFrame —— 读取暴雪玩家 DebuffFrame.auraInfo / deadlyDebuffInfo 的 debuffType（Blizzard 非 taint 代码已把 auraData.dispelName 解包成普通字符串，随 UNIT_AURA 更新），只认中毒 / 疾病 / 魔法；UnitHasDispel 对 player 优先走该信号，secret 战斗态下直接给出权威 true/false，不再依赖读不到的 C_UnitAuras。脱战 / 可读状态仍保留原缓存 + 接口路径。
- 验证：.workbuddy/test_paladin_cleanse_combat.py 新增 J1–J9（Poison / 中文「中毒」/ Magic / 诅咒 / 流血 / 空帧 / 无帧 / 不触发 C_UnitAuras 查询）全过；全部 29 个圣骑士夹具、57 个离线夹具全绿；全量 197 个 Lua 文件语法 0 失败。

【防骑】2026-11-15（清洁术战斗中可用：secret 光环下走 HARMFUL|RAID 过滤器探针）
- 用户口径：「防骑的清洁术目前战斗中不驱散，要改」。
- 根因：12.x 的 SecretWhenAurasRestricted 在战斗 / 首领战 / 挑战模式 / PVP 中把所有光环数据变成 secret。WR_ScanAurasForUnit 读到 secret 字段会抛 “Auras cannot be accessed when secret”，整段扫描被 pcall 丢弃 → WR_AuraCache 里没有 HARMFUL → WR_PaladinForever_UnitHasDispel 恒 false → 清洁术色块战斗中永远不亮，面板 5 模式和「自己 / 目标」复选框全部失效。
- 修复（Paladin/Paladin_Forever.lua）：
  ① 新增 WR_PaladinForever_ProbeDispellableByFilter：优先用 C_UnitAuras.UnitAuraSlots(unit, "HARMFUL|RAID", 1) 只枚举槽位号（不读取任何光环字段）；再退回 C_UnitAuras.GetAuraDataByIndex(unit, 1, "HARMFUL|RAID") 只做存在性布尔判断。HARMFUL|RAID 在引擎侧只返回「玩家自己能驱散」的 debuff（圣骑士 = 中毒 / 疾病 / 魔法），不会把诅咒算进来。
  ② WR_PaladinForever_UnitHasDispel 在缓存扫描之前先走该探针；探针明确为空且处于 secret 状态时直接判无，避免每 tick 触发必然失败的光环扫描；探针不可用时保留旧缓存 / WR_UnitDebuffType / 旧名字兜底。
  ③ WR_PaladinForever_CanCleanseCast 增加 WR_Forever_IsSpellKnown 兜底：12.x 的 IsPlayerSpell 可能不存在，战斗中 IsUsableSpell 对需要友方目标的清洁术返回 false 时，仍能凭「已学会」点亮。
- 验证：新增 .workbuddy/test_paladin_cleanse_combat.py 19 项全过（secret 战斗态过滤器命中、槽位命中、为空、抛错降级、不触发缓存扫描、自身 / 目标 43/44 点亮、非 secret 旧缓存回归）；test_paladin_cleanse.py / test_paladin_cleanse_dispeltype.py 全过；全部 29 个圣骑士夹具、57 个离线夹具全绿；全量 197 个 Lua 文件语法 0 失败。

【防骑】2026-11-14（圣印改为「能平砍的时候才挂自身圣印」，消灭空放）
- 用户口径：「防骑圣印应该修改为能平砍的时候才挂自身圣印，不然会出现空放圣印的情况」。
- 根因：圣印是自身 Buff，客户端不验证目标就会放出去；旧 CanApplySeal 自带一套 target / UnitCanAttack / 裸 UnitIsDead / 8 码判定（裸 UnitIsDead 拿不到 secret 的确认 true、也不查 ghost，尸体目标会被当活体放行），且 ShowSealBlock 的切印 / 切回 / 插入路径完全不过距离门，保护窗口 RefreshSealPrompt 每 tick 无条件重亮——没目标 / 目标跑远 / 目标已死时色块照亮，AHK 同色连按就是空放圣印，白烧 GCD 和蓝。
- 修复（Paladin/Paladin_Forever.lua）：
  ① 新增 WR_PaladinForever_CanMeleeSwing：有敌对活目标（TargetCastable：存在 + 可攻击 + 非尸体/ghost）+ 在「攻击」平砍射程 8 码内；距离读不到（999/secret）按全项目口径放行，避免无限服退化成永远不补印。
  ② WR_PaladinForever_CanApplySeal 统一改为「战斗中 + 能平砍」，删除旧的自带重复判定。
  ③ WR_PaladinForever_ShowSealBlock 增加统一出口门：不能平砍时一律不点亮任何圣印色块（补印 / 切印 / 切回 / 插入全覆盖），并按槽位熄灭残留色块。
  ④ WR_PaladinForever_RefreshSealPrompt 在 1 秒保护窗口内每 tick 复查「能平砍」，目标跑远 / 死亡时立即熄灭并清窗口，AHK 不再连点空放。
- 验证：新增 .workbuddy/test_paladin_seal_melee_gate.py 15 项全过（能平砍判定 / 无目标 / 死亡 / 过远 / 不可攻击 / 距离未知放行 / CanApplySeal / ShowSealBlock / RefreshSealPrompt / 端到端）；全部 28 个圣骑士夹具、56 个离线夹具全绿；全量 197 个 Lua 文件语法 0 失败。

【治疗】2026-11-14（战斗中加血修复：secret 血量下用 UNIT_COMBAT 估算队伍血量）
- 用户口径：「我就是需要战斗中需要加血」。
- 根因：Forever 继承 12.x secret value —— 战斗中 UnitHealth / UnitHealthMax / UnitHealthPercent 对插件返回 secret，WR_GetUnitHP 统一降级为 1（满血），戒律牧/奶骑等所有按血量选人的治疗逻辑战斗中全部静默；客户端实际仍允许 UNIT_COMBAT 的伤害/治疗量（普通数字）与 UNIT_HEALTH 事件。
- 修复：新增 Core/Forever_CombatHealth.lua —— 脱战/可读时精确快照；战斗中按 UNIT_COMBAT 的 WOUND / DAMAGE / SPELL_DAMAGE / HEAL 等 amount 增减估算每个队伍成员的血量；未匹配 UNIT_COMBAT 的 UNIT_HEALTH 连续事件按压力逐级压低估算（1 次→85%、2 次→65%、3 次以上→45%），保证持续掉血的目标进入治疗阈值。WR_GetUnitHP 在 secret 时返回估算值；Core/Utils_HealerWeight.lua 的选人权重改走 WR_GetUnitHP。
- 复核修正（2026-11-14）：CombatHealth 把 focus/target 解析到真实队伍单位（避免焦点血量永远按 100%）；UNIT_HEALTH 先到与 UNIT_COMBAT 后到不再重复计压力；未知最大血时按压力兜底；Utils_HealerWeight 的最大血改走估算缓存。
- 验证：新增 .workbuddy/test_forever_combat_health.py 11 项、.workbuddy/test_forever_combat_heal_e2e.py 15 项、.workbuddy/test_healer_weight_combat.py 3 项全过；全部 55 个离线夹具 0 失败；全量 197 个 Lua 文件语法 0 失败。

【戒律牧】2026-11-14（恢复老版「焦点目标加血」：自动设焦点 + 完整戒律治疗循环）
- 用户口径：「查看一下插件中的戒律牧专精，老版本是焦点目标加血的方式，目前更新到了无限服客户端不一样，技能天赋都不同，需要实现以前的加血功能」。
- 根因：Priest_Macros.lua 所有治疗宏都是 [@focus] 形态（53 治疗祷言 / 54 苦修 / 55 恢复 / 56 联结治疗 / 57 快速治疗 / 58 愈合祷言 / 59 真言术：盾 / 64 痛苦压制 / 150 绝望祷言），但 Forever 版 WR_PriestForeverDiscipline 只用 WR_SoD_GetLowestFriendly 算低血目标、从不点亮「设焦点」色块；AHK 按治疗键时打的是玩家当前焦点（或没有焦点），表现为判 A 治 B / 治不出。
- 修复（Priest/Priest_Forever_Discipline.lua）：按时光服老版 Priest_Discipline.lua 的链路重建焦点目标加血——每 tick 先按面板「治疗模式」JL_ZLMS（自动/坦克/脆皮/目标）选最低血友方，低于阈值时点亮 192/147/176-179/121-145 的设焦点色块，下一 tick 再用 [@focus] 治疗；当前焦点更危急则保持，尊重玩家手动焦点。治疗优先级：自身绝望祷言 <30% → 痛苦压制 <30%（无限缺失自动跳过）→ 治疗祷言（≥3 人 <70%）→ 愈合祷言 → 真言术：盾（JL_ZYSD 档位 / 全团 JL_QTTD / 坦克 JL_TKZD / 焦点 JL_JDSD）→ 苦修 <90% → 快速治疗/联结治疗 <85% → 恢复 <95%。全部沿用现有 JL_* 存档键与宏槽位。
- 验证：新增 .workbuddy/test_priest_discipline_focus.py 23 项全过（满血不提示 / 设焦点槽位 / 焦点直达 / 愈合·盾·苦修·快疗·恢复优先级 / 群体治疗 / 坦克·脆皮·目标模式 / 自身保命 / 读条保护 / 痛苦压制缺失）；全量 196 个 Lua 文件语法 0 失败。

【防骑】2026-11-14（新增「愤怒之锤·精英」开关：只对精英怪 / BOSS 斩杀）
- 用户口径：「防骑再新增一个愤怒之锤的按钮，控制愤怒之锤目标为精英怪，boss的时候才用」。
- 实现（Paladin/Paladin_Forever_Prot.lua）：新增 WR_PaladinForever_HammerTargetIsEliteOrBoss / WR_PaladinForever_HammerTargetAllowed；hammerEligible 追加目标类型门——勾选「精英」后，仅当目标分类为 elite / rareelite / worldboss / boss、boss1~5 单位帧、骷髅级（等级 -1）或 UnitIsBoss 时才提示愤怒之锤；普通小怪即使进入斩杀期也不点亮（省 0.87 秒读条 + 295 蓝）。主链与第 11 档兜底共用 hammerEligible，行为一致。
- 面板（Paladin/Paladin_Menu.lua）：「愤怒之锤」右侧新增「精英」复选框 FH_FNZC_JY（默认关闭 = 保持原行为，全目标可用）；原「愤怒之锤」tooltip 同步说明。
- 验证：新增 .workbuddy/test_paladin_hammer_wrath_elite.py 20 项全过（开关关闭原行为 / elite·rareelite·worldboss·boss / 骷髅级 / boss1~5 / 普通怪拦截 / 与总开关·斩杀期·蓝量·射程叠加 / 主链与兜底 / 菜单存在性）；全部 27 个圣骑士夹具全绿；全量 195 个 Lua 文件语法 0 失败。

【圣骑士】2026-11-14（清洁术真正可用：按 dispelType 识别中毒/疾病/魔法，不再按光环名空匹配）
- 用户口径：「骑士这个版本清洁术用不了」（截图：清洁术 4987，驱散 1 个中毒 / 1 个疾病 / 1 个魔法）。
- 根因：WR_PaladinForever_UnitHasDispel / WR_PaladinForeverHoly_HasDispel 旧实现把「中毒 / 疾病 / 魔法」当成 debuff 名称传给 WR_GetUnitDebuffTime；该函数按【光环名精确匹配】，而真机 debuff 名是技能名（毒液箭 / 撕裂 / 腐蚀…），永远匹配不到 → 可驱散判定恒 false → 清洁术所有模式都不亮。
- 修复（Paladin/Paladin_Forever.lua）：新增 WR_PaladinForever_NormalizeDispelType / IsCleansableDispelType / CacheHasDispel；UnitHasDispel 改为先扫 HARMFUL 光环缓存的 dispelType（Poison / Disease / Magic，兼容客户端本地化的「中毒 / 疾病 / 魔法」），再走公共 WR_UnitDebuffType、C_UnitAuras 直读和旧名字兜底；继续排除「诅咒」。新增 WR_PaladinForever_CanCleanseCast：IsUsableSpell 对需要友方目标的技能在敌方/无目标时可能返回 false，此时只要已学会且不在本地 CD 就允许点亮（蓝量仍由色块总闸拦截）。
- 修复（Paladin/Paladin_Forever_Holy.lua）：WR_PaladinForeverHoly_HasDispel 统一委托公共判定，奶骑同步修复；清洁术可用性走同一 CanCleanseCast。
- 修复（Core/Core_Functions.lua）：光环缓存 dispelType 兼容 data.dispelName / data.dispelType 两种字段名。
- 验证：新增 .workbuddy/test_paladin_cleanse_dispeltype.py 18 项全过（真实技能名 + dispelType、中文类型、Curse 排除、缓存缺失直读 C_UnitAuras、CleanseStep 接线）；test_paladin_cleanse.py 旧夹具同步更新后全过；全部 26 个圣骑士夹具全绿；全量 195 个 Lua 文件语法 0 失败。

【防骑】2026-11-14（目标已有圣光审判时切回所选常驻圣印：修复光明圣印残留不切愤怒）
- 用户口径：「防骑存在异常，当目标有圣光审判时，身上有圣光圣印，选择圣印是愤怒圣印，这时候没有切对应圣印」。
- 根因：① WR_PaladinForever_SealNeedsRefresh 的「任意圣印在身一律不补」会挡住「从光明圣印切回面板所选常驻圣印」，只要身上能读到任意圣印就永远不亮愤怒圣印；② 光明/十字军/智慧三个 buff 维持状态机 phase4 旧条件要求 LightSealOnPlayer() 为真，战斗中光环 name 是 secret / 施放事件丢失时会误判「不在光明」，于是不提示切回；③ SealBuffState 在光环 name 为 secret 时只返回 "up", nil，无法知道身上是哪条圣印。
- 修复（Paladin/Paladin_Forever.lua）：新增 WR_PaladinForever_SealNameBySpellID，SealBuffState 缓存分支与直扫分支在光环 name 不可读时按 spellId 反查具体圣印名。
- 修复（Paladin/Paladin_Forever_Prot.lua；Paladin/Paladin_Menu.lua 同步光明圣印 tooltip）：新增 WR_PaladinForever_MainSealOnPlayer / WR_PaladinForever_SealShouldSwitchToMain；当光环明确是另一条「审判 buff 维持类」圣印（光明/十字军/智慧）且目标已有对应审判 debuff（含圣光审判/光明审判与本地单槽位记账兜底）时，允许切回面板所选常驻圣印并本 tick 直接点亮；光明/十字军/智慧三个状态机 phase4 改为反向确认「常驻圣印是否已在身上」（not MainSealOnPlayer），不再依赖能否读到光明/十字军/智慧光环。
- 验证：新增 .workbuddy/test_paladin_seal_switch_back.py 8 项全过（未勾选维持 / 勾选维持 / 光环不可读 / 常驻=光明 / 正义不误切 / 光明审判旧名 / spellID 反查）；全部 25 个圣骑士夹具全绿；全量 195 个 Lua 文件语法 0 失败。

【防骑】2026-11-14（愤怒/正义圣印正常打审判，不被光明/智慧审判buff开关误伤）
- 用户口径：「愤怒和正义不会顶审判buff，要正常打审判」。
- 根因：WR_PaladinForever_JudgementUsesSingleSlot 把 FH_CRGMSY / FH_ZHSP 两个审判buff维持开关直接判成「单审判槽位」；即使常驻圣印是正义/愤怒，主调度 judgeEligible 也会被整段跳过——这两条圣印的审判根本不产生审判 debuff，却被当成光明/智慧审判一样限制。
- 修复（Paladin/Paladin_Forever_Prot.lua；Paladin/Paladin_Menu.lua 同步正义/愤怒 tooltip）：单槽位判定只看「本次实际消耗的圣印」——只有光明圣印/智慧圣印算单槽位；正义/愤怒等审判不产生审判 debuff，不受 buff 维持开关影响。主调度 judgeEligible 仅在「常驻圣印本身是光明/智慧且对应维持开关开着」时让位；phase4 维持期恢复普通审判。光明/智慧状态机改为按自己实际切过去的圣印判定，避免拿常驻圣印误判。
- 验证：新增 .workbuddy/test_paladin_judgement_nonconflict_seals.py，E1-E6 / F1-F4 / G1-G5 共 15 项全过；全部 24 个圣骑士夹具全绿（含光明/智慧/十字军三个 buff 维持状态机与光明/智慧互斥夹具）；同步修正 4 个旧夹具的 phase4 判定时间适配 1.0 秒圣印提示保护窗口；全量 195 个 Lua 文件语法 0 失败。

【防骑】2026-11-14（圣印提示优先级提高：上圣印不再被其它技能色块顶掉）
- 用户口径：「防骑目前上圣印经常被顶，导致无法使用出圣印，将圣印优先级调高」。
- 根因：圣印色块保持/保护窗口只有 0.3 秒（约 3 个主循环 tick）。WR_ColorFrame_Show 每次
  点亮任意技能都会先隐藏全部色块，0.3 秒窗口一旦被下一 tick 的审判/神圣打击/攻击等色块
  覆盖，AHK 就读不到圣印键 → 不补印；补印重试又要等 CanPrompt 的 3 秒闩锁，表现就是
  「上圣印经常被顶、圣印出不来」。
- 修复（Paladin/Paladin_Forever.lua）：
  ① WR_PaladinForever_SEAL_PROMPT_HOLD：0.3 → 1.0 秒（约 10 个主循环 tick），
     整个窗口内 WR_PaladinForever_RefreshSealPrompt 每 tick 重亮同一圣印并让循环直接
     return true，任何其它技能提示都顶不掉圣印色块；
  ② WR_PaladinForever_ShowSealBlock 点亮成功即写入 ActiveSealPromptUntil（不再依赖
     调用方一定紧接着调 HideSkillLater），保护窗口不会漏开；
  ③ 1.0 秒严格小于圣骑士 1.5 秒 GCD，一个窗口最多成功施放一次圣印；施放成功事件
     仍立即 HideNow，不会回到「同色常亮连按 50 次」的反复上印老问题。
- 验证：新增 .workbuddy/test_paladin_seal_priority.py 12 项全过（常量 / 点亮即开窗 /
  0.4s 与 0.95s 持续保护 / 1.0s 到期 / 圣印保持上限 / 普通技能保持不变 /
  Prot 顶部优先级分支命中并重亮圣印）；Paladin_Forever.lua 与
  Paladin_Forever_Prot.lua 语法编译通过，全量 195 个 Lua 文件语法 0 失败。

【防骑】2026-11-14（修复愤怒之锤从未点亮：Forever 隐藏目标血量导致判定恒为满血）
- 用户口径：「防骑愤怒之锤没有打出来过」。
- 根因：无限/WoW Forever 的 UnitHealth / UnitHealthMax 对插件恒为 secret 值，WR_SafeHPPct 按安全层口径降级为 1（=满血）；旧门 `WR_SafeHPPct("target") < 0.20` 永远不成立 → hammerEligible 恒 false，主链与兜底都不会点亮愤怒之锤。
- 修复（Paladin/Paladin_Forever_Prot.lua）：新增 WR_PaladinForever_HammerExecuteReady / WR_PaladinForever_TargetHealthPctSafe；血量可读时按 <20%，血量不可读（Forever 常态）时改用 C_Spell.IsSpellUsable（本服 IsUsableSpell 已映射到该 API；愤怒之锤仅斩杀期可施放，可用性即执行期信号且非 secret），并用 C_SpellActivationOverlay.IsSpellOverlayed（原生技能发光）兜底；主链与兜底统一走新判定。
- 冷却记账：WR_PaladinForever_SpellRankIDs 补全愤怒之锤 Rank1/2/3 = 24275/24274/24239（Forever DB 实测：44/52/60 级），换 rank 不再漏记 6 秒本地 CD。
- 同步：Paladin/Paladin_Forever_Ret.lua 的惩戒愤怒之锤复用同一判定（同一根因，避免换专精后再次出现）。
- 验证：新增 .workbuddy/test_paladin_hammer_wrath_secret.py（隐藏血量 + 执行期/非执行期/冷却中/原生发光兜底）；test_paladin_hammer_wrath.py 等全部圣骑夹具与全量 Lua 语法通过。

【圣骑士】2026-11-14（修复清洁术面板功能：防护/惩戒 Forever 循环未读取面板设置）
- 用户口径：「骑士清洁术功能匹配一下，目前插件面板中的清洁术无法使用」；截图：清洁术 4987，驱散 1 个中毒/1 个疾病/1 个魔法。
- 根因：面板已有 FH_QJS / CJ_QJS 五模式下拉与 FH_QJS_Player / FH_QJS_Target 复选框，但 Paladin_Forever_Prot.lua 完全没有清洁术逻辑；Paladin_Forever_Ret.lua 读的是已废弃变量 CJ_QJ，且固定点 27=targettarget 宏；公共 HasDispel 还把不能解的「诅咒」算进来。
- 修复：新增共享 WR_PaladinForever_CleanseStep / WR_PaladinForever_UnitHasDispel / WR_PaladinForever_OnCooldown；防护接入 FH_QJS 的「优先/常规/目标/指向/禁用」与独立「自己/目标」复选框，惩戒接入 CJ_QJS；施放槽 43 自己 / 44 目标 / 59 指向，不设焦点；只认中毒/疾病/魔法。
- 验证：新增 .workbuddy/test_paladin_cleanse.py；全部圣骑夹具与 194 文件语法检查通过。

【圣骑士】2026-11-13（修复防骑「常驻光明圣印 + 智慧审判」：主循环误打光明审判顶掉智慧审判）
- 用户口径：「角色使用光明圣印，审判选择智慧审判；当智慧审判命中目标并给目标加上智慧审判buff后，
  再切回光明圣印进行攻击时，系统仍会释放光明审判，导致目标身上的智慧审判buff被顶掉消失」。
- 根因：无限 12.x 战斗中 target 光环是 secret，WR_GetUnitDebuffTime 读不到目标身上的
  光明/智慧审判 debuff。旧的 WR_PaladinForever_JudgementAllowed 只靠光环判断 →
  战斗中恒判「没有审判」，主调度按当前圣印打出一发（常驻光明 → 光明审判），
  把智慧审判顶掉；且智慧审判状态机 phase3 切回光明圣印后到 phase4 之间主调度也会抢打。
- 修复（Paladin/Paladin_Forever_Prot.lua）：
  ① 新增 40 秒「单审判槽位」本地记账（kind=light/wisdom）：审判施放成功 / 状态机确认时记录，
     光环不可读时由 WR_PaladinForever_SingleSlotJudgementInfo 兜底；换目标自动失效。
  ② WR_PaladinForever_JudgementAllowed 改为类型感知：光明审判永远不许覆盖智慧审判；
     智慧审判可以把光明审判顶掉（用户要的就是智慧）。
  ③ 主调度 judgeEligible：FH_CRGMSY / FH_ZHSP 开启时审判由对应状态机独占，
     主循环任何时刻不再自己打审判，杜绝 phase3/4 切回常驻圣印时抢打光明审判。
- 验证：新增 .workbuddy/test_paladin_light_wisdom_conflict_repro.py（A-G 全绿：
  智慧审判挂上后、目标 debuff 不可读时主循环不再点亮审判）；全部圣骑士夹具与
  全量 Lua 语法 194/194 通过。

【全局】2026-11-13（修复主面板插件图标被「全局」区背景遮挡成黑块）
- 用户口径：「面板中这里面板UI挡住了图标要移动一下」（截图：全局标题条左侧图标整块发黑）。
- 根因：插件图标 MKHelperForeverIcon 挂在 configFrame 上（绘制层级低于子框架
  WR_GlobalRegion 的 region 底色 0.90 alpha），整块图标被左区背景压暗；且 22px 图标
  与 22px 标题条等高，底边被标题条底部 1px 分隔线切过。
- 修复（Core/UI_Config.lua）：图标改挂 globalHeader 的 OVERLAY 层（高于左区底色），
  尺寸 22→18、垂直居中（LEFT, 4, 0），完整落在标题条内，不再被背景/分隔线遮挡。
- 验证：新增 .workbuddy/test_ui_icon_visibility.py（A-C 全绿）；UI 折叠/菜单夹具与
  全量 Lua 语法全绿。

【圣骑士】2026-11-13（修复防骑自动把小队第 2 名设为焦点：奶骑自动焦点宏隔离）
- 用户口径：「防骑配置每次都会自动把焦点设置在小队第二个队友身上，之前不会」。
- 根因：奶骑自动焦点（2026-11-13）把共享 Paladin_Macros.lua 的 31 条设焦点宏
  去掉了 nocombat，并把 [@partyN]/[@raidN] 改成 [target=partyN]/[target=raidN]
  以绕开 WR_ShouldGateFocusMacro。防骑/惩戒与神圣骑共用同一套宏；防骑的共享祝福
  模块（Paladin_Blessing.lua）在战斗锁定/直施回读失败时回落焦点流程，点亮 176-179，
  AHK 按 ALT-SHIFT-PAGEUP（177=party2）就真的执行 /focus party2。
- 修复：Paladin_Macros.lua 按专精注册焦点宏——只有神圣骑使用活跃版；防护/惩戒恢复
  [@partyN]/[@raidN,...,nocombat] 安全版（跟随关闭时会被门控为空宏）。
  Paladin_Blessing.lua 增加 WR_PaladinBlessing_FocusFlowAllowed：非神圣专精禁止
  回落焦点流程；WR_PaladinBlessing_Blocked 增加 InCombatLockdown 硬闸。
- 验证：新增 .workbuddy/test_paladin_focus_spec_guard.py（A-F 全绿）；
  test_focus_gate.py、test_paladin_blessing_misfire.py、test_paladin_blessing.py 全绿；
  全量 Lua 语法 194/194。

【全局】2026-11-13（修复「设置」折叠后右区菜单整片空白 / 天赋面板菜单被连带隐藏）
- 用户口径：「点了折叠后出现了异常bug」；截图表现为右区「设置」标题下方整块菜单区空白，
  下拉/滑块/按钮全不见，只剩下方职业分区。
- 根因：下拉菜单/滑块/按钮等「设置」控件原先直接挂在各专精天赋 Frame 上，
  天赋 Frame 的 Show/Hide、高度收缩或「设置」折叠逐控件 Hide 的残留状态，
  会把整块菜单连带隐藏；同时 MAX_FRAME_HEIGHT 压缩分支在设置折叠时还会把
  menuRegionH 重新抬回正数，留下大块空白。
- 修复（Core/UI_Config.lua）：每个天赋面板新增独立 MenuBox（挂 WR_ClassMenuRegion，
  不随天赋 Frame 显隐），全部 DM 控件改挂 MenuBox；WR_ApplySettingsCollapse 统一显隐
  MenuBox 并兼容旧面板重建 menuWidgets；WR_LayoutConfigFrame 压缩分支在设置折叠时
  强制 menuRegionH=0。
- 修复（Core/UI_TalentFrame.lua）：切换专精时同步 MenuBox 显隐，避免旧专精菜单残留。
- 验证：新增 .workbuddy/test_ui_menu_visibility.py；test_config_section_collapse.py、
  test_ui_top_section_collapse.py、_syntax_all.py 全绿。

【全局】2026-11-13（主面板「全局」「设置」标题条支持折叠）
- 用户口径：「插件UI面板中，目前全局，设置无法折叠，全局折叠向右」。
- 改动：Core/UI_Config.lua 的 SECTION_COLLAPSE_KEYS 登记「全局」= UI_GLOBAL_SECTION_COLLAPSED、
  「设置」= UI_SETTINGS_SECTION_COLLAPSED；两个标题条改为可点击折叠（右侧显示 +/−）。
- 全局：折叠时隐藏左区全部控件（标题条保留），左区高度收缩到标题条；展开恢复。
  「全局」标题文字右对齐并预留折叠符宽度（折叠符固定在标题条右侧）。
- 设置：折叠时隐藏右区下拉/滑块/按钮与天赋标题，菜单区高度归零，图标网格紧贴
  「设置」标题条下方；展开恢复。
- 验证：新增 .workbuddy/test_ui_top_section_collapse.py；_syntax_all.py 193 文件 FAIL=0。

【全局】2026-11-13（技能色块「按技能逐个判蓝」补全：消耗缓存随法术书失效 + 蓝量变化事件立即刷新）
- 用户口径：「为每个技能单独判断角色当前蓝量是否足够支付该技能的消耗；蓝量不足时
  对应色块不亮并熄灭；蓝量足够时亮起；蓝量变化、技能消耗变化或相关状态更新时及时
  刷新所有技能色块；蓝量恰好等于消耗时视为可释放并亮起；各技能色块判断相互独立，
  避免仅根据全局状态统一控制」。
- 现状核对：按技能判定的三级闸（WR_ColorFrame_ShowSkill 总闸 → WR_SoD_NotEnoughPower
  按技能名查客户端回执黑名单 + 消耗算术 → WR_Forever_NotEnoughPower 的 cur<cost 判死 /
  == 放行）2026-11-12 已落地；冰法/圣印/祝福/ShowSkillCD 四条旋转路径全部经由该判定，
  无绕过点（冰法 MageFrost_Show 最终走 ShowSkill；直接点 WR_ColorFrame_Show 的均为
  饰品/药水/跟随/焦点/首领预警等非技能提示，不在技能色块范围）。
- 改动①（Core/Forever_Compat.lua）：技能消耗正缓存此前**永不过期**——升级（新客户端
  同一 spellID 消耗按等级缩放）、换天赋/雕文修正都会改消耗，旧消耗留着会出现「蓝不够
  还亮（旧低）/够蓝却不亮（旧高）」。现随法术书/天赋事件（SPELLS_CHANGED /
  PLAYER_ENTERING_WORLD / PLAYER_TALENT_UPDATE）立即清空 WR_Forever_PowerCostCache，
  下一次点亮按需逐技能重探；清空零成本，战斗中也不掉帧。
- 改动②（Core/SoD_Runes.lua）：
  · WR_SoD_SweepPowerBlocked 拆出 WR_SoD_RefreshPowerBlocks(force)：force=true 跳过
    「本轮已亮过」短路——蓝量在点亮之后又被其它动作吃掉时，本 tick 刚亮的色块同样
    立即熄灭；force=false 保持每 tick 收尾清扫语义（MainLoop 调用点不变）。
  · 新增资源变化事件帧：UNIT_POWER_UPDATE / UNIT_POWER / UNIT_MANA / UNIT_RAGE /
    UNIT_ENERGY 按客户端代际并集注册（逐个 pcall，新客户端注册未知事件会抛错）；
    触发时先清 0.05 秒资源帧缓存再强制复查当前亮着的技能色块——蓝降立即熄灭、
    蓝升由下一 tick 循环照常重点亮（事件层只做「熄灭」方向，不越权点亮）。
    事件带 unitToken 时只认玩家自己；战斗中资源读不到（secret）自动放行不误灭。
- 验证：新增 .workbuddy/test_power_refresh.py 共 27 项全过（消耗缓存随法术书/天赋事件
  失效并按新消耗判 / 事件 force 路径立即熄灭 / 事件帧自清资源缓存 / 蓝回升不越权点亮 /
  == 边界在 ShowSkill 层 / 贵技能拦下不牵连便宜技能与回执黑名单独立性 / 只认 player /
  注册并集 / 老 tick 清扫语义回归）；test_power_gate.py 30 项回归通过；_syntax_all.py
  193 文件 FAIL=0；全量 39 个夹具 39/39 全绿。

【全局】2026-11-13（删除全局面板「爆发总闸」开关）
- 用户口径：「删除插件中全局下的爆发总闸」。
- 改动：Core/UI_Config.lua 左侧「全局」面板删除「爆发总闸」复选框（WR_GlobalBurstCheckbox）
  及其文字标签、点击/提示脚本；GLOBAL_BURST 存档键不再初始化与读写。
- 布局：原锚在爆发总闸下方的「启用怪物屏蔽」改为锚定「偷药时间」滑块，其后的
  职业屏蔽 / 屏幕文字提示 / 图标缩放 / 窗口透明度 / 自动跟随整条链保持不变。
- 说明：该开关原为纯 UI 总闸，各职业自己的爆发开关与判定逻辑均不受影响。
- 验证：_syntax_all.py 全量语法通过；test_config_prepull_removed.py 与新增
  test_config_global_burst_removed.py 全过。

【防骑】2026-11-13（目标已死亡/尸体 → 不切「审判buff」圣印、不空放审判）
- 用户口径：「勾选后，当目标已死亡且显示为尸体时，仍会切换所选圣印并尝试释放审判」。
- 根因：死亡/尸体判定全部是裸真值调用——TargetCastable（CanHitTarget 的底座）只有
  `if UnitIsDead(unit) then return false end` 一道闸：① 12.0 战斗中单位状态型接口
  可能返回 secret boolean（哑值），裸真值拿不到「确认的 true」；② 整条链从未查
  UnitIsGhost（本服尸体目标可能挂在 ghost 态上，UnitIsDead 读不到 true）。
  于是目标变尸体后：光明/十字军/智慧三状态机 phase0 照常点火切 buff 圣印，
  phase1 照常点亮审判——全部空放，白顶常驻圣印 + 白烧切印的蓝。
- 修复：
  ① Paladin_Forever.lua 新增 WR_PaladinForever_UnitIsDeadOrGhost(unit) 统一判定：
    UnitIsDead / UnitIsDeadOrGhost / UnitIsGhost 任一明确回答 true 即死亡，
    另加「血量读得到且 ≤0」兜底；secret 比较全部包 pcall，API 缺失/读不到一律放行
    （口径与射程 999/secret 放行一致，活体目标行为不变）；
  ② TargetCastable 的裸 UnitIsDead 改走统一门 → CanHitTarget 全链对尸体统一拦截：
    主循环审判 / 多目标链 / 三状态机 phase0 切印门与 phase1 审判门 / 插入一次性 /
    愤怒之锤 / 驱邪术 / 奉献 / 攻击，惩戒与神圣同样受益；
  ③ 三状态机入口各加【尸体不切印】总门：确认目标死亡 → 重置阶段并 return false，
    不点火切印、不提示审判，也不会卡在 phase1~4 对着尸体空等超时；
    常驻圣印由主循环圣印维持逻辑（CanApplySeal）自行恢复；目标复活后流程从头重开。
- 验证：新增 .workbuddy/test_paladin_dead_target.py 18 项全过（死亡 / ghost 态 /
  血量兜底 / API 缺失放行 / phase1 中途变尸体立即放弃 / 复活后直接补审判）；
  _syntax_all.py 193 文件 FAIL=0；range_gate / light / crusader / wisdom /
  light_mode / seal_switch_timing / justice_seal_loop / seal_early_loss / hammer /
  blessing_misfire 10 个旧夹具回归全绿。

【防骑】2026-11-13（愤怒之锤接入主循环优先级 + 面板开关）
- 用户口径：「请在提供的防骑主循环逻辑中新增愤怒之锤的使用分支，明确其触发条件、
  冷却与资源限制，并与现有技能优先级正确衔接」。
- 触发条件：面板「愤怒之锤」开关 FH_FNZC（防护区第 7 行第 2 列，默认勾选）+ 目标生命
  少于 20%（WR_SafeHPPct，读不到视为满血不触发）+ 目标可攻击且存活 + 30 码射程
  （WR_PaladinForever_SPELL_RANGE）+ 本地 6 秒 CD + 蓝量 ≥20%（WR_PaladinForever_PROT_HOW_MANA_MIN）。
- 优先级衔接：多目标链 审判 之后、神圣打击 之前；单体链 Ready-first 之后、驱邪术 之前；
  原第 11 档兜底保留并同样受开关控制。
- 读条保护：0.87 秒读条 + PROMPT_HOLD 1.5 秒窗口内整条调度让路（窗口内即使目标回血
  也让路，保护可能仍在飞行的读条），窗口走完或施放成功后自动恢复常规调度。
- 冷却记账：WR_PaladinForever_SpellRankIDs 登记 愤怒之锤 = 24275（截图实测），
  施放成功事件按 ID 记账，战斗中事件名 secret 时本地 6 秒 CD 照常推进。
- 离线夹具 .workbuddy/test_paladin_hammer_wrath.py 17 项全过；_syntax_all.py 193 文件 FAIL=0。
【防骑】2026-11-13（小队祝福误施到自己 / 顶掉个人祝福——五道硬闸补全）
- 用户口径：「当队伍中仅剩我和另一名队友时，我选中一个敌对目标，插件会错误地将
  预先设置的小队祝福buff施放到我自己身上，此时该队友并不在我身边；同时这个错误
  施放的小队祝福会顶替我已选择的个人祝福buff」。
- 根因（三条通道，均在 Paladin_Blessing.lua）：
  ① 槽 95 是共享动态宏：战斗锁定下 SetAttribute 被静默丢弃，而旧回读校验只在
    「读到了且不同」时拦截，「读不到 / 空」会放行 → AHK 按键执行上一次的旧宏文本
    （可能是 [@player] 自施文本）→ 祝福上到自己，顶掉个人祝福；
  ② 小队模式下「自己」的祝福也走槽 95 直施 → 槽 95 里合法存在 [@player,help]
    自施文本，任何一次重写失败留下的残留都会自施；
  ③ 射程三层全读不到（战斗 secret）时 InCastRange 按「读不到放行」点亮，配合本服
    宏条件回退（超程 / 条件失败 → 退化施放 → 当前是敌对目标时友善法术自施）
    ——「队友不在身边 + 选中敌对目标 = 小队祝福上自己」。
- 修复：
  ① TryUnit 入口新增 WR_PaladinBlessing_PlayerTargetHostile 总闸：当前目标明确
    敌对 → 队友祝福本 tick 一律不点亮（读不到放行；个人祝福不受影响）；
  ② 小队/团队模式下「自己」的普通祝福改走自施宏 91~93（注册期静态文本，战斗中
    按键照常生效）→ 槽 95 从此只承载队友文本，结构上不可能再落到玩家身上；
  ③ CastDirect 新增 InCombatLockdown 硬闸（战斗锁定期拒绝直施、回落焦点流程），
    回读校验改严格：读不到 / 空 = 写失败，一律不点亮；
  ④ Auto 新增 WR_PaladinBlessing_RangeConfirmed 射程确认闸：三层必须有一层明确
    回答「在射程内」才点亮，全读不到按超程跳过（宁可不补，也不能误施）；
  ⑤ 超程 / 射程读不到时顺手 HideNow 收口残留色块，AHK 不会连按空键。
- 语义：小队祝福只作用于确认在射程内的队友；选中敌对目标时不给队友点亮；
  个人祝福（91~93 自施）独立生效，与小队祝福互不顶替。
- 验证：.workbuddy/test_paladin_blessing_misfire.py 28 项全过（敌对目标闸 / 超程 /
  射程读不到 / 战斗锁 / 回读严格 / 自施改道 / 正常直施 / 单元口径）；
  _syntax_all.py 193 文件 FAIL=0。


【防骑】2026-11-13（战斗中目标不在审判射程 → 不切「审判buff」对应圣印）
- 用户口径：「战斗中怪没有在近战位置，打不到也会切审判buff对应的圣印，
  导致和选择的圣印互顶，浪费了蓝」。
- 根因：光明圣印 / 十字军审判 / 智慧审判 三个常驻状态机点火只看审判 CD 窗口
  （JudgementSwitchDue），没有判目标射程——目标在审判 10 码外时照样切 buff 圣印，
  这发审判根本打不出去，白顶掉面板所选常驻圣印 + 白烧一次切印的蓝。
- 修复：三状态机入口各加「打得到才切印」总门：phase 0（新点火）且
  WR_PaladinForever_CanHitTarget("审判","target") 为假 → 本 tick 直接不切印，
  维持面板所选常驻圣印；已进入 phase 1~4 的流程照常收尾；距离读不到
  （999 / secret）放行，与主调度 judgeEligible 的射程口径一致。
- 校验：_syntax_all.py 193 文件 FAIL=0；light/crusader/wisdom toggle 与
  seal_switch_timing 夹具全通过；新增 .workbuddy/test_paladin_range_gate.py
  覆盖三状态机「射程外不切印 / 射程内正常切 / 中途脱离不卡死 / 999 放行」。

【术士】2026-11-13（无限服输出循环按参考图语义重写，面板零改动、仅术士作用域）
- 根因：旧 Forever 三系循环为 SoD 机械转译，读不存在的 FANG_ADD_WL 键、
  依赖无限已移除的符文/技能（鬼影缠身门、混乱箭等），且无 DOT 预判/护甲/
  召唤/拉条阈值/插入/切目标语义，与参考图功能面板脱节。
- 改动（仅 Warlock/ + 本日志块）：
  · Warlock_Forever.lua 重写为公共件：停手门/插入段(一次性自关+无脑火雨)/
    自保(红药30%+吸生命)/护甲(邪甲→恶魔皮肤回退/魔甲)/召唤(脱战静止)/
    宠物攻击/切目标(1秒防抖)/防ADD战斗门(按专精读 FANG_ADD_TKS/EMS/HMS)/
    拉条(分流30%·高血80%·魔杖50%，参考图默认值)/DOT(只补自己的·灾祸二选一)/
    读条引导(吸灵魂斩杀>灵魂之火>烧尽>灼热之痛>折磨>暗影箭，引导不打断)。
  · 三专精文件重写为薄壳传参；旧循环逻辑删除（非 Forever 仍回退旧 SoD 函数）。
  · Warlock_OOC_Summon_BExt.lua 追加 移动/吃喝/恶魔牺牲 三门。
  · Warlock_Macros.lua 新增槽 91折磨/92灼热之痛/93恶魔皮肤（键位空闲核对）+
    WR_SkillColor 登记复用槽 1/9/25/35/40/76/77/86/190/30/56。
- 兼容：血蓝 WR_GetUnitHP/MP、光环 WR_GetUnit*Time(ByMe)、可用性 WR_SpellUsable、
  色块 WR_ColorFrame_ShowSkill/WR_HideSkillColorSlot；不注册 CLEU、不裸算 secret；
  缺失技能（厄运诅咒等）经 WR_Forever_SkillAbsent 闸门自然跳过。
- 校验：lua_check.js 全量 FAIL=0；行尾保持（公共件/宏 LF，三薄壳 CRLF）；
  隔离基线 .workbuddy/warlock_scope_baseline_20261113.txt 核对仅允许清单变更；
  备份 *.bak-20261113wl。留痕 .workbuddy/memory/2026-11-13.md。

【法师·冰霜】2026-11-13（NGA 攻略二次核对：FoF 名称兼容 + 冰锥术单体收尾）
- 依据：NGA《[无限服] AFK回归，浅析无限服法师天赋与升级天赋分享》7 页纯图片版
  （123.pdf，逐页渲染成整页图后人工核对）；权威数据仍以
  https://talentsforever.com/export/mage.json 为准，攻略只作交叉验证。
- 核对结论（二者无冲突）：冰枪术 8 秒 CD / 对冻结目标 +300% 伤害；寒冰指
  等级 2/2（冰冷效果 15% 概率，下 2 次法术视为目标已冻结，持续 15 秒）；
  寒冰护体属核心天赋且要「注意冰盾的保持」；强化冰锥术 +35%、深冬之寒让
  冰锥术再 +20% → 冰锥术应进单体循环；冰霜新星用来提供冰冻效果；作者明确
  「三系输出循环都有一定复杂度，不存在一个技能搓到底」。
- 修正①（静默丢输出）Mage/Mage_Forever_Frost.lua：Fingers of Frost 的中文名在
  不同数据源不一致（攻略 / 游戏内 tooltip「寒冰指」 vs Data/Forever_Abilities.lua
  的 zh 与 Core/SoD_Runes.lua「冰霜之指」）。原代码只查「冰霜之指」单一名字，
  客户端若用另一个名字则 FoF 永远读不到 → 冰枪术碎裂窗口全部丢失，且不掉血、
  不报错。改为 WR_MageFrost_FOF_BUFFS 候选名列表（含英文 "Fingers of Frost"），
  任一命中即视为触发；保留 WR_MageFrost_FOF_BUFF 旧全局名作兼容别名。
- 修正②（输出链缺口）同文件 9.2 段：冰锥术原条件 `inMelee10 and UnitCount8 >= 2`
  把它锁死在多目标，单体永远轮不到。按攻略「可以作为收尾技能加入循环」「灵活
  使用冰锥术收尾」放宽为 `inMelee10`（贴身即用，含单体）。仍保留 10 码射程门、
  蓝量下限 0.15、10 秒本地 CD 记账与提示防抖；被挡住时继续走寒冰护体 /
  急速冷却 / 寒冰箭，不卡链。
- 文案同步：Mage/Mage_Menu.lua 的「智能AOE模式」tooltip 明确「本开关只门控暴风雪」，
  冰锥术贴身收尾不受该开关控制，避免文案暗示了代码里并不存在的门控关系。
- 校验：全量 Lua 语法双跑（lupa 193 文件 / luaparse Lua 5.1 772 文件，均 0 失败）；
  29 个既有夹具 + 新增 .workbuddy/test_mage_frost_nga.py（23 条断言）共 30 个
  全部 exit=0；TOC 引用完整性 184/184。独立审查记录见 .workbuddy/oa_final_report.md。

【全局】2026-11-12（修复「技能不够蓝释放时色块仍然亮，导致一直按空键」）
- 用户口径原话：「技能不够蓝释放时，应当不亮色块，导致一直按按键」。
- 现象链（色块模型）：法力不够 → 色块照样亮 → AHK 读色按键 → 客户端以
  「法力不足」拒绝 → 技能没出去 → 色块不灭（下一 tick 又点亮）→ AHK 继续按，
  形成空按死循环。
- 根因（三层，全部实测确认）：
  ① Core/Forever_Compat.lua 的 WR_IsSpellUsableCompat 只取 IsUsableSpell 的
     **第 1 个返回值**，把「缺法力」的第二返回值 noMana 彻底丢掉；很多客户端
     在法力不足时第 1 个返回值仍是 true（第 2 个才报缺资源）→ WR_SpellUsable
     恒 true → 色块常亮。12.x 的 C_Spell.IsSpellUsable 还可能返回 **table**
     { isUsable, insufficientPower }，旧代码把 table 直接当真值 → 同样恒 true。
  ② 完全没有「当前资源 vs 技能消耗」的比对，只能等客户端报错。
  ③ 色块是「亮着就一直按」的模型：各循环拦下时只 return false、**不熄灭**该槽位，
     上一 tick 的色块会一直挂着 → AHK 读到同色继续按。
- 修复（三层闸，读不到一律放行，宁可少判不可误杀）：
  ① 客户端回执归一（Core/Forever_Compat.lua）：
     · 新增 WR_Forever_ParseUsable / WR_Forever_TakeUsable：自适应多返回值与
       table 两种形状，noMana / insufficientPower=true → 直接判死；
     · 新增 WR_Forever_SpellPowerCost（GetSpellPowerCost / C_Spell 版，按
       spellID 缓存）与 WR_Forever_NotEnoughPower（cur < cost → 判死）；
       只判 法力0/怒气1/集中值2/能量3/符文能量6 五类，连击点/符文/碎片/圣能
       一律不判（避免误挡盗贼、德鲁伊、死骑、圣骑士）；
     · 负缓存（取不到消耗）改为 **3 秒过期** —— 旧实现永久记 false，登录初期
       法术书未就绪或换 rank 后该技能再也不会被资源检查，蓝不够照样常亮；
     · 探测统一改用 pcall（本仓库老坑：type(API)=="function" 在离线夹具里是
       "userdata"，会让整段守卫静默跳过）。
  ② 色块总闸（Core/SoD_Runes.lua WR_ColorFrame_ShowSkill）：
     · 新增 WR_SoD_NotEnoughPower（资源算术 + 客户端回执黑名单）；
     · 拦下时**主动熄灭该技能自己的槽位**（新增 WR_HideSkillColorSlot，
       只灭该技能、不动别的提示框）；
     · 新增 UI_ERROR_MESSAGE 监听：捕获「法力/能量/怒气不足」文案，把刚亮过的
       技能记进 2.5 秒短期黑名单并立刻熄灭 —— 战斗中资源是 secret 读不到时，
       只有客户端知道到底缺不缺，这条回执是唯一可靠证据；
     · 新增 WR_SoD_BeginTick / WR_SoD_SweepPowerBlocked：每 tick 收尾清扫，
       本轮一个色块都没点亮、而残留色块对应的技能现在资源不足 → 熄灭它。
  ③ 循环侧：WR_SpellUsable（全仓 ~300 处调用）自动受益；冰法 WR_MageFrost_Show
     的蓝量下限、圣骑 WR_PaladinForever_ShowSkillCD 与祝福 WR_PaladinBlessing_Show
     在拦下时同步熄灭该槽位。
- 校验：全量 Lua 语法 TOTAL=194 OK=194 FAIL=0；全部 28 个 test_*.py exit=0。
  新增夹具 test_power_gate.py（A~F 六段 30 条）：noMana 第二返回值 / table 形状 /
  资源算术边界（== 放行、> 放行、无消耗放行、读不到放行、非判资源不判）/
  总闸熄灭 / 回执黑名单与过期 / 每 tick 清扫四条路径 / MainLoop 静态接线。

【全局】2026-11-12（主面板：删除全局功能区「倒数偷药」开关）
- 用户口径原话：「删除全局功能区下的倒数偷药开关」。
- 改动范围（Core/UI_Config.lua 左侧 globalRegion）：
  · 删除「倒数偷药」复选框 WR_PrepullCheckbox、文字标签「倒数偷药」、
    OnClick/OnEnter/OnLeave 脚本，以及该处的 PigSet["DBM_PREPULL_POTION"] 默认值初始化。
- 关键联动：左区控件是**链式锚定**，「偷药时间」滑块（WR_TouyaoSlider）原锚在
  prepullCheckbox 下方。删掉复选框后已把该滑块改锚到「自动救人」rescueCheckbox
  （TOPLEFT → rescueCheckbox BOTTOMLEFT, -GLOBAL_ROW_H），保证整条布局链不断裂；
  leftContentH 仍为 660（链上移约 26px，余量更充足），窗口尺寸不变。
- 明确**未删除**的部分（避免误伤其它功能）：
  · 「偷药时间」滑块与 PigSet["TOUYAO_TIME"] 保留 —— 它经 WR_PrepullInWindow()
    控制全职业的「爆发预开窗口」（药水/饰品/种族/手套/血DK邪恶狂热等），
    与本次删除的 DBM_PREPULL_POTION 总闸不是同一件事；
  · 底层逻辑保留 —— Core/Combat_Tools.lua 的 WR_PrePullPotion_BExt /
    WR_PrePullPotions_BExt、Core/ZZ_Features_Migration.lua 的 TryPrePullPotion /
    WR_PrepullInWindow 及默认值 DBM_PREPULL_POTION=false 均不动。
    只移除 UI 入口，旧存档里已开启的值仍按原设置生效，不改变任何职业的循环行为。
- 校验：全量 Lua 语法 TOTAL=194 OK=194 FAIL=0；新增 test_config_prepull_removed.py
  （删除结果 + 锚点重接 + 其余全局控件仍在 + 底层逻辑未动），全部夹具 0 失败。
- /reload 后生效。

【圣骑士】2026-11-12（祝福：修复「队友不在附近时，队友的祝福上到自己身上」）
- 用户口径原话：「存在异常，当队友不在附近时，队友的祝福会上到自己身上
  导致与个人选择的祝福冲突」。
- 根因（两条同源，都是 **WoW 宏的条件回退 macro fallthrough**）：
  ① 直施宏 `/cast [@party1] 力量祝福` 里的 `[@party1]` 只是**条件**，不是硬目标：
     条件不成立（离队 / 死亡 / 单位 token 失效）时该条件被丢弃，
     `/cast` 退化成「无目标施放」→ 落到当前目标；没有目标时友善法术就落到
     **自己**身上 → 与单人选的那条互相顶掉 = 用户说的「冲突」。
     更糟的是 Paladin_Macros.lua 里槽 95 的**初始文本**原本是
     `/cast [target=player] 力量祝福`（纯自施）：CreateClassesMacro 每次脱战
     都重跑，只要动态重写有任何一次没写成功，按 ALT-F5 就是直接给自己上祝福。
  ② 焦点兜底宏 `/cast [@focus] 力量祝福` 同理：焦点为空、或焦点**还停在自己**
     身上（单人行 146 号槽就是 `/focus [@player]`，给队友切焦点失败时焦点
     留在自己）→ 祝福直接打给自己。
     而 WR_PaladinBlessing_FocusIs 原本「UnitIsUnit 读不到 → 返回 true」，
     战斗中 secret 时等于无条件放行，正好走进这条自施路径。
- 修复（Paladin/Paladin_Blessing.lua + Paladin/Paladin_Macros.lua）：
  · 新增 WR_PaladinBlessing_DirectMacroText：直施宏改成两段式硬闸 ——
      `/stopmacro [@partyN,noexists] [@partyN,dead] [@partyN,nohelp]`
      `/cast [@partyN,help] 祝福名`
    目标无效时 /stopmacro 让**整条宏立刻结束**（什么都不做），绝不回退成自施；
    /cast 行再带 [,help] 双保险。
  · 焦点祝福宏 102~107 全部改成同样的两段式硬闸（noexists / dead / nohelp）。
  · 槽 95 初始注册文本由 `/cast [target=player] 力量祝福` 改为裸 `/stopmacro`
    （无条件空转）：重写一旦没生效，按下去什么都不做，绝不误施。
  · WR_PaladinBlessing_CastDirect 写完宏后**回读 GetAttribute("macrotext") 校验**：
    战斗锁定导致 SetAttribute 被丢弃时宏还是上一次的旧目标，这时一律返回 false
    不点亮色块 —— 宁可不补，也不能把祝福打给错误的人。
  · WR_PaladinBlessing_FocusIs 增加两道保护：给队友补时先独立探测
    「焦点是不是自己」（是 → 强制走切焦点流程）；UnitIsUnit 读不到时不再
    无条件放行，改为「确认焦点不是自己才放行」。
- 夹具（新增 2 个，共 27 个）：
  · test_blessing_no_self_cast.py（静态，28 条）：直施/焦点宏必须带
    stopmacro 闸与 [,help]、槽 95 初始文本不得是自施、ALT-F5 只注册一次、
    FocusIs 探测焦点为自己、CastDirect 有 macrotext 校验、单人自施 91~93 不变。
    修复前 28 条全红，修复后全绿。
  · test_blessing_no_self_cast_dyn.py（动态，17 条）：真跑 Auto()，覆盖
    「宏写不进去 → 绝不点亮槽 95」「焦点==自己 / 读不到 → 绝不点亮队友的
    [@focus] 祝福」「队友超程 → 跳过且不退化成自施」「直施宏目标与本次要补的
    单位一致（不张冠李戴）」「单人自施不受影响」。
  · 三个既有祝福夹具里硬编码的 `"/cast [@party1] 力量祝福"` 断言改为
    语义解析 direct_cast_target()，只看「施放行的目标单位 + 法术名」。
- 校验：全量 Lua 语法 TOTAL=194 OK=194 FAIL=0；全部 27 个 test_*.py exit=0。

【法师】2026-11-12（冰霜：主循环接线复查 —— 修掉「输出被保底火球术穿插」与「脱战色块粘连」）
- 用户口径原话：「检查冰法在无限服客户端是否能正常输出，打主循环」。
- 复查范围（全部离线可验证，逐层走通）：
  · MainLoop.lua:976 → WR_MageForeverRotation()（MAGE 分支，10Hz OnUpdate）；
  · WR_GetMyTalent() → 无限服天赋 shim 第 2/5 返回值 → WR_Forever_NormalizeSpec
    → "冰霜"（SPEC_TREES.MAGE = {奥术, 火焰, 冰霜}），分发器 spec=="冰霜"
    → WR_MageForeverFrost()；isForever 由接口号 16000~16999 判定；
  · 9 个技能槽位逐条交叉核对 WR_MageFrost_SLOT / Mage_Macros.lua 的
    WR_SkillColor["MAGE"] / Core/UI_ColorFrame.lua 的 ColorTable(1..240) /
    外部 AHK ColorMap，全部一致且有绑定（60/44/27/26/11/65/32/63/18）；
  · WR_ColorFrame_ShowSkill → WR_SoD_ResolveSlot 优先宏表，缺失回退调用处槽位，
    不会点亮 ColorTable 之外的 key（不会触发 PIG_BGRtoBGR(nil) 崩溃）。
- 发现并修复的两个真机缺陷：
  ① 【输出被保底火球术穿插】寒冰箭（唯一无 CD 填充）带
     WR_MageFrost_PROMPT_DEBOUNCE=0.4s 提示防抖，而主循环是 10Hz(0.1s/tick)。
     防抖期内的 tick 返回 false → 分发器 WR_MageForeverRotation() 一看到 false
     就点亮「保底火球术」(槽 5)，于是冰法每 4 tick 有 3 tick 被 3.5 秒读条的
     火球术占掉。修复：仅当确实是「防抖空窗」时返回 true 表示冰法链已接管，
     阻止保底插入；其它失败原因（槽位非法 / 蓝量不足）仍返回 false 交给保底
     （保底自身有 noMana 门槛）。防抖空窗不点亮新色块是正确的：上一 tick 的
     寒冰箭色块保持常亮、AHK 同色连按继续打寒冰箭。
  ② 【脱战 / 超射程色块粘连】WR_ColorFrame_Show 每次成功点亮才「隐藏全部 →
     显示一个」；整条链返回 false 时没有任何 Show 调用，上一 tick 的色块会
     一直常亮，AHK 继续按（甚至可能在防ADD开的情况下自动开怪）。文件里早已
     写好 WR_MageFrost_HideNow / ClearPrompts 但从未接线。修复：在「战斗门
     return false」与「链末 return false」两处调用 WR_MageFrost_ClearPrompts()，
     按 WR_MageFrost_PromptSlot 精确 Hide 本循环自己的槽位（不碰焦点/跟随/BOSS
     等其它系统的色块），并清掉防抖计时便于下次进战立刻点亮；
     ★ 防抖空窗的 return true 路径绝不调用 —— 那里正是要靠常亮让 AHK 连按。
- 夹具：新增 .workbuddy/test_mage_frost_dispatch.py（端到端：分发器入口 →
  专精分派 → 点亮槽位；A 分发 / B 槽位交叉 / C 12tick 保底调用 0 次 /
  D 冻结窗口 / E 非冰霜·非Forever 兜底 / F 战斗门 / G 脱战熄灭与防抖不熄灭）。
  原有 test_mage_frost.py 的 A~M 段无回归。
- 校验：全量 Lua 语法 TOTAL=194 OK=194 FAIL=0；全部 25 个 test_*.py exit=0。
- 仍需真机 /reload 验证（离线无法覆盖）：UNIT_SPELLCAST_SUCCEEDED 的 spellID
  是否命中 WR_MageFrost_RANK_IDS、战斗中 aura 为 secret 时 frozen 判为 false
  后的降级链、AHK 实际按键与色块颜色的一致性、防ADD 面板默认值 FADD_BF=1。

【圣骑士】2026-11-12（祝福：新增「射程条件」——队友不在祝福射程内就跳过，不卡着用）
- 用户口径原话：「新增一个祝福条件吧，当队友不在技能释放范围的时候，
  不在卡着使用祝福buff」。
- 根因：旧距离门只有 UnitInRange（40 码「连线距离」），而且读不到就放行。
  但本服普通祝福的真实射程只有 30 码（数据源 talentsforever.com/export/paladin.json：
  Blessing of Might / Wisdom / Kings = "30 yd range"，
  Greater Blessing of * = "40 yd range"）。于是：
  ① 30~40 码之间的队友仍然被点亮色块 → AHK 按下去被客户端以「距离不够」拒绝
     → 色块灭了、buff 没上身；
  ② 这次无效点亮还占掉了本 tick 唯一的返回点，并记了 pending（2.5 秒）与
     施放单位（JustCast 8 秒宽限）→ 后面的队友全被这条「打不出去的祝福」卡住。
  两者合起来正是用户说的「卡着使用祝福buff」。
- 修复（Paladin/Paladin_Blessing.lua）：
  · 新增常量 WR_PAL_BLESS_RANGE = 30（普通祝福）、
    WR_PAL_BLESS_RANGE_GREATER = 40（强效祝福）、WR_PAL_BLESS_RANGE_SLACK = 2（分桶容差）；
  · 新增 WR_PaladinBlessing_CastRange / WR_PaladinBlessing_InCastRange：
    三层判定，任一层能明确给答案就用它，全部读不到才放行 ——
    ① IsSpellInRange(spell, unit)：1=在射程 / 0=超射程（最准，客户端按技能算，
       普通 30 / 强效 40 自动区分）；
    ② UnitInRange(unit)：false = 超 40 码 → 对两种祝福都算超程（保守否决）；
    ③ WR_UnitRange(unit)（LibRangeCheck）：数值距离 > 射程 + 2 码余量即超程。
    player 永远放行（自施不受距离限制）。
  · Auto() 主循环接入射程门，位置在 Needs 之前（连距离都不够就不必扫光环 / 判退避）：
    超程 → **跳过该单位**（不是 return false）→ 不点亮、不记 pending、不记 JustCast、
    不占 GCD 间隔闸，队列继续推进到下一个够得着的队友；
    同时收口该单位残留状态：清 pending + HideNow 熄灭该祝福的各槽位色块
    （防 AHK 读到旧色块继续连按）。
  · 语义保持：读不到距离（战斗中 secret / 库不可用 / 法术名解析不出）一律放行 ——
    宁可多点亮一次（AHK 按一下被拒绝，代价小），也不能因读值失败把全队挡在门外。
  · 面板说明追加一行「距离条件」文案，讲清 30/40 码与「走近了自动补上」。
- 夹具：新增 .workbuddy/test_blessing_cast_range.py（24 条断言，A~I 九段）：
  射程常量与权威导出数据一致 / 自己永远放行 / 射程内正常点亮 / 射程外不点亮且
  不写 pending 与直施宏 / 射程外队友不得卡住后面的队友（tick 继续推进）/
  读不到距离放行 / 超程收口残留状态 / 强效 40 码比普通 30 码宽（含 35 码分流）/
  静态接线（射程门在 Auto() 里且在 Needs 之前）。全部通过。
- 回归：全量 Lua 语法 TOTAL=194 OK=194 FAIL=0；祝福相关夹具
  （test_paladin_blessing.py 110 条、test_blessing_rebuff_stress.py、
  test_blessing_cast_range.py）全部通过，无回归。

【圣骑士】2026-11-12（祝福：修正「补祝福的时机太晚」——脱战不第一时间补 / 队友排队）
- 用户口径原话：「骑士祝福脱战了，没有第一时间补祝福」+「给队友加也是这样，
  补的时机太晚」。
- 根因（三条，均已用离线脚本量化复现）：
  ① 【队友之间撞 GCD】祝福是占 GCD 的主动技能，但旧实现完全没有 GCD 间隔闸：
     脱战瞬间 tick 点亮 player → AHK 按键 → 祝福打出（吃 GCD）；
     0.1 秒后 tick 又点亮 party1 并重写 ALT-F5 宏 → AHK 立刻按 → **GCD 还没转完，
     客户端直接拒绝** → 色块灭了但 buff 没上身；pending 再把该单位锁 8 秒
     → 才轮到 party2。离线实测 4 个队友分别在第 0.1 / 8.2 / 16.3 / 24.4 / 32.5 秒
     才拿到祝福，这就是「补得太晚」。
  ② 【JustCast 按法术名全局判定】给 player 打出「智慧祝福」后，8 秒内
     JustCast("智慧祝福") 对**所有单位**都返回 true —— 祝福明明是按单位生效的，
     给 A 加过跟 B 毫无关系，却让每个队友都白等 8 秒。
  ③ 【队友光环缓存永不自愈】旧的自愈重扫只针对 player
     （RepairPlayerAuraCache）。而 Core 的 WR_ScanAurasForUnit 在战斗中命中
     secret 就放弃扫描、保留 nil 缓存、却仍标记「已扫描」→ 队友永久读不到
     → 恒判「缺祝福」→ 走指数退避（10/30/60/120/300 秒）→ 补一次要等好几分钟。
- 修复（Paladin/Paladin_Blessing.lua）：
  · 新增 WR_PAL_BLESS_CAST_GAP = 1.2（一个 GCD）+ CastGapReady/NoteLightAt：
    点亮一次后隔一个 GCD 再处理下一个单位 —— 按键不再撞 GCD，队列也不再被
    pending 拉长。带时钟倒退保护，绝不因异常永久卡住。
  · JustCast(spellName, unit) 增加单位维度：新增 LastCastUnit 表 + NoteCastUnit，
    NoteLit 时登记「这条祝福这次是给哪个单位的」；只有「同一单位刚加过」才抑制，
    别的单位刚加过一律放行（单位未知的旧调用点保持原语义）。
  · PENDING_TTL 8 秒 → 2.5 秒（≈ GCD 1.5 秒 + AHK 读屏按键余量）：撞 GCD 被拒
    后不再白锁 8 秒。
  · PROMPT_CD 10 秒 → 3 秒：「读得到 + 确实没有」= AHK 漏按或被驱散，3 秒重试
    才对得上手感；反复刷已由 CacheUnreadable 指数退避单独处理，不再靠拉长重试
    间隔来防刷。
  · 新增 RepairUnitAuraCache：把缓存自愈重扫扩展到所有被遍历的队友单位
    （每单位独立节流 2 秒，避免全队读不到时每 tick 扫 25 个单位）；
    player 仍走原专用通道，保持「战斗 secret 态不做 force 重扫」的原语义。
- 效果（离线实测，修复前 → 修复后）：
  · 4 个队友全部拿到祝福：32.5 秒 → 5.3 秒，相邻间隔稳定 ≈ 1.3 秒（一个 GCD）；
  · 脱战后第一次补祝福：仍是脱战后第一个 tick（0.1 秒），不受本次改动影响；
  · 光环长期读不到 10 分钟：仍只点亮 ≤ 6 次（反复刷防护未被削弱）。
- 夹具：test_blessing_rebuff_stress.py 新增 H 段 8 条断言
  （H1a/H1b 脱战首 tick 就补、H2a/H2b/H2c 多队友排队 ≈ 一个 GCD、
  H3 同一条祝福给 player 后不挡队友、H4a/H4b 队友缓存自愈）；
  test_paladin_blessing.py 的 O1b/O3 改为「GCD 已过才推进到下一个单位」，
  reset_env 补清 LastLightAt / UnitRepairAt / LastCastUnit。
- 校验：全量 Lua 语法 TOTAL=194 OK=194 FAIL=0；全部 23 个 test_*.py exit=0。

【圣骑士】2026-11-12（祝福：彻底堵住「反复刷 buff」最后一条真机路径）
- 用户口径原话：「目前祝福有异常，单人的时候每次脱战会再次刷选择的对应
  buff，选择目标后还会再次刷一次，造成反复刷 buff 的异常」。
- 本轮复查结论：前四条修复（基础名匹配 / JustCast 宽限 / pending 待确认 /
  缓存自愈）覆盖了「读得到但不精确」与「短时间读不到」，但**还剩一条**：
  WR_AuraCache[unit] 整块为 nil 时（战斗中 C_UnitAuras 抛 secret、扫描被
  pcall 放弃、单位刚出现还没扫过），WR_GetAuraInfoCore 直接 return 0,0,0
  → BuffRemain 恒 0 → Needs 恒 true。而 JustCast 宽限只有 8 秒、pending 只有
  8 秒，两者一过就回到「每 WR_PAL_BLESS_PROMPT_CD(10 秒) 亮一次色块」
  → AHK 每 10 秒按一次 → 玩家看到的仍然是「反复刷 buff」。
- 复现：新增离线压力夹具 .workbuddy/test_blessing_rebuff_stress.py，
  按真机语义（精确名匹配 + 999 哨兵 + 过期残留不算有）连续 tick 仿真，
  统计「色块被点亮次数」= AHK 会按下多少次祝福键。修复前实测：
  · 光环长期读不到 10 分钟 → 点亮 60 次（正是每 10 秒一次）；
  · 刚施放后读不到 120 秒 → 点亮 13 次。
- 修复（Paladin/Paladin_Blessing.lua，新增「核心五」）：
  · WR_PaladinBlessing_CacheUnreadable(unit)：判定「整块读不到」
    （WR_AuraCache[unit] / .HELPFUL 不是 table）；
  · WR_PAL_BLESS_UNREADABLE_BACKOFF = { 10, 30, 60, 120, 300 }：
    读不到时的指数退避序列，封顶 5 分钟；
  · BackoffAllow / BackoffBump / BackoffClear：按 [unit|kind] 记等级，
    点亮一次推进一级；光环恢复可读 / 确认不需要补 → 立刻清零回正常节奏。
  ★ 关键区分（不能混为一谈）：
    「缓存表在、只是里面没这条祝福」= 真的没有 → 仍按 10 秒重试（正确）；
    「缓存整块缺失」= 读不到，有没有无法区分 → 必须退避，绝不按 10 秒刷。
  祝福本身持续 30~60 分钟，最坏晚 5 分钟补上，远好过每 10 秒白刷一次。
- 修复后同一夹具实测：长期读不到 10 分钟 → 点亮 3 次（原 60 次）；
  刚施放后读不到 120 秒 → 点亮 2 次（原 13 次）。
- 夹具：test_paladin_blessing.py 新增 S1~S7（整块缺失 vs 表在为空 /
  退避期内不点亮 / 等级封顶 / 恢复可读即清零 / 静态接线）；
  另新增 test_blessing_rebuff_stress.py（A~F 六段长时间仿真）。
- 校验：全量 Lua 语法 TOTAL=194 OK=194 FAIL=0；全部 23 个 test_*.py exit=0。

【圣骑士】2026-11-12（祝福：修复「小队队友加不上选择的祝福」）
- 用户口径原话：「目前不给小队队友加选择的对应祝福buff」。
- 根因（已用离线脚本复现整条路径）：祝福设置窗口「小队」4 行的存档 key
  用的是 row.curName，而它只在 WR_PaladinBlessing_Refresh() 里赋值一次
  —— 也就是**窗口打开的那一刻**。真实流程几乎必然是：
    ① 单人/刚上线时打开祝福窗口 → 还没组队，4 行全显示「（空）」，
       row.curName 全是 nil；
    ② 之后才被拉进小队 → 窗口没重开，row.curName 仍是 nil；
    ③ 玩家点「力/智/王」→ Toggle("party", nil, 1) 第一行
       `if scope ~= "solo" and key == nil then return false end` 直接返回
       → 存档里什么都没写（而且**完全静默**：格子不亮、也不报错，
         玩家只会觉得「点了没用」）；
    ④ 循环 Auto() 里 partyPick[队友名] 查不到 → 落到团队职业表 raidPick
       → 职业表没配就是 0（不加）→ 表现就是「选了祝福也不给队友加」。
- 附带同源 bug：Paladin_Macros.lua 里 ALT-F5（槽 95，小队/团队直施动态宏）
  被注册了**两次**，第二次是空宏 `WR_CreateMacro("ALT-F5", "")`，把上面刚
  注册的动态宏覆盖掉。CreateClassesMacro 在 PLAYER_ENTERING_WORLD 与**每次
  脱战**都会重跑 → 脱战瞬间槽 95 变空宏，一旦祝福模块没能在点亮前重写成功
  （宏系统异常 / 冷却跳过），AHK 按 ALT-F5 就是按了个空键 → 队友收不到祝福。
- 修复：
  ① Paladin/Paladin_Blessing.lua 新增 WR_PaladinBlessing_PartyName(index)：
     现场向客户端要 partyN 的名字。小队 4 行的 keyFn 改为
     `function() return WR_PaladinBlessing_PartyName(idx) end`
     —— 不再依赖「打开窗口那一刻」的快照，什么时候点都拿得到当前名字。
     （idx 用 local 固定住，避免闭包共享同一个循环变量。）
  ② Refresh() 里小队行标签也改走同一个函数，保证「标签显示的名字」和
     「点格子写进存档的 key」永远是同一个名字（不会出现标签显示甲、
     写进乙的情况）。
  ③ Toggle() 空行不再静默失败：打印「这一行还没有队友…先组队再点」。
  ④ 新增队伍名单变化事件监听（GROUP_ROSTER_UPDATE /
     PARTY_MEMBERS_CHANGED / RAID_ROSTER_UPDATE / PLAYER_ENTERING_WORLD）：
     队友进出时窗口自动刷新行标签与格子亮灭，不用手动关掉重开。
     事件帧用 WR_PalBless_Fn(CreateFrame) 做能力检测（夹具里接口是
     userdata，写死 type()=="function" 会被静默跳过 —— 本文件的老坑）。
  ⑤ Paladin_Macros.lua 删掉那行覆盖用的空 ALT-F5 注册，槽 95 只注册一次。
- 夹具：test_paladin_blessing.py 新增 R 段 8 条断言，把真实回归路径锁死：
  R3 单人状态建窗口（小队行全空）→ R4 窗口不重开也能写进存档
  （partyPick[队友甲]=1）→ R5 点完立刻 Auto() 真的点亮直施槽 95 且宏文本是
  /cast [@party1] 力量祝福 → R6 队伍名单变化事件触发后行标签跟着变 →
  R7 空行点格子拒写存档且不再静默 → R8 ALT-F5 只注册一次且非空宏。
  R1/R2 是静态接线断言。
- 校验：全量 Lua 语法 TOTAL=194 OK=194 FAIL=0；全部 22 个 test_*.py exit=0。

【圣骑士】2026-11-12（祝福：修复「反复刷 buff」——读值失败 ≠ 真的没有）
- 用户口径原话：「目前祝福有异常，单人的时候每次脱战会再次刷选择的对应
  buff，选择目标后还会再次刷一次，造成反复刷 buff 的异常」。
  用户截图证明自身 buff 栏里确实已有「智慧祝福 / 法术ID 19850 /
  每 5 秒恢复 18 点法力值 / 剩余 60 分钟」——祝福明明在身，插件还在提示补。
- 根因（两条同源路径，实测确认）：
  ① 本服光环名带「（等级 N）」后缀（如「智慧祝福（等级 3）」），而
     WR_GetUnitBuffTime 走 Core_Functions.lua 的 WR_GetAuraInfoCore
     `name == AuraName` 精确名匹配 → 恒返回 0 → Needs 恒 true →
     每 WR_PAL_BLESS_PROMPT_CD(10 秒) 重新点亮一次色块 → AHK 连按 → 反复刷。
     圣印模块（Paladin_Forever.lua:1391）踩过同一个坑：Lua 5.1 字符类按字节
     匹配，[（(] 写法对多字节全角括号不生效，必须两步字面量 gsub。
  ② WR_ScanAurasForUnit 用 pcall(doScan) 包住整段扫描：命中 secret 单位就
     放弃本次扫描、保留旧缓存（可能为 nil），但仍把 WR_AuraCacheScanned
     标成 true → 之后 WR_GetAuraInfoCore 读到 not cache 直接 return 0,0,0，
     永不重扫。于是「缓存坏掉」= 永久读到 0 = 永久认为没祝福。
  核心病症：**「读值失败」和「真的没有」被当成同一件事**。
- 修复（只动 Paladin/Paladin_Blessing.lua，不改 Core 热路径）：
  ① 名字容错：新增 WR_PalBless_StripRankSuffix / WR_PalBless_BaseName
     （两步字面量 gsub 剥全角/半角「（等级 N）」）+ 
     WR_PaladinBlessing_BuffRemainFromCache（扫 WR_AuraCache[unit].HELPFUL
     按基础名比较，明确看到才返回秒数/999）。BuffRemain 改为
     「精确名快路径 + 缓存基础名扫描」双通道取较大值，不依赖 spellID。
  ② 施放事件宽限：WR_PAL_BLESS_AFTER_CAST_GRACE = 8 秒，
     WR_PaladinBlessing_JustCast 用 UNIT_SPELLCAST_SUCCEEDED 维护的
     WR_Forever_LastPlayerCast 兜底 —— 刚刚确实打出过就不重复提示。
     ★ 额外加本地闩锁 WR_PaladinBlessing_LastCastAt：全局记录只保留
     最近一次施法，玩家打出祝福后常立刻接圣印/审判，0.1 秒内就被覆盖，
     只读全局记录等于没加保护。
  ③ 已点亮待确认：WR_PAL_BLESS_PENDING_TTL = 8 秒，
     NoteLit / IsPendingLit / SettlePending / Light 统一出口；
     点亮后 HideSkillLater(1.0)，下一 tick 一旦 Needs 变 false（buff 真上身）
     立刻 HideNow 熄灭，不再等保持到期（那 1.5 秒里 AHK 会继续连按）。
  ④ 缓存自愈：WR_PaladinBlessing_RepairPlayerAuraCache —— cache nil 时
     WR_ForceRefreshAuraCache("player")，2 秒节流 + 刚脱战强制一次。
     ★ 战斗态用 combatKnown 三分（true/false/读不到）：UnitAffectingCombat
     战斗中返 secret → 收敛成 nil，若据此判「刚脱战」会每 tick 走 force 重扫
     绕过节流，把热路径变成全量扫描。
  ⑤ 修复二（上一轮只读审计确认的结构缺陷）：Auto() 原来遍历单位时一遇到
     「在防刷屏冷却中」就 return false 直接结束整个 tick，而 units[1] 永远是
     player —— 自己的 10 秒冷却会把后面所有队友一起挡掉（实测「自己缺智慧 +
     队友甲缺力量」时队友甲永远轮不到）。现抽出 TryUnit 单单位逻辑，
     冷却中的单位改为「跳过」而非结束 tick，tick 继续推进到下一个单位。
- 夹具：test_paladin_blessing.py 622 → 1036 行、断言 110 条全绿（新增
  L/M/N/O/P 五段 40 条：带全角/半角等级后缀 / 999 / 快到期 / 已过期 /
  不同种不串味；刚施放宽限含「祝福后立刻接圣印、全局记录被覆盖，闩锁仍生效」；
  buff 上身立刻 HideNow / pending 内不重复 / 超时允许重提示；
  修复二三种场景；脱战强制重扫 + secret 战斗态不刷热路径）。A~K 原有断言无回归。
- 校验：全量 Lua 语法 TOTAL=194 OK=194 FAIL=0；全部 19 个 test_*.py exit=0。
- 备注（2026-11-12 已修）：Data/Forever_SkillRegistry.lua:124 与
  Core/Forever_Compat.lua:142 原写 ["智慧祝福"] = 19742，但截图实测 buff 工具提示
  法术ID 是 19850 —— 19742 是旧 rank1 的 ID（与力量祝福 19740→19834 完全同型的坑）。
  已把两处数据改为 19850；SPELL_ID_OVERRIDES 只在 IsPlayerSpell(19850) 为真时才采用，
  学不会时仍走法术书索引，故低等级角色不受影响。本文件祝福修复本身不依赖 spellID，
  修正前后的判定路径完全一致。

【法师】2026-11-12（冰霜：按 Forever 冰霜天赋树重写输出循环）
- 用户口径原话：「修复目前冰法循环」「当前魔兽世界版本是无限服，可以从 nga、
  抖音等平台获取最新的冰法输出循环，并实现该功能」。
- 数据源：https://talentsforever.com/export/mage.json（直接从 Forever 客户端
  数据文件导出，build 1.60.1.70755）。NGA 需登录（403）、抖音抓不到，
  这份客户端原始数据比二手攻略权威。
- 核实结论：Forever 冰霜树共 18 条天赋，**只有 4 条是主动技能**（passive:false）：
  冰枪术 r3c3（45 蓝 / 瞬发 / **8 秒 CD** / 对 Frozen 目标 +300% 即 4 倍伤害）、
  寒冰屏障 r4c2（15 蓝 / 瞬发 / 5 分钟）、急速冷却 r5c2（瞬发 / 10 分钟）、
  寒冰护体 r7c2（305 蓝 / 瞬发 / 30 秒 / 吸收 447 + 冰霜伤害 +15%，持续 1 分钟）。
  其余 14 条全部 passive（Frost Warding / Improved Frostbolt / Precision /
  Ice Shards / Frostbite / Improved Frost Nova / Permafrost / Frost Channeling /
  Improved Blizzard / Arctic Reach / Shatter / Improved Cone of Cold /
  Fingers of Frost / Winter's Chill），只能当判定条件，不能进循环。
  **「冰冷之血 / Icy Veins」在 Forever 冰霜树里根本不存在**（那是 SoD 腿符文）。
- 原实现 4 类问题（2 个会崩 / 1 个按错键）：
  ① 【主 bug】冰枪术判定写成 `if (fofProc or true)` —— **恒为真**；叠加
     「无限战斗中 GetSpellCooldown 是 secret → WR_GetGCD 收敛成 0 →
     WR_SpellUsable 恒 true」，导致每 tick 都点亮 44 号槽 → AHK 连按 →
     冰枪术在 8 秒 CD 里反复施放失败，**整条循环永久卡在第一行**，
     寒冰箭 / 暴风雪 / 冰锥术一次都轮不到。
  ② 【会崩】寒冰屏障 / 急速冷却 / 寒冰护盾 点亮 304 / 305 / 306 号槽，而
     Core/UI_ColorFrame.lua 的 ColorTable **只到 240** → WR_Frame_Color[304]
     为 nil → WR_CreateSingleColorSlot 把它送进 PIG_BGRtoBGR 做
     math.floor(nil / 0x10000) → **直接抛错，整个 tick 崩掉**。
     改为真实绑定了宏的 32（ALT-CTRL-NUMPAD2 /cast 寒冰屏障）、
     63（ALT-CTRL-F3 /cast 急速冷却）、65（ALT-CTRL-F5 /cast 寒冰护体）。
  ③ 【会崩 + 按错键】「冰冷之血」用了 4 号槽，而 4 号槽在本服绑的是
     `/CAST 活动炸弹`；技能本身也不存在 → 整条删除。
  ④ 【按错键】魔爆术点了 75 号槽，但 Mage_Macros.lua 里没有任何宏绑魔爆术，
     75 号槽实际是 `/petautocaston 水箭` → 点亮它会让 AHK 去开关水元素
     自动施法 → 已从优先级链移除。
  另外原实现全程裸用 WR_SpellUsable、没有本地 CD 记账（防骑 11-09 踩过同一个
  坑），天赋主动技能也没做「已学会」判定（没点天赋也会常亮）。
- 新优先级（Mage/Mage_Forever_Frost.lua 重写）：
  保命/资源：1 寒冰屏障（血量 <30% 且面板「自动冰箱」开）→ 2 唤醒（蓝量 <25%）
  单体/通用链：3 冰枪术（**仅当目标 Frozen 且 8 秒 CD 已好**）→
  4 冰霜新星（25 秒 CD，贴身且尚未冻结时开碎裂窗口）→
  5 暴风雪（面板「智能AOE」开且 8 码内 ≥3 目标，或勾了「插入暴风雪」）→
  6 冰锥术（10 秒 CD，≥2 目标且贴身）→ 7 寒冰护体（30 秒 CD，排在伤害链之后补）→
  8 急速冷却（仅当「目标 Frozen + 冰枪术在 CD」时，多开一个碎裂窗口）→
  9 寒冰箭（无 CD 填充，整条链的兜底）。
  ★ 关键取舍：冰枪术只在冻结窗口打，非冻结时绝不为「CD 好了」浪费这一发 ——
  这是原实现最大的错误。
- 实现要点：新增本地 CD 记账（WR_MageFrost_CastAt / CastAtByID 双通道 +
  UNIT_SPELLCAST_SUCCEEDED 接线，名字 secret 时靠 spellID 反查）；
  提示防抖 0.4 秒 + 色块保持 1.5 秒 + HideNow；
  **槽位合法性闸 WR_MageFrost_SlotUsable**（ColorTable 外一律不放行，防崩）；
  **已学会闸 WR_MageFrost_KNOWN_GATE**（4 个天赋主动技能）；蓝量下限表 /
  rank-ID 反查表 / 冻结 debuff 候选表。
  另修：`type(f) == "function"` 守卫在 lupa 夹具下会漏掉 C 侧 callable → 统一改 pcall。
- Mage/Mage_Macros.lua：WR_SkillColor["MAGE"] 把 301/302/303/304/305/306
  （ColorTable 不存在，历史遗留越界）改为真实宏槽位 15/16/22/32/63/65；
  「寒冰护盾」→「寒冰护体」（65 号槽宏的真实名字）并保留别名。
- Mage/Mage_Menu.lua：更新 3 条 tooltip（智能AOE / 急速冷却 / 自动冰箱）
  使其与新逻辑一致。
- 夹具：新增 .workbuddy/test_mage_frost.py（A~M 共 13 段），覆盖
  冰枪术 CD 记账（3s/7.9s 不打、8.05s 放行）、冻结窗口 4 种 debuff 名、
  非冻结不打冰枪术、冰霜之指等价 Frozen、单体/多目标/智能AOE 开关、
  蓝量门 6 档边界、14 条被动天赋 + 9 个不存在技能永不点亮、
  防抖与施放记账（含「事件名字 secret、只有 spellID」）、
  槽位合法性（9 个分支断言零 PIG_BGRtoBGR(nil) 崩溃）、保命链、
  急速冷却不拿大招换小 buff、防ADD 与射程门、完整链顺序。
- 校验：全量 Lua 语法 TOTAL=194 OK=194 FAIL=0；全部 21 个 test_*.py exit=0。
- ★ 顺手修掉同源的历史遗留（Lead 复核时发现，影响火法/奥法/旧 SoD 三系）：
  · 「魔爆术 = 75」号槽：Mage_Macros.lua 里 75 号槽实际绑的是
    `/petautocaston 水箭`（开关水元素自动施法），而全仓库**没有任何宏绑魔爆术**
    —— 火法/奥法/旧 SoD 三系点亮 75 时，AHK 会去开关水元素而不是放 AOE。
    修复：把原为空占位的 78 号槽（CTRL-SHIFT-F8；ColorTable 有、AHK 已映射
    ^+{F8}、且未被任何全局宏占用）绑成 `/cast 魔爆术`，
    WR_SkillColor["MAGE"]["魔爆术"] 由 75 改 78，
    五处调用点（Mage_Forever_Fire / Mage_Forever_Arcane / Mage_Arcane /
    Mage_Fire / Mage_Frost）的回退槽位一并从 75 改 78。
  · 「冰冷之血 = 4」号槽：4 号槽实际绑 `/CAST 活动炸弹`，且 Forever 冰霜树里
    根本没有冰冷之血 → WR_SkillColor 里这条登记已注释删除，避免后续接入者误用。
- 备注（未改动）：Data/Forever_Abilities.lua 里 Ice Barrier 的 zh 写「寒冰护盾」，
  但客户端真名是「寒冰护体」（Mage_Macros.lua 65 号槽宏即 /cast 寒冰护体）。
  本次按客户端真名实现并在 WR_SkillColor 保留别名。

【法师】2026-11-12（新增：法师法术书 SpellID / IconID 速查表）
- 用户口径原话：「目录下 fengfeng，这是我存放目前法师所学的技能，你可以记住
  这些技能法术图标 id，用于后面的功能开发」。
- 素材：fengfeng\ 下 29 张游戏内「法术书」截图，逐张读出 tooltip 上的
  SpellID / IconID / 等级 / 消耗 / 施法 / CD / 射程。
- 新增 Data\Forever_MageSpells.lua（toc 第 82 行，排在 Data 段末尾）：
  · WR_Forever_MageSpells：29 条表项（18 奥术 / 3 火焰 / 8 冰霜）；
  · 三个索引表：WR_Forever_MageSpellIndex（按名）、
    WR_Forever_MageIconIndex（按图标，可反查撞车）；
  · 四个查询函数：WR_Forever_MageSpell / _MageSpellID /
    _MageIconID / _MageNamesByIcon；
  · 调试命令 /mkmagespells 打印整张表。
- 关键 ID（可直接用于 Mage_Menu.lua 的 IconID 字段）：
  火球术 8402/135812、火焰冲击 8413/135807、烈焰风暴 8422/135826、
  寒冰箭 8408/135846、冰枪术 1240044/135844、冰锥术 8492/135852、
  暴风雪 8427/135857、冰霜新星 865/135848、寒冰屏障 11958/135841、
  霜甲术 7301/135843、冰甲术 7302/135843、奥术智慧 1461/135932、
  奥术飞弹 8416/136096、魔爆术 8439/136116、法力护盾 8495/136153、
  法术反制 2139/135856、缓落术 130/135992、解除次级诅咒 475/136082、
  变形术 12824/136071、闪现术 1953/135736、唤醒 12051/136075、
  制造魔法玛瑙 759/134104、制造魔法翡翠 3552/134105、
  造水术 6127/132797、造食术 6129/133950、魔甲术 6117/135991、
  传送：奥格瑞玛 3567/135759、传送：幽暗城 3563/135766、
  传送：雷霆崖 3566/135765。
- 校验：29 条 spellID 无重复；图标仅 135843 被霜甲术/冰甲术共用（已注释提醒
  按图标反查会撞，优先按名查）。SpellID 与截图上的法术等级完全吻合
  （火球术 8402=Rank7、寒冰箭 8408=Rank7、奥术飞弹 8416=Rank4 等），
  说明取到的数字可信。
- 注意：冰枪术是 7 位 1240044，属无限新增段（1200000..1400000），
  不是经典段的 30455/42872 —— 后续写循环时别用错。

【圣骑士】2026-11-12（防护：修正 buff 维持开关「切圣印的时机」）
- 用户口径原话：「防骑需要修正各项维持buff常驻开关切圣印的时机，当审判cd还有
  2秒钟恢复使用时目标没有对应审判buff，这时候再切选择的对应圣印打审判，
  不要第一时间开启了维持审判buff的开关后就切对应圣印等审判使用」。
- 旧行为：勾选「光明圣印 / 十字军审判 / 智慧审判」开关后立刻切走常驻圣印，
  然后干等审判 CD 转好（最长近 10 秒）—— 这段时间没有常驻圣印的仇恨/嘲讽收益。
- 新行为（三个开关统一）：
  · 审判剩余冷却 > 2 秒 → 维持面板「圣印」专区所选常驻圣印，不切印；
  · 审判剩余冷却 ≤ 2 秒（含已就绪）+ 目标没有对应审判 debuff → 才切 buff 圣印 → 打审判；
  · 已经切过去（phase1/2）继续占着，直到审判打出并切回常驻圣印；
  · 40 秒 debuff 到期后同样先等下一个「审判 CD ≤2 秒」窗口，不再第一时间切印。
- 实现：
  · Paladin/Paladin_Forever.lua 新增 WR_PaladinForever_JudgementRemain /
    WR_PaladinForever_JudgementSwitchDue（窗口常量 JUDGE_SWITCH_LEAD = 2.0，
    单 tick 记忆避免重复探测 CD）。
  · Paladin/Paladin_Forever_Prot.lua 新增 WR_PaladinForever_BuffSealHolds(phase, cd)，
    三个状态机 phase0 先过窗口、ProtSealGoal 与主调度「让出审判」判断统一走它；
    窗口外 phase0 视为「维持常驻圣印」，审判仍由主调度正常打（不会被没到窗口的
    流程占住）；窗口外若身上还挂着 buff 圣印，仍会提示切回常驻圣印（不干等）。
- 面板 tooltip 三个开关同步改写（说明「审判 CD 只剩 2 秒才切印」）。
- 回归：新增 .workbuddy/test_paladin_seal_switch_timing.py（A-L 共 23 项，
  覆盖 8 秒不切 / 3 秒不切 / 2 秒切 / 已就绪切 / debuff 到期不第一时间切 /
  phase1 不看窗口 / 十字军与智慧同款 / 窗口外不让出审判 / 窗口内让出审判 /
  窗口外挂错印切回 / 目标已有 debuff 不切印 / 常量与源码静态断言）；
  原有 test_paladin_light_seal_toggle、test_paladin_crusader_seal_toggle、
  test_paladin_wisdom_judgement_toggle、test_justice_seal_loop、
  test_paladin_prot_gate、test_paladin_prot_aoe 等全部通过。

【圣骑士】2026-11-12（祝福：修复「团队裹自己不跟随单人行选择」）
- 上一轮只读审计确认的遗留问题：小队已修「单人行选择被忽略」，但团队模式
  没有同样的跟随 —— 团队里自己只按职业表 raidPick[classToken] 加祝福，
  单人行（角色名那一行）选的格子被完全忽略。
- 修复（Paladin/Paladin_Blessing.lua WR_PaladinBlessing_UnitPick raid 分支）：
  团队状态下「自己」（unit=player）且单人行选了 1/2/3 → 跟随单人行种类，
  仍用强效祝福（团队段口径不变）；单人行没点（0/未设置）才回落职业表。
  队友仍按职业表+团队表，行为不变。
- 未动：审计的「修复二」（Auto() 点亮一个就 return，队首自己可能挡住队友
  的排队节奏）保持只读状态，待单独确认后再改。
- 回归：.workbuddy/test_paladin_blessing.py 新增 E5（团队自己+soloPick=2 →
  智慧、强效）、E6（soloPick=0 → 回落职业表、强效），原有 E1-E4/H/J/K 全部
  通过；审计脚本 .workbuddy/_audit_group_bless.py 团队段实测点亮
  @player 强效智慧祝福。

【圣骑士】2026-11-12（祝福：修复「单人选了智慧还是只会亮力量」）
- 用户口径原话：「单人我选择了智慧还是只会亮力量」。
- 根因：祝福设置窗口的「单人」行只在**单人状态**下生效；但多开组队后
  （哪怕队伍里只有自己一个人），状态切到「小队」，自己走的是小队分支 ——
  小队 4 行只列 party1~4，没有"自己"这一行，单人行选的格子被完全忽略，
  自己直接落到职业表（圣骑士行若是力量，看到的就是一直亮力量祝福）。
- 修复（Paladin/Paladin_Blessing.lua WR_PaladinBlessing_UnitPick）：
  小队状态下「自己」（unit=player）没被小队行单独点过时，跟随单人行
  （角色名那一行）的选择，普通祝福；单人行没点（0/未设置）才回退职业表。
- 单人状态行为不变：soloPick 直接点亮自施槽 91/92/93（ALT-F1/F2/F3）。
- 回归：.workbuddy/test_paladin_blessing.py 新增 H4w（单人选智慧→槽92
  智慧祝福）、H4k（王者→槽93）、H4p/H4p2（小队状态自己跟随单人行→
  直施宏 /cast [@player] 智慧祝福），全部通过。

【圣骑士】2026-11-12（祝福：单人/小队/团队全程不切焦点，直接施放）
- 用户口径原话：「单人可以不用设置焦点直接使用加祝福buff」「小队，团队祝福也
  可以不用焦点直接加」。
- 单人：启用空占位宏槽 91/92/93（ALT-F1/F2/F3）为自施宏
  /cast [target=player] 力量/智慧/王者祝福；单人补祝福直接点亮对应槽，
  不再「先切焦点到自己 → @focus 宏」，也不受当前目标影响。
- 小队/团队：启用空占位宏槽 95（ALT-F5）为「直施动态宏」，每次补祝福前
  把宏文本重写为 /cast [@partyN|@raidN] 祝福名 再点亮槽 95 —— AHK 按
  ALT-F5 直接对该队友施放，全程不占用焦点；普通/强效祝福按段自动区分。
- 焦点流程保留为兜底：宏系统不可用（如离线环境）时才回落
  「切焦点 + [@focus] 宏 102~107」，行为与旧版一致。
- 防刷屏沿用同一规则（同一单位同一祝福 10 秒内不重复点亮）；
  停手条件（战斗/坐骑/吃喝/死亡/打字）与三段勾选不变。
- 回归：.workbuddy/test_paladin_blessing.py 更新为断言自施槽 91 / 直施槽 95
  与动态宏文本，全部通过；slot_key_audit 校验 91/92/93/95 链路一致。

【圣骑士】2026-11-12（祝福设置窗口：修复说明文字被控件遮挡）
- 用户反馈原话：「祝福设置界面中的字体也出现异常，被掩盖了」。
- 根因：顶部说明文字 6 行在 380px 宽度内自动折行成约 10 行（实际高约 170px），
  而下方「- 额外条件 / 祝福（总开关）/ 单人」按写死的 110px 起排，
  说明文的后几行正好被这三行控件压住，看起来就是文字异常 / 被掩盖。
- 修复（Paladin/Paladin_Blessing.lua）：
  · 说明块高度改为 GetStringHeight 实测（+8px 间隙），下方控件跟着实际高度排；
    实测不到（离线夹具 stub）时保持 110 不变，旧行为与回归断言不受影响；
    实测值比 110 还小也仍按 110，绝不比旧版排得更挤。
  · 说明文与「进了小队才列出队友」小字从 11px 提到 12px，与全窗口文字一致，
    中文小字渲染发糊的问题一并消除。
- 回归：.workbuddy/test_paladin_blessing.py 全部通过（I/K 几何断言不变）。

【圣骑士】2026-11-11（祝福下拉框 → 「祝福设置」按钮 + 独立列表）
- 用户口径原话：「骑士将祝福下拉框删除，更改为祝福按钮，放在打断下方，
  按钮打开后是一个祝福设置的单独列表，列表如图所示功能」。
- 下拉框：删除三专精「祝福」下拉（CJ_ZF / FH_ZF / SS_ZF）；旧存档字段与
  FH_ZF_V2 迁移标记由 ZZ_Features_Migration 清理；旧的 WR_PaladinForever_Blessing
  系列保留但弃用，三专精循环改走 WR_PaladinBlessing_Auto()。
- 按钮：Core/UI_Config.lua 的 DM 列表新增 isButton 按钮行支持；三专精菜单区
  末尾各加一个「祝福设置」按钮，防护的按口径放在「打断」滑块正下方。
- 独立列表（新增 Paladin/Paladin_Blessing.lua，toc 已加载）：
  · 额外条件「祝福」总闸；单人 / 小队 / 团队三段各自勾选（去掉「团队」的勾，
    进了团就不自动补）。
  · 每行 4 个格子（力量 / 智慧 / 王者 / 无），每行只亮一个、再点一下取消；
    小队一人一行按名字存，团队一个职业一行按职业存；点「无」= 明确不加。
  · 单人/小队用普通祝福、团队用强效祝福；身上没有或快到期才补，
    别的骑士加的同一种（普通或强效）也算有。
  · 战斗中 / 坐骑 / 吃喝 / 死亡 / 打字时不补；给队友加时先切焦点再用
    [@focus] 祝福宏（102~107）施放。
  · 命令 /palbless 或 /祝福 打开列表。
- 回归：新增 .workbuddy/test_paladin_blessing.py；其余夹具不变。

【全职业】2026-11-11（删除「命令清单」功能与按钮）
- 用户口径原话：「插件中命令清单功能删除，按钮也删除」。
- 删除 Core/UI_CommandList.lua（ZZ_CMDLIST_DATA 数据表、ZZ_CmdList_* 独立查询界面、
  /zzcmd /cmdlist /mkhcmd /命令清单 斜杠命令），MKHelperForever.toc 移除加载项。
- 删除主界面顶栏「命令」按钮；功能设置弹窗删除「命令清单」分区，
  「更新公告」前移为分区3，顶栏「更新」按钮同步指向 sectionIdx=3。
- 各开关的斜杠命令仍由菜单复选框（UI_Config.lua 通用注册）与
  Paladin_Forever.lua 的显式注册提供，删除查询界面不影响任何开关功能。

【全职业】2026-11-11（关闭插件中所有屏幕文字提示）
- 用户口径原话：「把插件中屏幕文字提示都关闭了」。
- 新增总闸 PigSet.ScreenTextNotice（默认关闭）：WR_ScreenTextNoticeEnabled() 定义于
  Core/Forever_Compat.lua（最先加载），所有文字输出通道统一在此判定。
- 覆盖的通道：
  · PigAlert 屏幕中央大字（Core/TIP.lua 统一拦截全部 11 处调用；/pg 测试命令同步）；
  · 色块/技能图标上叠加的技能名文字（Core/UI_ColorFrame_1.lua：仅 Hide 文字、保留 SetText，
    色块颜色框架照常 Show，AHK 取色与读取 GetText 的逻辑均不受影响）；
  · 聊天框开关提示保持开启（用户后续要求「希望聊天框的开关提示继续保留」，未接入总闸）；
  · WR_MessageWindows 版本通信弹窗、/wrdebug 调试 HUD 文字。
- 面板：左侧全局区「开关提示」复选框改为「屏幕文字提示」总闸，默认不勾选；
  新增 /screentip on|off|status；/pigchat 1|2 会顺带打开总闸，避免设了模式却看不到提示。
- 不影响：色块颜色本身（AHK 取色）、循环判定与技能提示逻辑、手动执行的诊断/调试命令输出。

【防骑】2026-11-11（修复：十字军审判 buff 维持反复施放十字军圣印）
- 用户口径原话：「开启了维持十字军审判buff选项后，会出现反复使用十字军圣印的情况」。
- 根因：战斗中 UNIT_SPELLCAST_SUCCEEDED 的 spellName / spellID 可能都是 secret，
  事件认不出具体圣印。旧版「终极兜底」只记了通用 LastSealCastAt，没有写
  CrusaderSealCastAt 与 LastSealAppliedName；而十字军审判状态机在该圣印光环不可读时
  只能靠这两个字段判断「十字军圣印是否在身上」→ 永远判不在 → 每 1~2 秒重新点亮
  十字军圣印色块 → AHK「同色常亮就一直按」→ 反复施放十字军圣印。
- 修复：圣印色块点亮时记录具体圣印名（SealPromptLitName）；施放事件完全认不出名字时，
  用「刚刚点亮过的圣印」反推，统一写入 RecordSealAppliedByName（LastSealAppliedName +
  对应圣印的专用 CastAt）；只剩 spellID 时也先按 ID 反查具体圣印名再记账。
  同时 JudgeSealOnPlayer 在切印后 2 秒内允许施放记录覆盖光环缓存的旧值，避免
  状态机因缓存延迟误判「没切成功」而回到 phase0 重复提示。
- 回归：test_paladin_crusader_seal_toggle.py 新增 J 段（匿名施放事件 → 不重复点亮）。

【全职业】2026-11-11（删除全局区「智能AOE」功能与选项）
- 用户口径原话：「删除全局区下的，AOE功能和选项」。
- 面板：左侧全局区删除「智能AOE」分类及「智能AOE（自动）」「手动AOE（爆发）」两个复选框；
  调试模式等其余全局控件整体上移，左区高度同步收敛。
- 代码：删除 Core/SmartAOE.lua（WR_ShouldUseAOE / WR_GetEnemyCountInRange / 调试开关），
  并从 MKHelperForever.toc 移除加载项。
- 兼容：旧存档 WR_GLOBAL_SMART_AOE / WR_GLOBAL_MANUAL_AOE 由 ZZ_Features_Migration 清理。

【全职业】2026-11-11（所有分区支持折叠：同步「圣印」区折叠方案）
- 用户口径原话：「将圣印区的折叠方案，同步到其他区中」。
- 面板：所有天赋面板的分类标题条统一支持点击折叠/展开，不再只有「圣印」「审判buff」两个专区；
  自动 / 爆发 / 审判buff / 圣印 / 插入 五个分区各自独立保存状态，互不影响，重载后保持。
- 状态键：自动=FH_AUTO_SECTION_COLLAPSED / 爆发=FH_BURST_SECTION_COLLAPSED /
  审判buff=FH_JUDGEMENT_BUFF_SECTION_COLLAPSED / 圣印=FH_SEAL_SECTION_COLLAPSED /
  插入=FH_INSERT_SECTION_COLLAPSED。
- 外观：标题条右侧显示 +/-，点击标题条即可折叠/展开；折叠后该分区图标、复选框与文字隐藏，面板高度自动收缩。
- 回归：新增 test_config_section_collapse.py（五个分区逐一折叠/展开 + 布局高度变化）。

【防骑】2026-11-11（自动循环：神圣之盾后移到奉献之后，删除制裁之锤）
- 用户口径原话：「这条循环里，神圣之盾放在奉献后面，循环里删除制裁之锤」。
- 循环：目标 ≤1 的单体链顺序改为 神圣打击（CD 优先）→ 审判 → 驱邪术 → 奉献（该链不可达）→
  神圣之盾 → 愤怒之锤；神圣之盾不再抢在驱邪术前面。
- 删除：自动循环不再提示「制裁之锤」（原第 11 步）；面板「插入 制裁之锤」一次性手动开关保留，
  需要眩晕/打断时仍可手动勾选。
- 多目标固定链不变（奉献 → 审判 → 神圣打击 → 驱邪术 → 神圣之盾）；删除制裁之锤后其收尾只剩愤怒之锤。
- 回归：test_paladin_prot_gate.py 新增 G15/G15b（单目标驱邪术先于神圣之盾、非亡灵落到神圣之盾）
  与 G9b（目标近身施法也不自动提示制裁之锤）。

【防骑】2026-11-11（buff 维持按钮改为「审判buff」专区，可折叠）
- 用户口径原话：「再将维持buff的功能按钮，设置审判buff专区并且可以折叠，位置放在圣印上面」。
- 面板：把「光明圣印」「十字军审判」「智慧审判」三个 buff 维持开关从「自动」分组移入新的「审判buff」专区；
  分类顺序为 自动 → 爆发 → 审判buff → 圣印 → 插入。
- 折叠：与「圣印」专区同款，标题条右侧显示 +/-，点击折叠/展开；状态保存在 FH_JUDGEMENT_BUFF_SECTION_COLLAPSED，重载后保持。
- 回归：相关夹具的分组断言改为「审判buff」；test_paladin_seal_dropdown.py 新增分区顺序、折叠键与三个开关归属检查。

【防骑】2026-11-11（新增「智慧审判」buff 维持开关）
- 用户口径原话：「同样的功能，帮我添加智慧审判的buff维持按钮」。
- 面板：防护「自动」分组新增「智慧审判」buff 维持开关（saveVariable=FH_ZHSP，图标 135970），
  与「光明圣印」「十字军审判」同款状态机：勾选后优先维持自身智慧圣印，目标没有「智慧审判」
  debuff 时用智慧圣印打审判（攻击/法术有几率回蓝），目标已有 debuff 时自动切回常驻圣印
  （「圣印」专区所选，默认愤怒圣印），40 秒到期后自动重复；未学会智慧圣印/审判时自动跳过。
- 互斥：「光明圣印」「十字军审判」「智慧审判」三个 buff 维持开关同属 PAL_PROT_JUDGEMENT_SEAL，
  同时只能开启一个；三者均可与「圣印」专区所选常驻圣印共存。
- 联动：开启「智慧审判」buff 维持时，一次性「插入智慧圣印」(FH_CRZHSY) 自动取消，避免两条流程抢审判。
- 命令：新增 /FH_ZHSP。
- 回归：新增 test_paladin_wisdom_judgement_toggle.py；test_paladin_crusader_seal_toggle.py 的互斥数量断言改为 3。

【防骑】2026-11-11（圣印常驻 buff 按钮与圣印专区所选圣印共存）
- 用户口径原话：「圣印常驻buff按钮，可以与圣印区所选的圣印共存同时」。
- 面板：防护「自动」分组的「光明圣印」「十字军审判」两个 buff 维持开关不再因
  「圣印」专区已选同种圣印而自动取消勾选；两者可与所选常驻圣印共存，
  常驻已选光明圣印 / 十字军圣印时开关同样有效。
- 循环：常驻圣印与 buff 开关目标相同时，状态机照常维持该圣印并挂对应审判 debuff，
  仅省略「切回常驻圣印」这一步（避免重复提示上同一种圣印）；40 秒到期后继续循环。
- 互斥：「光明圣印」与「十字军审判」两个 buff 维持开关之间仍互斥（同时只能开一个）。
- 回归：test_paladin_light_seal_toggle.py / test_paladin_crusader_seal_toggle.py /
  test_paladin_light_seal_mode.py / test_paladin_seal_dropdown.py 的「同种圣印自动取消」
  用例改为「保持勾选并正常进入状态机」。

【防骑】2026-11-11（圣印专区拖出宏移除 /cast 行）
- 用户口径原话：「圣印区中创建的宏，需要删除/cast 技能，不需要这一项」。
- 面板：圣印专区六个单选按钮拖到动作条生成的宏不再包含 /cast 行，只保留：
  #showtooltip <圣印名> / FH_SEAL <序号>（例：拖「愤怒」生成 #showtooltip 愤怒圣印 + /FH_SEAL 3）。
- 说明：圣印的实际施放由循环提示 / AHK 色块链路负责，宏只用于切换常驻圣印选项。
- 回归：test_config_seal_radio.py 的 G 段新增「宏不含 /cast 行」断言。

【防骑】2026-11-11（删除「单体循环」；新增「十字军审判」buff 维持）
- 用户口径原话：「删除单体循环，根据光明圣印审判功能，新增十字军审判buff维持」。
- 删除：面板「单体」(FH_DT) 开关与 Paladin_Forever_Prot.lua 的 14.5 单体起手状态机
  （十字军圣印 → 审判 → 切回常驻圣印）整体移除；旧存档 FH_DT 由迁移清理，/FH_DT 命令删除。
- 新增：防护「自动」分组新增「十字军审判」buff 维持开关（saveVariable=FH_SZJSP），
  与「光明圣印」开关同款状态机：勾选后优先维持自身十字军圣印，目标没有「十字军审判」
  debuff 时用十字军圣印打审判，目标已有 debuff 时自动切回常驻圣印（圣印专区所选），
  40 秒到期后自动重复；未学会十字军圣印/审判时自动跳过，不影响循环。
- 互斥：「光明圣印」与「十字军审判」两个 buff 维持开关同属 PAL_PROT_JUDGEMENT_SEAL，
  同时只能开启一个（两者都需要抢占圣印，避免互相顶印）。
- 命令：删除 /FH_DT；新增 /FH_SZJSP。
- 回归：test_paladin_prot_gate.py 删除 G14a-G14d 单体起手用例；test_paladin_prot_aoe.py
  删除 I 段单体让位用例；新增 test_paladin_crusader_seal_toggle.py 覆盖十字军审判状态机。

【防骑】2026-11-11（圣印专区图标按实际图标 ID 更新）
- 用户口径原话：「十字军圣印图标id是135924，愤怒圣印图标id是135957，正义圣印图标ID是132325，光明圣印图标135917，根据图标id修改对应功能的图标显示」。
- 面板：圣印专区按钮图标改为对应图标 ID —— 十字军=135924 / 正义=132325 / 愤怒=135957 / 光明=135917；
  「光明圣印」常驻开关图标同步改用 135917，与光明圣印按钮一致。
- 说明：智慧、公正未提供新图标 ID，保持原有图标不变。

【防骑】2026-11-11（「圣印」专区按钮支持拖出宏）
- 用户口径原话：「圣印区下的按钮，我需要它们都可以拖动创建宏使用」。
- 面板：圣印专区六个单选按钮均可按住图标拖到动作条，生成对应圣印的组合宏：
  #showtooltip <圣印名> / cast <圣印名> / FH_SEAL <序号>（例：拖「愤怒」生成 愤怒圣印 + /FH_SEAL 3）。
- 通用：Core/UI_Config.lua 的 WR_PickupToggleMacro 支持 radioVariable/radioValue 配置；
  同一个按钮重复拖动会复用既有宏，不重复占用宏位；战斗中拖出仍会被拦截并红字提示。
- 回归：test_config_seal_radio.py 新增 G 段，验证六个按钮都能拖出、宏命令带正确序号且可复用。

【防骑】2026-11-11（「圣印」下拉框改为「圣印」专区按钮，可折叠）
- 用户口径原话：「圣印我不喜欢下拉框的，给我设置成按钮，单独弄一个圣印专区，此专区在爆发区下，可以折叠」。
- 面板：删除防护 DM 的「圣印」下拉框；在「爆发」分类下方新增可折叠的「圣印」专区，
  6 个单选按钮 = 十字军(30) / 正义(47) / 愤怒(11，默认) / 光明·回血(54) / 智慧·回蓝(108) / 公正(9)。
  点击任一按钮即把 FH_SEAL 设为对应序号，同组其它按钮自动取消勾选。
- 折叠：标题条右侧显示 +/-，点击折叠/展开；状态保存在 FH_SEAL_SECTION_COLLAPSED，重载后保持。
- 命令：/FH_SEAL 1-6 保留（不再由下拉控件自动注册，改为显式注册）。
- 回归：test_paladin_seal_dropdown.py 改为按钮静态检查 + test_config_seal_radio.py 验证单选逻辑。

【防骑】2026-11-11（恢复「圣印」下拉框：可选常驻圣印）
- 用户口径原话：「帮我加回来 > 可选常驻圣印」。
- 面板：防护专精下拉区恢复「圣印」下拉框（saveVariable=FH_SEAL，默认 3=愤怒圣印）：
  1=十字军圣印(30) 2=正义圣印(47) 3=愤怒圣印(11)
  4=光明圣印·回血(54) 5=智慧圣印·回蓝(108) 6=公正圣印(9)
- 循环：WR_PaladinForever_MainSeal() 统一读 FH_SEAL 映射名称/槽位/施放计时字段；
  补印、进战补印、单体起手收尾、光明圣印开关的切回全部跟随下拉选择。
- 兼容：FH_GMSY=true → 4（光明·回血）；否则 FH_ZYSY=true → 2（正义）；否则 3（愤怒）；
  已有显式 FH_SEAL 不被覆盖，迁移只执行一次（FH_SEAL_MIGRATED）。
- 命令：恢复 /FH_SEAL。
- 回归：test_paladin_light_seal_mode.py 的 F 段改为验证下拉存在与 /FH_SEAL 命令。

【防骑】2026-11-11（光明圣印 buff 常驻开关：兼容「光明审判」debuff）
- 用户口径原话：「还需要增加一个光明圣印buff常驻开关，勾选优先维持光明圣印，目标有光明审判debuff时自动切回圣印选择里的圣印」。
- 面板：防护「自动」分组的「光明圣印」常驻开关（saveVariable=FH_CRGMSY）即本功能；
  勾选后优先维持自身光明圣印，目标有审判 debuff 时自动切回当前常驻圣印（默认愤怒圣印 11）。
- 循环：WR_PaladinForever_LightSealDebuffRemain() 的 debuff 名称匹配新增「光明审判」，
  同时兼容「圣光审判」「光明圣印」旧名；此前只认「圣光审判」，若客户端实际叫「光明审判」，
  会被误判为没有 debuff，表现为一直维持光明圣印不切回。
- 回归：test_paladin_light_seal_toggle.py 新增 F4「目标已有光明审判 → 直接切回常驻圣印」。

【防骑】2026-11-11（奉献新增蓝量下限 30%）
- 用户口径原话：「需要新增奉献蓝量下限：蓝量百分比低于百分之30设定值时不施放奉献」。
- 改动：Paladin/Paladin_Forever_Prot.lua 的奉献蓝量门由 `PlayerMP > 0.55` 改为
  `PlayerMP >= WR_PaladinForever_PROT_CONSECRATION_MANA_MIN`（= 0.30）。
  即蓝量百分比 <30% 时不提示/不施放奉献，≥30% 才进入奉献判断；其余门槛
  （FH_FX 开关、8 码内目标 ≥3、近战 5 码、本地 8 秒 CD）不变。
- 面板：防护「自动 奉献」tooltip 同步改为「蓝量 ≥30%（低于 30% 不施放）」。
- 说明：战斗中 UnitPower 可能是 secret，安全层降级为 1（满蓝）时该门恒通过，
  属客户端硬限制；脱战/可读时按 30% 生效。
- 回归：test_paladin_prot_aoe.py G 场景改为「29% → 跳过奉献」，新增 G2「30%/35% → 奉献」。

【防骑】2026-11-11（修复：神圣打击本地冷却误写 10 秒 → 实际 6 秒）
- 用户反馈原话：「神圣打击的cd是6秒钟，你是不是不知道它的cd，才导致它没有第一时间打出」。
- 根因：Paladin/Paladin_Forever.lua 的 WR_PaladinForever_SkillCD["神圣打击"] 误写为 10 秒
  （等级5 / SpellID 2495 的客户端截图显示「6秒冷却时间」）。每次成功施放后本地多锁 4 秒，
  6~10 秒这段实际已经转好却不亮色块，表现就是「CD 好了没有第一时间打出」。
- 修复：本地冷却改为 6 秒；防护与惩戒共用同一张 SkillCD 表，ShowSkillCD / Ready / FreeAt 同步生效。
- 回归：test_paladin_prot_aoe.py 新增 C3（6.05 秒前刚打 → 已就绪，必须优先点亮神圣打击）。

【防骑】2026-11-11（删除「圣印」选择下拉框）
- 用户口径原话：「不想要前面新增的圣印下拉框了，帮我删除」。
- 面板：移除防护专精下拉区的「圣印」下拉框（原 saveVariable=FH_SEAL 六项），不恢复旧的圣印复选框。
- 循环：WR_PaladinForever_MainSeal() 默认返回愤怒圣印（槽 11）；补印、进战补印、单体起手收尾、
  光明圣印开关的切回全部使用愤怒圣印。
- 兼容：旧存档 FH_SEAL / FH_SEAL_MIGRATED / FH_GMSY / FH_ZYSY 统一清理，避免残留配置影响。

【防骑】2026-11-11（「插入光明圣印」改为「光明圣印」常驻开关）
- 用户口径原话：「插入光明圣印修改为光明圣印开关，当勾选优先维持光明圣印，目标有光明圣印debuff时自动切回圣印选择里的圣印」。
- 面板：原「插入」分组的「插入 光明圣印」复选框（saveVariable=FH_CRGMSY）改为
  「自动」分组的「光明圣印」常驻开关；勾选后一直生效，不再自动取消勾选。
- 循环（Paladin_Forever_Prot.lua）：
  · 状态机 0=需要光明圣印（缺印自动补）/ 1=已提示切光明、等 1 秒 / 2=已提示审判 /
    3=已提示切回常驻圣印 / 4=目标已有光明审判、保持常驻圣印；
  · 勾选后优先维持光明圣印；目标没有「光明审判」debuff 时用光明圣印打审判；
  · 目标有「光明审判」debuff 时自动切回常驻圣印（愤怒圣印）；
  · 本服「光明审判」持续 40 秒（ForeverDB build 1.60.1.70862，Classic 为 10 秒），
    debuff 到期后自动重新切光明圣印并补审判，形成常驻循环。
- 细节：新增 WR_PaladinForever_LastSealAppliedName 记账，光环不可读时也能判断
  当前是否在光明圣印上；切换目标（GUID/名字可读时）会重新给新目标挂光明审判。
- 防呆：未学会光明圣印或审判时自动取消，不影响循环。
- 回归：新增 test_paladin_light_seal_toggle.py 覆盖常驻循环；其余圣印/防护夹具保持通过。

【防骑】2026-11-10（奉献改为 3 目标使用）
- 用户口径原话：「防骑奉献改为3目标使用」。
- 改动：Paladin_Forever_Prot.lua 多目标固定链的奉献门由 tryConsecrate(2) 改为 tryConsecrate(3)。
  · 8 码内目标 ≥3 个：仍按 奉献 → 审判 → 神圣打击 → 驱邪术 → 神圣之盾；
  · 8 码内目标 = 2 个：不再铺奉献，链从 审判 开始（审判 → 神圣打击 → 驱邪术 → 神圣之盾）；
  · 其余门槛不变（FH_FX 开关、蓝量 >55%、目标可攻击、近战 5 码、奉献本地 8 秒 CD）。
- 说明：多目标模式本身的触发阈值仍是 ≥2 个目标（用户 2026-11-10 原口径未改），
  本次只调整「奉献」这一个技能的目标数量门。
- 回归：test_paladin_prot_aoe.py B 场景改为「2 目标 → 审判（不铺奉献）」；A 场景 3 目标仍奉献。

【防骑】2026-11-10（修复：神圣打击「CD 好了也不打」——等级换 rank 后写死 Rank3 ID 失效）
- 用户反馈原话：「神圣打击还是老问题，审判cd4秒的时候，它cd好了也不打」。
- 根因（角色 42 级实机配置）：
  · Core/Forever_Compat.lua 的 F.SPELL_ID_FORCE 把「神圣打击」强制写死为 Rank3 的 1866；
  · Paladin_Forever.lua 的 SpellRankIDs 只登记 678/679/1866/10332/10333，
    缺 Rank4=680、Rank5=2495、Rank6=5569（ForeverDB build 1.60.1.70862）；
  · 42 级当前是 Rank5（2495）→ IsUsableSpell(1866) 返回 false →
    WR_SpellUsable("神圣打击") 恒 false → 防护循环 hsEligible 恒 false →
    神圣打击色块永远不亮，表现就是「CD 好了也不打」。
- 修复：
  · WR_BuildSpellBookIndex 新增「去掉（等级 N）后缀的基础名 → 最高 rank」索引；
  · WR_ResolveSpellID 对 SPELL_ID_FORCE 改为优先用法术书里的当前 rank，强制 ID 仅兜底；
  · SpellRankIDs 补全神圣打击 8 个 rank：678/679/1866/680/2495/5569/10332/10333；
  · Prot/Ret 的 hsEligible 改用 SpellKnown（内部遍历全部 rank），冷却仍由本地 Ready 记账；
  · 修正所有「（等级 N）」后缀剥离：Lua 5.1 字符类按字节匹配，[（(] 对多字节全角括号
    实际不生效，改为「全角（等级 N）」→「半角(等级 N)」两步字面量匹配；
  · /mkpal 增加「解析ID / 已学会」输出，便于实机核对当前 rank 解析是否正确。
- 回归：新增 test_paladin_spell_rank.py（法术书带等级后缀 → 解析 2495 而非 1866）；
  test_paladin_prot_aoe.py 新增 N 场景（42级 Rank5 → 神圣打击正常点亮）；
  全量 9 套夹具全绿、justice_seal_loop 62 项 0 失败；语法 194 项 193 过
  （Core/UI_Config.lua 历史遗留非法转义与本次无关）。

【防骑】2026-11-10（单体循环：神圣打击 CD 好了永远优先审判 —— 用户方案 2）
- 用户口径：确认选择方案 2「让神圣打击永远优先审判」（接受审判的仇恨/嘲讽顺序后移）。
- 问题：审判点「强化审判」后 8 秒 CD、神圣打击 10 秒，两者周期不同步；旧
  Ready-first 按 FreeAt 排序，审判更频繁就绪 → 神圣打击刚转好时经常排在审判
  后面，被顺延 1.1~1.2 秒，叠加补圣印/其它 GCD 可到 2~3 秒（离线模拟：AHK 每
  60ms 连按、GCD 1.5 秒，不是游戏实测）。
- 改动：Paladin_Forever_Prot.lua 的单体链（非多目标固定链）在 Ready-first 调度前
  先尝试 tryHolyStrike()：只要神圣打击「面板开关 / 8 码射程 / 目标可攻击 / 本地
  冷却」都过，就立即亮神圣打击；只有它不可用时才轮到审判。神圣打击刚亮过、还在
  0.45 秒防抖或 GCD 重试窗口时，本 tick 不再把色块让给审判（最多等提示保持
  PROMPT_HOLD=1.5 秒），避免 AHK 把刚亮的「神圣打击」色块顶掉；1.5 秒后仍无法
  点亮则正常放行，不会永久卡死。
- 不变：多目标固定顺序仍为 奉献 → 审判 → 神圣打击 → 驱邪术 → 神圣之盾（用户
  2026-11-10 原口径，本次未改）；神圣打击在 CD 时审判照常轮转，不会把审判饿死。
- 回归：test_paladin_prot_aoe.py 新增 C/C2（神圣打击优先于 FreeAt 更早的审判；
  神圣打击 CD 中由审判顶上），test_paladin_prot_opening.py 的 A/B/E 期望同步改为
  神圣打击；全量语法 194 项 193 过（Core/UI_Config.lua 历史遗留非法转义与本次无关），
  九套夹具全绿、justice_seal_loop 62 项 0 失败。

【防骑/惩戒】2026-11-10（删除三条屏幕中央文字提醒）
- 用户口径原话：「可施放 迅捷审判 开启防御光环 开启输出光环 这几个删除」。
- 删除的提示（PigAlert，屏幕中央大字）：
  · Paladin_Forever_Prot.lua：删除「可施放 迅捷审判」分支；
  · Paladin_Forever_Ret.lua：删除「可施放 迅捷审判」与「开启输出光环」两处
    （输出光环检查整段移除）；
  · Paladin_Protection.lua：删除「开启防御光环」提示及其专属函数
    WR_PaladinProtection_SYTX 与调用。
- 仅删除文字提醒，不改循环优先级、伤害/治疗判定与色块逻辑。

【防骑】2026-11-10（功能区新增「光明圣印」模式，替换愤怒圣印）
- 用户口径原话：「功能区加入光明圣印模式，替换愤怒圣印」。
- 面板：防护「自动」功能区第 7 行第 3 格新增「光明圣印」开关（saveVariable=FH_GMSY，
  槽位 54 / 宏 CTRL-F11）。勾选后，防护循环的常驻圣印由愤怒圣印改为光明圣印；
  不勾选时仍保持原来的愤怒圣印，不影响老配置。
- 循环：WR_PaladinForever_MainSeal() 的选择顺序改为
  FH_GMSY → 光明圣印(54)；否则 FH_ZYSY → 正义圣印(47)；否则 愤怒圣印(11)。
  补印、进战强制补印、单体起手收尾、插入智慧圣印后的切回，全部自动跟随 MainSeal。
- 互斥：与「正义圣印」「单体循环」同属 PAL_PROT_SEAL_MODE 组（三选一）。
  开一个会自动关闭另外两个；历史存档里的多开由面板创建时按「后声明者优先」收敛。
- 细节：Paladin_Forever.lua 新增 LightSealCastAt 施放计时字段（/mkseal 可看），
  施放成功事件按名记账；死亡/提前掉印清理时一并作废。
- 防呆：「插入光明圣印」（FH_CRGMSY）是「切光明→审判→切回」的一次性流程，
  在常驻已是光明圣印时没有意义；本模式下自动取消该勾选，避免白占 GCD / 抢色块。
- 回归：新增 test_paladin_light_seal_mode.py 覆盖 MainSeal 选择、面板互斥、
  缺印补印、插入自动取消；既有八套夹具与语法检查无回归。

【防骑】2026-11-10（战斗中加入自动平砍 + 圣印被提前驱散不再等满硬锁）
- 用户口径原话两条：
  ① 「战斗中加入自动平砍」；
  ② 「圣印被提前驱散或顶掉时，仍要等满硬锁……如果正义圣印在第 10 秒被驱散，
     要等到第 31 秒才会补，也就是 21 秒空窗。这个问题的触发概率比正常到期低，
     但一旦发生，空窗会很长。这个问题要修复」。

- 一、战斗中加入自动平砍
  · 旧 bug：WR_PaladinForever_AutoAttackActive() 在战斗中恒返回 true —— 无限
    1.60.x 读不到真实的「自动攻击进行中」状态，兼容层只能按 UnitAffectingCombat
    兜底。于是循环里唯一的「攻击」提示只在脱战出现；平砍一旦在战斗中停下
    （切目标 / 目标死亡换目标 / 被控制后恢复 / 手动停），插件再也不提示，
    玩家白丢整场平砍输出。
  · 现在：
    - Paladin_Forever.lua 新增 WR_PaladinForever_AutoAttackNeedsRestart()：
      事件优先（PLAYER_ENTER_COMBAT → 认为平砍在跑，立刻停止提示；
      PLAYER_LEAVE_COMBAT → 清标记 + 清提示防抖，下一 tick 立刻重开），
      事件不可用时退化为「每 2 秒最多提示一次」的限频盲试
      （WR_PaladinForever_AUTOATTACK_RETRY = 2.0）。
    - Paladin_Forever_Prot.lua 第 4 段：脱战仍照旧优先提示「攻击」（开怪）；
      战斗中不再在这里 return，改到函数末尾新增的第 15 段兜底。
    - 第 15 段放在【所有技能环节之后】：只要有任一技能该打就先打技能，
      整轮都没技能可打（全 CD / 条件不满足）时才用「攻击」色块把平砍接上。
      即使状态判错也绝不抢占技能优先级、不会饿死主调度。
  · 为什么不会变成「色块常亮被 AHK 连按」：2 秒限频 + 1.5 秒保持
    → 亮 1.5 秒 / 暗 0.5 秒，永不常亮；一次 /startattack 就足以接上平砍。
    事件可用时收到 ENTER 会立刻停，比限频更快。

- 二、圣印被提前驱散/顶掉不再等满硬锁
  · 旧问题：SealNeedsRefresh 只认 SealBuffKnownUntil / 30.2 秒硬锁。第 10 秒
    被驱散也要等到第 31 秒才补 → 最长 21 秒空窗。
  · 现在新增 WR_PaladinForever_SealLostEarly()，三条同时成立才提前放行：
    ① 光环扫描是【权威 missing】（不是 unknown / 缓存不可信）；
    ② 本次上印之后确实【可读地读到过】圣印光环（Paladin_Forever.lua 新增
       WR_PaladinForever_SealAuraLastUpAt，由 SealBuffState 在读到 up 时记录）
       —— 天然读不到光环的愤怒圣印永远不满足这条，所以不会回到
       「每 2~3 秒反复上印」的老 bug；
    ③ 已过 1 秒缓冲（SEAL_EARLY_LOST_GRACE），吸收施放事件与光环缓存刷新延迟。
  · 命中后调用 ClearSealLockOnEarlyLoss() 作废本地 30 秒记账（否则
    SealBuffKnownUntil 会拦住下一次判定），再由 Prot 第 3 段的 0.1 秒缺印确认
    点亮色块 → 实测被驱散后约 0.4 秒重新亮。
  · 防连按：额外加 10 秒闩锁（SEAL_EARLY_LOST_COOLDOWN）。万一光环出现
    「读到 up → 下一帧 missing」的瞬时误读，没有闩锁会每 ~1 秒补一次；
    真实被驱散不可能 10 秒内连续发生多次，所以不影响正常响应速度。
    真正的防洪闸仍是 CanPrompt(mainSeal, 3)，本轮未动。
  · 正常到期路径完全不变（实测仍是 t=30.2 秒补印）。

- 新增夹具：
  · .workbuddy/test_paladin_seal_early_loss.py（7 项）：第 10 秒被驱散 →
    0.4 秒内点亮；天然读不到光环的圣印绝不提前补；战斗 secret（unknown）
    仍等硬锁；瞬时 up/missing 抖动 20 秒只亮 ≤3 次窗口；记账被正确作废；
    正常到期仍 30.2 秒（回归保护）。
  · .workbuddy/test_paladin_autoattack_combat.py（8 项）：有技能时平砍不抢
    优先级；全 CD 时点亮「攻击」；ENTER 停止提示；LEAVE 立刻恢复；
    4 秒内只亮 2 tick（不常亮）；20 码不提示；脱战开怪仍提示；
    补印保持窗口内不提示攻击（不顶掉圣印色块）。
- 回归：语法 194 项 193 过（Core/UI_Config.lua 历史遗留非法转义，与本次无关），
  八套夹具全绿、justice_seal_loop 62 项 0 失败。

【防骑】2026-11-10（圣印空档期再收紧：掉印 → 重新亮色块 2 秒改 0.3 秒）
- 用户口径原话：「圣印空档期太久，我想更快点补圣印」。
- 时序（掉印到重新亮色块）三次演变：
  · 最初：硬锁缓冲 3 秒 + 缺印确认 1 秒 → 掉印后约 4~5 秒才补；
  · 上一版：缓冲 3 → 1 秒 → 掉印后 2 秒补；
  · 现在：缓冲 1 → 0.2 秒 + 缺印确认 1 → 0.1 秒 → 掉印后 0.3 秒补。
- 改动只有三处数值，循环优先级/审判门控/圣印补印入口全部未动：
  · Paladin_Forever.lua WR_PaladinForever_SEAL_LOCK_GRACE：1 → 0.2
    （硬锁 = Buff 30 + 0.2 = 30.2 秒）；
  · Paladin_Forever_Prot.lua 第 3 段缺印确认：>= 1 → >= 0.1；
  · Paladin_Forever.lua WR_PaladinForever_NoteSealBuffRemain 的 cap：
    Buff + 2 秒 → Buff + 硬锁缓冲（否则「可读光环读到 30~32 秒剩余」时
    SealBuffKnownUntil 会盖过新硬锁，勾选正义圣印时 0.2 秒缓冲不生效）。
- 为什么不会回到「反复上印」：
  · 硬锁 30.2 秒仍严格大于真实 Buff 30 秒，一个 Buff 周期最多点亮一次色块，
    理论补印频率完全不变（每 ~30.2 秒一次）；
  · 0.2 秒余量只吸收「客户端 Buff 到期时刻 vs 本地记账时刻」的偏差
    （施放成功事件延迟 + 主循环 0.1 秒 tick 量化）；
  · 真正的防洪闸没动：① 光环可读时以客户端为准（state=up 一律不补）；
    ② CanPrompt(mainSeal, 3) —— 色块亮过后 3 秒内不重亮，专治
    「施放成功事件丢失导致记账不推进」的连按洪水。这一条刻意**没有**跟着
    收紧到 0.3 秒，否则会立刻复现旧版「每 2~3 秒反复上印」。
- 实测（模拟 AHK 成功按键）：愤怒圣印补印时刻 = [30.4]，即 t=0 上印、
  t=30.4 重新亮色块，掉印后 0.3 秒内补上；审判在 t=30.5 恢复点亮。
- 回归：test_paladin_prot_aoe.py 的 M1~M3 改为 30.2 秒硬锁 + 新增
  「补印时刻必须 ≤30.7 秒（掉印后 0.3 秒内）」；test_justice_seal_loop.py 的
  S40/S42/S44/S45/S53 里写死的 31 秒口径同步改 30.2 秒。
  全量语法 194 项 193 过（Core/UI_Config.lua 历史遗留非法转义，与本次无关），
  六套夹具全绿、justice_seal_loop 62 项 0 失败。

【防骑】2026-11-10（圣印掉落 → 重新亮色块：约 5 秒改 2 秒）
- 用户口径原话：「五秒太久了改2秒」。
- 旧时序（掉印到重新亮色块）：
  · 圣印 Buff 到期 30 秒；
  · 硬锁缓冲 SEAL_LOCK_GRACE = 3 秒 → 硬锁 33 秒；
  · 再等 1 秒「缺印确认」（SealMissingSince）才点亮色块；
  · 合计 30 + 3 + 1 = 34 秒，玩家感知「掉了以后要等 4~5 秒才补」。
- 现在：SEAL_LOCK_GRACE 由 3 秒收到 1 秒 → 硬锁 31 秒，加 1 秒缺印确认，
  掉印后 2 秒内就重新亮色块。实测补印时刻 = [32.0]（t=0 上印，t=32 补）。
- 为什么不会回到「反复上印」：硬锁下限仍是完整 Buff 周期（31 > 30 秒），
  一个 Buff 周期最多点亮一次色块，1 秒缓冲只覆盖读屏/按键/GCD 抖动。
- 回归：test_paladin_prot_aoe.py 的 M1~M3 断言同步改为 31 秒硬锁 + 新增
  「补印时刻必须 ≤33 秒（掉印后 2 秒内）」；test_justice_seal_loop.py 的
  S40/S42/S44/S45 口径同步更新（S40 改为锁定「审判后 1 秒内绝不许亮 +
  硬锁内不许亮」，比原来「整段 30 秒零点亮」更精确地锁住「审判不消耗圣印」）。
  六套夹具全绿（62 项 0 失败）。

【防骑】2026-11-10（修复：默认愤怒圣印 300 秒不补印 → 审判连带饿死 5 分钟）
- 用户提问：「循环里没有挂圣印吗」——核查后确认挂印入口共 3 处（第 3 段常驻圣印补印、
  进战强制补印、单体起手十字军→常驻），但默认的「愤怒圣印」存在一个 300 秒空窗。
- 现象（模拟 AHK 成功按键实测）：默认愤怒圣印只在 t=1s 点亮一次，之后 300 秒不再补；
  审判在 t=1.5 / 11.5 / 21.5 亮过 3 次后彻底断掉，180 秒内一次都没有。
  对照组常驻正义圣印每 10 秒一发审判，完全正常。
- 根因是「两个时间窗不一致」，不是漏写挂印：
  · Paladin_Forever.lua 的 SealNeedsRefresh 把「愤怒圣印」列进 SEAL_NO_AURA 名单，
    单独走极宽兜底 SEAL_MISSING_FALLBACK = 300 秒（理由：本服读不到它的光环，
    「读不到」≠「没了」）；
  · 但 ProtSealState / AnySealUp 按真实 30 秒 Buff 时效判，31 秒就判 missing；
  · 审判门控是 (sealState ~= "missing" or SealActive())，两条同时不成立
    → 31~300 秒之间审判永远不亮，主循环只剩神圣打击 / 神圣之盾。
  这段逻辑在 HEAD 里就存在，是长期潜伏的老问题，不是本轮改动引入的。
- 修复：两种圣印统一走「Buff 时长 + 缓冲」硬锁（30 + 缓冲；缓冲原定 3 秒，
  先后按用户「五秒太久了改2秒」收到 1 秒、「更快点补圣印」收到 0.2 秒，见上两条）。
  · 一个 Buff 周期最多点亮一次色块 —— 这是理论最小补印频率，
    不会回到用户此前反复反馈的「每 2~3 秒反复上印」（那是旧版 2 秒提前补的锅）；
  · 硬锁走完仍读不到光环 → 视为真的掉了，补一次并重新开始硬锁；
  · 光环可读且确有圣印（玩家手动续的印）→ 第 ① 步已 return false，不补。
  SEAL_NO_AURA 名单保留但只用于诊断，不再改变补印节奏。
- 实测修复后：愤怒圣印补印时刻 = [32.0, 64.0, 96.0]（每 31 秒一次，120 秒 3 个窗口）；
  审判恢复为每 10 秒一发。
- 夹具：test_justice_seal_loop.py 的 S42 / S44 原断言是「120 秒零重补」，
  固化的正是这个错误口径，已按新语义改写为「120 秒补印窗口 3~5 且间隔 ≥30 秒」
  （旧 bug 约 48 次，仍会被拦住）。test_paladin_prot_aoe.py 新增 M1~M3：
  31 秒硬锁内不补、硬锁后 2 秒内补、审判恢复点亮、31 秒后不再出现
  「不许补印 + 认为没圣印」的矛盾状态。
- 回归：语法 194 项 193 通过（Core/UI_Config.lua 的历史遗留非法转义与本次无关）；
  六套夹具全绿（config_exclusive / prot_gate / prot_aoe / prot_opening /
  focus_gate / justice_seal_loop 62 项 0 失败）。

【防骑】2026-11-10（面板互斥：「正义圣印」与「单体循环」只能勾一个）
- 用户口径原话：「正义圣印按钮和单体循环模式按钮只能勾选一个，修改为开启一个后另一个自动关闭」。
- 为什么以前能双开、双开有什么问题：
  · 这两个开关分别存在 PigSet.FH_ZYSY（常驻圣印改用正义圣印）与 PigSet.FH_DT
    （单体起手：十字军圣印 → 审判 → 切回常驻圣印），面板上各自独立、互不感知；
  · 双开时循环里 FH_DT 的起手状态机与 FH_ZYSY 的常驻圣印同时生效，
    表现为「先切十字军、打完审判再切回正义圣印」，与玩家在面板上看到的状态不符，
    排查时很难判断到底是哪个开关在起作用。
- 实现（Core/UI_Config.lua 新增通用「开关互斥组」机制，不是给防骑写的特例）：
  · 菜单配置里给开关加 exclusiveGroup = "<组名>"，同组开关自动变成单选；
  · 面板点击：打开 A → 同组其它开关立刻自动关闭，PigSet 与界面勾选同时刷新；
  · 斜杠命令 /A on、/A（toggle）、以及从图标拖到动作条的切换宏，走同一条互斥逻辑
    （避免「点面板互斥、用宏却能双开」的不一致）；
  · 关闭开关不触发互斥（关 A 不会把 B 顶开），反复开关同一开关也不会互相顶；
  · 历史存档/重置后若出现同组双开，在面板创建末尾与重置按钮后各收敛一次，
    按「后声明者优先」保留一个，并在聊天框明确写出关掉了哪个（不静默改玩家状态）；
  · 互斥开关的 tooltip 追加红字「【互斥】与 [...] 只能同时开启一个」；
  · 只改面板开关状态，不介入循环逻辑（循环仍按 PigSet 现值判断），
    因此不会改变任何已验收的循环行为。
- 接线：Paladin_Menu.lua 的「单体」(FH_DT) 与「正义圣印」(FH_ZYSY) 同属
  exclusiveGroup = "PAL_PROT_SEAL_MODE"；两者 tooltip 措辞同步改写
  （原文写「与单体开关可同时使用」，与本次口径冲突，已改为互斥说明）。
- Core/UI_CommandList.lua 补上 /FH_DT 条目（原先命令清单里没有「单体」），
  并给两条命令标注「★互斥」。
- 新增离线夹具 .workbuddy/test_config_exclusive.py（17 条）：存档双开收敛、
  点开单体→正义圣印自动关、点开正义圣印→单体自动关、关闭不触发互斥、
  斜杠命令 on/toggle/off 三条路径、非互斥开关不受影响、互斥组登记幂等、
  tooltip 互斥文案。直接加载真实 Core/UI_Config.lua 建出真实复选框面板验证。
- 验证：全量语法 194 文件 OK=193 FAIL=1（唯一失败仍是 Core\UI_Config.lua 既有
  非法转义序列，与本次改动无关）；互斥 17/17、门禁 17/17、多目标 15/15、
  开怪 7/7、圣印回归 62/62、焦点门 A-G 全部通过。

【防骑】2026-11-10（循环硬规则：任一环节不满足条件就不亮色块，直接判断下一个环节）
- 用户口径原话：「循环中任意一个环节，不符合条件就不亮色块，进行下一个循环」。
- 为什么必须做：AHK 是「同色常亮就一直按」（约 60ms 一次）。某环节若在「这一发实际
  打不出去」（目标没了 / 不可攻击 / 超出射程）时仍点亮色块，客户端不会回施放成功事件 →
  本地 CD 记账不推进 → ShowSkillCD 保守兜底每 1.5 秒重亮 → 该环节持续抢帧空按，
  玩家看到的是「色块一直闪、技能不出」。
- Paladin_Forever.lua 新增统一门（供全循环复用）：
  · WR_PaladinForever_SPELL_RANGE —— 各技能有效射程表（攻击8/审判10/神圣打击8/
    制裁之锤10/愤怒之锤30/驱邪术30/奉献5），未登记 = 自身 Buff 类不判射程；
  · WR_PaladinForever_TargetCastable —— 目标存在 + 可攻击 + 活着；
  · WR_PaladinForever_InSpellRange —— 射程判定，距离读不到(999/nil)时放行
    （战斗中 GUID 可能是 secret，LibRangeCheck 偶尔算不出，据此拦截会永不出技能）；
  · WR_PaladinForever_CanHitTarget —— 上面两者合并的统一门。
- Paladin_Forever_Prot.lua 逐环节接入：
  · 主调度 审判 / 神圣打击 / 驱邪术 / 奉献 / 神圣之盾 的 eligible 与 tryXxx 闭包全部复核射程门；
  · 单目标 Ready-first 调度选出的技能、起手 3 秒优先审判，均改为走带门的闭包；
  · 补射程门：制裁之锤(10)、愤怒之锤(30)、攻击(8)（原来只有「目标在施法 / 血量 / 可攻击」）；
  · 单体起手 phase1 打审判、插入光明圣印 phase1 打审判、插入智慧圣印 phase1 打审判，
    三处都补 CanHitTarget（目标在 10 码外时不切印、不亮审判，避免白跑一遍切印流程）；
  · 一次性「插入」：只有真正需要敌方目标的（制裁之锤）才判门；圣疗术/圣盾术/神圣牺牲/
    自由之手/拯救之手/保护之手/牺牲之手/神圣愤怒属自身或队友技能，不判敌方目标
    （UnitCanAttack 对友方恒 false，统一判会把这整组功能拦死）；
    且条件不满足时「不点亮也不取消勾选」，等下个 tick 条件满足再打。
- ★ 补齐「其他切圣印入口」的同一道门（本轮审计发现 2 处漏接）：
  · 单体起手 phase0 切「十字军圣印」原先不判任何条件 → 目标打不到时白切一次印，
    把常驻圣印顶掉、白丢一个 GCD，且 phase 推进到 1 后审判一直打不到就永久卡住
    （常驻补印被「任意圣印在身一律不切」挡住，整场只剩神圣之盾）。
    现在：先过 CanHitTarget("审判") 才切印；打不到就不亮色块、phase 保持 0，
    目标回到 10 码内下一 tick 自然补上起手。
  · 单体起手 phase1 打审判：目标跑出射程后不再死等。新增 2 秒缓冲
    （走位/击退不误判），超过就直接跳过审判这一环节、推进到 phase2 切回常驻圣印，
    绝不让「审判打不到」把整个循环锁死。
  · 已核对无需改动：插入光明圣印 / 插入智慧圣印 phase0 切印已判 CanHitTarget("审判")；
    单体起手 phase2、光明插入 phase3 的「切回常驻圣印」是自身 Buff 收尾动作，
    本来就必须亮（否则玩家永远停在十字军/光明圣印上），刻意不判敌方目标门。
- 修复 P0：圣殿壁垒槽位 118 撞宏
  · Paladin_Macros.lua 原写 ["圣殿壁垒"]=118 且注释称「118 无冲突」，但同文件 :132
    已把 118 绑定 /target 凯雷塞斯王子（纳克萨玛斯 BOSS）；
  · 后果：① 圣殿壁垒永远打不出去；② 色块亮 1.5 秒 → AHK 连按 15~25 次强行切目标，
    战斗中会毁掉当前目标与整条循环；
  · 现在按 115/116/117 同一处理：槽位置 nil，循环里改为只弹文字提示（PigAlert）。
- 修复 CD 记账缺口：Paladin_Forever.lua 的 NameFromID 动态反查名单补上
  奉献/驱邪术/愤怒之锤/制裁之锤/圣疗术/圣佑术。原先静态 SpellRankIDs 只有 5 项，
  这些技能在战斗中 spellName 为 secret 时完全没有 ID 通道 → 施放成功后仍按 1.5 秒重亮
  （奉献 8 秒 CD / 驱邪术 15 秒 CD 会被过量施放）。
- 修复「长 CD 一次漏按锁死整个 CD」：ShowSkillCD 的保守兜底原为「长 CD 一律按完整 CD
  屏蔽」，而圣疗术传 1200 秒、圣佑术传 300 秒 —— 施放事件没记上账时，第一次点亮后
  20 分钟 / 5 分钟内不再提示（玩家完全没按也不亮）。现改为三段：
  ≤15 秒按提示保持窗口重试；≤300 秒最多每 20 秒重试一次；更长的才按完整 CD 防刷屏。
- 如实注释两处「形同虚设的门」（客户端 secret 硬限制，非漏写，避免后续反复当 bug 排查）：
  · 生存自保 PlayerHP < 0.20 / 0.35：战斗中 UnitHealth 是 secret → 安全层降级为 1
    → 恒不成立，圣疗术/圣佑术 自动提示在战斗中永不亮（可手动施放或走插入开关）；
  · 奉献蓝量门 PlayerMP > 0.55：战斗中 UnitPower 同为 secret → 降级为 1 → 恒通过。
- 新增离线夹具 .workbuddy/test_paladin_prot_gate.py（17 条）：40/25/12/7 码射程递补、
  无目标/目标已死/目标不可攻击、射程读不到放行、制裁之锤与愤怒之锤射程、
  攻击提示近战门、自身类插入不被敌方门拦死、圣殿壁垒不占色块。
- 验证：全量语法 194 文件 OK=193 FAIL=1（唯一失败仍是 Core\UI_Config.lua:3174 既有
  非法转义序列，与本次改动无关）；门禁 17/17、多目标 15/15、开怪 7/7、
  圣印回归 62/62、焦点门 A-G 全部通过。

【防骑】2026-11-10（新增多目标循环：8 码内目标 ≥2 个时改走固定优先级）
- 用户口径：目标 >2 个时，先奉献 → 挂所选常驻圣印打审判 → 神圣打击 → 驱邪术（可用就打）→ 神圣之盾。
- Paladin_Forever_Prot.lua 第 6 步主调度拆成两条链：
  · 多目标链（UnitCount8 >= 2）：严格按上述固定顺序逐个尝试，不做 Ready-first 重排；
    奉献门从「≥3 目标」放宽到「≥2 目标」，其余条件（FH_FX 开关、蓝量 >55%、近战 5 码）不变。
  · 单体链（目标 ≤1）：完整保留原「谁 CD 好了先打谁」的 Ready-first 调度与各技能原有门槛，
    行为与改动前逐条一致（含起手 3 秒优先审判、单体起手/插入圣印让出审判）。
- 常驻圣印逻辑不动：多目标仍按面板选择（默认愤怒圣印，勾 FH_ZYSY 则正义圣印）补/切，
  审判只在「身上有任意圣印」时进入候选。
- 两条链共用同一套 eligible 判定与 tryXxx 闭包，避免多目标/单体口径分裂。
- 新增离线夹具 .workbuddy/test_paladin_prot_aoe.py（12 条：3/2/1 目标顺序、逐个 CD 递补、
  亡灵驱邪术插入、开关/蓝量/距离门、单体起手与插入圣印让位、缺印优先补印）。
- 验证：全量语法 194 文件 OK=193 FAIL=1（唯一失败仍是 Core\UI_Config.lua:3174 既有非法转义序列，
  与本次改动无关）；圣印回归 62/62、开怪夹具 A-F、焦点门 A-G、插入开关检查全部通过。

【全职业】2026-9-1（移除「取消灌注/专注」冲分纯化功能，方案B彻底删除）
- 删除 Utils_DeathTime.lua 的 WR_ALL_QXGZ（通用取消能量灌注/专注魔法）与 WR_ALL_QXFS（法师取消能量灌注）两个函数；此前它们挂在 WCL 冲分模式，合并 WCL 后临时改为受 MONSTER_BLOCK_ENABLED 控制，但两者语义无关（怪物屏蔽≠取消自身增益），故按方案B直接下线。
- 同步移除 9 处职业旋转入口的早期 return 调用：Mage_Frost/Fire/Arcane、Druid_Feral、Warlock_Demonology/Destruction/Affliction、Priest_Shadow、Shaman_Enhancement。
- 不再有任何代码自动取消玩家身上的能量灌注/专注魔法；冲分玩家如需「无外部增益」打法改为手动管理。
- 验证：全目录 luaparse 147/147 语法 0 错误。

【防骑】2026-9-1（补齐「插入圣盾术 / 插入圣疗术」函数，修复勾选无反应）
- 复骑菜单本就有「插入圣盾术」(FH_CRSDS) 与「插入圣疗术」(FH_CRSLS) 复选框，但 Paladin_Protection.lua 一直缺少对应函数 WR_FQ_CRSDS / WR_FQ_CRSLS，导致勾选后毫无反应。
- 新增 WR_FQ_CRSDS() 与 WR_FQ_CRSLS()，写法对齐其它插入开关（可用则出图标、不可用则自动取消勾选 SlashCmdList[...]("off")）。
- 两函数均额外判断「自律」debuff（WR_GetUnitDebuffTime("player","自律")==0）：圣盾术/圣疗术共用自律，缺此判断会在自律期间卡帧且无法自动取消勾选（与先前自动圣疗术卡死同理）。
- 接线：插入段最前面（WR_FQ_CRSDS 排第一、WR_FQ_CRSLS 次之，先于制裁之锤等），即插入类最高优先级；自动圣盾术(FH_SDS)与自动圣疗术(FH_SL)仍处全循环最高优先级（治疗石之后）。
- 验证：Paladin 目录 luaparse 9/9 语法 0 错误。

【全职业】2026-9-1（清理：移除各文件散落的「修改记录」注释与乱码加载注释）
- 移除全插件各 .lua 文件头部散落的「-- 修改记录：」+ 日期变更注释块（共 49 个文件、263 行），变更记录统一收敛到本 GX 更新日志，杜绝代码文件头部冗余、避免每次改动都要在文件里写注释。
- 移除各职业文件首行因编码错误产生的乱码加载注释（即「★ 按职业延迟加载：非 X 职业跳过此文件」的乱码形式），共 101 个文件、101 行。
- 仅删除注释行，严格保留各文件内 `if WR_PlayerClass ~= "X" then return end` 实际加载守卫，无功能变化。
- 验证：全目录 luaparse 147/147 语法 0 错误。

【全职业】2026-8-31（图标拖出宏支持「实际施放 + 开关切换」组合宏）
- 扩展 Core/UI_Config.lua 的 WR_PickupToggleMacro：拖出开关图标生成宏时，若开关能推导出真实可施放技能/物品名（复用现有 showSpell / tooltip 推导，并经 GetSpellInfo/GetItemInfo 校验、排除纯数字 FileID），则在切换命令 /<saveVariable> 前追加一行 /cast <技能名>，生成一个动作条按键「既施放技能又切开关」的组合宏。
- 无对应技能的开关（AOE 总开关、自动跟随等回退到图标 FileID 的）仍只生成纯切换宏，行为不变；已拖出的旧纯切换宏再次拖出时自动升级为组合宏（EditMacro 复用）。

【全职业】2026-8-30（全职业通用宏 Global_Macros + 焦点跟随/上马体系 + 200+ 颜色段扩展）
- 新增 Core/Global_Macros.lua（TOC 第 23 行，早于各职业宏加载）承载全职业通用宏：201 目标跟随(CTRL-SHIFT-X→/follow target)、202 焦点上马(CTRL-SHIFT-M→/run C_MountJournal.SummonByID(0)，含 nil 守卫)、203 设置焦点(CTRL-SHIFT-F→/focus)、204 焦点跟随(CTRL-SHIFT-G→/follow focus)；205-210 预留空位；211-215 为 /focus party1-5，216-240 为 /focus raid1-25。
- 颜色段 ColorTable 由 201 扩展至 240（UI_ColorFrame.lua）：201-210 通用宏色块，211-240 为 party/raid 专属焦点色块，全段零冲突。
- 焦点上马判定：Core_Functions.lua 新增 WR_IsUnitMounted（用 GetUnitSpeed>8.5 近似上马），MainLoop.lua 的 WR_AutoFollow 焦点模式改为提示焦点上马（颜色 202），由 AHK 按 CTRL-SHIFT-M 上马。
- 防骑指向三手（FH_ZZBH/ZZXS/ZZJZ）统一改为施放成功后自动取消勾选（与奶骑 SS_ZZ* 一致）。
- 跟随自动提示 115/116/117 迁移至 201/203/204；跟随下拉选择队员后通过新增 WR_FollowFocusShow（party1-5→211-215、raid1-25→216-240）显示专属焦点色块，AHK 按对应 /focus 宏键设焦，已为焦点则转 204 跟随提示。
- AHK 启动器 启动器8.30.ahk2 同步 201-240 段（含 205-210 空位空颜色/空键，保留原 115/116/117 等不删）；新增 gen_ahk_colormap.py 从插件 Lua 自动反推启动器 ColorMap，改插件后重跑即自动同步，启动器无需手改。
- 自动跟随：注册 /mkaf 斜杠命令替代 /run WR_SetAutoFollow(true/false)/WR_ToggleAutoFollow()，避免触发暴雪「自定义脚本」确认弹窗；跟随复选框/下拉框 Tooltip 同步更新为 /mkaf 命令提示。
- 修复 /run 绑键宏的「自定义脚本」确认弹窗（上马 / 萨满 NUMPAD9 / 德鲁伊 CTRL-F5）：
  · 核心：Core/UI_ColorFrame.lua 的 WR_CreateMacro 现自动识别「纯 /run 或 /script」宏，改用普通按钮 OnClick 直接执行 Lua（不走宏文本，故不触发确认框，战斗中也能由 addon 按键回调执行）；其余宏仍走安全动作按钮 + 宏文本（/cast /use /target /focus /click /console 等）。
  · 上马宏（202 / CTRL-SHIFT-M）= /run if C_MountJournal and C_MountJournal.SummonByID then C_MountJournal.SummonByID(0) end（带 C_MountJournal nil 守卫，无 API 时静默）。
  · 萨满 NUMPAD9 = /run DestroyTotem(1)。
  · 德鲁伊 CTRL-F5 = /console autoUnshift 0 + /cast !猎豹形态 + /console autoUnshift 1（以 /console 改 CVar 替代 /run SetCVar，!/cast 强制变形不受 autoUnshift 影响），不再含 /run。
  · 已删除原错误的 /mkmount /mktotem 插件斜杠命令（从安全按钮宏文本调用 addon 斜杠命令在战斗中会被拦截、且 38002 客户端可能无该 API，属无效方案）。
- 验证：全目录 luaparse 147 文件语法 0 错误。

【全职业】2026-8-26（插入开关图标可拖动作条生成切换宏 + 全职业插入冷却自动识别）
- 新增「图标拖出宏」：面板任意插入类开关（_CR / CR<技能> / section=插入）图标可「按住左键拖到动作条空位」生成一条切换宏（/<saveVariable>），图标正确、带技能冷却读秒。
- 战斗中（InCombatLockdown）拖拽红字拦截，不生成宏；拖拽成功本次点击不误切开关状态。
- 宏名与 #showtooltip 真实技能/物品名自动从 tooltipText 推导（着色段优先），手套(工程手套)、饰品(槽13/14)、速度/狂野魔法/不灭药水、种族等特例经 NormalizeTipName 处理；全部失败回退 IconID。
- 复用同名宏（FindMacroByCommand）不占新宏位；重名自动加数字且超 16 字截断。
- 验证：全目录 luaparse 146/146 语法通过。

【全职业】2026-8-21（UI 全面重做：技能提示图标 / 面板去框体 / 标题规范）
- 新增「技能提示图标」框体：独立可拖动，显示当前提示技能图标 + 文字，与左上角色块分离；「全局」区新增开关控制显隐，关闭时完全隐藏无底色。
- 主配置面板去掉外框体边框线条（UIPanelDialogTemplate → 仅深色底）；分类标题条灰线保留。
- 功能设置界面（ZZ 面板）同步去外框体，标题改为左上角 18 号字放大显示，右上角自建关闭按钮。
- 面板初始高度收敛（左区兜底 800→740），减少底部空白。
- 所有复选框文字字号 +2；缩放回车即时生效；右侧弹窗滚动条底色统一黑色。
- 验证：全目录 luaparse 145/145 语法通过。

【全职业】2026-8-20（全面 Bug 排查修复：邪DK 僵尸调用 / 菜单位置冲突 / 调试输出清理）
- P1-② 邪DK 打断僵尸调用：删除 3 处未定义函数调用 WR_DK_XDK_DD（打断功能由 WR_DK_Unholy_DD_Target/Focus 无条件承担，不受影响）。
- P1-③ 邪DK 常规邪：删除 WR_XDK_ZDQS_TG_SCX 僵尸调用（自动天鬼功能已由 WR_DK_XDK_ZHSXG_ZD_SCX 完整覆盖）。
- P2 菜单位置冲突 3 处（同专精内图标重叠）：DK 冰霜「能量」row3col1→col2、「不灭」col2→col3；法师奥术「自己」row4col5→row5col5；牧师暗影「优先」row8col3→row9col3。
- P2 残留：删除 UI_Config.lua 主窗口高度 DEBUG print，/reload 不再刷屏。
- 全目录 luaparse 144/144 语法通过；菜单位置冲突复扫归零。

【全职业】2026-8-19（ZZ 移植第二三四批：治疗/野德/暗牧/冰DK 8 项功能）

-- === 第二批：治疗 4 项 ===
- 奶德 HF_JJS：新增荆棘术自动——战斗中自动给 TankUnit 列表第一个满足距离条件的坦克补荆棘术。
- 奶德 HF_YH_TANK + HF_YH_HP：愈合坦克 HP% 阈值模式（ZZ 口径，HP%≤阈值补愈合，阈值0=只看优先级debuff），与原有失血量判定互补。
- 奶骑 QS_SS_ZDJR / 神牧 MS_SS_ZDJR：MKH 已有等价实现（WR_PaladinHoly_JS / WR_PriestHoly_FHS 自动救人），无需改动。

-- === 第三批：猎人/野德 5 项 ===
- 猎人三系宝宝攻击：MKH 已实现三态（跟随/不跟随/不控制），无需改动。
- 野德 YD_ST：MKH 已实现（WR_DruidFeral_ST），无需改动。
- 野德 YD_CAT_CAT_AUTO / YD_CAT_CAT_CR：补齐——自动版开关检查 + 插入版（一次性用完自关）+ 火焰之花 3s 防连跳状态位。

-- === 第四批：暗牧/增强/防骑/冰DK 7 项 ===
- 暗牧 MS_AY_JSBCTIME：精神鞭笞打断阈值挂接 8 档（原 WR_MS_AY_BIANCHI_MB 硬编码 <=0.1 不生效，现改调 WR_MS_AY_BIANCHI_TJ）。
- 暗牧 MS_AY_AYSY_BOSS：渊 BOSS 限定开关化（原 UnitIsBoss 写死，现可切换全目标/BOSS）。
- 增强萨 SM_ZQ_CRSP/CRST/CRZZ/CRKYMF：MKH 已实现，无需改动。
- 防骑 FH_SSZD：MKH 已实现，无需改动。
- 冰DK DK_BDK_WZFS_ZD：亡者复生条件补齐（双病>7.5s+maxTime 且双死亡符文 HZFW==2，原 >2 会提前拉宠物卡符文）。
- 冰DK DK_BDK_CRSCTJ：新增一次性插入死从天降（可用即放，CD>2s 自动关）。
- 冰DK DK_BDK_CRTQTB：新增一次性插入铜墙铁壁（CD 剩余≤15s 提前插，施放成功事件自动关开关）。

效果：奶德荆棘术/愈合坦克阈值、野德解定身开关、暗牧鞭笞阈值8档+渊BOSS开关、冰DK 亡者复生/插入死从天降/插入铜墙铁壁全部可配置。
验证：/reload 后对应职业菜单出现新开关；冰DK 插入开关一次性生效后自动关闭。

【冰DK】2026-8-19（ZZ 移植第一弹：AOE 总开关 + 凛风优先级档 + 魔印切换 + 铁壁黑锋冰寒联动）

-- === AOE 总开关（DK_BDK_AOE） ===
问题：冰DK 凛风/血液沸腾/传染/多目标死从天降随智能 AOE 自动触发，无总闸，部分场景想关闭 AOE 打纯单体做不到。
修复（DeathKnight_Frost.lua）：新增「AOE」复选框（默认开）。关闭后凛风冲击（AOE 分支）、血液沸腾、AOE 传染、≥2 怪时死从天降全部不参与循环；单目标传染（WR_DK_BDK_CR）不受影响。

-- === 免费凛风优先级三档（DK_BDK_LFCJ_YXJ） ===
问题：免费凛风（冰冻之雾触发）固定排在普通冰霜打击前，无法调整与湮没的相对优先级。
修复：新增「免费凛风」下拉三档——湮没前 / 湮没后冰打前（默认）/ 普通冰霜打击后最低填充。主循环按档位调整 WR_DK_BDK_LFCJ_TC 调用位置。

-- === 魔印切换（DK_BDK_MYQH，魔印舞） ===
问题：恶意魔印（疾病增伤）与警觉魔印（湮没/冰霜增伤）只能手动切换，双印收益无法自动兼顾。
修复：新增「魔印切换」下拉四档——首次湮没 / 首次触发 / 循环切换 / 禁用（默认）。背包或装备栏同时拥有两印时生效：档1 首湮没后换警觉、档2 首次不洁之力后换警觉、档3 不洁之力期间警觉/结束后换回恶意；前三种模式脱战自动换回恶意魔印。

-- === 铁壁黑锋冰寒联动（DK_BDK_ZDHFBH） ===
问题：黑锋冰寒仅在爆发/杀戮机器时自动开，铜墙铁壁窗口内湮没吃不到必爆。
修复：新增「自动」复选框（默认开）。铜墙铁壁期间湮没满足原释放条件且黑锋冰寒可用时，先使用黑锋冰寒再打湮没（必爆湮没）。

效果：冰DK 可精细控制 AOE 范围；免费凛风优先级可调；双魔印收益自动兼顾；铁壁窗口湮没必爆。
验证：/reload 后菜单出现 2 下拉 + 2 复选框；魔印切换在持有双印时脱战自动换恶意、战斗按档位换警觉；关闭 AOE 后凛风/血沸/传染不再推荐。

【冰DK】2026-8-19（血冰/邪冰天赋分支识别 + 疾病动态续病危险区 + 分支循环优化）

-- === 血冰/邪冰天赋分支识别（P0） ===
问题：Frost DK 是统一循环，未按副天赋（血/邪）区分疾病续期、符文节奏与泄能策略；血冰通常 0 点蔓延（疾病 15s），邪冰通常满蔓延（疾病 24s），同一套阈值会同时亏 DPS。
修复（DeathKnight/DeathKnight_Frost.lua）：
- 新增 WR_DK_BDK_IsBloodFrost / WR_DK_BDK_IsUnholyFrost：判定顺序=菜单强制 > 蔓延天赋(51099/51160/51161) > 实测疾病时长特征（DK_DiseaseMax ≥20s 判邪冰，非主流 1~2 点蔓延也可靠）。
- 主循环在 DK_DiseaseMax 稳定后设置全局标记 DK_IsBloodFrost / DK_IsUnholyFrost，供所有阈值判断读取，避免重复 IsPlayerSpell。
- 菜单新增「天赋」下拉（DeathKnight_Menu.lua，DK_BDK_TF）：自动识别 / 血冰 / 邪冰，可强制指定分支。

-- === 分支循环优化（P1） ===
血冰（0 蔓延，疾病 15s，符文紧张）：
- 冰冷触摸补病阈值：3s → 疾病×0.3（≈4.5s），补得更早防断病。
- 湮没疾病门槛：>2s → >5s，避免强行湮没断病。
- 冰霜打击泄能：阈值提到 ≥60（未到 60 不泄能，保资源给死从天降/符文武器）。

邪冰（满蔓延，疾病 24s，能量充裕）：
- 冰冷触摸补病阈值：3s → 2.5s，补得更晚省 GCD。
- 冰霜打击（无杀戮机器）泄能：阈值提到 ≥80，能量充裕攒爆发。
- AOE 传染刷新阈值：7.5s → 动态 疾病×0.35（≈8.4s），更早传染保 24s 窗口。
- 黑冰天赋增益：凛风冲击疾病门槛放宽（>2s → >1.5s），AOE 更积极。

-- === 疾病动态续病危险区（P1） ===
问题：鲜血打击/血液沸腾使用固定阈值（>8 / <7.5 / >2），未区分 15s 与 24s 疾病窗口；0 蔓延时疾病 <7.5s 已进入续病危险区，此时打填充容易断病。
修复：新增 WR_DK_BDK_RefreshThreshold（疾病×0.35，血冰≈5.25s/邪冰≈8.4s）与 WR_DK_BDK_DangerZone（疾病×0.25，血冰≈3.75s/邪冰≈6s）。
- 血液沸腾/鲜血打击常规条件：固定 >8 → 动态 > refreshThreshold（疾病低于该值禁止非必要填充）。
- 危险区内配合传染的刷新变体：固定 <7.5 且 >2 → < refreshThreshold 且 > dangerZone。
- AOE 例外：≥3 目标时血液沸腾作为 AOE 主伤害，底线放宽到 dangerZone（仍保证至少 1 组符文留给续病）。
- 多目标保护：≥2 目标时鲜血打击跳过"双死亡符文"变体，避免填充占用死亡符文。

效果：血冰/邪冰各自走最优阈值；续病窗口内不再抢 GCD 打填充导致断病；AOE 场景不因保守损失伤害。
验证：/reload 后 DK_IsBloodFrost / DK_IsUnholyFrost 仅一个为 true；血冰 5min 木桩断病 ≤2；邪冰 5min 疾病覆盖率 ≥95%。

【布局/功能】2026-8-18（怪物屏蔽面板紧凑化 + 右侧图标去饱和 + 开关迁入左区全局）

-- === 开关迁入左区全局面板 ===
问题：怪物屏蔽/职业屏蔽开关散落在「功能设置」弹窗，入口分散、与全局开关割裂。
修复（Core/UI_Config.lua + Core/ZZ_Features_Migration.lua）：
- "启用怪物屏蔽"与"职业屏蔽"（近战AOE / 远程多线 / 坦克）迁入主界面左侧"全局"面板、置于"爆发总闸"下方，改为普通复选框（UICheckButtonTemplate）。
- ZZ_MonsterBlockMasterChk 由 local 改 global，供 ZZ_SetMonsterBlock 与 /monster 命令跨文件同步勾选态；原弹窗对应开关块删除并留注释。
- 修复迁移后 frame:OnShow 仍引用已删本地变量（master / meleeBlCheckbox / rangedBlCheckbox / tankBlCheckbox）导致的 nil 引用运行时报错。

-- === 怪物屏蔽面板紧凑化 ===
问题：移除开关后面板顶部留大片空白。
修复（Core/ZZ_Features_Migration.lua 分区1）：phaseDivider、团本阶段按钮(row1/row2)、怪物名单滚动框整体上移 100px 填补空白，滚动区因顶部上移而增高。

-- === 右侧图标未勾选去饱和 ===
问题：此前黑色遮罩压暗方案的辨识度/风格不符预期。
修复（Core/UI_Config.lua UpdateCheckboxGlow）：未勾选态改为 iconTexture:SetVertexColor(0.45,0.45,0.45)（去饱和）+ SetAlpha(0.28)（降低透明度）；勾选态恢复彩色；移除 ICON_DIM_ALPHA 与 dimOverlay 旧方案。

效果：怪物屏蔽面板紧凑无空白；左区全局开关集中；未勾选图标呈中灰+半透明，勾选恢复彩色。

【布局】2026-8-17（恢复「自动」标题条 + 标题条上下留白归零）

-- === 恢复三标题条 + 极致紧凑 ===
问题：上一轮为让自动组第一排紧贴上方，把「自动」标题条 Hide 了；用户反馈奶骑面板「自动」标题条不见，三个归纳不齐。

修复（Core/UI_Config.lua）：
- WR_LayoutTalentCheckboxes 的 placeHeader：取消对「自动」的特殊隐藏逻辑，「自动/爆发/插入」三标题条统一显示。
- SECTION_HEADER_GAP：2 → 0（标题条上下不再留白）。
- 布局起始 yCursor：-2 → 0，使第一个「自动」标题条顶部紧贴图标区/菜单区交界。

效果：三个归纳标题条齐全；自动标题条紧贴上方下拉/滑块区，第一排复选框紧贴自动标题条下方；爆发/插入标题条同样紧贴上下内容。整体在紧凑和归类清晰之间取平衡。

【布局】2026-8-17（修复右区内容溢出：取消已迁移底栏的底部占位）

-- === 内容溢出根因 ===
问题：DK 等图标较多的职业出现复选框/标题条跑出主窗口底部。
根因：图标缩放、窗口透明度两个滑块早已迁入左侧全局区，但 `Core/UI_Config.lua` 里的 `BOTTOM_BAR_H` 仍按 86px 预留旧底栏高度。该高度同时被左右区底部锚点使用，导致右职业区实际可用高度被削掉 86px，内容装不下就溢出。

修复（Core/UI_Config.lua）：
- `BOTTOM_BAR_H`：86 → 0，并更新注释说明底栏控件已迁走。

效果：右职业区底部重新贴到主窗口下边缘，恢复被吞掉的 86px 垂直空间；DK 等长列表不再溢出。其他职业只要内容没超过窗口最大高度，也会正常显示。

【布局】2026-8-17（自动组紧贴上方：取消「自动」标题条占位）

-- === 自动组标题条去占位 ===
问题：上一轮收紧间距后仍反馈——「自动」作为第一排复选框，没有紧挨着上面的下拉框/滑动条。根因是「自动」标题条（高 22 + 上下留白）仍占据垂直空间，把第一排图标往下挤。

修复（Core/UI_Config.lua WR_LayoutTalentCheckboxes）：
- placeHeader 对 sec=="自动" 的处理改为：标题条 Hide()（不显示占位），yCursor 仅减 2px 起始留白（原减 SECTION_HEADER_GAP+SECTION_HEADER_H+SECTION_HEADER_GAP=22+）。
- 「爆发」「插入」分类标题条保留，用于中间分隔各组，不产生混乱。

效果：自动组第一排复选框紧贴上方下拉/滑块区（间距约 4px），爆发/插入仍用标题条分组，界面更紧凑且保持归类清晰。

【布局】2026-8-17（收紧下拉/滑块区与复选框区的垂直间距）

-- === 间距收紧 ===
问题：截图反馈蓝色框区域（下拉菜单/滑动条底部 → 复选框「自动」标题条）垂直留白过大，显得松散。

修复（Core/UI_Config.lua 常量）：
- MENU_BOTTOM_PAD：4 → 0（菜单区底部不再额外留白）
- ICON_REGION_TOP_PAD：4 → 0（图标区标题条紧贴菜单区底部）
- SECTION_HEADER_GAP：4 → 2（分类标题条上下留白减半）

效果：滑动条/下拉框与下方「自动/爆发/插入」复选框标题条之间的距离显著减小，界面更紧凑。

【分类】2026-8-17（恢复「自动/爆发/插入」三归纳，未归类复选框统一归入自动）

-- === 恢复三大分类归纳 ===
问题：上一轮删除 section="自动" 时，部分写成独占行格式的自动项未被替换，导致：
- 多数原「自动」项变成无 section 默认项（无标题条、排在最前），视觉上"没归纳"；
- 少数残留 section="自动" 项在末尾又冒出「自动」标题条，造成混乱/重叠。

修复（Core/UI_Config.lua）：
- WR_LayoutTalentCheckboxes：无 section 的复选框一律归入「自动」归纳（sec = config.section or "自动"），恢复 sectionPriority = {自动=1, 爆发=2, 插入=3}。
- 移除 defaultItems 单独分支，统一由各分类标题条顺序摆放（自动 → 爆发 → 插入）。
- 创建复选框处（CreateTalentFrame）：无 section 项也惰性创建「自动」标题条，确保三大分类标题条齐全。

效果：所有复选框都归属「自动/爆发/插入」三大分类之一，不再有无标题默认项，消除重叠。

-- === 历史 ===
此前经历「特化」→「自动」→取消「自动」的反复，本次以"布局层兜底 + 标题条兜底"彻底固定三分类结构。

【分类】2026-8-17（取消「自动」section 标题条，BOSS 机制选项融入默认组）

-- === 取消「自动」section 标题条 ===
将所有职业 *Menu.lua 中 CB 复选框的 section="自动" 统一删除，使其成为无 section 的默认项（defaultItems）。
涉及文件：Paladin_Menu.lua、DeathKnight_Menu.lua、Druid_Menu.lua、Hunter_Menu.lua、Mage_Menu.lua、Priest_Menu.lua、Rogue_Menu.lua、Shaman_Menu.lua、Warlock_Menu.lua、Warrior_Menu.lua。

效果：
- 不再显示「自动」金色标题条，所有原「自动」选项（含寒霜刺骨、狂咒、血肉成灰、制裁之锤、瓦格里逃脱、血兽屏蔽、统御心灵旋风、反魔法护罩等 BOSS 机制开关）直接作为默认项连续排列。
- 「爆发」「插入」section 仍保留标题条，按 爆发 → 插入 顺序排列在默认项之后。

-- === UI 间距收紧 ===
Core/UI_Config.lua：
- MENU_BOTTOM_PAD：10 → 4，减小下拉菜单区底部留白。
- ICON_REGION_TOP_PAD：12 → 4，减小图标区顶部留白。
- sectionPriority 移除「自动」，仅保留「爆发」「插入」。

解决：复选框（图标区）与上方下拉框/滑动条之间垂直距离过远的问题。

-- === 历史 ===
此前曾尝试将 BOSS 机制选项单独归为「特化」，后出现标题条重叠；后改回「自动」，又因「自动」标题条造成视觉分割。本次彻底取消「自动」标题条，使所有自动类选项融为一体。

【分类】2026-8-17（取消「特化」分组，BOSS 机制选项合并回「自动」）

-- === 取消「特化」分组 ===
将此前标记为 section="特化" 的 BOSS 机制类选项统一改回 section="自动"，不再单独显示「特化」标题条。
涉及文件：Paladin_Menu.lua、DeathKnight_Menu.lua、Druid_Menu.lua、Hunter_Menu.lua、Mage_Menu.lua、Priest_Menu.lua、Rogue_Menu.lua、Shaman_Menu.lua、Warlock_Menu.lua、Warrior_Menu.lua。

合并回「自动」的选项类型：
- 寒霜刺骨（冰龙）：DK 三系、德鲁伊野性/平衡、圣骑士惩戒、潜行者三系、萨满元素/增强、战士武器/狂怒。
- 狂咒（辛达苟萨）：法师三系、牧师戒律/神圣/暗影、萨满元素、德鲁伊平衡。
- 血肉成灰（腐面/烂肠）：圣骑士神圣、德鲁伊恢复。
- 制裁之锤（巫妖王瓦格里/中虫）：圣骑士惩戒/防骑/神圣。
- 瓦格里逃脱：猎人三系。
- 血兽屏蔽/统御心灵旋风/反魔法护罩等 ICC/TOC 机制：对应职业复选框一并合并回「自动」。

-- === UI 同步调整 ===
Core/UI_Config.lua：
- 移除 CreateTalentFrame 中的 DM 特化分组逻辑，不再在默认 DM 组末尾插入「特化」标题条。
- WR_LayoutTalentCheckboxes 的 sectionPriority 恢复为仅「爆发/自动/插入」，不再对「特化」单独排序。
- 解决此前出现两个「特化」标题条、并与上方滑动条/下拉框重叠的问题。

【分类】2026-8-17（神圣骑 BOSS 特化复选框归类 + 图标区顶部间距加大）

-- === 神圣骑 BOSS 机制开关归入「特化」分类 ===
Paladin/Paladin_Menu.lua（神圣专精 CB）：
- 「狂咒」(SS_KZ) 与 「血肉成灰」(SS_XRCZ) 的 section 由 "自动" 改为 "特化"，使 ICC 辛达苟萨/烂肠腐面等 BOSS 机制开关单独成组。

Core/UI_Config.lua：
- WR_LayoutTalentCheckboxes 的 sectionPriority 新增 ["特化"] = 0，排序在「爆发」之前，确保特化标题条显示在最上方。

-- === 图标区与上方下拉/滑动条间距加大 ===
Core/UI_Config.lua：
- MENU_BOTTOM_PAD 由 6 增大到 10，ICON_REGION_TOP_PAD 由 6 增大到 12，缓解图标区顶部与菜单区底部贴得太紧、甚至重叠的问题。

【分类】2026-8-17（插件图标归位到左框架左上角）

-- === 插件图标从左上角标题旁移回左侧全局区左上角 ===
Core/UI_Config.lua：
- 插件图标(MKHelperForeverIcon)锚点由 configFrame 顶栏 TOPLEFT(10,-2)（即标题左侧）改为 globalRegion 左上角 TOPLEFT(GLOBAL_INNER_PAD, -GLOBAL_INNER_PAD)，落在左侧"全局"区左上角，不再压在顶栏标题左侧。

【分类】2026-8-17（顶栏外观 + 按钮布局 + 整体缩放）

-- === 顶栏去除深灰染色 ===
Core/UI_Config.lua：
- 移除顶栏自定义深灰纹理(WR_TopBar)与下缘分界线(WR_TopBarLine)，恢复 UIPanelDialogTemplate 默认外观。
- 标题直接锚定主框顶部中央(STANDARD_TEXT_FONT 14 + OUTLINE 白色)，不再依赖任何自定义色块，正常显示即可。

-- === 功能设置/重置按钮左移避免与×重合 ===
- 功能设置按钮 TOPRIGHT x 由 -76 改为 -109；重置按钮 TOPRIGHT x 由 -5 改为 -34；关闭按钮保持 TOPRIGHT。三者依次排列，重置与右上角×不再重合。

-- === 右下角支持整体等比缩放 ===
- 右下角手柄(scaleGrabber)由"整体宽度/高度双轴调整(BeginConfigFrameResize)"改为真正的等比缩放：OnUpdate 中按光标右下外拖/内拖增量计算新 scale(0.5x~2x)，SetScale + 记录 PigSet.FrameScale，文字与控件随窗口一起放大/缩小；旧的双轴 rightSizer 宽度调整保留在右边缘。

【分类】2026-8-17（滑动条与顶栏精修）

-- === 顶栏职业色染色取消 ===
Core/UI_Config.lua：
- 取消顶栏下缘职业色分隔线，改为深灰(0.18,0.18,0.18,0.75)，避免顶部出现大面积职业色横条，标题在任意职业色下都清晰。

-- === 滑动条百分比改到右端并与下拉框对齐 ===
CreateMenuSlider(Core/UI_Config.lua)：
- 百分比数值由"滑块上方"改为"滑块右侧"，预留固定 40px 宽度，文本右端与下拉框右端对齐。
- 滑块轨道左端仍接标签右缘，右端缩短以容纳百分比，确保"滑块+百分比"整体左右端与下拉框对齐。
- 行高 MENU_ROW_H 由 26 增大到 32，滑块在垂直方向居中于行内，缓解滑动条与上下下拉框的拥挤感。

【分类】2026-8-17（顶栏与滑动条对齐修复）

-- === 顶栏标题不清晰修复 ===
Core/UI_Config.lua：
- TOP_BAR_H 由 64 收窄为 28，仅保留标题栏区域，避免过宽的色块压迫下方左/右分区。
- 顶栏背景改为深灰(0.12,0.12,0.12,0.95)，职业色仅用于下缘 2px 分隔线，确保任意职业色下标题都清晰。
- 标题锚定顶栏中心，使用 STANDARD_TEXT_FONT 14 + OUTLINE 描边，白色文字，彻底解决浅色职业色上标题看不清的问题。
- 插件图标缩小为 24x24 并移回顶栏左侧；功能设置/重置按钮 y 偏移由 -35 改为 -3，保持在标题栏内。

-- === 滑动条长度与下拉框对齐 ===
CreateMenuSlider(Core/UI_Config.lua)：
- 滑动条右缘由 "父框右缘 - (labelX+54)" 改为 "父框右缘 - labelX"，与下拉框右缘完全对齐。
- 百分比数值由"滑块右侧外部"改为"滑块上方右侧"，既保留在轨道旁边可读，又不占用轨道水平空间，保证轨道与下拉框等长。

【分类】2026-8-17（界面UI借鉴ZZHELPER·方案A-D）

-- === A. 顶部职业色装饰条 ===
主配置窗口(WR_ConfigFrame, Core/UI_Config.lua)顶部新增职业色装饰条：BACKGROUND 层 0.9 alpha 覆盖顶栏(TOP_BAR_H=64)全宽 + 下缘 2px 深色分隔线；标题文字改白色更清晰。插件图标/功能设置按钮/关闭按钮位于其上层不受影响，一眼可辨 MKH 专属界面。

-- === B. 滑动条统一主题化 ===
CreateMenuSlider 现有轨道/填充基础上：隐藏的拇指改为可见金色竖条(6x18, 顶点色 1,0.84,0)，便于拖拽；外框描边由纯黑改为职业色半透明(0.5 alpha)，与顶栏职业色呼应。百分比文字仍位于滑块右侧外部。

-- === C. 下拉菜单弹出位置优化 ===
CreateDropdownMenu 的菜单弹出锚点由"下拉框左下角(BOTTOMLEFT)"改为"下拉框底部中央(TOP/BOTTOM 水平居中)"，菜单向下展开不偏出窗口右侧，与焦点下拉框体验一致。

-- === D. 图标按钮与复选框状态联动 ===
未勾选时图标去饱和+变暗(顶点色灰 0.45 + alpha 0.28)，勾选时恢复彩色(顶点色 1 + alpha 0.85/1)：
- 配置面板图标(Core/UI_Config.lua UpdateCheckboxGlow 的 else 分支)：复用现有金色光效表达"已启用"，未勾选额外去饱和+暗淡；
- 功能设置面板图标(Core/ZZ_Features_Migration.lua Iconid_F005)：新增 ApplyIconEnableState()，接入点击切换/斜杠命令 on/off/toggle 与悬停恢复，未勾选即灰暗、勾选即亮彩。
- 注：WoW 客户端无 SetDesaturated，改用 SetVertexColor 灰度 + 降 alpha 模拟，全客户端兼容。

【分类】2026-8-17（下拉框指示图标）

-- === 下拉框统一使用原生下拉箭头 ===
为所有配置面板下拉框（天赋 DM 下拉、WCL 下拉、两处功能迁移下拉）恢复并统一使用 UIDropDownMenuTemplate 原生下拉箭头，与焦点/专精下拉框的箭头样式、位置、交互完全一致：
- 移除之前自定义的职业色三角按钮与 SetAlpha(0) 隐藏原生箭头的逻辑；
- 保留 overlayBtn 覆盖输入区用于整框点击展开/收起，原生箭头按钮负责右侧箭头区域的点击；
- 所有下拉框视觉统一，不再出现自定义箭头与原生箭头并存或位置不一致的问题。

【分类】2026-8-17

-- === 同步参考版更新·冰DK疾病/种族/不灭药水/符文武器增效 + 全职业种族GCD + UI缩放（2026-8-17）===
依据参考版更新日志逐条同步到本地 MKH：

① 冰DK 蔓延0点疾病续病阈值动态化(DeathKnight_Frost.lua):新增文件级 DK_DiseaseMax 追踪双疫病最大持续时间（疾病消失即重置），血液沸腾(WR_DK_BDK_XYFT)/鲜血打击(WR_DK_BDK_XXDJ) 的"疫病快结束"续病判定由固定 7.5s/2s 改为按 DK_DiseaseMax 比例(0.5/0.13)计算——蔓延0点(15s)时≈7.5s/2s 与旧值一致，蔓延满(24s)时按比例放宽，避免0点天赋因阈值错位断病。常规">8 健康门"保持不变以降低风险。

② 全职业种族技能加 GCD 闸门 + 矮人石像形态(20 个职业文件共 32+ 处):所有正向种族可用判定 WR_SpellUsable("狂暴"/"血性狂怒"/"狮心") 追加第二参 true（GCD 结束才返回 true），修复爆发窗口每帧重复提示种族技能、卡住主循环的问题；并在同一 OR 链补 WR_SpellUsable("石像形态", true)，使矮人也能被"自动种族"识别（非矮人该 spell 不可用自动跳过，无副作用）。负向 not WR_SpellUsable(...) 自动关闭逻辑不动。

③ 冰DK/武器战 不灭药水脱战过早提示(DeathKnight_Frost.lua WR_DK_BDK_BMYSH / Warrior_Arms.lua WR_WQZ_BMYSH):触发前新增"非战斗且不在 DBM 预拉窗口则直接 return false"闸门，避免 BOSS 战结束刚脱战就过早提示喝不灭药水；预拉偷药窗口不受影响。

④ 冰DK 符文武器增效耗空判断收紧(DeathKnight_Frost.lua WR_DK_BDK_CRWZDJ):插入式符文武器增效触发条件由"任一符文类型<1 即可"改为"至少两种符文类型同时耗空((HFW<1且LVFW<1)或(HFW<1且LANFW<1)或(LVFW<1且LANFW<1))"，更贴合"符文耗空时"语义、避免单次符文空窗就浪费 2 分钟 CD；亡者大军分支逻辑不变。

⑤ 设置界面拖拽缩放框体不跟随鼠标(Core/UI_Config.lua BeginConfigFrameResize):光标位移换算用的缩放由 configFrame:GetEffectiveScale() 改为 UIParent:GetEffectiveScale()，修复配置框被自身 SetScale 缩放后换算倍率叠加、拖拽/缩放时框体移动速度跟不上鼠标的问题。

注：①/④ 为循环逻辑改动，建议木桩与实战验证疾病覆盖与符文武器增效触发时机；② 矮人石像形态为防御向技能，若实战中发现矮人职业在爆发窗口过度提示石像形态，可后续改为仅中毒/疾病/流血时触发。

【分类】2026-8-16

-- === 修复 血DK 主循环 93 行 nil 报错（2026-8-16）===
DeathKnight_Blood.lua:主循环「预拉块」(93行)及另外3处调用点原调用文件尾部 local 函数 WR_GetDBMCountdown，在脱战待机帧被前向调用时该 local 尚未就绪 → attempt to call a nil value（每帧报错，刷数千次）。已全部改为调用全局 WR_GetDBMCountdown_EM()（Core 早已加载，无前向解析问题）。修复后木桩/倒数测试不再崩溃。

-- === 血DK(DKT)木桩/训练假人支持测试（2026-8-16）===
DeathKnight_Blood.lua:WR_DK_Blood_DPS_XEKR_P(自己邪恶狂热) 门控由 zidongbaofa 改为 (zidongbaofa or WR_IsTrainingDummy("target"))。新增全局函数 WR_IsTrainingDummy，用名字子串(训练假人/木桩/Dummy/Training/大领主)兜底识别训练假人，不再依赖客户端可能缺失的 UnitIsTrainingDummy API。使木桩(含大领主的训练假人、奥格等各城市假人)也能测试预拉狂热，无需锁定白名单 Boss。

-- === 血DK(DKT)自己邪恶狂热接入 DBM 倒数预拉（2026-8-16）===
DeathKnight_Blood.lua:在「自动攻击」之后、「进战斗判定」之前新增预拉块。开启「自己邪恶狂热 DK_Blood_ZDXEKR_P」时，若 DBM 倒数 ≤ 预开窗口(默认3秒，受「偷药预开时间 TOUYAO_TIME」控制)且未进战斗，提前给自己施放邪恶狂热(满攻速起手)；进战斗后 6冰触 正常先打，狂热已进 CD 被跳过。新起手顺序：狂热(预拉)→ 进战斗 → 6冰触。复用既有 WR_GetDBMCountdown_EM()+WR_PrepullInWindow() 预开框架(与药水/种族/手套/饰品一致)。菜单提示同步补充"DBM 倒数 ≤3 秒预拉提前上"及"木桩也可测试"。

-- === 防骑「指向保护/牺牲」改名全局保护/牺牲 + 三项鼠标指向归入「插入」分组（2026-8-16）===
防骑下拉框改名(Paladin_Menu.lua + Core/UI_CommandList.lua):原「指向保护」「指向牺牲」下拉框实际是团血阈值自动补，名不副实，现改为「全局保护」「全局牺牲」，tooltip 明确为"全局保护(自动保护之手)/全局牺牲(自动牺牲之手)：开启后团内非坦克队友血量≤阈值时自动对其施放，与下方鼠标指向插入复选框相互独立"；UI_CommandList.lua 第77/78行命令描述同步改为「全局保护(自动保护之手)」「全局牺牲(自动牺牲之手)」。三项鼠标指向复选框归入插入分组(Paladin_Menu.lua):「指向保护 FH_ZZBH」「指向牺牲 FH_ZZXS」「指向拯救 FH_ZZJZ」均为鼠标指向队友直接插入、属一次性插入语义，section 由"自动"改为"插入"（显示名保持「指向保护/指向牺牲/指向拯救」不变）；原误将其当作"自动"聚合，现与插入类技能/饰品/药水/手套/种族/图腾同组。复选框 tooltip 同步把"上方下拉"措辞改为"上方「全局保护/全局牺牲」下拉"以对应新名。

-- === 血DK(DKT)自己邪恶狂热支持（2026-8-16）===
DeathKnight_Blood.lua:原 WR_DK_Blood_DPS_XEKR_P(自己邪恶狂热)仅在输出模式(DK_Blood_ZZ==2)块调用，坦克练级模式(DK_Blood_ZZ==1)未调用，导致 DKT 无法对自己施放邪恶狂热；函数本身无坦克模式门控(仅查开关 DK_Blood_ZDXEKR_P + 技能可用 + zidongbaofa 爆发)，现于坦克模式块(焦点调用后)补一行调用，使 DKT 爆发时也能对自己施放。菜单提示修正(DeathKnight_Menu.lua):「自己邪恶狂热 DK_Blood_ZDXEKR_P」提示由"输出模式专用"改为"坦克/输出模式均可，爆发时自动对自己邪恶狂热"；「焦点邪恶狂热 DK_Blood_ZDXEKR_F」提示原写"坦克模式无效"与代码(两模式均调)不符，改为"坦克/输出模式均可，爆发时对焦点玩家邪恶狂热"。注：邪恶狂热给自己施放会使施法者承受伤害+5%(WLK机制)，DKT 权衡攻速收益自定是否开启。

-- === 战斗逻辑优化（防骑驱散/萨满牧师进攻驱散/奶萨风剪打断/刺杀贼毒伤，2026-8-16）===
防骑 自己/目标驱散改不走焦点(Paladin_Protection.lua + Paladin_Macros.lua):原 WR_PaladinProtection_Unit_QJS 非鼠标指向分支用 WR_FocusCast(Unit,63,"清洁术") 会设焦点执行；现 player/target 改为直接对单位施放，复用既有直通宏按钮 43=/cast [target=player] 清洁术、44=/cast [target=target] 清洁术（不另增宏、不占用玩家手动焦点）；小队/团队扫描仍保留 WR_FocusCast 设焦点；两个复选框 FH_QJS_Player/FH_QJS_Target 不再占用玩家手动焦点。

萨满/牧师 进攻驱散修正(Core_Functions.lua + Shaman_Restoration.lua + Priest_Discipline.lua + Priest_Holy.lua):新增 WR_UnitBuffType(Unit,BuffType) 镜像 WR_UnitDebuffType 但扫描 HELPFUL 光环；三处进攻驱散（净化术/驱散魔法打敌方）原误用 WR_UnitDebuffType("target","Magic")（检测魔法减益）导致对无增益目标空放、浪费GCD卡住后续技能，现改为 WR_UnitBuffType("target","Magic")（只处理射程内、确有可移除魔法增益的敌方目标）。原函数已含 IsSpellInRange 与 UnitCanAttack 敌方判定。

奶萨 焦点自动打断(Shaman_Restoration.lua + Shaman_Menu.lua):新增 WR_ShamanRestoration_DD()，开启 HF_ZDDD 后对【焦点】敌方（须Enemy且风剪射程内且正在读条/引导）用风剪(按钮12=/cast [target=focus,exists] 风剪;风剪)打断，保留当前目标作为治疗目标；在主循环"保命"之后、"驱散/治疗"之前插入，必要时停止治疗优先打断。菜单恢复萨 CB 第3行第1列新增"打断"开关，默认关。

刺杀贼 毒伤补涂时机优化(Rogue_Assassination.lua):WR_DZ_CS_DS 原仅在毒伤增益彻底消失(<0.1s)或能量溢出或目标将死时补涂，存在空窗；新增"增益剩余<2s 且连击点≥阈值(minLJD)且能量≥毒伤消耗"时提前重涂，提高毒伤/加速增益覆盖。连击点阈值仍由 DZ_CS_DSXS 控制(默认5/可选3或4)。

-- === 战斗逻辑优化·二次修订（2026-8-16 依据实测反馈调整）===
防骑 清洁术复用既有宏(Paladin_Macros.lua + Paladin_Protection.lua):移除首轮临时新增的 72/73 宏，改复用既有直通宏 43(/cast [target=player] 清洁术)、44(/cast [target=target] 清洁术)；WR_PaladinProtection_Unit_QJS 的 player/target 分支改用按钮 43/44 直放，行为不变（仍不经设焦点）。

奶萨 打断改为焦点(Shaman_Restoration.lua + Shaman_Menu.lua):WR_ShamanRestoration_DD 由"当前目标"改为"焦点"敌方打断（按钮 17→12，宏 12=/cast [target=focus,exists] 风剪;风剪）；保留当前目标作为治疗目标，避免选中治疗目标时无法加血。菜单"打断"提示同步改为对焦点敌方。

萨满 进攻驱散支持焦点(Shaman_Restoration.lua + Shaman_Macros.lua):WR_ShamanRestoration_JHQS 新增优先对【焦点】敌方净化（新增宏 64=/cast [target=focus] 净化术，按钮 64），其次才对当前目标敌方净化；两者均仅处理射程内、确有可移除魔法增益的敌方，避免空放卡GCD。移除原 WR_FocusCast 调用以免误抢玩家焦点。

-- === 全职业「爆发」分类（2026-8-16）===
全职业设置新增「爆发」分类(Core/UI_Config.lua + 全部 *_Menu.lua):天赋面板图标网格改为支持按 config.section 分组——同 section 的开关自动归到面板底部、并以金色标题条「爆发」分隔（标题条复用功能设置分区样式），无 section 标签时布局完全不变。已为 10 个职业菜单共 146 个爆发相关开关打上 section="爆发"：初版覆盖爆发模式主开关、爆发期偷药、自动饰品、工程手套附魔、爆发窗口胸甲，以及职业爆发技能（复仇之怒/鲁莽/死亡之愿/狂暴/冲动/奥术强化/准备就绪/嗜血/死从天降/黑锋冰寒 等）；随后补充将「自动手套(ZDST)」「自动种族(ZDZZ)」「自动药水(ZDSDYS/ZDSRYS/SDYS，含猎人速度药水，排除手动插入类 CR 前缀)」三类通用开关（共 66 个）一并归入「爆发」分组，使手套/种族/药水与爆发总闸/饰品/偷药聚合在同一金色标题条下。WR_LayoutTalentCheckboxes 改为先按「默认组+各分类」测算像素高度供外层算面板尺寸，再按分组落位（默认组在前、各分类带标题条在后）。注：种族爆发（血性狂暴/奥术洪流/战争践踏/石像形态/逃命/影遁 等）当前未在天赋面板以开关形式暴露，故未纳入；后续若新增种族爆发开关，打上 section="爆发" 即可自动归入该分类。

-- === 全职业「自动 / 插入」分类（2026-8-16）===
全职业设置新增「自动」「插入」两个分组(Core/UI_Config.lua + 全部 *_Menu.lua):沿用「爆发」的 config.section 机制（标题条文字动态取 config.section，复用功能设置分区样式）。新增固定分组顺序 爆发 → 自动 → 插入（WR_LayoutTalentCheckboxes 内 sectionOrder 改为按 sectionPriority 表固定排序，未知分组按名称排其后），保证各职业面板底部标题条顺序一致。打标规则：①已有 section="爆发" 的 146 个开关保持不动；②显示文本含「插入」的复选框归入 section="插入"（共 177 个，覆盖各职业 插入XXX技能 / 饰品 / 药水 / 手套 / 种族 / 图腾 等手动插入类，排除已归 爆发的 11 个重叠项）；③其余所有持久化复选框（"勾选一次一直生效"的自动化/行为开关）归入 section="自动"（共 510 个，覆盖 自动XXX / 坦克 / 炸弹 / 锁BOSS / 打断 / 焦点 / 屏蔽 / 智能AOE / 全局 / 治疗阈值 等）。全职业 833 个复选框 100% 归入 爆发/自动/插入 三分组，默认组为空。打标脚本按 saveVariable+显示文本识别，对已含 section 的条目跳过，可重入。

-- === 更新日志适配（指向痛苦压制 / 坦克盾优先当前坦克 / 不灭药水不重复喝）===
戒律牧 指向痛苦压制(Priest_Discipline.lua + Priest_Macros.lua + Priest_Menu.lua + UI_CommandList.lua):新增独立开关 JL_TKYZ_MOUSEOVER（默认关）。开启后对鼠标指向的友方队友无条件施放痛苦压制（不做血量阈值/战斗判定），复用宏槽 82（[@focus] 痛苦压制）经 WR_FocusCast 两帧聚焦鼠标目标后释放；主循环第 10 步插入 WR_PriestDisCipline_TKYZ_Mouseover()。菜单第 6 行第 1 列新增复选框，命令 /JL_TKYZ_MOUSEOVER。

戒律牧 坦克盾优先当前抗怪坦克(Priest_Discipline.lua):WR_PriestDisCipline_ZYSD("坦克") 分支改为优先 CurrentTankUnit（由 WR_PriestDisCipline_FindTank 基于仇恨统计得出），其余坦克兜底，确保真言术：盾先覆盖正在抗怪的坦克。

冰DK/武器战 不灭药水不重复喝(DeathKnight_Frost.lua + Warrior_Arms.lua):WR_DK_BDK_BMYSH()/WR_WQZ_BMYSH() 开头新增 WR_GetUnitBuffTime("player","坚不可摧")>0 守卫，已有不灭药水增益期间不再重复喝。

-- === 主面板左右分区重构（左全局区 / 右职业区）===
主面板 WR_ConfigFrame 拆分为左右双区(Core/UI_Config.lua):新增 WR_GlobalRegion(左侧固定宽 180,承载跨职业通用开关,仅构建一次) / WR_Divider(分隔线) / WR_ClassRegion(右侧自适应宽,承载当前专精天赋面板)。左区含:调试模式、自动跟随+跟随目标、自动救人(ZL_ZDJS)、倒数偷药(DBM_PREPULL_POTION)、偷药时间(TOUYAO_TIME 滑块)、爆发总闸(GLOBAL_BURST 新增全局 UI 总闸)、开关提示;右区复用 WR_TalentFrameList 天赋面板(挂 WR_ClassRegion 并按其 TOP 锚定)。WR_LayoutConfigFrame 改为双区算宽(总宽=左区+分隔+右区+两侧边距,总高含顶栏/底栏,限制最小总宽度 420 与右区最少 2 列图标),WR_UpdateIconLayoutAnchor 与 WR_LayoutTalentCheckboxes 改引 WR_ClassRegion;底栏仅保留图标缩放+窗口透明度(挂右区底部)。UI_TalentFrame.lua 职业标题 TianFu_Text 锚点改引 WR_ClassRegion。ZZ_Features_Migration.lua 的 Iconid_F008 通用设置移除已上提的 倒数偷药/偷药时间/治疗职业自动救人 三项;Priest_Menu.lua 戒律牧/神圣牧移除重复的救人 CB(统一由左区管理)。WCL模式保留在顶栏。首次加载尺寸标记改为 _UI_Config_Resized_2026_08_16，强制应用新默认尺寸 420x420，避免旧 260x240 导致溢出。

-- === 主面板左右分区布局修复（2026-8-16 实测后调整）===
主面板(Core/UI_Config.lua):修复默认宽度 260 过窄导致右区仅 1 列/整体被撑高、默认高度 240 过矮导致左区控件溢出 globalRegion 的问题。调整默认尺寸为 420x420、左区宽 180、行高 26;左区所有全局开关改用相对前一控件锚定(标题→调试模式→自动跟随→跟随下拉→自动救人→倒数偷药→偷药时间→爆发总闸→开关提示),不再使用固定绝对偏移。WR_LayoutConfigFrame 新增 minFrameW/minRightW 限制，拖拽缩放最小宽度 300，防止右区被压成单列;FrameUserSized 时仍按当前宽度重算列数，不足最小宽度才强制扩展。

-- === 主面板左右分区布局二次修复（2026-8-16 解决右区溢出/未居中/滑块越界）===
主面板(Core/UI_Config.lua + UI_TalentFrame.lua):①默认宽度 420→560、最小总宽度 420→540，给右职业区留出足够空间；②CreateTalentFrame 中天赋面板 Frame 改为用 TOPLEFT/BOTTOMRIGHT 四点锚定填满 WR_ClassRegion，避免旧 1x1 尺寸导致下拉菜单标签锚点失效；③CreateDropdownMenu 新增 align="left" 分支供职业区使用（标签在左、下拉框在右），CreateTalentFrame 调用时传入 align="left"，使下拉菜单在右区内整齐左对齐；④底栏图标缩放/窗口透明度滑块父框改为 classRegion、锚点改为底部居中，WR_LayoutConfigFrame 中滑块宽度改为 rightW-32，避免越出右区；⑤职业标题 TianFu_Text 改为在 WR_ClassRegion 顶部居中。WCL 模式等顶栏下拉仍保持默认右对齐，不受职业区改动影响。

-- === 主面板左右分区布局三次修复（2026-8-16 解决旧尺寸未重置导致仍按 260 宽渲染）===
主面板(Core/UI_Config.lua):①将尺寸重置逻辑从 ConfigFrame 末尾移到函数开头（在读取 FrameWide/FrameHigh 之前），确保首次加载即丢弃旧版 260x240 尺寸；②默认宽度 560→820、默认高度 420→480、左区宽 180→200、下拉菜单默认宽 180→150、行高 26→24；③WR_LayoutConfigFrame 中新增右区下拉框宽度自适应逻辑（dmMaxW = rightW - 90），随面板缩放动态压缩，防止越界；④底栏滑块宽度 rightW-32→rightW-48，给右侧数值文字留足空间；⑤最小总宽度 540→640，避免用户拖得过窄导致右区溢出。UI_TalentFrame.lua 职业标题锚点保持右区顶部居中不变。

-- === 主面板左右分区布局四次修复（2026-8-16 解决右区下拉/图标互相挤压）===
主面板(Core/UI_Config.lua + UI_TalentFrame.lua):①右职业区 WR_ClassRegion 拆分为顶部菜单区 WR_ClassMenuRegion 与底部图标区 WR_ClassIconRegion，下拉菜单与图标网格分区承载，避免 DM 过多时把 CB 图标推到底栏/面板外；②WR_LayoutConfigFrame 按 menuRegionH + iconRegionH + bottomBarH 重新计算右区高度，超过 MAX_FRAME_HEIGHT(680) 时优先压缩菜单区、保留图标区最小高度；③CreateTalentFrame 父框改为 WR_ClassMenuRegion，图标锚点 WR_IconLayoutAnchor 改为挂在 WR_ClassIconRegion，WR_UpdateIconLayoutAnchor 同步改引图标区；④CreateMenuSlider 对齐方式改为与 CreateDropdownMenu 一致（标签在左、滑块在右）；⑤默认宽度 820→720、最小总宽度 640→580、外边距/左区宽微调，进一步适配常见分辨率；⑥尺寸重置标记升级为 _UI_Config_Resized_2026_08_16_03，/reload 后强制应用新默认尺寸。UI_TalentFrame.lua 职业标题锚点改引 WR_ClassMenuRegion。

-- === 主面板左右分区布局五次修复（2026-8-16 WCL模式移到右区顶部）===
主面板(Core/UI_Config.lua):将 WCL 模式下拉菜单从左上角(原锚定 MKHelperForeverIcon)移到右侧职业区顶部菜单区 WR_ClassMenuRegion 右上角，与居中的天赋标题 TianFu_Text 同处标题行，避免占用左侧全局区空间；下拉框向左展开，不额外占用职业下拉菜单行。尺寸重置标记保持 _UI_Config_Resized_2026_08_16_03 不变，/reload 即可生效。

-- === 主面板左右分区布局六次修复（2026-8-16 按用户三点要求调整）===
主面板(Core/UI_Config.lua):①底栏两个滑块(窗口透明度 WR_AlphaSlider / 图标大小缩放 WR_IconScaleSlider)由右职业区底部迁入左侧全局区,锚定在「开关提示」复选框下方依次排列,左区完整收纳所有全局控制项,右职业区底部不再保留底栏;②WCL 模式改为与职业下拉模块左对齐(align="left",标签在左、下拉框在右),置于右区菜单区第一行,职业下拉模块整体下移一行(MENU_TITLE_H+MENU_ROW_H)给 WCL 让位;③左侧「焦点」跟随目标下拉框由「跟随」复选框下方改为其右侧并列(锚定跟随标签 RIGHT),宽度压缩至左区剩余空间。WR_LayoutConfigFrame 同步:左区内容高度加 2 行、右区去掉底栏高度、菜单区为 WCL 预留 1 行、删除对两个已迁移滑块的宽高复写。尺寸重置标记保持 _UI_Config_Resized_2026_08_16_03 不变,/reload 即可生效。

-- === 主面板左右分区布局十次修复（2026-8-16 左区控件顺序与滑块数值越界）===
主面板(Core/UI_Config.lua):①按用户要求将「自动跟随」复选框与「跟随目标」下拉框移到左区最底部:在窗口透明度滑块(alphaSlider)创建后,对 followCheckbox 与 followDropdown 执行 ClearAllPoints 并重新锚定到 alphaSlider 下方(followDropdown 置于 followCheckbox 正下方);②自动救人(rescueCheckbox)锚点由 followCheckbox BOTTOMLEFT 改为调试模式 checkbox BOTTOMLEFT,让出顶部位置,使左区顺序变为:调试→救人→倒数偷药→偷药时间滑块→爆发总闸→开关提示→图标缩放→窗口透明度→自动跟随→跟随目标;③跟随下拉框由"右侧并列(followLabel RIGHT)"改回"跟随复选框下方(BOTTOMLEFT)",宽度由 GLOBAL_REGION_W-...-64 加宽到 GLOBAL_REGION_W-...-4 占满左区;④修复偷药时间滑块数值越界:WR_TouyaoSlider 宽度 GLOBAL_REGION_W-GLOBAL_INNER_PAD*2-4(170) 加上 RIGHT+6 的数值文字超出左区可用宽(174),改为预留 -30 宽并把数值文字贴右边距 +4,使"Ns"整体落在左区框内(图标缩放/窗口透明度滑块本就预留 -44 不越界)。/reload 即可生效。

-- === 主面板左右分区布局七次修复（2026-8-16 对齐微调）===
主面板(Core/UI_Config.lua):①左区对齐修正:自动救人、倒数偷药、爆发总闸、开关提示的锚点由跟随目标下拉框改为跟随复选框,与左侧复选框纵向左对齐;修复图标缩放/透明度滑块因在开关提示复选框之前创建并引用其锚点导致的布局失败,将开关提示复选框移到爆发总闸之后、滑块之前,确保锚点存在。②右区对齐统一:新增常量 MENU_LABEL_W=80,CreateDropdownMenu 与 CreateMenuSlider 的标签固定宽度左对齐,下拉框/滑块控件右边缘与父框右边缘对齐,数值文字移至滑块内部右侧,保证所有下拉框与阈值条左右两侧均对齐;WCL 模式删除手动 ClearAllPoints,改用标准左对齐,与职业下拉风格一致。③WR_LayoutConfigFrame 中 dmMaxW 改为 rightW - MENU_LABEL_W - GLOBAL_INNER_PAD*3,并同步更新全局 WCL 下拉宽度,确保右区所有下拉框等宽。尺寸重置标记保持 _UI_Config_Resized_2026_08_16_03 不变,/reload 即可生效。

-- === 主面板左右分区布局九次修复（2026-8-16 功能设置按钮点击被挡）===
主面板(Core/UI_Config.lua):功能设置入口按钮 featureBtn 原锚定 WR_ConfigFrame 右上角 TOPRIGHT(-5,-62),其下半截(y<-64)落入右侧职业区菜单区 WR_ClassMenuRegion(从-64 开始向下)的 EnableMouse 覆盖范围,且右区下拉框/天赋面板因模板及显式 FrameLevel 加成绘制在上层,导致点击命中不到功能设置按钮(用户反馈"鲜血天赋那片挡住功能设置")。修复:将 featureBtn 上移到顶栏内与重置按钮并排(锚定 WR_ConfigFrame TOPRIGHT(-76,-35),宽80,与重置按钮(-5,-35,宽65)水平相邻、间距6),完全脱离右区菜单区覆盖区,确保可正常点击。/reload 即可生效。

-- === 主面板左右分区布局八次修复（2026-8-16 WCL下压与下拉定位）===
主面板(Core/UI_Config.lua):①WCL 模式下拉由天赋标题行内下移到标题下方第一行(row=2,父框直接为 classMenuRegion,移除 1x1 辅助锚点框 wclRowAnchor),职业下拉模块仍从标题下方第二行开始(-MENU_TITLE_H-MENU_ROW_H),使 WCL 与防 ADD 间距紧凑;②CreateDropdownMenu 重构:区分"打开时初始化函数(InitializeDropdown)"与"外部刷新显示函数(RefreshDisplay)",创建阶段仅注册 initialize 不再立即调用 UIDropDownMenu_Initialize,避免创建时向当前打开的全局 DropDownList 追加错误按钮导致列表内容混乱;③align="left" 时下拉框改为左接标签、右对齐父框右侧,杜绝因父框 1x1 尺寸导致的漂移;④下拉弹出锚点保持锚定下拉框自身左下角,覆盖按钮点击先 CloseDropDownMenus() 再打开,防止多下拉同时展开。尺寸重置标记保持 _UI_Config_Resized_2026_08_16_03 不变,/reload 即可生效。

-- === 主面板左右分区布局十一次修复（2026-8-16 焦点下拉框越界 + 全局标题右对齐）===
主面板(Core/UI_Config.lua):①修复「跟随目标」下拉框(WR_FollowDropdown,用户称"焦点下拉框")超出左框架到右边的越界:根因是 UIDropDownMenu_SetWidth 会在传入宽度基础上额外叠加约 25px 按钮内边距作为整个下拉框(frame)的实际宽度,此前传入 GLOBAL_REGION_W-GLOBAL_INNER_PAD*2-4(174)使得可见框宽约 199px 远超左区 190px;改为传入 GLOBAL_REGION_W-GLOBAL_INNER_PAD*2-28(150),最终框宽约 175px 稳稳落在左框架内,并保持 TOPLEFT 锚定跟随复选框下方(左对齐)。②左框架标题"全局"改为在左框架内右对齐显示:保留其拓扑锚点(TOPLEFT 于 globalRegion 内边距)不变以避免下方控件整体右移,新增 SetWidth(内宽) + SetJustifyH("RIGHT"),使文字贴右排列。③后续截图反馈下拉框可见左边缘仍与"跟随"复选框左边缘有偏差,追加 x 偏移 -16 以抵消 UIDropDownMenuTemplate 左侧装饰边框内边距,使下拉框可见区域真正与复选框左对齐。④按用户要求将左侧全局区所有文字标签(调试模式/跟随/自动救人/倒数偷药/偷药时间/爆发总闸/开关提示/图标大小缩放/窗口透明度及其滑块数值/全局标题)字号由 12(标题 13)统一改为 STANDARD_TEXT_FONT 14,与「焦点」下拉框显示文字(ApplyDropdownDisplayText 中设为 14)等大;右侧职业区文字未动。尺寸重置标记保持 _UI_Config_Resized_2026_08_16_03 不变,/reload 即可生效。

-- === 主面板左右分区布局十二次修复（2026-8-16 复选框统一尺寸 + 焦点下拉贴紧跟随 + 开关提示拉开图标缩放）===
主面板(Core/UI_Config.lua):①左侧 6 个复选框尺寸统一为 24x24:此前「调试模式」(WR_TestCheckbox)与「跟随」(WR_FollowCheckbox)沿用 UICheckButtonTemplate 默认 26x26,而「自动救人/倒数偷药/爆发总闸/开关提示」显式 SetSize(24,24) 导致框子大小不一;现为调试模式与跟随补加 SetSize(24,24),全部对齐。②焦点下拉框(跟随目标)与「跟随」复选框垂直距离拉近:锚点 y 偏移由 -GLOBAL_ROW_H+6(≈18px)改为 -10px(初始化与底部重定位两处同步修改)。③「开关提示」与「图标大小缩放」垂直间距加大:图标缩放滑块锚点由 noticeCheckbox 下方 -GLOBAL_ROW_H+4(≈20px)改为 -GLOBAL_ROW_H-8(≈32px),二者拉开更远;同步将左区内容高度 leftContentH 由 24+10*GLOBAL_ROW_H+8 改为 +12 以容纳新增间距,避免框架裁剪。尺寸重置标记保持 _UI_Config_Resized_2026_08_16_03 不变,/reload 即可生效。

【分类】2026-8-15

-- === 职业修复补录（O16~O22 + 冰DK天赋加强 + 兽王闪烁，2026-8-15）===
痛苦术 腐蚀术 DoT 快照真实评分(Warlock_Affliction.lua + Warlock_Corruption_Refresh.lua):删除硬编码 currentWeight=1,改用 WR_CalcCorruptionWeight() 基于真实法强/暴击/伤害修正/低血量增伤(有泰坦能量×1.5)评分;腐蚀术 AURA 日志同步记录真实权重,使快照比较真正生效,修复"腐蚀快照比较永远返回 true"。

毁灭术 斩杀快照常量复核(Warlock_DrainSoul_Calc.lua):删除顶部写死 drainSoulModifier=4/baseDS=840,改为运行时读取 PigSet.SS_DS_Modifier/SS_DS_Base(默认回退 4/840),用户可按本服数值 /run 调整。

毁灭术 燃烧改为转好就放(Warlock_Destruction.lua):新增 WR_SS_HM_RS_Ready()(仅判断燃烧CD与射程,不再耦合目标献祭;3.1+ 燃烧不再消耗献祭),主循环由 WR_SS_HM_RS() 改为调用之;原函数保留供兼容。

冰DK 符文打击守卫统一(DeathKnight_Frost.lua + DeathKnight_Unholy.lua):WR_DK_BDK_FWDJ/WR_DK_XDK_FWDJ 由 `fwdj and NENGLIANG>=60` 改为 `fwdj==false and ...`,与血DK语义一致,修复冰/邪几乎永不触发符文打击。

冰DK 疾病维持主动续(DeathKnight_Frost.lua):WR_DK_BDK_BLCM 冰霜疫病 `==0` 改 `<3`,与传染逻辑续病阈值风格一致,避免断档损失湮没/凛风增益。

冰DK 适配时光服天赋加强(寒冰余波/死从天降,DeathKnight_Frost.lua):新增 WR_DK_BDK_HasColdAftershock()/HasDeathFromAbove()/SCTJ_InRange()/SaveRPForSCTJ();三个冰霜打击函数加 SaveRPForSCTJ 守卫(死从天降窗口内保留符文能量不泄);死从天降插入 WR_DK_BDK_SCTJ 加天赋闸门+资源/护盾判定,放宽原铜墙铁壁硬限制。spellID 不匹配时自动退化为保守分支,安全。

兽王猎 面板复选框闪烁修复(Hunter_Menu.lua):奥术射击总闸 LR_SWL_ASSJ 与焦点误导 LR_SWL_WD_FOCUS 原同处第5行第3列坐标冲突导致两框抢位闪烁;LR_SWL_ASSJ 移至第8行第3列,全量扫描确认无其它坐标冲突。需游戏内 /reload 生效。

-- === O01 惩戒骑十字军打击优先于审判（对齐 CS>J 标准）===
惩戒骑 Retribution 主循环(105-155行)将十字军打击(SZJDJ)提到审判(SP)之前:
  优先: WR_PaladinRetribution_SZJDJ("三谛圣契") 移到 WR_PaladinRetribution_SP("优先") 之前;
  填充: WR_PaladinRetribution_SZJDJ("填充") 移到 WR_PaladinRetribution_SP("填充") 之前。
保持奉献/愤怒之锤/神圣风暴/CD技能在CS、J之前不变,仅调整CS与J的先后。符合WotLK 3.3.5标准循环(CS>J),提升十字军命中率与GCD利用率。

-- === O04 奶骑神圣恳求改为空档+蓝阈值触发（Liu 资源引擎）===
奶骑 Holy 新增 WR_PaladinHoly_HealUrgent() 治疗紧迫判定:
  正在读条/焦点<50%血/自身或任意团队成员<30%血 时认为治疗紧迫,不允许裸放恳求。
WR_PaladinHoly_SSKQ() 增加 not WR_PaladinHoly_HealUrgent() 守卫,仅在非紧迫且蓝低于设置阈值时才恳求(建议设置60%)。
WR_PaladinHoly_QS_Cycle_Check() 三轮循环恳求的蓝量阈值由 0.75 下调为 0.6,并增加同样守卫。
避免恳求打断治疗节奏,蓝量续航更平滑;爆发窗口仍配合神启/翅膀/饰品/手套预开(原有BF逻辑不变)。

-- === 全职业焦点施法屏蔽火女（双子战）===
所有DPS/坦克专精的"设焦点打"逻辑新增:焦点=火女(高阶术士奥蕾塞丝)时跳过该焦点施法。
覆盖:痛苦术(焦点痛苦无常/焦点腐蚀术/焦点痛苦诅咒)、毁灭术(焦点献祭)、火法(焦点活动炸弹)、
猎人三系(焦点奥术射击·动力炸弹/焦点杀戮射击/焦点毒蛇钉刺)、暗牧(焦点吸血鬼之触/焦点暗言术：痛/焦点精神鞭笞)、
狂怒战(焦点破甲)。与恶魔术 WR_SS_EM_FSS 焦点分支屏蔽火女逻辑完全一致。
(治疗专精焦点治疗、焦点打断脚踢/拳击/心灵冰冻/盾击、焦点控制放逐 不在此列,避免双子战无法打断火女读条)

-- === TIAN 高优先级整改（#6~#12，2026-8-15）===
冰法(Mage_Frost.lua) 召唤水元素智能(WR_BF_ZHSYS):战斗中无宠物/宠物已死且冰冷血脉爆发期/永恒之水雕文常驻时,自动提示召唤水元素(槽位103);受 PigSet.BF_BLXM 控制,蓝胖/镜像等场合不误召。

猎人 三系独立自动饰品总闸(Hunter 三系 + Menu):兽王 LR_SWL_ZDSP / 射击 LR_SJL_ZDSP / 生存 LR_SCL_ZDSP 各自独立自动饰品开关(原共用逻辑拆分),爆发/斩杀/DBM倒数触发,默认开;UI_CommandList.lua 三系各自命令。

冰DK 锁红脸(自动冰霜灵气 WR_DK_BDK_ZDBSLQ):三种灵气均未激活时自动切回冰霜灵气(槽位9),避免误切血/邪脸损失符文能量;默认开。
DKT 蓝脸(自动冰霜灵气 WR_DK_Blood_ZDBHLQ):鲜血DK坦克(DKT)模式下,只要当前不是冰霜灵气(开红脸/绿脸/未开均触发)即提示切回冰霜灵气(槽位201,蓝脸);与冰DK红脸不同,不要求"三种都未激活"(否则血DK常开红脸导致永不触发)。手动切换按 SHIFT-F10 冰霜灵气宏(原空槽50,不新增键位)。默认开。
冰DK 黑锋冰寒(WR_DK_BDK_HFCH):新天赋瞬发2分钟CD,爆发/杀戮机器时提示施放(槽位10),使下次冰触/凛风/冰打/湮没必爆;默认开。

惩戒骑 衣服使用加力量(Paladin_Retribution.lua + Menu,CJ_YF):爆发期/目标将死/DBM倒数(≤3s)窗口内,检测胸甲(slot5)"使用:力量"效果就绪(WR_GetEquipCD)且十字军打击在射程,提示按下胸甲"使用"按键(槽位195);默认关。
(注:项目物品"使用"均为提示机制,玩家自绑按键,不自动 UseInventoryItem)

药水文案统一(12文件):Shaman_Elemental/Enhancement、Warlock_Affliction/Demonology/Destruction、Rogue_Subtlety/Assassination/Combat、Priest_Shadow、Mage_Arcane/Fire/Frost 共12个自动药水函数,slot183 的"自动速度药水"显示文案统一为"速度药水"(与单函数职业对齐);保留"插入速度药水"(不同概念)。命令说明/注释语境未动。

戒律牧 神圣赞美诗 + 焦点补盾(Priest_Discipline.lua + Menu):
  新增 WR_PriestDisCipline_SMZS():团血≤50%且团≥4人(raid)或≥2人(party)时,静止/非施法中提示神圣赞美诗(槽位196,JL_SMZS,默认关),团刷救场;
  新增 WR_PriestDisCipline_ZYSD("焦点")分支:焦点存在/存活/非敌对/40码内且无盾(非虚弱灵魂)时补真言术：盾(JL_JDSD,默认关),复用原 Unit_ZYSD 单体内核。

-- === TIAN 补充整改（兽王猎奥术开关 / 戒律插入神歌蓝歌 / 武器战强化缴械，2026-8-15）===
兽王猎 奥术射击总闸(Hunter_BeastMastery.lua + Menu + 命令):WR_LR_SWL_ASSJ() 加 PigSet.LR_SWL_ASSJ 闸门(原无条件常开),菜单行5列3复选框(默认开),/LR_SWL_ASSJ 由通用机制自动生成;保持原有槽位17提示。

戒律牧 插入神圣赞美诗 + 插入希望圣歌(Priest_Discipline.lua + Menu + 命令):新增 WR_PriestDisCipline_CRSSZMS()(JL_CRSSZMS,槽位197)与 WR_PriestDisCipline_CRXWSG()(JL_CRXWSG,槽位198),释放后自动关开关(照暗牧 MS_AY_CRSSZMS/CRXWSG 模式);主循环7.6段接入。原 JL_SMZS 团血低自动团刷保留为独立开关(自动版+插入版并存)。

武器战/防战 自动缴械细化(Warrior_Arms.lua + Warrior_Protection.lua):
  武器战 WR_WQZ_JF 已按 zidongbaofa(爆发列表目标)触发;防战 WR_WARRIOR_FZ_JF 已按爆发/斩杀期触发;
  二者均新增 WR_Warrior_HasImprovedDisarm() 检测"强化缴械"天赋(SpellID 12313, 同时 fallback 按中文名),未点该天赋时不自动缴械(检测不到时放行,需在游戏内验证)。

-- === TIAN Top5 整改（#24~#29，2026-8-15）===
毁灭术 未命中/施放失败 回退印记(Warlock_Destruction.lua):战斗日志新增 SPELL_CAST_FAILED 与 SPELL_MISSED 回退逻辑(参照 ZZ 同名修复,并扩展 MISSED 覆盖真正未命中),对 暗影箭/烧尽/混乱之箭/献祭 的 HM_AYYJ/HM_YJYJ/SJCS 计数回退并夹紧≥0。修复"技能未命中后印记层数仍增加"。

戒律牧 坦克盾独立开关(Priest_Discipline.lua + Menu + 命令):主循环14段"坦克"分支加 PigSet.JL_TKZD 闸门;关闭后不覆盖坦克(常规盾逻辑本就排除坦克)。新增复选框(行5列5,默认开)与 /JL_TKZD。

惩戒骑 工程手套独立开关(Paladin_Retribution.lua + Menu + 命令):WR_PaladinRetribution_ST() 改为受 PigSet.CJ_GCST 控制(默认开),不再依赖 CJ_BF(复仇之怒);CJ_BF 提示文案同步去掉"手套"。新增复选框(行7列3)与 /CJ_GCST。

野德 工程手套独立开关(Druid_Feral.lua + Menu + 命令):WR_DruidFeral_ST() 加 PigSet.YD_GCST 闸门(默认开)。新增复选框(行4列2)与 /YD_GCST。

毁灭术 预判循环(循环)开关暴露到菜单(Warlock_Menu.lua + 命令):底层 SS_HM_TEXT 早已存在(控制烧尽按爆燃/余烬预判填充),此前未在菜单暴露且无默认值;新增复选框(行5列1,默认开=预判循环)与 /SS_HM_TEXT。关闭后暗影箭补到4层、暗影灼烧期间补到6层再烧尽填充。

冰DK 锁红脸修正为鲜血灵气(DeathKnight_Frost.lua + Menu):WR_DK_BDK_ZDBSLQ() 由冰霜灵气改为鲜血灵气(用户确认红脸=鲜血灵气);菜单提示文案同步。槽位9。

冰法 召唤水元素新增祖尔金P3(山猫/lynx,血量40%~60%)阶段除外(Mage_Frost.lua):新增 WR_BF_ZHSYS_ZuljinP3() 检测当前目标/Boss单位为祖尔金且血量落在40%~60%(山猫阶段),WR_BF_ZHSYS() 顶部加该守卫,该阶段不召唤且不补召唤水元素(覆盖智能召唤/冰冷血脉爆发/永恒之水雕文三分支)。【修正】原35%~50%按用户设定更正为40%~60%。

-- === 更新日志8条整改（治疗自动救人 / 邪DK白骨之盾DBM门槛 / 邪DK宝宝跟随 / 猎人宝宝三模式 / 术士武器石 / 全职业偷药时间，2026-8-15）===
法师 脱战自动制造法力宝石(奥法 Mage_Arcane.lua):脱战自动制造并装备法力宝石(WR_AF_ZDFL 等)早已实现,本期确认覆盖,无需改动。

暗牧 渊(噬灵疫病)接灭提前落地修复(Priest_Shadow.lua):上一轮已在灭的相关函数顶部加"噬灵疫病读条中/GCD内"守卫,避免渊接噬灵疫病后紧接灭导致提前落地;本期确认覆盖。

治疗职业 自动救人开关(5治疗专精 + ZZ_Features_Migration.lua + UI_CommandList.lua):新增全局开关 ZL_ZDJS(默认开),戒律牧 WR_PriestDisCipline_FHS / 神圣牧 WR_PriestHoly_FHS / 奶骑 WR_PaladinHoly_JS / 奶萨 WR_ShamanRestoration_XZZH / 奶德 WR_DruidRestoration_QSHS 五处复活函数首行加 `if PigSet.ZL_ZDJS == false then return false end`;五治疗专精命令清单各加 ZL_ZDJS,通用设置面板 Iconid_F008 加"治疗职业自动救人"复选框。

邪DK 白骨之盾 DBM倒数10秒内不自动(DeathKnight_Unholy.lua):四个白骨之盾分支(WR_DK_XDK_BGZD_ZD / _ZD_DLB / _TZ / _NEW)顶部统一加 `local dbmCountdown = WR_GetDBMCountdown_XDK(); if dbmCountdown and dbmCountdown > 0 and dbmCountdown <= 10 then return false end`,开怪前10秒倒数内不自动白骨之盾。

邪DK 宝宝攻击优化(切目标跟随,DeathKnight_Unholy.lua):WR_DK_XDK_KZBBGJ() 攻击条件新增 `(not UnitExists("pettarget") or not UnitIsUnit("pettarget","target")) and`,玩家切换目标时食尸鬼跟随攻击新目标。

猎人 宝宝攻击三模式(跟随/不跟随/不控制,Hunter_Menu.lua + 三系 lua + UI_CommandList.lua):LR_SWL_KZBB / LR_SJL_KZBB / LR_SCL_KZBB 由复选框布尔值迁移为下拉数字(1=跟随/2=不跟随/3=不控制),ZZ_Features_Migration 加迁移;三系菜单移除原"攻击"复选框改加"宝宝模式"下拉;宝宝攻击函数条件 `==true` 改 `~=3`(不控制模式不提示),宝宝跟随函数条件改 `==1`(仅跟随模式召回)。【修正】用户反馈选"不跟随"宠物仍追怪。根因：攻击函数用 `/petattack`(槽21),而 `/petattack` 本身会让宠物追怪/跟随目标;原条件 `~=3` 使模式1+2都攻击,故"不跟随"(模式2)照样追怪。现把三系攻击函数(含兽王撕咬)条件由 `~=3` 改为 `==1`,仅"跟随"(模式1)自动攻击+追怪,"不跟随/不控制"均不自动攻击(宠物被动待命、不追怪);菜单 tooltip 同步更正"不跟随=不自动攻击不追怪"。【修正2】用户二次反馈：要求三模式清晰区分(跟随/不跟随/不控制)。现改：攻击函数条件保持 `==1`(仅跟随自动攻击);三系召回函数 WR_LR_xxx_KZBBGS 新增模式切换检测——切到不控制(3)时发 `/petstay`(槽89,猎人宏新增,此前槽43被速度药水占用故用空闲89),宠物原地待命完全手动;切到跟随/不跟随(1/2)时发 `/petfollow`(槽42)召回跟主人;不跟随(2)=黏主人但不自动攻击(从战斗中切回会召回),不控制(3)=原地(切模式瞬间定一次位,之后不干预,玩家可手动 /petattack)。

术士 三系武器石选择并自动主手附魔(Warlock_Menu.lua + 三系 lua + ZZ_Features_Migration.lua + UI_CommandList.lua):WL_AFL_ZDFSS(痛苦)/WL_EM_ZDFSS(恶魔学识)/SS_HM_HRS(毁灭) 由复选框迁移为"武器石"下拉(1=关闭/2=法术石[副手]/3=火焰石[主手]),ZZ_Features_Migration 加迁移与 CoreDefaults;三系 WR_WL_AFL_FSS / WR_WL_EM_FSS / WR_SS_HM_HRS 改造为按所选石种制造并附魔(火焰石自动附魔主手,法术石附魔副手),无则自动制造;三系命令清单加对应【下拉】条目。【修正】原法术石宏(id 80)误写为 `/use 16`(主手),导致法术石/火焰石都附主手;现改为 `/use 17`(副手),火焰石宏(id 194 `/use 完美火焰石`)默认主手,符合"法术石→副手、火焰石→主手"。

全职业 偷药时间 0-3 秒可调(ZZ_Features_Migration.lua + 30个职业文件):新增全局配置 TOUYAO_TIME(默认3,滑条0-3,通用设置面板 Iconid_F008),新增 WR_PrepullInWindow(dbmCountdown) 统一判定 DBM 倒数是否落在预开窗口;所有职业"偷药/爆发预开"处的硬编码 `dbmCountdown > 0 and dbmCountdown <= 3` 全部替换为 WR_PrepullInWindow(dbmCountdown),使全职业偷药/爆发预开窗口在 0-3 秒内可调(0=仅战斗中触发)。

-- === TIAN 毁灭术补充整改（#1② / #4 / #8 / #12，2026-8-15）===
毁灭术 脱战/切目标/目标死亡清除烧尽次数SJCS(Warlock_Destruction.lua):TIAN #4 要求切换目标/目标死亡/脱离战斗后清除上一轮遗留的烧尽次数;在 PLAYER_TARGET_CHANGED/PLAYER_STARTED_MOVING/PLAYER_STOPPED_MOVING 与 UNIT_DIED/UNIT_DESTROYED 分支补 SJCS=0,并新增注册 PLAYER_REGEN_ENABLED 事件在脱战时清空 HM_YJYJ/HM_AYYJ/SJCS(ZZ 同缺口,两端此前均未清 SJCS)。

毁灭术 关闭循环+暗影印记≤2 自动暗影之怒(Warlock_Destruction.lua):TIAN #8 在 WR_SS_HM_AYZN() 增加分支——当 PigSet.SS_HM_TEXT(循环)关闭且 HM_AYYJ<=2 时自动暗影之怒;原"双燃烧轮"(混沌流星后燃烧CD>5)逻辑保留。顺手修正插入/自动暗影之怒提示文案误写为"插入饰品"的 bug。

毁灭术 献祭读条期间燃烧转好短暂提示(Warlock_Destruction.lua):TIAN #1② 新增 WR_SS_HM_XJ_RS_TIP(),玩家正在施放"献祭"且燃烧可用、目标已有献祭时提示"燃烧好了"(帧199);主循环每帧刷新提示,条件不满足即不再提示,实现"超时恢复"。

毁灭术 1+1 必爆献祭测试开关(Warlock_Destruction.lua + Menu + 命令):TIAN #12 新增 SS_HM_TEST_11(默认关),开启后 WR_SS_HM_XJ() 强制打献祭、配套燃烧(RS_Ready)连打成 1+1,仅用于测试循环;新增复选框(行10列2)与 /SS_HM_TEST_11。

焦点跟随提示广播到聊天窗口(MainLoop.lua + UI_Config.lua):焦点跟随的"设置焦点(色块116)""焦点跟随(色块117)"原仅以屏幕色块提示,现与复选框切换提示一致——通过 UI_Config.lua 新增的全局 WR_PrintToVisible(尊重 ChatNoticeMode:0关/1默认窗口/2所有可见窗口)广播到所有可见聊天窗口;WR_AutoFollow() 的 party/focus 分支与 WR_SetFocusFromTarget() 各加带 5 秒节流的提示,避免每帧刷屏。目标跟随(色块115)保持仅色块,不在本次范围。
自动跟随开关提示也广播到所有可见窗口(MainLoop.lua):WR_ToggleAutoFollow()/WR_SetAutoFollow() 原用 print() 仅输出默认聊天框,现改为 WR_PrintToVisible(),通过 /run WR_ToggleAutoFollow()、WR_SetAutoFollow(true/false) 或快捷命令切换时,"自动跟随已开启/已关闭"也像复选框一样在所有可见聊天窗口可见(菜单复选框点击本就走 PrintToVisible,无需改)。

血DK 血液沸腾/枯萎凋零的AOE模式与单拉模式智能AOE门槛拆分(DeathKnight_Blood.lua + Menu):移除 WR_DK_Blood_XYFT_NEW/XYFT_QZ/XYFT/KWDL 内部的 PigSet.DK_Blood_KWDL(智能AOE)门槛,改为在调用处按模式区分——AOE模式(WR_DK_Blood_AOE_Mode)调用处不再判断,血液沸腾/枯萎凋零不受智能AOE复选框影响、始终尝试(仍受符文与2+目标约束);单拉模式(WR_DK_Blood_Single_Mode)调用处保留 DK_Blood_KWDL 门槛,仍受智能AOE控制;输出模式(伤害最大化)的 XYFT_NEW 调用处补回 DK_Blood_KWDL 门槛以维持原行为。菜单"输出循环模式"提示文案同步更新。

武器战与狂暴战优化(Warrior_Arms.lua + Warrior_Fury.lua + Warrior_Menu.lua):
O11 英勇/顺劈加平砍门控:Arms 的 WR_WQZ_YYDJ()/WR_WQZ_SPZ() 新增 (NextMainHandTime==0 or NextMainHandTime<0.3) 门控,仅在主手平砍剩余<0.3s 或无计时信息时才排队英勇/顺劈;Fury 的 WR_KBZ_YYDJ()/WR_KBZ_SPZ() 把原有 NextMainHandTime>0.2 改为同一 late-queue 策略,避免早排队吃怒挤 GCD,对齐 Naizui/ZZ 平砍捆绑思路。
O12 武器战致死/压制顺序对调:Arms 核心输出段把 WR_WQZ_ZSDJ() 提到 WR_WQZ_YZ() 之前,使致死打击优先于压制,对齐 ZZ 标准与 WotLK APL 共识。
O13 利刃风暴默认进循环:Warrior_Menu.lua 中 Arms 的 WQZ_DFC(自动大风车)复选框 defaultState 从 false 改为 true,使利刃风暴默认自动在低怒期/合适窗口释放。
O14 狂暴战斩杀阈值下调:WR_KBZ_ZS() 的怒气门槛从 NUQI>70 改为 NUQI>60,使斩杀期更早触发,与 Arms/Naizui 对齐。
O15 剔除狂暴战战斗姿态压制死代码:Fury 主循环删除 WR_KBZ_YZ() 调用(Fury 常驻狂暴姿态 zitai==3,而压制仅能在战斗姿态 zitai==1 使用,永不触发),并删除该函数体。

血DK 传染与AOE模式疾病保持修复(DeathKnight_Blood.lua):
① 传染扩散门槛:WR_DK_Blood_CR() 与 WR_DK_Blood_AOECR() 的 isForSpread(扩散)分支新增 WR_DK_Blood_TargetDiseaseFresh() 门槛(目标双疾病冰霜疫病/血之疫病剩余均≥7.5秒才算新鲜),仅当目标疾病新鲜时才传染扩散,修复"目标疾病剩6秒甚至更高时就传染、把过期/短病程复制给周围小怪"的问题(无疾病雕文时传染仅复制当前剩余时间)。AOECR 的 isForRefresh 同步补上 WR_IsUsingGlyph("疾病雕文") 要求,与 CR 一致,避免无雕文时空传染续命。
② AOE模式提前补疾病:新增 WR_DK_Blood_AOE_DiseaseKeep()(AOE时目标双疾病剩余<7.5秒即补冰冷触摸/暗影打击,比默认<3秒更积极),并在 WR_DK_Blood_AOE_Mode() 中把"保持目标双疾病"步骤移到传染之前,实现"周围小怪没双疾病时先多打几个冰触/暗影打击、再传染扩散",保证扩散出去的是满/近满持续时间疾病。

奥法 O27 4层+强化死锁边界(Mage_Arcane.lua):
修改 WR_AF_ASFD/WR_AF_ASDM 中"奥术强化期间延迟消层"的飞弹速射阈值:ASFD 由 >1.5s 收紧为 >0.5s,ASDM 由"强化期间绝对不打"改为"强化且速射仍>0.5s才不打"。修复 4层+奥术强化+飞弹速射>1.5s 时飞弹/弹幕/冲击三技能互斥死锁导致无技能可放的隐患,让速射接近结束时强制消层。

奥法 O29 低蓝自动唤醒(Mage_Arcane.lua + Mage_Menu.lua + UI_CommandList.lua):
新增 WR_AF_ZDHX() 自动唤醒分支(蓝<25%、战斗中、非奥术强化爆发期、目标存活>8秒、未移动时提示唤醒,槽位18);新增菜单复选框 AF_ZDHX(行5列3,默认关);命令清单加 /AF_ZDHX。补充原有仅宝石补蓝的法力管理体系,低蓝且宝石不足/CD时可自动唤醒续航。

暗牧 O32 斩杀段灭处理补强(Priest_Shadow.lua + Priest_Menu.lua + UI_CommandList.lua):
新增「死神慈悲优先灭」分支(PigSet.MS_AY_MIE_CS_PRI,默认关):当玩家身上死神慈悲剩余<2s且目标死亡时间<3s时,优先提示暗言术:灭(槽位87),避免高层死神慈悲在斩杀期过期浪费。
新增「卡CD灭」分支(PigSet.MS_AY_MIE_CD,默认关):开关开启时只要暗言术:灭可用就提示(槽位41),不依赖斩杀阈值与血量,用于最大化斩杀期DPS(注意会反伤自身)。
新增菜单复选框(行8列3/4)与命令 /MS_AY_MIE_CS_PRI、/MS_AY_MIE_CD。

【时光服】2026-8-12

-- === 阶段三·8/12 合并实现（B更新日志缺口精准构建）===
防战 新增自动缴械(仅人型/野兽,爆发或斩杀期择机释放) 开关FZ_JF 默认关
武器战 新增自动缴械/强化缴械(仅人型/野兽,爆发或斩杀期择机释放) 开关WQZ_JF 默认关
暗牧 新增T9暗影布甲2件套检测 WR_MS_AY_T9_2PC(返回是否拥有2件套,供加速阈值优化引用;默认不强制改变输出)
命令 UI_CommandList.lua:防战新增/FZ_JF 武器战新增/WQZ_JF

-- === 防战 狂暴之怒解恐惧 对齐官方PigToGo 7.16版 ===
防战 狂暴之怒解除恐惧(WR_FZ_KBZN,开关FZ_KBZN)经核对官方PigToGo 7.16版:官方主循环在碎裂投掷之后/惩戒痛击之前即调用WR_FZ_KBZN()(非"最高优先级"),而本插件主循环此前缺失该调用(仅复仇循环WR_WARRIOR_FZ_RevengeCycle行首有),导致主循环路径下中恐惧不弹框不解.已补回主循环插入段调用(碎裂投掷WR_FZ_CRSLTZ之后,惩戒痛击WR_FZ_CJTJ_CR之前),与官方位置一致;并撤销先前误提至自动攻击之后的5.5段调用.函数体/宏(CTRL-NUMPAD1=/CAST 狂暴之怒)/菜单开关均与官方相同,解恐惧依赖提示框+手动按CTRL-NUMPAD1(插件不自动施法)
★ 2026-8-24 增强:WR_FZ_KBZN 在官方7个恐惧译名(心灵尖啸/煽动惊恐/恐吓/破胆怒吼/恐惧/低沉咆哮/恐慌)基础上,新增泰坦服兜底——直接扫描player的HARMFUL debuff缓存,凡名字含[恐惧/恐慌/尖啸/惊骇/嚎/恐吓/破胆/恐]任一关键词即弹框.覆盖官方未列出的副本特定恐惧译名变体(如恐怖嚎叫/暗影恐惧/心灵惊骇等),解决"中恐惧不提示"问题

-- === 宠物小吃复选框新增（猎人三系 + 术士痛苦/毁灭）===
猎人 三系(兽王/射击/生存)新增宠物小吃复选框 LR_SWL_XLMMXC / LR_SJL_XLMMXC / LR_SCL_XLMMXC 默认关(原无条件执行,现受开关控制)
术士 痛苦新增宠物小吃复选框 SS_TK_XLMMXC 默认关
术士 毁灭新增宠物小吃复选框 SS_HM_XLMMXC 默认关(原与恶魔学识共用同名WR_EM_XLMMXC,现独立改名WR_HM_XLMMXC消除重名隐患)
命令 UI_CommandList.lua:猎人三系 + 术士痛苦/毁灭 各加 /xx_XLMMXC

-- === 恶魔术新增插入火焰之雨 ===
恶魔术 新增插入火焰之雨复选框 SS_EM_CRHYZY 默认关(照毁灭模式:可用时提示施放,战斗日志施放后自动关闭;火焰之雨无冷却故不能靠GCD判定关闭)
命令 UI_CommandList.lua:恶魔区加 /SS_EM_CRHYZY

-- === 恶魔术新增无脑火焰之雨 ===
恶魔术 新增无脑火焰之雨复选框 SS_EM_WBHYZY 默认关(开关常开,循环中火焰之雨可用且未在引导时即通过宏76自动施放,不自动关闭;与插入火焰之雨SS_EM_CRHYZY互斥使用)
命令 UI_CommandList.lua:恶魔区加 /SS_EM_WBHYZY

-- === 怪物屏蔽总开关默认改为关闭 ===
怪物屏蔽总开关 MONSTER_BLOCK_ENABLED 默认值由 启用(true) 改为 关闭(false)(配置界面复选框"启用怪物屏蔽"默认不勾选;CoreDefaults 表与 checkbox defaultState 两处同步;点"恢复所有默认设置"亦保持关闭;需在功能设置面板手动勾选"启用怪物屏蔽"才生效)

-- === 术士脱战宠物(脱战自动召唤) 默认关闭、重置亦关闭 ===
术士三系"脱战宠物"下拉(脱战无宝宝时自动召唤指定宠物):痛苦 SS_TK_AUTOSUMMON defaultID=5(地狱猎犬) / 恶魔 SS_EM_AUTOSUMMON defaultID=6(恶魔卫士,2026-8-24由小鬼ID2改) / 毁灭 SS_HM_AUTOSUMMON defaultID=2(小鬼,2026-8-24由关闭ID1改,毁灭默认召唤小鬼).初始加载(PigSet为nil/非数字/越界时按defaultID播种,UI_Config.lua:522)与天赋"重置"按钮(UI_Config.lua:1055 强制 PigSet=defaultID)按各系defaultID生效;脱战无宝宝时按所选宠物自动召唤(恶魔学识默认恶魔卫士,毁灭默认小鬼)

-- === 修复：生存猎"无脑乱射"复选框变量名碰撞（误用兽王 LR_SW_WLS）===
生存猎(生存块 row5c5)"无脑乱射"复选框 saveVariable 原误写为兽王的 LR_SW_WLS(应为 LR_SCL_WLS):导致生存玩家勾该框无任何效果(生存主循环无 WR_LR_SCL_WLS 调用/函数),且会误改兽王开关.现修正为 LR_SCL_WLS,并补齐: Hunter_Survival.lua 主循环"插入乱射"后加 WR_LR_SCL_WLS() 调用(82行) + 新增函数 WR_LR_SCL_WLS()(602行,照兽王 WR_LR_SW_WLS 写法:战斗中可用且未在引导乱射即宏37施放,无脑不自动关); UI_CommandList.lua 生存块加 /LR_SCL_WLS(758行).兽王 LR_SW_WLS 保持独立不受影响

-- === 召唤恶魔卫士(SS_EM_CREMWS) 改为常开 ===
术士"召唤恶魔卫士"复选框 SS_EM_CREMWS 原是"插入型"(施放后战斗日志自动 off 关开关,痛苦 Warlock_Affliction.lua / 毁灭 Warlock_Destruction.lua 两处).现删除这两处自动 off,改为真正常开开关:开关保持勾选,仅恶魔卫士不存在/死亡时(WR_SS_EM_CREMWS 守卫)提示召唤,宠物存活不提示.消除跨专精(纯恶魔学识不自动关/痛苦毁灭自动关)不一致

-- === 阶段三·补充确认项(二)·中优先级实际取用项 ===
冰DK 寒冬号角补<30秒阈值(Frost/Blood照搬Unholy写法,仅号角buff剩余<30秒或已消失才补,避免满buff空转GCD)
惩戒骑 圣印下拉补为4项(CJ_SY新增4=光明圣印,蓝量≥751时治疗向切换;防护端FH_SY早已支持4=光明)
奥法 气定神闲自动衔接爆发 WR_AF_QDSX(复用AF_ASQH总闸;气定可用先铺垫,气定buff存在后打一气定奥冲)
恶魔术 嗜血自动恶魔变形bug重写(加嗜血/英勇闸门,避免非爆发期浪费变形;触发面较旧版更宽)

-- === 阶段三·第三步·高优先级6项提取增强 ===
冰DK 新天赋 铜墙铁壁(增伤)窗口内湮没/冰霜打击前移 WR_DK_BDK_YM_TQTB/WR_DK_BDK_BSDJ_TQTB(剥离MOP寒冰余波,以铜墙铁壁作窗口;纯增量前移)
治疗 自动驱散独立总开关(5个总闸,优先级高于各分项下拉,默认关): 戒律/JL_QS_AUTO 神圣/SS_QS_AUTO 神圣骑/SS_QJS_AUTO 恢复德萨/HF_QS_AUTO 恢复萨进攻/HF_JHQS_AUTO
战士 碎裂投掷切姿态(碎裂投掷需战斗姿态;武器战已修,狂暴战/防战按B安全模式重写 WR_KBZ_CRSLTZ/WR_FZ_CRSLTZ:切战斗→施放→切回主姿态→关开关)
BOSS识别增强 WR_UnitIsBoss(原首领框GUID匹配基础上补分类/负等级/UnitIsBoss/战斗兜底)

-- === 阶段三·第一步·BExt维度提取 ===
范围计数族 Core/AOE_Count.lua(替代原未定义函数,统一周边敌人计数)
战斗工具集 Core/Combat_Tools.lua(通用战斗工具函数族)
装备管理扩展 Core/Engineering_Check.lua + Core/Trinket_Monitor.lua(BExt装备/工程检测扩展,剥离B引擎)
怪物屏蔽接入 MainLoop Core/BLACKLIST.lua WR_IsBlacklisted 中枢统一拦截(优先级:白名单>BOSS豁免>怪物屏蔽>黑名单;19处职业调用点自动继承)

-- === 残留回采(阶段二)===
防骑 神圣之盾(优先)排除(正义之锤可用时不抢占,仅盾壁将断时优先补;贴近B仇恨优先语义)
猎人 自动假死 WR_LR_JSD_JSWD(BExt提取自B,三专精;仅目标为ICC灵魂戒卫且读条且目标target=player时假死脱仇保宠,无需开关)
术士 脱战召唤统一入口 Warlock/Warlock_OOC_Summon_BExt.lua(三系统一,替代原各自实现;沿用各系 AUTOSUMMON 开关)

【时光服】2026-8-7

-- === 自动爆发名单 + 职业循环补缺（对照时光服更新日志逐条核查）===
Burst_Whitelist.lua 太阳井高地5Boss(卡雷苟斯/布鲁塔卢斯/菲米丝/艾瑞达双子/穆鲁/基尔加丹)加入自动爆发名单
Burst_Whitelist.lua 祖阿曼6Boss(埃基尔松/纳洛拉克/加亚莱/哈尔拉兹/妖术领主玛拉卡斯/祖尔金)加入自动爆发名单
Burst_Whitelist.lua 基尔加丹门口小怪(基尔加丹之手/欺诈者之手)确认不加入自动爆发名单(按设计)
痛苦术士 新增脱战自动完美法术石(无则制造法术石,有则装备完美法术石) 开关WL_AFL_ZDFSS 默认开
毁灭术士 新增脱战自动完美火焰石(无则制造完美火焰石,有则附魔武器) 开关SS_HM_HRS 默认开（由普通火焰石升级为完美版）
毁灭术士 新增脱战无宝宝自动召唤小鬼 开关SS_HM_ZHXG 默认开
法师(三专精) 新增脱战法力青玉不足3个自动制造法力宝石 开关AF_ZDFS 默认开
戒律牧 新增群体驱散插入(光标位置,队友有魔法减益时点一下放一次) 开关JL_QTQS 默认开
冰DK 新增新天赋死从天降插入(爆发+铜墙铁壁期间+周围≥2怪时) 开关DK_BDK_SCTJ 默认开
冰DK 适配时光服冰DK天赋加强(寒冰余波/死从天降)：新增死从天降窗口内保留符文能量、不泄冰霜打击(WR_DK_BDK_SaveRPForSCTJ)，死从天降插入对齐ZZHELPER 20260812窗口协调(寒冰余波窗口初期攒资源)；HasColdAftershock/HasDeathFromAbove用IsPlayerSpell检测

-- === BUG修复 第一波7项高风险崩溃 ===
BUG修复 猎人AOE范围怪物计数调用未定义函数 → 改用已实现的 WR_CountNearbyEnemies
BUG修复 治疗权重单位吸收量函数未定义 → 新增 WR_GetHealAbsorbs(UnitGetTotalAbsorbs)
BUG修复 戒律牧/恢复萨坦克判定调用未定义函数 → 改用 WR_UnitIsGroupTank
BUG修复 火法停手函数未定义 → 新增 WR_Fire_KZ_STOP(复用奥法停手)
BUG修复 武僧模块未实现主循环调用崩溃 → 加函数存在守卫(模块缺失时跳过不崩)
BUG修复 法师/术士BOSS特化角色守卫缺失 → 补 WR_CheckRoleApplicable and 守卫
BUG修复 惩戒骑误定义同名切目标函数覆盖猎人 → 改名 WR_CJ_Tab 解除冲突

-- === BUG修复 第二波 中低风险（死分支/守卫/跨文件重复定义）===
BUG修复 Utils_HealerWeight 加拉克苏斯大王治疗优先级加权死分支(WR_JaraxxusFleshAnyoneActive未定义致整段逻辑不执行) → 新增该闸门函数恢复加权
BUG修复 猎人AOE DBM倒计时调用 WR_GetDBMCountdown_EM 加存在守卫 防极端加载顺序崩溃
BUG修复 WR_GetUnitLostHealth 旧实现覆盖Core高精度版(含吸收盾/ IncomingHeals) → 用 if not 守卫保留Core版
BUG修复 WR_ALL_QXGZ 增强萨空壳return false覆盖Utils真实取消灌注/专注逻辑(WCL模式失效) → 删除空壳恢复(影响德/牧/术多系)
BUG修复 毁灭术宠物小吃(WR_EM_XLMMXC)缺失PigSet.SS_EM_XLMMXC==false关闭守卫 → 补齐与恶魔术一致

【时光服】2026-8-6

-- === BossAI 模块化框架 P2 阶段完成 ===
BossAI 新增 AI_Perceptor.lua 感知器模块（340行）.4子传感器:职业识别/站位分析/技能探测/仇恨追踪
BossAI 感知器集成至 AIDriver 生命周期:EnterCombat初始化/每帧Update驱动/LeaveCombat清理
BossAI AI_BossConfig.lua 新增太阳井5Boss(卡雷苟斯/布鲁塔卢斯/艾瑞达双子/穆鲁/基尔加丹)+祖阿曼6Boss(鹰王/熊王/龙鹰王/豹王/妖术领主/祖金)共11个直配数据
BossAI AI_BossConfig.lua 修复 Lua5.1 兼容性:移除 goto continue 改用 if-elseif 嵌套
BossAI AI_DecisionEngine.lua 修复7处 Lua5.1 goto 语法错误.全部改为 if not skip then ... end 嵌套
BossAI AI_DecisionEngine.lua 升级3大函数:_IsPigSetEnabled(PigSet开关读取)/_MatchRoleFilter(角色过滤)/_CheckTargetFilter(目标名过滤)
BossAI COUNTER维度从Stub升级为完整实现.感知器驱动反制评估权重动态调整
BossAI 桥接 WR_BossMechanics 自动迁移.旧系统46个Boss机制无缝接入新框架

-- === BOSS特化界面跨新旧系统重构 ===
WR_BossUI.lua DungeonGroups 补全 P1-P11 全部副本Boss名单.新增P11终章HS/BT分组(14个Boss)
WR_BossUI.lua RefreshCurrentBoss 显示 AIDriver 激活状态.新增旧/新系统切换按钮
WR_BossUI.lua RefreshDetail 增加 BossAI 框架信息展示(阶段/血量/感知状态)
WR_BossUI.lua 修复BOSS特化列表只显示P10/P4/P6的BUG.根因:RefreshBossListInline()仅遍历WR_BossRegistry旧系统数据
WR_BossUI.lua 重写为遍历PHASES完整P1-P11数据.选项卡间距优化(4px->6px).行距增大

-- === 新旧系统并存切换 ===
MainLoop.lua 新增 IsLegacyFallback() 判断.按新旧系统双分支切换控制权
命令 /aiboss switch 可在旧WR_BossRegistry与新BossAI框架间切换
MKHelperForever.toc 注册 AI_Perceptor.lua 文件加载

【时光服】2026-8-5

-- === 神圣震击释放逻辑修复 ===
神圣 修复常规模式下移动中未正确使用神圣震击的问题.原逻辑(PigSet.SS_SSZJ == 1 and PlayerMove)导致不移动时几乎不会使用
神圣 重构WR_PaladinHoly_SSZJ()函数:模式1(常规)=所有情况下焦点血量≤80%都可使用/模式2(积极)=同常规/模式3(急救)=仅限血量≤40%或有优先减益/模式4=禁用
神圣 移除PlayerMove条件限制,确保无论是否移动都能在正确血量阈值下释放神圣震击

-- === 圣疗术目标选择与阈值系统完整实现 ===
神圣 新增下拉框SS_SLS_Target选择治疗目标:1-4=坦克1-4号(动态显示名称)/5=自己/6=全团检测(遍历所有队员)/7=禁用
神圣 恢复独立滑块SS_SLS作为统一阈值(0-100%,默认30%).所有目标模式共享同一个阈值
神圣 核心逻辑重构:WR_PaladinHoly_SLS()优先使用SS_SLS滑块值.阈值=slsValue>0 and (slsValue/100) or 0.30
神圣 菜单动态更新:WR_PaladinHoly_UpdateMenu()中SS_SLS下拉框同步坦克名称和阈值标识(如“坦克1 (30%)”)
神圣 全团检测模式(mode==6):遍历整个团队/队伍的所有成员,自动选择血量低于阈值的任意队员
神圣 命令清单新增:SS_SLS【滑条】圣疗术血量0-100

-- === 插入神圣牺牲功能新增 ===
神圣 新增复选框SS_CRSSXS控制插入神圣牺牲功能(第2行第3列,图标253400)
神圣 核心函数WR_PaladinHoly_CRSSXS():战斗中且技能不可用时触发插入宏SlashCmdList["SS_CRSSXS"]("")
神圣 智能开关管理:当神圣牺牲真正可用时自动关闭插入开关(SlashCmdList["SS_CRSSXS"]("off"))防止重复触发
神圣 颜色框架提示:可用时显示编号25色块提示.与防骑/惩戒骑逻辑完全一致
神圣 命令清单新增:SS_CRSSXS 插入神圣牺牲

-- === BOSSUI特化系统扩展更新 ===
BOSS UI WR_Warrior_BossSpecials.lua今日更新(13:53).WR_Druid_BossSpecials.lua(13:23).WR_Hunter_BossSpecials.lua(12:43).WR_Paladin_BossSpecials.lua(12:42).WR_Warlock_BossSpecials.lua(10:50)
BOSS UI 统一角色类型分类:tank/melee_dps/ranged_caster_dps/ranged_physical_dps/healer.法系远程(法师/术士/暗牧/平衡德/元素萨)与物理远程(猎人)差异化处理
BOSS UI 新增太阳井4BOSS特化(卡雷苟斯/布鲁塔卢斯/穆鲁/基尔加丹).祖阿曼6BOSS(鹰王/熊王/龙鹰王/豹王/妖术领主/祖金).祖尔格拉布4BOSS(哈卡/金度/血领主/祭司泰卡尔)
BOSS UI 法系/物理差异化:冰龙刺骨停读条vs走位反魔法护盾法系停手物理正常萨鲁法尔法系不取消保护物理取消翡翠巨龙法系跑位物理不跑燃烧之血血议会法系过滤黑暗之核猎人切目标更快教授催泪毒气法系停读条物理走位

【时光服】2026-8-4

-- === 圣骑士清洁术下拉菜单驱散模式（防护/惩戒对齐奶骑） ===
防骑 新增清洁术下拉菜单(FH_QJS),5模式:常规/优先/目标/指向/禁用.与奶骑(SS_QJS)完全一致
防骑 清洁术逻辑重写:WR_PaladinProtection_QJS(Text)支持双优先级调用(优先+常规).扫描顺序:目标>指向>自己>队友
防骑 删除旧复选框FH_QJS_Player/FH_QJS_Target.下拉菜单完全替代
惩戒 新增清洁术下拉菜单(CJ_QJS),5模式:常规/优先/目标/指向/禁用.与奶骑完全一致
惩戒 清洁术逻辑重写:WR_PaladinRetribution_QJS(Text)支持双优先级调用.新增WR_PaladinRetribution_Unit_QJS_DM通用驱散函数
惩戒 旧复选框CJ_QJS改为下拉菜单变量(布尔→数字).全局清洁术复选框重命名为CJ_QJS_QJ(驱散灵魂尖啸/熔化冲压)
惩戒 删除旧复选框CJ_QJS_Player/CJ_QJS_Target.下拉菜单完全替代
迁移 ZZ_Features_Migration.lua:CJ_QJS从布尔值迁移为数字(true→1常规,false/nil→1常规).FH_QJS默认1(常规).CJ_QJS_QJ默认true(开)
菜单 Paladin_Menu.lua:防护/惩戒各新增清洁术下拉菜单(5选项).防护/惩戒第3行删除自己/目标清洁术复选框并调整列号
命令 UI_CommandList.lua:防护/惩戒清洁术命令更新为下拉菜单格式

-- === 2026-8-9 防护骑清洁术复选框恢复（与下拉并存） ===
防骑 恢复自己/目标清洁术复选框(FH_QJS_Player/FH_QJS_Target),与下拉菜单FH_QJS并存(下拉不再唯一控制)
防骑 复选框为独立通道:勾选即驱散自己/目标,不受下拉"禁用"影响;默认开启以还原旧行为
防骑 新增WR_PaladinProtection_QJS_SelfTarget()函数,在主循环优先段(WR_PaladinProtection_QJS("优先")前)调用
菜单 Paladin_Menu.lua:防护第3行第4/5列恢复自己/目标清洁术复选框(defaultState=true)
迁移 ZZ_Features_Migration.lua:FH_QJS_Player/FH_QJS_Target默认true
命令 UI_CommandList.lua:新增/FH_QJS_Player /FH_QJS_Target

-- === 圣骑士下拉祝福系统修复 ===
防骑 防护骑士下拉祝福重写:WR_PaladinProtection_ZF()不再委托WR_PaladinHoly_ZF().8种祝福全部调用专属全团扫描函数
防骑 新增6个专属全团扫描函数:LLZF_Raid/ZHZF_Raid/WZZF_Raid/QXLLZF_Raid/QXZHZF_Raid/QXWZZF_Raid
防骑 每个函数独立实现:战斗外检查→法术可用→构建团队/小队列表→逐个检测buff→距离检查→WR_FocusCast施法
惩戒 惩戒骑士下拉祝福同步修复:WR_PaladinRetribution_ZF()不再委托WR_PaladinHoly_ZF().6种祝福直接调用防护骑的专属全团扫描函数
惩戒 复用防护骑的Raid函数(全局函数共享),无需重复定义
核心 根因:原代码通过临时修改PigSet.SS_ZF复用奶骑逻辑,在防护/惩戒骑士身上存在兼容性问题

【时光服】2026-8-1

-- === 五治疗过量停条窗口统一改造 ===
治疗 五治疗(奶骑/神牧/戒律牧/奶萨/奶德)统一增加过量停条窗口.施法剩余时间<=窗口值时检查目标血量.满血则停止施法避免过量
治疗 过量停条支持关闭及0.1至0.5秒检查窗口(下拉菜单5档).默认关闭.开启后用窗口值控制检查时机
治疗 保留首领机制与特殊治疗模式例外:狂咒停手(辛达苟萨)/血肉成灰/停止复活等始终生效.不受过量停条开关影响
治疗 配置变量3组(按现有前缀共享):SS_GLTC/SS_GLTCCK(奶骑+神牧)/HF_GLTC/HF_GLTCCK(奶萨+奶德)/JL_GLTC/JL_GLTCCK(戒律牧)
治疗 各职业Stopcasting改造:过量判断包裹if PigSet.XX_GLTC then + CastingRemainingTime<=窗口.窗口值=(XX_GLTCCK or 5)*0.1
奶骑 复用已有CastingRemainingTime变量.固定0.5秒窗口改为读SS_GLTCCK配置.圣光术(圣光之赐满血停)/圣光闪现
戒律牧 过量快疗/联结治疗判断包裹JL_GLTC开关+窗口
神牧 过量快疗/强效治疗术/联结治疗判断包裹SS_GLTC开关+窗口
奶萨 过量次级治疗波/治疗波/治疗链判断包裹HF_GLTC开关+窗口
奶德 过量愈合/治疗之触/滋养判断包裹HF_GLTC开关+窗口
UI 五治疗面板各注册1复选框(过量停条开关,默认false)+1下拉(停条窗口0.1~0.5秒,默认0.5秒).改动文件:Paladin_Menu/Priest_Menu(戒律+神圣)/Shaman_Menu/Druid_Menu
ZZ ZZ_Features_Migration.lua新增6个默认值(早期初始化块+Core_ConfigUI_Init defaults表两处).SS/HF/JL_GLTC=false + XX_GLTCCK=5
UI 切换提示与6冰触一致:复选框显示"开启/关闭[过量停条]".下拉显示"过量停条 已设置为：0.5秒".受/pigchat控制
UI 开关命令清单(MKHelperForever_开关命令清单.md)与游戏内命令清单(UI_CommandList.lua)同步增加5治疗过量停条开关(SS/HF/JL_GLTC)+窗口下拉(SS/HF/JL_GLTCCK)命令

-- === 恶魔术双子宝宝提前开怪修复 ===
恶魔 宠物攻击函数WR_SS_EM_KZBBGJ缺少UnitAffectingCombat(player)战斗检查.当FANG_ADD_EMS==2(防ADD=否)时主循环非战斗也运行.玩家吃黑暗精粹选白BOSS(菲奥拉)后宝宝攻击色块在未开怪时触发导致提前开怪
恶魔 修复:WR_SS_EM_KZBBGJ新增UnitAffectingCombat(player)条件.并排除双子BOSS名称(光明邪使菲奥拉/黑暗邪使艾蒂丝).确保非战斗时宝宝不主动攻击
宝宝 同类问题排查:猎人三系(兽王WR_LR_SWL_KZBBGJ+撕咬/射击WR_LR_SJL_KZBBGJ/生存WR_LR_SCL_KZBBGJ)与术士毁灭(WR_SS_HM_KZBBGJ)宠物攻击函数均缺少UnitAffectingCombat(player)检查.已统一修复
宝宝 术士毁灭同步排除双子BOSS名称(菲奥拉/艾蒂丝).术士痛苦(WR_SS_TK_KZBBGJ)与死骑邪恶(WR_DK_XDK_KZBBGJ)已有战斗检查无需修改

-- === 时光服不存在的Cata/MOP技能从循环剔除 ===
战士 注释武器战循环巨人打击调用(Warrior_Arms.lua L114).时光服基于WLK80级框架无Cata4.0巨人打击.GetSpellInfo空值保护会no-op但占循环位
战士 注释狂暴战循环3个Cata/MOP技能调用(Warrior_Fury.lua L112/115/118):巨人打击(Cata4.0)/怒击(Cata4.0)/狂风(MOP5.0)
法师 注释冰法循环寒冰宝珠调用(Mage_Frost.lua L131).时光服无MOP5.0寒冰宝珠(Frozen Orb)
盗贼 注释敏锐贼循环4处Cata/MOP调用(Rogue_Subtlety.lua):自动起手10星(L89,转嫁Cata4.0+10星MOP)/死亡印记AOE(L124,MOP)/死亡印记35%(L146,MOP)/死亡印记单体(L149,MOP)
删除 8个Cata/MOP函数定义全部删除:WR_WQZ_JRDJ/WR_KBZ_JRDJ/WR_KBZ_NUJI/WR_KBZ_FENGNU/WR_BF_HBBZ_ZD/WR_DZ_MR_SWYJ/WR_DZ_MR_SWYJ35/WR_DZ_MR_AUTO_QS.全局搜索确认仅自身文件引用无外部依赖(UI/斜杠命令均未调用).循环注释行改为纯说明不再引用函数名.陷阱发射器(用户未选中)保留
依据 暴雪官方公告确认时光泰坦服=WLK80级框架.仅官方新增雄鹰射击/豪猪诱饵.未引入任何Cata/MOP零售技能

-- === 鸟德哈卡饰品(赞达拉英雄护符)BUFF触发技能调整 ===
鸟德 确认哈卡饰品BUFFID=24659(截图验证:能量无常,法强+708).原代码错误注释为"自然之赐"天赋
鸟德 调整逻辑:DLY_ZDLHF函数中,当检测到24659 BUFF时,原逻辑施放"愤怒"(色块20)改为施放"星火术"(色块21)
鸟德 实现:2-3层BUFF时强制星火,1层BUFF且在读愤怒时打断打星火.色块ID从20改为21
鸟德 需求实现:轨道炮(星落)以后有哈卡饰品buff先打星火.其他情况保持原急速判断逻辑

-- === 猎人三系AOE2模式重构（防骑风格） ===
猎人 用户反馈:兽王猎AOE2仍用乱射/陷阱/多重以外的技能(雄鹰射击/猎人印记/急速射击/狂野怒火/守护切换等).之前mode~=3包裹方式无效
猎人 根因:原结构分散(mode~=3包裹非核心技能 + mode==3分支核心输出).两层判断容易遗漏.且mode值可能未正确读取
猎人 重构:按防骑风格重写.单一if mode==3 then ... else ... end分支.AOE2分支只放多重/乱射/爆炸陷阱.else分支放全部单体/AOE1技能
猎人 公共部分(所有模式执行):自动射击(平射)+宠物控制(攻击/跟随)+误导(目标的目标/焦点/宠物)
猎人 AOE2分支:陷阱发射器爆炸陷阱+多重射击+乱射.无其他技能
猎人 单体/AOE1分支:守护切换>猎人印记>爆发(药水/种族/手套/炸弹/急速射击/狂野怒火/准备就绪)>杂项(摔绊/扰乱/震荡)>动力炸弹>核心输出>AOE1乱射/单体稳固
猎人 修改文件:Hunter_BeastMastery.lua(L83-176)/Hunter_Marksmanship.lua(L83-188)/Hunter_Survival.lua(L82-183)
猎人 说明:LR_SWL_CYCLE_MODE为SavedVariablesPerCharacter.下拉菜单保存1-based索引(1=单体/2=AOE1/3=AOE2).mode==3判断AOE2.值3会被持久化不会被迁移重置
猎人 排查:雄鹰射击在else分支(mode~=3).AOE2(mode==3)不会触发.若仍触发需确认PigSet.LR_SWL_CYCLE_MODE值是否为3(检查UI下拉菜单是否切到AOE2)

-- === 猎人三系AOE2模式二次修复（变量类型污染） ===
猎人 用户反馈:防骑风格重构后AOE2仍不生效.仍有雄鹰射击/猎人印记/急速射击等技能触发
猎人 根因:CYCLE_MODE变量可能被污染为布尔值true/false.原代码`PigSet.X or 1`在变量为true时返回true(非数字).`mode==3`即`true==3`永远为false.AOE2分支无法进入
猎人 污染来源:与WCL_MODE历史问题相同——复选框OnClick可能将下拉菜单的数字变量覆写为布尔值.或旧版SavedVariables残留布尔值
猎人 修复1(ZZ_Features_Migration.lua):新增CYCLE_MODE变量迁移.将true/false/nil/非数字/越界值统一重置为1(单体).用户需重新从下拉菜单选择AOE2
猎人 修复2(三系Hunter文件):mode读取改用`tonumber(PigSet.X) or 1`确保类型安全.tonumber(true)=nil→or 1=1.tonumber("3")=3.tonumber(3)=3
猎人 修复3(三系Hunter文件):mode读取提前到战斗循环外.新增模式变化调试提示print.用户进游戏后切换模式可在聊天窗口看到"[兽王猎] 输出模式: AOE2"确认值正确
猎人 对比防骑:防骑用`local isRaid=(PigSet.FH_PRIORITY_MODE==1)`直接比较.不依赖or回退.nil==1=false→安全进入else.猎人原用`or 1`回退在变量为true时不安全
猎人 修改文件:ZZ_Features_Migration.lua(L201-213)/Hunter_BeastMastery.lua(L74-82)/Hunter_Marksmanship.lua(L77-85)/Hunter_Survival.lua(L76-84)

-- === 猎人三系输出模式简化（3项→2项） ===
猎人 需求:去掉AOE1模式,把AOE2改名为AOE,只保留单体和AOE两种模式
猎人 修改:下拉菜单从3项(单体/AOE1/AOE2)改为2项(单体/AOE).代码中mode==3改为mode==2.删除else分支内的AOE1乱射块.只保留稳固射击
猎人 迁移(ZZ_Features_Migration.lua):旧3→新2(AOE2→AOE).旧2→新2(AOE1→AOE).旧1→新1(单体不变).范围检查>2
猎人 模式对照:1=单体(守护/印记/爆发/核心输出/稳固填充) 2=AOE(只放多重/乱射/爆炸陷阱)
猎人 修改文件:Hunter_Menu.lua(3处下拉菜单)/Hunter_BeastMastery.lua/Hunter_Marksmanship.lua/Hunter_Survival.lua/ZZ_Features_Migration.lua

-- === 全职业输出循环优先级汇总文件 ===
整理 新增 Rotation_Summaries.md 文件.集中汇总全部24个职业专精的核心输出循环优先级.便于查看对照调试
整理 覆盖:战士3系/圣骑士2系/DK3系/德鲁伊2系/盗贼3系/猎人3系/法师3系/暗牧/萨满2系/术士3系
整理 每个专精列出:自动切目标状态(✅激活/❌已注释)+核心输出优先级+模式分流说明
整理 附:自动切目标状态总览表+通用执行流程分层说明(基础变量→最高优先级→打断→插入→切目标→自动攻击→战斗主循环)
整理 战士武器/狂暴近战切目标(WR_War_Arms_Tab/WR_War_Fury_Tab)确认已注释.全部近战/坦克切目标已统一取消

【时光服】2026-7-31

-- === 猎人宠物死亡识别修复 ===
猎人 修复宠物死亡后仍提示"召唤宠物"而非"复活宠物"的BUG.三专精(ZZ_LR_SW/SJ/SC_SHCW)同步修复
猎人 根因1:UnitExists("pet")在宠物死亡后部分场景返回false(尸体消失/区域切换).复活检查全部依赖UnitExists导致被跳过.落到召唤逻辑(召唤死亡宠物会失败)
猎人 根因2:复活检查用WR_SpellUsable("复活宠物",true)含GCD<=0.4严格判断.战斗中GCD常>0.4导致复活提示不触发.而召唤检查无此GCD限制(见原注释)故始终触发
猎人 修复:新增粘性标记WR_PetDeadState.宠物死亡(UnitIsDead或近期错误消息<15秒)时置true.宠物存活或确实不存在时置false.复活检查改用WR_PetDeadState.不再依赖UnitExists
猎人 修复:复活检查改用C_Spell.IsSpellUsable("复活宠物")直接判断.移除GCD严格限制.与召唤检查保持一致.战斗中能正常提示复活
猎人 修复:召唤检查增加not WR_PetDeadState条件.宠物死亡状态下不再误提示召唤.避免召唤失败

-- === 兽王猎AOE2循环修复 ===
兽王猎 修复AOE2模式多打奥术射击和稳固射击的BUG.AOE2应只打陷阱/多重/乱射(注释原意)
兽王猎 删除mode==3块末尾WR_LR_SWL_ASSJ(奥术射击)和WR_LR_SWL_WGSJ(稳固射击)两行.与射击/生存专精AOE2保持一致

-- === 血DK AOE模式血液沸腾前置 ===
血DK AOE模式(WR_DK_Blood_AOE_Mode)血液沸腾全部前置到枯萎凋零之前.原顺序起手BB>DnD>疾病BB导致有疾病时DnD先于BB
血DK 新顺序:血液沸腾(起手+新判断+强制+标准)>枯萎凋零>传染>疾病保持>心脏/鲜血打击>灵界打击>填充>凋零缠绕
血DK XYFT_NEW的KWDLGCD<7.5条件在DnD可用时(cooldown=0)为true.BB前置后DnD可用时BB优先触发.符合用户要求
血DK 修复起手BB(WR_DK_Blood_XYFT_Qishou)GCD严格门限BUG.原WR_SpellUsable("血液沸腾",true)受ShiFaSuDu=0.3限制.GCD>0.3时起手BB不显示
血DK 起手BB改用C_Spell.IsSpellUsable("血液沸腾")直接判断.移除GCD<=0.3严格限制.战斗中能可靠提示起手血液沸腾

-- === 开关切换提示信息统一 ===
UI 所有下拉菜单/复选框切换均按6冰触方式增加切换提示信息.原下拉菜单UI点击无提示(仅斜杠命令有)
UI_Config.lua:PrintToVisible提升为文件级函数.下拉菜单UI点击新增"X已设置为Y"提示.下拉斜杠命令print改PrintToVisible(尊重ChatNoticeMode)
UI_Config.lua:复选框off消息修正(原"已使用OR在冷却"误写→"已关闭").复选框UI点击+斜杠命令均统一PrintToVisible
UI_Config.lua:跟随/近战黑名单/远程黑名单/坦克黑名单复选框+跟随目标下拉菜单 print改PrintToVisible(尊重ChatNoticeMode).noticeCheckbox保留print(自身切换提示开关需始终可见)
ZZ_Features_Migration.lua:新增文件级PrintToVisible.通用设置面板下拉菜单(Iconid_F007)UI点击+斜杠命令新增提示.内联复选框UI点击新增"开启/关闭[label]"提示
UI 提示受/pigchat控制(0关闭/1默认窗口/2全部可见窗口).与6冰触完全一致

-- === WCL模式默认值修复+变量名冲突解决 ===
核心 修复WCL_MODE默认值BUG.ZZ_Features_Migration.lua默认值原为true(布尔).UI_Config.lua迁移逻辑把true转1(冲分).导致新用户默认冲分模式而非正常模式
核心 修复:ZZ_Features_Migration.lua两处默认值true→2.L177默认2.L2545 defaults表默认2.新用户现在默认正常模式
核心 解决变量名冲突:PigSet.WCL_MODE同时被两个功能共用(WCL冲分/正常下拉菜单+怪物屏蔽开关).复选框OnClick会把数字2覆盖成true/false破坏下拉菜单状态
核心 怪物屏蔽系统改用独立变量MONSTER_BLOCK_ENABLED(布尔).与WCL_MODE(数字)完全分离.互不干扰
核心 迁移兼容:旧WCL_MODE=false(关闭怪物屏蔽)的用户.MONSTER_BLOCK_ENABLED继承false.WCL_MODE由UI_Config转为2(正常)
核心 修改7处:IsMonsterBlocked判断/2处复选框SetChecked/复选框OnClick/defaults表/通用设置面板saveVariable

-- === 近战/坦克取消自动切目标 ===
近战/坦克 取消近战和坦克职业的自动切目标功能.近战切目标需跑位不实用.坦克切目标会丢失仇恨
近战 取消4个仍启用的近战/坦克切目标调用:冰DK(WR_DK_Frost_Tab)/邪DK(WR_DK_Unholy_Tab)/惩戒骑(WR_Hun_MM_Tab)/防骑(WR_Pal_Pro_Tab)
近战 其余近战/坦克职业切目标此前已注释:血DK/防战/野德/三系盗贼/增强萨.本次补齐最后4个
远程 远程职业(猎人3系/法师3系/鸟德/暗牧/元素萨)切目标保持不变.远程切目标无跑位成本

-- === 防骑仇恨向神圣之盾优先级调整 ===
防骑 仇恨向循环去掉神圣之盾"优先"位置(原第4优先级)."优先"模式需盾牌壁垒<1.5秒或层数<=1才触发.条件严格导致仇恨向几乎不使用神圣之盾
防骑 仇恨向只保留神圣之盾"填充"位置(第8优先级).神圣之盾仍会使用但优先级低.不抢占正义之锤/正义盾击/奉献/愤怒之锤等仇恨技能
防骑 新优先级:正义之锤(AOE)>正义盾击>奉献(AOE)>愤怒之锤>正义之锤(填充)>奉献(填充)>审判(填充)>神圣之盾(填充)>神圣恳求
防骑 生存向循环不变.神圣之盾仍在第1优先级(优先格挡)

-- === 防骑神圣之盾永不释放根因(修正) ===
防骑 仇恨向(及生存向)神圣之盾"始终不释放"的真正根因不在循环优先级,而在SSZD函数本身的两道过严门控
防骑 SSZD原首行:WR_SpellUsable("神圣之盾",true) and UnitIsUnit("targettarget","player"),且填充位另加 TargetRange<=20
防骑 UnitIsUnit("targettarget","player")要求"当前目标必须正在打你",但AOE拉怪/切目标/BOSS打别人/击退拉远时普遍不满足→神圣之盾永不释放
防骑 这是全骑士唯一带此门控的技能(进攻技能均不检查),故进攻技能正常而神圣之盾卡死;此门控同时拖垮生存向的优先/填充位
防骑 修复:SSZD去掉 UnitIsUnit("targettarget","player") 与 TargetRange<=20 两道门控(神圣之盾是自身增益,循环已在战斗内判定),循环空档即稳定释放
防骑 优先级(仇恨向):正义之锤(AOE)>正义盾击>奉献(AOE)>神圣之盾(优先,维护)>愤怒之锤>正义之锤(填充)>奉献(填充)>审判(填充)>神圣之盾(填充)>神圣恳求
防骑 优先位逻辑:盾牌壁垒(神圣之盾buff)<1.5秒或层数<=1且正义之锤不可用才补,不抢占仇恨GCD;填充位无门控靠10s自身CD限频
防骑 注:303-307条目所述"误删优先位"并非根因;根因为SSZD门控,影响全部循环。优先位恢复仅是顺带对齐菜单/GX559文档

-- === BOSS特化系统v2.1 ===
BOSS特化 新增WR_BossMechanics.lua统一BOSS机制配置库.集中管理所有副本BOSS的机制/触发条件/适用角色/颜色ID
BOSS特化 角色类型从5类细化为6类:tank/melee_dps/ranged_caster_dps/ranged_physical_dps/healer+兼容旧ranged_dps
BOSS特化 法系远程DPS(法师/术士/暗牧/平衡德/元素萨)与物理远程DPS(猎人)针对同一BOSS有完全不同的应对措施
BOSS特化 新增WR_CheckRoleApplicable函数.支持新旧角色常量双向兼容.机制applicableRoles多key配置
BOSS特化 重写全部10个职业BossSpecials文件.按角色类型精确筛选适用机制.直接调用WR_ColorFrame_Show显示颜色
BOSS特化 治疗天赋(神圣骑/恢复德/恢复萨/戒律神牧)自动跳过所有BOSS特化检查.避免干扰治疗循环

-- === 远程DPS法系/物理差异化（核心改进）===
冰龙辛达苟萨 法系刺骨>=3层停读条(施法速度大降卡条).物理刺骨>=5层停手(无读条阈值更高)
冰龙辛达苟萨 BOSS有反魔法护盾时法系停手省蓝(法术全被吸收).物理不受影响照常打
萨鲁法尔 法系不取消保护之手(法术输出不受物理免疫影响).物理必须停手取消(物理伤害全被吸收)
翡翠巨龙 燃烧之血时法系停手省蓝(耗蓝翻倍有蓝条).猎人不受影响(无蓝条照常输出)
血议会 法系强化过滤黑暗之核(黑暗之核吃魔法绝对不能打).猎人也过滤但切目标更快保留提示
教授普崔希德 法系催泪毒气停读条(施法速度降低).物理走位提示(移动速度降低但输出正常)
尤格萨隆 法系心灵牢笼沉默时停手(不能施法).物理精神控制时停手
腐面烂肠 法系突变停读条立刻跑(否则施法完跑不出去).物理走位(不用考虑读条)
巫妖王 法系污染停读条立刻跑(施法时间长了走不出去).物理立刻走位
奥尔加隆 法系宇宙撞击停读条(卡条风险极高).物理坍缩之星走位停手

-- === 太阳井高地(5个BOSS)特化新增 ===
太阳井 新增卡雷苟斯(黑暗之门/腐蚀/燃烧).布鲁塔卢斯(陨石打击/燃烧之血).艾瑞达双子(暗影之痛/火焰之痛)
太阳井 新增穆鲁(虚空哨兵/熵).基尔加丹(千魂/暗影之矛/炽焰弹幕/虚空之盾)
太阳井 布鲁塔卢斯坦克陨石打击开减伤.近战DPS停手.远程DPS燃烧之血开火箭靴跑位
太阳井 基尔加丹千魂全体停手.暗影之矛法系停读条.虚空之盾法系停手省蓝

-- === 祖阿曼(6个BOSS)特化新增 ===
祖阿曼 新增鹰王(电气风暴/雷霆风暴).熊王(冲锋/熊形态).龙鹰王(火焰新星/小龙鹰)
祖阿曼 新增豹王(闪避/图腾).妖术领主(妖术/灵魂吸取).祖金(狂暴/毒/变形)
祖阿曼 鹰王电气风暴全体集合.雷霆风暴法系停读条
祖阿曼 豹王闪避近战停手(打不出伤害).过滤图腾
祖阿曼 妖术领主妖术全体停手(被变青蛙不能施法).灵魂吸取法系停读条

-- === 祖尔格拉布(4个BOSS)特化新增 ===
祖尔格拉布 新增哈卡(鲜血虹吸/心灵控制).金度(妖术/幽灵).血领主(凝视/冲锋).祭司泰卡尔(豹形态/复活)
祖尔格拉布 哈卡鲜血虹吸全体停手.过滤哈卡之子
祖尔格拉布 血领主凝视全体停手(被凝视者不能攻击BOSS).冲锋近战停手
祖尔格拉布 金度妖术全体停手.过滤金度幽灵

-- === 副本覆盖统计 ===
BOSS特化 v2.1共支持28个BOSS:ICC(13)+太阳井(5)+祖阿曼(6)+祖尔格拉布(4)
BOSS特化 颜色映射:stop=3/target=4/defensive=8/rocketboots=108/lk_contamination=107
BOSS特化 各职业BossSpecials通过WR_FindCurrentBossMechanics自动匹配目标BOSS.无需单独注册

-- === ZZHELPER_TITAN 功能迁移至 MKHelperForever ===
核心 新增ZZ_Features_Migration.lua整合从ZZHELPER_TITAN迁移的26个功能模块.共1559行代码
核心 DBM倒计时系统(WR_GetDBMCountdown_EM).监听START_PLAYER_COUNTDOWN/CANCEL_PLAYER_COUNTDOWN事件.复用现有DBM接口
核心 预开药水逻辑(TryPrePullPotion/TryPrePullSpeedPotion).关联PigSet.DBM_PREPULL_POTION开关.倒数0-1秒提前吃药
核心 职业颜色函数(ZZ_ClassesColor).支持全13个职业颜色返回|cff格式
核心 FocusCast焦点施法系统(SetFocusCastInfo/ShowFocusHealthFrame).战斗日志监听SPELL_CAST_SUCCESS重置状态
核心 Boss阶段配置表(PHASES).5个阶段覆盖MC/SSC/TK/NAXX/OS/EOE/TOC/ZG/SWP/ZA全部团本小怪名单
核心 怪物屏蔽系统(IsMonsterBlocked/ZZ_MonsterBlockIndex).多线目标屏蔽+近战AOE数量屏蔽.含别名映射表
核心 CVar锁定系统.战斗外自动锁定镜头距离/姓名板/亮度等12项基础设置+11项副本设置.战斗中延迟修改
核心 怪物屏蔽配置界面(ZZ_MonsterBlockFrame).5阶段标签页+勾选名单+恢复默认.支持手动覆盖
核心 治疗权重计算系统(EvaluateUnitHealWeight/GetHealthMaxWeightUnit).血量+Debuff+职业专精三维优先级
核心 焦点最大权重显示(ShowFocusHealthMaxWeightUnit).0.15秒缓存节流.自动选择最需治疗目标
核心 饰品爆发窗口检测(CheckTrinketBurstWindow).22种饰品数据.DK额外检查不洁之力buff
核心 单目标战斗判断(IsSingleUnitFight).26个BOSS名单匹配
核心 停止施法判断(IsStopCastSpellIncoming).4种需打断技能预判
核心 法力宝石可用性(HasManaGemReady).检查法力青玉数量和冷却
核心 框架透明度控制(Iconid_F001/F002/F003).背景色alpha动态调整.OnShow自动重应用
核心 配置界面构建器(Iconid_F004下拉菜单/Iconid_F005复选框/Iconid_F006滑块).支持斜杠命令快捷设置
核心 聊天框通知模式(SLASH_PIGCHAT).0关闭/1默认窗口/2全部可见窗口三档切换
核心 插件过期检查(ShowExpirationNotice).多时间API兼容(C_DateAndTime/CalendarGetDate/date).过期弹窗强制显示
核心 更新日志面板(Myaddon_SD_F001).MKHelperForeverUpdateFrame+MKHelperForeverFAQFrame双面板.支持重载检测
核心 按键绑定检查系统(CheckBindingByKey/CheckAllBindings/RegisterClassBinding).TITAN/MOP双版本期望数量.宏内容校验
核心 API兼容性初始化(Core_InitAPI).兼容GetSpellInfo/GetSpellDescription/GetSpellCooldown等旧版API
核心 配置面板创建(Iconid_F007/F008/F009/F010).主配置界面+职业设置+通用设置+重置按钮
核心 Core_GroupRoles辅助函数44个.含治疗药水/驱散判断/团队Buff/单位状态/技能追踪等
核心 Core_TempText调试工具(Temptext_F001/F002/F003).调试计时/团队图标目标选择/单位名称匹配

-- === 自动跟随提示优化 ===
跟随 修复已跟随上目标后提示色块(115/116/117)不消失的问题
跟随 已跟随时立即清除提示色块(WR_HideFollowColorFrames).不再一直显示"焦点跟随/目标跟随"
跟随 移除1.5秒冷却(lastFollowAttempt).未跟随时每帧持续显示色块.避免被技能色块覆盖只闪1帧
跟随 修复脱离跟随(AUTOFOLLOW_END)后提示不立即重新显示的问题.现在每帧刷新色块持续可见
跟随 已跟随时返回false让职业循环正常执行.未跟随时返回true阻塞职业循环优先跟随
跟随 清理lastFollowAttempt变量及所有引用.关闭跟随/AUTOFOLLOW_END不再需要重置冷却

-- === 术士TOC冠军阵营功能 ===
术士 新增TOC冠军阵营辅助功能.支持放逐奶德/恐惧牧师/恐惧奶萨/选盗贼猎人4个目标
术士 痛苦/恶魔学识/毁灭3专精均已集成TOC冠军检查逻辑.位于循环优先级第5.5节
术士 TOC放逐奶德:目标麦拉多·深谷游者/伊林·雾蹄→放逐术.颜色74(CCTRL+SHIFT+F11)
术士 TOC恐惧牧师:目标安塔尔·缮炉者/严肃的凯普斯→恐惧.颜色84(ALT+CTRL+SHIFT+F11)
术士 TOC恐惧奶萨:目标萨缪尔/萨卡加尔→恐惧.颜色90(ALT+CTRL+SHIFT+F10)
术士 TOC选盗贼猎人:目标玛兹迪娜/伊锐丝·影踪/鲁姬卡/阿莱希娅·月行者.颜色110(ALT+SHIFT+F10)
术士 3专精菜单均新增4个TOC开关.按专精前缀区分(SS_TK/SS_EM/SS_HM)
术士 修复BOSS UI语法错误.移除continue关键字改用skipGroup标志位模式.BOSS列表正常渲染

【时光服】2026-7-30
-- === 恶魔术全局偷灭杀 ===
恶魔术 新增全局偷灭杀功能(WR_SS_EM_TMS_QJ).灭杀buff<2秒时自动扫描附近低血敌人(<35%)续灭杀
恶魔术 全局偷灭杀通过遍历队友目标(raid1-25target/party1-4target)实现.不改变玩家目标
恶魔术 全局偷灭杀焦点单位用色块82施放.非焦点用WR_FocusUnit临时切焦点.全程不碰当前目标
恶魔术 全局偷灭杀菜单开关SS_EM_TMS_QJ.默认开启.与指向/焦点偷灭杀互补

-- === 恶魔术循环修复 ===
恶魔术 腐蚀术改为0秒刷新.只在debuff消失后补充.避免3秒提前刷新导致GCD冲突卡技能
恶魔术 自动种族技能修复.修正执行顺序(ZDZZ优先于CRZZ).移除石像形态/奥术洪流只保留狂暴/血性狂怒/狮心
恶魔术 自动种族移除过度严格的BOSS判断.改用zidongbaofa标志判断.非BOSS目标也能触发
恶魔术 放逐焦点列表增加"麦拉多·深谷游者".与"火誓者"逻辑一致

-- === WCL模式核心BUG修复 ===
核心 修复WCL_MODE布尔判断BUG.5处代码使用旧布尔逻辑(not PigSet.WCL_MODE)导致正常模式(值=2)也被限制
核心 修复位置:WR_IsWCLBlacklisted/多目标屏蔽/AOE跳过小怪/取消灌注专注/法师取消灌注
核心 正常模式(值=2)现在完全不受WCL黑名单限制.冲分模式(值=1)才应用黑名单
核心 双子(菲奥拉/艾蒂丝)从WCL冲分黑名单移除.双子是计分BOSS不应进黑名单
核心 焦点/指向DoT从WCL黑名单移除(所有职业通用).玩家手动设置的焦点和鼠标指向的多线目标不应被WCL过滤
核心 目标DoT保留WCL黑名单检查.防止自动切到不计分小怪时浪费GCD
核心 修复职业:恶魔术焦点献祭/腐蚀+猎人焦点/指向钉刺+火法焦点/指向活动炸弹

-- === 全职业种族技能精简(移除石像形态/奥术洪流) ===
全职业 移除石像形态和奥术洪流从所有种族技能检查.只保留狂暴/血性狂怒/狮心3种核心爆发技能
全职业 移除范围:ZDZZ(自动种族)/CRZZ(插入种族)/开关判断/宏定义共4个位置同步删除
全职业 影响文件共21个:术士3专精+法师3专精+DK3专精+猎人3专精+盗贼3专精+战士3专精+萨满2专精+牧师+防战+惩戒圣骑+宏文件
全职业 ZDZZ/CRZZ调用顺序全部正确.ZDZZ(自动种族)始终在CRZZ(插入种族)之前执行
全职业 种族技能触发条件无统一WR_TargetIsBoss判断.大部分职业使用zidongbaofa标志+爆发期条件判断
黑名单 修复PigSet.BLACKLIST为nil时报错(attempt to get length of field 'BLACKLIST')
黑名单 默认黑名单初始化移至ADDON_LOADED事件.确保SavedVariables加载后再添加默认值
黑名单 新增命令别名/mkhbl和/pigblacklist.避免与其他插件/blacklist命令冲突
黑名单 函数内部添加PigSet和PigSet.BLACKLIST运行时nil保护

-- === UI缩放问题修复 ===
界面 修复两个战网UI大小不一致问题.删除错误的SetScale(1.0)代码恢复继承UIParent缩放
界面 SetScale(1.0)会覆盖UIParent的0.7缩放导致UI偏大.删除后框架自动继承UIParent缩放
界面 两个战网FrameScale不一致时手动执行: /run PigSet["FrameScale"]=0.74 然后/reload
界面 该值保存在PigSet中下次登录自动生效.两个战网设相同值即可完全一致

【时光服】2026-7-29
全职业 偷药与自动药水逻辑分离.偷药开关只控制DBM倒数提前喝药(战斗前).自动药水开关只控制战斗中爆发期喝药.两者互不影响
全职业 所有药水面板开关默认值统一为false(关闭)
全职业 自动种族技能添加BOSS判断.只有目标是BOSS才触发.不再对小怪使用
鲜血DK 群拉循环优化.起手优先血液沸腾立即建立AOE仇恨(无疾病时触发).比枯萎凋零更快拉住怪
鲜血DK 传染逻辑优化.只在疾病快消失(刷新)或周边有2+怪无疾病(扩散)时使用.扩散用途8秒内部CD避免频繁使用

-- === UI界面垂直间距大幅压缩 ===
界面 单元格高度从66px压缩至54px(-18%).图标基础大小从38→34.复选框从30→28
界面 下拉菜单行高从26→22px(-15%).基础宽度从280→260.基础高度从125→100
界面 WRH高度计算公式优化：Sum1系数20→18/Sum2系数50→42.界面整体高度降低约25-30%
界面 底部控件间距从12-18px压缩至8-14px.滑块标签间距从5→3
界面 图标布局锚点间距从5→3.顶部预留空间从105→95.整体更紧凑

-- === 跟随系统关键修复 ===
主循环 修复下拉选择目标后无法正确设置焦点和跟随的问题
主循环 重写为状态机架构：idle→waiting_focus→waiting_follow三阶段严格验证
主循环 阶段1(waiting_focus):选中目标+显示色块116，验证玩家是否真的设置了焦点(UnitIsUnit)
主循环 阶段2(waiting_follow):验证焦点正确后显示色块117，持续监控焦点状态避免丢失
主循环 "焦点"模式:焦点不存在时提示116(设置焦点)，焦点存在但不对时提示116(重设焦点)
主循环 "目标"模式:无需焦点直接进入跟随阶段(色块115)
主循环 状态追踪变量:currentFollowPhase/currentFollowUnit/currentFollowMode三变量协同
主循环 焦点丢失自动回退到idle重新走完整流程，防止跟随失效

-- === 底部控件间距回调(解决重叠) ===
界面 跟随→屏蔽间距:8→14px(+75%)
界面 屏蔽→图标缩放间距:14→16px(+14%)
界面 图标缩放→透明度间距:14→16px(+14%)
界面 透明度→开关提示间距:12→15px(+25%)
界面 滑块标签间距:3→5px(+67%)
界面 控件底部边距:10→12px
界面 横向三屏蔽间距:18→20px
界面 WR_FRAME_BASE_HEIGHT:100→112
界面 WRH函数Sum1系数:18→19/Sum2系数:42→44/附加值:2→6
界面 FrameHigh默认:220→240
界面 图标布局锚点预留:95→102

-- === 跟随复选框和WCL/ADD间距修复 ===
跟随 修复复选框不能直接控制跟随的问题.OnClick时重置状态机变量(currentFollowPhase/GUID/Unit/lastFollowAttempt)
界面 WCL模式/防ADD垂直间距:MENU_ROW_H从22→26px(+18%)
界面 下拉菜单行首yOffset从-12→-15px.增加行间间距
界面 WCL锚点从-20→-24px.增加与图标间距

-- === 跟随复选框和WCL/ADD间距再次优化 ===
跟随 修复复选框开启时不直接生效的问题.开启时检查当前状态,若焦点已设置则直接进入waiting_follow状态
跟随 关闭时完全重置状态机变量,开启时智能判断当前状态
界面 底部控件垂直间距统一增加至18px:跟随→防ADD(14→18)/防ADD→图标缩放(16→18)/图标缩放→透明度(16→18)/透明度→开关提示(15→18)
界面 WCL锚点间距从-24→-32px(-33%).大幅增加与天赋面板间距,防止重叠
界面 WRH函数Sum1系数从19→26.与MENU_ROW_H保持一致,确保高度计算正确

-- === 跟随核心逻辑修复（直接执行跟随） ===
跟随 重写WR_AutoFollow函数，从复杂状态机简化为直接执行模式
跟随 移除状态机idle→waiting_focus→waiting_follow三阶段流程，改为直接FollowUnit调用
跟随 移除range>25距离限制，跟随不需要距离检查
跟随 添加500ms节流机制，避免每帧都调用FollowUnit
跟随 target模式：目标是玩家时直接FollowUnit("target")
跟随 focus模式：焦点存在且正确时直接FollowUnit("focus")
跟随 party模式：焦点已设置且正确时直接FollowUnit("focus")
跟随 焦点不存在或不正确时才显示色块116提示玩家设置焦点

-- === 神圣牧优化 ===
神圣牧 圣光涌动智能优先.坦克>有减益>低血量缺口三维判断.不再只触发焦点
神圣牧 治疗之环增加坦克紧急条件(坦克<40%且2+低血量).增加条件4(3人<50%血量)
神圣牧 心灵专注预读阈值从35%提升至45%.有减益时也触发
神圣牧 守护之魂阈值从35%收紧至30%.真正紧急才触发
神圣牧 愈合祷言扩展：除坦克外，血量<35%非坦克队友也触发

-- === 奶德优化 ===
奶德 生命绽放优化：坦克满3层后<50%血量仍可刷新保持3层.焦点<40%紧急施放
奶德 回春术优化：移动中或目标有优先级减益时即使未达血量阈值也触发
奶德 野性成长增加坦克紧急触发：坦克<40%且有2+低血量队友
奶德 新增SpellValue_HCS回春术治疗量计算并纳入过量容忍度调整

帧数优化
核心新增光环缓存系统(WR_EnsureAuraCached).替代重复255槽位扫描.减少API调用70-85%
核心新增姓名板缓存系统(WR_EnsureNameplatesCached).5次独立遍历合并为1次共享遍历
核心新增WR_UpdateFrameState集中帧状态缓存.所有HP/MP/目标状态统一管理.50ms缓存过期+0.05秒节流
核心新增WR_RegisterCombatLogHandler战斗日志统一分发.避免78+独立OnUpdate扫描
核心SetCVar调用移出OnUpdate.改为事件驱动(PLAYER_REGEN_ENABLED/ZONE_CHANGED_NEW_AREA)
修复UnitIsHostile无效API调用.改用UnitCanAttack判断敌对关系

-- === 5专精输出循环深度优化 ===
防骑 修复神圣之盾被正义之盾条件阻断的问题.盾牌壁垒低时始终优先使用神圣之盾获取格挡buff
防骑 正义盾击优先级提升至愤怒之锤之前.作为仇恨+生存核心技能更早在循环中检查
防骑 奉献增加刷新阈值检查.剩余<3秒时立即刷新避免断档.不再只检查多目标条件
防战 毁灭打击(续破甲)优先级提升.移至盾牌猛击/致死打击之前.破甲<5秒时必刷防止断档
恶魔术 献祭刷新时机优化.改为剩余<3秒时刷新(原先是过期才补).大幅减少DPS损失
恶魔术 腐蚀术刷新时机优化.改为剩余<3秒时刷新.保持快照连续性
恶魔术 灵魂之火(灭杀)优先级提升.灭杀触发时立即使用.不再等待厄运诅咒/烧尽
血DK 冰霜疫病/血之疫病保持优化.改为剩余<3秒时刷新(原先是完全消失才补).防止疾病断档
血DK 输出模式疫病保持同样优化.符文刃舞爆发时自动刷新不受影响
兽王猎 杀戮射击优先级提升.移至杀戮命令之后/黑箭之前.确保20%斩杀期每发杀戮都不浪费

-- === T套装特化逻辑 ===
火法 4T10特化.炎爆术优先级直接提升至最高.跳过活动炸弹快炸/填充判断.冲破极限buff触发时全额增益
火法 2T10保持原有逻辑.炎爆术在特定条件下优先于填充
猎人 2T10特化.急速射击期间稳固射击优先(触发免费技能概率)
猎人 4T10特化.全局优先稳固射击(射击有几率额外伤害)

-- === 猎人核心优化 ===
猎人 稳固延迟GCD等待.核心技能(爆炸/杀戮/奇美拉)即将就绪(<0.5秒)时最多等待0.45秒.让核心技能优先释放.DPS提升2-3%
猎人 毒蛇钉刺智能优先级.焦点钉刺即将断补(<3秒)时强制优先.主目标钉刺自动让位
猎人 弹道飞行时间修正.远距离(≥35码)时提前释放奇美拉/瞄准射击.避免弹道到达前目标离开射程

-- === 火法核心优化 ===
火法 燃烧+镜像联动.燃烧期间自动开镜像(优先级高于冰冷血脉).分身炎爆享受燃烧暴击增益
火法 弹道飞行时间修正.35码外炎爆术增加飞行时间预判.目标>38码时优先释放

-- === WCL冲分模式优化 ===
新增WR_IsWCLBlacklisted统一过滤函数.冲分模式下自动跳过不计分小怪(软泥/骨刺/血兽/冰球/议会王子等60种)
猎人 毒蛇钉刺(指向/焦点/目标)集成WCL过滤
术士 献祭/腐蚀术/厄运诅咒集成WCL过滤
法师 活动炸弹(目标/焦点/指向/全局)集成WCL过滤
Core_Functions WR_CanDot函数集成WCL统一过滤层

-- === 多线管理优化 ===
新增WR_SortMultilineTargets多线目标智能排序函数.按TTD短>Debuff即将断补>BOSS/精英>远距离排序
猎人 焦点钉刺智能优先级.剩余<3秒时强制补.主目标钉刺让位
术士 焦点腐蚀术智能优先级.剩余<3秒时强制补

-- === 防骑团本循环风格选项 ===
防骑 团本循环新增「仇恨向/生存向」切换选项.菜单路径：循环模式→团本循环
防骑 仇恨向：正义之锤(AOE)>正义盾击>奉献>神圣之盾(优先) 优先建立稳定仇恨
防骑 生存向：神圣之盾(优先)>正义盾击>奉献>正义之锤(AOE) 优先格挡减伤生存

-- === UI界面优化 ===
界面 窗口宽度从230px扩展至280px(+22%).默认高度从310px扩展至380px(+23%)
界面 滑块宽度从110px扩展至180px(+64%).更容易拖拽操作
界面 控件垂直间距从25px增加至35px(+40%).视觉更清晰
界面 屏蔽控件(近战/远程/坦克)间距从10px增加至25px(+150%)
界面 标签与复选框间距从-2px调整至5px.更好读
界面 新增全局Tooltip提示系统.鼠标悬停显示功能说明和快捷命令
界面 跟随控件新增3个快捷命令提示：WR_SetAutoFollow(true/false)/WR_ToggleAutoFollow()
界面 图标缩放/透明度滑块新增Tooltip说明
界面 配置切换按钮新增Tooltip说明和快捷命令
界面 屏蔽标签简化为「近战/远程/坦克」.详细说明移至Tooltip
界面 WCL模式下拉菜单宽度从130px扩展至160px
界面 顶部间距优化.图标区域更宽敞
界面 配置窗口可拖拽缩放.右下角新增拖拽调整大小功能

-- === 猎人新增功能 ===
猎人 新增冰冻之箭插入功能.射击/兽王/生存专精均可使用.开启后按快捷键自动释放冰冻之箭
猎人 射击专精新增WR_LR_SJL_BZJJ()函数.检测冰冻之箭可用时自动显示图标
猎人 兽王专精新增WR_LR_SWL_BZJJ()函数.与射击专精逻辑一致
猎人 生存专精新增WR_LR_SCL_BZJJ()函数.与射击/兽王逻辑一致
猎人 射击/兽王/生存主循环插入区域新增冰冻之箭调用.位于冰霜陷阱之后
猎人 菜单新增冰冻之箭开关.
  - 射击: 第7行第5列
  - 兽王: 第7行第4列
  - 生存: 第7行第4列
猎人 新增3个冰冻之箭宏:
  - ALT-CTRL-SHIFT-F1(81): 焦点冰冻之箭
  - ALT-CTRL-SHIFT-F8(88): 目标冰冻之箭
  - ALT-F1(91): 指向冰冻之箭(备用)
  - ALT-NUMPAD0(30): 指向冰冻之箭(原有)

【时光服】2026-7-26-16:00
猎人3系 优化稳固逻辑
奶萨 修复小强战斗的bug
戒律牧 小强P3改为只有中了debuff才会用联结

【时光服】2026-7-26-13:40
3系骑士 自动祝福现在只在战斗外补你选定的那一系.不会补小的不会智能补

【时光服】2026-7-26-12:00
鸟德 开关重新排列更容易看懂.默认重置状态优化.自动哈卡吹风屏蔽了坦克职责

【时光服】2026-7-25-23:00
盗贼 优化冰吼的消失

【时光服】2026-7-24-22:50
敏锐贼 多目标优先级优化
盗贼 自动上毒优化.不在会连续施法
萨满 自动武器附魔优化
猎人 杀戮命令优化 误导优化只在开打前15秒使用
奶萨 修复小强乱加的bug
开关界面调整 新增 功能设置开关 近战aoe屏蔽和远程多线屏蔽目标可以diy了

【时光服】2026-7-24-15:50
修复 关闭偷药也可能失效的问题
盗贼的自动潜行关联到DBM倒数1秒

【时光服】2026-7-24-11:00
战斗贼 修复一个aoe问题
全职业增加一个偷药开关.不想要可以关闭

【时光服】2026-7-23-18:30
武器战 冰DK 增加一个自动喝不灭开关 用法和急速一样.同时开是先喝速度自己注意关闭速度药水

【时光服】2026-7-22-17:50
邪DK 关闭倒数偷药功能

【时光服】2026-7-22-16:25
戒律牧 增加一个目标愈合祷言开关.如果你有选目标 满足血量条件会优先扔给目标.然后才是坦克
全团盾和填充盾排除坦克目标

【时光服】2026-7-22-15:30
戒律牧 修复不会上盾问题

【时光服】2026-7-22-2:20
所有按键调整 不在需要调整英伟达按键
火法 修复镜像问题

【时光服】2026-7-21-22:25
自动吃药功能可以适配DBM倒数1秒吃
优化猎人 误导变黑不会打功能
狂暴战 鲁莽会在dbm倒数1秒提前开

【时光服】2026-7-21-21:10
敏锐贼 优化平a出消失问题 优化消失逻辑

【时光服】2026-7-21-13:45
所有职业的手套功能现在自带工程及400点判断.如果你删除了工程以后手套附魔还在的话不再会卡住手套

【时光服】2026-7-21-11:30
戒律牧 暗影魔滑条控制
暗牧 渊改为只对boss生效
法师 自动冰箱的哈卡改为判断boss战斗.不需要目标
鸟德 星火和愤怒填充临界点优化

【时光服】2026-7-19-23:10
刺杀贼 灭绝消失开关修复.现在关联到boss才会用

【时光服】2026-7-19-16:30
鸟德 适配新急速算法

【时光服】2026-7-19-11:00
治疗 所有治疗优化.滑动开关按技能优先级从上到下顺序排列.可以更清晰的设置自己想让他怎么加
奶骑 审判增加一个模式选择
所有职业帧数优化
鸟德 修复会发呆问题
惩戒骑 爆发关联矮人天赋

【时光服】2026-7-18-15:40
火法 修复一个炎宝术在饰品触发末端报错导致发呆的问题

【时光服】2026-7-17-15:30
奶萨,戒律牧,神牧 增加进攻驱散开关.用法是选目标自动驱散

【时光服】2026-7-16-21:40
敏锐贼 放宽了暗影之舞的启动条件.不在需要目标身上一定要有印记.(我翻了一下100分现在也是这么打)
毁灭术 删除了完美循环测试开关

【时光服】2026-7-16-20:20
惩戒骑 增加了一个起手2+3分开祈求的逻辑开关
鸟德 优化了月之选民期的逻辑

【时光服】7-15-19:28
修复更新日志部分客户端乱闪/错字
防骑增加祝福选项（与奶骑相同，可禁用）

【时光服】7-14-0:20
火法修复 指向炸弹BUG
火法修复无法连击炎爆问题

【时光服】2026-7-12-17:47
精修版 增加 刺杀贼 完美循环 （刺杀现在很猛）
精修版 刺杀贼 消失续灭绝（爆发/嗜血/英勇多模式）
精修版包含（狂暴战 暗牧 冰法 鸟德 毁灭 战斗贼 刺杀贼）
精修版P5版本只有年卡以上能用，目前免费
------【请用5.2登陆器才能更新到】--------
面板右下角可以开关文字提示
刺杀贼：消失逻辑重新调整
敏锐贼：切割/割裂条件优化
鸟德：修复层数计算错误导致卡轨道炮
鸟德：轨道炮「同步」改「BOSS」开关 + 5 秒预计死亡预判
鸟德：自动吃药改到轨道炮前
戒律牧：修复死亡卡愈合祷言
奶萨：治疗链优先级调整
奶德：宁静增加全团血量预测自动释放
奶德：新增 99% 无脑回春、宁静插入开关
奶萨/奶德/奶骑：优化治疗逻辑和开关
奶萨/奶德/奶骑：血肉成灰特殊处理
大幅优化治疗帧数
修复邪DK切脸问题
修复暗牧焦点不上痛问题
修复火法不会指向炸弹问题
删除 自动跟随功能(有点越线）放弃

【时光服】2026-7-9-20:09
鸟德 适配3层模式
惩戒骑 爆发期优先审判
狂暴战 增加一个无脑英勇开关(毕业装可以打开,不丢平a)
鸟德 增加一个断条的精准预判
术士 增加一个断条的精准预判
法 修复一个深度冻结的bug
修复主城 乱开爆发BUG
鸟德 插入宁静按钮 重新加入
修复所有职业 没有进战斗 爆发药水乱放问题
启动暂停会失控，角色乱跑
冰法 修复深度冻结相关 bug

【时光服】2026-7-5-3:26
全职业 修复主城点开始无目标无战斗误开爆发
全职业 优化进战斗起手卡顿
精修版 增加 毁灭术 完美循环
精修版 增加 鸟德  完美循环
精修版目前（狂暴战 暗牧 冰法 鸟德 毁灭 战斗贼）
精修版P5版本只有年卡以上能用，目前免费
---------------------------------
增加一个 重置设置按钮（进游戏默认配置就很猛）
血DK修复单体技能循环不打问题
血DK 龙类停手逻辑（防止误点）
血DK 优化DK的双目标逻辑.会优先使用心脏打击
邪DK 增加一个凋零缠绕的能量控制开关和一个是否使用的总开关.方便手动挡
修复冰法会自动放吹风冰环问题
修复鸟德不会自动变形问题
鸟德 填充的星火增加一个判断
鸟德 修复一个饰品开过早问题
鸟德 星火算法加入愤怒急速兜底机制.
鸟德 优化层数计算和同步轨道炮逻辑.稳定不坠机
当填充愤怒施法条小于1的情况下会优先打星火术
当自然之赐的剩余时间小于一个愤怒的施法时间优先释放星火
树德 加入 插入宁静功能
修复元素萨满不能自动放图腾问题
冰法 逻辑重做提升DPS
冰法 手套关联在冰冷血脉或者冰脸血脉CD没好的情况.
冰法 智能aoe屏蔽了双子.这样双子也可以常开没影响了
不会一直卡CD打,移除了移动冰枪和火冲
火法 修复素质5连开关
敏锐贼 修复若干问题
敏锐贼 消失的GCD控制优化
敏锐贼 没有影舞的技能的乱舞天赋出血改到60能量
刺杀贼 优化冷血 有乱舞+嫁祸诀窍 或者有乱舞嫁祸CD 或者有嫁祸 乱舞CD
暗牧 修复 断病BUG
暗牧 渊增加一个死亡预判.死亡时间大于<6不再开启渊
猎人 修复一个站最远距离不会开爆发的bug
毁灭术 修复近战位开关不移动不会喷问题
毁灭术 移动的猪头喷改为单独开关可控
防战 修复一个不打毁灭的问题
防战 5破提到最高优先级.只对boss目标生效 ,由破甲开关控制
法系的取消关注和专注也关联在WCL开关里了.
盗贼 3系盗贼增加一个剑刃乱舞开启条件列表 配合下方乱舞开关使用
毁灭术 冰法 加回了宝宝攻击.能多打1.2W.不打的时候还是自己不要常开吧.
防止宝宝add之类的(理论上应该不会)
城里可以正常的关血条  
法系职业可以正常的自动取消专注了.



【时光服】6-27-17:24
精修版 增加狂暴战（打开WCL模式选冲分）
WCL模式开关：选冲分 只打计分的小怪
精修版 目前支持（冰法  暗牧  战斗贼  狂暴战 ）
精修版  其他职业陆续增加
精修版目前免费测试 后续年卡免费使用
6月30日下架永久卡 要买的抓紧
---------------
优化界面 增加透明度 
优化界面  图标大小缩放
优化界面  右下角窗体大小控制
全职业增加WCL 计分模式
打开为屏蔽所有不算分小怪.关闭所有怪都会打
敏锐贼：没有影舞时，乱舞天赋出血改到 60 能量
邪 DK：新增 换武器（装备管理器：十字军 / 黑魔法 两套）
自己用系统自带的装备管理器保存一套叫十字军 一套叫黑魔法即可
姓名板：城里可正常关闭
毁灭术：4T5 混乱箭 / 烧尽 时间计算更精细
毁灭术：预判层数错误问题修复

【时光服】6-27-1:58
精修版 增加 冰法（打开WCL模式选冲分）
WCL模式开关：选冲分 远程2+1 近战2+1 记得点上
冲分版 一定要带速度药水 不然时间轴会推迟
好不好用请反馈给客服再做修复
--------------------------
精修版 目前支持（冰法 暗牧  战斗贼  狂暴战）
精修版  其他职业陆续增加
精修版目前免费测试 后续年卡免费使用
6月30日下架永久卡 要买的抓紧
-------------------------

【时光服】6-25-15:41
精修版 增加狂暴战（打开WCL模式选冲分）
WCL模式开关：选冲分 只打计分的小怪
精修版 目前支持（暗牧  战斗贼  狂暴战）
精修版  其他职业陆续增加
精修版目前免费测试 后续年卡免费使用
6月30日下架永久卡 要买的抓紧
-------------------------------
战斗贼精修版优化循环
添加WCL名单，后续全DPS都会出开关
修复狂暴战精修版 老虎二阶段 TOC老2 小强 单体和AOE识别问题
修复战斗贼精修版 多目标割裂去除 直接打五星剔骨
所有DPS职业增加 【取消灌注/专注】 防止别人恶搞
毁灭术 暗影印记 / 余烬印记 预判层数逻辑重写
兽王排除「蹒跚的血僵尸」
暗牧精修版 再次加强坠机风险

【时光服】6-23-17:45
盗贼 修复 菊花茶 失效
盗贼三系 增加祖格饰品识别和判断
敏锐贼 修复 暗影之舞发呆问题
敏锐贼 锁喉开关重新加上 不影响第一个超级锁
武器战 狂暴战 祖格饰品 怒气判断
毁灭术 监控印记层数优化 更精准
血DK增加灵界打击 血量控制 
冰法删除移动冰枪

【时光服】6-22-3:55
精修版上线~（暗牧，战斗贼）
精修版免条件测试一个月，慢慢补全其他职业
精修版使用条件（年卡以上用户）
精修版正式版预计P5上线
精修版循环均以WCL满分循环运作
（自备高级药水猴戏材料，装备差打不出来）
------------------------------
增强萨 修复 打完脱战还会招狼的BUG
增强萨 修复 起手 不开爆发问题
修复毁灭焦点献祭失效
修复猎人焦点钉刺失效
修复暗牧焦点痛失效
武器战和狂暴战的饰品功能 重新做开关 
防战 增加一个致死打击判断(复仇战才有)
恶魔术 增加一个全局偷灭杀
血DK 输出血的刃舞自带饰品手套

【时光服】6-20-2:50
法系适配 狂野魔精药水 如果身上有带魔精 
打开自动狂野魔法的开关优先吃魔精
武器战 增加一个斩杀开关
武器战 大风车增加距离判断 大风车的时候会开启饰品
武器战 增加一个 自动饰品开关
狂暴战 增加一个焦点破甲功能在不占用嗜血和旋风的情况下.
狂暴战 增加血性狂暴按钮自动判断
修复一个吃狂野药水的bug
TOC 阵营冠军 / 双子防 ADD 加强 防止ADD
敏锐贼 修复一个影舞的bug 
敏锐伤害型消失对冰吼也添加了屏蔽.只留了躲技能

【时光服】6-19-16:25
战斗贼 更改 非匕首开关的循环
切割 → 剑舞 → 背刺 → 杀戮 → 背刺 → 冲动
CJQ修复 制裁BUG问题 
CJQ 群AOE问题 修复
元素萨 增加 火焰星星开关（自选）
元素萨（火爹出来以后就会打火焰新星）
修复敏锐贼 打不高的技能循序问题
修复冰法2+1 判断问题 

【时光服】6-17-01:17
狂暴战 英勇怒气控制bug修复
暗牧 增加渊开关，删除疫病和震爆开关
暗牧 超高急速打完渊发呆问题修复
盗贼三系刀扇 数量可以选
法师修复自动吃宝石逻辑
法师修复哈卡虹吸冰箱修复
法师修复脱战还放吹风BUG
惩戒骑全局锤子延时指向修复
战士TOC老1顺劈斩解锁
战斗贼重新做逻辑
战斗贼增加主匕首开关
战斗贼增加：割裂+切割都在且目标能活 ≥8 秒 → 5 星刺骨
战斗贼现在剑舞期间一律允许维护切割
战斗贼菊花茶只在BOSS战会自动喝

时光服 6-14-03:09
盗贼 修复自动上毒问题.
敏锐贼 优化aoe天赋的消失.取消了自动菊花茶
敏锐贼 能量控制优化
冰法近战AOE改为只能AOE
暗牧 增加 渊后专注灭的最大伤害逻辑
暗牧 修复 渊的引导坠机概率
暗牧修复 输出逻辑 以超级痛为主
战斗贼：P4 单体起手对齐 WCL榜单：
破甲→乱舞→杀戮→割裂→冲动→刺骨
TOC/ZG 多目标：阵营冠军刀扇、双子不乱舞刀扇、转嫁转火
开关必须点：自动乱舞 / 杀戮 / 冲动 / 手套种族饰品
冰法 惩戒骑 修复偶尔丢失目标 锁定BOSS选开

时光服 6-13-16:07
修复邪DK凋零单体不打逻辑
狂暴战多目标识别修复

时光服 6-13-4:45
奶萨 小强P3 剔除治疗链只刷刺骨和坦克次波+激流
邪DK 天打天赋 修复自动凋零无法识别单体
邪DK 天打天赋 天打逻辑调整重写
冰法 修复 爆发有寒冰指 立刻深结
冰法 修复 深结后冰枪 被距离限制
冰法 修复 浪费 寒冰指/碎冰
冰法 修复 吹风2+1不灵BUG
狂暴战 猛击默认改为 填充
狂暴战 面板增加 英勇 顺劈斩 怒气选择（默认50%）
狂暴战 调整技能优先级 嗜血 / 旋风 / 猛击 → 再顺劈或英勇
狂暴战 修复纯单体 BOSS 英勇过多
狂暴战 怒气管理 问题，改善单体与多目标 BOSS 伤害表现

时光服 6-11-23:31
暗牧优化补噬灵疫病阈值
暗牧渊读条后解锁时间随急速缩放
鸟德修复饰品和工程手套
冰法修复换登陆器2+1逻辑失效问题
（如有好的建议随时反馈客服）

时光服 6-11-13:14"
武器战 优化AOE 超过3怪智能顺劈，2只怪横扫偏向英勇
暗牧 适配新更新 有问题反馈 
毁灭术 分流优化
CJQ 命令光环修复
DK 修复霸权印记不开问题

时光服 6-10-18:49
修复FQ 循环BUG
骑士增加光明圣印按钮和禁用选项
修复治疗无法循环BUG
修复盗贼 一直上毒问题

时光服 6-9-01:05
邪DK 自动工程手套提前到大军/天鬼前面
邪DK 天赋菜单更换名字 邪要堆够263命中 否则断病乱循环
适配适配水晶之心
毁灭术 增加厄运诅咒开关
武器战 有横扫时优先英勇，无横扫才智能顺劈
元素萨满 雷霆风暴增加自动用开关（低于蓝80%开始工作）））
暗牧 修复暗牧上天开手套掉下来的bug,增加哈卡的自动躲吸,冰吼暂时还没搞定
修复吃药卡狂野魔法问题
敏锐贼 十字军老1前面几个boss不再会自动使用消失
血领主 冰吼 有几个近战不再会自动取消自动保护之手
毁灭术 修复一个献祭不加层数计算的bug
暗牧 修复一个升天开饰品掉下来问题

时光服 6-6-05:27
邪DK 优化自动起手.应该可以留能量了.
暗牧 修复一个灭的bug
删除邪DK完美起手，放弃这种固定轴逻辑
再次优化血肉治疗职业只放读条过量技能

时光服 6-5-01:30
双子BOSS切BOSS发呆问题修复
优化血肉治疗过量刷血肉成灰
邪DK toc老1自动起手15码应该可以正常释放天鬼了
敏锐贼的乱舞期间的消失和伺机待发应该能正常开启了
猫德 蜘蛛网增加一个判断.如果你触发无法打背的错误提示也会猫变猫.充实整体逻辑
新暗牧修复引导被打断的BUG
新暗牧适配循环 有问题请反馈

时光服 6-4-01:24
邪DK 修复靠嗜血激活的天鬼大军会先放完大军才吃药的问题
邪DK 恶意双持 重新优化起手7.5S天灾优先级
修复治疗 血肉模糊 选中目标发呆问题
修复小强 吸血虫群只刷一个刺骨问题
优化插件按键延迟 和多开屏幕切换卡屏问题

时光服 6-3-02:01
祖格隐藏boss和老虎boss小怪的爆发匹配
冰法虹吸冰箱bug修复
防战和武器战的英勇打击和顺劈斩改为怒气完全自选式
所有主城木桩适配爆发饰品 方便客户测试循环技能
修复DK逻辑不开饰品爆发
治疗增加TOC 老2 血肉 老5 骨刺优先开关和逻辑
（不用手动找血肉队友，和骨刺队友了）

时光服 6-2-04:15
毁灭术 优化一个特定时间点引起暗影灼烧延后的问题.
刺杀贼增加一个自动乱舞功能
3系贼的自动乱舞都改为目标为BOSS.5码内存在多目标激活.不再考虑触发

时光服 6-1-23:56
TOC老3防add优化
猫德 猫变猫只会在打不到的时候解
冰法 2+1的吹风 冰环 冰枪现在有可控开关
猫德 猫德被网了自动猫变猫解(无开关)
盗贼 自动上毒增加非战斗判断
3系法师 哈卡自动冰箱
所有近战职业 aoe屏蔽图腾
增加几个饰品（霸权印记）适配全本 
术士增加焦点献祭开关
DK爆发宏增加赞达拉英雄勋章

时光服 05-31-04:55
刺杀贼 能适配祖格4件套的能量计算
全近战智能aoe屏蔽豹女的祖利安徘徊者.不再会激活aoe
刺杀贼 毒伤毁伤逻辑优化,现在应该可以很精准的控制能量
三系盗贼上毒全部改为主手致命 副手速效
小幅度优化DK输出逻辑

时光服 05-30-02:35 
盗贼自动涂抹修复BUG
DK恶意循环修复逻辑
增加冠军试炼老3爆发
战斗贼 增加武器自动判断功能.主手匕首就打背刺拿非匕首就打影袭
邪DK 修复新的toc老一开关打开无效问题
DK的普通双持天鬼和大军专用改为全天赋生效.嗜血期都会自动天鬼
萨满和暗牧进攻驱散可以驱散目标身上任何魔法

时光服 05-29-17:15
DK修复恶意循环，高优先级的天灾
DK增加一个toc老一的自动起手模式.到天鬼自动停然后回提示.跑出15码自动释放

时光服 05-29-01:35
祖格龙BOSS 凝视自动停手
邪DK加入恶意魔印，请选 「恶意双持邪」，才有天灾 + 魔印凋零逻辑。
惩戒专精新增 「嗜血」 开关身上有 嗜血 或 英勇 buff，且正义+虔诚叠满（共 5 层），自动触发 祈求圣光
盗贼三系：脱战自动上毒 主手优先，再副手
武器速度 ≤ 2.6 秒 → 致命药膏
武器速度 > 2.6 秒 → 速效药膏
奶骑 加入回蓝恳求75%50%25%选项
奶骑 泄蓝模式增加仅坦克（可偷刀只刷T）

时光服 05-28-12:21
适配祖格BOSS，适配宝库，爆发
修复治疗跟随小BUG，目前只有治疗有自动跟随

时光服 05-28-03:55
战斗贼 提高爆发的优先级到aoe之前
邪DK 开启天鬼的时候会使用白金战斗圆盘
鸟德增加 自动星落选项（CD好就放）
所有治疗增加自动跟随功能（脱战自动跟随）
时光服 05-25-05:25
毁灭术：优化 烧尽、混乱之箭 逻辑
毁灭术：修复某一轮 暗影印记先到 6 层 的 bug
敏锐贼：十星起手切割加 停止平砍；暗影步后未接上技能则 自动关闭十星；
毁灭术：自动地狱火（不含 4DK）、移动腐蚀术、宝宝 自动攻击BUG；
敏锐贼：优化 伏击 星数判断
敏锐贼：尾刀可能不打毒伤/印记修复；武器/狂暴战：自动碎裂投掷（Boss + 饰品触发 + 主手出手 1.5 秒内）；毁灭术：分流时间、暗影灼烧时机优化
敏锐贼：修复 35% 印记「选正常反而不正常」

时光服 05-22-02:03
武器战 放宽了猛击条件.现在会打更多的猛击
毁灭术 特别处理了分流厄运时机.输出逻辑重新排列.
毁灭术 修复判断叠层 发呆1-2秒问题，双满层且献祭快消失时，也会提示生命分流，放宽暗影层判定。
优化插件内存，优化网吧按键可能失效
时光服 05-20-1:00
毁灭术 叠层逻辑大幅优化.减少烧尽次数
修复卡药水问题(应该可能没问题了)
战斗贼 电男自动屏蔽杀戮.无需关闭了
毁灭术 修复暗影之怒的问题.打在了一个错误的时机
冰法 优化宝宝水箭释放
毁灭术 厄运诅咒屏蔽了4DK
惩戒骑 修复放了祈求以后没层数不打愤怒之锤问题.优化了一下惩戒骑的缝问题
毁灭术 大幅优化小鬼火焰箭速度 现在小鬼攻击无法被关闭.开关已经失去了作用.开怪就会一直打,删除了移动腐蚀术

时光服 05-15-00:19
冰法 优化了一下爆发宝石 手套 炸弹等吃掉2+1的问题
火法 优化自动镜像改到饰品触发
毁灭术 双燃烧轮增加一个暗影之怒功能.请鼠标指向怪物.所有技术都是预判.默认你打到了.你扔歪了层数计算会有问题导致提前流星
毁灭术 降低烧尽优先级

时光服 05-13-20:40
惩戒骑 光掌部分也关联进专注开关了.以及优先级调整
时光服 05-12-18:30
适配了一个网吧不能用的按键
海啸 六分仪 冷却适配
时光服 05-12-0:51
盗贼 修复蜘蛛3失败被捆会浪费消失问题.修改马上喷射期间的帧数刷新.应该能更稳定的躲过喷射
敏锐贼 优化35%以下印记.现在应该不会被切割干扰断割裂了.
时光服 2026-05-11-1:30
盗贼 修复盗贼蜘蛛3问题
时光服 2026-05-10-1:00
惩戒骑 修复一个专注光环被别人强化专注覆盖以后无限专注光环的bug
盗贼 蜘蛛3的消失改为反应式.蜘蛛喷射瞬间消失.时间应该是足够的
时光服 2026-05-10-0:15
冰法 修复不会深度冻结和吹风问题
自动爆发判断增加 黑龙的3条小龙
修复不吃药水bug
时光服 2026-05-09-14:30
惩戒骑 优化整体输出循环.风暴正常模式就可以全部优先叠5层.5层以后正常优先
敏锐贼 优化印记间输出
惩戒骑开祈求前3秒有提示
时光服 2026-05-09-10:35
冰法 修复GCD<1的时候没有正确的先释放深度冻结和霜火箭的问题.
时光服 2026-05-09-00:50
惩戒骑 修复别人开光掌导致你一直切专注的bug
冰法 修复GCD1.0几的时候不会打2+1问题
时光服 2026-05-08-12:50
惩戒骑 增加一个专注光环锁定开关.
增加祈求前自动光掌(如果你开的是专注光环)功能
邪DK自动起手内增加诺甘农判断
时光服 2026-05-07-22:00
惩戒骑 修复第二次爆发会先开翅膀问题
敏锐贼 修复伺机待发导致报错无法正常aoe问题
时光服 2026-05-07-21:30
惩戒骑 优化祈求圣光,现在在你自动祈求圣光期间不小心移动以后下次cd好了必然会继续释放.
全职业按键绑定优化.
时光服 2026-05-07-19:20
萨满 修复瘟疫2自动解毒功能的bug.现在带了胸针饰品的小鱼人火人能正确判断了
时光服 2026-05-07-14:10
惩戒骑 优化了一下祈求圣光的插入功能
时光服 2026-05-07-09:20
惩戒骑 新版调整结束.
时光服 2026-05-07-02:20
敏锐贼 修复乱舞敏锐的aoe卡主问题
时光服 2026-05-06-13:50
优化药水问题
盗贼消失调整到40.1秒了
时光服 2026-05-06-13:00
兽王猎 优化输出循环,爆发开启调整到饰品触发
敏锐贼 修复10星无影舞卡主问题,修复多目标卡主问题
时光服 2026-05-05-11:00
敏锐贼 优化十星起手开关的功能
起手的切割 和转嫁会在战斗外开启节约起手时间.注意自己启动器的开启关闭状态
时光服 2026-05-05-2:00
毁灭术 暗影灼烧提示优化
时光服 2026-05-04-12:35
盗贼 蜘蛛3消失再延后0.1秒
敏锐贼aoe增加消失判断.(乱舞期间才会消失)
时光服 2026-05-04-12:10
鸟德 增加一个愈合开关
时光服 2026-05-04-11:30
全职业 修复一个瑞文戴尔男爵不会开爆发以及破甲相关问题
猎人误导重做成类似盗贼嫁祸
射击猎 循环增加奥术射击
时光服 2026-05-03-21:15
敏锐贼 如果出剑刃乱舞的时候能正确的打剔骨.多目标身上有乱舞直接剔骨.多目标没乱舞会先对主目标上割裂.再剔骨
时光服 2026-05-03-19:30
敏锐贼 修复十星起手,自己没开破甲别人又没打破甲不打影舞的bug.
时光服 2026-05-02-22:10
武器战 饰品触发关联大风车.
熊德 割伤会在小于5秒就补防止意外断5层
时光服 2026-05-02-00:00
萨满 修复火元素解毒失败问题
时光服 2026-05-01-22:45
敏锐贼 增加一个10星自动起手开关.前提:你身上必须有个5星的转嫁已保存.开打前身上要有星开切割(我做的几星都可以).
切割>转嫁>死亡印记>暗影步>预谋>锁喉>割裂(5星)>破甲(开关控制),暗影之舞--然后自动会关闭10星开关 单次循环
]]

-- ★ 暴露为全局变量供功能设置界面内联显示
MyAddonUpdateContent = UpdateContent

-- ==========================================
-- 创建更新日志窗口框架
-- ==========================================

local UpdateFrame = CreateFrame("Frame", "MyAddonUpdateFrame", UIParent, "BackdropTemplate")
UpdateFrame:SetSize(450, 480)                      -- 窗口宽450，高480
UpdateFrame:SetPoint("CENTER")                    -- 居中显示
UpdateFrame:SetFrameStrata("DIALOG")              -- 对话框层级
UpdateFrame:Hide()                                -- 初始隐藏

-- 设置背景和边框样式（★ 2026-08-21：去掉外框体边框，仅深色底，与功能设置界面风格统一）
UpdateFrame:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
  edgeFile = nil,
  tile = true,
  tileSize = 32,
  edgeSize = 0,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
UpdateFrame:SetBackdropColor(0.28, 0.28, 0.28, 1)

-- 允许窗口拖动
UpdateFrame:SetMovable(true)
UpdateFrame:EnableMouse(true)
UpdateFrame:RegisterForDrag("LeftButton")
UpdateFrame:SetScript("OnDragStart", UpdateFrame.StartMoving)
UpdateFrame:SetScript("OnDragStop", UpdateFrame.StopMovingOrSizing)

-- ==========================================
-- 标题栏
-- ==========================================
local Title = UpdateFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
Title:SetPoint("TOP", UpdateFrame, "TOP", 0, -20)
Title:SetWidth(400)
Title:SetJustifyH("CENTER")
Title:SetSpacing(4)
Title:SetText(
  "|cffFFD100 更新日志|r" ..
  "|cff888888(" .. CurrentVersion .. ")|r"
)

-- ==========================================
-- 关闭按钮（右上角X）
-- ==========================================
local CloseBtnTopRight = CreateFrame("Button", nil, UpdateFrame, "UIPanelCloseButton")
CloseBtnTopRight:SetPoint("TOPRIGHT", -5, -5)

-- 返回功能设置按钮
local backToSettingsBtn = CreateFrame("Button", nil, UpdateFrame, "UIPanelButtonTemplate")
backToSettingsBtn:SetSize(100, 24)
backToSettingsBtn:SetPoint("TOPRIGHT", CloseBtnTopRight, "TOPLEFT", -2, 0)
backToSettingsBtn:SetText("返回功能设置")
backToSettingsBtn:SetScript("OnClick", function()
    UpdateFrame:Hide()
    if ZZ_MonsterBlockFrame then
        ZZ_MonsterBlockFrame:Show()
    end
end)

-- ==========================================
-- "我知道了" 按钮（底部）
-- ==========================================
local OkayBtn = CreateFrame("Button", nil, UpdateFrame, "UIPanelButtonTemplate")
OkayBtn:SetSize(120, 30)
OkayBtn:SetPoint("BOTTOM", 0, 15)
OkayBtn:SetText("我知道了")
OkayBtn:SetScript("OnClick", function()
  UpdateFrame:Hide()   -- 点击后隐藏窗口
end)

-- ==========================================
-- 滚动区域（用于显示长文本）
-- ==========================================
local ScrollFrame = CreateFrame("ScrollFrame", "MyAddonScrollFrame", UpdateFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 25, -50)
ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 55)
WR_StyleScrollBarBlack(ScrollFrame)

local ScrollChild = CreateFrame("Frame", nil, ScrollFrame)
ScrollChild:SetSize(ScrollFrame:GetWidth(), 1)
ScrollFrame:SetScrollChild(ScrollChild)

-- 使用 FontString 展示日志（避免中文乱码/闪烁）
local ContentText = ScrollChild:CreateFontString(nil, "ARTWORK")
ContentText:SetFont(STANDARD_TEXT_FONT, FontSize, "")
ContentText:SetJustifyH("LEFT")
ContentText:SetJustifyV("TOP")
ContentText:SetNonSpaceWrap(true)
ContentText:SetWordWrap(true)
ContentText:SetWidth(360)
ContentText:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 5, -5)

-- ==========================================
-- 刷新显示函数：处理文本中的特殊字符
-- ==========================================
local function RefreshDisplay()
  -- 替换不可见字符为普通空格
  local safeContent = string.gsub(UpdateContent, "\194\160", " ")
  safeContent = string.gsub(safeContent, "\r", "")                     -- 移除回车符
  -- 替换特殊符号为可显示字符（避免部分客户端缺字库显示方块）
  safeContent = string.gsub(safeContent, "\226\134\146", "->")        -- → 改为 ->
  safeContent = string.gsub(safeContent, "\226\137\165", ">=")        -- ≥ 改为 >=
  safeContent = string.gsub(safeContent, "\226\137\164", "<=")        -- ≤ 改为 <=
  ContentText:SetText(safeContent)

  -- 延迟计算文本高度，确保滚动区域正确
  C_Timer.After(0.05, function()
    local rawHeight = ContentText:GetStringHeight() or 100
    if rawHeight < 50 then rawHeight = 100 end
    ScrollChild:SetHeight(rawHeight + 30)
  end)
end

-- ==========================================
-- 重载UI时记录状态（避免重载后重复弹窗）
-- ==========================================
hooksecurefunc("ReloadUI", function()
  if type(MyAddon_SaveData) ~= "table" then
    MyAddon_SaveData = {}
  end
  MyAddon_SaveData.IsReloading = true
end)

-- ==========================================
-- 玩家登录事件：显示更新日志窗口
-- ==========================================
local LogicFrame = CreateFrame("Frame")
LogicFrame:RegisterEvent("PLAYER_LOGIN")
LogicFrame:SetScript("OnEvent", function()
  if type(MyAddon_SaveData) ~= "table" then
    MyAddon_SaveData = {}
  end
  RefreshDisplay()

  -- 只有非重载情况下才显示窗口（重载时不重复弹窗）
  if not MyAddon_SaveData.IsReloading then
        -- UpdateFrame:Show()
  end
  MyAddon_SaveData.IsReloading = false
end)

-- ==========================================
-- 哈希校验（用于版本防篡改/防盗版）
-- ==========================================
do
  local M = 4294967296   -- 2^32，用于无符号整数运算

  -- 取模32位无符号
  local function u(n)
    n = n % M
    if n < 0 then n = n + M end
    return n
  end

  -- 32位无符号乘法
  local function mm(a, b)
    a, b = u(a), u(b)
    local r = 0
    while b > 0 do
      if b % 2 == 1 then
        r = u(r + a)
      end
      a = u(a + a)
      b = math.floor(b / 2)
    end
    return r
  end

  -- BKDR哈希算法（常用于字符串签名）
  local function kh(s)
    local h = 5381
    for i = 1, #s do
      h = u(mm(h, 33) + s:byte(i))
    end
    return h
  end

  -- 生成版本签名：用于服务端校验客户端是否被篡改
  PIG_GxUiStamp = kh((CurrentVersion or "") .. "|" .. #UpdateContent .. "|" .. (_GxSaleTag or "") .. "|pig-gx-v1")
end