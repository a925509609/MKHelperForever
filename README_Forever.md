# MKHelperForever —— 《魔兽世界：无限》(World of Warcraft: Forever) 适配版

> 本插件是 **MKHelperSoD（探索赛季版）** 的官方「无限」分叉。在原 SoD 逻辑基础上新增客户端识别、专精树名归一、种族特长注入、BOSS 注册框架，**向后兼容 SoD 客户端**（在 SoD 上所有新增逻辑自动降级为 no-op）。

---

## 1. 这是什么

| 项目 | 内容 |
|------|------|
| 适配目标 | 《魔兽世界：无限》/ WoW: Forever（暴雪嘉年华 2026 公布，11 月 5 日全球上线，国服 10 月 6 日 beta） |
| 客户端类型 | Classic+ 常驻 60 级平行服（继承 1.15.x 经典客户端，无资料片） |
| 版本上限 | 等级上限 60，横向内容（无 DK，9 职业） |
| 新增种族 | 中立种族 **天裔 Skyborne**（部落风剪=萨满 / 联盟高阶秩序=法师，均可战/猎/贼/德）；新增组合 **亡灵圣骑士**、**矮人萨满** |
| 取代系统 | 探索赛季「符文」改为重构天赋树 + 种族特长（武器专精移入种族被动） |
| 文件数 | 184（154 个 .lua） |
| 分支来源 | MKHelperSoD（已全量重命名为 MKHelperForever） |

---

## 2. 安装

1. 将 `MKHelperForever` 文件夹整体复制到 WoW 经典客户端 `Interface\AddOns\` 目录下。
2. 登录游戏，在「插件」列表勾选 **MKHelperForever**。
3. **若客户端仍提示「过期插件」**：在插件列表底部勾选 **「加载过期插件 / Load out of date AddOns」**。
   - TOC 已使用多版本容错 `## Interface:` 列表（覆盖 1.15.x 与无限客户端号），正常情况下不会弹过期。

```
World of Warcraft\_classic_titan_\Interface\AddOns\
└── MKHelperForever\
    ├── MKHelperForever.toc
    ├── Data\
    │   ├── Forever_Content.lua     # 无限首发区域/地下城/团本/战场/系统
    │   ├── Forever_Racials.lua     # 10 种族 40 项种族特长（含天裔）
    │   └── Forever_Abilities.lua   # 9 职业天赋主动技能 + SoD 符文存活对照
    ├── Core\
    │   ├── Forever_Compat.lua      # 客户端识别 / 专精树名归一 / API 兜底
    │   └── Forever_Hooks.lua       # 符文守卫 / 种族爆发注入 / 符文短路
    ├── Boss\Forever_BossMechanics.lua  # 无限副本注册表与机制框架
    └── ...（其余继承自 MKHelperSoD）
```

> 死亡骑士相关文件（`DeathKnight\`）保留在磁盘但**未列入 TOC 加载顺序**——无限首发无 DK，后续暴雪开放时可直接恢复。

---

## 3. 客户端模式识别

插件自动识别当前客户端是「无限」还是「探索赛季」：

| 命令 | 作用 |
|------|------|
| `/mkfclient` | 打印客户端诊断（模式来源、接口号、C_Engraving 是否存在） |
| `/mkfmode auto\|forever\|sod` | 手工指定模式（auto = 自动探测） |
| `/mkfforever` | 适配状态总览（专精 / 种族 / 天赋技能数 / 符文存活统计 / 副本数） |
| `/mkfforever rehook` | 重新校验并安装 3 个适配钩子 |

识别依据（`Core/Forever_Compat.lua`）：
- `C_Engraving` API 是否存在（探索赛季有，无限无）→ 核心判据；
- `## Interface` 接口号区间；
- `PigSet.FOREVER_MODE` 手写覆盖（最高优先）。

---

## 4. 关键适配点（三处硬阻断 → 解决方式）

| # | 硬阻断 | 根因 | 解决方案 | 位置 |
|---|--------|------|----------|------|
| 1 | 专精树改名导致专精分发失败 | 萨满「Elemental Combat」→元素战斗、牧师「Shadow Magic」→暗影魔法、德「Feral Combat」→野性战斗 | `WR_Forever_NormalizeSpec()` 注入 `WR_GetMyTalent()` / `WR_GetTalent()` | Core/Forever_Compat.lua + MainLoop.lua + Core_Functions.lua |
| 2 | DK 符文 API 在非 DK 客户端崩溃 | 无限无死亡骑士，`GetRuneCount` 调 DK 专用 API | 钩 1 包裹 `WR_GetRuneCount` → 非 DK 且无限模式返回 0 | Core/Forever_Hooks.lua |
| 3 | 新增种族爆发技能未进宏 | 经典爆发只有狂暴/血性狂怒/狮心；无限新增艾露恩之光/尤里卡！ | 钩 2 包裹 `WR_CreateMacro` → 按玩家实际种族注入 `/cast 种族技能`（240 字节宏长度保护） | Core/Forever_Hooks.lua |

附加：
- 钩 3 包裹 `WR_SoD_HasRune` → 无限中不存在的符文键（`status="absent"`）短路返回 false，省解析开销。
- 钩 4 登录横幅 + 无限 BOSS 表并入全局 `WR_BossMechanics`。

---

## 5. 9/17 公开测试注意事项（上线前必读）

- **种族技能中文名**：`艾露恩之光`、`尤里卡！` 等为依据官方英文名预先译定的「预期客户端名」。真客户端可读后用 `/run` 打印真实名，若不符只需改 `Core/Forever_Hooks.lua` 顶部 `WR_Forever_RacialSpellNameOverride` 表，**无需动逻辑**。
- **天赋主动技能**：`Data/Forever_Abilities.lua` 的 `WR_ForeverAbilities` 依权威「Forever 天赋」数据生成（83 项）。其中 `status="absent"` 的符文表示「未出现在无限天赋数据中，可能为基础技能或已移除，需上线核对」——**不是删除**，仅作标记。
- **BOSS 机制**：`Boss/Forever_BossMechanics.lua` 目前为 11 座副本的**注册框架**（名称/等级/类型已填，机制待 beta 实测）。填充用：
  ```
  /mkfboss register <BOSS中文名> <BOSS英文名>
  -- 或 Lua：WR_Forever_RegisterBoss(bossZH, bossEN, { ...机制表... })
  ```
  机制表 schema 与 `WR_BossMechanics` 完全兼容，可直接并入。
- **真实接口号**：先用 `/run print(select(4,GetBuildInfo()))` 确认；若不在 TOC 列表内，按第 2 节开启「加载过期插件」。

---

## 6. 已知限制

- 旋转/循环逻辑仍复用 SoD 的「符文=法术书技能」判定（`WR_SoD_HasRune` 走 `IsPlayerSpell`），在无限下对真实存在的天赋技能天然兼容；上线后需逐职业核对天赋主动技是否都被正确识别。
- 亡灵圣骑士 / 矮人萨满 / 天裔 三套新组合尚未做专属旋转适配，目前按对应职业通用逻辑运行。
- BOSS 机制条目为占位 `pending=true`，需 beta 实测后补全。

---

## 7. 改动追溯

工程级 before/after 改动对照见同目录 **`Forever_Adaptation_Plan.md`**。
语法质量门禁：全量 154 个 .lua 通过 Lua 5.1 解析（0 错误）。
