# MKHelperSoD 移植逻辑一致性审计（PigToGo 官方 ↔ MK 移植版）

*生成时间：2026-08-24*
*方法：对"声称已移植覆盖"的功能，逐功能把 MK 的实现与 PigToGo 官方源码（`PigToGo_Translated/`）并排对照，核对触发条件 / 阈值 / 行为是否一致。*

---

## 结论速览

| 功能 | 官方位置 | MK 位置 | 逻辑是否一致 | 等级 |
|------|---------|---------|------------|------|
| 冰DK 亡者大军（倒数大军） | `DeathKnight_Frost_Rotation.lua` `WR_DK_BDK_CountdownArmy` | `DeathKnight_Frost.lua:521` `WR_DK_BDK_CRWZDJ` | **大体一致，时序/灵气切换不同** | P2 |
| 毁灭术 暗影灼烧距离提示 | `Warlock_Destruction_Rotation.lua:21` `WR_SS_HM_ShadowburnRangeTip` | `Warlock_Destruction.lua:115` | **一致** | ✅ |
| 惩戒骑 祈求圣光"别动了" | `Paladin_Retribution_Rotation.lua:1463` + 调用处 1153/1168 | `Paladin_Retribution_Check.lua:52` | **不一致（触发信号不同）** | **P1** |
| 智能AOE（跨职业） | 各职业 Menu 文案 + 内联 | `Core/SmartAOE.lua:56` `WR_ShouldUseAOE` | **核心一致；暗牧缺失** | ✅ / P1(缺口) |
| 鸟德 月神轨道炮 | `Druid_Balance_Rotation.lua:220-251` | `Druid_Balance.lua:320` + `DRUID_EclipseSystem.lua:157` | **大体一致；有直呼瑕疵** | P3 |

**一句话：大部分移植逻辑正确，但「惩戒骑祈求圣光提醒」存在明确的触发信号偏差（把"满足=5层"误读成"CD快好"），是最需要修的一项。**

---

## 1. 冰DK 亡者大军（倒数大军）—— P2

**官方逻辑**（`WR_DK_BDK_CountdownArmy`）：
- 由**开怪前 DBM 药水倒数**驱动：`remain = WR_PotionRemaining(); if remain < 14 or remain > 15 then return`（只在倒数 14~15 秒窗口触发）
- 放大军前先切**邪恶灵气（绿脸）**：`WR_ColorFrame_Show(8, "倒数大军切绿脸")`
- 施放：`WR_GetGCD("亡者大军") < 11` 时 `WR_ColorFrame_Show(19, "倒数亡者大军")`
- 结束后/取消后切回**鲜血灵气（红脸）**：`WR_ColorFrame_Show(7, ...)`

**MK 逻辑**（`WR_DK_BDK_CRWZDJ`，用户插入宏）：
- 是**战斗中手动插入宏**（开关 `DK_BDK_CRWZDJ`），CD 剩余 ≤8 秒弹"大军即将就绪"提示（line 523），`WR_GetGCD("亡者大军") < 11` 时施放（line 543）
- 施放成功事件里切回鲜血灵气（line 450-457），并有锁红脸自动 `WR_DK_BDK_ZDBSLQ`

**差异点**：
1. **施法阈值 `GCD < 11` 一致 ✅**，切回鲜血灵气一致 ✅
2. ⚠️ 官方是"开怪前倒数自动序列"，MK 是"战斗中手动插入"——**时序模型不同**（官方会在进战前就铺好大军，MK 进战后按 CD 放）
3. ⚠️ 官方放大军前**切邪恶灵气（绿脸）**增益，MK 冰DK **没有这一步**（MK 只有鲜血灵气自动，无邪恶灵气预切换）。属缺失优化，不影响放出但损失增伤。

**影响**：非硬性 bug，大军能正常放出；但与官方"倒数→绿脸→大军→红脸"的精确时序不符，伤害/节奏略逊。

---

## 2. 毁灭术 暗影灼烧距离提示 —— ✅ 一致

**官方**（`WR_SS_HM_ShadowburnRangeTip`）：战斗中 + 目标存在 + 可攻击 + 未死亡 + `IsSpellInRange("暗影灼烧") ~= 1` 时显示 "暗影灼烧 距离太远!!!"；进射程 `OnUpdate` 立即隐藏；按 `lastGuid`（同目标）+ `C_Timer.After(4)` 节流。

**MK**（`Warlock_Destruction.lua:115`）：`PigSet.SS_HM_HD_TIP` 开启时，目标存在+可攻击+未死亡+ `IsSpellInRange ~= 1` 弹 `PigAlert("距离不够 靠近")`；进射程重置节流（`WR_SS_HM_HD_TIP_T = 0`）；按 `WR_SS_HM_HD_TIP_T`（1.5 秒）节流。

**核对**：触发条件、进射程消失、节流防刷三者完全一致。差异仅为：
- 文案官方"暗影灼烧 距离太远!!!" vs MK"距离不够 靠近"（语义相同）
- 实现官方用独立 tipFrame、MK 用 `PigAlert`（都是屏幕中央红字，等价）
- 开关变量名官方 `SS_HM_HDLX` vs MK `SS_HM_HD_TIP`——已确认 `Warlock_Menu.lua:306` 的 `saveVariable="SS_HM_HD_TIP"` 与代码一致，内部自洽 ✅

**结论：逻辑等价，无问题。**

---

## 3. 惩戒骑 祈求圣光"别动了" —— ⚠️ P1（逻辑不一致）

**官方逻辑**：`WR_PaladinRetribution_QQSG_TipShow()` 本身只做显示+节流（2 秒），**真正的触发条件在调用处**：
- 主触发（line 1151-1155）：`WR_SpellUsable("祈求圣光", true) and noBurden and zidongbaofa and ( (zy==5,qc==0) or (zy==4,qc==1) or (zy==3,qc==2) or (needQQSG and zy>=5) )` → 即**"祈求圣光可用 + 正义/虔诚合计达 5 层（满足）"**时才提醒。
- 次触发（line 1168）：`noBurden and (zy or 0) >= 4` 时在十字军块里也提醒。
- GX 日志原文："**祈求快满足时**屏幕大红字"——"满足"= 5 层组合。

**MK 逻辑**（`Paladin_Retribution_Check.lua:52-62`）：
```
local cdLeft = WR_CJ_SpellCDLeft("祈求圣光")
local layersNear = (justice + piety) >= 4
if cdLeft > 0 and cdLeft <= 4 and layersNear and now >= tipCooldown.qqsg then
    PigAlert("祈求圣光 别动了", 1, 0, 0, 1.2)
```
即 **"CD 剩余 ≤4 秒 + 总层数 ≥4"** 时提醒（注释 line 50 明确写"提前 4 秒"）。

**核心偏差**：
- 官方触发信号 = **技能可用（已脱 CD）+ 5 层组合**；MK 触发信号 = **CD 还剩 ≤4 秒（尚未可用）+ 总层数 ≥4**。
- MK 把"满足"误读为"CD 快好"，**提前约 4 秒弹出**，且层数门槛是"≥4"而非官方的"5 层精确组合"。
- 后果：玩家在祈求圣光**还放不出来**时就被喊"别动了"；而真正该提醒的"技能可用+5层"窗口，MK 反而可能因层数<4 或 CD 恰好>4 而漏提醒。

**建议修正**（对齐官方）：改为 `WR_SpellUsable("祈求圣光", true)` 且 `not 圣光重担` 且 `(zy==5,qc==0)or(zy==4,qc==1)or(zy==3,qc==2)`（或至少 `zy+qc>=5`）时提醒，移除 `cdLeft<=4` 这一错误信号。

**这是本轮审计发现的最明确逻辑错误。**

---

## 4. 智能AOE（跨职业）—— 核心 ✅，暗牧缺口 P1

**MK 核心函数** `WR_ShouldUseAOE(spellName, range, debuffName, minCount)`（`Core/SmartAOE.lua:56`）：
- 手动 AOE 模式（`WR_GLOBAL_MANUAL_AOE`）→ 强制施放
- 智能+手动都关 → 不施放
- 智能开 → `范围内敌对数 >= minCount` 才施放（支持按 debuff 排除）

逻辑干净、自洽。各职业调用阈值核对：
- 烈焰风暴 `WR_ShouldUseAOE("烈焰风暴", 8, "", 2)` ✅
- 暴风雪 `WR_ShouldUseAOE("暴风雪", 35, "", 3)` ✅（注释"35yd≥3"对得上）
- 冰锥术/冰霜新星 `WR_ShouldUseAOE("...", 10, "", 2)` ✅
- 战士/萨满/盗贼/术士/法师均按"手动爆发强制 / 智能按 N 码≥M"模式 ✅

与官方 GX"远程输出增加独立智能AOE（暗牧/元素/术士等）"设计意图**一致**（每技能独立判断、最少 N 个扎堆目标）。

**缺口（P1，延续上轮结论）**：**暗牧（Priest）目录无 `智能AOE` 守卫**。官方 8-22 点名的"暗牧独立智能AOE"在 MK 暗牧未落地（已 grep 确认 Priest 目录无 `智能AOE` / `WR_ShouldUseAOE` 调用）。这是真实功能缺失，非逻辑错误。

---

## 5. 鸟德 月神轨道炮 —— 大体一致，P3 小瑕疵

**官方**（`Druid_Balance_Rotation.lua`）：`WR_ColorFrame_Show(86, "月神轨道炮")` + `WR_StopCast(WR_GetTrueCastTime("月神轨道炮"))` 停读优化；释放条件 `(BIRD_MOON>=3 and BIRD_SUN>=3) or WR_SpellUsable("月神轨道炮")`。

**MK**（`Druid_Balance.lua:320-348`）：主线用 `WR_ColorFrame_Show(86, "月神轨道炮")` + `not WR_StopCast(...)` ✅，阈值 `WR_SpellUsable` 与官方 `WR_SpellUsable` 分支一致 ✅。

**小瑕疵**：`DRUID_EclipseSystem.lua:180` 用 `CastSpellByName("月神轨道炮")` **直接施放**，绕过 MK 统一的 `WR_ColorFrame_Show`/宏体系，可能与主线重复触发或绕过 stopcast 判断。建议统一改回 `WR_ColorFrame_Show(86, "月神轨道炮")`。

---

## 行动建议（按优先级）

1. **P1 必修**：修正 `Paladin_Retribution_Check.lua:52-62` 惩戒骑提醒——去掉 `cdLeft<=4`，改为"技能可用 + 5 层组合"（对齐官方）。
2. **P1 补缺口**：给暗牧加独立智能 AOE 守卫（参考 `Warlock_Destruction.lua:835` 的 `WR_ShouldUseAOE` 调用范式）。
3. **P2 优化**：冰DK 亡者大军补"施放前切邪恶灵气（绿脸）"一步，并评估是否要改回"开怪前 DBM 倒数自动序列"以对齐官方时序。
4. **P3 清理**：鸟德 `DRUID_EclipseSystem.lua:180` 的 `CastSpellByName` 改回 `WR_ColorFrame_Show(86, "月神轨道炮")`。
5. 其余（毁灭术距离提示、智能AOE 核心、鸟德主线）**逻辑等价，无需改动**。

> 注：以上为静态代码对照结论，最终仍需游戏内木桩/副本实测验证行为。
