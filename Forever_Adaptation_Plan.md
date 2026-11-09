# Forever 适配改动计划（前后对照）

> 面向工程维护者：记录 MKHelperSoD → MKHelperForever 的逐文件改动。
> 设计原则：**加法兼容**——新增代码在 SoD 客户端上全部降级为 no-op，绝不改动既有 SoD 行为路径。

---

## 0. 身份变更（Identity）

| 项 | Before (SoD) | After (Forever) |
|----|--------------|-----------------|
| 插件目录 | `MKHelperSoD/` | `MKHelperForever/`（`cp -r` 后整体重命名） |
| TOC 文件 | `MKHelperSoD.toc` | `MKHelperForever.toc` |
| 图标 | `MKHelperSoD.tga` | `MKHelperForever.tga` |
| 全局字符串 | `MKHelperSoD`（49 处引用） | `MKHelperForever`（全局 `sed` 替换，0 残留） |
| 死亡骑士 | 列入 TOC 加载 | 文件保留磁盘，**移出 TOC 加载顺序**（无限首发无 DK） |

> 残留 `MKHelperSoD` 仅出现在 2 处注释（Forever_Compat.lua / MKHelperForever.toc 的「 lineage 说明」），不影响加载。

---

## 1. TOC 加载顺序重写（`MKHelperForever.toc`）

- `## Interface:` 改为多版本容错列表：`11500,11501,...,11509,12000,12001,12002`（覆盖 SoD 1.15.x + 无限客户端号）。
- `## Title` 增加 zhCN 标记：`|cffFF69B4 MKHelperForever|cff00ff00[魔兽世界：无限]v1.0`；新增 `## X-Client: forever`。
- 新增加载行（顺序敏感）：

| 顺序 | 文件 | 作用 |
|------|------|------|
| 早（Core 前） | `Data\Forever_Content.lua` | 无限首发内容表 |
| 早 | `Data\Forever_Racials.lua` | 10 种族 40 项种族特长 |
| 早 | `Data\Forever_Abilities.lua` | 9 职业天赋主动技能 + 符文存活对照 |
| 早 | `Core\Forever_Compat.lua` | 客户端识别 / 树名归一 / API 兜底 |
| 中（Boss 后） | `Boss\Forever_BossMechanics.lua` | 无限副本注册框架 |
| 末（最后） | `Core\Forever_Hooks.lua` | 3 个钩子 + 登录缝合 |

---

## 2. 专精树名归一（硬阻断 #1）

| 文件 | 改动 |
|------|------|
| `Core/Forever_Compat.lua`（新增） | `WR_Forever.SPEC_ALIAS` 树名映射（元素战斗→元素 / 暗影魔法→暗影 / 野性战斗→野性，含 enUS→zh）；`WR_Forever_NormalizeSpec(name)` 返回归一名或原名 |
| `Core/MainLoop.lua` | `WR_GetMyTalent()` 内 `tabName` 经 `WR_Forever_NormalizeSpec()` 包裹（循环体 + fallback 分支） |
| `Core/Core_Functions.lua` | `WR_GetTalent()` 循环内 `tabName = WR_Forever_NormalizeSpec(tabName)` |

---

## 3. 客户端识别与 API 兜底（`Core/Forever_Compat.lua` 新增）

| 函数 | 作用 |
|------|------|
| `WR_Forever_GetClientInfo()` / `WR_Forever_ClientInfo()` | 探测 `{mode,isForever,isSoD,modeSource}`，依据 `C_Engraving` + 接口号 + `PigSet.FOREVER_MODE` 覆盖；支持 `/mkfclient`、`/mkfmode` |
| `WR_Forever_HasAbility()` / `WR_Forever_HasAnyAbility()` | 经 `WR_SoD_GetSpellID` + `IsPlayerSpell`/`IsSpellKnown`（pcall 保护）检测技能 |
| `WR_Forever_SafeRuneCount()` | 非 DK 返回 0 |
| `WR_Forever_PlayerRace()` / `WR_Forever_RaceToken` | 玩家种族 zh→token |
| `WR_Forever_IsNewRaceCombo()` | 判定天裔 / 亡灵圣骑士 / 矮人萨满 |
| `WR_Forever_GetRacialBursts()` | 取种族爆发技能名 |

---

## 4. 挂钩层（`Core/Forever_Hooks.lua` 新增）

加载期（非事件期）即安装，覆盖 `PLAYER_ENTERING_WORLD` 建宏：

| 钩 | 包裹函数 | 行为 |
|----|----------|------|
| 1 | `WR_GetRuneCount` | 非 DK 且无限模式 → 返回 0（不落 DK API） |
| 2 | `WR_CreateMacro` | 无限模式按玩家实际种族向「种族爆发宏」注入 `/cast 种族技能`，240 字节宏长度保护；译名可经 `WR_Forever_RacialSpellNameOverride` 修正 |
| 3 | `WR_SoD_HasRune` | `status="absent"` 符文键短路返回 false |
| 4 | `PLAYER_LOGIN` 帧 | 合并无限 BOSS 表 + 登录横幅 |

> 每个钩均 `if type(fn) ~= "function" then return false end` + `.__foreverWrapped` 防重入，缺失原函数时安全跳过。

---

## 5. BOSS 注册框架（`Boss/Forever_BossMechanics.lua` 新增）

| 导出 | 作用 |
|------|------|
| `WR_ForeverBossInstances` | 11 座无限副本（9 地下城 + 2 团本），含 zh/en/kind/levelMin/levelMax/zone，`pending=true` |
| `WR_ForeverInstanceByZone` | 按地图 ID 查副本 |
| `WR_Forever_RegisterBoss(bossZH,bossEN,data)` | 填充单 BOSS 机制 |
| `WR_Forever_MergeBossMechanics()` | 并入全局 `WR_BossMechanics`（不覆盖既有键） |
| `WR_Forever_CurrentInstance()` / `WR_Forever_IsInForeverInstance()` | 运行期查询 |
| `/mkfboss list\|now\|merge\|register` | 命令 |

机制表 schema 与 `WR_BossMechanics` 完全一致，可直接并入，无需改职业文件。

---

## 6. 数据层（3 个新增 Data 文件）

| 文件 | 关键导出 | 来源 |
|------|----------|------|
| `Data/Forever_Content.lua` | `WR_ForeverContent`（版本/上线日/等级上限/beta 日/zones/dungeons/raids/battlegrounds/systems/races/combos）+ 辅助函数 | 暴雪嘉年华面板 + 官方资料 |
| `Data/Forever_Racials.lua` | `WR_ForeverRacials`（10 种族 40 项，role 标记 burst/defensive/control/utility/passive，isNew/moved/changed 标志）、`WR_Forever_RacialSpells`、`WR_Forever_RaceToken`、`WR_Forever_NewCombos` | racials 重构资料 |
| `Data/Forever_Abilities.lua` | `WR_ForeverAbilities`（83 主动天赋）、`WR_Forever_AbilityNameZH`、`WR_Forever_BaselineAbilities`、`WR_Forever_ClassRacials`、`WR_Forever_RuneToTalent`（4 档符文存活对照）、`WR_Forever_RuneTierLabel` | `_ft_data.json` + `_ft_zh_*.json`（生成器 `_ftgen_abilities.js`） |

> `WR_Forever_RuneToTalent` 4 档状态：`talent`（同名 EN 名保留）/ `ability`（zh 名命中）/ `referenced`（被其他天赋描述引用）/ `absent`（未见于无限天赋数据，可能基础技能或已移除，需上线核对）。**非删除标记**。

---

## 7. 验证记录

| 项 | 结果 |
|----|------|
| Lua 5.1 全量语法回归（154 文件） | ✅ 0 错误 |
| 残留 `MKHelperSoD` 字符串 | ✅ 0（仅 2 处 lineage 注释） |
| DeathKnight 加载行（TOC） | ✅ 0（仅注释说明保留） |
| 引用全局符号可解析（`WR_Show`/`WR_GetRuneCount`/`WR_CreateMacro`/`WR_SoD_HasRune` 等） | ✅ 全部存在 |
| `WR_Show` 表声明 | ✅ `MainLoop.lua:3` `WR_Show = WR_Show or {}` |

### 修复记录
- `Data/Forever_Abilities.lua:401` 生成器误用 `"talent" = "天赋"`（非法 Lua 表字面量）→ 改为 `["talent"] = "天赋"`；根因 `_ftgen_abilities.js:258` 同步修正为括号键形式，避免重生成复现。

---

## 8. 后续工作（待用户/beta 触发）

- [ ] 逐职业核对天赋主动技能识别（上线后）
- [ ] 三套新组合（天裔/亡灵骑/矮人萨）专属旋转适配
- [ ] 11 座副本 BOSS 机制实测填充（`/mkfboss register`）
- [ ] 真实 zhCN 种族技能名核对 → 修正 `WR_Forever_RacialSpellNameOverride`
- [ ] 真客户端接口号确认 → 必要时扩 TOC `## Interface` 列表
