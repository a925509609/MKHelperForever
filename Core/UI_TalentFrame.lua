-- ============================================================
-- UI_TalentFrame.lua
-- 功能：根据当前激活的天赋，显示对应的配置面板（下拉菜单+复选框）
-- ============================================================

local Frame = {}
WR_TalentFrameList = WR_TalentFrameList or {}

function WR_TalentFrame(Menu, Talent_Name, Talent_Id)
    -- 天赋ID为5表示未激活
    if Talent_Id == 5 then
        if TianFu_Text then
            -- ★ 2026-08-21：对齐 ZZHELPER 文案「天赋: 未激活」
            TianFu_Text:SetText("天赋：|cff808080未激活|r")
            TianFu_Text:SetPoint("TOP", WR_ClassMenuRegion or WR_ClassRegion or WR_ConfigFrame, "TOP", 0, -4)
        end
        for i = 1, 4 do
            if Frame[i] then Frame[i]:Hide() end
        end
        return
    end

    -- 首次调用：创建所有天赋面板
    if not WR_TalentFrameCreateOK then
        WR_TalentFrameList = {}
        local createdAny = false
        for i = 1, 4 do
            _, name = GetTalentTabInfo(i)
            if name ~= "" and Menu and Menu[name] and Menu[name].DM and Menu[name].CB then
                Frame[i] = WR_CreateTalentFrame(Menu[name].DM, Menu[name].CB)
                WR_TalentFrameList[i] = Frame[i]
                createdAny = true
            end
        end
        -- ★ 2026-08-21 兜底：1级/未点天赋时天赋页名匹配不上（createdAny=false），
        --   面板一个都建不出来 → 按 Menu 键建面板，且默认专精（德鲁伊=平衡）放 slot 1，
        --   保证 WR_GetMyTalent 返回 Talent_Id=1 时显示的是平衡面板
        if not createdAny and Menu then
            local defaultSpec = (type(WR_GetDefaultSpecByClass) == "function") and WR_GetDefaultSpecByClass() or nil
            local slot = 1
            if defaultSpec and Menu[defaultSpec] and Menu[defaultSpec].DM and Menu[defaultSpec].CB then
                Frame[slot] = WR_CreateTalentFrame(Menu[defaultSpec].DM, Menu[defaultSpec].CB)
                WR_TalentFrameList[slot] = Frame[slot]
                slot = slot + 1
            end
            for specName, specData in pairs(Menu) do
                if specName ~= defaultSpec and specData and specData.DM and specData.CB and slot <= 4 then
                    Frame[slot] = WR_CreateTalentFrame(specData.DM, specData.CB)
                    WR_TalentFrameList[slot] = Frame[slot]
                    slot = slot + 1
                end
            end
        end
        WR_TalentFrameCreateOK = true
    end

    -- 更新标题并显示对应面板
    if WR_ConfigFrame then
        local displayName = Talent_Name

        TianFu_Text:SetText("天赋：" .. WR_ClassesColor("player") .. displayName .. "|r")
        TianFu_Text:SetPoint("TOP", WR_ClassMenuRegion or WR_ClassRegion or WR_ConfigFrame, "TOP", 0, -4)

        -- 显示对应天赋的面板，隐藏其他
        for i = 1, 4 do
            if Frame[i] then
                if i == Talent_Id then
                    Frame[i]:Show()
                    if type(WR_SetActiveTalentDropdowns) == "function" then
                        WR_SetActiveTalentDropdowns(Frame[i])
                    end
                else
                    Frame[i]:Hide()
                end
            end
        end

        -- 刷新布局
        if type(WR_RefreshConfigUI) == "function" then
            WR_RefreshConfigUI()
        elseif type(WR_LayoutConfigFrame) == "function" then
            WR_LayoutConfigFrame()
        else
            local CB_List_Row = 0
            if Menu and Menu[Talent_Name] and Menu[Talent_Name].CB then
                for _, config in ipairs(Menu[Talent_Name].CB) do
                    if config.row > CB_List_Row then
                        CB_List_Row = config.row
                    end
                end
                WR_ConfigFrame:SetSize(WR_ConfigFrame:GetWidth(),
                    WRH(#Menu[Talent_Name].DM, CB_List_Row))
            end
        end
    end
end