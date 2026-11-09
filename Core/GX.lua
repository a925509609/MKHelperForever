-- ==========================================
-- 【游戏助手】更新日志配置区
-- ==========================================

-- 当前版本号（用于显示和哈希校验）
local CurrentVersion = "2026-8-30"

-- 销售标识（防盗版标记）
local _GxSaleTag = "9"

-- 日志内容字体大小
local FontSize = 16

-- ==========================================
-- 更新日志正文（按时间倒序排列）
-- ==========================================
local UpdateContent = [[

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