-- ============================================================
-- Hunter_Forever_SV.lua  《魔兽世界：无限》(Forever) 生存专精循环
-- 改动日期：2026-11-16（按猪猪 / 彼岸花-无限服生存页重做）
-- ------------------------------------------------------------
-- 本次重做：
--   1. 面板按截图重建：选择（防ADD / 共享冷却：瞄准射击or多重射击）、
--      拉条（喝红药30%）、爆发（急速射击 / 种族爆发 + 全开/全关/切换）、
--      功能（远程技能 / 近战技能 / 宠物 / 印记 / 切换目标）、
--      插入（献祭陷阱/冰冻陷阱/冰霜陷阱/震荡射击/扰乱射击/治疗宠物/
--            急速射击/照明弹/乱射/爆炸陷阱/假死）。
--   2. 功能层全部在 Hunter_Survival_Features.lua（WR_HunterSV）：
--      远程技能与近战技能各自右键小窗逐项勾选；宠物右键选召唤/复活模式/
--      脱战治疗阈值；印记右键可只打首领；急速右键可只打首领。
--   3. 删除 80 级 / 无限不存在的旧技能引用：杀戮射击 / 杀戮命令 /
--      眼镜蛇射击 / 奇美拉射击 / 稳固射击 / 爆炸射击（读条填充） /
--      黑箭 / 削砍 / 准备就绪 / 沉默射击 / 饰品 / 手套 / 炸弹 / 速度药水等；
--      保留 60 级真实技能：毒蛇钉刺 / 奥术射击 / 瞄准射击 / 多重射击 /
--      狙击 / 震荡射击 / 猫鼬撕咬 / 摔绊 / 猛禽一击 / 反击 / 陆行鸟踢击。
--   4. 循环顺序：
--      宠物维护（脱战召唤/复活/治疗）→ 切换目标 → 自动射击 →
--      防ADD门 → 守护 → 插入 → 喝红药 → 猎人印记 → 爆发 →
--      远程技能 → 近战技能。
--   5. 「共享冷却」：瞄准射击与多重射击共享 6 秒冷却，面板下拉选择优先项
--      （1=瞄准射击 / 2=多重射击）。
-- ============================================================

if WR_PlayerClass ~= "HUNTER" then return end

function WR_HunterForeverSV()
    local specName = "生存"
    local HS = WR_HunterSV
    if type(HS) ~= "table" then return false end

    -- 宠物维护：不需要目标，脱战也要能召唤/复活/治疗
    if HS.PetStep() then return true end

    -- 目标失效时先切目标（无目标也能工作）
    if HS.TargetSwitchStep() then return true end

    local inRange = WR_HunterForever_Base()
    if not inRange then return false end

    -- 自动射击保持：防ADD开启且脱战时由公共件自动约束
    if WR_HunterForever_AutoShot(inRange, specName) then return true end
    if not WR_HunterForever_InCombatGate(specName) then return false end
    if WR_HunterForever_Aspect() then return true end

    -- 插入（一次性，放完自关）：不受远程/近战总开关影响
    if HS.InsertStep() then return true end

    -- 喝红药（拉条 30%）
    if HS.PotionStep() then return true end

    -- 猎人印记（独立开关）
    if HS.MarkStep() then return true end

    -- 爆发（急速射击 / 种族爆发）
    if HS.BurstStep() then return true end

    -- 远程技能（右键小窗逐项勾选）
    if HS.RemoteStep(inRange) then return true end

    -- 近战技能（贴身 8 码内）
    if HS.MeleeStep(inRange) then return true end

    return false
end
