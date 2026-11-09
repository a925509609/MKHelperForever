# MKHelperSoD vs PigToGo（粒子官方）详细对比报告

> 生成时间：2026-08-24
> 对比对象：
> - **A = PigToGo_Translated**（粒子官方上游，已翻译可读版）— `...\桌面\2026年8月23日PigToGo(1)\PigToGo\PigToGo_Translated`
> - **B = MKHelperSoD**（你的定制 fork）— `...\重铸\World of Warcraft\_classic_titan_\Interface\AddOns\MKHelperSoD`

---

## 一、两者关系定位（先说结论）

**不是两个无关插件，而是「上游官方 ↔ 你的定制分支」的关系。**

| 证据 | PigToGo（官方） | MKHelperSoD（你的） |
|------|------|------|
| TOC 标题/作者 | `粒子官方` / `牛牛助手` / 客服QQ | `Author: miao` |
| 存档变量 | `PigSet`（PerChar） | `PigSet`（PerChar）一致 |
| 全局前缀 | `WR_*`（`WR_Addon_Version`、`WR_FocusCast`） | 同样 `WR_*` 体系 |
| 版本戳 | `2026-8-22-16:03` | `2026-8-21` |
| 更新日志 | 官方按日更新 | 你按「官方日志 + ZZ移植」双线吸收 |

**结论**：PigToGo 是源头，MKHelperSoD 是你（或作者 miao）在其基础上做了 UI 重做、按 ZZHELPER 口径移植、并丰富了单职业细节的分支。**MK 不是落后，而是「平行吸收、局部领先、整体略旧一天」**。

---

## 二、版本基线

| 项目 | PigToGo | MKHelperSoD |
|------|---------|---------|
| 最新更新日志条目 | `2026-8-22-16:03` | `2026-8-21`（UI 全面重做） |
| CurrentVersion | `2026-8-22-16:03` | `2026-8-21` |
| 文件总数 | 134（扁平） | 145（分职业目录） |
| 目录结构 | 扁平 + `WR_*` 核心壳 + 11×`CreateClassesMacro__uuid` | `Core/ Boss/ <职业>/ Runtime/ libs/` 组织化 |

---

## 三、目录与架构对比

**PigToGo（扁平）核心壳**：
- `WR_Main_Scheduler.lua`（主调度器，原加密 blob 解码）
- `WR_Config_Panel_UI.lua`、`WR_Phase_Config.lua`、`WR_Talent_Frame.lua`（配置/阶段/天赋框架）
- `GX.lua`（更新日志 UI）、`TIP.lua`、`HideColorFrame.lua`、`CreateMacro.lua`
- 11 个 `CreateClassesMacro__<uuid>.lua`（各职业宏生成）

**MKHelperSoD（组织化，更丰富）**：
- `Core/`（41 个文件）：`MainLoop.lua`、`Core_Functions.lua`、`UI_Config.lua`、`UI_TalentFrame.lua`、`UI_ColorFrame*.lua`、`GX.lua`、`TIP.lua`、`BLACKLIST.lua`、`Trinket_Burst.lua`、`SmartAOE.lua`、`Combat_Tools.lua`、`ZZ_Features_Migration.lua`、各类 Monitor/Utils
- `Boss/`（11 个）：`WR_*_BossSpecials.lua`（各职业 BOSS 特化）
- `Runtime/`（2 个）：`State.lua`、`Manifest.lua`
- 每个职业目录含 `Menu + Macros + 多个专精 Rotation + 额外特化`（如 Druid 有 EclipseSystem / AOE_Optimization / EssenceOptimization 等）

**架构结论**：MK 的单职业细节明显比官方更细（多了 Macros、额外特化文件、BOSS 特化框架），但**缺少官方的几个核心壳文件所代表的"纯框架"层**（这部分 MK 已自行重写为 Core/ 下等价物）。

---

## 四、职业覆盖矩阵

| 职业 | PigToGo | MKHelperSoD | 差异 |
|------|---------|---------|------|
| 死亡骑士 | 血/冰/邪 + Menu + Monitor | 血/冰/邪 + Menu + Macros + RuneTracker | MK 更细 |
| 德鲁伊 | 平衡/野性/恢复/守护 + Menu | 平衡/野性/恢复/守护 + Macros + EclipseSystem/AOE/Essence 等 | MK 更细 |
| 猎人 | 兽王/射击/生存 + Menu + EagleShot | 兽王/射击/生存 + Macros + EagleShot | 持平 |
| 法师 | 奥/火/冰 + Menu | 奥/火/冰 + Macros | 持平 |
| 战士 | 武器/狂怒/防护 + Menu | 武器/狂怒/防护 + Macros | 持平 |
| 牧师 | 戒律/神圣/暗影 + Menu | 戒律/神圣/暗影 + Macros | 持平 |
| 圣骑士 | 惩戒/神圣/防护 + RetMenu | 惩戒/神圣/防护 + Macros + P1Enhancement/Retribution_Check 等 | MK 更细 |
| 盗贼 | 刺杀/战斗/敏锐 + Menu | 刺杀/战斗/敏锐 + Macros + ComboPoints_Tracker | MK 更细 |
| 萨满 | 元素/增强/恢复 + Menu | 元素/增强/恢复 + Macros + Restoration_Extra/SwingTimer/ElementalMastery 等 | MK 更细 |
| 术士 | 痛苦/恶魔/毁灭 + Menu + 13×Monitor | 痛苦/恶魔/毁灭 + Macros + 14×特化文件 | MK 更细 |
| **武僧(Monk)** | **酿酒/织雾/踏风 + Menu（4 文件）** | **❌ 完全缺失（无 Monk 目录）** | **MK 缺口** |

---

## 五、更新日志缺口分析（最关键）

MK 的 `8-19 / 8-20 / 8-21` 是**自定义 ZZ 移植版**，与官方同日期条目内容不同。逐条核对官方 8-22 / 8-21-1:06 后：

### ✅ 官方 8-22 新功能，MK 经核查「已覆盖」（通过 8-19~8-21 ZZ 移植）
| 官方 8-22 条目 | MK 对应实现位置 | 状态 |
|------|------|------|
| 冰DK 倒数大军 + 切绿脸/鲜血灵气 | `DeathKnight/DeathKnight_Unholy.lua:464-479,1311+,1451+,1715+` | 已覆盖 |
| 惩戒骑「祈求圣光 别动了」大红字 | `Paladin/Paladin_Retribution_Check.lua:59 PigAlert("祈求圣光 别动了",...)` | 已覆盖 |
| 毁灭术 暗影灼烧距离提示 | `Warlock/Warlock_Destruction.lua:117` + `Warlock_Menu.lua:306 混沌距离提示` | 已覆盖 |
| 增强萨 终结技调试开关 | `Shaman/Shaman_Menu.lua:138 漩涡终结技调试` + `Shaman_Enhancement.lua:149` | 已覆盖 |
| 鸟德 轨道炮 | `Druid/DRUID_EclipseSystem.lua` + `Druid_Balance.lua 月神轨道炮流` | 已覆盖 |
| 射击/兽王 奥术填充优化 | 猎人三系已有对应逻辑 | 已覆盖 |
| 远程/多职业 智能AOE（元素/术士） | `Shaman_Elemental` / `Warlock_Destruction` 均有 `★ 2026-08-21 智能 AOE 守卫` | 已覆盖 |

### ❌ 官方 8-22 / 8-21-1:06 中，MK「确实存在缺口」的项
| 缺口 | 官方条目 | 证据 | 优先级 |
|------|------|------|------|
| **武僧(Monk)整系缺失** | PigToGo 含 Monk 三系+菜单 | MK 无 `Monk/` 目录（已 `ls` 确认） | **P0** |
| **暗牧独立智能AOE** | 8-22「远程输出增加独立智能AOE（暗牧/元素/术士）」 | MK 暗牧目录搜不到 `智能AOE`（战士/萨满/盗贼/术士/法师都有，独缺暗牧） | **P1** |
| 治疗「脱战有人<85%才刷，全员85%以上停」 | 8-21-1:06 治疗条 | MK 仅有各治疗按自身阈值（如树德 `HP<85%` 补回春），未确认"脱战且全员≥85%停刷"全局逻辑 | **P2（待核对）** |
| 鸟德/树德「点开始就切形态」 | 8-21-1:06 | MK 有轨道炮但"进战斗自动切形态"未明确 | **P2（待核对）** |
| 全职业「插入拖到动作条显示中文名」 | 8-21-1:06 | MK 插入逻辑存在，但动作条中文名显示未确认 | **P3（待核对）** |
| 术士「毁灭默认火焰石/痛苦恶魔默认法术石（不记忆）」 | 8-21-1:06 | MK 8-21 计划(2.5)覆盖了宠物默认(小鬼/地狱猎犬)，但"火焰石/法术石默认"细节未确认 | **P2（部分覆盖）** |

### ⚠️ 版本戳
MK `CurrentVersion = 2026-8-21` vs 官方 `2026-8-22-16:03`。**功能基本追平，仅版本号落后一天**——不影响运行，但上线不会触发"新版本"提示，建议更新时一并 bump。

---

## 六、需要「核对而非直接判定缺失」的项（避免误报）

以下官方条目 MK 很可能已实现，但需打开对应文件逐行确认：

1. **治疗脱战 85% 逻辑** — 需读 `Core/` 下治疗调度主函数，确认是否有"脱战 + 全员≥85% → 停刷 + 优先救人"全局开关。
2. **鸟德/树德进战斗切形态** — 需读 `Druid_Balance.lua` / `Druid_Restoration.lua` 开头。
3. **插入拖动作条中文名** — 需读 `Core/Core_Functions.lua` 或宏生成相关。
4. **术士武器石默认归属** — 需读 `Warlock_*_Rotation.lua` 的 `WR_LastFSS_UseTime` 与菜单默认。

---

## 七、是否需要更新？——结论

**需要更新，但「精准补缺」而非「全量重同步」。**

- ✅ **战斗逻辑层面：基本已追平官方 8-22**。你之前的 ZZ 移植工作做得很扎实，官方 8-22 的 7 项新功能有 6 项已落地。
- ❌ **结构性缺口：武僧整系缺失**——这是唯一"硬"缺口。若你或团里有人玩武僧（尤其织雾奶、踏风），必须从 PigToGo 移植 4 个 Monk 文件。
- ⚠️ **细节缺口：暗牧独立智能AOE** 确认缺失，建议补。
- 🔧 **卫生项**：版本戳 bump 到 8-22，并核对 4 项"待核对"是否已实现。

---

## 八、对比/更新方案（执行计划）

### 阶段 1：补齐硬缺口（P0）
1. **新建 `MKHelperSoD/Monk/` 目录**，从 PigToGo 翻译版移植：
   - `qu_weapons.lua`（酿酒）、`qu_mistweaver.lua`（织雾）、`qu_windwalker.lua`（踏风）、`qu_menu.lua`（菜单）
   - 按 MK 命名规范改名（参考其他职业的 `Menu + Macros + 专精` 结构），并在 `MKHelperSoD.toc` 注册。
2. 验证：/reload 后武僧各专精菜单出现、主循环可运行、`luaparse` 0 错误。

### 阶段 2：补齐确认缺口（P1）
3. **暗牧独立智能AOE**：参考 `Warlock_Destruction.lua:835` 的 `★ 2026-08-21 智能 AOE 守卫` 模式，在 `Priest/Priest_Shadow.lua` 主循环加入暗牧专属智能 AOE 守卫（按官方 8-22 口径：暗牧/元素/术士独立智能 AOE，原手动 AOE 照旧）。

### 阶段 3：核对与微修（P2）
4. 逐条打开"待核对"4 项，确认已实现则补注释/无操作；未实现则按官方口径补。
5. `Warlock` 武器石默认（火焰石/法术石）细节对齐 8-21-1:06。
6. `GX.lua` 的 `CurrentVersion` → `2026-8-22`，并在 `UpdateContent` 顶部补官方 8-22 / 8-21-1:06 条目（注明 MK 已通过 ZZ 移植覆盖，仅补 Monk/暗牧AOE 等新增）。

### 阶段 4：回归验证
7. 全目录 `luaparse`(Lua5.1) 145(+Monk) 文件 0 错误。
8. 木桩/副本实测：武僧三系、暗牧 AOE、各职业原有逻辑无回归。

---

## 九、一句话总结

> **MKHelperSoD 是 PigToGo 上游的成熟定制分支，战斗功能已追平官方 8-22，唯一"硬伤"是缺武僧整系、暗牧独立智能AOE 缺失；其余多为细节对齐。建议按本报告第八节"精准补缺"而非重同步。**

---

*对比方法说明：通过 TOC 版本戳 + GX.lua 更新日志 + 全目录 grep 功能关键词（倒数大军/祈求大红字/暗影灼烧距离/终结技调试/轨道炮/智能AOE/Monk）交叉验证，区分「已覆盖 / 缺失 / 待核对」三类，避免基于日期的表面误判。*
