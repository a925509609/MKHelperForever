-- 生成“刺骨”菜单项（针对阿努巴拉克P3阶段）
local function WR_MenuAnubHeal_MakeEntry()
  return {
    row = 5, column = 1,        -- 菜单位置（第5行第1列）
    IconID = 135838,            -- 图标ID
    text = "刺骨",              -- 显示文字
    tooltipText = "TOC|cff00adf0小强P3|r：大团吃到|cff00adf0虫群|r后，仅优先刷|cff996b1f坦克|r和中|cff00adf0刺骨之寒|r的人，其他人掉血不刷。",
    saveVariable = "ZL_CQGCYX", -- 保存设置用的变量名
    defaultState = true,        -- 默认开启
  }
end

-- 生成“血肉”菜单项（针对加拉克苏斯大王）
local function WR_MenuJaraxxusHeal_MakeEntry()
  return {
    row = 5, column = 2,
    IconID = 136186,
    text = "血肉",
    tooltipText = "TOC|cff00adf0加拉克苏斯|r：团里有人中|cff00adf0血肉成灰|r时，最高优先级过量刷到debuff消失。",
    saveVariable = "ZL_XRCYX",
    defaultState = true,
  }
end

-- 检查某个菜单列表里是否已经存在某个saveVariable
local function WR_MenuHealerTOC_HasEntry(cbList, saveVariable)
  if type(cbList) ~= "table" then return false end
  for _, cb in ipairs(cbList) do
    if cb.saveVariable == saveVariable then return true end
  end
  return false
end

-- 将TOC特有选项注入到指定职业专精的菜单中
local function WR_MenuHealerTOC_InjectHealerSpec(classMenu, specKey)
  if type(classMenu) ~= "table" then return end
  local specData = classMenu[specKey]   -- 获取该专精的菜单数据
  if type(specData) ~= "table" or not specData.CB then return end

  -- 如果还没有“刺骨”项，则添加
  if not WR_MenuHealerTOC_HasEntry(specData.CB, "ZL_CQGCYX") then
    specData.CB[#specData.CB + 1] = WR_MenuAnubHeal_MakeEntry()
  end
  -- 如果还没有“血肉”项，则添加
  if not WR_MenuHealerTOC_HasEntry(specData.CB, "ZL_XRCYX") then
    specData.CB[#specData.CB + 1] = WR_MenuJaraxxusHeal_MakeEntry()
  end
end

-- 所有治疗专精列表（需要注入的）
local healerSpecs = {
  { menu = Paladin_Menu, key = "神圣" },
  { menu = Priest_Menu,  key = "戒律" },
  { menu = Priest_Menu,  key = "神圣" },
  { menu = Druid_Menu,   key = "恢复" },
  { menu = Shaman_Menu,  key = "恢复" },
  { menu = Monk_Menu,    key = "织雾" },
}

-- 遍历并注入
for _, entry in ipairs(healerSpecs) do
  WR_MenuHealerTOC_InjectHealerSpec(entry.menu, entry.key)
end